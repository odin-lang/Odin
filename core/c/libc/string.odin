package libc

import "base:runtime"

// 7.24 String handling

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

foreign libc {
	// 7.24.2 Copying functions
	memcpy   :: proc(s1, s2: rawptr, n: size_t) -> rawptr ---
	memmove  :: proc(s1, s2: rawptr, n: size_t) -> rawptr ---
	strcpy   :: proc(s1: [^]char, s2: cstring) -> [^]char ---
	strncpy  :: proc(s1: [^]char, s2: cstring, n: size_t) -> [^]char ---

	// 7.24.3 Concatenation functions
	strcat   :: proc(s1: [^]char, s2: cstring) -> [^]char ---
	strncat  :: proc(s1: [^]char, s2: cstring, n: size_t) -> [^]char ---

	// 7.24.4 Comparison functions
	memcmp   :: proc(s1, s2: rawptr, n: size_t) -> int ---
	strcmp   :: proc(s1, s2: cstring) -> int ---
	strcoll  :: proc(s1, s2: cstring) -> int ---
	strncmp  :: proc(s1, s2: cstring, n: size_t) -> int ---
	strxfrm  :: proc(s1: [^]char, s2: cstring, n: size_t) -> size_t ---

	// 7.24.5 Search functions
	memchr   :: proc(s: rawptr, c: int, n: size_t) -> rawptr ---
	strchr   :: proc(s: cstring, c: int) -> [^]char ---
	strcspn  :: proc(s1, s2: cstring) -> size_t ---
	strpbrk  :: proc(s1, s2: cstring) -> [^]char ---
	strrchr  :: proc(s: [^]char, c: int) -> [^]char ---
	strcpn   :: proc(s1, s2: cstring) -> [^]char ---
	strtok   :: proc(s1: [^]char, s2: cstring) -> [^]char ---

	// 7.24.6 Miscellaneous functions
	strerror :: proc(errnum: int) -> cstring ---
	strlen   :: proc(s: cstring) -> size_t ---
}
memset :: proc "c" (s: rawptr, c: int, n: size_t) -> rawptr {
	return runtime.memset(s, c, auto_cast n)
}
