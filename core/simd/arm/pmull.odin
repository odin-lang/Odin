#+build arm64,arm32
package simd_arm

import "core:simd"

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_p8)
@(require_results, enable_target_feature = "neon")
vbsl_p8 :: #force_inline proc "c" (a: uint8x8_t, b: poly8x8_t, c: poly8x8_t) -> poly8x8_t {
	not := int8x8_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint8x8_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_p16)
@(require_results, enable_target_feature = "neon")
vbsl_p16 :: #force_inline proc "c" (a: uint16x4_t, b: poly16x4_t, c: poly16x4_t) -> poly16x4_t {
	not := int16x4_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(uint16x4_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbsl_p64)
@(require_results, enable_target_feature = "neon")
vbsl_p64 :: #force_inline proc "c" (a: poly64x1_t, b: poly64x1_t, c: poly64x1_t) -> poly64x1_t {
	not := int64x1_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(poly64x1_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_p8)
@(require_results, enable_target_feature = "neon")
vbslq_p8 :: #force_inline proc "c" (a: uint8x16_t, b: poly8x16_t, c: poly8x16_t) -> poly8x16_t {
	not := int8x16_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(poly8x16_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_p16)
@(require_results, enable_target_feature = "neon")
vbslq_p16 :: #force_inline proc "c" (a: uint16x8_t, b: poly16x8_t, c: poly16x8_t) -> poly16x8_t {
	not := int16x8_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(poly16x8_t)not), c),
	)
}

// Bitwise Select.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vbslq_p64)
@(require_results, enable_target_feature = "neon")
vbslq_p64 :: #force_inline proc "c" (a: poly64x2_t, b: poly64x2_t, c: poly64x2_t) -> poly64x2_t {
	not := int64x2_t(-1)
	return simd.bit_or(
		simd.bit_and(a, b),
		simd.bit_and(simd.bit_xor(a, transmute(poly64x2_t)not), c),
	)
}

// Join two smaller vectors into a single larger vector
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_p8)
@(require_results, enable_target_feature = "neon")
vcombine_p8 :: #force_inline proc "c" (low, high: poly8x8_t) -> poly8x16_t {
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_p16)
@(require_results, enable_target_feature = "neon")
vcombine_p16 :: #force_inline proc "c" (low, high: poly16x4_t) -> poly16x8_t {
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcombine_p64)
@(require_results, enable_target_feature = "neon")
vcombine_p64 :: #force_inline proc "c" (low, high: poly64x1_t) -> poly64x2_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(low, high, 0, 1)
	} else {
		c := simd.shuffle(low, high, 0, 1)
		return simd.shuffle(c, c, 1, 0)
	}
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vset_lane_p8)
@(require_results, enable_target_feature = "neon")
vset_lane_p8 :: #force_inline proc "c" (a: poly8_t, v: poly8x8_t, $LANE: int32_t) -> poly8x8_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.replace(v, LANE, a)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		c := simd.replace(v, LANE, a)
		return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vset_lane_p16)
@(require_results, enable_target_feature = "neon")
vset_lane_p16 :: #force_inline proc "c" (a: poly16_t, v: poly16x4_t, $LANE: int32_t) -> poly16x4_t where 0 <= LANE, LANE < 4 {
	when ODIN_ENDIAN == .Little {
		return simd.replace(v, LANE, a)
	} else {
		v := simd.shuffle(v, v, 3, 2, 1, 0)
		c := simd.replace(v, LANE, a)
		return simd.shuffle(c, c, 3, 2, 1, 0)
	}
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vset_lane_p64)
@(require_results, enable_target_feature = "neon")
vset_lane_p64 :: #force_inline proc "c" (a: poly64_t, v: poly64x1_t, $LANE: int32_t) -> poly64x1_t where LANE == 0 {
	return simd.replace(v, LANE, a)
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_p8)
@(require_results, enable_target_feature = "neon")
vget_lane_p8 :: #force_inline proc "c" (v: poly8x8_t, $LANE: int32_t) -> poly8_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_p16)
@(require_results, enable_target_feature = "neon")
vget_lane_p16 :: #force_inline proc "c" (v: poly16x4_t, $LANE: int32_t) -> poly16_t where 0 <= LANE, LANE < 4 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_lane_p64)
@(require_results, enable_target_feature = "neon")
vget_lane_p64 :: #force_inline proc "c" (v: poly64x1_t, $LANE: int32_t) -> poly64_t where LANE == 0 {
	return simd.extract(v, LANE)
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsetq_lane_p8)
@(require_results, enable_target_feature = "neon")
vsetq_lane_p8 :: #force_inline proc "c" (a: poly8_t, v: poly8x16_t, $LANE: int32_t) -> poly8x16_t where 0 <= LANE, LANE < 16 {
	when ODIN_ENDIAN == .Little {
		return simd.replace(v, LANE, a)
	} else {
		v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		c := simd.replace(v, LANE, a)
		return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsetq_lane_p16)
