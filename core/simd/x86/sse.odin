#+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"

_MM_HINT_T0  : i32 : 3
_MM_HINT_T1  : i32 : 2
_MM_HINT_T2  : i32 : 1
_MM_HINT_NTA : i32 : 0
_MM_HINT_ET0 : i32 : 7
_MM_HINT_ET1 : i32 : 6

_MM_EXCEPT_INVALID    : u32 : 0x0001
_MM_EXCEPT_DENORM     : u32 : 0x0002
_MM_EXCEPT_DIV_ZERO   : u32 : 0x0004
_MM_EXCEPT_OVERFLOW   : u32 : 0x0008
_MM_EXCEPT_UNDERFLOW  : u32 : 0x0010
_MM_EXCEPT_INEXACT    : u32 : 0x0020
_MM_EXCEPT_MASK       : u32 : 0x003f

_MM_MASK_INVALID      : u32 : 0x0080
_MM_MASK_DENORM       : u32 : 0x0100
_MM_MASK_DIV_ZERO     : u32 : 0x0200
_MM_MASK_OVERFLOW     : u32 : 0x0400
_MM_MASK_UNDERFLOW    : u32 : 0x0800
_MM_MASK_INEXACT      : u32 : 0x1000
_MM_MASK_MASK         : u32 : 0x1f80

_MM_ROUND_NEAREST     : u32 : 0x0000
_MM_ROUND_DOWN        : u32 : 0x2000
_MM_ROUND_UP          : u32 : 0x4000
_MM_ROUND_TOWARD_ZERO : u32 : 0x6000

_MM_ROUND_MASK        : u32 : 0x6000

_MM_FLUSH_ZERO_MASK   : u32 : 0x8000
_MM_FLUSH_ZERO_ON     : u32 : 0x8000
_MM_FLUSH_ZERO_OFF    : u32 : 0x0000

// Add the lower single-precision (32-bit) floating-point element in `a` and `b`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_ss)
@(require_results, enable_target_feature="sse")
_mm_add_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.replace(a, 0, simd.extract(a, 0) + simd.extract(b, 0))
}

// Add packed single-precision (32-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_ps)
@(require_results, enable_target_feature="sse")
_mm_add_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.add(a, b)
}

// Subtract the lower single-precision (32-bit) floating-point element in `b`
// from the lower single-precision (32-bit) floating-point element in `a`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_ss)
@(require_results, enable_target_feature="sse")
_mm_sub_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.replace(a, 0, simd.extract(a, 0) - simd.extract(b, 0))
}

// Subtract packed single-precision (32-bit) floating-point elements in `b`
// from packed single-precision (32-bit) floating-point elements in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_ps)
@(require_results, enable_target_feature="sse")
_mm_sub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.sub(a, b)
}

// Multiply the lower single-precision (32-bit) floating-point element in `a` and `b`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_ss)
@(require_results, enable_target_feature="sse")
_mm_mul_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.replace(a, 0, simd.extract(a, 0) * simd.extract(b, 0))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_ps)
@(require_results, enable_target_feature="sse")
_mm_mul_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.mul(a, b)
}

// Divide the lower single-precision (32-bit) floating-point element in `a`
// by the lower single-precision (32-bit) floating-point element in `b`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_div_ss)
@(require_results, enable_target_feature="sse")
_mm_div_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.replace(a, 0, simd.extract(a, 0) / simd.extract(b, 0))
}

// Divide packed single-precision (32-bit) floating-point elements in `a`
// by packed elements in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_div_ps)
@(require_results, enable_target_feature="sse")
_mm_div_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.div(a, b)
}

// Compute the square root of the lower single-precision (32-bit) floating-point element in `a`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sqrt_ss)
@(require_results, enable_target_feature="sse")
_mm_sqrt_ss :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.replace(a, 0, simd.sqrt(simd.extract(a, 0)))
}

// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sqrt_ps)
@(require_results, enable_target_feature="sse")
_mm_sqrt_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.sqrt(a)
}

