package math_big

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains radix conversions, `string_to_int` (atoi) and `int_to_string` (itoa).

	TODO:
		- Use Barrett reduction for non-powers-of-two.
		- Also look at extracting and splatting several digits at once.
*/

import "base:intrinsics"

/*
	This version of `itoa` allocates on behalf of the caller. The caller must free the string.
	The radix defaults to 10.
*/
int_itoa_string :: proc(a: ^Int, radix := i8(10), zero_terminate := false, allocator := context.allocator) -> (res: string, err: Error) {
	assert_if_nil(a)
	a := a; radix := radix
	a = _zero_if_uninitialized(a)

	context.allocator = allocator

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
	buffer, mem_err := make([]u8, size)
	if mem_err != nil {
		err = cast(Error)mem_err
		return
	}

	/*
		Write the digits out into the buffer.
	*/
	written: int
	written, err = int_itoa_raw(a, radix, buffer, size, zero_terminate)
	if err != nil {
		delete(buffer)
		return "", err
	}

	return string(buffer[:written]), nil
}

/*
	This version of `itoa` allocates on behalf of the caller. The caller must free the string.
	The radix defaults to 10.
*/
int_itoa_cstring :: proc(a: ^Int, radix := i8(10), allocator := context.allocator) -> (res: cstring, err: Error) {
	assert_if_nil(a)
	a := a; radix := radix
	a = _zero_if_uninitialized(a)

	context.allocator = allocator

	s: string
	s, err = int_itoa_string(a, radix, true)
	return cstring(raw_data(s)), err
}

