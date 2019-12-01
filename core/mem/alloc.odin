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


delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
};


new :: inline proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> ^T {
	return new_aligned(T, align_of(T), allocator, loc);
}
new_aligned :: inline proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), alignment, allocator, loc));
	if ptr != nil do ptr^ = T{};
	return ptr;
}
new_clone :: inline proc(data: $T, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(alloc(size_of(T), align_of(T), allocator, loc));
	if ptr != nil do ptr^ = data;
	return ptr;
}


make_slice :: inline proc($T: typeid/[]$E, auto_cast len: int, allocator := context.allocator, loc := #caller_location) -> T {
	return make_aligned(T, len, align_of(E), allocator, loc);
}
make_aligned :: proc($T: typeid/[]$E, auto_cast len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> T {
	runtime.make_slice_error_loc(loc, len);
	data := alloc(size_of(E)*len, alignment, allocator, loc);
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

make :: proc{
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
};



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

