#+private
package _mldsa

import "base:intrinsics"
import "core:crypto"
import "core:crypto/shake"

Poly :: struct {
	coeffs: [N]i32,
}

poly_reduce :: proc "contextless" (a: ^Poly) {
	for v, i in a.coeffs {
		a.coeffs[i] = reduce32(v)
	}
}

poly_caddq :: proc "contextless" (a: ^Poly) {
	for v, i in a.coeffs {
		a.coeffs[i] = caddq(v)
	}
}

poly_add :: proc "contextless" (c, a, b: ^Poly) #no_bounds_check {
	for i in 0..<N {
		c.coeffs[i] = a.coeffs[i] + b.coeffs[i]
	}
}

poly_sub :: proc "contextless" (c, a, b: ^Poly) #no_bounds_check {
	for i in 0..<N {
		c.coeffs[i] = a.coeffs[i] - b.coeffs[i]
	}
}

poly_shiftl :: proc "contextless" (a: ^Poly) {
	for i in 0..<N {
		a.coeffs[i] <<= D
	}
}

poly_ntt :: proc "contextless" (a: ^Poly) {
	ntt(&a.coeffs)
}

poly_invntt_tomont :: proc "contextless" (a: ^Poly) {
	invntt_tomont(&a.coeffs)
}

poly_pointwise_montgomery :: proc "contextless" (c, a, b: ^Poly) #no_bounds_check {
	for i in 0..<N {
		c.coeffs[i] = montgomery_reduce(i64(a.coeffs[i]) * i64(b.coeffs[i]))
	}
}

poly_power2round :: proc "contextless" (a1, a0, a: ^Poly) #no_bounds_check {
	for i in 0..<N {
		a0.coeffs[i], a1.coeffs[i] = power2round(a.coeffs[i])
	}
}

poly_decompose :: proc "contextless" (a1, a0, a: ^Poly, params: ^Params) #no_bounds_check {
	for i in 0..<N {
		a0.coeffs[i], a1.coeffs[i] = decompose(a.coeffs[i], params.gamma2)
	}
}

poly_make_hint :: proc "contextless" (h, a0, a1: ^Poly, params: ^Params) -> uint #no_bounds_check {
	s: uint

	for i in 0..<N {
		h.coeffs[i] = i32(make_hint(a0.coeffs[i], a1.coeffs[i], params.gamma2))
		s += uint(h.coeffs[i])
	}

	return s
}

poly_use_hint :: proc "contextless" (b, a, h: ^Poly, params: ^Params) {
	for i in 0..<N {
		b.coeffs[i] = use_hint(a.coeffs[i], uint(h.coeffs[i]), params.gamma2)
	}
}

poly_chknorm :: proc "contextless" (a: ^Poly, bound: i32) -> bool #no_bounds_check {
	// It is ok to leak which coefficient violates the bound since
	// the probability for each coefficient is independent of secret
	// data but we must not leak the sign of the centralized
	// representative.
	for i in 0..<N {
		// Absolute value
		t := a.coeffs[i] >> 31
		t = a.coeffs[i] - (t & 2 * a.coeffs[i])

		if t >= bound {
			return true
		}
	}

	return false
}

unchecked_get_u24le :: #force_inline proc "contextless" (b: []byte) -> u32 #no_bounds_check {
	r := u32(b[0])
	r |= u32(b[1]) << 8
	r |= u32(b[2]) << 16
	return r
}

rej_uniform :: proc "contextless" (a: []i32, buf: []byte) -> int #no_bounds_check {
	ctr, pos: int

	a_len, b_len := len(a), len(buf)
	for ctr < a_len && pos + 3 <= b_len {
		t := unchecked_get_u24le(buf[pos:])
		t &= 0x7FFFFF
		pos += 3

		if t < Q {
			a[ctr] = i32(t)
			ctr += 1
		}
	}

	return ctr
}