// Compute the approximate reciprocal of the lower single-precision (32-bit) floating-point element in `a`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rcp_ss)
@(require_results, enable_target_feature="sse")
_mm_rcp_ss :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_rcpss(a)
}

// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rcp_ps)
@(require_results, enable_target_feature="sse")
_mm_rcp_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_rcpps(a)
}

// Compute the approximate reciprocal square root of the lower single-precision (32-bit) floating-point element in `a`,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rsqrt_ss)
@(require_results, enable_target_feature="sse")
_mm_rsqrt_ss :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_rsqrtss(a)
}

// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`,
// and store the results in `dst`. The maximum relative error for this approximation is less than `1.5*2^-12`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_rsqrt_ps)
@(require_results, enable_target_feature="sse")
_mm_rsqrt_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return llvm_rsqrtps(a)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// store the minimum value in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper element of `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_ss)
@(require_results, enable_target_feature="sse")
_mm_min_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_minss(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_ps)
@(require_results, enable_target_feature="sse")
_mm_min_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_minps(a, b)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// store the maximum value in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper element of `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_ss)
@(require_results, enable_target_feature="sse")
_mm_max_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_maxss(a, b)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard
// for Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_ps)
@(require_results, enable_target_feature="sse")
_mm_max_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_maxps(a, b)
}

// Compute the bitwise AND of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_and_ps)
@(require_results, enable_target_feature="sse")
_mm_and_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_and(transmute(__m128i)a, transmute(__m128i)b)
}

// Compute the bitwise NOT of packed single-precision (32-bit) floating-point elements in `a`
// and then AND with `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_andnot_ps)
@(require_results, enable_target_feature="sse")
_mm_andnot_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	c := __m128i(-1)
	return transmute(__m128)simd.bit_and(simd.bit_xor(c, transmute(__m128i)a), transmute(__m128i)b)
}

// Compute the bitwise OR of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_or_ps)
@(require_results, enable_target_feature="sse")
_mm_or_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_or(transmute(__m128i)a, transmute(__m128i)b)
}

// Compute the bitwise XOR of packed single-precision (32-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_xor_ps)
@(require_results, enable_target_feature="sse")
_mm_xor_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return transmute(__m128)simd.bit_xor(transmute(__m128i)a, transmute(__m128i)b)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for equality,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpeq_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 0)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for less-than,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_ss)
@(require_results, enable_target_feature="sse")
_mm_cmplt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 1)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for less-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmple_ss)
@(require_results, enable_target_feature="sse")
_mm_cmple_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 2)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for greater-than,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpgt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, llvm_cmpss(b, a, 1), 4, 1, 2, 3)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for greater-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpge_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpge_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, llvm_cmpss(b, a, 2), 4, 1, 2, 3)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-equal,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from a to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpneq_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpneq_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 4)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnlt_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpnlt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 5)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnle_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpnle_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 6)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpngt_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpngt_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, llvm_cmpss(b, a, 5), 4, 1, 2, 3)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnge_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpnge_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, llvm_cmpss(b, a, 6), 4, 1, 2, 3)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` to see if neither is NaN,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpord_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpord_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 7)
}

// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` to see if either is NaN,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpunord_ss)
@(require_results, enable_target_feature="sse")
_mm_cmpunord_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpss(a, b, 3)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for equality,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpeq_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 0)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for less-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_ps)
@(require_results, enable_target_feature="sse")
_mm_cmplt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 1)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for less-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmple_ps)
@(require_results, enable_target_feature="sse")
_mm_cmple_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 2)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for greater-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpgt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 1)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for greater-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpge_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpge_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 2)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpneq_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpneq_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 4)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnlt_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpnlt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 5)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnle_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpnle_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(a, b, 6)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpngt_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpngt_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 5)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnge_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpnge_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 6)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` to see if neither is NaN,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpord_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpord_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 7)
}

// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` to see if either is NaN,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpunord_ps)
@(require_results, enable_target_feature="sse")
_mm_cmpunord_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return llvm_cmpps(b, a, 3)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for equality,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comieq_ss)
@(require_results, enable_target_feature="sse")
_mm_comieq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comieq_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comilt_ss)
@(require_results, enable_target_feature="sse")
_mm_comilt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comilt_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than-or-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comile_ss)
@(require_results, enable_target_feature="sse")
_mm_comile_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comile_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comigt_ss)
@(require_results, enable_target_feature="sse")
_mm_comigt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comigt_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than-or-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comige_ss)
@(require_results, enable_target_feature="sse")
_mm_comige_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comige_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for not-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comineq_ss)
@(require_results, enable_target_feature="sse")
_mm_comineq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_comineq_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for equality,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomieq_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomieq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomieq_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomilt_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomilt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomilt_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than-or-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomile_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomile_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomile_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomigt_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomigt_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomigt_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than-or-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomige_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomige_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomige_ss(a, b)
}

// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for not-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomineq_ss)
@(require_results, enable_target_feature="sse")
_mm_ucomineq_ss :: #force_inline proc "c" (a, b: __m128) -> b32 {
	return llvm_ucomineq_ss(a, b)
}

// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit integer,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_si32)
@(require_results, enable_target_feature="sse")
_mm_cvtss_si32 :: #force_inline proc "c" (a: __m128) -> i32 {
	return llvm_cvtss2si(a)
}

// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit integer,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_ss2si)
@(require_results, enable_target_feature="sse")
_mm_cvt_ss2si :: #force_inline proc "c" (a: __m128) -> i32 {
	return llvm_cvtss2si(a)
}

// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit integer with truncation,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttss_si32)
@(require_results, enable_target_feature="sse")
_mm_cvttss_si32 :: #force_inline proc "c" (a: __m128) -> i32 {
	return llvm_cvttss2si(a)
}

// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit integer with truncation,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtt_ss2si)
@(require_results, enable_target_feature="sse")
_mm_cvtt_ss2si :: #force_inline proc "c" (a: __m128) -> i32 {
	return llvm_cvttss2si(a)
}

// Copy the lower single-precision (32-bit) floating-point element of `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_f32)
@(require_results, enable_target_feature="sse")
_mm_cvtss_f32 :: #force_inline proc "c" (a: __m128) -> f32 {
	return simd.extract(a, 0)
}

// Convert the signed 32-bit integer `b` to a single-precision (32-bit) floating-point element,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi32_ss)
@(require_results, enable_target_feature="sse")
_mm_cvtsi32_ss :: #force_inline proc "c" (a: __m128, b: i32) -> __m128 {
	return simd.replace(a, 0, f32(b))
}

// Convert the signed 32-bit integer `b` to a single-precision (32-bit) floating-point element,
// store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvt_si2ss)
@(require_results, enable_target_feature="sse")
_mm_cvt_si2ss :: #force_inline proc "c" (a: __m128, b: i32) -> __m128 {
	return simd.replace(a, 0, f32(b))
}

// Copy single-precision (32-bit) floating-point element `a` to the lower element of `dst`,
// and zero the upper 3 elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_ss)
@(require_results, enable_target_feature="sse")
_mm_set_ss :: #force_inline proc "c" (a: f32) -> __m128 {
	return __m128 {a, 0, 0, 0}
}

// Broadcast single-precision (32-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_ps)
@(require_results, enable_target_feature="sse")
_mm_set1_ps :: #force_inline proc "c" (a: f32) -> __m128 {
	return __m128(a)
}

// Broadcast single-precision (32-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_ps1)
@(require_results, enable_target_feature="sse")
_mm_set_ps1 :: #force_inline proc "c" (a: f32) -> __m128 {
	return __m128(a)
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_ps)
@(require_results, enable_target_feature="sse")
_mm_set_ps :: #force_inline proc "c" (e3, e2, e1, e0: f32) -> __m128 {
	return __m128 {e0, e1, e2, e3}
}

// Set packed single-precision (32-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setr_ps)
@(require_results, enable_target_feature="sse")
_mm_setr_ps :: #force_inline proc "c" (e3, e2, e1, e0: f32) -> __m128 {
	return __m128 {e3, e2, e1, e0}
}

