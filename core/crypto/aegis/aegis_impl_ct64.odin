package aegis

import aes "core:crypto/_aes/ct64"
import "core:encoding/endian"
import "core:mem"

// This uses the bitlsiced 64-bit general purpose register SWAR AES
// round function.  The intermediate state is stored in interleaved
// but NOT orthogonalized form, as leaving things in the orthgonalized
// format would overly complicate the update implementation.
//
// Note/perf: Per Frank Denis and a review of the specification, it is
// possible to gain slightly more performance by leaving the state in
// orthogonalized form while doing initialization, finalization, and
// absorbing AAD.  This implementation opts out of those optimizations
// for the sake of simplicity.
//
// The update function leverages the paralleism (4xblocks) at once.

@(private)
State_SW :: struct {
	s0_0, s0_1: u64,
	s1_0, s1_1: u64,
	s2_0, s2_1: u64,
	s3_0, s3_1: u64,
	s4_0, s4_1: u64,
	s5_0, s5_1: u64,
	s6_0, s6_1: u64,
	s7_0, s7_1: u64,
	q_k, q_b:   [8]u64,
	rate:       int,
}

@(private)
init_sw :: proc "contextless" (ctx: ^Context, st: ^State_SW, iv: []byte) {
	switch ctx._key_len {
	case KEY_SIZE_128L:
		key_0, key_1 := aes.load_interleaved(ctx._key[:16])
		iv_0, iv_1 := aes.load_interleaved(iv)

		st.s0_0, st.s0_1 = aes.xor_interleaved(key_0, key_1, iv_0, iv_1)
		st.s1_0, st.s1_1 = aes.load_interleaved(_C1[:])
		st.s2_0, st.s2_1 = aes.load_interleaved(_C0[:])
		st.s3_0, st.s3_1 = st.s1_0, st.s1_1
		st.s4_0, st.s4_1 = st.s0_0, st.s0_1
		st.s5_0, st.s5_1 = aes.xor_interleaved(key_0, key_1, st.s2_0, st.s2_1)
		st.s6_0, st.s6_1 = aes.xor_interleaved(key_0, key_1, st.s1_0, st.s1_1)
		st.s7_0, st.s7_1 = st.s5_0, st.s5_1
		st.rate = _RATE_128L

		for _ in 0 ..< 10 {
			update_sw_128l(st, iv_0, iv_1, key_0, key_1)
		}
	case KEY_SIZE_256:
		k0_0, k0_1 := aes.load_interleaved(ctx._key[:16])
		k1_0, k1_1 := aes.load_interleaved(ctx._key[16:])
		n0_0, n0_1 := aes.load_interleaved(iv[:16])
		n1_0, n1_1 := aes.load_interleaved(iv[16:])

		st.s0_0, st.s0_1 = aes.xor_interleaved(k0_0, k0_1, n0_0, n0_1)
		st.s1_0, st.s1_1 = aes.xor_interleaved(k1_0, k1_1, n1_0, n1_1)
		st.s2_0, st.s2_1 = aes.load_interleaved(_C1[:])
		st.s3_0, st.s3_1 = aes.load_interleaved(_C0[:])
		st.s4_0, st.s4_1 = aes.xor_interleaved(k0_0, k0_1, st.s3_0, st.s3_1)
		st.s5_0, st.s5_1 = aes.xor_interleaved(k1_0, k1_1, st.s2_0, st.s2_1)
		st.rate = _RATE_256

		u0_0, u0_1, u1_0, u1_1 := st.s0_0, st.s0_1, st.s1_0, st.s1_1
		for _ in 0 ..< 4 {
			update_sw_256(st, k0_0, k0_1)
			update_sw_256(st, k1_0, k1_1)
			update_sw_256(st, u0_0, u0_1)
			update_sw_256(st, u1_0, u1_1)
		}
	}
}

