#+build windows
package benchmark_codegen

import win "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign kernel32 {
	SetPriorityClass :: proc(hProcess: win.HANDLE, dwPriorityClass: win.DWORD) -> win.BOOL ---
}

// Raises the process priority, and pins the main thread to `cpu` unless it is -1.
@(require_results)
prepare_process :: proc(cpu: int) -> bool {
	SetPriorityClass(win.GetCurrentProcess(), win.HIGH_PRIORITY_CLASS)
	if cpu < 0 {
		return true
	}

	if cpu >= 8*size_of(win.DWORD_PTR) {
		return false
	}

	mask     := win.DWORD_PTR(1) << uint(cpu)
	previous := win.SetThreadAffinityMask(win.GetCurrentThread(), mask)
	return previous != 0
}