// Return vector of type __m128 with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setzero_ps)
@(require_results, enable_target_feature="sse")
_mm_setzero_ps :: #force_inline proc "c" () -> __m128 {
	return __m128(0)
}

// Shuffle single-precision (32-bit) floating-point elements in `a` using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shuffle_ps)
@(require_results, enable_target_feature="sse")
_mm_shuffle_ps :: #force_inline proc "c" (a, b: __m128, $IMM8: i32) -> __m128 where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		b,
		(u32(IMM8) & 0b11),
		((u32(IMM8) >> 2) & 0b11),
		((u32(IMM8) >> 4) & 0b11) + 4,
		((u32(IMM8) >> 6) & 0b11) + 4,
	)
}

// Unpack and interleave single-precision (32-bit) floating-point elements from the high half `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_ps)
@(require_results, enable_target_feature="sse")
_mm_unpackhi_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 2, 6, 3, 7)
}

// Unpack and interleave single-precision (32-bit) floating-point elements from the low half of `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_ps)
@(require_results, enable_target_feature="sse")
_mm_unpacklo_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 0, 4, 1, 5)
}

// Move the upper 2 single-precision (32-bit) floating-point elements from `b` to the lower 2 elements of `dst`,
// and copy the upper 2 elements from `a` to the upper 2 elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movehl_ps)
@(require_results, enable_target_feature="sse")
_mm_movehl_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 6, 7, 2, 3)
}

// Move the lower 2 single-precision (32-bit) floating-point elements from `b` to the upper 2 elements of `dst`,
// and copy the lower 2 elements from `a` to the lower 2 elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movelh_ps)
@(require_results, enable_target_feature="sse")
_mm_movelh_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 0, 1, 4, 5)
}

// Set each bit of mask `dst` based on the most significant bit of the corresponding
// packed single-precision (32-bit) floating-point element in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movemask_ps)
@(require_results, enable_target_feature="sse")
_mm_movemask_ps :: #force_inline proc "c" (a: __m128) -> i32 {
	mask := simd.lanes_lt(transmute(simd.i32x4)a, simd.i32x4(0))
	return i32(transmute(u8)simd.extract_lsbs(mask))
}

// Load a single-precision (32-bit) floating-point element from memory into the lower of `dst`,
// and zero the upper 3 elements. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_ss)
@(require_results, enable_target_feature="sse")
_mm_load_ss :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	return __m128 {mem_addr^, 0, 0, 0}
}

// Load a single-precision (32-bit) floating-point element from memory into all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load1_ps)
@(require_results, enable_target_feature="sse")
_mm_load1_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	a := mem_addr^
	return __m128(a)
}

// Load a single-precision (32-bit) floating-point element from memory into all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_ps1)
@(require_results, enable_target_feature="sse")
_mm_load_ps1 :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	a := mem_addr^
	return __m128(a)
}

// Load 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from memory into `dst`.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_ps)
@(require_results, enable_target_feature="sse")
_mm_load_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	return (^__m128)(mem_addr)^
}

// Load 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from memory into `dst`.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_ps)
@(require_results, enable_target_feature="sse")
_mm_loadu_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	dst := _mm_undefined_ps()
	intrinsics.mem_copy_non_overlapping(&dst, mem_addr, size_of(__m128))
	return dst
}

// Load 4 single-precision (32-bit) floating-point elements from memory into `dst` in reverse order.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadr_ps)
@(require_results, enable_target_feature="sse")
_mm_loadr_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m128 {
	a := _mm_load_ps(mem_addr)
	return simd.shuffle(a, a, 3, 2, 1, 0)
}

// Store the lower single-precision (32-bit) floating-point element from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_ss)
@(enable_target_feature="sse")
_mm_store_ss :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	mem_addr^ = simd.extract(a, 0)
}

// Store the lower single-precision (32-bit) floating-point element from `a` into 4 contiguous elements in memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store1_ps)
@(enable_target_feature="sse")
_mm_store1_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	b := simd.shuffle(a, a, 0, 0, 0, 0)
	(^__m128)(mem_addr)^ = b
}

