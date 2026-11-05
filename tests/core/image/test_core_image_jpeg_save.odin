package test_core_image

import "base:runtime"
import "core:image"
import "core:image/jpeg"
import "core:image/png"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:testing"

JPEG_SAVE_QUALITIES :: [?]int{10, 25, 50, 75, 90, 100}

when ODIN_ARCH == .riscv64 {
	JPEG_SAVE_SOURCE_QUALITIES :: bit_set[0..<len(JPEG_SAVE_QUALITIES)]{2, 4}
	JPEG_SAVE_MATRIX_SIZES     :: [?]int{1, 8, 9, 17}
	JPEG_SAVE_FUZZ_ROUNDS      :: 50
	JPEG_SAVE_EXTREME_QUALITY  :: [?]int{1, 100}
	JPEG_SAVE_STRIP_SIZES      :: [?][2]int{{1, 1}, {3, 517}, {517, 3}}
	JPEG_SAVE_EOBRUN_QUALITY   :: [?]int{100}
	JPEG_SAVE_WIDE_QUALITIES   :: [?]int{1, 100}
} else {
	JPEG_SAVE_SOURCE_QUALITIES :: bit_set[0..<len(JPEG_SAVE_QUALITIES)]{0, 1, 2, 3, 4, 5}
	JPEG_SAVE_MATRIX_SIZES     :: [?]int{1, 2, 7, 8, 9, 15, 16, 17}
	JPEG_SAVE_FUZZ_ROUNDS      :: 200
	JPEG_SAVE_EXTREME_QUALITY  :: [?]int{1, 2, 50, 99, 100}
	JPEG_SAVE_STRIP_SIZES      :: [?][2]int{{1, 1}, {1, 1000}, {1000, 1}, {3, 517}, {517, 3}}
	JPEG_SAVE_EOBRUN_QUALITY   :: [?]int{100, 75}
	JPEG_SAVE_WIDE_QUALITIES   :: [?]int{1, 50, 100}
}

JPEG_Save_Source :: struct {
	file:     string,
	min_psnr: [jpeg.Subsampling][len(JPEG_SAVE_QUALITIES)]f64,
}

JPEG_Save_Sources := []JPEG_Save_Source{
	{TEST_SUITE_PATH_JPG + "/baseline-444.ref.png", {.S444 = {26, 29, 31, 46, 44, 56}, .S422 = {25, 28, 29, 33, 36, 38}, .S420 = {24, 27, 28, 32, 34, 35}}},
	{TEST_SUITE_PATH_JPG + "/grad-420.ref.png",     {.S444 = {29, 33, 36, 40, 43, 53}, .S422 = {29, 33, 35, 39, 43, 47}, .S420 = {28, 32, 34, 38, 41, 45}}},
	{TEST_SUITE_PATH_JPG + "/noise-q100.ref.png",   {.S444 = {10, 11, 15, 21, 28, 53}, .S422 = { 9, 10, 11, 12, 13, 13}, .S420 = { 9, 10, 10, 11, 11, 11}}},
	{TEST_SUITE_PATH_JPG + "/odd-444.ref.png",      {.S444 = {17, 19, 22, 36, 35, 51}, .S422 = {16, 19, 20, 24, 26, 27}, .S420 = {16, 18, 19, 22, 23, 24}}},
	{TEST_SUITE_PATH_JPG + "/one-420.ref.png",      {.S444 = {33, 39, 45, 98, 98, 98}, .S422 = {33, 39, 45, 98, 98, 98}, .S420 = {33, 39, 45, 98, 98, 98}}},
	{TEST_SUITE_PATH_JPG + "/gray.ref.png",         {.S444 = {28, 31, 34, 51, 47, 62}, .S422 = {28, 31, 34, 51, 47, 62}, .S420 = {28, 31, 34, 51, 47, 62}}},
	{TEST_SUITE_PATH_JPG + "/gray-odd.ref.png",     {.S444 = {20, 23, 26, 41, 40, 57}, .S422 = {20, 23, 26, 41, 40, 57}, .S420 = {20, 23, 26, 41, 40, 57}}},
	{TEST_SUITE_PATH_PNG + "/basn0g08.png",         {.S444 = {33, 37, 43, 45, 50, 69}, .S422 = {33, 37, 43, 45, 50, 69}, .S420 = {33, 37, 43, 45, 50, 69}}},
	{TEST_SUITE_PATH_PNG + "/basn2c08.png",         {.S444 = {30, 34, 38, 43, 45, 54}, .S422 = {29, 34, 39, 42, 45, 53}, .S420 = {20, 21, 23, 24, 24, 24}}},
	{TEST_SUITE_PATH_PNG + "/basn4a08.png",         {.S444 = {33, 39, 47, 47, 57, 98}, .S422 = {33, 39, 47, 47, 57, 98}, .S420 = {33, 39, 47, 47, 57, 98}}},
	{TEST_SUITE_PATH_PNG + "/basn6a08.png",         {.S444 = {30, 34, 37, 41, 45, 52}, .S422 = {30, 34, 37, 41, 45, 52}, .S420 = {26, 31, 34, 35, 37, 38}}},
}

JPEG_Save_Mode :: struct {
	profile: jpeg.Profile,
	options: jpeg.Save_Options,
}

JPEG_Save_Modes := [?]JPEG_Save_Mode{
	{.Baseline,    {}},
	{.Baseline,    {entropy_coding = .Huffman_Optimized}},
	{.Extended,    {}},
	{.Progressive, {}},
	{.Extended,    {entropy_coding = .Arithmetic}},
	{.Progressive, {entropy_coding = .Arithmetic}},
}

JPEG_Save_Wide_Modes := [?]JPEG_Save_Mode{
	{.Extended,    {}},
	{.Extended,    {entropy_coding = .Huffman_Optimized}},
	{.Progressive, {}},
	{.Extended,    {entropy_coding = .Arithmetic}},
	{.Progressive, {entropy_coding = .Arithmetic}},
}

JPEG_Save_Wide_Sources := []JPEG_Save_Source{
	{TEST_SUITE_PATH_PNG + "/basn0g16.png",         {.S444 = {45, 51, 56, 60, 65, 89}, .S422 = {45, 51, 56, 60, 65, 89}, .S420 = {45, 51, 56, 60, 65, 89}}},
	{TEST_SUITE_PATH_PNG + "/basn2c16.png",         {.S444 = {43, 48, 50, 56, 61, 76}, .S422 = {41, 44, 47, 48, 49, 49}, .S420 = {40, 42, 45, 45, 45, 46}}},
	{TEST_SUITE_PATH_PNG + "/basn4a16.png",         {.S444 = {36, 44, 49, 54, 62, 83}, .S422 = {36, 44, 49, 54, 62, 83}, .S420 = {36, 44, 49, 54, 62, 83}}},
	{TEST_SUITE_PATH_PNG + "/basn6a16.png",         {.S444 = {35, 40, 44, 50, 57, 75}, .S422 = {31, 32, 33, 33, 33, 33}, .S420 = {29, 30, 31, 31, 31, 31}}},
	{TEST_SUITE_PATH_JPG + "/baseline-444.ref.png", {.S444 = {40, 46, 48, 52, 59, 75}, .S422 = {35, 37, 37, 38, 38, 38}, .S420 = {33, 34, 35, 35, 35, 35}}},
}

