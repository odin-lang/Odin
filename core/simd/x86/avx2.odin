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

// Compute the absolute value of packed signed 8-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_abs_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_abs_epi8 :: #force_inline proc "c" (a: __m256i) -> __m256i {
	b := transmute(simd.i8x32)a
	c := simd.select(simd.lanes_lt(b, simd.i8x32(0)), simd.neg(b), b)
	return transmute(__m256i)c
}

// Compute the absolute value of packed signed 16-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_abs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_abs_epi16 :: #force_inline proc "c" (a: __m256i) -> __m256i {
	b := transmute(simd.i16x16)a
	c := simd.select(simd.lanes_lt(b, simd.i16x16(0)), simd.neg(b), b)
	return transmute(__m256i)c
}

// Compute the absolute value of packed signed 32-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_abs_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_abs_epi32 :: #force_inline proc "c" (a: __m256i) -> __m256i {
	b := transmute(simd.i32x8)a
	c := simd.select(simd.lanes_lt(b, simd.i32x8(0)), simd.neg(b), b)
	return transmute(__m256i)c
}

// Add packed 8-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_add_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.add(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Add packed 16-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_add_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.add(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Add packed 32-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_add_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.add(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Add packed 64-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_add_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.add(a, b)
}

// Add packed 8-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_adds_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_adds_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_add(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Add packed 16-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_adds_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_adds_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_add(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Add packed unsigned 8-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_adds_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_adds_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_add(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Add packed unsigned 16-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_adds_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_adds_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_add(transmute(simd.u16x16)a, transmute(simd.u16x16)b)
}

// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_sub_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.sub(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_sub_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.sub(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_sub_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.sub(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Subtract packed 64-bit integers in `b` from packed 64-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_sub_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.sub(a, b)
}

// Subtract packed signed 8-bit integers in `b` from packed 8-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_subs_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_subs_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_sub(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Subtract packed signed 16-bit integers in `b` from packed 16-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_subs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_subs_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_sub(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Subtract packed unsigned 8-bit integers in `b` from packed unsigned 8-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_subs_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_subs_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_sub(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Subtract packed unsigned 16-bit integers in `b` from packed unsigned 16-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_subs_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_subs_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.saturating_sub(transmute(simd.u16x16)a, transmute(simd.u16x16)b)
}

// Unpack and interleave 8-bit integers from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_unpackhi_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i8x32)a,
		transmute(simd.i8x32)b,
		 8, 40,  9, 41, 10, 42, 11, 43,
		12, 44, 13, 45, 14, 46, 15, 47,
		24, 56, 25, 57, 26, 58, 27, 59,
		28, 60, 29, 61, 30, 62, 31, 63,
	)
}

// Unpack and interleave 16-bit integers from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_unpackhi_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		 4, 20,  5, 21,  6, 22,  7, 23,
		12, 28, 13, 29, 14, 30, 15, 31,
	)
}

// Unpack and interleave 32-bit integers from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_unpackhi_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		2, 10, 3, 11, 6, 14, 7, 15,
	)
}

// Unpack and interleave 64-bit integers from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_unpackhi_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.shuffle(a, b, 1, 5, 3, 7)
}

// Unpack and interleave 8-bit integers from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_unpacklo_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i8x32)a,
		transmute(simd.i8x32)b,
		 0, 32,  1, 33,  2, 34,  3, 35,
		 4, 36,  5, 37,  6, 38,  7, 39,
		16, 48, 17, 49, 18, 50, 19, 51,
		20, 52, 21, 53, 22, 54, 23, 55,
	)
}

// Unpack and interleave 16-bit integers from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_unpacklo_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		0, 16, 1, 17,  2, 18,  3, 19,
		8, 24, 9, 25, 10, 26, 11, 27,
	)
}

// Unpack and interleave 32-bit integers from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_unpacklo_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		0, 8, 1, 9, 4, 12, 5, 13,
	)
}

// Unpack and interleave 64-bit integers from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_unpacklo_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.shuffle(a, b, 0, 4, 2, 6)
}

// Compare packed signed 8-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_max_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Compare packed signed 16-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_max_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_max_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Compare packed unsigned 8-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_max_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Compare packed unsigned 16-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_max_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.u16x16)a, transmute(simd.u16x16)b)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epu32)
@(require_results, enable_target_feature="avx2")
_mm256_max_epu32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.u32x8)a, transmute(simd.u32x8)b)
}

// Compare packed signed 8-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_min_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Compare packed signed 16-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_min_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_min_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Compare packed unsigned 8-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_min_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Compare packed unsigned 16-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_min_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.u16x16)a, transmute(simd.u16x16)b)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epu32)
@(require_results, enable_target_feature="avx2")
_mm256_min_epu32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.u32x8)a, transmute(simd.u32x8)b)
}

// Average packed unsigned 8-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_avg_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_avg_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := cast(simd.u16x32)(transmute(simd.u8x32)a)
	d := cast(simd.u16x32)(transmute(simd.u8x32)b)
	e := simd.shr(simd.add(simd.add(c, d), simd.u16x32(1)), simd.u16x32(1))
	return transmute(__m256i)(cast(simd.u8x32)e)
}

// Average packed unsigned 16-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_avg_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_avg_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := cast(simd.u32x16)(transmute(simd.u16x16)a)
	d := cast(simd.u32x16)(transmute(simd.u16x16)b)
	e := simd.shr(simd.add(simd.add(c, d), simd.u32x16(1)), simd.u32x16(1))
	return transmute(__m256i)(cast(simd.u16x16)e)
}

// Negate packed signed 8-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative, and store the results in `dst`.
// Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sign_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_sign_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_psignb(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Negate packed signed 16-bit integers in `a` when the corresponding signed 16-bit integer in `b` is negative, and store the results in `dst`.
// Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sign_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_sign_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_psignw(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Negate packed signed 32-bit integers in `a` when the corresponding signed 32-bit integer in `b` is negative, and store the results in `dst`.
// Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sign_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_sign_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_psignd(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Multiply the low signed 32-bit integers from each packed 64-bit element in `a` and `b`, and store the signed 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mul_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_mul_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := cast(__m256i)(cast(simd.i32x4)a)
	d := cast(__m256i)(cast(simd.i32x4)b)
	return simd.mul(c, d)
}

// Multiply the low unsigned 32-bit integers from each packed 64-bit element in `a` and `b`, and store the unsigned 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mul_epu32)
@(require_results, enable_target_feature="avx2")
_mm256_mul_epu32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := transmute(simd.u64x4)a
	d := transmute(simd.u64x4)b
	m := simd.u64x4(max(u32))
	return transmute(__m256i)simd.mul(simd.bit_and(c, m), simd.bit_and(d, m))
}

// Multiply the packed signed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the high 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mulhi_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_mulhi_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := cast(simd.i32x16)(transmute(simd.i16x16)a)
	d := cast(simd.i32x16)(transmute(simd.i16x16)b)
	e := simd.shr(simd.mul(c, d), simd.u32x16(16))
	return transmute(__m256i)(cast(simd.i16x16)e)
}

