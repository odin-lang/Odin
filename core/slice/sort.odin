package slice

/*
Result of comparing two values.
*/
Ordering :: enum {
	// First value is lesser than the second
	Less    = -1,
	// The values are equal
	Equal   =  0,
	// First value is greater than the second
	Greater = +1,
}

/*
Compare two values.

Inputs:
- `a`: First value
- `b`: Second value

Returns:
- The `Ordering` comparison result.
*/
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

/*
Return a procedure to compare two values of a given type.

Inputs:
- Type of the values to compare

Returns:
- The procedure to compare two values of type `E`
*/
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

/*
Sort a slice.

Not guaranteed to be stable.

Inputs:
- `array`: The slice to sort

Example:

	import "core:slice"
	import "core:fmt"

	sort_example :: proc() {
		array := []rune{'C', 'A', 'B'}
		slice.sort(array)
		fmt.println(array)
	}

Output:

	[A, B, C]

*/
sort :: proc(array: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_quick_sort_general(array, 0, n, _max_depth(n), struct{}{}, .Ordered)
		}
	}
}

/*
Reorder the slice based on an array of indices.

There is another way to call this procedure. See `sort_by_indices_allocate`.

Inputs:
- `array`: Input slice
- `sorted`: Output slice
- `indices`: Slice specifying which input element ends up at which index

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_indices_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		indices := []int{2, 0, 1}
		sorted := []rune{0, 0, 0}
		slice.sort_by_indices(array, sorted, indices)
		fmt.println(sorted)
	}

Output:

	[C, A, B]
*/
sort_by_indices :: proc{ sort_by_indices_allocate, _sort_by_indices}

/*
Reorder the slice based on an array of indices.

*Allocates Using Provided Allocator*

Inputs:
- `array`: Input slice
- `indices`: Slice specifying which input element ends up at which index
- `allocator`: Allocator to use for the resulting slice (default is context.allocator)

Returns:
- `sorted`: Slice with the values ordered by `indices`

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_indices_allocate_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		indices := []int{2, 0, 1}
		sorted := slice.sort_by_indices_allocate(array, indices)
		defer delete(sorted)
		fmt.println(sorted)
	}

Output:

	[C, A, B]
*/
sort_by_indices_allocate :: proc(array: $T/[]$E, indices: []int, allocator := context.allocator) -> (sorted: T) {
	assert(len(array) == len(indices))
	sorted = make(T, len(array), allocator)
	for v, i in indices {
		sorted[i] = array[v]
	}
	return
}

/*
Reorder the slice based on an array of indices.

See `sort_by_indices`.
*/
_sort_by_indices :: proc(array, sorted: $T/[]$E, indices: []int) {
	assert(len(array) == len(indices))
	assert(len(array) == len(sorted))
	for v, i in indices {
		sorted[i] = array[v]
	}
}

/*
Reorder the slice based on an array of indices.

*Internally allocates and deallocates memory using `context.allocator`.*

Inputs:
- `array`: Input slice
- `indices`: Slice specifying which input element ends up at which index

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_indices_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		indices := []int{2, 0, 1}
		slice.sort_by_indices_overwrite(array, indices)
		fmt.println(array)
	}

Output:

	[C, A, B]
*/
sort_by_indices_overwrite :: proc(array: $T/[]$E, indices: []int) {
	assert(len(array) == len(indices))
	temp := make([]E, len(array), context.allocator)
	defer delete(temp)
	for v, i in indices {
		temp[i] = array[v]
	}
	swap_with_slice(array, temp)
}

/*
Sort a slice and return a slice of the original indices.

*Allocates Using Provided Allocator*

This sort is not guaranteed to be stable.

Inputs:
- `array`: Input slice
- `allocator`: Allocator to use for the returned indices (default is context.allocator)

Returns:
- `indices`: Indices of the original elements

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_indices_example :: proc() {
		array := []rune{'C', 'A', 'B'}
		indices := slice.sort_with_indices(array)
		fmt.println(array)
		fmt.println(indices)
	}

Output:

	[A, B, C]
	[1, 2, 0]
*/
sort_with_indices :: proc(array: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(array), allocator)
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}
			_quick_sort_general_with_indices(array, indices, 0, n, _max_depth(n), struct{}{}, .Ordered)
		}
		return indices
	}
	return indices
}

