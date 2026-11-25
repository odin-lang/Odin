// A sorting interface and algorithms.
package sort

import "core:mem"
import "core:slice"
import "base:intrinsics"

_ :: slice
ORD :: intrinsics.type_is_ordered

/*
A generic interface describing a sequence of elements that can be sorted.

It provides the operations the sorting procedures use to inspect and reorder
the elements: `len` reports the number of elements, `less` compares two
elements, and `swap` exchanges two elements. The underlying data lives in
`collection`.

Use `slice_interface` to obtain an `Interface` for a slice, or
`reverse_interface` to wrap an `Interface` so that it is ordered in reverse.
*/
Interface :: struct {
	len:  proc(it: Interface) -> int,
	less: proc(it: Interface, i, j: int) -> bool,
	swap: proc(it: Interface, i, j: int),
	collection: rawptr,
}

/*
Sorts the elements of an `Interface` in place, keeping equal elements in their original order.

Inputs:
- it: The `Interface` to sort.

Example:

	import "core:fmt"
	import "core:sort"

	sort_example :: proc() {
		data := []int{5, 2, 8, 1, 9}
		sort.sort(sort.slice_interface(&data))
		fmt.println(data)
	}

Output:

	[1, 2, 5, 8, 9]

*/
sort :: proc(it: Interface) {
	_stable_sort(it, 0, it->len())
}

/*
Creates an `Interface` over the given slice of ordered elements, for use with
the sorting procedures.

The elements are compared with the `<` operator, so the resulting sort is in
ascending order.

Inputs:
- s: A pointer to the slice to wrap.

Returns:
- An `Interface` that describes the elements of `s`.

Example:

	import "core:fmt"
	import "core:sort"

	slice_interface_example :: proc() {
		data := []int{3, 1, 2}
		it := sort.slice_interface(&data)
		fmt.println(sort.is_sorted(it))
		sort.sort(it)
		fmt.println(data)
	}

Output:

	false
	[1, 2, 3]

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
Wraps an `Interface` so that the ordering is reversed, making the sorting
procedures sort the elements in descending order.

Inputs:
- it: A pointer to the `Interface` to reverse.

Returns:
- A new `Interface` that reverses the ordering of `it`.

Example:

	import "core:fmt"
	import "core:sort"

	reverse_interface_example :: proc() {
		data := []int{5, 2, 8}
		s := sort.slice_interface(&data)
		sort.sort(sort.reverse_interface(&s))
		fmt.println(data)
	}

Output:

	[8, 5, 2]

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
Sorts the elements of an `Interface` in descending order, in place, keeping equal elements in their original order.

Inputs:
- it: The `Interface` to sort.

Example:

	import "core:fmt"
	import "core:sort"

	reverse_sort_example :: proc() {
		data := []int{5, 2, 8, 1}
		sort.reverse_sort(sort.slice_interface(&data))
		fmt.println(data)
	}

Output:

	[8, 5, 2, 1]

*/
reverse_sort :: proc(it: Interface) {
	it := it
	sort(reverse_interface(&it))
}

/*
Sorts the elements of an `Interface` in place, keeping equal elements in their original order.

Inputs:
- it: The `Interface` to sort.

Example:

	import "core:fmt"
	import "core:sort"

	stable_sort_example :: proc() {
		data := []int{5, 2, 8, 1, 9}
		sort.stable_sort(sort.slice_interface(&data))
		fmt.println(data)
	}

Output:

	[1, 2, 5, 8, 9]

*/
stable_sort :: sort

/*
Sorts the elements of an `Interface` in descending order, in place, keeping equal elements in their original order.

Inputs:
- it: The `Interface` to sort.

Example:

	import "core:fmt"
	import "core:sort"

	reverse_stable_sort_example :: proc() {
		data := []int{5, 2, 8, 1}
		sort.reverse_stable_sort(sort.slice_interface(&data))
		fmt.println(data)
	}

Output:

	[8, 5, 2, 1]

*/
reverse_stable_sort :: reverse_sort

