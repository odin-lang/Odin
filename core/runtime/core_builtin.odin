package runtime

@builtin
Maybe :: union(T: typeid) #maybe {T};

@thread_local global_default_temp_allocator_data: Default_Temp_Allocator;

@builtin
init_global_temporary_allocator :: proc(size: int, backup_allocator := context.allocator) {
	default_temp_allocator_init(&global_default_temp_allocator_data, size, backup_allocator);
}


@builtin
copy_slice :: proc "contextless" (dst, src: $T/[]$E) -> int {
	n := max(0, min(len(dst), len(src)));
	if n > 0 {
		mem_copy(raw_data(dst), raw_data(src), n*size_of(E));
	}
	return n;
}
@builtin
copy_from_string :: proc "contextless" (dst: $T/[]$E/u8, src: $S/string) -> int {
	n := max(0, min(len(dst), len(src)));
	if n > 0 {
		mem_copy(raw_data(dst), raw_data(src), n);
	}
	return n;
}
@builtin
copy :: proc{copy_slice, copy_from_string};



@builtin
unordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	n := len(array)-1;
	if index != n {
		array[index] = array[n];
	}
	pop(array);
}

@builtin
ordered_remove :: proc(array: ^$D/[dynamic]$T, index: int, loc := #caller_location) {
	bounds_check_error_loc(loc, index, len(array));
	if index+1 < len(array) {
		copy(array[index:], array[index+1:]);
	}
	pop(array);
}

@builtin
remove_range :: proc(array: ^$D/[dynamic]$T, lo, hi: int, loc := #caller_location) {
	slice_expr_error_lo_hi_loc(loc, lo, hi, len(array));
	n := max(hi-lo, 0);
	if n > 0 {
		if hi != len(array) {
			copy(array[lo:], array[hi:]);
		}
		(^Raw_Dynamic_Array)(array).len -= n;
	}
}


@builtin
pop :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, "", loc);
	res = array[len(array)-1];
	(^Raw_Dynamic_Array)(array).len -= 1;
	return res;
}


@builtin
pop_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return;
	}
	res, ok = array[len(array)-1], true;
	(^Raw_Dynamic_Array)(array).len -= 1;
	return;
}

@builtin
pop_front :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, "", loc);
	res = array[0];
	if len(array) > 1 {
		copy(array[0:], array[1:]);
	}
	(^Raw_Dynamic_Array)(array).len -= 1;
	return res;
}

@builtin
pop_front_safe :: proc(array: ^$T/[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return;
	}
	res, ok = array[0], true;
	if len(array) > 1 {
		copy(array[0:], array[1:]);
	}
	(^Raw_Dynamic_Array)(array).len -= 1;
	return;
}


@builtin
clear :: proc{clear_dynamic_array, clear_map};

@builtin
reserve :: proc{reserve_dynamic_array, reserve_map};

@builtin
resize :: proc{resize_dynamic_array};


@builtin
free :: proc{mem_free};

@builtin
free_all :: proc{mem_free_all};



@builtin
delete_string :: proc(str: string, allocator := context.allocator, loc := #caller_location) {
	mem_free(raw_data(str), allocator, loc);
}
@builtin
delete_cstring :: proc(str: cstring, allocator := context.allocator, loc := #caller_location) {
	mem_free((^byte)(str), allocator, loc);
}
@builtin
delete_dynamic_array :: proc(array: $T/[dynamic]$E, loc := #caller_location) {
	mem_free(raw_data(array), array.allocator, loc);
}
@builtin
delete_slice :: proc(array: $T/[]$E, allocator := context.allocator, loc := #caller_location) {
	mem_free(raw_data(array), allocator, loc);
}
@builtin
delete_map :: proc(m: $T/map[$K]$V, loc := #caller_location) {
	raw := transmute(Raw_Map)m;
	delete_slice(raw.hashes, raw.entries.allocator, loc);
	mem_free(raw.entries.data, raw.entries.allocator, loc);
}


@builtin
delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
};


// The new built-in procedure allocates memory. The first argument is a type, not a value, and the value
// return is a pointer to a newly allocated value of that type using the specified allocator, default is context.allocator
@builtin
new :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(mem_alloc(size_of(T), align_of(T), allocator, loc));
	if ptr != nil { ptr^ = T{}; }
	return ptr;
}