poly_uniform :: proc(a: ^Poly, seed: []byte, iv: u16) #no_bounds_check {
	// Note/yawning: The dilithium reference code does something
	// inexplicably more complicated, but this is identical in
	// behavior, and simpler.
	#assert(STREAM128_BLOCKBYTES % 3 == 0)
	POLY_UNIFORM_NBLOCKS :: ((768 + STREAM128_BLOCKBYTES - 1)/STREAM128_BLOCKBYTES)

	buf: [POLY_UNIFORM_NBLOCKS*STREAM128_BLOCKBYTES]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	ctx: shake.Context = ---
	defer shake.reset(&ctx)
	stream128_init(&ctx, seed, iv)

	shake.read(&ctx, buf[:])
	ctr := rej_uniform(a.coeffs[:], buf[:])

	b := buf[:STREAM128_BLOCKBYTES]
	for ctr < N {
		shake.read(&ctx, b)
		ctr += rej_uniform(a.coeffs[ctr:], b)
	}
}

rej_eta :: proc "contextless" (a: []i32, buf: []byte, params: ^Params) -> int {
	ctr, pos: int
	a_len, b_len := len(a), len(buf)
	switch params.eta {
	case 2:
		for ctr < a_len && pos < b_len {
			t0 := u32(buf[pos] & 0x0F)
			t1 := u32(buf[pos] >> 4)
			pos += 1

			if t0 < 15 {
				t0 = t0 - (205 * t0 >> 10) * 5
				a[ctr] = i32(2 - t0)
				ctr += 1
			}
			if t1 < 15 && ctr < a_len {
				t1 = t1 - (205 * t1 >> 10) * 5
				a[ctr] = i32(2 - t1)
				ctr += 1
			}
		}
	case 4:
		for ctr < a_len && pos < b_len {
			t0 := u32(buf[pos] & 0x0F)
			t1 := u32(buf[pos] >> 4)
			pos += 1

			if t0 < 9 {
				a[ctr] = i32(4 - t0)
				ctr += 1
			}
			if t1 < 9 && ctr < a_len {
				a[ctr] = i32(4 - t1)
				ctr += 1
			}
		}
	case:
		unreachable()
	}

	return ctr
}

