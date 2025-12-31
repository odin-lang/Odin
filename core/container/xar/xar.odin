/*
	Exponential Array (Xar).

	A dynamically growing array using exponentially-sized chunks, providing stable
	memory addresses for all elements. Unlike `[dynamic]T`, elements are never
	moved once allocated, making it safe to hold pointers to elements.

	For more information: https://azmr.uk/dyn/#exponential-arrayxar

	Example:

		import "core:container/xar"

		example :: proc() {
			x: xar.Array(int, 4)
			defer xar.destroy(&x)

			xar.push_back(&x, 10)
			xar.push_back(&x, 20)
			xar.push_back(&x, 30)

			ptr := xar.get_ptr(&x, 1)  // ptr remains valid after more push_backs
			xar.push_back(&x, 40)
			fmt.println(ptr^)  // prints 20
		}
*/
package container_xar

@(require) import "core:mem"
@(require) import "base:intrinsics"
@(require) import "base:runtime"

PLATFORM_BITS :: 8*size_of(uint)
_LOG2_PLATFORM_BITS :: intrinsics.constant_log2(PLATFORM_BITS)

MAX_SHIFT :: PLATFORM_BITS>>1

/*
	An Exponential Array with stable element addresses.

	Unlike `[dynamic]T` which reallocates and moves elements when growing, `Array`
	allocates separate chunks of exponentially increasing size. This guarantees
	that pointers to elements remain valid for the lifetime of the container.

	Fields:
	- `chunks`: Fixed array of multi-pointers to allocated chunks
	- `len`: Number of elements currently stored
	- `allocator`: Allocator used for chunk allocations

	Type Parameters:
	- `T`: The element type
	- `SHIFT`: Controls initial chunk size (1 << SHIFT). Must be in range (0, MAX_SHIFT].
	          Larger values mean fewer, bigger chunks. Recommended: 4-8.

	Chunk sizes grow as:
	- `chunks[0]`: 1 << SHIFT elements
	- `chunks[1]`: 1 << SHIFT elements
	- `chunks[2]`: 1 << (SHIFT + 1) elements
	- `chunks[3]`: 1 << (SHIFT + 2) elements
	- `chunks[4]`: 1 << (SHIFT + 3) elements
	- ...and so on

	Example:

		import "core:container/xar"

		example :: proc() {
			// Xar with initial chunk size of 16 (1 << 4)
			x: xar.Array(My_Struct, 4)
			defer xar.destroy(&x)
		}
*/
Array :: struct($T: typeid, $SHIFT: uint) where 0 < SHIFT, SHIFT <= MAX_SHIFT {
	chunks:    [(1 << (_LOG2_PLATFORM_BITS - intrinsics.constant_log2(SHIFT))) + 1][^]T,
	len:       int,
	allocator: mem.Allocator,
}


/*
Initializes an exponential array with the given allocator.

**Inputs**
- `x`: Pointer to the exponential array to initialize
- `allocator`: Allocator to use for chunk allocations (defaults to context.allocator)
*/
init :: proc(x: ^$X/Array($T, $SHIFT), allocator := context.allocator) {
	x^ = {allocator = allocator}
}

/*
Frees all allocated chunks and resets the exponential array.

**Inputs**
- `x`: Pointer to the exponential array to destroy
*/
destroy :: proc(x: ^$X/Array($T, $SHIFT)) {
	#reverse for c, i in x.chunks {
		if c != nil {
			n := 1 << (SHIFT + uint(i if i > 0 else 1) - 1)
			size_in_bytes := n * size_of(T)
			mem.free_with_size(c, size_in_bytes, x.allocator)
		}
	}
	x^ = {}
}

/*
Resets the array's length to zero without freeing memory.
Allocated chunks are retained for reuse.
*/
clear :: proc(x: ^$X/Array($T, $SHIFT)) {
	x.len = 0
}

// Returns the length of the exponential-array
@(require_results)
len :: proc(x: $X/Array($T, $SHIFT)) -> int {
	return x.len
}

// Returns the number of allocated elements
@(require_results)
cap :: proc(x: $X/Array($T, $SHIFT)) -> int {
	#reverse for c, i in x.chunks {
		if c != nil {
			return 1 << (SHIFT + uint(i if i > 0 else 1))
		}
	}
	return 0
}