JPEG_SAVE_SPACE_CHANNELS :: [jpeg.Color_Space]int{
	.Gray       = 1,
	.Gray_Alpha = 2,
	.YCbCr      = 3,
	.RGB        = 3,
	.CMYK       = 4,
	.YCCK       = 4,
}

JPEG_Save_Result :: struct {
	psnr:     f64,
	mean:     f64,
	max_diff: int,
	size:     int,
}

@(test)
jpeg_save_sources :: proc(t: ^testing.T) {
	for source in JPEG_Save_Sources {
		src, src_err := png.load(source.file, {.do_not_expand_channels})
		defer png.destroy(src)
		testing.expectf(t, src_err == nil && src.depth == 8, "%v: source load returned %v", source.file, src_err)
		if src_err != nil || src.depth != 8 {
			continue
		}

		for subsampling in jpeg.Subsampling {
			previous: JPEG_Save_Result
			for quality, qi in JPEG_SAVE_QUALITIES {
				if qi not_in JPEG_SAVE_SOURCE_QUALITIES {
					continue
				}
				result, ok := expect_jpeg_save_modes(t, source.file, src, quality, subsampling)
				if !ok {
					continue
				}
				floor := source.min_psnr[subsampling][qi]
				testing.expectf(t, result.psnr >= floor, "%v q%v %v: PSNR %.2f below %.2f", source.file, quality, subsampling, result.psnr, floor)
				if qi > 0 {
					testing.expectf(t, result.size >= previous.size, "%v q%v %v: size %v smaller than %v at a lower quality", source.file, quality, subsampling, result.size, previous.size)
				}
				previous = result
			}
		}
	}
}

