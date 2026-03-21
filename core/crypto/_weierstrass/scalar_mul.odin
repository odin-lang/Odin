package _weierstrass

import "core:crypto"
@(require) import subtle "core:crypto/_subtle"

pt_scalar_mul :: proc "contextless" (
	p, a: ^$T,
	sc: ^$S,
	unsafe_is_vartime: bool = false,
) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		SC_SZ :: SC_SIZE_P256R1
	} else when T == Point_p384r1 && S == Scalar_p384r1 {
		SC_SZ :: SC_SIZE_P384R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	b: [SC_SZ]byte = ---
	sc_bytes(b[:], sc)

	pt_scalar_mul_bytes(p, a, b[:], unsafe_is_vartime)

	if !unsafe_is_vartime {
		crypto.zero_explicit(&b, size_of(b))
	}
}

pt_scalar_mul_bytes :: proc "contextless" (
	p, a: ^$T,
	sc: []byte,
	unsafe_is_vartime: bool = false,
) {
	when T == Point_p256r1 {
		p_tbl: Multiply_Table_p256r1 = ---
		q, tmp: Point_p256r1 = ---, ---
		SC_SZ :: SC_SIZE_P256R1
	} else when T == Point_p384r1 {
		p_tbl: Multiply_Table_p384r1 = ---
		q, tmp: Point_p384r1 = ---, ---
		SC_SZ :: SC_SIZE_P384R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	assert_contextless(len(sc) == SC_SZ, "weierstrass: invalid scalar size")
	mul_tbl_set(&p_tbl, a, unsafe_is_vartime)

	pt_identity(&q)
	for limb_byte, i in sc {
		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 0 {
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
		}
		mul_tbl_lookup_add(&q, &tmp, &p_tbl, u64(hi), unsafe_is_vartime)

		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		mul_tbl_lookup_add(&q, &tmp, &p_tbl, u64(lo), unsafe_is_vartime)
	}

	pt_set(p, &q)

	if !unsafe_is_vartime {
		crypto.zero_explicit(&p_tbl, size_of(p_tbl))
		pt_clear_vec([]^T{&q, &tmp})
	}
}

pt_double_scalar_mul_generator_vartime :: proc "contextless" (
	p, q: ^$T,
	sc_g, sc_q: ^$Q,
) {
	// Strauss-Shamir, commonly referred to as the "Shamir trick",
	// saves half the doublings, relative to doing this the naive way.
	//
	// Note: In the unlikely event where we support curves with an
	// efficent endomorphism (secp256k1), scalarmul + GLV is faster.
	when T == Point_p256r1 && Q == Scalar_p256r1 {
		q_tbl: Multiply_Table_p256r1 = ---
		SC_SZ :: SC_SIZE_P256R1
	} else when T == Point_p384r1 && Q == Scalar_p384r1 {
		q_tbl: Multiply_Table_p384r1 = ---
		SC_SZ :: SC_SIZE_P384R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	sc_q_bytes, sc_g_bytes: [SC_SZ]byte = ---, ---
	sc_bytes(sc_q_bytes[:], sc_q)
	sc_bytes(sc_g_bytes[:], sc_g)

	r, tmp: T = ---, ---
	when crypto.COMPACT_IMPLS == true {
		pt_generator(&r)
		when T == Point_p256r1 {
			g_tbl: Multiply_Table_p256r1 = ---
		} else when T == Point_p384r1 {
			g_tbl: Multiply_Table_p384r1 = ---
		}
		mul_tbl_set(&g_tbl, &r, true)
	} else {
		when T == Point_p256r1 {
			g_tbl := &Gen_Multiply_Table_p256r1_lo[31]
		} else when T == Point_p384r1 {
			g_tbl := &Gen_Multiply_Table_p384r1_lo[47]
		}
	}
	mul_tbl_set(&q_tbl, q, true)

	pt_identity(&r)
	for i in 0..<SC_SZ {
		limb_byte_q, limb_byte_g := sc_q_bytes[i], sc_g_bytes[i]
		hi_q, lo_q := (limb_byte_q >> 4) & 0x0f, limb_byte_q & 0x0f
		hi_g, lo_g := (limb_byte_g >> 4) & 0x0f, limb_byte_g & 0x0f

		if i != 0 {
			pt_double(&r, &r)
			pt_double(&r, &r)
			pt_double(&r, &r)
			pt_double(&r, &r)
		}
		mul_tbl_lookup_add(&r, &tmp, &q_tbl, u64(hi_q), true)
		when crypto.COMPACT_IMPLS == true {
			mul_tbl_lookup_add(&r, &tmp, &g_tbl, u64(hi_g), true)
		} else {
			mul_affine_tbl_lookup_add(&r, &tmp, g_tbl, u64(hi_g), true)
		}

		pt_double(&r, &r)
		pt_double(&r, &r)
		pt_double(&r, &r)
		pt_double(&r, &r)
		mul_tbl_lookup_add(&r, &tmp, &q_tbl, u64(lo_q), true)
		when crypto.COMPACT_IMPLS == true {
			mul_tbl_lookup_add(&r, &tmp, &g_tbl, u64(lo_g), true)
		} else {
			mul_affine_tbl_lookup_add(&r, &tmp, g_tbl, u64(lo_g), true)
		}
	}

	pt_set(p, &r)
}

when crypto.COMPACT_IMPLS == true {
	pt_scalar_mul_generator :: proc "contextless" (
		p: ^$T,
		sc: ^$S,
		unsafe_is_vartime: bool = false,
	) {
		g: T
		pt_generator(&g)

		pt_scalar_mul(p, &g, sc, unsafe_is_vartime)
	}
} else {
	pt_scalar_mul_generator :: proc "contextless" (
		p: ^$T,
		sc: ^$S,
		unsafe_is_vartime: bool = false,
	) {
		when T == Point_p256r1 && S == Scalar_p256r1 {
			p_tbl_hi := &Gen_Multiply_Table_p256r1_hi
			p_tbl_lo := &Gen_Multiply_Table_p256r1_lo
			tmp: Point_p256r1 = ---
			SC_SZ :: SC_SIZE_P256R1
		} else when T == Point_p384r1 && S == Scalar_p384r1 {
			p_tbl_hi := &Gen_Multiply_Table_p384r1_hi
			p_tbl_lo := &Gen_Multiply_Table_p384r1_lo
			tmp: Point_p384r1 = ---
			SC_SZ :: SC_SIZE_P384R1
		} else {
			#panic("weierstrass: invalid curve")
		}

		b: [SC_SZ]byte
		sc_bytes(b[:], sc)

		pt_identity(p)
		for limb_byte, i in b {
			hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f
			mul_affine_tbl_lookup_add(p, &tmp, &p_tbl_hi[i], u64(hi), unsafe_is_vartime)
			mul_affine_tbl_lookup_add(p, &tmp, &p_tbl_lo[i], u64(lo), unsafe_is_vartime)
		}

		if !unsafe_is_vartime {
			crypto.zero_explicit(&b, size_of(b))
			pt_clear(&tmp)
		}
	}
}

@(private="file")
Multiply_Table_p256r1 :: [15]Point_p256r1
@(private="file")
Multiply_Table_p384r1 :: [15]Point_p384r1

@(private="file")
mul_tbl_set :: proc "contextless"(
	tbl: ^$T,
	point: ^$U,
	unsafe_is_vartime: bool,
) {
	when T == Multiply_Table_p256r1 && U == Point_p256r1{
		tmp: Point_p256r1
	} else when T == Multiply_Table_p384r1 && U == Point_p384r1{
		tmp: Point_p384r1
	} else {
		#panic("weierstrass: invalid curve")
	}

	pt_set(&tmp, point)
	pt_set(&tbl[0], &tmp)
	for i in 1 ..<15 {
		pt_add(&tmp, &tmp, point)
		pt_set(&tbl[i], &tmp)
	}

	if !unsafe_is_vartime {
		pt_clear(&tmp)
	}
}

@(private="file")
mul_tbl_lookup_add :: proc "contextless" (
	point, tmp: ^$T,
	tbl: ^$U,
	idx: u64,
	unsafe_is_vartime: bool,
 ) {
	if unsafe_is_vartime {
		switch idx {
		case 0:
		case:
			pt_add(point, point, &tbl[idx - 1])
		}
		return
	}

	pt_identity(tmp)
	for i in u64(1)..<16 {
		ctrl := subtle.eq(i, idx)
		pt_cond_select(tmp, tmp, &tbl[i - 1], int(ctrl))
	}

	pt_add(point, point, tmp)
}

when crypto.COMPACT_IMPLS == false {
	@(private)
	Affine_Point_p256r1 :: struct {
		x: Field_Element_p256r1,
		y: Field_Element_p256r1,
	}

	@(private)
	Affine_Point_p384r1 :: struct {
		x: Field_Element_p384r1,
		y: Field_Element_p384r1,
	}

	@(private="file")
	mul_affine_tbl_lookup_add :: proc "contextless" (
		point, tmp: ^$T,
		tbl: ^$U,
		idx: u64,
		unsafe_is_vartime: bool,
	) {
		if unsafe_is_vartime {
			switch idx {
			case 0:
			case:
				pt_add_mixed(point, point, &tbl[idx - 1].x, &tbl[idx - 1].y)
			}
			return
		}

		pt_identity(tmp)
		for i in u64(1)..<16 {
			ctrl := int(subtle.eq(i, idx))
			fe_cond_select(&tmp.x, &tmp.x, &tbl[i - 1].x, ctrl)
			fe_cond_select(&tmp.y, &tmp.y, &tbl[i - 1].y, ctrl)
		}

		// The mixed addition formula assumes that the addend is not
		// the neutral element.  Do the addition regardless, and then
		// conditionally select the right result.
		pt_add_mixed(tmp, point, &tmp.x, &tmp.y)

		ctrl := subtle.u64_is_non_zero(idx)
		pt_cond_select(point, point, tmp, int(ctrl))
	}
}