// Multiply the packed unsigned 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the high 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mulhi_epu16)
@(require_results, enable_target_feature="avx2")
_mm256_mulhi_epu16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := cast(simd.u32x16)(transmute(simd.u16x16)a)
	d := cast(simd.u32x16)(transmute(simd.u16x16)b)
	e := simd.shr(simd.mul(c, d), simd.u32x16(16))
	return transmute(__m256i)(cast(simd.u16x16)e)
}

// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
// Truncate each intermediate integer to the 18 most significant bits, round by adding 1, and store bits `[16:1]` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mulhrs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_mulhrs_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_pmulhrsw(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Multiply the packed signed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the low 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mullo_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_mullo_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.mul(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Multiply the packed signed 32-bit integers in `a` and `b`, producing intermediate 64-bit integers,
// and store the low 32 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mullo_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_mullo_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.mul(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using signed saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_packs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_packs_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_packsswb(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using signed saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_packs_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_packs_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_packssdw(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using unsigned saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_packus_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_packus_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_packuswb(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using unsigned saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_packus_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_packus_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_packusdw(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each consecutive 8 differences to
// produce four unsigned 16-bit integers, and pack these unsigned 16-bit integers in the low 16 bits of 64-bit elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sad_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_sad_epu8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_psadbw(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Shuffle 8-bit integers in `a` within 128-bit lanes according to shuffle control mask
// in the corresponding 8-bit element of `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shuffle_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_shuffle_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_pshufb(transmute(simd.u8x32)a, transmute(simd.u8x32)b)
}

// Shuffle 32-bit integers in `a` within 128-bit lanes using the control in `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shuffle_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_shuffle_epi32 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)a,
		(u32(IMM8) & 0b11),
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
		(u32(IMM8) & 0b11) + 4,
		((u32(IMM8) >> 2) & 0b11) + 4,
		((u32(IMM8) >> 4) & 0b11) + 4,
		((u32(IMM8) >> 6) & 0b11) + 4,
	)
}

// Shuffle 16-bit integers in the high 64 bits of 128-bit lanes of `a` using the control in `imm8`.
// Store the results in the high 64 bits of 128-bit lanes of `dst`, with the low 64 bits
// of 128-bit lanes being copied from from `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shufflehi_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_shufflehi_epi16 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)a,
		0,
		1,
		2,
		3,
		4 + (u32(IMM8) & 0b11),
		4 + ((u32(IMM8) >> 2) & 0b11),
		4 + ((u32(IMM8) >> 4) & 0b11),
		4 + ((u32(IMM8) >> 6) & 0b11),
		8,
		9,
		10,
		11,
		12 + (u32(IMM8) & 0b11),
		12 + ((u32(IMM8) >> 2) & 0b11),
		12 + ((u32(IMM8) >> 4) & 0b11),
		12 + ((u32(IMM8) >> 6) & 0b11),
	)
}

// Shuffle 16-bit integers in the low 64 bits of 128-bit lanes of `a` using the control in `imm8`.
// Store the results in the low 64 bits of 128-bit lanes of `dst`, with the high 64 bits
// of 128-bit lanes being copied from from `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shufflelo_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_shufflelo_epi16 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)a,
		0 + (u32(IMM8) & 0b11),
		0 + ((u32(IMM8) >> 2) & 0b11),
		0 + ((u32(IMM8) >> 4) & 0b11),
		0 + ((u32(IMM8) >> 6) & 0b11),
		4,
		5,
		6,
		7,
		8 + (u32(IMM8) & 0b11),
		8 + ((u32(IMM8) >> 2) & 0b11),
		8 + ((u32(IMM8) >> 4) & 0b11),
		8 + ((u32(IMM8) >> 6) & 0b11),
		12,
		13,
		14,
		15,
	)
}

// Shift packed 16-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sll_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_sll_epi16 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_psllw(transmute(simd.i16x16)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sll_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_sll_epi32 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_pslld(transmute(simd.i32x8)a, transmute(simd.i32x4)count)
}

// Shift packed 64-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sll_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_sll_epi64 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return llvm_psllq(a, count)
}

// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_slli_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_slli_epi16 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 16 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shl(transmute(simd.u16x16)a, simd.u16x16(IMM8))
	}
}

// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_slli_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_slli_epi32 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shl(transmute(simd.u32x8)a, simd.u32x8(IMM8))
	}
}

// Shift packed 64-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_slli_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_slli_epi64 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 64 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shl(transmute(simd.u64x4)a, simd.u64x4(IMM8))
	}
}

// Shift packed 16-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srl_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_srl_epi16 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_psrlw(transmute(simd.i16x16)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srl_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_srl_epi32 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_psrld(transmute(simd.i32x8)a, transmute(simd.i32x4)count)
}

// Shift packed 64-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srl_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_srl_epi64 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return llvm_psrlq(a, count)
}

// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srli_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_srli_epi16 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 16 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shr(transmute(simd.u16x16)a, simd.u16x16(IMM8))
	}
}

// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srli_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_srli_epi32 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shr(transmute(simd.u32x8)a, simd.u32x8(IMM8))
	}
}

// Shift packed 64-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srli_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_srli_epi64 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 64 {
		return __m256i(0)
	} else {
		return transmute(__m256i)simd.shr(transmute(simd.u64x4)a, simd.u64x4(IMM8))
	}
}

// Shift packed 16-bit integers in `a` right by `count` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sra_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_sra_epi16 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_psraw(transmute(simd.i16x16)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` right by `count` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sra_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_sra_epi32 :: #force_inline proc "c" (a: __m256i, count: __m128i) -> __m256i {
	return transmute(__m256i)llvm_psrad(transmute(simd.i32x8)a, transmute(simd.i32x4)count)
}

// Shift packed 16-bit integers in `a` right by `imm8` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srai_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_srai_epi16 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shr(transmute(simd.i16x16)a, simd.u16x16(min(IMM8, 15)))
}

// Shift packed 32-bit integers in `a` right by `imm8` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srai_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_srai_epi32 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shr(transmute(simd.i32x8)a, simd.u32x8(min(IMM8, 31)))
}

// Shift packed 32-bit integers in `a` right by the amount specified by the corresponding element in `count`
// while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srav_epi32)
@(require_results, enable_target_feature="avx2")
_mm_srav_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	b := simd.lanes_lt(transmute(simd.u32x4)count, simd.u32x4(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x4)count, simd.u32x4(31))
	return transmute(__m128i)simd.shr(transmute(simd.i32x4)a, c)
}

// Shift packed 32-bit integers in `a` right by the amount specified by the corresponding element in `count`
// while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srav_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_srav_epi32 :: #force_inline proc "c" (a: __m256i, count: __m256i) -> __m256i {
	b := simd.lanes_lt(transmute(simd.u32x8)count, simd.u32x8(8 * size_of(u32)))
	c := simd.select(b, transmute(simd.u32x8)count, simd.u32x8(31))
	return transmute(__m256i)simd.shr(transmute(simd.i32x8)a, c)
}

