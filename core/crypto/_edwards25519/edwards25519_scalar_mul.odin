package _edwards25519

import "core:crypto"
import field "core:crypto/_fiat/field_scalar25519"
import subtle "core:crypto/_subtle"
import "core:mem"

ge_scalarmult :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	ge_scalarmult_raw(ge, p, &tmp)

	mem.zero_explicit(&tmp, size_of(tmp))
}

ge_scalarmult_vartime :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	ge_scalarmult_raw(ge, p, &tmp, true)
}

ge_double_scalarmult_basepoint_vartime :: proc "contextless" (
	ge: ^Group_Element,
	a: ^Scalar,
	A: ^Group_Element,
	b: ^Scalar,
) {
	// Strauss-Shamir, commonly referred to as the "Shamir trick",
	// saves half the doublings, relative to doing this the naive way.
	//
	// ABGLSV-Pornin (https://eprint.iacr.org/2020/454) is faster,
	// but significantly more complex, and has incompatibilities with
	// mixed-order group elements.

	tmp_add: Add_Scratch = ---
	tmp_addend: Addend_Group_Element = ---
	tmp_dbl: Double_Scratch = ---
	tmp: Group_Element = ---

	A_tbl: Multiply_Table = ---
	mul_tbl_set(&A_tbl, A, &tmp_add)
	when crypto.COMPACT_IMPLS == true {
		G_tbl: Multiply_Table = ---
		mul_tbl_set(&G_tbl, &GE_BASEPOINT, &tmp_add)
	} else {
		tmp_bp_addend: Basepoint_Addend_Group_Element = ---
	}

	sc_a, sc_b: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&sc_a, a)
	field.fe_from_montgomery(&sc_b, b)

	ge_identity(&tmp)
	for i := 31; i >= 0; i = i - 1 {
		limb := i / 8
		shift := uint(i & 7) * 8

		limb_byte_a := sc_a[limb] >> shift
		limb_byte_b := sc_b[limb] >> shift

		hi_a, lo_a := (limb_byte_a >> 4) & 0x0f, limb_byte_a & 0x0f
		hi_b, lo_b := (limb_byte_b >> 4) & 0x0f, limb_byte_b & 0x0f

		if i != 31 {
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
		}
		mul_tbl_add(&tmp, &A_tbl, hi_a, &tmp_add, &tmp_addend, true)
		when crypto.COMPACT_IMPLS == true {
			mul_tbl_add(&tmp, &G_tbl, hi_b, &tmp_add, &tmp_addend, true)
		} else {
			mul_bp_tbl_add(&tmp, GE_BASEPOINT_TABLE, hi_b, &tmp_add, &tmp_bp_addend, true)
		}

		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		mul_tbl_add(&tmp, &A_tbl, lo_a, &tmp_add, &tmp_addend, true)
		when crypto.COMPACT_IMPLS == true {
			mul_tbl_add(&tmp, &G_tbl, lo_b, &tmp_add, &tmp_addend, true)
		} else {
			mul_bp_tbl_add(&tmp, GE_BASEPOINT_TABLE, lo_b, &tmp_add, &tmp_bp_addend, true)
		}
	}

	ge_set(ge, &tmp)
}

ge_scalarmult_raw :: proc "contextless" (
	ge, p: ^Group_Element,
	sc: ^field.Non_Montgomery_Domain_Field_Element,
	unsafe_is_vartime := false,
) {
	// Do the simplest possible thing that works and provides adequate,
	// performance, which is windowed add-then-multiply.

	tmp_add: Add_Scratch = ---
	tmp_addend: Addend_Group_Element = ---
	tmp_dbl: Double_Scratch = ---
	tmp: Group_Element = ---

	p_tbl: Multiply_Table = ---
	mul_tbl_set(&p_tbl, p, &tmp_add)

	ge_identity(&tmp)
	for i := 31; i >= 0; i = i - 1 {
		limb := i / 8
		shift := uint(i & 7) * 8
		limb_byte := sc[limb] >> shift

		hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f

		if i != 31 {
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
			ge_double(&tmp, &tmp, &tmp_dbl)
		}
		mul_tbl_add(&tmp, &p_tbl, hi, &tmp_add, &tmp_addend, unsafe_is_vartime)

		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		ge_double(&tmp, &tmp, &tmp_dbl)
		mul_tbl_add(&tmp, &p_tbl, lo, &tmp_add, &tmp_addend, unsafe_is_vartime)
	}

	ge_set(ge, &tmp)

	if !unsafe_is_vartime {
		ge_clear(&tmp)
		mem.zero_explicit(&tmp_add, size_of(Add_Scratch))
		mem.zero_explicit(&tmp_addend, size_of(Addend_Group_Element))
		mem.zero_explicit(&tmp_dbl, size_of(Double_Scratch))
	}
}

@(private)
Multiply_Table :: [15]Addend_Group_Element // 0 = inf, which is implicit.

@(private)
mul_tbl_set :: proc "contextless" (
	tbl: ^Multiply_Table,
	ge: ^Group_Element,
	tmp_add: ^Add_Scratch,
) {
	tmp: Group_Element = ---
	ge_set(&tmp, ge)

	ge_addend_set(&tbl[0], ge)
	for i := 1; i < 15; i = i + 1 {
		ge_add_addend(&tmp, &tmp, &tbl[0], tmp_add)
		ge_addend_set(&tbl[i], &tmp)
	}

	ge_clear(&tmp)
}

@(private)
mul_tbl_add :: proc "contextless" (
	ge: ^Group_Element,
	tbl: ^Multiply_Table,
	idx: u64,
	tmp_add: ^Add_Scratch,
	tmp_addend: ^Addend_Group_Element,
	unsafe_is_vartime: bool,
) {
	// Variable time lookup, with the addition omitted entirely if idx == 0.
	if unsafe_is_vartime {
		// Skip adding the point at infinity.
		if idx != 0 {
			ge_add_addend(ge, ge, &tbl[idx - 1], tmp_add)
		}
		return
	}

	// Constant time lookup.
	tmp_addend^ = {
		// Point at infinity (0, 1, 1, 0) in precomputed form
		{1, 0, 0, 0, 0}, // y - x
		{1, 0, 0, 0, 0}, // y + x
		{0, 0, 0, 0, 0}, // t * 2d
		{2, 0, 0, 0, 0}, // z * 2
	}
	for i := u64(1); i < 16; i = i + 1 {
		ctrl := subtle.eq(i, idx)
		ge_addend_conditional_assign(tmp_addend, &tbl[i - 1], int(ctrl))
	}
	ge_add_addend(ge, ge, tmp_addend, tmp_add)
}
