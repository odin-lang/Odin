/*
A dynamically-sized array of bits.

The Bit Array can be used in several ways:

By default you don't need to instantiate a `Bit_Array`.
Example:
	package test

	import "core:fmt"
	import ba "core:container/bit_array"

	main :: proc() {
		bits: ba.Bit_Array

		// returns `true`
		fmt.println(ba.set(&bits, 42))

		// returns `false`, `false`, because this Bit Array wasn't created to allow negative indices.
		was_set, was_retrieved := ba.get(&bits, -1)
		fmt.println(was_set, was_retrieved)
		ba.destroy(&bits)
	}

A `Bit_Array` can optionally allow for negative indices, if the minimum value was given during creation.
Example:
	package test

	import "core:fmt"
	import ba "core:container/bit_array"

	main :: proc() {
		Foo :: enum int {
			Negative_Test = -42,
			Bar           = 420,
			Leaves        = 69105,
		}

		bits := ba.create_from_enum(Foo)
		defer ba.destroy(bits)

		assert(bits.bias   == int(Foo.Negative_Test))
		assert(bits.length == abs(int(min(Foo))) + int(max(Foo)))

		fmt.printfln("Set(Bar):             %v", ba.set(bits, Foo.Bar))
		fmt.printfln("Get(Bar):             %v", ba.get(bits, Foo.Bar))
		fmt.printfln("Set(Negative_Test):   %v", ba.set(bits, Foo.Negative_Test))
		fmt.printfln("Get(Leaves):          %v", ba.get(bits, Foo.Leaves))
		fmt.printfln("Get(Leaves):          %v", ba.unsafe_get(bits, Foo.Leaves))
		fmt.printfln("Get(Negative_Test):   %v", ba.get(bits, Foo.Negative_Test))
		fmt.printfln("Unset(Negative_Test): %v", ba.unset(bits, Foo.Negative_Test))
		assert(ba.get(bits, Foo.Negative_Test) == false)
	}
*/
package container_dynamic_bit_array