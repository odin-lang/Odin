#+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"

// Add packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_pd)
@(require_results, enable_target_feature="avx")
_mm256_add_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.add(a, b)
}

// Add packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_add_ps)
@(require_results, enable_target_feature="avx")
_mm256_add_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.add(a, b)
}

// Compute the bitwise AND of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_and_pd)
@(require_results, enable_target_feature="avx")
_mm256_and_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return transmute(__m256d)simd.bit_and(transmute(simd.u64x4)a, transmute(simd.u64x4)b)
}

// Compute the bitwise AND of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_and_ps)
@(require_results, enable_target_feature="avx")
_mm256_and_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return transmute(__m256)simd.bit_and(transmute(simd.u32x8)a, transmute(simd.u32x8)b)
}

// Compute the bitwise OR of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_or_pd)
@(require_results, enable_target_feature="avx")
_mm256_or_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return transmute(__m256d)simd.bit_or(transmute(simd.u64x4)a, transmute(simd.u64x4)b)
}

// Compute the bitwise OR of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_or_ps)
@(require_results, enable_target_feature="avx")
_mm256_or_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return transmute(__m256)simd.bit_or(transmute(simd.u32x8)a, transmute(simd.u32x8)b)
}

// Shuffle double-precision (64-bit) floating-point elements within 128-bit lanes using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shuffle_pd)
@(require_results, enable_target_feature="avx")
_mm256_shuffle_pd :: #force_inline proc "c" (a, b: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		b,
		(u32(IMM8) & 0b1),
		((u32(IMM8) >> 1) & 0b1) + 4,
		((u32(IMM8) >> 2) & 0b1) + 2,
		((u32(IMM8) >> 3) & 0b1) + 6,
	)
}

// Shuffle single-precision (32-bit) floating-point elements in a within 128-bit lanes using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_shuffle_ps)
@(require_results, enable_target_feature="avx")
_mm256_shuffle_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		b,
		(u32(IMM8) & 0b11),
		((u32(IMM8) >> 2) & 0b11),
		((u32(IMM8) >> 4) & 0b11) + 8,
		((u32(IMM8) >> 6) & 0b11) + 8,
		((u32(IMM8) & 0b11) + 4),
		((u32(IMM8) >> 2) & 0b11) + 4,
		((u32(IMM8) >> 4) & 0b11) + 12,
		((u32(IMM8) >> 6) & 0b11) + 12,
	)
}

// Compute the bitwise NOT of packed double-precision (64-bit) floating-point elements in `a` and then AND with `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_andnot_pd)
@(require_results, enable_target_feature="avx")
_mm256_andnot_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	c := simd.u64x4(max(u64))
	return transmute(__m256d)simd.bit_and(simd.bit_xor(c, transmute(simd.u64x4)a), transmute(simd.u64x4)b)
}

// Compute the bitwise NOT of packed single-precision (32-bit) floating-point elements in `a` and then AND with `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_andnot_ps)
@(require_results, enable_target_feature="avx")
_mm256_andnot_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	c := simd.u32x8(max(u32))
	return transmute(__m256)simd.bit_and(simd.bit_xor(c, transmute(simd.u32x8)a), transmute(simd.u32x8)b)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_pd)
@(require_results, enable_target_feature="avx")
_mm256_max_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return llvm_vmaxpd(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_ps)
@(require_results, enable_target_feature="avx")
_mm256_max_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return llvm_vmaxps(a, b)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_pd)
@(require_results, enable_target_feature="avx")
_mm256_min_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return llvm_vminpd(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_ps)
@(require_results, enable_target_feature="avx")
_mm256_min_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return llvm_vminps(a, b)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mul_pd)
@(require_results, enable_target_feature="avx")
_mm256_mul_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.mul(a, b)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mul_ps)
@(require_results, enable_target_feature="avx")
_mm256_mul_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.mul(a, b)
}

// Alternatively add and subtract packed double-precision (64-bit) floating-point elements in `a`
// to/from packed elements in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_addsub_pd)
@(require_results, enable_target_feature="avx")
_mm256_addsub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.shuffle(
		simd.add(a, b),
		simd.sub(a, b),
		4, 1, 6, 3,
	)
}

// Alternatively add and subtract packed single-precision (32-bit) floating-point elements in `a`
// to/from packed elements in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_addsub_ps)
@(require_results, enable_target_feature="avx")
_mm256_addsub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.shuffle(
		simd.add(a, b),
		simd.sub(a, b),
		8, 1, 10, 3, 12, 5, 14, 7,
	)
}

// Subtract packed double-precision (64-bit) floating-point elements in `b`
// from packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_pd)
@(require_results, enable_target_feature="avx")
_mm256_sub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.sub(a, b)
}

// Subtract packed single-precision (32-bit) floating-point elements in `b`
// from packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sub_ps)
@(require_results, enable_target_feature="avx")
_mm256_sub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.sub(a, b)
}

// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_div_pd)
@(require_results, enable_target_feature="avx")
_mm256_div_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.div(a, b)
}

// Divide packed single-precision (32-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_div_ps)
@(require_results, enable_target_feature="avx")
_mm256_div_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.div(a, b)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` using the `rounding` parameter,
// and store the results as packed double-precision floating-point elements in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_round_pd)
@(require_results, enable_target_feature="avx")
_mm256_round_pd :: #force_inline proc "c" (a: __m256d, $ROUNDING: i32) -> __m256d where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundpd256(a, ROUNDING)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` up to an integer value,
// and store the results as packed double-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_ceil_pd)
@(require_results, enable_target_feature="avx")
_mm256_ceil_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return simd.ceil(a)
}

// Round the packed double-precision (64-bit) floating-point elements in `a` down to an integer value,
// and store the results as packed double-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_floor_pd)
@(require_results, enable_target_feature="avx")
_mm256_floor_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return simd.floor(a)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` using the `rounding` parameter,
// and store the results as packed single-precision floating-point elements in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_round_ps)
@(require_results, enable_target_feature="avx")
_mm256_round_ps :: #force_inline proc(a: __m256, $ROUNDING: i32) -> __m256 where 0 <= ROUNDING, ROUNDING < 16 {
	return llvm_roundps256(a, ROUNDING)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` up to an integer value,
// and store the results as packed single-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_ceil_ps)
@(require_results, enable_target_feature="avx")
_mm256_ceil_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return simd.ceil(a)
}

// Round the packed single-precision (32-bit) floating-point elements in `a` down to an integer value,
// and store the results as packed single-precision floating-point elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_floor_ps)
@(require_results, enable_target_feature="avx")
_mm256_floor_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return simd.floor(a)
}

// Compute the square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sqrt_pd)
@(require_results, enable_target_feature="avx")
_mm256_sqrt_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return simd.sqrt(a)
}

// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sqrt_ps)
@(require_results, enable_target_feature="avx")
_mm256_sqrt_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return simd.sqrt(a)
}

// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using control mask `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blend_pd)
@(require_results, enable_target_feature="avx")
_mm256_blend_pd :: #force_inline proc "c" (a, b: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 16 {
	return simd.shuffle(
		a,
		b,
		((u32(IMM8) >> 0) & 1) * 4 + 0,
		((u32(IMM8) >> 1) & 1) * 4 + 1,
		((u32(IMM8) >> 2) & 1) * 4 + 2,
		((u32(IMM8) >> 3) & 1) * 4 + 3,
	)
}

// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using control mask `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blend_ps)
@(require_results, enable_target_feature="avx")
_mm256_blend_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		b,
		((u32(IMM8) >> 0) & 1) * 8 + 0,
		((u32(IMM8) >> 1) & 1) * 8 + 1,
		((u32(IMM8) >> 2) & 1) * 8 + 2,
		((u32(IMM8) >> 3) & 1) * 8 + 3,
		((u32(IMM8) >> 4) & 1) * 8 + 4,
		((u32(IMM8) >> 5) & 1) * 8 + 5,
		((u32(IMM8) >> 6) & 1) * 8 + 6,
		((u32(IMM8) >> 7) & 1) * 8 + 7,
	)
}

// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using `mask`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blendv_pd)
@(require_results, enable_target_feature="avx")
_mm256_blendv_pd :: #force_inline proc "c" (a, b: __m256d, mask: __m256d) -> __m256d {
	c := simd.lanes_lt(transmute(simd.i64x4)mask, simd.i64x4(0))
	return simd.select(c, b, a)
}

// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using `mask`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blendv_ps)
@(require_results, enable_target_feature="avx")
_mm256_blendv_ps :: #force_inline proc "c" (a, b: __m256, mask: __m256) -> __m256 {
	c := simd.lanes_lt(transmute(simd.i32x8)mask, simd.i32x8(0))
	return simd.select(c, b, a)
}

// Conditionally multiply the packed single-precision (32-bit) floating-point elements in `a` and `b`
// using the high 4 bits in `imm8`, sum the four products, and conditionally store the sum in `dst`
// using the low 4 bits of `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_dp_ps)
@(require_results, enable_target_feature="avx")
_mm256_dp_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vdpps(a, b, cast(u8)IMM8)
}

// Horizontally add adjacent pairs of double-precision (64-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hadd_pd)
@(require_results, enable_target_feature="avx")
_mm256_hadd_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.add(
		simd.shuffle(a, b, 0, 4, 2, 6),
		simd.shuffle(a, b, 1, 5, 3, 7),
	)
}

// Horizontally add adjacent pairs of single-precision (32-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hadd_ps)
@(require_results, enable_target_feature="avx")
_mm256_hadd_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.add(
		simd.shuffle(a, b, 0, 2, 8, 10, 4, 6, 12, 14),
		simd.shuffle(a, b, 1, 3, 9, 11, 5, 7, 13, 15),
	)
}

// Horizontally subtract adjacent pairs of double-precision (64-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hsub_pd)
@(require_results, enable_target_feature="avx")
_mm256_hsub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.sub(
		simd.shuffle(a, b, 0, 4, 2, 6),
		simd.shuffle(a, b, 1, 5, 3, 7),
	)
}

// Horizontally subtract adjacent pairs of single-precision (32-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_hsub_ps)
@(require_results, enable_target_feature="avx")
_mm256_hsub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.sub(
		simd.shuffle(a, b, 0, 2, 8, 10, 4, 6, 12, 14),
		simd.shuffle(a, b, 1, 3, 9, 11, 5, 7, 13, 15),
	)
}

// Compute the bitwise XOR of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_xor_pd)
@(require_results, enable_target_feature="avx")
_mm256_xor_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return transmute(__m256d)simd.bit_xor(transmute(simd.u64x4)a, transmute(simd.u64x4)b)
}

// Compute the bitwise XOR of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_xor_ps)
@(require_results, enable_target_feature="avx")
_mm256_xor_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return transmute(__m256)simd.bit_xor(transmute(simd.u32x8)a, transmute(simd.u32x8)b)
}

_CMP_EQ_OQ    : i32 : 0x00 // Equal (ordered, non-signaling)
_CMP_LT_OS    : i32 : 0x01 // Less-than (ordered, signaling)
_CMP_LE_OS    : i32 : 0x02 // Less-than-or-equal (ordered, signaling)
_CMP_UNORD_Q  : i32 : 0x03 // Unordered (non-signaling)
_CMP_NEQ_UQ   : i32 : 0x04 // Not-equal (unordered, non-signaling)
_CMP_NLT_US   : i32 : 0x05 // Not-less-than (unordered, signaling)
_CMP_NLE_US   : i32 : 0x06 // Not-less-than-or-equal (unordered, signaling)
_CMP_ORD_Q    : i32 : 0x07 // Ordered (non-signaling)
_CMP_EQ_UQ    : i32 : 0x08 // Equal (unordered, non-signaling)
_CMP_NGE_US   : i32 : 0x09 // Not-greater-than-or-equal (unordered, signaling)
_CMP_NGT_US   : i32 : 0x0a // Not-greater-than (unordered, signaling)
_CMP_FALSE_OQ : i32 : 0x0b // False (ordered, non-signaling)
_CMP_NEQ_OQ   : i32 : 0x0c // Not-equal (ordered, non-signaling)
_CMP_GE_OS    : i32 : 0x0d // Greater-than-or-equal (ordered, signaling)
_CMP_GT_OS    : i32 : 0x0e // Greater-than (ordered, signaling)
_CMP_TRUE_UQ  : i32 : 0x0f // True (unordered, non-signaling)
_CMP_EQ_OS    : i32 : 0x10 // Equal (ordered, signaling)
_CMP_LT_OQ    : i32 : 0x11 // Less-than (ordered, non-signaling)
_CMP_LE_OQ    : i32 : 0x12 // Less-than-or-equal (ordered, non-signaling)
_CMP_UNORD_S  : i32 : 0x13 // Unordered (signaling)
_CMP_NEQ_US   : i32 : 0x14 // Not-equal (unordered, signaling)
_CMP_NLT_UQ   : i32 : 0x15 // Not-less-than (unordered, non-signaling)
_CMP_NLE_UQ   : i32 : 0x16 // Not-less-than-or-equal (unordered, non-signaling)
_CMP_ORD_S    : i32 : 0x17 // Ordered (signaling)
_CMP_EQ_US    : i32 : 0x18 // Equal (unordered, signaling)
_CMP_NGE_UQ   : i32 : 0x19 // Not-greater-than-or-equal (unordered, non-signaling)
_CMP_NGT_UQ   : i32 : 0x1a // Not-greater-than (unordered, non-signaling)
_CMP_FALSE_OS : i32 : 0x1b // False (ordered, signaling)
_CMP_NEQ_OS   : i32 : 0x1c // Not-equal (ordered, signaling)
_CMP_GE_OQ    : i32 : 0x1d // Greater-than-or-equal (ordered, non-signaling)
_CMP_GT_OQ    : i32 : 0x1e // Greater-than (ordered, non-signaling)
_CMP_TRUE_US  : i32 : 0x1f // True (unordered, signaling)

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`
// based on the comparison operand specified by `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_pd)
@(require_results, enable_target_feature="avx")
_mm_cmp_pd :: #force_inline proc "c" (a, b: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmppd(a, b, cast(i8)IMM8)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`
// based on the comparison operand specified by `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmp_pd)
@(require_results, enable_target_feature="avx")
_mm256_cmp_pd :: #force_inline proc "c" (a, b: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmppd256(a, b, cast(u8)IMM8)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`
// based on the comparison operand specified by `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_ps)
@(require_results, enable_target_feature="avx")
_mm_cmp_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmpps(a, b, cast(i8)IMM8)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`
// based on the comparison operand specified by `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmp_ps)
@(require_results, enable_target_feature="avx")
_mm256_cmp_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmpps256(a, b, cast(u8)IMM8)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b`
// based on the comparison operand specified by `imm8`, store the result in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_sd)
@(require_results, enable_target_feature="avx")
_mm_cmp_sd :: #force_inline proc "c" (a, b: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmpsd(a, b, cast(i8)IMM8)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b`
// based on the comparison operand specified by `imm8`, store the result in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_ss)
@(require_results, enable_target_feature="avx")
_mm_cmp_ss :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 32 {
	return llvm_vcmpss(a, b, cast(i8)IMM8)
}

