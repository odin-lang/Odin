package mem

import "base:runtime"

//NOTE(bill, 2019-12-31): These are defined in `package runtime` as they are used in the `context`. This is to prevent an import definition cycle.

/*
A request to allocator procedure.

This type represents a type of allocation request made to an allocator
procedure. There is one allocator procedure per allocator, and this value is
used to discriminate between different functions of the allocator.

The type is defined as follows:

	Allocator_Mode :: enum byte {
		Alloc,
		Alloc_Non_Zeroed,
		Free,
		Free_All,
		Resize,
		Resize_Non_Zeroed,
		Query_Features,
	}

Depending on which value is used, the allocator procedure will perform different
functions:

- `Alloc`: Allocates a memory region with a given `size` and `alignment`.
- `Alloc_Non_Zeroed`: Same as `Alloc` without explicit zero-initialization of
	the memory region.
- `Free`: Free a memory region located at address `ptr` with a given `size`.
- `Free_All`: Free all memory allocated using this allocator.
- `Resize`: Resize a memory region located at address `old_ptr` with size
	`old_size` to be `size` bytes in length and have the specified `alignment`,
	in case a re-alllocation occurs.
- `Resize_Non_Zeroed`: Same as `Resize`, without explicit zero-initialization.
*/
Allocator_Mode :: runtime.Allocator_Mode

/*
A set of allocator features.

This type represents values that contain a set of features an allocator has.
Currently the type is defined as follows:

	Allocator_Mode_Set :: distinct bit_set[Allocator_Mode];
*/
Allocator_Mode_Set :: runtime.Allocator_Mode_Set

/*
Allocator information.

This type represents information about a given allocator at a specific point
in time. Currently the type is defined as follows:

	Allocator_Query_Info :: struct {
		pointer:   rawptr,
		size:      Maybe(int),
		alignment: Maybe(int),
	}

- `pointer`: Pointer to a backing buffer.
- `size`: Size of the backing buffer.
- `alignment`: The allocator's alignment.

If not applicable, any of these fields may be `nil`.
*/
Allocator_Query_Info :: runtime.Allocator_Query_Info

/*
An allocation request error.

This type represents error values the allocators may return upon requests.

	Allocator_Error :: enum byte {
		None                 = 0,
		Out_Of_Memory        = 1,
		Invalid_Pointer      = 2,
		Invalid_Argument     = 3,
		Mode_Not_Implemented = 4,
	}

The meaning of the errors is as follows:

- `None`: No error.
- `Out_Of_Memory`: Either:
	1. The allocator has ran out of the backing buffer, or the requested
		allocation size is too large to fit into a backing buffer.
	2. The operating system error during memory allocation.
	3. The backing allocator was used to allocate a new backing buffer and the
		backing allocator returned Out_Of_Memory.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
	to any of the allocators backing buffers or does not point to a valid start
	of an allocation made in that allocator.
- `Invalid_Argument`: Can occur if one of the arguments makes it impossible to
	satisfy a request (i.e. having alignment larger than the backing buffer
	of the allocation).
- `Mode_Not_Implemented`: The allocator does not support the specified
	operation. For example, an arena does not support freeing individual
	allocations.
*/
Allocator_Error :: runtime.Allocator_Error

