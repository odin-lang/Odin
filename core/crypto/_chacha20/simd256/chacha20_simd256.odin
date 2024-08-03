//+build amd64
package chacha20_simd256

import "base:intrinsics"
import "core:crypto/_chacha20"
import chacha_simd128 "core:crypto/_chacha20/simd128"
import "core:simd"
import "core:sys/info"

// This is loosely based on Ted Krovetz's public domain C intrinsic
// implementations.  While written using `core:simd`, this is currently
// amd64 specific because we do not have a way to detect ARM SVE.
//
// See:
// supercop-20230530/crypto_stream/chacha20/krovetz/vec128
// supercop-20230530/crypto_stream/chacha20/krovetz/avx2

#assert(ODIN_ENDIAN == .Little)

@(private = "file")
_ROT_7L: simd.u32x8 : {7, 7, 7, 7, 7, 7, 7, 7}
@(private = "file")
_ROT_7R: simd.u32x8 : {25, 25, 25, 25, 25, 25, 25, 25}
@(private = "file")
_ROT_12L: simd.u32x8 : {12, 12, 12, 12, 12, 12, 12, 12}
@(private = "file")
_ROT_12R: simd.u32x8 : {20, 20, 20, 20, 20, 20, 20, 20}
@(private = "file")
_ROT_8L: simd.u32x8 : {8, 8, 8, 8, 8, 8, 8, 8}
@(private = "file")
_ROT_8R: simd.u32x8 : {24, 24, 24, 24, 24, 24, 24, 24}
@(private = "file")
_ROT_16: simd.u32x8 : {16, 16, 16, 16, 16, 16, 16, 16}
@(private = "file")
_VEC_ZERO_ONE: simd.u64x4 : {0, 0, 1, 0}
@(private = "file")
_VEC_TWO: simd.u64x4 : {2, 0, 2, 0}

// is_performant returns true iff the target and current host both support
// "enough" SIMD to make this implementation performant.
is_performant :: proc "contextless" () -> bool {
	req_features :: info.CPU_Features{.avx, .avx2}

	features, ok := info.cpu_features.?
	if !ok {
		return false
	}

	return features >= req_features
}

@(private = "file")
_dq_round_simd256 :: #force_inline proc "contextless" (
	v0, v1, v2, v3: simd.u32x8,
) -> (
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
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
	v1 = simd.shuffle(v1, v1, 1, 2, 3, 0, 5, 6, 7, 4)
	v2 = simd.shuffle(v2, v2, 2, 3, 0, 1, 6, 7, 4, 5)
	v3 = simd.shuffle(v3, v3, 3, 0, 1, 2, 7, 4, 5, 6)

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
	v1 = simd.shuffle(v1, v1, 3, 0, 1, 2, 7, 4, 5, 6)
	v2 = simd.shuffle(v2, v2, 2, 3, 0, 1, 6, 7, 4, 5)
	v3 = simd.shuffle(v3, v3, 1, 2, 3, 0, 5, 6, 7, 4)

	return v0, v1, v2, v3
}

@(private = "file")
_add_and_permute_state_simd256 :: #force_inline proc "contextless" (
	v0, v1, v2, v3, s0, s1, s2, s3: simd.u32x8,
) -> (
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
) {
	t0 := simd.add(v0, s0)
	t1 := simd.add(v1, s1)
	t2 := simd.add(v2, s2)
	t3 := simd.add(v3, s3)

	// Big Endian would byteswap here.

	// Each of v0 .. v3 has 128-bits of keystream for 2 separate blocks.
	// permute the state such that (r0, r1) contains block 0, and (r2, r3)
	// contains block 1.
	r0 := simd.shuffle(t0, t1, 0, 1, 2, 3, 8, 9, 10, 11)
	r2 := simd.shuffle(t0, t1, 4, 5, 6, 7, 12, 13, 14, 15)
	r1 := simd.shuffle(t2, t3, 0, 1, 2, 3, 8, 9, 10, 11)
	r3 := simd.shuffle(t2, t3, 4, 5, 6, 7, 12, 13, 14, 15)

	return r0, r1, r2, r3
}

