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
	if n, _ := is_neg(a);  n { return -1, .Invalid_Argument; }
	if z, _ := is_zero(a); z { return -1, .Invalid_Argument; }

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
	Internal implementation of log.	
*/
_int_log :: proc(a: ^Int, base: DIGIT) -> (res: int, err: Error) {
	bracket_low, bracket_high, bracket_mid, t, bi_base := &Int{}, &Int{}, &Int{}, &Int{}, &Int{};

	cnt := 0;

	ic, _ := cmp(a, base);
	if ic == -1 || ic == 0 {
		return 1 if ic == 0 else 0, .None;
	}

	if err = set(bi_base, base);          err != .None { return -1, err; }
	if err = _init_multi(bracket_mid, t); err != .None { return -1, err; }
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

	 	cnt += 1;
	 	if cnt == 7 {
		 	destroy(bracket_low, bracket_high, bracket_mid, t, bi_base);
			return -2, .Max_Iterations_Reached;
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