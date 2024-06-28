package os2

import "core:sync"
import "core:time"
import "base:runtime"

args: []string

exit :: proc "contextless" (code: int) -> ! {
	runtime.trap()
}

get_uid :: proc() -> int {
	return -1
}

get_euid :: proc() -> int {
	return -1
}

get_gid :: proc() -> int {
	return -1
}

get_egid :: proc() -> int {
	return -1
}

get_pid :: proc() -> int {
	return -1
}

get_ppid :: proc() -> int {
	return -1
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

Process_Attributes_OS_Specific :: struct{}

Process_Error :: enum {
	None,
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


find_process :: proc(pid: int) -> (^Process, Process_Error) {
	return nil, .None
}


process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes) -> (^Process, Process_Error) {
	return nil, .None
}

process_release :: proc(p: ^Process) -> Process_Error {
	return .None
}

process_kill :: proc(p: ^Process) -> Process_Error {
	return .None
}

process_signal :: proc(p: ^Process, sig: Signal) -> Process_Error {
	return .None
}

process_wait :: proc(p: ^Process) -> (Process_State, Process_Error) {
	return {}, .None
}




