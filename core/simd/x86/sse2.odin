#+build i386, amd64
package simd_x86

import "base:intrinsics"
import "core:simd"

// Provide a hint to the processor that the code sequence is a spin-wait loop.
// This can help improve the performance and power consumption of spin-wait loops.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_pause)
@(enable_target_feature="sse2")
_mm_pause :: #force_inline proc "c" () {
	llvm_pause()
}

// Invalidate and flush the cache line that contains `mem_addr` from all levels of the cache hierarchy.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_clflush)
@(enable_target_feature="sse2")
_mm_clflush :: #force_inline proc "c" (mem_addr: rawptr) {
	llvm_clflush(mem_addr)
}

// Perform a serializing operation on all load-from-memory instructions that were issued prior to this instruction.
// Guarantees that every load instruction that precedes, in program order,
// is globally visible before any load instruction which follows the fence in program order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_lfence)
@(enable_target_feature="sse2")
_mm_lfence :: #force_inline proc "c" () {
	llvm_lfence()
}

// Perform a serializing operation on all load-from-memory and store-to-memory instructions
// that were issued prior to this instruction. Guarantees that every memory access that precedes,
// in program order, the memory fence instruction is globally visible before any memory instruction
// which follows the fence in program order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mfence)
@(enable_target_feature="sse2")
_mm_mfence :: #force_inline proc "c" () {
	llvm_mfence()
}

// Add packed 8-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_epi8)
@(require_results, enable_target_feature="sse2")
_mm_add_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.add(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Add packed 16-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_epi16)
@(require_results, enable_target_feature="sse2")
_mm_add_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.add(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Add packed 32-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_epi32)
@(require_results, enable_target_feature="sse2")
_mm_add_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.add(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Add packed 64-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_epi64)
@(require_results, enable_target_feature="sse2")
_mm_add_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.add(a, b)
}

// Add packed signed 8-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_adds_epi8)
@(require_results, enable_target_feature="sse2")
_mm_adds_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_add(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Add packed signed 16-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_adds_epi16)
@(require_results, enable_target_feature="sse2")
_mm_adds_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_add(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Add packed unsigned 8-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_adds_epu8)
@(require_results, enable_target_feature="sse2")
_mm_adds_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_add(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Add packed unsigned 16-bit integers in `a` and `b` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_adds_epu16)
@(require_results, enable_target_feature="sse2")
_mm_adds_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_add(transmute(simd.u16x8)a, transmute(simd.u16x8)b)
}

// Average packed unsigned 8-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_avg_epu8)
@(require_results, enable_target_feature="sse2")
_mm_avg_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := cast(simd.u16x16)(transmute(simd.u8x16)a)
	d := cast(simd.u16x16)(transmute(simd.u8x16)b)
	e := simd.shr(simd.add(simd.add(c, d), simd.u16x16(1)), simd.u16x16(1))
	return transmute(__m128i)(cast(simd.u8x16)e)
}

// Average packed unsigned 16-bit integers in `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_avg_epu16)
@(require_results, enable_target_feature="sse2")
_mm_avg_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := cast(simd.u32x8)(transmute(simd.u16x8)a)
	d := cast(simd.u32x8)(transmute(simd.u16x8)b)
	e := simd.shr(simd.add(simd.add(c, d), simd.u32x8(1)), simd.u32x8(1))
	return transmute(__m128i)(cast(simd.u16x8)e)
}

// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
// Horizontally add adjacent pairs of intermediate 32-bit integers, and pack the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_madd_epi16)
@(require_results, enable_target_feature="sse2")
_mm_madd_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_pmaddwd(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed signed 16-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epi16)
@(require_results, enable_target_feature="sse2")
_mm_max_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed unsigned 8-bit integers in `a` and `b`, and store packed maximum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_epu8)
@(require_results, enable_target_feature="sse2")
_mm_max_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.max(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Compare packed signed 16-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epi16)
@(require_results, enable_target_feature="sse2")
_mm_min_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed unsigned 8-bit integers in `a` and `b`, and store packed minimum values in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_epu8)
@(require_results, enable_target_feature="sse2")
_mm_min_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.min(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Multiply the packed signed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the high 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mulhi_epi16)
@(require_results, enable_target_feature="sse2")
_mm_mulhi_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := cast(simd.i32x8)(transmute(simd.i16x8)a)
	d := cast(simd.i32x8)(transmute(simd.i16x8)b)
	e := simd.shr(simd.mul(c, d), simd.u32x8(16))
	return transmute(__m128i)(cast(simd.i16x8)e)
}

// Multiply the packed unsigned 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the high 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mulhi_epu16)
@(require_results, enable_target_feature="sse2")
_mm_mulhi_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := cast(simd.u32x8)(transmute(simd.u16x8)a)
	d := cast(simd.u32x8)(transmute(simd.u16x8)b)
	e := simd.shr(simd.mul(c, d), simd.u32x8(16))
	return transmute(__m128i)(cast(simd.u16x8)e)
}

// Multiply the packed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers,
// and store the low 16 bits of the intermediate integers in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mullo_epi16)
@(require_results, enable_target_feature="sse2")
_mm_mullo_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.mul(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Multiply the low unsigned 32-bit integers from each packed 64-bit element in `a` and `b`,
// and store the unsigned 64-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_epu32)
@(require_results, enable_target_feature="sse2")
_mm_mul_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := transmute(simd.u64x2)a
	d := transmute(simd.u64x2)b
	m := simd.u64x2(max(u32))
	return transmute(__m128i)simd.mul(simd.bit_and(c, m), simd.bit_and(d, m))
}

// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each consecutive 8 differences
// to produce two unsigned 16-bit integers, and pack these unsigned 16-bit integers in the low 16 bits of 64-bit elements in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sad_epu8)
@(require_results, enable_target_feature="sse2")
_mm_sad_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psadbw(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_epi8)
@(require_results, enable_target_feature="sse2")
_mm_sub_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_epi16)
@(require_results, enable_target_feature="sse2")
_mm_sub_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_epi32)
@(require_results, enable_target_feature="sse2")
_mm_sub_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.sub(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Subtract packed 64-bit integers in `b` from packed 64-bit integers in `a`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_epi64)
@(require_results, enable_target_feature="sse2")
_mm_sub_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.sub(a, b)
}

// Subtract packed signed 8-bit integers in `b` from packed 8-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_subs_epi8)
@(require_results, enable_target_feature="sse2")
_mm_subs_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_sub(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Subtract packed signed 16-bit integers in `b` from packed 16-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_subs_epi16)
@(require_results, enable_target_feature="sse2")
_mm_subs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_sub(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Subtract packed unsigned 8-bit integers in `b` from packed unsigned 8-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_subs_epu8)
@(require_results, enable_target_feature="sse2")
_mm_subs_epu8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_sub(transmute(simd.u8x16)a, transmute(simd.u8x16)b)
}

// Subtract packed unsigned 16-bit integers in `b` from packed unsigned 16-bit integers in `a` using saturation, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_subs_epu16)
@(require_results, enable_target_feature="sse2")
_mm_subs_epu16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.saturating_sub(transmute(simd.u16x8)a, transmute(simd.u16x8)b)
}

