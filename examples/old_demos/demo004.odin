import "core:fmt.odin";
import "core:utf8.odin";
import "core:hash.odin";
import "core:mem.odin";

main :: proc() {
	{ // New Standard Library stuff
		s := "Hello";
		fmt.println(s,
		            utf8.valid_string(s),
		            hash.murmur64(cast([]u8)s));

		// utf8.odin
		// hash.odin
		//     - crc, fnv, fnva, murmur
		// mem.odin
		//     - Custom allocators
		//     - Helpers
	}

	{
		arena: mem.Arena;
		mem.init_arena_from_context(&arena, mem.megabytes(16)); // Uses default allocator
		defer mem.destroy_arena(&arena);

		push_allocator mem.arena_allocator(&arena) {
			x := new(int);
			x^ = 1337;

			fmt.println(x^);
		}

		/*
			push_allocator x {
				..
			}

			is equivalent to:

			{
				prev_allocator := __context.allocator
				__context.allocator = x
				defer __context.allocator = prev_allocator

				..
			}
		*/

		// You can also "push" a context

		c := context; // Create copy of the allocator
		c.allocator = mem.arena_allocator(&arena);

		push_context c {
			x := new(int);
			x^ = 365;

			fmt.println(x^);
		}
	}

	// Backend improvements
	// - Minimal dependency building (only build what is needed)
	// - Numerous bugs fixed
	// - Mild parsing recovery after bad syntax error
}
