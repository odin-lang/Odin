package slice

import "core:intrinsics"
import "core:builtin"
import "core:math/bits"
import "core:mem"

_ :: intrinsics
_ :: builtin
_ :: bits
_ :: mem

/*
	Turn a pointer and a length into a slice.
*/
from_ptr :: proc "contextless" (ptr: ^$T, count: int) -> []T {
    return ([^]T)(ptr)[:count]
}

/*
	Turn a pointer and a length into a byte slice.
*/
bytes_from_ptr :: proc "contextless" (ptr: rawptr, byte_count: int) -> []byte {
    return ([^]byte)(ptr)[:byte_count]
}

/*
	Turn a slice into a byte slice.

	See `slice.reinterpret` to go the other way.
*/
to_bytes :: proc "contextless" (s: []$T) -> []byte {
	return ([^]byte)(raw_data(s))[:len(s) * size_of(T)]
}

/*
	Turn a slice of one type, into a slice of another type.

	Only converts the type and length of the slice itself.
	The length is rounded down to the nearest whole number of items.

	```
	large_items := []i64{1, 2, 3, 4}
	small_items := slice.reinterpret([]i32, large_items)
	assert(len(small_items) == 8)
	```
	```
	small_items := []byte{1, 0, 0, 0, 0, 0, 0, 0,
	                      2, 0, 0, 0}
	large_items := slice.reinterpret([]i64, small_items)
	assert(len(large_items) == 1) // only enough bytes to make 1 x i64; two would need at least 8 bytes.
	```
*/
reinterpret :: proc "contextless" ($T: typeid/[]$U, s: []$V) -> []U {
	bytes := to_bytes(s)
	n := len(bytes) / size_of(U)
	return ([^]U)(raw_data(bytes))[:n]
}


swap :: proc(array: $T/[]$E, a, b: int) {
	when size_of(E) > 8 {
		ptr_swap_non_overlapping(&array[a], &array[b], size_of(E))
	} else {
		array[a], array[b] = array[b], array[a]
	}
}

swap_between :: proc(a, b: $T/[]$E) {
	n := builtin.min(len(a), len(b))
	if n >= 0 {
		ptr_swap_overlapping(&a[0], &b[0], size_of(E)*n)
	}	
}


reverse :: proc(array: $T/[]$E) {
	n := len(array)/2
	for i in 0..<n {
		a, b := i, len(array)-i-1
		array[a], array[b] = array[b], array[a]
	}
}


contains :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	_, found := linear_search(array, value)
	return found
}

linear_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_comparable(T) #no_bounds_check {
	for x, i in array {
		if x == key {
			return i, true
		}
	}
	return -1, false
}

linear_search_proc :: proc(array: $A/[]$T, f: proc(T) -> bool) -> (index: int, found: bool) #no_bounds_check {
	for x, i in array {
		if f(x) {
			return i, true
		}
	}
	return -1, false
}

binary_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_ordered(T) #no_bounds_check {

	n := len(array)
	switch n {
	case 0:
		return -1, false
	case 1:
		if array[0] == key {
			return 0, true
		}
		return -1, false
	}

	lo, hi := 0, n-1

	for array[hi] != array[lo] && key >= array[lo] && key <= array[hi] {
		when intrinsics.type_is_ordered_numeric(T) {
			// NOTE(bill): This is technically interpolation search
			m := lo + int((key - array[lo]) * T(hi - lo) / (array[hi] - array[lo]))
		} else {
			m := lo + (hi - lo)/2
		}
		switch {
		case array[m] < key:
			lo = m + 1
		case key < array[m]:
			hi = m - 1
		case:
			return m, true
		}
	}

	if key == array[lo] {
		return lo, true
	}
	return -1, false
}


equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_comparable(E) {
	if len(a) != len(b) {
		return false
	}
	when intrinsics.type_is_simple_compare(E) {
		return mem.compare_ptrs(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
	} else {
		for i in 0..<len(a) {
			if a[i] != b[i] {
				return false
			}
		}
		return true
	}
}

simple_equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_simple_compare(E) {
	if len(a) != len(b) {
		return false
	}
	return mem.compare_ptrs(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
}


has_prefix :: proc(array: $T/[]$E, needle: E) -> bool where intrinsics.type_is_comparable(E) {
	n := len(needle)
	if len(array) >= n {
		return equal(array[:n], needle)
	}
	return false
}


has_suffix :: proc(array: $T/[]$E, needle: E) -> bool where intrinsics.type_is_comparable(E) {
	array := array
	m, n := len(array), len(needle)
	if m >= n {
		return equal(array[m-n:], needle)
	}
	return false
}

fill :: proc(array: $T/[]$E, value: E) #no_bounds_check {
	if len(array) <= 0 {
		return
	}
	array[0] = value
	for i := 1; i < len(array); i *= 2 {
		copy(array[i:], array[:i])
	}
}

rotate_left :: proc(array: $T/[]$E, mid: int) {
	n := len(array)
	m := mid %% n
	k := n - m
	p := raw_data(array)
	ptr_rotate(mid, ptr_add(p, mid), k)
}
rotate_right :: proc(array: $T/[]$E, k: int) {
	rotate_left(array, -k)
}

swap_with_slice :: proc(a, b: $T/[]$E, loc := #caller_location) {
	assert(len(a) == len(b), "miss matching slice lengths", loc)

	ptr_swap_non_overlapping(raw_data(a), raw_data(b), len(a)*size_of(E))
}

concatenate :: proc(a: []$T/[]$E, allocator := context.allocator) -> (res: T) {
	if len(a) == 0 {
		return
	}
	n := 0
	for s in a {
		n += len(s)
	}
	res = make(T, n, allocator)
	i := 0
	for s in a {
		i += copy(res[i:], s)
	}
	return
}

// copies a slice into a new slice
clone :: proc(a: $T/[]$E, allocator := context.allocator) -> []E {
	d := make([]E, len(a), allocator)
	copy(d[:], a)
	return d
}


// copies slice into a new dynamic array
clone_to_dynamic :: proc(a: $T/[]$E, allocator := context.allocator) -> [dynamic]E {
	d := make([dynamic]E, len(a), allocator)
	copy(d[:], a)
	return d
}
to_dynamic :: clone_to_dynamic

// Converts slice into a dynamic array without cloning or allocating memory
into_dynamic :: proc(a: $T/[]$E) -> [dynamic]E {
	s := transmute(mem.Raw_Slice)a
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = mem.nil_allocator(),
	}
	return transmute([dynamic]E)d
}


