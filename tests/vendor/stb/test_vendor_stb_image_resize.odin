package test_vendor_stb

import "core:c"
import "core:c/libc"
import "core:testing"
import stbi "vendor:stb/image"

// The extended API takes a pointer to `resizer`, so its layout has to match the C `STBIR_RESIZE` exactly.
@(test)
test_resizer_layout :: proc(t: ^testing.T) {
	when size_of(rawptr) == 8 {
		testing.expect_value(t, size_of(stbi.resizer), 280)
		testing.expect_value(t, align_of(stbi.resizer), 8)
		testing.expect_value(t, offset_of(stbi.resizer, input_cb), 80)
		testing.expect_value(t, offset_of(stbi.resizer, input_stride_in_bytes), 128)
		testing.expect_value(t, offset_of(stbi.resizer, horizontal_filter), 176)
		testing.expect_value(t, offset_of(stbi.resizer, horizontal_filter_kernel_new), 224)
		testing.expect_value(t, offset_of(stbi.resizer, samplers), 272)
	}
}

// A 4x4 single channel image made of four constant 2x2 blocks.
BLOCKS := [16]u8{
	  0,   0, 100, 100,
	  0,   0, 100, 100,
	200, 200,  50,  50,
	200, 200,  50,  50,
}

expect_near :: proc(t: ^testing.T, got, want: []u8, tolerance: int, loc := #caller_location) {
	if !testing.expect_value(t, len(got), len(want), loc = loc) {
		return
	}
	for i in 0..<len(want) {
		if abs(int(got[i]) - int(want[i])) > tolerance {
			testing.expectf(t, false, "pixel %v: got %v, want %v (+/- %v)", i, got[i], want[i], tolerance, loc = loc)
			return
		}
	}
}

@(test)
test_medium_api_box_downscale :: proc(t: ^testing.T) {
	// A box filter over an integer ratio averages the blocks exactly.
	blocks := BLOCKS
	out: [4]u8
	result := stbi.resize(&blocks, 4, 4, 0, &out, 2, 2, 0, .CHANNEL_1, .UINT8, .CLAMP, .BOX)
	testing.expect(t, result != nil, "resize failed")
	expect_near(t, out[:], {0, 100, 200, 50}, 1)
}

@(test)
test_constant_image_survives_every_filter :: proc(t: ^testing.T) {
	// Whatever the filter, resizing a flat color must not change the color.
	input: [8 * 8]u8
	for &p in input { p = 77 }

	for f in stbi.filter.BOX..=stbi.filter.MURATORI6 {
		down: [5 * 5]u8
		up:   [13 * 13]u8
		testing.expect(t, stbi.resize(&input, 8, 8, 0, &down, 5, 5, 0, .CHANNEL_1, .UINT8, .CLAMP, f) != nil)
		testing.expect(t, stbi.resize(&input, 8, 8, 0, &up, 13, 13, 0, .CHANNEL_1, .UINT8, .REFLECT, f) != nil)
		want_down: [5 * 5]u8
		want_up:   [13 * 13]u8
		for &p in want_down { p = 77 }
		for &p in want_up   { p = 77 }
		expect_near(t, down[:], want_down[:], 1)
		expect_near(t, up[:], want_up[:], 1)
	}
}

@(test)
test_easy_api_allocates_when_output_is_nil :: proc(t: ^testing.T) {
	input: [4 * 4 * 4]u8
	for i in 0..<16 {
		input[i * 4 + 0] = 10
		input[i * 4 + 1] = 20
		input[i * 4 + 2] = 30
		input[i * 4 + 3] = 255
	}

	// With no output buffer the library allocates one with malloc, so it has to be freed with libc.free.
	out := stbi.resize_uint8_linear(&input[0], 4, 4, 0, nil, 8, 8, 0, .RGBA)
	if !testing.expect(t, out != nil, "resize_uint8_linear returned nil") {
		return
	}
	defer libc.free(out)

	pixels := out[:8 * 8 * 4]
	for i in 0..<64 {
		if pixels[i * 4 + 0] != 10 || pixels[i * 4 + 1] != 20 || pixels[i * 4 + 2] != 30 || pixels[i * 4 + 3] != 255 {
			testing.expectf(t, false, "pixel %v is %v, want [10 20 30 255]", i, pixels[i * 4:i * 4 + 4])
			return
		}
	}
}

@(test)
test_easy_api_srgb_and_float :: proc(t: ^testing.T) {
	flat: [6 * 6]u8
	for &p in flat { p = 128 }
	out := make([]u8, 3 * 3)
	defer delete(out)

	result := stbi.resize_uint8_srgb(&flat[0], 6, 6, 0, raw_data(out), 3, 3, 0, .CHANNEL_1)
	testing.expect(t, result != nil, "resize_uint8_srgb failed")
	want: [3 * 3]u8
	for &p in want { p = 128 }
	expect_near(t, out, want[:], 1)

	fin: [6 * 6]f32
	for &p in fin { p = 0.25 }
	fout: [3 * 3]f32
	fresult := stbi.resize_float_linear(&fin[0], 6, 6, 0, &fout[0], 3, 3, 0, .CHANNEL_1)
	testing.expect(t, fresult != nil, "resize_float_linear failed")
	for v, i in fout {
		testing.expectf(t, abs(v - 0.25) < 0.0001, "float pixel %v is %v, want 0.25", i, v)
	}
}

