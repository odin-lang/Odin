/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains prime finding operations.
*/


package math_big

/*
	Determines if an Integer is divisible by one of the _PRIME_TABLE primes.
	Returns true if it is, false if not. 
*/
internal_int_prime_is_divisible :: proc(a: ^Int, allocator := context.allocator) -> (res: bool, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	internal_clear_if_uninitialized(a) or_return

	for prime in _private_prime_table {
		rem := #force_inline int_mod_digit(a, prime) or_return
		if rem == 0 {
			return true, nil
		}
	}
	/*
		Default to not divisible.
	*/
	return false, nil
}

/*
	This is a shell function that calls either the normal or Montgomery exptmod functions.
	Originally the call to the Montgomery code was embedded in the normal function but that
	wasted alot of stack space for nothing (since 99% of the time the Montgomery code would be called).

	Computes res == G**X mod P.
	Assumes `res`, `G`, `X` and `P` to not be `nil` and for `G`, `X` and `P` to have been initialized.
*/
internal_int_power_modulo :: proc(res, G, X, P: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	dr: int

	/*
		Modulus P must be positive.
	*/
	if internal_is_negative(P) { return .Invalid_Argument }

	/*
		If exponent X is negative we have to recurse.
	*/
	if internal_is_negative(X) {
		tmpG, tmpX := &Int{}, &Int{}
		defer internal_destroy(tmpG, tmpX)

		internal_init_multi(tmpG, tmpX) or_return

		/*
			First compute 1/G mod P.
		*/
		internal_invmod(tmpG, G, P) or_return

		/*
			now get |X|.
		*/
		internal_abs(tmpX, X) or_return

		/*
			And now compute (1/G)**|X| instead of G**X [X < 0].
		*/
		return internal_int_exponent_mod(res, tmpG, tmpX, P)
	}

	/*
		Modified diminished radix reduction.
	*/
	can_reduce_2k_l := _private_int_reduce_is_2k_l(P) or_return
	if can_reduce_2k_l {
		return _private_int_exponent_mod(res, G, X, P, 1)
	}

	/*
		Is it a DR modulus? default to no.
	*/
	dr = 1 if _private_dr_is_modulus(P) else 0

	/*
		If not, is it a unrestricted DR modulus?
	*/
	if dr == 0 {
		reduce_is_2k := _private_int_reduce_is_2k(P) or_return
		dr = 2 if reduce_is_2k else 0
	}

	/*
		If the modulus is odd or dr != 0 use the montgomery method.
	*/
	if internal_int_is_odd(P) || dr != 0 {
		return _private_int_exponent_mod(res, G, X, P, dr)
	}

	/*
		Otherwise use the generic Barrett reduction technique.
	*/
	return _private_int_exponent_mod(res, G, X, P, 0)
}
internal_int_exponent_mod :: internal_int_power_modulo
internal_int_powmod :: internal_int_power_modulo
internal_powmod :: proc { internal_int_power_modulo, }

/*
	Kronecker/Legendre symbol (a|p)
	Straightforward implementation of algorithm 1.4.10 in
	Henri Cohen: "A Course in Computational Algebraic Number Theory"

	@book{cohen2013course,
		title={A course in computational algebraic number theory},
		author={Cohen, Henri},
		volume={138},
		year={2013},
		publisher={Springer Science \& Business Media}
	}

	Assumes `a` and `p` to not be `nil` and to have been initialized.
*/
internal_int_kronecker :: proc(a, p: ^Int, allocator := context.allocator) -> (kronecker: int, err: Error) {
	context.allocator = allocator

	a1, p1, r := &Int{}, &Int{}, &Int{}
	defer internal_destroy(a1, p1, r)

	table := []int{0, 1, 0, -1, 0, -1, 0, 1}

	if internal_int_is_zero(p) {
		if a.used == 1 && a.digit[0] == 1 {
			return 1, nil
		} else {
			return 0, nil
		}
	}

	if internal_is_even(a) && internal_is_even(p) {
		return 0, nil
	}

	internal_copy(a1, a) or_return
	internal_copy(p1, p) or_return

	v := internal_count_lsb(p1) or_return
	internal_shr(p1, p1, v) or_return

	k := 1 if v & 1 == 0 else table[a.digit[0] & 7]

	if internal_is_negative(p1) {
		p1.sign = .Zero_or_Positive
		if internal_is_negative(a1) {
			k = -k
		}
	}

	internal_zero(r) or_return

	for {
		if internal_is_zero(a1) {
			if internal_eq(p1, 1) {
				return k, nil
			} else {
				return 0, nil
			}
		}

		v = internal_count_lsb(a1) or_return
		internal_shr(a1, a1, v) or_return

		if v & 1 == 1 {
			k = k * table[p1.digit[0] & 7]
		}

		if internal_is_negative(a1) {
			/*
				Compute k = (-1)^((a1)*(p1-1)/4) * k.
				a1.digit[0] + 1 cannot overflow because the MSB
				of the DIGIT type is not set by definition.
			 */
			if ((a1.digit[0] + 1) & p1.digit[0] & 2) != 0 {
				k = -k
			}
		} else {
			/*
				Compute k = (-1)^((a1-1)*(p1-1)/4) * k.
			*/
			if (a1.digit[0] & p1.digit[0] & 2) != 0 {
				k = -k
			}
		}

		internal_copy(r, a1) or_return
		r.sign = .Zero_or_Positive

		internal_mod(a1, p1, r) or_return
		internal_copy(p1, r)    or_return
	}
	return
}
internal_int_legendre :: internal_int_kronecker

