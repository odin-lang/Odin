package test_vendor_stb

import "core:testing"
import stbi  "vendor:stb/image"
import stbrp "vendor:stb/rect_pack"
import stbpf "vendor:stb/sprintf"
import stbtt "vendor:stb/truetype"
import stbv  "vendor:stb/vorbis"

// These tests exist mostly to make sure each stb library links and runs on every target.

@(test)
test_sprintf :: proc(t: ^testing.T) {
	buf: [64]u8
	n := stbpf.snprintf(raw_data(buf[:]), i32(len(buf)), "%d-%s-%.2f", i32(42), cstring("odin"), f64(1.5))
	testing.expect_value(t, string(buf[:n]), "42-odin-1.50")
}

@(test)
test_rect_pack :: proc(t: ^testing.T) {
	ctx:   stbrp.Context
	nodes: [64]stbrp.Node
	rects := [4]stbrp.Rect{
		{id = 0, w = 32, h = 32},
		{id = 1, w = 32, h = 32},
		{id = 2, w = 32, h = 32},
		{id = 3, w = 32, h = 32},
	}
	stbrp.init_target(&ctx, 64, 64, raw_data(nodes[:]), i32(len(nodes)))
	testing.expect(t, stbrp.pack_rects(&ctx, raw_data(rects[:]), i32(len(rects))) == 1, "four 32x32 rects must fill a 64x64 target")

	for r in rects {
		testing.expect(t, bool(r.was_packed))
		testing.expect(t, r.x >= 0 && r.y >= 0 && r.x + r.w <= 64 && r.y + r.h <= 64)
	}
}

@(test)
test_image_write_load_roundtrip :: proc(t: ^testing.T) {
	W, H :: 4, 4
	pixels: [W * H * 4]u8
	for i in 0..<W * H {
		pixels[i*4 + 0] = u8(i * 16)
		pixels[i*4 + 1] = u8(255 - i * 16)
		pixels[i*4 + 2] = 7
		pixels[i*4 + 3] = 255
	}

	Sink :: struct {
		data: [1024]u8,
		len:  int,
	}
	sink: Sink

	write :: proc "c" (ctx: rawptr, data: rawptr, size: i32) {
		sink := (^Sink)(ctx)
		n := copy(sink.data[sink.len:], ([^]u8)(data)[:size])
		sink.len += n
	}

	testing.expect(t, stbi.write_png_to_func(write, &sink, W, H, 4, raw_data(pixels[:]), W * 4) != 0)
	testing.expect(t, sink.len > 8 && sink.len < len(sink.data))

	x, y, comp: i32
	loaded := stbi.load_from_memory(raw_data(sink.data[:]), i32(sink.len), &x, &y, &comp, 4)
	if !testing.expect(t, loaded != nil, "PNG written by stb_image_write must load again") {
		return
	}
	defer stbi.image_free(loaded)

	testing.expect_value(t, x, W)
	testing.expect_value(t, y, H)
	testing.expect_value(t, comp, 4)
	for v, i in loaded[:W * H * 4] {
		if v != pixels[i] {
			testing.expectf(t, false, "PNG round trip differs at byte %v: got %v, want %v", i, v, pixels[i])
			break
		}
	}
}

@(test)
test_truetype_rejects_garbage :: proc(t: ^testing.T) {
	garbage := [64]u8{}
	testing.expect_value(t, stbtt.GetNumberOfFonts(raw_data(garbage[:])), 0)

	info: stbtt.fontinfo
	testing.expect(t, !stbtt.InitFont(&info, raw_data(garbage[:]), 0), "an all zero buffer is not a font")
}

@(test)
test_vorbis_rejects_garbage :: proc(t: ^testing.T) {
	garbage := [64]u8{}
	err: stbv.Error
	v := stbv.open_memory(raw_data(garbage[:]), i32(len(garbage)), &err, nil)
	testing.expect(t, v == nil, "an all zero buffer is not an Ogg stream")
	testing.expect(t, err != .none)
}
