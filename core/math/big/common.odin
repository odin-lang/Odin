/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.
*/


package math_big

import "base:intrinsics"

/*
	TODO: Make the tunables runtime adjustable where practical.

	This allows to benchmark and/or setting optimized values for a certain CPU without recompiling.
*/

/*
	==========================    TUNABLES     ==========================

	`initialize_constants` returns `#config(MUL_KARATSUBA_CUTOFF, _DEFAULT_MUL_KARATSUBA_CUTOFF)`
	and we initialize this cutoff that way so that the procedure is used and called,
	because it handles initializing the constants ONE, ZERO, MINUS_ONE, NAN and INF.

	`initialize_constants` also replaces the other `_DEFAULT_*` cutoffs with custom compile-time values if so `#config`ured.

*/

/*
	There is a bug with DLL globals. They don't get set.
	To allow tests to run we add `-define:MATH_BIG_EXE=false` to hardcode the cutoffs for now.
*/
when #config(MATH_BIG_EXE, true) {
	MUL_KARATSUBA_CUTOFF := initialize_constants()
	SQR_KARATSUBA_CUTOFF := _DEFAULT_SQR_KARATSUBA_CUTOFF
	MUL_TOOM_CUTOFF      := _DEFAULT_MUL_TOOM_CUTOFF
	SQR_TOOM_CUTOFF      := _DEFAULT_SQR_TOOM_CUTOFF
} else {
	MUL_KARATSUBA_CUTOFF := _DEFAULT_MUL_KARATSUBA_CUTOFF
	SQR_KARATSUBA_CUTOFF := _DEFAULT_SQR_KARATSUBA_CUTOFF
	MUL_TOOM_CUTOFF      := _DEFAULT_MUL_TOOM_CUTOFF
	SQR_TOOM_CUTOFF      := _DEFAULT_SQR_TOOM_CUTOFF	
}

/*
	These defaults were tuned on an AMD A8-6600K (64-bit) using libTomMath's `make tune`.

	TODO(Jeroen): Port this tuning algorithm and tune them for more modern processors.

	It would also be cool if we collected some data across various processor families.
	This would let uss set reasonable defaults at runtime as this library initializes
	itself by using `cpuid` or the ARM equivalent.

	IMPORTANT: The 32_BIT path has largely gone untested. It needs to be tested and
	debugged where necessary.
*/

_DEFAULT_MUL_KARATSUBA_CUTOFF :: #config(MATH_BIG_MUL_KARATSUBA_CUTOFF,  80)
_DEFAULT_SQR_KARATSUBA_CUTOFF :: #config(MATH_BIG_SQR_KARATSUBA_CUTOFF, 120)
_DEFAULT_MUL_TOOM_CUTOFF      :: #config(MATH_BIG_MUL_TOOM_CUTOFF,      350)
_DEFAULT_SQR_TOOM_CUTOFF      :: #config(MATH_BIG_SQR_TOOM_CUTOFF,      400)


MAX_ITERATIONS_ROOT_N := 500

/*
	Largest `N` for which we'll compute `N!`
*/
FACTORIAL_MAX_N       := 1_000_000

/*
	Cutoff to switch to int_factorial_binary_split, and its max recursion level.
*/
FACTORIAL_BINARY_SPLIT_CUTOFF         := 6100
FACTORIAL_BINARY_SPLIT_MAX_RECURSIONS := 100

/*
	`internal_int_is_prime` switchables.

	Use Frobenius-Underwood for primality testing, or use Lucas-Selfridge (default).
*/
MATH_BIG_USE_LUCAS_SELFRIDGE_TEST :: #config(MATH_BIG_USE_LUCAS_SELFRIDGE_TEST, false)
MATH_BIG_USE_FROBENIUS_TEST       :: !MATH_BIG_USE_LUCAS_SELFRIDGE_TEST

/*
	Runtime tunable to use Miller-Rabin primality testing only and skip the above.
*/
USE_MILLER_RABIN_ONLY       := false

/*
	How many times we'll call `internal_int_random` during random prime generation before we bail out.
	Set to 0 or less to try indefinitely.	
*/
MAX_ITERATIONS_RANDOM_PRIME  := 1_000_000

/*
	How many iterations we used for the last random prime.
*/
@thread_local RANDOM_PRIME_ITERATIONS_USED: int

