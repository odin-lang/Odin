#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+private
package container_pool

import "base:runtime"

import "core:mem"

_Pool_Arena :: runtime.Arena

_DEFAULT_BLOCK_SIZE :: mem.Megabyte

_pool_arena_init :: proc(arena: ^Pool_Arena, block_size: uint = DEFAULT_BLOCK_SIZE) -> (err: runtime.Allocator_Error) {
	runtime.arena_init(arena, block_size, runtime.default_allocator()) or_return
	return
}

_pool_arena_allocator :: proc(arena: ^Pool_Arena) -> runtime.Allocator {
	return runtime.arena_allocator(arena)
}

_pool_arena_destroy :: proc(arena: ^Pool_Arena) {
	runtime.arena_destroy(arena)
}
