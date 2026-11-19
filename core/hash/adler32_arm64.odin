#+build arm64
package hash

import "base:intrinsics"
import "core:simd"

@(private)
ADLER32_SIMD :: true

@(private)
ADLER32_UDOT :: ODIN_OS == .Darwin && ODIN_PLATFORM_SUBTARGET == .Default

@(private)
ADLER32_SIMD_MIN :: 64 when ADLER32_UDOT else 32

@(private)
adler32_simd_available :: #force_inline proc "contextless" () -> bool {
	return true
}

@(private)
adler32_simd :: #force_inline proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) {
	when ADLER32_UDOT {
		return adler32_udot(a, b, data)
	} else {
		return adler32_uaddlp(a, b, data)
	}
}

@(private, enable_target_feature="neon")
adler32_uaddlp :: proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) #no_bounds_check {
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

@(private, enable_target_feature="neon,dotprod")
adler32_udot :: proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) #no_bounds_check {
	ADLER_CONST :: 65521
	UNIT        :: 64
	BLOCK_UNITS :: 256

	Bytes :: #simd[16]u8
	Quads :: #simd[4]u32
	Longs :: #simd[4]u64

	ONES :: Bytes{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
	W0   :: Bytes{64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49}
	W1   :: Bytes{48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33}
	W2   :: Bytes{32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17}
	W3   :: Bytes{16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}

	new_a, new_b = a, b
	units := len(data) / UNIT
	p := raw_data(data)
	for units > 0 {
		k := min(units, BLOCK_UNITS)
		s1, prefix, w0, w1, w2, w3: Quads
		for _ in 0..<k {
			v0 := intrinsics.unaligned_load((^Bytes)(p))
			v1 := intrinsics.unaligned_load((^Bytes)(p[16:]))
			v2 := intrinsics.unaligned_load((^Bytes)(p[32:]))
			v3 := intrinsics.unaligned_load((^Bytes)(p[48:]))
			prefix += s1
			s1 += neon_udot(neon_udot(neon_udot(neon_udot(Quads{}, v0, ONES), v1, ONES), v2, ONES), v3, ONES)
			w0 = neon_udot(w0, v0, W0)
			w1 = neon_udot(w1, v1, W1)
			w2 = neon_udot(w2, v2, W2)
			w3 = neon_udot(w3, v3, W3)
			p = p[UNIT:]
		}
		new_b += u64(k * UNIT) * new_a
		new_b += UNIT * simd.reduce_add_pairs(cast(Longs)prefix)
		new_b += simd.reduce_add_pairs(cast(Longs)(w0 + w1) + cast(Longs)(w2 + w3))
		new_a += simd.reduce_add_pairs(cast(Longs)s1)
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
	@(link_name="llvm.aarch64.neon.udot.v4i32.v16i8")   neon_udot       :: proc(acc: #simd[4]u32, a, b: #simd[16]u8) -> #simd[4]u32 ---
}
