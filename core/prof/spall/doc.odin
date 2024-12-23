/*
Example:
	package main

	import "base:runtime"
	import "core:prof/spall"
	import "core:sync"

	spall_ctx: spall.Context
	@(thread_local) spall_buffer: spall.Buffer

	foo :: proc() {
		spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)
	}

	main :: proc() {
		spall_ctx = spall.context_create("trace_test.spall")
		defer spall.context_destroy(&spall_ctx)

		buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
		defer delete(buffer_backing)

		spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
		defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

		spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

		for i := 0; i < 9001; i += 1 {
			foo()
		}
	}

	// Automatic profiling of every procedure:

	@(instrumentation_enter)
	spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
		spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
	}

	@(instrumentation_exit)
	spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
		spall._buffer_end(&spall_ctx, &spall_buffer)
	}
*/
package spall
