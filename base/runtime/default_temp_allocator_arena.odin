package runtime

import "base:intrinsics"

DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE :: uint(DEFAULT_TEMP_ALLOCATOR_BACKING_SIZE)

Memory_Block :: struct {
	prev:      ^Memory_Block,
	allocator: Allocator,
	base:      [^]byte,
	used:      uint,
	capacity:  uint,
}

// NOTE: This is a growing arena that is only used for the default temp allocator.
// For your own growing arena needs, prefer `Arena` from `core:mem/virtual`.
Arena :: struct {
	backing_allocator:  Allocator,
	curr_block:         ^Memory_Block,
	total_used:         uint,
	total_capacity:     uint,
	minimum_block_size: uint,
	temp_count:         uint,
}

@(private, require_results)
safe_add :: #force_inline proc "contextless" (x, y: uint) -> (uint, bool) {
	z, did_overflow := intrinsics.overflow_add(x, y)
	return z, !did_overflow
}

@(require_results)
memory_block_alloc :: proc(allocator: Allocator, capacity: uint, alignment: uint, loc := #caller_location) -> (block: ^Memory_Block, err: Allocator_Error) {
	total_size  := uint(capacity + max(alignment, size_of(Memory_Block)))
	base_offset := uintptr(max(alignment, size_of(Memory_Block)))

	min_alignment: int = max(16, align_of(Memory_Block), int(alignment))
	data := mem_alloc(int(total_size), min_alignment, allocator, loc) or_return
	block = (^Memory_Block)(raw_data(data))
	end := uintptr(raw_data(data)[len(data):])

	block.allocator = allocator
	block.base = ([^]byte)(uintptr(block) + base_offset)
	block.capacity = uint(end - uintptr(block.base))

	// Should be zeroed
	assert(block.used == 0)
	assert(block.prev == nil)
	return
}

memory_block_dealloc :: proc(block_to_free: ^Memory_Block, loc := #caller_location) {
	if block_to_free != nil {
		allocator := block_to_free.allocator
		mem_free(block_to_free, allocator, loc)
	}
}

@(require_results)
alloc_from_memory_block :: proc(block: ^Memory_Block, min_size, alignment: uint) -> (data: []byte, err: Allocator_Error) {
	calc_alignment_offset :: proc "contextless" (block: ^Memory_Block, alignment: uintptr) -> uint {
		alignment_offset := uint(0)
		ptr := uintptr(block.base[block.used:])
		mask := alignment-1
		if ptr & mask != 0 {
			alignment_offset = uint(alignment - (ptr & mask))
		}
		return alignment_offset

	}
	if block == nil {
		return nil, .Out_Of_Memory
	}
	alignment_offset := calc_alignment_offset(block, uintptr(alignment))
	size, size_ok := safe_add(min_size, alignment_offset)
	if !size_ok {
		err = .Out_Of_Memory
		return
	}

	if to_be_used, ok := safe_add(block.used, size); !ok || to_be_used > block.capacity {
		err = .Out_Of_Memory
		return
	}
	data = block.base[block.used+alignment_offset:][:min_size]
	block.used += size
	return
}

@(require_results)
arena_alloc :: proc(arena: ^Arena, size, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	align_forward_uint :: proc "contextless" (ptr, align: uint) -> uint {
		p := ptr
		modulo := p & (align-1)
		if modulo != 0 {
			p += align - modulo
		}
		return p
	}

	assert(alignment & (alignment-1) == 0, "non-power of two alignment", loc)

	size := size
	if size == 0 {
		return
	}
	
	needed := align_forward_uint(size, alignment)
	if arena.curr_block == nil || (safe_add(arena.curr_block.used, needed) or_else 0) > arena.curr_block.capacity {
		if arena.minimum_block_size == 0 {
			arena.minimum_block_size = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE
		}

		block_size := max(needed, arena.minimum_block_size)

		if arena.backing_allocator.procedure == nil {
			arena.backing_allocator = default_allocator()
		}

		new_block := memory_block_alloc(arena.backing_allocator, block_size, alignment, loc) or_return
		new_block.prev = arena.curr_block
		arena.curr_block = new_block
		arena.total_capacity += new_block.capacity
	}

	prev_used := arena.curr_block.used
	data, err = alloc_from_memory_block(arena.curr_block, size, alignment)
	arena.total_used += arena.curr_block.used - prev_used
	return
}

