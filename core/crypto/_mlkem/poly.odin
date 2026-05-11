#+private
package _mlkem

import "core:crypto"
import subtle "core:crypto/_subtle"

// Elements of R_q = Z_q[X]/(X^n + 1). Represents polynomial
// coeffs[0] + X*coeffs[1] + X^2*coeffs[2] + ... + X^{n-1}*coeffs[n-1]
Poly :: struct {
	coeffs: [N]i16,
}

poly_compress :: proc "contextless" (r: []byte, a: ^Poly) #no_bounds_check {
	t: [8]byte = ---
	defer crypto.zero_explicit(&t, size_of(t))

	r := r
	switch len(r) {
	case POLYCOMPRESSEDBYTES_768: // Also covers _512
		for i in 0..<N/8 {
			for j in 0..<8 {
				// map to positive standard representatives
				u := a.coeffs[8*i+j]
				u += (u >> 15) & Q
				// t[j] = ((((uint16_t)u << 4) + Q/2)/Q) & 15
				d0 := u32(u) << 4
				d0 += 1665
				d0 *= 80635
				d0 >>= 28
				t[j] = byte(d0) & 0xf
			}

			r[0] = t[0] | (t[1] << 4)
			r[1] = t[2] | (t[3] << 4)
			r[2] = t[4] | (t[5] << 4)
			r[3] = t[6] | (t[7] << 4)
			r = r[4:]
		}
	case POLYCOMPRESSEDBYTES_1024:
		for i in 0..<N/8 {
			for j in 0..<8 {
				// map to positive standard representatives
				u := a.coeffs[8*i+j]
				u += (u >> 15) & Q
				// t[j] = ((((uint16_t)u << 5) + Q/2)/Q) & 31
				d0 := u32(u) << 5
				d0 += 1664
				d0 *= 40318
				d0 >>= 27
				t[j] = byte(d0) & 0x1f
			}

			r[0] = (t[0] >> 0) | (t[1] << 5)
			r[1] = (t[1] >> 3) | (t[2] << 2) | (t[3] << 7)
			r[2] = (t[3] >> 1) | (t[4] << 4)
			r[3] = (t[4] >> 4) | (t[5] << 1) | (t[6] << 6)
			r[4] = (t[6] >> 2) | (t[7] << 3)
			r = r[5:]
		}
	case:
		panic_contextless("crypto/mlkem: invalid POLYCOMPRESSEDBYTES")
	}
}

poly_decompress :: proc "contextless" (r: ^Poly, a: []byte) {
	a := a
	switch len(a) {
	case POLYCOMPRESSEDBYTES_768: // Also covers _512
		for i in 0..<N/2 {
			r.coeffs[2*i+0] = i16(((u16(a[0] & 15) * Q) + 8) >> 4)
			r.coeffs[2*i+1] = i16(((u16(a[0] >> 4) * Q) + 8) >> 4)
			a = a[1:]
		}
	case POLYCOMPRESSEDBYTES_1024:
		t: [8]byte = ---
		defer crypto.zero_explicit(&t, size_of(t))

		for i in 0..<N/8 {
			t[0] = (a[0] >> 0)
			t[1] = (a[0] >> 5) | (a[1] << 3)
			t[2] = (a[1] >> 2)
			t[3] = (a[1] >> 7) | (a[2] << 1)
			t[4] = (a[2] >> 4) | (a[3] << 4)
			t[5] = (a[3] >> 1)
			t[6] = (a[3] >> 6) | (a[4] << 2)
			t[7] = (a[4] >> 3)
			a = a[5:]

			for j in 0..<8 {
				r.coeffs[8*i+j] = i16((u32(t[j] & 31) * Q + 16) >> 5)
			}
		}
	case:
		panic_contextless("crypto/mlkem: invalid POLYCOMPRESSEDBYTES")
	}
}

poly_tobytes :: proc "contextless" (r: []byte, a: ^Poly) #no_bounds_check {
	ensure_contextless(len(r) >= POLYBYTES)

	for i in 0..<N/2 {
		// map to positive standard representatives
		t0 := u16(a.coeffs[2*i])
		t0 += u16((i16(t0) >> 15) & Q)
		t1 := u16(a.coeffs[2*i+1])
		t1 += u16((i16(t1) >> 15) & Q)
		r[3*i+0] = byte(t0 >> 0)
		r[3*i+1] = byte(t0 >> 8) | byte(t1 << 4)
		r[3*i+2] = byte(t1 >> 4)
	}
}

