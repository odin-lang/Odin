#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package terminal

import "core:os"
import "core:sys/posix"

_is_terminal :: proc(handle: os.Handle) -> bool {
	return bool(posix.isatty(posix.FD(handle)))
}
