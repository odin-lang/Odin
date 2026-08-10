#+build arm64,arm32
package simd_arm

import "core:simd"

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_s8)
@(require_results, enable_target_feature = "neon")
vcls_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	return _vcls_s8(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_s16)
@(require_results, enable_target_feature = "neon")
vcls_s16 :: #force_inline proc "c" (a: int16x4_t) -> int16x4_t {
	return _vcls_s16(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_s32)
@(require_results, enable_target_feature = "neon")
vcls_s32 :: #force_inline proc "c" (a: int32x2_t) -> int32x2_t {
	return _vcls_s32(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_u8)
@(require_results, enable_target_feature = "neon")
vcls_u8 :: #force_inline proc "c" (a: uint8x8_t) -> int8x8_t {
	return vcls_s8(transmute(int8x8_t)a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_u16)
@(require_results, enable_target_feature = "neon")
vcls_u16 :: #force_inline proc "c" (a: uint16x4_t) -> int16x4_t {
	return vcls_s16(transmute(int16x4_t)a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcls_u32)
@(require_results, enable_target_feature = "neon")
vcls_u32 :: #force_inline proc "c" (a: uint32x2_t) -> int32x2_t {
	return vcls_s32(transmute(int32x2_t)a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_s8)
@(require_results, enable_target_feature = "neon")
vclsq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	return _vclsq_s8(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_s16)
@(require_results, enable_target_feature = "neon")
vclsq_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x8_t {
	return _vclsq_s16(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_s32)
@(require_results, enable_target_feature = "neon")
vclsq_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x4_t {
	return _vclsq_s32(a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_u8)
@(require_results, enable_target_feature = "neon")
vclsq_u8 :: #force_inline proc "c" (a: uint8x16_t) -> int8x16_t {
	return vclsq_s8(transmute(int8x16_t)a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_u16)
@(require_results, enable_target_feature = "neon")
vclsq_u16 :: #force_inline proc "c" (a: uint16x8_t) -> int16x8_t {
	return vclsq_s16(transmute(int16x8_t)a)
}

// Count leading sign bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclsq_u32)
@(require_results, enable_target_feature = "neon")
vclsq_u32 :: #force_inline proc "c" (a: uint32x4_t) -> int32x4_t {
	return vclsq_s32(transmute(int32x4_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_s8)
@(require_results, enable_target_feature = "neon")
vclz_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_s16)
@(require_results, enable_target_feature = "neon")
vclz_s16 :: #force_inline proc "c" (a: int16x4_t) -> int16x4_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_s32)
@(require_results, enable_target_feature = "neon")
vclz_s32 :: #force_inline proc "c" (a: int32x2_t) -> int32x2_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_u8)
@(require_results, enable_target_feature = "neon")
vclz_u8 :: #force_inline proc "c" (a: uint8x8_t) -> uint8x8_t {
	return transmute(uint8x8_t)vclz_s8(transmute(int8x8_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_u16)
@(require_results, enable_target_feature = "neon")
vclz_u16 :: #force_inline proc "c" (a: uint16x4_t) -> uint16x4_t {
	return transmute(uint16x4_t)vclz_s16(transmute(int16x4_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclz_u32)
@(require_results, enable_target_feature = "neon")
vclz_u32 :: #force_inline proc "c" (a: uint32x2_t) -> uint32x2_t {
	return transmute(uint32x2_t)vclz_s32(transmute(int32x2_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_s8)
@(require_results, enable_target_feature = "neon")
vclzq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_s16)
@(require_results, enable_target_feature = "neon")
vclzq_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x8_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_s32)
@(require_results, enable_target_feature = "neon")
vclzq_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x4_t {
	return simd.count_leading_zeros(a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_u8)
@(require_results, enable_target_feature = "neon")
vclzq_u8 :: #force_inline proc "c" (a: uint8x16_t) -> uint8x16_t {
	return transmute(uint8x16_t)vclzq_s8(transmute(int8x16_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_u16)
@(require_results, enable_target_feature = "neon")
vclzq_u16 :: #force_inline proc "c" (a: uint16x8_t) -> uint16x8_t {
	return transmute(uint16x8_t)vclzq_s16(transmute(int16x8_t)a)
}

// Count leading zero bits.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vclzq_u32)
@(require_results, enable_target_feature = "neon")
vclzq_u32 :: #force_inline proc "c" (a: uint32x4_t) -> uint32x4_t {
	return transmute(uint32x4_t)vclzq_s32(transmute(int32x4_t)a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcnt_s8)
@(require_results, enable_target_feature = "neon")
vcnt_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	return simd.count_ones(a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcnt_u8)
@(require_results, enable_target_feature = "neon")
vcnt_u8 :: #force_inline proc "c" (a: uint8x8_t) -> uint8x8_t {
	return transmute(uint8x8_t)vcnt_s8(transmute(int8x8_t)a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcnt_p8)
@(require_results, enable_target_feature = "neon")
vcnt_p8 :: #force_inline proc "c" (a: poly8x8_t) -> poly8x8_t {
	return transmute(poly8x8_t)vcnt_s8(transmute(int8x8_t)a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcntq_s8)
@(require_results, enable_target_feature = "neon")
vcntq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	return simd.count_ones(a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcntq_u8)
@(require_results, enable_target_feature = "neon")
vcntq_u8 :: #force_inline proc "c" (a: uint8x16_t) -> uint8x16_t {
	return transmute(uint8x16_t)vcntq_s8(transmute(int8x16_t)a)
}

// Population count per byte.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcntq_p8)
@(require_results, enable_target_feature = "neon")
vcntq_p8 :: #force_inline proc "c" (a: poly8x16_t) -> poly8x16_t {
	return transmute(poly8x16_t)vcntq_s8(transmute(int8x16_t)a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_s8)
@(require_results, enable_target_feature = "neon")
vbic_s8 :: #force_inline proc "c" (a: int8x8_t, b: int8x8_t) -> int8x8_t {
	c := int8x8_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_s16)
@(require_results, enable_target_feature = "neon")
vbic_s16 :: #force_inline proc "c" (a: int16x4_t, b: int16x4_t) -> int16x4_t {
	c := int16x4_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_s32)
