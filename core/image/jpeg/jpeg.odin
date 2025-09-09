package jpeg

import "core:bytes"
import "core:compress"
import "core:math"
import "core:mem"
import "core:image"
import "core:slice"
import "core:strings"

Image :: image.Image
Error :: image.Error
Options :: image.Options

HUFFMAN_MAX_SYMBOLS :: 176
HUFFMAN_MAX_BITS  :: 16
// 768 bytes of 24-bit RGB values.
THUMBNAIL_PALETTE_SIZE :: 768
BLOCK_SIZE :: 8
COEFFICIENT_COUNT :: BLOCK_SIZE * BLOCK_SIZE
SEGMENT_MAX_SIZE :: 65533

Coefficient :: enum u8 {
	DC,
	AC,
}

Component :: enum u8 {
	Y = 1,
	Cb = 2,
	Cr = 3,
}

Huffman_Table :: struct {
	symbols: [HUFFMAN_MAX_SYMBOLS]byte,
	codes: [HUFFMAN_MAX_SYMBOLS]u32,
	offsets: [HUFFMAN_MAX_BITS + 1]byte,
}

Quantization_Table :: [COEFFICIENT_COUNT]u16be

Color_Component :: struct {
	dc_table_idx: u8,
	ac_table_idx: u8,
	quantization_table_idx: u8,
	v_sampling_factor: int,
	h_sampling_factor: int,
}

// 8x8 block of pixels
Block :: [Component][COEFFICIENT_COUNT]i16

@(private="file")
zigzag := [?]byte{
    0,   1,  8, 16,  9,  2,  3, 10,
    17, 24, 32, 25, 18, 11,  4,  5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13,  6,  7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
}

@(optimization_mode="favor_size", private="file")
refill_msb :: #force_inline proc(z: ^compress.Context_Memory_Input, width := i8(48)) {
	refill := u64(width)
	b      := u64(0)

	if z.num_bits > refill {
		return
	}

	for {
		if len(z.input_data) != 0 {
			b = u64(z.input_data[0])

			if len(z.input_data) > 1 && b == 0xFF {
				next := u64(z.input_data[1])

				if next == 0x00 {
					// 0x00 is used as a stuffing to indicate that the 0xFF is part of the data and not
					// the beginning of a marker
					z.input_data = z.input_data[2:]
				} else if next >= cast(u64)image.JPEG_Marker.RST0 && next <= cast(u64)image.JPEG_Marker.RST7 {
					// Skip any RSTn markers if we encounter them
					if len(z.input_data) > 2 {
						b = u64(z.input_data[2])
						z.input_data = z.input_data[3:]
					} else {
						b = 0
					}
				}
			} else {
				z.input_data = z.input_data[1:]
			}
		} else {
			b = 0
		}

		z.code_buffer |= ((b << 56) >> u8(z.num_bits))
		z.num_bits += 8
		if z.num_bits > refill {
			break
		}
	}
}

@(optimization_mode="favor_size", private="file")
consume_bits_msb :: #force_inline proc(z: ^compress.Context_Memory_Input, width: u8) {
	z.code_buffer <<= width
	z.num_bits -= u64(width)
}

@(private="file")
byte_align :: #force_inline proc(z: ^compress.Context_Memory_Input) {
	skip := z.num_bits % 8
	consume_bits_msb(z, cast(u8)skip)
}

@(optimization_mode="favor_size", private="file")
peek_bits_msb :: #force_inline proc(z: ^compress.Context_Memory_Input, width: u8) -> u32 {
	if z.num_bits < u64(width) {
		refill_msb(z)
	}
	return u32((z.code_buffer &~ (max(u64) >> width)) >> (64 - width))
}

@(optimization_mode="favor_size", private="file")
read_bits_msb :: #force_inline proc(z: ^compress.Context_Memory_Input, width: u8) -> u32 {
	k := #force_inline peek_bits_msb(z, width)
	#force_inline consume_bits_msb(z, width)
	return k
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	ctx := &compress.Context_Memory_Input{
		input_data = data,
	}

	img, err = load_from_context(ctx, options, allocator)
	return img, err
}

@(private="file")
get_symbol :: proc(ctx: ^$C, huffman_table: Huffman_Table) -> byte {
	possible_code: u32 = 0

	for i in 0..<HUFFMAN_MAX_BITS {
		bit := read_bits_msb(ctx, 1)
		possible_code = (possible_code << 1) | bit

		for j := huffman_table.offsets[i]; j < huffman_table.offsets[i + 1]; j += 1 {
			if possible_code == huffman_table.codes[j] {
				return huffman_table.symbols[j]
			}
		}
	}

	return 0
}

