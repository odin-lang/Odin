package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains various comparison routines.

	We essentially just check if params are initialized before punting to the `internal_*` versions.
	This has the side benefit of being able to add additional characteristics to numbers, like NaN,
	and keep support for that contained.
*/

import "core:intrinsics"

int_is_initialized :: proc(a: ^Int) -> bool {
	if a == nil { return false; }

	return #force_inline internal_int_is_initialized(a);
}

int_is_zero :: proc(a: ^Int) -> (zero: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_zero(a), nil;
}

int_is_positive :: proc(a: ^Int) -> (positive: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_positive(a), nil;
}

int_is_negative :: proc(a: ^Int) -> (negative: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_negative(a), nil;
}

int_is_even :: proc(a: ^Int) -> (even: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_even(a), nil;
}

int_is_odd :: proc(a: ^Int) -> (odd: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_odd(a), nil;
}

platform_int_is_power_of_two :: #force_inline proc(a: int) -> bool {
	return ((a) != 0) && (((a) & ((a) - 1)) == 0);
}

int_is_power_of_two :: proc(a: ^Int) -> (res: bool, err: Error) {
	if a == nil { return false, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return false, err; }

	return #force_inline internal_is_power_of_two(a), nil;
}

/*
	Compare two `Int`s, signed.
*/
int_compare :: proc(a, b: ^Int) -> (comparison: int, err: Error) {
	if a == nil || b == nil { return 0, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a, b); err != nil {	return 0, err; }

	return #force_inline internal_cmp(a, b), nil;
}
int_cmp :: int_compare;

/*
	Compare an `Int` to an unsigned number upto the size of the backing type.
*/
int_compare_digit :: proc(a: ^Int, b: DIGIT) -> (comparison: int, err: Error) {
	if a == nil { return 0, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a); err != nil { return 0, err; }

	return #force_inline internal_cmp_digit(a, b), nil;
}
int_cmp_digit :: int_compare_digit;

/*
	Compare the magnitude of two `Int`s, unsigned.
*/
int_compare_magnitude :: proc(a, b: ^Int) -> (res: int, err: Error) {
	if a == nil || b == nil { return 0, .Invalid_Pointer; }
	if err = clear_if_uninitialized(a, b); err != nil { return 0, err; }

	return #force_inline internal_cmp_mag(a, b), nil;
}