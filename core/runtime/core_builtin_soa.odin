package runtime

import "core:intrinsics"
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

raw_soa_footer_slice :: proc(array: ^$T/#soa[]$E) -> (footer: ^Raw_SOA_Footer_Slice) {
	if array == nil {
		return nil
	}
	field_count := uintptr(intrinsics.type_struct_field_count(E))
	footer = (^Raw_SOA_Footer_Slice)(uintptr(array) + field_count*size_of(rawptr))
	return
}
raw_soa_footer_dynamic_array :: proc(array: ^$T/#soa[dynamic]$E) -> (footer: ^Raw_SOA_Footer_Dynamic_Array) {
	if array == nil {
		return nil
	}
	field_count: uintptr
	when intrinsics.type_is_array(E) {
		field_count = len(E)
	} else {
		field_count = uintptr(intrinsics.type_struct_field_count(E))
	}
	footer = (^Raw_SOA_Footer_Dynamic_Array)(uintptr(array) + field_count*size_of(rawptr))
	return
}
raw_soa_footer :: proc{
	raw_soa_footer_slice,
	raw_soa_footer_dynamic_array,
}



@builtin
make_soa_aligned :: proc($T: typeid/#soa[]$E, length: int, alignment: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_second {
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

	field_count := uintptr(intrinsics.type_struct_field_count(E))

	total_size := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem
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
		type := si.types[i].variant.(Type_Info_Pointer).elem

		offset = align_forward_int(offset, max_align)

		(^uintptr)(data)^ = uintptr(new_data) + uintptr(offset)
		data += size_of(rawptr)
		offset += type.size * length
	}
	footer.len = length

	return
}

@builtin
make_soa_slice :: proc($T: typeid/#soa[]$E, length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_second {
	return make_soa_aligned(T, length, align_of(E), allocator, loc)
}

@builtin
make_soa_dynamic_array :: proc($T: typeid/#soa[dynamic]$E, allocator := context.allocator, loc := #caller_location) -> (array: T) {
	context.allocator = allocator
	reserve_soa(&array, DEFAULT_RESERVE_CAPACITY, loc)
	return
}

@builtin
make_soa_dynamic_array_len :: proc($T: typeid/#soa[dynamic]$E, auto_cast length: int, allocator := context.allocator, loc := #caller_location) -> (array: T) {
	context.allocator = allocator
	resize_soa(&array, length, loc)
	return
}

@builtin
make_soa_dynamic_array_len_cap :: proc($T: typeid/#soa[dynamic]$E, auto_cast length, capacity: int, allocator := context.allocator, loc := #caller_location) -> (array: T) {
	context.allocator = allocator
	if reserve_soa(&array, capacity, loc) {
		resize_soa(&array, length, loc)
	}
	return
}


@builtin
make_soa :: proc{
	make_soa_slice,
	make_soa_dynamic_array,
	make_soa_dynamic_array_len,
	make_soa_dynamic_array_len_cap,
}


@builtin
resize_soa :: proc(array: ^$T/#soa[dynamic]$E, length: int, loc := #caller_location) -> bool {
	if array == nil {
		return false
	}
	if !reserve_soa(array, length, loc) {
		return false
	}
	footer := raw_soa_footer(array)
	footer.len = length
	return true
}

