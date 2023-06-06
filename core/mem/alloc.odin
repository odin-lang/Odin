package mem

import "core:runtime"

// NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.
Allocator_Mode :: runtime.Allocator_Mode
/*
Allocator_Mode :: enum byte {
	Alloc,
	Free,
	Free_All,
	Resize,
	Query_Features,
}
*/

Allocator_Mode_Set :: runtime.Allocator_Mode_Set
/*
Allocator_Mode_Set :: distinct bit_set[Allocator_Mode];
*/

Allocator_Query_Info :: runtime.Allocator_Query_Info
/*
Allocator_Query_Info :: struct {
	pointer:   rawptr,
	size:      Maybe(int),
	alignment: Maybe(int),
}
*/

Allocator_Error :: runtime.Allocator_Error
/*
Allocator_Error :: enum byte {
	None                 = 0,
	Out_Of_Memory        = 1,
	Invalid_Pointer      = 2,
	Invalid_Argument     = 3,
	Mode_Not_Implemented = 4,
}
*/
Allocator_Proc :: runtime.Allocator_Proc
/*
Allocator_Proc :: #type proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, location: Source_Code_Location = #caller_location) -> ([]byte, Allocator_Error);
*/

Allocator :: runtime.Allocator
/*
Allocator :: struct {
	procedure: Allocator_Proc,
	data:      rawptr,
}
*/

DEFAULT_ALIGNMENT :: 2*align_of(rawptr)

DEFAULT_PAGE_SIZE ::
	64 * 1024 when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 else
	16 * 1024 when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 else
	4 * 1024

@(require_results)
alloc :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (rawptr, Allocator_Error) {
	data, err := runtime.mem_alloc(size, alignment, allocator, loc)
	return raw_data(data), err
}

@(require_results)
alloc_bytes :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return runtime.mem_alloc(size, alignment, allocator, loc)
}

@(require_results)
alloc_bytes_non_zeroed :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return runtime.mem_alloc_non_zeroed(size, alignment, allocator, loc)
}

free :: proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.mem_free(ptr, allocator, loc)
}

free_with_size :: proc(ptr: rawptr, byte_count: int, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if ptr == nil || allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, .Free, 0, 0, ptr, byte_count, loc)
	return err
}

free_bytes :: proc(bytes: []byte, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.mem_free_bytes(bytes, allocator, loc)
}

free_all :: proc(allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.mem_free_all(allocator, loc)
}

@(require_results)
resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> (rawptr, Allocator_Error) {
	data, err := runtime.mem_resize(ptr, old_size, new_size, alignment, allocator, loc)
	return raw_data(data), err
}

@(require_results)
resize_bytes :: proc(old_data: []byte, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return runtime.mem_resize(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}

@(require_results)
query_features :: proc(allocator: Allocator, loc := #caller_location) -> (set: Allocator_Mode_Set) {
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, .Query_Features, 0, 0, &set, 0, loc)
		return set
	}
	return nil
}

@(require_results)
query_info :: proc(pointer: rawptr, allocator: Allocator, loc := #caller_location) -> (props: Allocator_Query_Info) {
	props.pointer = pointer
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, .Query_Info, 0, 0, &props, 0, loc)
	}
	return
}



delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return free_with_size(raw_data(str), len(str), allocator, loc)
}
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return free((^byte)(str), allocator, loc)
}
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	return free_with_size(raw_data(array), cap(array)*size_of(E), array.allocator, loc)
}
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return free_with_size(raw_data(array), len(array)*size_of(E), allocator, loc)
}
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
	return runtime.map_free_dynamic(transmute(Raw_Map)m, runtime.map_info(T), loc)
}


delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
}


@(require_results)
new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> (^T, Allocator_Error) {
	return new_aligned(T, align_of(T), allocator, loc)
}
@(require_results)
new_aligned :: proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	data := alloc_bytes(size_of(T), alignment, allocator, loc) or_return
	t = (^T)(raw_data(data))
	return
}
@(require_results)
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	backing := alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return
	t = (^T)(raw_data(backing))
	if t != nil {
		t^ = data
		return t, nil
	}
	return nil, .Out_Of_Memory
}

@(require_results)
make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (slice: T, err: Allocator_Error) {
	runtime.make_slice_error_loc(loc, len)
	data := alloc_bytes(size_of(E)*len, alignment, allocator, loc) or_return
	if data == nil && size_of(E) != 0 {
		return
	}
	slice = transmute(T)Raw_Slice{raw_data(data), len}
	return
}
@(require_results)
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_aligned(T, len, align_of(E), allocator, loc)
}
@(require_results)
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_dynamic_array_len_cap(T, 0, 16, allocator, loc)
}
@(require_results)
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
@(require_results)
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, #any_int len: int, #any_int cap: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) {
	runtime.make_dynamic_array_error_loc(loc, len, cap)
	data := alloc_bytes(size_of(E)*cap, align_of(E), allocator, loc) or_return
	s := Raw_Dynamic_Array{raw_data(data), len, cap, allocator}
	if data == nil && size_of(E) != 0 {
		s.len, s.cap = 0, 0
	}
	array = transmute(T)s
	return
}
@(require_results)
make_map :: proc($T: typeid/map[$K]$E, #any_int cap: int = 1<<runtime.MAP_MIN_LOG2_CAPACITY, allocator := context.allocator, loc := #caller_location) -> (m: T, err: Allocator_Error) {
	runtime.make_map_expr_error_loc(loc, cap)
	context.allocator = allocator

	err = reserve_map(&m, cap, loc)
	return
}
@(require_results)
make_multi_pointer :: proc($T: typeid/[^]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) {
	runtime.make_slice_error_loc(loc, len)
	data := alloc_bytes(size_of(E)*len, align_of(E), allocator, loc) or_return
	if data == nil && size_of(E) != 0 {
		return
	}
	mp = cast(T)raw_data(data)
	return
}

make :: proc{
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
}


@(require_results)
default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> (res: rawptr, err: Allocator_Error) {
	data: []byte
	data, err = default_resize_bytes_align(([^]byte)(old_memory)[:old_size], new_size, alignment, allocator, loc)
	res = raw_data(data)
	return
}
@(require_results)
default_resize_bytes_align :: proc(old_data: []byte, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if old_memory == nil {
		return alloc_bytes(new_size, alignment, allocator, loc)
	}

	if new_size == 0 {
		err := free_bytes(old_data, allocator, loc)
		return nil, err
	}

	if new_size == old_size {
		return old_data, .None
	}

	new_memory, err := alloc_bytes(new_size, alignment, allocator, loc)
	if new_memory == nil || err != nil {
		return nil, err
	}

	runtime.copy(new_memory, old_data)
	free_bytes(old_data, allocator, loc)
	return new_memory, err
}
