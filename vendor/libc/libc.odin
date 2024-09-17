package odin_libc

import "base:runtime"

import "core:mem"

@(private)
g_ctx: runtime.Context
@(private)
g_allocator: mem.Compat_Allocator

@(init)
init_context :: proc() {
	g_ctx = context

	// Wrapping the allocator with the mem.Compat_Allocator so we can
	// mimic the realloc semantics.
	mem.compat_allocator_init(&g_allocator, g_ctx.allocator)
	g_ctx.allocator = mem.compat_allocator(&g_allocator)
}

// NOTE: the allocator must respect an `old_size` of `-1` on resizes!
set_context :: proc(ctx := context) {
	g_ctx = ctx
}
