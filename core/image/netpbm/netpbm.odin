#+vet !using-stmt
package netpbm

import "core:bytes"
import "core:fmt"
import "core:image"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "base:runtime"

Image        :: image.Image
Format       :: image.Netpbm_Format
Header       :: image.Netpbm_Header
Info         :: image.Netpbm_Info
Error        :: image.Error
Format_Error :: image.Netpbm_Error

Formats :: bit_set[Format]
PBM     :: Formats{.P1, .P4}
PGM     :: Formats{.P2, .P5}
PPM     :: Formats{.P3, .P6}
PNM     :: PBM + PGM + PPM
PAM     :: Formats{.P7}
PFM     :: Formats{.Pf, .PF}
ASCII   :: Formats{.P1, .P2, .P3}
BINARY  :: Formats{.P4, .P5, .P6} + PAM + PFM

load_from_bytes :: proc(data: []byte, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator

	img = new(Image)
	img.which = .NetPBM

	header: Header; defer header_destroy(&header)
	header_size: int
	header, header_size = parse_header(data) or_return

	img_data := data[header_size:]
	decode_image(img, header, img_data) or_return

	info := new(Info)
	info.header = header
	if header.format == .P7 && header.tupltype != "" {
		info.header.tupltype = strings.clone(header.tupltype)
	}
	img.metadata = info

	return img, nil
}

