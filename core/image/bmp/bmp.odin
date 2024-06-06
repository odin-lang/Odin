// package bmp implements a Microsoft BMP image reader
package core_image_bmp

import "core:image"
import "core:bytes"
import "core:compress"
import "core:mem"
import "base:intrinsics"
import "base:runtime"
@(require) import "core:fmt"

Error   :: image.Error
Image   :: image.Image
Options :: image.Options

RGB_Pixel  :: image.RGB_Pixel
RGBA_Pixel :: image.RGBA_Pixel

FILE_HEADER_SIZE :: 14
INFO_STUB_SIZE   :: FILE_HEADER_SIZE + size_of(image.BMP_Version)

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	ctx := &compress.Context_Memory_Input{
		input_data = data,
	}

	img, err = load_from_context(ctx, options, allocator)
	return img, err
}

@(optimization_mode="speed")
load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	// For compress.read_slice(), until that's rewritten to not use temp allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	if .info in options {
		options |= {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	info_buf: [size_of(image.BMP_Header)]u8

	// Read file header (14) + info size (4)
	stub_data := compress.read_slice(ctx, INFO_STUB_SIZE) or_return
	copy(info_buf[:], stub_data[:])
	stub_info := transmute(image.BMP_Header)info_buf

	if stub_info.magic != .Bitmap {
		for v in image.BMP_Magic {
			if stub_info.magic == v {
				return img, .Unsupported_OS2_File
			}
		}
		return img, .Invalid_Signature
	}

	info: image.BMP_Header
	switch stub_info.info_size {
	case .OS2_v1:
		// Read the remainder of the header
		os2_data := compress.read_data(ctx, image.OS2_Header) or_return

		info = transmute(image.BMP_Header)info_buf
		info.width  = i32le(os2_data.width)
		info.height = i32le(os2_data.height)
		info.planes = os2_data.planes
		info.bpp    = os2_data.bpp

		switch info.bpp {
		case 1, 4, 8, 24:
		case:
			return img, .Unsupported_BPP
		}

	case .ABBR_16 ..= .V5:
		// Sizes include V3, V4, V5 and OS2v2 outright, but can also handle truncated headers.
		// Sometimes called BITMAPV2INFOHEADER or BITMAPV3INFOHEADER.
		// Let's just try to process it.

		to_read   := int(stub_info.info_size) - size_of(image.BMP_Version)
		info_data := compress.read_slice(ctx, to_read) or_return
		copy(info_buf[INFO_STUB_SIZE:], info_data[:])

		// Update info struct with the rest of the data we read
		info = transmute(image.BMP_Header)info_buf

	case:
		return img, .Unsupported_BMP_Version
	}

	/* TODO(Jeroen): Add a "strict" option to catch these non-issues that violate spec?
	if info.planes != 1 {
		return img, .Invalid_Planes_Value
	}
	*/

	if img == nil {
		img = new(Image)
	}
	img.which = .BMP

	img.metadata = new_clone(image.BMP_Info{
		info = info,
	})

	img.width    = abs(int(info.width))
	img.height   = abs(int(info.height))
	img.channels = 3
	img.depth    = 8

	if img.width == 0 || img.height == 0 {
		return img, .Invalid_Image_Dimensions
	}

	total_pixels := abs(img.width * img.height)
	if total_pixels > image.MAX_DIMENSIONS {
		return img, .Image_Dimensions_Too_Large
	}

	// TODO(Jeroen): Handle RGBA.
	switch info.compression {
	case .Bit_Fields, .Alpha_Bit_Fields:
		switch info.bpp {
		case 16, 32:
			make_output(img, allocator)           or_return
			decode_rgb(ctx, img, info, allocator) or_return
		case:
			if is_os2(info.info_size) {
				return img, .Unsupported_Compression
			}
			return img, .Unsupported_BPP
		}
	case .RGB:
		make_output(img, allocator)           or_return
		decode_rgb(ctx, img, info, allocator) or_return
	case .RLE4, .RLE8:
		make_output(img, allocator)           or_return
		decode_rle(ctx, img, info, allocator) or_return
	case .CMYK, .CMYK_RLE4, .CMYK_RLE8: fallthrough
	case .PNG, .JPEG:                   fallthrough
	case: return img, .Unsupported_Compression
	}

	// Flipped vertically
	if info.height < 0 {
		pixels := mem.slice_data_cast([]RGB_Pixel, img.pixels.buf[:])
		for y in 0..<img.height / 2 {
			for x in 0..<img.width {
				top := y * img.width + x
				bot := (img.height - y - 1) * img.width + x

				pixels[top], pixels[bot] = pixels[bot], pixels[top]
			}
		}
	}
	return
}

