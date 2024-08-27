package chacha20_simd128

import "base:intrinsics"
import "core:crypto/_chacha20"
import "core:simd"
@(require) import "core:sys/info"

// Portable 128-bit `core:simd` implementation.
//
// This is loosely based on Ted Krovetz's public domain C intrinsic
// implementation.
//
// This is written to perform adequately on any target that has "enough"
// 128-bit vector registers, the current thought is that 4 blocks at at
// time is reasonable for amd64, though Ted's code is more conservative.
//
// See:
// supercop-20230530/crypto_stream/chacha20/krovetz/vec128

// Ensure the compiler emits SIMD instructions.  This is a minimum, and
// setting the microarchitecture at compile time will allow for better
// code gen when applicable (eg: AVX).  This is somewhat redundant with
// the default microarchitecture configurations.
when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
	@(private = "file")
	TARGET_SIMD_FEATURES :: "neon"
} else when ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 {
	// Note: LLVM appears to be smart enough to use PSHUFB despite not
	// explicitly using simd.u8x16 shuffles.
	@(private = "file")
	TARGET_SIMD_FEATURES :: "sse2,ssse3"
} else when ODIN_ARCH == .riscv64 {
	@(private = "file")
	TARGET_SIMD_FEATURES :: "v"
} else {
	@(private = "file")
	TARGET_SIMD_FEATURES :: ""
}

// Some targets lack runtime feature detection, and will flat out refuse
// to load binaries that have unknown instructions.  This is distinct from
// `simd.IS_EMULATED` as actually good designs support runtime feature
// detection and that constant establishes a baseline.
//
// See:
// - https://github.com/WebAssembly/design/issues/1161
@(private = "file")
TARGET_IS_DESIGNED_BY_IDIOTS :: (ODIN_ARCH == .wasm64p32 || ODIN_ARCH == .wasm32) && !intrinsics.has_target_feature("simd128")

@(private = "file")
_ROT_7L: simd.u32x4 : {7, 7, 7, 7}
@(private = "file")
_ROT_7R: simd.u32x4 : {25, 25, 25, 25}
@(private = "file")
_ROT_12L: simd.u32x4 : {12, 12, 12, 12}
@(private = "file")
_ROT_12R: simd.u32x4 : {20, 20, 20, 20}
@(private = "file")
_ROT_8L: simd.u32x4 : {8, 8, 8, 8}
@(private = "file")
_ROT_8R: simd.u32x4 : {24, 24, 24, 24}
@(private = "file")
_ROT_16: simd.u32x4 : {16, 16, 16, 16}

when ODIN_ENDIAN == .Big {
	@(private = "file")
	_increment_counter :: #force_inline proc "contextless" (ctx: ^_chacha20.Context) -> simd.u32x4 {
		// In the Big Endian case, the low and high portions in the vector
		// are flipped, so the 64-bit addition can't be done with a simple
		// vector add.
		x := &ctx._s

		new_ctr := ((u64(ctx._s[13]) << 32) | u64(ctx._s[12])) + 1
		x[12] = u32(new_ctr)
		x[13] = u32(new_ctr >> 32)

		return intrinsics.unaligned_load(transmute(^simd.u32x4)&x[12])
	}

	// Convert the endian-ness of the components of a u32x4 vector, for
	// the purposes of output.
	@(private = "file")
	_byteswap_u32x4 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
		return(
			transmute(simd.u32x4)simd.shuffle(
				transmute(simd.u8x16)v,
				transmute(simd.u8x16)v,
				3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
			)
		)
	}
} else {
	@(private = "file")
	_VEC_ONE: simd.u64x2 : {1, 0}
}

