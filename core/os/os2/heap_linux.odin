//+private
package os2

import "core:sys/linux"
import "core:sync"
import "core:mem"

// NOTEs
//
// All allocations below DIRECT_MMAP_THRESHOLD exist inside of memory "Regions." A region
// consists of a Region_Header and the memory that will be divided into allocations to
// send to the user. The memory is an array of "Allocation_Headers" which are 8 bytes.
// Allocation_Headers are used to navigate the memory in the region. The "next" member of
// the Allocation_Header points to the next header, and the space between the headers
// can be used to send to the user. This space between is referred to as "blocks" in the
// code. The indexes in the header refer to these blocks instead of bytes.  This allows us
// to index all the memory in the region with a u16.
//
// When an allocation request is made, it will use the first free block that can contain
// the entire block.  If there is an excess number of blocks (as specified by the constant
// BLOCK_SEGMENT_THRESHOLD), this extra space will be segmented and left in the free_list.
//
// To keep the implementation simple, there can never exist 2 free blocks adjacent to each
// other. Any freeing will result in attempting to merge the blocks before and after the
// newly free'd blocks.
//
// Any request for size above the DIRECT_MMAP_THRESHOLD will result in the allocation
// getting its own individual mmap. Individual mmaps will still get an Allocation_Header
// that contains the size with the last bit set to 1 to indicate it is indeed a direct
// mmap allocation.

// Why not brk?
// glibc's malloc utilizes a mix of the brk and mmap system calls. This implementation
// does *not* utilize the brk system call to avoid possible conflicts with foreign C
// code. Just because we aren't directly using libc, there is nothing stopping the user
// from doing it.

// What's with all the #no_bounds_check?
// When memory is returned from mmap, it technically doesn't get written ... well ... anywhere
// until that region is written to by *you*.  So, when a new region is created, we call mmap
// to get a pointer to some memory, and we claim that memory is a ^Region.  Therefor, the
// region itself is never formally initialized by the compiler as this would result in writing
// zeros to memory that we can already assume are 0. This would also have the effect of
// actually commiting this data to memory whether it gets used or not.


//
// Some variables to play with
//

// Minimum blocks used for any one allocation
MINIMUM_BLOCK_COUNT :: 2

// Number of extra blocks beyond the requested amount where we would segment.
// E.g. (blocks) |H0123456| 7 available
//               |H01H0123| Ask for 2, now 4 available
BLOCK_SEGMENT_THRESHOLD :: 4

// Anything above this threshold will get its own memory map. Since regions
// are indexed by 16 bit integers, this value should not surpass max(u16) * 6
DIRECT_MMAP_THRESHOLD_USER :: int(max(u16))

// The point at which we convert direct mmap to region. This should be a decent
// amount less than DIRECT_MMAP_THRESHOLD to avoid jumping in and out of regions.
MMAP_TO_REGION_SHRINK_THRESHOLD :: DIRECT_MMAP_THRESHOLD - PAGE_SIZE * 4

// free_list is dynamic and is initialized in the begining of the region memory
// when the region is initialized. Once resized, it can be moved anywhere.
FREE_LIST_DEFAULT_CAP :: 32


//
// Other constants that should not be touched
//

// This universally seems to be 4096 outside of uncommon archs.
PAGE_SIZE :: 4096

// just rounding up to nearest PAGE_SIZE
DIRECT_MMAP_THRESHOLD :: (DIRECT_MMAP_THRESHOLD_USER-1) + PAGE_SIZE - (DIRECT_MMAP_THRESHOLD_USER-1) % PAGE_SIZE

// Regions must be big enough to hold DIRECT_MMAP_THRESHOLD - 1 as well
// as end right on a page boundary as to not waste space.
SIZE_OF_REGION :: DIRECT_MMAP_THRESHOLD + 4 * int(PAGE_SIZE)

// size of user memory blocks
BLOCK_SIZE :: size_of(Allocation_Header)

