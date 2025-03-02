package mem_virtual

import "core:mem"
import "core:sync"

Arena_Kind :: enum uint {
	Growing = 0, // Chained memory blocks (singly linked list).
	Static  = 1, // Fixed reservation sized.
	Buffer  = 2, // Uses a fixed sized buffer.
}

/*
	Arena is a generalized arena allocator that supports 3 different variants.

	Growing: A linked list of `Memory_Block`s allocated with virtual memory.
	Static: A single `Memory_Block` allocated with virtual memory.
	Buffer: A single `Memory_Block` created from a user provided []byte.
*/
Arena :: struct {
	kind:                Arena_Kind,
	curr_block:          ^Memory_Block,

	total_used:          uint,
	total_reserved:      uint,

	default_commit_size: uint, // commit size <= reservation size
	minimum_block_size:  uint, // block size == total reservation

	temp_count:          uint,
	mutex:               sync.Mutex,
}


// 1 MiB should be enough to start with
DEFAULT_ARENA_STATIC_COMMIT_SIZE         :: mem.Megabyte
DEFAULT_ARENA_GROWING_COMMIT_SIZE        :: 8*mem.Megabyte
DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE :: DEFAULT_ARENA_STATIC_COMMIT_SIZE

// 1 GiB on 64-bit systems, 128 MiB on 32-bit systems by default
DEFAULT_ARENA_STATIC_RESERVE_SIZE :: mem.Gigabyte when size_of(uintptr) == 8 else 128 * mem.Megabyte



// Initialization of an `Arena` to be a `.Growing` variant.
// A growing arena is a linked list of `Memory_Block`s allocated with virtual memory.
@(require_results)
arena_init_growing :: proc(arena: ^Arena, reserved: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Growing
	arena.curr_block     = memory_block_alloc(0, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved

	if arena.minimum_block_size == 0 {
		arena.minimum_block_size = reserved
	}
	return
}


// Initialization of an `Arena` to be a `.Static` variant.
// A static arena contains a single `Memory_Block` allocated with virtual memory.
@(require_results)
arena_init_static :: proc(arena: ^Arena, reserved: uint = DEFAULT_ARENA_STATIC_RESERVE_SIZE, commit_size: uint = DEFAULT_ARENA_STATIC_COMMIT_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Static
	arena.curr_block     = memory_block_alloc(commit_size, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}

// Initialization of an `Arena` to be a `.Buffer` variant.
// A buffer arena contains single `Memory_Block` created from a user provided []byte.
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

// Allocates memory from the provided arena.
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
		needed := mem.align_forward_uint(size, alignment)
		if arena.curr_block == nil || (safe_add(arena.curr_block.used, needed) or_else 0) > arena.curr_block.reserved {
			if arena.minimum_block_size == 0 {
				arena.minimum_block_size = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE
				arena.minimum_block_size = mem.align_forward_uint(arena.minimum_block_size, DEFAULT_PAGE_SIZE)
			}
			if arena.default_commit_size == 0 {
				arena.default_commit_size = min(DEFAULT_ARENA_GROWING_COMMIT_SIZE, arena.minimum_block_size)
				arena.default_commit_size = mem.align_forward_uint(arena.default_commit_size, DEFAULT_PAGE_SIZE)
			}

			if arena.default_commit_size != 0 {
				arena.default_commit_size, arena.minimum_block_size =
					min(arena.default_commit_size, arena.minimum_block_size),
					max(arena.default_commit_size, arena.minimum_block_size)
			}

			needed = max(needed, arena.default_commit_size)
			block_size := max(needed, arena.minimum_block_size)

			new_block := memory_block_alloc(needed, block_size, alignment, {}) or_return
			new_block.prev = arena.curr_block
			arena.curr_block = new_block
			arena.total_reserved += new_block.reserved
		}

		prev_used := arena.curr_block.used
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment, default_commit_size=arena.default_commit_size)
		arena.total_used += arena.curr_block.used - prev_used
	case .Static:
		if arena.curr_block == nil {
			if arena.minimum_block_size == 0 {
				arena.minimum_block_size = DEFAULT_ARENA_STATIC_RESERVE_SIZE
			}
			arena_init_static(arena, reserved=arena.minimum_block_size, commit_size=DEFAULT_ARENA_STATIC_COMMIT_SIZE) or_return
		}
		if arena.curr_block == nil {
			return nil, .Out_Of_Memory
		}
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment, default_commit_size=arena.default_commit_size)
		arena.total_used = arena.curr_block.used

	case .Buffer:
		if arena.curr_block == nil {
			return nil, .Out_Of_Memory
		}
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment, default_commit_size=0)
		arena.total_used = arena.curr_block.used
	}
	return
}

// Resets the memory of a Static or Buffer arena to a specific `position` (offset) and zeroes the previously used memory.
arena_static_reset_to :: proc(arena: ^Arena, pos: uint, loc := #caller_location) -> bool {
	sync.mutex_guard(&arena.mutex)

	if arena.curr_block != nil {
		assert(arena.kind != .Growing, "expected a non .Growing arena", loc)

		prev_pos := arena.curr_block.used
		arena.curr_block.used = clamp(pos, 0, arena.curr_block.reserved)

		if prev_pos > pos {
			mem.zero_slice(arena.curr_block.base[arena.curr_block.used:][:prev_pos-pos])
		}
		arena.total_used = arena.curr_block.used
		return true
	} else if pos == 0 {
		arena.total_used = 0
		return true
	}
	return false
}

