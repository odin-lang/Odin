package test_core_slice

import "core:slice"
import "core:testing"
import "core:fmt"
import "core:os"
import "core:math/rand"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}
	test_sort_with_indices(&t)
	test_binary_search(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

@test
test_sort_with_indices :: proc(t: ^testing.T) {
	seed := rand.uint64()
	fmt.printf("Random seed: %v\n", seed)

	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}

	for test_size in test_sizes {
		fmt.printf("Sorting %v random u64 values along with index.\n", test_size)

		r := rand.create(seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i]     = rand.uint64(&r)
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.init(&r, seed)

		for v, i in f_idx {
			r_idx[v] = i
		}

		last: u64
		for v, i in vals {
			if i > 0 {
				val_pass := v >= last
				expect(t, val_pass, "Expected values to have been sorted.")
				if !val_pass {
					break
				}
			}

			idx_pass := vals[r_idx[i]] == rand.uint64(&r)
			expect(t, idx_pass, "Expected index to have been sorted.")
			if !idx_pass {
				break
			}
			last = v
		}
	}
}

@test
test_sort_by_indices :: proc(t: ^testing.T) {
	seed := rand.uint64()
	fmt.printf("Random seed: %v\n", seed)

	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}

	for test_size in test_sizes {
		fmt.printf("Sorting %v random u64 values along with index.\n", test_size)

		r := rand.create(seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i]     = rand.uint64(&r)
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.init(&r, seed)

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
				expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
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
				expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
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
				expect(t, idx_pass, "Expected the sorted index to be the same as the result from sort_with_indices")
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

    test_search :: proc(s: []i32, v: i32) -> (int, bool) {
		fmt.printf("Searching for %v in %v\n", v, s)
		index, found := slice.binary_search(s, v)
		fmt.printf("index: %v\nfound: %v\n", index, found)

		return index, found
    }

    s := []i32{0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55}

	index, found = test_search(s, 13)
	assert(index == 9, "Expected index to be 9.")
	assert(found == true, "Expected found to be true.")

	index, found = test_search(s, 4)
	assert(index == 7, "Expected index to be 7.")
	assert(found == false, "Expected found to be false.")

	index, found = test_search(s, 100)
	assert(index == 13, "Expected index to be 13.")
	assert(found == false, "Expected found to be false.")

	index, found = test_search(s, 1)
	assert(index >= 1 && index <= 4, "Expected index to be 1, 2, 3, or 4.")
	assert(found == true, "Expected found to be true.")

	index, found = test_search(s, -1)
	assert(index == 0, "Expected index to be 0.")
	assert(found == false, "Expected found to be false.")

	a := []i32{}

	index, found = test_search(a, 13)
	assert(index == 0, "Expected index to be 0.")
	assert(found == false, "Expected found to be false.")

	b := []i32{1}

	index, found = test_search(b, 13)
	assert(index == 1, "Expected index to be 1.")
	assert(found == false, "Expected found to be false.")

	index, found = test_search(b, 1)
	assert(index == 0, "Expected index to be 0.")
	assert(found == true, "Expected found to be true.")

	index, found = test_search(b, 0)
	assert(index == 0, "Expected index to be 0.")
	assert(found == false, "Expected found to be false.")
}
