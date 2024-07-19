/*
A debug stack trace library. Only works when debug symbols are enabled `-debug`.

Example:
	import "base:runtime"
	import "core:debug/trace"

	import "core:fmt"

	global_trace_ctx: trace.Context

	debug_trace_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! {
		runtime.print_caller_location(loc)
		runtime.print_string(" ")
		runtime.print_string(prefix)
		if len(message) > 0 {
			runtime.print_string(": ")
			runtime.print_string(message)
		}
		runtime.print_byte('\n')

		ctx := &trace_ctx
		if !trace.in_resolve(ctx) {
			buf: [64]trace.Frame
			runtime.print_string("Debug Trace:\n")
			frames := trace.frames(ctx, 1, buf[:])
			for f, i in frames {
				fl := trace.resolve(ctx, f, context.temp_allocator)
				if fl.loc.file_path == "" && fl.loc.line == 0 {
					continue
				}
				runtime.print_caller_location(fl.loc)
				runtime.print_string(" - frame ")
				runtime.print_int(i)
				runtime.print_byte('\n')
			}
		}
		runtime.trap()
	}

	main :: proc() {
		trace.init(&global_trace_ctx)
		defer trace.destroy(&global_trace_ctx)

		context.assertion_failure_proc = debug_trace_assertion_failure_proc

		...
	}

*/
package debug_trace