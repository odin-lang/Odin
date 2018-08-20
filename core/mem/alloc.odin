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



alloc_with_allocator :: inline proc(a: Allocator, size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	return a.procedure(a.data, Allocator_Mode.Alloc, size, alignment, nil, 0, 0, loc);
}
alloc :: inline proc(size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	return alloc_with_allocator(context.allocator, size, alignment, loc);
}

free_ptr_with_allocator :: inline proc(a: Allocator, ptr: rawptr, loc := #caller_location) {
	if ptr == nil do return;
	if a.procedure == nil do return;
	a.procedure(a.data, Allocator_Mode.Free, 0, 0, ptr, 0, 0, loc);
}
free :: inline proc(ptr: rawptr, loc := #caller_location) do free_ptr_with_allocator(context.allocator, ptr, loc);

free_all_with_allocator :: inline proc(a: Allocator, loc := #caller_location) {
	a.procedure(a.data, Allocator_Mode.Free_All, 0, 0, nil, 0, 0, loc);
}
free_all :: inline proc(loc := #caller_location) {
	free_all_with_allocator(context.allocator, loc);
}

resize_with_allocator :: inline proc(a: Allocator, ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	return a.procedure(a.data, Allocator_Mode.Resize, new_size, alignment, ptr, old_size, 0, loc);
}
resize :: inline proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, loc := #caller_location) -> rawptr {
	return resize_with_allocator(context.allocator, ptr, old_size, new_size, alignment, loc);
}


delete_string :: proc(str: string, loc := #caller_location) {
	free(raw_data(str), loc);
}
delete_cstring :: proc(str: cstring, loc := #caller_location) {
	free((^byte)(str), loc);
}
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) {
	free(raw_data(array), loc);
}
delete_slice :: proc(array: $T/[]$E, loc := #caller_location) {
	free(raw_data(array), loc);
}
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) {
	raw := transmute(Raw_Map)m;
	delete_dynamic_array(raw.hashes, loc);
	free(raw.entries.data, loc);
}


delete :: proc[
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
];


new :: inline proc(T: type, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), align_of(T), loc));
	ptr^ = T{};
	return ptr;
}
new_clone :: inline proc(data: $T, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), align_of(T), loc));
	ptr^ = data;
	return ptr;
}

new_with_allocator :: inline proc(a: Allocator, T: type, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc_with_allocator(a, size_of(T), align_of(T), loc));
	ptr^ = T{};
	return ptr;
}

new_clone_with_allocator :: inline proc(a: Allocator, data: $T, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc_with_allocator(a, size_of(T), align_of(T), loc));
	ptr^ = data;
	return ptr;
}


make_slice :: proc(T: type/[]$E, auto_cast len: int, loc := #caller_location) -> T {
	runtime.make_slice_error_loc(loc, len);
	if len == 0 {
		return nil;
	}
	data := alloc(size_of(E)*len, align_of(E));
	s := Raw_Slice{data, len};
	return transmute(T)s;
}
make_dynamic_array :: proc(T: type/[dynamic]$E, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, 0, 16, loc);
}
make_dynamic_array_len :: proc(T: type/[dynamic]$E, auto_cast len: int, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, len, len, loc);
}
make_dynamic_array_len_cap :: proc(T: type/[dynamic]$E, auto_cast len: int, auto_cast cap: int, loc := #caller_location) -> T {
	runtime.make_dynamic_array_error_loc(loc, len, cap);
	data: rawptr;
	if cap > 0 do data = alloc(size_of(E)*cap, align_of(E));
	s := Raw_Dynamic_Array{data, len, cap, context.allocator};
	return transmute(T)s;
}
make_map :: proc(T: type/map[$K]$E, auto_cast cap: int = 16, loc := #caller_location) -> T {
	runtime.make_map_expr_error_loc(loc, cap);
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



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int, loc := #caller_location) -> rawptr {
	if old_memory == nil do return alloc(new_size, alignment, loc);

	if new_size == 0 {
		free(old_memory, loc);
		return nil;
	}

	if new_size == old_size do return old_memory;

	new_memory := alloc(new_size, alignment, loc);
	if new_memory == nil do return nil;

	copy(new_memory, old_memory, min(old_size, new_size));;
	free(old_memory, loc);
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
		free_ptr_with_allocator(block_allocator, a);
	}
	clear(&out_band_allocations);
}

pool_free_all :: proc(using pool: ^Pool) {
	pool_reset(pool);

	for block in unused_blocks {
		free_ptr_with_allocator(block_allocator, block);
	}
	clear(&unused_blocks);
}
