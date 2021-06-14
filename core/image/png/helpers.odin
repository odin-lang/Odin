package png

import "core:image"
import "core:compress/zlib"
import coretime "core:time"
import "core:strings"
import "core:bytes"
import "core:mem"

/*
	These are a few useful utility functions to work with PNG images.
*/

/*
	Cleanup of image-specific data.
	There are other helpers for cleanup of PNG-specific data.
	Those are named *_destroy, where * is the name of the helper.
*/

destroy :: proc(img: ^Image) {
	if img == nil {
		/*
			Nothing to do.
			Load must've returned with an error.
		*/
		return;
	}

	bytes.buffer_destroy(&img.pixels);

	/*
		We don't need to do anything for the individual chunks.
		They're allocated on the temp allocator, as is info.chunks

		See read_chunk.
	*/
	free(img);
}

/*
	Chunk helpers
*/

gamma :: proc(c: Chunk) -> f32 {
	assert(c.header.type == .gAMA);
	res := (^gAMA)(raw_data(c.data))^;
	when true {
		// Returns the wrong result on old backend
		// Fixed for -llvm-api
		return f32(res.gamma_100k) / 100_000.0;
	} else {
		return f32(u32(res.gamma_100k)) / 100_000.0;
	}
}

INCHES_PER_METER :: 1000.0 / 25.4;

phys :: proc(c: Chunk) -> pHYs {
	assert(c.header.type == .pHYs);
	res := (^pHYs)(raw_data(c.data))^;
	return res;
}

phys_to_dpi :: proc(p: pHYs) -> (x_dpi, y_dpi: f32) {
	return f32(p.ppu_x) / INCHES_PER_METER, f32(p.ppu_y) / INCHES_PER_METER;
}

time :: proc(c: Chunk) -> tIME {
	assert(c.header.type == .tIME);
	res := (^tIME)(raw_data(c.data))^;
	return res;
}

core_time :: proc(c: Chunk) -> (t: coretime.Time, ok: bool) {
	png_time := time(c);
	using png_time;
	return coretime.datetime_to_time(
		int(year), int(month), int(day),
		int(hour), int(minute), int(second),
	);
}

text :: proc(c: Chunk) -> (res: Text, ok: bool) {
	#partial switch c.header.type {
	case .tEXt:
		ok = true;

		fields := bytes.split(s=c.data, sep=[]u8{0}, allocator=context.temp_allocator);
		if len(fields) == 2 {
			res.keyword = strings.clone(string(fields[0]));
			res.text    = strings.clone(string(fields[1]));
		} else {
			ok = false;
		}
		return;
	case .zTXt:
		ok = true;

		fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator);
		if len(fields) != 3 || len(fields[1]) != 0 {
			// Compression method must be 0=Deflate, which thanks to the split above turns
			// into an empty slice
			ok = false; return;
		}

		// Set up ZLIB context and decompress text payload.
		buf: bytes.Buffer;
		zlib_error := zlib.inflate_from_byte_array(fields[2], &buf);
		defer bytes.buffer_destroy(&buf);
		if zlib_error != nil {
			ok = false; return;
		}

		res.keyword = strings.clone(string(fields[0]));
		res.text = strings.clone(bytes.buffer_to_string(&buf));
		return;
	case .iTXt:
		ok = true;

		s := string(c.data);
		null := strings.index_byte(s, 0);
		if null == -1 {
			ok = false; return;
		}
		if len(c.data) < null + 4 {
			// At a minimum, including the \0 following the keyword, we require 5 more bytes.
			ok = false;	return;
		}
		res.keyword = strings.clone(string(c.data[:null]));
		rest := c.data[null+1:];

		compression_flag := rest[:1][0];
		if compression_flag > 1 {
			ok = false; return;
		}
		compression_method := rest[1:2][0];
		if compression_flag == 1 && compression_method > 0 {
			// Only Deflate is supported
			ok = false; return;
		}
		rest = rest[2:];

		// We now expect an optional language keyword and translated keyword, both followed by a \0
		null = strings.index_byte(string(rest), 0);
		if null == -1 {
			ok = false; return;
		}
		res.language = strings.clone(string(rest[:null]));
		rest = rest[null+1:];

		null = strings.index_byte(string(rest), 0);
		if null == -1 {
			ok = false; return;
		}
		res.keyword_localized = strings.clone(string(rest[:null]));
		rest = rest[null+1:];
		if compression_flag == 0 {
			res.text = strings.clone(string(rest));
		} else {
			// Set up ZLIB context and decompress text payload.
			buf: bytes.Buffer;
			zlib_error := zlib.inflate_from_byte_array(rest, &buf);
			defer bytes.buffer_destroy(&buf);
			if zlib_error != nil {

				ok = false; return;
			}

			res.text = strings.clone(bytes.buffer_to_string(&buf));
		}
		return;
	case:
		// PNG text helper called with an unrecognized chunk type.
		ok = false; return;
	}
}

