#+private
#+build wasm32, wasm64p32
package sync

_current_thread_id :: proc "contextless" () -> int {
	// TODO(bill): _current_thread_id for wasm32
	return 0
}