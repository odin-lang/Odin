package runtime

import "base:intrinsics"
_ :: intrinsics

/*

	SOA types are implemented with this sort of layout:

	SOA Fixed Array
	struct {
		f0: [N]T0,
		f1: [N]T1,
		f2: [N]T2,
	}

	SOA Slice
	struct {
		f0: ^T0,
		f1: ^T1,
		f2: ^T2,

		len: int,
	}

	SOA Dynamic Array
	struct {
		f0: ^T0,
		f1: ^T1,
		f2: ^T2,

		len: int,
		cap: int,
		allocator: Allocator,
	}

	A footer is used rather than a header purely to simplify access to the fields internally
	i.e. field index of the AOS == SOA

*/


Raw_SOA_Footer_Slice :: struct {
	len: int,
}

Raw_SOA_Footer_Dynamic_Array :: struct {
	len: int,
	cap: int,
	allocator: Allocator,
}

@(builtin, require_results)
raw_soa_footer_slice :: proc(array: ^$T/#soa[]$E) -> (footer: ^Raw_SOA_Footer_Slice) {
	if array == nil {
		return nil
	}
	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))
	footer = (^Raw_SOA_Footer_Slice)(uintptr(array) + field_count*size_of(rawptr))
	return
}
@(builtin, require_results)
raw_soa_footer_dynamic_array :: proc(array: ^$T/#soa[dynamic]$E) -> (footer: ^Raw_SOA_Footer_Dynamic_Array) {
	if array == nil {
		return nil
	}
	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))
	footer = (^Raw_SOA_Footer_Dynamic_Array)(uintptr(array) + field_count*size_of(rawptr))
	return
}
raw_soa_footer :: proc{
	raw_soa_footer_slice,
	raw_soa_footer_dynamic_array,
}



@(builtin, require_results)
make_soa_aligned :: proc($T: typeid/#soa[]$E, #any_int length, alignment: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	if length <= 0 {
		return
	}

	footer := raw_soa_footer(&array)
	if size_of(E) == 0 {
		footer.len = length
		return
	}

	max_align := max(alignment, align_of(E))

	ti := type_info_of(typeid_of(T))
	ti = type_info_base(ti)
	si := &ti.variant.(Type_Info_Struct)

	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

	total_size := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem
		total_size += type.size * length
		total_size = align_forward_int(total_size, max_align)
	}

	allocator := allocator
	if allocator.procedure == nil {
		allocator = context.allocator
	}
	assert(allocator.procedure != nil)

	new_bytes: []byte
	new_bytes, err = allocator.procedure(
		allocator.data, .Alloc, total_size, max_align,
		nil, 0, loc,
	)
	if new_bytes == nil || err != nil {
		return
	}
	new_data := raw_data(new_bytes)

	data := uintptr(&array)
	offset := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

		offset = align_forward_int(offset, max_align)

		(^uintptr)(data)^ = uintptr(new_data) + uintptr(offset)
		data += size_of(rawptr)
		offset += type.size * length
	}
	footer.len = length

	return
}

@(builtin, require_results)
make_soa_slice :: proc($T: typeid/#soa[]$E, #any_int length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	return make_soa_aligned(T, length, align_of(E), allocator, loc)
}

@(builtin, require_results)
make_soa_dynamic_array :: proc($T: typeid/#soa[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	reserve_soa(&array, 0, loc) or_return
	return array, nil
}

@(builtin, require_results)
make_soa_dynamic_array_len :: proc($T: typeid/#soa[dynamic]$E, #any_int length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	resize_soa(&array, length, loc) or_return
	return array, nil
}

@(builtin, require_results)
make_soa_dynamic_array_len_cap :: proc($T: typeid/#soa[dynamic]$E, #any_int length, capacity: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	reserve_soa(&array, capacity, loc) or_return
	resize_soa(&array, length, loc) or_return
	return array, nil
}


@builtin
make_soa :: proc{
	make_soa_slice,
	make_soa_dynamic_array,
	make_soa_dynamic_array_len,
	make_soa_dynamic_array_len_cap,
}


@builtin
resize_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	reserve_soa(array, length, loc) or_return
	footer := raw_soa_footer(array)
	footer.len = length
	return nil
}

@builtin
non_zero_resize_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	non_zero_reserve_soa(array, length, loc) or_return
	footer := raw_soa_footer(array)
	footer.len = length
	return nil
}

@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, true, loc)
}

@builtin
non_zero_reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, false, loc)
}

_reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, capacity: int, zero_memory: bool, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}

	old_cap := cap(array)
	if capacity <= old_cap {
		return nil
	}

	if array.allocator.procedure == nil {
		array.allocator = context.allocator
	}
	assert(array.allocator.procedure != nil)

	footer := raw_soa_footer(array)
	if size_of(E) == 0 {
		footer.cap = capacity
		return nil
	}

	ti := type_info_of(typeid_of(T))
	ti = type_info_base(ti)
	si := &ti.variant.(Type_Info_Struct)

	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))
	assert(footer.cap == old_cap)

	old_size := 0
	new_size := 0

	max_align :: align_of(E)
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

		old_size += type.size * old_cap
		new_size += type.size * capacity

		old_size = align_forward_int(old_size, max_align)
		new_size = align_forward_int(new_size, max_align)
	}

	old_data := (^rawptr)(array)^

	new_bytes := array.allocator.procedure(
		array.allocator.data, .Alloc if zero_memory else .Alloc_Non_Zeroed, new_size, max_align,
		nil, old_size, loc,
	) or_return
	new_data := raw_data(new_bytes)


	footer.cap = capacity

	old_offset := 0
	new_offset := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

		old_offset = align_forward_int(old_offset, max_align)
		new_offset = align_forward_int(new_offset, max_align)

		new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset))
		old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset))

		mem_copy(new_data_elem, old_data_elem, type.size * old_cap)

		(^rawptr)(uintptr(array) + i*size_of(rawptr))^ = new_data_elem

		old_offset += type.size * old_cap
		new_offset += type.size * capacity
	}

	array.allocator.procedure(
		array.allocator.data, .Free, 0, max_align,
		old_data, old_size, loc,
	) or_return

	return nil
}


