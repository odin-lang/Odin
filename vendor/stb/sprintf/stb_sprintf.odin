package stb_sprintf

import "core:c"

@(private)
LIB :: (
	     "../lib/stb_sprintf.lib"      when ODIN_OS == .Windows
	else "../lib/stb_sprintf.a"        when ODIN_OS == .Linux
	else "../lib/darwin/stb_sprintf.a" when ODIN_OS == .Darwin
	else "../lib/stb_sprintf_wasm.o"   when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
	else ""
)

when LIB != "" {
	when !#exists(LIB) {
		#panic("Could not find the compiled STB libraries, they can be compiled by running `make -C \"" + ODIN_ROOT + "vendor/stb/src\"`")
	}
}

when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import stbpf "../lib/stb_sprintf_wasm.o"
} else when LIB != "" {
	foreign import stbpf { LIB }
} else {
	foreign import stbpf "system:stb_sprintf"
}

@(link_prefix="stbsp_", default_calling_convention="c")
foreign stbpf {
	sprintf    :: proc(buf: [^]byte, fmt: cstring, #c_vararg args: ..any) -> i32 ---
	snprintf   :: proc(buf: [^]byte, count: i32, fmt: cstring, #c_vararg args: ..any) -> i32 ---
	vsprintf   :: proc(buf: [^]byte, fmt: cstring, va: ^c.va_list) -> i32 ---
	vsnprintf  :: proc(buf: [^]byte, count: i32, fmt: cstring, va: ^c.va_list) -> i32 ---
	vsprintfcb :: proc(callback: SPRINTFCB, user: rawptr, buf: [^]byte, fmt: cstring, va: ^c.va_list) -> i32 ---
}

SPRINTFCB :: #type proc "c" (buf: [^]byte, user: rawptr, len: i32) -> cstring