// Store the lower single-precision (32-bit) floating-point element from `a` into 4 contiguous elements in memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_ps1)
@(enable_target_feature="sse")
_mm_store_ps1 :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	b := simd.shuffle(a, a, 0, 0, 0, 0)
	(^__m128)(mem_addr)^ = b
}

// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_ps)
@(enable_target_feature="sse")
_mm_store_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	(^__m128)(mem_addr)^ = a
}

// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_ps)
@(enable_target_feature="sse")
_mm_storeu_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	b := a
	intrinsics.mem_copy_non_overlapping(mem_addr, &b, size_of(__m128))
}

// Store 4 single-precision (32-bit) floating-point elements from `a` into memory in reverse order.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storer_ps)
@(enable_target_feature="sse")
_mm_storer_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m128) {
	b := simd.shuffle(a, a, 3, 2, 1, 0)
	(^__m128)(mem_addr)^ = b
}

// Move the lower single-precision (32-bit) floating-point element from `b` to the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_move_ss)
@(require_results, enable_target_feature="sse")
_mm_move_ss :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(a, b, 4, 1, 2, 3)
}

// Perform a serializing operation on all store-to-memory instructions that were issued prior to this instruction.
// Guarantees that every store instruction that precedes, in program order, is globally visible before any store
// instruction which follows the fence in program order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sfence)
@(enable_target_feature="sse")
_mm_sfence :: #force_inline proc "c" () {
	llvm_sfence()
}

// Get the unsigned 32-bit value of the MXCSR control and status register.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_getcsr)
@(require_results, enable_target_feature="sse")
_mm_getcsr :: #force_inline proc "c" () -> (dst: u32) {
	llvm_stmxcsr(&dst)
	return
}

// Set the MXCSR control and status register with the value in unsigned 32-bit integer `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setcsr)
@(enable_target_feature="sse")
_mm_setcsr :: #force_inline proc "c" (val: u32) {
	val := val
	llvm_ldmxcsr(&val)
}

// Get the exception mask bits from the MXCSR control and status register.
// The exception mask may contain any of the following flags:
// `_MM_MASK_INVALID`, `_MM_MASK_DIV_ZERO`, `_MM_MASK_DENORM`,
// `_MM_MASK_OVERFLOW`, `_MM_MASK_UNDERFLOW`, `_MM_MASK_INEXACT`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_GET_EXCEPTION_MASK)
@(require_results, enable_target_feature="sse")
_MM_GET_EXCEPTION_MASK :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_MASK_MASK
}

// Get the exception state bits from the MXCSR control and status register.
// The exception state may contain any of the following flags:
// `_MM_EXCEPT_INVALID`, `_MM_EXCEPT_DIV_ZERO`, `_MM_EXCEPT_DENORM`,
// `_MM_EXCEPT_OVERFLOW`, `_MM_EXCEPT_UNDERFLOW`, `_MM_EXCEPT_INEXACT`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_GET_EXCEPTION_STATE)
@(require_results, enable_target_feature="sse")
_MM_GET_EXCEPTION_STATE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_EXCEPT_MASK
}

// Get the flush zero bits from the MXCSR control and status register.
// The flush zero may contain any of the following flags:
// `_MM_FLUSH_ZERO_ON` or `_MM_FLUSH_ZERO_OFF`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_GET_FLUSH_ZERO_MODE)
@(require_results, enable_target_feature="sse")
_MM_GET_FLUSH_ZERO_MODE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_FLUSH_ZERO_MASK
}

// Macro: Get the rounding mode bits from the MXCSR control and status register.
// The rounding mode may contain any of the following flags:
// `_MM_ROUND_NEAREST`, `_MM_ROUND_DOWN`, `_MM_ROUND_UP`, `_MM_ROUND_TOWARD_ZERO`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_GET_ROUNDING_MODE)
@(require_results, enable_target_feature="sse")
_MM_GET_ROUNDING_MODE :: #force_inline proc "c" () -> u32 {
	return _mm_getcsr() & _MM_ROUND_MASK
}