// Blend packed 32-bit integers from `a` and `b` using control mask `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blend_epi32)
@(require_results, enable_target_feature="avx2")
_mm_blend_epi32 :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 16 {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		[4]int {0, 4, 0, 4}[(u32(IMM8) & 0b11)],
		[4]int {1, 1, 5, 5}[(u32(IMM8) & 0b11)],
		[4]int {2, 6, 2, 6}[(u32(IMM8) >> 2) & 0b11],
		[4]int {3, 3, 7, 7}[(u32(IMM8) >> 2) & 0b11],
	)
}

// Blend packed 16-bit integers from `a` and `b` within 128-bit lanes using control mask `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blend_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_blend_epi16 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		[4]int {0, 16, 0, 16}[(u32(IMM8) & 0b11)],
		[4]int {1, 1, 17, 17}[(u32(IMM8) & 0b11)],
		[4]int {2, 18, 2, 18}[(u32(IMM8) >> 2) & 0b11],
		[4]int {3, 3, 19, 19}[(u32(IMM8) >> 2) & 0b11],
		[4]int {4, 20, 4, 20}[(u32(IMM8) >> 4) & 0b11],
		[4]int {5, 5, 21, 21}[(u32(IMM8) >> 4) & 0b11],
		[4]int {6, 22, 6, 22}[(u32(IMM8) >> 6) & 0b11],
		[4]int {7, 7, 23, 23}[(u32(IMM8) >> 6) & 0b11],
		[4]int {8, 24, 8, 24}[(u32(IMM8) & 0b11)],
		[4]int {9, 9, 25, 25}[(u32(IMM8) & 0b11)],
		[4]int {10, 26, 10, 26}[(u32(IMM8) >> 2) & 0b11],
		[4]int {11, 11, 27, 27}[(u32(IMM8) >> 2) & 0b11],
		[4]int {12, 28, 12, 28}[(u32(IMM8) >> 4) & 0b11],
		[4]int {13, 13, 29, 29}[(u32(IMM8) >> 4) & 0b11],
		[4]int {14, 30, 14, 30}[(u32(IMM8) >> 6) & 0b11],
		[4]int {15, 15, 31, 31}[(u32(IMM8) >> 6) & 0b11],
	)
}

// Blend packed 32-bit integers from `a` and `b` using control mask `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blend_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_blend_epi32 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		[4]int {0, 8, 0, 8}[(u32(IMM8) & 0b11)],
		[4]int {1, 1, 9, 9}[(u32(IMM8) & 0b11)],
		[4]int {2, 10, 2, 10}[(u32(IMM8) >> 2) & 0b11],
		[4]int {3, 3, 11, 11}[(u32(IMM8) >> 2) & 0b11],
		[4]int {4, 12, 4, 12}[(u32(IMM8) >> 4) & 0b11],
		[4]int {5, 5, 13, 13}[(u32(IMM8) >> 4) & 0b11],
		[4]int {6, 14, 6, 14}[(u32(IMM8) >> 6) & 0b11],
		[4]int {7, 7, 15, 15}[(u32(IMM8) >> 6) & 0b11],
	)
}

// Blend packed 8-bit integers from `a` and `b` using `mask`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blendv_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_blendv_epi8 :: #force_inline proc "c" (a, b: __m256i, mask: __m256i) -> __m256i {
	c := simd.lanes_lt(transmute(simd.i8x32)mask, simd.i8x32(0))
	return transmute(__m256i)simd.select(c, transmute(simd.i8x32)b, transmute(simd.i8x32)a)
}

// Broadcast the low packed 8-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastb_epi8)
@(require_results, enable_target_feature="avx2")
_mm_broadcastb_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i8x16)a,
		simd.i8x16(0),
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
	)
}

// Broadcast the low packed 8-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastb_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastb_epi8 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i8x16)a,
		simd.i8x16(0),
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
	)
}

// Broadcast the low packed 16-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastw_epi16)
@(require_results, enable_target_feature="avx2")
_mm_broadcastw_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		simd.i16x8(0),
		0, 0, 0, 0, 0, 0, 0, 0,
	)
}

// Broadcast the low packed 16-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastw_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastw_epi16 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i16x8)a,
		simd.i16x8(0),
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
	)
}

// Broadcast the low packed 32-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastd_epi32)
@(require_results, enable_target_feature="avx2")
_mm_broadcastd_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i32x4)a,
		simd.i32x4(0),
		0, 0, 0, 0,
	)
}

// Broadcast the low packed 32-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastd_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastd_epi32 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)simd.shuffle(
		transmute(simd.i32x4)a,
		simd.i32x4(0),
		0, 0, 0, 0, 0, 0, 0, 0,
	)
}

// Broadcast the low packed 64-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastq_epi64)
@(require_results, enable_target_feature="avx2")
_mm_broadcastq_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return simd.shuffle(a, __m128i(0), 0, 0)
}

// Broadcast the low packed 64-bit integer from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastq_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastq_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return simd.shuffle(a, __m128i(0), 0, 0, 0, 0)
}

// Broadcast the low double-precision (64-bit) floating-point element from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastsd_pd)
@(require_results, enable_target_feature="avx2")
_mm_broadcastsd_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.shuffle(a, __m128d(0), 0, 0)
}

// Broadcast the low double-precision (64-bit) floating-point element from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastsd_pd)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastsd_pd :: #force_inline proc "c" (a: __m128d) -> __m256d {
	return simd.shuffle(a, __m128d(0), 0, 0, 0, 0)
}

// Broadcast 128 bits of integer data from `a` to all 128-bit lanes in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastsi128_si256)
@(require_results, enable_target_feature="avx2")
_mm_broadcastsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return simd.shuffle(a, __m128i(0), 0, 1, 0, 1)
}

// Broadcast 128 bits of integer data from `a` to all 128-bit lanes in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastsi128_si256)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return simd.shuffle(a, __m128i(0), 0, 1, 0, 1)
}

// Broadcast the low single-precision (32-bit) floating-point element from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcastss_ps)
@(require_results, enable_target_feature="avx2")
_mm_broadcastss_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.shuffle(a, __m128(0), 0, 0, 0, 0)
}

// Broadcast the low single-precision (32-bit) floating-point element from `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcastss_ps)
@(require_results, enable_target_feature="avx2")
_mm256_broadcastss_ps :: #force_inline proc "c" (a: __m128) -> __m256 {
	return simd.shuffle(a, __m128(0), 0, 0, 0, 0, 0, 0, 0, 0)
}

// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hadd_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_hadd_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		0, 2, 4, 6, 16, 18, 20, 22, 8, 10, 12, 14, 24, 26, 28, 30,
	)
	d := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		1, 3, 5, 7, 17, 19, 21, 23, 9, 11, 13, 15, 25, 27, 29, 31,
	)
	return transmute(__m256i)simd.add(c, d)
}

// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hadd_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_hadd_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		0, 2, 8, 10, 4, 6, 12, 14,
	)
	d := simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		1, 3, 9, 11, 5, 7, 13, 15,
	)
	return transmute(__m256i)simd.add(c, d)
}

// Horizontally add adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hadds_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_hadds_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		0, 2, 4, 6, 16, 18, 20, 22, 8, 10, 12, 14, 24, 26, 28, 30,
	)
	d := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		1, 3, 5, 7, 17, 19, 21, 23, 9, 11, 13, 15, 25, 27, 29, 31,
	)
	return transmute(__m256i)simd.saturating_add(c, d)
}