// number of allocation sections (call them blocks) of the region used for allocations
BLOCKS_PER_REGION :: u16((SIZE_OF_REGION - size_of(Region_Header)) / BLOCK_SIZE)

// minimum amount of space that can used by any individual allocation (includes header)
MINIMUM_ALLOCATION :: (MINIMUM_BLOCK_COUNT * BLOCK_SIZE) + BLOCK_SIZE

// This is used as a boolean value for Region_Header.local_addr.
CURRENTLY_ACTIVE :: (^^Region)(~uintptr(0))

FREE_LIST_ENTRIES_PER_BLOCK :: BLOCK_SIZE / size_of(u16)

MMAP_FLAGS : linux.Map_Flags      : {.ANONYMOUS, .PRIVATE}
MMAP_PROT  : linux.Mem_Protection : {.READ, .WRITE}

@thread_local _local_region: ^Region
global_regions: ^Region


// There is no way of correctly setting the last bit of free_idx or
// the last bit of requested, so we can safely use it as a flag to
// determine if we are interacting with a direct mmap.
REQUESTED_MASK :: 0x7FFFFFFFFFFFFFFF
IS_DIRECT_MMAP :: 0x8000000000000000

// Special free_idx value that does not index the free_list.
NOT_FREE :: 0x7FFF
Allocation_Header :: struct #raw_union {
	using _:   struct {
		// Block indicies
		idx:      u16,
		prev:     u16,
		next:     u16,
		free_idx: u16,
	},
	requested: u64,
}

Region_Header :: struct #align(16) {
	next_region:   ^Region,  // points to next region in global_heap (linked list)
	local_addr:    ^^Region, // tracks region ownership via address of _local_region
	reset_addr:    ^^Region, // tracks old local addr for reset
	free_list:     []u16,
	free_list_len: u16,
	free_blocks:   u16,      // number of free blocks in region (includes headers)
	last_used:     u16,      // farthest back block that has been used (need zeroing?)
	_reserved:     u16,
}

Region :: struct {
	hdr: Region_Header,
	memory: [BLOCKS_PER_REGION]Allocation_Header,
}

_heap_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	//
	// NOTE(tetra, 2020-01-14): The heap doesn't respect alignment.
	// Instead, we overallocate by `alignment + size_of(rawptr) - 1`, and insert
	// padding. We also store the original pointer returned by heap_alloc right before
	// the pointer we return to the user.
	//

	aligned_alloc :: proc(size, alignment: int, old_ptr: rawptr = nil) -> ([]byte, mem.Allocator_Error) {
		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_mem: rawptr
		if old_ptr != nil {
			original_old_ptr := mem.ptr_offset((^rawptr)(old_ptr), -1)^
			allocated_mem = heap_resize(original_old_ptr, space+size_of(rawptr))
		} else {
			allocated_mem = heap_alloc(space+size_of(rawptr))
		}
		aligned_mem := rawptr(mem.ptr_offset((^u8)(allocated_mem), size_of(rawptr)))

		ptr := uintptr(aligned_mem)
		aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a)
		diff := int(aligned_ptr - ptr)
		if (size + diff) > space || allocated_mem == nil {
			return nil, .Out_Of_Memory
		}

		aligned_mem = rawptr(aligned_ptr)
		mem.ptr_offset((^rawptr)(aligned_mem), -1)^ = allocated_mem

		return mem.byte_slice(aligned_mem, size), nil
	}

	aligned_free :: proc(p: rawptr) {
		if p != nil {
			heap_free(mem.ptr_offset((^rawptr)(p), -1)^)
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int) -> (new_memory: []byte, err: mem.Allocator_Error) {
		if p == nil {
			return nil, nil
		}

		return aligned_alloc(new_size, new_alignment, p)
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return aligned_alloc(size, alignment)

	case .Free:
		aligned_free(old_memory)

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return aligned_alloc(size, alignment)
		}
		return aligned_resize(old_memory, old_size, size, alignment)

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}

