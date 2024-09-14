#+build linux, darwin, freebsd, openbsd, netbsd, haiku
#+private
package runtime

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
	@(link_name="malloc")   _unix_malloc   :: proc(size: int) -> rawptr ---
	@(link_name="calloc")   _unix_calloc   :: proc(num, size: int) -> rawptr ---
	@(link_name="free")     _unix_free     :: proc(ptr: rawptr) ---
	@(link_name="realloc")  _unix_realloc  :: proc(ptr: rawptr, size: int) -> rawptr ---
}

_heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
	if size <= 0 {
		return nil
	}
	if zero_memory {
		return _unix_calloc(1, size)
	} else {
		return _unix_malloc(size)
	}
}

_heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
	// NOTE: _unix_realloc doesn't guarantee new memory will be zeroed on
	// POSIX platforms. Ensure your caller takes this into account.
	return _unix_realloc(ptr, new_size)
}

_heap_free :: proc "contextless" (ptr: rawptr) {
	_unix_free(ptr)
}
