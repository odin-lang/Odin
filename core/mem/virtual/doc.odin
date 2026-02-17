/*
A platform agnostic way to reserve/commit/decommit virtual memory.

virtual.Arena usage

Example:
	// Source: https://github.com/odin-lang/examples/blob/master/arena_allocator/arena_allocator.odin
	import "core:fmt"
	import "core:os"

	// virtual package implements a multi-purpose arena allocator. If you are on a
	// platform that does not support virtual memory, then there is also a similar
	// arena in `core:mem`.
	import vmem "core:mem/virtual"

	load_files :: proc() -> ([]string, vmem.Arena) {
		// This creates a growing virtual memory arena. It uses virtual memory and
		// can grow as things are added to it.
		arena: vmem.Arena
		arena_err := vmem.arena_init_growing(&arena)
		ensure(arena_err == nil)
		arena_alloc := vmem.arena_allocator(&arena)

		// See arena_init_static for an arena that uses virtual memory, but cannot grow.

		// See arena_init_buffer for an arena that does not use virtual memory,
		// instead it relies on you feeding it a buffer.

		f1, f1_err := os.read_entire_file("file1.txt", arena_alloc)
		ensure(f1_err == nil)

		f2, f2_err := os.read_entire_file("file2.txt", arena_alloc)
		ensure(f2_err == nil)

		f3, f3_err := os.read_entire_file("file3.txt", arena_alloc)
		ensure(f3_err == nil)

		res := make([]string, 3, arena_alloc)
		res[0] = string(f1)
		res[1] = string(f2)
		res[2] = string(f3)

		return res, arena
	}

	main :: proc() {
		files, arena := load_files()

		for f in files {
			fmt.println(f)
		}

		// This deallocates everything that was allocated on the arena:
		// The loaded content of the files as well as the `files` slice.
		vmem.arena_destroy(&arena)
	}

virtual.map_file usage

Example:
	// Source: https://github.com/odin-lang/examples/blob/master/arena_allocator/arena_allocator.odin
	import "core:fmt"

	// virtual package implements cross-platform file memory mapping
	import vmem "core:mem/virtual"

	main :: proc() {
		data, err := virtual.map_file_from_path(#file, {.Read})
		defer virtual.unmap_file(data)
		fmt.printfln("Error: %v", err)
		fmt.printfln("Data:  %s", data)
	}
*/
package mem_virtual