/*
The allocator procedure.

This type represents allocation procedures. An allocation procedure is a single
procedure, implementing all allocator functions such as allocating the memory,
freeing the memory, etc.

Currently the type is defined as follows:

	Allocator_Proc :: #type proc(
		allocator_data: rawptr,
		mode: Allocator_Mode,
		size: int,
		alignment: int,
		old_memory: rawptr,
		old_size: int,
		location: Source_Code_Location = #caller_location,
	) -> ([]byte, Allocator_Error);

The function of this procedure and the meaning of parameters depends on the
value of the `mode` parameter. For any operation the following constraints
apply:

- The `alignment` must be a power of two.
- The `size` must be a positive integer.

## 1. `.Alloc`, `.Alloc_Non_Zeroed`

Allocates a memory region of size `size`, aligned on a boundary specified by
`alignment`.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Alloc` or `.Alloc_Non_Zeroed`.
- `size`: The desired size of the memory region.
- `alignment`: The desired alignmnet of the allocation.
- `old_memory`: Unused, should  be `nil`.
- `old_size`: Unused, should be 0.

**Returns**:
1. The memory region, if allocated successfully, or `nil` otherwise.
2. An error, if allocation failed.

**Note**: The nil allocator may return `nil`, even if no error is returned.
Always check both the error and the allocated buffer.

**Note**: The `.Alloc` mode is required to be implemented for an allocator
and can not return a `.Mode_Not_Implemented` error.

## 2. `Free`

Frees a memory region located at the address specified by `old_memory`. If the
allocator does not track sizes of allocations, the size should be specified in
the `old_size` parameter.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Free`.
- `size`: Unused, should be 0.
- `alignment`: Unused, should be 0.
- `old_memory`: Pointer to the memory region to free.
- `old_size`: The size of the memory region to free. This parameter is optional
	if the allocator keeps track of the sizes of allocations.

**Returns**:
1. `nil`
2. Error, if freeing failed.

## 3. `Free_All`

Frees all allocations, associated with the allocator, making it available for
further allocations using the same backing buffers.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Free_All`.
- `size`: Unused, should be 0.
- `alignment`: Unused, should be 0.
- `old_memory`: Unused, should be `nil`.
- `old_size`: Unused, should be `0`.

**Returns**:
1. `nil`.
2. Error, if freeing failed.

## 4. `Resize`, `Resize_Non_Zeroed`

Resizes the memory region, of the size `old_size` located at the address
specified by `old_memory` to have the new size `size`. The slice of the new
memory region is returned from the procedure. The allocator may attempt to
keep the new memory region at the same address as the previous allocation,
however no such guarantee is made. Do not assume the new memory region will
be at the same address as the old memory region.

If `old_memory` pointer is `nil`, this function acts just like `.Alloc` or
`.Alloc_Non_Zeroed`, using `size` and `alignment` to allocate a new memory
region.

If `new_size` is `nil`, the procedure acts just like `.Free`, freeing the
memory region `old_size` bytes in length, located at the address specified by
`old_memory`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

**Inputs**:
- `allocator_data`: Pointer to the allocator data.
- `mode`: `.Resize` or `.Resize_All`.
- `size`: The desired new size of the memory region.
- `alignment`: The alignment of the new memory region, if its allocated
- `old_memory`: The pointer to the memory region to resize.
- `old_size`: The size of the memory region to resize. If the allocator
	keeps track of the sizes of allocations, this parameter is optional.

**Returns**:
1. The slice of the  memory region after resize operation, if successfull,
	`nil` otherwise.
2. An error, if the resize failed.

**Note**: Some allocators may return `nil`, even if no error is returned.
Always check both the error and the allocated buffer.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
Allocator_Proc :: runtime.Allocator_Proc

/*
Allocator.

This type represents generic interface for all allocators. Currently this type
is defined as follows:

	Allocator :: struct {
		procedure: Allocator_Proc,
		data: rawptr,
	}

- `procedure`: Pointer to the allocation procedure.
- `data`: Pointer to the allocator data.
*/
Allocator :: runtime.Allocator

/*
Default alignment.

This value is the default alignment for all platforms that is used, if the
alignment is not specified explicitly.
*/
DEFAULT_ALIGNMENT :: 2*align_of(rawptr)

/*
Default page size.

This value is the default page size for the current platform.
*/
DEFAULT_PAGE_SIZE ::
	64 * 1024 when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 else
	16 * 1024 when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 else
	4 * 1024

/*
Allocate memory.

This function allocates `size` bytes of memory, aligned to a boundary specified
by `alignment` using the allocator specified by `allocator`.

If the `size` parameter is `0`, the operation is a no-op.

**Inputs**:
- `size`: The desired size of the allocated memory region.
- `alignment`: The desired alignment of the allocated memory region.
- `allocator`: The allocator to allocate from.

**Returns**:
1. Pointer to the allocated memory, or `nil` if allocation failed.
2. Error, if the allocation failed.

**Errors**:
- `None`: If no error occurred.
- `Out_Of_Memory`: Occurs when the allocator runs out of space in any of its
	backing buffers, the backing allocator has ran out of space, or an operating
	system failure occurred.
- `Invalid_Argument`: If the supplied `size` is negative, alignment is not a
	power of two.
*/
@(require_results)
alloc :: proc(
	size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	data, err := runtime.mem_alloc(size, alignment, allocator, loc)
	return raw_data(data), err
}