@(private = "file")
_xor_simd256 :: #force_inline proc "contextless" (
	src: [^]simd.u32x8,
	v0, v1, v2, v3: simd.u32x8,
) -> (
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
	simd.u32x8,
) {
	v0, v1, v2, v3 := v0, v1, v2, v3

	v0 = simd.bit_xor(v0, intrinsics.unaligned_load((^simd.u32x8)(src[0:])))
	v1 = simd.bit_xor(v1, intrinsics.unaligned_load((^simd.u32x8)(src[1:])))
	v2 = simd.bit_xor(v2, intrinsics.unaligned_load((^simd.u32x8)(src[2:])))
	v3 = simd.bit_xor(v3, intrinsics.unaligned_load((^simd.u32x8)(src[3:])))

	return v0, v1, v2, v3
}

@(private = "file")
_xor_simd256_x1 :: #force_inline proc "contextless" (
	src: [^]simd.u32x8,
	v0, v1: simd.u32x8,
) -> (
	simd.u32x8,
	simd.u32x8,
) {
	v0, v1 := v0, v1

	v0 = simd.bit_xor(v0, intrinsics.unaligned_load((^simd.u32x8)(src[0:])))
	v1 = simd.bit_xor(v1, intrinsics.unaligned_load((^simd.u32x8)(src[1:])))

	return v0, v1
}

@(private = "file")
_store_simd256 :: #force_inline proc "contextless" (
	dst: [^]simd.u32x8,
	v0, v1, v2, v3: simd.u32x8,
) {
	intrinsics.unaligned_store((^simd.u32x8)(dst[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x8)(dst[1:]), v1)
	intrinsics.unaligned_store((^simd.u32x8)(dst[2:]), v2)
	intrinsics.unaligned_store((^simd.u32x8)(dst[3:]), v3)
}

@(private = "file")
_store_simd256_x1 :: #force_inline proc "contextless" (
	dst: [^]simd.u32x8,
	v0, v1: simd.u32x8,
) {
	intrinsics.unaligned_store((^simd.u32x8)(dst[0:]), v0)
	intrinsics.unaligned_store((^simd.u32x8)(dst[1:]), v1)
}

