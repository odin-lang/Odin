package test_core_math_big

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/big"
import "core:math/rand"
import "core:testing"

// `Rat` results are checked with plain `Int` arithmetic: values by cross-multiplication, canonical form with `int_gcd`.

@(private="file")
Bin_Op :: enum {
	Add,
	Sub,
	Mul,
	Div,
}

@(private="file")
Int_Op :: enum {
	Rat_Add_Int,
	Rat_Sub_Int,
	Rat_Mul_Int,
	Rat_Div_Int,
	Int_Add_Rat,
	Int_Sub_Rat,
	Int_Mul_Rat,
	Int_Div_Rat,
}

@(private="file")
POOL_RATS :: 56

@(private="file")
POOL_INTS :: 16

@(private="file")
Pool :: struct {
	rats: [POOL_RATS]big.Rat,
	ints: [POOL_INTS]big.Int,
}

@(test)
test_rat_binary_ops :: proc(t: ^testing.T) {
	pool := new(Pool)
	defer free(pool)

	make_pool(pool)
	defer destroy_pool(pool)

	for &x in pool.rats {
		for &y in pool.rats {
			for op in Bin_Op {
				if !check_bin_op(t, op, &x, &y) {
					return
				}
			}
		}
		for op in Bin_Op {
			if !check_bin_op_self(t, op, &x) {
				return
			}
		}
	}
}

@(test)
test_rat_int_ops :: proc(t: ^testing.T) {
	pool := new(Pool)
	defer free(pool)

	make_pool(pool)
	defer destroy_pool(pool)

	for &x in pool.rats {
		for &n in pool.ints {
			for op in Int_Op {
				if !check_int_op(t, op, &x, &n) {
					return
				}
			}
		}
	}
}

@(test)
test_rat_compare :: proc(t: ^testing.T) {
	pool := new(Pool)
	defer free(pool)

	make_pool(pool)
	defer destroy_pool(pool)

	for &x in pool.rats {
		for &y in pool.rats {
			if !check_compare(t, &x, &y) {
				return
			}
		}
	}

	// x = 2^p / (2^s - 1) and y = (2^r - 1) / 2^q: the bit lengths of a*d and c*b differ by one, the other way round.
	x, y: big.Rat
	defer big.destroy(&x, &y)

	n, d: big.Int
	defer big.destroy(&n, &d)

	sizes := [?][3]int{{100, 90, 80}, {70, 65, 3}, {200, 64, 63}, {130, 127, 126}}
	for size in sizes {
		p, s, q := size[0], size[1], size[2]
		r := p + q + 1 - s

		big.set(&n, 1)
		big.shl(&n, &n, p)
		big.set(&d, 1)
		big.shl(&d, &d, s)
		big.sub(&d, &d, 1)
		set_rat(&x, &n, &d)

		big.set(&n, 1)
		big.shl(&n, &n, r)
		big.sub(&n, &n, 1)
		big.set(&d, 1)
		big.shl(&d, &d, q)
		set_rat(&y, &n, &d)

		for _ in 0..<2 {
			if !check_compare(t, &x, &y) || !check_compare(t, &y, &x) {
				return
			}
			big.neg(&x.a, &x.a)
			big.neg(&y.a, &y.a)
		}
	}
}

@(private="file")
check_compare :: proc(t: ^testing.T, x, y: ^big.Rat) -> (ok: bool) {
	den_x := den_copy(x)
	den_y := den_copy(y)
	defer big.destroy(&den_x, &den_y)

	l, r: big.Int
	defer big.destroy(&l, &r)

	big.mul(&l, &x.a, &den_y)
	big.mul(&r, &y.a, &den_x)
	want, _ := big.cmp(&l, &r)

	got, err := big.rat_compare(x, y)
	if got != want || err != nil {
		return testing.expectf(t, false, "compare(%s, %s) = %d, %v; want %d", rat_str(x), rat_str(y), got, err, want)
	}
	return true
}

