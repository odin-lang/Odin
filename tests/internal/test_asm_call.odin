#+build amd64
package test_internal

import "core:testing"

@(test)
asm_call_internal_subroutine :: proc(t: ^testing.T) {
	// Calls a subroutine at one of its own labels twice. Each call doubles r and returns to the next instruction.
	quadruple :: asm(x: u64) -> (r: u64) [
		x -> r = %rax,
		#align_stack,
	] {
		call .double
		call .double
		jmp .done
	.double:
		add %rax, %rax
		ret
	.done:
	}

	testing.expect_value(t, quadruple(0), u64(0))
	testing.expect_value(t, quadruple(5), u64(20))
	testing.expect_value(t, quadruple(1<<40), u64(1<<42))
}