// Shift `a` left by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_slli_si128)
@(require_results, enable_target_feature="sse2")
_mm_slli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8)
	return transmute(__m128i)simd.shuffle(
		simd.i8x16(0),
		transmute(simd.i8x16)a,
		0  when shift > 15 else (0  + 16 - shift),
		1  when shift > 15 else (1  + 16 - shift),
		2  when shift > 15 else (2  + 16 - shift),
		3  when shift > 15 else (3  + 16 - shift),
		4  when shift > 15 else (4  + 16 - shift),
		5  when shift > 15 else (5  + 16 - shift),
		6  when shift > 15 else (6  + 16 - shift),
		7  when shift > 15 else (7  + 16 - shift),
		8  when shift > 15 else (8  + 16 - shift),
		9  when shift > 15 else (9  + 16 - shift),
		10 when shift > 15 else (10 + 16 - shift),
		11 when shift > 15 else (11 + 16 - shift),
		12 when shift > 15 else (12 + 16 - shift),
		13 when shift > 15 else (13 + 16 - shift),
		14 when shift > 15 else (14 + 16 - shift),
		15 when shift > 15 else (15 + 16 - shift),
	)
}

// Shift `a` left by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_bslli_si128)
@(require_results, enable_target_feature="sse2")
_mm_bslli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8)
	return transmute(__m128i)simd.shuffle(
		simd.i8x16(0),
		transmute(simd.i8x16)a,
		0  when shift > 15 else (0  + 16 - shift),
		1  when shift > 15 else (1  + 16 - shift),
		2  when shift > 15 else (2  + 16 - shift),
		3  when shift > 15 else (3  + 16 - shift),
		4  when shift > 15 else (4  + 16 - shift),
		5  when shift > 15 else (5  + 16 - shift),
		6  when shift > 15 else (6  + 16 - shift),
		7  when shift > 15 else (7  + 16 - shift),
		8  when shift > 15 else (8  + 16 - shift),
		9  when shift > 15 else (9  + 16 - shift),
		10 when shift > 15 else (10 + 16 - shift),
		11 when shift > 15 else (11 + 16 - shift),
		12 when shift > 15 else (12 + 16 - shift),
		13 when shift > 15 else (13 + 16 - shift),
		14 when shift > 15 else (14 + 16 - shift),
		15 when shift > 15 else (15 + 16 - shift),
	)
}

// Shift `a` right by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srli_si128)
@(require_results, enable_target_feature="sse2")
_mm_srli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8)
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i8x16)a,
		simd.i8x16(0),
		(0  + 16) when shift > 15 else (0  + shift),
		(1  + 16) when shift > 15 else (1  + shift),
		(2  + 16) when shift > 15 else (2  + shift),
		(3  + 16) when shift > 15 else (3  + shift),
		(4  + 16) when shift > 15 else (4  + shift),
		(5  + 16) when shift > 15 else (5  + shift),
		(6  + 16) when shift > 15 else (6  + shift),
		(7  + 16) when shift > 15 else (7  + shift),
		(8  + 16) when shift > 15 else (8  + shift),
		(9  + 16) when shift > 15 else (9  + shift),
		(10 + 16) when shift > 15 else (10 + shift),
		(11 + 16) when shift > 15 else (11 + shift),
		(12 + 16) when shift > 15 else (12 + shift),
		(13 + 16) when shift > 15 else (13 + shift),
		(14 + 16) when shift > 15 else (14 + shift),
		(15 + 16) when shift > 15 else (15 + shift),
	)
}

// Shift `a` right by `imm8` bytes while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_bsrli_si128)
@(require_results, enable_target_feature="sse2")
_mm_bsrli_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	shift :: u32(IMM8)
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i8x16)a,
		simd.i8x16(0),
		(0  + 16) when shift > 15 else (0  + shift),
		(1  + 16) when shift > 15 else (1  + shift),
		(2  + 16) when shift > 15 else (2  + shift),
		(3  + 16) when shift > 15 else (3  + shift),
		(4  + 16) when shift > 15 else (4  + shift),
		(5  + 16) when shift > 15 else (5  + shift),
		(6  + 16) when shift > 15 else (6  + shift),
		(7  + 16) when shift > 15 else (7  + shift),
		(8  + 16) when shift > 15 else (8  + shift),
		(9  + 16) when shift > 15 else (9  + shift),
		(10 + 16) when shift > 15 else (10 + shift),
		(11 + 16) when shift > 15 else (11 + shift),
		(12 + 16) when shift > 15 else (12 + shift),
		(13 + 16) when shift > 15 else (13 + shift),
		(14 + 16) when shift > 15 else (14 + shift),
		(15 + 16) when shift > 15 else (15 + shift),
	)
}

// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_slli_epi16)
@(require_results, enable_target_feature="sse2")
_mm_slli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 16 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shl(transmute(simd.u16x8)a, simd.u16x8(IMM8))
	}
}

// Shift packed 16-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sll_epi16)
@(require_results, enable_target_feature="sse2")
_mm_sll_epi16 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psllw(transmute(simd.i16x8)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_slli_epi32)
@(require_results, enable_target_feature="sse2")
_mm_slli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shl(transmute(simd.u32x4)a, simd.u32x4(IMM8))
	}
}

// Shift packed 32-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sll_epi32)
@(require_results, enable_target_feature="sse2")
_mm_sll_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_pslld(transmute(simd.i32x4)a, transmute(simd.i32x4)count)
}

// Shift packed 64-bit integers in `a` left by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_slli_epi64)
@(require_results, enable_target_feature="sse2")
_mm_slli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 64 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shl(transmute(simd.u64x2)a, simd.u64x2(IMM8))
	}
}

// Shift packed 64-bit integers in `a` left by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sll_epi64)
@(require_results, enable_target_feature="sse2")
_mm_sll_epi64 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return llvm_psllq(a, count)
}

// Shift packed 16-bit integers in `a` right by `imm8` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srai_epi16)
@(require_results, enable_target_feature="sse2")
_mm_srai_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shr(transmute(simd.i16x8)a, simd.u16x8(min(IMM8, 15)))
}

