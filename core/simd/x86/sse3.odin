#+build i386, amd64
package simd_x86

import "core:simd"

// Alternatively add and subtract packed double-precision (64-bit) floating-point elements in `a`
// to/from packed elements in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_addsub_pd)
@(require_results, enable_target_feature="sse3")
_mm_addsub_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(
		simd.add(a, b),
		simd.sub(a, b),
		2, 1,
	)
}

// Alternatively add and subtract packed single-precision (32-bit) floating-point elements in `a`
// to/from packed elements in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_addsub_ps)
@(require_results, enable_target_feature="sse3")
_mm_addsub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.shuffle(
		simd.add(a, b),
		simd.sub(a, b),
		4, 1, 6, 3,
	)
}

// Horizontally add adjacent pairs of double-precision (64-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hadd_pd)
@(require_results, enable_target_feature="sse3")
_mm_hadd_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.add(
		simd.shuffle(a, b, 0, 2),
		simd.shuffle(a, b, 1, 3),
	)
}

// Horizontally add adjacent pairs of single-precision (32-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hadd_ps)
@(require_results, enable_target_feature="sse3")
_mm_hadd_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.add(
		simd.shuffle(a, b, 0, 2, 4, 6),
		simd.shuffle(a, b, 1, 3, 5, 7),
	)
}

// Horizontally subtract adjacent pairs of double-precision (64-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hsub_pd)
@(require_results, enable_target_feature="sse3")
_mm_hsub_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.sub(
		simd.shuffle(a, b, 0, 2),
		simd.shuffle(a, b, 1, 3),
	)
}

// Horizontally add adjacent pairs of single-precision (32-bit) floating-point elements in `a` and `b`,
// and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hsub_ps)
@(require_results, enable_target_feature="sse3")
_mm_hsub_ps :: #force_inline proc "c" (a, b: __m128) -> __m128 {
	return simd.sub(
		simd.shuffle(a, b, 0, 2, 4, 6),
		simd.shuffle(a, b, 1, 3, 5, 7),
	)
}

// Load 128-bits of integer data from unaligned memory into `dst`.
// This intrinsic may perform better than `_mm_loadu_si128` when the data crosses a cache line boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_lddqu_si128)
@(require_results, enable_target_feature="sse3")
_mm_lddqu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	return transmute(__m128i)llvm_lddqu(mem_addr)
}

// Duplicate the low double-precision (64-bit) floating-point element from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movedup_pd)
@(require_results, enable_target_feature="sse3")
_mm_movedup_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.shuffle(a, a, 0, 0)
}

// Load a double-precision (64-bit) floating-point element from memory into both elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loaddup_pd)
@(require_results, enable_target_feature="sse3")
_mm_loaddup_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return __m128d(mem_addr^)
}

// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movehdup_ps)
@(require_results, enable_target_feature="sse3")
_mm_movehdup_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.shuffle(a, a, 1, 1, 3, 3)
}

// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_moveldup_ps)
@(require_results, enable_target_feature="sse3")
_mm_moveldup_ps :: #force_inline proc "c" (a: __m128) -> __m128 {
	return simd.shuffle(a, a, 0, 0, 2, 2)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse3.ldu.dq") llvm_lddqu :: proc(mem_addr: rawptr) -> simd.i8x16 ---
}
