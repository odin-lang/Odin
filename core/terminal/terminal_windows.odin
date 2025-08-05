#+private
package terminal

import "core:os"
import "core:sys/windows"

_is_terminal :: proc(handle: os.Handle) -> bool {
	is_tty := windows.GetFileType(windows.HANDLE(handle)) == windows.FILE_TYPE_CHAR
	return is_tty
}

old_modes: [2]struct{
	handle: windows.DWORD,
	mode: windows.DWORD,
} = {
	{windows.STD_OUTPUT_HANDLE, 0},
	{windows.STD_ERROR_HANDLE, 0},
}

@(init)
_init_terminal :: proc() {
	vtp_enabled: bool

	for &v in old_modes {
		handle := windows.GetStdHandle(v.handle)
		if handle == windows.INVALID_HANDLE || handle == nil {
			return
		}
		if windows.GetConsoleMode(handle, &v.mode) {
			windows.SetConsoleMode(handle, v.mode | windows.ENABLE_PROCESSED_OUTPUT | windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING)

			new_mode: windows.DWORD
			windows.GetConsoleMode(handle, &new_mode)

			if new_mode & (windows.ENABLE_PROCESSED_OUTPUT | windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0 {
				vtp_enabled = true
			}
		}
	}

	if vtp_enabled {
		// This color depth is available on Windows 10 since build 10586.
		color_depth = .Four_Bit
	} else {
		// The user may be on a non-default terminal emulator.
		color_depth = get_environment_color()
	}
}

@(fini)
_fini_terminal :: proc() {
	for v in old_modes {
		handle := windows.GetStdHandle(v.handle)
		if handle == windows.INVALID_HANDLE || handle == nil {
			return
		}
		
		windows.SetConsoleMode(handle, v.mode)
	}
}
