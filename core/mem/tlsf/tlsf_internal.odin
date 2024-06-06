/*
	Copyright 2024 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Matt Conte:      Original C implementation, see LICENSE file in this package
		Jeroen van Rijn: Source port
*/


package mem_tlsf

import "base:intrinsics"
import "base:runtime"
// import "core:fmt"

// log2 of number of linear subdivisions of block sizes.
// Larger values require more memory in the control structure.
// Values of 4 or 5 are typical.
TLSF_SL_INDEX_COUNT_LOG2 :: #config(TLSF_SL_INDEX_COUNT_LOG2, 5)

// All allocation sizes and addresses are aligned to 4/8 bytes
ALIGN_SIZE_LOG2 :: 3 when size_of(uintptr) == 8 else 2

// We can increase this to support larger allocation sizes,
// at the expense of more overhead in the TLSF structure
FL_INDEX_MAX :: 32 when size_of(uintptr) == 8 else 30
#assert(FL_INDEX_MAX < 36)

ALIGN_SIZE          :: 1 << ALIGN_SIZE_LOG2
SL_INDEX_COUNT      :: 1 << TLSF_SL_INDEX_COUNT_LOG2
FL_INDEX_SHIFT      :: TLSF_SL_INDEX_COUNT_LOG2 + ALIGN_SIZE_LOG2
FL_INDEX_COUNT      :: FL_INDEX_MAX - FL_INDEX_SHIFT + 1
SMALL_BLOCK_SIZE    :: 1 << FL_INDEX_SHIFT

/*
We support allocations of sizes up to (1 << `FL_INDEX_MAX`) bits.
However, because we linearly subdivide the second-level lists, and
our minimum size granularity is 4 bytes, it doesn't make sense to
create first-level lists for sizes smaller than `SL_INDEX_COUNT` * 4,
or (1 << (`TLSF_SL_INDEX_COUNT_LOG2` + 2)) bytes, as there we will be
trying to split size ranges into more slots than we have available.
Instead, we calculate the minimum threshold size, and place all
blocks below that size into the 0th first-level list.
*/

// SL_INDEX_COUNT must be <= number of bits in sl_bitmap's storage tree
#assert(size_of(uint) * 8 >= SL_INDEX_COUNT)

// Ensure we've properly tuned our sizes.
#assert(ALIGN_SIZE == SMALL_BLOCK_SIZE / SL_INDEX_COUNT)

#assert(size_of(Allocator) % ALIGN_SIZE == 0)

Pool :: struct {
	data:      []u8 `fmt:"-"`,
	allocator: runtime.Allocator,
	next:      ^Pool,
}


/*
Block header structure.

There are several implementation subtleties involved:
- The `prev_phys_block` field is only valid if the previous block is free.
- The `prev_phys_block` field is actually stored at the end of the
	previous block. It appears at the beginning of this structure only to
	simplify the implementation.
- The `next_free` / `prev_free` fields are only valid if the block is free.
*/
Block_Header :: struct {
	prev_phys_block: ^Block_Header,
	size:            uint, // The size of this block, excluding the block header

	// Next and previous free blocks.
	next_free: ^Block_Header,
	prev_free: ^Block_Header,
}
#assert(offset_of(Block_Header, prev_phys_block) == 0)

/*
Since block sizes are always at least a multiple of 4, the two least
significant bits of the size field are used to store the block status:
- bit 0: whether block is busy or free
- bit 1: whether previous block is busy or free
*/
BLOCK_HEADER_FREE      :: uint(1 << 0)
BLOCK_HEADER_PREV_FREE :: uint(1 << 1)

/*
The size of the block header exposed to used blocks is the `size` field.
The `prev_phys_block` field is stored *inside* the previous free block.
*/
BLOCK_HEADER_OVERHEAD :: uint(size_of(uint))

POOL_OVERHEAD :: 2 * BLOCK_HEADER_OVERHEAD