@(private = "file")
update_sw_128l :: proc "contextless" (st: ^State_SW, m0_0, m0_1, m1_0, m1_1: u64) {
	st.q_k[0], st.q_k[4] = aes.xor_interleaved(st.s0_0, st.s0_1, m0_0, m0_1)
	st.q_k[1], st.q_k[5] = st.s1_0, st.s1_1
	st.q_k[2], st.q_k[6] = st.s2_0, st.s2_1
	st.q_k[3], st.q_k[7] = st.s3_0, st.s3_1
	aes.orthogonalize(&st.q_k)

	st.q_b[0], st.q_b[4] = st.s7_0, st.s7_1
	st.q_b[1], st.q_b[5] = st.s0_0, st.s0_1
	st.q_b[2], st.q_b[6] = st.s1_0, st.s1_1
	st.q_b[3], st.q_b[7] = st.s2_0, st.s2_1
	aes.orthogonalize(&st.q_b)

	aes.sub_bytes(&st.q_b)
	aes.shift_rows(&st.q_b)
	aes.mix_columns(&st.q_b)
	aes.add_round_key(&st.q_b, st.q_k[:])
	aes.orthogonalize(&st.q_b)

	st.s0_0, st.s0_1 = st.q_b[0], st.q_b[4]
	st.s1_0, st.s1_1 = st.q_b[1], st.q_b[5]
	st.s2_0, st.s2_1 = st.q_b[2], st.q_b[6]
	s3_0, s3_1 := st.q_b[3], st.q_b[7]

	st.q_k[0], st.q_k[4] = aes.xor_interleaved(st.s4_0, st.s4_1, m1_0, m1_1)
	st.q_k[1], st.q_k[5] = st.s5_0, st.s5_1
	st.q_k[2], st.q_k[6] = st.s6_0, st.s6_1
	st.q_k[3], st.q_k[7] = st.s7_0, st.s7_1
	aes.orthogonalize(&st.q_k)

	st.q_b[0], st.q_b[4] = st.s3_0, st.s3_1
	st.q_b[1], st.q_b[5] = st.s4_0, st.s4_1
	st.q_b[2], st.q_b[6] = st.s5_0, st.s5_1
	st.q_b[3], st.q_b[7] = st.s6_0, st.s6_1
	aes.orthogonalize(&st.q_b)

	aes.sub_bytes(&st.q_b)
	aes.shift_rows(&st.q_b)
	aes.mix_columns(&st.q_b)
	aes.add_round_key(&st.q_b, st.q_k[:])
	aes.orthogonalize(&st.q_b)

	st.s3_0, st.s3_1 = s3_0, s3_1
	st.s4_0, st.s4_1 = st.q_b[0], st.q_b[4]
	st.s5_0, st.s5_1 = st.q_b[1], st.q_b[5]
	st.s6_0, st.s6_1 = st.q_b[2], st.q_b[6]
	st.s7_0, st.s7_1 = st.q_b[3], st.q_b[7]
}

@(private = "file")
update_sw_256 :: proc "contextless" (st: ^State_SW, m_0, m_1: u64) {
	st.q_k[0], st.q_k[4] = aes.xor_interleaved(st.s0_0, st.s0_1, m_0, m_1)
	st.q_k[1], st.q_k[5] = st.s1_0, st.s1_1
	st.q_k[2], st.q_k[6] = st.s2_0, st.s2_1
	st.q_k[3], st.q_k[7] = st.s3_0, st.s3_1
	aes.orthogonalize(&st.q_k)

	st.q_b[0], st.q_b[4] = st.s5_0, st.s5_1
	st.q_b[1], st.q_b[5] = st.s0_0, st.s0_1
	st.q_b[2], st.q_b[6] = st.s1_0, st.s1_1
	st.q_b[3], st.q_b[7] = st.s2_0, st.s2_1
	aes.orthogonalize(&st.q_b)

	aes.sub_bytes(&st.q_b)
	aes.shift_rows(&st.q_b)
	aes.mix_columns(&st.q_b)
	aes.add_round_key(&st.q_b, st.q_k[:])
	aes.orthogonalize(&st.q_b)

	st.s0_0, st.s0_1 = st.q_b[0], st.q_b[4]
	st.s1_0, st.s1_1 = st.q_b[1], st.q_b[5]
	st.s2_0, st.s2_1 = st.q_b[2], st.q_b[6]
	s3_0, s3_1 := st.q_b[3], st.q_b[7]

	st.q_k[0], st.q_k[4] = st.s4_0, st.s4_1
	st.q_k[1], st.q_k[5] = st.s5_0, st.s5_1
	aes.orthogonalize(&st.q_k)

	st.q_b[0], st.q_b[4] = st.s3_0, st.s3_1
	st.q_b[1], st.q_b[5] = st.s4_0, st.s4_1
	aes.orthogonalize(&st.q_b)

	aes.sub_bytes(&st.q_b)
	aes.shift_rows(&st.q_b)
	aes.mix_columns(&st.q_b)
	aes.add_round_key(&st.q_b, st.q_k[:])
	aes.orthogonalize(&st.q_b)

	st.s3_0, st.s3_1 = s3_0, s3_1
	st.s4_0, st.s4_1 = st.q_b[0], st.q_b[4]
	st.s5_0, st.s5_1 = st.q_b[1], st.q_b[5]
}