@(test)
test_rat_set_frac :: proc(t: ^testing.T) {
	for _ in 0..<500 {
		n, d: big.Int
		defer big.destroy(&n, &d)

		random_int(&n, rand.int_max(200) + 1)
		random_int(&d, rand.int_max(200) + 1)
		if rand.int_max(4) == 0 {
			big.mul(&n, &n, &d)
		}

		r: big.Rat
		defer big.destroy(&r)

		err := big.rat_set_frac_int(&r, &n, &d)
		if is_zero_int(&d) {
			testing.expect_value(t, err, big.Error.Division_by_Zero)
			continue
		}
		testing.expect_value(t, err, nil)
		if !expect_rat(t, &r, &n, &d, "rat_set_frac_int") {
			return
		}

		c: big.Rat
		defer big.destroy(&c)

		big.int_copy(&c.a, &n)
		big.int_copy(&c.b, &d)
		testing.expect_value(t, big.rat_copy(&r, &c), nil)
		if !expect_rat(t, &r, &n, &d, "rat_copy") {
			return
		}
	}

	for _ in 0..<500 {
		n := big.DIGIT(rand.uint64())
		d := big.DIGIT(rand.uint64())
		if rand.int_max(2) == 0 {
			n >>= uint(rand.int_max(64))
			d >>= uint(rand.int_max(64))
		}

		r: big.Rat
		defer big.destroy(&r)

		err := big.rat_set_frac_digit(&r, n, d)
		if d == 0 {
			testing.expect_value(t, err, big.Error.Division_by_Zero)
			continue
		}
		testing.expect_value(t, err, nil)

		nn, dd: big.Int
		defer big.destroy(&nn, &dd)

		big.set(&nn, n)
		big.set(&dd, d)
		if !expect_rat(t, &r, &nn, &dd, "rat_set_frac_digit") {
			return
		}
	}

	r: big.Rat
	defer big.destroy(&r)

	one, minus_two: big.Int
	defer big.destroy(&one, &minus_two)

	big.set(&one, 1)
	big.set(&minus_two, -2)

	testing.expect_value(t, big.rat_set_frac_int(&r, &one, &minus_two), nil)
	expect_rat(t, &r, &one, &minus_two, "1/-2")

	testing.expect_value(t, big.rat_set_frac_int(&r, &minus_two, &minus_two), nil)
	expect_rat(t, &r, &one, &one, "-2/-2")
}

@(test)
test_rat_set_integers :: proc(t: ^testing.T) {
	r: big.Rat
	defer big.destroy(&r)

	one, n: big.Int
	defer big.destroy(&one, &n)

	big.set(&one, 1)

	values := [?]i64{0, 1, -1, max(i64), min(i64)}
	for v in values {
		big.set(&n, v)
		testing.expect_value(t, big.rat_set_i64(&r, v), nil)
		expect_rat(t, &r, &n, &one, "rat_set_i64")
		testing.expect(t, big.rat_is_int(&r))
	}

	big.set(&n, max(u64))
	testing.expect_value(t, big.rat_set_u64(&r, max(u64)), nil)
	expect_rat(t, &r, &n, &one, "rat_set_u64")

	big.set(&n, 12345)
	testing.expect_value(t, big.rat_set_digit(&r, 12345), nil)
	expect_rat(t, &r, &n, &one, "rat_set_digit")

	big.set(&n, -6)
	testing.expect_value(t, big.rat_set_int(&r, &n), nil)
	expect_rat(t, &r, &n, &one, "rat_set_int")
}

@(test)
test_rat_abs_neg_is_int :: proc(t: ^testing.T) {
	pool := new(Pool)
	defer free(pool)

	make_pool(pool)
	defer destroy_pool(pool)

	for &x in pool.rats {
		den := den_copy(&x)
		defer big.destroy(&den)

		want_int := den_is_one(&x) || x.a.used == 0
		testing.expectf(t, big.rat_is_int(&x) == want_int, "rat_is_int(%s)", rat_str(&x))

		n: big.Int
		defer big.destroy(&n)

		r: big.Rat
		defer big.destroy(&r)

		big.abs(&n, &x.a)
		testing.expect_value(t, big.rat_abs(&r, &x), nil)
		if !expect_rat(t, &r, &n, &den, "rat_abs") {
			return
		}

		big.neg(&n, &x.a)
		testing.expect_value(t, big.rat_neg(&r, &x), nil)
		if !expect_rat(t, &r, &n, &den, "rat_neg") {
			return
		}

		testing.expect_value(t, big.rat_set_rat(&r, &x), nil)
		if !expect_rat(t, &r, &x.a, &den, "rat_set_rat") {
			return
		}
	}
}

@(test)
test_rat_set_f64 :: proc(t: ^testing.T) {
	values := [?]f64{
		0, -0.0, 1, -1, 0.5, 0.1, -0.75, 3, 1e300, -1e-300,
		math.F64_MAX, -math.F64_MAX, 2.2250738585072014e-308, 5e-324, -5e-324,
		1 << 53, 1 << 53 + 2, 123456789.125,
	}
	for v in values {
		if !check_set_f64(t, v) {
			return
		}
	}
	for _ in 0..<2000 {
		v := transmute(f64)rand.uint64()
		if math.is_nan(v) || math.is_inf(v) {
			continue
		}
		if !check_set_f64(t, v) {
			return
		}
	}

	r: big.Rat
	defer big.destroy(&r)

	testing.expect_value(t, big.rat_set_f64(&r, math.nan_f64()), nil)
	testing.expectf(t, .NaN in r.a.flags, "NaN: flags = %v", r.a.flags)

	testing.expect_value(t, big.rat_set_f64(&r, math.inf_f64(1)), nil)
	testing.expectf(t, .Inf in r.a.flags, "+Inf: flags = %v", r.a.flags)
	testing.expectf(t, r.a.sign == .Zero_or_Positive, "+Inf: sign = %v", r.a.sign)

	testing.expect_value(t, big.rat_set_f64(&r, math.inf_f64(-1)), nil)
	testing.expectf(t, .Inf in r.a.flags, "-Inf: flags = %v", r.a.flags)
	testing.expectf(t, r.a.sign == .Negative, "-Inf: sign = %v", r.a.sign)

	testing.expect_value(t, big.rat_set_f64(&r, 0.25), nil)
	testing.expectf(t, r.a.flags == {}, "0.25 after -Inf: flags = %v", r.a.flags)
}