save_to_buffer :: proc(img: ^Image, custom_info: Info = {}, allocator := context.allocator) -> (buffer: []byte, err: Error) {
	context.allocator = allocator

	info: Info = {}
	if custom_info.header.width > 0 {
		// Custom info has been set, use it.
		info = custom_info
	} else {
		img_info, ok := img.metadata.(^image.Netpbm_Info)
		if !ok {
			// image doesn't have .Netpbm info, guess it
			auto_info, auto_info_found := autoselect_pbm_format_from_image(img)
			if auto_info_found {
				info = auto_info
			} else {
				return {}, .Invalid_Input_Image
			}
		} else {
			// use info as stored on image
			info = img_info^
		}
	}

	// using info so we can just talk about the header
	using info

	// validation
	if header.format in (PBM + PGM + Formats{.Pf}) && img.channels != 1 \
	|| header.format in (PPM + Formats{.PF}) && img.channels != 3 {
		err = .Invalid_Number_Of_Channels
		return
	}

	if header.format in (PNM + PAM) {
		if header.maxval <= int(max(u8)) && img.depth != 8 \
		|| header.maxval > int(max(u8)) && header.maxval <= int(max(u16)) && img.depth != 16 {
			err = .Invalid_Image_Depth
			return
		}
	} else if header.format in PFM && img.depth != 32 {
		err = .Invalid_Image_Depth
		return
	}

	// we will write to a string builder
	data: strings.Builder
	strings.builder_init(&data)

	// all PNM headers start with the format
	fmt.sbprintf(&data, "%s\n", header.format)
	if header.format in PNM {
		fmt.sbprintf(&data, "%i %i\n", img.width, img.height)
		if header.format not_in PBM {
			fmt.sbprintf(&data, "%i\n", header.maxval)
		}
	} else if header.format in PAM {
		if len(header.tupltype) > 0 {
			fmt.sbprintf(&data, "WIDTH %i\nHEIGHT %i\nMAXVAL %i\nDEPTH %i\nTUPLTYPE %s\nENDHDR\n",
				img.width, img.height, header.maxval, img.channels, header.tupltype)
		} else {
			fmt.sbprintf(&data, "WIDTH %i\nHEIGHT %i\nMAXVAL %i\nDEPTH %i\nENDHDR\n",
				img.width, img.height, header.maxval, img.channels)
		}

	} else if header.format in PFM {
		scale := -header.scale if header.little_endian else header.scale
		fmt.sbprintf(&data, "%i %i\n%f\n", img.width, img.height, scale)
	}

	switch header.format {
	// Compressed binary
	case .P4:
		header_buf := data.buf[:]
		pixels := img.pixels.buf[:]

		p4_buffer_size := (img.width / 8 + 1) * img.height
		reserve(&data.buf, len(header_buf) + p4_buffer_size)

		// we build up a byte value until it is completely filled
		// or we reach the end the row
		for y in 0 ..< img.height {
			b: byte

			for x in 0 ..< img.width {
				i := y * img.width + x
				bit := byte(7 - (x % 8))
				v : byte = 0 if pixels[i] == 0 else 1
				b |= (v << bit)

				if bit == 0 {
					append(&data.buf, b)
					b = 0
				}
			}

			if b != 0 {
				append(&data.buf, b)
				b = 0
			}
		}

	// Simple binary
	case .P5, .P6, .P7, .Pf, .PF:
		header_buf := data.buf[:]
		pixels := img.pixels.buf[:]

		resize(&data.buf, len(header_buf) + len(pixels))
		mem.copy(raw_data(data.buf[len(header_buf):]), raw_data(pixels), len(pixels))

		// convert from native endianness
		if img.depth == 16 {
			pixels := mem.slice_data_cast([]u16be, data.buf[len(header_buf):])
			for &p in pixels {
				p = u16be(transmute(u16) p)
			}
		} else if header.format in PFM {
			if header.little_endian {
				pixels := mem.slice_data_cast([]f32le, data.buf[len(header_buf):])
				for &p in pixels {
					p = f32le(transmute(f32) p)
				}
			} else {
				pixels := mem.slice_data_cast([]f32be, data.buf[len(header_buf):])
				for &p in pixels {
					p = f32be(transmute(f32) p)
				}
			}
		}

	// If-it-looks-like-a-bitmap ASCII
	case .P1:
		pixels := img.pixels.buf[:]
		for y in 0 ..< img.height {
			for x in 0 ..< img.width {
				i := y * img.width + x
				append(&data.buf, '0' if pixels[i] == 0 else '1')
			}
			append(&data.buf, '\n')
		}

	// Token ASCII
	case .P2, .P3:
		switch img.depth {
		case 8:
			pixels := img.pixels.buf[:]
			for y in 0 ..< img.height {
				for x in 0 ..< img.width {
					i := y * img.width + x
					for c in 0 ..< img.channels {
						j := i * img.channels + c
						fmt.sbprintf(&data, "%i ", pixels[j])
					}
					fmt.sbprint(&data, "\n")
				}
				fmt.sbprint(&data, "\n")
			}

		case 16:
			pixels := mem.slice_data_cast([]u16, img.pixels.buf[:])
			for y in 0 ..< img.height {
				for x in 0 ..< img.width {
					i := y * img.width + x
					for c in 0 ..< img.channels {
						j := i * img.channels + c
						fmt.sbprintf(&data, "%i ", pixels[j])
					}
					fmt.sbprint(&data, "\n")
				}
				fmt.sbprint(&data, "\n")
			}

		case:
			return data.buf[:], .Invalid_Image_Depth
		}

	case:
		return data.buf[:], .Invalid_Format
	}

	return data.buf[:], Format_Error.None
}

parse_header :: proc(data: []byte, allocator := context.allocator) -> (header: Header, length: int, err: Error) {
	context.allocator = allocator

	// we need the signature and a space
	if len(data) < 3 {
		err = Format_Error.Incomplete_Header
		return
	}

	if data[0] == 'P' {
		switch data[1] {
		case '1' ..= '6':
			return _parse_header_pnm(data)
		case '7':
			return _parse_header_pam(data, allocator)
		case 'F', 'f':
			return _parse_header_pfm(data)
		}
	}

	err = .Invalid_Signature
	return
}

