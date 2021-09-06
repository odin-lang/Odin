package slice

import "core:intrinsics"
_ :: intrinsics

ORD :: intrinsics.type_is_ordered

Ordering :: enum {
	Less    = -1,
	Equal   =  0,
	Greater = +1,
}

cmp :: proc(a, b: $E) -> Ordering where ORD(E) {
	switch {
	case a < b:
		return .Less
	case a > b:
		return .Greater
	}
	return .Equal
}

cmp_proc :: proc($E: typeid) -> (proc(E, E) -> Ordering) where ORD(E) {
	return proc(a, b: E) -> Ordering {
		switch {
		case a < b:
			return .Less
		case a > b:
			return .Greater
		}
		return .Equal
	}
}

// sort sorts a slice
// This sort is not guaranteed to be stable
sort :: proc(data: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort(data, 0, n, _max_depth(n))
		}
	}
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort_less(data, 0, n, _max_depth(n), less)
		}
	}
}

sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort_cmp(data, 0, n, _max_depth(n), cmp)
		}
	}
}

is_sorted :: proc(array: $T/[]$E) -> bool where ORD(E) {
	for i := len(array)-1; i > 0; i -= 1 {
		if array[i] < array[i-1] {
			return false
		}
	}
	return true
}

is_sorted_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if less(array[i], array[i-1]) {
			return false
		}
	}
	return true
}

is_sorted_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if cmp(array[i], array[i-1]) == .Equal {
			return false
		}
	}
	return true
}



reverse_sort :: proc(data: $T/[]$E) where ORD(E) {
	sort_by(data, proc(i, j: E) -> bool {
		return j < i
	})
}


reverse_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) where ORD(E) {
	context._internal = rawptr(less)
	sort_by(data, proc(i, j: E) -> bool {
		k := (proc(i, j: E) -> bool)(context._internal)
		return k(j, i)
	})
}

reverse_sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) where ORD(E) {
	context._internal = rawptr(cmp)
	sort_by_cmp(data, proc(i, j: E) -> Ordering {
		k := (proc(i, j: E) -> Ordering)(context._internal)
		return k(j, i)
	})
}


// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	context._internal = rawptr(key)
	sort_by(data, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context._internal)
		return k(i) < k(j)
	})
}

reverse_sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	context._internal = rawptr(key)
	sort_by(data, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context._internal)
		return k(j) < k(i)
	})
}

is_sorted_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) -> bool where ORD(K) {
	for i := len(array)-1; i > 0; i -= 1 {
		if key(array[i]) < key(array[i-1]) {
			return false
		}
	}
	return true
}



@(private)
_max_depth :: proc(n: int) -> int { // 2*ceil(log2(n+1))
	depth: int
	for i := n; i > 0; i >>= 1 {
		depth += 1
	}
	return depth * 2
}

