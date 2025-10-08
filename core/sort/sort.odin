/*
The sort package provides sorting algorithms for slices and custom interfaces.

This package includes implementations of quicksort, mergesort, heapsort, and bubble sort,
along with utilities for creating sorting interfaces and comparison functions for various types.
It supports sorting slices of ordered types directly or custom data structures via the `Interface` type.
The package is designed for Odin's core libraries, with a focus on performance and flexibility.



Note(stability): Sorting procedures are not guaranteed to be stable unless specified otherwise.
Note(Comparison of Sorting Methods):
- Quicksort: Fast average-case performance (O(n log n)), but not stable. Best for general-purpose sorting with good cache performance.
- Merge Sort: Stable with O(n log n) complexity, requiring extra memory. Ideal for linked lists or when stability is needed.
- Heap Sort: O(n log n) complexity, not stable, in-place but with poor cache locality. Suitable for environments with limited memory
or when constant-time removal of largest/smallest elements is needed.
- Bubble Sort: Simple but inefficient (O(n²)). Stable. Useful for small datasets or educational purposes.
*/
package sort

import "core:mem"
import _slice "core:slice"
import "base:intrinsics"

_ :: intrinsics
_ :: _slice
ORD :: intrinsics.type_is_ordered

/*
The interface for custom sorting operations.

This struct defines the methods required to sort a collection using the `sort` procedure.
It is typically used for custom data structures or when additional control over sorting is needed.
*/
Interface :: struct {
	// Length of the collection
	len:  proc(it: Interface) -> int,
	// Compare elements at indices `i` and `j`, returning true if element at `i` is less than `j`
	less: proc(it: Interface, i, j: int) -> bool,
	// Swap elements at indices `i` and `j`
	swap: proc(it: Interface, i, j: int),
	// Pointer to the collection being sorted
	collection: rawptr,
}

/*
Sort a collection using the provided Interface.

This procedure sorts the collection defined by `it` in ascending order using a quicksort algorithm.
This sort is not guaranteed to be stable, meaning equal elements may be reordered.
Fast average-case performance (O(n log n)). Best for general-purpose sorting with good cache performance.

Note: Quicksort is a divide-and-conquer algorithm that selects a pivot and partitions the collection
into elements less than and greater than the pivot, recursively sorting the partitions.

Inputs:
- `it`: The Interface defining the collection and sorting operations

Example:
    import "core:sort"
    import "core:fmt"

    sort_interface_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        it := sort.slice_interface(&data)
        sort.sort(it)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
sort :: proc(it: Interface) {
	max_depth :: proc(n: int) -> int { // 2*ceil(log2(n+1))
		depth: int
		for i := n; i > 0; i >>= 1 {
			depth += 1
		}
		return depth * 2
	}

	n := it->len()
	_quick_sort(it, 0, n, max_depth(n))
}

/*
Create a sorting Interface for a slice of ordered elements.

This procedure creates an `Interface` for sorting a slice `s` of type `T` where `T` supports ordering.
The resulting Interface can be used with the `sort` procedure.

Inputs:
- `s`: Pointer to the slice to be sorted

Returns:
- An Interface configured for sorting the slice

Example:
    import "core:sort"
    import "core:fmt"

    slice_interface_example :: proc() {
        data := []int{3, 1, 4, 1, 5}
        it := sort.slice_interface(&data)
        sort.sort(it)
        fmt.println(data)
    }

Output:
    [1, 1, 3, 4, 5]
*/
slice_interface :: proc(s: ^$T/[]$E) -> Interface where ORD(E) {
	return Interface{
		collection = rawptr(s),
		len = proc(it: Interface) -> int {
			s := (^T)(it.collection)
			return len(s^)
		},
		less = proc(it: Interface, i, j: int) -> bool {
			s := (^T)(it.collection)
			return s[i] < s[j]
		},
		swap = proc(it: Interface, i, j: int) {
			s := (^T)(it.collection)
			s[i], s[j] = s[j], s[i]
		},
	}
}

