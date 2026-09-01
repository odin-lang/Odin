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

// Note: When casting array to access footer/fields
// uintptr(array) lowers to LLVM ptrtoint and captures pointer provenance,
// whcih defeats #no_alias on the array in any code following (including in callers).
// Multipointer indexing lowers to GEP and doesn't capture, so prefer that throughout.

@(builtin, require_results)
raw_soa_footer_slice :: proc "contextless" (array: ^$T/#soa[]$E) -> (footer: ^Raw_SOA_Footer_Slice) {
	if array == nil {
		return nil
	}
	field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	footer = (^Raw_SOA_Footer_Slice)(&([^]byte)(array)[field_count*size_of(rawptr)])
	return
}
@(builtin, require_results)
raw_soa_footer_dynamic_array :: proc "contextless" (array: ^$T/#soa[dynamic]$E) -> (footer: ^Raw_SOA_Footer_Dynamic_Array) {
	if array == nil {
		return nil
	}
	field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	footer = (^Raw_SOA_Footer_Dynamic_Array)(&([^]byte)(array)[field_count*size_of(rawptr)])
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
		assert(allocator.procedure != nil)
	}

	new_bytes: []byte
	new_bytes, err = allocator.procedure(
		allocator.data, .Alloc, total_size, max_align,
		nil, 0, loc,
	)
	if new_bytes == nil || err != nil {
		return
	}
	new_data := raw_data(new_bytes)

	offset := 0
	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

		offset = align_forward_int(offset, max_align)

		([^]rawptr)(&array)[i] = rawptr(uintptr(new_data) + uintptr(offset))
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
	array.allocator = allocator
	reserve_soa(&array, 0, loc) or_return
	return array, nil
}

@(builtin, require_results)
make_soa_dynamic_array_len :: proc($T: typeid/#soa[dynamic]$E, #any_int length: int, allocator := context.allocator, loc := #caller_location) -> (array: T, err: Allocator_Error) #optional_allocator_error {
	context.allocator = allocator
	array.allocator = allocator
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
resize_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}

	footer := raw_soa_footer(array)
	old_len := footer.len
	old_cap := footer.cap

	if length > old_cap {
		reserve_soa(array, length, loc) or_return
	}

	// reserve_soa has zeroed any newly allocated [old_cap, length)
	// reused [old_len, min(old_cap, length)) still needs zeroing
	to_zero_end := min(old_cap, length)
	if size_of(E) > 0 && to_zero_end > old_len {
		ti := type_info_base(type_info_of(typeid_of(T)))
		si := &ti.variant.(Type_Info_Struct)

		field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)

		data := (^rawptr)(array)^

		soa_offset := 0
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			soa_offset = align_forward_int(soa_offset, align_of(E))

			mem_zero(rawptr(uintptr(data) + uintptr(soa_offset) + uintptr(type.size * old_len)), type.size * (to_zero_end - old_len))

			soa_offset += type.size * footer.cap
		}
	}

	footer.len = max(length, 0)
	return nil
}

@builtin
non_zero_resize_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int length: int, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}
	non_zero_reserve_soa(array, length, loc) or_return
	footer := raw_soa_footer(array)
	footer.len = max(length, 0)
	return nil
}

// `reserve_soa` will try to reserve memory of a passed SOA dynamic array to the requested element count (setting the `cap`).
//
// For maximizing performance it is recommended to avoid power-of-2 capacities
// when manually reserving memory for SOA arrays, more so for sizes above 512.
// For element types with several fields, prefer padding such capacities by at
// least the number of fields that fit in a CPU cache line.
// Modern cache lines are typically 64 (Intel/AMD/Arm64) or 128 bytes (Apple Silicon),
// so pad requested capacity with e.g. `128 / size_of(field)` (for the smallest field when field sizes differ),
// that is, prefer capacity of 4128 instead of 4096 for 4-byte fields.
@builtin
reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, true, loc)
}

@builtin
non_zero_reserve_soa :: proc(array: ^$T/#soa[dynamic]$E, #any_int capacity: int, loc := #caller_location) -> Allocator_Error {
	return _reserve_soa(array, capacity, false, loc)
}


