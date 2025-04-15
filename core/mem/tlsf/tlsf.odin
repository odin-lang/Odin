/*
	Copyright 2024 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Matt Conte:      Original C implementation, see LICENSE file in this package
		Jeroen van Rijn: Source port
*/

// package mem_tlsf implements a Two Level Segregated Fit memory allocator.
package mem_tlsf

import "base:intrinsics"
import "base:runtime"

Error :: enum byte {
	None                      = 0,
	Invalid_Backing_Allocator = 1,
	Invalid_Alignment         = 2,
	Backing_Buffer_Too_Small  = 3,
	Backing_Buffer_Too_Large  = 4,
	Backing_Allocator_Error   = 5,
}

Allocator :: struct {
	// Empty lists point at this block to indicate they are free.
	block_null: Block_Header,

	// Bitmaps for free lists.
	fl_bitmap: u32                  `fmt:"-"`,
	sl_bitmap: [FL_INDEX_COUNT]u32  `fmt:"-"`,

	// Head of free lists.
	blocks: [FL_INDEX_COUNT][SL_INDEX_COUNT]^Block_Header `fmt:"-"`,

	// Keep track of pools so we can deallocate them.
	// If `pool.allocator` is blank, we don't do anything.
	// We also use this linked list of pools to report
	// statistics like how much memory is still available,
	// fragmentation, etc.
	pool: Pool,

	// If we're expected to grow when we run out of memory,
	// how much should we ask the backing allocator for?
	new_pool_size: uint,
}
#assert(size_of(Allocator) % ALIGN_SIZE == 0)

@(require_results)
allocator :: proc(t: ^Allocator) -> runtime.Allocator {
	return runtime.Allocator{
		procedure = allocator_proc,
		data      = t,
	}
}

// Tries to estimate a pool size sufficient for `count` allocations, each of `size` and with `alignment`.
estimate_pool_from_size_alignment :: proc(count: int, size: int, alignment: int) -> (pool_size: int) {
	per_allocation := align_up(uint(size + alignment) + BLOCK_HEADER_OVERHEAD, ALIGN_SIZE)
	return count * int(per_allocation) + int(INITIAL_POOL_OVERHEAD)
}

// Tries to estimate a pool size sufficient for `count` allocations of `type`.
estimate_pool_from_typeid :: proc(count: int, type: typeid) -> (pool_size: int) {
	ti := type_info_of(type)
	return estimate_pool_size(count, ti.size, ti.align)
}

estimate_pool_size :: proc{estimate_pool_from_size_alignment, estimate_pool_from_typeid}


@(require_results)
init_from_buffer :: proc(control: ^Allocator, buf: []byte) -> Error {
	assert(control != nil)
	if uintptr(raw_data(buf)) % ALIGN_SIZE != 0 {
		return .Invalid_Alignment
	}

	pool_bytes := align_down(len(buf) - INITIAL_POOL_OVERHEAD, ALIGN_SIZE)
	if pool_bytes < BLOCK_SIZE_MIN {
		return .Backing_Buffer_Too_Small
	} else if pool_bytes > BLOCK_SIZE_MAX {
		return .Backing_Buffer_Too_Large
	}

	control.pool = Pool{
		data      = buf,
		allocator = {},
	}

	return free_all(control)
}

@(require_results)
init_from_allocator :: proc(control: ^Allocator, backing: runtime.Allocator, initial_pool_size: int, new_pool_size := 0) -> Error {
	assert(control != nil)
	pool_bytes := uint(estimate_pool_size(1, initial_pool_size, ALIGN_SIZE))
	if pool_bytes < BLOCK_SIZE_MIN {
		return .Backing_Buffer_Too_Small
	} else if pool_bytes > BLOCK_SIZE_MAX {
		return .Backing_Buffer_Too_Large
	}

	buf, backing_err := runtime.make_aligned([]byte, pool_bytes, ALIGN_SIZE, backing)
	if backing_err != nil {
		return .Backing_Allocator_Error
	}

	control.pool = Pool{
		data      = buf,
		allocator = backing,
	}

	control.new_pool_size = uint(new_pool_size)

	return free_all(control)
}
init :: proc{init_from_buffer, init_from_allocator}

destroy :: proc(control: ^Allocator) {
	if control == nil { return }

	if control.pool.allocator.procedure != nil {
		runtime.delete(control.pool.data, control.pool.allocator)
	}

	// No need to call `pool_remove` or anything, as they're they're embedded in the backing memory.
	// We do however need to free the `Pool` tracking entities and the backing memory itself.
	for p := control.pool.next; p != nil; {
		next := p.next

		// Free the allocation on the backing allocator
		runtime.delete(p.data, p.allocator)
		free(p, p.allocator)

		p = next
	}
}

allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
                       size, alignment: int,
                       old_memory: rawptr, old_size: int, location := #caller_location) -> ([]byte, runtime.Allocator_Error)  {

	control := (^Allocator)(allocator_data)
	if control == nil {
		return nil, .Invalid_Argument
	}

	switch mode {
	case .Alloc:
		return alloc_bytes(control, uint(size), uint(alignment))
	case .Alloc_Non_Zeroed:
		return alloc_bytes_non_zeroed(control, uint(size), uint(alignment))

	case .Free:
		free_with_size(control, old_memory, uint(old_size))
		return nil, nil

	case .Free_All:
		free_all(control)
		return nil, nil

	case .Resize:
		return resize(control, old_memory, uint(old_size), uint(size), uint(alignment))

	case .Resize_Non_Zeroed:
		return resize_non_zeroed(control, old_memory, uint(old_size), uint(size), uint(alignment))

	case .Query_Features:
		set := (^runtime.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, /* .Free_All, */ .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

// Exported solely to facilitate testing
@(require_results)
ffs :: proc "contextless" (word: u32) -> (bit: i32) {
	return -1 if word == 0 else i32(intrinsics.count_trailing_zeros(word))
}

// Exported solely to facilitate testing
@(require_results)
fls :: proc "contextless" (word: u32) -> (bit: i32) {
	N :: (size_of(u32) * 8) - 1
	return i32(N - intrinsics.count_leading_zeros(word))
}

// Exported solely to facilitate testing
@(require_results)
fls_uint :: proc "contextless" (size: uint) -> (bit: i32) {
	N :: (size_of(uint) * 8) - 1
	return i32(N - intrinsics.count_leading_zeros(size))
}