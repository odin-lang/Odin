/*
The SIMD support package.

SIMD (Single Instruction Multiple Data), is a CPU hardware feature that
introduce special registers and instructions which operate on multiple units
of data at the same time, which enables faster data processing for
applications with heavy computational workloads.

In Odin SIMD is exposed via a special kinds of arrays, called the *SIMD
vectors*. The types of SIMD vectors is written as `#simd [N]T`, where N is a
power of two, and T could be any basic type (integers, floats, etc.). The
documentation of this package will call *SIMD vectors* just *vectors*.

SIMD vectors consist of elements, called *scalar values*, or
*scalars*, each occupying a *lane* of the SIMD vector. In the type declaration,
`N` specifies the amount of lanes, or values, that a vector stores.

This package implements procedures for working with vectors.
*/
package simd

import "base:builtin"
import "base:intrinsics"

/*
Check if SIMD is software-emulated on a target platform.

This value is `false`, when the compile-time target has the hardware support for
at 128-bit (or wider) SIMD. If the compile-time target lacks the hardware support
for 128-bit SIMD, this value is `true`, and all SIMD operations will likely be
emulated.
*/
IS_EMULATED :: true when (ODIN_ARCH == .amd64 || ODIN_ARCH == .i386) && !intrinsics.has_target_feature("sse2") else
	true when (ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32) && !intrinsics.has_target_feature("neon") else
	true when (ODIN_ARCH == .wasm64p32 || ODIN_ARCH == .wasm32) && !intrinsics.has_target_feature("simd128") else
	true when (ODIN_ARCH == .riscv64) && !intrinsics.has_target_feature("v") else
	false

/*
Vector of 16 `u8` lanes (128 bits).
*/
u8x16 :: #simd[16]u8

/*
Vector of 16 `i8` lanes (128 bits).
*/
i8x16 :: #simd[16]i8

/*
Vector of 8 `u16` lanes (128 bits).
*/
u16x8 :: #simd[8]u16

/*
Vector of 8 `i16` lanes (128 bits).
*/
i16x8 :: #simd[8]i16

/*
Vector of 4 `u32` lanes (128 bits).
*/
u32x4 :: #simd[4]u32

/*
Vector of 4 `i32` lanes (128 bits).
*/
i32x4 :: #simd[4]i32

/*
Vector of 2 `u64` lanes (128 bits).
*/
u64x2 :: #simd[2]u64

/*
Vector of 2 `i64` lanes (128 bits).
*/
i64x2 :: #simd[2]i64

/*
Vector of 4 `f32` lanes (128 bits).
*/
f32x4 :: #simd[4]f32

/*
Vector of 2 `f64` lanes (128 bits).
*/
f64x2 :: #simd[2]f64

/*
Vector of 16 `bool` lanes (128 bits).
*/
boolx16 :: #simd[16]bool

/*
Vector of 16 `b8` lanes (128 bits).
*/
b8x16   :: #simd[16]b8

/*
Vector of 8 `b16` lanes (128 bits).
*/
b16x8   :: #simd[8]b16

/*
Vector of 4 `b32` lanes (128 bits).
*/
b32x4   :: #simd[4]b32

/*
Vector of 2 `b64` lanes (128 bits).
*/
b64x2   :: #simd[2]b64

/*
Vector of 32 `u8` lanes (256 bits).
*/
u8x32  :: #simd[32]u8

/*
Vector of 32 `i8` lanes (256 bits).
*/
i8x32  :: #simd[32]i8

/*
Vector of 16 `u16` lanes (256 bits).
*/
u16x16 :: #simd[16]u16

/*
Vector of 16 `i16` lanes (256 bits).
*/
i16x16 :: #simd[16]i16

/*
Vector of 8 `u32` lanes (256 bits).
*/
u32x8  :: #simd[8]u32

/*
Vector of 8 `i32` lanes (256 bits).
*/
i32x8  :: #simd[8]i32

/*
Vector of 4 `u64` lanes (256 bits).
*/
u64x4  :: #simd[4]u64

/*
Vector of 4 `i64` lanes (256 bits).
*/
i64x4  :: #simd[4]i64

/*
Vector of 8 `f32` lanes (256 bits).
*/
f32x8  :: #simd[8]f32

/*
Vector of 4 `f64` lanes (256 bits).
*/
f64x4  :: #simd[4]f64

/*
Vector of 32 `bool` lanes (256 bits).
*/
boolx32 :: #simd[32]bool

/*
Vector of 32 `b8` lanes (256 bits).
*/
b8x32   :: #simd[32]b8

/*
Vector of 16 `b16` lanes (256 bits).
*/
b16x16  :: #simd[16]b16

/*
Vector of 8 `b32` lanes (256 bits).
*/
b32x8   :: #simd[8]b32

/*
Vector of 4 `b64` lanes (256 bits).
*/
b64x4   :: #simd[4]b64

/*
Vector of 64 `u8` lanes (512 bits).
*/
u8x64  :: #simd[64]u8

/*
Vector of 64 `i8` lanes (512 bits).
*/
i8x64  :: #simd[64]i8

/*
Vector of 32 `u16` lanes (512 bits).
*/
u16x32 :: #simd[32]u16

/*
Vector of 32 `i16` lanes (512 bits).
*/
i16x32 :: #simd[32]i16

/*
Vector of 16 `u32` lanes (512 bits).
*/
u32x16 :: #simd[16]u32

/*
Vector of 16 `i32` lanes (512 bits).
*/
i32x16 :: #simd[16]i32

/*
Vector of 8 `u64` lanes (512 bits).
*/
u64x8  :: #simd[8]u64

/*
Vector of 8 `i64` lanes (512 bits).
*/
i64x8  :: #simd[8]i64

/*
Vector of 16 `f32` lanes (512 bits).
*/
f32x16 :: #simd[16]f32

/*
Vector of 8 `f64` lanes (512 bits).
*/
f64x8  :: #simd[8]f64

/*
Vector of 64 `bool` lanes (512 bits).
*/
boolx64 :: #simd[64]bool

/*
Vector of 64 `b8` lanes (512 bits).
*/
b8x64   :: #simd[64]b8

/*
Vector of 32 `b16` lanes (512 bits).
*/
b16x32  :: #simd[32]b16

/*
Vector of 16 `b32` lanes (512 bits).
*/
b32x16  :: #simd[16]b32

/*
Vector of 8 `b64` lanes (512 bits).
*/
b64x8   :: #simd[8]b64

/*
Add SIMD vectors.

This procedure returns a vector, where each lane holds the sum of the
corresponding `a` and `b` vectors' lanes.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector that is the sum of two input vectors.

**Operation**:
	
	for i in 0 ..< len(res) {
		res[i] = a[i] + b[i]
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  0  |  1  |  2  |  3  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  |  1  |  2  | -1  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  0  |  2  |  4  |  2  |
	   +-----+-----+-----+-----+
*/
add :: intrinsics.simd_add

/*
Subtract SIMD vectors.

This procedure returns a vector, where each lane holds the difference between
the corresponding lanes of the vectors `a` and `b`. The lanes from the vector
`b` are subtracted from the corresponding lanes of the vector `a`.

Inputs:
- `a`: An integer or a float vector to subtract from.
- `b`: An integer or a float vector.

Returns:
- A vector that is the difference of two vectors, `a` - `b`.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] - b[i]
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  2  |  2  |  2  |  2  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  |  1  |  2  |  3  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  2  |  1  |  0  | -1  |
	   +-----+-----+-----+-----+
*/
sub :: intrinsics.simd_sub

