package container_xar

@(require) import "base:runtime"

Freelist_Array :: struct($T: typeid, $SHIFT: uint) where
	0 < SHIFT,
	SHIFT <= MAX_SHIFT,
	size_of(T) >= size_of(^T) {
	array:    Array(T, SHIFT),
	freelist: ^T,
}

freelist_init :: proc(x: ^$X/Freelist_Array($T, $SHIFT), allocator := context.allocator) {
	init(&x.array, allocator)
	x.freelist = nil
}

freelist_destroy :: proc(x: ^$X/Freelist_Array($T, $SHIFT)) {
	destroy(&x.array)
	x.freelist = nil
}

freelist_clear :: proc(x: ^$X/Freelist_Array($T, $SHIFT)) {
	clear(&x.array)
	x.freelist = nil
}

@(require_results)
freelist_push_with_index :: proc(x: ^$X/Freelist_Array($T, $SHIFT), value: T, loc := #caller_location) -> (ptr: ^T, index: int, err: runtime.Allocator_Error) {
	if x.freelist != nil {
		slot := x.freelist
		idx, found := freelist_linear_search(x, slot)
		assert(found)
		x.freelist = (^^T)(slot)^
		slot^ = value
		return slot, idx, nil
	}
	idx := x.array.len
	ptr = array_push_back_elem_and_get_ptr(&x.array, value, loc) or_return
	return ptr, idx, nil
}

@(require_results)
freelist_push :: proc(x: ^$X/Freelist_Array($T, $SHIFT), value: T, loc := #caller_location) -> (ptr: ^T, err: runtime.Allocator_Error) {
	ptr, _, err = freelist_push_with_index(x, value, loc)
	return
}

freelist_pop :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int, loc := #caller_location) -> T {
	item := array_get_ptr(&x.array, index, loc)
	result := item^
	(^^T)(item)^ = x.freelist
	x.freelist = item
	return result
}

freelist_release :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int, loc := #caller_location) {
	item := array_get_ptr(&x.array, index, loc)
	(^^T)(item)^ = x.freelist
	x.freelist = item
}

@(require_results)
freelist_linear_search :: proc(x: ^$X/Freelist_Array($T, $SHIFT), ptr: ^T) -> (index: int, found: bool) {
	base := 0
	for chunk, c in x.array.chunks {
		if chunk == nil {
			break
		}
		chunk_cap := 1 << (SHIFT + uint(c if c > 0 else 1) - 1)
		ptr_addr  := uintptr(ptr)
		chunk_start_addr := uintptr(chunk)
		chunk_end_addr   := chunk_start_addr + uintptr(chunk_cap * size_of(T))
		if chunk_start_addr <= ptr_addr && ptr_addr < chunk_end_addr {
			offset := int(ptr_addr - chunk_start_addr) / size_of(T)
			return base + offset, true
		}
		base += chunk_cap
	}
	return -1, false
}

@(require_results)
freelist_get :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int, loc := #caller_location) -> T {
	return array_get(&x.array, index, loc)
}

@(require_results)
freelist_get_ptr :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int, loc := #caller_location) -> ^T {
	return array_get_ptr(&x.array, index, loc)
}

freelist_set :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int, value: T, loc := #caller_location) {
	array_set(&x.array, index, value, loc)
}

@(require_results)
freelist_len :: proc(x: $X/Freelist_Array($T, $SHIFT)) -> int {
	return x.array.len
}

@(require_results)
freelist_cap :: proc(x: $X/Freelist_Array($T, $SHIFT)) -> int {
	return array_cap(x.array)
}

@(require_results)
freelist_is_freed :: proc(x: ^$X/Freelist_Array($T, $SHIFT), #any_int index: int) -> bool {
	ptr := array_get_ptr(&x.array, index)
	current := x.freelist
	for current != nil {
		if current == ptr {
			return true
		}
		current = (^^T)(current)^
	}
	return false
}

Freelist_Iterator :: struct($T: typeid, $SHIFT: uint) {
	freelist_array: ^Freelist_Array(T, SHIFT),
	idx:            int,
}

freelist_iterator :: proc(x: ^$X/Freelist_Array($T, $SHIFT)) -> Freelist_Iterator(T, SHIFT) {
	return {freelist_array = x, idx = 0}
}

@(require_results)
freelist_iterate_by_val :: proc(it: ^Freelist_Iterator($T, $SHIFT)) -> (val: T, idx: int, ok: bool) {
	for it.idx < it.freelist_array.array.len {
		if !freelist_is_freed(it.freelist_array, it.idx) {
			val = array_get(&it.freelist_array.array, it.idx)
			idx = it.idx
			it.idx += 1
			return val, idx, true
		}
		it.idx += 1
	}
	it.idx = 0
	return
}

@(require_results)
freelist_iterate_by_ptr :: proc(it: ^Freelist_Iterator($T, $SHIFT)) -> (val: ^T, idx: int, ok: bool) {
	for it.idx < it.freelist_array.array.len {
		if !freelist_is_freed(it.freelist_array, it.idx) {
			val = array_get_ptr(&it.freelist_array.array, it.idx)
			idx = it.idx
			it.idx += 1
			return val, idx, true
		}
		it.idx += 1
	}
	it.idx = 0
	return
}
