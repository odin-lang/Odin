#+build !freestanding, wasm32, wasm64p32
package mem

import "core:sync"

/*
The data for mutex allocator.
*/
Mutex_Allocator :: struct {
	backing: Allocator,
	mutex:   sync.Mutex,
}

/*
Initialize the mutex allocator.

This procedure initializes the mutex allocator using `backin_allocator` as the
allocator that will be used to pass all allocation requests through.
*/
mutex_allocator_init :: proc(m: ^Mutex_Allocator, backing_allocator: Allocator) {
	m.backing = backing_allocator
	m.mutex = {}
}

/*
Mutex allocator.

The mutex allocator is a wrapper for allocators that is used to serialize all
allocator requests across multiple threads.
*/
@(require_results)
mutex_allocator :: proc(m: ^Mutex_Allocator) -> Allocator {
	return Allocator{
		procedure = mutex_allocator_proc,
		data = m,
	}
}

mutex_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size: int,
	alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (result: []byte, err: Allocator_Error) {
	m := (^Mutex_Allocator)(allocator_data)
	sync.mutex_guard(&m.mutex)
	return m.backing.procedure(m.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

