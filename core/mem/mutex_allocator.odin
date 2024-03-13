//+build !freestanding
package mem

import "core:sync"

Mutex_Allocator :: struct {
	backing: Allocator,
	mutex:   sync.Mutex,
}

mutex_allocator_init :: proc(m: ^Mutex_Allocator, backing_allocator: Allocator) {
	m.backing = backing_allocator
	m.mutex = {}
}


@(require_results)
mutex_allocator :: proc(m: ^Mutex_Allocator) -> Allocator {
	return Allocator{
		procedure = mutex_allocator_proc,
		data = m,
	}
}

mutex_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, loc := #caller_location) -> (result: []byte, err: Allocator_Error) {
	m := (^Mutex_Allocator)(allocator_data)

	sync.mutex_guard(&m.mutex)
	return m.backing.procedure(m.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

