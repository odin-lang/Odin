#+build js wasm32, js wasm64p32
#+private
package os

// None of this does anything on js/wasm.
// It's only here so importing `core:os` on wasm panics cleanly,
// without spamming about all sorts of missing procs and types.

import "base:runtime"

build_env :: proc() -> (err: Error) {
	return
}

@(require_results)
_lookup_env_alloc :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	return
}

_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, error: Error) {
	return "", .Unsupported
}
_lookup_env :: proc{_lookup_env_alloc, _lookup_env_buf}

@(require_results)
_set_env :: proc(key, value: string) -> (err: Error) {
	return .Unsupported
}

@(require_results)
_unset_env :: proc(key: string) -> bool {
	return true
}

_clear_env :: proc() {

}

@(require_results)
_environ :: proc(allocator: runtime.Allocator) -> (environ: []string, err: Error) {
	return {}, .Unsupported
}