@(require_results, enable_target_feature = "neon")
vsetq_lane_p16 :: #force_inline proc "c" (a: poly16_t, v: poly16x8_t, $LANE: int32_t) -> poly16x8_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.replace(v, LANE, a)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		c := simd.replace(v, LANE, a)
		return simd_shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Insert vector element from another vector element
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsetq_lane_p64)
@(require_results, enable_target_feature = "neon")
vsetq_lane_p64 :: #force_inline proc "c" (a: poly64_t, v: poly64x2_t, $LANE: int32_t) -> poly64x2_t where 0 <= LANE, LANE < 2 {
	when ODIN_ENDIAN == .Little {
		return simd.replace(v, LANE, a)
	} else {
		v := simd.shuffle(v, v, 1, 0)
		c := simd.replace(v, LANE, a)
		return simd.shuffle(c, c, 1, 0)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vgetq_lane_p8)
@(require_results, enable_target_feature = "neon")
vgetq_lane_p8 :: #force_inline proc "c" (v: poly8x16_t, $LANE: int32_t) -> poly8_t where 0 <= LANE, LANE < 16 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vgetq_lane_p16)
@(require_results, enable_target_feature = "neon")
vgetq_lane_p16 :: #force_inline proc "c" (v: poly16x8_t, $LANE: int32_t) -> poly16_t where 0 <= LANE, LANE < 8 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Move vector element to general-purpose register
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vgetq_lane_p64)
@(require_results, enable_target_feature = "neon")
vgetq_lane_p64 :: #force_inline proc "c" (v: poly64x2_t, $LANE: int32_t) -> poly64_t where 0 <= LANE, LANE < 2 {
	when ODIN_ENDIAN == .Little {
		return simd.extract(v, LANE)
	} else {
		v := simd.shuffle(v, v, 1, 0)
		return simd.extract(v, LANE)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_low_p8)
