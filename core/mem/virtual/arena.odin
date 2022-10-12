package mem_virtual

import "core:mem"

Arena_Kind :: enum u8 {
	Growing = 0, // chained memory block
	Static  = 1, // fixed reservation
}

Arena :: struct {
	curr_block: ^Memory_Block,
	total_used:     uint,
	total_reserved: uint,

	kind:               Arena_Kind,
	minimum_block_size: uint,
	temp_count:         int,
}


STATIC_ARENA_DEFAULT_COMMIT_SIZE  :: 1<<20 // 1 MiB should be enough to start with
GROWING_ARENA_DEFAULT_MINIMUM_BLOCK_SIZE :: STATIC_ARENA_DEFAULT_COMMIT_SIZE

// 1 GiB on 64-bit systems, 128 MiB on 32-bit systems by default
STATIC_ARENA_DEFAULT_RESERVE_SIZE :: 1<<30 when size_of(uintptr) == 8 else 1<<27



arena_init_growing :: proc(arena: ^Arena, reserved: uint = GROWING_ARENA_DEFAULT_MINIMUM_BLOCK_SIZE) -> (err: Allocator_Error) {
	arena.kind = .Growing
	arena.curr_block = memory_block_alloc(0, reserved, {}) or_return
	arena.total_used = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}


arena_init_static :: proc(arena: ^Arena, reserved: uint, commit_size: uint = STATIC_ARENA_DEFAULT_COMMIT_SIZE) -> (err: Allocator_Error) {
	arena.kind = .Static
	arena.curr_block = memory_block_alloc(commit_size, reserved, {}) or_return
	arena.total_used = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}

arena_alloc :: proc(arena: ^Arena, min_size: int, alignment: int, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	assert(mem.is_power_of_two(uintptr(alignment)), "non-power of two alignment", loc)

	switch arena.kind {
	case .Growing:
		size := uint(min_size)
		if arena.curr_block != nil {
			// align forward offset
			ptr := uintptr(arena.curr_block.base[arena.curr_block.used:])
			mask := uintptr(alignment-1)
			if ptr & mask != 0 {
				size += uint(alignment) - uint(ptr & mask)
			}
		}

		if arena.curr_block == nil || arena.curr_block.used + size > arena.curr_block.reserved {
			size = uint(mem.align_forward_int(min_size, alignment))
			arena.minimum_block_size = max(GROWING_ARENA_DEFAULT_MINIMUM_BLOCK_SIZE, arena.minimum_block_size)

			block_size := max(size, arena.minimum_block_size)

			new_block := memory_block_alloc(size, block_size, {}) or_return
			new_block.prev = arena.curr_block
			arena.curr_block = new_block
			arena.total_reserved += new_block.reserved
		}


		data, err = alloc_from_memory_block(arena.curr_block, int(size), alignment)
		if err == nil {
			arena.total_used += size
		}
	case .Static:
		if arena.curr_block == nil {
			reserve_size := max(arena.minimum_block_size, STATIC_ARENA_DEFAULT_RESERVE_SIZE)
			arena_init_static(arena, reserve_size, STATIC_ARENA_DEFAULT_COMMIT_SIZE) or_return
		}
		data, err = alloc_from_memory_block(arena.curr_block, min_size, alignment)
		arena.total_used = arena.curr_block.used
	}
	return
}

arena_static_reset_to :: proc(arena: ^Arena, pos: uint, loc := #caller_location) -> bool {
	if arena.curr_block != nil {
		assert(arena.kind == .Static, "expected a .Static arena", loc)

		prev_pos := arena.curr_block.used
		arena.curr_block.used = clamp(pos, 0, arena.curr_block.reserved)

		if prev_pos < pos {
			mem.zero_slice(arena.curr_block.base[arena.curr_block.used:][:pos-prev_pos])
		}
		arena.total_used = arena.curr_block.used
		return true
	} else if pos == 0 {
		arena.total_used = 0
		return true
	}
	return false
}

arena_growing_free_last_memory_block :: proc(arena: ^Arena, loc := #caller_location) {
	if free_block := arena.curr_block; free_block != nil {
		assert(arena.kind == .Growing, "expected a .Growing arena", loc)
		arena.curr_block = free_block.prev
		memory_block_dealloc(free_block)
	}
}