@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, capacity: int, loc := #caller_location) -> bool {
	if array == nil {
		return false
	}

	old_cap := cap(array)
	if capacity <= old_cap {
		return true
	}

	if array.allocator.procedure == nil {
		array.allocator = context.allocator
	}
	assert(array.allocator.procedure != nil)

	footer := raw_soa_footer(array)
	if size_of(E) == 0 {
		footer.cap = capacity
		return true
	}

	ti := type_info_of(typeid_of(T))
	ti = type_info_base(ti)
	si := &ti.variant.(Type_Info_Struct)

	field_count: uintptr
	when intrinsics.type_is_array(E) {
		field_count = len(E)
	} else {
		field_count = uintptr(intrinsics.type_struct_field_count(E))
	}
	assert(footer.cap == old_cap)

	old_size := 0
	new_size := 0

	max_align :: align_of(E)
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem

		old_size += type.size * old_cap
		new_size += type.size * capacity

		old_size = align_forward_int(old_size, max_align)
		new_size = align_forward_int(new_size, max_align)
	}

	old_data := (^rawptr)(array)^

	new_bytes, err := array.allocator.procedure(
		array.allocator.data, .Alloc, new_size, max_align,
		nil, old_size, loc,
	)
	if new_bytes == nil || err != nil {
		return false
	}
	new_data := raw_data(new_bytes)


	footer.cap = capacity

	old_offset := 0
	new_offset := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Pointer).elem

		old_offset = align_forward_int(old_offset, max_align)
		new_offset = align_forward_int(new_offset, max_align)

		new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset))
		old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset))

		mem_copy(new_data_elem, old_data_elem, type.size * old_cap)

		(^rawptr)(uintptr(array) + i*size_of(rawptr))^ = new_data_elem

		old_offset += type.size * old_cap
		new_offset += type.size * capacity
	}

	_, err = array.allocator.procedure(
		array.allocator.data, .Free, 0, max_align,
		old_data, old_size, loc,
	)

	return true
}

@builtin
append_soa_elem :: proc(array: ^$T/#soa[dynamic]$E, arg: E, loc := #caller_location) {
	if array == nil {
		return
	}

	arg_len := 1

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len)
		_ = reserve_soa(array, cap, loc)
	}
	arg_len = min(cap(array)-len(array), arg_len)

	footer := raw_soa_footer(array)

	if size_of(E) > 0 && arg_len > 0 {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)
		field_count: uintptr
		when intrinsics.type_is_array(E) {
			field_count = len(E)
		} else {
			field_count = uintptr(intrinsics.type_struct_field_count(E))
		}

		data := (^rawptr)(array)^

		soa_offset := 0
		item_offset := 0

		arg_copy := arg
		arg_ptr := &arg_copy

		max_align :: align_of(E)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem

			soa_offset  = align_forward_int(soa_offset, max_align)
			item_offset = align_forward_int(item_offset, type.align)

			dst := rawptr(uintptr(data) + uintptr(soa_offset) + uintptr(type.size * footer.len))
			src := rawptr(uintptr(arg_ptr) + uintptr(item_offset))
			mem_copy(dst, src, type.size)

			soa_offset  += type.size * cap(array)
			item_offset += type.size
		}
	}
	footer.len += arg_len
}

@builtin
append_soa_elems :: proc(array: ^$T/#soa[dynamic]$E, args: ..E, loc := #caller_location) {
	if array == nil {
		return
	}

	arg_len := len(args)
	if arg_len == 0 {
		return
	}

	if cap(array) <= len(array)+arg_len {
		cap := 2 * cap(array) + max(8, arg_len)
		_ = reserve_soa(array, cap, loc)
	}
	arg_len = min(cap(array)-len(array), arg_len)

	footer := raw_soa_footer(array)
	if size_of(E) > 0 && arg_len > 0 {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)
		field_count := uintptr(intrinsics.type_struct_field_count(E))

		data := (^rawptr)(array)^

		soa_offset := 0
		item_offset := 0

		args_ptr := &args[0]

		max_align :: align_of(E)
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Pointer).elem

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
}


// The append_soa built-in procedure appends elements to the end of an #soa dynamic array
@builtin
append_soa :: proc{
	append_soa_elem,
	append_soa_elems,
}


delete_soa_slice :: proc(array: $T/#soa[]$E, allocator := context.allocator, loc := #caller_location) {
	when intrinsics.type_struct_field_count(E) != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		free(ptr, allocator, loc)
	}
}

delete_soa_dynamic_array :: proc(array: $T/#soa[dynamic]$E, loc := #caller_location) {
	when intrinsics.type_struct_field_count(E) != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		footer := raw_soa_footer(&array)
		free(ptr, footer.allocator, loc)
	}
}


@builtin
delete_soa :: proc{
	delete_soa_slice,
	delete_soa_dynamic_array,
}
