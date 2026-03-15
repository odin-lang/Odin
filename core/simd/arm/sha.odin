#+build arm64,arm32
package simd_arm

@(require_results, enable_target_feature = "sha2")
vsha1cq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	return _vsha1cq_u32(hash_abcd, e, wk)
}

@(require_results, enable_target_feature = "sha2")
vsha1pq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	return _vsha1pq_u32(hash_abcd, e, wk)
}

@(require_results, enable_target_feature = "sha2")
vsha1mq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	return _vsha1mq_u32(hash_abcd, e, wk)
}

@(require_results, enable_target_feature = "sha2")
vsha1h_u32 :: #force_inline proc "c" (e: uint32_t) -> uint32_t {
	return _vsha1h_u32(e)
}

@(require_results, enable_target_feature = "sha2")
vsha1su0q_u32 :: #force_inline proc "c" (w0_3, w4_7, w8_11: uint32x4_t) -> uint32x4_t {
	return _vsha1su0q_u32(w0_3, w4_7, w8_11)
}

@(require_results, enable_target_feature = "sha2")
vsha1su1q_u32 :: #force_inline proc "c" (tw0_3, w12_15: uint32x4_t) -> uint32x4_t {
	return _vsha1su1q_u32(tw0_3, w12_15)
}

@(require_results, enable_target_feature = "sha2")
vsha256hq_u32 :: #force_inline proc "c" (hash_abcd, hash_efgh, wk: uint32x4_t) -> uint32x4_t {
	return _vsha256hq_u32(hash_abcd, hash_efgh, wk)
}

@(require_results, enable_target_feature = "sha2")
vsha256h2q_u32 :: #force_inline proc "c" (hash_efgh, hash_abcd, wk: uint32x4_t) -> uint32x4_t {
	return _vsha256h2q_u32(hash_efgh, hash_abcd, wk)
}

@(require_results, enable_target_feature = "sha2")
vsha256su0q_u32 :: #force_inline proc "c" (w0_3, w4_7: uint32x4_t) -> uint32x4_t {
	return _vsha256su0q_u32(w0_3, w4_7)
}

@(require_results, enable_target_feature = "sha2")
vsha256su1q_u32 :: #force_inline proc "c" (tw0_3, w8_11, w12_15: uint32x4_t) -> uint32x4_t {
	return _vsha256su1q_u32(tw0_3, w8_11, w12_15)
}

// Note: The SHA512 instructions are part of the `sha3` feature set.

@(require_results, enable_target_feature = "sha3")
vsha512hq_u64 :: #force_inline proc "c" (hash_ed, hash_gf, kwh_kwh2: uint64x2_t) -> uint64x2_t {
	return _vsha512hq_u64(hash_ed, hash_gf, kwh_kwh2)
}

@(require_results, enable_target_feature = "sha3")
vsha512h2q_u64 :: #force_inline proc "c" (sum_ab, hash_c_, hash_ab: uint64x2_t) -> uint64x2_t {
	return _vsha512h2q_u64(sum_ab, hash_c_, hash_ab)
}

@(require_results, enable_target_feature = "sha3")
vsha512su0q_u64 :: #force_inline proc "c" (w0_1, w2_: uint64x2_t) -> uint64x2_t {
	return _vsha512su0q_u64(w0_1, w2_)
}

@(require_results, enable_target_feature = "sha3")
vsha512su1q_u64 :: #force_inline proc "c" (s01_s02, w14_15, w9_10: uint64x2_t) -> uint64x2_t {
	return _vsha512su1q_u64(s01_s02, w14_15, w9_10)
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.aarch64.crypto.sha1c" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1c")
	_vsha1cq_u32 :: proc(hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1p" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1p")
	_vsha1pq_u32 :: proc(hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1m" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1m")
	_vsha1mq_u32 :: proc(hash_abcd: uint32x4_t, e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1h" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1h")
	_vsha1h_u32 :: proc(e: uint32_t) -> uint32_t ---
	@(link_name = "llvm.aarch64.crypto.sha1su0" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1su0")
	_vsha1su0q_u32 :: proc(w0_3, w4_7, w8_11: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1su1" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1su1")
	_vsha1su1q_u32 :: proc(tw0_3, w12_15: uint32x4_t) -> uint32x4_t ---

	@(link_name = "llvm.aarch64.crypto.sha256h" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha256h")
	_vsha256hq_u32 :: proc(hash_abcd, hash_efgh, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha256h2" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha256h2")
	_vsha256h2q_u32 :: proc(hash_efgh, hash_abcd, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha256su0" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha256su0")
	_vsha256su0q_u32 :: proc(w0_3, w4_7: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha256su1" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha256su1")
	_vsha256su1q_u32 :: proc(tw0_3, w8_11, w12_15: uint32x4_t) -> uint32x4_t ---

	@(link_name = "llvm.aarch64.crypto.sha512h" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha512h")
	_vsha512hq_u64 :: proc(hash_ed, hash_gf, kwh_kwh2: uint64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.crypto.sha512h2" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha512h2")
	_vsha512h2q_u64 :: proc(sum_ab, hash_c_, hash_ab: uint64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.crypto.sha512su0" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha512su0")
	_vsha512su0q_u64 :: proc(w0_1, w2_: uint64x2_t) -> uint64x2_t ---
	@(link_name = "llvm.aarch64.crypto.sha512su1" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha512su1")
	_vsha512su1q_u64 :: proc(s01_s02, w14_15, w9_10: uint64x2_t) -> uint64x2_t ---
}