/*
	Miller-Rabin test of "a" to the base of "b" as described in HAC pp. 139 Algorithm 4.24.

	Sets result to `false` if definitely composite or `true` if probably prime.
	Randomly the chance of error is no more than 1/4 and often very much lower.

	Assumes `a` and `b` not to be `nil` and to have been initialized.
*/
internal_int_prime_miller_rabin :: proc(a, b: ^Int, allocator := context.allocator) -> (probably_prime: bool, err: Error) {
	context.allocator = allocator

	n1, y, r := &Int{}, &Int{}, &Int{}
	defer internal_destroy(n1, y, r)

	/*
		Ensure `b` > 1.
	*/
	if internal_lte(b, 1) { return false, nil }

	/*
		Get `n1` = `a` - 1.
	*/
	internal_copy(n1, a) or_return
	internal_sub(n1, n1, 1) or_return

	/*
		Set `2`**`s` * `r` = `n1`
	*/
	internal_copy(r, n1) or_return

	/*
		Count the number of least significant bits which are zero.
	*/
	s := internal_count_lsb(r) or_return

	/*
		Now divide `n` - 1 by `2`**`s`.
	*/
	internal_shr(r, r, s) or_return

	/*
		Compute `y` = `b`**`r` mod `a`.
	*/
	internal_int_exponent_mod(y, b, r, a) or_return

	/*
		If `y` != 1 and `y` != `n1` do.
	*/
	if !internal_eq(y, 1) && !internal_eq(y, n1) {
		j := 1

		/*
			While `j` <= `s` - 1 and `y` != `n1`.
		*/
		for j <= (s - 1) && !internal_eq(y, n1) {
			internal_sqrmod(y, y, a) or_return

			/*
				If `y` == 1 then composite.
			*/
			if internal_eq(y, 1) {
				return false, nil
			}

			j += 1
		}

		/*
			If `y` != `n1` then composite.
		*/
		if !internal_eq(y, n1) {
			return false, nil
		}
	}

	/*
		Probably prime now.
	*/
	return true, nil
}

