package slice

import "base:intrinsics"
import "base:builtin"
import "core:math/bits"
import "base:runtime"

_ :: intrinsics
_ :: builtin
_ :: bits
_ :: runtime

/*
Turn a pointer and a length into a slice.

Inputs:
- `ptr`: A pointer to the first element
- `count`: The number of elements

Returns:
- A slice using the `ptr` for data and `count` for length.
*/
@(require_results)
from_ptr :: proc "contextless" (ptr: ^$T, count: int) -> []T {
	return ([^]T)(ptr)[:count]
}

/*
Turn a pointer and a length into a byte slice.

Inputs:
- `ptr`: A pointer to the first byte
- `byte_count`: The number of bytes

Returns:
- A byte slice using the `ptr` for data and `byte_count` for length.
*/
@(require_results)
bytes_from_ptr :: proc "contextless" (ptr: rawptr, byte_count: int) -> []byte {
	return ([^]byte)(ptr)[:byte_count]
}

/*
Turn a slice into a byte slice.

See `slice.reinterpret` to go the other way.

Inputs:
- `array`: The slice to convert

Returns:
- A byte slice pointing to the same data as `s`.
*/
@(require_results)
to_bytes :: proc "contextless" (array: $T/[]$E) -> []byte {
	return ([^]byte)(raw_data(array))[:len(array) * size_of(E)]
}

/*
Turns a byte slice into a type.

Inputs:
- `buf`: The slice to convert
- `T`: Type of the resulting value

Returns:
- A value of type `T`
- `true` if the slice was long enough, `false` otherwise
*/
@(require_results)
to_type :: proc(buf: []u8, $T: typeid) -> (T, bool) #optional_ok {
	if len(buf) < size_of(T) {
		return {}, false
	}
	return intrinsics.unaligned_load((^T)(raw_data(buf))), true
}

/*
Turn a slice of one type, into a slice of another type.

Only converts the type and length of the slice itself.
The length is rounded down to the nearest whole number of items.

Inputs:
- `T`: Target slice type
- `array`: Input slice

Returns:
- A slice pointing to the same data but with a different type

Example:

	import "core:fmt"
	import "core:slice"

	i64s_as_i32s :: proc() {
		large_items := []i64{1, 2, 3, 4}
		small_items := slice.reinterpret([]i32, large_items)
		assert(len(small_items) == 8)
		fmt.println(large_items, "->", small_items)
	}

	bytes_as_i64s :: proc() {
		small_items := [12]byte{}
		small_items[0] = 1
		small_items[8] = 2
		large_items := slice.reinterpret([]i64, small_items[:])
		assert(len(large_items) == 1) // only enough bytes to make 1 x i64; two would need at least 8 bytes.
		fmt.println(small_items, "->", large_items)
	}

	reinterpret_example :: proc() {
		i64s_as_i32s()
		bytes_as_i64s()
	}

Output:
	[1, 2, 3, 4] -> [1, 0, 2, 0, 3, 0, 4, 0]
	[1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0] -> [1]

*/
@(require_results)
reinterpret :: proc "contextless" ($T: typeid/[]$U, array: []$V) -> []U {
	when size_of(U) == 0 || size_of(V) == 0 {
		return nil
	} else {
		bytes := to_bytes(array)
		n := len(bytes) / size_of(U)
		return ([^]U)(raw_data(bytes))[:n]
	}
}

/*
Swap values at two indices of a slice.

Inputs:
- `array`: The input slice
- `a`: First index
- `b`: Second index

Example:

	import "core:slice"
	import "core:fmt"

	swap_example :: proc() {
		data := []rune{'A', 'B', 'C'}
		slice.swap(data, 2, 1)
		fmt.println(data)
	}

Outputs:

	[A, C, B]
*/
swap :: proc(array: $T/[]$E, a, b: int) {
	when size_of(E) > 8 {
		ptr_swap_non_overlapping(&array[a], &array[b], size_of(E))
	} else {
		array[a], array[b] = array[b], array[a]
	}
}

/*
Swap values of two slices up to the length of the shorter slice.

Inputs:
- `a`: First slice
- `b`: Second slice

Example:

	import "core:slice"
	import "core:fmt"

	swap_between_example :: proc() {
		a := []rune{'A', 'B', 'C'}
		b := []rune{'x', 'y', 'z', 'w'}
		slice.swap_between(a, b)
		fmt.println(a)
		fmt.println(b)
	}

Outputs:

	[x, y, z]
	[A, B, C, w]
*/
swap_between :: proc(a, b: $T/[]$E) {
	n := builtin.min(len(a), len(b))
	if n >= 0 {
		ptr_swap_overlapping(&a[0], &b[0], size_of(E)*n)
	}
}

/*
Reverse the order of items in a slice.

Inputs:
- `array`: Slice to reverse

Example:

	import "core:slice"
	import "core:fmt"

	reverse_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		slice.reverse(array)
		fmt.println(array)
	}

Outputs:

	[C, B, A]
*/
reverse :: proc(array: $T/[]$E) {
	n := len(array)/2
	for i in 0..<n {
		swap(array, i, len(array)-i-1)
	}
}

/*
Check if the slice contains a given value.

To get the index of the searched value use `linear_search`.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `true` if value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	contains_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		has_b := slice.contains(array, 'A')
		has_x := slice.contains(array, 'x')
		fmt.println(has_b, has_x)
	}

Outputs:

	true false
*/
@(require_results)
contains :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	_, found := linear_search(array, value)
	return found
}

/*
Search the slice for the given element in *O(n)* time.

If you need a custom search condition, see `linear_search_proc`

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `index`: The index `i`, such that `array[i]` is the first occurrence of `value` in `array`, or -1 if `value` is not present in `array`
- `found`: `true` if the value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	linear_search_example :: proc() {
		a := []rune{'A', 'x', 'B', 'x', 'C'}
		a_index_x, a_has_x := slice.linear_search(a, 'x')
		fmt.println(a_index_x, a_has_x)

		// The index will be 0, because it is relative to `a[3:]`
		s_index_x, s_has_x := slice.linear_search(a[3:], 'x')
		fmt.println(s_index_x, s_has_x)

		b := []rune{'A', 'B', 'C'}
		b_index_x, b_has_x := slice.linear_search(b, 'x')
		fmt.println(b_index_x, b_has_x)
	}

Outputs:

	1 true
	0 true
	-1 false
*/
@(require_results)
linear_search :: proc(array: $T/[]$E, value: E) -> (index: int, found: bool)
	where intrinsics.type_is_comparable(E) {
	for x, i in array {
		if x == value {
			return i, true
		}
	}
	return -1, false
}

