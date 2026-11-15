package math_big

import "base:builtin"
import "base:intrinsics"
import "core:math"

/*
	A rational number `a/b`.

	Results are canonical: `b > 0`, `gcd(a, b) == 1`, and zero is `0/1`.
	The zero value `Rat{}` is 0. A zero `b` with a nonzero `a` is invalid: procedures return `.Division_by_Zero`.
	Operations expect canonical operands. `internal_rat_norm` makes a `Rat` canonical after setting `a` or `b` directly.
	`rat_set_f64` stores +/-Inf and NaN as +/-1/1 with `.Inf` or `.NaN` in `a.flags`. `rat_to_f*` returns them as inexact +/-Inf or NaN, `rat_copy`, `rat_set_rat`, `rat_abs` and `rat_neg` keep them, and `rat_is_int` is false for them. Arithmetic, `rat_compare` and `rat_is_positive`, `rat_is_negative`, `rat_is_even` and `rat_is_odd` return `.Invalid_Argument` for them.
*/
Rat :: struct {
	a, b: Int,
}

rat_set_f64 :: proc(dst: ^Rat, f: f64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return

	EXP_MASK :: 1<<11 - 1

	bits     := transmute(u64)f
	mantissa := bits & (1<<52 - 1)
	exp      := int((bits>>52) & EXP_MASK)
	negative := bits>>63 != 0

	switch exp {
	case EXP_MASK:
		// +/-1 with a flag, like `INT_NAN` and `INT_INF`.
		_rat_set_u128(&dst.a, 1, negative && mantissa == 0) or_return
		if mantissa != 0 {
			dst.a.flags = {.NaN}
		} else {
			dst.a.flags = {.Inf}
		}
		return _rat_set_one(&dst.b)
	case 0:
		if mantissa == 0 {
			return _rat_set_zero(dst)
		}

		exp = 1
	case:
		mantissa |= 1<<52
	}

	// f = +/-mantissa * 2^shift.
	// An odd mantissa over a power of two is already reduced.
	shift := exp - 1075
	if shift < 0 {
		zeros := min(int(intrinsics.count_trailing_zeros(mantissa)), -shift)
		mantissa >>= uint(zeros)
		shift     += zeros
	}

	_rat_set_u128(&dst.a, u128(mantissa), negative) or_return
	if shift >= 0 {
		internal_int_shl(&dst.a, &dst.a, shift) or_return
		return _rat_set_one(&dst.b)
	}

	internal_int_power_of_two(&dst.b, -shift) or_return
	dst.b.sign  = .Zero_or_Positive
	dst.b.flags = {}
	return nil
}

rat_set_f32 :: proc(dst: ^Rat, f: f32, allocator := context.allocator) -> (err: Error) {
	return rat_set_f64(dst, f64(f), allocator)
}
rat_set_f16 :: proc(dst: ^Rat, f: f16, allocator := context.allocator) -> (err: Error) {
	return rat_set_f64(dst, f64(f), allocator)
}


rat_set_frac :: proc{rat_set_frac_digit, rat_set_frac_int}

rat_set_frac_digit :: proc(dst: ^Rat, a, b: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	if b == 0 {
		return .Division_by_Zero
	}
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return

	g := DIGIT(_private_gcd_u64(u64(a), u64(b)))
	_rat_set_u128(&dst.a, u128(a / g), false) or_return
	return _rat_set_u128(&dst.b, u128(b / g), false)
}

rat_set_frac_int :: proc(dst: ^Rat, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	assert_if_nil(a, b)
	if internal_is_zero(b) {
		return .Division_by_Zero
	}
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	internal_error_if_non_finite(a, b) or_return
	switch {
	case b == &dst.a && a == &dst.b:
		internal_swap(&dst.a, &dst.b)
	case b == &dst.a:
		_rat_copy_int(&dst.b, b) or_return
		_rat_copy_int(&dst.a, a) or_return
	case:
		_rat_copy_int(&dst.a, a) or_return
		_rat_copy_int(&dst.b, b) or_return
	}
	return internal_rat_norm(dst)
}

rat_set_int :: proc(dst: ^Rat, a: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	assert_if_nil(a)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_copy_int(&dst.a, a) or_return
	return _rat_set_one(&dst.b)
}

rat_set_digit :: proc(dst: ^Rat, a: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	internal_set(&dst.a, a) or_return
	return _rat_set_one(&dst.b)
}

