// This package implements fenwick tree operations over a slice
package algorithm_fenwick_tree

import "base:intrinsics"

// Reference(s): https://cp-algorithms.com/data_structures/fenwick.html

init :: proc(tree: $S/[]$E)
	where intrinsics.type_is_numeric(E) {

	n := len(tree)
	for i := 0; i < n; i += 1 {
        r := i | (i + 1)
        if r < n {
        	tree[r] += tree[i]
        }
	}
}

add :: proc(tree: $S/[]$E, #any_int p: int, v: E)
	where intrinsics.type_is_numeric(E) {

	x := p + 1
	for p <= len(tree) {
		tree[x - 1] += v
		x += x & -x;
	}
}

sum :: proc(tree: $S/[]$E, #any_int r: int) -> E
	where intrinsics.type_is_numeric(E) {

	sum := 0
	ptr := r
	for ptr > 0 {
		sum += tree[r - 1]
		ptr -= ptr & -ptr
	}
	return sum
}

range_sum :: proc(tree: $S/[]$E, #any_int l: int, #any_int r: int) -> E
	where intrinsics.type_is_numeric(E) {

	return sum(tree, r) - sum(tree, l)
}