is_os2 :: proc(version: image.BMP_Version) -> (res: bool) {
	#partial switch version {
	case .OS2_v1, .OS2_v2: return true
	case: return false
	}
}

make_output :: proc(img: ^Image, allocator := context.allocator) -> (err: Error) {
	assert(img != nil)
	bytes_needed := img.channels * img.height * img.width
	img.pixels.buf = make([dynamic]u8, bytes_needed, allocator)
	if len(img.pixels.buf) != bytes_needed {
		return .Unable_To_Allocate_Or_Resize
	}
	return
}

write :: proc(img: ^Image, x, y: int, pix: RGB_Pixel) -> (err: Error) {
	if y >= img.height || x >= img.width {
		return .Corrupt
	}
	out := mem.slice_data_cast([]RGB_Pixel, img.pixels.buf[:])
	assert(img.height >= 1 && img.width >= 1)
	out[(img.height - y - 1) * img.width + x] = pix
	return
}

Bitmask :: struct {
	mask:  [4]u32le `fmt:"b"`,
	shift: [4]u32le,
	bits:  [4]u32le,
}

read_or_make_bit_masks :: proc(ctx: ^$C, info: image.BMP_Header) -> (res: Bitmask, read: int, err: Error) {
	ctz :: intrinsics.count_trailing_zeros
	c1s :: intrinsics.count_ones

	#partial switch info.compression {
	case .RGB:
		switch info.bpp {
		case 16:
			return {
				mask  = {31 << 10, 31 << 5, 31, 0},
				shift = {      10,       5,  0, 0},
				bits  = {       5,       5,  5, 0},
			}, int(4 * info.colors_used), nil

		case 32:
			return {
				mask  = {255 << 16, 255 << 8, 255, 255 << 24},
				shift = {       16,        8,        0,   24},
				bits  = {        8,        8,        8,    8},
			}, int(4 * info.colors_used), nil

		case: return {}, 0, .Unsupported_BPP
		}
	case .Bit_Fields, .Alpha_Bit_Fields:
		bf := info.masks
		alpha_mask := false
		bit_count: u32le

		#partial switch info.info_size {
		case .ABBR_52 ..= .V5:
			// All possible BMP header sizes 52+ bytes long, includes V4 + V5
			// Bit fields were read as part of the header
			// V3 header is 40 bytes. We need 56 at a minimum for RGBA bit fields in the next section.
			if info.info_size >= .ABBR_56 {
				alpha_mask = true
			}

		case .V3:
			// Version 3 doesn't have a bit field embedded, but can still have a 3 or 4 color bit field.
			// Because it wasn't read as part of the header, we need to read it now.

			if info.compression == .Alpha_Bit_Fields {
				bf = compress.read_data(ctx, [4]u32le) or_return
				alpha_mask = true
				read = 16
			} else {
				bf.xyz = compress.read_data(ctx, [3]u32le) or_return
				read = 12
			}

		case:
			// Bit fields are unhandled for this BMP version
			return {}, 0, .Bitfield_Version_Unhandled
		}

		if alpha_mask {
			res = {
				mask  = {bf.r,      bf.g,      bf.b,      bf.a},
				shift = {ctz(bf.r), ctz(bf.g), ctz(bf.b), ctz(bf.a)},
				bits  = {c1s(bf.r), c1s(bf.g), c1s(bf.b), c1s(bf.a)},
			}

			bit_count = res.bits.r + res.bits.g + res.bits.b + res.bits.a
		} else {
			res = {
				mask  = {bf.r,      bf.g,      bf.b,      0},
				shift = {ctz(bf.r), ctz(bf.g), ctz(bf.b), 0},
				bits  = {c1s(bf.r), c1s(bf.g), c1s(bf.b), 0},
			}

			bit_count = res.bits.r + res.bits.g + res.bits.b
		}

		if bit_count > u32le(info.bpp) {
			err = .Bitfield_Sum_Exceeds_BPP
		}

		overlapped := res.mask.r | res.mask.g | res.mask.b | res.mask.a
		if c1s(overlapped) < bit_count {
			err = .Bitfield_Overlapped
		}
		return res, read, err

	case:
		return {}, 0, .Unsupported_Compression
	}
	return
}