rat_set_rat :: proc(dst, x: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_check_denominator(x) or_return
	return _rat_set_rat(dst, x, false)
}

rat_set_u64 :: proc(dst: ^Rat, x: u64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	internal_set(&dst.a, x) or_return
	return _rat_set_one(&dst.b)
}
rat_set_i64 :: proc(dst: ^Rat, x: i64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	internal_set(&dst.a, x) or_return
	return _rat_set_one(&dst.b)
}

rat_copy :: proc(dst, src: ^Rat, minimize := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, src)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_check_denominator(src) or_return
	if dst != src {
		_rat_copy_int(&dst.a, &src.a, minimize) or_return
		_rat_copy_int(&dst.b, &src.b, minimize) or_return
	}
	return internal_rat_norm(dst)
}

internal_rat_destroy :: proc(rationals: ..^Rat) {
	rationals := rationals

	for &z in rationals {
		internal_int_destroy(&z.a, &z.b)
	}
}

internal_rat_norm :: proc(z: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(z)
	context.allocator = allocator

	if internal_is_zero(&z.a) {
		z.a.sign = .Zero_or_Positive
		return _rat_set_one(&z.b)
	}
	if internal_is_zero(&z.b) {
		return .Division_by_Zero
	}

	negative := z.a.sign != z.b.sign
	z.a.sign = .Zero_or_Positive
	z.b.sign = .Zero_or_Positive

	switch {
	case _rat_is_one(&z.b):

	case z.a.used == 1 && z.b.used == 1:
		g := DIGIT(_private_gcd_u64(u64(z.a.digit[0]), u64(z.b.digit[0])))
		z.a.digit[0] /= g
		z.b.digit[0] /= g

	case:
		g: Int
		defer internal_destroy(&g)

		g_digit := _rat_gcd(&g, &z.a, &z.b) or_return
		if g_digit != 1 {
			_rat_div_gcd(&z.a, &z.a, g_digit, &g) or_return
			_rat_div_gcd(&z.b, &z.b, g_digit, &g) or_return
		}
	}

	if negative {
		z.a.sign = .Negative
	}
	return nil
}

rat_swap :: proc(a, b: ^Rat) {
	assert_if_nil(a, b)
	assert(.Immutable not_in a.a.flags && .Immutable not_in a.b.flags && .Immutable not_in b.a.flags && .Immutable not_in b.b.flags, "Assignment to immutable")
	#force_inline internal_swap(a, b)
}

internal_rat_swap :: #force_inline proc(a, b: ^Rat) {
	internal_int_swap(&a.a, &b.a)
	internal_int_swap(&a.b, &b.b)
}

rat_sign :: proc(z: ^Rat) -> Sign {
	if z == nil {
		return .Zero_or_Positive
	}
	return z.a.sign
}

rat_is_int :: proc(z: ^Rat) -> bool {
	assert_if_nil(z)
	if .NaN in z.a.flags || .Inf in z.a.flags {
		return false
	}
	return internal_is_zero(&z.a) || _rat_is_one(&z.b)
}

rat_is_zero :: proc(z: ^Rat) -> bool {
	return internal_rat_is_zero(z)
}
internal_rat_is_zero :: #force_inline proc(z: ^Rat) -> bool {
	assert_if_nil(z)
	return internal_is_zero(&z.a)
}

internal_int_mul_denom :: proc(dst, x, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	switch {
	case internal_is_zero(x) && internal_is_zero(y):
		return internal_set(dst, 1)
	case internal_is_zero(x):
		return internal_set(dst, y)
	case internal_is_zero(y):
		return internal_set(dst, x)
	}
	return int_mul(dst, x, y)
}

internal_int_scale_denom :: proc(dst, x, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	if internal_is_zero(y) {
		return internal_set(dst, x)
	}
	int_mul(dst, x, y) or_return
	dst.sign = x.sign
	return
}


rat_add_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub(dst, x, y, false)
}

rat_sub_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub(dst, x, y, true)
}

