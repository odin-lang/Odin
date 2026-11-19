#+build arm64
package hash

import "base:intrinsics"
import "core:simd/arm"

@(private)
CRC64_XZ_HW_STATIC :: ODIN_OS == .Darwin || intrinsics.has_target_feature("aes")

@(private)
CRC64_XZ_HW_MIN :: 32

@(private)
crc64_xz_hw_available :: #force_inline proc "contextless" () -> bool {
	return CRC64_XZ_HW_STATIC
}

@(private, enable_target_feature="neon,aes")
crc64_xz_hw :: proc "contextless" (crc: u64, data: [^]byte, length: int) -> (new_crc: u64, consumed: int) #no_bounds_check {
	K512 :: arm.uint64x2_t{0x6ae3efbb9dd441f3, 0x081f6054a7842df4}
	K128 :: arm.uint64x2_t{0xe05dd497ca393ae4, 0xdabe95afc7875f40}

	@(enable_target_feature="neon,aes")
	fold :: #force_inline proc "contextless" (x, k: arm.uint64x2_t) -> arm.uint64x2_t {
		lo := arm.vmull_p64(arm.vgetq_lane_u64(x, 0), arm.vgetq_lane_u64(k, 0))
		hi := arm.vmull_p64(arm.vgetq_lane_u64(x, 1), arm.vgetq_lane_u64(k, 1))
		return transmute(arm.uint64x2_t)(lo ~ hi)
	}
	@(enable_target_feature="neon")
	load :: #force_inline proc "contextless" (p: [^]byte) -> arm.uint64x2_t {
		return intrinsics.unaligned_load((^arm.uint64x2_t)(p))
	}

	x0 := load(data[0:]) ~ arm.uint64x2_t{crc, 0}
	p  := 16

	if length >= 64 {
		x1 := load(data[16:])
		x2 := load(data[32:])
		x3 := load(data[48:])
		p = 64

		for length - p >= 64 {
			x0 = fold(x0, K512) ~ load(data[p:])
			x1 = fold(x1, K512) ~ load(data[p + 16:])
			x2 = fold(x2, K512) ~ load(data[p + 32:])
			x3 = fold(x3, K512) ~ load(data[p + 48:])
			p += 64
		}

		x0 = fold(x0, K128) ~ x1
		x0 = fold(x0, K128) ~ x2
		x0 = fold(x0, K128) ~ x3
	}
	for length - p >= 16 {
		x0 = fold(x0, K128) ~ load(data[p:])
		p += 16
	}

	folded: [16]byte = ---
	intrinsics.unaligned_store((^arm.uint64x2_t)(&folded), x0)
	return crc64_xz_table(0, folded[:]), p
}
