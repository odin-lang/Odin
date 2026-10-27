package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import TTF "vendor:sdl3/ttf"

// Links `vendor:sdl3/ttf` and prints its version as a line `VERSION SDL3_ttf <version>`, and those of FreeType and HarfBuzz that it
// is built with. On Windows it must be the version the bindings were written for.

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
	TTF.Quit()
}
