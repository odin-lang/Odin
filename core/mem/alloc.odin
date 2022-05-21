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
	64 * 1024 when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64 else
	16 * 1024 when ODIN_OS == .darwin && ODIN_ARCH == .arm64 else
	4 * 1024

alloc :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if size == 0 {
		return nil
	}
	if allocator.procedure == nil {
		return nil
	}
	data, err := allocator.procedure(allocator.data, Allocator_Mode.Alloc, size, alignment, nil, 0, loc)
	_ = err
	return raw_data(data)
}

alloc_bytes :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size == 0 {
		return nil, nil
	}
	if allocator.procedure == nil {
		return nil, nil
	}
	return allocator.procedure(allocator.data, Allocator_Mode.Alloc, size, alignment, nil, 0, loc)
}

free :: proc(ptr: rawptr, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if ptr == nil {
		return nil
	}
	if allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, 0, loc)
	return err
}

free_bytes :: proc(bytes: []byte, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if bytes == nil {
		return nil
	}
	if allocator.procedure == nil {
		return nil
	}
	_, err := allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, raw_data(bytes), len(bytes), loc)
	return err
}

free_all :: proc(allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	if allocator.procedure != nil {
		_, err := allocator.procedure(allocator.data, Allocator_Mode.Free_All, 0, 0, nil, 0, loc)
		return err
	}
	return nil
}

resize :: proc(ptr: rawptr, old_size, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if allocator.procedure == nil {
		return nil
	}
	if new_size == 0 {
		if ptr != nil {
			allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, old_size, loc)
		}
		return nil
	} else if ptr == nil {
		_, err := allocator.procedure(allocator.data, Allocator_Mode.Alloc, new_size, alignment, nil, 0, loc)
		_ = err
		return nil
	}
	data, err := allocator.procedure(allocator.data, Allocator_Mode.Resize, new_size, alignment, ptr, old_size, loc)
	if err == .Mode_Not_Implemented {
		data, err = allocator.procedure(allocator.data, Allocator_Mode.Alloc, new_size, alignment, nil, 0, loc)
		if err != nil {
			return nil
		}
		runtime.copy(data, byte_slice(ptr, old_size))
		_, err = allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, old_size, loc)
		return raw_data(data)
	}
	return raw_data(data)
}

resize_bytes :: proc(old_data: []byte, new_size: int, alignment: int = DEFAULT_ALIGNMENT, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if allocator.procedure == nil {
		return nil, nil
	}
	ptr := raw_data(old_data)
	old_size := len(old_data)
	if new_size == 0 {
		if ptr != nil {
			_, err := allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, old_size, loc)
			return nil, err
		}
		return nil, nil
	} else if ptr == nil {
		return allocator.procedure(allocator.data, Allocator_Mode.Alloc, new_size, alignment, nil, 0, loc)
	}
	data, err := allocator.procedure(allocator.data, Allocator_Mode.Resize, new_size, alignment, ptr, old_size, loc)
	if err == .Mode_Not_Implemented {
		data, err = allocator.procedure(allocator.data, Allocator_Mode.Alloc, new_size, alignment, nil, 0, loc)
		if err != nil {
			return data, err
		}
		runtime.copy(data, old_data)
		_, err = allocator.procedure(allocator.data, Allocator_Mode.Free, 0, 0, ptr, old_size, loc)
	}
	return data, err
}

query_features :: proc(allocator: Allocator, loc := #caller_location) -> (set: Allocator_Mode_Set) {
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, Allocator_Mode.Query_Features, 0, 0, &set, 0, loc)
		return set
	}
	return nil
}

query_info :: proc(pointer: rawptr, allocator: Allocator, loc := #caller_location) -> (props: Allocator_Query_Info) {
	props.pointer = pointer
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, Allocator_Mode.Query_Info, 0, 0, &props, 0, loc)
	}
	return
}



delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) {
	free(raw_data(str), allocator, loc)
}
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) {
	free((^byte)(str), allocator, loc)
}
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) {
	free(raw_data(array), array.allocator, loc)
}
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) {
	free(raw_data(array), allocator, loc)
}
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) {
	raw := transmute(Raw_Map)m
	delete_slice(raw.hashes, raw.entries.allocator, loc)
	free(raw.entries.data, raw.entries.allocator, loc)
}


delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
}


new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> (^T, Allocator_Error) {
	return new_aligned(T, align_of(T), allocator, loc)
}
new_aligned :: proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	data := alloc_bytes(size_of(T), alignment, allocator, loc) or_return
	t = (^T)(raw_data(data))
	return
}
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	backing := alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return
	t = (^T)(raw_data(backing))
	if t != nil {
		t^ = data
		return t, nil
	}
	return nil, .Out_Of_Memory
}

DEFAULT_RESERVE_CAPACITY :: 16

make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (slice: T, err: Allocator_Error) {
	runtime.make_slice_error_loc(loc, len)
	data := alloc_bytes(size_of(E)*len, alignment, allocator, loc) or_return
	if data == nil && size_of(E) != 0 {
		return
	}
	slice = transmute(T)Raw_Slice{raw_data(data), len}
	return
}
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_aligned(T, len, align_of(E), allocator, loc)
}
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_dynamic_array_len_cap(T, 0, DEFAULT_RESERVE_CAPACITY, allocator, loc)
}
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
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
make_map :: proc($T: typeid/map[$K]$E, #any_int cap: int = DEFAULT_RESERVE_CAPACITY, allocator := context.allocator, loc := #caller_location) -> T {
	runtime.make_map_expr_error_loc(loc, cap)
	context.allocator = allocator

	m: T
	reserve_map(&m, cap)
	return m
}
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



default_resize_align :: proc(old_memory: rawptr, old_size, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> rawptr {
	if old_memory == nil {
		return alloc(new_size, alignment, allocator, loc)
	}

	if new_size == 0 {
		free(old_memory, allocator, loc)
		return nil
	}

	if new_size == old_size {
		return old_memory
	}

	new_memory := alloc(new_size, alignment, allocator, loc)
	if new_memory == nil {
		return nil
	}

	copy(new_memory, old_memory, min(old_size, new_size))
	free(old_memory, allocator, loc)
	return new_memory
}
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
