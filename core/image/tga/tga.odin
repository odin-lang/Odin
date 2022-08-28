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
import "core:os"
import "core:compress"
import "core:strings"
import "core:fmt"
_ :: fmt

// TODO: alpha_premultiply support

Error   :: image.Error
Image   :: image.Image
Options :: image.Options

RGB_Pixel  :: image.RGB_Pixel
RGBA_Pixel :: image.RGBA_Pixel

save_to_memory  :: proc(output: ^bytes.Buffer, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
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

	if !resize(&output.buf, necessary) {
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

save_to_file :: proc(output: string, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	out := &bytes.Buffer{}
	defer bytes.buffer_destroy(out)

	save_to_memory(out, img, options) or_return
	write_ok := os.write_entire_file(output, out.buf[:])

	return nil if write_ok else .Unable_To_Write_File
}

save :: proc{save_to_memory, save_to_file}

load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .alpha_premultiply in options {
		return nil, .Unsupported_Option
	}

	if .info in options {
		options |= {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	// First check for a footer.
	filesize := compress.input_size(ctx) or_return

	footer: image.TGA_Footer
	have_valid_footer := false

	if filesize >= size_of(image.TGA_Header) + size_of(image.TGA_Footer) {
		if f, f_err := compress.peek_data(ctx, image.TGA_Footer, filesize - i64(size_of(image.TGA_Footer))); f_err == .None {
			if string(f.signature[:]) == image.New_TGA_Signature {
				have_valid_footer = true
				footer = f
			}
		}
	}

	header := image.read_data(ctx, image.TGA_Header) or_return
	
	// Header checks
	rle_encoding := false 

	switch header.data_type_code {
		case .Compressed_RBB: rle_encoding = true
		case .Uncompressed_RGB:
		case: return nil, .Unsupported_Format 	
	}

	if header.bits_per_pixel != 24 && header.bits_per_pixel != 32 {
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

	src_channels := int(header.bits_per_pixel) / 8
	img.which = .TGA
	img.channels = 4 if .alpha_add_if_missing  in options else src_channels
	img.channels = 3 if .alpha_drop_if_present in options else img.channels

	img.depth  = 8
	img.width  = int(header.dimensions[0])
	img.height = int(header.dimensions[1])

	// Read Image ID if present
	image_id := ""
	if _id, e := compress.read_slice(ctx, int(header.id_length)); e != .None {
		return nil, .Corrupt
	} else {
		if .return_metadata in options {
			id := strings.trim_right_null(string(_id))
			image_id = strings.clone(id)
		}
	}

	if .return_metadata in options {
		info := new(image.TGA_Info)
		info.header   = header
		info.image_id = image_id
		if have_valid_footer {
			info.footer = footer
		}
		img.metadata = info
	}

	if .do_not_decompress_image in options {
		return img, nil
	}

	if !resize(&img.pixels.buf, img.channels * img.width * img.height) {
		return img, .Unable_To_Allocate_Or_Resize
	}

	origin_is_topleft    := header.image_descriptor & IMAGE_DESCRIPTOR_TOPLEFT_MASK != 0
	rle_repetition_count := 0
	read_pixel           := true
	is_packet_rle        := false

	pixel: [4]u8

	stride := img.width * img.channels
	line   := 0 if origin_is_topleft else img.height - 1

	for _ in 0..<img.height {
		offset := line * stride
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

				pixel[2] = src[0]
				pixel[1] = src[1]
				pixel[0] = src[2]

				pixel[3] = src_channels == 4 ? src[3] : 255
				if img.channels == 4 {
					if src_channels == 4 {
						img.pixels.buf[offset:][3] = src[3]
					} else {
						img.pixels.buf[offset:][3] = 255
					}
				}
			}

			// Write pixel
			copy(img.pixels.buf[offset:], pixel[:img.channels])
			offset += img.channels
			rle_repetition_count -= 1
		}
		line += 1 if origin_is_topleft else -1
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

load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	data, ok := os.read_entire_file(filename)
	defer delete(data)

	if ok {
		return load_from_bytes(data, options)
	} else {
		return nil, .Unable_To_Read_File
	}
}

load :: proc{load_from_file, load_from_bytes, load_from_context}

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
IMAGE_DESCRIPTOR_TOPLEFT_MASK :: 1<<5

@(init, private)
_register :: proc() {
	image.register(.TGA, load_from_bytes, destroy)
}