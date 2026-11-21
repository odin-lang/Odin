#+build i386, amd64
package simd_x86

import "core:simd"

// Compute the absolute value of packed signed 32-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_abs_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_abs_epi32 :: #force_inline proc "c" (a: __m512i) -> __m512i {
	b := transmute(simd.i32x16)a
	c := simd.select(simd.lanes_lt(b, simd.i32x16(0)), simd.neg(b), b)
	return transmute(__m512i)c
}

// Compute the absolute value of packed signed 64-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_abs_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_abs_epi64 :: #force_inline proc "c" (a: __m512i) -> __m512i {
	return simd.select(simd.lanes_lt(a, simd.i64x8(0)), simd.neg(a), a)
}

// Compute the absolute value of packed signed 64-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_abs_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_abs_epi64 :: #force_inline proc "c" (a: __m256i) -> __m256i {
	return simd.select(simd.lanes_lt(a, simd.i64x4(0)), simd.neg(a), a)
}

// Compute the absolute value of packed signed 64-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_abs_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_abs_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return simd.select(simd.lanes_lt(a, simd.i64x2(0)), simd.neg(a), a)
}

// Finds the absolute value of each packed single-precision (32-bit) floating-point element in `a`,
// storing the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_abs_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_abs_ps :: #force_inline proc "c" (a: __m512) -> __m512 {
	return simd.abs(a)
}

// Finds the absolute value of each packed double-precision (64-bit) floating-point element in `a`,
// storing the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_abs_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_abs_pd :: #force_inline proc "c" (a: __m512d) -> __m512d {
	return simd.abs(a)
}

// Add packed 32-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_add_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.add(transmute(simd.i32x16)a, transmute(simd.i32x16)b)
}

// Add packed 64-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_add_epi64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.add(a, b)
}

// Add packed single-precision (32-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_add_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return simd.add(a, b)
}

// Add packed double-precision (64-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_add_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return simd.add(a, b)
}

// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.sub(transmute(simd.i32x16)a, transmute(simd.i32x16)b)
}

// Subtract packed 64-bit integers in `b` from packed 64-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_epi64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.sub(a, b)
}

// Subtract packed single-precision (32-bit) floating-point elements in `b` from packed single-precision (32-bit)
// floating-point elements in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return simd.sub(a, b)
}

// Subtract packed double-precision (64-bit) floating-point elements in `b` from packed double-precision (64-bit)
// floating-point elements in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return simd.sub(a, b)
}

// Multiply the low signed 32-bit integers from each packed 64-bit element in `a` and `b`,
// and store the signed 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	c := cast(__m512i)(cast(simd.i32x8)a)
	d := cast(__m512i)(cast(simd.i32x8)b)
	return simd.mul(c, d)
}

// Multiply the packed 32-bit integers in `a` and `b`, producing intermediate 64-bit integers,
// and store the low 32 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mullo_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mullo_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.mul(transmute(simd.i32x16)a, transmute(simd.i32x16)b)
}

// Multiplies elements in packed 64-bit integer vectors `a` and `b` together,
// storing the lower 64 bits of the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mullox_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_mullox_epi64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.mul(a, b)
}

// Multiply the low unsigned 32-bit integers from each packed 64-bit element in `a` and `b`,
// and store the unsigned 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_epu32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	c := transmute(simd.u64x8)a
	d := transmute(simd.u64x8)b
	m := simd.u64x8(max(u32))
	return transmute(__m512i)simd.mul(simd.bit_and(c, m), simd.bit_and(d, m))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return simd.mul(a, b)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return simd.mul(a, b)
}

// Divide packed single-precision (32-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_div_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_div_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return simd.div(a, b)
}

// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_div_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_div_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return simd.div(a, b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_max_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.max(transmute(simd.i32x16)a, transmute(simd.i32x16)b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_max_epi64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.max(a, b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_max_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.max(a, b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_max_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.max(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_max_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return llvm_vmaxps(a, b, _MM_FROUND_CUR_DIRECTION)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_max_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return llvm_vmaxpd(a, b, _MM_FROUND_CUR_DIRECTION)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_max_epu32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.max(transmute(simd.u32x16)a, transmute(simd.u32x16)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_epu64)
@(require_results, enable_target_feature="avx512f")
_mm512_max_epu64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.max(transmute(simd.u64x8)a, transmute(simd.u64x8)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_epu64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_max_epu64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.max(transmute(simd.u64x4)a, transmute(simd.u64x4)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epu64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_max_epu64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.u64x2)a, transmute(simd.u64x2)b)
}

// Compare packed signed 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_min_epi32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.min(transmute(simd.i32x16)a, transmute(simd.i32x16)b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_min_epi64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.min(a, b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_min_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return simd.min(a, b)
}

// Compare packed signed 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_min_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.min(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_min_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return llvm_vminps(a, b, _MM_FROUND_CUR_DIRECTION)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_min_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return llvm_vminpd(a, b, _MM_FROUND_CUR_DIRECTION)
}

// Compare packed unsigned 32-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_min_epu32 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.min(transmute(simd.u32x16)a, transmute(simd.u32x16)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_epu64)
@(require_results, enable_target_feature="avx512f")
_mm512_min_epu64 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)simd.min(transmute(simd.u64x8)a, transmute(simd.u64x8)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_epu64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_min_epu64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)simd.min(transmute(simd.u64x4)a, transmute(simd.u64x4)b)
}

// Compare packed unsigned 64-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epu64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_min_epu64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.u64x2)a, transmute(simd.u64x2)b)
}

// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sqrt_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_sqrt_ps :: #force_inline proc "c" (a: __m512) -> __m512 {
	return simd.sqrt(a)
}

