package test_vendor_sdl2

import "core:log"
import "core:testing"
import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

// Links `vendor:sdl2/image` and prints its version as a line `VERSION SDL2_image <version>`. On Windows it must be the version
// the bindings were written for, and initializing the image formats loads the libraries that SDL2_image needs for them, which are
// the DLLs that `test.bat` copies next to the test. It also encodes and decodes a PNG and a JPG, which SDL2_image does without any DLLs.

@(test)
test_sdl_image :: proc(t: ^testing.T) {
	linked := IMG.Linked_Version()
	log.infof("VERSION SDL2_image %v.%v.%v", linked.major, linked.minor, linked.patch)
	when ODIN_OS == .Windows {
		dll      := [3]int{int(linked.major), int(linked.minor), int(linked.patch)}
		bindings := [3]int{IMG.MAJOR_VERSION, IMG.MINOR_VERSION, IMG.PATCHLEVEL}
		testing.expectf(t, dll == bindings, "the SDL2_image DLL is %v but the bindings are for %v", dll, bindings)
	}

	wanted := IMG.InitFlags{.JPG, .PNG, .TIF, .WEBP}
	got := IMG.Init(wanted)
	defer IMG.Quit()
	log.infof("SDL2_image formats %v", got)
	when ODIN_OS == .Windows {
		testing.expectf(t, got == wanted, "SDL2_image could only initialize %v of %v, its DLLs are missing or the wrong version", got, wanted)
	}

	// Write a surface to memory as a PNG and as a JPG, and read both back.
	surface := SDL.CreateRGBSurfaceWithFormat(0, 16, 16, 32, u32(SDL.PixelFormatEnum.RGBA32))
	if !testing.expect(t, surface != nil) { return }
	defer SDL.FreeSurface(surface)
	_ = SDL.FillRect(surface, nil, 0xFF3366CC)

	buffer: [8192]u8
	for format in ([?]string{"PNG", "JPG"}) {
		out := SDL.RWFromMem(&buffer[0], len(buffer))
		saved := IMG.SavePNG_RW(surface, out, false) if format == "PNG" else IMG.SaveJPG_RW(surface, out, false, 90)
		size := SDL.RWtell(out)
		SDL.RWclose(out)
		if !testing.expectf(t, saved == 0 && size > 0, "could not encode a %v: %v", format, SDL.GetError()) { continue }

		src := SDL.RWFromConstMem(&buffer[0], i32(size))
		testing.expectf(t, bool(IMG.isPNG(src)) == (format == "PNG"), "the encoded data is not detected as a %v", format)
		_ = SDL.RWseek(src, 0, SDL.SEEK_SET)
		decoded := IMG.Load_RW(src, true)
		if testing.expectf(t, decoded != nil, "could not decode the %v: %v", format, SDL.GetError()) {
			testing.expect_value(t, decoded.w, 16)
			testing.expect_value(t, decoded.h, 16)
			SDL.FreeSurface(decoded)
		}
	}
}