heap_alloc :: proc(size: int) -> rawptr {
	if size >= DIRECT_MMAP_THRESHOLD {
		return _direct_mmap_alloc(size)
	}

	// atomically check if the local region has been stolen
	if _local_region != nil {
		res := sync.atomic_compare_exchange_strong_explicit(
			&_local_region.hdr.local_addr,
			&_local_region,
			CURRENTLY_ACTIVE,
			.Acquire,
			.Relaxed,
		)
		if res != &_local_region {
			// At this point, the region has been stolen and res contains the unexpected value
			expected := res
			if res != CURRENTLY_ACTIVE {
				expected = res
				res = sync.atomic_compare_exchange_strong_explicit(
					&_local_region.hdr.local_addr,
					expected,
					CURRENTLY_ACTIVE,
					.Acquire,
					.Relaxed,
				)
			}
			if res != expected {
				_local_region = nil
			}
		}
	}

	size := size
	size = _round_up_to_nearest(size, BLOCK_SIZE)
	blocks_needed := u16(max(MINIMUM_BLOCK_COUNT, size / BLOCK_SIZE))

	// retrieve a region if new thread or stolen
	if _local_region == nil {
		_local_region, _ = _region_retrieve_with_space(blocks_needed)
		if _local_region == nil {
			return nil
		}
	}
	defer sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)

	// At this point we have a usable region. Let's find the user some memory
	idx: u16
	local_region_idx := _region_get_local_idx()
	back_idx := -1
	infinite: for {
		for i := 0; i < int(_local_region.hdr.free_list_len); i += 1 {
			idx = _local_region.hdr.free_list[i]
			#no_bounds_check if _get_block_count(_local_region.memory[idx]) >= blocks_needed {
				break infinite
			}
		}
		sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)
		_local_region, back_idx = _region_retrieve_with_space(blocks_needed, local_region_idx, back_idx)
	}
	user_ptr, used := _region_get_block(_local_region, idx, blocks_needed)

	sync.atomic_sub_explicit(&_local_region.hdr.free_blocks, used + 1, .Release)

	// If this memory was ever used before, it now needs to be zero'd.
	if idx < _local_region.hdr.last_used {
		mem.zero(user_ptr, int(used) * BLOCK_SIZE)
	} else {
		_local_region.hdr.last_used = idx + used
	}

	return user_ptr
}

heap_resize :: proc(old_memory: rawptr, new_size: int) -> rawptr #no_bounds_check {
	alloc := _get_allocation_header(old_memory)
	if alloc.requested & IS_DIRECT_MMAP > 0 {
		return _direct_mmap_resize(alloc, new_size)
	}

	if new_size > DIRECT_MMAP_THRESHOLD {
		return _direct_mmap_from_region(alloc, new_size)
	}

	return _region_resize(alloc, new_size)
}

heap_free :: proc(memory: rawptr) {
	alloc := _get_allocation_header(memory)
	if sync.atomic_load(&alloc.requested) & IS_DIRECT_MMAP == IS_DIRECT_MMAP {
		_direct_mmap_free(alloc)
		return
	}

	assert(alloc.free_idx == NOT_FREE)

	_region_find_and_assign_local(alloc)
	_region_local_free(alloc)
	sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)
}

