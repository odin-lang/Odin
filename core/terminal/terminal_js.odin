#+private
#+build js
package terminal

_is_terminal :: proc "contextless" (handle: any) -> bool {
	return true
}

_init_terminal :: proc "contextless" () {
	color_depth = .None
}

_fini_terminal :: proc "contextless" () { }