/*
Reports whether the elements of an `Interface` are in ascending order.

Inputs:
- it: The `Interface` to check.

Returns:
- `true` if the elements are sorted in ascending order, `false` otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	is_sorted_example :: proc() {
		a := []int{1, 2, 3}
		b := []int{3, 1, 2}
		fmt.println(sort.is_sorted(sort.slice_interface(&a)))
		fmt.println(sort.is_sorted(sort.slice_interface(&b)))
	}

Output:

	true
	false

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
Swaps `n` elements beginning at index `a` with the `n` elements beginning at
index `b`.

Inputs:
- it: The `Interface`.
- a: Start index of the first range to swap.
- b: Start index of the second range to swap.
- n: The number of elements to swap.

Example:

	import "core:fmt"
	import "core:sort"

	swap_range_example :: proc() {
		data := []int{1, 2, 3, 4}
		sort.swap_range(sort.slice_interface(&data), 0, 2, 2)
		fmt.println(data)
	}

Output:

	[3, 4, 1, 2]

*/
swap_range :: proc(it: Interface, a, b, n: int) {
	for i in 0..<n {
		it->swap(a+i, b+i)
	}
}

/*
Rotates the elements of an `Interface` in the range `[a, b)` so that the
element at index `m` becomes the first element of the range.

Inputs:
- it: The `Interface`.
- a: Start index of the range.
- m: The index whose element becomes first after the rotation.
- b: Exclusive end index of the range.

Example:

	import "core:fmt"
	import "core:sort"

	rotate_example :: proc() {
		data := []int{0, 1, 2, 3}
		sort.rotate(sort.slice_interface(&data), 0, 2, 4)
		fmt.println(data)
	}

Output:

	[2, 3, 0, 1]

*/
rotate :: proc(it: Interface, a, m, b: int) {
	if a == m || m == b {
		return
	}

	i := m - a
	j := b - m

	for i != j {
		if i > j {
			swap_range(it, m-i, m, j)
			i -= j
		} else {
			swap_range(it, m-i, m+j-i, i)
			j -= i
		}
	}
	swap_range(it, m-i, m, i)
}



@(private)
_heap_sort :: proc(it: Interface, a, b: int) {
	sift_down :: proc(it: Interface, root, n, first: int) {
		root := root
		for {
			child := 2*root + 1
			if child >= n {
				return
			}
			if child+1 < n && it->less(first+child, first+child+1) {
				child += 1
			}
			if !it->less(first+root, first+child) {
				return
			}
			it->swap(first+root, first+child)
			root = child
		}
	}

	n := b - a
	for i := (n-1)/2; i >= 0; i -= 1 {
		sift_down(it, i, n, a)
	}
	for i := n-1; i > 0; i -= 1 {
		it->swap(a, a+i)
		sift_down(it, 0, i, a)
	}
}

// NOTE(bill, 2026-11-25): A stable merge sort that only compares and swaps.
// It gathers items with distinct keys into a buffer inside the array, merges through it with swaps, and splits larger merges with rotations.
@(private)
_stable_sort :: proc(it: Interface, a, b: int) {
	INSERTION :: 32
	BLOCK     :: 8

	if _sorted_or_reversed(it, a, b) {
		return
	}

	n := b - a
	if n <= INSERTION {
		_insertion_sort(it, a, b)
		return
	}

	root := 1
	for root*root < n {
		root += 1
	}
	keys := _collect_keys(it, a, b, 2*root)

	for lo := a+keys; lo < b; lo += BLOCK {
		_insertion_sort(it, lo, min(lo+BLOCK, b))
	}
	for width := BLOCK; width < n-keys; width *= 2 {
		for lo := a+keys; lo+width < b; lo += 2*width {
			_merge(it, lo, lo+width, min(lo+2*width, b), a, keys)
		}
	}

	_heap_sort(it, a, a+keys)
	_merge(it, a, a+keys, b, a, 0)
}

