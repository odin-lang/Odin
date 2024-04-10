/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.
*/


package math_big

import "base:intrinsics"
import rnd "core:math/rand"

/*
	TODO: Int.flags and Constants like ONE, NAN, etc, are not yet properly handled everywhere.
*/

/*
	Deallocates the backing memory of one or more `Int`s.
*/
int_destroy :: proc(integers: ..^Int) {
	integers := integers

	for a in integers {
		assert_if_nil(a)
	}
	#force_inline internal_int_destroy(..integers)
}

/*
	Helpers to set an `Int` to a specific value.
*/
int_set_from_integer :: proc(dest: ^Int, src: $T, minimize := false, allocator := context.allocator) -> (err: Error)
	where intrinsics.type_is_integer(T) {
	context.allocator = allocator
	src := src

	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest)
	#force_inline internal_error_if_immutable(dest) or_return

	return #force_inline internal_int_set_from_integer(dest, src, minimize)
}

set :: proc { 
	int_set_from_integer, 
	int_copy, 
	int_atoi, 

	rat_set_f64, 
	rat_set_f32, 
	rat_set_f16, 
	rat_set_u64, 
	rat_set_i64,
	rat_set_int, 
	rat_set_digit, 
	rat_set_rat, 
}

/*
	Copy one `Int` to another.
*/
int_copy :: proc(dest, src: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		If dest == src, do nothing
	*/
	if (dest == src) { return nil }

	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src)
	context.allocator = allocator

	#force_inline internal_clear_if_uninitialized(src) or_return
	#force_inline internal_error_if_immutable(dest)    or_return

	return #force_inline internal_int_copy(dest, src, minimize)
}
copy :: proc { 
	int_copy, 
	rat_copy,
}

/*
	In normal code, you can also write `a, b = b, a`.
	However, that only swaps within the current scope.
	This helper swaps completely.
*/
int_swap :: proc(a, b: ^Int) {
	assert_if_nil(a, b)
	#force_inline internal_swap(a, b)
}
swap :: proc { int_swap, rat_swap }

/*
	Set `dest` to |`src`|.
*/
int_abs :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src)
	context.allocator = allocator

	#force_inline internal_clear_if_uninitialized(src) or_return
	#force_inline internal_error_if_immutable(dest)    or_return

	return #force_inline internal_int_abs(dest, src)
}

platform_abs :: proc(n: $T) -> T where intrinsics.type_is_integer(T) {
	return n if n >= 0 else -n
}
abs :: proc{ int_abs, platform_abs, rat_abs }

/*
	Set `dest` to `-src`.
*/
int_neg :: proc(dest, src: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src)
	context.allocator = allocator

	#force_inline internal_clear_if_uninitialized(src) or_return
	#force_inline internal_error_if_immutable(dest)    or_return

	return #force_inline internal_int_neg(dest, src)
}
neg :: proc { int_neg, rat_neg }

/*
	Helpers to extract values from the `Int`.
*/
int_bitfield_extract_single :: proc(a: ^Int, offset: int, allocator := context.allocator) -> (bit: _WORD, err: Error) {
	return #force_inline int_bitfield_extract(a, offset, 1, allocator)
}

int_bitfield_extract :: proc(a: ^Int, offset, count: int, allocator := context.allocator) -> (res: _WORD, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	context.allocator = allocator

	#force_inline internal_clear_if_uninitialized(a) or_return
	return #force_inline internal_int_bitfield_extract(a, offset, count)
}

/*
	Resize backing store.
*/
shrink :: proc(a: ^Int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	context.allocator = allocator

	#force_inline internal_clear_if_uninitialized(a) or_return
	return #force_inline internal_shrink(a)
}

int_grow :: proc(a: ^Int, digits: int, allow_shrink := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_int_grow(a, digits, allow_shrink, allocator)
}
grow :: proc { int_grow, }

/*
	Clear `Int` and resize it to the default size.
*/
int_clear :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_int_clear(a, minimize, allocator)
}
clear :: proc { int_clear, }
zero  :: clear

/*
	Set the `Int` to 1 and optionally shrink it to the minimum backing size.
*/
int_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_one(a, minimize, allocator)
}
one :: proc { int_one, }

/*
	Set the `Int` to -1 and optionally shrink it to the minimum backing size.
*/
int_minus_one :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_minus_one(a, minimize, allocator)
}
minus_one :: proc { int_minus_one, }

