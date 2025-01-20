#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

when ODIN_ARCH == .amd64 {
	SYS_mmap    :: uintptr(9)
	SYS_munmap  :: uintptr(11)
	SYS_mremap  :: uintptr(25)
} else when ODIN_ARCH == .arm32 {
	SYS_mmap    :: uintptr(90)
	SYS_munmap  :: uintptr(91)
	SYS_mremap  :: uintptr(163)
} else when ODIN_ARCH == .arm64 {
	SYS_mmap    :: uintptr(222)
	SYS_munmap  :: uintptr(215)
	SYS_mremap  :: uintptr(216)
} else when ODIN_ARCH == .i386 {
	SYS_mmap    :: uintptr(90)
	SYS_munmap  :: uintptr(91)
	SYS_mremap  :: uintptr(163)
} else when ODIN_ARCH == .riscv64 {
	SYS_mmap    :: uintptr(222)
	SYS_munmap  :: uintptr(215)
	SYS_mremap  :: uintptr(216)
} else {
	#panic("Syscall numbers related to virtual memory are missing for this Linux architecture.")
}

PROT_READ      :: 0x01
PROT_WRITE     :: 0x02

MAP_PRIVATE    :: 0x02
MAP_ANONYMOUS  :: 0x20

MREMAP_MAYMOVE :: 0x01

ENOMEM         :: ~uintptr(11)

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	result := intrinsics.syscall(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if int(result) < 0 {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	// This depends on Transparent HugePage Support being enabled.
	result := intrinsics.syscall(SYS_mmap, 0, SUPERPAGE_SIZE, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if int(result) < 0 {
		return nil
	}
	if uintptr(result) % SUPERPAGE_SIZE != 0 {
		// If THP support is not enabled, we may receive an address aligned to a
		// page boundary instead, in which case, we must manually align a new
		// address.
		_free_virtual_memory(rawptr(result), SUPERPAGE_SIZE)
		return _allocate_virtual_memory_aligned(SUPERPAGE_SIZE, SUPERPAGE_SIZE)
	}
	return rawptr(result)
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	if alignment <= PAGE_SIZE {
		// This is the simplest case.
		//
		// By virtue of binary arithmetic, any address aligned to a power of
		// two is necessarily aligned to all lesser powers of two, and because
		// mmap returns page-aligned addresses, we don't have to do anything
		// extra here.
		result := intrinsics.syscall(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
		if int(result) < 0 {
			return nil
		}
		return rawptr(result)
	}
	// We must over-allocate then adjust the address.
	mmap_result := intrinsics.syscall(SYS_mmap, 0, uintptr(size + alignment), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if int(mmap_result) < 0 {
		return nil
	}
	assert_contextless(mmap_result % PAGE_SIZE == 0)
	modulo := mmap_result & uintptr(alignment-1)
	if modulo != 0 {
		// The address is misaligned, so we must return an adjusted address
		// and free the pages we don't need.
		delta := uintptr(alignment) - modulo
		adjusted_result := mmap_result + delta

		// Sanity-checking:
		// - The adjusted address is still page-aligned, so it is a valid argument for mremap and munmap.
		// - The adjusted address is aligned to the user's needs.
		assert_contextless(adjusted_result % PAGE_SIZE == 0)
		assert_contextless(adjusted_result % uintptr(alignment) == 0)

		// Round the delta to a multiple of the page size.
		delta = delta / PAGE_SIZE * PAGE_SIZE
		if delta > 0 {
			// Unmap the pages we don't need.
			intrinsics.syscall(SYS_munmap, mmap_result, delta)
		}

		return rawptr(adjusted_result)
	} else if size + alignment > PAGE_SIZE {
		// The address is coincidentally aligned as desired, but we have space
		// that will never be seen by the user, so we must free the backing
		// pages for it.
		start := size / PAGE_SIZE * PAGE_SIZE
		if size % PAGE_SIZE != 0 {
			start += PAGE_SIZE
		}
		length := size + alignment - start
		if length > 0 {
			intrinsics.syscall(SYS_munmap, mmap_result + uintptr(start), uintptr(length))
		}
	}
	return rawptr(mmap_result)
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	intrinsics.syscall(SYS_munmap, uintptr(ptr), uintptr(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	if alignment == 0 {
		// The user does not care about alignment, which is the simpler case.
		result := intrinsics.syscall(SYS_mremap, uintptr(ptr), uintptr(old_size), uintptr(new_size), MREMAP_MAYMOVE)
		if int(result) < 0 {
			return nil
		}
		return rawptr(result)
	} else {
		// First, let's try to mremap without MREMAP_MAYMOVE. We might get
		// lucky and the operating system could expand (or shrink, as the case
		// may be) the pages in place, which means we don't have to allocate a
		// whole new chunk of memory.
		mremap_result := intrinsics.syscall(SYS_mremap, uintptr(ptr), uintptr(old_size), uintptr(new_size), 0)
		if mremap_result != ENOMEM {
			// We got lucky.
			return rawptr(mremap_result)
		}

		// mremap failed to resize the memory in place, which means we must
		// allocate an entirely new aligned chunk of memory, copy the old data,
		// and free the old pointer before returning the new one.
		//
		// This is costly but unavoidable with the API available to us.
		result := _allocate_virtual_memory_aligned(new_size, alignment)
		intrinsics.mem_copy_non_overlapping(result, ptr, min(new_size, old_size))
		_free_virtual_memory(ptr, old_size)
		return result
	}
}
