package _edwards25519

import field "core:crypto/_fiat/field_scalar25519"
import "core:mem"

ge_scalarmult :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	_ge_scalarmult(ge, p, &tmp)

	mem.zero_explicit(&tmp, size_of(tmp))
}

ge_scalarmult_basepoint :: proc "contextless" (ge: ^Group_Element, sc: ^Scalar) {
	// TODO: Constant time pre-computed table.
	ge_scalarmult(ge, &GE_BASE_POINT, sc)
}

ge_scalarmult_vartime :: proc "contextless" (ge, p: ^Group_Element, sc: ^Scalar) {
	tmp: field.Non_Montgomery_Domain_Field_Element
	field.fe_from_montgomery(&tmp, sc)

	_ge_scalarmult(ge, p, &tmp, true)
}

ge_double_scalarmult_basepoint_vartime :: proc "contextless" (
	ge: ^Group_Element,
	a: ^Scalar,
	A: ^Group_Element,
	b: ^Scalar,
) {
	// TODO: Variable time Shamir-Strauss
	// Notes:
	// - ABGLSV-Pornin (https://eprint.iacr.org/2020/454) is the fastest
	//   known method for this, but it is rather complicated relative
	//   to Shamir-Strauss.
	tmp: Group_Element = ---
	ge_scalarmult_vartime(&tmp, A, a)
	ge_scalarmult_basepoint(ge, b)
	ge_add(ge, &tmp, ge)
}

@(private)
_ge_scalarmult :: proc "contextless" (
	ge, p: ^Group_Element,
	sc: ^field.Non_Montgomery_Domain_Field_Element,
	unsafe_is_vartime := false,
) {
	// Do the simplest possible thing that works for now, which is
	// add-then-multiply.
	//
	// Notes:
	// - This needs to handle non-canonically encoded scalars so that
	//   it is possible to check prime-order group membership.
	// - (TODO) This will eventually be at least a 4-bit window, because
	//   that is consistent with how I will do the NIST curves, and it
	//   is easy to understand.
	// - w-NAF is faster, but the added complication is not worth it.
	q, addend: Group_Element = ---, ---
	ge_identity(&q)

	for i := 0; i < 255; i = i + 1 {
		limb := i / 64
		shift := uint(i & 0x3f)
		bit := (sc[limb] >> shift) & 1

		switch unsafe_is_vartime {
		case false:
			ge_cond_select(&addend, &GE_IDENTITY, p, int(bit))
			ge_add(&q, &q, &addend)
		case true:
			if bit != 0 {
				ge_add(&q, &q, p)
			}
		}

		if i != 0 {
			ge_double(&q, &q)
		}
	}

	ge_set(ge, &q)

	if !unsafe_is_vartime {
		ge_clear(&addend)
		ge_clear(&q)
	}
}