/*
	`a` is the big Int to test for primality.

	`miller_rabin_trials` can be one of the following:
		`< 0`:	For `a` up to 3_317_044_064_679_887_385_961_981, set `miller_rabin_trials` to negative to run a predetermined
				number of trials for a deterministic answer.
		`= 0`:	Run Miller-Rabin with bases 2, 3 and one random base < `a`. Non-deterministic.
		`> 0`:	Run Miller-Rabin with bases 2, 3 and `miller_rabin_trials` number of random bases. Non-deterministic.

	`miller_rabin_only`:
		`false`	Also use either Frobenius-Underwood or Lucas-Selfridge, depending on the compile-time `MATH_BIG_USE_FROBENIUS_TEST` choice.
		`true`	Run Rabin-Miller trials but skip Frobenius-Underwood / Lucas-Selfridge.

	`r` takes a pointer to an instance of `core:math/rand`'s `Rand` and may be `nil` to use the global one.

	Returns `is_prime` (bool), where:
		`false`	Definitively composite.
		`true`	Probably prime if `miller_rabin_trials` >= 0, with increasing certainty with more trials.
				Deterministically prime if `miller_rabin_trials` = 0 for `a` up to 3_317_044_064_679_887_385_961_981.

	Assumes `a` not to be `nil` and to have been initialized.
*/
internal_int_is_prime :: proc(a: ^Int, miller_rabin_trials := int(-1), miller_rabin_only := USE_MILLER_RABIN_ONLY, allocator := context.allocator) -> (is_prime: bool, err: Error) {
	context.allocator = allocator
	miller_rabin_trials := miller_rabin_trials

	// Default to `no`.
	is_prime = false

	b, res := &Int{}, &Int{}
	defer internal_destroy(b, res)

	// Some shortcuts
	// `N` > 3
	if a.used == 1 {
		if a.digit[0] == 0 || a.digit[0] == 1 {
			return
		}
		if a.digit[0] == 2 {
			return true, nil
		}
	}

	// `N` must be odd.
	if internal_is_even(a) {
		return
	}

	// `N` is not a perfect square: floor(sqrt(`N`))^2 != `N` 
	if internal_int_is_square(a) or_return { return }

	// Is the input equal to one of the primes in the table?
	for p in _private_prime_table {
		if internal_eq(a, p) {
			return true, nil
		}
	}

	// First perform trial division
	if internal_int_prime_is_divisible(a) or_return { return }

	// Run the Miller-Rabin test with base 2 for the BPSW test.
	internal_set(b, 2) or_return
	if !(internal_int_prime_miller_rabin(a, b) or_return) { return }

	// Rumours have it that Mathematica does a second M-R test with base 3.
	// Other rumours have it that their strong L-S test is slightly different.
	// It does not hurt, though, beside a bit of extra runtime.

	b.digit[0] += 1
	if !(internal_int_prime_miller_rabin(a, b) or_return) { return }

	// Both, the Frobenius-Underwood test and the the Lucas-Selfridge test are quite
	// slow so if speed is an issue, set `USE_MILLER_RABIN_ONLY` to use M-R tests with
	// bases 2, 3 and t random bases.

	if !miller_rabin_only {
		if miller_rabin_trials >= 0 {
			when MATH_BIG_USE_FROBENIUS_TEST {
				if !(internal_int_prime_frobenius_underwood(a) or_return) { return }
			} else {
				if !(internal_int_prime_strong_lucas_selfridge(a) or_return) { return }
			}
		}
	}

	// Run at least one Miller-Rabin test with a random base.
	// Don't replace this with `min`, because we try known deterministic bases
	//     for certain sized inputs when `miller_rabin_trials` is negative.
	if miller_rabin_trials == 0 {
		miller_rabin_trials = 1
	}

	// Only recommended if the input range is known to be < 3_317_044_064_679_887_385_961_981
	// It uses the bases necessary for a deterministic M-R test if the input is	smaller than 3_317_044_064_679_887_385_961_981
	// The caller has to check the size.
	// TODO: can be made a bit finer grained but comparing is not free.

	if miller_rabin_trials < 0 {
		p_max := 0

		// Sorenson, Jonathan; Webster, Jonathan (2015), "Strong Pseudoprimes to Twelve Prime Bases".

		// 0x437ae92817f9fc85b7e5 = 318_665_857_834_031_151_167_461
		atoi(b, "437ae92817f9fc85b7e5", 16) or_return
		if internal_lt(a, b) {
			p_max = 12
		} else {
			/* 0x2be6951adc5b22410a5fd = 3_317_044_064_679_887_385_961_981 */
			atoi(b, "2be6951adc5b22410a5fd", 16) or_return
			if internal_lt(a, b) {
				p_max = 13
			} else {
				return false, .Invalid_Argument
			}
		}

		// We did bases 2 and 3  already, skip them
		for ix := 2; ix < p_max; ix += 1 {
			internal_set(b, _private_prime_table[ix])
			if !(internal_int_prime_miller_rabin(a, b) or_return) { return }
		}
	} else if miller_rabin_trials > 0 {
		// Perform `miller_rabin_trials` M-R tests with random bases between 3 and "a".
		// See Fips 186.4 p. 126ff

		// The DIGITs have a defined bit-size but the size of a.digit is a simple 'int',
		// the size of which can depend on the platform.
		size_a := internal_count_bits(a)
		mask   := (1 << uint(ilog2(size_a))) - 1

		/*
			Assuming the General Rieman hypothesis (never thought to write that in a
			comment) the upper bound can be lowered to  2*(log a)^2.
			E. Bach, "Explicit bounds for primality testing and related problems,"
			Math. Comp. 55 (1990), 355-380.

				size_a = (size_a/10) * 7;
				len = 2 * (size_a * size_a);

			E.g.: a number of size 2^2048 would be reduced to the upper limit

				floor(2048/10)*7 = 1428
				2 * 1428^2       = 4078368

			(would have been ~4030331.9962 with floats and natural log instead)
			That number is smaller than 2^28, the default bit-size of DIGIT on 32-bit platforms.
		*/

		/*
			How many tests, you might ask? Dana Jacobsen of Math::Prime::Util fame
			does exactly 1. In words: one. Look at the end of _GMP_is_prime() in
			Math-Prime-Util-GMP-0.50/primality.c if you do not believe it.

			The function rand() goes to some length to use a cryptographically
			good PRNG. That also means that the chance to always get the same base
			in the loop is non-zero, although very low.
			-- NOTE(Jeroen): This is not yet true in Odin, but I have some ideas.

			If the BPSW test and/or the additional Frobenious test have been
			performed instead of just the Miller-Rabin test with the bases 2 and 3,
			a single extra test should suffice, so such a very unlikely event will not do much harm.

			To preemptivly answer the dangling question: no, a witness does not	need to be prime.
		*/
		for ix := 0; ix < miller_rabin_trials; ix += 1 {

			// rand() guarantees the first digit to be non-zero
			internal_random(b, _DIGIT_TYPE_BITS) or_return

			// Reduce digit before casting because DIGIT might be bigger than
			// an unsigned int and "mask" on the other side is most probably not.
			l: int

			fips_rand := (uint)(b.digit[0] & DIGIT(mask))
			if fips_rand > (uint)(max(int) - _DIGIT_BITS) {
				l = max(int) / _DIGIT_BITS
			} else {
				l = (int(fips_rand) + _DIGIT_BITS) / _DIGIT_BITS
			}

			// Unlikely.
			if (l < 0) {
				ix -= 1
				continue
			}
			internal_random(b, l) or_return

			// That number might got too big and the witness has to be smaller than "a"
			l = internal_count_bits(b)
			if l >= size_a {
				l = (l - size_a) + 1
				internal_shr(b, b, l) or_return
			}

			// Although the chance for b <= 3 is miniscule, try again.
			if internal_lte(b, 3) {
				ix -= 1
				continue
			}
			if !(internal_int_prime_miller_rabin(a, b) or_return) { return }
		}
	}

	// Passed the test.
	return true, nil
}

/*
 * floor of positive solution of (2^16) - 1 = (a + 4) * (2 * a + 5)
 * TODO: Both values are smaller than N^(1/4), would have to use a bigint
 *       for `a` instead, but any `a` bigger than about 120 are already so rare that
 *       it is possible to ignore them and still get enough pseudoprimes.
 *       But it is still a restriction of the set of available pseudoprimes
 *       which makes this implementation less secure if used stand-alone.
 */
_FROBENIUS_UNDERWOOD_A :: 32764

