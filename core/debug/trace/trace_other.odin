#+build !linux
#+build !darwin
#+build !windows
#+private file
#+vet explicit-allocators
package debug_trace

@(require) import "base:runtime"

when !INSTRUMENTATION_MODE {

@(private="package")
_Capture_Entry :: struct {}

@(private="package")
_capture :: #force_no_inline proc(buf: Capture, skip: int) -> (n: int) {
	return
}

@(private="package")
_locations_destroy :: proc(locations: []Location, allocator: runtime.Allocator) {}

@(private="package")
_resolve :: proc(bt: Capture, allocator, temp_allocator: runtime.Allocator) -> (locations: []Location, err: Resolve_Error) {
	return
}

} // INSTRUMENTATION_MODE