@(enable_target_feature = "sse2,ssse3,avx,avx2")
stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per IV.
	_chacha20.check_counter_limit(ctx, nr_blocks)

	dst_v := ([^]simd.u32x8)(raw_data(dst))
	src_v := ([^]simd.u32x8)(raw_data(src))

	x := &ctx._s
	n := nr_blocks

	// The state vector is an array of uint32s in native byte-order.
	// Setup s0 .. s3 such that each register stores 2 copies of the
	// state.
	x_v := ([^]simd.u32x4)(raw_data(x))
	t0 := intrinsics.unaligned_load((^simd.u32x4)(x_v[0:]))
	t1 := intrinsics.unaligned_load((^simd.u32x4)(x_v[1:]))
	t2 := intrinsics.unaligned_load((^simd.u32x4)(x_v[2:]))
	t3 := intrinsics.unaligned_load((^simd.u32x4)(x_v[3:]))
	s0 := simd.swizzle(t0, 0, 1, 2, 3, 0, 1, 2, 3)
	s1 := simd.swizzle(t1, 0, 1, 2, 3, 0, 1, 2, 3)
	s2 := simd.swizzle(t2, 0, 1, 2, 3, 0, 1, 2, 3)
	s3 := simd.swizzle(t3, 0, 1, 2, 3, 0, 1, 2, 3)

	// Advance the counter in the 2nd copy of the state by one.
	s3 = transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s3, _VEC_ZERO_ONE)

	// 8 blocks at a time.
	for ; n >= 8; n = n - 8 {
		v0, v1, v2, v3 := s0, s1, s2, s3

		s7 := transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s3, _VEC_TWO)
		v4, v5, v6, v7 := s0, s1, s2, s7

		s11 := transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s7, _VEC_TWO)
		v8, v9, v10, v11 := s0, s1, s2, s11

		s15 := transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s11, _VEC_TWO)
		v12, v13, v14, v15 := s0, s1, s2, s15

		for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
			v0, v1, v2, v3 = _dq_round_simd256(v0, v1, v2, v3)
			v4, v5, v6, v7 = _dq_round_simd256(v4, v5, v6, v7)
			v8, v9, v10, v11 = _dq_round_simd256(v8, v9, v10, v11)
			v12, v13, v14, v15 = _dq_round_simd256(v12, v13, v14, v15)
		}

		v0, v1, v2, v3 = _add_and_permute_state_simd256(v0, v1, v2, v3, s0, s1, s2, s3)
		v4, v5, v6, v7 = _add_and_permute_state_simd256(v4, v5, v6, v7, s0, s1, s2, s7)
		v8, v9, v10, v11 = _add_and_permute_state_simd256(v8, v9, v10, v11, s0, s1, s2, s11)
		v12, v13, v14, v15 = _add_and_permute_state_simd256(v12, v13, v14, v15, s0, s1, s2, s15)

		#no_bounds_check {
			if src != nil {
				v0, v1, v2, v3 = _xor_simd256(src_v, v0, v1, v2, v3)
				v4, v5, v6, v7 = _xor_simd256(src_v[4:], v4, v5, v6, v7)
				v8, v9, v10, v11 = _xor_simd256(src_v[8:], v8, v9, v10, v11)
				v12, v13, v14, v15 = _xor_simd256(src_v[12:], v12, v13, v14, v15)
				src_v = src_v[16:]
			}

			_store_simd256(dst_v, v0, v1, v2, v3)
			_store_simd256(dst_v[4:], v4, v5, v6, v7)
			_store_simd256(dst_v[8:], v8, v9, v10, v11)
			_store_simd256(dst_v[12:], v12, v13, v14, v15)
			dst_v = dst_v[16:]
		}

		s3 = transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s15, _VEC_TWO)
	}


	// 2 (or 1) block at a time.
	for ; n > 0; n = n - 2 {
		v0, v1, v2, v3 := s0, s1, s2, s3

		for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
			v0, v1, v2, v3 = _dq_round_simd256(v0, v1, v2, v3)
		}
		v0, v1, v2, v3 = _add_and_permute_state_simd256(v0, v1, v2, v3, s0, s1, s2, s3)

		if n == 1 {
			// Note: No need to advance src_v, dst_v, or increment the counter
			// since this is guaranteed to be the final block.
			#no_bounds_check {
				if src != nil {
					v0, v1 = _xor_simd256_x1(src_v, v0, v1)
				}

				_store_simd256_x1(dst_v, v0, v1)
			}
			break
		}

		#no_bounds_check {
			if src != nil {
				v0, v1, v2, v3 = _xor_simd256(src_v, v0, v1, v2, v3)
				src_v = src_v[4:]
			}

			_store_simd256(dst_v, v0, v1, v2, v3)
			dst_v = dst_v[4:]
		}

		s3 = transmute(simd.u32x8)simd.add(transmute(simd.u64x4)s3, _VEC_TWO)
	}

	// Write back the counter.  Doing it this way, saves having to
	// pull out the correct counter value from s3.
	new_ctr := ((u64(ctx._s[13]) << 32) | u64(ctx._s[12])) + u64(nr_blocks)
	ctx._s[12] = u32(new_ctr)
	ctx._s[13] = u32(new_ctr >> 32)
}

@(enable_target_feature = "sse2,ssse3,avx")
hchacha20 :: proc "contextless" (dst, key, iv: []byte) {
	// We can just enable AVX and call the simd128 code as going
	// wider has 0 performance benefit, but VEX encoded instructions
	// is nice.
	#force_inline chacha_simd128.hchacha20(dst, key, iv)
}