internal_int_prime_frobenius_underwood :: proc(N: ^Int, allocator := context.allocator) -> (result: bool, err: Error) {
	context.allocator = allocator

	T1z, T2z, Np1z, sz, tz := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(T1z, T2z, Np1z, sz, tz)

	internal_init_multi(T1z, T2z, Np1z, sz, tz) or_return

	a, ap2: int

	frob: for a = 0; a < _FROBENIUS_UNDERWOOD_A; a += 1 {
		switch a {
		case 2, 4, 7, 8, 10, 14, 18, 23, 26, 28:
			continue frob
		}

		internal_set(T1z, i32((a * a) - 4))
		j := internal_int_kronecker(T1z, N) or_return

		switch j {
		case -1: break frob
		case  0: return false, nil
		}
	}

	// Tell it a composite and set return value accordingly.
	if a >= _FROBENIUS_UNDERWOOD_A { return false, .Max_Iterations_Reached }

	// Composite if N and (a+4)*(2*a+5) are not coprime.
	internal_set(T1z, u32((a + 4) * ((2 * a) + 5)))
	internal_int_gcd(T1z, T1z, N) or_return

	if !(T1z.used == 1 && T1z.digit[0] == 1) {
		// Composite.
		return false, nil
	}

	ap2 = a + 2
	internal_add(Np1z, N, 1) or_return

	internal_set(sz, 1) or_return
	internal_set(tz, 2) or_return

	for i := internal_count_bits(Np1z) - 2; i >= 0; i -= 1 {
		// temp = (sz * (a * sz + 2 * tz)) % N;
		// tz   = ((tz - sz) * (tz + sz)) % N;
		// sz   = temp;

		internal_int_shl1(T2z, tz) or_return

		// a = 0 at about 50% of the cases (non-square and odd input)
		if a != 0 {
			internal_mul(T1z, sz, DIGIT(a)) or_return
			internal_add(T2z, T2z, T1z) or_return
		}

		internal_mul(T1z, T2z, sz) or_return
		internal_sub(T2z, tz, sz) or_return
		internal_add(sz, sz, tz) or_return
		internal_mul(tz, sz, T2z) or_return
		internal_mod(tz, tz, N) or_return
		internal_mod(sz, T1z, N) or_return

		if bit, _ := internal_int_bitfield_extract_bool(Np1z, i); bit {
			// temp = (a+2) * sz + tz
			// tz   = 2 * tz - sz
			// sz   = temp
			if a == 0 {
				internal_int_shl1(T1z, sz) or_return
			} else {
				internal_mul(T1z, sz, DIGIT(ap2)) or_return
			}
			internal_add(T1z, T1z, tz) or_return
			internal_int_shl1(T2z, tz) or_return
			internal_sub(tz, T2z, sz)
			internal_swap(sz, T1z)
		}
	}

	internal_set(T1z, u32((2 * a) + 5)) or_return
	internal_mod(T1z, T1z, N) or_return

	result = internal_is_zero(sz) && internal_eq(tz, T1z)

	return
}