// Convert packed signed 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi32_pd)
@(require_results, enable_target_feature="avx")
_mm256_cvtepi32_pd :: #force_inline proc "c" (a: __m128i) -> __m256d {
	return cast(__m256d)(transmute(simd.i32x4)a)
}

// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi32_ps)
@(require_results, enable_target_feature="avx")
_mm256_cvtepi32_ps :: #force_inline proc "c" (a: __m256i) -> __m256 {
	return cast(__m256)(transmute(simd.i32x8)a)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed single-precision (32-bit)
// floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtpd_ps)
@(require_results, enable_target_feature="avx")
_mm256_cvtpd_ps :: #force_inline proc "c" (a: __m256d) -> __m128 {
	return cast(__m128)a
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtps_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvtps_epi32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvtps2dq(a)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed double-precision (64-bit)
// floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtps_pd)
@(require_results, enable_target_feature="avx")
_mm256_cvtps_pd :: #force_inline proc "c" (a: __m128) -> __m256d {
	return cast(__m256d)a
}

// Copy the lower double-precision (64-bit) floating-point element of `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsd_f64)
@(require_results, enable_target_feature="avx")
_mm256_cvtsd_f64 :: #force_inline proc "c" (a: __m256d) -> f64 {
	return simd.extract(a, 0)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers with truncation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttpd_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvttpd_epi32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2dq(a)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtpd_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvtpd_epi32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2dq(a)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers with truncation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttps_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvttps_epi32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvttps2dq(a)
}

// Extract 128 bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a`,
// selected with `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extractf128_ps)
@(require_results, enable_target_feature="avx")
_mm256_extractf128_ps :: #force_inline proc "c" (a: __m256, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		__m256(0),
		[2]int {0, 4}[u32(IMM8)],
		[2]int {1, 5}[u32(IMM8)],
		[2]int {2, 6}[u32(IMM8)],
		[2]int {3, 7}[u32(IMM8)],
	)
}

// Extract 128 bits (composed of 2 packed double-precision (64-bit) floating-point elements) from `a`,
// selected with `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extractf128_pd)
@(require_results, enable_target_feature="avx")
_mm256_extractf128_pd :: #force_inline proc "c" (a: __m256d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		__m256d(0),
		[2]int {0, 2}[u32(IMM8)],
		[2]int {1, 3}[u32(IMM8)],
	)
}

// Extract 128 bits (composed of integer data) from `a`, selected with `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extractf128_si256)
@(require_results, enable_target_feature="avx")
_mm256_extractf128_si256 :: #force_inline proc "c" (a: __m256i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		__m256i(0),
		[2]int {0, 2}[u32(IMM8)],
		[2]int {1, 3}[u32(IMM8)],
	)
}

// Extract a 32-bit integer from `a`, selected with `index`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extract_epi32)
@(require_results, enable_target_feature="avx")
_mm256_extract_epi32 :: #force_inline proc "c" (a: __m256i, $INDEX: i32) -> i32 where 0 <= INDEX, INDEX < 8 {
	return simd.extract(transmute(simd.i32x8)a, INDEX)
}

// Copy the lower 32-bit integer in `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsi256_si32)
@(require_results, enable_target_feature="avx")
_mm256_cvtsi256_si32 :: #force_inline proc "c" (a: __m256i) -> i32 {
	return simd.extract(transmute(simd.i32x8)a, 0)
}

// Zero the contents of all XMM or YMM registers.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zeroall)
@(enable_target_feature="avx")
_mm256_zeroall :: #force_inline proc "c" () {
	llvm_vzeroall()
}

// Zero the upper 128 bits of all YMM registers; the lower 128-bits of the registers are unmodified.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zeroupper)
@(enable_target_feature="avx")
_mm256_zeroupper :: #force_inline proc "c" () {
	llvm_vzeroupper()
}

// Shuffle single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using the control in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar_ps)
@(require_results, enable_target_feature="avx")
_mm256_permutevar_ps :: #force_inline proc "c" (a: __m256, b: __m256i) -> __m256 {
	return llvm_vpermilps256(a, transmute(simd.i32x8)b)
}

// Shuffle single-precision (32-bit) floating-point elements in `a` using the control in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permutevar_ps)
@(require_results, enable_target_feature="avx")
_mm_permutevar_ps :: #force_inline proc "c" (a: __m128, b: __m128i) -> __m128 {
	return llvm_vpermilps(a, transmute(simd.i32x4)b)
}

// Shuffle single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute_ps)
@(require_results, enable_target_feature="avx")
_mm256_permute_ps :: #force_inline proc "c" (a: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		__m256(0),
		((u32(IMM8) >> 0) & 0b11),
		((u32(IMM8) >> 2) & 0b11),
		((u32(IMM8) >> 4) & 0b11),
		((u32(IMM8) >> 6) & 0b11),
		((u32(IMM8) >> 0) & 0b11) + 4,
		((u32(IMM8) >> 2) & 0b11) + 4,
		((u32(IMM8) >> 4) & 0b11) + 4,
		((u32(IMM8) >> 6) & 0b11) + 4,
	)
}

// Shuffle single-precision (32-bit) floating-point elements in `a` using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permute_ps)
@(require_results, enable_target_feature="avx")
_mm_permute_ps :: #force_inline proc "c" (a: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		__m128(0),
		(u32(IMM8) >> 0) & 0b11,
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
	)
}

// Shuffle double-precision (64-bit) floating-point elements in `a` within 128-bit lanes using the control in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar_pd)
@(require_results, enable_target_feature="avx")
_mm256_permutevar_pd :: #force_inline proc "c" (a: __m256d, b: __m256i) -> __m256d {
	return llvm_vpermilpd256(a, b)
}

// Shuffle double-precision (64-bit) floating-point elements in `a` using the control in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permutevar_pd)
@(require_results, enable_target_feature="avx")
_mm_permutevar_pd :: #force_inline proc "c" (a: __m128d, b: __m128i) -> __m128d {
	return llvm_vpermilpd(a, b)
}

// Shuffle double-precision (64-bit) floating-point elements in `a` within 128-bit lanes using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute_pd)
@(require_results, enable_target_feature="avx")
_mm256_permute_pd :: #force_inline proc "c" (a: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 16 {
	return simd.shuffle(
		a,
		__m256d(0),
		((u32(IMM8) >> 0) & 1),
		((u32(IMM8) >> 1) & 1),
		((u32(IMM8) >> 2) & 1) + 2,
		((u32(IMM8) >> 3) & 1) + 2,
	)
}

// Shuffle double-precision (64-bit) floating-point elements in `a` using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permute_pd)
@(require_results, enable_target_feature="avx")
_mm_permute_pd :: #force_inline proc "c" (a: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 4 {
	return simd.shuffle(
		a,
		__m128d(0),
		(u32(IMM8) >> 0) & 1,
		(u32(IMM8) >> 1) & 1,
	)
}

// Shuffle 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements)
// selected by `imm8` from `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute2f128_ps)
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256)_mm256_permute2f128_si256(
		transmute(__m256i)a,
		transmute(__m256i)b,
		IMM8,
	)
}