// Horizontally subtract adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hsub_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_hsub_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		0, 2, 4, 6, 16, 18, 20, 22, 8, 10, 12, 14, 24, 26, 28, 30,
	)
	d := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		1, 3, 5, 7, 17, 19, 21, 23, 9, 11, 13, 15, 25, 27, 29, 31,
	)
	return transmute(__m256i)simd.sub(c, d)
}

// Horizontally subtract adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hsub_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_hsub_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		0, 2, 8, 10, 4, 6, 12, 14,
	)
	d := simd.shuffle(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		1, 3, 9, 11, 5, 7, 13, 15,
	)
	return transmute(__m256i)simd.sub(c, d)
}

// Horizontally subtract adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hsubs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_hsubs_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	c := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		0, 2, 4, 6, 16, 18, 20, 22, 8, 10, 12, 14, 24, 26, 28, 30,
	)
	d := simd.shuffle(
		transmute(simd.i16x16)a,
		transmute(simd.i16x16)b,
		1, 3, 5, 7, 17, 19, 21, 23, 9, 11, 13, 15, 25, 27, 29, 31,
	)
	return transmute(__m256i)simd.saturating_sub(c, d)
}

// Concatenate pairs of 16-byte blocks in `a` and `b` into a 32-byte temporary result,
// shift the result right by `imm8` bytes, and store the low 16 bytes in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_alignr_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_alignr_epi8 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m256i(0)
	} else when IMM8 > 16 {
		shift :: u32(IMM8) % 16
		c, d := __m256i(0), a
		return transmute(__m256i)simd.shuffle(
			transmute(simd.i8x32)d,
			transmute(simd.i8x32)c,
			(0  + shift) when (0  % 16) < 16 - shift else (0  + 16 + shift),
			(1  + shift) when (1  % 16) < 16 - shift else (1  + 16 + shift),
			(2  + shift) when (2  % 16) < 16 - shift else (2  + 16 + shift),
			(3  + shift) when (3  % 16) < 16 - shift else (3  + 16 + shift),
			(4  + shift) when (4  % 16) < 16 - shift else (4  + 16 + shift),
			(5  + shift) when (5  % 16) < 16 - shift else (5  + 16 + shift),
			(6  + shift) when (6  % 16) < 16 - shift else (6  + 16 + shift),
			(7  + shift) when (7  % 16) < 16 - shift else (7  + 16 + shift),
			(8  + shift) when (8  % 16) < 16 - shift else (8  + 16 + shift),
			(9  + shift) when (9  % 16) < 16 - shift else (9  + 16 + shift),
			(10 + shift) when (10 % 16) < 16 - shift else (10 + 16 + shift),
			(11 + shift) when (11 % 16) < 16 - shift else (11 + 16 + shift),
			(12 + shift) when (12 % 16) < 16 - shift else (12 + 16 + shift),
			(13 + shift) when (13 % 16) < 16 - shift else (13 + 16 + shift),
			(14 + shift) when (14 % 16) < 16 - shift else (14 + 16 + shift),
			(15 + shift) when (15 % 16) < 16 - shift else (15 + 16 + shift),
			(16 + shift) when (16 % 16) < 16 - shift else (16 + 16 + shift),
			(17 + shift) when (17 % 16) < 16 - shift else (17 + 16 + shift),
			(18 + shift) when (18 % 16) < 16 - shift else (18 + 16 + shift),
			(19 + shift) when (19 % 16) < 16 - shift else (19 + 16 + shift),
			(20 + shift) when (20 % 16) < 16 - shift else (20 + 16 + shift),
			(21 + shift) when (21 % 16) < 16 - shift else (21 + 16 + shift),
			(22 + shift) when (22 % 16) < 16 - shift else (22 + 16 + shift),
			(23 + shift) when (23 % 16) < 16 - shift else (23 + 16 + shift),
			(24 + shift) when (24 % 16) < 16 - shift else (24 + 16 + shift),
			(25 + shift) when (25 % 16) < 16 - shift else (25 + 16 + shift),
			(26 + shift) when (26 % 16) < 16 - shift else (26 + 16 + shift),
			(27 + shift) when (27 % 16) < 16 - shift else (27 + 16 + shift),
			(28 + shift) when (28 % 16) < 16 - shift else (28 + 16 + shift),
			(29 + shift) when (29 % 16) < 16 - shift else (29 + 16 + shift),
			(30 + shift) when (30 % 16) < 16 - shift else (30 + 16 + shift),
			(31 + shift) when (31 % 16) < 16 - shift else (31 + 16 + shift),
		)
	} else when IMM8 == 16 {
		return a
	} else {
		shift :: u32(IMM8)
		c, d := a, b
		return transmute(__m256i)simd.shuffle(
			transmute(simd.i8x32)d,
			transmute(simd.i8x32)c,
			(0  + shift) when (0  % 16) < 16 - shift else (0  + 16 + shift),
			(1  + shift) when (1  % 16) < 16 - shift else (1  + 16 + shift),
			(2  + shift) when (2  % 16) < 16 - shift else (2  + 16 + shift),
			(3  + shift) when (3  % 16) < 16 - shift else (3  + 16 + shift),
			(4  + shift) when (4  % 16) < 16 - shift else (4  + 16 + shift),
			(5  + shift) when (5  % 16) < 16 - shift else (5  + 16 + shift),
			(6  + shift) when (6  % 16) < 16 - shift else (6  + 16 + shift),
			(7  + shift) when (7  % 16) < 16 - shift else (7  + 16 + shift),
			(8  + shift) when (8  % 16) < 16 - shift else (8  + 16 + shift),
			(9  + shift) when (9  % 16) < 16 - shift else (9  + 16 + shift),
			(10 + shift) when (10 % 16) < 16 - shift else (10 + 16 + shift),
			(11 + shift) when (11 % 16) < 16 - shift else (11 + 16 + shift),
			(12 + shift) when (12 % 16) < 16 - shift else (12 + 16 + shift),
			(13 + shift) when (13 % 16) < 16 - shift else (13 + 16 + shift),
			(14 + shift) when (14 % 16) < 16 - shift else (14 + 16 + shift),
			(15 + shift) when (15 % 16) < 16 - shift else (15 + 16 + shift),
			(16 + shift) when (16 % 16) < 16 - shift else (16 + 16 + shift),
			(17 + shift) when (17 % 16) < 16 - shift else (17 + 16 + shift),
			(18 + shift) when (18 % 16) < 16 - shift else (18 + 16 + shift),
			(19 + shift) when (19 % 16) < 16 - shift else (19 + 16 + shift),
			(20 + shift) when (20 % 16) < 16 - shift else (20 + 16 + shift),
			(21 + shift) when (21 % 16) < 16 - shift else (21 + 16 + shift),
			(22 + shift) when (22 % 16) < 16 - shift else (22 + 16 + shift),
			(23 + shift) when (23 % 16) < 16 - shift else (23 + 16 + shift),
			(24 + shift) when (24 % 16) < 16 - shift else (24 + 16 + shift),
			(25 + shift) when (25 % 16) < 16 - shift else (25 + 16 + shift),
			(26 + shift) when (26 % 16) < 16 - shift else (26 + 16 + shift),
			(27 + shift) when (27 % 16) < 16 - shift else (27 + 16 + shift),
			(28 + shift) when (28 % 16) < 16 - shift else (28 + 16 + shift),
			(29 + shift) when (29 % 16) < 16 - shift else (29 + 16 + shift),
			(30 + shift) when (30 % 16) < 16 - shift else (30 + 16 + shift),
			(31 + shift) when (31 % 16) < 16 - shift else (31 + 16 + shift),
		)
	}
}