// Internal: computes chunk index, element index within chunk, and chunk capacity for a given index.
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
/*
Get a copy of the element at the specified index.

**Inputs**
- `x`: Pointer to the exponential array
- `index`: Position of the element (0-indexed)

**Returns**
- a copy of the element
*/
@(require_results)
get :: proc(x: ^$X/Array($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	return x.chunks[chunk_idx][elem_idx]
}

/*
Get a pointer to the element at the specified index.

The returned pointer remains valid even after additional elements are added,
as long as the element is not removed and the array is not destroyed.

**Inputs**
- `x`: Pointer to the exponential array
- `index`: Position of the element (0-indexed)

**Returns**
- a stable pointer to the element

Example:

	import "core:container/xar"

	get_ptr_example :: proc() {
		x: xar.Array(int, 4)
		defer xar.destroy(&x)

		xar.push_back(&x, 100)
		ptr := xar.get_ptr(&x, 0)

		// Pointer remains valid after growing
		for i in 0..<1000 {
			xar.push_back(&x, i)
		}

		fmt.println(ptr^)  // Still prints 100
	}
*/
@(require_results)
get_ptr :: proc(x: ^$X/Array($T, $SHIFT), #any_int index: int, loc := #caller_location) -> (val: ^T) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	return &x.chunks[chunk_idx][elem_idx]
}

/*
Set the element at the specified index to the given value.

**Inputs**
- `x`: Pointer to the exponential array
- `index`: Position of the element (0-indexed)
- `value`: The value to set
*/
set :: proc(x: ^$X/Array($T, $SHIFT), #any_int index: int, value: T, loc := #caller_location) #no_bounds_check {
	runtime.bounds_check_error_loc(loc, index, x.len)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, uint(index))
	x.chunks[chunk_idx][elem_idx] = value
}

append    :: proc{push_back_elem, push_back_elems}
push_back :: proc{push_back_elem, push_back_elems}

