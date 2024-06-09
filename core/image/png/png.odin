/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		Ginger Bill:     Cosmetic changes.
*/


// package png implements a PNG image reader
//
// The PNG specification is at https://www.w3.org/TR/PNG/.
//+vet !using-stmt
package png

import "core:compress"
import "core:compress/zlib"
import "core:image"

import "core:hash"
import "core:bytes"
import "core:io"
import "core:mem"
import "base:intrinsics"
import "base:runtime"

// Limit chunk sizes.
// By default: IDAT = 8k x 8k x 16-bits + 8k filter bytes.
// The total number of pixels defaults to 64 Megapixel and can be tuned in image/common.odin.

_MAX_IDAT_DEFAULT :: ( 8192 /* Width */ *  8192 /* Height */ * 2 /* 16-bit */) +  8192 /* Filter bytes */
_MAX_IDAT         :: (65535 /* Width */ * 65535 /* Height */ * 2 /* 16-bit */) + 65535 /* Filter bytes */

MAX_IDAT_SIZE     :: min(#config(PNG_MAX_IDAT_SIZE, _MAX_IDAT_DEFAULT), _MAX_IDAT)

/*
	For chunks other than IDAT with a variable size like `zTXT` and `eXIf`,
	limit their size to 16 MiB each by default. Max of 256 MiB each.
*/
MAX_CHUNK_SIZE    :: min(#config(PNG_MAX_CHUNK_SIZE, 16_777_216), 268_435_456)


Error     :: image.Error
Image     :: image.Image
Options   :: image.Options

Signature :: enum u64be {
	// 0x89504e470d0a1a0a
	PNG = 0x89 << 56 | 'P' << 48 | 'N' << 40 | 'G' << 32 | '\r' << 24 | '\n' << 16 | 0x1a << 8 | '\n',
}

Row_Filter :: enum u8 {
	None    = 0,
	Sub     = 1,
	Up      = 2,
	Average = 3,
	Paeth   = 4,
}

PLTE_Entry :: image.RGB_Pixel

PLTE :: struct #packed {
	entries: [256]PLTE_Entry,
	used:    u16,
}

hIST :: struct #packed {
	entries: [256]u16,
	used:    u16,
}

sPLT :: struct #packed {
	name:    string,
	depth:   u8,
	entries: union {
		[][4]u8,
		[][4]u16,
	},
	used:    u16,
}

// Other chunks
tIME :: struct #packed {
	year:   u16be,
	month:  u8,
	day:    u8,
	hour:   u8,
	minute: u8,
	second: u8,
}
#assert(size_of(tIME) == 7)

CIE_1931_Raw :: struct #packed {
	x: u32be,
	y: u32be,
}

CIE_1931 :: struct #packed {
	x: f32,
	y: f32,
}

cHRM_Raw :: struct #packed {
	w: CIE_1931_Raw,
	r: CIE_1931_Raw,
	g: CIE_1931_Raw,
	b: CIE_1931_Raw,
}
#assert(size_of(cHRM_Raw) == 32)

cHRM :: struct #packed {
	w: CIE_1931,
	r: CIE_1931,
	g: CIE_1931,
	b: CIE_1931,
}
#assert(size_of(cHRM) == 32)

gAMA :: struct {
	gamma_100k: u32be, // Gamma * 100k
}
#assert(size_of(gAMA) == 4)

pHYs :: struct #packed {
	ppu_x: u32be,
	ppu_y: u32be,
	unit:  pHYs_Unit,
}
#assert(size_of(pHYs) == 9)

pHYs_Unit :: enum u8 {
	Unknown = 0,
	Meter   = 1,
}

Text :: struct {
	keyword:           string,
	keyword_localized: string,
	language:          string,
	text:              string,
}

Exif :: struct {
	byte_order: enum {
		little_endian,
		big_endian,
	},
	data: []u8,
}

iCCP :: struct {
	name:    string,
	profile: []u8,
}

sRGB_Rendering_Intent :: enum u8 {
	Perceptual            = 0,
	Relative_colorimetric = 1,
	Saturation            = 2,
	Absolute_colorimetric = 3,
}

sRGB :: struct #packed {
	intent: sRGB_Rendering_Intent,
}

ADAM7_X_ORIG    := []int{ 0,4,0,2,0,1,0 }
ADAM7_Y_ORIG    := []int{ 0,0,4,0,2,0,1 }
ADAM7_X_SPACING := []int{ 8,8,4,4,2,2,1 }
ADAM7_Y_SPACING := []int{ 8,8,8,4,4,2,2 }

// Implementation starts here

read_chunk :: proc(ctx: ^$C) -> (chunk: image.PNG_Chunk, err: Error) {
	ch, e := compress.read_data(ctx, image.PNG_Chunk_Header)
	if e != .None {
		return {}, compress.General_Error.Stream_Too_Short
	}
	chunk.header = ch

	/*
		Sanity check chunk size
	*/
	#partial switch ch.type {
	case .IDAT:
		if ch.length > MAX_IDAT_SIZE {
			return {}, image.PNG_Error.IDAT_Size_Too_Large
		}
	case:
		if ch.length > MAX_CHUNK_SIZE {
			return {}, image.PNG_Error.Invalid_Chunk_Length
		}
	}

	chunk.data, e = compress.read_slice(ctx, int(ch.length))
	if e != .None {
		return {}, compress.General_Error.Stream_Too_Short
	}

	// Compute CRC over chunk type + data
	type := (^[4]byte)(&ch.type)^
	computed_crc := hash.crc32(type[:])
	computed_crc =  hash.crc32(chunk.data, computed_crc)

	crc, e3 := compress.read_data(ctx, u32be)
	if e3 != .None {
		return {}, compress.General_Error.Stream_Too_Short
	}
	chunk.crc = crc

	if chunk.crc != u32be(computed_crc) {
		return {}, compress.General_Error.Checksum_Failed
	}
	return chunk, nil
}