// `arena_init` will initialize the arena with a usable block.
// This procedure is not necessary to use the Arena as the default zero as `arena_alloc` will set things up if necessary
@(require_results)
arena_init :: proc(arena: ^Arena, size: uint, backing_allocator: Allocator, loc := #caller_location) -> Allocator_Error {
	arena^ = {}
	arena.backing_allocator = backing_allocator
	arena.minimum_block_size = max(size, 1<<12) // minimum block size of 4 KiB
	new_block := memory_block_alloc(arena.backing_allocator, arena.minimum_block_size, 0, loc) or_return
	arena.curr_block = new_block
	arena.total_capacity += new_block.capacity
	return nil
}


arena_free_last_memory_block :: proc(arena: ^Arena, loc := #caller_location) {
	if free_block := arena.curr_block; free_block != nil {
		arena.curr_block = free_block.prev

		arena.total_capacity -= free_block.capacity
		memory_block_dealloc(free_block, loc)
	}
}

// `arena_free_all` will free all but the first memory block, and then reset the memory block
arena_free_all :: proc(arena: ^Arena, loc := #caller_location) {
	for arena.curr_block != nil && arena.curr_block.prev != nil {
		arena_free_last_memory_block(arena, loc)
	}

	if arena.curr_block != nil {
		intrinsics.mem_zero(arena.curr_block.base, arena.curr_block.used)
		arena.curr_block.used = 0
	}
	arena.total_used = 0
}

arena_destroy :: proc(arena: ^Arena, loc := #caller_location) {
	for arena.curr_block != nil {
		free_block := arena.curr_block
		arena.curr_block = free_block.prev

		arena.total_capacity -= free_block.capacity
		memory_block_dealloc(free_block, loc)
	}
	arena.total_used = 0
	arena.total_capacity = 0
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{arena_allocator_proc, arena}
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena := (^Arena)(allocator_data)

	size, alignment := uint(size), uint(alignment)
	old_size := uint(old_size)

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return arena_alloc(arena, size, alignment, location)
	case .Free:
		err = .Mode_Not_Implemented
	case .Free_All:
		arena_free_all(arena, location)
	case .Resize, .Resize_Non_Zeroed:
		old_data := ([^]byte)(old_memory)

		switch {
		case old_data == nil:
			return arena_alloc(arena, size, alignment, location)
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

		new_memory := arena_alloc(arena, size, alignment, location) or_return
		if new_memory == nil {
			return
		}
		copy(new_memory, old_data[:old_size])
		return new_memory, nil
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
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

	temp.arena = arena
	temp.block = arena.curr_block
	if arena.curr_block != nil {
		temp.used = arena.curr_block.used
	}
	arena.temp_count += 1
	return
}

arena_temp_end :: proc(temp: Arena_Temp, loc := #caller_location) {
	if temp.arena == nil {
		assert(temp.block == nil)
		assert(temp.used == 0)
		return
	}
	arena := temp.arena

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
			arena_free_last_memory_block(arena)
		}

		if block := arena.curr_block; block != nil {
			assert(block.used >= temp.used, "out of order use of arena_temp_end", loc)
			amount_to_zero := block.used-temp.used
			intrinsics.mem_zero(block.base[temp.used:], amount_to_zero)
			block.used = temp.used
			arena.total_used -= amount_to_zero
		}
	}

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Ignore the use of a `arena_temp_begin` entirely
arena_temp_ignore :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

arena_check_temp :: proc(arena: ^Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Arena_Temp not been ended", loc)
}
