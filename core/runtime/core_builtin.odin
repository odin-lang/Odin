package runtime

import "core:intrinsics"

@builtin
Maybe :: union($T: typeid) #maybe {T}

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


@builtin
free :: proc{mem_free}

@builtin
free_all :: proc{mem_free_all}



@builtin
delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free(raw_data(str), allocator, loc)
}
@builtin
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free((^byte)(str), allocator, loc)
}
@builtin
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	return mem_free(raw_data(array), array.allocator, loc)
}
@builtin
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return mem_free(raw_data(array), allocator, loc)
}
@builtin
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) -> Allocator_Error {
	raw := transmute(Raw_Map)m
	err := delete_slice(raw.hashes, raw.entries.allocator, loc)
	err1 := mem_free(raw.entries.data, raw.entries.allocator, loc)
	if err == nil {
		err = err1
	}
	return err
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
new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> (^T, Allocator_Error) #optional_second {
	return new_aligned(T, align_of(T), allocator, loc)
}
new_aligned :: proc($T: typeid, alignment: int, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) {
	data := mem_alloc_bytes(size_of(T), alignment, allocator, loc) or_return
	t = (^T)(raw_data(data))
	return
}

@builtin
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> (t: ^T, err: Allocator_Error) #optional_second {
	t_data := mem_alloc_bytes(size_of(T), align_of(T), allocator, loc) or_return
	t = (^T)(raw_data(t_data))
	if t != nil {
		t^ = data
	}
	return
}

DEFAULT_RESERVE_CAPACITY :: 16

make_aligned :: proc($T: typeid/[]$E, #any_int len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_second {
	make_slice_error_loc(loc, len)
	data, err := mem_alloc_bytes(size_of(E)*len, alignment, allocator, loc)
	if data == nil && size_of(E) != 0 {
		return nil, err
	}
	s := Raw_Slice{raw_data(data), len}
	return transmute(T)s, err
}

@(builtin)
make_slice :: proc($T: typeid/[]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_second {
	return make_aligned(T, len, align_of(E), allocator, loc)
}
@(builtin)
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_second {
	return make_dynamic_array_len_cap(T, 0, DEFAULT_RESERVE_CAPACITY, allocator, loc)
}
@(builtin)
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (T, Allocator_Error) #optional_second {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc)
}
@(builtin)
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, #any_int len: int, #any_int cap: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_second {
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
make_map :: proc($T: typeid/map[$K]$E, #any_int cap: int = DEFAULT_RESERVE_CAPACITY, allocator := context.allocator, loc := #caller_location) -> T {
	make_map_expr_error_loc(loc, cap)
	context.allocator = allocator

	m: T
	reserve_map(&m, cap)
	return m
}
@(builtin)
make_multi_pointer :: proc($T: typeid/[^]$E, #any_int len: int, allocator := context.allocator, loc := #caller_location) -> (mp: T, err: Allocator_Error) #optional_second {
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
	raw_map := (^Raw_Map)(m)
	entries := (^Raw_Dynamic_Array)(&raw_map.entries)
	entries.len = 0
	for _, i in raw_map.hashes {
		raw_map.hashes[i] = -1
	}
}

@builtin
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int) {
	if m != nil {
		__dynamic_map_reserve(__get_map_header(m), capacity)
	}
}

// The delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@builtin
delete_key :: proc(m: ^$T/map[$K]$V, key: K) -> (deleted_key: K, deleted_value: V) {
	if m != nil {
		key := key
		h := __get_map_header(m)
		hash := __get_map_hash(&key)
		fr := __dynamic_map_find(h, hash)
		if fr.entry_index >= 0 {
			entry := __dynamic_map_get_entry(h, fr.entry_index)
			deleted_key   = (^K)(uintptr(entry)+h.key_offset)^
			deleted_value = (^V)(uintptr(entry)+h.value_offset)^

			__dynamic_map_erase(h, fr)
		}
	}

	return
}



@builtin
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location)  {
	if array == nil {
		return
	}

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
	}
}

@builtin
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location)  {
	if array == nil {
		return
	}

	arg_len := len(args)
	if arg_len <= 0 {
		return
	}


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
}

// The append_string built-in procedure appends a string to the end of a [dynamic]u8 like type
@builtin
append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) {
	args := transmute([]E)arg
	append_elems(array=array, args=args, loc=loc)
}


// The append_string built-in procedure appends multiple strings to the end of a [dynamic]u8 like type
@builtin
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) {
	for arg in args {
		append(array = array, args = transmute([]E)(arg), loc = loc)
	}
}

// The append built-in procedure appends elements to the end of a dynamic array
@builtin append :: proc{append_elem, append_elems, append_elem_string}


@builtin
append_nothing :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) {
	if array == nil {
		return
	}
	resize(array, len(array)+1)
}


@builtin
insert_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
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
insert_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
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
insert_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool) #no_bounds_check {
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

@builtin insert_at :: proc{insert_at_elem, insert_at_elems, insert_at_elem_string}




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

	new_data, err := allocator.procedure(
		allocator.data, .Resize, new_size, align_of(E),
		a.data, old_size, loc,
	)
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

	new_data, err := allocator.procedure(
		allocator.data, .Resize, new_size, align_of(E),
		a.data, old_size, loc,
	)
	if new_data == nil || err != nil {
		return false
	}

	a.data = raw_data(new_data)
	a.len = length
	a.cap = length
	return true
}

@builtin
map_insert :: proc(m: ^$T/map[$K]$V, key: K, value: V, loc := #caller_location) -> (ptr: ^V) {
	key, value := key, value
	h := __get_map_header(m)
	hash := __get_map_hash(&key)
	
	data := uintptr(__dynamic_map_set(h, hash, &value, loc))
	return (^V)(data + h.value_offset)
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
raw_array_data :: proc "contextless" (a: $P/^($T/[$N]$E)) -> ^E {
	return (^E)(a)
}
@builtin
raw_slice_data :: proc "contextless" (s: $S/[]$E) -> ^E {
	ptr := (transmute(Raw_Slice)s).data
	return (^E)(ptr)
}
@builtin
raw_dynamic_array_data :: proc "contextless" (s: $S/[dynamic]$E) -> ^E {
	ptr := (transmute(Raw_Dynamic_Array)s).data
	return (^E)(ptr)
}
@builtin
raw_string_data :: proc "contextless" (s: $S/string) -> ^u8 {
	return (transmute(Raw_String)s).data
}

@builtin
raw_data :: proc{raw_array_data, raw_slice_data, raw_dynamic_array_data, raw_string_data}



@builtin
@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := "", loc := #caller_location) {
	if !condition {
		// NOTE(bill): This is wrapped in a procedure call
		// to improve performance to make the CPU not
		// execute speculatively, making it about an order of
		// magnitude faster
		proc(message: string, loc: Source_Code_Location) {
			p := context.assertion_failure_proc
			if p == nil {
				p = default_assertion_failure_proc
			}
			p("runtime assertion", message, loc)
		}(message, loc)
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

@builtin
@(disabled=ODIN_DISABLE_ASSERT)
unreachable :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc
	if p == nil {
		p = default_assertion_failure_proc
	}
	if message != "" {
		p("internal error", message, loc)
	} else {
		p("internal error", "entered unreachable code", loc)
	}
}
