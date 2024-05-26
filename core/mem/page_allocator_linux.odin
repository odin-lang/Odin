//+private
package mem

import "core:sys/linux"

_PAGE_SIZE                    :: 4 * Kilobyte
_PAGE_ALLOCATOR_MAX_ALIGNMENT :: 1 * Terabyte

// unused
_Page_Allocator_Platform_Data :: uintptr

MMAP_FLAGS   : linux.Map_Flags      : {.ANONYMOUS, .PRIVATE}
MMAP_PROT    : linux.Mem_Protection : {.READ, .WRITE}

_page_allocator_aligned_alloc :: proc(size, alignment: int, flags: Page_Allocator_Flags) -> ([]byte, Allocator_Error) {
	if size == 0 {
		return nil, .Invalid_Argument
	}
	aligned_size      := align_forward_int(size, PAGE_SIZE)
	aligned_alignment := align_forward_int(alignment, PAGE_SIZE)

	mapping_size := aligned_size

	if alignment > PAGE_SIZE {
		// Add extra pages
		mapping_size += aligned_alignment - PAGE_SIZE
	}

	flags: linux.Map_Flags = MMAP_FLAGS

	// 1 GB *huge* page
	if aligned_size >= 1 * Gigabyte || alignment >= 1 * Gigabyte {
		raw_flags : i32 = transmute(i32)(MMAP_FLAGS) | i32(linux.MAP_HUGE_1GB)
		flags = transmute(linux.Map_Flags)(raw_flags)
		flags += {.HUGETLB}
		if ptr, errno := linux.mmap(0, uint(aligned_size), MMAP_PROT, flags); ptr != nil && errno == nil {
			g_last_was_large = true
			g_head_waste = 0
			g_tail_waste = 0
			return byte_slice(ptr, size), nil
		}
	}
	// 2 MB huge page
	if aligned_size >= 2 * Megabyte || alignment >= 2 * Megabyte {
		raw_flags : i32 = transmute(i32)(MMAP_FLAGS) | i32(linux.MAP_HUGE_2MB)
		flags = transmute(linux.Map_Flags)(raw_flags)
		flags += {.HUGETLB}
		if ptr, errno := linux.mmap(0, uint(aligned_size), MMAP_PROT, flags); ptr != nil && errno == nil {
			g_last_was_large = true
			g_head_waste = 0
			g_tail_waste = 0
			return byte_slice(ptr, size), nil
		}
	}
	g_last_was_large = false
	ptr, errno := linux.mmap(0, uint(mapping_size), MMAP_PROT, MMAP_FLAGS)
	if errno != nil || ptr == nil {
		return nil, .Out_Of_Memory
	}

	// If these don't match, we added extra for alignment.
	// Find the correct alignment, and unmap the waste.
	if aligned_size != mapping_size {
		aligned_ptr := align_forward_uintptr(uintptr(ptr), uintptr(aligned_alignment))

		g_head_waste = int(aligned_ptr - uintptr(ptr))
		g_tail_waste = (aligned_alignment - PAGE_SIZE) - g_head_waste
		if g_head_waste > 0 {
			linux.munmap(ptr, uint(g_head_waste))
		}
		if g_tail_waste > 0 {
			linux.munmap(rawptr(aligned_ptr + uintptr(aligned_size)), uint(g_tail_waste))
		}
		ptr = rawptr(aligned_ptr)
	}
	return byte_slice(ptr, size), nil
}

_page_allocator_aligned_resize :: proc(old_ptr: rawptr,
	                               old_size, new_size, new_align: int,
				       flags: Page_Allocator_Flags) -> (new_memory: []byte, err: Allocator_Error) {
	if old_ptr == nil {
		return nil, nil
	}
	if !page_aligned(old_ptr) {
		return nil, .Invalid_Pointer
	}
	new_ptr: rawptr

	new_align := new_align

	aligned_size      := align_forward_int(new_size, PAGE_SIZE)
	aligned_alignment := align_forward_int(new_align, PAGE_SIZE)

	// If we meet all our alignment requirements or we're not allowed to move,
	// we may be able to get away with doing nothing at all or growing in place.
	errno: linux.Errno
	if .Unmovable_Pages in flags || ((uintptr(aligned_alignment) - 1) & uintptr(old_ptr)) == 0 {
		if aligned_size == align_forward_int(old_size, PAGE_SIZE) {
			return byte_slice(old_ptr, old_size), nil
		}
		
		new_ptr, errno = linux.mremap(old_ptr, uint(old_size) , uint(new_size), {.FIXED})
		if new_ptr != nil && errno == nil {
			return byte_slice(new_ptr, new_size), nil
		}
		if .Unmovable_Pages in flags {
			return byte_slice(old_ptr, old_size), .Out_Of_Memory
		}
	}

	// If you want greater than page size alignment (and we failed to expand in place above),
	// send to aligned_alloc, manually copy the conents, and unmap the old mapping.
	if aligned_alignment > PAGE_SIZE {
		new_bytes: []u8
		new_align      = align_forward_int(new_align, PAGE_ALLOCATOR_MAX_ALIGNMENT)
		new_bytes, err = _page_allocator_aligned_alloc(new_size, new_align, flags)
		if new_bytes == nil || err != nil {
			return byte_slice(old_ptr, old_size), err == nil ? .Out_Of_Memory : err
		}

		copy_non_overlapping(&new_bytes[0], old_ptr, old_size)
		linux.munmap(old_ptr, align_forward_uint(uint(old_size), PAGE_SIZE))

		return new_bytes[:new_size], nil
	}

	new_ptr, errno = linux.mremap(old_ptr,
	                              align_forward_uint(uint(old_size), PAGE_SIZE),
	                              uint(aligned_size),
	                              {.MAYMOVE})
	if new_ptr == nil || errno != nil {
		return nil, .Out_Of_Memory
	}
	return byte_slice(new_ptr, new_size), nil
}

_page_allocator_free :: proc(p: rawptr, size: int) -> Allocator_Error {
	if p != nil && size >= 0 && page_aligned(p) && page_aligned(rawptr(uintptr(size))) {
		errno := linux.munmap(p, uint(size))
		return errno == nil ? nil : .Invalid_Pointer
	}
	return .Invalid_Argument
}

_set_system_large_page_count :: proc(count: int) -> (okay: bool) {
	// TODO: write to /proc/sys/vm/nr_hugepages
	return false
}
