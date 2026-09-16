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

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx1_s8)
@(require_results, enable_target_feature = "neon")
vtbx1_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x8_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, int8x8_t(8)),
			vqtbx1_s8(v, vcombine_s8(t, int8x8_t{}), transmute(uint8x8_t)idx),
			v,
		)
	} else {
		return _vtbx1(v, t, idx)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx1_u8)
@(require_results, enable_target_feature = "neon")
vtbx1_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x8_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(8)),
			vqtbx1_u8(v, vcombine_u8(t, uint8x8_t{}), idx),
			v,
		)
	} else {
		return transmute(uint8x8_t)_vtbx1(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t,
			transmute(int8x8_t)idx,
		)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx2_s8)
@(require_results, enable_target_feature = "neon")
vtbx2_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x8x2_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, int8x8_t(16)),
			vqtbx1_s8(v, vcombine_s8(t.x, t.y), transmute(uint8x8_t)idx),
			v,
		)
	} else {
		return _vtbx2(v, t.x, t.y, idx)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx2_u8)
@(require_results, enable_target_feature = "neon")
vtbx2_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x8x2_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(16)),
			vqtbx1_u8(v, vcombine_u8(t.x, t.y), idx),
			v,
		)
	} else {
		return transmute(uint8x8_t)_vtbx2(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)idx,
		)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx3_s8)
@(require_results, enable_target_feature = "neon")
vtbx3_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x8x3_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		x := int8x16x2_t {
			vcombine_s8(t.x, t.y),
			vcombine_s8(t.z, int8x8_t{}),
		}
		return simd.select(
			simd.lanes_lt(idx, int8x8_t(24)),
			vqtbx2_s8(v, x, transmute(uint8x8_t)idx),
			v,
		)
	} else {
		return _vtbx3(v, t.x, t.y, t.z, idx)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx3_u8)
@(require_results, enable_target_feature = "neon")
vtbx3_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x8x3_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		x := uint8x16x2_t {
			vcombine_u8(t.x, t.y),
			vcombine_u8(t.z, uint8x8_t{}),
		}
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(24)),
			vqtbx2_u8(v, x, idx),
			v,
		)
	} else {
		return transmute(uint8x8_t)_vtbx3(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)idx,
		)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx4_s8)
@(require_results, enable_target_feature = "neon")
vtbx4_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x8x4_t, idx: int8x8_t) -> int8x8_t {
	when ODIN_ARCH == .arm64 {
		x := int8x16x2_t {
			vcombine_s8(t.x, t.y),
			vcombine_s8(t.z, t.w),
		}
		return simd.select(
			simd.lanes_lt(idx, int8x8_t(32)),
			vqtbx2_s8(v, x, transmute(uint8x8_t)idx),
			v,
		)
	} else {
		return _vtbx4(v, t.x, t.y, t.z, t.w, idx)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx4_u8)
@(require_results, enable_target_feature = "neon")
vtbx4_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x8x4_t, idx: uint8x8_t) -> uint8x8_t {
	when ODIN_ARCH == .arm64 {
		x := uint8x16x2_t {
			vcombine_u8(t.x, t.y),
			vcombine_u8(t.z, t.w),
		}
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(32)),
			vqtbx2_u8(v, x, idx),
			v,
		)
	} else {
		return transmute(uint8x8_t)_vtbx4(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)t.w,
			transmute(int8x8_t)idx,
		)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vdup_n_s8)
@(require_results, enable_target_feature = "neon")
vdup_n_s8 :: #force_inline proc "c" (value: int8_t) -> int8x8_t {
	return int8x8_t(value)
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vdup_n_s16)
@(require_results, enable_target_feature = "neon")
vdup_n_s16 :: #force_inline proc "c" (value: int16_t) -> int16x4_t {
	return int16x4_t(value)
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vdup_n_s32)
@(require_results, enable_target_feature = "neon")
vdup_n_s32 :: #force_inline proc "c" (value: int32_t) -> int32x2_t {
	return int32x2_t(value)
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vdup_n_s64)
@(require_results, enable_target_feature = "neon")
vdup_n_s64 :: #force_inline proc "c" (value: int64_t) -> int64x1_t {
	return int64x1_t(value)
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_s8)
@(require_results, enable_target_feature = "neon")
vget_lane_s8 :: #force_inline proc "c" (v: int8x8_t, $LANE: int32_t) -> int8_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_u8)
@(require_results, enable_target_feature = "neon")
vget_lane_u8 :: #force_inline proc "c" (v: uint8x8_t, $LANE: int32_t) -> uint8_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_s16)
@(require_results, enable_target_feature = "neon")
vget_lane_s16 :: #force_inline proc "c" (v: int16x4_t, $LANE: int32_t) -> int16_t where 0 <= LANE, LANE < 4 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_u16)
@(require_results, enable_target_feature = "neon")
vget_lane_u16 :: #force_inline proc "c" (v: uint16x4_t, $LANE: int32_t) -> uint16_t where 0 <= LANE, LANE < 4 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_s32)
@(require_results, enable_target_feature = "neon")
vget_lane_s32 :: #force_inline proc "c" (v: int32x2_t, $LANE: int32_t) -> int32_t where 0 <= LANE, LANE < 2 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_u32)
@(require_results, enable_target_feature = "neon")
vget_lane_u32 :: #force_inline proc "c" (v: uint32x2_t, $LANE: int32_t) -> uint32_t where 0 <= LANE, LANE < 2 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_s64)
@(require_results, enable_target_feature = "neon")
vget_lane_s64 :: #force_inline proc "c" (v: int64x1_t, $LANE: int32_t) -> int64_t where LANE == 0 {
	return simd.extract(v, LANE)
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_u64)
@(require_results, enable_target_feature = "neon")
vget_lane_u64 :: #force_inline proc "c" (v: uint64x1_t, $LANE: int32_t) -> uint64_t where LANE == 0 {
	return simd.extract(v, LANE)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vneg_s8)
@(require_results, enable_target_feature = "neon")
vneg_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	return simd.neg(a)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vnegq_s8)
@(require_results, enable_target_feature = "neon")
vnegq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	return simd.neg(a)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vneg_s16)
@(require_results, enable_target_feature = "neon")
vneg_s16 :: #force_inline proc "c" (a: int16x4_t) -> int16x4_t {
	return simd.neg(a)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vnegq_s16)
@(require_results, enable_target_feature = "neon")
vnegq_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x8_t {
	return simd.neg(a)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vneg_s32)
@(require_results, enable_target_feature = "neon")
vneg_s32 :: #force_inline proc "c" (a: int32x2_t) -> int32x2_t {
	return simd.neg(a)
}

// Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vnegq_s32)
@(require_results, enable_target_feature = "neon")
vnegq_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x4_t {
	return simd.neg(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqneg_s8)
@(require_results, enable_target_feature = "neon")
vqneg_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	return _vqneg_s8(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqneg_s16)
@(require_results, enable_target_feature = "neon")
vqneg_s16 :: #force_inline proc "c" (a: int16x4_t) -> int16x4_t {
	return _vqneg_s16(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqneg_s32)
@(require_results, enable_target_feature = "neon")
vqneg_s32 :: #force_inline proc "c" (a: int32x2_t) -> int32x2_t {
	return _vqneg_s32(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegq_s8)
@(require_results, enable_target_feature = "neon")
vqnegq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	return _vqnegq_s8(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegq_s16)
@(require_results, enable_target_feature = "neon")
vqnegq_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x8_t {
	return _vqnegq_s16(a)
}

// Signed saturating Negate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegq_s32)
@(require_results, enable_target_feature = "neon")
vqnegq_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x4_t {
	return _vqnegq_s32(a)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_s8)
@(require_results, enable_target_feature = "neon")
vmvn_s8 :: #force_inline proc "c" (a: int8x8_t) -> int8x8_t {
	b := int8x8_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_u8)
@(require_results, enable_target_feature = "neon")
vmvn_u8 :: #force_inline proc "c" (a: uint8x8_t) -> uint8x8_t {
	b := uint8x8_t(max(uint8_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_s16)
@(require_results, enable_target_feature = "neon")
vmvn_s16 :: #force_inline proc "c" (a: int16x4_t) -> int16x4_t {
	b := int16x4_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_u16)
@(require_results, enable_target_feature = "neon")
vmvn_u16 :: #force_inline proc "c" (a: uint16x4_t) -> uint16x4_t {
	b := uint16x4_t(max(uint16_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_s32)
@(require_results, enable_target_feature = "neon")
vmvn_s32 :: #force_inline proc "c" (a: int32x2_t) -> int32x2_t {
	b := int32x2_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_u32)
@(require_results, enable_target_feature = "neon")
vmvn_u32 :: #force_inline proc "c" (a: uint32x2_t) -> uint32x2_t {
	b := uint32x2_t(max(uint32_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_s8)
@(require_results, enable_target_feature = "neon")
vmvnq_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x16_t {
	b := int8x16_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_u8)
@(require_results, enable_target_feature = "neon")
vmvnq_u8 :: #force_inline proc "c" (a: uint8x16_t) -> uint8x16_t {
	b := uint8x16_t(max(uint8_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_s16)
@(require_results, enable_target_feature = "neon")
vmvnq_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x8_t {
	b := int16x8_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_u16)
@(require_results, enable_target_feature = "neon")
vmvnq_u16 :: #force_inline proc "c" (a: uint16x8_t) -> uint16x8_t {
	b := uint16x8_t(max(uint16_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_s32)
@(require_results, enable_target_feature = "neon")
vmvnq_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x4_t {
	b := int32x4_t(-1)
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_u32)
@(require_results, enable_target_feature = "neon")
vmvnq_u32 :: #force_inline proc "c" (a: uint32x4_t) -> uint32x4_t {
	b := uint32x4_t(max(uint32_t))
	return simd.bit_xor(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_s8)
@(require_results, enable_target_feature = "neon")
vand_s8 :: #force_inline proc "c" (a, b: int8x8_t) -> int8x8_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_u8)
@(require_results, enable_target_feature = "neon")
vand_u8 :: #force_inline proc "c" (a, b: uint8x8_t) -> uint8x8_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_s16)
@(require_results, enable_target_feature = "neon")
vand_s16 :: #force_inline proc "c" (a, b: int16x4_t) -> int16x4_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_u16)
@(require_results, enable_target_feature = "neon")
vand_u16 :: #force_inline proc "c" (a, b: uint16x4_t) -> uint16x4_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_s32)
@(require_results, enable_target_feature = "neon")
vand_s32 :: #force_inline proc "c" (a, b: int32x2_t) -> int32x2_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_u32)
@(require_results, enable_target_feature = "neon")
vand_u32 :: #force_inline proc "c" (a, b: uint32x2_t) -> uint32x2_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_s64)
@(require_results, enable_target_feature = "neon")
vand_s64 :: #force_inline proc "c" (a, b: int64x1_t) -> int64x1_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vand_u64)
@(require_results, enable_target_feature = "neon")
vand_u64 :: #force_inline proc "c" (a, b: uint64x1_t) -> uint64x1_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_s8)
@(require_results, enable_target_feature = "neon")
vandq_s8 :: #force_inline proc "c" (a, b: int8x16_t) -> int8x16_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_u8)
@(require_results, enable_target_feature = "neon")
vandq_u8 :: #force_inline proc "c" (a, b: uint8x16_t) -> uint8x16_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_s16)
@(require_results, enable_target_feature = "neon")
vandq_s16 :: #force_inline proc "c" (a, b: int16x8_t) -> int16x8_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_u16)
@(require_results, enable_target_feature = "neon")
vandq_u16 :: #force_inline proc "c" (a, b: uint16x8_t) -> uint16x8_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_s32)
@(require_results, enable_target_feature = "neon")
vandq_s32 :: #force_inline proc "c" (a, b: int32x4_t) -> int32x4_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_u32)
@(require_results, enable_target_feature = "neon")
vandq_u32 :: #force_inline proc "c" (a, b: uint32x4_t) -> uint32x4_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_s64)
@(require_results, enable_target_feature = "neon")
vandq_s64 :: #force_inline proc "c" (a, b: int64x2_t) -> int64x2_t {
	return simd.bit_and(a, b)
}

// Bitwise And.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vandq_u64)
@(require_results, enable_target_feature = "neon")
vandq_u64 :: #force_inline proc "c" (a, b: uint64x2_t) -> uint64x2_t {
	return simd.bit_and(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_s8)
@(require_results, enable_target_feature = "neon")
vorr_s8 :: #force_inline proc "c" (a, b: int8x8_t) -> int8x8_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_u8)
@(require_results, enable_target_feature = "neon")
vorr_u8 :: #force_inline proc "c" (a, b: uint8x8_t) -> uint8x8_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_s16)
@(require_results, enable_target_feature = "neon")
vorr_s16 :: #force_inline proc "c" (a, b: int16x4_t) -> int16x4_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_u16)
@(require_results, enable_target_feature = "neon")
vorr_u16 :: #force_inline proc "c" (a, b: uint16x4_t) -> uint16x4_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_s32)
@(require_results, enable_target_feature = "neon")
vorr_s32 :: #force_inline proc "c" (a, b: int32x2_t) -> int32x2_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_u32)
@(require_results, enable_target_feature = "neon")
vorr_u32 :: #force_inline proc "c" (a, b: uint32x2_t) -> uint32x2_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_s64)
@(require_results, enable_target_feature = "neon")
vorr_s64 :: #force_inline proc "c" (a, b: int64x1_t) -> int64x1_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorr_u64)
@(require_results, enable_target_feature = "neon")
vorr_u64 :: #force_inline proc "c" (a, b: uint64x1_t) -> uint64x1_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_s8)
@(require_results, enable_target_feature = "neon")
vorrq_s8 :: #force_inline proc "c" (a, b: int8x16_t) -> int8x16_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_u8)
@(require_results, enable_target_feature = "neon")
vorrq_u8 :: #force_inline proc "c" (a, b: uint8x16_t) -> uint8x16_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_s16)
@(require_results, enable_target_feature = "neon")
vorrq_s16 :: #force_inline proc "c" (a, b: int16x8_t) -> int16x8_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_u16)
@(require_results, enable_target_feature = "neon")
vorrq_u16 :: #force_inline proc "c" (a, b: uint16x8_t) -> uint16x8_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_s32)
@(require_results, enable_target_feature = "neon")
vorrq_s32 :: #force_inline proc "c" (a, b: int32x4_t) -> int32x4_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_u32)
@(require_results, enable_target_feature = "neon")
vorrq_u32 :: #force_inline proc "c" (a, b: uint32x4_t) -> uint32x4_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_s64)
@(require_results, enable_target_feature = "neon")
vorrq_s64 :: #force_inline proc "c" (a, b: int64x2_t) -> int64x2_t {
	return simd.bit_or(a, b)
}

// Bitwise Inclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorrq_u64)
@(require_results, enable_target_feature = "neon")
vorrq_u64 :: #force_inline proc "c" (a, b: uint64x2_t) -> uint64x2_t {
	return simd.bit_or(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_s8)
@(require_results, enable_target_feature = "neon")
veor_s8 :: #force_inline proc "c" (a, b: int8x8_t) -> int8x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_u8)
@(require_results, enable_target_feature = "neon")
veor_u8 :: #force_inline proc "c" (a, b: uint8x8_t) -> uint8x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_s16)
@(require_results, enable_target_feature = "neon")
veor_s16 :: #force_inline proc "c" (a, b: int16x4_t) -> int16x4_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_u16)
@(require_results, enable_target_feature = "neon")
veor_u16 :: #force_inline proc "c" (a, b: uint16x4_t) -> uint16x4_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_s32)
@(require_results, enable_target_feature = "neon")
veor_s32 :: #force_inline proc "c" (a, b: int32x2_t) -> int32x2_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_u32)
@(require_results, enable_target_feature = "neon")
veor_u32 :: #force_inline proc "c" (a, b: uint32x2_t) -> uint32x2_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_s64)
@(require_results, enable_target_feature = "neon")
veor_s64 :: #force_inline proc "c" (a, b: int64x1_t) -> int64x1_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veor_u64)
@(require_results, enable_target_feature = "neon")
veor_u64 :: #force_inline proc "c" (a, b: uint64x1_t) -> uint64x1_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_s8)
@(require_results, enable_target_feature = "neon")
veorq_s8 :: #force_inline proc "c" (a, b: int8x16_t) -> int8x16_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_u8)
@(require_results, enable_target_feature = "neon")
veorq_u8 :: #force_inline proc "c" (a, b: uint8x16_t) -> uint8x16_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_s16)
@(require_results, enable_target_feature = "neon")
veorq_s16 :: #force_inline proc "c" (a, b: int16x8_t) -> int16x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_u16)
@(require_results, enable_target_feature = "neon")
veorq_u16 :: #force_inline proc "c" (a, b: uint16x8_t) -> uint16x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_s32)
@(require_results, enable_target_feature = "neon")
veorq_s32 :: #force_inline proc "c" (a, b: int32x4_t) -> int32x4_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_u32)
@(require_results, enable_target_feature = "neon")
veorq_u32 :: #force_inline proc "c" (a, b: uint32x4_t) -> uint32x4_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_s64)
@(require_results, enable_target_feature = "neon")
veorq_s64 :: #force_inline proc "c" (a, b: int64x2_t) -> int64x2_t {
	return simd.bit_xor(a, b)
}