// Shuffle 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements)
// selected by `imm8` from `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute2f128_pd)
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_pd :: #force_inline proc "c" (a, b: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256d)_mm256_permute2f128_si256(
		transmute(__m256i)a,
		transmute(__m256i)b,
		IMM8,
	)
}

// Shuffle 128-bits (composed of integer data) selected by `imm8` from `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permute2f128_si256)
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_si256 :: #force_inline proc "c" (a, b: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
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

// Broadcast a single-precision (32-bit) floating-point element from memory to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcast_ss)
@(require_results, enable_target_feature="avx")
_mm256_broadcast_ss :: #force_inline proc "c" (mem_addr: ^f32) -> __m256 {
	return __m256(mem_addr^)
}

// Broadcast a single-precision (32-bit) floating-point element from memory to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_broadcast_ss)
@(require_results, enable_target_feature="avx")
_mm_broadcast_ss :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	return __m128(mem_addr^)
}

// Broadcast a double-precision (64-bit) floating-point element from memory to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcast_sd)
@(require_results, enable_target_feature="avx")
_mm256_broadcast_sd :: #force_inline proc "c" (mem_addr: ^f64) -> __m256d {
	return __m256d(mem_addr^)
}

// Broadcast 128 bits from memory (composed of 4 packed single-precision (32-bit) floating-point elements)
// to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcast_ps)
@(require_results, enable_target_feature="avx")
_mm256_broadcast_ps :: #force_inline proc "c" (mem_addr: ^__m128) -> __m256 {
	return simd.shuffle(mem_addr^, __m128(0), 0, 1, 2, 3, 0, 1, 2, 3)
}

// Broadcast 128 bits from memory (composed of 2 packed double-precision (64-bit) floating-point elements)
// to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_broadcast_pd)
@(require_results, enable_target_feature="avx")
_mm256_broadcast_pd :: #force_inline proc "c" (mem_addr: ^__m128d) -> __m256d {
	return simd.shuffle(mem_addr^, __m128d(0), 0, 1, 0, 1)
}

// Copy `a` to `dst`, then insert 128 bits (composed of 4 packed single-precision (32-bit) floating-point elements)
// from `b` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insertf128_ps)
@(require_results, enable_target_feature="avx")
_mm256_insertf128_ps :: #force_inline proc "c" (a: __m256, b: __m128, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		_mm256_castps128_ps256(b),
		[2]int { 8,  0}[u32(IMM8)],
		[2]int { 9,  1}[u32(IMM8)],
		[2]int {10,  2}[u32(IMM8)],
		[2]int {11,  3}[u32(IMM8)],
		[2]int { 4,  8}[u32(IMM8)],
		[2]int { 5,  9}[u32(IMM8)],
		[2]int { 6, 10}[u32(IMM8)],
		[2]int { 7, 11}[u32(IMM8)],
	)
}

// Copy `a` to `dst`, then insert 128 bits (composed of 2 packed double-precision (64-bit) floating-point elements)
// from `b` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insertf128_pd)
@(require_results, enable_target_feature="avx")
_mm256_insertf128_pd :: #force_inline proc "c" (a: __m256d, b: __m128d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		_mm256_castpd128_pd256(b),
		[2]int {4, 0}[u32(IMM8)],
		[2]int {5, 1}[u32(IMM8)],
		[2]int {2, 4}[u32(IMM8)],
		[2]int {3, 5}[u32(IMM8)],
	)
}

// Copy `a` to `dst`, then insert 128 bits from `b` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insertf128_si256)
@(require_results, enable_target_feature="avx")
_mm256_insertf128_si256 :: #force_inline proc "c" (a: __m256i, b: __m128i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 2 {
	return simd.shuffle(
		a,
		_mm256_castsi128_si256(b),
		[2]int {4, 0}[u32(IMM8)],
		[2]int {5, 1}[u32(IMM8)],
		[2]int {2, 4}[u32(IMM8)],
		[2]int {3, 5}[u32(IMM8)],
	)
}

// Copy `a` to `dst`, and insert the 8-bit integer `i` into `dst` at the location specified by `index`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insert_epi8)
@(require_results, enable_target_feature="avx")
_mm256_insert_epi8 :: #force_inline proc "c" (a: __m256i, i: i8, $INDEX: i32) -> __m256i where 0 <= INDEX, INDEX < 32 {
	return transmute(__m256i)simd.replace(transmute(simd.i8x32)a, INDEX, i)
}

// Copy `a` to `dst`, and insert the 16-bit integer `i` into `dst` at the location specified by `index`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insert_epi16)
@(require_results, enable_target_feature="avx")
_mm256_insert_epi16 :: #force_inline proc "c" (a: __m256i, i: i16, $INDEX: i32) -> __m256i where 0 <= INDEX, INDEX < 16 {
	return transmute(__m256i)simd.replace(transmute(simd.i16x16)a, INDEX, i)
}

// Copy `a` to `dst`, and insert the 32-bit integer `i` into `dst` at the location specified by `index`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insert_epi32)
@(require_results, enable_target_feature="avx")
_mm256_insert_epi32 :: #force_inline proc "c" (a: __m256i, i: i32, $INDEX: i32) -> __m256i where 0 <= INDEX, INDEX < 8 {
	return transmute(__m256i)simd.replace(transmute(simd.i32x8)a, INDEX, i)
}

// Load 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from memory into `dst`.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_pd)
@(require_results, enable_target_feature="avx")
_mm256_load_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m256d {
	return (^__m256d)(mem_addr)^
}

// Store 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_pd)
@(enable_target_feature="avx")
_mm256_store_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m256d) {
	(^__m256d)(mem_addr)^ = a
}

// Load 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from memory into `dst`.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_ps)
@(require_results, enable_target_feature="avx")
_mm256_load_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m256 {
	return (^__m256)(mem_addr)^
}

// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_ps)
@(enable_target_feature="avx")
_mm256_store_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m256) {
	(^__m256)(mem_addr)^ = a
}

// Load 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from memory into `dst`.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu_pd)
@(enable_target_feature="avx")
_mm256_loadu_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m256d {
	return intrinsics.unaligned_load((^__m256d)(mem_addr))
}

// Store 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu_pd)
@(enable_target_feature="avx")
_mm256_storeu_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m256d) {
	intrinsics.unaligned_store((^__m256d)(mem_addr), a)
}

// Load 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from memory into `dst`.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu_ps)
@(require_results, enable_target_feature="avx")
_mm256_loadu_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m256 {
	return intrinsics.unaligned_load((^__m256)(mem_addr))
}

// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu_ps)
@(enable_target_feature="avx")
_mm256_storeu_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m256) {
	intrinsics.unaligned_store((^__m256)(mem_addr), a)
}

// Load 256-bits of integer data from memory into `dst`.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_si256)
@(require_results, enable_target_feature="avx")
_mm256_load_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return mem_addr^
}

// Store 256-bits of integer data from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_si256)
@(enable_target_feature="avx")
_mm256_store_si256 :: #force_inline proc "c" (mem_addr: ^__m256i, a: __m256i) {
	mem_addr^ = a
}

// Load 256-bits of integer data from memory into `dst`.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu_si256)
@(require_results, enable_target_feature="avx")
_mm256_loadu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return intrinsics.unaligned_load(mem_addr)
}

// Store 256-bits of integer data from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu_si256)
@(enable_target_feature="avx")
_mm256_storeu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i, a: __m256i) {
	intrinsics.unaligned_store(mem_addr, a)
}

