package mem

import "core:runtime"

DEFAULT_ALIGNMENT :: 2*align_of(rawptr);

Allocator_Mode :: enum byte {
	Alloc,
	Free,
	Free_All,
	Resize,
}

Allocator_Proc :: #type proc(allocator_data: rawptr, mode: Allocator_Mode,
	                         size, alignment: int,
	                         old_memory: rawptr, old_size: int, flags: u64 = 0, location := #caller_location) -> rawptr;


Allocator :: struct {
	procedure: Allocator_Proc,
	data:      rawptr,
}



alloc :: inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if size == 0 do return nil;
	if allocator.procedure == nil do return nil;
	return allocator.procedure(allocator.data, Allocator_Mode.Alloc, size, alignment, nil, 0, 0, loc);
}

free :: inline proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) {
	if ptr == nil do return;
	if allocator.procedure == nil do return;
	allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, 0, 0, loc);
}

free_all :: inline proc(allocator := context.allocator, loc := #caller_location) {
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, Allocator_Mode.Free_All, 0, 0, nil, 0, 0, loc);
	}
}

resize :: inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if allocator.procedure == nil {
		return nil;
	}
	if new_size == 0 {
		free(ptr, allocator, loc);
		return nil;
	} else if ptr == nil {
		return allocator.procedure(allocator.data, Allocator_Mode.Alloc, new_size, alignment, nil, 0, 0, loc);
	}
	return allocator.procedure(allocator.data, Allocator_Mode.Resize, new_size, alignment, ptr, old_size, 0, loc);
}


delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) {
	free(raw_data(str), allocator, loc);
}
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) {
	free((^byte)(str), allocator, loc);
}
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) {
	free(raw_data(array), array.allocator, loc);
}
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) {
	free(raw_data(array), allocator, loc);
}
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) {
	raw := transmute(Raw_Map)m;
	delete_slice(raw.hashes);
	free(raw.entries.data, raw.entries.allocator, loc);
}


delete :: proc[
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
];


new :: inline proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), align_of(T), allocator, loc));
	if ptr != nil do ptr^ = T{};
	return ptr;
}
new_clone :: inline proc(data: $T, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), align_of(T), allocator, loc));
	if ptr != nil do ptr^ = data;
	return ptr;
}


make_slice :: proc($T: typeid/[]$E, auto_cast len: int, allocator := context.allocator, loc := #caller_location) -> T {
	runtime.make_slice_error_loc(loc, len);
	data := alloc(size_of(E)*len, align_of(E), allocator, loc);
	s := Raw_Slice{data, len};
	return transmute(T)s;
}
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, 0, 16, allocator, loc);
}
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, auto_cast len: int, allocator := context.allocator, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc);
}
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, auto_cast len: int, auto_cast cap: int, allocator := context.allocator, loc := #caller_location) -> T {
	runtime.make_dynamic_array_error_loc(loc, len, cap);
	data := alloc(size_of(E)*cap, align_of(E), allocator, loc);
	s := Raw_Dynamic_Array{data, len, cap, allocator};
	return transmute(T)s;
}
make_map :: proc($T: typeid/map[$K]$E, auto_cast cap: int = 16, allocator := context.allocator, loc := #caller_location) -> T {
	runtime.make_map_expr_error_loc(loc, cap);
	context.allocator = allocator;

	m: T;
	reserve_map(&m, cap);
	return m;
}

make :: proc[
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
];



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if old_memory == nil do return alloc(new_size, alignment, allocator, loc);

	if new_size == 0 {
		free(old_memory, allocator, loc);
		return nil;
	}

	if new_size == old_size do return old_memory;

	new_memory := alloc(new_size, alignment, allocator, loc);
	if new_memory == nil do return nil;

	copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory, allocator, loc);
	return new_memory;
}


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

Scratch_Allocator :: struct {
	data:     []byte,
	curr_offset: int,
	prev_offset: int,
	backup_allocator: Allocator,
	leaked_allocations: [dynamic]rawptr,
}

scratch_allocator_init :: proc(scratch: ^Scratch_Allocator, data: []byte, backup_allocator := context.allocator) {
	scratch.data = data;
	scratch.curr_offset = 0;
	scratch.prev_offset = 0;
	scratch.backup_allocator = backup_allocator;
}