// Shift packed 16-bit integers in `a` right by `count` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sra_epi16)
@(require_results, enable_target_feature="sse2")
_mm_sra_epi16 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psraw(transmute(simd.i16x8)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` right by `imm8` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srai_epi32)
@(require_results, enable_target_feature="sse2")
_mm_srai_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shr(transmute(simd.i32x4)a, simd.u32x4(min(IMM8, 31)))
}

// Shift packed 32-bit integers in `a` right by `count` while shifting in sign bits, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sra_epi32)
@(require_results, enable_target_feature="sse2")
_mm_sra_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psrad(transmute(simd.i32x4)a, transmute(simd.i32x4)count)
}

// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srli_epi16)
@(require_results, enable_target_feature="sse2")
_mm_srli_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 16 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shr(transmute(simd.u16x8)a, simd.u16x8(IMM8))
	}
}

// Shift packed 16-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srl_epi16)
@(require_results, enable_target_feature="sse2")
_mm_srl_epi16 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psrlw(transmute(simd.i16x8)a, transmute(simd.i16x8)count)
}

// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srli_epi32)
@(require_results, enable_target_feature="sse2")
_mm_srli_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 32 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shr(transmute(simd.u32x4)a, simd.u32x4(IMM8))
	}
}

// Shift packed 32-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srl_epi32)
@(require_results, enable_target_feature="sse2")
_mm_srl_epi32 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return transmute(__m128i)llvm_psrld(transmute(simd.i32x4)a, transmute(simd.i32x4)count)
}

// Shift packed 64-bit integers in `a` right by `imm8` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srli_epi64)
@(require_results, enable_target_feature="sse2")
_mm_srli_epi64 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	when IMM8 >= 64 {
		return __m128i(0)
	} else {
		return transmute(__m128i)simd.shr(transmute(simd.u64x2)a, simd.u64x2(IMM8))
	}
}

// Shift packed 64-bit integers in `a` right by `count` while shifting in zeros, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_srl_epi64)
@(require_results, enable_target_feature="sse2")
_mm_srl_epi64 :: #force_inline proc "c" (a: __m128i, count: __m128i) -> __m128i {
	return llvm_psrlq(a, count)
}

// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_and_si128)
@(require_results, enable_target_feature="sse2")
_mm_and_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_and(a, b)
}

// Compute the bitwise NOT of 128 bits (representing integer data) in `a` and then AND with `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_andnot_si128)
@(require_results, enable_target_feature="sse2")
_mm_andnot_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	c := __m128i(-1)
	return simd.bit_and(simd.bit_xor(a, c), b)
}

// Compute the bitwise OR of 128 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_or_si128)
@(require_results, enable_target_feature="sse2")
_mm_or_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_or(a, b)
}

// Compute the bitwise XOR of 128 bits (representing integer data) in `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_xor_si128)
@(require_results, enable_target_feature="sse2")
_mm_xor_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.bit_xor(a, b)
}

// Compare packed 8-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_epi8)
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compare packed 16-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_epi16)
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed 32-bit integers in `a` and `b` for equality, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_eq(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compare packed signed 8-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_epi8)
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compare packed signed 16-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_epi16)
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed signed 32-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Compare packed signed 8-bit integers in `a` and `b` for less-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_epi8)
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compare packed signed 16-bit integers in `a` and `b` for less-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_epi16)
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Compare packed signed 32-bit integers in `a` and `b` for less-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cmplt_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_lt(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Convert packed signed 32-bit integers in `a` to packed double-precision (64-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi32_pd)
@(require_results, enable_target_feature="sse2")
_mm_cvtepi32_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	b := transmute(simd.i32x4)a
	return cast(__m128d)simd.shuffle(b, b, 0, 1)
}

// Convert the signed 32-bit integer `b` to a double-precision (64-bit) floating-point element,
// store the result in the lower element of `dst`, and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi32_sd)
@(require_results, enable_target_feature="sse2")
_mm_cvtsi32_sd :: #force_inline proc "c" (a: __m128d, b: i32) -> __m128d {
	return simd.replace(a, 0, f64(b))
}

// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtepi32_ps)
@(require_results, enable_target_feature="sse2")
_mm_cvtepi32_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return cast(__m128)(transmute(simd.i32x4)a)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtps_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cvtps_epi32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)llvm_cvtps2dq(a)
}

// Copy 32-bit integer `a` to the lower elements of `dst`, and zero the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi32_si128)
@(require_results, enable_target_feature="sse2")
_mm_cvtsi32_si128 :: #force_inline proc "c" (a: i32) -> __m128i {
	return transmute(__m128i)(simd.i32x4 {a, 0, 0, 0})
}

// Copy the lower 32-bit integer in `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi128_si32)
@(require_results, enable_target_feature="sse2")
_mm_cvtsi128_si32 :: #force_inline proc "c" (a: __m128i) -> i32 {
	return simd.extract(transmute(simd.i32x4)a, 0)
}

// Set packed 64-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_epi64x)
@(require_results, enable_target_feature="sse2")
_mm_set_epi64x :: #force_inline proc "c" (e1, e0: i64) -> __m128i {
	return __m128i {e0, e1}
}

// Set packed 32-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_epi32)
@(require_results, enable_target_feature="sse2")
_mm_set_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m128i {
	return transmute(__m128i)(simd.i32x4 {e0, e1, e2, e3})
}

// Set packed 16-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_epi16)
@(require_results, enable_target_feature="sse2")
_mm_set_epi16 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i16) -> __m128i {
	return transmute(__m128i)(simd.i16x8 {e0, e1, e2, e3, e4, e5, e6, e7})
}

// Set packed 8-bit integers in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_epi8)
@(require_results, enable_target_feature="sse2")
_mm_set_epi8 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i8,
	e07, e06, e05, e04, e03, e02, e01, e00: i8,
) -> __m128i {
	return transmute(__m128i)(simd.i8x16 {
		e00, e01, e02, e03, e04, e05, e06, e07,
		e08, e09, e10, e11, e12, e13, e14, e15,
	})
}

// Broadcast 64-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_epi64x)
@(require_results, enable_target_feature="sse2")
_mm_set1_epi64x :: #force_inline proc "c" (a: i64) -> __m128i {
	return __m128i(a)
}

// Broadcast 32-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_epi32)
@(require_results, enable_target_feature="sse2")
_mm_set1_epi32 :: #force_inline proc "c" (a: i32) -> __m128i {
	return transmute(__m128i)simd.i32x4(a)
}

// Broadcast 16-bit integer `a` to all all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_epi16)
@(require_results, enable_target_feature="sse2")
_mm_set1_epi16 :: #force_inline proc "c" (a: i16) -> __m128i {
	return transmute(__m128i)simd.i16x8(a)
}

// Broadcast 8-bit integer `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_epi8)
@(require_results, enable_target_feature="sse2")
_mm_set1_epi8 :: #force_inline proc "c" (a: i8) -> __m128i {
	return transmute(__m128i)simd.i8x16(a)
}

// Set packed 32-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setr_epi32)
@(require_results, enable_target_feature="sse2")
_mm_setr_epi32 :: #force_inline proc "c" (e3, e2, e1, e0: i32) -> __m128i {
	return transmute(__m128i)(simd.i32x4 {e3, e2, e1, e0})
}

// Set packed 16-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setr_epi16)
@(require_results, enable_target_feature="sse2")
_mm_setr_epi16 :: #force_inline proc "c" (e7, e6, e5, e4, e3, e2, e1, e0: i16) -> __m128i {
	return transmute(__m128i)(simd.i16x8 {e7, e6, e5, e4, e3, e2, e1, e0})
}

// Set packed 8-bit integers in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setr_epi8)
@(require_results, enable_target_feature="sse2")
_mm_setr_epi8 :: #force_inline proc "c" (
	e15, e14, e13, e12, e11, e10, e09, e08: i8,
	e07, e06, e05, e04, e03, e02, e01, e00: i8,
) -> __m128i {
	return transmute(__m128i)(simd.i8x16 {
		e15, e14, e13, e12, e11, e10, e09, e08,
		e07, e06, e05, e04, e03, e02, e01, e00,
	})
}

