package test_internal

import "base:intrinsics"
import "core:testing"

@(test)
transmute_array_like_to_simd_and_u128 :: proc(t: ^testing.T) {
	Named_Lane :: enum { A, B, C, D }
	Item :: struct {
		tag: u32,
		arr: [4]f32,     		// offs 4
		e:   [Named_Lane]u32,	// offs 20
		w:   [2]u64,
	}

	items := make([]Item, 2)
	defer delete(items)
	items[0] = {1, {1, 2, 3, 4}, {.A = 5, .B = 6, .C = 7, .D = 8}, {9, 10}}
	it := &items[0]
	testing.expect_value(t, transmute([4]f32)transmute(#simd[4]f32)it.arr, [4]f32{1, 2, 3, 4})
	testing.expect_value(t, transmute([4]u32)transmute(#simd[4]u32)it.e, [4]u32{5, 6, 7, 8})
	testing.expect_value(t, transmute(u128)it.e, u128(8)<<96 | u128(7)<<64 | u128(6)<<32 | 5)
	testing.expect_value(t, transmute(u128)it.w, u128(10)<<64 | 9)

	bytes: [32]u8
	for &b, i in bytes {
		b = u8(i)
	}
	odd := (^[16]u8)(&bytes[1])
	testing.expect_value(t, transmute(u128)odd^, u128(0x10_0f_0e_0d_0c_0b_0a_09_08_07_06_05_04_03_02_01))

	local := [4]f32{1, 2, 3, 4}
	testing.expect_value(t, transmute([4]f32)transmute(#simd[4]f32)local, [4]f32{1, 2, 3, 4})
	local_e := [Named_Lane]u32{.A = 1, .B = 2, .C = 3, .D = 4}
	testing.expect_value(t, transmute(u128)local_e, u128(4)<<96 | u128(3)<<64 | u128(2)<<32 | 1)
}

Helper :: struct #min_field_align(16) {
	p: ^[4]f32,  // align 16 for the storage of the pointer
}

@(export)
transmute_pointed_array :: #force_no_inline proc (s: ^Helper) -> #simd[4]f32 {
	return transmute(#simd[4]f32)s.p^
}

@(test)
transmute_through_aligned_pointer_storage :: proc(t: ^testing.T) {
	arr := [8]f32{0, 1, 2, 3, 4, 5, 6, 7}
	s := Helper{p = (^[4]f32)(&arr[1])}  // [4]f32 and arr[1] are both align 4

	v := transmute_pointed_array(&s)
	testing.expect_value(t, transmute([4]f32)v, [4]f32{1, 2, 3, 4})
}

@(test)
transmute_from_less_aligned_src :: proc(t: ^testing.T) {
	Vec4 :: struct { x, y, z, w: f32 }	// align 4
	P :: struct { id: u32, pos: Vec4 }  // pos at offs 4

	ps := make([]P, 4)
	defer delete(ps)
	for &p, i in ps {
		p = {u32(i), {f32(i), 1, 2, 3}}
	}
	sum: #simd[4]f32
	for &p in ps {
		sum += transmute(#simd[4]f32)p.pos
	}
	testing.expect_value(t, transmute([4]f32)sum, [4]f32{6, 4, 8, 12})

	H :: struct { lo, hi: u64 }       // align 8
	Rec :: struct { a: u64, h: H }  // h at offs 8
	r := Rec{1, {3, 5}}
	testing.expect_value(t, transmute(u128)r.h, u128(5)<<64 | 3)

	bytes: [16]u8
	for &b, i in bytes {
		b = u8(i)
	}
	odd := (^[8]u8)(&bytes[1])
	testing.expect_value(t, transmute(u64)odd^, u64(0x08_07_06_05_04_03_02_01))
}

Transmute_Vec4 :: struct { x, y, z, w: f32 }  // align 4
Transmute_H    :: struct { lo, hi: u64 }      // align 8

@(export)
transmute_struct_to_simd :: #force_no_inline proc (v: ^Transmute_Vec4) -> #simd[4]f32 {
	return transmute(#simd[4]f32)v^
}

@(export)
transmute_struct_to_u128 :: #force_no_inline proc (h: ^Transmute_H) -> u128 {
	return transmute(u128)h^
}

@(export)
transmute_bytes_to_u64 :: #force_no_inline proc (p: ^[8]u8) -> u64 {
	return transmute(u64)p^
}

@(test)
transmute_from_less_aligned_ptr :: proc(t: ^testing.T) {
	@(align=16) buf: [64]u8

	v := (^Transmute_Vec4)(&buf[4])  // only 4 aligned
	v^ = {0, 1, 2, 3}
	testing.expect_value(t, transmute([4]f32)transmute(#simd[4]f32)v^, [4]f32{0, 1, 2, 3})
	testing.expect_value(t, transmute([4]f32)transmute_struct_to_simd(v), [4]f32{0, 1, 2, 3})

	h := (^Transmute_H)(&buf[8])  // only 8 aligned
	h^ = {3, 5}
	testing.expect_value(t, transmute(u128)h^, u128(5)<<64 | 3)
	testing.expect_value(t, transmute_struct_to_u128(h), u128(5)<<64 | 3)

	odd := (^[8]u8)(&buf[1])  // only 1 aligned
	odd^ = {1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, transmute_bytes_to_u64(odd), u64(0x08_07_06_05_04_03_02_01))
}

Transmute_Wide :: struct { lo, hi: u128 }  // align 16

@(export)
transmute_wide_array_param :: #force_no_inline proc (w: [2]u128) -> u128 {
	return w[0] ~ w[1]
}

@(export)
transmute_wide_struct_param :: #force_no_inline proc (w: Transmute_Wide) -> u128 {
	return w.lo ~ w.hi
}

@(export)
transmute_wide_simd_param :: #force_no_inline proc (v: [2]#simd[4]f32) -> #simd[4]f32 {
	return v[0] + v[1]
}

@(export)
transmute_wide_any_param :: #force_no_inline proc (a: any) -> u128 {
	w := (^[2]u128)(a.data)^
	return w[0] ~ w[1]
}

// The result of a transmute from a less aligned pointer is passed by pointer or put in an `any`.
// That pointer must be aligned for the result type.
@(test)
transmute_from_less_aligned_ptr_as_parameter :: proc(t: ^testing.T) {
	@(align=16) buf: [64]u8

	p := (^[4]u64)(&buf[8])  // only 8 aligned
	p^ = {1, 2, 3, 4}
	want := u128(2 ~ 4)<<64 | u128(1 ~ 3)
	testing.expect_value(t, transmute_wide_array_param(transmute([2]u128)p^), want)
	testing.expect_value(t, transmute_wide_struct_param(transmute(Transmute_Wide)p^), want)
	testing.expect_value(t, transmute_wide_any_param(transmute([2]u128)p^), want)

	f := (^[8]f32)(&buf[4])  // only 4 aligned
	f^ = {1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, transmute([4]f32)transmute_wide_simd_param(transmute([2]#simd[4]f32)f^), [4]f32{6, 8, 10, 12})
}

@(export)
transmute_unaligned_halves :: #force_no_inline proc (p: ^#simd[8]f32) -> #simd[4]f32 {
	x := transmute([2]#simd[4]f32)intrinsics.unaligned_load(p)
	return x[0] + x[1]
}

@(export)
unaligned_simd_from_any :: #force_no_inline proc (a: any) -> #simd[8]f32 {
	return (^#simd[8]f32)(a.data)^
}

// The result of `intrinsics.unaligned_load` is transmuted or put in an `any`.
// Neither may assume the pointer it was loaded from is aligned.
@(test)
transmute_unaligned_load :: proc(t: ^testing.T) {
	@(align=32) buf: [64]u8

	p := (^#simd[8]f32)(&buf[4])  // only 4 aligned
	(^[8]f32)(p)^ = {1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, transmute([4]f32)transmute_unaligned_halves(p), [4]f32{6, 8, 10, 12})
	testing.expect_value(t, transmute([8]f32)unaligned_simd_from_any(intrinsics.unaligned_load(p)), [8]f32{1, 2, 3, 4, 5, 6, 7, 8})
}
