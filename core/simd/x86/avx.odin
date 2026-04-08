#+build i386, amd64
package simd_x86

import "base:intrinsics"

// Adds packed double-precision (64-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_add_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_add(a, b)
}

// Adds packed single-precision (32-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_add_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_add(a, b)
}

// Computes the bitwise AND of a packed double-precision (64-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_and_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	a := transmute(#simd[4]u64)a
	b := transmute(#simd[4]u64)b
	return transmute(__m256d)intrinsics.simd_bit_and(a, b)
}

// Computes the bitwise AND of packed single-precision (32-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_and_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	a := transmute(#simd[8]u32)a
	b := transmute(#simd[8]u32)b
	return transmute(__m256)intrinsics.simd_bit_and(a, b)
}

// Computes the bitwise OR packed double-precision (64-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_or_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	a := transmute(#simd[4]u64)a
	b := transmute(#simd[4]u64)b
	return transmute(__m256d)intrinsics.simd_bit_or(a, b)
}

// Computes the bitwise OR packed single-precision (32-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_or_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	a := transmute(#simd[8]u32)a
	b := transmute(#simd[8]u32)b
	return transmute(__m256)intrinsics.simd_bit_or(a, b)
}

// Shuffles double-precision (64-bit) floating-point elements within 128-bit lanes using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_shuffle_pd :: #force_inline proc "c" (a, b: __m256d, $MASK: u8) -> __m256d {
	return intrinsics.simd_shuffle(
		a,
		b,
		MASK & 1,
		((MASK >> 1) & 1) + 4,
		((MASK >> 2) & 1) + 2,
		((MASK >> 3) & 1) + 6,
	)
}


// Shuffles single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_shuffle_ps :: #force_inline proc "c" (a, b: __m256, $MASK: u8) -> __m256 {
	return intrinsics.simd_shuffle(
		a,
		b,
		MASK & 0b11,
		(MASK >> 2) & 0b11,
		((MASK >> 4) & 0b11) + 8,
		((MASK >> 6) & 0b11) + 8,
		(MASK & 0b11) + 4,
		((MASK >> 2) & 0b11) + 4,
		((MASK >> 4) & 0b11) + 12,
		((MASK >> 6) & 0b11) + 12,
	)
}



// Computes the bitwise NOT of packed double-precision (64-bit) floating-point elements in `a`, and then AND with `b`.
@(require_results, enable_target_feature="avx")
_mm256_andnot_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	a := transmute(#simd[4]u64)a
	b := transmute(#simd[4]u64)b
	return transmute(__m256d)intrinsics.simd_bit_and(intrinsics.simd_bit_xor((#simd[4]u64)(0), a), b)
}

// Computes the bitwise NOT of packed single-precision (32-bit) floating-point elements in `a` and then AND with `b`.
@(require_results, enable_target_feature="avx")
_mm256_andnot_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	a := transmute(#simd[8]u32)a
	b := transmute(#simd[8]u32)b
	return transmute(__m256)intrinsics.simd_bit_and(intrinsics.simd_bit_xor((#simd[8]u32)(0), a), b)
}



// Compares packed double-precision (64-bit) floating-point elements in `a` and `b`, and returns packed maximum values
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_pd)
@(require_results, enable_target_feature="avx")
_mm256_max_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return llvm_vmaxpd(a, b)
}

// Compares packed single-precision (32-bit) floating-point elements in `a` and `b`, and returns packed maximum values
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_max_ps)
@(require_results, enable_target_feature="avx")
_mm256_max_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return llvm_vmaxps(a, b)
}

// Compares packed double-precision (64-bit) floating-point elements in `a` and `b`, and returns packed minimum values
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_pd)
@(require_results, enable_target_feature="avx")
_mm256_min_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return llvm_vminpd(a, b)
}

// Compares packed single-precision (32-bit) floating-point elements in `a` and `b`, and returns packed minimum values
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_min_ps)
@(require_results, enable_target_feature="avx")
_mm256_min_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return llvm_vminps(a, b)
}



// Multiplies packed double-precision (64-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_mul_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_mul(a, b)
}

// Multiplies packed single-precision (32-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_mul_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_mul(a, b)
}

// Alternatively adds and subtracts packed double-precision (64-bit) floating-point elements in `a` to/from packed elements in `b`.
@(require_results, enable_target_feature="avx")
_mm256_addsub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	add := intrinsics.simd_add(a, b)
	sub := intrinsics.simd_sub(a, b)
	return intrinsics.simd_shuffle(add, sub, 4, 1, 6, 3)
}


// Alternatively adds and subtracts packed single-precision (32-bit) floating-point elements in `a` to/from packed elements in `b`.
@(require_results, enable_target_feature="avx")
_mm256_addsub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	add := intrinsics.simd_add(a, b)
	sub := intrinsics.simd_sub(a, b)
	return intrinsics.simd_shuffle(add, sub, 8, 1, 10, 3, 12, 5, 14, 7)
}


// Subtracts packed double-precision (64-bit) floating-point elements in `b`
// from packed elements in `a`.
@(require_results, enable_target_feature="avx")
_mm256_sub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_sub(a, b)
}

// Subtracts packed single-precision (32-bit) floating-point elements in `b`
// from packed elements in `a`.
@(require_results, enable_target_feature="avx")
_mm256_sub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_sub(a, b)
}

// Computes the division of each of the 8 packed 32-bit floating-point elements
// in `a` by the corresponding packed elements in `b`.
@(require_results, enable_target_feature="avx")
_mm256_div_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_div(a, b)
}

// Computes the division of each of the 4 packed 64-bit floating-point elements
// in `a` by the corresponding packed elements in `b`.
@(require_results, enable_target_feature="avx")
_mm256_div_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_div(a, b)
}



// Rounds packed double-precision (64-bit) floating point elements in `a`
// according to the flag `ROUNDING`. The value of `ROUNDING` may be as follows:
//
// - `0x00`: Round to the nearest whole number.
// - `0x01`: Round down, toward negative infinity.
// - `0x02`: Round up, toward positive infinity.
// - `0x03`: Truncate the values.
//
// For a complete list of options, check [the LLVM docs][llvm_docs].
//
// [llvm_docs]: https://github.com/llvm-mirror/clang/blob/dcd8d797b20291f1a6b3e0ddda085aa2bbb382a8/lib/Headers/avxintrin.h#L382
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_round_pd)
@(require_results, enable_target_feature="avx")
_mm256_round_pd :: #force_inline proc "c" (a: __m256d, $ROUNDING: u8) -> __m256d where ROUNDING < 16 {
	return llvm_roundpd256(a, ROUNDING)
}

// Rounds packed double-precision (64-bit) floating point elements in `a`
// toward positive infinity.
@(require_results, enable_target_feature="avx")
_mm256_ceil_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return intrinsics.simd_ceil(a)
}

// Rounds packed double-precision (64-bit) floating point elements in `a`
// toward negative infinity.
@(require_results, enable_target_feature="avx")
_mm256_floor_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return intrinsics.simd_floor(a)
}



// Rounds packed single-precision (32-bit) floating point elements in `a`
// according to the flag `ROUNDING`. The value of `ROUNDING` may be as follows:
//
// - `0x00`: Round to the nearest whole number.
// - `0x01`: Round down, toward negative infinity.
// - `0x02`: Round up, toward positive infinity.
// - `0x03`: Truncate the values.
//
// For a complete list of options, check [the LLVM docs][llvm_docs].
//
// [llvm_docs]: https://github.com/llvm-mirror/clang/blob/dcd8d797b20291f1a6b3e0ddda085aa2bbb382a8/lib/Headers/avxintrin.h#L382
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_round_ps)
@(require_results, enable_target_feature="avx")
_mm256_round_ps :: #force_inline proc(a: __m256, $ROUNDING: u8) -> __m256 where ROUNDING < 16 {
	return llvm_roundps256(a, u32(ROUNDING))
}

// Rounds packed single-precision (32-bit) floating point elements in `a`
// toward positive infinity.
@(require_results, enable_target_feature="avx")
_mm256_ceil_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return intrinsics.simd_ceil(a)
}

// Rounds packed single-precision (32-bit) floating point elements in `a`
// toward negative infinity.
@(require_results, enable_target_feature="avx")
_mm256_floor_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return intrinsics.simd_floor(a)
}

// Returns the square root of packed single-precision (32-bit) floating point elements in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sqrt_ps)
@(require_results, enable_target_feature="avx")
_mm256_sqrt_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return intrinsics.sqrt(a)
}

// Returns the square root of packed double-precision (64-bit) floating point elements in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sqrt_pd)
@(require_results, enable_target_feature="avx")
_mm256_sqrt_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return intrinsics.sqrt(a)
}



// Blends packed double-precision (64-bit) floating-point elements from
// `a` and `b` using control mask `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_blend_pd)
@(require_results, enable_target_feature="avx")
_mm256_blend_pd :: #force_inline proc "c" (a, b: __m256d, $IIM4: u32) -> __m256d where IMM4 < 16 {
	return intrinsics.simd_shuffle(
		a,
		b,
		((IMM4 >> 0) & 1) * 4 + 0,
		((IMM4 >> 1) & 1) * 4 + 1,
		((IMM4 >> 2) & 1) * 4 + 2,
		((IMM4 >> 3) & 1) * 4 + 3,
	)
}

