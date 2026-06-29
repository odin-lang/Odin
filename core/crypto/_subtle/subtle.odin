/*
Various useful bit operations in constant time.
*/
package _subtle

import "core:crypto/_fiat"
import "core:math/bits"

// byte_eq returns 1 if and only if (⟺) a == b, 0 otherwise.
@(optimization_mode="none")
byte_eq :: proc "contextless" (a, b: byte) -> int {
	v := a ~ b

	// v == 0 if and only if (⟺) a == b.  The subtraction will underflow, setting the
	// sign bit, which will get returned.
	return int((u32(v)-1) >> 31)
}

// u64_eq returns 1 if and only if (⟺) a == b, 0 otherwise.
@(optimization_mode="none")
u64_eq :: proc "contextless" (a, b: u64) -> u64 {
	_, borrow := bits.sub_u64(0, a ~ b, 0)
	return (~borrow) & 1
}

eq :: proc {
	byte_eq,
	u64_eq,
}

// u64_is_zero returns 1 if and only if (⟺) a == 0, 0 otherwise.
@(optimization_mode="none")
u64_is_zero :: proc "contextless" (a: u64) -> u64 {
	_, borrow := bits.sub_u64(a, 1, 0)
	return borrow
}

// u64_is_non_zero returns 1 if and only if (⟺) a != 0, 0 otherwise.
@(optimization_mode="none")
u64_is_non_zero :: proc "contextless" (a: u64) -> u64 {
	is_zero := u64_is_zero(a)
	return (~is_zero) & 1
}

@(optimization_mode="none")
cmov_bytes :: proc "contextless" (dst, src: []byte, ctrl: int) {
	s_len := len(src)
	ensure_contextless(s_len == len(dst), "crypto: cmov length mismatch")

	c := -(byte)(ctrl)
	for i in 0..<s_len {
		dst[i] ~= c & (dst[i] ~ src[i])
	}
}

@(optimization_mode="none")
csel_i16 :: proc "contextless" (a, b: i16, ctrl: int) -> i16 {
	c := -(u16)(ctrl)
	return a ~ i16(c & u16(a ~ b))
}

@(optimization_mode="none")
csel_u16 :: proc "contextless" (a, b: u16, ctrl: int) -> u16 {
	c := -(u16)(ctrl)
	return a ~ (c & (a ~ b))
}

csel_u32 :: proc "contextless" (a, b: u32, ctrl: int) -> u32 {
	return _fiat.cmovznz_u32(_fiat.u1(ctrl), a, b)
}

csel_u64 :: proc "contextless" (a, b: u64, ctrl: int) -> u64 {
	return _fiat.cmovznz_u64(_fiat.u1(ctrl), a, b)
}

csel :: proc {
	csel_i16,
	csel_u16,
	csel_u32,
	csel_u64,
}
