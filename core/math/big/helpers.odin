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
/*
	Deallocates the backing memory of one or more `Int`s.
*/
int_destroy :: proc(integers: ..^Int) {
	integers := integers;

	for a in &integers {
		mem.zero_slice(a.digit[:]);
		free(&a.digit[0]);
		a = &Int{};
	}
}

/*
	Helpers to set an `Int` to a specific value.
*/
int_set_from_integer :: proc(dest: ^Int, src: $T, minimize := false, allocator := context.allocator) -> (err: Error)
	where intrinsics.type_is_integer(T) {
	src := src;
	if err = clear_if_uninitialized(dest); err != .None {
		return err;
	}

	dest.used = 0;
	dest.sign = .Zero_or_Positive if src >= 0 else .Negative;
	src = abs(src);

	for src != 0 {
		dest.digit[dest.used] = DIGIT(src) & _MASK;
		dest.used += 1;
		src >>= _DIGIT_BITS;
	}
	_zero_unused(dest);
	return .None;
}

set :: proc { int_set_from_integer, int_copy };

/*
	Copy one `Int` to another.
*/
int_copy :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	if err = clear_if_uninitialized(src); err != .None {
		return err;
	}
	/*
		If dest == src, do nothing
	*/
	if (dest == src) {
		return .None;
	}
	/*
		Grow `dest` to fit `src`.
		If `dest` is not yet initialized, it will be using `allocator`.
	*/
	if err = grow(dest, src.used, false, allocator); err != .None {
		return err;
	}

	/*
		Copy everything over and zero high digits.
	*/
	for v, i in src.digit[:src.used+1] {
		dest.digit[i] = v;
	}
	dest.used = src.used;
	dest.sign = src.sign;
	_zero_unused(dest);
	return .None;
}
copy :: proc { int_copy, };

/*
	Set `dest` to |`src`|.
*/
int_abs :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that src is usable.
	*/
	if err = clear_if_uninitialized(src); err != .None {
		return err;
	}
	/*
		If `dest == src`, just fix `dest`'s sign.
	*/
	if (dest == src) {
		dest.sign = .Zero_or_Positive;
		return .None;
	}

	/*
		Copy `src` to `dest`
	*/
	if err = copy(dest, src, allocator); err != .None {
		return err;
	}

	/*
		Fix sign.
	*/
	dest.sign = .Zero_or_Positive;
	return .None;
}

platform_abs :: proc(n: $T) -> T where intrinsics.type_is_integer(T) {
	return n if n >= 0 else -n;
}
abs :: proc{int_abs, platform_abs};

/*
	Set `dest` to `-src`.
*/
neg :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that src is usable.
	*/
	if err = clear_if_uninitialized(src); err != .None {
		return err;
	}
	/*
		If `dest == src`, just fix `dest`'s sign.
	*/
	sign := Sign.Zero_or_Positive;
	if z, _ := is_zero(src); z {
		sign = .Negative;
	}
	if n, _ := is_neg(src); n {
		sign = .Negative;
	}
	if (dest == src) {
		dest.sign = sign;
		return .None;
	}
	/*
		Copy `src` to `dest`
	*/
	if err = copy(dest, src, allocator); err != .None {
		return err;
	}

	/*
		Fix sign.
	*/
	dest.sign = sign;
	return .None;
}

/*
	Helpers to extract values from the `Int`.
*/
extract_bit :: proc(a: ^Int, bit_offset: int) -> (bit: DIGIT, err: Error) {
	/*
		Check that `a`is usable.
	*/
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}

	limb := bit_offset / _DIGIT_BITS;
	if limb < 0 || limb >= a.used {
		return 0, .Invalid_Argument;
	}

	i := DIGIT(1 << DIGIT((bit_offset % _DIGIT_BITS)));

	return 1 if ((a.digit[limb] & i) != 0) else 0, .None;
}

/*
	TODO: Optimize.
*/
extract_bits :: proc(a: ^Int, offset, count: int) -> (res: _WORD, err: Error) {
	/*
		Check that `a`is usable.
	*/
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}

	if count > _WORD_BITS || count < 1 {
		return 0, .Invalid_Argument;
	}

	v: DIGIT;
	e: Error;
	for shift := 0; shift < count; shift += 1 {
		o   := offset + shift;
		v, e = extract_bit(a, o);
		if e != .None {
			break;
		}
		res = res + _WORD(v) << uint(shift);
	}

	return res, e;
}

/*
	Resize backing store.
*/
shrink :: proc(a: ^Int) -> (err: Error) {
	if a == nil {
		return .Invalid_Pointer;
	}

	needed := max(_MIN_DIGIT_COUNT, a.used);

	if a.used != needed {
		return grow(a, needed);
	}
	return .None;
}