/*
	Strong Lucas-Selfridge test.
	returns true if it is a strong L-S prime, false if it is composite

	Code ported from Thomas Ray Nicely's implementation of the BPSW test at http://www.trnicely.net/misc/bpsw.html

	Freeware copyright (C) 2016 Thomas R. Nicely <http://www.trnicely.net>.
	Released into the public domain by the author, who disclaims any legal liability arising from its use.

	The multi-line comments are made by Thomas R. Nicely and are copied verbatim.
	(If that name sounds familiar, he is the guy who found the fdiv bug in the Pentium CPU.)
*/
internal_int_prime_strong_lucas_selfridge :: proc(a: ^Int, allocator := context.allocator) -> (lucas_selfridge: bool, err: Error) {
	// TODO: choose better variable names!

	Dz, gcd, Np1, Uz, Vz, U2mz, V2mz, Qmz, Q2mz, Qkdz, T1z, T2z, T3z, T4z, Q2kdz := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(Dz, gcd, Np1, Uz, Vz, U2mz, V2mz, Qmz, Q2mz, Qkdz, T1z, T2z, T3z, T4z, Q2kdz)

	/*
		Find the first element D in the sequence {5, -7, 9, -11, 13, ...}
		such that Jacobi(D,N) = -1 (Selfridge's algorithm). Theory
		indicates that, if N is not a perfect square, D will "nearly
		always" be "small." Just in case, an overflow trap for D is	included.
	*/
	internal_init_multi(Dz, gcd, Np1, Uz, Vz, U2mz, V2mz, Qmz, Q2mz, Qkdz, T1z, T2z, T3z, T4z, Q2kdz) or_return

	D    := 5
	sign := 1
	Ds   : int

	for {
		Ds   = sign * D
		sign = -sign

		internal_set(Dz, D) or_return
		internal_int_gcd(gcd, a, Dz) or_return

		/*
			If 1 < GCD < `N` then `N` is composite with factor "D", and
			Jacobi(D, N) is technically undefined (but often returned as zero).
		*/
		if internal_gt(gcd, 1) && internal_lt(gcd, a)    { return }
		if Ds < 0 { Dz.sign = .Negative }

		j := internal_int_kronecker(Dz, a) or_return
		if j == -1 { break }

		D += 2
		if D > max(int) - 2                              { return false, .Invalid_Argument }
	}

	Q := (1 - Ds) / 4   /* Required so D = P*P - 4*Q */

	/*
		NOTE: The conditions (a) N does not divide Q, and
		(b) D is square-free or not a perfect square, are included by
		some authors; e.g., "Prime numbers and computer methods for
		factorization," Hans Riesel (2nd ed., 1994, Birkhauser, Boston),
		p. 130. For this particular application of Lucas sequences,
		these conditions were found to be immaterial.
	*/

	/*
		Now calculate N - Jacobi(D,N) = N + 1 (even), and calculate the
		odd positive integer d and positive integer s for which
		N + 1 = 2^s*d (similar to the step for N - 1 in Miller's test).
		The strong Lucas-Selfridge test then returns N as a strong
		Lucas probable prime (slprp) if any of the following
		conditions is met: U_d=0, V_d=0, V_2d=0, V_4d=0, V_8d=0,
		V_16d=0, ..., etc., ending with V_{2^(s-1)*d}=V_{(N+1)/2}=0
		(all equalities mod N). Thus d is the highest index of U that
		must be computed (since V_2m is independent of U), compared
		to U_{N+1} for the standard Lucas-Selfridge test; and no
		index of V beyond (N+1)/2 is required, just as in the
		standard Lucas-Selfridge test. However, the quantity Q^d must
		be computed for use (if necessary) in the latter stages of
		the test. The result is that the strong Lucas-Selfridge test
		has a running time only slightly greater (order of 10 %) than
		that of the standard Lucas-Selfridge test, while producing
		only (roughly) 30 % as many pseudoprimes (and every strong
		Lucas pseudoprime is also a standard Lucas pseudoprime). Thus
		the evidence indicates that the strong Lucas-Selfridge test is
		more effective than the standard Lucas-Selfridge test, and a
		Baillie-PSW test based on the strong Lucas-Selfridge test
		should be more reliable.
	*/
	internal_add(Np1, a, 1) or_return
	s := internal_count_lsb(Np1) or_return

	/*
		This should round towards zero because Thomas R. Nicely used GMP's mpz_tdiv_q_2exp()
		and mp_div_2d() is equivalent. Additionally: dividing an even number by two does not produce
		any leftovers.
	*/
	internal_int_shr(Dz, Np1, s) or_return

	/*
		We must now compute U_d and V_d. Since d is odd, the accumulated
		values U and V are initialized to U_1 and V_1 (if the target
		index were even, U and V would be initialized instead to U_0=0
		and V_0=2). The values of U_2m and V_2m are also initialized to
		U_1 and V_1; the FOR loop calculates in succession U_2 and V_2,
		U_4 and V_4, U_8 and V_8, etc. If the corresponding bits
		(1, 2, 3, ...) of t are on (the zero bit having been accounted
		for in the initialization of U and V), these values are then
		combined with the previous totals for U and V, using the
		composition formulas for addition of indices.
	*/
	internal_set(Uz,   1) or_return
	internal_set(Vz,   1) or_return //	P := 1; /* Selfridge's choice */
	internal_set(U2mz, 1) or_return
	internal_set(V2mz, 1) or_return //	P := 1; /* Selfridge's choice */
	internal_set(Qmz,  Q) or_return

	internal_int_shl1(Q2mz, Qmz) or_return

	/*
		Initializes calculation of Q^d.
	*/
	internal_set(Qkdz, Q) or_return
	Nbits := internal_count_bits(Dz)

	for u := 1; u < Nbits; u += 1 { /* zero bit off, already accounted for */
		/*
			Formulas for doubling of indices (carried out mod N). Note that
			the indices denoted as "2m" are actually powers of 2, specifically
			2^(ul-1) beginning each loop and 2^ul ending each loop.
			U_2m = U_m*V_m
			V_2m = V_m*V_m - 2*Q^m
		*/
		internal_mul(U2mz, U2mz, V2mz) or_return
		internal_mod(U2mz, U2mz, a) or_return
		internal_sqr(V2mz, V2mz) or_return
		internal_sub(V2mz, V2mz, Q2mz) or_return
		internal_mod(V2mz, V2mz, a) or_return

		/*
			Must calculate powers of Q for use in V_2m, also for Q^d later.
		*/
		internal_sqr(Qmz, Qmz) or_return

		/* Prevents overflow. Still necessary without a fixed prealloc'd mem.? */
		internal_mod(Qmz, Qmz, a) or_return
		internal_int_shl1(Q2mz, Qmz) or_return

		if internal_int_bitfield_extract_bool(Dz, u) or_return {
			/*
				Formulas for addition of indices (carried out mod N);
				U_(m+n) = (U_m*V_n + U_n*V_m)/2
				V_(m+n) = (V_m*V_n + D*U_m*U_n)/2
				Be careful with division by 2 (mod N)!
			*/
			internal_mul(T1z, U2mz, Vz) or_return
			internal_mul(T2z, Uz, V2mz) or_return
			internal_mul(T3z, V2mz, Vz) or_return
			internal_mul(T4z, U2mz, Uz) or_return
			internal_mul(T4z, T4z,  Ds) or_return

			internal_add(Uz,  T1z, T2z) or_return

			if internal_is_odd(Uz) {
				internal_add(Uz, Uz, a) or_return
			}

			/*
				This should round towards negative infinity because Thomas R. Nicely used GMP's mpz_fdiv_q_2exp().
				But `internal_shr1` does not do so, it is truncating instead.
			*/
			oddness := internal_is_odd(Uz)
			internal_int_shr1(Uz, Uz) or_return
			if internal_is_negative(Uz) && oddness {
				internal_sub(Uz, Uz, 1) or_return
			}
			internal_add(Vz, T3z, T4z) or_return
			if internal_is_odd(Vz) {
				internal_add(Vz, Vz, a) or_return
			}

			oddness  = internal_is_odd(Vz)
			internal_int_shr1(Vz, Vz) or_return
			if internal_is_negative(Vz) && oddness {
				internal_sub(Vz, Vz, 1) or_return
			}
			internal_mod(Uz, Uz, a) or_return
			internal_mod(Vz, Vz, a) or_return

			/* Calculating Q^d for later use */
			internal_mul(Qkdz, Qkdz, Qmz) or_return
			internal_mod(Qkdz, Qkdz, a) or_return
		}
	}

	/*
		If U_d or V_d is congruent to 0 mod N, then N is a prime or a strong Lucas pseudoprime. */
	if internal_is_zero(Uz) || internal_is_zero(Vz) {
		return true, nil
	}

	/*
		NOTE: Ribenboim ("The new book of prime number records," 3rd ed.,
		1995/6) omits the condition V0 on p.142, but includes it on
		p. 130. The condition is NECESSARY; otherwise the test will
		return false negatives---e.g., the primes 29 and 2000029 will be
		returned as composite.
	*/

	/*
		Otherwise, we must compute V_2d, V_4d, V_8d, ..., V_{2^(s-1)*d}
		by repeated use of the formula V_2m = V_m*V_m - 2*Q^m. If any of
		these are congruent to 0 mod N, then N is a prime or a strong
		Lucas pseudoprime.
	*/

	/* Initialize 2*Q^(d*2^r) for V_2m */
	internal_int_shr1(Q2kdz, Qkdz) or_return

	for r := 1; r < s; r += 1 {
		internal_sqr(Vz, Vz) or_return
		internal_sub(Vz, Vz, Q2kdz) or_return
		internal_mod(Vz, Vz, a) or_return
		if internal_is_zero(Vz) {
			return true, nil
		}
		/* Calculate Q^{d*2^r} for next r (final iteration irrelevant). */
		if r < (s - 1) {
			internal_sqr(Qkdz, Qkdz) or_return
			internal_mod(Qkdz, Qkdz, a) or_return
			internal_int_shl1(Q2kdz, Qkdz) or_return
		}
	}
	return false, nil
}

