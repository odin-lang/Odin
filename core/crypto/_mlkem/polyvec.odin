#+private
package _mlkem

import "core:crypto"

Polyvec :: struct {
	vec: [K_MAX]Poly,
}

polyvec_compress :: proc "contextless" (r: []byte, a: ^Polyvec, kay: int) #no_bounds_check {
	d0: u64

	r := r
	switch len(r) {
	case POLYVECCOMPRESSEDBYTES_512, POLYVECCOMPRESSEDBYTES_768:
		ensure_contextless(kay == K_512 || kay == K_768)

		t: [4]u16 = ---
		defer crypto.zero_explicit(&t, size_of(t))

		for i in 0..<kay {
			for j in 0..<N/4 {
				for k in 0..<4 {
					t[k] = u16(a.vec[i].coeffs[4*j+k])
					t[k] += u16((i16(t[k]) >> 15) & Q)
					// t[k]  = ((((uint32_t)t[k] << 10) + Q/2)/Q) & 0x3ff
					d0 = u64(t[k])
					d0 <<= 10
					d0 += 1665
					d0 *= 1290167
					d0 >>= 32
					t[k] = u16(d0 & 0x3ff)
				}

				r[0] = byte(t[0] >> 0)
				r[1] = byte((t[0] >> 8) | (t[1] << 2))
				r[2] = byte((t[1] >> 6) | (t[2] << 4))
				r[3] = byte((t[2] >> 4) | (t[3] << 6))
				r[4] = byte(t[3] >> 2)
				r = r[5:]
			}
		}
	case POLYVECCOMPRESSEDBYTES_1024:
		ensure_contextless(kay == K_1024)

		t: [8]u16 = ---
		defer crypto.zero_explicit(&t, size_of(t))

		for i in 0..<K_1024 {
			for j in 0..<N/8 {
				for k in 0..<8 {
					t[k] = u16(a.vec[i].coeffs[8*j+k])
					t[k] += u16((i16(t[k]) >> 15) & Q)
					// t[k]  = ((((uint32_t)t[k] << 11) + Q/2)/Q) & 0x7ff
					d0 = u64(t[k])
					d0 <<= 11
					d0 += 1664
					d0 *= 645084
					d0 >>= 31
					t[k] = u16(d0 & 0x7ff)
				}

				r[0] = byte(t[0] >> 0)
				r[1] = byte((t[0] >> 8) | (t[1] << 3))
				r[2] = byte((t[1] >> 5) | (t[2] << 6))
				r[3] = byte(t[2] >> 2)
				r[4] = byte((t[2] >> 10) | (t[3] << 1))
				r[5] = byte((t[3] >> 7) | (t[4] << 4))
				r[6] = byte((t[4] >> 4) | (t[5] << 7))
				r[7] = byte(t[5] >> 1)
				r[8] = byte((t[5] >> 9) | (t[6] << 2))
				r[9] = byte((t[6] >> 6) | (t[7] << 5))
				r[10] = byte(t[7] >> 3)
				r = r[11:]
			}
		}
	case:
		panic_contextless("crypto/mlkem: invalid POLYVECCOMPRESSEDBYTES")
	}
}

