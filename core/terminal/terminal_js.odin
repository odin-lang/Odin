#+private
#+build js
package terminal

import "core:os"

_is_terminal :: proc(handle: os.Handle) -> bool {
	return true
}

_init_terminal :: proc() {
	color_depth = .None
}

_fini_terminal :: proc() { }