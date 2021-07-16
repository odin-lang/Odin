package bigint

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	A BigInt implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
*/

import "core:intrinsics"

/*
	Tunables
*/
_LOW_MEMORY          :: #config(BIGINT_SMALL_MEMORY, false);
when _LOW_MEMORY {
	_DEFAULT_DIGIT_COUNT :: 8;
} else {
	_DEFAULT_DIGIT_COUNT :: 32;
}

_MUL_KARATSUBA_CUTOFF :: #config(MUL_KARATSUBA_CUTOFF, _DEFAULT_MUL_KARATSUBA_CUTOFF);
_SQR_KARATSUBA_CUTOFF :: #config(SQR_KARATSUBA_CUTOFF, _DEFAULT_SQR_KARATSUBA_CUTOFF);
_MUL_TOOM_CUTOFF      :: #config(MUL_TOOM_CUTOFF,      _DEFAULT_MUL_TOOM_CUTOFF);
_SQR_TOOM_CUTOFF      :: #config(SQR_TOOM_CUTOFF,      _DEFAULT_SQR_TOOM_CUTOFF);

/*
	These defaults were tuned on an AMD A8-6600K (64-bit) using libTomMath's `make tune`.
	TODO(Jeroen): Port this tuning algorithm and tune them for more modern processors.
*/
_DEFAULT_MUL_KARATSUBA_CUTOFF ::  80;
_DEFAULT_SQR_KARATSUBA_CUTOFF :: 120;
_DEFAULT_MUL_TOOM_CUTOFF      :: 350;
_DEFAULT_SQR_TOOM_CUTOFF      :: 400;


Sign :: enum u8 {
	Zero_or_Positive = 0,
	Negative         = 1,
};

Int :: struct {
	used:      int,
	allocated: int,
	sign:      Sign,
	digit:     [dynamic]DIGIT,
};

Comparison_Flag :: enum i8 {
	Less_Than     = -1,
	Equal         =  0,
	Greater_Than  =  1,

	/* One of the numbers was uninitialized */
	Uninitialized = -127,
};

Error :: enum i8 {
	OK                     =  0,
	Unknown_Error          = -1,
	Out_of_Memory          = -2,
	Invalid_Input          = -3,
	Max_Iterations_Reached = -4,
	Buffer_Overflow        = -5,
	Integer_Overflow       = -6,

	Unimplemented          = -127,
};

Primality_Flag :: enum u8 {
	Blum_Blum_Shub = 0,	/* BBS style prime */
	Safe           = 1,	/* Safe prime (p-1)/2 == prime */
	Second_MSB_On  = 3, /* force 2nd MSB to 1 */
};
Primality_Flags :: bit_set[Primality_Flag; u8];

/*
	How do we store the Ints?

	Minimum number of available digits in `Int`, `_DEFAULT_DIGIT_COUNT` >= `_MIN_DIGIT_COUNT`
	- Must be at least 3 for `_div_school`.
	- Must be large enough such that `init_integer` can store `u128` in the `Int` without growing.
 */

_MIN_DIGIT_COUNT :: max(3, ((size_of(u128) + _DIGIT_BITS) - 1) / _DIGIT_BITS);
#assert(_DEFAULT_DIGIT_COUNT >= _MIN_DIGIT_COUNT);

/*
	Maximum number of digits.
	- Must be small enough such that `_bit_count` does not overflow.
 	- Must be small enough such that `_radix_size` for base 2 does not overflow.
	`_radix_size` needs two additional bytes for zero termination and sign.
*/
_MAX_DIGIT_COUNT :: (max(int) - 2) / _DIGIT_BITS;

when size_of(rawptr) == 8 {
	/*
		We can use u128 as an intermediary.
	*/
	DIGIT        :: distinct(u64);
	_WORD        :: distinct(u128);
} else {
	DIGIT        :: distinct(u32);
	_WORD        :: distinct(u64);
}
#assert(size_of(_WORD) == 2 * size_of(DIGIT));

_DIGIT_TYPE_BITS :: 8 * size_of(DIGIT);
_WORD_TYPE_BITS  :: 8 * size_of(_WORD);

_DIGIT_BITS      :: _DIGIT_TYPE_BITS - 4;

_MASK            :: (DIGIT(1) << DIGIT(_DIGIT_BITS)) - DIGIT(1);
_DIGIT_MAX       :: _MASK;
_MAX_COMBA       :: 1 <<  (_WORD_TYPE_BITS - (2 * _DIGIT_BITS))     ;
_WARRAY          :: 1 << ((_WORD_TYPE_BITS - (2 * _DIGIT_BITS)) + 1);

Order :: enum i8 {
	LSB_First = -1,
	MSB_First =  1,
};

Endianness :: enum i8 {
   Little   = -1,
   Platform =  0,
   Big      =  1,
};