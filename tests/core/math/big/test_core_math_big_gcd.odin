package test_core_math_big

import "core:math/big"
import "core:math/rand"
import "core:testing"

// `int_gcd_lcm` is checked against Euclid's algorithm written with `int_mod`.

@(test)
test_gcd_random :: proc(t: ^testing.T) {
	a, b: big.Int
	defer big.destroy(&a, &b)

	sizes := [?]int{1, 30, 62, 63, 64, 100, 126, 127, 128, 200, 500, 1000, 3000}
	for size_a in sizes {
		for size_b in sizes {
			for _ in 0..<3 {
				random_signed(&a, size_a)
				random_signed(&b, size_b)
				if !check_gcd(t, &a, &b) {
					return
				}
			}
		}
	}
}

@(test)
test_gcd_common_factor :: proc(t: ^testing.T) {
	a, b, g: big.Int
	defer big.destroy(&a, &b, &g)

	factor_sizes := [?]int{1, 20, 63, 64, 126, 200, 1000}
	sizes        := [?]int{1, 63, 64, 300, 1000}
	for factor_size in factor_sizes {
		for size_a in sizes {
			for size_b in sizes {
				random_signed(&g, factor_size)
				random_signed(&a, size_a)
				random_signed(&b, size_b)
				big.mul(&a, &a, &g)
				big.mul(&b, &b, &g)
				if !check_gcd(t, &a, &b) {
					return
				}
			}
		}
	}
}

@(test)
test_gcd_fibonacci :: proc(t: ^testing.T) {
	// Consecutive Fibonacci numbers make every Euclid quotient 1.
	f0, f1, s0, s1, factor: big.Int
	defer big.destroy(&f0, &f1, &s0, &s1, &factor)

	big.set(&f0, 0)
	big.set(&f1, 1)
	random_signed(&factor, 100)
	big.abs(&factor, &factor)
	big.add(&factor, &factor, 1)

	checked := [?]int{2, 3, 50, 91, 92, 93, 180, 500, 1000, 2000, 4000}
	k := 0
	for n in 1..=4000 {
		big.add(&f0, &f0, &f1)
		big.swap(&f0, &f1)
		if k < len(checked) && n == checked[k] {
			k += 1
			if !check_gcd(t, &f1, &f0) {
				return
			}

			big.mul(&s0, &f0, &factor)
			big.mul(&s1, &f1, &factor)
			if !check_gcd(t, &s1, &s0) {
				return
			}
		}
	}
}

@(test)
test_gcd_shapes :: proc(t: ^testing.T) {
	a, b, c: big.Int
	defer big.destroy(&a, &b, &c)

	// Powers of two times odd numbers.
	shifts := [?]int{0, 1, 62, 63, 64, 130}
	for i in shifts {
		for j in shifts {
			random_signed(&a, 200)
			random_signed(&b, 150)
			big.shl(&a, &a, i)
			big.shl(&b, &b, j)
			if !check_gcd(t, &a, &b) {
				return
			}
		}
	}

	// 2^n - 1 and 2^m - 1, whose gcd is 2^gcd(n, m) - 1. Multiples of 63 bits fill whole digits.
	bit_counts := [?]int{1, 2, 62, 63, 64, 126, 189, 252, 300, 504, 1000}
	for n in bit_counts {
		for m in bit_counts {
			big.set(&a, 1)
			big.shl(&a, &a, n)
			big.sub(&a, &a, 1)
			big.set(&b, 1)
			big.shl(&b, &b, m)
			big.sub(&b, &b, 1)
			if !check_gcd(t, &a, &b) {
				return
			}
		}
	}

	sizes := [?]int{1, 63, 64, 200, 1000}
	for size in sizes {
		random_signed(&a, size)

		// Equal, opposite, one dividing the other, and neighbours.
		if !check_gcd(t, &a, &a) {
			return
		}
		big.neg(&b, &a)
		if !check_gcd(t, &a, &b) {
			return
		}
		random_signed(&c, 100)
		big.mul(&b, &a, &c)
		if !check_gcd(t, &a, &b) || !check_gcd(t, &b, &a) {
			return
		}
		big.add(&b, &a, 1)
		if !check_gcd(t, &a, &b) {
			return
		}

		// Zero on either side, and both.
		big.set(&b, 0)
		if !check_gcd(t, &a, &b) || !check_gcd(t, &b, &a) || !check_gcd(t, &b, &b) {
			return
		}
	}
}

