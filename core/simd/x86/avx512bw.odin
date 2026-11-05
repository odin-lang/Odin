#+build i386, amd64
package simd_x86

import "core:simd"

// Shift packed 16-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srlv_epi16)
@(require_results, enable_target_feature="avx512bw,avx512vl")
_mm_srlv_epi16 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u16x8)count, simd.u16x8(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x8)count, simd.u16x8(0))
	return transmute(__m128i)simd.select(b, simd.shr(transmute(simd.u16x8)a, c), simd.u16x8(0))
}

// Shift packed 16-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srlv_epi16)
@(require_results, enable_target_feature="avx512bw,avx512vl")
_mm256_srlv_epi16 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u16x16)count, simd.u16x16(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x16)count, simd.u16x16(0))
	return transmute(__m256i)simd.select(b, simd.shr(transmute(simd.u16x16)a, c), simd.u16x16(0))
}

// Shift packed 16-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_srlv_epi16)
@(require_results, enable_target_feature="avx512bw,evex512")
_mm512_srlv_epi16 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u16x32)count, simd.u16x32(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x32)count, simd.u16x32(0))
	return transmute(__m512i)simd.select(b, simd.shr(transmute(simd.u16x32)a, c), simd.u16x32(0))
}

// Shift packed 16-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sllv_epi16)
@(require_results, enable_target_feature="avx512bw,avx512vl")
_mm_sllv_epi16 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u16x8)count, simd.u16x8(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x8)count, simd.u16x8(0))
	return transmute(__m128i)simd.select(b, simd.shl(transmute(simd.u16x8)a, c), simd.u16x8(0))
}

// Shift packed 16-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sllv_epi16)
@(require_results, enable_target_feature="avx512bw,avx512vl")
_mm256_sllv_epi16 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u16x16)count, simd.u16x16(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x16)count, simd.u16x16(0))
	return transmute(__m256i)simd.select(b, simd.shl(transmute(simd.u16x16)a, c), simd.u16x16(0))
}

// Shift packed 16-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sllv_epi16)
@(require_results, enable_target_feature="avx512bw,evex512")
_mm512_sllv_epi16 :: #force_inline proc "c" (a: __m512i, count: __m512i) -> __m512i {
	b := simd.lanes_lt(transmute(simd.u16x32)count, simd.u16x32(8 * size_of(u16)))
	c := simd.select(b, transmute(simd.u16x32)count, simd.u16x32(0))
	return transmute(__m512i)simd.select(b, simd.shl(transmute(simd.u16x32)a, c), simd.u16x32(0))
}
