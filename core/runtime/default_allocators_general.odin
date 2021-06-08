//+build !windows
//+build !freestanding
package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	// mem.nil_allocator reimplementation

	default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
	                               size, alignment: int,
	                               old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
		return nil, .None;
	}

	default_allocator :: proc() -> Allocator {
		return Allocator{
			procedure = default_allocator_proc,
			data = nil,
		};
	}
} else {
	// TODO(bill): reimplement these procedures in the os_specific stuff
	import "core:os"

	default_allocator_proc :: os.heap_allocator_proc;

	default_allocator :: proc() -> Allocator {
		return os.heap_allocator();
	}
}
