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

Sort_Item_64 :: struct {
	key:   i64,
	index: i64,
	pad:   [6]u64,
}

Sort_Item_136 :: struct {
	key:   i64,
	index: i64,
	pad:   [15]u64,
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
	Equal,
	Sorted,
	Reversed,
	Nearly_Sorted,
	Organ_Pipe,
	Sawtooth,
	Descending_Runs,
}

Sort_Api :: enum {
	Sort_By,
	Sort_By_Cmp,
	Sort_By_With_Data,
	Sort_By_Cmp_With_Data,
	Sort_By_Generic_Cmp,
	Sort_By_Key,
	Stable_Sort_By,
	Stable_Sort_By_Cmp,
}

STABLE_SORT_APIS :: bit_set[Sort_Api]{.Stable_Sort_By, .Stable_Sort_By_Cmp}

@(require_results)
sort_pattern_key :: proc(pattern: Sort_Pattern, i, n: int) -> i64 {
	switch pattern {
	case .Random:          return i64(rand.int_max(1 << 30))
	case .Duplicates:      return i64(rand.int_max(max(n/4, 1)))
	case .Few_Keys:        return i64(rand.int_max(8))
	case .Equal:           return 7
	case .Sorted:          return i64(i/3)
	case .Reversed:        return i64((n-i)/3)
	case .Nearly_Sorted:   return i64(i)
	case .Organ_Pipe:      return i64(min(i, n-i))
	case .Sawtooth:        return i64(i%37)
	case .Descending_Runs: return i64(1000 - i%1000 + (i/1000)*7)
	}
	return 0
}

fill_sort_items :: proc(items: []$T, pattern: Sort_Pattern) {
	n := len(items)
	for &item, i in items {
		item = {}
		item.key   = sort_pattern_key(pattern, i, n)
		item.index = i64(i)
	}

	if pattern == .Nearly_Sorted && n >= 2 {
		for _ in 0..<max(n/50, 1) {
			i := rand.int_max(n)
			j := rand.int_max(n)
			items[i], items[j] = items[j], items[i]
		}
	}
}

@(require_results)
is_permutation_of_indices :: proc(items: []$T) -> bool {
	seen := make([]bool, len(items))
	defer delete(seen)

	for item in items {
		if !(0 <= item.index && item.index < i64(len(items))) {
			return false
		}
		if seen[item.index] {
			return false
		}
		seen[item.index] = true
	}
	return true
}

// Sorted by key, ascending or descending, and a permutation of the input.
// With `stable`, equal keys also keep their input order.
@(require_results)
is_sorted_items :: proc(items: []$T, descending, stable: bool) -> bool {
	for i in 1..<len(items) {
		prev := items[i-1]
		item := items[i]
		if descending {
			if prev.key < item.key {
				return false
			}
		} else {
			if prev.key > item.key {
				return false
			}
		}
		if stable && prev.key == item.key && prev.index > item.index {
			return false
		}
	}
	return is_permutation_of_indices(items)
}

sort_items :: proc(items: []$T, api: Sort_Api) {
	by_key :: proc(a, b: T) -> bool {
		return a.key < b.key
	}
	cmp_key :: proc(a, b: T) -> slice.Ordering {
		return slice.cmp(a.key, b.key)
	}
	by_key_with_data :: proc(a, b: T, user_data: rawptr) -> bool {
		assert(user_data == rawptr(uintptr(1)))
		return a.key < b.key
	}
	cmp_key_with_data :: proc(a, b: T, user_data: rawptr) -> slice.Ordering {
		assert(user_data == rawptr(uintptr(1)))
		return slice.cmp(a.key, b.key)
	}
	generic_cmp_key :: proc(lhs, rhs: rawptr, user_data: rawptr) -> slice.Ordering {
		assert(user_data == rawptr(uintptr(1)))
		return slice.cmp((^T)(lhs).key, (^T)(rhs).key)
	}
	key :: proc(item: T) -> i64 {
		return item.key
	}

	switch api {
	case .Sort_By:               slice.sort_by(items, by_key)
	case .Sort_By_Cmp:           slice.sort_by_cmp(items, cmp_key)
	case .Sort_By_With_Data:     slice.sort_by_with_data(items, by_key_with_data, rawptr(uintptr(1)))
	case .Sort_By_Cmp_With_Data: slice.sort_by_cmp_with_data(items, cmp_key_with_data, rawptr(uintptr(1)))
	case .Sort_By_Generic_Cmp:   slice.sort_by_generic_cmp(items, generic_cmp_key, rawptr(uintptr(1)))
	case .Sort_By_Key:           slice.sort_by_key(items, key)
	case .Stable_Sort_By:        slice.stable_sort_by(items, by_key)
	case .Stable_Sort_By_Cmp:    slice.stable_sort_by_cmp(items, cmp_key)
	}
}

