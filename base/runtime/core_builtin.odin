package runtime

import "base:intrinsics"

@builtin
Maybe :: union($T: typeid) {T}


@(builtin, require_results)
container_of :: #force_inline proc "contextless" (ptr: $P/^$Field_Type, $T: typeid, $field_name: string) -> ^T
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Field_Type {
	offset :: offset_of_by_string(T, field_name)
	return (^T)(uintptr(ptr) - offset) if ptr != nil else nil
}


when !NO_DEFAULT_TEMP_ALLOCATOR {
	@thread_local global_default_temp_allocator_data: Default_Temp_Allocator
}

@(builtin, disabled=NO_DEFAULT_TEMP_ALLOCATOR)
init_global_temporary_allocator :: proc(size: int, backup_allocator := context.allocator) {
	when !NO_DEFAULT_TEMP_ALLOCATOR {
		default_temp_allocator_init(&global_default_temp_allocator_data, size, backup_allocator)
	}
}


// `copy_slice` is a built-in procedure that copies elements from a source slice `src` to a destination slice `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
//
// Prefer the procedure group `copy`.
@builtin
copy_slice :: proc "contextless" (dst, src: $T/[]$E) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		intrinsics.mem_copy(raw_data(dst), raw_data(src), n*size_of(E))
	}
	return n
}
// `copy_from_string` is a built-in procedure that copies elements from a source slice `src` to a destination string `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
//
// Prefer the procedure group `copy`.
@builtin
copy_from_string :: proc "contextless" (dst: $T/[]$E/u8, src: $S/string) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		intrinsics.mem_copy(raw_data(dst), raw_data(src), n)
	}
	return n
}
// `copy` is a built-in procedure that copies elements from a source slice `src` to a destination slice/string `dst`.
// The source and destination may overlap. Copy returns the number of elements copied, which will be the minimum
// of len(src) and len(dst).
@builtin
copy :: proc{copy_slice, copy_from_string}



// `unordered_remove` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the dynamic array by 1.
//
// Note: This is an O(1) operation.
// Note: If you the elements to remain in their order, use `ordered_remove`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
unordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	n := len(array)-1
	if index != n {
		array[index] = array[n]
	}
	(^Raw_Dynamic_Array)(array).len -= 1
}
// `ordered_remove` removed the element at the specified `index` whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If you the elements do not have to remain in their order, prefer `unordered_remove`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
ordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		copy(array[index:], array[index+1:])
	}
	(^Raw_Dynamic_Array)(array).len -= 1
}

// `remove_range` removes a range of elements specified by the range `lo` and `hi`, whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If the range is out of bounds, this procedure will panic.
@builtin
remove_range :: proc(array: ^$D/[dynamic]$T, lo, hi: int, loc := #caller_location) #no_bounds_check {
	slice_expr_error_lo_hi_loc(loc, lo, hi, len(array))
	n := max(hi-lo, 0)
	if n > 0 {
		if hi != len(array) {
			copy(array[lo:], array[hi:])
		}
		(^Raw_Dynamic_Array)(array).len -= n
	}
}


// `pop` will remove and return the end value of dynamic array `array` and reduces the length of `array` by 1.
//
// Note: If the dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[len(array)-1]
	(^Raw_Dynamic_Array)(array).len -= 1
	return res
}


// `pop_safe` trys to remove and return the end value of dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
@builtin
pop_safe :: proc "contextless" (array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[len(array)-1], true
	(^Raw_Dynamic_Array)(array).len -= 1
	return
}

// `pop_front` will remove and return the first value of dynamic array `array` and reduces the length of `array` by 1.
//
// Note: If the dynamic array as no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop_front :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[0]
	if len(array) > 1 {
		copy(array[0:], array[1:])
	}
	(^Raw_Dynamic_Array)(array).len -= 1
	return res
}

// `pop_front_safe` trys to return and remove the first value of dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
@builtin
pop_front_safe :: proc "contextless" (array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[0], true
	if len(array) > 1 {
		copy(array[0:], array[1:])
	}
	(^Raw_Dynamic_Array)(array).len -= 1
	return
}


// `clear` will set the length of a passed dynamic array or map to `0`
@builtin
clear :: proc{clear_dynamic_array, clear_map}

// `reserve` will try to reserve memory of a passed dynamic array or map to the requested element count (setting the `cap`).
@builtin
reserve :: proc{reserve_dynamic_array, reserve_map}

@builtin
non_zero_reserve :: proc{non_zero_reserve_dynamic_array}

