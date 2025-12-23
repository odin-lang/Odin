package runtime

nil_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                           size, alignment: int,
                           old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		return nil, .Out_Of_Memory
	case .Free:
		return nil, .None
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize, .Resize_Non_Zeroed:
		if size == 0 {
			return nil, .None
		}
		return nil, .Out_Of_Memory
	case .Query_Features:
		return nil, .Mode_Not_Implemented
	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}
	return nil, .None
}

// nil_allocator returns an allocator which will return `nil` for any result.
// * `.Alloc`, `.Alloc_Non_Zero`, `.Resize`, `.Resize_Non_Zeroed` will return `nil, .Out_Of_Memory`
// * `.Free` will return `nil, .None`
// * `.Free_All` will return `nil, .Mode_Not_Implemented`
// * `.Query_Features`, `.Query_Info` will return `nil, .Mode_Not_Implemented`
//
// This is extremely useful for creating a dynamic array from a buffer which does not nothing
// on a resize/reserve beyond the originally allocated memory.
@(require_results)
nil_allocator :: proc "contextless" () -> Allocator {
	return Allocator{
		procedure = nil_allocator_proc,
		data = nil,
	}
}


panic_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                             size, alignment: int,
                             old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	switch mode {
	case .Alloc:
		if size > 0 {
			panic("panic allocator, .Alloc called", loc=loc)
		}
	case .Alloc_Non_Zeroed:
		if size > 0 {
			panic("panic allocator, .Alloc_Non_Zeroed called", loc=loc)
		}
	case .Resize:
		if size > 0 {
			panic("panic allocator, .Resize called", loc=loc)
		}
	case .Resize_Non_Zeroed:
		if size > 0 {
			panic("panic allocator, .Alloc_Non_Zeroed called", loc=loc)
		}
	case .Free:
		if old_memory != nil {
			panic("panic allocator, .Free called", loc=loc)
		}
	case .Free_All:
		panic("panic allocator, .Free_All called", loc=loc)

	case .Query_Features:
		set := (^Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = {.Query_Features}
		}
		return nil, nil

	case .Query_Info:
		panic("panic allocator, .Query_Info called", loc=loc)
	}

	return nil, nil
}

// panic_allocator returns an allocator which will panic for any non-zero-sized allocation or `query_info`
//
// This is extremely useful for to check when something does a memory operation when it should not, and thus panic.
@(require_results)
panic_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = panic_allocator_proc,
		data = nil,
	}
}