@(private = "file")
absorb_sw_128l :: #force_inline proc "contextless" (st: ^State_SW, ai: []byte) #no_bounds_check {
	t0_0, t0_1 := aes.load_interleaved(ai[:16])
	t1_0, t1_1 := aes.load_interleaved(ai[16:])
	update_sw_128l(st, t0_0, t0_1, t1_0, t1_1)
}

@(private = "file")
absorb_sw_256 :: #force_inline proc "contextless" (st: ^State_SW, ai: []byte) {
	m_0, m_1 := aes.load_interleaved(ai)
	update_sw_256(st, m_0, m_1)
}

@(private)
absorb_sw :: proc "contextless" (st: ^State_SW, aad: []byte) #no_bounds_check {
	ai, l := aad, len(aad)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			absorb_sw_128l(st, ai)
			ai = ai[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			absorb_sw_256(st, ai)

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
			absorb_sw_128l(st, tmp[:])
		case _RATE_256:
			absorb_sw_256(st, tmp[:])
		}
	}
}

@(private = "file", require_results)
z_sw_128l :: proc "contextless" (st: ^State_SW) -> (u64, u64, u64, u64) {
	z0_0, z0_1 := aes.and_interleaved(st.s2_0, st.s2_1, st.s3_0, st.s3_1)
	z0_0, z0_1 = aes.xor_interleaved(st.s1_0, st.s1_1, z0_0, z0_1)
	z0_0, z0_1 = aes.xor_interleaved(st.s6_0, st.s6_1, z0_0, z0_1)

	z1_0, z1_1 := aes.and_interleaved(st.s6_0, st.s6_1, st.s7_0, st.s7_1)
	z1_0, z1_1 = aes.xor_interleaved(st.s5_0, st.s5_1, z1_0, z1_1)
	z1_0, z1_1 = aes.xor_interleaved(st.s2_0, st.s2_1, z1_0, z1_1)

	return z0_0, z0_1, z1_0, z1_1
}

@(private = "file", require_results)
z_sw_256 :: proc "contextless" (st: ^State_SW) -> (u64, u64) {
	z_0, z_1 := aes.and_interleaved(st.s2_0, st.s2_1, st.s3_0, st.s3_1)
	z_0, z_1 = aes.xor_interleaved(st.s5_0, st.s5_1, z_0, z_1)
	z_0, z_1 = aes.xor_interleaved(st.s4_0, st.s4_1, z_0, z_1)
	return aes.xor_interleaved(st.s1_0, st.s1_1, z_0, z_1)
}

@(private = "file")
enc_sw_128l :: #force_inline proc "contextless" (st: ^State_SW, ci, xi: []byte) #no_bounds_check {
	z0_0, z0_1, z1_0, z1_1 := z_sw_128l(st)

	t0_0, t0_1 := aes.load_interleaved(xi[:16])
	t1_0, t1_1 := aes.load_interleaved(xi[16:])
	update_sw_128l(st, t0_0, t0_1, t1_0, t1_1)

	out0_0, out0_1 := aes.xor_interleaved(t0_0, t0_1, z0_0, z0_1)
	out1_0, out1_1 := aes.xor_interleaved(t1_0, t1_1, z1_0, z1_1)
	aes.store_interleaved(ci[:16], out0_0, out0_1)
	aes.store_interleaved(ci[16:], out1_0, out1_1)
}