// `resize` will try to resize memory of a passed dynamic array to the requested element count (setting the `len`, and possibly `cap`).
@builtin
resize :: proc{resize_dynamic_array}

@builtin
non_zero_resize :: proc{non_zero_resize_dynamic_array}

// Shrinks the capacity of a dynamic array or map down to the current length, or the given capacity.
@builtin
shrink :: proc{shrink_dynamic_array, shrink_map}

// `free` will try to free the passed pointer, with the given `allocator` if the allocator supports this operation.
@builtin
free :: proc{mem_free}

// `free_all` will try to free/reset all of the memory of the given `allocator` if the allocator supports this operation.
@builtin
free_all :: proc{mem_free_all}



// `delete_string` will try to free the underlying data of the passed string, with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer the procedure group `delete`.
@builtin
delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(str), len(str), allocator, loc)
}
// `delete_cstring` will try to free the underlying data of the passed string, with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer the procedure group `delete`.
@builtin
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free((^byte)(str), allocator, loc)
}
// `delete_dynamic_array` will try to free the underlying data of the passed dynamic array, with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer the procedure group `delete`.
@builtin
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(array), cap(array)*size_of(E), array.allocator, loc)
}
// `delete_slice` will try to free the underlying data of the passed sliced, with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer the procedure group `delete`.
@builtin
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(array), len(array)*size_of(E), allocator, loc)
}
// `delete_map` will try to free the underlying data of the passed map, with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer the procedure group `delete`.
@builtin
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
	return map_free_dynamic(transmute(Raw_Map)m, map_info(T), loc)
}


// `delete` will try to free the underlying data of the passed built-in data structure (string, cstring, dynamic array, slice, or map), with the given `allocator` if the allocator supports this operation.
//
// Note: Prefer `delete` over the specific `delete_*` procedures where possible.
@builtin
delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
	delete_soa_slice,
	delete_soa_dynamic_array,
}


// The new built-in procedure allocates memory. The first argument is a type, not a value, and the value
// return is a pointer to a newly allocated value of that type using the specified allocator, default is context.allocator
@(builtin, require_results)
new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> (^T, Allocator_Error) #optional_allocator_error {
	return new_aligned(T, align_of(T), allocator, loc)
}
@(require_results)
new_aligned :: proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	data := mem_alloc_bytes(size_of(T), alignment, allocator, loc) or_return
	t = (^T)(raw_data(data))
	return
}

@(builtin, require_results)
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) #optional_allocator_error {
	t_data := mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return
	t = (^T)(raw_data(t_data))
	if t != nil {
		t^ = data
	}
	return
}

DEFAULT_RESERVE_CAPACITY :: 16

@(require_results)
make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	make_slice_error_loc(loc, len)
	data, err := mem_alloc_bytes(size_of(E)*len, alignment, allocator, loc)
	if data == nil && size_of(E) != 0 {
		return nil, err
	}
	s := Raw_Slice{raw_data(data), len}
	return transmute(T)s, err
}

// `make_slice` allocates and initializes a slice. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_aligned(T, len, align_of(E), allocator, loc)
}
// `make_dynamic_array` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_dynamic_array_len_cap(T, 0, DEFAULT_RESERVE_CAPACITY, allocator, loc)
}
// `make_dynamic_array_len` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
// `make_dynamic_array_len_cap` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, #any_int len: int, #any_int cap: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	make_dynamic_array_error_loc(loc, len, cap)
	array.allocator = allocator // initialize allocator before just in case it fails to allocate any memory
	data := mem_alloc_bytes(size_of(E)*cap, align_of(E), allocator, loc) or_return
	s := Raw_Dynamic_Array{raw_data(data), len, cap, allocator}
	if data == nil && size_of(E) != 0 {
		s.len, s.cap = 0, 0
	}
	array = transmute(T)s
	return
}
// `make_map` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_map :: proc($T: typeid/map[$K]$E, #any_int capacity: int = 1<<MAP_MIN_LOG2_CAPACITY, allocator := context.allocator, loc := #caller_location) -> (m: T, err: Allocator_Error) #optional_allocator_error {
	make_map_expr_error_loc(loc, capacity)
	context.allocator = allocator

	err = reserve_map(&m, capacity, loc)
	return
}
// `make_multi_pointer` allocates and initializes a dynamic array. Like `new`, the first argument is a type, not a value.
// Unlike `new`, `make`'s return value is the same as the type of its argument, not a pointer to it.
//
// This is "similar" to doing `raw_data(make([]E, len, allocator))`.
//
// Note: Prefer using the procedure group `make`.
@(builtin, require_results)
make_multi_pointer :: proc($T: typeid/[^]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) #optional_allocator_error {
	make_slice_error_loc(loc, len)
	data := mem_alloc_bytes(size_of(E)*len, align_of(E), allocator, loc) or_return
	if data == nil && size_of(E) != 0 {
		return
	}
	mp = cast(T)raw_data(data)
	return
}


