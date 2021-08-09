package big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:mem"
import "core:intrinsics"
import rnd "core:math/rand"
import "core:fmt"

/*
	TODO: Int.flags and Constants like ONE, NAN, etc, are not yet properly handled everywhere.
*/

/*
	Deallocates the backing memory of one or more `Int`s.
*/
int_destroy :: proc(integers: ..^Int) {
	integers := integers;

	for a in &integers {
		assert_if_nil(a);
	}
	#force_inline internal_int_destroy(..integers);
}

/*
	Helpers to set an `Int` to a specific value.
*/
int_set_from_integer :: proc(dest: ^Int, src: $T, minimize := false, allocator := context.allocator) -> (err: Error)
	where intrinsics.type_is_integer(T) {
	src := src;

	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest);
	if err = #force_inline internal_error_if_immutable(dest);    err != nil { return err; }

	return #force_inline internal_int_set_from_integer(dest, src, minimize, allocator);
}

set :: proc { int_set_from_integer, int_copy };

/*
	Copy one `Int` to another.
*/
int_copy :: proc(dest, src: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		If dest == src, do nothing
	*/
	if (dest == src) { return nil; }

	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src);
	if err = #force_inline internal_clear_if_uninitialized(src); err != nil { return err; }
	if err = #force_inline internal_error_if_immutable(dest);    err != nil { return err; }

	return #force_inline internal_int_copy(dest, src, minimize, allocator);
}
copy :: proc { int_copy, };

/*
	In normal code, you can also write `a, b = b, a`.
	However, that only swaps within the current scope.
	This helper swaps completely.
*/
int_swap :: proc(a, b: ^Int) {
	assert_if_nil(a, b);
	#force_inline internal_swap(a, b);
}
swap :: proc { int_swap, };

/*
	Set `dest` to |`src`|.
*/
int_abs :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src);
	if err = #force_inline internal_clear_if_uninitialized(src); err != nil { return err; }
	if err = #force_inline internal_error_if_immutable(dest);    err != nil { return err; }

	return #force_inline internal_int_abs(dest, src, allocator);
}

platform_abs :: proc(n: $T) -> T where intrinsics.type_is_integer(T) {
	return n if n >= 0 else -n;
}
abs :: proc{ int_abs, platform_abs, };

/*
	Set `dest` to `-src`.
*/
int_neg :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src);
	if err = #force_inline internal_clear_if_uninitialized(src); err != nil { return err; }
	if err = #force_inline internal_error_if_immutable(dest);    err != nil { return err; }

	return #force_inline internal_int_neg(dest, src, allocator);
}
neg :: proc { int_neg, };

/*
	Helpers to extract values from the `Int`.
*/
int_bitfield_extract_single :: proc(a: ^Int, offset: int) -> (bit: _WORD, err: Error) {
	return #force_inline int_bitfield_extract(a, offset, 1);
}

int_bitfield_extract :: proc(a: ^Int, offset, count: int) -> (res: _WORD, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a); err != nil { return 0, err; }

	return #force_inline internal_int_bitfield_extract(a, offset, count);
}

/*
	Resize backing store.
*/
shrink :: proc(a: ^Int) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a); err != nil { return err; }

	return #force_inline internal_shrink(a);
}

int_grow :: proc(a: ^Int, digits: int, allow_shrink := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_int_grow(a, digits, allow_shrink, allocator);
}
grow :: proc { int_grow, };

/*
	Clear `Int` and resize it to the default size.
*/
int_clear :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_int_clear(a, minimize, allocator);
}
clear :: proc { int_clear, };
zero  :: clear;

/*
	Set the `Int` to 1 and optionally shrink it to the minimum backing size.
*/
int_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_one(a, minimize, allocator);
}
one :: proc { int_one, };

/*
	Set the `Int` to -1 and optionally shrink it to the minimum backing size.
*/
int_minus_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_minus_one(a, minimize, allocator);
}
minus_one :: proc { int_minus_one, };

/*
	Set the `Int` to Inf and optionally shrink it to the minimum backing size.
*/
int_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_inf(a, minimize, allocator);
}
inf :: proc { int_inf, };

/*
	Set the `Int` to -Inf and optionally shrink it to the minimum backing size.
*/
int_minus_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_minus_inf(a, minimize, allocator);
}
minus_inf :: proc { int_inf, };

