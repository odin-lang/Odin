package math_big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	This file collects public proc maps and their aliases.
*/

/*

	=== === === === === === === === === === === === === === === === === === === === === === === ===
	                                    Basic arithmetic.
	                                    See `public.odin`.
	=== === === === === === === === === === === === === === === === === === === === === === === ===
*/

/*
	High-level addition. Handles sign.
*/
add :: proc {
	/*
		int_add :: proc(dest, a, b: ^Int, allocator := context.allocator) -> (err: Error)
	*/
	int_add,
	/*
		Adds the unsigned `DIGIT` immediate to an `Int`, such that the
		`DIGIT` doesn't have to be turned into an `Int` first.

		int_add_digit :: proc(dest, a: ^Int, digit: DIGIT, allocator := context.allocator) -> (err: Error)
	*/
	int_add_digit,
	rat_add_rat,
	rat_add_int,
	int_add_rat,
}

/*
	err = sub(dest, a, b);
*/
sub :: proc {
	/*
		int_sub :: proc(dest, a, b: ^Int) -> (err: Error)
	*/
	int_sub,
	/*
		int_sub_digit :: proc(dest, a: ^Int, digit: DIGIT) -> (err: Error)
	*/
	int_sub_digit,
	rat_sub_rat,
	rat_sub_int,
	int_sub_rat,
}

/*
	=== === === === === === === === === === === === === === === === === === === === === === === ===
	                                        Comparisons.
	                                    See `compare.odin`.
	=== === === === === === === === === === === === === === === === === === === === === === === ===
*/

is_initialized :: proc {
	/*
		int_is_initialized :: proc(a: ^Int) -> bool
	*/
	int_is_initialized,
}

is_zero :: proc {
	/*
		int_is_zero :: proc(a: ^Int) -> bool
	*/
	int_is_zero,
	/*
		rat_is_zero :: proc(a: ^Rat) -> bool
	*/
	rat_is_zero,
}

is_positive :: proc {
	/*
		int_is_positive :: proc(a: ^Int) -> bool
	*/
	int_is_positive,
	rat_is_positive,
}
is_pos :: is_positive

is_negative :: proc {
	/*
		int_is_negative :: proc(a: ^Int) -> bool
	*/
	int_is_negative,
	rat_is_negative,
}
is_neg :: is_negative

is_even :: proc {
	/*
		int_is_even :: proc(a: ^Int) -> bool
	*/
	int_is_even,
	rat_is_even,
}

is_odd :: proc {
	/*
		int_is_odd :: proc(a: ^Int) -> bool
	*/
	int_is_odd,
	rat_is_odd,
}

is_power_of_two :: proc {
	/*
		platform_int_is_power_of_two :: proc(a: int) -> bool
	*/
	platform_int_is_power_of_two,
	/*
		int_is_power_of_two :: proc(a: ^Int) -> (res: bool)
	*/
	int_is_power_of_two,
}

compare :: proc {
	/*
		Compare two `Int`s, signed.

		int_compare :: proc(a, b: ^Int) -> Comparison_Flag
	*/
	int_compare,
	/*
		Compare an `Int` to an unsigned number upto the size of the backing type.

		int_compare_digit :: proc(a: ^Int, u: DIGIT) -> Comparison_Flag
	*/
	int_compare_digit,
}
cmp :: compare

compare_magnitude :: proc {
	/*
		Compare the magnitude of two `Int`s, unsigned.
	*/
	int_compare_magnitude,
}
cmp_mag :: compare_magnitude

/*
	=== === === === === === === === === === === === === === === === === === === === === === === ===
	                              Initialization and other helpers.
	                                    See `helpers.odin`.
	=== === === === === === === === === === === === === === === === === === === === === === === ===
*/

destroy :: proc {
	/*
		Clears one or more `Int`s and dellocates their backing memory.

		int_destroy :: proc(integers: ..^Int)
	*/
	int_destroy,
	internal_rat_destroy,
}