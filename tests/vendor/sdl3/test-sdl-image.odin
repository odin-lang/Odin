package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import IMG "vendor:sdl3/image"

// Links `vendor:sdl3/image` and prints its version as a line `VERSION SDL3_image <version>`. On Windows it must be the version the
// bindings were written for. It also writes a surface to memory in the formats that SDL3_image has been able to write since 3.2, and
// reads each back, which lists the formats that work and uses the DLLs that `test.bat` copies next to the test for PNG and AVIF.
// The formats that were added in 3.4 are in test-sdl-image-34.odin, so that an older system library can still be linked here.

Format :: enum { PNG, JPG, AVIF }

// Encodes `surface` to `io` as `format`.
encode :: proc(format: Format, surface: ^SDL.Surface, io: ^SDL.IOStream) -> bool {
	switch format {
	case .PNG:  return IMG.SavePNG_IO(surface, io, false)
	case .JPG:  return IMG.SaveJPG_IO(surface, io, false, 90)
	case .AVIF: return IMG.SaveAVIF_IO(surface, io, false, 90)
	}
	return false
}

// Whether SDL3_image recognizes the data of `io` as `format`.
detect :: proc(format: Format, io: ^SDL.IOStream) -> bool {
	switch format {
	case .PNG:  return IMG.isPNG(io)
	case .JPG:  return IMG.isJPG(io)
	case .AVIF: return IMG.isAVIF(io)
	}
	return false
}

@(test)
test_sdl_image :: proc(t: ^testing.T) {
	linked := IMG.Version()
	major, minor, micro := SDL.VERSIONNUM_MAJOR(linked), SDL.VERSIONNUM_MINOR(linked), SDL.VERSIONNUM_MICRO(linked)
	log.infof("VERSION SDL3_image %v.%v.%v", major, minor, micro)
	when ODIN_OS == .Windows {
		dll      := [3]int{int(major), int(minor), int(micro)}
		bindings := [3]int{IMG.MAJOR_VERSION, IMG.MINOR_VERSION, IMG.PATCHLEVEL}
		testing.expectf(t, dll == bindings, "the SDL3_image DLL is %v but the bindings are for %v", dll, bindings)
	}

	surface := SDL.CreateSurface(16, 16, .RGBA32)
	if !testing.expect(t, surface != nil) { return }
	defer SDL.DestroySurface(surface)
	_ = SDL.FillSurfaceRect(surface, nil, 0xFF3366CC)

	working: [dynamic]Format
	defer delete(working)
	buffer: [16384]u8
	for format in Format {
		out := SDL.IOFromMem(&buffer[0], len(buffer))
		saved := encode(format, surface, out)
		size := SDL.TellIO(out)
		_ = SDL.CloseIO(out)
		if !saved || size <= 0 {
			log.infof("SDL3_image cannot write %v: %v", format, SDL.GetError())
			continue
		}

		src := SDL.IOFromConstMem(&buffer[0], uint(size))
		detected := detect(format, src)
		_ = SDL.SeekIO(src, 0, .SEEK_SET)
		decoded := IMG.Load_IO(src, true)
		if detected && decoded != nil && decoded.w == 16 && decoded.h == 16 {
			append(&working, format)
		} else {
			log.infof("SDL3_image wrote a %v but could not read it back (detected %v): %v", format, detected, SDL.GetError())
		}
		if decoded != nil { SDL.DestroySurface(decoded) }
	}
	log.infof("SDL3_image formats %v", working[:])

	// the DLLs of the optional formats are next to the test on Windows, so everything must work
	when ODIN_OS == .Windows {
		testing.expectf(t, len(working) == len(Format), "SDL3_image could only write and read %v of all %v formats, its DLLs are missing or the wrong version", working[:], len(Format))
	} else {
		testing.expect(t, len(working) > 0, "SDL3_image works with no format at all")
	}
}
