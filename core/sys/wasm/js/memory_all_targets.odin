#+build !js
package wasm_js_interface

import "core:mem"

PAGE_SIZE :: 64 * 1024
page_alloc :: proc(page_count: int) -> (data: []byte, err: mem.Allocator_Error) {
	panic("vendor:wasm/js not supported on non-js targets")
}

page_allocator :: proc() -> mem.Allocator {
	panic("vendor:wasm/js not supported on non-js targets")
}

