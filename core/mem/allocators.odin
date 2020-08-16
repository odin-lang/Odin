package mem

import "intrinsics"
import "core:runtime"

nil_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	return nil;
}

nil_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	};
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
	a.data       = data;
	a.offset     = 0;
	a.peak_used  = 0;
	a.temp_count = 0;
}

arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

arena_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64, location := #caller_location) -> rawptr {
	arena := cast(^Arena)allocator_data;

	switch mode {
	case .Alloc:
		total_size := size + alignment;

		if arena.offset + total_size > len(arena.data) {
			return nil;
		}

		#no_bounds_check end := &arena.data[arena.offset];

		ptr := align_forward(end, uintptr(alignment));
		arena.offset += total_size;
		arena.peak_used = max(arena.peak_used, arena.offset);
		return zero(ptr, size);

	case .Free:
		// NOTE(bill): Free all at once
		// Use Arena_Temp_Memory if you want to free a block

	case .Free_All:
		arena.offset = 0;

	case .Resize:
		return default_resize_align(old_memory, old_size, size, alignment, arena_allocator(arena));

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free_All, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
}

begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
	tmp: Arena_Temp_Memory;
	tmp.arena = a;
	tmp.prev_offset = a.offset;
	a.temp_count += 1;
	return tmp;
}

end_arena_temp_memory :: proc(using tmp: Arena_Temp_Memory) {
	assert(arena.offset >= prev_offset);
	assert(arena.temp_count > 0);
	arena.offset = prev_offset;
	arena.temp_count -= 1;
}



Scratch_Allocator :: struct {
	data:     []byte,
	curr_offset: int,
	prev_offset: int,
	backup_allocator: Allocator,
	leaked_allocations: [dynamic]rawptr,
	default_to_default_allocator: bool,
}

scratch_allocator_init :: proc(scratch: ^Scratch_Allocator, data: []byte, backup_allocator := context.allocator) {
	scratch.data = data;
	scratch.curr_offset = 0;
	scratch.prev_offset = 0;
	scratch.backup_allocator = backup_allocator;
}

scratch_allocator_destroy :: proc(using scratch: ^Scratch_Allocator) {
	if scratch == nil {
		return;
	}
	for ptr in leaked_allocations {
		free(ptr, backup_allocator);
	}
	delete(leaked_allocations);
	delete(data, backup_allocator);
	scratch^ = {};
}