/*
Create a reverse sorting Interface from an existing Interface.

This procedure wraps an existing `Interface` to sort in descending order by reversing the `less` comparison.

Inputs:
- `it`: Pointer to the original Interface

Returns:
- An Interface that sorts in descending order

Example:
    import "core:sort"
    import "core:fmt"

    reverse_interface_example :: proc() {
        data := []int{3, 1, 4, 1, 5}
        it := sort.slice_interface(&data)
        reverse_it := sort.reverse_interface(&it)
        sort.sort(reverse_it)
        fmt.println(data)
    }

Output:
    [5, 4, 3, 1, 1]
*/
reverse_interface :: proc(it: ^Interface) -> Interface {
	return Interface{
		collection = it,

		len = proc(rit: Interface) -> int {
			it := (^Interface)(rit.collection)
			return it.len(it^)
		},
		less = proc(rit: Interface, i, j: int) -> bool {
			it := (^Interface)(rit.collection)
			return it.less(it^, j, i) // reverse parameters
		},
		swap = proc(rit: Interface, i, j: int) {
			it := (^Interface)(rit.collection)
			it.swap(it^, i, j)
		},
	}
}

/*
Sort a collection in descending order.

This procedure sorts the collection defined by `it` in descending order by using a reversed Interface.

Inputs:
- `it`: The Interface defining the collection and sorting operations

Example:
    import "core:sort"
    import "core:fmt"

    reverse_sort_example :: proc() {
        data := []int{2, 3, 5, 1, 4}
        it := sort.slice_interface(&data)
        sort.reverse_sort(it)
        fmt.println(data)
    }

Output:
    [5, 4, 3, 2, 1]
*/
reverse_sort :: proc(it: Interface) {
	it := it
	sort(reverse_interface(&it))
}

/*
Check if a collection is sorted in ascending order.

This procedure verifies if the collection defined by `it` is sorted in ascending order.

Inputs:
- `it`: The Interface defining the collection and sorting operations

Returns:
- True if the collection is sorted in ascending order, false otherwise

Example:
    import "core:sort"
    import "core:fmt"

    is_sorted_example :: proc() {
        data := []int{1, 2, 3, 4, 5}
        it := sort.slice_interface(&data)
        result := sort.is_sorted(it)
        fmt.println(result) // Prints: true
    }

Output:
    true
*/
is_sorted :: proc(it: Interface) -> bool {
	n := it->len()
	for i := n-1; i > 0; i -= 1 {
		if it->less(i, i-1) {
			return false
		}
	}
	return true
}

/*
Swap a range of elements in a collection.

This procedure swaps `n` elements starting at indices `a` and `b` in the collection defined by `it`.

Inputs:
- `it`: The Interface defining the collection and sorting operations
- `a`: Starting index of the first range
- `b`: Starting index of the second range
- `n`: Number of elements to swap

Example:
    import "core:sort"
    import "core:fmt"

	swap_range_example :: proc() {
        data := []int{1, 5, 6, 4, 2, 3}
        it := sort.slice_interface(&data)
        sort.swap_range(it, 1, 4, 2)
        fmt.println(data)
    }


Output:
    [1, 2, 3, 4, 5, 6]
*/
swap_range :: proc(it: Interface, a, b, n: int) {
	for i in 0..<n {
		it->swap(a+i, b+i)
	}
}

/*
Rotate elements in a collection.

This procedure rotates elements in the range `[a, b)` around the pivot `m` in the collection defined by `it`.

Inputs:
- `it`: The Interface defining the collection and sorting operations
- `a`: Start index of the range
- `m`: Pivot index for rotation
- `b`: End index of the range (exclusive)

Example:
    import "core:sort"
    import "core:fmt"

    rotate_example :: proc() {
        data := []int{1, 3, 5, 4, 2, 6}
        it := sort.slice_interface(&data)
        sort.rotate(it, 1, 4, 5)
        fmt.println(data)
    }

Output:
    [1, 2, 3, 4, 5, 6]
*/
rotate :: proc(it: Interface, a, m, b: int) {
	i := m - a
	j := b - m

	for i != j {
		if i > j {
			swap_range(it, m-i, m, j)
			i -= j
		} else {
			swap_range(it, m-i, m+j-1, i)
			j -= 1
		}
	}
	swap_range(it, m-i, m, i)
}


