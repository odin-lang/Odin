/*
Captures and resolves stack traces for debugging purpose.

Debug info based support is implemented for Windows, MacOS, and Linux.

Other targets can use the instrumentation based mode, which uses Odin's instrumentation
features to trace, with some runtime overhead.
Opt in with `-define:ODIN_TRACE_INSTRUMENTATION_MODE=true`.

Example:
	package main

	import "core:debug/trace"
	import "core:fmt"

	main :: proc() {
		track: trace.Tracking_Allocator
		trace.tracking_allocator_init(&track, context.allocator)
		defer trace.tracking_allocator_destroy(&track)

		context.allocator = trace.tracking_allocator(&track)
		defer trace.tracking_allocator_print_results(&track)

		context.assertion_failure_proc = trace.assertion_failure_proc

		_main()
	}

	_main :: proc() {
		// Uncomment to try tracking allocator.
		// for _ in 0..<5 {
		// 	_ = new(int)
		// 	free(rawptr(uintptr(100)))
		// }

		// Uncomment to try assertion failure handling.
		// assert(false)

		capture := trace.capture()
		locations, err := trace.resolve(capture)
		if err != nil { fmt.eprintfln("trace error: %v", err) }
		defer trace.locations_destroy(locations)
		trace.print(locations)
	}
*/
package debug_trace
