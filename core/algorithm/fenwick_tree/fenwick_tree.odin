// This package implements fenwick tree operations over a slice
package algorithm_fenwick_tree

add :: proc(tree: $Slice_Type/[]$Elem_Type, p: int, v: Elem_Type)  {
	p += 1;
	for p <= len(tree) {
		tree[p - 1] += v;
		p += p & -p;	
	}
}

sum :: proc(tree: $Slice_Type/[]$Elem_Type, r: int)  {
	sum := 0
	for r > 0 {
		sum += tree[r - 1]
		r -= r & -r;
	}
	return sum
}

range_sum :: proc(tree: $Slice_Type/[]$Elem_Type, l: int, r: int)  {
	return sum(tree, r) - sum(tree, l)
}