// Shift 128-bit lanes in `a` left by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_bslli_epi128)
@(require_results, enable_target_feature="avx2")
_mm256_bslli_epi128 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8) & u32(max(u8))
	return transmute(__m256i)simd.shuffle(
		simd.i8x32(0),
		transmute(simd.i8x32)a,
		0 when shift > 15 || (0  % 16) < shift else (32 + 0  - shift),
		0 when shift > 15 || (1  % 16) < shift else (32 + 1  - shift),
		0 when shift > 15 || (2  % 16) < shift else (32 + 2  - shift),
		0 when shift > 15 || (3  % 16) < shift else (32 + 3  - shift),
		0 when shift > 15 || (4  % 16) < shift else (32 + 4  - shift),
		0 when shift > 15 || (5  % 16) < shift else (32 + 5  - shift),
		0 when shift > 15 || (6  % 16) < shift else (32 + 6  - shift),
		0 when shift > 15 || (7  % 16) < shift else (32 + 7  - shift),
		0 when shift > 15 || (8  % 16) < shift else (32 + 8  - shift),
		0 when shift > 15 || (9  % 16) < shift else (32 + 9  - shift),
		0 when shift > 15 || (10 % 16) < shift else (32 + 10 - shift),
		0 when shift > 15 || (11 % 16) < shift else (32 + 11 - shift),
		0 when shift > 15 || (12 % 16) < shift else (32 + 12 - shift),
		0 when shift > 15 || (13 % 16) < shift else (32 + 13 - shift),
		0 when shift > 15 || (14 % 16) < shift else (32 + 14 - shift),
		0 when shift > 15 || (15 % 16) < shift else (32 + 15 - shift),
		0 when shift > 15 || (16 % 16) < shift else (32 + 16 - shift),
		0 when shift > 15 || (17 % 16) < shift else (32 + 17 - shift),
		0 when shift > 15 || (18 % 16) < shift else (32 + 18 - shift),
		0 when shift > 15 || (19 % 16) < shift else (32 + 19 - shift),
		0 when shift > 15 || (20 % 16) < shift else (32 + 20 - shift),
		0 when shift > 15 || (21 % 16) < shift else (32 + 21 - shift),
		0 when shift > 15 || (22 % 16) < shift else (32 + 22 - shift),
		0 when shift > 15 || (23 % 16) < shift else (32 + 23 - shift),
		0 when shift > 15 || (24 % 16) < shift else (32 + 24 - shift),
		0 when shift > 15 || (25 % 16) < shift else (32 + 25 - shift),
		0 when shift > 15 || (26 % 16) < shift else (32 + 26 - shift),
		0 when shift > 15 || (27 % 16) < shift else (32 + 27 - shift),
		0 when shift > 15 || (28 % 16) < shift else (32 + 28 - shift),
		0 when shift > 15 || (29 % 16) < shift else (32 + 29 - shift),
		0 when shift > 15 || (30 % 16) < shift else (32 + 30 - shift),
		0 when shift > 15 || (31 % 16) < shift else (32 + 31 - shift),
	)
}

// Shift 128-bit lanes in `a` right by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_bsrli_epi128)
@(require_results, enable_target_feature="avx2")
_mm256_bsrli_epi128 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8) & u32(max(u8))
	return transmute(__m256i)simd.shuffle(
		simd.i8x32(0),
		transmute(simd.i8x32)a,
		0 when shift > 15 || (15 - (0  % 16)) < shift else (32 + 0  + shift),
		0 when shift > 15 || (15 - (1  % 16)) < shift else (32 + 1  + shift),
		0 when shift > 15 || (15 - (2  % 16)) < shift else (32 + 2  + shift),
		0 when shift > 15 || (15 - (3  % 16)) < shift else (32 + 3  + shift),
		0 when shift > 15 || (15 - (4  % 16)) < shift else (32 + 4  + shift),
		0 when shift > 15 || (15 - (5  % 16)) < shift else (32 + 5  + shift),
		0 when shift > 15 || (15 - (6  % 16)) < shift else (32 + 6  + shift),
		0 when shift > 15 || (15 - (7  % 16)) < shift else (32 + 7  + shift),
		0 when shift > 15 || (15 - (8  % 16)) < shift else (32 + 8  + shift),
		0 when shift > 15 || (15 - (9  % 16)) < shift else (32 + 9  + shift),
		0 when shift > 15 || (15 - (10 % 16)) < shift else (32 + 10 + shift),
		0 when shift > 15 || (15 - (11 % 16)) < shift else (32 + 11 + shift),
		0 when shift > 15 || (15 - (12 % 16)) < shift else (32 + 12 + shift),
		0 when shift > 15 || (15 - (13 % 16)) < shift else (32 + 13 + shift),
		0 when shift > 15 || (15 - (14 % 16)) < shift else (32 + 14 + shift),
		0 when shift > 15 || (15 - (15 % 16)) < shift else (32 + 15 + shift),
		0 when shift > 15 || (15 - (16 % 16)) < shift else (32 + 16 + shift),
		0 when shift > 15 || (15 - (17 % 16)) < shift else (32 + 17 + shift),
		0 when shift > 15 || (15 - (18 % 16)) < shift else (32 + 18 + shift),
		0 when shift > 15 || (15 - (19 % 16)) < shift else (32 + 19 + shift),
		0 when shift > 15 || (15 - (20 % 16)) < shift else (32 + 20 + shift),
		0 when shift > 15 || (15 - (21 % 16)) < shift else (32 + 21 + shift),
		0 when shift > 15 || (15 - (22 % 16)) < shift else (32 + 22 + shift),
		0 when shift > 15 || (15 - (23 % 16)) < shift else (32 + 23 + shift),
		0 when shift > 15 || (15 - (24 % 16)) < shift else (32 + 24 + shift),
		0 when shift > 15 || (15 - (25 % 16)) < shift else (32 + 25 + shift),
		0 when shift > 15 || (15 - (26 % 16)) < shift else (32 + 26 + shift),
		0 when shift > 15 || (15 - (27 % 16)) < shift else (32 + 27 + shift),
		0 when shift > 15 || (15 - (28 % 16)) < shift else (32 + 28 + shift),
		0 when shift > 15 || (15 - (29 % 16)) < shift else (32 + 29 + shift),
		0 when shift > 15 || (15 - (30 % 16)) < shift else (32 + 30 + shift),
		0 when shift > 15 || (15 - (31 % 16)) < shift else (32 + 31 + shift),
	)
}