text_destroy :: proc(text: Text) {
	delete(text.keyword);
	delete(text.keyword_localized);
	delete(text.language);
	delete(text.text);
}

iccp :: proc(c: Chunk) -> (res: iCCP, ok: bool) {
	ok = true;

	fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator);

	if len(fields[0]) < 1 || len(fields[0]) > 79 {
		// Invalid profile name
		ok = false; return;
	}

	if len(fields[1]) != 0 {
		// Compression method should be a zero, which the split turned into an empty slice.
		ok = false; return;
	}

	// Set up ZLIB context and decompress iCCP payload
	buf: bytes.Buffer;
	zlib_error := zlib.inflate_from_byte_array(fields[2], &buf);
	if zlib_error != nil {
		bytes.buffer_destroy(&buf);
		ok = false; return;
	}

	res.name = strings.clone(string(fields[0]));
	res.profile = bytes.buffer_to_bytes(&buf);

	return;
}

iccp_destroy :: proc(i: iCCP) {
	delete(i.name);

	delete(i.profile);

}

srgb :: proc(c: Chunk) -> (res: sRGB, ok: bool) {
	ok = true;

	if c.header.type != .sRGB || len(c.data) != 1 {
		return {}, false;
	}

	res.intent = sRGB_Rendering_Intent(c.data[0]);
	if res.intent > max(sRGB_Rendering_Intent) {
		ok = false; return;
	}
	return;
}

plte :: proc(c: Chunk) -> (res: PLTE, ok: bool) {
	if c.header.type != .PLTE {
		return {}, false;
	}

	i := 0; j := 0; ok = true;
	for j < int(c.header.length) {
		res.entries[i] = {c.data[j], c.data[j+1], c.data[j+2]};
		i += 1; j += 3;
	}
	res.used = u16(i);
	return;
}

splt :: proc(c: Chunk) -> (res: sPLT, ok: bool) {
	if c.header.type != .sPLT {
		return {}, false;
	}
	ok = true;

	fields := bytes.split_n(s=c.data, sep=[]u8{0}, n=2, allocator=context.temp_allocator);
	if len(fields) != 2 {
		return {}, false;
	}

	res.depth = fields[1][0];
	if res.depth != 8 && res.depth != 16 {
		return {}, false;
	}

	data := fields[1][1:];
	count: int;

	if res.depth == 8 {
		if len(data) % 6 != 0 {
			return {}, false;
		}
		count = len(data) / 6;
		if count > 256 {
			return {}, false;
		}

		res.entries = mem.slice_data_cast([][4]u8, data);
	} else { // res.depth == 16
		if len(data) % 10 != 0 {
			return {}, false;
		}
		count = len(data) / 10;
		if count > 256 {
			return {}, false;
		}

		res.entries = mem.slice_data_cast([][4]u16, data);
	}

	res.name = strings.clone(string(fields[0]));
	res.used = u16(count);

	return;
}

splt_destroy :: proc(s: sPLT) {
	delete(s.name);
}

sbit :: proc(c: Chunk) -> (res: [4]u8, ok: bool) {
	/*
		Returns [4]u8 with the significant bits in each channel.
		A channel will contain zero if not applicable to the PNG color type.
	*/

	if len(c.data) < 1 || len(c.data) > 4 {
		ok = false; return;
	}
	ok = true;

	for i := 0; i < len(c.data); i += 1 {
		res[i] = c.data[i];
	}
	return;

}

hist :: proc(c: Chunk) -> (res: hIST, ok: bool) {
	if c.header.type != .hIST {
		return {}, false;
	}
	if c.header.length & 1 == 1 || c.header.length > 512 {
		// The entries are u16be, so the length must be even.
		// At most 256 entries must be present
		return {}, false;
	}

	ok = true;
	data := mem.slice_data_cast([]u16be, c.data);
	i := 0;
	for len(data) > 0 {
		// HIST entries are u16be, we unpack them to machine format
		res.entries[i] = u16(data[0]);
		i += 1; data = data[1:];
	}
	res.used = u16(i);
	return;
}

chrm :: proc(c: Chunk) -> (res: cHRM, ok: bool) {
	ok = true;
	if c.header.length != size_of(cHRM_Raw) {
		return {}, false;
	}
	chrm := (^cHRM_Raw)(raw_data(c.data))^;

	res.w.x = f32(chrm.w.x) / 100_000.0;
	res.w.y = f32(chrm.w.y) / 100_000.0;
	res.r.x = f32(chrm.r.x) / 100_000.0;
	res.r.y = f32(chrm.r.y) / 100_000.0;
	res.g.x = f32(chrm.g.x) / 100_000.0;
	res.g.y = f32(chrm.g.y) / 100_000.0;
	res.b.x = f32(chrm.b.x) / 100_000.0;
	res.b.y = f32(chrm.b.y) / 100_000.0;
	return;
}