@(require_results, enable_target_feature = "neon")
vbic_s32 :: #force_inline proc "c" (a: int32x2_t, b: int32x2_t) -> int32x2_t {
	c := int32x2_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_s64)
@(require_results, enable_target_feature = "neon")
vbic_s64 :: #force_inline proc "c" (a: int64x1_t, b: int64x1_t) -> int64x1_t {
	c := int64x1_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_u8)
@(require_results, enable_target_feature = "neon")
vbic_u8 :: #force_inline proc "c" (a: uint8x8_t, b: uint8x8_t) -> uint8x8_t {
	c := int8x8_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint8x8_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_u16)
@(require_results, enable_target_feature = "neon")
vbic_u16 :: #force_inline proc "c" (a: uint16x4_t, b: uint16x4_t) -> uint16x4_t {
	c := int16x4_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint16x4_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_u32)
@(require_results, enable_target_feature = "neon")
vbic_u32 :: #force_inline proc "c" (a: uint32x2_t, b: uint32x2_t) -> uint32x2_t {
	c := int32x2_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint32x2_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbic_u64)
@(require_results, enable_target_feature = "neon")
vbic_u64 :: #force_inline proc "c" (a: uint64x1_t, b: uint64x1_t) -> uint64x1_t {
	c := int64x1_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint64x1_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_s8)
@(require_results, enable_target_feature = "neon")
vbicq_s8 :: #force_inline proc "c" (a: int8x16_t, b: int8x16_t) -> int8x16_t {
	c := int8x16_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_s16)
@(require_results, enable_target_feature = "neon")
vbicq_s16 :: #force_inline proc "c" (a: int16x8_t, b: int16x8_t) -> int16x8_t {
	c := int16x8_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_s32)
