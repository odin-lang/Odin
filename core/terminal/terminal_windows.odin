package terminal

import "core:os"
import "core:sys/windows"

_is_terminal :: proc(handle: os.Handle) -> bool {
	mode: windows.DWORD
	return bool(windows.GetConsoleMode(windows.HANDLE(handle), &mode))
}