//
// Regions
//
_new_region :: proc() -> ^Region #no_bounds_check {
	ptr, errno := linux.mmap(0, uint(SIZE_OF_REGION), MMAP_PROT, MMAP_FLAGS, -1, 0)
	if errno != .NONE {
		return nil
	}
	new_region := (^Region)(ptr)

	new_region.hdr.local_addr = CURRENTLY_ACTIVE
	new_region.hdr.reset_addr = &_local_region

	free_list_blocks := _round_up_to_nearest(FREE_LIST_DEFAULT_CAP, FREE_LIST_ENTRIES_PER_BLOCK)
	_region_assign_free_list(new_region, &new_region.memory[1], u16(free_list_blocks) * FREE_LIST_ENTRIES_PER_BLOCK)

	// + 2 to account for free_list's allocation header
	first_user_block := len(new_region.hdr.free_list) / FREE_LIST_ENTRIES_PER_BLOCK + 2

	// first allocation header (this is a free list)
	new_region.memory[0].next = u16(first_user_block)
	new_region.memory[0].free_idx = NOT_FREE
	new_region.memory[first_user_block].idx = u16(first_user_block)
	new_region.memory[first_user_block].next = BLOCKS_PER_REGION - 1

	// add the first user block to the free list
	new_region.hdr.free_list[0] = u16(first_user_block)
	new_region.hdr.free_list_len = 1
	new_region.hdr.free_blocks = _get_block_count(new_region.memory[first_user_block]) + 1

	for r := sync.atomic_compare_exchange_strong(&global_regions, nil, new_region);
	    r != nil;
	    r = sync.atomic_compare_exchange_strong(&r.hdr.next_region, nil, new_region) {}

	return new_region
}

_region_resize :: proc(alloc: ^Allocation_Header, new_size: int, alloc_is_free_list: bool = false) -> rawptr #no_bounds_check {
	assert(alloc.free_idx == NOT_FREE)

	old_memory := mem.ptr_offset(alloc, 1)

	old_block_count := _get_block_count(alloc^)
	new_block_count := u16(
		max(MINIMUM_BLOCK_COUNT, _round_up_to_nearest(new_size, BLOCK_SIZE) / BLOCK_SIZE),
	)
	if new_block_count < old_block_count {
		if new_block_count - old_block_count >= MINIMUM_BLOCK_COUNT {
			_region_find_and_assign_local(alloc)
			_region_segment(_local_region, alloc, new_block_count, alloc.free_idx)
			new_block_count = _get_block_count(alloc^)
			sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)
		}
		// need to zero anything within the new block that that lies beyond new_size
		extra_bytes := int(new_block_count * BLOCK_SIZE) - new_size
		extra_bytes_ptr := mem.ptr_offset((^u8)(alloc), new_size + BLOCK_SIZE)
		mem.zero(extra_bytes_ptr, extra_bytes)
		return old_memory
	}

	if !alloc_is_free_list {
		_region_find_and_assign_local(alloc)
	}
	defer if !alloc_is_free_list {
		sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)
	}
	
	// First, let's see if we can grow in place.
	if alloc.next != BLOCKS_PER_REGION - 1 && _local_region.memory[alloc.next].free_idx != NOT_FREE {
		next_alloc := _local_region.memory[alloc.next]
		total_available := old_block_count + _get_block_count(next_alloc) + 1
		if total_available >= new_block_count {
			alloc.next = next_alloc.next
			_local_region.memory[alloc.next].prev = alloc.idx
			if total_available - new_block_count > BLOCK_SEGMENT_THRESHOLD {
				_region_segment(_local_region, alloc, new_block_count, next_alloc.free_idx)
			} else {
				_region_free_list_remove(_local_region, next_alloc.free_idx)
			}
			mem.zero(&_local_region.memory[next_alloc.idx], int(alloc.next - next_alloc.idx) * BLOCK_SIZE)
			_local_region.hdr.last_used = max(alloc.next, _local_region.hdr.last_used)
			_local_region.hdr.free_blocks -= (_get_block_count(alloc^) - old_block_count)
			if alloc_is_free_list {
				_region_assign_free_list(_local_region, old_memory, _get_block_count(alloc^))
			}
			return old_memory
		}
	}

	// If we made it this far, we need to resize, copy, zero and free.
	region_iter := _local_region
	local_region_idx := _region_get_local_idx()
	back_idx := -1
	idx: u16
	infinite: for {
		for i := 0; i < len(region_iter.hdr.free_list); i += 1 {
			idx = region_iter.hdr.free_list[i]
			if _get_block_count(region_iter.memory[idx]) >= new_block_count {
				break infinite
			}
		}
		if region_iter != _local_region {
			sync.atomic_store_explicit(
				&region_iter.hdr.local_addr,
				region_iter.hdr.reset_addr,
				.Release,
			)
		}
		region_iter, back_idx = _region_retrieve_with_space(new_block_count, local_region_idx, back_idx)
	}
	if region_iter != _local_region {
		sync.atomic_store_explicit(
			&region_iter.hdr.local_addr,
			region_iter.hdr.reset_addr,
			.Release,
		)
	}

	// copy from old memory
	new_memory, used_blocks := _region_get_block(region_iter, idx, new_block_count)
	mem.copy(new_memory, old_memory, int(old_block_count * BLOCK_SIZE))

	// zero any new memory
	addon_section := mem.ptr_offset((^Allocation_Header)(new_memory), old_block_count)
	new_blocks := used_blocks - old_block_count
	mem.zero(addon_section, int(new_blocks) * BLOCK_SIZE)

	region_iter.hdr.free_blocks -= (used_blocks + 1)

	// Set free_list before freeing.
	if alloc_is_free_list {
		_region_assign_free_list(_local_region, new_memory, used_blocks)
	}

	// free old memory
	_region_local_free(alloc)
	return new_memory
}

