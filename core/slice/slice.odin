package slice

import "base:intrinsics"
import "base:builtin"
import "core:math/bits"
import "base:runtime"

_ :: intrinsics
_ :: builtin
_ :: bits
_ :: runtime

/*
	Turn a pointer and a length into a slice.
*/
@(require_results)
from_ptr :: proc "contextless" (ptr: ^$T, count: int) -> []T {
	return ([^]T)(ptr)[:count]
}

/*
	Turn a pointer and a length into a byte slice.
*/
@(require_results)
bytes_from_ptr :: proc "contextless" (ptr: rawptr, byte_count: int) -> []byte {
	return ([^]byte)(ptr)[:byte_count]
}

/*
	Turn a slice into a byte slice.

	See `slice.reinterpret` to go the other way.
*/
@(require_results)
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
@(require_results)
reinterpret :: proc "contextless" ($T: typeid/[]$U, s: []$V) -> []U {
	when size_of(U) == 0 || size_of(V) == 0 {
		return nil
	} else {
		bytes := to_bytes(s)
		n := len(bytes) / size_of(U)
		return ([^]U)(raw_data(bytes))[:n]
	}
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
		swap(array, i, len(array)-i-1)
	}
}


@(require_results)
contains :: proc(array: $T/[]$E, value: E) -> bool where intrinsics.type_is_comparable(E) {
	_, found := linear_search(array, value)
	return found
}

@(require_results)
linear_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_comparable(T) #no_bounds_check {
	for x, i in array {
		if x == key {
			return i, true
		}
	}
	return -1, false
}

@(require_results)
linear_search_proc :: proc(array: $A/[]$T, f: proc(T) -> bool) -> (index: int, found: bool) #no_bounds_check {
	for x, i in array {
		if f(x) {
			return i, true
		}
	}
	return -1, false
}

/*
	Binary search searches the given slice for the given element.
	If the slice is not sorted, the returned index is unspecified and meaningless.

	If the value is found then the returned int is the index of the matching element.
	If there are multiple matches, then any one of the matches could be returned.

	If the value is not found then the returned int is the index where a matching
	element could be inserted while maintaining sorted order.

	# Examples

	Looks up a series of four elements. The first is found, with a
	uniquely determined position; the second and third are not
	found; the fourth could match any position in `[1, 4]`.

	```
	index: int
	found: bool

	s := []i32{0, 1, 1, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55}

	index, found = slice.binary_search(s, 13)
	assert(index == 9 && found == true)

	index, found = slice.binary_search(s, 4)
	assert(index == 7 && found == false)

	index, found = slice.binary_search(s, 100)
	assert(index == 13 && found == false)

	index, found = slice.binary_search(s, 1)
	assert(index >= 1 && index <= 4 && found == true)
	```

	For slices of more complex types see: binary_search_by
*/
@(require_results)
binary_search :: proc(array: $A/[]$T, key: T) -> (index: int, found: bool)
	where intrinsics.type_is_ordered(T) #no_bounds_check
{
	return binary_search_by(array, key, cmp_proc(T))
}

@(require_results)
binary_search_by :: proc(array: $A/[]$T, key: T, f: proc(T, T) -> Ordering) -> (index: int, found: bool) #no_bounds_check {
	n := len(array)
	left, right := 0, n
	for left < right {
		mid := int(uint(left+right) >> 1)
		if f(array[mid], key) == .Less {
			left = mid+1
		} else {
			// .Equal or .Greater
			right = mid
		}
	}
	// left == right
	// f(array[left-1], key) == .Less (if left > 0)
	return left, left < n && f(array[left], key) == .Equal
}

@(require_results)
equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_comparable(E) {
	if len(a) != len(b) {
		return false
	}
	when intrinsics.type_is_simple_compare(E) {
		return runtime.memory_compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
	} else {
		for i in 0..<len(a) {
			if a[i] != b[i] {
				return false
			}
		}
		return true
	}
}

@(require_results)
simple_equal :: proc(a, b: $T/[]$E) -> bool where intrinsics.type_is_simple_compare(E) {
	if len(a) != len(b) {
		return false
	}
	return runtime.memory_compare(raw_data(a), raw_data(b), len(a)*size_of(E)) == 0
}