@(private)
_parse_header_pnm :: proc(data: []byte) -> (header: Header, length: int, err: Error) {
	SIG_LENGTH :: 2

	{
		header_formats := []Format{.P1, .P2, .P3, .P4, .P5, .P6}
		header.format = header_formats[data[1] - '0' - 1]
	}

	// have a list of fielda for easy iteration
	header_fields: []^int
	if header.format in PBM {
		header_fields = {&header.width, &header.height}
		header.maxval = 1 // we know maxval for a bitmap
	} else {
		header_fields = {&header.width, &header.height, &header.maxval}
	}

	// we're keeping track of the header byte length
	length = SIG_LENGTH

	// loop state
	in_comment := false
	already_in_space := true
	current_field := 0
	current_value := header_fields[0]

	parse_loop: for d in data[SIG_LENGTH:] {
		length += 1

		// handle comments
		if in_comment {
			switch d {
			// comments only go up to next carriage return or line feed
			case '\r', '\n':
				in_comment = false
			}
			continue
		} else if d == '#' {
			in_comment = true
			continue
		}

		// handle whitespace
		in_space := unicode.is_white_space(rune(d))
		if in_space {
			if already_in_space {
				continue
			}
			already_in_space = true

			// switch to next value
			current_field += 1
			if current_field == len(header_fields) {
				// header byte length is 1-index so we'll increment again
				length += 1
				break parse_loop
			}
			current_value = header_fields[current_field]
		} else {
			already_in_space = false

			if !unicode.is_digit(rune(d)) {
				err = Format_Error.Invalid_Header_Token_Character
				return
			}

			val := int(d - '0')
			current_value^ = current_value^ * 10 + val
		}
	}

	// set extra info
	header.channels = 3 if header.format in PPM else 1
	header.depth    = 16 if header.maxval > int(max(u8)) else 8

	// limit checking
	if current_field < len(header_fields) {
		err = Format_Error.Incomplete_Header
		return
	}

	if header.width < 1 \
	|| header.height < 1 \
	|| header.maxval < 1 || header.maxval > int(max(u16)) {
		fmt.printf("[pnm] Header: {{width = %v, height = %v, maxval: %v}}\n", header.width, header.height, header.maxval)
		err = .Invalid_Header_Value
		return
	}

	length -= 1
	err = Format_Error.None
	return
}

@(private)
_parse_header_pam :: proc(data: []byte, allocator := context.allocator) -> (header: Header, length: int, err: Error) {
	context.allocator = allocator

	// the spec needs the newline apparently
	if string(data[0:3]) != "P7\n" {
		err = .Invalid_Signature
		return
	}
	header.format = .P7

	SIGNATURE_LENGTH :: 3
	HEADER_END :: "ENDHDR\n"

	// we can already work out the size of the header
	header_end_index := strings.index(string(data), HEADER_END)
	if header_end_index == -1 {
		err = Format_Error.Incomplete_Header
		return
	}
	length = header_end_index + len(HEADER_END)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	// string buffer for the tupltype
	tupltype: strings.Builder
	strings.builder_init(&tupltype, context.temp_allocator); defer strings.builder_destroy(&tupltype)
	fmt.sbprint(&tupltype, "")

	// PAM uses actual lines, so we can iterate easily
	line_iterator := string(data[SIGNATURE_LENGTH : header_end_index])
	parse_loop: for line in strings.split_lines_iterator(&line_iterator) {
		line := line

		if len(line) == 0 || line[0] == '#' {
			continue
		}

		field, ok := strings.fields_iterator(&line)
		value := strings.trim_space(line)

		// the field will change, but the logic stays the same
		current_field: ^int

		switch field {
		case "WIDTH":  current_field = &header.width
		case "HEIGHT": current_field = &header.height
		case "DEPTH":  current_field = &header.channels
		case "MAXVAL": current_field = &header.maxval

		case "TUPLTYPE":
			if len(value) == 0 {
				err = .Invalid_Header_Value
				return
			}

			if len(tupltype.buf) == 0 {
				fmt.sbprint(&tupltype, value)
			} else {
				fmt.sbprint(&tupltype, "", value)
			}

			continue

		case:
			continue
		}

		if current_field^ != 0 {
			err = Format_Error.Duplicate_Header_Field
			return
		}
		current_field^, ok = strconv.parse_int(value)
		if !ok {
			err = Format_Error.Invalid_Header_Value
			return
		}
	}

	// extra info
	header.depth = 16 if header.maxval > int(max(u8)) else 8

	// limit checking
	if header.width < 1 \
	|| header.height < 1 \
	|| header.maxval < 1 \
	|| header.maxval > int(max(u16)) {
		fmt.printf("[pam] Header: {{width = %v, height = %v, maxval: %v}}\n", header.width, header.height, header.maxval)
		err = Format_Error.Invalid_Header_Value
		return
	}

	header.tupltype = strings.clone(strings.to_string(tupltype))
	err = Format_Error.None
	return
}

