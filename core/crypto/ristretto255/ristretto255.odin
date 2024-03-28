/*
package ristretto255 implement the ristretto255 prime-order group.

See:
- https://www.rfc-editor.org/rfc/rfc9496
*/
package ristretto255

import grp "core:crypto/_edwards25519"
import field "core:crypto/_fiat/field_curve25519"
import "core:mem"

// Group_Element is a ristretto255 group element.
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
	_ge_assert_initialized([]^Group_Element{a})

	grp.ge_set(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_identity sets ge to the identity (neutral) element.
ge_identity :: proc "contextless" (ge: ^Group_Element) {
	grp.ge_identity(&ge._p)
	ge._is_initialized = true
}

// ge_generator

// ge_set_bytes sets ge to the result of decoding b as a ristretto255
// group element, and returns true on success.
@(require_results)
ge_set_bytes :: proc "contextless" (ge: ^Group_Element, b: []byte) -> bool {
	// 1.  Interpret the string as an unsigned integer s in little-endian
	//     representation.  If the length of the string is not 32 bytes or
	//     if the resulting value is >= p, decoding fails.
	//
	// 2.  If IS_NEGATIVE(s) returns TRUE, decoding fails.

	if len(b) != 32 {
		return false
	}
	if b[31] & 127 != 0 || b[0] & 1 != 0 {
		// Fail early if b is clearly > p, or negative.
		return false
	}

	b_ := transmute(^[32]byte)(raw_data(b))

	s: field.Tight_Field_Element = ---
	defer field.fe_clear(&s)

	field.fe_from_bytes(&s, b_)
	if field.fe_equal_bytes(&s, b_) != 1 {
		// Reject non-canonical encodings of s.
		return false
	}

	// 3.  Process s as follows
	v, u1, u2: field.Loose_Field_Element = ---, ---, ---
	tmp, u2_sqr: field.Tight_Field_Element = ---, ---

	// ss = s^2
	// u1 = 1 - ss
	// u2 = 1 + ss
	// u2_sqr = u2^2
	field.fe_carry_square(&tmp, field.fe_relax_cast(&s))
	field.fe_sub(&u1, &field.ONE, &tmp)
	field.fe_add(&u2, &field.ONE, &tmp)
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
		field.fe_relax_cast(&field.ONE),
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

	field.fe_clear(&u1)
	field.fe_clear(&u2)
	field.fe_clear(&tmp)
	field.fe_clear(&u2_sqr)
	field.fe_clear(&v)

	defer field.fe_clear(&x)
	defer field.fe_clear(&y)
	defer field.fe_clear(&t)

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
	case field.fe_equal(&y, &field.ZERO) != 0:
		return false
	}

	field.fe_set(&ge._p.x, &x)
	field.fe_set(&ge._p.y, &y)
	field.fe_one(&ge._p.z)
	field.fe_set(&ge._p.t, &t)

	return true
}

// ge_bytes

// ge_add sets `ge = a + b`.
ge_add :: proc(ge, a, b: ^Group_Element) {
	_ge_assert_initialized([]^Group_Element{a, b})

	grp.ge_add(&ge._p, &a._p, &b._p)
	ge._is_initialized = true
}

// ge_double sets `ge = a + a`.
ge_double :: proc(ge, a: ^Group_Element) {
	_ge_assert_initialized([]^Group_Element{a})

	grp.ge_double(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_negate sets `ge = -a`.
ge_negate :: proc(ge, a: ^Group_Element) {
	_ge_assert_initialized([]^Group_Element{a})

	grp.ge_negate(&ge._p, &a._p)
	ge._is_initialized = true
}

// ge_cond_negate sets `ge = a` iff `ctrl == 0` and `ge = -a` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_negate :: proc(ge, a: ^Group_Element, ctrl: int) {
	_ge_assert_initialized([]^Group_Element{a})

	grp.ge_cond_negate(&ge._p, &a._p, ctrl)
	ge._is_initialized = true
}

// ge_cond_assign sets `ge = ge` iff `ctrl == 0` and `ge = a` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_assign :: proc(ge, a: ^Group_Element, ctrl: int) {
	_ge_assert_initialized([]^Group_Element{ge, a})

	grp.ge_cond_assign(&ge._p, &a._p, ctrl)
}

// ge_cond_select sets `ge = a` iff `ctrl == 0` and `ge = b` iff `ctrl == 1`.
// Behavior for all other values of ctrl are undefined,
ge_cond_select :: proc(ge, a, b: ^Group_Element, ctrl: int) {
	_ge_assert_initialized([]^Group_Element{a, b})

	grp.ge_cond_select(&ge._p, &a._p, &b._p, ctrl)
	ge._is_initialized = true
}

// ge_equal returns 1 iff `a == b`, and 0 otherwise.
@(require_results)
ge_equal :: proc(a, b: ^Group_Element) -> int {
	_ge_assert_initialized([]^Group_Element{a, b})

	// CT_EQ(x1 * y2, y1 * x2) | CT_EQ(y1 * y2, x1 * x2)
	ax_by, ay_bx, ay_by, ax_bx: field.Tight_Field_Element = ---, ---, ---, ---
	field.fe_carry_mul(&ax_by, field.fe_relax_cast(&a._p.x), field.fe_relax_cast(&b._p.y))
	field.fe_carry_mul(&ay_bx, field.fe_relax_cast(&a._p.y), field.fe_relax_cast(&b._p.x))
	field.fe_carry_mul(&ay_by, field.fe_relax_cast(&a._p.y), field.fe_relax_cast(&b._p.y))
	field.fe_carry_mul(&ax_bx, field.fe_relax_cast(&a._p.x), field.fe_relax_cast(&b._p.x))

	ret := field.fe_equal(&ax_by, &ay_bx) | field.fe_equal(&ay_by, &ax_bx)

	field.fe_clear(&ax_by)
	field.fe_clear(&ay_bx)
	field.fe_clear(&ay_by)
	field.fe_clear(&ax_bx)

	return ret
}

// The multiplies

@(private)
_ge_assert_initialized :: proc(ges: []^Group_Element) {
	for ge in ges {
		if !ge._is_initialized {
			panic("crypto/ristretto255: uninitialized group element")
		}
	}
}