copy_chunk :: proc(src: image.PNG_Chunk, allocator := context.allocator) -> (dest: image.PNG_Chunk, err: Error) {
	if int(src.header.length) != len(src.data) {
		return {}, .Invalid_Chunk_Length
	}

	dest.header = src.header
	dest.crc    = src.crc
	dest.data   = make([]u8, dest.header.length, allocator) or_return

	copy(dest.data[:], src.data[:])
	return
}

append_chunk :: proc(list: ^[dynamic]image.PNG_Chunk, src: image.PNG_Chunk, allocator := context.allocator) -> (err: Error) {
	if int(src.header.length) != len(src.data) {
		return .Invalid_Chunk_Length
	}

	c := copy_chunk(src, allocator) or_return
	length := len(list)
	append(list, c)
	if len(list) != length + 1 {
		// Resize during append failed.
		return .Unable_To_Allocate_Or_Resize
	}

	return
}

read_header :: proc(ctx: ^$C) -> (image.PNG_IHDR, Error) {
	c, e := read_chunk(ctx)
	if e != nil {
		return {}, e
	}

	header := (^image.PNG_IHDR)(raw_data(c.data))^
	// Validate IHDR
	using header
	if width == 0 || height == 0 || u128(width) * u128(height) > image.MAX_DIMENSIONS {
		return {}, .Invalid_Image_Dimensions
	}

	if compression_method != 0 {
		return {}, compress.General_Error.Unknown_Compression_Method
	}

	if filter_method != 0 {
		return {}, .Unknown_Filter_Method
	}

	if interlace_method != .None && interlace_method != .Adam7 {
		return {}, .Unknown_Interlace_Method

	}

	switch transmute(u8)color_type {
	case 0:
		/*
			Grayscale.
			Allowed bit depths: 1, 2, 4, 8 and 16.
		*/
		allowed := false
		for i in ([]u8{1, 2, 4, 8, 16}) {
			if bit_depth == i {
				allowed = true
				break
			}
		}
		if !allowed {
			return {}, .Invalid_Color_Bit_Depth_Combo
		}
	case 2, 4, 6:
		/*
			RGB, Grayscale+Alpha, RGBA.
			Allowed bit depths: 8 and 16
		*/
		if bit_depth != 8 && bit_depth != 16 {
			return {}, .Invalid_Color_Bit_Depth_Combo
		}
	case 3:
		/*
			Paletted. PLTE chunk must appear.
			Allowed bit depths: 1, 2, 4 and 8.
		*/
		allowed := false
		for i in ([]u8{1, 2, 4, 8}) {
			if bit_depth == i {
				allowed = true
				break
			}
		}
		if !allowed {
			return {}, .Invalid_Color_Bit_Depth_Combo
		}

	case:
		return {}, .Unknown_Color_Type
	}

	return header, nil
}

chunk_type_to_name :: proc(type: ^image.PNG_Chunk_Type) -> string {
	return string(([^]u8)(type)[:4])
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	ctx := &compress.Context_Memory_Input{
		input_data = data,
	}

	/*
		TODO: Add a flag to tell the PNG loader that the stream is backed by a slice.
		This way the stream reader could avoid the copy into the temp memory returned by it,
		and instead return a slice into the original memory that's already owned by the caller.
	*/
	img, err = load_from_context(ctx, options, allocator)

	return img, err
}

