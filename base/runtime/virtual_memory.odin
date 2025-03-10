package runtime

ODIN_VIRTUAL_MEMORY_SUPPORTED :: VIRTUAL_MEMORY_SUPPORTED

// Virtually all MMUs supported by Odin should have a 4KiB page size.
PAGE_SIZE :: 4 * Kilobyte

when ODIN_ARCH == .arm32 {
	SUPERPAGE_SIZE :: 1 * Megabyte
} else {
	// All other architectures should have support for 2MiB pages.
	// i386 supports it in PAE mode.
	// amd64, arm64, and riscv64 support it by default.
	SUPERPAGE_SIZE :: 2 * Megabyte
}

#assert(SUPERPAGE_SIZE & (SUPERPAGE_SIZE-1) == 0, "SUPERPAGE_SIZE must be a power of two.")

/*
Allocate virtual memory from the operating system.

The address returned is guaranteed to point to data that is at least `size`
bytes large but may be larger, due to rounding `size` to the page size of the
system.
*/
@(require_results)
allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	return _allocate_virtual_memory(size)
}

/*
Allocate a superpage of virtual memory from the operating system.

This is a contiguous block of memory larger than what is normally distributed
by the operating system, sometimes with special performance properties related
to the Translation Lookaside Buffer.

The address will be a multiple of the `SUPERPAGE_SIZE` constant, and the memory
pointed to will be at least as long as that very same constant.

The name derives from the superpage concept on the *BSD operating systems,
where it is known as huge pages on Linux and large pages on Windows.
*/
@(require_results)
allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	return _allocate_virtual_memory_superpage()
}

/*
Allocate virtual memory from the operating system.

The address returned is guaranteed to be a multiple of `alignment` and point to
data that is at least `size` bytes large but may be larger, due to rounding
`size` to the page size of the system.

`alignment` must be a power of two.
*/
@(require_results)
allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	assert_contextless(is_power_of_two(alignment))
	return _allocate_virtual_memory_aligned(size, alignment)
}

/*
Free virtual memory allocated by any of the `allocate_*` procs.
*/
free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	_free_virtual_memory(ptr, size)
}

/*
Resize virtual memory allocated by `allocate_virtual_memory`.

**Caveats:**

- `new_size` must not be zero.
- If `old_size` and `new_size` are the same, nothing happens.
- The resulting behavior is undefined if `old_size` is incorrect.
- If the address is changed, `alignment` will be ensured.
- `alignment` should be the same value used when the memory was allocated.
- Resizing memory returned by `allocate_virtual_memory_superpage` is not
  well-defined. The memory may be resized, but it may no longer be backed by a
  superpage.
*/
@(require_results)
resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int = 0) -> rawptr {
	// * This is due to a restriction of mremap on Linux.
	assert_contextless(new_size != 0, "Cannot resize virtual memory address to zero.")
	// * The statement about undefined behavior of incorrect `old_size` is due to
	//   how VirtualFree works on Windows.
	if old_size == new_size {
		return ptr
	}
	return _resize_virtual_memory(ptr, old_size, new_size, alignment)
}
