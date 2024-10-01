#+private
package testing

import win32 "core:sys/windows"

console_ansi_init :: proc() {
	stdout := win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
	if stdout != win32.INVALID_HANDLE && stdout != nil {
		old_console_mode: u32
		if win32.GetConsoleMode(stdout, &old_console_mode) {
			win32.SetConsoleMode(stdout, old_console_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
		}
	}

	stderr := win32.GetStdHandle(win32.STD_ERROR_HANDLE)
	if stderr != win32.INVALID_HANDLE && stderr != nil {
		old_console_mode: u32
		if win32.GetConsoleMode(stderr, &old_console_mode) {
			win32.SetConsoleMode(stderr, old_console_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
		}
	}
}
