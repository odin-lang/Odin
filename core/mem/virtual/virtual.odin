package virtual

import "core:mem"
import "core:os"


enclosing_page :: proc(ptr: rawptr) -> []byte {
	page_size := os.get_page_size();
	start := cast(^byte) mem.align_backward(ptr, uintptr(page_size));
	return mem.slice_ptr(start, page_size);
}

next_page :: proc(page: []byte) -> []byte {
	page_size := os.get_page_size();
	ptr := mem.align_forward(&page[0], uintptr(page_size));
	return mem.slice_ptr(cast(^byte) ptr, page_size);
}

previous_page :: proc(page: []byte) -> []byte {
	page_size := os.get_page_size();
	ptr := mem.align_backward(&page[0], uintptr(page_size));
	return mem.slice_ptr(cast(^byte) ptr, page_size);
}