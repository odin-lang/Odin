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
test_interface_sort :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	values   := make([]int, 5003)
	expected := make([]int, 5003)
	defer delete(values)
	defer delete(expected)

	for n in ([?]int{0, 1, 2, 3, 12, 13, 40, 41, 100, 1000, 5003}) {
		for &v in values[:n] {
			v = rand.int_max(n/2 + 1)
		}
		copy(expected[:n], values[:n])
		slice.sort(expected[:n])

		v := values[:n]
		sort.sort(sort.slice_interface(&v))
		testing.expectf(t, slice.equal(v, expected[:n]), "sort, n = %d", n)

		sort.reverse_sort(sort.slice_interface(&v))
		slice.reverse(expected[:n])
		testing.expectf(t, slice.equal(v, expected[:n]), "reverse_sort, n = %d", n)
	}
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
