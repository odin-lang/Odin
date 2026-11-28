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

Sort_Item :: struct {
	key:   i64,
	index: i64,
}

Sort_Item_8 :: struct {
	key:   i32,
	index: i32,
}

// 4-aligned, and not a multiple of 8 bytes.
Sort_Item_12 :: struct {
	key:   i32,
	index: i32,
	pad:   i32,
}

Sort_Item_24 :: struct {
	key:   i64,
	index: i64,
	pad:   u64,
}

Sort_Item_64 :: struct {
	key:   i64,
	index: i64,
	pad:   [6]u64,
}

Sort_Item_96 :: struct {
	key:   i64,
	index: i64,
	pad:   [10]u64,
}

Sort_Item_136 :: struct {
	key:   i64,
	index: i64,
	pad:   [15]u64,
}

Sort_Item_264 :: struct {
	key:   i64,
	index: i64,
	pad:   [31]u64,
}

Sort_Item_600 :: struct {
	key:   i64,
	index: i64,
	pad:   [73]u64,
}

Sort_Item_20000 :: struct {
	key:   i64,
	index: i64,
	pad:   [2498]u64,
}

Sort_Pattern :: enum {
	Random,
	Duplicates,
	Few_Keys,
	Mostly_Equal,
	Equal,
	Sorted,
	Reversed,
	Descending,
	Nearly_Sorted,
	Swapped,
	Spikes,
	Organ_Pipe,
	Sawtooth,
	Runs,
	Short_Runs,
	Half_Sorted,
	Descending_Runs,
}

// The `_runtime` and `_constant` variants are called directly. `sort_by` and the like take the constant one only from
// -o:speed, and the two take different paths.
Sort_Api :: enum {
	Sort_By,
	Sort_By_Constant,
	Sort_By_Cmp,
	Sort_By_Cmp_Constant,
	Sort_By_With_Data,
	Sort_By_Cmp_With_Data,
	Sort_By_Generic_Cmp,
	Sort_By_Key,
	Reverse_Sort_By,
	Reverse_Sort_By_Constant,
	Reverse_Sort_By_Cmp,
	Reverse_Sort_By_Cmp_Constant,
	Reverse_Sort_By_Key,
}

REVERSE_SORT_APIS :: bit_set[Sort_Api]{.Reverse_Sort_By, .Reverse_Sort_By_Constant, .Reverse_Sort_By_Cmp, .Reverse_Sort_By_Cmp_Constant, .Reverse_Sort_By_Key}

// Fills `keys` with a pattern. Keys are never negative, and most patterns repeat them: stability shows only among equal keys.
sort_pattern_keys :: proc(keys: []i64, pattern: Sort_Pattern) {
	n := len(keys)
	switch pattern {
	case .Random:
		for &k in keys {
			k = i64(rand.int_max(1 << 30))
		}
	case .Duplicates:
		for &k in keys {
			k = i64(rand.int_max(max(n/4, 1)))
		}
	case .Few_Keys:
		for &k in keys {
			k = i64(rand.int_max(8))
		}
	case .Mostly_Equal:
		// One key apart from every eighth item: nothing long is sorted, and a partition meets mostly its pivot.
		for &k, i in keys {
			k = i64(rand.int_max(10)) if i%8 == 3 else 5
		}
	case .Equal:
		for &k in keys {
			k = 7
		}
	case .Sorted:
		for &k, i in keys {
			k = i64(i/3)
		}
	case .Reversed:
		for &k, i in keys {
			k = i64((n-i)/3)
		}
	case .Descending:
		// Strictly descending between equal pairs. A reversal past one would swap the pair.
		for &k, i in keys {
			k = i64(n - i + i/64)
		}
	case .Nearly_Sorted, .Swapped:
		// With 1% of keys swapped, the sort keeps the sorted items in place and merges the others back, across segments
		// once its buffer fills. With 8%, a comparator sort merges natural runs, the input still sorted at large scale.
		for &k, i in keys {
			k = i64(i/3)
		}
		swaps := (n+99)/100 if pattern == .Nearly_Sorted else n*8/100
		for _ in 0..<swaps {
			a, b := rand.int_max(n), rand.int_max(n)
			keys[a], keys[b] = keys[b], keys[a]
		}
	case .Spikes:
		// Lone items and equal pairs above what follows them, each equal to keys further on.
		for &k, i in keys {
			k = i64(i/3) + (40 if i%61 == 60 || i%60 == 57 || i%60 == 58 else 0)
		}
	case .Organ_Pipe:
		for &k, i in keys {
			k = i64(min(i, n-i))
		}
	case .Sawtooth:
		for &k, i in keys {
			k = i64(i%37)
		}
	case .Runs:
		// Long and short runs for a comparator sort to merge, ascending with repeats or strictly descending between equal pairs.
		lengths := [?]int{300, 3, 31, 32, 33, 1, 700, 12, 64, 2, 250, 20, 97}
		start, run := 0, 0
		for start < n {
			length := min(lengths[run % len(lengths)], n - start)
			for j in 0..<length {
				keys[start+j] = i64(j/2) if run%2 == 0 else i64(length - j + j/16)
			}
			start += length
			run   += 1
		}
	case .Short_Runs:
		// Sorted runs of 20 to 60 keys: few descents, but each run starts below the one before.
		for &k in keys {
			k = i64(rand.int_max(max(n/4, 1)))
		}
		for start := 0; start < n; {
			end := min(start + 20 + rand.int_max(41), n)
			slice.sort(keys[start:end])
			start = end
		}
	case .Half_Sorted:
		// Quarters in order and quarters not, over the same keys.
		for &k, i in keys {
			k = i64(i/3) if i < n/2 else i64(rand.int_max(max(n/6, 1)))
		}
	case .Descending_Runs:
		for &k, i in keys {
			k = i64(1000 - i%1000 + (i/1000)*7)
		}
	}
}