/*
	Set the `Int` to Inf and optionally shrink it to the minimum backing size.
*/
int_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_inf(a, minimize, allocator)
}
inf :: proc { int_inf, }

/*
	Set the `Int` to -Inf and optionally shrink it to the minimum backing size.
*/
int_minus_inf :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_minus_inf(a, minimize, allocator)
}
minus_inf :: proc { int_inf, }

/*
	Set the `Int` to NaN and optionally shrink it to the minimum backing size.
*/
int_nan :: proc(a: ^Int, minimize := false, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_nan(a, minimize, allocator)
}
nan :: proc { int_nan, }

power_of_two :: proc(a: ^Int, power: int, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return #force_inline internal_int_power_of_two(a, power, allocator)
}

int_get_u128 :: proc(a: ^Int, allocator := context.allocator) -> (res: u128, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, u128, allocator)
}
get_u128 :: proc { int_get_u128, }

int_get_i128 :: proc(a: ^Int, allocator := context.allocator) -> (res: i128, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, i128, allocator)
}
get_i128 :: proc { int_get_i128, }

int_get_u64 :: proc(a: ^Int, allocator := context.allocator) -> (res: u64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, u64, allocator)
}
get_u64 :: proc { int_get_u64, }

int_get_i64 :: proc(a: ^Int, allocator := context.allocator) -> (res: i64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, i64, allocator)
}
get_i64 :: proc { int_get_i64, }

int_get_u32 :: proc(a: ^Int, allocator := context.allocator) -> (res: u32, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, u32, allocator)
}
get_u32 :: proc { int_get_u32, }

int_get_i32 :: proc(a: ^Int, allocator := context.allocator) -> (res: i32, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	return int_get(a, i32, allocator)
}
get_i32 :: proc { int_get_i32, }

/*
	TODO: Think about using `count_bits` to check if the value could be returned completely,
	and maybe return max(T), .Integer_Overflow if not?
*/
int_get :: proc(a: ^Int, $T: typeid, allocator := context.allocator) -> (res: T, err: Error) where intrinsics.type_is_integer(T) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return
	return #force_inline internal_int_get(a, T)
}
get :: proc { int_get, }

int_get_float :: proc(a: ^Int, allocator := context.allocator) -> (res: f64, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return
	return #force_inline internal_int_get_float(a)
}

/*
	Count bits in an `Int`.
*/
count_bits :: proc(a: ^Int, allocator := context.allocator) -> (count: int, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return
	return #force_inline internal_count_bits(a), nil
}

/*
	Returns the number of trailing zeroes before the first one.
	Differs from regular `ctz` in that 0 returns 0.
*/
int_count_lsb :: proc(a: ^Int, allocator := context.allocator) -> (count: int, err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return
	return #force_inline internal_int_count_lsb(a)
}

platform_count_lsb :: #force_inline proc(a: $T) -> (count: int)
	where intrinsics.type_is_integer(T) && intrinsics.type_is_unsigned(T) {
	return int(intrinsics.count_trailing_zeros(a)) if a > 0 else 0
}

count_lsb :: proc { int_count_lsb, platform_count_lsb, }

int_random_digit :: proc(r: ^rnd.Rand = nil) -> (res: DIGIT) {
	when _DIGIT_BITS == 60 { // DIGIT = u64
		return DIGIT(rnd.uint64(r)) & _MASK
	} else when _DIGIT_BITS == 28 { // DIGIT = u32
		return DIGIT(rnd.uint32(r)) & _MASK
	} else {
		panic("Unsupported DIGIT size.")
	}

	return 0 // We shouldn't get here.
}

int_random :: proc(dest: ^Int, bits: int, r: ^rnd.Rand = nil, allocator := context.allocator) -> (err: Error) {
	/*
		Check that `a` is usable.
	*/
	assert_if_nil(dest)
	return #force_inline internal_int_random(dest, bits, r, allocator)

}
random :: proc { int_random, }

/*
	Internal helpers.
*/
assert_initialized :: proc(a: ^Int, loc := #caller_location) {
	assert_if_nil(a)
	assert(is_initialized(a), "`Int` was not properly initialized.", loc)
}

zero_unused :: proc(dest: ^Int, old_used := -1) {
	assert_if_nil(dest)
	if ! #force_inline is_initialized(dest) { return }

	#force_inline internal_zero_unused(dest, old_used)
}

