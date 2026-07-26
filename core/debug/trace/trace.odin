#+vet explicit-allocators
package debug_trace

import "base:runtime"

import "core:fmt"
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
			fmt.eprintfln("could not get backtrace for assertion failure: %v", err)
		} else {
			fmt.eprintfln("[back trace]")
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
		fmt.eprintf("%s#%v %v at %v", padding, i, location.procedure, location.file_path)
		if location.line > 0 {
			when ODIN_ERROR_POS_STYLE == .Default {
				fmt.eprintf("(%v", location.line)
				if location.column > 0 {
					fmt.eprintf(":%v)", location.column)
				} else {
					fmt.eprint(")")
				}
			} else when ODIN_ERROR_POS_STYLE == .Unix {
				fmt.eprintf(":%v", location.line)
				if location.column > 0 {
					fmt.eprintf(":%v", location.column)
				}
			} else {
				#panic("unhandled ODIN_ERROR_POS_STYLE")
			}
		}

		fmt.eprintln()
	}
}

/*
The dbghelp library of win32 is not thread safe, this library uses this mutex to get exclusive access.
It is provided in case you want to use the dbghelp library, and want to coordinate access with this package.
*/
_win32_dbghelp_mutex: sync.Mutex