poly_uniform_eta :: proc(a: ^Poly, seed: []byte, iv: u16, params: ^Params) {
	POLY_UNIFORM_ETA2_NBLOCKS :: ((136 + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES)
	POLY_UNIFORM_ETA4_NBLOCKS :: ((227 + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES)

	buf_: [POLY_UNIFORM_ETA4_NBLOCKS*STREAM256_BLOCKBYTES]byte = ---
	buf: []byte
	switch params.eta {
	case 2:
		buf = buf_[:POLY_UNIFORM_ETA2_NBLOCKS*STREAM256_BLOCKBYTES]
	case 4:
		buf = buf_[:POLY_UNIFORM_ETA4_NBLOCKS*STREAM256_BLOCKBYTES]
	case:
		unreachable()
	}
	defer crypto.zero_explicit(&buf_, size_of(buf_))

	ctx: shake.Context = ---
	defer shake.reset(&ctx)
	stream256_init(&ctx, seed, iv)

	shake.read(&ctx, buf)
	ctr := rej_eta(a.coeffs[:], buf, params)

	b := buf[:STREAM256_BLOCKBYTES]
	for ctr < N {
		shake.read(&ctx, b)
		ctr += rej_eta(a.coeffs[ctr:], b, params)
	}
}

poly_uniform_gamma1 :: proc(a: ^Poly, seed: []byte, iv: u16, params: ^Params) {
	POLY_UNIFORM_GAMMA1_NBLOCKS_MAX :: ((POLYZ_PACKEDBYTES_MAX + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES)

	n_blocks := (polyz_packedbytes(params) + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES

	buf_: [POLY_UNIFORM_GAMMA1_NBLOCKS_MAX*STREAM256_BLOCKBYTES]byte = ---
	buf := buf_[:n_blocks*STREAM256_BLOCKBYTES]
	defer crypto.zero_explicit(&buf_, size_of(buf_))

	ctx: shake.Context = ---
	defer shake.reset(&ctx)
	stream256_init(&ctx, seed, iv)

	shake.read(&ctx, buf)
	polyz_unpack(a, buf, params)
}

poly_challenge :: proc(c: ^Poly, seed: []byte, params: ^Params) #no_bounds_check {
	buf: [STREAM256_BLOCKBYTES]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	ctx: shake.Context = ---
	defer shake.reset(&ctx)

	shake.init_256(&ctx)
	shake.write(&ctx, seed)
	shake.read(&ctx, buf[:])

	signs: u64
	for i in uint(0)..<8 {
		signs |= u64(buf[i]) << (8*i)
	}
	pos := 8

	b: int
	intrinsics.mem_zero(c, size_of(Poly))
	for i := N - params.tau; i < N; i+= 1 {
		for {
			if pos >= STREAM256_BLOCKBYTES {
				shake.read(&ctx, buf[:])
				pos = 0
			}

			b = int(buf[pos])
			pos += 1
			if b <= i {
				break
			}
		}

		c.coeffs[i] = c.coeffs[b]
		c.coeffs[b] = i32(1 - 2 * (signs & 1))
		signs >>= 1
	}
}

polyeta_pack :: proc "contextless" (r: []byte, a: ^Poly, params: ^Params) #no_bounds_check {
	t: [8]byte = ---
	defer crypto.zero_explicit(&t, size_of(t))

	eta := params.eta
	switch eta {
	case 2:
		for i in 0..<N/8 {
			t[0] = byte(eta - a.coeffs[8*i+0])
			t[1] = byte(eta - a.coeffs[8*i+1])
			t[2] = byte(eta - a.coeffs[8*i+2])
			t[3] = byte(eta - a.coeffs[8*i+3])
			t[4] = byte(eta - a.coeffs[8*i+4])
			t[5] = byte(eta - a.coeffs[8*i+5])
			t[6] = byte(eta - a.coeffs[8*i+6])
			t[7] = byte(eta - a.coeffs[8*i+7])

			r[3*i+0]  = (t[0] >> 0) | (t[1] << 3) | (t[2] << 6)
			r[3*i+1]  = (t[2] >> 2) | (t[3] << 1) | (t[4] << 4) | (t[5] << 7)
			r[3*i+2]  = (t[5] >> 1) | (t[6] << 2) | (t[7] << 5)
		}
	case 4:
		for i in 0..<N/2 {
			t[0] = byte(eta - a.coeffs[2*i+0])
			t[1] = byte(eta - a.coeffs[2*i+1])
			r[i] = t[0] | (t[1] << 4)
		}
	case:
		unreachable()
	}
}

polyeta_unpack :: proc "contextless" (r: ^Poly, a: []byte, params: ^Params) #no_bounds_check {
	eta := params.eta
	switch eta {
	case 2:
		for i in 0..<N/8 {
			r.coeffs[8*i+0] = i32((a[3*i+0] >> 0) & 7)
			r.coeffs[8*i+1] = i32((a[3*i+0] >> 3) & 7)
			r.coeffs[8*i+2] = i32(((a[3*i+0] >> 6) | (a[3*i+1] << 2)) & 7)
			r.coeffs[8*i+3] = i32((a[3*i+1] >> 1) & 7)
			r.coeffs[8*i+4] = i32((a[3*i+1] >> 4) & 7)
			r.coeffs[8*i+5] = i32(((a[3*i+1] >> 7) | (a[3*i+2] << 1)) & 7)
			r.coeffs[8*i+6] = i32((a[3*i+2] >> 2) & 7)
			r.coeffs[8*i+7] = i32((a[3*i+2] >> 5) & 7)

			r.coeffs[8*i+0] = eta - r.coeffs[8*i+0]
			r.coeffs[8*i+1] = eta - r.coeffs[8*i+1]
			r.coeffs[8*i+2] = eta - r.coeffs[8*i+2]
			r.coeffs[8*i+3] = eta - r.coeffs[8*i+3]
			r.coeffs[8*i+4] = eta - r.coeffs[8*i+4]
			r.coeffs[8*i+5] = eta - r.coeffs[8*i+5]
			r.coeffs[8*i+6] = eta - r.coeffs[8*i+6]
			r.coeffs[8*i+7] = eta - r.coeffs[8*i+7]
		}
	case 4:
		for i in 0..<N/2 {
			r.coeffs[2*i+0] = i32(a[i] & 0x0F)
			r.coeffs[2*i+1] = i32(a[i] >> 4)
			r.coeffs[2*i+0] = eta - r.coeffs[2*i+0]
			r.coeffs[2*i+1] = eta - r.coeffs[2*i+1]
		}
	case:
		unreachable()
	}
}

polyt1_pack :: proc "contextless" (r: []byte, a: ^Poly) #no_bounds_check {
	for i in 0..<N/4 {
		r[5*i+0] = byte(a.coeffs[4*i+0] >> 0)
		r[5*i+1] = byte((a.coeffs[4*i+0] >> 8) | (a.coeffs[4*i+1] << 2))
		r[5*i+2] = byte((a.coeffs[4*i+1] >> 6) | (a.coeffs[4*i+2] << 4))
		r[5*i+3] = byte((a.coeffs[4*i+2] >> 4) | (a.coeffs[4*i+3] << 6))
		r[5*i+4] = byte(a.coeffs[4*i+3] >> 2)
	}
}

