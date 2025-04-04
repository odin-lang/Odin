#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

SYS_munmap :: uintptr(73)
SYS_mmap   :: uintptr(197)
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

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	result, ok := intrinsics.syscall_bsd(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if !ok {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	// NOTE(Feoramund): I am uncertain if NetBSD has direct support for
	// superpages, so we just use the aligned allocate procedure here.
	return _allocate_virtual_memory_aligned(SUPERPAGE_SIZE, SUPERPAGE_SIZE)
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	// NOTE: Unlike FreeBSD, the NetBSD man pages do not indicate that
	// `MAP_ALIGNED` can cause this to fail, so we don't try a second time with
	// manual alignment.
	map_aligned_n := intrinsics.count_trailing_zeros(uintptr(alignment)) << MAP_ALIGNMENT_SHIFT
	result, ok := intrinsics.syscall_bsd(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE|map_aligned_n, ~uintptr(0), 0)
	if !ok {
		return nil
	}
	return rawptr(result)
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	intrinsics.syscall_bsd(SYS_munmap, uintptr(ptr), uintptr(size))
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	if alignment == 0 {
		// The user does not care about alignment, which is the simpler case.
		result, ok := intrinsics.syscall_bsd(SYS_mremap, uintptr(ptr), uintptr(old_size), uintptr(new_size), 0)
		if !ok {
			return nil
		}
		return rawptr(result)
	} else {
		map_aligned_n := intrinsics.count_trailing_zeros(uintptr(alignment)) << MAP_ALIGNMENT_SHIFT
		result, ok := intrinsics.syscall_bsd(SYS_mremap, uintptr(ptr), uintptr(old_size), uintptr(new_size), map_aligned_n)
		if !ok {
			return nil
		}
		return rawptr(result)
	}
}
