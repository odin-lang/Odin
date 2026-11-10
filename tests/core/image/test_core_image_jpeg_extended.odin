package test_core_image

import "core:bytes"
import "core:compress"
import "core:image"
import "core:image/jpeg"
import pbm "core:image/netpbm"
import "core:image/png"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"

JPG_Wide_Reference :: struct {
	name:           string,
	reference:      string,
	max_difference: int,
}

JPG_Wide_Reference_Files := []JPG_Wide_Reference{
	{"p12-seq-444",        "p12-seq-444.ref.ppm",        3},
	{"p12-seq-420",        "p12-seq-420.ref.ppm",        3},
	{"p12-seq-422",        "p12-seq-422.ref.ppm",        3},
	{"p12-prog-420",       "p12-prog-420.ref.ppm",       3},
	{"p12-restart",        "p12-restart.ref.ppm",        3},
	{"p12-gray",           "p12-gray.ref.pgm",           3},
	{"p12-prog-gray",      "p12-prog-gray.ref.pgm",      3},
	{"p12-q100",           "p12-q100.ref.ppm",           3},
	{"ll-p16-psv1",        "ll-p16-psv1.ref.ppm",        0},
	{"ll-p16-psv2",        "ll-p16-psv2.ref.ppm",        0},
	{"ll-p16-psv3",        "ll-p16-psv3.ref.ppm",        0},
	{"ll-p16-psv4",        "ll-p16-psv4.ref.ppm",        0},
	{"ll-p16-psv5",        "ll-p16-psv5.ref.ppm",        0},
	{"ll-p16-psv6",        "ll-p16-psv6.ref.ppm",        0},
	{"ll-p16-psv7",        "ll-p16-psv7.ref.ppm",        0},
	{"ll-p16-gray",        "ll-p16-gray.ref.pgm",        0},
	{"ll-p16-pt",          "ll-p16-pt.ref.ppm",          0},
	{"ll-p16-restart",     "ll-p16-restart.ref.ppm",     0},
	{"ll-p12-psv1",        "ll-p12-psv1.ref.ppm",        0},
	{"ll-p12-psv2",        "ll-p12-psv2.ref.ppm",        0},
	{"ll-p12-psv3",        "ll-p12-psv3.ref.ppm",        0},
	{"ll-p12-psv4",        "ll-p12-psv4.ref.ppm",        0},
	{"ll-p12-psv5",        "ll-p12-psv5.ref.ppm",        0},
	{"ll-p12-psv6",        "ll-p12-psv6.ref.ppm",        0},
	{"ll-p12-psv7",        "ll-p12-psv7.ref.ppm",        0},
	{"ll-p12-gray",        "ll-p12-gray.ref.pgm",        0},
	{"ll-p12-pt",          "ll-p12-pt.ref.ppm",          0},
	{"ll-p12-restart",     "ll-p12-restart.ref.ppm",     0},
	{"ll-p8-psv1",         "ll-p8-psv1.ref.ppm",         0},
	{"ll-p8-gray",         "ll-p8-gray.ref.pgm",         0},
	{"ll-p2-psv1",         "ll-p2-psv1.ref.ppm",         0},
	{"ll-p2-gray",         "ll-p2-gray.ref.pgm",         0},
	{"ll-py-sub",          "ll-py-sub.ref.ppm",          0},
	{"ll-py-ga16",         "ll-py-ga16.ref.pam",         0},
	{"ll-py-ga8",          "ll-py-ga8.ref.pam",          0},
	{"dc-gray-alpha",      "dc-gray-alpha.ref.pam",      0},
	{"richter-nodnl",      "richter-nodnl.ref.ppm",      3},
	{"arith-seq-444",      "arith-seq-444.ref.ppm",      3},
	{"arith-seq-420",      "arith-seq-420.ref.ppm",      3},
	{"arith-prog-420",     "arith-prog-420.ref.ppm",     3},
	{"arith-restart",      "arith-restart.ref.ppm",      3},
	{"arith-gray",         "arith-gray.ref.pgm",         3},
	{"arith-p12-seq-420",  "arith-p12-seq-420.ref.ppm",  3},
	{"arith-p12-prog-gray","arith-p12-prog-gray.ref.pgm",3},
	{"arith-dac-420",      "arith-dac-420.ref.ppm",      3},
	{"arith-dac-gray",     "arith-dac-gray.ref.pgm",     3},
	{"arith-dac-p12",      "arith-dac-p12.ref.ppm",      3},
	{"ll-arith-gray12",    "ll-arith-gray12.ref.pgm",    0},
	{"ll-arith-rgb16",     "ll-arith-rgb16.ref.ppm",     0},
	{"hl-gray16",          "hl-gray16.ref.pgm",          0},
	{"hl-gray16-arith",    "hl-gray16.ref.pgm",          0},
	{"hl-rgb8",            "hl-rgb8.ref.ppm",            0},
	{"hl-rgb8-arith",      "hl-rgb8.ref.ppm",            0},
	{"hl-rgb12-arith",     "hl-rgb12.ref.ppm",           0},
	{"hl-sub-h",           "hl-sub-h.ref.ppm",           0},
	{"hl-sub-a",           "hl-sub-a.ref.ppm",           0},
	{"hier-sub-h",         "hier-sub-h.ref.ppm",         0},
	{"hier-sub-a",         "hier-sub-a.ref.ppm",         0},
	{"hier-prog-h12",      "hier-prog-h12.ref.pgm",      0},
	{"hier-prog-a12",      "hier-prog-a12.ref.ppm",      0},
	{"ll-py-cmyk8",        "ll-py-cmyk8.ref.pam",        0},
	{"ll-py-cmyk12",       "ll-py-cmyk12.ref.pam",       0},
	{"ll-py-ycck8",        "ll-py-ycck8.ref.pam",        0},
	{"ll-py-ycck12",       "ll-py-ycck12.ref.pam",       0},
}

