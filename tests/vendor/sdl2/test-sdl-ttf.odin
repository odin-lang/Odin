package test_vendor_sdl2

import "core:log"
import "core:os"
import "core:testing"
import SDL "vendor:sdl2"
import TTF "vendor:sdl2/ttf"

// Links `vendor:sdl2/ttf` and prints its version as a line `VERSION SDL2_ttf <version>`. On Windows it must be the version the
// bindings were written for, and it renders some text with a system font, which only needs the SDL2_ttf DLL: FreeType is built into it.

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

	FONTS :: [?]cstring{
		"C:/Windows/Fonts/arial.ttf",
		"/System/Library/Fonts/Supplemental/Arial.ttf",
		"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
	}
	font: ^TTF.Font
	for path in FONTS {
		if os.exists(string(path)) {
			font = TTF.OpenFont(path, 24)
			if font != nil { break }
		}
	}
	if font == nil {
		log.info("no system font found, not rendering any text")
		return
	}
	defer TTF.CloseFont(font)

	surface := TTF.RenderUTF8_Blended(font, "Hello, SDL2_ttf", SDL.Color{255, 255, 255, 255})
	if testing.expectf(t, surface != nil, "could not render text: %v", TTF.GetError()) {
		testing.expect(t, surface.w > 50 && surface.h > 10, "the rendered text has a size")
		SDL.FreeSurface(surface)
	}
}
