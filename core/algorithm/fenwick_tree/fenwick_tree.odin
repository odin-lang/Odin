// This package implements fenwick tree operations over a slice
package algorithm_fenwick_tree

// Reference(s): https://cp-algorithms.com/data_structures/fenwick.html

init_from_slice :: proc(tree: $S/[]$E, src: $A/[]E) {
	n := len(tree)
	for i := 0; i < n; i += 1 {
        tree[i] += src[i]
        r := i | (i + 1)
        if r < n {
        	tree[r] += tree[i]
        }
	}
}

add :: proc(tree: $S/[]$E, #any_int p: int, v: E) {
	p += 1;
	for p <= len(tree) {
		tree[p - 1] += v;
		p += p & -p;	
	}
}

sum :: proc(tree: $S/[]$E, #any_int r: int) {
	sum := 0
	for r > 0 {
		sum += tree[r - 1]
		r -= r & -r;
	}
	return sum
}

range_sum :: proc(tree: $S/[]$E, #any_int l: int, #any_int r: int) {
	return sum(tree, r) - sum(tree, l)
}
