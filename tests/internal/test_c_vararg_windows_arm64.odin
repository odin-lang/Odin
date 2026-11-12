package test_internal

import "base:intrinsics"
import "core:c"
import "core:testing"

// Windows arm64 passes the composites of a variadic call as integers in general purpose registers or on the
// stack, never as homogeneous aggregates, and those over 16 bytes by reference.
// See `lbAbiArm64::windows_variadic_composite` and `lb_emit_windows_arm64_va_arg`.

C_Vararg_Hfa   :: struct { a, b: f32 }               // an HFA on other arm64 targets
C_Vararg_Odd   :: struct { a: u8, b: u16, c: u8 }    // 6 bytes
C_Vararg_Wide  :: struct { a: i128 }                 // 16 byte aligned
C_Vararg_Pair  :: struct { a: f64, b: i64 }          // 16 bytes
C_Vararg_Large :: struct { a: [5]i64 }               // over 16 bytes

C_Vararg_Composites :: struct {
	hfa:   C_Vararg_Hfa,
	odd:   C_Vararg_Odd,
	wide:  C_Vararg_Wide,
	pair:  C_Vararg_Pair,
	large: C_Vararg_Large,
	last:  f64,
}

c_vararg_read_composites :: proc "c" (out: ^C_Vararg_Composites, #c_vararg args: ..any) {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	out.hfa   = intrinsics.c_va_arg(&list, C_Vararg_Hfa)
	out.odd   = intrinsics.c_va_arg(&list, C_Vararg_Odd)
	out.wide  = intrinsics.c_va_arg(&list, C_Vararg_Wide)
	out.pair  = intrinsics.c_va_arg(&list, C_Vararg_Pair)
	out.large = intrinsics.c_va_arg(&list, C_Vararg_Large)
	out.last  = intrinsics.c_va_arg(&list, f64)
}

// A named HFA of a variadic procedure is passed in general purpose registers too.
c_vararg_named_hfa :: proc "c" (hfa: C_Vararg_Hfa, #c_vararg args: ..any) -> f64 {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	return f64(hfa.a) + f64(hfa.b) + intrinsics.c_va_arg(&list, f64)
}

@(test)
c_vararg_windows_arm64_composites :: proc(t: ^testing.T) {
	// `out` is in x0, then: hfa in x1, odd in x2, wide in x4 and x5 (skipping x3 to start in an even register),
	// pair in x6 and x7, and large (by reference) and last on the stack.
	v: C_Vararg_Composites
	large := C_Vararg_Large{{1, 2, 3, 4, 5}}
	c_vararg_read_composites(&v,
		C_Vararg_Hfa{1.5, -2.25},
		C_Vararg_Odd{0xab, 0xcdef, 0x12},
		C_Vararg_Wide{i128(1) << 100 | 7},
		C_Vararg_Pair{0.5, -9},
		large,
		f64(42),
	)
	testing.expect_value(t, v.hfa,   C_Vararg_Hfa{1.5, -2.25})
	testing.expect_value(t, v.odd,   C_Vararg_Odd{0xab, 0xcdef, 0x12})
	testing.expect_value(t, v.wide,  C_Vararg_Wide{i128(1) << 100 | 7})
	testing.expect_value(t, v.pair,  C_Vararg_Pair{0.5, -9})
	testing.expect_value(t, v.large, large)
	testing.expect_value(t, v.last,  f64(42))

	testing.expect_value(t, c_vararg_named_hfa(C_Vararg_Hfa{1, 2}, f64(4)), f64(7))
}

C_Vararg_V4 :: #simd[4]f32
C_Vararg_V2 :: #simd[2]f32

C_Vararg_Vectors :: struct {
	v2:   C_Vararg_V2,
	v4:   C_Vararg_V4,
	last: i64,
}

c_vararg_read_vectors :: proc "c" (out: ^C_Vararg_Vectors, #c_vararg args: ..any) {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	out.v2   = intrinsics.c_va_arg(&list, C_Vararg_V2)
	out.v4   = intrinsics.c_va_arg(&list, C_Vararg_V4)
	out.last = intrinsics.c_va_arg(&list, i64)
}

// A named vector of a variadic procedure is passed in general purpose registers too.
c_vararg_named_vector :: proc "c" (v: C_Vararg_V4, #c_vararg args: ..any) -> i64 {
	list: c.va_list
	intrinsics.c_va_start(&list, args)
	defer intrinsics.c_va_end(&list)
	return i64(intrinsics.simd_reduce_add_ordered(v)) + intrinsics.c_va_arg(&list, i64)
}

@(test)
c_vararg_windows_arm64_vectors :: proc(t: ^testing.T) {
	// No SIMD register is used: `out` is in x0, then v2 in x1, v4 in x2 and x3 (as a 16 byte aligned
	// composite), and last in x4.
	v: C_Vararg_Vectors
	c_vararg_read_vectors(&v, C_Vararg_V2{5, 6}, C_Vararg_V4{1, 2, 3, 4}, i64(77))
	testing.expect_value(t, v.v2,   C_Vararg_V2{5, 6})
	testing.expect_value(t, v.v4,   C_Vararg_V4{1, 2, 3, 4})
	testing.expect_value(t, v.last, i64(77))

	testing.expect_value(t, c_vararg_named_vector(C_Vararg_V4{1, 2, 3, 4}, i64(5)), i64(15))
}
