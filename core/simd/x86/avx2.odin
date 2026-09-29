#+build i386, amd64
package simd_x86

import "core:simd"

// Shift packed 32-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srlv_epi32)
@(require_results, enable_target_feature="avx2")
_mm_srlv_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u32x4)count, simd.u32x4(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x4)count, simd.u32x4(0))
	return transmute(__m128i)simd.select(b, simd.shr(transmute(simd.u32x4)a, c), simd.u32x4(0))
}

// Shift packed 64-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srlv_epi64)
@(require_results, enable_target_feature="avx2")
_mm_srlv_epi64 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u64x2)count, simd.u64x2(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x2)count, simd.u64x2(0))
	return transmute(__m128i)simd.select(b, simd.shr(transmute(simd.u64x2)a, c), simd.u64x2(0))
}

// Shift packed 32-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srlv_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_srlv_epi32 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u32x8)count, simd.u32x8(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x8)count, simd.u32x8(0))
	return transmute(__m256i)simd.select(b, simd.shr(transmute(simd.u32x8)a, c), simd.u32x8(0))
}

// Shift packed 64-bit integers in `a` right by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srlv_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_srlv_epi64 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u64x4)count, simd.u64x4(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x4)count, simd.u64x4(0))
	return transmute(__m256i)simd.select(b, simd.shr(transmute(simd.u64x4)a, c), simd.u64x4(0))
}

// Shift packed 32-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sllv_epi32)
@(require_results, enable_target_feature="avx2")
_mm_sllv_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u32x4)count, simd.u32x4(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x4)count, simd.u32x4(0))
	return transmute(__m128i)simd.select(b, simd.shl(transmute(simd.u32x4)a, c), simd.u32x4(0))
}

// Shift packed 64-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sllv_epi64)
@(require_results, enable_target_feature="avx2")
_mm_sllv_epi64 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u64x2)count, simd.u64x2(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x2)count, simd.u64x2(0))
	return transmute(__m128i)simd.select(b, simd.shl(transmute(simd.u64x2)a, c), simd.u64x2(0))
}

// Shift packed 32-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sllv_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_sllv_epi32 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u32x8)count, simd.u32x8(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x8)count, simd.u32x8(0))
	return transmute(__m256i)simd.select(b, simd.shl(transmute(simd.u32x8)a, c), simd.u32x8(0))
}

// Shift packed 64-bit integers in `a` left by the amount specified by
// the corresponding element in `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sllv_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_sllv_epi64 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u64x4)count, simd.u64x4(8 * size_of(u64)))
	c := simd.select(b, transmute(simd.u64x4)count, simd.u64x4(0))
	return transmute(__m256i)simd.select(b, simd.shl(transmute(simd.u64x4)a, c), simd.u64x4(0))
}

// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_and_si256)
@(require_results, enable_target_feature="avx2")
_mm256_and_si256 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.bit_and(a, b)
}

// Compute the bitwise NOT of 256 bits (representing integer data) in `a` and then AND with `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_andnot_si256)
@(require_results, enable_target_feature="avx2")
_mm256_andnot_si256 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := __m256i(-1)
	return simd.bit_and(simd.bit_xor(a, c), b)
}

// Compute the bitwise OR of 256 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_or_si256)
@(require_results, enable_target_feature="avx2")
_mm256_or_si256 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.bit_or(a, b)
}

// Compute the bitwise XOR of 256 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_xor_si256)
@(require_results, enable_target_feature="avx2")
_mm256_xor_si256 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.bit_xor(a, b)
}
