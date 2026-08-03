#+build arm64,arm32
package simd_arm

import "core:simd"
_ :: simd

// SHA1 hash update accelerator, choose.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1cq_u32)
@(require_results, enable_target_feature = "sha2")
vsha1cq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha1cq_u32(hash_abcd, hash_e, wk)
	} else {
		hash_abcd := simd.shuffle(hash_abcd, hash_abcd, 3, 2, 1, 0)
		wk := simd.shuffle(wk, wk, 3, 2, 1, 0)
		c := _vsha1cq_u32(hash_abcd, hash_e, wk)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA1 hash update accelerator, parity.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1pq_u32)
@(require_results, enable_target_feature = "sha2")
vsha1pq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha1pq_u32(hash_abcd, hash_e, wk)
	} else {
		hash_abcd := simd.shuffle(hash_abcd, hash_abcd, 3, 2, 1, 0)
		wk := simd.shuffle(wk, wk, 3, 2, 1, 0)
		c := _vsha1pq_u32(hash_abcd, hash_e, wk)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA1 hash update accelerator, majority.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1mq_u32)
@(require_results, enable_target_feature = "sha2")
vsha1mq_u32 :: #force_inline proc "c" (hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha1mq_u32(hash_abcd, hash_e, wk)
	} else {
		hash_abcd := simd.shuffle(hash_abcd, hash_abcd, 3, 2, 1, 0)
		wk := simd.shuffle(wk, wk, 3, 2, 1, 0)
		c := _vsha1mq_u32(hash_abcd, hash_e, wk)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA1 fixed rotate.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1h_u32)
@(require_results, enable_target_feature = "sha2")
vsha1h_u32 :: #force_inline proc "c" (hash_e: uint32_t) -> uint32_t {
	return _vsha1h_u32(hash_e)
}

// SHA1 schedule update accelerator, first part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1su0q_u32)
@(require_results, enable_target_feature = "sha2")
vsha1su0q_u32 :: #force_inline proc "c" (w0_3, w4_7, w8_11: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha1su0q_u32(w0_3, w4_7, w8_11)
	} else {
		w0_3 := simd.shuffle(w0_3, w0_3, 3, 2, 1, 0)
		w4_7 := simd.shuffle(w4_7, w4_7, 3, 2, 1, 0)
		w8_11 := simd.shuffle(w8_11, w8_11, 3, 2, 1, 0)
		c := _vsha1su0q_u32(w0_3, w4_7, w8_11)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA1 schedule update accelerator, second part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha1su1q_u32)
@(require_results, enable_target_feature = "sha2")
vsha1su1q_u32 :: #force_inline proc "c" (tw0_3, w12_15: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha1su1q_u32(tw0_3, w12_15)
	} else {
		tw0_3 := simd.shuffle(tw0_3, tw0_3, 3, 2, 1, 0)
		w12_15 := simd.shuffle(w12_15, w12_15, 3, 2, 1, 0)
		c := _vsha1su1q_u32(tw0_3, w12_15)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA256 hash update accelerator, first part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha256hq_u32)
@(require_results, enable_target_feature = "sha2")
vsha256hq_u32 :: #force_inline proc "c" (hash_abcd, hash_efgh, wk: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha256hq_u32(hash_abcd, hash_efgh, wk)
	} else {
		hash_abcd := simd.shuffle(hash_abcd, hash_abcd, 3, 2, 1, 0)
		hash_efgh := simd.shuffle(hash_efgh, hash_efgh, 3, 2, 1, 0)
		wk := simd.shuffle(wk, wk, 3, 2, 1, 0)
		c := _vsha256hq_u32(hash_abcd, hash_efgh, wk)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA256 hash update accelerator, second part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha256h2q_u32)
@(require_results, enable_target_feature = "sha2")
vsha256h2q_u32 :: #force_inline proc "c" (hash_efgh, hash_abcd, wk: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha256h2q_u32(hash_efgh, hash_abcd, wk)
	} else {
		hash_abcd := simd.shuffle(hash_abcd, hash_abcd, 3, 2, 1, 0)
		hash_efgh := simd.shuffle(hash_efgh, hash_efgh, 3, 2, 1, 0)
		wk := simd.shuffle(wk, wk, 3, 2, 1, 0)
		c := _vsha256h2q_u32(hash_efgh, hash_abcd, wk)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA256 schedule update accelerator, first part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha256su0q_u32)
@(require_results, enable_target_feature = "sha2")
vsha256su0q_u32 :: #force_inline proc "c" (w0_3, w4_7: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha256su0q_u32(w0_3, w4_7)
	} else {
		w0_3 := simd.shuffle(w0_3, w0_3, 3, 2, 1, 0)
		w4_7 := simd.shuffle(w4_7, w4_7, 3, 2, 1, 0)
		c := _vsha256su0q_u32(w0_3, w4_7)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

// SHA256 schedule update accelerator, second part.
//
// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha256su1q_u32)
@(require_results, enable_target_feature = "sha2")
vsha256su1q_u32 :: #force_inline proc "c" (tw0_3, w8_11, w12_15: uint32x4_t) -> uint32x4_t {
	when ODIN_ENDIAN == .Little {
		return _vsha256su1q_u32(tw0_3, w8_11, w12_15)
	} else {
		tw0_3 := simd.shuffle(tw0_3, tw0_3, 3, 2, 1, 0)
		w8_11 := simd.shuffle(w8_11, w8_11, 3, 2, 1, 0)
		w12_15 := simd.shuffle(w12_15, w12_15, 3, 2, 1, 0)
		c := _vsha256su1q_u32(tw0_3, w8_11, w12_15)
		return simd_shuffle(c, c, 3, 2, 1, 0)
	}
}

