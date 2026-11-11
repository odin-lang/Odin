package test_core_image

import "core:hash"
import "core:image"
import "core:image/png"
import "core:testing"

png_chunk_bytes :: proc(buf: ^[dynamic]u8, type: string, data: []u8, corrupt_crc := false) {
	length := u32(len(data))
	append(buf, u8(length >> 24), u8(length >> 16), u8(length >> 8), u8(length))
	append(buf, type)
	append(buf, ..data)
	crc := hash.crc32(transmute([]u8)type)
	crc  = hash.crc32(data, crc)
	if corrupt_crc {
		crc ~= 0xDEAD_BEEF
	}
	append(buf, u8(crc >> 24), u8(crc >> 16), u8(crc >> 8), u8(crc))
}

png_insert_after_ihdr :: proc(src: []u8, type: string, data: []u8, corrupt_crc: bool) -> (out: [dynamic]u8) {
	IHDR_END :: 8 + 12 + 13
	append(&out, ..src[:IHDR_END])
	png_chunk_bytes(&out, type, data, corrupt_crc)
	append(&out, ..src[IHDR_END:])
	return
}

png_chunk_test_image :: proc(channels: int) -> (img: image.Image) {
	img = image.Image{width = 5, height = 3, channels = channels, depth = 8}
	resize(&img.pixels, img.width * img.height * channels)
	for &v, i in img.pixels {
		v = u8(i * 37 + 11)
	}
	return
}

@(test)
png_ancillary_chunk_bad_crc_is_skipped :: proc(t: ^testing.T) {
	Case :: struct {
		channels: int,
		type:     string,
		data:     []u8,
	}
	cases := []Case{
		{3, "iCCP", {'x', 0, 0, 0x78, 0x9C, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01}},
		{3, "tEXt", {'k', 0, 'v'}},
		{3, "bKGD", {0, 1, 0, 2, 0, 3}},
		{3, "tRNS", {0, 1, 0, 2, 0, 3}},
		{1, "tRNS", {0, 7}},
	}

	for c in cases {
		src := png_chunk_test_image(c.channels)
		defer delete(src.pixels)

		encoded: [dynamic]u8
		defer delete(encoded)
		testing.expect_value(t, png.save_to_buffer(&encoded, &src), nil)

		control, control_err := png.load_from_bytes(encoded[:])
		defer png.destroy(control)
		testing.expectf(t, control_err == nil, "%v: control load error %v", c.type, control_err)
		if control_err != nil {
			continue
		}

		corrupted := png_insert_after_ihdr(encoded[:], c.type, c.data, true)
		defer delete(corrupted)

		img, err := png.load_from_bytes(corrupted[:])
		testing.expectf(t, err == nil, "%v: unexpected error %v", c.type, err)
		if err == nil {
			testing.expectf(t, img.channels == control.channels, "%v: channels %v, expected %v", c.type, img.channels, control.channels)
			testing.expectf(t, string(img.pixels[:]) == string(control.pixels[:]), "%v: pixels differ", c.type)
			testing.expectf(t, img.background == nil, "%v: background %v from a discarded chunk", c.type, img.background)
		}
		png.destroy(img)
	}
}

@(test)
png_critical_chunk_bad_crc_is_rejected :: proc(t: ^testing.T) {
	src := png_chunk_test_image(3)
	defer delete(src.pixels)

	encoded: [dynamic]u8
	defer delete(encoded)
	testing.expect_value(t, png.save_to_buffer(&encoded, &src), nil)

	corrupted := png_insert_after_ihdr(encoded[:], "PLTE", {1, 2, 3}, true)
	defer delete(corrupted)

	img, err := png.load_from_bytes(corrupted[:])
	png.destroy(img)
	testing.expect(t, err != nil, "expected an error for a critical chunk with a bad CRC")
}