/*
Perform a quicksort on a collection (private).

This procedure implements the quicksort algorithm for the range `[a, b)` in the collection defined by `it`.
It uses a hybrid approach with heap sort for small partitions and shell sort for very small ones.
Fast average-case performance (O(n log n)). Best for general-purpose sorting with good cache performance.

Note: Quicksort is a divide-and-conquer algorithm that selects a pivot and partitions the collection
into elements less than and greater than the pivot, recursively sorting the partitions.

Inputs:
- `it`: The Interface defining the collection and sorting operations
- `a`: Start index of the range
- `b`: End index of the range (exclusive)
- `max_depth`: Maximum recursion depth to prevent stack overflow
*/
@(private)
_quick_sort :: proc(it: Interface, a, b, max_depth: int) {
	median3 :: proc(it: Interface, m1, m0, m2: int) {
		if it->less(m1, m0) {
			it->swap(m1, m0)
		}
		if it->less(m2, m1) {
			it->swap(m2, m1)
			if it->less(m1, m0) {
				it->swap(m1, m0)
			}
		}
	}

	do_pivot :: proc(it: Interface, lo, hi: int) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(it, lo, lo+s, lo+s*2)
			median3(it, m, m-s, m+s)
			median3(it, hi-1, hi-1-s, hi-1-s*2)
		}
		median3(it, lo, m, hi-1)

		pivot := lo
		a, c := lo+1, hi-1

		for ; a < c && it->less(a, pivot); a += 1 {
		}
		b := a

		for {
			for ; b < c && !it->less(pivot, b); b += 1 { // data[b] <= pivot
			}
			for ; b < c && it->less(pivot, c-1); c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			it->swap(b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if !it->less(pivot, hi-1) {
				it->swap(c, hi-1)
				c += 1
				dups += 1
			}
			if !it->less(b-1, pivot) {
				b -= 1
				dups += 1
			}

			if !it->less(m, pivot) {
				it->swap(m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !it->less(b-1, pivot); b -= 1 {
				}
				for ; a < b && it->less(a, pivot); a += 1 {
				}
				if a >= b {
					break
				}
				it->swap(a, b-1)
				a += 1
				b -= 1
			}
		}
		it->swap(pivot, b-1)
		return b-1, c
	}

	heap_sort :: proc(it: Interface, a, b: int) {
		sift_down :: proc(it: Interface, lo, hi, first: int) {
			root := lo
			for {
				child := 2*root + 1
				if child >= hi {
					break
				}
				if child+1 < hi && it->less(first+child, first+child+1) {
					child += 1
				}
				if !it->less(first+root, first+child) {
					return
				}
				it->swap(first+root, first+child)
				root = child
			}
		}


		first, lo, hi := a, 0, b-a

		for i := (hi-1)/2; i >= 0; i -= 1 {
			sift_down(it, i, hi, first)
		}

		for i := hi-1; i >= 0; i -= 1 {
			it->swap(first, first+i)
			sift_down(it, lo, i, first)
		}
	}



	a, b, max_depth := a, b, max_depth

	for b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			heap_sort(it, a, b)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(it, a, b)
		if mlo-a < b-mhi {
			_quick_sort(it, a, mlo, max_depth)
			a = mhi
		} else {
			_quick_sort(it, mhi, b, max_depth)
			b = mlo
		}
	}
	if b-a > 1 {
	// Shell short with gap 6
		for i in a+6..<b {
			if it->less(i, i-6) {
				it->swap(i, i-6)
			}
		}
		_insertion_sort(it, a, b)
	}
}

/*
Perform an insertion sort on a collection (private).

This procedure sorts the range `[a, b)` in the collection defined by `it` using insertion sort.

Inputs:
- `it`: The Interface defining the collection and sorting operations
- `a`: Start index of the range
- `b`: End index of the range (exclusive)
*/
@(private)
_insertion_sort :: proc(it: Interface, a, b: int) {
	for i in a+1..<b {
		for j := i; j > a && it->less(j, j-1); j -= 1 {
			it->swap(j, j-1)
		}
	}
}

