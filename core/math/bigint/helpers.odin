package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:mem"
import "core:intrinsics"

/*
	Deallocates the backing memory of an Int.
*/

destroy :: proc(a: ^Int, allocator_zeroes := false, free_int := true, loc := #caller_location) {
	if !is_initialized(a) {
		// Nothing to do.
		return;
	}

	if !allocator_zeroes {
		mem.zero_slice(a.digit[:]);
	}
	free(&a.digit[0]);
	a.used      = 0;
	a.allocated = 0;
	if free_int {
		free(a);
	}
}

/*
	Creates and returns a new `Int`.
*/

init_new :: proc(allocator_zeroes := true, allocator := context.allocator, size := _DEFAULT_DIGIT_COUNT) -> (a: ^Int, err: Error) {
	/*
		Allocating a new variable.
	*/
	a = new(Int, allocator);

	a.digit     = mem.make_dynamic_array_len_cap([dynamic]DIGIT, size, size, allocator);
	a.allocated = 0;
	a.used      = 0;
	a.sign      = .Zero_or_Positive;

	if len(a.digit) != size {
		return a, .Out_of_Memory;
	}
	a.allocated = size;

	if !allocator_zeroes {
		_zero_unused(a);
	}
	return a, .OK;
}

/*
	Initialize from a signed or unsigned integer.
	Inits a new `Int` and then calls the appropriate `set` routine.
*/

init_new_integer :: proc(u: $T, minimize := false, allocator_zeroes := true, allocator := context.allocator) -> (a: ^Int, err: Error) where intrinsics.type_is_integer(T) {

	n := _DEFAULT_DIGIT_COUNT;
	if minimize {
		n = _MIN_DIGIT_COUNT;
	}

	a, err = init_new(allocator_zeroes, allocator, n);
	if err == .OK {
		set(a, u, minimize);
	}
	return;
}

init :: proc{init_new, init_new_integer};

/*
	Helpers to set an `Int` to a specific value.
*/

set_integer :: proc(a: ^Int, n: $T, minimize := false) where intrinsics.type_is_integer(T) {
	n := n;
	_panic_if_uninitialized(a);

	a.used = 0;
	a.sign = .Zero_or_Positive if n >= 0 else .Negative;
	n = abs(n);
	for n != 0 {
		a.digit[a.used] = DIGIT(n) & _MASK;
		a.used += 1;
		n >>= _DIGIT_BITS;
	}
	if minimize {
		shrink(a);
	}

	_zero_unused(a);
}

set :: proc{set_integer};

/*
	Resize backing store.
*/

shrink :: proc(a: ^Int) -> (err: Error) {
	needed := max(_MIN_DIGIT_COUNT, a.used);

	if a.used != needed {
		return grow(a, needed);
	}
	return .OK;
}

grow :: proc(a: ^Int, n: int) -> (err: Error) {
    _panic_if_uninitialized(a);

    resize(&a.digit, n);
    if len(a.digit) != n {
    	return .Out_of_Memory;
    }

    a.used = min(n, a.used);
    a.allocated = n;
    return .OK;
}

/*
	Clear `Int` and resize it to the default size.
*/
clear :: proc(a: ^Int) -> (err: Error) {
	_panic_if_uninitialized(a);

	mem.zero_slice(a.digit[:]);
	a.sign = .Zero_or_Positive;
	a.used = 0;
	grow(a, _DEFAULT_DIGIT_COUNT);

	return .OK;	
}

/*
	Set the `Int` to 0 and optionally shrink it to the minimum backing size.
*/
zero :: proc(a: ^Int, minimize := false) -> (err: Error) {
	_panic_if_uninitialized(a);

	mem.zero_slice(a.digit[:]);
	a.sign = .Zero_or_Positive;
	a.used = 0;
	if minimize {
		return shrink(a);
	}

	return .OK;
}

/*
	Set the `Int` to 1 and optionally shrink it to the minimum backing size.
*/
one :: proc(a: ^Int, minimize := false) -> (err: Error) {
	_panic_if_uninitialized(a);

	mem.zero_slice(a.digit[:]);
	a.sign     = .Zero_or_Positive;
	a.used     = 1;
	a.digit[0] = 1;
	if minimize {
		return shrink(a);
	}

	return .OK;
}

/*
	Set the `Int` to -1 and optionally shrink it to the minimum backing size.
*/
minus_one :: proc(a: ^Int, minimize := false) -> (err: Error) {
	_panic_if_uninitialized(a);

	mem.zero_slice(a.digit[:]);
	a.sign     = .Negative;
	a.used     = 1;
	a.digit[0] = 1;
	if minimize {
		return shrink(a);
	}

	return .OK;
}

/*
	Internal helpers.
*/

_panic_if_uninitialized :: proc(a: ^Int, loc := #caller_location) {
	if !is_initialized(a) {
		panic("Int was not properly initialized.", loc);
	}
}

_zero_unused :: proc(a: ^Int) {
	_panic_if_uninitialized(a);
	if a.used < a.allocated {
		mem.zero_slice(a.digit[a.used:]);
	}
}

clamp :: proc(a: ^Int) {
	_panic_if_uninitialized(a);
	/*
		Trim unused digits
	 	This is used to ensure that leading zero digits are
	 	trimmed and the leading "used" digit will be non-zero.
		Typically very fast.  Also fixes the sign if there
	 	are no more leading digits.
	*/

	for a.used > 0 && a.digit[a.used - 1] == 0 {
		a.used -= 1;
	}

	if is_zero(a) {
		a.sign = .Zero_or_Positive;
	}
}