package ecdsa

import "core:crypto/hash"
import "core:crypto/hmac"
import "core:mem"

@(private)
Drbg_RFC6979 :: struct {
	v: [hash.MAX_DIGEST_SIZE]byte,
	k: [hash.MAX_DIGEST_SIZE]byte,

	algorithm: hash.Algorithm,
	sz: int,
	need_update: bool,
}

@(private)
init_drbg_rfc6979 :: proc(rng: ^Drbg_RFC6979, algorithm: hash.Algorithm, x_bytes, e_bytes: []byte) {
	rng.algorithm = algorithm
	rng.sz = hash.DIGEST_SIZES[algorithm]
	for i in 0..<rng.sz {
		rng.v[i] = 0x01
		rng.k[i] = 0x00
	}

	drbg_init_update_k(rng, x_bytes, e_bytes, 0x00)
	drbg_update_v(rng)
	drbg_init_update_k(rng, x_bytes, e_bytes, 0x01)
	drbg_update_v(rng)
}

@(private)
drbg_read_rfc6979 :: proc(rng: ^Drbg_RFC6979, sc: ^$T) -> bool {
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
	mem.zero_explicit(rng, size_of(Drbg_RFC6979))
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
drbg_init_update_k :: proc(rng: ^Drbg_RFC6979, i2o_b, b2o_h1: []byte, internal_octet: byte) {
	k, v := rng.k[:rng.sz], rng.v[:rng.sz]

	ctx: hmac.Context
	hmac.init(&ctx, rng.algorithm, k)
	hmac.update(&ctx, v)
	hmac.update(&ctx, []byte{internal_octet})
	hmac.update(&ctx, i2o_b)
	hmac.update(&ctx, b2o_h1)
	hmac.final(&ctx, k)
}
