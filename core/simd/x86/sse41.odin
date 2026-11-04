#+build i386, amd64
package simd_x86

import "core:simd"

_MM_FROUND_TO_NEAREST_INT : i32 : 0x00
_MM_FROUND_TO_NEG_INF     : i32 : 0x01
_MM_FROUND_TO_POS_INF     : i32 : 0x02
_MM_FROUND_TO_ZERO        : i32 : 0x03
_MM_FROUND_CUR_DIRECTION  : i32 : 0x04
_MM_FROUND_RAISE_EXC      : i32 : 0x00
_MM_FROUND_NO_EXC         : i32 : 0x08
_MM_FROUND_NINT           : i32 : 0x00
_MM_FROUND_FLOOR          : i32 : _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEG_INF
_MM_FROUND_CEIL           : i32 : _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_POS_INF
_MM_FROUND_TRUNC          : i32 : _MM_FROUND_RAISE_EXC | _MM_FROUND_TO_ZERO
_MM_FROUND_RINT           : i32 : _MM_FROUND_RAISE_EXC | _MM_FROUND_CUR_DIRECTION
_MM_FROUND_NEARBYINT      : i32 : _MM_FROUND_NO_EXC    | _MM_FROUND_CUR_DIRECTION

// Blend packed 8-bit integers from `a` and `b` using `mask`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blendv_epi8)
@(require_results, enable_target_feature="sse4.1")
_mm_blendv_epi8 :: #force_inline proc "c" (a, b: __m128i, mask: __m128i) -> __m128i {
	c := simd.lanes_lt(transmute(simd.i8x16)mask, simd.i8x16(0))
	return transmute(__m128i)simd.select(c, transmute(simd.i8x16)b, transmute(simd.i8x16)a)
}

// Blend packed 16-bit integers from `a` and `b` using control mask `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blend_epi16)
@(require_results, enable_target_feature="sse4.1")
_mm_blend_epi16 :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)b,
		[2]int {0, 8 }[(u32(IMM8) >> 0) & 1],
		[2]int {1, 9 }[(u32(IMM8) >> 1) & 1],
		[2]int {2, 10}[(u32(IMM8) >> 2) & 1],
		[2]int {3, 11}[(u32(IMM8) >> 3) & 1],
		[2]int {4, 12}[(u32(IMM8) >> 4) & 1],
		[2]int {5, 13}[(u32(IMM8) >> 5) & 1],
		[2]int {6, 14}[(u32(IMM8) >> 6) & 1],
		[2]int {7, 15}[(u32(IMM8) >> 7) & 1],
	)
}

// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using `mask`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blendv_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_blendv_pd :: #force_inline proc "c" (a, b: __m128d, mask: __m128d) -> __m128d {
	c := simd.lanes_lt(transmute(simd.i64x2)mask, simd.i64x2(0))
	return simd.select(c, b, a)
}

// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using `mask`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blendv_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_blendv_ps :: #force_inline proc "c" (a, b, mask: __m128) -> __m128 {
	c := simd.lanes_lt(transmute(simd.i32x4)mask, simd.i32x4(0))
	return simd.select(c, b, a)
}

// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using control mask `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blend_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_blend_pd :: #force_inline proc "c" (a, b: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 4 {
	return simd.shuffle(
		a,
		b,
		[2]int {0, 2}[(u32(IMM8) >> 0) & 1],
		[2]int {1, 3}[(u32(IMM8) >> 1) & 1],
	)
}

// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using control mask `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_blend_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_blend_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 16 {
	return simd.shuffle(
		a,
		b,
		[2]int {0, 4}[(u32(IMM8) >> 0) & 1],
		[2]int {1, 5}[(u32(IMM8) >> 1) & 1],
		[2]int {2, 6}[(u32(IMM8) >> 2) & 1],
		[2]int {3, 7}[(u32(IMM8) >> 3) & 1],
	)
}

// Extract a single-precision (32-bit) floating-point element from `a`, selected with `imm8`,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_extract_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_extract_ps :: #force_inline proc "c" (a: __m128, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 4 {
	return transmute(i32)simd.extract(a, IMM8)
}

