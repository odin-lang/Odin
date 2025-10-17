package _weierstrass

import "core:mem"

// TODO/perf: Rewrite this to use a windowed multiply.
pt_scalar_mul :: proc "contextless" (p, a: ^$T, s: ^$S) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
		SC_SC :: SC_SIZE_P256R1
		q, id, addend: Point_p256r1
	} else {
		#panic("weierstrass: invalid curve")
	}

	// Naive constant-time double-and-add (MSB->LSB).
	pt_identity(&q)
	pt_identity(&id)

	b: [SC_SIZE]byte
	sc_bytes(b[:], s)

	n_bits :: SC_SC * 8 - 1
	for i := n_bits; i >= 0; i = i - 1 {
		if i != n_bits { // Skip doubling the identity point.
			pt_double(&q, &q)
		}

		b_ := (b[i/8] >> (i % 8)) & 1
		pt_cond_select(&addend, &id, p, int(b_))

		pt_add(&q, &q, &addend)
	}
	mem.zero_explicit(&b, sizeof(b))

	pt_set(p, &q)

	pt_clear_vec([]^T{&q, &addend})
}