/*
Multiply (component-wise) SIMD vectors.

This procedure returns a vector, where each lane holds the product of the
corresponding lanes of the vectors `a` and `b`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector that is the product of two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] * b[i]
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  2  |  2  |  2  |  2  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  | -1  |  2  | -3  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  0  | -2  |  4  | -6  |
	   +-----+-----+-----+-----+
*/
mul :: intrinsics.simd_mul

/*
Divide SIMD vectors.

This procedure returns a vector, where each lane holds the quotient (result
of division) between the corresponding lanes of the vectors `a` and `b`. Each
lane of the vector `a` is divided by the corresponding lane of the vector `b`.

This operation performs a standard floating-point division for each lane.

Inputs:
- `a`: A float vector.
- `b`: A float vector to divide by.

Returns:
- A vector that is the quotient of two vectors, `a` / `b`.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] / b[i]
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  2  |  2  |  2  |  2  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  | -1  |  2  | -3  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+------+
	   | +∞  | -2  |  1  | -2/3 |
	   +-----+-----+-----+------+
*/
div :: intrinsics.simd_div

/*
Shift left lanes of a vector.

This procedure returns a vector, such that each lane holds the result of a
shift-left (aka shift-up) operation of the corresponding lane from vector `a` by the shift
amount from the corresponding lane of the vector `b`.

If the shift amount is greater than the bit-width of a lane, the result is `0`
in the corresponding positions of the result.

Inputs:
- `a`: An integer vector of values to shift.
- `b`: An unsigned integer vector of the shift amounts.

Result:
- A vector, where each lane is the lane from `a` shifted left by the amount
specified in the corresponding lane of the vector `b`.

**Operation**:

	for i in 0 ..< len(res) {
		if b[i] < 8*size_of(a[i]) {
			res[i] = a[i] << b[i]
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	// An example for a 4-lane 8-bit signed integer vector `a`.

	   +-------+-------+-------+-------+
	a: |  0x11 |  0x55 |  0x03 |  0xff |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   2   |   1   |   33  |   1   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+--------+
	   |  0x44 |  0xaa |   0   |  0xfe  |
	   +-------+-------+-------+--------+
*/
shl :: intrinsics.simd_shl

/*
Shift right lanes of a vector.

This procedure returns a vector, such that each lane holds the result of a
shift-right (aka shift-down) operation, of lane from the vector `a` by the shift
amount from the corresponding lane of the vector `b`.

If the shift amount is greater than the bit-width of a lane, the result is `0`
in the corresponding positions of the result.

If the first vector is a vector of signed integers, the arithmetic shift
operation is performed. Otherwise, if the first vector is a vector of unsigned
integers, a logical shift is performed.

Inputs:
- `a`: An integer vector of values to shift.
- `b`: An unsigned integer vector of the shift amounts.

Result:
- A vector, where each lane is the lane from `a` shifted right by the amount
specified in the corresponding lane of the vector `b`.

**Operation**:

	for i in 0 ..< len(res) {
		if b[i] < 8*size_of(a[i]) {
			res[i] = a[i] >> b[i]
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	// An example for a 4-lane 8-bit signed integer vector `a`.

	   +-------+-------+-------+-------+
	a: |  0x11 |  0x55 |  0x03 |  0xff |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   2   |   1   |   33  |   1   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+--------+
	   |  0x04 |  0x2a |   0   |  0xff  |
	   +-------+-------+-------+--------+
*/
shr :: intrinsics.simd_shr

/*
Shift left lanes of a vector (masked).

This procedure returns a vector, such that each lane holds the result of a
shift-left (aka shift-up) operation, of lane from the vector `a` by the shift
amount from the corresponding lane of the vector `b`.

The shift amount is wrapped (masked) to the bit-width of the lane.

Inputs:
- `a`: An integer vector of values to shift.
- `b`: An unsigned integer vector of the shift amounts.

Result:
- A vector, where each lane is the lane from `a` shifted left by the amount
specified in the corresponding lane of the vector `b`.

**Operation**:

	for i in 0 ..< len(res) {
		mask := 8*size_of(a[i]) - 1
		res[i] = a[i] << (b[i] & mask)
	}
	return res

Example:

	// An example for a 4-lane vector `a` of 8-bit signed integers.

	   +-------+-------+-------+-------+
	a: |  0x11 |  0x55 |  0x03 |  0xff |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   2   |   1   |   33  |   1   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+--------+
	   |  0x44 |  0xaa |  0x06 |  0xfe  |
	   +-------+-------+-------+--------+
*/
shl_masked :: intrinsics.simd_shl_masked

/*
Shift right lanes of a vector (masked).

This procedure returns a vector, such that each lane holds the result of a
shift-right (aka shift-down) operation, of lane from the vector `a` by the shift
amount from the corresponding lane of the vector `b`.

The shift amount is wrapped (masked) to the bit-width of the lane.

If the first vector is a vector of signed integers, the arithmetic shift
operation is performed. Otherwise, if the first vector is a vector of unsigned
integers, a logical shift is performed.

Inputs:
- `a`: An integer vector of values to shift.
- `b`: An unsigned integer vector of the shift amounts.

Result:
- A vector, where each lane is the lane from `a` shifted right by the amount
specified in the corresponding lane of the vector `b`.

**Operation**:

	for i in 0 ..< len(res) {
		mask := 8*size_of(a[i]) - 1
		res[i] = a[i] >> (b[i] & mask)
	}
	return res

Example:

	// An example for a 4-lane vector `a` of 8-bit signed integers.

	   +-------+-------+-------+-------+
	a: |  0x11 |  0x55 |  0x03 |  0xff |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   2   |   1   |   33  |   1   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+--------+
	   |  0x04 |  0x2a |  0x01 |  0xff  |
	   +-------+-------+-------+--------+
*/
shr_masked :: intrinsics.simd_shr_masked

/*
Saturated addition of SIMD vectors.

The *saturated sum* is a just like a normal sum, except the treatment of the
result upon overflow or underflow is different. In saturated operations, the
result is not wrapped to the bit-width of the lane, and instead is kept clamped
between the minimum and the maximum values of the lane type.

This procedure returns a vector where each lane is the saturated sum of the
corresponding lanes of vectors `a` and `b`.

Inputs:
- `a`: An integer vector.
- `b`: An integer vector.

Returns:
- The saturated sum of the two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		switch {
		case b[i] >= max(type_of(a[i])) - a[i]: // (overflow of a[i])
			res[i] = max(type_of(a[i]))
		case b[i] <= min(type_of(a[i])) - a[i]: // (underflow of a[i])
			res[i] = min(type_of(a[i]))
		} else {
			res[i] = a[i] + b[i]
		}
	}
	return res

Example:

	// An example for a 4-lane vector `a` of 8-bit signed integers.

	   +-----+-----+-----+-----+
	a: |  0  | 255 |  2  |  3  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  1  |  3  |  2  | -1  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  1  | 255 |  4  |  2  |
	   +-----+-----+-----+-----+
*/
saturating_add :: intrinsics.simd_saturating_add