JPG_Hierarchical_DCT_Reference :: struct {
	name:           string,
	reference:      string,
	max_difference: int,
	max_mean:       f64,
}

JPG_Hierarchical_DCT_Files := []JPG_Hierarchical_DCT_Reference{
	{"hier-dct-h0",   "hier-dct-h0.ref.ppm",   1,  0.5},
	{"hier-dct-a0",   "hier-dct-a0.ref.ppm",   1,  0.5},
	{"hier-dct-gray", "hier-dct-gray.ref.pgm", 1,  0.35},
	{"hier-dct-h2",   "hier-dct-h2.ref.ppm",   5,  1.0},
	{"hier-dct-rst",  "hier-dct-rst.ref.ppm",  5,  1.0},
	{"hier-dct-a3",   "hier-dct-a3.ref.ppm",   6,  1.25},
	{"hier-dct-420",  "hier-dct-420.ref.ppm",  17, 1.0},
	{"hier-dct-prog-h2",  "hier-dct-prog-h2.ref.ppm",  5, 1.0},
	{"hier-dct-prog-a2",  "hier-dct-prog-a2.ref.ppm",  5, 1.0},
	{"hier-dct-prog-h0",  "hier-dct-prog-h0.ref.ppm",  1, 0.5},
	{"hier-dct-prog-g12", "hier-dct-prog-g12.ref.pgm", 4, 0.75},
}

JPG_DNL_Files := [][2]string{
	{"ll-py-gray-dnl",    "ll-py-gray-dnl.ref.pgm"},
	{"ll-py-sub-dnl",     "ll-py-sub.ref.ppm"},
	{"dc-gray-alpha-dnl", "dc-gray-alpha.ref.pam"},
	{"richter-dnl",       "richter-nodnl.ref.ppm"},
}

JPG_RAW_OPTIONS :: image.Options{.do_not_expand_channels}

jpg_path :: proc(name: string, extension := ".jpg") -> string {
	return strings.concatenate({TEST_SUITE_PATH_JPG, "/", name, extension}, context.temp_allocator)
}

samples_u16 :: proc(img: ^image.Image) -> []u16 {
	if img.depth == 16 {
		return slice.reinterpret([]u16, img.pixels[:])
	}
	out := make([]u16, len(img.pixels), context.temp_allocator)
	for v, i in img.pixels {
		out[i] = u16(v)
	}
	return out
}