// Extract an 8-bit integer from `a`, selected with `imm8`, and store the result in the lower element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_extract_epi8)
@(require_results, enable_target_feature="sse4.1")
_mm_extract_epi8 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 16 {
	return i32(simd.extract(transmute(simd.u8x16)a, IMM8))
}

// Extract a 32-bit integer from `a`, selected with `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_extract_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_extract_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 4 {
	return simd.extract(transmute(simd.i32x4)a, IMM8)
}

// Copy `a` to `tmp`, then insert a single-precision (32-bit) floating-point element from `b`
// into `tmp` using the control in `imm8`. Store `tmp` to `dst` using the mask in `imm8`
// (elements are zeroed out when the corresponding bit is set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_insert_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_insert_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_insertps(a, b, cast(u8)IMM8)
}

// Copy `a` to `dst`, and insert the lower 8-bit integer from `i` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_insert_epi8)
@(require_results, enable_target_feature="sse4.1")
_mm_insert_epi8 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 16 {
	return transmute(__m128i)simd.replace(transmute(simd.i8x16)a, IMM8, i8(i))
}

// Copy `a` to `dst`, and insert the 32-bit integer `i` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_insert_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_insert_epi32 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 4 {
	return transmute(__m128i)simd.replace(transmute(simd.i32x4)a, IMM8, i)
}

// Compare packed signed 8-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epi8)
@(require_results, enable_target_feature="sse4.1")
_mm_max_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compare packed unsigned 16-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epu16)
@(require_results, enable_target_feature="sse4.1")
_mm_max_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.u16x8)a, transmute(simd.u16x8)b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_max_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epu32)
@(require_results, enable_target_feature="sse4.1")
_mm_max_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.u32x4)a, transmute(simd.u32x4)b)
}

// Compare packed signed 8-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epi8)
@(require_results, enable_target_feature="sse4.1")
_mm_min_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compare packed unsigned 16-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epu16)
@(require_results, enable_target_feature="sse4.1")
_mm_min_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.u16x8)a, transmute(simd.u16x8)b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_min_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epu32)
@(require_results, enable_target_feature="sse4.1")
_mm_min_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.u32x4)a, transmute(simd.u32x4)b)
}

// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_packus_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_packus_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_packusdw(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compare packed 64-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cmpeq_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(a, b)
}

// Sign extend packed 8-bit integers in `a` to packed 16-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi8_epi16)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i8x16)a
	c := simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
	return transmute(__m128i)(cast(simd.i16x8)c)
}

// Sign extend packed 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi8_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i8x16)a
	c := simd.shuffle(b, b, 0, 1, 2, 3)
	return transmute(__m128i)(cast(simd.i32x4)c)
}

// Sign extend packed 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi8_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i8x16)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Sign extend packed 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi16_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i16x8)a
	c := simd.shuffle(b, b, 0, 1, 2, 3)
	return transmute(__m128i)(cast(simd.i32x4)c)
}

// Sign extend packed 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi16_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i16x8)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Sign extend packed 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi32_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepi32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i32x4)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Zero extend packed unsigned 8-bit integers in `a` to packed 16-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu8_epi16)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u8x16)a
	c := simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
	return transmute(__m128i)(cast(simd.i16x8)c)
}

// Zero extend packed unsigned 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu8_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u8x16)a
	c := simd.shuffle(b, b, 0, 1, 2, 3)
	return transmute(__m128i)(cast(simd.i32x4)c)
}

// Zero extend packed unsigned 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu8_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u8x16)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Zero extend packed unsigned 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu16_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu16_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u16x8)a
	c := simd.shuffle(b, b, 0, 1, 2, 3)
	return transmute(__m128i)(cast(simd.i32x4)c)
}

// Zero extend packed unsigned 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu16_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u16x8)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Zero extend packed unsigned 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu32_epi64)
@(require_results, enable_target_feature="sse4.1")
_mm_cvtepu32_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.u32x4)a
	c := simd.shuffle(b, b, 0, 1)
	return cast(__m128i)c
}

// Conditionally multiply the packed double-precision (64-bit) floating-point elements in `a` and `b`
// using the high 4 bits in `imm8`, sum the four products, and conditionally store the sum in `dst`
// using the low 4 bits of `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_dp_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_dp_pd :: #force_inline proc "c" (a, b: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_dppd(a, b, cast(u8)IMM8)
}

