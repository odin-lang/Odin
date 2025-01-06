#+private
package slice

import "base:intrinsics"
_ :: intrinsics

ORD :: intrinsics.type_is_ordered

Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}

_quick_sort_general :: proc(data: $T/[]$E, a, b, max_depth: int, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}

	insertion_sort :: proc(data: $T/[]$E, a, b: int, call: P) #no_bounds_check {
		for i in a+1..<b {
			for j := i; j > a && less(data[j], data[j-1], call); j -= 1 {
				swap(data, j, j-1)
			}
		}
	}

	heap_sort :: proc(data: $T/[]$E, a, b: int, call: P) #no_bounds_check {
		sift_down :: proc(data: T, lo, hi, first: int, call: P) #no_bounds_check {
			root := lo
			for {
				child := 2*root + 1
				if child >= hi {
					break
				}
				if child+1 < hi && less(data[first+child], data[first+child+1], call) {
					child += 1
				}
				if !less(data[first+root], data[first+child], call) {
					return
				}
				swap(data, first+root, first+child)
				root = child
			}
		}


		first, lo, hi := a, 0, b-a

		for i := (hi-1)/2; i >= 0; i -= 1 {
			sift_down(data, i, hi, first, call)
		}

		for i := hi-1; i >= 0; i -= 1 {
			swap(data, first, first+i)
			sift_down(data, lo, i, first, call)
		}
	}

	median3 :: proc(data: T, m1, m0, m2: int, call: P) #no_bounds_check {
		if less(data[m1], data[m0], call) {
			swap(data, m1, m0)
		}
		if less(data[m2], data[m1], call) {
			swap(data, m2, m1)
			if less(data[m1], data[m0], call) {
				swap(data, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int, call: P) -> (midlo, midhi: int) #no_bounds_check {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, lo, lo+s, lo+s*2, call)
			median3(data, m, m-s, m+s, call)
			median3(data, hi-1, hi-1-s, hi-1-s*2, call)
		}
		median3(data, lo, m, hi-1, call)

		pivot := lo
		a, c := lo+1, hi-1


		for ; a < c && less(data[a], data[pivot], call); a += 1 {
		}
		b := a

		for {
			for ; b < c && !less(data[pivot], data[b], call); b += 1 { // data[b] <= pivot
			}
			for ; b < c && less(data[pivot], data[c-1], call); c -=1 { // data[c-1] > pivot
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
			if !less(data[pivot], data[hi-1], call) {
				swap(data, c, hi-1)
				c += 1
				dups += 1
			}
			if !less(data[b-1], data[pivot], call) {
				b -= 1
				dups += 1
			}

			if !less(data[m], data[pivot], call) {
				swap(data, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !less(data[b-1], data[pivot], call); b -= 1 {
				}
				for ; a < b && less(data[a], data[pivot], call); a += 1 {
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

	for b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			heap_sort(data, a, b, call)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, a, b, call)
		if mlo-a < b-mhi {
			_quick_sort_general(data, a, mlo, max_depth, call, KIND)
			a = mhi
		} else {
			_quick_sort_general(data, mhi, b, max_depth, call, KIND)
			b = mlo
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if less(data[i], data[i-6], call) {
				swap(data, i, i-6)
			}
		}
		insertion_sort(data, a, b, call)
	}
}


_stable_sort_general :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}
	
	// insertion sort
	// TODO(bill): use a different algorithm as insertion sort is O(n^2)
	n := len(data)
	for i in 1..<n {
		for j := i; j > 0 && less(data[j], data[j-1], call); j -= 1 {
			swap(data, j, j-1)
		}
	}
}

_quick_sort_general_with_indices :: proc(data: $T/[]$E, indices: []int, a, b, max_depth: int, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}

	insertion_sort :: proc(data: $T/[]$E, indices: []int, a, b: int, call: P) #no_bounds_check {
		for i in a+1..<b {
			for j := i; j > a && less(data[j], data[j-1], call); j -= 1 {
				swap(data, j, j-1)
				swap(indices, j, j-1)
			}
		}
	}

	heap_sort :: proc(data: $T/[]$E, indices: []int, a, b: int, call: P) #no_bounds_check {
		sift_down :: proc(data: T, indices: []int, lo, hi, first: int, call: P) #no_bounds_check {
			root := lo
			for {
				child := 2*root + 1
				if child >= hi {
					break
				}
				if child+1 < hi && less(data[first+child], data[first+child+1], call) {
					child += 1
				}
				if !less(data[first+root], data[first+child], call) {
					return
				}
				swap(data, first+root, first+child)
				swap(indices, first+root, first+child)
				root = child
			}
		}


		first, lo, hi := a, 0, b-a

		for i := (hi-1)/2; i >= 0; i -= 1 {
			sift_down(data, indices, i, hi, first, call)
		}

		for i := hi-1; i >= 0; i -= 1 {
			swap(data, first, first+i)
			swap(indices, first, first+i)
			sift_down(data, indices, lo, i, first, call)
		}
	}

	median3 :: proc(data: T, indices: []int, m1, m0, m2: int, call: P) #no_bounds_check {
		if less(data[m1], data[m0], call) {
			swap(data, m1, m0)
			swap(indices, m1, m0)
		}
		if less(data[m2], data[m1], call) {
			swap(data, m2, m1)
			swap(indices, m2, m1)
			if less(data[m1], data[m0], call) {
				swap(data, m1, m0)
				swap(indices, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, indices: []int, lo, hi: int, call: P) -> (midlo, midhi: int) #no_bounds_check {
		m := int(uint(lo+hi)>>1)
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, indices, lo, lo+s, lo+s*2, call)
			median3(data, indices, m, m-s, m+s, call)
			median3(data, indices, hi-1, hi-1-s, hi-1-s*2, call)
		}
		median3(data, indices, lo, m, hi-1, call)

		pivot := lo
		a, c := lo+1, hi-1


		for ; a < c && less(data[a], data[pivot], call); a += 1 {
		}
		b := a

		for {
			for ; b < c && !less(data[pivot], data[b], call); b += 1 { // data[b] <= pivot
			}
			for ; b < c && less(data[pivot], data[c-1], call); c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			swap(data, b, c-1)
			swap(indices, b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if !less(data[pivot], data[hi-1], call) {
				swap(data, c, hi-1)
				swap(indices, c, hi-1)
				c += 1
				dups += 1
			}
			if !less(data[b-1], data[pivot], call) {
				b -= 1
				dups += 1
			}

			if !less(data[m], data[pivot], call) {
				swap(data, m, b-1)
				swap(indices, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !less(data[b-1], data[pivot], call); b -= 1 {
				}
				for ; a < b && less(data[a], data[pivot], call); a += 1 {
				}
				if a >= b {
					break
				}
				swap(data, a, b-1)
				swap(indices, a, b-1)
				a += 1
				b -= 1
			}
		}
		swap(data, pivot, b-1)
		swap(indices, pivot, b-1)
		return b-1, c
	}

	assert(len(data) == len(indices))

	a, b, max_depth := a, b, max_depth

	for b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			heap_sort(data, indices, a, b, call)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, indices, a, b, call)
		if mlo-a < b-mhi {
			_quick_sort_general_with_indices(data, indices, a, mlo, max_depth, call, KIND)
			a = mhi
		} else {
			_quick_sort_general_with_indices(data, indices, mhi, b, max_depth, call, KIND)
			b = mlo
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if less(data[i], data[i-6], call) {
				swap(data, i, i-6)
				swap(indices, i, i-6)
			}
		}
		insertion_sort(data, indices, a, b, call)
	}
}
