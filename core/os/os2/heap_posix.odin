//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:intrinsics"

import "core:mem"
import "core:sys/posix"


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
		assert(size > 0)

		a := max(alignment, align_of(rawptr))
		space := size + a - 1

		allocated_mem: rawptr
		if old_ptr != nil {
			original_old_ptr := mem.ptr_offset((^rawptr)(old_ptr), -1)^
			allocated_mem = posix.realloc(original_old_ptr, uint(space)+size_of(rawptr))
		} else if zero_memory {
			allocated_mem = posix.calloc(1, uint(space)+size_of(rawptr))
		} else {
			allocated_mem = posix.malloc(uint(space)+size_of(rawptr))
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
			posix.free(mem.ptr_offset((^rawptr)(p), -1)^)
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int, zero_memory: bool) -> (new_memory: []byte, err: mem.Allocator_Error) {
		assert(p != nil)

		new_memory = aligned_alloc(new_size, new_alignment, false, p) or_return

		if zero_memory && new_size > old_size {
			new_region := raw_data(new_memory[old_size:])
			intrinsics.mem_zero(new_region, new_size - old_size)
		}
		return
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
			return aligned_alloc(size, alignment, mode == .Resize)
		}
		return aligned_resize(old_memory, old_size, size, alignment, mode == .Resize)

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
