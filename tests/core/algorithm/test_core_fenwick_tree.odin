package test_core_algorithm

import "core:testing"
import "core:algorithm/fenwick_tree"

@(test)
test_fenwick_tree :: proc(t: ^testing.T) {
	tree := []int{1,2,3,4,5}
	fenwick_tree.init(tree)

}
