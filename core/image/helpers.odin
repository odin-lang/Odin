package image

/*
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

import "core:mem"
import "core:slice"

// Function to help with image buffer calculations
compute_buffer_size :: proc(width, height, channels, depth: int, extra_row_bytes := int(0)) -> (size: int) {
	size = ((((channels * width * depth) + 7) >> 3) + extra_row_bytes) * height
	return
}

// Take a slice of pixels (`[]RGBA_Pixel`, etc), and return an `Image`
// Don't call `destroy` on the resulting `Image`. Instead, delete the original `pixels` slice.
pixels_to_image :: proc(pixels: [][$N]$E, width: int, height: int) -> (img: Image, ok: bool) where E == u8 || E == u16, N >= 1, N <= 4 {
	if len(pixels) != width * height {
		return {}, false
	}

	img.height   = height
	img.width    = width
	img.depth    = 8 when E == u8 else 16
	img.channels = N

	s := transmute(mem.Raw_Slice)pixels
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = s.len * size_of(E) * N,
		cap  = s.len * size_of(E) * N,
		allocator = mem.nil_allocator(),
	}
	img.pixels = transmute([dynamic]u8)d

	return img, true
}

to_gray :: proc(img: ^Image) -> (pixels: []G_Pixel, ok: bool) {
	return reinterpret_pixels(img, G_Pixel)
}

to_gray16 :: proc(img: ^Image) -> (pixels: []G_Pixel_16, ok: bool) {
	return reinterpret_pixels(img, G_Pixel_16)
}

to_ga :: proc(img: ^Image) -> (pixels: []GA_Pixel, ok: bool) {
	return reinterpret_pixels(img, GA_Pixel)
}

to_ga16 :: proc(img: ^Image) -> (pixels: []GA_Pixel_16, ok: bool) {
	return reinterpret_pixels(img, GA_Pixel_16)
}

to_rgb :: proc(img: ^Image) -> (pixels: []RGB_Pixel, ok: bool) {
	return reinterpret_pixels(img, RGB_Pixel)
}

to_rgb16 :: proc(img: ^Image) -> (pixels: []RGB_Pixel_16, ok: bool) {
	return reinterpret_pixels(img, RGB_Pixel_16)
}

to_rgba :: proc(img: ^Image) -> (pixels: []RGBA_Pixel, ok: bool) {
	return reinterpret_pixels(img, RGBA_Pixel)
}

to_rgba16 :: proc(img: ^Image) -> (pixels: []RGBA_Pixel_16, ok: bool) {
	return reinterpret_pixels(img, RGBA_Pixel_16)
}

@(private)
reinterpret_pixels :: proc(img: ^Image, $T: typeid/[$N]$E) -> (pixels: []T, ok: bool) {
	if img == nil || img.channels != N || img.depth != 8 * size_of(E) || img.width < 0 || img.height < 0 {
		return nil, false
	}
	if len(img.pixels) != compute_buffer_size(img.width, img.height, N, 8 * size_of(E)) {
		return nil, false
	}
	return slice.reinterpret([]T, img.pixels[:]), true
}

// When you have an RGB(A) image, but want a particular channel.
return_single_channel :: proc(img: ^Image, channel: Channel) -> (res: ^Image, ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return nil, false
	}

	ok = false
	t: [dynamic]u8

	idx := int(channel)

	if img.channels == 2 && idx == 4 {
		// Alpha requested, which in a two channel image is index 2: G.
		idx = 2
	}

	if idx > img.channels {
		return {}, false
	}

	switch img.depth {
	case 8:
		buffer_size := compute_buffer_size(img.width, img.height, 1, 8)
		t = [dynamic]u8{}
		resize(&t, buffer_size)

		i := img.pixels[:]
		o := t[:]

		for len(i) > 0 {
			o[0] = i[idx - 1]
			i = i[img.channels:]
			o = o[1:]
		}
	case 16:
		buffer_size := compute_buffer_size(img.width, img.height, 1, 16)
		t = [dynamic]u8{}
		resize(&t, buffer_size)

		i := mem.slice_data_cast([]u16, img.pixels[:])
		o := mem.slice_data_cast([]u16, t[:])

		for len(i) > 0 {
			o[0] = i[idx - 1]
			i = i[img.channels:]
			o = o[1:]
		}
	case 1, 2, 4:
		// We shouldn't see this case, as the loader already turns these into 8-bit.
		return {}, false
	}

	res = new(Image)
	res.width         = img.width
	res.height        = img.height
	res.channels      = 1
	res.depth         = img.depth
	res.pixels        = t
	res.background    = img.background
	res.metadata      = img.metadata

	return res, true
}

// Does the image have 1 or 2 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_grayscale_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	// Are we a Gray or Gray + Alpha image?
	if img.channels != 1 && img.channels != 2 {
		return false
	}

	// Do we have an acceptable bit depth?
	if img.depth != 8 && img.depth != 16 {
		return false
	}

	// This returns 0 if any of the inputs is zero.
	bytes_expected := compute_buffer_size(img.width, img.height, img.channels, img.depth)

	// If the dimensions are invalid or the buffer size doesn't match the image characteristics, bail.
	if bytes_expected == 0 || bytes_expected != len(img.pixels) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	return true
}

// Does the image have 3 or 4 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_color_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	// Are we an RGB or RGBA image?
	if img.channels != 3 && img.channels != 4 {
		return false
	}

	// Do we have an acceptable bit depth?
	if img.depth != 8 && img.depth != 16 {
		return false
	}

	// This returns 0 if any of the inputs is zero.
	bytes_expected := compute_buffer_size(img.width, img.height, img.channels, img.depth)

	// If the dimensions are invalid or the buffer size doesn't match the image characteristics, bail.
	if bytes_expected == 0 || bytes_expected != len(img.pixels) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	return true
}

// Does the image have 1..4 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	return is_valid_color_image(img) || is_valid_grayscale_image(img)
}

/*
	Add alpha channel if missing, in-place.

	Expects 1..4 channels (Gray, Gray + Alpha, RGB, RGBA).
	Any other number of channels will be considered an error, returning `false` without modifying the image.
	If the input image already has an alpha channel, it'll return `true` early (without considering optional keyed alpha).

	If an image doesn't already have an alpha channel:
	If the optional `alpha_key` is provided, it will be resolved as follows:
		- For RGB,  if pix = key.rgb -> pix = {0, 0, 0, key.a}
		- For Gray, if pix = key.r  -> pix = {0, key.g}
	Otherwise, an opaque alpha channel will be added.
*/
alpha_add_if_missing :: proc(img: ^Image, alpha_key := Alpha_Key{}, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_image(img) {
		return false
	}

	// We should now have a valid Image with 1..4 channels. Do we already have alpha?
	if img.channels == 2 || img.channels == 4 {
		// We're done.
		return true
	}

	channels     := img.channels + 1
	bytes_wanted := compute_buffer_size(img.width, img.height, channels, img.depth)

	buf := [dynamic]u8{}

	// Can we allocate the return buffer?
	if resize(&buf, bytes_wanted) != nil {
		delete(buf)
		return false
	}

	switch img.depth {
	case 8:
		switch channels {
		case 2:
			// Turn Gray into Gray + Alpha
			inp := mem.slice_data_cast([]G_Pixel,  img.pixels[:])
			out := mem.slice_data_cast([]GA_Pixel, buf[:])

			if key, key_ok := alpha_key.(GA_Pixel); key_ok {
				// We have keyed alpha.
				o: GA_Pixel
				for p in inp {
					if p.r == key.r {
						o = GA_Pixel{0, key.g}
					} else {
						o = GA_Pixel{p.r, 255}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := GA_Pixel{0, 255}
				for p in inp {
					o.r    = p.r
					out[0] = o
					out = out[1:]
				}
			}

		case 4:
			// Turn RGB into RGBA
			inp := mem.slice_data_cast([]RGB_Pixel,  img.pixels[:])
			out := mem.slice_data_cast([]RGBA_Pixel, buf[:])

			if key, key_ok := alpha_key.(RGBA_Pixel); key_ok {
				// We have keyed alpha.
				o: RGBA_Pixel
				for p in inp {
					if p == key.rgb {
						o = RGBA_Pixel{0, 0, 0, key.a}
					} else {
						o = RGBA_Pixel{p.r, p.g, p.b, 255}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := RGBA_Pixel{0, 0, 0, 255}
				for p in inp {
					o.rgb  = p
					out[0] = o
					out = out[1:]
				}
			}
		case:
			// We shouldn't get here.
			unreachable()
		}
	case 16:
		switch channels {
		case 2:
			// Turn Gray into Gray + Alpha
			inp := mem.slice_data_cast([]G_Pixel_16,  img.pixels[:])
			out := mem.slice_data_cast([]GA_Pixel_16, buf[:])

			if key, key_ok := alpha_key.(GA_Pixel_16); key_ok {
				// We have keyed alpha.
				o: GA_Pixel_16
				for p in inp {
					if p.r == key.r {
						o = GA_Pixel_16{0, key.g}
					} else {
						o = GA_Pixel_16{p.r, 65535}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := GA_Pixel_16{0, 65535}
				for p in inp {
					o.r    = p.r
					out[0] = o
					out = out[1:]
				}
			}

		case 4:
			// Turn RGB into RGBA
			inp := mem.slice_data_cast([]RGB_Pixel_16,  img.pixels[:])
			out := mem.slice_data_cast([]RGBA_Pixel_16, buf[:])

			if key, key_ok := alpha_key.(RGBA_Pixel_16); key_ok {
				// We have keyed alpha.
				o: RGBA_Pixel_16
				for p in inp {
					if p == key.rgb {
						o = RGBA_Pixel_16{0, 0, 0, key.a}
					} else {
						o = RGBA_Pixel_16{p.r, p.g, p.b, 65535}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := RGBA_Pixel_16{0, 0, 0, 65535}
				for p in inp {
					o.rgb  = p
					out[0] = o
					out = out[1:]
				}
			}
		case:
			// We shouldn't get here.
			unreachable()
		}
	}

	// If we got here, that means we've now got a buffer with the alpha channel added.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	delete(img.pixels)
	img.pixels   = buf
	img.channels = channels
	return true
}
alpha_apply_keyed_alpha :: alpha_add_if_missing

/*
	Drop alpha channel if present, in-place.

	Expects 1..4 channels (Gray, Gray + Alpha, RGB, RGBA).
	Any other number of channels will be considered an error, returning `false` without modifying the image.

	Of the `options`, the following are considered:
	`.alpha_premultiply`
		If the image has an alpha channel, returns image data as follows:
			RGB *= A, Gray = Gray *= A

	`.blend_background`
		If `img.background` is set, it'll be blended in like this:
			RGB = (1 - A) * Background + A * RGB

	If an image has 1 (Gray) or 3 (RGB) channels, it'll return early without modifying the image,
	with one exception: `alpha_key` and `img.background` are present, and `.blend_background` is set.

	In this case a keyed alpha pixel will be replaced with the background color.
*/
alpha_drop_if_present :: proc(img: ^Image, options := Options{}, alpha_key := Alpha_Key{}, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_image(img) {
		return false
	}

	// Do we have a background to blend?
	will_it_blend := false
	switch v in img.background {
	case RGB_Pixel_16: will_it_blend = true if .blend_background in options else false
	}

	// Do we have keyed alpha?
	keyed := false
	switch v in alpha_key {
	case GA_Pixel:      keyed = true if img.channels == 1 && img.depth ==  8 else false
	case RGBA_Pixel:    keyed = true if img.channels == 3 && img.depth ==  8 else false
	case GA_Pixel_16:   keyed = true if img.channels == 1 && img.depth == 16 else false
	case RGBA_Pixel_16: keyed = true if img.channels == 3 && img.depth == 16 else false
	}

	// We should now have a valid Image with 1..4 channels. Do we have alpha?
	if img.channels == 1 || img.channels == 3 {
		if !(will_it_blend && keyed) {
			// We're done
			return true
		}
	}

	// # of destination channels
	channels := 1 if img.channels < 3 else 3

	bytes_wanted := compute_buffer_size(img.width, img.height, channels, img.depth)
	buf := [dynamic]u8{}

	// Can we allocate the return buffer?
	if resize(&buf, bytes_wanted) != nil {
		delete(buf)
		return false
	}

	switch img.depth {
	case 8:
		switch img.channels {
		case 1: // Gray to Gray, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]G_Pixel, img.pixels[:])
			out := mem.slice_data_cast([]G_Pixel, buf[:])

			key := alpha_key.(GA_Pixel).r
			bg  := G_Pixel{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, take just the red channel's topmost byte.
				bg.r = u8(temp_bg.r >> 8)
			}

			for p in inp {
				out[0] = bg if p.r == key else p
				out    = out[1:]
			}

		case 2: // Gray + Alpha to Gray, no keyed alpha but we can have a background.
			inp := mem.slice_data_cast([]GA_Pixel, img.pixels[:])
			out := mem.slice_data_cast([]G_Pixel,  buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg  := f32(0.0)
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel's topmost byte.
					bg = f32(temp_bg.r >> 8)
				}

				for p in inp {
					a := f32(p.g) / 255.0
					c := ((1.0 - a) * bg + a * f32(p.r))
					out[0].r = u8(c)
					out      = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a := f32(p.g) / 255.0
					c := f32(p.r) * a
					out[0].r = u8(c)
					out      = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0].r = p.r
					out      = out[1:]
				}
			}

		case 3: // RGB to RGB, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]RGB_Pixel, img.pixels[:])
			out := mem.slice_data_cast([]RGB_Pixel, buf[:])

			key := alpha_key.(RGBA_Pixel)
			bg  := RGB_Pixel{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, squash down to 8 bits.
				bg = {u8(temp_bg.r >> 8), u8(temp_bg.g >> 8), u8(temp_bg.b >> 8)}
			}

			for p in inp {
				out[0] = bg if p == key.rgb else p
				out    = out[1:]
			}

		case 4: // RGBA to RGB, no keyed alpha but we can have a background or need to premultiply.
			inp := mem.slice_data_cast([]RGBA_Pixel, img.pixels[:])
			out := mem.slice_data_cast([]RGB_Pixel,  buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg := [3]f32{}
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel's topmost byte.
					bg = {f32(temp_bg.r >> 8), f32(temp_bg.g >> 8), f32(temp_bg.b >> 8)}
				}

				for p in inp {
					a   := f32(p.a) / 255.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := ((1.0 - a) * bg + a * rgb)

					out[0] = {u8(c.r), u8(c.g), u8(c.b)}
					out    = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a   := f32(p.a) / 255.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := rgb * a

					out[0] = {u8(c.r), u8(c.g), u8(c.b)}
					out    = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0] = p.rgb
					out    = out[1:]
				}
			}
		}

	case 16:
		switch img.channels {
		case 1: // Gray to Gray, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]G_Pixel_16, img.pixels[:])
			out := mem.slice_data_cast([]G_Pixel_16, buf[:])

			key := alpha_key.(GA_Pixel_16).r
			bg  := G_Pixel_16{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, take just the red channel.
				bg.r = temp_bg.r
			}

			for p in inp {
				out[0] = bg if p.r == key else p
				out    = out[1:]
			}

		case 2: // Gray + Alpha to Gray, no keyed alpha but we can have a background.
			inp := mem.slice_data_cast([]GA_Pixel_16, img.pixels[:])
			out := mem.slice_data_cast([]G_Pixel_16,  buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg  := f32(0.0)
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel.
					bg = f32(temp_bg.r)
				}

				for p in inp {
					a := f32(p.g) / 65535.0
					c := ((1.0 - a) * bg + a * f32(p.r))
					out[0].r = u16(c)
					out      = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a := f32(p.g) / 65535.0
					c := f32(p.r) * a
					out[0].r = u16(c)
					out      = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0].r = p.r
					out      = out[1:]
				}
			}

		case 3: // RGB to RGB, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]RGB_Pixel_16, img.pixels[:])
			out := mem.slice_data_cast([]RGB_Pixel_16, buf[:])

			key := alpha_key.(RGBA_Pixel_16)
			bg  := img.background.(RGB_Pixel_16)

			for p in inp {
				out[0] = bg if p == key.rgb else p
				out    = out[1:]
			}

		case 4: // RGBA to RGB, no keyed alpha but we can have a background or need to premultiply.
			inp := mem.slice_data_cast([]RGBA_Pixel_16, img.pixels[:])
			out := mem.slice_data_cast([]RGB_Pixel_16,  buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg := [3]f32{}
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, convert to [3]f32 to blend.
					bg = {f32(temp_bg.r), f32(temp_bg.g), f32(temp_bg.b)}
				}

				for p in inp {
					a   := f32(p.a) / 65535.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := ((1.0 - a) * bg + a * rgb)

					out[0] = {u16(c.r), u16(c.g), u16(c.b)}
					out    = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a   := f32(p.a) / 65535.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := rgb * a

					out[0] = {u16(c.r), u16(c.g), u16(c.b)}
					out    = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0] = p.rgb
					out    = out[1:]
				}
			}
		}

	case:
		unreachable()
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	delete(img.pixels)
	img.pixels   = buf
	img.channels = channels
	return true
}

// Apply palette to 8-bit single-channel image and return an 8-bit RGB image, in-place.
// If the image given is not a valid 8-bit single channel image, the procedure will return `false` early.
apply_palette_rgb :: proc(img: ^Image, palette: [256]RGB_Pixel, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if img == nil || img.channels != 1 || img.depth != 8 {
		return false
	}

	bytes_expected := compute_buffer_size(img.width, img.height, 1, 8)
	if bytes_expected == 0 || bytes_expected != len(img.pixels) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	// Can we allocate the return buffer?
	buf := [dynamic]u8{}
	bytes_wanted := compute_buffer_size(img.width, img.height, 3, 8)
	if resize(&buf, bytes_wanted) != nil {
		delete(buf)
		return false
	}

	out := mem.slice_data_cast([]RGB_Pixel, buf[:])

	// Apply the palette
	for p, i in img.pixels {
		out[i] = palette[p]
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	delete(img.pixels)
	img.pixels   = buf
	img.channels = 3
	return true
}

// Apply palette to 8-bit single-channel image and return an 8-bit RGBA image, in-place.
// If the image given is not a valid 8-bit single channel image, the procedure will return `false` early.
apply_palette_rgba :: proc(img: ^Image, palette: [256]RGBA_Pixel, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if img == nil || img.channels != 1 || img.depth != 8 {
		return false
	}

	bytes_expected := compute_buffer_size(img.width, img.height, 1, 8)
	if bytes_expected == 0 || bytes_expected != len(img.pixels) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	// Can we allocate the return buffer?
	buf := [dynamic]u8{}
	bytes_wanted := compute_buffer_size(img.width, img.height, 4, 8)
	if resize(&buf, bytes_wanted) != nil {
		delete(buf)
		return false
	}

	out := mem.slice_data_cast([]RGBA_Pixel, buf[:])

	// Apply the palette
	for p, i in img.pixels {
		out[i] = palette[p]
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	delete(img.pixels)
	img.pixels   = buf
	img.channels = 4
	return true
}
apply_palette :: proc{apply_palette_rgb, apply_palette_rgba}

blend_single_channel :: #force_inline proc(fg, alpha, bg: $T) -> (res: T) where T == u8 || T == u16 {
	when T == u8 {
		return T((u32(fg) * (1 + u32(alpha)) + u32(bg) * (256 - u32(alpha))) >> 8)
	} else {
		return T((u64(fg) * (1 + u64(alpha)) + u64(bg) * (65536 - u64(alpha))) >> 16)
	}
}

blend_pixel :: #force_inline proc(fg: [$N]$T, alpha: T, bg: [N]T) -> (res: [N]T) where (T == u8 || T == u16), N >= 1, N <= 4 {
	when N == 4 {
		for i in 0..<3 {
			res[i] = blend_single_channel(fg[i], alpha, bg[i])
		}
		res[3] = max(T)
	} else {
		for i in 0..<N {
			res[i] = blend_single_channel(fg[i], alpha, bg[i])
		}
	}
	return
}
blend :: proc{blend_single_channel, blend_pixel}

// For all pixels of the image, multiplies R, G and B by Alpha. This is useful mainly for games rendering anti-aliased transparent sprites.
// Grayscale with alpha images are supported as well.
// Note that some image formats like QOI explicitly do NOT support premultiplied alpha, so you will end up with a non-standard file.
premultiply_alpha :: proc(img: ^Image) -> (ok: bool) {
	switch {
	case img.channels == 2 && img.depth == 8:
		pixels := mem.slice_data_cast([]GA_Pixel, img.pixels[:])
		for &pixel in pixels {
			pixel.r = u8(u32(pixel.r) * u32(pixel.g) / 0xFF)
		}
		return true
	case img.channels == 2 && img.depth == 16:
		pixels := mem.slice_data_cast([]GA_Pixel_16, img.pixels[:])
		for &pixel in pixels {
			pixel.r = u16(u32(pixel.r) * u32(pixel.g) / 0xFFFF)
		}
		return true
	case img.channels == 4 && img.depth == 8:
		pixels := mem.slice_data_cast([]RGBA_Pixel, img.pixels[:])
		for &pixel in pixels {
			pixel.r = u8(u32(pixel.r) * u32(pixel.a) / 0xFF)
			pixel.g = u8(u32(pixel.g) * u32(pixel.a) / 0xFF)
			pixel.b = u8(u32(pixel.b) * u32(pixel.a) / 0xFF)
		}
		return true
	case img.channels == 4 && img.depth == 16:
		pixels := mem.slice_data_cast([]RGBA_Pixel_16, img.pixels[:])
		for &pixel in pixels {
			pixel.r = u16(u32(pixel.r) * u32(pixel.a) / 0xFFFF)
			pixel.g = u16(u32(pixel.g) * u32(pixel.a) / 0xFFFF)
			pixel.b = u16(u32(pixel.b) * u32(pixel.a) / 0xFFFF)
		}
		return true
	case: return false
	}
}

// Replicates grayscale values into RGB(A) 8- or 16-bit images as appropriate.
// Returns early with `false` if already an RGB(A) image.
expand_grayscale :: proc(img: ^Image, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_grayscale_image(img) {
		return false
	}

	// We should have 1 or 2 channels of 8- or 16 bits now. We need to turn that into 3 or 4.
	// Can we allocate the return buffer?
	buf := [dynamic]u8{}
	bytes_wanted := compute_buffer_size(img.width, img.height, img.channels + 2, img.depth)
	if resize(&buf, bytes_wanted) != nil {
		delete(buf)
		return false
	}

	switch img.depth {
	case 8:
		switch img.channels {
		case 1: // Turn Gray into RGB
			out := mem.slice_data_cast([]RGB_Pixel, buf[:])

			for p in img.pixels {
				out[0] = p // Broadcast gray value into RGB components.
				out    = out[1:]
			}

		case 2: // Turn Gray + Alpha into RGBA
			inp := mem.slice_data_cast([]GA_Pixel,   img.pixels[:])
			out := mem.slice_data_cast([]RGBA_Pixel, buf[:])

			for p in inp {
				out[0].rgb = p.r // Gray component.
				out[0].a   = p.g // Alpha component.
				out    = out[1:]
			}

		case:
			unreachable()
		}

	case 16:
		switch img.channels {
		case 1: // Turn Gray into RGB
			inp := mem.slice_data_cast([]u16, img.pixels[:])
			out := mem.slice_data_cast([]RGB_Pixel_16, buf[:])

			for p in inp {
				out[0] = p // Broadcast gray value into RGB components.
				out    = out[1:]
			}

		case 2: // Turn Gray + Alpha into RGBA
			inp := mem.slice_data_cast([]GA_Pixel_16,   img.pixels[:])
			out := mem.slice_data_cast([]RGBA_Pixel_16, buf[:])

			for p in inp {
				out[0].rgb = p.r // Gray component.
				out[0].a   = p.g // Alpha component.
				out    = out[1:]
			}

		case:
			unreachable()
		}

	case:
		unreachable()
	}


	// If we got here, that means we've now got a buffer with the extra alpha channel.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	delete(img.pixels)
	img.pixels   = buf
	img.channels += 2
	return true
}
