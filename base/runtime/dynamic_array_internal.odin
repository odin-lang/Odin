package runtime

__dynamic_array_make :: proc(array_: rawptr, elem_size, elem_align: int, len, cap: int, loc := #caller_location) {
	array := (^Raw_Dynamic_Array)(array_)
	array.allocator = context.allocator
	assert(array.allocator.procedure != nil)

	if cap > 0 {
		__dynamic_array_reserve(array_, elem_size, elem_align, cap, loc)
		array.len = len
	}
}

__dynamic_array_reserve :: proc(array_: rawptr, elem_size, elem_align: int, cap: int, loc := #caller_location) -> bool {
	array := (^Raw_Dynamic_Array)(array_)

	// NOTE(tetra, 2020-01-26): We set the allocator before earlying-out below, because user code is usually written
	// assuming that appending/reserving will set the allocator, if it is not already set.
	if array.allocator.procedure == nil {
		array.allocator = context.allocator
	}
	assert(array.allocator.procedure != nil)

	if cap <= array.cap {
		return true
	}

	old_size  := array.cap * elem_size
	new_size  := cap * elem_size
	allocator := array.allocator

	new_data, err := mem_resize(array.data, old_size, new_size, elem_align, allocator, loc)
	if err != nil {
		return false
	}
	if elem_size == 0 {
		array.data = raw_data(new_data)
		array.cap = cap
		return true
	} else if new_data != nil {
		array.data = raw_data(new_data)
		array.cap = min(cap, len(new_data)/elem_size)
		return true
	}
	return false
}

__dynamic_array_shrink :: proc(array_: rawptr, elem_size, elem_align: int, new_cap: int, loc := #caller_location) -> (did_shrink: bool) {
	array := (^Raw_Dynamic_Array)(array_)

	// NOTE(tetra, 2020-01-26): We set the allocator before earlying-out below, because user code is usually written
	// assuming that appending/reserving will set the allocator, if it is not already set.
	if array.allocator.procedure == nil {
		array.allocator = context.allocator
	}
	assert(array.allocator.procedure != nil)

	if new_cap > array.cap {
		return
	}

	new_cap := new_cap
	new_cap = max(new_cap, 0)
	old_size  := array.cap * elem_size
	new_size  := new_cap * elem_size
	allocator := array.allocator

	new_data, err := mem_resize(array.data, old_size, new_size, elem_align, allocator, loc)
	if err != nil {
		return
	}

	array.data = raw_data(new_data)
	array.len = min(new_cap, array.len)
	array.cap = new_cap
	return true
}

__dynamic_array_resize :: proc(array_: rawptr, elem_size, elem_align: int, len: int, loc := #caller_location) -> bool {
	array := (^Raw_Dynamic_Array)(array_)

	ok := __dynamic_array_reserve(array_, elem_size, elem_align, len, loc)
	if ok {
		array.len = len
	}
	return ok
}


__dynamic_array_append :: proc(array_: rawptr, elem_size, elem_align: int,
                               items: rawptr, item_count: int, loc := #caller_location) -> int {
	array := (^Raw_Dynamic_Array)(array_)

	if items == nil    {
		return 0
	}
	if item_count <= 0 {
		return 0
	}


	ok := true
	if array.cap < array.len+item_count {
		cap := 2 * array.cap + max(8, item_count)
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap, loc)
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok {
		return array.len
	}

	assert(array.data != nil)
	data := uintptr(array.data) + uintptr(elem_size*array.len)

	mem_copy(rawptr(data), items, elem_size * item_count)
	array.len += item_count
	return array.len
}

__dynamic_array_append_nothing :: proc(array_: rawptr, elem_size, elem_align: int, loc := #caller_location) -> int {
	array := (^Raw_Dynamic_Array)(array_)

	ok := true
	if array.cap < array.len+1 {
		cap := 2 * array.cap + max(8, 1)
		ok = __dynamic_array_reserve(array, elem_size, elem_align, cap, loc)
	}
	// TODO(bill): Better error handling for failed reservation
	if !ok {
		return array.len
	}

	assert(array.data != nil)
	data := uintptr(array.data) + uintptr(elem_size*array.len)
	mem_zero(rawptr(data), elem_size)
	array.len += 1
	return array.len
}
