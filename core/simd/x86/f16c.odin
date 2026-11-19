#+build i386, amd64
package simd_x86

import "core:simd"

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtph_ps)
@(require_results, enable_target_feature="f16c")
_mm_cvtph_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	b := transmute(simd.f16x8)a
	return cast(__m128)simd.shuffle(b, b, 0, 1, 2, 3)
}

// Convert packed half-precision (16-bit) floating-point elements in `a`
// to packed single-precision (32-bit) floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtph_ps)
@(require_results, enable_target_feature="f16c")
_mm256_cvtph_ps :: #force_inline proc "c" (a: __m128i) -> __m256 {
	return cast(__m256)(transmute(simd.f16x8)a)
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
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtps_ph)
@(require_results, enable_target_feature="f16c")
_mm_cvtps_ph :: #force_inline proc "c" (a: __m128, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph128(a, ROUNDING)
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
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtps_ph)
@(require_results, enable_target_feature="f16c")
_mm256_cvtps_ph :: #force_inline proc "c" (a: __m256, $ROUNDING: i32) -> __m128i {
	#assert(0 <= ROUNDING && ROUNDING < 5, "simd/x86: invalid ROUNDING value")
	return transmute(__m128i)llvm_vcvtps2ph256(a, ROUNDING)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.vcvtps2ph.128") llvm_vcvtps2ph128 :: proc(a: simd.f32x4, rounding: i32) -> simd.i16x8 ---
	@(link_name="llvm.x86.vcvtps2ph.256") llvm_vcvtps2ph256 :: proc(a: simd.f32x8, rounding: i32) -> simd.i16x8 ---
}