/*
Search the slice for the first element satisfying a predicate in *O(n)* time.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to check values with

Returns:
- `index`: The index `i`, such that `array[i]` is the first occurrence of `f(array[i]) == true` in `array`, or -1 if there is no such an occurrence
- `found`: `true` if a value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	linear_search_proc_example :: proc() {
		array := []int{50, -2, 300, 47, 103}
		is_greater_than_100 :: proc(v: int) -> bool {
			return v > 100
		}
		index, found := slice.linear_search_proc(array, is_greater_than_100)
		fmt.println(index, found)
	}

Outputs:

	2 true
*/
@(require_results)
linear_search_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> (index: int, found: bool) {
	for x, i in array {
		if f(x) {
			return i, true
		}
	}
	return -1, false
}

/*
Search the slice for the given element in *O(n)* time, starting from the end of the slice.

If you need a custom search condition, see `linear_search_reverse_proc`

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `index`: The index `i`, such that `array[i]` is the last occurrence of `value` in `array`, or -1 if `value` is not present in `array`
- `found`: `true` if the value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	linear_search_reverse_example :: proc() {
		a := []rune{'A', 'x', 'B', 'x', 'C'}
		a_index_x, a_has_x := slice.linear_search_reverse(a, 'x')
		fmt.println(a_index_x, a_has_x)

		// The index will be 0, because it is relative to `a[3:]`
		s_index_x, s_has_x := slice.linear_search_reverse(a[3:], 'x')
		fmt.println(s_index_x, s_has_x)

		b := []rune{'A', 'B', 'C'}
		b_index_x, b_has_x := slice.linear_search_reverse(b, 'x')
		fmt.println(b_index_x, b_has_x)
	}

Outputs:

	3 true
	0 true
	-1 false
*/
@(require_results)
linear_search_reverse :: proc(array: $T/[]$E, value: E) -> (index: int, found: bool)
	where intrinsics.type_is_comparable(E) {
	#reverse for x, i in array {
		if x == value {
			return i, true
		}
	}
	return -1, false
}

/*
Search the slice for the last element satisfying a predicate in *O(n)* time.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to check values with

Returns:
- `index`: The index `i`, such that `array[i]` is the last occurrence of `f(array[i]) == true` in `array`, or -1 if there is no such an occurrence
- `found`: `true` if a value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	linear_search_reverse_proc_example :: proc() {
		array := []int{50, -2, 300, 47, 103}
		is_greater_than_100 :: proc(v: int) -> bool {
			return v > 100
		}
		index, found := slice.linear_search_reverse_proc(array, is_greater_than_100)
		fmt.println(index, found)
	}

Outputs:

	4 true
*/
@(require_results)
linear_search_reverse_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> (index: int, found: bool) {
	#reverse for x, i in array {
		if f(x) {
			return i, true
		}
	}
	return -1, false
}

/*
Search a sorted slice for the given element.

If the slice is not sorted, the returned index is unspecified and meaningless.

If the value is found then the returned int is the index of the matching element.
If there are multiple matches, then any one of the matches could be returned.

If the value is not found then the returned int is the index where a matching
element could be inserted while maintaining sorted order.

For slices of more complex types see: `binary_search_by`.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `index`: The index of `value`, or an index where `value` could be inserted maintaining sorted order.
- `found`: `true` if a value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	binary_search_example :: proc() {
		fib := []i32{0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55}
		two_index, two_found := slice.binary_search(fib, 2)
		fmt.println(two_index, two_found)

		fourteen_index, fourteen_found := slice.binary_search(fib, 14)
		fmt.println(fourteen_index, fourteen_found)
	}

Outputs:

	3 true
	8 false
*/
@(require_results)
binary_search :: proc(array: $T/[]$E, value: E) -> (index: int, found: bool)
	where intrinsics.type_is_ordered(E) #no_bounds_check {
	return binary_search_by(array, value, cmp_proc(E))
}

/*
Search a sorted slice for the given element.

If the slice is not sorted, the returned index is unspecified and meaningless.

If the value is found then the returned int is the index of the matching element.
If there are multiple matches, then any one of the matches could be returned.

If the value is not found then the returned int is the index where a matching
element could be inserted while maintaining sorted order.

The array elements and `value` may be of different types. This allows the `cmp` procedure
to compare elements against a slice of structs, one struct value at a time.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for
- `cmp`: Procedure comparing input slice values

Returns:
- `index`: The index of `value`, or an index where `value` could be inserted maintaining sorted order.
- `found`: `true` if a value was found, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	binary_search_by_example :: proc() {
		Enemy :: struct {
			health: int
		}
		array := []Enemy{{10}, {20}, {30}, {40}}
		cmp :: proc(a, b: Enemy) -> slice.Ordering {
			return slice.cmp(a.health, b.health)
		}
		index, found := slice.binary_search_by(array, Enemy{20}, cmp)
		fmt.println(index, found)
	}

Outputs:

	1 true
*/
@(require_results)
binary_search_by :: proc(array: $T/[]$U, value: $V, cmp: proc(U, V) -> Ordering) -> (index: int, found: bool) #no_bounds_check {
	n := len(array)
	left, right := 0, n
	for left < right {
		mid := int(uint(left+right) >> 1)
		if cmp(array[mid], value) == .Less {
			left = mid+1
		} else {
			// .Equal or .Greater
			right = mid
		}
	}
	return left, left < n && cmp(array[left], value) == .Equal
}