@(require_results, enable_target_feature = "neon")
vbicq_s32 :: #force_inline proc "c" (a: int32x4_t, b: int32x4_t) -> int32x4_t {
	c := int32x4_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_s64)
@(require_results, enable_target_feature = "neon")
vbicq_s64 :: #force_inline proc "c" (a: int64x2_t, b: int64x2_t) -> int64x2_t {
	c := int64x2_t(-1)
	return simd.bit_and(simd.bit_xor(b, c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_u8)
@(require_results, enable_target_feature = "neon")
vbicq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: uint8x16_t) -> uint8x16_t {
	c := int8x16_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint8x16_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_u16)
@(require_results, enable_target_feature = "neon")
vbicq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: uint16x8_t) -> uint16x8_t {
	c := int16x8_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint16x8_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_u32)
@(require_results, enable_target_feature = "neon")
vbicq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: uint32x4_t) -> uint32x4_t {
	c := int32x4_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint32x4_t)c), a)
}

// Vector bitwise bit clear.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbicq_u64)
@(require_results, enable_target_feature = "neon")
vbicq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: uint64x2_t) -> uint64x2_t {
	c := int64x2_t(-1)
	return simd.bit_and(simd.bit_xor(b, transmute(uint64x2_t)c), a)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_s8)
@(require_results, enable_target_feature = "neon")
vbsl_s8 :: #force_inline proc "c" (a: uint8x8_t, b: int8x8_t, c: int8x8_t) -> int8x8_t {
	not := int8x8_t(-1)
	return transmute(int8x8_t)simd.bit_or(
		simd.bit_and(a, transmute(uint8x8_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint8x8_t)not), transmute(uint8x8_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_s16)
@(require_results, enable_target_feature = "neon")
vbsl_s16 :: #force_inline proc "c" (a: uint16x4_t, b: int16x4_t, c: int16x4_t) -> int16x4_t {
	not := int16x4_t(-1)
	return transmute(int16x4_t)simd.bit_or(
		simd.bit_and(a, transmute(uint16x4_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint16x4_t)not), transmute(uint16x4_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_s32)
@(require_results, enable_target_feature = "neon")
vbsl_s32 :: #force_inline proc "c" (a: uint32x2_t, b: int32x2_t, c: int32x2_t) -> int32x2_t {
	not := int32x2_t(-1)
	return transmute(int32x2_t)simd.bit_or(
		simd.bit_and(a, transmute(uint32x2_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint32x2_t)not), transmute(uint32x2_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_s64)
@(require_results, enable_target_feature = "neon")
vbsl_s64 :: #force_inline proc "c" (a: uint64x1_t, b: int64x1_t, c: int64x1_t) -> int64x1_t {
	not := int64x1_t(-1)
	return transmute(int64x1_t)simd.bit_or(
		simd.bit_and(a, transmute(uint64x1_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint64x1_t)not), transmute(uint64x1_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_u8)
@(require_results, enable_target_feature = "neon")
vbsl_u8 :: #force_inline proc "c" (a: uint8x8_t, b: uint8x8_t, c: uint8x8_t) -> uint8x8_t {
	not := int8x8_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint8x8_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_u16)
@(require_results, enable_target_feature = "neon")
vbsl_u16 :: #force_inline proc "c" (a: uint16x4_t, b: uint16x4_t, c: uint16x4_t) -> uint16x4_t {
	not := int16x4_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint16x4_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_u32)
@(require_results, enable_target_feature = "neon")
vbsl_u32 :: #force_inline proc "c" (a: uint32x2_t, b: uint32x2_t, c: uint32x2_t) -> uint32x2_t {
	not := int32x2_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint32x2_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_u64)
@(require_results, enable_target_feature = "neon")
vbsl_u64 :: #force_inline proc "c" (a: uint64x1_t, b: uint64x1_t, c: uint64x1_t) -> uint64x1_t {
	not := int64x1_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint64x1_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_s8)
