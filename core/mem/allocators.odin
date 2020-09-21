package mem

import "core:intrinsics"
import "core:runtime"

nil_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return nil, nil
}

nil_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	}
}

// Custom allocators

Arena :: struct {
	data:       []byte,
	offset:     int,
	peak_used:  int,
	temp_count: int,
}

Arena_Temp_Memory :: struct {
	arena:       ^Arena,
	prev_offset: int,
}


init_arena :: proc(a: ^Arena, data: []byte) {
	a.data       = data
	a.offset     = 0
	a.peak_used  = 0
	a.temp_count = 0
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	}
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, Allocator_Error)  {
	arena := cast(^Arena)allocator_data

	switch mode {
	case .Alloc:
		total_size := size + alignment

		if arena.offset + total_size > len(arena.data) {
			return nil, .Out_Of_Memory
		}

		#no_bounds_check end := &arena.data[arena.offset]

		ptr := align_forward(end, uintptr(alignment))
		arena.offset += total_size
		arena.peak_used = max(arena.peak_used, arena.offset)
		zero(ptr, size)
		return byte_slice(ptr, size), nil

	case .Free:
		return nil, .Mode_Not_Implemented

	case .Free_All:
		arena.offset = 0

	case .Resize:
		return default_resize_bytes_align(byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena))

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free_All, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
	tmp: Arena_Temp_Memory
	tmp.arena = a
	tmp.prev_offset = a.offset
	a.temp_count += 1
	return tmp
}

end_arena_temp_memory :: proc(using tmp: Arena_Temp_Memory) {
	assert(arena.offset >= prev_offset)
	assert(arena.temp_count > 0)
	arena.offset = prev_offset
	arena.temp_count -= 1
}



Scratch_Allocator :: struct {
	data:               []byte,
	curr_offset:        int,
	prev_allocation:    rawptr,
	backup_allocator:   Allocator,
	leaked_allocations: [dynamic][]byte,
}

scratch_allocator_init :: proc(s: ^Scratch_Allocator, size: int, backup_allocator := context.allocator) -> Allocator_Error {
	s.data = make_aligned([]byte, size, 2*align_of(rawptr), backup_allocator) or_return
	s.curr_offset = 0
	s.prev_allocation = nil
	s.backup_allocator = backup_allocator
	s.leaked_allocations.allocator = backup_allocator
	return nil
}

scratch_allocator_destroy :: proc(s: ^Scratch_Allocator) {
	if s == nil {
		return
	}
	for ptr in s.leaked_allocations {
		free_bytes(ptr, s.backup_allocator)
	}
	delete(s.leaked_allocations)
	delete(s.data, s.backup_allocator)
	s^ = {}
}