@(private)
_parse_header_pfm :: proc(data: []byte) -> (header: Header, length: int, err: Error) {
	// we can just cycle through tokens for PFM
	field_iterator := string(data)
	field, ok := strings.fields_iterator(&field_iterator)

	switch field {
	case "Pf":
		header.format = .Pf
		header.channels = 1
	case "PF":
		header.format = .PF
		header.channels = 3
	case:
		err = .Invalid_Signature
		return
	}

	// floating point
	header.depth = 32

	// width
	field, ok = strings.fields_iterator(&field_iterator)
	if !ok {
		err = Format_Error.Incomplete_Header
		return
	}
	header.width, ok = strconv.parse_int(field)
	if !ok {
		err = Format_Error.Invalid_Header_Value
		return
	}

	// height
	field, ok = strings.fields_iterator(&field_iterator)
	if !ok {
		err = Format_Error.Incomplete_Header
		return
	}
	header.height, ok = strconv.parse_int(field)
	if !ok {
		err = Format_Error.Invalid_Header_Value
		return
	}

	// scale (sign is endianness)
	field, ok = strings.fields_iterator(&field_iterator)
	if !ok {
		err = Format_Error.Incomplete_Header
		return
	}
	header.scale, ok = strconv.parse_f32(field)
	if !ok {
		err = Format_Error.Invalid_Header_Value
		return
	}

	if header.scale < 0.0 {
		header.little_endian = true
		header.scale = -header.scale
	}

	// pointer math to get header size
	length = int((uintptr(raw_data(field_iterator)) + 1) - uintptr(raw_data(data)))

	// limit checking
	if header.width < 1 \
	|| header.height < 1 \
	|| header.scale == 0.0 {
		fmt.printf("[pfm] Header: {{width = %v, height = %v, scale: %v}}\n", header.width, header.height, header.scale)
		err = .Invalid_Header_Value
		return
	}

	err = Format_Error.None
	return
}

decode_image :: proc(img: ^Image, header: Header, data: []byte, allocator := context.allocator) -> (err: Error) {
	assert(img != nil)
	context.allocator = allocator

	img.width    = header.width
	img.height   = header.height
	img.channels = header.channels
	img.depth    = header.depth

	buffer_size := image.compute_buffer_size(img.width, img.height, img.channels, img.depth)

	// we can check data size for binary formats
	if header.format in BINARY {
		if len(data) < buffer_size {
			fmt.printf("len(data): %v, buffer size: %v\n", len(data), buffer_size)
			return .Buffer_Too_Small
		}
	}

	// for ASCII and P4, we use length for the termination condition, so start at 0
	// BINARY will be a simple memcopy so the buffer length should also be initialised
	if header.format in ASCII || header.format == .P4 {
		bytes.buffer_init_allocator(&img.pixels, 0, buffer_size)
	} else {
		bytes.buffer_init_allocator(&img.pixels, buffer_size, buffer_size)
	}

	switch header.format {
	// Compressed binary
	case .P4:
		for d in data {
			for b in 1 ..= 8 {
				bit := byte(8 - b)
				pix := (d >> bit) & 1
				bytes.buffer_write_byte(&img.pixels, pix)
				if len(img.pixels.buf) % img.width == 0 {
					break
				}
			}

			if len(img.pixels.buf) == cap(img.pixels.buf) {
				break
			}
		}

	// Simple binary
	case .P5, .P6, .P7, .Pf, .PF:
		copy(img.pixels.buf[:], data[:])

		// convert to native endianness
		if header.format in PFM {
			pixels := mem.slice_data_cast([]f32, img.pixels.buf[:])
			if header.little_endian {
				for &p in pixels {
					p = f32(transmute(f32le) p)
				}
			} else {
				for &p in pixels {
					p = f32(transmute(f32be) p)
				}
			}
		} else {
			if img.depth == 16 {
				pixels := mem.slice_data_cast([]u16, img.pixels.buf[:])
				for &p in pixels {
					p = u16(transmute(u16be) p)
				}
			}
		}

	// If-it-looks-like-a-bitmap ASCII
	case .P1:
		for c in data {
			switch c {
			case '0', '1':
				bytes.buffer_write_byte(&img.pixels, c - '0')
			}

			if len(img.pixels.buf) == cap(img.pixels.buf) {
				break
			}
		}

		if len(img.pixels.buf) < cap(img.pixels.buf) {
			err = Format_Error.Buffer_Too_Small
			return
		}

	// Token ASCII
	case .P2, .P3:
		field_iterator := string(data)
		for field in strings.fields_iterator(&field_iterator) {
			value, ok := strconv.parse_int(field)
			if !ok {
				err = Format_Error.Invalid_Buffer_ASCII_Token
				return
			}

			//? do we want to enforce the maxval, the limit, or neither
			if value > int(max(u16)) /*header.maxval*/ {
				err = Format_Error.Invalid_Buffer_Value
				return
			}

			switch img.depth {
			case 8:
				bytes.buffer_write_byte(&img.pixels, u8(value))
			case 16:
				vb := transmute([2]u8) u16(value)
				bytes.buffer_write(&img.pixels, vb[:])
			}

			if len(img.pixels.buf) == cap(img.pixels.buf) {
				break
			}
		}

		if len(img.pixels.buf) < cap(img.pixels.buf) {
			err = Format_Error.Buffer_Too_Small
			return
		}
	}

	err = Format_Error.None
	return
}

