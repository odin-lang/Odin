package math_big

import "base:builtin"
import "base:intrinsics"
import "core:math"

Rat :: struct {
	a, b: Int,
}

rat_set_f64 :: proc(dst: ^Rat, f: f64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	
	EXP_MASK :: 1<<11 - 1
	
	bits := transmute(u64)f
	mantissa := bits & (1<<52 - 1)
	exp := int((bits>>52) & EXP_MASK)
	
	int_set_from_integer(&dst.b, 1) or_return
	
	switch exp {
	case EXP_MASK:
		dst.a.flags += {.Inf}
		return
	case 0:
		exp -= 1022
	case:
		mantissa |= 1<<52
		exp -= 1023
	}
	
	shift := 52 - exp
	
	for mantissa&1 == 0 && shift > 0 {
		mantissa >>= 1
		shift -= 1
	}
	
	int_set_from_integer(&dst.a, mantissa) or_return
	dst.a.sign = .Negative if f < 0 else .Zero_or_Positive
	
	if shift > 0 {
		internal_int_shl(&dst.b, &dst.b, shift) or_return
	} else {
		internal_int_shl(&dst.a, &dst.a, -shift) or_return
	}
	
	return internal_rat_norm(dst)
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
	internal_set(&dst.a, a) or_return
	internal_set(&dst.b, b) or_return
	return internal_rat_norm(dst)
}

rat_set_frac_int :: proc(dst: ^Rat, a, b: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	assert_if_nil(a, b)
	if internal_is_zero(b) {
		return .Division_by_Zero
	}
	context.allocator = allocator
	internal_set(&dst.a, a) or_return
	internal_set(&dst.b, b) or_return
	return internal_rat_norm(dst)
}

rat_set_int :: proc(dst: ^Rat, a: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	assert_if_nil(a)
	context.allocator = allocator
	internal_set(&dst.a, a) or_return
	internal_set(&dst.b, 1) or_return
	return
}

rat_set_digit :: proc(dst: ^Rat, a: DIGIT, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_set(&dst.a, a) or_return
	internal_set(&dst.b, 1) or_return
	return
}

rat_set_rat :: proc(dst, x: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	context.allocator = allocator
	internal_set(&dst.a, &x.a) or_return
	internal_set(&dst.b, &x.b) or_return
	return
}

rat_set_u64 :: proc(dst: ^Rat, x: u64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_set(&dst.a, x) or_return
	internal_set(&dst.b, 1) or_return
	return
}
rat_set_i64 :: proc(dst: ^Rat, x: i64, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst)
	context.allocator = allocator
	internal_set(&dst.a, x) or_return
	internal_set(&dst.b, 1) or_return
	return
}

rat_copy :: proc(dst, src: ^Rat, minimize := false, allocator := context.allocator) -> (err: Error) {
	if (dst == src) { return nil }
	
	assert_if_nil(dst, src)
	context.allocator = allocator
	int_copy(&dst.a, &src.a, minimize, allocator) or_return
	int_copy(&dst.b, &src.b, minimize, allocator) or_return
	internal_rat_norm(dst) or_return
	return nil
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
	switch {
	case internal_is_zero(&z.a):
		z.a.sign = .Zero_or_Positive
		fallthrough
	case internal_is_zero(&z.b):
		int_set_from_integer(&z.b, 1) or_return
	case:
		sign := z.a.sign
		z.a.sign = .Zero_or_Positive
		z.b.sign = .Zero_or_Positive
		
		f := &Int{}
		internal_int_gcd(f, &z.a, &z.b) or_return
		if !internal_int_equals_digit(f, 1) {
			f.sign = .Zero_or_Positive
			internal_int_div(&z.a, &z.a, f) or_return
			internal_int_div(&z.b, &z.b, f) or_return
		}
		z.a.sign = sign	
	}
	return
}

rat_swap :: proc(a, b: ^Rat) {
	assert_if_nil(a, b)
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
	return internal_is_zero(&z.a) || internal_int_equals_digit(&z.b, 1)
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
	
	a1, a2: Int
	defer internal_destroy(&a1, &a2)
	
	internal_int_scale_denom(&a1, &x.a, &y.b)  or_return
	internal_int_scale_denom(&a2, &y.a, &x.b)  or_return
	int_add(&dst.a, &a1, &a2)                  or_return
	internal_int_mul_denom(&dst.b, &x.b, &y.b) or_return
	return internal_rat_norm(dst)
}

rat_sub_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	
	a1, a2 := &Int{}, &Int{}
	defer internal_destroy(a1, a2)
	
	internal_int_scale_denom(a1, &x.a, &y.b)   or_return
	internal_int_scale_denom(a2, &y.a, &x.b)   or_return
	int_sub(&dst.a, a1, a2)                    or_return
	internal_int_mul_denom(&dst.b, &x.b, &y.b) or_return
	return internal_rat_norm(dst)
}