// Note: capacity and performance
// Each field is stored in contiguous memory with stride between fields capacity * size_of(field) (+ alignment).
// When the stride is a multiple of 4KB, e.g. a power-of-2 capacity >= 1024 with 4-byte fields,
// every same-size field's cache line for a given index maps to the same L1 set, and
// per-element operations degrade (e.g. append_soa, inject_at_soa).
// It is worst past 8 same-size fields where the burst exceeds the common
// L1 8-way associativity and the fields collide (measured up to ~7-8x degradation
// on a type with 18 same-size fields; fields of different sizes advance through
// the sets at different rates, so they don't collide persistently).
// Common SoA iterative flows may also be affected, when the loop touches multiple fields
// and other hot data aliases the same L1 set.
// So, for types with several fields, prefer padding such capacities by at
// least the number of fields that fit in a CPU cache line.
// Modern cache lines are typically 64 (Intel/AMD/Arm64) or 128 bytes (Apple Silicon),
// so pad with e.g. 128 / size_of(field) (for the smallest field when field sizes differ),
// so prefer 4128 instead of 4096 for 4-byte fields. Setting cap to e.g. 4097 is NOT enough
// (it shifts field memory by only 4 bytes (same cache line) and fields keep colliding).
// Note: 4KB stride in the discussion above is the x86 L1 set period (32–48KB/8–12-way);
// Apple Silicon (128KB/8-way) has a 16KB period, so cap 4096 × 4 = 16KB stride
// is still pathological there and the recommended 128-byte pad fixes it.
// Note: struct size also plays a role, but the user facing padding recommendation
// on reserve_soa() will handle up to 256 fields (of 4 bytes) decently on 8-way caches.
// Note: Ideally, this should be handled internally by allowing allocated capacity to exceed requested capacity.
// This would break current runtime tests though, they explicitly test requested cap.
// Note: Capacities produced by append growth all the way from empty (2*cap + 8) are not affected.
_reserve_soa :: #force_no_inline proc(array: ^$T/#soa[dynamic]$E, capacity: int, zero_memory: bool, loc := #caller_location) -> Allocator_Error {
	if array == nil {
		return nil
	}

	old_cap := cap(array)
	if capacity <= old_cap {
		return nil
	}

	if array.allocator.procedure == nil {
		array.allocator = context.allocator
		assert(array.allocator.procedure != nil)
	}

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

	resize: if old_data != nil {

		new_bytes, resize_err := array.allocator.procedure(
			array.allocator.data, .Resize_Non_Zeroed, new_size, max_align,
			old_data, old_size, loc,
		)
		new_data := raw_data(new_bytes)

		#partial switch resize_err {
		case .Mode_Not_Implemented: break resize
		case .None: // continue resizing
		case: return resize_err
		}

		footer.cap = capacity

		old_offset := 0
		new_offset := 0

		// Correct data memory
		// from: |x x y y z z _ _ _|
		// to:   |x x _ y y _ z z _|

		// move old data to the end of the new allocation to avoid overlap
		old_data = rawptr(uintptr(new_data) + uintptr(new_size - old_size))
		mem_copy(old_data, new_data, old_size)

		// now:  |_ _ _ x x y y z z|

		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			old_offset = align_forward_int(old_offset, max_align)
			new_offset = align_forward_int(new_offset, max_align)

			new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset))
			old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset))

			old_size_elem := type.size * old_cap
			new_size_elem := type.size * capacity

			mem_copy(new_data_elem, old_data_elem, old_size_elem)

			([^]rawptr)(array)[i] = new_data_elem

			if zero_memory {
				mem_zero(rawptr(uintptr(new_data_elem) + uintptr(old_size_elem)), new_size_elem - old_size_elem)
			}

			old_offset += old_size_elem
			new_offset += new_size_elem
		}

		return nil
	}

	new_bytes := array.allocator.procedure(
		array.allocator.data, .Alloc if zero_memory else .Alloc_Non_Zeroed, new_size, max_align,
		nil, old_size, loc,
	) or_return
	new_data := raw_data(new_bytes)

	footer.cap = capacity

	old_offset := 0
	new_offset := 0

	// Correct data memory
	// from: |x x y y z z| ... |_ _ _ _ _ _ _ _ _|
	// to:                     |x x _ y y _ z z _|

	for i in 0..<field_count {
		type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

		old_offset = align_forward_int(old_offset, max_align)
		new_offset = align_forward_int(new_offset, max_align)

		new_data_elem := rawptr(uintptr(new_data) + uintptr(new_offset))
		old_data_elem := rawptr(uintptr(old_data) + uintptr(old_offset))

		mem_copy(new_data_elem, old_data_elem, type.size * old_cap)

		([^]rawptr)(array)[i] = new_data_elem

		old_offset += type.size * old_cap
		new_offset += type.size * capacity
	}

	if old_data != nil {
		array.allocator.procedure(
			array.allocator.data, .Free, 0, max_align,
			old_data, old_size, loc,
		) or_return
	}

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