@(test)
jpeg_save_matrix :: proc(t: ^testing.T) {
	sizes := JPEG_SAVE_MATRIX_SIZES

	for channels in 1..=4 {
		for width in sizes {
			for height in sizes {
				img := png_save_test_image(width, height, channels, 8)
				defer delete(img.pixels)

				for subsampling in jpeg.Subsampling {
					result, ok := expect_jpeg_save_modes(t, "synthetic", &img, 90, subsampling)
					if ok && subsampling == .S444 {
						testing.expectf(t, result.psnr >= 30, "synthetic %vx%vx%v %v: PSNR %.2f", width, height, channels, subsampling, result.psnr)
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_flat :: proc(t: ^testing.T) {
	colors := [?][3]u8{{0, 0, 0}, {255, 255, 255}, {128, 128, 128}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {12, 200, 77}}

	for color in colors {
		for channels in ([?]int{1, 3, 4}) {
			img := image.Image{width = 19, height = 11, channels = channels, depth = 8}
			resize(&img.pixels, img.width * img.height * channels)
			defer delete(img.pixels)
			for i in 0..<img.width * img.height {
				for c in 0..<channels {
					img.pixels[i * channels + c] = color[c] if c < 3 else 0
				}
			}

			for quality in ([?]int{90, 100}) {
				for subsampling in jpeg.Subsampling {
					result, ok := expect_jpeg_save_modes(t, "flat", &img, quality, subsampling)
					if ok {
						testing.expectf(t, result.max_diff <= 1, "flat %v x%v q%v %v: max difference %v", color, channels, quality, subsampling, result.max_diff)
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_structure :: proc(t: ^testing.T) {
	img := png_save_test_image(33, 21, 3, 8)
	defer delete(img.pixels)

	for mode in JPEG_Save_Modes {
		buf: [dynamic]u8
		defer delete(buf)

		save_err := jpeg.save(&buf, &img, profile = mode.profile, save_options = mode.options)
		testing.expect_value(t, save_err, nil)
		if save_err != nil || len(buf) < 20 {
			continue
		}

		head := [?]u8{0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0x00, 0x01, 0x01}
		testing.expectf(t, string(buf[:len(head)]) == string(head[:]), "%v: unexpected header % x", mode, buf[:len(head)])
		testing.expectf(t, buf[len(buf) - 2] == 0xFF && buf[len(buf) - 1] == 0xD9, "%v: missing EOI", mode)

		out, load_err := jpeg.load(buf[:], {.return_metadata, .do_not_decompress_image})
		defer jpeg.destroy(out)
		testing.expect_value(t, load_err, nil)
		if load_err != nil {
			continue
		}
		info, info_ok := out.metadata.(^image.JPEG_Info)
		testing.expect(t, info_ok)
		if !info_ok {
			continue
		}
		_, has_jfif := info.jfif_app0.?
		testing.expect(t, has_jfif)
		want := image.JPEG_Marker.SOF0 if mode.profile == .Baseline else image.JPEG_Marker(jpeg_save_want_marker(mode))
		testing.expectf(t, info.frame_type == want, "%v: frame type %v, expected %v", mode, info.frame_type, want)
		testing.expect_value(t, info.color_space, jpeg.Color_Space.YCbCr)
	}
}

@(test)
jpeg_save_restart_structure :: proc(t: ^testing.T) {
	img := png_save_test_image(33, 21, 3, 8)
	defer delete(img.pixels)

	for mode in JPEG_Save_Modes {
		buf: [dynamic]u8
		defer delete(buf)

		options := mode.options
		options.restart_interval_rows = 1
		testing.expect_value(t, jpeg.save(&buf, &img, {}, 90, .S420, mode.profile, options), nil)

		dri, rst := jpeg_save_count_markers(buf[:])
		testing.expectf(t, dri >= 1, "%v: no DRI marker", mode)
		testing.expectf(t, rst >= 1, "%v: no RST markers", mode)
	}

	wide := jpeg_save_pattern_image(9000, 16, 1, .Gradient)
	defer delete(wide.pixels)

	buf: [dynamic]u8
	defer delete(buf)
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Baseline, save_options = {restart_interval_rows = 65535}), nil)
	interval := -1
	for i in 0..<len(buf) - 5 {
		if buf[i] == 0xFF && buf[i + 1] == 0xDD {
			interval = int(buf[i + 4]) << 8 | int(buf[i + 5])
			break
		}
	}
	testing.expect_value(t, interval, 65535 / 1125 * 1125)
}

jpeg_save_count_markers :: proc(buf: []u8) -> (dri, rst: int) {
	for i in 0..<len(buf) - 1 {
		if buf[i] != 0xFF {
			continue
		}
		switch buf[i + 1] {
		case 0xDD:       dri += 1
		case 0xD0..=0xD7: rst += 1
		}
	}
	return
}

@(test)
jpeg_save_restart :: proc(t: ^testing.T) {
	sizes := [?][2]int{{1, 1}, {17, 9}, {40, 33}, {67, 41}}
	for size in sizes {
		for channels in ([?]int{1, 2, 4}) {
			img := jpeg_save_pattern_image(size[0], size[1], channels, .Gradient)
			defer delete(img.pixels)

			for rows in ([?]u16{1, 2}) {
				for subsampling in jpeg.Subsampling {
					expect_jpeg_save_modes(t, "restart", &img, 90, subsampling, nil, rows)
				}
				if channels == 4 {
					expect_jpeg_save_modes(t, "restart", &img, 90, .S420, jpeg.Color_Space.YCCK, rows)
					expect_jpeg_save_modes(t, "restart", &img, 90, .S444, jpeg.Color_Space.CMYK, rows)
				}
			}
		}
	}
}

jpeg_save_space_accepts :: proc(space: jpeg.Color_Space, channels: int) -> bool {
	switch space {
	case .Gray:        return true
	case .Gray_Alpha:  return channels == 2 || channels == 4
	case .YCbCr, .RGB: return channels >= 3
	case .CMYK, .YCCK: return channels == 4
	}
	return false
}

@(test)
jpeg_save_color_spaces :: proc(t: ^testing.T) {
	for space in jpeg.Color_Space {
		for channels in 1..=4 {
			img := jpeg_save_pattern_image(37, 29, channels, .Gradient)
			defer delete(img.pixels)

			buf: [dynamic]u8
			defer delete(buf)

			if !jpeg_save_space_accepts(space, channels) {
				testing.expectf(t, jpeg.save(&buf, &img, save_options = {color_space = space}) == image.Error(.Invalid_Color_Space), "%v x%v: expected Invalid_Color_Space", space, channels)
				continue
			}

			for subsampling in jpeg.Subsampling {
				result, ok := expect_jpeg_save_modes(t, "space", &img, 100, subsampling, space)
				if ok && (subsampling == .S444 || (space != .YCbCr && space != .YCCK)) {
					testing.expectf(t, result.psnr >= 38, "%v x%v %v: PSNR %.2f", space, channels, subsampling, result.psnr)
				}
			}

			testing.expect_value(t, jpeg.save(&buf, &img, save_options = {color_space = space}), nil)
			out, load_err := jpeg.load(buf[:], {.return_metadata, .do_not_decompress_image})
			defer jpeg.destroy(out)
			testing.expect_value(t, load_err, nil)
			if load_err != nil {
				continue
			}
			info, info_ok := out.metadata.(^image.JPEG_Info)
			testing.expect(t, info_ok)
			if info_ok {
				testing.expectf(t, info.color_space == space, "%v x%v: loaded as %v", space, channels, info.color_space)
				_, has_jfif := info.jfif_app0.?
				testing.expectf(t, has_jfif == (space == .Gray || space == .YCbCr), "%v x%v: JFIF present %v", space, channels, has_jfif)
			}
		}
	}
}

JPEG_Save_Lossless_Case :: struct {
	space:    Maybe(jpeg.Color_Space),
	channels: int,
	want:     int,
}

@(test)
jpeg_save_lossless :: proc(t: ^testing.T) {
	cases := [?]JPEG_Save_Lossless_Case{
		{nil, 1, 1},
		{nil, 2, 1},
		{nil, 3, 3},
		{nil, 4, 3},
		{jpeg.Color_Space.Gray,       1, 1},
		{jpeg.Color_Space.Gray,       2, 1},
		{jpeg.Color_Space.Gray_Alpha, 2, 2},
		{jpeg.Color_Space.RGB,        3, 3},
		{jpeg.Color_Space.RGB,        4, 3},
		{jpeg.Color_Space.CMYK,       4, 4},
	}
	sizes := [?][2]int{{1, 1}, {17, 9}, {40, 33}}
	for depth in ([?]int{8, 16}) {
		for size in sizes {
			for test_case in cases {
				for pattern in 0..<3 {
					img := jpeg_save_lossless_image(size[0], size[1], test_case.channels, depth, pattern)
					defer delete(img.pixels)

					for predictor in jpeg.Lossless_Predictor {
						for rows in ([?]u16{0, 2}) {
							for entropy in ([?]jpeg.Entropy_Coding{.Huffman, .Arithmetic}) {
								expect_jpeg_save_lossless(t, &img, test_case.space, test_case.want, predictor, rows, entropy)
							}
						}
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_lossless_sources :: proc(t: ^testing.T) {
	files := [?]string{
		TEST_SUITE_PATH_PNG + "/basn0g08.png",
		TEST_SUITE_PATH_PNG + "/basn2c08.png",
		TEST_SUITE_PATH_PNG + "/basn4a08.png",
		TEST_SUITE_PATH_PNG + "/basn6a08.png",
		TEST_SUITE_PATH_PNG + "/basn0g16.png",
		TEST_SUITE_PATH_PNG + "/basn2c16.png",
		TEST_SUITE_PATH_PNG + "/basn4a16.png",
		TEST_SUITE_PATH_PNG + "/basn6a16.png",
		TEST_SUITE_PATH_JPG + "/baseline-444.ref.png",
	}
	for file in files {
		src, src_err := png.load(file, {.do_not_expand_channels})
		defer png.destroy(src)
		testing.expectf(t, src_err == nil, "%v: source load returned %v", file, src_err)
		if src_err != nil {
			continue
		}

		space: Maybe(jpeg.Color_Space)
		want := [5]int{0, 1, 2, 3, 3}
		if src.channels == 2 {
			space = jpeg.Color_Space.Gray_Alpha
		}
		expect_jpeg_save_lossless(t, src, space, want[src.channels], .Best, 0)
		expect_jpeg_save_lossless(t, src, space, want[src.channels], .Left, 16)
		expect_jpeg_save_lossless(t, src, space, want[src.channels], .Best, 0, .Arithmetic)
		expect_jpeg_save_lossless(t, src, space, want[src.channels], .Average, 16, .Arithmetic)
	}
}

jpeg_save_lossless_image :: proc(width, height, channels, depth, pattern: int) -> (img: image.Image) {
	img = image.Image{width = width, height = height, channels = channels, depth = depth}
	resize(&img.pixels, width * height * channels * depth / 8)
	for y in 0..<height {
		for x in 0..<width {
			for c in 0..<channels {
				v: int
				switch pattern {
				case 0: v = rand.int_max(1 << uint(depth))
				case 1: v = ((x + y + c) & 1) << uint(depth - 1)
				case 2: v = ((x * 5 + y * 3 + c * 40) & 255) * (257 if depth == 16 else 1)
				}
				i := (y * width + x) * channels + c
				if depth == 16 {
					(^u16)(&img.pixels[2 * i])^ = u16(v)
				} else {
					img.pixels[i] = u8(v)
				}
			}
		}
	}
	return
}

jpeg_save_scan_predictor :: proc(buf: []u8) -> int {
	for i in 0..<len(buf) - 5 {
		if buf[i] == 0xFF && buf[i + 1] == 0xDA {
			count := int(buf[i + 4])
			if i + 5 + 2 * count < len(buf) {
				return int(buf[i + 5 + 2 * count])
			}
		}
	}
	return -1
}

expect_jpeg_save_lossless :: proc(t: ^testing.T, img: ^image.Image, space: Maybe(jpeg.Color_Space), want_channels: int, predictor: jpeg.Lossless_Predictor, rows: u16, entropy := jpeg.Entropy_Coding.Huffman, loc := #caller_location) {
	buf: [dynamic]u8
	defer delete(buf)

	save_err := jpeg.save(&buf, img, profile = .Lossless, save_options = {entropy_coding = entropy, lossless_predictor = predictor, restart_interval_rows = rows, color_space = space})
	testing.expectf(t, save_err == nil, "%vx%vx%v@%v %v %v r%v: save returned %v", img.width, img.height, img.channels, img.depth, space, predictor, rows, save_err, loc=loc)
	if save_err != nil {
		return
	}

	out, load_err := jpeg.load(buf[:], {.do_not_expand_channels, .return_metadata})
	defer jpeg.destroy(out)
	testing.expectf(t, load_err == nil, "%vx%vx%v@%v %v %v r%v: load returned %v", img.width, img.height, img.channels, img.depth, space, predictor, rows, load_err, loc=loc)
	if load_err != nil {
		return
	}

	dims      := Dims{out.width, out.height, out.channels, out.depth}
	want_dims := Dims{img.width, img.height, want_channels, img.depth}
	testing.expectf(t, dims == want_dims, "%v %v: decoded as %v, expected %v", space, predictor, dims, want_dims, loc=loc)
	if dims != want_dims {
		return
	}

	info, info_ok := out.metadata.(^image.JPEG_Info)
	testing.expect(t, info_ok, loc=loc)
	if info_ok {
		want_space, want_space_ok := space.?
		if !want_space_ok {
			want_space = .Gray if img.channels <= 2 else .RGB
		}
		want_frame := image.JPEG_Marker.SOF11 if entropy == .Arithmetic else .SOF3
		testing.expectf(t, info.frame_type == want_frame, "%v %v %v: frame type %v", space, predictor, entropy, info.frame_type, loc=loc)
		testing.expectf(t, info.color_space == want_space, "%v %v: color space %v", space, predictor, info.color_space, loc=loc)
	}

	bytes := img.depth / 8
	same  := true
	for p in 0..<img.width * img.height {
		for c in 0..<want_channels {
			a := img.pixels[(p * img.channels + c) * bytes:][:bytes]
			b := out.pixels[(p * want_channels + c) * bytes:][:bytes]
			if string(a) != string(b) {
				same = false
			}
		}
	}
	testing.expectf(t, same, "%vx%vx%v@%v %v %v r%v: not lossless", img.width, img.height, img.channels, img.depth, space, predictor, rows, loc=loc)

	if rows > 0 {
		_, rst := jpeg_save_count_markers(buf[:])
		testing.expectf(t, rst == (img.height - 1) / int(rows), "%vx%v r%v: %v RST markers", img.width, img.height, rows, rst, loc=loc)
	}

	ss := jpeg_save_scan_predictor(buf[:])
	if predictor != .Best {
		testing.expectf(t, ss == int(predictor) + 1, "%v: scan predictor %v", predictor, ss, loc=loc)
		return
	}
	testing.expectf(t, ss >= 1 && ss <= 7, "Best: scan predictor %v", ss, loc=loc)
	if ss < 1 || ss > 7 {
		return
	}
	explicit: [dynamic]u8
	defer delete(explicit)
	testing.expect_value(t, jpeg.save(&explicit, img, profile = .Lossless, save_options = {entropy_coding = entropy, lossless_predictor = jpeg.Lossless_Predictor(ss - 1), restart_interval_rows = rows, color_space = space}), nil, loc=loc)
	testing.expectf(t, string(buf[:]) == string(explicit[:]), "Best: differs from predictor %v", ss, loc=loc)
}

@(test)
jpeg_save_wide_sources :: proc(t: ^testing.T) {
	for source in JPEG_Save_Wide_Sources {
		src, src_err := png.load(source.file, {.do_not_expand_channels})
		defer png.destroy(src)
		testing.expectf(t, src_err == nil, "%v: source load returned %v", source.file, src_err)
		if src_err != nil {
			continue
		}
		narrow := src^
		wide   := jpeg_save_widen(src)
		defer delete(wide.pixels)

		for subsampling in jpeg.Subsampling {
			previous: JPEG_Save_Result
			for quality, qi in JPEG_SAVE_QUALITIES {
				if qi not_in JPEG_SAVE_SOURCE_QUALITIES {
					continue
				}
				result, ok := expect_jpeg_save_wide(t, source.file, &wide, quality, subsampling)
				if !ok {
					continue
				}
				floor := source.min_psnr[subsampling][qi]
				testing.expectf(t, result.psnr >= floor, "%v q%v %v: PSNR %.2f below %.2f", source.file, quality, subsampling, result.psnr, floor)
				if qi > 0 {
					testing.expectf(t, result.size >= previous.size, "%v q%v %v: size %v smaller than %v at a lower quality", source.file, quality, subsampling, result.size, previous.size)
				}
				previous = result

				if narrow.depth == 8 {
					buf: [dynamic]u8
					defer delete(buf)
					testing.expect_value(t, jpeg.save(&buf, &narrow, {}, quality, subsampling, .Extended), nil)
					out, load_err := jpeg.load(buf[:], {.do_not_expand_channels})
					defer jpeg.destroy(out)
					if load_err == nil {
						expected := jpeg_save_expected(&narrow, .Gray if narrow.channels <= 2 else .YCbCr)
						defer delete(expected)
						narrow_result := jpeg_save_compare(expected, out)
						testing.expectf(t, result.psnr >= narrow_result.psnr, "%v q%v %v: 12-bit PSNR %.2f below 8-bit %.2f", source.file, quality, subsampling, result.psnr, narrow_result.psnr)
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_wide_matrix :: proc(t: ^testing.T) {
	sizes := JPEG_SAVE_MATRIX_SIZES

	for channels in 1..=4 {
		for width in sizes {
			for height in sizes {
				img := jpeg_save_wide_image(width, height, channels, .Gradient)
				defer delete(img.pixels)

				for subsampling in jpeg.Subsampling {
					result, ok := expect_jpeg_save_wide(t, "synthetic", &img, 90, subsampling)
					if ok && subsampling == .S444 {
						testing.expectf(t, result.psnr >= 65, "synthetic %vx%vx%v %v: PSNR %.2f", width, height, channels, subsampling, result.psnr)
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_wide_spaces :: proc(t: ^testing.T) {
	for channels in 1..=4 {
		for space in jpeg.Color_Space {
			if !jpeg_save_space_accepts(space, channels) {
				continue
			}
			for pattern in ([?]JPEG_Save_Pattern{.Noise, .Pixel_Checker, .Gradient}) {
				img := jpeg_save_wide_image(33, 19, channels, pattern)
				defer delete(img.pixels)

				for quality in JPEG_SAVE_WIDE_QUALITIES {
					for subsampling in ([?]jpeg.Subsampling{.S444, .S420}) {
						for rows in ([?]u16{0, 1}) {
							result, ok := expect_jpeg_save_wide(t, "space", &img, quality, subsampling, space, rows)
							if !ok {
								continue
							}
							exact := space != .YCbCr && space != .YCCK && !(space == .Gray && channels > 2) && !(space == .Gray_Alpha && channels > 2)
							if quality == 100 && exact {
								testing.expectf(t, result.max_diff <= 1, "%v x%v %v %v r%v: max difference %v", space, channels, pattern, subsampling, rows, result.max_diff)
							}
						}
					}

					buf: [dynamic]u8
					defer delete(buf)
					testing.expect_value(t, jpeg.save(&buf, &img, {}, quality, .S444, .Extended, {color_space = space}), nil)
					testing.expectf(t, jpeg_save_dqt_precision(buf[:]) == (1 if quality < 50 else 0), "%v q%v: DQT precision %v", space, quality, jpeg_save_dqt_precision(buf[:]))
				}
			}
		}
	}
}

jpeg_save_widen :: proc(src: ^image.Image) -> (img: image.Image) {
	img = src^
	img.pixels = {}
	img.depth  = 16
	if src.depth == 16 {
		append(&img.pixels, ..src.pixels[:])
		return
	}
	resize(&img.pixels, 2 * len(src.pixels))
	for v, i in src.pixels {
		(^u16)(&img.pixels[2 * i])^ = u16(v) * 257
	}
	return
}

jpeg_save_wide_image :: proc(width, height, channels: int, pattern: JPEG_Save_Pattern) -> (img: image.Image) {
	base := jpeg_save_pattern_image(width, height, channels, pattern)
	defer delete(base.pixels)
	img = jpeg_save_widen(&base)
	for i in 0..<width * height * channels {
		x := i / channels % width
		y := i / channels / width
		c := i % channels
		#partial switch pattern {
		case .Noise:    (^u16)(&img.pixels[2 * i])^ = u16(rand.int_max(65536))
		case .Gradient: (^u16)(&img.pixels[2 * i])^ = u16(((x * 61 + y * 17 + c * 900) & 4095) << 4)
		}
	}
	return
}

jpeg_save_sample16 :: proc(pixels: []u8, i: int) -> int {
	return int((^u16)(&pixels[2 * i])^)
}

jpeg_save_wide_expected :: proc(src: ^image.Image, space: jpeg.Color_Space) -> (expected: []u16) {
	channels := JPEG_SAVE_SPACE_CHANNELS
	n := channels[space]
	expected = make([]u16, src.width * src.height * n)
	for i in 0..<src.width * src.height {
		p   := i * src.channels
		out := expected[i * n:][:n]
		switch space {
		case .Gray, .Gray_Alpha:
			if src.channels <= 2 {
				out[0] = u16(jpeg_save_sample16(src.pixels[:], p) >> 4)
			} else {
				r := f64(jpeg_save_sample16(src.pixels[:], p)     >> 4)
				g := f64(jpeg_save_sample16(src.pixels[:], p + 1) >> 4)
				b := f64(jpeg_save_sample16(src.pixels[:], p + 2) >> 4)
				out[0] = u16(clamp(math.round(0.299 * r + 0.587 * g + 0.114 * b), 0, 4095))
			}
			if space == .Gray_Alpha {
				out[1] = u16(jpeg_save_sample16(src.pixels[:], p + src.channels - 1) >> 4)
			}
		case .YCbCr, .RGB, .CMYK, .YCCK:
			for c in 0..<n {
				out[c] = u16(jpeg_save_sample16(src.pixels[:], p + c) >> 4)
			}
		}
	}
	return
}

jpeg_save_frame_header :: proc(buf: []u8) -> (marker: u8, precision: u8) {
	i := 2
	for i + 4 < len(buf) && buf[i] == 0xFF {
		switch buf[i + 1] {
		case 0xC0..=0xC3, 0xC9..=0xCB:
			return buf[i + 1], buf[i + 4]
		case 0xDA:
			return
		}
		i += 2 + int(buf[i + 2]) << 8 + int(buf[i + 3])
	}
	return
}

jpeg_save_want_marker :: proc(mode: JPEG_Save_Mode) -> u8 {
	marker := u8(0xC2 if mode.profile == .Progressive else 0xC1)
	if mode.options.entropy_coding == .Arithmetic {
		marker += 8
	}
	return marker
}

jpeg_save_dqt_length :: proc(buf: []u8) -> int {
	for i in 0..<len(buf) - 4 {
		if buf[i] == 0xFF && buf[i + 1] == 0xDB {
			return int(buf[i + 2]) << 8 | int(buf[i + 3])
		}
	}
	return 0
}

jpeg_save_dqt_precision :: proc(buf: []u8) -> int {
	for i in 0..<len(buf) - 4 {
		if buf[i] == 0xFF && buf[i + 1] == 0xDB {
			return int(buf[i + 4] >> 4)
		}
	}
	return -1
}

expect_jpeg_save_wide :: proc(t: ^testing.T, name: string, src: ^image.Image, quality: int, subsampling: jpeg.Subsampling, color_space: Maybe(jpeg.Color_Space) = nil, restart_rows := u16(0), loc := #caller_location) -> (result: JPEG_Save_Result, ok: bool) {
	space, space_ok := color_space.?
	if !space_ok {
		space = .Gray if src.channels <= 2 else .YCbCr
	}
	channels := JPEG_SAVE_SPACE_CHANNELS
	want_channels := channels[space]
	expected := jpeg_save_wide_expected(src, space)
	defer delete(expected)

	reference: ^image.Image
	defer jpeg.destroy(reference)
	extended: [dynamic]u8
	defer delete(extended)

	for mode, mi in JPEG_Save_Wide_Modes {
		buf: [dynamic]u8
		defer delete(buf)

		options := mode.options
		options.color_space           = color_space
		options.restart_interval_rows = restart_rows
		save_err := jpeg.save(&buf, src, {}, quality, subsampling, mode.profile, options)
		testing.expectf(t, save_err == nil, "%v %vx%vx%v q%v %v %v %v r%v: save returned %v", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, save_err, loc=loc)
		if save_err != nil {
			return
		}

		marker, precision := jpeg_save_frame_header(buf[:])
		want_marker := jpeg_save_want_marker(mode)
		testing.expectf(t, marker == want_marker && precision == 12, "%v q%v %v %v: frame %2X at %v bits", name, quality, subsampling, mode, marker, precision, loc=loc)

		out, load_err := jpeg.load(buf[:], {.do_not_expand_channels})
		testing.expectf(t, load_err == nil, "%v %vx%vx%v q%v %v %v %v r%v: load returned %v", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, load_err, loc=loc)
		if load_err != nil {
			jpeg.destroy(out)
			return
		}

		dims      := Dims{out.width, out.height, out.channels, out.depth}
		want_dims := Dims{src.width, src.height, want_channels, 16}
		testing.expectf(t, dims == want_dims, "%v q%v %v %v %v: decoded as %v, expected %v", name, quality, subsampling, mode, space, dims, want_dims, loc=loc)
		if dims != want_dims {
			jpeg.destroy(out)
			return
		}

		if mi == 0 {
			reference = out
			for v, i in expected {
				d := abs(int(v) - jpeg_save_sample16(out.pixels[:], i))
				result.psnr     += f64(d * d)
				result.mean     += f64(d)
				result.max_diff  = max(result.max_diff, d)
			}
			n := f64(len(expected))
			mse := result.psnr / n
			result.mean /= n
			result.psnr  = 99 if mse == 0 else 10 * math.log10(4095 * 4095 / mse)
			result.size  = len(buf) - jpeg_save_dqt_length(buf[:])
			append(&extended, ..buf[:])
			expect_stream_loads(t, name, buf[:], jpeg_context_loader, {.do_not_expand_channels}, out, load_err, loc=loc)
			continue
		}
		defer jpeg.destroy(out)

		if mode.profile == .Extended && mode.options.entropy_coding != .Arithmetic {
			testing.expectf(t, string(buf[:]) == string(extended[:]), "%v %vx%vx%v q%v %v %v: Huffman and Huffman_Optimized differ", name, src.width, src.height, src.channels, quality, subsampling, space, loc=loc)
		}
		testing.expectf(t, string(out.pixels[:]) == string(reference.pixels[:]), "%v %vx%vx%v q%v %v %v %v r%v: decodes differently from the extended encoding", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, loc=loc)
	}
	return result, true
}

@(test)
jpeg_save_file :: proc(t: ^testing.T) {
	img := png_save_test_image(17, 9, 3, 8)
	defer delete(img.pixels)

	dir, dir_err := os.temp_directory(context.temp_allocator)
	testing.expect_value(t, dir_err, nil)
	if dir_err != nil {
		return
	}
	path, path_err := os.join_path({dir, "odin_jpeg_save_test.jpg"}, context.temp_allocator)
	testing.expect_value(t, path_err, nil)
	if path_err != nil {
		return
	}
	defer os.remove(path)

	testing.expect_value(t, jpeg.save(path, &img), nil)

	out, load_err := jpeg.load(path)
	defer jpeg.destroy(out)
	testing.expect_value(t, load_err, nil)
	if load_err == nil {
		testing.expect_value(t, Dims{out.width, out.height, out.channels, out.depth}, Dims{17, 9, 3, 8})
	}
}

@(test)
jpeg_save_invalid :: proc(t: ^testing.T) {
	buf: [dynamic]u8
	defer delete(buf)

	img := png_save_test_image(4, 4, 3, 8)
	defer delete(img.pixels)

	testing.expect_value(t, jpeg.save(&buf, nil), image.Error(.Invalid_Input_Image))
	testing.expect_value(t, jpeg.save(nil, &img), image.Error(.Invalid_Output))

	bad := img
	bad.width = 0
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Image_Dimensions))

	bad = img
	bad.height = 0
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Image_Dimensions))

	bad = img
	bad.width = 65536
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Image_Dimensions))

	bad = img
	bad.channels = 0
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Number_Of_Channels))

	bad = img
	bad.channels = 5
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Number_Of_Channels))

	bad = img
	bad.depth = 16
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Image_Depth))

	bad = img
	bad.depth = 1
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Image_Depth))

	bad = img
	bad.width = 5
	testing.expect_value(t, jpeg.save(&buf, &bad), image.Error(.Invalid_Input_Image))

	testing.expect_value(t, jpeg.save(&buf, &img, quality = 0), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, quality = 101), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, subsampling = jpeg.Subsampling(3)), image.Error(.Unsupported_Option))

	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Lossless, save_options = {entropy_coding = .Arithmetic}), nil)
	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Lossless, save_options = {color_space = .YCbCr}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Lossless, save_options = {color_space = .Gray}), image.Error(.Unsupported_Option))

	bad = img
	bad.depth = 16
	testing.expect_value(t, jpeg.save(&buf, &bad, profile = .Lossless), image.Error(.Invalid_Input_Image))

	wide := png_save_test_image(4, 4, 4, 16)
	defer delete(wide.pixels)
	testing.expect_value(t, jpeg.save(&buf, &wide), image.Error(.Invalid_Image_Depth))
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Extended), nil)
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Progressive), nil)
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Extended, save_options = {entropy_coding = .Arithmetic}), nil)
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Progressive, save_options = {entropy_coding = .Arithmetic}), nil)
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Lossless, save_options = {entropy_coding = .Arithmetic}), nil)
	bad = img
	bad.depth = 16
	testing.expect_value(t, jpeg.save(&buf, &bad, profile = .Extended), image.Error(.Invalid_Input_Image))
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Lossless, save_options = {color_space = .YCCK}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Lossless, save_options = {color_space = .Gray_Alpha}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Lossless), nil)
	testing.expect_value(t, jpeg.save(&buf, &img, profile = jpeg.Profile(9)), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, save_options = {entropy_coding = .Arithmetic}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Baseline, save_options = {entropy_coding = .Arithmetic}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &wide, profile = .Baseline, save_options = {entropy_coding = .Arithmetic}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Extended, save_options = {entropy_coding = .Arithmetic}), nil)
	testing.expect_value(t, jpeg.save(&buf, &img, profile = .Progressive, save_options = {entropy_coding = .Arithmetic}), nil)
	testing.expect_value(t, jpeg.save(&buf, &img, save_options = {entropy_coding = jpeg.Entropy_Coding(9)}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, save_options = {lossless_predictor = jpeg.Lossless_Predictor(9)}), image.Error(.Unsupported_Option))
	testing.expect_value(t, jpeg.save(&buf, &img, save_options = {color_space = jpeg.Color_Space(9)}), image.Error(.Invalid_Color_Space))

}

