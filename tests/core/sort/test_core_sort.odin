package test_core_sort

import "core:math/rand"
import "core:slice"
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
test_rotate :: proc(t: ^testing.T) {
	data:     [12]int
	expected: [12]int
	for n in 0..=len(data) {
		for a in 0..=n {
			for m in a..=n {
				for b in m..=n {
					for &v, i in data {
						v = i
					}
					copy(expected[:], data[:])
					copy(expected[a:], data[m:b])
					copy(expected[a+b-m:], data[a:m])

					values := data[:n]
					sort.rotate(sort.slice_interface(&values), a, m, b)
					testing.expectf(t, data == expected, "rotate(%d, %d, %d) on %d items gave %v", a, m, b, n, data[:n])
				}
			}
		}
	}
}

@test
test_interface_sort_inconsistent_less :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	buffer := make([]int, 5003)
	seen   := make([]bool, 5003)
	defer delete(buffer)
	defer delete(seen)

	values: []int

	it := sort.Interface{
		collection = &values,
		len = proc(it: sort.Interface) -> int {
			return len((^[]int)(it.collection)^)
		},
		less = proc(it: sort.Interface, i, j: int) -> bool {
			return rand.int_max(2) == 0
		},
		swap = proc(it: sort.Interface, i, j: int) {
			s := (^[]int)(it.collection)^
			s[i], s[j] = s[j], s[i]
		},
	}

	for n in ([?]int{0, 1, 2, 25, 129, 1000, 5003}) {
		values = buffer[:n]
		for &v, i in values {
			v = i
		}
		sort.sort(it)

		for &s in seen[:n] {
			s = false
		}
		permutation := true
		for v in values {
			if seen[v] {
				permutation = false
				break
			}
			seen[v] = true
		}
		testing.expectf(t, permutation, "n = %d", n)
	}
}

// An adversary that decides the order of items only as the sort compares them, steering the sort towards its worst case.
@test
test_interface_sort_adversary :: proc(t: ^testing.T) {
	Adversary :: struct {
		items:       []int,
		values:      []int,
		gas:         int,
		solid:       int,
		candidate:   int,
		comparisons: int,
	}

	N :: 4096

	adversary: Adversary
	adversary.items  = make([]int, N)
	adversary.values = make([]int, N)
	defer delete(adversary.items)
	defer delete(adversary.values)

	adversary.gas = N
	for i in 0..<N {
		adversary.items[i]  = i
		adversary.values[i] = adversary.gas
	}

	// A descent then an ascent up front, so the scan for sorted input stops at once.
	adversary.values[0] = 1
	adversary.values[1] = 0
	adversary.values[2] = 2
	adversary.solid     = 3

	it := sort.Interface{
		collection = &adversary,
		len = proc(it: sort.Interface) -> int {
			return len((^Adversary)(it.collection).items)
		},
		less = proc(it: sort.Interface, i, j: int) -> bool {
			adv := (^Adversary)(it.collection)
			adv.comparisons += 1

			x := adv.items[i]
			y := adv.items[j]
			if adv.values[x] == adv.gas && adv.values[y] == adv.gas {
				if x == adv.candidate {
					adv.values[x] = adv.solid
				} else {
					adv.values[y] = adv.solid
				}
				adv.solid += 1
			}

			if adv.values[x] == adv.gas {
				adv.candidate = x
			} else if adv.values[y] == adv.gas {
				adv.candidate = y
			}
			return adv.values[x] < adv.values[y]
		},
		swap = proc(it: sort.Interface, i, j: int) {
			adv := (^Adversary)(it.collection)
			adv.items[i], adv.items[j] = adv.items[j], adv.items[i]
		},
	}

	sort.sort(it)

	for i in 1..<N {
		x := adversary.items[i-1]
		y := adversary.items[i]
		if adversary.values[x] > adversary.values[y] {
			testing.expectf(t, false, "not sorted at %d", i)
			break
		}
	}

	log2_n := 12
	testing.expectf(t, adversary.comparisons <= 8*N*log2_n, "%d comparisons for %d items", adversary.comparisons, N)
}

Sort_Record :: struct {
	key:   int,
	index: int,
}