scratch_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {

	s := (^Scratch_Allocator)(allocator_data)

	if s.data == nil {
		DEFAULT_BACKING_SIZE :: 1<<22
		if !(context.allocator.procedure != scratch_allocator_proc &&
		     context.allocator.data != allocator_data) {
			panic("cyclic initialization of the scratch allocator with itself")
		}
		scratch_allocator_init(s, DEFAULT_BACKING_SIZE)
	}

	size := size

	switch mode {
	case .Alloc:
		size = align_forward_int(size, alignment)

		switch {
		case s.curr_offset+size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := start + uintptr(s.curr_offset)
			ptr = align_forward_uintptr(ptr, uintptr(alignment))
			zero(rawptr(ptr), size)

			s.prev_allocation = rawptr(ptr)
			offset := int(ptr - start)
			s.curr_offset = offset + size
			return byte_slice(rawptr(ptr), size), nil

		case size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := align_forward_uintptr(start, uintptr(alignment))
			zero(rawptr(ptr), size)

			s.prev_allocation = rawptr(ptr)
			offset := int(ptr - start)
			s.curr_offset = offset + size
			return byte_slice(rawptr(ptr), size), nil
		}
		a := s.backup_allocator
		if a.procedure == nil {
			a = context.allocator
			s.backup_allocator = a
		}

		ptr, err := alloc_bytes(size, alignment, a, loc)
		if err != nil {
			return ptr, err
		}
		if s.leaked_allocations == nil {
			s.leaked_allocations, err = make([dynamic][]byte, a)
		}
		append(&s.leaked_allocations, ptr)

		if logger := context.logger; logger.lowest_level <= .Warning {
			if logger.procedure != nil {
				logger.procedure(logger.data, .Warning, "mem.Scratch_Allocator resorted to backup_allocator" , logger.options, loc)
			}
		}

		return ptr, err

	case .Free:
		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		old_ptr := uintptr(old_memory)

		if s.prev_allocation == old_memory {
			s.curr_offset = int(uintptr(s.prev_allocation) - start)
			s.prev_allocation = nil
			return nil, nil
		}

		if start <= old_ptr && old_ptr < end {
			// NOTE(bill): Cannot free this pointer but it is valid
			return nil, nil
		}

		if len(s.leaked_allocations) != 0 {
			for data, i in s.leaked_allocations {
				ptr := raw_data(data)
				if ptr == old_memory {
					free_bytes(data, s.backup_allocator)
					ordered_remove(&s.leaked_allocations, i)
					return nil, nil
				}
			}
		}
		return nil, .Invalid_Pointer
		// panic("invalid pointer passed to default_temp_allocator");

	case .Free_All:
		s.curr_offset = 0
		s.prev_allocation = nil
		for ptr in s.leaked_allocations {
			free_bytes(ptr, s.backup_allocator)
		}
		clear(&s.leaked_allocations)

	case .Resize:
		begin := uintptr(raw_data(s.data))
		end := begin + uintptr(len(s.data))
		old_ptr := uintptr(old_memory)
		if begin <= old_ptr && old_ptr < end && old_ptr+uintptr(size) < end {
			s.curr_offset = int(old_ptr-begin)+size
			return byte_slice(old_memory, size), nil
		}
		data, err := scratch_allocator_proc(allocator_data, .Alloc, size, alignment, old_memory, old_size, loc)
		if err != nil {
			return data, err
		}
		runtime.copy(data, byte_slice(old_memory, old_size))
		_, err = scratch_allocator_proc(allocator_data, .Free, 0, alignment, old_memory, old_size, loc)
		return data, err

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

scratch_allocator :: proc(allocator: ^Scratch_Allocator) -> Allocator {
	return Allocator{
		procedure = scratch_allocator_proc,
		data = allocator,
	}
}





Stack_Allocation_Header :: struct {
	prev_offset: int,
	padding:     int,
}

// Stack is a stack-like allocator which has a strict memory freeing order
Stack :: struct {
	data: []byte,
	prev_offset: int,
	curr_offset: int,
	peak_used: int,
}

init_stack :: proc(s: ^Stack, data: []byte) {
	s.data = data
	s.prev_offset = 0
	s.curr_offset = 0
	s.peak_used = 0
}

stack_allocator :: proc(stack: ^Stack) -> Allocator {
	return Allocator{
		procedure = stack_allocator_proc,
		data = stack,
	}
}


stack_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, Allocator_Error) {
	s := cast(^Stack)allocator_data

	if s.data == nil {
		return nil, .Invalid_Argument
	}

	raw_alloc :: proc(s: ^Stack, size, alignment: int) -> ([]byte, Allocator_Error) {
		curr_addr := uintptr(raw_data(s.data)) + uintptr(s.curr_offset)
		padding := calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Stack_Allocation_Header))
		if s.curr_offset + padding + size > len(s.data) {
			return nil, .Out_Of_Memory
		}
		s.prev_offset = s.curr_offset
		s.curr_offset += padding

		next_addr := curr_addr + uintptr(padding)
		header := (^Stack_Allocation_Header)(next_addr - size_of(Stack_Allocation_Header))
		header.padding = padding
		header.prev_offset = s.prev_offset

		s.curr_offset += size

		s.peak_used = max(s.peak_used, s.curr_offset)

		zero(rawptr(next_addr), size)
		return byte_slice(rawptr(next_addr), size), nil
	}

	switch mode {
	case .Alloc:
		return raw_alloc(s, size, alignment)
	case .Free:
		if old_memory == nil {
			return nil, nil
		}
		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		curr_addr := uintptr(old_memory)

		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (free)")
		}

		if curr_addr >= start+uintptr(s.curr_offset) {
			// NOTE(bill): Allow double frees
			return nil, nil
		}

		header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))

		if old_offset != header.prev_offset {
			// panic("Out of order stack allocator free");
			return nil, .Invalid_Pointer
		}

		s.curr_offset = old_offset
		s.prev_offset = header.prev_offset

	case .Free_All:
		s.prev_offset = 0
		s.curr_offset = 0

	case .Resize:
		if old_memory == nil {
			return raw_alloc(s, size, alignment)
		}
		if size == 0 {
			return nil, nil
		}

		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		curr_addr := uintptr(old_memory)
		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (resize)")
		}

		if curr_addr >= start+uintptr(s.curr_offset) {
			// NOTE(bill): Allow double frees
			return nil, nil
		}

		if old_size == size {
			return byte_slice(old_memory, size), nil
		}

		header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))

		if old_offset != header.prev_offset {
			data, err := raw_alloc(s, size, alignment)
			if err == nil {
				runtime.copy(data, byte_slice(old_memory, old_size))
			}
			return data, err
		}

		old_memory_size := uintptr(s.curr_offset) - (curr_addr - start)
		assert(old_memory_size == uintptr(old_size))

		diff := size - old_size
		s.curr_offset += diff // works for smaller sizes too
		if diff > 0 {
			zero(rawptr(curr_addr + uintptr(diff)), diff)
		}

		return byte_slice(old_memory, size), nil

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}







