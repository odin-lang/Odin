#+private
#+build netbsd, openbsd, freebsd
package terminal

import bsd "core:sys/freebsd"
import "core:sys/posix"

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	Winsize :: struct {
		row, col: u16,
	}

	ws: Winsize

	if bsd.ioctl(posix.STDOUT_FILENO, bsd.TIOCGWINSZ, uintptr(&ws)) == 0 {
		width = int(ws.col)
		height = int(ws.row)
		ok = width > 0 && height > 0
	}

	return width, height, ok
}