// Return vector of type `__m128i` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setzero_si128)
@(require_results, enable_target_feature="sse2")
_mm_setzero_si128 :: #force_inline proc "c" () -> __m128i {
	return __m128i(0)
}

// Load 64-bit integer from memory into the first element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadl_epi64)
@(require_results, enable_target_feature="sse2")
_mm_loadl_epi64 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	a := intrinsics.unaligned_load((^i64)(mem_addr))
	return __m128i {a, 0}
}

// Load 128-bits of integer data from memory into `dst`. `mem_addr` must be aligned on a 16-byte boundary
// or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_si128)
@(require_results, enable_target_feature="sse2")
_mm_load_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	return mem_addr^
}

// Load 128-bits of integer data from memory into `dst`. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_si128)
@(require_results, enable_target_feature="sse2")
_mm_loadu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i) -> __m128i {
	dst := _mm_undefined_si128()
	intrinsics.mem_copy_non_overlapping(&dst, mem_addr, size_of(__m128i))
	return dst
}

// Conditionally store 8-bit integer elements from `a` into memory using `mask`
// (elements are not stored when the highest bit is not set in the corresponding element)
// and a non-temporal memory hint. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_maskmoveu_si128)
@(enable_target_feature="sse2")
_mm_maskmoveu_si128 :: #force_inline proc "c" (a: __m128i, mask: __m128i, mem_addr: rawptr) {
	llvm_maskmovdqu(transmute(simd.i8x16)a, transmute(simd.i8x16)mask, mem_addr)
}

// Store 128-bits of integer data from `a` into memory. `mem_addr` must be aligned on a 16-byte boundary
// or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_si128)
@(enable_target_feature="sse2")
_mm_store_si128 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	mem_addr^ = a
}

// Store 128-bits of integer data from `a` into memory. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_si128)
@(enable_target_feature="sse2")
_mm_storeu_si128 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	intrinsics.unaligned_store(mem_addr, a)
}

// Store 64-bit integer from the first element of `a` into memory.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storel_epi64)
@(enable_target_feature="sse2")
_mm_storel_epi64 :: #force_inline proc "c" (mem_addr: ^__m128i, a: __m128i) {
	b := a
	intrinsics.mem_copy_non_overlapping(mem_addr, &b, size_of(i64))
}

// Copy the lower 64-bit integer in `a` to the lower element of `dst`, and zero the upper element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_move_epi64)
@(require_results, enable_target_feature="sse2")
_mm_move_epi64 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return simd.shuffle(a, __m128i(0), 0, 2)
}

// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_packs_epi16)
@(require_results, enable_target_feature="sse2")
_mm_packs_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_packsswb(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using signed saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_packs_epi32)
@(require_results, enable_target_feature="sse2")
_mm_packs_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_packssdw(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using unsigned saturation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_packus_epi16)
@(require_results, enable_target_feature="sse2")
_mm_packus_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_packuswb(transmute(simd.i16x8)a, transmute(simd.i16x8)b)
}

// Extract a 16-bit integer from `a`, selected with `imm8`, and store the result in the lower element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_extract_epi16)
@(require_results, enable_target_feature="sse2")
_mm_extract_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 8 {
	return i32(simd.extract(transmute(simd.u16x8)a, IMM8))
}

// Copy `a` to `dst`, and insert the 16-bit integer `i` into `dst` at the location specified by `imm8`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_insert_epi16)
@(require_results, enable_target_feature="sse2")
_mm_insert_epi16 :: #force_inline proc "c" (a: __m128i, i: i32, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 8 {
	return transmute(__m128i)simd.replace(transmute(simd.i16x8)a, IMM8, i16(i))
}

// Create mask from the most significant bit of each 8-bit element in `a`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movemask_epi8)
@(require_results, enable_target_feature="sse2")
_mm_movemask_epi8 :: #force_inline proc "c" (a: __m128i) -> i32 {
	mask := simd.lanes_lt(transmute(simd.i8x16)a, simd.i8x16(0))
	return i32(transmute(u16)simd.extract_lsbs(mask))
}

// Shuffle 32-bit integers in `a` using the control in `imm8`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shuffle_epi32)
@(require_results, enable_target_feature="sse2")
_mm_shuffle_epi32 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)a,
		(u32(IMM8) & 0b11),
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
	)
}

// Shuffle 16-bit integers in the high 64 bits of `a` using the control in `imm8`.
// Store the results in the high 64 bits of `dst`, with the low 64 bits being copied from from `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shufflehi_epi16)
@(require_results, enable_target_feature="sse2")
_mm_shufflehi_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)a,
		0,
		1,
		2,
		3,
		((u32(IMM8) & 0b11) + 4),
		((u32(IMM8) >> 2) & 0b11) + 4,
		((u32(IMM8) >> 4) & 0b11) + 4,
		((u32(IMM8) >> 6) & 0b11) + 4,
	)
}

// Shuffle 16-bit integers in the low 64 bits of `a` using the control in `imm8`.
// Store the results in the low 64 bits of `dst`, with the high 64 bits being copied from from `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shufflelo_epi16)
@(require_results, enable_target_feature="sse2")
_mm_shufflelo_epi16 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)a,
		(u32(IMM8) & 0b11),
		(u32(IMM8) >> 2) & 0b11,
		(u32(IMM8) >> 4) & 0b11,
		(u32(IMM8) >> 6) & 0b11,
		4,
		5,
		6,
		7,
	)
}

// Unpack and interleave 8-bit integers from the high half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_epi8)
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		 8, 24,  9, 25, 10, 26, 11, 27,
		12, 28, 13, 29, 14, 30, 15, 31,
	)
}

// Unpack and interleave 16-bit integers from the high half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_epi16)
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)b,
		4, 12, 5, 13, 6, 14, 7, 15,
	)
}

// Unpack and interleave 32-bit integers from the high half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_epi32)
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		2, 6, 3, 7,
	)
}

// Unpack and interleave 64-bit integers from the high half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_epi64)
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.shuffle(a, b, 1, 3)
}

// Unpack and interleave 8-bit integers from the low half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_epi8)
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		0, 16, 1, 17, 2, 18, 3, 19,
		4, 20, 5, 21, 6, 22, 7, 23,
	)
}

// Unpack and interleave 16-bit integers from the low half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_epi16)
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi16 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i16x8)a,
		transmute(simd.i16x8)b,
		0, 8, 1, 9, 2, 10, 3, 11,
	)
}

// Unpack and interleave 32-bit integers from the low half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_epi32)
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.shuffle(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		0, 4, 1, 5,
	)
}

// Unpack and interleave 64-bit integers from the low half of `a` and `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_epi64)
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return simd.shuffle(a, b, 0, 2)
}

// Add the lower double-precision (64-bit) floating-point element in `a` and `b`,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_sd)
@(require_results, enable_target_feature="sse2")
_mm_add_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, simd.extract(a, 0) + simd.extract(b, 0))
}

// Add packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_add_pd)
@(require_results, enable_target_feature="sse2")
_mm_add_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.add(a, b)
}

