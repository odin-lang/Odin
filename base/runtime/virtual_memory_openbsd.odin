#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

SYS_munmap :: uintptr(73)
SYS_mmap   :: uintptr(49)

PROT_READ   :: 0x01
PROT_WRITE  :: 0x02

MAP_PRIVATE   :: 0x0002
MAP_ANONYMOUS :: 0x1000

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
	// NOTE(Feoramund): I am uncertain if OpenBSD has direct support for superpages.
	return 0
}

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	result, ok := intrinsics.syscall_bsd(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if !ok {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	return nil
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	if alignment <= page_size {
		// This is the simplest case.
		//
		// By virtue of binary arithmetic, any address aligned to a power of
		// two is necessarily aligned to all lesser powers of two, and because
		// mmap returns page-aligned addresses, we don't have to do anything
		// extra here.
		result, ok := intrinsics.syscall_bsd(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
		if !ok {
			return nil
		}
		return cast(rawptr)result
	}
	// We must over-allocate then adjust the address.
	mmap_result, ok := intrinsics.syscall_bsd(SYS_mmap, 0, uintptr(size + alignment), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if !ok {
		return nil
	}
	assert_contextless(mmap_result % uintptr(page_size) == 0)
	modulo := mmap_result & uintptr(alignment-1)
	if modulo != 0 {
		// The address is misaligned, so we must return an adjusted address
		// and free the pages we don't need.
		delta := uintptr(alignment) - modulo
		adjusted_result := mmap_result + delta

		// Sanity-checking:
		// - The adjusted address is still page-aligned, so it is a valid argument for munmap.
		// - The adjusted address is aligned to the user's needs.
		assert_contextless(adjusted_result % uintptr(page_size) == 0)
		assert_contextless(adjusted_result % uintptr(alignment) == 0)

		// Round the delta to a multiple of the page size.
		delta = delta / uintptr(page_size) * uintptr(page_size)
		if delta > 0 {
			// Unmap the pages we don't need.
			intrinsics.syscall_bsd(SYS_munmap, mmap_result, delta)
		}

		return rawptr(adjusted_result)
	} else if size + alignment > page_size {
		// The address is coincidentally aligned as desired, but we have space
		// that will never be seen by the user, so we must free the backing
		// pages for it.
		start := size / page_size * page_size
		if size % page_size != 0 {
			start += page_size
		}
		length := size + alignment - start
		if length > 0 {
			intrinsics.syscall_bsd(SYS_munmap, mmap_result + uintptr(start), uintptr(length))
		}
	}
	return rawptr(mmap_result)
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	intrinsics.syscall_bsd(SYS_munmap, uintptr(ptr), uintptr(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	// OpenBSD does not have a mremap syscall.
	// All we can do is mmap a new address, copy the data, and munmap the old.
	result: rawptr = ---
	if alignment == 0 {
		result = _allocate_virtual_memory(new_size)
	} else {
		result = _allocate_virtual_memory_aligned(new_size, alignment)
	}
	intrinsics.mem_copy_non_overlapping(result, ptr, min(new_size, old_size))
	intrinsics.syscall_bsd(SYS_munmap, uintptr(ptr), uintptr(old_size))
	return result
}