@(private)
_sorted_or_reversed :: proc(it: Interface, a, b: int) -> bool {
	ascending  := true
	descending := true
	for i in a+1..<b {
		if it->less(i, i-1) {
			ascending = false
		} else {
			descending = false
		}
		if !(ascending || descending) {
			return false
		}
	}

	if descending {
		for i, j := a, b-1; i < j; i, j = i+1, j-1 {
			it->swap(i, j)
		}
	}
	return true
}

@(private)
_collect_keys :: proc(it: Interface, a, b: int, want: int) -> (keys: int) {
	SCAN :: 8

	h     := a
	limit := min(b, a + want*SCAN)

	keys = 1
	for i := a+1; i < limit && keys < want; i += 1 {
		r := _lower_bound(it, h, h+keys, i)
		if r < h+keys && !it->less(i, r) {
			continue
		}

		rotate(it, h, h+keys, i)
		r += i - keys - h
		h = i - keys

		rotate(it, r, i, i+1)
		keys += 1
	}

	rotate(it, a, h, h+keys)
	return
}

@(private)
_merge :: proc(it: Interface, a, mid, b: int, buffer, buffer_len: int) {
	if a == mid || mid == b || !it->less(mid, mid-1) {
		return
	}

	lo := _upper_bound(it, a, mid, mid)
	hi := _lower_bound(it, mid, b, mid-1)

	left  := mid - lo
	right := hi - mid

	switch {
	case left <= buffer_len && left <= right:
		_merge_left_through_buffer(it, lo, mid, hi, buffer)
		return
	case right <= buffer_len:
		_merge_right_through_buffer(it, lo, mid, hi, buffer)
		return
	}

	cut1, cut2: int
	if left >= right {
		cut1 = lo + left/2
		cut2 = _lower_bound(it, mid, hi, cut1)
	} else {
		cut2 = mid + right/2
		cut1 = _upper_bound(it, lo, mid, cut2)
	}

	rotate(it, cut1, mid, cut2)
	new_mid := cut1 + cut2 - mid

	_merge(it, lo, cut1, new_mid, buffer, buffer_len)
	_merge(it, new_mid, cut2, hi, buffer, buffer_len)
}

@(private)
_merge_left_through_buffer :: proc(it: Interface, lo, mid, hi: int, buffer: int) {
	left := mid - lo
	swap_range(it, buffer, lo, left)

	p   := buffer
	end := buffer + left
	q   := mid
	o   := lo
	for p < end && q < hi {
		if it->less(q, p) {
			it->swap(o, q)
			q += 1
		} else {
			it->swap(o, p)
			p += 1
		}
		o += 1
	}

	for p < end {
		it->swap(o, p)
		p += 1
		o += 1
	}
}

@(private)
_merge_right_through_buffer :: proc(it: Interface, lo, mid, hi: int, buffer: int) {
	right := hi - mid
	swap_range(it, buffer, mid, right)

	p := buffer + right - 1
	q := mid - 1
	o := hi - 1
	for p >= buffer && q >= lo {
		if it->less(p, q) {
			it->swap(o, q)
			q -= 1
		} else {
			it->swap(o, p)
			p -= 1
		}
		o -= 1
	}

	for p >= buffer {
		it->swap(o, p)
		p -= 1
		o -= 1
	}
}

@(private)
_lower_bound :: proc(it: Interface, a, b: int, key: int) -> int {
	lo := a
	hi := b
	for lo < hi {
		m := int(uint(lo+hi) >> 1)
		if it->less(m, key) {
			lo = m + 1
		} else {
			hi = m
		}
	}
	return lo
}

@(private)
_upper_bound :: proc(it: Interface, a, b: int, key: int) -> int {
	lo := a
	hi := b
	for lo < hi {
		m := int(uint(lo+hi) >> 1)
		if it->less(key, m) {
			hi = m
		} else {
			lo = m + 1
		}
	}
	return lo
}

