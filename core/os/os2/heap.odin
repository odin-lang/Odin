package os2

import "core:runtime"

heap_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	};
}


heap_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	return _heap_allocator_proc(allocator_data, mode, size, alignment, old_memory, old_size, flags, loc);
}


@(private)
error_allocator := heap_allocator;
