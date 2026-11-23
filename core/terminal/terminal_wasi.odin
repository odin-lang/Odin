#+private
#+build wasi
package terminal

import "base:runtime"
import "core:os"

_is_terminal :: proc "contextless" (f: ^os.File) -> bool {
	return os.is_tty(f)
}

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	return 0, 0, false
}

_init_terminal :: proc "contextless" () {
	context = runtime.default_context()
	color_depth = get_environment_color()
	is_dumb     = get_is_dumb()
}

_fini_terminal :: proc "contextless" () { }