@builtin
new_clone :: proc(data: $T, allocator := context.allocator, loc := #caller_location) -> ^T {
	ptr := (^T)(mem_alloc(size_of(T), align_of(T), allocator, loc));
	if ptr != nil { ptr^ = data; }
	return ptr;
}

make_aligned :: proc($T: typeid/[]$E, auto_cast len: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> T {
	make_slice_error_loc(loc, len);
	data := mem_alloc(size_of(E)*len, alignment, allocator, loc);
	if data == nil && size_of(E) != 0 {
		return nil;
	}
	// mem_zero(data, size_of(E)*len);
	s := Raw_Slice{data, len};
	return transmute(T)s;
}

@builtin
make_slice :: proc($T: typeid/[]$E, auto_cast len: int, allocator := context.allocator, loc := #caller_location) -> T {
	return make_aligned(T, len, align_of(E), allocator, loc);
}

@builtin
make_dynamic_array :: proc($T: typeid/[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, 0, 16, allocator, loc);
}

@builtin
make_dynamic_array_len :: proc($T: typeid/[dynamic]$E, auto_cast len: int, allocator := context.allocator, loc := #caller_location) -> T {
	return make_dynamic_array_len_cap(T, len, len, allocator, loc);
}

@builtin
make_dynamic_array_len_cap :: proc($T: typeid/[dynamic]$E, auto_cast len: int, auto_cast cap: int, allocator := context.allocator, loc := #caller_location) -> T {
	make_dynamic_array_error_loc(loc, len, cap);
	data := mem_alloc(size_of(E)*cap, align_of(E), allocator, loc);
	s := Raw_Dynamic_Array{data, len, cap, allocator};
	if data == nil && size_of(E) != 0 {
		s.len, s.cap = 0, 0;
	}
	// mem_zero(data, size_of(E)*cap);
	return transmute(T)s;
}

@builtin
make_map :: proc($T: typeid/map[$K]$E, auto_cast cap: int = 16, allocator := context.allocator, loc := #caller_location) -> T {
	make_map_expr_error_loc(loc, cap);
	context.allocator = allocator;

	m: T;
	reserve_map(&m, cap);
	return m;
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
};



@builtin
clear_map :: proc "contextless" (m: ^$T/map[$K]$V) {
	if m == nil {
		return;
	}
	raw_map := (^Raw_Map)(m);
	entries := (^Raw_Dynamic_Array)(&raw_map.entries);
	entries.len = 0;
	for _, i in raw_map.hashes {
		raw_map.hashes[i] = -1;
	}
}

@builtin
reserve_map :: proc(m: ^$T/map[$K]$V, capacity: int) {
	if m != nil {
		__dynamic_map_reserve(__get_map_header(m), capacity);
	}
}

// The delete_key built-in procedure deletes the element with the specified key (m[key]) from the map.
// If m is nil, or there is no such element, this procedure is a no-op
@builtin
delete_key :: proc(m: ^$T/map[$K]$V, key: K) {
	if m != nil {
		key := key;
		__dynamic_map_delete_key(__get_map_header(m), __get_map_hash(&key));
	}
}



@builtin
append_elem :: proc(array: ^$T/[dynamic]$E, arg: E, loc := #caller_location)  {
	if array == nil {
		return;
	}

	arg_len := 1;

	if cap(array) < len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^Raw_Dynamic_Array)(array);
		if size_of(E) != 0 {
			data := (^E)(a.data);
			assert(data != nil);
			val := arg;
			mem_copy(ptr_offset(data, a.len), &val, size_of(E));
		}
		a.len += arg_len;
	}
}

@builtin
append_elems :: proc(array: ^$T/[dynamic]$E, args: ..E, loc := #caller_location)  {
	if array == nil {
		return;
	}

	arg_len := len(args);
	if arg_len <= 0 {
		return;
	}


	if cap(array) < len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		a := (^Raw_Dynamic_Array)(array);
		if size_of(E) != 0 {
			data := (^E)(a.data);
			assert(data != nil);
			mem_copy(ptr_offset(data, a.len), &args[0], size_of(E) * arg_len);
		}
		a.len += arg_len;
	}
}