@(private = "file")
enc_sw_256 :: #force_inline proc "contextless" (st: ^State_SW, ci, xi: []byte) #no_bounds_check {
	z_0, z_1 := z_sw_256(st)

	xi_0, xi_1 := aes.load_interleaved(xi)
	update_sw_256(st, xi_0, xi_1)

	ci_0, ci_1 := aes.xor_interleaved(xi_0, xi_1, z_0, z_1)
	aes.store_interleaved(ci, ci_0, ci_1)
}

@(private)
enc_sw :: proc "contextless" (st: ^State_SW, dst, src: []byte) #no_bounds_check {
	ci, xi, l := dst, src, len(src)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			enc_sw_128l(st, ci, xi)
			ci = ci[_RATE_128L:]
			xi = xi[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			enc_sw_256(st, ci, xi)
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
			enc_sw_128l(st, tmp[:], tmp[:])
		case _RATE_256:
			enc_sw_256(st, tmp[:], tmp[:])
		}
		copy(ci, tmp[:l])
	}
}

@(private = "file")
dec_sw_128l :: #force_inline proc "contextless" (st: ^State_SW, xi, ci: []byte) #no_bounds_check {
	z0_0, z0_1, z1_0, z1_1 := z_sw_128l(st)

	t0_0, t0_1 := aes.load_interleaved(ci[:16])
	t1_0, t1_1 := aes.load_interleaved(ci[16:])
	out0_0, out0_1 := aes.xor_interleaved(t0_0, t0_1, z0_0, z0_1)
	out1_0, out1_1 := aes.xor_interleaved(t1_0, t1_1, z1_0, z1_1)

	update_sw_128l(st, out0_0, out0_1, out1_0, out1_1)
	aes.store_interleaved(xi[:16], out0_0, out0_1)
	aes.store_interleaved(xi[16:], out1_0, out1_1)
}

@(private = "file")
dec_sw_256 :: #force_inline proc "contextless" (st: ^State_SW, xi, ci: []byte) #no_bounds_check {
	z_0, z_1 := z_sw_256(st)

	ci_0, ci_1 := aes.load_interleaved(ci)
	xi_0, xi_1 := aes.xor_interleaved(ci_0, ci_1, z_0, z_1)

	update_sw_256(st, xi_0, xi_1)
	aes.store_interleaved(xi, xi_0, xi_1)
}

@(private = "file")
dec_partial_sw_128l :: proc "contextless" (st: ^State_SW, xn, cn: []byte) #no_bounds_check {
	tmp: [_RATE_128L]byte
	defer mem.zero_explicit(&tmp, size_of(tmp))

	z0_0, z0_1, z1_0, z1_1 := z_sw_128l(st)
	copy(tmp[:], cn)

	t0_0, t0_1 := aes.load_interleaved(tmp[:16])
	t1_0, t1_1 := aes.load_interleaved(tmp[16:])
	out0_0, out0_1 := aes.xor_interleaved(t0_0, t0_1, z0_0, z0_1)
	out1_0, out1_1 := aes.xor_interleaved(t1_0, t1_1, z1_0, z1_1)

	aes.store_interleaved(tmp[:16], out0_0, out0_1)
	aes.store_interleaved(tmp[16:], out1_0, out1_1)
	copy(xn, tmp[:])

	for off := len(xn); off < _RATE_128L; off += 1 {
		tmp[off] = 0
	}
	out0_0, out0_1 = aes.load_interleaved(tmp[:16])
	out1_0, out1_1 = aes.load_interleaved(tmp[16:])
	update_sw_128l(st, out0_0, out0_1, out1_0, out1_1)
}

@(private = "file")
dec_partial_sw_256 :: proc "contextless" (st: ^State_SW, xn, cn: []byte) #no_bounds_check {
	tmp: [_RATE_256]byte
	defer mem.zero_explicit(&tmp, size_of(tmp))

	z_0, z_1 := z_sw_256(st)
	copy(tmp[:], cn)

	cn_0, cn_1 := aes.load_interleaved(tmp[:])
	xn_0, xn_1 := aes.xor_interleaved(cn_0, cn_1, z_0, z_1)

	aes.store_interleaved(tmp[:], xn_0, xn_1)
	copy(xn, tmp[:])

	for off := len(xn); off < _RATE_256; off += 1 {
		tmp[off] = 0
	}
	xn_0, xn_1 = aes.load_interleaved(tmp[:])
	update_sw_256(st, xn_0, xn_1)
}