// User data starts directly after the size field in a used block.
BLOCK_START_OFFSET :: offset_of(Block_Header, size) + size_of(Block_Header{}.size)

/*
A free block must be large enough to store its header minus the size of
the `prev_phys_block` field, and no larger than the number of addressable
bits for `FL_INDEX`.
*/
BLOCK_SIZE_MIN :: uint(size_of(Block_Header) - size_of(^Block_Header))
BLOCK_SIZE_MAX :: uint(1) << FL_INDEX_MAX

/*
	TLSF achieves O(1) cost for `alloc` and `free` operations by limiting
	the search for a free block to a free list of guaranteed size
	adequate to fulfill the request, combined with efficient free list
	queries using bitmasks and architecture-specific bit-manipulation
	routines.

	NOTE: TLSF spec relies on ffs/fls returning value 0..31.
*/

@(require_results)
ffs :: proc "contextless" (word: u32) -> (bit: i32) {
	return -1 if word == 0 else i32(intrinsics.count_trailing_zeros(word))
}

@(require_results)
fls :: proc "contextless" (word: u32) -> (bit: i32) {
	N :: (size_of(u32) * 8) - 1
	return i32(N - intrinsics.count_leading_zeros(word))
}

@(require_results)
fls_uint :: proc "contextless" (size: uint) -> (bit: i32) {
	N :: (size_of(uint) * 8) - 1
	return i32(N - intrinsics.count_leading_zeros(size))
}

@(require_results)
block_size :: proc "contextless" (block: ^Block_Header) -> (size: uint) {
	return block.size &~ (BLOCK_HEADER_FREE | BLOCK_HEADER_PREV_FREE)
}

block_set_size :: proc "contextless" (block: ^Block_Header, size: uint) {
	old_size := block.size
	block.size = size | (old_size & (BLOCK_HEADER_FREE | BLOCK_HEADER_PREV_FREE))
}

@(require_results)
block_is_last :: proc "contextless" (block: ^Block_Header) -> (is_last: bool) {
	return block_size(block) == 0
}

@(require_results)
block_is_free :: proc "contextless" (block: ^Block_Header) -> (is_free: bool) {
	return (block.size & BLOCK_HEADER_FREE) == BLOCK_HEADER_FREE
}

block_set_free :: proc "contextless" (block: ^Block_Header) {
	block.size |= BLOCK_HEADER_FREE
}

block_set_used :: proc "contextless" (block: ^Block_Header) {
	block.size &~= BLOCK_HEADER_FREE
}

@(require_results)
block_is_prev_free :: proc "contextless" (block: ^Block_Header) -> (is_prev_free: bool) {
	return (block.size & BLOCK_HEADER_PREV_FREE) == BLOCK_HEADER_PREV_FREE
}

block_set_prev_free :: proc "contextless" (block: ^Block_Header) {
	block.size |= BLOCK_HEADER_PREV_FREE
}

block_set_prev_used :: proc "contextless" (block: ^Block_Header) {
	block.size &~= BLOCK_HEADER_PREV_FREE
}

@(require_results)
block_from_ptr :: proc(ptr: rawptr) -> (block_ptr: ^Block_Header) {
	return (^Block_Header)(uintptr(ptr) - BLOCK_START_OFFSET)
}

@(require_results)
block_to_ptr   :: proc(block: ^Block_Header) -> (ptr: rawptr) {
	return rawptr(uintptr(block) + BLOCK_START_OFFSET)
}

// Return location of next block after block of given size.
@(require_results)
offset_to_block :: proc(ptr: rawptr, size: uint) -> (block: ^Block_Header) {
	return (^Block_Header)(uintptr(ptr) + uintptr(size))
}

@(require_results)
offset_to_block_backwards :: proc(ptr: rawptr, size: uint) -> (block: ^Block_Header) {
	return (^Block_Header)(uintptr(ptr) - uintptr(size))
}