// Load packed double-precision (64-bit) floating-point elements from memory into `dst` using `mask`
// (elements are zeroed out when the high bit of the corresponding element is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskload_pd)
@(require_results, enable_target_feature="avx")
_mm256_maskload_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m256i) -> __m256d {
	m := simd.shr(mask, simd.u64x4(63))
	return simd.masked_load(mem_addr, __m256d(0), m)
}

// Store packed double-precision (64-bit) floating-point elements from `a` into memory using `mask`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskstore_pd)
@(enable_target_feature="avx")
_mm256_maskstore_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m256i, a: __m256d) {
	m := simd.shr(mask, simd.u64x4(63))
	simd.masked_store(mem_addr, a, m)
}

// Load packed double-precision (64-bit) floating-point elements from memory into `dst` using `mask`
// (elements are zeroed out when the high bit of the corresponding element is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskload_pd)
@(require_results, enable_target_feature="avx")
_mm_maskload_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m128i) -> __m128d {
	m := simd.shr(mask, simd.u64x2(63))
	return simd.masked_load(mem_addr, __m128d(0), m)
}

// Store packed double-precision (64-bit) floating-point elements from `a` into memory using `mask`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskstore_pd)
@(enable_target_feature="avx")
_mm_maskstore_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m128i, a: __m128d) {
	m := simd.shr(mask, simd.u64x2(63))
	simd.masked_store(mem_addr, a, m)
}

// Load packed single-precision (32-bit) floating-point elements from memory into `dst` using `mask`
// (elements are zeroed out when the high bit of the corresponding element is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskload_ps)
@(require_results, enable_target_feature="avx")
_mm256_maskload_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m256i) -> __m256 {
	m := simd.shr(transmute(simd.i32x8)mask, simd.u32x8(31))
	return simd.masked_load(mem_addr, __m256(0), m)
}

// Store packed single-precision (32-bit) floating-point elements from `a` into memory using `mask`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskstore_ps)
@(enable_target_feature="avx")
_mm256_maskstore_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m256i, a: __m256) {
	m := simd.shr(transmute(simd.i32x8)mask, simd.u32x8(31))
	simd.masked_store(mem_addr, a, m)
}

// Load packed single-precision (32-bit) floating-point elements from memory into `dst` using `mask`
// (elements are zeroed out when the high bit of the corresponding element is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskload_ps)
@(require_results, enable_target_feature="avx")
_mm_maskload_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m128i) -> __m128 {
	m := simd.shr(transmute(simd.i32x4)mask, simd.u32x4(31))
	return simd.masked_load(mem_addr, __m128(0), m)
}

// Store packed single-precision (32-bit) floating-point elements from `a` into memory using `mask`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskstore_ps)
@(enable_target_feature="avx")
_mm_maskstore_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m128i, a: __m128) {
	m := simd.shr(transmute(simd.i32x4)mask, simd.u32x4(31))
	simd.masked_store(mem_addr, a, m)
}

// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_movehdup_ps)
@(require_results, enable_target_feature="avx")
_mm256_movehdup_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return simd.shuffle(a, a, 1, 1, 3, 3, 5, 5, 7, 7)
}

// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_moveldup_ps)
@(require_results, enable_target_feature="avx")
_mm256_moveldup_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return simd.shuffle(a, a, 0, 0, 2, 2, 4, 4, 6, 6)
}

// Duplicate even-indexed double-precision (64-bit) floating-point elements from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_movedup_pd)
@(require_results, enable_target_feature="avx")
_mm256_movedup_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return simd.shuffle(a, a, 0, 0, 2, 2)
}

// Load 256-bits of integer data from unaligned memory into `dst`.
// This intrinsic may perform better than `_mm256_loadu_si256` when the data crosses a cache line boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_lddqu_si256)
@(require_results, enable_target_feature="avx")
_mm256_lddqu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return transmute(__m256i)llvm_vlddqu(mem_addr)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rcp_ps)
@(require_results, enable_target_feature="avx")
_mm256_rcp_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrcpps(a)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rsqrt_ps)
@(require_results, enable_target_feature="avx")
_mm256_rsqrt_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrsqrtps(a)
}

// Unpack and interleave double-precision (64-bit) floating-point elements
// from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_pd)
@(require_results, enable_target_feature="avx")
_mm256_unpackhi_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.shuffle(a, b, 1, 5, 3, 7)
}

// Unpack and interleave single-precision (32-bit) floating-point elements
// from the high half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpackhi_ps)
@(require_results, enable_target_feature="avx")
_mm256_unpackhi_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.shuffle(a, b, 2, 10, 3, 11, 6, 14, 7, 15)
}

// Unpack and interleave double-precision (64-bit) floating-point elements
// from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_pd)
@(require_results, enable_target_feature="avx")
_mm256_unpacklo_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return simd.shuffle(a, b, 0, 4, 2, 6)
}

// Unpack and interleave single-precision (32-bit) floating-point elements
// from the low half of each 128-bit lane in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_unpacklo_ps)
@(require_results, enable_target_feature="avx")
_mm256_unpacklo_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return simd.shuffle(a, b, 0, 8, 1, 9, 4, 12, 5, 13)
}

// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testz_si256)
@(require_results, enable_target_feature="avx")
_mm256_testz_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	dst := simd.reduce_or(simd.bit_and(a, b))
	return i32(dst == 0)
}

// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testc_si256)
@(require_results, enable_target_feature="avx")
_mm256_testc_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	dst := simd.reduce_or(simd.bit_and(simd.bit_xor(a, __m256i(-1)), b))
	return i32(dst == 0)
}

// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`, and set `ZF` to 1 if the result is zero,
// otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if the result is zero,
// otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_si256)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	return llvm_ptestnzc256(a, b)
}

// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testz_pd)
@(require_results, enable_target_feature="avx")
_mm256_testz_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestzpd256(a, b)
}

// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testc_pd)
@(require_results, enable_target_feature="avx")
_mm256_testc_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestcpd256(a, b)
}

// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_pd)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestnzcpd256(a, b)
}

// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testz_pd)
@(require_results, enable_target_feature="sse2,avx")
_mm_testz_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	dst := simd.reduce_or(simd.lanes_lt(transmute(__m128i)_mm_and_pd(a, b), __m128i(0)))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testc_pd)
@(require_results, enable_target_feature="sse2,avx")
_mm_testc_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	dst := simd.reduce_or(simd.lanes_lt(transmute(__m128i)_mm_andnot_pd(a, b), __m128i(0)))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 64-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testnzc_pd)
@(require_results, enable_target_feature="avx")
_mm_testnzc_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return llvm_vtestnzcpd(a, b)
}

// Compute the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testz_ps)
@(require_results, enable_target_feature="avx")
_mm256_testz_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestzps256(a, b)
}

// Compute the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testc_ps)
@(require_results, enable_target_feature="avx")
_mm256_testc_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestcps256(a, b)
}

// Compute the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 256-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_ps)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestnzcps256(a, b)
}

// Compute the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testz_ps)
@(require_results, enable_target_feature="sse,avx")
_mm_testz_ps :: #force_inline proc "c" (a, b: __m128) -> i32 {
	dst := simd.reduce_or(simd.lanes_lt(transmute(simd.i32x4)_mm_and_ps(a, b), simd.i32x4(0)))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testc_ps)
@(require_results, enable_target_feature="sse,avx")
_mm_testc_ps :: #force_inline proc "c" (a, b: __m128) -> i32 {
	dst := simd.reduce_or(simd.lanes_lt(transmute(simd.i32x4)_mm_andnot_ps(a, b), simd.i32x4(0)))
	return i32(dst == 0)
}

