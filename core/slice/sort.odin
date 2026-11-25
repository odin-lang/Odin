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
		gingersort(([]E)(data), struct{}{}, .Ordered)
	}
}


sort_by_indices :: proc{ sort_by_indices_allocate, _sort_by_indices}

sort_by_indices_allocate :: proc(data: $T/[]$E, indices: []int, allocator := context.allocator, loc := #caller_location) -> (sorted: T) {
	assert(len(data) == len(indices))
	sorted = non_zero_make(T, len(data), allocator, loc)
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
	temp := non_zero_make([]E, len(data), context.allocator)
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
sort_with_indices :: proc(data: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(data), allocator, loc)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			gingersort(indices, ([]E)(data), .Indices_Ordered)

			sort_from_permutation_indices(data, indices)
		}
	}
	return indices
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), less, .Less)
	}
}

sort_by_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), Sort_Less_With_Data(E){less, user_data}, .Less_With_Data)
	}
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// This sort is not guaranteed to be stable
sort_by_with_indices :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool, allocator := context.allocator, loc := #caller_location) -> (indices : []int) {
	indices = make([]int, len(data), allocator, loc)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			gingersort(indices, Sort_Indices_Less(E){less, ([]E)(data)}, .Indices_Less)

			sort_from_permutation_indices(data, indices)
		}
	}
	return indices
}

sort_by_with_indices_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr, allocator := context.allocator, loc := #caller_location) -> (indices : []int) {
	indices = make([]int, len(data), allocator, loc)
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}

			gingersort(indices, Sort_Indices_Less_With_Data(E){less, ([]E)(data), user_data}, .Indices_Less_With_Data)

			sort_from_permutation_indices(data, indices)
		}
	}
	return indices
}

sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), cmp, .Cmp)
	}
}


sort_by_cmp_with_data :: proc(data: $T/[]$E, cmp: proc(i, j: E, user_data: rawptr) -> Ordering, user_data: rawptr) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), Sort_Cmp_With_Data(E){cmp, user_data}, .Cmp_With_Data)
	}
}


sort_by_generic_cmp :: proc(data: $T/[]$E, cmp: Generic_Cmp, user_data: rawptr) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), Sort_Generic_Cmp{cmp, user_data}, .Generic_Cmp)
	}
}


/*
Sorts a slice while maintaining the relative order of elements with the same key. For an example see either `stable_sort_by` or `stable_sort_by_cmp`.
*/
stable_sort :: proc(data: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), struct{}{}, .Ordered)
	}
}

/*
Sorts a slice while maintaining the relative order of elements with the same key. Two items `i` and `j` are ordered if `less(i, j)` returns `true`.

Example:
	import "core:slice"
	import "core:fmt"
	
	stable_sort_by_example :: proc() {
		Example :: struct { n: int, s: string }

		arr := []Example {
			{2, "name"},
			{3, "Bill"},
			{1, "My"},
			{2, "is"}
		}
		slice.stable_sort_by(arr, proc(i, j: Example) -> bool {
			return i.n < j.n
		})
		
		for e in arr do  fmt.printf("%s ", e.s)
		fmt.println()
	}
	
Output:
	My name is Bill 
*/
stable_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), less, .Less)
	}
}


/*
Sorts a slice while maintaining the relative order of elements with the same key. The ordering of the any two items is defined by the user-provided `cmp`.

Example:
	import "core:slice"
	import "core:fmt"
	
	stable_sort_by_cmp_example :: proc() {
		Example :: struct { n: int, s: string }

		arr := []Example {
			{2, "name"},
			{3, "Bill"},
			{1, "My"},
			{2, "is"}
		}
		slice.stable_sort_by_cmp(arr, proc(i, j: Example) -> slice.Ordering {
			return slice.cmp(i.n, j.n)
		})
		
		for e in arr do  fmt.printf("%s ", e.s)
		fmt.println()
	}
	
Output:
	My name is Bill 
*/
stable_sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), cmp, .Cmp)
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
	when size_of(E) != 0 {
		gingersort(([]E)(data), struct{}{}, .Ordered_Reverse)
	}
}


reverse_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), less, .Less_Reverse)
	}
}

reverse_sort_by_cmp :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), cmp, .Cmp_Reverse)
	}
}


// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), key, .Key)
	}
}

reverse_sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	when size_of(E) != 0 {
		gingersort(([]E)(data), key, .Key_Reverse)
	}
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
