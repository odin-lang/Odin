package _edwards25519

/*
This implements the edwards25519 composite-order group, primarily for
the purpose of implementing X25519, Ed25519, and ristretto255.  Use of
this package for other purposes is NOT RECOMMENDED.

See:
- https://eprint.iacr.org/2011/368.pdf
- https://datatracker.ietf.org/doc/html/rfc8032
- https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html
*/

import "core:crypto"
import field "core:crypto/_fiat/field_curve25519"
import "core:mem"

// Group_Element is an edwards25519 group element, as extended homogenous
// coordinates, which represents the affine point `(x, y)` as `(X, Y, Z, T)`,
// with the relations `x = X/Z`, `y = Y/Z`, and `x * y = T/Z`.
//
// d = -121665/121666 = 37095705934669439343138083508754565189542113879843219016388785533085940283555
// a = -1
//
// Notes:
// - There is considerable scope for optimization, however that
//   will not change the external API, and this is simple and reasonably
//   performant.
// - The API delibarately makes it hard to create arbitrary group
//   elements that are not on the curve.
// - The group element decoding routine takes the opinionated stance of
//   rejecting non-canonical encodings.

@(rodata)
FE_D := field.Tight_Field_Element {
	929955233495203,
	466365720129213,
	1662059464998953,
	2033849074728123,
	1442794654840575,
}
@(private, rodata)
FE_A := field.Tight_Field_Element {
	2251799813685228,
	2251799813685247,
	2251799813685247,
	2251799813685247,
	2251799813685247,
}
@(private, rodata)
FE_D2 := field.Tight_Field_Element {
	1859910466990425,
	932731440258426,
	1072319116312658,
	1815898335770999,
	633789495995903,
}
@(private, rodata)
GE_BASEPOINT := Group_Element {
	field.Tight_Field_Element {
		1738742601995546,
		1146398526822698,
		2070867633025821,
		562264141797630,
		587772402128613,
	},
	field.Tight_Field_Element {
		1801439850948184,
		1351079888211148,
		450359962737049,
		900719925474099,
		1801439850948198,
	},
	field.Tight_Field_Element{1, 0, 0, 0, 0},
	field.Tight_Field_Element {
		1841354044333475,
		16398895984059,
		755974180946558,
		900171276175154,
		1821297809914039,
	},
}
@(rodata)
GE_IDENTITY := Group_Element {
	field.Tight_Field_Element{0, 0, 0, 0, 0},
	field.Tight_Field_Element{1, 0, 0, 0, 0},
	field.Tight_Field_Element{1, 0, 0, 0, 0},
	field.Tight_Field_Element{0, 0, 0, 0, 0},
}

Group_Element :: struct {
	x: field.Tight_Field_Element,
	y: field.Tight_Field_Element,
	z: field.Tight_Field_Element,
	t: field.Tight_Field_Element,
}

ge_clear :: proc "contextless" (ge: ^Group_Element) {
	mem.zero_explicit(ge, size_of(Group_Element))
}

ge_set :: proc "contextless" (ge, a: ^Group_Element) {
	field.fe_set(&ge.x, &a.x)
	field.fe_set(&ge.y, &a.y)
	field.fe_set(&ge.z, &a.z)
	field.fe_set(&ge.t, &a.t)
}