/*
	Performs one Fermat test.

	If "a" were prime then b**a == b (mod a) since the order of
	the multiplicative sub-group would be phi(a) = a-1.  That means
	it would be the same as b**(a mod (a-1)) == b**1 == b (mod a).

	Returns `true` if the congruence holds, or `false` otherwise.

	Assumes `a` and `b` not to be `nil` and to have been initialized.
*/
internal_prime_fermat :: proc(a, b: ^Int, allocator := context.allocator) -> (fermat: bool, err: Error) {
	t := &Int{}
	defer internal_destroy(t)

	/*
		Ensure `b` > 1.
	*/
	if !internal_gt(b, 1) { return false, .Invalid_Argument }

	/*
		Compute `t` = `b`**`a` mod `a`
	*/
	internal_int_exponent_mod(t, b, a, a) or_return

	/*
		Is it equal to b?
	*/
	fermat = internal_eq(t, b)
	return
}

/*
	Tonelli-Shanks algorithm
	https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
	https://gmplib.org/list-archives/gmp-discuss/2013-April/005300.html
*/
internal_int_sqrtmod_prime :: proc(res, n, prime: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		The type is "int" because of the types in the mp_int struct.
		Don't forget to change them here when you change them there!
	*/
	S, M, i: int

	t1, C, Q, Z, T, R, two := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(t1, C, Q, Z, T, R, two)

	/*
		First handle the simple cases.
	*/
	if internal_is_zero(n)                                           { return internal_zero(res)	}

	/*
		"prime" must be odd and > 2
	*/
	if internal_is_even(prime) || internal_lt(prime, 3)              { return .Invalid_Argument }
	legendre := internal_int_kronecker(n, prime)                     or_return

	/*
		n \not\cong 0 (mod p) and n \cong r^2 (mod p) for some r \in N^+
	*/
	if legendre != 1                                                 { return .Invalid_Argument }

	internal_init_multi(t1, C, Q, Z, T, R, two)                      or_return

	/*
		SPECIAL CASE: if prime mod 4 == 3
		compute directly: err = n^(prime+1)/4 mod prime
		Handbook of Applied Cryptography algorithm 3.36

		x%4 == x&3 for x in N and x>0
	*/
	if prime.digit[0] & 3 == 3 {
		internal_add(t1, prime, 1)                                   or_return
		internal_shr(t1, t1, 2)                                      or_return
		internal_int_exponent_mod(res, n, t1, prime)                 or_return
		return
	}

	/*
		NOW: Tonelli-Shanks algorithm
		Factor out powers of 2 from prime-1, defining Q and S as: prime-1 = Q*2^S

		Q = prime - 1
	*/
	internal_copy(Q, prime)                                          or_return
	internal_sub(Q, Q, 1)                                            or_return

	/*
		S = 0
	*/
	S = 0
	for internal_is_even(Q) {
		/*
			Q = Q / 2
		*/
		internal_int_shr1(Q, Q)                                      or_return
		/*
			S = S + 1
		*/
		S += 1
	}

	/*
		Find a `Z` such that the Legendre symbol (Z|prime) == -1.
		Z = 2.
	*/
	internal_set(Z, 2)                                               or_return

	for {
		legendre = internal_int_kronecker(Z, prime)                  or_return

		/*
			If "prime" (p) is an odd prime Jacobi(k|p) = 0 for k \cong 0 (mod p)
			but there is at least one non-quadratic residue before k>=p if p is an odd prime.
		*/
		if legendre == 0                                             { return .Invalid_Argument }
		if legendre == -1                                            { break }

		/*
			Z = Z + 1
		*/
		internal_add(Z, Z, 1)                                        or_return
	}

	/*
		C = Z ^ Q mod prime
	*/
	internal_int_exponent_mod(C, Z, Q, prime)                        or_return

	/*
		t1 = (Q + 1) / 2
	*/
	internal_add(t1, Q, 1)                                           or_return
	internal_int_shr1(t1, t1)                                        or_return

	/*
		R = n ^ ((Q + 1) / 2) mod prime
	*/
	internal_int_exponent_mod(R, n, t1, prime)                       or_return

	/*
		T = n ^ Q mod prime
	*/
	internal_int_exponent_mod(T, n, Q, prime)                        or_return

	/*
		M = S
	*/
	M = S
	internal_set(two, 2)

	for {
		internal_copy(t1, T)                                         or_return

		i = 0
		for {
			if internal_eq(T, 1)                                     { break }

			/*
				No exponent in the range 0 < i < M found.
				(M is at least 1 in the first round because "prime" > 2)
			*/
			if M == i                                                { return .Invalid_Argument }
			internal_int_exponent_mod(t1, t1, two, prime)            or_return

			i += 1
		}

		if i == 0 {
			internal_copy(res, R)                                    or_return
		}

		/*
			t1 = 2 ^ (M - i - 1)
		*/
		internal_set(t1, M - i - 1)                                  or_return
		internal_int_exponent_mod(t1, two, t1, prime)                or_return

		/*
			t1 = C ^ (2 ^ (M - i - 1)) mod prime
		*/
		internal_int_exponent_mod(t1, C, t1, prime)                  or_return

		/*
			C = (t1 * t1) mod prime
		*/
		internal_sqrmod(C, t1, prime)                                or_return

		/*
			R = (R * t1) mod prime
		*/
		internal_mulmod(R, R, t1, prime)                             or_return

		/*
			T = (T * C) mod prime
		*/
		mulmod(T, T, C, prime)                                       or_return

		/*
			M = i
		*/
		M = i
	}

	return
}