/*
Saturated subtraction of 2 lanes of vectors.

The *saturated difference* is a just like a normal difference, except the treatment of the
result upon overflow or underflow is different. In saturated operations, the
result is not wrapped to the bit-width of the lane, and instead is kept clamped
between the minimum and the maximum values of the lane type.

This procedure returns a vector where each lane is the saturated difference of
the corresponding lanes of vectors `a` and `b`.

Inputs:
- `a`: An integer vector to subtract from.
- `b`: An integer vector.

Returns:
- The saturated difference of the two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		switch {
		case b[i] >= max(type_of(a[i])) + a[i]: // (overflow of a[i])
			res[i] = max(type_of(a[i]))
		case b[i] <= min(type_of(a[i])) + a[i]: // (underflow of a[i])
			res[i] = min(type_of(a[i]))
		} else {
			res[i] = a[i] - b[i]
		}
	}
	return res

Example:

	// An example for a 4-lane vector `a` of 8-bit signed integers.

	   +-----+-----+-----+-----+
	a: |  0  | 255 |  2  |  3  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  3  |  3  |  2  | -1  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  0  | 252 |  0  |  4  |
	   +-----+-----+-----+-----+
*/
saturating_sub :: intrinsics.simd_saturating_sub

/*
Bitwise AND of vectors.

This procedure returns a vector, such that each lane has the result of a bitwise
AND operation between the corresponding lanes of the vectors `a` and `b`.

Inputs:
- `a`: An integer or a boolean vector.
- `b`: An integer or a boolean vector.

Returns:
- A vector that is the result of the bitwise AND operation between two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] & b[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: | 0x11 | 0x33 | 0x55 | 0xaa |
	   +------+------+------+------+
	   +------+------+------+------+
	b: | 0xff | 0xf0 | 0x0f | 0x00 |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   | 0x11 | 0x30 | 0x05 | 0x00 |
	   +------+------+------+------+
*/
bit_and     :: intrinsics.simd_bit_and

/*
Bitwise OR of vectors.

This procedure returns a vector, such that each lane has the result of a bitwise
OR operation between the corresponding lanes of the vectors `a` and `b`.

Inputs:
- `a`: An integer or a boolean vector.
- `b`: An integer or a boolean vector.

Returns:
- A vector that is the result of the bitwise OR operation between two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] | b[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: | 0x11 | 0x33 | 0x55 | 0xaa |
	   +------+------+------+------+
	   +------+------+------+------+
	b: | 0xff | 0xf0 | 0x0f | 0x00 |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   | 0xff | 0xf3 | 0x5f | 0xaa |
	   +------+------+------+------+
*/
bit_or      :: intrinsics.simd_bit_or

/*
Bitwise XOR of vectors.

This procedure returns a vector, such that each lane has the result of a bitwise
XOR operation between the corresponding lanes of the vectors `a` and `b`.

Inputs:
- `a`: An integer or a boolean vector.
- `b`: An integer or a boolean vector.

Returns:
- A vector that is the result of the bitwise XOR operation between two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] ~ b[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: | 0x11 | 0x33 | 0x55 | 0xaa |
	   +------+------+------+------+
	   +------+------+------+------+
	b: | 0xff | 0xf0 | 0x0f | 0x00 |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   | 0xee | 0xc3 | 0x5a | 0xaa |
	   +------+------+------+------+
*/
bit_xor     :: intrinsics.simd_bit_xor

/*
Bitwise AND NOT of vectors.

This procedure returns a vector, such that each lane has the result of a bitwise
AND NOT operation between the corresponding lanes of the vectors `a` and `b`.

Inputs:
- `a`: An integer or a boolean vector.
- `b`: An integer or a boolean vector.

Returns:
- A vector that is the result of the bitwise AND NOT operation between two vectors.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = a[i] &~ b[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: | 0x11 | 0x33 | 0x55 | 0xaa |
	   +------+------+------+------+
	   +------+------+------+------+
	b: | 0xff | 0xf0 | 0x0f | 0x00 |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   | 0x00 | 0x03 | 0x50 | 0xaa |
	   +------+------+------+------+
*/
bit_and_not :: intrinsics.simd_bit_and_not

/*
Negation of a SIMD vector.

This procedure returns a vector where each lane is the negation of the
corresponding lane in the vector `a`.

Inputs:
- `a`: An integer or a float vector to negate.

Returns:
- The negated version of the vector `a`.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = -a[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: |   0  |   1  |   2  |   3  |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   |   0  |  -1  |  -2  |  -3  |
	   +------+------+------+------+
*/
neg :: intrinsics.simd_neg

/*
Absolute value of a SIMD vector.

This procedure returns a vector where each lane has the absolute value of the
corresponding lane in the vector `a`.

Inputs:
- `a`: An integer or a float vector to negate

Returns:
- The absolute value of a vector.

**Operation**:

	for i in 0 ..< len(res) {
		switch {
			case a[i] < 0:  res[i] = -a[i]
			case a[i] > 0:  res[i] = a[i]
			case a[i] == 0: res[i] = 0
		}
	}
	return res

Example:

	   +------+------+------+------+
	a: |   0  |  -1  |   2  |  -3  |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   |   0  |   1  |   2  |   3  |
	   +------+------+------+------+
*/
abs   :: intrinsics.simd_abs

/*
Minimum of each lane of vectors.

This procedure returns a vector, such that each lane has the minimum value
between the corresponding lanes in vectors `a` and `b`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector containing with minimum values from corresponding lanes of `a` and `b`.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] < b[i] {
			res[i] = a[i]
		} else {
			res[i] = b[i]
		}
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  0  |  1  |  2  |  3  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  |  2  |  1  | -1  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  0  |  1  |  1  | -1  |
	   +-----+-----+-----+-----+
*/
min   :: intrinsics.simd_min

/*
Maximum of each lane of vectors.

This procedure returns a vector, such that each lane has the maximum value
between the corresponding lanes in vectors `a` and `b`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector containing with maximum values from corresponding lanes of `a` and `b`.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] > b[i] {
			res[i] = a[i]
		} else {
			res[i] = b[i]
		}
	}
	return res

Example:

	   +-----+-----+-----+-----+
	a: |  0  |  1  |  2  |  3  |
	   +-----+-----+-----+-----+
	   +-----+-----+-----+-----+
	b: |  0  |  2  |  1  | -1  |
	   +-----+-----+-----+-----+
	res:
	   +-----+-----+-----+-----+
	   |  0  |  2  |  2  |  3  |
	   +-----+-----+-----+-----+
*/
max   :: intrinsics.simd_max

/*
Clamp lanes of vector.

This procedure returns a vector, where each lane is the result of the
clamping of the lane from the vector `v` between the values in the corresponding
lanes of vectors `min` and `max`.

Inputs:
- `v`: An integer or a float vector with values to be clamped.
- `min`: An integer or a float vector with minimum bounds.
- `max`: An integer or a float vectoe with maximum bounds.

Returns:
- A vector containing clamped values in each lane.

**Operation**:

	for i in 0 ..< len(res) {
		val := v[i]
		switch {
			case val < min: val = min
			case val > max: val = max
		}
		res[i] = val
	}
	return res

Example:

	     +-------+-------+-------+-------+
	v:   |  -1   |  0.3  |  1.2  |   1   |
	     +-------+-------+-------+-------+
	     +-------+-------+-------+-------+
	min: |   0   |   0   |   0   |   0   |
	     +-------+-------+-------+-------+
	     +-------+-------+-------+-------+
	max: |   1   |   1   |   1   |   1   |
	     +-------+-------+-------+-------+
	res:
	     +-------+-------+-------+-------+
	     |   0   |  0.3  |   1   |   1   |
	     +-------+-------+-------+-------+
*/
clamp :: intrinsics.simd_clamp

