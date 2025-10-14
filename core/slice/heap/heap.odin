// A generic in-place max heap on a slice for any type.
package heap

/*
	Copyright 2022 Dale Weiler <weilercdale@gmail.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Dale Weiler: Initial implementation
*/

/*
	Constructs a max heap in slice given by data with comparator. A max heap is
	a range of elements which has the following properties:

	1. With N = len(data), for all 0 < i < N, data[(i - 1) / 2] does not compare
	   less than data[i].

	2. A new element can be added using push in O(log n) time.

	3. The first element can be removed using pop in O(log n) time.

	The comparator compares elements of type T and can be used to construct a
	max heap (less than) or min heap (greater than) for T.
*/
make :: proc(data: []$T, less: proc(a, b: T) -> bool) {
	// amoritize length lookup
	length := len(data)
	if length <= 1 {
		return
	}

	// start from data parent, no need to consider children
	for start := (length - 2) / 2; start >= 0; start -= 1 {
		sift_down(data, less, start)
	}
}

/*
	Inserts the element at the position len(data)-1 into the max heap with
	comparator.

	At most log(N) comparisons where N = len(data) will be performed.
*/
push :: proc(data: []$T, less: proc(a, b: T) -> bool) {
	sift_up(data, less)
}

/*
	Swaps the value in position data[0] and the value in data[len(data)-1] and
	makes subrange [0, len(data)-1) into a heap. This has the effect of removing
	the first element from the heap.

	At most 2 * log(N) comparisons where N = len(data) will be performed.
*/
pop :: proc(data: []$T, less: proc(a, b: T) -> bool) {
	length := len(data)
	if length <= 1 {
		return
	}

	last := length

	// create a hole at 0
	top := data[0]
	hole := floyd_sift_down(data, less)
	last -= 1

	if hole == last {
		data[hole] = top
	} else {
		data[hole] = data[last]
		hole += 1
		data[last] = top
		sift_up(data[:hole], less)
	}
}

/*
	Converts the max heap into a sorted range in ascending order. The resulting
	slice will no longer be a heap after this.

	At most 2 * N * log(N) comparisons where N = len(data) will be performed.
*/
sort :: proc(data: []$T, less: proc(a, b: T) -> bool) {
	for n := len(data); n >= 1; n -= 1 {
		pop(data[:n], less)
	}
}

/*
	Examines the slice and finds the largest range which is a max-heap. Elements
	are compared with user-supplied comparison procedure.

	This returns the upper bound of the largest range in the slice which is a
	max heap. That is, the last index for which data is a max heap.

	At most O(n) comparisons where N = len(data) will be performed.
*/
is_heap_until :: proc(data: []$T, less: proc(a, b: T) -> bool) -> int {
	length := len(data)
	a := 0
	b := 1
	for b < length {
		if less(data[a], data[b]) {
			return b
		}
		b += 1
		if b == length || less(data[a], data[b]) {
			return b
		}
		a += 1
		b = 2 * a + 1
	}
	return length
}

/*
	Checks if a given slice is a max heap.

	At most O(n) comparisons where N = len(data) will be performed.
*/
is_heap :: #force_inline proc(data: []$T, less: proc(a, b: T) -> bool) -> bool {
	return is_heap_until(data, less) == len(data)
}

@(private="file")
floyd_sift_down :: proc(data: []$T, less: proc(a, b: T) -> bool) -> int {
	length := len(data)
	assert(length >= 2)

	hole := 0
	child := 0
	index := 0
	for {
		index += child + 1
		child = 2 * child + 1
		if child + 1 < length && less(data[index], data[index + 1]) {
			child += 1
			index += 1
		}

		data[hole] = data[index]
		hole = index

		if child > (length - 2) / 2 {
			return hole
		}
	}

	unreachable()
}

@(private="file")
sift_down :: proc(data: []$T, less: proc(a, b: T) -> bool, start: int) {
	start := start
	child := start

	// amoritize length lookup
	length := len(data)

	// left child of start is at 2 * start + 1
	// right child of start is at 2 * start + 2
	if length < 2 || (length - 2) / 2 < child {
		return
	}

	child = 2 * child + 1

	if child + 1 < length && less(data[child], data[child + 1]) {
		// right child exists and is greater than left child
		child += 1
	}

	// check if in heap order
	if less(data[child], data[start]) {
		// start is larger than its largest child
		return
	}

	top := data[start]
	for {
		// not in heap order, swap parent with its largest child
		data[start] = data[child]
		start = child

		if (length - 2) / 2 < child {
			break
		}

		// recompute child based off updated parent
		child = 2 * child + 1

		if child + 1 < length && less(data[child], data[child + 1]) {
			// right child exists and is greater than left child
			child += 1
		}

		// check if we are in heap order
		if less(data[child], top) {
			break
		}
	}

	data[start] = top
}

@(private="file")
sift_up :: proc(data: []$T, less: proc(a, b: T) -> bool) {
	// amoritize length lookup
	length := len(data)

	if length <= 1 {
		return
	}

	last := length
	length = (length - 2) / 2
	index := length
	last -= 1
	if less(data[index], data[last]) {
		top := data[last]
		for {
			data[last] = data[index]
			last = index
			if length == 0 {
				break
			}
			length = (length - 1) / 2
			index = length
			if !less(data[index], top) {
				break
			}
		}
		data[last] = top
	}
}