rat_mul_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x, y)
	context.allocator = allocator
	
	if x == y {
		internal_sqr(&dst.a, &x.a)         or_return
		if internal_is_zero(&x.b) {
			internal_set(&dst.b, 1)    or_return
		} else {
			internal_sqr(&dst.a, &x.b) or_return
		}
		return
	}
	
	int_mul(&dst.a, &x.a, &y.a)                or_return
	internal_int_mul_denom(&dst.b, &x.b, &y.b) or_return
	return internal_rat_norm(dst)
}

rat_div_rat :: proc(dst, x, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	if internal_rat_is_zero(y) {
		return .Division_by_Zero
	}
	context.allocator = allocator
	
	a, b := &Int{}, &Int{}
	defer internal_destroy(a, b)
	
	internal_int_scale_denom(a, &x.a, &y.b) or_return
	internal_int_scale_denom(b, &y.a, &x.b) or_return
	internal_set(&dst.a, a) or_return
	internal_set(&dst.b, b) or_return
	internal_int_abs(&dst.a, &dst.a) 
	internal_int_abs(&dst.b, &dst.b) 
	dst.a.sign = .Negative if a.sign != b.sign else .Zero_or_Positive
	return internal_rat_norm(dst)
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
	a := int_is_positive(&z.a, allocator) or_return
	b := int_is_positive(&z.b, allocator) or_return
	return !(a ~ b), nil
}
rat_is_negative :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	a := int_is_positive(&z.a, allocator) or_return
	b := int_is_positive(&z.b, allocator) or_return
	return (a ~ b), nil
}

rat_is_even :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	if rat_is_int(z) {
		return int_is_even(&z.a, allocator)
	}
	return false, nil
}
rat_is_odd :: proc(z: ^Rat, allocator := context.allocator) -> (ok: bool, err: Error) {
	assert_if_nil(z)
	if rat_is_int(z) {
		return int_is_odd(&z.a, allocator)
	}
	return false, nil
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
	
	alen := internal_count_bits(a)
	if alen == 0 {
		return 0, true, nil
	}
	blen := internal_count_bits(b)
	if blen == 0 {
		return T(math.nan_f64()), false, .Division_by_Zero
	}
	
	has_sign := a.sign != b.sign
	defer if has_sign {
		f = -builtin.abs(f)
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
	if math.is_inf(f, 0) {
		exact = false
	}
	return
}


rat_compare :: proc(x, y: ^Rat, allocator := context.allocator) -> (comparison: int, error: Error) {
	assert_if_nil(x, y)
	context.allocator = allocator
	
	a, b: Int
	internal_init_multi(&a, &b) or_return
	defer internal_destroy(&a, &b)
	internal_int_scale_denom(&a, &x.a, &y.b) or_return
	internal_int_scale_denom(&b, &y.a, &x.b) or_return
	return int_compare(&a, &b)
}



rat_add_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	
	z: Rat
	rat_set_int(&z, y, allocator) or_return
	defer internal_destroy(&z)
	return rat_add_rat(dst, x, &z, allocator)
}

rat_sub_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	
	z: Rat
	rat_set_int(&z, y, allocator) or_return
	defer internal_destroy(&z)
	return rat_sub_rat(dst, x, &z, allocator)
}

rat_mul_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(dst, x)
	assert_if_nil(y)
	
	z: Rat
	rat_set_int(&z, y, allocator) or_return
	defer internal_destroy(&z)
	return rat_mul_rat(dst, x, &z, allocator)
}

rat_div_int :: proc(dst, x: ^Rat, y: ^Int, allocator := context.allocator) -> (err: Error) {
	if internal_is_zero(y) {
		return .Division_by_Zero
	}
	z: Rat
	rat_set_int(&z, y, allocator) or_return
	defer internal_destroy(&z)
	return rat_div_rat(dst, x, &z, allocator)
}


int_add_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	
	w: Rat
	rat_set_int(&w, x, allocator) or_return
	defer internal_destroy(&w)
	return rat_add_rat(dst, &w, y, allocator)
}

int_sub_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	
	w: Rat
	rat_set_int(&w, x, allocator) or_return
	defer internal_destroy(&w)
	return rat_sub_rat(dst, &w, y, allocator)
}

int_mul_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(x)
	assert_if_nil(dst, y)
	
	w: Rat
	rat_set_int(&w, x, allocator) or_return
	defer internal_destroy(&w)
	return rat_mul_rat(dst, &w, y, allocator)
}

int_div_rat :: proc(dst: ^Rat, x: ^Int, y: ^Rat, allocator := context.allocator) -> (err: Error) {
	if internal_is_zero(y) {
		return .Division_by_Zero
	}
	w: Rat
	rat_set_int(&w, x, allocator) or_return
	defer internal_destroy(&w)
	return rat_div_rat(dst, &w, y, allocator)
}