/*
Append an element to the end of the exponential array.
Allocates a new chunk if necessary. Existing elements aren't moved, and their pointers remain stable.

**Inputs**
- `x`: Pointer to the exponential array
- `value`: The element to append

**Returns**
- number of elements added (always 1 on success)
- allocation error if chunk allocation failed

Example:

	import "core:container/xar"

	push_back_example :: proc() {
		x: xar.Array(string, 4)
		defer xar.destroy(&x)

		xar.push_back(&x, "hello")
		xar.push_back(&x, "world")

		fmt.println(xar.get(&x, 0))  // hello
		fmt.println(xar.get(&x, 1))  // world
	}
*/
push_back_elem :: proc(x: ^$X/Array($T, $SHIFT), value: T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
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

/*
Append multiple elements to the end of the exponential array.

**Inputs**
- `x`: Pointer to the exponential array
- `values`: The elements to append

**Returns**
- number of elements successfully added
- allocation error if chunk allocation failed (partial append possible)
*/
push_back_elems :: proc(x: ^$X/Array($T, $SHIFT), values: ..T, loc := #caller_location) -> (n: int, err: mem.Allocator_Error) {
	for value in values {
		n += push_back_elem(x, value, loc) or_return
	}
	return
}

append_and_get_ptr :: push_back_elem_and_get_ptr
/*
Append an element and return a stable pointer to it.
This is useful when you need to initialize a complex struct in-place or
retain a reference to the newly added element.

**Inputs**
- `x`: Pointer to the exponential array
- `value`: The element to append

**Returns**
- a stable pointer to the newly added element
- allocation error if chunk allocation failed

Example:

	import "core:container/xar"

	push_back_and_get_ptr_example :: proc() {
		x: xar.Array(My_Struct, 4)
		defer xar.destroy(&x)

		ptr := xar.push_back_elem_and_get_ptr(&x, My_Struct{}) or_else panic("alloc failed")
		ptr.field = 42  // Initialize in-place
	}
*/
@(require_results)
push_back_elem_and_get_ptr :: proc(x: ^$X/Array($T, $SHIFT), value: T, loc := #caller_location) -> (ptr: ^T, err: mem.Allocator_Error) {
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
	ptr = &x.chunks[chunk_idx][elem_idx]
	return
}

// `pop` will remove and return the end value of an exponential array `x` and reduces the length of the array by 1.
//
// Note: If the exponential array has no elements (`xar.len(x) == 0`), this procedure will panic.
pop :: proc(x: ^$X/Array($T, $SHIFT), loc := #caller_location) -> (val: T) {
	assert(x.len > 0, loc=loc)
	index := uint(x.len-1)
	chunk_idx, elem_idx, _ := _meta_get(SHIFT, index)
	x.len -= 1
	return x.chunks[chunk_idx][elem_idx]
}

// `pop_safe` trys to remove and return the end value of dynamic array `x` and reduces the length of the array by 1.
// If the operation is not possible, it will return false.
@(require_results)
pop_safe :: proc(x: ^$X/Array($T, $SHIFT)) -> (val: T, ok: bool) {
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

/*
	`unordered_remove` removed the element at the specified `index`. It does so by replacing the current end value
	with the old value, and reducing the length of the exponential array by 1.

	Note: This is an O(1) operation.
	Note: This is currently no procedure that is the equivalent of an "ordered_remove"
	Note: If the index is out of bounds, this procedure will panic.

	Note: Pointers to the last element become invalid (it gets moved). Pointers to other elements remain valid.

	Example:

		import "core:encoding/xar"

		unordered_remove_example :: proc() {
			x: xar.Array(int, 4)
			defer xar.destroy(&x)

			xar.push_back(&x, 10)
			xar.push_back(&x, 20)
			xar.push_back(&x, 30)

			xar.unordered_remove(&x, 0)  // Removes 10, replaces with 30

			// Array now contains [30, 20]
			fmt.println(xar.get(&x, 0))  // 30
			fmt.println(xar.get(&x, 1))  // 20
		}
*/
unordered_remove :: proc(x: ^$X/Array($T, $SHIFT), #any_int index: int, loc := #caller_location) {
	runtime.bounds_check_error_loc(loc, index, x.len)
	n := x.len-1
	if index != n {
		end := get(x, n)
		set(x, index, end)
	}
	x.len -= 1
}


/*
Iterator state for traversing a `Xar`.

Fields:
- `xar`: Pointer to the exponential array being iterated
- `idx`: Current iteration index
*/
Iterator :: struct($T: typeid, $SHIFT: uint) {
	xar: ^Array(T, SHIFT),
	idx: int,
}

/*
Create an iterator for traversing the exponential array.

**Inputs**
- `xar`: Pointer to the exponential array

**Returns**
- an iterator positioned at the start

Example:

	import "lib:xar"

	iteration_example :: proc() {
		x: xar.Array(int, 4)
		defer xar.destroy(&x)

		xar.push_back(&x, 10)
		xar.push_back(&x, 20)
		xar.push_back(&x, 30)

		it := xar.iterator(&x)
		for val in xar.iterate_by_ptr(&it) {
			fmt.println(val^)
		}
	}

Output:

	10
	20
	30
*/
iterator :: proc(xar: ^$X/Array($T, $SHIFT)) -> Iterator(T, SHIFT) {
	return {xar = auto_cast xar, idx = 0}
}

/*
Advance the iterator and returns the next element.

**Inputs**
- `it`: Pointer to the iterator

**Returns**
- current element
- `true` if an element was returned, `false` if iteration is complete
*/
iterate_by_val :: proc(it: ^Iterator($T, $SHIFT)) -> (val: T, ok: bool) {
	if it.idx >= it.xar.len {
		return
	}
	val = get(it.xar, it.idx)
	it.idx += 1
	return val, true
}


/*
Advance the iterator and returns a pointer to the next element.

**Inputs**
- `it`: Pointer to the iterator

**Returns**
- pointer to the current element
- `true` if an element was returned, `false` if iteration is complete
*/
iterate_by_ptr :: proc(it: ^Iterator($T, $SHIFT)) -> (val: ^T, ok: bool) {
	if it.idx >= it.xar.len {
		return
	}
	val = get_ptr(it.xar, it.idx)
	it.idx += 1
	return val, true
}
