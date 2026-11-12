package png

import "core:compress"
import "core:compress/deflate"
import "core:encoding/endian"
import "core:hash"
import "core:image"
import "core:mem"

DEFAULT_LEVEL :: deflate.Deflate_Level.Level_5

Filter_Strategy :: enum u8 {
	None     = 0,
	Sub      = 1,
	Up       = 2,
	Average  = 3,
	Paeth    = 4,
	Adaptive = 5,
}

save_to_buffer :: proc(output: ^[dynamic]byte, img: ^Image, options := Options{}, level := DEFAULT_LEVEL, filter := Filter_Strategy.Adaptive, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if img == nil {
		return .Invalid_Input_Image
	}
	if output == nil {
		return .Invalid_Output
	}
	if img.width <= 0 || img.height <= 0 || img.width > int(max(u32be) >> 1) || img.height > int(max(u32be) >> 1) || img.width * img.height > image.MAX_DIMENSIONS {
		return .Invalid_Image_Dimensions
	}
	if img.channels < 1 || img.channels > 4 {
		return .Invalid_Number_Of_Channels
	}
	if img.depth != 8 && img.depth != 16 {
		return .Invalid_Image_Depth
	}
	if filter > .Adaptive {
		return .Unsupported_Option
	}

	bytes_per_pixel := img.channels * img.depth / 8
	row_stride      := img.width * bytes_per_pixel
	if row_stride * img.height != len(img.pixels) {
		return .Invalid_Input_Image
	}

	filtered_size := (row_stride + 1) * img.height
	bound         := deflate.deflate_bound(filtered_size)
	if bound < 0 || bound > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return .Image_Dimensions_Too_Large
	}

	filtered := make([]u8, filtered_size) or_return
	defer delete(filtered)

	save_filter(filtered, img, row_stride, bytes_per_pixel, filter) or_return

	header := image.PNG_IHDR{
		width      = u32be(img.width),
		height     = u32be(img.height),
		bit_depth  = u8(img.depth),
		color_type = SAVE_COLOR_TYPE[img.channels],
	}

	if non_zero_resize(output, SAVE_DATA_OFFSET + bound + SAVE_TRAILER_SIZE) != nil {
		return .Unable_To_Allocate_Or_Resize
	}
	buf := output[:]

	signature := transmute([size_of(Signature)]u8)Signature.PNG
	copy(buf, signature[:])

	header_bytes := transmute([image.PNG_IHDR_SIZE]u8)header
	copy(buf[SAVE_IHDR_OFFSET + size_of(image.PNG_Chunk_Header):], header_bytes[:])
	save_chunk(buf, SAVE_IHDR_OFFSET, image.PNG_IHDR_SIZE, .IHDR)

	s := new(deflate.Deflate) or_return
	defer free(s)

	written := deflate.deflate_zlib_to_slice(s, buf[SAVE_DATA_OFFSET:][:bound], filtered, level) or_return
	if written > int(max(i32)) {
		return .Image_Dimensions_Too_Large
	}
	save_chunk(buf, SAVE_IDAT_OFFSET, written, .IDAT)

	iend_offset := SAVE_DATA_OFFSET + written + size_of(u32be)
	save_chunk(buf, iend_offset, 0, .IEND)

	non_zero_resize(output, iend_offset + size_of(image.PNG_Chunk_Header) + size_of(u32be))
	return nil
}

@(private, rodata)
SAVE_COLOR_TYPE := [5]image.PNG_Color_Type{
	{},
	{},
	{.Alpha},
	{.Color},
	{.Color, .Alpha},
}

@(private)
SAVE_IHDR_OFFSET  :: size_of(Signature)
@(private)
SAVE_IDAT_OFFSET  :: SAVE_IHDR_OFFSET + size_of(image.PNG_Chunk_Header) + image.PNG_IHDR_SIZE + size_of(u32be)
@(private)
SAVE_DATA_OFFSET  :: SAVE_IDAT_OFFSET + size_of(image.PNG_Chunk_Header)
@(private)
SAVE_TRAILER_SIZE :: size_of(u32be) + size_of(image.PNG_Chunk_Header) + size_of(u32be)

@(private)
save_chunk :: proc(buf: []u8, offset, length: int, type: image.PNG_Chunk_Type) #no_bounds_check {
	(^image.PNG_Chunk_Header)(&buf[offset])^ = {length = u32be(length), type = type}
	crc := hash.crc32(buf[offset + size_of(u32be):][:size_of(image.PNG_Chunk_Type) + length])
	endian.unchecked_put_u32be(buf[offset + size_of(image.PNG_Chunk_Header) + length:], crc)
}