load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .info in options {
		options |= {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	if .alpha_drop_if_present in options && .alpha_add_if_missing in options {
		return {}, compress.General_Error.Incompatible_Options
	}

	if .do_not_expand_channels in options {
		options |= {.do_not_expand_grayscale, .do_not_expand_indexed}
	}

	if img == nil {
		img = new(Image)
	}
	img.which = .PNG

	info := new(image.PNG_Info)
	img.metadata = info

	signature, io_error := compress.read_data(ctx, Signature)
	if io_error != .None || signature != .PNG {
		return img, .Invalid_Signature
	}

	idat: []u8
	idat_b: bytes.Buffer
	defer bytes.buffer_destroy(&idat_b)

	idat_length := u64(0)

	c:	image.PNG_Chunk
	ch:     image.PNG_Chunk_Header
	e:      io.Error

	header:	image.PNG_IHDR

	// State to ensure correct chunk ordering.
	seen_ihdr := false; first := true
	seen_plte := false
	seen_bkgd := false
	seen_trns := false
	seen_idat := false
	seen_iend := false

	_plte := PLTE{}
	trns := image.PNG_Chunk{}

	final_image_channels := 0

	read_error: io.Error
	// 12 bytes is the size of a chunk with a zero-length payload.
	for read_error == .None && !seen_iend {
		// Peek at next chunk's length and type.
		// TODO: Some streams may not provide seek/read_at

		ch, e = compress.peek_data(ctx, image.PNG_Chunk_Header)
		if e != .None {
			return img, compress.General_Error.Stream_Too_Short
		}
		// name := chunk_type_to_name(&ch.type); // Only used for debug prints during development.

		#partial switch ch.type {
		case .IHDR:
			if seen_ihdr || !first {
				return {}, .IHDR_Not_First_Chunk
			}
			seen_ihdr = true

			header = read_header(ctx) or_return

			if .Paletted in header.color_type {
				// Color type 3
				img.channels = 1
				final_image_channels = 3
				img.depth    = 8
			} else if .Color in header.color_type {
				// Color image without a palette
				img.channels = 3
				final_image_channels = 3
				img.depth    = int(header.bit_depth)
			} else {
				// Grayscale
				img.channels = 1
				final_image_channels = 1
				img.depth    = int(header.bit_depth)
			}

			if .Alpha in header.color_type {
				img.channels += 1
				final_image_channels += 1
			}

			if img.channels == 0 || img.depth == 0 {
				return {}, .IHDR_Corrupt
			}

			img.width  = int(header.width)
			img.height = int(header.height)

			h := image.PNG_IHDR{
				width              = header.width,
				height             = header.height,
				bit_depth          = header.bit_depth,
				color_type         = header.color_type,
				compression_method = header.compression_method,
				filter_method      = header.filter_method,
				interlace_method   = header.interlace_method,
			}
			info.header = h

			if .return_header in options && .return_metadata not_in options && .do_not_decompress_image not_in options {
				return img, nil
			}

		case .PLTE:
			seen_plte = true
			// PLTE must appear before IDAT and can't appear for color types 0, 4.
			ct := transmute(u8)info.header.color_type
			if seen_idat || ct == 0 || ct == 4 {
				return img, .PLTE_Encountered_Unexpectedly
			}

			c = read_chunk(ctx) or_return

			if c.header.length % 3 != 0 || c.header.length > 768 {
				return img, .PLTE_Invalid_Length
			}
			plte_ok: bool
			_plte, plte_ok = plte(c)
			if !plte_ok {
				return img, .PLTE_Invalid_Length
			}

			if .return_metadata in options {
				append_chunk(&info.chunks, c) or_return
			}

		case .IDAT:
			// If we only want image metadata and don't want the pixel data, we can early out.
			if .return_metadata not_in options && .do_not_decompress_image in options {
				img.channels = final_image_channels
				return img, nil
			}
			// There must be at least 1 IDAT, contiguous if more.
			if seen_idat {
				return img, .IDAT_Must_Be_Contiguous
			}

			if idat_length > 0 {
				return img, .IDAT_Must_Be_Contiguous
			}

			next := ch.type
			for next == .IDAT {
				c = read_chunk(ctx) or_return

				bytes.buffer_write(&idat_b, c.data)
				idat_length += u64(c.header.length)

				if idat_length > MAX_IDAT_SIZE {
					return {}, image.PNG_Error.IDAT_Size_Too_Large
				}

				ch, e = compress.peek_data(ctx, image.PNG_Chunk_Header)
				if e != .None {
					return img, compress.General_Error.Stream_Too_Short
				}
				next = ch.type
			}

			idat = bytes.buffer_to_bytes(&idat_b)
			if int(idat_length) != len(idat) {
				return {}, .IDAT_Corrupt
			}
			seen_idat = true

		case .IEND:
			c = read_chunk(ctx) or_return
			seen_iend = true

		case .bKGD:
			c = read_chunk(ctx) or_return
			seen_bkgd = true
			if .return_metadata in options {
				append_chunk(&info.chunks, c) or_return
			}

			ct := transmute(u8)info.header.color_type
			switch ct {
				case 3: // Indexed color
					if c.header.length != 1 {
						return {}, .BKGD_Invalid_Length
					}
					col := _plte.entries[c.data[0]]
					img.background = [3]u16{
						u16(col[0]) << 8 | u16(col[0]),
						u16(col[1]) << 8 | u16(col[1]),
						u16(col[2]) << 8 | u16(col[2]),
					}
				case 0, 4: // Grayscale, with and without Alpha
					if c.header.length != 2 {
						return {}, .BKGD_Invalid_Length
					}
					col := u16(mem.slice_data_cast([]u16be, c.data[:])[0])
					img.background = [3]u16{col, col, col}
				case 2, 6: // Color, with and without Alpha
					if c.header.length != 6 {
						return {}, .BKGD_Invalid_Length
					}
					col := mem.slice_data_cast([]u16be, c.data[:])
					img.background = [3]u16{u16(col[0]), u16(col[1]), u16(col[2])}
			}

		case .tRNS:
			c = read_chunk(ctx) or_return

			if .Alpha in info.header.color_type {
				return img, .TRNS_Encountered_Unexpectedly
			}

			if .return_metadata in options {
				append_chunk(&info.chunks, c) or_return
			}

			/*
				This makes the image one with transparency, so set it to +1 here,
				even if we need we leave img.channels alone for the defilterer's
				sake. If we early because the user just cares about metadata,
				we'll set it to 'final_image_channels'.
			*/

			final_image_channels += 1
			seen_trns = true

			if .Paletted in header.color_type {
				if len(c.data) > 256 {
					return img, .TNRS_Invalid_Length
				}
			} else if .Color in header.color_type {
				if len(c.data) != 6 {
					return img, .TNRS_Invalid_Length
				}
			} else if len(c.data) != 2 {
				return img, .TNRS_Invalid_Length
			}

			if info.header.bit_depth < 8 && .Paletted not_in info.header.color_type {
				// Rescale tRNS data so key matches intensity
				dsc   := depth_scale_table
				scale := dsc[info.header.bit_depth]
				if scale != 1 {
					key := (^u16be)(raw_data(c.data))^ * u16be(scale)
					c.data = []u8{0, u8(key & 255)}
				}
			}

			trns = c

		case .iDOT, .CgBI:
			/*
				iPhone PNG bastardization that doesn't adhere to spec with broken IDAT chunk.
				We're not going to add support for it. If you have the misfortune of coming
				across one of these files, use a utility to defry it.
			*/
			return img, .Image_Does_Not_Adhere_to_Spec

		case:
			// Unhandled type
			c = read_chunk(ctx) or_return
			if .return_metadata in options {
				append_chunk(&info.chunks, c) or_return
			}

			first = false
		}
	}

	if .do_not_decompress_image in options {
		img.channels = final_image_channels
		return img, nil
	}

	if !seen_idat {
		return img, .IDAT_Missing
	}

	if .Paletted in header.color_type && !seen_plte {
		return img, .PLTE_Missing
	}

	/*
		Calculate the expected output size, to help `inflate` make better decisions about the output buffer.
		We'll also use it to check the returned buffer size is what we expected it to be.

		Let's calcalate the expected size of the IDAT based on its dimensions, and whether or not it's interlaced.
	*/
	expected_size: int

	if header.interlace_method != .Adam7 {
		expected_size = compute_buffer_size(int(header.width), int(header.height), int(img.channels), int(header.bit_depth), 1)
	} else {
		/*
			Because Adam7 divides the image up into sub-images, and each scanline must start
			with a filter byte, Adam7 interlaced images can have a larger raw size.
		*/
		for p := 0; p < 7; p += 1 {
			x := (int(header.width)  - ADAM7_X_ORIG[p] + ADAM7_X_SPACING[p] - 1) / ADAM7_X_SPACING[p]
			y := (int(header.height) - ADAM7_Y_ORIG[p] + ADAM7_Y_SPACING[p] - 1) / ADAM7_Y_SPACING[p]
			if x > 0 && y > 0 {
				expected_size += compute_buffer_size(int(x), int(y), int(img.channels), int(header.bit_depth), 1)
			}
		}
	}

	buf: bytes.Buffer
	zlib_error := zlib.inflate(idat, &buf, false, expected_size)
	defer bytes.buffer_destroy(&buf)

	if zlib_error != nil {
		return {}, zlib_error
	}

	buf_len := len(buf.buf)
	if expected_size != buf_len {
		return {}, .IDAT_Corrupt
	}

	/*
		Defilter just cares about the raw number of image channels present.
		So, we'll save the old value of img.channels we return to the user
		as metadata, and set it instead to the raw number of channels.
	*/
	defilter_error := defilter(img, &buf, &header, options)
	if defilter_error != nil {
		bytes.buffer_destroy(&img.pixels)
		return {}, defilter_error
	}

	if .Paletted in header.color_type && .do_not_expand_indexed in options {
		return img, nil
	}
	if .Color not_in header.color_type && .do_not_expand_grayscale in options {
		return img, nil
	}

	/*
		Now we're going to optionally apply various post-processing stages,
		to for example expand grayscale, apply a palette, premultiply alpha, etc.
	*/
	raw_image_channels := img.channels
	out_image_channels := 3

	/*
		To give ourselves less options to test, we'll knock out
		`.blend_background` and `seen_bkgd` if we haven't seen both.
	*/
	if !(seen_bkgd && .blend_background in options) {
		options -= {.blend_background}
		seen_bkgd = false
	}

	if seen_trns || .Alpha in info.header.color_type || .alpha_add_if_missing in options {
		out_image_channels = 4
	}

	if .alpha_drop_if_present in options {
		out_image_channels = 3
	}

	if seen_bkgd && .blend_background in options && .alpha_add_if_missing not_in options {
		out_image_channels = 3
	}

	add_alpha   := (seen_trns && .alpha_drop_if_present not_in options) || (.alpha_add_if_missing in options)
	premultiply := .alpha_premultiply in options || seen_bkgd

	img.channels = out_image_channels

	if .Paletted in header.color_type {
		temp := img.pixels
		defer bytes.buffer_destroy(&temp)

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 8)
		t := bytes.Buffer{}
		if resize(&t.buf, dest_raw_size) != nil {
			return {}, .Unable_To_Allocate_Or_Resize
		}

		// If we don't have transparency or drop it without applying it, we can do this:
		if (!seen_trns || (seen_trns && .alpha_drop_if_present in options && .alpha_premultiply not_in options)) && .alpha_add_if_missing not_in options {
			output := mem.slice_data_cast([]image.RGB_Pixel, t.buf[:])
			for pal_idx, idx in temp.buf {
				output[idx] = _plte.entries[pal_idx]
			}
		} else if add_alpha || .alpha_drop_if_present in options {
			bg := PLTE_Entry{0, 0, 0}
			if premultiply && seen_bkgd {
				c16 := img.background.([3]u16)
				bg = {u8(c16.r), u8(c16.g), u8(c16.b)}
			}

			no_alpha := (.alpha_drop_if_present in options || premultiply) && .alpha_add_if_missing not_in options
			blend_background := seen_bkgd && .blend_background in options

			if no_alpha {
				output := mem.slice_data_cast([]image.RGB_Pixel, t.buf[:])
				for orig, idx in temp.buf {
					c := _plte.entries[orig]
					a := int(orig) < len(trns.data) ? trns.data[orig] : 255

					if blend_background {
						output[idx] = image.blend(c, a, bg)
					} else if premultiply {
						output[idx] = image.blend(PLTE_Entry{}, a, c)
					}
				}
			} else {
				output := mem.slice_data_cast([]image.RGBA_Pixel, t.buf[:])
				for orig, idx in temp.buf {
					c := _plte.entries[orig]
					a := int(orig) < len(trns.data) ? trns.data[orig] : 255

					if blend_background {
						c = image.blend(c, a, bg)
						a = 255
					} else if premultiply {
						c = image.blend(PLTE_Entry{}, a, c)
					}

					output[idx] = {c.r, c.g, c.b, u8(a)}
				}
			}
		} else {
			unreachable()
		}

		img.pixels = t

	} else if img.depth == 16 {
		// Check if we need to do something.
		if raw_image_channels == out_image_channels {
			// If we have 3 in and 3 out, or 4 in and 4 out without premultiplication...
			if raw_image_channels == 4 && .alpha_premultiply not_in options && !seen_bkgd {
				// Then we're done.
				return img, nil
			}
		}

		temp := img.pixels
		defer bytes.buffer_destroy(&temp)

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 16)
		t := bytes.Buffer{}
		if resize(&t.buf, dest_raw_size) != nil {
			return {}, .Unable_To_Allocate_Or_Resize
		}

		p16 := mem.slice_data_cast([]u16, temp.buf[:])
		o16 := mem.slice_data_cast([]u16, t.buf[:])

		switch raw_image_channels {
		case 1:
			// Gray without Alpha. Might have tRNS alpha.
			key   := u16(0)
			if seen_trns {
				key = mem.slice_data_cast([]u16, trns.data)[0]
			}

			for len(p16) > 0 {
				r := p16[0]

				alpha := u16(1) // Default to full opaque

				if seen_trns {
					if r == key {
						if seen_bkgd {
							c := img.background.([3]u16)
							r = c[0]
						} else {
							alpha = 0 // Keyed transparency
						}
					}
				}

				if premultiply {
					o16[0] = r * alpha
					o16[1] = r * alpha
					o16[2] = r * alpha
				} else {
					o16[0] = r
					o16[1] = r
					o16[2] = r
				}

				if out_image_channels == 4 {
					o16[3] = alpha * 65535
				}

				p16 = p16[1:]
				o16 = o16[out_image_channels:]
			}
		case 2:
			// Gray with alpha, we shouldn't have a tRNS chunk.
			bg := f32(0.0)
			if seen_bkgd {
				bg = f32(img.background.([3]u16)[0])
			}

			for len(p16) > 0 {
				r := p16[0]
				if seen_bkgd {
					alpha := f32(p16[1]) / f32(65535)
					c := u16(f32(r) * alpha + (1.0 - alpha) * bg)
					o16[0] = c
					o16[1] = c
					o16[2] = c
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					p16[1] = 65535
				} else if premultiply {
					alpha := p16[1]
					c := u16(f32(r) * f32(alpha) / f32(65535))
					o16[0] = c
					o16[1] = c
					o16[2] = c
				} else {
					o16[0] = r
					o16[1] = r
					o16[2] = r
				}

				if out_image_channels == 4 {
					o16[3] = p16[1]
				}

				p16 = p16[2:]
				o16 = o16[out_image_channels:]
			}
		case 3:
			/*
				Color without Alpha.
				We may still have a tRNS chunk or `.alpha_add_if_missing`.
			*/

			key: []u16
			if seen_trns {
				key = mem.slice_data_cast([]u16, trns.data)
			}

			for len(p16) > 0 {
				r     := p16[0]
				g     := p16[1]
				b     := p16[2]

				alpha := u16(1) // Default to full opaque

				if seen_trns {
					if r == key[0] && g == key[1] && b == key[2] {
						if seen_bkgd {
							c := img.background.([3]u16)
							r = c[0]
							g = c[1]
							b = c[2]
						} else {
							alpha = 0 // Keyed transparency
						}
					}
				}

				if premultiply {
					o16[0] = r * alpha
					o16[1] = g * alpha
					o16[2] = b * alpha
				} else {
					o16[0] = r
					o16[1] = g
					o16[2] = b
				}

				if out_image_channels == 4 {
					o16[3] = alpha * 65535
				}

				p16 = p16[3:]
				o16 = o16[out_image_channels:]
			}
		case 4:
			// Color with Alpha, can't have tRNS.
			for len(p16) > 0 {
				r     := p16[0]
				g     := p16[1]
				b     := p16[2]
				a     := p16[3]

				if seen_bkgd {
					alpha := f32(a) / 65535.0
					c  := img.background.([3]u16)
					rb := f32(c[0]) * (1.0 - alpha)
					gb := f32(c[1]) * (1.0 - alpha)
					bb := f32(c[2]) * (1.0 - alpha)

					o16[0] = u16(f32(r) * alpha + rb)
					o16[1] = u16(f32(g) * alpha + gb)
					o16[2] = u16(f32(b) * alpha + bb)
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					a = 65535
				} else if premultiply {
					alpha := f32(a) / 65535.0
					o16[0] = u16(f32(r) * alpha)
					o16[1] = u16(f32(g) * alpha)
					o16[2] = u16(f32(b) * alpha)
				} else {
					o16[0] = r
					o16[1] = g
					o16[2] = b
				}

				if out_image_channels == 4 {
					o16[3] = a
				}

				p16 = p16[4:]
				o16 = o16[out_image_channels:]
			}
		case:
			panic("We should never seen # channels other than 1-4 inclusive.")
		}

		img.pixels = t
		img.channels = out_image_channels

	} else if img.depth == 8 {
		// Check if we need to do something.
		if raw_image_channels == out_image_channels {
			// If we have 3 in and 3 out, or 4 in and 4 out without premultiplication...
			if !premultiply {
				// Then we're done.
				return img, nil
			}
		}

		temp := img.pixels
		defer bytes.buffer_destroy(&temp)

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 8)
		t := bytes.Buffer{}
		if resize(&t.buf, dest_raw_size) != nil {
			return {}, .Unable_To_Allocate_Or_Resize
		}

		p := temp.buf[:]
		o := t.buf[:]

		switch raw_image_channels {
		case 1:
			// Gray without Alpha. Might have tRNS alpha.
			key   := u8(0)
			if seen_trns {
				key = u8(mem.slice_data_cast([]u16be, trns.data)[0])
			}

			for len(p) > 0 {
				r     := p[0]
				alpha := u8(1)

				if seen_trns {
					if r == key {
						if seen_bkgd {
							bc := img.background.([3]u16)
							r = u8(bc[0])
						} else {
							alpha = 0 // Keyed transparency
						}
					}
					if premultiply {
						r *= alpha
					}
				}
				o[0] = r
				o[1] = r
				o[2] = r

				if out_image_channels == 4 {
					o[3] = alpha * 255
				}

				p = p[1:]
				o = o[out_image_channels:]
			}
		case 2:
			// Gray with alpha, we shouldn't have a tRNS chunk.
			bg := f32(0.0)
			if seen_bkgd {
				bg = f32(img.background.([3]u16)[0])
			}

			for len(p) > 0 {
				r := p[0]
				if seen_bkgd {
					alpha := f32(p[1]) / f32(255)
					c := u8(f32(r) * alpha + (1.0 - alpha) * bg)
					o[0] = c
					o[1] = c
					o[2] = c
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					p[1] = 255
				} else if .alpha_premultiply in options {
					alpha := p[1]
					c := u8(f32(r) * f32(alpha) / f32(255))
					o[0] = c
					o[1] = c
					o[2] = c
				} else {
					o[0] = r
					o[1] = r
					o[2] = r
				}

				if out_image_channels == 4 {
					o[3] = p[1]
				}

				p = p[2:]
				o = o[out_image_channels:]
			}
		case 3:
			// Color without Alpha. We may still have a tRNS chunk
			key: []u8
			if seen_trns {
				/*
					For 8-bit images, the tRNS chunk still contains a triple in u16be.
					We use only the low byte in this case.
				*/
				key = []u8{trns.data[1], trns.data[3], trns.data[5]}
			}

			for len(p) > 0 {
				r     := p[0]
				g     := p[1]
				b     := p[2]

				alpha := u8(1) // Default to full opaque

				if seen_trns {
					if r == key[0] && g == key[1] && b == key[2] {
						if seen_bkgd {
							c := img.background.([3]u16)
							r = u8(c[0])
							g = u8(c[1])
							b = u8(c[2])
						} else {
							alpha = 0 // Keyed transparency
						}
					}

					if premultiply {
						r *= alpha
						g *= alpha
						b *= alpha
					}
				}

				o[0] = r
				o[1] = g
				o[2] = b

				if out_image_channels == 4 {
					o[3] = alpha * 255
				}

				p = p[3:]
				o = o[out_image_channels:]
			}
		case 4:
			// Color with Alpha, can't have tRNS.
			for len(p) > 0 {
				r     := p[0]
				g     := p[1]
				b     := p[2]
				a     := p[3]
				if seen_bkgd {
					alpha := f32(a) / 255.0
					c  := img.background.([3]u16)
					rb := f32(c[0]) * (1.0 - alpha)
					gb := f32(c[1]) * (1.0 - alpha)
					bb := f32(c[2]) * (1.0 - alpha)

					o[0] = u8(f32(r) * alpha + rb)
					o[1] = u8(f32(g) * alpha + gb)
					o[2] = u8(f32(b) * alpha + bb)
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					a = 255
				} else if premultiply {
					alpha := f32(a) / 255.0
					o[0] = u8(f32(r) * alpha)
					o[1] = u8(f32(g) * alpha)
					o[2] = u8(f32(b) * alpha)
				} else {
					o[0] = r
					o[1] = g
					o[2] = b
				}

				if out_image_channels == 4 {
					o[3] = a
				}

				p = p[4:]
				o = o[out_image_channels:]
			}
		case:
			panic("We should never seen # channels other than 1-4 inclusive.")
		}

		img.pixels = t
		img.channels = out_image_channels

	} else {
		/*
			This may change if we ever don't expand 1, 2 and 4 bit images. But, those raw
			returns will likely bypass this processing pipeline.
		*/
		panic("We should never see bit depths other than 8, 16 and 'Paletted' here.")
	}

	return img, nil
}

