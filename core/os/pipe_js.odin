#+build js wasm32, js wasm64p32
#+private
package os

_pipe :: proc() -> (r, w: ^File, err: Error) {
	err = .Unsupported
	return
}

@(require_results)
_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	err = .Unsupported
	return
}