// Checks gcd and lcm of `a` and `b`, with fresh results and with results aliasing the operands.
@(private="file")
check_gcd :: proc(t: ^testing.T, a, b: ^big.Int, loc := #caller_location) -> (ok: bool) {
	want_gcd, want_lcm: big.Int
	defer big.destroy(&want_gcd, &want_lcm)

	euclid_gcd(&want_gcd, a, b)
	if is_zero(&want_gcd) {
		big.set(&want_lcm, 0)
	} else {
		big.mul(&want_lcm, a, b)
		big.abs(&want_lcm, &want_lcm)
		big.int_div(&want_lcm, &want_lcm, &want_gcd)
	}

	g, l: big.Int
	defer big.destroy(&g, &l)

	err := big.int_gcd(&g, a, b)
	expect_int(t, &g, &want_gcd, err, "gcd", a, b, loc) or_return

	err = big.int_gcd_lcm(&g, &l, a, b)
	expect_int(t, &g, &want_gcd, err, "gcd_lcm gcd", a, b, loc) or_return
	expect_int(t, &l, &want_lcm, err, "gcd_lcm lcm", a, b, loc) or_return

	big.int_copy(&g, a)
	err = big.int_gcd(&g, &g, b)
	expect_int(t, &g, &want_gcd, err, "gcd res=a", a, b, loc) or_return

	big.int_copy(&g, b)
	err = big.int_gcd(&g, a, &g)
	expect_int(t, &g, &want_gcd, err, "gcd res=b", a, b, loc) or_return

	big.int_copy(&l, a)
	err = big.int_lcm(&l, &l, b)
	expect_int(t, &l, &want_lcm, err, "lcm res=a", a, b, loc) or_return

	// gcd(a, a) with every argument the same `Int`.
	big.int_copy(&g, a)
	err = big.int_gcd(&g, &g, &g)
	big.abs(&l, a)
	return expect_int(t, &g, &l, err, "gcd res=a=b", a, a, loc)
}

@(private="file")
expect_int :: proc(t: ^testing.T, got, want: ^big.Int, err: big.Error, what: string, a, b: ^big.Int, loc := #caller_location) -> (ok: bool) {
	equal, _ := big.equals(got, want)
	if err != nil || !equal || got.sign == .Negative {
		return testing.expectf(t, false, "%s(%s, %s) = %s, %v; want %s", what, str(a), str(b), str(got), err, str(want), loc=loc)
	}
	return true
}

// gcd(|a|, |b|) by Euclid's algorithm.
@(private="file")
euclid_gcd :: proc(g, a, b: ^big.Int) {
	x, y, r: big.Int
	defer big.destroy(&x, &y, &r)

	big.abs(&x, a)
	big.abs(&y, b)
	for !is_zero(&y) {
		big.int_mod(&r, &x, &y)
		big.swap(&x, &y)
		big.swap(&y, &r)
	}
	big.int_copy(g, &x)
}

@(private="file")
random_signed :: proc(x: ^big.Int, bits: int) {
	big.int_random(x, bits)
	if rand.int_max(2) == 0 {
		big.neg(x, x)
	}
}

@(private="file", require_results)
is_zero :: proc(x: ^big.Int) -> bool {
	zero, _ := big.is_zero(x)
	return zero
}

@(private="file", require_results)
str :: proc(x: ^big.Int) -> string {
	s, _ := big.int_itoa_string(x, 10, false, context.temp_allocator)
	return s
}