/*
Sort a slice using bubble sort with a custom comparison function.

This procedure sorts the slice `array` in-place using bubble sort and the comparison function `f`.
It is a simple but inefficient (O(n²)) algorithm. Stable. Useful for small datasets or for educational purposes.

Note: Bubble sort repeatedly steps through the list, compares adjacent elements, and swaps them
if they are in the wrong order, until no swaps are needed.

Inputs:
- `array`: The slice to sort
- `f`: Comparison function returning -1, 0, or 1 for less than, equal, or greater than

Example:
    import "core:sort"
    import "core:fmt"

    bubble_sort_proc_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.bubble_sort_proc(data, sort.compare_ints)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
bubble_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil)
	count := len(array)

	init_j, last_j := 0, count-1

	for {
		init_swap, prev_swap := -1, -1

		for j in init_j..<last_j {
			if f(array[j], array[j+1]) > 0 {
				array[j], array[j+1] = array[j+1], array[j]
				prev_swap = j
				if init_swap == -1 {
					init_swap = j
				}
			}
		}

		if prev_swap == -1 {
			return
		}

		init_j = max(init_swap-1, 0)
		last_j = prev_swap
	}
}

/*
Sort a slice of ordered elements using bubble sort.

This procedure sorts the slice `array` in-place using bubble sort for types that support ordering.
It is a simple but inefficient (O(n²)) algorithm. Stable. Useful for small datasets or for educational purposes.

Note: Bubble sort repeatedly steps through the list, compares adjacent elements, and swaps them
if they are in the wrong order, until no swaps are needed.

Inputs:
- `array`: The slice to sort

Example:
    import "core:sort"
    import "core:fmt"

    bubble_sort_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.bubble_sort(data)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
bubble_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	count := len(array)

	init_j, last_j := 0, count-1

	for {
		init_swap, prev_swap := -1, -1

		for j in init_j..<last_j {
			if array[j] > array[j+1] {
				array[j], array[j+1] = array[j+1], array[j]
				prev_swap = j
				if init_swap == -1 {
					init_swap = j
				}
			}
		}

		if prev_swap == -1 {
			return
		}

		init_j = max(init_swap-1, 0)
		last_j = prev_swap
	}
}

/*
Sort a slice using quicksort with a custom comparison function.

This procedure sorts the slice `array` in-place using quicksort and the comparison function `f`.
Fast average-case performance (O(n log n)). Best for general-purpose sorting with good cache performance.

Note: Quicksort is a divide-and-conquer algorithm that selects a pivot and partitions the slice
into elements less than and greater than the pivot, recursively sorting the partitions.

Inputs:
- `array`: The slice to sort
- `f`: Comparison function returning -1, 0, or 1 for less than, equal, or greater than

Example:
    import "core:sort"
    import "core:fmt"

    quick_sort_proc_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.quick_sort_proc(data, sort.compare_ints)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
quick_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil)
	a := array
	n := len(a)
	if n < 2 {
		return
	}

	p := a[n/2]
	i, j := 0, n-1

	loop: for {
		for f(a[i], p) < 0 { i += 1 }
		for f(p, a[j]) < 0 { j -= 1 }

		if i >= j {
			break loop
		}

		a[i], a[j] = a[j], a[i]
		i += 1
		j -= 1
	}

	quick_sort_proc(a[0:i], f)
	quick_sort_proc(a[i:n], f)
}

/*
Sort a slice of ordered elements using quicksort.

This procedure sorts the slice `array` in-place using quicksort for types that support ordering.
Fast average-case performance (O(n log n)). Best for general-purpose sorting with good cache performance.

Note: Quicksort is a divide-and-conquer algorithm that selects a pivot and partitions the slice
into elements less than and greater than the pivot, recursively sorting the partitions.

Inputs:
- `array`: The slice to sort

Example:
    import "core:sort"
    import "core:fmt"

    quick_sort_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.quick_sort(data)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
quick_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	a := array
	n := len(a)
	if n < 2 {
		return
	}

	p := a[n/2]
	i, j := 0, n-1

	loop: for {
		for a[i] < p { i += 1 }
		for p < a[j] { j -= 1 }

		if i >= j {
			break loop
		}

		a[i], a[j] = a[j], a[i]
		i += 1
		j -= 1
	}

	quick_sort(a[0:i])
	quick_sort(a[i:n])
}

/*
Compute the base-2 logarithm of an integer (private).

This procedure calculates the floor of the base-2 logarithm of `x`, used internally for sorting algorithms.

Inputs:
- `x`: The input integer

Returns:
- The floor of log2(x)
*/
_log2 :: proc(x: int) -> int {
	res := 0
	for n := x; n != 0; n >>= 1 {
		res += 1
	}
	return res
}

