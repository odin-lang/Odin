//+build windows
package os2

import "core:sys/windows"
import "base:runtime"

_Process_Handle :: windows.HANDLE

_exit :: proc "contextless" (code: int) -> ! {
	windows.ExitProcess(u32(code))
}

_get_uid :: proc() -> int {
	return -1
}

_get_euid :: proc() -> int {
	return -1
}

_get_gid :: proc() -> int {
	return -1
}

_get_egid :: proc() -> int {
	return -1
}

_get_pid :: proc() -> int {
	return cast(int) windows.GetCurrentProcessId()
}

_get_ppid :: proc() -> int {
	our_pid := windows.GetCurrentProcessId()
	snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snap == windows.INVALID_HANDLE_VALUE {
		return -1
	}
	defer windows.CloseHandle(snap)
	entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
	status := windows.Process32FirstW(snap, &entry)
	for status {
		if entry.th32ProcessID == our_pid {
			return cast(int) entry.th32ParentProcessID
		}
		status = windows.Process32NextW(snap, &entry)
	}
	return -1
}

_process_list :: proc(allocator: runtime.Allocator) -> ([]int, Error) {
	pid_list := make([dynamic]int, allocator)
	snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snap == windows.INVALID_HANDLE_VALUE {
		return pid_list[:], _get_platform_error()
	}
	entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
	status := windows.Process32FirstW(snap, &entry)
	for status {
		append(&pid_list, cast(int) entry.th32ProcessID)
		status = windows.Process32NextW(snap, &entry)
	}
	return pid_list[:], nil
}

_process_open :: proc(pid: int) -> (Process, Error) {
	handle := windows.OpenProcess(windows.PROCESS_QUERY_LIMITED_INFORMATION, false, cast(u32) pid)
	if handle == windows.INVALID_HANDLE_VALUE {
		return {}, _get_platform_error()
	}
	return Process {
		handle = handle,
	}, nil
}

_process_close :: proc(process: Process) -> (Error) {
	if !windows.CloseHandle(process.handle) {
		return _get_platform_error()
	}
}
