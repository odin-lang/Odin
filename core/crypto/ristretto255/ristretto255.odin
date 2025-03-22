/*
package ristretto255 implement the ristretto255 prime-order group.

See:
- [[ https://www.rfc-editor.org/rfc/rfc9496 ]]
*/
package ristretto255

import grp "core:crypto/_edwards25519"
import field "core:crypto/_fiat/field_curve25519"
import "core:mem"

// ELEMENT_SIZE is the size of a byte-encoded ristretto255 group element.
ELEMENT_SIZE :: 32
// WIDE_ELEMENT_SIZE is the side of a wide byte-encoded ristretto255
// group element.
WIDE_ELEMENT_SIZE :: 64

@(private, rodata)
FE_NEG_ONE := field.Tight_Field_Element {
	2251799813685228,
	2251799813685247,
	2251799813685247,
	2251799813685247,
	2251799813685247,
}
@(private, rodata)
FE_INVSQRT_A_MINUS_D := field.Tight_Field_Element {
	278908739862762,
	821645201101625,
	8113234426968,
	1777959178193151,
	2118520810568447,
}
@(private, rodata)
FE_ONE_MINUS_D_SQ := field.Tight_Field_Element {
	1136626929484150,
	1998550399581263,
	496427632559748,
	118527312129759,
	45110755273534,
}
@(private, rodata)
FE_D_MINUS_ONE_SQUARED := field.Tight_Field_Element {
	1507062230895904,
	1572317787530805,
	683053064812840,
	317374165784489,
	1572899562415810,
}
@(private, rodata)
FE_SQRT_AD_MINUS_ONE := field.Tight_Field_Element {
	2241493124984347,
	425987919032274,
	2207028919301688,
	1220490630685848,
	974799131293748,
}
@(private)
GE_IDENTITY := Group_Element{grp.GE_IDENTITY, true}

// Group_Element is a ristretto255 group element.  The zero-initialized
// value is invalid.
Group_Element :: struct {
	// WARNING: While the internal representation is an Edwards25519
	// group element, this is not guaranteed to always be the case,
	// and your code *WILL* break if you mess with `_p`.
	_p:              grp.Group_Element,
	_is_initialized: bool,
}

// ge_clear clears ge to the uninitialized state.
ge_clear :: proc "contextless" (ge: ^Group_Element) {
	mem.zero_explicit(ge, size_of(Group_Element))
}

