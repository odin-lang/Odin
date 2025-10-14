package mem

import "base:intrinsics"
import "base:runtime"

// NOTE(Feoramund): Sanitizer usage in this package has been temporarily
// disabled pending a thorough review per allocator, as ASan is particular
// about the addresses and ranges it receives.
//
// In short, it keeps track only of 8-byte blocks. This can cause issues if an
// allocator poisons an entire range but an allocation for less than 8 bytes is
// desired or if the next allocation address would not be 8-byte aligned.
//
// This must be handled carefully on a per-allocator basis and some allocators
// may not be able to participate.
//
// Please see the following link for more information:
//
// https://github.com/google/sanitizers/wiki/AddressSanitizerAlgorithm#mapping
//
// import "base:sanitizer"


/*
This procedure checks if a byte slice `range` is poisoned and makes sure the
root address of the poison range is the base pointer of `range`.

This can help guard against buggy allocators returning memory that they already returned.

This has no effect if `-sanitize:address` is not enabled.
*/
// @(disabled=.Address not_in ODIN_SANITIZER_FLAGS, private)
// ensure_poisoned :: proc(range: []u8, loc := #caller_location) {
// 	cond := sanitizer.address_region_is_poisoned(range) == raw_data(range)
// 	// If this fails, we've overlapped an allocation and it's our fault.
// 	ensure(cond, `This allocator has sliced a block of memory of which some part is not poisoned before returning.
// This is a bug in the core library and should be reported to the Odin developers with a stack trace and minimal example code if possible.`, loc)
// }

/*
This procedure checks if a byte slice `range` is not poisoned.

This can help guard against buggy allocators resizing memory that they should not.

This has no effect if `-sanitize:address` is not enabled.
*/
// @(disabled=.Address not_in ODIN_SANITIZER_FLAGS, private)
// ensure_not_poisoned :: proc(range: []u8, loc := #caller_location) {
// 	cond := sanitizer.address_region_is_poisoned(range) == nil
// 	// If this fails, we've tried to resize memory that is poisoned, which
// 	// could be user error caused by an incorrect `old_memory` pointer.
// 	ensure(cond, `This allocator has sliced a block of memory of which some part is poisoned before returning.
// This may be a bug in the core library, or it could be user error due to an invalid pointer passed to a resize operation.
// If after ensuring your own code is not responsible, report the problem to the Odin developers with a stack trace and minimal example code if possible.`, loc)
// }

/*
Nil allocator.

The `nil` allocator returns `nil` on every allocation attempt. This type of
allocator can be used in scenarios where memory doesn't need to be allocated,
but an attempt to allocate memory is not an error.
*/
@(require_results)
nil_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data      = nil,
	}
}

nil_allocator_proc :: proc(
	allocator_data:  rawptr,
	mode:            Allocator_Mode,
	size, alignment: int,
	old_memory:      rawptr,
	old_size:        int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	return nil, nil
}


/*
Panic allocator.

The panic allocator is a type of allocator that panics on any allocation
attempt. This type of allocator can be used in scenarios where memory should
not be allocated, and an attempt to allocate memory is an error.
*/
@(require_results)
panic_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = panic_allocator_proc,
		data      = nil,
	}
}

panic_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
    size, alignment: int,
    old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	switch mode {
	case .Alloc:
		if size > 0 {
			panic("mem: panic allocator, .Alloc called", loc=loc)
		}
	case .Alloc_Non_Zeroed:
		if size > 0 {
			panic("mem: panic allocator, .Alloc_Non_Zeroed called", loc=loc)
		}
	case .Resize:
		if size > 0 {
			panic("mem: panic allocator, .Resize called", loc=loc)
		}
	case .Resize_Non_Zeroed:
		if size > 0 {
			panic("mem: panic allocator, .Resize_Non_Zeroed called", loc=loc)
		}
	case .Free:
		if old_memory != nil {
			panic("mem: panic allocator, .Free called", loc=loc)
		}
	case .Free_All:
		panic("mem: panic allocator, .Free_All called", loc=loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features}
		}
		return nil, nil

	case .Query_Info:
		panic("mem: panic allocator, .Query_Info called", loc=loc)
	}
	return nil, nil
}


/*
Arena allocator data.
*/
Arena :: struct {
	data:       []byte,
	offset:     int,
	peak_used:  int,
	temp_count: int,
}

/*
Arena allocator.

The arena allocator (also known as a linear allocator, bump allocator,
region allocator) is an allocator that uses a single backing buffer for
allocations.

The buffer is used contiguously, from start to end. Each subsequent allocation
occupies the next adjacent region of memory in the buffer. Since the arena
allocator does not keep track of any metadata associated with the allocations
and their locations, it is impossible to free individual allocations.

The arena allocator can be used for temporary allocations in frame-based memory
management. Games are one example of such applications. A global arena can be
used for any temporary memory allocations, and at the end of each frame all
temporary allocations are freed. Since no temporary object is going to live
longer than a frame, no lifetimes are violated.
*/
@(require_results)
arena_allocator :: proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	}
}

/*
Initialize an arena.

This procedure initializes the arena `a` with memory region `data` as its
backing buffer.
*/
arena_init :: proc(a: ^Arena, data: []byte) {
	a.data       = data
	a.offset     = 0
	a.peak_used  = 0
	a.temp_count = 0
	// sanitizer.address_poison(a.data)
}

