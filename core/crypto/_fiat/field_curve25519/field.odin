package field_curve25519

import "core:crypto"
import "core:mem"

fe_relax_cast :: #force_inline proc "contextless" (arg1: ^Tight_Field_Element) -> ^Loose_Field_Element {
	return transmute(^Loose_Field_Element)(arg1)
}

fe_tighten_cast :: #force_inline proc "contextless" (arg1: ^Loose_Field_Element) -> ^Tight_Field_Element {
	return transmute(^Tight_Field_Element)(arg1)
}

fe_from_bytes :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^[32]byte) {
	// Ignore the unused bit by copying the input and masking the bit off
	// prior to deserialization.
	tmp1: [32]byte = ---
	copy_slice(tmp1[:], arg1[:])
	tmp1[31] &= 127

	_fe_from_bytes(out1, &tmp1)

	mem.zero_explicit(&tmp1, size_of(tmp1))
}

fe_equal :: proc "contextless" (arg1, arg2: ^Tight_Field_Element) -> int {
	tmp2: [32]byte = ---

	fe_to_bytes(&tmp2, arg2)
	ret := fe_equal_bytes(arg1, &tmp2)

	mem.zero_explicit(&tmp2, size_of(tmp2))

	return ret
}

fe_equal_bytes :: proc "contextless" (arg1: ^Tight_Field_Element, arg2: ^[32]byte) -> int {
	tmp1: [32]byte = ---

	fe_to_bytes(&tmp1, arg1)

	ret := crypto.compare_constant_time(tmp1[:], arg2[:])

	mem.zero_explicit(&tmp1, size_of(tmp1))

	return ret
}

fe_carry_pow2k :: proc (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element, arg2: uint) {
	// Special case: `arg1^(2 * 0) = 1`, though this should never happen.
	if arg2 == 0 {
		fe_one(out1)
		return
	}

	fe_carry_square(out1, arg1)
	for _ in 1..<arg2 {
		fe_carry_square(out1, fe_relax_cast(out1))
	}
}

fe_carry_opp :: #force_inline proc "contextless" (out1, arg1: ^Tight_Field_Element) {
	fe_opp(fe_relax_cast(out1), arg1)
	fe_carry(out1, fe_relax_cast(out1))
}

fe_carry_invsqrt :: proc (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) -> int {
	// Inverse square root taken from Monocypher.

	tmp1, tmp2, tmp3: Tight_Field_Element = ---, ---, ---

	// t0 = x^((p-5)/8)
	// Can be achieved with a simple double & add ladder,
	// but it would be slower.
	fe_carry_pow2k(&tmp1, arg1, 1)
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp1), 2)
	fe_carry_mul(&tmp2, arg1, fe_relax_cast(&tmp2))
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp1), fe_relax_cast(&tmp2))
	fe_carry_pow2k(&tmp1, fe_relax_cast(&tmp1), 1)
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp1), 5)
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp1), 10)
	fe_carry_mul(&tmp2, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp3, fe_relax_cast(&tmp2), 20)
	fe_carry_mul(&tmp2, fe_relax_cast(&tmp3), fe_relax_cast(&tmp2))
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp2), 10)
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp1), 50)
	fe_carry_mul(&tmp2, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp3, fe_relax_cast(&tmp2), 100)
	fe_carry_mul(&tmp2, fe_relax_cast(&tmp3), fe_relax_cast(&tmp2))
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp2), 50)
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp2), fe_relax_cast(&tmp1))
	fe_carry_pow2k(&tmp1, fe_relax_cast(&tmp1), 2)
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp1), arg1)

	// quartic = x^((p-1)/4)
	quartic := &tmp2
	fe_carry_square(quartic, fe_relax_cast(&tmp1))
	fe_carry_mul(quartic, fe_relax_cast(quartic), arg1)

	// Serialize quartic once to save on repeated serialization/sanitization.
	quartic_buf: [32]byte = ---
	fe_to_bytes(&quartic_buf, quartic)
	check := &tmp3

	fe_one(check)
	p1 := fe_equal_bytes(check, &quartic_buf)
	fe_carry_opp(check, check)
	m1 := fe_equal_bytes(check, &quartic_buf)
	fe_carry_opp(check, &SQRT_M1)
	ms := fe_equal_bytes(check, &quartic_buf)

	// if quartic == -1 or sqrt(-1)
	// then  isr = x^((p-1)/4) * sqrt(-1)
	// else  isr = x^((p-1)/4)
	fe_carry_mul(out1, fe_relax_cast(&tmp1), fe_relax_cast(&SQRT_M1))
	fe_cond_assign(out1, &tmp1, (m1|ms) ~ 1)

	mem.zero_explicit(&tmp1, size_of(tmp1))
	mem.zero_explicit(&tmp2, size_of(tmp2))
	mem.zero_explicit(&tmp3, size_of(tmp3))
	mem.zero_explicit(&quartic_buf, size_of(quartic_buf))

	return p1 | m1
}

fe_carry_inv :: proc (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	tmp1: Tight_Field_Element

	fe_carry_square(&tmp1, arg1)
	_ = fe_carry_invsqrt(&tmp1, fe_relax_cast(&tmp1))
	fe_carry_square(&tmp1, fe_relax_cast(&tmp1))
	fe_carry_mul(out1, fe_relax_cast(&tmp1), arg1)

	mem.zero_explicit(&tmp1, size_of(tmp1))
}