/*
Check whether two slices have the same length and elements.

Inputs:
- `a`: First slice
- `b`: Second slice

Returns:
- `true` if the slices are equal, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	equal_example :: proc() {
		a := []int{1, 2, 3}
		b := []int{1, 2, 3}
		c := []int{1, 2, 3, 4}
		d := []int{1, 2, 5}

		a_equal_b := slice.equal(a, b)
		fmt.println(a_equal_b)

		a_equal_c := slice.equal(a, c)
		fmt.println(a_equal_c)

		a_equal_d := slice.equal(a, d)
		fmt.println(a_equal_d)
	}

Outputs:

	true
	false
	false

*/
@(require_results)
equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_comparable(E) #no_bounds_check {
	if len(a) != len(b) {
		return false
	}
	when intrinsics.type_is_simple_compare(E) {
		if len(a) == 0 {
			// Empty slices are always equivalent to each other.
			//
			// This check is here in the event that a slice with a `data` of
			// nil is compared against a slice with a non-nil `data` but a
			// length of zero.
			//
			// In that case, `memory_compare` would return -1 or +1 because one
			// of the pointers is nil.
			return true
		}
		return runtime.memory_compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
	} else {
		for i in 0..<len(a) {
			if a[i] != b[i] {
				return false
			}
		}
		return true
	}
}

/*
Check whether two slices have the same length and elements.

Works exactly the same as `equal`, but only for slices that can be checked for equality just by comparing thier memory.

**WARNING: If one of the slices is nil but the other is not this procedure will return `false`.**
*/
@(require_results)
simple_equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_simple_compare(E) {
	if len(a) != len(b) {
		return false
	}
	return runtime.memory_compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
}

/*
Return the prefix length common between two slices.

Inputs:
- `a`: First slice
- `b`: Second slice

Returns:
- `n`: Length of the common prefix

Example:

	import "core:slice"
	import "core:fmt"

	prefix_length_example :: proc() {
		a := []int{1, 2, 50, 60}
		b := []int{1, 2, 70}
		length := slice.prefix_length(a, b)
		fmt.println(length)
	}

Outputs:

	2
*/
@(require_results)
prefix_length :: proc(a, b: $T/[]$E) -> (n: int) where intrinsics.type_is_comparable(E) {
	_len := builtin.min(len(a), len(b))

	#no_bounds_check for n < _len && a[n] == b[n] {
		n += 1
	}
	return
}

/*
Check whether the slice starts with a given prefix.

Inputs:
- `array`: The slice to check
- `prefix`: The prefix to look for

Returns:
- `true` if the slice starts with a given prefix, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	has_prefix_example :: proc() {
		a := []int{1, 2, 3, 4}
		b := []int{1, 2}
		c := []int{1, 2, 5}

		has_12_prefix := slice.has_prefix(a, b)
		fmt.println(has_12_prefix)

		has_125_prefix := slice.has_prefix(a, c)
		fmt.println(has_125_prefix)
	}

Output:

	true
	false
*/
@(require_results)
has_prefix :: proc(array: $T/[]$E, prefix: T) -> bool where intrinsics.type_is_comparable(E) {
	n := len(prefix)
	if len(array) >= n {
		return equal(array[:n], prefix)
	}
	return false
}

/*
Check whether the slice ends with a given suffix.

Inputs:
- `array`: The slice to check
- `suffix`: The suffix to look for

Returns:
- `true` if the slice ends with a given suffix, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	has_suffix_example :: proc() {
		a := []int{1, 2, 3, 4}
		b := []int{3, 4}
		c := []int{5, 3, 4}

		has_34_suffix := slice.has_suffix(a, b)
		fmt.println(has_34_suffix)

		has_534_suffix := slice.has_suffix(a, c)
		fmt.println(has_534_suffix)
	}

Output:

	true
	false
*/
@(require_results)
has_suffix :: proc(array: $T/[]$E, suffix: T) -> bool where intrinsics.type_is_comparable(E) {
	array := array
	m, n := len(array), len(suffix)
	if m >= n {
		return equal(array[m-n:], suffix)
	}
	return false
}

/*
Zero the memory contents of a slice.

Inputs:
- `array`: The slice to zero the memory of

Example:

	import "core:slice"
	import "core:fmt"

	zero_example :: proc() {
		array := []int{1, 2, 3, 4}
		slice.zero(array)
		fmt.println(array)
	}

Output:

	[0, 0, 0, 0]
*/
zero :: proc(array: $T/[]$E) #no_bounds_check {
	if len(array) > 0 {
		intrinsics.mem_zero(raw_data(array), size_of(E)*len(array))
	}
}

/*
Fill the slice with a given value.

Inputs:
- `array`: The slice to fill
- `value`: The value to fill the slice with

Example:

	import "core:slice"
	import "core:fmt"

	has_suffix_example :: proc() {
		array := []int{1, 2, 3}
		slice.fill(array, 7)
		fmt.println(array)
	}

Output:

	[7, 7, 7]
*/
fill :: proc(array: $T/[]$E, value: E) #no_bounds_check {
	if len(array) <= 0 {
		return
	}
	array[0] = value
	for i := 1; i < len(array); i *= 2 {
		copy(array[i:], array[:i])
	}
}

/*
Rotate the elements of the slice `k` positions to the left.

Inputs:
- `array`: The slice to rotate the elements of
- `k`: The number of positions to rotate by

Example:

	import "core:slice"
	import "core:fmt"

	rotate_left :: proc() {
		array := []int{1, 2, 3, 4, 5}
		slice.rotate_left(array, 2)
		fmt.println(array)
	}

Outputs:

	[3, 4, 5, 1, 2]
*/
rotate_left :: proc(array: $T/[]$E, k: int) {
	n := len(array)
	left := k %% n
	right := n - left
	// FIXME: (ap29600) this cast is a temporary fix for the compiler not matching
	// [^T] with $P/^$T
	p := cast(^E)raw_data(array)
	ptr_rotate(left, ptr_add(p, left), right)
}

/*
Rotate the elements of the slice `k` positions to the right.

Inputs:
- `array`: The slice to rotate the elements of
- `k`: The number of positions to rotate by

Example:

	import "core:slice"
	import "core:fmt"

	rotate_left :: proc() {
		array := []int{1, 2, 3, 4, 5}
		slice.rotate_right(array, 2)
		fmt.println(array)
	}

Outputs:

	[4, 5, 1, 2, 3]
*/
rotate_right :: proc(array: $T/[]$E, k: int) {
	rotate_left(array, -k)
}