@(require_results, enable_target_feature = "neon")
vget_low_p8 :: #force_inline proc "c" (a: poly8x16_t) -> poly8x8_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 0, 1, 2, 3, 4, 5, 6, 7)
	} else {
		a := simd.shuffle(a, a, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 0, 1, 2, 3, 4, 5, 6, 7)
		return simd.shuffle(b, b, 7, 6, 5, 4, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_low_p16)
@(require_results, enable_target_feature = "neon")
vget_low_p16 :: #force_inline proc "c" (a: poly16x8_t) -> poly16x4_t {
	when ODIN_ENDIAN == .Little {
		return simd.shuffle(a, a, 0, 1, 2, 3)
	} else {
		a := simd.shuffle(a, a, 7, 6, 5, 4, 3, 2, 1, 0)
		b := simd.shuffle(a, a, 0, 1, 2, 3)
		return simd.shuffle(b, b, 3, 2, 1, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_low_p64)
@(require_results, enable_target_feature = "neon")
vget_low_p64 :: #force_inline proc "c" (a: poly64x2_t) -> poly64x1_t {
	when ODIN_ENDIAN == .Little {
		return transmute(poly64x1_t)simd.extract(a, 0)
	} else {
		a := simd.shuffle(a, a, 1, 0)
		return transmute(poly64x1_t)simd.extract(a, 0)
	}
}

// Duplicate vector element to vector or scalar
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_p8)
@(require_results, enable_target_feature = "neon")
vget_high_p8 :: #force_inline proc "c" (a: poly8x16_t) -> poly8x8_t {
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_p16)
@(require_results, enable_target_feature = "neon")
vget_high_p16 :: #force_inline proc "c" (a: poly16x8_t) -> poly16x4_t {
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vget_high_p64)
@(require_results, enable_target_feature = "neon")
vget_high_p64 :: #force_inline proc "c" (a: poly64x2_t) -> poly64x1_t {
	when ODIN_ENDIAN == .Little {
		return transmute(poly64x1_t)simd.extract(a, 1)
	} else {
		a := simd.shuffle(a, a, 1, 0)
		return transmute(poly64x1_t)simd.extract(a, 1)
	}
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vadd_p8)
@(require_results, enable_target_feature = "neon")
vadd_p8 :: #force_inline proc "c" (a, b: poly8x8_t) -> poly8x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vadd_p16)
@(require_results, enable_target_feature = "neon")
vadd_p16 :: #force_inline proc "c" (a, b: poly16x4_t) -> poly16x4_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vadd_p64)
@(require_results, enable_target_feature = "neon")
vadd_p64 :: #force_inline proc "c" (a, b: poly64x1_t) -> poly64x1_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vaddq_p8)
@(require_results, enable_target_feature = "neon")
vaddq_p8 :: #force_inline proc "c" (a, b: poly8x16_t) -> poly8x16_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vaddq_p16)
@(require_results, enable_target_feature = "neon")
vaddq_p16 :: #force_inline proc "c" (a, b: poly16x8_t) -> poly16x8_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vaddq_p64)
@(require_results, enable_target_feature = "neon")
vaddq_p64 :: #force_inline proc "c" (a, b: poly64x2_t) -> poly64x2_t {
	return simd.bit_xor(a, b)
}

// Bitwise exclusive OR
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vaddq_p128)
@(require_results, enable_target_feature = "neon")
vaddq_p128 :: #force_inline proc "c" (a, b: poly128_t) -> poly128_t {
	return a ~ b
}

// Polynomial multiply
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmul_p8)
@(require_results, enable_target_feature = "neon")
vmul_p8 :: #force_inline proc "c" (a, b: poly8x8_t) -> poly8x8_t {
	return _vmul_p8(a, b)
}

// Polynomial multiply
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmulq_p8)
@(require_results, enable_target_feature = "neon")
vmulq_p8 :: #force_inline proc "c" (a, b: poly8x16_t) -> poly8x16_t {
	return _vmulq_p8(a, b)
}

// Polynomial multiply long
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmull_p8)
@(require_results, enable_target_feature = "neon")
vmull_p8 :: #force_inline proc "c" (a, b: poly8x8_t) -> poly16x8_t {
	return _vmull_p8(a, b)
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl1_p8)
@(require_results, enable_target_feature = "neon")
vtbl1_p8 :: #force_inline proc "c" (t: poly8x8_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_p8(vcombine_p8(t, poly8x8_t{}), idx)
	} else {
		return transmute(poly8x8_t)_vtbl1(transmute(int8x8_t)t, transmute(int8x8_t)idx)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl2_p8)
@(require_results, enable_target_feature = "neon")
vtbl2_p8 :: #force_inline proc "c" (t: poly8x8x2_t, idx: poly8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		return vqtbl1_p8(vcombine_p8(t.x, t.y), idx)
	} else {
		return transmute(poly8x8_t)_vtbl2(
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)idx,
		)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl3_p8)
@(require_results, enable_target_feature = "neon")
vtbl3_p8 :: #force_inline proc "c" (t: poly8x8x3_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		v := poly8x16x2_t {
			vcombine_p8(t.x, t.y),
			vcombine_p8(t.z, poly8x8_t{}),
		}
		return vqtbl2_p8(v, idx)
	} else {
		return transmute(poly8x8_t)_vtbl3(
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)idx,
		)
	}
}

// Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbl4_p8)
@(require_results, enable_target_feature = "neon")
vtbl4_p8 :: #force_inline proc "c" (t: poly8x8x4_t, idx: poly8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		v := poly8x16x2_t {
			vcombine_p8(t.x, t.y),
			vcombine_p8(t.z, t.w),
		}
		return vqtbl2_p8(v, idx)
	} else {
		return transmute(poly8x8_t)_vtbl4(
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx1_p8)
@(require_results, enable_target_feature = "neon")
vtbx1_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x8_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(8)),
			vqtbx1_p8(v, vcombine_p8(t, poly8x8_t{}), idx),
			v,
		)
	} else {
		return transmute(poly8x8_t)_vtbx1(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t,
			transmute(int8x8_t)idx,
		)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx2_p8)
@(require_results, enable_target_feature = "neon")
vtbx2_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x8x2_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(16)),
			vqtbx1_p8(v, vcombine_p8(t.x, t.y), idx),
			v,
		)
	} else {
		return transmute(poly8x8_t)_vtbx2(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)idx,
		)
	}
}

// Extended Table Lookup.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx3_p8)
@(require_results, enable_target_feature = "neon")
vtbx3_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x8x3_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		x := poly8x16x2_t {
			vcombine_p8(t.x, t.y),
			vcombine_p8(t.z, poly8x8_t{}),
		}
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(24)),
			vqtbx2_p8(v, x, idx),
			v,
		)
	} else {
		return transmute(poly8x8_t)_vtbx3(
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vtbx4_p8)
@(require_results, enable_target_feature = "neon")
vtbx4_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x8x4_t, idx: uint8x8_t) -> poly8x8_t {
	when ODIN_ARCH == .arm64 {
		x := poly8x16x2_t {
			vcombine_p8(t.x, t.y),
			vcombine_p8(t.z, t.w),
		}
		return simd.select(
			simd.lanes_lt(idx, uint8x8_t(32)),
			vqtbx2_p8(v, x, idx),
			v,
		)
	} else {
		return transmute(poly8x8_t)_vtbx4(
			transmute(int8x8_t)v,
			transmute(int8x8_t)t.x,
			transmute(int8x8_t)t.y,
			transmute(int8x8_t)t.z,
			transmute(int8x8_t)t.w,
			transmute(int8x8_t)idx,
		)
	}
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
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vcntq_p8)
@(require_results, enable_target_feature = "neon")
vcntq_p8 :: #force_inline proc "c" (a: poly8x16_t) -> poly8x16_t {
	return transmute(poly8x16_t)vcntq_s8(transmute(int8x16_t)a)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvn_p8)
@(require_results, enable_target_feature = "neon")
vmvn_p8 :: #force_inline proc "c" (a: poly8x8_t) -> poly8x8_t {
	b := poly8x8_t(max(poly8_t))
	return simd.bit_xor(a, b)
}

// Bitwise Not.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmvnq_p8)
@(require_results, enable_target_feature = "neon")
vmvnq_p8 :: #force_inline proc "c" (a: poly8x16_t) -> poly8x16_t {
	b := poly8x16_t(max(poly8_t))
	return simd.bit_xor(a, b)
}