// Blends packed single-precision (32-bit) floating-point elements from
// `a` and `b` using control mask `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_blend_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: u8) -> __m256 {
	return intrinsics.simd_shuffle(
		a,
		b,
		((IMM8 >> 0) & 1) * 8 + 0,
		((IMM8 >> 1) & 1) * 8 + 1,
		((IMM8 >> 2) & 1) * 8 + 2,
		((IMM8 >> 3) & 1) * 8 + 3,
		((IMM8 >> 4) & 1) * 8 + 4,
		((IMM8 >> 5) & 1) * 8 + 5,
		((IMM8 >> 6) & 1) * 8 + 6,
		((IMM8 >> 7) & 1) * 8 + 7,
	)
}



// Blends packed double-precision (64-bit) floating-point elements from
// `a` and `b` using `c` as a mask.
@(require_results, enable_target_feature="avx")
_mm256_blendv_pd :: #force_inline proc "c" (a, b: __m256d, c: __m256d) -> __m256d {
	mask := intrinsics.simd_lanes_lt(transmute(#simd[4]i64)c, 0)
	return intrinsics.simd_select(mask, b, a)
}

// Blends packed single-precision (32-bit) floating-point elements from
// `a` and `b` using `c` as a mask.
@(require_results, enable_target_feature="avx")
_mm256_blendv_ps :: #force_inline proc "c" (a, b: __m256, c: __m256) -> __m256 {
	mask := intrinsics.simd_lanes_lt(transmute(#simd[8]i32)c, 0)
	return intrinsics.simd_select(mask, b, a)
}



// Conditionally multiplies the packed single-precision (32-bit) floating-point elements in `a` and `b` using the high 4 bits in `imm8`,
// sum the four products, and conditionally return the sum
//  using the low 4 bits of `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_dp_ps)
@(require_results, enable_target_feature="avx")
_mm256_dp_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: i8) -> __m256 {
	return llvm_vdpps(a, b, IMM8)
}

// Horizontal addition of adjacent pairs in the two packed vectors
// of 4 64-bit floating points `a` and `b`.
// In the result, sums of elements from `a` are returned in even locations,
// while sums of elements from `b` are returned in odd locations.
@(require_results, enable_target_feature="avx")
_mm256_hadd_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	even := intrinsics.simd_shuffle(a, b, 0, 4, 2, 6)
	odd  := intrinsics.simd_shuffle(a, b, 1, 5, 3, 7)
	return intrinsics.simd_add(even, odd)
}



// Horizontal addition of adjacent pairs in the two packed vectors
// of 8 32-bit floating points `a` and `b`.
// In the result, sums of elements from `a` are returned in locations of
// indices 0, 1, 4, 5; while sums of elements from `b` are locations
// 2, 3, 6, 7.
@(require_results, enable_target_feature="avx")
_mm256_hadd_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	even := intrinsics.simd_shuffle(a, b, 0, 2, 8, 10, 4, 6, 12, 14)
	odd  := intrinsics.simd_shuffle(a, b, 1, 3, 9, 11, 5, 7, 13, 15)
	return intrinsics.simd_add(even, odd)
}

// Horizontal subtraction of adjacent pairs in the two packed vectors
// of 4 64-bit floating points `a` and `b`.
// In the result, sums of elements from `a` are returned in even locations,
// while sums of elements from `b` are returned in odd locations.
@(require_results, enable_target_feature="avx")
_mm256_hsub_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	even := intrinsics.simd_shuffle(a, b, 0, 4, 2, 6)
	odd  := intrinsics.simd_shuffle(a, b, 1, 5, 3, 7)
	return intrinsics.simd_sub(even, odd)
}

// Horizontal subtraction of adjacent pairs in the two packed vectors
// of 8 32-bit floating points `a` and `b`.
// In the result, sums of elements from `a` are returned in locations of
// indices 0, 1, 4, 5; while sums of elements from `b` are locations
// 2, 3, 6, 7.
@(require_results, enable_target_feature="avx")
_mm256_hsub_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	even := intrinsics.simd_shuffle(a, b, 0, 2, 8, 10, 4, 6, 12, 14)
	odd  := intrinsics.simd_shuffle(a, b, 1, 3, 9, 11, 5, 7, 13, 15)
	return intrinsics.simd_sub(even, odd)
}

// Computes the bitwise XOR of packed double-precision (64-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_xor_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	a := transmute(#simd[4]u64)a
	b := transmute(#simd[4]u64)b
	return transmute(__m256d)intrinsics.simd_bit_xor(a, b)
}

// Computes the bitwise XOR of packed single-precision (32-bit) floating-point elements in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_xor_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	a := transmute(#simd[8]u32)a
	b := transmute(#simd[8]u32)b
	return transmute(__m256)intrinsics.simd_bit_xor(a, b)
}



_CMP_EQ_OQ    :: 0x00 // Equal (ordered, non-signaling)
_CMP_LT_OS    :: 0x01 // Less-than (ordered, signaling)
_CMP_LE_OS    :: 0x02 // Less-than-or-equal (ordered, signaling)
_CMP_UNORD_Q  :: 0x03 // Unordered (non-signaling)
_CMP_NEQ_UQ   :: 0x04 // Not-equal (unordered, non-signaling)
_CMP_NLT_US   :: 0x05 // Not-less-than (unordered, signaling)
_CMP_NLE_US   :: 0x06 // Not-less-than-or-equal (unordered, signaling)
_CMP_ORD_Q    :: 0x07 // Ordered (non-signaling)
_CMP_EQ_UQ    :: 0x08 // Equal (unordered, non-signaling)
_CMP_NGE_US   :: 0x09 // Not-greater-than-or-equal (unordered, signaling)
_CMP_NGT_US   :: 0x0a // Not-greater-than (unordered, signaling)
_CMP_FALSE_OQ :: 0x0b // False (ordered, non-signaling)
_CMP_NEQ_OQ   :: 0x0c // Not-equal (ordered, non-signaling)
_CMP_GE_OS    :: 0x0d // Greater-than-or-equal (ordered, signaling)
_CMP_GT_OS    :: 0x0e // Greater-than (ordered, signaling)
_CMP_TRUE_UQ  :: 0x0f // True (unordered, non-signaling)
_CMP_EQ_OS    :: 0x10 // Equal (ordered, signaling)
_CMP_LT_OQ    :: 0x11 // Less-than (ordered, non-signaling)
_CMP_LE_OQ    :: 0x12 // Less-than-or-equal (ordered, non-signaling)
_CMP_UNORD_S  :: 0x13 // Unordered (signaling)
_CMP_NEQ_US   :: 0x14 // Not-equal (unordered, signaling)
_CMP_NLT_UQ   :: 0x15 // Not-less-than (unordered, non-signaling)
_CMP_NLE_UQ   :: 0x16 // Not-less-than-or-equal (unordered, non-signaling)
_CMP_ORD_S    :: 0x17 // Ordered (signaling)
_CMP_EQ_US    :: 0x18 // Equal (unordered, signaling)
_CMP_NGE_UQ   :: 0x19 // Not-greater-than-or-equal (unordered, non-signaling)
_CMP_NGT_UQ   :: 0x1a // Not-greater-than (unordered, non-signaling)
_CMP_FALSE_OS :: 0x1b // False (ordered, signaling)
_CMP_NEQ_OS   :: 0x1c // Not-equal (ordered, signaling)
_CMP_GE_OQ    :: 0x1d // Greater-than-or-equal (ordered, non-signaling)
_CMP_GT_OQ    :: 0x1e // Greater-than (ordered, non-signaling)
_CMP_TRUE_US  :: 0x1f // True (unordered, signaling)



// Compares packed double-precision (64-bit) floating-point elements in `a` and `b` based on the comparison operand specified by `IMM5`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_pd)
@(require_results, enable_target_feature="avx")
_mm_cmp_pd :: #force_inline proc "c" (a, b: __m128d, $IMM5: u8) -> __m128d where IMM5 < 32 {
	return llvm_vcmppd(a, b, IMM5)
}

// Compares packed double-precision (64-bit) floating-point elements in `a` and `b` based on the comparison operand specified by `IMM5`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmp_pd)
@(require_results, enable_target_feature="avx")
_mm256_cmp_pd :: #force_inline proc "c" (a, b: __m256d, $IMM5: u8) -> __m256d where IMM5 < 32 {
	return llvm_vcmppd256(a, b, IMM5)
}

// Compares packed single-precision (32-bit) floating-point elements in `a` and `b` based on the comparison operand specified by `IMM5`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_ps)
@(require_results, enable_target_feature="avx")
_mm_cmp_ps :: #force_inline proc "c" (a: __m128, b: __m128, $IMM5: u8) -> __m128 where IMM5 < 32 {
	return llvm_vcmpps(a, b, IMM5)
}

// Compares packed single-precision (32-bit) floating-point elements in `a` and `b` based on the comparison operand specified by `IMM5`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cmp_ps)
@(require_results, enable_target_feature="avx")
_mm256_cmp_ps :: #force_inline proc "c" (a, b: __m256, $IMM5: u8) -> __m256 where IMM5 < 32 {
	return llvm_vcmpps256(a, b, IMM5)
}

