//+build i386, amd64
package simd_x86

import "core:simd"

_SIDD_UBYTE_OPS                :: 0b0000_0000
_SIDD_UWORD_OPS                :: 0b0000_0001
_SIDD_SBYTE_OPS                :: 0b0000_0010
_SIDD_SWORD_OPS                :: 0b0000_0011

_SIDD_CMP_EQUAL_ANY            :: 0b0000_0000
_SIDD_CMP_RANGES               :: 0b0000_0100
_SIDD_CMP_EQUAL_EACH           :: 0b0000_1000
_SIDD_CMP_EQUAL_ORDERED        :: 0b0000_1100

_SIDD_POSITIVE_POLARITY        :: 0b0000_0000
_SIDD_NEGATIVE_POLARITY        :: 0b0001_0000
_SIDD_MASKED_POSITIVE_POLARITY :: 0b0010_0000
_SIDD_MASKED_NEGATIVE_POLARITY :: 0b0011_0000

_SIDD_LEAST_SIGNIFICANT        :: 0b0000_0000
_SIDD_MOST_SIGNIFICANT         :: 0b0100_0000

_SIDD_BIT_MASK                 :: 0b0000_0000
_SIDD_UNIT_MASK                :: 0b0100_0000

@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrm :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> __m128i {
	return transmute(__m128i)pcmpistrm128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistri :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistri128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrz :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistriz128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrc :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistric128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistrs :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistris128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistro :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistrio128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpistra :: #force_inline proc "c" (a: __m128i, b: __m128i, $IMM8: i8) -> i32 {
	return pcmpistria128(transmute(i8x16)a, transmute(i8x16)b, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrm :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> __m128i {
	return transmute(__m128i)pcmpestrm128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestri :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestri128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrz :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestriz128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrc :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestric128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestrs :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestris128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestro :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestrio128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpestra :: #force_inline proc "c" (a: __m128i, la: i32, b: __m128i, lb: i32, $IMM8: i8) -> i32 {
	return pcmpestria128(transmute(i8x16)a, la, transmute(i8x16)b, lb, IMM8)
}
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u8 :: #force_inline proc "c" (crc: u32, v: u8) -> u32 {
	return crc32_32_8(crc, v)
}
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u16 :: #force_inline proc "c" (crc: u32, v: u16) -> u32 {
	return crc32_32_16(crc, v)
}
@(require_results, enable_target_feature="sse4.2")
_mm_crc32_u32 :: #force_inline proc "c" (crc: u32, v: u32) -> u32 {
	return crc32_32_32(crc, v)
}
@(require_results, enable_target_feature="sse4.2")
_mm_cmpgt_epi64 :: #force_inline proc "c" (a: __m128i, b: __m128i) -> __m128i {
	return transmute(__m128i)simd.lanes_gt(a, b)
}

when ODIN_ARCH == .amd64 {
	@(require_results, enable_target_feature="sse4.2")
	_mm_crc32_u64 :: #force_inline proc "c" (crc: u64, v: u64) -> u64 {
		return crc32_64_64(crc, v)
	}
}

@(private, default_calling_convention="none")
foreign _ {
	// SSE 4.2 string and text comparison ops
	@(link_name="llvm.x86.sse42.pcmpestrm128")
	pcmpestrm128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> u8x16 ---
	@(link_name="llvm.x86.sse42.pcmpestri128")
	pcmpestri128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestriz128")
	pcmpestriz128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestric128")
	pcmpestric128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestris128")
	pcmpestris128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestrio128")
	pcmpestrio128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpestria128")
	pcmpestria128 :: proc(a: i8x16, la: i32, b: i8x16, lb: i32, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistrm128")
	pcmpistrm128 :: proc(a, b: i8x16, #const imm8: i8) -> i8x16 ---
	@(link_name="llvm.x86.sse42.pcmpistri128")
	pcmpistri128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistriz128")
	pcmpistriz128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistric128")
	pcmpistric128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistris128")
	pcmpistris128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistrio128")
	pcmpistrio128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	@(link_name="llvm.x86.sse42.pcmpistria128")
	pcmpistria128 :: proc(a, b: i8x16, #const imm8: i8) -> i32 ---
	// SSE 4.2 CRC instructions
	@(link_name="llvm.x86.sse42.crc32.32.8")
	crc32_32_8 :: proc(crc: u32, v: u8) -> u32 ---
	@(link_name="llvm.x86.sse42.crc32.32.16")
	crc32_32_16 :: proc(crc: u32, v: u16) -> u32 ---
	@(link_name="llvm.x86.sse42.crc32.32.32")
	crc32_32_32 :: proc(crc: u32, v: u32) -> u32 ---

	// AMD64 Only
	@(link_name="llvm.x86.sse42.crc32.64.64")
	crc32_64_64 :: proc(crc: u64, v: u64) -> u64 ---
}