@(private)
_quick_sort :: proc(data: $T/[]$E, a, b, max_depth: int) where ORD(E) {
	median3 :: proc(data: T, m1, m0, m2: int) {
		if data[m1] < data[m0] {
			swap(data, m1, m0)
		}
		if data[m2] < data[m1] {
			swap(data, m2, m1)
			if data[m1] < data[m0] {
				swap(data, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, lo, lo+s, lo+s*2)
			median3(data, m, m-s, m+s)
			median3(data, hi-1, hi-1-s, hi-1-s*2)
		}
		median3(data, lo, m, hi-1)


		pivot := lo
		a, c := lo+1, hi-1

		for ; a < c && data[a] < data[pivot]; a += 1 {
		}
		b := a

		for {
			for ; b < c && !(data[pivot] < data[b]); b += 1 { // data[b] <= pivot
			}
			for ; b < c && data[pivot] < data[c-1]; c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			swap(data, b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if !(data[pivot] < data[hi-1]) {
				swap(data, c, hi-1)
				c += 1
				dups += 1
			}
			if !(data[b-1] < data[pivot]) {
				b -= 1
				dups += 1
			}

			if !(data[m] < data[pivot]) {
				swap(data, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !(data[b-1] < data[pivot]); b -= 1 {
				}
				for ; a < b && data[a] < data[pivot]; a += 1 {
				}
				if a >= b {
					break
				}
				swap(data, a, b-1)
				a += 1
				b -= 1
			}
		}
		swap(data, pivot, b-1)
		return b-1, c
	}


	a, b, max_depth := a, b, max_depth

	if b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			_heap_sort(data, a, b)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, a, b)
		if mlo-a < b-mhi {
			_quick_sort(data, a, mlo, max_depth)
			a = mhi
		} else {
			_quick_sort(data, mhi, b, max_depth)
			b = mlo
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if data[i] < data[i-6] {
				swap(data, i, i-6)
			}
		}
		_insertion_sort(data, a, b)
	}
}

@(private)
_insertion_sort :: proc(data: $T/[]$E, a, b: int) where ORD(E) {
	for i in a+1..<b {
		for j := i; j > a && data[j] < data[j-1]; j -= 1 {
			swap(data, j, j-1)
		}
	}
}

@(private)
_heap_sort :: proc(data: $T/[]$E, a, b: int) where ORD(E) {
	sift_down :: proc(data: T, lo, hi, first: int) {
		root := lo
		for {
			child := 2*root + 1
			if child >= hi {
				break
			}
			if child+1 < hi && data[first+child] < data[first+child+1] {
				child += 1
			}
			if !(data[first+root] < data[first+child]) {
				return
			}
			swap(data, first+root, first+child)
			root = child
		}
	}


	first, lo, hi := a, 0, b-a

	for i := (hi-1)/2; i >= 0; i -= 1 {
		sift_down(data, i, hi, first)
	}

	for i := hi-1; i >= 0; i -= 1 {
		swap(data, first, first+i)
		sift_down(data, lo, i, first)
	}
}






@(private)
_quick_sort_less :: proc(data: $T/[]$E, a, b, max_depth: int, less: proc(i, j: E) -> bool) {
	median3 :: proc(data: T, m1, m0, m2: int, less: proc(i, j: E) -> bool) {
		if less(data[m1], data[m0]) {
			swap(data, m1, m0)
		}
		if less(data[m2], data[m1]) {
			swap(data, m2, m1)
			if less(data[m1], data[m0]) {
				swap(data, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int, less: proc(i, j: E) -> bool) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, lo, lo+s, lo+s*2, less)
			median3(data, m, m-s, m+s, less)
			median3(data, hi-1, hi-1-s, hi-1-s*2, less)
		}
		median3(data, lo, m, hi-1, less)

		pivot := lo
		a, c := lo+1, hi-1

		for ; a < c && less(data[a], data[pivot]); a += 1 {
		}
		b := a

		for {
			for ; b < c && !less(data[pivot], data[b]); b += 1 { // data[b] <= pivot
			}
			for ; b < c && less(data[pivot], data[c-1]); c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			swap(data, b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if !less(data[pivot], data[hi-1]) {
				swap(data, c, hi-1)
				c += 1
				dups += 1
			}
			if !less(data[b-1], data[pivot]) {
				b -= 1
				dups += 1
			}

			if !less(data[m], data[pivot]) {
				swap(data, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !less(data[b-1], data[pivot]); b -= 1 {
				}
				for ; a < b && less(data[a], data[pivot]); a += 1 {
				}
				if a >= b {
					break
				}
				swap(data, a, b-1)
				a += 1
				b -= 1
			}
		}
		swap(data, pivot, b-1)
		return b-1, c
	}


	a, b, max_depth := a, b, max_depth

	if b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			_heap_sort_less(data, a, b, less)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, a, b, less)
		if mlo-a < b-mhi {
			_quick_sort_less(data, a, mlo, max_depth, less)
			a = mhi
		} else {
			_quick_sort_less(data, mhi, b, max_depth, less)
			b = mlo
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if less(data[i], data[i-6]) {
				swap(data, i, i-6)
			}
		}
		_insertion_sort_less(data, a, b, less)
	}
}

@(private)
_insertion_sort_less :: proc(data: $T/[]$E, a, b: int, less: proc(i, j: E) -> bool) {
	for i in a+1..<b {
		for j := i; j > a && less(data[j], data[j-1]); j -= 1 {
			swap(data, j, j-1)
		}
	}
}

@(private)
_heap_sort_less :: proc(data: $T/[]$E, a, b: int, less: proc(i, j: E) -> bool) {
	sift_down :: proc(data: T, lo, hi, first: int, less: proc(i, j: E) -> bool) {
		root := lo
		for {
			child := 2*root + 1
			if child >= hi {
				break
			}
			if child+1 < hi && less(data[first+child], data[first+child+1]) {
				child += 1
			}
			if !less(data[first+root], data[first+child]) {
				return
			}
			swap(data, first+root, first+child)
			root = child
		}
	}


	first, lo, hi := a, 0, b-a

	for i := (hi-1)/2; i >= 0; i -= 1 {
		sift_down(data, i, hi, first, less)
	}

	for i := hi-1; i >= 0; i -= 1 {
		swap(data, first, first+i)
		sift_down(data, lo, i, first, less)
	}
}






@(private)
_quick_sort_cmp :: proc(data: $T/[]$E, a, b, max_depth: int, cmp: proc(i, j: E) -> Ordering) {
	median3 :: proc(data: T, m1, m0, m2: int, cmp: proc(i, j: E) -> Ordering) {
		if cmp(data[m1], data[m0]) == .Less {
			swap(data, m1, m0)
		}
		if cmp(data[m2], data[m1]) == .Less {
			swap(data, m2, m1)
			if cmp(data[m1], data[m0]) == .Less {
				swap(data, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int, cmp: proc(i, j: E) -> Ordering) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, lo, lo+s, lo+s*2, cmp)
			median3(data, m, m-s, m+s, cmp)
			median3(data, hi-1, hi-1-s, hi-1-s*2, cmp)
		}
		median3(data, lo, m, hi-1, cmp)

		pivot := lo
		a, c := lo+1, hi-1

		for ; a < c && cmp(data[a], data[pivot]) == .Less; a += 1 {
		}
		b := a

		for {
			for ; b < c && cmp(data[pivot], data[b]) >= .Equal; b += 1 { // data[b] <= pivot
			}
			for ; b < c && cmp(data[pivot], data[c-1]) == .Less; c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			swap(data, b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if cmp(data[pivot], data[hi-1]) != .Less {
				swap(data, c, hi-1)
				c += 1
				dups += 1
			}
			if cmp(data[b-1], data[pivot]) != .Less {
				b -= 1
				dups += 1
			}

			if cmp(data[m], data[pivot]) != .Less {
				swap(data, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && cmp(data[b-1], data[pivot]) >= .Equal; b -= 1 {
				}
				for ; a < b && cmp(data[a], data[pivot]) == .Less; a += 1 {
				}
				if a >= b {
					break
				}
				swap(data, a, b-1)
				a += 1
				b -= 1
			}
		}
		swap(data, pivot, b-1)
		return b-1, c
	}


	a, b, max_depth := a, b, max_depth

	if b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			_heap_sort_cmp(data, a, b, cmp)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, a, b, cmp)
		if mlo-a < b-mhi {
			_quick_sort_cmp(data, a, mlo, max_depth, cmp)
			a = mhi
		} else {
			_quick_sort_cmp(data, mhi, b, max_depth, cmp)
			b = mlo
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if cmp(data[i], data[i-6]) == .Less {
				swap(data, i, i-6)
			}
		}
		_insertion_sort_cmp(data, a, b, cmp)
	}
}

@(private)
_insertion_sort_cmp :: proc(data: $T/[]$E, a, b: int, cmp: proc(i, j: E) -> Ordering) {
	for i in a+1..<b {
		for j := i; j > a && cmp(data[j], data[j-1]) == .Less; j -= 1 {
			swap(data, j, j-1)
		}
	}
}

@(private)
_heap_sort_cmp :: proc(data: $T/[]$E, a, b: int, cmp: proc(i, j: E) -> Ordering) {
	sift_down :: proc(data: T, lo, hi, first: int, cmp: proc(i, j: E) -> Ordering) {
		root := lo
		for {
			child := 2*root + 1
			if child >= hi {
				break
			}
			if child+1 < hi && cmp(data[first+child], data[first+child+1]) == .Less {
				child += 1
			}
			if cmp(data[first+root], data[first+child]) >= .Equal {
				return
			}
			swap(data, first+root, first+child)
			root = child
		}
	}


	first, lo, hi := a, 0, b-a

	for i := (hi-1)/2; i >= 0; i -= 1 {
		sift_down(data, i, hi, first, cmp)
	}

	for i := hi-1; i >= 0; i -= 1 {
		swap(data, first, first+i)
		sift_down(data, lo, i, first, cmp)
	}
}