exif :: proc(c: Chunk) -> (res: Exif, ok: bool) {

	ok = true;

	if len(c.data) < 4 {
		ok = false; return;
	}

	if c.data[0] == 'M' && c.data[1] == 'M' {
		res.byte_order = .big_endian;
		if c.data[2] != 0 || c.data[3] != 42 {
			ok = false; return;
		}
	} else if c.data[0] == 'I' && c.data[1] == 'I' {
		res.byte_order = .little_endian;
		if c.data[2] != 42 || c.data[3] != 0 {
			ok = false; return;
		}
	} else {
		ok = false; return;
	}

	res.data = c.data;
	return;
}

/*
	General helper functions
*/

compute_buffer_size :: image.compute_buffer_size;

/*
	PNG save helpers
*/

when false {

	make_chunk :: proc(c: any, t: Chunk_Type) -> (res: Chunk) {

		data: []u8;
		if v, ok := c.([]u8); ok {
			data = v;
		} else {
			data = mem.any_to_bytes(c);
		}

		res.header.length = u32be(len(data));
		res.header.type   = t;
		res.data   = data;

		// CRC the type
		crc    := hash.crc32(mem.any_to_bytes(res.header.type));
		// Extend the CRC with the data
		res.crc = u32be(hash.crc32(data, crc));
		return;
	}

	write_chunk :: proc(fd: os.Handle, chunk: Chunk) {
		c := chunk;
		// Write length + type
		os.write_ptr(fd, &c.header, 8);
		// Write data
		os.write_ptr(fd, mem.raw_data(c.data), int(c.header.length));
		// Write CRC32
		os.write_ptr(fd, &c.crc, 4);
	}

	write_image_as_png :: proc(filename: string, image: Image) -> (err: Error) {
		profiler.timed_proc();
		using image;
		using os;
		flags: int = O_WRONLY|O_CREATE|O_TRUNC;

		if len(image.pixels) == 0 || len(image.pixels) < image.width * image.height * int(image.channels) {
			return E_PNG.Invalid_Image_Dimensions;
		}

		mode: int = 0;
		when ODIN_OS == "linux" || ODIN_OS == "darwin" {
			// NOTE(justasd): 644 (owner read, write; group read; others read)
			mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
		}

		fd, fderr := open(filename, flags, mode);
		if fderr != 0 {
			return E_General.Cannot_Open_File;
		}
		defer close(fd);

		magic := Signature;

		write_ptr(fd, &magic, 8);

		ihdr := IHDR{
			width              = u32be(width),
			height             = u32be(height),
			bit_depth          = depth,
			compression_method = 0,
			filter_method      = 0,
			interlace_method   = .None,
		};

		switch channels {
		case 1: ihdr.color_type = Color_Type{};
		case 2: ihdr.color_type = Color_Type{.Alpha};
		case 3: ihdr.color_type = Color_Type{.Color};
		case 4: ihdr.color_type = Color_Type{.Color, .Alpha};
		case:// Unhandled
			return E_PNG.Unknown_Color_Type;
		}
		h := make_chunk(ihdr, .IHDR);
		write_chunk(fd, h);

		bytes_needed := width * height * int(channels) + height;
		filter_bytes := mem.make_dynamic_array_len_cap([dynamic]u8, bytes_needed, bytes_needed, context.allocator);
		defer delete(filter_bytes);

		i := 0; j := 0;
		// Add a filter byte 0 per pixel row
		for y := 0; y < height; y += 1 {
			filter_bytes[j] = 0; j += 1;
			for x := 0; x < width; x += 1 {
				for z := 0; z < channels; z += 1 {
					filter_bytes[j+z] = image.pixels[i+z];
				}
				i += channels; j += channels;
			}
		}
		assert(j == bytes_needed);

		a: []u8 = filter_bytes[:];

		out_buf: ^[dynamic]u8;
		defer free(out_buf);

		ctx := zlib.ZLIB_Context{
			in_buf  = &a,
			out_buf = out_buf,
		};
		err = zlib.write_zlib_stream_from_memory(&ctx);

		b: []u8;
		if err == nil {
			b = ctx.out_buf[:];
		} else {
			return err;
		}

		idat := make_chunk(b, .IDAT);

		write_chunk(fd, idat);

		iend := make_chunk([]u8{}, .IEND);
		write_chunk(fd, iend);

		return nil;
	}
}
