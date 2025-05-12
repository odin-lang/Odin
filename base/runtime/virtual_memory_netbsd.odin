#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

SYS_munmap :: uintptr(73)
SYS_mremap :: uintptr(411)

PROT_READ   :: 0x01
PROT_WRITE  :: 0x02

MAP_PRIVATE   :: 0x0002
MAP_ANONYMOUS :: 0x1000

// The following features are specific to NetBSD only.
/*
 * Alignment (expressed in log2).  Must be >= log2(PAGE_SIZE) and
 * < # bits in a pointer (32 or 64).
 */
// #define MAP_ALIGNED(n) ((int)((unsigned int)(n) << MAP_ALIGNMENT_SHIFT))
MAP_ALIGNMENT_SHIFT :: 24

_init_virtual_memory :: proc "contextless" () {
	page_size = _get_page_size()
}

_get_page_size :: proc "contextless" () -> int {
	// This is a fallback value if the auxiliary vector does not supply it.
	DEFAULT_PAGE_SIZE :: 4096

	if value, found := _get_auxiliary(.AT_PAGESZ); found {
		return int(value.a_val)
	} else {
		return DEFAULT_PAGE_SIZE
	}
}

_get_superpage_size :: proc "contextless" () -> int {
	// NOTE(Feoramund): I am uncertain if NetBSD has direct support for superpages.
	return 0
}

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	result, ok := __netbsd_sys_mmap(nil, uint(size), PROT_READ|PROT_WRITE, i32(MAP_ANONYMOUS|MAP_PRIVATE), -1, 0, 0)
	if !ok {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	return nil
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	// NOTE: Unlike FreeBSD, the NetBSD man pages do not indicate that
	// `MAP_ALIGNED` can cause this to fail, so we don't try a second time with
	// manual alignment.
	map_aligned_n: u32
	if alignment > page_size {
		map_aligned_n = u32(intrinsics.count_trailing_zeros(uintptr(alignment)) << MAP_ALIGNMENT_SHIFT)
	}
	result, ok := __netbsd_sys_mmap(nil, uint(size), PROT_READ|PROT_WRITE, i32(MAP_ANONYMOUS|MAP_PRIVATE|map_aligned_n), -1, 0, 0)
	if !ok {
		return nil
	}
	return rawptr(result)
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	intrinsics.syscall_bsd(SYS_munmap, uintptr(ptr), uintptr(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	// NetBSD will not abide by `new_size` and `old_size` not being a multiple
	// of the page size when remapping.
	old_size_in_pages := old_size / page_size
	if old_size % page_size != 0 {
		old_size_in_pages += 1
	}
	new_size_in_pages := new_size / page_size
	if new_size % page_size != 0 {
		new_size_in_pages += 1
	}
	old_size_rounded := old_size_in_pages * page_size
	new_size_rounded := new_size_in_pages * page_size

	flags := uintptr(0)
	if alignment > page_size {
		flags = intrinsics.count_trailing_zeros(uintptr(alignment)) << MAP_ALIGNMENT_SHIFT
	}

	if result, ok := intrinsics.syscall_bsd(SYS_mremap, uintptr(ptr), uintptr(old_size_rounded), uintptr(new_size_rounded), 0, flags); ok {
		return rawptr(result)
	}

	// It may not have been possible to extend the old address space.
	// Try to allocate a new mapping and copy the old data.
	new_ptr: rawptr
	if alignment > page_size {
		new_ptr = _allocate_virtual_memory_aligned(new_size, alignment)
	} else {
		new_ptr = _allocate_virtual_memory(new_size)
	}

	if new_ptr == nil {
		// Memory allocation failed.
		return nil
	}

	intrinsics.mem_copy_non_overlapping(new_ptr, ptr, min(old_size, new_size))
	_free_virtual_memory(ptr, old_size)
	return rawptr(new_ptr)
}
