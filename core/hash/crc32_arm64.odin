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
crc32_hw :: proc "contextless" (crc: u32, dst, src: [^]byte, length: int, $COPY: bool) -> (new_crc: u32, consumed: int) #no_bounds_check {
	K12 :: arm.uint64x2_t{0x154442bd4, 0x1c6e41596}
	K34 :: arm.uint64x2_t{0x1751997d0, 0x0ccaa009e}

	@(enable_target_feature="neon,aes")
	fold :: #force_inline proc "contextless" (x, k: arm.uint64x2_t) -> arm.uint64x2_t {
		lo := arm.vmull_p64(arm.vgetq_lane_u64(x, 0), arm.vgetq_lane_u64(k, 0))
		hi := arm.vmull_p64(arm.vgetq_lane_u64(x, 1), arm.vgetq_lane_u64(k, 1))
		return transmute(arm.uint64x2_t)(lo ~ hi)
	}
	@(enable_target_feature="neon,aes")
	load :: #force_inline proc "contextless" (dst, src: [^]byte, p: int, $COPY: bool) -> arm.uint64x2_t {
		v := intrinsics.unaligned_load((^arm.uint64x2_t)(src[p:]))
		when COPY {
			intrinsics.unaligned_store((^arm.uint64x2_t)(dst[p:]), v)
		}
		return v
	}

	crc := crc
	p   := 0

	if length >= CRC32_FOLD_MIN {
		x0 := load(dst, src, 0, COPY) ~ arm.uint64x2_t{u64(crc), 0}
		x1 := load(dst, src, 16, COPY)
		x2 := load(dst, src, 32, COPY)
		x3 := load(dst, src, 48, COPY)
		p = 64

		for length - p >= 64 {
			x0 = fold(x0, K12) ~ load(dst, src, p, COPY)
			x1 = fold(x1, K12) ~ load(dst, src, p + 16, COPY)
			x2 = fold(x2, K12) ~ load(dst, src, p + 32, COPY)
			x3 = fold(x3, K12) ~ load(dst, src, p + 48, COPY)
			p += 64
		}

		x0 = fold(x0, K34) ~ x1
		x0 = fold(x0, K34) ~ x2
		x0 = fold(x0, K34) ~ x3
		for length - p >= 16 {
			x0 = fold(x0, K34) ~ load(dst, src, p, COPY)
			p += 16
		}

		crc = arm.__crc32d(0, arm.vgetq_lane_u64(x0, 0))
		crc = arm.__crc32d(crc, arm.vgetq_lane_u64(x0, 1))
	}

	for length - p >= 8 {
		w := intrinsics.unaligned_load((^u64)(src[p:]))
		when COPY {
			intrinsics.unaligned_store((^u64)(dst[p:]), w)
		}
		crc = arm.__crc32d(crc, w)
		p += 8
	}
	for p < length {
		when COPY {
			dst[p] = src[p]
		}
		crc = arm.__crc32b(crc, src[p])
		p += 1
	}
	return crc, p
}
