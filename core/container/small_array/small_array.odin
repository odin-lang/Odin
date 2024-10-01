package container_small_array

import "base:builtin"
import "base:runtime"
_ :: runtime

Small_Array :: struct($N: int, $T: typeid) where N >= 0 {
	data: [N]T,
	len:  int,
}


len :: proc "contextless" (a: $A/Small_Array) -> int {
	return a.len
}

cap :: proc "contextless" (a: $A/Small_Array) -> int {
	return builtin.len(a.data)
}

space :: proc "contextless" (a: $A/Small_Array) -> int {
	return builtin.len(a.data) - a.len
}

slice :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> []T {
	return a.data[:a.len]
}


get :: proc "contextless" (a: $A/Small_Array($N, $T), index: int) -> T {
	return a.data[index]
}
get_ptr :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int) -> ^T {
	return &a.data[index]
}

get_safe :: proc(a: $A/Small_Array($N, $T), index: int) -> (T, bool) #no_bounds_check {
	if index < 0 || index >= a.len {
		return {}, false
	}
	return a.data[index], true
}

get_ptr_safe :: proc(a: ^$A/Small_Array($N, $T), index: int) -> (^T, bool) #no_bounds_check {
	if index < 0 || index >= a.len {
		return {}, false
	}
	return &a.data[index], true
}

set :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, item: T) {
	a.data[index] = item
}

resize :: proc "contextless" (a: ^$A/Small_Array, length: int) {
	a.len = min(length, builtin.len(a.data))
}


push_back :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.data[a.len] = item
		a.len += 1
		return true
	}
	return false
}

push_front :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T) -> bool {
	if a.len < cap(a^) {
		a.len += 1
		data := slice(a)
		copy(data[1:], data[:])
		data[0] = item
		return true
	}
	return false
}

pop_back :: proc "odin" (a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[a.len-1]
	a.len -= 1
	return item
}

pop_front :: proc "odin" (a: ^$A/Small_Array($N, $T), loc := #caller_location) -> T {
	assert(condition=(N > 0 && a.len > 0), loc=loc)
	item := a.data[0]
	s := slice(a)
	copy(s[:], s[1:])
	a.len -= 1
	return item
}

pop_back_safe :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> (item: T, ok: bool) {
	if N > 0 && a.len > 0 {
		item = a.data[a.len-1]
		a.len -= 1
		ok = true
	}
	return
}

pop_front_safe :: proc "contextless" (a: ^$A/Small_Array($N, $T)) -> (item: T, ok: bool) {
	if N > 0 && a.len > 0 {
		item = a.data[0]
		s := slice(a)
		copy(s[:], s[1:])
		a.len -= 1
		ok = true
	}
	return
}

consume :: proc "odin" (a: ^$A/Small_Array($N, $T), count: int, loc := #caller_location) {
	assert(condition=a.len >= count, loc=loc)
	a.len -= count
}

ordered_remove :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, a.len)
	if index+1 < a.len {
		copy(a.data[index:], a.data[index+1:])
	}
	a.len -= 1
}

unordered_remove :: proc "contextless" (a: ^$A/Small_Array($N, $T), index: int, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, a.len)
	n := a.len-1
	if index != n {
		a.data[index] = a.data[n]
	}
	a.len -= 1
}

clear :: proc "contextless" (a: ^$A/Small_Array($N, $T)) {
	resize(a, 0)
}

push_back_elems :: proc "contextless" (a: ^$A/Small_Array($N, $T), items: ..T) -> bool {
	if a.len + builtin.len(items) <= cap(a^) {
		n := copy(a.data[a.len:], items[:])
		a.len += n
		return true
	}
	return false
}

inject_at :: proc "contextless" (a: ^$A/Small_Array($N, $T), item: T, index: int) -> bool #no_bounds_check {
	if a.len < cap(a^) && index >= 0 && index <= len(a^) {
		a.len += 1
		for i := a.len - 1; i >= index + 1; i -= 1 {
			a.data[i] = a.data[i - 1]
		}
		a.data[index] = item
		return true
	}
	return false
}

append_elem  :: push_back
append_elems :: push_back_elems
push   :: proc{push_back, push_back_elems}
append :: proc{push_back, push_back_elems}