// Conditionally multiply the packed single-precision (32-bit) floating-point elements in `a` and `b`
// using the high 4 bits in `imm8`, sum the four products, and conditionally store the sum in `dst`
// using the low 4 bits of `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_dp_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_dp_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_dpps(a, b, cast(u8)IMM8)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` down to an integer value,
// and store the results as packed double-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_floor_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_floor_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.floor(a)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` down to an integer value,
// and store the results as packed single-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_floor_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_floor_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.floor(a)
}

// Round the lower double-precision (64-bit) floating-point element in `b` down to an integer value,
// store the result as a double-precision floating-point element in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_floor_sd)
@(require_results, enable_target_feature="sse4.1")
_mm_floor_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_roundsd(a, b, _MM_FROUND_FLOOR)
}

// Round the lower single-precision (32-bit) floating-point element in `b` down to an integer value,
// store the result as a single-precision floating-point element in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_floor_ss)
@(require_results, enable_target_feature="sse4.1")
_mm_floor_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_roundss(a, b, _MM_FROUND_FLOOR)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` up to an integer value,
// and store the results as packed double-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ceil_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.ceil(a)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` up to an integer value,
// and store the results as packed single-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ceil_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.ceil(a)
}

// Round the lower double-precision (64-bit) floating-point element in `b` up to an integer value,
// store the result as a double-precision floating-point element in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ceil_sd)
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_roundsd(a, b, _MM_FROUND_CEIL)
}

// Round the lower single-precision (32-bit) floating-point element in `b` up to an integer value,
// store the result as a single-precision floating-point element in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ceil_ss)
@(require_results, enable_target_feature="sse4.1")
_mm_ceil_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_roundss(a, b, _MM_FROUND_CEIL)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` using the rounding parameter,
// and store the results as packed double-precision floating-point elements in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_round_pd)
@(require_results, enable_target_feature="sse4.1")
_mm_round_pd :: #force_inline proc "c" (a: __m128d, $ROUNDING: i32) -> __m128d where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundpd(a, ROUNDING)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` using the rounding parameter,
// and store the results as packed single-precision floating-point elements in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_round_ps)
@(require_results, enable_target_feature="sse4.1")
_mm_round_ps :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> __m128 where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundps(a, ROUNDING)
}

// Round the lower double-precision (64-bit) floating-point element in `b` using the rounding parameter,
// store the result as a double-precision floating-point element in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_round_sd)
@(require_results, enable_target_feature="sse4.1")
_mm_round_sd :: #force_inline proc "c" (a, b: __m128d, $ROUNDING: i32) -> __m128d where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundsd(a, b, ROUNDING)
}

// Round the lower single-precision (32-bit) floating-point element in `b` using the rounding parameter,
// store the result as a single-precision floating-point element in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_round_ss)
@(require_results, enable_target_feature="sse4.1")
_mm_round_ss :: #force_inline proc "c" (a, b: __m128, $ROUNDING: i32) -> __m128 where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundss(a, b, ROUNDING)
}

// Horizontally compute the minimum amongst the packed unsigned 16-bit integers in `a`,
// store the minimum and index in `dst`, and zero the remaining bits in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_minpos_epu16)
@(require_results, enable_target_feature="sse4.1")
_mm_minpos_epu16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_phminposuw(transmute(simd.u16x8)a)
}

// Multiply the low signed 32-bit integers from each packed 64-bit element in `a` and `b`,
// and store the signed 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_mul_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := cast(__m128i)(cast(simd.i32x2)a)
	d := cast(__m128i)(cast(simd.i32x2)b)
	return simd.mul(c, d)
}

// Multiply the packed 32-bit integers in `a` and `b`, producing intermediate 64-bit integers,
// and store the low 32 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mullo_epi32)
@(require_results, enable_target_feature="sse4.1")
_mm_mullo_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.mul(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compute the sum of absolute differences (SADs) of quadruplets of unsigned 8-bit integers in `a` compared to those in `b`,
// and store the 16-bit results in `dst`. Eight SADs are performed using one quadruplet from `b` and eight quadruplets from `a`.
// One quadruplet is selected from `b` starting at on the offset specified in `imm8`. Eight quadruplets are formed from
// sequential 8-bit integers selected from `a` starting at the offset specified in `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mpsadbw_epu8)
@(require_results, enable_target_feature="sse4.1")
_mm_mpsadbw_epu8 :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 8 {
	return transmute(__m128i)llvm_mpsadbw(
		transmute(simd.u8x16)a,
		transmute(simd.u8x16)b,
		cast(u8)IMM8,
	)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testnzc_si128)
@(require_results, enable_target_feature="sse4.1")
_mm_testnzc_si128 :: #force_inline proc "c" (a, b: __m128i) -> i32 {
	return llvm_ptestnzc(a, b)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `mask`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `mask`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_test_mix_ones_zeros)
