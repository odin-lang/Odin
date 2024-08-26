//+private
package os2

import "base:runtime"

@(require_results)
file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
}

temp_allocator_proc :: runtime.arena_allocator_proc

@(private="file")
MAX_TEMP_ARENA_COUNT :: 2

@(private="file", thread_local)
global_default_temp_allocator_arenas: [MAX_TEMP_ARENA_COUNT]runtime.Arena

@(private="file", thread_local)
global_default_temp_allocator_index: uint


@(require_results)
temp_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{
		procedure = temp_allocator_proc,
		data      = &global_default_temp_allocator_arenas[global_default_temp_allocator_index],
	}
}



@(require_results)
temp_allocator_temp_begin :: proc(loc := #caller_location) -> (temp: runtime.Arena_Temp) {
	temp = runtime.arena_temp_begin(&global_default_temp_allocator_arenas[global_default_temp_allocator_index], loc)
	return
}

temp_allocator_temp_end :: proc(temp: runtime.Arena_Temp, loc := #caller_location) {
	runtime.arena_temp_end(temp, loc)
}

@(fini, private)
temp_allocator_fini :: proc() {
	for &arena in global_default_temp_allocator_arenas {
		runtime.arena_destroy(&arena)
	}
	global_default_temp_allocator_arenas = {}
}

TEMP_ALLOCATOR_GUARD_END :: proc(temp: runtime.Arena_Temp, loc := #caller_location) {
	runtime.arena_temp_end(temp, loc)
	if temp.arena != nil {
		global_default_temp_allocator_index = (global_default_temp_allocator_index-1)%MAX_TEMP_ARENA_COUNT
	}
}

@(deferred_out=TEMP_ALLOCATOR_GUARD_END)
TEMP_ALLOCATOR_GUARD :: #force_inline proc(loc := #caller_location) -> (runtime.Arena_Temp, runtime.Source_Code_Location) {
	tmp := temp_allocator_temp_begin(loc)
	global_default_temp_allocator_index = (global_default_temp_allocator_index+1)%MAX_TEMP_ARENA_COUNT
	return tmp, loc
}

@(init, private)
init_thread_local_cleaner :: proc() {
	runtime.add_thread_local_cleaner(temp_allocator_fini)
}
