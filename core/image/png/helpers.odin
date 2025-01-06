/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		Ginger Bill:     Cosmetic changes.

	These are a few useful utility functions to work with PNG images.
*/

package png

import "core:image"
import "core:compress/zlib"
import coretime "core:time"
import "core:strings"
import "core:bytes"
import "core:mem"
import "base:runtime"

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
		return
	}

	bytes.buffer_destroy(&img.pixels)

	if v, ok := img.metadata.(^image.PNG_Info); ok {
		for chunk in v.chunks {
			delete(chunk.data)
		}
		delete(v.chunks)
		free(v)
	}
	free(img)
}

/*
	Chunk helpers
*/

gamma :: proc(c: image.PNG_Chunk) -> (res: f32, ok: bool) {
	if c.header.type != .gAMA || len(c.data) != size_of(gAMA) {
		return {}, false
	}
	gama := (^gAMA)(raw_data(c.data))^
	return f32(gama.gamma_100k) / 100_000.0, true
}

INCHES_PER_METER :: 1000.0 / 25.4

phys :: proc(c: image.PNG_Chunk) -> (res: pHYs, ok: bool) {
	if c.header.type != .pHYs || len(c.data) != size_of(pHYs) {
		return {}, false
	}

	return (^pHYs)(raw_data(c.data))^, true 
}

phys_to_dpi :: proc(p: pHYs) -> (x_dpi, y_dpi: f32) {
	return f32(p.ppu_x) / INCHES_PER_METER, f32(p.ppu_y) / INCHES_PER_METER
}

time :: proc(c: image.PNG_Chunk) -> (res: tIME, ok: bool) {
	if c.header.type != .tIME || len(c.data) != size_of(tIME) {
		return {}, false
	}

	return (^tIME)(raw_data(c.data))^, true
}

core_time :: proc(c: image.PNG_Chunk) -> (t: coretime.Time, ok: bool) {
	if t, png_ok := time(c); png_ok {
		return coretime.datetime_to_time(
			int(t.year), int(t.month),  int(t.day),
			int(t.hour), int(t.minute), int(t.second),
		)
	} else {
		return {}, false
	}
}

text :: proc(c: image.PNG_Chunk) -> (res: Text, ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	assert(len(c.data) == int(c.header.length))
	#partial switch c.header.type {
	case .tEXt:
		ok = true

		fields := bytes.split(c.data, sep=[]u8{0}, allocator=context.temp_allocator)
		if len(fields) == 2 {
			res.keyword = strings.clone(string(fields[0]))
			res.text    = strings.clone(string(fields[1]))
		} else {
			ok = false
		}
		return
	case .zTXt:
		ok = true

		fields := bytes.split_n(c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator)
		if len(fields) != 3 || len(fields[1]) != 0 {
			// Compression method must be 0=Deflate, which thanks to the split above turns
			// into an empty slice
			ok = false; return
		}

		// Set up ZLIB context and decompress text payload.
		buf: bytes.Buffer
		zlib_error := zlib.inflate_from_byte_array(fields[2], &buf)
		defer bytes.buffer_destroy(&buf)
		if zlib_error != nil {
			ok = false; return
		}

		res.keyword = strings.clone(string(fields[0]))
		res.text = strings.clone(bytes.buffer_to_string(&buf))
		return
	case .iTXt:
		ok = true

		s := string(c.data)
		null := strings.index_byte(s, 0)
		if null == -1 {
			ok = false; return
		}
		if len(c.data) < null + 4 {
			// At a minimum, including the \0 following the keyword, we require 5 more bytes.
			ok = false;	return
		}
		res.keyword = strings.clone(string(c.data[:null]))
		rest := c.data[null+1:]

		compression_flag := rest[:1][0]
		if compression_flag > 1 {
			ok = false; return
		}
		compression_method := rest[1:2][0]
		if compression_flag == 1 && compression_method > 0 {
			// Only Deflate is supported
			ok = false; return
		}
		rest = rest[2:]

		// We now expect an optional language keyword and translated keyword, both followed by a \0
		null = strings.index_byte(string(rest), 0)
		if null == -1 {
			ok = false; return
		}
		res.language = strings.clone(string(rest[:null]))
		rest = rest[null+1:]

		null = strings.index_byte(string(rest), 0)
		if null == -1 {
			ok = false; return
		}
		res.keyword_localized = strings.clone(string(rest[:null]))
		rest = rest[null+1:]
		if compression_flag == 0 {
			res.text = strings.clone(string(rest))
		} else {
			// Set up ZLIB context and decompress text payload.
			buf: bytes.Buffer
			zlib_error := zlib.inflate_from_byte_array(rest, &buf)
			defer bytes.buffer_destroy(&buf)
			if zlib_error != nil {

				ok = false; return
			}

			res.text = strings.clone(bytes.buffer_to_string(&buf))
		}
		return
	case:
		// PNG text helper called with an unrecognized chunk type.
		ok = false; return
	}
}

text_destroy :: proc(text: Text) {
	delete(text.keyword)
	delete(text.keyword_localized)
	delete(text.language)
	delete(text.text)
}

