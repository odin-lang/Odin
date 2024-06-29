package field_curve25519

import "core:crypto"
import "core:mem"

fe_relax_cast :: #force_inline proc "contextless" (
	arg1: ^Tight_Field_Element,
) -> ^Loose_Field_Element {
	return (^Loose_Field_Element)(arg1)
}

fe_tighten_cast :: #force_inline proc "contextless" (
	arg1: ^Loose_Field_Element,
) -> ^Tight_Field_Element {
	return (^Tight_Field_Element)(arg1)
}

fe_clear :: proc "contextless" (
	arg1: $T,
) where T == ^Tight_Field_Element || T == ^Loose_Field_Element {
	mem.zero_explicit(arg1, size_of(arg1^))
}

fe_clear_vec :: proc "contextless" (
	arg1: $T,
) where T == []^Tight_Field_Element || T == []^Loose_Field_Element {
	for fe in arg1 {
		fe_clear(fe)
	}
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

fe_is_negative :: proc "contextless" (arg1: ^Tight_Field_Element) -> int {
	tmp1: [32]byte = ---

	fe_to_bytes(&tmp1, arg1)
	ret := tmp1[0] & 1

	mem.zero_explicit(&tmp1, size_of(tmp1))

	return int(ret)
}

fe_equal :: proc "contextless" (arg1, arg2: ^Tight_Field_Element) -> int {
	tmp1, tmp2: [32]byte = ---, ---

	fe_to_bytes(&tmp1, arg1)
	fe_to_bytes(&tmp2, arg2)
	ret := crypto.compare_constant_time(tmp1[:], tmp2[:])

	mem.zero_explicit(&tmp1, size_of(tmp1))
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

fe_carry_pow2k :: proc "contextless" (
	out1: ^Tight_Field_Element,
	arg1: ^Loose_Field_Element,
	arg2: uint,
) {
	// Special case: `arg1^(2 * 0) = 1`, though this should never happen.
	if arg2 == 0 {
		fe_one(out1)
		return
	}

	fe_carry_square(out1, arg1)
	for _ in 1 ..< arg2 {
		fe_carry_square(out1, fe_relax_cast(out1))
	}
}

fe_carry_add :: #force_inline proc "contextless" (out1, arg1, arg2: ^Tight_Field_Element) {
	fe_add(fe_relax_cast(out1), arg1, arg2)
	fe_carry(out1, fe_relax_cast(out1))
}

fe_carry_sub :: #force_inline proc "contextless" (out1, arg1, arg2: ^Tight_Field_Element) {
	fe_sub(fe_relax_cast(out1), arg1, arg2)
	fe_carry(out1, fe_relax_cast(out1))
}

fe_carry_opp :: #force_inline proc "contextless" (out1, arg1: ^Tight_Field_Element) {
	fe_opp(fe_relax_cast(out1), arg1)
	fe_carry(out1, fe_relax_cast(out1))
}

fe_carry_abs :: #force_inline proc "contextless" (out1, arg1: ^Tight_Field_Element) {
	fe_cond_negate(out1, arg1, fe_is_negative(arg1))
}

fe_carry_sqrt_ratio_m1 :: proc "contextless" (
	out1: ^Tight_Field_Element,
	arg1: ^Loose_Field_Element, // u
	arg2: ^Loose_Field_Element, // v
) -> int {
	// SQRT_RATIO_M1(u, v) from RFC 9496 - 4.2, based on the inverse
	// square root from Monocypher.

	w: Tight_Field_Element = ---
	fe_carry_mul(&w, arg1, arg2) // u * v

	// r = tmp1 = u * w^((p-5)/8)
	tmp1, tmp2, tmp3: Tight_Field_Element = ---, ---, ---
	fe_carry_pow2k(&tmp1, fe_relax_cast(&w), 1)
	fe_carry_pow2k(&tmp2, fe_relax_cast(&tmp1), 2)
	fe_carry_mul(&tmp2, fe_relax_cast(&w), fe_relax_cast(&tmp2))
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
	fe_carry_mul(&tmp1, fe_relax_cast(&tmp1), fe_relax_cast(&w)) // w^((p-5)/8)

	fe_carry_mul(&tmp1, fe_relax_cast(&tmp1), arg1) // u * w^((p-5)/8)

	// Serialize `check` once to save on repeated serialization.
	r, check := &tmp1, &tmp2
	b: [32]byte = ---
	fe_carry_square(check, fe_relax_cast(r))
	fe_carry_mul(check, fe_relax_cast(check), arg2) // check * v
	fe_to_bytes(&b, check)

	u, neg_u, neg_u_i := &tmp3, &w, check
	fe_carry(u, arg1)
	fe_carry_opp(neg_u, u)
	fe_carry_mul(neg_u_i, fe_relax_cast(neg_u), fe_relax_cast(&FE_SQRT_M1))

	correct_sign_sqrt := fe_equal_bytes(u, &b)
	flipped_sign_sqrt := fe_equal_bytes(neg_u, &b)
	flipped_sign_sqrt_i := fe_equal_bytes(neg_u_i, &b)

	r_prime := check
	fe_carry_mul(r_prime, fe_relax_cast(r), fe_relax_cast(&FE_SQRT_M1))
	fe_cond_assign(r, r_prime, flipped_sign_sqrt | flipped_sign_sqrt_i)

	// Pick the non-negative square root.
	fe_carry_abs(out1, r)

	fe_clear_vec([]^Tight_Field_Element{&w, &tmp1, &tmp2, &tmp3})
	mem.zero_explicit(&b, size_of(b))

	return correct_sign_sqrt | flipped_sign_sqrt
}

