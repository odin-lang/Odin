package _mldsa

import "core:crypto"
import "core:crypto/shake"

// This implementation is derived from the PQ-CRYSTALS reference
// implementation [[ https://github.com/pq-crystals/dilithium ]],
// primarily for licensing reasons.  Arguably mldsa-native is
// a more "up to date" codebase, but the changes to the
// ref code is minor and they slapped an attribution-required
// license on something that was originally CC-0/Apache 2.0.

SEEDBYTES :: 32
RNDBYTES :: 32
CTXBYTES_MAX :: 255

Params :: struct {
	k: int,
	l: int,
	eta: i32,
	tau: int,
	beta: i32,
	gamma1: i32,
	gamma2: i32,
	omega: int,
	ctild_bytes: int,
}

@(rodata)
Params_44 := Params{
	k = 4,
	l = 4,
	eta = 2,
	tau = 39,
	beta = 78,
	gamma1 = 1 << 17,
	gamma2 = (Q-1)/88,
	omega = 80,
	ctild_bytes = 32,
}

@(rodata)
Params_65 := Params{
	k = 6,
	l = 5,
	eta = 4,
	tau = 49,
	beta = 196,
	gamma1 = 1 << 19,
	gamma2 = (Q-1)/32,
	omega = 55,
	ctild_bytes = 48,
}

@(rodata)
Params_87 := Params{
	k = 8,
	l = 7,
	eta = 2,
	tau = 60,
	beta = 120,
	gamma1 = 1 << 19,
	gamma2 = (Q-1)/32,
	omega = 75,
	ctild_bytes = 64,
}

Private_Key :: struct {
	params: ^Params,

	rho: [SEEDBYTES]byte,
	tr: [TRBYTES]byte,
	key: [SEEDBYTES]byte,
	t0: Polyvec_K,
	s1: Polyvec_L,
	s2: Polyvec_K,

	pub_key: Public_Key,
	seed: [SEEDBYTES]byte,
}

Public_Key :: struct {
	params: ^Params,

	t1: Polyvec_K,
	rho: [SEEDBYTES]byte,
	mu: [TRBYTES]byte,
}

@(private)
Signature :: struct {
	params: ^Params,

	c: [CTILDBYTES_MAX]byte,
	z: Polyvec_L,
	h: Polyvec_K,
}

dsa_keygen_internal :: proc(
	priv_key: ^Private_Key,
	seed: []byte,
	params: ^Params,
) {
	ensure(len(seed) == SEEDBYTES, "crypto/mldsa: invalid seed")

	pub_key := &priv_key.pub_key
	pub_key.params = params
	priv_key.params = params

	copy(priv_key.seed[:], seed)

	seedbuf: [2*SEEDBYTES + CRHBYTES]byte = ---
	mat_: [K_MAX]Polyvec_L = ---
	defer crypto.zero_explicit(&seedbuf, size_of(seedbuf))
	defer crypto.zero_explicit(&mat_, size_of(mat_))

	// Expand randomness for rho, rhoprime and key
	copy(seedbuf[:], seed)
	seedbuf[SEEDBYTES] = byte(params.k)
	seedbuf[SEEDBYTES+1] = byte(params.l)
	shake256(seedbuf[:], seedbuf[:SEEDBYTES+2])
	copy(priv_key.rho[:], seedbuf[:SEEDBYTES])
	rhoprime := seedbuf[SEEDBYTES:SEEDBYTES+CRHBYTES]
	copy(priv_key.key[:], seedbuf[SEEDBYTES+CRHBYTES:])

	// Expand matrix
	mat := mat_[:params.k]
	polyvec_matrix_expand(mat, priv_key.rho[:], params)

	// Sample short vectors s1 and s2
	polyvec_l_uniform_eta(&priv_key.s1, rhoprime, 0, params)
	polyvec_k_uniform_eta(&priv_key.s2, rhoprime, u16(params.l), params)

	// Matrix-vector multiplication
	s1hat: Polyvec_L = ---
	defer crypto.zero_explicit(&s1hat, size_of(Polyvec_L))
	polyvec_copy(&s1hat, &priv_key.s1, params)
	polyvec_l_ntt(&s1hat, params)
	polyvec_matrix_pointwise_montgomery(&pub_key.t1, mat, &s1hat, params)
	polyvec_k_reduce(&pub_key.t1, params)
	polyvec_k_invntt_tomont(&pub_key.t1, params)

	// Add error vector s2
	polyvec_k_add(&pub_key.t1, &pub_key.t1, &priv_key.s2, params)

	// Extract t1 and write public key
	pk_bytes_: [SEEDBYTES+POLYVECT1_PACKEDBYTES_MAX]byte = ---
	pk_bytes := pk_bytes_[:public_key_size(params)]
	polyvec_k_caddq(&pub_key.t1, params)
	polyvec_k_power2round(&pub_key.t1, &priv_key.t0, &pub_key.t1, params)
	copy(pub_key.rho[:], priv_key.rho[:])
	_ = pack_pk(pk_bytes, pub_key)

	// Compute H(rho, t1) and write secret key
	shake256(pub_key.mu[:], pk_bytes)
	copy(priv_key.tr[:], pub_key.mu[:])
}