// Return location of previous block.
@(require_results)
block_prev :: proc(block: ^Block_Header) -> (prev: ^Block_Header) {
	assert(block_is_prev_free(block), "previous block must be free")
	return block.prev_phys_block
}

// Return location of next existing block.
@(require_results)
block_next :: proc(block: ^Block_Header) -> (next: ^Block_Header) {
	return offset_to_block(block_to_ptr(block), block_size(block) - BLOCK_HEADER_OVERHEAD)
}

// Link a new block with its physical neighbor, return the neighbor.
@(require_results)
block_link_next :: proc(block: ^Block_Header) -> (next: ^Block_Header) {
	next = block_next(block)
	next.prev_phys_block = block
 	return
}

block_mark_as_free :: proc(block: ^Block_Header) {
	// Link the block to the next block, first.
	next := block_link_next(block)
	block_set_prev_free(next)
	block_set_free(block)
}

block_mark_as_used :: proc(block: ^Block_Header) {
	next := block_next(block)
	block_set_prev_used(next)
	block_set_used(block)
}

@(require_results)
align_up :: proc(x, align: uint) -> (aligned: uint) {
	assert(0 == (align & (align - 1)), "must align to a power of two")
	return (x + (align - 1)) &~ (align - 1)
}

@(require_results)
align_down :: proc(x, align: uint) -> (aligned: uint) {
	assert(0 == (align & (align - 1)), "must align to a power of two")
	return x - (x & (align - 1))
}

@(require_results)
align_ptr :: proc(ptr: rawptr, align: uint) -> (aligned: rawptr) {
	assert(0 == (align & (align - 1)), "must align to a power of two")
	align_mask := uintptr(align) - 1
	_ptr       := uintptr(ptr)
	_aligned   := (_ptr + align_mask) &~ (align_mask)
	return rawptr(_aligned)
}

// Adjust an allocation size to be aligned to word size, and no smaller than internal minimum.
@(require_results)
adjust_request_size :: proc(size, align: uint) -> (adjusted: uint) {
	if size == 0 {
		return 0
	}

	// aligned size must not exceed `BLOCK_SIZE_MAX`, or we'll go out of bounds on `sl_bitmap`.
	if aligned := align_up(size, align); aligned < BLOCK_SIZE_MAX {
		adjusted = min(aligned, BLOCK_SIZE_MAX)
	}
	return
}

// Adjust an allocation size to be aligned to word size, and no smaller than internal minimum.
@(require_results)
adjust_request_size_with_err :: proc(size, align: uint) -> (adjusted: uint, err: runtime.Allocator_Error) {
	if size == 0 {
		return 0, nil
	}

	// aligned size must not exceed `BLOCK_SIZE_MAX`, or we'll go out of bounds on `sl_bitmap`.
	if aligned := align_up(size, align); aligned < BLOCK_SIZE_MAX {
		adjusted = min(aligned, BLOCK_SIZE_MAX)
	} else {
		err = .Out_Of_Memory
	}
	return
}

// TLSF utility functions. In most cases these are direct translations of
// the documentation in the research paper.

@(optimization_mode="speed", require_results)
mapping_insert :: proc(size: uint) -> (fl, sl: i32) {
	if size < SMALL_BLOCK_SIZE {
		// Store small blocks in first list.
		sl = i32(size) / (SMALL_BLOCK_SIZE / SL_INDEX_COUNT)
	} else {
		fl = fls_uint(size)
		sl = i32(size >> (uint(fl) - TLSF_SL_INDEX_COUNT_LOG2)) ~ (1 << TLSF_SL_INDEX_COUNT_LOG2)
		fl -= (FL_INDEX_SHIFT - 1)
	}
	return
}

@(optimization_mode="speed", require_results)
mapping_round :: #force_inline proc(size: uint) -> (rounded: uint) {
	rounded = size
	if size >= SMALL_BLOCK_SIZE {
		round := uint(1 << (uint(fls_uint(size) - TLSF_SL_INDEX_COUNT_LOG2))) - 1
		rounded += round
	}
	return
}

