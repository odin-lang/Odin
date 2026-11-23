package test_internal

import "base:intrinsics"
import "core:testing"

// A part of a volatile, non-temporal, or atomic load is taken from the loaded value.
// Reading it again through the pointer would be a second, plain access.

@(private="file")
Pair :: struct {
	a, b: u32,
}

@(private="file")
Big :: struct {
	x:   [32]u32,
	tag: u32,
}

@(private="file")
make_big :: proc() -> (b: Big) {
	for &v, i in b.x {
		v = u32(i)*3 + 1
	}
	b.tag = 7
	return
}

@(test)
test_volatile_load_selector :: proc(t: ^testing.T) {
	pair := Pair{1, 2}
	testing.expect_value(t, intrinsics.volatile_load(&pair).a,     1)
	testing.expect_value(t, intrinsics.volatile_load(&pair).b,     2)
	testing.expect_value(t, intrinsics.non_temporal_load(&pair).b, 2)

	arr := [4]u32{10, 20, 30, 40}
	i := 3
	testing.expect_value(t, intrinsics.volatile_load(&arr)[2],     30)
	testing.expect_value(t, intrinsics.volatile_load(&arr)[i],     40)
	testing.expect_value(t, intrinsics.non_temporal_load(&arr)[1], 20)

	big := make_big()
	testing.expect_value(t, intrinsics.volatile_load(&big).x[7], 22)
	testing.expect_value(t, intrinsics.volatile_load(&big).tag,  7)

	str := "hello"
	testing.expect_value(t, len(intrinsics.volatile_load(&str)), 5)

	c: complex64 = 3 + 4i
	testing.expect_value(t, real(intrinsics.volatile_load(&c)), 3)
	testing.expect_value(t, imag(intrinsics.volatile_load(&c)), 4)

	v := [4]f32{1, 2, 3, 4}
	testing.expect_value(t, intrinsics.volatile_load(&v).zw, [2]f32{3, 4})
}

@(private="file")
load_big :: #force_no_inline proc(p: ^Big) -> Big {
	return intrinsics.volatile_load(p)
}

@(test)
test_volatile_load_whole_value :: proc(t: ^testing.T) {
	big := make_big()
	copy: Big
	copy = intrinsics.volatile_load(&big)
	testing.expect_value(t, copy, big)
	testing.expect_value(t, load_big(&big), big)

	a := [4]f32{1, 2, 3, 4}
	b := [4]f32{10, 20, 30, 40}
	testing.expect_value(t, intrinsics.volatile_load(&a) + intrinsics.volatile_load(&b), [4]f32{11, 22, 33, 44})

	m := matrix[4, 4]f32{
		1, 0, 0, 1,
		0, 2, 0, 0,
		0, 0, 3, 0,
		1, 0, 0, 4,
	}
	testing.expect_value(t, m * intrinsics.volatile_load(&a), [4]f32{5, 4, 9, 17})
}

@(private="file")
write_then_read_pair :: #force_no_inline proc(p: ^Pair, x: any) -> Pair {
	p.a = 99
	return (^Pair)(x.data)^
}

@(private="file")
write_then_read_u64 :: #force_no_inline proc(p: ^u64, x: any) -> u64 {
	p^ = 99
	return (^u64)(x.data)^
}

@(private="file")
box_volatile_load :: #force_no_inline proc(p: ^Pair) -> Pair {
	return write_then_read_pair(p, intrinsics.volatile_load(p))
}

@(private="file")
box_non_temporal_load :: #force_no_inline proc(p: ^Pair) -> Pair {
	return write_then_read_pair(p, intrinsics.non_temporal_load(p))
}

@(private="file")
box_atomic_load :: #force_no_inline proc(p: ^u64) -> u64 {
	return write_then_read_u64(p, intrinsics.atomic_load(p))
}

// An `any` holds the value that was loaded, not the place it was loaded from
@(test)
test_volatile_load_in_any :: proc(t: ^testing.T) {
	pair := Pair{1, 2}
	testing.expect_value(t, box_volatile_load(&pair), Pair{1, 2})
	pair = {1, 2}
	testing.expect_value(t, box_non_temporal_load(&pair), Pair{1, 2})
	n: u64 = 1
	testing.expect_value(t, box_atomic_load(&n), 1)
}

@(private="file", deferred_in=end_scope_big)
begin_scope_big :: #force_no_inline proc(seen: ^u32, big: Big) {}

@(private="file")
end_scope_big :: #force_no_inline proc(seen: ^u32, big: Big) {
	seen^ = big.tag
}

@(test)
test_volatile_load_deferred_in :: proc(t: ^testing.T) {
	seen: u32
	big := make_big()
	{
		begin_scope_big(&seen, intrinsics.volatile_load(&big))
		big.tag = 8
	}
	testing.expect_value(t, seen, 7)
}

// A non-temporal store of an aggregate stays whole rather than being split into plain stores
@(test)
test_non_temporal_store_aggregate :: proc(t: ^testing.T) {
	a, b := u32(1), u32(2)
	pair: Pair
	intrinsics.non_temporal_store(&pair, Pair{a, b})
	testing.expect_value(t, pair, Pair{1, 2})

	arr: [4]u64
	n := u64(5)
	intrinsics.non_temporal_store(&arr, [4]u64{n, n + 1, n + 2, n + 3})
	testing.expect_value(t, arr, [4]u64{5, 6, 7, 8})

	src := make_big()
	dst: Big
	intrinsics.non_temporal_store(&dst, src)
	testing.expect_value(t, dst, src)

	intrinsics.non_temporal_store(&dst, Big{tag = 9})
	testing.expect_value(t, dst, Big{tag = 9})
}
