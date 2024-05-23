package os2

import "core:sync"
import "core:time"
import "core:c"

args: []string = _alloc_command_line_arguments()

exit :: proc "contextless" (code: int) -> ! {
	_exit(code)
}

@(require_results)
get_uid :: proc() -> int {
	return _get_uid()
}

@(require_results)
get_euid :: proc() -> int {
	return _get_euid()
}

@(require_results)
get_gid :: proc() -> int {
	return _get_gid()
}

@(require_results)
get_egid :: proc() -> int {
	return _get_euid()
}

@(require_results)
get_pid :: proc() -> int {
	return _get_pid()
}

@(require_results)
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
	stdin: ^File,
	stdout: ^File,
	stderr: ^File,
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

Signal :: enum {
	Abort,
	Floating_Point_Exception,
	Illegal_Instruction,
	Interrupt,
	Segmentation_Fault,
	Termination,
}

Signal_Handler_Proc :: #type proc "c" (c.int)
Signal_Handler_Special :: enum {
	Default,
	Ignore,
}

Signal_Handler :: union {
	Signal_Handler_Proc,
	Signal_Handler_Special,
}

@(require_results)
process_find :: proc(pid: int) -> (Process, Error) {
	return _process_find(pid)
}

@(require_results)
process_get_state :: proc(p: Process) -> (Process_State, Error) {
	return _process_get_state(p)
}

@(require_results)
process_start :: proc(name: string, argv: []string, attr: ^Process_Attributes = nil) -> (Process, Error) {
	return _process_start(name, argv, attr)
}

process_release :: proc(p: ^Process) -> Error {
	return _process_release(p)
}

process_kill :: proc(p: ^Process) -> Error {
	return _process_kill(p)
}

process_signal :: proc(sig: Signal, h: Signal_Handler) -> Error {
	return _process_signal(sig, h)
}

process_wait :: proc(p: ^Process, t: time.Duration = time.MAX_DURATION) -> (Process_State, Error) {
	return _process_wait(p, t)
}