length :: proc(a: $T/[]$E) -> int {
	return len(a)
}
is_empty :: proc(a: $T/[]$E) -> bool {
	return len(a) == 0
}




split_at :: proc(array: $T/[]$E, index: int) -> (a, b: T) {
	return array[:index], array[index:]
}


split_first :: proc(array: $T/[]$E) -> (first: E, rest: T) {
	return array[0], array[1:]
}
split_last :: proc(array: $T/[]$E) -> (rest: T, last: E) {
	n := len(array)-1
	return array[:n], array[n]
}

first :: proc(array: $T/[]$E) -> E {
	return array[0]
}
last :: proc(array: $T/[]$E) -> E {
	return array[len(array)-1]
}


first_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[0]
	}
	return nil
}
last_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[len(array)-1]
	}
	return nil
}

get :: proc(array: $T/[]$E, index: int) -> (value: E, ok: bool) {
	if 0 <= index && index < len(array) {
		value = array[index]
		ok = true
	}
	return
}
get_ptr :: proc(array: $T/[]$E, index: int) -> (value: ^E, ok: bool) {
	if 0 <= index && index < len(array) {
		value = &array[index]
		ok = true
	}
	return
}

as_ptr :: proc(array: $T/[]$E) -> [^]E {
	return raw_data(array)
}


mapper :: proc(s: $S/[]$U, f: proc(U) -> $V, allocator := context.allocator) -> []V {
	r := make([]V, len(s), allocator)
	for v, i in s {
		r[i] = f(v)
	}
	return r
}

reduce :: proc(s: $S/[]$U, initializer: $V, f: proc(V, U) -> V) -> V {
	r := initializer
	for v in s {
		r = f(r, v)
	}
	return r
}

filter :: proc(s: $S/[]$U, f: proc(U) -> bool, allocator := context.allocator) -> S {
	r := make([dynamic]U, 0, 0, allocator)
	for v in s {
		if f(v) {
			append(&r, v)
		}
	}
	return r[:]
}

scanner :: proc (s: $S/[]$U, initializer: $V, f: proc(V, U) -> V, allocator := context.allocator) -> []V {
	if len(s) == 0 { return {} }

	res := make([]V, len(s), allocator)
	p := as_ptr(s)
	q := as_ptr(res)
	r := initializer

	for l := len(s); l > 0; l -= 1 {
		r = f(r, p[0])
		q[0] = r
		p = p[1:]
		q = q[1:]
	}

	return res
}


min :: proc(s: $S/[]$T) -> (res: T, ok: bool) where intrinsics.type_is_ordered(T) #optional_ok {
	if len(s) != 0 {
		res = s[0]
		ok = true
		for v in s[1:] {
			res = builtin.min(res, v)
		}
	}
	return
}
max :: proc(s: $S/[]$T) -> (res: T, ok: bool) where intrinsics.type_is_ordered(T) #optional_ok {
	if len(s) != 0 {
		res = s[0]
		ok = true
		for v in s[1:] {
			res = builtin.max(res, v)
		}
	}
	return
}

min_max :: proc(s: $S/[]$T) -> (min, max: T, ok: bool) where intrinsics.type_is_ordered(T) {
	if len(s) != 0 {
		min, max = s[0], s[0]
		ok = true
		for v in s[1:] {
			min = builtin.min(min, v)
			max = builtin.max(max, v)
		}
	}
	return
}

any_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			return true
		}
	}
	return false
}

none_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			return false
		}
	}
	return true
}

all_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
	if len(s) == 0 {
		return false
	}
	for v in s {
		if v != value {
			return false
		}
	}
	return true
}


any_of_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> bool {
	for v in s {
		if f(v) {
			return true
		}
	}
	return false
}

none_of_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> bool {
	for v in s {
		if f(v) {
			return false
		}
	}
	return true
}

all_of_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> bool {
	if len(s) == 0 {
		return false
	}
	for v in s {
		if !f(v) {
			return false
		}
	}
	return true
}


count :: proc(s: $S/[]$T, value: T) -> (n: int) where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			n += 1
		}
	}
	return
}

count_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> (n: int) {
	for v in s {
		if f(v) {
			n += 1
		}
	}
	return
}


dot_product :: proc(a, b: $S/[]$T) -> (r: T, ok: bool)
	where intrinsics.type_is_numeric(T) {
	if len(a) != len(b) {
		return
	}
	#no_bounds_check for _, i in a {
		r += a[i] * b[i]
	}
	return r, true
}