_region_local_free :: proc(alloc: ^Allocation_Header) #no_bounds_check {
	alloc := alloc
	add_to_free_list := true

	idx := sync.atomic_load(&alloc.idx)
	prev := sync.atomic_load(&alloc.prev)
	next := sync.atomic_load(&alloc.next)
	block_count := next - idx - 1
	free_blocks := sync.atomic_load(&_local_region.hdr.free_blocks) + block_count + 1
	sync.atomic_store_explicit(&_local_region.hdr.free_blocks, free_blocks, .Release)

	// try to merge with prev
	if idx > 0 && sync.atomic_load(&_local_region.memory[prev].free_idx) != NOT_FREE {
		sync.atomic_store_explicit(&_local_region.memory[prev].next, next, .Release)
		_local_region.memory[next].prev = prev
		alloc = &_local_region.memory[prev]
		add_to_free_list = false
	}

	// try to merge with next
	if next < BLOCKS_PER_REGION - 1 && sync.atomic_load(&_local_region.memory[next].free_idx) != NOT_FREE {
		old_next := next
		sync.atomic_store_explicit(&alloc.next, sync.atomic_load(&_local_region.memory[old_next].next), .Release)

		sync.atomic_store_explicit(&_local_region.memory[next].prev, idx, .Release)

		if add_to_free_list {
		        sync.atomic_store_explicit(&_local_region.hdr.free_list[_local_region.memory[old_next].free_idx], idx, .Release)
		        sync.atomic_store_explicit(&alloc.free_idx, _local_region.memory[old_next].free_idx, .Release)
		} else {
			// NOTE: We have aleady merged with prev, and now merged with next.
			//       Now, we are actually going to remove from the free_list.
			_region_free_list_remove(_local_region, _local_region.memory[old_next].free_idx)
		}
		add_to_free_list = false
	}

	// This is the only place where anything is appended to the free list.
	if add_to_free_list {
		fl := _local_region.hdr.free_list
		fl_len := sync.atomic_load(&_local_region.hdr.free_list_len)
		sync.atomic_store_explicit(&alloc.free_idx, fl_len, .Release)
		fl[alloc.free_idx] = idx
		sync.atomic_store_explicit(&_local_region.hdr.free_list_len, fl_len + 1, .Release)
		if int(fl_len + 1) == len(fl) {
			free_alloc := _get_allocation_header(mem.raw_data(_local_region.hdr.free_list))
			_region_resize(free_alloc, len(fl) * 2 * size_of(fl[0]), true)
		}
	}
}

_region_assign_free_list :: proc(region: ^Region, memory: rawptr, blocks: u16) {
	raw_free_list := transmute(mem.Raw_Slice)region.hdr.free_list
	raw_free_list.len = int(blocks) * FREE_LIST_ENTRIES_PER_BLOCK
	raw_free_list.data = memory
	region.hdr.free_list = transmute([]u16)(raw_free_list)
}

