#+build orca
package runtime

// This is the libc malloc-based Odin allocator, used as a fallback for
// platforms that do not support virtual memory, superpages, or aligned
// allocation, or for platforms where we would prefer to use the system's
// built-in allocator through the malloc interface.

import "base:intrinsics"

foreign {
	@(link_name="malloc")   _libc_malloc   :: proc "c" (size: uint) -> rawptr ---
	@(link_name="calloc")   _libc_calloc   :: proc "c" (num, size: uint) -> rawptr ---
	@(link_name="free")     _libc_free     :: proc "c" (ptr: rawptr) ---
	@(link_name="realloc")  _libc_realloc  :: proc "c" (ptr: rawptr, size: uint) -> rawptr ---
}

@(require_results)
heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
	if size <= 0 {
		return nil
	}
	if zero_memory {
		return _libc_calloc(1, uint(size))
	} else {
		return _libc_malloc(uint(size))
	}
}

@(require_results)
heap_resize :: proc "contextless" (old_ptr: rawptr, old_size: int, new_size: int, zero_memory: bool = true) -> (new_ptr: rawptr) {
	new_ptr = _libc_realloc(old_ptr, uint(new_size))

	// Section 7.22.3.5.2 of the C17 standard: "The contents of the new object
	// shall be the same as that of the old object prior to deallocation, up to
	// the lesser of the new and old sizes. Any bytes in the new object beyond
	// the size of the old object have indeterminate values."
	//
	// Therefore, we zero the memory ourselves.
	if zero_memory && new_size > old_size {
		intrinsics.mem_zero(rawptr(uintptr(new_ptr) + uintptr(old_size)), new_size - old_size)
	}

	return
}

heap_free :: proc "contextless" (ptr: rawptr) {
	_libc_free(ptr)
}

heap_allocator :: proc() -> Allocator {
	return {
		data      = nil,
		procedure = heap_allocator_proc,
	}
}

heap_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {

	// Because malloc does not support alignment requests, and aligned_alloc
	// has specific requirements for what sizes it supports, this allocator
	// over-allocates by the alignment requested and stores the original
	// pointer behind the address returned to the user.

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		padding := max(alignment, size_of(rawptr))
		ptr := heap_alloc(size + padding, mode == .Alloc)
		if ptr == nil {
			return nil, .Out_Of_Memory
		}
		shift := uintptr(padding) - uintptr(ptr) & uintptr(padding-1)
		aligned_ptr := rawptr(uintptr(ptr) + shift)
		([^]rawptr)(aligned_ptr)[-1] = ptr
		return byte_slice(aligned_ptr, size), nil

	case .Free:
		if old_memory != nil {
			heap_free(([^]rawptr)(old_memory)[-1])
		}

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		new_padding := max(alignment, size_of(rawptr))
		original_ptr := ([^]rawptr)(old_memory)[-1]
		ptr: rawptr

		if alignment > align_of(rawptr) {
			// The alignment is in excess of what malloc/realloc will return
			// for address alignment per the C standard, so we must reallocate
			// manually in order to guarantee alignment for the user.
			//
			// Resizing through realloc simply won't work because it's possible
			// that our target address originally only needed a padding of 8
			// bytes, but if we expand the memory used and the address is moved,
			// we may then need 16 bytes for proper alignment, for example.
			//
			// We'll copy the old data later.
			ptr = heap_alloc(size + new_padding, mode == .Resize)

		} else {
			real_old_size := size_of(rawptr) + old_size
			real_new_size := new_padding + size

			ptr = heap_resize(original_ptr, real_old_size, real_new_size, mode == .Resize)
		}

		shift := uintptr(new_padding) - uintptr(ptr) & uintptr(new_padding-1)
		aligned_ptr := rawptr(uintptr(ptr) + shift)
		([^]rawptr)(aligned_ptr)[-1] = ptr

		if alignment > align_of(rawptr) {
			intrinsics.mem_copy_non_overlapping(aligned_ptr, old_memory, min(size, old_size))
			heap_free(original_ptr)
		}

		return byte_slice(aligned_ptr, size), nil

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Resize_Non_Zeroed, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}