// Shift 128-bit lanes in `a` left by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_slli_si256)
@(require_results, enable_target_feature="avx2")
_mm256_slli_si256 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8) & u32(max(u8))
	return transmute(__m256i)simd.shuffle(
		simd.i8x32(0),
		transmute(simd.i8x32)a,
		0 when shift > 15 || (0  % 16) < shift else (32 + 0  - shift),
		0 when shift > 15 || (1  % 16) < shift else (32 + 1  - shift),
		0 when shift > 15 || (2  % 16) < shift else (32 + 2  - shift),
		0 when shift > 15 || (3  % 16) < shift else (32 + 3  - shift),
		0 when shift > 15 || (4  % 16) < shift else (32 + 4  - shift),
		0 when shift > 15 || (5  % 16) < shift else (32 + 5  - shift),
		0 when shift > 15 || (6  % 16) < shift else (32 + 6  - shift),
		0 when shift > 15 || (7  % 16) < shift else (32 + 7  - shift),
		0 when shift > 15 || (8  % 16) < shift else (32 + 8  - shift),
		0 when shift > 15 || (9  % 16) < shift else (32 + 9  - shift),
		0 when shift > 15 || (10 % 16) < shift else (32 + 10 - shift),
		0 when shift > 15 || (11 % 16) < shift else (32 + 11 - shift),
		0 when shift > 15 || (12 % 16) < shift else (32 + 12 - shift),
		0 when shift > 15 || (13 % 16) < shift else (32 + 13 - shift),
		0 when shift > 15 || (14 % 16) < shift else (32 + 14 - shift),
		0 when shift > 15 || (15 % 16) < shift else (32 + 15 - shift),
		0 when shift > 15 || (16 % 16) < shift else (32 + 16 - shift),
		0 when shift > 15 || (17 % 16) < shift else (32 + 17 - shift),
		0 when shift > 15 || (18 % 16) < shift else (32 + 18 - shift),
		0 when shift > 15 || (19 % 16) < shift else (32 + 19 - shift),
		0 when shift > 15 || (20 % 16) < shift else (32 + 20 - shift),
		0 when shift > 15 || (21 % 16) < shift else (32 + 21 - shift),
		0 when shift > 15 || (22 % 16) < shift else (32 + 22 - shift),
		0 when shift > 15 || (23 % 16) < shift else (32 + 23 - shift),
		0 when shift > 15 || (24 % 16) < shift else (32 + 24 - shift),
		0 when shift > 15 || (25 % 16) < shift else (32 + 25 - shift),
		0 when shift > 15 || (26 % 16) < shift else (32 + 26 - shift),
		0 when shift > 15 || (27 % 16) < shift else (32 + 27 - shift),
		0 when shift > 15 || (28 % 16) < shift else (32 + 28 - shift),
		0 when shift > 15 || (29 % 16) < shift else (32 + 29 - shift),
		0 when shift > 15 || (30 % 16) < shift else (32 + 30 - shift),
		0 when shift > 15 || (31 % 16) < shift else (32 + 31 - shift),
	)
}

// Shift 128-bit lanes in `a` right by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_srli_si256)
@(require_results, enable_target_feature="avx2")
_mm256_srli_si256 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8) & u32(max(u8))
	return transmute(__m256i)simd.shuffle(
		simd.i8x32(0),
		transmute(simd.i8x32)a,
		0 when shift > 15 || (15 - (0  % 16)) < shift else (32 + 0  + shift),
		0 when shift > 15 || (15 - (1  % 16)) < shift else (32 + 1  + shift),
		0 when shift > 15 || (15 - (2  % 16)) < shift else (32 + 2  + shift),
		0 when shift > 15 || (15 - (3  % 16)) < shift else (32 + 3  + shift),
		0 when shift > 15 || (15 - (4  % 16)) < shift else (32 + 4  + shift),
		0 when shift > 15 || (15 - (5  % 16)) < shift else (32 + 5  + shift),
		0 when shift > 15 || (15 - (6  % 16)) < shift else (32 + 6  + shift),
		0 when shift > 15 || (15 - (7  % 16)) < shift else (32 + 7  + shift),
		0 when shift > 15 || (15 - (8  % 16)) < shift else (32 + 8  + shift),
		0 when shift > 15 || (15 - (9  % 16)) < shift else (32 + 9  + shift),
		0 when shift > 15 || (15 - (10 % 16)) < shift else (32 + 10 + shift),
		0 when shift > 15 || (15 - (11 % 16)) < shift else (32 + 11 + shift),
		0 when shift > 15 || (15 - (12 % 16)) < shift else (32 + 12 + shift),
		0 when shift > 15 || (15 - (13 % 16)) < shift else (32 + 13 + shift),
		0 when shift > 15 || (15 - (14 % 16)) < shift else (32 + 14 + shift),
		0 when shift > 15 || (15 - (15 % 16)) < shift else (32 + 15 + shift),
		0 when shift > 15 || (15 - (16 % 16)) < shift else (32 + 16 + shift),
		0 when shift > 15 || (15 - (17 % 16)) < shift else (32 + 17 + shift),
		0 when shift > 15 || (15 - (18 % 16)) < shift else (32 + 18 + shift),
		0 when shift > 15 || (15 - (19 % 16)) < shift else (32 + 19 + shift),
		0 when shift > 15 || (15 - (20 % 16)) < shift else (32 + 20 + shift),
		0 when shift > 15 || (15 - (21 % 16)) < shift else (32 + 21 + shift),
		0 when shift > 15 || (15 - (22 % 16)) < shift else (32 + 22 + shift),
		0 when shift > 15 || (15 - (23 % 16)) < shift else (32 + 23 + shift),
		0 when shift > 15 || (15 - (24 % 16)) < shift else (32 + 24 + shift),
		0 when shift > 15 || (15 - (25 % 16)) < shift else (32 + 25 + shift),
		0 when shift > 15 || (15 - (26 % 16)) < shift else (32 + 26 + shift),
		0 when shift > 15 || (15 - (27 % 16)) < shift else (32 + 27 + shift),
		0 when shift > 15 || (15 - (28 % 16)) < shift else (32 + 28 + shift),
		0 when shift > 15 || (15 - (29 % 16)) < shift else (32 + 29 + shift),
		0 when shift > 15 || (15 - (30 % 16)) < shift else (32 + 30 + shift),
		0 when shift > 15 || (15 - (31 % 16)) < shift else (32 + 31 + shift),
	)
}

// Compare packed 8-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpeq_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_cmpeq_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_eq(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Compare packed 16-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpeq_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_cmpeq_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_eq(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Compare packed 32-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpeq_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cmpeq_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_eq(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Compare packed 64-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpeq_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cmpeq_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_eq(a, b)
}

// Compare packed signed 8-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpgt_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_cmpgt_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_gt(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Compare packed signed 16-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpgt_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_cmpgt_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_gt(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Compare packed signed 32-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpgt_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cmpgt_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_gt(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// Compare packed signed 64-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmpgt_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cmpgt_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.lanes_gt(a, b)
}

