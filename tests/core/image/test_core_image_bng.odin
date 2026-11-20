package test_core_image

import "core:bytes"
import "core:compress"
import "core:image"
import "core:image/bng"
import "core:image/png"
import "core:os"
import "core:strings"
import "core:testing"

BNG_KAT_WIDTH  :: 16
BNG_KAT_HEIGHT :: 6

BNG_KAT := []u8{
	0xFF, 0x0E, 0x38, 0x30, 0x2A, 0x1A, 0x18, 0x01, 0x10, 0x00, 0x00, 0x00,
	0x06, 0x00, 0x00, 0x00, 0x85, 0x00, 0x00, 0x00, 0xE0, 0x11, 0x20, 0x92,
	0x0F, 0x0C, 0x09, 0x20, 0x9E, 0x78, 0x88, 0x88, 0x88, 0x8E, 0x02, 0xC4,
	0x44, 0x44, 0x70, 0xED, 0x3A, 0x74, 0xE9, 0xFE, 0xB3, 0xA7, 0x4E, 0x97,
	0xA2, 0xA6, 0xA4, 0x1A, 0x9F, 0x41, 0x24, 0xC1, 0x24, 0x92, 0x49, 0x24,
	0x20, 0x82, 0x08, 0x20, 0x82, 0x0B, 0x94, 0xF5, 0xFD, 0x06, 0xA6, 0xA4,
	0x1A, 0x9F, 0x41, 0x24, 0x12, 0x49, 0x24, 0x92, 0x4A, 0x08, 0x20, 0x82,
	0x28, 0x20, 0xBD, 0x1C, 0xA7, 0xAF, 0xE8, 0x06, 0xA7, 0x44, 0xD4, 0x92,
	0x41, 0x24, 0x92, 0x49, 0x24, 0x84, 0x10, 0x41, 0x04, 0x10, 0x41, 0x72,
	0x9E, 0xBF, 0xA2, 0x86, 0xA7, 0x44, 0xFA, 0x09, 0x30, 0x49, 0x24, 0x92,
	0x49, 0x28, 0x20, 0x82, 0x08, 0xA0, 0x82, 0xF4, 0x72, 0x9E, 0xBF, 0xA2,
	0xA6, 0xA4, 0x1A, 0x9F, 0x41, 0x20, 0x92, 0x49, 0x24, 0x92, 0x48, 0x41,
	0x04, 0x10, 0x41, 0x04, 0x17, 0x29, 0xEB, 0xFA, 0x00,
}

bng_kat_pixel :: proc(x, y: int) -> image.RGBA_Pixel {
	return {
		u8(x * 3 + y),
		128,
		200 if x > 8 else 10,
		255 if x < 12 else u8(255 - y * 20),
	}
}

bng_make_image :: proc(width, height, channels: int, pattern: int) -> (img: image.Image) {
	img = image.Image{width = width, height = height, channels = channels, depth = 8}
	resize(&img.pixels, width * height * channels)
	state := u32(0x2545_F491)
	for y in 0..<height {
		for x in 0..<width {
			for c in 0..<channels {
				v: u8
				switch pattern {
				case 0:
					v = u8(x * (c + 1) + y * (3 - c))
				case 1:
					state ~= state << 13
					state ~= state >> 17
					state ~= state << 5
					v = u8(state >> 24)
				case 2:
					v = 77 if x == width - 1 && y == height - 1 else 9
				case:
					v = u8((x / 7 + y / 5) * 40) if c < 3 else u8(x * 255 / max(width - 1, 1))
				}
				img.pixels[(y * width + x) * channels + c] = v
			}
		}
	}
	if channels == 4 {
		for i := 0; i < len(img.pixels); i += 4 {
			a := u32(img.pixels[i + 3])
			for c in 0..<3 {
				img.pixels[i + c] = u8((u32(img.pixels[i + c]) * a + 127) / 255)
			}
		}
	}
	return
}

@test
bng_test_known_answer :: proc(t: ^testing.T) {
	img, err := bng.load(BNG_KAT)
	defer bng.destroy(img)
	testing.expect_value(t, err, nil)
	if err != nil {
		return
	}
	testing.expect_value(t, img.width, BNG_KAT_WIDTH)
	testing.expect_value(t, img.height, BNG_KAT_HEIGHT)
	testing.expect_value(t, img.channels, 4)
	testing.expect_value(t, img.which, image.Which_File_Type.BNG)

	pixels := transmute([]image.RGBA_Pixel)img.pixels[:]
	for y in 0..<BNG_KAT_HEIGHT {
		for x in 0..<BNG_KAT_WIDTH {
			testing.expectf(t, pixels[y * BNG_KAT_WIDTH + x] == bng_kat_pixel(x, y), "pixel %v,%v: %v", x, y, pixels[y * BNG_KAT_WIDTH + x])
		}
	}

	out: [dynamic]u8
	defer delete(out)
	testing.expect_value(t, bng.save_to_buffer(&out, img), nil)
	testing.expect(t, string(out[:]) == string(BNG_KAT), "re-encoded KAT differs from the reference encoder")
}