/*
Sort a slice using a given procedure to test whether two values are ordered "i < j".

This sort is not guaranteed to be stable.

Inputs:
- `array`: Input slice
- `less`: Procedure comparing input slice values

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_example :: proc() {
		Enemy :: struct {
			health: int
		}
		array := []Enemy{{30}, {10}, {20}}
		less :: proc(i, j: Enemy) -> bool {
			return i.health < j.health
		}
		slice.sort_by(array, less)
		fmt.println(array)
	}

Output:

	[Enemy{health = 10}, Enemy{health = 20}, Enemy{health = 30}]
*/
sort_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_quick_sort_general(array, 0, n, _max_depth(n), less, .Less)
		}
	}
}

/*
Sort a slice using a given procedure to test whether two values are ordered "i < j"  and return a slice of the original indices.

*Allocates Using Provided Allocator*

This sort is not guaranteed to be stable.

Inputs:
- `array`: Input slice
- `less`: Procedure comparing input slice values
- `allocator`: Allocator to use for the returned indices (default is context.allocator)

Returns:
- `indices`: Indices of the original elements

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_with_indices_example :: proc() {
		Enemy :: struct {
			health: int
		}
		array := []Enemy{{30}, {10}, {20}}
		less :: proc(i, j: Enemy) -> bool {
			return i.health < j.health
		}
		indices := slice.sort_by_with_indices(array, less)
		fmt.println(array)
		fmt.println(indices)
	}

Output:

	[Enemy{health = 10}, Enemy{health = 20}, Enemy{health = 30}]
	[1, 2, 0]
*/
sort_by_with_indices :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool, allocator := context.allocator) -> (indices : []int) {
	indices = make([]int, len(array), allocator)
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			for _, idx in indices {
				indices[idx] = idx
			}
			_quick_sort_general_with_indices(array, indices, 0, n, _max_depth(n), less, .Less)
			return indices
		}
	}
	return indices
}

/*
Sort a slice using a given procedure to compare values.

This sort is not guaranteed to be stable.

Inputs:
- `array`: Input slice
- `cmp`: Procedure comparing input slice values

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_cmp_example :: proc() {
		Enemy :: struct {
			health: int
		}
		array := []Enemy{{30}, {10}, {20}}
		cmp :: proc(a, b: Enemy) -> slice.Ordering {
			return slice.cmp(a.health, b.health)
		}
		slice.sort_by_cmp(array, cmp)
		fmt.println(array)
	}

Output:

	[Enemy{health = 10}, Enemy{health = 20}, Enemy{health = 30}]
*/
sort_by_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_quick_sort_general(array, 0, n, _max_depth(n), cmp, .Cmp)
		}
	}
}

/*
Sort a slice.

Works just like `sort`, but is guaranteed to be stable.
*/
stable_sort :: proc(array: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_stable_sort_general(array, struct{}{}, .Ordered)
		}
	}
}

/*
Sort a slice using a given procedure to test whether two values are ordered "i < j".

Works just like `sort_by`, but is guaranteed to be stable.
*/
stable_sort_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_stable_sort_general(array, less, .Less)
		}
	}
}

/*
Sort a slice using a given procedure to compare values.

Works just like `sort_by_cmp_by`, but is guaranteed to be stable.
*/
stable_sort_by_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	when size_of(E) != 0 {
		if n := len(array); n > 1 {
			_stable_sort_general(array, cmp, .Cmp)
		}
	}
}

/*
Check if the slice is sorted.

Inputs:
- `array`: The slice to check

Returns:
- `true` if the slice is sorted, `false` otherwise
*/
@(require_results)
is_sorted :: proc(array: $T/[]$E) -> bool where ORD(E) {
	for i := len(array)-1; i > 0; i -= 1 {
		if array[i] < array[i-1] {
			return false
		}
	}
	return true
}

