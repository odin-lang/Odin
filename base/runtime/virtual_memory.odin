package runtime

import "base:intrinsics"

ODIN_VIRTUAL_MEMORY_SUPPORTED :: VIRTUAL_MEMORY_SUPPORTED

/*
The page size of the operating system, used for virtual memory allocations.
*/
page_size: int

/*
The superpage size of the operating system.

This may be zero if unavailable.
*/
superpage_size: int

@(init, private)
init_virtual_memory :: proc "contextless" () {
	_init_virtual_memory()
}

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

The address will be a multiple of `superpage_size`, and the memory
pointed to will be at least as long as that.

The name derives from the superpage concept on the *BSD operating systems,
where it is known as huge pages on Linux and large pages on Windows.

This may return nil if a superpage size was unable to be retrieved from the
operating system or if the feature is otherwise unavailable.
*/
@(require_results)
allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	if superpage_size == 0 {
		return nil
	}
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
	// TODO: There is currently no good way to tell ThreadSanitizer that we're
	// done with a region of memory and to clear any information it has about
	// it, so that when it's enabled, we simply do not release any memory back
	// to the operating system.
	//
	// This prevents all false positive warnings when one thread inevitably
	// gives up some of its memory that is then re-assigned to a different
	// thread by the operating system.
	//
	// This is a workaround for the time being.
	when .Thread not_in ODIN_SANITIZER_FLAGS {
		_free_virtual_memory(ptr, size)
	}
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