// ge_set sets `ge = a`.
ge_set :: proc(ge, a: ^Group_Element) {
	_ge_ensure_initialized([]^Group_Element{a})

	grp.ge_set(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_identity sets ge to the identity (neutral) element.
ge_identity :: proc "contextless" (ge: ^Group_Element) {
	grp.ge_identity(&ge._p)
	ge._is_initialized = true
}

// ge_generator sets ge to the group generator.
ge_generator :: proc "contextless" (ge: ^Group_Element) {
	grp.ge_generator(&ge._p)
	ge._is_initialized = true
}

// ge_set_bytes sets ge to the result of decoding b as a ristretto255
// group element, and returns true on success.
@(require_results)
ge_set_bytes :: proc "contextless" (ge: ^Group_Element, b: []byte) -> bool {
	// 1.  Interpret the string as an unsigned integer s in little-endian
	//     representation.  If the length of the string is not 32 bytes or
	//     if the resulting value is >= p, decoding fails.
	//
	// 2.  If IS_NEGATIVE(s) returns TRUE, decoding fails.

	if len(b) != ELEMENT_SIZE {
		return false
	}
	if b[31] & 128 != 0 || b[0] & 1 != 0 {
		// Fail early if b is clearly > p, or negative.
		return false
	}

	b_ := (^[32]byte)(raw_data(b))

	s: field.Tight_Field_Element = ---
	defer field.fe_clear(&s)

	field.fe_from_bytes(&s, b_)
	if field.fe_equal_bytes(&s, b_) != 1 {
		// Reject non-canonical encodings of s.
		return false
	}

	// 3.  Process s as follows:
	v, u1, u2: field.Loose_Field_Element = ---, ---, ---
	tmp, u2_sqr: field.Tight_Field_Element = ---, ---

	// ss = s^2
	// u1 = 1 - ss
	// u2 = 1 + ss
	// u2_sqr = u2^2
	field.fe_carry_square(&tmp, field.fe_relax_cast(&s))
	field.fe_sub(&u1, &field.FE_ONE, &tmp)
	field.fe_add(&u2, &field.FE_ONE, &tmp)
	field.fe_carry_square(&u2_sqr, &u2)

	// v = -(D * u1^2) - u2_sqr
	field.fe_carry_square(&tmp, &u1)
	field.fe_carry_mul(&tmp, field.fe_relax_cast(&grp.FE_D), field.fe_relax_cast(&tmp))
	field.fe_carry_add(&tmp, &tmp, &u2_sqr)
	field.fe_opp(&v, &tmp)

	// (was_square, invsqrt) = SQRT_RATIO_M1(1, v * u2_sqr)
	field.fe_carry_mul(&tmp, &v, field.fe_relax_cast(&u2_sqr))
	was_square := field.fe_carry_sqrt_ratio_m1(
		&tmp,
		field.fe_relax_cast(&field.FE_ONE),
		field.fe_relax_cast(&tmp),
	)

	// den_x = invsqrt * u2
	// den_y = invsqrt * den_x * v
	x, y, t: field.Tight_Field_Element = ---, ---, ---
	field.fe_carry_mul(&x, field.fe_relax_cast(&tmp), &u2)
	field.fe_carry_mul(&y, field.fe_relax_cast(&tmp), field.fe_relax_cast(&x))
	field.fe_carry_mul(&y, field.fe_relax_cast(&y), &v)

	// x = CT_ABS(2 * s * den_x)
	field.fe_carry_mul(&x, field.fe_relax_cast(&s), field.fe_relax_cast(&x))
	field.fe_carry_add(&x, &x, &x)
	field.fe_carry_abs(&x, &x)

	// y = u1 * den_y
	field.fe_carry_mul(&y, &u1, field.fe_relax_cast(&y))

	// t = x * y
	field.fe_carry_mul(&t, field.fe_relax_cast(&x), field.fe_relax_cast(&y))

	field.fe_clear_vec([]^field.Loose_Field_Element{&v, &u1, &u2})
	field.fe_clear_vec([]^field.Tight_Field_Element{&tmp, &u2_sqr})
	defer field.fe_clear_vec([]^field.Tight_Field_Element{&x, &y, &t})

	// 4.  If was_square is FALSE, IS_NEGATIVE(t) returns TRUE, or y = 0,
	// decoding fails.  Otherwise, return the group element represented
	// by the internal representation (x, y, 1, t) as the result of
	// decoding.

	switch {
	case was_square == 0:
		// Not sure why the RFC doesn't have this just fail early.
		return false
	case field.fe_is_negative(&t) != 0:
		return false
	case field.fe_equal(&y, &field.FE_ZERO) != 0:
		return false
	}

	field.fe_set(&ge._p.x, &x)
	field.fe_set(&ge._p.y, &y)
	field.fe_one(&ge._p.z)
	field.fe_set(&ge._p.t, &t)
	ge._is_initialized = true

	return true
}

// ge_set_wide_bytes sets ge to the result of deriving a ristretto255
// group element, from a wide (512-bit) byte string.
ge_set_wide_bytes :: proc(ge: ^Group_Element, b: []byte) {
	ensure(len(b) == WIDE_ELEMENT_SIZE, "crypto/ristretto255: invalid wide input size")

	// The element derivation function on an input string b proceeds as
	// follows:
	//
	// 1.  Compute P1 as MAP(b[0:32]).
	// 2.  Compute P2 as MAP(b[32:64]).
	// 3.  Return P1 + P2.

	p1, p2: Group_Element = ---, ---
	ge_map(&p1, b[0:32])
	ge_map(&p2, b[32:64])

	ge_add(ge, &p1, &p2)

	ge_clear(&p1)
	ge_clear(&p2)
}

// ge_bytes sets dst to the canonical encoding of ge.
ge_bytes :: proc(ge: ^Group_Element, dst: []byte) {
	_ge_ensure_initialized([]^Group_Element{ge})
	ensure(len(dst) == ELEMENT_SIZE, "crypto/ristretto255: invalid destination size")

	x0, y0, z0, t0 := &ge._p.x, &ge._p.y, &ge._p.z, &ge._p.t

	// 1.  Process the internal representation into a field element s as
	// follows:

	// u1 = (z0 + y0) * (z0 - y0)
	// u2 = x0 * y0
	u1, u2: field.Tight_Field_Element = ---, ---
	tmp1, tmp2: field.Loose_Field_Element = ---, ---
	field.fe_add(&tmp1, z0, y0)
	field.fe_sub(&tmp2, z0, y0)
	field.fe_carry_mul(&u1, &tmp1, &tmp2)
	field.fe_carry_mul(&u2, field.fe_relax_cast(x0), field.fe_relax_cast(y0))

	// Ignore was_square since this is always square.
	// (_, invsqrt) = SQRT_RATIO_M1(1, u1 * u2^2)
	tmp: field.Tight_Field_Element = ---
	field.fe_carry_square(&tmp, field.fe_relax_cast(&u2))
	field.fe_carry_mul(&tmp, field.fe_relax_cast(&u1), field.fe_relax_cast(&tmp))
	_ = field.fe_carry_sqrt_ratio_m1(
		&tmp,
		field.fe_relax_cast(&field.FE_ONE),
		field.fe_relax_cast(&tmp),
	)

	// den1 = invsqrt * u1
	// den2 = invsqrt * u2
	// z_inv = den1 * den2 * t0
	den1, den2 := &u1, &u2
	z_inv: field.Tight_Field_Element = ---
	field.fe_carry_mul(den1, field.fe_relax_cast(&tmp), field.fe_relax_cast(&u1))
	field.fe_carry_mul(den2, field.fe_relax_cast(&tmp), field.fe_relax_cast(&u2))
	field.fe_carry_mul(&z_inv, field.fe_relax_cast(den1), field.fe_relax_cast(den2))
	field.fe_carry_mul(&z_inv, field.fe_relax_cast(&z_inv), field.fe_relax_cast(t0))

	// rotate = IS_NEGATIVE(t0 * z_inv)
	// Note: Reordered from the RFC because invsqrt is no longer needed.
	field.fe_carry_mul(&tmp, field.fe_relax_cast(t0), field.fe_relax_cast(&z_inv))
	rotate := field.fe_is_negative(&tmp)

	// ix0 = x0 * SQRT_M1
	// iy0 = y0 * SQRT_M1
	// enchanted_denominator = den1 * INVSQRT_A_MINUS_D
	ix0, iy0: field.Tight_Field_Element = ---, ---
	field.fe_carry_mul(&ix0, field.fe_relax_cast(x0), field.fe_relax_cast(&field.FE_SQRT_M1))
	field.fe_carry_mul(&iy0, field.fe_relax_cast(y0), field.fe_relax_cast(&field.FE_SQRT_M1))
	field.fe_carry_mul(&tmp, field.fe_relax_cast(den1), field.fe_relax_cast(&FE_INVSQRT_A_MINUS_D))

	// Conditionally rotate x and y.
	// x = CT_SELECT(iy0 IF rotate ELSE x0)
	// y = CT_SELECT(ix0 IF rotate ELSE y0)
	// z = z0
	// den_inv = CT_SELECT(enchanted_denominator IF rotate ELSE den2)
	x, y: field.Tight_Field_Element = ---, ---
	field.fe_cond_select(&x, x0, &iy0, rotate)
	field.fe_cond_select(&y, y0, &ix0, rotate)
	field.fe_cond_select(&tmp, den2, &tmp, rotate)

	// y = CT_SELECT(-y IF IS_NEGATIVE(x * z_inv) ELSE y)
	field.fe_carry_mul(&x, field.fe_relax_cast(&x), field.fe_relax_cast(&z_inv))
	field.fe_cond_negate(&y, &y, field.fe_is_negative(&x))

	// s = CT_ABS(den_inv * (z - y))
	field.fe_sub(&tmp1, z0, &y)
	field.fe_carry_mul(&tmp, field.fe_relax_cast(&tmp), &tmp1)
	field.fe_carry_abs(&tmp, &tmp)

	// 2.  Return the 32-byte little-endian encoding of s.  More
	// specifically, this is the encoding of the canonical
	// representation of s as an integer between 0 and p-1, inclusive.
	dst_ := (^[32]byte)(raw_data(dst))
	field.fe_to_bytes(dst_, &tmp)

	field.fe_clear_vec([]^field.Tight_Field_Element{&u1, &u2, &tmp, &z_inv, &ix0, &iy0, &x, &y})
	field.fe_clear_vec([]^field.Loose_Field_Element{&tmp1, &tmp2})
}

// ge_add sets `ge = a + b`.
ge_add :: proc(ge, a, b: ^Group_Element) {
	_ge_ensure_initialized([]^Group_Element{a, b})

	grp.ge_add(&ge._p, &a._p, &b._p)
	ge._is_initialized = true
}

// ge_double sets `ge = a + a`.
ge_double :: proc(ge, a: ^Group_Element) {
	_ge_ensure_initialized([]^Group_Element{a})

	grp.ge_double(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_negate sets `ge = -a`.
ge_negate :: proc(ge, a: ^Group_Element) {
	_ge_ensure_initialized([]^Group_Element{a})

	grp.ge_negate(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_scalarmult sets `ge = A * sc`.
ge_scalarmult :: proc(ge, A: ^Group_Element, sc: ^Scalar) {
	_ge_ensure_initialized([]^Group_Element{A})

	grp.ge_scalarmult(&ge._p, &A._p, sc)
	ge._is_initialized = true
}

// ge_scalarmult_generator sets `ge = G * sc`
ge_scalarmult_generator :: proc "contextless" (ge: ^Group_Element, sc: ^Scalar) {
	grp.ge_scalarmult_basepoint(&ge._p, sc)
	ge._is_initialized = true
}

// ge_scalarmult_vartime sets `ge = A * sc` in variable time.
ge_scalarmult_vartime :: proc(ge, A: ^Group_Element, sc: ^Scalar) {
	_ge_ensure_initialized([]^Group_Element{A})

	grp.ge_scalarmult_vartime(&ge._p, &A._p, sc)
	ge._is_initialized = true
}

// ge_double_scalarmult_generator_vartime sets `ge = A * a + G * b` in variable
// time.
ge_double_scalarmult_generator_vartime :: proc(
	ge: ^Group_Element,
	a: ^Scalar,
	A: ^Group_Element,
	b: ^Scalar,
) {
	_ge_ensure_initialized([]^Group_Element{A})

	grp.ge_double_scalarmult_basepoint_vartime(&ge._p, a, &A._p, b)
	ge._is_initialized = true
}

// ge_cond_negate sets `ge = a` iff `ctrl == 0` and `ge = -a` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_negate :: proc(ge, a: ^Group_Element, ctrl: int) {
	_ge_ensure_initialized([]^Group_Element{a})

	grp.ge_cond_negate(&ge._p, &a._p, ctrl)
	ge._is_initialized = true
}

// ge_cond_assign sets `ge = ge` iff `ctrl == 0` and `ge = a` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_assign :: proc(ge, a: ^Group_Element, ctrl: int) {
	_ge_ensure_initialized([]^Group_Element{ge, a})

	grp.ge_cond_assign(&ge._p, &a._p, ctrl)
}

// ge_cond_select sets `ge = a` iff `ctrl == 0` and `ge = b` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_select :: proc(ge, a, b: ^Group_Element, ctrl: int) {
	_ge_ensure_initialized([]^Group_Element{a, b})

	grp.ge_cond_select(&ge._p, &a._p, &b._p, ctrl)
	ge._is_initialized = true
}

// ge_equal returns 1 iff `a == b`, and 0 otherwise.
@(require_results)
ge_equal :: proc(a, b: ^Group_Element) -> int {
	_ge_ensure_initialized([]^Group_Element{a, b})

	// CT_EQ(x1 * y2, y1 * x2) | CT_EQ(y1 * y2, x1 * x2)
	ax_by, ay_bx, ay_by, ax_bx: field.Tight_Field_Element = ---, ---, ---, ---
	field.fe_carry_mul(&ax_by, field.fe_relax_cast(&a._p.x), field.fe_relax_cast(&b._p.y))
	field.fe_carry_mul(&ay_bx, field.fe_relax_cast(&a._p.y), field.fe_relax_cast(&b._p.x))
	field.fe_carry_mul(&ay_by, field.fe_relax_cast(&a._p.y), field.fe_relax_cast(&b._p.y))
	field.fe_carry_mul(&ax_bx, field.fe_relax_cast(&a._p.x), field.fe_relax_cast(&b._p.x))

	ret := field.fe_equal(&ax_by, &ay_bx) | field.fe_equal(&ay_by, &ax_bx)

	field.fe_clear_vec([]^field.Tight_Field_Element{&ax_by, &ay_bx, &ay_by, &ax_bx})

	return ret
}

// ge_is_identity returns 1 iff `ge` is the identity element, and 0 otherwise.
@(require_results)
ge_is_identity :: proc(ge: ^Group_Element) -> int {
	return ge_equal(ge, &GE_IDENTITY)
}

@(private)
ge_map :: proc "contextless" (ge: ^Group_Element, b: []byte) {
	b_ := (^[32]byte)(raw_data(b))

	// The MAP function is defined on 32-byte strings as:
	//
	// 1.  Mask the most significant bit in the final byte of the string,
	// and interpret the string as an unsigned integer r in little-
	// endian representation.  Reduce r modulo p to obtain a field
	// element t.
	// *  Masking the most significant bit is equivalent to interpreting
	// the whole string as an unsigned integer in little-endian
	// representation and then reducing it modulo 2^255.
	t: field.Tight_Field_Element = ---
	field.fe_from_bytes(&t, b_)

	// 2.  Process t as follows:
	//
	// r = SQRT_M1 * t^2
	// u = (r + 1) * ONE_MINUS_D_SQ
	// v = (-1 - r*D) * (r + D)
	tmp1: field.Loose_Field_Element = ---
	r, u, v: field.Tight_Field_Element = ---, ---, ---

	field.fe_carry_square(&r, field.fe_relax_cast(&t))
	field.fe_carry_mul(&r, field.fe_relax_cast(&field.FE_SQRT_M1), field.fe_relax_cast(&r))

	field.fe_add(&tmp1, &field.FE_ONE, &r)
	field.fe_carry_mul(&u, &tmp1, field.fe_relax_cast(&FE_ONE_MINUS_D_SQ))

	field.fe_carry_mul(&v, field.fe_relax_cast(&r), field.fe_relax_cast(&grp.FE_D))
	field.fe_carry_add(&v, &field.FE_ONE, &v)
	field.fe_carry_opp(&v, &v)
	field.fe_add(&tmp1, &r, &grp.FE_D)
	field.fe_carry_mul(&v, field.fe_relax_cast(&v), &tmp1)

	// (was_square, s) = SQRT_RATIO_M1(u, v)
	// s_prime = -CT_ABS(s*t)
	// s = CT_SELECT(s IF was_square ELSE s_prime)
	// c = CT_SELECT(-1 IF was_square ELSE r)
	s, s_prime, c: field.Tight_Field_Element = ---, ---, ---
	was_square := field.fe_carry_sqrt_ratio_m1(
		&s,
		field.fe_relax_cast(&u),
		field.fe_relax_cast(&v),
	)
	field.fe_carry_mul(&s_prime, field.fe_relax_cast(&s), field.fe_relax_cast(&t))
	field.fe_carry_abs(&s_prime, &s_prime)
	field.fe_carry_opp(&s_prime, &s_prime)
	field.fe_cond_select(&s, &s_prime, &s, was_square)
	field.fe_cond_select(&c, &r, &FE_NEG_ONE, was_square)

	// N = c * (r - 1) * D_MINUS_ONE_SQ - v
	N: field.Tight_Field_Element = ---
	field.fe_sub(&tmp1, &r, &field.FE_ONE)
	field.fe_carry_mul(&N, field.fe_relax_cast(&c), &tmp1)
	field.fe_carry_mul(&N, field.fe_relax_cast(&N), field.fe_relax_cast(&FE_D_MINUS_ONE_SQUARED))
	field.fe_carry_sub(&N, &N, &v)

	// w0 = 2 * s * v
	// w1 = N * SQRT_AD_MINUS_ONE
	// w2 = 1 - s^2
	// w3 = 1 + s^2
	w0, w1: field.Tight_Field_Element = ---, ---
	w2, w3: field.Loose_Field_Element = ---, ---
	field.fe_carry_mul(&w0, field.fe_relax_cast(&s), field.fe_relax_cast(&v))
	field.fe_carry_add(&w0, &w0, &w0)
	field.fe_carry_mul(&w1, field.fe_relax_cast(&N), field.fe_relax_cast(&FE_SQRT_AD_MINUS_ONE))
	field.fe_carry_square(&s, field.fe_relax_cast(&s))
	field.fe_sub(&w2, &field.FE_ONE, &s)
	field.fe_add(&w3, &field.FE_ONE, &s)

	// 3.  Return the group element represented by the internal
	// representation (w0*w3, w2*w1, w1*w3, w0*w2).

	field.fe_carry_mul(&ge._p.x, field.fe_relax_cast(&w0), &w3)
	field.fe_carry_mul(&ge._p.y, &w2, field.fe_relax_cast(&w1))
	field.fe_carry_mul(&ge._p.z, field.fe_relax_cast(&w1), &w3)
	field.fe_carry_mul(&ge._p.t, field.fe_relax_cast(&w0), &w2)
	ge._is_initialized = true

	field.fe_clear_vec([]^field.Tight_Field_Element{&r, &u, &v, &s, &s_prime, &c, &N, &w0, &w1})
	field.fe_clear_vec([]^field.Loose_Field_Element{&tmp1, &w2, &w3})
}

@(private)
_ge_ensure_initialized :: proc(ges: []^Group_Element) {
	for ge in ges {
		ensure(ge._is_initialized, "crypto/ristretto255: uninitialized group element")
	}
}