@test
bng_test_round_trip :: proc(t: ^testing.T) {
	Case :: struct {
		width, height, channels, pattern: int,
		raw: bool,
	}
	cases := []Case{
		{1,    1,  4, 0, true},
		{1,    1,  3, 1, true},
		{1,    37, 4, 3, true},
		{37,   1,  4, 3, false},
		{17,   13, 4, 0, false},
		{17,   13, 3, 0, false},
		{64,   64, 4, 1, true},
		{64,   64, 4, 3, false},
		{9000, 2,  4, 2, false},
		{8193, 3,  3, 2, false},
	}
	for c in cases {
		src := bng_make_image(c.width, c.height, c.channels, c.pattern)
		defer delete(src.pixels)

		out: [dynamic]u8
		defer delete(out)
		err := bng.save_to_buffer(&out, &src)
		testing.expectf(t, err == nil, "%v: save error %v", c, err)
		if err != nil {
			continue
		}

		is_raw := len(out) >= 20 && out[19] & 0x80 != 0
		testing.expectf(t, is_raw == c.raw, "%v: raw body %v", c, is_raw)
		if is_raw {
			testing.expectf(t, len(out) == 20 + 4 * c.width * c.height, "%v: raw length %v", c, len(out))
		}

		option_sets := []bng.Options{bng.Default_Options, bng.Default_Options + {.alpha_drop_if_present}, {}, {.alpha_drop_if_present}}
		if c.channels == 4 {
			option_sets = option_sets[:2]
		}
		for options in option_sets {
			img, load_err := bng.load(out[:], options)
			testing.expectf(t, load_err == nil, "%v %v: load error %v", c, options, load_err)
			if load_err == nil {
				channels := 3 if .alpha_drop_if_present in options else 4
				testing.expectf(t, img.channels == channels, "%v %v: channels %v", c, options, img.channels)
				same := len(img.pixels) == channels * c.width * c.height
				for i := 0; same && i < c.width * c.height; i += 1 {
					for ch in 0..<channels {
						expected := u8(255)
						if ch < c.channels {
							expected = src.pixels[i * c.channels + ch]
						}
						if img.pixels[i * channels + ch] != expected {
							same = false
						}
					}
				}
				testing.expectf(t, same, "%v %v: pixels differ", c, options)
			}
			bng.destroy(img)
		}
	}
}

@test
bng_test_straight_alpha :: proc(t: ^testing.T) {
	src := bng_make_image(31, 9, 4, 1)
	defer delete(src.pixels)

	out: [dynamic]u8
	defer delete(out)
	testing.expect_value(t, bng.save_to_buffer(&out, &src), nil)

	straight, err := bng.load(out[:], {})
	defer bng.destroy(straight)
	testing.expect_value(t, err, nil)
	if err != nil {
		return
	}

	premultiplied, premultiplied_err := bng.load(out[:])
	defer bng.destroy(premultiplied)
	testing.expect_value(t, premultiplied_err, nil)
	if premultiplied_err != nil {
		return
	}

	for i := 0; i < len(src.pixels); i += 4 {
		a := u32(src.pixels[i + 3])
		testing.expect_value(t, straight.pixels[i + 3], src.pixels[i + 3])
		for c in 0..<3 {
			expected := src.pixels[i + c]
			testing.expectf(t, premultiplied.pixels[i + c] == expected, "byte %v: %v, expected %v", i + c, premultiplied.pixels[i + c], expected)
			again := u8((u32(straight.pixels[i + c]) * a + 127) / 255)
			testing.expectf(t, again == expected, "byte %v: straight %v does not premultiply back to %v", i + c, straight.pixels[i + c], expected)
		}
	}
}

