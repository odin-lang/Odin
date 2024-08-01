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