/*
Check if lanes of vectors are equal.

This procedure checks each pair of lanes from vectors `a` and `b` for whether
they are equal, and if they are, the corresponding lane of the result vector
will have a value with all bits set (`0xff..ff`). Otherwise the lane of the
result vector will have the value `0`.

Inputs:
- `a`: An integer, a float or a boolean vector.
- `b`: An integer, a float or a boolean vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] == b[i] {
			res[i] = max(T)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	   | 0xff  | 0x00  | 0xff  | 0x00  |
	   +-------+-------+-------+-------+
*/
lanes_eq :: intrinsics.simd_lanes_eq

/*
Check if lanes of vectors are not equal.

This procedure checks each pair of lanes from vectors `a` and `b` for whether
they are not equal, and if they are, the corresponding lane of the result
vector will have a value with all bits set (`0xff..ff`). Otherwise the lane of
the result vector will have the value `0`.

Inputs:
- `a`: An integer, a float or a boolean vector.
- `b`: An integer, a float or a boolean vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] != b[i] {
			res[i] = unsigned(-1)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	   | 0x00  | 0xff  | 0x00  | 0xff  |
	   +-------+-------+-------+-------+
*/
lanes_ne :: intrinsics.simd_lanes_ne

/*
Check if lanes of a vector are less than another.

This procedure checks each pair of lanes from vectors `a` and `b` for whether
the lane of `a` is less than the lane of `b`, and if so, the corresponding lane
of the result vector will have a value with all bits set (`0xff..ff`). Otherwise
the lane of the result vector will have the value `0`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] < b[i] {
			res[i] = unsigned(-1)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	r: | 0x00  | 0xff  | 0x00  | 0x00  |
	   +-------+-------+-------+-------+
*/
lanes_lt :: intrinsics.simd_lanes_lt

/*
Check if lanes of a vector are less than or equal than another.
SIMD vector.

This procedure checks each pair of lanes from vectors `a` and `b` for whether the
lane of `a` is less than or equal to the lane of `b`, and if so, the
corresponding lane of the result vector will have a value with all bits set
(`0xff..ff`). Otherwise the lane of the result vector will have the value `0`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] <= b[i] {
			res[i] = unsigned(-1)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	   | 0xff  | 0xff  | 0xff  | 0x00  |
	   +-------+-------+-------+-------+
*/
lanes_le :: intrinsics.simd_lanes_le

/*
Check if lanes of a vector are greater than another.
vector.

This procedure checks each pair of lanes from vectors `a` and `b` for whether the
lane of `a` is greater than to the lane of `b`, and if so, the corresponding
lane of the result vector will have a value with all bits set (`0xff..ff`).
Otherwise the lane of the result vector will have the value `0`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] > b[i] {
			res[i] = unsigned(-1)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	   | 0x00  | 0x00  | 0x00  | 0xff  |
	   +-------+-------+-------+-------+
*/
lanes_gt :: intrinsics.simd_lanes_gt

/*
Check if lanes of a vector are greater than or equal than another.
SIMD vector.

This procedure checks each pair of lanes from vectors `a` and `b` for whether the
lane of `a` is greater than or equal to the lane of `b`, and if so, the
corresponding lane of the result vector will have a value with all bits set
(`0xff..ff`). Otherwise the lane of the result vector will have the value `0`.

Inputs:
- `a`: An integer or a float vector.
- `b`: An integer or a float vector.

Returns:
- A vector of unsigned integers of the same size as the input vector's lanes,
containing the comparison results for each lane.

**Operation**:

	for i in 0 ..< len(res) {
		if a[i] >= b[i] {
			res[i] = unsigned(-1)
		} else {
			res[i] = 0
		}
	}
	return res

Example:

	   +-------+-------+-------+-------+
	a: |   0   |   1   |   2   |   3   |
	   +-------+-------+-------+-------+
	   +-------+-------+-------+-------+
	b: |   0   |   2   |   2   |   2   |
	   +-------+-------+-------+-------+
	res:
	   +-------+-------+-------+-------+
	   | 0xff  | 0x00  | 0xff  | 0xff  |
	   +-------+-------+-------+-------+
*/
lanes_ge :: intrinsics.simd_lanes_ge

/*
Perform a gather load into a vector.

A *gather* operation is memory load operation, that loads values from an vector
of addresses into a single value vector. This can be used to achieve the
following results:

- Accessing every N'th element of an array (strided access)
- Access of elements according to some computed offsets (indexed access).
- Access of elements in a different order (shuffling access).

When used alongside other SIMD procedures in order to compute the offsets
for the `ptr` and `mask` parameters.

Inputs:
- `ptr`: A vector of memory locations. Each pointer points to a single value,
	of a SIMD vector's lane type that will be loaded into the vector. Pointer
	in this vector can be `nil` or any other invalid value, if the corresponding
	value in the `mask` parameter is zero.
- `val`: A vector of values that will be used at corresponding positions
	of the result vector, if the corresponding memory location has been
	masked out.
- `mask`: A vector of booleans or unsigned integers that determines which memory
	locations to read from. If the value at an index has the value true
	(lowest bit set), the value at that index will be loaded into the result
	vector from the corresponding memory location in the `ptr` vector. Otherwise
	the value will be loaded from the `val` vector.

Returns:
- A vector with all values from unmasked indices
loaded from the pointer vector `ptr`, and all values from masked indices loaded
from the value vector `val`.

**Operation**:

	for i in 0 ..< len(res) {
		if mask[i]&1 == 1 {
			res[i] = ptr[i]^
		} else {
			res[i] = val[i]
		}
	}
	return res

Example:

	// Example below loads 2 lanes of values from 2 lanes of float vectors, `v1` and
	// `v2`. From each of these vectors we're loading the second value, into the first
	// and the third position of the result vector.

	// Therefore the `ptrs` argument is initialized such that the first and the third
	// value are the addresses of the values that we want to load into the result
	// vector, and we'll fill in `nil` for the rest of them. To prevent CPU from
	// dereferencing those `nil` addresses we provide the mask that only allows us
	// to load valid positions of the `ptrs` array, and the array of defaults which
	// will have `127` in each position as the default value.

	v1 := [4] f32 {1, 2, 3, 4};
	v2 := [4] f32 {9, 10,11,12};
	ptrs := #simd [4]rawptr { &v1[1], nil, &v2[1], nil }
	mask := #simd [4]bool { true, false, true, false }
	defaults := #simd [4]f32 { 0x7f, 0x7f, 0x7f, 0x7f }
	res := simd.gather(ptrs, defaults, mask)
	fmt.println(res)

Output:

	<2, 127, 10, 127>

The first and the third positions came from the `ptrs` array, and the other
2 lanes of from the default vector. The graphic below shows how the values of
the result are decided based on the mask:

	      +-------------------------------+ 
	mask: |   1   |   0   |   1   |   0   | 
	      +-------------------------------+ 
	        |         |       |       `----------------------------.
	        |         |       |                                    |
	        |          `----  |  ------------------------.         |
	        v                 v                          v         v
	      +-------------------------------+       +-------------------+
	ptrs: |  &m0  |  nil  |  &m2  |  nil  | vals: | d0 | d1 | d2 | d3 |
	      +-------------------------------+       +-------------------+
	          |               |                          |         |
	          |          .--- | -------------------------'         |
	          |         |     |          ,-------------------------'
	          v         v     v         v
	        +-------------------------------+
	result: |   m0  |   d1  |   m2  |  d3   |
	        +-------------------------------+
*/
gather  :: intrinsics.simd_gather