@(test)
test_rat_to_float :: proc(t: ^testing.T) {
	x: big.Rat
	defer big.destroy(&x)

	n, d: big.Int
	defer big.destroy(&n, &d)

	// Values either side of each float type's precision, exact ties among them.
	precisions := [?]int{11, 24, 53}
	offsets    := [?]int{-1, 0, 1, 2, 3}
	for p in precisions {
		den_bits := [?]int{0, 1, 2, p-1, p, p+1}
		for offset in offsets {
			for bits in den_bits {
				big.set(&n, 1)
				big.shl(&n, &n, p)
				if offset < 0 {
					big.sub(&n, &n, 1)
				} else {
					big.add(&n, &n, big.DIGIT(offset))
				}

				big.set(&d, 1)
				big.shl(&d, &d, bits)
				if bits > 2 {
					big.add(&d, &d, 1)
				}

				set_rat(&x, &n, &d)
				if !check_to_float(t, &x) {
					return
				}

				big.neg(&x.a, &x.a)
				if !check_to_float(t, &x) {
					return
				}
			}
		}
	}

	ranges := [?][2]int{{1, 12}, {1, 25}, {1, 54}, {50, 70}, {1, 200}}
	for _ in 0..<1500 {
		for r in ranges {
			random_int(&n, r[0] + rand.int_max(r[1] - r[0] + 1))
			random_int(&d, r[0] + rand.int_max(r[1] - r[0] + 1))
			nonzero(&d)

			set_rat(&x, &n, &d)
			if !check_to_float(t, &x) {
				return
			}
		}
	}

	// Results in the subnormal ranges and past either end.
	exponents := [?]int{-1080, -1074, -1060, -160, -150, -140, -30, -25, -20, 20, 120, 130, 1030}
	for e in exponents {
		random_int(&n, 60)
		nonzero(&n)

		big.set(&d, 1)
		if e < 0 {
			big.shl(&d, &d, -e)
		} else {
			big.shl(&n, &n, e)
		}

		set_rat(&x, &n, &d)
		if !check_to_float(t, &x) {
			return
		}
	}
}

@(test)
test_rat_zero_value :: proc(t: ^testing.T) {
	zero_value: big.Rat

	half, z: big.Rat
	defer big.destroy(&half, &z)

	big.rat_set_frac(&half, big.DIGIT(1), big.DIGIT(2))

	testing.expect(t, big.rat_is_zero(&zero_value))
	testing.expect(t, big.rat_is_int(&zero_value))

	f, exact, err := big.rat_to_f64(&zero_value)
	testing.expect_value(t, f, 0)
	testing.expect(t, exact)
	testing.expect_value(t, err, nil)

	c, c_err := big.rat_compare(&zero_value, &half)
	testing.expect_value(t, c, -1)
	testing.expect_value(t, c_err, nil)

	n, d: big.Int
	defer big.destroy(&n, &d)

	big.set(&n, 0)
	big.set(&d, 1)
	testing.expect_value(t, big.rat_set_rat(&z, &zero_value), nil)
	expect_rat(t, &z, &n, &d, "rat_set_rat(Rat{})")

	testing.expect_value(t, big.rat_mul_rat(&z, &zero_value, &half), nil)
	expect_rat(t, &z, &n, &d, "Rat{} * 1/2")

	testing.expect_value(t, big.rat_div_rat(&z, &half, &zero_value), big.Error.Division_by_Zero)

	// None of the above writes to its operand.
	testing.expect_value(t, cap(zero_value.a.digit), 0)
	testing.expect_value(t, cap(zero_value.b.digit), 0)

	sum: big.Rat
	defer big.destroy(&sum)

	for _ in 0..<3 {
		testing.expect_value(t, big.rat_add_rat(&sum, &sum, &half), nil)
	}
	big.set(&n, 3)
	big.set(&d, 2)
	expect_rat(t, &sum, &n, &d, "Rat{} + 1/2 + 1/2 + 1/2")
}