scratch_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {

	scratch := (^Scratch_Allocator)(allocator_data);

	if scratch.data == nil {
		DEFAULT_SCRATCH_BACKING_SIZE :: 1<<22;
		scratch_allocator_init(scratch, make([]byte, 1<<22));
	}

	switch mode {
	case Allocator_Mode.Alloc:
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

	case Allocator_Mode.Free:
		last_ptr := rawptr(&scratch.data[scratch.prev_offset]);
		if old_memory == last_ptr {
			full_size := scratch.curr_offset - scratch.prev_offset;
			scratch.curr_offset = scratch.prev_offset;
			zero(last_ptr, full_size);
			return nil;
		}
		// NOTE(bill): It's scratch memory, don't worry about freeing

	case Allocator_Mode.Free_All:
		scratch.curr_offset = 0;
		scratch.prev_offset = 0;
		for ptr in scratch.leaked_allocations {
			free(ptr, scratch.backup_allocator);
		}
		clear(&scratch.leaked_allocations);

	case Allocator_Mode.Resize:
		last_ptr := rawptr(&scratch.data[scratch.prev_offset]);
		if old_memory == last_ptr && len(scratch.data)-scratch.prev_offset >= size {
			scratch.curr_offset = scratch.prev_offset+size;
			return old_memory;
		}
		return scratch_allocator_proc(allocator_data, Allocator_Mode.Alloc, size, alignment, old_memory, old_size, flags, loc);
	}

	return nil;
}

scratch_allocator :: proc(scratch: ^Scratch_Allocator) -> Allocator {
	return Allocator{
		procedure = scratch_allocator_proc,
		data = scratch,
	};
}




Pool :: struct {
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


POOL_BLOCK_SIZE_DEFAULT       :: 65536;
POOL_OUT_OF_BAND_SIZE_DEFAULT :: 6554;



pool_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	pool := (^Pool)(allocator_data);

	switch mode {
	case Allocator_Mode.Alloc:
		return pool_alloc(pool, size);
	case Allocator_Mode.Free:
		panic("Allocator_Mode.Free is not supported for a pool");
	case Allocator_Mode.Free_All:
		pool_free_all(pool);
	case Allocator_Mode.Resize:
		panic("Allocator_Mode.Resize is not supported for a pool");
		if old_size >= size {
			return old_memory;
		}
		ptr := pool_alloc(pool, size);
		copy(ptr, old_memory, old_size);
		return ptr;
	}
	return nil;
}


pool_allocator :: proc(pool: ^Pool) -> Allocator {
	return Allocator{
		procedure = pool_allocator_proc,
		data = pool,
	};
}

pool_init :: proc(pool: ^Pool,
                  block_allocator := Allocator{} , array_allocator := Allocator{},
                  block_size := POOL_BLOCK_SIZE_DEFAULT, out_band_size := POOL_OUT_OF_BAND_SIZE_DEFAULT,
                  alignment := 8) {
	pool.block_size = block_size;
	pool.out_band_size = out_band_size;
	pool.alignment = alignment;

	if block_allocator.procedure == nil {
		block_allocator = context.allocator;
	}
	if array_allocator.procedure == nil {
		array_allocator = context.allocator;
	}

	pool.block_allocator = block_allocator;

	pool.out_band_allocations.allocator = array_allocator;
	pool.       unused_blocks.allocator = array_allocator;
	pool.         used_blocks.allocator = array_allocator;
}

pool_destroy :: proc(using pool: ^Pool) {
	pool_free_all(pool);
	delete(unused_blocks);
	delete(used_blocks);

	zero(pool, size_of(pool^));
}


pool_alloc :: proc(using pool: ^Pool, bytes: int) -> rawptr {
	cycle_new_block :: proc(using pool: ^Pool) {
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


	extra := alignment - (bytes % alignment);
	bytes += extra;
	if bytes >= out_band_size {
		assert(block_allocator.procedure != nil);
		memory := block_allocator.procedure(block_allocator.data, Allocator_Mode.Alloc,
			                                block_size, alignment,
			                                nil, 0);
		if memory != nil {
			append(&out_band_allocations, (^byte)(memory));
		}
		return memory;
	}

	if bytes_left < bytes {
		cycle_new_block(pool);
		if current_block == nil {
			return nil;
		}
	}

	memory := current_pos;
	current_pos = ptr_offset((^byte)(current_pos), bytes);
	bytes_left -= bytes;
	return memory;
}


pool_reset :: proc(using pool: ^Pool) {
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

pool_free_all :: proc(using pool: ^Pool) {
	pool_reset(pool);

	for block in unused_blocks {
		free(block, block_allocator);
	}
	clear(&unused_blocks);
}