scratch_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {

	scratch := (^Scratch_Allocator)(allocator_data);

	if scratch.data == nil {
		DEFAULT_SCRATCH_BACKING_SIZE :: 1<<22;
		if !(context.allocator.procedure != scratch_allocator_proc &&
		     context.allocator.data != allocator_data) {
			panic("cyclic initialization of the scratch allocator with itself");
		}
		scratch_allocator_init(scratch, make([]byte, 1<<22));
	}

	switch mode {
	case .Alloc:
		switch {
		case scratch.curr_offset+size <= len(scratch.data):
			offset := align_forward_uintptr(uintptr(scratch.curr_offset), uintptr(alignment));
			ptr := &scratch.data[offset];
			zero(ptr, size);
			scratch.prev_offset = int(offset);
			scratch.curr_offset = int(offset) + size;
			return ptr;
		case size <= len(scratch.data):
			offset := align_forward_uintptr(uintptr(0), uintptr(alignment));
			ptr := &scratch.data[offset];
			zero(ptr, size);
			scratch.prev_offset = int(offset);
			scratch.curr_offset = int(offset) + size;
			return ptr;
		}
		// TODO(bill): Should leaks be notified about? Should probably use a logging system that is built into the context system
		a := scratch.backup_allocator;
		if a.procedure == nil {
			a = context.allocator;
			scratch.backup_allocator = a;
		}

		ptr := alloc(size, alignment, a, loc);
		if scratch.leaked_allocations == nil {
			scratch.leaked_allocations = make([dynamic]rawptr, a);
		}
		append(&scratch.leaked_allocations, ptr);

		return ptr;

	case .Free:
		last_ptr := rawptr(&scratch.data[scratch.prev_offset]);
		if old_memory == last_ptr {
			full_size := scratch.curr_offset - scratch.prev_offset;
			scratch.curr_offset = scratch.prev_offset;
			zero(last_ptr, full_size);
			return nil;
		}
		// NOTE(bill): It's scratch memory, don't worry about freeing

	case .Free_All:
		scratch.curr_offset = 0;
		scratch.prev_offset = 0;
		for ptr in scratch.leaked_allocations {
			free(ptr, scratch.backup_allocator);
		}
		clear(&scratch.leaked_allocations);

	case .Resize:
		last_ptr := rawptr(&scratch.data[scratch.prev_offset]);
		if old_memory == last_ptr && len(scratch.data)-scratch.prev_offset >= size {
			scratch.curr_offset = scratch.prev_offset+size;
			return old_memory;
		}
		return scratch_allocator_proc(allocator_data, Allocator_Mode.Alloc, size, alignment, old_memory, old_size, flags, loc);

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
}

scratch_allocator :: proc(scratch: ^Scratch_Allocator) -> Allocator {
	return Allocator{
		procedure = scratch_allocator_proc,
		data = scratch,
	};
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
	s.data = data;
	s.prev_offset = 0;
	s.curr_offset = 0;
	s.peak_used = 0;
}

stack_allocator :: proc(stack: ^Stack) -> Allocator {
	return Allocator{
		procedure = stack_allocator_proc,
		data = stack,
	};
}


stack_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64, location := #caller_location) -> rawptr {
	s := cast(^Stack)allocator_data;

	if s.data == nil {
		return nil;
	}

	raw_alloc :: proc(s: ^Stack, size, alignment: int) -> rawptr {
		curr_addr := uintptr(raw_data(s.data)) + uintptr(s.curr_offset);
		padding := calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Stack_Allocation_Header));
		if s.curr_offset + padding + size > len(s.data) {
			return nil;
		}
		s.prev_offset = s.curr_offset;
		s.curr_offset += padding;

		next_addr := curr_addr + uintptr(padding);
		header := (^Stack_Allocation_Header)(next_addr - size_of(Stack_Allocation_Header));
		header.padding = auto_cast padding;
		header.prev_offset = auto_cast s.prev_offset;

		s.curr_offset += size;

		s.peak_used = max(s.peak_used, s.curr_offset);

		return zero(rawptr(next_addr), size);
	}

	switch mode {
	case .Alloc:
		return raw_alloc(s, size, alignment);
	case .Free:
		if old_memory == nil {
			return nil;
		}
		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		curr_addr := uintptr(old_memory);

		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (free)");
		}

		if curr_addr >= start+uintptr(s.curr_offset) {
			// NOTE(bill): Allow double frees
			return nil;
		}

		header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header));
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)));

		if old_offset != int(header.prev_offset) {
			panic("Out of order stack allocator free");
		}

		s.curr_offset = int(old_offset);
		s.prev_offset = int(header.prev_offset);


	case .Free_All:
		s.prev_offset = 0;
		s.curr_offset = 0;

	case .Resize:
		if old_memory == nil {
			return raw_alloc(s, size, alignment);
		}
		if size == 0 {
			return nil;
		}

		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		curr_addr := uintptr(old_memory);
		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (resize)");
		}

		if curr_addr >= start+uintptr(s.curr_offset) {
			// NOTE(bill): Allow double frees
			return nil;
		}

		if old_size == size {
			return old_memory;
		}

		header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header));
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)));

		if old_offset != int(header.prev_offset) {
			ptr := raw_alloc(s, size, alignment);
			copy(ptr, old_memory, min(old_size, size));
			return ptr;
		}

		old_memory_size := uintptr(s.curr_offset) - (curr_addr - start);
		assert(old_memory_size == uintptr(old_size));

		diff := size - old_size;
		s.curr_offset += diff; // works for smaller sizes too
		if diff > 0 {
			zero(rawptr(curr_addr + uintptr(diff)), diff);
		}

		return old_memory;

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features};
		}
		return set;
	case .Query_Info:
		return nil;
	}

	return nil;
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
	s.data = data;
	s.offset = 0;
	s.peak_used = 0;
}

small_stack_allocator :: proc(stack: ^Small_Stack) -> Allocator {
	return Allocator{
		procedure = small_stack_allocator_proc,
		data = stack,
	};
}

