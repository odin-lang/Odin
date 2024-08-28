package mem

import "base:runtime"

// NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.
Allocator_Mode :: runtime.Allocator_Mode
/*
Allocator_Mode :: enum byte {
	Alloc,
	Free,
	Free_All,
	Resize,
	Query_Features,
	Alloc_Non_Zeroed,
	Resize_Non_Zeroed,
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
	return runtime.mem_free_with_size(ptr, byte_count, allocator, loc)
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
	return runtime.delete_string(str, allocator, loc)
}
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.delete_cstring(str, allocator, loc)
}
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	return runtime.delete_dynamic_array(array, loc)
}
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.delete_slice(array, allocator, loc)
}
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
	return runtime.delete_map(m, loc)
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
	return runtime.new_aligned(T, alignment, allocator, loc)
}
@(require_results)
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	return runtime.new_clone(data, allocator, loc)
}

@(require_results)
make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (slice: T, err: Allocator_Error) {
	return runtime.make_aligned(T, len, alignment, allocator, loc)
}
@(require_results)
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return runtime.make_slice(T, len, allocator, loc)
}
@(require_results)
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return runtime.make_dynamic_array(T, allocator, loc)
}
@(require_results)
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) {
	return runtime.make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
@(require_results)
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, #any_int len: int, #any_int cap: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) {
	return runtime.make_dynamic_array_len_cap(T, len, cap, allocator, loc)
}
@(require_results)
make_map :: proc($T: typeid/map[$K]$E, #any_int cap: int = 1<<runtime.MAP_MIN_LOG2_CAPACITY, allocator := context.allocator, loc := #caller_location) -> (m: T, err: Allocator_Error) {
	return runtime.make_map(T, cap, allocator, loc)
}
@(require_results)
make_multi_pointer :: proc($T: typeid/[^]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) {
	return runtime.make_multi_pointer(T, len, allocator, loc)
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
default_resize_bytes_align_non_zeroed :: proc(old_data: []byte, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return _default_resize_bytes_align(old_data, new_size, alignment, false, allocator, loc)
}
@(require_results)
default_resize_bytes_align :: proc(old_data: []byte, new_size, alignment: int, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	return _default_resize_bytes_align(old_data, new_size, alignment, true, allocator, loc)
}

@(require_results)
_default_resize_bytes_align :: #force_inline proc(old_data: []byte, new_size, alignment: int, should_zero: bool, allocator := context.allocator, loc := #caller_location) -> ([]byte, Allocator_Error) {
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if old_memory == nil {
		if should_zero {
			return alloc_bytes(new_size, alignment, allocator, loc)
		} else {
			return alloc_bytes_non_zeroed(new_size, alignment, allocator, loc)
		}
	}

	if new_size == 0 {
		err := free_bytes(old_data, allocator, loc)
		return nil, err
	}

	if new_size == old_size {
		return old_data, .None
	}

	new_memory : []byte
	err : Allocator_Error
	if should_zero {
		new_memory, err = alloc_bytes(new_size, alignment, allocator, loc)
	} else {
		new_memory, err = alloc_bytes_non_zeroed(new_size, alignment, allocator, loc)
	}
	if new_memory == nil || err != nil {
		return nil, err
	}

	runtime.copy(new_memory, old_data)
	free_bytes(old_data, allocator, loc)
	return new_memory, err
}
