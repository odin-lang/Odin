/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains radix conversions, `string_to_int` (atoi) and `int_to_string` (itoa).

	TODO:
		- Use Barrett reduction for non-powers-of-two.
		- Also look at extracting and splatting several digits at once.
*/


package math_big

import "base:intrinsics"
import "core:mem"
import "core:os"

/*
	This version of `itoa` allocates on behalf of the caller. The caller must free the string.
	The radix defaults to 10.
*/
int_itoa_string :: proc(a: ^Int, radix := i8(10), zero_terminate := false, allocator := context.allocator) -> (res: string, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	a := a; radix := radix
	clear_if_uninitialized(a) or_return

	/*
		TODO: If we want to write a prefix for some of the radixes, we can oversize the buffer.
		Then after the digits are written and the string is reversed
	*/

	/*
		Calculate the size of the buffer we need, and 
		Exit if calculating the size returned an error.
	*/
	size := radix_size(a, radix, zero_terminate) or_return

	/*
		Allocate the buffer we need.
	*/
	buffer := make([]u8, size)

	/*
		Write the digits out into the buffer.
	*/
	written: int
	written, err = int_itoa_raw(a, radix, buffer, size, zero_terminate)

	return string(buffer[:written]), err
}

/*
	This version of `itoa` allocates on behalf of the caller. The caller must free the string.
	The radix defaults to 10.
*/
int_itoa_cstring :: proc(a: ^Int, radix := i8(10), allocator := context.allocator) -> (res: cstring, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	a := a; radix := radix
	clear_if_uninitialized(a) or_return

	s: string
	s, err = int_itoa_string(a, radix, true)
	return cstring(raw_data(s)), err
}