// Compute the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`,
// producing an intermediate 128-bit value, and set `ZF` to 1 if the sign bit of each 32-bit element in the intermediate
// value is zero, otherwise set `ZF` to 0. Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate
// value, and set `CF` to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise set `CF` to 0.
// Return 1 if both the `ZF` and `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testnzc_ps)
@(require_results, enable_target_feature="avx")
_mm_testnzc_ps :: #force_inline proc "c" (a, b: __m128) -> i32 {
	return llvm_vtestnzcps(a, b)
}

// Set each bit of mask dst based on the most significant bit of the corresponding
// packed double-precision (64-bit) floating-point element in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_movemask_pd)
@(require_results, enable_target_feature="avx")
_mm256_movemask_pd :: #force_inline proc "c" (a: __m256d) -> i32 {
	mask := simd.lanes_lt(transmute(simd.i64x4)a, simd.i64x4(0))
	return i32(transmute(u8)simd.extract_lsbs(mask))
}

// Set each bit of mask dst based on the most significant bit of the corresponding
// packed single-precision (32-bit) floating-point element in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_movemask_ps)
@(require_results, enable_target_feature="avx")
_mm256_movemask_ps :: #force_inline proc "c" (a: __m256) -> i32 {
	mask := simd.lanes_lt(transmute(simd.i32x8)a, simd.i32x8(0))
	return i32(transmute(u8)simd.extract_lsbs(mask))
}

// Return vector of type `__m256d` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setzero_pd)
@(require_results, enable_target_feature="avx")
_mm256_setzero_pd :: #force_inline proc "c" () -> __m256d {
	return __m256d(0)
}

// Return vector of type `__m256` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setzero_ps)
@(require_results, enable_target_feature="avx")
_mm256_setzero_ps :: #force_inline proc "c" () -> __m256 {
	return __m256(0)
}

// Return vector of type `__m256i` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setzero_si256)
@(require_results, enable_target_feature="avx")
_mm256_setzero_si256 :: #force_inline proc "c" () -> __m256i {
	return __m256i(0)
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_pd)
@(require_results, enable_target_feature="avx")
_mm256_set_pd :: #force_inline proc "c" (e3, e2, e1, e0: f64) -> __m256d {
	return __m256d {e0, e1, e2, e3}
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_ps)
@(require_results, enable_target_feature="avx")
_mm256_set_ps :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: f32) -> __m256 {
	return __m256 {e0, e1, e2, e3, e4, e5, e6, e7}
}

// Set packed 8-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_epi8)
@(require_results, enable_target_feature="avx")
_mm256_set_epi8 :: #force_inline proc "c" (
	e31, e30, e29, e28, e27, e26, e25, e24: i8,
	e23, e22, e21, e20, e19, e18, e17, e16: i8,
	e15, e14, e13, e12, e11, e10, e09, e08: i8,
	e07, e06, e05, e04, e03, e02, e01, e00: i8,
) -> __m256i {
	return transmute(__m256i)(simd.i8x32 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
		e16, e17, e18, e19, e20, e21, e22, e23,
		e24, e25, e26, e27, e28, e29, e30, e31,
	})
}

// Set packed 16-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_epi16)
@(require_results, enable_target_feature="avx")
_mm256_set_epi16 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i16,
	e07, e06, e05, e04, e03, e02, e01, e00: i16,
) -> __m256i {
	return transmute(__m256i)(simd.i16x16 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
	})
}

// Set packed 32-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_epi32)
@(require_results, enable_target_feature="avx")
_mm256_set_epi32 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i32) -> __m256i {
	return transmute(__m256i)(simd.i32x8 {e0, e1, e2, e3, e4, e5, e6, e7})
}

// Set packed 64-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_epi64x)
@(require_results, enable_target_feature="avx")
_mm256_set_epi64x :: #force_inline proc "c" (e3, e2, e1, e0: i64) -> __m256i {
	return __m256i {e0, e1, e2, e3}
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_pd)
@(require_results, enable_target_feature="avx")
_mm256_setr_pd :: #force_inline proc "c" (e3, e2, e1, e0: f64) -> __m256d {
	return __m256d {e3, e2, e1, e0}
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_ps)
@(require_results, enable_target_feature="avx")
_mm256_setr_ps :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: f32) -> __m256 {
	return __m256 {e7, e6, e5, e4, e3, e2, e1, e0}
}

// Set packed 8-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_epi8)
@(require_results, enable_target_feature="avx")
_mm256_setr_epi8 :: #force_inline proc "c" (
	e31, e30, e29, e28, e27, e26, e25, e24: i8,
	e23, e22, e21, e20, e19, e18, e17, e16: i8,
	e15, e14, e13, e12, e11, e10, e09, e08: i8,
	e07, e06, e05, e04, e03, e02, e01, e00: i8,
) -> __m256i {
	return transmute(__m256i)(simd.i8x32 {
		e31, e30, e29, e28, e27, e26, e25, e24,
		e23, e22, e21, e20, e19, e18, e17, e16,
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	})
}

// Set packed 16-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_epi16)
@(require_results, enable_target_feature="avx")
_mm256_setr_epi16 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i16,
	e07, e06, e05, e04, e03, e02, e01, e00: i16,
) -> __m256i {
	return transmute(__m256i)(simd.i16x16 {
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	})
}

// Set packed 32-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_epi32)
@(require_results, enable_target_feature="avx")
_mm256_setr_epi32 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i32) -> __m256i {
	return transmute(__m256i)(simd.i32x8 {e7, e6, e5, e4, e3, e2, e1, e0})
}

// Set packed 64-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_epi64x)
@(require_results, enable_target_feature="avx")
_mm256_setr_epi64x :: #force_inline proc "c" (e3, e2, e1, e0: i64) -> __m256i {
	return __m256i {e3, e2, e1, e0}
}

// Broadcast double-precision (64-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_pd)
@(require_results, enable_target_feature="avx")
_mm256_set1_pd :: #force_inline proc "c" (a: f64) -> __m256d {
	return __m256d(a)
}

// Broadcast single-precision (32-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_ps)
@(require_results, enable_target_feature="avx")
_mm256_set1_ps :: #force_inline proc "c" (a: f32) -> __m256 {
	return __m256(a)
}

// Broadcast 8-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi8)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi8 :: #force_inline proc "c" (a: i8) -> __m256i {
	return transmute(__m256i)(simd.i8x32(a))
}

// Broadcast 16-bit integer `a` to all all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi16)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi16 :: #force_inline proc "c" (a: i16) -> __m256i {
	return transmute(__m256i)(simd.i16x16(a))
}

// Broadcast 32-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi32)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi32 :: #force_inline proc "c" (a: i32) -> __m256i {
	return transmute(__m256i)(simd.i32x8(a))
}

// Broadcast 64-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi64x)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi64x :: #force_inline proc "c" (a: i64) -> __m256i {
	return __m256i(a)
}

// Cast vector of type `__m256d` to type `__m256`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castpd_ps)
@(require_results, enable_target_feature="avx")
_mm256_castpd_ps :: #force_inline proc "c" (a: __m256d) -> __m256 {
	return transmute(__m256)a
}

// Cast vector of type `__m256` to type `__m256d`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castps_pd)
@(require_results, enable_target_feature="avx")
_mm256_castps_pd :: #force_inline proc "c" (a: __m256) -> __m256d {
	return transmute(__m256d)a
}

// Cast vector of type `__m256` to type `__m256i`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castps_si256)
@(require_results, enable_target_feature="avx")
_mm256_castps_si256 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)a
}

