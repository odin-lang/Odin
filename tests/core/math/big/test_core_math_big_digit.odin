package test_core_math_big

import "core:math/big"
import "core:math/rand"
import "core:testing"

// Division by one `DIGIT` is checked against `int_divmod` with the divisor as an `Int`.
// `itoa` is checked by reading its output back with `atoi`.

@(private="file")
DIVISORS :: [?]big.DIGIT{
	1, 2, 3, 5, 7, 10, 1 << 31, 1 << 62, 1 << 63,
	1 << 62 + 1, 1 << 63 - 1, 1 << 63 + 1, max(big.DIGIT),
	1_000_000_000_000_000_000,
}

@(test)
test_divmod_digit :: proc(t: ^testing.T) {
	a: big.Int
	defer big.destroy(&a)

	sizes := [?]int{0, 1, 62, 63, 64, 126, 127, 128, 200, 1000, 4000}
	for bits in sizes {
		for _ in 0..<4 {
			random_signed(&a, bits)

			divisors := DIVISORS
			for d in divisors {
				if !check_divmod_digit(t, &a, d) {
					return
				}
			}
			for _ in 0..<8 {
				d := big.DIGIT(rand.uint64() >> uint(rand.int_max(64)))
				if d != 0 && !check_divmod_digit(t, &a, d) {
					return
				}
			}
		}
	}

	q: big.Int
	defer big.destroy(&q)

	big.set(&a, 12345)
	_, err := big.int_divmod_digit(&q, &a, 0)
	testing.expect_value(t, err, big.Error.Division_by_Zero)
	_, err = big.int_mod_digit(&a, 0)
	testing.expect_value(t, err, big.Error.Division_by_Zero)
}

@(test)
test_digit_reciprocal :: proc(t: ^testing.T) {
	// floor((2^128 - 1) / divisor) - 2^64, for the divisor shifted until its top bit is set.
	all_ones, shifted, want, two_64: big.Int
	defer big.destroy(&all_ones, &shifted, &want, &two_64)

	big.set(&all_ones, max(u128))
	big.set(&two_64, 1)
	big.shl(&two_64, &two_64, 64)

	check :: proc(t: ^testing.T, d: big.DIGIT, all_ones, shifted, want, two_64: ^big.Int) -> bool {
		r := big._private_digit_reciprocal(d)
		big.set(shifted, u64(d))
		big.shl(shifted, shifted, int(r.shift))
		big.int_div(want, all_ones, shifted)
		big.sub(want, want, two_64)
		want_reciprocal, _ := big.get(want, u64)
		want_divisor,    _ := big.get(shifted, u64)
		return testing.expectf(t, r.divisor == want_divisor && r.divisor >> 63 == 1 && r.reciprocal == want_reciprocal, "reciprocal of %d: %v", d, r)
	}

	divisors := DIVISORS
	for d in divisors {
		if !check(t, d, &all_ones, &shifted, &want, &two_64) {
			return
		}
	}
	for _ in 0..<1000 {
		d := big.DIGIT(rand.uint64() >> uint(rand.int_max(64)))
		if d != 0 && !check(t, d, &all_ones, &shifted, &want, &two_64) {
			return
		}
	}
}

@(test)
test_itoa_round_trip :: proc(t: ^testing.T) {
	a, b, ten: big.Int
	defer big.destroy(&a, &b, &ten)

	sizes := [?]int{1, 63, 64, 126, 127, 200, 1000, 4000}
	for bits in sizes {
		random_signed(&a, bits)
		for radix in 2..=64 {
			if !check_round_trip(t, &a, i8(radix)) {
				return
			}
		}
	}

	// Powers of ten, and one less, either side of the chunks `itoa` prints at once.
	big.set(&ten, 10)
	exponents := [?]int{1, 17, 18, 19, 35, 36, 37, 54, 100}
	for e in exponents {
		big.int_pow(&a, &ten, e)
		if !check_round_trip(t, &a, 10) {
			return
		}
		big.sub(&a, &a, 1)
		if !check_round_trip(t, &a, 10) {
			return
		}
	}
}