// Automatically try to select an appropriate format to save to based on `img.channel` and `img.depth`
autoselect_pbm_format_from_image :: proc(img: ^Image, prefer_binary := true, force_black_and_white := false, pfm_scale := f32(1.0)) -> (res: Info, ok: bool) {
	/*
		PBM (P1, P4): Portable Bit Map,       stores black and white images   (1 channel)
		PGM (P2, P5): Portable Gray Map,      stores greyscale images         (1 channel, 1 or 2 bytes per value)
		PPM (P3, P6): Portable Pixel Map,     stores colour images            (3 channel, 1 or 2 bytes per value)
		PAM (P7    ): Portable Arbitrary Map, stores arbitrary channel images            (1 or 2 bytes per value)
		PFM (Pf, PF): Portable Float Map,     stores floating-point images    (Pf: 1 channel, PF: 3 channel)

		ASCII   :: Formats{.P1, .P2, .P3}
	*/
	using res.header

	width    = img.width
	height   = img.height
	channels = img.channels
	depth    = img.depth
	maxval   = 255 if img.depth == 8 else 65535
	little_endian = true if ODIN_ENDIAN == .Little else false

	// Assume we'll find a suitable format
	ok = true

	switch img.channels {
	case 1:
		// Must be Portable Float Map
		if img.depth == 32 {
			format = .Pf
			return
		}

		if force_black_and_white {
			// Portable Bit Map
			format = .P4 if prefer_binary else .P1
			maxval = 1
			return
		} else {
			// Portable Gray Map
			format = .P5 if prefer_binary else .P2
			return
		}

	case 3:
		// Must be Portable Float Map
		if img.depth == 32 {
			format = .PF
			return
		}

		// Portable Pixel Map
		format = .P6 if prefer_binary else .P3
		return

	case:
		// Portable Arbitrary Map
		if img.depth == 8 || img.depth == 16 {
			format = .P7
			scale  = pfm_scale
			return
		}
	}

	// We couldn't find a suitable format
	return {}, false
}

@(init, private)
_register :: proc() {
	loader :: proc(data: []byte, options: image.Options, allocator: mem.Allocator) -> (img: ^Image, err: Error) {
		return load_from_bytes(data, allocator)
	}
	destroyer :: proc(img: ^Image) {
		_ = destroy(img)
	}
	image.register(.NetPBM, loader, destroyer)
}
