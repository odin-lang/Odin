package libc

// 7.13 Nonlocal jumps

when ODIN_OS == "windows" {
	foreign import libc "system:libucrt.lib"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
	// 7.13.1 Save calling environment
	//
	// NOTE(dweiler): C11 requires setjmp be a macro, which means it won't
	// necessarily export a symbol named setjmp but rather _setjmp in the case
	// of musl, glibc, BSD libc, and msvcrt.
	@(link_name="_setjmp")
	setjmp  :: proc(env: ^jmp_buf) -> int ---;

	// 7.13.2 Restore calling environment
	longjmp :: proc(env: ^jmp_buf, val: int) -> ! ---;
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
jmp_buf :: struct #align 16 { _: [4096]char, };
