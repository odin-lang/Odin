package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

int_log :: proc(a: ^Int, base: DIGIT) -> (res: int, err: Error) {
	if base < 2 || DIGIT(base) > _DIGIT_MAX {
		return -1, .Invalid_Argument;
	}
	if err = clear_if_uninitialized(a); err != .None { return -1, err; }
	if n, _ := is_neg(a);  n { return -1, .Math_Domain_Error; }
	if z, _ := is_zero(a); z { return -1, .Math_Domain_Error; }

	/*
		Fast path for bases that are a power of two.
	*/
	if is_power_of_two(int(base)) { return _log_power_of_two(a, base); }

	/*
		Fast path for `Int`s that fit within a single `DIGIT`.
	*/
	if a.used == 1 { return log(a.digit[0], DIGIT(base)); }

	return _int_log(a, base);

}

log :: proc { int_log, int_log_digit, };

/*
	Calculate c = a**b  using a square-multiply algorithm.
*/
int_pow :: proc(dest, base: ^Int, power: int) -> (err: Error) {
	power := power;
	if err = clear_if_uninitialized(base); err != .None { return err; }
	if err = clear_if_uninitialized(dest); err != .None { return err; }
	/*
		Early outs.
	*/
	if z, _ := is_zero(base); z {
		/*
			A zero base is a special case.
		*/
		if power  < 0 {
			if err = zero(dest); err != .None { return err; }
			return .Math_Domain_Error;
		}
		if power == 0 { return  one(dest); }
		if power  > 0 { return zero(dest); }

	}
	if power < 0 {
		/*
			Fraction, so we'll return zero.
		*/
		return zero(dest);
	}
	switch(power) {
	case 0:
		/*
			Any base to the power zero is one.
		*/
		return one(dest);
	case 1:
		/*
			Any base to the power one is itself.
		*/
		return copy(dest, base);
	case 2:
		return sqr(dest, base);
	}

	g := &Int{};
	if err = copy(g, base); err != .None { return err; }

	/*
		Set initial result.
	*/
	if err = set(dest, 1); err != .None { return err; }

	loop: for power > 0 {
		/*
			If the bit is set, multiply.
		*/
		if power & 1 != 0 {
			if err = mul(dest, g, dest); err != .None {
				break loop;
			}
		}
		/*
			Square.
		*/
		if power > 1 {
			if err = sqr(g, g); err != .None {
				break loop;
			}
		}

		/* shift to next bit */
		power >>= 1;
	}

	destroy(g);
	return err;
}

/*
	Calculate c = a**b.
*/
int_pow_int :: proc(dest: ^Int, base, power: int) -> (err: Error) {
	base_t := &Int{};
	defer destroy(base_t);

	if err = set(base_t, base); err != .None { return err; }

	return int_pow(dest, base_t, power);
}

pow :: proc { int_pow, int_pow_int, };
exp :: pow;

/*
	Returns the log2 of an `Int`, provided `base` is a power of two.
	Don't call it if it isn't.
*/
_log_power_of_two :: proc(a: ^Int, base: DIGIT) -> (log: int, err: Error) {
	base := base;
	y: int;
	for y = 0; base & 1 == 0; {
		y += 1;
		base >>= 1;
	}
	log, err = count_bits(a);
	return (log - 1) / y, err;
}

/*

*/
small_pow :: proc(base: _WORD, exponent: _WORD) -> (result: _WORD) {
	exponent := exponent; base := base;
   	result = _WORD(1);

   	for exponent != 0 {
   		if exponent & 1 == 1 {
   			result *= base;
   		}
   		exponent >>= 1;
   		base *= base;
   	}
   	return result;
}

int_log_digit :: proc(a: DIGIT, base: DIGIT) -> (log: int, err: Error) {
	/*
		If the number is smaller than the base, it fits within a fraction.
		Therefore, we return 0.
	*/
	if a < base {
		return 0, .None;
	}

	/*
		If a number equals the base, the log is 1.
	*/
	if a == base {
		return 1, .None;
	}

	N := _WORD(a);
	bracket_low  := _WORD(1);
	bracket_high := _WORD(base);
	high := 1;
	low  := 0;

	for bracket_high < N {
		low = high;
		bracket_low = bracket_high;
		high <<= 1;
		bracket_high *= bracket_high;
	}

	for high - low > 1 {
		mid := (low + high) >> 1;
		bracket_mid := bracket_low * small_pow(_WORD(base), _WORD(mid - low));

		if N < bracket_mid {
			high = mid;
			bracket_high = bracket_mid;
		}
		if N > bracket_mid {
			low = mid;
			bracket_low = bracket_mid;
		}
		if N == bracket_mid {
			return mid, .None;
		}
   	}

   	if bracket_high == N {
   		return high, .None;
   	} else {
   		return low, .None;
   	}
}

