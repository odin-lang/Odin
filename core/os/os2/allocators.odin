//+private
package os2

import "base:runtime"

@(require_results)
file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
}

temp_allocator_proc :: runtime.arena_allocator_proc

@(private="file", thread_local)
global_default_temp_allocator_arena: runtime.Arena

@(require_results)
temp_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = temp_allocator_proc,
		data      = &global_default_temp_allocator_arena,
	}
}

@(require_results)
temp_allocator_temp_begin :: proc(loc := #caller_location) -> (temp: runtime.Arena_Temp) {
	temp = runtime.arena_temp_begin(&global_default_temp_allocator_arena, loc)
	return
}

temp_allocator_temp_end :: proc(temp: runtime.Arena_Temp, loc := #caller_location) {
	runtime.arena_temp_end(temp, loc)
}

@(fini, private)
temp_allocator_fini :: proc() {
	runtime.arena_destroy(&global_default_temp_allocator_arena)
	global_default_temp_allocator_arena = {}
}

@(deferred_out=temp_allocator_temp_end)
TEMP_ALLOCATOR_GUARD :: #force_inline proc(ignore := false, loc := #caller_location) -> (runtime.Arena_Temp, runtime.Source_Code_Location) {
	if ignore {
		return {}, loc
	} else {
		return temp_allocator_temp_begin(loc), loc
	}
}