polyt1_unpack :: proc "contextless" (r: ^Poly, a: []byte) #no_bounds_check {
	for i in 0..<N/4 {
		r.coeffs[4*i+0] = i32((u32(a[5*i+0] >> 0) | (u32(a[5*i+1]) << 8)) & 0x3FF)
		r.coeffs[4*i+1] = i32((u32(a[5*i+1] >> 2) | (u32(a[5*i+2]) << 6)) & 0x3FF)
		r.coeffs[4*i+2] = i32((u32(a[5*i+2] >> 4) | (u32(a[5*i+3]) << 4)) & 0x3FF)
		r.coeffs[4*i+3] = i32((u32(a[5*i+3] >> 6) | (u32(a[5*i+4]) << 2)) & 0x3FF)
	}
}

polyt0_pack :: proc "contextless" (r: []byte, a: ^Poly) #no_bounds_check {
	t: [8]byte = ---
	defer crypto.zero_explicit(&t, size_of(t))

	for i in 0..<N/8 {
		t[0] = byte((1 << (D-1)) - a.coeffs[8*i+0])
		t[1] = byte((1 << (D-1)) - a.coeffs[8*i+1])
		t[2] = byte((1 << (D-1)) - a.coeffs[8*i+2])
		t[3] = byte((1 << (D-1)) - a.coeffs[8*i+3])
		t[4] = byte((1 << (D-1)) - a.coeffs[8*i+4])
		t[5] = byte((1 << (D-1)) - a.coeffs[8*i+5])
		t[6] = byte((1 << (D-1)) - a.coeffs[8*i+6])
		t[7] = byte((1 << (D-1)) - a.coeffs[8*i+7])

		r[13*i+ 0] = t[0]
		r[13*i+ 1] = t[0] >>  8
		r[13*i+ 1] |= t[1] <<  5
		r[13*i+ 2] = t[1] >>  3
		r[13*i+ 3] = t[1] >> 11
		r[13*i+ 3] |= t[2] <<  2
		r[13*i+ 4] = t[2] >>  6
		r[13*i+ 4] |= t[3] <<  7
		r[13*i+ 5] = t[3] >>  1
		r[13*i+ 6] = t[3] >>  9
		r[13*i+ 6] |=  t[4] <<  4
		r[13*i+ 7] = t[4] >>  4
		r[13*i+ 8] =  t[4] >> 12
		r[13*i+ 8] |= t[5] <<  1
		r[13*i+ 9] = t[5] >>  7
		r[13*i+ 9] |= t[6] <<  6
		r[13*i+10] = t[6] >>  2
		r[13*i+11] = t[6] >> 10
		r[13*i+11] |= t[7] <<  3
		r[13*i+12] = t[7] >>  5
	}
}