/*
Perform a scatter store from a vector.

A *scatter* operation is a memory store operation that stores values from a
vector into multiple memory locations. This operation is effectively the
opposite of the *gather* operation.

Inputs:
- `ptr`: A vector of memory locations. Each masked location will be written
	to with a value from the `val` vector. Pointers in this vector can be `nil`
	or any other invalid value if the corresponding value in the `mask`
	parameter is zero.
- `val`: A vector of values to write to the memory locations.
- `mask`: A vector of booleans or unsigned integers that decides which lanes
	get written to memory. If the value of the mask is `true` (the lowest bit
	set), the corresponding lane is written into memory. Otherwise it's not
	written into memory.

**Operation**:

	for i in 0 ..< len(ptr) {
		if mask[i]&1 == 1 {
			ptr[i]^ = val[i]
		}
	}

Example:

	// Example below writes value `127` to the second element of two different
	// vectors. The addresses of store destinations are written to the first and the
	// third argument of the `ptr` vector, and the `mask` is set accordingly.

	v1 := [4] f32 {1, 2, 3, 4};
	v2 := [4] f32 {5, 6, 7, 8};
	ptrs := #simd [4]rawptr { &v1[1], nil, &v2[1], nil }
	mask := #simd [4]bool { true, false, true, false }
	vals := #simd [4]f32 { 0x7f, 0x7f, 0x7f, 0x7f }
	simd.scatter(ptrs, vals, mask)
	fmt.println(v1)
	fmt.println(v2)

Output:

	[1, 127, 3, 4]
	[5, 127, 7, 8]

The graphic below shows how the data gets written into memory.

	
	      +-------------------+
	mask: | 1  | 0  | 1  | 0  |
	      +-------------------+
	        |    |    |    |
	        v    X    v    X
	      +-------------------+
	vals: | d0 | d1 | d2 | d3 |
	      +-------------------+
	         |         \
	         v          v
	      +-----------------------+
	ptrs: | &m0 | nil | &m2 | nil |
	      +-----------------------+
*/
scatter :: intrinsics.simd_scatter

/*
Perform a masked load into the vector.

This procedure performs a masked load from memory, into the vector. The `ptr`
argument specifies the base address from which the values of the vector
will be loaded. The mask selects the source for the result vector's lanes. If
the mask for the corresponding lane has the value `true` (lowest bit set), the
result lane is loaded from memory. Otherwise the result lane is loaded from the
corresponding lane of the `val` vector.

Inputs:
- `ptr`: The address of the vector values to load. Masked-off values are not
	accessed.
- `val`: The vector of values that will be loaded into the masked slots of the
	result vector.
- `mask`: The mask that selects where to load the values from.

Returns:
- The loaded vector. The lanes for which the mask was set are loaded from
memory, and the other lanes are loaded from the `val` vector.

**Operation**:

	for i in 0 ..< len(res) {
		if mask[i]&1 == 1 {
			res[i] = ptr[i]
		} else {
			res[i] = vals[i]
		}
	}
	return res

Example:

	// The following code loads two values from the `src` vector, the first and the
	// third value (selected by the mask). The masked-off values are given the value
	// of 127 (`0x7f`).

	src := [4] f32 {1, 2, 3, 4};
	mask := #simd [4]bool { true, false, true, false }
	vals := #simd [4]f32 { 0x7f, 0x7f, 0x7f, 0x7f }
	res := simd.masked_load(&src, vals, mask)
	fmt.println(res)

Output:

	<1, 127, 3, 127>

The graphic below demonstrates the flow of lanes.

	      +-------------------------------+ 
	mask: |   1   |   0   |   1   |   0   | 
	      +-------------------------------+ 
	        |         |       |       `----------------------------.
	        |         |       |                                    |
	        |          `----  |  ------------------------.         |
	ptr     v                 v                          v         v
	+---->+-------------------------------+       +-------------------+
	      |   v1  |   v2  |   v3  |   v4  | vals: | d0 | d1 | d2 | d3 |
	      +-------------------------------+       +-------------------+
	          |               |                          |         |
	          |          .--- | -------------------------'         |
	          |         |     |          ,-------------------------'
	          v         v     v         v
	        +-------------------------------+
	result: |  v1   |   d1  |  v3   |  d3   |
	        +-------------------------------+
*/
masked_load  :: intrinsics.simd_masked_load

/*
Perform a masked store to memory.

This procedure performs a masked store from a vector `val`, into memory at
address `ptr`, with the `mask` deciding which lanes are going to be stored,
and which aren't. If the mask at a corresponding lane has the value `true`
(lowest bit set), the lane is stored into memory. Otherwise the lane is not
stored into memory.

Inputs:
- `ptr`: The base address of the store.
- `val`: The vector to store.
- `mask`: The mask, selecting which lanes of the vector to store into memory.

**Operation**:

	for i in 0 ..< len(val) {
		if mask[i]&1 == 1 {
			ptr[i] = val
		}
	}

Example:

	// Example below stores the value 127 into the first and the third slot of the
	// vector `v`.

	v := [4] f32 {1, 2, 3, 4};
	mask := #simd [4]bool { true, false, true, false }
	vals := #simd [4]f32 { 0x7f, 0x7f, 0x7f, 0x7f }
	simd.masked_store(&v, vals, mask)
	fmt.println(v)

Output:

	[127, 2, 127, 4]

The graphic below shows the flow of lanes:

	      +-------------------+
	mask: | 1  | 0  | 1  | 0  |
	      +-------------------+
	        |    |    |    |
	        v    X    v    X
	      +-------------------+
	vals: | v0 | v1 | v2 | v3 |
	      +-------------------+
	         |         \
	ptr      v          v
	 +--->+-----------------------+
	      | v0  | ... | v2  | ... |
	      +-----------------------+
*/
masked_store :: intrinsics.simd_masked_store

