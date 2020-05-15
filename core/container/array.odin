package container

import "core:mem"
import "core:runtime"

Array :: struct(T: typeid) {
	data:      ^T,
	len:       int,
	cap:       int,
	allocator: mem.Allocator,
}

/*
array_init :: proc {
	array_init_none,
	array_init_len,
	array_init_len_cap,
}
array_init
array_delete
array_len
array_cap
array_space
array_slice
array_get
array_get_ptr
array_set
array_reserve
array_resize
array_push = array_append :: proc{
	array_push_back,
	array_push_back_elems,
}
array_push_front
array_pop_back
array_pop_front
array_consume
array_trim
array_clear
array_clone
array_set_capacity
array_grow
*/

array_init_none :: proc(a: ^$A/Array, allocator := context.allocator) {
	array_init_len(a, 0, allocator);
}
array_init_len :: proc(a: ^$A/Array, len: int, allocator := context.allocator) {
	array_init_len_cap(a, 0, 16, allocator);
}
array_init_len_cap :: proc(a: ^$A/Array($T), len: int, cap: int, allocator := context.allocator) {
	a.allocator = allocator;
	a.data = (^T)(mem.alloc(size_of(T)*cap, align_of(T), a.allocator));
	a.len = len;
	a.cap = cap;
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

array_cap_slice :: proc(a: $A/Array($T)) -> []T {
	s := mem.Raw_Slice{a.data, a.cap};
	return transmute([]T)s;
}

array_get :: proc(a: $A/Array($T), index: int, loc := #caller_location) -> T {
	runtime.bounds_check_error_loc(loc, index, array_len(a));
	return (^T)(uintptr(a.data) + size_of(T)*uintptr(index))^;
}
array_get_ptr :: proc(a: $A/Array($T), index: int, loc := #caller_location) -> ^T {
	runtime.bounds_check_error_loc(loc, index, array_len(a));
	return (^T)(uintptr(a.data) + size_of(T)*uintptr(index));
}

array_set :: proc(a: ^$A/Array($T), index: int, item: T, loc := #caller_location)  {
	runtime.bounds_check_error_loc(loc, index, array_len(a^));
	(^T)(uintptr(a.data) + size_of(T)*uintptr(index))^ = item;
}


array_reserve :: proc(a: ^$A/Array, capacity: int) {
	if capacity > a.len {
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

	a.len += 1;
	array_set(a, a.len-1, item);
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

array_pop_back :: proc(a: ^$A/Array($T), loc := #caller_location) -> T {
	assert(condition=a.len > 0, loc=loc);
	item := array_get(a^, a.len-1);
	a.len -= 1;
	return item;
}

array_pop_front :: proc(a: ^$A/Array($T), loc := #caller_location) -> T {
	assert(condition=a.len > 0, loc=loc);
	item := array_get(a^, 0);
	s := array_slice(a^);
	copy(s[:], s[1:]);
	a.len -= 1;
	return item;
}


array_consume :: proc(a: ^$A/Array($T), count: int, loc := #caller_location) {
	assert(condition=a.len >= count, loc=loc);
	a.len -= count;
}


array_trim :: proc(a: ^$A/Array($T)) {
	array_set_capacity(a, a.len);
}

array_clear :: proc(a: ^$A/Array($T)) {
	array_resize(a, 0);
}

array_clone :: proc(a: $A/Array($T), allocator := context.allocator) -> A {
	res: A;
	array_init(&res, array_len(a), array_len(a), allocator);
	copy(array_slice(res), array_slice(a));
	return res;
}

array_push_back_elems :: proc(a: ^$A/Array($T), items: ..T) {
	if array_space(a^) < len(items) {
		array_grow(a, a.len + len(items));
	}
	offset := a.len;
	data := array_cap_slice(a^);
	n := copy(data[a.len:], items);
	a.len += n;
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
		if a.allocator.procedure == nil {
			a.allocator = context.allocator;
		}
		new_data = (^T)(mem.alloc(size_of(T)*new_capacity, align_of(T), a.allocator));
		if new_data != nil {
			mem.copy(new_data, a.data, size_of(T)*a.len);
		}
	}
	mem.free(a.data, a.allocator);
	a.data = new_data;
	a.cap = new_capacity;
}
array_grow :: proc(a: ^$A/Array, min_capacity: int = 0) {
	new_capacity := max(array_len(a^)*2 + 8, min_capacity);
	array_set_capacity(a, new_capacity);
}
