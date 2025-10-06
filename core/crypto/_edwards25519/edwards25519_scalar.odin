package _edwards25519

import field "core:crypto/_fiat/field_scalar25519"
import "core:mem"

Scalar :: field.Montgomery_Domain_Field_Element

// WARNING: This is non-canonical and only to be used when checking if
// a group element is on the prime-order subgroup.
@(private, rodata)
SC_ELL := field.Non_Montgomery_Domain_Field_Element {
	field.ELL[0],
	field.ELL[1],
	field.ELL[2],
	field.ELL[3],
}

sc_set_u64 :: proc "contextless" (sc: ^Scalar, i: u64) {
	tmp := field.Non_Montgomery_Domain_Field_Element{i, 0, 0, 0}
	field.fe_to_montgomery(sc, &tmp)

	mem.zero_explicit(&tmp, size_of(tmp))
}

@(require_results)
sc_set_bytes :: proc "contextless" (sc: ^Scalar, b: []byte) -> bool {
	ensure_contextless(len(b) == 32, "edwards25519: invalid scalar size")
	b_ := (^[32]byte)(raw_data(b))
	return field.fe_from_bytes(sc, b_)
}

sc_set_bytes_rfc8032 :: proc "contextless" (sc: ^Scalar, b: []byte) {
	ensure_contextless(len(b) == 32, "edwards25519: invalid scalar size")
	b_ := (^[32]byte)(raw_data(b))
	field.fe_from_bytes_rfc8032(sc, b_)
}

sc_clear :: proc "contextless" (sc: ^Scalar) {
	mem.zero_explicit(sc, size_of(Scalar))
}

sc_set :: field.fe_set
sc_set_bytes_wide :: field.fe_from_bytes_wide
sc_bytes :: field.fe_to_bytes

sc_zero :: field.fe_zero
sc_one :: field.fe_one

sc_add :: field.fe_add
sc_sub :: field.fe_sub
sc_negate :: field.fe_opp
sc_mul :: field.fe_mul
sc_square :: field.fe_square

sc_cond_assign :: field.fe_cond_assign
sc_equal :: field.fe_equal
