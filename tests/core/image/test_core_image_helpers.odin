package test_core_image

import "core:image"
import "core:image/png"
import "core:strings"
import "core:testing"

@(test)
image_return_single_channel :: proc(t: ^testing.T) {
	for depth in ([?]int{8, 16}) {
		for channels in 1..=4 {
			img := png_save_test_image(5, 3, channels, depth)
			defer delete(img.pixels)
			bytes_per_channel := depth / 8

			for c in image.Channel {
				src := int(c) - 1
				if channels == 2 && c == .A {
					src = 1
				}

				res, ok := image.return_single_channel(&img, c)
				testing.expectf(t, ok == (src < channels), "%vx%v %v: ok = %v", channels, depth, c, ok)
				if !ok {
					continue
				}
				defer {
					delete(res.pixels)
					free(res)
				}

				testing.expect_value(t, res.channels, 1)
				testing.expect_value(t, res.depth, depth)
				testing.expect_value(t, len(res.pixels), img.width * img.height * bytes_per_channel)

				for p in 0..<img.width * img.height {
					for b in 0..<bytes_per_channel {
						got  := res.pixels[p * bytes_per_channel + b]
						want := img.pixels[(p * channels + src) * bytes_per_channel + b]
						if got != want {
							testing.expectf(t, false, "%vx%v %v: pixel %v byte %v is %v, expected %v", channels, depth, c, p, b, got, want)
							return
						}
					}
				}
			}
		}
	}
}

@(test)
image_to_pixel_views :: proc(t: ^testing.T) {
	for depth in ([?]int{8, 16}) {
		for channels in 1..=4 {
			img := png_save_test_image(5, 3, channels, depth)
			defer delete(img.pixels)

			views: [8]bool
			_, views[0] = image.to_gray(&img)
			_, views[1] = image.to_ga(&img)
			_, views[2] = image.to_rgb(&img)
			_, views[3] = image.to_rgba(&img)
			_, views[4] = image.to_gray16(&img)
			_, views[5] = image.to_ga16(&img)
			_, views[6] = image.to_rgb16(&img)
			_, views[7] = image.to_rgba16(&img)

			want := channels - 1 + (4 if depth == 16 else 0)
			for ok, i in views {
				testing.expectf(t, ok == (i == want), "%vx%v: view %v ok = %v", channels, depth, i, ok)
			}
		}
	}

	img := png_save_test_image(5, 3, 4, 8)
	defer delete(img.pixels)

	pixels, ok := image.to_rgba(&img)
	testing.expect(t, ok)
	testing.expect_value(t, len(pixels), 15)
	testing.expect_value(t, rawptr(raw_data(pixels)), rawptr(raw_data(img.pixels)))
	testing.expect_value(t, pixels[7], image.RGBA_Pixel{img.pixels[28], img.pixels[29], img.pixels[30], img.pixels[31]})

	short := img
	short.height = 4
	_, ok = image.to_rgba(&short)
	testing.expect(t, !ok)

	_, ok = image.to_rgba(nil)
	testing.expect(t, !ok)
}

@(test)
image_blend_partial_alpha :: proc(t: ^testing.T) {
	for fg := 0; fg < 256; fg += 5 {
		for bg := 0; bg < 256; bg += 7 {
			for a in 0..<256 {
				got  := int(image.blend(u8(fg), u8(a), u8(bg)))
				want := (fg * a + bg * (255 - a)) / 255
				if abs(got - want) > 1 {
					testing.expectf(t, false, "blend(%v, %v, %v) = %v, expected %v", fg, a, bg, got, want)
					return
				}
			}
		}
	}
	for fg := 0; fg < 65536; fg += 4099 {
		for bg := 0; bg < 65536; bg += 5003 {
			for a := 0; a < 65536; a += 97 {
				got  := i64(image.blend(u16(fg), u16(a), u16(bg)))
				want := (i64(fg) * i64(a) + i64(bg) * i64(65535 - a)) / 65535
				if abs(got - want) > 1 {
					testing.expectf(t, false, "blend(%v, %v, %v) = %v, expected %v", fg, a, bg, got, want)
					return
				}
			}
		}
	}
	px := image.blend(image.RGBA_Pixel{200, 100, 0, 7}, 128, image.RGBA_Pixel{0, 100, 200, 9})
	testing.expect_value(t, px, image.RGBA_Pixel{100, 100, 100, 255})
}

@(test)
png_paletted_premultiply :: proc(t: ^testing.T) {
	for name in ([?]string{"tm3n3p02", "tbbn3p08"}) {
		file := fmt_path(name)
		defer delete(file)

		ref, ref_err := png.load(file)
		defer png.destroy(ref)
		testing.expectf(t, ref_err == nil && ref.channels == 4, "%v: reference load failed with %v", name, ref_err)
		if ref_err != nil {
			continue
		}
		rgba, _ := image.to_rgba(ref)

		partial := false
		for p in rgba {
			partial |= p.a != 0 && p.a != 255
		}

		for options in ([?]image.Options{{.alpha_premultiply}, {.alpha_premultiply, .alpha_drop_if_present}}) {
			img, err := png.load(file, options)
			defer png.destroy(img)
			testing.expectf(t, err == nil, "%v %v: load failed with %v", name, options, err)
			if err != nil {
				continue
			}
			want_channels := 3 if .alpha_drop_if_present in options else 4
			testing.expectf(t, img.channels == want_channels, "%v %v: %v channels, expected %v", name, options, img.channels, want_channels)

			for p, i in rgba {
				got: [4]u8
				if want_channels == 3 {
					px, _ := image.to_rgb(img)
					got = {px[i].r, px[i].g, px[i].b, p.a}
				} else {
					px, _ := image.to_rgba(img)
					got = px[i]
				}
				for c in 0..<3 {
					want := int(p[c]) * int(p.a) / 255
					if abs(int(got[c]) - want) > 1 || got.a != p.a {
						testing.expectf(t, false, "%v %v: pixel %v is %v, expected premultiplied %v (partial alpha: %v)", name, options, i, got, p, partial)
						return
					}
				}
			}
		}
	}
}

fmt_path :: proc(name: string) -> string {
	return strings.concatenate({TEST_SUITE_PATH_PNG, "/", name, ".png"})
}
