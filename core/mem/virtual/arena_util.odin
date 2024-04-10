package mem_virtual

import "base:runtime"
_ :: runtime

// The `new` procedure allocates memory for a type `T` from a `virtual.Arena`. The second argument is a type,
// not a value, and the value return is a pointer to a newly allocated value of that type using the specified allocator.
@(require_results)
new :: proc(arena: ^Arena, $T: typeid, loc := #caller_location) -> (ptr: ^T, err: Allocator_Error) {
	return new_aligned(arena, T, align_of(T), loc)
}

// The `new_aligned` procedure allocates memory for a type `T` from a `virtual.Arena` with a specified `alignment`.
// The second argument is a type, not a value, and the value return is a pointer to a newly allocated value of
// that type using the specified allocator.
@(require_results)
new_aligned :: proc(arena: ^Arena, $T: typeid, alignment: uint, loc := #caller_location) -> (ptr: ^T, err: Allocator_Error) {
	data := arena_alloc(arena, size_of(T), alignment, loc) or_return
	ptr = (^T)(raw_data(data))
	return
}

// `make_slice` allocates and initializes a slice. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(require_results)
make_slice :: proc(arena: ^Arena, $T: typeid/[]$E, #any_int len: int, loc := #caller_location) -> (T, Allocator_Error) {
	return make_aligned(arena, T, len, align_of(E), loc)
}

// `make_aligned` allocates and initializes a slice. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(require_results)
make_aligned :: proc(arena: ^Arena, $T: typeid/[]$E, #any_int len: int, alignment: uint, loc := #caller_location) -> (T, Allocator_Error) {
	runtime.make_slice_error_loc(loc, len)
	data, err := arena_alloc(arena, size_of(E)*uint(len), alignment, loc)
	if data == nil && size_of(E) != 0 {
		return nil, err
	}
	s := ([^]E)(raw_data(data))[:len]
	return T(s), err
}


// `make_multi_pointer` allocates and initializes a dynamic array. Like `new`, the second argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// This is "similar" to doing `raw_data(make([]E, len, allocator))`.
//
// Note: Prefer using the procedure group `make`.
@(require_results)
make_multi_pointer :: proc(arena: ^Arena, $T: typeid/[^]$E, #any_int len: int, loc := #caller_location) -> (T, Allocator_Error) {
	runtime.make_slice_error_loc(loc, len)
	data, err := arena_alloc(arena, size_of(E)*uint(len), align_of(E), loc)
	if data == nil && size_of(E) != 0 {
		return nil, err
	}
	return (T)(raw_data(data)), err
}

make :: proc{
	make_slice,
	make_multi_pointer,
}