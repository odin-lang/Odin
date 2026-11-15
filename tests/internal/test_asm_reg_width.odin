#+build amd64
package test_internal

import "core:testing"

// Implicit register writes (`rdtsc` -> EDX:EAX, `cqo` -> RDX) carry no operand width, and the
// sub-register width analysis treated them as defining 0 bits, so any later full-width read of
// the register was rejected with "only its low 0 bits are defined". Writes through a pinned
// parameter had the same problem. An input pinned to a register that is only read implicitly
// (`cqo` reads RAX) was also reported as never used.
@(test)
asm_implicit_write_width :: proc(t: ^testing.T) {
	rdtsc :: asm() -> (ts: u64) [ts = %rax] {
		rdtsc
		shl %rdx, 32
		or %rax, %rdx
	}
	sign_64 :: asm(x: i64) -> (r: i64) [x = %rax] { cqo; mov r, %rdx }
	sign_32 :: asm(x: i32) -> (r: u64) [x = %rax] { cdq; mov r, %rdx } // EDX write zero-extends RDX
	pinned  :: asm(x: u64) -> (r: u64) [r = %rax] { mov r, x; add %rax, 1 }

	testing.expect(t, rdtsc() != 0)

	testing.expect_value(t, sign_64(-5),  i64(-1))
	testing.expect_value(t, sign_64(5),   i64(0))
	testing.expect_value(t, sign_32(-5),  u64(0xFFFF_FFFF))
	testing.expect_value(t, sign_32(5),   u64(0))

	testing.expect_value(t, pinned(41),   u64(42))
}