@(test)
test_rat_zero_denominator :: proc(t: ^testing.T) {
	// 3/0, with `b` never set and with `b` set to zero.
	for b_set in ([2]bool{false, true}) {
		x, half, z: big.Rat
		defer big.destroy(&x, &half, &z)

		big.set(&x.a, 3)
		if b_set {
			big.set(&x.b, 0)
		}
		big.rat_set_frac(&half, big.DIGIT(1), big.DIGIT(2))

		n: big.Int
		defer big.destroy(&n)

		big.set(&n, 5)

		errors := [?]big.Error{
			big.rat_add_rat(&z, &x, &half),
			big.rat_sub_rat(&z, &half, &x),
			big.rat_mul_rat(&z, &x, &half),
			big.rat_mul_rat(&z, &x, &x),
			big.rat_div_rat(&z, &x, &half),
			big.rat_div_rat(&z, &half, &x),
			big.rat_add_int(&z, &x, &n),
			big.rat_sub_int(&z, &x, &n),
			big.rat_mul_int(&z, &x, &n),
			big.rat_div_int(&z, &x, &n),
			big.int_add_rat(&z, &n, &x),
			big.int_sub_rat(&z, &n, &x),
			big.int_mul_rat(&z, &n, &x),
			big.int_div_rat(&z, &n, &x),
			big.rat_set_rat(&z, &x),
			big.rat_copy(&z, &x),
			big.rat_abs(&z, &x),
			big.rat_neg(&z, &x),
			big.internal_rat_norm(&x),
		}
		for err, i in errors {
			testing.expectf(t, err == .Division_by_Zero, "b_set=%v, case %d: err = %v", b_set, i, err)
		}

		_, compare_err := big.rat_compare(&half, &x)
		testing.expect_value(t, compare_err, big.Error.Division_by_Zero)

		_, positive_err := big.rat_is_positive(&x)
		testing.expect_value(t, positive_err, big.Error.Division_by_Zero)

		_, even_err := big.rat_is_even(&x)
		testing.expect_value(t, even_err, big.Error.Division_by_Zero)

		f, exact, f_err := big.rat_to_f64(&x)
		testing.expect(t, math.is_nan(f))
		testing.expect(t, !exact)
		testing.expect_value(t, f_err, big.Error.Division_by_Zero)

		testing.expect(t, !big.rat_is_int(&x))

		// `x` is left as it was.
		testing.expect_value(t, x.a.used, 1)
		testing.expect_value(t, x.a.sign, big.Sign.Zero_or_Positive)
		testing.expect_value(t, x.b.used, 0)
	}
}

// Checks `x op y` with a fresh `dst`, then with `dst` aliasing `x` and `y`.
@(private="file", require_results)
check_bin_op :: proc(t: ^testing.T, op: Bin_Op, x, y: ^big.Rat, loc := #caller_location) -> (ok: bool) {
	n, d: big.Int
	defer big.destroy(&n, &d)

	valid := reference_bin_op(op, &n, &d, x, y)

	z: big.Rat
	defer big.destroy(&z)

	err := apply_bin_op(op, &z, x, y)
	expect_op(t, err, valid, op, x, y, "", loc) or_return
	if !valid {
		return true
	}

	problem := rat_problem(&z, &n, &d)
	if problem != "" {
		return fail_op(t, op, x, y, "", &z, problem, &n, &d, loc)
	}

	w: big.Rat
	defer big.destroy(&w)

	copy_rat(&w, x)
	err = apply_bin_op(op, &w, &w, y)
	expect_op(t, err, true, op, x, y, "dst=x", loc) or_return
	expect_same(t, &w, &z, op, x, y, "dst=x", loc) or_return

	copy_rat(&w, y)
	err = apply_bin_op(op, &w, x, &w)
	expect_op(t, err, true, op, x, y, "dst=y", loc) or_return
	return expect_same(t, &w, &z, op, x, y, "dst=y", loc)
}

// Checks `x op x` with a fresh `dst` and with `dst` aliasing both operands.
@(private="file", require_results)
check_bin_op_self :: proc(t: ^testing.T, op: Bin_Op, x: ^big.Rat, loc := #caller_location) -> (ok: bool) {
	n, d: big.Int
	defer big.destroy(&n, &d)

	valid := reference_bin_op(op, &n, &d, x, x)

	z: big.Rat
	defer big.destroy(&z)

	err := apply_bin_op(op, &z, x, x)
	expect_op(t, err, valid, op, x, x, "x=y", loc) or_return
	if !valid {
		return true
	}

	problem := rat_problem(&z, &n, &d)
	if problem != "" {
		return fail_op(t, op, x, x, "x=y", &z, problem, &n, &d, loc)
	}

	w: big.Rat
	defer big.destroy(&w)

	copy_rat(&w, x)
	err = apply_bin_op(op, &w, &w, &w)
	expect_op(t, err, true, op, x, x, "dst=x=y", loc) or_return
	return expect_same(t, &w, &z, op, x, x, "dst=x=y", loc)
}

