package mem_virtual

import "core:mem"

Static_Arena :: struct {
	block: ^Memory_Block,
	minimum_reserve_size: uint,
	
	temp_count: int,
}

STATIC_ARENA_DEFAULT_COMMIT_SIZE  :: 1<<20
STATIC_ARENA_DEFAULT_RESERVE_SIZE :: 1<<30 when size_of(uintptr) == 8 else 1<<26

static_arena_init :: proc(arena: ^Static_Arena, reserved: uint, commit_size: uint = STATIC_ARENA_DEFAULT_COMMIT_SIZE) -> (err: Allocator_Error) {
	reserved := reserved
	reserved = max(reserved, STATIC_ARENA_DEFAULT_COMMIT_SIZE)
	data := reserve(uint(reserved)) or_return
	committed := max(commit_size, STATIC_ARENA_DEFAULT_COMMIT_SIZE)
	committed = min(committed, reserved)
	
	ptr := raw_data(data)
	commit(ptr, uint(committed))
	
	arena.block = memory_block_alloc(commit_size, reserved, {}) or_return
	return
} 

static_arena_destroy :: proc(arena: ^Static_Arena) {
	memory_block_dealloc(arena.block)
	arena^ = {}
} 


static_arena_alloc :: proc(arena: ^Static_Arena, size: int, alignment: int) -> (data: []byte, err: Allocator_Error) {
	align_forward :: #force_inline proc "contextless" (ptr: uint, align: uint) -> uint {
		mask := align-1
		return (ptr + mask) &~ mask
	}
	
	if arena.block == nil {
		reserve_size := max(arena.minimum_reserve_size, STATIC_ARENA_DEFAULT_RESERVE_SIZE)
		static_arena_init(arena, reserve_size, STATIC_ARENA_DEFAULT_COMMIT_SIZE) or_return
	}
	
	MINIMUM_ALIGN :: 2*align_of(uintptr)
	
	align := max(MINIMUM_ALIGN, alignment)
	
	return alloc_from_memory_block(arena.block, size, align)
}

static_arena_reset_to :: proc(arena: ^Static_Arena, pos: uint) -> bool {
	if arena.block != nil {
		prev_pos := arena.block.used
		arena.block.used = clamp(pos, 0, arena.block.reserved)
		
		if prev_pos < pos {
			mem.zero_slice(arena.block.base[arena.block.used:][:pos-prev_pos])
		}
		return true
	} else if pos == 0 {
		return true
	}
	return false
}

static_arena_free_all :: proc(arena: ^Static_Arena) {
	static_arena_reset_to(arena, 0)
}

static_arena_allocator :: proc(arena: ^Static_Arena) -> mem.Allocator {
	return mem.Allocator{static_arena_allocator_proc, arena}
}

static_arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena := (^Static_Arena)(allocator_data)
	
	switch mode {
	case .Alloc:
		return static_arena_alloc(arena, size, alignment)
	case .Free:
		err = .Mode_Not_Implemented
		return
	case .Free_All:
		static_arena_free_all(arena)
		return
	case .Resize:
		return mem.default_resize_bytes_align(mem.byte_slice(old_memory, old_size), size, alignment, static_arena_allocator(arena), location)
		
	case .Query_Features, .Query_Info:
		err = .Mode_Not_Implemented
		return	
	}	
	
	err = .Mode_Not_Implemented
	return 
}


Static_Arena_Temp :: struct {
	arena: ^Static_Arena,
	used:  uint,
}


static_arena_temp_begin :: proc(arena: ^Static_Arena) -> (temp: Static_Arena_Temp) {
	temp.arena = arena
	temp.used = arena.block.used if arena.block != nil else 0
	arena.temp_count += 1
	return
}

static_arena_temp_end :: proc(temp: Static_Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena
	
	used := arena.block.used if arena.block != nil else 0
	
	assert(temp.used >= used, "invalid Static_Arena_Temp", loc)
	
	static_arena_reset_to(arena, temp.used)
	
	assert(arena.temp_count > 0, "double-use of growing_arena_temp_end", loc)
	arena.temp_count -= 1
}


static_arena_check_temp :: proc(arena: ^Static_Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Static_Arena_Temp not been ended", loc)
}