expect_matches_netpbm :: proc(t: ^testing.T, name: string, img: ^image.Image, reference: string, max_difference: int, max_mean := JPG_REFERENCE_MAX_MEAN, loc := #caller_location) {
	ref, ref_err := pbm.load_from_file(jpg_path(reference, ""))
	defer pbm.destroy(ref)
	testing.expectf(t, ref_err == nil, "%v: reference load returned %v", name, ref_err, loc=loc)
	if ref_err != nil {
		return
	}

	dims     := Dims{img.width, img.height, img.channels, img.depth}
	ref_dims := Dims{ref.width, ref.height, ref.channels, ref.depth}
	testing.expectf(t, dims == ref_dims, "%v has %v, expected %v", name, dims, ref_dims, loc=loc)
	if dims != ref_dims {
		return
	}

	a := samples_u16(img)
	b := samples_u16(ref)
	worst := 0
	total := 0
	for i in 0..<len(a) {
		difference := abs(int(a[i]) - int(b[i]))
		worst  = max(worst, difference)
		total += difference
	}
	mean := f64(total) / f64(len(a))
	testing.expectf(t, worst <= max_difference, "%v: maximum difference from the reference is %v", name, worst, loc=loc)
	testing.expectf(t, mean <= max_mean, "%v: mean difference from the reference is %v", name, mean, loc=loc)
}

@test
jpeg_test_wide_reference :: proc(t: ^testing.T) {
	for file in JPG_Wide_Reference_Files {
		jpg_file := jpg_path(file.name)
		img, err := jpeg.load(jpg_file, JPG_RAW_OPTIONS)
		defer jpeg.destroy(img)
		testing.expectf(t, err == nil, "%v: load returned %v", file.name, err)
		if err != nil {
			continue
		}
		expect_stream_loads_file(t, file.name, jpg_file, jpeg_context_loader, JPG_RAW_OPTIONS, img, nil)
		expect_matches_netpbm(t, file.name, img, file.reference, file.max_difference)
	}
}

@test
jpeg_test_hierarchical_dct :: proc(t: ^testing.T) {
	for file in JPG_Hierarchical_DCT_Files {
		jpg_file := jpg_path(file.name)
		img, err := jpeg.load(jpg_file, JPG_RAW_OPTIONS)
		defer jpeg.destroy(img)
		testing.expectf(t, err == nil, "%v: load returned %v", file.name, err)
		if err != nil {
			continue
		}
		expect_stream_loads_file(t, file.name, jpg_file, jpeg_context_loader, JPG_RAW_OPTIONS, img, nil)
		expect_matches_netpbm(t, file.name, img, file.reference, file.max_difference, file.max_mean)
	}
}

replicate_sample :: proc(v: u32, from, to: int) -> (out: u32) {
	bits := to
	for bits > 0 {
		if bits >= from {
			out  |= v << u32(bits - from)
			bits -= from
		} else {
			out  |= v >> u32(from - bits)
			bits  = 0
		}
	}
	return
}

@test
jpeg_test_sample_scaling :: proc(t: ^testing.T) {
	Case :: struct {
		name:      string,
		precision: int,
		depth:     int,
	}
	cases := []Case{
		{"p12-seq-444", 12, 16},
		{"ll-p12-gray", 12, 16},
		{"ll-p2-gray",   2,  8},
		{"ll-p8-psv1",   8,  8},
		{"ll-p16-psv1", 16, 16},
		{"ll-py-cmyk12", 12, 16},
		{"ll-py-ycck12", 12, 16},
	}
	for c in cases {
		raw, raw_err := jpeg.load(jpg_path(c.name), JPG_RAW_OPTIONS)
		defer jpeg.destroy(raw)
		scaled, scaled_err := jpeg.load(jpg_path(c.name), {.do_not_expand_grayscale})
		defer jpeg.destroy(scaled)
		testing.expectf(t, raw_err == nil && scaled_err == nil, "%v: load returned %v, %v", c.name, raw_err, scaled_err)
		if raw_err != nil || scaled_err != nil {
			continue
		}
		testing.expectf(t, raw.depth == c.depth && scaled.depth == c.depth, "%v: depth %v and %v, expected %v", c.name, raw.depth, scaled.depth, c.depth)
		a := samples_u16(raw)
		b := samples_u16(scaled)
		mismatches := 0
		for i in 0..<len(a) {
			if u32(b[i]) != replicate_sample(u32(a[i]), c.precision, c.depth) {
				mismatches += 1
			}
		}
		testing.expectf(t, mismatches == 0, "%v: %v samples are not scaled from %v to %v bits", c.name, mismatches, c.precision, c.depth)
	}

	gray, gray_err := jpeg.load(jpg_path("ll-p12-gray"))
	defer jpeg.destroy(gray)
	testing.expectf(t, gray_err == nil && gray.channels == 3 && gray.depth == 16, "ll-p12-gray: expanded load returned %v", gray_err)
	if gray_err == nil && gray.channels == 3 {
		s := samples_u16(gray)
		ok := true
		for i := 0; i < len(s); i += 3 {
			if s[i] != s[i + 1] || s[i] != s[i + 2] {
				ok = false
			}
		}
		testing.expect(t, ok, "ll-p12-gray: expanded channels differ")
	}
}