JPEG_Save_Pattern :: enum {
	Noise,
	Low_Noise,
	Flat_Black,
	Flat_White,
	Pixel_Checker,
	Block_Checker,
	Stripes,
	Gradient,
}

@(test)
jpeg_save_fuzz :: proc(t: ^testing.T) {
	for _ in 0..<JPEG_SAVE_FUZZ_ROUNDS {
		width       := 1 + rand.int_max(40)
		height      := 1 + rand.int_max(40)
		channels    := 1 + rand.int_max(4)
		quality     := 1 + rand.int_max(100)
		subsampling := jpeg.Subsampling(rand.int_max(len(jpeg.Subsampling)))
		pattern     := JPEG_Save_Pattern(rand.int_max(len(JPEG_Save_Pattern)))

		img := jpeg_save_pattern_image(width, height, channels, pattern)
		defer delete(img.pixels)

		restart_rows := u16(rand.int_max(3))
		space: Maybe(jpeg.Color_Space)
		if rand.int_max(2) == 1 {
			candidate := jpeg.Color_Space(rand.int_max(len(jpeg.Color_Space)))
			if jpeg_save_space_accepts(candidate, channels) {
				space = candidate
			}
		}
		expect_jpeg_save_modes(t, "fuzz", &img, quality, subsampling, space, restart_rows)
		expect_jpeg_save_lossless(t, &img, nil, 1 if channels <= 2 else 3, jpeg.Lossless_Predictor(rand.int_max(len(jpeg.Lossless_Predictor))), restart_rows, jpeg.Entropy_Coding(rand.int_max(len(jpeg.Entropy_Coding))))

		wide := jpeg_save_wide_image(width, height, channels, pattern)
		defer delete(wide.pixels)
		expect_jpeg_save_wide(t, "fuzz", &wide, quality, subsampling, space, restart_rows)
	}
}