@(require_results)
is_permutation_of_indices :: proc(items: []$T) -> bool {
	seen := make([]bool, len(items))
	defer delete(seen)

	for item in items {
		index := i64(item.index)
		if !(0 <= index && index < i64(len(items))) {
			return false
		}
		if seen[index] {
			return false
		}
		seen[index] = true
	}
	return true
}

// Sorted by key, ascending or descending, with equal keys in their input order, and a permutation of the input.
// Only the stable order passes.
@(require_results)
is_sorted_items :: proc(items: []$T, descending: bool) -> bool {
	for i in 1..<len(items) {
		prev, item := items[i-1], items[i]
		in_order := prev.key > item.key if descending else prev.key < item.key
		if !in_order && (prev.key != item.key || prev.index > item.index) {
			return false
		}
	}
	return is_permutation_of_indices(items)
}

sort_items :: proc(items: []$T, api: Sort_Api) {
	less :: proc(a, b: T) -> bool {
		return a.key < b.key
	}
	cmp :: proc(a, b: T) -> slice.Ordering {
		return slice.cmp(a.key, b.key)
	}
	less_with_data :: proc(a, b: T, user_data: rawptr) -> bool {
		assert(user_data == rawptr(uintptr(1)))
		return a.key < b.key
	}
	cmp_with_data :: proc(a, b: T, user_data: rawptr) -> slice.Ordering {
		assert(user_data == rawptr(uintptr(1)))
		return slice.cmp(a.key, b.key)
	}
	generic_cmp :: proc(lhs, rhs: rawptr, user_data: rawptr) -> slice.Ordering {
		assert(user_data == rawptr(uintptr(1)))
		return slice.cmp((^T)(lhs).key, (^T)(rhs).key)
	}
	key :: proc(item: T) -> i64 {
		return i64(item.key)
	}

	switch api {
	case .Sort_By:                      slice.sort_by_runtime(items, less)
	case .Sort_By_Constant:             slice.sort_by_constant(items, less)
	case .Sort_By_Cmp:                  slice.sort_by_cmp_runtime(items, cmp)
	case .Sort_By_Cmp_Constant:         slice.sort_by_cmp_constant(items, cmp)
	case .Sort_By_With_Data:            slice.sort_by_with_data(items, less_with_data, rawptr(uintptr(1)))
	case .Sort_By_Cmp_With_Data:        slice.sort_by_cmp_with_data(items, cmp_with_data, rawptr(uintptr(1)))
	case .Sort_By_Generic_Cmp:          slice.sort_by_generic_cmp(items, generic_cmp, rawptr(uintptr(1)))
	case .Sort_By_Key:                  slice.sort_by_key(items, key)
	case .Reverse_Sort_By:              slice.reverse_sort_by_runtime(items, less)
	case .Reverse_Sort_By_Constant:     slice.reverse_sort_by_constant(items, less)
	case .Reverse_Sort_By_Cmp:          slice.reverse_sort_by_cmp_runtime(items, cmp)
	case .Reverse_Sort_By_Cmp_Constant: slice.reverse_sort_by_cmp_constant(items, cmp)
	case .Reverse_Sort_By_Key:          slice.reverse_sort_by_key(items, key)
	}
}

