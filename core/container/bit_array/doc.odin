/*
The Bit Array can be used in several ways:

By default you don't need to instantiate a Bit Array.
Example:
	package test

	import "core:fmt"
	import "core:container/bit_array"

	main :: proc() {
		using bit_array

		bits: Bit_Array

		// returns `true`
		fmt.println(set(&bits, 42))

		// returns `false`, `false`, because this Bit Array wasn't created to allow negative indices.
		was_set, was_retrieved := get(&bits, -1)
		fmt.println(was_set, was_retrieved) 
		destroy(&bits)
	}

A Bit Array can optionally allow for negative indices, if the minimum value was given during creation.
Example:
	package test

	import "core:fmt"
	import "core:container/bit_array"

	main :: proc() {
		Foo :: enum int {
			Negative_Test = -42,
			Bar           = 420,
			Leaves        = 69105,
		}

		using bit_array

		bits := create(int(max(Foo)), int(min(Foo)))
		defer destroy(bits)

		fmt.printf("Set(Bar):           %v\n",     set(bits, Foo.Bar))
		fmt.printf("Get(Bar):           %v, %v\n", get(bits, Foo.Bar))
		fmt.printf("Set(Negative_Test): %v\n",     set(bits, Foo.Negative_Test))
		fmt.printf("Get(Leaves):        %v, %v\n", get(bits, Foo.Leaves))
		fmt.printf("Get(Negative_Test): %v, %v\n", get(bits, Foo.Negative_Test))
		fmt.printf("Freed.\n")
	}
*/
package container_dynamic_bit_array