// Compute the square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sqrt_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_sqrt_pd :: #force_inline proc "c" (a: __m512d) -> __m512d {
	return simd.sqrt(a)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmadd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmadd_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.fused_mul_add(a, b, c)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmadd_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmadd_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.fused_mul_add(a, b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsub_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsub_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsub_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsub_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmaddsub_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmaddsub_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		16, 1, 18,  3, 20,  5, 22,  7,
		24, 9, 26, 11, 28, 13, 30, 15,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmaddsub_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmaddsub_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		8, 1, 10, 3, 12, 5, 14, 7,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsubadd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsubadd_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 17,  2, 19,  4, 21,  6, 23,
		8, 25, 10, 27, 12, 29, 14, 31,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsubadd_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsubadd_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 9, 2, 11, 4, 13, 6, 15,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmadd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmadd_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmadd_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmadd_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmsub_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmsub_ps :: #force_inline proc "c" (a, b, c: __m512) -> __m512 {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmsub_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmsub_pd :: #force_inline proc "c" (a, b, c: __m512d) -> __m512d {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_rcp14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_rcp14_ps :: #force_inline proc "c" (a: __m512) -> __m512 {
	return llvm_vrcp14ps(a, __m512(0), max(u16))
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_rcp14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_rcp14_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512) -> __m512 {
	return llvm_vrcp14ps(a, src, k)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_rcp14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_rcp14_ps :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512 {
	return llvm_vrcp14ps(a, __m512(0), k)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_rcp14_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrcp14ps256(a, __m256(0), max(u8))
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_rcp14_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m256) -> __m256 {
	return llvm_vrcp14ps256(a, src, k)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_rcp14_ps :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m256 {
	return llvm_vrcp14ps256(a, __m256(0), k)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_rcp14_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_vrcp14ps128(a, __m128(0), 0b00001111)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_rcp14_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a: __m128) -> __m128 {
	return llvm_vrcp14ps128(a, src, k)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_rcp14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_rcp14_ps :: #force_inline proc "c" (k: __mmask8, a: __m128) -> __m128 {
	return llvm_vrcp14ps128(a, __m128(0), k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_rcp14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_rcp14_pd :: #force_inline proc "c" (a: __m512d) -> __m512d {
	return llvm_vrcp14pd(a, __m512d(0), max(u8))
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_rcp14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_rcp14_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vrcp14pd(a, src, k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_rcp14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_rcp14_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vrcp14pd(a, __m512d(0), k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_rcp14_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return llvm_vrcp14pd256(a, __m256d(0), 0b00001111)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_rcp14_pd :: #force_inline proc "c" (src: __m256d, k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vrcp14pd256(a, src, k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_rcp14_pd :: #force_inline proc "c" (k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vrcp14pd256(a, __m256d(0), k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_rcp14_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return llvm_vrcp14pd128(a, __m128d(0), 0b00000011)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_rcp14_pd :: #force_inline proc "c" (src: __m128d, k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vrcp14pd128(a, src, k)
}

// Compute the approximate reciprocal of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_rcp14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_rcp14_pd :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vrcp14pd128(a, __m128d(0), k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_rsqrt14_ps :: #force_inline proc "c" (a: __m512) -> __m512 {
	return llvm_vrsqrt14ps(a, __m512(0), max(u16))
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_rsqrt14_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512) -> __m512 {
	return llvm_vrsqrt14ps(a, src, k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_rsqrt14_ps :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512 {
	return llvm_vrsqrt14ps(a, __m512(0), k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_rsqrt14_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrsqrt14ps256(a, __m256(0), max(u8))
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_rsqrt14_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m256) -> __m256 {
	return llvm_vrsqrt14ps256(a, src, k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_rsqrt14_ps :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m256 {
	return llvm_vrsqrt14ps256(a, __m256(0), k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_rsqrt14_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_vrsqrt14ps128(a, __m128(0), 0b00001111)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_rsqrt14_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a: __m128) -> __m128 {
	return llvm_vrsqrt14ps128(a, src, k)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_rsqrt14_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_rsqrt14_ps :: #force_inline proc "c" (k: __mmask8, a: __m128) -> __m128 {
	return llvm_vrsqrt14ps128(a, __m128(0), k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_rsqrt14_pd :: #force_inline proc "c" (a: __m512d) -> __m512d {
	return llvm_vrsqrt14pd(a, __m512d(0), max(u8))
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_rsqrt14_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vrsqrt14pd(a, src, k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_rsqrt14_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vrsqrt14pd(a, __m512d(0), k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_rsqrt14_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return llvm_vrsqrt14pd256(a, __m256d(0), 0b00001111)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_rsqrt14_pd :: #force_inline proc "c" (src: __m256d, k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vrsqrt14pd256(a, src, k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_rsqrt14_pd :: #force_inline proc "c" (k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vrsqrt14pd256(a, __m256d(0), k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_rsqrt14_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return llvm_vrsqrt14pd128(a, __m128d(0), 0b00000011)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_rsqrt14_pd :: #force_inline proc "c" (src: __m128d, k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vrsqrt14pd128(a, src, k)
}

// Compute the approximate reciprocal square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). The maximum relative error for this approximation is less than `2^-14`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_rsqrt14_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_rsqrt14_pd :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vrsqrt14pd128(a, __m128d(0), k)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getexp_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_getexp_ps :: #force_inline proc "c" (a: __m512) -> __m512 {
	return llvm_vgetexpps(a, __m512(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getexp_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getexp_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512) -> __m512 {
	return llvm_vgetexpps(a, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getexp_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getexp_ps :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512 {
	return llvm_vgetexpps(a, __m512(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_getexp_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vgetexpps256(a, __m256(0), max(u8))
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_getexp_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m256) -> __m256 {
	return llvm_vgetexpps256(a, src, k)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_getexp_ps :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m256 {
	return llvm_vgetexpps256(a, __m256(0), k)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_getexp_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_vgetexpps128(a, __m128(0), 0b00001111)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_getexp_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a: __m128) -> __m128 {
	return llvm_vgetexpps128(a, src, k)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_getexp_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_getexp_ps :: #force_inline proc "c" (k: __mmask8, a: __m128) -> __m128 {
	return llvm_vgetexpps128(a, __m128(0), k)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getexp_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_getexp_pd :: #force_inline proc "c" (a: __m512d) -> __m512d {
	return llvm_vgetexppd(a, __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getexp_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getexp_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vgetexppd(a, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getexp_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getexp_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m512d {
	return llvm_vgetexppd(a, __m512d(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_getexp_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return llvm_vgetexppd256(a, __m256d(0), 0b00001111)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_getexp_pd :: #force_inline proc "c" (src: __m256d, k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vgetexppd256(a, src, k)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_getexp_pd :: #force_inline proc "c" (k: __mmask8, a: __m256d) -> __m256d {
	return llvm_vgetexppd256(a, __m256d(0), k)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_getexp_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return llvm_vgetexppd128(a, __m128d(0), 0b00000011)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_getexp_pd :: #force_inline proc "c" (src: __m128d, k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vgetexppd128(a, src, k)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_getexp_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_getexp_pd :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128d {
	return llvm_vgetexppd128(a, __m128d(0), k)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_roundscale_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_roundscale_ps :: #force_inline proc "c" (a: __m512, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps(a, IMM8, __m512(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_roundscale_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_roundscale_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps(a, IMM8, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_roundscale_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_roundscale_ps :: #force_inline proc "c" (k: __mmask16, a: __m512, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps(a, IMM8, __m512(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_roundscale_ps :: #force_inline proc "c" (a: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps256(a, IMM8, __m256(0), max(u8))
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_roundscale_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps256(a, IMM8, src, k)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_roundscale_ps :: #force_inline proc "c" (k: __mmask8, a: __m256, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps256(a, IMM8, __m256(0), k)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_roundscale_ps :: #force_inline proc "c" (a: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps128(a, IMM8, __m128(0), 0b00001111)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_roundscale_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps128(a, IMM8, src, k)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_roundscale_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_roundscale_ps :: #force_inline proc "c" (k: __mmask8, a: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscaleps128(a, IMM8, __m128(0), k)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_roundscale_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_roundscale_pd :: #force_inline proc "c" (a: __m512d, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd(a, IMM8, __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_roundscale_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_roundscale_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd(a, IMM8, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_roundscale_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_roundscale_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd(a, IMM8, __m512d(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_roundscale_pd :: #force_inline proc "c" (a: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd256(a, IMM8, __m256d(0), 0b00001111)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_roundscale_pd :: #force_inline proc "c" (src: __m256d, k: __mmask8, a: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd256(a, IMM8, src, k)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_roundscale_pd :: #force_inline proc "c" (k: __mmask8, a: __m256d, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd256(a, IMM8, __m256d(0), k)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_roundscale_pd :: #force_inline proc "c" (a: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd128(a, IMM8, __m128d(0), 0b00000011)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_roundscale_pd :: #force_inline proc "c" (src: __m128d, k: __mmask8, a: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd128(a, IMM8, src, k)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_roundscale_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_roundscale_pd :: #force_inline proc "c" (k: __mmask8, a: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vrndscalepd128(a, IMM8, __m128d(0), k)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_scalef_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_scalef_ps :: #force_inline proc "c" (a, b: __m512) -> __m512 {
	return llvm_vscalefps(a, b, __m512(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_scalef_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_scalef_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a, b: __m512) -> __m512 {
	return llvm_vscalefps(a, b, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_scalef_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_scalef_ps :: #force_inline proc "c" (k: __mmask16, a, b: __m512) -> __m512 {
	return llvm_vscalefps(a, b, __m512(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_scalef_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return llvm_vscalefps256(a, b, __m256(0), max(u8))
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_scalef_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a, b: __m256) -> __m256 {
	return llvm_vscalefps256(a, b, src, k)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_scalef_ps :: #force_inline proc "c" (k: __mmask8, a, b: __m256) -> __m256 {
	return llvm_vscalefps256(a, b, __m256(0), k)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_scalef_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_vscalefps128(a, b, __m128(0), 0b00001111)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_scalef_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a, b: __m128) -> __m128 {
	return llvm_vscalefps128(a, b, src, k)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_scalef_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_scalef_ps :: #force_inline proc "c" (k: __mmask8, a, b: __m128) -> __m128 {
	return llvm_vscalefps128(a, b, __m128(0), k)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_scalef_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_scalef_pd :: #force_inline proc "c" (a, b: __m512d) -> __m512d {
	return llvm_vscalefpd(a, b, __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_scalef_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_scalef_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a, b: __m512d) -> __m512d {
	return llvm_vscalefpd(a, b, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_scalef_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_scalef_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m512d) -> __m512d {
	return llvm_vscalefpd(a, b, __m512d(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_scalef_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return llvm_vscalefpd256(a, b, __m256d(0), 0b00001111)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_scalef_pd :: #force_inline proc "c" (src: __m256d, k: __mmask8, a, b: __m256d) -> __m256d {
	return llvm_vscalefpd256(a, b, src, k)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_scalef_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m256d) -> __m256d {
	return llvm_vscalefpd256(a, b, __m256d(0), k)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_scalef_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_vscalefpd128(a, b, __m128d(0), 0b00000011)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_scalef_pd :: #force_inline proc "c" (src: __m128d, k: __mmask8, a, b: __m128d) -> __m128d {
	return llvm_vscalefpd128(a, b, src, k)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_scalef_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_scalef_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m128d) -> __m128d {
	return llvm_vscalefpd128(a, b, __m128d(0), k)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fixupimm_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fixupimm_ps :: #force_inline proc "c" (a, b: __m512, c: __m512i, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps(a, b, transmute(simd.i32x16)c, IMM8, max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_fixupimm_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_fixupimm_ps :: #force_inline proc "c" (a: __m512, k: __mmask16, b: __m512, c: __m512i, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps(a, b, transmute(simd.i32x16)c, IMM8, k, _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_fixupimm_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_fixupimm_ps :: #force_inline proc "c" (k: __mmask16, a, b: __m512, c: __m512i, $IMM8: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpsz(a, b, transmute(simd.i32x16)c, IMM8, k, _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_fixupimm_ps :: #force_inline proc "c" (a, b: __m256, c: __m256i, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps256(a, b, transmute(simd.i32x8)c, IMM8, max(u8))
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_fixupimm_ps :: #force_inline proc "c" (a: __m256, k: __mmask8, b: __m256, c: __m256i, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps256(a, b, transmute(simd.i32x8)c, IMM8, k)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_fixupimm_ps :: #force_inline proc "c" (k: __mmask8, a, b: __m256, c: __m256i, $IMM8: i32) -> __m256 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpsz256(a, b, transmute(simd.i32x8)c, IMM8, k)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_fixupimm_ps :: #force_inline proc "c" (a, b: __m128, c: __m128i, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps128(a, b, transmute(simd.i32x4)c, IMM8, 0b00001111)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_fixupimm_ps :: #force_inline proc "c" (a: __m128, k: __mmask8, b: __m128, c: __m128i, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmps128(a, b, transmute(simd.i32x4)c, IMM8, k)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_fixupimm_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_fixupimm_ps :: #force_inline proc "c" (k: __mmask8, a, b: __m128, c: __m128i, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpsz128(a, b, transmute(simd.i32x4)c, IMM8, k)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fixupimm_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fixupimm_pd :: #force_inline proc "c" (a, b: __m512d, c: __m512i, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd(a, b, c, IMM8, max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_fixupimm_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_fixupimm_pd :: #force_inline proc "c" (a: __m512d, k: __mmask8, b: __m512d, c: __m512i, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd(a, b, c, IMM8, k, _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_fixupimm_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_fixupimm_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m512d, c: __m512i, $IMM8: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpdz(a, b, c, IMM8, k, _MM_FROUND_CUR_DIRECTION)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_fixupimm_pd :: #force_inline proc "c" (a, b: __m256d, c: __m256i, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd256(a, b, c, IMM8, 0b00001111)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_fixupimm_pd :: #force_inline proc "c" (a: __m256d, k: __mmask8, b: __m256d, c: __m256i, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd256(a, b, c, IMM8, k)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_fixupimm_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m256d, c: __m256i, $IMM8: i32) -> __m256d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpdz256(a, b, c, IMM8, k)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_fixupimm_pd :: #force_inline proc "c" (a, b: __m128d, c: __m128i, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd128(a, b, c, IMM8, 0b00000011)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_fixupimm_pd :: #force_inline proc "c" (a: __m128d, k: __mmask8, b: __m128d, c: __m128i, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpd128(a, b, c, IMM8, k)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// `imm8` is used to set the required flags reporting.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_fixupimm_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_fixupimm_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m128d, c: __m128i, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return llvm_vfixupimmpdz128(a, b, c, IMM8, k)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 32-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_ternarylogic_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_ternarylogic_epi32 :: #force_inline proc "c" (a, b, c: __m512i, $IMM8: i32) -> __m512i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m512i)llvm_vpternlogd(
		transmute(simd.i32x16)a,
		transmute(simd.i32x16)b,
		transmute(simd.i32x16)c,
		IMM8,
	)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 32-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_ternarylogic_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_ternarylogic_epi32 :: #force_inline proc "c" (a, b, c: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m256i)llvm_vpternlogd256(
		transmute(simd.i32x8)a,
		transmute(simd.i32x8)b,
		transmute(simd.i32x8)c,
		IMM8,
	)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 32-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ternarylogic_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_ternarylogic_epi32 :: #force_inline proc "c" (a, b, c: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)llvm_vpternlogd128(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		transmute(simd.i32x4)c,
		IMM8,
	)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 64-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_ternarylogic_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_ternarylogic_epi64 :: #force_inline proc "c" (a, b, c: __m512i, $IMM8: i32) -> __m512i where 0 <= IMM8, IMM8 < 256 {
	return llvm_vpternlogq(a, b, c, IMM8)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 64-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_ternarylogic_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_ternarylogic_epi64 :: #force_inline proc "c" (a, b, c: __m256i, $IMM8: i32) -> __m256i where 0 <= IMM8, IMM8 < 256 {
	return llvm_vpternlogq256(a, b, c, IMM8)
}

// Bitwise ternary logic that provides the capability to implement any three-operand binary function;
// the specific binary function is specified by value in `imm8`. For each bit in each packed 64-bit integer,
// the corresponding bit from `a`, `b`, and `c` are used according to `imm8`,
// and the result is written to the corresponding bit in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ternarylogic_epi64)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_ternarylogic_epi64 :: #force_inline proc "c" (a, b, c: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return llvm_vpternlogq128(a, b, c, IMM8)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getmant_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_getmant_ps :: #force_inline proc "c" (
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, __m512(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getmant_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getmant_ps :: #force_inline proc "c" (
	src: __m512,
	k: __mmask16,
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getmant_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getmant_ps :: #force_inline proc "c" (
	k: __mmask16,
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, __m512(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_getmant_ps :: #force_inline proc "c" (
	a: __m256,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps256(a, SIGN << 2 | NORM, __m256(0), max(u8))
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_getmant_ps :: #force_inline proc "c" (
	src: __m256,
	k: __mmask8,
	a: __m256,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps256(a, SIGN << 2 | NORM, src, k)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_getmant_ps :: #force_inline proc "c" (
	k: __mmask8,
	a: __m256,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps256(a, SIGN << 2 | NORM, __m256(0), k)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_getmant_ps :: #force_inline proc "c" (
	a: __m128,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps128(a, SIGN << 2 | NORM, __m128(0), 0b00001111)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_getmant_ps :: #force_inline proc "c" (
	src: __m128,
	k: __mmask8,
	a: __m128,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps128(a, SIGN << 2 | NORM, src, k)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_getmant_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_getmant_ps :: #force_inline proc "c" (
	k: __mmask8,
	a: __m128,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantps128(a, SIGN << 2 | NORM, __m128(0), k)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getmant_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_getmant_pd :: #force_inline proc "c" (
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getmant_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getmant_pd :: #force_inline proc "c" (
	src: __m512d,
	k: __mmask8,
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getmant_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getmant_pd :: #force_inline proc "c" (
	k: __mmask8,
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, __m512d(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_getmant_pd :: #force_inline proc "c" (
	a: __m256d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd256(a, SIGN << 2 | NORM, __m256d(0), 0b00001111)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_getmant_pd :: #force_inline proc "c" (
	src: __m256d,
	k: __mmask8,
	a: __m256d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd256(a, SIGN << 2 | NORM, src, k)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_getmant_pd :: #force_inline proc "c" (
	k: __mmask8,
	a: __m256d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m256d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd256(a, SIGN << 2 | NORM, __m256d(0), k)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_getmant_pd :: #force_inline proc "c" (
	a: __m128d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd128(a, SIGN << 2 | NORM, __m128d(0), 0b00000011)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_getmant_pd :: #force_inline proc "c" (
	src: __m128d,
	k: __mmask8,
	a: __m128d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd128(a, SIGN << 2 | NORM, src, k)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_getmant_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_getmant_pd :: #force_inline proc "c" (
	k: __mmask8,
	a: __m128d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
) -> __m128d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	return llvm_vgetmantpd128(a, SIGN << 2 | NORM, __m128d(0), k)
}

// Add packed single-precision (32-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_add_round_ps :: #force_inline proc "c" (a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vaddps(a, b, ROUNDING)
}

// Add packed double-precision (64-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_add_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_add_round_pd :: #force_inline proc "c" (a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vaddpd(a, b, ROUNDING)
}

// Subtract packed single-precision (32-bit) floating-point elements in `b` from packed single-precision (32-bit)
// floating-point elements in `a`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_round_ps :: #force_inline proc "c" (a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vsubps(a, b, ROUNDING)
}

// Subtract packed double-precision (64-bit) floating-point elements in `b` from packed double-precision (64-bit)
// floating-point elements in `a`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sub_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_sub_round_pd :: #force_inline proc "c" (a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vsubpd(a, b, ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_round_ps :: #force_inline proc "c" (a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vmulps(a, b, ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mul_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mul_round_pd :: #force_inline proc "c" (a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vmulpd(a, b, ROUNDING)
}

// Divide packed single-precision (32-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_div_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_div_round_ps :: #force_inline proc "c" (a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vdivps(a, b, ROUNDING)
}

// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_div_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_div_round_pd :: #force_inline proc "c" (a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vdivpd(a, b, ROUNDING)
}

// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sqrt_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_sqrt_round_ps :: #force_inline proc "c" (a: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vsqrtps(a, ROUNDING)
}

// Compute the square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_sqrt_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_sqrt_round_pd :: #force_inline proc "c" (a: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vsqrtpd(a, ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmadd_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmadd_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132psround(a, b, c, ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmadd_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmadd_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132pdround(a, b, c, ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsub_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsub_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132psround(a, b, simd.neg(c), ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsub_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsub_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132pdround(a, b, simd.neg(c), ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmaddsub_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmaddsub_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmaddsubpsround(a, b, c, ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmaddsub_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmaddsub_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmaddsubpdround(a, b, c, ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsubadd_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsubadd_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmaddsubpsround(a, b, simd.neg(c), ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fmsubadd_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fmsubadd_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmaddsubpdround(a, b, simd.neg(c), ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmadd_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmadd_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132psround(simd.neg(a), b, c, ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmadd_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmadd_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132pdround(simd.neg(a), b, c, ROUNDING)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmsub_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmsub_round_ps :: #force_inline proc "c" (a, b, c: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132psround(simd.neg(a), b, simd.neg(c), ROUNDING)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fnmsub_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fnmsub_round_pd :: #force_inline proc "c" (a, b, c: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vfmadd132pdround(simd.neg(a), b, simd.neg(c), ROUNDING)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. Exceptions can be suppressed by passing
// `_MM_FROUND_NO_EXC` in the `sae` parameter. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_max_round_ps :: #force_inline proc "c" (a, b: __m512, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vmaxps(a, b, SAE)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. Exceptions can be suppressed by passing
// `_MM_FROUND_NO_EXC` in the `sae` parameter. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_max_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_max_round_pd :: #force_inline proc "c" (a, b: __m512d, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vmaxpd(a, b, SAE)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. Exceptions can be suppressed by passing
// `_MM_FROUND_NO_EXC` in the `sae` parameter. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_min_round_ps :: #force_inline proc "c" (a, b: __m512, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vminps(a, b, SAE)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. Exceptions can be suppressed by passing
// `_MM_FROUND_NO_EXC` in the `sae` parameter. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_min_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_min_round_pd :: #force_inline proc "c" (a, b: __m512d, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vminpd(a, b, SAE)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getexp_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_getexp_round_ps :: #force_inline proc "c" (a: __m512, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexpps(a, __m512(0), max(u16), SAE)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getexp_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getexp_round_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexpps(a, src, k, SAE)
}

// Convert the exponent of each packed single-precision (32-bit) floating-point element in `a`
// to a single-precision (32-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getexp_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getexp_round_ps :: #force_inline proc "c" (k: __mmask16, a: __m512, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexpps(a, __m512(0), k, SAE)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst`. This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getexp_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_getexp_round_pd :: #force_inline proc "c" (a: __m512d, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexppd(a, __m512d(0), max(u8), SAE)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getexp_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getexp_round_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexppd(a, src, k, SAE)
}

// Convert the exponent of each packed double-precision (64-bit) floating-point element in `a`
// to a double-precision (64-bit) floating-point number representing the integer exponent,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). This intrinsic essentially calculates `floor(log2(x))` for each element.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getexp_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getexp_round_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vgetexppd(a, __m512d(0), k, SAE)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_roundscale_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_roundscale_round_ps :: #force_inline proc "c" (a: __m512, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscaleps(a, IMM8, __m512(0), max(u16), SAE)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_roundscale_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_roundscale_round_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m512, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscaleps(a, IMM8, src, k, SAE)
}

// Round packed single-precision (32-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_roundscale_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_roundscale_round_ps :: #force_inline proc "c" (k: __mmask16, a: __m512, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscaleps(a, IMM8, __m512(0), k, SAE)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`.
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_roundscale_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_roundscale_round_pd :: #force_inline proc "c" (a: __m512d, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscalepd(a, IMM8, __m512d(0), max(u8), SAE)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_roundscale_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_roundscale_round_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512d, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscalepd(a, IMM8, src, k, SAE)
}

// Round packed double-precision (64-bit) floating-point elements in `a`
// to the number of fraction bits specified by `imm8`, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `imm8` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_roundscale_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_roundscale_round_pd :: #force_inline proc "c" (k: __mmask8, a: __m512d, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vrndscalepd(a, IMM8, __m512d(0), k, SAE)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_scalef_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_scalef_round_ps :: #force_inline proc "c" (a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefps(a, b, __m512(0), max(u16), ROUNDING)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_scalef_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_scalef_round_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefps(a, b, src, k, ROUNDING)
}

// Scale the packed single-precision (32-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_scalef_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_scalef_round_ps :: #force_inline proc "c" (k: __mmask16, a, b: __m512, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefps(a, b, __m512(0), k, ROUNDING)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_scalef_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_scalef_round_pd :: #force_inline proc "c" (a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefpd(a, b, __m512d(0), max(u8), ROUNDING)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding
// mask bit is not set). Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_scalef_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_scalef_round_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefpd(a, b, src, k, ROUNDING)
}

// Scale the packed double-precision (64-bit) floating-point elements in `a` using values from `b`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_scalef_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_scalef_round_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m512d, $ROUNDING: i32) -> __m512d {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vscalefpd(a, b, __m512d(0), k, ROUNDING)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fixupimm_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_fixupimm_round_ps :: #force_inline proc "c" (a, b: __m512, c: __m512i, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmps(a, b, transmute(simd.i32x16)c, IMM8, max(u16), SAE)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding
// mask bit is not set). `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_fixupimm_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_fixupimm_round_ps :: #force_inline proc "c" (a: __m512, k: __mmask16, b: __m512, c: __m512i, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmps(a, b, transmute(simd.i32x16)c, IMM8, k, SAE)
}

// Fix up packed single-precision (32-bit) floating-point elements in `a` and `b` using packed 32-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_fixupimm_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_fixupimm_round_ps :: #force_inline proc "c" (k: __mmask16, a, b: __m512, c: __m512i, $IMM8, $SAE: i32) -> __m512 where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmpsz(a, b, transmute(simd.i32x16)c, IMM8, k, SAE)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst`. `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_fixupimm_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_fixupimm_round_pd :: #force_inline proc "c" (a, b: __m512d, c: __m512i, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmpd(a, b, c, IMM8, max(u8), SAE)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using writemask `k` (elements are copied from `a` when the corresponding
// mask bit is not set). `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_fixupimm_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_fixupimm_round_pd :: #force_inline proc "c" (a: __m512d, k: __mmask8, b: __m512d, c: __m512i, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmpd(a, b, c, IMM8, k, SAE)
}

// Fix up packed double-precision (64-bit) floating-point elements in `a` and `b` using packed 64-bit integers in `c`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding
// mask bit is not set). `imm8` is used to set the required flags reporting. Exceptions can be suppressed
// by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_fixupimm_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_fixupimm_round_pd :: #force_inline proc "c" (k: __mmask8, a, b: __m512d, c: __m512i, $IMM8, $SAE: i32) -> __m512d where 0 <= IMM8, IMM8 < 256 {
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vfixupimmpdz(a, b, c, IMM8, k, SAE)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getmant_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_getmant_round_ps :: #force_inline proc "c" (
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, __m512(0), max(u16), SAE)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getmant_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getmant_round_ps :: #force_inline proc "c" (
	src: __m512,
	k: __mmask16,
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, src, k, SAE)
}

// Normalize the mantissas of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getmant_round_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getmant_round_ps :: #force_inline proc "c" (
	k: __mmask16,
	a: __m512,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512 {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantps(a, SIGN << 2 | NORM, __m512(0), k, SAE)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`. This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_getmant_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_getmant_round_pd :: #force_inline proc "c" (
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, __m512d(0), max(u8), SAE)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using writemask `k` (elements are copied from `src`
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_getmant_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_getmant_round_pd :: #force_inline proc "c" (
	src: __m512d,
	k: __mmask8,
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, src, k, SAE)
}

// Normalize the mantissas of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst` using zeromask `k` (elements are zeroed out
// when the corresponding mask bit is not set). This intrinsic essentially calculates `±(2^k)*|x.significand|`,
// where `k` depends on the interval range defined by `norm` and the sign depends on `sign` and the source sign.
// The mantissa is normalized to the interval specified by `norm`, which can take the following values:
//
// * `_MM_MANT_NORM_1_2`     : interval `[1, 2)`
// * `_MM_MANT_NORM_p5_2`    : interval `[0.5, 2)`
// * `_MM_MANT_NORM_p5_1`    : interval `[0.5, 1)`
// * `_MM_MANT_NORM_p75_1p5` : interval `[0.75, 1.5)`
//
// The sign is determined by `sign` which can take the following values:
//
// * `_MM_MANT_SIGN_src`  : sign = sign(src)
// * `_MM_MANT_SIGN_zero` : sign = 0
// * `_MM_MANT_SIGN_nan`  : dst = NaN if sign(src) = 1
//
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_getmant_round_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_getmant_round_pd :: #force_inline proc "c" (
	k: __mmask8,
	a: __m512d,
	$NORM: _MM_MANTISSA_NORM_ENUM,
	$SIGN: _MM_MANTISSA_SIGN_ENUM,
	$SAE: i32,
) -> __m512d {
	#assert(0 <= NORM && NORM < 16, "simd/x86: invalid NORM value")
	#assert(0 <= SIGN && SIGN <  4, "simd/x86: invalid SIGN value")
	#assert(SAE == 4 || SAE == 8 || SAE == 12, "simd/x86: invalid SAE value")
	return llvm_vgetmantpd(a, SIGN << 2 | NORM, __m512d(0), k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtps_epi32 :: #force_inline proc "c" (a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2dq(a, simd.i32x16(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtps_epi32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2dq(a, transmute(simd.i32x16)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtps_epi32 :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2dq(a, simd.i32x16(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtps_epu32 :: #force_inline proc "c" (a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2udq(a, simd.u32x16(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtps_epu32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2udq(a, transmute(simd.u32x16)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtps_epu32 :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvtps2udq(a, simd.u32x16(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtps_epu32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvtps2udq256(a, simd.u32x8(0), max(u8))
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtps_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvtps2udq256(a, transmute(simd.u32x8)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtps_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvtps2udq256(a, simd.u32x8(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtps_epu32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvtps2udq128(a, simd.u32x4(0), max(u8))
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtps_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvtps2udq128(a, transmute(simd.u32x4)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtps_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvtps2udq128(a, simd.u32x4(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtps_pd :: #force_inline proc "c" (a: __m256) -> __m512d {
	return llvm_vcvtps2pd(a, __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtps_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m256) -> __m512d {
	return llvm_vcvtps2pd(a, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtps_pd :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m512d {
	return llvm_vcvtps2pd(a, __m512d(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Performs element-by-element conversion of the lower half of packed single-precision (32-bit) floating-point elements
// in `a` to packed double-precision (64-bit) floating-point elements, storing the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtpslo_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtpslo_pd :: #force_inline proc "c" (a: __m512) -> __m512d {
	return llvm_vcvtps2pd(_mm512_castps512_ps256(a), __m512d(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Performs element-by-element conversion of the lower half of packed single-precision (32-bit) floating-point elements
// in `a` to packed double-precision (64-bit) floating-point elements, storing the results in `dst` using writemask `k`
// (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtpslo_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtpslo_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m512) -> __m512d {
	return llvm_vcvtps2pd(_mm512_castps512_ps256(a), src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtpd_ps :: #force_inline proc "c" (a: __m512d) -> __m256 {
	return llvm_vcvtpd2ps(a, __m256(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst` using writemask `k`
// (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtpd_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m512d) -> __m256 {
	return llvm_vcvtpd2ps(a, src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst` using zeromask `k`
// (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtpd_ps :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m256 {
	return llvm_vcvtpd2ps(a, __m256(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst` using writemask `k`
// (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtpd_ps)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtpd_ps :: #force_inline proc "c" (src: __m128, k: __mmask8, a: __m128d) -> __m128 {
	return llvm_vcvtpd2ps128(a, src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtpd_epi32 :: #force_inline proc "c" (a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2dq(a, simd.i32x8(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtpd_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2dq(a, transmute(simd.i32x8)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtpd_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2dq(a, simd.i32x8(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtpd_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtpd_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2dq128(a, transmute(simd.i32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtpd_epu32 :: #force_inline proc "c" (a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2udq(a, simd.u32x8(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtpd_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2udq(a, transmute(simd.u32x8)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvtpd2udq(a, simd.u32x8(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtpd_epu32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq256(a, simd.u32x4(0), max(u8))
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtpd_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq256(a, transmute(simd.u32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq256(a, simd.u32x4(0), k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtpd_epu32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq128(a, simd.u32x4(0), max(u8))
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtpd_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq128(a, transmute(simd.u32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2udq128(a, simd.u32x4(0), k)
}

// Performs an element-by-element conversion of packed double-precision (64-bit) floating-point elements in `a`
// to single-precision (32-bit) floating-point elements and stores them in `dst`. The elements are stored
// in the lower half of the results vector, while the remaining upper half locations are set to 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtpd_pslo)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtpd_pslo :: #force_inline proc "c" (a: __m512d) -> __m512 {
	b := llvm_vcvtpd2ps(a, __m256(0), max(u8), _MM_FROUND_CUR_DIRECTION)
	return simd.shuffle(b, __m256(0), 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 8, 8, 8, 8, 8)
}

// Performs an element-by-element conversion of packed double-precision (64-bit) floating-point elements in `a`
// to single-precision (32-bit) floating-point elements and stores them in `dst` using writemask `k`
// (elements are copied from `src` when the corresponding mask bit is not set). The elements are stored
// in the lower half of the results vector, while the remaining upper half locations are set to 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtpd_pslo)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtpd_pslo :: #force_inline proc "c" (src: __m512, k: __mmask8, a: __m512d) -> __m512 {
	b := llvm_vcvtpd2ps(a, _mm512_castps512_ps256(src), k, _MM_FROUND_CUR_DIRECTION)
	return simd.shuffle(b, __m256(0), 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 8, 8, 8, 8, 8)
}

// Sign extend packed 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi8_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	b := transmute(simd.i8x16)a
	return transmute(__m512i)(cast(simd.i32x16)b)
}

// Sign extend packed 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi8_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	b := transmute(simd.i8x16)a
	return cast(__m512i)simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Zero extend packed unsigned 8-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu8_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu8_epi32 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	b := transmute(simd.u8x16)a
	return transmute(__m512i)(cast(simd.i32x16)b)
}

// Zero extend packed unsigned 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu8_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu8_epi64 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	b := transmute(simd.u8x16)a
	return cast(__m512i)simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Sign extend packed 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi16_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi16_epi32 :: #force_inline proc "c" (a: __m256i) -> __m512i {
	b := transmute(simd.i16x16)a
	return transmute(__m512i)(cast(simd.i32x16)b)
}

// Sign extend packed 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi16_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	return cast(__m512i)(transmute(simd.i16x8)a)
}

// Zero extend packed unsigned 16-bit integers in `a` to packed 32-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu16_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu16_epi32 :: #force_inline proc "c" (a: __m256i) -> __m512i {
	b := transmute(simd.u16x16)a
	return transmute(__m512i)(cast(simd.i32x16)b)
}

// Zero extend packed unsigned 16-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu16_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu16_epi64 :: #force_inline proc "c" (a: __m128i) -> __m512i {
	return cast(__m512i)(transmute(simd.u16x8)a)
}

// Sign extend packed 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32_epi64 :: #force_inline proc "c" (a: __m256i) -> __m512i {
	return cast(__m512i)(transmute(simd.i32x8)a)
}

// Zero extend packed unsigned 32-bit integers in `a` to packed 64-bit integers, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu32_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu32_epi64 :: #force_inline proc "c" (a: __m256i) -> __m512i {
	return cast(__m512i)(transmute(simd.u32x8)a)
}

// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32_ps :: #force_inline proc "c" (a: __m512i) -> __m512 {
	return cast(__m512)(transmute(simd.i32x16)a)
}

// Convert packed signed 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32_pd :: #force_inline proc "c" (a: __m256i) -> __m512d {
	return cast(__m512d)(transmute(simd.i32x8)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu32_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu32_ps :: #force_inline proc "c" (a: __m512i) -> __m512 {
	return cast(__m512)(transmute(simd.u32x16)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel Software Development Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepu32_ps :: #force_inline proc "c" (a: __m256i) -> __m256 {
	return cast(__m256)(transmute(simd.u32x8)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel Software Development Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepu32_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return cast(__m128)(transmute(simd.u32x4)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu32_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu32_pd :: #force_inline proc "c" (a: __m256i) -> __m512d {
	return cast(__m512d)(transmute(simd.u32x8)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepu32_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepu32_pd :: #force_inline proc "c" (a: __m128i) -> __m256d {
	return cast(__m256d)(transmute(simd.u32x4)a)
}

// Convert packed unsigned 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepu32_pd)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepu32_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	b := transmute(simd.u32x4)a
	return cast(__m128d)simd.shuffle(b, b, 0, 1)
}

// Performs element-by-element conversion of the lower half of packed 32-bit integer elements in `a`
// to packed double-precision (64-bit) floating-point elements, storing the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32lo_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32lo_pd :: #force_inline proc "c" (a: __m512i) -> __m512d {
	b := transmute(simd.i32x16)a
	return cast(__m512d)simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Performs element-by-element conversion of the lower half of packed 32-bit unsigned integer elements in `a`
// to packed double-precision (64-bit) floating-point elements, storing the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepu32lo_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepu32lo_pd :: #force_inline proc "c" (a: __m512i) -> __m512d {
	b := transmute(simd.u32x16)a
	return cast(__m512d)simd.shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Convert packed 32-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32_epi16 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	b := transmute(simd.i32x16)a
	return transmute(__m256i)(cast(simd.i16x16)b)
}

// Convert packed 32-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepi32_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	b := transmute(simd.i32x8)a
	return transmute(__m128i)(cast(simd.i16x8)b)
}

// Convert packed 32-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepi32_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdw128(transmute(simd.i32x4)a, simd.i16x8(0), max(u8))
}

// Convert packed 32-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtepi32_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdw128(transmute(simd.i32x4)a, transmute(simd.i16x8)src, k)
}

// Convert packed 32-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtepi32_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdw128(transmute(simd.i32x4)a, simd.i16x8(0), k)
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi32_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	b := transmute(simd.i32x16)a
	return transmute(__m128i)(cast(simd.i8x16)b)
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepi32_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb256(transmute(simd.i32x8)a, simd.i8x16(0), max(u8))
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb256(transmute(simd.i32x8)a, transmute(simd.i8x16)src, k)
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb256(transmute(simd.i32x8)a, simd.i8x16(0), k)
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepi32_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb128(transmute(simd.i32x4)a, simd.i8x16(0), max(u8))
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb128(transmute(simd.i32x4)a, transmute(simd.i8x16)src, k)
}

// Convert packed 32-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovdb128(transmute(simd.i32x4)a, simd.i8x16(0), k)
}

// Convert packed 64-bit integers in `a` to packed 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi64_epi32 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	return transmute(__m256i)(cast(simd.i32x8)a)
}

// Convert packed 64-bit integers in `a` to packed 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepi64_epi32 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)(cast(simd.i32x4)a)
}

// Convert packed 64-bit integers in `a` to packed 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepi64_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqd128(a, simd.i32x4(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 32-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtepi64_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqd128(a, transmute(simd.i32x4)src, k)
}

// Convert packed 64-bit integers in `a` to packed 32-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqd128(a, simd.i32x4(0), k)
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi64_epi16 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)(cast(simd.i16x8)a)
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepi64_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw256(a, simd.i16x8(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw256(a, transmute(simd.i16x8)src, k)
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw256(a, simd.i16x8(0), k)
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepi64_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw128(a, simd.i16x8(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw128(a, transmute(simd.i16x8)src, k)
}

// Convert packed 64-bit integers in `a` to packed 16-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqw128(a, simd.i16x8(0), k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtepi64_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb(a, simd.i8x16(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb(a, transmute(simd.i8x16)src, k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb(a, simd.i8x16(0), k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtepi64_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb256(a, simd.i8x16(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb256(a, transmute(simd.i8x16)src, k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb256(a, simd.i8x16(0), k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtepi64_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb128(a, simd.i8x16(0), max(u8))
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb128(a, transmute(simd.i8x16)src, k)
}

// Convert packed 64-bit integers in `a` to packed 8-bit integers with truncation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovqb128(a, simd.i8x16(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtsepi32_epi16 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsdw(transmute(simd.i32x16)a, simd.i16x16(0), max(u16))
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtsepi32_epi16 :: #force_inline proc "c" (src: __m256i, k: __mmask16, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsdw(transmute(simd.i32x16)a, transmute(simd.i16x16)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtsepi32_epi16 :: #force_inline proc "c" (k: __mmask16, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsdw(transmute(simd.i32x16)a, simd.i16x16(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtsepi32_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw256(transmute(simd.i32x8)a, simd.i16x8(0), max(u8))
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtsepi32_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw256(transmute(simd.i32x8)a, transmute(simd.i16x8)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtsepi32_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw256(transmute(simd.i32x8)a, simd.i16x8(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtsepi32_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw128(transmute(simd.i32x4)a, simd.i16x8(0), max(u8))
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtsepi32_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw128(transmute(simd.i32x4)a, transmute(simd.i16x8)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtsepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtsepi32_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdw128(transmute(simd.i32x4)a, simd.i16x8(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtsepi32_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb(transmute(simd.i32x16)a, simd.i8x16(0), max(u16))
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtsepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask16, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb(transmute(simd.i32x16)a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtsepi32_epi8 :: #force_inline proc "c" (k: __mmask16, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb(transmute(simd.i32x16)a, simd.i8x16(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtsepi32_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb256(transmute(simd.i32x8)a, simd.i8x16(0), max(u8))
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtsepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb256(transmute(simd.i32x8)a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtsepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb256(transmute(simd.i32x8)a, simd.i8x16(0), k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtsepi32_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb128(transmute(simd.i32x4)a, simd.i8x16(0), max(u8))
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtsepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb128(transmute(simd.i32x4)a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 32-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtsepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtsepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsdb128(transmute(simd.i32x4)a, simd.i8x16(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtsepi64_epi32 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsqd(a, simd.i32x8(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtsepi64_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsqd(a, transmute(simd.i32x8)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtsepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovsqd(a, simd.i32x8(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtsepi64_epi32 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd256(a, simd.i32x4(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtsepi64_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd256(a, transmute(simd.i32x4)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtsepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd256(a, simd.i32x4(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtsepi64_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd128(a, simd.i32x4(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtsepi64_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd128(a, transmute(simd.i32x4)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 32-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtsepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtsepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqd128(a, simd.i32x4(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtsepi64_epi16 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw(a, simd.i16x8(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtsepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw(a, transmute(simd.i16x8)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtsepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw(a, simd.i16x8(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtsepi64_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw256(a, simd.i16x8(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtsepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw256(a, transmute(simd.i16x8)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtsepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw256(a, simd.i16x8(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtsepi64_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw128(a, simd.i16x8(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtsepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw128(a, transmute(simd.i16x8)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 16-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtsepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtsepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqw128(a, simd.i16x8(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtsepi64_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb(a, simd.i8x16(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtsepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb(a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtsepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb(a, simd.i8x16(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtsepi64_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb256(a, simd.i8x16(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtsepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb256(a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtsepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb256(a, simd.i8x16(0), k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtsepi64_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb128(a, simd.i8x16(0), max(u8))
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtsepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb128(a, transmute(simd.i8x16)src, k)
}

// Convert packed signed 64-bit integers in `a` to packed 8-bit integers with signed saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtsepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtsepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovsqb128(a, simd.i8x16(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtusepi32_epi16 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusdw(transmute(simd.u32x16)a, simd.u16x16(0), max(u16))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtusepi32_epi16 :: #force_inline proc "c" (src: __m256i, k: __mmask16, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusdw(transmute(simd.u32x16)a, transmute(simd.u16x16)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtusepi32_epi16 :: #force_inline proc "c" (k: __mmask16, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusdw(transmute(simd.u32x16)a, simd.u16x16(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtusepi32_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw256(transmute(simd.u32x8)a, simd.u16x8(0), max(u8))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtusepi32_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw256(transmute(simd.u32x8)a, transmute(simd.u16x8)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtusepi32_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw256(transmute(simd.u32x8)a, simd.u16x8(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtusepi32_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw128(transmute(simd.u32x4)a, simd.u16x8(0), max(u8))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtusepi32_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw128(transmute(simd.u32x4)a, transmute(simd.u16x8)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtusepi32_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtusepi32_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdw128(transmute(simd.u32x4)a, simd.u16x8(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtusepi32_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb(transmute(simd.u32x16)a, simd.u8x16(0), max(u16))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtusepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask16, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb(transmute(simd.u32x16)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtusepi32_epi8 :: #force_inline proc "c" (k: __mmask16, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb(transmute(simd.u32x16)a, simd.u8x16(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtusepi32_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb256(transmute(simd.u32x8)a, simd.u8x16(0), max(u8))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtusepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb256(transmute(simd.u32x8)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtusepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb256(transmute(simd.u32x8)a, simd.u8x16(0), k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtusepi32_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb128(transmute(simd.u32x4)a, simd.u8x16(0), max(u8))
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtusepi32_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb128(transmute(simd.u32x4)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 32-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtusepi32_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtusepi32_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusdb128(transmute(simd.u32x4)a, simd.u8x16(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtusepi64_epi32 :: #force_inline proc "c" (a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusqd(transmute(simd.u64x8)a, simd.u32x8(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtusepi64_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusqd(transmute(simd.u64x8)a, transmute(simd.u32x8)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtusepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m256i {
	return transmute(__m256i)llvm_vpmovusqd(transmute(simd.u64x8)a, simd.u32x8(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtusepi64_epi32 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd256(transmute(simd.u64x4)a, simd.u32x4(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtusepi64_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd256(transmute(simd.u64x4)a, transmute(simd.u32x4)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtusepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd256(transmute(simd.u64x4)a, simd.u32x4(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtusepi64_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd128(transmute(simd.u64x2)a, simd.u32x4(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtusepi64_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd128(transmute(simd.u64x2)a, transmute(simd.u32x4)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 32-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtusepi64_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtusepi64_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqd128(transmute(simd.u64x2)a, simd.u32x4(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtusepi64_epi16 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw(transmute(simd.u64x8)a, simd.u16x8(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtusepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw(transmute(simd.u64x8)a, transmute(simd.u16x8)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtusepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw(transmute(simd.u64x8)a, simd.u16x8(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtusepi64_epi16 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw256(transmute(simd.u64x4)a, simd.u16x8(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtusepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw256(transmute(simd.u64x4)a, transmute(simd.u16x8)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtusepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw256(transmute(simd.u64x4)a, simd.u16x8(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtusepi64_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw128(transmute(simd.u64x2)a, simd.u16x8(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtusepi64_epi16 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw128(transmute(simd.u64x2)a, transmute(simd.u16x8)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 16-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtusepi64_epi16)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtusepi64_epi16 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqw128(transmute(simd.u64x2)a, simd.u16x8(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtusepi64_epi8 :: #force_inline proc "c" (a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb(transmute(simd.u64x8)a, simd.u8x16(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtusepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb(transmute(simd.u64x8)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtusepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m512i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb(transmute(simd.u64x8)a, simd.u8x16(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvtusepi64_epi8 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb256(transmute(simd.u64x4)a, simd.u8x16(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtusepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb256(transmute(simd.u64x4)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtusepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m256i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb256(transmute(simd.u64x4)a, simd.u8x16(0), k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvtusepi64_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb128(transmute(simd.u64x2)a, simd.u8x16(0), max(u8))
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtusepi64_epi8 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb128(transmute(simd.u64x2)a, transmute(simd.u8x16)src, k)
}

// Convert packed unsigned 64-bit integers in `a` to packed unsigned 8-bit integers with unsigned saturation,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtusepi64_epi8)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtusepi64_epi8 :: #force_inline proc "c" (k: __mmask8, a: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vpmovusqb128(transmute(simd.u64x2)a, simd.u8x16(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundps_epi32 :: #force_inline proc "c" (a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2dq(a, simd.i32x16(0), max(u16), ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundps_epi32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2dq(a, transmute(simd.i32x16)src, k, ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundps_epi32 :: #force_inline proc "c" (k: __mmask16, a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2dq(a, simd.i32x16(0), k, ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundps_epu32 :: #force_inline proc "c" (a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2udq(a, simd.u32x16(0), max(u16), ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundps_epu32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2udq(a, transmute(simd.u32x16)src, k, ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundps_epu32 :: #force_inline proc "c" (k: __mmask16, a: __m512, $ROUNDING: i32) -> __m512i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m512i)llvm_vcvtps2udq(a, simd.u32x16(0), k, ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundps_pd :: #force_inline proc "c" (a: __m256, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtps2pd(a, __m512d(0), max(u8), SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundps_pd :: #force_inline proc "c" (src: __m512d, k: __mmask8, a: __m256, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtps2pd(a, src, k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed double-precision (64-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundps_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundps_pd :: #force_inline proc "c" (k: __mmask8, a: __m256, $SAE: i32) -> __m512d {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtps2pd(a, __m512d(0), k, SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundpd_epi32 :: #force_inline proc "c" (a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2dq(a, simd.i32x8(0), max(u8), ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundpd_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2dq(a, transmute(simd.i32x8)src, k, ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundpd_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2dq(a, simd.i32x8(0), k, ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundpd_epu32 :: #force_inline proc "c" (a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2udq(a, simd.u32x8(0), max(u8), ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundpd_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2udq(a, transmute(simd.u32x8)src, k, ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed unsigned 32-bit integers,
// and store the results in `dst` using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256i {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtpd2udq(a, simd.u32x8(0), k, ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundpd_ps :: #force_inline proc "c" (a: __m512d, $ROUNDING: i32) -> __m256 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vcvtpd2ps(a, __m256(0), max(u8), ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundpd_ps :: #force_inline proc "c" (src: __m256, k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vcvtpd2ps(a, src, k, ROUNDING)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundpd_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundpd_ps :: #force_inline proc "c" (k: __mmask8, a: __m512d, $ROUNDING: i32) -> __m256 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vcvtpd2ps(a, __m256(0), k, ROUNDING)
}

// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundepi32_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundepi32_ps :: #force_inline proc "c" (a: __m512i, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vcvtdq2ps(transmute(simd.i32x16)a, ROUNDING)
}

// Convert packed unsigned 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`. Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundepu32_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundepu32_ps :: #force_inline proc "c" (a: __m512i, $ROUNDING: i32) -> __m512 {
	#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
	return llvm_vcvtudq2ps(transmute(simd.u32x16)a, ROUNDING)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundps_ph :: #force_inline proc "c" (a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, simd.i16x16(0), max(u16))
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundps_ph :: #force_inline proc "c" (src: __m256i, k: __mmask16, a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, transmute(simd.i16x16)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundps_ph :: #force_inline proc "c" (k: __mmask16, a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, simd.i16x16(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvt_roundps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvt_roundps_ph :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph256(a, ROUNDING, transmute(simd.i16x8)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvt_roundps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvt_roundps_ph :: #force_inline proc "c" (k: __mmask8, a: __m256, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph256(a, ROUNDING, simd.i16x8(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvt_roundps_ph :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph128(a, ROUNDING, transmute(simd.i16x8)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvt_roundps_ph :: #force_inline proc "c" (k: __mmask8, a: __m128, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph128(a, ROUNDING, simd.i16x8(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`.
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtps_ph :: #force_inline proc "c" (a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, simd.i16x16(0), max(u16))
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtps_ph :: #force_inline proc "c" (src: __m256i, k: __mmask16, a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, transmute(simd.i16x16)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
// * `_MM_FROUND_CUR_DIRECTION`  | `_MM_FROUND_NO_EXC` : use `MXCSR.RC` and suppress exceptions - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtps_ph)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtps_ph :: #force_inline proc "c" (k: __mmask16, a: __m512, $ROUNDING: i32) -> __m256i {
	#assert((ROUNDING & 7) < 5 && (ROUNDING &~ 15) == 0, "simd/x86: invalid ROUNDING value")
	return transmute(__m256i)llvm_vcvtps2ph(a, ROUNDING, simd.i16x16(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvtps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvtps_ph :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph256(a, ROUNDING, transmute(simd.i16x8)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvtps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvtps_ph :: #force_inline proc "c" (k: __mmask8, a: __m256, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph256(a, ROUNDING, simd.i16x8(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvtps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvtps_ph :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph128(a, ROUNDING, transmute(simd.i16x8)src, k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed half-precision (16-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Rounding is done according to the `rounding` parameter, which can be one of:
//
// * `_MM_FROUND_TO_NEAREST_INT` : round to nearest
// * `_MM_FROUND_TO_NEG_INF`     : round down
// * `_MM_FROUND_TO_POS_INF`     : round up
// * `_MM_FROUND_TO_ZERO`        : truncate
// * `_MM_FROUND_CUR_DIRECTION`  : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvtps_ph)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvtps_ph :: #force_inline proc "c" (k: __mmask8, a: __m128, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph128(a, ROUNDING, simd.i16x8(0), k)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvt_roundph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvt_roundph_ps :: #force_inline proc "c" (a: __m256i, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, __m512(0), max(u16), SAE)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvt_roundph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvt_roundph_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m256i, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, src, k, SAE)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvt_roundph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvt_roundph_ps :: #force_inline proc "c" (k: __mmask16, a: __m256i, $SAE: i32) -> __m512 {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, __m512(0), k, SAE)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtph_ps :: #force_inline proc "c" (a: __m256i) -> __m512 {
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, __m512(0), max(u16), _MM_FROUND_NO_EXC)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtph_ps :: #force_inline proc "c" (src: __m512, k: __mmask16, a: __m256i) -> __m512 {
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, src, k, _MM_FROUND_NO_EXC)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtph_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtph_ps :: #force_inline proc "c" (k: __mmask16, a: __m256i) -> __m512 {
	return llvm_vcvtph2ps(transmute(simd.i16x16)a, __m512(0), k, _MM_FROUND_NO_EXC)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtt_roundps_epi32 :: #force_inline proc "c" (a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2dq(a, simd.i32x16(0), max(u16), SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtt_roundps_epi32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2dq(a, transmute(simd.i32x16)src, k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtt_roundps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtt_roundps_epi32 :: #force_inline proc "c" (k: __mmask16, a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2dq(a, simd.i32x16(0), k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtt_roundps_epu32 :: #force_inline proc "c" (a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2udq(a, simd.u32x16(0), max(u16), SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtt_roundps_epu32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2udq(a, transmute(simd.u32x16)src, k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtt_roundps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtt_roundps_epu32 :: #force_inline proc "c" (k: __mmask16, a: __m512, $SAE: i32) -> __m512i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m512i)llvm_vcvttps2udq(a, simd.u32x16(0), k, SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtt_roundpd_epi32 :: #force_inline proc "c" (a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2dq(a, simd.i32x8(0), max(u8), SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtt_roundpd_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2dq(a, transmute(simd.i32x8)src, k, SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtt_roundpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtt_roundpd_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2dq(a, simd.i32x8(0), k, SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvtt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvtt_roundpd_epu32 :: #force_inline proc "c" (a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2udq(a, simd.i32x8(0), max(u8), SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvtt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvtt_roundpd_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2udq(a, transmute(simd.i32x8)src, k, SAE)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
// Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvtt_roundpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvtt_roundpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m512d, $SAE: i32) -> __m256i {
	#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
	return transmute(__m256i)llvm_vcvttpd2udq(a, simd.i32x8(0), k, SAE)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvttps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvttps_epi32 :: #force_inline proc "c" (a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2dq(a, simd.i32x16(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvttps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvttps_epi32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2dq(a, transmute(simd.i32x16)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvttps_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvttps_epi32 :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2dq(a, simd.i32x16(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvttps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvttps_epu32 :: #force_inline proc "c" (a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2udq(a, simd.u32x16(0), max(u16), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvttps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvttps_epu32 :: #force_inline proc "c" (src: __m512i, k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2udq(a, transmute(simd.u32x16)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvttps_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvttps_epu32 :: #force_inline proc "c" (k: __mmask16, a: __m512) -> __m512i {
	return transmute(__m512i)llvm_vcvttps2udq(a, simd.u32x16(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvttps_epu32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvttps2udq256(a, simd.u32x8(0), max(u8))
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvttps_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvttps2udq256(a, transmute(simd.u32x8)src, k)
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvttps_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvttps2udq256(a, simd.u32x8(0), k)
}

// Convert packed single-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvttps_epu32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvttps2udq128(a, simd.u32x4(0), max(u8))
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvttps_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvttps2udq128(a, transmute(simd.u32x4)src, k)
}

// Convert packed double-precision (32-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvttps_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvttps_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m128) -> __m128i {
	return transmute(__m128i)llvm_vcvttps2udq128(a, simd.u32x4(0), k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvttpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvttpd_epi32 :: #force_inline proc "c" (a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2dq(a, simd.i32x8(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvttpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvttpd_epi32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2dq(a, transmute(simd.i32x8)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvttpd_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvttpd_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2dq(a, simd.i32x8(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvttpd_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvttpd_epi32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2dq128(a, transmute(simd.i32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvttpd_epi32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvttpd_epi32 :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2dq128(a, simd.i32x4(0), k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_cvttpd_epu32 :: #force_inline proc "c" (a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2udq(a, simd.i32x8(0), max(u8), _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_mask_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_mask_cvttpd_epu32 :: #force_inline proc "c" (src: __m256i, k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2udq(a, transmute(simd.i32x8)src, k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_maskz_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f")
_mm512_maskz_cvttpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m512d) -> __m256i {
	return transmute(__m256i)llvm_vcvttpd2udq(a, simd.i32x8(0), k, _MM_FROUND_CUR_DIRECTION)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_cvttpd_epu32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq256(a, simd.i32x4(0), max(u8))
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_mask_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_mask_cvttpd_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq256(a, transmute(simd.i32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_maskz_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm256_maskz_cvttpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq256(a, simd.i32x4(0), k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_cvttpd_epu32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq128(a, simd.i32x4(0), max(u8))
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using writemask `k` (elements are copied from `src` when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mask_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_mask_cvttpd_epu32 :: #force_inline proc "c" (src: __m128i, k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq128(a, transmute(simd.i32x4)src, k)
}

// Convert packed double-precision (64-bit) floating-point elements in `a`
// to packed unsigned 32-bit integers with truncation, and store the results in `dst`
// using zeromask `k` (elements are zeroed out when the corresponding mask bit is not set).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskz_cvttpd_epu32)
@(require_results, enable_target_feature="avx512f,avx512vl")
_mm_maskz_cvttpd_epu32 :: #force_inline proc "c" (k: __mmask8, a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2udq128(a, simd.i32x4(0), k)
}

// Return vector of type `__m512d` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setzero_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_setzero_pd :: #force_inline proc "c" () -> __m512d {
	return __m512d(0)
}

// Return vector of type `__m512` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setzero_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_setzero_ps :: #force_inline proc "c" () -> __m512 {
	return __m512(0)
}

// Return vector of type `__m512` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setzero)
@(require_results, enable_target_feature="avx512f")
_mm512_setzero :: #force_inline proc "c" () -> __m512 {
	return __m512(0)
}

// Return vector of type `__m512i` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setzero_si512)
@(require_results, enable_target_feature="avx512f")
_mm512_setzero_si512 :: #force_inline proc "c" () -> __m512i {
	return __m512i(0)
}

// Return vector of type `__m512i` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setzero_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_setzero_epi32 :: #force_inline proc "c" () -> __m512i {
	return __m512i(0)
}

// Set packed 64-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_setr_epi64 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i64) -> __m512i {
	return __m512i {e7, e6, e5, e4, e3, e2, e1, e0}
}

// Set packed 64-bit integers in `dst` with the supplied values.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_set_epi64 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i64) -> __m512i {
	return __m512i {e0, e1, e2, e3, e4, e5, e6, e7}
}

// Set packed 32-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_setr_epi32 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i32,
	e07, e06, e05, e04, e03, e02, e01, e00: i32,
) -> __m512i {
	return transmute(__m512i)(simd.i32x16 {
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	})
}

// Set packed 32-bit integers in `dst` with the supplied values.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_set_epi32 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i32,
	e07, e06, e05, e04, e03, e02, e01, e00: i32,
) -> __m512i {
	return transmute(__m512i)(simd.i32x16 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
	})
}

// Set packed 16-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_set_epi16 :: #force_inline proc "c" (
	e31, e30, e29, e28, e27, e26, e25, e24: i16,
	e23, e22, e21, e20, e19, e18, e17, e16: i16,
	e15, e14, e13, e12, e11, e10, e09, e08: i16,
	e07, e06, e05, e04, e03, e02, e01, e00: i16,
) -> __m512i {
	return transmute(__m512i)(simd.i16x32 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
		e16, e17, e18, e19, e20, e21, e22, e23,
		e24, e25, e26, e27, e28, e29, e30, e31,
	})
}

// Set packed 8-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_set_epi8 :: #force_inline proc "c" (
	e63, e62, e61, e60, e59, e58, e57, e56: i8,
	e55, e54, e53, e52, e51, e50, e49, e48: i8,
	e47, e46, e45, e44, e43, e42, e41, e40: i8,
	e39, e38, e37, e36, e35, e34, e33, e32: i8,
	e31, e30, e29, e28, e27, e26, e25, e24: i8,
	e23, e22, e21, e20, e19, e18, e17, e16: i8,
	e15, e14, e13, e12, e11, e10, e09, e08: i8,
	e07, e06, e05, e04, e03, e02, e01, e00: i8,
) -> __m512i {
	return transmute(__m512i)(simd.i8x64 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
		e16, e17, e18, e19, e20, e21, e22, e23,
		e24, e25, e26, e27, e28, e29, e30, e31,
		e32, e33, e34, e35, e36, e37, e38, e39,
		e40, e41, e42, e43, e44, e45, e46, e47,
		e48, e49, e50, e51, e52, e53, e54, e55,
		e56, e57, e58, e59, e60, e61, e62, e63,
	})
}

// Set packed 64-bit integers in `dst` with the repeated 4 element sequence in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr4_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_setr4_epi64 :: #force_inline proc "c" (e3, e2, e1, e0: i64) -> __m512i {
	return __m512i {e3, e2, e1, e0, e3, e2, e1, e0}
}

// Set packed 64-bit integers in `dst` with the repeated 4 element sequence.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set4_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_set4_epi64 :: #force_inline proc "c" (e3, e2, e1, e0: i64) -> __m512i {
	return __m512i {e0, e1, e2, e3, e0, e1, e2, e3}
}

// Set packed 32-bit integers in `dst` with the repeated 4 element sequence in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr4_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_setr4_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m512i {
	return transmute(__m512i)(simd.i32x16 {
		e3, e2, e1, e0, e3, e2, e1, e0,
		e3, e2, e1, e0, e3, e2, e1, e0,
	})
}

// Set packed 32-bit integers in `dst` with the repeated 4 element sequence.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set4_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_set4_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m512i {
	return transmute(__m512i)(simd.i32x16 {
		e0, e1, e2, e3, e0, e1, e2, e3,
		e0, e1, e2, e3, e0, e1, e2, e3,
	})
}

// Set packed double-precision (64-bit) floating-point elements in `dst`
// with the repeated 4 element sequence in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr4_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_setr4_pd :: #force_inline proc "c" (e3, e2, e1, e0: f64) -> __m512d {
	return __m512d {e3, e2, e1, e0, e3, e2, e1, e0}
}

// Set packed double-precision (64-bit) floating-point elements in `dst`
// with the repeated 4 element sequence.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set4_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_set4_pd :: #force_inline proc "c" (e3, e2, e1, e0: f64) -> __m512d {
	return __m512d {e0, e1, e2, e3, e0, e1, e2, e3}
}

// Set packed single-precision (32-bit) floating-point elements in `dst`
// with the repeated 4 element sequence in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr4_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_setr4_ps :: #force_inline proc "c" (e3, e2, e1, e0: f32) -> __m512 {
	return __m512 {
		e3, e2, e1, e0, e3, e2, e1, e0,
		e3, e2, e1, e0, e3, e2, e1, e0,
	}
}

// Set packed single-precision (32-bit) floating-point elements in `dst`
// with the repeated 4 element sequence.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set4_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_set4_ps :: #force_inline proc "c" (e3, e2, e1, e0: f32) -> __m512 {
	return __m512 {
		e0, e1, e2, e3, e0, e1, e2, e3,
		e0, e1, e2, e3, e0, e1, e2, e3,
	}
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_setr_pd :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: f64) -> __m512d {
	return __m512d {e7, e6, e5, e4, e3, e2, e1, e0}
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_set_pd :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: f64) -> __m512d {
	return __m512d {e0, e1, e2, e3, e4, e5, e6, e7}
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_setr_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_setr_ps :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: f32,
	e07, e06, e05, e04, e03, e02, e01, e00: f32,
) -> __m512 {
	return __m512 {
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	}
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_set_ps :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: f32,
	e07, e06, e05, e04, e03, e02, e01, e00: f32,
) -> __m512 {
	return __m512 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
	}
}

// Broadcast 64-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_epi64)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_epi64 :: #force_inline proc "c" (a: i64) -> __m512i {
	return __m512i(a)
}

// Broadcast 32-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_epi32)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_epi32 :: #force_inline proc "c" (a: i32) -> __m512i {
	return transmute(__m512i)simd.i32x16(a)
}

// Broadcast 16-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_epi16)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_epi16 :: #force_inline proc "c" (a: i16) -> __m512i {
	return transmute(__m512i)simd.i16x32(a)
}

// Broadcast 8-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_epi8)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_epi8 :: #force_inline proc "c" (a: i8) -> __m512i {
	return transmute(__m512i)simd.i8x64(a)
}

// Broadcast double-precision (64-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_pd)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_pd :: #force_inline proc "c" (a: f64) -> __m512d {
	return __m512d(a)
}

// Broadcast single-precision (32-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation]( https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_set1_ps)
@(require_results, enable_target_feature="avx512f")
_mm512_set1_ps :: #force_inline proc "c" (a: f32) -> __m512 {
	return __m512(a)
}

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
_mm512_xor_si512 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return simd.bit_xor(a, b)
}

// Cast vector of type `__m512` to type `__m256`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_castps512_ps256)
@(require_results, enable_target_feature="avx512f")
_mm512_castps512_ps256 :: #force_inline proc "c" (a: __m512) -> __m256 {
	return simd.shuffle(a, a, 0, 1, 2, 3, 4, 5, 6, 7)
}

when ODIN_ARCH == .amd64 {
	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtsd_i64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_cvtsd2si64(a)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtss_i64 :: #force_inline proc "c" (a: __m128) -> i64 {
		return llvm_cvtss2si64(a)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to an unsigned 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtss_u64 :: #force_inline proc "c" (a: __m128) -> u64 {
		return llvm_vcvtss2usi64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to an unsigned 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtsd_u64 :: #force_inline proc "c" (a: __m128d) -> u64 {
		return llvm_vcvtsd2usi64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the signed 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvti64_ss)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvti64_ss :: #force_inline proc "c" (a: __m128, b: i64) -> __m128 {
		return simd.replace(a, 0, cast(f32)b)
	}

	// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvti64_sd)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvti64_sd :: #force_inline proc "c" (a: __m128d, b: i64) -> __m128d {
		return simd.replace(a, 0, cast(f64)b)
	}

	// Convert the unsigned 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtu64_ss)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtu64_ss :: #force_inline proc "c" (a: __m128, b: u64) -> __m128 {
		return simd.replace(a, 0, cast(f32)b)
	}

	// Convert the unsigned 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtu64_sd)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtu64_sd :: #force_inline proc "c" (a: __m128d, b: u64) -> __m128d {
		return simd.replace(a, 0, cast(f64)b)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttsd_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvttsd_i64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_vcvttsd2si64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to an unsigned 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttsd_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvttsd_u64 :: #force_inline proc "c" (a: __m128d) -> u64 {
		return llvm_vcvttsd2usi64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttss_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvttss_i64 :: #force_inline proc "c" (a: __m128) -> i64 {
		return llvm_vcvttss2si64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to an unsigned 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttss_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvttss_u64 :: #force_inline proc "c" (a: __m128) -> u64 {
		return llvm_vcvttss2usi64(a, _MM_FROUND_CUR_DIRECTION)
	}

	// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundi64_sd)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundi64_sd :: #force_inline proc "c" (a: __m128d, b: i64, $ROUNDING: i32) -> __m128d {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsi2sd64(a, b, ROUNDING)
	}

	// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundsi64_sd)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundsi64_sd :: #force_inline proc "c" (a: __m128d, b: i64, $ROUNDING: i32) -> __m128d {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsi2sd64(a, b, ROUNDING)
	}

	// Convert the signed 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundi64_ss)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundi64_ss :: #force_inline proc "c" (a: __m128, b: i64, $ROUNDING: i32) -> __m128 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsi2ss64(a, b, ROUNDING)
	}

	// Convert the signed 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundsi64_ss)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundsi64_ss :: #force_inline proc "c" (a: __m128, b: i64, $ROUNDING: i32) -> __m128 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsi2ss64(a, b, ROUNDING)
	}

	// Convert the unsigned 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundu64_sd)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundu64_sd :: #force_inline proc "c" (a: __m128d, b: u64, $ROUNDING: i32) -> __m128d {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtusi2sd64(a, b, ROUNDING)
	}

	// Convert the unsigned 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundu64_ss)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundu64_ss :: #force_inline proc "c" (a: __m128, b: u64, $ROUNDING: i32) -> __m128 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtusi2ss64(a, b, ROUNDING)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundsd_si64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundsd_si64 :: #force_inline proc "c" (a: __m128d, $ROUNDING: i32) -> i64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsd2si64(a, ROUNDING)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundsd_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundsd_i64 :: #force_inline proc "c" (a: __m128d, $ROUNDING: i32) -> i64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsd2si64(a, ROUNDING)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundss_si64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundss_si64 :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> i64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtss2si64(a, ROUNDING)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundss_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundss_i64 :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> i64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtss2si64(a, ROUNDING)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to an unsigned 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundsd_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundsd_u64 :: #force_inline proc "c" (a: __m128d, $ROUNDING: i32) -> u64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtsd2usi64(a, ROUNDING)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to an unsigned 64-bit integer,
	// and store the result in `dst`.
	// Rounding is done according to the `rounding` parameter, which can be one of:
	//
	// * `_MM_FROUND_TO_NEAREST_INT` | `_MM_FROUND_NO_EXC` : round to nearest and suppress exceptions
	// * `_MM_FROUND_TO_NEG_INF`     | `_MM_FROUND_NO_EXC` : round down and suppress exceptions
	// * `_MM_FROUND_TO_POS_INF`     | `_MM_FROUND_NO_EXC` : round up and suppress exceptions
	// * `_MM_FROUND_TO_ZERO`        | `_MM_FROUND_NO_EXC` : truncate and suppress exceptions
	// * `_MM_FROUND_CUR_DIRECTION` : use `MXCSR.RC` - see `_MM_SET_ROUNDING_MODE`
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_roundss_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvt_roundss_u64 :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> u64 {
		#assert(ROUNDING == 4 || (8 <= ROUNDING && ROUNDING <= 11), "simd/x86: invalid ROUNDING value")
		return llvm_vcvtss2usi64(a, ROUNDING)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundsd_si64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundsd_si64 :: #force_inline proc "c" (a: __m128d, $SAE: i32) -> i64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttsd2si64(a, SAE)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundsd_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundsd_i64 :: #force_inline proc "c" (a: __m128d, $SAE: i32) -> i64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttsd2si64(a, SAE)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundss_i64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundss_i64 :: #force_inline proc "c" (a: __m128, $SAE: i32) -> i64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttss2si64(a, SAE)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundss_si64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundss_si64 :: #force_inline proc "c" (a: __m128, $SAE: i32) -> i64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttss2si64(a, SAE)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to an unsigned 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundsd_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundsd_u64 :: #force_inline proc "c" (a: __m128d, $SAE: i32) -> u64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttsd2usi64(a, SAE)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to an unsigned 64-bit integer with truncation,
	// and store the result in `dst`. Exceptions can be suppressed by passing `_MM_FROUND_NO_EXC` in the `sae` parameter.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_roundss_u64)
	@(require_results, enable_target_feature="avx512f")
	_mm_cvtt_roundss_u64 :: #force_inline proc "c" (a: __m128, $SAE: i32) -> u64 {
		#assert(SAE == 4 || SAE == 8, "simd/x86: invalid SAE value")
		return llvm_vcvttss2usi64(a, SAE)
	}
}

