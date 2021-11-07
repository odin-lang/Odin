//+build !windows
//+build !freestanding
//+build !wasi
//+build !js
package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	// mem.nil_allocator reimplementation
	default_allocator_proc :: nil_allocator_proc
	default_allocator :: nil_allocator
} else {
	// TODO(bill): reimplement these procedures in the os_specific stuff
	import "core:os"

	default_allocator_proc :: os.heap_allocator_proc

	default_allocator :: proc() -> Allocator {
		return os.heap_allocator()
	}
}
