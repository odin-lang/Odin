#+private
package os2

import "core:mem"
import win32 "core:sys/windows"

heap_alloc :: proc(size: int, zero_memory: bool) -> rawptr {
	return win32.HeapAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY if zero_memory else 0, uint(size))
}

heap_resize :: proc(ptr: rawptr, new_size: int, zero_memory: bool) -> rawptr {
	if new_size == 0 {
		heap_free(ptr)
		return nil
	}
	if ptr == nil {
		return heap_alloc(new_size, zero_memory)
	}

	return win32.HeapReAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, ptr, uint(new_size))
}
heap_free :: proc(ptr: rawptr) {
	if ptr == nil {
		return
	}
	win32.HeapFree(win32.GetProcessHeap(), 0, ptr)
}

_heap_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                            size, alignment: int,
                            old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	//
	// NOTE(tetra, 2020-01-14): The heap doesn't respect alignment.
	// Instead, we overallocate by `alignment + size_of(rawptr) - 1`, and insert
	// padding. We also store the original pointer returned by heap_alloc right before
	// the pointer we return to the user.
	//

	aligned_alloc :: proc(size, alignment: int, zero_memory: bool, old_ptr: rawptr = nil) -> ([]byte, mem.Allocator_Error) {
		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_mem: rawptr
		if old_ptr != nil {
			original_old_ptr := mem.ptr_offset((^rawptr)(old_ptr), -1)^
			allocated_mem = heap_resize(original_old_ptr, space+size_of(rawptr), zero_memory)
		} else {
			allocated_mem = heap_alloc(space+size_of(rawptr), zero_memory)
		}
		aligned_mem := rawptr(mem.ptr_offset((^u8)(allocated_mem), size_of(rawptr)))

		ptr := uintptr(aligned_mem)
		aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a)
		diff := int(aligned_ptr - ptr)
		if (size + diff) > space || allocated_mem == nil {
			return nil, .Out_Of_Memory
		}

		aligned_mem = rawptr(aligned_ptr)
		mem.ptr_offset((^rawptr)(aligned_mem), -1)^ = allocated_mem

		return mem.byte_slice(aligned_mem, size), nil
	}

	aligned_free :: proc(p: rawptr) {
		if p != nil {
			heap_free(mem.ptr_offset((^rawptr)(p), -1)^)
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int) -> ([]byte, mem.Allocator_Error) {
		if p == nil {
			return nil, nil
		}
		return aligned_alloc(new_size, new_alignment, true, p)
	}

	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return aligned_alloc(size, alignment, mode == .Alloc)

	case .Free:
		aligned_free(old_memory)

	case .Free_All:
		return nil, .Mode_Not_Implemented

	case .Resize, .Resize_Non_Zeroed:
		if old_memory == nil {
			return aligned_alloc(size, alignment, true)
		}
		return aligned_resize(old_memory, old_size, size, alignment)

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Free, .Resize, .Query_Features}
		}
		return nil, nil

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, nil
}
