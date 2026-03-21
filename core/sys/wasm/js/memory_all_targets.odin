#+build !js
package wasm_js_interface

import "base:runtime"

PAGE_SIZE :: 64 * 1024
page_alloc :: proc(page_count: int) -> (data: []byte, err: runtime.Allocator_Error) {
	panic("vendor:wasm/js not supported on non-js targets")
}

page_allocator :: proc() -> runtime.Allocator {
	panic("vendor:wasm/js not supported on non-js targets")
}