// This version rounds up to the next block size (for allocations)
@(optimization_mode="speed", require_results)
mapping_search :: proc(size: uint) -> (fl, sl: i32) {
	return mapping_insert(mapping_round(size))
}

@(require_results)
search_suitable_block :: proc(control: ^Allocator, fli, sli: ^i32) -> (block: ^Block_Header) {
	// First, search for a block in the list associated with the given fl/sl index.
	fl := fli^; sl := sli^

	sl_map := control.sl_bitmap[fli^] & (~u32(0) << uint(sl))
	if sl_map == 0 {
		// No block exists. Search in the next largest first-level list.
		fl_map := control.fl_bitmap & (~u32(0) << uint(fl + 1))
		if fl_map == 0 {
			// No free blocks available, memory has been exhausted.
			return {}
		}

		fl = ffs(fl_map)
		fli^ = fl
		sl_map = control.sl_bitmap[fl]
	}
	assert(sl_map != 0, "internal error - second level bitmap is null")
	sl = ffs(sl_map)
	sli^ = sl

	// Return the first block in the free list.
	return control.blocks[fl][sl]
}

// Remove a free block from the free list.
remove_free_block :: proc(control: ^Allocator, block: ^Block_Header, fl: i32, sl: i32) {
	prev := block.prev_free
	next := block.next_free
	assert(prev != nil, "prev_free can not be nil")
	assert(next != nil, "next_free can not be nil")
	next.prev_free = prev
	prev.next_free = next

	// If this block is the head of the free list, set new head.
	if control.blocks[fl][sl] == block {
		control.blocks[fl][sl] = next

		// If the new head is nil, clear the bitmap
		if next == &control.block_null {
			control.sl_bitmap[fl] &~= (u32(1) << uint(sl))

			// If the second bitmap is now empty, clear the fl bitmap
			if control.sl_bitmap[fl] == 0 {
				control.fl_bitmap &~= (u32(1) << uint(fl))
			}
		}
	}
}

// Insert a free block into the free block list.
insert_free_block :: proc(control: ^Allocator, block: ^Block_Header, fl: i32, sl: i32) {
	current := control.blocks[fl][sl]
	assert(current != nil, "free lists cannot have a nil entry")
	assert(block   != nil, "cannot insert a nil entry into the free list")
	block.next_free = current
	block.prev_free = &control.block_null
	current.prev_free = block

	assert(block_to_ptr(block) == align_ptr(block_to_ptr(block), ALIGN_SIZE), "block not properly aligned")

	// Insert the new block at the head of the list, and mark the first- and second-level bitmaps appropriately.
	control.blocks[fl][sl] = block
	control.fl_bitmap     |= (u32(1) << uint(fl))
	control.sl_bitmap[fl] |= (u32(1) << uint(sl))
}

// Remove a given block from the free list.
block_remove :: proc(control: ^Allocator, block: ^Block_Header) {
	fl, sl := mapping_insert(block_size(block))
	remove_free_block(control, block, fl, sl)
}

// Insert a given block into the free list.
block_insert :: proc(control: ^Allocator, block: ^Block_Header) {
	fl, sl := mapping_insert(block_size(block))
	insert_free_block(control, block, fl, sl)
}

@(require_results)
block_can_split :: proc(block: ^Block_Header, size: uint) -> (can_split: bool) {
	return block_size(block) >= size_of(Block_Header) + size
}

