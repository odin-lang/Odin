package _edwards25519

import "core:crypto"
import field "core:crypto/_fiat/field_curve25519"
import scalar "core:crypto/_fiat/field_scalar25519"
import subtle "core:crypto/_subtle"
import "core:mem"

ge_scalarmult_basepoint :: proc "contextless" (ge: ^Group_Element, sc: ^Scalar) {
	when crypto.COMPACT_IMPLS == true {
		ge_scalarmult(ge, &GE_BASEPOINT, sc)
	} else {
		tmp_sc: scalar.Non_Montgomery_Domain_Field_Element
		scalar.fe_from_montgomery(&tmp_sc, sc)

		tmp_add: Add_Scratch = ---
		tmp_addend: Basepoint_Addend_Group_Element = ---

		ge_identity(ge)
		for i in 0..<32 {
			limb := i / 8
			shift := uint(i & 7) * 8
			limb_byte := tmp_sc[limb] >> shift

			hi, lo := (limb_byte >> 4) & 0x0f, limb_byte & 0x0f
			mul_bp_tbl_add(ge, &Gen_Multiply_Table_edwards25519_lo[i], lo, &tmp_add, &tmp_addend, false)
			mul_bp_tbl_add(ge, &Gen_Multiply_Table_edwards25519_hi[i], hi, &tmp_add, &tmp_addend, false)
		}

		mem.zero_explicit(&tmp_sc, size_of(tmp_sc))
		mem.zero_explicit(&tmp_add, size_of(Add_Scratch))
		mem.zero_explicit(&tmp_addend, size_of(Basepoint_Addend_Group_Element))
	}
}

when crypto.COMPACT_IMPLS == false {
	@(private="file",rodata)
	TWO_TIMES_Z2 := field.Loose_Field_Element{2, 0, 0, 0, 0}

	@(private)
	Basepoint_Addend_Group_Element :: struct {
		y2_minus_x2:  field.Loose_Field_Element, // t1
		y2_plus_x2:   field.Loose_Field_Element, // t3
		k_times_t2:   field.Tight_Field_Element, // t4
	}

	@(private)
	Basepoint_Multiply_Table :: [15]Basepoint_Addend_Group_Element

	@(private)
	ge_bp_addend_conditional_assign :: proc "contextless" (ge_a, a: ^Basepoint_Addend_Group_Element, ctrl: int) {
		field.fe_cond_select(&ge_a.y2_minus_x2, &ge_a.y2_minus_x2, &a.y2_minus_x2, ctrl)
		field.fe_cond_select(&ge_a.y2_plus_x2, &ge_a.y2_plus_x2, &a.y2_plus_x2, ctrl)
		field.fe_cond_select(&ge_a.k_times_t2, &ge_a.k_times_t2, &a.k_times_t2, ctrl)
	}

	@(private)
	ge_add_bp_addend :: proc "contextless" (
		ge, a: ^Group_Element,
		b: ^Basepoint_Addend_Group_Element,
		scratch: ^Add_Scratch,
	) {
		// https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#addition-add-2008-hwcd-3
		// Assumptions: k=2*d, z = 1 (precomputation ftw)
		//
		// t0 = Y1-X1
		// t1 = Y2-X2
		// A = t0*t1
		// t2 = Y1+X1
		// t3 = Y2+X2
		// B = t2*t3
		// t4 = k*T2
		// C = T1*t4
		// t5 = 2*Z2
		// D = Z1*t5
		// E = B-A
		// F = D-C
		// G = D+C
		// H = B+A
		// X3 = E*F
		// Y3 = G*H
		// T3 = E*H
		// Z3 = F*G
		//
		// In order to make the scalar multiply faster, the addend is provided
		// as a `Addend_Group_Element` with t1, t3, t4, and t5 precomputed, as
		// it is trivially obvious that those are the only values used by the
		// formula that are directly dependent on `b`, and are only dependent
		// on `b` and constants.  This saves 1 sub, 2 adds, and 1 multiply,
		// each time the intermediate representation can be reused.

		A, B, C, D := &scratch.A, &scratch.B, &scratch.C, &scratch.D
		E, F, G, H := &scratch.E, &scratch.F, &scratch.G, &scratch.H
		t0, t2 := &scratch.t0, &scratch.t2

		field.fe_sub(t0, &a.y, &a.x)
		t1 := &b.y2_minus_x2
		field.fe_carry_mul(A, t0, t1)
		field.fe_add(t2, &a.y, &a.x)
		t3 := &b.y2_plus_x2
		field.fe_carry_mul(B, t2, t3)
		t4 := &b.k_times_t2
		field.fe_carry_mul(C, field.fe_relax_cast(&a.t), field.fe_relax_cast(t4))
		field.fe_carry_mul(D, field.fe_relax_cast(&a.z), &TWO_TIMES_Z2)
		field.fe_sub(E, B, A)
		field.fe_sub(F, D, C)
		field.fe_add(G, D, C)
		field.fe_add(H, B, A)
		field.fe_carry_mul(&ge.x, E, F)
		field.fe_carry_mul(&ge.y, G, H)
		field.fe_carry_mul(&ge.t, E, H)
		field.fe_carry_mul(&ge.z, F, G)
	}

	@(private)
	mul_bp_tbl_add :: proc "contextless" (
		ge: ^Group_Element,
		tbl: ^Basepoint_Multiply_Table,
		idx: u64,
		tmp_add: ^Add_Scratch,
		tmp_addend: ^Basepoint_Addend_Group_Element,
		unsafe_is_vartime: bool,
	) {
		// Variable time lookup, with the addition omitted entirely if idx == 0.
		if unsafe_is_vartime {
			// Skip adding the point at infinity.
			if idx != 0 {
				ge_add_bp_addend(ge, ge, &tbl[idx-1], tmp_add)
			}
			return
		}

		// Constant time lookup.
		tmp_addend^ = {
			// Point at infinity (0, 1, 1, 0) in precomputed form, note
			// that the precomputed tables rescale so that `Z = 1`.
			{1, 0, 0, 0, 0}, // y - x
			{1, 0, 0, 0, 0}, // y + x
			{0, 0, 0, 0, 0}, // t * 2d
		}
		for i := u64(1); i < 16; i = i + 1 {
			ctrl := subtle.eq(i, idx)
			ge_bp_addend_conditional_assign(tmp_addend, &tbl[i - 1], int(ctrl))
		}
		ge_add_bp_addend(ge, ge, tmp_addend, tmp_add)
	}
}