@(test)
jpeg_save_extremes :: proc(t: ^testing.T) {
	for pattern in ([?]JPEG_Save_Pattern{.Pixel_Checker, .Block_Checker, .Stripes, .Noise}) {
		for channels in ([?]int{1, 3}) {
			img := jpeg_save_pattern_image(64, 48, channels, pattern)
			defer delete(img.pixels)

			for quality in JPEG_SAVE_EXTREME_QUALITY {
				for subsampling in jpeg.Subsampling {
					result, ok := expect_jpeg_save_modes(t, "extreme", &img, quality, subsampling)
					if ok && quality == 100 && (subsampling == .S444 || channels == 1) {
						testing.expectf(t, result.psnr >= 30, "%v x%v q100 %v: PSNR %.2f", pattern, channels, subsampling, result.psnr)
					}
				}
			}
		}
	}
}

@(test)
jpeg_save_strips :: proc(t: ^testing.T) {
	sizes := JPEG_SAVE_STRIP_SIZES
	for size in sizes {
		for channels in ([?]int{1, 3}) {
			img := jpeg_save_pattern_image(size[0], size[1], channels, .Gradient)
			defer delete(img.pixels)

			for subsampling in jpeg.Subsampling {
				expect_jpeg_save_modes(t, "strip", &img, 90, subsampling)
			}
		}
	}
}

