package stb_image

import c "core:c/libc"

@(private)
WRITE_LIB :: (
	     "../lib/stb_image_write.lib"      when ODIN_OS == .Windows
	else "../lib/stb_image_write.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_image_write.a" when ODIN_OS == .Darwin
	else ""
)

when WRITE_LIB != "" {
	when !#exists(WRITE_LIB) {
		// The STB libraries are shipped with the compiler on Windows so a Windows specific message should not be needed.
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}

	foreign import stbiw { WRITE_LIB }
} else {
	foreign import stbiw "system:stb_image_write"
}

write_func :: proc "c" (ctx: rawptr, data: rawptr, size: c.int)

@(default_calling_convention="c", link_prefix="stbi_")
foreign stbiw {
	write_png :: proc(filename: cstring, w, h, comp: c.int, data: rawptr, stride_in_bytes: c.int)     -> c.int ---
	write_bmp :: proc(filename: cstring, w, h, comp: c.int, data: rawptr)                             -> c.int ---
	write_tga :: proc(filename: cstring, w, h, comp: c.int, data: rawptr)                             -> c.int ---
	write_hdr :: proc(filename: cstring, w, h, comp: c.int, data: [^]f32)                             -> c.int ---
	write_jpg :: proc(filename: cstring, w, h, comp: c.int, data: rawptr, quality: c.int /*0..=100*/) -> c.int ---
	
	write_png_to_func :: proc(func: write_func, ctx: rawptr, w, h, comp: c.int, data: rawptr, stride_in_bytes: c.int)     -> c.int ---
	write_bmp_to_func :: proc(func: write_func, ctx: rawptr, w, h, comp: c.int, data: rawptr)                             -> c.int ---
	write_tga_to_func :: proc(func: write_func, ctx: rawptr, w, h, comp: c.int, data: rawptr)                             -> c.int ---
	write_hdr_to_func :: proc(func: write_func, ctx: rawptr, w, h, comp: c.int, data: [^]f32)                             -> c.int ---
	write_jpg_to_func :: proc(func: write_func, ctx: rawptr, x, y, comp: c.int, data: rawptr, quality: c.int /*0..=100*/) -> c.int ---
	
	flip_vertically_on_write :: proc(flip_boolean: b32) ---
}