// Compares the lower double-precision (64-bit) floating-point element in
// `a` and `b` based on the comparison operand specified by `IMM5`,
// store the result in the lower element of returned vector,
// and copies the upper element from `a` to the upper element of returned
// vector.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_sd)
@(require_results, enable_target_feature="avx")
_mm_cmp_sd :: #force_inline proc "c" (a, b: __m128d, $IMM5: u8) -> __m128d where IMM5 < 32 {
	return llvm_vcmpsd(a, b, IMM5)
}

// Compares the lower single-precision (32-bit) floating-point element in
// `a` and `b` based on the comparison operand specified by `IMM5`,
// store the result in the lower element of returned vector,
// and copies the upper 3 packed elements from `a` to the upper elements of
// returned vector.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmp_ss)
@(require_results, enable_target_feature="avx")
_mm_cmp_ss :: #force_inline proc "c" (a: __m128, b: __m128, $IMM5: u8) -> __m128 where IMM5 < 32 {
	return llvm_vcmpss(a, b, IMM5)
}

// Converts packed 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements.
@(require_results, enable_target_feature="avx")
_mm256_cvtepi32_pd :: #force_inline proc "c" (a: __m128i) -> __m256d {
	return __m256d(transmute(#simd[4]i32)a)
}

// Converts packed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements.
@(require_results, enable_target_feature="avx")
_mm256_cvtepi32_ps :: #force_inline proc "c" (a: __m256i) -> __m256 {
	return __m256(transmute(#simd[8]i32)a)
}

// Converts packed double-precision (64-bit) floating-point elements in `a` to packed single-precision (32-bit) floating-point elements.
@(require_results, enable_target_feature="avx")
_mm256_cvtpd_ps :: #force_inline proc "c" (a: __m256d) -> __m128 {
	return __m128(a)
}

// Converts packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtps_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvtps_epi32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvtps2dq(a)
}

// Converts packed single-precision (32-bit) floating-point elements in `a` to packed double-precision (64-bit) floating-point elements.
@(require_results, enable_target_feature="avx")
_mm256_cvtps_pd :: #force_inline proc "c" (a: __m128) -> __m256d {
	return __m256d(a)
}

// Returns the first element of the input vector of `[4 x double]`.
@(require_results, enable_target_feature="avx")
_mm256_cvtsd_f64 :: #force_inline proc "c" (a: __m256d) -> f64 {
	return intrinsics.simd_extract(a, 0)
}

// Converts packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers with truncation.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttpd_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvttpd_epi32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvttpd2dq(a)
}

// Converts packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvtpd_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvtpd_epi32 :: #force_inline proc "c" (a: __m256d) -> __m128i {
	return transmute(__m128i)llvm_vcvtpd2dq(a)
}

// Converts packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers with truncation.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_cvttps_epi32)
@(require_results, enable_target_feature="avx")
_mm256_cvttps_epi32 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)llvm_vcvttps2dq(a)
}



// Extracts 128 bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a`, selected with `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_extractf128_ps :: #force_inline proc "c" (a: __m256, $IMM1: u8) -> __m128 where IMM1 < 2 {
	when IMM1 == 0 {
		return intrinsics.simd_shuffle(a, _mm256_undefined_ps(), 0, 1, 2, 3)
	} else {
		return intrinsics.simd_shuffle(a, _mm256_undefined_ps(), 4, 5, 6, 7)
	}
}

// Extracts 128 bits (composed of 2 packed double-precision (64-bit) floating-point elements) from `a`, selected with `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_extractf128_pd :: #force_inline proc "c" (a: __m256d, $IMM1: u8) -> __m128d where IMM1 < 2 {
	when IMM1 == 0 {
		return intrinsics.simd_shuffle(a, _mm256_undefined_pd(), 0, 1)
	} else {
		return intrinsics.simd_shuffle(a, _mm256_undefined_pd(), 2, 3)
	}
}

// Extracts 128 bits (composed of integer data) from `a`, selected with `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_extractf128_si256 :: #force_inline proc "c" (a: __m256i, $IMM1: u8) -> __m128i where IMM1 < 2 {
	when IMM1 == 0 {
		dst := intrinsics.simd_shuffle(transmute(#simd[4]i64)a, (#simd[4]i64)(0), 0, 1)
		return transmute(__m128i)dst
	} else {
		dst := intrinsics.simd_shuffle(transmute(#simd[4]i64)a, (#simd[4]i64)(0), 2, 3)
		return transmute(__m128i)dst
	}
}

// Extracts a 32-bit integer from `a`, selected with `INDEX`.
@(require_results, enable_target_feature="avx")
_mm256_extract_epi32 :: #force_inline proc "c" (a: __m256i, $INDEX: u8) -> i32 where INDEX < 8 {
	return intrinsics.simd_extract(transmute(#simd[8]i32)a, INDEX)
}

@(require_results, enable_target_feature="avx")
_mm256_cvtsi256_si32 :: #force_inline proc "c" (a: __m256i) -> i32 {
	return intrinsics.simd_extract(transmute(#simd[8]i32)a, 0)
}

// Zeroes the contents of all XMM or YMM registers.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zeroall)
@(enable_target_feature="avx")
_mm256_zeroall :: #force_inline proc "c" () {
	llvm_vzeroall()
}

// Zeroes the upper 128 bits of all YMM registers; the lower 128-bits of the registers are unmodified.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_zeroupper)
@(enable_target_feature="avx")
_mm256_zeroupper :: #force_inline proc "c" () {
	llvm_vzeroupper()
}

// Shuffles single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using the control in `b`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar_ps)
@(require_results, enable_target_feature="avx")
_mm256_permutevar_ps :: #force_inline proc "c" (a: __m256, b: __m256i) -> __m256 {
	return llvm_vpermilps256(a, transmute(#simd[8]i32)b)
}

// Shuffles single-precision (32-bit) floating-point elements in `a` using the control in `b`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permutevar_ps)
@(require_results, enable_target_feature="avx")
_mm_permutevar_ps :: #force_inline proc "c" (a: __m128, b: __m128i) -> __m128 {
	return llvm_vpermilps(a, transmute(#simd[4]i32)b)
}

// Shuffles single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_permute_ps :: #force_inline proc "c" (a: __m256, $IMM8: u8) -> __m256 {
	return intrinsics.simd_shuffle(
		a,
		_mm256_undefined_ps(),
		(IMM8 >> 0) & 0b11,
		(IMM8 >> 2) & 0b11,
		(IMM8 >> 4) & 0b11,
		(IMM8 >> 6) & 0b11,
		((IMM8 >> 0) & 0b11) + 4,
		((IMM8 >> 2) & 0b11) + 4,
		((IMM8 >> 4) & 0b11) + 4,
		((IMM8 >> 6) & 0b11) + 4,
	)
}

// Shuffles single-precision (32-bit) floating-point elements in `a` using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm_permute_ps :: #force_inline proc "c" (a: __m128, $IMM8: u8) -> __m128 {
	return intrinsics.simd_shuffle(
		a,
		_mm_undefined_ps(),
		(IMM8 >> 0) & 0b11,
		(IMM8 >> 2) & 0b11,
		(IMM8 >> 4) & 0b11,
		(IMM8 >> 6) & 0b11,
	)
}

// Shuffles double-precision (64-bit) floating-point elements in `a` within 256-bit lanes using the control in `b`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_permutevar_pd)
@(require_results, enable_target_feature="avx")
_mm256_permutevar_pd :: #force_inline proc "c" (a: __m256d, b: __m256i) -> __m256d {
	return llvm_vpermilpd256(a, b)
}

// Shuffles double-precision (64-bit) floating-point elements in `a` using the control in `b`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_permutevar_pd)
@(require_results, enable_target_feature="avx")
_mm_permutevar_pd :: #force_inline proc "c" (a: __m128d, b: __m128i) -> __m128d {
	return llvm_vpermilpd(a, b)
}

// Shuffles double-precision (64-bit) floating-point elements in `a` within 128-bit lanes using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_permute_pd :: #force_inline proc "c" (a: __m256d, $IMM4: u8) -> __m256d where IMM4 < 16 {
	return intrinsics.simd_shuffle(
		a,
		_mm256_undefined_pd(),
		((IMM4 >> 0) & 1),
		((IMM4 >> 1) & 1),
		((IMM4 >> 2) & 1) + 2,
		((IMM4 >> 3) & 1) + 2,
	)
}

// Shuffles double-precision (64-bit) floating-point elements in `a` using the control in `imm8`.
@(require_results, enable_target_feature="avx")
_mm_permute_pd :: #force_inline proc "c" (a: __m128d, $IMM2: u8) -> __m128d where IMM2 < 4 {
	return intrinsics.simd_shuffle(
		a,
		_mm_undefined_pd(),
		(IMM2) & 1,
		(IMM2 >> 1) & 1,
	)
}



// Shuffles 256 bits (composed of 8 packed single-precision (32-bit) floating-point elements) selected by `imm8` from `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_ps :: #force_inline proc "c" (a, b: __m256, $IMM8: u8) -> __m256 {
	return _mm256_castsi256_ps(_mm256_permute2f128_si256(
		_mm256_castps_si256(a),
		_mm256_castps_si256(b),
		IMM8,
	))
}

