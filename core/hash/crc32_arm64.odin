#+build arm64
package hash

import "base:intrinsics"
import "core:simd/arm"

@(private)
CRC32_HW_STATIC :: ODIN_OS == .Darwin || (intrinsics.has_target_feature("crc") && intrinsics.has_target_feature("aes"))

@(private)
CRC32_HW_MIN :: 0

@(private)
CRC32_FOLD_MIN :: 192

@(private)
crc32_hw_available :: #force_inline proc "contextless" () -> bool {
	return CRC32_HW_STATIC
}

@(private, enable_target_feature="neon,aes,crc")
crc32_hw :: proc "contextless" (crc: u32, data: [^]byte, length: int) -> (new_crc: u32, consumed: int) #no_bounds_check {
	K12 :: arm.uint64x2_t{0x154442bd4, 0x1c6e41596}
	K34 :: arm.uint64x2_t{0x1751997d0, 0x0ccaa009e}

	@(enable_target_feature="neon,aes")
	fold :: #force_inline proc "contextless" (x, k: arm.uint64x2_t) -> arm.uint64x2_t {
		lo := arm.vmull_p64(arm.vgetq_lane_u64(x, 0), arm.vgetq_lane_u64(k, 0))
		hi := arm.vmull_p64(arm.vgetq_lane_u64(x, 1), arm.vgetq_lane_u64(k, 1))
		return transmute(arm.uint64x2_t)(lo ~ hi)
	}
	@(enable_target_feature="neon,aes")
	load :: #force_inline proc "contextless" (p: [^]byte) -> arm.uint64x2_t {
		return intrinsics.unaligned_load((^arm.uint64x2_t)(p))
	}

	crc := crc
	p   := 0

	if length >= CRC32_FOLD_MIN {
		x0 := load(data[0:]) ~ arm.uint64x2_t{u64(crc), 0}
		x1 := load(data[16:])
		x2 := load(data[32:])
		x3 := load(data[48:])
		p = 64

		for length - p >= 64 {
			x0 = fold(x0, K12) ~ load(data[p:])
			x1 = fold(x1, K12) ~ load(data[p + 16:])
			x2 = fold(x2, K12) ~ load(data[p + 32:])
			x3 = fold(x3, K12) ~ load(data[p + 48:])
			p += 64
		}

		x0 = fold(x0, K34) ~ x1
		x0 = fold(x0, K34) ~ x2
		x0 = fold(x0, K34) ~ x3
		for length - p >= 16 {
			x0 = fold(x0, K34) ~ load(data[p:])
			p += 16
		}

		crc = arm.__crc32d(0, arm.vgetq_lane_u64(x0, 0))
		crc = arm.__crc32d(crc, arm.vgetq_lane_u64(x0, 1))
	}

	for length - p >= 8 {
		crc = arm.__crc32d(crc, intrinsics.unaligned_load((^u64)(data[p:])))
		p += 8
	}
	for p < length {
		crc = arm.__crc32b(crc, data[p])
		p += 1
	}
	return crc, p
}
