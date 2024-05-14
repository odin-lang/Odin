package os2

import "base:runtime"

@(require_results)
heap_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	}
}


@(require_results)
heap_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	return _heap_allocator_proc(allocator_data, mode, size, alignment, old_memory, old_size, loc)
}


@(private)
error_allocator := heap_allocator