rat_mul_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_check(x) or_return
	_rat_check(y) or_return
	_rat_clear_non_finite(dst)

	if internal_is_zero(&x.a) || internal_is_zero(&y.a) {
		return _rat_set_zero(dst)
	}

	if x == y {
		// Squares of coprime numbers are coprime.
		if _rat_is_small(x) {
			a, b, _ := _rat_words(x)
			return _rat_set_words(dst, u128(a) * u128(a), false, u128(b) * u128(b))
		}
		internal_sqr(&dst.a, &x.a) or_return
		return internal_sqr(&dst.b, &x.b)
	}

	if _rat_is_small(x) && _rat_is_small(y) {
		a, b, a_negative := _rat_words(x)
		c, d, c_negative := _rat_words(y)
		return _rat_mul_words(dst, a, b, c, d, a_negative != c_negative)
	}

	negative := x.a.sign != y.a.sign
	if dst == y {
		// `_rat_mul_cross` allows `dst` on the left only.
		return _rat_mul_cross(dst, &y.a, &y.b, &x.a, &x.b, negative)
	}
	return _rat_mul_cross(dst, &x.a, &x.b, &y.a, &y.b, negative)
}

rat_div_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_check(x) or_return
	_rat_check(y) or_return

	if internal_rat_is_zero(y) {
		return .Division_by_Zero
	}
	_rat_clear_non_finite(dst)
	if internal_is_zero(&x.a) {
		return _rat_set_zero(dst)
	}
	if x == y {
		return _rat_set_words(dst, 1, false, 1)
	}

	// a/b / c/d = (a*d) / (b*c)
	if _rat_is_small(x) && _rat_is_small(y) {
		a, b, a_negative := _rat_words(x)
		c, d, c_negative := _rat_words(y)
		return _rat_mul_words(dst, a, b, d, c, a_negative != c_negative)
	}

	negative := x.a.sign != y.a.sign
	if dst == y {
		// Move the divisor out of `dst` before writing to it.
		divisor: Rat
		defer internal_rat_destroy(&divisor)

		internal_rat_swap(&divisor, dst)
		return _rat_mul_cross(dst, &x.a, &x.b, &divisor.b, &divisor.a, negative)
	}
	return _rat_mul_cross(dst, &x.a, &x.b, &y.b, &y.a, negative)
}


rat_abs :: proc(dst, x: ^Rat, allocator := context.allocator) -> (err: Error) {
	rat_set_rat(dst, x, allocator)          or_return
	internal_abs(&dst.a, &dst.a, allocator) or_return
	return
}
rat_neg :: proc(dst, x: ^Rat, allocator := context.allocator) -> (err: Error) {
	rat_set_rat(dst, x, allocator)          or_return
	internal_neg(&dst.a, &dst.a, allocator) or_return
	return
}


rat_is_positive :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	_rat_check(z) or_return
	return z.a.sign == z.b.sign, nil
}
rat_is_negative :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	_rat_check(z) or_return
	return z.a.sign != z.b.sign, nil
}

rat_is_even :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	_rat_check(z) or_return
	return rat_is_int(z) && internal_is_even(&z.a), nil
}
rat_is_odd :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	_rat_check(z) or_return
	return rat_is_int(z) && internal_is_odd(&z.a), nil
}

rat_to_f16 :: proc(z: ^Rat, allocator := context.allocator) -> (f: f16, exact: bool, err: Error) {
	assert_if_nil(z)
	return internal_rat_to_float(f16, z, allocator)
}
rat_to_f32 :: proc(z: ^Rat, allocator := context.allocator) -> (f: f32, exact: bool, err: Error) {
	assert_if_nil(z)
	return internal_rat_to_float(f32, z, allocator)
}
rat_to_f64 :: proc(z: ^Rat, allocator := context.allocator) -> (f: f64, exact: bool, err: Error) {
	assert_if_nil(z)
	return internal_rat_to_float(f64, z, allocator)
}

