package container

import "core:mem"

Array :: struct(T: typeid) {
	data:      ^T,
	len:       int,
	cap:       int,
	allocator: mem.Allocator,
}

array_init_none :: proc(a: ^$A/Array, allocator := context.allocator) {
	array_init_len(a, 0, allocator);
}
array_init_len :: proc(a: ^$A/Array, len: int, allocator := context.allocator) {
	array_init_len_cap(a, 0, 16, allocator);
}
array_init_len_cap :: proc(a: ^$A/Array($T), len: int, cap: int, allocator := context.allocator) {
	a.data = (^T)(mem.alloc(size_of(T)*cap, align_of(T), allocator));
	a.len = len;
	a.cap = cap;
	a.allocator = allocator;
}

array_init :: proc{array_init_none, array_init_len, array_init_len_cap};

array_delete :: proc(a: $A/Array) {
	mem.free(a.data, a.allocator);
}

array_len :: proc(a: $A/Array) -> int {
	return a.len;
}

array_cap :: proc(a: $A/Array) -> int {
	return a.cap;
}

array_space :: proc(a: $A/Array) -> int {
	return a.cap - a.len;
}

array_slice :: proc(a: $A/Array($T)) -> []T {
	s := mem.Raw_Slice{a.data, a.len};
	return transmute([]T)s;
}


array_get :: proc(a: $A/Array($T), index: int) -> T {
	assert(uint(index) < a.len);
	return (^T)(uintptr(a.data) + size_of(T)*uintptr(index))^;
}
array_get_ptr :: proc(a: $A/Array($T), index: int) -> ^T {
	assert(uint(index) < a.len);
	return (^T)(uintptr(a.data) + size_of(T)*uintptr(index));
}

array_set :: proc(a: ^$A/Array($T), index: int, item: T)  {
	assert(uint(index) < a.len);
	(^T)(uintptr(a.data) + size_of(T)*uintptr(index))^ = item;
}


array_reserve :: proc(a: ^$A/Array, capacity: int) {
	if capacity > a.size {
		array_set_capacity(a, capacity);
	}
}

array_resize :: proc(a: ^$A/Array, length: int) {
	if length > a.len {
		array_set_capacity(a, length);
	}
	a.len = length;
}



array_push_back :: proc(a: ^$A/Array($T), item: T) {
	if array_space(a^) == 0 {
		array_grow(a);
	}

	a.size += 1;
	array_set(a, a.size, item);
}

array_push_front :: proc(a: ^$A/Array($T), item: T) {
	if array_space(a^) == 0 {
		array_grow(a);
	}

	a.len += 1;
	data := array_slice(a^);
	copy(data[1:], data[:]);
	data[0] = item;
}

array_pop_back :: proc(a: ^$A/Array($T)) -> T {
	assert(a.len > 0);
	item := array_get(a^, a.len-1);
	a.len -= 1;
	return item;
}

array_pop_font :: proc(a: ^$A/Array($T)) -> T {
	assert(a.len > 0);
	item := array_get(a^, 0);
	s := array_slice(a^);
	copy(s[:], s[1:]);
	a.len -= 1;
	return item;
}


array_consume :: proc(a: ^$A/Array($T), count: int) {
	assert(a.size >= count);
	a.size -= count;
}


array_trim :: proc(a: ^$A/Array($T)) {
	array_set_capacity(a, a.len);
}

array_clear :: proc(q: ^$Q/Queue($T)) {
	array_resize(q, 0);
}


array_push_back_elems :: proc(a: ^$A/Array($T), items: ..T) {
	if array_space(a^) < len(items) {
		array_grow(a, a.size + len(items));
	}
	offset := a.len;
	a.len += len(items);
	data := array_slice(a^);
	n := copy(data[offset:], items);
	a.len = offset + n;
}

array_push   :: proc{array_push_back, array_push_back_elems};
array_append :: proc{array_push_back, array_push_back_elems};

array_set_capacity :: proc(a: ^$A/Array($T), new_capacity: int) {
	if new_capacity == a.cap {
		return;
	}

	if new_capacity < a.len {
		array_resize(a, new_capacity);
	}

	new_data: ^T;
	if new_capacity > 0 {
		new_data = (^T)(mem.alloc(size_of(T)*new_capacity, align_of(T), a.allocator));
		if new_data != nil {
			mem.copy(new_data, a.data, size_of(T)*a.len);
		}
	}
	mem.free(a.data);
	a.data = new_data;
	a.cap = new_capacity;
}
array_grow :: proc(a: ^$A/Array, min_capacity: int = 0) {
	new_capacity := max(len(a.data)*2 + 8, min_capacity);
	array_set_capacity(a, new_capacity);
}