// Cast vector of type `__m256i` to type `__m256`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castsi256_ps)
@(require_results, enable_target_feature="avx")
_mm256_castsi256_ps :: #force_inline proc "c" (a: __m256i) -> __m256 {
	return transmute(__m256)a
}

// Cast vector of type `__m256d` to type `__m256i`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castpd_si256)
@(require_results, enable_target_feature="avx")
_mm256_castpd_si256 :: #force_inline proc "c" (a: __m256d) -> __m256i {
	return transmute(__m256i)a
}

// Cast vector of type `__m256i` to type `__m256d`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castsi256_pd)
@(require_results, enable_target_feature="avx")
_mm256_castsi256_pd :: #force_inline proc "c" (a: __m256i) -> __m256d {
	return transmute(__m256d)a
}

// Cast vector of type `__m256` to type `__m128`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castps256_ps128)
@(require_results, enable_target_feature="avx")
_mm256_castps256_ps128 :: #force_inline proc "c" (a: __m256) -> __m128 {
	return simd.shuffle(a, a, 0, 1, 2, 3)
}

// Cast vector of type `__m256d` to type `__m128d`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castpd256_pd128)
@(require_results, enable_target_feature="avx")
_mm256_castpd256_pd128 :: #force_inline proc "c" (a: __m256d) -> __m128d {
	return simd.shuffle(a, a, 0, 1)
}

// Cast vector of type `__m256i` to type `__m128i`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castsi256_si128)
@(require_results, enable_target_feature="avx")
_mm256_castsi256_si128 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return simd.shuffle(a, a, 0, 1)
}

// Cast vector of type `__m128` to type `__m256`; the upper 128 bits of the result are undefined.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castps128_ps256)
@(require_results, enable_target_feature="avx")
_mm256_castps128_ps256 :: #force_inline proc "c" (a: __m128) -> __m256 {
	return simd.shuffle(a, __m128(0), 0, 1, 2, 3, 4, 4, 4, 4)
}

// Cast vector of type `__m128d` to type `__m256d`; the upper 128 bits of the result are undefined.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castpd128_pd256)
@(require_results, enable_target_feature="avx")
_mm256_castpd128_pd256 :: #force_inline proc "c" (a: __m128d) -> __m256d {
	return simd.shuffle(a, __m128d(0), 0, 1, 2, 2)
}

// Cast vector of type `__m128i` to type `__m256i`; the upper 128 bits of the result are undefined.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_castsi128_si256)
@(require_results, enable_target_feature="avx")
_mm256_castsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return simd.shuffle(a, __m128i(0), 0, 1, 2, 2)
}

// Cast vector of type `__m128` to type `__m256`; the upper 128 bits of the result are zeroed.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zextps128_ps256)
@(require_results, enable_target_feature="avx")
_mm256_zextps128_ps256 :: #force_inline proc "c" (a: __m128) -> __m256 {
	return simd.shuffle(a, __m128(0), 0, 1, 2, 3, 4, 5, 6, 7)
}

// Cast vector of type `__m128i` to type `__m256i`; the upper 128 bits of the result are zeroed.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zextsi128_si256)
@(require_results, enable_target_feature="avx")
_mm256_zextsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return simd.shuffle(a, __m128i(0), 0, 1, 2, 3)
}

// Cast vector of type `__m128d` to type `__m256d`; the upper 128 bits of the result are zeroed.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zextpd128_pd256)
@(require_results, enable_target_feature="avx")
_mm256_zextpd128_pd256 :: #force_inline proc "c" (a: __m128d) -> __m256d {
	return simd.shuffle(a, __m128d(0), 0, 1, 2, 3)
}

// Return vector of type `__m256` with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_undefined_ps)
@(require_results, enable_target_feature="avx")
_mm256_undefined_ps :: #force_inline proc "c" () -> __m256 {
	return __m256(0)
}

// Return vector of type `__m256d` with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_undefined_pd)
@(require_results, enable_target_feature="avx")
_mm256_undefined_pd :: #force_inline proc "c" () -> __m256d {
	return __m256d(0)
}

// Return vector of type `__m256i` with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_undefined_si256)
@(require_results, enable_target_feature="avx")
_mm256_undefined_si256 :: #force_inline proc "c" () -> __m256i {
	return __m256i(0)
}

// Set packed `__m256` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_m128)
@(require_results, enable_target_feature="avx")
_mm256_set_m128 :: #force_inline proc "c" (hi, lo: __m128) -> __m256 {
	return simd.shuffle(lo, hi, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Set packed `__m256d` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_m128d)
@(require_results, enable_target_feature="avx")
_mm256_set_m128d :: #force_inline proc "c" (hi, lo: __m128d) -> __m256d {
	return simd.shuffle(lo, hi, 0, 1, 2, 3)
}

// Set packed `__m256i` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set_m128i)
@(require_results, enable_target_feature="avx")
_mm256_set_m128i :: #force_inline proc "c" (hi, lo: __m128i) -> __m256i {
	return simd.shuffle(lo, hi, 0, 1, 2, 3)
}

// Set packed `__m256` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_m128)
@(require_results, enable_target_feature="avx")
_mm256_setr_m128 :: #force_inline proc "c" (lo, hi: __m128) -> __m256 {
	return simd.shuffle(lo, hi, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Set packed `__m256d` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_m128d)
@(require_results, enable_target_feature="avx")
_mm256_setr_m128d :: #force_inline proc "c" (lo, hi: __m128d) -> __m256d {
	return simd.shuffle(lo, hi, 0, 1, 2, 3)
}

// Set packed `__m256i` vector `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_setr_m128i)
@(require_results, enable_target_feature="avx")
_mm256_setr_m128i :: #force_inline proc "c" (lo, hi: __m128i) -> __m256i {
	return simd.shuffle(lo, hi, 0, 1, 2, 3)
}

// Load two 128-bit values (composed of 4 packed single-precision (32-bit) floating-point elements) from memory,
// and combine them into a 256-bit value in `dst`. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu2_m128)
@(require_results, enable_target_feature="sse,avx")
_mm256_loadu2_m128 :: #force_inline proc "c" (hiaddr, loaddr: ^f32) -> __m256 {
	a := _mm256_castps128_ps256(_mm_loadu_ps(loaddr))
	return _mm256_insertf128_ps(a, _mm_loadu_ps(hiaddr), 1)
}

// Load two 128-bit values (composed of 2 packed double-precision (64-bit) floating-point elements) from memory,
// and combine them into a 256-bit value in `dst`. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu2_m128d)
@(require_results, enable_target_feature="sse2,avx")
_mm256_loadu2_m128d :: #force_inline proc "c" (hiaddr, loaddr: ^f64) -> __m256d {
	a := _mm256_castpd128_pd256(_mm_loadu_pd(loaddr))
	return _mm256_insertf128_pd(a, _mm_loadu_pd(hiaddr), 1)
}

// Load two 128-bit values (composed of integer data) from memory,
// and combine them into a 256-bit value in `dst`. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_loadu2_m128i)
@(require_results, enable_target_feature="sse2,avx")
_mm256_loadu2_m128i :: #force_inline proc "c" (hiaddr, loaddr: ^__m128i) -> __m256i {
	a := _mm256_castsi128_si256(_mm_loadu_si128(loaddr))
	return _mm256_insertf128_si256(a, _mm_loadu_si128(hiaddr), 1)
}