internal_rat_to_float :: proc($T: typeid, z: ^Rat, allocator := context.allocator) -> (f: T, exact: bool, err: Error)  where intrinsics.type_is_float(T) {
	FSIZE :: 8*size_of(T)
	when FSIZE == 16 {
		MSIZE :: 10
	} else when FSIZE == 32 {
		MSIZE :: 23
	} else when FSIZE == 64 {
		MSIZE :: 52
	} else {
		#panic("unsupported float type")
	}

	MSIZE1 :: MSIZE+1
	MSIZE2 :: MSIZE+2

	ESIZE :: FSIZE - MSIZE1
	EBIAS :: 1<<(ESIZE-1) - 1
	EMIN  :: 1 - EBIAS
	EMAX  :: EBIAS

	assert_if_nil(z)
	a, b := &z.a, &z.b

	context.allocator = allocator

	if .NaN in a.flags {
		return T(math.nan_f64()), false, nil
	}
	if .Inf in a.flags {
		return T(math.inf_f64(-1 if a.sign == .Negative else 1)), false, nil
	}

	alen := internal_count_bits(a)
	if alen == 0 {
		return 0, true, nil
	}
	blen := internal_count_bits(b)
	if blen == 0 {
		return T(math.nan_f64()), false, .Division_by_Zero
	}

	has_sign := a.sign != b.sign

	// Both parts fit in `T` exactly. One `f64` division then rounds correctly for `f16`, `f32`, and `f64` (53 >= 2*MSIZE1 + 2).
	if alen <= MSIZE1 && blen <= MSIZE1 {
		n := u64(a.digit[0])
		d := u64(b.digit[0])
		f = T(f64(n) / f64(d))

		// `n/d` is a finite binary fraction if and only if the odd part of `d` divides `n`.
		exact = n % (d >> intrinsics.count_trailing_zeros(d)) == 0
		if has_sign {
			f = -f
		}
		return
	}

	exp := alen - blen
	a2, b2 := &Int{}, &Int{}
	defer internal_destroy(a2, b2)
	internal_int_abs(a2, a) or_return
	internal_int_abs(b2, b) or_return

	if shift := MSIZE2 - exp; shift > 0 {
		internal_int_shl(a2, a2, shift) or_return
	} else if shift < 0 {
		internal_int_shl(b2, b2, -shift) or_return
	}

	q, r := &Int{}, &Int{}
	defer internal_destroy(q, r)

	internal_int_divmod(q, r, a2, b2) or_return

	has_rem := !internal_is_zero(r)
	mantissa := internal_int_get_u64(q) or_return

	if mantissa>>MSIZE2 == 1 {
		if mantissa&1 == 1 {
			has_rem = true
		}
		mantissa >>= 1
		exp += 1
	}

	assert(mantissa>>MSIZE1 == 1, "invalid bit result")


	if EMIN-MSIZE <= exp && exp <= EMIN {
		shift := uint(EMIN - (exp - 1))
		lost_bits := mantissa & (1<<shift - 1)
		has_rem ||= lost_bits != 0
		mantissa >>= shift
		exp = 2 - EBIAS // exp + shift
	}


	exact = !has_rem
	if mantissa&1 != 0 {
		exact = false
		if has_rem || mantissa&2 != 0 {
			mantissa += 1
			if mantissa >= 1<<MSIZE2 {
				mantissa >>= 1
				exp += 1
			}
		}
	}

	mantissa >>= 1

	f = T(math.ldexp(f64(mantissa), exp-MSIZE1))
	if math.is_inf(f, 0) || f == 0 {
		exact = false
	}
	if has_sign {
		f = -builtin.abs(f)
	}
	return
}


rat_compare :: proc(x, y: ^Rat, allocator := context.allocator) -> (comparison: int, error: Error) {
	assert_if_nil(x, y)
	context.allocator = allocator
	_rat_check(x) or_return
	_rat_check(y) or_return

	x_sign := _rat_sign_int(x)
	y_sign := _rat_sign_int(y)
	switch {
	case x_sign < y_sign: return -1, nil
	case x_sign > y_sign: return +1, nil
	case x_sign == 0:     return  0, nil
	}

	magnitude := _rat_compare_magnitude(x, y) or_return
	return magnitude * x_sign, nil
}



rat_add_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub_int(dst, x, y, false, false)
}

rat_sub_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub_int(dst, x, y, true, false)
}

rat_mul_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_mul_int(dst, x, y, false)
}

rat_div_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_mul_int(dst, x, y, true)
}


int_add_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub_int(dst, y, x, false, false)
}

int_sub_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_add_sub_int(dst, y, x, true, true)
}

int_mul_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	return _rat_mul_int(dst, y, x, false)
}

