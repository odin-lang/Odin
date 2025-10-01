package _weierstrass

import "core:math/bits"
import "core:mem"
import "core:slice"

pt_scalar_mul :: proc "contextless" (
	p, a: ^$T,
	sc: ^$S,
	unsafe_is_vartime: bool = false,
) {
	when T == Point_p256r1 && S == Scalar_p256r1 {
		p_tbl: Multiply_Table_p256r1 = ---
		q, tmp: Point_p256r1
		SC_SZ :: SC_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	mul_tbl_set(&p_tbl, a, unsafe_is_vartime)

	b: [SC_SZ]byte
	sc_bytes(b[:], sc)

	pt_identity(&q)
	for limb_byte, i in b {
		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 0 {
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
			pt_double(&q, &q)
		}

		mul_tbl_lookup(&tmp, &p_tbl, u64(hi), unsafe_is_vartime)
		pt_add(&q, &q, &tmp)

		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		pt_double(&q, &q)
		mul_tbl_lookup(&tmp, &p_tbl, u64(lo), unsafe_is_vartime)
		pt_add(&q, &q, &tmp)
	}

	pt_set(p, &q)

	if !unsafe_is_vartime {
		mem.zero_explicit(&b, size_of(b))
		mem.zero_explicit(&p_tbl, size_of(p_tbl))
		pt_clear_vec([]^T{&q, &tmp})
	}
}

@(private = "file")
Multiply_Table_p256r1 :: [15]Point_p256r1

@(private = "file")
mul_tbl_set :: proc "contextless"(
	tbl: ^$T,
	point: ^$U,
	unsafe_is_vartime: bool,
) {
	when T == Multiply_Table_p256r1 && U == Point_p256r1{
		tmp: Point_p256r1
		pt_set(&tmp, point)
	} else {
		#panic("weierstrass: invalid curve")
	}

	pt_set(&tbl[0], &tmp)
	for i in 1 ..<15 {
		pt_add(&tmp, &tmp, point)
		pt_set(&tbl[i], &tmp)
	}

	if !unsafe_is_vartime {
		pt_clear(&tmp)
	}
}

@(private = "file")
mul_tbl_lookup :: proc "contextless" (
	point: ^$T,
	tbl: ^$U,
	idx: u64,
	unsafe_is_vartime: bool,
 ) {
	if unsafe_is_vartime {
		switch idx {
		case 0:
			pt_identity(point)
		case:
			pt_set(point, &tbl[idx - 1])
		}
		return
	}

	pt_identity(point)
	for i in u64(1)..<16 {
		_, ctrl := bits.sub_u64(0, (i ~ idx), 0)
		pt_cond_select(point, point, &tbl[i - 1], int(~ctrl) & 1)
	}
}

