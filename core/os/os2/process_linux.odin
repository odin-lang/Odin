//+private
package os2

_Process :: struct {}

_process_open :: proc(desc: Process_Desc) -> (Process, Process_Error) {
	return {}, .Unspecified_Error
}

_process_close :: proc(process: Process) -> (Process_Error) {
	return .Unspecified_Error
}

_process_start :: proc(process: Process) -> (Process_Error) {
	return .Unspecified_Error
}

_process_suspend :: proc(process: Process) -> (Process_Error) {
	return .Unspecified_Error
}

_process_terminate :: proc(process: Process, code: i32) -> (Process_Error) {
	return .Unspecified_Error
}

_process_wait :: proc(process: Process, timeout: time.Duration) -> (int, Wait_Status) {
	return -1, .Error
}