@(private = "file")
_dq_round_simd128 :: #force_inline proc "contextless" (
	v0, v1, v2, v3: simd.u32x4,
) -> (
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
) {
	v0, v1, v2, v3 := v0, v1, v2, v3

	// a += b; d ^= a; d = ROTW16(d);
	v0 = simd.add(v0, v1)
	v3 = simd.bit_xor(v3, v0)
	v3 = simd.bit_xor(simd.shl(v3, _ROT_16), simd.shr(v3, _ROT_16))

	// c += d; b ^= c; b = ROTW12(b);
	v2 = simd.add(v2, v3)
	v1 = simd.bit_xor(v1, v2)
	v1 = simd.bit_xor(simd.shl(v1, _ROT_12L), simd.shr(v1, _ROT_12R))

	// a += b; d ^= a; d = ROTW8(d);
	v0 = simd.add(v0, v1)
	v3 = simd.bit_xor(v3, v0)
	v3 = simd.bit_xor(simd.shl(v3, _ROT_8L), simd.shr(v3, _ROT_8R))

	// c += d; b ^= c; b = ROTW7(b);
	v2 = simd.add(v2, v3)
	v1 = simd.bit_xor(v1, v2)
	v1 = simd.bit_xor(simd.shl(v1, _ROT_7L), simd.shr(v1, _ROT_7R))

	// b = ROTV1(b); c = ROTV2(c);  d = ROTV3(d);
	v1 = simd.shuffle(v1, v1, 1, 2, 3, 0)
	v2 = simd.shuffle(v2, v2, 2, 3, 0, 1)
	v3 = simd.shuffle(v3, v3, 3, 0, 1, 2)

	// a += b; d ^= a; d = ROTW16(d);
	v0 = simd.add(v0, v1)
	v3 = simd.bit_xor(v3, v0)
	v3 = simd.bit_xor(simd.shl(v3, _ROT_16), simd.shr(v3, _ROT_16))

	// c += d; b ^= c; b = ROTW12(b);
	v2 = simd.add(v2, v3)
	v1 = simd.bit_xor(v1, v2)
	v1 = simd.bit_xor(simd.shl(v1, _ROT_12L), simd.shr(v1, _ROT_12R))

	// a += b; d ^= a; d = ROTW8(d);
	v0 = simd.add(v0, v1)
	v3 = simd.bit_xor(v3, v0)
	v3 = simd.bit_xor(simd.shl(v3, _ROT_8L), simd.shr(v3, _ROT_8R))

	// c += d; b ^= c; b = ROTW7(b);
	v2 = simd.add(v2, v3)
	v1 = simd.bit_xor(v1, v2)
	v1 = simd.bit_xor(simd.shl(v1, _ROT_7L), simd.shr(v1, _ROT_7R))

	// b = ROTV3(b); c = ROTV2(c); d = ROTV1(d);
	v1 = simd.shuffle(v1, v1, 3, 0, 1, 2)
	v2 = simd.shuffle(v2, v2, 2, 3, 0, 1)
	v3 = simd.shuffle(v3, v3, 1, 2, 3, 0)

	return v0, v1, v2, v3
}

@(private = "file")
_add_state_simd128 :: #force_inline proc "contextless" (
	v0, v1, v2, v3, s0, s1, s2, s3: simd.u32x4,
) -> (
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
) {
	v0, v1, v2, v3 := v0, v1, v2, v3

	v0 = simd.add(v0, s0)
	v1 = simd.add(v1, s1)
	v2 = simd.add(v2, s2)
	v3 = simd.add(v3, s3)

	when ODIN_ENDIAN == .Big {
		v0 = _byteswap_u32x4(v0)
		v1 = _byteswap_u32x4(v1)
		v2 = _byteswap_u32x4(v2)
		v3 = _byteswap_u32x4(v3)
	}

	return v0, v1, v2, v3
}

@(private = "file")
_xor_simd128 :: #force_inline proc "contextless" (
	src: [^]simd.u32x4,
	v0, v1, v2, v3: simd.u32x4,
) -> (
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
	simd.u32x4,
) {
	v0, v1, v2, v3 := v0, v1, v2, v3

	v0 = simd.bit_xor(v0, intrinsics.unaligned_load((^simd.u32x4)(src[0:])))
	v1 = simd.bit_xor(v1, intrinsics.unaligned_load((^simd.u32x4)(src[1:])))
	v2 = simd.bit_xor(v2, intrinsics.unaligned_load((^simd.u32x4)(src[2:])))
	v3 = simd.bit_xor(v3, intrinsics.unaligned_load((^simd.u32x4)(src[3:])))

	return v0, v1, v2, v3
}