@test
jpeg_test_dnl :: proc(t: ^testing.T) {
	for file in JPG_DNL_Files {
		data, read_err := os.read_entire_file(jpg_path(file[0]), context.allocator)
		defer delete(data)
		testing.expectf(t, read_err == nil, "%v: couldn't read: %v", file[0], read_err)
		if read_err != nil {
			continue
		}

		for kind in Stream_Kind {
			input := data
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr)
			defer compress.destroy_context(&ctx)

			img, err := jpeg.load_from_context(&ctx, JPG_RAW_OPTIONS)
			defer jpeg.destroy(img)
			if kind == .One_Byte_No_Seek {
				testing.expectf(t, err == .DNL_Requires_Seekable_Stream, "%v, %v: load returned %v", file[0], kind, err)
				continue
			}
			testing.expectf(t, err == nil, "%v, %v: load returned %v", file[0], kind, err)
			if err == nil {
				expect_matches_netpbm(t, file[0], img, file[1], 3)
			}
		}

		info, info_err := jpeg.load_from_bytes(data, {.info})
		defer jpeg.destroy(info)
		testing.expectf(t, info_err == nil && info.height == 0, "%v: info returned %v", file[0], info_err)
	}

	data, read_err := os.read_entire_file(jpg_path("ll-py-gray-dnl"), context.allocator)
	defer delete(data)
	if read_err != nil {
		return
	}
	dnl := bytes.index(data, {0xFF, 0xDC, 0x00, 0x04})
	testing.expect(t, dnl > 0, "ll-py-gray-dnl: no DNL marker")
	if dnl <= 0 {
		return
	}

	missing := slice.concatenate([][]u8{data[:dnl], data[dnl + 6:]})
	defer delete(missing)
	img, err := jpeg.load_from_bytes(missing)
	jpeg.destroy(img)
	testing.expect_value(t, err, image.Error(.Missing_DNL_Marker))

	zero := slice.clone(data)
	defer delete(zero)
	zero[dnl + 4], zero[dnl + 5] = 0, 0
	img, err = jpeg.load_from_bytes(zero)
	jpeg.destroy(img)
	testing.expect_value(t, err, image.Error(.Invalid_Image_Dimensions))

	bad_length := slice.clone(data)
	defer delete(bad_length)
	bad_length[dnl + 3] = 5
	img, err = jpeg.load_from_bytes(bad_length)
	jpeg.destroy(img)
	testing.expect_value(t, err, image.Error(.Corrupt))
}

