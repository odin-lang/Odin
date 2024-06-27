//+private
package os2

import "core:runtime"
import "core:time"

_alloc_command_line_arguments :: proc() -> []string {
	return nil
}

_exit :: proc "contextless" (_: int) -> ! {
	runtime.trap()
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
	return -1
}

_get_ppid :: proc() -> int {
	return -1
}

Process_Attributes_OS_Specific :: struct{}

_process_find :: proc(pid: int) -> (Process, Error) {
	return Process{}, nil
}

_process_get_state :: proc(p: Process) -> (Process_State, Error) {
	return Process_State{}, nil
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

_process_signal :: proc(sig: Signal, handler: Signal_Handler) -> Error {
	return nil
}

_process_wait :: proc(p: ^Process, t: time.Duration) -> (Process_State, Error) {
	return Process_State{}, nil
}