dsa_sign_internal :: proc(
	sig_bytes: []byte,
	m: []byte,
	ctx: []byte,
	rnd: []byte,
	priv_key: ^Private_Key,
	external_mu: []byte = nil
) -> bool {
	params := priv_key.params
	switch params {
	case &Params_44, &Params_65, &Params_87:
	case:
		return false
	}
	if len(sig_bytes) != signature_size(params) {
		return false
	}
	ensure(len(ctx) <= CTXBYTES_MAX, "crypto/mlkem: invalid contxt size")
	ensure(len(rnd) == RNDBYTES, "crypto/mlkem: invalid rnd size")

	mu, rhoprime: [CRHBYTES]byte = ---, ---
	mat_: [K_MAX]Polyvec_L
	w1_bytes_: [SEEDBYTES+POLYVECT1_PACKEDBYTES_MAX]byte = ---
	s1, y: Polyvec_L = ---, ---
	t0, s2, w1, w0: Polyvec_K = ---, ---, ---, ---
	cp: Poly

	polyvec_copy(&s1, &priv_key.s1, params)
	polyvec_copy(&s2, &priv_key.s2, params)
	polyvec_copy(&t0, &priv_key.t0, params)

	defer crypto.zero_explicit(&mu, size_of(mu))
	defer crypto.zero_explicit(&rhoprime, size_of(rhoprime))
	defer crypto.zero_explicit(&mat_, size_of(mat_))
	defer crypto.zero_explicit(&w1_bytes_, size_of(w1_bytes_))
	defer polyvec_clear([]^Polyvec_L{&s1, &y})
	defer polyvec_clear([]^Polyvec_K{&t0, &s2, &w1, &w0})
	defer crypto.zero_explicit(&cp, size_of(cp))

	sig: Signature = ---
	sig.params = params
	h := &sig.h
	z := &sig.z
	c := sig.c[:params.ctild_bytes]

	w1_bytes := w1_bytes_[:params.k*polyw1_packedbytes(params)]

	// Compute mu = CRH(tr, pre, msg)
	if len(external_mu) == 0 {
		// The FIPS publication handles the shake prefix
		// in the public sign operation, but doing it
		// here makes more sense.
		ctx_buf: [2]byte
		shake_ctx: shake.Context = ---
		defer shake.reset(&shake_ctx)

		ctx_len := len(ctx)

		shake.init_256(&shake_ctx)
		shake.write(&shake_ctx, priv_key.tr[:])
		if ctx_len > 0 {
			ctx_buf[1] = byte(ctx_len)
		}
		shake.write(&shake_ctx, ctx_buf[:])
		if ctx_len > 0 {
			shake.write(&shake_ctx, ctx)
		}
		shake.write(&shake_ctx, m)
		shake.read(&shake_ctx, mu[:])
	} else {
		ensure(len(external_mu) == CRHBYTES, "crypto/mlkem: invalid external mu")
		copy(mu[:], external_mu)
	}

	// Compute rhoprime = CRH(key, rnd, mu)
	shake256(rhoprime[:], priv_key.key[:], rnd, mu[:])

	// Expand matrix and transform vectors
	mat := mat_[:params.k]
	polyvec_matrix_expand(mat, priv_key.rho[:], params)
	polyvec_l_ntt(&s1, params)
	polyvec_k_ntt(&s2, params)
	polyvec_k_ntt(&t0, params)

	// Rejection-sampling loop
	iv: u32 // ref uses u16, but ML-DSA-87 will reuse the IV at p = ~2^{-23400}
	for {
		// Sample intermediate vector y
		polyvec_l_uniform_gamma1(&y, rhoprime[:], iv, params)
		iv += 1

		// Matrix-vector multiplication
		polyvec_copy(z, &y, params)
		polyvec_l_ntt(z, params)
		polyvec_matrix_pointwise_montgomery(&w1, mat, z, params)
		polyvec_k_reduce(&w1, params)
		polyvec_k_invntt_tomont(&w1, params)

		// Decompose w and call the random oracle
		polyvec_k_caddq(&w1, params)
		polyvec_k_decompose(&w1, &w0, &w1, params)
		polyvec_k_pack_w1(w1_bytes, &w1, params)

		shake256(c, mu[:], w1_bytes)
		poly_challenge(&cp, c, params)
		poly_ntt(&cp)

		// Compute z, reject if it reveals secret
		polyvec_l_pointwise_poly_montgomery(z, &cp, &s1, params)
		polyvec_l_invntt_tomont(z, params)
		polyvec_l_add(z, z, &y, params)
		polyvec_l_reduce(z, params)
		if polyvec_l_chknorm(z, params.gamma1 - params.beta, params) {
			continue
		}

		// Check that subtracting cs2 does not change high bits of w
		// and low bits do not reveal secret information
		polyvec_k_pointwise_poly_montgomery(h, &cp, &s2, params)
		polyvec_k_invntt_tomont(h, params)
		polyvec_k_sub(&w0, &w0, h, params)
		polyvec_k_reduce(&w0, params)
		if polyvec_k_chknorm(&w0, params.gamma2 - params.beta, params) {
			continue
		}

		// Compute hints for w1
		polyvec_k_pointwise_poly_montgomery(h, &cp, &t0, params)
		polyvec_k_invntt_tomont(h, params)
		polyvec_k_reduce(h, params)
		if polyvec_k_chknorm(h, params.gamma2, params) {
			continue
		}

		polyvec_k_add(&w0, &w0, h, params)
		n := polyvec_k_make_hint(h, &w0, &w1, params)
		if n <= uint(params.omega) {
			break
		}
	}

	// Write signature
	return pack_sig(sig_bytes, &sig)
}

