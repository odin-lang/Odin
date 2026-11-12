#+build amd64
package test_internal

import "core:testing"

// A width-view inherits its source's register, so a view of a pinned operand is itself pinned.
// The liveness pass asserted that a view and its source were never pinned, crashing the compiler
// whenever such a view was used as an operand
@(test)
asm_pinned_view :: proc(t: ^testing.T) {
	full :: asm(x: int) -> (r: int) [
		v: int = r,
		r = %rcx,
	] {
		mov v, x
	}

	low32 :: asm(x: u32) -> (r: u64) [
		v: u32 = r,
		r = %rax,
	] {
		mov v, x
	}

	testing.expect_value(t, full(-42),          -42)
	testing.expect_value(t, low32(0xFFFF_FFFF), u64(0xFFFF_FFFF))
}