_append_soa_elem :: proc(#no_alias array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast arg: E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}

	if cap(array) < len(array) + 1 {
		// Same behavior as append_soa_elems but there's only one arg, so we always just add DEFAULT_DYNAMIC_ARRAY_CAPACITY.
		cap := 2 * cap(array) + DEFAULT_DYNAMIC_ARRAY_CAPACITY
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}

	if size_of(E) > 0 && cap(array)-len(array) > 0 {
		footer := raw_soa_footer(array)
		// Field stores are generated by the compiler's #soa
		// element store lowering, specialized for E.
		// Note that #no_bounds_check is not optional, we write at index == len.
		#no_bounds_check {
			array[footer.len] = arg
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


_append_soa_elems :: proc(#no_alias array: ^$T/#soa[dynamic]$E, zero_memory: bool, #no_broadcast args: []E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return
	}

	arg_len := len(args)
	if arg_len == 0 {
		return
	}

	if cap(array) < len(array)+arg_len {
		cap := 2 * cap(array) + max(DEFAULT_DYNAMIC_ARRAY_CAPACITY, arg_len)
		err = _reserve_soa(array, cap, zero_memory, loc) // do not 'or_return' here as it could be a partial success
	}
	arg_len = min(cap(array)-len(array), arg_len)

	footer := raw_soa_footer(array)
	if size_of(E) > 0 && arg_len > 0 {
		FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
		// Advance len before the copy, soa_copy_from_slice needs the final len to be set
		when FIELD_COUNT != 0 {
			offset := footer.len
		}

		footer.len += arg_len

		when FIELD_COUNT == 0 {
			// do nothing
		} else when FIELD_COUNT <= 16 && ODIN_OPTIMIZATION_MODE <= .Size {
			// Use the compiler's #soa element store lowering, more compact at these field counts.
			#no_bounds_check for j in 0..<arg_len {
				array[offset + j] = args[j]
			}
		} else {
			intrinsics.soa_copy_from_slice(array, offset, args[:arg_len])
		}
	} else {
		footer.len += arg_len
	}
	return arg_len, err
}

// The append_soa built-in procedure appends elements to the end of an #soa dynamic array
@builtin
append_soa :: proc{
	append_soa_elem,
	append_soa_elems,
}


// `append_nothing_soa` appends an empty value to a dynamic SOA array. It returns `1, nil` if successful, and `0, err` when it was not possible,
// whatever `err` happens to be.
@builtin
append_nothing_soa :: proc(array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (n: int, err: Allocator_Error) #optional_allocator_error {
	if array == nil {
		return 0, nil
	}
	prev_len := len(array)
	resize_soa(array, len(array)+1, loc) or_return
	return len(array)-prev_len, nil
}


// `inject_at_elem_soa` injects an element in a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin
inject_at_elem_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, #no_broadcast arg: E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return
	}
	old_len := len(array)
	n := max(old_len, index)
	m :: 1
	new_len := n + m

	// The tail shift and the stored element cover every new slot,
	// except a gap of [old_len, index) when injecting past the end, which is
	// zeroed explicitly below.
	non_zero_resize_soa(array, new_len, loc) or_return

	when size_of(E) != 0 {
		ti := type_info_base(type_info_of(typeid_of(T)))
		si := &ti.variant.(Type_Info_Struct)

		FIELD_COUNT :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)

		for i in 0..<FIELD_COUNT {
			data := uintptr(([^]rawptr)(array)[i])
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			if index > old_len { // zero the gap left by injecting past the end
				mem_zero(rawptr(data + uintptr(old_len * type.size)), (index - old_len) * type.size)
			}

			src := data + uintptr(index * type.size)
			dst := data + uintptr((index + m) * type.size)
			mem_copy(rawptr(dst), rawptr(src), (n - index) * type.size)
		}

		// store the new element via the compiler's #soa element store lowering
		array[index] = arg
	}

	ok = true
	return
}

// `inject_at_elems_soa` injects multiple elements in a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin
inject_at_elems_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, #no_broadcast args: ..E, loc := #caller_location) -> (ok: bool, err: Allocator_Error) #no_bounds_check #optional_allocator_error {
	when !ODIN_NO_BOUNDS_CHECK {
		ensure(index >= 0, "Index must be positive.", loc)
	}
	if array == nil {
		return
	}
	if len(args) == 0 {
		ok = true
		return
	}

	old_len := len(array)
	n := max(old_len, index)
	m := len(args)
	new_len := n + m

	// The tail shift and the stored elements cover every new slot,
	// except a gap of [old_len, index) when injecting past the end, which is
	// zeroed explicitly below.
	non_zero_resize_soa(array, new_len, loc) or_return

	when size_of(E) != 0 {
		ti := type_info_base(type_info_of(typeid_of(T)))
		si := &ti.variant.(Type_Info_Struct)

		field_count := len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)

		args_ptr := &args[0]

		when !intrinsics.type_is_array(E) {
			// E's field offsets come from E's own RTTI (si describes the SOA
			// struct, whose fields are multipointers); basing on default struct
			// layout here would misplace the fields of #packed elements.
			se := &type_info_base(si.soa_base_type).variant.(Type_Info_Struct)
		}

		for i in 0..<field_count {
			data := uintptr(([^]rawptr)(array)[i])
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem
			when intrinsics.type_is_array(E) {
				// array lanes are uniform, so offsets are just i * stride
				item_offset := uintptr(i * type.size)
			} else {
				item_offset := se.offsets[i]
			}

			if index > old_len { // zero the gap left by injecting past the end
				mem_zero(rawptr(data + uintptr(old_len * type.size)), (index - old_len) * type.size)
			}

			src := data + uintptr(index * type.size)
			dst := data + uintptr((index + m) * type.size)
			mem_copy(rawptr(dst), rawptr(src), (n - index) * type.size)

			for j in 0..<len(args) {
				d := rawptr(src + uintptr(j*type.size))
				s := rawptr(uintptr(args_ptr) + item_offset + uintptr(j*size_of(E)))
				mem_copy(d, s, type.size)
			}
		}
	}

	ok = true
	return
}

