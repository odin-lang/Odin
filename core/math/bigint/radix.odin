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

itoa :: proc(a: ^Int, radix: int, allocator := context.allocator) -> (res: string, err: Error) {
	assert_initialized(a);

	if radix < 2 || radix > 64 {
		return strings.clone("", allocator), .Invalid_Input;
	}

	/*
		Fast path for radixes that are a power of two.
	*/
	if is_power_of_two(radix) {

	}




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

int_to_string :: itoa;

/*
	We size for `string`, not `cstring`.
*/
radix_size :: proc(a: ^Int, radix: int) -> (size: int, err: Error) {
	t := a;

	if radix < 2 || radix > 64 {
		return -1, .Invalid_Input;
	}

 	if is_zero(a) {
 		return 1, .OK;
 	}

 	t.sign = .Zero_or_Positive;
 	log: int;

 	log, err = log_n(t, radix);
 	if err != .OK {
 		return log, err;
 	}

 	/*
		log truncates to zero, so we need to add one more, and one for `-` if negative.
 	*/
 	if is_neg(a) {
 		return log + 2, .OK;
 	} else {
 		return log + 1, .OK;
 	}
}