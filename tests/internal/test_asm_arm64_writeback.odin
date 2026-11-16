#+build arm64
package test_internal

import "core:testing"

// #pre and #post memory operands were written without their writeback:
// `ldr r, #post [p + 8]` became `ldr r, [p, #8]`, and `stp a, b, #pre [%sp - 16]` stored below sp without moving it.
// A $ immediate displacement was dropped too: `[p + K]` became `[p]`.
@(test)
asm_arm64_writeback :: proc(t: ^testing.T) {
	post :: asm(p: [^]u64) -> (r: u64, next: [^]u64) [p -> next] { ldr r, #post [next + 8] }
	pre  :: asm(p: [^]u64) -> (r: u64, next: [^]u64) [p -> next] { ldr r, #pre [next + 8] }
	at   :: asm(p: [^]u64, $K: i64) -> (r: u64) { ldr r, [p + K] }

	// a round trip through the stack, which leaves sp where it was
	swap :: asm(a, b: u64) -> (x, y: u64) [
		#align_stack,
	] {
		stp a, b, #pre [%sp - 16]
		ldp y, x, #post [%sp + 16]
	}

	buf := [3]u64{10, 20, 30}

	r0, next0 := post(&buf[0])
	testing.expect_value(t, r0, u64(10))
	testing.expect(t, next0 == &buf[1])

	r1, next1 := pre(&buf[0])
	testing.expect_value(t, r1, u64(20))
	testing.expect(t, next1 == &buf[1])

	testing.expect_value(t, at(&buf[0], 16), u64(30))

	x, y := swap(1, 2)
	testing.expect_value(t, x, u64(2))
	testing.expect_value(t, y, u64(1))
}