@(private = "file")
_store_simd128 :: #force_inline proc "contextless" (
	dst: [^]simd.u32x4,
	v0, v1, v2, v3: simd.u32x4,
) {
	intrinsics.unaligned_store((^simd.u32x4)(dst[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x4)(dst[1:]), v1)
	intrinsics.unaligned_store((^simd.u32x4)(dst[2:]), v2)
	intrinsics.unaligned_store((^simd.u32x4)(dst[3:]), v3)
}

// is_performant returns true iff the target and current host both support
// "enough" 128-bit SIMD to make this implementation performant.
is_performant :: proc "contextless" () -> bool {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 || ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 || ODIN_ARCH == .riscv64 {
		when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
			req_features :: info.CPU_Features{.asimd}
		} else when ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 {
			req_features :: info.CPU_Features{.sse2, .ssse3}
		} else when ODIN_ARCH == .riscv64 {
			req_features :: info.CPU_Features{.V}
		}

		features, ok := info.cpu_features.?
		if !ok {
			return false
		}

		return features >= req_features
	} else when ODIN_ARCH == .wasm64p32 || ODIN_ARCH == .wasm32 {
		return intrinsics.has_target_feature("simd128")
	} else {
		return false
	}
}

@(enable_target_feature = TARGET_SIMD_FEATURES)
stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per IV.
	_chacha20.check_counter_limit(ctx, nr_blocks)

	dst_v := ([^]simd.u32x4)(raw_data(dst))
	src_v := ([^]simd.u32x4)(raw_data(src))

	x := &ctx._s
	n := nr_blocks

	// The state vector is an array of uint32s in native byte-order.
	x_v := ([^]simd.u32x4)(raw_data(x))
	s0 := intrinsics.unaligned_load((^simd.u32x4)(x_v[0:]))
	s1 := intrinsics.unaligned_load((^simd.u32x4)(x_v[1:]))
	s2 := intrinsics.unaligned_load((^simd.u32x4)(x_v[2:]))
	s3 := intrinsics.unaligned_load((^simd.u32x4)(x_v[3:]))

	// 8 blocks at a time.
	//
	// Note:
	// This uses a ton of registers so it is only worth it on targets
	// that have something like 32 128-bit registers.  This is currently
	// all ARMv8 targets, and RISC-V Zvl128b (`V` application profile)
	// targets.
	//
	// While our current definition of `.arm32` is 32-bit ARMv8, this
	// may change in the future (ARMv7 is still relevant), and things
	// like Cortex-A8/A9 does "pretend" 128-bit SIMD 64-bits at a time
	// thus needs bemchmarking.
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		for ; n >= 8; n = n - 8 {
			v0, v1, v2, v3 := s0, s1, s2, s3

			when ODIN_ENDIAN == .Little {
				s7 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s3, _VEC_ONE)
			} else {
				s7 := _increment_counter(ctx)
			}
			v4, v5, v6, v7 := s0, s1, s2, s7

			when ODIN_ENDIAN == .Little {
				s11 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s7, _VEC_ONE)
			} else {
				s11 := _increment_counter(ctx)
			}
			v8, v9, v10, v11 := s0, s1, s2, s11

			when ODIN_ENDIAN == .Little {
				s15 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s11, _VEC_ONE)
			} else {
				s15 := _increment_counter(ctx)
			}
			v12, v13, v14, v15 := s0, s1, s2, s15

			when ODIN_ENDIAN == .Little {
				s19 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s15, _VEC_ONE)
			} else {
				s19 := _increment_counter(ctx)
			}

			v16, v17, v18, v19 := s0, s1, s2, s19
			when ODIN_ENDIAN == .Little {
				s23 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s19, _VEC_ONE)
			} else {
				s23 := _increment_counter(ctx)
			}

			v20, v21, v22, v23 := s0, s1, s2, s23
			when ODIN_ENDIAN == .Little {
				s27 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s23, _VEC_ONE)
			} else {
				s27 := _increment_counter(ctx)
			}

			v24, v25, v26, v27 := s0, s1, s2, s27
			when ODIN_ENDIAN == .Little {
				s31 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s27, _VEC_ONE)
			} else {
				s31 := _increment_counter(ctx)
			}
			v28, v29, v30, v31 := s0, s1, s2, s31

			for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
				v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
				v4, v5, v6, v7 = _dq_round_simd128(v4, v5, v6, v7)
				v8, v9, v10, v11 = _dq_round_simd128(v8, v9, v10, v11)
				v12, v13, v14, v15 = _dq_round_simd128(v12, v13, v14, v15)
				v16, v17, v18, v19 = _dq_round_simd128(v16, v17, v18, v19)
				v20, v21, v22, v23 = _dq_round_simd128(v20, v21, v22, v23)
				v24, v25, v26, v27 = _dq_round_simd128(v24, v25, v26, v27)
				v28, v29, v30, v31 = _dq_round_simd128(v28, v29, v30, v31)
			}

			v0, v1, v2, v3 = _add_state_simd128(v0, v1, v2, v3, s0, s1, s2, s3)
			v4, v5, v6, v7 = _add_state_simd128(v4, v5, v6, v7, s0, s1, s2, s7)
			v8, v9, v10, v11 = _add_state_simd128(v8, v9, v10, v11, s0, s1, s2, s11)
			v12, v13, v14, v15 = _add_state_simd128(v12, v13, v14, v15, s0, s1, s2, s15)
			v16, v17, v18, v19 = _add_state_simd128(v16, v17, v18, v19, s0, s1, s2, s19)
			v20, v21, v22, v23 = _add_state_simd128(v20, v21, v22, v23, s0, s1, s2, s23)
			v24, v25, v26, v27 = _add_state_simd128(v24, v25, v26, v27, s0, s1, s2, s27)
			v28, v29, v30, v31 = _add_state_simd128(v28, v29, v30, v31, s0, s1, s2, s31)

			#no_bounds_check {
				if src != nil {
					v0, v1, v2, v3 = _xor_simd128(src_v, v0, v1, v2, v3)
					v4, v5, v6, v7 = _xor_simd128(src_v[4:], v4, v5, v6, v7)
					v8, v9, v10, v11 = _xor_simd128(src_v[8:], v8, v9, v10, v11)
					v12, v13, v14, v15 = _xor_simd128(src_v[12:], v12, v13, v14, v15)
					v16, v17, v18, v19 = _xor_simd128(src_v[16:], v16, v17, v18, v19)
					v20, v21, v22, v23 = _xor_simd128(src_v[20:], v20, v21, v22, v23)
					v24, v25, v26, v27 = _xor_simd128(src_v[24:], v24, v25, v26, v27)
					v28, v29, v30, v31 = _xor_simd128(src_v[28:], v28, v29, v30, v31)
					src_v = src_v[32:]
				}

				_store_simd128(dst_v, v0, v1, v2, v3)
				_store_simd128(dst_v[4:], v4, v5, v6, v7)
				_store_simd128(dst_v[8:], v8, v9, v10, v11)
				_store_simd128(dst_v[12:], v12, v13, v14, v15)
				_store_simd128(dst_v[16:], v16, v17, v18, v19)
				_store_simd128(dst_v[20:], v20, v21, v22, v23)
				_store_simd128(dst_v[24:], v24, v25, v26, v27)
				_store_simd128(dst_v[28:], v28, v29, v30, v31)
				dst_v = dst_v[32:]
			}

			when ODIN_ENDIAN == .Little {
				// s31 holds the most current counter, so `s3 = s31 + 1`.
				s3 = transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s31, _VEC_ONE)
			} else {
				s3 = _increment_counter(ctx)
			}
		}
	}

	// 4 blocks at a time.
	//
	// Note: This is skipped on several targets for various reasons.
	// - i386 lacks the required number of registers
	// - Generating code when runtime "hardware" SIMD support is impossible
	//   to detect is pointless, since this will be emulated using GP regs.
	when ODIN_ARCH != .i386 && !TARGET_IS_DESIGNED_BY_IDIOTS {
		for ; n >= 4; n = n - 4 {
			v0, v1, v2, v3 := s0, s1, s2, s3

			when ODIN_ENDIAN == .Little {
				s7 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s3, _VEC_ONE)
			} else {
				s7 := _increment_counter(ctx)
			}
			v4, v5, v6, v7 := s0, s1, s2, s7

			when ODIN_ENDIAN == .Little {
				s11 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s7, _VEC_ONE)
			} else {
				s11 := _increment_counter(ctx)
			}
			v8, v9, v10, v11 := s0, s1, s2, s11

			when ODIN_ENDIAN == .Little {
				s15 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s11, _VEC_ONE)
			} else {
				s15 := _increment_counter(ctx)
			}
			v12, v13, v14, v15 := s0, s1, s2, s15

			for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
				v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
				v4, v5, v6, v7 = _dq_round_simd128(v4, v5, v6, v7)
				v8, v9, v10, v11 = _dq_round_simd128(v8, v9, v10, v11)
				v12, v13, v14, v15 = _dq_round_simd128(v12, v13, v14, v15)
			}

			v0, v1, v2, v3 = _add_state_simd128(v0, v1, v2, v3, s0, s1, s2, s3)
			v4, v5, v6, v7 = _add_state_simd128(v4, v5, v6, v7, s0, s1, s2, s7)
			v8, v9, v10, v11 = _add_state_simd128(v8, v9, v10, v11, s0, s1, s2, s11)
			v12, v13, v14, v15 = _add_state_simd128(v12, v13, v14, v15, s0, s1, s2, s15)

			#no_bounds_check {
				if src != nil {
					v0, v1, v2, v3 = _xor_simd128(src_v, v0, v1, v2, v3)
					v4, v5, v6, v7 = _xor_simd128(src_v[4:], v4, v5, v6, v7)
					v8, v9, v10, v11 = _xor_simd128(src_v[8:], v8, v9, v10, v11)
					v12, v13, v14, v15 = _xor_simd128(src_v[12:], v12, v13, v14, v15)
					src_v = src_v[16:]
				}

				_store_simd128(dst_v, v0, v1, v2, v3)
				_store_simd128(dst_v[4:], v4, v5, v6, v7)
				_store_simd128(dst_v[8:], v8, v9, v10, v11)
				_store_simd128(dst_v[12:], v12, v13, v14, v15)
				dst_v = dst_v[16:]
			}

			when ODIN_ENDIAN == .Little {
				// s15 holds the most current counter, so `s3 = s15 + 1`.
				s3 = transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s15, _VEC_ONE)
			} else {
				s3 = _increment_counter(ctx)
			}
		}
	}

	// 1 block at a time.
	for ; n > 0; n = n - 1 {
		v0, v1, v2, v3 := s0, s1, s2, s3

		for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
			v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
		}
		v0, v1, v2, v3 = _add_state_simd128(v0, v1, v2, v3, s0, s1, s2, s3)

		#no_bounds_check {
			if src != nil {
				v0, v1, v2, v3 = _xor_simd128(src_v, v0, v1, v2, v3)
				src_v = src_v[4:]
			}

			_store_simd128(dst_v, v0, v1, v2, v3)
			dst_v = dst_v[4:]
		}

		// Increment the counter.  Overflow checking is done upon
		// entry into the routine, so a 64-bit increment safely
		// covers both cases.
		when ODIN_ENDIAN == .Little {
			s3 = transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s3, _VEC_ONE)
		} else {
			s3 = _increment_counter(ctx)
		}
	}

	when ODIN_ENDIAN == .Little {
		// Write back the counter to the state.
		intrinsics.unaligned_store((^simd.u32x4)(x_v[3:]), s3)
	}
}

@(enable_target_feature = TARGET_SIMD_FEATURES)
hchacha20 :: proc "contextless" (dst, key, iv: []byte) {
	v0 := simd.u32x4{_chacha20.SIGMA_0, _chacha20.SIGMA_1, _chacha20.SIGMA_2, _chacha20.SIGMA_3}
	v1 := intrinsics.unaligned_load((^simd.u32x4)(&key[0]))
	v2 := intrinsics.unaligned_load((^simd.u32x4)(&key[16]))
	v3 := intrinsics.unaligned_load((^simd.u32x4)(&iv[0]))

	when ODIN_ENDIAN == .Big {
		v1 = _byteswap_u32x4(v1)
		v2 = _byteswap_u32x4(v2)
		v3 = _byteswap_u32x4(v3)
	}

	for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
		v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
	}

	when ODIN_ENDIAN == .Big {
		v0 = _byteswap_u32x4(v0)
		v3 = _byteswap_u32x4(v3)
	}

	dst_v := ([^]simd.u32x4)(raw_data(dst))
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x4)(dst_v[1:]), v3)
}