@(require_results, enable_target_feature = "neon")
vbslq_s8 :: #force_inline proc "c" (a: uint8x16_t, b: int8x16_t, c: int8x16_t) -> int8x16_t {
	not := int8x16_t(-1)
	return transmute(int8x16_t)simd.bit_or(
		simd.bit_and(a, transmute(uint8x16_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint8x16_t)not), transmute(uint8x16_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_s16)
@(require_results, enable_target_feature = "neon")
vbslq_s16 :: #force_inline proc "c" (a: uint16x8_t, b: int16x8_t, c: int16x8_t) -> int16x8_t {
	not := int16x8_t(-1)
	return transmute(int16x8_t)simd.bit_or(
		simd.bit_and(a, transmute(uint16x8_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint16x8_t)not), transmute(uint16x8_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_s32)
@(require_results, enable_target_feature = "neon")
vbslq_s32 :: #force_inline proc "c" (a: uint32x4_t, b: int32x4_t, c: int32x4_t) -> int32x4_t {
	not := int32x4_t(-1)
	return transmute(int32x4_t)simd.bit_or(
		simd.bit_and(a, transmute(uint32x4_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint32x4_t)not), transmute(uint32x4_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_s64)
@(require_results, enable_target_feature = "neon")
vbslq_s64 :: #force_inline proc "c" (a: uint64x2_t, b: int64x2_t, c: int64x2_t) -> int64x2_t {
	not := int64x2_t(-1)
	return transmute(int64x2_t)simd.bit_or(
		simd.bit_and(a, transmute(uint64x2_t)b),
		simd.bit_and(simd.bit_xor(a, transmute(uint64x2_t)not), transmute(uint64x2_t)c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_u8)
@(require_results, enable_target_feature = "neon")
vbslq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: uint8x16_t, c: uint8x16_t) -> uint8x16_t {
	not := int8x16_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint8x16_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_u16)
@(require_results, enable_target_feature = "neon")
vbslq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: uint16x8_t, c: uint16x8_t) -> uint16x8_t {
	not := int16x8_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint16x8_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_u32)
@(require_results, enable_target_feature = "neon")
vbslq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: uint32x4_t, c: uint32x4_t) -> uint32x4_t {
	not := int32x4_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint32x4_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_u64)
@(require_results, enable_target_feature = "neon")
vbslq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: uint64x2_t, c: uint64x2_t) -> uint64x2_t {
	not := int64x2_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint64x2_t)not), c),
	)
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_s8)
@(require_results, enable_target_feature = "neon")
vcombine_s8 :: #force_inline proc "c" (low, high: int8x8_t) -> int8x16_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
	} else {
		low := simd.shuffle(low, low, 7, 6, 5, 4, 3, 2, 1, 0)
		high := simd.shuffle(high, high, 7, 6, 5, 4, 3, 2, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
		return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_u8)
@(require_results, enable_target_feature = "neon")
vcombine_u8 :: #force_inline proc "c" (low, high: uint8x8_t) -> uint8x16_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
	} else {
		low := simd.shuffle(low, low, 7, 6, 5, 4, 3, 2, 1, 0)
		high := simd.shuffle(high, high, 7, 6, 5, 4, 3, 2, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
		return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_s16)
@(require_results, enable_target_feature = "neon")
vcombine_s16 :: #force_inline proc "c" (low, high: int16x4_t) -> int16x8_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7)
	} else {
		low := simd.shuffle(low, low, 3, 2, 1, 0)
		high := simd.shuffle(high, high, 3, 2, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7)
		return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_u16)
@(require_results, enable_target_feature = "neon")
vcombine_u16 :: #force_inline proc "c" (low, high: uint16x4_t) -> uint16x8_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7)
	} else {
		low := simd.shuffle(low, low, 3, 2, 1, 0)
		high := simd.shuffle(high, high, 3, 2, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3, 4, 5, 6, 7)
		return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_s32)