when ODIN_ARCH == .arm64 {
	// SHA512 hash update accelerator, first part.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha512hq_u64)
	@(require_results, enable_target_feature = "sha3")
	vsha512hq_u64 :: #force_inline proc "c" (hash_ed, hash_gf, kwh_kwh2: uint64x2_t) -> uint64x2_t {
		when ODIN_ENDIAN == .Little {
			return _vsha512hq_u64(hash_ed, hash_gf, kwh_kwh2)
		} else {
			hash_ed := simd.shuffle(hash_ed, hash_ed, 1, 0)
			hash_gf := simd.shuffle(hash_gf, hash_gf, 1, 0)
			kwh_kwh2 := simd.shuffle(kwh_kwh2, kwh_kwh2, 1, 0)
			c := _vsha512hq_u64(hash_ed, hash_gf, kwh_kwh2)
			return simd.shuffle(c, c, 1, 0)
		}
	}

	// SHA512 hash update accelerator, second part.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha512h2q_u64)
	@(require_results, enable_target_feature = "sha3")
	vsha512h2q_u64 :: #force_inline proc "c" (sum_ab, hash_c_, hash_ab: uint64x2_t) -> uint64x2_t {
		when ODIN_ENDIAN == .Little {
			return _vsha512h2q_u64(sum_ab, hash_c_, hash_ab)
		} else {
			sum_ab := simd.shuffle(sum_ab, sum_ab, 1, 0)
			hash_c_ := simd.shuffle(hash_c_, hash_c_, 1, 0)
			hash_ab := simd.shuffle(hash_ab, hash_ab, 1, 0)
			c := _vsha512h2q_u64(sum_ab, hash_c_, hash_ab)
			return simd.shuffle(c, c, 1, 0)
		}
	}

	// SHA512 schedule update accelerator, first part.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha512su0q_u64)
	@(require_results, enable_target_feature = "sha3")
	vsha512su0q_u64 :: #force_inline proc "c" (w0_1, w2_: uint64x2_t) -> uint64x2_t {
		when ODIN_ENDIAN == .Little {
			return _vsha512su0q_u64(w0_1, w2_)
		} else {
			w0_1 := simd.shuffle(w0_1, w0_1, 1, 0)
			w2_ := simd.shuffle(w2_, w2_, 1, 0)
			c := _vsha512su0q_u64(w0_1, w2_)
			return simd.shuffle(c, c, 1, 0)
		}
	}

	// SHA512 schedule update accelerator, second part.
	//
	// [Arm's documentation](https://developer.arm.com/architectures/instruction-sets/intrinsics/vsha512su1q_u64)
	@(require_results, enable_target_feature = "sha3")
	vsha512su1q_u64 :: #force_inline proc "c" (s01_s02, w14_15, w9_10: uint64x2_t) -> uint64x2_t {
		when ODIN_ENDIAN == .Little {
			return _vsha512su1q_u64(s01_s02, w14_15, w9_10)
		} else {
			s01_s02 := simd.shuffle(s01_s02, s01_s02, 1, 0)
			w14_15 := simd.shuffle(w14_15, w14_15, 1, 0)
			w9_10 := simd.shuffle(w9_10, w9_10, 1, 0)
			c := _vsha512su1q_u64(s01_s02, w14_15, w9_10)
			return simd.shuffle(c, c, 1, 0)
		}
	}
}

@(private, default_calling_convention = "none")
foreign _ {
	@(link_name = "llvm.aarch64.crypto.sha1c" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1c")
	_vsha1cq_u32 :: proc(hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1p" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1p")
	_vsha1pq_u32 :: proc(hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1m" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1m")
	_vsha1mq_u32 :: proc(hash_abcd: uint32x4_t, hash_e: uint32_t, wk: uint32x4_t) -> uint32x4_t ---
	@(link_name = "llvm.aarch64.crypto.sha1h" when ODIN_ARCH == .arm64 else "llvm.arm.neon.sha1h")
	_vsha1h_u32 :: proc(hash_e: uint32_t) -> uint32_t ---
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
}

when ODIN_ARCH == .arm64 {
	@(private, default_calling_convention = "none")
	foreign _ {
		@(link_name = "llvm.aarch64.crypto.sha512h")
		_vsha512hq_u64 :: proc(hash_ed, hash_gf, kwh_kwh2: uint64x2_t) -> uint64x2_t ---
		@(link_name = "llvm.aarch64.crypto.sha512h2")
		_vsha512h2q_u64 :: proc(sum_ab, hash_c_, hash_ab: uint64x2_t) -> uint64x2_t ---
		@(link_name = "llvm.aarch64.crypto.sha512su0")
		_vsha512su0q_u64 :: proc(w0_1, w2_: uint64x2_t) -> uint64x2_t ---
		@(link_name = "llvm.aarch64.crypto.sha512su1")
		_vsha512su1q_u64 :: proc(s01_s02, w14_15, w9_10: uint64x2_t) -> uint64x2_t ---
	}
}