/*
Allocate memory.

This function allocates `size` bytes of memory, aligned to a boundary specified
by `alignment` using the allocator specified by `allocator`.

**Inputs**:
- `size`: The desired size of the allocated memory region.
- `alignment`: The desired alignment of the allocated memory region.
- `allocator`: The allocator to allocate from.

**Returns**:
1. Slice of the allocated memory region, or `nil` if allocation failed.
2. Error, if the allocation failed.

**Errors**:
- `None`: If no error occurred.
- `Out_Of_Memory`: Occurs when the allocator runs out of space in any of its
	backing buffers, the backing allocator has ran out of space, or an operating
	system failure occurred.
- `Invalid_Argument`: If the supplied `size` is negative, alignment is not a
	power of two.
*/
@(require_results)
alloc_bytes :: proc(
	size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return runtime.mem_alloc(size, alignment, allocator, loc)
}

/*
Allocate non-zeroed memory.

This function allocates `size` bytes of memory, aligned to a boundary specified
by `alignment` using the allocator specified by `allocator`. This procedure
does not explicitly zero-initialize allocated memory region.

**Inputs**:
- `size`: The desired size of the allocated memory region.
- `alignment`: The desired alignment of the allocated memory region.
- `allocator`: The allocator to allocate from.

**Returns**:
1. Slice of the allocated memory region, or `nil` if allocation failed.
2. Error, if the allocation failed.

**Errors**:
- `None`: If no error occurred.
- `Out_Of_Memory`: Occurs when the allocator runs out of space in any of its
	backing buffers, the backing allocator has ran out of space, or an operating
	system failure occurred.
- `Invalid_Argument`: If the supplied `size` is negative, alignment is not a
	power of two.
*/
@(require_results)
alloc_bytes_non_zeroed :: proc(
	size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return runtime.mem_alloc_non_zeroed(size, alignment, allocator, loc)
}

/*
Free memory.

This procedure frees memory region located at the address, specified by `ptr`,
allocated from the allocator specified by `allocator`.

**Inputs**:
- `ptr`: Pointer to the memory region to free.
- `allocator`: The allocator to free to.

**Returns**:
- The error, if freeing failed.

**Errors**:
- `None`: When no error has occurred.
- `Invalid_Pointer`: The specified pointer is not owned by the specified allocator,
	or does not point to a valid allocation.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
free :: proc(
	ptr: rawptr,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.mem_free(ptr, allocator, loc)
}

/*
Free a memory region.

This procedure frees `size` bytes of memory region located at the address,
specified by `ptr`, allocated from the allocator specified by `allocator`.

If the `size` parameter is `0`, this call is equivalent to `free()`.

**Inputs**:
- `ptr`: Pointer to the memory region to free.
- `size`: The size of the memory region to free.
- `allocator`: The allocator to free to.

**Returns**:
- The error, if freeing failed.

**Errors**:
- `None`: When no error has occurred.
- `Invalid_Pointer`: The specified pointer is not owned by the specified allocator,
	or does not point to a valid allocation.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
free_with_size :: proc(
	ptr: rawptr,
	size: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.mem_free_with_size(ptr, size, allocator, loc)
}

/*
Free a memory region.

This procedure frees memory region, specified by `bytes`, allocated from the
allocator specified by `allocator`.

If the length of the specified slice is zero, the `.Invalid_Argument` error
is returned.

**Inputs**:
- `bytes`: The memory region to free.
- `allocator`: The allocator to free to.

**Returns**:
- The error, if freeing failed.

**Errors**:
- `None`: When no error has occurred.
- `Invalid_Pointer`: The specified pointer is not owned by the specified allocator,
	or does not point to a valid allocation.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
free_bytes :: proc(
	bytes: []byte,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.mem_free_bytes(bytes, allocator, loc)
}

/*
Free all allocations.

This procedure frees all allocations made on the allocator specified by
`allocator` to that allocator, making it available for further allocations.

**Inputs**:
- `allocator`: The allocator to free to.

**Errors**:
- `None`: When no error has occurred.
- `Mode_Not_Implemented`: If the specified allocator does not support the `.Free`
mode.
*/
free_all :: proc(allocator := context.allocator, loc := #caller_location) -> Allocator_Error {
	return runtime.mem_free_all(allocator, loc)
}