@(require_results)
ge_set_bytes :: proc "contextless" (ge: ^Group_Element, b: []byte) -> bool {
	ensure_contextless(len(b) == 32, "edwards25519: invalid group element size")
	b_ := (^[32]byte)(raw_data(b))

	// Do the work in a scratch element, so that ge is unchanged on
	// failure.
	tmp: Group_Element = ---
	defer ge_clear(&tmp)
	field.fe_one(&tmp.z) // Z = 1

	// The encoding is the y-coordinate, with the x-coordinate polarity
	// (odd/even) encoded in the MSB.
	field.fe_from_bytes(&tmp.y, b_) // ignores high bit

	// Recover the candidate x-coordinate via the curve equation:
	// x^2 = (y^2 - 1) / (d * y^2 + 1) (mod p)

	fe_tmp := &tmp.t // Use this to store intermediaries.
	fe_one := &tmp.z

	// x = num = y^2 - 1
	field.fe_carry_square(fe_tmp, field.fe_relax_cast(&tmp.y)) // fe_tmp = y^2
	field.fe_carry_sub(&tmp.x, fe_tmp, fe_one)

	// den = d * y^2 + 1
	field.fe_carry_mul(fe_tmp, field.fe_relax_cast(fe_tmp), field.fe_relax_cast(&FE_D))
	field.fe_carry_add(fe_tmp, fe_tmp, fe_one)

	// x = invsqrt(den/num)
	is_square := field.fe_carry_sqrt_ratio_m1(
		&tmp.x,
		field.fe_relax_cast(&tmp.x),
		field.fe_relax_cast(fe_tmp),
	)
	if is_square == 0 {
		return false
	}

	// Pick the right x-coordinate.
	field.fe_cond_negate(&tmp.x, &tmp.x, int(b[31] >> 7))

	// t = x * y
	field.fe_carry_mul(&tmp.t, field.fe_relax_cast(&tmp.x), field.fe_relax_cast(&tmp.y))

	// Reject non-canonical encodings of ge.
	buf: [32]byte = ---
	field.fe_to_bytes(&buf, &tmp.y)
	buf[31] |= byte(field.fe_is_negative(&tmp.x)) << 7
	is_canonical := crypto.compare_constant_time(b, buf[:])

	ge_cond_assign(ge, &tmp, is_canonical)

	mem.zero_explicit(&buf, size_of(buf))

	return is_canonical == 1
}

ge_bytes :: proc "contextless" (ge: ^Group_Element, dst: []byte) {
	ensure_contextless(len(dst) == 32, "edwards25519: invalid group element size")
	dst_ := (^[32]byte)(raw_data(dst))

	// Convert the element to affine (x, y) representation.
	x, y, z_inv: field.Tight_Field_Element = ---, ---, ---
	field.fe_carry_inv(&z_inv, field.fe_relax_cast(&ge.z))
	field.fe_carry_mul(&x, field.fe_relax_cast(&ge.x), field.fe_relax_cast(&z_inv))
	field.fe_carry_mul(&y, field.fe_relax_cast(&ge.y), field.fe_relax_cast(&z_inv))

	// Encode the y-coordinate.
	field.fe_to_bytes(dst_, &y)

	// Copy the least significant bit of the x-coordinate to the most
	// significant bit of the encoded y-coordinate.
	dst_[31] |= byte((x[0] & 1) << 7)

	field.fe_clear_vec([]^field.Tight_Field_Element{&x, &y, &z_inv})
}

ge_identity :: proc "contextless" (ge: ^Group_Element) {
	field.fe_zero(&ge.x)
	field.fe_one(&ge.y)
	field.fe_one(&ge.z)
	field.fe_zero(&ge.t)
}

ge_generator :: proc "contextless" (ge: ^Group_Element) {
	ge_set(ge, &GE_BASEPOINT)
}

@(private)
Addend_Group_Element :: struct {
	y2_minus_x2:  field.Loose_Field_Element, // t1
	y2_plus_x2:   field.Loose_Field_Element, // t3
	k_times_t2:   field.Tight_Field_Element, // t4
	two_times_z2: field.Loose_Field_Element, // t5
}

@(private)
ge_addend_set :: proc "contextless" (ge_a: ^Addend_Group_Element, ge: ^Group_Element) {
	field.fe_sub(&ge_a.y2_minus_x2, &ge.y, &ge.x)
	field.fe_add(&ge_a.y2_plus_x2, &ge.y, &ge.x)
	field.fe_carry_mul(&ge_a.k_times_t2, field.fe_relax_cast(&FE_D2), field.fe_relax_cast(&ge.t))
	field.fe_add(&ge_a.two_times_z2, &ge.z, &ge.z)
}

