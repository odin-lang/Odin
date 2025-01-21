#+private
package os2

import "base:runtime"

import "core:time"
import "core:sys/wasm/wasi"

_exit :: proc "contextless" (code: int) -> ! {
	wasi.proc_exit(wasi.exitcode_t(code))
}

_get_uid :: proc() -> int {
	return 0
}

_get_euid :: proc() -> int {
	return 0
}

_get_gid :: proc() -> int {
	return 0
}

_get_egid :: proc() -> int {
	return 0
}

_get_pid :: proc() -> int {
	return 0
}

_get_ppid :: proc() -> int {
	return 0
}

_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	err = .Unsupported
	return
}

_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
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

_process_kill :: proc(process: Process) -> (err: Error) {
	return .Unsupported
}

_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	err = .Unsupported
	return
}

_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	err = .Unsupported
	return
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	process.pid = pid
	err = .Unsupported
	return
}

_process_handle_still_valid :: proc(p: Process) -> Error {
	return nil
}

_process_state_update_times :: proc(p: Process, state: ^Process_State) {
	return
}
