/*
package mem implements various types of allocators.


An example of how to use the `Tracking_Allocator` to track subsequent allocations
in your program and report leaks and bad frees:

```odin
package foo

import "core:mem"
import "core:fmt"

_main :: proc() {
	do stuff
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}
```
*/
package mem