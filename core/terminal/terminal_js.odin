#+private
#+build js
package terminal

import "core:os"

_is_terminal :: proc "contextless" (handle: os.Handle) -> bool {
	return true
}

_init_terminal :: proc "contextless" () {
	color_depth = .None
}

_fini_terminal :: proc "contextless" () { }