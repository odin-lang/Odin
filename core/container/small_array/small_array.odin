package container_small_array

import "base:builtin"
import "base:runtime"
_ :: runtime

/*
A fixed-size stack-allocated array operated on in a dynamic fashion.

Fields:
- `data`: The underlying array
- `len`: Amount of items that the `Small_Array` currently holds

Example:

	import "core:container/small_array"

	example :: proc() {
		a: small_array.Small_Array(100, int)
		small_array.push_back(&a, 10)
	}
*/
Small_Array :: struct($N: int, $T: typeid) where N >= 0 {
	data: [N]T,
	len:  int,
}

/*
Returns the amount of items in the small-array.

**Inputs**
- `a`: The small-array

**Returns**
- the amount of items in the array
*/
len :: proc "contextless" (a: $A/Small_Array) -> int {
	return a.len
}

/*
Returns the capacity of the small-array.

**Inputs**
- `a`: The small-array

**Returns** the capacity
*/
cap :: proc "contextless" (a: $A/Small_Array) -> int {
	return builtin.len(a.data)
}

/*
Returns how many more items the small-array could fit.

**Inputs**
- `a`: The small-array

**Returns**
- the number of unused slots
*/
space :: proc "contextless" (a: $A/Small_Array) -> int {
	return builtin.len(a.data) - a.len
}

/*
Returns a slice of the data.

**Inputs**
- `a`: The pointer to the small-array

**Returns**
- the slice

Example:

	import "core:container/small_array"
	import "core:fmt"

	slice_example :: proc() {
		print :: proc(a: ^small_array.Small_Array($N, int)) {
			for item in small_array.slice(a) {
				fmt.println(item)
			}
		}

		a: small_array.Small_Array(5, int)
		small_array.push_back(&a, 1)
		small_array.push_back(&a, 2)
		print(&a)
	}

Output:

	1
	2
*/
slice :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> []T {
	return a.data[:a.len]
}

/*
Get a copy of the item at the specified position.
This operation assumes that the small-array is large enough.

This will result in:
	- the value if 0 <= index < len
	- the zero value of the type if len < index < capacity
	- 'crash' if capacity < index or index < 0

**Inputs**
- `a`: The small-array
- `index`: The position of the item to get

**Returns**
- the element at the specified position
*/
get :: proc "contextless" (a: $A/Small_Array($N, $T), index: int) -> T {
	return a.data[index]
}

/*
Get a pointer to the item at the specified position.
This operation assumes that the small-array is large enough.

This will result in:
	- the pointer if 0 <= index < len
	- the pointer to the zero value if len < index < capacity
	- 'crash' if capacity < index or index < 0

**Inputs**
- `a`: A pointer to the small-array
- `index`: The position of the item to get

**Returns**
- the pointer to the element at the specified position
*/
get_ptr :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int) -> ^T {
	return &a.data[index]
}

/*
Attempt to get a copy of the item at the specified position.

**Inputs**
- `a`: The small-array
- `index`: The position of the item to get

**Returns**
- the element at the specified position
- true if element exists, false otherwise

Example:

	import "core:container/small_array"
	import "core:fmt"

	get_safe_example :: proc() {
		a: small_array.Small_Array(5, rune)
		small_array.push_back(&a, 'A')
		
		fmt.println(small_array.get_safe(a, 0) or_else 'x')
		fmt.println(small_array.get_safe(a, 1) or_else 'x')
	}

Output:

	A
	x

*/
get_safe :: proc(a: $A/Small_Array($N, $T), index: int) -> (T, bool) #no_bounds_check {
	if index < 0 || index >= a.len {
		return {}, false
	}
	return a.data[index], true
}

/*
Get a pointer to the item at the specified position.

**Inputs**
- `a`: A pointer to the small-array
- `index`: The position of the item to get

**Returns** 
- the pointer to the element at the specified position
- true if element exists, false otherwise
*/
get_ptr_safe :: proc(a: ^$A/Small_Array($N, $T), index: int) -> (^T, bool) #no_bounds_check {
	if index < 0 || index >= a.len {
		return {}, false
	}
	return &a.data[index], true
}

