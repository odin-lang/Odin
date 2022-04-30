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
import "core:compress"
import "core:bytes"
import "core:os"

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