/*
Swap values of two slices.

Requires the slices to be of equal length and non-overlapping.

Inputs:
- `a`: First slice
- `b`: Second slice
- `loc`: Caller location for length assertion (default is #caller_location)

Example:

	import "core:slice"
	import "core:fmt"

	swap_with_slice_example :: proc() {
		a := []rune{'A', 'B', 'C'}
		b := []rune{'x', 'y', 'z'}
		slice.swap_with_slice(a, b)
		fmt.println(a)
		fmt.println(b)
	}

Outputs:

	[x, y, z]
	[A, B, C]
*/
swap_with_slice :: proc(a, b: $T/[]$E, loc := #caller_location) {
	assert(len(a) == len(b), "miss matching slice lengths", loc)

	ptr_swap_non_overlapping(raw_data(a), raw_data(b), len(a)*size_of(E))
}

/*
Concatenate nested slices.

*Allocates Using Provided Allocator*

Inputs:
- `slices`: A slice of nested slices to concatenate
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `res`: The concatenated slice
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	concatenate_example :: proc() {
		a := []int{1, 2}
		b := []int{3, 4}
		c := []int{5}
		result : = slice.concatenate([][]int{a, b, c})
		defer delete(result)
		fmt.println(result)
	}

Outputs:

	[1, 2, 3, 4, 5]
*/
@(require_results)
concatenate :: proc(slices: []$T/[]$E, allocator := context.allocator) -> (res: T, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(slices) == 0 {
		return
	}
	n := 0
	for s in slices {
		n += len(s)
	}
	res = make(T, n, allocator) or_return
	i := 0
	for s in slices {
		i += copy(res[i:], s)
	}
	return
}

/*
Copy a slice into a new slice.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The slice to clone
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)
- `loc`: Caller location for allocation (default is #caller_location)

Returns:
- The cloned slice
- An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	clone_example :: proc() {
		array := []int{1, 2, 3}
		cloned : = slice.clone(array)
		defer delete(cloned)

		slice.fill(array, 7)
		fmt.println(array)
		fmt.println(cloned)
	}

Outputs:

	[7, 7, 7]
	[1, 2, 3]
*/
@(require_results)
clone :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> ([]E, runtime.Allocator_Error) #optional_allocator_error {
	d, err := make([]E, len(array), allocator, loc)
	copy(d[:], array)
	return d, err
}

/*
Copy a slice into a new dynamic array.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The slice to clone
- `allocator`: The allocator to use for the resulting array (default is `context.aloocator`)
- `loc`: Caller location for allocation (default is #caller_location)

Returns:
- The dynamic array filled with the contents of the slice
- An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	clone_to_dynamic_example :: proc() {
		array := []int{1, 2, 3}
		cloned : = slice.clone_to_dynamic(array)
		defer delete(cloned)

		append(&cloned, 4)
		fmt.println(array)
		fmt.println(cloned)
	}

Outputs:

	[1, 2, 3]
	[1, 2, 3, 4]
*/
clone_to_dynamic :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> ([dynamic]E, runtime.Allocator_Error) #optional_allocator_error {
	d, err := make([dynamic]E, len(array), allocator, loc)
	copy(d[:], array)
	return d, err
}

/*
Alias for `clone_to_dynamic`.
*/
to_dynamic :: clone_to_dynamic

/*
Convert a slice into a dynamic array without cloning or allocating memory.

The resulting array has a length of 0, has a capacity equal to the length of the slice and is backed by
`runtime.nil_allocator`.

Inputs:
- `array`: The slice to convert

Returns:
- A dynamic array using the contents of the slice as backing memory

Example:

	import "core:slice"
	import "core:fmt"

	into_dynamic_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		dyn : = slice.into_dynamic(array)
		append(&dyn, 100)
		append(&dyn, 200)
		fmt.println(dyn)
		fmt.println(array)
	}

Outputs:

	[100, 200]
	[100, 200, 3, 4, 5]
*/
@(require_results)
into_dynamic :: proc(array: $T/[]$E) -> [dynamic]E {
	s := transmute(runtime.Raw_Slice)array
	d := runtime.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = runtime.nil_allocator(),
	}
	return transmute([dynamic]E)d
}

/*
Return the length of the slice.

Equivalent to using `len`.

Inputs:
- `array`: The slice to evaluate

Returns:
- Length of the slice
*/
@(require_results)
length :: proc(array: $T/[]$E) -> int {
	return len(array)
}

/*
Check if the slice is empty.

Inputs:
- `array`: The slice to evaluate

Returns:
- `true` if the slice has zero length, `false` otherwise
*/
@(require_results)
is_empty :: proc(a: $T/[]$E) -> bool {
	return len(a) == 0
}

/*
Return the byte size of the backing data.

Inputs:
- `array`: The slice to evaluate

Returns:
- The byte size of the backing data

Example:

	import "core:slice"
	import "core:fmt"

	size_example :: proc() {
		array := []i32{1, 2, 3}
		size : = slice.size(array)
		fmt.println(size)
	}

Outputs:

	12
*/
@(require_results)
size :: proc "contextless" (array: $T/[]$E) -> int {
	return len(array) * size_of(E)
}

/*
Split the slice into two slices, one up to, one from the target index.

Inputs:
- `array`: The slice to split
- `index`: The index to split at

Returns:
- `left`: The slice including elements up to index
- `right`: The slice including elements at index and after

Example:

	import "core:slice"
	import "core:fmt"

	split_at_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		left, right : = slice.split_at(array, 2)
		fmt.println(left, right)
	}

Outputs:

	[1, 2] [3, 4, 5]
*/
@(require_results)
split_at :: proc(array: $T/[]$E, index: int) -> (left, right: T) {
	return array[:index], array[index:]
}

/*
Return the first element and the remaining slice.

Inputs:
- `array`: The slice to split

Returns:
- `first`: The extracted first element
- `rest`: The remaining slice excluding the returned first element

Example:

	import "core:slice"
	import "core:fmt"

	split_first_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		first, rest : = slice.split_first(array)
		fmt.println(first, rest)
	}

Outputs:

	1 [2, 3, 4, 5]
*/
@(require_results)
split_first :: proc(array: $T/[]$E) -> (first: E, rest: T) {
	return array[0], array[1:]
}

