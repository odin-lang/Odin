package mem_virtual

import "core:mem"
import "core:sync"

// import "base:sanitizer"

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

	`total_used` and `curr_block.used` are only brought up to date when the arena changes or resets a block.
	`arena_total_used` gives the live value.
*/
Arena :: struct {
	// The current block's base, committed size, and used size, for the fast path
	_base:               [^]byte,
	_end:                uint,
	_offset:             uint,

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


// Writes the fast path's offset back to the current block, so block-level code sees it.
@(private, no_sanitize_address)
arena_close :: #force_inline proc "contextless" (arena: ^Arena) {
	if block := arena.curr_block; block != nil {
		arena.total_used += arena._offset - block.used
		block.used = arena._offset
	}
}

// Hands the current block to the fast path.
@(private, no_sanitize_address)
arena_open :: #force_inline proc "contextless" (arena: ^Arena) {
	if block := arena.curr_block; block != nil {
		arena._base   = block.base
		arena._end    = block.committed
		arena._offset = block.used
	} else {
		arena._base   = nil
		arena._end    = 0
		arena._offset = 0
	}
}


// Initialization of an `Arena` to be a `.Growing` variant.
// A growing arena is a linked list of `Memory_Block`s allocated with virtual memory.
@(require_results, no_sanitize_address)
arena_init_growing :: proc(arena: ^Arena, reserved: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Growing
	arena.curr_block     = memory_block_alloc(0, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved

	if arena.minimum_block_size == 0 {
		arena.minimum_block_size = reserved
	}
	arena_open(arena)
	// sanitizer.address_poison(arena.curr_block.base[:arena.curr_block.committed])
	return
}


// Initialization of an `Arena` to be a `.Static` variant.
// A static arena contains a single `Memory_Block` allocated with virtual memory.
@(require_results, no_sanitize_address)
arena_init_static :: proc(arena: ^Arena, reserved: uint = DEFAULT_ARENA_STATIC_RESERVE_SIZE, commit_size: uint = DEFAULT_ARENA_STATIC_COMMIT_SIZE) -> (err: Allocator_Error) {
	arena.kind           = .Static
	arena.curr_block     = memory_block_alloc(commit_size, reserved, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved
	arena_open(arena)
	// sanitizer.address_poison(arena.curr_block.base[:arena.curr_block.committed])
	return
}

// Initialization of an `Arena` to be a `.Buffer` variant.
// A buffer arena contains single `Memory_Block` created from a user provided []byte.
@(require_results, no_sanitize_address)
arena_init_buffer :: proc(arena: ^Arena, buffer: []byte) -> (err: Allocator_Error) {
	if len(buffer) < size_of(Memory_Block) {
		return .Out_Of_Memory
	}

	arena.kind = .Buffer

	// sanitizer.address_poison(buffer[:])

	block_base := raw_data(buffer)
	block := (^Memory_Block)(block_base)
	block.base      = block_base[size_of(Memory_Block):]
	block.reserved  = len(buffer) - size_of(Memory_Block)
	block.committed = block.reserved
	block.used      = 0

	arena.curr_block = block
	arena.total_used = 0
	arena.total_reserved = arena.curr_block.reserved
	arena_open(arena)
	return
}

// Allocates memory from the provided arena.
@(require_results, no_sanitize_address)
arena_alloc :: #force_inline proc(arena: ^Arena, size: uint, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	assert(alignment & (alignment-1) == 0, "non-power of two alignment", loc)

	size := size
	if size == 0 {
		return nil, nil
	}

	sync.mutex_guard(&arena.mutex)
	return arena_alloc_unguarded(arena, size, alignment, loc)
}

// Allocates memory from the provided arena.
@(require_results, no_sanitize_address, private)
arena_alloc_unguarded :: #force_inline proc(arena: ^Arena, size: uint, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	if size == 0 {
		return nil, nil
	}
	if fast, ok := arena_alloc_fast(arena, size, max(alignment, 1)); ok {
		return fast, nil
	}
	return arena_alloc_slow(arena, size, alignment, loc)
}

@(require_results, no_sanitize_address, private)
arena_alloc_fast :: #force_inline proc "contextless" (arena: ^Arena, size, alignment: uint) -> (data: []byte, ok: bool) #no_bounds_check {
	used := arena._offset
	end  := arena._end
	pad  := (alignment - ((uint(uintptr(arena._base)) + used) & (alignment-1))) & (alignment-1)
	if pad > end-used || size > end-used-pad {
		return
	}

	arena._offset = used + pad + size
	return arena._base[used+pad:][:size], true
}