/*
Resize a memory region.

This procedure resizes a memory region, `old_size` bytes in size, located at
the address specified by `ptr`, such that it has a new size, specified by
`new_size` and and is aligned on a boundary specified by `alignment`.

If the `ptr` parameter is `nil`, `resize()` acts just like `alloc()`, allocating
`new_size` bytes, aligned on a boundary specified by `alignment`.

If the `new_size` parameter is `0`, `resize()` acts just like `free()`, freeing
the memory region `old_size` bytes in length, located at the address specified
by `ptr`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

**Inputs**:
- `ptr`: Pointer to the memory region to resize.
- `old_size`: Size of the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The pointer to the resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
	allocator does not have enough space to fit in an allocation with the new
	size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
	to any of the allocators backing buffers or does not point to a valid start
	of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
	or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
@(require_results)
resize :: proc(
	ptr: rawptr,
	old_size: int,
	new_size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	data, err := runtime.mem_resize(ptr, old_size, new_size, alignment, allocator, loc)
	return raw_data(data), err
}

/*
Resize a memory region without zero-initialization.

This procedure resizes a memory region, `old_size` bytes in size, located at
the address specified by `ptr`, such that it has a new size, specified by
`new_size` and and is aligned on a boundary specified by `alignment`.

If the `ptr` parameter is `nil`, `resize()` acts just like `alloc()`, allocating
`new_size` bytes, aligned on a boundary specified by `alignment`.

If the `new_size` parameter is `0`, `resize()` acts just like `free()`, freeing
the memory region `old_size` bytes in length, located at the address specified
by `ptr`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

Unlike `resize()`, this procedure does not explicitly zero-initialize any new
memory.

**Inputs**:
- `ptr`: Pointer to the memory region to resize.
- `old_size`: Size of the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The pointer to the resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
	allocator does not have enough space to fit in an allocation with the new
	size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
	to any of the allocators backing buffers or does not point to a valid start
	of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
	or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
@(require_results)
resize_non_zeroed :: proc(
	ptr: rawptr,
	old_size: int,
	new_size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	data, err := runtime.non_zero_mem_resize(ptr, old_size, new_size, alignment, allocator, loc)
	return raw_data(data), err
}

/*
Resize a memory region.

This procedure resizes a memory region, specified by `old_data`, such that it
has a new size, specified by `new_size` and and is aligned on a boundary
specified by `alignment`.

If the `old_data` parameter is `nil`, `resize_bytes()` acts just like
`alloc_bytes()`, allocating `new_size` bytes, aligned on a boundary specified
by `alignment`.

If the `new_size` parameter is `0`, `resize_bytes()` acts just like
`free_bytes()`, freeing the memory region specified by `old_data`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

**Inputs**:
- `old_data`: Pointer to the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
	allocator does not have enough space to fit in an allocation with the new
	size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
	to any of the allocators backing buffers or does not point to a valid start
	of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
	or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
@(require_results)
resize_bytes :: proc(
	old_data: []byte,
	new_size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return runtime.mem_resize(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}

/*
Resize a memory region.

This procedure resizes a memory region, specified by `old_data`, such that it
has a new size, specified by `new_size` and and is aligned on a boundary
specified by `alignment`.

If the `old_data` parameter is `nil`, `resize_bytes()` acts just like
`alloc_bytes()`, allocating `new_size` bytes, aligned on a boundary specified
by `alignment`.

If the `new_size` parameter is `0`, `resize_bytes()` acts just like
`free_bytes()`, freeing the memory region specified by `old_data`.

If the `old_memory` pointer is not aligned to the boundary specified by
`alignment`, the procedure relocates the buffer such that the reallocated
buffer is aligned to the boundary specified by `alignment`.

Unlike `resize_bytes()`, this procedure does not explicitly zero-initialize
any new memory.

**Inputs**:
- `old_data`: Pointer to the memory region to resize.
- `new_size`: The desired size of the resized memory region.
- `alignment`: The desired alignment of the resized memory region.
- `allocator`: The owner of the memory region to resize.

**Returns**:
1. The resized memory region, if successfull, `nil` otherwise.
2. Error, if resize failed.

**Errors**:
- `None`: No error.
- `Out_Of_Memory`: When the allocator's backing buffer or it's backing
	allocator does not have enough space to fit in an allocation with the new
	size, or an operating system failure occurs.
- `Invalid_Pointer`: The pointer referring to a memory region does not belong
	to any of the allocators backing buffers or does not point to a valid start
	of an allocation made in that allocator.
- `Invalid_Argument`: When `size` is negative, alignment is not a power of two,
	or the `old_size` argument is incorrect.
- `Mode_Not_Implemented`: The allocator does not support the `.Realloc` mode.

**Note**: if `old_size` is `0` and `old_memory` is `nil`, this operation is a
no-op, and should not return errors.
*/
@(require_results)
resize_bytes_non_zeroed :: proc(
	old_data: []byte,
	new_size: int,
	alignment: int = DEFAULT_ALIGNMENT,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return runtime.non_zero_mem_resize(raw_data(old_data), len(old_data), new_size, alignment, allocator, loc)
}

