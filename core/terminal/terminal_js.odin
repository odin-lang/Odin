#+private
#+build js
package terminal

_is_terminal :: proc "contextless" (handle: any) -> bool {
	return true
}

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	return 0, 0, false
}

_init_terminal :: proc "contextless" () {
	color_depth = .None
	is_dumb     = true
}

_fini_terminal :: proc "contextless" () { }