clear_if_uninitialized_single :: proc(arg: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(arg)
	return #force_inline internal_clear_if_uninitialized_single(arg, allocator)
}

clear_if_uninitialized_multi :: proc(args: ..^Int, allocator := context.allocator) -> (err: Error) {
	args := args
	assert_if_nil(..args)

	for i in args {
		#force_inline internal_clear_if_uninitialized_single(i, allocator) or_return
	}
	return err
}
clear_if_uninitialized :: proc {clear_if_uninitialized_single, clear_if_uninitialized_multi, }

error_if_immutable_single :: proc(arg: ^Int) -> (err: Error) {
	if arg != nil && .Immutable in arg.flags { return .Assignment_To_Immutable }
	return nil
}

error_if_immutable_multi :: proc(args: ..^Int) -> (err: Error) {
	for i in args {
		if i != nil && .Immutable in i.flags { return .Assignment_To_Immutable }
	}
	return nil
}
error_if_immutable :: proc {error_if_immutable_single, error_if_immutable_multi, }

/*
	Allocates several `Int`s at once.
*/
int_init_multi :: proc(integers: ..^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(..integers)

	integers := integers
	for a in integers {
		#force_inline internal_clear(a, true, allocator) or_return
	}
	return nil
}

init_multi :: proc { int_init_multi, }

copy_digits :: proc(dest, src: ^Int, digits: int, offset := int(0), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		Check that `src` is usable and `dest` isn't immutable.
	*/
	assert_if_nil(dest, src)
	#force_inline internal_clear_if_uninitialized(src) or_return

	return #force_inline internal_copy_digits(dest, src, digits, offset)
}

/*
	Trim unused digits.

	This is used to ensure that leading zero digits are trimmed and the leading "used" digit will be non-zero.
	Typically very fast.  Also fixes the sign if there are no more leading digits.
*/
clamp :: proc(a: ^Int, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return

	for a.used > 0 && a.digit[a.used - 1] == 0 {
		a.used -= 1
	}

	if z, _ := is_zero(a); z {
		a.sign = .Zero_or_Positive
	}
	return nil
}


/*
	Size binary representation	
*/
int_to_bytes_size :: proc(a: ^Int, signed := false, allocator := context.allocator) -> (size_in_bytes: int, err: Error) {
	assert_if_nil(a)
	#force_inline internal_clear_if_uninitialized(a, allocator) or_return

	size_in_bits := internal_count_bits(a)

	size_in_bytes  = (size_in_bits / 8)
	size_in_bytes += 0 if size_in_bits % 8 == 0 else 1
	size_in_bytes += 1 if signed else 0
	return
}

/*
	Return Little Endian binary representation of `a`, either signed or unsigned.
	If `a` is negative and we ask for the default unsigned representation, we return abs(a).
*/
int_to_bytes_little :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)

	size_in_bytes := int_to_bytes_size(a, signed, allocator) or_return
	l := len(buf)
	if size_in_bytes > l { return .Buffer_Overflow }

	size_in_bits := internal_count_bits(a)
	i := 0
	if signed {
		buf[l - 1] = 1 if a.sign == .Negative else 0
	}
	#no_bounds_check for offset := 0; offset < size_in_bits; offset += 8 {
		bits, _ := internal_int_bitfield_extract(a, offset, 8)
		buf[i] = u8(bits & 255); i += 1
	}
	return
}

/*
	Return Big Endian binary representation of `a`, either signed or unsigned.
	If `a` is negative and we ask for the default unsigned representation, we return abs(a).
*/
int_to_bytes_big :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)

	size_in_bytes := int_to_bytes_size(a, signed, allocator) or_return
	l := len(buf)
	if size_in_bytes > l { return .Buffer_Overflow }

	size_in_bits := internal_count_bits(a)
	i := l - 1

	if signed {
		buf[0] = 1 if a.sign == .Negative else 0
	}
	#no_bounds_check for offset := 0; offset < size_in_bits; offset += 8 {
		bits, _ := internal_int_bitfield_extract(a, offset, 8)
		buf[i] = u8(bits & 255); i -= 1
	}
	return
}