when ODIN_ARCH == .arm64 {
	// Polynomial multiply long
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmull_high_p8)
	@(require_results, enable_target_feature = "neon")
	vmull_high_p8 :: #force_inline proc "c" (a, b: poly8x16_t) -> poly16x8_t {
		a := vget_high_p8(a)
		b := vget_high_p8(b)
		return vmull_p8(a, b)
	}

	// Polynomial multiply long
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmull_p64)
	@(require_results, enable_target_feature = "neon,aes")
	vmull_p64 :: #force_inline proc "c" (a, b: poly64_t) -> poly128_t {
		return transmute(poly128_t)_vmull_p64(a, b)
	}

	// Polynomial multiply long
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vmull_high_p64)
	@(require_results, enable_target_feature = "neon,aes")
	vmull_high_p64 :: #force_inline proc "c" (a, b: poly64x2_t) -> poly128_t {
		return vmull_p64(vgetq_lane_p64(a, 1), vgetq_lane_p64(b, 1))
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1_p8 :: #force_inline proc "c" (t: poly8x16_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbl1(transmute(int8x16_t)t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbl1(transmute(int8x16_t)t, idx)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl1q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl1q_p8 :: #force_inline proc "c" (t: poly8x16_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbl1q(transmute(int8x16_t)t, idx)
		} else {
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbl1q(transmute(int8x16_t)t, idx)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2_p8 :: #force_inline proc "c" (t: poly8x16x2_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbl2(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			t := poly8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbl2(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl2q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl2q_p8 :: #force_inline proc "c" (t: poly8x16x2_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbl2q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			t := poly8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbl2q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3_p8 :: #force_inline proc "c" (t: poly8x16x3_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbl3(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			t := poly8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbl3(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl3q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl3q_p8 :: #force_inline proc "c" (t: poly8x16x3_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbl3q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			t := poly8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbl3q(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4_p8 :: #force_inline proc "c" (t: poly8x16x4_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbl4(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			t := poly8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbl4(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbl4q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbl4q_p8 :: #force_inline proc "c" (t: poly8x16x4_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbl4q(
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			t := poly8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbl4q(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x16_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbx1(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbx1(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t,
				idx,
			)
			return simd.shuffle(c, c, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx1q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx1q_p8 :: #force_inline proc "c" (v: poly8x16_t, t: poly8x16_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbx1q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := simd.shuffle(t, t, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbx1q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t,
				idx,
			)
			return simd.shuffle(c, c, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
		}
	}

	// Extended Table Lookup.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x16x2_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbx2(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbx2(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx2q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx2q_p8 :: #force_inline proc "c" (v: poly8x16_t, t: poly8x16x2_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbx2q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x2_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbx2q(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x16x3_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbx3(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbx3(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx3q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx3q_p8 :: #force_inline proc "c" (v: poly8x16_t, t: poly8x16x3_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbx3q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x3_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbx3q(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4_p8 :: #force_inline proc "c" (v: poly8x8_t, t: poly8x16x4_t, idx: uint8x8_t) -> poly8x8_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x8_t)_vqtbx4(
				transmute(int8x8_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x8_t)_vqtbx4(
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
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vqtbx4q_p8)
	@(require_results, enable_target_feature = "neon")
	vqtbx4q_p8 :: #force_inline proc "c" (v: poly8x16_t, t: poly8x16x4_t, idx: uint8x16_t) -> poly8x16_t {
		when ODIN_ENDIAN == .Little {
			return transmute(poly8x16_t)_vqtbx4q(
				transmute(int8x16_t)v,
				transmute(int8x16_t)t.x,
				transmute(int8x16_t)t.y,
				transmute(int8x16_t)t.z,
				transmute(int8x16_t)t.w,
				idx,
			)
		} else {
			v := simd.shuffle(v, v, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			t := poly8x16x4_t {
				simd.shuffle(t.x, t.x, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.y, t.y, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.z, t.z, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
				simd.shuffle(t.w, t.w, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
			}
			idx := simd.shuffle(idx, idx, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
			c := transmute(poly8x16_t)_vqtbx4q(
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
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.aarch64.neon.pmul.v8i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vmulp.v8i8")
	_vmul_p8 :: proc(a, b: poly8x8_t) -> poly8x8_t ---
	@(link_name = "llvm.aarch64.neon.pmul.v16i8" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vmulp.v16i8")
	_vmulq_p8 :: proc(a, b: poly8x16_t) -> poly8x16_t ---
	@(link_name = "llvm.aarch64.neon.pmull.v8i16" when ODIN_ARCH == .arm64 else "llvm.arm.neon.vmullp.v8i16")
	_vmull_p8 :: proc(a, b: poly8x8_t) -> poly16x8_t ---
}

when ODIN_ARCH == .arm64 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.aarch64.neon.pmull64")
		_vmull_p64 :: proc(a, b: poly64_t) -> int8x16_t ---
	}
}
