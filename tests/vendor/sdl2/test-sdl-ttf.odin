package test_vendor_sdl2

import "core:log"
import "core:testing"
import SDL "vendor:sdl2"
import TTF "vendor:sdl2/ttf"

// Links `vendor:sdl2/ttf` and prints its version as a line `VERSION SDL2_ttf <version>`. On Windows it must be the version the
// bindings were written for, and it renders some text using NotoSans, which only needs the SDL2_ttf DLL: FreeType is built into it.

NOTO_SANS :: ODIN_ROOT + "tests/core/assets/Fonts/NotoSans-Regular.ttf"

@(test)
test_sdl_ttf :: proc(t: ^testing.T) {
	linked := TTF.Linked_Version()
	log.infof("VERSION SDL2_ttf %v.%v.%v", linked.major, linked.minor, linked.patch)
	when ODIN_OS == .Windows {
		dll      := [3]int{int(linked.major), int(linked.minor), int(linked.patch)}
		bindings := [3]int{TTF.MAJOR_VERSION, TTF.MINOR_VERSION, TTF.PATCHLEVEL}
		testing.expectf(t, dll == bindings, "the SDL2_ttf DLL is %v but the bindings are for %v", dll, bindings)
	}

	testing.expect_value(t, TTF.Init(), 0)
	defer TTF.Quit()
	testing.expect(t, TTF.WasInit() > 0)

	// the versions of the libraries it is built with
	freetype, harfbuzz: [3]i32
	TTF.GetFreeTypeVersion(&freetype[0], &freetype[1], &freetype[2])
	TTF.GetHarfBuzzVersion(&harfbuzz[0], &harfbuzz[1], &harfbuzz[2])
	log.infof("VERSION FreeType %v.%v.%v", freetype[0], freetype[1], freetype[2])
	log.infof("VERSION HarfBuzz %v.%v.%v", harfbuzz[0], harfbuzz[1], harfbuzz[2])

	font := TTF.OpenFont(NOTO_SANS, 24)
	if !testing.expectf(t, font != nil, "could not open %v, run tests/core/download_assets.py to fetch the test assets: %v", NOTO_SANS, TTF.GetError()) {
		return
	}
	defer TTF.CloseFont(font)

	testing.expect_value(t, string(TTF.FontFaceFamilyName(font)), "Noto Sans")
	testing.expect_value(t, string(TTF.FontFaceStyleName(font)), "Regular")
	testing.expect_value(t, TTF.FontFaces(font), 1)
	testing.expect(t, bool(TTF.FontFaceIsFixedWidth(font) == 0), "Noto Sans is proportional")
	testing.expect(t, TTF.FontHeight(font) > TTF.FontAscent(font), "the line is taller than the ascent")
	testing.expect(t, TTF.FontDescent(font) < 0, "the descent is below the baseline")

	surface := TTF.RenderUTF8_Blended(font, "Hello, SDL2_ttf", SDL.Color{255, 255, 255, 255})
	if testing.expectf(t, surface != nil, "could not render text: %v", TTF.GetError()) {
		testing.expect(t, surface.w > 50 && surface.h > 10, "the rendered text has a size")
		SDL.FreeSurface(surface)
	}

	narrow_w, wide_w, height: i32
	testing.expect_value(t, TTF.SizeUTF8(font, "i", &narrow_w, &height), 0)
	testing.expect_value(t, TTF.SizeUTF8(font, "m", &wide_w, &height), 0)
	testing.expect(t, narrow_w > 0 && wide_w > narrow_w, "m is wider than i")
	testing.expect_value(t, height, TTF.FontHeight(font))

	minx, maxx, miny, maxy, advance: i32
	testing.expect_value(t, TTF.GlyphMetrics32(font, 'A', &minx, &maxx, &miny, &maxy, &advance), 0)
	testing.expect(t, maxx > minx && maxy > miny && advance > 0 && advance < 2 * (maxx - minx), "the metrics of A are consistent")
	testing.expect(t, TTF.GlyphIsProvided32(font, 0x3b1) != 0, "Greek alpha is in Noto Sans")
	testing.expect_value(t, TTF.GlyphIsProvided32(font, 0x0e01), 0)
}