// Bitwise Exclusive Or.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/veorq_u64)
@(require_results, enable_target_feature = "neon")
veorq_u64 :: #force_inline proc "c" (a, b: uint64x2_t) -> uint64x2_t {
	return simd.bit_xor(a, b)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_s8)
@(require_results, enable_target_feature = "neon")
vorn_s8 :: #force_inline proc "c" (a, b: int8x8_t) -> int8x8_t {
	c := int8x8_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_u8)
@(require_results, enable_target_feature = "neon")
vorn_u8 :: #force_inline proc "c" (a, b: uint8x8_t) -> uint8x8_t {
	c := uint8x8_t(max(uint8_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_s16)
@(require_results, enable_target_feature = "neon")
vorn_s16 :: #force_inline proc "c" (a, b: int16x4_t) -> int16x4_t {
	c := int16x4_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_u16)
@(require_results, enable_target_feature = "neon")
vorn_u16 :: #force_inline proc "c" (a, b: uint16x4_t) -> uint16x4_t {
	c := uint16x4_t(max(uint16_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_s32)
@(require_results, enable_target_feature = "neon")
vorn_s32 :: #force_inline proc "c" (a, b: int32x2_t) -> int32x2_t {
	c := int32x2_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_u32)
@(require_results, enable_target_feature = "neon")
vorn_u32 :: #force_inline proc "c" (a, b: uint32x2_t) -> uint32x2_t {
	c := uint32x2_t(max(uint32_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_s64)
@(require_results, enable_target_feature = "neon")
vorn_s64 :: #force_inline proc "c" (a, b: int64x1_t) -> int64x1_t {
	c := int64x1_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vorn_u64)
@(require_results, enable_target_feature = "neon")
vorn_u64 :: #force_inline proc "c" (a, b: uint64x1_t) -> uint64x1_t {
	c := uint64x1_t(max(uint64_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_s8)
@(require_results, enable_target_feature = "neon")
vornq_s8 :: #force_inline proc "c" (a, b: int8x16_t) -> int8x16_t {
	c := int8x16_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_u8)
@(require_results, enable_target_feature = "neon")
vornq_u8 :: #force_inline proc "c" (a, b: uint8x16_t) -> uint8x16_t {
	c := uint8x16_t(max(uint8_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_s16)
@(require_results, enable_target_feature = "neon")
vornq_s16 :: #force_inline proc "c" (a, b: int16x8_t) -> int16x8_t {
	c := int16x8_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_u16)
@(require_results, enable_target_feature = "neon")
vornq_u16 :: #force_inline proc "c" (a, b: uint16x8_t) -> uint16x8_t {
	c := uint16x8_t(max(uint16_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_s32)
@(require_results, enable_target_feature = "neon")
vornq_s32 :: #force_inline proc "c" (a, b: int32x4_t) -> int32x4_t {
	c := int32x4_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_u32)
@(require_results, enable_target_feature = "neon")
vornq_u32 :: #force_inline proc "c" (a, b: uint32x4_t) -> uint32x4_t {
	c := uint32x4_t(max(uint32_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_s64)
@(require_results, enable_target_feature = "neon")
vornq_s64 :: #force_inline proc "c" (a, b: int64x2_t) -> int64x2_t {
	c := int64x2_t(-1)
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Bitwise Inclusive Or Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vornq_u64)
@(require_results, enable_target_feature = "neon")
vornq_u64 :: #force_inline proc "c" (a, b: uint64x2_t) -> uint64x2_t {
	c := uint64x2_t(max(uint64_t))
	return simd.bit_or(simd.bit_xor(b, c), a)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_s8)
@(require_results, enable_target_feature = "neon")
vshl_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> int8x8_t where 0 <= N, N < 8 {
	return simd.shl(v, uint8x8_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_u8)
@(require_results, enable_target_feature = "neon")
vshl_n_u8 :: #force_inline proc "c" (v: uint8x8_t, $N: int32_t) -> uint8x8_t where 0 <= N, N < 8 {
	return simd.shl(v, uint8x8_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_s16)
@(require_results, enable_target_feature = "neon")
vshl_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> int16x4_t where 0 <= N, N < 16 {
	return simd.shl(v, uint16x4_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_u16)
@(require_results, enable_target_feature = "neon")
vshl_n_u16 :: #force_inline proc "c" (v: uint16x4_t, $N: int32_t) -> uint16x4_t where 0 <= N, N < 16 {
	return simd.shl(v, uint16x4_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_s32)
@(require_results, enable_target_feature = "neon")
vshl_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> int32x2_t where 0 <= N, N < 32 {
	return simd.shl(v, uint32x2_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_u32)
@(require_results, enable_target_feature = "neon")
vshl_n_u32 :: #force_inline proc "c" (v: uint32x2_t, $N: int32_t) -> uint32x2_t where 0 <= N, N < 32 {
	return simd.shl(v, uint32x2_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_s64)
@(require_results, enable_target_feature = "neon")
vshl_n_s64 :: #force_inline proc "c" (v: int64x1_t, $N: int32_t) -> int64x1_t where 0 <= N, N < 64 {
	return simd.shl(v, uint64x1_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_n_u64)
@(require_results, enable_target_feature = "neon")
vshl_n_u64 :: #force_inline proc "c" (v: uint64x1_t, $N: int32_t) -> uint64x1_t where 0 <= N, N < 64 {
	return simd.shl(v, uint64x1_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_s8)
@(require_results, enable_target_feature = "neon")
vshlq_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> int8x16_t where 0 <= N, N < 8 {
	return simd.shl(v, uint8x16_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_u8)
@(require_results, enable_target_feature = "neon")
vshlq_n_u8 :: #force_inline proc "c" (v: uint8x16_t, $N: int32_t) -> uint8x16_t where 0 <= N, N < 8 {
	return simd.shl(v, uint8x16_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_s16)
@(require_results, enable_target_feature = "neon")
vshlq_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> int16x8_t where 0 <= N, N < 16 {
	return simd.shl(v, uint16x8_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_u16)
@(require_results, enable_target_feature = "neon")
vshlq_n_u16 :: #force_inline proc "c" (v: uint16x8_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 16 {
	return simd.shl(v, uint16x8_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_s32)
@(require_results, enable_target_feature = "neon")
vshlq_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> int32x4_t where 0 <= N, N < 32 {
	return simd.shl(v, uint32x4_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_u32)
@(require_results, enable_target_feature = "neon")
vshlq_n_u32 :: #force_inline proc "c" (v: uint32x4_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 32 {
	return simd.shl(v, uint32x4_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_s64)
@(require_results, enable_target_feature = "neon")
vshlq_n_s64 :: #force_inline proc "c" (v: int64x2_t, $N: int32_t) -> int64x2_t where 0 <= N, N < 64 {
	return simd.shl(v, uint64x2_t(N))
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_n_u64)
@(require_results, enable_target_feature = "neon")
vshlq_n_u64 :: #force_inline proc "c" (v: uint64x2_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 64 {
	return simd.shl(v, uint64x2_t(N))
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_s8)
@(require_results, enable_target_feature = "neon")
vshl_s8 :: #force_inline proc "c" (a: int8x8_t, b: int8x8_t) -> int8x8_t {
	return _vshl_s8(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_u8)
@(require_results, enable_target_feature = "neon")
vshl_u8 :: #force_inline proc "c" (a: uint8x8_t, b: int8x8_t) -> uint8x8_t {
	return _vshl_u8(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_s16)
@(require_results, enable_target_feature = "neon")
vshl_s16 :: #force_inline proc "c" (a: int16x4_t, b: int16x4_t) -> int16x4_t {
	return _vshl_s16(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_u16)
@(require_results, enable_target_feature = "neon")
vshl_u16 :: #force_inline proc "c" (a: uint16x4_t, b: int16x4_t) -> uint16x4_t {
	return _vshl_u16(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_s32)
@(require_results, enable_target_feature = "neon")
vshl_s32 :: #force_inline proc "c" (a: int32x2_t, b: int32x2_t) -> int32x2_t {
	return _vshl_s32(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_u32)
@(require_results, enable_target_feature = "neon")
vshl_u32 :: #force_inline proc "c" (a: uint32x2_t, b: int32x2_t) -> uint32x2_t {
	return _vshl_u32(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_s64)
@(require_results, enable_target_feature = "neon")
vshl_s64 :: #force_inline proc "c" (a: int64x1_t, b: int64x1_t) -> int64x1_t {
	return _vshl_s64(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshl_u64)
@(require_results, enable_target_feature = "neon")
vshl_u64 :: #force_inline proc "c" (a: uint64x1_t, b: int64x1_t) -> uint64x1_t {
	return _vshl_u64(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_s8)
@(require_results, enable_target_feature = "neon")
vshlq_s8 :: #force_inline proc "c" (a: int8x16_t, b: int8x16_t) -> int8x16_t {
	return _vshlq_s8(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_u8)
@(require_results, enable_target_feature = "neon")
vshlq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: int8x16_t) -> uint8x16_t {
	return _vshlq_u8(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_s16)
@(require_results, enable_target_feature = "neon")
vshlq_s16 :: #force_inline proc "c" (a: int16x8_t, b: int16x8_t) -> int16x8_t {
	return _vshlq_s16(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_u16)
@(require_results, enable_target_feature = "neon")
vshlq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: int16x8_t) -> uint16x8_t {
	return _vshlq_u16(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_s32)
@(require_results, enable_target_feature = "neon")
vshlq_s32 :: #force_inline proc "c" (a: int32x4_t, b: int32x4_t) -> int32x4_t {
	return _vshlq_s32(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_u32)
@(require_results, enable_target_feature = "neon")
vshlq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: int32x4_t) -> uint32x4_t {
	return _vshlq_u32(a, b)
}

// Signed Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_s64)
@(require_results, enable_target_feature = "neon")
vshlq_s64 :: #force_inline proc "c" (a: int64x2_t, b: int64x2_t) -> int64x2_t {
	return _vshlq_s64(a, b)
}

// Unsigned Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshlq_u64)
@(require_results, enable_target_feature = "neon")
vshlq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: int64x2_t) -> uint64x2_t {
	return _vshlq_u64(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_s8)
@(require_results, enable_target_feature = "neon")
vrshl_s8 :: #force_inline proc "c" (a: int8x8_t, b: int8x8_t) -> int8x8_t {
	return _vrshl_s8(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_u8)
@(require_results, enable_target_feature = "neon")
vrshl_u8 :: #force_inline proc "c" (a: uint8x8_t, b: int8x8_t) -> uint8x8_t {
	return _vrshl_u8(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_s16)
@(require_results, enable_target_feature = "neon")
vrshl_s16 :: #force_inline proc "c" (a: int16x4_t, b: int16x4_t) -> int16x4_t {
	return _vrshl_s16(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_u16)
@(require_results, enable_target_feature = "neon")
vrshl_u16 :: #force_inline proc "c" (a: uint16x4_t, b: int16x4_t) -> uint16x4_t {
	return _vrshl_u16(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_s32)
@(require_results, enable_target_feature = "neon")
vrshl_s32 :: #force_inline proc "c" (a: int32x2_t, b: int32x2_t) -> int32x2_t {
	return _vrshl_s32(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_u32)
@(require_results, enable_target_feature = "neon")
vrshl_u32 :: #force_inline proc "c" (a: uint32x2_t, b: int32x2_t) -> uint32x2_t {
	return _vrshl_u32(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_s64)
@(require_results, enable_target_feature = "neon")
vrshl_s64 :: #force_inline proc "c" (a: int64x1_t, b: int64x1_t) -> int64x1_t {
	return _vrshl_s64(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshl_u64)
@(require_results, enable_target_feature = "neon")
vrshl_u64 :: #force_inline proc "c" (a: uint64x1_t, b: int64x1_t) -> uint64x1_t {
	return _vrshl_u64(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_s8)
@(require_results, enable_target_feature = "neon")
vrshlq_s8 :: #force_inline proc "c" (a: int8x16_t, b: int8x16_t) -> int8x16_t {
	return _vrshlq_s8(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_u8)
@(require_results, enable_target_feature = "neon")
vrshlq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: int8x16_t) -> uint8x16_t {
	return _vrshlq_u8(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_s16)
@(require_results, enable_target_feature = "neon")
vrshlq_s16 :: #force_inline proc "c" (a: int16x8_t, b: int16x8_t) -> int16x8_t {
	return _vrshlq_s16(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_u16)
@(require_results, enable_target_feature = "neon")
vrshlq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: int16x8_t) -> uint16x8_t {
	return _vrshlq_u16(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_s32)
@(require_results, enable_target_feature = "neon")
vrshlq_s32 :: #force_inline proc "c" (a: int32x4_t, b: int32x4_t) -> int32x4_t {
	return _vrshlq_s32(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_u32)
@(require_results, enable_target_feature = "neon")
vrshlq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: int32x4_t) -> uint32x4_t {
	return _vrshlq_u32(a, b)
}

// Signed Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_s64)
@(require_results, enable_target_feature = "neon")
vrshlq_s64 :: #force_inline proc "c" (a: int64x2_t, b: int64x2_t) -> int64x2_t {
	return _vrshlq_s64(a, b)
}