/*
Check if the slice is sorted using a given procedure to test whether two values are ordered "i < j".

Inputs:
- `array`: The slice to check
- `less`: Procedure comparing input slice values

Returns:
- `true` if the slice is sorted, `false` otherwise
*/
@(require_results)
is_sorted_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if less(array[i], array[i-1]) {
			return false
		}
	}
	return true
}

/*
Alias for `is_sorted_cmp`.
*/
is_sorted_by_cmp :: is_sorted_cmp


/*
Check if the slice is sorted using a given procedure to compare values.

Inputs:
- `array`: The slice to check
- `cmp`: Procedure comparing input slice values

Returns:
- `true` if the slice is sorted, `false` otherwise
*/
@(require_results)
is_sorted_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) -> bool {
	for i := len(array)-1; i > 0; i -= 1 {
		if cmp(array[i], array[i-1]) == .Less {
			return false
		}
	}
	return true
}

/*
Sort a slice in reverse order.

Works just like `sort`, but reversed.
*/
reverse_sort :: proc(array: $T/[]$E) where ORD(E) {
	sort_by(array, proc(i, j: E) -> bool {
		return j < i
	})
}

/*
Sort a slice in reverse order using a given procedure to test whether two values are ordered "i < j".

Works just like `sort_by`, but reversed.
*/
reverse_sort_by :: proc(array: $T/[]$E, less: proc(i, j: E) -> bool) {
	context._internal = rawptr(less)
	sort_by(array, proc(i, j: E) -> bool {
		k := (proc(i, j: E) -> bool)(context._internal)
		return k(j, i)
	})
}

/*
Sort a slice in reverse order using a given procedure to compare values.

Works just like `sort_by_cmp`, but reversed.
*/
reverse_sort_by_cmp :: proc(array: $T/[]$E, cmp: proc(i, j: E) -> Ordering) {
	context._internal = rawptr(cmp)
	sort_by_cmp(array, proc(i, j: E) -> Ordering {
		k := (proc(i, j: E) -> Ordering)(context._internal)
		return k(j, i)
	})
}

/*
Sort a slice using a given procedure to access the property to compare.

This sort is not guaranteed to be stable.

Inputs:
- `array`: Input slice
- `key`: Procedure extracting some property

Example:

	import "core:slice"
	import "core:fmt"

	sort_by_key_example :: proc() {
		Enemy :: struct {
			health: int
		}
		array := []Enemy{{30}, {10}, {20}}
		key :: proc(e: Enemy) -> int {
			return e.health
		}
		slice.sort_by_key(array, key)
		fmt.println(array)
	}

Output:

	[Enemy{health = 10}, Enemy{health = 20}, Enemy{health = 30}]
*/
sort_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	// TODO(bill): Should `sort_by_key` exist or is `sort_by` more than enough?
	context._internal = rawptr(key)
	sort_by(array, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context._internal)
		return k(i) < k(j)
	})
}

/*
Sort a slice in reverse order using a given procedure to access the property to compare.

Works just like `sort_by_key`, but reversed.
*/
reverse_sort_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) where ORD(K) {
	context._internal = rawptr(key)
	sort_by(array, proc(i, j: E) -> bool {
		k := (proc(E) -> K)(context._internal)
		return k(j) < k(i)
	})
}

/*
Check if the slice is sorted using a given procedure to access the property to compare.

Inputs:
- `array`: The slice to check
- `key`: Procedure extracting some property

Returns:
- `true` if the slice is sorted, `false` otherwise
*/
@(require_results)
is_sorted_by_key :: proc(array: $T/[]$E, key: proc(E) -> $K) -> bool where ORD(K) {
	for i := len(array)-1; i > 0; i -= 1 {
		if key(array[i]) < key(array[i-1]) {
			return false
		}
	}
	return true
}

@(private, require_results)
_max_depth :: proc(n: int) -> (depth: int) { // 2*ceil(log2(n+1))
	for i := n; i > 0; i >>= 1 {
		depth += 1
	}
	return depth * 2
}