@(private="file", require_results)
check_int_op :: proc(t: ^testing.T, op: Int_Op, x: ^big.Rat, n: ^big.Int, loc := #caller_location) -> (ok: bool) {
	// `n` as `n/1`, for the reference and the messages.
	nr: big.Rat
	defer big.destroy(&nr)

	big.int_copy(&nr.a, n)
	big.set(&nr.b, 1)

	want_n, want_d: big.Int
	defer big.destroy(&want_n, &want_d)

	valid: bool
	switch op {
	case .Rat_Add_Int: valid = reference_bin_op(.Add, &want_n, &want_d, x, &nr)
	case .Rat_Sub_Int: valid = reference_bin_op(.Sub, &want_n, &want_d, x, &nr)
	case .Rat_Mul_Int: valid = reference_bin_op(.Mul, &want_n, &want_d, x, &nr)
	case .Rat_Div_Int: valid = reference_bin_op(.Div, &want_n, &want_d, x, &nr)
	case .Int_Add_Rat: valid = reference_bin_op(.Add, &want_n, &want_d, &nr, x)
	case .Int_Sub_Rat: valid = reference_bin_op(.Sub, &want_n, &want_d, &nr, x)
	case .Int_Mul_Rat: valid = reference_bin_op(.Mul, &want_n, &want_d, &nr, x)
	case .Int_Div_Rat: valid = reference_bin_op(.Div, &want_n, &want_d, &nr, x)
	}

	z: big.Rat
	defer big.destroy(&z)

	err := apply_int_op(op, &z, x, n)
	expect_op(t, err, valid, op, x, &nr, "", loc) or_return
	if !valid {
		return true
	}

	problem := rat_problem(&z, &want_n, &want_d)
	if problem != "" {
		return fail_op(t, op, x, &nr, "", &z, problem, &want_n, &want_d, loc)
	}

	w: big.Rat
	defer big.destroy(&w)

	copy_rat(&w, x)
	err = apply_int_op(op, &w, &w, n)
	expect_op(t, err, true, op, x, &nr, "dst=x", loc) or_return
	return expect_same(t, &w, &z, op, x, &nr, "dst=x", loc)
}

@(private="file")
apply_bin_op :: proc(op: Bin_Op, dst, x, y: ^big.Rat) -> big.Error {
	switch op {
	case .Add: return big.rat_add_rat(dst, x, y)
	case .Sub: return big.rat_sub_rat(dst, x, y)
	case .Mul: return big.rat_mul_rat(dst, x, y)
	case .Div: return big.rat_div_rat(dst, x, y)
	}
	return nil
}

@(private="file")
apply_int_op :: proc(op: Int_Op, dst, x: ^big.Rat, n: ^big.Int) -> big.Error {
	switch op {
	case .Rat_Add_Int: return big.rat_add_int(dst, x, n)
	case .Rat_Sub_Int: return big.rat_sub_int(dst, x, n)
	case .Rat_Mul_Int: return big.rat_mul_int(dst, x, n)
	case .Rat_Div_Int: return big.rat_div_int(dst, x, n)
	case .Int_Add_Rat: return big.int_add_rat(dst, n, x)
	case .Int_Sub_Rat: return big.int_sub_rat(dst, n, x)
	case .Int_Mul_Rat: return big.int_mul_rat(dst, n, x)
	case .Int_Div_Rat: return big.int_div_rat(dst, n, x)
	}
	return nil
}

// Sets `n/d` to the unreduced value of `x op y`. False on division by zero.
@(private="file", require_results)
reference_bin_op :: proc(op: Bin_Op, n, d: ^big.Int, x, y: ^big.Rat) -> (ok: bool) {
	den_x := den_copy(x)
	den_y := den_copy(y)
	defer big.destroy(&den_x, &den_y)

	t: big.Int
	defer big.destroy(&t)

	switch op {
	case .Add:
		big.mul(n, &x.a, &den_y)
		big.mul(&t, &y.a, &den_x)
		big.add(n, n, &t)
		big.mul(d, &den_x, &den_y)

	case .Sub:
		big.mul(n, &x.a, &den_y)
		big.mul(&t, &y.a, &den_x)
		big.sub(n, n, &t)
		big.mul(d, &den_x, &den_y)

	case .Mul:
		big.mul(n, &x.a, &y.a)
		big.mul(d, &den_x, &den_y)

	case .Div:
		if y.a.used == 0 {
			return false
		}
		big.mul(n, &x.a, &den_y)
		big.mul(d, &den_x, &y.a)
	}
	return true
}