// Shuffles 256 bits (composed of 4 packed double-precision (64-bit) floating-point elements) selected by `imm8` from `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_pd :: #force_inline proc "c" (a, b: __m256d, $IMM8: u8) -> __m256d {
	_mm256_castsi256_pd(_mm256_permute2f128_si256(
		_mm256_castpd_si256(a),
		_mm256_castpd_si256(b),
		IMM8,
	))
}

// Shuffles 128-bits (composed of integer data) selected by `imm8` from `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_permute2f128_si256 :: #force_inline proc "c" (a, b: __m256i, $IMM8: u8) -> __m256i {
	r := intrinsics.simd_shuffle(
		a,
		b,
		2 * ((IMM8 & 0xf) & 0b11) + 0,
		2 * ((IMM8 & 0xf) & 0b11) + 1,

		2 * (((IMM8 & 0xf0) >> 4) & 0b11) + 0,
		2 * (((IMM8 & 0xf0) >> 4) & 0b11) + 1,
	)
	return intrinsics.simd_shuffle(
		r,
		__m256i(0),

		4 if ((IMM8 & 0xf) & 0b1000) != 0 else 0,
		4 if ((IMM8 & 0xf) & 0b1000) != 0 else 1,

		4 if (((IMM8 & 0xf0)>>4) & 0b1000) != 0 else 2,
		4 if (((IMM8 & 0xf0)>>4) & 0b1000) != 0 else 3,
	)
}

// Broadcasts a single-precision (32-bit) floating-point element from memory to all elements of the returned vector.
@(require_results, enable_target_feature="avx")
_mm256_broadcast_ss :: #force_inline proc "c" (f: ^f32) -> __m256 {
	return _mm256_set1_ps(f^)
}

// Broadcasts a single-precision (32-bit) floating-point element from memory to all elements of the returned vector.
@(require_results, enable_target_feature="sse,avx")
_mm_broadcast_ss :: #force_inline proc "c" (f: ^f32) -> __m128 {
	return _mm_set1_ps(f^)
}

// Broadcasts a double-precision (64-bit) floating-point element from memory to all elements of the returned vector.
@(require_results, enable_target_feature="avx")
_mm256_broadcast_sd :: #force_inline proc "c" (f: ^f64) -> __m256d {
	return _mm256_set1_pd(f^)
}

// Broadcasts 128 bits from memory (composed of 4 packed single-precision (32-bit) floating-point elements) to all elements of the returned vector.
@(require_results, enable_target_feature="sse,avx")
_mm256_broadcast_ps :: #force_inline proc "c" (a: ^__m128) -> __m256 {
	return intrinsics.simd_shuffle(a^, _mm_setzero_ps(), 0, 1, 2, 3, 0, 1, 2, 3)
}

// Broadcasts 128 bits from memory (composed of 2 packed double-precision (64-bit) floating-point elements) to all elements of the returned vector.
@(require_results, enable_target_feature="sse2,avx")
_mm256_broadcast_pd :: #force_inline proc "c" (a: ^__m128d) -> __m256d {
	return intrinsics.simd_shuffle(a^, _mm_setzero_pd(), 0, 1, 0, 1)
}

// Copies `a` to result, then inserts 128 bits (composed of 4 packed
// single-precision (32-bit) floating-point elements) from `b` into result
// at the location specified by `imm8`.
@(require_results, enable_target_feature="sse,avx")
_mm256_insertf128_ps :: #force_inline proc "c" (a: __m256, b: __m128, $IMM1: u8) -> __m256 where IMM1 < 2 {
	when IMM1 == 0  {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castps128_ps256(b),
			8, 9, 10, 11, 4, 5, 6, 7,
		)
	} else {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castps128_ps256(b),
			0, 1, 2, 3, 8, 9, 10, 11,
		)
	}
}

// Copies `a` to result, then inserts 128 bits (composed of 2 packed
// double-precision (64-bit) floating-point elements) from `b` into result
// at the location specified by `imm8`.
@(require_results, enable_target_feature="sse2,avx")
_mm256_insertf128_pd :: #force_inline proc "c" (a: __m256d, b: __m128d, $IMM1: u8) -> __m256d where IMM1 < 2 {
	when IMM1 == 0 {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castpd128_pd256(b),
			4, 5, 2, 3,
		)
	} else {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castpd128_pd256(b),
			0, 1, 4, 5,
		)
	}
}

// Copies `a` to result, then inserts 128 bits from `b` into result at the location specified by `imm8`.
@(require_results, enable_target_feature="avx")
_mm256_insertf128_si256 :: #force_inline proc "c" (a: __m256i, b: __m128i, $IMM1: u8) -> __m256i where IMM1 < 2 {
	when IMM1 == 0 {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castsi128_si256(b),
			4, 5, 2, 3,
		)
	} else {
		return intrinsics.simd_shuffle(
			a,
			_mm256_castsi128_si256(b),
			0, 1, 4, 5,
		)
	}
}

// Copies `a` to result, and inserts the 8-bit integer `i` into result at the location specified by `index`.
@(require_results, enable_target_feature="avx")
_mm256_insert_epi8 :: #force_inline proc "c" (a: __m256i, i: i8, $INDEX: u8) -> __m256i where INDEX < 32 {
	return transmute(__m256i)intrinsics.simd_replace(transmute(#simd[32]i8)a, INDEX, i)
}

// Copies `a` to result, and inserts the 16-bit integer `i` into result at the location specified by `index`.
@(require_results, enable_target_feature="avx")
_mm256_insert_epi16 :: #force_inline proc "c" (a: __m256i, i: i16, $INDEX: u8) -> __m256i where INDEX < 16 {
	return transmute(__m256i)intrinsics.simd_replace(transmute(#simd[16]i16)a, INDEX, i)
}

// Copies `a` to result, and inserts the 32-bit integer `i` into result at the location specified by `index`.
@(require_results, enable_target_feature="avx")
_mm256_insert_epi32 :: #force_inline proc "c" (a: __m256i, i: i32, $INDEX: u8) -> __m256i where INDEX < 8 {
	return transmute(__m256i)intrinsics.simd_replace(transmute(#simd[8]i32)a, INDEX, i)
}



// Loads 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from memory into result.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_pd)
@(require_results, enable_target_feature="avx")
_mm256_load_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m256d {
	return (^__m256d)(mem_addr)^
}

// Stores 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_pd)
@(enable_target_feature="avx")
_mm256_store_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m256d) {
	(^__m256d)(mem_addr)^ = a
}

// Loads 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from memory into result.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_ps)
@(require_results, enable_target_feature="avx")
_mm256_load_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m256 {
	return (^__m256)(mem_addr)^
}

// Stores 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_ps)
@(enable_target_feature="avx")
_mm256_store_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m256) {
	(^__m256)(mem_addr)^ = a
}

// Loads 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from memory into result.
// `mem_addr` does not need to be aligned on any particular boundary.
@(enable_target_feature="avx")
_mm256_loadu_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m256d {
	return intrinsics.unaligned_load((^__m256d)(mem_addr))
}

// Stores 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
@(enable_target_feature="avx")
_mm256_storeu_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m256d) {
	intrinsics.unaligned_store((^__m256d)(mem_addr), a)
}

// Loads 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from memory into result.
// `mem_addr` does not need to be aligned on any particular boundary.
@(require_results, enable_target_feature="avx")
_mm256_loadu_ps :: #force_inline proc "c" (mem_addr: ^f32) -> __m256 {
	return intrinsics.unaligned_load((^__m256)(mem_addr))
}

// Stores 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
@(enable_target_feature="avx")
_mm256_storeu_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m256) {
	intrinsics.unaligned_store((^__m256)(mem_addr), a)
}

// Loads 256-bits of integer data from memory into result.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_load_si256)
@(require_results, enable_target_feature="avx")
_mm256_load_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return mem_addr^
}

// Stores 256-bits of integer data from `a` into memory.
// `mem_addr` must be aligned on a 32-byte boundary or a
// general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_store_si256)
@(enable_target_feature="avx")
_mm256_store_si256 :: #force_inline proc "c" (mem_addr: ^__m256i, a: __m256i) {
	mem_addr^ = a
}

// Loads 256-bits of integer data from memory into result.
// `mem_addr` does not need to be aligned on any particular boundary.
@(require_results, enable_target_feature="avx")
_mm256_loadu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return intrinsics.unaligned_load(mem_addr)
}

// Stores 256-bits of integer data from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
@(enable_target_feature="avx")
_mm256_storeu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i, a: __m256i) {
	intrinsics.unaligned_store(mem_addr, a)
}

// Loads packed double-precision (64-bit) floating-point elements from memory
// into result using `mask` (elements are zeroed out when the high bit of the
// corresponding element is not set).
@(require_results, enable_target_feature="avx")
_mm256_maskload_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m256i) -> __m256d {
	mask_mask := intrinsics.simd_shr(mask, 63)
	return intrinsics.simd_masked_load(mem_addr, _mm256_setzero_pd(), mask_mask)
}

