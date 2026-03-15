#+build amd64,arm64,arm32
package aegis

import "base:intrinsics"
import "core:crypto"
import aes_hw "core:crypto/_aes/hw"
import "core:encoding/endian"
import "core:simd"

@(private)
State_HW :: struct {
	s0:   simd.u8x16,
	s1:   simd.u8x16,
	s2:   simd.u8x16,
	s3:   simd.u8x16,
	s4:   simd.u8x16,
	s5:   simd.u8x16,
	s6:   simd.u8x16,
	s7:   simd.u8x16,
	rate: int,
}

when ODIN_ARCH == .amd64 {
	@(private="file")
	TARGET_FEATURES :: "sse2,aes"
} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
	@(private="file")
	TARGET_FEATURES :: "neon,aes"
}

// is_hardware_accelerated returns true if and only if (⟺) hardware
// accelerated AEGIS is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return aes_hw.is_supported()
}

@(private, enable_target_feature = TARGET_FEATURES)
init_hw :: proc "contextless" (ctx: ^Context, st: ^State_HW, iv: []byte) {
	switch ctx._key_len {
	case KEY_SIZE_128L:
		key := intrinsics.unaligned_load((^simd.u8x16)(&ctx._key[0]))
		iv := intrinsics.unaligned_load((^simd.u8x16)(raw_data(iv)))

		st.s0 = simd.bit_xor(key, iv)
		st.s1 = intrinsics.unaligned_load((^simd.u8x16)(&_C1[0]))
		st.s2 = intrinsics.unaligned_load((^simd.u8x16)(&_C0[0]))
		st.s3 = st.s1
		st.s4 = st.s0
		st.s5 = simd.bit_xor(key, st.s2) // key ^ C0
		st.s6 = simd.bit_xor(key, st.s1) // key ^ C1
		st.s7 = st.s5
		st.rate = _RATE_128L

		for _ in 0 ..< 10 {
			update_hw_128l(st, iv, key)
		}
	case KEY_SIZE_256:
		k0 := intrinsics.unaligned_load((^simd.u8x16)(&ctx._key[0]))
		k1 := intrinsics.unaligned_load((^simd.u8x16)(&ctx._key[16]))
		n0 := intrinsics.unaligned_load((^simd.u8x16)(&iv[0]))
		n1 := intrinsics.unaligned_load((^simd.u8x16)(&iv[16]))

		st.s0 = simd.bit_xor(k0, n0)
		st.s1 = simd.bit_xor(k1, n1)
		st.s2 = intrinsics.unaligned_load((^simd.u8x16)(&_C1[0]))
		st.s3 = intrinsics.unaligned_load((^simd.u8x16)(&_C0[0]))
		st.s4 = simd.bit_xor(k0, st.s3) // k0 ^ C0
		st.s5 = simd.bit_xor(k1, st.s2) // k1 ^ C1
		st.rate = _RATE_256

		u0, u1 := st.s0, st.s1
		for _ in 0 ..< 4 {
			update_hw_256(st, k0)
			update_hw_256(st, k1)
			update_hw_256(st, u0)
			update_hw_256(st, u1)
		}
	}
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
update_hw_128l :: #force_inline proc "contextless" (st: ^State_HW, m0, m1: simd.u8x16) {
	s0_ := aes_hw.aesenc(st.s7, simd.bit_xor(st.s0, m0))
	s1_ := aes_hw.aesenc(st.s0, st.s1)
	s2_ := aes_hw.aesenc(st.s1, st.s2)
	s3_ := aes_hw.aesenc(st.s2, st.s3)
	s4_ := aes_hw.aesenc(st.s3, simd.bit_xor(st.s4, m1))
	s5_ := aes_hw.aesenc(st.s4, st.s5)
	s6_ := aes_hw.aesenc(st.s5, st.s6)
	s7_ := aes_hw.aesenc(st.s6, st.s7)
	st.s0, st.s1, st.s2, st.s3, st.s4, st.s5, st.s6, st.s7 = s0_, s1_, s2_, s3_, s4_, s5_, s6_, s7_
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
update_hw_256 :: #force_inline proc "contextless" (st: ^State_HW, m: simd.u8x16) {
	s0_ := aes_hw.aesenc(st.s5, simd.bit_xor(st.s0, m))
	s1_ := aes_hw.aesenc(st.s0, st.s1)
	s2_ := aes_hw.aesenc(st.s1, st.s2)
	s3_ := aes_hw.aesenc(st.s2, st.s3)
	s4_ := aes_hw.aesenc(st.s3, st.s4)
	s5_ := aes_hw.aesenc(st.s4, st.s5)
	st.s0, st.s1, st.s2, st.s3, st.s4, st.s5 = s0_, s1_, s2_, s3_, s4_, s5_
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
absorb_hw_128l :: #force_inline proc "contextless" (st: ^State_HW, ai: []byte) {
	t0 := intrinsics.unaligned_load((^simd.u8x16)(&ai[0]))
	t1 := intrinsics.unaligned_load((^simd.u8x16)(&ai[16]))
	update_hw_128l(st, t0, t1)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
absorb_hw_256 :: #force_inline proc "contextless" (st: ^State_HW, ai: []byte) {
	m := intrinsics.unaligned_load((^simd.u8x16)(&ai[0]))
	update_hw_256(st, m)
}

