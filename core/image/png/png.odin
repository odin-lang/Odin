package png

import "core:compress"
import "core:compress/zlib"
import "core:image"

import "core:os"
import "core:strings"
import "core:hash"
import "core:bytes"
import "core:io"
import "core:mem"
import "core:intrinsics"

Error     :: compress.Error;
E_General :: compress.General_Error;
E_PNG     :: image.Error;
E_Deflate :: compress.Deflate_Error;

Image     :: image.Image;
Options   :: image.Options;

Signature :: enum u64be {
	// 0x89504e470d0a1a0a
	PNG = 0x89 << 56 | 'P' << 48 | 'N' << 40 | 'G' << 32 | '\r' << 24 | '\n' << 16 | 0x1a << 8 | '\n',
}

Info :: struct {
	header: IHDR,
	chunks: [dynamic]Chunk,
}

Chunk_Header :: struct #packed {
	length: u32be,
	type:   Chunk_Type,
}

Chunk :: struct #packed {
	header: Chunk_Header,
	data:   []byte,
	crc:    u32be,
}

Chunk_Type :: enum u32be {
	// IHDR must come first in a file
	IHDR = 'I' << 24 | 'H' << 16 | 'D' << 8 | 'R',
	// PLTE must precede the first IDAT chunk
	PLTE = 'P' << 24 | 'L' << 16 | 'T' << 8 | 'E',
	bKGD = 'b' << 24 | 'K' << 16 | 'G' << 8 | 'D',
	tRNS = 't' << 24 | 'R' << 16 | 'N' << 8 | 'S',
	IDAT = 'I' << 24 | 'D' << 16 | 'A' << 8 | 'T',

	iTXt = 'i' << 24 | 'T' << 16 | 'X' << 8 | 't',
	tEXt = 't' << 24 | 'E' << 16 | 'X' << 8 | 't',
	zTXt = 'z' << 24 | 'T' << 16 | 'X' << 8 | 't',

	iCCP = 'i' << 24 | 'C' << 16 | 'C' << 8 | 'P',
	pHYs = 'p' << 24 | 'H' << 16 | 'Y' << 8 | 's',
	gAMA = 'g' << 24 | 'A' << 16 | 'M' << 8 | 'A',
	tIME = 't' << 24 | 'I' << 16 | 'M' << 8 | 'E',

	sPLT = 's' << 24 | 'P' << 16 | 'L' << 8 | 'T',
	sRGB = 's' << 24 | 'R' << 16 | 'G' << 8 | 'B',
	hIST = 'h' << 24 | 'I' << 16 | 'S' << 8 | 'T',
	cHRM = 'c' << 24 | 'H' << 16 | 'R' << 8 | 'M',
	sBIT = 's' << 24 | 'B' << 16 | 'I' << 8 | 'T',

	/*
		eXIf tags are not part of the core spec, but have been ratified
		in v1.5.0 of the PNG Ext register.

		We will provide unprocessed chunks to the caller if `.return_metadata` is set.
		Applications are free to implement an Exif decoder.
	*/
	eXIf = 'e' << 24 | 'X' << 16 | 'I' << 8 | 'f',

	// PNG files must end with IEND
	IEND = 'I' << 24 | 'E' << 16 | 'N' << 8 | 'D',

	/*
		XCode sometimes produces "PNG" files that don't adhere to the PNG spec.
		We recognize them only in order to avoid doing further work on them.

		Some tools like PNG Defry may be able to repair them, but we're not
		going to reward Apple for producing proprietary broken files purporting
		to be PNGs by supporting them.

	*/
	iDOT = 'i' << 24 | 'D' << 16 | 'O' << 8 | 'T',
	CbGI = 'C' << 24 | 'b' << 16 | 'H' << 8 | 'I',
}

IHDR :: struct #packed {
	width: u32be,
	height: u32be,
	bit_depth: u8,
	color_type: Color_Type,
	compression_method: u8,
	filter_method: u8,
	interlace_method: Interlace_Method,
}
IHDR_SIZE :: size_of(IHDR);
#assert (IHDR_SIZE == 13);

Color_Value :: enum u8 {
	Paletted = 0, // 1 << 0 = 1
	Color    = 1, // 1 << 1 = 2
	Alpha    = 2, // 1 << 2 = 4
}
Color_Type :: distinct bit_set[Color_Value; u8];

Interlace_Method :: enum u8 {
	None  = 0,
	Adam7 = 1,
}

Row_Filter :: enum u8 {
	None    = 0,
	Sub     = 1,
	Up      = 2,
	Average = 3,
	Paeth   = 4,
};

PLTE_Entry    :: [3]u8;

PLTE :: struct #packed {
	entries: [256]PLTE_Entry,
	used: u16,
}

hIST :: struct #packed {
	entries: [256]u16,
	used: u16,
}

sPLT :: struct #packed {
	name: string,
	depth: u8,
	entries: union {
		[][4]u8,
		[][4]u16,
	},
	used: u16,
}

// Other chunks
tIME :: struct #packed {
	year:   u16be,
	month:  u8,
	day:    u8,
	hour:   u8,
	minute: u8,
	second: u8,
};
#assert(size_of(tIME) == 7);

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
#assert(size_of(cHRM_Raw) == 32);

cHRM :: struct #packed {
	w: CIE_1931,
	r: CIE_1931,
	g: CIE_1931,
	b: CIE_1931,
}
#assert(size_of(cHRM) == 32);

gAMA :: struct {
	gamma_100k: u32be, // Gamma * 100k
};
#assert(size_of(gAMA) == 4);

pHYs :: struct #packed {
	ppu_x: u32be,
	ppu_y: u32be,
	unit:  pHYs_Unit,
};
#assert(size_of(pHYs) == 9);

pHYs_Unit :: enum u8 {
	Unknown = 0,
	Meter   = 1,
};

Text :: struct {
	keyword:           string,
	keyword_localized: string,
	language:          string,
	text:              string,
};

