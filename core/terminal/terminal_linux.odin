#+private
package terminal

import "core:sys/linux"
import "core:sys/posix"

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	Winsize :: struct {
		row, col, xpixel, ypixel: u16,
	}

	ws: Winsize

	if linux.ioctl(posix.STDOUT_FILENO, linux.TIOCGWINSZ, uintptr(&ws)) == 0 {
		width = int(ws.col)
		height = int(ws.row)
		ok = width > 0 && height > 0
	}

	return width, height, ok
}
