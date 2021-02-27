package slice

import "intrinsics"
import "core:math/bits"
import "core:mem"

_ :: intrinsics;
_ :: bits;
_ :: mem;


swap :: proc(array: $T/[]$E, a, b: int, loc := #caller_location) {
	when size_of(E) > 8 {
		ptr_swap_non_overlapping(&array[a], &array[b], size_of(E));
	} else {
		array[a], array[b] = array[b], array[a];
	}
}


reverse :: proc(array: $T/[]$E) {
	n := len(array)/2;
	for i in 0..<n {
		a, b := i, len(array)-i-1;
		array[a], array[b] = array[b], array[a];
	}
}


contains :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	_, found := linear_search(array, value);
	return found;
}

linear_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_comparable(T) #no_bounds_check {
	for x, i in array {
		if x == key {
			return i, true;
		}
	}
	return -1, false;
}

linear_search_proc :: proc(array: $A/[]$T, f: proc(T) -> bool) -> (index: int, found: bool) #no_bounds_check {
	for x, i in array {
		if f(x) {
			return i, true;
		}
	}
	return -1, false;
}

binary_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_ordered(T) #no_bounds_check {

	n := len(array);
	switch n {
	case 0:
		return -1, false;
	case 1:
		if array[0] == key {
			return 0, true;
		}
		return -1, false;
	}

	lo, hi := 0, n-1;

	for array[hi] != array[lo] && key >= array[lo] && key <= array[hi] {
		when intrinsics.type_is_ordered_numeric(T) {
			// NOTE(bill): This is technically interpolation search
			m := lo + int((key - array[lo]) * T(hi - lo) / (array[hi] - array[lo]));
		} else {
			m := lo + (hi - lo)/2;
		}
		switch {
		case array[m] < key:
			lo = m + 1;
		case key < array[m]:
			hi = m - 1;
		case:
			return m, true;
		}
	}

	if key == array[lo] {
		return lo, true;
	}
	return -1, false;
}


equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_comparable(E) {
	if len(a) != len(b) {
		return false;
	}
	when intrinsics.type_is_simple_compare(E) {
		return mem.compare_ptrs(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0;
	} else {
		for i in 0..<len(a) {
			if a[i] != b[i] {
				return false;
			}
		}
		return true;
	}
}

simple_equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_simple_compare(E) {
	if len(a) != len(b) {
		return false;
	}
	return mem.compare_ptrs(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0;
}


has_prefix :: proc(array: $T/[]$E, needle: T) -> bool where intrinsics.type_is_comparable(E) {
	n := len(needle);
	if len(array) >= n {
		return equal(array[:n], needle);
	}
	return false;
}


has_suffix :: proc(array: $T/[]$E, needle: T) -> bool where intrinsics.type_is_comparable(E) {
	array := array;
	m, n := len(array), len(needle);
	if m >= n {
		return equal(array[m-n:], needle);
	}
	return false;
}

fill :: proc(array: $T/[]$E, value: T) {
	for _, i in array {
		array[i] = value;
	}
}

rotate_left :: proc(array: $T/[]$E, k: int) {
	n := len(array);
	m := mid %% n;
	k := n - m;
	p := raw_data(array);
	ptr_rotate(mid, ptr_add(p, mid), k);
}
rotate_right :: proc(array: $T/[]$E, k: int) {
	rotate_left(array, -k);
}

swap_with_slice :: proc(a, b: $T/[]$E, loc := #caller_location) {
	assert(len(a) == len(b), "miss matching slice lengths", loc);

	ptr_swap_non_overlapping(raw_data(a), raw_data(b), len(a)*size_of(E));
}

concatenate :: proc(a: []$T/[]$E, allocator := context.allocator) -> (res: T) {
	if len(a) == 0 {
		return;
	}
	n := 0;
	for s in a {
		n += len(s);
	}
	res = make(T, n, allocator);
	i := 0;
	for s in a {
		i += copy(res[i:], s);
	}
	return;
}

// copies slice into a new dynamic array
clone :: proc(a: $T/[]$E, allocator := context.allocator) -> []E {
	d := make([]E, len(a), allocator);
	copy(d[:], a);
	return d;
}


// copies slice into a new dynamic array
to_dynamic :: proc(a: $T/[]$E, allocator := context.allocator) -> [dynamic]E {
	d := make([dynamic]E, len(a), allocator);
	copy(d[:], a);
	return d;
}

// Converts slice into a dynamic array without cloning or allocating memory
into_dynamic :: proc(a: $T/[]$E) -> [dynamic]E {
	s := transmute(mem.Raw_Slice)a;
	d := mem.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = mem.nil_allocator(),
	};
	return transmute([dynamic]E)d;
}


length :: proc(a: $T/[]$E) -> int {
	return len(a);
}
is_empty :: proc(a: $T/[]$E) -> bool {
	return len(a) == 0;
}




split_at :: proc(array: $T/[]$E, index: int) -> (a, b: T) {
	return array[:index], array[index:];
}


split_first :: proc(array: $T/[]$E) -> (first: E, rest: T) {
	return array[0], array[1:];
}
split_last :: proc(array: $T/[]$E) -> (rest: T, last: E) {
	n := len(array)-1;
	return array[:n], array[n];
}

first :: proc(array: $T/[]$E) -> E {
	return array[0];
}
last :: proc(array: $T/[]$E) -> E {
	return array[len(array)-1];
}


first_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[0];
	}
	return nil;
}
last_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[len(array)-1];
	}
	return nil;
}

get :: proc(array: $T/[]$E, index: int) -> (value: E, ok: bool) {
	if 0 <= index && index < len(array) {
		value = array[index];
		ok = true;
	}
	return;
}
get_ptr :: proc(array: $T/[]$E, index: int) -> (value: ^E, ok: bool) {
	if 0 <= index && index < len(array) {
		value = &array[index];
		ok = true;
	}
	return;
}

as_ptr :: proc(array: $T/[]$E) -> ^E {
	return raw_data(array);
}


mapper :: proc(s: $S/[]$U, f: proc(U) -> $V, allocator := context.allocator) -> []V {
	r := make([]V, len(s), allocator);
	for v, i in s {
		r[i] = f(v);
	}
	return r;
}

reduce :: proc(s: $S/[]$U, initializer: $V, f: proc(V, U) -> V) -> V {
	r := initializer;
	for v in s {
		r = f(r, v);
	}
	return r;
}

filter :: proc(s: $S/[]$U, f: proc(U) -> bool, allocator := context.allocator) -> S {
	r := make([dynamic]S, 0, 0, allocator);
	for v in s {
		if f(v) {
			append(&r, v);
		}
	}
	return r[:];
}



dot_product :: proc(a, b: $S/[]$T) -> T
	where intrinsics.type_is_numeric(T) {
	if len(a) != len(b) {
		panic("slice.dot_product: slices of unequal length");
	}
	r: T;
	#no_bounds_check for _, i in a {
		r += a[i] * b[i];
	}
	return r;
}