scale :: proc(val: $T, mask, shift, bits: u32le) -> (res: u8) {
	if bits == 0 { return 0 } // Guard against malformed bit fields
	v := (u32le(val) & mask) >> shift
	mask_in := u32le(1 << bits) - 1
	return u8(v * 255 / mask_in)
}

decode_rgb :: proc(ctx: ^$C, img: ^Image, info: image.BMP_Header, allocator := context.allocator) -> (err: Error) {
	pixel_offset := int(info.pixel_offset)
	pixel_offset -= int(info.info_size) + FILE_HEADER_SIZE

	palette: [256]RGBA_Pixel

	// Palette size is info.colors_used if populated. If not it's min(1 << bpp, offset to the pixels / channel count)
	colors_used := min(256, 1 << info.bpp if info.colors_used == 0 else info.colors_used)
	max_colors  := pixel_offset / 3 if info.info_size == .OS2_v1 else pixel_offset / 4
	colors_used  = min(colors_used, u32le(max_colors))

	switch info.bpp {
	case 1:
		if info.info_size == .OS2_v1 {
			// 2 x RGB palette of instead of variable RGBA palette
			for i in 0..<colors_used {
				palette[i].rgb = image.read_data(ctx, RGB_Pixel) or_return
			}
			pixel_offset -= int(3 * colors_used)
		} else {
			for i in 0..<colors_used {
				palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
			}
			pixel_offset -= int(4 * colors_used)
		}
		skip_space(ctx, pixel_offset)

		stride := (img.width + 7) / 8
		for y in 0..<img.height {
			data := compress.read_slice(ctx, stride) or_return
			for x in 0..<img.width {
				shift := u8(7 - (x & 0x07))
				p := (data[x / 8] >> shift) & 0x01
				write(img, x, y, palette[p].bgr) or_return
			}
		}

	case 2: // Non-standard on modern Windows, but was allowed on WinCE
		for i in 0..<colors_used {
			palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
		}
		pixel_offset -= int(4 * colors_used)
		skip_space(ctx, pixel_offset)

		stride := (img.width + 3) / 4
		for y in 0..<img.height {
			data := compress.read_slice(ctx, stride) or_return
			for x in 0..<img.width {
				shift := 6 - (x & 0x03) << 1
				p := (data[x / 4] >> u8(shift)) & 0x03
				write(img, x, y, palette[p].bgr) or_return
			}
		}

	case 4:
		if info.info_size == .OS2_v1 {
			// 16 x RGB palette of instead of variable RGBA palette
			for i in 0..<colors_used {
				palette[i].rgb = image.read_data(ctx, RGB_Pixel) or_return
			}
			pixel_offset -= int(3 * colors_used)
		} else {
			for i in 0..<colors_used {
				palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
			}
			pixel_offset -= int(4 * colors_used)
		}
		skip_space(ctx, pixel_offset)

		stride := (img.width + 1) / 2
		for y in 0..<img.height {
			data := compress.read_slice(ctx, stride) or_return
			for x in 0..<img.width {
				p := data[x / 2] >> 4 if x & 1 == 0 else data[x / 2]
				write(img, x, y, palette[p & 0x0f].bgr) or_return
			}
		}

	case 8:
		if info.info_size == .OS2_v1 {
			// 256 x RGB palette of instead of variable RGBA palette
			for i in 0..<colors_used {
				palette[i].rgb = image.read_data(ctx, RGB_Pixel) or_return
			}
			pixel_offset -= int(3 * colors_used)
		} else {
			for i in 0..<colors_used {
				palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
			}
			pixel_offset -= int(4 * colors_used)
		}
		skip_space(ctx, pixel_offset)

		stride := align4(img.width)
		for y in 0..<img.height {
			data := compress.read_slice(ctx, stride) or_return
			for x in 0..<img.width {
				write(img, x, y, palette[data[x]].bgr) or_return
			}
		}

	case 16:
		bm, read := read_or_make_bit_masks(ctx, info) or_return
		// Skip optional palette and other data
		pixel_offset -= read
		skip_space(ctx, pixel_offset)

		stride := align4(img.width * 2)
		for y in 0..<img.height {
			data   := compress.read_slice(ctx, stride) or_return
			pixels := mem.slice_data_cast([]u16le, data)
			for x in 0..<img.width {
				v := pixels[x]
				r := scale(v, bm.mask.r, bm.shift.r, bm.bits.r)
				g := scale(v, bm.mask.g, bm.shift.g, bm.bits.g)
				b := scale(v, bm.mask.b, bm.shift.b, bm.bits.b)
				write(img, x, y, RGB_Pixel{r, g, b}) or_return
			}
		}

	case 24:
		// Eat useless palette and other padding
		skip_space(ctx, pixel_offset)

		stride := align4(img.width * 3)
		for y in 0..<img.height {
			data   := compress.read_slice(ctx, stride) or_return
			pixels := mem.slice_data_cast([]RGB_Pixel, data)
			for x in 0..<img.width {
				write(img, x, y, pixels[x].bgr) or_return
			}
		}

	case 32:
		bm, read := read_or_make_bit_masks(ctx, info) or_return
		// Skip optional palette and other data
		pixel_offset -= read
		skip_space(ctx, pixel_offset)

		for y in 0..<img.height {
			data   := compress.read_slice(ctx, img.width * size_of(RGBA_Pixel)) or_return
			pixels := mem.slice_data_cast([]u32le, data)
			for x in 0..<img.width {
				v := pixels[x]
				r := scale(v, bm.mask.r, bm.shift.r, bm.bits.r)
				g := scale(v, bm.mask.g, bm.shift.g, bm.bits.g)
				b := scale(v, bm.mask.b, bm.shift.b, bm.bits.b)
				write(img, x, y, RGB_Pixel{r, g, b}) or_return
			}
		}

	case:
		return .Unsupported_BPP
	}
	return nil
}

