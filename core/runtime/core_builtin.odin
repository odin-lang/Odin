package runtime

import "core:intrinsics"

@builtin
Maybe :: union($T: typeid) {T}


@builtin
container_of :: #force_inline proc "contextless" (ptr: $P/^$Field_Type, $T: typeid, $field_name: string) -> ^T
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == Field_Type {
	offset :: offset_of_by_string(T, field_name)
	return (^T)(uintptr(ptr) - offset) if ptr != nil else nil
}


@thread_local global_default_temp_allocator_data: Default_Temp_Allocator

@builtin
init_global_temporary_allocator :: proc(size: int, backup_allocator := context.allocator) {
	default_temp_allocator_init(&global_default_temp_allocator_data, size, backup_allocator)
}


@builtin
copy_slice :: proc "contextless" (dst, src: $T/[]$E) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		intrinsics.mem_copy(raw_data(dst), raw_data(src), n*size_of(E))
	}
	return n
}
@builtin
copy_from_string :: proc "contextless" (dst: $T/[]$E/u8, src: $S/string) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		intrinsics.mem_copy(raw_data(dst), raw_data(src), n)
	}
	return n
}
@builtin
copy :: proc{copy_slice, copy_from_string}



@builtin
unordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	n := len(array)-1
	if index != n {
		array[index] = array[n]
	}
	(^Raw_Dynamic_Array)(array).len -= 1
}

@builtin
ordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		copy(array[index:], array[index+1:])
	}
	(^Raw_Dynamic_Array)(array).len -= 1
}

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


@builtin
pop :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, "", loc)
	res = array[len(array)-1]
	(^Raw_Dynamic_Array)(array).len -= 1
	return res
}


@builtin
pop_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[len(array)-1], true
	(^Raw_Dynamic_Array)(array).len -= 1
	return
}

@builtin
pop_front :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, "", loc)
	res = array[0]
	if len(array) > 1 {
		copy(array[0:], array[1:])
	}
	(^Raw_Dynamic_Array)(array).len -= 1
	return res
}

@builtin
pop_front_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
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


@builtin
clear :: proc{clear_dynamic_array, clear_map}

@builtin
reserve :: proc{reserve_dynamic_array, reserve_map}

@builtin
resize :: proc{resize_dynamic_array}

// Shrinks the capacity of a dynamic array or map down to the current length, or the given capacity.
@builtin
shrink :: proc{shrink_dynamic_array, shrink_map}

@builtin
free :: proc{mem_free}

@builtin
free_all :: proc{mem_free_all}



@builtin
delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(str), len(str), allocator, loc)
}
@builtin
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free((^byte)(str), allocator, loc)
}
@builtin
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(array), cap(array)*size_of(E), array.allocator, loc)
}
@builtin
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free_with_size(raw_data(array), len(array)*size_of(E), allocator, loc)
}
@builtin
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
	return map_free_dynamic(transmute(Raw_Map)m, map_info(T), loc)
}


@builtin
delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
}


// The new built-in procedure allocates memory. The first argument is a type, not a value, and the value
// return is a pointer to a newly allocated value of that type using the specified allocator, default is context.allocator
@builtin
new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> (^T, Allocator_Error) #optional_allocator_error {
	return new_aligned(T, align_of(T), allocator, loc)
}
new_aligned :: proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	data := mem_alloc_bytes(size_of(T), alignment, allocator, loc) or_return
	t = (^T)(raw_data(data))
	return
}

@builtin
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) #optional_allocator_error {
	t_data := mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return
	t = (^T)(raw_data(t_data))
	if t != nil {
		t^ = data
	}
	return
}

DEFAULT_RESERVE_CAPACITY :: 16

make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	make_slice_error_loc(loc, len)
	data, err := mem_alloc_bytes(size_of(E)*len, alignment, allocator, loc)
	if data == nil && size_of(E) != 0 {
		return nil, err
	}
	s := Raw_Slice{raw_data(data), len}
	return transmute(T)s, err
}