/*
Sort a slice using merge sort with a custom comparison function.

This procedure sorts the slice `array` in-place using merge sort and the comparison function `f`.
Merge sort is stable, preserving the order of equal elements. O(n log n) complexity, requiring extra memory.
Ideal for linked lists or when stability is needed.

Note: Merge sort is a divide-and-conquer algorithm that recursively divides the slice into halves,
sorts them, and merges the sorted halves while maintaining stability.

Inputs:
- `array`: The slice to sort
- `f`: Comparison function returning -1, 0, or 1 for less than, equal, or greater than

Example:
    import "core:sort"
    import "core:fmt"

    merge_sort_proc_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.merge_sort_proc(data, sort.compare_ints)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
merge_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	merge :: proc(a: A, start, mid, end: int, f: proc(T, T) -> int) {
		s, m := start, mid

		s2 := m + 1
		if f(a[m], a[s2]) <= 0 {
			return
		}

		for s <= m && s2 <= end {
			if f(a[s], a[s2]) <= 0 {
				s += 1
			} else {
				v := a[s2]
				i := s2

				for i != s {
					a[i] = a[i-1]
					i -= 1
				}
				a[s] = v

				s  += 1
				m  += 1
				s2 += 1
			}
		}
	}
	internal_sort :: proc(a: A, l, r: int, f: proc(T, T) -> int) {
		if l < r {
			m := l + (r - l) / 2

			internal_sort(a, l, m, f)
			internal_sort(a, m+1, r, f)
			merge(a, l, m, r, f)
		}
	}

	internal_sort(array, 0, len(array)-1, f)
}

/*
Sort a slice of ordered elements using merge sort.

This procedure sorts the slice `array` in-place using merge sort for types that support ordering.
Merge sort is stable, preserving the order of equal elements. O(n log n) complexity, requiring extra memory.
Ideal for linked lists or when stability is needed.

Note: Merge sort is a divide-and-conquer algorithm that recursively divides the slice into halves,
sorts them, and merges the sorted halves while maintaining stability.

Inputs:
- `array`: The slice to sort

Example:
    import "core:sort"
    import "core:fmt"

    merge_sort_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.merge_sort(data)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
merge_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	merge :: proc(a: A, start, mid, end: int) {
		s, m := start, mid

		s2 := m + 1
		if a[m] <= a[s2] {
			return
		}

		for s <= m && s2 <= end {
			if a[s] <= a[s2] {
				s += 1
			} else {
				v := a[s2]
				i := s2

				for i != s {
					a[i] = a[i-1]
					i -= 1
				}
				a[s] = v

				s  += 1
				m  += 1
				s2 += 1
			}
		}
	}
	internal_sort :: proc(a: A, l, r: int) {
		if l < r {
			m := l + (r - l) / 2

			internal_sort(a, l, m)
			internal_sort(a, m+1, r)
			merge(a, l, m, r)
		}
	}

	internal_sort(array, 0, len(array)-1)
}

/*
Sort a slice using heap sort with a custom comparison function.

This procedure sorts the slice `array` in-place using heap sort and the comparison function `f`.
O(n log n) complexity, not stable, in-place but with poor cache locality. Suitable for environments
with limited memory or when constant-time removal of largest/smallest elements is needed.

Note: Heap sort builds a max-heap from the slice, repeatedly extracts the maximum element,
and places it at the end, reducing the heap size until sorted.

Inputs:
- `array`: The slice to sort
- `f`: Comparison function returning -1, 0, or 1 for less than, equal, or greater than

Example:
    import "core:sort"
    import "core:fmt"

    heap_sort_proc_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.heap_sort_proc(data, sort.compare_ints)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
heap_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	sift_proc :: proc(a: A, pi: int, n: int, f: proc(T, T) -> int) #no_bounds_check {
		p := pi
		v := a[p]
		m := p*2 + 1
		for m <= n {
			if (m < n) && f(a[m+1], a[m]) > 0 {
				m += 1
			}
			if f(v, a[m]) >= 0 {
				break
			}
			a[p] = a[m]
			p = m
			m += m+1
			a[p] = v
		}
	}

	n := len(array)
	if n == 0 {
		return
	}

	for i := n/2; i >= 0; i -= 1 {
		sift_proc(array, i, n-1, f)
	}

	for i := n-1; i >= 1; i -= 1 {
		array[0], array[i] = array[i], array[0]
		sift_proc(array, 0, i-1, f)
	}
}

/*
Sort a slice of ordered elements using heap sort.

This procedure sorts the slice `array` in-place using heap sort for types that support ordering.
Suitable for environments with limited memory or when constant-time removal of largest/smallest elements is needed.

Note: Heap sort builds a max-heap from the slice, repeatedly extracts the maximum element,
and places it at the end, reducing the heap size until sorted.

Inputs:
- `array`: The slice to sort

Example:
    import "core:sort"
    import "core:fmt"

    heap_sort_example :: proc() {
        data := []int{5, 2, 8, 1, 9}
        sort.heap_sort(data)
        fmt.println(data)
    }

Output:
    [1, 2, 5, 8, 9]
*/
heap_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	sift :: proc(a: A, pi: int, n: int) #no_bounds_check {
		p := pi
		v := a[p]
		m := p*2 + 1
		for m <= n {
			if (m < n) && (a[m+1] > a[m]) {
				m += 1
			}
			if v >= a[m] {
				break
			}
			a[p] = a[m]
			p = m
			m += m+1
			a[p] = v
		}
	}

	n := len(array)
	if n == 0 {
		return
	}

	for i := n/2; i >= 0; i -= 1 {
		sift(array, i, n-1)
	}

	for i := n-1; i >= 1; i -= 1 {
		array[0], array[i] = array[i], array[0]
		sift(array, 0, i-1)
	}
}