@(private)
_insertion_sort :: proc(it: Interface, a, b: int) {
	for i in a+1..<b {
		for j := i; j > a && it->less(j, j-1); j -= 1 {
			it->swap(j, j-1)
		}
	}
}

/*
Sorts a slice in place using bubble sort, ordered by the given comparator.

The comparator `f` is called with two elements and must return a negative
number if the first is less than the second, `0` if they are equal, and a
positive number otherwise.

Inputs:
- array: The slice to sort.
- f: The comparator used to order the elements.

Example:

	import "core:fmt"
	import "core:sort"

	bubble_sort_proc_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.bubble_sort_proc(data, sort.compare_ints)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

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
Sorts a slice of ordered elements in place using bubble sort, in ascending
order.

Inputs:
- array: The slice to sort.

Example:

	import "core:fmt"
	import "core:sort"

	bubble_sort_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.bubble_sort(data)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

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
Sorts a slice in place, ordered by the given comparator.
It is the same sort as `slice.sort_by`.

The comparator `f` is called with two elements and must return a negative
number if the first is less than the second, `0` if they are equal, and a
positive number otherwise.

Inputs:
- array: The slice to sort.
- f: The comparator used to order the elements.

Example:

	import "core:fmt"
	import "core:sort"

	quick_sort_proc_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.quick_sort_proc(data, sort.compare_ints)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

*/
quick_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil)
	less :: proc(a, b: T, user_data: rawptr) -> bool {
		f := (proc(T, T) -> int)(user_data)
		return f(a, b) < 0
	}
	slice.sort_by_with_data(array, less, rawptr(f))
}

/*
Sorts a slice of ordered elements in place, in ascending order.
It is the same sort as `slice.sort`.

Inputs:
- array: The slice to sort.

Example:

	import "core:fmt"
	import "core:sort"

	quick_sort_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.quick_sort(data)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

*/
quick_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	slice.sort(array)
}

/*
Sorts a slice in place, ordered by the given comparator.
It is the same sort as `slice.stable_sort_by`.

The comparator `f` is called with two elements and must return a negative
number if the first is less than the second, `0` if they are equal, and a
positive number otherwise.

Inputs:
- array: The slice to sort.
- f: The comparator used to order the elements.

Example:

	import "core:fmt"
	import "core:sort"

	merge_sort_proc_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.merge_sort_proc(data, sort.compare_ints)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

*/
merge_sort_proc :: quick_sort_proc

/*
Sorts a slice of ordered elements in place, in ascending order.
It is the same sort as `slice.stable_sort`.

Inputs:
- array: The slice to sort.

Example:

	import "core:fmt"
	import "core:sort"

	merge_sort_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.merge_sort(data)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

*/
merge_sort :: quick_sort

/*
Sorts a slice in place using heap sort, ordered by the given comparator.

The comparator `f` is called with two elements and must return a negative
number if the first is less than the second, `0` if they are equal, and a
positive number otherwise.

Inputs:
- array: The slice to sort.
- f: The comparator used to order the elements.

Example:

	import "core:fmt"
	import "core:sort"

	heap_sort_proc_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.heap_sort_proc(data, sort.compare_ints)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

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
Sorts a slice of ordered elements in place using heap sort, in ascending
order.

Inputs:
- array: The slice to sort.

Example:

	import "core:fmt"
	import "core:sort"

	heap_sort_example :: proc() {
		data := []int{5, 3, 8, 1}
		sort.heap_sort(data)
		fmt.println(data)
	}

Output:

	[1, 3, 5, 8]

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
Compares two booleans for ordering, where `false` is considered less than
`true`.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_bools_example :: proc() {
		fmt.println(sort.compare_bools(false, true))
		fmt.println(sort.compare_bools(true, true))
		fmt.println(sort.compare_bools(true, false))
	}

Output:

	-1
	0
	1

*/
compare_bools :: proc(a, b: bool) -> int {
	switch {
	case !a && b: return -1
	case a && !b: return +1
	}
	return 0
}


