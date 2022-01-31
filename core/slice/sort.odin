package slice

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
			_quick_sort_general(data, 0, n, _max_depth(n), struct{}{}, .Ordered)
		}
	}
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort_general(data, 0, n, _max_depth(n), less, .Less)
		}
	}
}

sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_quick_sort_general(data, 0, n, _max_depth(n), cmp, .Cmp)
		}
	}
}

// stable_sort sorts a slice
stable_sort :: proc(data: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_stable_sort_general(data, struct{}{}, .Ordered)
		}
	}
}

// stable_sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
stable_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_stable_sort_general(data, less, .Less)
		}
	}
}

stable_sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_stable_sort_general(data, cmp, .Cmp)
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

is_sorted_by_cmp :: is_sorted_cmp
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
_max_depth :: proc(n: int) -> (depth: int) { // 2*ceil(log2(n+1))
	for i := n; i > 0; i >>= 1 {
		depth += 1
	}
	return depth * 2
}