@(private, enable_target_feature = TARGET_FEATURES)
absorb_hw :: proc "contextless" (st: ^State_HW, aad: []byte) #no_bounds_check {
	ai, l := aad, len(aad)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			absorb_hw_128l(st, ai)
			ai = ai[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			absorb_hw_256(st, ai)

			ai = ai[_RATE_256:]
			l -= _RATE_256
		}
	}

	// Pad out the remainder with `0`s till it is rate sized.
	if l > 0 {
		tmp: [_RATE_MAX]byte // AAD is not confidential.
		copy(tmp[:], ai)
		switch st.rate {
		case _RATE_128L:
			absorb_hw_128l(st, tmp[:])
		case _RATE_256:
			absorb_hw_256(st, tmp[:])
		}
	}
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
z_hw_128l :: #force_inline proc "contextless" (st: ^State_HW) -> (simd.u8x16, simd.u8x16) {
	z0 := simd.bit_xor(
		st.s6,
		simd.bit_xor(
			st.s1,
			simd.bit_and(st.s2, st.s3),
		),
	)
	z1 := simd.bit_xor(
		st.s2,
		simd.bit_xor(
			st.s5,
			simd.bit_and(st.s6, st.s7),
		),
	)
	return z0, z1
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
z_hw_256 :: #force_inline proc "contextless" (st: ^State_HW) -> simd.u8x16 {
	return simd.bit_xor(
		st.s1,
		simd.bit_xor(
			st.s4,
			simd.bit_xor(
				st.s5,
				simd.bit_and(st.s2, st.s3),
			),
		),
	)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
enc_hw_128l :: #force_inline proc "contextless" (st: ^State_HW, ci, xi: []byte) #no_bounds_check {
	z0, z1 := z_hw_128l(st)

	t0 := intrinsics.unaligned_load((^simd.u8x16)(&xi[0]))
	t1 := intrinsics.unaligned_load((^simd.u8x16)(&xi[16]))
	update_hw_128l(st, t0, t1)

	out0 := simd.bit_xor(t0, z0)
	out1 := simd.bit_xor(t1, z1)
	intrinsics.unaligned_store((^simd.u8x16)(&ci[0]), out0)
	intrinsics.unaligned_store((^simd.u8x16)(&ci[16]), out1)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
enc_hw_256 :: #force_inline proc "contextless" (st: ^State_HW, ci, xi: []byte) #no_bounds_check {
	z := z_hw_256(st)

	xi_ := intrinsics.unaligned_load((^simd.u8x16)(raw_data(xi)))
	update_hw_256(st, xi_)

	ci_ := simd.bit_xor(xi_, z)
	intrinsics.unaligned_store((^simd.u8x16)(raw_data(ci)), ci_)
}

@(private, enable_target_feature = TARGET_FEATURES)
enc_hw :: proc "contextless" (st: ^State_HW, dst, src: []byte) #no_bounds_check {
	ci, xi, l := dst, src, len(src)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			enc_hw_128l(st, ci, xi)
			ci = ci[_RATE_128L:]
			xi = xi[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			enc_hw_256(st, ci, xi)
			ci = ci[_RATE_256:]
			xi = xi[_RATE_256:]
			l -= _RATE_256
		}
	}

	// Pad out the remainder with `0`s till it is rate sized.
	if l > 0 {
		tmp: [_RATE_MAX]byte // Ciphertext is not confidential.
		copy(tmp[:], xi)
		switch st.rate {
		case _RATE_128L:
			enc_hw_128l(st, tmp[:], tmp[:])
		case _RATE_256:
			enc_hw_256(st, tmp[:], tmp[:])
		}
		copy(ci, tmp[:l])
	}
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
dec_hw_128l :: #force_inline proc "contextless" (st: ^State_HW, xi, ci: []byte) #no_bounds_check {
	z0, z1 := z_hw_128l(st)

	t0 := intrinsics.unaligned_load((^simd.u8x16)(&ci[0]))
	t1 := intrinsics.unaligned_load((^simd.u8x16)(&ci[16]))
	out0 := simd.bit_xor(t0, z0)
	out1 := simd.bit_xor(t1, z1)

	update_hw_128l(st, out0, out1)
	intrinsics.unaligned_store((^simd.u8x16)(&xi[0]), out0)
	intrinsics.unaligned_store((^simd.u8x16)(&xi[16]), out1)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
dec_hw_256 :: #force_inline proc "contextless" (st: ^State_HW, xi, ci: []byte) #no_bounds_check {
	z := z_hw_256(st)

	ci_ := intrinsics.unaligned_load((^simd.u8x16)(raw_data(ci)))
	xi_ := simd.bit_xor(ci_, z)

	update_hw_256(st, xi_)
	intrinsics.unaligned_store((^simd.u8x16)(raw_data(xi)), xi_)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