/*
	This function is less generic than `root_n`, simpler and faster.
*/
int_sqrt :: proc(dest, src: ^Int) -> (err: Error) {

	when true {
		if err = clear_if_uninitialized(dest);			err != .None { return err; }
		if err = clear_if_uninitialized(src);			err != .None { return err; }

		/*						Must be positive. 					*/
		if src.sign == .Negative						{ return .Invalid_Argument; }

		/*			Easy out. If src is zero, so is dest.			*/
		if z, _ := is_zero(src); 						z { return zero(dest); }

		/*						Set up temporaries.					*/
		x, y, t1, t2 := &Int{}, &Int{}, &Int{}, &Int{};
		defer destroy(x, y, t1, t2);

		count: int;
		if count, err = count_bits(src); err != .None { return err; }

		a, b := count >> 1, count & 1;
		if err = power_of_two(x, a+b);                  err != .None { return err; }

		for {
			/*
				y = (x + n//x)//2
			*/
			div(t1, src, x);
			add(t2, t1, x);
			shr(y, t2, 1);

			if c, _ := cmp(y, x); c == 0 || c == 1 {
				swap(dest, x);
				return .None;
			}
			swap(x, y);
		}

		swap(dest, x);
		return err;
	} else {
		// return root_n(dest, src, 2);
	}
}
sqrt :: proc { int_sqrt, };


/*
	Find the nth root of an Integer.
 	Result found such that `(dest)**n <= src` and `(dest+1)**n > src`

	This algorithm uses Newton's approximation `x[i+1] = x[i] - f(x[i])/f'(x[i])`,
  	which will find the root in `log(n)` time where each step involves a fair bit.
*/
int_root_n :: proc(dest, src: ^Int, n: int) -> (err: Error) {
	/*						Fast path for n == 2 						*/
	if n == 2 { return sqrt(dest, src); }

	/*					Initialize dest + src if needed. 				*/
	if err = clear_if_uninitialized(dest);			err != .None { return err; }
	if err = clear_if_uninitialized(src);			err != .None { return err; }

	if n < 0 || n > int(_DIGIT_MAX) {
		return .Invalid_Argument;
	}

	neg: bool;
	if n & 1 == 0 {
		if neg, err = is_neg(src); neg || err != .None { return .Invalid_Argument; }
	}

	/*							Set up temporaries.						*/
	t1, t2, t3, a := &Int{}, &Int{}, &Int{}, &Int{};
	defer destroy(t1, t2, t3);

	/*			If a is negative fudge the sign but keep track.			*/
	a.sign  = .Zero_or_Positive;
	a.used  = src.used;
	a.digit = src.digit;

	/*
	  If "n" is larger than INT_MAX it is also larger than
	  log_2(src) because the bit-length of the "src" is measured
	  with an int and hence the root is always < 2 (two).
	*/
	if n > max(int) / 2 {
		err = set(dest, 1);
		dest.sign = a.sign;
		return err;
	}

	/*					Compute seed: 2^(log_2(src)/n + 2)				*/
	ilog2: int;
	ilog2, err = count_bits(src);

	/*			"src" is smaller than max(int), we can cast safely.		*/
	if ilog2 < n {
		err = set(dest, 1);
		dest.sign = a.sign;
		return err;
	}

	ilog2 /= n;
	if ilog2 == 0 {
		err = set(dest, 1);
		dest.sign = a.sign;
		return err;
	}

	/*					Start value must be larger than root.			*/
	ilog2 += 2;
	if err = power_of_two(t2, ilog2); err != .None { return err; }

	c: int;
	iterations := 0;
	for {
		/* t1 = t2 */
		if err = copy(t1, t2); err != .None { return err; }

		/* t2 = t1 - ((t1**b - a) / (b * t1**(b-1))) */

		/* t3 = t1**(b-1) */
		if err = pow(t3, t1, n-1); err != .None { return err; }

		/* numerator */
		/* t2 = t1**b */
		if err = mul(t2, t1, t3); err != .None { return err; }

		/* t2 = t1**b - a */
		if err = sub(t2, t2, a); err != .None { return err; }

		/* denominator */
		/* t3 = t1**(b-1) * b  */
		if err = mul(t3, t3, DIGIT(n)); err != .None { return err; }

		/* t3 = (t1**b - a)/(b * t1**(b-1)) */
		if err = div(t3, t2, t3); err != .None { return err; }
		if err = sub(t2, t1, t3); err != .None { return err; }

		/*
			 Number of rounds is at most log_2(root). If it is more it
			 got stuck, so break out of the loop and do the rest manually.
		*/
		if ilog2 -= 1; ilog2 == 0 {
			break;
		}
		if c, err = cmp(t1, t2); c == 0 { break; }
		iterations += 1;
		if iterations == _MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached;
		}
	}

	/*						Result can be off by a few so check.					*/
	/* Loop beneath can overshoot by one if found root is smaller than actual root. */

	iterations = 0;
	for {
		if err = pow(t2, t1, n); err != .None { return err; }

		c, err = cmp(t2, a);
		if c == 0 {
			swap(dest, t1);
			return .None;
		} else if c == -1 {
			if err = add(t1, t1, DIGIT(1)); err != .None { return err; }
		} else {
			break;
		}

		iterations += 1;
		if iterations == _MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached;
		}
	}

	iterations = 0;
	/*					Correct overshoot from above or from recurrence.			*/
	for {
		if err = pow(t2, t1, n); err != .None { return err; }

		c, err = cmp(t2, a);
		if c == 1 {
			if err = sub(t1, t1, DIGIT(1)); err != .None { return err; }
		} else {
			break;
		}

		iterations += 1;
		if iterations == _MAX_ITERATIONS_ROOT_N {
			return .Max_Iterations_Reached;
		}
	}

	/*								Set the result.									*/
	swap(dest, t1);

	/* set the sign of the result */
	dest.sign = src.sign;

	return err;
}
root_n :: proc { int_root_n, };

