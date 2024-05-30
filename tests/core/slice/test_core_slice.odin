package test_core_slice

import "core:slice"
import "core:testing"
import "core:math/rand"

@test
test_sort_with_indices :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}

	for test_size in test_sizes {
		r := rand.create(t.seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i] = rand.uint64(&r)
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.init(&r, t.seed)

		for v, i in f_idx {
			r_idx[v] = i
		}

		last: u64
		for v, i in vals {
			if i > 0 {
				val_pass := v >= last
				testing.expect(t, val_pass, "Expected randomized test values to have been sorted")
				if !val_pass {
					break
				}
			}

			idx_pass := vals[r_idx[i]] == rand.uint64(&r)
			testing.expect(t, idx_pass, "Expected index to have been sorted")
			if !idx_pass {
				break
			}
			last = v
		}
	}
}

@test
test_sort_by_indices :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}

	for test_size in test_sizes {
		r := rand.create(t.seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i] = rand.uint64(&r)
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.init(&r, t.seed)

		{
			indices := make([]int, test_size)
			defer delete(indices)
			for _, i in indices {
				indices[i] = i
			}

			sorted_indices := slice.sort_by_indices(indices, f_idx)
			defer delete(sorted_indices)
			for v, i in sorted_indices {
				idx_pass := v == f_idx[i]
				testing.expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
				if !idx_pass {
					break
				}
			}
		}
		{
			indices := make([]int, test_size)
			defer delete(indices)
			for _, i in indices {
				indices[i] = i
			}

			slice.sort_by_indices_overwrite(indices, f_idx)
			for v, i in indices {
				idx_pass := v == f_idx[i]
				testing.expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
				if !idx_pass {
					break
				}
			}
		}
		{
			indices := make([]int, test_size)
			swap := make([]int, test_size)
			defer {
				delete(indices)
				delete(swap)
			}
			for _, i in indices {
				indices[i] = i
			}

			slice.sort_by_indices(indices, swap, f_idx)
			for v, i in swap {
				idx_pass := v == f_idx[i]
				testing.expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
				if !idx_pass {
					break
				}
			}
		}
	}
}

@test
test_binary_search :: proc(t: ^testing.T) {
	index: int
	found: bool

	s := []i32{0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55}

	index, found = slice.binary_search(s, 13)
	testing.expect(t, index == 9,    "Expected index to be 9")
	testing.expect(t, found == true, "Expected found to be true")

	index, found = slice.binary_search(s, 4)
	testing.expect(t, index == 7,     "Expected index to be 7.")
	testing.expect(t, found == false, "Expected found to be false.")

	index, found = slice.binary_search(s, 100)
	testing.expect(t, index == 13,    "Expected index to be 13.")
	testing.expect(t, found == false, "Expected found to be false.")

	index, found = slice.binary_search(s, 1)
	testing.expect(t, index >= 1 && index <= 4, "Expected index to be 1, 2, 3, or 4.")
	testing.expect(t, found == true, "Expected found to be true.")

	index, found = slice.binary_search(s, -1)
	testing.expect(t, index == 0,     "Expected index to be 0.")
	testing.expect(t, found == false, "Expected found to be false.")

	a := []i32{}

	index, found = slice.binary_search(a, 13)
	testing.expect(t, index == 0,     "Expected index to be 0.")
	testing.expect(t, found == false, "Expected found to be false.")

	b := []i32{1}

	index, found = slice.binary_search(b, 13)
	testing.expect(t, index == 1,     "Expected index to be 1.")
	testing.expect(t, found == false, "Expected found to be false.")

	index, found = slice.binary_search(b, 1)
	testing.expect(t, index == 0,    "Expected index to be 0.")
	testing.expect(t, found == true, "Expected found to be true.")

	index, found = slice.binary_search(b, 0)
	testing.expect(t, index == 0,     "Expected index to be 0.")
	testing.expect(t, found == false, "Expected found to be false.")
}