@(private="file")
check_divmod_digit :: proc(t: ^testing.T, a: ^big.Int, d: big.DIGIT, loc := #caller_location) -> (ok: bool) {
	want_q, want_r, divisor, magnitude: big.Int
	defer big.destroy(&want_q, &want_r, &divisor, &magnitude)

	big.set(&divisor, d)
	big.abs(&magnitude, a)
	big.int_divmod(&want_q, &want_r, &magnitude, &divisor)
	if a.sign == .Negative {
		big.neg(&want_q, &want_q)
	}
	want_rem, _ := big.get(&want_r, u64)
	want_mod := want_rem
	if a.sign == .Negative && want_rem != 0 {
		want_mod = u64(d) - want_rem
	}

	rem, err := big.int_mod_digit(a, d)
	if err != nil || u64(rem) != want_mod {
		return testing.expectf(t, false, "int_mod_digit(%s, %d) = %d, %v; want %d", str(a), d, rem, err, want_mod, loc=loc)
	}

	rem = big._private_int_mod_digit(a, d)
	if u64(rem) != want_rem {
		return testing.expectf(t, false, "_private_int_mod_digit(%s, %d) = %d; want %d", str(a), d, rem, want_rem, loc=loc)
	}

	q: big.Int
	defer big.destroy(&q)

	rem, err = big.int_divmod_digit(&q, a, d)
	expect_quotient(t, &q, &want_q, rem, want_rem, err, "int_divmod_digit", a, d, loc) or_return

	big.int_copy(&q, a)
	rem, err = big.int_divmod_digit(&q, &q, d)
	expect_quotient(t, &q, &want_q, rem, want_rem, err, "int_divmod_digit in place", a, d, loc) or_return

	// A quotient that held a longer number must not keep its old high digits.
	big.set(&q, 1)
	big.shl(&q, &q, 5000)
	big.sub(&q, &q, 1)
	rem, err = big.int_divmod_digit(&q, a, d)
	return expect_quotient(t, &q, &want_q, rem, want_rem, err, "int_divmod_digit into a longer quotient", a, d, loc)
}

@(private="file")
expect_quotient :: proc(t: ^testing.T, q, want_q: ^big.Int, rem: big.DIGIT, want_rem: u64, err: big.Error, what: string, a: ^big.Int, d: big.DIGIT, loc := #caller_location) -> (ok: bool) {
	equal, _ := big.equals(q, want_q)
	clamped  := q.used == 0 || q.digit[q.used-1] != 0
	for i in q.used..<len(q.digit) {
		clamped &&= q.digit[i] == 0
	}
	if err != nil || !equal || !clamped || u64(rem) != want_rem {
		return testing.expectf(t, false, "%s(%s, %d) = %s (used %d), %d, %v; want %s, %d", what, str(a), d, str(q), q.used, rem, err, str(want_q), want_rem, loc=loc)
	}
	return true
}

@(private="file")
check_round_trip :: proc(t: ^testing.T, a: ^big.Int, radix: i8, loc := #caller_location) -> (ok: bool) {
	s, err := big.int_itoa_string(a, radix, false, context.temp_allocator)
	if err != nil {
		return testing.expectf(t, false, "itoa(%s, %d): %v", str(a), radix, err, loc=loc)
	}

	b: big.Int
	defer big.destroy(&b)

	err = big.atoi(&b, s, radix)
	equal, _ := big.equals(&b, a)
	if err != nil || !equal {
		return testing.expectf(t, false, "atoi(itoa(%s, %d) = %q) = %s, %v", str(a), radix, s, str(&b), err, loc=loc)
	}
	return true
}

@(private="file")
random_signed :: proc(x: ^big.Int, bits: int) {
	if bits == 0 {
		big.set(x, 0)
		return
	}
	big.int_random(x, bits)
	if rand.int_max(2) == 0 {
		big.neg(x, x)
	}
}

@(private="file", require_results)
str :: proc(x: ^big.Int) -> string {
	s, _ := big.int_itoa_string(x, 10, false, context.temp_allocator)
	return s
}