/*
Return the last element and the remaining slice.

Inputs:
- `array`: The slice to split

Returns:
- `rest`: The remaining slice excluding the returned last element
- `last`: The extracted last element

Example:

	import "core:slice"
	import "core:fmt"

	split_last_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		rest, last : = slice.split_last(array)
		fmt.println(rest, last)
	}

Outputs:

	[1, 2, 3, 4] 5
*/
@(require_results)
split_last :: proc(array: $T/[]$E) -> (rest: T, last: E) {
	n := len(array)-1
	return array[:n], array[n]
}

/*
Return the first element of the slice.

Inputs:
- `array`: The slice to extract the first element from

Returns:
- The extracted first element
*/
@(require_results)
first :: proc(array: $T/[]$E) -> E {
	return array[0]
}

/*
Return the last element of the slice.

Inputs:
- `array`: The slice to extract the last element from

Returns:
- The extracted last element
*/
@(require_results)
last :: proc(array: $T/[]$E) -> E {
	return array[len(array)-1]
}

/*
Return a pointer to the first element of the slice or `nil` if slice is empty.

Inputs:
- `array`: The slice to get the pointer from

Returns:
- Pointer to the first element or `nil` if slice is empty
*/
@(require_results)
first_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[0]
	}
	return nil
}

/*
Return a pointer to the last element of the slice or `nil` if slice is empty.

Inputs:
- `array`: The slice to get the pointer from

Returns:
- Pointer to the last element or `nil` if slice is empty
*/
@(require_results)
last_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[len(array)-1]
	}
	return nil
}

/*
Return the element at the specified index and whether the retrieval succeeded.

Inputs:
- `array`: The slice to get the element from
- `index`: The index of the desired element

Returns:
- `value`: The retrieved element or a default value
- `ok`: `true` if the element was found, `false` otherwise
*/
@(require_results)
get :: proc(array: $T/[]$E, index: int) -> (value: E, ok: bool) {
	if uint(index) < len(array) {
		value = array[index]
		ok = true
	}
	return
}

/*
Return a pointer to the element at the specified index and whether the retrieval succeeded.

Inputs:
- `array`: The slice to get the pointer from
- `index`: The index of the desired element

Returns:
- `ptr`: A pointer to the desired element or `nil`
- `ok`: `true` if the element was found, `false` otherwise
*/
@(require_results)
get_ptr :: proc(array: $T/[]$E, index: int) -> (ptr: ^E, ok: bool) {
	if uint(index) < len(array) {
		ptr = &array[index]
		ok = true
	}
	return
}

/*
Return a multi-pointer to the slice data.

Equivalent to `raw_data`.

Inputs:
- `array`: The slice to get the pointer to

Returns:
- A multi-pointer to the slice data.
*/
@(require_results)
as_ptr :: proc(array: $T/[]$E) -> [^]E {
	return raw_data(array)
}

/*
Create a new slice with values transformed using the provided procedure.

*Allocates Using Provided Allocator*

Note: Named `mapper`, because `map` is a reserved keyword.

Inputs:
- `array`: The input slice
- `f`: The procedure used to transform the values
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `mapped`: A new slice with values transformed using `f`
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	mapper_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		add_one :: proc(a: int) -> int {
			return a + 1
		}
		mapped : = slice.mapper(array, add_one)
		defer delete(mapped)
		fmt.println(mapped)
	}

Outputs:

	[2, 3, 4, 5, 6]
*/
@(require_results)
mapper :: proc(array: $T/[]$U, f: proc(U) -> $V, allocator := context.allocator) -> (mapped: []V, err: runtime.Allocator_Error) #optional_allocator_error {
	mapped = make([]V, len(array), allocator) or_return
	for v, i in array {
		mapped[i] = f(v)
	}
	return
}

/*
Executes a procedure on each slice element, in order, passing in the return value from the calculation on the preceding element.

The final result of running the reducer across all elements of the array is a single value.

Inputs:
- `array`: The input slice
- `initial`: The initial value of the accumulator
- `f`: The reducer procedure; takes the accumulator as the first and value as the second argument and returns a new accumulator

Returns:
- The final value of the accumulator

Example:

	import "core:slice"
	import "core:fmt"

	reduce_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		sum_even_odd :: proc(even_odd: [2]int, value: int) -> [2]int {
			if value % 2 == 0 {
				return {even_odd[0] + value, even_odd[1]}
			}
			return {even_odd[0], even_odd[1] + value}
		}
		even_odd : = slice.reduce(array, [2]int{}, sum_even_odd)
		fmt.println(even_odd)
	}

Outputs:

	[6, 9]
*/
@(require_results)
reduce :: proc(array: $T/[]$E, initial: $A, f: proc(A, E) -> A) -> A {
	r := initial
	for v in array {
		r = f(r, v)
	}
	return r
}

/*
Executes a procedure on each slice element, in reverse order, passing in the return value from the calculation on the following element.

The final result of running the reducer across all elements of the array is a single value.

Inputs:
- `array`: The input slice
- `initial`: The initial value of the accumulator
- `f`: The reducer procedure; takes the accumulator as the first and value as the second argument and returns a new accumulator

Returns:
- The final value of the accumulator

Example:

	import "core:slice"
	import "core:fmt"

	reduce_reverse_example :: proc() {
		Hero :: struct {
			hitpoints:  int,
			kill_count: int,
		}
		hero := Hero{20, 0}
		enemies := []int{4, 5, 7, 2, 11}
		fight :: proc(hero: Hero, enemy: int) -> Hero {
			if hero.hitpoints >= enemy {
				return {hero.hitpoints - enemy, hero.kill_count + 1}
			}
			return {0, hero.kill_count}
		}
		result : = slice.reduce_reverse(enemies, hero, fight)
		fmt.println(result)
	}

Outputs:

	Hero{hitpoints = 0, kill_count = 3}
*/
@(require_results)
reduce_reverse :: proc(array: $T/[]$E, initial: $A, f: proc(A, E) -> A) -> A {
	r := initial
	for i := len(array)-1; i >= 0; i -= 1 {
		#no_bounds_check r = f(r, array[i])
	}
	return r
}