// Unsigned Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshlq_u64)
@(require_results, enable_target_feature = "neon")
vrshlq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: int64x2_t) -> uint64x2_t {
	return _vrshlq_u64(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_s8)
@(require_results, enable_target_feature = "neon")
vqshl_s8 :: #force_inline proc "c" (a: int8x8_t, b: int8x8_t) -> int8x8_t {
	return _vqshl_s8(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_u8)
@(require_results, enable_target_feature = "neon")
vqshl_u8 :: #force_inline proc "c" (a: uint8x8_t, b: int8x8_t) -> uint8x8_t {
	return _vqshl_u8(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_s16)
@(require_results, enable_target_feature = "neon")
vqshl_s16 :: #force_inline proc "c" (a: int16x4_t, b: int16x4_t) -> int16x4_t {
	return _vqshl_s16(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_u16)
@(require_results, enable_target_feature = "neon")
vqshl_u16 :: #force_inline proc "c" (a: uint16x4_t, b: int16x4_t) -> uint16x4_t {
	return _vqshl_u16(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_s32)
@(require_results, enable_target_feature = "neon")
vqshl_s32 :: #force_inline proc "c" (a: int32x2_t, b: int32x2_t) -> int32x2_t {
	return _vqshl_s32(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_u32)
@(require_results, enable_target_feature = "neon")
vqshl_u32 :: #force_inline proc "c" (a: uint32x2_t, b: int32x2_t) -> uint32x2_t {
	return _vqshl_u32(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_s64)
@(require_results, enable_target_feature = "neon")
vqshl_s64 :: #force_inline proc "c" (a: int64x1_t, b: int64x1_t) -> int64x1_t {
	return _vqshl_s64(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_u64)
@(require_results, enable_target_feature = "neon")
vqshl_u64 :: #force_inline proc "c" (a: uint64x1_t, b: int64x1_t) -> uint64x1_t {
	return _vqshl_u64(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_s8)
@(require_results, enable_target_feature = "neon")
vqshlq_s8 :: #force_inline proc "c" (a: int8x16_t, b: int8x16_t) -> int8x16_t {
	return _vqshlq_s8(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_u8)
@(require_results, enable_target_feature = "neon")
vqshlq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: int8x16_t) -> uint8x16_t {
	return _vqshlq_u8(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_s16)
@(require_results, enable_target_feature = "neon")
vqshlq_s16 :: #force_inline proc "c" (a: int16x8_t, b: int16x8_t) -> int16x8_t {
	return _vqshlq_s16(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_u16)
@(require_results, enable_target_feature = "neon")
vqshlq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: int16x8_t) -> uint16x8_t {
	return _vqshlq_u16(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_s32)
@(require_results, enable_target_feature = "neon")
vqshlq_s32 :: #force_inline proc "c" (a: int32x4_t, b: int32x4_t) -> int32x4_t {
	return _vqshlq_s32(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_u32)
@(require_results, enable_target_feature = "neon")
vqshlq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: int32x4_t) -> uint32x4_t {
	return _vqshlq_u32(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_s64)
@(require_results, enable_target_feature = "neon")
vqshlq_s64 :: #force_inline proc "c" (a: int64x2_t, b: int64x2_t) -> int64x2_t {
	return _vqshlq_s64(a, b)
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_u64)
@(require_results, enable_target_feature = "neon")
vqshlq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: int64x2_t) -> uint64x2_t {
	return _vqshlq_u64(a, b)
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_s8)
@(require_results, enable_target_feature = "neon")
vqshl_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> int8x8_t where 0 <= N, N < 8 {
	return vqshl_s8(v, int8x8_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_u8)
@(require_results, enable_target_feature = "neon")
vqshl_n_u8 :: #force_inline proc "c" (v: uint8x8_t, $N: int32_t) -> uint8x8_t where 0 <= N, N < 8 {
	return vqshl_u8(v, int8x8_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_s16)
@(require_results, enable_target_feature = "neon")
vqshl_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> int16x4_t where 0 <= N, N < 16 {
	return vqshl_s16(v, int16x4_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_u16)
@(require_results, enable_target_feature = "neon")
vqshl_n_u16 :: #force_inline proc "c" (v: uint16x4_t, $N: int32_t) -> uint16x4_t where 0 <= N, N < 16 {
	return vqshl_u16(v, int16x4_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_s32)
@(require_results, enable_target_feature = "neon")
vqshl_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> int32x2_t where 0 <= N, N < 32 {
	return vqshl_s32(v, int32x2_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_u32)
@(require_results, enable_target_feature = "neon")
vqshl_n_u32 :: #force_inline proc "c" (v: uint32x2_t, $N: int32_t) -> uint32x2_t where 0 <= N, N < 32 {
	return vqshl_u32(v, int32x2_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_s64)
@(require_results, enable_target_feature = "neon")
vqshl_n_s64 :: #force_inline proc "c" (v: int64x1_t, $N: int32_t) -> int64x1_t where 0 <= N, N < 64 {
	return vqshl_s64(v, int64x1_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshl_n_u64)
@(require_results, enable_target_feature = "neon")
vqshl_n_u64 :: #force_inline proc "c" (v: uint64x1_t, $N: int32_t) -> uint64x1_t where 0 <= N, N < 64 {
	return vqshl_u64(v, int64x1_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_s8)
@(require_results, enable_target_feature = "neon")
vqshlq_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> int8x16_t where 0 <= N, N < 8 {
	return vqshlq_s8(v, int8x16_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_u8)
@(require_results, enable_target_feature = "neon")
vqshlq_n_u8 :: #force_inline proc "c" (v: uint8x16_t, $N: int32_t) -> uint8x16_t where 0 <= N, N < 8 {
	return vqshlq_u8(v, int8x16_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_s16)
@(require_results, enable_target_feature = "neon")
vqshlq_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> int16x8_t where 0 <= N, N < 16 {
	return vqshlq_s16(v, int16x8_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_u16)
@(require_results, enable_target_feature = "neon")
vqshlq_n_u16 :: #force_inline proc "c" (v: uint16x8_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 16 {
	return vqshlq_u16(v, int16x8_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_s32)
@(require_results, enable_target_feature = "neon")
vqshlq_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> int32x4_t where 0 <= N, N < 32 {
	return vqshlq_s32(v, int32x4_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_u32)
@(require_results, enable_target_feature = "neon")
vqshlq_n_u32 :: #force_inline proc "c" (v: uint32x4_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 32 {
	return vqshlq_u32(v, int32x4_t(N))
}

// Signed Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_s64)
@(require_results, enable_target_feature = "neon")
vqshlq_n_s64 :: #force_inline proc "c" (v: int64x2_t, $N: int32_t) -> int64x2_t where 0 <= N, N < 64 {
	return vqshlq_s64(v, int64x2_t(N))
}

// Unsigned Saturating Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlq_n_u64)
@(require_results, enable_target_feature = "neon")
vqshlq_n_u64 :: #force_inline proc "c" (v: uint64x2_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 64 {
	return vqshlq_u64(v, int64x2_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlu_n_s8)
@(require_results, enable_target_feature = "neon")
vqshlu_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> uint8x8_t where 0 <= N, N < 8 {
	return _vqshlu_n_s8(v, int8x8_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlu_n_s16)
@(require_results, enable_target_feature = "neon")
vqshlu_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> uint16x4_t where 0 <= N, N < 16 {
	return _vqshlu_n_s16(v, int16x4_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlu_n_s32)
@(require_results, enable_target_feature = "neon")
vqshlu_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> uint32x2_t where 0 <= N, N < 32 {
	return _vqshlu_n_s32(v, int32x2_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlu_n_s64)
@(require_results, enable_target_feature = "neon")
vqshlu_n_s64 :: #force_inline proc "c" (v: int64x1_t, $N: int32_t) -> uint64x1_t where 0 <= N, N < 64 {
	return _vqshlu_n_s64(v, int64x1_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshluq_n_s8)
@(require_results, enable_target_feature = "neon")
vqshluq_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> uint8x16_t where 0 <= N, N < 8 {
	return _vqshluq_n_s8(v, int8x16_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshluq_n_s16)
@(require_results, enable_target_feature = "neon")
vqshluq_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 16 {
	return _vqshluq_n_s16(v, int16x8_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshluq_n_s32)
@(require_results, enable_target_feature = "neon")
vqshluq_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 32 {
	return _vqshluq_n_s32(v, int32x4_t(N))
}

// Signed Saturating Shift Left Unsigned.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshluq_n_s64)
@(require_results, enable_target_feature = "neon")
vqshluq_n_s64 :: #force_inline proc "c" (v: int64x2_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 64 {
	return _vqshluq_n_s64(v, int64x2_t(N))
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_s8)
@(require_results, enable_target_feature = "neon")
vqrshl_s8 :: #force_inline proc "c" (a: int8x8_t, b: int8x8_t) -> int8x8_t {
	return _vqrshl_s8(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_u8)
@(require_results, enable_target_feature = "neon")
vqrshl_u8 :: #force_inline proc "c" (a: uint8x8_t, b: int8x8_t) -> uint8x8_t {
	return _vqrshl_u8(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_s16)
@(require_results, enable_target_feature = "neon")
vqrshl_s16 :: #force_inline proc "c" (a: int16x4_t, b: int16x4_t) -> int16x4_t {
	return _vqrshl_s16(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_u16)
@(require_results, enable_target_feature = "neon")
vqrshl_u16 :: #force_inline proc "c" (a: uint16x4_t, b: int16x4_t) -> uint16x4_t {
	return _vqrshl_u16(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_s32)
@(require_results, enable_target_feature = "neon")
vqrshl_s32 :: #force_inline proc "c" (a: int32x2_t, b: int32x2_t) -> int32x2_t {
	return _vqrshl_s32(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_u32)
@(require_results, enable_target_feature = "neon")
vqrshl_u32 :: #force_inline proc "c" (a: uint32x2_t, b: int32x2_t) -> uint32x2_t {
	return _vqrshl_u32(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_s64)
@(require_results, enable_target_feature = "neon")
vqrshl_s64 :: #force_inline proc "c" (a: int64x1_t, b: int64x1_t) -> int64x1_t {
	return _vqrshl_s64(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshl_u64)
@(require_results, enable_target_feature = "neon")
vqrshl_u64 :: #force_inline proc "c" (a: uint64x1_t, b: int64x1_t) -> uint64x1_t {
	return _vqrshl_u64(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_s8)
@(require_results, enable_target_feature = "neon")
vqrshlq_s8 :: #force_inline proc "c" (a: int8x16_t, b: int8x16_t) -> int8x16_t {
	return _vqrshlq_s8(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_u8)
@(require_results, enable_target_feature = "neon")
vqrshlq_u8 :: #force_inline proc "c" (a: uint8x16_t, b: int8x16_t) -> uint8x16_t {
	return _vqrshlq_u8(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_s16)
@(require_results, enable_target_feature = "neon")
vqrshlq_s16 :: #force_inline proc "c" (a: int16x8_t, b: int16x8_t) -> int16x8_t {
	return _vqrshlq_s16(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_u16)
@(require_results, enable_target_feature = "neon")
vqrshlq_u16 :: #force_inline proc "c" (a: uint16x8_t, b: int16x8_t) -> uint16x8_t {
	return _vqrshlq_u16(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_s32)
@(require_results, enable_target_feature = "neon")
vqrshlq_s32 :: #force_inline proc "c" (a: int32x4_t, b: int32x4_t) -> int32x4_t {
	return _vqrshlq_s32(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_u32)
@(require_results, enable_target_feature = "neon")
vqrshlq_u32 :: #force_inline proc "c" (a: uint32x4_t, b: int32x4_t) -> uint32x4_t {
	return _vqrshlq_u32(a, b)
}

// Signed Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_s64)
@(require_results, enable_target_feature = "neon")
vqrshlq_s64 :: #force_inline proc "c" (a: int64x2_t, b: int64x2_t) -> int64x2_t {
	return _vqrshlq_s64(a, b)
}

// Unsigned Saturating Rounding Shift Left.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlq_u64)
@(require_results, enable_target_feature = "neon")
vqrshlq_u64 :: #force_inline proc "c" (a: uint64x2_t, b: int64x2_t) -> uint64x2_t {
	return _vqrshlq_u64(a, b)
}

// Signed Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_s8)
@(require_results, enable_target_feature = "neon")
vshll_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> int16x8_t where 0 <= N, N < 8 {
	return simd.shl(cast(int16x8_t)v, uint16x8_t(N))
}

// Unsigned Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_u8)
@(require_results, enable_target_feature = "neon")
vshll_n_u8 :: #force_inline proc "c" (v: uint8x8_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 8 {
	return simd.shl(cast(uint16x8_t)v, uint16x8_t(N))
}

// Signed Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_s16)
@(require_results, enable_target_feature = "neon")
vshll_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> int32x4_t where 0 <= N, N < 16 {
	return simd.shl(cast(int32x4_t)v, uint32x4_t(N))
}

// Unsigned Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_u16)
@(require_results, enable_target_feature = "neon")
vshll_n_u16 :: #force_inline proc "c" (v: uint16x4_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 16 {
	return simd.shl(cast(uint32x4_t)v, uint32x4_t(N))
}

// Signed Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_s32)
@(require_results, enable_target_feature = "neon")
vshll_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> int64x2_t where 0 <= N, N < 32 {
	return simd.shl(cast(int64x2_t)v, uint64x2_t(N))
}

// Unsigned Shift Left Long.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_n_u32)
@(require_results, enable_target_feature = "neon")
vshll_n_u32 :: #force_inline proc "c" (v: uint32x2_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 32 {
	return simd.shl(cast(uint64x2_t)v, uint64x2_t(N))
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_s8)
@(require_results, enable_target_feature = "neon")
vget_high_s8 :: #force_inline proc "c" (a: int8x16_t) -> int8x8_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 8, 9, 10, 11, 12, 13, 14, 15)
	} else {
		a := simd.shuffle(a, a, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 8, 9, 10, 11, 12, 13, 14, 15)
		return simd.shuffle(b, b, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_u8)
@(require_results, enable_target_feature = "neon")
vget_high_u8 :: #force_inline proc "c" (a: uint8x16_t) -> uint8x8_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 8, 9, 10, 11, 12, 13, 14, 15)
	} else {
		a := simd.shuffle(a, a, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 8, 9, 10, 11, 12, 13, 14, 15)
		return simd.shuffle(b, b, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_s16)
@(require_results, enable_target_feature = "neon")
vget_high_s16 :: #force_inline proc "c" (a: int16x8_t) -> int16x4_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 4, 5, 6, 7)
	} else {
		a := simd.shuffle(a, a, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 4, 5, 6, 7)
		return simd.shuffle(b, b, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_u16)
@(require_results, enable_target_feature = "neon")
vget_high_u16 :: #force_inline proc "c" (a: uint16x8_t) -> uint16x4_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 4, 5, 6, 7)
	} else {
		a := simd.shuffle(a, a, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 4, 5, 6, 7)
		return simd.shuffle(b, b, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_s32)
@(require_results, enable_target_feature = "neon")
vget_high_s32 :: #force_inline proc "c" (a: int32x4_t) -> int32x2_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 2, 3)
	} else {
		a := simd.shuffle(a, a, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 2, 3)
		return simd.shuffle(b, b, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_u32)
@(require_results, enable_target_feature = "neon")
vget_high_u32 :: #force_inline proc "c" (a: uint32x4_t) -> uint32x2_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 2, 3)
	} else {
		a := simd.shuffle(a, a, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 2, 3)
		return simd.shuffle(b, b, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_s64)
@(require_results, enable_target_feature = "neon")
vget_high_s64 :: #force_inline proc "c" (a: int64x2_t) -> int64x1_t {
	when ODIN_ENDIAN == .Little {
		return transmute(int64x1_t)simd.extract(a, 1)
	} else {
		a := simd.shuffle(a, a, 1, 0)
		return transmute(int64x1_t)simd.extract(a, 1)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_u64)
@(require_results, enable_target_feature = "neon")
vget_high_u64 :: #force_inline proc "c" (a: uint64x2_t) -> uint64x1_t {
	when ODIN_ENDIAN == .Little {
		return transmute(uint64x1_t)simd.extract(a, 1)
	} else {
		a := simd.shuffle(a, a, 1, 0)
		return transmute(uint64x1_t)simd.extract(a, 1)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_s8)
@(require_results, enable_target_feature = "neon")
vsli_n_s8 :: #force_inline proc "c" (a, b: int8x8_t, $N: int32_t) -> int8x8_t where 0 <= N, N < 8 {
	when ODIN_ARCH == .arm64 {
		return _vsli_n_s8(a, b, N)
	} else {
		return _vshiftlins_v8i8(a, b, int8x8_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_u8)
@(require_results, enable_target_feature = "neon")
vsli_n_u8 :: #force_inline proc "c" (a, b: uint8x8_t, $N: int32_t) -> uint8x8_t where 0 <= N, N < 8 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint8x8_t)_vsli_n_s8(
			transmute(int8x8_t)a,
			transmute(int8x8_t)b,
			N,
		)
	} else {
		return transmute(uint8x8_t)_vshiftlins_v8i8(
			transmute(int8x8_t)a,
			transmute(int8x8_t)b,
			int8x8_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_s16)
@(require_results, enable_target_feature = "neon")
vsli_n_s16 :: #force_inline proc "c" (a, b: int16x4_t, $N: int32_t) -> int16x4_t where 0 <= N, N < 16 {
	when ODIN_ARCH == .arm64 {
		return _vsli_n_s16(a, b, N)
	} else {
		return _vshiftlins_v4i16(a, b, int16x4_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_u16)
@(require_results, enable_target_feature = "neon")
vsli_n_u16 :: #force_inline proc "c" (a, b: uint16x4_t, $N: int32_t) -> uint16x4_t where 0 <= N, N < 16 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint16x4_t)_vsli_n_s16(
			transmute(int16x4_t)a,
			transmute(int16x4_t)b,
			N,
		)
	} else {
		return transmute(uint16x4_t)_vshiftlins_v4i16(
			transmute(int16x4_t)a,
			transmute(int16x4_t)b,
			int16x4_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_s32)
@(require_results, enable_target_feature = "neon")
vsli_n_s32 :: #force_inline proc "c" (a, b: int32x2_t, $N: int32_t) -> int32x2_t where 0 <= N, N < 32 {
	when ODIN_ARCH == .arm64 {
		return _vsli_n_s32(a, b, N)
	} else {
		return _vshiftlins_v2i32(a, b, int32x2_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_u32)
@(require_results, enable_target_feature = "neon")
vsli_n_u32 :: #force_inline proc "c" (a, b: uint32x2_t, $N: int32_t) -> uint32x2_t where 0 <= N, N < 32 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint32x2_t)_vsli_n_s32(
			transmute(int32x2_t)a,
			transmute(int32x2_t)b,
			N,
		)
	} else {
		return transmute(uint32x2_t)_vshiftlins_v2i32(
			transmute(int32x2_t)a,
			transmute(int32x2_t)b,
			int32x2_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_s64)
@(require_results, enable_target_feature = "neon")
vsli_n_s64 :: #force_inline proc "c" (a, b: int64x1_t, $N: int32_t) -> int64x1_t where 0 <= N, N < 64 {
	when ODIN_ARCH == .arm64 {
		return _vsli_n_s64(a, b, N)
	} else {
		return _vshiftlins_v1i64(a, b, int64x1_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsli_n_u64)
@(require_results, enable_target_feature = "neon")
vsli_n_u64 :: #force_inline proc "c" (a, b: uint64x1_t, $N: int32_t) -> uint64x1_t where 0 <= N, N < 64 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint64x1_t)_vsli_n_s64(
			transmute(int64x1_t)a,
			transmute(int64x1_t)b,
			N,
		)
	} else {
		return transmute(uint64x1_t)_vshiftlins_v1i64(
			transmute(int64x1_t)a,
			transmute(int64x1_t)b,
			int64x1_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_s8)
@(require_results, enable_target_feature = "neon")
vsliq_n_s8 :: #force_inline proc "c" (a, b: int8x16_t, $N: int32_t) -> int8x16_t where 0 <= N, N < 8 {
	when ODIN_ARCH == .arm64 {
		return _vsliq_n_s8(a, b, N)
	} else {
		return _vshiftlins_v16i8(a, b, int8x16_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_u8)
@(require_results, enable_target_feature = "neon")
vsliq_n_u8 :: #force_inline proc "c" (a, b: uint8x16_t, $N: int32_t) -> uint8x16_t where 0 <= N, N < 8 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint8x16_t)_vsliq_n_s8(
			transmute(int8x16_t)a,
			transmute(int8x16_t)b,
			N,
		)
	} else {
		return transmute(uint8x16_t)_vshiftlins_v16i8(
			transmute(int8x16_t)a,
			transmute(int8x16_t)b,
			int8x16_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_s16)
@(require_results, enable_target_feature = "neon")
vsliq_n_s16 :: #force_inline proc "c" (a, b: int16x8_t, $N: int32_t) -> int16x8_t where 0 <= N, N < 16 {
	when ODIN_ARCH == .arm64 {
		return _vsliq_n_s16(a, b, N)
	} else {
		return _vshiftlins_v8i16(a, b, int16x8_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_u16)
@(require_results, enable_target_feature = "neon")
vsliq_n_u16 :: #force_inline proc "c" (a, b: uint16x8_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 16 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint16x8_t)_vsliq_n_s16(
			transmute(int16x8_t)a,
			transmute(int16x8_t)b,
			N,
		)
	} else {
		return transmute(uint16x8_t)_vshiftlins_v8i16(
			transmute(int16x8_t)a,
			transmute(int16x8_t)b,
			int16x8_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_s32)
@(require_results, enable_target_feature = "neon")
vsliq_n_s32 :: #force_inline proc "c" (a, b: int32x4_t, $N: int32_t) -> int32x4_t where 0 <= N, N < 32 {
	when ODIN_ARCH == .arm64 {
		return _vsliq_n_s32(a, b, N)
	} else {
		return _vshiftlins_v4i32(a, b, int32x4_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_u32)
@(require_results, enable_target_feature = "neon")
vsliq_n_u32 :: #force_inline proc "c" (a, b: uint32x4_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 32 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint32x4_t)_vsliq_n_s32(
			transmute(int32x4_t)a,
			transmute(int32x4_t)b,
			N,
		)
	} else {
		return transmute(uint32x4_t)_vshiftlins_v4i32(
			transmute(int32x4_t)a,
			transmute(int32x4_t)b,
			int32x4_t(N),
		)
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_s64)
@(require_results, enable_target_feature = "neon")
vsliq_n_s64 :: #force_inline proc "c" (a, b: int64x2_t, $N: int32_t) -> int64x2_t where 0 <= N, N < 64 {
	when ODIN_ARCH == .arm64 {
		return _vsliq_n_s64(a, b, N)
	} else {
		return _vshiftlins_v2i64(a, b, int64x2_t(N))
	}
}