@test
jpeg_test_gray_alpha :: proc(t: ^testing.T) {
	for name in ([]string{"dc-gray-alpha", "ll-py-ga16"}) {
		raw, raw_err := jpeg.load(jpg_path(name), {.do_not_expand_grayscale})
		defer jpeg.destroy(raw)
		testing.expectf(t, raw_err == nil && raw.channels == 2, "%v: gray + alpha load returned %v", name, raw_err)
		if raw_err != nil || raw.channels != 2 {
			continue
		}
		ga     := samples_u16(raw)
		maxval := u32(1) << u32(raw.depth) - 1
		pixels := raw.width * raw.height

		Case :: struct {
			options:     image.Options,
			channels:    int,
			premultiply: bool,
		}
		cases := []Case{
			{{},                       4, false},
			{{.alpha_drop_if_present}, 3, false},
			{{.alpha_premultiply},     4, true},
			{{.alpha_add_if_missing},  4, false},
		}
		for c in cases {
			img, err := jpeg.load(jpg_path(name), c.options)
			defer jpeg.destroy(img)
			testing.expectf(t, err == nil && img.channels == c.channels && img.depth == raw.depth, "%v, %v: load returned %v", name, c.options, err)
			if err != nil || img.channels != c.channels {
				continue
			}
			s := samples_u16(img)
			mismatches := 0
			for i in 0..<pixels {
				g := u32(ga[i * 2])
				a := u32(ga[i * 2 + 1])
				if c.premultiply {
					g = (g * a + maxval / 2) / maxval
				}
				p := s[i * c.channels:][:c.channels]
				if u32(p[0]) != g || u32(p[1]) != g || u32(p[2]) != g {
					mismatches += 1
				}
				if c.channels == 4 && u32(p[3]) != a {
					mismatches += 1
				}
			}
			testing.expectf(t, mismatches == 0, "%v, %v: %v pixels differ", name, c.options, mismatches)
		}
	}
}

jpeg_color_space :: proc(img: ^image.Image) -> (space: image.JPEG_Color_Space, ok: bool) {
	info := img.metadata.(^image.JPEG_Info) or_return
	return info.color_space, true
}

@test
jpeg_test_cmyk :: proc(t: ^testing.T) {
	Case :: struct {
		name:  string,
		space: image.JPEG_Color_Space,
	}
	cases := []Case{
		{"cmyk",         .YCCK},
		{"ll-py-cmyk8",  .CMYK},
		{"ll-py-cmyk12", .CMYK},
		{"ll-py-ycck8",  .YCCK},
		{"ll-py-ycck12", .YCCK},
	}
	for c in cases {
		base, base_err := jpeg.load(jpg_path(c.name))
		defer jpeg.destroy(base)
		testing.expectf(t, base_err == nil && base.channels == 4, "%v: load returned %v", c.name, base_err)
		if base_err != nil || base.channels != 4 {
			continue
		}
		space, space_ok := jpeg_color_space(base)
		testing.expectf(t, space_ok && space == c.space, "%v: color space %v (%v), expected %v", c.name, space, space_ok, c.space)

		for options in ([]image.Options{{.alpha_add_if_missing}, {.alpha_drop_if_present}, {.alpha_premultiply}, {.do_not_expand_grayscale}}) {
			img, err := jpeg.load(jpg_path(c.name), options)
			defer jpeg.destroy(img)
			testing.expectf(t, err == nil && img.channels == 4 && img.depth == base.depth, "%v, %v: load returned %v", c.name, options, err)
			if err == nil {
				testing.expectf(t, bytes.equal(img.pixels[:], base.pixels[:]), "%v, %v: pixels differ", c.name, options)
			}
		}

		info, info_err := jpeg.load(jpg_path(c.name), {.info})
		defer jpeg.destroy(info)
		testing.expectf(t, info_err == nil, "%v: info returned %v", c.name, info_err)
		if info_err == nil {
			info_space, info_ok := jpeg_color_space(info)
			testing.expectf(t, info_ok && info_space == c.space && info.channels == 4, "%v: info color space %v, %v channels", c.name, info_space, info.channels)
		}
	}

	img, err := jpeg.load(jpg_path("cmyk"))
	defer jpeg.destroy(img)
	ref, ref_err := png.load(jpg_path("cmyk", ".ref.png"), {.do_not_expand_channels})
	defer png.destroy(ref)
	testing.expectf(t, err == nil && ref_err == nil, "cmyk: load returned %v, %v", err, ref_err)
	if err != nil || ref_err != nil || img.channels != 4 || img.width != ref.width || img.height != ref.height {
		return
	}
	worst := 0
	total := 0
	pixels := img.width * img.height
	for i in 0..<pixels {
		k := int(img.pixels[i * 4 + 3])
		for ch in 0..<3 {
			v := (int(img.pixels[i * 4 + ch]) * k + 127) / 255
			difference := abs(v - int(ref.pixels[i * ref.channels + ch]))
			worst  = max(worst, difference)
			total += difference
		}
	}
	mean := f64(total) / f64(pixels * 3)
	testing.expectf(t, worst <= JPG_REFERENCE_MAX_DIFFERENCE, "cmyk: maximum difference from the RGB reference is %v", worst)
	testing.expectf(t, mean <= JPG_REFERENCE_MAX_MEAN, "cmyk: mean difference from the RGB reference is %v", mean)
}

