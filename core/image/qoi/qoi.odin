/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/


// package qoi implements a QOI image reader
//
// The QOI specification is at https://qoiformat.org.
package qoi

import "core:image"
import "core:compress"
import "core:bytes"

Error   :: image.Error
Image   :: image.Image
Options :: image.Options

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
	if pixels == 0 || pixels > image.MAX_DIMENSIONS {
		return .Invalid_Input_Image
	}

	// QOI supports only 8-bit images with 3 or 4 channels.
	if img.depth != 8 || img.channels < 3 || img.channels > 4 {
		return .Invalid_Input_Image
	}

	if img.channels * pixels != len(img.pixels.buf) {
		return .Invalid_Input_Image
	}

	written := 0

	// Calculate and allocate maximum size. We'll reclaim space to actually written output at the end.
	max_size := pixels * (img.channels + 1) + size_of(image.QOI_Header) + size_of(u64be)

	if resize(&output.buf, max_size) != nil {
		return .Unable_To_Allocate_Or_Resize
	}

	header := image.QOI_Header{
		magic       = image.QOI_Magic,
		width       = u32be(img.width),
		height      = u32be(img.height),
		channels    = u8(img.channels),
		color_space = .Linear if .qoi_all_channels_linear in options else .sRGB,
	}
	header_bytes := transmute([size_of(image.QOI_Header)]u8)header

	copy(output.buf[written:], header_bytes[:])
	written += size_of(image.QOI_Header)

	/*
		Encode loop starts here.
	*/
	seen: [64]RGBA_Pixel
	pix  := RGBA_Pixel{0, 0, 0, 255}
	prev := pix

	input := img.pixels.buf[:]
	run   := u8(0)

	for len(input) > 0 {
		if img.channels == 4 {
			pix     = (^RGBA_Pixel)(raw_data(input))^
		} else {
			pix.rgb = (^RGB_Pixel)(raw_data(input))^
		}
		input = input[img.channels:]

		if pix == prev {
			run += 1
			// As long as the pixel matches the last one, accumulate the run total.
			// If we reach the max run length or the end of the image, write the run.
			if run == 62 || len(input) == 0 {
				// Encode and write run
				output.buf[written] = u8(QOI_Opcode_Tag.RUN) | (run - 1)
				written += 1
				run = 0
			}
		} else {
			if run > 0 {
				// The pixel differs from the previous one, but we still need to write the pending run.
				// Encode and write run
				output.buf[written] = u8(QOI_Opcode_Tag.RUN) | (run - 1)
				written += 1
				run = 0
			}

			index := qoi_hash(pix)

			if seen[index] == pix {
				// Write indexed pixel
				output.buf[written] = u8(QOI_Opcode_Tag.INDEX) | index
				written += 1
			} else {
				// Add pixel to index
				seen[index] = pix

				// If the alpha matches the previous pixel's alpha, we don't need to write a full RGBA literal.
				if pix.a == prev.a {
					// Delta
					d  := pix.rgb - prev.rgb

					// DIFF, biased and modulo 256
					_d := d + 2

					// LUMA, biased and modulo 256
					_l := RGB_Pixel{ d.r - d.g + 8, d.g + 32, d.b - d.g + 8 }

					if _d.r < 4 && _d.g < 4 && _d.b < 4 {
						// Delta is between -2 and 1 inclusive
						output.buf[written] = u8(QOI_Opcode_Tag.DIFF) | _d.r << 4 | _d.g << 2 | _d.b
						written += 1
					} else if _l.r < 16 && _l.g < 64 && _l.b < 16 {
						// Biased luma is between {-8..7, -32..31, -8..7}
						output.buf[written    ] = u8(QOI_Opcode_Tag.LUMA) | _l.g
						output.buf[written + 1] = _l.r << 4 | _l.b
						written += 2
					} else {
						// Write RGB literal
						output.buf[written] = u8(QOI_Opcode_Tag.RGB)
						copy(output.buf[written + 1:], pix[:3])
						written += 4
					}
				} else {
					// Write RGBA literal
					output.buf[written] = u8(QOI_Opcode_Tag.RGBA)
					copy(output.buf[written + 1:], pix[:])
					written += 5
				}
			}
		}
		prev = pix
	}

	trailer := []u8{0, 0, 0, 0, 0, 0, 0, 1}
	copy(output.buf[written:], trailer[:])
	written += len(trailer)

	resize(&output.buf, written)
	return nil
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	ctx := &compress.Context_Memory_Input{
		input_data = data,
	}

	img, err = load_from_context(ctx, options, allocator)
	return img, err
}

