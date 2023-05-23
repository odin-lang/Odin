package os2

import "core:sync"
import "core:time"
import "core:runtime"

args: []string

exit :: proc "contextless" (code: int) -> ! {
	runtime.trap()
}

get_uid :: proc() -> int {
	return _get_uid()
}

get_euid :: proc() -> int {
	return _get_euid()
}

get_gid :: proc() -> int {
	return _get_gid()
}

get_egid :: proc() -> int {
	return _get_euid()
}

get_pid :: proc() -> int {
	return _get_pid()
}

get_ppid :: proc() -> int {
	return _get_ppid()
}


Process :: struct {
	pid:          int,
	handle:       uintptr,
	is_done:      b32,
	signal_mutex: sync.RW_Mutex,
}


Process_Attributes :: struct {
	dir: string,
	env: []string,
	files: []^File,
	sys: ^Process_Attributes_OS_Specific,
}

Process_State :: struct {
	pid:         int,
	exit_code:   int,
	exited:      bool,
	success:     bool,
	system_time: time.Duration,
	user_time:   time.Duration,
	sys:         rawptr,
}

Signal :: #type proc()

Kill:      Signal = nil
Interrupt: Signal = nil


find_process :: proc(pid: int) -> (^Process, Error) {
	return _find_process(pid)
}

process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes = nil) -> (Process, Error) {
	return _process_start(name, argv, attr)
}

process_release :: proc(p: ^Process) -> Error {
	return _process_release(p)
}

process_kill :: proc(p: ^Process) -> Error {
	return _process_kill(p)
}

process_signal :: proc(p: ^Process, sig: Signal) -> Error {
	return _process_signal(p, sig)
}

process_wait :: proc(p: ^Process) -> (Process_State, Error) {
	return _process_wait(p)
}




