// A sorting interface and algorithms.
package sort

import "core:mem"
import _slice "core:slice"
import "base:intrinsics"

_ :: intrinsics
_ :: _slice
ORD :: intrinsics.type_is_ordered

Interface :: struct {
	len:  proc(it: Interface) -> int,
	less: proc(it: Interface, i, j: int) -> bool,
	swap: proc(it: Interface, i, j: int),
	collection: rawptr,
}

// sort sorts an Interface
// This sort is not guaranteed to be stable
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

reverse_sort :: proc(it: Interface) {
	it := it
	sort(reverse_interface(&it))
}

is_sorted :: proc(it: Interface) -> bool {
	n := it->len()
	for i := n-1; i > 0; i -= 1 {
		if it->less(i, i-1) {
			return false
		}
	}
	return true
}


swap_range :: proc(it: Interface, a, b, n: int) {
	for i in 0..<n {
		it->swap(a+i, b+i)
	}
}

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

@(private)
_insertion_sort :: proc(it: Interface, a, b: int) {
	for i in a+1..<b {
		for j := i; j > a && it->less(j, j-1); j -= 1 {
			it->swap(j, j-1)
		}
	}
}

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

_log2 :: proc(x: int) -> int {
	res := 0
	for n := x; n != 0; n >>= 1 {
		res += 1
	}
	return res
}

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

compare_bools :: proc(a, b: bool) -> int {
	switch {
	case !a && b: return -1
	case a && !b: return +1
	}
	return 0
}


compare_ints :: proc(a, b: int) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}

compare_uints :: proc(a, b: uint) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_u8s :: proc(a, b: u8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_u16s :: proc(a, b: u16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_u32s :: proc(a, b: u32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_u64s :: proc(a, b: u64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_i8s :: proc(a, b: i8) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_i16s :: proc(a, b: i16) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_i32s :: proc(a, b: i32) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}

compare_i64s :: proc(a, b: i64) -> int {
	switch {
	case a < b: return -1
	case a > b: return +1
	}
	return 0
}




compare_f32s :: proc(a, b: f32) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}
compare_f64s :: proc(a, b: f64) -> int {
	switch delta := a - b; {
	case delta < 0: return -1
	case delta > 0: return +1
	}
	return 0
}
compare_strings :: proc(a, b: string) -> int {
	x := transmute(mem.Raw_String)a
	y := transmute(mem.Raw_String)b
	
	ret := mem.compare_byte_ptrs(x.data, y.data, min(x.len, y.len))
	if ret == 0 && x.len != y.len {
		return -1 if x.len < y.len else +1
	}
	return ret
}