check_sorts :: proc(t: ^testing.T, $T: typeid, sizes: []int, apis: bit_set[Sort_Api]) {
	items := make([]T, slice.max(sizes))
	defer delete(items)

	for api in apis {
		for pattern in Sort_Pattern {
			for n in sizes {
				fill_sort_items(items[:n], pattern)
				sort_items(items[:n], api)
				stable := api in STABLE_SORT_APIS
				testing.expectf(t, is_sorted_items(items[:n], false, stable), "%v, %v, %v, n = %d", api, typeid_of(T), pattern, n)
			}
		}
	}
}

@test
test_sort_patterns :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	sizes: [dynamic]int
	defer delete(sizes)
	for n in 0..=200 {
		append(&sizes, n)
	}
	append(&sizes, 255, 256, 257, 511, 512, 513, 1000, 2049, 4097, 20011)

	check_sorts(t, Sort_Item, sizes[:], ~bit_set[Sort_Api]{})
}

@test
test_sort_element_sizes :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	sizes := []int{0, 1, 2, 3, 7, 8, 16, 17, 31, 32, 33, 96, 97, 132, 133, 255, 256, 257, 1000, 5003}
	check_sorts(t, Sort_Item_64,  sizes, STABLE_SORT_APIS)
	check_sorts(t, Sort_Item_136, sizes, STABLE_SORT_APIS)
	check_sorts(t, Sort_Item_600, sizes, STABLE_SORT_APIS)

	huge_sizes := []int{0, 1, 2, 15, 16, 17, 18, 33, 64, 100, 257}
	check_sorts(t, Sort_Item_20000, huge_sizes, STABLE_SORT_APIS)
}

@test
test_sort_ordered :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	values   := make([]i32, 20011)
	expected := make([]i32, 20011)
	defer delete(values)
	defer delete(expected)

	by_value :: proc(a, b: i32) -> bool {
		return a < b
	}

	sizes := []int{0, 1, 2, 5, 17, 100, 133, 1000, 20011}
	for pattern in Sort_Pattern {
		for n in sizes {
			for &value, i in values[:n] {
				value = i32(sort_pattern_key(pattern, i, n))
			}
			copy(expected[:n], values[:n])
			slice.stable_sort_by(expected[:n], by_value)

			slice.sort(values[:n])
			testing.expectf(t, slice.equal(values[:n], expected[:n]), "sort, %v, n = %d", pattern, n)

			slice.reverse(values[:n])
			slice.stable_sort(values[:n])
			testing.expectf(t, slice.equal(values[:n], expected[:n]), "stable_sort, %v, n = %d", pattern, n)

			slice.reverse_sort(values[:n])
			slice.reverse(values[:n])
			testing.expectf(t, slice.equal(values[:n], expected[:n]), "reverse_sort, %v, n = %d", pattern, n)
		}
	}
}

