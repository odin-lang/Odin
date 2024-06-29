//+build wasm32, wasm64p32
package runtime

import "base:intrinsics"

/*
Port of emmalloc, modified for use in Odin.

Invariants:
	- Per-allocation header overhead is 8 bytes, smallest allocated payload
	  amount is 8 bytes, and a multiple of 4 bytes.
	- Acquired memory blocks are subdivided into disjoint regions that lie
	  next to each other.
	- A region is either in used or free.
	  Used regions may be adjacent, and a used and unused region
	  may be adjacent, but not two unused ones - they would be
	  merged.
	- Memory allocation takes constant time, unless the alloc needs to wasm_memory_grow()
	  or memory is very close to being exhausted.
	- Free and used regions are managed inside "root regions", which are slabs
	  of memory acquired via wasm_memory_grow().
	- Memory retrieved using wasm_memory_grow() can not be given back to the OS.
	  Therefore, frees are internal to the allocator.

Copyright (c) 2010-2014 Emscripten authors, see AUTHORS file.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

WASM_Allocator :: struct #no_copy {
	// The minimum alignment of allocations.
	alignment: uint,
	// A region that contains as payload a single forward linked list of pointers to
	// root regions of each disjoint region blocks.
	list_of_all_regions: ^Root_Region,
	// For each of the buckets, maintain a linked list head node. The head node for each
	// free region is a sentinel node that does not actually represent any free space, but
	// the sentinel is used to avoid awkward testing against (if node == freeRegionHeadNode)
	// when adding and removing elements from the linked list, i.e. we are guaranteed that
	// the sentinel node is always fixed and there, and the actual free region list elements
	// start at free_region_buckets[i].next each.
	free_region_buckets: [NUM_FREE_BUCKETS]Region,
	// A bitmask that tracks the population status for each of the 64 distinct memory regions:
	// a zero at bit position i means that the free list bucket i is empty. This bitmask is
	// used to avoid redundant scanning of the 64 different free region buckets: instead by
	// looking at the bitmask we can find in constant time an index to a free region bucket
	// that contains free memory of desired size.
	free_region_buckets_used: BUCKET_BITMASK_T,
	// Because wasm memory can only be allocated in pages of 64k at a time, we keep any
	// spilled/unused bytes that are left from the allocated pages here, first using this
	// when bytes are needed.
	spill: []byte,
	// Mutex for thread safety, only used if the target feature "atomics" is enabled.
	mu: Mutex_State,
}

// Not required to be called, called on first allocation otherwise.
wasm_allocator_init :: proc(a: ^WASM_Allocator, alignment: uint = 8) {
	assert(is_power_of_two(alignment), "alignment must be a power of two")
	assert(alignment > 4, "alignment must be more than 4")

	a.alignment = alignment

	for i in 0..<NUM_FREE_BUCKETS {
		a.free_region_buckets[i].next = &a.free_region_buckets[i]
		a.free_region_buckets[i].prev = a.free_region_buckets[i].next
	}

	if !claim_more_memory(a, 3*size_of(Region)) {
		panic("wasm_allocator: initial memory could not be allocated")
	}
}

global_default_wasm_allocator_data: WASM_Allocator

default_wasm_allocator :: proc() -> Allocator {
	return wasm_allocator(&global_default_wasm_allocator_data)
}

wasm_allocator :: proc(a: ^WASM_Allocator) -> Allocator {
	return {
		data      = a,
		procedure = wasm_allocator_proc,
	}
}

wasm_allocator_proc :: proc(a: rawptr, mode: Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	a := (^WASM_Allocator)(a)
	if a == nil {
		a = &global_default_wasm_allocator_data
	}

	if a.alignment == 0 {
		wasm_allocator_init(a)
	}

	switch mode {
	case .Alloc:
		ptr := aligned_alloc(a, uint(alignment), uint(size), loc)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		intrinsics.mem_zero(ptr, size)
		return ([^]byte)(ptr)[:size], nil

	case .Alloc_Non_Zeroed:
		ptr := aligned_alloc(a, uint(alignment), uint(size), loc)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		return ([^]byte)(ptr)[:size], nil

	case .Resize:
		ptr := aligned_realloc(a, old_memory, uint(alignment), uint(size), loc)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}

		bytes := ([^]byte)(ptr)[:size]

		if size > old_size {
			new_region := raw_data(bytes[old_size:])
			intrinsics.mem_zero(new_region, size - old_size)
		}

		return bytes, nil

	case .Resize_Non_Zeroed:
		ptr := aligned_realloc(a, old_memory, uint(alignment), uint(size), loc)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		return ([^]byte)(ptr)[:size], nil

	case .Free:
		free(a, old_memory, loc)
		return nil, nil

	case .Free_All, .Query_Info:
		return nil, .Mode_Not_Implemented

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Resize_Non_Zeroed, .Query_Features }
		}
		return nil, nil
	}

	unreachable()
}

// Returns the allocated size of the allocator (both free and used).
// If `nil` is given, the global allocator is used.
wasm_allocator_size :: proc(a: ^WASM_Allocator = nil) -> (size: uint) {
	a := a
	if a == nil {
		a = &global_default_wasm_allocator_data
	}

	lock(a)
	defer unlock(a)

	root := a.list_of_all_regions
	for root != nil {
		size += uint(uintptr(root.end_ptr) - uintptr(root))
		root = root.next
	}

	size += len(a.spill)

	return
}

// Returns the amount of free memory on the allocator.
// If `nil` is given, the global allocator is used.
wasm_allocator_free_space :: proc(a: ^WASM_Allocator = nil) -> (free: uint) {
	a := a
	if a == nil {
		a = &global_default_wasm_allocator_data
	}

	lock(a)
	defer unlock(a)

	bucket_index: u64 = 0
	bucket_mask := a.free_region_buckets_used

	for bucket_mask != 0 {
		index_add := intrinsics.count_trailing_zeros(bucket_mask)
		bucket_index += index_add
		bucket_mask >>= index_add
		for free_region := a.free_region_buckets[bucket_index].next; free_region != &a.free_region_buckets[bucket_index]; free_region = free_region.next {
			free += free_region.size - REGION_HEADER_SIZE
		}
		bucket_index += 1
		bucket_mask >>= 1
	}

	free += len(a.spill)

	return
}

@(private="file")
NUM_FREE_BUCKETS :: 64
@(private="file")
BUCKET_BITMASK_T :: u64

// Dynamic memory is subdivided into regions, in the format

// <size:u32> ..... <size:u32> | <size:u32> ..... <size:u32> | <size:u32> ..... <size:u32> | .....

// That is, at the bottom and top end of each memory region, the size of that region is stored. That allows traversing the
// memory regions backwards and forwards. Because each allocation must be at least a multiple of 4 bytes, the lowest two bits of
// each size field is unused. Free regions are distinguished by used regions by having the FREE_REGION_FLAG bit present
// in the size field. I.e. for free regions, the size field is odd, and for used regions, the size field reads even.
@(private="file")
FREE_REGION_FLAG :: 0x1

// Attempts to alloc more than this many bytes would cause an overflow when calculating the size of a region,
// therefore allocations larger than this are short-circuited immediately on entry.
@(private="file")
MAX_ALLOC_SIZE :: 0xFFFFFFC7

// A free region has the following structure:
// <size:uint> <prevptr> <nextptr> ... <size:uint>

@(private="file")
Region :: struct {
	size: uint,
	prev, next: ^Region,
	_at_the_end_of_this_struct_size: uint,
}

// Each memory block starts with a Root_Region at the beginning.
// The Root_Region specifies the size of the region block, and forms a linked
// list of all Root_Regions in the program, starting with `list_of_all_regions`
// below.
@(private="file")
Root_Region :: struct {
	size:    u32,
	next:    ^Root_Region,
	end_ptr: ^byte,
}

@(private="file")
Mutex_State :: enum u32 {
	Unlocked = 0,
	Locked   = 1,
	Waiting  = 2,
}

@(private="file")
lock :: proc(a: ^WASM_Allocator) {
	when intrinsics.has_target_feature("atomics") {
		@(cold)
		lock_slow :: proc(a: ^WASM_Allocator, curr_state: Mutex_State) {
			new_state := curr_state // Make a copy of it

			spin_lock: for spin in 0..<i32(100) {
				state, ok := intrinsics.atomic_compare_exchange_weak_explicit(&a.mu, .Unlocked, new_state, .Acquire, .Consume)
				if ok {
					return
				}

				if state == .Waiting {
					break spin_lock
				}

				for i := min(spin+1, 32); i > 0; i -= 1 {
					intrinsics.cpu_relax()
				}
			}

			// Set just in case 100 iterations did not do it
			new_state = .Waiting

			for {
				if intrinsics.atomic_exchange_explicit(&a.mu, .Waiting, .Acquire) == .Unlocked {
					return
				}

				assert(intrinsics.wasm_memory_atomic_wait32((^u32)(&a.mu), u32(new_state), -1) != 0)
				intrinsics.cpu_relax()
			}
		}


		if v := intrinsics.atomic_exchange_explicit(&a.mu, .Locked, .Acquire); v != .Unlocked {
			lock_slow(a, v)
		}
	}
}

@(private="file")
unlock :: proc(a: ^WASM_Allocator) {
	when intrinsics.has_target_feature("atomics") {
		@(cold)
		unlock_slow :: proc(a: ^WASM_Allocator) {
			for {
				s := intrinsics.wasm_memory_atomic_notify32((^u32)(&a.mu), 1)
				if s >= 1 {
					return
				}
			}
		}

		switch intrinsics.atomic_exchange_explicit(&a.mu, .Unlocked, .Release) {
		case .Unlocked:
			unreachable()
		case .Locked:
		// Okay
		case .Waiting:
			unlock_slow(a)
		}
	}
}

@(private="file")
assert_locked :: proc(a: ^WASM_Allocator) {
	when intrinsics.has_target_feature("atomics") {
		assert(intrinsics.atomic_load(&a.mu) != .Unlocked)
	}
}

@(private="file")
has_alignment_uintptr :: proc(ptr: uintptr, #any_int alignment: uintptr) -> bool {
	return ptr & (alignment-1) == 0
}

@(private="file")
has_alignment_uint :: proc(ptr: uint, alignment: uint) -> bool {
	return ptr & (alignment-1) == 0
}

@(private="file")
has_alignment :: proc {
	has_alignment_uintptr,
	has_alignment_uint,
}

@(private="file")
REGION_HEADER_SIZE :: 2*size_of(uint)

@(private="file")
SMALLEST_ALLOCATION_SIZE :: 2*size_of(rawptr)

// Subdivide regions of free space into distinct circular doubly linked lists, where each linked list
// represents a range of free space blocks. The following function compute_free_list_bucket() converts
// an allocation size to the bucket index that should be looked at.
#assert(NUM_FREE_BUCKETS == 64, "Following function is tailored specifically for the NUM_FREE_BUCKETS == 64 case")
@(private="file")
compute_free_list_bucket :: proc(size: uint) -> uint {
	if size < 128 { return (size >> 3) - 1 }

	clz := intrinsics.count_leading_zeros(i32(size))
	bucket_index: i32 = ((clz > 19) \
		?     110 - (clz<<2) + ((i32)(size >> (u32)(29-clz)) ~ 4) \
		: min( 71 - (clz<<1) + ((i32)(size >> (u32)(30-clz)) ~ 2), NUM_FREE_BUCKETS-1))

	assert(bucket_index >= 0)
	assert(bucket_index < NUM_FREE_BUCKETS)
	return uint(bucket_index)
}

@(private="file")
prev_region :: proc(region: ^Region) -> ^Region {
	prev_region_size := ([^]uint)(region)[-1]
	prev_region_size  = prev_region_size & ~uint(FREE_REGION_FLAG)
	return (^Region)(uintptr(region)-uintptr(prev_region_size))
}

@(private="file")
next_region :: proc(region: ^Region) -> ^Region {
	return (^Region)(uintptr(region)+uintptr(region.size))
}

@(private="file")
region_ceiling_size :: proc(region: ^Region) -> uint {
	return ([^]uint)(uintptr(region)+uintptr(region.size))[-1]
}

@(private="file")
region_is_free :: proc(r: ^Region) -> bool {
	return region_ceiling_size(r) & FREE_REGION_FLAG >= 1
}

@(private="file")
region_is_in_use :: proc(r: ^Region) -> bool {
	return r.size == region_ceiling_size(r)
}

@(private="file")
region_payload_start_ptr :: proc(r: ^Region) -> [^]byte {
	return ([^]byte)(r)[size_of(uint):]
}

@(private="file")
region_payload_end_ptr :: proc(r: ^Region) -> [^]byte {
	return ([^]byte)(r)[r.size-size_of(uint):]
}

@(private="file")
create_used_region :: proc(ptr: rawptr, size: uint) {
	assert(has_alignment(uintptr(ptr), size_of(uint)))
	assert(has_alignment(size, size_of(uint)))
	assert(size >= size_of(Region))

	uptr := ([^]uint)(ptr)
	uptr[0] = size
	uptr[size/size_of(uint)-1] = size
}

@(private="file")
create_free_region :: proc(ptr: rawptr, size: uint) {
	assert(has_alignment(uintptr(ptr), size_of(uint)))
	assert(has_alignment(size, size_of(uint)))
	assert(size >= size_of(Region))

	free_region := (^Region)(ptr)
	free_region.size = size
	([^]uint)(ptr)[size/size_of(uint)-1] = size | FREE_REGION_FLAG
}

@(private="file")
prepend_to_free_list :: proc(region: ^Region, prepend_to: ^Region) {
	assert(region_is_free(region))
	region.next = prepend_to
	region.prev = prepend_to.prev
	prepend_to.prev = region
	region.prev.next = region
}

@(private="file")
unlink_from_free_list :: proc(region: ^Region) {
	assert(region_is_free(region))
	region.prev.next = region.next
	region.next.prev = region.prev
}

@(private="file")
link_to_free_list :: proc(a: ^WASM_Allocator, free_region: ^Region) {
	assert(free_region.size >= size_of(Region))
	bucket_index := compute_free_list_bucket(free_region.size-REGION_HEADER_SIZE)
	free_list_head := &a.free_region_buckets[bucket_index]
	free_region.prev = free_list_head
	free_region.next = free_list_head.next
	free_list_head.next = free_region
	free_region.next.prev = free_region
	a.free_region_buckets_used |= BUCKET_BITMASK_T(1) << bucket_index
}

@(private="file")
claim_more_memory :: proc(a: ^WASM_Allocator, num_bytes: uint) -> bool {

	PAGE_SIZE :: 64 * 1024

	page_alloc :: proc(page_count: int) -> []byte {
		prev_page_count := intrinsics.wasm_memory_grow(0, uintptr(page_count))
		if prev_page_count < 0 { return nil }

		ptr := ([^]byte)(uintptr(prev_page_count) * PAGE_SIZE)
		return ptr[:page_count * PAGE_SIZE]
	}

	alloc :: proc(a: ^WASM_Allocator, num_bytes: uint) -> (bytes: [^]byte) #no_bounds_check {
		if uint(len(a.spill)) >= num_bytes {
			bytes = raw_data(a.spill[:num_bytes])
			a.spill = a.spill[num_bytes:]
			return
		}

		pages := int((num_bytes / PAGE_SIZE) + 1)
		allocated := page_alloc(pages)
		if allocated == nil { return nil }

		// If the allocated memory is a direct continuation of the spill from before,
		// we can just extend the spill.
		spill_end := uintptr(raw_data(a.spill)) + uintptr(len(a.spill))
		if spill_end == uintptr(raw_data(allocated)) {
			raw_spill := (^Raw_Slice)(&a.spill)
			raw_spill.len += len(allocated)
		} else {
			// Otherwise, we have to "waste" the previous spill.
			// Now this is probably uncommon, and will only happen if another code path
			// is also requesting pages.
			a.spill = allocated
		}

		bytes = raw_data(a.spill)
		a.spill = a.spill[num_bytes:]
		return
	}

	num_bytes := num_bytes
	num_bytes  = align_forward(num_bytes, a.alignment)

	start_ptr := alloc(a, uint(num_bytes))
	if start_ptr == nil { return false }

	assert(has_alignment(uintptr(start_ptr), align_of(uint)))
	end_ptr := start_ptr[num_bytes:]

	end_sentinel_region := (^Region)(end_ptr[-size_of(Region):])
	create_used_region(end_sentinel_region, size_of(Region))

	// If we are the sole user of wasm_memory_grow(), it will feed us continuous/consecutive memory addresses - take advantage
	// of that if so: instead of creating two disjoint memory regions blocks, expand the previous one to a larger size.
	prev_alloc_end_address := a.list_of_all_regions != nil ? a.list_of_all_regions.end_ptr : nil
	if start_ptr == prev_alloc_end_address {
		prev_end_sentinel := prev_region((^Region)(start_ptr))
		assert(region_is_in_use(prev_end_sentinel))
		prev_region := prev_region(prev_end_sentinel)

		a.list_of_all_regions.end_ptr = end_ptr

		// Two scenarios, either the last region of the previous block was in use, in which case we need to create
		// a new free region in the newly allocated space; or it was free, in which case we can extend that region
		// to cover a larger size.
		if region_is_free(prev_region) {
			new_free_region_size := uint(uintptr(end_sentinel_region) - uintptr(prev_region))
			unlink_from_free_list(prev_region)
			create_free_region(prev_region, new_free_region_size)
			link_to_free_list(a, prev_region)
			return true
		}

		start_ptr = start_ptr[-size_of(Region):]
	} else {
		create_used_region(start_ptr, size_of(Region))

		new_region_block := (^Root_Region)(start_ptr)
		new_region_block.next = a.list_of_all_regions
		new_region_block.end_ptr = end_ptr
		a.list_of_all_regions = new_region_block
		start_ptr = start_ptr[size_of(Region):]
	}

	create_free_region(start_ptr, uint(uintptr(end_sentinel_region)-uintptr(start_ptr)))
	link_to_free_list(a, (^Region)(start_ptr))
	return true
}

@(private="file")
validate_alloc_size :: proc(size: uint) -> uint {
	#assert(size_of(uint) >= size_of(uintptr))
	#assert(size_of(uint)  % size_of(uintptr) == 0)

	// NOTE: emmalloc aligns this forward on pointer size, but I think that is a mistake and will
	// do bad on wasm64p32.

	validated_size := size > SMALLEST_ALLOCATION_SIZE ? align_forward(size, size_of(uint)) : SMALLEST_ALLOCATION_SIZE
	assert(validated_size >= size) // Assert we haven't wrapped.

	return validated_size
}

@(private="file")
allocate_memory :: proc(a: ^WASM_Allocator, alignment: uint, size: uint, loc := #caller_location) -> rawptr {

	attempt_allocate :: proc(a: ^WASM_Allocator, free_region: ^Region, alignment, size: uint) -> rawptr {
		assert_locked(a)
		free_region := free_region

		payload_start_ptr := uintptr(region_payload_start_ptr(free_region))
		payload_start_ptr_aligned := align_forward(payload_start_ptr, uintptr(alignment))
		payload_end_ptr := uintptr(region_payload_end_ptr(free_region))

		if payload_start_ptr_aligned + uintptr(size) > payload_end_ptr {
			return nil
		}

		// We have enough free space, so the memory allocation will be made into this region. Remove this free region
		// from the list of free regions: whatever slop remains will be later added back to the free region pool.
		unlink_from_free_list(free_region)

		// Before we proceed further, fix up the boundary between this and the preceding region,
		// so that the boundary between the two regions happens at a right spot for the payload to be aligned.
		if payload_start_ptr != payload_start_ptr_aligned {
			prev := prev_region(free_region)
			assert(region_is_in_use(prev))
			region_boundary_bump_amount := payload_start_ptr_aligned - payload_start_ptr
			new_this_region_size := free_region.size - uint(region_boundary_bump_amount)
			create_used_region(prev, prev.size + uint(region_boundary_bump_amount))
			free_region = (^Region)(uintptr(free_region) + region_boundary_bump_amount)
			free_region.size = new_this_region_size
		}

		// Next, we need to decide whether this region is so large that it should be split into two regions,
		// one representing the newly used memory area, and at the high end a remaining leftover free area.
		// This splitting to two is done always if there is enough space for the high end to fit a region.
		// Carve 'size' bytes of payload off this region. So,
		// [sz prev next sz]
		// becomes
		// [sz payload sz] [sz prev next sz]
		if size_of(Region) + REGION_HEADER_SIZE + size <= free_region.size {
			new_free_region := (^Region)(uintptr(free_region) + REGION_HEADER_SIZE + uintptr(size))
			create_free_region(new_free_region, free_region.size - size - REGION_HEADER_SIZE)
			link_to_free_list(a, new_free_region)
			create_used_region(free_region, size + REGION_HEADER_SIZE)
		} else {
			// There is not enough space to split the free memory region into used+free parts, so consume the whole
			// region as used memory, not leaving a free memory region behind.
			// Initialize the free region as used by resetting the ceiling size to the same value as the size at bottom.
			([^]uint)(uintptr(free_region) + uintptr(free_region.size))[-1] = free_region.size
		}

		return rawptr(uintptr(free_region) + size_of(uint))
	}

	assert_locked(a)
	assert(is_power_of_two(alignment))
	assert(size <= MAX_ALLOC_SIZE, "allocation too big", loc=loc)

	alignment := alignment
	alignment  = max(alignment, a.alignment)

	size := size
	size  = validate_alloc_size(size)

	// Attempt to allocate memory starting from smallest bucket that can contain the required amount of memory.
	// Under normal alignment conditions this should always be the first or second bucket we look at, but if
	// performing an allocation with complex alignment, we may need to look at multiple buckets.
	bucket_index := compute_free_list_bucket(size)
	bucket_mask := a.free_region_buckets_used >> bucket_index

	// Loop through each bucket that has free regions in it, based on bits set in free_region_buckets_used bitmap.
	for bucket_mask != 0 {
		index_add := intrinsics.count_trailing_zeros(bucket_mask)
		bucket_index += uint(index_add)
		bucket_mask >>= index_add
		assert(bucket_index <= NUM_FREE_BUCKETS-1)
		assert(a.free_region_buckets_used & (BUCKET_BITMASK_T(1) << bucket_index) > 0)

		free_region := a.free_region_buckets[bucket_index].next
		assert(free_region != nil)
		if free_region != &a.free_region_buckets[bucket_index] {
			ptr := attempt_allocate(a, free_region, alignment, size)
			if ptr != nil {
				return ptr
			}

			// We were not able to allocate from the first region found in this bucket, so penalize
			// the region by cycling it to the end of the doubly circular linked list. (constant time)
			// This provides a randomized guarantee that when performing allocations of size k to a
			// bucket of [k-something, k+something] range, we will not always attempt to satisfy the
			// allocation from the same available region at the front of the list, but we try each
			// region in turn.
			unlink_from_free_list(free_region)
			prepend_to_free_list(free_region, &a.free_region_buckets[bucket_index])
			// But do not stick around to attempt to look at other regions in this bucket - move
			// to search the next populated bucket index if this did not fit. This gives a practical
			// "allocation in constant time" guarantee, since the next higher bucket will only have
			// regions that are all of strictly larger size than the requested allocation. Only if
			// there is a difficult alignment requirement we may fail to perform the allocation from
			// a region in the next bucket, and if so, we keep trying higher buckets until one of them
			// works.
			bucket_index += 1
			bucket_mask >>= 1
		} else {
			// This bucket was not populated after all with any regions,
			// but we just had a stale bit set to mark a populated bucket.
			// Reset the bit to update latest status so that we do not
			// redundantly look at this bucket again.
			a.free_region_buckets_used &~= BUCKET_BITMASK_T(1) << bucket_index
			bucket_mask ~= 1
		}

		assert((bucket_index == NUM_FREE_BUCKETS && bucket_mask == 0) || (bucket_mask == a.free_region_buckets_used >> bucket_index))
	}

	// None of the buckets were able to accommodate an allocation. If this happens we are almost out of memory.
	// The largest bucket might contain some suitable regions, but we only looked at one region in that bucket, so
	// as a last resort, loop through more free regions in the bucket that represents the largest allocations available.
	// But only if the bucket representing largest allocations available is not any of the first thirty buckets,
	// these represent allocatable areas less than <1024 bytes - which could be a lot of scrap.
	// In such case, prefer to claim more memory right away.
	largest_bucket_index := NUM_FREE_BUCKETS - 1 - intrinsics.count_leading_zeros(a.free_region_buckets_used)
	// free_region will be null if there is absolutely no memory left. (all buckets are 100% used)
	free_region := a.free_region_buckets_used > 0 ? a.free_region_buckets[largest_bucket_index].next : nil
	// The 30 first free region buckets cover memory blocks < 2048 bytes, so skip looking at those here (too small)
	if a.free_region_buckets_used >> 30 > 0 {
		// Look only at a constant number of regions in this bucket max, to avoid bad worst case behavior.
		// If this many regions cannot find free space, we give up and prefer to claim more memory instead.
		max_regions_to_try_before_giving_up :: 99
		num_tries_left := max_regions_to_try_before_giving_up
		for ; free_region != &a.free_region_buckets[largest_bucket_index] && num_tries_left > 0; num_tries_left -= 1 {
			ptr := attempt_allocate(a, free_region, alignment, size)
			if ptr != nil {
				return ptr
			}
			free_region = free_region.next
		}
	}

	// We were unable to find a free memory region. Must claim more memory!
	num_bytes_to_claim := size+size_of(Region)*3
	if alignment > a.alignment {
		num_bytes_to_claim += alignment
	}
	success := claim_more_memory(a, num_bytes_to_claim)
	if (success) {
		// Try allocate again with the newly available memory.
		return allocate_memory(a, alignment, size)
	}

	// also claim_more_memory failed, we are really really constrained :( As a last resort, go back to looking at the
	// bucket we already looked at above, continuing where the above search left off - perhaps there are
	// regions we overlooked the first time that might be able to satisfy the allocation.
	if free_region != nil {
		for free_region != &a.free_region_buckets[largest_bucket_index] {
			ptr := attempt_allocate(a, free_region, alignment, size)
			if ptr != nil {
				return ptr
			}
			free_region = free_region.next
		}
	}

	// Fully out of memory.
	return nil
}

@(private="file")
aligned_alloc :: proc(a: ^WASM_Allocator, alignment, size: uint, loc := #caller_location) -> rawptr {
	lock(a)
	defer unlock(a)

	return allocate_memory(a, alignment, size, loc)
}

@(private="file")
free :: proc(a: ^WASM_Allocator, ptr: rawptr, loc := #caller_location) {
	if ptr == nil {
		return
	}

	region_start_ptr := uintptr(ptr) - size_of(uint)
	region := (^Region)(region_start_ptr)
	assert(has_alignment(region_start_ptr, size_of(uint)))

	lock(a)
	defer unlock(a)

	size := region.size
	assert(region_is_in_use(region), "double free or corrupt region", loc=loc)

	prev_region_size_field := ([^]uint)(region)[-1]
	prev_region_size := prev_region_size_field & ~uint(FREE_REGION_FLAG)
	if prev_region_size_field != prev_region_size {
		prev_region := (^Region)(uintptr(region) - uintptr(prev_region_size))
		unlink_from_free_list(prev_region)
		region_start_ptr = uintptr(prev_region)
		size += prev_region_size
	}

	next_reg := next_region(region)
	size_at_end := (^uint)(region_payload_end_ptr(next_reg))^
	if next_reg.size != size_at_end {
		unlink_from_free_list(next_reg)
		size += next_reg.size
	}

	create_free_region(rawptr(region_start_ptr), size)
	link_to_free_list(a, (^Region)(region_start_ptr))
}

@(private="file")
aligned_realloc :: proc(a: ^WASM_Allocator, ptr: rawptr, alignment, size: uint, loc := #caller_location) -> rawptr {

	attempt_region_resize :: proc(a: ^WASM_Allocator, region: ^Region, size: uint) -> bool {
		lock(a)
		defer unlock(a)

		// First attempt to resize this region, if the next region that follows this one
		// is a free region.
		next_reg := next_region(region)
		next_region_end_ptr := uintptr(next_reg) + uintptr(next_reg.size)
		size_at_ceiling := ([^]uint)(next_region_end_ptr)[-1]
		if next_reg.size != size_at_ceiling { // Next region is free?
			assert(region_is_free(next_reg))
			new_next_region_start_ptr := uintptr(region) + uintptr(size)
			assert(has_alignment(new_next_region_start_ptr, size_of(uint)))
			// Next region does not shrink to too small size?
			if new_next_region_start_ptr + size_of(Region) <= next_region_end_ptr {
				unlink_from_free_list(next_reg)
				create_free_region(rawptr(new_next_region_start_ptr), uint(next_region_end_ptr - new_next_region_start_ptr))
				link_to_free_list(a, (^Region)(new_next_region_start_ptr))
				create_used_region(region, uint(new_next_region_start_ptr - uintptr(region)))
				return true
			}
			// If we remove the next region altogether, allocation is satisfied?
			if new_next_region_start_ptr <= next_region_end_ptr {
				unlink_from_free_list(next_reg)
				create_used_region(region, region.size + next_reg.size)
				return true
			}
		} else {
			// Next region is an used region - we cannot change its starting address. However if we are shrinking the
			// size of this region, we can create a new free region between this and the next used region.
			if size + size_of(Region) <= region.size {
				free_region_size := region.size - size
				create_used_region(region, size)
				free_region := (^Region)(uintptr(region) + uintptr(size))
				create_free_region(free_region, free_region_size)
				link_to_free_list(a, free_region)
				return true
			} else if size <= region.size {
				// Caller was asking to shrink the size, but due to not being able to fit a full Region in the shrunk
				// area, we cannot actually do anything. This occurs if the shrink amount is really small. In such case,
				// just call it success without doing any work.
				return true
			}
		}

		return false
	}

	if ptr == nil {
		return aligned_alloc(a, alignment, size, loc)
	}

	if size == 0 {
		free(a, ptr, loc)
		return nil
	}

	if size > MAX_ALLOC_SIZE {
		return nil
	}

	assert(is_power_of_two(alignment))
	assert(has_alignment(uintptr(ptr), alignment), "realloc on different alignment than original allocation", loc=loc)

	size := size
	size  = validate_alloc_size(size)

	region := (^Region)(uintptr(ptr) - size_of(uint))

	// Attempt an in-place resize.
	if attempt_region_resize(a, region, size + REGION_HEADER_SIZE) {
		return ptr
	}

	// Can't do it in-place, allocate new region and copy over.
	newptr := aligned_alloc(a, alignment, size, loc)
	if newptr != nil {
		intrinsics.mem_copy(newptr, ptr, min(size, region.size - REGION_HEADER_SIZE))
		free(a, ptr, loc=loc)
	}

	return newptr
}