@(test)
test_extended_api_matches_medium_api :: proc(t: ^testing.T) {
	blocks := BLOCKS
	medium: [4]u8
	testing.expect(t, stbi.resize(&blocks, 4, 4, 0, &medium, 2, 2, 0, .CHANNEL_1, .UINT8, .CLAMP, .BOX) != nil)

	out: [4]u8
	r: stbi.resizer
	stbi.resize_init(&r, &blocks, 4, 4, 0, &out, 2, 2, 0, .CHANNEL_1, .UINT8)
	testing.expect_value(t, stbi.set_filters(&r, .BOX, .BOX), 1)
	testing.expect_value(t, stbi.set_edgemodes(&r, .CLAMP, .CLAMP), 1)
	testing.expect_value(t, stbi.resize_extended(&r), 1)
	testing.expect_value(t, out, medium)
}

@(test)
test_extended_api_reuses_samplers :: proc(t: ^testing.T) {
	// Same sizes, many frames: build the samplers once.
	frame_a := BLOCKS
	frame_b: [16]u8
	for i in 0..<16 { frame_b[i] = 255 - BLOCKS[i] }
	out: [4]u8

	r: stbi.resizer
	stbi.resize_init(&r, &frame_a, 4, 4, 0, &out, 2, 2, 0, .CHANNEL_1, .UINT8)
	testing.expect_value(t, stbi.set_filters(&r, .BOX, .BOX), 1)
	testing.expect_value(t, stbi.build_samplers(&r), 1)
	defer stbi.free_samplers(&r)

	testing.expect_value(t, stbi.resize_extended(&r), 1)
	expect_near(t, out[:], {0, 100, 200, 50}, 1)

	stbi.set_buffer_ptrs(&r, &frame_b, 0, &out, 0)
	testing.expect_value(t, stbi.resize_extended(&r), 1)
	expect_near(t, out[:], {255, 155, 55, 205}, 1)
}

@(test)
test_extended_api_split :: proc(t: ^testing.T) {
	input: [16 * 16]u8
	for &p, i in input { p = u8(i * 3) }

	whole: [8 * 8]u8
	testing.expect(t, stbi.resize(&input, 16, 16, 0, &whole, 8, 8, 0, .CHANNEL_1, .UINT8, .CLAMP, .MITCHELL) != nil)

	pieces: [8 * 8]u8
	r: stbi.resizer
	stbi.resize_init(&r, &input, 16, 16, 0, &pieces, 8, 8, 0, .CHANNEL_1, .UINT8)
	testing.expect_value(t, stbi.set_filters(&r, .MITCHELL, .MITCHELL), 1)

	splits := stbi.build_samplers_with_splits(&r, 4)
	defer stbi.free_samplers(&r)
	testing.expect(t, splits >= 1, "no splits")
	for i in 0..<splits {
		testing.expect_value(t, stbi.resize_extended_split(&r, i, 1), 1)
	}
	testing.expect_value(t, pieces, whole)
}

Row_Collector :: struct {
	pixels: [4 * 4]u8,
	calls:  int,
}

collect_output :: proc "c" (output_ptr: rawptr, num_pixels: c.int, x, y: c.int, ctx: rawptr) {
	collector := (^Row_Collector)(ctx)
	collector.calls += 1
	src := ([^]u8)(output_ptr)
	for i in 0..<int(num_pixels) {
		collector.pixels[int(y) * 4 + int(x) + i] = src[i]
	}
}

@(test)
test_extended_api_output_callback :: proc(t: ^testing.T) {
	input: [8 * 8]u8
	for &p in input { p = 90 }
	out: [4 * 4]u8

	collector: Row_Collector
	r: stbi.resizer
	stbi.resize_init(&r, &input, 8, 8, 0, &out, 4, 4, 0, .CHANNEL_1, .UINT8)
	stbi.set_pixel_callbacks(&r, nil, collect_output)
	stbi.set_user_data(&r, &collector)
	testing.expect_value(t, stbi.resize_extended(&r), 1)

	testing.expect(t, collector.calls > 0, "output callback was never called")
	want: [4 * 4]u8
	for &p in want { p = 90 }
	expect_near(t, collector.pixels[:], want[:], 1)
}

@(test)
test_pixel_layout_from_channel_count :: proc(t: ^testing.T) {
	// The old API took a channel count; the same numbers still select the matching layout.
	testing.expect_value(t, stbi.pixel_layout(1), stbi.pixel_layout.CHANNEL_1)
	testing.expect_value(t, stbi.pixel_layout(3), stbi.pixel_layout.RGB)
	testing.expect_value(t, stbi.pixel_layout(4), stbi.pixel_layout.RGBA)
	testing.expect_value(t, stbi.PIXEL_LAYOUT_RGBA_NO_AW, stbi.pixel_layout.RGBA_PM)
}