// `make` built-in procedure allocates and initializes a value of type slice, dynamic array, map, or multi-pointer (only).
//
// Similar to `new`, the first argument is a type, not a value. Unlike new, make's return type is the same as the
// type of its argument, not a pointer to it.
// Make uses the specified allocator, default is context.allocator.
@builtin
make :: proc{
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
}



// `clear_map` will set the length of a passed map to `0`
//
// Note: Prefer the procedure group `clear`
@builtin
clear_map :: proc "contextless" (m: ^$T/map[$K]$V) {
	if m == nil {
		return
	}
	map_clear_dynamic((^Raw_Map)(m), map_info(T))
}

// `reserve_map` will try to reserve memory of a passed map to the requested element count (setting the `cap`).
//
// Note: Prefer the procedure group `reserve`
@builtin
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int, loc := #caller_location) -> Allocator_Error {
	return __dynamic_map_reserve((^Raw_Map)(m), map_info(T), uint(capacity), loc) if m != nil else nil
}

// Shrinks the capacity of a map down to the current length.
//
// Note: Prefer the procedure group `shrink`
@builtin
shrink_map :: proc(m: ^$T/map[$K]$V, loc := #caller_location) -> (did_shrink: bool, err: Allocator_Error) {
	if m != nil {
		return map_shrink_dynamic((^Raw_Map)(m), map_info(T), loc)
	}
	return
}

// The delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@builtin
delete_key :: proc(m: ^$T/map[$K]$V, key: K) -> (deleted_key: K, deleted_value: V) {
	if m != nil {
		key := key
		old_k, old_v, ok := map_erase_dynamic((^Raw_Map)(m), map_info(T), uintptr(&key))
		if ok {
			deleted_key   = (^K)(old_k)^
			deleted_value = (^V)(old_v)^
		}
	}
	return
}

_append_elem :: #force_inline proc(array: ^$T/[dynamic]$E, arg: E, should_zero: bool, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}
	when size_of(E) == 0 {
		array := (^Raw_Dynamic_Array)(array)
		array.len += 1
		return 1, nil
	} else {
		if cap(array) < len(array)+1 {
			cap := 2 * cap(array) + max(8, 1)

			// do not 'or_return' here as it could be a partial success
			if should_zero {
				err = reserve(array, cap, loc)
			} else {
				err = non_zero_reserve(array, cap, loc) 
			}
		}
		if cap(array)-len(array) > 0 {
			a := (^Raw_Dynamic_Array)(array)
			when size_of(E) != 0 {
				data := ([^]E)(a.data)
				assert(data != nil, loc=loc)
				data[a.len] = arg
			}
			a.len += 1
			return 1, err
		}
		return 0, err
	}
}

@builtin
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elem(array, arg, true, loc=loc)
}

@builtin
non_zero_append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elem(array, arg, false, loc=loc)
}

_append_elems :: #force_inline proc(array: ^$T/[dynamic]$E, should_zero: bool, loc := #caller_location, args: ..E) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}

	arg_len := len(args)
	if arg_len <= 0 {
		return 0, nil
	}

	when size_of(E) == 0 {
		array := (^Raw_Dynamic_Array)(array)
		array.len += arg_len
		return arg_len, nil
	} else {
		if cap(array) < len(array)+arg_len {
			cap := 2 * cap(array) + max(8, arg_len)

			// do not 'or_return' here as it could be a partial success
			if should_zero {
				err = reserve(array, cap, loc)
			} else {
				err = non_zero_reserve(array, cap, loc)
			}
		}
		arg_len = min(cap(array)-len(array), arg_len)
		if arg_len > 0 {
			a := (^Raw_Dynamic_Array)(array)
			when size_of(E) != 0 {
				data := ([^]E)(a.data)
				assert(data != nil, loc=loc)
				intrinsics.mem_copy(&data[a.len], raw_data(args), size_of(E) * arg_len)
			}
			a.len += arg_len
		}
		return arg_len, err
	}
}