/*
	Finds the next prime after the number `a` using `t` trials of Miller-Rabin,
	in place: It sets `a` to the prime found.
	`bbs_style` = true means the prime must be congruent to 3 mod 4
*/
internal_int_prime_next_prime :: proc(a: ^Int, trials: int, bbs_style: bool, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	res_tab := [_PRIME_TAB_SIZE]DIGIT{}

	/*
		Force positive.
	*/
	a.sign = .Zero_or_Positive

	/*
		Simple algo if `a` is less than the largest prime in the table.
	*/
	if internal_lt(a, _private_prime_table[_PRIME_TAB_SIZE - 1]) {
		/*
			Find which prime it is bigger than `a`
		*/
		for p in _private_prime_table {
			cmp := internal_cmp(a, p)

			if cmp == 0 { continue }
			if cmp != 1 {
				if bbs_style && (p & 3 != 3) {
					/*
						Try again until we get a prime congruent to 3 mod 4.
					*/
					continue
				} else {
					return internal_set(a, p)
				}
			}
		}
		/*
			Fall through to the sieve.
		*/
	}

	/*
		Generate a prime congruent to 3 mod 4 or 1/3 mod 4?
	*/
	kstep: DIGIT = 4 if bbs_style else 2

	/*
		At this point we will use a combination of a sieve and Miller-Rabin.
	*/
	if bbs_style {
		/*
			If `a` mod 4 != 3 subtract the correct value to make it so.
		*/
		if a.digit[0] & 3 != 3 {
			internal_sub(a, a, (a.digit[0] & 3) + 1) or_return
		}
	} else {
		if internal_is_even(a) {
			/*
				Force odd.
			*/
			internal_sub(a, a, 1) or_return
		}
	}

	/*
		Generate the restable.
	*/
	for x := 1; x < _PRIME_TAB_SIZE; x += 1 {
		res_tab = cast(type_of(res_tab))(internal_mod(a, _private_prime_table[x]) or_return)
	}

	for {
		step := DIGIT(0)
		y: bool

		/*
			Skip to the next non-trivially divisible candidate.
		*/
		for {
			/*
				y == true if any residue was zero [e.g. cannot be prime]
			*/
			y = false

			/*
				Increase step to next candidate.
			*/
			step += kstep

			/*
				Compute the new residue without using division.
			*/
			for x := 1; x < _PRIME_TAB_SIZE; x += 1 {
				/*
					Add the step to each residue.
				*/
				res_tab[x] += kstep

				/*
					Subtract the modulus [instead of using division].
				*/
				if res_tab[x] >= _private_prime_table[x] {
					res_tab[x] -= _private_prime_table[x]
				}

				/*
					Set flag if zero.
				*/
				if res_tab[x] == 0 {
					y = true
				}
			}
			if !(y && (step < (((1 << _DIGIT_BITS) - kstep)))) { break }
		}

		/*
			Add the step.
		*/
		internal_add(a, a, step) or_return

		/*
			If we didn't pass the sieve and step == MP_MAX then skip test */
		if y && (step >= ((1 << _DIGIT_BITS) - kstep)) { continue }

		if internal_int_is_prime(a, trials) or_return { break }
	}
	return
}