// Returns what is wrong with `r` as the canonical form of `n/d` (`d` may be negative), or "".
@(private="file", require_results)
rat_problem :: proc(r: ^big.Rat, n, d: ^big.Int) -> string {
	if r.b.used == 0 {
		return "denominator not set"
	}

	den := den_copy(r)
	defer big.destroy(&den)

	l, rr, g: big.Int
	defer big.destroy(&l, &rr, &g)

	big.mul(&l, &r.a, d)
	big.mul(&rr, n, &den)
	equal, _ := big.equals(&l, &rr)
	if !equal {
		return "wrong value"
	}

	if den.sign == .Negative || den.used == 0 || r.b.sign == .Negative {
		return "denominator not positive"
	}

	if r.a.used == 0 {
		one, _ := big.equals(&den, 1)
		if !one {
			return "zero with a denominator other than 1"
		}
		if r.a.sign == .Negative {
			return "negative zero"
		}
		return ""
	}

	big.int_gcd(&g, &r.a, &den)
	one, _ := big.equals(&g, 1)
	if !one {
		return "not reduced"
	}
	return ""
}

@(private="file")
expect_rat :: proc(t: ^testing.T, r: ^big.Rat, n, d: ^big.Int, what: string, loc := #caller_location) -> (ok: bool) {
	problem := rat_problem(r, n, d)
	if problem != "" {
		return testing.expectf(t, false, "%s: got %s, want %s/%s: %s", what, rat_str(r), int_str(n), int_str(d), problem, loc=loc)
	}
	return true
}

@(private="file")
expect_op :: proc(t: ^testing.T, err: big.Error, valid: bool, op: $Op, x, y: ^big.Rat, alias: string, loc: runtime.Source_Code_Location) -> (ok: bool) {
	want := big.Error.None if valid else big.Error.Division_by_Zero
	if err != want {
		return testing.expectf(t, false, "%v(%s, %s) %s: err = %v, want %v", op, rat_str(x), rat_str(y), alias, err, want, loc=loc)
	}
	return true
}

@(private="file")
fail_op :: proc(t: ^testing.T, op: $Op, x, y: ^big.Rat, alias: string, got: ^big.Rat, problem: string, n, d: ^big.Int, loc: runtime.Source_Code_Location) -> bool {
	return testing.expectf(t, false, "%v(%s, %s) %s = %s, want %s/%s: %s", op, rat_str(x), rat_str(y), alias, rat_str(got), int_str(n), int_str(d), problem, loc=loc)
}

// Expects `got` to equal `want` digit for digit, with `b` set.
@(private="file")
expect_same :: proc(t: ^testing.T, got, want: ^big.Rat, op: $Op, x, y: ^big.Rat, alias: string, loc: runtime.Source_Code_Location) -> (ok: bool) {
	a_equal, _ := big.equals(&got.a, &want.a)
	b_equal, _ := big.equals(&got.b, &want.b)
	if !(a_equal && b_equal) || got.a.sign != want.a.sign || got.b.used == 0 {
		return testing.expectf(t, false, "%v(%s, %s) %s = %s, want %s", op, rat_str(x), rat_str(y), alias, rat_str(got), rat_str(want), loc=loc)
	}
	return true
}

@(private="file")
check_set_f64 :: proc(t: ^testing.T, v: f64) -> (ok: bool) {
	r: big.Rat
	defer big.destroy(&r)

	testing.expect_value(t, big.rat_set_f64(&r, v), nil) or_return

	n, d: big.Int
	defer big.destroy(&n, &d)

	float_exact(&n, &d, v)
	return expect_rat(t, &r, &n, &d, fmt.tprintf("rat_set_f64(%v)", v))
}

@(private="file")
check_to_float :: proc(t: ^testing.T, x: ^big.Rat) -> (ok: bool) {
	f64_value, f64_exact, f64_err := big.rat_to_f64(x)
	testing.expect_value(t, f64_err, nil) or_return
	check_rounding(t, x, f64_value, f64_exact) or_return

	f32_value, f32_exact, f32_err := big.rat_to_f32(x)
	testing.expect_value(t, f32_err, nil) or_return
	check_rounding(t, x, f32_value, f32_exact) or_return

	f16_value, f16_exact, f16_err := big.rat_to_f16(x)
	testing.expect_value(t, f16_err, nil) or_return
	return check_rounding(t, x, f16_value, f16_exact)
}