@(private)
save_filter :: proc(filtered: []u8, img: ^Image, row_stride, bytes_per_pixel: int, filter: Filter_Strategy) -> (err: Error) #no_bounds_check {
	scratch := make([]u8, 3 * row_stride) or_return
	defer delete(scratch)

	prev  := scratch[:row_stride]
	swap  := scratch[row_stride:][:row_stride]
	other := scratch[2 * row_stride:]
	dest  := filtered

	for y in 0..<img.height {
		cur := img.pixels[y * row_stride:][:row_stride]
		if img.depth == 16 {
			wide := mem.slice_data_cast([]u16,   cur)
			big  := mem.slice_data_cast([]u16be, swap)
			for v, i in wide {
				big[i] = u16be(v)
			}
			cur = swap
			swap, other = other, swap
		}

		row_filter := filter_choose(cur, prev, bytes_per_pixel) if filter == .Adaptive else Row_Filter(filter)
		filter_row(dest[:row_stride + 1], cur, prev, bytes_per_pixel, row_filter)

		dest = dest[row_stride + 1:]
		prev = cur
	}
	return nil
}

@(private)
filter_choose :: proc(cur, prev: []u8, bytes_per_pixel: int) -> (best: Row_Filter) #no_bounds_check {
	costs: [Row_Filter]u32
	for i in 0..<bytes_per_pixel {
		filter_cost_add(&costs, cur[i], 0, prev[i], 0)
	}
	for i in bytes_per_pixel..<len(cur) {
		filter_cost_add(&costs, cur[i], cur[i - bytes_per_pixel], prev[i], prev[i - bytes_per_pixel])
	}

	best = .None
	for filter in Row_Filter.Sub..=Row_Filter.Paeth {
		if costs[filter] < costs[best] {
			best = filter
		}
	}
	return
}

@(private)
filter_cost_add :: #force_inline proc "contextless" (costs: ^[Row_Filter]u32, x, left, up, up_left: u8) {
	costs[.None]    += filter_magnitude(x)
	costs[.Sub]     += filter_magnitude(x - left)
	costs[.Up]      += filter_magnitude(x - up)
	costs[.Average] += filter_magnitude(x - u8((u16(left) + u16(up)) >> 1))
	costs[.Paeth]   += filter_magnitude(x - filter_paeth_select(left, up, up_left))
}

@(private)
filter_magnitude :: #force_inline proc "contextless" (v: u8) -> u32 {
	return u32(min(v, 0 - v))
}

@(private)
filter_paeth_select :: #force_inline proc "contextless" (left, up, up_left: u8) -> u8 {
	a, b, c := i16(left), i16(up), i16(up_left)
	pa := abs(b - c)
	pb := abs(a - c)
	pc := abs(a + b - 2 * c)
	return left if pa <= pb && pa <= pc else (up if pb <= pc else up_left)
}

@(private)
filter_row :: proc(dest, cur, prev: []u8, bytes_per_pixel: int, filter: Row_Filter) #no_bounds_check {
	dest[0] = u8(filter)
	switch filter {
	case .None:    copy(dest[1:], cur)
	case .Sub:     filter_apply(dest[1:], cur, prev, bytes_per_pixel, .Sub)
	case .Up:      filter_apply(dest[1:], cur, prev, bytes_per_pixel, .Up)
	case .Average: filter_apply(dest[1:], cur, prev, bytes_per_pixel, .Average)
	case .Paeth:   filter_apply(dest[1:], cur, prev, bytes_per_pixel, .Paeth)
	}
}

@(private)
filter_apply :: proc(dest, cur, prev: []u8, bytes_per_pixel: int, $FILTER: Row_Filter) #no_bounds_check {
	for i in 0..<bytes_per_pixel {
		dest[i] = cur[i] - filter_predict(0, prev[i], 0, FILTER)
	}
	for i in bytes_per_pixel..<len(cur) {
		dest[i] = cur[i] - filter_predict(cur[i - bytes_per_pixel], prev[i], prev[i - bytes_per_pixel], FILTER)
	}
}

@(private)
filter_predict :: #force_inline proc(left, up, up_left: u8, $FILTER: Row_Filter) -> u8 {
	when FILTER == .None {
		return 0
	} else when FILTER == .Sub {
		return left
	} else when FILTER == .Up {
		return up
	} else when FILTER == .Average {
		return u8((u16(left) + u16(up)) >> 1)
	} else {
		return filter_paeth_select(left, up, up_left)
	}
}