// Commits more memory, or moves to a new memory block, then allocates.
@(cold, require_results, no_sanitize_address, private)
arena_alloc_slow :: proc(arena: ^Arena, size: uint, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena_close(arena)
	defer arena_open(arena)

	switch arena.kind {
	case .Growing:
		prev_used := 0 if arena.curr_block == nil else arena.curr_block.used
		data, err = alloc_from_memory_block(arena.curr_block, size, alignment, default_commit_size=arena.default_commit_size)
		if err == .Out_Of_Memory {
			if arena.minimum_block_size == 0 {
				arena.minimum_block_size = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE
				arena.minimum_block_size = mem.align_forward_uint(arena.minimum_block_size, uint(mem.PAGE_SIZE))
			}
			if arena.default_commit_size == 0 {
				arena.default_commit_size = min(DEFAULT_ARENA_GROWING_COMMIT_SIZE, arena.minimum_block_size)
				arena.default_commit_size = mem.align_forward_uint(arena.default_commit_size, uint(mem.PAGE_SIZE))
			}

			if arena.default_commit_size != 0 {
				arena.default_commit_size, arena.minimum_block_size =
					min(arena.default_commit_size, arena.minimum_block_size),
					max(arena.default_commit_size, arena.minimum_block_size)
			}

			needed := max(size, arena.default_commit_size)
			block_size := max(needed, arena.minimum_block_size)

			new_block := memory_block_alloc(needed, block_size, alignment) or_return
			new_block.prev = arena.curr_block
			arena.curr_block = new_block
			arena.total_reserved += new_block.reserved

			prev_used = 0
			data, err = alloc_from_memory_block(arena.curr_block, size, alignment, default_commit_size=arena.default_commit_size)
		}
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

	// sanitizer.address_unpoison(data)
	return
}

// Resets the memory of a Static or Buffer arena to a specific `position` (offset) and zeroes the previously used memory.
@(no_sanitize_address)
arena_static_reset_to :: proc(arena: ^Arena, pos: uint, loc := #caller_location) -> bool {
	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

	if block := arena.curr_block; block != nil {
		assert(arena.kind != .Growing, "expected a non .Growing arena", loc)

		new_pos := min(pos, block.reserved)
		switch {
		case new_pos < block.used:
			mem.zero_slice(block.base[new_pos:block.used])
			block.used = new_pos
		case new_pos > block.used:
			// Moving forward commits the memory in between.
			if _, err := alloc_from_memory_block(block, new_pos-block.used, 1, arena.default_commit_size); err != nil {
				return false
			}
		}
		arena.total_used = block.used
		// sanitizer.address_poison(arena.curr_block.base[:arena.curr_block.committed])
		return true
	} else if pos == 0 {
		arena.total_used = 0
		return true
	}
	return false
}

// Frees the last memory block of a Growing Arena
@(no_sanitize_address)
arena_growing_free_last_memory_block :: proc(arena: ^Arena, loc := #caller_location) {
	arena_close(arena)
	defer arena_open(arena)

	if free_block := arena.curr_block; free_block != nil {
		assert(arena.kind == .Growing, "expected a .Growing arena", loc)
		arena.total_used -= free_block.used
		arena.total_reserved -= free_block.reserved

		arena.curr_block = free_block.prev
		// sanitizer.address_poison(free_block.base[:free_block.committed])
		memory_block_dealloc(free_block)
	}
}

// Deallocates all but the first memory block of the arena and resets the allocator's usage to 0.
@(no_sanitize_address)
arena_free_all :: proc(arena: ^Arena, loc := #caller_location) {
	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

	arena_free_all_unguarded(arena, loc)
}

@(no_sanitize_address, private)
arena_free_all_unguarded :: proc(arena: ^Arena, loc := #caller_location) {
	// NOTE(bill): Free all but the first memory block (if it exists)
	for arena.curr_block != nil && arena.curr_block.prev != nil {
		arena_growing_free_last_memory_block(arena, loc)
	}
	// Zero the first block's memory
	if arena.curr_block != nil {
		curr_block_used := int(arena.curr_block.used)
		arena.curr_block.used = 0
		// sanitizer.address_unpoison(arena.curr_block.base[:curr_block_used])
		mem.zero(arena.curr_block.base, curr_block_used)
		// sanitizer.address_poison(arena.curr_block.base[:arena.curr_block.committed])
	}
	arena.total_used = 0
}

// Frees all of the memory allocated by the arena and zeros all of the values of an arena.
// A buffer based arena does not `delete` the provided `[]byte` bufffer.
@(no_sanitize_address)
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
	arena_open(arena)
}

// The number of bytes used across all of the arena's memory blocks, including alignment padding.
@(require_results, no_sanitize_address)
arena_total_used :: proc(arena: ^Arena) -> uint {
	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

	return arena.total_used
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
@(require_results, no_sanitize_address)
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
@(require_results, no_sanitize_address)
arena_growing_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, minimum_block_size: uint = DEFAULT_ARENA_GROWING_MINIMUM_BLOCK_SIZE) -> (ptr: ^T, err: Allocator_Error) {
	return arena_growing_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), minimum_block_size)
}

// Ability to bootstrap allocate a struct with an arena within the struct itself using the static variant strategy.
@(require_results, no_sanitize_address)
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
@(require_results, no_sanitize_address)
arena_static_bootstrap_new_by_name :: proc($T: typeid, $field_name: string, reserved: uint) -> (ptr: ^T, err: Allocator_Error) {
	return arena_static_bootstrap_new_by_offset(T, offset_of_by_string(T, field_name), reserved)
}


