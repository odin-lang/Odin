package libc

// 7.22 General utilities

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

@(require)
import "base:runtime"

when ODIN_OS == .Windows {
	RAND_MAX :: 0x7fff

	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		___mb_cur_max_func :: proc() -> int ---
	}

	MB_CUR_MAX :: #force_inline proc() -> size_t {
		return size_t(___mb_cur_max_func())
	}
}

when ODIN_OS == .Linux {
	RAND_MAX :: 0x7fffffff

	// GLIBC and MUSL only
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		__ctype_get_mb_cur_max :: proc() -> size_t ---
	}

	MB_CUR_MAX :: #force_inline proc() -> size_t {
		return size_t(__ctype_get_mb_cur_max())
	}
}


when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {
	RAND_MAX :: 0x7fffffff

	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		___mb_cur_max :: proc() -> int ---
	}

	MB_CUR_MAX :: #force_inline proc() -> size_t {
		return size_t(___mb_cur_max())
	}
}

when ODIN_OS == .NetBSD {
	RAND_MAX :: 0x7fffffff

	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		__mb_cur_max: size_t
	}

	MB_CUR_MAX :: #force_inline proc() -> size_t {
		return __mb_cur_max
	}
}

// C does not declare what these values should be, as an implementation is free
// to use any two distinct values it wants to indicate success or failure.
// However, nobody actually does and everyone appears to have agreed upon these
// values.
EXIT_SUCCESS :: 0
EXIT_FAILURE :: 1

// C does not declare which order 'quot' and 'rem' should be for the divide
// structures. An implementation could put 'rem' first. However, nobody actually
// does and everyone appears to have agreed upon this layout.
div_t   :: struct { quot, rem: int, }
ldiv_t  :: struct { quot, rem: long, }
lldiv_t :: struct { quot, rem: longlong, }

@(default_calling_convention="c")
foreign libc {
	// 7.22.1 Numeric conversion functions
	atof          :: proc(nptr: cstring) -> double ---
	atoi          :: proc(nptr: cstring) -> int ---
	atol          :: proc(nptr: cstring) -> long ---
	atoll         :: proc(nptr: cstring) -> longlong ---
	strtod        :: proc(nptr: cstring, endptr: ^[^]char) -> double ---
	strtof        :: proc(nptr: cstring, endptr: ^[^]char) -> float ---
	strtol        :: proc(nptr: cstring, endptr: ^[^]char, base: int) -> long ---
	strtoll       :: proc(nptr: cstring, endptr: ^[^]char, base: int) -> longlong ---
	strtoul       :: proc(nptr: cstring, endptr: ^[^]char, base: int) -> ulong ---
	strtoull      :: proc(nptr: cstring, endptr: ^[^]char, base: int) -> ulonglong ---

	// 7.22.2 Pseudo-random sequence generation functions
	rand          :: proc() -> int ---
	srand         :: proc(seed: uint) ---

	// 7.22.3 Memory management functions
	calloc        :: proc(nmemb, size: size_t) -> rawptr ---
	free          :: proc(ptr: rawptr) ---
	malloc        :: proc(size: size_t) -> rawptr ---
	realloc       :: proc(ptr: rawptr, size: size_t) -> rawptr ---

	// 7.22.4 Communication with the environment
	abort         :: proc() -> ! ---
	atexit        :: proc(func: proc "c" ()) -> int ---
	at_quick_exit :: proc(func: proc "c" ()) -> int ---
	exit          :: proc(status: int) -> ! ---
	_Exit         :: proc(status: int) -> ! ---
	getenv        :: proc(name: cstring) -> cstring ---
	quick_exit    :: proc(status: int) -> ! ---
	system        :: proc(cmd: cstring) -> int ---

	// 7.22.5 Searching and sorting utilities
	bsearch       :: proc(key, base: rawptr, nmemb, size: size_t, compar: proc "c" (lhs, rhs: rawptr) -> int) -> rawptr ---
	qsort         :: proc(base: rawptr, nmemb, size: size_t, compar: proc "c" (lhs, rhs: rawptr) -> int) ---

	// 7.22.6 Integer arithmetic functions
	abs           :: proc(j: int) -> int ---
	labs          :: proc(j: long) -> long ---
	llabs         :: proc(j: longlong) -> longlong ---
	div           :: proc(numer, denom: int) -> div_t ---
	ldiv          :: proc(numer, denom: long) -> ldiv_t ---
	lldiv         :: proc(numer, denom: longlong) -> lldiv_t ---

	// 7.22.7 Multibyte/wide character conversion functions
	mblen         :: proc(s: cstring, n: size_t) -> int ---
	mbtowc        :: proc(pwc: ^wchar_t, s: cstring, n: size_t) -> int ---
	wctomb        :: proc(s: [^]char, wc: wchar_t) -> int ---

	// 7.22.8 Multibyte/wide string conversion functions
	mbstowcs      :: proc(pwcs: ^wchar_t, s: cstring, n: size_t) -> size_t ---
	wcstombs      :: proc(s: [^]char, pwcs: ^wchar_t, n: size_t) -> size_t ---
}


aligned_alloc :: #force_inline proc "c" (alignment, size: size_t) -> rawptr {
	when ODIN_OS == .Windows {
		foreign libc {
			_aligned_malloc :: proc(size, alignment: size_t) -> rawptr ---
		}
		return _aligned_malloc(size=size, alignment=alignment)
	} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
		context = runtime.default_context()
		data, _ := runtime.mem_alloc_bytes(auto_cast size, auto_cast alignment)
		return raw_data(data)
	} else {
		foreign libc {
			aligned_alloc :: proc(alignment, size: size_t) -> rawptr ---
		}
		return aligned_alloc(alignment=alignment, size=size)
	}
}


aligned_free :: #force_inline proc "c" (ptr: rawptr) {
	when ODIN_OS == .Windows {
		foreign libc {
			_aligned_free :: proc(ptr: rawptr) ---
		}
		_aligned_free(ptr)
	} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
		context = runtime.default_context()
		runtime.mem_free(ptr)
	} else {
		free(ptr)
	}
}