@test
test_slice_sorts :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	compare_records :: proc(a, b: Sort_Record) -> int {
		return sort.compare_ints(a.key, b.key)
	}

	Algorithm :: enum {
		Quick_Sort,
		Quick_Sort_Proc,
		Merge_Sort,
		Merge_Sort_Proc,
		Heap_Sort,
		Heap_Sort_Proc,
		Bubble_Sort,
		Bubble_Sort_Proc,
	}
	STABLE :: bit_set[Algorithm]{.Merge_Sort_Proc, .Bubble_Sort_Proc}

	values   := make([]int, 2049)
	expected := make([]int, 2049)
	records  := make([]Sort_Record, 2049)
	defer delete(values)
	defer delete(expected)
	defer delete(records)

	for algorithm in Algorithm {
		for n in ([?]int{0, 1, 2, 3, 7, 8, 33, 100, 257, 2049}) {
			for &v in values[:n] {
				v = rand.int_max(n/4 + 1)
			}
			copy(expected[:n], values[:n])
			slice.sort(expected[:n])

			for &r, i in records[:n] {
				r = {rand.int_max(n/4 + 1), i}
			}

			v := values[:n]
			r := records[:n]
			switch algorithm {
			case .Quick_Sort:       sort.quick_sort(v)
			case .Quick_Sort_Proc:  sort.quick_sort_proc(r, compare_records)
			case .Merge_Sort:       sort.merge_sort(v)
			case .Merge_Sort_Proc:  sort.merge_sort_proc(r, compare_records)
			case .Heap_Sort:        sort.heap_sort(v)
			case .Heap_Sort_Proc:   sort.heap_sort_proc(r, compare_records)
			case .Bubble_Sort:      sort.bubble_sort(v)
			case .Bubble_Sort_Proc: sort.bubble_sort_proc(r, compare_records)
			}

			#partial switch algorithm {
			case .Quick_Sort, .Merge_Sort, .Heap_Sort, .Bubble_Sort:
				testing.expectf(t, slice.equal(v, expected[:n]), "%v, n = %d", algorithm, n)
				continue
			}

			sorted := true
			for i in 1..<n {
				if r[i-1].key > r[i].key {
					sorted = false
					break
				}
				if algorithm in STABLE && r[i-1].key == r[i].key && r[i-1].index > r[i].index {
					sorted = false
					break
				}
			}
			testing.expectf(t, sorted, "%v, n = %d", algorithm, n)
		}
	}
}

Stable_Pattern :: enum {
	Random,
	Duplicates,
	Few_Keys,
	Two_Keys,
	Equal,
	Sorted,
	Reversed,
	Nearly_Sorted,
	Organ_Pipe,
	Sawtooth,
	Sorted_Tail,
}

fill_stable_pattern :: proc(records: []Sort_Record, pattern: Stable_Pattern) {
	n := len(records)
	for &r, i in records {
		key: int
		switch pattern {
		case .Random:        key = rand.int_max(1 << 30)
		case .Duplicates:    key = rand.int_max(max(n/8, 1))
		case .Few_Keys:      key = rand.int_max(5)
		case .Two_Keys:      key = rand.int_max(2)
		case .Equal:         key = 7
		case .Sorted:        key = i/3
		case .Reversed:      key = (n-i)/3
		case .Nearly_Sorted: key = i
		case .Organ_Pipe:    key = min(i, n-i)
		case .Sawtooth:      key = i % 37
		case .Sorted_Tail:   key = i if i < n - n/10 else rand.int_max(n + 1)
		}
		r = {key, i}
	}

	if pattern == .Nearly_Sorted && n >= 2 {
		for _ in 0..<max(n/50, 1) {
			i := rand.int_max(n)
			j := rand.int_max(n)
			records[i], records[j] = records[j], records[i]
		}
	}
}

record_interface :: proc(records: ^[]Sort_Record) -> sort.Interface {
	return sort.Interface{
		collection = records,
		len = proc(it: sort.Interface) -> int {
			return len((^[]Sort_Record)(it.collection)^)
		},
		less = proc(it: sort.Interface, i, j: int) -> bool {
			s := (^[]Sort_Record)(it.collection)^
			return s[i].key < s[j].key
		},
		swap = proc(it: sort.Interface, i, j: int) {
			s := (^[]Sort_Record)(it.collection)^
			s[i], s[j] = s[j], s[i]
		},
	}
}

@(require_results)
is_stable_order :: proc(records: []Sort_Record, descending: bool) -> bool {
	seen := make([]bool, len(records))
	defer delete(seen)

	for r, i in records {
		if !(0 <= r.index && r.index < len(records)) || seen[r.index] {
			return false
		}
		seen[r.index] = true

		if i == 0 {
			continue
		}
		prev := records[i-1]
		if descending {
			if prev.key < r.key {
				return false
			}
		} else {
			if prev.key > r.key {
				return false
			}
		}
		if prev.key == r.key && prev.index > r.index {
			return false
		}
	}
	return true
}

@test
test_interface_sort :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	buffer := make([]Sort_Record, 100003)
	defer delete(buffer)

	sizes := []int{0, 1, 2, 3, 8, 9, 31, 32, 33, 64, 100, 257, 1000, 4099, 20011, 100003}
	for pattern in Stable_Pattern {
		for n in sizes {
			records := buffer[:n]

			fill_stable_pattern(records, pattern)
			sort.sort(record_interface(&records))
			testing.expectf(t, is_stable_order(records, false), "sort, %v, n = %d", pattern, n)

			fill_stable_pattern(records, pattern)
			sort.reverse_sort(record_interface(&records))
			testing.expectf(t, is_stable_order(records, true), "reverse_sort, %v, n = %d", pattern, n)
		}
	}

	records := buffer[:1000]
	fill_stable_pattern(records, .Duplicates)
	sort.stable_sort(record_interface(&records))
	testing.expect(t, is_stable_order(records, false), "stable_sort")

	fill_stable_pattern(records, .Duplicates)
	sort.reverse_stable_sort(record_interface(&records))
	testing.expect(t, is_stable_order(records, true), "reverse_stable_sort")
}