/*
Load consecutive scalar values and expand into a vector.

This procedure loads a number of consecutive scalar values from an address,
specified by the `ptr` parameter, and stores them in a result vector, according
to the mask. The number of values read from memory is the number of set bits
in the mask. The lanes for which the mask has the value `true` get the next
consecutive value from memory, otherwise if the mask is `false` for the
lane, its value is filled from the corresponding lane of the `val` parameter.

This procedure acts like `masked_store`, except the values from memory are
read consecutively, and not according to the lanes. The memory values are read
and assigned to the result vector's masked lanes in order of increasing
addresses.

Inputs:
- `ptr`: The pointer to the memory to read from.
- `vals`: The default values for masked-off entries.
- `mask`: The mask that determines which lanes get consecutive memory values.

Returns:
- The result vector, holding masked memory values unmasked default values.

**Operation**:

	mem_idx := 0
	for i in 0 ..< len(mask) {
		if mask[i]&1 == 1 {
			res[i] = ptr[mem_idx]
			mem_idx += 1
		} else {
			res[i] = val[i]
		}
	}
	return res

Example:

	// The example below loads two values from memory of the vector `v`. Two values in
	// the mask are set to `true`, meaning only two memory items will be loaded into
	// the result vector. The mask is set to `true` in the first and the third
	// position, which specifies that the first memory item will be read into the
	// first lane of the result vector, and the second memory item will be read into
	// the third lane of the result vector. All the other lanes of the result vector
	// will be initialized to the default value `127`.

	v := [2] f64 {1, 2};
	mask := #simd [4]bool { true, false, true, false }
	vals := #simd [4]f64 { 0x7f, 0x7f, 0x7f, 0x7f }
	res := simd.masked_expand_load(&v, vals, mask)
	fmt.println(res)

Output:

	<1, 127, 2, 127>

Graphical representation of the operation:


	ptr --->+-----------+-----
	        | m0  | m1  | ...
	        +-----------+-----
	          |      `--.
	          v         v
	        +-------------------+         +-------------------+
	mask:   | 1  | 0  | 1  | 0  |   vals: | v0 | v1 | v2 | v3 |
	        +-------------------+         +-------------------+
	          |         |                         |         |
	          |     .-- | -----------------------'          |
	          |    |    |     ,----------------------------'
	          v    v    v    v
	        +-------------------+
	result: | m0 | v1 | m1 | v3 |
	        +-------------------+
*/
masked_expand_load    :: intrinsics.simd_masked_expand_load

/*
Store masked values to consecutive memory locations.

This procedure stores values from masked lanes of a vector `val` consecutively
into memory. This operation is the opposite of `masked_expand_load`. The number
of items stored into memory is the number of set bits in the mask. If the value
in a lane of a mask is `true`, that lane is stored into memory. Otherwise
nothing is stored.

Inputs:
- `ptr`: The pointer to the memory of a store.
- `val`: The vector to store into memory.
- `mask`: The mask that selects which values to store into memory.

**Operation**:

	mem_idx := 0
	for i in 0 ..< len(mask) {
		if mask[i]&1 == 1 {
			ptr[mem_idx] = val[i]
			mem_idx += 1
		}
	}

Example:

	// The code below fills the vector `v` with two values from a 4-element SIMD
	// vector, the first and the third value. The items in the mask are set to `true`
	// in those lanes.

	v := [2] f64 { };
	mask := #simd [4]bool { true, false, true, false }
	vals := #simd [4]f64 { 1, 2, 3, 4 }
	simd.masked_compress_store(&v, vals, mask)
	fmt.println(v)

Output:

	[1, 3]

Graphical representation of the operation:

	      +-------------------+
	mask: | 1  | 0  | 1  | 0  |
	      +-------------------+
	        |         |
	        v         v
	      +-------------------+
	vals: | v0 | v1 | v2 | v3 |
	      +-------------------+
	        |      ,--'
	ptr     v     v
	 +--->+-----------------
	      | v0  | v2  | ...
	      +-----------------
*/
masked_compress_store :: intrinsics.simd_masked_compress_store

/*
Extract scalar from a vector's lane.

This procedure returns the scalar from the lane at the specified index of the
vector.

Inputs:
- `a`: The vector to extract from.
- `idx`: The lane index.

Returns:
- The value of the lane at the specified index.

**Operation**:

	return a[idx]
*/
extract :: intrinsics.simd_extract

/*
Replace the value in a vector's lane.

This procedure places a scalar value at the lane corresponding to the given index of
the vector.

Inputs:
- `a`: The vector to replace a lane in.
- `idx`: The lane index.
- `elem`: The scalar to place.

Returns:
- Vector with the specified lane replaced.

**Operation**:

	a[idx] = elem
*/
replace :: intrinsics.simd_replace

/*
Reduce a vector to a scalar by adding up all the lanes.

This procedure returns a scalar that is the ordered sum of all lanes. The
ordered sum may be important for accounting for precision errors in
floating-point computation, as floating-point addition is not associative,
that is `(a+b)+c` may not be equal to `a+(b+c)`.

Inputs:
- `a`: The vector to reduce.

Result:
- Sum of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res += a[i]
	}
*/
reduce_add_ordered :: intrinsics.simd_reduce_add_ordered

/*
Reduce a vector to a scalar by multiplying all the lanes.

This procedure returns a scalar that is the ordered product of all lanes.
The ordered product may be important for accounting for precision errors in
floating-point computation, as floating-point multiplication is not associative,
that is `(a*b)*c` may not be equal to `a*(b*c)`.

Inputs:
- `a`: The vector to reduce.

Result:
- Product of all lanes, as a scalar.

**Operation**:

	res := 1
	for i in 0 ..< len(a) {
		res *= a[i]
	}
*/
reduce_mul_ordered :: intrinsics.simd_reduce_mul_ordered

/*
Reduce a vector to a scalar by finding the minimum value between all of the lanes.

This procedure returns a scalar that is the minimum value of all the lanes
in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Minimum value of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res = min(res, a[i])
	}
*/
reduce_min :: intrinsics.simd_reduce_min

/*
Reduce a vector to a scalar by finding the maximum value between all of the lanes.

This procedure returns a scalar that is the maximum value of all the lanes
in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Maximum value of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res = max(res, a[i])
	}
*/
reduce_max :: intrinsics.simd_reduce_max

/*
Reduce a vector to a scalar by performing bitwise AND of all of the lanes.

This procedure returns a scalar that is the result of the bitwise AND operation
between all of the lanes in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Bitwise AND of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res &= a[i]
	}
*/
reduce_and :: intrinsics.simd_reduce_and

/*
Reduce a vector to a scalar by performing bitwise OR of all of the lanes.

This procedure returns a scalar that is the result of the bitwise OR operation
between all of the lanes in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Bitwise OR of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res |= a[i]
	}
*/
reduce_or :: intrinsics.simd_reduce_or

/*
Reduce SIMD vector to a scalar by performing bitwise XOR of all of the lanes.

This procedure returns a scalar that is the result of the bitwise XOR operation
between all of the lanes in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Bitwise XOR of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res ~= a[i]
	}
*/
reduce_xor :: intrinsics.simd_reduce_xor

/*
Reduce SIMD vector to a scalar by performing bitwise OR of all of the lanes.

This procedure returns a scalar that is the result of the bitwise OR operation
between all of the lanes in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Bitwise OR of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res |= a[i]
	}
*/
reduce_any :: intrinsics.simd_reduce_any

/*
Reduce SIMD vector to a scalar by performing bitwise AND of all of the lanes.

This procedure returns a scalar that is the result of the bitwise AND operation
between all of the lanes in a vector.

Inputs:
- `a`: The vector to reduce.

Result:
- Bitwise AND of all lanes, as a scalar.

**Operation**:

	res := 0
	for i in 0 ..< len(a) {
		res &= a[i]
	}
*/
reduce_all :: intrinsics.simd_reduce_all

