package mem_virtual

import "core:mem"
import "core:sync"

Arena_Kind :: enum uint {
	Growing = 0, // Chained memory blocks (singly linked list).
	Static  = 1, // Fixed reservation sized.
	Buffer  = 2, // Uses a fixed sized buffer.
}

Arena :: struct {
	kind:               Arena_Kind,
	curr_block:         ^Memory_Block,
	total_used:         uint,
	total_reserved:     uint,
	minimum_block_size: uint,
	temp_count:         uint,
	mutex:              sync.Mutex,
}


// 1 MiB should be enough to start with
DEFAULT_ARENA_STATIC_COMMIT_SIZE         :: mem.Megabyte
DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE :: DEFAULT_ARENA_STATIC_COMMIT_SIZE

// 1 GiB on 64-bit systems, 128 MiB on 32-bit systems by default
DEFAULT_ARENA_STATIC_RESERVE_SIZE :: mem.Gigabyte when size_of(uintptr) == 8 else 128 * mem.Megabyte



@(require_results)
arena_init_growing :: proc(arena: ^Arena, reserved: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Growing
	arena.curr_block     = memory_block_alloc(0, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}


@(require_results)
arena_init_static :: proc(arena: ^Arena, reserved: uint, commit_size: uint = DEFAULT_ARENA_STATIC_COMMIT_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Static
	arena.curr_block     = memory_block_alloc(commit_size, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}

@(require_results)
arena_init_buffer :: proc(arena: ^Arena, buffer: []byte) -> (err: Allocator_Error) {
	if len(buffer) < size_of(Memory_Block) {
		return .Out_Of_Memory
	}

	arena.kind = .Buffer

	mem.zero_slice(buffer)

	block_base := raw_data(buffer)
	block := (^Memory_Block)(block_base)
	block.base      = block_base[size_of(Memory_Block):]
	block.reserved  = len(buffer) - size_of(Memory_Block)
	block.committed = block.reserved
	block.used      = 0

	arena.curr_block = block
	arena.total_used = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}

@(require_results)
arena_alloc :: proc(arena: ^Arena, size: uint, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	assert(alignment & (alignment-1) == 0, "non-power of two alignment", loc)

	size := size
	if size == 0 {
		return nil, nil
	}

	sync.mutex_guard(&arena.mutex)

	switch arena.kind {
	case .Growing:
		if arena.curr_block == nil || (safe_add(arena.curr_block.used, size) or_else 0) > arena.curr_block.reserved {
			size = mem.align_forward_uint(size, alignment)
			if arena.minimum_block_size == 0 {
				arena.minimum_block_size = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE
			}

			block_size := max(size, arena.minimum_block_size)

			new_block := memory_block_alloc(size, block_size, {}) or_return
			new_block.prev = arena.curr_block
			arena.curr_block = new_block
			arena.total_reserved += new_block.reserved
		}

		prev_used := arena.curr_block.used
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment)
		arena.total_used += arena.curr_block.used - prev_used
	case .Static:
		if arena.curr_block == nil {
			if arena.minimum_block_size == 0 {
				arena.minimum_block_size = DEFAULT_ARENA_STATIC_RESERVE_SIZE
			}
			arena_init_static(arena=arena, reserved=arena.minimum_block_size, commit_size=DEFAULT_ARENA_STATIC_COMMIT_SIZE) or_return
		}
		fallthrough
	case .Buffer:
		if arena.curr_block == nil {
			return nil, .Out_Of_Memory
		}
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment)
		arena.total_used = arena.curr_block.used
	}
	return
}

arena_static_reset_to :: proc(arena: ^Arena, pos: uint, loc := #caller_location) -> bool {
	sync.mutex_guard(&arena.mutex)

	if arena.curr_block != nil {
		assert(arena.kind != .Growing, "expected a non .Growing arena", loc)

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
		sync.mutex_guard(&arena.mutex)
		for arena.curr_block != nil {
			arena_growing_free_last_memory_block(arena)
		}
		arena.total_reserved = 0
	case .Static, .Buffer:
		arena_static_reset_to(arena, 0)
	}
	arena.total_used = 0
}

arena_destroy :: proc(arena: ^Arena) {
	arena_free_all(arena)
	if arena.kind != .Buffer {
		memory_block_dealloc(arena.curr_block)
	}
	arena.curr_block = nil
	arena.total_used     = 0
	arena.total_reserved = 0
	arena.temp_count     = 0
}

arena_growing_bootstrap_new :: proc{
	arena_growing_bootstrap_new_by_offset,
	arena_growing_bootstrap_new_by_name,
}

arena_static_bootstrap_new :: proc{
	arena_static_bootstrap_new_by_offset,
	arena_static_bootstrap_new_by_name,
}

@(require_results)
arena_growing_bootstrap_new_by_offset :: proc($T: typeid, offset_to_arena: uintptr, minimum_block_size: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	bootstrap: Arena
	bootstrap.kind = .Growing
	bootstrap.minimum_block_size = minimum_block_size

	data := arena_alloc(&bootstrap, size_of(T), align_of(T)) or_return

	ptr = (^T)(raw_data(data))

	(^Arena)(uintptr(ptr) + offset_to_arena)^ = bootstrap

	return
}

@(require_results)
arena_growing_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, minimum_block_size: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	return arena_growing_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), minimum_block_size)
}

@(require_results)
arena_static_bootstrap_new_by_offset :: proc($T: typeid, offset_to_arena: uintptr, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	bootstrap: Arena
	bootstrap.kind = .Static
	bootstrap.minimum_block_size = reserved

	data := arena_alloc(&bootstrap, size_of(T), align_of(T)) or_return

	ptr = (^T)(raw_data(data))

	(^Arena)(uintptr(ptr) + offset_to_arena)^ = bootstrap

	return
}

@(require_results)
arena_static_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	return arena_static_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), reserved)
}


@(require_results)
arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return mem.Allocator{arena_allocator_proc, arena}
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena := (^Arena)(allocator_data)

	size, alignment := uint(size), uint(alignment)
	old_size := uint(old_size)

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return arena_alloc(arena, size, alignment)
	case .Free:
		err = .Mode_Not_Implemented
	case .Free_All:
		arena_free_all(arena)
	case .Resize:
		old_data := ([^]byte)(old_memory)

		switch {
		case old_data == nil:
			return arena_alloc(arena, size, alignment)
		case size == old_size:
			// return old memory
			data = old_data[:size]
			return
		case size == 0:
			err = .Mode_Not_Implemented
			return
		case (uintptr(old_data) & uintptr(alignment-1) == 0) && size < old_size:
			// shrink data in-place
			data = old_data[:size]
			return
		}

		new_memory := arena_alloc(arena, size, alignment) or_return
		if new_memory == nil {
			return
		}
		copy(new_memory, old_data[:old_size])
		return new_memory, nil
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
		}
	case .Query_Info:
		err = .Mode_Not_Implemented
	}

	return
}




Arena_Temp :: struct {
	arena: ^Arena,
	block: ^Memory_Block,
	used:  uint,
}

@(require_results)
arena_temp_begin :: proc(arena: ^Arena, loc := #caller_location) -> (temp: Arena_Temp) {
	assert(arena != nil, "nil arena", loc)
	sync.mutex_guard(&arena.mutex)

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
	sync.mutex_guard(&arena.mutex)

	if temp.block != nil {
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
	}

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Ignore the use of a `arena_temp_begin` entirely
arena_temp_ignore :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena
	sync.mutex_guard(&arena.mutex)

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

arena_check_temp :: proc(arena: ^Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Arena_Temp not been ended", loc)
}
