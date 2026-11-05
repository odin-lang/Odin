package test_internal

import "base:intrinsics"
import "core:c"
import "core:testing"

C_Vararg_Flags :: bit_set[0..<8; u8]

C_Vararg_Values :: struct {
	f:  f32,
	h:  f16,
	d:  f64,
	i8_: i8,
	u8_: u8,
	i16_: i16,
	u16_: u16,
	b:  bool,
	bs: C_Vararg_Flags,
	i:  i64,
}

// Reads the arguments back as their own types, after the caller promoted them like C.
c_vararg_read :: proc "c" (out: ^C_Vararg_Values, #c_vararg args: ..any) {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	out.f    = intrinsics.c_va_arg(&list, f32)
	out.h    = intrinsics.c_va_arg(&list, f16)
	out.d    = intrinsics.c_va_arg(&list, f64)
	out.i8_  = intrinsics.c_va_arg(&list, i8)
	out.u8_  = intrinsics.c_va_arg(&list, u8)
	out.i16_ = intrinsics.c_va_arg(&list, i16)
	out.u16_ = intrinsics.c_va_arg(&list, u16)
	out.b    = intrinsics.c_va_arg(&list, bool)
	out.bs   = intrinsics.c_va_arg(&list, C_Vararg_Flags)
	out.i    = intrinsics.c_va_arg(&list, i64)
}

@(test)
c_vararg_promoted_arguments :: proc(t: ^testing.T) {
	v: C_Vararg_Values
	c_vararg_read(&v, f32(2.25), f16(-1.5), f64(0.125), i8(-3), u8(200), i16(-30000), u16(60000), true, C_Vararg_Flags{1, 7}, i64(1) << 40)
	testing.expect_value(t, v.f, 2.25)
	testing.expect_value(t, v.h, -1.5)
	testing.expect_value(t, v.d, 0.125)
	testing.expect_value(t, v.i8_, -3)
	testing.expect_value(t, v.u8_, 200)
	testing.expect_value(t, v.i16_, -30000)
	testing.expect_value(t, v.u16_, 60000)
	testing.expect_value(t, v.b, true)
	testing.expect_value(t, v.bs, C_Vararg_Flags{1, 7})
	testing.expect_value(t, v.i, i64(1) << 40)
}

C_Vararg_Many :: struct {
	ints:   [10]i64,
	floats: [10]f64,
	p:      rawptr,
}

// More arguments than any target passes in registers, so the rest come from the stack.
c_vararg_read_many :: proc "c" (out: ^C_Vararg_Many, #c_vararg args: ..any) {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	for i in 0..<10 {
		out.ints[i]   = intrinsics.c_va_arg(&list, i64)
		out.floats[i] = intrinsics.c_va_arg(&list, f64)
	}
	out.p = intrinsics.c_va_arg(&list, rawptr)
}

@(test)
c_vararg_stack_arguments :: proc(t: ^testing.T) {
	v: C_Vararg_Many
	marker: int
	c_vararg_read_many(&v,
		i64(1), 1.5, i64(2), 2.5, i64(3), 3.5, i64(4), 4.5, i64(5), 5.5,
		i64(6), 6.5, i64(7), 7.5, i64(8), 8.5, i64(9), 9.5, i64(10), 10.5,
		&marker,
	)
	for i in 0..<10 {
		testing.expect_value(t, v.ints[i], i64(i+1))
		testing.expect_value(t, v.floats[i], f64(i+1) + 0.5)
	}
	testing.expect_value(t, v.p, rawptr(&marker))
}