filter_paeth :: #force_inline proc(left, up, up_left: u8) -> u8 {
	aa, bb, cc := i16(left), i16(up), i16(up_left)
	p  := aa + bb - cc
	pa := abs(p - aa)
	pb := abs(p - bb)
	pc := abs(p - cc)
	if pa <= pb && pa <= pc {
		return left
	}
	if pb <= pc {
		return up
	}
	return up_left
}

Filter_Params :: struct #packed {
	src:      []u8,
	dest:     []u8,
	width:    int,
	height:   int,
	depth:    int,
	channels: int,
	rescale:  bool,
}

depth_scale_table :: []u8{0, 0xff, 0x55, 0, 0x11, 0,0,0, 0x01}

// @(optimization_mode="speed")
defilter_8 :: proc(params: ^Filter_Params) -> (ok: bool) {

	using params
	row_stride := channels * width

	// TODO: See about doing a Duff's #unroll where practicable

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride, context.temp_allocator)
	ok = true

	for _ in 0..<height {
		nk := row_stride - channels

		filter := Row_Filter(src[0]); src = src[1:]
		switch filter {
		case .None:
			copy(dest, src[:row_stride])
		case .Sub:
			for i := 0; i < channels; i += 1 {
				dest[i] = src[i]
			}
			for k := 0; k < nk; k += 1 {
				dest[channels+k] = (src[channels+k] + dest[k]) & 255
			}
		case .Up:
			for k := 0; k < row_stride; k += 1 {
				dest[k] = (src[k] + up[k]) & 255
			}
		case .Average:
			for i := 0; i < channels; i += 1 {
				avg := up[i] >> 1
				dest[i] = (src[i] + avg) & 255
			}
			for k := 0; k < nk; k += 1 {
				avg := u8((u16(up[channels+k]) + u16(dest[k])) >> 1)
				dest[channels+k] = (src[channels+k] + avg) & 255
			}
		case .Paeth:
			for i := 0; i < channels; i += 1 {
				paeth := filter_paeth(0, up[i], 0)
				dest[i] = (src[i] + paeth) & 255
			}
			for k := 0; k < nk; k += 1 {
				paeth := filter_paeth(dest[k], up[channels+k], up[k])
				dest[channels+k] = (src[channels+k] + paeth) & 255
			}
		case:
			return false
		}

		src     = src[row_stride:]
		up      = dest
		dest    = dest[row_stride:]
	}
	return
}

