package slice

import "intrinsics"
_ :: intrinsics;

ORD :: intrinsics.type_is_ordered;


// sort sorts a slice
// This sort is not guaranteed to be stable
sort :: proc(data: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort(data, 0, n, _max_depth(n));
		}
	}
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort_proc(data, 0, n, _max_depth(n), less);
		}
	}
}

is_sorted :: proc(array: $T/[]$E) -> bool where ORD(E) {
	for i := len(array)-1; i > 0; i -= 1 {
		if array[i] < array[i-1] {
			return false;
		}
	}
	return true;
}

is_sorted_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if less(array[i], array[i-1]) {
			return false;
		}
	}
	return true;
}


reverse_sort :: proc(data: $T/[]$E) where ORD(E) {
	sort_by(data, proc(i, j: E) -> bool {
		return j < i;
	});
}


// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	context.user_ptr = rawptr(key);
	sort_by(data, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context.user_ptr);
		return k(i) < k(j);
	});
}

reverse_sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	context.user_ptr = rawptr(key);
	sort_by(data, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context.user_ptr);
		return k(j) < k(i);
	});
}

is_sorted_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) -> bool where ORD(K) {
	for i := len(array)-1; i > 0; i -= 1 {
		if key(array[i]) < key(array[i-1]) {
			return false;
		}
	}
	return true;
}



@(private)
_max_depth :: proc(n: int) -> int { // 2*ceil(log2(n+1))
	depth: int;
	for i := n; i > 0; i >>= 1 {
		depth += 1;
	}
	return depth * 2;
}

@(private)
_quick_sort :: proc(data: $T/[]$E, a, b, max_depth: int) where ORD(E) {
	median3 :: proc(data: T, m1, m0, m2: int) {
		if data[m1] < data[m0] {
			swap(data, m1, m0);
		}
		if data[m2] < data[m1] {
			swap(data, m2, m1);
			if data[m1] < data[m0] {
				swap(data, m1, m0);
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1);
		if hi-lo > 40 {
			s := (hi-lo)/8;
			median3(data, lo, lo+s, lo+s*2);
			median3(data, m, m-s, m+s);
			median3(data, hi-1, hi-1-s, hi-1-s*2);
		}
		median3(data, lo, m, hi-1);


		pivot := lo;
		a, c := lo+1, hi-1;

		for ; a < c && data[a] < data[pivot]; a += 1 {
		}
		b := a;

		for {
			for ; b < c && !(data[pivot] < data[b]); b += 1 { // data[b] <= pivot
			}
			for ; b < c && data[pivot] < data[c-1]; c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break;
			}

			swap(data, b, c-1);
			b += 1;
			c -= 1;
		}

		protect := hi-c < 5;
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0;
			if !(data[pivot] < data[hi-1]) {
				swap(data, c, hi-1);
				c += 1;
				dups += 1;
			}
			if !(data[b-1] < data[pivot]) {
				b -= 1;
				dups += 1;
			}

			if !(data[m] < data[pivot]) {
				swap(data, m, b-1);
				b -= 1;
				dups += 1;
			}
			protect = dups > 1;
		}
		if protect {
			for {
				for ; a < b && !(data[b-1] < data[pivot]); b -= 1 {
				}
				for ; a < b && data[a] < data[pivot]; a += 1 {
				}
				if a >= b {
					break;
				}
				swap(data, a, b-1);
				a += 1;
				b -= 1;
			}
		}
		swap(data, pivot, b-1);
		return b-1, c;
	}


	a, b, max_depth := a, b, max_depth;

	if b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			_heap_sort(data, a, b);
			return;
		}
		max_depth -= 1;
		mlo, mhi := do_pivot(data, a, b);
		if mlo-a < b-mhi {
			_quick_sort(data, a, mlo, max_depth);
			a = mhi;
		} else {
			_quick_sort(data, mhi, b, max_depth);
			b = mlo;
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if data[i] < data[i-6] {
				swap(data, i, i-6);
			}
		}
		_insertion_sort(data, a, b);
	}
}

@(private)
_insertion_sort :: proc(data: $T/[]$E, a, b: int) where ORD(E) {
	for i in a+1..<b {
		for j := i; j > a && data[j] < data[j-1]; j -= 1 {
			swap(data, j, j-1);
		}
	}
}

