package mem

import "base:runtime"
// import "base:sanitizer"

/*
Rollback stack default block size.
*/
ROLLBACK_STACK_DEFAULT_BLOCK_SIZE :: 4 * Megabyte

/*
Rollback stack max head block size.

This limitation is due to the size of `prev_ptr`, but it is only for the
head block; any allocation in excess of the allocator's `block_size` is
valid, so long as the block allocator can handle it.

This is because allocations over the block size are not split up if the item
within is freed; they are immediately returned to the block allocator.
*/
ROLLBACK_STACK_MAX_HEAD_BLOCK_SIZE :: 2 * Gigabyte

/*
Allocation header of the rollback stack allocator.
*/
Rollback_Stack_Header :: bit_field u64 {
	prev_offset:  uintptr | 32,
	is_free:         bool |  1,
	prev_ptr:     uintptr | 31,
}

/*
Block header of the rollback stack allocator.
*/
Rollback_Stack_Block :: struct {
	next_block: ^Rollback_Stack_Block,
	last_alloc: rawptr,
	offset: uintptr,
	buffer: []byte,
}

/*
Rollback stack allocator data.
*/
Rollback_Stack :: struct {
	head: ^Rollback_Stack_Block,
	block_size: int,
	block_allocator: Allocator,
}

@(private="file", require_results, no_sanitize_address)
rb_ptr_in_bounds :: proc(block: ^Rollback_Stack_Block, ptr: rawptr) -> bool {
	start := raw_data(block.buffer)
	end   := start[block.offset:]
	return start < ptr && ptr <= end
}

@(private="file", require_results, no_sanitize_address)
rb_find_ptr :: proc(stack: ^Rollback_Stack, ptr: rawptr) -> (
	parent: ^Rollback_Stack_Block,
	block:  ^Rollback_Stack_Block,
	header: ^Rollback_Stack_Header,
	err: Allocator_Error,
) {
	for block = stack.head; block != nil; block = block.next_block {
		if rb_ptr_in_bounds(block, ptr) {
			header = cast(^Rollback_Stack_Header)(cast(uintptr)ptr - size_of(Rollback_Stack_Header))
			return
		}
		parent = block
	}
	return nil, nil, nil, .Invalid_Pointer
}

@(private="file", require_results, no_sanitize_address)
rb_find_last_alloc :: proc(stack: ^Rollback_Stack, ptr: rawptr) -> (
	block: ^Rollback_Stack_Block,
	header: ^Rollback_Stack_Header,
	ok: bool,
) {
	for block = stack.head; block != nil; block = block.next_block {
		if block.last_alloc == ptr {
			header = cast(^Rollback_Stack_Header)(cast(uintptr)ptr - size_of(Rollback_Stack_Header))
			return block, header, true
		}
	}
	return nil, nil, false
}

@(private="file", no_sanitize_address)
rb_rollback_block :: proc(block: ^Rollback_Stack_Block, header: ^Rollback_Stack_Header) {
	header := header

	for block.offset > 0 && header.is_free {
		block.offset = header.prev_offset
		block.last_alloc = raw_data(block.buffer)[header.prev_ptr:]
		header = cast(^Rollback_Stack_Header)(raw_data(block.buffer)[header.prev_ptr - size_of(Rollback_Stack_Header):])
	}
}

/*
Free memory to a rollback stack allocator.
*/
@(private="file", require_results, no_sanitize_address)
rb_free :: proc(stack: ^Rollback_Stack, ptr: rawptr) -> Allocator_Error {
	parent, block, header := rb_find_ptr(stack, ptr) or_return

	if header.is_free {
		return .Invalid_Pointer
	}
	header.is_free = true
	if block.last_alloc == ptr {
		block.offset = header.prev_offset
		rb_rollback_block(block, header)
	}
	if parent != nil && block.offset == 0 {
		parent.next_block = block.next_block
		runtime.mem_free_with_size(block, size_of(Rollback_Stack_Block) + len(block.buffer), stack.block_allocator)
	}
	return nil
}