// Extract an 8-bit integer from `a`, selected with `index`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extract_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_extract_epi8 :: #force_inline proc "c" (a: __m256i, $INDEX: i32) -> i32 where 0 <= INDEX, INDEX < 32 {
	return cast(i32)simd.extract(transmute(simd.u8x32)a, uint(INDEX))
}

// Extract a 16-bit integer from `a`, selected with `index`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extract_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_extract_epi16 :: #force_inline proc "c" (a: __m256i, $INDEX: i32) -> i32 where 0 <= INDEX, INDEX < 16 {
	return cast(i32)simd.extract(transmute(simd.u16x16)a, uint(INDEX))
}

// Extract 128 bits (composed of integer data) from `a`, selected with `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extracti128_si256)
@(require_results, enable_target_feature="avx2")
_mm256_extracti128_si256 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		__m256i(0),
		[2]int {0, 2}[u32(IMM8)],
		[2]int {1, 3}[u32(IMM8)],
	)
}

// Copy `a` to `dst`, then insert 128 bits (composed of integer data) from `b` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_inserti128_si256)
@(require_results, enable_target_feature="avx,avx2")
_mm256_inserti128_si256 :: #force_inline proc "c" (a: __m256i, b: __m128i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		_mm256_castsi128_si256(b),
		[2]int {4, 0}[u32(IMM8)],
		[2]int {5, 1}[u32(IMM8)],
		[2]int {2, 4}[u32(IMM8)],
		[2]int {3, 5}[u32(IMM8)],
	)
}

// Sign extend packed 8-bit integers in `a` to packed 16-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi8_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)(cast(simd.i16x16)(transmute(simd.i8x16)a))
}

// Sign extend the lower eight signed 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi8_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	b := simd.shuffle(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)a,
		0, 1, 2, 3, 4, 5, 6, 7,
	)
	return transmute(__m256i)(cast(simd.i32x8)b)
}

// Sign extend the lower four signed 8-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi8_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return cast(simd.i64x4)simd.shuffle(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)a,
		0, 1, 2, 3,
	)
}

// Zero extend packed unsigned 8-bit integers in `a` to packed 16-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu8_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)(cast(simd.u16x16)(transmute(simd.u8x16)a))
}

// Zero extend the lower eight unsigned 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu8_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	b := simd.shuffle(
		transmute(simd.u8x16)a,
		transmute(simd.u8x16)a,
		0, 1, 2, 3, 4, 5, 6, 7,
	)
	return transmute(__m256i)(cast(simd.u32x8)b)
}

// Zero extend the lower four unsigned 8-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu8_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	b := simd.shuffle(
		transmute(simd.u8x16)a,
		transmute(simd.u8x16)a,
		0, 1, 2, 3,
	)
	return transmute(__m256i)(cast(simd.u64x4)b)
}

// Sign extend packed 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi16_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)(cast(simd.i32x8)(transmute(simd.i16x8)a))
}

// Sign extend the lower four signed 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi16_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return cast(simd.i64x4)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)a,
		0, 1, 2, 3,
	)
}

// Zero extend packed unsigned 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu16_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)(cast(simd.u32x8)(transmute(simd.u16x8)a))
}

// Zero extend the lower four unsigned 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu16_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	b := simd.shuffle(
		transmute(simd.u16x8)a,
		transmute(simd.u16x8)a,
		0, 1, 2, 3,
	)
	return transmute(__m256i)(cast(simd.u64x4)b)
}

// Sign extend packed 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi32_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepi32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return cast(simd.i64x4)(transmute(simd.i32x4)a)
}

// Zero extend packed unsigned 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu32_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_cvtepu32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return transmute(__m256i)(cast(simd.u64x4)(transmute(simd.u32x4)a))
}

// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
// Horizontally add adjacent pairs of intermediate 32-bit integers, and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_madd_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_madd_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_pmaddwd(transmute(simd.i16x16)a, transmute(simd.i16x16)b)
}

// Vertically multiply each unsigned 8-bit integer from `a` with the corresponding signed 8-bit integer from `b`,
// producing intermediate signed 16-bit integers. Horizontally add adjacent pairs of intermediate signed 16-bit integers,
// and pack the saturated results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maddubs_epi16)
@(require_results, enable_target_feature="avx2")
_mm256_maddubs_epi16 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_pmaddubsw(transmute(simd.u8x32)a, transmute(simd.i8x32)b)
}

// Create mask from the most significant bit of each 8-bit element in `a`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_movemask_epi8)
@(require_results, enable_target_feature="avx2")
_mm256_movemask_epi8 :: #force_inline proc "c" (a: __m256i) -> i32 {
	return transmute(i32)simd.extract_msbs(transmute(simd.i8x32)a)
}

// Compute the sum of absolute differences (SADs) of quadruplets of unsigned 8-bit integers in `a` compared to those in `b`,
// and store the 16-bit results in `dst`. Eight SADs are performed for each 128-bit lane using one quadruplet from `b` and
// eight quadruplets from `a`. One quadruplet is selected from `b` starting at on the offset specified in `imm8`.
// Eight quadruplets are formed from sequential 8-bit integers selected from `a` starting at the offset specified in `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mpsadbw_epu8)
@(require_results, enable_target_feature="avx2")
_mm256_mpsadbw_epu8 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)llvm_mpsadbw(
		transmute(simd.u8x32)a,
		transmute(simd.u8x32)b,
		transmute(i8)(cast(u8)IMM8),
	)
}

// Shuffle 128-bits (composed of integer data) selected by `imm8` from `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute2x128_si256)
@(require_results, enable_target_feature="avx2")
_mm256_permute2x128_si256 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	c := simd.shuffle(
		a,
		b,
		2 * ((u32(IMM8) & 0xf) & 0b11) + 0,
		2 * ((u32(IMM8) & 0xf) & 0b11) + 1,
		2 * (((u32(IMM8) & 0xf0) >> 4) & 0b11) + 0,
		2 * (((u32(IMM8) & 0xf0) >> 4) & 0b11) + 1,
	)
	return simd.shuffle(
		c,
		__m256i(0),
		4 when ((u32(IMM8) & 0xf) & 0b1000) != 0 else 0,
		4 when ((u32(IMM8) & 0xf) & 0b1000) != 0 else 1,
		4 when (((u32(IMM8) & 0xf0) >> 4) & 0b1000) != 0 else 2,
		4 when (((u32(IMM8) & 0xf0) >> 4) & 0b1000) != 0 else 3,
	)
}

// Shuffle 64-bit integers in `a` across lanes using the control in `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute4x64_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_permute4x64_epi64 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		__m256i(0),
		(u32(IMM8) & 0b11),
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
	)
}

// Shuffle double-precision (64-bit) floating-point elements in `a` across lanes using the control in `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute4x64_pd)
@(require_results, enable_target_feature="avx2")
_mm256_permute4x64_pd :: #force_inline proc "c" (a: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		__m256d(0),
		(u32(IMM8) & 0b11),
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
	)
}

// Shuffle 32-bit integers in `a` across lanes using the corresponding index in `idx`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar8x32_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_permutevar8x32_epi32 :: #force_inline proc "c" (a: __m256i, idx: __m256i) -> __m256i {
	return transmute(__m256i)llvm_permd(transmute(simd.u32x8)a, transmute(simd.u32x8)idx)
}