// Split a block into two, the second of which is free.
@(require_results)
block_split :: proc(block: ^Block_Header, size: uint) -> (remaining: ^Block_Header) {
	// Calculate the amount of space left in the remaining block.
	remaining = offset_to_block(block_to_ptr(block), size - BLOCK_HEADER_OVERHEAD)

	remain_size := block_size(block) - (size + BLOCK_HEADER_OVERHEAD)

	assert(block_to_ptr(remaining) == align_ptr(block_to_ptr(remaining), ALIGN_SIZE),
		"remaining block not aligned properly")

	assert(block_size(block) == remain_size + size + BLOCK_HEADER_OVERHEAD)
	block_set_size(remaining, remain_size)
	assert(block_size(remaining) >= BLOCK_SIZE_MIN, "block split with invalid size")

	block_set_size(block, size)
	block_mark_as_free(remaining)

	return remaining
}

// Absorb a free block's storage into an adjacent previous free block.
@(require_results)
block_absorb :: proc(prev: ^Block_Header, block: ^Block_Header) -> (absorbed: ^Block_Header) {
	assert(!block_is_last(prev), "previous block can't be last")
	// Note: Leaves flags untouched.
	prev.size += block_size(block) + BLOCK_HEADER_OVERHEAD
	_ = block_link_next(prev)
	return prev
}

// Merge a just-freed block with an adjacent previous free block.
@(require_results)
block_merge_prev :: proc(control: ^Allocator, block: ^Block_Header) -> (merged: ^Block_Header) {
	merged = block
	if (block_is_prev_free(block)) {
		prev := block_prev(block)
		assert(prev != nil,         "prev physical block can't be nil")
		assert(block_is_free(prev), "prev block is not free though marked as such")
		block_remove(control, prev)
		merged = block_absorb(prev, block)
	}
	return merged
}

// Merge a just-freed block with an adjacent free block.
@(require_results)
block_merge_next :: proc(control: ^Allocator, block: ^Block_Header) -> (merged: ^Block_Header) {
	merged = block
	next  := block_next(block)
	assert(next != nil, "next physical block can't be nil")

	if (block_is_free(next)) {
		assert(!block_is_last(block), "previous block can't be last")
		block_remove(control, next)
		merged = block_absorb(block, next)
	}
	return merged
}

// Trim any trailing block space off the end of a free block, return to pool.
block_trim_free :: proc(control: ^Allocator, block: ^Block_Header, size: uint) {
	assert(block_is_free(block), "block must be free")
	if (block_can_split(block, size)) {
		remaining_block := block_split(block, size)
		_ = block_link_next(block)
		block_set_prev_free(remaining_block)
		block_insert(control, remaining_block)
	}
}

// Trim any trailing block space off the end of a used block, return to pool.
block_trim_used :: proc(control: ^Allocator, block: ^Block_Header, size: uint) {
	assert(!block_is_free(block), "Block must be used")
	if (block_can_split(block, size)) {
		// If the next block is free, we must coalesce.
		remaining_block := block_split(block, size)
		block_set_prev_used(remaining_block)

		remaining_block = block_merge_next(control, remaining_block)
		block_insert(control, remaining_block)
	}
}

// Trim leading block space, return to pool.
@(require_results)
block_trim_free_leading :: proc(control: ^Allocator, block: ^Block_Header, size: uint) -> (remaining: ^Block_Header) {
	remaining = block
	if block_can_split(block, size) {
		// We want the 2nd block.
		remaining = block_split(block, size - BLOCK_HEADER_OVERHEAD)
		block_set_prev_free(remaining)

		_ = block_link_next(block)
		block_insert(control, block)
	}
	return remaining
}

@(require_results)
block_locate_free :: proc(control: ^Allocator, size: uint) -> (block: ^Block_Header) {
	fl, sl: i32
	if size != 0 {
		fl, sl = mapping_search(size)

		/*
		`mapping_search` can futz with the size, so for excessively large sizes it can sometimes wind up
		with indices that are off the end of the block array. So, we protect against that here,
		since this is the only call site of `mapping_search`. Note that we don't need to check `sl`,
		as it comes from a modulo operation that guarantees it's always in range.
		*/
		if fl < FL_INDEX_COUNT {
			block = search_suitable_block(control, &fl, &sl)
		}
	}

	if block != nil {
		assert(block_size(block) >= size)
		remove_free_block(control, block, fl, sl)
	}
	return block
}

