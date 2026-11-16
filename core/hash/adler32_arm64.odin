#+build arm64
package hash

import "base:intrinsics"
import "core:simd"

@(private)
ADLER32_SIMD :: true

@(private)
ADLER32_SIMD_MIN :: 32

@(private)
adler32_simd_available :: #force_inline proc "contextless" () -> bool {
	return true
}

@(private, enable_target_feature="neon")
adler32_simd :: proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) #no_bounds_check {
	ADLER_CONST :: 65521
	UNIT        :: 32
	BLOCK_UNITS :: 128

	Bytes   :: #simd[16]u8
	Columns :: #simd[16]u16
	Pairs   :: #simd[8]u16
	Quads   :: #simd[4]u32
	Wide    :: #simd[16]u32

	HIGH :: Wide{32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17}
	LOW  :: Wide{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}

	new_a, new_b = a, b
	units := len(data) / UNIT
	p := raw_data(data)
	for units > 0 {
		k := min(units, BLOCK_UNITS)
		s1, prefix: Quads
		c0, c1: Columns
		for _ in 0..<k {
			v0 := intrinsics.unaligned_load((^Bytes)(p))
			v1 := intrinsics.unaligned_load((^Bytes)(p[16:]))
			prefix += s1
			c0 += cast(Columns)v0
			c1 += cast(Columns)v1
			s1 += neon_uaddlp_u16(neon_uaddlp_u8(v0) + neon_uaddlp_u8(v1))
			p = p[UNIT:]
		}
		new_b += u64(k * UNIT) * new_a
		new_b += UNIT * u64(simd.reduce_add_pairs(prefix))
		new_b += u64(simd.reduce_add_pairs(cast(Wide)c0 * HIGH))
		new_b += u64(simd.reduce_add_pairs(cast(Wide)c1 * LOW))
		new_a += u64(simd.reduce_add_pairs(s1))
		new_a %= ADLER_CONST
		new_b %= ADLER_CONST
		units -= k
		consumed += k * UNIT
	}
	return
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.aarch64.neon.uaddlp.v8i16.v16i8") neon_uaddlp_u8  :: proc(a: #simd[16]u8) -> #simd[8]u16 ---
	@(link_name="llvm.aarch64.neon.uaddlp.v4i32.v8i16") neon_uaddlp_u16 :: proc(a: #simd[8]u16) -> #simd[4]u32 ---
}
