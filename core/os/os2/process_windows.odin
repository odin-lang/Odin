//+private
package os2

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
	return -1
}

_get_ppid :: proc() -> int {
	return -1
}

Process_Attributes_OS_Specific :: struct{}

_find_process :: proc(pid: int) -> (^Process, Error) {
	return nil, nil
}

_process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (Process, Error) {
	return Process{}, nil
}

_process_release :: proc(p: ^Process) -> Error {
	return nil
}

_process_kill :: proc(p: ^Process) -> Error {
	return nil
}

_process_signal :: proc(p: ^Process, sig: Signal) -> Error {
	return nil
}

_process_wait :: proc(p: ^Process) -> (Process_State, Error) {
	return {}, nil
}
