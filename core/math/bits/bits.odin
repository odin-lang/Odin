// Bit-level operations, including the ability to set or toggle individual bits in an integer.
package math_bits

import "base:intrinsics"

// The minimum value held by a `u8`. The same value as `min(u8)`, except untyped.
U8_MIN  :: 0
// The minimum value held by a `u16`. The same value as `min(u16)`, except untyped.
U16_MIN :: 0
// The minimum value held by a `u32`. The same value as `min(u32)`, except untyped.
U32_MIN :: 0
// The minimum value held by a `u64`. The same value as `min(u64)`, except untyped.
U64_MIN :: 0
// The minimum value held by a `uint`. The same value as `min(uint)`, except untyped.
UINT_MIN :: 0

// The maximum value held by a `u8`. The same value as `max(u8)`, except untyped.
U8_MAX  :: 1 <<  8 - 1
// The maximum value held by a `u16`. The same value as `max(u16)`, except untyped.
U16_MAX :: 1 << 16 - 1
// The maximum value held by a `u32`. The same value as `max(u32)`, except untyped.
U32_MAX :: 1 << 32 - 1
// The maximum value held by a `u64`. The same value as `max(u64)`, except untyped.
U64_MAX :: 1 << 64 - 1
// The maximum value held by a `uint`. The same value as `max(uint)`, except untyped.
UINT_MAX :: U64_MAX when size_of(uint) == 8 else U32_MAX

// The minimum value held by an `i8`. The same value as `min(i8)`, except untyped.
I8_MIN  :: - 1 << 7
// The minimum value held by an `i16`. The same value as `min(i16)`, except untyped.
I16_MIN :: - 1 << 15
// The minimum value held by an `i32`. The same value as `min(i32)`, except untyped.
I32_MIN :: - 1 << 31
// The minimum value held by an `i64`. The same value as `min(i64)`, except untyped.
I64_MIN :: - 1 << 63
// The minimum value held by an `int`. The same value as `min(int)`, except untyped.
INT_MIN :: I64_MIN when size_of(int) == 8 else I32_MIN

// The maximum value held by an `i8`. The same value as `max(i8)`, except untyped.
I8_MAX  :: 1 <<  7 - 1
// The maximum value held by an `i16`. The same value as `max(i16)`, except untyped.
I16_MAX :: 1 << 15 - 1
// The maximum value held by an `i32`. The same value as `max(i32)`, except untyped.
I32_MAX :: 1 << 31 - 1
// The maximum value held by an `i64`. The same value as `max(i64)`, except untyped.
I64_MAX :: 1 << 63 - 1
// The maximum value held by an `int`. The same value as `max(int)`, except untyped.
INT_MAX :: I64_MAX when size_of(int) == 8 else I32_MAX

count_ones           :: intrinsics.count_ones
count_zeros          :: intrinsics.count_zeros
trailing_zeros       :: intrinsics.count_trailing_zeros
leading_zeros        :: intrinsics.count_leading_zeros
count_trailing_zeros :: intrinsics.count_trailing_zeros
count_leading_zeros  :: intrinsics.count_leading_zeros
reverse_bits         :: intrinsics.reverse_bits
byte_swap            :: intrinsics.byte_swap
overflowing_add      :: intrinsics.overflow_add
overflowing_sub      :: intrinsics.overflow_sub
overflowing_mul      :: intrinsics.overflow_mul