int_div_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	context.allocator = allocator
	internal_error_if_immutable(&dst.a, &dst.b) or_return
	_rat_check(y) or_return
	internal_error_if_non_finite(x) or_return

	if internal_rat_is_zero(y) {
		return .Division_by_Zero
	}
	_rat_clear_non_finite(dst)
	if internal_is_zero(x) {
		return _rat_set_zero(dst)
	}

	// n / (c/d) = (n*d) / c
	negative := x.sign != y.a.sign
	if x.used == 1 && _rat_is_small(y) {
		n := _rat_int_word(x)
		c, d, _ := _rat_words(y)
		return _rat_mul_words(dst, n, 1, d, c, negative)
	}

	if dst == y {
		// Move the divisor out of `dst` before writing to it. `x` may point into it too.
		divisor: Rat
		defer internal_rat_destroy(&divisor)

		internal_rat_swap(&divisor, dst)

		n := x
		switch x {
		case &dst.a: n = &divisor.a
		case &dst.b: n = &divisor.b
		}
		return _rat_mul_cross(dst, n, INT_ONE, &divisor.b, &divisor.a, negative)
	}
	return _rat_mul_cross(dst, x, INT_ONE, &y.b, &y.a, negative)
}


// dst = x + y, or x - y when `subtract` is set. `dst` may be `x`, `y`, or both.
_rat_add_sub :: proc(dst, x, y: ^Rat, subtract: bool) -> (err: Error) {
	_rat_check(x) or_return
	_rat_check(y) or_return
	_rat_clear_non_finite(dst)

	switch {
	case internal_is_zero(&y.a): return _rat_set_rat(dst, x, false)
	case internal_is_zero(&x.a): return _rat_set_rat(dst, y, subtract)
	}

	if _rat_is_small(x) && _rat_is_small(y) {
		a, b, a_negative := _rat_words(x)
		c, d, c_negative := _rat_words(y)
		return _rat_add_words(dst, a, b, a_negative, c, d, c_negative != subtract)
	}

	a, b := &x.a, &x.b
	c, d := &y.a, &y.b

	// Each step reads the parts of `x` and `y` it needs before writing the part of `dst` that may share their storage.
	t: Int
	defer internal_destroy(&t)

	b_one := _rat_is_one(b)
	d_one := _rat_is_one(d)

	switch {
	case b_one && d_one:
		_rat_add_or_sub(&dst.a, a, c, subtract) or_return
		return _rat_set_one(&dst.b)

	case d_one:
		// a/b +/- c = (a +/- c*b)/b: already reduced.
		_rat_mul(&t, c, b) or_return
		_rat_add_or_sub(&dst.a, a, &t, subtract) or_return
		return internal_copy(&dst.b, b)

	case b_one:
		// a +/- c/d = (a*d +/- c)/d: already reduced.
		_rat_mul(&t, a, d) or_return
		_rat_add_or_sub(&dst.a, &t, c, subtract) or_return
		return internal_copy(&dst.b, d)
	}

	g: Int
	defer internal_destroy(&g)

	g_digit := _rat_gcd(&g, b, d) or_return
	if g_digit == 1 {
		// (a*d +/- c*b) / (b*d): already reduced.
		_rat_mul(&t, c, b) or_return
		_rat_mul(&dst.a, a, d) or_return
		_rat_add_or_sub(&dst.a, &dst.a, &t, subtract) or_return
		return _rat_mul(&dst.b, b, d)
	}

	// Knuth 4.5.1: with s = b/g and u = a*(d/g) +/- c*s, the result is (u/g2) / (s*(d/g2)) for g2 = gcd(u, g).
	s, d_cut: Int
	defer internal_destroy(&s, &d_cut)

	_rat_div_gcd(&s,     b, g_digit, &g) or_return
	_rat_div_gcd(&d_cut, d, g_digit, &g) or_return
	_rat_mul(&t, c, &s)                  or_return
	_rat_mul(&dst.a, a, &d_cut)          or_return
	_rat_add_or_sub(&dst.a, &dst.a, &t, subtract) or_return

	if internal_is_zero(&dst.a) {
		return _rat_set_one(&dst.b)
	}

	g2: Int
	defer internal_destroy(&g2)

	g2_digit: DIGIT
	if g_digit != 0 {
		g2_digit = DIGIT(_private_gcd_u64(u64(_private_int_mod_digit(&dst.a, g_digit)), u64(g_digit)))
	} else {
		g2_digit = _rat_gcd(&g2, &dst.a, &g) or_return
	}

	if g2_digit == 1 {
		return _rat_mul(&dst.b, &s, d)
	}
	_rat_div_gcd(&dst.a, &dst.a, g2_digit, &g2) or_return
	_rat_div_gcd(&d_cut, d, g2_digit, &g2)      or_return
	return _rat_mul(&dst.b, &s, &d_cut)
}

