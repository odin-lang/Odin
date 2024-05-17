//+build amd64, arm32, arm64
package chacha20

import "base:intrinsics"
import "core:simd"

// Portable 128-bit `core/simd` implementation.
//
// This is loosely based on Ted Krovetz's public domain C intrinsic
// implementation.
//
// This is written to perform adequately on any target that has "enough"
// 128-bit vector registers, and to try to avoid spilling.  Most targets
// are capable of taking performance further (3 or 4 blocks per iter),
// however this quickly becomes a battle against register pressure, and
// such targets would also be (in most cases) better served by a 256-bit
// implementation.
//
// Notes:
// - Using a byte shuffle (ie: PSHUFB) for the 8 and 16 rotates
//   benchmarks worse than using two shifts and an xor, but this may
//   be due to AMD CPU weirdness, since the generated assembly looks
//   fine.
//
// See:
// supercop-20230530/crypto_stream/chacha20/krovetz/vec128

@(private)
_ROT_7L: simd.u32x4 : {7, 7, 7, 7}
@(private)
_ROT_7R: simd.u32x4 : {25, 25, 25, 25}
@(private)
_ROT_12L: simd.u32x4 : {12, 12, 12, 12}
@(private)
_ROT_12R: simd.u32x4 : {20, 20, 20, 20}
@(private)
_ROT_8L: simd.u32x4 : {8, 8, 8, 8}
@(private)
_ROT_8R: simd.u32x4 : {24, 24, 24, 24}
@(private)
_ROT_16: simd.u32x4 : {16, 16, 16, 16}

when ODIN_ENDIAN == .Big {
	@(private)
	_increment_counter :: #force_inline proc "contextless" (ctx: ^Context) -> simd.u32x4 {
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
	@(private)
	_byteswap_u32x4 :: #force_inline proc "contextless" (v: simd.u32x4) -> simd.u32x4 {
		return transmute(simd.u32x4)simd.shuffle(
			transmute(simd.u8x16)v,
			transmute(simd.u8x16)v,
			3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12,
		)
	}
} else {
	@(private)
	_VEC_ONE: simd.u64x2 : {1, 0}
}

@(private)
_dq_round_simd128 :: #force_inline proc "contextless" (v0, v1, v2, v3: simd.u32x4) -> (simd.u32x4, simd.u32x4, simd.u32x4, simd.u32x4) {
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

@(private)
_add_state_simd128 :: #force_inline proc "contextless" (v0, v1, v2, v3, s0, s1, s2, s3: simd.u32x4) -> (simd.u32x4, simd.u32x4, simd.u32x4, simd.u32x4) {
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

@(private)
_do_blocks :: proc(ctx: ^Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per nonce.
	_check_counter_limit(ctx, nr_blocks)

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

	// 2 blocks at a time.
	for ; n > 1; n = n - 2 {
		v0, v1, v2, v3 := s0, s1, s2, s3

		when ODIN_ENDIAN == .Little {
			s7 := transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s3, _VEC_ONE)
		} else {
			s7 := _increment_counter(ctx)
		}

		v4, v5, v6, v7 := s0, s1, s2, s7

		for i := _ROUNDS; i > 0; i = i - 2 {
			v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
			v4, v5, v6, v7 = _dq_round_simd128(v4, v5, v6, v7)
		}

		v0, v1, v2, v3 = _add_state_simd128(v0, v1, v2, v3, s0, s1, s2, s3)
		v4, v5, v6, v7 = _add_state_simd128(v4, v5, v6, v7, s0, s1, s2, s7)

		#no_bounds_check {
			if src != nil {
				v0 = simd.bit_xor(v0, intrinsics.unaligned_load((^simd.u32x4)(src_v[0:])))
				v1 = simd.bit_xor(v1, intrinsics.unaligned_load((^simd.u32x4)(src_v[1:])))
				v2 = simd.bit_xor(v2, intrinsics.unaligned_load((^simd.u32x4)(src_v[2:])))
				v3 = simd.bit_xor(v3, intrinsics.unaligned_load((^simd.u32x4)(src_v[3:])))
				v4 = simd.bit_xor(v4, intrinsics.unaligned_load((^simd.u32x4)(src_v[4:])))
				v5 = simd.bit_xor(v5, intrinsics.unaligned_load((^simd.u32x4)(src_v[5:])))
				v6 = simd.bit_xor(v6, intrinsics.unaligned_load((^simd.u32x4)(src_v[6:])))
				v7 = simd.bit_xor(v7, intrinsics.unaligned_load((^simd.u32x4)(src_v[7:])))
				src_v = src_v[_BLOCK_SIZE * 2 / 16:]
			}

			intrinsics.unaligned_store((^simd.u32x4)(dst_v[0:]), v0)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[1:]), v1)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[2:]), v2)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[3:]), v3)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[4:]), v4)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[5:]), v5)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[6:]), v6)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[7:]), v7)
			dst_v = dst_v[_BLOCK_SIZE * 2 / 16:]
		}

		when ODIN_ENDIAN == .Little {
			// s7 holds the most current counter, so `s3 = s7 + 1`.
			s3 = transmute(simd.u32x4)simd.add(transmute(simd.u64x2)s7, _VEC_ONE)
		} else {
			s3 = _increment_counter(ctx)
		}
	}

	// 1 block at a time.
	for ; n > 0; n = n - 1 {
		v0, v1, v2, v3 := s0, s1, s2, s3

		for i := _ROUNDS; i > 0; i = i - 2 {
			v0, v1, v2, v3 = _dq_round_simd128(v0, v1, v2, v3)
		}

		v0, v1, v2, v3 = _add_state_simd128(v0, v1, v2, v3, s0, s1, s2, s3)

		#no_bounds_check {
			if src != nil {
				v0 = simd.bit_xor(v0, intrinsics.unaligned_load((^simd.u32x4)(src_v[0:])))
				v1 = simd.bit_xor(v1, intrinsics.unaligned_load((^simd.u32x4)(src_v[1:])))
				v2 = simd.bit_xor(v2, intrinsics.unaligned_load((^simd.u32x4)(src_v[2:])))
				v3 = simd.bit_xor(v3, intrinsics.unaligned_load((^simd.u32x4)(src_v[3:])))
				src_v = src_v[_BLOCK_SIZE / 16:]
			}

			intrinsics.unaligned_store((^simd.u32x4)(dst_v[0:]), v0)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[1:]), v1)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[2:]), v2)
			intrinsics.unaligned_store((^simd.u32x4)(dst_v[3:]), v3)
			dst_v = dst_v[_BLOCK_SIZE / 16:]
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

@(private)
_hchacha20 :: proc "contextless" (dst, key, nonce: []byte) {
	v0 := simd.u32x4{_SIGMA_0, _SIGMA_1, _SIGMA_2, _SIGMA_3}
	v1 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[0])
	v2 := intrinsics.unaligned_load(transmute(^simd.u32x4)&key[16])
	v3 := intrinsics.unaligned_load(transmute(^simd.u32x4)&nonce[0])

	when ODIN_ENDIAN == .Big {
		v1 = _byteswap_u32x4(v1)
		v2 = _byteswap_u32x4(v2)
		v3 = _byteswap_u32x4(v3)
	}

	for i := _ROUNDS; i > 0; i = i - 2 {
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