// Divide the lower double-precision (64-bit) floating-point element in `a`
// by the lower double-precision (64-bit) floating-point element in `b`,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_div_sd)
@(require_results, enable_target_feature="sse2")
_mm_div_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, simd.extract(a, 0) / simd.extract(b, 0))
}

// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_div_pd)
@(require_results, enable_target_feature="sse2")
_mm_div_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.div(a, b)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// store the maximum value in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`. `dst` does not follow the IEEE Standard for
// Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_sd)
@(require_results, enable_target_feature="sse2")
_mm_max_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_maxsd(a, b)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed maximum values in `dst`. `dst` does not follow the IEEE Standard for
// Floating-Point Arithmetic (IEEE 754) maximum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_max_pd)
@(require_results, enable_target_feature="sse2")
_mm_max_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_maxpd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b`,
// store the minimum value in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`. `dst` does not follow the IEEE Standard for
// Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_sd)
@(require_results, enable_target_feature="sse2")
_mm_min_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_minsd(a, b)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store packed minimum values in `dst`. `dst` does not follow the IEEE Standard for
// Floating-Point Arithmetic (IEEE 754) minimum value when inputs are NaN or signed-zero values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_min_pd)
@(require_results, enable_target_feature="sse2")
_mm_min_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_minpd(a, b)
}

// Multiply the lower double-precision (64-bit) floating-point element in `a` and `b`,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_sd)
@(require_results, enable_target_feature="sse2")
_mm_mul_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, simd.extract(a, 0) * simd.extract(b, 0))
}

// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_mul_pd)
@(require_results, enable_target_feature="sse2")
_mm_mul_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.mul(a, b)
}

// Compute the square root of the lower double-precision (64-bit) floating-point element in `b`,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sqrt_sd)
@(require_results, enable_target_feature="sse2")
_mm_sqrt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, simd.sqrt(simd.extract(b, 0)))
}

// Compute the square root of packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sqrt_pd)
@(require_results, enable_target_feature="sse2")
_mm_sqrt_pd :: #force_inline proc "c" (a: __m128d) -> __m128d {
	return simd.sqrt(a)
}

// Subtract the lower double-precision (64-bit) floating-point element in `b`
// from the lower double-precision (64-bit) floating-point element in `a`,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_sd)
@(require_results, enable_target_feature="sse2")
_mm_sub_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(a, 0, simd.extract(a, 0) - simd.extract(b, 0))
}

// Subtract packed double-precision (64-bit) floating-point elements in `b`
// from packed double-precision (64-bit) floating-point elements in `a`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sub_pd)
@(require_results, enable_target_feature="sse2")
_mm_sub_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.sub(a, b)
}

// Compute the bitwise AND of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_and_pd)
@(require_results, enable_target_feature="sse2")
_mm_and_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)simd.bit_and(transmute(__m128i)a, transmute(__m128i)b)
}

// Compute the bitwise NOT of packed double-precision (64-bit) floating-point elements in `a` and then AND with `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_andnot_pd)
@(require_results, enable_target_feature="sse2")
_mm_andnot_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	c := __m128i(-1)
	return transmute(__m128d)simd.bit_and(simd.bit_xor(c, transmute(__m128i)a), transmute(__m128i)b)
}

// Compute the bitwise OR of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_or_pd)
@(require_results, enable_target_feature="sse2")
_mm_or_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)simd.bit_or(transmute(__m128i)a, transmute(__m128i)b)
}

// Compute the bitwise XOR of packed double-precision (64-bit) floating-point elements in `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_xor_pd)
@(require_results, enable_target_feature="sse2")
_mm_xor_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return transmute(__m128d)simd.bit_xor(transmute(__m128i)a, transmute(__m128i)b)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for equality,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 0)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for less-than,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmplt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 1)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for less-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmple_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmple_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 2)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for greater-than,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(llvm_cmpsd(b, a, 1), 1, simd.extract(a, 1))
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for greater-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpge_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpge_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(llvm_cmpsd(b, a, 2), 1, simd.extract(a, 1))
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` to see if neither is NaN,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpord_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpord_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 7)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` to see if either is NaN,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpunord_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpunord_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 3)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for not-equal,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpneq_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpneq_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 4)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for not-less-than,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnlt_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnlt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 5)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for not-less-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnle_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnle_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmpsd(a, b, 6)
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for not-greater-than,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpngt_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpngt_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(llvm_cmpsd(b, a, 5), 1, simd.extract(a, 1))
}

// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal,
// store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnge_sd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnge_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.replace(llvm_cmpsd(b, a, 6), 1, simd.extract(a, 1))
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for equality,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpeq_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpeq_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 0)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for less-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmplt_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmplt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 1)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for less-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmple_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmple_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 2)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for greater-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpgt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(b, a, 1)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for greater-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpge_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpge_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(b, a, 2)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` to see if neither is NaN,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpord_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpord_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 7)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` to see if either is NaN,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpunord_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpunord_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 3)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for not-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpneq_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpneq_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 4)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for not-less-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnlt_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnlt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 5)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for not-less-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnle_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnle_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(a, b, 6)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for not-greater-than,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpngt_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpngt_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(b, a, 5)
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpnge_pd)
@(require_results, enable_target_feature="sse2")
_mm_cmpnge_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return llvm_cmppd(b, a, 6)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for equality,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comieq_sd)
@(require_results, enable_target_feature="sse2")
_mm_comieq_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comieqsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for less-than,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comilt_sd)
@(require_results, enable_target_feature="sse2")
_mm_comilt_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comiltsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for less-than-or-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comile_sd)
@(require_results, enable_target_feature="sse2")
_mm_comile_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comilesd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for greater-than,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comigt_sd)
@(require_results, enable_target_feature="sse2")
_mm_comigt_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comigtsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for greater-than-or-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comige_sd)
@(require_results, enable_target_feature="sse2")
_mm_comige_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comigesd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for not-equal,
// and return the boolean result (0 or 1).
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_comineq_sd)
@(require_results, enable_target_feature="sse2")
_mm_comineq_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_comineqsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for equality,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomieq_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomieq_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomieqsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for less-than,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomilt_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomilt_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomiltsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for less-than-or-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomile_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomile_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomilesd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for greater-than,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomigt_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomigt_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomigtsd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for greater-than-or-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomige_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomige_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomigesd(a, b)
}

// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` for not-equal,
// and return the boolean result (0 or 1). This instruction will not signal an exception for QNaNs.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_ucomineq_sd)
@(require_results, enable_target_feature="sse2")
_mm_ucomineq_sd :: #force_inline proc "c" (a, b: __m128d) -> b32 {
	return llvm_ucomineqsd(a, b)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed single-precision (32-bit)
// floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtpd_ps)
@(require_results, enable_target_feature="sse2")
_mm_cvtpd_ps :: #force_inline proc "c" (a: __m128d) -> __m128 {
	return simd.shuffle(cast(simd.f32x2)a, simd.f32x2(0), 0, 1, 2, 3)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed double-precision (64-bit)