Exif :: struct {
	byte_order: enum {
		little_endian,
		big_endian,
	},
	data: []u8,
}

iCCP :: struct {
	name: string,
	profile: []u8,
}

sRGB_Rendering_Intent :: enum u8 {
	Perceptual = 0,
	Relative_colorimetric = 1,
	Saturation = 2,
	Absolute_colorimetric = 3,
}

sRGB :: struct #packed {
	intent: sRGB_Rendering_Intent,
}

ADAM7_X_ORIG    := []int{ 0,4,0,2,0,1,0 };
ADAM7_Y_ORIG    := []int{ 0,0,4,0,2,0,1 };
ADAM7_X_SPACING := []int{ 8,8,4,4,2,2,1 };
ADAM7_Y_SPACING := []int{ 8,8,8,4,4,2,2 };

// Implementation starts here

read_chunk :: proc(ctx: ^compress.Context) -> (chunk: Chunk, err: Error) {
	ch, e := compress.read_data(ctx, Chunk_Header);
	if e != .None {
		return {}, E_General.Stream_Too_Short;
	}
	chunk.header = ch;

	data := make([]u8, ch.length, context.temp_allocator);
	_, e2 := ctx.input->impl_read(data);
	if e2 != .None {
		return {}, E_General.Stream_Too_Short;
	}
	chunk.data = data;

	// Compute CRC over chunk type + data
	type := (^[4]byte)(&ch.type)^;
	computed_crc := hash.crc32(type[:]);
	computed_crc =  hash.crc32(data, computed_crc);

	crc, e3 := compress.read_data(ctx, u32be);
	if e3 != .None {
		return {}, E_General.Stream_Too_Short;
	}
	chunk.crc = crc;

	if chunk.crc != u32be(computed_crc) {
		return {}, E_General.Checksum_Failed;
	}
	return chunk, nil;
}

read_header :: proc(ctx: ^compress.Context) -> (IHDR, Error) {
	c, e := read_chunk(ctx);
	if e != nil {
		return {}, e;
	}

	header := (^IHDR)(raw_data(c.data))^;
	// Validate IHDR
	using header;
	if width == 0 || height == 0 {
		return {}, E_PNG.Invalid_Image_Dimensions;
	}

	if compression_method != 0 {
		return {}, E_General.Unknown_Compression_Method;
	}

	if filter_method != 0 {
		return {}, E_PNG.Unknown_Filter_Method;
	}

	if interlace_method != .None && interlace_method != .Adam7 {
		return {}, E_PNG.Unknown_Interlace_Method;

	}

	switch transmute(u8)color_type {
	case 0:
		/*
			Grayscale.
			Allowed bit depths: 1, 2, 4, 8 and 16.
		*/
		allowed := false;
		for i in ([]u8{1, 2, 4, 8, 16}) {
			if bit_depth == i {
				allowed = true;
				break;
			}
		}
		if !allowed {
			return {}, E_PNG.Invalid_Color_Bit_Depth_Combo;
		}
	case 2, 4, 6:
		/*
			RGB, Grayscale+Alpha, RGBA.
			Allowed bit depths: 8 and 16
		*/
		if bit_depth != 8 && bit_depth != 16 {
			return {}, E_PNG.Invalid_Color_Bit_Depth_Combo;
		}
	case 3:
		/*
			Paletted. PLTE chunk must appear.
			Allowed bit depths: 1, 2, 4 and 8.
		*/
		allowed := false;
		for i in ([]u8{1, 2, 4, 8}) {
			if bit_depth == i {
				allowed = true;
				break;
			}
		}
		if !allowed {
			return {}, E_PNG.Invalid_Color_Bit_Depth_Combo;
		}

	case:
		return {}, E_PNG.Unknown_Color_Type;
	}

	return header, nil;
}

chunk_type_to_name :: proc(type: ^Chunk_Type) -> string {
	t := transmute(^u8)type;
	return strings.string_from_ptr(t, 4);
}

load_from_slice :: proc(slice: []u8, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	r := bytes.Reader{};
	bytes.reader_init(&r, slice);
	stream := bytes.reader_to_stream(&r);

	/*
		TODO: Add a flag to tell the PNG loader that the stream is backed by a slice.
		This way the stream reader could avoid the copy into the temp memory returned by it,
		and instead return a slice into the original memory that's already owned by the caller.
	*/
	img, err = load_from_stream(stream, options, allocator);

	return img, err;
}

load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	data, ok := os.read_entire_file(filename, allocator);
	defer delete(data);

	if ok {
		img, err = load_from_slice(data, options, allocator);
		return;
	} else {
		img = new(Image);
		return img, E_General.File_Not_Found;
	}
}

