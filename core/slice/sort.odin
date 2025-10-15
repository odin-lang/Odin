package slice

Ordering :: enum {
	Less    = -1,
	Equal   =  0,
	Greater = +1,
}

Generic_Cmp :: #type proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering

@(require_results)
cmp :: proc(a, b: $E) -> Ordering where ORD(E) {
	switch {
	case a < b:
		return .Less
	case a > b:
		return .Greater
	}
	return .Equal
}

@(require_results)
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
			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				if x < y {
					return .Less
				} else if x > y {
					return .Greater
				}
				return .Equal
			}, nil)
		}
	}
}


sort_by_indices :: proc{ sort_by_indices_allocate, _sort_by_indices}

sort_by_indices_allocate :: proc(data: $T/[]$E, indices: []int, allocator := context.allocator) -> (sorted: T) {
	assert(len(data) == len(indices))
	sorted = make(T, len(data), allocator)
	for v, i in indices {
		sorted[i] = data[v]
	}
	return
}

_sort_by_indices :: proc(data, sorted: $T/[]$E, indices: []int) {
	assert(len(data) == len(indices))
	assert(len(data) == len(sorted))
	for v, i in indices {
		sorted[i] = data[v]
	}
}

sort_by_indices_overwrite :: proc(data: $T/[]$E, indices: []int) {
	assert(len(data) == len(indices))
	temp := make([]E, len(data), context.allocator)
	defer delete(temp)
	for v, i in indices {
		temp[i] = data[v]
	}
	swap_with_slice(data, temp)
}

sort_from_permutation_indices :: proc(data: $T/[]$E, indices: []int) {
	assert(len(data) == len(indices))
	if len(indices) <= 1 {
		return
	}

	for i in 0..<len(indices) {
		index_to_swap := indices[i]

		for index_to_swap < i {
			index_to_swap = indices[index_to_swap]
		}

		ptr_swap_non_overlapping(&data[i], &data[index_to_swap], size_of(E))
	}
}

// sort sorts a slice and returns a slice of the original indices
// This sort is not guaranteed to be stable
sort_with_indices :: proc(data: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(data), allocator)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			raw := ([^]byte)(raw_data(indices))
			_smoothsort(raw, uint(len(indices)), size_of(int), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				data := ([^]E)(user_data)

				xi, yi := (^int)(lhs)^, (^int)(rhs)^
				#no_bounds_check x, y := data[xi], data[yi]
				if x < y {
					return .Less
				} else if x > y {
					return .Greater
				}
				return .Equal
			}, raw_data(data))

			sort_from_permutation_indices(data, indices)
		}
		return indices
	}
	return indices
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				less := (proc(E, E) -> bool)(user_data)
				switch {
				case less(x, y): return .Less
				case less(y, x): return .Greater
				}
				return .Equal
			}, rawptr(less))
		}
	}
}

sort_by_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			Context :: struct {
				less:      proc(i, j: E, user_data: rawptr) -> bool,
				user_data: rawptr,
			}
			ctx := &Context{less, user_data}

			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				ctx := (^Context)(user_data)
				switch {
				case ctx.less(x, y, ctx.user_data): return .Less
				case ctx.less(y, x, ctx.user_data): return .Greater
				}
				return .Equal
			}, ctx)
		}
	}
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by_with_indices :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool, allocator := context.allocator) -> (indices : []int) {
	indices = make([]int, len(data), allocator)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			Context :: struct{
				less: proc(i, j: E) -> bool,
				data: T,
			}
			ctx := &Context{less, data}

			raw := ([^]byte)(raw_data(indices))
			_smoothsort(raw, uint(len(indices)), size_of(int), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				ctx := (^Context)(user_data)
				xi, yi := (^int)(lhs)^, (^int)(rhs)^
				x, y := ctx.data[xi], ctx.data[yi]
				switch {
				case ctx.less(x, y): return .Less
				case ctx.less(y, x): return .Greater
				}
				return .Equal
			}, ctx)

			sort_from_permutation_indices(data, indices)
		}
	}
	return indices
}

