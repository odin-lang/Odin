#+feature dynamic-literals
package test_core_slice

import "core:slice"
import "core:testing"
import "core:math/rand"
import "core:log"
import "core:mem"
import "base:runtime"

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
test_sort_stability :: proc(t: ^testing.T) {
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
			val = {rand.int_max(10), i}
		}

		// Sort
		slice.stable_sort_by(vals, proc(l, r: Data) -> bool {return l.rand < r.rand})

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

@test
test_non_zero_allocating_procs :: proc(t: ^testing.T) {
	// wraps an allocator and fills all new memory with 0xAA to catch non-written elements
	poison_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
		parent := (^runtime.Allocator)(data)
		res, err := parent.procedure(parent.data, mode, size, alignment, old_memory, old_size, loc)
		if err == nil && res != nil {
			#partial switch mode {
			case .Alloc, .Alloc_Non_Zeroed:
				mem.set(raw_data(res), 0xAA, size)
			case .Resize, .Resize_Non_Zeroed:
				if size > old_size {
					mem.set(&res[old_size], 0xAA, size - old_size)
				}
			}
		}
		return res, err
	}

	parent := context.allocator
	context.allocator = runtime.Allocator{poison_allocator_proc, &parent}

	a := []int{1, 2, 3, 4, 5}

	concatenated := slice.concatenate([][]int{a[:2], {}, a[2:]})
	defer delete(concatenated)
	testing.expect(t, slice.equal(concatenated, a))

	cloned := slice.clone(a)
	defer delete(cloned)
	testing.expect(t, slice.equal(cloned, a))

	dyn := slice.clone_to_dynamic(a)
	defer delete(dyn)
	testing.expect_value(t, len(dyn), len(a))
	testing.expect(t, slice.equal(dyn[:], a))

	mapped := slice.mapper(a, proc(x: int) -> int { return x * 10 })
	defer delete(mapped)
	testing.expect(t, slice.equal(mapped, []int{10, 20, 30, 40, 50}))

	scanned := slice.scanner(a, 0, proc(acc, x: int) -> int { return acc + x })
	defer delete(scanned)
	testing.expect(t, slice.equal(scanned, []int{1, 3, 6, 10, 15}))

	repeated := slice.repeat(a[:3], 3)
	defer delete(repeated)
	testing.expect(t, slice.equal(repeated, []int{1, 2, 3, 1, 2, 3, 1, 2, 3}))

	E :: enum{A, B, C, D}
	enums := slice.bitset_to_enum_slice(bit_set[E]{.B, .D}, E)
	defer delete(enums)
	testing.expect(t, slice.equal(enums, []E{.B, .D}))

	reversed := slice.sort_by_indices(a, []int{4, 3, 2, 1, 0})
	defer delete(reversed)
	testing.expect(t, slice.equal(reversed, []int{5, 4, 3, 2, 1}))

	slice.sort_by_indices_overwrite(cloned, []int{4, 3, 2, 1, 0})
	testing.expect(t, slice.equal(cloned, []int{5, 4, 3, 2, 1}))

	// large enough so that filter() grows its dynamic array
	big := make([]int, 1000)
	defer delete(big)
	for &v, i in big {
		v = i
	}
	is_multiple_of_3 :: proc(x: int) -> bool { return x % 3 == 0 }

	filtered := slice.filter(big, is_multiple_of_3)
	defer delete(filtered)
	testing.expect_value(t, len(filtered), 334)
	for v, i in filtered {
		testing.expect_value(t, v, 3 * i)
	}

	filtered_reverse := slice.filter_reverse(big, is_multiple_of_3)
	defer delete(filtered_reverse)
	testing.expect_value(t, len(filtered_reverse), 334)
	for v, i in filtered_reverse {
		testing.expect_value(t, v, 999 - 3 * i)
	}

	m := map[int]int{1 = 10, 2 = 20, 3 = 30}
	defer delete(m)

	keys, keys_err := slice.map_keys(m)
	defer delete(keys)
	testing.expect_value(t, keys_err, nil)
	slice.sort(keys)
	testing.expect(t, slice.equal(keys, []int{1, 2, 3}))

	values, values_err := slice.map_values(m)
	defer delete(values)
	testing.expect_value(t, values_err, nil)
	slice.sort(values)
	testing.expect(t, slice.equal(values, []int{10, 20, 30}))
}
