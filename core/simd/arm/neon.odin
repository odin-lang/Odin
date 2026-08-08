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