@(test)
png_large_rgba_dimensions_accepted :: proc(t: ^testing.T) {
	WIDTH  :: 4300
	HEIGHT :: 4300

	buf: [dynamic]u8
	defer delete(buf)
	append(&buf, "\x89PNG\r\n\x1a\n")
	ihdr := []u8{
		u8(WIDTH >> 24), u8(WIDTH >> 16), u8(WIDTH >> 8), u8(WIDTH & 0xFF),
		u8(HEIGHT >> 24), u8(HEIGHT >> 16), u8(HEIGHT >> 8), u8(HEIGHT & 0xFF),
		8, 6, 0, 0, 0,
	}
	png_chunk_bytes(&buf, "IHDR", ihdr)
	png_chunk_bytes(&buf, "IEND", {})

	img, err := png.load_from_bytes(buf[:], {.info})
	defer png.destroy(img)
	testing.expect_value(t, err, nil)
	if err == nil {
		testing.expect_value(t, img.width, WIDTH)
		testing.expect_value(t, img.height, HEIGHT)
		testing.expect_value(t, img.channels, 4)
	}
}

Png_Test_Chunk :: struct {
	type: string,
	data: []u8,
}

png_build_1x1 :: proc(color_type: u8, chunks: []Png_Test_Chunk) -> (buf: [dynamic]u8) {
	raw: []u8
	switch color_type {
	case 2:  raw = {0, 1, 2, 3}
	case:    raw = {0, 0}
	}
	idat: [dynamic]u8
	defer delete(idat)
	length := u16(len(raw))
	append(&idat, 0x78, 0x01, 0x01, u8(length), u8(length >> 8), u8(~length), u8(~length >> 8))
	append(&idat, ..raw)
	adler := hash.adler32(raw)
	append(&idat, u8(adler >> 24), u8(adler >> 16), u8(adler >> 8), u8(adler))

	append(&buf, "\x89PNG\r\n\x1a\n")
	png_chunk_bytes(&buf, "IHDR", {0, 0, 0, 1, 0, 0, 0, 1, 8, color_type, 0, 0, 0})
	for c in chunks {
		png_chunk_bytes(&buf, c.type, c.type == "IDAT" ? idat[:] : c.data)
	}
	return
}

