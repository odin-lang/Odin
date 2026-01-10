/*
Various useful bit operations in constant time.
*/
package _subtle

import "core:math/bits"

// byte_eq returns 1 iff a == b, 0 otherwise.
@(optimization_mode="none")
byte_eq :: proc "contextless" (a, b: byte) -> int {
	v := a ~ b

	// v == 0 iff a == b.  The subtraction will underflow, setting the
	// sign bit, which will get returned.
	return int((u32(v)-1) >> 31)
}

// u64_eq returns 1 iff a == b, 0 otherwise.
@(optimization_mode="none")
u64_eq :: proc "contextless" (a, b: u64) -> u64 {
	_, borrow := bits.sub_u64(0, a ~ b, 0)
	return (~borrow) & 1
}

eq :: proc {
	byte_eq,
	u64_eq,
}

// u64_is_zero returns 1 iff a == 0, 0 otherwise.
@(optimization_mode="none")
u64_is_zero :: proc "contextless" (a: u64) -> u64 {
	_, borrow := bits.sub_u64(a, 1, 0)
	return borrow
}

// u64_is_non_zero returns 1 iff a != 0, 0 otherwise.
@(optimization_mode="none")
u64_is_non_zero :: proc "contextless" (a: u64) -> u64 {
	is_zero := u64_is_zero(a)
	return (~is_zero) & 1
}