// Stores packed double-precision (64-bit) floating-point elements from `a`
// into memory using `mask`.
@(enable_target_feature="avx")
_mm256_maskstore_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m256i, a: __m256d) {
	mask_mask := intrinsics.simd_shr(mask, 63)
	intrinsics.simd_masked_store(mem_addr, a, mask_mask)
}


// Loads packed double-precision (64-bit) floating-point elements from memory
// into result using `mask` (elements are zeroed out when the high bit of the
// corresponding element is not set).
@(require_results, enable_target_feature="sse2,avx")
_mm_maskload_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m128i) -> __m128d {
	mask_mask := intrinsics.simd_shr(mask, 63)
	return intrinsics.simd_masked_load(mem_addr, _mm_setzero_pd(), mask_mask)
}

// Stores packed double-precision (64-bit) floating-point elements from `a`
// into memory using `mask`.
@(enable_target_feature="avx")
_mm_maskstore_pd :: #force_inline proc "c" (mem_addr: ^f64, mask: __m128i, a: __m128d) {
	mask_mask := intrinsics.simd_shr(mask, 63)
	intrinsics.simd_masked_store(mem_addr, a, mask_mask)
}

// Loads packed single-precision (32-bit) floating-point elements from memory
// into result using `mask` (elements are zeroed out when the high bit of the
// corresponding element is not set).
@(require_results, enable_target_feature="avx")
_mm256_maskload_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m256i) -> __m256 {
	mask_mask := intrinsics.simd_shr(transmute(#simd[8]i32)mask, 31)
	return intrinsics.simd_masked_load(mem_addr, _mm256_setzero_ps(), mask_mask)
}

// Stores packed single-precision (32-bit) floating-point elements from `a`
// into memory using `mask`.
@(enable_target_feature="avx")
_mm256_maskstore_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m256i, a: __m256) {
	mask_mask := intrinsics.simd_shr(transmute(#simd[8]i32)mask, 31)
	intrinsics.simd_masked_store(mem_addr, a, mask_mask)
}

// Loads packed single-precision (32-bit) floating-point elements from memory
// into result using `mask` (elements are zeroed out when the high bit of the
// corresponding element is not set).
@(require_results, enable_target_feature="sse,avx")
_mm_maskload_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m128i) -> __m128 {
	mask_mask := intrinsics.simd_shr(transmute(#simd[4]i32)mask, 31)
	return intrinsics.simd_masked_load(mem_addr, _mm_setzero_ps(), mask_mask)
}

// Stores packed single-precision (32-bit) floating-point elements from `a`
// into memory using `mask`.
@(enable_target_feature="avx")
_mm_maskstore_ps :: #force_inline proc "c" (mem_addr: ^f32, mask: __m128i, a: __m128) {
	mask_mask := intrinsics.simd_shr(transmute(#simd[4]i32)mask, 31)
	intrinsics.simd_masked_store(mem_addr, a, mask_mask)
}




// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`, and returns the results.
@(require_results, enable_target_feature="avx")
_mm256_movehdup_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return intrinsics.simd_shuffle(a, a, 1, 1, 3, 3, 5, 5, 7, 7)
}

// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`, and returns the results.
@(require_results, enable_target_feature="avx")
_mm256_moveldup_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return intrinsics.simd_shuffle(a, a, 0, 0, 2, 2, 4, 4, 6, 6)
}

// Duplicate even-indexed double-precision (64-bit) floating-point elements from `a`, and returns the results.
@(require_results, enable_target_feature="avx")
_mm256_movedup_pd :: #force_inline proc "c" (a: __m256d) -> __m256d {
	return intrinsics.simd_shuffle(a, a, 0, 0, 2, 2)
}


// Loads 256-bits of integer data from unaligned memory into result.
// This intrinsic may perform better than `_mm256_loadu_si256` when the
// data crosses a cache line boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_lddqu_si256)
@(require_results, enable_target_feature="avx")
_mm256_lddqu_si256 :: #force_inline proc "c" (mem_addr: ^__m256i) -> __m256i {
	return transmute(__m256i)llvm_vlddqu(mem_addr)
}

/*
// Moves integer data from a 256-bit integer vector to a 32-byte
// aligned memory location. To minimize caching, the data is flagged as
// non-temporal (unlikely to be used again soon)
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_si256)
//
// # Safety of non-temporal stores
//
// After using this intrinsic, but before any other access to the memory that this intrinsic
// mutates, a call to [`_mm_sfence`] must be performed by the thread that used the intrinsic. In
// particular, functions that call this intrinsic should generally call `_mm_sfence` before they
// return.
//
// See [`_mm_sfence`] for details.
@(enable_target_feature="avx")
_mm256_stream_si256 :: #force_inline proc "c" (mem_addr: ^__m256i, a: __m256i) {
	panic_contextless("TODO: _mm256_stream_si256")
}

// Moves double-precision values from a 256-bit vector of `[4 x double]`
// to a 32-byte aligned memory location. To minimize caching, the data is
// flagged as non-temporal (unlikely to be used again soon).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_pd)
//
// # Safety of non-temporal stores
//
// After using this intrinsic, but before any other access to the memory that this intrinsic
// mutates, a call to [`_mm_sfence`] must be performed by the thread that used the intrinsic. In
// particular, functions that call this intrinsic should generally call `_mm_sfence` before they
// return.
//
// See [`_mm_sfence`] for details.
@(enable_target_feature="avx")
_mm256_stream_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m256d) {
	panic_contextless("TODO: _mm256_stream_pd")
}

// Moves single-precision floating point values from a 256-bit vector
// of `[8 x float]` to a 32-byte aligned memory location. To minimize
// caching, the data is flagged as non-temporal (unlikely to be used again
// soon).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_stream_ps)
//
// # Safety of non-temporal stores
//
// After using this intrinsic, but before any other access to the memory that this intrinsic
// mutates, a call to [`_mm_sfence`] must be performed by the thread that used the intrinsic. In
// particular, functions that call this intrinsic should generally call `_mm_sfence` before they
// return.
//
// See [`_mm_sfence`] for details.
@(enable_target_feature="avx")
_mm256_stream_ps :: #force_inline proc "c" (mem_addr: ^f32, a: __m256) {
	panic_contextless("TODO: _mm256_stream_ps")
}
*/

// Computes the approximate reciprocal of packed single-precision (32-bit) floating-point elements in `a`, and returns the results. The maximum
// relative error for this approximation is less than 1.5*2^-12.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rcp_ps)
@(require_results, enable_target_feature="avx")
_mm256_rcp_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrcpps(a)
}

// Computes the approximate reciprocal square root of packed single-precision
// (32-bit) floating-point elements in `a`, and returns the results.
// The maximum relative error for this approximation is less than 1.5*2^-12.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_rsqrt_ps)
@(require_results, enable_target_feature="avx")
_mm256_rsqrt_ps :: #force_inline proc "c" (a: __m256) -> __m256 {
	return llvm_vrsqrtps(a)
}



// Unpacks and interleave double-precision (64-bit) floating-point elements
// from the high half of each 128-bit lane in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_unpackhi_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_shuffle(a, b, 1, 5, 3, 7)
}

// Unpacks and interleave single-precision (32-bit) floating-point elements
// from the high half of each 128-bit lane in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_unpackhi_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_shuffle(a, b, 2, 10, 3, 11, 6, 14, 7, 15)
}

// Unpacks and interleave double-precision (64-bit) floating-point elements
// from the low half of each 128-bit lane in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_unpacklo_pd :: #force_inline proc "c" (a, b: __m256d) -> __m256d {
	return intrinsics.simd_shuffle(a, b, 0, 4, 2, 6)
}

// Unpacks and interleave single-precision (32-bit) floating-point elements
// from the low half of each 128-bit lane in `a` and `b`.
@(require_results, enable_target_feature="avx")
_mm256_unpacklo_ps :: #force_inline proc "c" (a, b: __m256) -> __m256 {
	return intrinsics.simd_shuffle(a, b, 0, 8, 1, 9, 4, 12, 5, 13)
}

// Computes the bitwise AND of 256 bits (representing integer data) in `a` and
// `b`, and set `ZF` to 1 if the result is zero, otherwise set `ZF` to 0.
// Computes the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if
// the result is zero, otherwise set `CF` to 0. Return the `ZF` value.
@(require_results, enable_target_feature="avx")
_mm256_testz_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	r := intrinsics.simd_bit_and(a, b)
	return i32(0 == intrinsics.simd_reduce_or(r))
}

// Computes the bitwise AND of 256 bits (representing integer data) in `a` and
// `b`, and set `ZF` to 1 if the result is zero, otherwise set `ZF` to 0.
// Computes the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if
// the result is zero, otherwise set `CF` to 0. Return the `CF` value.
@(require_results, enable_target_feature="avx")
_mm256_testc_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	r := intrinsics.simd_bit_and(intrinsics.simd_bit_xor(a, __m256i(~i64(0))), b)
	return i32(0 == intrinsics.simd_reduce_or(r))
}



// Computes the bitwise AND of 256 bits (representing integer data) in `a` and
// `b`, and set `ZF` to 1 if the result is zero, otherwise set `ZF` to 0.
// Computes the bitwise NOT of `a` and then AND with `b`, and set `CF` to 1 if
// the result is zero, otherwise set `CF` to 0. Return 1 if both the `ZF` and
// `CF` values are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_si256)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_si256 :: #force_inline proc "c" (a, b: __m256i) -> i32 {
	return llvm_ptestnzc256(a, b)
}