_MM_CMPINT_EQ    : _MM_CMPINT_ENUM : 0x00
_MM_CMPINT_LT    : _MM_CMPINT_ENUM : 0x01
_MM_CMPINT_LE    : _MM_CMPINT_ENUM : 0x02
_MM_CMPINT_FALSE : _MM_CMPINT_ENUM : 0x03
_MM_CMPINT_NE    : _MM_CMPINT_ENUM : 0x04
_MM_CMPINT_NLT   : _MM_CMPINT_ENUM : 0x05
_MM_CMPINT_NLE   : _MM_CMPINT_ENUM : 0x06
_MM_CMPINT_TRUE  : _MM_CMPINT_ENUM : 0x07

_MM_MANT_NORM_1_2     : _MM_MANTISSA_NORM_ENUM : 0x00
_MM_MANT_NORM_P5_2    : _MM_MANTISSA_NORM_ENUM : 0x01
_MM_MANT_NORM_P5_1    : _MM_MANTISSA_NORM_ENUM : 0x02
_MM_MANT_NORM_P75_1P5 : _MM_MANTISSA_NORM_ENUM : 0x03
_MM_MANT_SIGN_SRC     : _MM_MANTISSA_SIGN_ENUM : 0x00
_MM_MANT_SIGN_ZERO    : _MM_MANTISSA_SIGN_ENUM : 0x01
_MM_MANT_SIGN_NAN     : _MM_MANTISSA_SIGN_ENUM : 0x02

