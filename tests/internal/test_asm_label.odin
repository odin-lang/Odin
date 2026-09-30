#+build amd64
package test_internal

import "core:testing"

// Regression coverage for label definitions inside inline-asm templates on amd64.
@(test)
asm_label_backward_branch :: proc(t: ^testing.T) {
	// Counts down to zero. A branch that falls through instead of looping returns n-1.
	drain :: asm(n: u64) -> (r: u64) [n -> r] {
	.loop:
		dec r
		jnz .loop
	}

	testing.expect_value(t, drain(1), u64(0))
	testing.expect_value(t, drain(5), u64(0))
	testing.expect_value(t, drain(64), u64(0))
}

@(test)
asm_label_forward_branch :: proc(t: ^testing.T) {
	// Clamps to 10. A branch that falls through instead of skipping clamps every input.
	saturate :: asm(n: u64) -> (r: u64) [n -> r] {
		cmp r, 10
		jbe .done
		mov r, 10
	.done:
		nop
	}

	testing.expect_value(t, saturate(0), u64(0))
	testing.expect_value(t, saturate(7), u64(7))
	testing.expect_value(t, saturate(10), u64(10))
	testing.expect_value(t, saturate(11), u64(10))
	testing.expect_value(t, saturate(1000), u64(10))
}