fe_carry_inv :: proc "contextless" (out1: ^Tight_Field_Element, arg1: ^Loose_Field_Element) {
	tmp1: Tight_Field_Element

	fe_carry_square(&tmp1, arg1)
	_ = fe_carry_sqrt_ratio_m1(&tmp1, fe_relax_cast(&FE_ONE), fe_relax_cast(&tmp1))
	fe_carry_square(&tmp1, fe_relax_cast(&tmp1))
	fe_carry_mul(out1, fe_relax_cast(&tmp1), arg1)

	fe_clear(&tmp1)
}

fe_zero :: proc "contextless" (out1: ^Tight_Field_Element) {
	out1[0] = 0
	out1[1] = 0
	out1[2] = 0
	out1[3] = 0
	out1[4] = 0
}

fe_one :: proc "contextless" (out1: ^Tight_Field_Element) {
	out1[0] = 1
	out1[1] = 0
	out1[2] = 0
	out1[3] = 0
	out1[4] = 0
}

fe_set :: proc "contextless" (out1, arg1: ^Tight_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	x4 := arg1[3]
	x5 := arg1[4]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

@(optimization_mode = "none")
fe_cond_swap :: #force_no_inline proc "contextless" (out1, out2: ^Tight_Field_Element, arg1: int) {
	mask := (u64(arg1) * 0xffffffffffffffff)
	x := (out1[0] ~ out2[0]) & mask
	x1, y1 := out1[0] ~ x, out2[0] ~ x
	x = (out1[1] ~ out2[1]) & mask
	x2, y2 := out1[1] ~ x, out2[1] ~ x
	x = (out1[2] ~ out2[2]) & mask
	x3, y3 := out1[2] ~ x, out2[2] ~ x
	x = (out1[3] ~ out2[3]) & mask
	x4, y4 := out1[3] ~ x, out2[3] ~ x
	x = (out1[4] ~ out2[4]) & mask
	x5, y5 := out1[4] ~ x, out2[4] ~ x
	out1[0], out2[0] = x1, y1
	out1[1], out2[1] = x2, y2
	out1[2], out2[2] = x3, y3
	out1[3], out2[3] = x4, y4
	out1[4], out2[4] = x5, y5
}

@(optimization_mode = "none")
fe_cond_select :: #force_no_inline proc "contextless" (
	out1, arg1, arg2: $T,
	arg3: int,
) where T == ^Tight_Field_Element || T == ^Loose_Field_Element {
	mask := (u64(arg3) * 0xffffffffffffffff)
	x1 := ((mask & arg2[0]) | ((~mask) & arg1[0]))
	x2 := ((mask & arg2[1]) | ((~mask) & arg1[1]))
	x3 := ((mask & arg2[2]) | ((~mask) & arg1[2]))
	x4 := ((mask & arg2[3]) | ((~mask) & arg1[3]))
	x5 := ((mask & arg2[4]) | ((~mask) & arg1[4]))
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
}

fe_cond_negate :: proc "contextless" (out1, arg1: ^Tight_Field_Element, ctrl: int) {
	tmp1: Tight_Field_Element = ---
	fe_carry_opp(&tmp1, arg1)
	fe_cond_select(out1, arg1, &tmp1, ctrl)

	fe_clear(&tmp1)
}
