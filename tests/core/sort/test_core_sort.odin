package test_core_sort

import "core:math/rand"
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
@test
test_interface_sort_stability :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}
	Data :: struct {
		rand: int,
		index: int,
	}

	for test_size in test_sizes {
		rand.reset(t.seed)

		vals  := make([]Data, test_size)
		defer delete(vals)

		// Set up test values
		for &val, i in vals {
			val = {rand.int_max(test_size / 2), i}
		}

		it := sort.Interface {
			collection = rawptr(&vals),
			len = proc(it: sort.Interface) -> int {
				s := (^[]Data)(it.collection)
				return len(s^)
			},
			less = proc(it: sort.Interface, i, j: int) -> bool {
				s := (^[]Data)(it.collection)
				return s[i].rand < s[j].rand
			},
			swap = proc(it: sort.Interface, i, j: int) {
				s := (^[]Data)(it.collection)
				s[i], s[j] = s[j], s[i]
			},
		}

		// Sort
		sort.sort_stable(it)

		// Verify sorted test values
		rand.reset(t.seed)

		sum := vals[0].index
		for i in 1..<len(vals) {
			sum += vals[i].index
			if vals[i - 1].rand > vals[i].rand {
				testing.expect(t, false, "Expected slice to be sorted")
			}
			if vals[i - 1].rand < vals[i].rand {
				continue
			}
			if vals[i - 1].index > vals[i].index {
				testing.expect(t, false, "Expected slice to be stable")
			}
		}

		testing.expect(t, sum == test_size * (test_size - 1) / 2, "Expected slice to have all indecies")

	}
}