// Expects `f` to be `x` rounded to nearest with ties to even, and `exact` to say whether `f` equals `x`.
@(private="file")
check_rounding :: proc(t: ^testing.T, x: ^big.Rat, f: $T, exact: bool) -> (ok: bool) {
	if math.is_inf(f) {
		if exact {
			return testing.expectf(t, false, "%v(%s) = %v but exact", typeid_of(T), rat_str(x), f)
		}
		return true
	}

	fn, fd: big.Int
	defer big.destroy(&fn, &fd)

	float_exact(&fn, &fd, f64(f))
	equal := distance_is_zero(x, &fn, &fd)
	if exact != equal {
		return testing.expectf(t, false, "%v(%s) = %v: exact = %v, want %v", typeid_of(T), rat_str(x), f, exact, equal)
	}

	neighbours := [2]T{
		math.nextafter(f, inf_of(T, -1)),
		math.nextafter(f, inf_of(T,  1)),
	}
	for g in neighbours {
		if math.is_inf(g) {
			continue
		}

		gn, gd: big.Int
		defer big.destroy(&gn, &gd)

		float_exact(&gn, &gd, f64(g))
		c := distance_compare(x, &fn, &fd, &gn, &gd)
		if c > 0 {
			return testing.expectf(t, false, "%v(%s) = %v but %v is nearer", typeid_of(T), rat_str(x), f, g)
		}
		if c == 0 && float_bits(f) & 1 != 0 {
			return testing.expectf(t, false, "%v(%s) = %v: a tie rounded to odd", typeid_of(T), rat_str(x), f)
		}
	}
	return true
}

@(private="file")
inf_of :: proc($T: typeid, sign: int) -> T {
	when T == f16 {
		return math.inf_f16(sign)
	} else when T == f32 {
		return math.inf_f32(sign)
	} else {
		return math.inf_f64(sign)
	}
}

@(private="file")
float_bits :: proc(f: $T) -> u64 {
	when T == f16 {
		return u64(transmute(u16)f)
	} else when T == f32 {
		return u64(transmute(u32)f)
	} else {
		return transmute(u64)f
	}
}

// |x - f| == 0, with f = fn/fd.
@(private="file")
distance_is_zero :: proc(x: ^big.Rat, fn, fd: ^big.Int) -> bool {
	den := den_copy(x)
	defer big.destroy(&den)

	l, r: big.Int
	defer big.destroy(&l, &r)

	big.mul(&l, &x.a, fd)
	big.mul(&r, fn, &den)
	equal, _ := big.equals(&l, &r)
	return equal
}

// Compares |x - f| with |x - g|: |a/b - fn/fd| = |a*fd - fn*b| / (b*fd), and the common `b` cancels.
@(private="file")
distance_compare :: proc(x: ^big.Rat, fn, fd, gn, gd: ^big.Int) -> int {
	den := den_copy(x)
	defer big.destroy(&den)

	df, dg, t: big.Int
	defer big.destroy(&df, &dg, &t)

	big.mul(&df, &x.a, fd)
	big.mul(&t, fn, &den)
	big.sub(&df, &df, &t)
	big.abs(&df, &df)

	big.mul(&dg, &x.a, gd)
	big.mul(&t, gn, &den)
	big.sub(&dg, &dg, &t)
	big.abs(&dg, &dg)

	big.mul(&df, &df, gd)
	big.mul(&dg, &dg, fd)
	c, _ := big.cmp(&df, &dg)
	return c
}

// Sets `n/d` to the exact value of `v`.
@(private="file")
float_exact :: proc(n, d: ^big.Int, v: f64) {
	bits     := transmute(u64)v
	exponent := int(bits >> 52 & 0x7ff)
	mantissa := bits & (1 << 52 - 1)
	if exponent == 0 {
		exponent = 1
	} else {
		mantissa |= 1 << 52
	}
	e := exponent - 1075

	big.set(n, mantissa)
	big.set(d, 1)
	if e >= 0 {
		big.shl(n, n, e)
	} else {
		big.shl(d, d, -e)
	}
	if bits >> 63 != 0 {
		big.neg(n, n)
	}
}