/*
Compare two boolean values.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First boolean value
- `b`: Second boolean value

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

	compare_bools_example :: proc() {
        Task :: struct {
            name: string,
            is_completed: bool,
        }
        tasks := []Task{
            {"Review code", false},
			{"Send email", true},
            {"Watch HR Training", false},
        }
        sort.quick_sort_proc(tasks, proc(a, b: Task) -> int {
            return sort.compare_bools(a.is_completed, b.is_completed)
        })

        fmt.println("Completed:")
        for task in tasks {
            fmt.printfln("%s, %t",task.name, task.is_completed)
        }
    }

Output:
	Completed:
	Watch HR Training, false
	Review code, false
	Send email, true
*/
compare_bools :: proc(a, b: bool) -> int {
	switch {
	case !a && b: return -1
	case a && !b: return +1
	}
	return 0
}

/*
Compare two integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First integer
- `b`: Second integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_ints_example :: proc() {
        data := []int{2, 8, 1, -5}
        sort.quick_sort_proc(data, sort.compare_ints)
        fmt.println(data)
    }

Output:
    [-5, 1, 2, 8]
*/
compare_ints :: proc(a, b: int) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}

/*
Compare two unsigned integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.

Inputs:
- `a`: First unsigned integer
- `b`: Second unsigned integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_uints_example :: proc() {
        data := []uint{10, 3, 7, 1}
        sort.quick_sort_proc(data, sort.compare_uints)
        fmt.println(data)
    }

Output:
    [1, 3, 7, 10]
*/
compare_uints :: proc(a, b: uint) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 8-bit unsigned integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 8-bit unsigned integer
- `b`: Second 8-bit unsigned integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_u8s_example :: proc() {
        data := []u8{50, 20, 80, 10}
        sort.quick_sort_proc(data, sort.compare_u8s)
        fmt.println(data)
    }

Output:
    [10, 20, 50, 80]
