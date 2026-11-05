#+build i386, amd64
package simd_x86

import "core:simd"

// Compute the absolute value of packed signed 8-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_abs_epi8)
@(require_results, enable_target_feature="ssse3")
_mm_abs_epi8 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i8x16)a
	c := simd.select(simd.lanes_lt(b, simd.i8x16(0)), simd.neg(b), b)
	return transmute(__m128i)c
}

// Compute the absolute value of packed signed 16-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_abs_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_abs_epi16 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i16x8)a
	c := simd.select(simd.lanes_lt(b, simd.i16x8(0)), simd.neg(b), b)
	return transmute(__m128i)c
}

// Compute the absolute value of packed signed 32-bit integers in `a`, and store the unsigned results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_abs_epi32)
@(require_results, enable_target_feature="ssse3")
_mm_abs_epi32 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	b := transmute(simd.i32x4)a
	c := simd.select(simd.lanes_lt(b, simd.i32x4(0)), simd.neg(b), b)
	return transmute(__m128i)c
}

// Shuffle packed 8-bit integers in `a` according to shuffle control mask in the corresponding 8-bit element of `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shuffle_epi8)
@(require_results, enable_target_feature="ssse3")
_mm_shuffle_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_pshufb128(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Concatenate 16-byte blocks in `a` and `b` into a 32-byte temporary result,
// shift the result right by `imm8` bytes, and store the low 16 bytes in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_alignr_epi8)
@(require_results, enable_target_feature="ssse3")
_mm_alignr_epi8 :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m128i(0)
	} else when IMM8 > 16 {
		shift :: u32(IMM8) % 16
		c, d := __m128i(0), a
		return transmute(__m128i)simd.shuffle(
			transmute(simd.i8x16)d,
			transmute(simd.i8x16)c,
			(0  + shift),
			(1  + shift),
			(2  + shift),
			(3  + shift),
			(4  + shift),
			(5  + shift),
			(6  + shift),
			(7  + shift),
			(8  + shift),
			(9  + shift),
			(10 + shift),
			(11 + shift),
			(12 + shift),
			(13 + shift),
			(14 + shift),
			(15 + shift),
		)
	} else when IMM8 == 16 {
		return a
	} else {
		shift :: u32(IMM8)
		c, d := a, b
		return transmute(__m128i)simd.shuffle(
			transmute(simd.i8x16)d,
			transmute(simd.i8x16)c,
			(0  + shift),
			(1  + shift),
			(2  + shift),
			(3  + shift),
			(4  + shift),
			(5  + shift),
			(6  + shift),
			(7  + shift),
			(8  + shift),
			(9  + shift),
			(10 + shift),
			(11 + shift),
			(12 + shift),
			(13 + shift),
			(14 + shift),
			(15 + shift),
		)
	}
}

// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`,
// and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hadd_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_hadd_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i16x8)a
	d := transmute(simd.i16x8)b
	return transmute(__m128i)simd.add(
		simd.shuffle(c, d, 0, 2, 4, 6, 8, 10, 12, 14),
		simd.shuffle(c, d, 1, 3, 5, 7, 9, 11, 13, 15),
	)
}

// Horizontally add adjacent pairs of signed 16-bit integers in `a` and `b` using saturation,
// and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hadds_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_hadds_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i16x8)a
	d := transmute(simd.i16x8)b
	return transmute(__m128i)simd.saturating_add(
		simd.shuffle(c, d, 0, 2, 4, 6, 8, 10, 12, 14),
		simd.shuffle(c, d, 1, 3, 5, 7, 9, 11, 13, 15),
	)
}

// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`,
// and pack the signed 32-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hadd_epi32)
@(require_results, enable_target_feature="ssse3")
_mm_hadd_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i32x4)a
	d := transmute(simd.i32x4)b
	return transmute(__m128i)simd.add(
		simd.shuffle(c, d, 0, 2, 4, 6),
		simd.shuffle(c, d, 1, 3, 5, 7),
	)
}

// Horizontally subtract adjacent pairs of 16-bit integers in `a` and `b`,
// and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hsub_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_hsub_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i16x8)a
	d := transmute(simd.i16x8)b
	return transmute(__m128i)simd.sub(
		simd.shuffle(c, d, 0, 2, 4, 6, 8, 10, 12, 14),
		simd.shuffle(c, d, 1, 3, 5, 7, 9, 11, 13, 15),
	)
}

// Horizontally subtract adjacent pairs of signed 16-bit integers in `a` and `b` using saturation,
// and pack the signed 16-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hsubs_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_hsubs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i16x8)a
	d := transmute(simd.i16x8)b
	return transmute(__m128i)simd.saturating_sub(
		simd.shuffle(c, d, 0, 2, 4, 6, 8, 10, 12, 14),
		simd.shuffle(c, d, 1, 3, 5, 7, 9, 11, 13, 15),
	)
}

// Horizontally subtract adjacent pairs of 32-bit integers in `a` and `b`,
// and pack the signed 32-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_hsub_epi32)
@(require_results, enable_target_feature="ssse3")
_mm_hsub_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.i32x4)a
	d := transmute(simd.i32x4)b
	return transmute(__m128i)simd.sub(
		simd.shuffle(c, d, 0, 2, 4, 6),
		simd.shuffle(c, d, 1, 3, 5, 7),
	)
}

// Vertically multiply each unsigned 8-bit integer from `a` with the corresponding signed 8-bit integer from `b`,
// producing intermediate signed 16-bit integers. Horizontally add adjacent pairs of intermediate signed 16-bit integers,
// and pack the saturated results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maddubs_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_maddubs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_pmaddubsw128(transmute(simd.u8x16)a, transmute(simd.i8x16)b)
}

// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
// Truncate each intermediate integer to the 18 most significant bits, round by adding 1, and store bits [16:1] to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mulhrs_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_mulhrs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_pmulhrsw128(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Negate packed 8-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative,
// and store the results in `dst`. Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sign_epi8)
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psignb128(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Negate packed 16-bit integers in `a` when the corresponding signed 16-bit integer in `b` is negative,
// and store the results in `dst`. Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sign_epi16)
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psignw128(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Negate packed 32-bit integers in `a` when the corresponding signed 32-bit integer in `b` is negative,
// and store the results in `dst`. Element in `dst` are zeroed out when the corresponding element in `b` is zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sign_epi32)
@(require_results, enable_target_feature="ssse3")
_mm_sign_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psignd128(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.ssse3.pshuf.b.128")     llvm_pshufb128    :: proc(a, b: simd.u8x16) -> simd.u8x16 ---
	@(link_name="llvm.x86.ssse3.pmadd.ub.sw.128") llvm_pmaddubsw128 :: proc(a: simd.u8x16, b: simd.i8x16) -> simd.i16x8 ---
	@(link_name="llvm.x86.ssse3.pmul.hr.sw.128")  llvm_pmulhrsw128  :: proc(a, b: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.ssse3.psign.b.128")     llvm_psignb128    :: proc(a, b: simd.i8x16) -> simd.i8x16 ---
	@(link_name="llvm.x86.ssse3.psign.w.128")     llvm_psignw128    :: proc(a, b: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.ssse3.psign.d.128")     llvm_psignd128    :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
}