// 4-byte keys go through a vector partition on most targets. Its float and unsigned compares must agree with
// the comparator path bit for bit: -0.0 and 0.0 compare equal and keep their order, and u32 keys above 1<<31 stay unsigned.
@test
test_sort_ordered_lanes :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	check :: proc(t: ^testing.T, $E: typeid) {
		values   := make([]E, 40011)
		expected := make([]E, 40011)
		defer delete(values)
		defer delete(expected)

		for n in ([?]int{0, 3, 4, 5, 17, 100, 1023, 1025, 5000, 40011}) {
			for &v in values[:n] {
				when E == f32 {
					switch rand.int_max(4) {
					case 0: v = -0.0
					case 1: v = 0.0
					case:   v = f32(rand.int_max(max(n/8, 2)) - n/16)
					}
				} else {
					v = u32(rand.int_max(max(n/8, 2))) + (1 << 31 if rand.int_max(2) == 0 else 0)
				}
			}

			copy(expected[:n], values[:n])
			slice.stable_sort_by(expected[:n], proc(a, b: E) -> bool { return a < b })
			slice.sort(values[:n])
			testing.expectf(t, slice.equal(transmute([]u32)values[:n], transmute([]u32)expected[:n]), "sort, %v, n = %d", typeid_of(E), n)

			copy(expected[:n], values[:n])
			slice.stable_sort_by(expected[:n], proc(a, b: E) -> bool { return a > b })
			slice.reverse_sort(values[:n])
			testing.expectf(t, slice.equal(transmute([]u32)values[:n], transmute([]u32)expected[:n]), "reverse_sort, %v, n = %d", typeid_of(E), n)
		}
	}

	check(t, f32)
	check(t, u32)
}

@test
test_reverse_sorts :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	by_key :: proc(a, b: Sort_Item) -> bool {
		return a.key < b.key
	}
	cmp_key :: proc(a, b: Sort_Item) -> slice.Ordering {
		return slice.cmp(a.key, b.key)
	}
	key :: proc(item: Sort_Item) -> i64 {
		return item.key
	}

	items := make([]Sort_Item, 5003)
	defer delete(items)

	sizes := []int{0, 1, 2, 7, 8, 33, 133, 257, 1000, 5003}
	for pattern in Sort_Pattern {
		for n in sizes {
			fill_sort_items(items[:n], pattern)
			slice.reverse_sort_by(items[:n], by_key)
			testing.expectf(t, is_sorted_items(items[:n], true, false), "reverse_sort_by, %v, n = %d", pattern, n)

			fill_sort_items(items[:n], pattern)
			slice.reverse_sort_by_cmp(items[:n], cmp_key)
			testing.expectf(t, is_sorted_items(items[:n], true, false), "reverse_sort_by_cmp, %v, n = %d", pattern, n)

			fill_sort_items(items[:n], pattern)
			slice.reverse_sort_by_key(items[:n], key)
			testing.expectf(t, is_sorted_items(items[:n], true, false), "reverse_sort_by_key, %v, n = %d", pattern, n)
		}
	}
}

@test
test_sort_with_indices_patterns :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	by_value :: proc(a, b: i64) -> bool {
		return a < b
	}
	by_value_with_data :: proc(a, b: i64, user_data: rawptr) -> bool {
		assert(user_data == rawptr(uintptr(1)))
		return a < b
	}

	values   := make([]i64, 5003)
	original := make([]i64, 5003)
	defer delete(values)
	defer delete(original)

	Api :: enum {
		Sort_With_Indices,
		Sort_By_With_Indices,
		Sort_By_With_Indices_With_Data,
	}

	sizes := []int{0, 1, 2, 7, 8, 33, 133, 257, 1000, 5003}
	for api in Api {
		for pattern in Sort_Pattern {
			for n in sizes {
				for &value, i in values[:n] {
					value = sort_pattern_key(pattern, i, n)
				}
				copy(original[:n], values[:n])

				indices: []int
				switch api {
				case .Sort_With_Indices:              indices = slice.sort_with_indices(values[:n])
				case .Sort_By_With_Indices:           indices = slice.sort_by_with_indices(values[:n], by_value)
				case .Sort_By_With_Indices_With_Data: indices = slice.sort_by_with_indices_with_data(values[:n], by_value_with_data, rawptr(uintptr(1)))
				}
				defer delete(indices)

				testing.expectf(t, slice.is_sorted(values[:n]), "%v, %v, n = %d: not sorted", api, pattern, n)
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
