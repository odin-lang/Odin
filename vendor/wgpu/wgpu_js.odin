package wgpu

import "base:runtime"

g_context: runtime.Context

@(private="file", init)
wgpu_init_allocator :: proc() {
	if g_context.allocator.procedure == nil {
		g_context = runtime.default_context()
	}
}

@(private="file", export)
wgpu_alloc :: proc "contextless" (size: i32) -> [^]byte {
	context = g_context
	bytes, err := runtime.mem_alloc(int(size), 16)
	assert(err == nil, "wgpu_alloc failed")
	return raw_data(bytes)
}

@(private="file", export)
wgpu_free :: proc "contextless" (ptr: rawptr) {
	context = g_context
	err := free(ptr)
	assert(err == nil, "wgpu_free failed")
}