_region_retrieve_with_space :: proc(blocks: u16, local_idx: int = -1, back_idx: int = -1) -> (^Region, int) {
	r: ^Region
	idx: int
	for r = sync.atomic_load(&global_regions); r != nil; r = r.hdr.next_region {
		if idx == local_idx || idx < back_idx || sync.atomic_load(&r.hdr.free_blocks) < blocks {
			idx += 1
			continue
		}
		idx += 1
		local_addr: ^^Region = sync.atomic_load(&r.hdr.local_addr)
		if local_addr != CURRENTLY_ACTIVE {
			res := sync.atomic_compare_exchange_strong_explicit(
				&r.hdr.local_addr,
				local_addr,
				CURRENTLY_ACTIVE,
				.Acquire,
				.Relaxed,
			)
			if res == local_addr {
				r.hdr.reset_addr = local_addr
				return r, idx
			}
		}
	}

	return _new_region(), idx
}

_region_retrieve_from_addr :: proc(addr: rawptr) -> ^Region {
	r: ^Region
	for r = global_regions; r != nil; r = r.hdr.next_region {
		if _region_contains_mem(r, addr) {
			return r
		}
	}
	unreachable()
}

_region_get_block :: proc(region: ^Region, idx, blocks_needed: u16) -> (rawptr, u16) #no_bounds_check {
	alloc := &region.memory[idx]

	assert(alloc.free_idx != NOT_FREE)
	assert(alloc.next > 0)

	block_count := _get_block_count(alloc^)
	if block_count - blocks_needed > BLOCK_SEGMENT_THRESHOLD {
		_region_segment(region, alloc, blocks_needed, alloc.free_idx)
	} else {
		_region_free_list_remove(region, alloc.free_idx)
	}

	alloc.free_idx = NOT_FREE
	return mem.ptr_offset(alloc, 1), _get_block_count(alloc^)
}

_region_segment :: proc(region: ^Region, alloc: ^Allocation_Header, blocks, new_free_idx: u16) #no_bounds_check {
	old_next := alloc.next
	alloc.next = alloc.idx + blocks + 1
	region.memory[old_next].prev = alloc.next

	// Initialize alloc.next allocation header here.
	region.memory[alloc.next].prev = alloc.idx
	region.memory[alloc.next].next = old_next
	region.memory[alloc.next].idx = alloc.next
	region.memory[alloc.next].free_idx = new_free_idx

	// Replace our original spot in the free_list with new segment.
	region.hdr.free_list[new_free_idx] = alloc.next
}

_region_get_local_idx :: proc() -> int {
	idx: int
	for r := sync.atomic_load(&global_regions); r != nil; r = r.hdr.next_region {
		if r == _local_region {
			return idx
		}
		idx += 1
	}

	return -1
}

_region_find_and_assign_local :: proc(alloc: ^Allocation_Header) {
	// Find the region that contains this memory
	if !_region_contains_mem(_local_region, alloc) {
		_local_region = _region_retrieve_from_addr(alloc)
	}

	// At this point, _local_region is set correctly. Spin until acquire
	res := CURRENTLY_ACTIVE

	for res == CURRENTLY_ACTIVE {
		res = sync.atomic_compare_exchange_strong_explicit(
			&_local_region.hdr.local_addr,
			&_local_region,
			CURRENTLY_ACTIVE,
			.Acquire,
			.Relaxed,
		)
	}
}

_region_contains_mem :: proc(r: ^Region, memory: rawptr) -> bool #no_bounds_check {
	if r == nil {
		return false
	}
	mem_int := uintptr(memory)
	return mem_int >= uintptr(&r.memory[0]) && mem_int <= uintptr(&r.memory[BLOCKS_PER_REGION - 1])
}