// Every sort is stable: items carry their input position, and only the stable order passes.
check_sorts :: proc(t: ^testing.T, $T: typeid, sizes: []int, apis: bit_set[Sort_Api]) {
	keys  := make([]i64, slice.max(sizes))
	items := make([]T, len(keys))
	defer delete(keys)
	defer delete(items)

	for pattern in Sort_Pattern {
		for n in sizes {
			sort_pattern_keys(keys[:n], pattern)
			for api in apis {
				for &item, i in items[:n] {
					item = {}
					item.key   = type_of(item.key)(keys[i])
					item.index = type_of(item.index)(i)
				}
				sort_items(items[:n], api)
				testing.expectf(t, is_sorted_items(items[:n], api in REVERSE_SORT_APIS), "%v, %v, %v, n = %d", api, typeid_of(T), pattern, n)
			}
		}
	}
}

// The sizes reach each part of the sort, on both sides of where it takes over.
@test
test_sort_patterns :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	sizes: [dynamic]int
	defer delete(sizes)
	for n in 0..=200 {
		append(&sizes, n)
	}
	append(&sizes, 255, 256, 257, 511, 512, 513, 1000, 1024, 1025, 2048, 2049, 4097)
	check_sorts(t, Sort_Item, sizes[:], ~bit_set[Sort_Api]{})

	// Comparators differ only in being calls or constants. Past these sizes, `sort_by` and `sort_by_constant` stand in for the rest.
	check_sorts(t, Sort_Item, {16384, 16385, 20011, 70001}, {.Sort_By, .Sort_By_Constant})
}

// Element sizes set the buffer sizes, and with them where each part of the sort takes over.
@test
test_sort_element_sizes :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	APIS :: bit_set[Sort_Api]{.Sort_By, .Sort_By_Constant}

	sizes := []int{0, 1, 2, 3, 7, 8, 9, 16, 17, 31, 32, 33, 64, 65, 96, 97, 132, 133, 255, 256, 257, 1000, 1025, 5003, 20011}
	check_sorts(t, Sort_Item_8,   sizes, APIS)
	check_sorts(t, Sort_Item_12,  sizes, APIS)
	check_sorts(t, Sort_Item_24,  sizes, APIS)
	check_sorts(t, Sort_Item_64,  sizes, APIS)
	check_sorts(t, Sort_Item_96,  sizes, APIS)
	check_sorts(t, Sort_Item_136, sizes, APIS)
	check_sorts(t, Sort_Item_264, sizes, APIS)
	check_sorts(t, Sort_Item_600, sizes[:len(sizes)-1], APIS)

	huge_sizes := []int{0, 1, 2, 15, 16, 17, 18, 33, 64, 100, 257}
	check_sorts(t, Sort_Item_20000, huge_sizes, APIS)
}

// Sorting either way must give the stable order, bit for bit. Bits tell apart values that compare equal: -0.0 and 0.0,
// or equal strings at different addresses. A sort of the values tagged with their positions gives the stable order, and
// the tags check it.
expect_stable_order :: proc(t: ^testing.T, values: []$E, what: any, loc := #caller_location) {
	Tagged :: struct {
		key:   E,
		index: i64,
	}
	less :: proc(a, b: Tagged) -> bool {
		return a.key < b.key
	}

	n := len(values)
	tagged   := make([]Tagged, n)
	expected := make([]E, n)
	sorted   := make([]E, n)
	defer delete(tagged)
	defer delete(expected)
	defer delete(sorted)

	for descending in ([?]bool{false, true}) {
		for &x, i in tagged {
			x = {values[i], i64(i)}
		}
		copy(sorted, values)
		if descending {
			slice.reverse_sort_by_runtime(tagged, less)
			slice.reverse_sort(sorted)
		} else {
			slice.sort_by_runtime(tagged, less)
			slice.sort(sorted)
		}

		api := "reverse_sort" if descending else "sort"
		if !testing.expectf(t, is_sorted_items(tagged, descending), "%s_by on tags, %v, %v, n = %d", api, typeid_of(E), what, n, loc = loc) {
			return
		}
		for x, i in tagged {
			expected[i] = values[x.index]
		}
		testing.expectf(t, slice.equal(slice.to_bytes(sorted), slice.to_bytes(expected)), "%s, %v, %v, n = %d", api, typeid_of(E), what, n, loc = loc)
	}
}