@(private)
dec_sw :: proc "contextless" (st: ^State_SW, dst, src: []byte) #no_bounds_check {
	xi, ci, l := dst, src, len(src)

	switch st.rate {
	case _RATE_128L:
		for l >= _RATE_128L {
			dec_sw_128l(st, xi, ci)
			xi = xi[_RATE_128L:]
			ci = ci[_RATE_128L:]
			l -= _RATE_128L
		}
	case _RATE_256:
		for l >= _RATE_256 {
			dec_sw_256(st, xi, ci)
			xi = xi[_RATE_256:]
			ci = ci[_RATE_256:]
			l -= _RATE_256
		}
	}

	// Process the remainder.
	if l > 0 {
		switch st.rate {
		case _RATE_128L:
			dec_partial_sw_128l(st, xi, ci)
		case _RATE_256:
			dec_partial_sw_256(st, xi, ci)
		}
	}
}

@(private)
finalize_sw :: proc "contextless" (st: ^State_SW, tag: []byte, ad_len, msg_len: int) {
	tmp: [16]byte
	endian.unchecked_put_u64le(tmp[0:], u64(ad_len) * 8)
	endian.unchecked_put_u64le(tmp[8:], u64(msg_len) * 8)

	t_0, t_1 := aes.load_interleaved(tmp[:])

	t0_0, t0_1, t1_0, t1_1: u64 = ---, ---, ---, ---
	switch st.rate {
	case _RATE_128L:
		t_0, t_1 = aes.xor_interleaved(st.s2_0, st.s2_1, t_0, t_1)
		for _ in 0 ..< 7 {
			update_sw_128l(st, t_0, t_1, t_0, t_1)
		}

		t0_0, t0_1 = aes.xor_interleaved(st.s0_0, st.s0_1, st.s1_0, st.s1_1)
		t0_0, t0_1 = aes.xor_interleaved(t0_0, t0_1, st.s2_0, st.s2_1)
		t0_0, t0_1 = aes.xor_interleaved(t0_0, t0_1, st.s3_0, st.s3_1)

		t1_0, t1_1 = aes.xor_interleaved(st.s4_0, st.s4_1, st.s5_0, st.s5_1)
		t1_0, t1_1 = aes.xor_interleaved(t1_0, t1_1, st.s6_0, st.s6_1)
		if len(tag) == TAG_SIZE_256 {
			t1_0, t1_1 = aes.xor_interleaved(t1_0, t1_1, st.s7_0, st.s7_1)
		}
	case _RATE_256:
		t_0, t_1 = aes.xor_interleaved(st.s3_0, st.s3_1, t_0, t_1)
		for _ in 0 ..< 7 {
			update_sw_256(st, t_0, t_1)
		}

		t0_0, t0_1 = aes.xor_interleaved(st.s0_0, st.s0_1, st.s1_0, st.s1_1)
		t0_0, t0_1 = aes.xor_interleaved(t0_0, t0_1, st.s2_0, st.s2_1)

		t1_0, t1_1 = aes.xor_interleaved(st.s3_0, st.s3_1, st.s4_0, st.s4_1)
		t1_0, t1_1 = aes.xor_interleaved(t1_0, t1_1, st.s5_0, st.s5_1)
	}
	switch len(tag) {
	case TAG_SIZE_128:
		t0_0, t0_1 = aes.xor_interleaved(t0_0, t0_1, t1_0, t1_1)
		aes.store_interleaved(tag, t0_0, t0_1)
	case TAG_SIZE_256:
		aes.store_interleaved(tag[:16], t0_0, t0_1)
		aes.store_interleaved(tag[16:], t1_0, t1_1)
	}
}

@(private)
reset_state_sw :: proc "contextless" (st: ^State_SW) {
	mem.zero_explicit(st, size_of(st^))
}