load_from_stream :: proc(stream: io.Stream, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	options := options;
	if .info in options {
		options |= {.return_metadata, .do_not_decompress_image};
		options -= {.info};
	}

	if .alpha_drop_if_present in options && .alpha_add_if_missing in options {
		return {}, E_General.Incompatible_Options;
	}

	if .do_not_expand_channels in options {
		options |= {.do_not_expand_grayscale, .do_not_expand_indexed};
	}

	if img == nil {
		img = new(Image);
	}

	img.sidecar = nil;

	ctx := &compress.Context{
		input = stream,
	};

	signature, io_error := compress.read_data(ctx, Signature);
	if io_error != .None || signature != .PNG {
		return img, E_PNG.Invalid_PNG_Signature;
	}

	idat: []u8;
	idat_b: bytes.Buffer;
	idat_length := u32be(0);
	defer bytes.buffer_destroy(&idat_b);

	c:		Chunk;
	ch:     Chunk_Header;
	e:      io.Error;

	header:	IHDR;
	info:   Info;
	info.chunks.allocator = context.temp_allocator;

	// State to ensure correct chunk ordering.
	seen_ihdr := false; first := true;
	seen_plte := false;
	seen_bkgd := false;
	seen_trns := false;
	seen_idat := false;
	seen_iend := false;

	_plte := PLTE{};
	trns := Chunk{};

	final_image_channels := 0;

	read_error: io.Error;
	// 12 bytes is the size of a chunk with a zero-length payload.
	for read_error == .None && !seen_iend {
		// Peek at next chunk's length and type.
		// TODO: Some streams may not provide seek/read_at

		ch, e = compress.peek_data(ctx, Chunk_Header);
		if e != .None {
			return img, E_General.Stream_Too_Short;
		}
		// name := chunk_type_to_name(&ch.type); // Only used for debug prints during development.

		#partial switch ch.type {
		case .IHDR:
			if seen_ihdr || !first {
				return {}, E_PNG.IHDR_Not_First_Chunk;
			}
			seen_ihdr = true;

			header, err = read_header(ctx);
			if err != nil {
				return img, err;
			}

			if .Paletted in header.color_type {
				// Color type 3
				img.channels = 1;
				final_image_channels = 3;
				img.depth    = 8;
			} else if .Color in header.color_type {
				// Color image without a palette
				img.channels = 3;
				final_image_channels = 3;
				img.depth    = header.bit_depth;
			} else {
				// Grayscale
				img.channels = 1;
				final_image_channels = 1;
				img.depth    = header.bit_depth;
			}

			if .Alpha in header.color_type {
				img.channels += 1;
				final_image_channels += 1;
			}

			if img.channels == 0 || img.depth == 0 {
				return {}, E_PNG.IHDR_Corrupt;
			}

			img.width  = int(header.width);
			img.height = int(header.height);

			using header;
			h := IHDR{
				width              = width,
				height             = height,
				bit_depth          = bit_depth,
				color_type         = color_type,
				compression_method = compression_method,
				filter_method      = filter_method,
				interlace_method   = interlace_method,
			};
			info.header = h;
		case .PLTE:
			seen_plte = true;
			// PLTE must appear before IDAT and can't appear for color types 0, 4.
			ct := transmute(u8)info.header.color_type;
			if seen_idat || ct == 0 || ct == 4 {
				return img, E_PNG.PLTE_Encountered_Unexpectedly;
			}

			c, err = read_chunk(ctx);
			if err != nil {
				return img, err;
			}

			if c.header.length % 3 != 0 || c.header.length > 768 {
				return img, E_PNG.PLTE_Invalid_Length;
			}
			plte_ok: bool;
			_plte, plte_ok = plte(c);
			if !plte_ok {
				return img, E_PNG.PLTE_Invalid_Length;
			}

			if .return_metadata in options {
				append(&info.chunks, c);
			}
		case .IDAT:
			// If we only want image metadata and don't want the pixel data, we can early out.
			if .return_metadata not_in options && .do_not_decompress_image in options {
				img.channels = final_image_channels;
				img.sidecar = info;
				return img, nil;
			}
			// There must be at least 1 IDAT, contiguous if more.
			if seen_idat {
				return img, E_PNG.IDAT_Must_Be_Contiguous;
			}

			if idat_length > 0 {
				return img, E_PNG.IDAT_Must_Be_Contiguous;
			}

			next := ch.type;
			for next == .IDAT {
				c, err = read_chunk(ctx);
				if err != nil {
					return img, err;
				}

				bytes.buffer_write(&idat_b, c.data);
				idat_length += c.header.length;

				ch, e = compress.peek_data(ctx, Chunk_Header);
				if e != .None {
					return img, E_General.Stream_Too_Short;
				}
				next = ch.type;
			}
			idat = bytes.buffer_to_bytes(&idat_b);
			if int(idat_length) != len(idat) {
				return {}, E_PNG.IDAT_Corrupt;
			}
			seen_idat = true;
		case .IEND:
			c, err = read_chunk(ctx);
			if err != nil {
				return img, err;
			}
			seen_iend = true;
		case .bKGD:

			// TODO: Make sure that 16-bit bKGD + tRNS chunks return u16 instead of u16be

			c, err = read_chunk(ctx);
			if err != nil {
				return img, err;
			}
			seen_bkgd = true;
			if .return_metadata in options {
				append(&info.chunks, c);
			}

			ct := transmute(u8)info.header.color_type;
			switch ct {
				case 3: // Indexed color
					if c.header.length != 1 {
						return {}, E_PNG.BKGD_Invalid_Length;
					}
					col := _plte.entries[c.data[0]];
					img.background = [3]u16{
						u16(col[0]) << 8 | u16(col[0]),
						u16(col[1]) << 8 | u16(col[1]),
						u16(col[2]) << 8 | u16(col[2]),
					};
				case 0, 4: // Grayscale, with and without Alpha
					if c.header.length != 2 {
						return {}, E_PNG.BKGD_Invalid_Length;
					}
					col := u16(mem.slice_data_cast([]u16be, c.data[:])[0]);
					img.background = [3]u16{col, col, col};
				case 2, 6: // Color, with and without Alpha
					if c.header.length != 6 {
						return {}, E_PNG.BKGD_Invalid_Length;
					}
					col := mem.slice_data_cast([]u16be, c.data[:]);
					img.background = [3]u16{u16(col[0]), u16(col[1]), u16(col[2])};
			}
		case .tRNS:
			c, err = read_chunk(ctx);
			if err != nil {
				return img, err;
			}

			if .Alpha in info.header.color_type {
				return img, E_PNG.TRNS_Encountered_Unexpectedly;
			}

			if .return_metadata in options {
				append(&info.chunks, c);
			}

			/*
				This makes the image one with transparency, so set it to +1 here,
				even if we need we leave img.channels alone for the defilterer's
				sake. If we early because the user just cares about metadata,
				we'll set it to 'final_image_channels'.
			*/

			final_image_channels += 1;

			seen_trns = true;
			if info.header.bit_depth < 8 && .Paletted not_in info.header.color_type {
				// Rescale tRNS data so key matches intensity
				dsc := depth_scale_table;
				scale := dsc[info.header.bit_depth];
				if scale != 1 {
					key := mem.slice_data_cast([]u16be, c.data)[0] * u16be(scale);
					c.data = []u8{0, u8(key & 255)};
				}
			}
			trns = c;
		case .iDOT, .CbGI:
			/*
				iPhone PNG bastardization that doesn't adhere to spec with broken IDAT chunk.
				We're not going to add support for it. If you have the misfortunte of coming
				across one of these files, use a utility to defry it.s
			*/
			return img, E_PNG.PNG_Does_Not_Adhere_to_Spec;
		case:
			// Unhandled type
			c, err = read_chunk(ctx);
			if err != nil {
				return img, err;
			}
			if .return_metadata in options {
				// NOTE: Chunk cata is currently allocated on the temp allocator.
				append(&info.chunks, c);
			}

			first = false;
		}
	}

	if .return_header in options || .return_metadata in options {
		img.sidecar = info;
	}
	if .do_not_decompress_image in options {
		img.channels = final_image_channels;
		return img, nil;
	}

	if !seen_idat {
		return img, E_PNG.IDAT_Missing;
	}

	buf: bytes.Buffer;
	zlib_error := zlib.inflate(idat, &buf);
	defer bytes.buffer_destroy(&buf);

	if zlib_error != nil {
		return {}, zlib_error;
	} else {
		/*
			Let's calcalate the expected size of the IDAT based on its dimensions,
			and whether or not it's interlaced
		*/
		expected_size: int;
		buf_len := len(buf.buf);

		if header.interlace_method != .Adam7 {
			expected_size = compute_buffer_size(int(header.width), int(header.height), int(img.channels), int(header.bit_depth), 1);
		} else {
			/*
				Because Adam7 divides the image up into sub-images, and each scanline must start
				with a filter byte, Adam7 interlaced images can have a larger raw size.
			*/
			for p := 0; p < 7; p += 1 {
				x := (int(header.width)  - ADAM7_X_ORIG[p] + ADAM7_X_SPACING[p] - 1) / ADAM7_X_SPACING[p];
				y := (int(header.height) - ADAM7_Y_ORIG[p] + ADAM7_Y_SPACING[p] - 1) / ADAM7_Y_SPACING[p];
				if x > 0 && y > 0 {
					expected_size += compute_buffer_size(int(x), int(y), int(img.channels), int(header.bit_depth), 1);
				}
			}
		}

		if expected_size != buf_len {
			return {}, E_PNG.IDAT_Corrupt;
		}
	}

	/*
		Defilter just cares about the raw number of image channels present.
		So, we'll save the old value of img.channels we return to the user
		as metadata, and set it instead to the raw number of channels.
	*/
	defilter_error := defilter(img, &buf, &header, options);
	if defilter_error != nil {
		bytes.buffer_destroy(&img.pixels);
		return {}, defilter_error;
	}

	/*
		Now we'll handle the relocoring of paletted images, handling of tRNS chunks,
		and we'll expand grayscale images to RGB(A).

		For the sake of convenience we return only RGB(A) images. In the future we
		may supply an option to return Gray/Gray+Alpha as-is, in which case RGB(A)
		will become the default.
	*/

	if .Paletted in header.color_type && .do_not_expand_indexed in options {
		return img, nil;
	}
	if .Color not_in header.color_type && .do_not_expand_grayscale in options {
		return img, nil;
	}


	raw_image_channels := img.channels;
	out_image_channels := 3;

	/*
		To give ourselves less options to test, we'll knock out
		`.blend_background` and `seen_bkgd` if we haven't seen both.
	*/
	if !(seen_bkgd && .blend_background in options) {
		options -= {.blend_background};
		seen_bkgd = false;
	}

	if seen_trns || .Alpha in info.header.color_type || .alpha_add_if_missing in options {
		out_image_channels = 4;
	}

	if .alpha_drop_if_present in options {
		out_image_channels = 3;
	}

	if seen_bkgd && .blend_background in options && .alpha_add_if_missing not_in options {
		out_image_channels = 3;
	}

	add_alpha   := (seen_trns && .alpha_drop_if_present not_in options) || (.alpha_add_if_missing in options);
	premultiply := .alpha_premultiply in options || seen_bkgd;

	img.channels = out_image_channels;

	if .Paletted in header.color_type {
		temp := img.pixels;
		defer bytes.buffer_destroy(&temp);

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 8);
		t := bytes.Buffer{};
		resize(&t.buf, dest_raw_size);

		i := 0; j := 0;

		// If we don't have transparency or drop it without applying it, we can do this:
		if (!seen_trns || (seen_trns && .alpha_drop_if_present in options && .alpha_premultiply not_in options)) && .alpha_add_if_missing not_in options {
			for h := 0; h < int(img.height); h += 1 {
				for w := 0; w < int(img.width);  w += 1 {
					c := _plte.entries[temp.buf[i]];
					t.buf[j  ] = c.r;
					t.buf[j+1] = c.g;
					t.buf[j+2] = c.b;
					i += 1; j += 3;
				}
			}
		} else if add_alpha || .alpha_drop_if_present in options {
			bg := [3]f32{0, 0, 0};
			if premultiply && seen_bkgd {
				c16 := img.background.([3]u16);
				bg = [3]f32{f32(c16.r), f32(c16.g), f32(c16.b)};
			}

			no_alpha := (.alpha_drop_if_present in options || premultiply) && .alpha_add_if_missing not_in options;
			blend_background := seen_bkgd && .blend_background in options;

			for h := 0; h < int(img.height); h += 1 {
				for w := 0; w < int(img.width);  w += 1 {
					index := temp.buf[i];

					c     := _plte.entries[index];
					a     := int(index) < len(trns.data) ? trns.data[index] : 255;
					alpha := f32(a) / 255.0;

					if blend_background {
						c.r = u8((1.0 - alpha) * bg[0] + f32(c.r) * alpha);
						c.g = u8((1.0 - alpha) * bg[1] + f32(c.g) * alpha);
						c.b = u8((1.0 - alpha) * bg[2] + f32(c.b) * alpha);
						a = 255;
					} else if premultiply {
						c.r = u8(f32(c.r) * alpha);
						c.g = u8(f32(c.g) * alpha);
						c.b = u8(f32(c.b) * alpha);
					}

					t.buf[j  ] = c.r;
					t.buf[j+1] = c.g;
					t.buf[j+2] = c.b;
					i += 1;

					if no_alpha {
						j += 3;
					} else {
						t.buf[j+3] = u8(a);
						j += 4;
					}
				}
			}
		} else {
			unreachable();
		}

		img.pixels = t;

	} else if img.depth == 16 {
		// Check if we need to do something.
		if raw_image_channels == out_image_channels {
			// If we have 3 in and 3 out, or 4 in and 4 out without premultiplication...
			if raw_image_channels == 4 && .alpha_premultiply not_in options && !seen_bkgd {
				// Then we're done.
				return img, nil;
			}
		}

		temp := img.pixels;
		defer bytes.buffer_destroy(&temp);

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 16);
		t := bytes.Buffer{};
		resize(&t.buf, dest_raw_size);

		p16 := mem.slice_data_cast([]u16, temp.buf[:]);
		o16 := mem.slice_data_cast([]u16, t.buf[:]);

		switch raw_image_channels {
		case 1:
			// Gray without Alpha. Might have tRNS alpha.
			key   := u16(0);
			if seen_trns {
				key = mem.slice_data_cast([]u16, trns.data)[0];
			}

			for len(p16) > 0 {
				r := p16[0];

				alpha := u16(1); // Default to full opaque

				if seen_trns {
					if r == key {
						if seen_bkgd {
							c := img.background.([3]u16);
							r = c[0];
						} else {
							alpha = 0; // Keyed transparency
						}
					}
				}

				if premultiply {
					o16[0] = r * alpha;
					o16[1] = r * alpha;
					o16[2] = r * alpha;
				} else {
					o16[0] = r;
					o16[1] = r;
					o16[2] = r;
				}

				if out_image_channels == 4 {
					o16[3] = alpha * 65535;
				}

				p16 = p16[1:];
				o16 = o16[out_image_channels:];
			}
		case 2:
			// Gray with alpha, we shouldn't have a tRNS chunk.
			bg := f32(0.0);
			if seen_bkgd {
				bg = f32(img.background.([3]u16)[0]);
			}

			for len(p16) > 0 {
				r := p16[0];
				if seen_bkgd {
					alpha := f32(p16[1]) / f32(65535);
					c := u16(f32(r) * alpha + (1.0 - alpha) * bg);
					o16[0] = c;
					o16[1] = c;
					o16[2] = c;
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					p16[1] = 65535;
				} else if premultiply {
					alpha := p16[1];
					c := u16(f32(r) * f32(alpha) / f32(65535));
					o16[0] = c;
					o16[1] = c;
					o16[2] = c;
				} else {
					o16[0] = r;
					o16[1] = r;
					o16[2] = r;
				}

				if out_image_channels == 4 {
					o16[3] = p16[1];
				}

				p16 = p16[2:];
				o16 = o16[out_image_channels:];
			}
		case 3:
			/*
				Color without Alpha.
				We may still have a tRNS chunk or `.alpha_add_if_missing`.
			*/

			key: []u16;
			if seen_trns {
				key = mem.slice_data_cast([]u16, trns.data);
			}

			for len(p16) > 0 {
				r     := p16[0];
				g     := p16[1];
				b     := p16[2];

				alpha := u16(1); // Default to full opaque

				if seen_trns {
					if r == key[0] && g == key[1] && b == key[2] {
						if seen_bkgd {
							c := img.background.([3]u16);
							r = c[0];
							g = c[1];
							b = c[2];
						} else {
							alpha = 0; // Keyed transparency
						}
					}
				}

				if premultiply {
					o16[0] = r * alpha;
					o16[1] = g * alpha;
					o16[2] = b * alpha;
				} else {
					o16[0] = r;
					o16[1] = g;
					o16[2] = b;
				}

				if out_image_channels == 4 {
					o16[3] = alpha * 65535;
				}

				p16 = p16[3:];
				o16 = o16[out_image_channels:];
			}
		case 4:
			// Color with Alpha, can't have tRNS.
			for len(p16) > 0 {
				r     := p16[0];
				g     := p16[1];
				b     := p16[2];
				a     := p16[3];

				if seen_bkgd {
					alpha := f32(a) / 65535.0;
					c  := img.background.([3]u16);
					rb := f32(c[0]) * (1.0 - alpha);
					gb := f32(c[1]) * (1.0 - alpha);
					bb := f32(c[2]) * (1.0 - alpha);

					o16[0] = u16(f32(r) * alpha + rb);
					o16[1] = u16(f32(g) * alpha + gb);
					o16[2] = u16(f32(b) * alpha + bb);
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					a = 65535;
				} else if premultiply {
					alpha := f32(a) / 65535.0;
					o16[0] = u16(f32(r) * alpha);
					o16[1] = u16(f32(g) * alpha);
					o16[2] = u16(f32(b) * alpha);
				} else {
					o16[0] = r;
					o16[1] = g;
					o16[2] = b;
				}

				if out_image_channels == 4 {
					o16[3] = a;
				}

				p16 = p16[4:];
				o16 = o16[out_image_channels:];
			}
		case:
			unreachable("We should never seen # channels other than 1-4 inclusive.");
		}

		img.pixels = t;
		img.channels = out_image_channels;

	} else if img.depth == 8 {
		// Check if we need to do something.
		if raw_image_channels == out_image_channels {
			// If we have 3 in and 3 out, or 4 in and 4 out without premultiplication...
			if !premultiply {
				// Then we're done.
				return img, nil;
			}
		}

		temp := img.pixels;
		defer bytes.buffer_destroy(&temp);

		// We need to create a new image buffer
		dest_raw_size := compute_buffer_size(int(header.width), int(header.height), out_image_channels, 8);
		t := bytes.Buffer{};
		resize(&t.buf, dest_raw_size);

		p := mem.slice_data_cast([]u8, temp.buf[:]);
		o := mem.slice_data_cast([]u8, t.buf[:]);

		switch raw_image_channels {
		case 1:
			// Gray without Alpha. Might have tRNS alpha.
			key   := u8(0);
			if seen_trns {
				key = u8(mem.slice_data_cast([]u16be, trns.data)[0]);
			}

			for len(p) > 0 {
				r     := p[0];
				alpha := u8(1);

				if seen_trns {
					if r == key {
						if seen_bkgd {
							bc := img.background.([3]u16);
							r = u8(bc[0]);
						} else {
							alpha = 0; // Keyed transparency
						}
					}
					if premultiply {
						r *= alpha;
					}
				}
				o[0] = r;
				o[1] = r;
				o[2] = r;

				if out_image_channels == 4 {
					o[3] = alpha * 255;
				}

				p = p[1:];
				o = o[out_image_channels:];
			}
		case 2:
			// Gray with alpha, we shouldn't have a tRNS chunk.
			bg := f32(0.0);
			if seen_bkgd {
				bg = f32(img.background.([3]u16)[0]);
			}

			for len(p) > 0 {
				r := p[0];
				if seen_bkgd {
					alpha := f32(p[1]) / f32(255);
					c := u8(f32(r) * alpha + (1.0 - alpha) * bg);
					o[0] = c;
					o[1] = c;
					o[2] = c;
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					p[1] = 255;
				} else if .alpha_premultiply in options {
					alpha := p[1];
					c := u8(f32(r) * f32(alpha) / f32(255));
					o[0] = c;
					o[1] = c;
					o[2] = c;
				} else {
					o[0] = r;
					o[1] = r;
					o[2] = r;
				}

				if out_image_channels == 4 {
					o[3] = p[1];
				}

				p = p[2:];
				o = o[out_image_channels:];
			}
		case 3:
			// Color without Alpha. We may still have a tRNS chunk
			key: []u8;
			if seen_trns {
				/*
					For 8-bit images, the tRNS chunk still contains a triple in u16be.
					We use only the low byte in this case.
				*/
				key = []u8{trns.data[1], trns.data[3], trns.data[5]};
			}

			for len(p) > 0 {
				r     := p[0];
				g     := p[1];
				b     := p[2];

				alpha := u8(1); // Default to full opaque

				if seen_trns {
					if r == key[0] && g == key[1] && b == key[2] {
						if seen_bkgd {
							c := img.background.([3]u16);
							r = u8(c[0]);
							g = u8(c[1]);
							b = u8(c[2]);
						} else {
							alpha = 0; // Keyed transparency
						}
					}

					if premultiply {
						r *= alpha;
						g *= alpha;
						b *= alpha;
					}
				}

				o[0] = r;
				o[1] = g;
				o[2] = b;

				if out_image_channels == 4 {
					o[3] = alpha * 255;
				}

				p = p[3:];
				o = o[out_image_channels:];
			}
		case 4:
			// Color with Alpha, can't have tRNS.
			for len(p) > 0 {
				r     := p[0];
				g     := p[1];
				b     := p[2];
				a     := p[3];
				if seen_bkgd {
					alpha := f32(a) / 255.0;
					c  := img.background.([3]u16);
					rb := f32(c[0]) * (1.0 - alpha);
					gb := f32(c[1]) * (1.0 - alpha);
					bb := f32(c[2]) * (1.0 - alpha);

					o[0] = u8(f32(r) * alpha + rb);
					o[1] = u8(f32(g) * alpha + gb);
					o[2] = u8(f32(b) * alpha + bb);
					/*
						After BG blending, the pixel is now fully opaque.
						Update the value we'll write to the output alpha.
					*/
					a = 255;
				} else if premultiply {
					alpha := f32(a) / 255.0;
					o[0] = u8(f32(r) * alpha);
					o[1] = u8(f32(g) * alpha);
					o[2] = u8(f32(b) * alpha);
				} else {
					o[0] = r;
					o[1] = g;
					o[2] = b;
				}

				if out_image_channels == 4 {
					o[3] = a;
				}

				p = p[4:];
				o = o[out_image_channels:];
			}
		case:
			unreachable("We should never seen # channels other than 1-4 inclusive.");
		}

		img.pixels = t;
		img.channels = out_image_channels;

	} else {
		/*
			This may change if we ever don't expand 1, 2 and 4 bit images. But, those raw
			returns will likely bypass this processing pipeline.
		*/
		unreachable("We should never see bit depths other than 8, 16 and 'Paletted' here.");
	}

	return img, nil;
}