/*
	Internal implementation of log.	
*/
_int_log :: proc(a: ^Int, base: DIGIT) -> (res: int, err: Error) {
	bracket_low, bracket_high, bracket_mid, t, bi_base := &Int{}, &Int{}, &Int{}, &Int{}, &Int{};

	ic, _ := cmp(a, base);
	if ic == -1 || ic == 0 {
		return 1 if ic == 0 else 0, .None;
	}

	if err = set(bi_base, base);          err != .None { return -1, err; }
	if err = init_multi(bracket_mid, t);  err != .None { return -1, err; }
	if err = one(bracket_low);            err != .None { return -1, err; }
	if err = set(bracket_high, base);     err != .None { return -1, err; }

	low  := 0; high := 1;

	/*
		A kind of Giant-step/baby-step algorithm.
		Idea shamelessly stolen from https://programmingpraxis.com/2010/05/07/integer-logarithms/2/
		The effect is asymptotic, hence needs benchmarks to test if the Giant-step should be skipped
		for small n.
	*/

	for {
		/*
			Iterate until `a` is bracketed between low + high.
		*/
		if bc, _ := cmp(bracket_high, a); bc != -1 {
			break;
		}

	 	low = high;
	 	if err = copy(bracket_low, bracket_high); err != .None {
			destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return -1, err;
	 	}
	 	high <<= 1;
	 	if err = sqr(bracket_high, bracket_high); err != .None {
			destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return -1, err;
	 	}
	}

	for (high - low) > 1 {
		mid := (high + low) >> 1;

		if err = pow(t, bi_base, mid - low); err != .None {
			destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return -1, err;
		}

		if err = mul(bracket_mid, bracket_low, t); err != .None {
			destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return -1, err;
		}
		mc, _ := cmp(a, bracket_mid);
		if mc == -1 {
			high = mid;
			swap(bracket_mid, bracket_high);
		}
		if mc == 1 {
			low = mid;
			swap(bracket_mid, bracket_low);
		}
		if mc == 0 {
			destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return mid, .None;
		}
	}

	fc, _ := cmp(bracket_high, a);
	res = high if fc == 0 else low;

	destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
	return;
}