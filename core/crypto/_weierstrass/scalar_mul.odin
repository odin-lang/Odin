package _weierstrass

import "core:mem"

// TODO/perf: Rewrite this to use a windowed multiply.
pt_scalar_mul :: proc (p, a: ^$T, s: ^$S) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
		SC_SZ :: SC_SIZE_P256R1
		q, id, addend: Point_p256r1
	} else {
		#panic("weierstrass: invalid curve")
	}

	// Naive constant-time double-and-add.
	pt_set(&q, a)
	pt_identity(p)
	pt_identity(&id)

	b: [SC_SZ]byte
	sc_bytes(b[:], s)

	n_bits :: SC_SZ * 8 - 1
	for i := n_bits; i >= 0; i = i - 1 {
		if i != n_bits {
			pt_double(&q, &q)
		}

		b_ := (b[i/8] >> uint(i % 8)) & 1
		pt_cond_select(&addend, &id, &q, int(b_))

		pt_add(p, p, &addend)
	}
	mem.zero_explicit(&b, size_of(b))

	pt_clear_vec([]^T{&q, &addend})
}
