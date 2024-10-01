/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		Benoit Jacquier: tga loader
*/


// package tga implements a TGA image writer for 8-bit RGB and RGBA images.
package tga

import "core:mem"
import "core:image"
import "core:bytes"
import "core:compress"
import "core:strings"

// TODO: alpha_premultiply support

Error   :: image.Error
Image   :: image.Image
Options :: image.Options

GA_Pixel   :: image.GA_Pixel
RGB_Pixel  :: image.RGB_Pixel
RGBA_Pixel :: image.RGBA_Pixel

save_to_buffer  :: proc(output: ^bytes.Buffer, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if img == nil {
		return .Invalid_Input_Image
	}

	if output == nil {
		return .Invalid_Output
	}

	pixels := img.width * img.height
	if pixels == 0 || pixels > image.MAX_DIMENSIONS || img.width > 65535 || img.height > 65535 {
		return .Invalid_Input_Image
	}

	// Our TGA writer supports only 8-bit images with 3 or 4 channels.
	if img.depth != 8 || img.channels < 3 || img.channels > 4 {
		return .Invalid_Input_Image
	}

	if img.channels * pixels != len(img.pixels.buf) {
		return .Invalid_Input_Image
	}

	written := 0

	// Calculate and allocate necessary space.
	necessary := pixels * img.channels + size_of(image.TGA_Header)

	if resize(&output.buf, necessary) != nil {
		return .Unable_To_Allocate_Or_Resize
	}

	header := image.TGA_Header{
		data_type_code   = .Uncompressed_RGB,
		dimensions       = {u16le(img.width), u16le(img.height)},
		bits_per_pixel   = u8(img.depth * img.channels),
		image_descriptor = 1 << 5, // Origin is top left.
	}
	header_bytes := transmute([size_of(image.TGA_Header)]u8)header

	copy(output.buf[written:], header_bytes[:])
	written += size_of(image.TGA_Header)

	/*
		Encode loop starts here.
	*/
	if img.channels == 3 {
		pix := mem.slice_data_cast([]RGB_Pixel, img.pixels.buf[:])
		out := mem.slice_data_cast([]RGB_Pixel, output.buf[written:])
		for p, i in pix {
			out[i] = p.bgr
		}
	} else if img.channels == 4 {
		pix := mem.slice_data_cast([]RGBA_Pixel, img.pixels.buf[:])
		out := mem.slice_data_cast([]RGBA_Pixel, output.buf[written:])
		for p, i in pix {
			out[i] = p.bgra
		}
	}
	return nil
}

