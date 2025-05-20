#+private
package testing

import win32 "core:sys/windows"

old_stdout_mode: u32
old_stderr_mode: u32

console_ansi_init :: proc() {
	stdout := win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
	if stdout != win32.INVALID_HANDLE && stdout != nil {
		if win32.GetConsoleMode(stdout, &old_stdout_mode) {
			win32.SetConsoleMode(stdout, old_stdout_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
		}
	}

	stderr := win32.GetStdHandle(win32.STD_ERROR_HANDLE)
	if stderr != win32.INVALID_HANDLE && stderr != nil {
		if win32.GetConsoleMode(stderr, &old_stderr_mode) {
			win32.SetConsoleMode(stderr, old_stderr_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
		}
	}
}

// Restore the cursor on exit
console_ansi_fini :: proc() {
	stdout := win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
	if stdout != win32.INVALID_HANDLE && stdout != nil {
		win32.SetConsoleMode(stdout, old_stdout_mode)
	}

	stderr := win32.GetStdHandle(win32.STD_ERROR_HANDLE)
	if stderr != win32.INVALID_HANDLE && stderr != nil {
		win32.SetConsoleMode(stderr, old_stderr_mode)
	}
}