@builtin
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elems(array, true, loc, ..args)
}

@builtin
non_zero_append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elems(array, false, loc, ..args)
}

// The append_string built-in procedure appends a string to the end of a [dynamic]u8 like type
_append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, should_zero: bool, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	args := transmute([]E)arg
	if should_zero { 
		return append_elems(array, ..args, loc=loc)
	} else {
		return non_zero_append_elems(array, ..args, loc=loc)
	}
}

@builtin
append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elem_string(array, arg, true, loc)
}
@builtin
non_zero_append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_elem_string(array, arg, false, loc)
}


// The append_string built-in procedure appends multiple strings to the end of a [dynamic]u8 like type
@builtin
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	n_arg: int
	for arg in args {
		n_arg, err = append(array, ..transmute([]E)(arg), loc=loc)
		n += n_arg
		if err != nil {
			return
		}
	}
	return
}

// The append built-in procedure appends elements to the end of a dynamic array
@builtin append :: proc{append_elem, append_elems, append_elem_string}
@builtin non_zero_append :: proc{non_zero_append_elem, non_zero_append_elems, non_zero_append_elem_string}


@builtin
append_nothing :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}
	prev_len := len(array)
	resize(array, len(array)+1, loc) or_return
	return len(array)-prev_len, nil
}


@builtin
inject_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	if array == nil {
		return
	}
	n := max(len(array), index)
	m :: 1
	new_size := n + m

	resize(array, new_size, loc) or_return
	when size_of(E) != 0 {
		copy(array[index + m:], array[index:])
		array[index] = arg
	}
	ok = true
	return
}

@builtin
inject_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	if array == nil {
		return
	}
	if len(args) == 0 {
		ok = true
		return
	}

	n := max(len(array), index)
	m := len(args)
	new_size := n + m

	resize(array, new_size, loc) or_return
	when size_of(E) != 0 {
		copy(array[index + m:], array[index:])
		copy(array[index:], args)
	}
	ok = true
	return
}

@builtin
inject_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	if array == nil {
		return
	}
	if len(arg) == 0 {
		ok = true
		return
	}

	n := max(len(array), index)
	m := len(arg)
	new_size := n + m

	resize(array, new_size, loc) or_return
	copy(array[index+m:], array[index:])
	copy(array[index:], arg)
	ok = true
	return
}

@builtin inject_at :: proc{inject_at_elem, inject_at_elems, inject_at_elem_string}



@builtin
assign_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	if index < len(array) {
		array[index] = arg
		ok = true
	} else {
		resize(array, index+1, loc) or_return
		array[index] = arg
		ok = true
	}
	return
}


@builtin
assign_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	new_size := index + len(args)
	if len(args) == 0 {
		ok = true
	} else if new_size < len(array) {
		copy(array[index:], args)
		ok = true
	} else {
		resize(array, new_size, loc) or_return
		copy(array[index:], args)
		ok = true
	}
	return
}


@builtin
assign_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	new_size := index + len(arg)
	if len(arg) == 0 {
		ok = true
	} else if new_size < len(array) {
		copy(array[index:], arg)
		ok = true
	} else {
		resize(array, new_size, loc) or_return
		copy(array[index:], arg)
		ok = true
	}
	return
}

@builtin assign_at :: proc{assign_at_elem, assign_at_elems, assign_at_elem_string}




// `clear_dynamic_array` will set the length of a passed dynamic array to `0`
//
// Note: Prefer the procedure group `clear`.
@builtin
clear_dynamic_array :: proc "contextless" (array: ^$T/[dynamic]$E) {
	if array != nil {
		(^Raw_Dynamic_Array)(array).len = 0
	}
}

// `reserve_dynamic_array` will try to reserve memory of a passed dynamic array or map to the requested element count (setting the `cap`).
//
// Note: Prefer the procedure group `reserve`.
_reserve_dynamic_array :: #force_inline proc(array: ^$T/[dynamic]$E, capacity: int, should_zero: bool, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	a := (^Raw_Dynamic_Array)(array)

	if capacity <= a.cap {
		return nil
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size  := a.cap * size_of(E)
	new_size  := capacity * size_of(E)
	allocator := a.allocator

	new_data: []byte
	if should_zero {
		new_data = mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc) or_return
	} else {
		new_data = non_zero_mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc) or_return
	}
	if new_data == nil && new_size > 0 {
		return .Out_Of_Memory
	}

	a.data = raw_data(new_data)
	a.cap = capacity
	return nil
}

