package mem_virtual

import "core:mem"
import sync "core:sync/sync2"

Growing_Arena :: struct {
	curr_block:      ^Memory_Block,
	total_used:      int,
	total_allocated: int,
	
	minimum_block_size: int,

	ignore_mutex: bool,	
	mutex: sync.Mutex,
}

DEFAULT_MINIMUM_BLOCK_SIZE :: 8*1024*1024
DEFAULT_PAGE_SIZE := 4096

growing_arena_alloc :: proc(arena: ^Growing_Arena, min_size: int, alignment: int) -> (data: []byte, err: mem.Allocator_Error) {
	align_forward_offset :: proc(arena: ^Growing_Arena, alignment: int) -> int #no_bounds_check {
		alignment_offset := 0
		ptr := uintptr(arena.curr_block.base[arena.curr_block.used:])
		mask := uintptr(alignment-1)
		if ptr & mask != 0 {
			alignment_offset = alignment - int(ptr & mask)
		}
		return alignment_offset
	}
	
	assert(mem.is_power_of_two(uintptr(alignment)))
	
	mutex := &arena.mutex
	if !arena.ignore_mutex {
		sync.mutex_lock(mutex)
	}
	
	size := 0
	if arena.curr_block != nil {
		size = min_size + align_forward_offset(arena, alignment)
	}
	
	if arena.curr_block == nil || arena.curr_block.used + size > arena.curr_block.size {
		size = mem.align_forward_int(min_size, alignment)
		arena.minimum_block_size = max(DEFAULT_MINIMUM_BLOCK_SIZE, arena.minimum_block_size)
		
		block_size := max(size, arena.minimum_block_size)
		
		new_block := memory_alloc(block_size) or_return
		new_block.prev = arena.curr_block
		arena.curr_block = new_block
		arena.total_allocated += new_block.size
	}
	
	curr_block := arena.curr_block
	assert(curr_block.used + size <= curr_block.size)
	
	ptr := curr_block.base[curr_block.used:]
	ptr = ptr[uintptr(align_forward_offset(arena, alignment)):]
	
	curr_block.used += size
	assert(curr_block.used <= curr_block.size)
	arena.total_used += size
	
	if !arena.ignore_mutex {
		sync.mutex_unlock(mutex)
	}
	
	return ptr[:min_size], nil
}

growing_arena_free_all :: proc(arena: ^Growing_Arena) {
	mutex := &arena.mutex
	if !arena.ignore_mutex {
		sync.mutex_lock(mutex)
	}
	for arena.curr_block != nil {
		free_block := arena.curr_block
		arena.curr_block = free_block.prev
		memory_dealloc(free_block)
	}
	arena.total_used = 0
	if !arena.ignore_mutex {
		sync.mutex_unlock(mutex)
	}
}

growing_arena_allocator :: proc(arena: ^Growing_Arena) -> mem.Allocator {
	return mem.Allocator{growing_arena_allocator_proc, arena}
}

growing_arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: mem.Allocator_Error) {
	arena := (^Growing_Arena)(allocator_data)
	
	switch mode {
	case .Alloc:
		return growing_arena_alloc(arena, size, alignment)
	case .Free:
		err = .Mode_Not_Implemented
		return
	case .Free_All:
		growing_arena_free_all(arena)
		return
	case .Resize:
		return mem.default_resize_bytes_align(mem.byte_slice(old_memory, old_size), size, alignment, growing_arena_allocator(arena), location)
		
	case .Query_Features, .Query_Info:
		err = .Mode_Not_Implemented
		return	
	}	
	
	err = .Mode_Not_Implemented
	return 
}