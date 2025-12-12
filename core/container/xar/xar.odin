/*
	Exponential Array (Xar).

	A fixed inline array of multi-pointers to exponentially growing chunks,
	allowing for stable memory addresses for elements.

	For more information: https://azmr.uk/dyn/#exponential-arrayxar
*/
package container_xar

@(require) import "core:mem"
@(require) import "base:intrinsics"
@(require) import "base:runtime"

PLATFORM_BITS :: 8*size_of(uint)
_LOG2_PLATFORM_BITS :: intrinsics.constant_log2(PLATFORM_BITS)

MAX_SHIFT :: PLATFORM_BITS>>1

/*
	An Exponential Array (Xar) is a fixed inline array of multi-pointers to exponentially growing chunks,
	allowing for stable memory addresses for elements.

	The chunk length uses as many chunks as much as addressable memory the machine provides.

	Size of chunks:
	len(chunks[0]) == 1<<(SHIFT+0)
	len(chunks[1]) == 1<<(SHIFT+0)
	len(chunks[2]) == 1<<(SHIFT+1)
	len(chunks[3]) == 1<<(SHIFT+2)
*/
Xar :: struct($T: typeid, $SHIFT: uint) where 0 < SHIFT, SHIFT <= MAX_SHIFT {
	chunks:    [(1 << (_LOG2_PLATFORM_BITS - intrinsics.constant_log2(SHIFT))) + 1][^]T,
	len:       int,
	allocator: mem.Allocator,
}

init :: proc(x: ^$X/Xar($T, $SHIFT), allocator := context.allocator) {
	x^ = {allocator = allocator}
}

destroy :: proc(x: ^$X/Xar($T, $SHIFT)) {
	#reverse for c, i in x.chunks {
		if c != nil {
			n := 1 << (SHIFT + uint(i if i > 0 else 1) - 1)
			size_in_bytes := n * size_of(T)
			mem.free_with_size(c, size_in_bytes, x.allocator)
		}
	}
	x^ = {}
}

// Resets the array's length to zero.
clear :: proc(x: $X/Xar($T, $SHIFT)) {
	x.len = 0
}

// Returns the length of the exponential-array
@(require_results)
len :: proc(x: $X/Xar($T, $SHIFT)) -> int {
	return x.len
}

// Returns the number of allocated elements
@(require_results)
cap :: proc(x: $X/Xar($T, $SHIFT)) -> int {
	#reverse for c, i in x.chunks {
		if c != nil {
			return 1 << (SHIFT + uint(i if i > 0 else 1))
		}
	}
	return 0
}

@(require_results)
_meta_get :: #force_inline proc($SHIFT: uint, index: uint) -> (chunk_idx, elem_idx, chunk_cap: uint) {
	elem_idx = index
	chunk_cap = uint(1) << SHIFT
	chunk_idx = 0

	index_shift := index >> SHIFT
	if index_shift > 0 {
		N :: 8*size_of(uint)-1
		CLZ :: intrinsics.count_leading_zeros
		chunk_idx = N-CLZ(index_shift) // MSB(index_shift)

		chunk_cap  = 1 << (chunk_idx + SHIFT)
		elem_idx   -= chunk_cap
		chunk_idx += 1
	}

	return
}

// Gets the element at the index
@(require_results)
get :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	return x.chunks[chunk_idx][elem_idx]
}

// Gets the pointer of the element at the index
@(require_results)
get_ptr :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: ^T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	return &x.chunks[chunk_idx][elem_idx]
}

// Sets the value at the index
set :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, value: T, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	x.chunks[chunk_idx][elem_idx] = value
}

append    :: proc{push_back_elem, push_back_elems}
push_back :: proc{push_back_elem, push_back_elems}

// `push_back_elem` pushes back (appends) an element to an exponential array
push_back_elem :: proc(x: ^$X/Xar($T, $SHIFT), value: T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
	if x.allocator.procedure == nil {
		// to minic `[dynamic]T` behaviour
		x.allocator = context.allocator
	}

	chunk_idx, elem_idx, chunk_cap := _meta_get(SHIFT, uint(x.len))
	if x.chunks[chunk_idx] == nil {
		x.chunks[chunk_idx] = make([^]T, chunk_cap, x.allocator) or_return
	}
	x.chunks[chunk_idx][elem_idx] = value
	x.len += 1
	n = 1
	return
}

// `push_back_elems` pushes back (appends) multiple elements to an exponential array
push_back_elems :: proc(x: ^$X/Xar($T, $SHIFT), values: ..T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
	for value in values {
		n += push_back_elem(x, value, loc) or_return
	}
	return
}

append_and_get_ptr :: push_back_elem_and_get_ptr

// `push_back_elem` pushes back (appends) an element to an exponential array and returns its pointer
@(require_results)
push_back_elem_and_get_ptr :: proc(x: ^$X/Xar($T, $SHIFT), value: T, loc := #caller_location) -> (ptr: ^T, err: mem.Allocator_Error) {
	if x.allocator.procedure == nil {
		// to minic `[dynamic]T` behaviour
		x.allocator = context.allocator
	}

	chunk_idx, elem_idx, chunk_cap := _meta_get(SHIFT, uint(x.len))
	if x.chunks[chunk_idx] == nil {
		x.chunks[chunk_idx] = make([^]T, chunk_cap, x.allocator) or_return
	}
	x.chunks[chunk_idx][elem_idx] = value
	x.len += 1
	n = 1
	ptr = &x.chunks[chunk_idx][elem_idx]
	return
}

// `pop` will remove and return the end value of an exponential array `x` and reduces the length of the array by 1.
//
// Note: If the exponential array has no elements (`xar.len(x) == 0`), this procedure will panic.
pop :: proc(x: ^$X/Xar($T, $SHIFT), loc := #caller_location) -> (val: T) {
	assert(x.len > 0, loc=loc)
	index := uint(x.len-1)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, index)
	x.len -= 1
	return x.chunks[chunk_idx][elem_idx]
}

// `pop_safe` trys to remove and return the end value of dynamic array `x` and reduces the length of the array by 1.
// If the operation is not possible, it will return false.
@(require_results)
pop_safe :: proc(x: ^$X/Xar($T, $SHIFT)) -> (val: T, ok: bool) {
	if x.len == 0 {
		return
	}
	index := uint(x.len-1)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, index)
	x.len -= 1

	val = x.chunks[chunk_idx][elem_idx]
	ok = true
	return
}

// `unordered_remove` removed the element at the specified `index`. It does so by replacing the current end value
// with the old value, and reducing the length of the exponential array by 1.
//
// Note: This is an O(1) operation.
// Note: This is currently no procedure that is the equivalent of an "ordered_remove"
// Note: If the index is out of bounds, this procedure will panic.
unordered_remove :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) {
	runtime.bounds_check_error_loc(loc, index, x.len)
	n := x.len-1
	if index != n {
		end := get(x, n)
		set(x, index, end)
	}
	x.len -= 1
}