@(require_results)
block_prepare_used :: proc(control: ^Allocator, block: ^Block_Header, size: uint) -> (res: []byte, err: runtime.Allocator_Error) {
	if block != nil {
		assert(size != 0, "Size must be non-zero")
		block_trim_free(control, block, size)
		block_mark_as_used(block)
		res = ([^]byte)(block_to_ptr(block))[:size]
	}
	return
}

// Clear control structure and point all empty lists at the null block
clear :: proc(control: ^Allocator) {
	control.block_null.next_free = &control.block_null
	control.block_null.prev_free = &control.block_null

	control.fl_bitmap = 0
	for i in 0..<FL_INDEX_COUNT {
		control.sl_bitmap[i] = 0
		for j in 0..<SL_INDEX_COUNT {
			control.blocks[i][j] = &control.block_null
		}
	}
}

@(require_results)
pool_add :: proc(control: ^Allocator, pool: []u8) -> (err: Error) {
	assert(uintptr(raw_data(pool)) % ALIGN_SIZE == 0, "Added memory must be aligned")

	pool_overhead := POOL_OVERHEAD
	pool_bytes := align_down(len(pool) - pool_overhead, ALIGN_SIZE)

	if pool_bytes < BLOCK_SIZE_MIN {
		return .Backing_Buffer_Too_Small
	} else if pool_bytes > BLOCK_SIZE_MAX {
		return .Backing_Buffer_Too_Large
	}

	// Create the main free block. Offset the start of the block slightly,
	// so that the `prev_phys_block` field falls outside of the pool -
	// it will never be used.
	block := offset_to_block_backwards(raw_data(pool), BLOCK_HEADER_OVERHEAD)

	block_set_size(block, pool_bytes)
	block_set_free(block)
	block_set_prev_used(block)
	block_insert(control, block)

	// Split the block to create a zero-size sentinel block
	next := block_link_next(block)
	block_set_size(next, 0)
	block_set_used(next)
	block_set_prev_free(next)
	return
}

pool_remove :: proc(control: ^Allocator, pool: []u8) {
	block := offset_to_block_backwards(raw_data(pool), BLOCK_HEADER_OVERHEAD)

	assert(block_is_free(block),               "Block should be free")
	assert(!block_is_free(block_next(block)),  "Next block should not be free")
	assert(block_size(block_next(block)) == 0, "Next block size should be zero")

	fl, sl := mapping_insert(block_size(block))
	remove_free_block(control, block, fl, sl)
}

@(require_results)
alloc_bytes_non_zeroed :: proc(control: ^Allocator, size: uint, align: uint) -> (res: []byte, err: runtime.Allocator_Error) {
	assert(control != nil)
	adjust := adjust_request_size(size, ALIGN_SIZE)

	GAP_MINIMUM :: size_of(Block_Header)
	size_with_gap := adjust_request_size(adjust + align + GAP_MINIMUM, align)

	aligned_size := size_with_gap if adjust != 0 && align > ALIGN_SIZE else adjust
	if aligned_size == 0 && size > 0 {
		return nil, .Out_Of_Memory
	}

	block  := block_locate_free(control, aligned_size)
	if block == nil {
		return nil, .Out_Of_Memory
	}
	ptr := block_to_ptr(block)
	aligned := align_ptr(ptr, align)
	gap := uint(int(uintptr(aligned)) - int(uintptr(ptr)))

	if gap != 0 && gap < GAP_MINIMUM {
		gap_remain := GAP_MINIMUM - gap
		offset := uintptr(max(gap_remain, align))
		next_aligned := rawptr(uintptr(aligned) + offset)

		aligned = align_ptr(next_aligned, align)

		gap = uint(int(uintptr(aligned)) - int(uintptr(ptr)))
	}

	if gap != 0 {
		assert(gap >= GAP_MINIMUM, "gap size too small")
		block = block_trim_free_leading(control, block, gap)
	}

	return block_prepare_used(control, block, adjust)
}