sort_by_with_indices_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr, allocator := context.allocator) -> (indices : []int) {
	indices = make([]int, len(data), allocator)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			Context :: struct{
				less: proc(i, j: E, user_data: rawptr) -> bool,
				data: T,
				user_data: rawptr,
			}
			ctx := &Context{less, data, user_data}

			raw := ([^]byte)(raw_data(indices))
			_smoothsort(raw, uint(len(indices)), size_of(int), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				ctx := (^Context)(user_data)
				xi, yi := (^int)(lhs)^, (^int)(rhs)^
				x, y := ctx.data[xi], ctx.data[yi]
				switch {
				case ctx.less(x, y, ctx.user_data): return .Less
				case ctx.less(y, x, ctx.user_data): return .Greater
				}
				return .Equal
			}, ctx)

			sort_from_permutation_indices(data, indices)
		}
	}
	return indices
}

sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				cmp := cast(proc(E, E) -> Ordering)(user_data)
				return cmp(x, y)
			}, rawptr(cmp))
		}
	}
}


sort_by_cmp_with_data :: proc(data: $T/[]$E, cmp: proc(i, j: E, user_data: rawptr) -> Ordering, user_data: rawptr) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			Context :: struct{
				cmp: proc(i, j: E, user_data: rawptr) -> Ordering,
				user_data: rawptr,
			}
			ctx := &Context{cmp, user_data}

			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				ctx := (^Context)(user_data)
				return ctx.cmp(x, y, ctx.user_data)
			}, ctx)
		}
	}
}


sort_by_generic_cmp :: proc(data: $T/[]$E, cmp: Generic_Cmp, user_data: rawptr) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), cmp, user_data)
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

@(require_results)
is_sorted :: proc(array: $T/[]$E) -> bool where ORD(E) {
	for i := len(array)-1; i > 0; i -= 1 {
		if array[i] < array[i-1] {
			return false
		}
	}
	return true
}

@(require_results)
is_sorted_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if less(array[i], array[i-1]) {
			return false
		}
	}
	return true
}

is_sorted_by_cmp :: is_sorted_cmp

@(require_results)
is_sorted_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if cmp(array[i], array[i-1]) == .Less {
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


reverse_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	sort_by_with_data(data, proc(i, j: E, user_data: rawptr) -> bool {
		less := (proc(E, E) -> bool)(user_data)
		return less(j, i)
	}, rawptr(less))
}

reverse_sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	sort_by_cmp_with_data(data, proc(i, j: E, user_data: rawptr) -> Ordering {
		k := (proc(i, j: E) -> Ordering)(user_data)
		return k(j, i)
	}, rawptr(data))
}


// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	Context :: struct {
		key: proc(E) -> K,
	}
	ctx := &Context{key}

	sort_by_generic_cmp(data, proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
		i, j := (^E)(lhs)^, (^E)(rhs)^

		ctx := (^Context)(user_data)
		a := ctx.key(i)
		b := ctx.key(j)
		switch {
		case a < b: return .Less
		case a > b: return .Greater
		}
		return .Equal
	}, ctx)
}

reverse_sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	Context :: struct {
		key: proc(E) -> K,
	}
	ctx := &Context{key}

	sort_by_generic_cmp(data, proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
		i, j := (^E)(lhs)^, (^E)(rhs)^

		ctx := (^Context)(user_data)
		a := ctx.key(i)
		b := ctx.key(j)
		switch {
		case a < b: return .Greater
		case a > b: return .Less
		}
		return .Equal
	}, ctx)
}

@(require_results)
is_sorted_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) -> bool where ORD(K) {
	for i := len(array)-1; i > 0; i -= 1 {
		if key(array[i]) < key(array[i-1]) {
			return false
		}
	}
	return true
}