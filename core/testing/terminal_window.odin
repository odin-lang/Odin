#+private
#+build windows
package testing

import win32 "core:sys/windows"

old_console_codepage: win32.CODEPAGE

set_utf8_codepage :: proc() {
	old_console_codepage = win32.GetConsoleOutputCP()
	win32.SetConsoleOutputCP(win32.CODEPAGE(65001))
}

restore_old_codepage :: proc() {
	win32.SetConsoleOutputCP(old_console_codepage)
}