@test
jpeg_test_color_space :: proc(t: ^testing.T) {
	Case :: struct {
		name:  string,
		space: image.JPEG_Color_Space,
	}
	cases := []Case{
		{"gray",          .Gray},
		{"hl-gray16",     .Gray},
		{"ll-py-ga8",     .Gray_Alpha},
		{"baseline-420",  .YCbCr},
		{"p12-seq-420",   .YCbCr},
		{"rgb",           .RGB},
		{"ll-p16-psv1",   .RGB},
		{"hier-sub-h",    .RGB},
		{"hier-dct-h0",   .RGB},
		{"hier-dct-h2",   .YCbCr},
		{"cmyk",          .YCCK},
		{"ll-py-cmyk8",   .CMYK},
	}
	for c in cases {
		for options in ([]image.Options{{.return_metadata}, {.info}}) {
			img, err := jpeg.load(jpg_path(c.name), options)
			defer jpeg.destroy(img)
			testing.expectf(t, err == nil, "%v, %v: load returned %v", c.name, options, err)
			if err != nil {
				continue
			}
			space, ok := jpeg_color_space(img)
			testing.expectf(t, ok && space == c.space, "%v, %v: color space %v (%v), expected %v", c.name, options, space, ok, c.space)
		}
		if c.space != .CMYK && c.space != .YCCK {
			img, err := jpeg.load(jpg_path(c.name))
			defer jpeg.destroy(img)
			testing.expectf(t, err == nil && img.metadata == nil, "%v: unrequested metadata, load returned %v", c.name, err)
		}
	}
}

find_jpeg_segment :: proc(data: []u8, marker: u8) -> int {
	i := 2
	for i + 4 <= len(data) && data[i] == 0xFF {
		if data[i + 1] == marker {
			return i
		}
		if data[i + 1] == 0xDA {
			break
		}
		i += 2 + (int(data[i + 2]) << 8 | int(data[i + 3]))
	}
	return -1
}

@test
jpeg_test_lossless_errors :: proc(t: ^testing.T) {
	Patch :: struct {
		file:   string,
		marker: u8,
		offset: int,
		value:  u8,
		want:   image.Error,
	}
	patches := []Patch{
		{"ll-p12-psv1",    0xDA, 2 + 2 + 1 + 2 * 3 + 0, 0,    .Invalid_Scan_Parameters},
		{"ll-p12-psv1",    0xDA, 2 + 2 + 1 + 2 * 3 + 0, 8,    .Invalid_Scan_Parameters},
		{"ll-p12-psv1",    0xDA, 2 + 2 + 1 + 2 * 3 + 1, 1,    .Invalid_Scan_Parameters},
		{"ll-p12-psv1",    0xDA, 2 + 2 + 1 + 2 * 3 + 2, 0x10, .Invalid_Scan_Parameters},
		{"ll-p12-psv1",    0xDA, 2 + 2 + 1 + 2 * 3 + 2, 12,   .Invalid_Scan_Parameters},
		{"ll-p12-psv1",    0xC3, 2 + 2,                 1,    .Invalid_Frame_Bit_Depth_Combo},
		{"ll-p12-psv1",    0xC3, 2 + 2,                 17,   .Invalid_Frame_Bit_Depth_Combo},
		{"ll-p12-psv1",    0xC3, 2 + 2 + 1,             0x40, .Missing_Image_Data},
		{"ll-p8-gray",     0xC3, 2 + 2 + 1 + 2,         0x40, .Missing_Image_Data},
		{"ll-p12-restart", 0xDD, 2 + 2 + 1,             30,   .Invalid_Scan_Parameters},
		{"p12-seq-444",    0xC1, 1,                     0xC0, .Invalid_Frame_Bit_Depth_Combo},
		{"p12-seq-444",    0xC1, 2 + 2,                 10,   .Invalid_Frame_Bit_Depth_Combo},
	}
	for p in patches {
		data, read_err := os.read_entire_file(jpg_path(p.file), context.allocator)
		defer delete(data)
		testing.expectf(t, read_err == nil, "%v: couldn't read: %v", p.file, read_err)
		if read_err != nil {
			continue
		}
		at := find_jpeg_segment(data, p.marker)
		testing.expectf(t, at > 0, "%v: no segment %2x", p.file, p.marker)
		if at <= 0 {
			continue
		}
		data[at + p.offset] = p.value
		img, err := jpeg.load_from_bytes(data)
		jpeg.destroy(img)
		testing.expectf(t, err == p.want, "%v, segment %2x[%v] = %v: load returned %v, expected %v", p.file, p.marker, p.offset, p.value, err, p.want)
	}
}

