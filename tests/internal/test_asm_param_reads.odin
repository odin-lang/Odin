#+build amd64
package test_internal

import "core:testing"

// A read through a pinned parameter did not count as a read of its register.
// Writing the parameter, then reading it, warned that the write to %rax was never read.
@(test)
asm_read_through_a_pinned_parameter :: proc(t: ^testing.T) {
	bump :: asm(a: u64) -> (r: u64) [
		a = %rax,
	] {
		add a, 1
		mov r, a
	}
	testing.expect_value(t, bump(41), u64(42))
}

// `xor sd, sd` on a 32-bit view zeroes the whole register. Like `xor s, s`, it defines `s` without reading it.
// Through the view, it was reported as reading `s` before it is assigned.
@(test)
asm_self_zeroing_through_a_view :: proc(t: ^testing.T) {
	zero :: asm() -> (r: u64) [
		s:  u64,
		sd: u32 = s,
	] {
		xor sd, sd
		mov r, s
	}
	testing.expect_value(t, zero(), u64(0))
}
