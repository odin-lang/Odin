package test_vendor_stb

import "core:log"
import "core:os"
import "core:testing"
import stbtt "vendor:stb/truetype"

NOTO_SANS :: ODIN_ROOT + "tests/core/assets/Fonts/NotoSans-Regular.ttf"

load_noto_sans :: proc(t: ^testing.T, info: ^stbtt.fontinfo) -> (ok: bool) {
	data, err := os.read_entire_file(NOTO_SANS, context.temp_allocator)
	if !testing.expectf(t, err == nil, "could not read %v, run tests/core/download_assets.py to fetch the test assets", NOTO_SANS) {
		return
	}
	testing.expect_value(t, stbtt.GetNumberOfFonts(raw_data(data)), 1)
	return testing.expect(t, bool(stbtt.InitFont(info, raw_data(data), 0)), "Noto Sans did not load")
}

@(test)
test_truetype_glyph_lookup :: proc(t: ^testing.T) {
	info: stbtt.fontinfo
	if !load_noto_sans(t, &info) { return }

	a := stbtt.FindGlyphIndex(&info, 'A')
	b := stbtt.FindGlyphIndex(&info, 'B')
	testing.expect(t, a != 0 && b != 0 && a != b, "Latin letters have distinct glyphs")
	testing.expect(t, stbtt.FindGlyphIndex(&info, 0x3b1) != 0, "Greek alpha is in Noto Sans")
	testing.expect(t, stbtt.FindGlyphIndex(&info, 0x416) != 0, "Cyrillic zhe is in Noto Sans")
	testing.expect_value(t, stbtt.FindGlyphIndex(&info, 0x0e01), 0)
}

@(test)
test_truetype_metrics :: proc(t: ^testing.T) {
	info: stbtt.fontinfo
	if !load_noto_sans(t, &info) { return }

	ascent, descent, line_gap: i32
	stbtt.GetFontVMetrics(&info, &ascent, &descent, &line_gap)
	log.infof("ascent %v, descent %v, line gap %v", ascent, descent, line_gap)
	testing.expect(t, ascent > 0 && descent < 0, "ascent is above and descent is below the baseline")

	advance_i, bearing_i, advance_m, bearing_m: i32
	stbtt.GetCodepointHMetrics(&info, 'i', &advance_i, &bearing_i)
	stbtt.GetCodepointHMetrics(&info, 'm', &advance_m, &bearing_m)
	log.infof("advance of i %v, of m %v", advance_i, advance_m)
	testing.expect(t, advance_i > 0 && advance_m > advance_i, "m is wider than i")

	x0, y0, x1, y1: i32
	testing.expect(t, stbtt.GetCodepointBox(&info, 'H', &x0, &y0, &x1, &y1) != 0, "H has an outline")
	testing.expect(t, x1 > x0 && y1 > y0, "the box of H is not empty")

	scale := stbtt.ScaleForPixelHeight(&info, 32)
	testing.expect(t, scale > 0, "a positive scale")
	testing.expect(t, f32(ascent - descent) * scale > 31 && f32(ascent - descent) * scale < 33, "ascent plus descent scales to the pixel height")
}

@(test)
test_truetype_kerning :: proc(t: ^testing.T) {
	info: stbtt.fontinfo
	if !load_noto_sans(t, &info) { return }

	testing.expect_value(t, stbtt.GetCodepointKernAdvance(&info, 'A', 'V'), -40)
	testing.expect_value(t, stbtt.GetCodepointKernAdvance(&info, 'H', 'H'), 0)
}

@(test)
test_truetype_bitmap :: proc(t: ^testing.T) {
	info: stbtt.fontinfo
	if !load_noto_sans(t, &info) { return }

	scale := stbtt.ScaleForPixelHeight(&info, 48)
	w, h, xoff, yoff: i32
	bitmap := stbtt.GetCodepointBitmap(&info, scale, scale, 'A', &w, &h, &xoff, &yoff)
	if !testing.expect(t, bitmap != nil, "A rasterizes") { return }
	defer stbtt.FreeBitmap(bitmap, nil)

	log.infof("A at 48px: %vx%v, offset %v,%v", w, h, xoff, yoff)
	testing.expect(t, w > 10 && w < 60 && h > 20 && h < 60, "the bitmap of A has a plausible size")
	testing.expect(t, yoff < 0, "the glyph sits above the baseline")

	set, opaque: int
	for v in bitmap[:int(w * h)] {
		if v != 0 { set += 1 }
		if v == 255 { opaque += 1 }
	}
	testing.expect(t, set > 0 && opaque > 0, "the bitmap has coverage")
	testing.expect(t, set < int(w * h), "the bitmap is not completely filled")

	empty_w, empty_h, empty_x, empty_y: i32
	space := stbtt.GetCodepointBitmap(&info, scale, scale, ' ', &empty_w, &empty_h, &empty_x, &empty_y)
	if space != nil { stbtt.FreeBitmap(space, nil) }
	testing.expect(t, empty_w == 0 || empty_h == 0, "a space has no pixels")

	stride := int(w)
	buffer := make([]byte, int(w * h), context.temp_allocator)
	stbtt.MakeCodepointBitmap(&info, raw_data(buffer), w, h, w, scale, scale, 'A')
	for v, i in buffer {
		if v != bitmap[i] {
			testing.expectf(t, false, "MakeCodepointBitmap differs from GetCodepointBitmap at %v (stride %v)", i, stride)
			break
		}
	}
}

@(test)
test_truetype_default_name_and_width_scale :: proc(t: ^testing.T) {
	info: stbtt.fontinfo
	if !load_noto_sans(t, &info) { return }

	name: [128]u8
	n := stbtt.GetFontNameDefault(&info, raw_data(name[:]), len(name))
	testing.expect(t, n > 0 && int(n) < len(name), "the default name fits and is not empty")
	log.infof("default name: %v", string(name[:max(n, 0)]))

	position, thickness: i32
	testing.expect(t, bool(stbtt.GetFontUnderlineMetrics(&info, &position, &thickness)), "Noto Sans has a post table")
	testing.expect(t, thickness > 0, "the underline has a thickness")

	scale := stbtt.ScaleForPixelWidth(&info, 32)
	testing.expect(t, scale > 0, "a positive scale")
}