/*
Create a new slice with only those values that pass the provided predicate.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The input slice
- `f`: The predicate used to check values
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `filtered`: A new slice with values filtered using `f`
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	filter_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		is_even :: proc(a: int) -> bool {
			return a % 2 == 0
		}
		filtered : = slice.filter(array, is_even)
		defer delete(filtered)
		fmt.println(filtered)
	}

Outputs:

	[2, 4]
*/
@(require_results)
filter :: proc(array: $T/[]$E, f: proc(E) -> bool, allocator := context.allocator) -> (filtered: T, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]E, 0, 0, allocator) or_return
	for v in array {
		if f(v) {
			append(&r, v)
		}
	}
	return r[:], nil
}

/*
Create a new slice with only those values that pass the provided predicate stored in reverse order.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The input slice
- `f`: The predicate used to check values
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `filtered`: A new slice with values filtered using `f` stored in reverse order
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	filter_reverse_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		is_odd :: proc(a: int) -> bool {
			return a % 2 != 0
		}
		filtered : = slice.filter_reverse(array, is_odd)
		defer delete(filtered)
		fmt.println(filtered)
	}

Outputs:

	[5, 3, 1]
*/
@(require_results)
filter_reverse :: proc(array: $T/[]$E, f: proc(E) -> bool, allocator := context.allocator) -> (filtered: T, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]E, 0, 0, allocator) or_return
	for i := len(array)-1; i >= 0; i -= 1 {
		#no_bounds_check v := array[i]
		if f(v) {
			append(&r, v)
		}
	}
	return r[:], nil
}

/*
Perform reduction over the slice and return all computed values of the accumulator.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The input slice
- `initial`: The initial value of the accumulator
- `f`: The reducer procedure; takes the accumulator as the first and value as the second argument and returns a new accumulator
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `res`: All computed values of the accumulator
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	scanner_example :: proc() {
		array := []int{1, 2, 3, 4, 5}
		sum :: proc(a, b: int) -> int {
			return a + b
		}
		scanned : = slice.scanner(array, 0, sum)
		defer delete(scanned)
		fmt.println(scanned)
	}

Outputs:

	[1, 3, 6, 10, 15]
*/
@(require_results)
scanner :: proc (array: $T/[]$E, initial: $A, f: proc(A, E) -> A, allocator := context.allocator) -> (res: []A, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(array) == 0 { return }

	res = make([]A, len(array), allocator) or_return
	p := as_ptr(array)
	q := as_ptr(res)
	r := initial

	for l := len(array); l > 0; l -= 1 {
		r = f(r, p[0])
		q[0] = r
		p = p[1:]
		q = q[1:]
	}

	return
}

/*
Create a slice with contents of the input slice repeated a number of times.

*Allocates Using Provided Allocator*

Inputs:
- `array`: The input slice
- `count`: The number of times to repeat the contents
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `repeated`: Slice containing the repeated values
- `err`: An `Allocator_Error`, if allocation failed

Example:

	import "core:slice"
	import "core:fmt"

	repeat_example :: proc() {
		array := []int{1, 2}
		repeated : = slice.repeat(array, 3)
		defer delete(repeated)
		fmt.println(repeated)
	}

Outputs:

	[1, 2, 1, 2, 1, 2]
*/
@(require_results)
repeat :: proc(array: $T/[]$E, count: int, allocator := context.allocator) -> (repeated: T, err: runtime.Allocator_Error) #optional_allocator_error {
	if count < 0 {
		panic("slice: negative repeat count")
	} else if count > 0 && (len(array)*count)/count != len(array) {
		panic("slice: repeat count will cause an overflow")
	}

	repeated = make(T, len(array)*count, allocator) or_return
	i := copy(repeated, array)
	for i < len(repeated) { // 2^N trick to reduce the need to copy
		copy(repeated[i:], repeated[:i])
		i *= 2
	}
	return
}

/*
Replace consecutive runs of equal elements with a single copy.

The procedures modifies the slice in-place and returns the modified slice.

Inputs:
- `array`: The input slice

Returns:
- The modifed slice with only unique elements

Example:

	import "core:slice"
	import "core:fmt"

	unique_example :: proc() {
		array := []int{1, 2, 2, 3, 3, 3, 7, 7}
		unique : = slice.unique(array)
		fmt.println(unique)
		fmt.println(array)
	}

Outputs:

	[1, 2, 3, 7]
	[1, 2, 3, 7, 3, 3, 7, 7]
*/
@(require_results)
unique :: proc(array: $T/[]$E) -> T where intrinsics.type_is_comparable(E) #no_bounds_check {
	if len(array) < 2 {
		return array
	}
	i := 1
	for j in 1..<len(array) {
		if array[j] != array[j-1] {
			if i != j {
				array[i] = array[j]
			}
			i += 1
		}
	}

	return array[:i]
}

/*
Replace consecutive runs of equal elements with a single copy using a procedure for equality checks.

The procedures modifies the slice in-place and returns the modified slice.

Inputs:
- `array`: The input slice
- `eq`: The procedure to use for equality checks

Returns:
- The modifed slice with only unique elements

Example:

	import "core:slice"
	import "core:fmt"

	unique_proc_example :: proc() {
		Toy :: struct {
			kind:  string,
			owner: string,
		}
		array := []Toy{{"horse", "Joe"}, {"horse", "Amy"}, {"robot", "Joe"}}
		eq_kind :: proc(a, b: Toy) -> bool {
			return a.kind == b.kind
		}
		unique : = slice.unique_proc(array, eq_kind)
		fmt.println(unique)
	}

Outputs:

	[Toy{kind = "horse", owner = "Joe"}, Toy{kind = "robot", owner = "Joe"}]
*/
@(require_results)
unique_proc :: proc(array: $T/[]$E, eq: proc(E, E) -> bool) -> T #no_bounds_check {
	if len(array) < 2 {
		return array
	}
	i := 1
	for j in 1..<len(array) {
		if !eq(array[j], array[j-1]) {
			if i != j {
				array[i] = array[j]
			}
			i += 1
		}
	}

	return array[:i]
}