@(test)
png_chunk_order_and_duplicates :: proc(t: ^testing.T) {
	PLTE :: []u8{10, 20, 30}
	GAMA :: []u8{0, 0, 0xB1, 0x8F}
	TIME :: []u8{0x07, 0xEA, 11, 7, 12, 0, 0}
	PHYS :: []u8{0, 0, 0x0B, 0x13, 0, 0, 0x0B, 0x13, 1}

	Case :: struct {
		name:       string,
		color_type: u8,
		chunks:     []Png_Test_Chunk,
		strict:     image.PNG_Error,
		ignored:    image.PNG_Error,
	}
	cases := []Case{
		{"unknown ancillary",         0, {{"teST", {1}}, {"IDAT", nil}, {"IEND", nil}},                                                       .None,                   .None},
		{"unknown critical",          0, {{"ABCD", {1}}, {"IDAT", nil}, {"IEND", nil}},                                                       .Unknown_Critical_Chunk, .Unknown_Critical_Chunk},
		{"duplicate PLTE",            3, {{"PLTE", PLTE}, {"PLTE", PLTE}, {"IDAT", nil}, {"IEND", nil}},                                      .Duplicate_Chunk,        .Duplicate_Chunk},
		{"duplicate tRNS",            0, {{"tRNS", {0, 5}}, {"tRNS", {0, 6}}, {"IDAT", nil}, {"IEND", nil}},                                  .Duplicate_Chunk,        .None},
		{"tRNS before PLTE",          3, {{"tRNS", {0x80}}, {"PLTE", PLTE}, {"IDAT", nil}, {"IEND", nil}},                                    .Chunk_Out_Of_Order,     .None},
		{"bKGD after IDAT",           3, {{"PLTE", PLTE}, {"IDAT", nil}, {"bKGD", {0}}, {"IEND", nil}},                                       .Chunk_Out_Of_Order,     .None},
		{"hIST without PLTE",         0, {{"hIST", {0, 1}}, {"IDAT", nil}, {"IEND", nil}},                                                    .Chunk_Out_Of_Order,     .None},
		{"gAMA after PLTE",           3, {{"PLTE", PLTE}, {"gAMA", GAMA}, {"IDAT", nil}, {"IEND", nil}},                                      .Chunk_Out_Of_Order,     .None},
		{"duplicate gAMA",            0, {{"gAMA", GAMA}, {"gAMA", GAMA}, {"IDAT", nil}, {"IEND", nil}},                                      .Duplicate_Chunk,        .None},
		{"pHYs after IDAT",           0, {{"IDAT", nil}, {"pHYs", PHYS}, {"IEND", nil}},                                                      .Chunk_Out_Of_Order,     .None},
		{"tIME after IDAT",           0, {{"IDAT", nil}, {"tIME", TIME}, {"IEND", nil}},                                                      .None,                   .None},
		{"duplicate tIME",            0, {{"tIME", TIME}, {"IDAT", nil}, {"tIME", TIME}, {"IEND", nil}},                                      .Duplicate_Chunk,        .None},
		{"repeated tEXt",             0, {{"IDAT", nil}, {"tEXt", {'k', 0, 'v'}}, {"tEXt", {'k', 0, 'w'}}, {"IEND", nil}},                    .None,                   .None},
		{"RGB tRNS before PLTE",      2, {{"tRNS", {0, 1, 0, 2, 0, 3}}, {"PLTE", PLTE}, {"IDAT", nil}, {"IEND", nil}},                        .Chunk_Out_Of_Order,     .None},
		{"palette chunks in order",   3, {{"gAMA", GAMA}, {"PLTE", PLTE}, {"tRNS", {0x80}}, {"hIST", {0, 1}}, {"bKGD", {0}}, {"IDAT", nil}, {"IEND", nil}}, .None, .None},
	}

	for c in cases {
		data := png_build_1x1(c.color_type, c.chunks)
		defer delete(data)

		img, err := png.load_from_bytes(data[:])
		png.destroy(img)
		testing.expectf(t, err == c.strict, "%v: strict load returned %v, expected %v", c.name, err, c.strict)

		img, err = png.load_from_bytes(data[:], {.ignore_duplicate_chunks})
		png.destroy(img)
		testing.expectf(t, err == c.ignored, "%v: lenient load returned %v, expected %v", c.name, err, c.ignored)
	}
}

@(test)
png_ignored_chunks_are_dropped :: proc(t: ^testing.T) {
	GAMA :: []u8{0, 0, 0xB1, 0x8F}

	data := png_build_1x1(0, {{"gAMA", GAMA}, {"tRNS", {0, 5}}, {"tRNS", {0, 6}}, {"gAMA", GAMA}, {"IDAT", nil}, {"IEND", nil}})
	defer delete(data)

	control_data := png_build_1x1(0, {{"gAMA", GAMA}, {"tRNS", {0, 5}}, {"IDAT", nil}, {"IEND", nil}})
	defer delete(control_data)

	control, control_err := png.load_from_bytes(control_data[:])
	defer png.destroy(control)
	testing.expect_value(t, control_err, nil)

	img, err := png.load_from_bytes(data[:], {.ignore_duplicate_chunks, .return_metadata})
	defer png.destroy(img)
	testing.expect_value(t, err, nil)
	if err != nil || control_err != nil {
		return
	}
	testing.expect_value(t, img.channels, control.channels)
	testing.expect(t, string(img.pixels[:]) == string(control.pixels[:]), "pixels differ from the control image")

	info, ok := img.metadata.(^image.PNG_Info)
	testing.expect(t, ok, "expected PNG metadata")
	if !ok {
		return
	}
	gama, trns := 0, 0
	for chunk in info.chunks {
		#partial switch chunk.header.type {
		case .gAMA: gama += 1
		case .tRNS: trns += 1
		}
	}
	testing.expect_value(t, gama, 1)
	testing.expect_value(t, trns, 1)
}