int_grow :: proc(a: ^Int, digits: int, allow_shrink := false, allocator := context.allocator) -> (err: Error) {
	if a == nil {
		return .Invalid_Pointer;
	}
	raw := transmute(mem.Raw_Dynamic_Array)a.digit;

	/*
		We need at least _MIN_DIGIT_COUNT or a.used digits, whichever is bigger.
		The caller is asking for `digits`. Let's be accomodating.
	*/
	needed := max(_MIN_DIGIT_COUNT, a.used, digits);
	if !allow_shrink {
		needed = max(needed, raw.cap);
	}

	/*
		If not yet iniialized, initialize the `digit` backing with the allocator we were passed.
		Otherwise, `[dynamic]DIGIT` already knows what allocator was used for it, so reuse will do the right thing.
	*/
	if raw.cap == 0 {
		a.digit = mem.make_dynamic_array_len_cap([dynamic]DIGIT, needed, needed, allocator);
	} else if raw.cap != needed {
		resize(&a.digit, needed);
	}
	/*
		Let's see if the allocation/resize worked as expected.
	*/
	if len(a.digit) != needed {
		return .Out_Of_Memory;
	}
	return .None;
}
grow :: proc { int_grow, };

/*
	Clear `Int` and resize it to the default size.
*/
int_clear :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	if a == nil {
		return .Invalid_Pointer;
	}

	raw := transmute(mem.Raw_Dynamic_Array)a.digit;
	if raw.cap != 0 {
		mem.zero_slice(a.digit[:]);
	}
	a.sign = .Zero_or_Positive;
	a.used = 0;

	return grow(a, a.used, minimize, allocator);
}
clear :: proc { int_clear, };
zero  :: clear;

/*
	Set the `Int` to 1 and optionally shrink it to the minimum backing size.
*/
int_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	if err = clear(a, minimize, allocator); err != .None {
		return err;
	}

	a.used     = 1;
	a.digit[0] = 1;
	a.sign     = .Zero_or_Positive;
	return .None;
}
one :: proc { int_one, };

/*
	Set the `Int` to -1 and optionally shrink it to the minimum backing size.
*/
int_minus_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	if err = clear(a, minimize, allocator); err != .None {
		return err;
	}

	a.used     = 1;
	a.digit[0] = 1;
	a.sign     = .Negative;
	return .None;
}
minus_one :: proc { int_minus_one, };



power_of_two :: proc(a: ^Int, power: int) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	if a == nil {
		return .Invalid_Pointer;
	}

	if power < 0 || power > _MAX_BIT_COUNT {
		return .Invalid_Argument;
	}

	/*
		Grow to accomodate the single bit.
	*/
	a.used = (power / _DIGIT_BITS) + 1;
	if err = grow(a, a.used); err != .None {
		return err;
	}
	/*
		Zero the entirety.
	*/
	mem.zero_slice(a.digit[:]);

	/*
		Set the bit.
	*/
	a.digit[power / _DIGIT_BITS] = 1 << uint((power % _DIGIT_BITS));
   	return .None;
}

/*
	Count bits in an `Int`.
*/
count_bits :: proc(a: ^Int) -> (count: int, err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}
	/*
		Fast path for zero.
	*/
	if z, _ := is_zero(a); z {
		return 0, .None;
	}
	/*
		Get the number of DIGITs and use it.
	*/
	count  = (a.used - 1) * _DIGIT_BITS;
	/*
		Take the last DIGIT and count the bits in it.
	*/
	clz   := int(intrinsics.count_leading_zeros(a.digit[a.used - 1]));
	count += (_DIGIT_TYPE_BITS - clz);
	return;
}

/*
	Internal helpers.
*/
assert_initialized :: proc(a: ^Int, loc := #caller_location) {
	assert(is_initialized(a), "`Int` was not properly initialized.", loc);
}

_zero_unused :: proc(a: ^Int) {
	if a == nil {
		return;
	} else if !is_initialized(a) {
		return;
	}

	if a.used < len(a.digit) {
		mem.zero_slice(a.digit[a.used:]);
	}
}

clear_if_uninitialized :: proc(dest: ^Int, minimize := false) -> (err: Error) {
	if !is_initialized(dest) {
		return grow(dest, _MIN_DIGIT_COUNT if minimize else _DEFAULT_DIGIT_COUNT);
	}
	return .None;
}

/*
	Trim unused digits.

	This is used to ensure that leading zero digits are trimmed and the leading "used" digit will be non-zero.
	Typically very fast.  Also fixes the sign if there are no more leading digits.
*/
clamp :: proc(a: ^Int) -> (err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return err;
	}

	for a.used > 0 && a.digit[a.used - 1] == 0 {
		a.used -= 1;
	}

	if z, _ := is_zero(a); z {
		a.sign = .Zero_or_Positive;
	}

	return .None;
}