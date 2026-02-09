#+build js wasm32, js wasm64p32
#+private
package os

import "base:runtime"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	return "", .Mode_Not_Implemented
}