_MM_PERM_AAAA : _MM_PERM_ENUM : 0x00
_MM_PERM_AAAB : _MM_PERM_ENUM : 0x01
_MM_PERM_AAAC : _MM_PERM_ENUM : 0x02
_MM_PERM_AAAD : _MM_PERM_ENUM : 0x03
_MM_PERM_AABA : _MM_PERM_ENUM : 0x04
_MM_PERM_AABB : _MM_PERM_ENUM : 0x05
_MM_PERM_AABC : _MM_PERM_ENUM : 0x06
_MM_PERM_AABD : _MM_PERM_ENUM : 0x07
_MM_PERM_AACA : _MM_PERM_ENUM : 0x08
_MM_PERM_AACB : _MM_PERM_ENUM : 0x09
_MM_PERM_AACC : _MM_PERM_ENUM : 0x0A
_MM_PERM_AACD : _MM_PERM_ENUM : 0x0B
_MM_PERM_AADA : _MM_PERM_ENUM : 0x0C
_MM_PERM_AADB : _MM_PERM_ENUM : 0x0D
_MM_PERM_AADC : _MM_PERM_ENUM : 0x0E
_MM_PERM_AADD : _MM_PERM_ENUM : 0x0F
_MM_PERM_ABAA : _MM_PERM_ENUM : 0x10
_MM_PERM_ABAB : _MM_PERM_ENUM : 0x11
_MM_PERM_ABAC : _MM_PERM_ENUM : 0x12
_MM_PERM_ABAD : _MM_PERM_ENUM : 0x13
_MM_PERM_ABBA : _MM_PERM_ENUM : 0x14
_MM_PERM_ABBB : _MM_PERM_ENUM : 0x15
_MM_PERM_ABBC : _MM_PERM_ENUM : 0x16
_MM_PERM_ABBD : _MM_PERM_ENUM : 0x17
_MM_PERM_ABCA : _MM_PERM_ENUM : 0x18
_MM_PERM_ABCB : _MM_PERM_ENUM : 0x19
_MM_PERM_ABCC : _MM_PERM_ENUM : 0x1A
_MM_PERM_ABCD : _MM_PERM_ENUM : 0x1B
_MM_PERM_ABDA : _MM_PERM_ENUM : 0x1C
_MM_PERM_ABDB : _MM_PERM_ENUM : 0x1D
_MM_PERM_ABDC : _MM_PERM_ENUM : 0x1E
_MM_PERM_ABDD : _MM_PERM_ENUM : 0x1F
_MM_PERM_ACAA : _MM_PERM_ENUM : 0x20
_MM_PERM_ACAB : _MM_PERM_ENUM : 0x21
_MM_PERM_ACAC : _MM_PERM_ENUM : 0x22
_MM_PERM_ACAD : _MM_PERM_ENUM : 0x23
_MM_PERM_ACBA : _MM_PERM_ENUM : 0x24
_MM_PERM_ACBB : _MM_PERM_ENUM : 0x25
_MM_PERM_ACBC : _MM_PERM_ENUM : 0x26
_MM_PERM_ACBD : _MM_PERM_ENUM : 0x27
_MM_PERM_ACCA : _MM_PERM_ENUM : 0x28
_MM_PERM_ACCB : _MM_PERM_ENUM : 0x29
_MM_PERM_ACCC : _MM_PERM_ENUM : 0x2A
_MM_PERM_ACCD : _MM_PERM_ENUM : 0x2B
_MM_PERM_ACDA : _MM_PERM_ENUM : 0x2C
_MM_PERM_ACDB : _MM_PERM_ENUM : 0x2D
_MM_PERM_ACDC : _MM_PERM_ENUM : 0x2E
_MM_PERM_ACDD : _MM_PERM_ENUM : 0x2F
_MM_PERM_ADAA : _MM_PERM_ENUM : 0x30
_MM_PERM_ADAB : _MM_PERM_ENUM : 0x31
_MM_PERM_ADAC : _MM_PERM_ENUM : 0x32
_MM_PERM_ADAD : _MM_PERM_ENUM : 0x33
_MM_PERM_ADBA : _MM_PERM_ENUM : 0x34
_MM_PERM_ADBB : _MM_PERM_ENUM : 0x35
_MM_PERM_ADBC : _MM_PERM_ENUM : 0x36
_MM_PERM_ADBD : _MM_PERM_ENUM : 0x37
_MM_PERM_ADCA : _MM_PERM_ENUM : 0x38
_MM_PERM_ADCB : _MM_PERM_ENUM : 0x39
_MM_PERM_ADCC : _MM_PERM_ENUM : 0x3A
_MM_PERM_ADCD : _MM_PERM_ENUM : 0x3B
_MM_PERM_ADDA : _MM_PERM_ENUM : 0x3C
_MM_PERM_ADDB : _MM_PERM_ENUM : 0x3D
_MM_PERM_ADDC : _MM_PERM_ENUM : 0x3E
_MM_PERM_ADDD : _MM_PERM_ENUM : 0x3F
_MM_PERM_BAAA : _MM_PERM_ENUM : 0x40
_MM_PERM_BAAB : _MM_PERM_ENUM : 0x41
_MM_PERM_BAAC : _MM_PERM_ENUM : 0x42
_MM_PERM_BAAD : _MM_PERM_ENUM : 0x43
_MM_PERM_BABA : _MM_PERM_ENUM : 0x44
_MM_PERM_BABB : _MM_PERM_ENUM : 0x45
_MM_PERM_BABC : _MM_PERM_ENUM : 0x46
_MM_PERM_BABD : _MM_PERM_ENUM : 0x47
_MM_PERM_BACA : _MM_PERM_ENUM : 0x48
_MM_PERM_BACB : _MM_PERM_ENUM : 0x49
_MM_PERM_BACC : _MM_PERM_ENUM : 0x4A
_MM_PERM_BACD : _MM_PERM_ENUM : 0x4B
_MM_PERM_BADA : _MM_PERM_ENUM : 0x4C
_MM_PERM_BADB : _MM_PERM_ENUM : 0x4D
_MM_PERM_BADC : _MM_PERM_ENUM : 0x4E
_MM_PERM_BADD : _MM_PERM_ENUM : 0x4F
_MM_PERM_BBAA : _MM_PERM_ENUM : 0x50
_MM_PERM_BBAB : _MM_PERM_ENUM : 0x51
_MM_PERM_BBAC : _MM_PERM_ENUM : 0x52
_MM_PERM_BBAD : _MM_PERM_ENUM : 0x53
_MM_PERM_BBBA : _MM_PERM_ENUM : 0x54
_MM_PERM_BBBB : _MM_PERM_ENUM : 0x55
_MM_PERM_BBBC : _MM_PERM_ENUM : 0x56
_MM_PERM_BBBD : _MM_PERM_ENUM : 0x57
_MM_PERM_BBCA : _MM_PERM_ENUM : 0x58
_MM_PERM_BBCB : _MM_PERM_ENUM : 0x59
_MM_PERM_BBCC : _MM_PERM_ENUM : 0x5A
_MM_PERM_BBCD : _MM_PERM_ENUM : 0x5B
_MM_PERM_BBDA : _MM_PERM_ENUM : 0x5C
_MM_PERM_BBDB : _MM_PERM_ENUM : 0x5D
_MM_PERM_BBDC : _MM_PERM_ENUM : 0x5E
_MM_PERM_BBDD : _MM_PERM_ENUM : 0x5F
_MM_PERM_BCAA : _MM_PERM_ENUM : 0x60
_MM_PERM_BCAB : _MM_PERM_ENUM : 0x61
_MM_PERM_BCAC : _MM_PERM_ENUM : 0x62
_MM_PERM_BCAD : _MM_PERM_ENUM : 0x63
_MM_PERM_BCBA : _MM_PERM_ENUM : 0x64
_MM_PERM_BCBB : _MM_PERM_ENUM : 0x65
_MM_PERM_BCBC : _MM_PERM_ENUM : 0x66
_MM_PERM_BCBD : _MM_PERM_ENUM : 0x67
_MM_PERM_BCCA : _MM_PERM_ENUM : 0x68
_MM_PERM_BCCB : _MM_PERM_ENUM : 0x69
_MM_PERM_BCCC : _MM_PERM_ENUM : 0x6A
_MM_PERM_BCCD : _MM_PERM_ENUM : 0x6B
_MM_PERM_BCDA : _MM_PERM_ENUM : 0x6C
_MM_PERM_BCDB : _MM_PERM_ENUM : 0x6D
_MM_PERM_BCDC : _MM_PERM_ENUM : 0x6E
_MM_PERM_BCDD : _MM_PERM_ENUM : 0x6F
_MM_PERM_BDAA : _MM_PERM_ENUM : 0x70
_MM_PERM_BDAB : _MM_PERM_ENUM : 0x71
_MM_PERM_BDAC : _MM_PERM_ENUM : 0x72
_MM_PERM_BDAD : _MM_PERM_ENUM : 0x73
_MM_PERM_BDBA : _MM_PERM_ENUM : 0x74
_MM_PERM_BDBB : _MM_PERM_ENUM : 0x75
_MM_PERM_BDBC : _MM_PERM_ENUM : 0x76
_MM_PERM_BDBD : _MM_PERM_ENUM : 0x77
_MM_PERM_BDCA : _MM_PERM_ENUM : 0x78
_MM_PERM_BDCB : _MM_PERM_ENUM : 0x79
_MM_PERM_BDCC : _MM_PERM_ENUM : 0x7A
_MM_PERM_BDCD : _MM_PERM_ENUM : 0x7B
_MM_PERM_BDDA : _MM_PERM_ENUM : 0x7C
_MM_PERM_BDDB : _MM_PERM_ENUM : 0x7D
_MM_PERM_BDDC : _MM_PERM_ENUM : 0x7E
_MM_PERM_BDDD : _MM_PERM_ENUM : 0x7F
_MM_PERM_CAAA : _MM_PERM_ENUM : 0x80
_MM_PERM_CAAB : _MM_PERM_ENUM : 0x81
_MM_PERM_CAAC : _MM_PERM_ENUM : 0x82
_MM_PERM_CAAD : _MM_PERM_ENUM : 0x83
_MM_PERM_CABA : _MM_PERM_ENUM : 0x84
_MM_PERM_CABB : _MM_PERM_ENUM : 0x85
_MM_PERM_CABC : _MM_PERM_ENUM : 0x86
_MM_PERM_CABD : _MM_PERM_ENUM : 0x87
_MM_PERM_CACA : _MM_PERM_ENUM : 0x88
_MM_PERM_CACB : _MM_PERM_ENUM : 0x89
_MM_PERM_CACC : _MM_PERM_ENUM : 0x8A
_MM_PERM_CACD : _MM_PERM_ENUM : 0x8B
_MM_PERM_CADA : _MM_PERM_ENUM : 0x8C
_MM_PERM_CADB : _MM_PERM_ENUM : 0x8D
_MM_PERM_CADC : _MM_PERM_ENUM : 0x8E
_MM_PERM_CADD : _MM_PERM_ENUM : 0x8F
_MM_PERM_CBAA : _MM_PERM_ENUM : 0x90
_MM_PERM_CBAB : _MM_PERM_ENUM : 0x91
_MM_PERM_CBAC : _MM_PERM_ENUM : 0x92
_MM_PERM_CBAD : _MM_PERM_ENUM : 0x93
_MM_PERM_CBBA : _MM_PERM_ENUM : 0x94
_MM_PERM_CBBB : _MM_PERM_ENUM : 0x95
_MM_PERM_CBBC : _MM_PERM_ENUM : 0x96
_MM_PERM_CBBD : _MM_PERM_ENUM : 0x97
_MM_PERM_CBCA : _MM_PERM_ENUM : 0x98
_MM_PERM_CBCB : _MM_PERM_ENUM : 0x99
_MM_PERM_CBCC : _MM_PERM_ENUM : 0x9A
_MM_PERM_CBCD : _MM_PERM_ENUM : 0x9B
_MM_PERM_CBDA : _MM_PERM_ENUM : 0x9C
_MM_PERM_CBDB : _MM_PERM_ENUM : 0x9D
_MM_PERM_CBDC : _MM_PERM_ENUM : 0x9E
_MM_PERM_CBDD : _MM_PERM_ENUM : 0x9F
_MM_PERM_CCAA : _MM_PERM_ENUM : 0xA0
_MM_PERM_CCAB : _MM_PERM_ENUM : 0xA1
_MM_PERM_CCAC : _MM_PERM_ENUM : 0xA2
_MM_PERM_CCAD : _MM_PERM_ENUM : 0xA3
_MM_PERM_CCBA : _MM_PERM_ENUM : 0xA4
_MM_PERM_CCBB : _MM_PERM_ENUM : 0xA5
_MM_PERM_CCBC : _MM_PERM_ENUM : 0xA6
_MM_PERM_CCBD : _MM_PERM_ENUM : 0xA7
_MM_PERM_CCCA : _MM_PERM_ENUM : 0xA8
_MM_PERM_CCCB : _MM_PERM_ENUM : 0xA9
_MM_PERM_CCCC : _MM_PERM_ENUM : 0xAA
_MM_PERM_CCCD : _MM_PERM_ENUM : 0xAB
_MM_PERM_CCDA : _MM_PERM_ENUM : 0xAC
_MM_PERM_CCDB : _MM_PERM_ENUM : 0xAD
_MM_PERM_CCDC : _MM_PERM_ENUM : 0xAE
_MM_PERM_CCDD : _MM_PERM_ENUM : 0xAF
_MM_PERM_CDAA : _MM_PERM_ENUM : 0xB0
_MM_PERM_CDAB : _MM_PERM_ENUM : 0xB1
_MM_PERM_CDAC : _MM_PERM_ENUM : 0xB2
_MM_PERM_CDAD : _MM_PERM_ENUM : 0xB3
_MM_PERM_CDBA : _MM_PERM_ENUM : 0xB4
_MM_PERM_CDBB : _MM_PERM_ENUM : 0xB5
_MM_PERM_CDBC : _MM_PERM_ENUM : 0xB6
_MM_PERM_CDBD : _MM_PERM_ENUM : 0xB7
_MM_PERM_CDCA : _MM_PERM_ENUM : 0xB8
_MM_PERM_CDCB : _MM_PERM_ENUM : 0xB9
_MM_PERM_CDCC : _MM_PERM_ENUM : 0xBA
_MM_PERM_CDCD : _MM_PERM_ENUM : 0xBB
_MM_PERM_CDDA : _MM_PERM_ENUM : 0xBC
_MM_PERM_CDDB : _MM_PERM_ENUM : 0xBD
_MM_PERM_CDDC : _MM_PERM_ENUM : 0xBE
_MM_PERM_CDDD : _MM_PERM_ENUM : 0xBF
_MM_PERM_DAAA : _MM_PERM_ENUM : 0xC0
_MM_PERM_DAAB : _MM_PERM_ENUM : 0xC1
_MM_PERM_DAAC : _MM_PERM_ENUM : 0xC2
_MM_PERM_DAAD : _MM_PERM_ENUM : 0xC3
_MM_PERM_DABA : _MM_PERM_ENUM : 0xC4
_MM_PERM_DABB : _MM_PERM_ENUM : 0xC5
_MM_PERM_DABC : _MM_PERM_ENUM : 0xC6
_MM_PERM_DABD : _MM_PERM_ENUM : 0xC7
_MM_PERM_DACA : _MM_PERM_ENUM : 0xC8
_MM_PERM_DACB : _MM_PERM_ENUM : 0xC9
_MM_PERM_DACC : _MM_PERM_ENUM : 0xCA
_MM_PERM_DACD : _MM_PERM_ENUM : 0xCB
_MM_PERM_DADA : _MM_PERM_ENUM : 0xCC
_MM_PERM_DADB : _MM_PERM_ENUM : 0xCD
_MM_PERM_DADC : _MM_PERM_ENUM : 0xCE
_MM_PERM_DADD : _MM_PERM_ENUM : 0xCF
_MM_PERM_DBAA : _MM_PERM_ENUM : 0xD0
_MM_PERM_DBAB : _MM_PERM_ENUM : 0xD1
_MM_PERM_DBAC : _MM_PERM_ENUM : 0xD2
_MM_PERM_DBAD : _MM_PERM_ENUM : 0xD3
_MM_PERM_DBBA : _MM_PERM_ENUM : 0xD4
_MM_PERM_DBBB : _MM_PERM_ENUM : 0xD5
_MM_PERM_DBBC : _MM_PERM_ENUM : 0xD6
_MM_PERM_DBBD : _MM_PERM_ENUM : 0xD7
_MM_PERM_DBCA : _MM_PERM_ENUM : 0xD8
_MM_PERM_DBCB : _MM_PERM_ENUM : 0xD9
_MM_PERM_DBCC : _MM_PERM_ENUM : 0xDA
_MM_PERM_DBCD : _MM_PERM_ENUM : 0xDB
_MM_PERM_DBDA : _MM_PERM_ENUM : 0xDC
_MM_PERM_DBDB : _MM_PERM_ENUM : 0xDD
_MM_PERM_DBDC : _MM_PERM_ENUM : 0xDE
_MM_PERM_DBDD : _MM_PERM_ENUM : 0xDF
_MM_PERM_DCAA : _MM_PERM_ENUM : 0xE0
_MM_PERM_DCAB : _MM_PERM_ENUM : 0xE1
_MM_PERM_DCAC : _MM_PERM_ENUM : 0xE2
_MM_PERM_DCAD : _MM_PERM_ENUM : 0xE3
_MM_PERM_DCBA : _MM_PERM_ENUM : 0xE4
_MM_PERM_DCBB : _MM_PERM_ENUM : 0xE5
_MM_PERM_DCBC : _MM_PERM_ENUM : 0xE6
_MM_PERM_DCBD : _MM_PERM_ENUM : 0xE7
_MM_PERM_DCCA : _MM_PERM_ENUM : 0xE8
_MM_PERM_DCCB : _MM_PERM_ENUM : 0xE9
_MM_PERM_DCCC : _MM_PERM_ENUM : 0xEA
_MM_PERM_DCCD : _MM_PERM_ENUM : 0xEB
_MM_PERM_DCDA : _MM_PERM_ENUM : 0xEC
_MM_PERM_DCDB : _MM_PERM_ENUM : 0xED
_MM_PERM_DCDC : _MM_PERM_ENUM : 0xEE
_MM_PERM_DCDD : _MM_PERM_ENUM : 0xEF
_MM_PERM_DDAA : _MM_PERM_ENUM : 0xF0
_MM_PERM_DDAB : _MM_PERM_ENUM : 0xF1
_MM_PERM_DDAC : _MM_PERM_ENUM : 0xF2
_MM_PERM_DDAD : _MM_PERM_ENUM : 0xF3
_MM_PERM_DDBA : _MM_PERM_ENUM : 0xF4
_MM_PERM_DDBB : _MM_PERM_ENUM : 0xF5
_MM_PERM_DDBC : _MM_PERM_ENUM : 0xF6
_MM_PERM_DDBD : _MM_PERM_ENUM : 0xF7
_MM_PERM_DDCA : _MM_PERM_ENUM : 0xF8
_MM_PERM_DDCB : _MM_PERM_ENUM : 0xF9
_MM_PERM_DDCC : _MM_PERM_ENUM : 0xFA
_MM_PERM_DDCD : _MM_PERM_ENUM : 0xFB
_MM_PERM_DDDA : _MM_PERM_ENUM : 0xFC
_MM_PERM_DDDB : _MM_PERM_ENUM : 0xFD
_MM_PERM_DDDC : _MM_PERM_ENUM : 0xFE
_MM_PERM_DDDD : _MM_PERM_ENUM : 0xFF

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.avx512.sqrt.ps.512")                llvm_vsqrtps             :: proc(a: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.sqrt.pd.512")                llvm_vsqrtpd             :: proc(a: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.vfmadd.ps.512")              llvm_vfmadd132psround    :: proc(a, b, c: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.vfmadd.pd.512")              llvm_vfmadd132pdround    :: proc(a, b, c: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.vfmaddsub.ps.512")           llvm_vfmaddsubpsround    :: proc(a, b, c: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.vfmaddsub.pd.512")           llvm_vfmaddsubpdround    :: proc(a, b, c: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.add.ps.512")                 llvm_vaddps              :: proc(a, b: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.add.pd.512")                 llvm_vaddpd              :: proc(a, b: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.sub.ps.512")                 llvm_vsubps              :: proc(a, b: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.sub.pd.512")                 llvm_vsubpd              :: proc(a, b: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mul.ps.512")                 llvm_vmulps              :: proc(a, b: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mul.pd.512")                 llvm_vmulpd              :: proc(a, b: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.div.ps.512")                 llvm_vdivps              :: proc(a, b: simd.f32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.div.pd.512")                 llvm_vdivpd              :: proc(a, b: simd.f64x8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.max.ps.512")                 llvm_vmaxps              :: proc(a, b: simd.f32x16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.max.pd.512")                 llvm_vmaxpd              :: proc(a, b: simd.f64x8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.min.ps.512")                 llvm_vminps              :: proc(a, b: simd.f32x16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.min.pd.512")                 llvm_vminpd              :: proc(a, b: simd.f64x8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.getexp.ps.512")         llvm_vgetexpps           :: proc(a: simd.f32x16, src: simd.f32x16, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.getexp.ps.256")         llvm_vgetexpps256        :: proc(a: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.getexp.ps.128")         llvm_vgetexpps128        :: proc(a: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.getexp.pd.512")         llvm_vgetexppd           :: proc(a: simd.f64x8, src: simd.f64x8, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.getexp.pd.256")         llvm_vgetexppd256        :: proc(a: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.getexp.pd.128")         llvm_vgetexppd128        :: proc(a: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.ps.512")       llvm_vrndscaleps         :: proc(a: simd.f32x16, imm8: i32, src: simd.f32x16, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.ps.256")       llvm_vrndscaleps256      :: proc(a: simd.f32x8, imm8: i32, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.ps.128")       llvm_vrndscaleps128      :: proc(a: simd.f32x4, imm8: i32, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.pd.512")       llvm_vrndscalepd         :: proc(a: simd.f64x8, imm8: i32, src: simd.f64x8, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.pd.256")       llvm_vrndscalepd256      :: proc(a: simd.f64x4, imm8: i32, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.pd.128")       llvm_vrndscalepd128      :: proc(a: simd.f64x2, imm8: i32, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.scalef.ps.512")         llvm_vscalefps           :: proc(a, b: simd.f32x16, src: simd.f32x16, mask: u16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.scalef.ps.256")         llvm_vscalefps256        :: proc(a, b: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.scalef.ps.128")         llvm_vscalefps128        :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.scalef.pd.512")         llvm_vscalefpd           :: proc(a, b: simd.f64x8, src: simd.f64x8, mask: u8, rounding: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.scalef.pd.256")         llvm_vscalefpd256        :: proc(a, b: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.scalef.pd.128")         llvm_vscalefpd128        :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.ps.512")       llvm_vfixupimmps         :: proc(a, b: simd.f32x16, c: simd.i32x16, imm8: i32, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.ps.256")       llvm_vfixupimmps256      :: proc(a, b: simd.f32x8, c: simd.i32x8, imm8: i32, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.ps.128")       llvm_vfixupimmps128      :: proc(a, b: simd.f32x4, c: simd.i32x4, imm8: i32, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.pd.512")       llvm_vfixupimmpd         :: proc(a, b: simd.f64x8, c: simd.i64x8, imm8: i32, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.pd.256")       llvm_vfixupimmpd256      :: proc(a, b: simd.f64x4, c: simd.i64x4, imm8: i32, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.pd.128")       llvm_vfixupimmpd128      :: proc(a, b: simd.f64x2, c: simd.i64x2, imm8: i32, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.ps.512")      llvm_vfixupimmpsz        :: proc(a, b: simd.f32x16, c: simd.i32x16, imm8: i32, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.ps.256")      llvm_vfixupimmpsz256     :: proc(a, b: simd.f32x8, c: simd.i32x8, imm8: i32, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.ps.128")      llvm_vfixupimmpsz128     :: proc(a, b: simd.f32x4, c: simd.i32x4, imm8: i32, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.pd.512")      llvm_vfixupimmpdz        :: proc(a, b: simd.f64x8, c: simd.i64x8, imm8: i32, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.pd.256")      llvm_vfixupimmpdz256     :: proc(a, b: simd.f64x4, c: simd.i64x4, imm8: i32, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.pd.128")      llvm_vfixupimmpdz128     :: proc(a, b: simd.f64x2, c: simd.i64x2, imm8: i32, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.pternlog.d.512")             llvm_vpternlogd          :: proc(a, b, c: simd.i32x16, imm8: i32) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.pternlog.d.256")             llvm_vpternlogd256       :: proc(a, b, c: simd.i32x8, imm8: i32) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.pternlog.d.128")             llvm_vpternlogd128       :: proc(a, b, c: simd.i32x4, imm8: i32) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.pternlog.q.512")             llvm_vpternlogq          :: proc(a, b, c: simd.i64x8, imm8: i32) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.pternlog.q.256")             llvm_vpternlogq256       :: proc(a, b, c: simd.i64x4, imm8: i32) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.pternlog.q.128")             llvm_vpternlogq128       :: proc(a, b, c: simd.i64x2, imm8: i32) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.mask.getmant.ps.512")        llvm_vgetmantps          :: proc(a: simd.f32x16, mantissas: i32, src: simd.f32x16, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.getmant.ps.256")        llvm_vgetmantps256       :: proc(a: simd.f32x8, mantissas: i32, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.getmant.ps.128")        llvm_vgetmantps128       :: proc(a: simd.f32x4, mantissas: i32, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.getmant.pd.512")        llvm_vgetmantpd          :: proc(a: simd.f64x8, mantissas: i32, src: simd.f64x8, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.getmant.pd.256")        llvm_vgetmantpd256       :: proc(a: simd.f64x4, mantissas: i32, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.getmant.pd.128")        llvm_vgetmantpd128       :: proc(a: simd.f64x2, mantissas: i32, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.rcp14.ps.512")               llvm_vrcp14ps            :: proc(a: simd.f32x16, src: simd.f32x16, mask: u16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.rcp14.ps.256")               llvm_vrcp14ps256         :: proc(a: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.rcp14.ps.128")               llvm_vrcp14ps128         :: proc(a: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.rcp14.pd.512")               llvm_vrcp14pd            :: proc(a: simd.f64x8, src: simd.f64x8, mask: u8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.rcp14.pd.256")               llvm_vrcp14pd256         :: proc(a: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.rcp14.pd.128")               llvm_vrcp14pd128         :: proc(a: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.rsqrt14.ps.512")             llvm_vrsqrt14ps          :: proc(a: simd.f32x16, src: simd.f32x16, mask: u16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.rsqrt14.ps.256")             llvm_vrsqrt14ps256       :: proc(a: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.rsqrt14.ps.128")             llvm_vrsqrt14ps128       :: proc(a: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.rsqrt14.pd.512")             llvm_vrsqrt14pd          :: proc(a: simd.f64x8, src: simd.f64x8, mask: u8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.rsqrt14.pd.256")             llvm_vrsqrt14pd256       :: proc(a: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.rsqrt14.pd.128")             llvm_vrsqrt14pd128       :: proc(a: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.cvtps2dq.512")          llvm_vcvtps2dq           :: proc(a: simd.f32x16, src: simd.i32x16, mask: u16, rounding: i32) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.mask.cvtps2udq.512")         llvm_vcvtps2udq          :: proc(a: simd.f32x16, src: simd.u32x16, mask: u16, rounding: i32) -> simd.u32x16 ---
	@(link_name="llvm.x86.avx512.mask.cvtps2udq.256")         llvm_vcvtps2udq256       :: proc(a: simd.f32x8, src: simd.u32x8, mask: u8) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvtps2udq.128")         llvm_vcvtps2udq128       :: proc(a: simd.f32x4, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvtps2pd.512")          llvm_vcvtps2pd           :: proc(a: simd.f32x8, src: simd.f64x8, mask: u8, sae: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2ps")              llvm_vcvtpd2ps128        :: proc(a: simd.f64x2, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2ps.512")          llvm_vcvtpd2ps           :: proc(a: simd.f64x8, src: simd.f32x8, mask: u8, rounding: i32) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2dq.128")          llvm_vcvtpd2dq128        :: proc(a: simd.f64x2, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2dq.512")          llvm_vcvtpd2dq           :: proc(a: simd.f64x8, src: simd.i32x8, mask: u8, rounding: i32) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2udq.512")         llvm_vcvtpd2udq          :: proc(a: simd.f64x8, src: simd.u32x8, mask: u8, rounding: i32) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2udq.256")         llvm_vcvtpd2udq256       :: proc(a: simd.f64x4, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvtpd2udq.128")         llvm_vcvtpd2udq128       :: proc(a: simd.f64x2, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.sitofp.round.v16f32.v16i32") llvm_vcvtdq2ps           :: proc(a: simd.i32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.uitofp.round.v16f32.v16i32") llvm_vcvtudq2ps          :: proc(a: simd.u32x16, rounding: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.vcvtps2ph.512")         llvm_vcvtps2ph           :: proc(a: simd.f32x16, rounding: i32, src: simd.i16x16, mask: u16) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx512.mask.vcvtps2ph.256")         llvm_vcvtps2ph256        :: proc(a: simd.f32x8, rounding: i32, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.vcvtps2ph.128")         llvm_vcvtps2ph128        :: proc(a: simd.f32x4, rounding: i32, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.vcvtph2ps.512")         llvm_vcvtph2ps           :: proc(a: simd.i16x16, src: simd.f32x16, mask: u16, sae: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.cvttps2dq.512")         llvm_vcvttps2dq          :: proc(a: simd.f32x16, src: simd.i32x16, mask: u16, rounding: i32) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.mask.cvttps2udq.512")        llvm_vcvttps2udq         :: proc(a: simd.f32x16, src: simd.u32x16, mask: u16, rounding: i32) -> simd.u32x16 ---
	@(link_name="llvm.x86.avx512.mask.cvttps2udq.256")        llvm_vcvttps2udq256      :: proc(a: simd.f32x8, src: simd.u32x8, mask: u8) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvttps2udq.128")        llvm_vcvttps2udq128      :: proc(a: simd.f32x4, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvttpd2dq.512")         llvm_vcvttpd2dq          :: proc(a: simd.f64x8, src: simd.i32x8, mask: u8, rounding: i32) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvttpd2dq.128")         llvm_vcvttpd2dq128       :: proc(a: simd.f64x2, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvttpd2udq.512")        llvm_vcvttpd2udq         :: proc(a: simd.f64x8, src: simd.i32x8, mask: u8, rounding: i32) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx512.mask.cvttpd2udq.256")        llvm_vcvttpd2udq256      :: proc(a: simd.f64x4, src: simd.i32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.cvttpd2udq.128")        llvm_vcvttpd2udq128      :: proc(a: simd.f64x2, src: simd.i32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmov.dw.128")           llvm_vpmovdw128          :: proc(a: simd.i32x4, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmov.db.256")           llvm_vpmovdb256          :: proc(a: simd.i32x8, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmov.db.128")           llvm_vpmovdb128          :: proc(a: simd.i32x4, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmov.qw.256")           llvm_vpmovqw256          :: proc(a: simd.i64x4, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmov.qw.128")           llvm_vpmovqw128          :: proc(a: simd.i64x2, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.256")           llvm_vpmovqb256          :: proc(a: simd.i64x4, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.128")           llvm_vpmovqb128          :: proc(a: simd.i64x2, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmov.qd.128")           llvm_vpmovqd128          :: proc(a: simd.i64x2, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmov.dw.mem.512")       llvm_vpmovdwmem          :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmov.dw.mem.256")       llvm_vpmovdwmem256       :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.dw.mem.128")       llvm_vpmovdwmem128       :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.mem.512")      llvm_vpmovsdwmem         :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.mem.256")      llvm_vpmovsdwmem256      :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.mem.128")      llvm_vpmovsdwmem128      :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.mem.512")     llvm_vpmovusdwmem        :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.mem.256")     llvm_vpmovusdwmem256     :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.mem.128")     llvm_vpmovusdwmem128     :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.db.mem.512")       llvm_vpmovdbmem          :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmov.db.mem.256")       llvm_vpmovdbmem256       :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.db.mem.128")       llvm_vpmovdbmem128       :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.mem.512")      llvm_vpmovsdbmem         :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.mem.256")      llvm_vpmovsdbmem256      :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.mem.128")      llvm_vpmovsdbmem128      :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.mem.512")     llvm_vpmovusdbmem        :: proc(mem_addr: rawptr, a: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.mem.256")     llvm_vpmovusdbmem256     :: proc(mem_addr: rawptr, a: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.mem.128")     llvm_vpmovusdbmem128     :: proc(mem_addr: rawptr, a: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qw.mem.512")       llvm_vpmovqwmem          :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qw.mem.256")       llvm_vpmovqwmem256       :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qw.mem.128")       llvm_vpmovqwmem128       :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.mem.512")      llvm_vpmovsqwmem         :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.mem.256")      llvm_vpmovsqwmem256      :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.mem.128")      llvm_vpmovsqwmem128      :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.mem.512")     llvm_vpmovusqwmem        :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.mem.256")     llvm_vpmovusqwmem256     :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.mem.128")     llvm_vpmovusqwmem128     :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.mem.512")       llvm_vpmovqbmem          :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.mem.256")       llvm_vpmovqbmem256       :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.mem.128")       llvm_vpmovqbmem128       :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.mem.512")      llvm_vpmovsqbmem         :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.mem.256")      llvm_vpmovsqbmem256      :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.mem.128")      llvm_vpmovsqbmem128      :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.mem.512")     llvm_vpmovusqbmem        :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.mem.256")     llvm_vpmovusqbmem256     :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.mem.128")     llvm_vpmovusqbmem128     :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qd.mem.512")       llvm_vpmovqdmem          :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qd.mem.256")       llvm_vpmovqdmem256       :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qd.mem.128")       llvm_vpmovqdmem128       :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.mem.512")      llvm_vpmovsqdmem         :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.mem.256")      llvm_vpmovsqdmem256      :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.mem.128")      llvm_vpmovsqdmem128      :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.mem.512")     llvm_vpmovusqdmem        :: proc(mem_addr: rawptr, a: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.mem.256")     llvm_vpmovusqdmem256     :: proc(mem_addr: rawptr, a: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.mem.128")     llvm_vpmovusqdmem128     :: proc(mem_addr: rawptr, a: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.pmov.qb.512")           llvm_vpmovqb             :: proc(a: simd.i64x8, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.512")          llvm_vpmovsdw            :: proc(a: simd.i32x16, src: simd.i16x16, mask: u16) -> simd.i16x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.256")          llvm_vpmovsdw256         :: proc(a: simd.i32x8, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.dw.128")          llvm_vpmovsdw128         :: proc(a: simd.i32x4, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.512")          llvm_vpmovsdb            :: proc(a: simd.i32x16, src: simd.i8x16, mask: u16) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.256")          llvm_vpmovsdb256         :: proc(a: simd.i32x8, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.db.128")          llvm_vpmovsdb128         :: proc(a: simd.i32x4, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.512")          llvm_vpmovsqd            :: proc(a: simd.i64x8, src: simd.i32x8, mask: u8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.256")          llvm_vpmovsqd256         :: proc(a: simd.i64x4, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qd.128")          llvm_vpmovsqd128         :: proc(a: simd.i64x2, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.512")          llvm_vpmovsqw            :: proc(a: simd.i64x8, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.256")          llvm_vpmovsqw256         :: proc(a: simd.i64x4, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qw.128")          llvm_vpmovsqw128         :: proc(a: simd.i64x2, src: simd.i16x8, mask: u8) -> simd.i16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.512")          llvm_vpmovsqb            :: proc(a: simd.i64x8, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.256")          llvm_vpmovsqb256         :: proc(a: simd.i64x4, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovs.qb.128")          llvm_vpmovsqb128         :: proc(a: simd.i64x2, src: simd.i8x16, mask: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.512")         llvm_vpmovusdw           :: proc(a: simd.u32x16, src: simd.u16x16, mask: u16) -> simd.u16x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.256")         llvm_vpmovusdw256        :: proc(a: simd.u32x8, src: simd.u16x8, mask: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.dw.128")         llvm_vpmovusdw128        :: proc(a: simd.u32x4, src: simd.u16x8, mask: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.512")         llvm_vpmovusdb           :: proc(a: simd.u32x16, src: simd.u8x16, mask: u16) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.256")         llvm_vpmovusdb256        :: proc(a: simd.u32x8, src: simd.u8x16, mask: u8) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.db.128")         llvm_vpmovusdb128        :: proc(a: simd.u32x4, src: simd.u8x16, mask: u8) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.512")         llvm_vpmovusqd           :: proc(a: simd.u64x8, src: simd.u32x8, mask: u8) -> simd.u32x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.256")         llvm_vpmovusqd256        :: proc(a: simd.u64x4, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qd.128")         llvm_vpmovusqd128        :: proc(a: simd.u64x2, src: simd.u32x4, mask: u8) -> simd.u32x4 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.512")         llvm_vpmovusqw           :: proc(a: simd.u64x8, src: simd.u16x8, mask: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.256")         llvm_vpmovusqw256        :: proc(a: simd.u64x4, src: simd.u16x8, mask: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qw.128")         llvm_vpmovusqw128        :: proc(a: simd.u64x2, src: simd.u16x8, mask: u8) -> simd.u16x8 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.512")         llvm_vpmovusqb           :: proc(a: simd.u64x8, src: simd.u8x16, mask: u8) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.256")         llvm_vpmovusqb256        :: proc(a: simd.u64x4, src: simd.u8x16, mask: u8) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.mask.pmovus.qb.128")         llvm_vpmovusqb128        :: proc(a: simd.u64x2, src: simd.u8x16, mask: u8) -> simd.u8x16 ---
	@(link_name="llvm.x86.avx512.gather.dpd.512")             llvm_vgatherdpd          :: proc(src: simd.f64x8, slice: rawptr, offsets: simd.i32x8, mask: i8, scale: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.gather.dps.512")             llvm_vgatherdps          :: proc(src: simd.f32x16, slice: rawptr, offsets: simd.i32x16, mask: i16, scale: i32) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.gather.qpd.512")             llvm_vgatherqpd          :: proc(src: simd.f64x8, slice: rawptr, offsets: simd.i64x8, mask: i8, scale: i32) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.gather.qps.512")             llvm_vgatherqps          :: proc(src: simd.f32x8, slice: rawptr, offsets: simd.i64x8, mask: i8, scale: i32) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.gather.dpq.512")             llvm_vpgatherdq          :: proc(src: simd.i64x8, slice: rawptr, offsets: simd.i32x8, mask: i8, scale: i32) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.gather.dpi.512")             llvm_vpgatherdd          :: proc(src: simd.i32x16, slice: rawptr, offsets: simd.i32x16, mask: i16, scale: i32) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.gather.qpq.512")             llvm_vpgatherqq          :: proc(src: simd.i64x8, slice: rawptr, offsets: simd.i64x8, mask: i8, scale: i32) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.gather.qpi.512")             llvm_vpgatherqd          :: proc(src: simd.i32x8, slice: rawptr, offsets: simd.i64x8, mask: i8, scale: i32) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.scatter.dpd.512")            llvm_vscatterdpd         :: proc(slice: rawptr, mask: i8, offsets: simd.i32x8, src: simd.f64x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.dps.512")            llvm_vscatterdps         :: proc(slice: rawptr, mask: i16, offsets: simd.i32x16, src: simd.f32x16, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.qpd.512")            llvm_vscatterqpd         :: proc(slice: rawptr, mask: i8, offsets: simd.i64x8, src: simd.f64x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.qps.512")            llvm_vscatterqps         :: proc(slice: rawptr, mask: i8, offsets: simd.i64x8, src: simd.f32x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.dpq.512")            llvm_vpscatterdq         :: proc(slice: rawptr, mask: i8, offsets: simd.i32x8, src: simd.i64x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.dpi.512")            llvm_vpscatterdd         :: proc(slice: rawptr, mask: i16, offsets: simd.i32x16, src: simd.i32x16, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.qpq.512")            llvm_vpscatterqq         :: proc(slice: rawptr, mask: i8, offsets: simd.i64x8, src: simd.i64x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatter.qpi.512")            llvm_vpscatterqd         :: proc(slice: rawptr, mask: i8, offsets: simd.i64x8, src: simd.i32x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv4.si")             llvm_vpscatterdd_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.i32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv2.di")             llvm_vpscatterdq_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.i64x2, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv2.df")             llvm_vscatterdpd_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.f64x2, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv4.sf")             llvm_vscatterdps_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.f32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv4.si")             llvm_vpscatterqd_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x2, src: simd.i32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv2.di")             llvm_vpscatterqq_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x2, src: simd.i64x2, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv2.df")             llvm_vscatterqpd_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x2, src: simd.f64x2, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv4.sf")             llvm_vscatterqps_128     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x2, src: simd.f32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv8.si")             llvm_vpscatterdd_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x8, src: simd.i32x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv4.di")             llvm_vpscatterdq_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.i64x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv4.df")             llvm_vscatterdpd_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x4, src: simd.f64x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scattersiv8.sf")             llvm_vscatterdps_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i32x8, src: simd.f32x8, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv8.si")             llvm_vpscatterqd_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x4, src: simd.i32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv4.di")             llvm_vpscatterqq_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x4, src: simd.i64x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv4.df")             llvm_vscatterqpd_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x4, src: simd.f64x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.scatterdiv8.sf")             llvm_vscatterqps_256     :: proc(slice: rawptr, mask: u8, offsets: simd.i64x4, src: simd.f32x4, scale: i32) ---
	@(link_name="llvm.x86.avx512.gather3siv4.si")             llvm_vpgatherdd_128      :: proc(src: simd.i32x4, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.gather3siv2.di")             llvm_vpgatherdq_128      :: proc(src: simd.i64x2, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.gather3siv2.df")             llvm_vgatherdpd_128      :: proc(src: simd.f64x2, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.gather3siv4.sf")             llvm_vgatherdps_128      :: proc(src: simd.f32x4, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.gather3div4.si")             llvm_vpgatherqd_128      :: proc(src: simd.i32x4, slice: rawptr, offsets: simd.i64x2, mask: u8, scale: i32) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.gather3div2.di")             llvm_vpgatherqq_128      :: proc(src: simd.i64x2, slice: rawptr, offsets: simd.i64x2, mask: u8, scale: i32) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.gather3div2.df")             llvm_vgatherqpd_128      :: proc(src: simd.f64x2, slice: rawptr, offsets: simd.i64x2, mask: u8, scale: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.gather3div4.sf")             llvm_vgatherqps_128      :: proc(src: simd.f32x4, slice: rawptr, offsets: simd.i64x2, mask: u8, scale: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.gather3siv8.si")             llvm_vpgatherdd_256      :: proc(src: simd.i32x8, slice: rawptr, offsets: simd.i32x8, mask: u8, scale: i32) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.gather3siv4.di")             llvm_vpgatherdq_256      :: proc(src: simd.i64x4, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.gather3siv4.df")             llvm_vgatherdpd_256      :: proc(src: simd.f64x4, slice: rawptr, offsets: simd.i32x4, mask: u8, scale: i32) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.gather3siv8.sf")             llvm_vgatherdps_256      :: proc(src: simd.f32x8, slice: rawptr, offsets: simd.i32x8, mask: u8, scale: i32) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.gather3div8.si")             llvm_vpgatherqd_256      :: proc(src: simd.i32x4, slice: rawptr, offsets: simd.i64x4, mask: u8, scale: i32) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.gather3div4.di")             llvm_vpgatherqq_256      :: proc(src: simd.i64x4, slice: rawptr, offsets: simd.i64x4, mask: u8, scale: i32) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.gather3div4.df")             llvm_vgatherqpd_256      :: proc(src: simd.f64x4, slice: rawptr, offsets: simd.i64x4, mask: u8, scale: i32) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.gather3div8.sf")             llvm_vgatherqps_256      :: proc(src: simd.f32x4, slice: rawptr, offsets: simd.i64x4, mask: u8, scale: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.cmp.ss")                llvm_vcmpss              :: proc(a, b: simd.f32x4, op: i32, m: i8, sae: i32) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.sd")                llvm_vcmpsd              :: proc(a, b: simd.f64x2, op: i32, m: i8, sae: i32) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.ps.512")            llvm_vcmpps              :: proc(a, b: simd.f32x16, op: i32, m: i16, sae: i32) -> i16 ---
	@(link_name="llvm.x86.avx512.mask.cmp.ps.256")            llvm_vcmpps256           :: proc(a, b: simd.f32x8, op: i32, m: i8) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.ps.128")            llvm_vcmpps128           :: proc(a, b: simd.f32x4, op: i32, m: i8) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.pd.512")            llvm_vcmppd              :: proc(a, b: simd.f64x8, op: i32, m: i8, sae: i32) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.pd.256")            llvm_vcmppd256           :: proc(a, b: simd.f64x4, op: i32, m: i8) -> i8 ---
	@(link_name="llvm.x86.avx512.mask.cmp.pd.128")            llvm_vcmppd128           :: proc(a, b: simd.f64x2, op: i32, m: i8) -> i8 ---
	@(link_name="llvm.x86.avx512.psll.d.512")                 llvm_vpslld              :: proc(a: simd.i32x16, count: simd.i32x4) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.psrl.d.512")                 llvm_vpsrld              :: proc(a: simd.i32x16, count: simd.i32x4) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.psll.q.512")                 llvm_vpsllq              :: proc(a: simd.i64x8, count: simd.i64x2) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.psrl.q.512")                 llvm_vpsrlq              :: proc(a: simd.i64x8, count: simd.i64x2) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.psra.d.512")                 llvm_vpsrad              :: proc(a: simd.i32x16, count: simd.i32x4) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.psra.q.512")                 llvm_vpsraq              :: proc(a: simd.i64x8, count: simd.i64x2) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.psra.q.256")                 llvm_vpsraq256           :: proc(a: simd.i64x4, count: simd.i64x2) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.psra.q.128")                 llvm_vpsraq128           :: proc(a: simd.i64x2, count: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.vpermilvar.ps.512")          llvm_vpermilps           :: proc(a: simd.f32x16, b: simd.i32x16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.vpermilvar.pd.512")          llvm_vpermilpd           :: proc(a: simd.f64x8, b: simd.i64x8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.permvar.si.512")             llvm_vpermd              :: proc(a: simd.i32x16, idx: simd.i32x16) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.permvar.di.512")             llvm_vpermq              :: proc(a: simd.i64x8, idx: simd.i64x8) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.permvar.di.256")             llvm_vpermq256           :: proc(a: simd.i64x4, idx: simd.i64x4) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.permvar.sf.512")             llvm_vpermps             :: proc(a: simd.f32x16, idx: simd.i32x16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.permvar.df.512")             llvm_vpermpd             :: proc(a: simd.f64x8, idx: simd.i64x8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.permvar.df.256")             llvm_vpermpd256          :: proc(a: simd.f64x4, idx: simd.i64x4) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.vpermi2var.d.512")           llvm_vpermi2d            :: proc(a: simd.i32x16, idx: simd.i32x16, b: simd.i32x16) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.vpermi2var.d.256")           llvm_vpermi2d256         :: proc(a: simd.i32x8, idx: simd.i32x8, b: simd.i32x8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.vpermi2var.d.128")           llvm_vpermi2d128         :: proc(a: simd.i32x4, idx: simd.i32x4, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.vpermi2var.q.512")           llvm_vpermi2q            :: proc(a: simd.i64x8, idx: simd.i64x8, b: simd.i64x8) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.vpermi2var.q.256")           llvm_vpermi2q256         :: proc(a: simd.i64x4, idx: simd.i64x4, b: simd.i64x4) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.vpermi2var.q.128")           llvm_vpermi2q128         :: proc(a: simd.i64x2, idx: simd.i64x2, b: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.vpermi2var.ps.512")          llvm_vpermi2ps           :: proc(a: simd.f32x16, idx: simd.i32x16, b: simd.f32x16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.vpermi2var.ps.256")          llvm_vpermi2ps256        :: proc(a: simd.f32x8, idx: simd.i32x8, b: simd.f32x8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.vpermi2var.ps.128")          llvm_vpermi2ps128        :: proc(a: simd.f32x4, idx: simd.i32x4, b: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.vpermi2var.pd.512")          llvm_vpermi2pd           :: proc(a: simd.f64x8, idx: simd.i64x8, b: simd.f64x8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.vpermi2var.pd.256")          llvm_vpermi2pd256        :: proc(a: simd.f64x4, idx: simd.i64x4, b: simd.f64x4) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.vpermi2var.pd.128")          llvm_vpermi2pd128        :: proc(a: simd.f64x2, idx: simd.i64x2, b: simd.f64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.compress.d.512")        llvm_vpcompressd         :: proc(a: simd.i32x16, src: simd.i32x16, mask: u16) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.mask.compress.d.256")        llvm_vpcompressd256      :: proc(a: simd.i32x8, src: simd.i32x8, mask: u8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.compress.d.128")        llvm_vpcompressd128      :: proc(a: simd.i32x4, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.compress.q.512")        llvm_vpcompressq         :: proc(a: simd.i64x8, src: simd.i64x8, mask: u8) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.mask.compress.q.256")        llvm_vpcompressq256      :: proc(a: simd.i64x4, src: simd.i64x4, mask: u8) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.mask.compress.q.128")        llvm_vpcompressq128      :: proc(a: simd.i64x2, src: simd.i64x2, mask: u8) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.mask.compress.ps.512")       llvm_vcompressps         :: proc(a: simd.f32x16, src: simd.f32x16, mask: u16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.compress.ps.256")       llvm_vcompressps256      :: proc(a: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.compress.ps.128")       llvm_vcompressps128      :: proc(a: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.compress.pd.512")       llvm_vcompresspd         :: proc(a: simd.f64x8, src: simd.f64x8, mask: u8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.compress.pd.256")       llvm_vcompresspd256      :: proc(a: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.compress.pd.128")       llvm_vcompresspd128      :: proc(a: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.compress.store.d.512")  llvm_vcompressstored     :: proc(mem: rawptr, data: simd.i32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.d.256")  llvm_vcompressstored256  :: proc(mem: rawptr, data: simd.i32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.d.128")  llvm_vcompressstored128  :: proc(mem: rawptr, data: simd.i32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.q.512")  llvm_vcompressstoreq     :: proc(mem: rawptr, data: simd.i64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.q.256")  llvm_vcompressstoreq256  :: proc(mem: rawptr, data: simd.i64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.q.128")  llvm_vcompressstoreq128  :: proc(mem: rawptr, data: simd.i64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.ps.512") llvm_vcompressstoreps    :: proc(mem: rawptr, data: simd.f32x16, mask: u16) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.ps.256") llvm_vcompressstoreps256 :: proc(mem: rawptr, data: simd.f32x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.ps.128") llvm_vcompressstoreps128 :: proc(mem: rawptr, data: simd.f32x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.pd.512") llvm_vcompressstorepd    :: proc(mem: rawptr, data: simd.f64x8, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.pd.256") llvm_vcompressstorepd256 :: proc(mem: rawptr, data: simd.f64x4, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.compress.store.pd.128") llvm_vcompressstorepd128 :: proc(mem: rawptr, data: simd.f64x2, mask: u8) ---
	@(link_name="llvm.x86.avx512.mask.expand.d.512")          llvm_vpexpandd           :: proc(a: simd.i32x16, src: simd.i32x16, mask: u16) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.mask.expand.d.256")          llvm_vpexpandd256        :: proc(a: simd.i32x8, src: simd.i32x8, mask: u8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.d.128")          llvm_vpexpandd128        :: proc(a: simd.i32x4, src: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.q.512")          llvm_vpexpandq           :: proc(a: simd.i64x8, src: simd.i64x8, mask: u8) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.q.256")          llvm_vpexpandq256        :: proc(a: simd.i64x4, src: simd.i64x4, mask: u8) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.q.128")          llvm_vpexpandq128        :: proc(a: simd.i64x2, src: simd.i64x2, mask: u8) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.mask.expand.ps.512")         llvm_vexpandps           :: proc(a: simd.f32x16, src: simd.f32x16, mask: u16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.expand.ps.256")         llvm_vexpandps256        :: proc(a: simd.f32x8, src: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.ps.128")         llvm_vexpandps128        :: proc(a: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.pd.512")         llvm_vexpandpd           :: proc(a: simd.f64x8, src: simd.f64x8, mask: u8) -> simd.f64x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.pd.256")         llvm_vexpandpd256        :: proc(a: simd.f64x4, src: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.pd.128")         llvm_vexpandpd128        :: proc(a: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.add.ss.round")          llvm_vaddss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.add.sd.round")          llvm_vaddsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.sub.ss.round")          llvm_vsubss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.sub.sd.round")          llvm_vsubsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.mul.ss.round")          llvm_vmulss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.mul.sd.round")          llvm_vmulsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.div.ss.round")          llvm_vdivss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.div.sd.round")          llvm_vdivsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.max.ss.round")          llvm_vmaxss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.max.sd.round")          llvm_vmaxsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.min.ss.round")          llvm_vminss              :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.min.sd.round")          llvm_vminsd              :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.sqrt.ss")               llvm_vsqrtss             :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.sqrt.sd")               llvm_vsqrtsd             :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.getexp.ss")             llvm_vgetexpss           :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.getexp.sd")             llvm_vgetexpsd           :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.getmant.ss")            llvm_vgetmantss          :: proc(a, b: simd.f32x4, mantissas: i32, src: simd.f32x4, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.getmant.sd")            llvm_vgetmantsd          :: proc(a, b: simd.f64x2, mantissas: i32, src: simd.f64x2, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.rsqrt14.ss")                 llvm_vrsqrt14ss          :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.rsqrt14.sd")                 llvm_vrsqrt14sd          :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.rcp14.ss")                   llvm_vrcp14ss            :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.rcp14.sd")                   llvm_vrcp14sd            :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.ss")           llvm_vrndscaless         :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, imm8: i32, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.rndscale.sd")           llvm_vrndscalesd         :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, imm8: i32, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.scalef.ss")             llvm_vscalefss           :: proc(a, b: simd.f32x4, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.scalef.sd")             llvm_vscalefsd           :: proc(a, b: simd.f64x2, src: simd.f64x2, mask: u8, rounding: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.vfmadd.f32")                 llvm_vfmaddssround       :: proc(a, b, c: f32, rounding: i32) -> f32 ---
	@(link_name="llvm.x86.avx512.vfmadd.f64")                 llvm_vfmaddsdround       :: proc(a, b, c: f64, rounding: i32) -> f64 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.ss")           llvm_vfixupimmss         :: proc(a, b: simd.f32x4, c: simd.i32x4, imm8: i32, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.fixupimm.sd")           llvm_vfixupimmsd         :: proc(a, b: simd.f64x2, c: simd.i64x2, imm8: i32, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.ss")          llvm_vfixupimmssz        :: proc(a, b: simd.f32x4, c: simd.i32x4, imm8: i32, mask: u8, sae: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.maskz.fixupimm.sd")          llvm_vfixupimmsdz        :: proc(a, b: simd.f64x2, c: simd.i64x2, imm8: i32, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.cvtss2sd.round")        llvm_vcvtss2sd           :: proc(a: simd.f64x2, b: simd.f32x4, src: simd.f64x2, mask: u8, sae: i32) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.cvtsd2ss.round")        llvm_vcvtsd2ss           :: proc(a: simd.f32x4, b: simd.f64x2, src: simd.f32x4, mask: u8, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.vcvtss2si32")                llvm_vcvtss2si           :: proc(a: simd.f32x4, rounding: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.vcvtss2usi32")               llvm_vcvtss2usi          :: proc(a: simd.f32x4, rounding: i32) -> u32 ---
	@(link_name="llvm.x86.avx512.vcvtsd2si32")                llvm_vcvtsd2si           :: proc(a: simd.f64x2, rounding: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.vcvtsd2usi32")               llvm_vcvtsd2usi          :: proc(a: simd.f64x2, rounding: i32) -> u32 ---
	@(link_name="llvm.x86.avx512.cvtsi2ss32")                 llvm_vcvtsi2ss           :: proc(a: simd.f32x4, b: i32, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.cvtusi2ss")                  llvm_vcvtusi2ss          :: proc(a: simd.f32x4, b: u32, rounding: i32) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.cvttss2si")                  llvm_vcvttss2si          :: proc(a: simd.f32x4, rounding: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.cvttss2usi")                 llvm_vcvttss2usi         :: proc(a: simd.f32x4, rounding: i32) -> u32 ---
	@(link_name="llvm.x86.avx512.cvttsd2si")                  llvm_vcvttsd2si          :: proc(a: simd.f64x2, rounding: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.cvttsd2usi")                 llvm_vcvttsd2usi         :: proc(a: simd.f64x2, rounding: i32) -> u32 ---
	@(link_name="llvm.x86.avx512.vcomi.ss")                   llvm_vcomiss             :: proc(a, b: simd.f32x4, imm8: i32, sae: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.vcomi.sd")                   llvm_vcomisd             :: proc(a, b: simd.f64x2, imm8: i32, sae: i32) -> i32 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.d.128")     llvm_expandloadd_128     :: proc(mem_addr: ^i32, a: simd.i32x4, mask: u8) -> simd.i32x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.q.128")     llvm_expandloadq_128     :: proc(mem_addr: ^i64, a: simd.i64x2, mask: u8) -> simd.i64x2 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.ps.128")    llvm_expandloadps_128    :: proc(mem_addr: ^f32, a: simd.f32x4, mask: u8) -> simd.f32x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.pd.128")    llvm_expandloadpd_128    :: proc(mem_addr: ^f64, a: simd.f64x2, mask: u8) -> simd.f64x2 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.d.256")     llvm_expandloadd_256     :: proc(mem_addr: ^i32, a: simd.i32x8, mask: u8) -> simd.i32x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.q.256")     llvm_expandloadq_256     :: proc(mem_addr: ^i64, a: simd.i64x4, mask: u8) -> simd.i64x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.ps.256")    llvm_expandloadps_256    :: proc(mem_addr: ^f32, a: simd.f32x8, mask: u8) -> simd.f32x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.pd.256")    llvm_expandloadpd_256    :: proc(mem_addr: ^f64, a: simd.f64x4, mask: u8) -> simd.f64x4 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.d.512")     llvm_expandloadd_512     :: proc(mem_addr: ^i32, a: simd.i32x16, mask: u16) -> simd.i32x16 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.q.512")     llvm_expandloadq_512     :: proc(mem_addr: ^i64, a: simd.i64x8, mask: u8) -> simd.i64x8 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.ps.512")    llvm_expandloadps_512    :: proc(mem_addr: ^f32, a: simd.f32x16, mask: u16) -> simd.f32x16 ---
	@(link_name="llvm.x86.avx512.mask.expand.load.pd.512")    llvm_expandloadpd_512    :: proc(mem_addr: ^f64, a: simd.f64x8, mask: u8) -> simd.f64x8 ---
}