/*
Find the smallest element in the slice.

Inputs:
- `array`: The input slice

Returns:
- `min`: The smallest element found, or a zero-initialized value
- `ok`: `true` if the slice had at least one element, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	min_example :: proc() {
		array := []int{5, 7, 1, 2}
		min, ok : = slice.min(array)
		fmt.println(min, ok)
	}

Outputs:

	1 true
*/
@(require_results)
min :: proc(array: $T/[]$E) -> (min: E, ok: bool) where intrinsics.type_is_ordered(E) #optional_ok {
	if len(array) != 0 {
		min = array[0]
		ok = true
		for v in array[1:] {
			min = builtin.min(min, v)
		}
	}
	return
}

/*
Find the largest element in the slice.

Inputs:
- `array`: The input slice

Returns:
- `max`: The largest element found, or a zero-initialized value
- `ok`: `true` if the slice had at least one element, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	max_example :: proc() {
		array := []int{5, 7, 1, 2}
		max, ok : = slice.max(array)
		fmt.println(max, ok)
	}

Outputs:

	7 true
*/
@(require_results)
max :: proc(array: $T/[]$E) -> (max: E, ok: bool) where intrinsics.type_is_ordered(E) #optional_ok {
	if len(array) != 0 {
		max = array[0]
		ok = true
		for v in array[1:] {
			max = builtin.max(max, v)
		}
	}
	return
}

/*
Find the smallest and the largest elements in the slice.

Inputs:
- `array`: The input slice

Returns:
- `min`: The smallest element found, or a zero-initialized value
- `max`: The largest element found, or a zero-initialized value
- `ok`: `true` if the slice had at least one element, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	max_example :: proc() {
		array := []int{5, 7, 1, 2}
		min, max, ok : = slice.min_max(array)
		fmt.println(min, max, ok)
	}

Outputs:

	1 7 true
*/
@(require_results)
min_max :: proc(array: $T/[]$E) -> (min, max: E, ok: bool) where intrinsics.type_is_ordered(E) {
	if len(array) != 0 {
		min, max = array[0], array[0]
		ok = true
		for v in array[1:] {
			min = builtin.min(min, v)
			max = builtin.max(max, v)
		}
	}
	return
}

/*
Find the index of the first smallest element in the slice.

Inputs:
- `array`: The input slice

Returns:
- `min_index`: The index of the first smallest element found, or `-1`
- `ok`: `true` if the slice had at least one element, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	min_index_example :: proc() {
		array := []int{5, 7, 1, 2}
		min_index, ok : = slice.min_index(array)
		fmt.println(min_index, ok)
	}

Outputs:

	2 true
*/
@(require_results)
min_index :: proc(array: $T/[]$E) -> (min_index: int, ok: bool) where intrinsics.type_is_ordered(E) #optional_ok {
	if len(array) == 0 {
		return -1, false
	}
	min_index = 0
	min_value := array[0]
	for v, i in array[1:] {
		if v < min_value {
			min_value = v
			min_index = i+1
		}
	}
	return min_index, true
}

/*
Find the index of the first largest element in the slice.

Inputs:
- `array`: The input slice

Returns:
- `max_index`: The index of the first largest element found, or `-1`
- `ok`: `true` if the slice had at least one element, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	max_index_example :: proc() {
		array := []int{5, 7, 1, 2}
		max_index, ok : = slice.max_index(array)
		fmt.println(max_index, ok)
	}

Outputs:

	1 true
*/
@(require_results)
max_index :: proc(array: $T/[]$E) -> (max_index: int, ok: bool) where intrinsics.type_is_ordered(E) #optional_ok {
	if len(array) == 0 {
		return -1, false
	}
	max_index = 0
	max_value := array[0]
	for v, i in array[1:] {
		if v > max_value {
			max_value = v
			max_index = i+1
		}
	}
	return max_index, true
}

/*
Check if any of the slice elements are equal to a given value.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `true` if any element is equal to the value provided, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	any_of_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		has_b := slice.any_of(array, 'A')
		has_x := slice.any_of(array, 'x')
		fmt.println(has_b, has_x)
	}

Outputs:

	true false
*/
@(require_results)
any_of :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	for v in array {
		if v == value {
			return true
		}
	}
	return false
}

/*
Check if none of the slice elements are equal to a given value.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `true` if none of the elements are equal to the value provided, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	none_of_example :: proc() {
		array := []rune{'A', 'B', 'C'}
		no_a := slice.none_of(array, 'A')
		no_x := slice.none_of(array, 'x')
		fmt.println(no_a, no_x)
	}

Outputs:

	false true
*/
@(require_results)
none_of :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	for v in array {
		if v == value {
			return false
		}
	}
	return true
}


/*
Check if all of the slice elements are equal to a given value.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- `true` if all of the elements are equal to the value provided, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	all_of_example :: proc() {
		array := []rune{7, 7, 2, 7}
		all_7 := slice.all_of(array, 7)
		fmt.println(all_7)
	}

Outputs:

	false
*/
@(require_results)
all_of :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	if len(array) == 0 {
		return false
	}
	for v in array {
		if v != value {
			return false
		}
	}
	return true
}

/*
Check if any of the slice elements satisfy a given predicate.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to test values with

Returns:
- `true` if any element satisfies the predicate, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	any_of_proc_example :: proc() {
		array := []int{5, 6, 2, 8}
		gt_7 :: proc(a: int) -> bool {
			return a > 7
		}
		has_gt_7 := slice.any_of_proc(array, gt_7)
		fmt.println(has_gt_7)
	}

Outputs:

	true
*/
@(require_results)
any_of_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> bool {
	for v in array {
		if f(v) {
			return true
		}
	}
	return false
}

/*
Check if none of the slice elements satisfy a given predicate.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to test values with

Returns:
- `true` if none of the elements satisfy the predicate, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	none_of_proc_example :: proc() {
		array := []int{1, 2, 5, 0}
		is_negative :: proc(a: int) -> bool {
			return a < 0
		}
		no_negative := slice.none_of_proc(array, is_negative)
		fmt.println(no_negative)
	}

Outputs:

	true
*/
@(require_results)
none_of_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> bool {
	for v in array {
		if f(v) {
			return false
		}
	}
	return true
}

