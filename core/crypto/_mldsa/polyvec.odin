#+private
package _mldsa

import "core:crypto"

Polyvec_L :: struct {
	vec: [L_MAX]Poly,
}

Polyvec_K :: struct {
	vec: [K_MAX]Poly,
}

polyvec_copy :: proc "contextless" (dst, src: ^$T, params: ^Params) where T == Polyvec_L || T == Polyvec_K {
	when T == Polyvec_L {
		n := params.l
	} else {
		n := params.k
	}

	for i in 0..<n {
		copy(dst.vec[i].coeffs[:], src.vec[i].coeffs[:])
	}
}

polyvec_clear :: proc "contextless" (vecs: []^$T) where T == Polyvec_L || T == Polyvec_K {
	for _, i in vecs {
		crypto.zero_explicit(vecs[i], size_of(T))
	}
}

polyvec_matrix_expand :: proc(mat: []Polyvec_L, rho: []byte, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		for j in 0..<params.l {
			poly_uniform(&mat[i].vec[j], rho, u16((i << 8) + j))
		}
	}
}

polyvec_matrix_pointwise_montgomery :: proc "contextless" (t: ^Polyvec_K, mat: []Polyvec_L, v: ^Polyvec_L, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		polyvec_l_pointwise_acc_montgomery(&t.vec[i], &mat[i], v, params)
	}
}

polyvec_l_uniform_eta :: proc(v: ^Polyvec_L, seed: []byte, iv: u16, params: ^Params) #no_bounds_check {
	iv := iv
	for i in 0..<params.l {
		poly_uniform_eta(&v.vec[i], seed, iv, params)
		iv += 1
	}
}

polyvec_l_uniform_gamma1 :: proc(v: ^Polyvec_L, seed: []byte, iv: u32, params: ^Params) #no_bounds_check {
	for i in 0..<params.l {
		poly_uniform_gamma1(&v.vec[i], seed, u16(u32(params.l) * iv + u32(i)), params)
	}
}

polyvec_l_reduce :: proc "contextless" (v: ^Polyvec_L, params: ^Params) #no_bounds_check {
	for i in 0..<params.l {
		poly_reduce(&v.vec[i])
	}
}

polyvec_l_add :: proc "contextless" (w, u, v: ^Polyvec_L, params: ^Params) #no_bounds_check {
	for i in 0..<params.l {
		poly_add(&w.vec[i], &u.vec[i], &v.vec[i])
	}
}

polyvec_l_ntt :: proc "contextless" (v: ^Polyvec_L, params: ^Params) {
	for i in 0..<params.l {
		poly_ntt(&v.vec[i])
	}
}

polyvec_l_invntt_tomont :: proc "contextless" (v: ^Polyvec_L, params: ^Params) {
	for i in 0..<params.l {
		poly_invntt_tomont(&v.vec[i])
	}
}

polyvec_l_pointwise_poly_montgomery :: proc "contextless" (r: ^Polyvec_L, a: ^Poly, v: ^Polyvec_L, params: ^Params) #no_bounds_check {
	for i in 0..<params.l {
		poly_pointwise_montgomery(&r.vec[i], a, &v.vec[i])
	}
}

polyvec_l_pointwise_acc_montgomery :: proc "contextless" (w: ^Poly, u, v: ^Polyvec_L, params: ^Params) #no_bounds_check {
	t: Poly

	poly_pointwise_montgomery(w, &u.vec[0], &v.vec[0])
	for i in 1..<params.l {
		poly_pointwise_montgomery(&t, &u.vec[i], &v.vec[i])
		poly_add(w, w, &t)
	}
}

polyvec_l_chknorm :: proc "contextless" (v: ^Polyvec_L, bound: i32, params: ^Params) -> bool #no_bounds_check {
	for i in 0..<params.l {
		if poly_chknorm(&v.vec[i],bound) {
			return true
		}
	}

	return false
}

polyvec_k_uniform_eta :: proc (v: ^Polyvec_K, seed: []byte, iv: u16, params: ^Params) #no_bounds_check {
	iv := iv
	for i in 0..<params.k {
		poly_uniform_eta(&v.vec[i], seed, iv, params)
		iv += 1
	}
}

polyvec_k_reduce :: proc "contextless" (v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_reduce(&v.vec[i])
	}
}

polyvec_k_caddq :: proc "contextless" (v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_caddq(&v.vec[i])
	}
}

polyvec_k_add :: proc "contextless" (w, u, v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_add(&w.vec[i], &u.vec[i], &v.vec[i])
	}
}

polyvec_k_sub :: proc "contextless" (w, u, v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_sub(&w.vec[i], &u.vec[i], &v.vec[i])
	}
}

polyvec_k_shiftl :: proc "contextless" (v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_shiftl(&v.vec[i])
	}
}

polyvec_k_ntt :: proc "contextless" (v: ^Polyvec_K, params: ^Params) {
	for i in 0..<params.k {
		poly_ntt(&v.vec[i])
	}
}

polyvec_k_invntt_tomont :: proc "contextless" (v: ^Polyvec_K, params: ^Params) {
	for i in 0..<params.k {
		poly_invntt_tomont(&v.vec[i])
	}
}

polyvec_k_pointwise_poly_montgomery :: proc "contextless" (r: ^Polyvec_K, a: ^Poly, v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_pointwise_montgomery(&r.vec[i], a, &v.vec[i])
	}
}

polyvec_k_chknorm :: proc "contextless" (v: ^Polyvec_K, bound: i32, params: ^Params) -> bool #no_bounds_check {
	for i in 0..<params.k {
		if poly_chknorm(&v.vec[i],bound) {
			return true
		}
	}

	return false
}

polyvec_k_power2round :: proc "contextless" (v1, v0, v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_power2round(&v1.vec[i], &v0.vec[i], &v.vec[i])
	}
}

polyvec_k_decompose :: proc "contextless" (v1, v0, v: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_decompose(&v1.vec[i], &v0.vec[i], &v.vec[i], params)
	}
}

polyvec_k_make_hint :: proc "contextless" (h, v0, v1: ^Polyvec_K, params: ^Params) -> uint #no_bounds_check {
	s: uint

	for i in 0..<params.k {
		s += poly_make_hint(&h.vec[i], &v0.vec[i], &v1.vec[i], params)
	}

	return s
}

polyvec_k_use_hint :: proc "contextless" (w, u, h: ^Polyvec_K, params: ^Params) #no_bounds_check {
	for i in 0..<params.k {
		poly_use_hint(&w.vec[i],&u.vec[i], &h.vec[i], params)
	}
}

polyvec_k_pack_w1 :: proc "contextless" (r: []byte, w1: ^Polyvec_K, params: ^Params) #no_bounds_check {
	packed_len := polyw1_packedbytes(params)
	for i in 0..<params.k {
		polyw1_pack(r[i*packed_len:], &w1.vec[i], params)
	}
}