/*
Reorder the lanes of a SIMD vector.

This procedure reorders the lanes of a vector, according to the provided
indices. The number of indices correspond to the number of lanes in the
result vector and must be the same as the number of lanes of the input vector.
Each index specifies, the lane of the scalar from the input vector, which
will be written at the corresponding position of the result vector.

Inputs:
- `x`: The input vector.
- `indices`: The indices of lanes to write to the result vector.

Result:
- Swizzled input vector.

**Operation**:

	res = {}
	for i in 0 ..< len(indices) {
		res[i] = x[indices[i]]
	}
	return res

Example:

	// The example below shows how the indices are used to determine which lanes of the
	// input vector get written into the result vector.
	
	x := #simd [4]f32 { 1.5, 2.5, 3.5, 4.5 }
	res := simd.swizzle(x, 0, 3, 1, 1)
	fmt.println("res")

Output:

	[ 1.5, 3.5, 2.5, 2.5 ]

The graphical representation of the operation is as follows. The `idx` vector in
the picture represents the `indices` parameter:

	      0     1     2     3
	      +-----+-----+-----+-----+
	x:    | 1.5 | 2.5 | 3.5 | 4.5 |
	      +-----+-----+-----+-----+
	         ^     ^           ^
	         |     |           |
	         |      '----.     |
	         |     .---- | ---'
	         |     |     |
	         |     |     +------.
	      +-----+-----+-----+-----+
	idx:  |  0  |  3  |  1  |  1  |
	      +-----+-----+-----+-----+
	         ^     ^     ^     ^
	         |     |     |     |
	      +-----+-----+-----+-----+
	res:  | 1.5 | 3.5 | 2.5 | 2.5 |
	      +-----+-----+-----+-----+
*/
swizzle :: builtin.swizzle

/*
Extract the set of most-significant bits of a SIMD vector.

This procedure checks the the most-significant bit (MSB) for each lane of vector
and returns the numbers of lanes with the most-significant bit set. This procedure
can be used in conjuction with `lanes_eq` (and other similar procedures) to
count the number of matched lanes by computing the cardinality of the resulting
set.

Inputs:
- `a`: An input vector.

Result:
- A bitset of integers, corresponding to the indexes of the lanes, whose MSBs
  are set.

**Operation**:

	bits_per_lane = 8*size_of(a[0])
	res = bit_set {}
	for i in 0 ..< len(a) {
		if a[i] & 1<<(bits_per_lane-1) != 0 {
			res |= i
		}
	}
	return res

Example:

	// Since lanes 0, 1, 4, 7 contain negative numbers, the most significant
	// bits for them will be set.
	v := #simd [8]i32 { -1, -2, +3, +4, -5, +6, +7, -8 }
	fmt.println(simd.extract_msbs(v))

Output:

	bit_set[0..=7]{0, 1, 4, 7}
*/
extract_msbs :: intrinsics.simd_extract_msbs

/*
Extract the set of least-significant bits of a SIMD vector.

This procedure checks the the least-significant bit (LSB) for each lane of vector
and returns the numbers of lanes with the least-significant bit set. This procedure
can be used in conjuction with `lanes_eq` (and other similar procedures) to
count the number of matched lanes by computing the cardinality of the resulting
set.

Inputs:
- `a`: An input vector.

Result:
- A bitset of integers, corresponding to the indexes of the lanes, whose LSBs
  are set.

**Operation**:

	res = bit_set {}
	for i in 0 ..< len(a) {
		if a[i] & 1 != 0 {
			res |= i
		}
	}
	return res

Example:

	// Since lanes 0, 2, 4, 6 contain odd integers, the least significant bits
	// for these lanes are set.
	v := #simd [8]i32 { -1, -2, +3, +4, -5, +6, +7, -8 }
	fmt.println(simd.extract_lsbs(v))

Output:

	bit_set[0..=7]{0, 2, 4, 6}
*/
extract_lsbs :: intrinsics.simd_extract_lsbs

/*
Reorder the lanes of two SIMD vectors.

This procedure returns a vector, containing the scalars from the lanes of two
vectors, according to the provided indices vector. Each index in the indices
vector specifies, the lane of the scalar from one of the two input vectors,
which will be written at the corresponding position of the result vector. If
the index is within bounds 0 ..< len(A), it corresponds to the indices of the
first input vector. Otherwise the index corresponds to the indices of the second
input vector.

Inputs:
- `a`: The first input vector.
- `b`: The second input vector.
- `indices`: The indices.

Result:
- Input vectors, shuffled according to the indices.

**Operation**:

	res = {}
	for i in 0 ..< len(indices) {
		idx = indices[i];
		if idx < len(a) {
			res[i] = a[idx]
		} else {
			res[i] = b[idx]
		}
	}
	return res

Example:

	// The example below shows how the indices are used to determine lanes of the
	// input vector that are shuffled into the result vector.
	
	a := #simd [4]f32 { 1, 2, 3, 4 }
	b := #simd [4]f32 { 5, 6, 7, 8 }
	res := simd.shuffle(a, b, 0, 4, 2, 5)
	fmt.println("res")

Output:

	[ 1, 5, 3, 6 ]

The graphical representation of the operation is as follows. The `idx` vector in
the picture represents the `indices` parameter:

	      0     1     2     3            4     5     6     7
	      +-----+-----+-----+-----+      +-----+-----+-----+-----+
	a:    |  1  |  2  |  3  |  4  |  b:  |  5  |  6  |  7  |  8  |
	      +-----+-----+-----+-----+      +-----+-----+-----+-----+
	         ^           ^                  ^     ^
	         |           |                  |     |
	         |           |                  |     |
	         |      .--- | ----------------'      |
	         |     |     |     .-----------------'
	      +-----+-----+-----+-----+
	idx:  |  0  |  4  |  2  |  5  |
	      +-----+-----+-----+-----+
	         ^     ^     ^     ^
	         |     |     |     |
	      +-----+-----+-----+-----+
	res:  |  1  |  5  |  3  |  6  |
	      +-----+-----+-----+-----+
*/
shuffle :: intrinsics.simd_shuffle

/*
Select values from one of the two vectors.

This procedure returns a vector, which has, on each lane a value from one of the
corresponding lanes in one of the two input vectors based on the `cond`
parameter. On each lane, if the value of the `cond` parameter is `true` (or
non-zero), the result lane will have a value from the `true` input vector,
otherwise the result lane will have a value from the `false` input vector.

Inputs:
- `cond`: The condition vector.
- `true`: The first input vector.
- `false`: The second input vector.

Result:
- The result of selecting values from the two input vectors.

**Operation**:

	res = {}
	for i in 0 ..< len(cond) {
		if cond[i] {
			res[i] = true[i]
		} else {
			res[i] = false[i]
		}
	}
	return res

Example:

	// The following example selects values from the two input vectors, `a` and `b`
	// into a single vector.
	a := #simd [4] f64 { 1,2,3,4 }
	b := #simd [4] f64 { 5,6,7,8 }
	cond := #simd[4] int { 1, 0, 1, 0 }
	fmt.println(simd.select(cond,a,b))

Output:
	
	[ 1, 6, 3, 8 ]

Graphically, the operation looks as follows. The `t` and `f` represent the
`true` and `false` vectors respectively:

	      0     1     2     3            0     1     2     3
	      +-----+-----+-----+-----+      +-----+-----+-----+-----+
	t:    |  1  |  2  |  3  |  4  |  f:  |  5  |  6  |  7  |  8  |
	      +-----+-----+-----+-----+      +-----+-----+-----+-----+
	         ^           ^                        ^           ^
	         |           |                        |           |
	         |           |                        |           |
	         |      .--- | ----------------------'            |
	         |     |     |     .-----------------------------'
	      +-----+-----+-----+-----+
	cond: |  1  |  0  |  1  |  0  |
	      +-----+-----+-----+-----+
	         ^     ^     ^     ^
	         |     |     |     |
	      +-----+-----+-----+-----+
	res:  |  1  |  5  |  3  |  6  |
	      +-----+-----+-----+-----+
*/
select :: intrinsics.simd_select