/*
	We don't allow these to be switched at runtime for two reasons:

	1) 32-bit and 64-bit versions of procedures use different types for their storage,
		so we'd have to double the number of procedures, and they couldn't interact.

	2) Optimizations thanks to precomputed masks wouldn't work.
*/
MATH_BIG_FORCE_64_BIT   :: #config(MATH_BIG_FORCE_64_BIT, false)
MATH_BIG_FORCE_32_BIT   :: #config(MATH_BIG_FORCE_32_BIT, false)
when (MATH_BIG_FORCE_32_BIT && MATH_BIG_FORCE_64_BIT) { #panic("Cannot force 32-bit and 64-bit big backend simultaneously.") }

/*
	Trade a smaller memory footprint for more processing overhead?
*/
_LOW_MEMORY             :: #config(MATH_BIG_SMALL_MEMORY, false)
when _LOW_MEMORY {
	_DEFAULT_DIGIT_COUNT ::   8
	_TAB_SIZE            ::  32
	_MAX_WIN_SIZE        ::   5
} else {
	_DEFAULT_DIGIT_COUNT ::  32
	_TAB_SIZE            :: 256
	_MAX_WIN_SIZE        ::   0
}

/*
	=======================    END OF TUNABLES     =======================
*/

Sign :: enum u8 {
	Zero_or_Positive = 0,
	Negative         = 1,
}

Int :: struct {
	used:  int,
	digit: [dynamic]DIGIT,
	sign:  Sign,
	flags: Flags,
}

Flag :: enum u8 {
	NaN,
	Inf,
	Immutable,
}

Flags :: bit_set[Flag; u8]

/*
	Errors are a strict superset of runtime.Allocation_Error.
*/
Error :: enum int {
	Okay                    = 0,
	Out_Of_Memory           = 1,
	Invalid_Pointer         = 2,
	Invalid_Argument        = 3,

	Assignment_To_Immutable = 10,
	Max_Iterations_Reached  = 11,
	Buffer_Overflow         = 12,
	Integer_Overflow        = 13,
	Integer_Underflow       = 14,

	Division_by_Zero        = 30,
	Math_Domain_Error       = 31,

	Cannot_Open_File        = 50,
	Cannot_Read_File        = 51,
	Cannot_Write_File       = 52,

	Unimplemented           = 127,
}

Error_String :: #sparse[Error]string{
	.Okay                    = "Okay",
	.Out_Of_Memory           = "Out of memory",
	.Invalid_Pointer         = "Invalid pointer",
	.Invalid_Argument        = "Invalid argument",

	.Assignment_To_Immutable = "Assignment to immutable",
	.Max_Iterations_Reached  = "Max iterations reached",
	.Buffer_Overflow         = "Buffer overflow",
	.Integer_Overflow        = "Integer overflow",
	.Integer_Underflow       = "Integer underflow",

	.Division_by_Zero        = "Division by zero",
	.Math_Domain_Error       = "Math domain error",

	.Cannot_Open_File        = "Cannot_Open_File",
	.Cannot_Read_File        = "Cannot_Read_File",
	.Cannot_Write_File       = "Cannot_Write_File",

	.Unimplemented           = "Unimplemented",
}

Primality_Flag :: enum u8 {
	Blum_Blum_Shub = 0,  // Make prime congruent to 3 mod 4
	Safe           = 1,  // Make sure (p-1)/2 is prime as well (implies .Blum_Blum_Shub)
	Second_MSB_On  = 3,  // Make the 2nd highest bit one
}
Primality_Flags :: bit_set[Primality_Flag; u8]

/*
	How do we store the Ints?

	Minimum number of available digits in `Int`, `_DEFAULT_DIGIT_COUNT` >= `_MIN_DIGIT_COUNT`
	- Must be at least 3 for `_div_school`.
	- Must be large enough such that `init_integer` can store `u128` in the `Int` without growing.
 */

_MIN_DIGIT_COUNT :: max(3, ((size_of(u128) + _DIGIT_BITS) - 1) / _DIGIT_BITS)
#assert(_DEFAULT_DIGIT_COUNT >= _MIN_DIGIT_COUNT)

/*
	Maximum number of digits.
	- Must be small enough such that `_bit_count` does not overflow.
	- Must be small enough such that `_radix_size` for base 2 does not overflow.
	`_radix_size` needs two additional bytes for zero termination and sign.
*/
_MAX_BIT_COUNT   :: (max(int) - 2)
_MAX_DIGIT_COUNT :: _MAX_BIT_COUNT / _DIGIT_BITS

when MATH_BIG_FORCE_64_BIT || (!MATH_BIG_FORCE_32_BIT && size_of(rawptr) == 8) {
	/*
		We can use u128 as an intermediary.
	*/
	DIGIT        :: distinct u64
	_WORD        :: distinct u128
} else {
	DIGIT        :: distinct u32
	_WORD        :: distinct u64
}
#assert(size_of(_WORD) == 2 * size_of(DIGIT))

_DIGIT_TYPE_BITS :: 8 * size_of(DIGIT)
_WORD_TYPE_BITS  :: 8 * size_of(_WORD)

_DIGIT_NAILS     :: 4
_DIGIT_BITS      :: _DIGIT_TYPE_BITS - _DIGIT_NAILS
_WORD_BITS       :: 2 * _DIGIT_BITS

_MASK            :: (DIGIT(1) << DIGIT(_DIGIT_BITS)) - DIGIT(1)
_DIGIT_MAX       :: _MASK
_MAX_COMBA       :: 1 <<  (_WORD_TYPE_BITS - (2 * _DIGIT_BITS))     
_WARRAY          :: 1 << ((_WORD_TYPE_BITS - (2 * _DIGIT_BITS)) + 1)

Order :: enum i8 {
	LSB_First = -1,
	MSB_First =  1,
}

Endianness :: enum i8 {
	Little   = -1,
	Platform =  0,
	Big      =  1,
}