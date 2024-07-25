//+private file
package os2

import "base:runtime"
import "core:time"
import "core:sys/linux"

@(private="package")
_exit :: proc "contextless" (code: int) -> ! {
	linux.exit(i32(code))
}


@(private="package")
_get_uid :: proc() -> int {
	return -1
}

@(private="package")
_get_euid :: proc() -> int {
	return -1
}

@(private="package")
_get_gid :: proc() -> int {
	return -1
}

@(private="package")
_get_egid :: proc() -> int {
	return -1
}

@(private="package")
_get_pid :: proc() -> int {
	return -1
}

@(private="package")
_get_ppid :: proc() -> int {
	return -1
}

@(private="package")
_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	return
}

@(private="package")
_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return
}

@(private="package")
_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return
}

@(private="package")
_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return
}

@(private="package")
_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	return
}

@(private="package")
_Sys_Process_Attributes :: struct {}

@(private="package")
_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	return
}

@(private="package")
_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	return
}

@(private="package")
_process_close :: proc(process: Process) -> Error {
	return nil
}

@(private="package")
_process_kill :: proc(process: Process) -> Error {
	return nil
}

@(private="package")
_process_exe_by_pid :: proc(pid: int, allocator: runtime.Allocator) -> (exe_path: string, err: Error) {
	return
}