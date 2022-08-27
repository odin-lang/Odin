/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/


// package tga implements a TGA image writer for 8-bit RGB and RGBA images.
package tga

import "core:mem"
import "core:image"
import "core:bytes"
import "core:os"
import "core:compress"

// TODO: alpha_premultiply support
// TODO: RLE decompression


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
		data_type_code   = 0x02, // Color, uncompressed.
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

	header := image.read_data(ctx, image.TGA_Header) or_return
	
	// Header checks
	if header.data_type_code != DATATYPE_UNCOMPRESSED_RGB {
		return nil, .Unsupported_Format
	}
	if header.bits_per_pixel!=24 && header.bits_per_pixel!=32 {
		return nil, .Unsupported_Format
	}
	if ( header.image_descriptor & IMAGE_DESCRIPTOR_INTERLEAVING_MASK ) != 0 {
		return nil, .Unsupported_Format
	}

	if (int(header.dimensions[0])*int(header.dimensions[1])) > image.MAX_DIMENSIONS {
		return nil, .Image_Dimensions_Too_Large
	}

	if img == nil {
		img = new(Image)
	}

	if .return_metadata in options {
		info := new(image.TGA_Info)
		info.header = header
		img.metadata = info
	}
	src_channels := int(header.bits_per_pixel)/8
	img.which = .TGA
	img.channels = .alpha_add_if_missing in options ? 4: src_channels
	img.channels = .alpha_drop_if_present in options ? 3: img.channels
	
	img.depth = 8
	img.width = int(header.dimensions[0])
	img.height = int(header.dimensions[1])

	if .do_not_decompress_image in options {
		return img, nil
	}

	// skip id
	if _, e := compress.read_slice(ctx, int(header.id_length)); e!= .None {
		destroy(img)
		return nil, .Corrupt
	}

	if !resize(&img.pixels.buf, img.channels * img.width * img.height) {
		destroy(img)
		return nil, .Unable_To_Allocate_Or_Resize
	}

	origin_is_topleft := (header.image_descriptor & IMAGE_DESCRIPTOR_TOPLEFT_MASK ) != 0
	for y in 0..<img.height {
		line := origin_is_topleft ? y : img.height-y-1
		dst := mem.ptr_offset(mem.raw_data(img.pixels.buf), line*img.width*img.channels)
		for x in 0..<img.width {
			src, err := compress.read_slice(ctx, src_channels)
			if err!=.None {
				destroy(img)
				return nil, .Corrupt
			}
			dst[2] = src[0]
			dst[1] = src[1]
			dst[0] = src[2]
			if img.channels==4 {
				if src_channels==4 {
					dst[3] = src[3]
				} else {
					dst[3] = 255
				}
			}
			dst = mem.ptr_offset(dst, img.channels)
		}
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
	if img == nil {
		return
	}

	bytes.buffer_destroy(&img.pixels)
	if v, ok := img.metadata.(^image.TGA_Info); ok {
		free(v)
	}

	free(img)
}

DATATYPE_UNCOMPRESSED_RGB :: 0x2
IMAGE_DESCRIPTOR_INTERLEAVING_MASK :: (1<<6) | (1<<7)
IMAGE_DESCRIPTOR_TOPLEFT_MASK :: 1<<5

@(init, private)
_register :: proc() {
	image.register(.TGA, load_from_bytes, destroy)
}