/*
Compares two `int` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_ints_example :: proc() {
		fmt.println(sort.compare_ints(1, 2))
		fmt.println(sort.compare_ints(2, 2))
		fmt.println(sort.compare_ints(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_ints :: proc(a, b: int) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `uint` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_uints_example :: proc() {
		fmt.println(sort.compare_uints(1, 2))
		fmt.println(sort.compare_uints(2, 2))
		fmt.println(sort.compare_uints(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_uints :: proc(a, b: uint) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `u8` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_u8s_example :: proc() {
		fmt.println(sort.compare_u8s(1, 2))
		fmt.println(sort.compare_u8s(2, 2))
		fmt.println(sort.compare_u8s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_u8s :: proc(a, b: u8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `u16` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_u16s_example :: proc() {
		fmt.println(sort.compare_u16s(1, 2))
		fmt.println(sort.compare_u16s(2, 2))
		fmt.println(sort.compare_u16s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_u16s :: proc(a, b: u16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `u32` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_u32s_example :: proc() {
		fmt.println(sort.compare_u32s(1, 2))
		fmt.println(sort.compare_u32s(2, 2))
		fmt.println(sort.compare_u32s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_u32s :: proc(a, b: u32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `u64` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_u64s_example :: proc() {
		fmt.println(sort.compare_u64s(1, 2))
		fmt.println(sort.compare_u64s(2, 2))
		fmt.println(sort.compare_u64s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_u64s :: proc(a, b: u64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `i8` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_i8s_example :: proc() {
		fmt.println(sort.compare_i8s(-1, 2))
		fmt.println(sort.compare_i8s(2, 2))
		fmt.println(sort.compare_i8s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_i8s :: proc(a, b: i8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `i16` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_i16s_example :: proc() {
		fmt.println(sort.compare_i16s(-1, 2))
		fmt.println(sort.compare_i16s(2, 2))
		fmt.println(sort.compare_i16s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_i16s :: proc(a, b: i16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `i32` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_i32s_example :: proc() {
		fmt.println(sort.compare_i32s(-1, 2))
		fmt.println(sort.compare_i32s(2, 2))
		fmt.println(sort.compare_i32s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_i32s :: proc(a, b: i32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

/*
Compares two `i64` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_i64s_example :: proc() {
		fmt.println(sort.compare_i64s(-1, 2))
		fmt.println(sort.compare_i64s(2, 2))
		fmt.println(sort.compare_i64s(3, 2))
	}

Output:

	-1
	0
	1

*/
compare_i64s :: proc(a, b: i64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}




/*
Compares two `f32` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_f32s_example :: proc() {
		fmt.println(sort.compare_f32s(1.0, 2.0))
		fmt.println(sort.compare_f32s(2.0, 2.0))
		fmt.println(sort.compare_f32s(3.0, 2.0))
	}

Output:

	-1
	0
	1

*/
compare_f32s :: proc(a, b: f32) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}
/*
Compares two `f64` values for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_f64s_example :: proc() {
		fmt.println(sort.compare_f64s(1.0, 2.0))
		fmt.println(sort.compare_f64s(2.0, 2.0))
		fmt.println(sort.compare_f64s(3.0, 2.0))
	}

Output:

	-1
	0
	1

*/
compare_f64s :: proc(a, b: f64) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}
/*
Compares two strings lexicographically (byte-wise) for ordering.

Returns:
- A negative number if `a` is less than `b`, `0` if they are equal, and a
  positive number otherwise.

Example:

	import "core:fmt"
	import "core:sort"

	compare_strings_example :: proc() {
		fmt.println(sort.compare_strings("apple", "banana"))
		fmt.println(sort.compare_strings("apple", "apple"))
		fmt.println(sort.compare_strings("banana", "apple"))
	}

Output:

	-1
	0
	1

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
