package test_core_sort

import "core:sort"
import "core:testing"

@test
test_compare_ints :: proc(t: ^testing.T) {
	values := [?]int{min(int), min(int) + 1, -1, 0, 1, max(int) - 1, max(int)}
	for a, i in values {
		for b, j in values {
			expected := 0
			if i < j {
				expected = -1
			} else if i > j {
				expected = 1
			}
			testing.expect_value(t, sort.compare_ints(a, b), expected)
		}
	}
}