/*
Compute the square root of each lane in a SIMD vector.
*/
sqrt    :: intrinsics.sqrt

/*
Ceil each lane in a SIMD vector.
*/
ceil    :: intrinsics.simd_ceil

/*
Floor each lane in a SIMD vector.
*/
floor   :: intrinsics.simd_floor

/*
Truncate each lane in a SIMD vector.
*/
trunc   :: intrinsics.simd_trunc

/*
Compute the nearest integer of each lane in a SIMD vector.
*/
nearest :: intrinsics.simd_nearest

/*
Transmute a SIMD vector into an integer vector.
*/
to_bits :: intrinsics.simd_to_bits

/*
Reverse the lanes of a SIMD vector.

This procedure reverses the lanes of a vector, putting last lane in the
first spot, etc. This procedure is equivalent to the following call (for
4-element vectors):

	swizzle(a, 3, 2, 1, 0)
*/
lanes_reverse :: intrinsics.simd_lanes_reverse

/*
Rotate the lanes of a SIMD vector left.

This procedure rotates the lanes of a vector, putting the first lane of the
last spot, second lane in the first spot, third lane in the second spot, etc.
For 4-element vectors, this procedure is equvalent to the following:

	swizzle(a, 1, 2, 3, 0)
*/
lanes_rotate_left :: intrinsics.simd_lanes_rotate_left

/*
Rotate the lanes of a SIMD vector right.

This procedure rotates the lanes of a SIMD vector, putting the first lane of the
second spot, second lane in the third spot, etc. For 4-element vectors, this
procedure is equvalent to the following:

	swizzle(a, 3, 0, 1, 2)
*/
lanes_rotate_right :: intrinsics.simd_lanes_rotate_right

/*
Count the number of set bits in each lane of a SIMD vector.
*/
count_ones :: intrinsics.count_ones

/*
Count the number of unset bits in each lane of a SIMD vector.
*/
count_zeros :: intrinsics.count_zeros

/*
Count the number of trailing unset bits in each lane of a SIMD vector.
*/
count_trailing_zeros :: intrinsics.count_trailing_zeros

/*
Count the number of leading unset bits in each lane of a SIMD vector.
*/
count_leading_zeros :: intrinsics.count_leading_zeros

/*
Reverse the bit pattern of a SIMD vector.
*/
reverse_bits :: intrinsics.reverse_bits

/*
Perform a FMA (Fused multiply-add) operation on each lane of SIMD vectors.

A fused multiply-add is a ternary operation that for three operands, `a`, `b`
and `c`  performs the operation `a*b+c`. This operation is a hardware feature
that allows to minimize floating-point error and allow for faster computation.

This procedure performs a FMA operation on each lane of the SIMD vectors.

Inputs:
- `a`: The multiplier
- `b`: The multiplicand
- `c`: The addend

Returns:
- `a*b+c`

**Operation**

	res := 0
	for i in 0 ..< len(a) {
		res[i] = fma(a[i], b[i], c[i])
	}
	return res
*/
fused_mul_add :: intrinsics.fused_mul_add

/*
Perform a FMA (Fused multiply-add) operation on each lane of SIMD vectors.

A fused multiply-add is a ternary operation that for three operands, `a`, `b`
and `c`  performs the operation `a*b+c`. This operation is a hardware feature
that allows to minimize floating-point error and allow for faster computation.

This procedure performs a FMA operation on each lane of the SIMD vectors.

Inputs:
- `a`: The multiplier.
- `b`: The multiplicand.
- `c`: The addend.

Returns:
- `a*b+c`

**Operation**

	res := 0
	for i in 0 ..< len(a) {
		res[i] = fma(a[i], b[i], c[i])
	}
	return res
*/
fma :: intrinsics.fused_mul_add

/*
Convert pointer to SIMD vector to an array pointer.
*/
to_array_ptr :: #force_inline proc "contextless" (v: ^#simd[$LANES]$E) -> ^[LANES]E {
	return (^[LANES]E)(v)
}

/*
Convert SIMD vector to an array.
*/
to_array :: #force_inline proc "contextless" (v: #simd[$LANES]$E) -> [LANES]E {
	return transmute([LANES]E)(v)
}

/*
Convert array to SIMD vector.
*/
from_array :: #force_inline proc "contextless" (v: $A/[$LANES]$E) -> #simd[LANES]E {
	return transmute(#simd[LANES]E)v
}

/*
Convert slice to SIMD vector.
*/
from_slice :: proc($T: typeid/#simd[$LANES]$E, slice: []E) -> T {
	assert(len(slice) >= LANES, "slice length must be a least the number of lanes")
	array: [LANES]E
	#no_bounds_check for i in 0..<LANES {
		array[i] = slice[i]
	}
	return transmute(T)array
}

/*
Perform binary not operation on a SIMD vector.

This procedure returns a vector where each lane is the result of the binary
NOT operation of the corresponding lane in the vector `a`.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = ~a[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: | 0x00 | 0x50 | 0x80 | 0xff |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   | 0xff | 0xaf | 0x7f | 0x00 |
	   +------+------+------+------+
*/
bit_not :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_integer(E) {
	return xor(v, T(~E(0)))
}

/*
Copy the signs from lanes of one SIMD vector into another SIMD vector.
*/
copysign :: #force_inline proc "contextless" (v, sign: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	neg_zero := to_bits(T(-0.0))
	sign_bit := to_bits(sign) & neg_zero
	magnitude := to_bits(v) &~ neg_zero
	return transmute(T)(sign_bit|magnitude)
}

/*
Return signs of SIMD lanes.

This procedure returns a vector, each lane of which contains either +1.0 or
-1.0 depending on the sign of the value in the corresponding lane of the
input vector. If the lane of the input vector has NaN, then the result vector
will contain this NaN value as-is.
*/
signum :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	is_nan := lanes_ne(v, v)
	return select(is_nan, v, copysign(T(1), v))
}

/*
Calculate reciprocals of SIMD lanes.

This procedure returns a vector where each lane is the reciprocal of the
corresponding lane in the vector `a`.

Inputs:
- `a`: An integer or a float vector to negate.

Returns:
- Negated vector.

**Operation**:

	for i in 0 ..< len(res) {
		res[i] = 1.0 / a[i]
	}
	return res

Example:

	   +------+------+------+------+
	a: |   2  |   1  |   3  |   5  |
	   +------+------+------+------+
	res:
	   +------+------+------+------+
	   |  0.5 |   1  | 0.33 |  0.2 |
	   +------+------+------+------+
*/
recip :: #force_inline proc "contextless" (v: $T/#simd[$LANES]$E) -> T where intrinsics.type_is_float(E) {
	return T(1) / v
}