// The append_string built-in procedure appends a string to the end of a [dynamic]u8 like type
@builtin
append_elem_string :: proc(array: ^$T/[dynamic]$E/u8, arg: $A/string, loc := #caller_location) {
	args := transmute([]E)arg;
	append_elems(array=array, args=args, loc=loc);
}

@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil {
		return false;
	}

	old_cap := cap(array);
	if capacity <= old_cap {
		return true;
	}

	if array.allocator.procedure == nil {
		array.allocator = context.allocator;
	}
	assert(array.allocator.procedure != nil);


	ti := type_info_of(typeid_of(T));
	ti = type_info_base(ti);
	si := &ti.variant.(Type_Info_Struct);

	field_count := uintptr(len(si.offsets) - 3);

	if field_count == 0 {
		return true;
	}

	cap_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 1)*size_of(rawptr));
	assert(cap_ptr^ == old_cap);


	old_size := 0;
	new_size := 0;

	max_align := 0;
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem;
		max_align = max(max_align, type.align);

		old_size = align_forward_int(old_size, type.align);
		new_size = align_forward_int(new_size, type.align);

		old_size += type.size * old_cap;
		new_size += type.size * capacity;
	}

	old_size = align_forward_int(old_size, max_align);
	new_size = align_forward_int(new_size, max_align);

	old_data := (^rawptr)(array)^;

	new_data := array.allocator.procedure(
		array.allocator.data, .Alloc, new_size, max_align,
		nil, old_size, 0, loc,
	);
	if new_data == nil {
		return false;
	}


	cap_ptr^ = capacity;

	old_offset := 0;
	new_offset := 0;
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem;
		max_align = max(max_align, type.align);

		old_offset = align_forward_int(old_offset, type.align);
		new_offset = align_forward_int(new_offset, type.align);

		new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset));
		old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset));

		mem_copy(new_data_elem, old_data_elem, type.size * old_cap);

		(^rawptr)(uintptr(array) + i*size_of(rawptr))^ = new_data_elem;

		old_offset += type.size * old_cap;
		new_offset += type.size * capacity;
	}

	array.allocator.procedure(
		array.allocator.data, .Free, 0, max_align,
		old_data, old_size, 0, loc,
	);

	return true;
}

@builtin
append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, arg: E, loc := #caller_location) {
	if array == nil {
		return;
	}

	arg_len := 1;

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve_soa(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		ti := type_info_of(typeid_of(T));
		ti = type_info_base(ti);
		si := &ti.variant.(Type_Info_Struct);
		field_count := uintptr(len(si.offsets) - 3);

		if field_count == 0 {
			return;
		}

		data := (^rawptr)(array)^;

		len_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 0)*size_of(rawptr));


		soa_offset := 0;
		item_offset := 0;

		arg_copy := arg;
		arg_ptr := &arg_copy;

		max_align := 0;
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem;
			max_align = max(max_align, type.align);

			soa_offset  = align_forward_int(soa_offset, type.align);
			item_offset = align_forward_int(item_offset, type.align);

			dst := rawptr(uintptr(data) + uintptr(soa_offset) + uintptr(type.size * len_ptr^));
			src := rawptr(uintptr(arg_ptr) + uintptr(item_offset));
			mem_copy(dst, src, type.size);

			soa_offset  += type.size * cap(array);
			item_offset += type.size;
		}

		len_ptr^ += arg_len;
	}
}

@builtin
append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, args: ..E, loc := #caller_location) {
	if array == nil {
		return;
	}

	arg_len := len(args);
	if arg_len == 0 {
		return;
	}

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len);
		_ = reserve_soa(array, cap, loc);
	}
	arg_len = min(cap(array)-len(array), arg_len);
	if arg_len > 0 {
		ti := type_info_of(typeid_of(T));
		ti = type_info_base(ti);
		si := &ti.variant.(Type_Info_Struct);
		field_count := uintptr(len(si.offsets) - 3);

		if field_count == 0 {
			return;
		}

		data := (^rawptr)(array)^;

		len_ptr := cast(^int)rawptr(uintptr(array) + (field_count + 0)*size_of(rawptr));


		soa_offset := 0;
		item_offset := 0;

		args_ptr := &args[0];

		max_align := 0;
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem;
			max_align = max(max_align, type.align);

			soa_offset  = align_forward_int(soa_offset, type.align);
			item_offset = align_forward_int(item_offset, type.align);

			dst := uintptr(data) + uintptr(soa_offset) + uintptr(type.size * len_ptr^);
			src := uintptr(args_ptr) + uintptr(item_offset);
			for j in 0..<arg_len {
				d := rawptr(dst + uintptr(j*type.size));
				s := rawptr(src + uintptr(j*size_of(E)));
				mem_copy(d, s, type.size);
			}

			soa_offset  += type.size * cap(array);
			item_offset += type.size;
		}

		len_ptr^ += arg_len;
	}
}

