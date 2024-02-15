package mem

import "base:intrinsics"
import "base:runtime"

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


arena_init :: proc(a: ^Arena, data: []byte) {
	a.data       = data
	a.offset     = 0
	a.peak_used  = 0
	a.temp_count = 0
}

@(deprecated="prefer 'mem.arena_init'")
init_arena :: proc(a: ^Arena, data: []byte) {
	a.data       = data
	a.offset     = 0
	a.peak_used  = 0
	a.temp_count = 0
}

@(require_results)
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
	case .Alloc, .Alloc_Non_Zeroed:
		#no_bounds_check end := &arena.data[arena.offset]

		ptr := align_forward(end, uintptr(alignment))

		total_size := size + ptr_sub((^byte)(ptr), (^byte)(end))

		if arena.offset + total_size > len(arena.data) {
			return nil, .Out_Of_Memory
		}

		arena.offset += total_size
		arena.peak_used = max(arena.peak_used, arena.offset)
		if mode != .Alloc_Non_Zeroed {
			zero(ptr, size)
		}
		return byte_slice(ptr, size), nil

	case .Free:
		return nil, .Mode_Not_Implemented

	case .Free_All:
		arena.offset = 0

    case .Resize:
        return default_resize_bytes_align(byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena))

    case .Resize_Non_Zeroed:
        return default_resize_bytes_align_non_zeroed(byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena))

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

@(require_results)
begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
	tmp: Arena_Temp_Memory
	tmp.arena = a
	tmp.prev_offset = a.offset
	a.temp_count += 1
	return tmp
}

end_arena_temp_memory :: proc(tmp: Arena_Temp_Memory) {
	assert(tmp.arena.offset >= tmp.prev_offset)
	assert(tmp.arena.temp_count > 0)
	tmp.arena.offset = tmp.prev_offset
	tmp.arena.temp_count -= 1
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
		DEFAULT_BACKING_SIZE :: 4 * Megabyte
		if !(context.allocator.procedure != scratch_allocator_proc &&
		     context.allocator.data != allocator_data) {
			panic("cyclic initialization of the scratch allocator with itself")
		}
		scratch_allocator_init(s, DEFAULT_BACKING_SIZE)
	}

	size := size

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		size = align_forward_int(size, alignment)

		switch {
		case s.curr_offset+size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := start + uintptr(s.curr_offset)
			ptr = align_forward_uintptr(ptr, uintptr(alignment))
			if mode != .Alloc_Non_Zeroed {
				zero(rawptr(ptr), size)
			}

			s.prev_allocation = rawptr(ptr)
			offset := int(ptr - start)
			s.curr_offset = offset + size
			return byte_slice(rawptr(ptr), size), nil

		case size <= len(s.data):
			start := uintptr(raw_data(s.data))
			ptr := align_forward_uintptr(start, uintptr(alignment))
			if mode != .Alloc_Non_Zeroed {
				zero(rawptr(ptr), size)
			}

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
		if old_memory == nil {
			return nil, nil
		}
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

	case .Resize, .Resize_Non_Zeroed:
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
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

@(require_results)
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

stack_init :: proc(s: ^Stack, data: []byte) {
	s.data = data
	s.prev_offset = 0
	s.curr_offset = 0
	s.peak_used = 0
}

@(deprecated="prefer 'mem.stack_init'")
init_stack :: proc(s: ^Stack, data: []byte) {
	s.data = data
	s.prev_offset = 0
	s.curr_offset = 0
	s.peak_used = 0
}

@(require_results)
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

	raw_alloc :: proc(s: ^Stack, size, alignment: int, zero_memory: bool) -> ([]byte, Allocator_Error) {
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

		if zero_memory {
			zero(rawptr(next_addr), size)
		}
		return byte_slice(rawptr(next_addr), size), nil
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return raw_alloc(s, size, alignment, mode == .Alloc)
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

	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return raw_alloc(s, size, alignment, mode == .Resize)
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
			data, err := raw_alloc(s, size, alignment, mode == .Resize)
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
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
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
	data:      []byte,
	offset:    int,
	peak_used: int,
}

small_stack_init :: proc(s: ^Small_Stack, data: []byte) {
	s.data      = data
	s.offset    = 0
	s.peak_used = 0
}

@(deprecated="prefer 'small_stack_init'")
init_small_stack :: proc(s: ^Small_Stack, data: []byte) {
	s.data      = data
	s.offset    = 0
	s.peak_used = 0
}

@(require_results)
small_stack_allocator :: proc(stack: ^Small_Stack) -> Allocator {
	return Allocator{
		procedure = small_stack_allocator_proc,
		data      = stack,
	}
}

small_stack_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                   size, alignment: int,
                                   old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, Allocator_Error) {
	s := cast(^Small_Stack)allocator_data

	if s.data == nil {
		return nil, .Invalid_Argument
	}

	align := clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)

	raw_alloc :: proc(s: ^Small_Stack, size, alignment: int, zero_memory: bool) -> ([]byte, Allocator_Error) {
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

		if zero_memory {
			zero(rawptr(next_addr), size)
		}
		return byte_slice(rawptr(next_addr), size), nil
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return raw_alloc(s, size, align, mode == .Alloc)
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

	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return raw_alloc(s, size, align, mode == .Resize)
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

		data, err := raw_alloc(s, size, align, mode == .Resize)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
		}
		return data, err

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
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

	unused_blocks:        [dynamic]rawptr,
	used_blocks:          [dynamic]rawptr,
	out_band_allocations: [dynamic]rawptr,

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
	case .Alloc, .Alloc_Non_Zeroed:
		return dynamic_pool_alloc_bytes(pool, size)
	case .Free:
		return nil, .Mode_Not_Implemented
	case .Free_All:
		dynamic_pool_free_all(pool)
		return nil, nil
	case .Resize, .Resize_Non_Zeroed:
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
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features, .Query_Info}
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