filter_paeth :: #force_inline proc(left, up, up_left: u8) -> u8 {
	aa, bb, cc := i16(left), i16(up), i16(up_left);
	p  := aa + bb - cc;
	pa := abs(p - aa);
	pb := abs(p - bb);
	pc := abs(p - cc);
	if pa <= pb && pa <= pc {
		return left;
	}
	if pb <= pc {
		return up;
	}
	return up_left;
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

depth_scale_table :: []u8{0, 0xff, 0x55, 0, 0x11, 0,0,0, 0x01};

// @(optimization_mode="speed")
defilter_8 :: proc(params: ^Filter_Params) -> (ok: bool) {

	using params;
	row_stride := channels * width;

	// TODO: See about doing a Duff's #unroll where practicable

	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride, context.temp_allocator);
	ok = true;

	for _ in 0..<height {
		nk := row_stride - channels;

		filter := Row_Filter(src[0]); src = src[1:];
		switch filter {
		case .None:
			copy(dest, src[:row_stride]);
		case .Sub:
			for i := 0; i < channels; i += 1 {
				dest[i] = src[i];
			}
			for k := 0; k < nk; k += 1 {
				dest[channels+k] = (src[channels+k] + dest[k]) & 255;
			}
		case .Up:
			for k := 0; k < row_stride; k += 1 {
				dest[k] = (src[k] + up[k]) & 255;
			}
		case .Average:
			for i := 0; i < channels; i += 1 {
				avg := up[i] >> 1;
				dest[i] = (src[i] + avg) & 255;
			}
			for k := 0; k < nk; k += 1 {
				avg := u8((u16(up[channels+k]) + u16(dest[k])) >> 1);
				dest[channels+k] = (src[channels+k] + avg) & 255;
			}
		case .Paeth:
			for i := 0; i < channels; i += 1 {
				paeth := filter_paeth(0, up[i], 0);
				dest[i] = (src[i] + paeth) & 255;
			}
			for k := 0; k < nk; k += 1 {
				paeth := filter_paeth(dest[k], up[channels+k], up[k]);
				dest[channels+k] = (src[channels+k] + paeth) & 255;
			}
		case:
			return false;
		}

		src     = src[row_stride:];
		up      = dest;
		dest    = dest[row_stride:];
	}
	return;
}