@test
bng_test_back_to_back :: proc(t: ^testing.T) {
	stream: [dynamic]u8
	defer delete(stream)
	append(&stream, ..BNG_KAT)
	append(&stream, ..BNG_KAT)
	append(&stream, 0xAB, 0xCD)

	data := stream[:]
	ctx  := compress.init_context_from_slice(&data)
	for _ in 0..<2 {
		img, err := bng.load_from_context(&ctx)
		testing.expect_value(t, err, nil)
		if err == nil {
			testing.expect_value(t, img.width, BNG_KAT_WIDTH)
		}
		bng.destroy(img)
	}
	testing.expect_value(t, len(ctx.window), 2)
}

@test
bng_test_info :: proc(t: ^testing.T) {
	img, err := bng.load(BNG_KAT, {.info})
	defer bng.destroy(img)
	testing.expect_value(t, err, nil)
	if err != nil {
		return
	}
	testing.expect_value(t, len(img.pixels), 0)
	info, ok := img.metadata.(^image.BNG_Info)
	testing.expect(t, ok, "missing BNG_Info")
	if ok {
		testing.expect_value(t, u32(info.header.stream_byte_count), u32(len(BNG_KAT) - 20))
	}
}

@test
bng_test_invalid :: proc(t: ^testing.T) {
	Case :: struct {
		offset: int,
		value:  u8,
		length: int,
		err:    image.Error,
	}
	cases := []Case{
		{0,  0x00, -1, image.General_Image_Error.Invalid_Signature},
		{7,  0x02, -1, image.BNG_Error.Unsupported_Version},
		{8,  0x00, -1, image.General_Image_Error.Invalid_Image_Dimensions},
		{15, 0x40, -1, image.General_Image_Error.Image_Dimensions_Too_Large},
		{19, 0x80, -1, image.BNG_Error.Invalid_Raw_Body_Length},
		{16, 0x86, -1, image.BNG_Error.Body_Length_Exceeds_Input},
		{0,  0xFF, 19, nil},
	}
	for c in cases {
		data := make([]u8, len(BNG_KAT))
		defer delete(data)
		copy(data, BNG_KAT)
		if c.offset == 8 {
			data[8] = 0
			data[9] = 0
			data[10] = 0
			data[11] = 0
		} else {
			data[c.offset] = c.value
		}
		input := data[:c.length] if c.length >= 0 else data[:]

		img, err := bng.load(input)
		bng.destroy(img)
		if c.err == nil {
			testing.expectf(t, err != nil, "%v: expected an error", c)
		} else {
			testing.expectf(t, err == c.err, "%v: got %v", c, err)
		}
	}

	truncated := make([]u8, 20 + 1)
	defer delete(truncated)
	copy(truncated, BNG_KAT[:20])
	truncated[12] = 100
	truncated[16] = 1
	img, err := bng.load(truncated)
	bng.destroy(img)
	testing.expect_value(t, err, image.Error(image.BNG_Error.Body_Ends_Too_Early))
}

bng_corruption_inputs :: proc(t: ^testing.T) -> (inputs: [3][]u8) {
	inputs[0] = make([]u8, len(BNG_KAT))
	copy(inputs[0], BNG_KAT)

	for pattern, i in ([2]int{3, 1}) {
		src := bng_make_image(37, 23, 4, pattern)
		defer delete(src.pixels)
		out: [dynamic]u8
		testing.expect_value(t, bng.save_to_buffer(&out, &src), nil)
		inputs[i + 1] = out[:]
	}
	raw := image.BNG_Raw_Flag & (^u32le)(&inputs[1][16])^
	testing.expect(t, raw == 0, "pattern 3 should produce a coded body")
	raw  = image.BNG_Raw_Flag & (^u32le)(&inputs[2][16])^
	testing.expect(t, raw != 0, "pattern 1 should produce a raw body")
	return
}

@test
bng_test_truncated :: proc(t: ^testing.T) {
	inputs := bng_corruption_inputs(t)
	defer for input in inputs {
		delete(input)
	}

	for data, i in inputs {
		for n in 0..<len(data) {
			for kind in Stream_Kind {
				input := data[:n]
				br: bytes.Reader
				tr: Trickle_Reader
				ctx := stream_test_context(kind, &input, &br, &tr)
				img, err := bng.load_from_context(&ctx)
				bng.destroy(img)
				compress.destroy_context(&ctx)
				testing.expectf(t, err != nil, "input %v, %v: truncated to %v of %v bytes loaded without error", i, kind, n, len(data))
			}
		}
	}
}