@(private="file")
make_pool :: proc(pool: ^Pool) {
	add :: proc(pool: ^Pool, i: ^int, n, d: ^big.Int) {
		set_rat(&pool.rats[i^], n, d)
		i^ += 1
	}

	n, d, smooth, shared: big.Int
	defer big.destroy(&n, &d, &smooth, &shared)

	// Factors shared between denominators: one small and smooth, one of several digits.
	big.set(&smooth, 720720)
	random_int(&shared, 140)
	big.abs(&shared, &shared)
	big.add(&shared, &shared, 1)

	i := 0

	big.set(&n, 0)
	big.set(&d, 1)
	add(pool, &i, &n, &d)

	// The zero value `Rat{}`.
	i += 1

	boundary := [?]u64{1, 2, 3, 1 << 62 + 1, 1 << 63 - 2, 1 << 63 - 1, 1 << 63, max(u64)}
	for v, k in boundary {
		big.set(&n, v)
		big.set(&d, boundary[(k*3+2) % len(boundary)])
		random_sign(&n)
		add(pool, &i, &n, &d)
	}

	for _ in 0..<10 {
		random_int(&n, 1 + rand.int_max(62))
		random_int(&d, 1 + rand.int_max(62))
		nonzero(&d)
		add(pool, &i, &n, &d)
	}

	for _ in 0..<6 {
		random_int(&n, 64 + rand.int_max(63))
		random_int(&d, 64 + rand.int_max(63))
		nonzero(&d)
		add(pool, &i, &n, &d)
	}

	for _ in 0..<5 {
		random_int(&n, 130 + rand.int_max(300))
		random_int(&d, 130 + rand.int_max(300))
		nonzero(&d)
		add(pool, &i, &n, &d)
	}

	integer_bits := [?]int{20, 62, 63, 100, 300}
	for bits in integer_bits {
		random_int(&n, bits)
		big.set(&d, 1)
		add(pool, &i, &n, &d)
	}

	for k in 0..<8 {
		random_int(&n, 1 + rand.int_max(60))
		random_int(&d, 1 + rand.int_max(40))
		nonzero(&d)
		if k < 5 {
			big.mul(&d, &d, &smooth)
		} else {
			big.mul(&d, &d, &shared)
		}
		if k % 2 == 1 {
			big.mul(&n, &n, &smooth)
		}
		add(pool, &i, &n, &d)
	}

	for k in 0..<6 {
		random_int(&n, 1 + rand.int_max(150))
		if k < 3 {
			big.mul(&n, &n, &shared)
		} else {
			big.mul(&n, &n, &smooth)
		}
		random_int(&d, 1 + rand.int_max(150))
		nonzero(&d)
		add(pool, &i, &n, &d)
	}

	for i < POOL_RATS {
		random_int(&n, 1 + rand.int_max(126))
		random_int(&d, 1 + rand.int_max(126))
		nonzero(&d)
		add(pool, &i, &n, &d)
	}

	ints := [?]i64{0, 1, -1, 7, -720720, max(i64), min(i64)}
	for v, k in ints {
		big.set(&pool.ints[k], v)
	}
	for k in len(ints)..<POOL_INTS {
		x := &pool.ints[k]
		switch k % 4 {
		case 0: random_int(x, 62)
		case 1: random_int(x, 126)
		case 2: random_int(x, 300)
		case 3:
			random_int(x, 60)
			big.mul(x, x, &shared)
		}
	}
}

@(private="file")
destroy_pool :: proc(pool: ^Pool) {
	for &r in pool.rats {
		big.destroy(&r)
	}
	for &n in pool.ints {
		big.destroy(&n)
	}
}

// Sets `r` to `n/d` in canonical form using `Int` arithmetic only.
@(private="file")
set_rat :: proc(r: ^big.Rat, n, d: ^big.Int) {
	g, nn, dd: big.Int
	defer big.destroy(&g, &nn, &dd)

	big.int_gcd(&g, n, d)
	big.int_div(&nn, n, &g)
	big.int_div(&dd, d, &g)
	if dd.sign == .Negative {
		big.neg(&nn, &nn)
		big.neg(&dd, &dd)
	}

	big.destroy(r)
	big.int_copy(&r.a, &nn)
	big.int_copy(&r.b, &dd)
}

// Copies `src` exactly, keeping unset parts unset.
@(private="file")
copy_rat :: proc(dst, src: ^big.Rat) {
	big.destroy(dst)
	if src.a.used > 0 {
		big.int_copy(&dst.a, &src.a)
	}
	if src.b.used > 0 {
		big.int_copy(&dst.b, &src.b)
	}
}

@(private="file", require_results)
den_copy :: proc(r: ^big.Rat) -> (d: big.Int) {
	if r.b.used == 0 {
		big.set(&d, 1)
	} else {
		big.int_copy(&d, &r.b)
	}
	return
}

@(private="file", require_results)
den_is_one :: proc(r: ^big.Rat) -> bool {
	return r.b.used == 0 || (r.b.used == 1 && r.b.digit[0] == 1)
}

@(private="file", require_results)
is_zero_int :: proc(x: ^big.Int) -> bool {
	zero, _ := big.is_zero(x)
	return zero
}

@(private="file")
random_int :: proc(x: ^big.Int, bits: int) {
	big.int_random(x, bits)
	random_sign(x)
}

@(private="file")
random_sign :: proc(x: ^big.Int) {
	if rand.int_max(2) == 0 {
		big.neg(x, x)
	}
}

@(private="file")
nonzero :: proc(x: ^big.Int) {
	if is_zero_int(x) {
		big.set(x, 1)
	}
}

@(private="file", require_results)
int_str :: proc(x: ^big.Int) -> string {
	s, _ := big.int_itoa_string(x, 10, false, context.temp_allocator)
	return s
}

@(private="file", require_results)
rat_str :: proc(r: ^big.Rat) -> string {
	if r.b.used == 0 {
		return fmt.tprintf("%s/<unset>", int_str(&r.a))
	}
	return fmt.tprintf("%s/%s", int_str(&r.a), int_str(&r.b))
}
