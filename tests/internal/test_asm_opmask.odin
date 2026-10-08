#+build amd64
package test_internal

import "core:sys/info"
import "core:testing"

// A `%k` opmask register was rejected wherever the instruction wants an opmask operand,
// so these templates did not compile.

@(test)
asm_opmask_registers :: proc(t: ^testing.T) {
	eq_mask :: asm(a: #simd[4]u32, b: #simd[4]u32) -> (r: u32) [#clobber %k1] { vpcmpd %k1, a, b, 0; kmovw r, %k1 }
	knot    :: asm(a: u32) -> (r: u32) [#clobber %k2, #clobber %k3] { kmovw %k2, a; knotw %k3, %k2; kmovw r, %k3 }

	// compiling is the actual test; running needs AVX-512
	if !(info.cpu_features() >= {.avx512f, .avx512vl}) {
		return
	}
	testing.expect_value(t, eq_mask({1, 2, 3, 4}, {1, 0, 3, 0}), u32(0b0101))
	testing.expect_value(t, knot(0x00F0), u32(0xFF0F))
}