/*
	Return Python 3.x compatible Little Endian binary representation of `a`, either signed or unsigned.
	If `a` is negative when asking for an unsigned number, we return an error like Python does.
*/
int_to_bytes_little_python :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)

	if !signed && a.sign == .Negative { return .Invalid_Argument }

	l := len(buf)
	size_in_bytes := int_to_bytes_size(a, signed, allocator) or_return
	if size_in_bytes > l { return .Buffer_Overflow  }

	if a.sign == .Negative {
		t := &Int{}
		defer destroy(t)
		internal_complement(t, a, allocator) or_return

		size_in_bits := internal_count_bits(t)
		i := 0
		#no_bounds_check for offset := 0; offset < size_in_bits; offset += 8 {
			bits, _ := internal_int_bitfield_extract(t, offset, 8)
			buf[i] = 255 - u8(bits & 255); i += 1
		}
		buf[l-1] = 255
	} else {
		size_in_bits := internal_count_bits(a)
		i := 0
		#no_bounds_check for offset := 0; offset < size_in_bits; offset += 8 {
			bits, _ := internal_int_bitfield_extract(a, offset, 8)
			buf[i] = u8(bits & 255); i += 1
		}
	}
	return
}

/*
	Return Python 3.x compatible Big Endian binary representation of `a`, either signed or unsigned.
	If `a` is negative when asking for an unsigned number, we return an error like Python does.
*/
int_to_bytes_big_python :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)

	if !signed && a.sign == .Negative { return .Invalid_Argument }
	if a.sign == .Zero_or_Positive    { return int_to_bytes_big(a, buf, signed, allocator) }

	l := len(buf)
	size_in_bytes := int_to_bytes_size(a, signed, allocator) or_return
	if size_in_bytes > l { return .Buffer_Overflow  }

	t := &Int{}
	defer destroy(t)

	internal_complement(t, a, allocator) or_return

	size_in_bits := internal_count_bits(t)
	i := l - 1
	#no_bounds_check for offset := 0; offset < size_in_bits; offset += 8 {
		bits, _ := internal_int_bitfield_extract(t, offset, 8)
		buf[i] = 255 - u8(bits & 255); i -= 1
	}
	buf[0] = 255

	return
}

/*
	Read `Int` from a Big Endian binary representation.
	Sign is detected from the first byte if `signed` is true.
*/
int_from_bytes_big :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)
	buf := buf
	l := len(buf)
	if l == 0 { return .Invalid_Argument }

	sign: Sign
	size_in_bits := l * 8
	if signed { 
		/*
			First byte denotes the sign.
		*/
		size_in_bits -= 8
	}
	size_in_digits := (size_in_bits + _DIGIT_BITS - 1) / _DIGIT_BITS
	size_in_digits += 0 if size_in_bits % 8 == 0 else 1
	internal_zero(a, false, allocator) or_return
	internal_grow(a, size_in_digits, false, allocator) or_return

	if signed {
		sign = .Zero_or_Positive if buf[0] == 0 else .Negative
		buf = buf[1:]
	}

	#no_bounds_check for v in buf {
		internal_shl(a, a, 8) or_return
		a.digit[0] |= DIGIT(v)
	}
	a.sign = sign
	a.used = size_in_digits
	return internal_clamp(a)
}

/*
	Read `Int` from a Big Endian Python binary representation.
	Sign is detected from the first byte if `signed` is true.
*/
int_from_bytes_big_python :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)
	buf := buf
	l := len(buf)
	if l == 0 { return .Invalid_Argument }

	sign: Sign
	size_in_bits := l * 8
	if signed { 
		/*
			First byte denotes the sign.
		*/
		size_in_bits -= 8
	}
	size_in_digits := (size_in_bits + _DIGIT_BITS - 1) / _DIGIT_BITS
	size_in_digits += 0 if size_in_bits % 8 == 0 else 1
	internal_zero(a, false, allocator) or_return
	internal_grow(a, size_in_digits, false, allocator) or_return

	if signed {
		sign = .Zero_or_Positive if buf[0] == 0 else .Negative
		buf = buf[1:]
	}

	#no_bounds_check for v in buf {
		internal_shl(a, a, 8) or_return
		if signed && sign == .Negative {
			a.digit[0] |= DIGIT(255 - v)	
		} else {
			a.digit[0] |= DIGIT(v)
		}
	}
	a.sign = sign
	a.used = size_in_digits
	internal_clamp(a) or_return

	if signed && sign == .Negative {
		return internal_sub(a, a, 1)
	}
	return nil
}

