#+private
#+build netbsd, openbsd, freebsd
package terminal

import "core:c"
import "core:sys/posix"

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	ioctl :: proc(fd: c.int, request: c.ulong, #c_vararg args: ..any) -> c.int ---
}

TIOCGWINSZ :: 0x40087468

_get_terminal_size :: proc "contextless" () -> (width, height: int, ok: bool) {
	Winsize :: struct {
		row, col, xpixel, ypixel: u16,
	}

	ws: Winsize

	if ioctl(posix.STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 {
		width = int(ws.col)
		height = int(ws.row)
		ok = width > 0 && height > 0
	}

	return width, height, ok
}
