package terminal

import "core:os"
import "core:sys/windows"

_is_terminal :: proc(handle: os.Handle) -> bool {
	is_tty := windows.GetFileType(windows.HANDLE(handle)) == windows.FILE_TYPE_CHAR
	return is_tty
}
