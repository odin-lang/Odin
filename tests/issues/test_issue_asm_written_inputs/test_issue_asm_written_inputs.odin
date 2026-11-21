#+build amd64
package test_issue_asm_written_inputs

import "base:intrinsics"
import "core:testing"

// A template may write an input: itself, through a width-view, or as a pointer it advances.
// Such an input was lowered as input-only. LLVM then assumed the register still held the argument,
// and at -o:speed the caller read back the value the template left there instead.
// A written input is now tied to a discarded output.
//
// The argument must be a run-time value kept live across the call in the input's register:
// a volatile load, returned after the call.
seed:  u64 = 0x1ff
bytes: [3]u8 = {10, 20, 30}
ptr:   [^]u8

bump :: asm(a: u64) -> (r: u64) {
	add a, 1
	mov r, a
}

bump_pinned :: asm(a: u64) -> (r: u64) [
	a = %rax,
] {
	add a, 1
	mov r, a
}

bump_view :: asm(a: u64) -> (r: u64) [
	ab: u8 = a,
] {
	add ab, 1
	mov r, a
}

bump_ptr :: asm(p: [^]u8) -> (r: u8) {
	add p, 1
	mov r, [p]:u8
}

call_bump :: #force_no_inline proc "contextless" () -> (r, x: u64) {
	x = intrinsics.volatile_load(&seed)
	r = bump(x)
	return
}

call_bump_pinned :: #force_no_inline proc "contextless" () -> (r, x: u64) {
	x = intrinsics.volatile_load(&seed)
	r = bump_pinned(x)
	return
}

call_bump_view :: #force_no_inline proc "contextless" () -> (r, x: u64) {
	x = intrinsics.volatile_load(&seed)
	r = bump_view(x)
	return
}

call_bump_ptr :: #force_no_inline proc "contextless" () -> (r: u8, p: [^]u8) {
	p = intrinsics.volatile_load(&ptr)
	r = bump_ptr(p)
	return
}

@(test)
test_written_input_keeps_the_argument :: proc(t: ^testing.T) {
	ptr = &bytes[0]

	r0, x0 := call_bump()
	testing.expect_value(t, r0, u64(0x200))
	testing.expect_value(t, x0, u64(0x1ff))

	r1, x1 := call_bump_pinned()
	testing.expect_value(t, r1, u64(0x200))
	testing.expect_value(t, x1, u64(0x1ff))

	r2, x2 := call_bump_view()
	testing.expect_value(t, r2, u64(0x100)) // only the low byte wraps
	testing.expect_value(t, x2, u64(0x1ff))

	r3, p3 := call_bump_ptr()
	testing.expect_value(t, r3, u8(20))
	testing.expect(t, p3 == &bytes[0])
}