// Shuffle single-precision (32-bit) floating-point elements in `a` across lanes using the corresponding index in `idx`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar8x32_ps)
@(require_results, enable_target_feature="avx2")
_mm256_permutevar8x32_ps :: #force_inline proc "c" (a: __m256, idx: __m256i) -> __m256 {
	return llvm_permps(a, transmute(simd.i32x8)idx)
}

// Load packed 32-bit integers from memory into `dst` using `mask`
// (elements are zeroed out when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskload_epi32)
@(require_results, enable_target_feature="avx2")
_mm_maskload_epi32 :: #force_inline proc "c" (mem_addr: ^i32, mask: __m128i) -> __m128i {
	m := simd.shr(transmute(simd.i32x4)mask, simd.u32x4(31))
	return transmute(__m128i)simd.masked_load(mem_addr, simd.i32x4(0), m)
}

// Load packed 32-bit integers from memory into `dst` using `mask`
// (elements are zeroed out when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskload_epi32)
@(require_results, enable_target_feature="avx2")
_mm256_maskload_epi32 :: #force_inline proc "c" (mem_addr: ^i32, mask: __m256i) -> __m256i {
	m := simd.shr(transmute(simd.i32x8)mask, simd.u32x8(31))
	return transmute(__m256i)simd.masked_load(mem_addr, simd.i32x8(0), m)
}

// Load packed 64-bit integers from memory into `dst` using `mask`
// (elements are zeroed out when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskload_epi64)
@(require_results, enable_target_feature="avx2")
_mm_maskload_epi64 :: #force_inline proc "c" (mem_addr: ^i64, mask: __m128i) -> __m128i {
	m := simd.shr(mask, simd.u64x2(63))
	return simd.masked_load(mem_addr, __m128i(0), m)
}

// Load packed 64-bit integers from memory into `dst` using `mask`
// (elements are zeroed out when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskload_epi64)
@(require_results, enable_target_feature="avx2")
_mm256_maskload_epi64 :: #force_inline proc "c" (mem_addr: ^i64, mask: __m256i) -> __m256i {
	m := simd.shr(mask, simd.u64x4(63))
	return simd.masked_load(mem_addr, __m256i(0), m)
}

// Store packed 32-bit integers from `a` into memory using `mask`
// (elements are not stored when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskstore_epi32)
@(enable_target_feature="avx2")
_mm_maskstore_epi32 :: #force_inline proc "c" (mem_addr: ^i32, mask: __m128i, a: __m128i) {
	m := simd.shr(transmute(simd.i32x4)mask, simd.u32x4(31))
	simd.masked_store(mem_addr, transmute(simd.i32x4)a, m)
}

// Store packed 32-bit integers from `a` into memory using `mask`
// (elements are not stored when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskstore_epi32)
@(enable_target_feature="avx2")
_mm256_maskstore_epi32 :: #force_inline proc "c" (mem_addr: ^i32, mask: __m256i, a: __m256i) {
	m := simd.shr(transmute(simd.i32x8)mask, simd.u32x8(31))
	simd.masked_store(mem_addr, transmute(simd.i32x8)a, m)
}

// Store packed 64-bit integers from `a` into memory using `mask`
// (elements are not stored when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskstore_epi64)
@(enable_target_feature="avx2")
_mm_maskstore_epi64 :: #force_inline proc "c" (mem_addr: ^i64, mask: __m128i, a: __m128i) {
	m := simd.shr(mask, simd.u64x2(63))
	simd.masked_store(mem_addr, a, m)
}

// Store packed 64-bit integers from `a` into memory using `mask`
// (elements are not stored when the highest bit is not set in the corresponding element).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskstore_epi64)
@(enable_target_feature="avx2")
_mm256_maskstore_epi64 :: #force_inline proc "c" (mem_addr: ^i64, mask: __m256i, a: __m256i) {
	m := simd.shr(mask, simd.u64x4(63))
	simd.masked_store(mem_addr, a, m)
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.avx2.psign.b")     llvm_psignb    :: proc(a: simd.i8x32, b: simd.i8x32) -> simd.i8x32 ---
	@(link_name="llvm.x86.avx2.psign.w")     llvm_psignw    :: proc(a: simd.i16x16, b: simd.i16x16) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.psign.d")     llvm_psignd    :: proc(a: simd.i32x8, b: simd.i32x8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx2.pmul.hr.sw")  llvm_pmulhrsw  :: proc(a: simd.i16x16, b: simd.i16x16) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.packsswb")    llvm_packsswb  :: proc(a: simd.i16x16, b: simd.i16x16) -> simd.i8x32 ---
	@(link_name="llvm.x86.avx2.packssdw")    llvm_packssdw  :: proc(a: simd.i32x8, b: simd.i32x8) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.packuswb")    llvm_packuswb  :: proc(a: simd.i16x16, b: simd.i16x16) -> simd.u8x32 ---
	@(link_name="llvm.x86.avx2.packusdw")    llvm_packusdw  :: proc(a: simd.i32x8, b: simd.i32x8) -> simd.u16x16 ---
	@(link_name="llvm.x86.avx2.psad.bw")     llvm_psadbw    :: proc(a: simd.u8x32, b: simd.u8x32) -> simd.u64x4 ---
	@(link_name="llvm.x86.avx2.pshuf.b")     llvm_pshufb    :: proc(a: simd.u8x32, b: simd.u8x32) -> simd.u8x32 ---
	@(link_name="llvm.x86.avx2.psll.w")      llvm_psllw     :: proc(a: simd.i16x16, count: simd.i16x8) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.psll.d")      llvm_pslld     :: proc(a: simd.i32x8, count: simd.i32x4) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx2.psll.q")      llvm_psllq     :: proc(a: simd.i64x4, count: simd.i64x2) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx2.psrl.w")      llvm_psrlw     :: proc(a: simd.i16x16, count: simd.i16x8) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.psrl.d")      llvm_psrld     :: proc(a: simd.i32x8, count: simd.i32x4) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx2.psrl.q")      llvm_psrlq     :: proc(a: simd.i64x4, count: simd.i64x2) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx2.psra.w")      llvm_psraw     :: proc(a: simd.i16x16, count: simd.i16x8) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.psra.d")      llvm_psrad     :: proc(a: simd.i32x8, count: simd.i32x4) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx2.pmadd.wd")    llvm_pmaddwd   :: proc(a: simd.i16x16, b: simd.i16x16) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx2.pmadd.ub.sw") llvm_pmaddubsw :: proc(a: simd.u8x32, b: simd.i8x32) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx2.mpsadbw")     llvm_mpsadbw   :: proc(a: simd.u8x32, b: simd.u8x32, imm8: i8) -> simd.u16x16 ---
	@(link_name="llvm.x86.avx2.permd")       llvm_permd     :: proc(a: simd.u32x8, b: simd.u32x8) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx2.permps")      llvm_permps    :: proc(a: simd.f32x8, b: simd.i32x8) -> simd.f32x8 ---
}