/*
	A low-level `itoa` using a caller-provided buffer. `itoa_string` and `itoa_cstring` use this.
	You can use also use it if you want to pre-allocate a buffer and optionally reuse it.

	Use `radix_size` or `radix_size_estimate` to determine a buffer size big enough.

	You can pass the output of `radix_size` to `size` if you've previously called it to size
	the output buffer. If you haven't, this routine will call it. This way it knows if the buffer
	is the appropriate size, and we can write directly in place without a reverse step at the end.

					=== === === IMPORTANT === === ===

	If you determined the buffer size using `radix_size_estimate`, or have a buffer
	that you reuse that you know is large enough, don't pass this size unless you know what you are doing,
	because we will always write backwards starting at last byte of the buffer.

	Keep in mind that if you set `size` yourself and it's smaller than the buffer,
	it'll result in buffer overflows, as we use it to avoid reversing at the end
	and having to perform a buffer overflow check each character.
*/
int_itoa_raw :: proc(a: ^Int, radix: i8, buffer: []u8, size := int(-1), zero_terminate := false) -> (written: int, err: Error) {
	assert_if_nil(a)
	a := a; radix := radix; size := size
	clear_if_uninitialized(a) or_return
	/*
		Radix defaults to 10.
	*/
	radix = radix if radix > 0 else 10
	if radix < 2 || radix > 64 {
		return 0, .Invalid_Argument
	}

	/*
		We weren't given a size. Let's compute it.
	*/
	if size == -1 {
		size = radix_size(a, radix, zero_terminate) or_return
	}

	/*
		Early exit if the buffer we were given is too small.
	*/
	available := len(buffer)
	if available < size {
		return 0, .Buffer_Overflow
	}
	/*
		Fast path for when `Int` == 0 or the entire `Int` fits in a single radix digit.
	*/
	z, _ := is_zero(a)
	if z || (a.used == 1 && a.digit[0] < DIGIT(radix)) {
		if zero_terminate {
			available -= 1
			buffer[available] = 0
		}
		available -= 1
		buffer[available] = RADIX_TABLE[a.digit[0]]

		if n, _ := is_neg(a); n {
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if written < size {
			diff := size - written
			mem.copy(&buffer[0], &buffer[diff], written)
		}
		return written, nil
	}

	/*
		Fast path for when `Int` fits within a `_WORD`.
	*/
	if a.used == 1 || a.used == 2 {
		if zero_terminate {
			available -= 1
			buffer[available] = 0
		}

		val := _WORD(a.digit[1]) << _DIGIT_BITS + _WORD(a.digit[0])
		for val > 0 {
			q := val / _WORD(radix)
			available -= 1
			buffer[available] = RADIX_TABLE[val - (q * _WORD(radix))]

			val = q
		}
		if n, _ := is_neg(a); n {
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if written < size {
			diff := size - written
			mem.copy(&buffer[0], &buffer[diff], written)
		}
		return written, nil
	}

	/*
		Fast path for radixes that are a power of two.
	*/
	if is_power_of_two(int(radix)) {
		if zero_terminate {
			available -= 1
			buffer[available] = 0
		}

		shift, count: int
		// mask  := _WORD(radix - 1);
		shift, err = log(DIGIT(radix), 2)
		count, err = count_bits(a)
		digit: _WORD

		for offset := 0; offset < count; offset += shift {
			bits_to_get := int(min(count - offset, shift))

			digit, err = int_bitfield_extract(a, offset, bits_to_get)
			if err != nil {
				return len(buffer) - available, .Invalid_Argument
			}
			available -= 1
			buffer[available] = RADIX_TABLE[digit]
		}

		if n, _ := is_neg(a); n {
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if written < size {
			diff := size - written
			mem.copy(&buffer[0], &buffer[diff], written)
		}
		return written, nil
	}

	return _itoa_raw_full(a, radix, buffer, zero_terminate)
}

itoa :: proc{int_itoa_string, int_itoa_raw}
int_to_string  :: int_itoa_string
int_to_cstring :: int_itoa_cstring

/*
	Read a string [ASCII] in a given radix.
*/
int_atoi :: proc(res: ^Int, input: string, radix := i8(10), allocator := context.allocator) -> (err: Error) {
	assert_if_nil(res)
	input := input
	context.allocator = allocator

	/*
		Make sure the radix is ok.
	*/

	if radix < 2 || radix > 64 { return .Invalid_Argument }

	/*
		Set the integer to the default of zero.
	*/
	internal_zero(res) or_return

	/*
		We'll interpret an empty string as zero.
	*/
	if len(input) == 0 {
		return nil
	}

	/*
		If the leading digit is a minus set the sign to negative.
		Given the above early out, the length should be at least 1.
	*/
	sign := Sign.Zero_or_Positive
	if input[0] == '-' {
		input = input[1:]
		sign = .Negative
	}

	/*
		Process each digit of the string.
	*/
	ch: rune
	for len(input) > 0 {
		/* if the radix <= 36 the conversion is case insensitive
		 * this allows numbers like 1AB and 1ab to represent the same value
		 * [e.g. in hex]
		*/

		ch = rune(input[0])
		if radix <= 36 && ch >= 'a' && ch <= 'z' {
			ch -= 32 // 'a' - 'A'
		}

		pos := ch - '+'
		if RADIX_TABLE_REVERSE_SIZE <= pos {
			break
		}
		y := RADIX_TABLE_REVERSE[pos]
		/* if the char was found in the map
		 * and is less than the given radix add it
		 * to the number, otherwise exit the loop.
		 */
		if y >= u8(radix) {
			break
		}

		internal_mul(res, res, DIGIT(radix)) or_return
		internal_add(res, res, DIGIT(y))     or_return

		input = input[1:]
	}
	/*
		If an illegal character was found, fail.
	*/
	if len(input) > 0 && ch != 0 && ch != '\r' && ch != '\n' {
		return .Invalid_Argument
	}
	/*
		Set the sign only if res != 0.
	*/
	if res.used > 0 {
		res.sign = sign
	}

	return nil
}


atoi :: proc { int_atoi, }

/*
	We size for `string` by default.
*/
radix_size :: proc(a: ^Int, radix: i8, zero_terminate := false, allocator := context.allocator) -> (size: int, err: Error) {
	a := a
	assert_if_nil(a)

	if radix < 2 || radix > 64                     { return -1, .Invalid_Argument }
	clear_if_uninitialized(a) or_return

	if internal_is_zero(a) {
		if zero_terminate {
			return 2, nil
		}
		return 1, nil
	}

	if internal_is_power_of_two(a) {
		/*
			Calculate `log` on a temporary "copy" with its sign set to positive.
		*/
		t := &Int{
			used      = a.used,
			sign      = .Zero_or_Positive,
			digit     = a.digit,
		}

		size = internal_log(t, DIGIT(radix)) or_return
	} else {
		la, k := &Int{}, &Int{}
		defer internal_destroy(la, k)

		/* la = floor(log_2(a)) + 1 */
		bit_count := internal_count_bits(a)
		internal_set(la, bit_count) or_return

		/* k = floor(2^29/log_2(radix)) + 1 */
		lb := _log_bases
		internal_set(k, lb[radix]) or_return

		/* n = floor((la *  k) / 2^29) + 1 */
		internal_mul(k, la, k) or_return
		internal_shr(k, k, _RADIX_SIZE_SCALE) or_return

		/* The "+1" here is the "+1" in "floor((la *  k) / 2^29) + 1" */
		/* n = n + 1 + EOS + sign */
		size_, _ := internal_get(k, u128)
		size = int(size_)
	}

	/*
		log truncates to zero, so we need to add one more, and one for `-` if negative.
	*/
	size += 2 if a.sign == .Negative else 1
	size += 1 if zero_terminate else 0
	return size, nil
}

/*
	We might add functions to read and write byte-encoded Ints from/to files, using `int_to_bytes_*` functions.

	LibTomMath allows exporting/importing to/from a file in ASCII, but it doesn't support a much more compact representation in binary, even though it has several pack functions int_to_bytes_* (which I expanded upon and wrote Python interoperable versions of as well), and (un)pack, which is GMP compatible.
	Someone could implement their own read/write binary int procedures, of course.

	Could be worthwhile to add a canonical binary file representation with an optional small header that says it's an Odin big.Int, big.Rat or Big.Float, byte count for each component that follows, flag for big/little endian and a flag that says a checksum exists at the end of the file.
	For big.Rat and big.Float the header couldn't be optional, because we'd have no way to distinguish where the components end.
*/

/*
	Read an Int from an ASCII file.
*/
internal_int_read_from_ascii_file :: proc(a: ^Int, filename: string, radix := i8(10), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		We can either read the entire file at once, or read a bunch at a time and keep multiplying by the radix.
		For now, we'll read the entire file. Eventually we'll replace this with a copy that duplicates the logic
		of `atoi` so we don't need to read the entire file.
	*/

	res, ok := os.read_entire_file(filename, allocator)
	defer delete(res, allocator)

	if !ok {
		return .Cannot_Read_File
	}

	as := string(res)
	return atoi(a, as, radix)
}

/*
	Write an Int to an ASCII file.
*/
internal_int_write_to_ascii_file :: proc(a: ^Int, filename: string, radix := i8(10), allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	/*
		For now we'll convert the Int using itoa and writing the result in one go.
		If we want to preserve memory we could duplicate the itoa logic and write backwards.
	*/

	as := itoa(a, radix) or_return
	defer delete(as)

	l := len(as)
	assert(l > 0)

	data := transmute([]u8)mem.Raw_Slice{
		data = raw_data(as),
		len  = l,
	}

	ok := os.write_entire_file(filename, data, truncate=true)
	return nil if ok else .Cannot_Write_File
}

/*
	Calculate the size needed for `internal_int_pack`.

	See https://gmplib.org/manual/Integer-Import-and-Export.html
*/
internal_int_pack_count :: proc(a: ^Int, $T: typeid, nails := 0) -> (size_needed: int) {
	assert(nails >= 0 && nails < (size_of(T) * 8))

	bits := internal_count_bits(a)
	size := size_of(T)

	size_needed  =  bits / ((size * 8) - nails)
	size_needed += 1 if (bits % ((size * 8) - nails)) != 0 else 0

	return size_needed
}

/*
	Based on gmp's mpz_export.
	See https://gmplib.org/manual/Integer-Import-and-Export.html

	`buf` is a pre-allocated slice of type `T` "words", which must be an unsigned integer of some description.
		Use `internal_int_pack_count(a, T, nails)` to calculate the necessary size.
		The library internally uses `DIGIT` as the type, which is u64 or u32 depending on the platform.
		You are of course welcome to export to []u8, []u32be, and so forth.
		After this you can use `mem.slice_data_cast` to interpret the buffer as bytes if you so choose.

	`nails` are the number of top bits the output "word" reserves.
		To mimic the internals of this library, this would be 4.

	To use the minimum amount of output bytes, set `nails` to 0 and pass a `[]u8`.
	IMPORTANT: `pack` serializes the magnitude of an Int, that is, the output is unsigned.

	Assumes `a` not to be `nil` and to have been initialized.
*/
internal_int_pack :: proc(a: ^Int, buf: []$T, nails := 0, order := Order.LSB_First) -> (written: int, err: Error)
                     where intrinsics.type_is_integer(T), intrinsics.type_is_unsigned(T), size_of(T) <= 16 {

	assert(nails >= 0 && nails < (size_of(T) * 8))

	type_size  := size_of(T)
	type_bits  := (type_size * 8) - nails

	word_count := internal_int_pack_count(a, T, nails)
	bit_count  := internal_count_bits(a)

	if len(buf) < word_count {
		return 0, .Buffer_Overflow
	}

	bit_offset  := 0
	word_offset := 0

	#no_bounds_check for i := 0; i < word_count; i += 1 {
		bit_offset = i * type_bits
		if order == .MSB_First {
			word_offset = word_count - i - 1
		} else {
			word_offset = i
		}

		bits_to_get := min(type_bits, bit_count - bit_offset)
		W := internal_int_bitfield_extract(a, bit_offset, bits_to_get) or_return
		buf[word_offset] = T(W)
	}

	return word_count, nil
}



internal_int_unpack :: proc(a: ^Int, buf: []$T, nails := 0, order := Order.LSB_First, allocator := context.allocator) -> (err: Error)
                     where intrinsics.type_is_integer(T), intrinsics.type_is_unsigned(T), size_of(T) <= 16 {
	assert(nails >= 0 && nails < (size_of(T) * 8))
	context.allocator = allocator

	type_size  := size_of(T)
	type_bits  := (type_size * 8) - nails
	type_mask  := T(1 << uint(type_bits)) - 1

	if len(buf) == 0 {
		return .Invalid_Argument
	}

	bit_count   := type_bits * len(buf)
	digit_count := (bit_count / _DIGIT_BITS) + min(1, bit_count % _DIGIT_BITS)

	/*
		Pre-size output Int.
	*/
	internal_grow(a, digit_count) or_return

	t := &Int{}
	defer internal_destroy(t)

	if order == .LSB_First {
		for W, i in buf {
			internal_set(t, W & type_mask)                           or_return
			internal_shl(t, t, type_bits * i)                        or_return
			internal_add(a, a, t)                                    or_return
		}
	} else {
		for W in buf {
			internal_set(t, W & type_mask)                           or_return
			internal_shl(a, a, type_bits)                            or_return
			internal_add(a, a, t)                                    or_return
		}		
	}

	return internal_clamp(a)
}

/*
	Overestimate the size needed for the bigint to string conversion by a very small amount.
	The error is about 10^-8; it will overestimate the result by at most 11 elements for
	a number of the size 2^(2^31)-1 which is currently the largest possible in this library.
	Some short tests gave no results larger than 5 (plus 2 for sign and EOS).
 */

/*
	Table of {0, INT(log_2([1..64])*2^p)+1 } where p is the scale
	factor defined in MP_RADIX_SIZE_SCALE and INT() extracts the integer part (truncating).
	Good for 32 bit "int". Set MP_RADIX_SIZE_SCALE = 61 and recompute values
	for 64 bit "int".
 */

_RADIX_SIZE_SCALE :: 29
_log_bases :: [65]u32{
			0,         0, 0x20000001, 0x14309399, 0x10000001,
	0xdc81a35, 0xc611924,  0xb660c9e,  0xaaaaaab,  0xa1849cd,
	0x9a209a9, 0x94004e1,  0x8ed19c2,  0x8a5ca7d,  0x867a000,
	0x830cee3, 0x8000001,  0x7d42d60,  0x7ac8b32,  0x7887847,
	0x7677349, 0x749131f,  0x72d0163,  0x712f657,  0x6fab5db,
	0x6e40d1b, 0x6ced0d0,  0x6badbde,  0x6a80e3b,  0x6964c19,
	0x6857d31, 0x6758c38,  0x6666667,  0x657fb21,  0x64a3b9f,
	0x63d1ab4, 0x6308c92,  0x624869e,  0x618ff47,  0x60dedea,
	0x6034ab0, 0x5f90e7b,  0x5ef32cb,  0x5e5b1b2,  0x5dc85c3,
	0x5d3aa02, 0x5cb19d9,  0x5c2d10f,  0x5bacbbf,  0x5b3064f,
	0x5ab7d68, 0x5a42df0,  0x59d1506,  0x5962ffe,  0x58f7c57,
	0x588f7bc, 0x582a000,  0x57c7319,  0x5766f1d,  0x5709243,
	0x56adad9, 0x565474d,  0x55fd61f,  0x55a85e8,  0x5555556,
}

/*
	Characters used in radix conversions.
*/
RADIX_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
RADIX_TABLE_REVERSE := [RADIX_TABLE_REVERSE_SIZE]u8{
	0x3e, 0xff, 0xff, 0xff, 0x3f, 0x00, 0x01, 0x02, 0x03, 0x04, /* +,-./01234 */
	0x05, 0x06, 0x07, 0x08, 0x09, 0xff, 0xff, 0xff, 0xff, 0xff, /* 56789:;<=> */
	0xff, 0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, /* ?@ABCDEFGH */
	0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, /* IJKLMNOPQR */
	0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0xff, 0xff, /* STUVWXYZ[\ */
	0xff, 0xff, 0xff, 0xff, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, /* ]^_`abcdef */
	0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, /* ghijklmnop */
	0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, /* qrstuvwxyz */
}
RADIX_TABLE_REVERSE_SIZE :: 80

/*
	Stores a bignum as a ASCII string in a given radix (2..64)
	The buffer must be appropriately sized. This routine doesn't check.
*/
_itoa_raw_full :: proc(a: ^Int, radix: i8, buffer: []u8, zero_terminate := false, allocator := context.allocator) -> (written: int, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	temp, denominator := &Int{}, &Int{}

	internal_copy(temp, a)           or_return
	internal_set(denominator, radix) or_return

	available := len(buffer)
	if zero_terminate {
		available -= 1
		buffer[available] = 0
	}

	if a.sign == .Negative {
		temp.sign = .Zero_or_Positive
	}

	remainder: DIGIT
	for {
		if remainder, err = #force_inline internal_divmod(temp, temp, DIGIT(radix)); err != nil {
			internal_destroy(temp, denominator)
			return len(buffer) - available, err
		}
		available -= 1
		buffer[available] = RADIX_TABLE[remainder]
		if temp.used == 0 {
			break
		}
	}

	if a.sign == .Negative {
		available -= 1
		buffer[available] = '-'
	}

	internal_destroy(temp, denominator)

	/*
		If we overestimated the size, we need to move the buffer left.
	*/
	written = len(buffer) - available
	if written < len(buffer) {
		diff := len(buffer) - written
		mem.copy(&buffer[0], &buffer[diff], written)
	}
	return written, nil
}