/*
Check if all of the slice elements satisfy a given predicate.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to test values with

Returns:
- `true` if all of the elements satisfy the predicate, `false` otherwise

Example:

	import "core:slice"
	import "core:fmt"

	all_of_proc_example :: proc() {
		array := []int{1, 2, 5, 0}
		is_positive :: proc(a: int) -> bool {
			return a > 0
		}
		all_positive := slice.all_of_proc(array, is_positive)
		fmt.println(all_positive)
	}

Outputs:

	false
*/
@(require_results)
all_of_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> bool {
	if len(array) == 0 {
		return false
	}
	for v in array {
		if !f(v) {
			return false
		}
	}
	return true
}

/*
Return the number of occurrences of a value in a slice.

Inputs:
- `array`: The slice to search in
- `value`: The value to search for

Returns:
- The number of slice elements equal to the value

Example:

	import "core:slice"
	import "core:fmt"

	count_example :: proc() {
		array := []int{7, 7, 2, 7}
		sevens := slice.count(array, 7)
		fmt.println(sevens)
	}

Outputs:

	3
*/
@(require_results)
count :: proc(array: $T/[]$E, value: E) -> (n: int) where intrinsics.type_is_comparable(E) {
	for v in array {
		if v == value {
			n += 1
		}
	}
	return
}

/*
Return the number of slice elements that satisfy a given predicate.

Inputs:
- `array`: The slice to search in
- `f`: The predicate to test values with

Returns:
- The number of slice elements that satisfy the predicate

Example:

	import "core:slice"
	import "core:fmt"

	count_proc_example :: proc() {
		array := []int{1, -8, 2, 5, 0}
		is_positive :: proc(a: int) -> bool {
			return a > 0
		}
		positive_count := slice.count_proc(array, is_positive)
		fmt.println(positive_count)
	}

Outputs:

	3
*/
@(require_results)
count_proc :: proc(array: $T/[]$E, f: proc(E) -> bool) -> (n: int) {
	for v in array {
		if f(v) {
			n += 1
		}
	}
	return
}

/*
Calculate the dot product of two numeric slices.

Inputs:
- `a`: First slice
- `b`: Second slice

Returns:
- `dot`: The dot product or `0` if the slices have different lengths
- `ok`: `true` when the slices have equal lengths, `false` otherwise
*/
@(require_results)
dot_product :: proc(a, b: $T/[]$E) -> (dot: E, ok: bool)
	where intrinsics.type_is_numeric(E) {
	if len(a) != len(b) {
		return
	}
	#no_bounds_check for _, i in a {
		dot += a[i] * b[i]
	}
	return dot, true
}

/*
Convert a pointer to an enumerated array to a slice of the element type.

Inputs:
- `ptr`: Pointer to the enumerated array

Returns:
- A slice of the element type

Example:

	import "core:slice"
	import "core:fmt"

	enumerated_array_example :: proc() {
		Ice_Cream_Flavor :: enum {
			Chocolate,
			Vanilla,
			Strawberry,
		}
		flavor_rating: [Ice_Cream_Flavor]int = {
			.Chocolate  = 5, 
			.Vanilla    = 4,
			.Strawberry = 2,
		}
		rating_slice := slice.enumerated_array(&flavor_rating)
		fmt.println(rating_slice)
	}

Outputs:

	[5, 4, 2]
*/
@(require_results)
enumerated_array :: proc(ptr: ^$T) -> []intrinsics.type_elem_type(T)
	where intrinsics.type_is_enumerated_array(T) {
	return ([^]intrinsics.type_elem_type(T))(ptr)[:len(T)]
}

/*
Turn a slice of enums into a bit_set of that enum.

Inputs:
- `enums`: The slice of enums
- `T`: The type of the bitset

Returns:
- `bits`: The resulting bit_set

Example:

	import "core:slice"
	import "core:fmt"

	enum_slice_to_bitset_example :: proc() {
		Text_Style :: enum {
			Bold,
			Italic,
			Underline,
		}
		Text_Styles :: distinct bit_set[Text_Style]

		styles := []Text_Style{.Bold, .Underline}
		bitset := slice.enum_slice_to_bitset(styles, Text_Styles)
		fmt.println(bitset)
	}

Outputs:

	Text_Styles{Bold, Underline}
*/
@(require_results)
enum_slice_to_bitset :: proc(enums: []$E, $T: typeid/bit_set[E]) -> (bits: T) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	for v in enums {
		bits += {v}
	}
	return
}

/*
Turn a `bit_set` into a slice of enums.

Inputs:
- `buf`: The slice backing the output slice
- `bits`: The input `bit_set`

Returns:
- `slice`: The slice of enums

Example:

	import "core:slice"
	import "core:fmt"

	bitset_to_enum_slice_with_buffer_example :: proc() {
		Direction :: enum {N, E, S, W}
		Directions :: distinct bit_set[Direction]

		bits := Directions{.N, .S}
		buf := make([]Direction, 4)
		defer delete(buf)
		enums := slice.bitset_to_enum_slice_with_buffer(buf, bits)
		fmt.println(enums)
	}

Outputs:

	["N", "S"]
*/
@(require_results)
bitset_to_enum_slice_with_buffer :: proc(buf: []$E, bits: $T) -> (slice: []E) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	count := 0
	for v in bits {
		buf[count] = v
		count += 1
	}
	return buf[:count]
}

/*
Turn a `bit_set` into a slice of enums.

*Allocates Using Provided Allocator*

Inputs:
- `bits`: The input `bit_set`
- `E`: Type of the enum
- `allocator`: The allocator to use for the resulting slice (default is `context.aloocator`)

Returns:
- `slice`: The slice of enums

Example:

	import "core:slice"
	import "core:fmt"

	bitset_to_enum_slice_with_make_example :: proc() {
		Direction :: enum {N, E, S, W}
		Directions :: distinct bit_set[Direction]

		bits := Directions{.N, .S}
		enums := slice.bitset_to_enum_slice_with_make(bits, Direction)
		defer delete(enums)
		fmt.println(enums)
	}

Outputs:

	["N", "S"]
*/
@(require_results)
bitset_to_enum_slice_with_make :: proc(bits: $T, $E: typeid, allocator := context.allocator) -> (slice: []E) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	buf := make([]E, card(bits), allocator)
	return bitset_to_enum_slice(buf, bits)
}

/*
Turn a `bit_set` into a slice of enums.
*/
bitset_to_enum_slice :: proc{bitset_to_enum_slice_with_make, bitset_to_enum_slice_with_buffer}