// Computes the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testz_pd)
@(require_results, enable_target_feature="avx")
_mm256_testz_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestzpd256(a, b)
}

// Computes the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testc_pd)
@(require_results, enable_target_feature="avx")
_mm256_testc_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestcpd256(a, b)
}

// Computes the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values
// are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_pd)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_pd :: #force_inline proc "c" (a, b: __m256d) -> i32 {
	return llvm_vtestnzcpd256(a, b)
}

// Computes the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `ZF` value.
@(require_results, enable_target_feature="sse2,avx")
_mm_testz_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	r := intrinsics.simd_lanes_lt(transmute(__m128i)_mm_and_pd(a, b), __m128i(0))
	return i32(0 == intrinsics.simd_reduce_or(r))
}

// Computes the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `CF` value.
@(require_results, enable_target_feature="sse2,avx")
_mm_testc_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	r := intrinsics.simd_lanes_lt(transmute(__m128i)_mm_andnot_pd(a, b), __m128i(0))
	return i32(0 == intrinsics.simd_reduce_or(r))
}

// Computes the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 64-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 64-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values
// are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testnzc_pd)
@(require_results, enable_target_feature="avx")
_mm_testnzc_pd :: #force_inline proc "c" (a, b: __m128d) -> i32 {
	return llvm_vtestnzcpd(a, b)
}

// Computes the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `ZF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testz_ps)
@(require_results, enable_target_feature="avx")
_mm256_testz_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestzps256(a, b)
}

// Computes the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `CF` value.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testc_ps)
@(require_results, enable_target_feature="avx")
_mm256_testc_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestcps256(a, b)
}

// Computes the bitwise AND of 256 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 256-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values
// are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_testnzc_ps)
@(require_results, enable_target_feature="avx")
_mm256_testnzc_ps :: #force_inline proc "c" (a, b: __m256) -> i32 {
	return llvm_vtestnzcps256(a, b)
}

// Computes the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `ZF` value.
@(require_results, enable_target_feature="sse,avx")
_mm_testz_ps :: #force_inline proc "c" (a: __m128, b: __m128) -> i32 {
	r := intrinsics.simd_lanes_lt(transmute(#simd[4]i32)_mm_and_ps(a, b), (#simd[4]i32)(0))
	return i32(0 == intrinsics.simd_reduce_or(r))
}

// Computes the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return the `CF` value.
@(require_results, enable_target_feature="sse,avx")
_mm_testc_ps :: #force_inline proc "c" (a: __m128, b: __m128) -> i32 {
	r := intrinsics.simd_lanes_lt(transmute(#simd[4]i32)_mm_andnot_ps(a, b), (#simd[4]i32)(0))
	return i32(0 == intrinsics.simd_reduce_or(r))
}

// Computes the bitwise AND of 128 bits (representing single-precision (32-bit) floating-point elements) in `a` and `b`, producing an intermediate 128-bit
// value, and set `ZF` to 1 if the sign bit of each 32-bit element in the
// intermediate value is zero, otherwise set `ZF` to 0. Compute the bitwise
// NOT of `a` and then AND with `b`, producing an intermediate value, and set
// `CF` to 1 if the sign bit of each 32-bit element in the intermediate value
// is zero, otherwise set `CF` to 0. Return 1 if both the `ZF` and `CF` values
// are zero, otherwise return 0.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_testnzc_ps)
@(require_results, enable_target_feature="avx")
_mm_testnzc_ps :: #force_inline proc "c" (a: __m128, b: __m128) -> i32 {
	return llvm_vtestnzcps(a, b)
}

// Sets each bit of the returned mask based on the most significant bit of the
// corresponding packed double-precision (64-bit) floating-point element in
// `a`.
@(require_results, enable_target_feature="avx")
_mm256_movemask_pd :: #force_inline proc "c" (a: __m256d) -> i32 {
	mask := intrinsics.simd_lanes_lt(transmute(#simd[4]i64)a, (#simd[4]i64)(0))
	return i32(transmute(u8)intrinsics.simd_extract_lsbs(mask))
}

// Sets each bit of the returned mask based on the most significant bit of the
// corresponding packed single-precision (32-bit) floating-point element in
// `a`.
@(require_results, enable_target_feature="avx")
_mm256_movemask_ps :: #force_inline proc "c" (a: __m256) -> i32 {
	// Propagate the highest bit to the rest, because simd_bitmask
	// requires all-1 or all-0.
	mask := intrinsics.simd_lanes_lt(transmute(#simd[8]i32)a, (#simd[8]i32)(0))
	return i32(transmute(u8)intrinsics.simd_extract_lsbs(mask))
}

// Returns vector of type __m256d with all elements set to zero.
@(require_results, enable_target_feature="avx")
_mm256_setzero_pd :: #force_inline proc "c" () -> __m256d {
	return 0
}

// Returns vector of type __m256 with all elements set to zero.
@(require_results, enable_target_feature="avx")
_mm256_setzero_ps :: #force_inline proc "c" () -> __m256 {
	return 0
}

// Returns vector of type __m256i with all elements set to zero.
@(require_results, enable_target_feature="avx")
_mm256_setzero_si256 :: #force_inline proc "c" () -> __m256i {
	return 0
}

// Sets packed double-precision (64-bit) floating-point elements in returned
// vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_pd :: #force_inline proc "c" (a: f64, b: f64, c: f64, d: f64) -> __m256d {
	return _mm256_setr_pd(d, c, b, a)
}

// Sets packed single-precision (32-bit) floating-point elements in returned
// vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_ps :: #force_inline proc "c" (
	a: f32,
	b: f32,
	c: f32,
	d: f32,
	e: f32,
	f: f32,
	g: f32,
	h: f32,
) -> __m256 {
	return _mm256_setr_ps(h, g, f, e, d, c, b, a)
}

// Sets packed 8-bit integers in returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_epi8 :: #force_inline proc "c" (
	e00, e01, e02, e03, e04, e05, e06, e07: i8,
	e08, e09, e10, e11, e12, e13, e14, e15: i8,
	e16, e17, e18, e19, e20, e21, e22, e23: i8,
	e24, e25, e26, e27, e28, e29, e30, e31: i8,
) -> __m256i {
	return _mm256_setr_epi8(
		e31, e30, e29, e28, e27, e26, e25, e24,
		e23, e22, e21, e20, e19, e18, e17, e16,
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	)
}

// Sets packed 16-bit integers in returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_epi16 :: #force_inline proc "c" (
	e00, e01, e02, e03, e04, e05, e06, e07: i16,
	e08, e09, e10, e11, e12, e13, e14, e15: i16,
) -> __m256i {
	return _mm256_setr_epi16(
		e15, e14, e13, e12,
		e11, e10, e09, e08,
		e07, e06, e05, e04,
		e03, e02, e01, e00,
	)
}

// Sets packed 32-bit integers in returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_epi32 :: #force_inline proc "c" (e0, e1, e2, e3, e4, e5, e6, e7: i32) -> __m256i {
	return _mm256_setr_epi32(e7, e6, e5, e4, e3, e2, e1, e0)
}

// Sets packed 64-bit integers in returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_epi64x :: #force_inline proc "c" (a: i64, b: i64, c: i64, d: i64) -> __m256i {
	return _mm256_setr_epi64x(d, c, b, a)
}

// Sets packed double-precision (64-bit) floating-point elements in returned
// vector with the supplied values in reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_pd :: #force_inline proc "c" (a: f64, b: f64, c: f64, d: f64) -> __m256d {
	return __m256d{a, b, c, d}
}

// Sets packed single-precision (32-bit) floating-point elements in returned
// vector with the supplied values in reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_ps :: #force_inline proc "c" (a, b, c, d, e, f, g, h: f32) -> __m256 {
	return __m256{a, b, c, d, e, f, g, h}
}

// Sets packed 8-bit integers in returned vector with the supplied values in
// reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_epi8 :: #force_inline proc "c" (
	e00, e01, e02, e03, e04, e05, e06, e07: i8,
	e08, e09, e10, e11, e12, e13, e14, e15: i8,
	e16, e17, e18, e19, e20, e21, e22, e23: i8,
	e24, e25, e26, e27, e28, e29, e30, e31: i8,
) -> __m256i {
	return transmute(__m256i)#simd[32]i8{
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
		e16, e17, e18, e19, e20, e21, e22, e23,
		e24, e25, e26, e27, e28, e29, e30, e31,
	}
}

// Sets packed 16-bit integers in returned vector with the supplied values in
// reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_epi16 :: #force_inline proc "c" (
	e00, e01, e02, e03, e04, e05, e06, e07: i16,
	e08, e09, e10, e11, e12, e13, e14, e15: i16,
) -> __m256i {
	return transmute(__m256i)#simd[16]i16{
		e00, e01, e02, e03,
		e04, e05, e06, e07,
		e08, e09, e10, e11,
		e12, e13, e14, e15,
	}
}