/*
Returns the base-2 logarithm of an unsigned integer `x`

Another way to say this is that `log2(x)` is the position of its leading `1` bit.

NOTE: This is ill-defined for `0` as it has no `1` bits, and `log2(0)` will return `max(T)`.

Inputs:
- x: The unsigned integer

Returns:
- res: The base-2 logarithm of `x`

Example:

	import "core:fmt"
	import "core:math/bits"

	log2_example :: proc() {
		for i in u8(1)..=8 {
			fmt.printfln("{0} ({0:4b}): {1}", i, bits.log2(i))
		}
		assert(bits.log2(  u8(0)) == max(u8))
		assert(bits.log2( u16(0)) == max(u16))
		assert(bits.log2( u32(0)) == max(u32))
		assert(bits.log2( u64(0)) == max(u64))
		assert(bits.log2(u128(0)) == max(u128))
	}

Output:

	1 (0001): 0
	2 (0010): 1
	3 (0011): 1
	4 (0100): 2
	5 (0101): 2
	6 (0110): 2
	7 (0111): 2
	8 (1000): 3

*/
@(require_results)
log2 :: proc "contextless" (x: $T) -> (res: T) where intrinsics.type_is_integer(T), intrinsics.type_is_unsigned(T) {
	return (8*size_of(T)-1) - count_leading_zeros(x)
}

/*
Returns unsigned integer `x` rotated left by `k` bits

Can be thought of as a bit shift in which the leading bits are shifted back in on the bottom, rather than dropped.

This is equivalent to the [[ROL ; https://www.felixcloutier.com/x86/rcl:rcr:rol:ror]] CPU instruction.

Inputs:
- x: The unsigned integer
- k: Number of bits to rotate left by

Returns:
- res: `x` rotated left by `k` bits

Example:

	import "core:fmt"
	import "core:math/bits"

	rotate_left8_example :: proc() {
		x := u8(13)
		for k in 0..<8 {
			fmt.printfln("{0:8b}: {1}", bits.rotate_left8(x, k), k)
		}
	}

Output:

	00001101: 0
	00011010: 1
	00110100: 2
	01101000: 3
	11010000: 4
	10100001: 5
	01000011: 6
	10000110: 7

*/
@(require_results)
rotate_left8 :: proc "contextless" (x: u8,  k: int) -> u8 {
	n :: 8
	s := uint(k) & (n-1)
	return x << s | x >> (n-s)
}

/*
Returns unsigned integer `x` rotated left by `k` bits

Can be thought of as a bit shift in which the leading bits are shifted back in on the bottom, rather than dropped.

This is equivalent to the [[ROL ; https://www.felixcloutier.com/x86/rcl:rcr:rol:ror]] CPU instruction.

Inputs:
- x: The unsigned integer
- k: Number of bits to rotate left by

Returns:
- res: `x` rotated left by `k` bits
*/
@(require_results)
rotate_left16 :: proc "contextless" (x: u16, k: int) -> u16 {
	n :: 16
	s := uint(k) & (n-1)
	return x << s | x >>(n-s)
}

/*
Returns unsigned integer `x` rotated left by `k` bits

Can be thought of as a bit shift in which the leading bits are shifted back in on the bottom, rather than dropped.

This is equivalent to the [[ROL ; https://www.felixcloutier.com/x86/rcl:rcr:rol:ror]] CPU instruction.

Inputs:
- x: The unsigned integer
- k: Number of bits to rotate left by

Returns:
- res: `x` rotated left by `k` bits
*/
@(require_results)
rotate_left32 :: proc "contextless" (x: u32, k: int) -> u32 {
	n :: 32
	s := uint(k) & (n-1)
	return x << s | x >> (n-s)
}

/*
Returns unsigned integer `x` rotated left by `k` bits

Can be thought of as a bit shift in which the leading bits are shifted back in on the bottom, rather than dropped.

This is equivalent to the [[ROL ; https://www.felixcloutier.com/x86/rcl:rcr:rol:ror]] CPU instruction.

Inputs:
- x: The unsigned integer
- k: Number of bits to rotate left by

Returns:
- res: `x` rotated left by `k` bits
*/
@(require_results)
rotate_left64 :: proc "contextless" (x: u64, k: int) -> u64 {
	n :: 64
	s := uint(k) & (n-1)
	return x << s | x >> (n-s)
}