// dst = x +/- n, or n - x when `reverse` is set as well as `subtract`.
_rat_add_sub_int :: proc(dst, x: ^Rat, n: ^Int, subtract, reverse: bool) -> (err: Error) {
	_rat_check(x) or_return
	internal_error_if_non_finite(n) or_return
	_rat_clear_non_finite(dst)

	if internal_is_zero(&x.a) {
		// 0 + n, 0 - n, or n - 0.
		_rat_copy_int(&dst.a, n) or_return
		if subtract && !reverse {
			internal_int_neg(&dst.a, &dst.a) or_return
		}
		return _rat_set_one(&dst.b)
	}

	if _rat_is_small(x) && n.used <= 1 {
		a, b, a_negative := _rat_words(x)
		c          := _rat_int_word(n)
		c_negative := (n.sign == .Negative) != subtract
		if reverse {
			a_negative = !a_negative
			c_negative = !c_negative
		}
		return _rat_add_words(dst, a, b, a_negative, c, 1, c_negative)
	}

	// (a +/- n*b)/b keeps gcd(a, b) == 1: no reduction needed.
	b := &x.b
	if _rat_is_one(b) {
		_rat_add_or_sub(&dst.a, &x.a, n, subtract) or_return
	} else {
		t: Int
		defer internal_destroy(&t)

		_rat_mul(&t, n, b) or_return
		_rat_add_or_sub(&dst.a, &x.a, &t, subtract) or_return
	}

	if reverse {
		internal_int_neg(&dst.a, &dst.a) or_return
	}
	return internal_copy(&dst.b, b)
}

// dst = x * n, or x / n when `divide` is set.
_rat_mul_int :: proc(dst, x: ^Rat, n: ^Int, divide: bool) -> (err: Error) {
	_rat_check(x) or_return
	internal_error_if_non_finite(n) or_return

	if divide && internal_is_zero(n) {
		return .Division_by_Zero
	}
	_rat_clear_non_finite(dst)
	if internal_is_zero(&x.a) || internal_is_zero(n) {
		return _rat_set_zero(dst)
	}

	negative := x.a.sign != n.sign
	if _rat_is_small(x) && n.used == 1 {
		a, b, _ := _rat_words(x)
		c := _rat_int_word(n)
		if divide {
			return _rat_mul_words(dst, a, b, 1, c, negative)
		}
		return _rat_mul_words(dst, a, b, c, 1, negative)
	}

	if n == &dst.a || n == &dst.b {
		n_copy: Int
		defer internal_destroy(&n_copy)

		internal_copy(&n_copy, n) or_return
		return _rat_mul_int(dst, x, &n_copy, divide)
	}

	if divide {
		return _rat_mul_cross(dst, &x.a, &x.b, INT_ONE, n, negative)
	}
	return _rat_mul_cross(dst, &x.a, &x.b, n, INT_ONE, negative)
}

// dst = (p*r) / (q*s) for nonzero `p` and `r`, with gcd(p, q) == gcd(r, s) == 1.
// `p` and `q` may be `dst.a` and `dst.b`. `r` and `s` must not be part of `dst`.
_rat_mul_cross :: proc(dst: ^Rat, p, q, r, s: ^Int, negative: bool) -> (err: Error) {
	g1, g2, r_cut, s_cut: Int
	defer internal_destroy(&g1, &g2, &r_cut, &s_cut)

	// Cancelling gcd(p, s) and gcd(r, q) first leaves the product reduced.
	g1_digit := DIGIT(1)
	if !_rat_is_one(p) && !_rat_is_one(s) {
		g1_digit = _rat_gcd(&g1, p, s) or_return
	}
	g2_digit := DIGIT(1)
	if !_rat_is_one(r) && !_rat_is_one(q) {
		g2_digit = _rat_gcd(&g2, r, q) or_return
	}

	r_factor := r
	if g2_digit != 1 {
		_rat_div_gcd(&r_cut, r, g2_digit, &g2) or_return
		r_factor = &r_cut
	}
	s_factor := s
	if g1_digit != 1 {
		_rat_div_gcd(&s_cut, s, g1_digit, &g1) or_return
		s_factor = &s_cut
	}

	_rat_div_gcd(&dst.a, p, g1_digit, &g1) or_return
	_rat_mul(&dst.a, &dst.a, r_factor)     or_return
	_rat_div_gcd(&dst.b, q, g2_digit, &g2) or_return
	_rat_mul(&dst.b, &dst.b, s_factor)     or_return

	dst.a.sign = .Negative if negative else .Zero_or_Positive
	dst.b.sign = .Zero_or_Positive
	return nil
}