// Sets packed 32-bit integers in returned vector with the supplied values in
// reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_epi32 :: #force_inline proc "c" (e0, e1, e2, e3, e4, e5, e6, e7: i32) -> __m256i {
	return transmute(__m256i)#simd[8]i32{e0, e1, e2, e3, e4, e5, e6, e7}
}

// Sets packed 64-bit integers in returned vector with the supplied values in
// reverse order.
@(require_results, enable_target_feature="avx")
_mm256_setr_epi64x :: #force_inline proc "c" (a: i64, b: i64, c: i64, d: i64) -> __m256i {
	return {a, b, c, d}
}

// Broadcasts double-precision (64-bit) floating-point value `a` to all elements of returned vector.
@(require_results, enable_target_feature="avx")
_mm256_set1_pd :: #force_inline proc "c" (a: f64) -> __m256d {
	return a
}

// Broadcasts single-precision (32-bit) floating-point value `a` to all elements of returned vector.
@(require_results, enable_target_feature="avx")
_mm256_set1_ps :: #force_inline proc "c" (a: f32) -> __m256 {
	return a
}

// Broadcasts 8-bit integer `a` to all elements of returned vector.
// This intrinsic may generate the `vpbroadcastb`.
@(require_results, enable_target_feature="avx")
_mm256_set1_epi8 :: #force_inline proc "c" (a: i8) -> __m256i {
	return transmute(__m256i)(#simd[32]i8)(a)
}

// Broadcasts 16-bit integer `a` to all elements of returned vector.
// This intrinsic may generate the `vpbroadcastw`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi16)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi16 :: #force_inline proc "c" (a: i16) -> __m256i {
	return transmute(__m256i)(#simd[16]i16)(a)
}

// Broadcasts 32-bit integer `a` to all elements of returned vector.
// This intrinsic may generate the `vpbroadcastd`.
@(require_results, enable_target_feature="avx")
_mm256_set1_epi32 :: #force_inline proc "c" (a: i32) -> __m256i {
	return transmute(__m256i)(#simd[8]i32)(a)
}

// Broadcasts 64-bit integer `a` to all elements of returned vector.
// This intrinsic may generate the `vpbroadcastq`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_set1_epi64x)
@(require_results, enable_target_feature="avx")
_mm256_set1_epi64x :: #force_inline proc "c" (a: i64) -> __m256i {
	return a
}

// Cast vector of type __m256d to type __m256.
@(require_results, enable_target_feature="avx")
_mm256_castpd_ps :: #force_inline proc "c" (a: __m256d) -> __m256 {
	return transmute(__m256)a
}

// Cast vector of type __m256 to type __m256d.
@(require_results, enable_target_feature="avx")
_mm256_castps_pd :: #force_inline proc "c" (a: __m256) -> __m256d {
	return transmute(__m256d)a
}

// Casts vector of type __m256 to type __m256i.
@(require_results, enable_target_feature="avx")
_mm256_castps_si256 :: #force_inline proc "c" (a: __m256) -> __m256i {
	return transmute(__m256i)a
}

// Casts vector of type __m256i to type __m256.
@(require_results, enable_target_feature="avx")
_mm256_castsi256_ps :: #force_inline proc "c" (a: __m256i) -> __m256 {
	return transmute(__m256)a
}

// Casts vector of type __m256d to type __m256i.
@(require_results, enable_target_feature="avx")
_mm256_castpd_si256 :: #force_inline proc "c" (a: __m256d) -> __m256i {
	return transmute(__m256i)a
}

// Casts vector of type __m256i to type __m256d.
@(require_results, enable_target_feature="avx")
_mm256_castsi256_pd :: #force_inline proc "c" (a: __m256i) -> __m256d {
	return transmute(__m256d)a
}

// Casts vector of type __m256 to type __m128.
@(require_results, enable_target_feature="avx")
_mm256_castps256_ps128 :: #force_inline proc "c" (a: __m256) -> __m128 {
	return intrinsics.simd_shuffle(a, a, 0, 1, 2, 3)
}

// Casts vector of type __m256d to type __m128d.
@(require_results, enable_target_feature="avx")
_mm256_castpd256_pd128 :: #force_inline proc "c" (a: __m256d) -> __m128d {
	return intrinsics.simd_shuffle(a, a, 0, 1)
}

// Casts vector of type __m256i to type __m128i.
@(require_results, enable_target_feature="avx")
_mm256_castsi256_si128 :: #force_inline proc "c" (a: __m256i) -> __m128i {
	return intrinsics.simd_shuffle(a, a, 0, 1)
}

// Casts vector of type __m128 to type __m256;
// the upper 128 bits of the result are indeterminate.
//
// In the Intel documentation, the upper bits are declared to be "undefined".
@(require_results, enable_target_feature="sse,avx")
_mm256_castps128_ps256 :: #force_inline proc "c" (a: __m128) -> __m256 {
	return intrinsics.simd_shuffle(a, _mm_undefined_ps(), 0, 1, 2, 3, 4, 4, 4, 4)
}

// Casts vector of type __m128d to type __m256d;
// the upper 128 bits of the result are indeterminate.
//
// In the Intel documentation, the upper bits are declared to be "undefined".
@(require_results, enable_target_feature="sse2,avx")
_mm256_castpd128_pd256 :: #force_inline proc "c" (a: __m128d) -> __m256d {
	return intrinsics.simd_shuffle(a, _mm_undefined_pd(), 0, 1, 2, 2)
}

// Casts vector of type __m128i to type __m256i;
// the upper 128 bits of the result are indeterminate.
//
// In the Intel documentation, the upper bits are declared to be "undefined".
@(require_results, enable_target_feature="avx")
_mm256_castsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return intrinsics.simd_shuffle(a, __m128i(0), 0, 1, 2, 2)
}

// Constructs a 256-bit floating-point vector of `[8 x float]` from a
// 128-bit floating-point vector of `[4 x float]`. The lower 128 bits contain
// the value of the source vector. The upper 128 bits are set to zero.
@(require_results, enable_target_feature="sse,avx")
_mm256_zextps128_ps256 :: #force_inline proc "c" (a: __m128) -> __m256 {
	return intrinsics.simd_shuffle(a, _mm_setzero_ps(), 0, 1, 2, 3, 4, 5, 6, 7)
}

// Constructs a 256-bit integer vector from a 128-bit integer vector.
// The lower 128 bits contain the value of the source vector. The upper
// 128 bits are set to zero.
@(require_results, enable_target_feature="avx")
_mm256_zextsi128_si256 :: #force_inline proc "c" (a: __m128i) -> __m256i {
	return intrinsics.simd_shuffle(a, __m128i(0), 0, 1, 2, 3)
}

// Constructs a 256-bit floating-point vector of `[4 x double]` from a
// 128-bit floating-point vector of `[2 x double]`. The lower 128 bits
// contain the value of the source vector. The upper 128 bits are set
// to zero.
@(require_results, enable_target_feature="sse2,avx")
_mm256_zextpd128_pd256 :: #force_inline proc "c" (a: __m128d) -> __m256d {
	return intrinsics.simd_shuffle(a, _mm_setzero_pd(), 0, 1, 2, 3)
}

// Returns vector of type `__m256` with indeterminate elements.
// Despite using the word "undefined" (following Intel's naming scheme), this non-deterministically
@(require_results, enable_target_feature="avx")
_mm256_undefined_ps :: #force_inline proc "c" () -> __m256 {
	return 0
}

// Returns vector of type `__m256d` with indeterminate elements.
// Despite using the word "undefined" (following Intel's naming scheme), this non-deterministically
@(require_results, enable_target_feature="avx")
_mm256_undefined_pd :: #force_inline proc "c" () -> __m256d {
	return 0
}

// Returns vector of type __m256i with with indeterminate elements.
// Despite using the word "undefined" (following Intel's naming scheme), this non-deterministically
@(require_results, enable_target_feature="avx")
_mm256_undefined_si256 :: #force_inline proc "c" () -> __m256i {
	return 0
}

// Sets packed __m256 returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_m128 :: #force_inline proc "c" (hi: __m128, lo: __m128) -> __m256 {
	return intrinsics.simd_shuffle(lo, hi, 0, 1, 2, 3, 4, 5, 6, 7)
}

// Sets packed __m256d returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_m128d :: #force_inline proc "c" (hi: __m128d, lo: __m128d) -> __m256d {
	hi := transmute(__m128)hi
	lo := transmute(__m128)lo
	return transmute(__m256d)_mm256_set_m128(hi, lo)
}

// Sets packed __m256i returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_set_m128i :: #force_inline proc "c" (hi: __m128i, lo: __m128i) -> __m256i {
	hi := transmute(__m128)hi
	lo := transmute(__m128)lo
	return transmute(__m256i)_mm256_set_m128(hi, lo)
}

// Sets packed __m256 returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_setr_m128 :: #force_inline proc "c" (lo: __m128, hi: __m128) -> __m256 {
	return _mm256_set_m128(hi, lo)
}

// Sets packed __m256d returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_setr_m128d :: #force_inline proc "c" (lo: __m128d, hi: __m128d) -> __m256d {
	return _mm256_set_m128d(hi, lo)
}

// Sets packed __m256i returned vector with the supplied values.
@(require_results, enable_target_feature="avx")
_mm256_setr_m128i :: #force_inline proc "c" (lo: __m128i, hi: __m128i) -> __m256i {
	return _mm256_set_m128i(hi, lo)
}

