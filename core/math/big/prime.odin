package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains basic arithmetic operations like `add`, `sub`, `mul`, `div`, ...
*/

/*
	Determines if an Integer is divisible by one of the _PRIME_TABLE primes.
	Returns true if it is, false if not. 
*/
int_prime_is_divisible :: proc(a: ^Int, allocator := context.allocator) -> (res: bool, err: Error) {
	assert_if_nil(a);
	context.allocator = allocator;

	if err = internal_clear_if_uninitialized(a); err != nil { return {}, err; }

	rem: DIGIT;
	for prime in _private_prime_table {
		if rem, err = #force_inline int_mod_digit(a, prime); err != nil { return false, err; }
		if rem == 0 { return true, nil; }
	}
	/*
		Default to not divisible.
	*/
	return false, nil;
}