// `inject_at_soa` injects something into a dynamic SOA array at a specified index and moves the previous elements after that index "across"
@builtin inject_at_soa :: proc{inject_at_elem_soa, inject_at_elems_soa}

@builtin
delete_soa_slice :: proc(array: $T/#soa[]$E, allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	field_count :: len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E)
	when field_count != 0 {
		array := array
		ptr := (^rawptr)(&array)^
		free(ptr, allocator, loc) or_return
	}
	return nil
}

@builtin
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

@builtin
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

// `pop_soa` will remove and return the end value of the #soa dynamic array `array` and reduces the length of `array` by 1.
//
// Note: If the #soa dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[len(array)-1]
	raw_soa_footer_dynamic_array(array).len -= 1
	return
}

// `pop_safe_soa` trys to remove and return the end value of the #soa dynamic array `array` and reduces the length of `array` by 1.
// If the operation is not possible, it will return false.
@builtin
pop_safe_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}
	res, ok = array[len(array)-1], true
	raw_soa_footer_dynamic_array(array).len -= 1
	return
}

// `pop_front_soa` will remove and return the first value of the #soa dynamic array `array` and reduces the length of `array` by 1,
// whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If the #soa dynamic array has no elements (`len(array) == 0`), this procedure will panic.
@builtin
pop_front_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, loc := #caller_location) -> (res: E) #no_bounds_check {
	assert(len(array) > 0, loc=loc)
	res = array[0]
	_ordered_remove_soa(array, 0)
	return
}

// `pop_front_safe_soa` trys to remove and return the first value of the #soa dynamic array `array` and reduces the
// length of `array` by 1, whilst keeping the order of the other elements.
// If the operation is not possible, it will return false.
//
// Note: This is an O(N) operation.
@builtin
pop_front_safe_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E) -> (res: E, ok: bool) #no_bounds_check {
	if len(array) == 0 {
		return
	}

	res, ok = array[0], true
	_ordered_remove_soa(array, 0)
	return
}

// `unordered_remove_soa` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the dynamic array by 1.
//
// Note: This is an O(1) operation.
// Note: If you want the elements to remain in their order, use `ordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
unordered_remove_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	if index+1 < len(array) {
		array[index] = array[len(array)-1]
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}

// `ordered_remove_soa` removed the element at the specified `index` whilst keeping the order of the other elements.
//
// Note: This is an O(N) operation.
// Note: If the elements do not have to remain in their order, prefer `unordered_remove_soa`.
// Note: If the index is out of bounds, this procedure will panic.
@builtin
ordered_remove_soa :: proc(#no_alias array: ^$T/#soa[dynamic]$E, #any_int index: int, loc := #caller_location) #no_bounds_check {
	bounds_check_error_loc(loc, index, len(array))
	_ordered_remove_soa(array, index)
}

// the unchecked body of ordered_remove_soa, shared with the front pops.
// index must already be known to be in bounds.
_ordered_remove_soa :: proc "contextless" (#no_alias array: ^$T/#soa[dynamic]$E, index: int) #no_bounds_check {
	if index+1 < len(array) {
		ti := type_info_of(typeid_of(T))
		ti = type_info_base(ti)
		si := &ti.variant.(Type_Info_Struct)

		l1 := len(array)-1
		field_count := uintptr(len(E) when intrinsics.type_is_array(E) else intrinsics.type_struct_field_count(E))
		for i in 0..<field_count {
			type := si.types[i].variant.(Type_Info_Multi_Pointer).elem

			offset := uintptr(([^]rawptr)(array)[i]) + uintptr(index*type.size)
			length := type.size*(l1 - index)
			mem_copy(rawptr(offset), rawptr(offset + uintptr(type.size)), length)
		}
	}
	raw_soa_footer_dynamic_array(array).len -= 1
}
