#+build i386, amd64
package simd_x86

import "core:simd"

// Shift packed 32-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_srlv_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_srlv_epi32 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u32x16)count, simd.u32x16(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x16)count, simd.u32x16(0))
	return transmute(__m512i)simd.select(b, simd.shr(transmute(simd.u32x16)a, c), simd.u32x16(0))
}

// Shift packed 64-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_srlv_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_srlv_epi64 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u64x8)count, simd.u64x8(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x8)count, simd.u64x8(0))
	return transmute(__m512i)simd.select(b, simd.shr(transmute(simd.u64x8)a, c), simd.u64x8(0))
}

// Shift packed 32-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sllv_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_sllv_epi32 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u32x16)count, simd.u32x16(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x16)count, simd.u32x16(0))
	return transmute(__m512i)simd.select(b, simd.shl(transmute(simd.u32x16)a, c), simd.u32x16(0))
}

// Shift packed 64-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sllv_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_sllv_epi64 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u64x8)count, simd.u64x8(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x8)count, simd.u64x8(0))
	return transmute(__m512i)simd.select(b, simd.shl(transmute(simd.u64x8)a, c), simd.u64x8(0))
}

// Compute the bitwise AND of 512 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_and_si512)
@(require_results, enable_target_feature="avx512f")
_mm512_and_si512 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.bit_and(a, b)
}

// Compute the bitwise NOT of 512 bits (representing integer data) in `a` and then AND with `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_andnot_si512)
@(require_results, enable_target_feature="avx512f")
_mm512_andnot_si512 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	c := __m512i(-1)
	return simd.bit_and(simd.bit_xor(a, c), b)
}

// Compute the bitwise OR of 512 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_or_si512)
@(require_results, enable_target_feature="avx512f")
_mm512_or_si512 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.bit_or(a, b)
}

// Compute the bitwise XOR of 512 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_xor_si512)
@(require_results, enable_target_feature="avx512f")
_mm512_xor_si512 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.bit_xor(a, b)
}