@(require_results, enable_target_feature = "neon")
vcombine_s32 :: #force_inline proc "c" (low, high: int32x2_t) -> int32x4_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3)
	} else {
		low := simd.shuffle(low, low, 1, 0)
		high := simd.shuffle(high, high, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3)
		return simd.shuffle(c, c, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_u32)
@(require_results, enable_target_feature = "neon")
vcombine_u32 :: #force_inline proc "c" (low, high: uint32x2_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1, 2, 3)
	} else {
		low := simd.shuffle(low, low, 1, 0)
		high := simd.shuffle(high, high, 1, 0)
		c := simd.shuffle(low, high, 0, 1, 2, 3)
		return simd.shuffle(c, c, 3, 2, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_s64)
@(require_results, enable_target_feature = "neon")
vcombine_s64 :: #force_inline proc "c" (low, high: int64x1_t) -> int64x2_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1)
	} else {
		c := simd.shuffle(low, high, 0, 1)
		return simd.shuffle(c, c, 1, 0)
	}
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_u64)
@(require_results, enable_target_feature = "neon")
vcombine_u64 :: #force_inline proc "c" (low, high: uint64x1_t) -> uint64x2_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1)
	} else {
		c := simd.shuffle(low, high, 0, 1)
		return simd.shuffle(c, c, 1, 0)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl1_s8)
@(require_results, enable_target_feature = "neon")
vtbl1_s8 :: #force_inline proc "c" (t: int8x8_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_s8(vcombine_s8(t, int8x8_t{}), transmute(uint8x8_t)idx)
	} else {
		return _vtbl1(t, idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl1_u8)
@(require_results, enable_target_feature = "neon")
vtbl1_u8 :: #force_inline proc "c" (t: uint8x8_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_u8(vcombine_u8(t, uint8x8_t{}), idx)
	} else {
		return transmute(uint8x8_t)_vtbl1(transmute(int8x8_t)t, transmute(int8x8_t)idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl2_s8)
@(require_results, enable_target_feature = "neon")
vtbl2_s8 :: #force_inline proc "c" (t: int8x8x2_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_s8(vcombine_s8(t.x, t.y), transmute(uint8x8_t)idx)
	} else {
		return _vtbl2(t.x, t.y, idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl2_u8)
@(require_results, enable_target_feature = "neon")
vtbl2_u8 :: #force_inline proc "c" (t: uint8x8x2_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_u8(vcombine_u8(t.x, t.y), idx)
	} else {
		return transmute(uint8x8_t)_vtbl2(
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)idx,
		)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl3_s8)
@(require_results, enable_target_feature = "neon")
vtbl3_s8 :: #force_inline proc "c" (t: int8x8x3_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		v := int8x16x2_t {
			vcombine_s8(t.x, t.y),
			vcombine_s8(t.z, int8x8_t{}),
		}
		return vqtbl2_s8(v, transmute(uint8x8_t)idx)
	} else {
		return _vtbl3(t.x, t.y, t.z, idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl3_u8)
@(require_results, enable_target_feature = "neon")
vtbl3_u8 :: #force_inline proc "c" (t: uint8x8x3_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		v := uint8x16x2_t {
			vcombine_u8(t.x, t.y),
			vcombine_u8(t.z, uint8x8_t{}),
		}
		return vqtbl2_u8(v, idx)
	} else {
		return transmute(uint8x8_t)_vtbl3(
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)idx,
		)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl4_s8)
@(require_results, enable_target_feature = "neon")
vtbl4_s8 :: #force_inline proc "c" (t: int8x8x4_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		v := int8x16x2_t {
			vcombine_s8(t.x, t.y),
			vcombine_s8(t.z, t.w),
		}
		return vqtbl2_s8(v, transmute(uint8x8_t)idx)
	} else {
		return _vtbl4(t.x, t.y, t.z, t.w, idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl4_u8)
@(require_results, enable_target_feature = "neon")
vtbl4_u8 :: #force_inline proc "c" (t: uint8x8x4_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		v := uint8x16x2_t {
			vcombine_u8(t.x, t.y),
			vcombine_u8(t.z, t.w),
		}
		return vqtbl2_u8(v, idx)
	} else {
		return transmute(uint8x8_t)_vtbl4(
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)t.w,
			transmute(int8x8_t)idx,
		)
	}
}

