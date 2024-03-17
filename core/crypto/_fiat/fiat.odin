package fiat

// This package provides various helpers and types common to all of the
// fiat-crypto derived backends.

// This code only works on a two's complement system.
#assert((-1 & 3) == 3)

u1 :: distinct u8
i1 :: distinct i8

@(optimization_mode = "none")
cmovznz_u64 :: proc "contextless" (arg1: u1, arg2, arg3: u64) -> (out1: u64) {
	x1 := (u64(arg1) * 0xffffffffffffffff)
	x2 := ((x1 & arg3) | ((~x1) & arg2))
	out1 = x2
	return
}

@(optimization_mode = "none")
cmovznz_u32 :: proc "contextless" (arg1: u1, arg2, arg3: u32) -> (out1: u32) {
	x1 := (u32(arg1) * 0xffffffff)
	x2 := ((x1 & arg3) | ((~x1) & arg2))
	out1 = x2
	return
}
