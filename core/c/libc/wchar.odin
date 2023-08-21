package libc

// 7.29 Extended multibyte and wide character utilities

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
	// 7.29.2 Formatted wide character input/output functions
	fwprintf  :: proc(stream: ^FILE, format: [^]wchar_t, #c_vararg arg: ..any) -> int ---
	fwscanf   :: proc(stream: ^FILE, format: [^]wchar_t, #c_vararg arg: ..any) -> int ---
	swprintf  :: proc(stream: ^FILE, n: size_t, format: [^]wchar_t, #c_vararg arg: ..any) -> int ---
	swscanf   :: proc(s, format: [^]wchar_t, #c_vararg arg: ..any) -> int ---
	vfwprintf :: proc(stream: ^FILE, format: [^]wchar_t, arg: va_list) -> int ---
	vfwscanf  :: proc(stream: ^FILE, format: [^]wchar_t, arg: va_list) -> int ---
	vswprintf :: proc(s: [^]wchar_t, n: size_t, format: [^]wchar_t, arg: va_list) -> int ---
	vswscanf  :: proc(s, format: [^]wchar_t, arg: va_list) -> int ---
	vwprintf  :: proc(format: [^]wchar_t, arg: va_list) -> int ---
	vwscanf   :: proc(format: [^]wchar_t, arg: va_list) -> int ---
	wprintf   :: proc(format: [^]wchar_t, #c_vararg arg: ..any) -> int ---
	wscanf    :: proc(format: [^]wchar_t, #c_vararg arg: ..any) -> int ---

	// 7.29.3 Wide character input/output functions
	fwgetc    :: proc(stream: ^FILE) -> wint_t ---
	fgetws    :: proc(s: [^]wchar_t, n: int, stream: ^FILE) -> wchar_t ---
	fputwc    :: proc(c: wchar_t, stream: ^FILE) -> wint_t ---
	fputws    :: proc(s: [^]wchar_t, stream: ^FILE) -> int ---
	fwide     :: proc(stream: ^FILE, mode: int) -> int ---
	getwc     :: proc(stream: ^FILE) -> wint_t ---
	getwchar  :: proc() -> wint_t ---
	putwc     :: proc(c: wchar_t, stream: ^FILE) -> wint_t ---
	putwchar  :: proc(c: wchar_t) -> wint_t ---
	ungetwc   :: proc(c: wchar_t, stream: ^FILE) -> wint_t ---

	// 7.29.4 General wide string utilities
	wcstod    :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t) -> double ---
	wcstof    :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t) -> float ---
	wcstol    :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t, base: int) -> long ---
	wcstoll   :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t, base: int) -> longlong ---
	wcstoul   :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t, base: int) -> ulong ---
	wcstoull  :: proc(nptr: [^]wchar_t, endptr: ^[^]wchar_t, base: int) -> ulonglong ---

	// 7.29.4.2 Wide string copying functions
	wcscpy    :: proc(s1, s2: [^]wchar_t) -> [^]wchar_t ---
	wcsncpy   :: proc(s1, s2: [^]wchar_t, n: size_t) -> [^]wchar_t ---
	wmemcpy   :: proc(s1, s2: [^]wchar_t, n: size_t) -> [^]wchar_t ---
	wmemmove  :: proc(s1, s2: [^]wchar_t, n: size_t) -> [^]wchar_t ---

	// 7.29.4.3 Wide string concatenation functions
	wcscat    :: proc(s1, s2: [^]wchar_t) -> [^]wchar_t ---
	wcsncat   :: proc(s1, s2: [^]wchar_t, n: size_t) -> [^]wchar_t ---

	// 7.29.4.4 Wide string comparison functions
	wcscmp    :: proc(s1, s2: [^]wchar_t) -> int ---
	wcscoll   :: proc(s1, s2: [^]wchar_t) -> int ---
	wcsncmp   :: proc(s1, s2: [^]wchar_t, n: size_t) -> int ---
	wcsxfrm   :: proc(s1, s2: [^]wchar_t, n: size_t) -> size_t ---
	wmemcmp   :: proc(s1, s2: [^]wchar_t, n: size_t) -> int ---

	// 7.29.4.5 Wide string search functions
	wcschr    :: proc(s: [^]wchar_t, c: wchar_t) -> [^]wchar_t ---
	wcscspn   :: proc(s1, s2: [^]wchar_t) -> size_t ---
	wcspbrk   :: proc(s1, s2: [^]wchar_t) -> [^]wchar_t ---
	wcsrchr   :: proc(s: [^]wchar_t, c: wchar_t) -> [^]wchar_t ---
	wcsspn    :: proc(s1, s2: [^]wchar_t) -> size_t ---
	wcsstr    :: proc(s1, s2: [^]wchar_t) -> [^]wchar_t ---
	wcstok    :: proc(s1, s2: [^]wchar_t, ptr: ^[^]wchar_t) -> [^]wchar_t ---
	wmemchr   :: proc(s: [^]wchar_t, c: wchar_t, n: size_t) -> [^]wchar_t ---

	// 7.29.4.6 Miscellaneous functions
	wcslen    :: proc(s: [^]wchar_t) -> size_t ---
	wmemset   :: proc(s: [^]wchar_t, c: wchar_t, n: size_t) -> [^]wchar_t ---

	// 7.29.5 Wide character time conversion functions
	wcsftime  :: proc(s: [^]wchar_t, maxsize: size_t, format: [^]wchar_t, timeptr: ^tm) -> size_t ---

	// 7.29.6.1 Single-byte/wide character conversion functions
	btowc     :: proc(c: int) -> wint_t ---
	wctob     :: proc(c: wint_t) -> int ---

	// 7.29.6.2 Conversion state functions
	mbsinit   :: proc(ps: ^mbstate_t) -> int ---

	// 7.29.6.3 Restartable multibyte/wide character conversion functions
	mbrlen    :: proc(s: cstring, n: size_t, ps: ^mbstate_t) -> size_t ---
	mbrtowc   :: proc(pwc: [^]wchar_t, s: cstring, n: size_t, ps: ^mbstate_t) -> size_t ---
	wcrtomb   :: proc(s: ^char, wc: wchar_t, ps: ^mbstate_t) -> size_t ---

	// 7.29.6.4 Restartable multibyte/wide string conversion functions
	mbsrtowcs :: proc(dst: [^]wchar_t, src: ^cstring, len: size_t, ps: ^mbstate_t) -> size_t ---
	wcsrtombs :: proc(dst: ^char, src: ^[^]wchar_t, len: size_t, ps: ^mbstate_t) -> size_t ---
}

// Large enough and aligned enough for any wide-spread in-use libc.
mbstate_t :: struct #align(16) { _: [32]char, }

// Odin does not have default argument promotion so the need for a separate type
// here isn't necessary, though make it distinct just to be safe.
wint_t    :: distinct wchar_t

// Calculate these values correctly regardless of what type wchar_t actually is.
WINT_MIN  :: 0
WINT_MAX  :: 1 << (size_of(wint_t) * 8)
WEOF      :: ~wint_t(0)
