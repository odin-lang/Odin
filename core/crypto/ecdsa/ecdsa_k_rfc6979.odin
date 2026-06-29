package ecdsa

import "core:crypto"
import "core:crypto/hash"
import "core:crypto/hmac"
import secec "core:crypto/_weierstrass"

@(private)
Drbg_RFC6979 :: struct {
	v: [hash.MAX_DIGEST_SIZE]byte,
	k: [hash.MAX_DIGEST_SIZE]byte,

	algorithm: hash.Algorithm,
	sz: int,
	need_update: bool,
}

@(private)
init_drbg_rfc6979 :: proc(rng: ^Drbg_RFC6979, algorithm: hash.Algorithm, x_bytes, e_bytes: []byte, deterministic: bool) {
	rng.algorithm = algorithm
	rng.sz = hash.DIGEST_SIZES[algorithm]
	rng.need_update = false
	for i in 0..<rng.sz {
		rng.v[i] = 0x01
		rng.k[i] = 0x00
	}

	if !deterministic {
		additional_input: [64]byte
		crypto.rand_bytes(additional_input[:])
		defer crypto.zero_explicit(&additional_input, size_of(additional_input))

		drbg_init_update_k(rng, x_bytes, e_bytes, 0x00, additional_input[:])
		drbg_update_v(rng)
		drbg_init_update_k(rng, x_bytes, e_bytes, 0x01, nil)
		drbg_update_v(rng)
	} else {
		drbg_init_update_k(rng, x_bytes, e_bytes, 0x00, nil)
		drbg_update_v(rng)
		drbg_init_update_k(rng, x_bytes, e_bytes, 0x01, nil)
		drbg_update_v(rng)
	}
}

@(private)
drbg_read_rfc6979 :: proc(rng: ^Drbg_RFC6979, sc: ^$T) -> bool {
	// Extremely unlikely, so avoid unless the rejection
	// sampling triggers.
	if rng.need_update {
		drbg_update_k(rng)
		drbg_update_v(rng)
	}

	drbg_update_v(rng)
	rng.need_update = true

	return secec.sc_set_bytes(sc, rng.v[:secec.sc_size(sc)])
}

@(private)
drbg_clear_rfc6979 :: proc(rng: ^Drbg_RFC6979) {
	crypto.zero_explicit(rng, size_of(Drbg_RFC6979))
}

@(private="file")
drbg_update_v :: proc(rng: ^Drbg_RFC6979) {
	// V = HMAC_K(V)
	k, v := rng.k[:rng.sz], rng.v[:rng.sz]
	hmac.sum(rng.algorithm, v, v, k)
}

@(private="file")
drbg_update_k :: proc(rng: ^Drbg_RFC6979) {
	// K = HMAC_K(V || 0x00)
	k, v := rng.k[:rng.sz], rng.v[:rng.sz]

	ctx: hmac.Context
	hmac.init(&ctx, rng.algorithm, k)
	hmac.update(&ctx, v)
	hmac.update(&ctx, []byte{0x00})
	hmac.final(&ctx, k)
}

@(private="file")
drbg_init_update_k :: proc(rng: ^Drbg_RFC6979, i2o_b, b2o_h1: []byte, internal_octet: byte, additional_input: []byte) {
	k, v := rng.k[:rng.sz], rng.v[:rng.sz]

	ctx: hmac.Context
	hmac.init(&ctx, rng.algorithm, k)
	hmac.update(&ctx, v)
	hmac.update(&ctx, []byte{internal_octet})
	hmac.update(&ctx, i2o_b)
	hmac.update(&ctx, b2o_h1)
	if additional_input != nil {
		hmac.update(&ctx, additional_input)
	}
	hmac.final(&ctx, k)
}
