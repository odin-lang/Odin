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