@(require_results)
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
	pool.out_band_allocations.allocator = array_allocator
	pool.       unused_blocks.allocator = array_allocator
	pool.         used_blocks.allocator = array_allocator
}

dynamic_pool_destroy :: proc(pool: ^Dynamic_Pool) {
	dynamic_pool_free_all(pool)
	delete(pool.unused_blocks)
	delete(pool.used_blocks)
	delete(pool.out_band_allocations)

	zero(pool, size_of(pool^))
}


@(require_results)
dynamic_pool_alloc :: proc(pool: ^Dynamic_Pool, bytes: int) -> (rawptr, Allocator_Error) {
	data, err := dynamic_pool_alloc_bytes(pool, bytes)
	return raw_data(data), err
}

@(require_results)
dynamic_pool_alloc_bytes :: proc(p: ^Dynamic_Pool, bytes: int) -> ([]byte, Allocator_Error) {
	cycle_new_block :: proc(p: ^Dynamic_Pool) -> (err: Allocator_Error) {
		if p.block_allocator.procedure == nil {
			panic("You must call pool_init on a Pool before using it")
		}

		if p.current_block != nil {
			append(&p.used_blocks, p.current_block)
		}

		new_block: rawptr
		if len(p.unused_blocks) > 0 {
			new_block = pop(&p.unused_blocks)
		} else {
			data: []byte
			data, err = p.block_allocator.procedure(p.block_allocator.data, Allocator_Mode.Alloc,
			                                        p.block_size, p.alignment,
			                                        nil, 0)
			new_block = raw_data(data)
		}

		p.bytes_left    = p.block_size
		p.current_pos   = new_block
		p.current_block = new_block
		return
	}

	n := bytes
	extra := p.alignment - (n % p.alignment)
	n += extra
	if n > p.block_size {
		return nil, .Invalid_Argument
	}
	if n >= p.out_band_size {
		assert(p.block_allocator.procedure != nil)
		memory, err := p.block_allocator.procedure(p.block_allocator.data, Allocator_Mode.Alloc,
		                                           p.block_size, p.alignment,
		                                           nil, 0)
		if memory != nil {
			append(&p.out_band_allocations, raw_data(memory))
		}
		return memory, err
	}

	if p.bytes_left < n {
		err := cycle_new_block(p)
		if err != nil {
			return nil, err
		}
		if p.current_block == nil {
			return nil, .Out_Of_Memory
		}
	}

	memory := p.current_pos
	p.current_pos = ([^]byte)(p.current_pos)[n:]
	p.bytes_left -= n
	return ([^]byte)(memory)[:bytes], nil
}


dynamic_pool_reset :: proc(p: ^Dynamic_Pool) {
	if p.current_block != nil {
		append(&p.unused_blocks, p.current_block)
		p.current_block = nil
	}

	for block in p.used_blocks {
		append(&p.unused_blocks, block)
	}
	clear(&p.used_blocks)

	for a in p.out_band_allocations {
		free(a, p.block_allocator)
	}
	clear(&p.out_band_allocations)

	p.bytes_left = 0 // Make new allocations call `cycle_new_block` again.
}

dynamic_pool_free_all :: proc(p: ^Dynamic_Pool) {
	dynamic_pool_reset(p)

	for block in p.unused_blocks {
		free(block, p.block_allocator)
	}
	clear(&p.unused_blocks)
}


panic_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,loc := #caller_location) -> ([]byte, Allocator_Error) {

	switch mode {
	case .Alloc:
		if size > 0 {
			panic("mem: panic allocator, .Alloc called", loc=loc)
		}
	case .Alloc_Non_Zeroed:
		if size > 0 {
			panic("mem: panic allocator, .Alloc_Non_Zeroed called", loc=loc)
		}
	case .Resize:
		if size > 0 {
			panic("mem: panic allocator, .Resize called", loc=loc)
		}
	case .Resize_Non_Zeroed:
		if size > 0 {
			panic("mem: panic allocator, .Resize_Non_Zeroed called", loc=loc)
		}
	case .Free:
		if old_memory != nil {
			panic("mem: panic allocator, .Free called", loc=loc)
		}
	case .Free_All:
		panic("mem: panic allocator, .Free_All called", loc=loc)

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features}
		}
		return nil, nil

	case .Query_Info:
		panic("mem: panic allocator, .Query_Info called", loc=loc)
	}

	return nil, nil
}

@(require_results)
panic_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = panic_allocator_proc,
		data = nil,
	}
}
