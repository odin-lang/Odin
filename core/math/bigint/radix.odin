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
	if radix & 1 == 0 {


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


radix_size :: proc(a: ^Int, base: int) -> (size: int, err: Error) {
   // mp_err err;
   // mp_int a_;
   // int b;

   // /* make sure the radix is in range */
   // if ((radix < 2) || (radix > 64)) {
   //    return MP_VAL;
   // }

   // if (mp_iszero(a)) {
   //    *size = 2;
   //    return MP_OKAY;
   // }

   // a_ = *a;
   // a_.sign = MP_ZPOS;
   // if ((err = mp_log_n(&a_, radix, &b)) != MP_OKAY) {
   //    return err;
   // }

   // /* mp_ilogb truncates to zero, hence we need one extra put on top and one for `\0`. */
   // *size = (size_t)b + 2U + (mp_isneg(a) ? 1U : 0U);

   return size, .OK;
}