@(test)
jpeg_save_eobrun :: proc(t: ^testing.T) {
	img := jpeg_save_pattern_image(2056, 1024, 1, .Low_Noise)
	defer delete(img.pixels)

	for quality in JPEG_SAVE_EOBRUN_QUALITY {
		expect_jpeg_save_modes(t, "eobrun", &img, quality, .S444)
	}
}

@(test)
jpeg_save_allocation_failure :: proc(t: ^testing.T) {
	for channels in ([?]int{1, 3}) {
		img := jpeg_save_pattern_image(61, 47, channels, .Noise)
		defer delete(img.pixels)

		modes: [len(JPEG_Save_Modes) + 2]JPEG_Save_Mode
		copy(modes[:], JPEG_Save_Modes[:])
		modes[len(JPEG_Save_Modes)] = {.Lossless, {lossless_predictor = .Best}}
		modes[len(JPEG_Save_Modes) + 1] = {.Lossless, {entropy_coding = .Arithmetic, lossless_predictor = .Best}}
		for mode in modes {
			expect_jpeg_save_allocations(t, &img, mode)
		}

		wide := jpeg_save_wide_image(61, 47, channels, .Noise)
		defer delete(wide.pixels)
		for mode in JPEG_Save_Wide_Modes {
			expect_jpeg_save_allocations(t, &wide, mode)
		}
	}
}

