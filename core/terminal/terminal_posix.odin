#+private
#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package terminal

import    "base:runtime"
import os "core:os/os2"

_is_terminal :: proc "contextless" (f: ^os.File) -> bool {
	return os.is_tty(f)
}

_init_terminal :: proc "contextless" () {
	context = runtime.default_context()
	color_depth = get_environment_color()
}

_fini_terminal :: proc "contextless" () { }