polyt0_unpack :: proc "contextless" (r: ^Poly, a: []byte) #no_bounds_check {
	for i in 0..<N/8 {
		r.coeffs[8*i+0] = i32(a[13*i+0])
		r.coeffs[8*i+0] |= i32(u32(a[13*i+1]) << 8)
		r.coeffs[8*i+0] &= 0x1FFF

		r.coeffs[8*i+1] = i32(a[13*i+1] >> 5)
		r.coeffs[8*i+1] |= i32(u32(a[13*i+2]) << 3)
		r.coeffs[8*i+1] |= i32(u32(a[13*i+3]) << 11)
		r.coeffs[8*i+1] &= 0x1FFF

		r.coeffs[8*i+2] = i32(a[13*i+3] >> 2)
		r.coeffs[8*i+2] |= i32(u32(a[13*i+4]) << 6)
		r.coeffs[8*i+2] &= 0x1FFF

		r.coeffs[8*i+3] = i32(a[13*i+4] >> 7)
		r.coeffs[8*i+3] |= i32(u32(a[13*i+5]) << 1)
		r.coeffs[8*i+3] |= i32(u32(a[13*i+6]) << 9)
		r.coeffs[8*i+3] &= 0x1FFF

		r.coeffs[8*i+4] = i32(a[13*i+6] >> 4)
		r.coeffs[8*i+4] |= i32(u32(a[13*i+7]) << 4)
		r.coeffs[8*i+4] |= i32(u32(a[13*i+8]) << 12)
		r.coeffs[8*i+4] &= 0x1FFF

		r.coeffs[8*i+5] = i32(a[13*i+8] >> 1)
		r.coeffs[8*i+5] |= i32(u32(a[13*i+9]) << 7)
		r.coeffs[8*i+5] &= 0x1FFF

		r.coeffs[8*i+6] = i32(a[13*i+9] >> 6)
		r.coeffs[8*i+6] |= i32(u32(a[13*i+10]) << 2)
		r.coeffs[8*i+6] |= i32(u32(a[13*i+11]) << 10)
		r.coeffs[8*i+6] &= 0x1FFF

		r.coeffs[8*i+7] = i32(a[13*i+11] >> 3)
		r.coeffs[8*i+7] |= i32(u32(a[13*i+12]) << 5)
		r.coeffs[8*i+7] &= 0x1FFF

		r.coeffs[8*i+0] = (1 << (D-1)) - r.coeffs[8*i+0]
		r.coeffs[8*i+1] = (1 << (D-1)) - r.coeffs[8*i+1]
		r.coeffs[8*i+2] = (1 << (D-1)) - r.coeffs[8*i+2]
		r.coeffs[8*i+3] = (1 << (D-1)) - r.coeffs[8*i+3]
		r.coeffs[8*i+4] = (1 << (D-1)) - r.coeffs[8*i+4]
		r.coeffs[8*i+5] = (1 << (D-1)) - r.coeffs[8*i+5]
		r.coeffs[8*i+6] = (1 << (D-1)) - r.coeffs[8*i+6]
		r.coeffs[8*i+7] = (1 << (D-1)) - r.coeffs[8*i+7]
	}
}

polyz_pack :: proc "contextless" (r: []byte, a: ^Poly, params: ^Params) #no_bounds_check {
	t: [4]u32 = ---
	defer crypto.zero_explicit(&t, size_of(t))

	gamma1 := params.gamma1
	switch gamma1 {
	case 1 << 17:
		for i in 0..<N/4 {
			t[0] = u32(gamma1 - a.coeffs[4*i+0])
			t[1] = u32(gamma1 - a.coeffs[4*i+1])
			t[2] = u32(gamma1 - a.coeffs[4*i+2])
			t[3] = u32(gamma1 - a.coeffs[4*i+3])

			r[9*i+0] = byte(t[0])
			r[9*i+1] = byte(t[0] >> 8)
			r[9*i+2] = byte(t[0] >> 16)
			r[9*i+2] |= byte(t[1] << 2)
			r[9*i+3] = byte(t[1] >> 6)
			r[9*i+4] = byte(t[1] >> 14)
			r[9*i+4] |= byte(t[2] << 4)
			r[9*i+5] = byte(t[2] >> 4)
			r[9*i+6] = byte(t[2] >> 12)
			r[9*i+6] |= byte(t[3] << 6)
			r[9*i+7] = byte(t[3] >> 2)
			r[9*i+8] = byte(t[3] >> 10)
		}
	case 1 << 19:
		for i in 0..<N/2 {
			t[0] = u32(gamma1 - a.coeffs[2*i+0])
			t[1] = u32(gamma1 - a.coeffs[2*i+1])

			r[5*i+0] = byte(t[0])
			r[5*i+1] = byte(t[0] >> 8)
			r[5*i+2] = byte(t[0] >> 16)
			r[5*i+2] |= byte(t[1] << 4)
			r[5*i+3] = byte(t[1] >> 4)
			r[5*i+4] = byte(t[1] >> 12)
		}
	case:
		unreachable()
	}
}