// @(optimization_mode="speed")
defilter_less_than_8 :: proc(params: ^Filter_Params) -> bool #no_bounds_check {

	using params

	row_stride_in  := ((channels * width * depth) + 7) >> 3
	row_stride_out := channels * width

	// Store defiltered bytes rightmost so we can widen in-place.
	row_offset := row_stride_out - row_stride_in
	// Save original dest because we'll need it for the bit widening.
	orig_dest := dest

	// TODO: See about doing a Duff's #unroll where practicable

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride_out, context.temp_allocator)

	#no_bounds_check for _ in 0..<height {
		nk := row_stride_in - channels

		dest = dest[row_offset:]

		filter := Row_Filter(src[0]); src = src[1:]
		switch filter {
		case .None:
			copy(dest, src[:row_stride_in])
		case .Sub:
			for i in 0..=channels {
				dest[i] = src[i]
			}
			for k in 0..=nk {
				dest[channels+k] = (src[channels+k] + dest[k]) & 255
			}
		case .Up:
			for k in 0..=row_stride_in {
				dest[k] = (src[k] + up[k]) & 255
			}
		case .Average:
			for i in 0..=channels {
				avg := up[i] >> 1
				dest[i] = (src[i] + avg) & 255
			}
			for k in 0..=nk {
				avg := u8((u16(up[channels+k]) + u16(dest[k])) >> 1)
				dest[channels+k] = (src[channels+k] + avg) & 255
			}
		case .Paeth:
			for i in 0..=channels {
				paeth := filter_paeth(0, up[i], 0)
				dest[i] = (src[i] + paeth) & 255
			}
			for k in 0..=nk {
				paeth := filter_paeth(dest[k], up[channels+k], up[k])
				dest[channels+k] = (src[channels+k] + paeth) & 255
			}
		case:
			return false
		}

		src  = src[row_stride_in:]
		up   = dest
		dest = dest[row_stride_in:]
	}

	// Let's expand the bits
	dest = orig_dest

	// Don't rescale the bits if we're a paletted image.
	dsc := depth_scale_table
	scale := rescale ? dsc[depth] : 1

	/*
		For sBIT support we should probably set scale to 1 and mask the significant bits.
		Seperately, do we want to support packed pixels? i.e defiltering only, no expansion?
		If so, all we have to do is call defilter_8 for that case and not set img.depth to 8.
	*/

	for j := 0; j < height; j += 1 {
		src = dest[row_offset:]

		switch depth {
		case 4:
			k := row_stride_out
			for ; k >= 2; k -= 2 {
				c := src[0]
				dest[0] = scale * (c >> 4)
				dest[1] = scale * (c & 15)
				dest = dest[2:]; src = src[1:]
			}
			if k > 0 {
				c := src[0]
				dest[0] = scale * (c >> 4)
				dest = dest[1:]
			}
		case 2:
			k := row_stride_out
			for ; k >= 4; k -= 4 {
				c := src[0]
				dest[0] = scale * ((c >> 6)    )
				dest[1] = scale * ((c >> 4) & 3)
				dest[2] = scale * ((c >> 2) & 3)
				dest[3] = scale * ((c     ) & 3)
				dest = dest[4:]; src = src[1:]
			}
			if k > 0 {
				c := src[0]
				dest[0] = scale * ((c >> 6)    )
				if k > 1 {
					dest[1] = scale * ((c >> 4) & 3)
				}
				if k > 2 {
					dest[2] = scale * ((c >> 2) & 3)
				}
				dest = dest[k:]
			}
		case 1:
			k := row_stride_out
			for ; k >= 8; k -= 8 {
				c := src[0]
				dest[0] = scale * ((c >> 7)    )
				dest[1] = scale * ((c >> 6) & 1)
				dest[2] = scale * ((c >> 5) & 1)
				dest[3] = scale * ((c >> 4) & 1)
				dest[4] = scale * ((c >> 3) & 1)
				dest[5] = scale * ((c >> 2) & 1)
				dest[6] = scale * ((c >> 1) & 1)
				dest[7] = scale * ((c     ) & 1)
				dest = dest[8:]; src = src[1:]
			}
			if k > 0 {
				c := src[0]
				dest[0] = scale * ((c >> 7)    )
				if k > 1 {
					dest[1] = scale * ((c >> 6) & 1)
				}
				if k > 2 {
					dest[2] = scale * ((c >> 5) & 1)
				}
				if k > 3 {
					dest[3] = scale * ((c >> 4) & 1)
				}
				if k > 4 {
					dest[4] = scale * ((c >> 3) & 1)
				}
				if k > 5 {
					dest[5] = scale * ((c >> 2) & 1)
				}
				if k > 6 {
					dest[6] = scale * ((c >> 1) & 1)
				}
				dest = dest[k:]

			}

		}
	}

	return true
}