load_from_context :: proc(ctx: ^$C, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	// Precalculate IDCT scaling factors
	m0 := 2.0 * math.cos_f32(1.0 / 16.0 * 2.0 * math.PI)
	m1 := 2.0 * math.cos_f32(2.0 / 16.0 * 2.0 * math.PI)
	m3 := 2.0 * math.cos_f32(2.0 / 16.0 * 2.0 * math.PI)
	m5 := 2.0 * math.cos_f32(3.0 / 16.0 * 2.0 * math.PI)
	m2 := m0 - m5
	m4 := m0 + m5

	s0 := math.cos_f32(0.0 / 16.0 * math.PI) / math.sqrt_f32(8.0)
	s1 := math.cos_f32(1.0 / 16.0 * math.PI) / 2.0
	s2 := math.cos_f32(2.0 / 16.0 * math.PI) / 2.0
	s3 := math.cos_f32(3.0 / 16.0 * math.PI) / 2.0
	s4 := math.cos_f32(4.0 / 16.0 * math.PI) / 2.0
	s5 := math.cos_f32(5.0 / 16.0 * math.PI) / 2.0
	s6 := math.cos_f32(6.0 / 16.0 * math.PI) / 2.0
	s7 := math.cos_f32(7.0 / 16.0 * math.PI) / 2.0

	if .info in options {
		options += {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	if .do_not_expand_channels in options || .do_not_expand_grayscale in options {
		return img, .Unsupported_Option
	}

	first := compress.read_u8(ctx) or_return
	soi := cast(image.JPEG_Marker)compress.read_u8(ctx) or_return
	if first != 0xFF && soi != .SOI {
		return img, .Invalid_Signature
	}

	img = new(Image) or_return
	img.which = .JPEG

	expect_EOI := false
	zero_based_components := false
	huffman: [Coefficient][4]Huffman_Table
	quantization: [4]Quantization_Table
	color_components: [Component]Color_Component
	restart_interval: int
	// Image width and height in MCUs
	mcu_width: int
	mcu_height: int
	// Image width and height in blocks
	block_width: int
	block_height: int
	blocks: []Block
	defer delete(blocks)

	loop: for {
		// Loop until we find 0xFF.
		first = compress.read_u8(ctx) or_return
		(first == 0xFF) or_continue

		marker := cast(image.JPEG_Marker)compress.read_u8(ctx) or_return
		if expect_EOI && marker != .EOI {
			return img, .Extra_Data_After_SOS
		}
		#partial switch marker {
		case cast(image.JPEG_Marker)0xFF:
			// If we encounter multiple FF bytes then just skip them
			continue
		case .SOI:
			return img, .Duplicate_SOI_Marker
		case .APP0:
			ident := make([dynamic]byte, 0, 16, context.temp_allocator) or_return
			length := cast(int)((compress.read_data(ctx, u16be) or_return) - 2)
			for {
				b := compress.read_u8(ctx) or_return
				if b == 0x00 {
					break
				}
				append(&ident, b) or_return
			}
			if slice.equal(ident[:], image.JFIF_Magic[:]) {
				if length != 14 {
					// Malformed APP0. Skip it
					compress.read_slice(ctx, length - len(ident) - 1) or_return
					continue
				}

				version := compress.read_data(ctx, u16be) or_return
				units := cast(image.JFIF_Unit)(compress.read_u8(ctx) or_return)
				x_density := compress.read_data(ctx, u16be) or_return
				y_density := compress.read_data(ctx, u16be) or_return
				x_thumbnail := cast(int)compress.read_u8(ctx) or_return
				y_thumbnail := cast(int)compress.read_u8(ctx) or_return
				thumbnail: []image.RGB_Pixel

				if x_thumbnail * y_thumbnail != 0 {
					greyscale_thumbnail := false
					thumbnail_size := x_thumbnail * y_thumbnail * 3
					// According to the JFIF spec, the thumbnail should always be made of RGB pixels.
					// But some jpegs encode single-channel thumbnails.
					if thumbnail_size != length - 14 && thumbnail_size / 3 == length - 14 {
						thumbnail_size = x_thumbnail * y_thumbnail
						greyscale_thumbnail = true
					} else {
						return img, .Invalid_Thumbnail_Size
					}
					thumb_pixels := slice.reinterpret([]image.RGB_Pixel, compress.read_slice_from_memory(ctx, x_thumbnail * y_thumbnail) or_return)

					if .return_metadata in options {
						thumbnail = make([]image.RGB_Pixel, x_thumbnail * y_thumbnail) or_return
						copy(thumbnail, thumb_pixels)

						info: ^image.JPEG_Info
						if img.metadata == nil {
							info = new(image.JPEG_Info) or_return
						} else {
							info = img.metadata.(^image.JPEG_Info)
						}
						info.jfif_app0 = image.JFIF_APP0{
							version,
							x_density,
							y_density,
							units,
							cast(u8)x_thumbnail,
							cast(u8)y_thumbnail,
							greyscale_thumbnail,
							thumbnail,
						}
						img.metadata = info
					}
				}
			} else if slice.equal(ident[:], image.JFXX_Magic[:]) {
				extension_code := cast(image.JFXX_Extension_Code)compress.read_u8(ctx) or_return
				thumbnail: []byte

				switch extension_code {
				// We return the JPEG-compressed bytes for this type of thumbnail.
				// It's up to the user if they want to decode it by checking the extension code
				// and calling image.load() on the thumbnail.
				// Not sure where to document that though, maybe it's better if the thumbnail is always raw pixel data.
				case .Thumbnail_JPEG:
					// +1 for the NUL byte
					thumbnail_len := length - (size_of(image.JFXX_Magic) + 1 + size_of(image.JFXX_Extension_Code))
					thumbnail_jpeg := compress.read_slice(ctx, thumbnail_len) or_return

					if .return_metadata in options {
						thumbnail = make([]byte, thumbnail_len) or_return
						copy(thumbnail, thumbnail_jpeg)

						info: ^image.JPEG_Info
						if img.metadata == nil {
							info = new(image.JPEG_Info) or_return
						} else {
							info = img.metadata.(^image.JPEG_Info)
						}
						info.jfxx_app0 = image.JFXX_APP0{
							extension_code,
							0,
							0,
							thumbnail,
						}
						img.metadata = info
					}
				case .Thumbnail_3_Byte_RGB:
					x_thumbnail := cast(int)compress.read_u8(ctx) or_return
					y_thumbnail := cast(int)compress.read_u8(ctx) or_return
					pixels := compress.read_slice(ctx, x_thumbnail * y_thumbnail * 3) or_return

					if .return_metadata in options {
						thumbnail = make([]byte, x_thumbnail * y_thumbnail * 3) or_return
						copy(thumbnail, pixels)

						info: ^image.JPEG_Info
						if img.metadata == nil {
							info = new(image.JPEG_Info) or_return
						} else {
							info = img.metadata.(^image.JPEG_Info)
						}
						info.jfxx_app0 = image.JFXX_APP0{
							extension_code,
							cast(u8)x_thumbnail,
							cast(u8)y_thumbnail,
							thumbnail,
						}
						img.metadata = info
					}
				case .Thumbnail_1_Byte_Palette: // NOTE(illusionman1212): NOT TESTED. Couldn't find a jpeg to test this with.
					x_thumbnail := cast(int)compress.read_u8(ctx) or_return
					y_thumbnail := cast(int)compress.read_u8(ctx) or_return
					palette := slice.reinterpret([]image.RGB_Pixel, compress.read_slice(ctx, THUMBNAIL_PALETTE_SIZE / 3) or_return)
					old_pixels := compress.read_slice(ctx, x_thumbnail * y_thumbnail) or_return

					if .return_metadata in options {
						pixels := make([]byte, x_thumbnail * y_thumbnail * 3) or_return
						for i in 0..<x_thumbnail*y_thumbnail {
							pixel := palette[old_pixels[i]]
							pixels[i] = pixel.r
							pixels[i + 1] = pixel.g
							pixels[i + 2] = pixel.b
						}

						info: ^image.JPEG_Info
						if img.metadata == nil {
							info = new(image.JPEG_Info) or_return
						} else {
							info = img.metadata.(^image.JPEG_Info)
						}
						info.jfxx_app0 = image.JFXX_APP0{
							extension_code,
							cast(u8)x_thumbnail,
							cast(u8)y_thumbnail,
							pixels,
						}
						img.metadata = info
					}
				case:
					return img, .Invalid_JFXX_Extension_Code
				}
			} else {
				// - 1 for the NUL byte
				compress.read_slice(ctx, length - len(ident) - 1) or_return
				continue
			}
		case .APP1: // Metadata
			length := cast(int)((compress.read_data(ctx, u16be) or_return) - 2)
			if .return_metadata not_in options {
				compress.read_slice(ctx, length) or_return
				continue
			}
			info: ^image.JPEG_Info
			if img.metadata == nil {
				info = new(image.JPEG_Info) or_return
			} else {
				info = img.metadata.(^image.JPEG_Info)
			}

			ident := make([dynamic]byte, 0, 16, context.temp_allocator) or_return
			for {
				b := compress.read_u8(ctx) or_return
				if b == 0x00 {
					break
				}
				append(&ident, b) or_return
			}

			if slice.equal(ident[:], image.Exif_Magic[:]) {
				// Padding byte according to section 4.7.2.2 in Exif spec 3.0
				compress.read_u8(ctx) or_return

				exif: image.Exif
				peek := compress.peek_data(ctx, [4]byte) or_return
				if peek[0] == 'M' && peek[1] == 'M' {
					exif.byte_order = .big_endian
					if peek[2] != 0 || peek[3] != 42 {
						// - 2 for the NUL byte and padding byte
						compress.read_slice(ctx, length - len(ident) - 2) or_return
						continue
					}
				} else if peek[0] == 'I' && peek[1] == 'I' {
					exif.byte_order = .little_endian
					if peek[2] != 42 || peek[3] != 0 {
						compress.read_slice(ctx, length - len(ident) - 2) or_return
						continue
					}
				} else {
					// If we can't determine the endianness then this Exif data is likely a continuation of the previous
					// APP1 Exif data

					// We only treat it as such if a previous Exif entry exists and its data length is the max
					if len(info.exif) > 0 && len(info.exif[len(info.exif) - 1].data) == SEGMENT_MAX_SIZE - len(ident) - 2 {
						exif.byte_order = info.exif[len(info.exif) - 1].byte_order
					} else {
						compress.read_slice(ctx, length - len(ident) - 2) or_return
						continue
					}
				}

				// - 2 for the NUL byte and padding byte
				data := compress.read_slice(ctx, length - len(ident) - 2) or_return
				exif.data = make([]byte, len(data)) or_return
				copy(exif.data, data)

				append(&info.exif, exif) or_return
				img.metadata = info
			} else {
				// - 1 for the NUL byte
				compress.read_slice(ctx, length - len(ident) - 1) or_return
				continue
			}
		case .COM:
			length := (compress.read_data(ctx, u16be) or_return) - 2
			comment := string(compress.read_slice(ctx, cast(int)length) or_return)
			if .return_metadata in options {
				if info, ok := img.metadata.(^image.JPEG_Info); ok {
					append(&info.comments, strings.clone(comment)) or_return
				}
			}
		case .DQT:
			length := cast(int)(compress.read_data(ctx, u16be) or_return) - 2

			for length > 0 {
				precision_and_index := compress.read_u8(ctx) or_return
				precision := precision_and_index >> 4
				index := precision_and_index & 0xF

				if precision != 0 && precision != 1 {
					return img, .Invalid_Quantization_Table_Precision
				}

				if index < 0 || index > 3 {
					return img, .Invalid_Quantization_Table_Index
				}

				// When precision is 0, we read 64 u8s.
				// when it's 1, we read 64 u16s.
				table_bytes := 64
				if precision == 1 {
					table_bytes = 128
					table := compress.read_slice(ctx, table_bytes) or_return
					for v, i in slice.reinterpret([]u16be, table) {
						quantization[index][i] = v
					}
				} else {
					table := compress.read_slice(ctx, table_bytes) or_return
					for v, i in table {
						quantization[index][i] = cast(u16be)v
					}
				}

				length -= table_bytes + 1
			}
		case .DHT:
			length := (compress.read_data(ctx, u16be) or_return) - 2

			for length > 0 {
				type_index := compress.read_u8(ctx) or_return
				type := cast(Coefficient)((type_index >> 4) & 0xF)
				index := type_index & 0xF

				if type != .DC && type != .AC {
					return img, .Invalid_Huffman_Coefficient_Type
				}

				if index < 0 || index > 3 {
					return img, .Invalid_Huffman_Table_Index
				}

				lengths := compress.read_slice(ctx, HUFFMAN_MAX_BITS) or_return
				num_symbols: u8 = 0
				for length, i in lengths {
					num_symbols += length
					huffman[type][index].offsets[i + 1] = num_symbols
				}

				if num_symbols > HUFFMAN_MAX_SYMBOLS {
					return img, .Huffman_Symbols_Exceeds_Max
				}

				symbols := compress.read_slice(ctx, cast(int)num_symbols) or_return
				copy(huffman[type][index].symbols[:], symbols)

				length -= cast(u16be)(1 + HUFFMAN_MAX_BITS + num_symbols)

				code: u32 = 0
				for i in 0..<HUFFMAN_MAX_BITS {
					for j := huffman[type][index].offsets[i]; j < huffman[type][index].offsets[i + 1]; j += 1 {
						huffman[type][index].codes[j] = code
						code += 1
					}
					code <<= 1
				}
			}
		case .EOI:
			break loop
		case .DRI:
			// Length
			compress.read_data(ctx, u16be) or_return
			restart_interval = cast(int)compress.read_data(ctx, u16be) or_return
		case .RST0..=.RST7: // Handled by the bit reader. These shouldn't appear outside the entropy coded stream.
			return img, .Encountered_RST_Marker_Outside_ECS
		case .SOF0, .SOF1: // Baseline sequential DCT, and extended sequential DCT
			if img.channels != 0 {
				return img, .Multiple_SOS_Markers
			}

			// Length
			compress.read_data(ctx, u16be) or_return
			precision := compress.read_u8(ctx) or_return
			height := compress.read_data(ctx, u16be) or_return
			width := compress.read_data(ctx, u16be) or_return
			components := compress.read_u8(ctx) or_return
			img.width = cast(int)width
			img.height = cast(int)height
			img.depth = cast(int)precision
			img.channels = cast(int)components

			// TODO: 12-bit precision is valid too but we don't support it.
			if precision == 12 {
				return img, .Unsupported_12_Bit_Depth
			}
			if precision != 8 {
				return img, .Invalid_Frame_Bit_Depth_Combo
			}

			// TODO: spec allows for the height to be 0 on the condition that a DNL marker MUST exist to define
			// how many lines in the frame we have.
			// ISO/IEC 10918-1: 1993.
			// Section B.2.5
			if img.width == 0 || img.height == 0 {
				return img, .Invalid_Image_Dimensions
			}

			if u128(img.width) * u128(img.height) > image.MAX_DIMENSIONS {
				return img, .Image_Dimensions_Too_Large
			}

			// TODO: Some JPEGs use CMYK as the color model which means there will be 4 components
			if components != 1 && components != 3 {
				return img, .Invalid_Number_Of_Channels
			}

			if img.metadata != nil {
				info := img.metadata.(^image.JPEG_Info)
				info.frame_type = marker
			}

			mcu_width = (img.width + 7) / BLOCK_SIZE
			mcu_height = (img.height + 7) / BLOCK_SIZE
			block_width = mcu_width
			block_height = mcu_height

			for _ in 0..<components {
				id := cast(Component)compress.read_u8(ctx) or_return

				if id == Component(0) {
					zero_based_components = true
				}

				if zero_based_components {
					id += Component(1)
				}

				// TODO: while others that use CMYK have these IDs 67, 77, 89, 75 which are CMYK in ASCII
				// TODO: even more weird ids. 82, 71, 66 which is RGB in ASCII
				if id < .Y || id > .Cr {
					return img, .Image_Does_Not_Adhere_to_Spec
				}

				h_v_factors := compress.read_u8(ctx) or_return
				horizontal_sampling := h_v_factors >> 4
				vertical_sampling := h_v_factors & 0xF

				// TODO: spec says the range for the sampling factors is 1-4
				// We only support 1,2 for now.
				if horizontal_sampling < 1 || horizontal_sampling > 2 {
					return img, .Invalid_Sampling_Factor
				}
				if vertical_sampling < 1 || vertical_sampling > 2 {
					return img, .Invalid_Sampling_Factor
				}

				if id == .Y {
					if horizontal_sampling == 2 && mcu_width % 2 == 1 {
						block_width += 1
					}
					if vertical_sampling == 2 && mcu_height % 2 == 1 {
						block_height += 1
					}
				} else {
					if horizontal_sampling != 1 && vertical_sampling != 1 {
						return img, .Invalid_Sampling_Factor
					}
				}

				quantization_table_idx := compress.read_u8(ctx) or_return

				if quantization_table_idx < 0 || quantization_table_idx > 3 {
					return img, .Invalid_Quantization_Table_Index
				}

				color_components[id].quantization_table_idx = quantization_table_idx
				color_components[id].v_sampling_factor = cast(int)vertical_sampling
				color_components[id].h_sampling_factor = cast(int)horizontal_sampling
			}
		case .SOF2: // Progressive DCT
			fallthrough
		case .SOF3: // Lossless (sequential)
			fallthrough
		case .SOF5: // Differential sequential DCT
			fallthrough
		case .SOF6: // Differential progressive DCT
			fallthrough
		case .SOF7: // Differential lossless (sequential)
			fallthrough
		case .SOF9: // Extended sequential DCT, Arithmetic coding
			fallthrough
		case .SOF10: // Progressive DCT, Arithmetic coding
			fallthrough
		case .SOF11: // Lossless (sequential), Arithmetic coding
			fallthrough
		case .SOF13: // Differential sequential DCT, Arithmetic coding
			fallthrough
		case .SOF14: // Differential progressive DCT, Arithmetic coding
			fallthrough
		case .SOF15: // Differential lossless (sequential), Arithmetic coding
			if img.metadata != nil {
				info := img.metadata.(^image.JPEG_Info)
				info.frame_type = marker
			}
			return img, .Unsupported_Frame_Type
		case .SOS:
			if img.channels == 0 && img.depth == 0 && img.width == 0 && img.height == 0 {
				return img, .Encountered_SOS_Before_SOF
			}

			if .do_not_decompress_image in options {
				return img, nil
			}

			// Length
			compress.read_data(ctx, u16be) or_return
			num_components := compress.read_u8(ctx) or_return
			if num_components != 1 && num_components != 3 {
				return img, .Invalid_Number_Of_Channels
			}

			for _ in 0..<num_components {
				component_id := cast(Component)compress.read_u8(ctx) or_return
				if zero_based_components {
					component_id += Component(1)
				}
				if component_id < .Y || component_id > .Cr {
					return img, .Image_Does_Not_Adhere_to_Spec
				}

				// high 4 is DC, low 4 is AC
				coefficient_indices := compress.read_u8(ctx) or_return
				dc_table_idx := coefficient_indices >> 4
				ac_table_idx := coefficient_indices & 0xF

				if (dc_table_idx < 0 || dc_table_idx > 3) || (ac_table_idx < 0 || ac_table_idx > 3) {
					return img, .Invalid_Huffman_Table_Index
				}

				color_components[component_id].dc_table_idx = dc_table_idx
				color_components[component_id].ac_table_idx = ac_table_idx
			}
			// TODO: These aren't used for sequential DCT, only progressive and lossless.
			Ss := compress.read_u8(ctx) or_return
			_ = Ss
			Se := compress.read_u8(ctx) or_return
			_ = Se
			Ah_Al := compress.read_u8(ctx) or_return
			_ = Ah_Al

			blocks = make([]Block, block_height * block_width) or_return

			previous_dc: [Component]i16

			luma_v_sampling_factor := color_components[.Y].v_sampling_factor
			luma_h_sampling_factor := color_components[.Y].h_sampling_factor

			restart_interval *= luma_v_sampling_factor * luma_h_sampling_factor
			#no_bounds_check for y := 0; y < mcu_height; y += luma_v_sampling_factor {
				for x := 0; x < mcu_width; x += luma_h_sampling_factor {
					blk := y * block_width + x

					if restart_interval != 0 && blk % restart_interval == 0 {
						previous_dc[.Y] = 0
						previous_dc[.Cb] = 0
						previous_dc[.Cr] = 0
						byte_align(ctx)
					}
					for c in 1..=img.channels {
						c := cast(Component)c
						for v in 0..<color_components[c].v_sampling_factor {
						h_loop:
							for h in 0..<color_components[c].h_sampling_factor {
								mcu := &blocks[(y + v) * block_width + (h + x)][c]
								dc_table := huffman[.DC][color_components[c].dc_table_idx]
								ac_table := huffman[.AC][color_components[c].ac_table_idx]
								quantization_table := quantization[color_components[c].quantization_table_idx]

								length := get_symbol(ctx, dc_table)

								if length > 11 {
									return img, .Corrupt
								}

								dc_coeff := cast(i16)read_bits_msb(ctx, length)

								if length != 0 && dc_coeff < (1 << (length - 1)) {
									dc_coeff -= (1 << length) - 1
								}
								mcu[0] = (dc_coeff + previous_dc[c]) * cast(i16)quantization_table[0]
								previous_dc[c] = dc_coeff + previous_dc[c]

								for i := 1; i < COEFFICIENT_COUNT; i += 1 {
									// High nibble is amount of 0s to skip.
									// Low nibble is length of coeff.
									symbol := get_symbol(ctx, ac_table)

									// Special symbol used to indicate
									// that the rest of the MCU is filled with 0s
									if symbol == 0x00 {
										continue h_loop
									}

									amnt_zeros := int(symbol >> 4)
									ac_coeff_len := symbol & 0xF
									ac_coeff: i16 = 0

									if i + amnt_zeros >= COEFFICIENT_COUNT || ac_coeff_len > 10 {
										return img, .Corrupt
									}

									i += amnt_zeros

									ac_coeff = cast(i16)read_bits_msb(ctx, ac_coeff_len)
									if ac_coeff < (1 << (ac_coeff_len - 1)) {
										ac_coeff -= (1 << ac_coeff_len) - 1
									}

									mcu[zigzag[i]] = ac_coeff * cast(i16)quantization_table[i]
								}
							}
						}
					}

					for c in 1..=img.channels {
						c := cast(Component)c

						for v in 0..<color_components[c].v_sampling_factor {
							for h in 0..< color_components[c].h_sampling_factor {
								mcu := &blocks[(y + v) * block_width + (x + h)][c]
								for i in 0..<BLOCK_SIZE {
									g0 := cast(f32)mcu[0 * BLOCK_SIZE + i] * s0
									g1 := cast(f32)mcu[4 * BLOCK_SIZE + i] * s4
									g2 := cast(f32)mcu[2 * BLOCK_SIZE + i] * s2
									g3 := cast(f32)mcu[6 * BLOCK_SIZE + i] * s6
									g4 := cast(f32)mcu[5 * BLOCK_SIZE + i] * s5
									g5 := cast(f32)mcu[1 * BLOCK_SIZE + i] * s1
									g6 := cast(f32)mcu[7 * BLOCK_SIZE + i] * s7
									g7 := cast(f32)mcu[3 * BLOCK_SIZE + i] * s3

									f4 := g4 - g7
									f5 := g5 + g6
									f6 := g5 - g6
									f7 := g4 + g7

									e0 := g0
									e1 := g1
									e2 := g2 - g3
									e3 := g2 + g3
									e4 := f4
									e5 := f5 - f7
									e6 := f6
									e7 := f5 + f7
									e8 := f4 + f6

									d0 := e0
									d1 := e1
									d2 := e2 * m1
									d3 := e3
									d4 := e4 * m2
									d5 := e5 * m3
									d6 := e6 * m4
									d7 := e7
									d8 := e8 * m5

									c0 := d0 + d1
									c1 := d0 - d1
									c2 := d2 - d3
									c3 := d3
									c4 := d4 + d8
									c5 := d5 + d7
									c6 := d6 - d8
									c7 := d7
									c8 := c5 - c6

									b0 := c0 + c3
									b1 := c1 + c2
									b2 := c1 - c2
									b3 := c0 - c3
									b4 := c4 - c8
									b5 := c8
									b6 := c6 - c7
									b7 := c7

									mcu[0 * BLOCK_SIZE + i] = cast(i16)(b0 + b7)
									mcu[1 * BLOCK_SIZE + i] = cast(i16)(b1 + b6)
									mcu[2 * BLOCK_SIZE + i] = cast(i16)(b2 + b5)
									mcu[3 * BLOCK_SIZE + i] = cast(i16)(b3 + b4)
									mcu[4 * BLOCK_SIZE + i] = cast(i16)(b3 - b4)
									mcu[5 * BLOCK_SIZE + i] = cast(i16)(b2 - b5)
									mcu[6 * BLOCK_SIZE + i] = cast(i16)(b1 - b6)
									mcu[7 * BLOCK_SIZE + i] = cast(i16)(b0 - b7)
								}

								for i in 0..<BLOCK_SIZE {
									g0 := cast(f32)mcu[i * BLOCK_SIZE + 0] * s0
									g1 := cast(f32)mcu[i * BLOCK_SIZE + 4] * s4
									g2 := cast(f32)mcu[i * BLOCK_SIZE + 2] * s2
									g3 := cast(f32)mcu[i * BLOCK_SIZE + 6] * s6
									g4 := cast(f32)mcu[i * BLOCK_SIZE + 5] * s5
									g5 := cast(f32)mcu[i * BLOCK_SIZE + 1] * s1
									g6 := cast(f32)mcu[i * BLOCK_SIZE + 7] * s7
									g7 := cast(f32)mcu[i * BLOCK_SIZE + 3] * s3

									f4 := g4 - g7
									f5 := g5 + g6
									f6 := g5 - g6
									f7 := g4 + g7

									e0 := g0
									e1 := g1
									e2 := g2 - g3
									e3 := g2 + g3
									e4 := f4
									e5 := f5 - f7
									e6 := f6
									e7 := f5 + f7
									e8 := f4 + f6

									d0 := e0
									d1 := e1
									d2 := e2 * m1
									d3 := e3
									d4 := e4 * m2
									d5 := e5 * m3
									d6 := e6 * m4
									d7 := e7
									d8 := e8 * m5

									c0 := d0 + d1
									c1 := d0 - d1
									c2 := d2 - d3
									c3 := d3
									c4 := d4 + d8
									c5 := d5 + d7
									c6 := d6 - d8
									c7 := d7
									c8 := c5 - c6

									b0 := c0 + c3
									b1 := c1 + c2
									b2 := c1 - c2
									b3 := c0 - c3
									b4 := c4 - c8
									b5 := c8
									b6 := c6 - c7
									b7 := c7

									mcu[i * BLOCK_SIZE + 0] = cast(i16)(b0 + b7)
									mcu[i * BLOCK_SIZE + 1] = cast(i16)(b1 + b6)
									mcu[i * BLOCK_SIZE + 2] = cast(i16)(b2 + b5)
									mcu[i * BLOCK_SIZE + 3] = cast(i16)(b3 + b4)
									mcu[i * BLOCK_SIZE + 4] = cast(i16)(b3 - b4)
									mcu[i * BLOCK_SIZE + 5] = cast(i16)(b2 - b5)
									mcu[i * BLOCK_SIZE + 6] = cast(i16)(b1 - b6)
									mcu[i * BLOCK_SIZE + 7] = cast(i16)(b0 - b7)
								}
							}
						}
					}

					// Convert the YCbCr pixel data to RGB
					cbcr_blk := &blocks[y * block_width + x]
					for v := luma_v_sampling_factor - 1; v >= 0; v -= 1 {
						for h := luma_h_sampling_factor - 1; h >= 0; h -= 1 {
							y_blk := &blocks[(y + v) * block_width + (x + h)]

							for j := BLOCK_SIZE - 1; j >= 0; j -= 1 {
								for k := BLOCK_SIZE - 1; k >= 0; k -= 1 {
									i := j * BLOCK_SIZE + k
									cbcr_pixel_row    := j / luma_v_sampling_factor + 4 * v
									cbcr_pixel_column := k / luma_h_sampling_factor + 4 * h
									cbcr_pixel := cbcr_pixel_row * BLOCK_SIZE + cbcr_pixel_column

									r := cast(i16)clamp(cast(f32)y_blk[.Y][i] + 1.402 * cast(f32)cbcr_blk[.Cr][cbcr_pixel] + 128, 0, 255)
									g := cast(i16)clamp(cast(f32)y_blk[.Y][i] - 0.344 * cast(f32)cbcr_blk[.Cb][cbcr_pixel] - 0.714 * cast(f32)cbcr_blk[.Cr][cbcr_pixel] + 128, 0, 255)
									b := cast(i16)clamp(cast(f32)y_blk[.Y][i] + 1.772 * cast(f32)cbcr_blk[.Cb][cbcr_pixel] + 128, 0, 255)

									y_blk[.Y][i]  = r
									y_blk[.Cb][i] = g
									y_blk[.Cr][i] = b
								}
							}
						}
					}
				}
			}

			orig_channels := img.channels

			// We automatically expand grayscale images to RGB
			if img.channels == 1 {
				img.channels += 2
			}

			if .alpha_add_if_missing in options {
				img.channels  += 1
				orig_channels += 1
			}

			if resize(&img.pixels.buf, img.width * img.height * img.channels) != nil {
				return img, .Unable_To_Allocate_Or_Resize
			}

			switch orig_channels {
			case 1: // Grayscale JPEG expanded to RGB
				out     := mem.slice_data_cast([]image.RGB_Pixel, img.pixels.buf[:])
				out_idx := 0
				for y in 0..<img.height {
					mcu_row   := y / BLOCK_SIZE
					pixel_row := y % BLOCK_SIZE
					for x in 0..<img.width {
						mcu_col   := x / BLOCK_SIZE
						pixel_col := x % BLOCK_SIZE
						mcu_idx   := mcu_row   * block_width + mcu_col
						pixel_idx := pixel_row * BLOCK_SIZE  + pixel_col

						luma := cast(byte)blocks[mcu_idx][.Y][pixel_idx]
						out[out_idx] = {luma, luma, luma}

						out_idx += 1
					}
				}

			case 2: // Grayscale JPEG expanded to RGBA
				out     := mem.slice_data_cast([]image.RGBA_Pixel, img.pixels.buf[:])
				out_idx := 0
				for y in 0..<img.height {
					mcu_row   := y / BLOCK_SIZE
					pixel_row := y % BLOCK_SIZE

					for x in 0..<img.width {
						mcu_col   := x / BLOCK_SIZE
						pixel_col := x % BLOCK_SIZE
						mcu_idx   := mcu_row   * block_width + mcu_col
						pixel_idx := pixel_row * BLOCK_SIZE  + pixel_col

						luma := cast(byte)blocks[mcu_idx][.Y][pixel_idx]
						out[out_idx] = {luma, luma, luma, 255}
						out_idx += 1
					}
				}

			case 3:
				out     := mem.slice_data_cast([]image.RGB_Pixel, img.pixels.buf[:])
				out_idx := 0
				for y in 0..<img.height {
					mcu_row   := y / BLOCK_SIZE
					pixel_row := y % BLOCK_SIZE

					for x in 0..<img.width {
						mcu_col   := x / BLOCK_SIZE
						pixel_col := x % BLOCK_SIZE
						mcu_idx   := mcu_row   * block_width + mcu_col
						pixel_idx := pixel_row * BLOCK_SIZE  + pixel_col

						out[out_idx] = {
							cast(byte)blocks[mcu_idx][.Y][pixel_idx],
							cast(byte)blocks[mcu_idx][.Cb][pixel_idx],
							cast(byte)blocks[mcu_idx][.Cr][pixel_idx],
						}
						out_idx += 1
					}
				}

			case 4:
				out     := mem.slice_data_cast([]image.RGBA_Pixel, img.pixels.buf[:])
				out_idx := 0
				for y in 0..<img.height {
					mcu_row   := y / BLOCK_SIZE
					pixel_row := y % BLOCK_SIZE

					for x in 0..<img.width {
						mcu_col   := x / BLOCK_SIZE
						pixel_col := x % BLOCK_SIZE
						mcu_idx   := mcu_row   * block_width + mcu_col
						pixel_idx := pixel_row * BLOCK_SIZE  + pixel_col

						out[out_idx] = {
							cast(byte)blocks[mcu_idx][.Y][pixel_idx],
							cast(byte)blocks[mcu_idx][.Cb][pixel_idx],
							cast(byte)blocks[mcu_idx][.Cr][pixel_idx],
							255, // Alpha
						}
						out_idx += 1
					}
				}
			}

			expect_EOI = true

		case .TEM:
			// TEM doesn't have a length, continue to next marker
		case:
			length := (compress.read_data(ctx, u16be) or_return) - 2
			compress.read_slice_from_memory(ctx, cast(int)length) or_return
		}
	}

	return
}

destroy :: proc(img: ^Image) {
	if img == nil {
		return
	}

	bytes.buffer_destroy(&img.pixels)

	if v, ok := img.metadata.(^image.JPEG_Info); ok {
		if jfxx, jfxx_ok := v.jfxx_app0.?; jfxx_ok {
			delete(jfxx.thumbnail)
		}
		if jfif, jfif_ok := v.jfif_app0.?; jfif_ok {
			delete(jfif.thumbnail)
		}

		for comment in v.comments {
			delete(comment)
		}
		delete(v.comments)

		for exif in v.exif {
			delete(exif.data)
		}
		delete(v.exif)

		free(v)
	}
	free(img)
}

@(init, private)
_register :: proc "contextless" () {
	image.register(.JPEG, load_from_bytes, destroy)
}