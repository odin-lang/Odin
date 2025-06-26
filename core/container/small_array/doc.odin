/*
Package small_array implements a dynamic array like
interface on a stack-allocated, fixed-size array.

The Small_Array type is optimal for scenarios where you need
a container for a fixed number of elements of a specific type,
with the total number known at compile time but the exact
number to be used determined at runtime.

Example:
	import "core:fmt"
	import "core:container/small_array"

	create :: proc() -> (result: small_array.Small_Array(10, rune)) {
		// appending single elements
		small_array.push(&result, 'e')
		// pushing a bunch of elements at once
		small_array.push(&result, 'l', 'i', 'x', '-', 'e')
		// pre-pending
		small_array.push_front(&result, 'H')
		// removing elements
		small_array.ordered_remove(&result, 4)
		// resizing to the desired length (the capacity will stay unchanged)
		small_array.resize(&result, 7)
		// inserting elements
		small_array.inject_at(&result, 'p', 5)
		// updating elements
		small_array.set(&result, 3, 'l')
		// getting pointers to elements
		o := small_array.get_ptr(&result, 4)
		o^ = 'o'
		// and much more ....
		return
	}

	// the Small_Array can be an ordinary parameter 'generic' over
	// the actual length to be usable with different sizes
	print_elements :: proc(arr: ^small_array.Small_Array($N, rune)) {
		for r in small_array.slice(arr) {
			fmt.print(r)
		}
	}

	main :: proc() {
		arr := create()
		// ...
		print_elements(&arr)
	}

Output:

	Hellope

*/
package container_small_array
