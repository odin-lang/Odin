package runtime

import "base:intrinsics"

heap_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	}
}

heap_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	//
	// NOTE(tetra, 2020-01-14): The heap doesn't respect alignment.
	// Instead, we overallocate by `alignment + size_of(rawptr) - 1`, and insert
	// padding. We also store the original pointer returned by heap_alloc right before
	// the pointer we return to the user.
	//

	aligned_alloc :: proc(size, alignment: int, old_ptr: rawptr = nil, zero_memory := true) -> ([]byte, Allocator_Error) {
		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_mem: rawptr
		if old_ptr != nil {
			original_old_ptr := ([^]rawptr)(old_ptr)[-1]
			allocated_mem = heap_resize(original_old_ptr, space+size_of(rawptr))
		} else {
			allocated_mem = heap_alloc(space+size_of(rawptr), zero_memory)
		}
		aligned_mem := rawptr(([^]u8)(allocated_mem)[size_of(rawptr):])

		ptr := uintptr(aligned_mem)
		aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a)
		diff := int(aligned_ptr - ptr)
		if (size + diff) > space || allocated_mem == nil {
			return nil, .Out_Of_Memory
		}

		aligned_mem = rawptr(aligned_ptr)
		([^]rawptr)(aligned_mem)[-1] = allocated_mem

		return byte_slice(aligned_mem, size), nil
	}

	aligned_free :: proc(p: rawptr) {
		if p != nil {
			heap_free(([^]rawptr)(p)[-1])
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int, zero_memory := true) -> (new_memory: []byte, err: Allocator_Error) {
		if p == nil {
			return nil, nil
		}

		new_memory = aligned_alloc(new_size, new_alignment, p, zero_memory) or_return

		// NOTE: heap_resize does not zero the new memory, so we do it
		if zero_memory && new_size > old_size {
			new_region := raw_data(new_memory[old_size:])
			intrinsics.mem_zero(new_region, new_size - old_size)
		}
		return
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return aligned_alloc(size, alignment, nil, mode == .Alloc)

	case .Free:
		aligned_free(old_memory)

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return aligned_alloc(size, alignment, nil, mode == .Resize)
		}
		return aligned_resize(old_memory, old_size, size, alignment, mode == .Resize)

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


heap_alloc :: proc "contextless" (size: int, zero_memory := true) -> rawptr {
	return _heap_alloc(size, zero_memory)
}

heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
	return _heap_resize(ptr, new_size)
}

heap_free :: proc "contextless" (ptr: rawptr) {
	_heap_free(ptr)
}