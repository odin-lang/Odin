#+vet explicit-allocators
#+private file
package debug_trace

@require import "base:runtime"

when INSTRUMENTATION_MODE {

when ODIN_OPTIMIZATION_MODE == .None {
	#panic("the `trace` package's instrumentation mode requires at least `-o:minimal` to work (it requires `#force_inline` to actually be applied)")
}

when ODIN_USE_SEPARATE_MODULES {
	#panic("the `trace` package's instrumentation mode requires `-use-single-module` to work (there are subtle instrumentation bugs to hunt down)")
}

@(private="package", no_instrumentation)
instrumentation_enter :: #force_inline proc "contextless" (a, b: rawptr, loc: runtime.Source_Code_Location) {
	_instrumentation_enter(a, b, loc)
}

@(private="package", no_instrumentation)
instrumentation_exit :: #force_inline proc "contextless" (a, b: rawptr, loc: runtime.Source_Code_Location) {
	_instrumentation_exit(a, b, loc)
}

@(private="package")
_Capture_Entry :: Location

@(private="package")
_capture :: #force_no_inline proc(buf: Capture, skip: int) -> (n: int) {
	lframe := frame

	// Omit `skip+2` frames. 2 being the current and caller.
	for _ in 0..<skip+2 {
		if lframe != nil { lframe = lframe.prev }
	}

	for lframe != nil && n < len(buf) {
		buf[n] = Capture_Entry(lframe.loc)

		n += 1
		lframe = lframe.prev
	}

	return
}

@(private="package")
_locations_destroy :: proc(locations: []Location, allocator: runtime.Allocator) {
	delete(locations, allocator)
}

@(private="package")
_resolve :: proc(bt: Capture, allocator, temp_allocator: runtime.Allocator) -> (out: []Location, err: Resolve_Error) {
	clone, mem_err := make(Capture, len(bt), allocator)
	if mem_err != nil { return nil, .Allocator_Error }
	for entry, i in bt {
		clone[i] = entry
	}
	return transmute([]Location)clone, nil
}

Frame :: struct {
	prev: ^Frame,
	loc:  runtime.Source_Code_Location,
}

@(thread_local)
frame: ^Frame

when CUSTOM_INSTRUMENTATION {
	@(no_instrumentation)
	_instrumentation_enter :: #force_inline proc "contextless" (_, _: rawptr, loc: runtime.Source_Code_Location) {
		frame = &Frame{
			prev = frame,
			loc  = loc,
		}
	}

	@(no_instrumentation)
	_instrumentation_exit :: #force_inline proc "contextless" (_, _: rawptr, loc: runtime.Source_Code_Location) {
		frame = frame.prev
	}
} else {
	@(instrumentation_enter)
	_instrumentation_enter :: #force_inline proc "contextless" (_, _: rawptr, loc: runtime.Source_Code_Location) {
		frame = &Frame{
			prev = frame,
			loc  = loc,
		}
	}

	@(instrumentation_exit)
	_instrumentation_exit :: #force_inline proc "contextless" (_, _: rawptr, loc: runtime.Source_Code_Location) {
		frame = frame.prev
	}
}
} // INSTRUMENTATION_MODE
