#+private
#+build !darwin
#+build !freebsd
#+build !linux
#+build !netbsd
#+build !openbsd
#+build !windows
package runtime

VIRTUAL_MEMORY_SUPPORTED :: false

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	unimplemented_contextless("Virtual memory is not supported on this platform.")
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	unimplemented_contextless("Virtual memory is not supported on this platform.")
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	unimplemented_contextless("Virtual memory is not supported on this platform.")
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	unimplemented_contextless("Virtual memory is not supported on this platform.")
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	unimplemented_contextless("Virtual memory is not supported on this platform.")
}