Small_Stack_Allocation_Header :: struct {
	padding: u8,
}

// Small_Stack is a stack-like allocator which uses the smallest possible header but at the cost of non-strict memory freeing order
Small_Stack :: struct {
	data: []byte,
	offset: int,
	peak_used: int,
}

init_small_stack :: proc(s: ^Small_Stack, data: []byte) {
	s.data = data
	s.offset = 0
	s.peak_used = 0
}

small_stack_allocator :: proc(stack: ^Small_Stack) -> Allocator {
	return Allocator{
		procedure = small_stack_allocator_proc,
		data = stack,
	}
}

small_stack_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                   size, alignment: int,
                                   old_memory: rawptr, old_size: int, ocation := #caller_location) -> ([]byte, Allocator_Error) {
	s := cast(^Small_Stack)allocator_data

	if s.data == nil {
		return nil, .Invalid_Argument
	}

	align := clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)

	raw_alloc :: proc(s: ^Small_Stack, size, alignment: int) -> ([]byte, Allocator_Error) {
		curr_addr := uintptr(raw_data(s.data)) + uintptr(s.offset)
		padding := calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Small_Stack_Allocation_Header))
		if s.offset + padding + size > len(s.data) {
			return nil, .Out_Of_Memory
		}
		s.offset += padding

		next_addr := curr_addr + uintptr(padding)
		header := (^Small_Stack_Allocation_Header)(next_addr - size_of(Small_Stack_Allocation_Header))
		header.padding = auto_cast padding

		s.offset += size

		s.peak_used = max(s.peak_used, s.offset)

		zero(rawptr(next_addr), size)
		return byte_slice(rawptr(next_addr), size), nil
	}

	switch mode {
	case .Alloc:
		return raw_alloc(s, size, align)
	case .Free:
		if old_memory == nil {
			return nil, nil
		}
		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		curr_addr := uintptr(old_memory)

		if !(start <= curr_addr && curr_addr < end) {
			// panic("Out of bounds memory address passed to stack allocator (free)");
			return nil, .Invalid_Pointer
		}

		if curr_addr >= start+uintptr(s.offset) {
			// NOTE(bill): Allow double frees
			return nil, nil
		}

		header := (^Small_Stack_Allocation_Header)(curr_addr - size_of(Small_Stack_Allocation_Header))
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))

		s.offset = old_offset

	case .Free_All:
		s.offset = 0

	case .Resize:
		if old_memory == nil {
			return raw_alloc(s, size, align)
		}
		if size == 0 {
			return nil, nil
		}

		start := uintptr(raw_data(s.data))
		end := start + uintptr(len(s.data))
		curr_addr := uintptr(old_memory)
		if !(start <= curr_addr && curr_addr < end) {
			// panic("Out of bounds memory address passed to stack allocator (resize)");
			return nil, .Invalid_Pointer
		}

		if curr_addr >= start+uintptr(s.offset) {
			// NOTE(bill): Treat as a double free
			return nil, nil
		}

		if old_size == size {
			return byte_slice(old_memory, size), nil
		}

		data, err := raw_alloc(s, size, align)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
		}
		return data, err

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}