/*
Set the element at the specified position to the given value.
This operation assumes that the small-array is large enough.

This will result in:
	- the value being set if 0 <= index < capacity
	- 'crash' otherwise

**Inputs**
- `a`: A pointer to the small-array
- `index`: The position of the item to set
- `value`: The value to set the element to

Example:

	import "core:container/small_array"
	import "core:fmt"

	set_example :: proc() {
		a: small_array.Small_Array(5, rune)
		small_array.push_back(&a, 'A')
		small_array.push_back(&a, 'B')
		fmt.println(small_array.slice(&a))

		// updates index 0
		small_array.set(&a, 0, 'Z')
		fmt.println(small_array.slice(&a))

		// updates to a position x, where
		// len <= x < cap are not visible since
		// the length of the small-array remains unchanged
		small_array.set(&a, 2, 'X')
		small_array.set(&a, 3, 'Y')
		small_array.set(&a, 4, 'Z')
		fmt.println(small_array.slice(&a))

		// resizing makes the change visible
		small_array.resize(&a, 100)
		fmt.println(small_array.slice(&a))
	}

Output:

	[A, B]
	[Z, B]
	[Z, B]
	[Z, B, X, Y, Z]

*/
set :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, item: T) {
	a.data[index] = item
}

/*
Tries to resize the small-array to the specified length.

The new length will be:
	- `length` if `length` <= capacity
	- capacity if length > capacity

**Inputs**
- `a`: A pointer to the small-array
- `length`: The new desired length

Example:
	
	import "core:container/small_array"
	import "core:fmt"

	resize_example :: proc() {
		a: small_array.Small_Array(5, int)

		small_array.push_back(&a, 1)
		small_array.push_back(&a, 2)
		fmt.println(small_array.slice(&a))
		
		small_array.resize(&a, 1)
		fmt.println(small_array.slice(&a))

		small_array.resize(&a, 100)
		fmt.println(small_array.slice(&a))
	}

Output:
	
	[1, 2]
	[1]
	[1, 2, 0, 0, 0]
*/
resize :: proc "contextless" (a: ^$A/Small_Array, length: int) {
	a.len = min(length, builtin.len(a.data))
}

/*
Attempts to add the given element to the end.

**Inputs**
- `a`: A pointer to the small-array
- `item`: The item to append

**Returns** 
- true if there was enough space to fit the element, false otherwise

Example:
	
	import "core:container/small_array"
	import "core:fmt"

	push_back_example :: proc() {
		a: small_array.Small_Array(2, int)

		assert(small_array.push_back(&a, 1), "this should fit")
		assert(small_array.push_back(&a, 2), "this should fit")
		assert(!small_array.push_back(&a, 3), "this should not fit")

		fmt.println(small_array.slice(&a))
	}

Output:

	[1, 2]
*/
push_back :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.data[a.len] = item
		a.len += 1
		return true
	}
	return false
}

/*
Attempts to add the given element at the beginning.
This operation assumes that the small-array is not empty.

Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.

**Inputs**
- `a`: A pointer to the small-array
- `item`: The item to append

**Returns** 
- true if there was enough space to fit the element, false otherwise

Example:
	
	import "core:container/small_array"
	import "core:fmt"

	push_front_example :: proc() {
		a: small_array.Small_Array(2, int)

		assert(small_array.push_front(&a, 2), "this should fit")
		assert(small_array.push_front(&a, 1), "this should fit")
		assert(!small_array.push_back(&a, 0), "this should not fit")

		fmt.println(small_array.slice(&a))
	}

Output:

	[1, 2]
*/
push_front :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.len += 1
		data := slice(a)
		copy(data[1:], data[:])
		data[0] = item
		return true
	}
	return false
}

/*
Removes and returns the last element of the small-array.
This operation assumes that the small-array is not empty.

**Inputs**
- `a`: A pointer to the small-array

**Returns** 
- a copy of the element removed from the end of the small-array

Example:

	import "core:container/small_array"
	import "core:fmt"

	pop_back_example :: proc() {
		a: small_array.Small_Array(5, int)
		small_array.push(&a, 0, 1, 2)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.pop_back(&a)
		fmt.println("AFTER: ", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2]
	AFTER:  [0, 1]
*/
pop_back :: proc "odin" (a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[a.len-1]
	a.len -= 1
	return item
}