expect_jpeg_save_allocations :: proc(t: ^testing.T, img: ^image.Image, mode: JPEG_Save_Mode, loc := #caller_location) {
	reference: [dynamic]u8
	defer delete(reference)
	testing.expect_value(t, jpeg.save(&reference, img, {}, 100, .S420, mode.profile, mode.options), nil, loc=loc)

	counter := Jpeg_Failing_Allocator{backing = context.allocator, fail_at = -1, limit = max(int)}
	expect_jpeg_save_with_allocator(t, img, mode, &counter, reference[:], loc)
	testing.expectf(t, !counter.failed, "x%v@%v %v: unexpected allocation failure", img.channels, img.depth, mode, loc=loc)

	for fail_at in 0..<counter.count {
		failing := Jpeg_Failing_Allocator{backing = context.allocator, fail_at = fail_at, limit = max(int)}
		expect_jpeg_save_with_allocator(t, img, mode, &failing, reference[:], loc)
	}

	for limit := 64; limit < 2 * len(reference); limit *= 2 {
		failing := Jpeg_Failing_Allocator{backing = context.allocator, fail_at = -1, limit = limit}
		expect_jpeg_save_with_allocator(t, img, mode, &failing, reference[:], loc)
	}
}

Jpeg_Failing_Allocator :: struct {
	backing: runtime.Allocator,
	fail_at: int,
	limit:   int,
	count:   int,
	failed:  bool,
}

