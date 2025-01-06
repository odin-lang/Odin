/*
package x25519 implements the X25519 (aka curve25519) Elliptic-Curve
Diffie-Hellman key exchange protocol.

See:
- [[ https://www.rfc-editor.org/rfc/rfc7748 ]]
*/
package x25519

import field "core:crypto/_fiat/field_curve25519"
import "core:mem"

// SCALAR_SIZE is the size of a X25519 scalar (private key) in bytes.
SCALAR_SIZE :: 32
// POINT_SIZE is the size of a X25519 point (public key/shared secret) in bytes.
POINT_SIZE :: 32

@(private)
_BASE_POINT: [32]byte = {9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

@(private)
_scalar_bit :: #force_inline proc "contextless" (s: ^[32]byte, i: int) -> u8 {
	if i < 0 {
		return 0
	}
	return (s[i >> 3] >> uint(i & 7)) & 1
}

@(private)
_scalarmult :: proc "contextless" (out, scalar, point: ^[32]byte) {
	// Montgomery pseduo-multiplication taken from Monocypher.

	// computes the scalar product
	x1: field.Tight_Field_Element = ---
	field.fe_from_bytes(&x1, point)

	// computes the actual scalar product (the result is in x2 and z2)
	x2, x3, z2, z3: field.Tight_Field_Element = ---, ---, ---, ---
	t0, t1: field.Loose_Field_Element = ---, ---

	// Montgomery ladder
	// In projective coordinates, to avoid divisions: x = X / Z
	// We don't care about the y coordinate, it's only 1 bit of information
	field.fe_one(&x2) // "zero" point
	field.fe_zero(&z2)
	field.fe_set(&x3, &x1) // "one" point
	field.fe_one(&z3)

	swap: int
	for pos := 255 - 1; pos >= 0; pos = pos - 1 {
		// constant time conditional swap before ladder step
		b := int(_scalar_bit(scalar, pos))
		swap ~= b // xor trick avoids swapping at the end of the loop
		field.fe_cond_swap(&x2, &x3, swap)
		field.fe_cond_swap(&z2, &z3, swap)
		swap = b // anticipates one last swap after the loop

		// Montgomery ladder step: replaces (P2, P3) by (P2*2, P2+P3)
		// with differential addition
		//
		// Note: This deliberately omits reductions after add/sub operations
		// if the result is only ever used as the input to a mul/square since
		// the implementations of those can deal with non-reduced inputs.
		//
		// fe_tighten_cast is only used to store a fully reduced
		// output in a Loose_Field_Element, or to provide such a
		// Loose_Field_Element as a Tight_Field_Element argument.
		field.fe_sub(&t0, &x3, &z3)
		field.fe_sub(&t1, &x2, &z2)
		field.fe_add(field.fe_relax_cast(&x2), &x2, &z2) // x2 - unreduced
		field.fe_add(field.fe_relax_cast(&z2), &x3, &z3) // z2 - unreduced
		field.fe_carry_mul(&z3, &t0, field.fe_relax_cast(&x2))
		field.fe_carry_mul(&z2, field.fe_relax_cast(&z2), &t1) // z2 - reduced
		field.fe_carry_square(field.fe_tighten_cast(&t0), &t1) // t0 - reduced
		field.fe_carry_square(field.fe_tighten_cast(&t1), field.fe_relax_cast(&x2)) // t1 - reduced
		field.fe_add(field.fe_relax_cast(&x3), &z3, &z2) // x3 - unreduced
		field.fe_sub(field.fe_relax_cast(&z2), &z3, &z2) // z2 - unreduced
		field.fe_carry_mul(&x2, &t1, &t0) // x2 - reduced
		field.fe_sub(&t1, field.fe_tighten_cast(&t1), field.fe_tighten_cast(&t0)) // safe - t1/t0 is reduced
		field.fe_carry_square(&z2, field.fe_relax_cast(&z2)) // z2 - reduced
		field.fe_carry_scmul_121666(&z3, &t1)
		field.fe_carry_square(&x3, field.fe_relax_cast(&x3)) // x3 - reduced
		field.fe_add(&t0, field.fe_tighten_cast(&t0), &z3) // safe - t0 is reduced
		field.fe_carry_mul(&z3, field.fe_relax_cast(&x1), field.fe_relax_cast(&z2))
		field.fe_carry_mul(&z2, &t1, &t0)
	}
	// last swap is necessary to compensate for the xor trick
	// Note: after this swap, P3 == P2 + P1.
	field.fe_cond_swap(&x2, &x3, swap)
	field.fe_cond_swap(&z2, &z3, swap)

	// normalises the coordinates: x == X / Z
	field.fe_carry_inv(&z2, field.fe_relax_cast(&z2))
	field.fe_carry_mul(&x2, field.fe_relax_cast(&x2), field.fe_relax_cast(&z2))
	field.fe_to_bytes(out, &x2)

	field.fe_clear_vec([]^field.Tight_Field_Element{&x1, &x2, &x3, &z2, &z3})
	field.fe_clear_vec([]^field.Loose_Field_Element{&t0, &t1})
}

// scalarmult "multiplies" the provided scalar and point, and writes the
// resulting point to dst.
scalarmult :: proc(dst, scalar, point: []byte) {
	if len(scalar) != SCALAR_SIZE {
		panic("crypto/x25519: invalid scalar size")
	}
	if len(point) != POINT_SIZE {
		panic("crypto/x25519: invalid point size")
	}
	if len(dst) != POINT_SIZE {
		panic("crypto/x25519: invalid destination point size")
	}

	// "clamp" the scalar
	e: [32]byte = ---
	copy_slice(e[:], scalar)
	e[0] &= 248
	e[31] &= 127
	e[31] |= 64

	p: [32]byte = ---
	copy_slice(p[:], point)

	d: [32]byte = ---
	_scalarmult(&d, &e, &p)
	copy_slice(dst, d[:])

	mem.zero_explicit(&e, size_of(e))
	mem.zero_explicit(&d, size_of(d))
}

// scalarmult_basepoint "multiplies" the provided scalar with the X25519
// base point and writes the resulting point to dst.
scalarmult_basepoint :: proc(dst, scalar: []byte) {
	scalarmult(dst, scalar, _BASE_POINT[:])
}
