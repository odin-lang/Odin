package libc

// 7.13 Nonlocal jumps

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}
when ODIN_OS == .Windows {
	@(default_calling_convention="c")
	foreign libc {
		// 7.13.1 Save calling environment
		//
		// NOTE(dweiler): C11 requires setjmp be a macro, which means it won't
		// necessarily export a symbol named setjmp but rather _setjmp in the case
		// of musl, glibc, BSD libc, and msvcrt.
		//
		/// NOTE(dweiler): UCRT has two implementations of longjmp. One that performs
		// stack unwinding and one that doesn't. The choice of which to use depends on a
		// flag which is set inside the jmp_buf structure given to setjmp. The default
		// behavior is to unwind the stack. Within Odin, we cannot use the stack
		// unwinding version as the unwinding information isn't present. To opt-in to
		// the regular non-unwinding version we need a way to set this flag. Since the
		// location of the flag within the struct is not defined or part of the ABI and
		// can change between versions of UCRT, we must rely on setjmp to set it. It
		// turns out that setjmp receives this flag in the RDX register on Win64, this
		// just so happens to coincide with the second argument of a function in the
		// Win64 ABI. By giving our setjmp a second argument with the value of zero,
		// the RDX register will contain zero and correctly set the flag to disable
		// stack unwinding.
		@(link_name="_setjmp")
		setjmp :: proc(env: ^jmp_buf, hack: rawptr = nil) -> int ---
	}
} else {
	@(default_calling_convention="c")
	foreign libc {
		// 7.13.1 Save calling environment
		@(link_name=LSETJMP)
		setjmp :: proc(env: ^jmp_buf) -> int ---
	}
}

@(default_calling_convention="c")
foreign libc {
	// 7.13.2 Restore calling environment
	@(link_name=LLONGJMP)
	longjmp :: proc(env: ^jmp_buf, val: int) -> ! ---
}

// The C99 Rationale describes jmp_buf as being an array type for backward
// compatibility. Odin does not need to honor this and couldn't as arrays in
// Odin don't decay to pointers. It is somewhat easy for us to bind this, we
// just need to ensure the structure contains enough storage with appropriate
// alignment. Since there are no types in C with an alignment larger than
// that of max_align_t, which cannot be larger than sizeof(long double) as any
// other exposed type wouldn't be valid C, the maximum alignment possible in a
// strictly conformant C implementation is 16 on the platforms we care about.
// The choice of 4096 bytes for storage of this type is more than enough on all
// relevant platforms.
jmp_buf :: struct #align(16) { _: [4096]char, }

when ODIN_OS == .NetBSD {
	@(private) LSETJMP  :: "__setjmp14"
	@(private) LLONGJMP :: "__longjmp14"
} else {
	@(private) LSETJMP  :: "setjmp"
	@(private) LLONGJMP :: "longjmp"
}
