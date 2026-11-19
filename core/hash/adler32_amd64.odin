#+build amd64
package hash

import "base:intrinsics"
import "core:simd"
import "core:simd/x86"

@(private)
ADLER32_SIMD :: true

@(private)
ADLER32_SIMD_MIN :: 64

@(private)
ADLER32_AVX2_STATIC :: intrinsics.has_target_feature("avx2")

@(private)
adler32_avx2_detected := ADLER32_AVX2_STATIC

@(init, private)
adler32_detect :: proc "contextless" () {
	when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
		return
	}
	max_id, _, _, _ := intrinsics.x86_cpuid(0, 0)
	_, _, ecx1, _ := intrinsics.x86_cpuid(1, 0)
	if max_id < 7 || ecx1 & (1 << 27) == 0 || ecx1 & (1 << 28) == 0 {
		return
	}
	xcr0, _ := intrinsics.x86_xgetbv(0)
	if xcr0 & 0b110 != 0b110 {
		return
	}
	_, ebx7, _, _ := intrinsics.x86_cpuid(7, 0)
	adler32_avx2_detected = ebx7 & (1 << 5) != 0
}

@(private)
adler32_simd_available :: #force_inline proc "contextless" () -> bool {
	when ADLER32_AVX2_STATIC {
		return true
	} else {
		return adler32_avx2_detected
	}
}

@(private, enable_target_feature="avx,avx2")
adler32_simd :: proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) #no_bounds_check {
	ADLER_CONST :: 65521
	UNIT        :: 64
	BLOCK_UNITS :: 1024

	new_a, new_b = a, b
	units := len(data) / UNIT
	p := raw_data(data)
	zero := x86._mm256_setzero_si256()
	ones := x86._mm256_set1_epi16(1)
	high := x86._mm256_setr_epi8(
		64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49,
		48, 47, 46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35, 34, 33,
	)
	low := x86._mm256_setr_epi8(
		32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17,
		16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
	)
	for units > 0 {
		k := min(units, BLOCK_UNITS)
		s1, prefix, s2: x86.__m256i
		for _ in 0..<k {
			v0 := x86._mm256_loadu_si256((^x86.__m256i)(p))
			v1 := x86._mm256_loadu_si256((^x86.__m256i)(p[32:]))
			prefix = x86._mm256_add_epi64(prefix, s1)
			s1 = x86._mm256_add_epi64(s1, x86._mm256_add_epi64(x86._mm256_sad_epu8(v0, zero), x86._mm256_sad_epu8(v1, zero)))
			w0 := x86._mm256_madd_epi16(x86._mm256_maddubs_epi16(v0, high), ones)
			w1 := x86._mm256_madd_epi16(x86._mm256_maddubs_epi16(v1, low), ones)
			s2 = x86._mm256_add_epi32(s2, x86._mm256_add_epi32(w0, w1))
			p = p[UNIT:]
		}
		new_b += u64(k * UNIT) * new_a
		new_b += UNIT * simd.reduce_add_pairs(transmute(#simd[4]u64)prefix)
		new_b += u64(simd.reduce_add_pairs(transmute(#simd[8]u32)s2))
		new_a += simd.reduce_add_pairs(transmute(#simd[4]u64)s1)
		new_a %= ADLER_CONST
		new_b %= ADLER_CONST
		units -= k
		consumed += k * UNIT
	}
	return
}