dsa_verify_internal :: proc(
	sig_bytes: []byte,
	m: []byte,
	ctx: []byte,
	pub_key: ^Public_Key,
) -> bool {
	ensure(len(ctx) <= CTXBYTES_MAX, "crypto/mlkem: invalid contxt size")

	params := pub_key.params
	switch params {
	case &Params_44, &Params_65, &Params_87:
	case:
		return false
	}

	sig: Signature = ---
	if !unpack_sig(&sig, sig_bytes, params) {
		return false
	}
	if polyvec_l_chknorm(&sig.z, params.gamma1 - params.beta, params) {
		return false
	}
	c := sig.c[:params.ctild_bytes]
	z := &sig.z
	h := &sig.h

	t1: Polyvec_K = ---
	polyvec_copy(&t1, &pub_key.t1, params)
	rho := pub_key.rho[:]

	// Compute CRH(H(rho, t1), pre, msg)
	mu: [CRHBYTES]byte
	{
		// The FIPS publication handles the shake prefix
		// in the public sign operation, but doing it
		// here makes more sense.
		ctx_buf: [2]byte
		shake_ctx: shake.Context = ---
		defer shake.reset(&shake_ctx)

		ctx_len := len(ctx)

		shake.init_256(&shake_ctx)
		shake.write(&shake_ctx, pub_key.mu[:])
		if ctx_len > 0 {
			ctx_buf[1] = byte(ctx_len)
		}
		shake.write(&shake_ctx, ctx_buf[:])
		if ctx_len > 0 {
			shake.write(&shake_ctx, ctx)
		}
		shake.write(&shake_ctx, m)
		shake.read(&shake_ctx, mu[:])
	}

	// Matrix-vector multiplication; compute Az - c2^dt1
	mat_: [K_MAX]Polyvec_L
	w1: Polyvec_K = ---
	cp: Poly = ---
	mat := mat_[:params.l]

	poly_challenge(&cp, c, params)
	polyvec_matrix_expand(mat, rho, params)

	polyvec_l_ntt(z, params)
	polyvec_matrix_pointwise_montgomery(&w1, mat, z, params)

	poly_ntt(&cp)
	polyvec_k_shiftl(&t1, params)
	polyvec_k_ntt(&t1, params)
	polyvec_k_pointwise_poly_montgomery(&t1, &cp, &t1, params)

	polyvec_k_sub(&w1, &w1, &t1, params)
	polyvec_k_reduce(&w1, params)
	polyvec_k_invntt_tomont(&w1, params)

	// Reconstruct w1
	buf_: [K_MAX*POLYW1_PACKEDBYTES_MAX]byte = ---
	buf := buf_[:params.k*polyw1_packedbytes(params)]
	polyvec_k_caddq(&w1, params)
	polyvec_k_use_hint(&w1, &w1, h, params)
	polyvec_k_pack_w1(buf, &w1, params)

	// Call random oracle and verify challenge
	c2_: [CTILDBYTES_MAX]byte
	c2 := c2_[:params.ctild_bytes]
	shake256(c2, mu[:], buf)

	// Note/perf: Can be vartime
	return crypto.compare_constant_time(c, c2) == 1
}