// Loads two 128-bit values (composed of 4 packed single-precision (32-bit) floating-point elements) from memory, and combine them into a 256-bit value.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(require_results, enable_target_feature="sse,avx")
_mm256_loadu2_m128 :: #force_inline proc "c" (hiaddr, loaddr: ^f32) -> __m256 {
	a := _mm256_castps128_ps256(_mm_loadu_ps(loaddr))
	return _mm256_insertf128_ps(a, _mm_loadu_ps(hiaddr), 1)
}

// Loads two 128-bit values (composed of 2 packed double-precision (64-bit) floating-point elements) from memory, and combine them into a 256-bit value.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(require_results, enable_target_feature="sse2,avx")
_mm256_loadu2_m128d :: #force_inline proc "c" (hiaddr, loaddr: ^f64) -> __m256d {
	a := _mm256_castpd128_pd256(_mm_loadu_pd(loaddr))
	return _mm256_insertf128_pd(a, _mm_loadu_pd(hiaddr), 1)
}

// Loads two 128-bit values (composed of integer data) from memory, and combine them into a 256-bit value.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(require_results, enable_target_feature="sse2,avx")
_mm256_loadu2_m128i :: #force_inline proc "c" (hiaddr, loaddr: ^__m128i) -> __m256i {
	a := _mm256_castsi128_si256(_mm_loadu_si128(loaddr))
	return _mm256_insertf128_si256(a, _mm_loadu_si128(hiaddr), 1)
}

// Stores the high and low 128-bit halves (each composed of 4 packed
// single-precision (32-bit) floating-point elements) from `a` into memory two
// different 128-bit locations.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(enable_target_feature="sse,avx")
_mm256_storeu2_m128 :: #force_inline proc "c" (hiaddr, loaddr: ^f32, a: __m256) {
	lo := _mm256_castps256_ps128(a)
	_mm_storeu_ps(loaddr, lo)
	hi := _mm256_extractf128_ps(a, 1)
	_mm_storeu_ps(hiaddr, hi)
}

// Stores the high and low 128-bit halves (each composed of 2 packed
// double-precision (64-bit) floating-point elements) from `a` into memory two
// different 128-bit locations.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(enable_target_feature="sse2,avx")
_mm256_storeu2_m128d :: #force_inline proc "c" (hiaddr, loaddr: ^f64, a: __m256d) {
	lo := _mm256_castpd256_pd128(a)
	_mm_storeu_pd(loaddr, lo)
	hi := _mm256_extractf128_pd(a, 1)
	_mm_storeu_pd(hiaddr, hi)
}

// Stores the high and low 128-bit halves (each composed of integer data) from
// `a` into memory two different 128-bit locations.
// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
@(enable_target_feature="sse2,avx")
_mm256_storeu2_m128i :: #force_inline proc "c" (hiaddr, loaddr: ^__m128i, a: __m256i) {
	lo := _mm256_castsi256_si128(a)
	_mm_storeu_si128(loaddr, lo)
	hi := _mm256_extractf128_si256(a, 1)
	_mm_storeu_si128(hiaddr, hi)
}

// Returns the first element of the input vector of `[8 x float]`.
@(require_results, enable_target_feature="avx")
_mm256_cvtss_f32 :: #force_inline proc "c" (a: __m256) -> f32 {
	return intrinsics.simd_extract(a, 0)
}



@(require_results, enable_target_feature="avx")
_mm256_insert_epi64 :: #force_inline proc "c" (a: __m256i, i: i64, $idx: u32) -> __m256i {
	return intrinsics.simd_replace(transmute(#simd[4]i64)a, idx, i)
}

@(require_results, enable_target_feature="avx")
_mm256_extract_epi64 :: #force_inline proc "c" (a: __m256i, $idx: u32) -> i64 {
	return intrinsics.simd_extract(transmute(#simd[4]i64)a, idx)
}


@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.avx.round.pd.256")      llvm_roundpd256    :: proc(a: __m256d, #const b: u32) -> __m256d ---
	@(link_name="llvm.x86.avx.round.ps.256")      llvm_roundps256    :: proc(a: __m256, #const b: u32) -> __m256 ---
	@(link_name="llvm.x86.avx.dp.ps.256")         llvm_vdpps         :: proc(a, b: __m256, #const imm8: u8) -> __m256 ---
	@(link_name="llvm.x86.sse2.cmp.pd")           llvm_vcmppd        :: proc(a, b: __m128d, #const imm8: u8) -> __m128d ---
	@(link_name="llvm.x86.avx.cmp.pd.256")        llvm_vcmppd256     :: proc(a, b: __m256d, imm8: u8) -> __m256d ---
	@(link_name="llvm.x86.sse.cmp.ps")            llvm_vcmpps        :: proc(a: __m128, b: __m128, #const imm8: u8) -> __m128 ---
	@(link_name="llvm.x86.avx.cmp.ps.256")        llvm_vcmpps256     :: proc(a, b: __m256, imm8: u8) -> __m256 ---
	@(link_name="llvm.x86.sse2.cmp.sd")           llvm_vcmpsd        :: proc(a, b: __m128d, #const imm8: u8) -> __m128d ---
	@(link_name="llvm.x86.sse.cmp.ss")            llvm_vcmpss        :: proc(a: __m128, b: __m128, #const imm8: u8) -> __m128 ---
	@(link_name="llvm.x86.avx.cvt.ps2dq.256")     llvm_vcvtps2dq     :: proc(a: __m256) -> #simd[8]i32 ---
	@(link_name="llvm.x86.avx.cvtt.pd2dq.256")    llvm_vcvttpd2dq    :: proc(a: __m256d) -> #simd[4]i32 ---
	@(link_name="llvm.x86.avx.cvt.pd2dq.256")     llvm_vcvtpd2dq     :: proc(a: __m256d) -> #simd[4]i32 ---
	@(link_name="llvm.x86.avx.cvtt.ps2dq.256")    llvm_vcvttps2dq    :: proc(a: __m256) -> #simd[8]i32 ---
	@(link_name="llvm.x86.avx.vzeroall")          llvm_vzeroall      :: proc() ---
	@(link_name="llvm.x86.avx.vzeroupper")        llvm_vzeroupper    :: proc() ---
	@(link_name="llvm.x86.avx.vpermilvar.ps.256") llvm_vpermilps256  :: proc(a: __m256, b: #simd[8]i32) -> __m256 ---
	@(link_name="llvm.x86.avx.vpermilvar.ps")     llvm_vpermilps     :: proc(a: __m128, b: #simd[4]i32) -> __m128 ---
	@(link_name="llvm.x86.avx.vpermilvar.pd.256") llvm_vpermilpd256  :: proc(a: __m256d, b: #simd[4]i64) -> __m256d ---
	@(link_name="llvm.x86.avx.vpermilvar.pd")     llvm_vpermilpd     :: proc(a: __m128d, b: #simd[2]i64) -> __m128d ---
	@(link_name="llvm.x86.avx.ldu.dq.256")        llvm_vlddqu        :: proc(mem_addr: rawptr) -> #simd[32]i8 ---
	@(link_name="llvm.x86.avx.rcp.ps.256")        llvm_vrcpps        :: proc(a: __m256) -> __m256 ---
	@(link_name="llvm.x86.avx.rsqrt.ps.256")      llvm_vrsqrtps      :: proc(a: __m256) -> __m256 ---
	@(link_name="llvm.x86.avx.ptestnzc.256")      llvm_ptestnzc256   :: proc(a: #simd[4]i64, b: #simd[4]i64) -> i32 ---
	@(link_name="llvm.x86.avx.vtestz.pd.256")     llvm_vtestzpd256   :: proc(a, b: __m256d) -> i32 ---
	@(link_name="llvm.x86.avx.vtestc.pd.256")     llvm_vtestcpd256   :: proc(a, b: __m256d) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.pd.256")   llvm_vtestnzcpd256 :: proc(a, b: __m256d) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.pd")       llvm_vtestnzcpd    :: proc(a, b: __m128d) -> i32 ---
	@(link_name="llvm.x86.avx.vtestz.ps.256")     llvm_vtestzps256   :: proc(a, b: __m256) -> i32 ---
	@(link_name="llvm.x86.avx.vtestc.ps.256")     llvm_vtestcps256   :: proc(a, b: __m256) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.ps.256")   llvm_vtestnzcps256 :: proc(a, b: __m256) -> i32 ---
	@(link_name="llvm.x86.avx.vtestnzc.ps")       llvm_vtestnzcps    :: proc(a: __m128, b: __m128) -> i32 ---
	@(link_name="llvm.x86.avx.min.ps.256")        llvm_vminps        :: proc(a, b: __m256) -> __m256 ---
	@(link_name="llvm.x86.avx.max.ps.256")        llvm_vmaxps        :: proc(a, b: __m256) -> __m256 ---
	@(link_name="llvm.x86.avx.min.pd.256")        llvm_vminpd        :: proc(a, b: __m256d) -> __m256d ---
	@(link_name="llvm.x86.avx.max.pd.256")        llvm_vmaxpd        :: proc(a, b: __m256d) -> __m256d ---
}