@test
jpeg_test_hierarchical_arithmetic_errors :: proc(t: ^testing.T) {
	Patch :: struct {
		file:   string,
		marker: u8,
		offset: int,
		value:  u8,
		want:   image.Error,
	}
	patches := []Patch{
		{"hl-rgb8",         0xDE, 1,  0xEF, .Corrupt},
		{"hl-rgb8",         0xDE, 4,  1,    .Invalid_Frame_Bit_Depth_Combo},
		{"hl-rgb8",         0xC3, 1,  0xC7, .Corrupt},
		{"hl-rgb8",         0xC3, 4,  12,   .Invalid_Frame_Bit_Depth_Combo},
		{"hl-rgb8",         0xC3, 7,  0x7F, .Invalid_Image_Dimensions},
		{"hl-rgb8",         0xC7, 1,  0xC5, .Corrupt},
		{"hl-rgb8",         0xC7, 10, 9,    .Invalid_Component},
		{"hl-rgb8",         0xDF, 4,  0x22, .Corrupt},
		{"hier-sub-h",      0xC1, 1,  0xC3, .Corrupt},
		{"hier-sub-h",      0xC1, 10, 1,    .Invalid_Component},
		{"hier-sub-h",      0xC7, 13, 3,    .Invalid_Component},
		{"hier-sub-a",      0xCF, 10, 2,    .Invalid_Component},
		{"hl-sub-h",        0xC3, 1,  0xC1, .Corrupt},
		{"ll-arith-gray12", 0xCC, 5,  0x0F, .Corrupt},
		{"arith-dac-gray",  0xCC, 4,  0x20, .Corrupt},
		{"arith-dac-gray",  0xCC, 7,  0,    .Corrupt},
	}
	for p in patches {
		data, read_err := os.read_entire_file(jpg_path(p.file), context.allocator)
		defer delete(data)
		testing.expectf(t, read_err == nil, "%v: couldn't read: %v", p.file, read_err)
		if read_err != nil {
			continue
		}
		at := bytes.index(data, {0xFF, p.marker})
		testing.expectf(t, at > 0, "%v: no marker %2x", p.file, p.marker)
		if at <= 0 {
			continue
		}
		data[at + p.offset] = p.value
		img, err := jpeg.load_from_bytes(data)
		jpeg.destroy(img)
		testing.expectf(t, err == p.want, "%v, marker %2x[%v] = %v: load returned %v, expected %v", p.file, p.marker, p.offset, p.value, err, p.want)
	}

	data, read_err := os.read_entire_file(jpg_path("hl-rgb8"), context.allocator)
	defer delete(data)
	testing.expectf(t, read_err == nil, "hl-rgb8: couldn't read: %v", read_err)
	if read_err != nil {
		return
	}

	info, info_err := jpeg.load_from_bytes(data, {.info})
	defer jpeg.destroy(info)
	dims := Dims{info.width, info.height, info.channels, 0} if info != nil else {}
	testing.expectf(t, info_err == nil && dims == {41, 30, 3, 0}, "hl-rgb8: info returned %v, %v", info_err, dims)

	data[bytes.index(data, {0xFF, 0xDE}) + 1] = 0xEF
	data[bytes.index(data, {0xFF, 0xC3}) + 1] = 0xC7
	img, err := jpeg.load_from_bytes(data)
	jpeg.destroy(img)
	testing.expect_value(t, err, image.Error(.Unsupported_Frame_Type))
}