@(builtin)
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_aligned(T, len, align_of(E), allocator, loc)
}
@(builtin)
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_dynamic_array_len_cap(T, 0, DEFAULT_RESERVE_CAPACITY, allocator, loc)
}
@(builtin)
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_allocator_error {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
@(builtin)
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, #any_int len: int, #any_int cap: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	make_dynamic_array_error_loc(loc, len, cap)
	data := mem_alloc_bytes(size_of(E)*cap, align_of(E), allocator, loc) or_return
	s := Raw_Dynamic_Array{raw_data(data), len, cap, allocator}
	if data == nil && size_of(E) != 0 {
		s.len, s.cap = 0, 0
	}
	array = transmute(T)s
	return
}
@(builtin)
make_map :: proc($T: typeid/map[$K]$E, #any_int capacity: int = 1<<MAP_MIN_LOG2_CAPACITY, allocator := context.allocator, loc := #caller_location) -> (m: T, err: Allocator_Error) #optional_allocator_error {
	make_map_expr_error_loc(loc, capacity)
	context.allocator = allocator

	err = reserve_map(&m, capacity, loc)
	return
}
@(builtin)
make_multi_pointer :: proc($T: typeid/[^]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) #optional_allocator_error {
	make_slice_error_loc(loc, len)
	data := mem_alloc_bytes(size_of(E)*len, align_of(E), allocator, loc) or_return
	if data == nil && size_of(E) != 0 {
		return
	}
	mp = cast(T)raw_data(data)
	return
}


// The make built-in procedure allocates and initializes a value of type slice, dynamic array, or map (only)
// Similar to new, the first argument is a type, not a value. Unlike new, make's return type is the same as the
// type of its argument, not a pointer to it.
// Make uses the specified allocator, default is context.allocator, default is context.allocator
@builtin
make :: proc{
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
}



@builtin
clear_map :: proc "contextless" (m: ^$T/map[$K]$V) {
	if m == nil {
		return
	}
	map_clear_dynamic((^Raw_Map)(m), map_info(T))
}

@builtin
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int, loc := #caller_location) -> Allocator_Error {
	return __dynamic_map_reserve((^Raw_Map)(m), map_info(T), uint(capacity), loc) if m != nil else nil
}

/*
	Shrinks the capacity of a map down to the current length.
*/
@builtin
shrink_map :: proc(m: ^$T/map[$K]$V, loc := #caller_location) -> (did_shrink: bool) {
	if m != nil {
		err := map_shrink_dynamic((^Raw_Map)(m), map_info(T), loc)
		did_shrink = err == nil
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



@builtin
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location) -> int {
	if array == nil {
		return 0
	}
	when size_of(E) == 0 {
		array.len += 1
		return 1
	} else {
		if cap(array) < len(array)+1 {
			cap := 2 * cap(array) + max(8, 1)
			_ = reserve(array, cap, loc)
		}
		if cap(array)-len(array) > 0 {
			a := (^Raw_Dynamic_Array)(array)
			when size_of(E) != 0 {
				data := ([^]E)(a.data)
				assert(condition=data != nil, loc=loc)
				data[a.len] = arg
			}
			a.len += 1
			return 1
		}
		return 0
	}
}

@builtin
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location) -> int {
	if array == nil {
		return 0
	}

	arg_len := len(args)
	if arg_len <= 0 {
		return 0
	}

	when size_of(E) == 0 {
		array.len += arg_len
		return arg_len
	} else {
		if cap(array) < len(array)+arg_len {
			cap := 2 * cap(array) + max(8, arg_len)
			_ = reserve(array, cap, loc)
		}
		arg_len = min(cap(array)-len(array), arg_len)
		if arg_len > 0 {
			a := (^Raw_Dynamic_Array)(array)
			when size_of(E) != 0 {
				data := ([^]E)(a.data)
				assert(condition=data != nil, loc=loc)
				intrinsics.mem_copy(&data[a.len], raw_data(args), size_of(E) * arg_len)
			}
			a.len += arg_len
		}
		return arg_len
	}
}

// The append_string built-in procedure appends a string to the end of a [dynamic]u8 like type
@builtin
append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) -> int {
	args := transmute([]E)arg
	return append_elems(array=array, args=args, loc=loc)
}


// The append_string built-in procedure appends multiple strings to the end of a [dynamic]u8 like type
@builtin
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) -> (n: int) {
	for arg in args {
		n += append(array = array, args = transmute([]E)(arg), loc = loc)
	}
	return
}

// The append built-in procedure appends elements to the end of a dynamic array
@builtin append :: proc{append_elem, append_elems, append_elem_string}


@builtin
append_nothing :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> int {
	if array == nil {
		return 0
	}
	prev_len := len(array)
	resize(array, len(array)+1)
	return len(array)-prev_len
}


@builtin
inject_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if array == nil {
		return
	}
	n := max(len(array), index)
	m :: 1
	new_size := n + m

	if resize(array, new_size, loc) {
		when size_of(E) != 0 {
			copy(array[index + m:], array[index:])
			array[index] = arg
		}
		ok = true
	}
	return
}

@builtin
inject_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
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

	if resize(array, new_size, loc) {
		when size_of(E) != 0 {
			copy(array[index + m:], array[index:])
			copy(array[index:], args)
		}
		ok = true
	}
	return
}