// Create an `Allocator` from the provided `Arena`
@(require_results, no_sanitize_address)
arena_allocator :: proc(arena: ^Arena) -> mem.Allocator {
	return mem.Allocator{arena_allocator_proc, arena}
}

// The allocator procedure used by an `Allocator` produced by `arena_allocator`
@(no_sanitize_address)
arena_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	arena := (^Arena)(allocator_data)

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return arena_alloc(arena, uint(size), uint(alignment), location)
	case .Free:
		err = .Mode_Not_Implemented
	case .Free_All:
		arena_free_all(arena, location)
	case .Resize, .Resize_Non_Zeroed:
		return arena_resize(arena, old_memory, uint(old_size), uint(size), uint(alignment), location)
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

@(no_sanitize_address, private)
arena_resize :: #force_no_inline proc(arena: ^Arena, old_memory: rawptr, old_size, size, alignment: uint, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
	old_data := ([^]byte)(old_memory)

	switch {
	case old_data == nil:
		return arena_alloc(arena, size, alignment, loc)
	case size == old_size && uintptr(old_data) & uintptr(alignment-1) == 0:
		// return old memory
		data = old_data[:size]
		return
	case size == 0:
		err = .Mode_Not_Implemented
		return
	}

	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

	if uintptr(old_data) & uintptr(alignment-1) == 0 {
		if block := arena.curr_block; block != nil {
			start := uint(uintptr(old_memory)) - uint(uintptr(block.base))
			old_end := start + old_size
			new_end := start + size
			if start < old_end && old_end == block.used && new_end <= block.reserved {
				switch {
				case size > old_size:
					// Grow data in-place by adjusting the next allocation
					prev_used := block.used
					_ = alloc_from_memory_block(block, new_end - old_end, 1, default_commit_size=arena.default_commit_size) or_return
					arena.total_used += block.used - prev_used

				case arena.temp_count == 0:
					// Shrink data in-place by giving the tail back to the block
					//
					// NOTE(bill): This is not done while an `Arena_Temp` is active.
					// It may have saved a position inside the tail.
					// The memory past `used` is kept zeroed because `.Alloc` relies on it.
					mem.zero_slice(block.base[new_end:old_end])
					// sanitizer.address_poison(block.base[new_end:old_end])
					block.used = new_end
					arena.total_used -= old_size - size
				}
				data = block.base[start:new_end]
				// sanitizer.address_unpoison(data)
				return
			}
		}

		if size < old_size {
			// Allow for shrinking data in-place
			data = old_data[:size]
			// sanitizer.address_poison(old_data[size:old_size])
			return
		}
	}

	new_memory := arena_alloc_slow(arena, size, alignment, loc) or_return
	if new_memory == nil {
		return
	}
	copy(new_memory, old_data[:old_size])
	// sanitizer.address_poison(old_data[:old_size])
	return new_memory, nil
}




// An `Arena_Temp` is a way to produce temporary watermarks to reset an arena to a previous state.
// All uses of an `Arena_Temp` must be handled by ending them with `arena_temp_end` or ignoring them with `arena_temp_ignore`.
Arena_Temp :: struct {
	arena: ^Arena,
	block: ^Memory_Block,
	used:  uint,
}

// Begins the section of temporary arena memory.
@(require_results, no_sanitize_address)
arena_temp_begin :: proc(arena: ^Arena, loc := #caller_location) -> (temp: Arena_Temp) {
	assert(arena != nil, "nil arena", loc)
	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

	temp.arena = arena
	temp.block = arena.curr_block
	if arena.curr_block != nil {
		temp.used = arena.curr_block.used
	}
	arena.temp_count += 1
	return
}

// Ends the section of temporary arena memory by resetting the memory to the stored position.
@(no_sanitize_address)
arena_temp_end :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena
	sync.mutex_guard(&arena.mutex)
	arena_close(arena)
	defer arena_open(arena)

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
	} else {
		// The arena had no memory block when the temp began: everything in it is newer.
		arena_free_all_unguarded(arena, loc)
	}

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Ignore the use of a `arena_temp_begin` entirely by __not__ resetting to the stored position.
@(no_sanitize_address)
arena_temp_ignore :: proc(temp: Arena_Temp, loc := #caller_location) {
	assert(temp.arena != nil, "nil arena", loc)
	arena := temp.arena
	sync.mutex_guard(&arena.mutex)

	assert(arena.temp_count > 0, "double-use of arena_temp_end", loc)
	arena.temp_count -= 1
}

// Asserts that all uses of `Arena_Temp` has been used by an `Arena`
@(no_sanitize_address)
arena_check_temp :: proc(arena: ^Arena, loc := #caller_location) {
	assert(arena.temp_count == 0, "Arena_Temp not been ended", loc)
}