// The append_string built-in procedure appends multiple strings to the end of a [dynamic]u8 like type
@builtin
append_string :: proc(array: ^$T/[dynamic]$E/u8, args: ..string, loc := #caller_location) {
	for arg in args {
		append(array = array, args = transmute([]E)(arg), loc = loc);
	}
}

// The append built-in procedure appends elements to the end of a dynamic array
@builtin append :: proc{append_elem, append_elems, append_elem_string};

// The append_soa built-in procedure appends elements to the end of an #soa dynamic array
@builtin append_soa :: proc{append_soa_elem, append_soa_elems};

@builtin
append_nothing :: proc(array: ^$T/[dynamic]$E, loc := #caller_location) {
	if array == nil {
		return;
	}
	resize(array, len(array)+1);
}


@builtin
insert_at_elem :: proc(array: ^$T/[dynamic]$E, index: int, arg: E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if array == nil {
		return;
	}
	n := len(array);
	m :: 1;
	resize(array, n+m, loc);
	if n+m <= len(array) {
		when size_of(E) != 0 {
			copy(array[index+m:], array[index:]);
			array[index] = arg;
		}
		ok = true;
	}
	return;
}

@builtin
insert_at_elems :: proc(array: ^$T/[dynamic]$E, index: int, args: ..E, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if array == nil {
		return;
	}
	if len(args) == 0 {
		ok = true;
		return;
	}

	n := len(array);
	m := len(args);
	resize(array, n+m, loc);
	if n+m <= len(array) {
		when size_of(E) != 0 {
			copy(array[index+m:], array[index:]);
			copy(array[index:], args);
		}
		ok = true;
	}
	return;
}

@builtin
insert_at_elem_string :: proc(array: ^$T/[dynamic]$E/u8, index: int, arg: string, loc := #caller_location) -> (ok: bool) #no_bounds_check {
	if array == nil {
		return;
	}
	if len(args) == 0 {
		ok = true;
		return;
	}

	n := len(array);
	m := len(args);
	resize(array, n+m, loc);
	if n+m <= len(array) {
		copy(array[index+m:], array[index:]);
		copy(array[index:], args);
		ok = true;
	}
	return;
}

@builtin insert_at :: proc{insert_at_elem, insert_at_elems, insert_at_elem_string};




@builtin
clear_dynamic_array :: proc "contextless" (array: ^$T/[dynamic]$E) {
	if array != nil {
		(^Raw_Dynamic_Array)(array).len = 0;
	}
}

@builtin
reserve_dynamic_array :: proc(array: ^$T/[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil {
		return false;
	}
	a := (^Raw_Dynamic_Array)(array);

	if capacity <= a.cap {
		return true;
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator;
	}
	assert(a.allocator.procedure != nil);

	old_size  := a.cap * size_of(E);
	new_size  := capacity * size_of(E);
	allocator := a.allocator;

	new_data := allocator.procedure(
		allocator.data, .Resize, new_size, align_of(E),
		a.data, old_size, 0, loc,
	);
	if new_data == nil {
		return false;
	}

	a.data = new_data;
	a.cap = capacity;
	return true;
}

@builtin
resize_dynamic_array :: proc(array: ^$T/[dynamic]$E, length: int, loc := #caller_location) -> bool {
	if array == nil {
		return false;
	}
	a := (^Raw_Dynamic_Array)(array);

	if length <= a.cap {
		a.len = max(length, 0);
		return true;
	}

	if a.allocator.procedure == nil {
		a.allocator = context.allocator;
	}
	assert(a.allocator.procedure != nil);

	old_size  := a.cap * size_of(E);
	new_size  := length * size_of(E);
	allocator := a.allocator;

	new_data := allocator.procedure(
		allocator.data, .Resize, new_size, align_of(E),
		a.data, old_size, 0, loc,
	);
	if new_data == nil {
		return false;
	}

	a.data = new_data;
	a.len = length;
	a.cap = length;
	return true;
}



@builtin
incl_elem :: proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ |= {elem};
	return s^;
}
@builtin
incl_elems :: proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems {
		s^ |= {elem};
	}
	return s^;
}
@builtin
incl_bit_set :: proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ |= other;
	return s^;
}
@builtin
excl_elem :: proc(s: ^$S/bit_set[$E; $U], elem: E) -> S {
	s^ &~= {elem};
	return s^;
}
@builtin
excl_elems :: proc(s: ^$S/bit_set[$E; $U], elems: ..E) -> S {
	for elem in elems {
		s^ &~= {elem};
	}
	return s^;
}
@builtin
excl_bit_set :: proc(s: ^$S/bit_set[$E; $U], other: S) -> S {
	s^ &~= other;
	return s^;
}