// Store the high and low 128-bit halves (each composed of 4 packed single-precision (32-bit) floating-point elements)
// from `a` into memory two different 128-bit locations. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu2_m128)
@(enable_target_feature="sse,avx")
_mm256_storeu2_m128 :: #force_inline proc "c" (hiaddr, loaddr: ^f32, a: __m256) {
	lo := _mm256_castps256_ps128(a)
	_mm_storeu_ps(loaddr, lo)
	hi := _mm256_extractf128_ps(a, 1)
	_mm_storeu_ps(hiaddr, hi)
}

// Store the high and low 128-bit halves (each composed of 2 packed double-precision (64-bit) floating-point elements)
// from `a` into memory two different 128-bit locations. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu2_m128d)
@(enable_target_feature="sse2,avx")
_mm256_storeu2_m128d :: #force_inline proc "c" (hiaddr, loaddr: ^f64, a: __m256d) {
	lo := _mm256_castpd256_pd128(a)
	_mm_storeu_pd(loaddr, lo)
	hi := _mm256_extractf128_pd(a, 1)
	_mm_storeu_pd(hiaddr, hi)
}

// Store the high and low 128-bit halves (each composed of integer data)
// from `a` into memory two different 128-bit locations. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_storeu2_m128i)
@(enable_target_feature="sse2,avx")
_mm256_storeu2_m128i :: #force_inline proc "c" (hiaddr, loaddr: ^__m128i, a: __m256i) {
	lo := _mm256_castsi256_si128(a)
	_mm_storeu_si128(loaddr, lo)
	hi := _mm256_extractf128_si256(a, 1)
	_mm_storeu_si128(hiaddr, hi)
}

// Copy the lower single-precision (32-bit) floating-point element of `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtss_f32)
@(require_results, enable_target_feature="avx")
_mm256_cvtss_f32 :: #force_inline proc "c" (a: __m256) -> f32 {
	return simd.extract(a, 0)
}

when ODIN_ARCH == .amd64 {
	// Store 256-bits of integer data from `a` into memory using a non-temporal memory hint.
	// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_si256)
	// @(enable_target_feature="avx")
	// _mm256_stream_si256 :: asm (mem_addr: ^__m256i, a: __m256i) {
	// 	vmovntdq [mem_addr], a
	// }

	// Store 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements)
	// from `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 32-byte
	// boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_pd)
	// @(enable_target_feature="avx")
	// _mm256_stream_pd :: asm (mem_addr: ^f64, a: __m256d) {
	// 	vmovntpd [mem_addr], a
	// }

	// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements)
	// from `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 32-byte
	// boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_ps)
	// @(enable_target_feature="avx")
	// _mm256_stream_ps :: asm (mem_addr: ^f32, a: __m256) {
	// 	vmovntps [mem_addr], a
	// }

	// Copy `a` to `dst`, and insert the 64-bit integer `i` into `dst` at the location specified by `index`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_insert_epi64)
	@(require_results, enable_target_feature="avx")
	_mm256_insert_epi64 :: #force_inline proc "c" (a: __m256i, i: i64, $INDEX: i32) -> __m256i where 0 <= INDEX, INDEX < 4 {
		return simd.replace(a, INDEX, i)
	}

	// Extract a 64-bit integer from `a`, selected with `index`, and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_extract_epi64)
	@(require_results, enable_target_feature="avx")
	_mm256_extract_epi64 :: #force_inline proc "c" (a: __m256i, $INDEX: i32) -> i64 where 0 <= INDEX, INDEX < 4 {
		return simd.extract(a, INDEX)
	}
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.avx.round.pd.256")      llvm_roundpd256    :: proc(a: simd.f64x4, b: i32) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx.round.ps.256")      llvm_roundps256    :: proc(a: simd.f32x8, b: i32) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.dp.ps.256")         llvm_vdpps         :: proc(a, b: simd.f32x8, imm8: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.sse2.cmp.pd")           llvm_vcmppd        :: proc(a, b: simd.f64x2, imm8: i8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx.cmp.pd.256")        llvm_vcmppd256     :: proc(a, b: simd.f64x4, imm8: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.sse.cmp.ps")            llvm_vcmpps        :: proc(a, b: simd.f32x4, imm8: i8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx.cmp.ps.256")        llvm_vcmpps256     :: proc(a, b: simd.f32x8, imm8: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.sse2.cmp.sd")           llvm_vcmpsd        :: proc(a, b: simd.f64x2, imm8: i8) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse.cmp.ss")            llvm_vcmpss        :: proc(a, b: simd.f32x4, imm8: i8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx.cvt.ps2dq.256")     llvm_vcvtps2dq     :: proc(a: simd.f32x8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx.cvtt.pd2dq.256")    llvm_vcvttpd2dq    :: proc(a: simd.f64x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx.cvt.pd2dq.256")     llvm_vcvtpd2dq     :: proc(a: simd.f64x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx.cvtt.ps2dq.256")    llvm_vcvttps2dq    :: proc(a: simd.f32x8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx.vzeroall")          llvm_vzeroall      :: proc() ---
	@(link_name="llvm.x86.avx.vzeroupper")        llvm_vzeroupper    :: proc() ---
	@(link_name="llvm.x86.avx.vpermilvar.ps.256") llvm_vpermilps256  :: proc(a: simd.f32x8, b: simd.i32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.vpermilvar.ps")     llvm_vpermilps     :: proc(a: simd.f32x4, b: simd.i32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx.vpermilvar.pd.256") llvm_vpermilpd256  :: proc(a: simd.f64x4, b: simd.i64x4) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx.vpermilvar.pd")     llvm_vpermilpd     :: proc(a: simd.f64x2, b: simd.i64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx.ldu.dq.256")        llvm_vlddqu        :: proc(mem_addr: rawptr) -> simd.i8x32 ---
	@(link_name="llvm.x86.avx.rcp.ps.256")        llvm_vrcpps        :: proc(a: simd.f32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.rsqrt.ps.256")      llvm_vrsqrtps      :: proc(a: simd.f32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.ptestnzc.256")      llvm_ptestnzc256   :: proc(a, b: simd.i64x4) -> i32 ---
	@(link_name="llvm.x86.avx.vtestz.pd.256")     llvm_vtestzpd256   :: proc(a, b: simd.f64x4) -> i32 ---
	@(link_name="llvm.x86.avx.vtestc.pd.256")     llvm_vtestcpd256   :: proc(a, b: simd.f64x4) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.pd.256")   llvm_vtestnzcpd256 :: proc(a, b: simd.f64x4) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.pd")       llvm_vtestnzcpd    :: proc(a, b: simd.f64x2) -> i32 ---
	@(link_name="llvm.x86.avx.vtestz.ps.256")     llvm_vtestzps256   :: proc(a, b: simd.f32x8) -> i32 ---
	@(link_name="llvm.x86.avx.vtestc.ps.256")     llvm_vtestcps256   :: proc(a, b: simd.f32x8) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.ps.256")   llvm_vtestnzcps256 :: proc(a, b: simd.f32x8) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.ps")       llvm_vtestnzcps    :: proc(a, b: simd.f32x4) -> i32 ---
	@(link_name="llvm.x86.avx.min.ps.256")        llvm_vminps        :: proc(a, b: simd.f32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.max.ps.256")        llvm_vmaxps        :: proc(a, b: simd.f32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx.min.pd.256")        llvm_vminpd        :: proc(a, b: simd.f64x4) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx.max.pd.256")        llvm_vmaxpd        :: proc(a, b: simd.f64x4) -> simd.f64x4 ---
}
