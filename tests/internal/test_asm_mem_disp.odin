#+build amd64
package test_internal

import "core:testing"

// `$` displacements were dropped, and labels were absolute addresses (no PIE link)
@(test)
asm_mem_disp :: proc(t: ^testing.T) {
	table     :: asm(i: u64) -> (r: u32) [t: u64] { lea t, [.tbl]; mov r, [t + i*4]:u32; jmp .out; .tbl: #byte 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0; .out: }
	data      :: asm() -> (r: u64) { mov r, [.d + 2]:u64; jmp .o; .d: #byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10; .o: }
	at_offset :: asm(p: [^]u64, $n: int) -> (r: u64) { mov r, [p + n] }
	below     :: asm(p: [^]u64, $n: int) -> (r: u64) { mov r, [p - n + 24] }

	testing.expect_value(t, table(2), u32(3))
	testing.expect_value(t, data(), u64(0x0A09080706050403))
	a := [4]u64{1, 2, 3, 4}
	testing.expect_value(t, at_offset(raw_data(a[:]), 16), u64(3))
	testing.expect_value(t, below(raw_data(a[:]), 8), u64(3))
}