// floating-point elements, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtps_pd)
@(require_results, enable_target_feature="sse2")
_mm_cvtps_pd :: #force_inline proc "c" (a: __m128) -> __m128d {
	return cast(__m128d)simd.shuffle(a, a, 0, 1)
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtpd_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cvtpd_epi32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_cvtpd2dq(a)
}

// Convert the lower double-precision (64-bit) floating-point element in `a` to a 32-bit integer,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_si32)
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_si32 :: #force_inline proc "c" (a: __m128d) -> i32 {
	return llvm_cvtsd2si(a)
}

// Convert the lower double-precision (64-bit) floating-point element in `b` to a single-precision (32-bit)
// floating-point element, store the result in the lower element of `dst`, and copy the upper 3 packed elements
// from `a` to the upper elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_ss)
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_ss :: #force_inline proc "c" (a: __m128, b: __m128d) -> __m128 {
	return llvm_cvtsd2ss(a, b)
}

// Copy the lower double-precision (64-bit) floating-point element of `a` to `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_f64)
@(require_results, enable_target_feature="sse2")
_mm_cvtsd_f64 :: #force_inline proc "c" (a: __m128d) -> f64 {
	return simd.extract(a, 0)
}

// Convert the lower single-precision (32-bit) floating-point element in `b` to a double-precision (64-bit)
// floating-point element, store the result in the lower element of `dst`, and copy the upper element
// from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtss_sd)
@(require_results, enable_target_feature="sse2")
_mm_cvtss_sd :: #force_inline proc "c" (a: __m128d, b: __m128) -> __m128d {
	return simd.replace(a, 0, f64(simd.extract(b, 0)))
}

// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers with truncation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttpd_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cvttpd_epi32 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)llvm_cvttpd2dq(a)
}

// Convert the lower double-precision (64-bit) floating-point element in `a` to a 32-bit integer with truncation,
// and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttsd_si32)
@(require_results, enable_target_feature="sse2")
_mm_cvttsd_si32 :: #force_inline proc "c" (a: __m128d) -> i32 {
	return llvm_cvttsd2si(a)
}

// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers with truncation,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttps_epi32)
@(require_results, enable_target_feature="sse2")
_mm_cvttps_epi32 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)llvm_cvttps2dq(a)
}

// Copy double-precision (64-bit) floating-point element `a` to the lower element of `dst`,
// and zero the upper element.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_sd)
@(require_results, enable_target_feature="sse2")
_mm_set_sd :: #force_inline proc "c" (a: f64) -> __m128d {
	return __m128d {a, 0}
}

// Broadcast double-precision (64-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set1_pd)
@(require_results, enable_target_feature="sse2")
_mm_set1_pd :: #force_inline proc "c" (a: f64) -> __m128d {
	return __m128d(a)
}

// Broadcast double-precision (64-bit) floating-point value `a` to all elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_pd1)
@(require_results, enable_target_feature="sse2")
_mm_set_pd1 :: #force_inline proc "c" (a: f64) -> __m128d {
	return __m128d(a)
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_set_pd)
@(require_results, enable_target_feature="sse2")
_mm_set_pd :: #force_inline proc "c" (e1, e0: f64) -> __m128d {
	return __m128d {e0, e1}
}

// Set packed double-precision (64-bit) floating-point elements in `dst` with the supplied values in reverse order.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setr_pd)
@(require_results, enable_target_feature="sse2")
_mm_setr_pd :: #force_inline proc "c" (e1, e0: f64) -> __m128d {
	return __m128d {e1, e0}
}

// Return vector of type `__m128d` with all elements set to zero.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_setzero_pd)
@(require_results, enable_target_feature="sse2")
_mm_setzero_pd :: #force_inline proc "c" () -> __m128d {
	return __m128d(0)
}

// Set each bit of mask `dst` based on the most significant bit of the corresponding
// packed double-precision (64-bit) floating-point element in `a`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_movemask_pd)
@(require_results, enable_target_feature="sse2")
_mm_movemask_pd :: #force_inline proc "c" (a: __m128d) -> i32 {
	mask := simd.lanes_lt(transmute(simd.i64x2)a, simd.i64x2(0))
	return i32(transmute(u8)simd.extract_lsbs(mask))
}

// Load 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from memory into `dst`.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_pd)
@(require_results, enable_target_feature="sse2")
_mm_load_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return (^__m128d)(mem_addr)^
}

// Load a double-precision (64-bit) floating-point element from memory into the lower of `dst`,
// and zero the upper element. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_sd)
@(require_results, enable_target_feature="sse2")
_mm_load_sd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return __m128d {mem_addr^, 0}
}

// Load a double-precision (64-bit) floating-point element from memory into the upper element of `dst`,
// and copy the lower element from `a` to `dst`. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadh_pd)
@(require_results, enable_target_feature="sse2")
_mm_loadh_pd :: #force_inline proc "c" (a: __m128d, mem_addr: ^f64) -> __m128d {
	return __m128d {simd.extract(a, 0), mem_addr^}
}

// Load a double-precision (64-bit) floating-point element from memory into the lower element of `dst`,
// and copy the upper element from `a` to `dst`. `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadl_pd)
@(require_results, enable_target_feature="sse2")
_mm_loadl_pd :: #force_inline proc "c" (a: __m128d, mem_addr: ^f64) -> __m128d {
	return __m128d {mem_addr^, simd.extract(a, 1)}
}

// Store the lower double-precision (64-bit) floating-point element from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_sd)
@(enable_target_feature="sse2")
_mm_store_sd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 0)
}

// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_pd)
@(enable_target_feature="sse2")
_mm_store_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	(^__m128d)(mem_addr)^ = a
}

// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_pd)
@(enable_target_feature="sse2")
_mm_storeu_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	intrinsics.unaligned_store((^__m128d)(mem_addr), a)
}

// Store 16-bit integer from the first element of `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_si16)
@(enable_target_feature="sse2")
_mm_storeu_si16:: #force_inline proc "c" (mem_addr: rawptr, a: __m128i) {
	intrinsics.unaligned_store((^i16)(mem_addr), simd.extract(transmute(simd.i16x8)a, 0))
}

// Store 32-bit integer from the first element of `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_si32)
@(enable_target_feature="sse2")
_mm_storeu_si32:: #force_inline proc "c" (mem_addr: rawptr, a: __m128i) {
	intrinsics.unaligned_store((^i32)(mem_addr), simd.extract(transmute(simd.i32x4)a, 0))
}

// Store 64-bit integer from the first element of `a` into memory.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeu_si64)
@(enable_target_feature="sse2")
_mm_storeu_si64:: #force_inline proc "c" (mem_addr: rawptr, a: __m128i) {
	intrinsics.unaligned_store((^i64)(mem_addr), simd.extract(a, 0))
}

// Store the lower double-precision (64-bit) floating-point element from `a` into 2 contiguous elements in memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store1_pd)
@(enable_target_feature="sse2")
_mm_store1_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	b := simd.shuffle(a, a, 0, 0)
	(^__m128d)(mem_addr)^ = b
}