load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .alpha_premultiply in options {
		return nil, .Unsupported_Option
	}

	if .info in options {
		options += {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	// First check for a footer.
	filesize := compress.input_size(ctx) or_return

	footer: image.TGA_Footer
	have_valid_footer := false

	extension: image.TGA_Extension
	have_valid_extension := false

	if filesize >= size_of(image.TGA_Header) + size_of(image.TGA_Footer) {
		if f, f_err := compress.peek_data(ctx, image.TGA_Footer, filesize - i64(size_of(image.TGA_Footer))); f_err == .None {
			if string(f.signature[:]) == image.New_TGA_Signature {
				have_valid_footer = true
				footer = f

				if i64(footer.extension_area_offset) + i64(size_of(image.TGA_Extension)) < filesize {
					if e, e_err := compress.peek_data(ctx, image.TGA_Extension, footer.extension_area_offset); e_err == .None {
						if e.extension_size == size_of(image.TGA_Extension) {
							have_valid_extension = true
							extension = e
						}
					}
				}
			}
		}
	}

	header := image.read_data(ctx, image.TGA_Header) or_return

	// Header checks
	rle_encoding  := false
	color_mapped  := false
	black_white   := false
	src_channels  := 0
	dest_depth    := header.bits_per_pixel
	dest_channels := 0

	#partial switch header.data_type_code {
	// Supported formats: RGB(A), RGB(A) RLE
	case .Compressed_RGB:
		rle_encoding = true
	case .Uncompressed_RGB:
		// Intentionally blank
	case .Uncompressed_Black_White:
		black_white  = true
		dest_depth   = 24
	case .Uncompressed_Color_Mapped:
		color_mapped = true
	case .Compressed_Color_Mapped:
		color_mapped = true
		rle_encoding = true
	case .Compressed_Black_White:
		black_white  = true
		rle_encoding = true
		dest_depth   = 24

	case:
		return nil, .Unsupported_Format
	}

	if color_mapped {
		if header.color_map_type != 1 {
			return nil, .Unsupported_Format
		}
		dest_depth = header.color_map_depth

		// Expect LUT entry index to be 8 bits
		if header.bits_per_pixel != 8 || header.color_map_origin != 0 || header.color_map_length > 256 {
			return nil, .Unsupported_Format
		}
	}

	switch dest_depth {
	case 15: // B5G5R5
		src_channels  = 2
		dest_channels = 3
		if color_mapped {
			src_channels = 1
		}
	case 16: // B5G5R5A1
		src_channels  = 2
		dest_channels = 3 // Alpha bit is dodgy in TGA, so we ignore it.
		if color_mapped {
			src_channels = 1
		}
	case 24: // RGB8
		src_channels  = 1 if (color_mapped || black_white) else 3
		dest_channels = 3
	case 32: // RGBA8
		src_channels  = 4 if !color_mapped else 1
		dest_channels = 4

	case:
		return nil, .Unsupported_Format
	}

	if header.image_descriptor & IMAGE_DESCRIPTOR_INTERLEAVING_MASK != 0 {
		return nil, .Unsupported_Format
	}

	if int(header.dimensions[0]) * int(header.dimensions[1]) > image.MAX_DIMENSIONS {
		return nil, .Image_Dimensions_Too_Large
	}

	if img == nil {
		img = new(Image)
	}

	defer if err != nil {
		destroy(img)
	}

	img.which = .TGA
	img.channels = 4 if .alpha_add_if_missing  in options else dest_channels
	img.channels = 3 if .alpha_drop_if_present in options else img.channels

	img.depth  = 8
	img.width  = int(header.dimensions[0])
	img.height = int(header.dimensions[1])

	// Read Image ID if present
	image_id := ""
	if _id, e := compress.read_slice(ctx, int(header.id_length)); e != .None {
		return img, .Corrupt
	} else {
		if .return_metadata in options {
			id := strings.trim_right_null(string(_id))
			image_id = strings.clone(id)
		}
	}

	color_map := make([]RGBA_Pixel, header.color_map_length)
	defer delete(color_map)

	if color_mapped {
		switch header.color_map_depth {
		case 16:
			for i in 0..<header.color_map_length {
				if lut, lut_err := compress.read_data(ctx, GA_Pixel); lut_err != .None {
					return img, .Corrupt
				} else {
					color_map[i].rg = lut
					color_map[i].ba = 255
				}
			}

		case 24:
			for i in 0..<header.color_map_length {
				if lut, lut_err := compress.read_data(ctx, RGB_Pixel); lut_err != .None {
					return img, .Corrupt
				} else {
					color_map[i].rgb = lut
					color_map[i].a   = 255
				}
			}

		case 32:
			for i in 0..<header.color_map_length {
				if lut, lut_err := compress.read_data(ctx, RGBA_Pixel); lut_err != .None {
					return img, .Corrupt
				} else {
					color_map[i] = lut
				}
			}
		}
	}

	if .return_metadata in options {
		info := new(image.TGA_Info)
		info.header   = header
		info.image_id = image_id
		if have_valid_footer {
			info.footer = footer
		}
		if have_valid_extension {
			info.extension = extension
		}
		img.metadata = info
	}

	if .do_not_decompress_image in options {
		return img, nil
	}

	if resize(&img.pixels.buf, dest_channels * img.width * img.height) != nil {
		return img, .Unable_To_Allocate_Or_Resize
	}

	origin_is_top        := header.image_descriptor & IMAGE_DESCRIPTOR_TOP_MASK   != 0
	origin_is_left       := header.image_descriptor & IMAGE_DESCRIPTOR_RIGHT_MASK == 0
	rle_repetition_count := 0
	read_pixel           := true
	is_packet_rle        := false

	pixel: RGBA_Pixel

	stride := img.width * dest_channels
	line   := 0 if origin_is_top else img.height - 1

	for _ in 0..<img.height {
		offset := line * stride + (0 if origin_is_left else (stride - dest_channels))
		for _ in 0..<img.width {
			// handle RLE decoding
			if rle_encoding {
				if rle_repetition_count == 0 {
					rle_cmd, err := compress.read_u8(ctx)
					if err != .None {
						return img, .Corrupt
					}
					is_packet_rle = (rle_cmd >> 7) != 0
					rle_repetition_count = 1 + int(rle_cmd & 0x7F)
					read_pixel = true
				} else if !is_packet_rle {
					read_pixel = rle_repetition_count > 0
				} else {
					read_pixel = false
				}
			}
			// Read pixel
			if read_pixel {
				src, src_err := compress.read_slice(ctx, src_channels)
				if src_err != .None {
					return img, .Corrupt
				}
				switch src_channels {
				case 1:
					// Color-mapped or Black & White
					if black_white {
						pixel = {src[0], src[0], src[0], 255}
					} else if header.color_map_depth == 24 {
						pixel = color_map[src[0]].bgra
					} else if header.color_map_depth == 16 {
						lut := color_map[src[0]]
						v := u16(lut.r) | u16(lut.g) << 8
						b := u8( v        & 31) << 3
						g := u8((v >>  5) & 31) << 3
						r := u8((v >> 10) & 31) << 3
						pixel = {r, g, b, 255}
					}

				case 2:
					v := u16(src[0]) | u16(src[1]) << 8
					b := u8( v        & 31) << 3
					g := u8((v >>  5) & 31) << 3
					r := u8((v >> 10) & 31) << 3
					pixel = {r, g, b, 255}

				case 3:
					pixel = {src[2], src[1], src[0], 255}
				case 4:
					pixel = {src[2], src[1], src[0], src[3]}
				case:
					return img, .Corrupt
				}
			}

			// Write pixel
			copy(img.pixels.buf[offset:], pixel[:dest_channels])
			offset += dest_channels if origin_is_left else -dest_channels
			rle_repetition_count -= 1
		}
		line += 1 if origin_is_top else -1
	}
	return img, nil
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	ctx := &compress.Context_Memory_Input{
		input_data = data,
	}

	img, err = load_from_context(ctx, options, allocator)
	return img, err
}


destroy :: proc(img: ^Image) {
	if img == nil || img.width == 0 || img.height == 0 {
		return
	}

	bytes.buffer_destroy(&img.pixels)
	if v, ok := img.metadata.(^image.TGA_Info); ok {
		delete(v.image_id)
		free(v)
	}

	// Make destroy idempotent
	img.width  = 0
	img.height = 0
	free(img)
}

IMAGE_DESCRIPTOR_INTERLEAVING_MASK :: (1<<6) | (1<<7)
IMAGE_DESCRIPTOR_RIGHT_MASK :: 1<<4
IMAGE_DESCRIPTOR_TOP_MASK   :: 1<<5

@(init, private)
_register :: proc() {
	image.register(.TGA, load_from_bytes, destroy)
}