small_stack_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                   size, alignment: int,
                                   old_memory: rawptr, old_size: int, flags: u64, location := #caller_location) -> rawptr {
	s := cast(^Small_Stack)allocator_data;

	if s.data == nil {
		return nil;
	}

	align := clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2);

	raw_alloc :: proc(s: ^Small_Stack, size, alignment: int) -> rawptr {
		curr_addr := uintptr(raw_data(s.data)) + uintptr(s.offset);
		padding := calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Small_Stack_Allocation_Header));
		if s.offset + padding + size > len(s.data) {
			return nil;
		}
		s.offset += padding;

		next_addr := curr_addr + uintptr(padding);
		header := (^Small_Stack_Allocation_Header)(next_addr - size_of(Small_Stack_Allocation_Header));
		header.padding = auto_cast padding;

		s.offset += size;

		s.peak_used = max(s.peak_used, s.offset);

		return zero(rawptr(next_addr), size);
	}

	switch mode {
	case .Alloc:
		return raw_alloc(s, size, align);
	case .Free:
		if old_memory == nil {
			return nil;
		}
		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		curr_addr := uintptr(old_memory);

		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (free)");
		}

		if curr_addr >= start+uintptr(s.offset) {
			// NOTE(bill): Allow double frees
			return nil;
		}

		header := (^Small_Stack_Allocation_Header)(curr_addr - size_of(Small_Stack_Allocation_Header));
		old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)));

		s.offset = int(old_offset);

	case .Free_All:
		s.offset = 0;

	case .Resize:
		if old_memory == nil {
			return raw_alloc(s, size, align);
		}
		if size == 0 {
			return nil;
		}

		start := uintptr(raw_data(s.data));
		end := start + uintptr(len(s.data));
		curr_addr := uintptr(old_memory);
		if !(start <= curr_addr && curr_addr < end) {
			panic("Out of bounds memory address passed to stack allocator (resize)");
		}

		if curr_addr >= start+uintptr(s.offset) {
			// NOTE(bill): Treat as a double free
			return nil;
		}

		if old_size == size {
			return old_memory;
		}

		ptr := raw_alloc(s, size, align);
		copy(ptr, old_memory, min(old_size, size));
		return ptr;

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
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


DYNAMIC_POOL_BLOCK_SIZE_DEFAULT       :: 65536;
DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT :: 6554;



dynamic_pool_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                                    size, alignment: int,
                                    old_memory: rawptr, old_size: int,
                                    flags: u64 = 0, loc := #caller_location) -> rawptr {
	pool := (^Dynamic_Pool)(allocator_data);

	switch mode {
	case .Alloc:
		return dynamic_pool_alloc(pool, size);
	case .Free:
		//
	case .Free_All:
		dynamic_pool_free_all(pool);
	case .Resize:
		if old_size >= size {
			return old_memory;
		}
		ptr := dynamic_pool_alloc(pool, size);
		copy(ptr, old_memory, old_size);
		return ptr;

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free_All, .Resize, .Query_Features, .Query_Info};
		}
		return set;

	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory);
		if info != nil && info.pointer != nil {
			info.size = pool.block_size;
			info.alignment = pool.alignment;
			return info;
		}
		return nil;
	}
	return nil;
}


dynamic_pool_allocator :: proc(pool: ^Dynamic_Pool) -> Allocator {
	return Allocator{
		procedure = dynamic_pool_allocator_proc,
		data = pool,
	};
}

dynamic_pool_init :: proc(pool: ^Dynamic_Pool,
                          block_allocator := context.allocator,
                          array_allocator := context.allocator,
                          block_size := DYNAMIC_POOL_BLOCK_SIZE_DEFAULT,
                          out_band_size := DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT,
                          alignment := 8) {
	pool.block_size      = block_size;
	pool.out_band_size   = out_band_size;
	pool.alignment       = alignment;
	pool.block_allocator = block_allocator;
	pool.out_band_allocations.allocator = array_allocator;
	pool.       unused_blocks.allocator = array_allocator;
	pool.         used_blocks.allocator = array_allocator;
}

dynamic_pool_destroy :: proc(using pool: ^Dynamic_Pool) {
	dynamic_pool_free_all(pool);
	delete(unused_blocks);
	delete(used_blocks);

	zero(pool, size_of(pool^));
}


dynamic_pool_alloc :: proc(using pool: ^Dynamic_Pool, bytes: int) -> rawptr {
	cycle_new_block :: proc(using pool: ^Dynamic_Pool) {
		if block_allocator.procedure == nil {
			panic("You must call pool_init on a Pool before using it");
		}

		if current_block != nil {
			append(&used_blocks, current_block);
		}

		new_block: rawptr;
		if len(unused_blocks) > 0 {
			new_block = pop(&unused_blocks);
		} else {
			new_block = block_allocator.procedure(block_allocator.data, Allocator_Mode.Alloc,
			                                      block_size, alignment,
			                                      nil, 0);
		}

		bytes_left = block_size;
		current_pos = new_block;
		current_block = new_block;
	}


	n := bytes;
	extra := alignment - (n % alignment);
	n += extra;
	if n >= out_band_size {
		assert(block_allocator.procedure != nil);
		memory := block_allocator.procedure(block_allocator.data, Allocator_Mode.Alloc,
			                                block_size, alignment,
			                                nil, 0);
		if memory != nil {
			append(&out_band_allocations, (^byte)(memory));
		}
		return memory;
	}

	if bytes_left < n {
		cycle_new_block(pool);
		if current_block == nil {
			return nil;
		}
	}

	memory := current_pos;
	current_pos = ptr_offset((^byte)(current_pos), n);
	bytes_left -= n;
	return memory;
}


