//+private
package os2

import "core:mem"

heap_alloc :: proc(size: int) -> rawptr {
	// TODO
	return nil
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	// TODO
	return nil
}
heap_free :: proc(ptr: rawptr) {
	if ptr == nil {
		return
	}
	// TODO
}

_heap_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	// TODO
	return nil, nil
}