jpeg_failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	f := (^Jpeg_Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		index := f.count
		f.count += 1
		if index == f.fail_at || size > f.limit {
			f.failed = true
			return nil, .Out_Of_Memory
		}
	}
	return f.backing.procedure(f.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

expect_jpeg_save_with_allocator :: proc(t: ^testing.T, img: ^image.Image, mode: JPEG_Save_Mode, f: ^Jpeg_Failing_Allocator, reference: []u8, loc := #caller_location) {
	allocator := runtime.Allocator{procedure = jpeg_failing_allocator_proc, data = f}
	buf := make([dynamic]u8, allocator)
	defer delete(buf)

	err := jpeg.save(&buf, img, {}, 100, .S420, mode.profile, mode.options, allocator)
	if f.failed {
		testing.expectf(t, err == image.Error(.Unable_To_Allocate_Or_Resize), "x%v %v fail_at %v limit %v: save returned %v", img.channels, mode, f.fail_at, f.limit, err, loc=loc)
		testing.expectf(t, len(buf) == 0, "x%v %v fail_at %v limit %v: %v bytes left in the output", img.channels, mode, f.fail_at, f.limit, len(buf), loc=loc)
	} else {
		testing.expectf(t, err == nil, "x%v %v: save returned %v", img.channels, mode, err, loc=loc)
		testing.expectf(t, string(buf[:]) == string(reference), "x%v %v limit %v: output differs from the reference", img.channels, mode, f.limit, loc=loc)
	}
}

jpeg_save_pattern_image :: proc(width, height, channels: int, pattern: JPEG_Save_Pattern) -> (img: image.Image) {
	img = image.Image{width = width, height = height, channels = channels, depth = 8}
	resize(&img.pixels, width * height * channels)
	for y in 0..<height {
		for x in 0..<width {
			for c in 0..<channels {
				v: int
				switch pattern {
				case .Noise:         v = rand.int_max(256)
				case .Low_Noise:     v = 128 + rand.int_max(5) - 2
				case .Flat_Black:    v = 0
				case .Flat_White:    v = 255
				case .Pixel_Checker: v = 255 * ((x + y + c) & 1)
				case .Block_Checker: v = 255 * ((x / 8 + y / 8 + c) & 1)
				case .Stripes:       v = 255 * ((y + c) & 1)
				case .Gradient:      v = (x * 7 + y * 3 + c * 50) & 255
				}
				img.pixels[(y * width + x) * channels + c] = u8(v)
			}
		}
	}
	return
}

expect_jpeg_save_modes :: proc(t: ^testing.T, name: string, src: ^image.Image, quality: int, subsampling: jpeg.Subsampling, color_space: Maybe(jpeg.Color_Space) = nil, restart_rows := u16(0), loc := #caller_location) -> (result: JPEG_Save_Result, ok: bool) {
	space, space_ok := color_space.?
	if !space_ok {
		space = .Gray if src.channels <= 2 else .YCbCr
	}
	channels := JPEG_SAVE_SPACE_CHANNELS
	want_channels := channels[space]
	expected := jpeg_save_expected(src, space)
	defer delete(expected)

	baseline: ^image.Image
	defer jpeg.destroy(baseline)

	for mode, mi in JPEG_Save_Modes {
		buf: [dynamic]u8
		defer delete(buf)

		options := mode.options
		options.color_space           = color_space
		options.restart_interval_rows = restart_rows
		save_err := jpeg.save(&buf, src, {}, quality, subsampling, mode.profile, options)
		testing.expectf(t, save_err == nil, "%v %vx%vx%v q%v %v %v %v r%v: save returned %v", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, save_err, loc=loc)
		if save_err != nil {
			return
		}

		marker, _ := jpeg_save_frame_header(buf[:])
		want_marker := u8(0xC0) if mode.profile == .Baseline else jpeg_save_want_marker(mode)
		testing.expectf(t, marker == want_marker, "%v q%v %v %v: frame %2X", name, quality, subsampling, mode, marker, loc=loc)

		out, load_err := jpeg.load(buf[:], {.do_not_expand_channels})
		testing.expectf(t, load_err == nil, "%v %vx%vx%v q%v %v %v %v r%v: load returned %v", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, load_err, loc=loc)
		if load_err != nil {
			jpeg.destroy(out)
			return
		}

		dims      := Dims{out.width, out.height, out.channels, out.depth}
		want_dims := Dims{src.width, src.height, want_channels, 8}
		testing.expectf(t, dims == want_dims, "%v q%v %v %v %v: decoded as %v, expected %v", name, quality, subsampling, mode, space, dims, want_dims, loc=loc)
		if dims != want_dims {
			jpeg.destroy(out)
			return
		}

		if mi == 0 {
			baseline    = out
			result      = jpeg_save_compare(expected, out)
			result.size = len(buf)
			expect_stream_loads(t, name, buf[:], jpeg_context_loader, {.do_not_expand_channels}, out, load_err, loc=loc)
			continue
		}
		defer jpeg.destroy(out)

		same := true
		for v, i in out.pixels {
			if v != baseline.pixels[i] {
				same = false
				break
			}
		}
		testing.expectf(t, same, "%v %vx%vx%v q%v %v %v %v r%v: decodes differently from the baseline encoding", name, src.width, src.height, src.channels, quality, subsampling, mode, space, restart_rows, loc=loc)
		if mode.options.entropy_coding != .Huffman && mode.profile != .Progressive {
			testing.expectf(t, len(buf) <= result.size, "%v q%v %v %v: optimized size %v exceeds baseline %v", name, quality, subsampling, mode, len(buf), result.size, loc=loc)
		}
	}
	return result, true
}

jpeg_save_expected :: proc(src: ^image.Image, space: jpeg.Color_Space) -> (expected: []u8) {
	channels := JPEG_SAVE_SPACE_CHANNELS
	n := channels[space]
	expected = make([]u8, src.width * src.height * n)
	for i in 0..<src.width * src.height {
		p   := src.pixels[i * src.channels:][:src.channels]
		out := expected[i * n:][:n]
		switch space {
		case .Gray, .Gray_Alpha:
			if src.channels <= 2 {
				out[0] = p[0]
			} else {
				out[0] = u8(clamp(math.round(0.299 * f64(p[0]) + 0.587 * f64(p[1]) + 0.114 * f64(p[2])), 0, 255))
			}
			if space == .Gray_Alpha {
				out[1] = p[src.channels - 1]
			}
		case .YCbCr, .RGB, .CMYK, .YCCK:
			copy(out, p[:n])
		}
	}
	return
}

jpeg_save_compare :: proc(expected: []u8, out: ^image.Image) -> (result: JPEG_Save_Result) {
	sum_sq: f64
	total:  int
	for v, i in expected {
		d := abs(int(v) - int(out.pixels[i]))
		sum_sq += f64(d * d)
		total  += d
		result.max_diff = max(result.max_diff, d)
	}
	n   := f64(len(expected))
	mse := sum_sq / n
	result.mean = f64(total) / n
	result.psnr = 99 if mse == 0 else 10 * math.log10(255 * 255 / mse)
	return
}
