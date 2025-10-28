#+private
#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package terminal

import    "base:runtime"
import os "core:os/os2"
import    "core:sys/posix"

_is_terminal :: proc "contextless" (f: ^os.File) -> bool {
	context = runtime.default_context()
	fd := os.fd(f)
	is_tty := posix.isatty(posix.FD(fd))
	return bool(is_tty)
}

_init_terminal :: proc "contextless" () {
	context = runtime.default_context()
	color_depth = get_environment_color()
}

_fini_terminal :: proc "contextless" () { }