// Set the exception mask bits of the MXCSR control
// and status register to the value in unsigned 32-bit integer `a`.
// The exception mask may contain any of the following flags:
// `_MM_MASK_INVALID`, `_MM_MASK_DIV_ZERO`, `_MM_MASK_DENORM`,
// `_MM_MASK_OVERFLOW`, `_MM_MASK_UNDERFLOW`, `_MM_MASK_INEXACT`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_SET_EXCEPTION_MASK)
@(enable_target_feature="sse")
_MM_SET_EXCEPTION_MASK :: #force_inline proc "c" (a: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_MASK_MASK) | (a & _MM_MASK_MASK))
}

// Set the exception state bits of the MXCSR control
// and status register to the value in unsigned 32-bit integer `a`.
// The exception state may contain any of the following flags:
// `_MM_EXCEPT_INVALID`, `_MM_EXCEPT_DIV_ZERO`, `_MM_EXCEPT_DENORM`,
// `_MM_EXCEPT_OVERFLOW`, `_MM_EXCEPT_UNDERFLOW`, `_MM_EXCEPT_INEXACT`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_SET_EXCEPTION_STATE)
@(enable_target_feature="sse")
_MM_SET_EXCEPTION_STATE :: #force_inline proc "c" (a: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_EXCEPT_MASK) | (a & _MM_EXCEPT_MASK))
}

// Set the flush zero bits of the MXCSR control
// and status register to the value in unsigned 32-bit integer `a`.
// The flush zero may contain any of the following flags:
// `_MM_FLUSH_ZERO_ON` or `_MM_FLUSH_ZERO_OFF`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_SET_FLUSH_ZERO_MODE)
@(enable_target_feature="sse")
_MM_SET_FLUSH_ZERO_MODE :: #force_inline proc "c" (a: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_FLUSH_ZERO_MASK) | (a & _MM_FLUSH_ZERO_MASK))
}

// Set the rounding mode bits of the MXCSR control
// and status register to the value in unsigned 32-bit integer `a`.
// The rounding mode may contain any of the following flags:
// `_MM_ROUND_NEAREST`, `_MM_ROUND_DOWN`,
// `_MM_ROUND_UP`, `_MM_ROUND_TOWARD_ZERO`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_SET_ROUNDING_MODE)
@(enable_target_feature="sse")
_MM_SET_ROUNDING_MODE :: #force_inline proc "c" (a: u32) {
	_mm_setcsr((_mm_getcsr() &~ _MM_ROUND_MASK) | (a & _MM_ROUND_MASK))
}

// Fetch the line of data from memory that contains address `mem_addr`
// to a location in the cache hierarchy specified by the locality hint `HINT`,
// which can be one of: `_MM_HINT_T0`, `_MM_HINT_T1`, `_MM_HINT_T2`,
// `_MM_HINT_NTA`, `_MM_HINT_ET0`, `_MM_HINT_ET1`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_prefetch)
@(enable_target_feature="sse")
_mm_prefetch :: #force_inline proc "c" (mem_addr: rawptr, $HINT: i32) where 0 <= HINT, HINT < 8 {
	llvm_prefetch(mem_addr, (HINT >> 2) & 1, (HINT & 3), 1)
}

// Return vector of type __m128 with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_undefined_ps)
@(require_results, enable_target_feature="sse")
_mm_undefined_ps :: #force_inline proc "c" () -> __m128 {
	return __m128(0)
}

// Transpose the 4x4 matrix formed by the 4 rows of single-precision (32-bit) floating-point elements
// in `row0`, `row1`, `row2`, and `row3`, and store the transposed matrix in these vectors (`row0` now contains column 0, etc.).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_MM_TRANSPOSE4_PS)
@(enable_target_feature="sse")
_MM_TRANSPOSE4_PS :: #force_inline proc "c" (row0, row1, row2, row3: ^__m128) {
	tmp0 := _mm_unpacklo_ps(row0^, row1^)
	tmp2 := _mm_unpacklo_ps(row2^, row3^)
	tmp1 := _mm_unpackhi_ps(row0^, row1^)
	tmp3 := _mm_unpackhi_ps(row2^, row3^)

	row0^ = _mm_movelh_ps(tmp0, tmp2)
	row1^ = _mm_movehl_ps(tmp2, tmp0)
	row2^ = _mm_movelh_ps(tmp1, tmp3)
	row3^ = _mm_movehl_ps(tmp3, tmp1)
}

