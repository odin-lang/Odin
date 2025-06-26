/*
package x448 implements the X448 (aka curve448) Elliptic-Curve
Diffie-Hellman key exchange protocol.

See:
- [[ https://www.rfc-editor.org/rfc/rfc7748 ]]
*/
package x448

import field "core:crypto/_fiat/field_curve448"
import "core:mem"

// SCALAR_SIZE is the size of a X448 scalar (private key) in bytes.
SCALAR_SIZE :: 56
// POINT_SIZE is the size of a X448 point (public key/shared secret) in bytes.
POINT_SIZE :: 56

@(private, rodata)
_BASE_POINT: [56]byte = {
	5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}

@(private)
_scalar_bit :: #force_inline proc "contextless" (s: ^[56]byte, i: int) -> u8 {
	if i < 0 {
		return 0
	}
	return (s[i >> 3] >> uint(i & 7)) & 1
}

@(private)
_scalarmult :: proc "contextless" (out, scalar, point: ^[56]byte) {
	// Montgomery pseudo-multiplication, using the RFC 7748 formula.
	t1, t2: field.Loose_Field_Element = ---, ---

	// x_1 = u
	// x_2 = 1
	// z_2 = 0
	// x_3 = u
	// z_3 = 1
	x1: field.Tight_Field_Element = ---
	field.fe_from_bytes(&x1, point)

	x2, x3, z2, z3: field.Tight_Field_Element = ---, ---, ---, ---
	field.fe_one(&x2)
	field.fe_zero(&z2)
	field.fe_set(&x3, &x1)
	field.fe_one(&z3)

	// swap = 0
	swap: int

	// For t = bits-1 down to 0:a
	for t := 448 - 1; t >= 0; t -= 1 {
		// k_t = (k >> t) & 1
		k_t := int(_scalar_bit(scalar, t))
		// swap ^= k_t
		swap ~= k_t
		// Conditional swap; see text below.
		// (x_2, x_3) = cswap(swap, x_2, x_3)
		field.fe_cond_swap(&x2, &x3, swap)
		// (z_2, z_3) = cswap(swap, z_2, z_3)
		field.fe_cond_swap(&z2, &z3, swap)
		// swap = k_t
		swap = k_t

		// Note: This deliberately omits reductions after add/sub operations
		// if the result is only ever used as the input to a mul/square since
		// the implementations of those can deal with non-reduced inputs.
		//
		// fe_tighten_cast is only used to store a fully reduced
		// output in a Loose_Field_Element, or to provide such a
		// Loose_Field_Element as a Tight_Field_Element argument.

		// A = x_2 + z_2
		field.fe_add(&t1, &x2, &z2)
		// B = x_2 - z_2
		field.fe_sub(&t2, &x2, &z2)
		// D = x_3 - z_3
		field.fe_sub(field.fe_relax_cast(&z2), &x3, &z3) // (z2 unreduced)
		// DA = D * A
		field.fe_carry_mul(&x2, field.fe_relax_cast(&z2), &t1)
		// C = x_3 + z_3
		field.fe_add(field.fe_relax_cast(&z3), &x3, &z3) // (z3 unreduced)
		// CB = C * B
		field.fe_carry_mul(&x3, &t2, field.fe_relax_cast(&z3))
		// z_3 = x_1 * (DA - CB)^2
		field.fe_sub(field.fe_relax_cast(&z3), &x2, &x3) // (z3 unreduced)
		field.fe_carry_square(&z3, field.fe_relax_cast(&z3))
		field.fe_carry_mul(&z3, field.fe_relax_cast(&x1), field.fe_relax_cast(&z3))
		// x_3 = (DA + CB)^2
		field.fe_add(field.fe_relax_cast(&z2), &x2, &x3) // (z2 unreduced)
		field.fe_carry_square(&x3, field.fe_relax_cast(&z2))

		// AA = A^2
		field.fe_carry_square(&z2, &t1)
		// BB = B^2
		field.fe_carry_square(field.fe_tighten_cast(&t1), &t2) // (t1 reduced)
		// x_2 = AA * BB
		field.fe_carry_mul(&x2, field.fe_relax_cast(&z2), &t1)
		// E = AA - BB
		field.fe_sub(&t2, &z2, field.fe_tighten_cast(&t1)) // (t1 (input) is reduced)
		// z_2 = E * (AA + a24 * E)
		field.fe_carry_mul_small(field.fe_tighten_cast(&t1), &t2, 39081) // (t1 reduced)
		field.fe_add(&t1, &z2, field.fe_tighten_cast(&t1)) // (t1 (input) is reduced)
		field.fe_carry_mul(&z2, &t2, &t1)
	}

	// Conditional swap; see text below.
	// (x_2, x_3) = cswap(swap, x_2, x_3)
	field.fe_cond_swap(&x2, &x3, swap)
	// (z_2, z_3) = cswap(swap, z_2, z_3)
	field.fe_cond_swap(&z2, &z3, swap)

	// Return x_2 * (z_2^(p - 2))
	field.fe_carry_inv(&z2, field.fe_relax_cast(&z2))
	field.fe_carry_mul(&x2, field.fe_relax_cast(&x2), field.fe_relax_cast(&z2))
	field.fe_to_bytes(out, &x2)

	field.fe_clear_vec([]^field.Tight_Field_Element{&x1, &x2, &x3, &z2, &z3})
	field.fe_clear_vec([]^field.Loose_Field_Element{&t1, &t2})
}

// scalarmult "multiplies" the provided scalar and point, and writes the
// resulting point to dst.
scalarmult :: proc(dst, scalar, point: []byte) {
	ensure(len(scalar) == SCALAR_SIZE, "crypto/x448: invalid scalar size")
	ensure(len(point) == POINT_SIZE, "crypto/x448: invalid point size")
	ensure(len(dst) == POINT_SIZE, "crypto/x448: invalid destination point size")

	// "clamp" the scalar
	e: [56]byte = ---
	copy_slice(e[:], scalar)
	e[0] &= 252
	e[55] |= 128

	p: [56]byte = ---
	copy_slice(p[:], point)

	d: [56]byte = ---
	_scalarmult(&d, &e, &p)
	copy_slice(dst, d[:])

	mem.zero_explicit(&e, size_of(e))
	mem.zero_explicit(&d, size_of(d))
}

// scalarmult_basepoint "multiplies" the provided scalar with the X448
// base point and writes the resulting point to dst.
scalarmult_basepoint :: proc(dst, scalar: []byte) {
	scalarmult(dst, scalar, _BASE_POINT[:])
}