*/
compare_u8s :: proc(a, b: u8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 16-bit unsigned integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 16-bit unsigned integer
- `b`: Second 16-bit unsigned integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_u16s_example :: proc() {
        data := []u16{500, 200, 800, 100}
        sort.quick_sort_proc(data, sort.compare_u16s)
        fmt.println(data)
    }

Output:
    [100, 200, 500, 800]
*/
compare_u16s :: proc(a, b: u16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 32-bit unsigned integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 32-bit unsigned integer
- `b`: Second 32-bit unsigned integer

Returns:
- Comparison result (-1, 0, or 1)
*/
compare_u32s :: proc(a, b: u32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 64-bit unsigned integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 64-bit unsigned integer
- `b`: Second 64-bit unsigned integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_u64s_example :: proc() {
        data := []u64{50000, 20000, 80000, 10000}
        sort.quick_sort_proc(data, sort.compare_u64s)
        fmt.println(data)
    }

Output:
    [10000, 20000, 50000, 80000]
*/
compare_u64s :: proc(a, b: u64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 8-bit signed integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 8-bit signed integer
- `b`: Second 8-bit signed integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_i8s_example :: proc() {
        data := []i8{50, -20, 80, -10}
        sort.quick_sort_proc(data, sort.compare_i8s)
        fmt.println(data)
    }

Output:
    [-20, -10, 50, 80]
*/
compare_i8s :: proc(a, b: i8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 16-bit signed integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 16-bit signed integer
- `b`: Second 16-bit signed integer

Returns:
- Comparison result (-1, 0, or 1)

	compare_i16s_example :: proc() {
        data := []i16{500, -200, 800, -100}
        sort.quick_sort_proc(data, sort.compare_i16s)
        fmt.println(data)
    }

Output:
    [-200, -100, 500, 800]
*/
compare_i16s :: proc(a, b: i16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 32-bit signed integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 32-bit signed integer
- `b`: Second 32-bit signed integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
	compare_i32s_example :: proc() {
        data := []i32{5000, -2000, 8000, -1000}
        sort.quick_sort_proc(data, sort.compare_i32s)
        fmt.println(data)
    }

Output:
    [-2000, -1000, 5000, 8000]
*/
compare_i32s :: proc(a, b: i32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 64-bit signed integers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 64-bit signed integer
- `b`: Second 64-bit signed integer

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_i64s_example :: proc() {
        data := []i64{50000, -20000, 80000, -10000}
        sort.quick_sort_proc(data, sort.compare_i64s)
        fmt.println(data)
    }

Output:
    [-20000, -10000, 50000, 80000]
*/
compare_i64s :: proc(a, b: i64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compare two 32-bit floating-point numbers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 32-bit float
- `b`: Second 32-bit float

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

compare_f32s_example :: proc() {
    data := []f32{2.5, 2.2, 2.8}
    sort.quick_sort_proc(data, sort.compare_f32s)
    fmt.println(data)
}

Output:
	[2.2, 2.5, 2.8]
*/
compare_f32s :: proc(a, b: f32) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}

/*
Compare two 64-bit floating-point numbers.

This procedure compares `a` and `b`, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Inputs:
- `a`: First 64-bit float
- `b`: Second 64-bit float

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

	compare_f64s_example :: proc() {
		data := []f64{1.00000000002, 1.00000000008, 1.00000000001}
		sort.quick_sort_proc(data, sort.compare_f64s)
		fmt.println(data)
	}

Output:
    [1.00000000001, 1.00000000002, 1.00000000008]
*/
compare_f64s :: proc(a, b: f64) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}

/*
Compare two strings lexicographically.

This procedure compares `a` and `b` based on their byte sequences, returning -1 if `a` is less than `b`, 0 if equal, or 1 if greater.
It is designed for use with `*_sort_proc` procedures (e.g., `quick_sort_proc`, `merge_sort_proc`)
as a comparison function to determine the ordering of elements.

Note: A string byte sequence is the sequence of bytes representing the string's characters,
typically in UTF-8 encoding, compared byte-by-byte to determine lexicographical order.

Inputs:
- `a`: First string
- `b`: Second string

Returns:
- Comparison result (-1, 0, or 1)

Example:
    import "core:sort"
    import "core:fmt"

    compare_strings_example :: proc() {
        data := []string{"crumpet", "cake", "carrot", "crape",}
        sort.quick_sort_proc(data, sort.compare_strings)
        fmt.println(data)
    }

Output:
    ["cake", "carrot", "crape", "crumpet"]
*/
compare_strings :: proc(a, b: string) -> int {
	x := transmute(mem.Raw_String)a
	y := transmute(mem.Raw_String)b

	ret := mem.compare_byte_ptrs(x.data, y.data, min(x.len, y.len))
	if ret == 0 && x.len != y.len {
		return -1 if x.len < y.len else +1
	}
	return ret
}