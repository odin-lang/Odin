//+build wasi
package runtime

default_allocator_proc :: proc(allocator_data: rawptr, mode: Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, Allocator_Error) {
	switch mode {
	case .Alloc:
		return nil, .Out_Of_Memory
	case .Free:
		return nil, .None
	case .Free_All:
		return nil, .Mode_Not_Implemented
	case .Resize:
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

default_allocator :: proc() -> Allocator {
	return Allocator{
		procedure = default_allocator_proc,
		data = nil,
	}
}