// @(optimization_mode="speed")
defilter_16 :: proc(params: ^Filter_Params) -> bool {
	using params

	stride := channels * 2
	row_stride := width * stride

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// TODO: See about doing a Duff's #unroll where practicable
	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride, context.temp_allocator)

	for y := 0; y < height; y += 1 {
		nk := row_stride - stride

		filter := Row_Filter(src[0]); src = src[1:]
		switch filter {
		case .None:
			copy(dest, src[:row_stride])
		case .Sub:
			for i := 0; i < stride; i += 1 {
				dest[i] = src[i]
			}
			for k := 0; k < nk; k += 1 {
				dest[stride+k] = (src[stride+k] + dest[k]) & 255
			}
		case .Up:
			for k := 0; k < row_stride; k += 1 {
				dest[k] = (src[k] + up[k]) & 255
			}
		case .Average:
			for i := 0; i < stride; i += 1 {
				avg := up[i] >> 1
				dest[i] = (src[i] + avg) & 255
			}
			for k := 0; k < nk; k += 1 {
				avg := u8((u16(up[stride+k]) + u16(dest[k])) >> 1)
				dest[stride+k] = (src[stride+k] + avg) & 255
			}
		case .Paeth:
			for i := 0; i < stride; i += 1 {
				paeth := filter_paeth(0, up[i], 0)
				dest[i] = (src[i] + paeth) & 255
			}
			for k := 0; k < nk; k += 1 {
				paeth := filter_paeth(dest[k], up[stride+k], up[k])
				dest[stride+k] = (src[stride+k] + paeth) & 255
			}
		case:
			return false
		}

		src     = src[row_stride:]
		up      = dest
		dest    = dest[row_stride:]
	}

	return true
}

