#+private
#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package terminal

import "base:runtime"
import "core:os"
import "core:sys/posix"

_is_terminal :: proc "contextless" (handle: os.Handle) -> bool {
	return bool(posix.isatty(posix.FD(handle)))
}

_init_terminal :: proc "contextless" () {
	context = runtime.default_context()
	color_depth = get_environment_color()
}

_fini_terminal :: proc "contextless" () { }
