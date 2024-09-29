package test_core_slice

import "core:slice"
import "core:testing"
import "core:math/rand"
import "core:log"

@test
test_sort_with_indices :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}

	for test_size in test_sizes {
		rand.reset(t.seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i] = rand.uint64()
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.reset(t.seed)

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

			idx_pass := vals[r_idx[i]] == rand.uint64()
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
		rand.reset(t.seed)

		vals  := make([]u64, test_size)
		r_idx := make([]int, test_size) // Reverse index
		defer {
			delete(vals)
			delete(r_idx)
		}

		// Set up test values
		for _, i in vals {
			vals[i] = rand.uint64()
		}

		// Sort
		f_idx := slice.sort_with_indices(vals)
		defer delete(f_idx)

		// Verify sorted test values
		rand.reset(t.seed)

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

@test
test_permutation_iterator :: proc(t: ^testing.T) {
	// Big enough to do some sanity checking but not overly large.
	FAC_5 :: 120
	s := []int{1, 2, 3, 4, 5}
	seen: map[int]bool
	defer delete(seen)

	iter := slice.make_permutation_iterator(s)
	defer slice.destroy_permutation_iterator(iter)

	permutations_counted: int
	for slice.permute(&iter) {
		n := 0
		for item in s {
			n *= 10
			n += item
		}
		if n in seen {
			log.error("Permutation iterator made a duplicate permutation.")
			return
		}
		seen[n] = true
		permutations_counted += 1
	}

	testing.expect_value(t, len(seen), FAC_5)
	testing.expect_value(t, permutations_counted, FAC_5)
}

// Test inputs from #3276 and #3769
UNIQUE_TEST_VECTORS :: [][2][]int{
	{{2,2,2},             {2}},
	{{1,1,1,2,2,3,3,3,3}, {1,2,3}},
	{{1,2,4,4,5},         {1,2,4,5}},
}

@test
test_unique :: proc(t: ^testing.T) {
	for v in UNIQUE_TEST_VECTORS {
		assorted := v[0]
		expected := v[1]

		uniq := slice.unique(assorted)
		testing.expectf(t, slice.equal(uniq, expected), "Expected slice.uniq(%v) == %v, got %v", v[0], v[1], uniq)
	}

	for v in UNIQUE_TEST_VECTORS {
		assorted := v[0]
		expected := v[1]

		uniq := slice.unique_proc(assorted, proc(a, b: int) -> bool {
			return a == b
		})
		testing.expectf(t, slice.equal(uniq, expected), "Expected slice.unique_proc(%v, ...) == %v, got %v", v[0], v[1], uniq)
	}

	r := rand.create(t.seed)
	context.random_generator = rand.default_random_generator(&r)

	// 10_000 random tests
	for _ in 0..<10_000 {
		assorted: [dynamic]i64
		expected: [dynamic]i64

		// Prime with 1 value
		old := rand.int63()
		append(&assorted, old)
		append(&expected, old)

		// Add 99 additional random values
		for _ in 1..<100 {
			new := rand.int63()
			append(&assorted, new)
			if old != new {
				append(&expected, new)
			}
			old = new
		}

		original := slice.clone(assorted[:])
		uniq := slice.unique(assorted[:])
		testing.expectf(t, slice.equal(uniq, expected[:]), "Expected slice.uniq(%v) == %v, got %v", original, expected, uniq)

		delete(assorted)
		delete(original)
		delete(expected)
	}
}

@test
test_compare_empty :: proc(t: ^testing.T) {
	a := []int{}
	b := []int{}
	c: [dynamic]int = { 0 }
	d: [dynamic]int = { 1 }
	clear(&c)
	clear(&d)
	defer {
		delete(c)
		delete(d)
	}

	testing.expectf(t, len(a) == 0,
		"Expected length of slice `a` to be zero")
	testing.expectf(t, len(c) == 0,
		"Expected length of dynamic array `c` to be zero")
	testing.expectf(t, len(d) == 0,
		"Expected length of dynamic array `d` to be zero")

	testing.expectf(t, slice.equal(a, a),
		"Expected empty slice to be equal to itself")
	testing.expectf(t, slice.equal(a, b),
		"Expected two different but empty stack-based slices to be equivalent")
	testing.expectf(t, slice.equal(a, c[:]),
		"Expected empty slice to be equal to slice of empty dynamic array")
	testing.expectf(t, slice.equal(c[:], d[:]),
		"Expected two separate empty slices of two dynamic arrays to be equal")
}

@test
test_linear_search_reverse :: proc(t: ^testing.T) {
	index: int
	found: bool

	s := []i32{0, 50, 50, 100}

	index, found = slice.linear_search_reverse(s, 100)
	testing.expect(t, found)
	testing.expect_value(t, index, len(s) - 1)

	index, found = slice.linear_search_reverse(s[len(s) - 1:], 100)
	testing.expect(t, found)
	testing.expect_value(t, index, 0)

	index, found = slice.linear_search_reverse(s, 50)
	testing.expect(t, found)
	testing.expect_value(t, index, 2)

	index, found = slice.linear_search_reverse(s, 0)
	testing.expect(t, found)
	testing.expect_value(t, index, 0)

	index, found = slice.linear_search_reverse(s, -1)
	testing.expect(t, !found)

	less_than_80 :: proc(x: i32) -> bool {
		return x < 80
	}

	index, found = slice.linear_search_reverse_proc(s, less_than_80)
	testing.expect(t, found)
	testing.expect_value(t, index, 2)
}