@(require_results, enable_target_feature="sse4.1")
_mm_test_mix_ones_zeros :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	return llvm_ptestnzc(a, mask)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testz_si128)
@(require_results, enable_target_feature="sse4.1")
_mm_testz_si128 :: #force_inline proc "c" (a, b: __m128i) -> i32 {
	dst := simd.reduce_or(simd.bit_and(a, b))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `mask`,
// and return 1 if the result is zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_test_all_zeros)
@(require_results, enable_target_feature="sse4.1")
_mm_test_all_zeros :: #force_inline proc "c" (a: __m128i, mask: __m128i) -> i32 {
	dst := simd.reduce_or(simd.bit_and(a, mask))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testc_si128)
@(require_results, enable_target_feature="sse4.1")
_mm_testc_si128 :: #force_inline proc "c" (a, b: __m128i) -> i32 {
	dst := simd.reduce_or(simd.bit_and(simd.bit_xor(a, __m128i(-1)), b))
	return i32(dst == 0)
}

// Compute the bitwise NOT of `a` and then AND with a 128-bit vector containing all 1's,
// and return 1 if the result is zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_test_all_ones)
@(require_results, enable_target_feature="sse2,sse4.1")
_mm_test_all_ones :: #force_inline proc "c" (a: __m128i) -> i32 {
	return _mm_testc_si128(a, _mm_cmpeq_epi32(a, a))
}

when ODIN_ARCH == .amd64 {
	// Load 128-bits of integer data from memory into `dst` using a non-temporal memory hint.
	// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_load_si128)
	// @(require_results, enable_target_feature="sse4.1")
	// _mm_stream_load_si128 :: asm (mem_addr: ^__m128i) -> (dst: __m128i) {
	// 	movntdqa dst, [mem_addr]
	// }

	// Extract a 64-bit integer from `a`, selected with `imm8`, and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_extract_epi64)
	@(require_results, enable_target_feature="sse4.1")
	_mm_extract_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> i64 where 0 <= IMM8, IMM8 < 2 {
		return simd.extract(a, IMM8)
	}

	// Copy `a` to `dst`, and insert the 64-bit integer `i` into `dst` at the location specified by `imm8`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_insert_epi64)
	@(require_results, enable_target_feature="sse4.1")
	_mm_insert_epi64 :: #force_inline proc "c" (a: __m128i, i: i64, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 2 {
		return simd.replace(a, IMM8, i)
	}
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse41.insertps")   llvm_insertps   :: proc(a, b: simd.f32x4, imm8: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse41.packusdw")   llvm_packusdw   :: proc(a, b: simd.i32x4) -> simd.u16x8 ---
	@(link_name="llvm.x86.sse41.dppd")       llvm_dppd       :: proc(a, b: simd.f64x2, imm8: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse41.dpps")       llvm_dpps       :: proc(a, b: simd.f32x4, imm8: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse41.round.pd")   llvm_roundpd    :: proc(a: simd.f64x2, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse41.round.ps")   llvm_roundps    :: proc(a: simd.f32x4, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse41.round.sd")   llvm_roundsd    :: proc(a, b: simd.f64x2, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse41.round.ss")   llvm_roundss    :: proc(a, b: simd.f32x4, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse41.phminposuw") llvm_phminposuw :: proc(a: simd.u16x8) -> simd.u16x8 ---
	@(link_name="llvm.x86.sse41.mpsadbw")    llvm_mpsadbw    :: proc(a, b: simd.u8x16, imm8: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.sse41.ptestnzc")   llvm_ptestnzc   :: proc(a: simd.i64x2, mask: simd.i64x2) -> i32 ---
}