// Shift Left and Insert.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsliq_n_u64)
@(require_results, enable_target_feature = "neon")
vsliq_n_u64 :: #force_inline proc "c" (a, b: uint64x2_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 64 {
	when ODIN_ARCH == .arm64 {
		return transmute(uint64x2_t)_vsliq_n_s64(
			transmute(int64x2_t)a,
			transmute(int64x2_t)b,
			N,
		)
	} else {
		return transmute(uint64x2_t)_vshiftlins_v2i64(
			transmute(int64x2_t)a,
			transmute(int64x2_t)b,
			int64x2_t(N),
		)
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_s8)
@(require_results, enable_target_feature = "neon")
vshr_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> int8x8_t where 1 <= N, N <= 8 {
	when N == 8 { M :: 7 } else { M :: N }
	return simd.shr(v, uint8x8_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_u8)
@(require_results, enable_target_feature = "neon")
vshr_n_u8 :: #force_inline proc "c" (v: uint8x8_t, $N: int32_t) -> uint8x8_t where 1 <= N, N <= 8 {
	when N == 8 {
		return uint8x8_t(0)
	} else {
		return simd.shr(v, uint8x8_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_s16)
@(require_results, enable_target_feature = "neon")
vshr_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> int16x4_t where 1 <= N, N <= 16 {
	when N == 16 { M :: 15 } else { M :: N }
	return simd.shr(v, uint16x4_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_u16)
@(require_results, enable_target_feature = "neon")
vshr_n_u16 :: #force_inline proc "c" (v: uint16x4_t, $N: int32_t) -> uint16x4_t where 1 <= N, N <= 16 {
	when N == 16 {
		return uint16x4_t(0)
	} else {
		return simd.shr(v, uint16x4_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_s32)
@(require_results, enable_target_feature = "neon")
vshr_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> int32x2_t where 1 <= N, N <= 32 {
	when N == 32 { M :: 31 } else { M :: N }
	return simd.shr(v, uint32x2_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_u32)
@(require_results, enable_target_feature = "neon")
vshr_n_u32 :: #force_inline proc "c" (v: uint32x2_t, $N: int32_t) -> uint32x2_t where 1 <= N, N <= 32 {
	when N == 32 {
		return uint32x2_t(0)
	} else {
		return simd.shr(v, uint32x2_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_s64)
@(require_results, enable_target_feature = "neon")
vshr_n_s64 :: #force_inline proc "c" (v: int64x1_t, $N: int32_t) -> int64x1_t where 1 <= N, N <= 64 {
	when N == 64 { M :: 63 } else { M :: N }
	return simd.shr(v, uint64x1_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshr_n_u64)
@(require_results, enable_target_feature = "neon")
vshr_n_u64 :: #force_inline proc "c" (v: uint64x1_t, $N: int32_t) -> uint64x1_t where 1 <= N, N <= 64 {
	when N == 64 {
		return uint64x1_t(0)
	} else {
		return simd.shr(v, uint64x1_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_s8)
@(require_results, enable_target_feature = "neon")
vshrq_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> int8x16_t where 1 <= N, N <= 8 {
	when N == 8 { M :: 7 } else { M :: N }
	return simd.shr(v, uint8x16_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_u8)
@(require_results, enable_target_feature = "neon")
vshrq_n_u8 :: #force_inline proc "c" (v: uint8x16_t, $N: int32_t) -> uint8x16_t where 1 <= N, N <= 8 {
	when N == 8 {
		return uint8x16_t(0)
	} else {
		return simd.shr(v, uint8x16_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_s16)
@(require_results, enable_target_feature = "neon")
vshrq_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> int16x8_t where 1 <= N, N <= 16 {
	when N == 16 { M :: 15 } else { M :: N }
	return simd.shr(v, uint16x8_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_u16)
@(require_results, enable_target_feature = "neon")
vshrq_n_u16 :: #force_inline proc "c" (v: uint16x8_t, $N: int32_t) -> uint16x8_t where 1 <= N, N <= 16 {
	when N == 16 {
		return uint16x8_t(0)
	} else {
		return simd.shr(v, uint16x8_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_s32)
@(require_results, enable_target_feature = "neon")
vshrq_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> int32x4_t where 1 <= N, N <= 32 {
	when N == 32 { M :: 31 } else { M :: N }
	return simd.shr(v, uint32x4_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_u32)
@(require_results, enable_target_feature = "neon")
vshrq_n_u32 :: #force_inline proc "c" (v: uint32x4_t, $N: int32_t) -> uint32x4_t where 1 <= N, N <= 32 {
	when N == 32 {
		return uint32x4_t(0)
	} else {
		return simd.shr(v, uint32x4_t(N))
	}
}

// Signed Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_s64)
@(require_results, enable_target_feature = "neon")
vshrq_n_s64 :: #force_inline proc "c" (v: int64x2_t, $N: int32_t) -> int64x2_t where 1 <= N, N <= 64 {
	when N == 64 { M :: 63 } else { M :: N }
	return simd.shr(v, uint64x2_t(M))
}

// Unsigned Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrq_n_u64)
@(require_results, enable_target_feature = "neon")
vshrq_n_u64 :: #force_inline proc "c" (v: uint64x2_t, $N: int32_t) -> uint64x2_t where 1 <= N, N <= 64 {
	when N == 64 {
		return uint64x2_t(0)
	} else {
		return simd.shr(v, uint64x2_t(N))
	}
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_s8)
@(require_results, enable_target_feature = "neon")
vrshr_n_s8 :: #force_inline proc "c" (v: int8x8_t, $N: int32_t) -> int8x8_t where 1 <= N, N <= 8 {
	return vrshl_s8(v, int8x8_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_u8)
@(require_results, enable_target_feature = "neon")
vrshr_n_u8 :: #force_inline proc "c" (v: uint8x8_t, $N: int32_t) -> uint8x8_t where 1 <= N, N <= 8 {
	return vrshl_u8(v, int8x8_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_s16)
@(require_results, enable_target_feature = "neon")
vrshr_n_s16 :: #force_inline proc "c" (v: int16x4_t, $N: int32_t) -> int16x4_t where 1 <= N, N <= 16 {
	return vrshl_s16(v, int16x4_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_u16)
@(require_results, enable_target_feature = "neon")
vrshr_n_u16 :: #force_inline proc "c" (v: uint16x4_t, $N: int32_t) -> uint16x4_t where 1 <= N, N <= 16 {
	return vrshl_u16(v, int16x4_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_s32)
@(require_results, enable_target_feature = "neon")
vrshr_n_s32 :: #force_inline proc "c" (v: int32x2_t, $N: int32_t) -> int32x2_t where 1 <= N, N <= 32 {
	return vrshl_s32(v, int32x2_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_u32)
@(require_results, enable_target_feature = "neon")
vrshr_n_u32 :: #force_inline proc "c" (v: uint32x2_t, $N: int32_t) -> uint32x2_t where 1 <= N, N <= 32 {
	return vrshl_u32(v, int32x2_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_s64)
@(require_results, enable_target_feature = "neon")
vrshr_n_s64 :: #force_inline proc "c" (v: int64x1_t, $N: int32_t) -> int64x1_t where 1 <= N, N <= 64 {
	return vrshl_s64(v, int64x1_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshr_n_u64)
@(require_results, enable_target_feature = "neon")
vrshr_n_u64 :: #force_inline proc "c" (v: uint64x1_t, $N: int32_t) -> uint64x1_t where 1 <= N, N <= 64 {
	return vrshl_u64(v, int64x1_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_s8)
@(require_results, enable_target_feature = "neon")
vrshrq_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> int8x16_t where 1 <= N, N <= 8 {
	return vrshlq_s8(v, int8x16_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_u8)
@(require_results, enable_target_feature = "neon")
vrshrq_n_u8 :: #force_inline proc "c" (v: uint8x16_t, $N: int32_t) -> uint8x16_t where 1 <= N, N <= 8 {
	return vrshlq_u8(v, int8x16_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_s16)
@(require_results, enable_target_feature = "neon")
vrshrq_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> int16x8_t where 1 <= N, N <= 16 {
	return vrshlq_s16(v, int16x8_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_u16)
@(require_results, enable_target_feature = "neon")
vrshrq_n_u16 :: #force_inline proc "c" (v: uint16x8_t, $N: int32_t) -> uint16x8_t where 1 <= N, N <= 16 {
	return vrshlq_u16(v, int16x8_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_s32)
@(require_results, enable_target_feature = "neon")
vrshrq_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> int32x4_t where 1 <= N, N <= 32 {
	return vrshlq_s32(v, int32x4_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_u32)
@(require_results, enable_target_feature = "neon")
vrshrq_n_u32 :: #force_inline proc "c" (v: uint32x4_t, $N: int32_t) -> uint32x4_t where 1 <= N, N <= 32 {
	return vrshlq_u32(v, int32x4_t(-N))
}

// Signed Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_s64)
@(require_results, enable_target_feature = "neon")
vrshrq_n_s64 :: #force_inline proc "c" (v: int64x2_t, $N: int32_t) -> int64x2_t where 1 <= N, N <= 64 {
	return vrshlq_s64(v, int64x2_t(-N))
}

// Unsigned Rounding Shift Right.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrq_n_u64)
@(require_results, enable_target_feature = "neon")
vrshrq_n_u64 :: #force_inline proc "c" (v: uint64x2_t, $N: int32_t) -> uint64x2_t where 1 <= N, N <= 64 {
	return vrshlq_u64(v, int64x2_t(-N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_s8)
@(require_results, enable_target_feature = "neon")
vsra_n_s8 :: #force_inline proc "c" (a, b: int8x8_t, $N: int32_t) -> int8x8_t where 1 <= N, N <= 8 {
	return simd.add(a, vshr_n_s8(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_u8)
@(require_results, enable_target_feature = "neon")
vsra_n_u8 :: #force_inline proc "c" (a, b: uint8x8_t, $N: int32_t) -> uint8x8_t where 1 <= N, N <= 8 {
	return simd.add(a, vshr_n_u8(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_s16)
@(require_results, enable_target_feature = "neon")
vsra_n_s16 :: #force_inline proc "c" (a, b: int16x4_t, $N: int32_t) -> int16x4_t where 1 <= N, N <= 16 {
	return simd.add(a, vshr_n_s16(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_u16)
@(require_results, enable_target_feature = "neon")
vsra_n_u16 :: #force_inline proc "c" (a, b: uint16x4_t, $N: int32_t) -> uint16x4_t where 1 <= N, N <= 16 {
	return simd.add(a, vshr_n_u16(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_s32)
@(require_results, enable_target_feature = "neon")
vsra_n_s32 :: #force_inline proc "c" (a, b: int32x2_t, $N: int32_t) -> int32x2_t where 1 <= N, N <= 32 {
	return simd.add(a, vshr_n_s32(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_u32)
@(require_results, enable_target_feature = "neon")
vsra_n_u32 :: #force_inline proc "c" (a, b: uint32x2_t, $N: int32_t) -> uint32x2_t where 1 <= N, N <= 32 {
	return simd.add(a, vshr_n_u32(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_s64)
@(require_results, enable_target_feature = "neon")
vsra_n_s64 :: #force_inline proc "c" (a, b: int64x1_t, $N: int32_t) -> int64x1_t where 1 <= N, N <= 64 {
	return simd.add(a, vshr_n_s64(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsra_n_u64)
@(require_results, enable_target_feature = "neon")
vsra_n_u64 :: #force_inline proc "c" (a, b: uint64x1_t, $N: int32_t) -> uint64x1_t where 1 <= N, N <= 64 {
	return simd.add(a, vshr_n_u64(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_s8)
@(require_results, enable_target_feature = "neon")
vsraq_n_s8 :: #force_inline proc "c" (a, b: int8x16_t, $N: int32_t) -> int8x16_t where 1 <= N, N <= 8 {
	return simd.add(a, vshrq_n_s8(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_u8)
@(require_results, enable_target_feature = "neon")
vsraq_n_u8 :: #force_inline proc "c" (a, b: uint8x16_t, $N: int32_t) -> uint8x16_t where 1 <= N, N <= 8 {
	return simd.add(a, vshrq_n_u8(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_s16)
@(require_results, enable_target_feature = "neon")
vsraq_n_s16 :: #force_inline proc "c" (a, b: int16x8_t, $N: int32_t) -> int16x8_t where 1 <= N, N <= 16 {
	return simd.add(a, vshrq_n_s16(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_u16)
@(require_results, enable_target_feature = "neon")
vsraq_n_u16 :: #force_inline proc "c" (a, b: uint16x8_t, $N: int32_t) -> uint16x8_t where 1 <= N, N <= 16 {
	return simd.add(a, vshrq_n_u16(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_s32)
@(require_results, enable_target_feature = "neon")
vsraq_n_s32 :: #force_inline proc "c" (a, b: int32x4_t, $N: int32_t) -> int32x4_t where 1 <= N, N <= 32 {
	return simd.add(a, vshrq_n_s32(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_u32)
@(require_results, enable_target_feature = "neon")
vsraq_n_u32 :: #force_inline proc "c" (a, b: uint32x4_t, $N: int32_t) -> uint32x4_t where 1 <= N, N <= 32 {
	return simd.add(a, vshrq_n_u32(b, N))
}

// Signed Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_s64)
@(require_results, enable_target_feature = "neon")
vsraq_n_s64 :: #force_inline proc "c" (a, b: int64x2_t, $N: int32_t) -> int64x2_t where 1 <= N, N <= 64 {
	return simd.add(a, vshrq_n_s64(b, N))
}

// Unsigned Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsraq_n_u64)
@(require_results, enable_target_feature = "neon")
vsraq_n_u64 :: #force_inline proc "c" (a, b: uint64x2_t, $N: int32_t) -> uint64x2_t where 1 <= N, N <= 64 {
	return simd.add(a, vshrq_n_u64(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_s8)
@(require_results, enable_target_feature = "neon")
vrsra_n_s8 :: #force_inline proc "c" (a, b: int8x8_t, $N: int32_t) -> int8x8_t where 1 <= N, N <= 8 {
	return simd.add(a, vrshr_n_s8(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_u8)
@(require_results, enable_target_feature = "neon")
vrsra_n_u8 :: #force_inline proc "c" (a, b: uint8x8_t, $N: int32_t) -> uint8x8_t where 1 <= N, N <= 8 {
	return simd.add(a, vrshr_n_u8(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_s16)
@(require_results, enable_target_feature = "neon")
vrsra_n_s16 :: #force_inline proc "c" (a, b: int16x4_t, $N: int32_t) -> int16x4_t where 1 <= N, N <= 16 {
	return simd.add(a, vrshr_n_s16(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_u16)
@(require_results, enable_target_feature = "neon")
vrsra_n_u16 :: #force_inline proc "c" (a, b: uint16x4_t, $N: int32_t) -> uint16x4_t where 1 <= N, N <= 16 {
	return simd.add(a, vrshr_n_u16(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_s32)
@(require_results, enable_target_feature = "neon")
vrsra_n_s32 :: #force_inline proc "c" (a, b: int32x2_t, $N: int32_t) -> int32x2_t where 1 <= N, N <= 32 {
	return simd.add(a, vrshr_n_s32(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_u32)
@(require_results, enable_target_feature = "neon")
vrsra_n_u32 :: #force_inline proc "c" (a, b: uint32x2_t, $N: int32_t) -> uint32x2_t where 1 <= N, N <= 32 {
	return simd.add(a, vrshr_n_u32(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_s64)
@(require_results, enable_target_feature = "neon")
vrsra_n_s64 :: #force_inline proc "c" (a, b: int64x1_t, $N: int32_t) -> int64x1_t where 1 <= N, N <= 64 {
	return simd.add(a, vrshr_n_s64(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsra_n_u64)
@(require_results, enable_target_feature = "neon")
vrsra_n_u64 :: #force_inline proc "c" (a, b: uint64x1_t, $N: int32_t) -> uint64x1_t where 1 <= N, N <= 64 {
	return simd.add(a, vrshr_n_u64(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_s8)
@(require_results, enable_target_feature = "neon")
vrsraq_n_s8 :: #force_inline proc "c" (a, b: int8x16_t, $N: int32_t) -> int8x16_t where 1 <= N, N <= 8 {
	return simd.add(a, vrshrq_n_s8(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_u8)
@(require_results, enable_target_feature = "neon")
vrsraq_n_u8 :: #force_inline proc "c" (a, b: uint8x16_t, $N: int32_t) -> uint8x16_t where 1 <= N, N <= 8 {
	return simd.add(a, vrshrq_n_u8(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_s16)
@(require_results, enable_target_feature = "neon")
vrsraq_n_s16 :: #force_inline proc "c" (a, b: int16x8_t, $N: int32_t) -> int16x8_t where 1 <= N, N <= 16 {
	return simd.add(a, vrshrq_n_s16(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_u16)
@(require_results, enable_target_feature = "neon")
vrsraq_n_u16 :: #force_inline proc "c" (a, b: uint16x8_t, $N: int32_t) -> uint16x8_t where 1 <= N, N <= 16 {
	return simd.add(a, vrshrq_n_u16(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_s32)
@(require_results, enable_target_feature = "neon")
vrsraq_n_s32 :: #force_inline proc "c" (a, b: int32x4_t, $N: int32_t) -> int32x4_t where 1 <= N, N <= 32 {
	return simd.add(a, vrshrq_n_s32(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_u32)
@(require_results, enable_target_feature = "neon")
vrsraq_n_u32 :: #force_inline proc "c" (a, b: uint32x4_t, $N: int32_t) -> uint32x4_t where 1 <= N, N <= 32 {
	return simd.add(a, vrshrq_n_u32(b, N))
}

// Signed Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_s64)
@(require_results, enable_target_feature = "neon")
vrsraq_n_s64 :: #force_inline proc "c" (a, b: int64x2_t, $N: int32_t) -> int64x2_t where 1 <= N, N <= 64 {
	return simd.add(a, vrshrq_n_s64(b, N))
}

// Unsigned Rounding Shift Right and Accumulate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsraq_n_u64)
@(require_results, enable_target_feature = "neon")
vrsraq_n_u64 :: #force_inline proc "c" (a, b: uint64x2_t, $N: int32_t) -> uint64x2_t where 1 <= N, N <= 64 {
	return simd.add(a, vrshrq_n_u64(b, N))
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

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x16_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx1(v, t, idx)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx1(v, t, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x16_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbx1(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbx1(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1q_s8 :: #force_inline proc "c" (v: int8x16_t, t: int8x16_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx1q(v, t, idx)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx1q(v, t, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1q_u8 :: #force_inline proc "c" (v: uint8x16_t, t: uint8x16_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbx1q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbx1q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x16x2_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx2(v, t.x, t.y, idx)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx2(v, t.x, t.y, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x16x2_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbx2(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbx2(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2q_s8 :: #force_inline proc "c" (v: int8x16_t, t: int8x16x2_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx2q(v, t.x, t.y, idx)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx2q(v, t.x, t.y, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2q_u8 :: #force_inline proc "c" (v: uint8x16_t, t: uint8x16x2_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbx2q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbx2q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x16x3_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx3(v, t.x, t.y, t.z, idx)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx3(v, t.x, t.y, t.z, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x16x3_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbx3(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbx3(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3q_s8 :: #force_inline proc "c" (v: int8x16_t, t: int8x16x3_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx3q(v, t.x, t.y, t.z, idx)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx3q(v, t.x, t.y, t.z, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3q_u8 :: #force_inline proc "c" (v: uint8x16_t, t: uint8x16x3_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbx3q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbx3q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4_s8 :: #force_inline proc "c" (v: int8x8_t, t: int8x16x4_t, idx: uint8x8_t) -> int8x8_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx4(v, t.x, t.y, t.z, t.w, idx)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx4(v, t.x, t.y, t.z, t.w, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4_u8 :: #force_inline proc "c" (v: uint8x8_t, t: uint8x16x4_t, idx: uint8x8_t) -> uint8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x8_t)_vqtbx4(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x8_t)_vqtbx4(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4q_s8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4q_s8 :: #force_inline proc "c" (v: int8x16_t, t: int8x16x4_t, idx: uint8x16_t) -> int8x16_t {
		when ODIN_ENDIAN == .Little {
			return _vqtbx4q(v, t.x, t.y, t.z, t.w, idx)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := int8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := _vqtbx4q(v, t.x, t.y, t.z, t.w, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4q_u8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4q_u8 :: #force_inline proc "c" (v: uint8x16_t, t: uint8x16x4_t, idx: uint8x16_t) -> uint8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(uint8x16_t)_vqtbx4q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := uint8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(uint8x16_t)_vqtbx4q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vneg_s64)
	@(require_results, enable_target_feature = "neon")
	vneg_s64 :: #force_inline proc "c" (a: int64x1_t) -> int64x1_t {
		return simd.neg(a)
	}

	// Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vnegd_s64)
	@(require_results, enable_target_feature = "neon")
	vnegd_s64 :: #force_inline proc "c" (a: int64_t) -> int64_t {
		return -a
	}

	// Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vnegq_s64)
	@(require_results, enable_target_feature = "neon")
	vnegq_s64 :: #force_inline proc "c" (a: int64x2_t) -> int64x2_t {
		return simd.neg(a)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqneg_s64)
	@(require_results, enable_target_feature = "neon")
	vqneg_s64 :: #force_inline proc "c" (a: int64x1_t) -> int64x1_t {
		return _vqneg_s64(a)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegq_s64)
	@(require_results, enable_target_feature = "neon")
	vqnegq_s64 :: #force_inline proc "c" (a: int64x2_t) -> int64x2_t {
		return _vqnegq_s64(a)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegb_s8)
	@(require_results, enable_target_feature = "neon")
	vqnegb_s8 :: #force_inline proc "c" (a: int8_t) -> int8_t {
		return vget_lane_s8(vqneg_s8(vdup_n_s8(a)), 0)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegh_s16)
	@(require_results, enable_target_feature = "neon")
	vqnegh_s16 :: #force_inline proc "c" (a: int16_t) -> int16_t {
		return vget_lane_s16(vqneg_s16(vdup_n_s16(a)), 0)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegs_s32)
	@(require_results, enable_target_feature = "neon")
	vqnegs_s32 :: #force_inline proc "c" (a: int32_t) -> int32_t {
		return vget_lane_s32(vqneg_s32(vdup_n_s32(a)), 0)
	}

	// Signed saturating Negate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqnegd_s64)
	@(require_results, enable_target_feature = "neon")
	vqnegd_s64 :: #force_inline proc "c" (a: int64_t) -> int64_t {
		return vget_lane_s64(vqneg_s64(vdup_n_s64(a)), 0)
	}

	// Signed Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshld_n_s64)
	@(require_results, enable_target_feature = "neon")
	vshld_n_s64 :: #force_inline proc "c" (v: int64_t, $N: int32_t) -> int64_t where 0 <= N, N < 64 {
		return v << uint64_t(N)
	}

	// Unsigned Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshld_n_u64)
	@(require_results, enable_target_feature = "neon")
	vshld_n_u64 :: #force_inline proc "c" (v: uint64_t, $N: int32_t) -> uint64_t where 0 <= N, N < 64 {
		return v << uint64_t(N)
	}

	// Signed Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshld_s64)
	@(require_results, enable_target_feature = "neon")
	vshld_s64 :: #force_inline proc "c" (a: int64_t, b: int64_t) -> int64_t {
		return transmute(int64_t)vshl_s64(transmute(int64x1_t)a, transmute(int64x1_t)b)
	}

	// Unsigned Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshld_u64)
	@(require_results, enable_target_feature = "neon")
	vshld_u64 :: #force_inline proc "c" (a: uint64_t, b: int64_t) -> uint64_t {
		return transmute(uint64_t)vshl_u64(transmute(uint64x1_t)a, transmute(int64x1_t)b)
	}

	// Signed Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshld_s64)
	@(require_results, enable_target_feature = "neon")
	vrshld_s64 :: #force_inline proc "c" (a: int64_t, b: int64_t) -> int64_t {
		return _vrshld_s64(a, b)
	}

	// Unsigned Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshld_u64)
	@(require_results, enable_target_feature = "neon")
	vrshld_u64 :: #force_inline proc "c" (a: uint64_t, b: int64_t) -> uint64_t {
		return _vrshld_u64(a, b)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshld_s64)
	@(require_results, enable_target_feature = "neon")
	vqshld_s64 :: #force_inline proc "c" (a: int64_t, b: int64_t) -> int64_t {
		return _vqshld_s64(a, b)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshld_u64)
	@(require_results, enable_target_feature = "neon")
	vqshld_u64 :: #force_inline proc "c" (a: uint64_t, b: int64_t) -> uint64_t {
		return _vqshld_u64(a, b)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlb_s8)
	@(require_results, enable_target_feature = "neon")
	vqshlb_s8 :: #force_inline proc "c" (a: int8_t, b: int8_t) -> int8_t {
		c := vqshl_s8(int8x8_t(a), int8x8_t(b))
		return vget_lane_s8(c, 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlb_u8)
	@(require_results, enable_target_feature = "neon")
	vqshlb_u8 :: #force_inline proc "c" (a: uint8_t, b: int8_t) -> uint8_t {
		c := vqshl_u8(uint8x8_t(a), int8x8_t(b))
		return vget_lane_u8(c, 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlh_s16)
	@(require_results, enable_target_feature = "neon")
	vqshlh_s16 :: #force_inline proc "c" (a: int16_t, b: int16_t) -> int16_t {
		c := vqshl_s16(int16x4_t(a), int16x4_t(b))
		return vget_lane_s16(c, 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlh_u16)
	@(require_results, enable_target_feature = "neon")
	vqshlh_u16 :: #force_inline proc "c" (a: uint16_t, b: int16_t) -> uint16_t {
		c := vqshl_u16(uint16x4_t(a), int16x4_t(b))
		return vget_lane_u16(c, 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshls_s32)
	@(require_results, enable_target_feature = "neon")
	vqshls_s32 :: #force_inline proc "c" (a: int32_t, b: int32_t) -> int32_t {
		c := vqshl_s32(int32x2_t(a), int32x2_t(b))
		return vget_lane_s32(c, 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshls_u32)
	@(require_results, enable_target_feature = "neon")
	vqshls_u32 :: #force_inline proc "c" (a: uint32_t, b: int32_t) -> uint32_t {
		c := vqshl_u32(uint32x2_t(a), int32x2_t(b))
		return vget_lane_u32(c, 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshld_n_s64)
	@(require_results, enable_target_feature = "neon")
	vqshld_n_s64 :: #force_inline proc "c" (v: int64_t, $N: int32_t) -> int64_t where 0 <= N, N < 64 {
		return vget_lane_s64(vqshl_n_s64(int64x1_t(v), N), 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshld_n_u64)
	@(require_results, enable_target_feature = "neon")
	vqshld_n_u64 :: #force_inline proc "c" (v: uint64_t, $N: int32_t) -> uint64_t where 0 <= N, N < 64 {
		return vget_lane_u64(vqshl_n_u64(uint64x1_t(v), N), 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlb_n_s8)
	@(require_results, enable_target_feature = "neon")
	vqshlb_n_s8 :: #force_inline proc "c" (v: int8_t, $N: int32_t) -> int8_t where 0 <= N, N < 8 {
		return vget_lane_s8(vqshl_n_s8(int8x8_t(v), N), 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlb_n_u8)
	@(require_results, enable_target_feature = "neon")
	vqshlb_n_u8 :: #force_inline proc "c" (v: uint8_t, $N: int32_t) -> uint8_t where 0 <= N, N < 8 {
		return vget_lane_u8(vqshl_n_u8(uint8x8_t(v), N), 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlh_n_s16)
	@(require_results, enable_target_feature = "neon")
	vqshlh_n_s16 :: #force_inline proc "c" (v: int16_t, $N: int32_t) -> int16_t where 0 <= N, N < 16 {
		return vget_lane_s16(vqshl_n_s16(int16x4_t(v), N), 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlh_n_u16)
	@(require_results, enable_target_feature = "neon")
	vqshlh_n_u16 :: #force_inline proc "c" (v: uint16_t, $N: int32_t) -> uint16_t where 0 <= N, N < 16 {
		return vget_lane_u16(vqshl_n_u16(uint16x4_t(v), N), 0)
	}

	// Signed Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshls_n_s32)
	@(require_results, enable_target_feature = "neon")
	vqshls_n_s32 :: #force_inline proc "c" (v: int32_t, $N: int32_t) -> int32_t where 0 <= N, N < 32 {
		return vget_lane_s32(vqshl_n_s32(int32x2_t(v), N), 0)
	}

	// Unsigned Saturating Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshls_n_u32)
	@(require_results, enable_target_feature = "neon")
	vqshls_n_u32 :: #force_inline proc "c" (v: uint32_t, $N: int32_t) -> uint32_t where 0 <= N, N < 32 {
		return vget_lane_u32(vqshl_n_u32(uint32x2_t(v), N), 0)
	}

	// Signed Saturating Shift Left Unsigned.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlub_n_s8)
	@(require_results, enable_target_feature = "neon")
	vqshlub_n_s8 :: #force_inline proc "c" (v: int8_t, $N: int32_t) -> uint8_t where 0 <= N, N < 8 {
		return vget_lane_u8(vqshlu_n_s8(int8x8_t(v), N), 0)
	}

	// Signed Saturating Shift Left Unsigned.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshluh_n_s16)
	@(require_results, enable_target_feature = "neon")
	vqshluh_n_s16 :: #force_inline proc "c" (v: int16_t, $N: int32_t) -> uint16_t where 0 <= N, N < 16 {
		return vget_lane_u16(vqshlu_n_s16(int16x4_t(v), N), 0)
	}

	// Signed Saturating Shift Left Unsigned.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlus_n_s32)
	@(require_results, enable_target_feature = "neon")
	vqshlus_n_s32 :: #force_inline proc "c" (v: int32_t, $N: int32_t) -> uint32_t where 0 <= N, N < 32 {
		return vget_lane_u32(vqshlu_n_s32(int32x2_t(v), N), 0)
	}

	// Signed Saturating Shift Left Unsigned.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqshlud_n_s64)
	@(require_results, enable_target_feature = "neon")
	vqshlud_n_s64 :: #force_inline proc "c" (v: int64_t, $N: int32_t) -> uint64_t where 0 <= N, N < 64 {
		return vget_lane_u64(vqshlu_n_s64(int64x1_t(v), N), 0)
	}

	// Signed Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlb_s8)
	@(require_results, enable_target_feature = "neon")
	vqrshlb_s8 :: #force_inline proc "c" (a: int8_t, b: int8_t) -> int8_t {
		c := vqrshl_s8(int8x8_t(a), int8x8_t(b))
		return vget_lane_s8(c, 0)
	}

	// Unsigned Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlb_u8)
	@(require_results, enable_target_feature = "neon")
	vqrshlb_u8 :: #force_inline proc "c" (a: uint8_t, b: int8_t) -> uint8_t {
		c := vqrshl_u8(uint8x8_t(a), int8x8_t(b))
		return vget_lane_u8(c, 0)
	}

	// Signed Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlh_s16)
	@(require_results, enable_target_feature = "neon")
	vqrshlh_s16 :: #force_inline proc "c" (a: int16_t, b: int16_t) -> int16_t {
		c := vqrshl_s16(int16x4_t(a), int16x4_t(b))
		return vget_lane_s16(c, 0)
	}

	// Unsigned Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshlh_u16)
	@(require_results, enable_target_feature = "neon")
	vqrshlh_u16 :: #force_inline proc "c" (a: uint16_t, b: int16_t) -> uint16_t {
		c := vqrshl_u16(uint16x4_t(a), int16x4_t(b))
		return vget_lane_u16(c, 0)
	}

	// Signed Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshls_s32)
	@(require_results, enable_target_feature = "neon")
	vqrshls_s32 :: #force_inline proc "c" (a: int32_t, b: int32_t) -> int32_t {
		return _vqrshls_s32(a, b)
	}

	// Unsigned Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshls_u32)
	@(require_results, enable_target_feature = "neon")
	vqrshls_u32 :: #force_inline proc "c" (a: uint32_t, b: int32_t) -> uint32_t {
		return _vqrshls_u32(a, b)
	}

	// Signed Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshld_s64)
	@(require_results, enable_target_feature = "neon")
	vqrshld_s64 :: #force_inline proc "c" (a: int64_t, b: int64_t) -> int64_t {
		return _vqrshld_s64(a, b)
	}

	// Unsigned Saturating Rounding Shift Left.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqrshld_u64)
	@(require_results, enable_target_feature = "neon")
	vqrshld_u64 :: #force_inline proc "c" (a: uint64_t, b: int64_t) -> uint64_t {
		return _vqrshld_u64(a, b)
	}

	// Signed Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_s8)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_s8 :: #force_inline proc "c" (v: int8x16_t, $N: int32_t) -> int16x8_t where 0 <= N, N < 8 {
		return vshll_n_s8(vget_high_s8(v), N)
	}

	// Unsigned Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_u8)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_u8 :: #force_inline proc "c" (v: uint8x16_t, $N: int32_t) -> uint16x8_t where 0 <= N, N < 8 {
		return vshll_n_u8(vget_high_u8(v), N)
	}

	// Signed Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_s16)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_s16 :: #force_inline proc "c" (v: int16x8_t, $N: int32_t) -> int32x4_t where 0 <= N, N < 16 {
		return vshll_n_s16(vget_high_s16(v), N)
	}

	// Unsigned Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_u16)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_u16 :: #force_inline proc "c" (v: uint16x8_t, $N: int32_t) -> uint32x4_t where 0 <= N, N < 16 {
		return vshll_n_u16(vget_high_u16(v), N)
	}

	// Signed Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_s32)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_s32 :: #force_inline proc "c" (v: int32x4_t, $N: int32_t) -> int64x2_t where 0 <= N, N < 32 {
		return vshll_n_s32(vget_high_s32(v), N)
	}

	// Unsigned Shift Left Long.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshll_high_n_u32)
	@(require_results, enable_target_feature = "neon")
	vshll_high_n_u32 :: #force_inline proc "c" (v: uint32x4_t, $N: int32_t) -> uint64x2_t where 0 <= N, N < 32 {
		return vshll_n_u32(vget_high_u32(v), N)
	}

	// Shift Left and Insert.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vslid_n_s64)
	@(require_results, enable_target_feature = "neon")
	vslid_n_s64 :: #force_inline proc "c" (a, b: int64_t, $N: int32_t) -> int64_t where 0 <= N, N < 64 {
		return transmute(int64_t)vsli_n_s64(
			transmute(int64x1_t)a,
			transmute(int64x1_t)b,
			N,
		)
	}

	// Shift Left and Insert.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vslid_n_u64)
	@(require_results, enable_target_feature = "neon")
	vslid_n_u64 :: #force_inline proc "c" (a, b: uint64_t, $N: int32_t) -> uint64_t where 0 <= N, N < 64 {
		return transmute(uint64_t)vsli_n_u64(
			transmute(uint64x1_t)a,
			transmute(uint64x1_t)b,
			N,
		)
	}

	// Signed Shift Right.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrd_n_s64)
	@(require_results, enable_target_feature = "neon")
	vshrd_n_s64 :: #force_inline proc "c" (v: int64_t, $N: int32_t) -> int64_t where 1 <= N, N <= 64 {
		when N == 64 { M :: 63 } else { M :: N }
		return v >> uint64_t(M)
	}

	// Unsigned Shift Right.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vshrd_n_u64)
	@(require_results, enable_target_feature = "neon")
	vshrd_n_u64 :: #force_inline proc "c" (v: uint64_t, $N: int32_t) -> uint64_t where 1 <= N, N <= 64 {
		when N == 64 {
			return uint64_t(0)
		} else {
			return v >> uint64_t(N)
		}
	}

	// Signed Rounding Shift Right.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrd_n_s64)
	@(require_results, enable_target_feature = "neon")
	vrshrd_n_s64 :: #force_inline proc "c" (v: int64_t, $N: int32_t) -> int64_t where 1 <= N, N <= 64 {
		return vrshld_s64(v, int64_t(-N))
	}

	// Unsigned Rounding Shift Right.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrshrd_n_u64)
	@(require_results, enable_target_feature = "neon")
	vrshrd_n_u64 :: #force_inline proc "c" (v: uint64_t, $N: int32_t) -> uint64_t where 1 <= N, N <= 64 {
		return vrshld_u64(v, int64_t(-N))
	}

	// Signed Shift Right and Accumulate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsrad_n_s64)
	@(require_results, enable_target_feature = "neon")
	vsrad_n_s64 :: #force_inline proc "c" (a, b: int64_t, $N: int32_t) -> int64_t where 1 <= N, N <= 64 {
		return a + vshrd_n_s64(b, N)
	}

	// Unsigned Shift Right and Accumulate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsrad_n_u64)
	@(require_results, enable_target_feature = "neon")
	vsrad_n_u64 :: #force_inline proc "c" (a, b: uint64_t, $N: int32_t) -> uint64_t where 1 <= N, N <= 64 {
		return a + vshrd_n_u64(b, N)
	}

	// Signed Rounding Shift Right and Accumulate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsrad_n_s64)
	@(require_results, enable_target_feature = "neon")
	vrsrad_n_s64 :: #force_inline proc "c" (a, b: int64_t, $N: int32_t) -> int64_t where 1 <= N, N <= 64 {
		return a + vrshrd_n_s64(b, N)
	}

	// Unsigned Rounding Shift Right and Accumulate.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vrsrad_n_u64)
	@(require_results, enable_target_feature = "neon")
	vrsrad_n_u64 :: #force_inline proc "c" (a, b: uint64_t, $N: int32_t) -> uint64_t where 1 <= N, N <= 64 {
		return a + vrshrd_n_u64(b, N)
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
	@(link_name = "llvm.aarch64.neon.sqneg.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v8i8")
	_vqneg_s8 :: proc(a: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.sqneg.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v4i16")
	_vqneg_s16 :: proc(a: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.sqneg.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v2i32")
	_vqneg_s32 :: proc(a: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.sqneg.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v16i8")
	_vqnegq_s8 :: proc(a: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.sqneg.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v8i16")
	_vqnegq_s16 :: proc(a: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.sqneg.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqneg.v4i32")
	_vqnegq_s32 :: proc(a: int32x4_t) -> int32x4_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v8i8")
	_vshl_s8 :: proc(a: int8x8_t, b: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v8i8")
	_vshl_u8 :: proc(a: uint8x8_t, b: int8x8_t) -> uint8x8_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v4i16")
	_vshl_s16 :: proc(a: int16x4_t, b: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v4i16")
	_vshl_u16 :: proc(a: uint16x4_t, b: int16x4_t) -> uint16x4_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v2i32")
	_vshl_s32 :: proc(a: int32x2_t, b: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v2i32")
	_vshl_u32 :: proc(a: uint32x2_t, b: int32x2_t) -> uint32x2_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v1i64")
	_vshl_s64 :: proc(a: int64x1_t, b: int64x1_t) -> int64x1_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v1i64")
	_vshl_u64 :: proc(a: uint64x1_t, b: int64x1_t) -> uint64x1_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v16i8")
	_vshlq_s8 :: proc(a: int8x16_t, b: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v16i8")
	_vshlq_u8 :: proc(a: uint8x16_t, b: int8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v8i16")
	_vshlq_s16 :: proc(a: int16x8_t, b: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v8i16")
	_vshlq_u16 :: proc(a: uint16x8_t, b: int16x8_t) -> uint16x8_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v4i32")
	_vshlq_s32 :: proc(a: int32x4_t, b: int32x4_t) -> int32x4_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v4i32")
	_vshlq_u32 :: proc(a: uint32x4_t, b: int32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.neon.sshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshifts.v2i64")
	_vshlq_s64 :: proc(a: int64x2_t, b: int64x2_t) -> int64x2_t ---
	@(link_name = "llvm.aarch64.neon.ushl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vshiftu.v2i64")
	_vshlq_u64 :: proc(a: uint64x2_t, b: int64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v8i8")
	_vrshl_s8 :: proc(a: int8x8_t, b: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v8i8")
	_vrshl_u8 :: proc(a: uint8x8_t, b: int8x8_t) -> uint8x8_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v4i16")
	_vrshl_s16 :: proc(a: int16x4_t, b: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v4i16")
	_vrshl_u16 :: proc(a: uint16x4_t, b: int16x4_t) -> uint16x4_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v2i32")
	_vrshl_s32 :: proc(a: int32x2_t, b: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v2i32")
	_vrshl_u32 :: proc(a: uint32x2_t, b: int32x2_t) -> uint32x2_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v1i64")
	_vrshl_s64 :: proc(a: int64x1_t, b: int64x1_t) -> int64x1_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v1i64")
	_vrshl_u64 :: proc(a: uint64x1_t, b: int64x1_t) -> uint64x1_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v16i8")
	_vrshlq_s8 :: proc(a: int8x16_t, b: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v16i8")
	_vrshlq_u8 :: proc(a: uint8x16_t, b: int8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v8i16")
	_vrshlq_s16 :: proc(a: int16x8_t, b: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v8i16")
	_vrshlq_u16 :: proc(a: uint16x8_t, b: int16x8_t) -> uint16x8_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v4i32")
	_vrshlq_s32 :: proc(a: int32x4_t, b: int32x4_t) -> int32x4_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v4i32")
	_vrshlq_u32 :: proc(a: uint32x4_t, b: int32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.neon.srshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshifts.v2i64")
	_vrshlq_s64 :: proc(a: int64x2_t, b: int64x2_t) -> int64x2_t ---
	@(link_name = "llvm.aarch64.neon.urshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vrshiftu.v2i64")
	_vrshlq_u64 :: proc(a: uint64x2_t, b: int64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v8i8")
	_vqshl_s8 :: proc(a: int8x8_t, b: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v8i8")
	_vqshl_u8 :: proc(a: uint8x8_t, b: int8x8_t) -> uint8x8_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v4i16")
	_vqshl_s16 :: proc(a: int16x4_t, b: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v4i16")
	_vqshl_u16 :: proc(a: uint16x4_t, b: int16x4_t) -> uint16x4_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v2i32")
	_vqshl_s32 :: proc(a: int32x2_t, b: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v2i32")
	_vqshl_u32 :: proc(a: uint32x2_t, b: int32x2_t) -> uint32x2_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v1i64")
	_vqshl_s64 :: proc(a: int64x1_t, b: int64x1_t) -> int64x1_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v1i64")
	_vqshl_u64 :: proc(a: uint64x1_t, b: int64x1_t) -> uint64x1_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v16i8")
	_vqshlq_s8 :: proc(a: int8x16_t, b: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v16i8")
	_vqshlq_u8 :: proc(a: uint8x16_t, b: int8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v8i16")
	_vqshlq_s16 :: proc(a: int16x8_t, b: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v8i16")
	_vqshlq_u16 :: proc(a: uint16x8_t, b: int16x8_t) -> uint16x8_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v4i32")
	_vqshlq_s32 :: proc(a: int32x4_t, b: int32x4_t) -> int32x4_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v4i32")
	_vqshlq_u32 :: proc(a: uint32x4_t, b: int32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.neon.sqshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshifts.v2i64")
	_vqshlq_s64 :: proc(a: int64x2_t, b: int64x2_t) -> int64x2_t ---
	@(link_name = "llvm.aarch64.neon.uqshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftu.v2i64")
	_vqshlq_u64 :: proc(a: uint64x2_t, b: int64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v8i8")
	_vqshlu_n_s8 :: proc(a: int8x8_t, b: int8x8_t) -> uint8x8_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v4i16")
	_vqshlu_n_s16 :: proc(a: int16x4_t, b: int16x4_t) -> uint16x4_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v2i32")
	_vqshlu_n_s32 :: proc(a: int32x2_t, b: int32x2_t) -> uint32x2_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v1i64")
	_vqshlu_n_s64 :: proc(a: int64x1_t, b: int64x1_t) -> uint64x1_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v16i8")
	_vqshluq_n_s8 :: proc(a: int8x16_t, b: int8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v8i16")
	_vqshluq_n_s16 :: proc(a: int16x8_t, b: int16x8_t) -> uint16x8_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v4i32")
	_vqshluq_n_s32 :: proc(a: int32x4_t, b: int32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.neon.sqshlu.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqshiftsu.v2i64")
	_vqshluq_n_s64 :: proc(a: int64x2_t, b: int64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v8i8")
	_vqrshl_s8 :: proc(a: int8x8_t, b: int8x8_t) -> int8x8_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v8i8")
	_vqrshl_u8 :: proc(a: uint8x8_t, b: int8x8_t) -> uint8x8_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v4i16")
	_vqrshl_s16 :: proc(a: int16x4_t, b: int16x4_t) -> int16x4_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v4i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v4i16")
	_vqrshl_u16 :: proc(a: uint16x4_t, b: int16x4_t) -> uint16x4_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v2i32")
	_vqrshl_s32 :: proc(a: int32x2_t, b: int32x2_t) -> int32x2_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v2i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v2i32")
	_vqrshl_u32 :: proc(a: uint32x2_t, b: int32x2_t) -> uint32x2_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v1i64")
	_vqrshl_s64 :: proc(a: int64x1_t, b: int64x1_t) -> int64x1_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v1i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v1i64")
	_vqrshl_u64 :: proc(a: uint64x1_t, b: int64x1_t) -> uint64x1_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v16i8")
	_vqrshlq_s8 :: proc(a: int8x16_t, b: int8x16_t) -> int8x16_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v16i8")
	_vqrshlq_u8 :: proc(a: uint8x16_t, b: int8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v8i16")
	_vqrshlq_s16 :: proc(a: int16x8_t, b: int16x8_t) -> int16x8_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v8i16")
	_vqrshlq_u16 :: proc(a: uint16x8_t, b: int16x8_t) -> uint16x8_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v4i32")
	_vqrshlq_s32 :: proc(a: int32x4_t, b: int32x4_t) -> int32x4_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v4i32" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v4i32")
	_vqrshlq_u32 :: proc(a: uint32x4_t, b: int32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.neon.sqrshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshifts.v2i64")
	_vqrshlq_s64 :: proc(a: int64x2_t, b: int64x2_t) -> int64x2_t ---
	@(link_name = "llvm.aarch64.neon.uqrshl.v2i64" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vqrshiftu.v2i64")
	_vqrshlq_u64 :: proc(a: uint64x2_t, b: int64x2_t) -> uint64x2_t ---
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
		@(link_name = "llvm.arm.neon.vtbx1")
		_vtbx1 :: proc(v: int8x8_t, t: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbx2")
		_vtbx2 :: proc(v: int8x8_t, t0, t1: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbx3")
		_vtbx3 :: proc(v: int8x8_t, t0, t1, t2: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vtbx4")
		_vtbx4 :: proc(v: int8x8_t, t0, t1, t2, t3: int8x8_t, idx: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v8i8")
		_vshiftlins_v8i8 :: proc(a: int8x8_t, b: int8x8_t, c: int8x8_t) -> int8x8_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v4i16")
		_vshiftlins_v4i16 :: proc(a: int16x4_t, b: int16x4_t, c: int16x4_t) -> int16x4_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v2i32")
		_vshiftlins_v2i32 :: proc(a: int32x2_t, b: int32x2_t, c: int32x2_t) -> int32x2_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v1i64")
		_vshiftlins_v1i64 :: proc(a: int64x1_t, b: int64x1_t, c: int64x1_t) -> int64x1_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v16i8")
		_vshiftlins_v16i8 :: proc(a: int8x16_t, b: int8x16_t, c: int8x16_t) -> int8x16_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v8i16")
		_vshiftlins_v8i16 :: proc(a: int16x8_t, b: int16x8_t, c: int16x8_t) -> int16x8_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v4i32")
		_vshiftlins_v4i32 :: proc(a: int32x4_t, b: int32x4_t, c: int32x4_t) -> int32x4_t ---
		@(link_name = "llvm.arm.neon.vshiftins.v2i64")
		_vshiftlins_v2i64 :: proc(a: int64x2_t, b: int64x2_t, c: int64x2_t) -> int64x2_t ---
	}
}

when ODIN_ARCH == .arm64 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.aarch64.neon.sqneg.v1i64")
		_vqneg_s64 :: proc(a: int64x1_t) -> int64x1_t ---
		@(link_name = "llvm.aarch64.neon.sqneg.v2i64")
		_vqnegq_s64 :: proc(a: int64x2_t) -> int64x2_t ---
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
		@(link_name = "llvm.aarch64.neon.tbx1.v8i8")
		_vqtbx1 :: proc(v: int8x8_t, t: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbx1.v16i8")
		_vqtbx1q :: proc(v: int8x16_t, t: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbx2.v8i8")
		_vqtbx2 :: proc(v: int8x8_t, t0, t1: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbx2.v16i8")
		_vqtbx2q :: proc(v: int8x16_t, t0, t1: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbx3.v8i8")
		_vqtbx3 :: proc(v: int8x8_t, t0, t1, t2: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbx3.v16i8")
		_vqtbx3q :: proc(v: int8x16_t, t0, t1, t2: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.tbx4.v8i8")
		_vqtbx4 :: proc(v: int8x8_t, t0, t1, t2, t3: int8x16_t, idx: uint8x8_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.tbx4.v16i8")
		_vqtbx4q :: proc(v: int8x16_t, t0, t1, t2, t3: int8x16_t, idx: uint8x16_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.srshl.i64")
		_vrshld_s64 :: proc(a: int64_t, b: int64_t) -> int64_t ---
		@(link_name = "llvm.aarch64.neon.urshl.i64")
		_vrshld_u64 :: proc(a: uint64_t, b: int64_t) -> uint64_t ---
		@(link_name = "llvm.aarch64.neon.sqshl.i64")
		_vqshld_s64 :: proc(a: int64_t, b: int64_t) -> int64_t ---
		@(link_name = "llvm.aarch64.neon.uqshl.i64")
		_vqshld_u64 :: proc(a: uint64_t, b: int64_t) -> uint64_t ---
		@(link_name = "llvm.aarch64.neon.sqrshl.i32")
		_vqrshls_s32 :: proc(a: int32_t, b: int32_t) -> int32_t ---
		@(link_name = "llvm.aarch64.neon.uqrshl.i32")
		_vqrshls_u32 :: proc(a: uint32_t, b: int32_t) -> uint32_t ---
		@(link_name = "llvm.aarch64.neon.sqrshl.i64")
		_vqrshld_s64 :: proc(a: int64_t, b: int64_t) -> int64_t ---
		@(link_name = "llvm.aarch64.neon.uqrshl.i64")
		_vqrshld_u64 :: proc(a: uint64_t, b: int64_t) -> uint64_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v8i8")
		_vsli_n_s8 :: proc(a: int8x8_t, b: int8x8_t, n: int32_t) -> int8x8_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v4i16")
		_vsli_n_s16 :: proc(a: int16x4_t, b: int16x4_t, n: int32_t) -> int16x4_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v2i32")
		_vsli_n_s32 :: proc(a: int32x2_t, b: int32x2_t, n: int32_t) -> int32x2_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v1i64")
		_vsli_n_s64 :: proc(a: int64x1_t, b: int64x1_t, n: int32_t) -> int64x1_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v16i8")
		_vsliq_n_s8 :: proc(a: int8x16_t, b: int8x16_t, n: int32_t) -> int8x16_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v8i16")
		_vsliq_n_s16 :: proc(a: int16x8_t, b: int16x8_t, n: int32_t) -> int16x8_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v4i32")
		_vsliq_n_s32 :: proc(a: int32x4_t, b: int32x4_t, n: int32_t) -> int32x4_t ---
		@(link_name = "llvm.aarch64.neon.vsli.v2i64")
		_vsliq_n_s64 :: proc(a: int64x2_t, b: int64x2_t, n: int32_t) -> int64x2_t ---
	}
}
