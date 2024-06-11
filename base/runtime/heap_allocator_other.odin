//+build js, wasi, freestanding, essence
//+private
package runtime

_heap_alloc :: proc(size: int, zero_memory := true) -> rawptr {
	unimplemented("base:runtime 'heap_alloc' procedure is not supported on this platform")
}

_heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	unimplemented("base:runtime 'heap_resize' procedure is not supported on this platform")
}

_heap_free :: proc(ptr: rawptr) {
	unimplemented("base:runtime 'heap_free' procedure is not supported on this platform")
}