decode_rle :: proc(ctx: ^$C, img: ^Image, info: image.BMP_Header, allocator := context.allocator) -> (err: Error) {
	pixel_offset := int(info.pixel_offset)
	pixel_offset -= int(info.info_size) + FILE_HEADER_SIZE

	bytes_needed := size_of(RGB_Pixel) * img.height * img.width
	if resize(&img.pixels.buf, bytes_needed) != nil {
		return .Unable_To_Allocate_Or_Resize
	}
	out := mem.slice_data_cast([]RGB_Pixel, img.pixels.buf[:])
	assert(len(out) == img.height * img.width)

	palette: [256]RGBA_Pixel

	switch info.bpp {
	case 4:
		colors_used := info.colors_used if info.colors_used > 0 else 16
		colors_used  = min(colors_used, 16)

		for i in 0..<colors_used {
			palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
			pixel_offset -= size_of(RGBA_Pixel)
		}
		skip_space(ctx, pixel_offset)

		pixel_size := info.size - info.pixel_offset
		remaining  := compress.input_size(ctx) or_return
		if remaining < i64(pixel_size) {
			return .Corrupt
		}

		data := make([]u8, int(pixel_size) + 4)
		defer delete(data)

		for i in 0..<pixel_size {
			data[i] = image.read_u8(ctx) or_return
		}

		y, x := 0, 0
		index := 0
		for {
			if len(data[index:]) < 2 {
				return .Corrupt
			}

			if data[index] > 0 {
				for count in 0..<data[index] {
					if count & 1 == 1 {
						write(img, x, y, palette[(data[index + 1] >> 0) & 0x0f].bgr)
					} else {
						write(img, x, y, palette[(data[index + 1] >> 4) & 0x0f].bgr)
					}
					x += 1
				}
				index += 2
			} else {
				switch data[index + 1] {
				case 0: // EOL
					x = 0; y += 1
					index += 2
				case 1: // EOB
					return
				case 2:	// MOVE
					x += int(data[index + 2])
					y += int(data[index + 3])
					index += 4
				case:   // Literals
					run_length := int(data[index + 1])
					aligned    := (align4(run_length) >> 1) + 2

					if index + aligned >= len(data) {
						return .Corrupt
					}

					for count in 0..<run_length {
						val := data[index + 2 + count / 2]
						if count & 1 == 1 {
							val &= 0xf
						} else {
							val  = val >> 4
						}
						write(img, x, y, palette[val].bgr)
						x += 1
					}
					index += aligned
				}
			}
		}

	case 8:
		colors_used := info.colors_used if info.colors_used > 0 else 256
		colors_used  = min(colors_used, 256)

		for i in 0..<colors_used {
			palette[i] = image.read_data(ctx, RGBA_Pixel) or_return
			pixel_offset -= size_of(RGBA_Pixel)
		}
		skip_space(ctx, pixel_offset)

		pixel_size := info.size - info.pixel_offset
		remaining  := compress.input_size(ctx) or_return
		if remaining < i64(pixel_size) {
			return .Corrupt
		}

		data := make([]u8, int(pixel_size) + 4)
		defer delete(data)

		for i in 0..<pixel_size {
			data[i] = image.read_u8(ctx) or_return
		}

		y, x := 0, 0
		index := 0
		for {
			if len(data[index:]) < 2 {
				return .Corrupt
			}

			if data[index] > 0 {
				for _ in 0..<data[index] {
					write(img, x, y, palette[data[index + 1]].bgr)
					x += 1
				}
				index += 2
			} else {
				switch data[index + 1] {
				case 0: // EOL
					x = 0; y += 1
					index += 2
				case 1: // EOB
					return
				case 2:	// MOVE
					x += int(data[index + 2])
					y += int(data[index + 3])
					index += 4
				case:   // Literals
					run_length := int(data[index + 1])
					aligned    := align2(run_length) + 2

					if index + aligned >= len(data) {
						return .Corrupt
					}
					for count in 0..<run_length {
						write(img, x, y, palette[data[index + 2 + count]].bgr)
						x += 1
					}
					index += aligned
				}
			}
		}

	case:
		return .Unsupported_BPP
	}
	return nil
}

align2 :: proc(width: int) -> (stride: int) {
	stride = width
	if width & 1 != 0 {
		stride += 2 - (width & 1)
	}
	return
}

align4 :: proc(width: int) -> (stride: int) {
	stride = width
	if width & 3 != 0 {
		stride += 4 - (width & 3)
	}
	return
}

skip_space :: proc(ctx: ^$C, bytes_to_skip: int) -> (err: Error) {
	if bytes_to_skip < 0 {
		return .Corrupt
	}
	for _ in 0..<bytes_to_skip {
		image.read_u8(ctx) or_return
	}
	return
}

// Cleanup of image-specific data.
destroy :: proc(img: ^Image) {
	if img == nil {
		// Nothing to do. Load must've returned with an error.
		return
	}

	bytes.buffer_destroy(&img.pixels)
	if v, ok := img.metadata.(^image.BMP_Info); ok {
	 	free(v)
	}
	free(img)
}

@(init, private)
_register :: proc() {
	image.register(.BMP, load_from_bytes, destroy)
}