@(private)
ge_addend_conditional_assign :: proc "contextless" (ge_a, a: ^Addend_Group_Element, ctrl: int) {
	field.fe_cond_select(&ge_a.y2_minus_x2, &ge_a.y2_minus_x2, &a.y2_minus_x2, ctrl)
	field.fe_cond_select(&ge_a.y2_plus_x2, &ge_a.y2_plus_x2, &a.y2_plus_x2, ctrl)
	field.fe_cond_select(&ge_a.k_times_t2, &ge_a.k_times_t2, &a.k_times_t2, ctrl)
	field.fe_cond_select(&ge_a.two_times_z2, &ge_a.two_times_z2, &a.two_times_z2, ctrl)
}

@(private)
Add_Scratch :: struct {
	A, B, C, D: field.Tight_Field_Element,
	E, F, G, H: field.Loose_Field_Element,
	t0, t2:     field.Loose_Field_Element,
}

ge_add :: proc "contextless" (ge, a, b: ^Group_Element) {
	b_: Addend_Group_Element = ---
	ge_addend_set(&b_, b)

	scratch: Add_Scratch = ---
	ge_add_addend(ge, a, &b_, &scratch)

	mem.zero_explicit(&b_, size_of(Addend_Group_Element))
	mem.zero_explicit(&scratch, size_of(Add_Scratch))
}