// `sort` and `reverse_sort` on values that compare equal but differ in their bits. f32 goes through a vector partition on
// most targets and f64 through the scalar one. Strings take the paths for comparisons that are calls.
@test
test_sort_ordered_stable :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	SIZES :: [?]int{0, 1, 2, 3, 5, 7, 8, 9, 16, 17, 31, 32, 33, 64, 65, 96, 97, 132, 133, 255, 256, 257, 1000, 1024, 1025, 2048, 2049, 4097, 16385, 20011}
	N :: SIZES[len(SIZES)-1]

	keys := make([]i64, N)
	defer delete(keys)

	floats :: proc(t: ^testing.T, $E: typeid, keys: []i64, pattern: Sort_Pattern) {
		values := make([]E, len(keys))
		defer delete(values)

		// The lowest third of the keys become -0.0 or 0.0 at random.
		lo, hi := slice.min(keys), slice.max(keys)
		zero := lo + (hi-lo)/3
		for &v, i in values {
			if keys[i] > zero {
				v = E(keys[i] - zero)
			} else {
				v = -0.0 if rand.int_max(2) == 0 else 0.0
			}
		}
		expect_stable_order(t, values, pattern)
	}

	texts   := make([][8]u8, N)
	strings := make([]string, N)
	defer delete(texts)
	defer delete(strings)

	for pattern in Sort_Pattern {
		for n in SIZES {
			sort_pattern_keys(keys[:n], pattern)
			floats(t, f32, keys[:n], pattern)
			floats(t, f64, keys[:n], pattern)

			// Big-endian bytes order as the keys do. Each string has its own copy.
			for &s, i in strings[:n] {
				texts[i] = transmute([8]u8)u64be(keys[i])
				s = string(texts[i][:])
			}
			expect_stable_order(t, strings[:n], pattern)
		}
	}
}

// Integers in their own order go through a radix sort. Every width and sign must sort as a comparison sort does.
@test
test_sort_integers :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	check :: proc(t: ^testing.T, $E: typeid) {
		SIZES :: [?]int{0, 1, 2, 5, 17, 100, 133, 257, 1000, 1025, 5000, 20011}
		N :: SIZES[len(SIZES)-1]

		values := make([]E, N)
		keys   := make([]i64, N)
		defer delete(values)
		defer delete(keys)

		for pattern in Sort_Pattern {
			for n in SIZES {
				// Random keys use every bit. The others shift down by n/2, which crosses zero or wraps.
				sort_pattern_keys(keys[:n], pattern)
				for &v, i in values[:n] {
					if pattern == .Random {
						v = E(rand.uint128())
					} else {
						v = E(keys[i]) - E(n/2)
					}
				}
				expect_stable_order(t, values[:n], pattern)
			}
		}

		// A few distinct keys spread over every bit take the partition instead: 4-byte keys past the buffer, others past 1 MB.
		few_values := make([]E, (1 << 20)/size_of(E) + 1)
		defer delete(few_values)

		for n in ([?]int{1025, 5000, len(few_values)}) {
			few: [3]E
			for &f in few {
				f = E(rand.uint128())
			}
			for &v in few_values[:n] {
				v = few[rand.int_max(len(few))]
			}
			expect_stable_order(t, few_values[:n], "few spread keys")
		}
	}

	check(t, i8)
	check(t, u8)
	check(t, i16)
	check(t, u16)
	check(t, i32)
	check(t, u32)
	check(t, rune)
	check(t, i64)
	check(t, u64)
	check(t, i128)
	check(t, u128)
}