_region_free_list_remove :: proc(region: ^Region, free_idx: u16) #no_bounds_check {
	// pop, swap and update allocation hdr
	if n := region.hdr.free_list_len - 1; free_idx != n {
		region.hdr.free_list[free_idx] = sync.atomic_load(&region.hdr.free_list[n]) 
		alloc_idx := region.hdr.free_list[free_idx]
		sync.atomic_store_explicit(&region.memory[alloc_idx].free_idx, free_idx, .Release)
	}
	region.hdr.free_list_len -= 1
}

//
// Direct mmap
//
_direct_mmap_alloc :: proc(size: int) -> rawptr {
	mmap_size := _round_up_to_nearest(size + BLOCK_SIZE, PAGE_SIZE)
	new_allocation, errno := linux.mmap(0, uint(mmap_size), MMAP_PROT, MMAP_FLAGS, -1, 0)
	if errno != .NONE {
		return nil
	}

	alloc := (^Allocation_Header)(uintptr(new_allocation))
	alloc.requested = u64(size) // NOTE: requested = requested size
	alloc.requested += IS_DIRECT_MMAP
	return rawptr(mem.ptr_offset(alloc, 1))
}

_direct_mmap_resize :: proc(alloc: ^Allocation_Header, new_size: int) -> rawptr {
	old_requested := int(alloc.requested & REQUESTED_MASK)
	old_mmap_size := _round_up_to_nearest(old_requested + BLOCK_SIZE, PAGE_SIZE)
	new_mmap_size := _round_up_to_nearest(new_size + BLOCK_SIZE, PAGE_SIZE)
	if int(new_mmap_size) < MMAP_TO_REGION_SHRINK_THRESHOLD {
		return _direct_mmap_to_region(alloc, new_size)
	} else if old_requested == new_size {
		return mem.ptr_offset(alloc, 1)
	}

	new_allocation, errno := linux.mremap(alloc, uint(old_mmap_size), uint(new_mmap_size), {.MAYMOVE})
	if errno != .NONE {
		return nil
	}

	new_header := (^Allocation_Header)(uintptr(new_allocation))
	new_header.requested = u64(new_size)
	new_header.requested += IS_DIRECT_MMAP

	if new_mmap_size > old_mmap_size {
		// new section may not be pointer aligned, so cast to ^u8
		new_section := mem.ptr_offset((^u8)(new_header), old_requested + BLOCK_SIZE)
		mem.zero(new_section, new_mmap_size - old_mmap_size)
	}
	return mem.ptr_offset(new_header, 1)

}

_direct_mmap_from_region :: proc(alloc: ^Allocation_Header, new_size: int) -> rawptr {
	new_memory := _direct_mmap_alloc(new_size)
	if new_memory != nil {
		old_memory := mem.ptr_offset(alloc, 1)
		mem.copy(new_memory, old_memory, int(_get_block_count(alloc^)) * BLOCK_SIZE)
	}
	_region_find_and_assign_local(alloc)
	_region_local_free(alloc)
	sync.atomic_store_explicit(&_local_region.hdr.local_addr, &_local_region, .Release)
	return new_memory
}

_direct_mmap_to_region :: proc(alloc: ^Allocation_Header, new_size: int) -> rawptr {
	new_memory := heap_alloc(new_size)
	if new_memory != nil {
		mem.copy(new_memory, mem.ptr_offset(alloc, -1), new_size)
		_direct_mmap_free(alloc)
	}
	return new_memory
}

_direct_mmap_free :: proc(alloc: ^Allocation_Header) {
	requested := int(alloc.requested & REQUESTED_MASK)
	mmap_size := _round_up_to_nearest(requested + BLOCK_SIZE, PAGE_SIZE)
	linux.munmap(alloc, uint(mmap_size))
}

//
// Util
//

_get_block_count :: #force_inline proc(alloc: Allocation_Header) -> u16 {
	return alloc.next - alloc.idx - 1
}

_get_allocation_header :: #force_inline proc(raw_mem: rawptr) -> ^Allocation_Header {
	return mem.ptr_offset((^Allocation_Header)(raw_mem), -1)
}

_round_up_to_nearest :: #force_inline proc(size, round: int) -> int {
	return (size-1) + round - (size-1) % round
}