dynamic_pool_reset :: proc(using pool: ^Dynamic_Pool) {
	if current_block != nil {
		append(&unused_blocks, current_block);
		current_block = nil;
	}

	for block in used_blocks {
		append(&unused_blocks, block);
	}
	clear(&used_blocks);

	for a in out_band_allocations {
		free(a, block_allocator);
	}
	clear(&out_band_allocations);
}

dynamic_pool_free_all :: proc(using pool: ^Dynamic_Pool) {
	dynamic_pool_reset(pool);

	for block in unused_blocks {
		free(block, block_allocator);
	}
	clear(&unused_blocks);
}


panic_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {

	switch mode {
	case .Alloc:
		if size > 0 {
			panic("mem: panic allocator, .Alloc called");
		}
	case .Resize:
		if size > 0 {
			panic("mem: panic allocator, .Resize called");
		}
	case .Free:
		if old_memory != nil {
			panic("mem: panic allocator, .Free called");
		}
	case .Free_All:
		panic("mem: panic allocator, .Free_All called");

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
}

panic_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = panic_allocator_proc,
		data = nil,
	};
}


alloca_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                              size, alignment: int,
                              old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	switch mode {
	case .Alloc:
		switch alignment {
		case:   return intrinsics.alloca(size, 2*align_of(uintptr));
		case 0: return intrinsics.alloca(size, 0);

		case 1:     return intrinsics.alloca(size, 1);
		case 2:     return intrinsics.alloca(size, 2);
		case 4:     return intrinsics.alloca(size, 4);
		case 8:     return intrinsics.alloca(size, 8);
		case 16:    return intrinsics.alloca(size, 16);
		case 32:    return intrinsics.alloca(size, 32);
		case 64:    return intrinsics.alloca(size, 64);
		case 128:   return intrinsics.alloca(size, 128);
		case 256:   return intrinsics.alloca(size, 256);
		case 512:   return intrinsics.alloca(size, 512);
		case 1024:  return intrinsics.alloca(size, 1024);
		case 2048:  return intrinsics.alloca(size, 2048);
		case 4096:  return intrinsics.alloca(size, 4096);
		case 8192:  return intrinsics.alloca(size, 8192);
		case 16384: return intrinsics.alloca(size, 16384);
		case 32768: return intrinsics.alloca(size, 32768);
		case 65536: return intrinsics.alloca(size, 65536);
		}
	case .Resize:
		return default_resize_align(old_memory, old_size, size, alignment, alloca_allocator());

	case .Free:
		// Do nothing
	case .Free_All:
		// Do nothing

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}
	return nil;
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
	location: runtime.Source_Code_Location,
}
Tracking_Allocator :: struct {
	backing:           Allocator,
	allocation_map:    map[rawptr]Tracking_Allocator_Entry,
	clear_on_free_all: bool,
}

tracking_allocator_init :: proc(t: ^Tracking_Allocator, backing_allocator: Allocator, allocation_map_allocator := context.allocator) {
	t.backing = backing_allocator;
	t.allocation_map.allocator = allocation_map_allocator;
}

tracking_allocator_destroy :: proc(t: ^Tracking_Allocator) {
	delete(t.allocation_map);
}

tracking_allocator :: proc(data: ^Tracking_Allocator) -> Allocator {
	return Allocator{
		data = data,
		procedure = tracking_allocator_proc,
	};
}

tracking_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	data := (^Tracking_Allocator)(allocator_data);
	if mode == .Query_Info {
		info := (^Allocator_Query_Info)(old_memory);
		if info != nil && info.pointer != nil {
			if entry, ok := data.allocation_map[info.pointer]; ok {
				info.size = entry.size;
				info.alignment = entry.alignment;
				return info;
			}
			info.pointer = nil;
		}

		return nil;
	}

	result := data.backing.procedure(data.backing.data, mode, size, alignment, old_memory, old_size, flags, loc);

	if data.allocation_map.allocator.procedure == nil {
		data.allocation_map.allocator = context.allocator;
	}

	switch mode {
	case .Alloc:
		data.allocation_map[result] = Tracking_Allocator_Entry{
			memory = result,
			size = size,
			alignment = alignment,
			location = loc,
		};
	case .Free:
		delete_key(&data.allocation_map, old_memory);
	case .Resize:
		if old_memory != result {
			delete_key(&data.allocation_map, old_memory);
		}
		data.allocation_map[result] = Tracking_Allocator_Entry{
			memory = result,
			size = size,
			alignment = alignment,
			location = loc,
		};

	case .Free_All:
		if data.clear_on_free_all {
			clear_map(&data.allocation_map);
		}

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Free_All, .Resize, .Query_Features, .Query_Info};
		}
		return set;

	case .Query_Info:
		unreachable();
	}

	return result;
}
