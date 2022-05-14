package arrays

import "core:intrinsics"

// Sums the elements in the array and returns the results 
array_sum :: proc($T: typeid/[]$E, arr: []E) -> E where intrinsics.type_is_numeric(E) {
	sum: E = 0

	for i in arr do sum += i

	return sum
}

// Loops thriugh the given array, applying the f parameter to each element in the array returning the new array
array_map :: proc($T: typeid/[]$E, arr: []E, f: proc(a: E) -> E) -> []E {
	NewArr := arr
	for i := 0; i < len(arr); i += 1 {
		NewArr[i] = f(arr[i])
	}

	return NewArr
}

// Loops through the given array, removing elements that don't fullfil the predicate
array_filter :: proc(
	$T: typeid/[dynamic]$E,
	arr: [dynamic]E,
	f: proc(a: E) -> bool,
) -> [dynamic]E {
	NewArr := [dynamic]E{}

	for i := 0; i < len(arr); i += 1 {
		if f(arr[i]) {
			append(&NewArr, arr[i])
		}
	}

	return NewArr
}

// loops through the given array applying the procedure argument to each element
array_foreach :: proc($T: typeid/[]$E, arr: []E, f: proc(a: E)) {
	for i := 0; i < len(arr); i += 1 {
		f(arr[i])
	}
}

// returns whether an array is empty
array_is_empty :: proc($T: typeid/[]$E, arr: []E) -> bool {
	return (len(arr) <= 0)
}

// merge 2 arrays of the same type
array_merge :: proc(
	$T: typeid/[dynamic]$E,
	arr: [dynamic]E,
	arr2: [dynamic]E,
) -> [dynamic]E {
	NewArr := [dynamic]E{}

	for item in arr {
		append_elem(&NewArr, item)
	}

	for item in arr2 {
		append_elem(&NewArr, item)
	}


	return NewArr
}
