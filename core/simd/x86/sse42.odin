#+build i386, amd64
package simd_x86

import "core:simd"

_SIDD_UBYTE_OPS                : i32 : 0b0000_0000
_SIDD_UWORD_OPS                : i32 : 0b0000_0001
_SIDD_SBYTE_OPS                : i32 : 0b0000_0010
_SIDD_SWORD_OPS                : i32 : 0b0000_0011

_SIDD_CMP_EQUAL_ANY            : i32 : 0b0000_0000
_SIDD_CMP_RANGES               : i32 : 0b0000_0100
_SIDD_CMP_EQUAL_EACH           : i32 : 0b0000_1000
_SIDD_CMP_EQUAL_ORDERED        : i32 : 0b0000_1100

_SIDD_POSITIVE_POLARITY        : i32 : 0b0000_0000
_SIDD_NEGATIVE_POLARITY        : i32 : 0b0001_0000
_SIDD_MASKED_POSITIVE_POLARITY : i32 : 0b0010_0000
_SIDD_MASKED_NEGATIVE_POLARITY : i32 : 0b0011_0000

_SIDD_LEAST_SIGNIFICANT        : i32 : 0b0000_0000
_SIDD_MOST_SIGNIFICANT         : i32 : 0b0100_0000

_SIDD_BIT_MASK                 : i32 : 0b0000_0000
_SIDD_UNIT_MASK                : i32 : 0b0100_0000

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and store the generated mask in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistrm)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrm :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)llvm_pcmpistrm128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and store the generated index in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistri)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistri :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistri128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and returns 1 if any character in `b` was null, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistrz)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrz :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistriz128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and returns 1 if the resulting mask was non-zero, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistrc)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrc :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistric128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and returns 1 if any character in `a` was null, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistrs)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrs :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistris128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and returns bit 0 of the resulting bit mask.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistro)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistro :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistrio128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings with implicit lengths in `a` and `b` using the control in `imm8`,
// and returns 1 if `b` did not contain a null character and the resulting mask was zero, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpistra)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistra :: #force_inline proc "c" (a, b: __m128i, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpistria128(
		transmute(simd.i8x16)a,
		transmute(simd.i8x16)b,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and store the generated mask in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestrm)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrm :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return transmute(__m128i)llvm_pcmpestrm128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and store the generated index in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestri)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestri :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestri128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and returns 1 if any character in `b` was null, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestrz)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrz :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestriz128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and returns 1 if the resulting mask was non-zero, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestrc)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrc :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestric128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and returns 1 if any character in `a` was null, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestrs)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrs :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestris128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and returns bit 0 of the resulting bit mask.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestro)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestro :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestrio128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Compare packed strings in `a` and `b` with lengths `la` and `lb` using the control in `imm8`,
// and returns 1 if `b` did not contain a null character and the resulting mask was zero, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpestra)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestra :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i32) -> i32 where 0 <= IMM8, IMM8 < 256 {
	return llvm_pcmpestria128(
		transmute(simd.i8x16)a, la,
		transmute(simd.i8x16)b, lb,
		cast(i8)IMM8,
	)
}

// Starting with the initial value in `crc`, accumulates a CRC32 value for unsigned 8-bit integer `v`,
// and stores the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_crc32_u8)
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u8 :: #force_inline proc "c" (crc: u32, v: u8) -> u32 {
	return llvm_crc32_32_8(crc, v)
}

// Starting with the initial value in `crc`, accumulates a CRC32 value for unsigned 16-bit integer `v`,
// and stores the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_crc32_u16)
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u16 :: #force_inline proc "c" (crc: u32, v: u16) -> u32 {
	return llvm_crc32_32_16(crc, v)
}

// Starting with the initial value in `crc`, accumulates a CRC32 value for unsigned 32-bit integer `v`,
// and stores the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_crc32_u32)
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u32 :: #force_inline proc "c" (crc: u32, v: u32) -> u32 {
	return llvm_crc32_32_32(crc, v)
}

// Compare packed signed 64-bit integers in `a` and `b` for greater-than, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_cmpgt_epi64)
@(require_results, enable_target_feature="sse4.2")
_mm_cmpgt_epi64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(a, b)
}

when ODIN_ARCH == .amd64 {
	// Starting with the initial value in `crc`, accumulates a CRC32 value for unsigned 64-bit integer `v`,
	// and stores the result in `dst`.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_crc32_u64)
	@(require_results, enable_target_feature="sse4.2")
	_mm_crc32_u64 :: #force_inline proc "c" (crc: u64, v: u64) -> u64 {
		return llvm_crc32_64_64(crc, v)
	}
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse42.pcmpestrm128")  llvm_pcmpestrm128  :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> simd.u8x16 ---
	@(link_name="llvm.x86.sse42.pcmpestri128")  llvm_pcmpestri128  :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestriz128") llvm_pcmpestriz128 :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestric128") llvm_pcmpestric128 :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestris128") llvm_pcmpestris128 :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestrio128") llvm_pcmpestrio128 :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestria128") llvm_pcmpestria128 :: proc(a: simd.i8x16, la: i32, b: simd.i8x16, lb: i32, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistrm128")  llvm_pcmpistrm128  :: proc(a, b: simd.i8x16, imm8: i8) -> simd.i8x16 ---
	@(link_name="llvm.x86.sse42.pcmpistri128")  llvm_pcmpistri128  :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistriz128") llvm_pcmpistriz128 :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistric128") llvm_pcmpistric128 :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistris128") llvm_pcmpistris128 :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistrio128") llvm_pcmpistrio128 :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistria128") llvm_pcmpistria128 :: proc(a, b: simd.i8x16, imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.crc32.32.8")    llvm_crc32_32_8    :: proc(crc: u32, v: u8) -> u32 ---
	@(link_name="llvm.x86.sse42.crc32.32.16")   llvm_crc32_32_16   :: proc(crc: u32, v: u16) -> u32 ---
	@(link_name="llvm.x86.sse42.crc32.32.32")   llvm_crc32_32_32   :: proc(crc: u32, v: u32) -> u32 ---
}

when ODIN_ARCH == .amd64 {
	@(private="file", default_calling_convention="none")
	foreign _ {
		@(link_name="llvm.x86.sse42.crc32.64.64") llvm_crc32_64_64 :: proc(crc: u64, v: u64) -> u64 ---
	}
}