/*
	return the prefix length common between slices `a` and `b`.

	slice.prefix_length([]u8{1, 2, 3, 4}, []u8{1}) -> 1
	slice.prefix_length([]u8{1, 2, 3, 4}, []u8{1, 2, 3}) -> 3
	slice.prefix_length([]u8{1, 2, 3, 4}, []u8{2, 3, 4}) -> 0
*/
@(require_results)
prefix_length :: proc(a, b: $T/[]$E) -> (n: int) where intrinsics.type_is_comparable(E) {
	_len := builtin.min(len(a), len(b))

	#no_bounds_check for n < _len && a[n] == b[n] {
		n += 1
	}
	return
}

@(require_results)
has_prefix :: proc(array: $T/[]$E, needle: T) -> bool where intrinsics.type_is_comparable(E) {
	n := len(needle)
	if len(array) >= n {
		return equal(array[:n], needle)
	}
	return false
}


@(require_results)
has_suffix :: proc(array: $T/[]$E, needle: T) -> bool where intrinsics.type_is_comparable(E) {
	array := array
	m, n := len(array), len(needle)
	if m >= n {
		return equal(array[m-n:], needle)
	}
	return false
}

zero :: proc(array: $T/[]$E) #no_bounds_check {
	if len(array) > 0 {
		intrinsics.mem_zero(raw_data(array), size_of(E)*len(array))
	}
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
	// FIXME: (ap29600) this cast is a temporary fix for the compiler not matching
	// [^T] with $P/^$T
	p := cast(^E)raw_data(array)
	ptr_rotate(m, ptr_add(p, m), k)
}
rotate_right :: proc(array: $T/[]$E, k: int) {
	rotate_left(array, -k)
}

swap_with_slice :: proc(a, b: $T/[]$E, loc := #caller_location) {
	assert(len(a) == len(b), "miss matching slice lengths", loc)

	ptr_swap_non_overlapping(raw_data(a), raw_data(b), len(a)*size_of(E))
}

@(require_results)
concatenate :: proc(a: []$T/[]$E, allocator := context.allocator) -> (res: T, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(a) == 0 {
		return
	}
	n := 0
	for s in a {
		n += len(s)
	}
	res = make(T, n, allocator) or_return
	i := 0
	for s in a {
		i += copy(res[i:], s)
	}
	return
}

// copies a slice into a new slice
@(require_results)
clone :: proc(a: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> ([]E, runtime.Allocator_Error) #optional_allocator_error {
	d, err := make([]E, len(a), allocator, loc)
	copy(d[:], a)
	return d, err
}


// copies slice into a new dynamic array
clone_to_dynamic :: proc(a: $T/[]$E, allocator := context.allocator, loc := #caller_location) -> ([dynamic]E, runtime.Allocator_Error) #optional_allocator_error {
	d, err := make([dynamic]E, len(a), allocator, loc)
	copy(d[:], a)
	return d, err
}
to_dynamic :: clone_to_dynamic

// Converts slice into a dynamic array without cloning or allocating memory
@(require_results)
into_dynamic :: proc(a: $T/[]$E) -> [dynamic]E {
	s := transmute(runtime.Raw_Slice)a
	d := runtime.Raw_Dynamic_Array{
		data = s.data,
		len  = 0,
		cap  = s.len,
		allocator = runtime.nil_allocator(),
	}
	return transmute([dynamic]E)d
}


@(require_results)
length :: proc(a: $T/[]$E) -> int {
	return len(a)
}
@(require_results)
is_empty :: proc(a: $T/[]$E) -> bool {
	return len(a) == 0
}



@(require_results)
split_at :: proc(array: $T/[]$E, index: int) -> (a, b: T) {
	return array[:index], array[index:]
}


@(require_results)
split_first :: proc(array: $T/[]$E) -> (first: E, rest: T) {
	return array[0], array[1:]
}
@(require_results)
split_last :: proc(array: $T/[]$E) -> (rest: T, last: E) {
	n := len(array)-1
	return array[:n], array[n]
}

