package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import TTF "vendor:sdl3/ttf"

// Links `vendor:sdl3/ttf` and prints its version as a line `VERSION SDL3_ttf <version>`, and those of FreeType and HarfBuzz that it
// is built with. On Windows it must be the version the bindings were written for.

NOTO_SANS :: ODIN_ROOT + "tests/core/assets/Fonts/NotoSans-Regular.ttf"

@(test)
test_sdl_ttf :: proc(t: ^testing.T) {
	linked := TTF.Version()
	major, minor, micro := SDL.VERSIONNUM_MAJOR(linked), SDL.VERSIONNUM_MINOR(linked), SDL.VERSIONNUM_MICRO(linked)
	log.infof("VERSION SDL3_ttf %v.%v.%v", major, minor, micro)
	when ODIN_OS == .Windows {
		got      := [3]int{int(major), int(minor), int(micro)}
		bindings := [3]int{TTF.MAJOR_VERSION, TTF.MINOR_VERSION, TTF.PATCHLEVEL}
		testing.expectf(t, got == bindings, "the SDL3_ttf DLL is %v but the bindings are for %v", got, bindings)
	}

	// FreeType is only known once the library is initialized
	testing.expect(t, TTF.Init(), "SDL3_ttf failed to initialize")

	freetype, harfbuzz: [3]i32
	TTF.GetFreeTypeVersion(&freetype[0], &freetype[1], &freetype[2])
	TTF.GetHarfBuzzVersion(&harfbuzz[0], &harfbuzz[1], &harfbuzz[2])
	log.infof("VERSION FreeType %v.%v.%v", freetype[0], freetype[1], freetype[2])
	log.infof("VERSION HarfBuzz %v.%v.%v", harfbuzz[0], harfbuzz[1], harfbuzz[2])

	testing.expect(t, TTF.WasInit() > 0)

	font := TTF.OpenFont(NOTO_SANS, 24)
	if !testing.expectf(t, font != nil, "could not open %v, run tests/core/download_assets.py to fetch the test assets: %v", NOTO_SANS, SDL.GetError()) {
		TTF.Quit()
		return
	}
	defer TTF.Quit()
	defer TTF.CloseFont(font)

	testing.expect_value(t, string(TTF.GetFontFamilyName(font)), "Noto Sans")
	testing.expect_value(t, string(TTF.GetFontStyleName(font)), "Regular")
	testing.expect(t, !TTF.FontIsFixedWidth(font), "Noto Sans is proportional")
	testing.expect(t, TTF.GetFontHeight(font) > TTF.GetFontAscent(font), "the line is taller than the ascent")
	testing.expect(t, TTF.GetFontDescent(font) < 0, "the descent is below the baseline")

	text := "Hello, SDL3_ttf"
	surface := TTF.RenderText_Blended(font, raw_data(text), uint(len(text)), SDL.Color{255, 255, 255, 255})
	if testing.expectf(t, surface != nil, "could not render text: %v", SDL.GetError()) {
		testing.expect(t, surface.w > 50 && surface.h > 10, "the rendered text has a size")
		SDL.DestroySurface(surface)
	}

	narrow_w, wide_w, height: i32
	narrow, wide := "i", "m"
	testing.expect(t, TTF.GetStringSize(font, raw_data(narrow), 1, &narrow_w, &height), "size of i")
	testing.expect(t, TTF.GetStringSize(font, raw_data(wide), 1, &wide_w, &height), "size of m")
	testing.expect(t, narrow_w > 0 && wide_w > narrow_w, "m is wider than i")
	testing.expect_value(t, height, TTF.GetFontHeight(font))

	minx, maxx, miny, maxy, advance: i32
	testing.expect(t, TTF.GetGlyphMetrics(font, 'A', &minx, &maxx, &miny, &maxy, &advance), "metrics of A")
	testing.expect(t, maxx > minx && maxy > miny && advance > 0 && advance < 2 * (maxx - minx), "the metrics of A are consistent")
	testing.expect(t, TTF.FontHasGlyph(font, 0x3b1), "Greek alpha is in Noto Sans")
	testing.expect(t, !TTF.FontHasGlyph(font, 0x0e01), "Thai is not in Noto Sans")
}