/*
	Makes a truly random prime of a given size (bits),

	Flags are as follows:
	 	Blum_Blum_Shub    - Make prime congruent to 3 mod 4
		Safe              - Make sure (p-1)/2 is prime as well (implies .Blum_Blum_Shub)
		Second_MSB_On     - Make the 2nd highest bit one

	This is possibly the mother of all prime generation functions, muahahahahaha!
*/
internal_random_prime :: proc(a: ^Int, size_in_bits: int, trials: int, flags := Primality_Flags{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	flags  := flags
	trials := trials

	/*
		Sanity check the input.
	*/
	if size_in_bits <= 1 || trials < -1                              { return .Invalid_Argument }

	/*
		`.Safe` implies `.Blum_Blum_Shub`.
	*/
	if .Safe in flags {
		if size_in_bits < 3 {
			/*
				The smallest safe prime is 5, which takes 3 bits.
				We early out now, else we'd be locked in an infinite loop trying to generate a 2-bit Safe Prime.
			*/
			return .Invalid_Argument
		}
		flags += { .Blum_Blum_Shub, }
	}

	/*
		Automatically choose the number of Rabin-Miller trials?
	*/
	if trials == -1 {
		trials = number_of_rabin_miller_trials(size_in_bits)
	}

	RANDOM_PRIME_ITERATIONS_USED = 0

	for {
		if MAX_ITERATIONS_RANDOM_PRIME > 0 {
			RANDOM_PRIME_ITERATIONS_USED += 1
			if RANDOM_PRIME_ITERATIONS_USED > MAX_ITERATIONS_RANDOM_PRIME {
				return .Max_Iterations_Reached
			}
		}

		internal_int_random(a, size_in_bits)                         or_return

		/*
			Make sure it's odd.
		*/
		if size_in_bits > 2 {
			a.digit[0] |= 1
		} else {
			/*
				A 2-bit prime can be either 2 (0b10) or 3 (0b11).
				So, let's force the top bit to 1 and return early.
			*/
			a.digit[0] |= 2
			return nil
		}

		if .Blum_Blum_Shub in flags {
			a.digit[0] |= 3
		}
		if .Second_MSB_On in flags {
			/*
				Ensure there's enough space for the bit to be set.
			*/
			if a.used * _DIGIT_BITS < size_in_bits - 1 {
				new_size := (size_in_bits - 1) / _DIGIT_BITS

				if new_size % _DIGIT_BITS > 0 {
					new_size += 1
				}

				internal_grow(a, new_size) or_return
				a.used = new_size
			}

			internal_int_bitfield_set_single(a, size_in_bits - 2) or_return
		}

		/*
			Is it prime?
		*/
		res := internal_int_is_prime(a, trials) or_return
		if !res {
			continue
		}

		if .Safe in flags {
			/*
				See if (a-1)/2 is prime.
			*/
			internal_sub(a, a, 1)                                    or_return
			internal_int_shr1(a, a)                                  or_return

			/*
				Is it prime?
			*/
			res = internal_int_is_prime(a, trials) or_return
		}
		if res {
			break
		}
	}

	if .Safe in flags {
		/*
			Restore a to the original value.
		*/
		internal_int_shl1(a, a)                                      or_return
		internal_add(a, a, 1)                                        or_return
	}
	return
}

/*
	Extended Euclidean algorithm of (a, b) produces `a * u1` + `b * u2` = `u3`.
*/
internal_int_extended_euclidean :: proc(a, b, U1, U2, U3: ^Int, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	u1, u2, u3, v1, v2, v3, t1, t2, t3, q, tmp := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}
	defer internal_destroy(u1, u2, u3, v1, v2, v3, t1, t2, t3, q, tmp)
	internal_init_multi(u1, u2, u3, v1, v2, v3, t1, t2, t3, q, tmp)  or_return

	/*
		Initialize, (u1, u2, u3) = (1, 0, a).
	*/
	internal_set(u1, 1)                                              or_return
	internal_set(u3, a)                                              or_return

	/*
		Initialize, (v1, v2, v3) = (0, 1, b).
	*/
	internal_set(v2, 1)                                              or_return
	internal_set(v3, b)                                              or_return

	/*
		Loop while v3 != 0
	*/
	for !internal_is_zero(v3) {
		/*
			q = u3 / v3
		*/
		internal_div(q, u3, v3)                                      or_return

		/*
			(t1, t2, t3) = (u1, u2, u3) - (v1, v2, v3)q
		*/
		internal_mul(tmp, v1, q)                                     or_return
		internal_sub( t1, u1, tmp)                                   or_return

		internal_mul(tmp, v2, q)                                     or_return
		internal_sub( t2, u2, tmp)                                   or_return

		internal_mul(tmp, v3, q)                                     or_return
		internal_sub( t3, u3, tmp)                                   or_return

		/*
			(u1, u2, u3) = (v1, v2, v3)
		*/
		internal_set(u1, v1)                                         or_return
		internal_set(u2, v2)                                         or_return
		internal_set(u3, v3)                                         or_return

		/*
			(v1, v2, v3) = (t1, t2, t3)
		*/
		internal_set(v1, t1)                                         or_return
		internal_set(v2, t2)                                         or_return
		internal_set(v3, t3)                                         or_return
	}

	/*
		Make sure U3 >= 0.
	*/
	if internal_is_negative(u3) {
		internal_neg(u1, u1)                                         or_return
		internal_neg(u2, u2)                                         or_return
		internal_neg(u3, u3)                                         or_return
	}

	/*
		Copy result out.
	*/
	if U1 != nil {
		internal_swap(u1, U1)
	}
	if U2 != nil {
		internal_swap(u2, U2)
	}
	if U3 != nil {
		internal_swap(u3, U3)
	}
	return
}


/*
	Returns the number of Rabin-Miller trials needed for a given bit size.
*/
number_of_rabin_miller_trials :: proc(bit_size: int) -> (number_of_trials: int) {
	switch {
	case bit_size <=    80:
		return -1		/* Use deterministic algorithm for size <= 80 bits */
	case bit_size >=    81 && bit_size <     96:
		return 37		/* max. error = 2^(-96)  */
	case bit_size >=    96 && bit_size <    128:
		return 32		/* max. error = 2^(-96)  */
	case bit_size >=   128 && bit_size <    160:
		return 40		/* max. error = 2^(-112) */
	case bit_size >=   160 && bit_size <    256:
		return 35		/* max. error = 2^(-112) */
	case bit_size >=   256 && bit_size <    384:
		return 27		/* max. error = 2^(-128) */
	case bit_size >=   384 && bit_size <    512:
		return 16		/* max. error = 2^(-128) */
	case bit_size >=   512 && bit_size <    768:
		return 18		/* max. error = 2^(-160) */
	case bit_size >=   768 && bit_size <    896:
		return 11		/* max. error = 2^(-160) */
	case bit_size >=   896 && bit_size <  1_024:
		return 10		/* max. error = 2^(-160) */
	case bit_size >= 1_024 && bit_size <  1_536:
		return 12		/* max. error = 2^(-192) */
	case bit_size >= 1_536 && bit_size <  2_048:
		return  8		/* max. error = 2^(-192) */
	case bit_size >= 2_048 && bit_size <  3_072:
		return  6		/* max. error = 2^(-192) */
	case bit_size >= 3_072 && bit_size <  4_096:
		return  4		/* max. error = 2^(-192) */
	case bit_size >= 4_096 && bit_size <  5_120:
		return  5		/* max. error = 2^(-256) */
	case bit_size >= 5_120 && bit_size <  6_144:
		return  4		/* max. error = 2^(-256) */
	case bit_size >= 6_144 && bit_size <  8_192:
		return  4		/* max. error = 2^(-256) */
	case bit_size >= 8_192 && bit_size <  9_216:
		return  3		/* max. error = 2^(-256) */
	case bit_size >= 9_216 && bit_size < 10_240:
		return  3		/* max. error = 2^(-256) */
	case:
		return  2		/* For keysizes bigger than 10_240 use always at least 2 Rounds */
	}
}