@(require_results)
poly_frombytes :: proc "contextless" (r: ^Poly, a: []byte) -> bool #no_bounds_check {
	ensure_contextless(len(a) >= POLYBYTES)

	ok := true
	for i in 0..<N/2 {
		r.coeffs[2*i] = i16(((u16(a[3*i+0]) >> 0) | (u16(a[3*i+1]) << 8)) & 0xFFF)
		r.coeffs[2*i+1] = i16(((u16(a[3*i+1]) >> 4) | (u16(a[3*i+2]) << 4)) & 0xFFF)
		ok &= r.coeffs[2*i] < Q && r.coeffs[2*i+1] < Q
	}

	return ok
}

poly_frommsg :: proc "contextless" (r: ^Poly, msg: []byte) #no_bounds_check {
	#assert(INDCPA_MSGBYTES == N/8)
	ensure_contextless(len(msg) == INDCPA_MSGBYTES)

	for i in 0..<N/8 {
		for j in 0..<8 {
			r.coeffs[8*i+j] = subtle.csel_i16(0, (Q+1)/2, int(msg[i] >> uint(j))&1)
		}
	}
}

poly_tomsg :: proc "contextless" (msg: []byte, a: ^Poly) #no_bounds_check {
	ensure_contextless(len(msg) == INDCPA_MSGBYTES)

	for i in 0..<N/8 {
		msg[i] = 0
		for j in uint(0)..<8 {
			t := u32(a.coeffs[8*i+int(j)])
			// t += ((int16_t)t >> 15) & Q
			// t  = (((t << 1) + Q/2)/Q) & 1
			t <<= 1
			t += 1665
			t *= 80635
			t >>= 28
			t &= 1
			msg[i] |= byte(t << j)
		}
	}
}

poly_getnoise_eta1_512 :: proc(r: ^Poly, seed: []byte, iv: byte) {
	buf: [ETA1_512*N/4]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	prf(buf[:], seed, iv)
	poly_cbd_eta1_512(r, &buf)
}

poly_getnoise_eta1 :: proc(r: ^Poly, seed: []byte, iv: byte) {
	buf: [ETA1*N/4]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	prf(buf[:], seed, iv)
	poly_cbd_eta1(r, &buf)
}

poly_getnoise_eta2 :: proc(r: ^Poly, seed: []byte, iv: byte) {
	buf: [ETA2*N/4]byte = ---
	defer crypto.zero_explicit(&buf, size_of(buf))

	prf(buf[:], seed, iv)
	poly_cbd_eta2(r, &buf)
}

poly_ntt :: proc "contextless" (r: ^Poly) {
	ntt(&r.coeffs)
	poly_reduce(r)
}

poly_invntt_tomont :: proc "contextless" (r: ^Poly) {
	invntt(&r.coeffs)
}

poly_basemul_montgomery :: proc "contextless" (r, a, b: ^Poly) #no_bounds_check {
	for i in 0..<N/4 {
		j := 4 * i
		r.coeffs[j], r.coeffs[j+1] = base_case_multiply(a.coeffs[j], a.coeffs[j+1], b.coeffs[j], b.coeffs[j+1], ZETAS[64+i])
		r.coeffs[j+2], r.coeffs[j+3] = base_case_multiply(a.coeffs[j+2], a.coeffs[j+3], b.coeffs[j+2], b.coeffs[j+3], -ZETAS[64+i])
	}
}

poly_tomont :: proc "contextless" (r: ^Poly) {
	F : i16 : (1 << 32) % Q
	for v, i  in r.coeffs {
		r.coeffs[i] = montgomery_reduce(i32(v)*i32(F))
	}
}

poly_reduce :: proc "contextless" (r: ^Poly) {
	for v, i  in r.coeffs {
		r.coeffs[i] = barrett_reduce(v)
	}
}

poly_add :: proc "contextless" (r, a, b: ^Poly) {
	for i in 0..<N {
		r.coeffs[i] = a.coeffs[i] + b.coeffs[i]
	}
}

poly_sub :: proc "contextless" (r, a, b: ^Poly) {
	for i in 0..<N {
		r.coeffs[i] = a.coeffs[i] - b.coeffs[i]
	}
}

poly_clear :: proc "contextless" (a: ..^Poly) {
	for j in 0..<len(a) {
		p := a[j]
		crypto.zero_explicit(p, size_of(Poly))
	}
}

poly_compressed_bytes :: #force_inline proc "contextless" (k: int) -> int {
	switch k {
	case K_512:
		return POLYCOMPRESSEDBYTES_512
	case K_768:
		return POLYCOMPRESSEDBYTES_768
	case K_1024:
		return POLYCOMPRESSEDBYTES_1024
	case:
		panic_contextless("crypto/mlkem: invalid k")
	}
}