@builtin
append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elem(array, true, arg, loc)
}

@builtin
non_zero_append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elem(array, false, arg, loc)
}

_append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}

	if cap(array) <= len(array) + 1 {
		// Same behavior as append_soa_elems but there's only one arg, so we always just add DEFAULT_DYNAMIC_ARRAY_CAPACITY.
		cap := 2 * cap(array) + DEFAULT_DYNAMIC_ARRAY_CAPACITY
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}

	footer := raw_soa_footer(array)

	if size_of(E) > 0 && cap(array)-len(array) > 0 {
		ti := type_info_of(T)
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)
		field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

		data := (^rawptr)(array)^

		soa_offset := 0
		item_offset := 0

		arg_copy := arg
		arg_ptr := &arg_copy

		max_align :: align_of(E)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			soa_offset  = align_forward_int(soa_offset, max_align)
			item_offset = align_forward_int(item_offset, type.align)

			dst := rawptr(uintptr(data) + uintptr(soa_offset) + uintptr(type.size * footer.len))
			src := rawptr(uintptr(arg_ptr) + uintptr(item_offset))
			mem_copy(dst, src, type.size)

			soa_offset  += type.size * cap(array)
			item_offset += type.size
		}
		footer.len += 1
		return 1, err
	}
	return 0, err
}

@builtin
append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elems(array, true, args=args, loc=loc)
}

@builtin
non_zero_append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, #no_broadcast args: ..E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	return _append_soa_elems(array, false, args=args, loc=loc)
}


_append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast args: []E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return
	}

	arg_len := len(args)
	if arg_len == 0 {
		return
	}

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(DEFAULT_DYNAMIC_ARRAY_CAPACITY, arg_len)
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}
	arg_len = min(cap(array)-len(array), arg_len)

	footer := raw_soa_footer(array)
	if size_of(E) > 0 && arg_len > 0 {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)
		field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

		data := (^rawptr)(array)^

		soa_offset := 0
		item_offset := 0

		args_ptr := &args[0]

		max_align :: align_of(E)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			soa_offset  = align_forward_int(soa_offset, max_align)
			item_offset = align_forward_int(item_offset, type.align)

			dst := uintptr(data) + uintptr(soa_offset) + uintptr(type.size * footer.len)
			src := uintptr(args_ptr) + uintptr(item_offset)
			for j in 0..<arg_len {
				d := rawptr(dst + uintptr(j*type.size))
				s := rawptr(src + uintptr(j*size_of(E)))
				mem_copy(d, s, type.size)
			}

			soa_offset  += type.size * cap(array)
			item_offset += type.size
		}
	}
	footer.len += arg_len
	return arg_len, err
}


// The append_soa built-in procedure appends elements to the end of an #soa dynamic array
@builtin
append_soa :: proc{
	append_soa_elem,
	append_soa_elems,
}


delete_soa_slice :: proc(array: $T/#soa[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		free(ptr, allocator, loc) or_return
	}
	return nil
}

delete_soa_dynamic_array :: proc(array: $T/#soa[dynamic]$E, loc := #caller_location) -> Allocator_Error {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		footer := raw_soa_footer(&array)
		free(ptr, footer.allocator, loc) or_return
	}
	return nil
}


@builtin
delete_soa :: proc{
	delete_soa_slice,
	delete_soa_dynamic_array,
}


clear_soa_dynamic_array :: proc(array: ^$T/#soa[dynamic]$E) {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		footer := raw_soa_footer(array)
		footer.len = 0
	}
}

@builtin
clear_soa :: proc{
	clear_soa_dynamic_array,
}

// Converts soa slice into a soa dynamic array without cloning or allocating memory
@(require_results)
into_dynamic_soa :: proc(array: $T/#soa[]$E) -> #soa[dynamic]E {
	d: #soa[dynamic]E
	footer := raw_soa_footer_dynamic_array(&d)
	footer^ = {
		cap = len(array),
		len = 0,
		allocator = nil_allocator(),
	}

	field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

	array := array
	dynamic_data := ([^]rawptr)(&d)[:field_count]
	slice_data   := ([^]rawptr)(&array)[:field_count]
	copy(dynamic_data, slice_data)

	return d
}

// `unordered_remove_soa` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the dynamic array by 1.
//
// Note: This is an O(1) operation.
// Note: If you the elements to remain in their order, use `ordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
unordered_remove_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)

		field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

		data := uintptr(array)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			offset := rawptr((^uintptr)(data)^ + uintptr(index*type.size))
			final := rawptr((^uintptr)(data)^ + uintptr((len(array)-1)*type.size))
			mem_copy(offset, final, type.size)
			data += size_of(rawptr)
		}
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}

// `ordered_remove_soa` removed the element at the specified `index` whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If you the elements do not have to remain in their order, prefer `unordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
ordered_remove_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)

		field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))

		data := uintptr(array)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			offset := (^uintptr)(data)^ + uintptr(index*type.size)
			length := type.size*(len(array) - index - 1)
			mem_copy(rawptr(offset), rawptr(offset + uintptr(type.size)), length)
			data += size_of(rawptr)
		}
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}
