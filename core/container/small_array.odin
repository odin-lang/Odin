package container

Small_Array :: struct(N: int, T: typeid) where N >= 0 {
	data: [N]T,
	len:  int,
}


small_array_len :: proc(a: $A/Small_Array) -> int {
	return a.len;
}

small_array_cap :: proc(a: $A/Small_Array) -> int {
	return len(a.data);
}

small_array_space :: proc(a: $A/Small_Array) -> int {
	return len(a.data) - a.len;
}

small_array_slice :: proc(a: ^$A/Small_Array($N, $T)) -> []T {
	return a.data[:a.len];
}


small_array_get :: proc(a: $A/Small_Array($N, $T), index: int, loc := #caller_location) -> T {
	return a.data[index];
}
small_array_get_ptr :: proc(a: $A/Small_Array($N, $T), index: int, loc := #caller_location) -> ^T {
	return &a.data[index];
}

small_array_set :: proc(a: ^$A/Small_Array($N, $T), index: int, item: T, loc := #caller_location) {
	a.data[index] = item;
}

small_array_resize :: proc(a: ^$A/Small_Array, length: int) {
	a.len = min(length, len(a.data));
}


small_array_push_back :: proc(a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < len(a.data) {
		a.len += 1;
		a.data[a.len-1] = item;
		return true;
	}
	return false;
}

small_array_push_front :: proc(a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < len(a.data) {
		a.len += 1;
		data := small_array_slice(a);
		copy(data[1:], data[:]);
		data[0] = item;
		return true;
	}
	return false;
}

small_array_pop_back :: proc(a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=a.len > 0, loc=loc);
	item := a.data[a.len-1];
	a.len -= 1;
	return item;
}

small_array_pop_font :: proc(a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=a.len > 0, loc=loc);
	item := a.data[0];
	s := small_array_slice(a);
	copy(s[:], s[1:]);
	a.len -= 1;
	return item;
}


small_array_consume :: proc(a: ^$A/Small_Array($N, $T), count: int, loc := #caller_location) {
	assert(condition=a.len >= count, loc=loc);
	a.len -= count;
}

small_array_clear :: proc(a: ^$A/Small_Array($N, $T)) {
	small_array_resize(a, 0);
}

small_array_push_back_elems :: proc(a: ^$A/Small_Array($N, $T), items: ..T) {
	n := copy(a.data[a.len:], items[:]);
	a.len += n;
}

small_array_push   :: proc{small_array_push_back, small_array_push_back_elems};
small_array_append :: proc{small_array_push_back, small_array_push_back_elems};