defilter :: proc(img: ^Image, filter_bytes: ^bytes.Buffer, header: ^image.PNG_IHDR, options: Options) -> (err: Error) {
	input    := bytes.buffer_to_bytes(filter_bytes)
	width    := int(header.width)
	height   := int(header.height)
	channels := int(img.channels)
	depth    := int(header.bit_depth)
	rescale  := .Color not_in header.color_type

	bytes_per_channel := depth == 16 ? 2 : 1

	num_bytes := compute_buffer_size(width, height, channels, depth == 16 ? 16 : 8)
	if resize(&img.pixels.buf, num_bytes) != nil {
		return .Unable_To_Allocate_Or_Resize
	}

	filter_ok: bool

	if header.interlace_method != .Adam7 {
		params := Filter_Params{
			src      = input,
			width    = width,
			height   = height,
			channels = channels,
			depth    = depth,
			rescale  = rescale,
			dest     = img.pixels.buf[:],
		}

		if depth == 8 {
			filter_ok = defilter_8(&params)
		} else if depth < 8 {
			filter_ok = defilter_less_than_8(&params)
			img.depth = 8
		} else {
			filter_ok = defilter_16(&params)
		}
		if !filter_ok {
			// Caller will destroy buffer for us.
			return .Unknown_Filter_Method
		}
	} else {
		/*
			For deinterlacing we need to make a temporary buffer, defiilter part of the image,
			and copy that back into the actual output buffer.
		*/

		for p := 0; p < 7; p += 1 {
			i,j,x,y: int
			x = (width  - ADAM7_X_ORIG[p] + ADAM7_X_SPACING[p] - 1) / ADAM7_X_SPACING[p]
			y = (height - ADAM7_Y_ORIG[p] + ADAM7_Y_SPACING[p] - 1) / ADAM7_Y_SPACING[p]
			if x > 0 && y > 0 {
				temp: bytes.Buffer
				temp_len := compute_buffer_size(x, y, channels, depth == 16 ? 16 : 8)
				if resize(&temp.buf, temp_len) != nil {
					return .Unable_To_Allocate_Or_Resize
				}

				params := Filter_Params{
					src      = input,
					width    = x,
					height   = y,
					channels = channels,
					depth    = depth,
					rescale  = rescale,
					dest     = temp.buf[:],
				}

				if depth == 8 {
					filter_ok = defilter_8(&params)
				} else if depth < 8 {
					filter_ok = defilter_less_than_8(&params)
					img.depth = 8
				} else {
					filter_ok = defilter_16(&params)
				}

				if !filter_ok {
					// Caller will destroy buffer for us.
					return .Unknown_Filter_Method
				}

				t := temp.buf[:]
				for j = 0; j < y; j += 1 {
					for i = 0; i < x; i += 1 {
						out_y := j * ADAM7_Y_SPACING[p] + ADAM7_Y_ORIG[p]
						out_x := i * ADAM7_X_SPACING[p] + ADAM7_X_ORIG[p]

						out_off := out_y * width * channels * bytes_per_channel
						out_off += out_x * channels * bytes_per_channel

						for z := 0; z < channels * bytes_per_channel; z += 1 {
							img.pixels.buf[out_off + z] = t[z]
						}
						t = t[channels * bytes_per_channel:]
					}
				}
				bytes.buffer_destroy(&temp)
				input_stride := compute_buffer_size(x, y, channels, depth, 1)
				input = input[input_stride:]
			}
		}
	}
	when ODIN_ENDIAN == .Little {
		if img.depth == 16 {
			// The pixel components are in Big Endian. Let's byteswap.
			input  := mem.slice_data_cast([]u16be, img.pixels.buf[:])
			output := mem.slice_data_cast([]u16  , img.pixels.buf[:])
			#no_bounds_check for v, i in input {
				output[i] = u16(v)
			}
		}
	}

	return nil
}

@(init, private)
_register :: proc() {
	image.register(.PNG, load_from_bytes, destroy)
}