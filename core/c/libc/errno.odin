package libc

// 7.5 Errors

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// C11 standard only requires the definition of:
//	EDOM,
//	EILSEQ
//	ERANGE
when ODIN_OS == .Linux {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="__errno_location")
		_get_errno :: proc() -> ^int ---
	}

	EDOM   :: 33
	EILSEQ :: 84
	ERANGE :: 34
}

when ODIN_OS == .FreeBSD {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="__error")
		_get_errno :: proc() -> ^int ---
	}

	EDOM   :: 33
	EILSEQ :: 84
	ERANGE :: 34
}

when ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="__errno")
		_get_errno :: proc() -> ^int ---
	}

	EDOM   :: 33
	EILSEQ :: 84
	ERANGE :: 34
}

when ODIN_OS == .Windows {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="_errno")
		_get_errno :: proc() -> ^int ---
	}

	EDOM   :: 33
	EILSEQ :: 42
	ERANGE :: 34
}

when ODIN_OS == .Darwin {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="__error")
		_get_errno :: proc() -> ^int ---
	}

	// Unknown
	EDOM   :: 33
	EILSEQ :: 92
	ERANGE :: 34
}

when ODIN_OS == .Haiku {
	@(private="file")
	@(default_calling_convention="c")
	foreign libc {
		@(link_name="_errnop")
		_get_errno :: proc() -> ^int ---
	}

	@(private="file")
	B_GENERAL_ERROR_BASE :: min(i32)
	@(private="file")
	B_POSIX_ERROR_BASE   :: B_GENERAL_ERROR_BASE + 0x7000

	EDOM   :: B_POSIX_ERROR_BASE + 16
	EILSEQ :: B_POSIX_ERROR_BASE + 38
	ERANGE :: B_POSIX_ERROR_BASE + 17
}

// Odin has no way to make an identifier "errno" behave as a function call to
// read the value, or to produce an lvalue such that you can assign a different
// error value to errno. To work around this, just expose it as a function like
// it actually is.
errno :: #force_inline proc "contextless" () -> ^int {
	return _get_errno()
}