polyz_unpack :: proc "contextless" (r: ^Poly, a: []byte, params: ^Params) #no_bounds_check {
	gamma1 := params.gamma1
	switch gamma1 {
	case 1 << 17:
		for i in 0..<N/4 {
			r.coeffs[4*i+0] = i32(a[9*i+0])
			r.coeffs[4*i+0] |= i32(u32(a[9*i+1]) << 8)
			r.coeffs[4*i+0] |= i32(u32(a[9*i+2]) << 16)
			r.coeffs[4*i+0] &= 0x3FFFF

			r.coeffs[4*i+1] = i32(a[9*i+2] >> 2)
			r.coeffs[4*i+1] |= i32(u32(a[9*i+3]) << 6)
			r.coeffs[4*i+1] |= i32(u32(a[9*i+4]) << 14)
			r.coeffs[4*i+1] &= 0x3FFFF

			r.coeffs[4*i+2] = i32(a[9*i+4] >> 4)
			r.coeffs[4*i+2] |= i32(u32(a[9*i+5]) << 4)
			r.coeffs[4*i+2] |= i32(u32(a[9*i+6]) << 12)
			r.coeffs[4*i+2] &= 0x3FFFF

			r.coeffs[4*i+3] = i32(a[9*i+6] >> 6)
			r.coeffs[4*i+3] |= i32(u32(a[9*i+7]) << 2)
			r.coeffs[4*i+3] |= i32(u32(a[9*i+8]) << 10)
			r.coeffs[4*i+3] &= 0x3FFFF

			r.coeffs[4*i+0] = gamma1 - r.coeffs[4*i+0]
			r.coeffs[4*i+1] = gamma1 - r.coeffs[4*i+1]
			r.coeffs[4*i+2] = gamma1 - r.coeffs[4*i+2]
			r.coeffs[4*i+3] = gamma1 - r.coeffs[4*i+3]
		}
	case 1 << 19:
		for i in 0..<N/2 {
			r.coeffs[2*i+0] = i32(a[5*i+0])
			r.coeffs[2*i+0] |= i32(u32(a[5*i+1]) << 8)
			r.coeffs[2*i+0] |= i32(u32(a[5*i+2]) << 16)
			r.coeffs[2*i+0] &= 0xFFFFF

			r.coeffs[2*i+1] = i32(a[5*i+2] >> 4)
			r.coeffs[2*i+1] |= i32(u32(a[5*i+3]) << 4)
			r.coeffs[2*i+1] |= i32(u32(a[5*i+4]) << 12)
			/* r.coeffs[2*i+1] &= 0xFFFFF */ /* No effect, since we're anyway at 20 bits */

			r.coeffs[2*i+0] = gamma1 - r.coeffs[2*i+0]
			r.coeffs[2*i+1] = gamma1 - r.coeffs[2*i+1]
		}
	case:
		unreachable()
	}
}

polyw1_pack :: proc "contextless" (r: []byte, a: ^Poly, params: ^Params) #no_bounds_check {
	switch params.gamma2 {
	case (Q-1)/88:
		for i in 0..<N/4 {
			r[3*i+0] = byte(a.coeffs[4*i+0])
			r[3*i+0] |= byte(a.coeffs[4*i+1] << 6)
			r[3*i+1] = byte(a.coeffs[4*i+1] >> 2)
			r[3*i+1] |= byte(a.coeffs[4*i+2] << 4)
			r[3*i+2] = byte(a.coeffs[4*i+2] >> 4)
			r[3*i+2] |= byte(a.coeffs[4*i+3] << 2)
		}
	case (Q-1)/32:
		for i in 0..<N/2 {
			r[i] = byte(a.coeffs[2*i+0] | (a.coeffs[2*i+1] << 4))
		}
	case:
		unreachable()
	}
}
