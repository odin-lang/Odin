package mem

import "base:intrinsics"
import "base:runtime"

nil_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	}
}

nil_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return nil, nil
}

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

@(require_results)
arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	}
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

arena_alloc :: proc(a: ^Arena, size: int, alignment := DEFAULT_ALIGNMENT) -> ([]byte, Allocator_Error) {
	bytes, err := arena_alloc_non_zeroed(a, size, alignment)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

arena_alloc_non_zeroed :: proc(a: ^Arena, size: int, alignment := DEFAULT_ALIGNMENT) -> ([]byte, Allocator_Error) {
	#no_bounds_check end := &a.data[a.offset]
	ptr := align_forward(end, uintptr(alignment))
	total_size := size + ptr_sub((^byte)(ptr), (^byte)(end))
	if a.offset + total_size > len(a.data) {
		return nil, .Out_Of_Memory
	}
	a.offset += total_size
	a.peak_used = max(a.peak_used, a.offset)
	return byte_slice(ptr, size), nil
}

arena_free_all :: proc(a: ^Arena) {
	a.offset = 0
}

arena_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size: int,
	alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location,
) -> ([]byte, Allocator_Error)  {
	arena := cast(^Arena)allocator_data
	switch mode {
	case .Alloc:
		return arena_alloc(arena, size, alignment)
	case .Alloc_Non_Zeroed:
		return arena_alloc_non_zeroed(arena, size, alignment)
	case .Free:
		return nil, .Mode_Not_Implemented
	case .Free_All:
		arena_free_all(arena)
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

/* old procedures */
Scratch_Allocator :: Scratch
scratch_allocator_init :: scratch_init
scratch_allocator_destroy :: scratch_destroy

Scratch :: struct {
	data:               []byte,
	curr_offset:        int,
	prev_allocation:    rawptr,
	backup_allocator:   Allocator,
	leaked_allocations: [dynamic][]byte,
}

@(require_results)
scratch_allocator :: proc(allocator: ^Scratch) -> Allocator {
	return Allocator{
		procedure = scratch_allocator_proc,
		data = allocator,
	}
}

scratch_init :: proc(s: ^Scratch, size: int, backup_allocator := context.allocator) -> Allocator_Error {
	s.data = make_aligned([]byte, size, 2*align_of(rawptr), backup_allocator) or_return
	s.curr_offset = 0
	s.prev_allocation = nil
	s.backup_allocator = backup_allocator
	s.leaked_allocations.allocator = backup_allocator
	return nil
}

scratch_destroy :: proc(s: ^Scratch) {
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

scratch_alloc :: proc(
	s: ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := scratch_alloc_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

scratch_alloc_non_zeroed :: proc(
	s: ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		DEFAULT_BACKING_SIZE :: 4 * Megabyte
		if !(context.allocator.procedure != scratch_allocator_proc && context.allocator.data != s) {
			panic("cyclic initialization of the scratch allocator with itself", loc)
		}
		scratch_init(s, DEFAULT_BACKING_SIZE)
	}
	size := size
	size = align_forward_int(size, alignment)
	switch {
	case s.curr_offset+size <= len(s.data):
		start := uintptr(raw_data(s.data))
		ptr := start + uintptr(s.curr_offset)
		ptr = align_forward_uintptr(ptr, uintptr(alignment))
		s.prev_allocation = rawptr(ptr)
		offset := int(ptr - start)
		s.curr_offset = offset + size
		return byte_slice(rawptr(ptr), size), nil
	case size <= len(s.data):
		start := uintptr(raw_data(s.data))
		ptr := align_forward_uintptr(start, uintptr(alignment))
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
	ptr, err := alloc_bytes_non_zeroed(size, alignment, a, loc)
	if err != nil {
		return ptr, err
	}
	if s.leaked_allocations == nil {
		s.leaked_allocations, err = make([dynamic][]byte, a)
	}
	append(&s.leaked_allocations, ptr)
	if logger := context.logger; logger.lowest_level <= .Warning {
		if logger.procedure != nil {
			logger.procedure(logger.data, .Warning, "mem.Scratch resorted to backup_allocator" , logger.options, loc)
		}
	}
	return ptr, err
}

scratch_free :: proc(s: ^Scratch, ptr: rawptr, loc := #caller_location) -> Allocator_Error {
	if s.data == nil {
		panic("Free on an uninitialized scratch allocator", loc)
	}
	if ptr == nil {
		return nil
	}
	start := uintptr(raw_data(s.data))
	end := start + uintptr(len(s.data))
	old_ptr := uintptr(ptr)
	if s.prev_allocation == ptr {
		s.curr_offset = int(uintptr(s.prev_allocation) - start)
		s.prev_allocation = nil
		return nil
	}
	if start <= old_ptr && old_ptr < end {
		// NOTE(bill): Cannot free this pointer but it is valid
		return nil
	}
	if len(s.leaked_allocations) != 0 {
		for data, i in s.leaked_allocations {
			ptr := raw_data(data)
			if ptr == ptr {
				free_bytes(data, s.backup_allocator, loc)
				ordered_remove(&s.leaked_allocations, i, loc)
				return nil
			}
		}
	}
	return .Invalid_Pointer
}

scratch_free_all :: proc(s: ^Scratch, loc := #caller_location) {
	if s.data == nil {
		panic("free_all called on an unitialized scratch allocator", loc)
	}
	s.curr_offset = 0
	s.prev_allocation = nil
	for ptr in s.leaked_allocations {
		free_bytes(ptr, s.backup_allocator, loc)
	}
	clear(&s.leaked_allocations)
}

scratch_resize :: proc(
	s: ^Scratch,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location
) -> ([]byte, Allocator_Error) {
	bytes, err := scratch_resize_non_zeroed(s, old_memory, old_size, size, alignment, loc)
	if bytes != nil && size > old_size {
		zero_slice(bytes[size:])
	}
	return bytes, err
}

scratch_resize_non_zeroed :: proc(
	s: ^Scratch,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		DEFAULT_BACKING_SIZE :: 4 * Megabyte
		if !(context.allocator.procedure != scratch_allocator_proc && context.allocator.data != s) {
			panic("cyclic initialization of the scratch allocator with itself", loc)
		}
		scratch_init(s, DEFAULT_BACKING_SIZE)
	}
	begin := uintptr(raw_data(s.data))
	end := begin + uintptr(len(s.data))
	// TODO(flysand): Doesn't handle old_memory == nil
	old_ptr := uintptr(old_memory)
	if begin <= old_ptr && old_ptr < end && old_ptr+uintptr(size) < end {
		s.curr_offset = int(old_ptr-begin)+size
		return byte_slice(old_memory, size), nil
	}
	data, err := scratch_alloc_non_zeroed(s, size, alignment, loc)
	if err != nil {
		return data, err
	}
	// TODO(flysand): OOB access on size < old_size.
	runtime.copy(data, byte_slice(old_memory, old_size))
	err = scratch_free(s, old_memory, loc)
	return data, err
}

scratch_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := (^Scratch)(allocator_data)
	size := size
	switch mode {
	case .Alloc:
		return scratch_alloc(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return scratch_alloc_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, scratch_free(s, old_memory, loc)
	case .Free_All:
		scratch_free_all(s, loc)
	case .Resize:
		return scratch_resize(s, old_memory, old_size, size, alignment, loc)
	case .Resize_Non_Zeroed:
		return scratch_resize_non_zeroed(s, old_memory, old_size, size, alignment, loc)
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



// Stack is a stack-like allocator which has a strict memory freeing order
Stack :: struct {
	data: []byte,
	prev_offset: int,
	curr_offset: int,
	peak_used: int,
}

Stack_Allocation_Header :: struct {
	prev_offset: int,
	padding:     int,
}

@(require_results)
stack_allocator :: proc(stack: ^Stack) -> Allocator {
	return Allocator{
		procedure = stack_allocator_proc,
		data = stack,
	}
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

stack_alloc :: proc(
	s: ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location
) -> ([]byte, Allocator_Error) {
	bytes, err := stack_alloc_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

stack_alloc_non_zeroed :: proc(
	s: ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		panic("Stack allocation on an uninitialized stack allocator", loc)
	}
	curr_addr := uintptr(raw_data(s.data)) + uintptr(s.curr_offset)
	padding := calc_padding_with_header(
		curr_addr,
		uintptr(alignment),
		size_of(Stack_Allocation_Header),
	)
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
	return byte_slice(rawptr(next_addr), size), nil
}

stack_free :: proc(
	s: ^Stack,
	old_memory: rawptr,
	loc := #caller_location,
) -> (Allocator_Error) {
	if s.data == nil {
		panic("Stack free on an uninitialized stack allocator", loc)
	}
	if old_memory == nil {
		return nil
	}
	start := uintptr(raw_data(s.data))
	end := start + uintptr(len(s.data))
	curr_addr := uintptr(old_memory)
	if !(start <= curr_addr && curr_addr < end) {
		panic("Out of bounds memory address passed to stack allocator (free)", loc)
	}
	if curr_addr >= start+uintptr(s.curr_offset) {
		// NOTE(bill): Allow double frees
		return nil
	}
	header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
	old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
	if old_offset != header.prev_offset {
		// panic("Out of order stack allocator free");
		return .Invalid_Pointer
	}
	s.curr_offset = old_offset
	s.prev_offset = header.prev_offset
	return nil
}

stack_free_all :: proc(s: ^Stack, loc := #caller_location) {
	if s.data == nil {
		panic("Stack free all on an uninitialized stack allocator", loc)
	}
	s.prev_offset = 0
	s.curr_offset = 0
}

stack_resize :: proc(
	s: ^Stack,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := stack_alloc_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		if old_memory == nil {
			zero_slice(bytes)
		} else if size > old_size {
			zero_slice(bytes[old_size:])
		}
	}
	return bytes, err
}

stack_resize_non_zeroed :: proc(
	s: ^Stack,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		panic("Stack free all on an uninitialized stack allocator", loc)
	}
	if old_memory == nil {
		return stack_alloc_non_zeroed(s, size, alignment, loc)
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
		data, err := stack_alloc_non_zeroed(s, size, alignment, loc)
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
}

stack_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size: int,
	alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := cast(^Stack)allocator_data
	if s.data == nil {
		return nil, .Invalid_Argument
	}
	switch mode {
	case .Alloc:
		return stack_alloc(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return stack_alloc_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, stack_free(s, old_memory, loc)
	case .Free_All:
		stack_free_all(s, loc)
	case .Resize:
		return stack_resize(s, old_memory, old_size, size, alignment, loc)
	case .Resize_Non_Zeroed:
		return stack_resize_non_zeroed(s, old_memory, old_size, size, alignment, loc)
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

small_stack_alloc :: proc(
	s: ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := small_stack_alloc_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

small_stack_alloc_non_zeroed :: proc(
	s: ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		return nil, .Invalid_Argument
	}
	alignment := alignment
	alignment := clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
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
	return byte_slice(rawptr(next_addr), size), nil
}

small_stack_free :: proc(
	s: ^Small_Stack,
	old_memory: rawptr,
	loc := #caller_location,
) -> Allocator_Error {
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
}

small_stack_free_all :: proc(s: ^Small_Stack) {
	s.offset = 0
}

small_stack_resize :: proc(
	s: ^Small_Stack,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := small_stack_resize_non_zeroed(s, old_memory, old_size, size, alignment, loc)
	if bytes != nil {
		if old_memory == nil {
			zero_slice(bytes)
		} else if size > old_size {
			zero_slice(bytes[old_size:])
		}
	}
	return bytes, err
}

small_stack_resize_non_zeroed :: proc(
	s: ^Small_Stack,
	old_memory: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if old_memory == nil {
		return small_stack_alloc_non_zeroed(s, size, align, loc)
	}
	if size == 0 {
		return nil, nil
	}
	alignment := alignment
	alignment := clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
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
	data, err := small_stack_alloc_non_zeroed(s, size, alignment, loc)
	if err == nil {
		runtime.copy(data, byte_slice(old_memory, old_size))
	}
	return data, err

}

small_stack_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
    size, alignment: int,
    old_memory: rawptr,
	old_size: int,
	location := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := cast(^Small_Stack)allocator_data
	if s.data == nil {
		return nil, .Invalid_Argument
	}
	switch mode {
	case .Alloc:
		return small_stack_alloc(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return small_stack_alloc_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, small_stack_free(s, old_memory, loc)
	case .Free_All:
		small_stack_free_all(s)
	case .Resize:
		return small_stack_resize(s, old_memory, old_size, size, alignment, loc)
	case .Resize_Non_Zeroed:
		return small_stack_resize_non_zeroed(s, old_memory, old_size, size, alignment, loc)
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

dynamic_pool_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size: int,
	alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
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

dynamic_pool_init :: proc(
	pool: ^Dynamic_Pool,
	block_allocator := context.allocator,
	array_allocator := context.allocator,
	block_size := DYNAMIC_POOL_BLOCK_SIZE_DEFAULT,
	out_band_size := DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT,
	alignment := 8,
) {
	pool.block_size = block_size
	pool.out_band_size = out_band_size
	pool.alignment = alignment
	pool.block_allocator = block_allocator
	pool.out_band_allocations.allocator = array_allocator
	pool.unused_blocks.allocator = array_allocator
	pool.used_blocks.allocator = array_allocator
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
			data, err = p.block_allocator.procedure(
				p.block_allocator.data,
				Allocator_Mode.Alloc,
				p.block_size,
				p.alignment,
				nil,
				0,
			)
			new_block = raw_data(data)
		}

		p.bytes_left    = p.block_size
		p.current_pos   = new_block
		p.current_block = new_block
		return
	}

	n := align_formula(bytes, p.alignment)
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

panic_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
    size, alignment: int,
    old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {

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

Buddy_Block :: struct #align(align_of(uint)) {
	size:    uint,
	is_free: bool,
}

@(require_results)
buddy_block_next :: proc(block: ^Buddy_Block) -> ^Buddy_Block {
	return (^Buddy_Block)(([^]byte)(block)[block.size:])
}

@(require_results)
buddy_block_split :: proc(block: ^Buddy_Block, size: uint) -> ^Buddy_Block {
	block := block
	if block != nil && size != 0 {
		// Recursive Split
		for size < block.size {
			sz := block.size >> 1
			block.size = sz
			block = buddy_block_next(block)
			block.size = sz
			block.is_free = true
		}
		if size <= block.size {
			return block
		}
	}
	// Block cannot fit the requested allocation size
	return nil
}

buddy_block_coalescence :: proc(head, tail: ^Buddy_Block) {
	for {
		// Keep looping until there are no more buddies to coalesce
		block := head
		buddy := buddy_block_next(block)

		no_coalescence := true
		for block < tail && buddy < tail { // make sure the buddies are within the range
			if block.is_free && buddy.is_free && block.size == buddy.size {
				// Coalesce buddies into one
				block.size <<= 1
				block = buddy_block_next(block)
				if block < tail {
					buddy = buddy_block_next(block)
					no_coalescence = false
				}
			} else if block.size < buddy.size {
				// The buddy block is split into smaller blocks
				block = buddy
				buddy = buddy_block_next(buddy)
			} else {
				block = buddy_block_next(buddy)
				if block < tail {
					// Leave the buddy block for the next iteration
					buddy = buddy_block_next(block)
				}
			}
		}

		if no_coalescence {
			return
		}
	}
}

@(require_results)
buddy_block_find_best :: proc(head, tail: ^Buddy_Block, size: uint) -> ^Buddy_Block {
	assert(size != 0)

	best_block: ^Buddy_Block
	block := head                    // left
	buddy := buddy_block_next(block) // right

	// The entire memory section between head and tail is free,
	// just call 'buddy_block_split' to get the allocation
	if buddy == tail && block.is_free {
		return buddy_block_split(block, size)
	}

	// Find the block which is the 'best_block' to requested allocation sized
	for block < tail && buddy < tail { // make sure the buddies are within the range
		// If both buddies are free, coalesce them together
		// NOTE: this is an optimization to reduce fragmentation
		//       this could be completely ignored
		if block.is_free && buddy.is_free && block.size == buddy.size {
			block.size <<= 1
			if size <= block.size && (best_block == nil || block.size <= best_block.size) {
				best_block = block
			}

			block = buddy_block_next(buddy)
			if block < tail {
				// Delay the buddy block for the next iteration
				buddy = buddy_block_next(block)
			}
			continue
		}


		if block.is_free && size <= block.size &&
		   (best_block == nil || block.size <= best_block.size) {
			best_block = block
		}

		if buddy.is_free && size <= buddy.size &&
		   (best_block == nil || buddy.size < best_block.size) {
			// If each buddy are the same size, then it makes more sense
			// to pick the buddy as it "bounces around" less
			best_block = buddy
		}

		if (block.size <= buddy.size) {
			block = buddy_block_next(buddy)
			if (block < tail) {
				// Delay the buddy block for the next iteration
				buddy = buddy_block_next(block)
			}
		} else {
			// Buddy was split into smaller blocks
			block = buddy
			buddy = buddy_block_next(buddy)
		}
	}

	if best_block != nil {
		// This will handle the case if the 'best_block' is also the perfect fit
		return buddy_block_split(best_block, size)
	}

	// Maybe out of memory
	return nil
}

Buddy_Allocator :: struct {
	head: ^Buddy_Block,
	tail: ^Buddy_Block,
	alignment: uint,
}

@(require_results)
buddy_allocator :: proc(b: ^Buddy_Allocator) -> Allocator {
	return Allocator{
		procedure = buddy_allocator_proc,
		data      = b,
	}
}

buddy_allocator_init :: proc(b: ^Buddy_Allocator, data: []byte, alignment: uint) {
	assert(data != nil)
	assert(is_power_of_two(uintptr(len(data))))
	assert(is_power_of_two(uintptr(alignment)))

	alignment := alignment
	if alignment < size_of(Buddy_Block) {
		alignment = size_of(Buddy_Block)
	}

	ptr := raw_data(data)
	assert(uintptr(ptr) % uintptr(alignment) == 0, "data is not aligned to minimum alignment")

	b.head = (^Buddy_Block)(ptr)

	b.head.size = len(data)
	b.head.is_free = true

	b.tail = buddy_block_next(b.head)

	b.alignment = alignment
}

@(require_results)
buddy_block_size_required :: proc(b: ^Buddy_Allocator, size: uint) -> uint {
	size := size
	actual_size := b.alignment
	size += size_of(Buddy_Block)
	size = align_forward_uint(size, b.alignment)

	for size > actual_size {
		actual_size <<= 1
	}

	return actual_size
}

@(require_results)
buddy_allocator_alloc :: proc(b: ^Buddy_Allocator, size: uint, zeroed: bool) -> ([]byte, Allocator_Error) {
	if size != 0 {
		actual_size := buddy_block_size_required(b, size)

		found := buddy_block_find_best(b.head, b.tail, actual_size)
		if found != nil {
			// Try to coalesce all the free buddy blocks and then search again
			buddy_block_coalescence(b.head, b.tail)
			found = buddy_block_find_best(b.head, b.tail, actual_size)
		}
		if found == nil {
			return nil, .Out_Of_Memory
		}
		found.is_free = false

		data := ([^]byte)(found)[b.alignment:][:size]
		if zeroed {
			zero_slice(data)
		}
		return data, nil
	}
	return nil, nil
}

buddy_allocator_free :: proc(b: ^Buddy_Allocator, ptr: rawptr) -> Allocator_Error {
	if ptr != nil {
		if !(b.head <= ptr && ptr <= b.tail) {
			return .Invalid_Pointer
		}

		block := (^Buddy_Block)(([^]byte)(ptr)[-b.alignment:])
		block.is_free = true

		buddy_block_coalescence(b.head, b.tail)
	}
	return nil
}

buddy_allocator_proc :: proc(
	allocator_data: rawptr, mode: Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {

	b := (^Buddy_Allocator)(allocator_data)

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return buddy_allocator_alloc(b, uint(size), mode == .Alloc)
	case .Resize:
		return default_resize_bytes_align(byte_slice(old_memory, old_size), size, alignment, buddy_allocator(b))
	case .Resize_Non_Zeroed:
		return default_resize_bytes_align_non_zeroed(byte_slice(old_memory, old_size), size, alignment, buddy_allocator(b))
	case .Free:
		return nil, buddy_allocator_free(b, old_memory)
	case .Free_All:

		alignment := b.alignment
		head := ([^]byte)(b.head)
		tail := ([^]byte)(b.tail)
		data := head[:ptr_sub(tail, head)]
		buddy_allocator_init(b, data, alignment)

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features, .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed, .Free, .Free_All, .Query_Info}
		}
		return nil, nil

	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			ptr := info.pointer
			if !(b.head <= ptr && ptr <= b.tail) {
				return nil, .Invalid_Pointer
			}

			block := (^Buddy_Block)(([^]byte)(ptr)[-b.alignment:])
			info.size = int(block.size)
			info.alignment = int(b.alignment)
			return byte_slice(info, size_of(info^)), nil
		}
		return nil, nil
	}

	return nil, nil
}