// Store the lower double-precision (64-bit) floating-point element from `a` into 2 contiguous elements in memory.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_store_pd1)
@(enable_target_feature="sse2")
_mm_store_pd1 :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	b := simd.shuffle(a, a, 0, 0)
	(^__m128d)(mem_addr)^ = b
}

// Store 2 double-precision (64-bit) floating-point elements from `a` into memory in reverse order.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storer_pd)
@(enable_target_feature="sse2")
_mm_storer_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	b := simd.shuffle(a, a, 1, 0)
	(^__m128d)(mem_addr)^ = b
}

// Store the upper double-precision (64-bit) floating-point element from `a` into memory.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storeh_pd)
@(enable_target_feature="sse2")
_mm_storeh_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 1)
}

// Store the lower double-precision (64-bit) floating-point element from `a` into memory.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_storel_pd)
@(enable_target_feature="sse2")
_mm_storel_pd :: #force_inline proc "c" (mem_addr: ^f64, a: __m128d) {
	mem_addr^ = simd.extract(a, 0)
}

// Load a double-precision (64-bit) floating-point element from memory into both elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load1_pd)
@(require_results, enable_target_feature="sse2")
_mm_load1_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return __m128d(mem_addr^)
}

// Load a double-precision (64-bit) floating-point element from memory into both elements of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_load_pd1)
@(require_results, enable_target_feature="sse2")
_mm_load_pd1 :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	return __m128d(mem_addr^)
}

// Load 2 double-precision (64-bit) floating-point elements from memory into `dst` in reverse order.
// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadr_pd)
@(require_results, enable_target_feature="sse2")
_mm_loadr_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	a := (^__m128d)(mem_addr)^
	return simd.shuffle(a, a, 1, 0)
}

// Load 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from memory into `dst`.
// `mem_addr` does not need to be aligned on any particular boundary.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_pd)
@(require_results, enable_target_feature="sse2")
_mm_loadu_pd :: #force_inline proc "c" (mem_addr: ^f64) -> __m128d {
	dst := _mm_undefined_pd()
	intrinsics.mem_copy_non_overlapping(&dst, mem_addr, size_of(__m128d))
	return dst
}

// Load unaligned 16-bit integer from memory into the first element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_si16)
@(require_results, enable_target_feature="sse2")
_mm_loadu_si16 :: #force_inline proc "c" (mem_addr: rawptr) -> __m128i {
	a := intrinsics.unaligned_load((^i16)(mem_addr))
	return transmute(__m128i)(simd.i16x8 {a, 0, 0, 0, 0, 0, 0, 0})
}

// Load unaligned 32-bit integer from memory into the first element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_si32)
@(require_results, enable_target_feature="sse2")
_mm_loadu_si32 :: #force_inline proc "c" (mem_addr: rawptr) -> __m128i {
	a := intrinsics.unaligned_load((^i32)(mem_addr))
	return transmute(__m128i)(simd.i32x4 {a, 0, 0, 0})
}

// Load unaligned 64-bit integer from memory into the first element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_loadu_si64)
@(require_results, enable_target_feature="sse2")
_mm_loadu_si64 :: #force_inline proc "c" (mem_addr: rawptr) -> __m128i {
	a := intrinsics.unaligned_load((^i64)(mem_addr))
	return __m128i {a, 0}
}

// Shuffle double-precision (64-bit) floating-point elements using the control in `imm8`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_shuffle_pd)
@(require_results, enable_target_feature="sse2")
_mm_shuffle_pd :: #force_inline proc "c" (a, b: __m128d, $IMM8: i32) -> __m128d where 0 <= IMM8, IMM8 < 256 {
	return simd.shuffle(
		a,
		b,
		(u32(IMM8) & 0b1),
		((u32(IMM8) >> 1) & 0b1) + 2,
	)
}

// Move the lower double-precision (64-bit) floating-point element from `b` to the lower element of `dst`,
// and copy the upper element from `a` to the upper element of `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_move_sd)
@(require_results, enable_target_feature="sse2")
_mm_move_sd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return __m128d {simd.extract(b, 0), simd.extract(a, 1)}
}

// Cast vector of type `__m128d` to type `__m128`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castpd_ps)
@(require_results, enable_target_feature="sse2")
_mm_castpd_ps :: #force_inline proc "c" (a: __m128d) -> __m128 {
	return transmute(__m128)a
}

// Cast vector of type `__m128d` to type `__m128i`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castpd_si128)
@(require_results, enable_target_feature="sse2")
_mm_castpd_si128 :: #force_inline proc "c" (a: __m128d) -> __m128i {
	return transmute(__m128i)a
}

// Cast vector of type `__m128` to type `__m128d`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castps_pd)
@(require_results, enable_target_feature="sse2")
_mm_castps_pd :: #force_inline proc "c" (a: __m128) -> __m128d {
	return transmute(__m128d)a
}

// Cast vector of type `__m128` to type `__m128i`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castps_si128)
@(require_results, enable_target_feature="sse2")
_mm_castps_si128 :: #force_inline proc "c" (a: __m128) -> __m128i {
	return transmute(__m128i)a
}

// Cast vector of type `__m128i` to type `__m128d`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castsi128_pd)
@(require_results, enable_target_feature="sse2")
_mm_castsi128_pd :: #force_inline proc "c" (a: __m128i) -> __m128d {
	return transmute(__m128d)a
}

// Cast vector of type `__m128i` to type `__m128`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_castsi128_ps)
@(require_results, enable_target_feature="sse2")
_mm_castsi128_ps :: #force_inline proc "c" (a: __m128i) -> __m128 {
	return transmute(__m128)a
}

// Return vector of type `__m128d` with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_undefined_pd)
@(require_results, enable_target_feature="sse2")
_mm_undefined_pd :: #force_inline proc "c" () -> __m128d {
	return __m128d(0)
}

// Return vector of type `__m128i` with undefined elements.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_undefined_si128)
@(require_results, enable_target_feature="sse2")
_mm_undefined_si128 :: #force_inline proc "c" () -> __m128i {
	return __m128i(0)
}

// Unpack and interleave double-precision (64-bit) floating-point elements from the high half of `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpackhi_pd)
@(require_results, enable_target_feature="sse2")
_mm_unpackhi_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 1, 3)
}

// Unpack and interleave double-precision (64-bit) floating-point elements from the low half of `a` and `b`,
// and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_unpacklo_pd)
@(require_results, enable_target_feature="sse2")
_mm_unpacklo_pd :: #force_inline proc "c" (a, b: __m128d) -> __m128d {
	return simd.shuffle(a, b, 0, 2)
}