when ODIN_ARCH == .arm64 {
	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1_s8 :: #force_inline proc "c" (t: int8x16_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl1(t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl1(t, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1_u8 :: #force_inline proc "c" (t: uint8x16_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbl1(transmute(int8x16_t)t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbl1(transmute(int8x16_t)t, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1q_s8 :: #force_inline proc "c" (t: int8x16_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl1q(t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl1q(t, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1q_u8 :: #force_inline proc "c" (t: uint8x16_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbl1q(transmute(int8x16_t)t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbl1q(transmute(int8x16_t)t, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2_s8 :: #force_inline proc "c" (t: int8x16x2_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl2(t.x, t.y, idx)
		} else {
			t := int8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl2(t.x, t.y, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2_u8 :: #force_inline proc "c" (t: uint8x16x2_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbl2(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			t := uint8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbl2(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2q_s8 :: #force_inline proc "c" (t: int8x16x2_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl2q(t.x, t.y, idx)
		} else {
			t := int8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl2q(t.x, t.y, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2q_u8 :: #force_inline proc "c" (t: uint8x16x2_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbl2q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			t := uint8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbl2q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3_s8 :: #force_inline proc "c" (t: int8x16x3_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl3(t.x, t.y, t.z, idx)
		} else {
			t := int8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl3(t.x, t.y, t.z, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3_u8 :: #force_inline proc "c" (t: uint8x16x3_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbl3(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			t := uint8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbl3(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3q_s8 :: #force_inline proc "c" (t: int8x16x3_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl3q(t.x, t.y, t.z, idx)
		} else {
			t := int8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl3q(t.x, t.y, t.z, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3q_u8 :: #force_inline proc "c" (t: uint8x16x3_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbl3q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			t := uint8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbl3q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4_s8 :: #force_inline proc "c" (t: int8x16x4_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl4(t.x, t.y, t.z, t.w, idx)
		} else {
			t := int8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl4(t.x, t.y, t.z, t.w, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4_u8 :: #force_inline proc "c" (t: uint8x16x4_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbl4(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			t := uint8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbl4(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4q_s8 :: #force_inline proc "c" (t: int8x16x4_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbl4q(t.x, t.y, t.z, t.w, idx)
		} else {
			t := int8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbl4q(t.x, t.y, t.z, t.w, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4q_u8 :: #force_inline proc "c" (t: uint8x16x4_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbl4q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			t := uint8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbl4q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.aarch64.neon.cls.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v8i8")
	_vcls_s8 :: proc(a: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.cls.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v4i16")
	_vcls_s16 :: proc(a: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.cls.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v2i32")
	_vcls_s32 :: proc(a: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.cls.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v16i8")
	_vclsq_s8 :: proc(a: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.cls.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v8i16")
	_vclsq_s16 :: proc(a: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.cls.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vcls.v4i32")
	_vclsq_s32 :: proc(a: int32x4_t) -> int32x4_t ---
}

when ODIN_ARCH == .arm32 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.arm.neon.vtbl1")
		_vtbl1 :: proc(t: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbl2")
		_vtbl2 :: proc(t0, t1: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbl3")
		_vtbl3 :: proc(t0, t1, t2: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbl4")
		_vtbl4 :: proc(t0, t1, t2, t3: int8x8_t, idx: int8x8_t) -> int8x8_t ---
	}
}

when ODIN_ARCH == .arm64 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.aarch64.neon.tbl1.v8i8")
		_vqtbl1 :: proc(t: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbl1.v16i8")
		_vqtbl1q :: proc(t: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbl2.v8i8")
		_vqtbl2 :: proc(t0, t1: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbl2.v16i8")
		_vqtbl2q :: proc(t0, t1: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbl3.v8i8")
		_vqtbl3 :: proc(t0, t1, t2: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbl3.v16i8")
		_vqtbl3q :: proc(t0, t1, t2: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbl4.v8i8")
		_vqtbl4 :: proc(t0, t1, t2, t3: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbl4.v16i8")
		_vqtbl4q :: proc(t0, t1, t2, t3: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
	}
}
