#+build orca
#+private
package tests_heap_allocator_libc

foreign {
	@(link_name="malloc")   _orca_malloc   :: proc "c" (size: int) -> rawptr ---
	@(link_name="calloc")   _orca_calloc   :: proc "c" (num, size: int) -> rawptr ---
	@(link_name="free")     _orca_free     :: proc "c" (ptr: rawptr) ---
	@(link_name="realloc")  _orca_realloc  :: proc "c" (ptr: rawptr, size: int) -> rawptr ---
}

_heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
	if size <= 0 {
		return nil
	}
	if zero_memory {
		return _orca_calloc(1, size)
	} else {
		return _orca_malloc(size)
	}
}

_heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
	return _orca_realloc(ptr, new_size)
}

_heap_free :: proc "contextless" (ptr: rawptr) {
	_orca_free(ptr)
}