// @(optimization_mode="speed")
defilter_less_than_8 :: proc(params: ^Filter_Params) -> (ok: bool) #no_bounds_check {

	using params;
	ok = true;

	row_stride_in  := ((channels * width * depth) + 7) >> 3;
	row_stride_out := channels * width;

	// Store defiltered bytes rightmost so we can widen in-place.
	row_offset := row_stride_out - row_stride_in;
	// Save original dest because we'll need it for the bit widening.
	orig_dest := dest;

	// TODO: See about doing a Duff's #unroll where practicable

	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride_out, context.temp_allocator);

	#no_bounds_check for _ in 0..<height {
		nk := row_stride_in - channels;

		dest = dest[row_offset:];

		filter := Row_Filter(src[0]); src = src[1:];
		switch filter {
		case .None:
			copy(dest, src[:row_stride_in]);
		case .Sub:
			for i in 0..=channels {
				dest[i] = src[i];
			}
			for k in 0..=nk {
				dest[channels+k] = (src[channels+k] + dest[k]) & 255;
			}
		case .Up:
			for k in 0..=row_stride_in {
				dest[k] = (src[k] + up[k]) & 255;
			}
		case .Average:
			for i in 0..=channels {
				avg := up[i] >> 1;
				dest[i] = (src[i] + avg) & 255;
			}
			for k in 0..=nk {
				avg := u8((u16(up[channels+k]) + u16(dest[k])) >> 1);
				dest[channels+k] = (src[channels+k] + avg) & 255;
			}
		case .Paeth:
			for i in 0..=channels {
				paeth := filter_paeth(0, up[i], 0);
				dest[i] = (src[i] + paeth) & 255;
			}
			for k in 0..=nk {
				paeth := filter_paeth(dest[k], up[channels+k], up[k]);
				dest[channels+k] = (src[channels+k] + paeth) & 255;
			}
		case:
			return false;
		}

		src  = src[row_stride_in:];
		up   = dest;
		dest = dest[row_stride_in:];
	}

	// Let's expand the bits
	dest = orig_dest;

	// Don't rescale the bits if we're a paletted image.
	dsc := depth_scale_table;
	scale := rescale ? dsc[depth] : 1;

	/*
		For sBIT support we should probably set scale to 1 and mask the significant bits.
		Seperately, do we want to support packed pixels? i.e defiltering only, no expansion?
		If so, all we have to do is call defilter_8 for that case and not set img.depth to 8.
	*/

	for j := 0; j < height; j += 1 {
		src = dest[row_offset:];

		switch depth {
		case 4:
			k := row_stride_out;
			for ; k >= 2; k -= 2 {
				c := src[0];
				dest[0] = scale * (c >> 4);
				dest[1] = scale * (c & 15);
				dest = dest[2:]; src = src[1:];
			}
			if k > 0 {
				c := src[0];
				dest[0] = scale * (c >> 4);
				dest = dest[1:];
			}
		case 2:
			k := row_stride_out;
			for ; k >= 4; k -= 4 {
				c := src[0];
				dest[0] = scale * ((c >> 6)    );
				dest[1] = scale * ((c >> 4) & 3);
				dest[2] = scale * ((c >> 2) & 3);
				dest[3] = scale * ((c     ) & 3);
				dest = dest[4:]; src = src[1:];
			}
			if k > 0 {
				c := src[0];
				dest[0] = scale * ((c >> 6)    );
				if k > 1 {
					dest[1] = scale * ((c >> 4) & 3);
				}
				if k > 2 {
					dest[2] = scale * ((c >> 2) & 3);
				}
				dest = dest[k:];
			}
		case 1:
			k := row_stride_out;
			for ; k >= 8; k -= 8 {
				c := src[0];
				dest[0] = scale * ((c >> 7)    );
				dest[1] = scale * ((c >> 6) & 1);
				dest[2] = scale * ((c >> 5) & 1);
				dest[3] = scale * ((c >> 4) & 1);
				dest[4] = scale * ((c >> 3) & 1);
				dest[5] = scale * ((c >> 2) & 1);
				dest[6] = scale * ((c >> 1) & 1);
				dest[7] = scale * ((c     ) & 1);
				dest = dest[8:]; src = src[1:];
			}
			if k > 0 {
				c := src[0];
				dest[0] = scale * ((c >> 7)    );
				if k > 1 {
					dest[1] = scale * ((c >> 6) & 1);
				}
				if k > 2 {
					dest[2] = scale * ((c >> 5) & 1);
				}
				if k > 3 {
					dest[3] = scale * ((c >> 4) & 1);
				}
				if k > 4 {
					dest[4] = scale * ((c >> 3) & 1);
				}
				if k > 5 {
					dest[5] = scale * ((c >> 2) & 1);
				}
				if k > 6 {
					dest[6] = scale * ((c >> 1) & 1);
				}
				dest = dest[k:];

			}

		}
	}

	return;
}