@(require_results)
alloc_bytes :: proc(control: ^Allocator, size: uint, align: uint) -> (res: []byte, err: runtime.Allocator_Error) {
	res, err = alloc_bytes_non_zeroed(control, size, align)
	if err != nil {
		intrinsics.mem_zero(raw_data(res), len(res))
	}
	return
}


free_with_size :: proc(control: ^Allocator, ptr: rawptr, size: uint) {
	assert(control != nil)
	// `size` is currently ignored
	if ptr == nil {
		return
	}

	block := block_from_ptr(ptr)
	assert(!block_is_free(block), "block already marked as free") // double free
	block_mark_as_free(block)
	block = block_merge_prev(control, block)
	block = block_merge_next(control, block)
	block_insert(control, block)
}


@(require_results)
resize :: proc(control: ^Allocator, ptr: rawptr, old_size, new_size: uint, alignment: uint) -> (res: []byte, err: runtime.Allocator_Error) {
	assert(control != nil)
	if ptr != nil && new_size == 0 {
		free_with_size(control, ptr, old_size)
		return
	} else if ptr == nil {
		return alloc_bytes(control, new_size, alignment)
	}

	block := block_from_ptr(ptr)
	next := block_next(block)

	curr_size := block_size(block)
	combined := curr_size + block_size(next) + BLOCK_HEADER_OVERHEAD
	adjust := adjust_request_size(new_size, max(ALIGN_SIZE, alignment))

	assert(!block_is_free(block), "block already marked as free") // double free

	min_size := min(curr_size, new_size, old_size)

	if adjust > curr_size && (!block_is_free(next) || adjust > combined) {
		res = alloc_bytes(control, new_size, alignment) or_return
		if res != nil {
			copy(res, ([^]byte)(ptr)[:min_size])
			free_with_size(control, ptr, curr_size)
		}
		return
	}
	if adjust > curr_size {
		_ = block_merge_next(control, block)
		block_mark_as_used(block)
	}

	block_trim_used(control, block, adjust)
	res = ([^]byte)(ptr)[:new_size]

	if min_size < new_size {
		to_zero := ([^]byte)(ptr)[min_size:new_size]
		runtime.mem_zero(raw_data(to_zero), len(to_zero))
	}
	return
}

@(require_results)
resize_non_zeroed :: proc(control: ^Allocator, ptr: rawptr, old_size, new_size: uint, alignment: uint) -> (res: []byte, err: runtime.Allocator_Error) {
	assert(control != nil)
	if ptr != nil && new_size == 0 {
		free_with_size(control, ptr, old_size)
		return
	} else if ptr == nil {
		return alloc_bytes_non_zeroed(control, new_size, alignment)
	}

	block := block_from_ptr(ptr)
	next := block_next(block)

	curr_size := block_size(block)
	combined := curr_size + block_size(next) + BLOCK_HEADER_OVERHEAD
	adjust := adjust_request_size(new_size, max(ALIGN_SIZE, alignment))

	assert(!block_is_free(block), "block already marked as free") // double free

	min_size := min(curr_size, new_size, old_size)

	if adjust > curr_size && (!block_is_free(next) || adjust > combined) {
		res = alloc_bytes_non_zeroed(control, new_size, alignment) or_return
		if res != nil {
			copy(res, ([^]byte)(ptr)[:min_size])
			free_with_size(control, ptr, old_size)
		}
		return
	}

	if adjust > curr_size {
		_ = block_merge_next(control, block)
		block_mark_as_used(block)
	}

	block_trim_used(control, block, adjust)
	res = ([^]byte)(ptr)[:new_size]
	return
}