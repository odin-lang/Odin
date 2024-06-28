//+build js, wasi, freestanding, essence
//+private
package runtime

_heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
	context = default_context()
	unimplemented("base:runtime 'heap_alloc' procedure is not supported on this platform")
}

_heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
	context = default_context()
	unimplemented("base:runtime 'heap_resize' procedure is not supported on this platform")
}

_heap_free :: proc "contextless" (ptr: rawptr) {
	context = default_context()
	unimplemented("base:runtime 'heap_free' procedure is not supported on this platform")
}