_rat_compare_magnitude :: proc(x, y: ^Rat) -> (comparison: int, err: Error) {
	if _rat_is_small(x) && _rat_is_small(y) {
		xn, xd, _ := _rat_words(x)
		yn, yd, _ := _rat_words(y)
		left  := u128(xn) * u128(yd)
		right := u128(yn) * u128(xd)
		switch {
		case left < right: return -1, nil
		case left > right: return +1, nil
		}
		return 0, nil
	}

	a, b := &x.a, &x.b
	c, d := &y.a, &y.b
	if _rat_is_one(b) && _rat_is_one(d) {
		return internal_int_compare_magnitude(a, c), nil
	}

	// |a*d| has `left-1` or `left` bits.
	left  := internal_count_bits(a) + internal_count_bits(d)
	right := internal_count_bits(c) + internal_count_bits(b)
	switch {
	case left > right + 1: return +1, nil
	case right > left + 1: return -1, nil
	}

	l, r: Int
	defer internal_destroy(&l, &r)

	_rat_mul(&l, a, d) or_return
	_rat_mul(&r, c, b) or_return
	return internal_int_compare_magnitude(&l, &r), nil
}

// dst = a/b + c/d with separate signs, for one-digit parts (Knuth 4.5.1). The products stay below 2^127.
_rat_add_words :: proc(dst: ^Rat, a, b: u64, a_negative: bool, c, d: u64, c_negative: bool) -> (err: Error) {
	g     := _private_gcd_u64(b, d)
	b_cut := b / g
	d_cut := d / g

	left  := u128(a) * u128(d_cut)
	right := u128(c) * u128(b_cut)

	num:      u128
	negative: bool
	switch {
	case a_negative == c_negative:
		num      = left + right
		negative = a_negative
	case left >= right:
		num      = left - right
		negative = a_negative
	case:
		num      = right - left
		negative = c_negative
	}

	if num == 0 {
		return _rat_set_zero(dst)
	}

	den := u128(b_cut) * u128(d)
	if g != 1 {
		g2 := _private_gcd_u64(u64(num % u128(g)), g)
		num /= u128(g2)
		den  = u128(b_cut) * u128(d / g2)
	}
	return _rat_set_words(dst, num, negative, den)
}

// dst = (p*r) / (q*s) for one-digit parts with gcd(p, q) == gcd(r, s) == 1.
_rat_mul_words :: proc(dst: ^Rat, p, q, r, s: u64, negative: bool) -> (err: Error) {
	if p == 0 || r == 0 {
		return _rat_set_zero(dst)
	}

	g1 := _private_gcd_u64(p, s)
	g2 := _private_gcd_u64(r, q)
	num := u128(p / g1) * u128(r / g2)
	den := u128(q / g2) * u128(s / g1)
	return _rat_set_words(dst, num, negative, den)
}

// gcd(|a|, |b|) for nonzero `a` and `b`. Returns it if it fits in a digit, otherwise 0 with the gcd in `g`.
_rat_gcd :: proc(g: ^Int, a, b: ^Int) -> (g_digit: DIGIT, err: Error) {
	switch {
	case a.used == 1 && b.used == 1:
		return DIGIT(_private_gcd_u64(u64(a.digit[0]), u64(b.digit[0]))), nil
	case a.used == 1:
		r := _private_int_mod_digit(b, a.digit[0])
		return DIGIT(_private_gcd_u64(u64(r), u64(a.digit[0]))), nil
	case b.used == 1:
		r := _private_int_mod_digit(a, b.digit[0])
		return DIGIT(_private_gcd_u64(u64(r), u64(b.digit[0]))), nil
	}

	internal_int_gcd(g, a, b) or_return
	if g.used == 1 {
		return g.digit[0], nil
	}
	return 0, nil
}

// dst = src / g for a gcd from `_rat_gcd`. `dst` may be `src`.
_rat_div_gcd :: proc(dst, src: ^Int, g_digit: DIGIT, g: ^Int) -> (err: Error) {
	switch g_digit {
	case 0: return internal_int_div(dst, src, g)
	case 1: return internal_copy(dst, src)
	}
	_, err = internal_int_divmod_digit(dst, src, g_digit)
	return
}