/*
Removes and returns the first element of the small-array.
This operation assumes that the small-array is not empty.

Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.

**Inputs**
- `a`: A pointer to the small-array

**Returns** 
- a copy of the element removed from the beginning of the small-array

Example:

	import "core:container/small_array"
	import "core:fmt"

	pop_front_example :: proc() {
		a: small_array.Small_Array(5, int)
		small_array.push(&a, 0, 1, 2)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.pop_front(&a)
		fmt.println("AFTER: ", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2]
	AFTER:  [1, 2]
*/
pop_front :: proc "odin" (a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[0]
	s := slice(a)
	copy(s[:], s[1:])
	a.len -= 1
	return item
}

/*
Attempts to remove and return the last element of the small array.
Unlike `pop_back`, it does not assume that the array is non-empty.

**Inputs**
- `a`: A pointer to the small-array

**Returns** 
- a copy of the element removed from the end of the small-array
- true if the small-array was not empty, false otherwise

Example:

	import "core:container/small_array"

	pop_back_safe_example :: proc() {
		a: small_array.Small_Array(3, int)
		small_array.push(&a, 1)

		el, ok := small_array.pop_back_safe(&a)
		assert(ok, "there was an element in the array")

		el, ok = small_array.pop_back_safe(&a)
		assert(!ok, "there was NO element in the array")
	}
*/
pop_back_safe :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> (item: T, ok: bool) {
	if N > 0 && a.len > 0 {
		item = a.data[a.len-1]
		a.len -= 1
		ok = true
	}
	return
}

/*
Attempts to remove and return the first element of the small array.
Unlike `pop_front`, it does not assume that the array is non-empty.

Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.

**Inputs**
- `a`: A pointer to the small-array

**Returns** 
- a copy of the element removed from the beginning of the small-array
- true if the small-array was not empty, false otherwise

Example:

	import "core:container/small_array"

	pop_front_safe_example :: proc() {
		a: small_array.Small_Array(3, int)
		small_array.push(&a, 1)

		el, ok := small_array.pop_front_safe(&a)
		assert(ok, "there was an element in the array")

		el, ok = small_array.pop_front_(&a)
		assert(!ok, "there was NO element in the array")
	}
*/
pop_front_safe :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> (item: T, ok: bool) {
	if N > 0 && a.len > 0 {
		item = a.data[0]
		s := slice(a)
		copy(s[:], s[1:])
		a.len -= 1
		ok = true
	}
	return
}

/*
Decreases the length of the small-array by the given amount.
The elements are therefore not really removed and can be
recovered by calling `resize`.

Note: This procedure assumes that the array has a sufficient length.

**Inputs**
- `a`: A pointer to the small-array
- `count`: The amount the length should be reduced by

Example:

	import "core:container/small_array"
	import "core:fmt"

	consume_example :: proc() {
		a: small_array.Small_Array(3, int)
		small_array.push(&a, 0, 1, 2)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.consume(&a, 2)
		fmt.println("AFTER :", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2]
	AFTER : [0]
*/
consume :: proc "odin" (a: ^$A/Small_Array($N, $T), count: int, loc := #caller_location) {
	assert(condition=a.len >= count, loc=loc)
	a.len -= count
}

/*
Removes the element at the specified index while retaining order.

Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.

**Inputs**
- `a`: A pointer to the small-array
- `index`: The position of the element to remove

Example:

	import "core:container/small_array"
	import "core:fmt"

	ordered_remove_example :: proc() {
		a: small_array.Small_Array(4, int)
		small_array.push(&a, 0, 1, 2, 3)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.ordered_remove(&a, 1)
		fmt.println("AFTER :", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2, 3]
	AFTER : [0, 2, 3]
*/
ordered_remove :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, a.len)
	if index+1 < a.len {
		copy(a.data[index:], a.data[index+1:])
	}
	a.len -= 1
}