/*
	Read `Int` from a Little Endian binary representation.
	Sign is detected from the last byte if `signed` is true.
*/
int_from_bytes_little :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)
	buf := buf
	l := len(buf)
	if l == 0 { return .Invalid_Argument }

	sign: Sign
	size_in_bits   := l * 8
	if signed { 
		/*
			First byte denotes the sign.
		*/
		size_in_bits -= 8
	}
	size_in_digits := (size_in_bits + _DIGIT_BITS - 1) / _DIGIT_BITS
	size_in_digits += 0 if size_in_bits % 8 == 0 else 1
	internal_zero(a, false, allocator) or_return
	internal_grow(a, size_in_digits, false, allocator) or_return

	if signed {
		sign = .Zero_or_Positive if buf[l-1] == 0 else .Negative
		buf = buf[:l-1]
		l -= 1
	}

	for _, i in buf {
		internal_shl(a, a, 8) or_return
		a.digit[0] |= DIGIT(buf[l-i-1])
	}
	a.sign = sign
	a.used = size_in_digits
	return internal_clamp(a)
}

/*
	Read `Int` from a Little Endian Python binary representation.
	Sign is detected from the first byte if `signed` is true.
*/
int_from_bytes_little_python :: proc(a: ^Int, buf: []u8, signed := false, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(a)
	buf := buf
	l := len(buf)
	if l == 0 { return .Invalid_Argument }

	sign: Sign
	size_in_bits := l * 8
	if signed { 
		/*
			First byte denotes the sign.
		*/
		size_in_bits -= 8
	}
	size_in_digits := (size_in_bits + _DIGIT_BITS - 1) / _DIGIT_BITS
	size_in_digits += 0 if size_in_bits % 8 == 0 else 1
	internal_zero(a, false, allocator) or_return
	internal_grow(a, size_in_digits, false, allocator) or_return

	if signed {
		sign = .Zero_or_Positive if buf[l-1] == 0 else .Negative
		buf = buf[:l-1]
		l -= 1
	}

	for _, i in buf {
		internal_shl(a, a, 8) or_return
		if signed && sign == .Negative {
			a.digit[0] |= DIGIT(255 - buf[l-i-1])
		} else {
			a.digit[0] |= DIGIT(buf[l-i-1])
		}
	}
	a.sign = sign
	a.used = size_in_digits
	internal_clamp(a) or_return

	if signed && sign == .Negative {
		return internal_sub(a, a, 1)
	}
	return nil
}

/*
	Initialize constants.
*/
INT_ONE, INT_ZERO, INT_MINUS_ONE, INT_INF, INT_MINUS_INF, INT_NAN := &Int{}, &Int{}, &Int{}, &Int{}, &Int{}, &Int{}

@(init, private)
_init_constants :: proc() {
	initialize_constants()
}

initialize_constants :: proc() -> (res: int) {
	internal_set(     INT_ZERO,  0);      INT_ZERO.flags = {.Immutable}
	internal_set(      INT_ONE,  1);       INT_ONE.flags = {.Immutable}
	internal_set(INT_MINUS_ONE, -1); INT_MINUS_ONE.flags = {.Immutable}

	/*
		We set these special values to -1 or 1 so they don't get mistake for zero accidentally.
		This allows for shortcut tests of is_zero as .used == 0.
	*/
	internal_set(      INT_NAN,  1);       INT_NAN.flags = {.Immutable, .NaN}
	internal_set(      INT_INF,  1);       INT_INF.flags = {.Immutable, .Inf}
	internal_set(INT_MINUS_INF, -1); INT_MINUS_INF.flags = {.Immutable, .Inf}

	return _DEFAULT_MUL_KARATSUBA_CUTOFF
}

/*
	Destroy constants.
	Optional for an EXE, as this would be called at the very end of a process.
*/
destroy_constants :: proc() {
	internal_destroy(INT_ONE, INT_ZERO, INT_MINUS_ONE, INT_INF, INT_MINUS_INF, INT_NAN)
}


assert_if_nil :: proc{
	assert_if_nil_int,
	assert_if_nil_rat,
}

assert_if_nil_int :: #force_inline proc(integers: ..^Int, loc := #caller_location) {
	for i in integers {
		assert(i != nil, "(nil)", loc)
	}
}

assert_if_nil_rat :: #force_inline proc(rationals: ..^Rat, loc := #caller_location) {
	for r in rationals {
		assert(r != nil, "(nil)", loc)
	}
}