/*
Allocate memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is zero-initialized.
This procedure returns a pointer to the newly allocated memory region.
*/
@(require_results)
arena_alloc :: proc(
	a:    ^Arena,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := arena_alloc_bytes(a, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is zero-initialized.
This procedure returns a slice of the newly allocated memory region.
*/
@(require_results)
arena_alloc_bytes :: proc(
	a:    ^Arena,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := arena_alloc_bytes_non_zeroed(a, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate non-initialized memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a pointer to the newly allocated
memory region.
*/
@(require_results)
arena_alloc_non_zeroed :: proc(
	a:    ^Arena,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := arena_alloc_bytes_non_zeroed(a, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate non-initialized memory from an arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from an arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a slice of the newly allocated
memory region.
*/
@(require_results)
arena_alloc_bytes_non_zeroed :: proc(
	a:    ^Arena,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> ([]byte, Allocator_Error) {
	if a.data == nil {
		panic("Allocation on uninitialized Arena allocator.", loc)
	}
	#no_bounds_check end := &a.data[a.offset]
	ptr := align_forward(end, uintptr(alignment))
	total_size := size + ptr_sub((^byte)(ptr), (^byte)(end))
	if a.offset + total_size > len(a.data) {
		return nil, .Out_Of_Memory
	}
	a.offset += total_size
	a.peak_used = max(a.peak_used, a.offset)
	result := byte_slice(ptr, size)
	// ensure_poisoned(result)
	// sanitizer.address_unpoison(result)
	return result, nil
}

/*
Free all memory back to the arena allocator.
*/
arena_free_all :: proc(a: ^Arena) {
	a.offset = 0
	// sanitizer.address_poison(a.data)
}

arena_allocator_proc :: proc(
	allocator_data: rawptr,
	mode:           Allocator_Mode,
	size:           int,
	alignment:      int,
	old_memory:     rawptr,
	old_size:       int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error)  {
	arena := cast(^Arena)allocator_data
	switch mode {
	case .Alloc:
		return arena_alloc_bytes(arena, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return arena_alloc_bytes_non_zeroed(arena, size, alignment, loc)
	case .Free:
		return nil, .Mode_Not_Implemented
	case .Free_All:
		arena_free_all(arena)
	case .Resize:
		return default_resize_bytes_align(byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena), loc)
	case .Resize_Non_Zeroed:
		return default_resize_bytes_align_non_zeroed(byte_slice(old_memory, old_size), size, alignment, arena_allocator(arena), loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}

/*
Temporary memory region of an `Arena` allocator.

Temporary memory regions of an arena act as "save-points" for the allocator.
When one is created, the subsequent allocations are done inside the temporary
memory region. When `end_arena_temp_memory` is called, the arena is rolled
back, and all of the memory that was allocated from the arena will be freed.

Multiple temporary memory regions can exist at the same time for an arena.
*/
Arena_Temp_Memory :: struct {
	arena:       ^Arena,
	prev_offset: int,
}

/*
Start a temporary memory region.

This procedure creates a temporary memory region. After a temporary memory
region is created, all allocations are said to be *inside* the temporary memory
region, until `end_arena_temp_memory` is called.
*/
@(require_results)
begin_arena_temp_memory :: proc(a: ^Arena) -> Arena_Temp_Memory {
	tmp: Arena_Temp_Memory
	tmp.arena = a
	tmp.prev_offset = a.offset
	a.temp_count += 1
	return tmp
}

/*
End a temporary memory region.

This procedure ends the temporary memory region for an arena. All of the
allocations *inside* the temporary memory region will be freed to the arena.
*/
end_arena_temp_memory :: proc(tmp: Arena_Temp_Memory) {
	assert(tmp.arena.offset >= tmp.prev_offset)
	assert(tmp.arena.temp_count > 0)
	// sanitizer.address_poison(tmp.arena.data[tmp.prev_offset:tmp.arena.offset])
	tmp.arena.offset = tmp.prev_offset
	tmp.arena.temp_count -= 1
}

/* Preserved for compatibility */
Scratch_Allocator :: Scratch
scratch_allocator_init :: scratch_init
scratch_allocator_destroy :: scratch_destroy

/*
Scratch allocator data.
*/
Scratch :: struct {
	data:                 []byte,
	curr_offset:          int,
	prev_allocation:      rawptr,
	prev_allocation_root: rawptr,
	backup_allocator:     Allocator,
	leaked_allocations:   [dynamic][]byte,
}

/*
Scratch allocator.

The scratch allocator works in a similar way to the `Arena` allocator. The
scratch allocator has a backing buffer that is allocated in contiguous regions,
from start to end.

Each subsequent allocation will be the next adjacent region of memory in the
backing buffer. If the allocation doesn't fit into the remaining space of the
backing buffer, this allocation is put at the start of the buffer, and all
previous allocations will become invalidated.

If the allocation doesn't fit into the backing buffer as a whole, it will be
allocated using a backing allocator, and the pointer to the allocated memory
region will be put into the `leaked_allocations` array. A `Warning`-level log
message will be sent as well.

Allocations which are resized will be resized in-place if they were the last
allocation. Otherwise, they are re-allocated to avoid overwriting previous
allocations.

The `leaked_allocations` array is managed by the `context` allocator if no
`backup_allocator` is specified in `scratch_init`.
*/
@(require_results)
scratch_allocator :: proc(allocator: ^Scratch) -> Allocator {
	return Allocator{
		procedure = scratch_allocator_proc,
		data = allocator,
	}
}

/*
Initialize a scratch allocator.
*/
scratch_init :: proc(s: ^Scratch, size: int, backup_allocator := context.allocator) -> Allocator_Error {
	s.data = make_aligned([]byte, size, 2*align_of(rawptr), backup_allocator) or_return
	s.curr_offset = 0
	s.prev_allocation = nil
	s.prev_allocation_root = nil
	s.backup_allocator = backup_allocator
	s.leaked_allocations.allocator = backup_allocator
	// sanitizer.address_poison(s.data)
	return nil
}

/*
Free all data associated with a scratch allocator.

This is distinct from `scratch_free_all` in that it deallocates all memory used
to setup the allocator, as opposed to all allocations made from that space.
*/
scratch_destroy :: proc(s: ^Scratch) {
	if s == nil {
		return
	}
	for ptr in s.leaked_allocations {
		free_bytes(ptr, s.backup_allocator)
	}
	delete(s.leaked_allocations)
	// sanitizer.address_unpoison(s.data)
	delete(s.data, s.backup_allocator)
	s^ = {}
}

/*
Allocate memory from a scratch allocator.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment`. The allocated memory region is zero-initialized. This procedure
returns a pointer to the allocated memory region.
*/
@(require_results)
scratch_alloc :: proc(
	s:    ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := scratch_alloc_bytes(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from a scratch allocator.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment`. The allocated memory region is zero-initialized. This procedure
returns a slice of the allocated memory region.
*/
@(require_results)
scratch_alloc_bytes :: proc(
	s:    ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := scratch_alloc_bytes_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate non-initialized memory from a scratch allocator.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment`. The allocated memory region is not explicitly zero-initialized.
This procedure returns a pointer to the allocated memory region.
*/
@(require_results)
scratch_alloc_non_zeroed :: proc(
	s:    ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := scratch_alloc_bytes_non_zeroed(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate non-initialized memory from a scratch allocator.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment`. The allocated memory region is not explicitly zero-initialized.
This procedure returns a slice of the allocated memory region.
*/
@(require_results)
scratch_alloc_bytes_non_zeroed :: proc(
	s:   ^Scratch,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		DEFAULT_BACKING_SIZE :: 4 * Megabyte
		if !(context.allocator.procedure != scratch_allocator_proc && context.allocator.data != s) {
			panic("Cyclic initialization of the scratch allocator with itself.", loc)
		}
		scratch_init(s, DEFAULT_BACKING_SIZE)
	}
	aligned_size := size
	if alignment > 1 {
		// It is possible to do this with less bytes, but this is the
		// mathematically simpler solution, and this being a Scratch allocator,
		// we don't need to be so strict about every byte.
		aligned_size += alignment - 1
	}
	if aligned_size <= len(s.data) {
		offset := uintptr(0)
		if s.curr_offset+aligned_size <= len(s.data) {
			offset = uintptr(s.curr_offset)
		} else {
			// The allocation will cause an overflow past the boundary of the
			// space available, so reset to the starting offset.
			offset = 0
		}
		start := uintptr(raw_data(s.data))
		ptr := rawptr(offset+start)
		// We keep track of the original base pointer without extra alignment
		// in order to later allow the free operation to work from that point.
		s.prev_allocation_root = ptr
		if !is_aligned(ptr, alignment) {
			ptr = align_forward(ptr, uintptr(alignment))
		}
		s.prev_allocation = ptr
		s.curr_offset = int(offset) + aligned_size
		result := byte_slice(ptr, size)
		// ensure_poisoned(result)
		// sanitizer.address_unpoison(result)
		return result, nil
	} else {
		// NOTE: No need to use `aligned_size` here, as the backup allocator will handle alignment for us.
		a := s.backup_allocator
		ptr, err := alloc_bytes_non_zeroed(size, alignment, a, loc)
		if err != nil {
			return ptr, err
		}
		append(&s.leaked_allocations, ptr)
		if logger := context.logger; logger.lowest_level <= .Warning {
			if logger.procedure != nil {
				logger.procedure(logger.data, .Warning, "mem.Scratch resorted to backup_allocator" , logger.options, loc)
			}
		}
		return ptr, err
	}
}

/*
Free memory back to the scratch allocator.

This procedure frees the memory region allocated at pointer `ptr`.

If `ptr` is not the latest allocation and is not a leaked allocation, this
operation is a no-op.
*/
scratch_free :: proc(s: ^Scratch, ptr: rawptr, loc := #caller_location) -> Allocator_Error {
	if s.data == nil {
		panic("Free on an uninitialized Scratch allocator.", loc)
	}
	if ptr == nil {
		return nil
	}
	start := uintptr(raw_data(s.data))
	end := start + uintptr(len(s.data))
	old_ptr := uintptr(ptr)
	if s.prev_allocation == ptr {
		s.curr_offset = int(uintptr(s.prev_allocation_root) - start)
		// sanitizer.address_poison(s.data[s.curr_offset:])
		s.prev_allocation = nil
		s.prev_allocation_root = nil
		return nil
	}
	if start <= old_ptr && old_ptr < end {
		// NOTE(bill): Cannot free this pointer but it is valid
		return nil
	}
	if len(s.leaked_allocations) != 0 {
		for data, i in s.leaked_allocations {
			ptr := raw_data(data)
			if ptr == ptr {
				free_bytes(data, s.backup_allocator, loc)
				ordered_remove(&s.leaked_allocations, i, loc)
				return nil
			}
		}
	}
	return .Invalid_Pointer
}

/*
Free all memory back to the scratch allocator.
*/
scratch_free_all :: proc(s: ^Scratch, loc := #caller_location) {
	s.curr_offset = 0
	s.prev_allocation = nil
	for ptr in s.leaked_allocations {
		free_bytes(ptr, s.backup_allocator, loc)
	}
	clear(&s.leaked_allocations)
	// sanitizer.address_poison(s.data)
}

/*
Resize an allocation owned by a scratch allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `scratch_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `scratch_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
scratch_resize :: proc(
	s:          ^Scratch,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> (rawptr, Allocator_Error) {
	bytes, err := scratch_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a scratch allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `scratch_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `scratch_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
scratch_resize_bytes :: proc(
	s:        ^Scratch,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> ([]byte, Allocator_Error) {
	bytes, err := scratch_resize_bytes_non_zeroed(s, old_data, size, alignment, loc)
	if bytes != nil && size > len(old_data) {
		zero_slice(bytes[size:])
	}
	return bytes, err
}

/*
Resize an allocation owned by a scratch allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `scratch_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `scratch_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
scratch_resize_non_zeroed :: proc(
	s:          ^Scratch,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> (rawptr, Allocator_Error) {
	bytes, err := scratch_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a scratch allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `scratch_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `scratch_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
scratch_resize_bytes_non_zeroed :: proc(
	s:        ^Scratch,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> ([]byte, Allocator_Error) {
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if s.data == nil {
		DEFAULT_BACKING_SIZE :: 4 * Megabyte
		if !(context.allocator.procedure != scratch_allocator_proc && context.allocator.data != s) {
			panic("Cyclic initialization of the scratch allocator with itself.", loc)
		}
		scratch_init(s, DEFAULT_BACKING_SIZE)
	}
	begin   := uintptr(raw_data(s.data))
	end     := begin + uintptr(len(s.data))
	old_ptr := uintptr(old_memory)
	// We can only sanely resize the last allocation; to do otherwise may
	// overwrite memory that could very well just have been allocated.
	//
	// Also, the alignments must match, otherwise we must re-allocate to
	// guarantee the user's request.
	if s.prev_allocation == old_memory && is_aligned(old_memory, alignment) && old_ptr+uintptr(size) < end {
		// ensure_not_poisoned(old_data)
		// sanitizer.address_poison(old_memory)
		s.curr_offset = int(old_ptr-begin)+size
		result := byte_slice(old_memory, size)
		// sanitizer.address_unpoison(result)
		return result, nil
	}
	data, err := scratch_alloc_bytes_non_zeroed(s, size, alignment, loc)
	if err != nil {
		return data, err
	}
	runtime.copy(data, byte_slice(old_memory, old_size))
	err = scratch_free(s, old_memory, loc)
	return data, err
}

scratch_allocator_proc :: proc(
	allocator_data:  rawptr,
	mode:            Allocator_Mode,
	size, alignment: int,
	old_memory:      rawptr,
	old_size:        int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := (^Scratch)(allocator_data)
	size := size
	switch mode {
	case .Alloc:
		return scratch_alloc_bytes(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return scratch_alloc_bytes_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, scratch_free(s, old_memory, loc)
	case .Free_All:
		scratch_free_all(s, loc)
	case .Resize:
		return scratch_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Resize_Non_Zeroed:
		return scratch_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}



/*
Stack allocator data.
*/
Stack :: struct {
	data:        []byte,
	prev_offset: int,
	curr_offset: int,
	peak_used:   int,
}

/*
Header of a stack allocation.
*/
Stack_Allocation_Header :: struct {
	prev_offset: int,
	padding:     int,
}

/*
Stack allocator.

The stack allocator is an allocator that allocates data in the backing buffer
linearly, from start to end. Each subsequent allocation will get the next
adjacent memory region.

Unlike arena allocator, the stack allocator saves allocation metadata and has
a strict freeing order. Only the last allocated element can be freed. After the
last allocated element is freed, the next previous allocated element becomes
available for freeing.

The metadata is stored in the allocation headers, that are located before the
start of each allocated memory region. Each header points to the start of the
previous allocation header.
*/
@(require_results)
stack_allocator :: proc(stack: ^Stack) -> Allocator {
	return Allocator{
		procedure = stack_allocator_proc,
		data      = stack,
	}
}

/*
Initialize a stack allocator.

This procedure initializes the stack allocator with a backing buffer specified
by `data` parameter.
*/
stack_init :: proc(s: ^Stack, data: []byte) {
	s.data        = data
	s.prev_offset = 0
	s.curr_offset = 0
	s.peak_used   = 0
	// sanitizer.address_poison(data)
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is zero-initialized. This
procedure returns the pointer to the allocated memory.
*/
@(require_results)
stack_alloc :: proc(
	s:    ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> (rawptr, Allocator_Error) {
	bytes, err := stack_alloc_bytes(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is zero-initialized. This
procedure returns the slice of the allocated memory.
*/
@(require_results)
stack_alloc_bytes :: proc(
	s:    ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> ([]byte, Allocator_Error) {
	bytes, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is not explicitly
zero-initialized. This procedure returns the pointer to the allocated memory.
*/
@(require_results)
stack_alloc_non_zeroed :: proc(
	s:    ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> (rawptr, Allocator_Error) {
	bytes, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from a stack allocator.

This procedure allocates `size` bytes of memory, aligned to the boundary
specified by `alignment`. The allocated memory is not explicitly
zero-initialized. This procedure returns the slice of the allocated memory.
*/
@(require_results, no_sanitize_address)
stack_alloc_bytes_non_zeroed :: proc(
	s:    ^Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		panic("Allocation on an uninitialized Stack allocator.", loc)
	}
	curr_addr := uintptr(raw_data(s.data)) + uintptr(s.curr_offset)
	padding := calc_padding_with_header(
		curr_addr,
		uintptr(alignment),
		size_of(Stack_Allocation_Header),
	)
	if s.curr_offset + padding + size > len(s.data) {
		return nil, .Out_Of_Memory
	}
	old_offset := s.prev_offset
	s.prev_offset = s.curr_offset
	s.curr_offset += padding
	next_addr := curr_addr + uintptr(padding)
	header := (^Stack_Allocation_Header)(next_addr - size_of(Stack_Allocation_Header))
	header.padding = padding
	header.prev_offset = old_offset
	s.curr_offset += size
	s.peak_used = max(s.peak_used, s.curr_offset)
	result := byte_slice(rawptr(next_addr), size)
	// ensure_poisoned(result)
	// sanitizer.address_unpoison(result)
	return result, nil
}

/*
Free memory back to the stack allocator.

This procedure frees the memory region starting at `old_memory` to the stack.
If the freeing is an out of order freeing, the `.Invalid_Pointer` error
is returned.
*/
stack_free :: proc(
	s:          ^Stack,
	old_memory: rawptr,
	loc := #caller_location,
) -> (Allocator_Error) {
	if s.data == nil {
		panic("Free on an uninitialized Stack allocator.", loc)
	}
	if old_memory == nil {
		return nil
	}
	start := uintptr(raw_data(s.data))
	end := start + uintptr(len(s.data))
	curr_addr := uintptr(old_memory)
	if !(start <= curr_addr && curr_addr < end) {
		panic("Out of bounds memory address passed to Stack allocator. (free)", loc)
	}
	if curr_addr >= start+uintptr(s.curr_offset) {
		// NOTE(bill): Allow double frees
		return nil
	}
	header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
	old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
	if old_offset != s.prev_offset {
		return .Invalid_Pointer
	}

	s.prev_offset = header.prev_offset
	// sanitizer.address_poison(s.data[old_offset:s.curr_offset])
	s.curr_offset = old_offset

	return nil
}

/*
Free all memory back to the stack allocator.
*/
stack_free_all :: proc(s: ^Stack, loc := #caller_location) {
	s.prev_offset = 0
	s.curr_offset = 0
	// sanitizer.address_poison(s.data)
}

/*
Resize an allocation owned by a stack allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
stack_resize :: proc(
	s:          ^Stack,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := stack_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a stack allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
stack_resize_bytes :: proc(
	s:        ^Stack,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := stack_resize_bytes_non_zeroed(s, old_data, size, alignment, loc)
	if err == nil {
		if old_data == nil {
			zero_slice(bytes)
		} else if size > len(old_data) {
			zero_slice(bytes[len(old_data):])
		}
	}
	return bytes, err
}

/*
Resize an allocation owned by a stack allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
stack_resize_non_zeroed :: proc(
	s:          ^Stack,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := stack_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a stack allocator, without zero-initialization.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
stack_resize_bytes_non_zeroed :: proc(
	s:        ^Stack,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if s.data == nil {
		panic("Resize on an uninitialized Stack allocator.", loc)
	}
	if old_memory == nil {
		return stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	}
	if size == 0 {
		return nil, stack_free(s, old_memory, loc)
	}
	start     := uintptr(raw_data(s.data))
	end       := start + uintptr(len(s.data))
	curr_addr := uintptr(old_memory)
	if !(start <= curr_addr && curr_addr < end) {
		panic("Out of bounds memory address passed to Stack allocator. (resize)")
	}
	if curr_addr >= start+uintptr(s.curr_offset) {
		// NOTE(bill): Allow double frees
		return nil, nil
	}
	if uintptr(old_memory) & uintptr(alignment-1) != 0 {
		// A different alignment has been requested and the current address
		// does not satisfy it.
		data, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
			// sanitizer.address_poison(old_memory)
		}
		return data, err
	}
	if old_size == size {
		return byte_slice(old_memory, size), nil
	}
	header := (^Stack_Allocation_Header)(curr_addr - size_of(Stack_Allocation_Header))
	old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
	if old_offset != header.prev_offset {
		data, err := stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
			// sanitizer.address_poison(old_memory)
		}
		return data, err
	}
	old_memory_size := uintptr(s.curr_offset) - (curr_addr - start)
	assert(old_memory_size == uintptr(old_size))
	diff := size - old_size
	s.curr_offset += diff // works for smaller sizes too
	if diff > 0 {
		zero(rawptr(curr_addr + uintptr(diff)), diff)
	} else {
		// sanitizer.address_poison(old_data[size:])
	}
	result := byte_slice(old_memory, size)
	// ensure_poisoned(result)
	// sanitizer.address_unpoison(result)
	return result, nil
}

stack_allocator_proc :: proc(
	allocator_data: rawptr,
	mode:           Allocator_Mode,
	size:           int,
	alignment:      int,
	old_memory:     rawptr,
	old_size:       int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := cast(^Stack)allocator_data
	if s.data == nil {
		return nil, .Invalid_Argument
	}
	switch mode {
	case .Alloc:
		return stack_alloc_bytes(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, stack_free(s, old_memory, loc)
	case .Free_All:
		stack_free_all(s, loc)
	case .Resize:
		return stack_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Resize_Non_Zeroed:
		return stack_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}


/*
Allocation header of the small stack allocator.
*/
Small_Stack_Allocation_Header :: struct {
	padding: u8,
}

/*
Small stack allocator data.
*/
Small_Stack :: struct {
	data:      []byte,
	offset:    int,
	peak_used: int,
}

/*
Initialize a small stack allocator.

This procedure initializes the small stack allocator with `data` as its backing
buffer.
*/
small_stack_init :: proc(s: ^Small_Stack, data: []byte) {
	s.data      = data
	s.offset    = 0
	s.peak_used = 0
	// sanitizer.address_poison(data)
}

/*
Small stack allocator.

The small stack allocator is just like a `Stack` allocator, with the only
difference being an extremely small header size. Unlike the stack allocator,
the small stack allows out-of order freeing of memory, with the stipulation
that all allocations made after the freed allocation will become invalidated
upon following allocations as they will begin to overwrite the memory formerly
used by the freed allocation.

The memory is allocated in the backing buffer linearly, from start to end.
Each subsequent allocation will get the next adjacent memory region.

The metadata is stored in the allocation headers, that are located before the
start of each allocated memory region. Each header contains the amount of
padding bytes between that header and end of the previous allocation.
*/
@(require_results)
small_stack_allocator :: proc(stack: ^Small_Stack) -> Allocator {
	return Allocator{
		procedure = small_stack_allocator_proc,
		data      = stack,
	}
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is zero-initialized. This procedure
returns a pointer to the allocated memory region.
*/
@(require_results)
small_stack_alloc :: proc(
	s:    ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := small_stack_alloc_bytes(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is zero-initialized. This procedure
returns a slice of the allocated memory region.
*/
@(require_results)
small_stack_alloc_bytes :: proc(
	s:    ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a pointer to the allocated memory region.
*/
@(require_results)
small_stack_alloc_non_zeroed :: proc(
	s:    ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a slice of the allocated memory region.
*/
@(require_results, no_sanitize_address)
small_stack_alloc_bytes_non_zeroed :: proc(
	s:    ^Small_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		panic("Allocation on an uninitialized Small Stack allocator.", loc)
	}
	alignment := alignment
	alignment = clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
	curr_addr := uintptr(raw_data(s.data)) + uintptr(s.offset)
	padding := calc_padding_with_header(curr_addr, uintptr(alignment), size_of(Small_Stack_Allocation_Header))
	if s.offset + padding + size > len(s.data) {
		return nil, .Out_Of_Memory
	}
	s.offset += padding
	next_addr := curr_addr + uintptr(padding)
	header := (^Small_Stack_Allocation_Header)(next_addr - size_of(Small_Stack_Allocation_Header))
	header.padding = cast(u8)padding
	// We must poison the header, no matter what its state is, because there
	// may have been an out-of-order free before this point.
	// sanitizer.address_poison(header)
	s.offset += size
	s.peak_used = max(s.peak_used, s.offset)
	result := byte_slice(rawptr(next_addr), size)
	// NOTE: We cannot ensure the poison state of this allocation, because this
	// allocator allows out-of-order frees with overwriting.
	// sanitizer.address_unpoison(result)
	return result, nil
}

/*
Allocate memory from a small stack allocator.

This procedure allocates `size` bytes of memory aligned to a boundary specified
by `alignment`. The allocated memory is not explicitly zero-initialized. This
procedure returns a slice of the allocated memory region.
*/
small_stack_free :: proc(
	s:          ^Small_Stack,
	old_memory: rawptr,
	loc := #caller_location,
) -> Allocator_Error {
	if s.data == nil {
		panic("Free on an uninitialized Small Stack allocator.", loc)
	}
	if old_memory == nil {
		return nil
	}
	start := uintptr(raw_data(s.data))
	end := start + uintptr(len(s.data))
	curr_addr := uintptr(old_memory)
	if !(start <= curr_addr && curr_addr < end) {
		panic("Out of bounds memory address passed to Small Stack allocator. (free)", loc)
	}
	if curr_addr >= start+uintptr(s.offset) {
		// NOTE(bill): Allow double frees
		return nil
	}
	header := (^Small_Stack_Allocation_Header)(curr_addr - size_of(Small_Stack_Allocation_Header))
	old_offset := int(curr_addr - uintptr(header.padding) - uintptr(raw_data(s.data)))
	// sanitizer.address_poison(s.data[old_offset:s.offset])
	s.offset = old_offset
	return nil
}

/*
Free all memory back to the small stack allocator.
*/
small_stack_free_all :: proc(s: ^Small_Stack) {
	s.offset = 0
	// sanitizer.address_poison(s.data)
}

/*
Resize an allocation owned by a small stack allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
small_stack_resize :: proc(
	s:          ^Small_Stack,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := small_stack_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a small stack allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
small_stack_resize_bytes :: proc(
	s:        ^Small_Stack,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := small_stack_resize_bytes_non_zeroed(s, old_data, size, alignment, loc)
	if bytes != nil {
		if old_data == nil {
			zero_slice(bytes)
		} else if size > len(old_data) {
			zero_slice(bytes[len(old_data):])
		}
	}
	return bytes, err
}

/*
Resize an allocation owned by a small stack allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
small_stack_resize_non_zeroed :: proc(
	s:          ^Small_Stack,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := small_stack_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a small stack allocator, without zero-initialization.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `small_stack_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

If `size` is 0, this procedure acts just like `small_stack_free()`, freeing the
memory region located at an address specified by `old_memory`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
small_stack_resize_bytes_non_zeroed :: proc(
	s:        ^Small_Stack,
	old_data: []byte,
	size:     int,
	alignment := DEFAULT_ALIGNMENT,
	loc       := #caller_location,
) -> ([]byte, Allocator_Error) {
	if s.data == nil {
		panic("Resize on an uninitialized Small Stack allocator.", loc)
	}
	old_memory := raw_data(old_data)
	old_size   := len(old_data)
	alignment  := alignment
	alignment = clamp(alignment, 1, 8*size_of(Stack_Allocation_Header{}.padding)/2)
	if old_memory == nil {
		return small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	}
	if size == 0 {
		return nil, small_stack_free(s, old_memory, loc)
	}
	start     := uintptr(raw_data(s.data))
	end       := start + uintptr(len(s.data))
	curr_addr := uintptr(old_memory)
	if !(start <= curr_addr && curr_addr < end) {
		panic("Out of bounds memory address passed to Small Stack allocator. (resize)", loc)
	}
	if curr_addr >= start+uintptr(s.offset) {
		// NOTE(bill): Treat as a double free
		return nil, nil
	}
	if uintptr(old_memory) & uintptr(alignment-1) != 0 {
		// A different alignment has been requested and the current address
		// does not satisfy it.
		data, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
		if err == nil {
			runtime.copy(data, byte_slice(old_memory, old_size))
			// sanitizer.address_poison(old_memory)
		}
		return data, err
	}
	if old_size == size {
		result := byte_slice(old_memory, size)
		// sanitizer.address_unpoison(result)
		return result, nil
	}
	data, err := small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	if err == nil {
		runtime.copy(data, byte_slice(old_memory, old_size))
	}
	return data, err

}

small_stack_allocator_proc :: proc(
	allocator_data:  rawptr,
	mode:            Allocator_Mode,
	size, alignment: int,
	old_memory:      rawptr,
	old_size:        int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	s := cast(^Small_Stack)allocator_data
	if s.data == nil {
		return nil, .Invalid_Argument
	}
	switch mode {
	case .Alloc:
		return small_stack_alloc_bytes(s, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return small_stack_alloc_bytes_non_zeroed(s, size, alignment, loc)
	case .Free:
		return nil, small_stack_free(s, old_memory, loc)
	case .Free_All:
		small_stack_free_all(s)
	case .Resize:
		return small_stack_resize_bytes(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Resize_Non_Zeroed:
		return small_stack_resize_bytes_non_zeroed(s, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, nil
}


/* Preserved for compatibility */
Dynamic_Pool                          :: Dynamic_Arena
DYNAMIC_POOL_BLOCK_SIZE_DEFAULT       :: DYNAMIC_ARENA_BLOCK_SIZE_DEFAULT
DYNAMIC_POOL_OUT_OF_BAND_SIZE_DEFAULT :: DYNAMIC_ARENA_OUT_OF_BAND_SIZE_DEFAULT
dynamic_pool_allocator_proc           :: dynamic_arena_allocator_proc
dynamic_pool_free_all                 :: dynamic_arena_free_all
dynamic_pool_reset                    :: dynamic_arena_reset
dynamic_pool_alloc_bytes              :: dynamic_arena_alloc_bytes
dynamic_pool_alloc                    :: dynamic_arena_alloc
dynamic_pool_init                     :: dynamic_arena_init
dynamic_pool_allocator                :: dynamic_arena_allocator
dynamic_pool_destroy                  :: dynamic_arena_destroy

/*
Default block size for dynamic arena.
*/
DYNAMIC_ARENA_BLOCK_SIZE_DEFAULT :: 65536

/*
Default out-band size of the dynamic arena.
*/
DYNAMIC_ARENA_OUT_OF_BAND_SIZE_DEFAULT :: 6554

/*
Dynamic arena allocator data.
*/
Dynamic_Arena :: struct {
	block_size:           int,
	out_band_size:        int,
	alignment:            int,
	unused_blocks:        [dynamic]rawptr,
	used_blocks:          [dynamic]rawptr,
	out_band_allocations: [dynamic]rawptr,
	current_block:        rawptr,
	current_pos:          rawptr,
	bytes_left:           int,
	block_allocator:      Allocator,
}

/*
Initialize a dynamic arena.

This procedure initializes a dynamic arena. The specified `block_allocator`
will be used to allocate arena blocks, and `array_allocator` to allocate
arrays of blocks and out-band blocks. The blocks have the default size of
`block_size` and out-band threshold will be `out_band_size`. All allocations
will be aligned to a boundary specified by `alignment`.
*/
dynamic_arena_init :: proc(
	pool: ^Dynamic_Arena,
	block_allocator := context.allocator,
	array_allocator := context.allocator,
	block_size      := DYNAMIC_ARENA_BLOCK_SIZE_DEFAULT,
	out_band_size   := DYNAMIC_ARENA_OUT_OF_BAND_SIZE_DEFAULT,
	alignment       := DEFAULT_ALIGNMENT,
) {
	pool.block_size                     = block_size
	pool.out_band_size                  = out_band_size
	pool.alignment                      = alignment
	pool.block_allocator                = block_allocator
	pool.out_band_allocations.allocator = array_allocator
	pool.unused_blocks.allocator        = array_allocator
	pool.used_blocks.allocator          = array_allocator
}

/*
Dynamic arena allocator.

The dynamic arena allocator uses blocks of a specific size, allocated on-demand
using the block allocator. This allocator acts similarly to `Arena`. All
allocations in a block happen contiguously, from start to end. If an allocation
does not fit into the remaining space of the block and its size is smaller
than the specified out-band size, a new block is allocated using the
`block_allocator` and the allocation is performed from a newly-allocated block.

If an allocation is larger than the specified out-band size, a new block
is allocated such that the allocation fits into this new block. This is referred
to as an *out-band allocation*. The out-band blocks are kept separately from
normal blocks.

Just like `Arena`, the dynamic arena does not support freeing of individual
objects.
*/
@(require_results)
dynamic_arena_allocator :: proc(a: ^Dynamic_Arena) -> Allocator {
	return Allocator{
		procedure = dynamic_arena_allocator_proc,
		data = a,
	}
}

/*
Destroy a dynamic arena.

This procedure frees all allocations made on a dynamic arena, including the
unused blocks, as well as the arrays for storing blocks.
*/
dynamic_arena_destroy :: proc(a: ^Dynamic_Arena) {
	dynamic_arena_free_all(a)
	delete(a.unused_blocks)
	delete(a.used_blocks)
	delete(a.out_band_allocations)
	zero(a, size_of(a^))
}

@(private="file")
_dynamic_arena_cycle_new_block :: proc(a: ^Dynamic_Arena, loc := #caller_location) -> (err: Allocator_Error) {
	if a.block_allocator.procedure == nil {
		panic("You must call `dynamic_arena_init` on a Dynamic Arena before using it.", loc)
	}
	if a.current_block != nil {
		append(&a.used_blocks, a.current_block, loc=loc)
	}
	new_block: rawptr
	if len(a.unused_blocks) > 0 {
		new_block = pop(&a.unused_blocks)
	} else {
		data: []byte
		data, err = a.block_allocator.procedure(
			a.block_allocator.data,
			Allocator_Mode.Alloc,
			a.block_size,
			a.alignment,
			nil,
			0,
		)
		// sanitizer.address_poison(data)
		new_block = raw_data(data)
	}
	a.bytes_left    = a.block_size
	a.current_pos   = new_block
	a.current_block = new_block
	return
}

/*
Allocate memory from a dynamic arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from a dynamic arena `a`. The allocated memory is
zero-initialized. This procedure returns a pointer to the newly allocated memory
region.
*/
@(require_results)
dynamic_arena_alloc :: proc(a: ^Dynamic_Arena, size: int, loc := #caller_location) -> (rawptr, Allocator_Error) {
	data, err := dynamic_arena_alloc_bytes(a, size, loc)
	return raw_data(data), err
}

/*
Allocate memory from a dynamic arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from a dynamic arena `a`. The allocated memory is
zero-initialized. This procedure returns a slice of the newly allocated memory
region.
*/
@(require_results)
dynamic_arena_alloc_bytes :: proc(a: ^Dynamic_Arena, size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	bytes, err := dynamic_arena_alloc_bytes_non_zeroed(a, size, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate non-initialized memory from a dynamic arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from a dynamic arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a pointer to the newly allocated
memory region.
*/
@(require_results)
dynamic_arena_alloc_non_zeroed :: proc(a: ^Dynamic_Arena, size: int, loc := #caller_location) -> (rawptr, Allocator_Error) {
	data, err := dynamic_arena_alloc_bytes_non_zeroed(a, size, loc)
	return raw_data(data), err
}

/*
Allocate non-initialized memory from a dynamic arena.

This procedure allocates `size` bytes of memory aligned on a boundary specified
by `alignment` from a dynamic arena `a`. The allocated memory is not explicitly
zero-initialized. This procedure returns a slice of the newly allocated
memory region.
*/
@(require_results)
dynamic_arena_alloc_bytes_non_zeroed :: proc(a: ^Dynamic_Arena, size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	if size >= a.out_band_size {
		assert(a.out_band_allocations.allocator.procedure != nil, "Backing array allocator must be initialized", loc=loc)
		memory, err := alloc_bytes_non_zeroed(size, a.alignment, a.out_band_allocations.allocator, loc)
		if memory != nil {
			append(&a.out_band_allocations, raw_data(memory), loc = loc)
		}
		return memory, err
	}
	n := align_formula(size, a.alignment)
	if n > a.block_size {
		return nil, .Invalid_Argument
	}
	if a.bytes_left < n {
		err := _dynamic_arena_cycle_new_block(a, loc)
		if err != nil {
			return nil, err
		}
		if a.current_block == nil {
			return nil, .Out_Of_Memory
		}
	}
	memory := a.current_pos
	a.current_pos = ([^]byte)(a.current_pos)[n:]
	a.bytes_left -= n
	result := ([^]byte)(memory)[:size]
	// ensure_poisoned(result)
	// sanitizer.address_unpoison(result)
	return result, nil
}

/*
Reset a dynamic arena allocator.

This procedure frees all the allocations owned by the dynamic arena, excluding
the unused blocks.
*/
dynamic_arena_reset :: proc(a: ^Dynamic_Arena, loc := #caller_location) {
	if a.current_block != nil {
		// sanitizer.address_poison(a.current_block, a.block_size)
		append(&a.unused_blocks, a.current_block, loc=loc)
		a.current_block = nil
	}
	for block in a.used_blocks {
		// sanitizer.address_poison(block, a.block_size)
		append(&a.unused_blocks, block, loc=loc)
	}
	clear(&a.used_blocks)
	for allocation in a.out_band_allocations {
		free(allocation, a.out_band_allocations.allocator, loc=loc)
	}
	clear(&a.out_band_allocations)
	a.bytes_left = 0 // Make new allocations call `_dynamic_arena_cycle_new_block` again.
}

/*
Free all memory back to the dynamic arena allocator.

This procedure frees all the allocations owned by the dynamic arena, including
the unused blocks.
*/
dynamic_arena_free_all :: proc(a: ^Dynamic_Arena, loc := #caller_location) {
	dynamic_arena_reset(a)
	for block in a.unused_blocks {
		// sanitizer.address_unpoison(block, a.block_size)
		free(block, a.block_allocator, loc)
	}
	clear(&a.unused_blocks)
}

/*
Resize an allocation owned by a dynamic arena allocator.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `dynamic_arena_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
dynamic_arena_resize :: proc(
	a:          ^Dynamic_Arena,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := dynamic_arena_resize_bytes(a, byte_slice(old_memory, old_size), size, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a dynamic arena allocator.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is
zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `dynamic_arena_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
dynamic_arena_resize_bytes :: proc(
	a:        ^Dynamic_Arena,
	old_data: []byte,
	size:     int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if size == 0 {
		// NOTE: This allocator has no Free mode.
		return nil, nil
	}
	bytes, err := dynamic_arena_resize_bytes_non_zeroed(a, old_data, size, loc)
	if bytes != nil {
		if old_data == nil {
			zero_slice(bytes)
		} else if size > len(old_data) {
			zero_slice(bytes[len(old_data):])
		}
	}
	return bytes, err
}

/*
Resize an allocation owned by a dynamic arena allocator, without zero-initialization.

This procedure resizes a memory region defined by its location `old_memory`
and its size `old_size` to have a size `size` and alignment `alignment`. The
newly allocated memory, if any, is not explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `dynamic_arena_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

This procedure returns the pointer to the resized memory region.
*/
@(require_results)
dynamic_arena_resize_non_zeroed :: proc(
	a:          ^Dynamic_Arena,
	old_memory: rawptr,
	old_size:   int,
	size:       int,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := dynamic_arena_resize_bytes_non_zeroed(a, byte_slice(old_memory, old_size), size, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by a dynamic arena allocator, without zero-initialization.

This procedure resizes a memory region specified by `old_data` to have a size
`size` and alignment `alignment`. The newly allocated memory, if any, is not
explicitly zero-initialized.

If `old_memory` is `nil`, this procedure acts just like `dynamic_arena_alloc()`,
allocating a memory region `size` bytes in size, aligned on a boundary specified
by `alignment`.

This procedure returns the slice of the resized memory region.
*/
@(require_results)
dynamic_arena_resize_bytes_non_zeroed :: proc(
	a:        ^Dynamic_Arena,
	old_data: []byte,
	size:     int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	if size == 0 {
		// NOTE: This allocator has no Free mode.
		return nil, nil
	}
	old_memory := raw_data(old_data)
	old_size := len(old_data)
	if old_size >= size {
		// sanitizer.address_poison(old_data[size:])
		return byte_slice(old_memory, size), nil
	}
	// No information is kept about allocations in this allocator, thus we
	// cannot truly resize anything and must reallocate.
	data, err := dynamic_arena_alloc_bytes_non_zeroed(a, size, loc)
	if err == nil {
		runtime.copy(data, byte_slice(old_memory, old_size))
	}
	return data, err
}

dynamic_arena_allocator_proc :: proc(
	allocator_data: rawptr,
	mode:           Allocator_Mode,
	size:           int,
	alignment:      int,
	old_memory:     rawptr,
	old_size:       int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	arena := (^Dynamic_Arena)(allocator_data)
	switch mode {
	case .Alloc:
		return dynamic_arena_alloc_bytes(arena, size, loc)
	case .Alloc_Non_Zeroed:
		return dynamic_arena_alloc_bytes_non_zeroed(arena, size, loc)
	case .Free:
		return nil, .Mode_Not_Implemented
	case .Free_All:
		dynamic_arena_free_all(arena, loc)
	case .Resize:
		return dynamic_arena_resize_bytes(arena, byte_slice(old_memory, old_size), size, loc)
	case .Resize_Non_Zeroed:
		return dynamic_arena_resize_bytes_non_zeroed(arena, byte_slice(old_memory, old_size), size, loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features, .Query_Info}
		}
		return nil, nil
	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			info.size = arena.block_size
			info.alignment = arena.alignment
			return byte_slice(info, size_of(info^)), nil
		}
		return nil, nil
	}
	return nil, nil
}


/*
Header of the buddy block.
*/
Buddy_Block :: struct #align(align_of(uint)) {
	size:    uint,
	is_free: bool,
}

/*
Obtain the next buddy block.
*/
@(require_results, no_sanitize_address)
buddy_block_next :: proc(block: ^Buddy_Block) -> ^Buddy_Block {
	return (^Buddy_Block)(([^]byte)(block)[block.size:])
}

/*
Split the block into two, by truncating the given block to a given size.
*/
@(require_results, no_sanitize_address)
buddy_block_split :: proc(block: ^Buddy_Block, size: uint) -> ^Buddy_Block {
	block := block
	if block != nil && size != 0 {
		// Recursive Split
		for size < block.size {
			sz := block.size >> 1
			block.size = sz
			block = buddy_block_next(block)
			block.size = sz
			block.is_free = true
		}
		if size <= block.size {
			return block
		}
	}
	// Block cannot fit the requested allocation size
	return nil
}

/*
Coalesce contiguous blocks in a range of blocks into one.
*/
@(no_sanitize_address)
buddy_block_coalescence :: proc(head, tail: ^Buddy_Block) {
	for {
		// Keep looping until there are no more buddies to coalesce
		block := head
		buddy := buddy_block_next(block)
		no_coalescence := true
		for block < tail && buddy < tail { // make sure the buddies are within the range
			if block.is_free && buddy.is_free && block.size == buddy.size {
				// Coalesce buddies into one
				block.size <<= 1
				block = buddy_block_next(block)
				if block < tail {
					buddy = buddy_block_next(block)
					no_coalescence = false
				}
			} else if block.size < buddy.size {
				// The buddy block is split into smaller blocks
				block = buddy
				buddy = buddy_block_next(buddy)
			} else {
				block = buddy_block_next(buddy)
				if block < tail {
					// Leave the buddy block for the next iteration
					buddy = buddy_block_next(block)
				}
			}
		}
		if no_coalescence {
			return
		}
	}
}

/*
Find the best block for storing a given size in a range of blocks.
*/
@(require_results, no_sanitize_address)
buddy_block_find_best :: proc(head, tail: ^Buddy_Block, size: uint) -> ^Buddy_Block {
	assert(size != 0)
	best_block: ^Buddy_Block
	block := head                    // left
	buddy := buddy_block_next(block) // right
	// The entire memory section between head and tail is free,
	// just call 'buddy_block_split' to get the allocation
	if buddy == tail && block.is_free {
		return buddy_block_split(block, size)
	}
	// Find the block which is the 'best_block' to requested allocation sized
	for block < tail && buddy < tail { // make sure the buddies are within the range
		// If both buddies are free, coalesce them together
		// NOTE: this is an optimization to reduce fragmentation
		//       this could be completely ignored
		if block.is_free && buddy.is_free && block.size == buddy.size {
			block.size <<= 1
			if size <= block.size && (best_block == nil || block.size <= best_block.size) {
				best_block = block
			}
			block = buddy_block_next(buddy)
			if block < tail {
				// Delay the buddy block for the next iteration
				buddy = buddy_block_next(block)
			}
			continue
		}
		if block.is_free && size <= block.size &&
		   (best_block == nil || block.size <= best_block.size) {
			best_block = block
		}
		if buddy.is_free && size <= buddy.size &&
		   (best_block == nil || buddy.size < best_block.size) {
			// If each buddy are the same size, then it makes more sense
			// to pick the buddy as it "bounces around" less
			best_block = buddy
		}
		if block.size <= buddy.size {
			block = buddy_block_next(buddy)
			if (block < tail) {
				// Delay the buddy block for the next iteration
				buddy = buddy_block_next(block)
			}
		} else {
			// Buddy was split into smaller blocks
			block = buddy
			buddy = buddy_block_next(buddy)
		}
	}
	if best_block != nil {
		// This will handle the case if the 'best_block' is also the perfect fit
		return buddy_block_split(best_block, size)
	}
	// Maybe out of memory
	return nil
}

/*
The buddy allocator data.
*/
Buddy_Allocator :: struct {
	head:      ^Buddy_Block,
	tail:      ^Buddy_Block `fmt:"-"`,
	alignment: uint,
}

/*
Buddy allocator.

The buddy allocator is a type of allocator that splits the backing buffer into
multiple regions called buddy blocks. Initially, the allocator only has one
block with the size of the backing buffer. Upon each allocation, the allocator
finds the smallest block that can fit the size of requested memory region, and
splits the block according to the allocation size. If no block can be found,
the contiguous free blocks are coalesced and the search is performed again.
*/
@(require_results)
buddy_allocator :: proc(b: ^Buddy_Allocator) -> Allocator {
	return Allocator{
		procedure = buddy_allocator_proc,
		data      = b,
	}
}

/*
Initialize a buddy allocator.

This procedure initializes the buddy allocator `b` with a backing buffer `data`
and block alignment specified by `alignment`.

`alignment` may be any power of two, but the backing buffer must be aligned to
at least `size_of(Buddy_Block)`.
*/
buddy_allocator_init :: proc(b: ^Buddy_Allocator, data: []byte, alignment: uint, loc := #caller_location) {
	assert(data != nil)
	assert(is_power_of_two(uintptr(len(data))), "Size of the backing buffer must be power of two", loc)
	assert(is_power_of_two(uintptr(alignment)), "Alignment must be a power of two", loc)
	alignment := alignment
	if alignment < size_of(Buddy_Block) {
		alignment = size_of(Buddy_Block)
	}
	ptr := raw_data(data)
	assert(uintptr(ptr) % uintptr(alignment) == 0, "The data is not aligned to the minimum alignment, which must be at least `size_of(Buddy_Block)`.", loc)
	b.head = (^Buddy_Block)(ptr)
	b.head.size = len(data)
	b.head.is_free = true
	b.tail = buddy_block_next(b.head)
	b.alignment = alignment
	assert(uint(len(data)) >= 2 * buddy_block_size_required(b, 1), "The size of the backing buffer must be large enough to hold at least two 1-byte allocations given the alignment requirements, otherwise it cannot split.", loc)
	// sanitizer.address_poison(data)
}

/*
Get required block size to fit in the allocation as well as the alignment padding.
*/
@(require_results)
buddy_block_size_required :: proc(b: ^Buddy_Allocator, size: uint) -> uint {
	assert(size > 0)
	// NOTE: `size_of(Buddy_Block)` will be accounted for in `b.alignment`.
	// This calculation is also previously guarded against being given a `size`
	// 0 by `buddy_allocator_alloc_bytes_non_zeroed` checking for that.
	actual_size := b.alignment + size
	if intrinsics.count_ones(actual_size) != 1 {
		// We're not a power of two. Let's fix that.
		actual_size = 1 << (size_of(uint) * 8 - intrinsics.count_leading_zeros(actual_size))
	}
	return actual_size
}

/*
Allocate memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is zero-initialized. This procedure returns a pointer to the allocated
memory region.
*/
@(require_results, no_sanitize_address)
buddy_allocator_alloc :: proc(b: ^Buddy_Allocator, size: uint) -> (rawptr, Allocator_Error) {
	bytes, err := buddy_allocator_alloc_bytes(b, size)
	return raw_data(bytes), err
}

/*
Allocate memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is zero-initialized. This procedure returns a slice of the allocated
memory region.
*/
@(require_results, no_sanitize_address)
buddy_allocator_alloc_bytes :: proc(b: ^Buddy_Allocator, size: uint) -> ([]byte, Allocator_Error) {
	bytes, err := buddy_allocator_alloc_bytes_non_zeroed(b, size)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate non-initialized memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is not explicitly zero-initialized. This procedure returns a pointer to
the allocated memory region.
*/
@(require_results, no_sanitize_address)
buddy_allocator_alloc_non_zeroed :: proc(b: ^Buddy_Allocator, size: uint) -> (rawptr, Allocator_Error) {
	bytes, err := buddy_allocator_alloc_bytes_non_zeroed(b, size)
	return raw_data(bytes), err
}

/*
Allocate non-initialized memory from a buddy allocator.

This procedure allocates `size` bytes of memory. The allocation's alignment is
fixed to the `alignment` specified at initialization. The allocated memory
region is not explicitly zero-initialized. This procedure returns a slice of
the allocated memory region.
*/
@(require_results, no_sanitize_address)
buddy_allocator_alloc_bytes_non_zeroed :: proc(b: ^Buddy_Allocator, size: uint) -> ([]byte, Allocator_Error) {
	if size != 0 {
		actual_size := buddy_block_size_required(b, size)
		found := buddy_block_find_best(b.head, b.tail, actual_size)
		if found == nil {
			// Try to coalesce all the free buddy blocks and then search again
			buddy_block_coalescence(b.head, b.tail)
			found = buddy_block_find_best(b.head, b.tail, actual_size)
		}
		if found == nil {
			return nil, .Out_Of_Memory
		}
		found.is_free = false
		data := ([^]byte)(found)[b.alignment:][:size]
		assert(cast(uintptr)raw_data(data)+cast(uintptr)(size-1) < cast(uintptr)buddy_block_next(found), "Buddy_Allocator has made an allocation which overlaps a block header.")
		// ensure_poisoned(data)
		// sanitizer.address_unpoison(data)
		return data, nil
	}
	return nil, nil
}

/*
Free memory back to the buddy allocator.

This procedure frees the memory region allocated at pointer `ptr`.

If `ptr` is not the latest allocation and is not a leaked allocation, this
operation is a no-op.
*/
@(no_sanitize_address)
buddy_allocator_free :: proc(b: ^Buddy_Allocator, ptr: rawptr) -> Allocator_Error {
	if ptr != nil {
		if !(b.head <= ptr && ptr <= b.tail) {
			return .Invalid_Pointer
		}
		block := (^Buddy_Block)(([^]byte)(ptr)[-b.alignment:])
		// sanitizer.address_poison(ptr, block.size)
		block.is_free = true
		buddy_block_coalescence(b.head, b.tail)
	}
	return nil
}

/*
Free all memory back to the buddy allocator.
*/
@(no_sanitize_address)
buddy_allocator_free_all :: proc(b: ^Buddy_Allocator) {
	alignment := b.alignment
	head := ([^]byte)(b.head)
	tail := ([^]byte)(b.tail)
	data := head[:ptr_sub(tail, head)]
	buddy_allocator_init(b, data, alignment)
}

@(no_sanitize_address)
buddy_allocator_proc :: proc(
	allocator_data:  rawptr,
	mode:            Allocator_Mode,
	size, alignment: int,
	old_memory:      rawptr,
	old_size:        int,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	b := (^Buddy_Allocator)(allocator_data)
	switch mode {
	case .Alloc:
		return buddy_allocator_alloc_bytes(b, uint(size))
	case .Alloc_Non_Zeroed:
		return buddy_allocator_alloc_bytes_non_zeroed(b, uint(size))
	case .Resize:
		return default_resize_bytes_align(byte_slice(old_memory, old_size), size, alignment, buddy_allocator(b), loc)
	case .Resize_Non_Zeroed:
		return default_resize_bytes_align_non_zeroed(byte_slice(old_memory, old_size), size, alignment, buddy_allocator(b), loc)
	case .Free:
		return nil, buddy_allocator_free(b, old_memory)
	case .Free_All:
		buddy_allocator_free_all(b)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features, .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed, .Free, .Free_All, .Query_Info}
		}
		return nil, nil
	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			ptr := info.pointer
			if !(b.head <= ptr && ptr <= b.tail) {
				return nil, .Invalid_Pointer
			}
			block := (^Buddy_Block)(([^]byte)(ptr)[-b.alignment:])
			info.size = int(block.size)
			info.alignment = int(b.alignment)
			return byte_slice(info, size_of(info^)), nil
		}
		return nil, nil
	}
	return nil, nil
}

// An allocator that keeps track of allocation sizes and passes it along to resizes.
// This is useful if you are using a library that needs an equivalent of `realloc` but want to use
// the Odin allocator interface.
//
// You want to wrap your allocator into this one if you are trying to use any allocator that relies
// on the old size to work.
//
// The overhead of this allocator is an extra max(alignment, size_of(Header)) bytes allocated for each allocation, these bytes are
// used to store the size and alignment.
Compat_Allocator :: struct {
	parent: Allocator,
}

compat_allocator_init :: proc(rra: ^Compat_Allocator, allocator := context.allocator) {
	rra.parent = allocator
}

@(require_results)
compat_allocator :: proc(rra: ^Compat_Allocator) -> Allocator {
	return Allocator{
		data      = rra,
		procedure = compat_allocator_proc,
	}
}

compat_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int,
                             location := #caller_location) -> (data: []byte, err: Allocator_Error) {
	Header :: struct {
		size:      int,
		alignment: int,
	}

	@(no_sanitize_address)
	get_unpoisoned_header :: #force_inline proc(ptr: rawptr) -> Header {
		header := ([^]Header)(ptr)[-1]
		// a      := max(header.alignment, size_of(Header))
		// sanitizer.address_unpoison(rawptr(uintptr(ptr)-uintptr(a)), a)
		return header
	}

	rra := (^Compat_Allocator)(allocator_data)
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		a        := max(alignment, size_of(Header))
		req_size := size + a
		assert(req_size >= 0, "overflow")

		allocation := rra.parent.procedure(rra.parent.data, mode, req_size, alignment, old_memory, old_size, location) or_return
		#no_bounds_check data = allocation[a:]

		([^]Header)(raw_data(data))[-1] = {
			size      = size,
			alignment = alignment,
		}

		// sanitizer.address_poison(raw_data(allocation), a)
		return

	case .Free:
		header    := get_unpoisoned_header(old_memory)
		a         := max(header.alignment, size_of(Header))
		orig_ptr  := rawptr(uintptr(old_memory)-uintptr(a))
		orig_size := header.size + a

		return rra.parent.procedure(rra.parent.data, mode, orig_size, header.alignment, orig_ptr, orig_size, location)

	case .Resize, .Resize_Non_Zeroed:
		header    := get_unpoisoned_header(old_memory)
		orig_a    := max(header.alignment, size_of(Header))
		orig_ptr  := rawptr(uintptr(old_memory)-uintptr(orig_a))
		orig_size := header.size + orig_a

		new_alignment := max(header.alignment, alignment)

		a        := max(new_alignment, size_of(header))
		req_size := size + a
		assert(size >= 0, "overflow")

		allocation := rra.parent.procedure(rra.parent.data, mode, req_size, new_alignment, orig_ptr, orig_size, location) or_return
		#no_bounds_check data = allocation[a:]

		([^]Header)(raw_data(data))[-1] = {
			size      = size,
			alignment = new_alignment,
		}

		// sanitizer.address_poison(raw_data(allocation), a)
		return

	case .Free_All:
		return rra.parent.procedure(rra.parent.data, mode, size, alignment, old_memory, old_size, location)

	case .Query_Info:
		info := (^Allocator_Query_Info)(old_memory)
		if info != nil && info.pointer != nil {
			header := get_unpoisoned_header(info.pointer)
			info.size      = header.size
			info.alignment = header.alignment
		}
		return

	case .Query_Features:
		data, err = rra.parent.procedure(rra.parent.data, mode, size, alignment, old_memory, old_size, location)
		if err != nil {
			set := (^Allocator_Mode_Set)(old_memory)
			set^ += {.Query_Info}
		}
		return

	case: unreachable()
	}
}