/*
Query allocator features.
*/
@(require_results)
query_features :: proc(allocator: Allocator, loc := #caller_location) -> (set: Allocator_Mode_Set) {
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, .Query_Features, 0, 0, &set, 0, loc)
		return set
	}
	return nil
}

/*
Query allocator information.
*/
@(require_results)
query_info :: proc(
	pointer: rawptr,
	allocator: Allocator,
	loc := #caller_location,
) -> (props: Allocator_Query_Info) {
	props.pointer = pointer
	if allocator.procedure != nil {
		allocator.procedure(allocator.data, .Query_Info, 0, 0, &props, 0, loc)
	}
	return
}

/*
Free a string.
*/
delete_string :: proc(
	str: string,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_string(str, allocator, loc)
}

/*
Free a cstring.
*/
delete_cstring :: proc(
	str: cstring,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_cstring(str, allocator, loc)
}

/*
Free a dynamic array.
*/
delete_dynamic_array :: proc(
	array: $T/[dynamic]$E,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_dynamic_array(array, loc)
}

/*
Free a slice.
*/
delete_slice :: proc(
	array: $T/[]$E,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_slice(array, allocator, loc)
}

/*
Free a map.
*/
delete_map :: proc(
	m: $T/map[$K]$V,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_map(m, loc)
}

/*
Free an SoA slice.
*/
delete_soa_slice :: proc(
	array: $T/#soa[]$E,
	allocator := context.allocator,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_soa_slice(array, allocator, loc)
}

/*
Free an SoA dynamic array.
*/
delete_soa_dynamic_array :: proc(
	array: $T/#soa[dynamic]$E,
	loc := #caller_location,
) -> Allocator_Error {
	return runtime.delete_soa_dynamic_array(array, loc)
}

/*
Free.
*/
delete :: proc{
	delete_string,
	delete_cstring,
	delete_dynamic_array,
	delete_slice,
	delete_map,
	delete_soa_slice,
	delete_soa_dynamic_array,
}

/*
Allocate a new object.

This procedure allocates a new object of type `T` using an allocator specified
by `allocator`, and returns a pointer to the allocated object, if allocated
successfully, or `nil` otherwise.
*/
@(require_results)
new :: proc(
	$T: typeid,
	allocator := context.allocator,
	loc := #caller_location,
) -> (^T, Allocator_Error) {
	return new_aligned(T, align_of(T), allocator, loc)
}