// Frees the last memory block of a Growing Arena
arena_growing_free_last_memory_block :: proc(arena: ^Arena, loc := #caller_location) {
	if free_block := arena.curr_block; free_block != nil {
		assert(arena.kind == .Growing, "expected a .Growing arena", loc)
		arena.total_used -= free_block.used
		arena.total_reserved -= free_block.reserved

		arena.curr_block = free_block.prev
		memory_block_dealloc(free_block)
	}
}

// Deallocates all but the first memory block of the arena and resets the allocator's usage to 0.
arena_free_all :: proc(arena: ^Arena, loc := #caller_location) {
	switch arena.kind {
	case .Growing:
		sync.mutex_guard(&arena.mutex)
		// NOTE(bill): Free all but the first memory block (if it exists)
		for arena.curr_block != nil && arena.curr_block.prev != nil {
			arena_growing_free_last_memory_block(arena, loc)
		}
		// Zero the first block's memory
		if arena.curr_block != nil {
			curr_block_used := int(arena.curr_block.used)
			arena.curr_block.used = 0
			mem.zero(arena.curr_block.base, curr_block_used)
		}
		arena.total_used = 0
	case .Static, .Buffer:
		arena_static_reset_to(arena, 0)
	}
	arena.total_used = 0
}

// Frees all of the memory allocated by the arena and zeros all of the values of an arena.
// A buffer based arena does not `delete` the provided `[]byte` bufffer.
arena_destroy :: proc(arena: ^Arena, loc := #caller_location) {
	sync.mutex_guard(&arena.mutex)
	switch arena.kind {
	case .Growing:
		for arena.curr_block != nil {
			arena_growing_free_last_memory_block(arena, loc)
		}
	case .Static:
		memory_block_dealloc(arena.curr_block)
	case .Buffer:
		// nothing
	}
	arena.curr_block     = nil
	arena.total_used     = 0
	arena.total_reserved = 0
	arena.temp_count     = 0
}

// Ability to bootstrap allocate a struct with an arena within the struct itself using the growing variant strategy.
arena_growing_bootstrap_new :: proc{
	arena_growing_bootstrap_new_by_offset,
	arena_growing_bootstrap_new_by_name,
}

// Ability to bootstrap allocate a struct with an arena within the struct itself using the static variant strategy.
arena_static_bootstrap_new :: proc{
	arena_static_bootstrap_new_by_offset,
	arena_static_bootstrap_new_by_name,
}

// Ability to bootstrap allocate a struct with an arena within the struct itself using the growing variant strategy.
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

// Ability to bootstrap allocate a struct with an arena within the struct itself using the growing variant strategy.
@(require_results)
arena_growing_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, minimum_block_size: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	return arena_growing_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), minimum_block_size)
}

// Ability to bootstrap allocate a struct with an arena within the struct itself using the static variant strategy.
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

// Ability to bootstrap allocate a struct with an arena within the struct itself using the static variant strategy.
@(require_results)
arena_static_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	return arena_static_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), reserved)
}


// Create an `Allocator` from the provided `Arena`
@(require_results)
arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return mem.Allocator{arena_allocator_proc, arena}
}

// The allocator procedure used by an `Allocator` produced by `arena_allocator`
arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
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
		case uintptr(old_data) & uintptr(alignment-1) == 0:
			if size < old_size {
				// shrink data in-place
				data = old_data[:size]
				return
			}

			if block := arena.curr_block; block != nil {
				start := uint(uintptr(old_memory)) - uint(uintptr(block.base))
				old_end := start + old_size
				new_end := start + size
				if start < old_end && old_end == block.used && new_end <= block.reserved {
					// grow data in-place, adjusting next allocation
					_ = alloc_from_memory_block(block, new_end - old_end, 1, default_commit_size=arena.default_commit_size) or_return
					data = block.base[start:new_end]
					return
				}
			}
		}

		new_memory := arena_alloc(arena, size, alignment, location) or_return
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




// An `Arena_Temp` is a way to produce temporary watermarks to reset an arena to a previous state.
// All uses of an `Arena_Temp` must be handled by ending them with `arena_temp_end` or ignoring them with `arena_temp_ignore`.
Arena_Temp :: struct {
	arena: ^Arena,
	block: ^Memory_Block,
	used:  uint,
}

// Begins the section of temporary arena memory.
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

// Ends the section of temporary arena memory by resetting the memory to the stored position.
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
			amount_to_zero := block.used-temp.used
			mem.zero_slice(block.base[temp.used:][:amount_to_zero])
			block.used = temp.used
			arena.total_used -= amount_to_zero
		}
	}

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Ignore the use of a `arena_temp_begin` entirely by __not__ resetting to the stored position.
arena_temp_ignore :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena
	sync.mutex_guard(&arena.mutex)

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Asserts that all uses of `Arena_Temp` has been used by an `Arena`
arena_check_temp :: proc(arena: ^Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Arena_Temp not been ended", loc)
}