/*
Returns unsigned integer `x` rotated left by `k` bits

Can be thought of as a bit shift in which the leading bits are shifted back in on the bottom, rather than dropped.

This is equivalent to the [[ROL ; https://www.felixcloutier.com/x86/rcl:rcr:rol:ror]] CPU instruction.

Inputs:
- x: The unsigned integer
- k: Number of bits to rotate left by

Returns:
- res: `x` rotated left by `k` bits
*/
@(require_results)
rotate_left :: proc "contextless" (x: uint, k: int) -> uint {
	n :: 8*size_of(uint)
	s := uint(k) & (n-1)
	return x << s | x >> (n-s)
}

/*
Returns unsigned integer `i`

NOTE: A byte has no endianness, so `from_be_u8` exists to be complementary to `from_be_*`.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`
*/
@(require_results)
from_be_u8   :: proc "contextless" (i:   u8) ->   u8 { return i }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_be_u16  :: proc "contextless" (i:  u16) ->  u16 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_be_u32  :: proc "contextless" (i:  u32) ->  u32 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_be_u64  :: proc "contextless" (i:  u64) ->  u64 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_be_uint :: proc "contextless" (i: uint) -> uint { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`

NOTE: A byte has no endianness, so `from_le_u8` exists to be complementary to `from_le_*`.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`
*/
@(require_results)
from_le_u8   :: proc "contextless" (i:   u8) ->   u8 { return i }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_le_u16  :: proc "contextless" (i:  u16) ->  u16 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_le_u32  :: proc "contextless" (i:  u32) ->  u32 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_le_u64  :: proc "contextless" (i:  u64) ->  u64 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
from_le_uint :: proc "contextless" (i: uint) -> uint { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`

NOTE: A byte has no endianness, so `to_be_u8` exists to be complementary to `to_be_*`.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`
*/
@(require_results)
to_be_u8   :: proc "contextless" (i:   u8) ->   u8 { return i }
@(require_results)

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
to_be_u16  :: proc "contextless" (i:  u16) ->  u16 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_be_u32  :: proc "contextless" (i:  u32) ->  u32 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_be_u64  :: proc "contextless" (i:  u64) ->  u64 { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a little endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_be_uint :: proc "contextless" (i: uint) -> uint { when ODIN_ENDIAN == .Big { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`

NOTE: A byte has no endianness, so `to_le_u8` exists to be complementary to `to_le_*`.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`
*/
@(require_results)
to_le_u8   :: proc "contextless" (i:   u8) ->   u8 { return i }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_le_u16  :: proc "contextless" (i:  u16) ->  u16 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_le_u32  :: proc "contextless" (i:  u32) ->  u32 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_le_u64  :: proc "contextless" (i:  u64) ->  u64 { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

/*
Returns unsigned integer `i`, byte-swapped if we're on a big endian target.

Inputs:
- i: The unsigned integer

Returns:
- res: `i`, optionally byte-swapped
*/
@(require_results)
to_le_uint :: proc "contextless" (i: uint) -> uint { when ODIN_ENDIAN == .Little { return i } else { return byte_swap(i) } }

// returns the minimum number of bits required to represent x
@(require_results)
len_u8 :: proc "contextless" (x: u8) -> int {
	return int(len_u8_table[x])
}

// returns the minimum number of bits required to represent x
@(require_results)
len_u16 :: proc "contextless" (x: u16) -> (n: int) {
	x := x
	if x >= 1<<8 {
		x >>= 8
		n = 8
	}
	return n + int(len_u8_table[x])
}

// returns the minimum number of bits required to represent x
@(require_results)
len_u32 :: proc "contextless" (x: u32) -> (n: int) {
	x := x
	if x >= 1<<16 {
		x >>= 16
		n = 16
	}
	if x >= 1<<8 {
		x >>= 8
		n += 8
	}
	return n + int(len_u8_table[x])
}

// returns the minimum number of bits required to represent x
@(require_results)
len_u64 :: proc "contextless" (x: u64) -> (n: int) {
	x := x
	if x >= 1<<32 {
		x >>= 32
		n = 32
	}
	if x >= 1<<16 {
		x >>= 16
		n += 16
	}
	if x >= 1<<8 {
		x >>= 8
		n += 8
	}
	return n + int(len_u8_table[x])
}

// returns the minimum number of bits required to represent x
@(require_results)
len_uint :: proc "contextless" (x: uint) -> (n: int) {
	when size_of(uint) == size_of(u64) {
		return len_u64(u64(x))
	} else {
		return len_u32(u32(x))
	}
}

// returns the minimum number of bits required to represent x
len :: proc{len_u8, len_u16, len_u32, len_u64, len_uint}

/*
Add with carry

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- carry: Carry in

Returns:
- sum: The sum
- carry_out: Carry out
*/
@(require_results)
add_u32 :: proc "contextless" (x, y, carry: u32) -> (sum, carry_out: u32) {
	tmp_carry, tmp_carry2: bool
	sum, tmp_carry  = intrinsics.overflow_add(x, y)
	sum, tmp_carry2 = intrinsics.overflow_add(sum, carry)
	carry_out = u32(tmp_carry | tmp_carry2)
	return
}

/*
Add with carry

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- carry: Carry in

Returns:
- sum: The sum
- carry_out: Carry out
*/
@(require_results)
add_u64 :: proc "contextless" (x, y, carry: u64) -> (sum, carry_out: u64) {
	tmp_carry, tmp_carry2: bool
	sum, tmp_carry  = intrinsics.overflow_add(x, y)
	sum, tmp_carry2 = intrinsics.overflow_add(sum, carry)
	carry_out = u64(tmp_carry | tmp_carry2)
	return
}

/*
Add with carry

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- carry: Carry in

Returns:
- sum: The sum
- carry_out: Carry out
*/
@(require_results)
add_uint :: proc "contextless" (x, y, carry: uint) -> (sum, carry_out: uint) {
	when size_of(uint) == size_of(u64) {
		a, b := add_u64(u64(x), u64(y), u64(carry))
	} else {
		#assert(size_of(uint) == size_of(u32))
		a, b := add_u32(u32(x), u32(y), u32(carry))
	}
	return uint(a), uint(b)
}

/*
Add with carry

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- carry: Carry in

Returns:
- sum: The sum
- carry_out: Carry out
*/
add :: proc{add_u32, add_u64, add_uint}

/*
Subtract with borrow

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- borrow: Borrow in

Returns:
- diff: The difference
- borrow_out: Borrow out
*/
@(require_results)
sub_u32 :: proc "contextless" (x, y, borrow: u32) -> (diff, borrow_out: u32) {
	tmp_borrow, tmp_borrow2: bool
	diff, tmp_borrow  = intrinsics.overflow_sub(x, y)
	diff, tmp_borrow2 = intrinsics.overflow_sub(diff, borrow)
	borrow_out = u32(tmp_borrow | tmp_borrow2)
	return
}

/*
Subtract with borrow

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- borrow: Borrow in

Returns:
- diff: The difference
- borrow_out: Borrow out
*/
@(require_results)
sub_u64 :: proc "contextless" (x, y, borrow: u64) -> (diff, borrow_out: u64) {
	tmp_borrow, tmp_borrow2: bool
	diff, tmp_borrow = intrinsics.overflow_sub(x, y)
	diff, tmp_borrow2 = intrinsics.overflow_sub(diff, borrow)
	borrow_out = u64(tmp_borrow | tmp_borrow2)
	return
}

/*
Subtract with borrow

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- borrow: Borrow in

Returns:
- diff: The difference
- borrow_out: Borrow out
*/
@(require_results)
sub_uint :: proc "contextless" (x, y, borrow: uint) -> (diff, borrow_out: uint) {
	when size_of(uint) == size_of(u64) {
		a, b := sub_u64(u64(x), u64(y), u64(borrow))
	} else {
		#assert(size_of(uint) == size_of(u32))
		a, b := sub_u32(u32(x), u32(y), u32(borrow))
	}
	return uint(a), uint(b)
}

/*
Subtract with borrow

Inputs:
- x: The unsigned integer
- y: Another unsigned integer
- borrow: Borrow in

Returns:
- diff: The difference
- borrow_out: Borrow out
*/
sub :: proc{sub_u32, sub_u64, sub_uint}

/*
Multiply two words and return the result in high and low word

Inputs:
- x: The unsigned integer
- y: Another unsigned integer

Returns:
- hi: The result's high word
- lo: The result's low word
*/
@(require_results)
mul_u32 :: proc "contextless" (x, y: u32) -> (hi, lo: u32) {
	z := u64(x) * u64(y)
	hi, lo = u32(z>>32), u32(z)
	return
}

/*
Multiply two words and return the result in high and low word

Inputs:
- x: The unsigned integer
- y: Another unsigned integer

Returns:
- hi: The result's high word
- lo: The result's low word
*/
@(require_results)
mul_u64 :: proc "contextless" (x, y: u64) -> (hi, lo: u64) {
	prod_wide := u128(x) * u128(y)
	hi, lo = u64(prod_wide>>64), u64(prod_wide)
	return
}

/*
Multiply two words and return the result in high and low word

Inputs:
- x: The unsigned integer
- y: Another unsigned integer

Returns:
- hi: The result's high word
- lo: The result's low word
*/
@(require_results)
mul_uint :: proc "contextless" (x, y: uint) -> (hi, lo: uint) {
	when size_of(uint) == size_of(u32) {
		a, b := mul_u32(u32(x), u32(y))
	} else {
		#assert(size_of(uint) == size_of(u64))
		a, b := mul_u64(u64(x), u64(y))
	}
	return uint(a), uint(b)
}

/*
Multiply two words and return the result in high and low word

Inputs:
- x: The unsigned integer
- y: Another unsigned integer

Returns:
- hi: The result's high word
- lo: The result's low word
*/
mul :: proc{mul_u32, mul_u64, mul_uint}

/*
Divide a 64-bit unsigned integer (in two 32-bit words) by a 32-bit divisor

Inputs:
- hi: High word of 64-bit integer
- lo: Low word of 64-bit integer
- y: Divisor

Returns:
- quo: 32-bit quotient
- rem: 32-bit remainder
*/
@(require_results)
div_u32 :: proc "odin" (hi, lo, y: u32) -> (quo, rem: u32) {
	assert(y != 0 && y <= hi)
	z := u64(hi)<<32 | u64(lo)
	quo, rem = u32(z/u64(y)), u32(z%u64(y))
	return
}

/*
Divide a 128-bit unsigned integer (in two 64-bit words) by a 64-bit divisor

Inputs:
- hi: High word of 128-bit integer
- lo: Low word of 128-bit integer
- y: Divisor

Returns:
- quo: 64-bit quotient
- rem: 64-bit Remainder
*/
@(require_results)
div_u64 :: proc "odin" (hi, lo, y: u64) -> (quo, rem: u64) {
	y := y
	two32  :: 1 << 32
	mask32 :: two32 - 1
	if y == 0 {
		panic("divide error")
	}
	if y <= hi {
		panic("overflow error")
	}

	s := uint(count_leading_zeros(y))
	y <<= s

	yn1 := y >> 32
	yn0 := y & mask32
	un32 := hi<<s | lo>>(64-s)
	un10 := lo << s
	un1 := un10 >> 32
	un0 := un10 & mask32
	q1 := un32 / yn1
	rhat := un32 - q1*yn1

	for q1 >= two32 || q1*yn0 > two32*rhat+un1 {
		q1 -= 1
		rhat += yn1
		if rhat >= two32 {
			break
		}
	}

	un21 := un32*two32 + un1 - q1*y
	q0 := un21 / yn1
	rhat = un21 - q0*yn1

	for q0 >= two32 || q0*yn0 > two32*rhat+un0 {
		q0 -= 1
		rhat += yn1
		if rhat >= two32 {
			break
		}
	}

	return q1*two32 + q0, (un21*two32 + un0 - q0*y) >> s
}

/*
Divide an unsigned integer (in two words) by a divisor

Inputs:
- hi: High word of input
- lo: Low word of input
- y: Divisor

Returns:
- quo: Quotient
- rem: Remainder
*/
@(require_results)
div_uint :: proc "odin" (hi, lo, y: uint) -> (quo, rem: uint) {
	when size_of(uint) == size_of(u32) {
		a, b := div_u32(u32(hi), u32(lo), u32(y))
	} else {
		#assert(size_of(uint) == size_of(u64))
		a, b := div_u64(u64(hi), u64(lo), u64(y))
	}
	return uint(a), uint(b)
}

/*
Divide an unsigned integer (in two words) by a divisor

Inputs:
- hi: High word of input
- lo: Low word of input
- y: Divisor

Returns:
- quo: Quotient
- rem: Remainder
*/
div :: proc{div_u32, div_u64, div_uint}

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_u8   :: proc "contextless" (i:   u8) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_i8   :: proc "contextless" (i:   i8) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_u16  :: proc "contextless" (i:  u16) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_i16  :: proc "contextless" (i:  i16) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_u32  :: proc "contextless" (i:  u32) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_i32  :: proc "contextless" (i:  i32) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_u64  :: proc "contextless" (i:  u64) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_i64  :: proc "contextless" (i:  i64) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_uint :: proc "contextless" (i: uint) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
@(require_results)
is_power_of_two_int  :: proc "contextless" (i:  int) -> (is_pot: bool) { return i > 0 && (i & (i-1)) == 0 }

/*
Checks whether an unsigned number is a power of two

Inputs:
- i: Unsigned number

Returns:
- is_pot: `true` if `i` is a power of two, `false` otherwise
*/
is_power_of_two :: proc{
	is_power_of_two_u8,   is_power_of_two_i8,
	is_power_of_two_u16,  is_power_of_two_i16,
	is_power_of_two_u32,  is_power_of_two_i32,
	is_power_of_two_u64,  is_power_of_two_i64,
	is_power_of_two_uint, is_power_of_two_int,
}


@private
len_u8_table := [256]u8{
	0         = 0,
	1         = 1,
	2..<4     = 2,
	4..<8     = 3,
	8..<16    = 4,
	16..<32   = 5,
	32..<64   = 6,
	64..<128  = 7,
	128..<256 = 8,
}

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_u8   :: proc "contextless" (value:   u8, offset, bits: uint) ->   (res: u8) { return (value >> offset) &   u8(1<<bits - 1) }

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_u16  :: proc "contextless" (value:  u16, offset, bits: uint) ->  (res: u16) { return (value >> offset) &  u16(1<<bits - 1) }

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_u32  :: proc "contextless" (value:  u32, offset, bits: uint) ->  (res: u32) { return (value >> offset) &  u32(1<<bits - 1) }

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_u64  :: proc "contextless" (value:  u64, offset, bits: uint) ->  (res: u64) { return (value >> offset) &  u64(1<<bits - 1) }

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_u128 :: proc "contextless" (value: u128, offset, bits: uint) -> (res: u128) { return (value >> offset) & u128(1<<bits - 1) }

/*
Extracts bits from an unsigned integer

Inputs:
- value: Unsigned integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_uint :: proc "contextless" (value: uint, offset, bits: uint) -> (res: uint) { return (value >> offset) & uint(1<<bits - 1) }

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_i8 :: proc "contextless" (value: i8, offset, bits: uint) -> i8 {
	v := (u8(value) >> offset) & u8(1<<bits - 1)
	m := u8(1<<(bits-1))
	r := (v~m) - m
	return i8(r)
}

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_i16 :: proc "contextless" (value: i16, offset, bits: uint) -> i16 {
	v := (u16(value) >> offset) & u16(1<<bits - 1)
	m := u16(1<<(bits-1))
	r := (v~m) - m
	return i16(r)
}

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_i32 :: proc "contextless" (value: i32, offset, bits: uint) -> i32 {
	v := (u32(value) >> offset) & u32(1<<bits - 1)
	m := u32(1<<(bits-1))
	r := (v~m) - m
	return i32(r)
}

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_i64 :: proc "contextless" (value: i64, offset, bits: uint) -> i64 {
	v := (u64(value) >> offset) & u64(1<<bits - 1)
	m := u64(1<<(bits-1))
	r := (v~m) - m
	return i64(r)
}

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_i128 :: proc "contextless" (value: i128, offset, bits: uint) -> i128 {
	v := (u128(value) >> offset) & u128(1<<bits - 1)
	m := u128(1<<(bits-1))
	r := (v~m) - m
	return i128(r)
}

/*
Extracts bits from a signed integer

Inputs:
- value: Signed integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
@(require_results)
bitfield_extract_int :: proc "contextless" (value: int, offset, bits: uint) -> int {
	v := (uint(value) >> offset) & uint(1<<bits - 1)
	m := uint(1<<(bits-1))
	r := (v~m) - m
	return int(r)
}

/*
Extracts bits from an integer

Inputs:
- value: Integer
- offset: Offset (counting from LSB) at which to extract
- bits: Number of bits to extract

Returns:
- res: `bits` bits starting at offset `offset`
*/
bitfield_extract :: proc{
	bitfield_extract_u8,
	bitfield_extract_u16,
	bitfield_extract_u32,
	bitfield_extract_u64,
	bitfield_extract_u128,
	bitfield_extract_uint,
	bitfield_extract_i8,
	bitfield_extract_i16,
	bitfield_extract_i32,
	bitfield_extract_i64,
	bitfield_extract_i128,
	bitfield_extract_int,
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_u8 :: proc "contextless" (base, insert: u8, offset, bits: uint) -> (res: u8) {
	mask := u8(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_u16 :: proc "contextless" (base, insert: u16, offset, bits: uint) -> (res: u16) {
	mask := u16(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_u32 :: proc "contextless" (base, insert: u32, offset, bits: uint) -> (res: u32) {
	mask := u32(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_u64 :: proc "contextless" (base, insert: u64, offset, bits: uint) -> (res: u64) {
	mask := u64(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_u128 :: proc "contextless" (base, insert: u128, offset, bits: uint) -> (res: u128) {
	mask := u128(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_uint :: proc "contextless" (base, insert: uint, offset, bits: uint) -> (res: uint) {
	mask := uint(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_i8 :: proc "contextless" (base, insert: i8, offset, bits: uint) -> (res: i8) {
	mask := i8(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_i16 :: proc "contextless" (base, insert: i16, offset, bits: uint) -> (res: i16) {
	mask := i16(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_i32 :: proc "contextless" (base, insert: i32, offset, bits: uint) -> (res: i32) {
	mask := i32(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_i64 :: proc "contextless" (base, insert: i64, offset, bits: uint) -> (res: i64) {
	mask := i64(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_i128 :: proc "contextless" (base, insert: i128, offset, bits: uint) -> (res: i128) {
	mask := i128(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
@(require_results)
bitfield_insert_int :: proc "contextless" (base, insert: int, offset, bits: uint) -> (res: int) {
	mask := int(1<<bits - 1)
	return (base &~ (mask<<offset)) | ((insert&mask) << offset)
}

/*
Insert a subset of bits from one integer into another integer

Copies `bits` number of `insert`'s lower bits to `base` at `offset`.

Inputs:
- base: Original integer to insert bits into
- insert: Integer to copy bits from
- offset: Bit offset in `base` at which to place `insert`'s bits
- bits: Number of bits to copy

Returns:
- res: `base` with `bits` bits at `offset` replaced with `insert`'s
*/
bitfield_insert :: proc{
	bitfield_insert_u8,
	bitfield_insert_u16,
	bitfield_insert_u32,
	bitfield_insert_u64,
	bitfield_insert_u128,
	bitfield_insert_uint,
	bitfield_insert_i8,
	bitfield_insert_i16,
	bitfield_insert_i32,
	bitfield_insert_i64,
	bitfield_insert_i128,
	bitfield_insert_int,
}