#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// setjmp.h - stack environment declarations

foreign lib {
	/*
	Equivalent to longjmp() but must not touch signals.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/_longjmp.html ]]
	*/
	_longjmp :: proc(env: ^jmp_buf, val: c.int) -> ! ---

	/*
	Equivalent to setjmp() but must not touch signals.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/_longjmp.html ]]
	*/
	_setjmp :: proc(env: ^jmp_buf) -> c.int ---

	/*
	Equivalent to longjmp() but restores saved signal masks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/siglongjump.html ]]
	*/
	@(link_name=LSIGLONGJMP)
	siglongjmp :: proc(env: ^sigjmp_buf, val: c.int) -> ! ---

	/*
	Equivalent to setjmp() but restores saved signal masks.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/siglongjump.html ]]
	*/
	@(link_name=LSIGSETJMP)
	sigsetjmp :: proc(env: ^sigjmp_buf, savemask: b32) -> c.int ---
}

sigjmp_buf :: distinct jmp_buf

when ODIN_OS == .NetBSD {
	@(private) LSIGSETJMP  :: "__sigsetjmp14"
	@(private) LSIGLONGJMP :: "__siglongjmp14"
} else {
	@(private) LSIGSETJMP  :: "sigsetjmp"
	@(private) LSIGLONGJMP :: "siglongjmp"
}
