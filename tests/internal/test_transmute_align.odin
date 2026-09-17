package test_internal

import "core:testing"

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