/*
	Set the `Int` to NaN and optionally shrink it to the minimum backing size.
*/
int_nan :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_nan(a, minimize, allocator);
}
nan :: proc { int_nan, };

power_of_two :: proc(a: ^Int, power: int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return #force_inline internal_int_power_of_two(a, power, allocator);
}

int_get_u128 :: proc(a: ^Int) -> (res: u128, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, u128);
}
get_u128 :: proc { int_get_u128, };

int_get_i128 :: proc(a: ^Int) -> (res: i128, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, i128);
}
get_i128 :: proc { int_get_i128, };

int_get_u64 :: proc(a: ^Int) -> (res: u64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, u64);
}
get_u64 :: proc { int_get_u64, };

int_get_i64 :: proc(a: ^Int) -> (res: i64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, i64);
}
get_i64 :: proc { int_get_i64, };

int_get_u32 :: proc(a: ^Int) -> (res: u32, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, u32);
}
get_u32 :: proc { int_get_u32, };

int_get_i32 :: proc(a: ^Int) -> (res: i32, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);

	return int_get(a, i32);
}
get_i32 :: proc { int_get_i32, };

/*
	TODO: Think about using `count_bits` to check if the value could be returned completely,
	and maybe return max(T), .Integer_Overflow if not?
*/
int_get :: proc(a: ^Int, $T: typeid, allocator := context.allocator) -> (res: T, err: Error) where intrinsics.type_is_integer(T) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a, allocator); err != nil { return T{}, err; }

	return #force_inline internal_int_get(a, T);
}
get :: proc { int_get, };

int_get_float :: proc(a: ^Int, allocator := context.allocator) -> (res: f64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a, allocator); err != nil { return 0, err; }

	return #force_inline internal_int_get_float(a);
}

/*
	Count bits in an `Int`.
*/
count_bits :: proc(a: ^Int, allocator := context.allocator) -> (count: int, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a, allocator); err != nil { return 0, err; }

	return #force_inline internal_count_bits(a);	
}

/*
	Returns the number of trailing zeroes before the first one.
	Differs from regular `ctz` in that 0 returns 0.
*/
int_count_lsb :: proc(a: ^Int, allocator := context.allocator) -> (count: int, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a);
	if err = #force_inline internal_clear_if_uninitialized(a, allocator); err != nil { return 0, err; }

	return #force_inline internal_int_count_lsb(a);
}

platform_count_lsb :: #force_inline proc(a: $T) -> (count: int)
	where intrinsics.type_is_integer(T) && intrinsics.type_is_unsigned(T) {
	return int(intrinsics.count_trailing_zeros(a)) if a > 0 else 0;
}

count_lsb :: proc { int_count_lsb, platform_count_lsb, };

int_random_digit :: proc(r: ^rnd.Rand = nil) -> (res: DIGIT) {
	when _DIGIT_BITS == 60 { // DIGIT = u64
		return DIGIT(rnd.uint64(r)) & _MASK;
	} else when _DIGIT_BITS == 28 { // DIGIT = u32
		return DIGIT(rnd.uint32(r)) & _MASK;
	} else {
		panic("Unsupported DIGIT size.");
	}

	return 0; // We shouldn't get here.
}

int_rand :: proc(dest: ^Int, bits: int, r: ^rnd.Rand = nil) -> (err: Error) {
	bits := bits;

	if bits <= 0 { return .Invalid_Argument; }

	digits := bits / _DIGIT_BITS;
	bits   %= _DIGIT_BITS;

	if bits > 0 {
		digits += 1;
	}

	if err = grow(dest, digits); err != nil { return err; }

	for i := 0; i < digits; i += 1 {
		dest.digit[i] = int_random_digit(r) & _MASK;
	}
	if bits > 0 {
		dest.digit[digits - 1] &= ((1 << uint(bits)) - 1);
	}
	dest.used = digits;
	return nil;
}
rand :: proc { int_rand, };

/*
	Internal helpers.
*/
assert_initialized :: proc(a: ^Int, loc := #caller_location) {
	assert(is_initialized(a), "`Int` was not properly initialized.", loc);
}

