#+build i386, amd64
package simd_x86

import "core:simd"

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmadd_pd)
@(require_results, enable_target_feature="fma")
_mm_fmadd_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.fused_mul_add(a, b, c)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmadd_pd)
@(require_results, enable_target_feature="fma")
_mm256_fmadd_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.fused_mul_add(a, b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmadd_ps)
@(require_results, enable_target_feature="fma")
_mm_fmadd_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.fused_mul_add(a, b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmadd_ps)
@(require_results, enable_target_feature="fma")
_mm256_fmadd_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.fused_mul_add(a, b, c)
}

// Multiply the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// and add the intermediate result to the lower element in `c`. Store the result in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmadd_sd)
@(require_results, enable_target_feature="fma")
_mm_fmadd_sd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	elem := simd.fused_mul_add(
		simd.extract(a, 0),
		simd.extract(b, 0),
		simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// and add the intermediate result to the lower element in `c`. Store the result in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmadd_ss)
@(require_results, enable_target_feature="fma")
_mm_fmadd_ss :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	elem := simd.fused_mul_add(
		simd.extract(a, 0),
		simd.extract(b, 0),
		simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmaddsub_pd)
@(require_results, enable_target_feature="fma")
_mm_fmaddsub_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		2, 1,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmaddsub_pd)
@(require_results, enable_target_feature="fma")
_mm256_fmaddsub_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		4, 1, 6, 3,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmaddsub_ps)
@(require_results, enable_target_feature="fma")
_mm_fmaddsub_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		4, 1, 6, 3,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively add and subtract packed elements in `c` to/from the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmaddsub_ps)
@(require_results, enable_target_feature="fma")
_mm256_fmaddsub_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		8, 1, 10, 3, 12, 5, 14, 7,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsub_pd)
@(require_results, enable_target_feature="fma")
_mm_fmsub_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmsub_pd)
@(require_results, enable_target_feature="fma")
_mm256_fmsub_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsub_ps)
@(require_results, enable_target_feature="fma")
_mm_fmsub_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmsub_ps)
@(require_results, enable_target_feature="fma")
_mm256_fmsub_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.fused_mul_add(a, b, simd.neg(c))
}

// Multiply the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// and subtract the lower element in `c` from the intermediate result. Store the result in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsub_sd)
@(require_results, enable_target_feature="fma")
_mm_fmsub_sd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		 simd.extract(b, 0),
		-simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// and subtract the lower element in `c` from the intermediate result. Store the result in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsub_ss)
@(require_results, enable_target_feature="fma")
_mm_fmsub_ss :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		 simd.extract(b, 0),
		-simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsubadd_pd)
@(require_results, enable_target_feature="fma")
_mm_fmsubadd_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 3,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmsubadd_pd)
@(require_results, enable_target_feature="fma")
_mm256_fmsubadd_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 5, 2, 7,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fmsubadd_ps)
@(require_results, enable_target_feature="fma")
_mm_fmsubadd_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 5, 2, 7,
	)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// alternatively subtract and add packed elements in `c` from/to the intermediate result,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fmsubadd_ps)
@(require_results, enable_target_feature="fma")
_mm256_fmsubadd_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.shuffle(
		simd.fused_mul_add(a, b, c),
		simd.fused_mul_add(a, b, simd.neg(c)),
		0, 9, 2, 11, 4, 13, 6, 15,
	)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmadd_pd)
@(require_results, enable_target_feature="fma")
_mm_fnmadd_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fnmadd_pd)
@(require_results, enable_target_feature="fma")
_mm256_fnmadd_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmadd_ps)
@(require_results, enable_target_feature="fma")
_mm_fnmadd_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// add the negated intermediate result to packed elements in `c`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fnmadd_ps)
@(require_results, enable_target_feature="fma")
_mm256_fnmadd_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.fused_mul_add(simd.neg(a), b, c)
}

// Multiply the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// and add the negated intermediate result to the lower element in `c`. Store the result in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmadd_sd)
@(require_results, enable_target_feature="fma")
_mm_fnmadd_sd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		-simd.extract(b, 0),
		 simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// and add the negated intermediate result to the lower element in `c`. Store the result in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmadd_ss)
@(require_results, enable_target_feature="fma")
_mm_fnmadd_ss :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		-simd.extract(b, 0),
		 simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmsub_pd)
@(require_results, enable_target_feature="fma")
_mm_fnmsub_pd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fnmsub_pd)
@(require_results, enable_target_feature="fma")
_mm256_fnmsub_pd :: #force_inline proc "c" (a, b, c: __m256d) -> __m256d {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmsub_ps)
@(require_results, enable_target_feature="fma")
_mm_fnmsub_ps :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`,
// subtract packed elements in `c` from the negated intermediate result, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_fnmsub_ps)
@(require_results, enable_target_feature="fma")
_mm256_fnmsub_ps :: #force_inline proc "c" (a, b, c: __m256) -> __m256 {
	return simd.fused_mul_add(simd.neg(a), b, simd.neg(c))
}

// Multiply the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// and subtract the lower element in `c` from the negated intermediate result. Store the result in the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmsub_sd)
@(require_results, enable_target_feature="fma")
_mm_fnmsub_sd :: #force_inline proc "c" (a, b, c: __m128d) -> __m128d {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		-simd.extract(b, 0),
		-simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}

// Multiply the lower single-precision (32-bit) floating-point elements in `a` and `b`,
// and subtract the lower element in `c` from the negated intermediate result. Store the result in the lower element of `dst`,
// and copy the upper 3 packed elements from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_fnmsub_ss)
@(require_results, enable_target_feature="fma")
_mm_fnmsub_ss :: #force_inline proc "c" (a, b, c: __m128) -> __m128 {
	elem := simd.fused_mul_add(
		 simd.extract(a, 0),
		-simd.extract(b, 0),
		-simd.extract(c, 0),
	)
	return simd.replace(a, 0, elem)
}
