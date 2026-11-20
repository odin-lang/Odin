package test_vendor_sdl3

import "core:log"
import "core:testing"
import SDL "vendor:sdl3"
import IMG "vendor:sdl3/image"

// The formats that SDL3_image has been able to write since 3.4: the same round trip as test-sdl-image.odin, in a file of its own so that
// a system library older than that fails only this test, because it lacks the functions to link, and not test-sdl-image.odin. On Windows
// WebP needs the DLL that `test.bat` copies next to the test.

Format34 :: enum { BMP, GIF, TGA, ICO, CUR, WEBP }

// Encodes `surface` to `io` as `format`.
encode34 :: proc(format: Format34, surface: ^SDL.Surface, io: ^SDL.IOStream) -> bool {
	switch format {
	case .BMP:  return IMG.SaveBMP_IO(surface, io, false)
	case .GIF:  return IMG.SaveGIF_IO(surface, io, false)
	case .TGA:  return IMG.SaveTGA_IO(surface, io, false)
	case .ICO:  return IMG.SaveICO_IO(surface, io, false)
	case .CUR:  return IMG.SaveCUR_IO(surface, io, false)
	case .WEBP: return IMG.SaveWEBP_IO(surface, io, false, 90)
	}
	return false
}

// Whether SDL3_image recognizes the data of `io` as `format`.
detect34 :: proc(format: Format34, io: ^SDL.IOStream) -> bool {
	switch format {
	case .BMP:  return IMG.isBMP(io)
	case .GIF:  return IMG.isGIF(io)
	case .TGA:  return true // TGA files have no signature to detect
	case .ICO:  return IMG.isICO(io)
	case .CUR:  return IMG.isCUR(io)
	case .WEBP: return IMG.isWEBP(io)
	}
	return false
}

@(test)
test_sdl_image_34 :: proc(t: ^testing.T) {
	surface := SDL.CreateSurface(16, 16, .RGBA32)
	if !testing.expect(t, surface != nil) { return }
	defer SDL.DestroySurface(surface)
	_ = SDL.FillSurfaceRect(surface, nil, 0xFF3366CC)

	working: [dynamic]Format34
	defer delete(working)
	buffer: [16384]u8
	for format in Format34 {
		out := SDL.IOFromMem(&buffer[0], len(buffer))
		saved := encode34(format, surface, out)
		size := SDL.TellIO(out)
		_ = SDL.CloseIO(out)
		if !saved || size <= 0 {
			log.infof("SDL3_image cannot write %v: %v", format, SDL.GetError())
			continue
		}

		src := SDL.IOFromConstMem(&buffer[0], uint(size))
		detected := detect34(format, src)
		_ = SDL.SeekIO(src, 0, .SEEK_SET)
		// TGA files have no signature, so the format has to be said
		decoded := IMG.LoadTyped_IO(src, true, "TGA") if format == .TGA else IMG.Load_IO(src, true)
		if detected && decoded != nil && decoded.w == 16 && decoded.h == 16 {
			append(&working, format)
		} else {
			log.infof("SDL3_image wrote a %v but could not read it back (detected %v): %v", format, detected, SDL.GetError())
		}
		if decoded != nil { SDL.DestroySurface(decoded) }
	}
	log.infof("SDL3_image formats since 3.4 %v", working[:])

	when ODIN_OS == .Windows {
		testing.expectf(t, len(working) == len(Format34), "SDL3_image could only write and read %v of all %v formats, its DLLs are missing or the wrong version", working[:], len(Format34))
	} else {
		testing.expect(t, len(working) > 0, "SDL3_image works with no format at all")
	}
}
