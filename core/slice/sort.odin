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
		return cmp(a, b)
	}
}

// sort sorts a slice
// Equal elements keep their original order
sort :: proc(data: $T/[]$E) where ORD(E) {
	gingersort(([]E)(data), struct{}{}, .Ordered)
}


sort_by_indices :: proc{ sort_by_indices_allocate, _sort_by_indices}

sort_by_indices_allocate :: proc(data: $T/[]$E, indices: []int, allocator := context.allocator, loc := #caller_location) -> (sorted: T) {
	assert(len(data) == len(indices))
	sorted = non_zero_make(T, len(data), allocator, loc)
	_sort_by_indices(data, sorted, indices)
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
	temp := non_zero_make(T, len(data), context.allocator)
	defer delete(temp)
	_sort_by_indices(data, temp, indices)
	copy(data, temp)
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

// sort_with_indices sorts a slice and returns a slice of the original indices
// Equal elements keep their original order
sort_with_indices :: proc(data: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(data), allocator, loc)
	ginger_sort_indices(([]E)(data), indices, ([]E)(data), .Indices_Ordered)
	return
}

// sort_by sorts a slice with a given procedure to test whether two values are ordered "i < j"
// Equal elements keep their original order
sort_by :: proc{
	sort_by_runtime,
	sort_by_constant where ODIN_OPTIMIZATION_MODE >= .Speed,
}

sort_by_runtime :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	gingersort(([]E)(data), less, .Less)
}

sort_by_constant :: proc(data: $T/[]$E, $less: proc(i, j: E) -> bool) {
	Less :: distinct proc(i, j: E) -> bool
	gingersort(([]E)(data), Less(less), .Less_Constant)
}

sort_by_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr) {
	gingersort(([]E)(data), Sort_Less_With_Data(E){less, user_data}, .Less_With_Data)
}

// sort_by_with_indices sorts a slice with a given procedure to test whether two values are ordered "i < j",
// and returns a slice of the original indices
// Equal elements keep their original order
sort_by_with_indices :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool, allocator := context.allocator, loc := #caller_location) -> (indices : []int) {
	indices = make([]int, len(data), allocator, loc)
	ginger_sort_indices(([]E)(data), indices, Sort_Indices_Less(E){less, ([]E)(data)}, .Indices_Less)
	return
}

sort_by_with_indices_with_data :: proc(data: $T/[]$E, less: proc(i, j: E, user_data: rawptr) -> bool, user_data: rawptr, allocator := context.allocator, loc := #caller_location) -> (indices : []int) {
	indices = make([]int, len(data), allocator, loc)
	ginger_sort_indices(([]E)(data), indices, Sort_Indices_Less_With_Data(E){less, ([]E)(data), user_data}, .Indices_Less_With_Data)
	return
}

sort_by_cmp :: proc{
	sort_by_cmp_runtime,
	sort_by_cmp_constant where ODIN_OPTIMIZATION_MODE >= .Speed,
}

sort_by_cmp_runtime :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	gingersort(([]E)(data), cmp, .Cmp)
}

sort_by_cmp_constant :: proc(data: $T/[]$E, $cmp: proc(i, j: E) -> Ordering) {
	Cmp :: distinct proc(i, j: E) -> Ordering
	gingersort(([]E)(data), Cmp(cmp), .Cmp_Constant)
}


sort_by_cmp_with_data :: proc(data: $T/[]$E, cmp: proc(i, j: E, user_data: rawptr) -> Ordering, user_data: rawptr) {
	gingersort(([]E)(data), Sort_Cmp_With_Data(E){cmp, user_data}, .Cmp_With_Data)
}


sort_by_generic_cmp :: proc(data: $T/[]$E, cmp: Generic_Cmp, user_data: rawptr) {
	gingersort(([]E)(data), Sort_Generic_Cmp{cmp, user_data}, .Generic_Cmp)
}


/*
Sorts a slice while maintaining the relative order of elements with the same key. For an example see either `stable_sort_by` or `stable_sort_by_cmp`.
*/
stable_sort :: sort

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
stable_sort_by :: sort_by


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
stable_sort_by_cmp :: sort_by_cmp

@(require_results)
is_sorted :: proc(array: $T/[]$E) -> bool where ORD(E) {
	return ginger_is_sorted(([]E)(array), struct{}{}, .Ordered)
}

@(require_results)
is_sorted_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) -> bool {
	return ginger_is_sorted(([]E)(array), less, .Less)
}

is_sorted_by_cmp :: is_sorted_cmp

@(require_results)
is_sorted_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) -> bool {
	return ginger_is_sorted(([]E)(array), cmp, .Cmp)
}



reverse_sort :: proc(data: $T/[]$E) where ORD(E) {
	gingersort(([]E)(data), struct{}{}, .Ordered_Reverse)
}


reverse_sort_by :: proc{
	reverse_sort_by_runtime,
	reverse_sort_by_constant where ODIN_OPTIMIZATION_MODE >= .Speed,
}

reverse_sort_by_runtime :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	gingersort(([]E)(data), less, .Less_Reverse)
}

reverse_sort_by_constant :: proc(data: $T/[]$E, $less: proc(i, j: E) -> bool) {
	Less :: distinct proc(i, j: E) -> bool
	gingersort(([]E)(data), Less(less), .Less_Reverse_Constant)
}

reverse_sort_by_cmp :: proc{
	reverse_sort_by_cmp_runtime,
	reverse_sort_by_cmp_constant where ODIN_OPTIMIZATION_MODE >= .Speed,
}

reverse_sort_by_cmp_runtime :: proc(data: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	gingersort(([]E)(data), cmp, .Cmp_Reverse)
}

reverse_sort_by_cmp_constant :: proc(data: $T/[]$E, $cmp: proc(i, j: E) -> Ordering) {
	Cmp :: distinct proc(i, j: E) -> Ordering
	gingersort(([]E)(data), Cmp(cmp), .Cmp_Reverse_Constant)
}


// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	gingersort(([]E)(data), key, .Key)
}

reverse_sort_by_key :: proc(data: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	gingersort(([]E)(data), key, .Key_Reverse)
}

@(require_results)
is_sorted_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) -> bool where ORD(K) {
	return ginger_is_sorted(([]E)(array), key, .Key)
}