iccp :: proc(c: image.PNG_Chunk) -> (res: iCCP, ok: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	fields := bytes.split_n(c.data, sep=[]u8{0}, n=3, allocator=context.temp_allocator)

	if len(fields[0]) < 1 || len(fields[0]) > 79 {
		// Invalid profile name
		return
	}

	if len(fields[1]) != 0 {
		// Compression method should be a zero, which the split turned into an empty slice.
		return
	}

	// Set up ZLIB context and decompress iCCP payload
	buf: bytes.Buffer
	zlib_error := zlib.inflate_from_byte_array(fields[2], &buf)
	if zlib_error != nil {
		bytes.buffer_destroy(&buf)
		return
	}

	res.name = strings.clone(string(fields[0]))
	res.profile = bytes.buffer_to_bytes(&buf)
	ok = true
	return
}

iccp_destroy :: proc(i: iCCP) {
	delete(i.name)

	delete(i.profile)

}

srgb :: proc(c: image.PNG_Chunk) -> (res: sRGB, ok: bool) {
	if c.header.type != .sRGB || len(c.data) != size_of(sRGB_Rendering_Intent) {
		return {}, false
	}

	res.intent = sRGB_Rendering_Intent(c.data[0])
	if res.intent > max(sRGB_Rendering_Intent) {
		ok = false; return
	}
	return res, true
}

plte :: proc(c: image.PNG_Chunk) -> (res: PLTE, ok: bool) {
	if c.header.type != .PLTE || c.header.length % 3 != 0 || c.header.length > 768 {
		return {}, false
	}

	plte := mem.slice_data_cast([]image.RGB_Pixel, c.data[:])
	for color, i in plte {
		res.entries[i] = color
	}
	res.used = u16(len(plte))
	return res, true
}

splt :: proc(c: image.PNG_Chunk) -> (res: sPLT, ok: bool) {
	if c.header.type != .sPLT {
		return
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	fields := bytes.split_n(c.data, sep=[]u8{0}, n=2, allocator=context.temp_allocator)
	if len(fields) != 2 {
		return
	}

	res.depth = fields[1][0]
	if res.depth != 8 && res.depth != 16 {
		return
	}

	data := fields[1][1:]
	count: int

	if res.depth == 8 {
		if len(data) % 6 != 0 {
			return
		}
		count = len(data) / 6
		if count > 256 {
			return
		}

		res.entries = mem.slice_data_cast([][4]u8, data)
	} else { // res.depth == 16
		if len(data) % 10 != 0 {
			return
		}
		count = len(data) / 10
		if count > 256 {
			return
		}

		res.entries = mem.slice_data_cast([][4]u16, data)
	}

	res.name = strings.clone(string(fields[0]))
	res.used = u16(count)
	ok = true
	return
}

splt_destroy :: proc(s: sPLT) {
	delete(s.name)
}

sbit :: proc(c: image.PNG_Chunk) -> (res: [4]u8, ok: bool) {
	/*
		Returns [4]u8 with the significant bits in each channel.
		A channel will contain zero if not applicable to the PNG color type.
	*/

	if len(c.data) < 1 || len(c.data) > 4 {
		ok = false; return
	}
	ok = true

	for i := 0; i < len(c.data); i += 1 {
		res[i] = c.data[i]
	}
	return

}

hist :: proc(c: image.PNG_Chunk) -> (res: hIST, ok: bool) {
	if c.header.type != .hIST {
		return {}, false
	}
	if c.header.length & 1 == 1 || c.header.length > 512 {
		// The entries are u16be, so the length must be even.
		// At most 256 entries must be present
		return {}, false
	}

	ok = true
	data := mem.slice_data_cast([]u16be, c.data)
	i := 0
	for len(data) > 0 {
		// HIST entries are u16be, we unpack them to machine format
		res.entries[i] = u16(data[0])
		i += 1; data = data[1:]
	}
	res.used = u16(i)
	return
}

chrm :: proc(c: image.PNG_Chunk) -> (res: cHRM, ok: bool) {
	ok = true
	if c.header.length != size_of(cHRM_Raw) {
		return {}, false
	}
	chrm := (^cHRM_Raw)(raw_data(c.data))^

	res.w.x = f32(chrm.w.x) / 100_000.0
	res.w.y = f32(chrm.w.y) / 100_000.0
	res.r.x = f32(chrm.r.x) / 100_000.0
	res.r.y = f32(chrm.r.y) / 100_000.0
	res.g.x = f32(chrm.g.x) / 100_000.0
	res.g.y = f32(chrm.g.y) / 100_000.0
	res.b.x = f32(chrm.b.x) / 100_000.0
	res.b.y = f32(chrm.b.y) / 100_000.0
	return
}

exif :: proc(c: image.PNG_Chunk) -> (res: Exif, ok: bool) {

	ok = true

	if len(c.data) < 4 {
		ok = false; return
	}

	if c.data[0] == 'M' && c.data[1] == 'M' {
		res.byte_order = .big_endian
		if c.data[2] != 0 || c.data[3] != 42 {
			ok = false; return
		}
	} else if c.data[0] == 'I' && c.data[1] == 'I' {
		res.byte_order = .little_endian
		if c.data[2] != 42 || c.data[3] != 0 {
			ok = false; return
		}
	} else {
		ok = false; return
	}

	res.data = c.data
	return
}

/*
	General helper functions
*/

compute_buffer_size :: image.compute_buffer_size