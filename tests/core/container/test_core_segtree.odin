package test_core_container

import "core:testing"
import "core:container/segtree"

add_ints :: proc "contextless" (x, y: int) -> int { 
	return x + y 
}

mul_f64s :: proc "contextless" (x,y: f64) -> f64 { 
	return x * y
}

/*
@test
test_segtree_bit_ceil :: proc(t: ^testing.T) {
	testing.expect_value(t, segtree._bit_ceil(1<<32+1), 1<<33)
	testing.expect_value(t, segtree._bit_ceil(29), 32)
	testing.expect_value(t, segtree._bit_ceil(-1), 1)
}*/


@test
test_segtree_prod_all_int_sum :: proc(t: ^testing.T) {
	tree: segtree.Segtree(int)
	segtree.init(&tree, 1, add_ints, 10)
	defer segtree.destroy(&tree)
	sum := segtree.prod_all(&tree)
	testing.expect_value(t, sum, 10)
}

@test
test_segtree_prod_all_f64_mul :: proc(t: ^testing.T) {
	tree: segtree.Segtree(f64)
	id := 1.0
	slice := []f64{1,2,3,4,5,6,7,8}
	segtree.init_from_slice(&tree, id, mul_f64s, slice)
	defer segtree.destroy(&tree)
	fact := segtree.prod_all(&tree)
	testing.expect_value(t, fact, 40320.0)
}

@test
test_segtree_max_right :: proc(t: ^testing.T) {
	tree: segtree.Segtree(int)
	slice := []int{2,1,3,4,2,1}
	segtree.init_from_slice(&tree, 1, add_ints, slice)
	defer segtree.destroy(&tree)
	f :: proc "contextless" (x: int) -> bool {
		return x <= 7
	}
	v := segtree.max_right(&tree, 1, f)
	testing.expect_value(t, v, 3)
}

@test
test_segtree_min_left :: proc(t: ^testing.T) {
	tree: segtree.Segtree(int)
	slice := []int{5,2,7,1,3,6}
	segtree.init_from_slice(&tree, 1, add_ints, slice)
	defer segtree.destroy(&tree)
	f :: proc "contextless" (x: int) -> bool {
		return x <= 10
	}
	v := segtree.min_left(&tree, 6, f)
	testing.expect_value(t, v, 4)
}
