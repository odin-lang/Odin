#+vet explicit-allocators
package debug_trace

import "base:runtime"

import "core:sync"

// Size of a constant backtrace, as used by the tracking allocator for example.
BACKTRACE_SIZE :: #config(ODIN_TRACE_SIZE, 16)

/*
Use the instrumentation based trace mode, instead of debug info based.
This mode has a little bit of runtime performance impact, but is supported on all targets.
*/
INSTRUMENTATION_MODE :: #config(ODIN_TRACE_INSTRUMENTATION_MODE, false)

/*
When using the instrumentation mode, but you also want to use Odin's instrumentation features
for something else. You can define this, and call this package's instrumentation procedures:
`instrumentation_enter`, and `instrumentation_exit`, in your own instrumentation enter/exit procedures.
*/
CUSTOM_INSTRUMENTATION :: #config(ODIN_TRACE_CUSTOM_INSTRUMENTATION, false)

/*
The path/command to invoke for symbolization.
Linux only.
*/
SYMBOLIZER_PROGRAM :: #config(ODIN_TRACE_SYMBOLIZER_PROGRAM, "addr2line")

// The string that is used when allocation failed for a symbol/file path.
OOM_MARKER :: "??OOM"

Capture :: []Capture_Entry

Capture_Const :: struct {
	trace: [BACKTRACE_SIZE]Capture_Entry,
	len:   int,
}

// Platform specific.
Capture_Entry :: distinct _Capture_Entry

/*
Capture a constantly sized trace (defined by `-define:ODIN_TRACE_SIZE`).

The trace starts at the stack frame that called this procedure,
you can start higher up the stack using the `skip` argument.
*/
capture :: #force_no_inline proc(skip := 0) -> (bt: Capture_Const) {
	bt.len = _capture(bt.trace[:], skip)
	return
}

/*
Capture must be deleted by the caller.
*/

/*
Capture a trace of the given size.

The trace starts at the stack frame that called this procedure,
you can start higher up the stack using the `skip` argument.

The capture must be deleted by the caller.
*/
capture_n :: #force_no_inline proc(max_len: i32, skip := 0, allocator := context.allocator) -> Capture {
	bt := make([]Capture_Entry, max_len, allocator)
	n  := _capture(bt[:], skip)
	return bt[:n]
}

/*
Capture a trace into the given preallocated capture buffer (owned by the caller).

The trace starts at the stack frame that called this procedure,
you can start higher up the stack using the `skip` argument.
*/
capture_fill :: #force_no_inline proc(buf: Capture, skip := 0) -> int {
	return _capture(buf, skip)
}

Resolve_Error :: enum {
	None,
	Allocator_Error,
	Parse_Address_Failed,
	Resolve_Aborted,
}

resolve_err_string :: proc(err: Resolve_Error) -> string {
	switch err {
	case .None:                 return "none"
	case .Allocator_Error:      return "allocator error"
	case .Parse_Address_Failed: return "parse address failed"
	case .Resolve_Aborted:      return "resolve aborted"
	case:                       return "unknown"
	}
}

Location :: runtime.Source_Code_Location

/*
Resolve the back trace into source code locations, if possible.

Compile with `-debug` (or use `-define:ODIN_TRACE_INSTRUMENTATION_MODE`) for the most useful information.

The result must be destroyed using `locations_destroy`.
*/
resolve :: proc {
	resolve_n,
	resolve_const,
}

/*
See the procedure group `resolve`.
*/
resolve_n :: proc(bt: Capture, allocator := context.allocator, temp_allocator := context.temp_allocator) -> (out: []Location, err: Resolve_Error) {
	return _resolve(bt, allocator, temp_allocator)
}

/*
See the procedure group `resolve`.
*/
resolve_const :: proc(bt: Capture_Const, allocator := context.allocator, temp_allocator := context.temp_allocator) -> (out: []Location, err: Resolve_Error) {
	bt := bt
	return _resolve(bt.trace[:bt.len], allocator, temp_allocator)
}

locations_destroy :: proc(locations: []Location, allocator := context.allocator) {
	_locations_destroy(locations, allocator)
}

/*
An assertion failure procedure that prints a back trace.

Example:
	context.assertion_failure_proc = trace.assertion_failure_proc
	assert(false)
*/
assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	{
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		lines, err := resolve(capture(skip=1), context.temp_allocator, context.temp_allocator)
		if err != nil {
			runtime.print_string("could not get backtrace for assertion failure: ")
			runtime.print_string(resolve_err_string(err))
			runtime.print_string("\n")
		} else {
			runtime.print_string("[back trace]\n")
			print(lines)
			locations_destroy(lines, context.temp_allocator)
		}
	}

	runtime.default_assertion_failure_proc(prefix, message, loc)
}

/*
Print locations to stderr.

Inputs:
- locations: the result of a `resolve` call.
- padding:   padding to print before each line, defaults to a tab.
*/
print :: proc(locations: []Location, padding := "\t") {
	for location, i in locations {
		runtime.print_string(padding)
		runtime.print_string("#")
		runtime.print_int(i)
		runtime.print_string(" ")
		runtime.print_string(location.procedure)
		runtime.print_string(" at ")
		runtime.print_string(location.file_path)
		if location.line > 0 {
			when ODIN_ERROR_POS_STYLE == .Default {
				runtime.print_string("(")
				runtime.print_i64(i64(location.line))
				if location.column > 0 {
					runtime.print_string(":")
					runtime.print_i64(i64(location.column))
				}
				runtime.print_string(")")
			} else when ODIN_ERROR_POS_STYLE == .Unix {
				runtime.print_string(":")
				runtime.print_i64(i64(location.line))
				if location.column > 0 {
					runtime.print_string(":")
					runtime.print_i64(i64(location.column))
				}
			} else {
				#panic("unhandled ODIN_ERROR_POS_STYLE")
			}
		}

		runtime.print_string("\n")
	}
}

/*
The dbghelp library of win32 is not thread safe, this library uses this mutex to get exclusive access.
It is provided in case you want to use the dbghelp library, and want to coordinate access with this package.
*/
_win32_dbghelp_mutex: sync.Mutex
