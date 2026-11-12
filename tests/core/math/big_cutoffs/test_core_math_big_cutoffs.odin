package test_core_math_big_cutoffs

import "core:math/big"
import "core:testing"

@(private="file")
ones :: proc(a: ^big.Int, limbs: int) {
	big.power_of_two(a, limbs * big._DIGIT_BITS)
	big.sub(a, a, 1)
}

@(private="file")
ones_product :: proc(e, tmp: ^big.Int, m, n: int) {
	big.power_of_two(e, (m + n) * big._DIGIT_BITS)
	big.add(e, e, 1)
	big.power_of_two(tmp, m * big._DIGIT_BITS)
	big.sub(e, e, tmp)
	big.power_of_two(tmp, n * big._DIGIT_BITS)
	big.sub(e, e, tmp)
}

@(private="file")
random_limbs :: proc(a, tmp: ^big.Int, limbs: int) {
	big.int_random(a, limbs * big._DIGIT_BITS - 1)
	big.power_of_two(tmp, limbs * big._DIGIT_BITS - 1)
	big.add(a, a, tmp)
}

@(test)
test_cutoffs_mul :: proc(t: ^testing.T) {
	a, b, c, e, tmp := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, c, e, tmp)

	for m in 1..=24 {
		for n in 1..=24 {
			ones(a, m)
			ones(b, n)
			ones_product(e, tmp, m, n)
			testing.expect_value(t, big.mul(c, a, b), nil)
			equal, _ := big.equals(c, e)
			testing.expectf(t, equal, "mul of %v and %v limbs of ones is wrong", m, n)

			random_limbs(a, tmp, m)
			random_limbs(b, tmp, n)
			testing.expect_value(t, big.mul(c, a, b), nil)
			testing.expect_value(t, big._private_int_mul(e, a, b, a.used + b.used + 1), nil)
			big.clamp(e)
			equal, _ = big.equals(c, e)
			testing.expectf(t, equal, "mul of random %v and %v limbs differs from schoolbook", m, n)
		}
	}
}

@(test)
test_cutoffs_sqr :: proc(t: ^testing.T) {
	a, c, e, tmp := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, c, e, tmp)

	for m in 1..=60 {
		ones(a, m)
		ones_product(e, tmp, m, m)
		testing.expect_value(t, big.sqr(c, a), nil)
		equal, _ := big.equals(c, e)
		testing.expectf(t, equal, "sqr of %v limbs of ones is wrong", m)

		random_limbs(a, tmp, m)
		testing.expect_value(t, big.sqr(c, a), nil)
		testing.expect_value(t, big._private_int_sqr(e, a), nil)
		big.clamp(e)
		equal, _ = big.equals(c, e)
		testing.expectf(t, equal, "sqr of random %v limbs differs from schoolbook", m)
	}
}

@(test)
test_cutoffs_divmod :: proc(t: ^testing.T) {
	a, b, q, r, q2, r2, c, tmp := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, q, r, q2, r2, c, tmp)

	for m in 1..=48 {
		for n in 1..=m {
			for pattern in 0..<4 {
				if pattern == 0 {
					ones(a, m)
					ones(b, n)
				} else {
					random_limbs(a, tmp, m)
					random_limbs(b, tmp, n)
					if pattern & 1 == 1 { big.neg(a, a) }
					if pattern & 2 == 2 { big.neg(b, b) }
				}
				testing.expect_value(t, big.divmod(q, r, a, b), nil)
				testing.expect_value(t, big._private_int_div_school(q2, r2, a, b), nil)

				equal_q, _ := big.equals(q, q2)
				equal_r, _ := big.equals(r, r2)
				testing.expectf(t, equal_q && equal_r, "divmod of %v by %v limbs (pattern %v) differs from schoolbook", m, n, pattern)

				big.mul(c, q, b)
				big.add(c, c, r)
				equal, _ := big.equals(c, a)
				testing.expectf(t, equal, "divmod of %v by %v limbs (pattern %v) doesn't round-trip", m, n, pattern)
				less, _ := big.less_than_abs(r, b)
				testing.expectf(t, less, "divmod of %v by %v limbs (pattern %v): remainder isn't below the divisor", m, n, pattern)

				testing.expect_value(t, big._private_int_div_recursive(q2, r2, a, b), nil)
				equal_q, _ = big.equals(q, q2)
				equal_r, _ = big.equals(r, r2)
				testing.expectf(t, equal_q && equal_r, "recursive division of %v by %v limbs (pattern %v) differs from schoolbook", m, n, pattern)
			}
		}
	}
}

@(test)
test_cutoffs_factorial :: proc(t: ^testing.T) {
	res, e := &big.Int{}, &big.Int{}
	defer big.destroy(res, e)

	big.set(e, 1)
	for n in 0..=300 {
		if n > 1 { big.mul(e, e, big.DIGIT(n)) }
		testing.expect_value(t, big.factorial(res, n), nil)
		equal, _ := big.equals(res, e)
		testing.expectf(t, equal, "factorial(%v) is wrong", n)
	}
}
