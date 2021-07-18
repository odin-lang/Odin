package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains radix conversions, `string_to_int` (atoi) and `int_to_string` (itoa).
*/

import "core:mem"
import "core:intrinsics"
import "core:fmt"
import "core:strings"
import "core:slice"

/*
	This version of `itoa` allocates one behalf of the caller. The caller must free the string.
*/
itoa_string :: proc(a: ^Int, radix := i8(-1), zero_terminate := false, allocator := context.allocator) -> (res: string, err: Error) {
	assert_initialized(a);
	/*
		Radix defaults to 10.
	*/
	radix := radix if radix > 0 else 10;

	/*
		TODO: If we want to write a prefix for some of the radixes, we can oversize the buffer.
		Then after the digits are written and the string is reversed
	*/

	/*
		Calculate the size of the buffer we need.
	*/
	size: int;
	size, err = radix_size(a, radix, zero_terminate);

	/*
		Exit if calculating the size returned an error.
	*/
	if err != .OK {
		if zero_terminate {
			return string(cstring("")), err;
		}
		return "", err;
	}

	/*
		Allocate the buffer we need.
	*/
	buffer := make([]u8, size);

	/*
		Write the digits out into the buffer.
	*/
	written: int;
	written, err = itoa_raw(a, radix, buffer, size, zero_terminate);

	/*
		For now, delete the buffer and fall back to the below on failure.
	*/
	if err == .OK {
		return string(buffer[:written]), .OK;
	}
	delete(buffer);

	fallback :: proc(a: ^Int, print_raw := false) -> string {
		   if print_raw {
				   return fmt.tprintf("%v", a);
		   }
		   sign := "-" if a.sign == .Negative else "";
		   if a.used <= 2 {
				   v := _WORD(a.digit[1]) << _DIGIT_BITS + _WORD(a.digit[0]);
				   return fmt.tprintf("%v%v", sign, v);
		   } else {
				   return fmt.tprintf("[%2d/%2d] %v%v", a.used, a.allocated, sign, a.digit[:a.used]);
		   }
	}
	return strings.clone(fallback(a), allocator), .Unimplemented;
}

/*
	This version of `itoa` allocates one behalf of the caller. The caller must free the string.
*/
itoa_cstring :: proc(a: ^Int, radix := i8(-1), allocator := context.allocator) -> (res: cstring, err: Error) {
	assert_initialized(a);
	/*
		Radix defaults to 10.
	*/
	radix := radix if radix > 0 else 10;

	s: string;
	s, err = itoa_string(a, radix, true, allocator);
	return cstring(raw_data(s)), err;
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
itoa_raw :: proc(a: ^Int, radix: i8, buffer: []u8, size := int(-1), zero_terminate := false) -> (written: int, err: Error) {
	assert_initialized(a); size := size;
	/*
		Radix defaults to 10.
	*/
	radix := radix if radix > 0 else 10;
	if radix < 2 || radix > 64 {
		return 0, .Invalid_Input;
	}

	/*
		We weren't given a size. Let's compute it.
	*/
	if size == -1 {
		size, err = radix_size(a, radix, zero_terminate);
	}

	/*
		Early exit if the buffer we were given is too small.
	*/
	available := len(buffer);
	if available < size {
		return 0, .Buffer_Overflow;
	}
	/*
		Fast path for when `Int` == 0 or the entire `Int` fits in a single radix digit.
	*/
	if is_zero(a) || (a.used == 1 && a.digit[0] < DIGIT(radix)) {
		needed := 2 if is_neg(a) else 1;
		needed += 1 if zero_terminate else 0;
		if available < needed {
			return 0, .Buffer_Overflow;
		}

		if zero_terminate {
			available -= 1;
			buffer[available] = 0;
			written   += 1;
		}

		available -= 1;
		buffer[available] = RADIX_TABLE[a.digit[0]];
		written   += 1;

		if is_neg(a) {
			available -= 1;
			buffer[available] = '-';
			written   += 1;
		}

		return written, .OK;
	}

	/*
		Fast path for when `Int` fits within a `_WORD`.
	*/
	if a.used == 1 || a.used == 2 {
		if zero_terminate {
			if available == 0 {
				return written, .Buffer_Overflow;
			}
			available -= 1;
			buffer[available] = 0;
			written   += 1;
		}

		val := _WORD(a.digit[1]) << _DIGIT_BITS + _WORD(a.digit[0]);
		for val > 0 {
			if available == 0 {
				return written, .Buffer_Overflow;
			}

			q := val / _WORD(radix);
			available -= 1;
			buffer[available] = RADIX_TABLE[val - (q * _WORD(radix))];
			written   += 1;

			val = q;
		}
		if is_neg(a) {
			if available == 0 {
				return written, .Buffer_Overflow;
			}
			available -= 1;
			buffer[available] = '-';
			written   += 1;
		}
		return written, .OK;
	}

	/*
		Fast path for radixes that are a power of two.
	*/
	if is_power_of_two(int(radix)) {

		// return len(buffer), .OK;
	}

	return -1, .Unimplemented;
}

itoa :: proc{itoa_string, itoa_raw};
int_to_string  :: itoa;
int_to_cstring :: itoa_cstring;

/*
	We size for `string`, not `cstring`.
*/
radix_size :: proc(a: ^Int, radix: i8, zero_terminate := false) -> (size: int, err: Error) {
	if radix < 2 || radix > 64 {
		return -1, .Invalid_Input;
	}

 	if is_zero(a) {
 		return 1, .OK;
 	}

 	/*
		Calculate `log` on a temporary "copy" with its sign set to positive.
 	*/
	t := &Int{
		used      = a.used,
		allocated = a.allocated,
		sign      = .Zero_or_Positive,
		digit     = a.digit,
	};

 	size, err = log_n(t, DIGIT(radix));
 	if err != .OK {
 		return;
 	}

 	/*
		log truncates to zero, so we need to add one more, and one for `-` if negative.
 	*/
 	size += 2 if is_neg(a) else 1;
 	size += 1 if zero_terminate else 0;
 	return size, .OK;
}

/*
	Characters used in radix conversions.
*/
RADIX_TABLE := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/";
RADIX_TABLE_REVERSE := [80]u8{
   0x3e, 0xff, 0xff, 0xff, 0x3f, 0x00, 0x01, 0x02, 0x03, 0x04, /* +,-./01234 */
   0x05, 0x06, 0x07, 0x08, 0x09, 0xff, 0xff, 0xff, 0xff, 0xff, /* 56789:;<=> */
   0xff, 0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, /* ?@ABCDEFGH */
   0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, /* IJKLMNOPQR */
   0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0xff, 0xff, /* STUVWXYZ[\ */
   0xff, 0xff, 0xff, 0xff, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, /* ]^_`abcdef */
   0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, /* ghijklmnop */
   0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, /* qrstuvwxyz */
};