zero_unused :: proc(dest: ^Int, old_used := -1) {
	if dest == nil { return; }
	if ! #force_inline is_initialized(dest) { return; }

	internal_zero_unused(dest, old_used);
}

clear_if_uninitialized_single :: proc(arg: ^Int) -> (err: Error) {
	if !is_initialized(arg) {
		if arg == nil { return nil; }
		return grow(arg, _DEFAULT_DIGIT_COUNT);
	}
	return err;
}

clear_if_uninitialized_multi :: proc(args: ..^Int) -> (err: Error) {
	for i in args {
		if i == nil { continue; }
		if !is_initialized(i) {
			e := grow(i, _DEFAULT_DIGIT_COUNT);
			if e != nil { err = e; }
		}
	}
	return err;
}
clear_if_uninitialized :: proc {clear_if_uninitialized_single, clear_if_uninitialized_multi, };

error_if_immutable_single :: proc(arg: ^Int) -> (err: Error) {
	if arg != nil && .Immutable in arg.flags { return .Assignment_To_Immutable; }
	return nil;
}

error_if_immutable_multi :: proc(args: ..^Int) -> (err: Error) {
	for i in args {
		if i != nil && .Immutable in i.flags { return .Assignment_To_Immutable; }
	}
	return nil;
}
error_if_immutable :: proc {error_if_immutable_single, error_if_immutable_multi, };

/*
	Allocates several `Int`s at once.
*/
int_init_multi :: proc(integers: ..^Int) -> (err: Error) {
	integers := integers;
	for a in &integers {
		if err = clear(a); err != nil { return err; }
	}
	return nil;
}

init_multi :: proc { int_init_multi, };

_copy_digits :: proc(dest, src: ^Int, digits: int) -> (err: Error) {
	digits := digits;
	if err = clear_if_uninitialized(src);  err != nil { return err; }
	if err = clear_if_uninitialized(dest); err != nil { return err; }
	/*
		If dest == src, do nothing
	*/
	if (dest == src) {
		return nil;
	}

	digits = min(digits, len(src.digit), len(dest.digit));
	mem.copy_non_overlapping(&dest.digit[0], &src.digit[0], size_of(DIGIT) * digits);
	return nil;
}

/*
	Trim unused digits.

	This is used to ensure that leading zero digits are trimmed and the leading "used" digit will be non-zero.
	Typically very fast.  Also fixes the sign if there are no more leading digits.
*/
clamp :: proc(a: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a); err != nil {
		return err;
	}
	for a.used > 0 && a.digit[a.used - 1] == 0 {
		a.used -= 1;
	}

	if z, _ := is_zero(a); z {
		a.sign = .Zero_or_Positive;
	}
	return nil;
}


/*
	Initialize constants.
*/
INT_ONE, INT_ZERO, INT_MINUS_ONE, INT_INF, INT_MINUS_INF, INT_NAN := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{};

initialize_constants :: proc() -> (res: int) {
	internal_set(     INT_ZERO,  0);      INT_ZERO.flags = {.Immutable};
	internal_set(      INT_ONE,  1);       INT_ONE.flags = {.Immutable};
	internal_set(INT_MINUS_ONE, -1); INT_MINUS_ONE.flags = {.Immutable};

	/*
		We set these special values to -1 or 1 so they don't get mistake for zero accidentally.
		This allows for shortcut tests of is_zero as .used == 0.
	*/
	internal_set(      INT_NAN,  1);       INT_NAN.flags = {.Immutable, .NaN};
	internal_set(      INT_INF,  1);       INT_INF.flags = {.Immutable, .Inf};
	internal_set(      INT_INF, -1); INT_MINUS_INF.flags = {.Immutable, .Inf};

	return _DEFAULT_MUL_KARATSUBA_CUTOFF;
}

/*
	Destroy constants.
	Optional for an EXE, as this would be called at the very end of a process.
*/
destroy_constants :: proc() {
	internal_destroy(INT_ONE, INT_ZERO, INT_MINUS_ONE, INT_INF, INT_MINUS_INF, INT_NAN);
}


assert_if_nil :: #force_inline proc(integers: ..^Int, loc := #caller_location) {
	integers := integers;

	for i in &integers {
		if i == nil {
			msg := fmt.tprintf("%v(nil)", loc.procedure);
			assert(false, msg, loc);
		}
	}
}