@builtin incl :: proc{incl_elem, incl_elems, incl_bit_set};
@builtin excl :: proc{excl_elem, excl_elems, excl_bit_set};


@builtin
card :: proc(s: $S/bit_set[$E; $U]) -> int {
	when size_of(S) == 1 {
		foreign { @(link_name="llvm.ctpop.i8")  count_ones :: proc(i: u8) -> u8 --- }
		return int(count_ones(transmute(u8)s));
	} else when size_of(S) == 2 {
		foreign { @(link_name="llvm.ctpop.i16") count_ones :: proc(i: u16) -> u16 --- }
		return int(count_ones(transmute(u16)s));
	} else when size_of(S) == 4 {
		foreign { @(link_name="llvm.ctpop.i32") count_ones :: proc(i: u32) -> u32 --- }
		return int(count_ones(transmute(u32)s));
	} else when size_of(S) == 8 {
		foreign { @(link_name="llvm.ctpop.i64") count_ones :: proc(i: u64) -> u64 --- }
		return int(count_ones(transmute(u64)s));
	} else when size_of(S) == 16 {
		foreign { @(link_name="llvm.ctpop.i128") count_ones :: proc(i: u128) -> u128 --- }
		return int(count_ones(transmute(u128)s));
	} else {
		#panic("Unhandled card bit_set size");
	}
}



@builtin
raw_array_data :: proc "contextless" (a: $P/^($T/[$N]$E)) -> ^E {
	return (^E)(a);
}
@builtin
raw_slice_data :: proc "contextless" (s: $S/[]$E) -> ^E {
	ptr := (transmute(Raw_Slice)s).data;
	return (^E)(ptr);
}
@builtin
raw_dynamic_array_data :: proc "contextless" (s: $S/[dynamic]$E) -> ^E {
	ptr := (transmute(Raw_Dynamic_Array)s).data;
	return (^E)(ptr);
}
@builtin
raw_string_data :: proc "contextless" (s: $S/string) -> ^u8 {
	return (transmute(Raw_String)s).data;
}

@builtin
raw_data :: proc{raw_array_data, raw_slice_data, raw_dynamic_array_data, raw_string_data};



@builtin
@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc(condition: bool, message := "", loc := #caller_location) {
	if !condition {
		proc(message: string, loc: Source_Code_Location) {
			p := context.assertion_failure_proc;
			if p == nil {
				p = default_assertion_failure_proc;
			}
			p("runtime assertion", message, loc);
		}(message, loc);
	}
}

@builtin
@(disabled=ODIN_DISABLE_ASSERT)
panic :: proc(message: string, loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("panic", message, loc);
}

@builtin
@(disabled=ODIN_DISABLE_ASSERT)
unimplemented :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	p("not yet implemented", message, loc);
}

@builtin
@(disabled=ODIN_DISABLE_ASSERT)
unreachable :: proc(message := "", loc := #caller_location) -> ! {
	p := context.assertion_failure_proc;
	if p == nil {
		p = default_assertion_failure_proc;
	}
	if message != "" {
		p("internal error", message, loc);
	} else {
		p("internal error", "entered unreachable code", loc);
	}
}
