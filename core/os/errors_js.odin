#+build js wasm32, js wasm64p32
#+private
package os

// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

_Platform_Error :: enum i32 {}

_error_string :: proc(errno: i32) -> string {
	return "<unknown platform error>"
}

_get_platform_error :: proc(errno: _Platform_Error) -> Error {
	return Platform_Error(errno)
}