when ODIN_ARCH == .amd64 {
	// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements)
	// from `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 16-byte
	// boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_ps)
	// @(enable_target_feature="sse")
	// _mm_stream_ps :: asm (mem_addr: ^f32, a: __m128) {
	// 	movntps [mem_addr], a
	// }

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_si64)
	@(require_results, enable_target_feature="sse")
	_mm_cvtss_si64 :: #force_inline proc "c"(a: __m128) -> i64 {
		return llvm_cvtss2si64(a)
	}

	// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttss_si64)
	@(require_results, enable_target_feature="sse")
	_mm_cvttss_si64 :: #force_inline proc "c"(a: __m128) -> i64 {
		return llvm_cvttss2si64(a)
	}

	// Convert the signed 64-bit integer `b` to a single-precision (32-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper 3 packed elements
	// from `a` to the upper elements of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi64_ss)
	@(require_results, enable_target_feature="sse")
	_mm_cvtsi64_ss :: #force_inline proc "c"(a: __m128, b: i64) -> __m128 {
		return simd.replace(a, 0, f32(b))
	}
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse.rcp.ss")      llvm_rcpss       :: proc(a: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.rcp.ps")      llvm_rcpps       :: proc(a: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.rsqrt.ss")    llvm_rsqrtss     :: proc(a: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.rsqrt.ps")    llvm_rsqrtps     :: proc(a: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.min.ss")      llvm_minss       :: proc(a, b: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.min.ps")      llvm_minps       :: proc(a, b: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.max.ss")      llvm_maxss       :: proc(a, b: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.max.ps")      llvm_maxps       :: proc(a, b: simd.f32x4) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.cmp.ss")      llvm_cmpss       :: proc(a, b: simd.f32x4, imm8: i8) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.cmp.ps")      llvm_cmpps       :: proc(a, b: simd.f32x4, imm8: i8) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse.comieq.ss")   llvm_comieq_ss   :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.comilt.ss")   llvm_comilt_ss   :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.comile.ss")   llvm_comile_ss   :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.comigt.ss")   llvm_comigt_ss   :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.comige.ss")   llvm_comige_ss   :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.comineq.ss")  llvm_comineq_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomieq.ss")  llvm_ucomieq_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomilt.ss")  llvm_ucomilt_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomile.ss")  llvm_ucomile_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomigt.ss")  llvm_ucomigt_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomige.ss")  llvm_ucomige_ss  :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.ucomineq.ss") llvm_ucomineq_ss :: proc(a, b: simd.f32x4) -> b32 ---
	@(link_name="llvm.x86.sse.cvtss2si")    llvm_cvtss2si    :: proc(a: simd.f32x4) -> i32 ---
	@(link_name="llvm.x86.sse.cvttss2si")   llvm_cvttss2si   :: proc(a: simd.f32x4) -> i32 ---
	@(link_name="llvm.x86.sse.sfence")      llvm_sfence      :: proc() ---
	@(link_name="llvm.x86.sse.stmxcsr")     llvm_stmxcsr     :: proc(p: rawptr) ---
	@(link_name="llvm.x86.sse.ldmxcsr")     llvm_ldmxcsr     :: proc(p: rawptr) ---
	@(link_name="llvm.prefetch.p0")         llvm_prefetch    :: proc(p: rawptr, rw: i32, loc: i32, ty: i32) ---
}

when ODIN_ARCH == .amd64 {
	@(private, default_calling_convention="none")
	foreign _ {
		@(link_name="llvm.x86.sse.cvtss2si64")  llvm_cvtss2si64  :: proc(a: simd.f32x4) -> i64 ---
		@(link_name="llvm.x86.sse.cvttss2si64") llvm_cvttss2si64 :: proc(a: simd.f32x4) -> i64 ---
	}
}
