#+private
package runtime

import "base:intrinsics"

VIRTUAL_MEMORY_SUPPORTED :: true

when ODIN_ARCH == .amd64 {
	SYS_open   :: uintptr(2)
	SYS_read   :: uintptr(0)
	SYS_close  :: uintptr(3)

	SYS_mmap   :: uintptr(9)
	SYS_munmap :: uintptr(11)
	SYS_mremap :: uintptr(25)
} else when ODIN_ARCH == .arm32 {
	SYS_open   :: uintptr(5)
	SYS_read   :: uintptr(3)
	SYS_close  :: uintptr(6)

	SYS_mmap   :: uintptr(90)
	SYS_munmap :: uintptr(91)
	SYS_mremap :: uintptr(163)
} else when ODIN_ARCH == .arm64 {
	SYS_openat :: uintptr(56)
	SYS_read   :: uintptr(63)
	SYS_close  :: uintptr(57)

	SYS_mmap   :: uintptr(222)
	SYS_munmap :: uintptr(215)
	SYS_mremap :: uintptr(216)
} else when ODIN_ARCH == .i386 {
	SYS_open   :: uintptr(5)
	SYS_read   :: uintptr(3)
	SYS_close  :: uintptr(6)

	SYS_mmap   :: uintptr(90)
	SYS_munmap :: uintptr(91)
	SYS_mremap :: uintptr(163)
} else when ODIN_ARCH == .riscv64 {
	SYS_openat :: uintptr(56)
	SYS_read   :: uintptr(63)
	SYS_close  :: uintptr(57)

	SYS_mmap   :: uintptr(222)
	SYS_munmap :: uintptr(215)
	SYS_mremap :: uintptr(216)
} else {
	#panic("Syscall numbers related to virtual memory are missing for this Linux architecture.")
}

PROT_READ      :: 0x01
PROT_WRITE     :: 0x02

MAP_PRIVATE    :: 0x02
MAP_ANONYMOUS  :: 0x20

MREMAP_MAYMOVE :: 0x01

ENOMEM         :: ~uintptr(11)

_init_virtual_memory :: proc "contextless" () {
	page_size = _get_page_size()
	superpage_size = _get_superpage_size()
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
	meminfo: cstring = "/proc/meminfo"

	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		AT_FDCWD :: ~uintptr(99) // -100
		fd := cast(int)intrinsics.syscall(SYS_openat, AT_FDCWD, transmute(uintptr)meminfo, 0 /* flags */, 0 /* mode */)
	} else {
		fd := cast(int)intrinsics.syscall(SYS_open, transmute(uintptr)meminfo, 0 /* flags */, 0 /* mode */)
	}
	if fd < 0 {
		// Error on opening file.
		return 0
	}
	defer intrinsics.syscall(SYS_close, uintptr(fd))

	buf: [4096]u8
	read := cast(int)intrinsics.syscall(SYS_read, cast(uintptr)fd, cast(uintptr)&buf[0], len(buf))
	if read <= 0 {
		// Failed to read anything.
		return 0
	}

	// Parse the file. It's in a format of "KEY:  VALUE\n" with a
	// variable number of spaces after the colon.
	str := buf[:read]
	for len(str) > 0 {
		key, val: []u8
		// Get the key.
		for c, i in str {
			if c == ':' {
				key, str = str[:i], str[1+i:]
				break
			}
		}
		// Trim the spaces.
		for c, i in str {
			if c != ' ' {
				str = str[i:]
				break
			}
		}
		// Get the value.
		for c, i in str {
			if c == '\n' {
				val, str = str[:i], str[1+i:]
				break
			}
		}
		// Break in the event something was parsed incorrectly.
		if len(key) == 0 || len(val) == 0 {
			break
		}

		if string(key) == "Hugepagesize" {
			// The value will be in a format like: 2048 kB
			n, unit: []u8
			for c, i in val {
				if c == ' ' {
					n = val[:i]
					unit = val[1+i:]
					break
				}
			}
			// Convert it to a number.
			bytes := 0
			for c in n {
				bytes *= 10
				bytes += int(c - '0')
			}
			// The man page for `proc_meminfo` does not state if it
			// uses measurements other than "kB" but just to be safe.
			switch string(unit) {
			case "kB": bytes *= Kilobyte
			case "mB": bytes *= Megabyte
			case "gB": bytes *= Gigabyte
			}

			return bytes
		}
	}
	return 0
}

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	result := intrinsics.syscall(SYS_mmap, 0, uintptr(size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if int(result) < 0 {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	// This depends on Transparent HugePage Support being enabled.
	result := intrinsics.syscall(SYS_mmap, 0, uintptr(superpage_size), PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, ~uintptr(0), 0)
	if int(result) < 0 {
		return nil
	}
	if uintptr(result) % uintptr(superpage_size) != 0 {
		// If THP support is not enabled, we may receive an address aligned to a
		// page boundary instead, in which case, we must manually align a new
		// address.
		_free_virtual_memory(rawptr(result), superpage_size)
		return _allocate_virtual_memory_aligned(superpage_size, superpage_size)
	}
	return rawptr(result)
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	if alignment <= page_size {
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
	assert_contextless(mmap_result % uintptr(page_size) == 0)
	modulo := mmap_result & uintptr(alignment-1)
	if modulo != 0 {
		// The address is misaligned, so we must return an adjusted address
		// and free the pages we don't need.
		delta := uintptr(alignment) - modulo
		adjusted_result := mmap_result + delta

		// Sanity-checking:
		// - The adjusted address is still page-aligned, so it is a valid argument for mremap and munmap.
		// - The adjusted address is aligned to the user's needs.
		assert_contextless(adjusted_result % uintptr(page_size) == 0)
		assert_contextless(adjusted_result % uintptr(alignment) == 0)

		// Round the delta to a multiple of the page size.
		delta = delta / uintptr(page_size) * uintptr(page_size)
		if delta > 0 {
			// Unmap the pages we don't need.
			intrinsics.syscall(SYS_munmap, mmap_result, delta)
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
