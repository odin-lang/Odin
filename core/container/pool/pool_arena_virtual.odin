#+build darwin, freebsd, openbsd, netbsd, linux, windows
package container_pool

import "base:runtime"

import "core:mem"
import "core:mem/virtual"

_Pool_Arena :: virtual.Arena

_DEFAULT_BLOCK_SIZE :: mem.Gigabyte

_pool_arena_init :: proc(arena: ^Pool_Arena, block_size: uint = DEFAULT_BLOCK_SIZE) -> (err: runtime.Allocator_Error) {
	virtual.arena_init_growing(arena, block_size) or_return
	return
}

_pool_arena_allocator :: proc(arena: ^Pool_Arena) -> runtime.Allocator {
	return virtual.arena_allocator(arena)
}

_pool_arena_destroy :: proc(arena: ^Pool_Arena) {
	virtual.arena_destroy(arena)
}
