//+build windows
package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	// mem.nil_allocator reimplementation
	default_allocator_proc :: nil_allocator_proc
	default_allocator :: nil_allocator
} else {
	default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
	                                size, alignment: int,
	                                old_memory: rawptr, old_size: int, loc := #caller_location) -> (data: []byte, err: Allocator_Error) {
		switch mode {
		case .Alloc:
			data, err = _windows_default_alloc(size, alignment)

		case .Free:
			_windows_default_free(old_memory)

		case .Free_All:
			return nil, .Mode_Not_Implemented

		case .Resize:
			data, err = _windows_default_resize(old_memory, old_size, size, alignment)

		case .Query_Features:
			set := (^Allocator_Mode_Set)(old_memory)
			if set != nil {
				set^ = {.Alloc, .Free, .Resize, .Query_Features}
			}

		case .Query_Info:
			return nil, .Mode_Not_Implemented
		}

		return
	}

	default_allocator :: proc() -> Allocator {
		return Allocator{
			procedure = default_allocator_proc,
			data = nil,
		}
	}
}