#+build arm64,arm32
package simd_arm

@(require_results,enable_target_feature="aes")
vaeseq_u8 :: #force_inline proc "c" (data, key: uint8x16_t) -> uint8x16_t {
	return _vaeseq_u8(data, key)
}

@(require_results,enable_target_feature="aes")
vaesdq_u8 :: #force_inline proc "c" (data, key: uint8x16_t) -> uint8x16_t {
	return _vaesdq_u8(data, key)
}

@(require_results,enable_target_feature="aes")
vaesmcq_u8 :: #force_inline proc "c" (data: uint8x16_t) -> uint8x16_t {
	return _vaesmcq_u8(data)
}

@(require_results,enable_target_feature="aes")
vaesimcq_u8 :: #force_inline proc "c" (data: uint8x16_t) -> uint8x16_t {
	return _vaesimcq_u8(data)
}

@(private,default_calling_convention="none")
foreign _ {
	@(link_name = "llvm.aarch64.crypto.aese" when ODIN_ARCH == .arm64 else "llvm.arm.neon.aese")
	_vaeseq_u8 :: proc(data, key: uint8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.crypto.aesd" when ODIN_ARCH == .arm64 else "llvm.arm.neon.aesd")
	_vaesdq_u8 :: proc(data, key: uint8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.crypto.aesmc" when ODIN_ARCH == .arm64 else "llvm.arm.neon.aesmc")
	_vaesmcq_u8 :: proc(data: uint8x16_t) -> uint8x16_t ---
	@(link_name = "llvm.aarch64.crypto.aesimc" when ODIN_ARCH == .arm64 else "llvm.arm.neon.aesimc")
	_vaesimcq_u8 :: proc(data: uint8x16_t) -> uint8x16_t ---
}