// dst = x * y. A one-digit side uses the digit product: no temporary.
_rat_mul :: proc(dst, x, y: ^Int) -> (err: Error) {
	if x.used == 0 || y.used == 0 {
		return internal_zero(dst)
	}

	negative := x.sign != y.sign
	switch {
	case x.used == 1: internal_int_mul_digit(dst, y, x.digit[0]) or_return
	case y.used == 1: internal_int_mul_digit(dst, x, y.digit[0]) or_return
	case:             internal_int_mul(dst, x, y)                or_return
	}
	dst.sign = .Negative if negative else .Zero_or_Positive
	return nil
}

_rat_add_or_sub :: proc(dst, x, y: ^Int, subtract: bool) -> (err: Error) {
	if subtract {
		return internal_int_sub_signed(dst, x, y)
	}
	return internal_int_add_signed(dst, x, y)
}

_rat_set_u128 :: proc(dst: ^Int, value: u128, negative: bool) -> (err: Error) {
	internal_error_if_immutable(dst) or_return
	if !internal_int_is_initialized(dst) {
		internal_grow(dst, _DEFAULT_DIGIT_COUNT) or_return
	}

	old_used := dst.used
	used     := 0
	for v := value; v != 0; v >>= _DIGIT_BITS {
		dst.digit[used] = DIGIT(v) & _MASK
		used += 1
	}

	dst.used  = used
	dst.sign  = .Negative if negative && used > 0 else .Zero_or_Positive
	dst.flags = {}
	internal_zero_unused(dst, old_used)
	return nil
}

_rat_set_words :: #force_inline proc(dst: ^Rat, num: u128, negative: bool, den: u128) -> (err: Error) {
	_rat_set_u128(&dst.a, num, negative) or_return
	return _rat_set_u128(&dst.b, den, false)
}

_rat_set_zero :: proc(dst: ^Rat) -> (err: Error) {
	return _rat_set_words(dst, 0, false, 1)
}

_rat_set_one :: proc(dst: ^Int) -> (err: Error) {
	return _rat_set_u128(dst, 1, false)
}

// `src` may be an unset `Int`.
_rat_copy_int :: proc(dst, src: ^Int, minimize := false) -> (err: Error) {
	if src.used == 0 {
		return _rat_set_u128(dst, 0, false)
	}
	return internal_int_copy(dst, src, minimize)
}

// dst = x, or -x when `negate` is set, for a valid `x`.
_rat_set_rat :: proc(dst, x: ^Rat, negate: bool) -> (err: Error) {
	if internal_is_zero(&x.a) {
		return _rat_set_zero(dst)
	}
	if dst != x {
		internal_copy(&dst.a, &x.a) or_return
		internal_copy(&dst.b, &x.b) or_return
	}
	if negate {
		return internal_int_neg(&dst.a, &dst.a)
	}
	return nil
}

// The zero value `Rat{}` is 0. A zero `b` with a nonzero `a` is invalid.
_rat_check_denominator :: #force_inline proc(x: ^Rat) -> (err: Error) {
	if x.b.used == 0 && x.a.used != 0 {
		return .Division_by_Zero
	}
	return nil
}

_rat_check :: #force_inline proc(x: ^Rat) -> (err: Error) {
	_rat_check_denominator(x) or_return
	if .NaN in x.a.flags || .Inf in x.a.flags {
		return .Invalid_Argument
	}
	return nil
}

_rat_clear_non_finite :: #force_inline proc "contextless" (dst: ^Rat) {
	dst.a.flags -= {.NaN, .Inf}
	dst.b.flags -= {.NaN, .Inf}
}

@(require_results)
_rat_is_one :: #force_inline proc(x: ^Int) -> bool {
	return x.used == 1 && x.digit[0] == 1
}

@(require_results)
_rat_is_small :: #force_inline proc(x: ^Rat) -> bool {
	return x.a.used == 1 && x.b.used == 1
}

@(require_results)
_rat_words :: #force_inline proc(x: ^Rat) -> (num, den: u64, negative: bool) {
	return u64(x.a.digit[0]), u64(x.b.digit[0]), x.a.sign == .Negative
}

@(require_results)
_rat_int_word :: #force_inline proc(x: ^Int) -> u64 {
	if x.used == 1 {
		return u64(x.digit[0])
	}
	return 0
}

@(require_results)
_rat_sign_int :: proc(x: ^Rat) -> int {
	switch {
	case x.a.used == 0:         return  0
	case x.a.sign == .Negative: return -1
	}
	return +1
}