polyvec_decompress :: proc "contextless" (r: ^Polyvec, a: []byte, kay: int) #no_bounds_check {
	a := a
	switch len(a) {
	case POLYVECCOMPRESSEDBYTES_512, POLYVECCOMPRESSEDBYTES_768:
		ensure_contextless(kay == K_512 || kay == K_768)

		t: [4]u16 = ---
		defer crypto.zero_explicit(&t, size_of(t))

		for i in 0..<kay {
			for j in 0..<N/4 {
				t[0] = u16(a[0] >> 0) | (u16(a[1]) << 8)
				t[1] = u16(a[1] >> 2) | (u16(a[2]) << 6)
				t[2] = u16(a[2] >> 4) | (u16(a[3]) << 4)
				t[3] = u16(a[3] >> 6) | (u16(a[4]) << 2)
				a = a[5:]

				for k in 0..<4 {
					r.vec[i].coeffs[4*j+k] = i16((u32(t[k] & 0x3FF) * Q + 512) >> 10)
				}
			}
		}
	case POLYVECCOMPRESSEDBYTES_1024:
		t: [8]u16 = ---
		defer crypto.zero_explicit(&t, size_of(t))

		for i in 0..<K_1024 {
			for j in 0..<N/8 {
				t[0] = u16(a[0] >> 0) | (u16(a[1]) << 8)
				t[1] = u16(a[1] >> 3) | (u16(a[2]) << 5)
				t[2] = u16(a[2] >> 6) | (u16(a[3]) << 2) | (u16(a[4]) << 10)
				t[3] = u16(a[4] >> 1) | (u16(a[5]) << 7)
				t[4] = u16(a[5] >> 4) | (u16(a[6]) << 4)
				t[5] = u16(a[6] >> 7) | (u16(a[7]) << 1) | (u16(a[8]) << 9)
				t[6] = u16(a[8] >> 2) | (u16(a[9]) << 6)
				t[7] = u16(a[9] >> 5) | (u16(a[10]) << 3)
				a = a[11:]

				for k in 0..<8 {
					r.vec[i].coeffs[8*j+k] = i16((u32(t[k] & 0x7FF) * Q + 1024) >> 11)
				}
			}
		}
	case:
		panic_contextless("crypto/mlkem: invalid POLYVECCOMPRESSEDBYTES")
	}
}

polyvec_tobytes :: proc "contextless" (r: []byte, a: ^Polyvec, k: int) #no_bounds_check {
	ensure_contextless(len(r) == k * POLYBYTES, "crypto/mlkem: invalid buffer")

	r := r
	for i in 0..<k {
		poly_tobytes(r, &a.vec[i])
		r = r[POLYBYTES:]
	}
}

@(require_results)
polyvec_frombytes :: proc "contextless" (r: ^Polyvec, a: []byte, k: int) -> bool #no_bounds_check {
	switch k {
	case K_512, K_768, K_1024:
	case:
		panic_contextless("crypto/mlkem: invalid POLYVECBYTES")
	}
	ensure_contextless(len(a) == k * POLYBYTES, "crypto/mlkem: invalid buffer")

	a := a
	ok := true
	for i in 0..<k {
		ok &= poly_frombytes(&r.vec[i], a)
		a = a[POLYBYTES:]
	}
	return ok
}

@(require_results)
polyvec_byte_size :: #force_inline proc "contextless" (k: int) -> int {
	switch k {
	case K_512, K_768, K_1024:
		return k * POLYBYTES
	case:
		return 0
	}
}

@(require_results)
polyvec_compressed_byte_size :: #force_inline proc "contextless" (k: int) -> int {
	switch k {
	case K_512:
		return POLYVECCOMPRESSEDBYTES_512
	case K_768:
		return POLYVECCOMPRESSEDBYTES_768
	case K_1024:
		return POLYVECCOMPRESSEDBYTES_1024
	case:
		return 0
	}
}

polyvec_ntt :: proc "contextless" (r: ^Polyvec, k: int) {
	for i in 0..<k {
		poly_ntt(&r.vec[i])
	}
}

polyvec_invntt_tomont :: proc "contextless" (r: ^Polyvec, k: int) {
	for i in 0..<k {
		poly_invntt_tomont(&r.vec[i])
	}
}

polyvec_basemul_acc_montgomery :: proc "contextless" (r: ^Poly, a, b: ^Polyvec, k: int) {
	t: Poly = ---
	defer crypto.zero_explicit(&t, size_of(t))

	poly_basemul_montgomery(r, &a.vec[0], &b.vec[0])
	for i in 1..<k {
		poly_basemul_montgomery(&t, &a.vec[i], &b.vec[i])
		poly_add(r, r, &t)
	}

	poly_reduce(r)
}

polyvec_reduce :: proc "contextless" (r: ^Polyvec, k: int) {
	for i in 0..<k {
		poly_reduce(&r.vec[i])
	}
}

polyvec_add :: proc "contextless" (r, a, b: ^Polyvec, k: int) {
	for i in 0..<k {
		poly_add(&r.vec[i], &a.vec[i], &b.vec[i])
	}
}

polyvec_clear :: proc "contextless" (rs: ..^Polyvec) {
	for j in 0..<len(rs) {
		r := rs[j]
		crypto.zero_explicit(r, size_of(Polyvec))
	}
}