@(private)
ge_add_addend :: proc "contextless" (
	ge, a: ^Group_Element,
	b: ^Addend_Group_Element,
	scratch: ^Add_Scratch,
) {
	// https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#addition-add-2008-hwcd-3
	// Assumptions: k=2*d.
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
	t5 := &b.two_times_z2
	field.fe_carry_mul(D, field.fe_relax_cast(&a.z), t5)
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
Double_Scratch :: struct {
	A, B, C, D, G: field.Tight_Field_Element,
	t0, t2, t3:    field.Tight_Field_Element,
	E, F, H:       field.Loose_Field_Element,
	t1:            field.Loose_Field_Element,
}

ge_double :: proc "contextless" (ge, a: ^Group_Element, scratch: ^Double_Scratch = nil) {
	// https://www.hyperelliptic.org/EFD/g1p/auto-twisted-extended-1.html#doubling-dbl-2008-hwcd
	//
	// A = X1^2
	// B = Y1^2
	// t0 = Z1^2
	// C = 2*t0
	// D = a*A
	// t1 = X1+Y1
	// t2 = t1^2
	// t3 = t2-A
	// E = t3-B
	// G = D+B
	// F = G-C
	// H = D-B
	// X3 = E*F
	// Y3 = G*H
	// T3 = E*H
	// Z3 = F*G

	sanitize, scratch := scratch == nil, scratch
	if sanitize {
		tmp: Double_Scratch = ---
		scratch = &tmp
	}

	A, B, C, D, G := &scratch.A, &scratch.B, &scratch.C, &scratch.D, &scratch.G
	t0, t2, t3 := &scratch.t0, &scratch.t2, &scratch.t3
	E, F, H := &scratch.E, &scratch.F, &scratch.H
	t1 := &scratch.t1

	field.fe_carry_square(A, field.fe_relax_cast(&a.x))
	field.fe_carry_square(B, field.fe_relax_cast(&a.y))
	field.fe_carry_square(t0, field.fe_relax_cast(&a.z))
	field.fe_carry_add(C, t0, t0)
	field.fe_carry_mul(D, field.fe_relax_cast(&FE_A), field.fe_relax_cast(A))
	field.fe_add(t1, &a.x, &a.y)
	field.fe_carry_square(t2, t1)
	field.fe_carry_sub(t3, t2, A)
	field.fe_sub(E, t3, B)
	field.fe_carry_add(G, D, B)
	field.fe_sub(F, G, C)
	field.fe_sub(H, D, B)
	G_ := field.fe_relax_cast(G)
	field.fe_carry_mul(&ge.x, E, F)
	field.fe_carry_mul(&ge.y, G_, H)
	field.fe_carry_mul(&ge.t, E, H)
	field.fe_carry_mul(&ge.z, F, G_)

	if sanitize {
		mem.zero_explicit(scratch, size_of(Double_Scratch))
	}
}

ge_negate :: proc "contextless" (ge, a: ^Group_Element) {
	field.fe_carry_opp(&ge.x, &a.x)
	field.fe_set(&ge.y, &a.y)
	field.fe_set(&ge.z, &a.z)
	field.fe_carry_opp(&ge.t, &a.t)
}

ge_cond_negate :: proc "contextless" (ge, a: ^Group_Element, ctrl: int) {
	tmp: Group_Element = ---
	ge_negate(&tmp, a)
	ge_cond_assign(ge, &tmp, ctrl)

	ge_clear(&tmp)
}

ge_cond_assign :: proc "contextless" (ge, a: ^Group_Element, ctrl: int) {
	field.fe_cond_assign(&ge.x, &a.x, ctrl)
	field.fe_cond_assign(&ge.y, &a.y, ctrl)
	field.fe_cond_assign(&ge.z, &a.z, ctrl)
	field.fe_cond_assign(&ge.t, &a.t, ctrl)
}

ge_cond_select :: proc "contextless" (ge, a, b: ^Group_Element, ctrl: int) {
	field.fe_cond_select(&ge.x, &a.x, &b.x, ctrl)
	field.fe_cond_select(&ge.y, &a.y, &b.y, ctrl)
	field.fe_cond_select(&ge.z, &a.z, &b.z, ctrl)
	field.fe_cond_select(&ge.t, &a.t, &b.t, ctrl)
}

@(require_results)
ge_equal :: proc "contextless" (a, b: ^Group_Element) -> int {
	// (x, y) ?= (x', y') -> (X/Z, Y/Z) ?= (X'/Z', Y'/Z')
	// X/Z ?= X'/Z', Y/Z ?= Y'/Z' -> X*Z' ?= X'*Z, Y*Z' ?= Y'*Z
	ax_bz, bx_az, ay_bz, by_az: field.Tight_Field_Element = ---, ---, ---, ---
	field.fe_carry_mul(&ax_bz, field.fe_relax_cast(&a.x), field.fe_relax_cast(&b.z))
	field.fe_carry_mul(&bx_az, field.fe_relax_cast(&b.x), field.fe_relax_cast(&a.z))
	field.fe_carry_mul(&ay_bz, field.fe_relax_cast(&a.y), field.fe_relax_cast(&b.z))
	field.fe_carry_mul(&by_az, field.fe_relax_cast(&b.y), field.fe_relax_cast(&a.z))

	ret := field.fe_equal(&ax_bz, &bx_az) & field.fe_equal(&ay_bz, &by_az)

	field.fe_clear_vec([]^field.Tight_Field_Element{&ax_bz, &ay_bz, &bx_az, &by_az})

	return ret
}

@(require_results)
ge_is_small_order :: proc "contextless" (ge: ^Group_Element) -> bool {
	tmp: Group_Element = ---
	ge_double(&tmp, ge)
	ge_double(&tmp, &tmp)
	ge_double(&tmp, &tmp)
	return ge_equal(&tmp, &GE_IDENTITY) == 1
}

@(require_results)
ge_in_prime_order_subgroup_vartime :: proc "contextless" (ge: ^Group_Element) -> bool {
	// This is currently *very* expensive.  The faster method would be
	// something like (https://eprint.iacr.org/2022/1164.pdf), however
	// that is a ~50% speedup, and a lot of added complexity for something
	// that is better solved by "just use ristretto255".
	tmp: Group_Element = ---
	_ge_scalarmult(&tmp, ge, &SC_ELL, true)
	return ge_equal(&tmp, &GE_IDENTITY) == 1
}