dec_partial_hw_128l :: #force_inline proc "contextless" (st: ^State_HW, xn, cn: []byte) #no_bounds_check {
	tmp: [_RATE_128L]byte
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	z0, z1 := z_hw_128l(st)
	copy(tmp[:], cn)

	t0 := intrinsics.unaligned_load((^simd.u8x16)(&tmp[0]))
	t1 := intrinsics.unaligned_load((^simd.u8x16)(&tmp[16]))
	out0 := simd.bit_xor(t0, z0)
	out1 := simd.bit_xor(t1, z1)

	intrinsics.unaligned_store((^simd.u8x16)(&tmp[0]), out0)
	intrinsics.unaligned_store((^simd.u8x16)(&tmp[16]), out1)
	copy(xn, tmp[:])

	for off := len(xn); off < _RATE_128L; off += 1 {
		tmp[off] = 0
	}
	out0 = intrinsics.unaligned_load((^simd.u8x16)(&tmp[0])) // v0
	out1 = intrinsics.unaligned_load((^simd.u8x16)(&tmp[16])) // v1
	update_hw_128l(st, out0, out1)
}

@(private = "file", enable_target_feature = TARGET_FEATURES)
dec_partial_hw_256 :: #force_inline proc "contextless" (st: ^State_HW, xn, cn: []byte) #no_bounds_check {
	tmp: [_RATE_256]byte
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	z := z_hw_256(st)
	copy(tmp[:], cn)

	cn_ := intrinsics.unaligned_load((^simd.u8x16)(&tmp[0]))
	xn_ := simd.bit_xor(cn_, z)

	intrinsics.unaligned_store((^simd.u8x16)(&tmp[0]), xn_)
	copy(xn, tmp[:])

	for off := len(xn); off < _RATE_256; off += 1 {
		tmp[off] = 0
	}
	xn_ = intrinsics.unaligned_load((^simd.u8x16)(&tmp[0]))
	update_hw_256(st, xn_)
}

@(private, enable_target_feature = TARGET_FEATURES)
dec_hw :: proc "contextless" (st: ^State_HW, dst, src: []byte) #no_bounds_check {
	xi, ci, l := dst, src, len(src)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			dec_hw_128l(st, xi, ci)
			xi = xi[_RATE_128L:]
			ci = ci[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			dec_hw_256(st, xi, ci)
			xi = xi[_RATE_256:]
			ci = ci[_RATE_256:]
			l -= _RATE_256
		}
	}

	// Process the remainder.
	if l > 0 {
		switch st.rate {
		case _RATE_128L:
			dec_partial_hw_128l(st, xi, ci)
		case _RATE_256:
			dec_partial_hw_256(st, xi, ci)
		}
	}
}

@(private, enable_target_feature = TARGET_FEATURES)
finalize_hw :: proc "contextless" (st: ^State_HW, tag: []byte, ad_len, msg_len: int) {
	tmp: [16]byte
	endian.unchecked_put_u64le(tmp[0:], u64(ad_len) * 8)
	endian.unchecked_put_u64le(tmp[8:], u64(msg_len) * 8)

	t := intrinsics.unaligned_load((^simd.u8x16)(&tmp[0]))

	t0, t1: simd.u8x16 = ---, ---
	switch st.rate {
	case _RATE_128L:
		t = simd.bit_xor(st.s2, t)
		for _ in 0 ..< 7 {
			update_hw_128l(st, t, t)
		}

		t0 = simd.bit_xor(st.s0, st.s1)
		t0 = simd.bit_xor(t0, st.s2)
		t0 = simd.bit_xor(t0, st.s3)

		t1 = simd.bit_xor(st.s4, st.s5)
		t1 = simd.bit_xor(t1, st.s6)
		if len(tag) == TAG_SIZE_256 {
			t1 = simd.bit_xor(t1, st.s7)
		}
	case _RATE_256:
		t = simd.bit_xor(st.s3, t)
		for _ in 0 ..< 7 {
			update_hw_256(st, t)
		}

		t0 = simd.bit_xor(st.s0, st.s1)
		t0 = simd.bit_xor(t0, st.s2)

		t1 = simd.bit_xor(st.s3, st.s4)
		t1 = simd.bit_xor(t1, st.s5)
	}
	switch len(tag) {
	case TAG_SIZE_128:
		t0 = simd.bit_xor(t0, t1)
		intrinsics.unaligned_store((^simd.u8x16)(&tag[0]), t0)
	case TAG_SIZE_256:
		intrinsics.unaligned_store((^simd.u8x16)(&tag[0]), t0)
		intrinsics.unaligned_store((^simd.u8x16)(&tag[16]), t1)
	}
}

@(private)
reset_state_hw :: proc "contextless" (st: ^State_HW) {
	crypto.zero_explicit(st, size_of(st^))
}
