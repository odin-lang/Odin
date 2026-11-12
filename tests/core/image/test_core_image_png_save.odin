package test_core_image

import "core:bytes"
import "core:compress/deflate"
import "core:image"
import "core:image/png"
import "core:testing"

@(test)
png_save_matrix :: proc(t: ^testing.T) {
	levels := [?]deflate.Deflate_Level{.Stored, .Level_1, .Default, .Best}
	widths := [?]int{1, 2, 3, 17}

	for channels in 1..=4 {
		for depth in ([?]int{8, 16}) {
			for width in widths {
				img := png_save_test_image(width, 13, channels, depth)
				defer delete(img.pixels)

				for filter in png.Filter_Strategy {
					for level in levels {
						expect_png_save_roundtrip(t, &img, level, filter)
					}
				}
			}
		}
	}
}

@(test)
png_save_invalid :: proc(t: ^testing.T) {
	buf: [dynamic]u8
	defer delete(buf)

	img := png_save_test_image(4, 4, 3, 8)
	defer delete(img.pixels)

	testing.expect_value(t, png.save(&buf, nil), image.Error(.Invalid_Input_Image))
	testing.expect_value(t, png.save(nil, &img), image.Error(.Invalid_Output))

	bad := img
	bad.width = 0
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Image_Dimensions))

	bad = img
	bad.height = 0
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Image_Dimensions))

	bad = img
	bad.channels = 0
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Number_Of_Channels))

	bad = img
	bad.channels = 5
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Number_Of_Channels))

	bad = img
	bad.depth = 1
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Image_Depth))

	bad = img
	bad.depth = 32
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Image_Depth))

	bad = img
	bad.width = 5
	testing.expect_value(t, png.save(&buf, &bad), image.Error(.Invalid_Input_Image))

	testing.expect_value(t, png.save(&buf, &img, filter = png.Filter_Strategy(6)), image.Error(.Unsupported_Option))
}

png_save_test_image :: proc(width, height, channels, depth: int) -> (img: image.Image) {
	img = image.Image{width = width, height = height, channels = channels, depth = depth}
	resize(&img.pixels, width * height * channels * depth / 8)

	seed := u32(0x9e3779b9)
	for y in 0..<height {
		for x in 0..<width {
			for c in 0..<channels {
				seed = seed * 1664525 + 1013904223
				v := u32(x * 7 + y * 13 + c * 61 + (x * y) >> 2) + (seed >> 29)
				i := (y * width + x) * channels + c
				if depth == 16 {
					(^u16)(&img.pixels[2 * i])^ = u16(v * 257 + (seed >> 16))
				} else {
					img.pixels[i] = u8(v)
				}
			}
		}
	}
	return
}

expect_png_save_roundtrip :: proc(t: ^testing.T, img: ^image.Image, level: deflate.Deflate_Level, filter: png.Filter_Strategy, loc := #caller_location) {
	buf: [dynamic]u8
	defer delete(buf)

	save_err := png.save(&buf, img, {}, level, filter)
	testing.expectf(t, save_err == nil, "%vx%vx%v@%v %v %v: save failed with %v", img.width, img.height, img.channels, img.depth, level, filter, save_err, loc=loc)
	if save_err != nil {
		return
	}

	out, load_err := png.load(buf[:], {.do_not_expand_channels})
	defer png.destroy(out)
	testing.expectf(t, load_err == nil, "%vx%vx%v@%v %v %v: load failed with %v", img.width, img.height, img.channels, img.depth, level, filter, load_err, loc=loc)
	if load_err != nil {
		return
	}

	same := out.width == img.width && out.height == img.height && out.channels == img.channels && out.depth == img.depth && bytes.equal(out.pixels[:], img.pixels[:])
	testing.expectf(t, same, "%vx%vx%v@%v %v %v: round trip mismatch, got %vx%vx%v@%v", img.width, img.height, img.channels, img.depth, level, filter, out.width, out.height, out.channels, out.depth, loc=loc)

	expect_stream_loads(t, "png_save", buf[:], png_context_loader, {.do_not_expand_channels}, out, load_err, loc=loc)
}
