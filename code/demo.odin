#import "fmt.odin"
#import "utf8.odin"
#import "hash.odin"
#import "mem.odin"

main :: proc() {
	{ // New Standard Library stuff
		s := "Hello"
		fmt.println(s,
		            utf8.valid_string(s),
		            hash.murmur64(s.data, s.count))

		// utf8.odin
		// hash.odin
		//     - crc, fnv, fnva, murmur
		// mem.odin
		//     - Custom allocators
		//     - Helpers
	}

	{
		arena: mem.Arena
		mem.init_arena_from_context(^arena, mem.megabytes(16)) // Uses default allocator
		defer mem.free_arena(^arena)

		push_allocator mem.arena_allocator(^arena) {
			x := new(int)
			x^ = 1337

			fmt.println(x^)
		}

		/*
			push_allocator x {
				...
			}

			is equivalent to this:

			{
				prev_allocator := current_context().allocator
				current_context().allocator = x
				defer current_context().allocator = prev_allocator

				...
			}
		*/

		// You can also "push" a context

		c := current_context()
		c.allocator = mem.arena_allocator(^arena)

		push_context c {
			x := new(int)
			x^ = 365

			fmt.println(x^)
		}
	}
}