when ODIN_ARCH == .amd64 {
	// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements)
	// from `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 16-byte boundary
	// or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_pd)
	// @(enable_target_feature="sse2")
	// _mm_stream_pd :: asm (mem_addr: ^f64, a: __m128d) {
	// 	movntpd [mem_addr], a
	// }

	// Store 128-bits of integer data from `a` into memory using a non-temporal memory hint.
	// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_si128)
	// @(enable_target_feature="sse2")
	// _mm_stream_si128 :: asm (mem_addr: ^__m128i, a: __m128i) {
	// 	movntdq [mem_addr], a
	// }

	// Store 32-bit integer `a` into memory using a non-temporal hint to minimize cache pollution.
	// If the cache line containing address `mem_addr` is already in the cache, the cache will be updated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_si32)
	// @(enable_target_feature="sse2")
	// _mm_stream_si32 :: asm (mem_addr: ^i32, a: i32) {
	// 	movnti [mem_addr], a
	// }

	// Store 64-bit integer `a` into memory using a non-temporal hint to minimize cache pollution.
	// If the cache line containing address `mem_addr` is already in the cache, the cache will be updated.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_stream_si64)
	// @(enable_target_feature="sse2")
	// _mm_stream_si64 :: asm (mem_addr: ^i64, a: i64) {
	// 	movnti [mem_addr], a
	// }

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_si64)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsd_si64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_cvtsd2si64(a)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsd_si64x)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsd_si64x :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_cvtsd2si64(a)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttsd_si64)
	@(require_results, enable_target_feature="sse2")
	_mm_cvttsd_si64 :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_cvttsd2si64(a)
	}

	// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation,
	// and store the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvttsd_si64x)
	@(require_results, enable_target_feature="sse2")
	_mm_cvttsd_si64x :: #force_inline proc "c" (a: __m128d) -> i64 {
		return llvm_cvttsd2si64(a)
	}

	// Copy 64-bit integer `a` to the lower element of `dst`, and zero the upper element.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi64_si128)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64_si128 :: #force_inline proc "c" (a: i64) -> __m128i {
		return __m128i {a, 0}
	}

	// Copy 64-bit integer `a` to the lower element of `dst`, and zero the upper element.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi64x_si128)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64x_si128 :: #force_inline proc "c" (a: i64) -> __m128i {
		return __m128i {a, 0}
	}

	// Copy the lower 64-bit integer in `a` to `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi128_si64)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi128_si64 :: #force_inline proc "c" (a: __m128i) -> i64 {
		return simd.extract(a, 0)
	}

	// Copy the lower 64-bit integer in `a` to `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi128_si64x)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi128_si64x :: #force_inline proc "c" (a: __m128i) -> i64 {
		return simd.extract(a, 0)
	}

	// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi64_sd)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64_sd :: #force_inline proc "c" (a: __m128d, b: i64) -> __m128d {
		return simd.replace(a, 0, f64(b))
	}

	// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element,
	// store the result in the lower element of `dst`, and copy the upper element
	// from `a` to the upper element of `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cvtsi64x_sd)
	@(require_results, enable_target_feature="sse2")
	_mm_cvtsi64x_sd :: #force_inline proc "c" (a: __m128d, b: i64) -> __m128d {
		return simd.replace(a, 0, f64(b))
	}
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse2.pause")        llvm_pause      :: proc() ---
	@(link_name="llvm.x86.sse2.clflush")      llvm_clflush    :: proc(p: rawptr) ---
	@(link_name="llvm.x86.sse2.lfence")       llvm_lfence     :: proc() ---
	@(link_name="llvm.x86.sse2.mfence")       llvm_mfence     :: proc() ---
	@(link_name="llvm.x86.sse2.pmadd.wd")     llvm_pmaddwd    :: proc(a, b: simd.i16x8) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psad.bw")      llvm_psadbw     :: proc(a, b: simd.u8x16) -> simd.u64x2 ---
	@(link_name="llvm.x86.sse2.psll.w")       llvm_psllw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psll.d")       llvm_pslld      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psll.q")       llvm_psllq      :: proc(a: simd.i64x2, count: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.psra.w")       llvm_psraw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psra.d")       llvm_psrad      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psrl.w")       llvm_psrlw      :: proc(a: simd.i16x8, count: simd.i16x8) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.psrl.d")       llvm_psrld      :: proc(a: simd.i32x4, count: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.psrl.q")       llvm_psrlq      :: proc(a: simd.i64x2, count: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse2.cvtps2dq")     llvm_cvtps2dq   :: proc(a: simd.f32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.maskmov.dqu")  llvm_maskmovdqu :: proc(a: simd.i8x16, mask: simd.i8x16, mem_addr: rawptr) ---
	@(link_name="llvm.x86.sse2.packsswb.128") llvm_packsswb   :: proc(a, b: simd.i16x8) -> simd.i8x16 ---
	@(link_name="llvm.x86.sse2.packssdw.128") llvm_packssdw   :: proc(a, b: simd.i32x4) -> simd.i16x8 ---
	@(link_name="llvm.x86.sse2.packuswb.128") llvm_packuswb   :: proc(a, b: simd.i16x8) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse2.max.sd")       llvm_maxsd      :: proc(a, b: simd.f64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.max.pd")       llvm_maxpd      :: proc(a, b: simd.f64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.min.sd")       llvm_minsd      :: proc(a, b: simd.f64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.min.pd")       llvm_minpd      :: proc(a, b: simd.f64x2) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.cmp.sd")       llvm_cmpsd      :: proc(a, b: simd.f64x2, imm8: i8) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.cmp.pd")       llvm_cmppd      :: proc(a, b: simd.f64x2, imm8: i8) -> simd.f64x2 ---
	@(link_name="llvm.x86.sse2.comieq.sd")    llvm_comieqsd   :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.comilt.sd")    llvm_comiltsd   :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.comile.sd")    llvm_comilesd   :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.comigt.sd")    llvm_comigtsd   :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.comige.sd")    llvm_comigesd   :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.comineq.sd")   llvm_comineqsd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomieq.sd")   llvm_ucomieqsd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomilt.sd")   llvm_ucomiltsd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomile.sd")   llvm_ucomilesd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomigt.sd")   llvm_ucomigtsd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomige.sd")   llvm_ucomigesd  :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.ucomineq.sd")  llvm_ucomineqsd :: proc(a, b: simd.f64x2) -> b32 ---
	@(link_name="llvm.x86.sse2.cvtpd2dq")     llvm_cvtpd2dq   :: proc(a: simd.f64x2) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.cvtsd2si")     llvm_cvtsd2si   :: proc(a: simd.f64x2) -> i32 ---
	@(link_name="llvm.x86.sse2.cvtsd2ss")     llvm_cvtsd2ss   :: proc(a: simd.f32x4, b: simd.f64x2) -> simd.f32x4 ---
	@(link_name="llvm.x86.sse2.cvttpd2dq")    llvm_cvttpd2dq  :: proc(a: simd.f64x2) -> simd.i32x4 ---
	@(link_name="llvm.x86.sse2.cvttsd2si")    llvm_cvttsd2si  :: proc(a: simd.f64x2) -> i32 ---
	@(link_name="llvm.x86.sse2.cvttps2dq")    llvm_cvttps2dq  :: proc(a: simd.f32x4) -> simd.i32x4 ---
}

when ODIN_ARCH == .amd64 {
	@(private="file", default_calling_convention="none")
	foreign _ {
		@(link_name="llvm.x86.sse2.cvtsd2si64")  llvm_cvtsd2si64  :: proc(a: simd.f64x2) -> i64 ---
		@(link_name="llvm.x86.sse2.cvttsd2si64") llvm_cvttsd2si64 :: proc(a: simd.f64x2) -> i64 ---
	}
}