/*
Free all memory owned by the rollback stack allocator.
*/
@(private="file", no_sanitize_address)
rb_free_all :: proc(stack: ^Rollback_Stack) {
	for block := stack.head.next_block; block != nil; /**/ {
		next_block := block.next_block
		runtime.mem_free_with_size(block, size_of(Rollback_Stack_Block) + len(block.buffer), stack.block_allocator)
		block = next_block
	}

	stack.head.next_block = nil
	stack.head.last_alloc = nil
	stack.head.offset = 0
	// sanitizer.address_poison(stack.head.buffer)
}

/*
Allocate memory using the rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_alloc :: proc(
	stack: ^Rollback_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := rb_alloc_bytes_non_zeroed(stack, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return raw_data(bytes), err
}

/*
Allocate memory using the rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_alloc_bytes :: proc(
	stack: ^Rollback_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]byte, Allocator_Error) {
	bytes, err := rb_alloc_bytes_non_zeroed(stack, size, alignment, loc)
	if bytes != nil {
		zero_slice(bytes)
	}
	return bytes, err
}

/*
Allocate non-initialized memory using the rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_alloc_non_zeroed :: proc(
	stack: ^Rollback_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := rb_alloc_bytes_non_zeroed(stack, size, alignment, loc)
	return raw_data(bytes), err
}

/*
Allocate non-initialized memory using the rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_alloc_bytes_non_zeroed :: proc(
	stack: ^Rollback_Stack,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (result: []byte, err: Allocator_Error) {
	assert(size >= 0, "Size must be positive or zero.", loc)
	assert(is_power_of_two(cast(uintptr)alignment), "Alignment must be a power of two.", loc)
	parent: ^Rollback_Stack_Block

	for block := stack.head; /**/; block = block.next_block {
		when !ODIN_DISABLE_ASSERT {
			allocated_new_block: bool
		}
		if block == nil {
			if stack.block_allocator.procedure == nil {
				return nil, .Out_Of_Memory
			}
			minimum_size_required := size_of(Rollback_Stack_Header) + size + alignment - 1
			new_block_size := max(minimum_size_required, stack.block_size)
			block = rb_make_block(new_block_size, stack.block_allocator) or_return
			parent.next_block = block
			when !ODIN_DISABLE_ASSERT {
				allocated_new_block = true
			}
		}
		start := raw_data(block.buffer)[block.offset:]
		padding := cast(uintptr)calc_padding_with_header(cast(uintptr)start, cast(uintptr)alignment, size_of(Rollback_Stack_Header))
		if block.offset + padding + cast(uintptr)size > cast(uintptr)len(block.buffer) {
			when !ODIN_DISABLE_ASSERT {
				if allocated_new_block {
					panic("Rollback Stack Allocator allocated a new block but did not use it.")
				}
			}
			parent = block
			continue
		}
		header := cast(^Rollback_Stack_Header)(start[padding - size_of(Rollback_Stack_Header):])
		ptr := start[padding:]
		header^ = {
			prev_offset = block.offset,
			prev_ptr = uintptr(0) if block.last_alloc == nil else cast(uintptr)block.last_alloc - cast(uintptr)raw_data(block.buffer),
			is_free = false,
		}
		block.last_alloc = ptr
		block.offset += padding + cast(uintptr)size
		if len(block.buffer) > stack.block_size {
			// This block exceeds the allocator's standard block size and is considered a singleton.
			// Prevent any further allocations on it.
			block.offset = cast(uintptr)len(block.buffer)
		}
		res := ptr[:size]
		// sanitizer.address_unpoison(res)
		return res, nil
	}
	return nil, .Out_Of_Memory
}