// @(optimization_mode="speed")
defilter_16 :: proc(params: ^Filter_Params) -> (ok: bool) {

	using params;
	ok = true;

	stride := channels * 2;
	row_stride := width * stride;

	// TODO: See about doing a Duff's #unroll where practicable
	// Apron so we don't need to special case first rows.
	up := make([]u8, row_stride, context.temp_allocator);

	for y := 0; y < height; y += 1 {
		nk := row_stride - stride;

		filter := Row_Filter(src[0]); src = src[1:];
		switch filter {
		case .None:
			copy(dest, src[:row_stride]);
		case .Sub:
			for i := 0; i < stride; i += 1 {
				dest[i] = src[i];
			}
			for k := 0; k < nk; k += 1 {
				dest[stride+k] = (src[stride+k] + dest[k]) & 255;
			}
		case .Up:
			for k := 0; k < row_stride; k += 1 {
				dest[k] = (src[k] + up[k]) & 255;
			}
		case .Average:
			for i := 0; i < stride; i += 1 {
				avg := up[i] >> 1;
				dest[i] = (src[i] + avg) & 255;
			}
			for k := 0; k < nk; k += 1 {
				avg := u8((u16(up[stride+k]) + u16(dest[k])) >> 1);
				dest[stride+k] = (src[stride+k] + avg) & 255;
			}
		case .Paeth:
			for i := 0; i < stride; i += 1 {
				paeth := filter_paeth(0, up[i], 0);
				dest[i] = (src[i] + paeth) & 255;
			}
			for k := 0; k < nk; k += 1 {
				paeth := filter_paeth(dest[k], up[stride+k], up[k]);
				dest[stride+k] = (src[stride+k] + paeth) & 255;
			}
		case:
			return false;
		}

		src     = src[row_stride:];
		up      = dest;
		dest    = dest[row_stride:];
	}

	return;
}

