//+build freestanding, js
package runtime

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