/*
Resize an allocation owned by rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_resize :: proc(
	stack: ^Rollback_Stack,
	old_ptr: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := rb_resize_bytes_non_zeroed(stack, byte_slice(old_ptr, old_size), size, alignment, loc)
	if bytes != nil {
		if old_ptr == nil {
			zero_slice(bytes)
		} else if size > old_size {
			zero_slice(bytes[old_size:])
		}
	}
	return raw_data(bytes), err
}

/*
Resize an allocation owned by rollback stack allocator.
*/
@(require_results, no_sanitize_address)
rb_resize_bytes :: proc(
	stack: ^Rollback_Stack,
	old_memory: []byte,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> ([]u8, Allocator_Error) {
	bytes, err := rb_resize_bytes_non_zeroed(stack, old_memory, size, alignment, loc)
	if bytes != nil {
		if old_memory == nil {
			zero_slice(bytes)
		} else if size > len(old_memory) {
			zero_slice(bytes[len(old_memory):])
		}
	}
	return bytes, err
}

/*
Resize an allocation owned by rollback stack allocator without explicit
zero-initialization.
*/
@(require_results, no_sanitize_address)
rb_resize_non_zeroed :: proc(
	stack: ^Rollback_Stack,
	old_ptr: rawptr,
	old_size: int,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (rawptr, Allocator_Error) {
	bytes, err := rb_resize_bytes_non_zeroed(stack, byte_slice(old_ptr, old_size), size, alignment, loc)
	return raw_data(bytes), err
}

/*
Resize an allocation owned by rollback stack allocator without explicit
zero-initialization.
*/
@(require_results, no_sanitize_address)
rb_resize_bytes_non_zeroed :: proc(
	stack: ^Rollback_Stack,
	old_memory: []byte,
	size: int,
	alignment := DEFAULT_ALIGNMENT,
	loc := #caller_location,
) -> (result: []byte, err: Allocator_Error) {
	old_size := len(old_memory)
	ptr := raw_data(old_memory)
	assert(size >= 0, "Size must be positive or zero.", loc)
	assert(old_size >= 0, "Old size must be positive or zero.", loc)
	assert(is_power_of_two(cast(uintptr)alignment), "Alignment must be a power of two.", loc)
	if ptr != nil {
		if block, _, ok := rb_find_last_alloc(stack, ptr); ok {
			// `block.offset` should never underflow because it is contingent
			// on `old_size` in the first place, assuming sane arguments.
			assert(block.offset >= cast(uintptr)old_size, "Rollback Stack Allocator received invalid `old_size`.")
			if block.offset + cast(uintptr)size - cast(uintptr)old_size < cast(uintptr)len(block.buffer) {
				// Prevent singleton allocations from fragmenting by forbidding
				// them to shrink, removing the possibility of overflow bugs.
				if len(block.buffer) <= stack.block_size {
					block.offset += cast(uintptr)size - cast(uintptr)old_size
				}
				res := (ptr)[:size]
				// sanitizer.address_unpoison(res)
				#no_bounds_check return res, nil
			}
		}
	}
	result = rb_alloc_bytes_non_zeroed(stack, size, alignment) or_return
	runtime.mem_copy_non_overlapping(raw_data(result), ptr, old_size)
	err = rb_free(stack, ptr)
	return
}

@(private="file", require_results, no_sanitize_address)
rb_make_block :: proc(size: int, allocator: Allocator) -> (block: ^Rollback_Stack_Block, err: Allocator_Error) {
	buffer := runtime.mem_alloc(size_of(Rollback_Stack_Block) + size, align_of(Rollback_Stack_Block), allocator) or_return
	block = cast(^Rollback_Stack_Block)raw_data(buffer)
	#no_bounds_check block.buffer = buffer[size_of(Rollback_Stack_Block):]
	return
}

/*
Initialize the rollback stack allocator using a fixed backing buffer.
*/
@(no_sanitize_address)
rollback_stack_init_buffered :: proc(stack: ^Rollback_Stack, buffer: []byte, location := #caller_location) {
	MIN_SIZE :: size_of(Rollback_Stack_Block) + size_of(Rollback_Stack_Header) + size_of(rawptr)
	assert(len(buffer) >= MIN_SIZE, "User-provided buffer to Rollback Stack Allocator is too small.", location)
	block := cast(^Rollback_Stack_Block)raw_data(buffer)
	block^ = {}
	#no_bounds_check block.buffer = buffer[size_of(Rollback_Stack_Block):]
	stack^ = {}
	stack.head = block
	stack.block_size = len(block.buffer)
}

/*
Initialize the rollback stack alocator using a backing block allocator.
*/
@(no_sanitize_address)
rollback_stack_init_dynamic :: proc(
	stack: ^Rollback_Stack,
	block_size : int = ROLLBACK_STACK_DEFAULT_BLOCK_SIZE,
	block_allocator := context.allocator,
	location := #caller_location,
) -> Allocator_Error {
	assert(block_size >= size_of(Rollback_Stack_Header) + size_of(rawptr), "Rollback Stack Allocator block size is too small.", location)
	when size_of(int) > 4 {
		// It's impossible to specify an argument in excess when your integer
		// size is insufficient; check only on platforms with big enough ints.
		assert(block_size <= ROLLBACK_STACK_MAX_HEAD_BLOCK_SIZE, "Rollback Stack Allocators cannot support head blocks larger than 2 gigabytes.", location)
	}
	block := rb_make_block(block_size, block_allocator) or_return
	stack^ = {}
	stack.head = block
	stack.block_size = block_size
	stack.block_allocator = block_allocator
	return nil
}

/*
Initialize the rollback stack.
*/
rollback_stack_init :: proc {
	rollback_stack_init_buffered,
	rollback_stack_init_dynamic,
}

/*
Destroy a rollback stack.
*/
@(no_sanitize_address)
rollback_stack_destroy :: proc(stack: ^Rollback_Stack) {
	if stack.block_allocator.procedure != nil {
		rb_free_all(stack)
		free(stack.head, stack.block_allocator)
	}
	stack^ = {}
}

/*
Rollback stack allocator.

The Rollback Stack Allocator was designed for the test runner to be fast,
able to grow, and respect the Tracking Allocator's requirement for
individual frees. It is not overly concerned with fragmentation, however.

It has support for expansion when configured with a block allocator and
limited support for out-of-order frees.

Allocation has constant-time best and usual case performance.
At worst, it is linear according to the number of memory blocks.

Allocation follows a first-fit strategy when there are multiple memory
blocks.

Freeing has constant-time best and usual case performance.
At worst, it is linear according to the number of memory blocks and number
of freed items preceding the last item in a block.

Resizing has constant-time performance, if it's the last item in a block, or
the new size is smaller. Naturally, this becomes linear-time if there are
multiple blocks to search for the pointer's owning block. Otherwise, the
allocator defaults to a combined alloc & free operation internally.

Out-of-order freeing is accomplished by collapsing a run of freed items
from the last allocation backwards.

Each allocation has an overhead of 8 bytes and any extra bytes to satisfy
the requested alignment.
*/
@(require_results, no_sanitize_address)
rollback_stack_allocator :: proc(stack: ^Rollback_Stack) -> Allocator {
	return Allocator {
		data = stack,
		procedure = rollback_stack_allocator_proc,
	}
}

@(require_results, no_sanitize_address)
rollback_stack_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (result: []byte, err: Allocator_Error) {
	stack := cast(^Rollback_Stack)allocator_data
	switch mode {
	case .Alloc:
		return rb_alloc_bytes(stack, size, alignment, loc)
	case .Alloc_Non_Zeroed:
		return rb_alloc_bytes_non_zeroed(stack, size, alignment, loc)
	case .Free:
		return nil, rb_free(stack, old_memory)
	case .Free_All:
		rb_free_all(stack)
		return nil, nil
	case .Resize:
		return rb_resize_bytes(stack, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Resize_Non_Zeroed:
		return rb_resize_bytes_non_zeroed(stack, byte_slice(old_memory, old_size), size, alignment, loc)
	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed}
		}
		return nil, nil
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return
}