defilter :: proc(img: ^Image, filter_bytes: ^bytes.Buffer, header: ^IHDR, options: Options) -> (err: compress.Error) {
	input    := bytes.buffer_to_bytes(filter_bytes);
	width    := int(header.width);
	height   := int(header.height);
	channels := int(img.channels);
	depth    := int(header.bit_depth);
	rescale  := .Color not_in header.color_type;

	bytes_per_channel := depth == 16 ? 2 : 1;

	num_bytes := compute_buffer_size(width, height, channels, depth == 16 ? 16 : 8);
	resize(&img.pixels.buf, num_bytes);

	filter_ok: bool;

	if header.interlace_method != .Adam7 {
		params := Filter_Params{
			src      = input,
			width    = width,
			height   = height,
			channels = channels,
			depth    = depth,
			rescale  = rescale,
			dest     = img.pixels.buf[:],
		};

		if depth == 8 {
			filter_ok = defilter_8(&params);
		} else if depth < 8 {
			filter_ok = defilter_less_than_8(&params);
			img.depth = 8;
		} else {
			filter_ok = defilter_16(&params);
		}
		if !filter_ok {
			// Caller will destroy buffer for us.
			return E_PNG.Unknown_Filter_Method;
		}
	} else {
		/*
			For deinterlacing we need to make a temporary buffer, defiilter part of the image,
			and copy that back into the actual output buffer.
		*/

		for p := 0; p < 7; p += 1 {
			i,j,x,y: int;
			x = (width  - ADAM7_X_ORIG[p] + ADAM7_X_SPACING[p] - 1) / ADAM7_X_SPACING[p];
			y = (height - ADAM7_Y_ORIG[p] + ADAM7_Y_SPACING[p] - 1) / ADAM7_Y_SPACING[p];
			if x > 0 && y > 0 {
				temp: bytes.Buffer;
				temp_len := compute_buffer_size(x, y, channels, depth == 16 ? 16 : 8);
				resize(&temp.buf, temp_len);

				params := Filter_Params{
					src      = input,
					width    = x,
					height   = y,
					channels = channels,
					depth    = depth,
					rescale  = rescale,
					dest     = temp.buf[:],
				};

				if depth == 8 {
					filter_ok = defilter_8(&params);
				} else if depth < 8 {
					filter_ok = defilter_less_than_8(&params);
					img.depth = 8;
				} else {
					filter_ok = defilter_16(&params);
				}

				if !filter_ok {
					// Caller will destroy buffer for us.
					return E_PNG.Unknown_Filter_Method;
				}

				t := temp.buf[:];
				for j = 0; j < y; j += 1 {
					for i = 0; i < x; i += 1 {
						out_y := j * ADAM7_Y_SPACING[p] + ADAM7_Y_ORIG[p];
						out_x := i * ADAM7_X_SPACING[p] + ADAM7_X_ORIG[p];

						out_off := out_y * width * channels * bytes_per_channel;
						out_off += out_x * channels * bytes_per_channel;

						for z := 0; z < channels * bytes_per_channel; z += 1 {
							img.pixels.buf[out_off + z] = t[z];
						}
						t = t[channels * bytes_per_channel:];
					}
				}
				bytes.buffer_destroy(&temp);
				input_stride := compute_buffer_size(x, y, channels, depth, 1);
				input = input[input_stride:];
			}
		}
	}
	when ODIN_ENDIAN == "little" {
		if img.depth == 16 {
			// The pixel components are in Big Endian. Let's byteswap.
			input  := mem.slice_data_cast([]u16be, img.pixels.buf[:]);
			output := mem.slice_data_cast([]u16  , img.pixels.buf[:]);
			#no_bounds_check for v, i in input {
				output[i] = u16(v);
			}
		}
	}

	return nil;
}

load :: proc{load_from_file, load_from_slice, load_from_stream};