/*
	A low-level `itoa` using a caller-provided buffer. `itoa_string` and `itoa_cstring` use this.
	You can use also use it if you want to pre-allocate a buffer and optionally reuse it.

	Use `radix_size` to determine a buffer size big enough.

	You can pass the output of `radix_size` to `size` if you've previously called it to size
	the output buffer. If you haven't, this routine will call it. This way it knows if the buffer
	is the appropriate size, and we can write directly in place without a reverse step at the end.

	The digits are written backwards from the end of `buffer` and then moved to the front,
	so the result is always `buffer[:written]`, however much larger than `size` the buffer is.

	`size` only saves the `radix_size` call. A buffer too small for the result gives `.Buffer_Overflow`.

	NaN and +/-Inf are written as "NaN", "+Inf" and "-Inf" in radix 2..=23. Radix 24..=64 gives `.Invalid_Argument`.
*/
int_itoa_raw :: proc(a: ^Int, radix: i8, buffer: []u8, size := int(-1), zero_terminate := false) -> (written: int, err: Error) {
	assert_if_nil(a)
	a := a; radix := radix; size := size
	a = _zero_if_uninitialized(a)
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
	if size < 0 {
		size = radix_size(a, radix, zero_terminate) or_return
	}

	/*
		Early exit if the buffer we were given is too small.
	*/
	available := len(buffer)
	if available < size {
		return 0, .Buffer_Overflow
	}

	if .NaN in a.flags || .Inf in a.flags {
		if radix > _MAX_NON_FINITE_RADIX { return 0, .Invalid_Argument }
		s := _non_finite_string(a)
		written = len(s) + (1 if zero_terminate else 0)
		if available < written { return 0, .Buffer_Overflow }
		intrinsics.mem_copy(&buffer[0], raw_data(s), len(s))
		if zero_terminate { buffer[len(s)] = 0 }
		return written, nil
	}

	/*
		Fast path for when `Int` == 0 or the entire `Int` fits in a single radix digit.
	*/
	z, _ := is_zero(a)
	if z || (a.used == 1 && a.digit[0] < DIGIT(radix)) {
		n, _ := is_neg(a)
		needed := 1
		if zero_terminate { needed += 1 }
		if n && !z        { needed += 1 }
		if available < needed {
			return 0, .Buffer_Overflow
		}

		if zero_terminate {
			available -= 1
			buffer[available] = 0
		}
		available -= 1
		buffer[available] = RADIX_TABLE[a.digit[0]]

		if n && !z {
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if available > 0 {
			intrinsics.mem_copy(&buffer[0], &buffer[available], written)
		}
		return written, nil
	}

	/*
		Fast path for when `Int` fits within a `_WORD`.
	*/
	if a.used == 1 || a.used == 2 {
		if zero_terminate {
			if available == 0 {
				return 0, .Buffer_Overflow
			}
			available -= 1
			buffer[available] = 0
		}

		val := _WORD(a.digit[1]) << _DIGIT_BITS + _WORD(a.digit[0])
		for val > 0 {
			if available == 0 {
				return 0, .Buffer_Overflow
			}
			q := val / _WORD(radix)
			available -= 1
			buffer[available] = RADIX_TABLE[val - (q * _WORD(radix))]

			val = q
		}
		if n, _ := is_neg(a); n {
			if available == 0 {
				return 0, .Buffer_Overflow
			}
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if available > 0 {
			intrinsics.mem_copy(&buffer[0], &buffer[available], written)
		}
		return written, nil
	}

	/*
		Fast path for radixes that are a power of two.
	*/
	count := count_bits(a) or_return

	if is_power_of_two(int(radix)) {
		shift := log(DIGIT(radix), 2) or_return
		n, _ := is_neg(a)
		needed := (count + shift - 1) / shift
		if zero_terminate { needed += 1 }
		if n              { needed += 1 }
		if available < needed {
			return 0, .Buffer_Overflow
		}

		if zero_terminate {
			available -= 1
			buffer[available] = 0
		}

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

		if n {
			available -= 1
			buffer[available] = '-'
		}

		/*
			If we overestimated the size, we need to move the buffer left.
		*/
		written = len(buffer) - available
		if available > 0 {
			intrinsics.mem_copy(&buffer[0], &buffer[available], written)
		}
		return written, nil
	}

	return _itoa_raw_full(a, radix, buffer, zero_terminate)
}

@(private)
_non_finite_string :: proc "contextless" (a: ^Int) -> string {
	if .NaN in a.flags { return "NaN" }
	return "-Inf" if a.sign == .Negative else "+Inf"
}

itoa :: proc{int_itoa_string, int_itoa_raw}
int_to_string  :: int_itoa_string
int_to_cstring :: int_itoa_cstring

/*
	Read a string [ASCII] in a given radix.

	If `n` isn't nil, it's set to the number of characters read, the same as `strconv`'s `n`: the
	digits, and a leading '-' if anything follows it. So `input[n:]` is whatever comes after them.

	In radix 2..=23, `input` may also start with "+Inf", "-Inf" or "NaN", which set `res` to +/-Inf or NaN and count as the number below.
	In radix 24..=64 they get no special treatment and are read like any other input, e.g. "NaN" is 30191 in radix 36.

	Returns:
	- `nil` if `input` is just the number.
	- `.Trailing_Whitespace` if only whitespace (`' '`, `'\t'`, `'\n'`, `'\v'`, `'\f'`, `'\r'`) or NUL
	  follows the number. `res` holds the number, so callers that don't mind trailing whitespace can
	  treat this as success. Other callers can trim `input` first.
	- `.Invalid_Character` if anything else follows the number, or `input` doesn't start with one,
	  e.g. `"12x"`, `"x"` or `"- \n"`. `res` holds whatever was read before that character.
	- `.Empty_Input` if `input` is `""`, `"-"` or only whitespace. `res` is zero.
	- `.Invalid_Argument` if `radix` isn't in 2..=64.
*/
int_atoi :: proc(res: ^Int, input: string, radix := i8(10), n: ^int = nil, allocator := context.allocator) -> (err: Error) {
	assert_if_nil(res)
	input_len := len(input)
	input := input
	context.allocator = allocator

	if n != nil {
		n^ = 0
	}

	/*
		Make sure the radix is ok.
	*/

	if radix < 2 || radix > 64 { return .Invalid_Argument }
	internal_error_if_immutable(res) or_return

	/*
		Set the integer to the default of zero.
	*/
	internal_zero(res) or_return

	if radix <= _MAX_NON_FINITE_RADIX {
		special := 0
		switch {
		case len(input) >= 4 && input[:4] == "+Inf":
			internal_inf(res) or_return
			special = 4
		case len(input) >= 4 && input[:4] == "-Inf":
			internal_minus_inf(res) or_return
			special = 4
		case len(input) >= 3 && input[:3] == "NaN":
			internal_nan(res) or_return
			special = 3
		}
		if special > 0 {
			if n != nil { n^ = special }
			input = input[special:]
			if len(input) == 0 { return nil }
			if _is_whitespace_or_nul(input) { return .Trailing_Whitespace }
			return .Invalid_Character
		}
	}

	/*
		If the leading digit is a minus set the sign to negative.
	*/
	sign := Sign.Zero_or_Positive
	if len(input) > 0 && input[0] == '-' {
		input = input[1:]
		sign = .Negative
	}

	/*
		There has to be at least one digit.
	*/
	if len(input) == 0 {
		return .Empty_Input
	}
	digits_start := len(input)

	/*
		Process each digit of the string.
	*/

	if platform_int_is_power_of_two(int(radix)) {

		/*
			For power-of-two bases, pack several digits into one native limb at once.
			This reduces the number of bigint multiply/add steps by a factor of roughly
			_DIGIT_BITS / log2(radix), while also preallocating the accumulator to avoid
			excessive reallocations on large hex inputs.
		*/

		bits_per_digit := 0
		power_of_two := DIGIT(radix)
		for power_of_two > 1 {
			power_of_two >>= 1
			bits_per_digit += 1
		}
		
		/*
			Ex.: Radix 16
			-> 4 bits per digit
			-> can fit 15 hex digits from the input into one 63-bit DIGIT
		*/
		digits_per_chunk := _DIGIT_BITS / bits_per_digit
		assert(digits_per_chunk > 1, "Optimized path was expecting to fit multiple input digits into one DIGIT. Did the allowed radix range change (2..64)?")

		/*
			Preallocate everything at once.
			The number of DIGIT elements is: ceildiv(len(input), chunk_digits)
		*/
		internal_grow(res, max(1, (len(input) + digits_per_chunk - 1) / digits_per_chunk)) or_return

		chunk_value: DIGIT
		chunk_count := 0  // Number of input digits we have already processed in the current chunk_value DIGIT
		for len(input) > 0 {
			ch := rune(input[0])
			if radix <= 36 && ch >= 'a' && ch <= 'z' {
				ch -= 32
			}

			pos := ch - '+'
			if RADIX_TABLE_REVERSE_SIZE <= u32(pos) {
				break
			}
			y := RADIX_TABLE_REVERSE[pos]
			if y >= u8(radix) {
				break
			}

			chunk_value = (chunk_value << uint(bits_per_digit)) | DIGIT(y)
			chunk_count += 1
			input = input[1:]

			if chunk_count == digits_per_chunk {
				// Submit chunk.
				// NOTE(bplu4t2f): Maybe this could be optimized further. For any given input digit,
				//                 we can predict exactly where it will go in the output, eliminating
				//                 the need for shl + add.
				if res.used == 0 {
					internal_set(res, chunk_value) or_return
				} else {
					internal_shl(res, res, bits_per_digit * chunk_count) or_return
					internal_add(res, res, chunk_value) or_return
				}
				chunk_value = 0
				chunk_count = 0
			}
		}

		/*
			Submit the last, partial chunk. The loop can also stop early, at the first character that
			isn't a digit in the radix.
		*/
		if chunk_count > 0 {
			if res.used == 0 {
				internal_set(res, chunk_value) or_return
			} else {
				internal_shl(res, res, bits_per_digit * chunk_count) or_return
				internal_add(res, res, chunk_value) or_return
			}
		}

	} else {

		/*
			Path for non-power-of-two bases.

			Like above, collect as many input digits as fit into one DIGIT and fold them into the
			result with one multiply and one add, instead of one of each per input digit.
			For radix 10 that is 18 digits per chunk.
		*/

		digits_per_chunk := 0
		chunk_limit      := DIGIT(1)
		for chunk_limit < (DIGIT(1) << _DIGIT_BITS) / DIGIT(radix) {
			chunk_limit      *= DIGIT(radix)
			digits_per_chunk += 1
		}

		/*
			Preallocate for ceil(log2(radix)) bits per input digit, which is a slight overestimate.
		*/
		bits_per_digit := 1
		for (1 << uint(bits_per_digit)) < int(radix) {
			bits_per_digit += 1
		}
		internal_grow(res, max(1, (len(input) * bits_per_digit + _DIGIT_BITS - 1) / _DIGIT_BITS + 1)) or_return

		chunk_value := DIGIT(0)
		chunk_scale := DIGIT(1) // radix^chunk_count
		chunk_count := 0

		for len(input) > 0 {
			/*
				if the radix <= 36 the conversion is case insensitive
				this allows numbers like 1AB and 1ab to represent the same value
				[e.g. in hex]
			*/

			ch := rune(input[0])
			if radix <= 36 && ch >= 'a' && ch <= 'z' {
				ch -= 32 // 'a' - 'A'
			}

			pos := ch - '+'
			if RADIX_TABLE_REVERSE_SIZE <= u32(pos) {
				break
			}
			y := RADIX_TABLE_REVERSE[pos]
			/*
				if the char was found in the map
				and is less than the given radix add it
				to the number, otherwise exit the loop.
			*/
			if y >= u8(radix) {
				break
			}

			chunk_value  = chunk_value * DIGIT(radix) + DIGIT(y)
			chunk_scale *= DIGIT(radix)
			chunk_count += 1
			input = input[1:]

			if chunk_count == digits_per_chunk {
				internal_mul(res, res, chunk_scale) or_return
				internal_add(res, res, chunk_value) or_return
				chunk_value = 0
				chunk_scale = 1
				chunk_count = 0
			}
		}

		/*
			Submit the last, partial chunk.
		*/
		if chunk_count > 0 {
			internal_mul(res, res, chunk_scale) or_return
			internal_add(res, res, chunk_value) or_return
		}
	}

	/*
		`input` now starts at the first character that isn't a digit in the radix, if there is one.
		Like `strconv`, `n` counts a leading '-' even when no digit follows it.
	*/
	if n != nil {
		n^ = input_len - len(input)
	}

	/*
		Without digits, whitespace alone is an empty input, but a '-' followed by whitespace is a
		number that was cut short.
	*/
	if len(input) == digits_start {
		if sign == .Zero_or_Positive && _is_whitespace_or_nul(input) {
			return .Empty_Input
		}
		return .Invalid_Character
	}

	/*
		Set the sign only if res != 0.
	*/
	if res.used > 0 {
		res.sign = sign
	}
	internal_clamp(res) or_return

	if len(input) == 0 {
		return nil
	}
	if _is_whitespace_or_nul(input) {
		return .Trailing_Whitespace
	}
	return .Invalid_Character
}

/*
	Whether `s` only has the ASCII characters `strings.is_space` accepts, and NUL.
*/
@(private)
_is_whitespace_or_nul :: proc "contextless" (s: string) -> bool {
	for i in 0..<len(s) {
		switch s[i] {
		case ' ', '\t', '\n', '\v', '\f', '\r', 0:
		case:
			return false
		}
	}
	return true
}


atoi :: proc { int_atoi, }
string_to_int :: int_atoi

/*
	We size for `string` by default.
*/
radix_size :: proc(a: ^Int, radix: i8, zero_terminate := false, allocator := context.allocator) -> (size: int, err: Error) {
	a := a
	assert_if_nil(a)
	context.allocator = allocator

	if radix < 2 || radix > 64                     { return -1, .Invalid_Argument }
	a = _zero_if_uninitialized(a)

	if .NaN in a.flags || .Inf in a.flags {
		if radix > _MAX_NON_FINITE_RADIX { return -1, .Invalid_Argument }
		size = len(_non_finite_string(a))
		return size + (1 if zero_terminate else 0), nil
	}

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
		internal_set(k, _log_bases[radix]) or_return

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
		W: _WORD
		got := 0
		for got < bits_to_get {
			n := min(bits_to_get - got, _WORD_BITS)
			part := internal_int_bitfield_extract(a, bit_offset + got, n) or_return
			W |= part << uint(got)
			got += n
		}
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
		return internal_zero(a)
	}

	bit_count   := type_bits * len(buf)
	digit_count := (bit_count / _DIGIT_BITS) + min(1, bit_count % _DIGIT_BITS)

	/*
		Pre-size output Int.
	*/
	internal_zero(a) or_return
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
@(rodata)
_log_bases := [65]u32{
	0,         0,          0x20000001, 0x14309399, 0x10000001,
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
	Characters used in radix conversions: digit `n` is written as `RADIX_TABLE[n]`, i.e. 0-9, A-Z, a-z, `+` and `/` for 0..=63.
	That is not RFC 4648 base64, which starts with A-Z. `atoi` also accepts a-z as A-Z in radix 2..=36.
*/
@(rodata)
RADIX_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
@(rodata)
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
	Stores a bignum as an ASCII string in a given radix (2..64).
	Returns `.Buffer_Overflow` if the buffer is too small.
*/

_itoa_raw_full :: proc(a: ^Int, radix: i8, buffer: []u8, zero_terminate := false, allocator := context.allocator) -> (written: int, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	// Calculate largest radix^n that fits within _DIGIT_BITS
	divisor     := _WORD(ITOA_DIVISOR)
	digit_count := ITOA_COUNT
	_radix      := DIGIT(radix)

	if radix != 10 {
		i := _WORD(1)
		digit_count = -1
		for i < _WORD(1 << _DIGIT_BITS) {
			divisor = _WORD(i)
			i *= _WORD(radix)
			digit_count += 1
		}
	}

	temp := &Int{}
	internal_copy(temp, a) or_return
	defer internal_destroy(temp)

	available := len(buffer)
	if zero_terminate {
		if available == 0 {
			return 0, .Buffer_Overflow
		}
		available -= 1
		buffer[available] = 0
	}

	if a.sign == .Negative {
		temp.sign = .Zero_or_Positive
	}

	reciprocal := _private_digit_reciprocal(DIGIT(divisor))

	remainder: DIGIT
	for {
		remainder = _private_divmod_digits(raw_data(temp.digit), raw_data(temp.digit), temp.used, reciprocal)
		internal_clamp(temp)

		count := digit_count
		for count > 0 && (temp.used > 0 || remainder > 0) {
			if available == 0 {
				return 0, .Buffer_Overflow
			}
			available -= 1
			buffer[available] = RADIX_TABLE[remainder % _radix]
			remainder /= _radix
			count -= 1
		}

		if temp.used == 0 {
			break
		}
	}

	if a.sign == .Negative {
		if available == 0 {
			return 0, .Buffer_Overflow
		}
		available -= 1
		buffer[available] = '-'
	}

	/*
		If we overestimated the size, we need to move the buffer left.
	*/
	written = len(buffer) - available
	if written < len(buffer) {
		diff := len(buffer) - written
		intrinsics.mem_copy(&buffer[0], &buffer[diff], written)
	}
	return written, nil
}

// Old internal digit extraction procedure.
// We're keeping this around as ground truth for the tests.
_itoa_raw_old :: proc(a: ^Int, radix: i8, buffer: []u8, zero_terminate := false, allocator := context.allocator) -> (written: int, err: Error) {
	assert_if_nil(a)
	context.allocator = allocator

	temp := &Int{}
	internal_copy(temp, a) or_return
	defer internal_destroy(temp)

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

	/*
		If we overestimated the size, we need to move the buffer left.
	*/
	written = len(buffer) - available
	if written < len(buffer) {
		diff := len(buffer) - written
		intrinsics.mem_copy(&buffer[0], &buffer[diff], written)
	}
	return written, nil
}