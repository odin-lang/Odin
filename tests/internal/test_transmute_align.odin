package test_internal

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
