#+build amd64
package test_internal

import "core:fmt"
import "core:testing"

// The `asm` restriction to amd64 is enforced in the parser, so a `when ODIN_ARCH` guard inside the
// body cannot suppress it -- the body is parsed either way. The file needs a build tag instead.
//
// A template of more than one instruction can write its output before a later instruction has read
// its inputs, so the output must not share a register with one of them. Without an early-clobber the
// allocator was free to overlap them and `mov r, a; add r, b` computed `a + a`.
//
// The shape below matters: the defect only appears when surrounding register pressure makes the
// allocator pick an input's register for the output, and two asm calls as arguments to one variadic
// call is what did it. The same calls in separate statements were always correct
@(test)
asm_multi_instruction_output_does_not_alias_an_input :: proc(t: ^testing.T) {
	add32 :: asm(a: i32, b: i32) -> (r: i32) { mov r, a; add r, b; }
	sub32 :: asm(a: i32, b: i32) -> (r: i32) { mov r, a; sub r, b; }
	mul32 :: asm(a: i32, b: i32) -> (r: i32) { mov r, a; imul r, b; }
	xor64 :: asm(a: u64, b: u64) -> (r: u64) { mov r, a; xor r, b; }
	wide  :: asm(a: i64) -> (r: i64) { mov r, a; }

	testing.expect_value(t, fmt.tprintf("%v %v", add32(20, 22), wide(-7)), "42 -7")
	testing.expect_value(t, fmt.tprintf("%v %v", sub32(50,  8), wide(-7)), "42 -7")
	testing.expect_value(t, fmt.tprintf("%v %v", mul32(6,   7), wide(-7)), "42 -7")
	testing.expect_value(t, fmt.tprintf("%v %v", xor64(0xF0, 0x0F), wide(-7)), "255 -7")

	// asymmetric arguments, so `a + a` or `a - a` cannot pass by coincidence
	testing.expect_value(t, add32(1, 100), i32(101))
	testing.expect_value(t, sub32(1, 100), i32(-99))
	testing.expect_value(t, mul32(1, 100), i32(100))
	testing.expect_value(t, wide(-7),      i64(-7))
}
