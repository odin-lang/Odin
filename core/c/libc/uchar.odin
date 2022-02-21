package libc

// 7.28 Unicode utilities

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
	// 7.28.1 Restartable multibyte/wide character conversion functions
	mbrtoc16 :: proc(pc16: [^]char16_t, s: cstring, n: size_t, ps: ^mbstate_t) -> size_t ---
	c16rtomb :: proc(s: ^char, c16: char16_t, ps: ^mbstate_t) -> size_t ---
	mbrtoc32 :: proc(pc32: [^]char32_t, s: cstring, n: size_t, ps: ^mbstate_t) -> size_t ---
	c32rtomb :: proc(s: ^char, c32: char32_t, ps: ^mbstate_t) -> size_t ---
}

char16_t :: uint_least16_t
char32_t :: uint_least32_t