@builtin
inject_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool) #no_bounds_check {
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

	if resize(array, new_size, loc) {
		copy(array[index+m:], array[index:])
		copy(array[index:], arg)
		ok = true
	}
	return
}

@builtin inject_at :: proc{inject_at_elem, inject_at_elems, inject_at_elem_string}



@builtin
assign_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if index < len(array) {
		array[index] = arg
		ok = true
	} else if resize(array, index+1, loc) {
		array[index] = arg
		ok = true
	}
	return
}


@builtin
assign_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if index+len(args) < len(array) {
		copy(array[index:], args)
		ok = true
	} else if resize(array, index+1+len(args), loc) {
		copy(array[index:], args)
		ok = true
	}
	return
}


@builtin
assign_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if len(args) == 0 {
		ok = true
	} else if index+len(args) < len(array) {
		copy(array[index:], args)
		ok = true
	} else if resize(array, index+1+len(args), loc) {
		copy(array[index:], args)
		ok = true
	}
	return
}

@builtin assign_at :: proc{assign_at_elem, assign_at_elems, assign_at_elem_string}




@builtin
clear_dynamic_array :: proc "contextless" (array: ^$T/[dynamic]$E) {
	if array != nil {
		(^Raw_Dynamic_Array)(array).len = 0
	}
}

@builtin
reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil {
		return false
	}
	a := (^Raw_Dynamic_Array)(array)

	if capacity <= a.cap {
		return true
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size  := a.cap * size_of(E)
	new_size  := capacity * size_of(E)
	allocator := a.allocator

	new_data, err := mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc)
	if new_data == nil || err != nil {
		return false
	}

	a.data = raw_data(new_data)
	a.cap = capacity
	return true
}

@builtin
resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> bool {
	if array == nil {
		return false
	}
	a := (^Raw_Dynamic_Array)(array)

	if length <= a.cap {
		a.len = max(length, 0)
		return true
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator
	}
	assert(a.allocator.procedure != nil)

	old_size  := a.cap * size_of(E)
	new_size  := length * size_of(E)
	allocator := a.allocator

	new_data, err := mem_resize(a.data, old_size, new_size, align_of(E), allocator, loc)
	if new_data == nil || err != nil {
		return false
	}

	a.data = raw_data(new_data)
	a.len = length
	a.cap = length
	return true
}

/*
	Shrinks the capacity of a dynamic array down to the current length, or the given capacity.

	If `new_cap` is negative, then `len(array)` is used.

	Returns false if `cap(array) < new_cap`, or the allocator report failure.

	If `len(array) < new_cap`, then `len(array)` will be left unchanged.
*/
shrink_dynamic_array :: proc(array: ^$T/[dynamic]$E, new_cap := -1, loc := #caller_location) -> (did_shrink: bool) {
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

	new_data, err := mem_resize(a.data, old_size, new_size, align_of(E), a.allocator, loc)
	if err != nil {
		return
	}

	a.data = raw_data(new_data)
	a.len = min(new_cap, a.len)
	a.cap = new_cap
	return true
}

@builtin
map_insert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
	key, value := key, value
	return (^V)(__dynamic_map_set_without_hash((^Raw_Map)(m), map_info(T), rawptr(&key), rawptr(&value), loc))
}


@builtin
incl_elem :: proc(s: ^$S/bit_set[$E; $U], elem: E) {
	s^ |= {elem}
}
@builtin
incl_elems :: proc(s: ^$S/bit_set[$E; $U], elems: ..E) {
	for elem in elems {
		s^ |= {elem}
	}
}
@builtin
incl_bit_set :: proc(s: ^$S/bit_set[$E; $U], other: S) {
	s^ |= other
}
@builtin
excl_elem :: proc(s: ^$S/bit_set[$E; $U], elem: E) {
	s^ &~= {elem}
}
@builtin
excl_elems :: proc(s: ^$S/bit_set[$E; $U], elems: ..E) {
	for elem in elems {
		s^ &~= {elem}
	}
}
@builtin
excl_bit_set :: proc(s: ^$S/bit_set[$E; $U], other: S) {
	s^ &~= other
}

@builtin incl :: proc{incl_elem, incl_elems, incl_bit_set}
@builtin excl :: proc{excl_elem, excl_elems, excl_bit_set}


@builtin
card :: proc(s: $S/bit_set[$E; $U]) -> int {
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
@(disabled=ODIN_DISABLE_ASSERT)
panic :: proc(message: string, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = default_assertion_failure_proc
	}
	p("panic", message, loc)
}

@builtin
@(disabled=ODIN_DISABLE_ASSERT)
unimplemented :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = default_assertion_failure_proc
	}
	p("not yet implemented", message, loc)
}