@test
bng_test_bit_flips :: proc(t: ^testing.T) {
	inputs := bng_corruption_inputs(t)
	defer for input in inputs {
		delete(input)
	}

	for data, i in inputs[:2] {
		width  := int((^u32le)(&data[8])^)
		height := int((^u32le)(&data[12])^)

		flipped := make([]u8, len(data))
		defer delete(flipped)

		for bit in 8 * size_of(image.BNG_Header)..<8 * len(data) {
			copy(flipped, data)
			flipped[bit >> 3] ~= u8(1) << uint(bit & 7)
			for options in ([]image.Options{bng.Default_Options, {}, {.alpha_drop_if_present}}) {
				img, err := bng.load_from_bytes(flipped, options)
				if err == nil {
					testing.expectf(t, img.width == width && img.height == height && len(img.pixels) == img.channels * width * height,
						"input %v, bit %v, %v: loaded %vx%v with %v bytes", i, bit, options, img.width, img.height, len(img.pixels))
				}
				bng.destroy(img)
			}
		}
	}
}

Bng_Bit_Builder :: struct {
	body:  [dynamic]u8,
	acc:   u8,
	count: uint,
	codes: [bng.TOKEN_COUNT]u32,
}

bng_builder_init :: proc(b: ^Bng_Bit_Builder) {
	code := u32(0)
	for length in u8(1)..=bng.MAX_CODE_LENGTH {
		for token in 0..<bng.TOKEN_COUNT {
			if bng.CODE_LENGTHS[token] == length {
				b.codes[token] = code
				code += 1
			}
		}
		code <<= 1
	}
}

bng_put_bits :: proc(b: ^Bng_Bit_Builder, value: u32, length: uint) {
	for i := int(length) - 1; i >= 0; i -= 1 {
		b.acc = b.acc << 1 | u8((value >> uint(i)) & 1)
		b.count += 1
		if b.count == 8 {
			append(&b.body, b.acc)
			b.acc   = 0
			b.count = 0
		}
	}
}

bng_put_token :: proc(b: ^Bng_Bit_Builder, token: int, mantissa := u32(0)) {
	bng_put_bits(b, b.codes[token], uint(bng.CODE_LENGTHS[token]))
	switch {
	case token >= 127 && token < bng.TOKEN_EOL:
		bng_put_bits(b, mantissa, uint(6 + (token - 127) / 2))
	case token > bng.TOKEN_EOL:
		bng_put_bits(b, mantissa, uint(token - bng.TOKEN_EOL))
	}
}