when ODIN_ARCH == .amd64 {
	@(private="file", default_calling_convention="none")
	foreign _ {
		@(link_name="llvm.x86.sse.cvtss2si64")      llvm_cvtss2si64    :: proc(a: simd.f32x4) -> i64 ---
		@(link_name="llvm.x86.sse2.cvtsd2si64")     llvm_cvtsd2si64    :: proc(a: simd.f64x2) -> i64 ---
		@(link_name="llvm.x86.avx512.vcvtss2si64")  llvm_vcvtss2si64   :: proc(a: simd.f32x4, rounding: i32) -> i64 ---
		@(link_name="llvm.x86.avx512.vcvtss2usi64") llvm_vcvtss2usi64  :: proc(a: simd.f32x4, rounding: i32) -> u64 ---
		@(link_name="llvm.x86.avx512.vcvtsd2si64")  llvm_vcvtsd2si64   :: proc(a: simd.f64x2, rounding: i32) -> i64 ---
		@(link_name="llvm.x86.avx512.vcvtsd2usi64") llvm_vcvtsd2usi64  :: proc(a: simd.f64x2, rounding: i32) -> u64 ---
		@(link_name="llvm.x86.avx512.cvtsi2ss64")   llvm_vcvtsi2ss64   :: proc(a: simd.f32x4, b: i64, rounding: i32) -> simd.f32x4 ---
		@(link_name="llvm.x86.avx512.cvtsi2sd64")   llvm_vcvtsi2sd64   :: proc(a: simd.f64x2, b: i64, rounding: i32) -> simd.f64x2 ---
		@(link_name="llvm.x86.avx512.cvtusi642ss")  llvm_vcvtusi2ss64  :: proc(a: simd.f32x4, b: u64, rounding: i32) -> simd.f32x4 ---
		@(link_name="llvm.x86.avx512.cvtusi642sd")  llvm_vcvtusi2sd64  :: proc(a: simd.f64x2, b: u64, rounding: i32) -> simd.f64x2 ---
		@(link_name="llvm.x86.avx512.cvttss2si64")  llvm_vcvttss2si64  :: proc(a: simd.f32x4, sae: i32) -> i64 ---
		@(link_name="llvm.x86.avx512.cvttss2usi64") llvm_vcvttss2usi64 :: proc(a: simd.f32x4, sae: i32) -> u64 ---
		@(link_name="llvm.x86.avx512.cvttsd2si64")  llvm_vcvttsd2si64  :: proc(a: simd.f64x2, sae: i32) -> i64 ---
		@(link_name="llvm.x86.avx512.cvttsd2usi64") llvm_vcvttsd2usi64 :: proc(a: simd.f64x2, sae: i32) -> u64 ---
	}
}
