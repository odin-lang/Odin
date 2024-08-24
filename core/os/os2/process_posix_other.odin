//+private
//+build netbsd, openbsd, freebsd
package os2

import "base:runtime"

_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	err = .Unsupported
	return
}

_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	err = .Unsupported
	return
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	err = .Unsupported
	return
}

_process_handle_still_valid :: proc(p: Process) -> Error {
	return nil
}

_process_state_update_times :: proc(p: Process, state: ^Process_State) {
	return
}