@(require_results)
first :: proc(array: $T/[]$E) -> E {
	return array[0]
}
@(require_results)
last :: proc(array: $T/[]$E) -> E {
	return array[len(array)-1]
}


@(require_results)
first_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[0]
	}
	return nil
}
@(require_results)
last_ptr :: proc(array: $T/[]$E) -> ^E {
	if len(array) != 0 {
		return &array[len(array)-1]
	}
	return nil
}

@(require_results)
get :: proc(array: $T/[]$E, index: int) -> (value: E, ok: bool) {
	if uint(index) < len(array) {
		value = array[index]
		ok = true
	}
	return
}
@(require_results)
get_ptr :: proc(array: $T/[]$E, index: int) -> (value: ^E, ok: bool) {
	if uint(index) < len(array) {
		value = &array[index]
		ok = true
	}
	return
}

@(require_results)
as_ptr :: proc(array: $T/[]$E) -> [^]E {
	return raw_data(array)
}


@(require_results)
mapper :: proc(s: $S/[]$U, f: proc(U) -> $V, allocator := context.allocator) -> (r: []V, err: runtime.Allocator_Error) #optional_allocator_error {
	r = make([]V, len(s), allocator) or_return
	for v, i in s {
		r[i] = f(v)
	}
	return
}

@(require_results)
reduce :: proc(s: $S/[]$U, initializer: $V, f: proc(V, U) -> V) -> V {
	r := initializer
	for v in s {
		r = f(r, v)
	}
	return r
}

@(require_results)
reduce_reverse :: proc(s: $S/[]$U, initializer: $V, f: proc(V, U) -> V) -> V {
	r := initializer
	for i := len(s)-1; i >= 0; i -= 1 {
		#no_bounds_check r = f(r, s[i])
	}
	return r
}

@(require_results)
filter :: proc(s: $S/[]$U, f: proc(U) -> bool, allocator := context.allocator) -> (res: S, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]U, 0, 0, allocator) or_return
	for v in s {
		if f(v) {
			append(&r, v)
		}
	}
	return r[:], nil
}

@(require_results)
filter_reverse :: proc(s: $S/[]$U, f: proc(U) -> bool, allocator := context.allocator) -> (res: S, err: runtime.Allocator_Error) #optional_allocator_error {
	r := make([dynamic]U, 0, 0, allocator) or_return
	for i := len(s)-1; i >= 0; i -= 1 {
		#no_bounds_check v := s[i]
		if f(v) {
			append(&r, v)
		}
	}
	return r[:], nil
}

@(require_results)
scanner :: proc (s: $S/[]$U, initializer: $V, f: proc(V, U) -> V, allocator := context.allocator) -> (res: []V, err: runtime.Allocator_Error) #optional_allocator_error {
	if len(s) == 0 { return }

	res = make([]V, len(s), allocator) or_return
	p := as_ptr(s)
	q := as_ptr(res)
	r := initializer

	for l := len(s); l > 0; l -= 1 {
		r = f(r, p[0])
		q[0] = r
		p = p[1:]
		q = q[1:]
	}

	return
}


@(require_results)
repeat :: proc(s: $S/[]$U, count: int, allocator := context.allocator) -> (b: S, err: runtime.Allocator_Error) #optional_allocator_error {
	if count < 0 {
		panic("slice: negative repeat count")
	} else if count > 0 && (len(s)*count)/count != len(s) {
		panic("slice: repeat count will cause an overflow")
	}

	b = make(S, len(s)*count, allocator) or_return
	i := copy(b, s)
	for i < len(b) { // 2^N trick to reduce the need to copy
		copy(b[i:], b[:i])
		i *= 2
	}
	return
}

// 'unique' replaces consecutive runs of equal elements with a single copy.
// The procedures modifies the slice in-place and returns the modified slice.
@(require_results)
unique :: proc(s: $S/[]$T) -> S where intrinsics.type_is_comparable(T) #no_bounds_check {
	if len(s) < 2 {
		return s
	}
	i := 1
	for j in 1..<len(s) {
		if s[j] != s[j-1] && i != j {
			s[i] = s[j]
			i += 1
		}
	}

	return s[:i]
}