Dynamic_Pool :: struct {
	block_size:    int,
	out_band_size: int,
	alignment:     int,

	unused_blocks:   [dynamic]rawptr,
	used_blocks:     [dynamic]rawptr,
	out_band_blocks: [dynamic]rawptr, // allocations that are bigger than the OOB size, get a block all by themselves.

	current_block: rawptr,
	current_pos:   rawptr,
	bytes_left:    int,

	block_allocator: Allocator,
}


DYNAMIC_POOL_BLOCK_SIZE_DEFAULT       :: 65536
DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT :: 6554



dynamic_pool_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                    size, alignment: int,
                                    old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	pool := (^Dynamic_Pool)(allocator_data)

	switch mode {
	case .Alloc:
		return dynamic_pool_alloc_bytes(pool, size)
	case .Free:
		return nil, .Mode_Not_Implemented
	case .Free_All:
		dynamic_pool_free_all(pool)
		return nil, nil
	case .Resize:
		if old_size >= size {
			return byte_slice(old_memory, size), nil
		}
		data, err := dynamic_pool_alloc_bytes(pool, size)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
		}
		return data, err

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free_All, .Resize, .Query_Features, .Query_Info}
		}
		return nil, nil

	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			info.size = pool.block_size
			info.alignment = pool.alignment
			return byte_slice(info, size_of(info^)), nil
		}
		return nil, nil
	}
	return nil, nil
}


dynamic_pool_allocator :: proc(pool: ^Dynamic_Pool) -> Allocator {
	return Allocator{
		procedure = dynamic_pool_allocator_proc,
		data = pool,
	}
}

dynamic_pool_init :: proc(pool: ^Dynamic_Pool,
                          block_allocator := context.allocator,
                          array_allocator := context.allocator,
                          block_size := DYNAMIC_POOL_BLOCK_SIZE_DEFAULT,
                          out_band_size := DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT,
                          alignment := 8) {
	pool.block_size      = block_size
	pool.out_band_size   = out_band_size
	pool.alignment       = alignment
	pool.block_allocator = block_allocator
	pool.out_band_blocks.allocator = array_allocator
	pool.unused_blocks.allocator = array_allocator
	pool.used_blocks.allocator = array_allocator
}

dynamic_pool_destroy :: proc(using pool: ^Dynamic_Pool) {
	dynamic_pool_free_all(pool)
	delete(unused_blocks)
	delete(used_blocks)

	zero(pool, size_of(pool^))
}


dynamic_pool_alloc :: proc(pool: ^Dynamic_Pool, bytes: int) -> rawptr {
	data, err := dynamic_pool_alloc_bytes(pool, bytes)
	assert(err == nil)
	return raw_data(data)
}

dynamic_pool_alloc_bytes :: proc(using pool: ^Dynamic_Pool, bytes: int) -> ([]byte, Allocator_Error) {
	cycle_new_block :: proc(using pool: ^Dynamic_Pool) -> (err: Allocator_Error) {
		if block_allocator.procedure == nil {
			panic("You must call pool_init on a Pool before using it")
		}

		if current_block != nil {
			append(&used_blocks, current_block)
		}

		new_block: rawptr
		if len(unused_blocks) > 0 {
			new_block = pop(&unused_blocks)
		} else {
			data: []byte
			data, err = block_allocator.procedure(block_allocator.data, Allocator_Mode.Alloc,
			                                           block_size, alignment,
			                                           nil, 0)
			new_block = raw_data(data)
		}

		bytes_left = block_size
		current_pos = new_block
		current_block = new_block
		return
	}

	n := bytes
	extra := alignment - (n % alignment)
	n += extra

	// NOTE(tetra): If we are asked to allocate more than a certain size,
	// we allocate it into it's own block, all by itself.
	if n >= out_band_size {
		if n > block_size do return nil

		assert(block_allocator.procedure != nil)
		memory, err := block_allocator.procedure(block_allocator.data, Allocator_Mode.Alloc,
			                                block_size, alignment,
			                                nil, 0)
		if err != nil {
			append(&out_band_blocks, (^byte)(memory));
		}
		return memory, err
	}

	// .. Otherwise we append it on to the current block (assuming there's space for it),
	// or make a new block if there is not.

	if bytes_left < n {
		err := cycle_new_block(pool)
		if err != nil {
			return nil, err
		}
		if current_block == nil {
			return nil, .Out_Of_Memory
		}
	}

	memory := current_pos
	current_pos = ptr_offset((^byte)(current_pos), n)
	bytes_left -= n
	return byte_slice(memory, bytes), nil
}


