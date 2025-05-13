package test_core_algorithm

import "core:testing"
import "core:algorithm/fenwick_tree"

@(test)
test_fenwick_tree :: proc(t: ^testing.T) {
	tree := []int{3,1,4,1,5,9}
	fenwick_tree.init(tree)
	testing.expect_value(t, fenwick_tree.sum(tree, 3), 8)
	testing.expect_value(t, fenwick_tree.range_sum(tree, 0, 4), 9)
	fenwick_tree.add(tree, 2, 6)
	testing.expect_value(t, fenwick_tree.sum(tree, 4), 15)
	testing.expect_value(t, fenwick_tree.range_sum(tree, 2, 5), 16)
	fenwick_tree.add(tree, 5, -4)
	testing.expect_value(t, fenwick_tree.sum(tree, 6), 25)
	testing.expect_value(t, fenwick_tree.range_sum(tree, 1, 3), 11)
}
