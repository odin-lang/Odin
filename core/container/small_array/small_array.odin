package container_small_array

import "core:builtin"

Small_Array :: struct($N: int, $T: typeid) where N >= 0 {
	data: [N]T,
	len:  int,
}


len :: proc(a: $A/Small_Array) -> int {
	return a.len
}

cap :: proc(a: $A/Small_Array) -> int {
	return builtin.len(a.data)
}

space :: proc(a: $A/Small_Array) -> int {
	return builtin.len(a.data) - a.len
}

slice :: proc(a: ^$A/Small_Array($N, $T)) -> []T {
	return a.data[:a.len]
}


get :: proc(a: $A/Small_Array($N, $T), index: int) -> T {
	return a.data[index]
}
get_ptr :: proc(a: ^$A/Small_Array($N, $T), index: int) -> ^T {
	return &a.data[index]
}

set :: proc(a: ^$A/Small_Array($N, $T), index: int, item: T) {
	a.data[index] = item
}

resize :: proc(a: ^$A/Small_Array, length: int) {
	a.len = min(length, builtin.len(a.data))
}


push_back :: proc(a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.data[a.len] = item
		a.len += 1
		return true
	}
	return false
}

push_front :: proc(a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.len += 1
		data := slice(a)
		copy(data[1:], data[:])
		data[0] = item
		return true
	}
	return false
}

pop_back :: proc(a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[a.len-1]
	a.len -= 1
	return item
}

pop_front :: proc(a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[0]
	s := slice(a)
	copy(s[:], s[1:])
	a.len -= 1
	return item
}

pop_back_safe :: proc(a: ^$A/Small_Array($N, $T)) -> (item: T, ok: bool) {
	if N > 0 && a.len > 0 {
		item = a.data[a.len-1]
		a.len -= 1
		ok = true
	}
	return
}

pop_front_safe :: proc(a: ^$A/Small_Array($N, $T)) -> (T, bool) {
	if N > 0 && a.len > 0 {
		item = a.data[0]
		s := slice(a)
		copy(s[:], s[1:])
		a.len -= 1
		ok = true
	} 
	return
}

consume :: proc(a: ^$A/Small_Array($N, $T), count: int, loc := #caller_location) {
	assert(condition=a.len >= count, loc=loc)
	a.len -= count
}

clear :: proc(a: ^$A/Small_Array($N, $T)) {
	resize(a, 0)
}

push_back_elems :: proc(a: ^$A/Small_Array($N, $T), items: ..T) {
	n := copy(a.data[a.len:], items[:])
	a.len += n
}

append_elem  :: push_back
append_elems :: push_back_elems
push   :: proc{push_back, push_back_elems}
append :: proc{push_back, push_back_elems}