bng_build_file :: proc(b: ^Bng_Bit_Builder, width, height: int) -> (file: [dynamic]u8) {
	if b.count > 0 {
		append(&b.body, b.acc << (8 - b.count))
		b.acc   = 0
		b.count = 0
	}
	append(&file, 0xFF, 0x0E, 0x38, 0x30, 0x2A, 0x1A, 0x18, 0x01)
	for v in ([]u32{u32(width), u32(height), u32(len(b.body))}) {
		append(&file, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
	}
	append(&file, ..b.body[:])
	delete(b.body)
	return
}

bng_expect_gray_row :: proc(t: ^testing.T, file: []u8, luma: []u8, name: string) {
	img, err := bng.load(file)
	defer bng.destroy(img)
	testing.expectf(t, err == nil, "%v: load error %v", name, err)
	if err != nil {
		return
	}
	testing.expectf(t, img.width == len(luma) && img.height == 1, "%v: size %vx%v", name, img.width, img.height)
	if img.width != len(luma) {
		return
	}
	for y, x in luma {
		pixel := image.RGBA_Pixel{img.pixels[4 * x], img.pixels[4 * x + 1], img.pixels[4 * x + 2], img.pixels[4 * x + 3]}
		if pixel != {y, y, y, 0} {
			testing.expectf(t, false, "%v: pixel %v is %v, expected %v", name, x, pixel, image.RGBA_Pixel{y, y, y, 0})
			return
		}
	}
}

@test
bng_test_token_129 :: proc(t: ^testing.T) {
	b: Bng_Bit_Builder
	bng_builder_init(&b)
	bng_put_token(&b, 129, 0)
	bng_put_token(&b, 129, 127)
	for _ in 0..<3 {
		bng_put_token(&b, bng.TOKEN_EOL)
	}
	file := bng_build_file(&b, 2, 1)
	defer delete(file)
	bng_expect_gray_row(t, file[:], {128, 127}, "token 129")
}

@test
bng_test_long_zero_runs :: proc(t: ^testing.T) {
	Run :: struct {
		token:    int,
		mantissa: u32,
	}
	runs := []Run{{140, 5}, {141, 1000}, {142, 0}, {143, 4095}}

	luma: [dynamic]u8
	defer delete(luma)
	b: Bng_Bit_Builder
	bng_builder_init(&b)
	level := u8(0)
	for run in runs {
		length := (1 << uint(run.token - bng.TOKEN_EOL)) + int(run.mantissa)
		bng_put_token(&b, run.token, run.mantissa)
		for _ in 0..<length {
			append(&luma, level)
		}
		bng_put_token(&b, 1)
		level += 1
		append(&luma, level)
	}
	for _ in 0..<3 {
		bng_put_token(&b, bng.TOKEN_EOL)
	}
	file := bng_build_file(&b, len(luma), 1)
	defer delete(file)
	bng_expect_gray_row(t, file[:], luma[:], "long runs")

	clamp: Bng_Bit_Builder
	bng_builder_init(&clamp)
	bng_put_token(&clamp, 143, 0)
	for _ in 0..<3 {
		bng_put_token(&clamp, bng.TOKEN_EOL)
	}
	clamped := bng_build_file(&clamp, 600, 1)
	defer delete(clamped)
	zeros := make([]u8, 600)
	defer delete(zeros)
	bng_expect_gray_row(t, clamped[:], zeros, "run clamped to row end")
}

BNG_Reference_Files := []string{
	"pngimg-crab_PNG40",
	"pngimg-jam_PNG63",
	"pngimg-lollipop_PNG98263",
	"pngimg-peacock_PNG22",
	"tango-actions-edit-delete",
	"tango-actions-list-remove",
	"tango-apps-preferences-system-windows",
	"tango-categories-applications-internet",
	"tango-mimetypes-x-office-spreadsheet-template",
	"tango-places-network-server",
	"tecnick-RGB_OR_1200x1200_062",
	"tecnick-RGB_OR_1200x1200_100",
}

@test
bng_test_reference :: proc(t: ^testing.T) {
	for name in BNG_Reference_Files {
		bng_path := strings.concatenate({TEST_SUITE_PATH_BNG, "/", name, ".bng"}, context.temp_allocator)
		png_path := strings.concatenate({TEST_SUITE_PATH_BNG, "/", name, ".png"}, context.temp_allocator)

		file, file_err := os.read_entire_file(bng_path, context.allocator)
		testing.expectf(t, file_err == nil, "%v: couldn't read %v: %v", name, bng_path, file_err)
		if file_err != nil {
			continue
		}
		defer delete(file)

		reference, png_err := png.load(png_path, {.alpha_add_if_missing})
		defer png.destroy(reference)
		testing.expectf(t, png_err == nil, "%v: png load error %v", name, png_err)
		if png_err != nil {
			continue
		}

		premultiplied, err := bng.load(file)
		defer bng.destroy(premultiplied)
		testing.expectf(t, err == nil, "%v: load error %v", name, err)
		if err != nil {
			continue
		}

		straight, straight_err := bng.load(file, {})
		defer bng.destroy(straight)
		testing.expectf(t, straight_err == nil, "%v: straight load error %v", name, straight_err)
		if straight_err != nil {
			continue
		}

		testing.expectf(t, reference.depth == 8 && reference.channels == 4, "%v: png is %v channels, %v bits", name, reference.channels, reference.depth)
		testing.expectf(t, premultiplied.width == reference.width && premultiplied.height == reference.height, "%v: size %vx%v, png %vx%v",
			name, premultiplied.width, premultiplied.height, reference.width, reference.height)
		if len(premultiplied.pixels) != len(reference.pixels) {
			continue
		}

		mismatches := 0
		for i := 0; i < len(reference.pixels); i += 4 {
			a := u32(reference.pixels[i + 3])
			for c in 0..<4 {
				expected := reference.pixels[i + c]
				if c < 3 {
					expected = u8((u32(expected) * a + 127) / 255)
				}
				if premultiplied.pixels[i + c] != expected {
					mismatches += 1
				}
				switch {
				case a == 255 || c == 3:
					if straight.pixels[i + c] != reference.pixels[i + c] {
						mismatches += 1
					}
				case a != 0:
					if u8((u32(straight.pixels[i + c]) * a + 127) / 255) != expected {
						mismatches += 1
					}
				}
			}
		}
		testing.expectf(t, mismatches == 0, "%v: %v mismatched channel values", name, mismatches)

		out: [dynamic]u8
		defer delete(out)
		testing.expectf(t, bng.save_to_buffer(&out, premultiplied) == nil && string(out[:]) == string(file), "%v: re-encode differs from the reference encoder", name)

		generic, generic_err := image.load_from_bytes(file)
		testing.expectf(t, generic_err == nil && generic.which == .BNG, "%v: generic load %v", name, generic_err)
		image.destroy(generic)
	}
}