/*
Removes the element at the specified index without retaining order.

**Inputs**
- `a`: A pointer to the small-array
- `index`: The position of the element to remove

Example:

	import "core:container/small_array"
	import "core:fmt"

	unordered_remove_example :: proc() {
		a: small_array.Small_Array(4, int)
		small_array.push(&a, 0, 1, 2, 3)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.unordered_remove(&a, 1)
		fmt.println("AFTER :", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2, 3]
	AFTER : [0, 3, 2]
*/
unordered_remove :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, a.len)
	n := a.len-1
	if index != n {
		a.data[index] = a.data[n]
	}
	a.len -= 1
}

/*
Sets the length of the small-array to 0.

**Inputs**
- `a`: A pointer to the small-array

Example:
	
	import "core:container/small_array"
	import "core:fmt"

	clear_example :: proc() {
		a: small_array.Small_Array(4, int)
		small_array.push(&a, 0, 1, 2, 3)

		fmt.println("BEFORE:", small_array.slice(&a))
		small_array.clear(&a)
		fmt.println("AFTER :", small_array.slice(&a))
	}

Output:

	BEFORE: [0, 1, 2, 3]
	AFTER : []

*/
clear :: proc "contextless" (a: ^$A/Small_Array($N, $T)) {
	resize(a, 0)
}

/*
Attempts to append all elements to the small-array returning
false if there is not enough space to fit all of them.

**Inputs**
- `a`: A pointer to the small-array
- `item`: The item to append
- ..:

**Returns**
- true if there was enough space to fit the element, false otherwise

Example:
	
	import "core:container/small_array"
	import "core:fmt"

	push_back_elems_example :: proc() {
		a: small_array.Small_Array(100, int)
		small_array.push_back_elems(&a, 0, 1, 2, 3, 4)
		fmt.println(small_array.slice(&a))
	}

Output:

	[0, 1, 2, 3, 4]
*/
push_back_elems :: proc "contextless" (a: ^$A/Small_Array($N, $T), items: ..T) -> bool {
	if a.len + builtin.len(items) <= cap(a^) {
		n := copy(a.data[a.len:], items[:])
		a.len += n
		return true
	}
	return false
}

/*
Tries to insert an element at the specified position.

Note: Performing this operation will cause pointers obtained
through get_ptr(_save) to reference incorrect elements.

**Inputs**
- `a`: A pointer to the small-array
- `item`: The item to insert
- `index`: The index to insert the item at

**Returns**
- true if there was enough space to fit the element, false otherwise

Example:

	import "core:container/small_array"
	import "core:fmt"

	inject_at_example :: proc() {
		arr: small_array.Small_Array(100, rune)
		small_array.push(&arr,  'A', 'C', 'D')
		small_array.inject_at(&arr, 'B', 1)
		fmt.println(small_array.slice(&arr))
	}

Output:

	[A, B, C, D]
*/
inject_at :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T, index: int) -> bool #no_bounds_check {
	if a.len < cap(a^) && index >= 0 && index <= len(a^) {
		a.len += 1
		for i := a.len - 1; i >= index + 1; i -= 1 {
			a.data[i] = a.data[i - 1]
		}
		a.data[index] = item
		return true
	}
	return false
}

// Alias for `push_back`
append_elem  :: push_back
// Alias for `push_back_elems`
append_elems :: push_back_elems

/*
Tries to append the element(s) to the small-array.

**Inputs**
- `a`: A pointer to the small-array
- `item`: The item to append
- ..:

**Returns**
- true if there was enough space to fit the element, false otherwise

Example:

	import "core:container/small_array"
	import "core:fmt"

	push_example :: proc() {
		a: small_array.Small_Array(100, int)
		small_array.push(&a, 0)
		small_array.push(&a, 1, 2, 3, 4)
		fmt.println(small_array.slice(&a))
	}

Output:

	[0, 1, 2, 3, 4]
*/
push   :: proc{push_back, push_back_elems}
// Alias for `push`
append :: proc{push_back, push_back_elems}
