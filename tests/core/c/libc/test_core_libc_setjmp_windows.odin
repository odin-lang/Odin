package test_core_libc

import "base:intrinsics"
import "core:c/libc"
import "core:testing"

// On Windows arm64, `longjmp` always unwinds the stack to the stack pointer that `setjmp` got on entry to its
// caller, which the compiler passes in (see `lb_emit_call_internal`).

@(private="file")
setjmp_env: libc.jmp_buf

@(private="file")
setjmp_jump :: #force_no_inline proc(depth: int) {
	if depth == 0 {
		libc.longjmp(&setjmp_env, 42)
	}
	setjmp_jump(depth - 1)
}

@(test)
test_setjmp_longjmp :: proc(t: ^testing.T) {
	// A local changed between `setjmp` and `longjmp` must be volatile, as in C.
	passes: int
	r := libc.setjmp(&setjmp_env)
	intrinsics.volatile_store(&passes, intrinsics.volatile_load(&passes) + 1)
	if r == 0 {
		setjmp_jump(10)
	}
	testing.expect_value(t, r, 42)
	testing.expect_value(t, intrinsics.volatile_load(&passes), 2)
}