// 'unique_proc' replaces consecutive runs of equal elements with a single copy using a comparison procedure
// The procedures modifies the slice in-place and returns the modified slice.
@(require_results)
unique_proc :: proc(s: $S/[]$T, eq: proc(T, T) -> bool) -> S #no_bounds_check {
	if len(s) < 2 {
		return s
	}
	i := 1
	for j in 1..<len(s) {
		if !eq(s[j], s[j-1]) && i != j {
			s[i] = s[j]
			i += 1
		}
	}

	return s[:i]
}


@(require_results)
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
@(require_results)
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

@(require_results)
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

// Find the index of the (first) minimum element in a slice.
@(require_results)
min_index :: proc(s: $S/[]$T) -> (min_index: int, ok: bool) where intrinsics.type_is_ordered(T) #optional_ok {
	if len(s) == 0 {
		return -1, false
	}
	min_index = 0
	min_value := s[0]
	for v, i in s[1:] {
		if v < min_value {
			min_value = v
			min_index = i+1
		}
	}
	return min_index, true
}

// Find the index of the (first) maximum element in a slice.
@(require_results)
max_index :: proc(s: $S/[]$T) -> (max_index: int, ok: bool) where intrinsics.type_is_ordered(T) #optional_ok {
	if len(s) == 0 {
		return -1, false
	}
	max_index = 0
	max_value := s[0]
	for v, i in s[1:] {
		if v > max_value {
			max_value = v
			max_index = i+1
		}
	}
	return max_index, true
}

@(require_results)
any_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			return true
		}
	}
	return false
}

@(require_results)
none_of :: proc(s: $S/[]$T, value: T) -> bool where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			return false
		}
	}
	return true
}

@(require_results)
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


@(require_results)
any_of_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> bool {
	for v in s {
		if f(v) {
			return true
		}
	}
	return false
}

@(require_results)
none_of_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> bool {
	for v in s {
		if f(v) {
			return false
		}
	}
	return true
}

@(require_results)
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


@(require_results)
count :: proc(s: $S/[]$T, value: T) -> (n: int) where intrinsics.type_is_comparable(T) {
	for v in s {
		if v == value {
			n += 1
		}
	}
	return
}

@(require_results)
count_proc :: proc(s: $S/[]$T, f: proc(T) -> bool) -> (n: int) {
	for v in s {
		if f(v) {
			n += 1
		}
	}
	return
}


@(require_results)
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


// Convert a pointer to an enumerated array to a slice of the element type
@(require_results)
enumerated_array :: proc(ptr: ^$T) -> []intrinsics.type_elem_type(T)
	where intrinsics.type_is_enumerated_array(T) {
	return ([^]intrinsics.type_elem_type(T))(ptr)[:len(T)]
}

// Turn a `[]E` into `bit_set[E]`
// e.g.:
//    bs := slice.enum_slice_to_bitset(my_flag_slice, rl.ConfigFlags)
@(require_results)
enum_slice_to_bitset :: proc(enums: []$E, $T: typeid/bit_set[E]) -> (bits: T) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	for v in enums {
		bits |= {v}
	}
	return
}

// Turn a `bit_set[E]` into a `[]E`
// e.g.:
//    sl := slice.bitset_to_enum_slice(flag_buf[:], bs)
@(require_results)
bitset_to_enum_slice_with_buffer :: proc(buf: []$E, bs: $T) -> (slice: []E) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	count := 0
	for v in bs {
		buf[count] = v
		count += 1
	}
	return buf[:count]
}

// Turn a `bit_set[E]` into a `[]E`, allocates
// e.g.:
//    sl := slice.bitset_to_enum_slice(bs)
@(require_results)
bitset_to_enum_slice_with_make :: proc(bs: $T, $E: typeid, allocator := context.allocator) -> (slice: []E) where intrinsics.type_is_enum(E), intrinsics.type_bit_set_elem_type(T) == E {
	ones := intrinsics.count_ones(transmute(E)bs)
	buf  := make([]E, int(ones), allocator)
	return bitset_to_enum_slice(buf, bs)
}

bitset_to_enum_slice :: proc{bitset_to_enum_slice_with_make, bitset_to_enum_slice_with_buffer}