dynamic_pool_reset :: proc(using pool: ^Dynamic_Pool) {
	if current_block != nil {
		append(&unused_blocks, current_block)
		current_block = nil
	}

	for block in used_blocks {
		append(&unused_blocks, block)
	}
	clear(&used_blocks)

	for a in out_band_blocks {
		free(a, block_allocator);
	}
	clear(&out_band_blocks);
}

dynamic_pool_free_all :: proc(using pool: ^Dynamic_Pool) {
	dynamic_pool_reset(pool)

	for block in unused_blocks {
		free(block, block_allocator)
	}
	clear(&unused_blocks)
}


panic_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,loc := #caller_location) -> ([]byte, Allocator_Error) {

	switch mode {
	case .Alloc:
		if size > 0 {
			panic("mem: panic allocator, .Alloc called")
		}
	case .Resize:
		if size > 0 {
			panic("mem: panic allocator, .Resize called")
		}
	case .Free:
		if old_memory != nil {
			panic("mem: panic allocator, .Free called")
		}
	case .Free_All:
		panic("mem: panic allocator, .Free_All called")

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features}
		}
		return nil, nil

	case .Query_Info:
		panic("mem: panic allocator, .Query_Info called")
	}

	return nil, nil
}

panic_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = panic_allocator_proc,
		data = nil,
	}
}

alloca_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = alloca_allocator_proc,
		data = nil,
	};
}


Tracking_Allocator_Entry :: struct {
	memory:    rawptr,
	size:      int,
	alignment: int,
	err:       Allocator_Error,
	location:  runtime.Source_Code_Location,
}
Tracking_Allocator_Bad_Free_Entry :: struct {
	memory:   rawptr,
	location: runtime.Source_Code_Location,
}
Tracking_Allocator :: struct {
	backing:           Allocator,
	allocation_map:    map[rawptr]Tracking_Allocator_Entry,
	bad_free_array:    [dynamic]Tracking_Allocator_Bad_Free_Entry,
	clear_on_free_all: bool,
}

tracking_allocator_init :: proc(t: ^Tracking_Allocator, backing_allocator: Allocator, internals_allocator := context.allocator) {
	t.backing = backing_allocator
	t.allocation_map.allocator = internals_allocator
	t.bad_free_array.allocator = internals_allocator
}

tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map)
	delete(t.bad_free_array)
}

tracking_allocator :: proc(data: ^Tracking_Allocator) -> Allocator {
	return Allocator{
		data = data,
		procedure = tracking_allocator_proc,
	}
}

tracking_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                size, alignment: int,
                                old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	data := (^Tracking_Allocator)(allocator_data)
	if mode == .Query_Info {
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			if entry, ok := data.allocation_map[info.pointer]; ok {
				info.size = entry.size
				info.alignment = entry.alignment
			}
			info.pointer = nil
		}

		return nil, nil
	}

	result: []byte
	err: Allocator_Error
	if mode == .Free && old_memory not_in data.allocation_map {
		append(&data.bad_free_array, Tracking_Allocator_Bad_Free_Entry{
			memory = old_memory,
			location = loc,
		})
	} else {
		result, err = data.backing.procedure(data.backing.data, mode, size, alignment, old_memory, old_size, loc)
		if err != nil {
			return result, err
		}
	}
	result_ptr := raw_data(result)

	if data.allocation_map.allocator.procedure == nil {
		data.allocation_map.allocator = context.allocator
	}

	switch mode {
	case .Alloc:
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry{
			memory = result_ptr,
			size = size,
			alignment = alignment,
			err = err,
			location = loc,
		}
	case .Free:
		delete_key(&data.allocation_map, old_memory)
	case .Resize:
		if old_memory != result_ptr {
			delete_key(&data.allocation_map, old_memory)
		}
		data.allocation_map[result_ptr] = Tracking_Allocator_Entry{
			memory = result_ptr,
			size = size,
			alignment = alignment,
			err = err,
			location = loc,
		}

	case .Free_All:
		if data.clear_on_free_all {
			clear_map(&data.allocation_map)
		}

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features, .Query_Info}
		}
		return nil, nil

	case .Query_Info:
		unreachable()
	}

	return result, err
}