/*
Allocate a new object with alignment.

This procedure allocates a new object of type `T` using an allocator specified
by `allocator`, and returns a pointer, aligned on a boundary specified by
`alignment`  to the allocated object, if allocated successfully, or `nil`
otherwise.
*/
@(require_results)
new_aligned :: proc(
	$T: typeid,
	alignment: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (t: ^T, err: Allocator_Error) {
	return runtime.new_aligned(T, alignment, allocator, loc)
}

/*
Allocate a new object and initialize it with a value.

This procedure allocates a new object of type `T` using an allocator specified
by `allocator`, and returns a pointer, aligned on a boundary specified by
`alignment`  to the allocated object, if allocated successfully, or `nil`
otherwise. The allocated object is initialized with `data`.
*/
@(require_results)
new_clone :: proc(
	data: $T,
	allocator := context.allocator,
	loc := #caller_location,
) -> (t: ^T, err: Allocator_Error) {
	return runtime.new_clone(data, allocator, loc)
}

/*
Allocate a new slice with alignment.

This procedure allocates a new slice of type `T` with length `len`, aligned
on a boundary specified by `alignment` from an allocator specified by
`allocator`, and returns the allocated slice.
*/
@(require_results)
make_aligned :: proc(
	$T: typeid/[]$E,
	#any_int len: int,
	alignment: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (slice: T, err: Allocator_Error) {
	return runtime.make_aligned(T, len, alignment, allocator, loc)
}

/*
Allocate a new slice.

This procedure allocates a new slice of type `T` with length `len`, from an
allocator specified by `allocator`, and returns the allocated slice.
*/
@(require_results)
make_slice :: proc(
	$T: typeid/[]$E,
	#any_int len: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (T, Allocator_Error) {
	return runtime.make_slice(T, len, allocator, loc)
}

/*
Allocate a dynamic array.

This procedure creates a dynamic array of type `T`, with `allocator` as its
backing allocator, and initial length and capacity of `0`.
*/
@(require_results)
make_dynamic_array :: proc(
	$T: typeid/[dynamic]$E,
	allocator := context.allocator,
	loc := #caller_location,
) -> (T, Allocator_Error) {
	return runtime.make_dynamic_array(T, allocator, loc)
}

/*
Allocate a dynamic array with initial length.

This procedure creates a dynamic array of type `T`, with `allocator` as its
backing allocator, and initial capacity and length specified by `len`.
*/
@(require_results)
make_dynamic_array_len :: proc(
	$T: typeid/[dynamic]$E,
	#any_int len: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (T, Allocator_Error) {
	return runtime.make_dynamic_array_len(T, len, allocator, loc)
}

/*
Allocate a dynamic array with initial length and capacity.

This procedure creates a dynamic array of type `T`, with `allocator` as its
backing allocator, and initial capacity specified by `cap`, and initial length
specified by `len`.
*/
@(require_results)
make_dynamic_array_len_cap :: proc(
	$T: typeid/[dynamic]$E,
	#any_int len: int,
	#any_int cap: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (array: T, err: Allocator_Error) {
	return runtime.make_dynamic_array_len_cap(T, len, cap, allocator, loc)
}

/*
Allocate a map.

This procedure creates a map of type `T` with initial capacity specified by
`cap`, that is using an allocator specified by `allocator` as its backing
allocator.
*/
@(require_results)
make_map :: proc(
	$T: typeid/map[$K]$E,
	#any_int cap: int = 1<<runtime.MAP_MIN_LOG2_CAPACITY,
	allocator := context.allocator,
	loc := #caller_location,
) -> (m: T, err: Allocator_Error) {
	return runtime.make_map(T, cap, allocator, loc)
}

/*
Allocate a multi pointer.

This procedure allocates a multipointer of type `T` pointing to `len` elements,
from an allocator specified by `allocator`.
*/
@(require_results)
make_multi_pointer :: proc(
	$T: typeid/[^]$E,
	#any_int len: int,
	allocator := context.allocator,
	loc := #caller_location
) -> (mp: T, err: Allocator_Error) {
	return runtime.make_multi_pointer(T, len, allocator, loc)
}

/*
Allocate an SoA slice.

This procedure allocates an SoA slice of type `T` with length `len`, from an
allocator specified by `allocator`, and returns the allocated SoA slice.
*/
@(require_results)
make_soa_slice :: proc(
	$T: typeid/#soa[]$E,
	#any_int len: int,
	allocator := context.allocator,
	loc := #caller_location
) -> (array: T, err: Allocator_Error) {
	return runtime.make_soa_slice(T, len, allocator, loc)
}

/*
Allocate an SoA dynamic array.

This procedure creates an SoA dynamic array of type `T`, with `allocator` as
its backing allocator, and initial length and capacity of `0`.
*/
@(require_results)
make_soa_dynamic_array :: proc(
	$T: typeid/#soa[dynamic]$E,
	allocator := context.allocator,
	loc := #caller_location
) -> (array: T, err: Allocator_Error) {
	return runtime.make_soa_dynamic_array(T, allocator, loc)
}

/*
Allocate an SoA dynamic array with initial length.

This procedure creates an SoA dynamic array of type `T`, with `allocator` as its
backing allocator, and initial capacity and length specified by `len`.
*/
@(require_results)
make_soa_dynamic_array_len :: proc(
	$T: typeid/#soa[dynamic]$E,
	#any_int len: int,
	allocator := context.allocator,
	loc := #caller_location
) -> (array: T, err: Allocator_Error) {
	return runtime.make_soa_dynamic_array_len(T, len, allocator, loc)
}

/*
Allocate an SoA dynamic array with initial length and capacity.

This procedure creates an SoA dynamic array of type `T`, with `allocator` as its
backing allocator, and initial capacity specified by `cap`, and initial length
specified by `len`.
*/
@(require_results)
make_soa_dynamic_array_len_cap :: proc(
	$T: typeid/#soa[dynamic]$E,
	#any_int len: int,
	#any_int cap: int,
	allocator := context.allocator,
	loc := #caller_location
) -> (array: T, err: Allocator_Error) {
	return runtime.make_soa_dynamic_array_len_cap(T, len, cap, allocator, loc)
}

/*
Allocate.
*/
make :: proc{
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
	make_soa_slice,
	make_soa_dynamic_array,
	make_soa_dynamic_array_len,
	make_soa_dynamic_array_len_cap,
}

/*
Default resize procedure.

When allocator does not support resize operation, but supports `.Alloc` and
`.Free`, this procedure is used to implement allocator's default behavior on
resize.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
	region of `old_size` bytes located at `old_memory`.
- If `old_memory` is `nil`, the function acts like `alloc()`, allocating
	`new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
	data from the old memory region is copied and the old memory region is
	freed.
*/
@(require_results)
default_resize_align :: proc(
	old_memory: rawptr,
	old_size: int,
	new_size: int,
	alignment: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> (res: rawptr, err: Allocator_Error) {
	data: []byte
	data, err = default_resize_bytes_align(
		([^]byte) (old_memory)[:old_size],
		new_size,
		alignment,
		allocator,
		loc,
	)
	res = raw_data(data)
	return
}

/*
Default resize procedure.

When allocator does not support resize operation, but supports
`.Alloc_Non_Zeroed` and `.Free`, this procedure is used to implement allocator's
default behavior on resize.

Unlike `default_resize_align` no new memory is being explicitly
zero-initialized.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
	region of `old_size` bytes located at `old_memory`.
- If `old_memory` is `nil`, the function acts like `alloc()`, allocating
	`new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
	data from the old memory region is copied and the old memory region is
	freed.
*/
@(require_results)
default_resize_bytes_align_non_zeroed :: proc(
	old_data: []byte,
	new_size: int,
	alignment: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return _default_resize_bytes_align(old_data, new_size, alignment, false, allocator, loc)
}

/*
Default resize procedure.

When allocator does not support resize operation, but supports `.Alloc` and
`.Free`, this procedure is used to implement allocator's default behavior on
resize.

The behavior of the function is as follows:

- If `new_size` is `0`, the function acts like `free()`, freeing the memory
	region specified by `old_data`.
- If `old_data` is `nil`, the function acts like `alloc()`, allocating
	`new_size` bytes of memory aligned on a boundary specified by `alignment`.
- Otherwise, a new memory region of size `new_size` is allocated, then the
	data from the old memory region is copied and the old memory region is
	freed.
*/
@(require_results)
default_resize_bytes_align :: proc(
	old_data: []byte,
	new_size: int,
	alignment: int,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return _default_resize_bytes_align(old_data, new_size, alignment, true, allocator, loc)
}

@(require_results)
_default_resize_bytes_align :: #force_inline proc(
	old_data: []byte,
	new_size: int,
	alignment: int,
	should_zero: bool,
	allocator := context.allocator,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if old_memory == nil {
		if should_zero {
			return alloc_bytes(new_size, alignment, allocator, loc)
		} else {
			return alloc_bytes_non_zeroed(new_size, alignment, allocator, loc)
		}
	}
	if new_size == 0 {
		err := free_bytes(old_data, allocator, loc)
		return nil, err
	}
	if new_size == old_size && is_aligned(old_memory, alignment) {
		return old_data, .None
	}
	new_memory : []byte
	err : Allocator_Error
	if should_zero {
		new_memory, err = alloc_bytes(new_size, alignment, allocator, loc)
	} else {
		new_memory, err = alloc_bytes_non_zeroed(new_size, alignment, allocator, loc)
	}
	if new_memory == nil || err != nil {
		return nil, err
	}
	runtime.copy(new_memory, old_data)
	free_bytes(old_data, allocator, loc)
	return new_memory, err
}
