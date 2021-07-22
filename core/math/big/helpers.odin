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
		raw := transmute(mem.Raw_Dynamic_Array)a.digit;
		if raw.cap > 0 {
			free(&a.digit[0]);
		}
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
	In normal code, you can also write `a, b = b, a`.
	However, that only swaps within the current scope.
	This helper swaps completely.
*/
int_swap :: proc(a, b: ^Int) {
	a := a; b := b;

	a.used,  b.used  = b.used,  a.used;
	a.sign,  b.sign  = b.sign,  a.sign;
	a.digit, b.digit = b.digit, a.digit;
}
swap :: proc { int_swap, };

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

int_get_u128 :: proc(a: ^Int) -> (res: u128, err: Error) {
	return int_get(a, u128);
}
get_u128 :: proc { int_get_u128, };

int_get_i128 :: proc(a: ^Int) -> (res: i128, err: Error) {
	return int_get(a, i128);
}
get_i128 :: proc { int_get_i128, };

int_get_u64 :: proc(a: ^Int) -> (res: u64, err: Error) {
	return int_get(a, u64);
}
get_u64 :: proc { int_get_u64, };

int_get_i64 :: proc(a: ^Int) -> (res: i64, err: Error) {
	return int_get(a, i64);
}
get_i64 :: proc { int_get_i64, };

int_get_u32 :: proc(a: ^Int) -> (res: u32, err: Error) {
	return int_get(a, u32);
}
get_u32 :: proc { int_get_u32, };

int_get_i32 :: proc(a: ^Int) -> (res: i32, err: Error) {
	return int_get(a, i32);
}
get_i32 :: proc { int_get_i32, };

/*
	TODO: Think about using `count_bits` to check if the value could be returned completely,
	and maybe return max(T), .Integer_Overflow if not?
*/
int_get :: proc(a: ^Int, $T: typeid) -> (res: T, err: Error) where intrinsics.type_is_integer(T) {
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}

	size_in_bits := int(size_of(T) * 8);
	i := int((size_in_bits + _DIGIT_BITS - 1) / _DIGIT_BITS);
	i  = min(int(a.used), i);

	for ; i >= 0; i -= 1 {
		res <<= uint(0) if size_in_bits <= _DIGIT_BITS else _DIGIT_BITS;
		res |= T(a.digit[i]);
		if size_in_bits <= _DIGIT_BITS {
			break;
		};
	}

	when !intrinsics.type_is_unsigned(T) {
		/*
			Mask off sign bit.
		*/
		res ~= 1 << uint(size_in_bits - 1);
		/*
			Set the sign.
		*/
		if a.sign == .Negative {
			res = -res;
		}
	}
	return;
}
get :: proc { int_get, };

int_get_float :: proc(a: ^Int) -> (res: f64, err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}	

	l   := min(a.used, 17); // log2(max(f64)) is approximately 1020, or 17 legs.
	fac := f64(1 << _DIGIT_BITS);
	d   := 0.0;

	for i := l; i >= 0; i -= 1 {
		d = (d * fac) + f64(a.digit[i]);
	}

	res = -d if a.sign == .Negative else d;
	return;
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
	Counts the number of LSBs which are zero before the first zero bit
*/
count_lsb :: proc(a: ^Int) -> (count: int, err: Error) {
	if err = clear_if_uninitialized(a); err != .None {
		return 0, err;
	}

	lnz := []u8{4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0};

	q: DIGIT;

	/*
		Early out for zero.
	*/
	if z, _ := is_zero(a); z {
		return 0, .None;
	}

	/*
		Scan lower digits until non-zero.
	*/
	for count = 0; (count < a.used && a.digit[count] == 0); count += 1 {}
	q = a.digit[count];
	count *= _DIGIT_BITS;

	/*
		Now scan this digit until a 1 is found.
	*/
	if q & 1 == 0 {
		p: DIGIT;
		for {
			p = q & 15;
			count += int(lnz[p]);
			q >>= 4;
			if p != 0 {
				break;
			}
		}
	}
	return count, .None;
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