// The indices of equal values must come out in increasing order.
@test
test_sort_with_indices_patterns :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	less :: proc(a, b: i64) -> bool {
		return a < b
	}
	less_with_data :: proc(a, b: i64, user_data: rawptr) -> bool {
		assert(user_data == rawptr(uintptr(1)))
		return a < b
	}

	SIZES :: [?]int{0, 1, 2, 7, 8, 9, 33, 97, 133, 257, 1000, 1025, 5003, 20011}
	N :: SIZES[len(SIZES)-1]

	values   := make([]i64, N)
	original := make([]i64, N)
	items    := make([]Sort_Item, N)
	defer delete(values)
	defer delete(original)
	defer delete(items)

	Api :: enum {
		Sort_With_Indices,
		Sort_By_With_Indices,
		Sort_By_With_Indices_With_Data,
	}

	for api in Api {
		for pattern in Sort_Pattern {
			for n in SIZES {
				sort_pattern_keys(values[:n], pattern)
				copy(original[:n], values[:n])

				indices: []int
				switch api {
				case .Sort_With_Indices:              indices = slice.sort_with_indices(values[:n])
				case .Sort_By_With_Indices:           indices = slice.sort_by_with_indices(values[:n], less)
				case .Sort_By_With_Indices_With_Data: indices = slice.sort_by_with_indices_with_data(values[:n], less_with_data, rawptr(uintptr(1)))
				}
				defer delete(indices)

				for index, i in indices {
					items[i] = {values[i], i64(index)}
				}
				testing.expectf(t, is_sorted_items(items[:n], false), "%v, %v, n = %d: not sorted, stable, or a permutation", api, pattern, n)
				for index, i in indices {
					if values[i] != original[index] {
						testing.expectf(t, false, "%v, %v, n = %d: index %d does not match", api, pattern, n, i)
						break
					}
				}
			}
		}
	}
}

@test
test_sort_inconsistent_comparator :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	random_less :: proc(a, b: Sort_Item) -> bool {
		return rand.int_max(2) == 0
	}
	random_cmp :: proc(a, b: Sort_Item) -> slice.Ordering {
		return slice.Ordering(rand.int_max(3) - 1)
	}

	sizes: [dynamic]int
	defer delete(sizes)
	for n in 0..=300 {
		append(&sizes, n)
	}
	append(&sizes, 511, 512, 513, 1000, 2049, 5003, 20011)

	items := make([]Sort_Item, slice.max(sizes[:]))
	defer delete(items)

	for n in sizes {
		for &item, i in items[:n] {
			item = {key = i64(i), index = i64(i)}
		}

		rand.shuffle(items[:n])
		slice.sort_by(items[:n], random_less)
		testing.expectf(t, is_permutation_of_indices(items[:n]), "sort_by lost or duplicated items, n = %d", n)

		rand.shuffle(items[:n])
		slice.sort_by_cmp(items[:n], random_cmp)
		testing.expectf(t, is_permutation_of_indices(items[:n]), "sort_by_cmp lost or duplicated items, n = %d", n)
	}
}

@test
test_retain :: proc(t: ^testing.T) {
	values := []int{1, 2, 3, 4, 5}
	kept := slice.retain(values, []bool{true, false, true, false, true})
	testing.expect(t, slice.equal(kept, []int{1, 3, 5}))
	testing.expect_value(t, len(slice.retain(values[:2], []bool{false, false})), 0)
	testing.expect_value(t, len(slice.retain(values[:0], nil)), 0)

	V :: struct {
		a: f32,
		b: u8,
	}
	soa := make(#soa[]V, 4)
	defer delete(soa)
	for i in 0..<4 {
		soa[i] = {f32(i), u8(i)}
	}
	kept_soa := slice.retain(soa, []bool{false, true, true, false})
	testing.expect_value(t, len(kept_soa), 2)
	testing.expect_value(t, kept_soa[0], V{1, 1})
	testing.expect_value(t, kept_soa[1], V{2, 2})
	testing.expect_value(t, raw_data(kept_soa.a), raw_data(soa.a))
}

when !testing.INLINE {
	@test
	test_retain_mask_length :: proc(t: ^testing.T) {
		values := []int{1, 2, 3}
		testing.expect_assert(t, "`keep` must be as long as `s`")
		_ = slice.retain(values, []bool{true})
	}
}
