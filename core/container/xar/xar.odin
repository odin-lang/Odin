package container_xar

@(require) import "core:mem"
@(require) import "base:intrinsics"
@(require) import "base:runtime"

PLATFORM_BITS :: 8*size_of(uint)
_LOG2_PLATFORM_BITS :: intrinsics.constant_log2(PLATFORM_BITS)

MAX_SHIFT :: PLATFORM_BITS>>1

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

clear :: proc(x: $X/Xar($T, $SHIFT)) {
	x.len = 0
}

@(require_results)
meta_get :: #force_inline proc($SHIFT: uint, index: uint) -> (chunk_idx, elem_idx, chunk_cap: uint) {
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

@(require_results)
get :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := meta_get(SHIFT, uint(index))
	return x.chunks[chunk_idx][elem_idx]
}

@(require_results)
get_ptr :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: ^T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := meta_get(SHIFT, uint(index))
	return &x.chunks[chunk_idx][elem_idx]
}

set :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, value: T, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := meta_get(SHIFT, uint(index))
	x.chunks[chunk_idx][elem_idx] = value
}

append    :: proc{push_back_elem, push_back_elems}
push_back :: proc{push_back_elem, push_back_elems}

push_back_elem :: proc(x: ^$X/Xar($T, $SHIFT), value: T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
	chunk_idx, elem_idx, chunk_cap := meta_get(SHIFT, uint(x.len))
	if x.chunks[chunk_idx] == nil {
		x.chunks[chunk_idx] = make([^]T, chunk_cap, x.allocator) or_return
	}
	x.chunks[chunk_idx][elem_idx] = value
	x.len += 1
	n = 1
	return
}

push_back_elems :: proc(x: ^$X/Xar($T, $SHIFT), values: ..T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
	for value in values {
		n += push_back_elem(x, value, loc) or_return
	}
	return
}

pop :: proc(x: ^$X/Xar($T, $SHIFT), loc := #caller_location) -> (val: T) {
	assert(x.len > 0, loc=loc)
	index := uint(x.len-1)
	chunk_idx, elem_idx, _ := meta_get(SHIFT, index)
	x.len -= 1
	return x.chunks[chunk_idx][elem_idx]
}

@(require_results)
pop_safe :: proc(x: ^$X/Xar($T, $SHIFT)) -> (val: T, ok: bool) {
	if x.len == 0 {
		return
	}
	index := uint(x.len-1)
	chunk_idx, elem_idx, _ := meta_get(SHIFT, index)
	x.len -= 1

	val = x.chunks[chunk_idx][elem_idx]
	ok = true
	return
}

unordered_remove :: proc(x: ^$X/Xar($T, $SHIFT), #any_int index: int, loc := #caller_location) {
	runtime.bounds_check_error_loc(loc, index, x.len)
	n := x.len-1
	if index != n {
		end := get(x, n)
		set(x, index, end)
	}
	x.len -= 1
}