@builtin
reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_dynamic_array(array, capacity, true, loc)
}

@builtin
non_zero_reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_dynamic_array(array, capacity, false, loc)
}

// `resize_dynamic_array` will try to resize memory of a passed dynamic array or map to the requested element count (setting the `len`, and possibly `cap`).
//
// Note: Prefer the procedure group `resize`
_resize_dynamic_array :: #force_inline proc(array: ^$T/[dynamic]$E, length: int, should_zero: bool, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	a := (^Raw_Dynamic_Array)(array)

	if length <= a.cap {
		a.len = max(length, 0)
		return nil
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size  := a.cap * size_of(E)
	new_size  := length * size_of(E)
	allocator := a.allocator

	new_data : []byte
	if should_zero {
		new_data = mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc) or_return
	} else {
		new_data = non_zero_mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc) or_return
	}
	if new_data == nil && new_size > 0 {
		return .Out_Of_Memory
	}

	a.data = raw_data(new_data)
	a.len = length
	a.cap = length
	return nil
}

@builtin
resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> Allocator_Error {
	return _resize_dynamic_array(array, length, true, loc=loc)
}

@builtin
non_zero_resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> Allocator_Error {
	return _resize_dynamic_array(array, length, false, loc=loc)
}

/*
	Shrinks the capacity of a dynamic array down to the current length, or the given capacity.

	If `new_cap` is negative, then `len(array)` is used.

	Returns false if `cap(array) < new_cap`, or the allocator report failure.

	If `len(array) < new_cap`, then `len(array)` will be left unchanged.

	Note: Prefer the procedure group `shrink`
*/
shrink_dynamic_array :: proc(array: ^$T/[dynamic]$E, new_cap := -1, loc := #caller_location) -> (did_shrink: bool, err: Allocator_Error) {
	if array == nil {
		return
	}
	a := (^Raw_Dynamic_Array)(array)

	new_cap := new_cap if new_cap >= 0 else a.len

	if new_cap > a.cap {
		return
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size := a.cap * size_of(E)
	new_size := new_cap * size_of(E)

	new_data := mem_resize(a.data, old_size, new_size, align_of(E), a.allocator, loc) or_return

	a.data = raw_data(new_data)
	a.len = min(new_cap, a.len)
	a.cap = new_cap
	return true, nil
}

@builtin
map_insert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
	key, value := key, value
	return (^V)(__dynamic_map_set_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc))
}

// Explicitly inserts a key and value into a map `m`, the same as `map_insert`, but the return values differ.
// - `prev_key` will return the previous pointer of a key if it exists, check `found_previous` if was previously found
// - `value_ptr` will return the pointer of the memory where the insertion happens, and `nil` if the map failed to resize
// - `found_previous` will be true a previous key was found
@(builtin, require_results)
map_upsert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (prev_key: K, value_ptr: ^V, found_previous: bool) {
	key, value := key, value
	kp, vp := __dynamic_map_set_extra_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc)
	if kp != nil {
		prev_key = (^K)(kp)^
		found_previous = true
	}
	value_ptr = (^V)(vp)
	return
}


@builtin
card :: proc "contextless" (s: $S/bit_set[$E; $U]) -> int {
	when size_of(S) == 1 {
		return int(intrinsics.count_ones(transmute(u8)s))
	} else when size_of(S) == 2 {
		return int(intrinsics.count_ones(transmute(u16)s))
	} else when size_of(S) == 4 {
		return int(intrinsics.count_ones(transmute(u32)s))
	} else when size_of(S) == 8 {
		return int(intrinsics.count_ones(transmute(u64)s))
	} else when size_of(S) == 16 {
		return int(intrinsics.count_ones(transmute(u128)s))
	} else {
		#panic("Unhandled card bit_set size")
	}
}



@builtin
@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := "", loc := #caller_location) {
	if !condition {
		// NOTE(bill): This is wrapped in a procedure call
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		@(cold)
		internal :: proc(message: string, loc: Source_Code_Location) {
			p := context.assertion_failure_proc
			if p == nil {
				p = default_assertion_failure_proc
			}
			p("runtime assertion", message, loc)
		}
		internal(message, loc)
	}
}

@builtin
panic :: proc(message: string, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = default_assertion_failure_proc
	}
	p("panic", message, loc)
}

@builtin
unimplemented :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = default_assertion_failure_proc
	}
	p("not yet implemented", message, loc)
}
