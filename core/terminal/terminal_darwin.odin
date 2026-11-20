#+private
package terminal

import "core:sys/darwin"
import "core:sys/posix"

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	Winsize :: struct {
		row, col, xpixel, ypixel: u16,
	}

	ws: Winsize

	if darwin.syscall_ioctl(posix.STDOUT_FILENO, darwin.TIOCGWINSZ, &ws) == 0 {
		width = int(ws.col)
		height = int(ws.row)
		ok = width > 0 && height > 0
	}

	return width, height, ok
}