@(private)
_heap_sort :: proc(data: $T/[]$E, a, b: int) where ORD(E) {
	sift_down :: proc(data: T, lo, hi, first: int) {
		root := lo;
		for {
			child := 2*root + 1;
			if child >= hi {
				break;
			}
			if child+1 < hi && data[first+child] < data[first+child+1] {
				child += 1;
			}
			if !(data[first+root] < data[first+child]) {
				return;
			}
			swap(data, first+root, first+child);
			root = child;
		}
	}


	first, lo, hi := a, 0, b-a;

	for i := (hi-1)/2; i >= 0; i -= 1 {
		sift_down(data, i, hi, first);
	}

	for i := hi-1; i >= 0; i -= 1 {
		swap(data, first, first+i);
		sift_down(data, lo, i, first);
	}
}






@(private)
_quick_sort_proc :: proc(data: $T/[]$E, a, b, max_depth: int, less: proc(i, j: E) -> bool) {
	median3 :: proc(data: T, m1, m0, m2: int, less: proc(i, j: E) -> bool) {
		if less(data[m1], data[m0]) {
			swap(data, m1, m0);
		}
		if less(data[m2], data[m1]) {
			swap(data, m2, m1);
			if less(data[m1], data[m0]) {
				swap(data, m1, m0);
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int, less: proc(i, j: E) -> bool) -> (midlo, midhi: int) {
		m := int(uint(lo+hi)>>1);
		if hi-lo > 40 {
			s := (hi-lo)/8;
			median3(data, lo, lo+s, lo+s*2, less);
			median3(data, m, m-s, m+s, less);
			median3(data, hi-1, hi-1-s, hi-1-s*2, less);
		}
		median3(data, lo, m, hi-1, less);

		pivot := lo;
		a, c := lo+1, hi-1;

		for ; a < c && less(data[a], data[pivot]); a += 1 {
		}
		b := a;

		for {
			for ; b < c && !less(data[pivot], data[b]); b += 1 { // data[b] <= pivot
			}
			for ; b < c && less(data[pivot], data[c-1]); c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break;
			}

			swap(data, b, c-1);
			b += 1;
			c -= 1;
		}

		protect := hi-c < 5;
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0;
			if !less(data[pivot], data[hi-1]) {
				swap(data, c, hi-1);
				c += 1;
				dups += 1;
			}
			if !less(data[b-1], data[pivot]) {
				b -= 1;
				dups += 1;
			}

			if !less(data[m], data[pivot]) {
				swap(data, m, b-1);
				b -= 1;
				dups += 1;
			}
			protect = dups > 1;
		}
		if protect {
			for {
				for ; a < b && !less(data[b-1], data[pivot]); b -= 1 {
				}
				for ; a < b && less(data[a], data[pivot]); a += 1 {
				}
				if a >= b {
					break;
				}
				swap(data, a, b-1);
				a += 1;
				b -= 1;
			}
		}
		swap(data, pivot, b-1);
		return b-1, c;
	}


	a, b, max_depth := a, b, max_depth;

	if b-a > 12 { // only use shell sort for lengths <= 12
		if max_depth == 0 {
			_heap_sort_proc(data, a, b, less);
			return;
		}
		max_depth -= 1;
		mlo, mhi := do_pivot(data, a, b, less);
		if mlo-a < b-mhi {
			_quick_sort_proc(data, a, mlo, max_depth, less);
			a = mhi;
		} else {
			_quick_sort_proc(data, mhi, b, max_depth, less);
			b = mlo;
		}
	}
	if b-a > 1 {
		// Shell short with gap 6
		for i in a+6..<b {
			if less(data[i], data[i-6]) {
				swap(data, i, i-6);
			}
		}
		_insertion_sort_proc(data, a, b, less);
	}
}

@(private)
_insertion_sort_proc :: proc(data: $T/[]$E, a, b: int, less: proc(i, j: E) -> bool) {
	for i in a+1..<b {
		for j := i; j > a && less(data[j], data[j-1]); j -= 1 {
			swap(data, j, j-1);
		}
	}
}

@(private)
_heap_sort_proc :: proc(data: $T/[]$E, a, b: int, less: proc(i, j: E) -> bool) {
	sift_down :: proc(data: T, lo, hi, first: int, less: proc(i, j: E) -> bool) {
		root := lo;
		for {
			child := 2*root + 1;
			if child >= hi {
				break;
			}
			if child+1 < hi && less(data[first+child], data[first+child+1]) {
				child += 1;
			}
			if !less(data[first+root], data[first+child]) {
				return;
			}
			swap(data, first+root, first+child);
			root = child;
		}
	}


	first, lo, hi := a, 0, b-a;

	for i := (hi-1)/2; i >= 0; i -= 1 {
		sift_down(data, i, hi, first, less);
	}

	for i := hi-1; i >= 0; i -= 1 {
		swap(data, first, first+i);
		sift_down(data, lo, i, first, less);
	}
}



