//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"
import "core:time"

import "core:sys/posix"

_exit :: proc "contextless" (code: int) -> ! {
	posix.exit(i32(code))
}

_get_uid :: proc() -> int {
	return int(posix.getuid())
}

_get_euid :: proc() -> int {
	return int(posix.geteuid())
}

_get_gid :: proc() -> int {
	return int(posix.getgid())
}

_get_egid :: proc() -> int {
	return int(posix.getegid())
}

_get_pid :: proc() -> int {
	return int(posix.getpid())
}

_get_ppid :: proc() -> int {
	return int(posix.getppid())
}

_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(process.pid, selection, allocator)
}

_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(_get_pid(), selection, allocator)
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	err = .Unsupported
	return
}

_Sys_Process_Attributes :: struct {}

_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	err = .Unsupported
	return
}

_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	err = .Unsupported
	return
}

_process_close :: proc(process: Process) -> Error {
	return .Unsupported
}

_process_kill :: proc(process: Process) -> Error {
	return .Unsupported
}
