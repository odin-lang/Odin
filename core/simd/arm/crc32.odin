#+build arm64,arm32
package simd_arm

// CRC32 single round checksum for bytes (8 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32b)
@(require_results, enable_target_feature = "crc")
__crc32b :: #force_inline proc "c" (crc: uint32_t, data: uint8_t) -> uint32_t {
	return ___crc32b(crc, uint32_t(data))
}

// CRC32-C single round checksum for bytes (8 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32cb)
@(require_results, enable_target_feature = "crc")
__crc32cb :: #force_inline proc "c" (crc: uint32_t, data: uint8_t) -> uint32_t {
	return ___crc32cb(crc, uint32_t(data))
}

// CRC32 single round checksum for bytes (16 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32h)
@(require_results, enable_target_feature = "crc")
__crc32h :: #force_inline proc "c" (crc: uint32_t, data: uint16_t) -> uint32_t {
	return ___crc32h(crc, uint32_t(data))
}

// CRC32-C single round checksum for bytes (16 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32ch)
@(require_results, enable_target_feature = "crc")
__crc32ch :: #force_inline proc "c" (crc: uint32_t, data: uint16_t) -> uint32_t {
	return ___crc32ch(crc, uint32_t(data))
}

// CRC32 single round checksum for bytes (32 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32w)
@(require_results, enable_target_feature = "crc")
__crc32w :: #force_inline proc "c" (crc: uint32_t, data: uint32_t) -> uint32_t {
	return ___crc32w(crc, data)
}

// CRC32-C single round checksum for bytes (32 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32cw)
@(require_results, enable_target_feature = "crc")
__crc32cw :: #force_inline proc "c" (crc: uint32_t, data: uint32_t) -> uint32_t {
	return ___crc32cw(crc, data)
}

// CRC32 single round checksum for quad words (64 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32d)
@(require_results, enable_target_feature = "crc")
__crc32d :: #force_inline proc "c" (crc: uint32_t, data: uint64_t) -> uint32_t {
	when ODIN_ARCH == .arm64 {
		return ___crc32d(crc, data)
	} else {
		b := uint32_t(data & 0xffffffff)
		c := uint32_t(data >> 32)
		return ___crc32w(___crc32w(crc, b), c)
	}
}

// CRC32-C single round checksum for quad words (64 bits).
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/__crc32cd)
@(require_results, enable_target_feature = "crc")
__crc32cd :: #force_inline proc "c" (crc: uint32_t, data: uint64_t) -> uint32_t {
	when ODIN_ARCH == .arm64 {
		return ___crc32cd(crc, data)
	} else {
		b := uint32_t(data & 0xffffffff)
		c := uint32_t(data >> 32)
		return ___crc32cw(___crc32cw(crc, b), c)
	}
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.aarch64.crc32b" when ODIN_ARCH == .arm64 else "llvm.arm.crc32b")
	___crc32b :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crc32h" when ODIN_ARCH == .arm64 else "llvm.arm.crc32h")
	___crc32h :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crc32w" when ODIN_ARCH == .arm64 else "llvm.arm.crc32w")
	___crc32w :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crc32cb" when ODIN_ARCH == .arm64 else "llvm.arm.crc32cb")
	___crc32cb :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crc32ch" when ODIN_ARCH == .arm64 else "llvm.arm.crc32ch")
	___crc32ch :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crc32cw" when ODIN_ARCH == .arm64 else "llvm.arm.crc32cw")
	___crc32cw :: proc(crc: uint32_t, data: uint32_t) -> uint32_t ---
}

when ODIN_ARCH == .arm64 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.aarch64.crc32x")
		___crc32d :: proc(crc: uint32_t, data: uint64_t) -> uint32_t ---
		@(link_name = "llvm.aarch64.crc32cx")
		___crc32cd :: proc(crc: uint32_t, data: uint64_t) -> uint32_t ---
	}
}
