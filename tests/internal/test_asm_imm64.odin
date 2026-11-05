#+build amd64
package test_internal

import "core:testing"

// A 64-bit immediate was printed into the template through an `int`, so it lost its upper 32 bits
@(test)
asm_imm64 :: proc(t: ^testing.T) {
	big :: asm() -> (r: u64) { mov r, 0x1122334455667788; }
	testing.expect_value(t, big(), u64(0x1122334455667788))
}
