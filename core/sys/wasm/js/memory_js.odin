#+build js wasm32, js wasm64p32, js wasm64
package wasm_js_interface

import "base:runtime"
import "base:intrinsics"

PAGE_SIZE :: 64 * 1024
page_alloc :: proc(page_count: int) -> (data: []byte, err: runtime.Allocator_Error) {
	prev_page_count := intrinsics.wasm_memory_grow(0, uintptr(page_count))
	if prev_page_count < 0 {
		return nil, .Out_Of_Memory
	}

	ptr := ([^]u8)(uintptr(prev_page_count) * PAGE_SIZE)
	return ptr[:page_count * PAGE_SIZE], nil
}

page_allocator :: proc() -> runtime.Allocator {
	procedure :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode,
	                  size, alignment: int,
	                  old_memory: rawptr, old_size: int,
	                  location := #caller_location) -> ([]byte, runtime.Allocator_Error) {
		switch mode {
		case .Alloc, .Alloc_Non_Zeroed:
			assert(size % PAGE_SIZE == 0)
			return page_alloc(size/PAGE_SIZE)
		case .Resize, .Free, .Free_All, .Query_Info, .Resize_Non_Zeroed:
			return nil, .Mode_Not_Implemented
		case .Query_Features:
			set := (^runtime.Allocator_Mode_Set)(old_memory)
			if set != nil {
				set^ = {.Alloc, .Query_Features}
			}
		}

		return nil, nil
	}

	return {
		procedure = procedure,
		data = nil,
	}
}

