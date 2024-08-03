//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"
import "core:time"

import "core:sys/posix"

_exit :: proc "contextless" (code: int) -> ! {
	posix.exit(i32(code))
}

_get_uid :: proc() -> int {
	return int(posix.getuid())
}

_get_euid :: proc() -> int {
	return int(posix.geteuid())
}

_get_gid :: proc() -> int {
	return int(posix.getgid())
}

_get_egid :: proc() -> int {
	return int(posix.getegid())
}

_get_pid :: proc() -> int {
	return int(posix.getpid())
}

_get_ppid :: proc() -> int {
	return int(posix.getppid())
}

_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(process.pid, selection, allocator)
}

_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(_get_pid(), selection, allocator)
}

_Sys_Process_Attributes :: struct {}

_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	if len(desc.command) == 0 {
		err = .Invalid_Path
		return
	}

	cwd: cstring; if desc.working_dir != "" {
		cwd = temp_cstring(desc.working_dir)
	}

	cmd := make([]cstring, len(desc.command)+1, temp_allocator())
	for part, i in desc.command {
		cmd[i] = temp_cstring(part)
	}

	switch pid := posix.fork(); pid {
	case -1:
		err = _get_platform_error()
		return

	case 0:
		// NOTE(laytan): would need to use execvp and look up the command in the PATH.
		assert(len(desc.env) == 0, "unimplemented: process_start with env")

		null := posix.open("/dev/null", { .RDWR, .CLOEXEC })
		assert(null != -1) // TODO: Does this happen/need to be handled?

		stderr := (^File_Impl)(desc.stderr.impl).fd if desc.stderr != nil else null
		stdout := (^File_Impl)(desc.stdout.impl).fd if desc.stdout != nil else null
		stdin  := (^File_Impl)(desc.stdin.impl).fd  if desc.stdin  != nil else null

		posix.dup2(stderr, posix.STDERR_FILENO)
		posix.dup2(stdout, posix.STDOUT_FILENO)
		posix.dup2(stdin,  posix.STDIN_FILENO )

		// NOTE(laytan): is this how we should handle these?
		// Maybe we can try to `stat` the cwd in the parent before forking?
		// Does that mean no other errors could happen in chdir?
		// How about execvp?

		if cwd != nil {
			if posix.chdir(cwd) != .OK {
				posix.exit(i32(posix.errno())) // TODO: handle, or is it fine this way?
			}
		}

		posix.execvp(cmd[0], raw_data(cmd))
		posix.exit(i32(posix.errno())) // TODO: handle, or is it fine this way?

	case:
		fmt.println("returning")
		process, _ = _process_open(int(pid), {})
		process.pid = int(pid)
		return
	}
}

import "core:fmt"
import "core:nbio/kqueue"

_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	process_state.pid = process.pid

	if !process_posix_handle_still_valid(process) {
		err = Platform_Error(posix.Errno.ESRCH)
		return
	}

	// prev := posix.signal(.SIGALRM, proc "c" (_: posix.Signal) {
	// 	context = runtime.default_context()
	// 	fmt.println("alarm")
	// })
	// defer posix.signal(.SIGALRM, prev)
	//
	// posix.alarm(u32(time.duration_seconds(timeout)))
	// defer posix.alarm(0)

	// TODO: if there's no timeout, don't set up a kqueue.

	// TODO: if timeout is 0, don't set up a kqueue and use NO_HANG.

	kq, qerr := kqueue.kqueue()
	if qerr != nil {
		err = Platform_Error(qerr)
		return
	}

	changelist, eventlist: [1]kqueue.KEvent

	changelist[0] = {
		ident  = uintptr(process.pid),
		filter = .Proc,
		flags  = { .Add },
		fflags = {
			fproc = 0x80000000,
		},
	}

	// NOTE: could this be interrupted which means it should be looped and subtracting the timeout on EINTR.

	n, eerr := kqueue.kevent(kq, changelist[:], eventlist[:], &{
		seconds     = i64(timeout / time.Second),
		nanoseconds = i64(timeout % time.Second),
	})
	if eerr != nil {
		err = Platform_Error(eerr)
		return
	}

	if n == 0 {
		err = .Timeout

		// TODO: populate the time fields.

		return
	}

	// NOTE(laytan): should this be looped untill WIFEXITED/WIFSIGNALED?

	status: i32
	wpid := posix.waitpid(posix.pid_t(process.pid), &status, {})
	if wpid == -1 {
		err = _get_platform_error()
		return
	}

	process_state.exited = true

	// TODO: populate times

	switch {
	case posix.WIFEXITED(status):
		fmt.printfln("child exited, status=%v", posix.WEXITSTATUS(status))
		process_state.exit_code = int(posix.WEXITSTATUS(status))
		process_state.success   = true
	case posix.WIFSIGNALED(status):
		fmt.printfln("child killed (signal %v)", posix.WTERMSIG(status))
		process_state.exit_code = int(posix.WTERMSIG(status))
		process_state.success   = false
	case:
		fmt.panicf("unexpected status (%x)", status)
	}

	return
}

_process_close :: proc(process: Process) -> Error {
	return nil
}

_process_kill :: proc(process: Process) -> (err: Error) {
	if !process_posix_handle_still_valid(process) {
		err = Platform_Error(posix.Errno.ESRCH)
		return
	}

	if posix.kill(posix.pid_t(process.pid), .SIGKILL) != .OK {
		err = _get_platform_error()
	}

	return
}