@(optimization_mode="favor_size")
load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .info in options {
		options += {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	header := image.read_data(ctx, image.QOI_Header) or_return
	if header.magic != image.QOI_Magic {
		return img, .Invalid_Signature
	}

	if img == nil {
		img = new(Image)
	}
	img.which = .QOI

	if .return_metadata in options {
		info := new(image.QOI_Info)
		info.header  = header
		img.metadata = info		
	}

	if header.channels != 3 && header.channels != 4 {
		return img, .Invalid_Number_Of_Channels
	}

	if header.color_space != .sRGB && header.color_space != .Linear {
		return img, .Invalid_Color_Space
	}

	if header.width == 0 || header.height == 0 {
		return img, .Invalid_Image_Dimensions
	}

	total_pixels := header.width * header.height
	if total_pixels > image.MAX_DIMENSIONS {
		return img, .Image_Dimensions_Too_Large
	}

	img.width    = int(header.width)
	img.height   = int(header.height)
	img.channels = 4 if .alpha_add_if_missing in options else int(header.channels)
	img.depth    = 8

	if .do_not_decompress_image in options {
		img.channels = int(header.channels)
		return
	}

	bytes_needed := image.compute_buffer_size(int(header.width), int(header.height), img.channels, 8)

	if resize(&img.pixels.buf, bytes_needed) != nil {
		return img, .Unable_To_Allocate_Or_Resize
	}

	/*
		Decode loop starts here.
	*/
	seen: [64]RGBA_Pixel
	pix    := RGBA_Pixel{0, 0, 0, 255}
	pixels := img.pixels.buf[:]

	decode: for len(pixels) > 0 {
		data := image.read_u8(ctx) or_return

		tag := QOI_Opcode_Tag(data)
		#partial switch tag {
		case .RGB:
			pix.rgb = image.read_data(ctx, RGB_Pixel) or_return

			#no_bounds_check {
				seen[qoi_hash(pix)] = pix	
			}

		case .RGBA:
			pix = image.read_data(ctx, RGBA_Pixel) or_return

			#no_bounds_check {
				seen[qoi_hash(pix)] = pix	
			}

		case:
			// 2-bit tag
			tag = QOI_Opcode_Tag(data & QOI_Opcode_Mask)
			#partial switch tag {
				case .INDEX:
					pix = seen[data & 63]

				case .DIFF:
					diff_r := ((data >> 4) & 3) - 2
					diff_g := ((data >> 2) & 3) - 2
					diff_b := ((data >> 0) & 3) - 2

					pix += {diff_r, diff_g, diff_b, 0}

					#no_bounds_check {
						seen[qoi_hash(pix)] = pix	
					}

				case .LUMA:
					data2 := image.read_u8(ctx) or_return

					diff_g := (data & 63) - 32
					diff_r := diff_g - 8 + ((data2 >> 4) & 15)
					diff_b := diff_g - 8 + (data2 & 15)

					pix += {diff_r, diff_g, diff_b, 0}

					#no_bounds_check {
						seen[qoi_hash(pix)] = pix	
					}

				case .RUN:
					if length := int(data & 63) + 1; (length * img.channels) > len(pixels) {
						return img, .Corrupt
					} else {
						#no_bounds_check for _ in 0..<length {
							copy(pixels, pix[:img.channels])
							pixels = pixels[img.channels:]
						}
					}

					continue decode

				case:
					unreachable()
			}
		}

		#no_bounds_check {
			copy(pixels, pix[:img.channels])
			pixels = pixels[img.channels:]
		}
	}

	// The byte stream's end is marked with 7 0x00 bytes followed by a single 0x01 byte.
	trailer, trailer_err := compress.read_data(ctx, u64be)
	if trailer_err != nil || trailer != 0x1 {
		return img, .Missing_Or_Corrupt_Trailer
	}

	if .alpha_premultiply in options && !image.alpha_drop_if_present(img, options) {
		return img, .Post_Processing_Error
	}

	return
}

/*
	Cleanup of image-specific data.
*/
destroy :: proc(img: ^Image) {
	if img == nil {
		/*
			Nothing to do.
			Load must've returned with an error.
		*/
		return
	}

	bytes.buffer_destroy(&img.pixels)

	if v, ok := img.metadata.(^image.QOI_Info); ok {
		free(v)
	}
	free(img)
}

QOI_Opcode_Tag :: enum u8 {
	// 2-bit tags
	INDEX = 0b0000_0000, // 6-bit index into color array follows
	DIFF  = 0b0100_0000, // 3x (RGB) 2-bit difference follows (-2..1), bias of 2.
	LUMA  = 0b1000_0000, // Luma difference
	RUN   = 0b1100_0000, // Run length encoding, bias -1

	// 8-bit tags
	RGB   = 0b1111_1110, // Raw RGB  pixel follows
	RGBA  = 0b1111_1111, // Raw RGBA pixel follows
}

QOI_Opcode_Mask :: 0b1100_0000
QOI_Data_Mask   :: 0b0011_1111

qoi_hash :: #force_inline proc(pixel: RGBA_Pixel) -> (index: u8) {
	i1 := u16(pixel.r) * 3
	i2 := u16(pixel.g) * 5
	i3 := u16(pixel.b) * 7
	i4 := u16(pixel.a) * 11

	return u8((i1 + i2 + i3 + i4) & 63)
}

@(init, private)
_register :: proc() {
	image.register(.QOI, load_from_bytes, destroy)
}