arena_free_all :: proc(arena: ^Arena) {
	switch arena.kind {
	case .Growing:
		for arena.curr_block != nil {
			arena_growing_free_last_memory_block(arena)
		}
	case .Static:
		arena_static_reset_to(arena, 0)
	}
	arena.total_used = 0
	arena.total_reserved = 0
}

arena_destroy :: proc(arena: ^Arena) {
	arena_free_all(arena)
	memory_block_dealloc(arena.curr_block)
	arena.curr_block = nil
	arena.total_used     = 0
	arena.total_reserved = 0
	arena.temp_count     = 0
}

arena_growing_bootstrap_new_by_offset :: proc($T: typeid, offset_to_arena: uintptr, minimum_block_size: uint = GROWING_ARENA_DEFAULT_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	bootstrap: Arena
	bootstrap.kind = .Growing
	bootstrap.minimum_block_size = minimum_block_size

	data := arena_alloc(&bootstrap, size_of(T), align_of(T)) or_return

	ptr = (^T)(raw_data(data))

	(^Arena)(uintptr(ptr) + offset_to_arena)^ = bootstrap

	return
}

arena_growing_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, minimum_block_size: uint = GROWING_ARENA_DEFAULT_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	return arena_growing_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), minimum_block_size)
}

arena_growing_bootstrap_new :: proc{
	arena_growing_bootstrap_new_by_offset,
	arena_growing_bootstrap_new_by_name,
}

arena_static_bootstrap_new_by_offset :: proc($T: typeid, offset_to_arena: uintptr, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	bootstrap: Arena
	bootstrap.kind = .Static
	bootstrap.minimum_block_size = reserved

	data := arena_alloc(&bootstrap, size_of(T), align_of(T)) or_return

	ptr = (^T)(raw_data(data))

	(^Arena)(uintptr(ptr) + offset_to_arena)^ = bootstrap

	return
}

arena_static_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	return arena_static_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), reserved)
}
arena_static_bootstrap_new :: proc{
	arena_static_bootstrap_new_by_offset,
	arena_static_bootstrap_new_by_name,
}


arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return mem.Allocator{arena_allocator_proc, arena}
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                                     size, alignment: int,
                                     old_memory: rawptr, old_size: int,
                                     location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena := (^Arena)(allocator_data)

	switch mode {
	case .Alloc:
		return arena_alloc(arena, size, alignment)
	case .Free:
		err = .Mode_Not_Implemented
		return
	case .Free_All:
		arena_free_all(arena)
		return
	case .Resize:
		return mem.default_resize_bytes_align(mem.byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena), location)

	case .Query_Features, .Query_Info:
		err = .Mode_Not_Implemented
		return
	}

	err = .Mode_Not_Implemented
	return
}

Arena_Temp :: struct {
	arena: ^Arena,
	block: ^Memory_Block,
	used:  uint,
}

arena_temp_begin :: proc(arena: ^Arena, loc := #caller_location) -> (temp: Arena_Temp) {
	assert(arena != nil, "nil arena", loc)
	temp.arena = arena
	temp.block = arena.curr_block
	if arena.curr_block != nil {
		temp.used = arena.curr_block.used
	}
	arena.temp_count += 1
	return
}

arena_temp_end :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena

	memory_block_found := false
	for block := arena.curr_block; block != nil; block = block.prev {
		if block == temp.block {
			memory_block_found = true
			break
		}
	}
	if !memory_block_found {
		assert(arena.curr_block == temp.block, "memory block stored within Arena_Temp not owned by Arena", loc)
	}

	for arena.curr_block != temp.block {
		arena_growing_free_last_memory_block(arena)
	}

	if block := arena.curr_block; block != nil {
		assert(block.used >= temp.used, "out of order use of arena_temp_end", loc)
		amount_to_zero := min(block.used-temp.used, block.reserved-block.used)
		mem.zero_slice(block.base[temp.used:][:amount_to_zero])
		block.used = temp.used
	}

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

arena_check_temp :: proc(arena: ^Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Arena_Temp not been ended", loc)
}



