#+build linux
#+private file
package os2

import "base:runtime"
import "base:intrinsics"

import "core:time"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:sys/linux"
import "core:path/filepath"

PIDFD_UNASSIGNED  :: ~uintptr(0)

@(private="package")
_exit :: proc "contextless" (code: int) -> ! {
	linux.exit_group(i32(code))
}

@(private="package")
_get_uid :: proc() -> int {
	return int(linux.getuid())
}

@(private="package")
_get_euid :: proc() -> int {
	return int(linux.geteuid())
}

@(private="package")
_get_gid :: proc() -> int {
	return int(linux.getgid())
}

@(private="package")
_get_egid :: proc() -> int {
	return int(linux.getegid())
}

@(private="package")
_get_pid :: proc() -> int {
	return int(linux.getpid())
}

@(private="package")
_get_ppid :: proc() -> int {
	return int(linux.getppid())
}

@(private="package")
_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	TEMP_ALLOCATOR_GUARD()

	dir_fd, errno := linux.open("/proc/", _OPENDIR_FLAGS)
	#partial switch errno {
	case .NONE:
		// okay
	case .ENOTDIR:
		err = .Invalid_Dir
		return
	case .ENOENT:
		err = .Not_Exist
		return
	case:
		err = _get_platform_error(errno)
		return
	}
	defer linux.close(dir_fd)

	dynamic_list := make([dynamic]int, temp_allocator()) or_return

	buf := make([dynamic]u8, 128, 128, temp_allocator()) or_return
	loop: for {
		buflen: int
		buflen, errno = linux.getdents(dir_fd, buf[:])
		#partial switch errno {
		case .EINVAL:
			resize(&buf, len(buf) * 2)
			continue loop
		case .NONE:
			if buflen == 0 { break loop }
		case:
			return {}, _get_platform_error(errno)
		}

		offset: int
		for d in linux.dirent_iterate_buf(buf[:buflen], &offset) {
			d_name_str := linux.dirent_name(d)

			if pid, ok := strconv.parse_int(d_name_str); ok {
				append(&dynamic_list, pid)
			}
		}
	}

	list, err = slice.clone(dynamic_list[:], allocator)
	return
}

@(private="package")
_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	TEMP_ALLOCATOR_GUARD()

	info.pid = pid

	// Use this to make cstrings without copying.
	path_backing: [48]u8
	path_builder := strings.builder_from_bytes(path_backing[:])

	strings.write_string(&path_builder, "/proc/")
	strings.write_int(&path_builder, pid)
	proc_fd, errno := linux.open(strings.to_cstring(&path_builder), _OPENDIR_FLAGS)
	if errno != .NONE {
		err = _get_platform_error(errno)
		return
	}
	defer linux.close(proc_fd)

	username_if: if .Username in selection {
		s: linux.Stat
		if errno = linux.fstat(proc_fd, &s); errno != .NONE {
			err = _get_platform_error(errno)
			break username_if
		}

		passwd_bytes: []u8
		passwd_err: Error
		passwd_bytes, passwd_err = _read_entire_pseudo_file_cstring("/etc/passwd", temp_allocator())
		if passwd_err != nil {
			err = passwd_err
			break username_if
		}

		passwd := string(passwd_bytes)
		for len(passwd) > 0 {
			n := strings.index_byte(passwd, ':')
			if n < 0 {
				break
			}
			username := passwd[:n]
			passwd = passwd[n+1:]

			// skip password field
			passwd = passwd[strings.index_byte(passwd, ':') + 1:]

			n = strings.index_byte(passwd, ':')
			if uid, ok := strconv.parse_int(passwd[:n]); ok && uid == int(s.uid) {
				info.username = strings.clone(username, allocator) or_return
				info.fields += {.Username}
				break
			} else if !ok {
				err = .Invalid_File
				break username_if
			}

			eol := strings.index_byte(passwd, '\n')
			if eol < 0 {
				break
			}
			passwd = passwd[eol + 1:]
		}
	}

	cmdline_if: if selection & {.Working_Dir, .Command_Line, .Command_Args, .Executable_Path} != {} {
		strings.builder_reset(&path_builder)
		strings.write_string(&path_builder, "/proc/")
		strings.write_int(&path_builder, pid)
		strings.write_string(&path_builder, "/cmdline")

		cmdline_bytes, cmdline_err := _read_entire_pseudo_file(strings.to_cstring(&path_builder), temp_allocator())
		if cmdline_err != nil || len(cmdline_bytes) == 0 {
			err = cmdline_err
			break cmdline_if
		}
		cmdline := string(cmdline_bytes)

		terminator := strings.index_byte(cmdline, 0)
		assert(terminator > 0)

		command_line_exec := cmdline[:terminator]

		// Still need cwd if the execution on the command line is relative.
		cwd: string
		cwd_err: Error
		if .Working_Dir in selection || (.Executable_Path in selection && command_line_exec[0] != '/') {
			strings.builder_reset(&path_builder)
			strings.write_string(&path_builder, "/proc/")
			strings.write_int(&path_builder, pid)
			strings.write_string(&path_builder, "/cwd")

			cwd, cwd_err = _read_link_cstr(strings.to_cstring(&path_builder), temp_allocator()) // allowed to fail
			if cwd_err == nil && .Working_Dir in selection {
				info.working_dir = strings.clone(cwd, allocator) or_return
				info.fields += {.Working_Dir}
			} else if cwd_err != nil {
				err = cwd_err
				break cmdline_if
			}
		}

		if .Executable_Path in selection {
			if cmdline[0] == '/' {
				info.executable_path = strings.clone(cmdline[:terminator], allocator) or_return
				info.fields += {.Executable_Path}
			} else if cwd_err == nil {
				info.executable_path = filepath.join({ cwd, cmdline[:terminator] }, allocator) or_return
				info.fields += {.Executable_Path}
			} else {
				break cmdline_if
			}
		}

		if selection & {.Command_Line, .Command_Args} != {} {
			// skip to first arg
			//cmdline = cmdline[terminator + 1:]
			command_line_builder: strings.Builder
			command_args_list: [dynamic]string

			if .Command_Line in selection {
				command_line_builder = strings.builder_make(allocator) or_return
				info.fields += {.Command_Line}
			}

			for i := 0; len(cmdline) > 0; i += 1 {
				if terminator = strings.index_byte(cmdline, 0); terminator < 0 {
					break
				}

				if .Command_Line in selection {
					if i > 0 {
						strings.write_byte(&command_line_builder, ' ')
					}
					strings.write_string(&command_line_builder, cmdline[:terminator])
				}
				if .Command_Args in selection {
					if i == 1 {
						command_args_list = make([dynamic]string, allocator) or_return
						info.fields += {.Command_Args}
					}
					if i > 0 {
						arg := strings.clone(cmdline[:terminator], allocator) or_return
						append(&command_args_list, arg) or_return
					}
				}

				cmdline = cmdline[terminator + 1:]
			}
			info.command_line = strings.to_string(command_line_builder)
			info.command_args = command_args_list[:]
		}
	}

	stat_if: if selection & {.PPid, .Priority} != {} {
		strings.builder_reset(&path_builder)
		strings.write_string(&path_builder, "/proc/")
		strings.write_int(&path_builder, pid)
		strings.write_string(&path_builder, "/stat")

		proc_stat_bytes, stat_err := _read_entire_pseudo_file(strings.to_cstring(&path_builder), temp_allocator())
		if stat_err != nil {
			err = stat_err
			break stat_if
		}
		if len(proc_stat_bytes) <= 0 {
			break stat_if
		}

		// Skip to the first field after the executable name
		stats: string
		if start := strings.last_index_byte(string(proc_stat_bytes), ')'); start != -1 {
			stats = string(proc_stat_bytes[start + 2:])
		} else {
			break stat_if
		}

		// NOTE: index 0 corresponds to field 3 (state) from `man 5 proc_pid_stat`
		//       because we skipped passed the executable name above.
		Fields :: enum {
			State,
			PPid,
			PGrp,
			Session,
			Tty_Nr,
			TpGid,
			Flags,
			MinFlt,
			CMinFlt,
			MajFlt,
			CMajFlt,
			UTime,
			STime,
			CUTime,
			CSTime,
			Priority,
			Nice,
			//... etc,
		}
		stat_fields := strings.split(stats, " ", temp_allocator()) or_return

		if len(stat_fields) <= int(Fields.Nice) {
			break stat_if
		}

		if .PPid in selection {
			if ppid, ok := strconv.parse_int(stat_fields[Fields.PPid]); ok {
				info.ppid = ppid
				info.fields += {.PPid}
			} else {
				err = .Invalid_File
				break stat_if
			}
		}

		if .Priority in selection {
			if nice, ok := strconv.parse_int(stat_fields[Fields.Nice]); ok {
				info.priority = nice
				info.fields += {.Priority}
			} else {
				err = .Invalid_File
				break stat_if
			}
		}
	}

	if .Environment in selection {
		strings.builder_reset(&path_builder)
		strings.write_string(&path_builder, "/proc/")
		strings.write_int(&path_builder, pid)
		strings.write_string(&path_builder, "/environ")

		if env_bytes, env_err := _read_entire_pseudo_file(strings.to_cstring(&path_builder), temp_allocator()); env_err == nil {
			env := string(env_bytes)

			env_list := make([dynamic]string, allocator) or_return
			for len(env) > 0 {
				terminator := strings.index_byte(env, 0)
				if terminator <= 0 {
					break
				}
				e := strings.clone(env[:terminator], allocator) or_return
				append(&env_list, e) or_return
				env = env[terminator + 1:]
			}
			info.environment = env_list[:]
			info.fields += {.Environment}
		} else if err == nil {
			err = env_err
		}
	}

	return
}

@(private="package")
_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(process.pid, selection, allocator)
}

@(private="package")
_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	return _process_info_by_pid(get_pid(), selection, allocator)
}

@(private="package")
_process_open :: proc(pid: int, _: Process_Open_Flags) -> (process: Process, err: Error) {
	process.pid = pid
	process.handle = PIDFD_UNASSIGNED

	pidfd, errno := linux.pidfd_open(linux.Pid(pid), {})
	if errno == .ENOSYS {
		return process, .Unsupported
	}
	if errno != .NONE {
		return process, _get_platform_error(errno)
	}
	process.handle = uintptr(pidfd)
	return
}

@(private="package")
_Sys_Process_Attributes :: struct {}

@(private="package")
_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	has_executable_permissions :: proc(fd: linux.Fd) -> bool {
		backing: [48]u8
		b := strings.builder_from_bytes(backing[:])
		strings.write_string(&b, "/proc/self/fd/")
		strings.write_int(&b, int(fd))
		return linux.access(strings.to_cstring(&b), linux.X_OK) == .NONE
	}

	TEMP_ALLOCATOR_GUARD()

	if len(desc.command) == 0 {
		return process, .Invalid_Command
	}

	dir_fd := linux.AT_FDCWD
	errno: linux.Errno
	if desc.working_dir != "" {
		dir_cstr := temp_cstring(desc.working_dir) or_return
		if dir_fd, errno = linux.open(dir_cstr, _OPENDIR_FLAGS); errno != .NONE {
			return process, _get_platform_error(errno)
		}
	}
	defer if desc.working_dir != "" {
		linux.close(dir_fd)
	}

	// search PATH if just a plain name is provided
	exe_fd: linux.Fd
	executable_name := desc.command[0]
	if strings.index_byte(executable_name, '/') < 0 {
		path_env := get_env("PATH", temp_allocator())
		path_dirs := filepath.split_list(path_env, temp_allocator()) or_return

		exe_builder := strings.builder_make(temp_allocator()) or_return

		found: bool
		for dir in path_dirs {
			strings.builder_reset(&exe_builder)
			strings.write_string(&exe_builder, dir)
			strings.write_byte(&exe_builder, '/')
			strings.write_string(&exe_builder, executable_name)

			exe_path := strings.to_cstring(&exe_builder)
			if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
				continue
			}
			if !has_executable_permissions(exe_fd) {
				linux.close(exe_fd)
				continue
			}
			found = true
			break
		}
		if !found {
			// check in cwd to match windows behavior
			strings.builder_reset(&exe_builder)
			strings.write_string(&exe_builder, "./")
			strings.write_string(&exe_builder, executable_name)

			exe_path := strings.to_cstring(&exe_builder)
			if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
				return process, .Not_Exist
			}
			if !has_executable_permissions(exe_fd) {
				linux.close(exe_fd)
				return process, .Permission_Denied
			}
		}
	} else {
		exe_path := temp_cstring(executable_name) or_return
		if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
			return process, _get_platform_error(errno)
		}
		if !has_executable_permissions(exe_fd) {
			linux.close(exe_fd)
			return process, .Permission_Denied
		}
	}

	// At this point, we have an executable.
	defer linux.close(exe_fd)

	// args and environment need to be a list of cstrings
	// that are terminated by a nil pointer.
	cargs := make([]cstring, len(desc.command) + 1, temp_allocator()) or_return
	for command, i in desc.command {
		cargs[i] = temp_cstring(command) or_return
	}

	// Use current process' environment if description didn't provide it.
	env: [^]cstring
	if desc.env == nil {
		// take this process's current environment
		env = raw_data(export_cstring_environment(temp_allocator()))
	} else {
		cenv := make([]cstring, len(desc.env) + 1, temp_allocator()) or_return
		for env, i in desc.env {
			cenv[i] = temp_cstring(env) or_return
		}
		env = &cenv[0]
	}

	child_pipe_fds: [2]linux.Fd
	if errno = linux.pipe2(&child_pipe_fds, {.CLOEXEC}); errno != .NONE {
		return process, _get_platform_error(errno)
	}
	defer linux.close(child_pipe_fds[READ])


	// TODO: This is the traditional textbook implementation with fork.
	//       A more efficient implementation with vfork:
	//
	//       1. retrieve signal handlers
	//       2. block all signals
	//       3. allocate some stack space
	//       4. vfork (waits for child exit or execve); In child:
	//           a. set child signal handlers
	//           b. set up any necessary pipes
	//           c. execve
	//       5. restore signal handlers
	//
	pid: linux.Pid
	if pid, errno = linux.fork(); errno != .NONE {
		linux.close(child_pipe_fds[WRITE])
		return process, _get_platform_error(errno)
	}

	STDIN  :: linux.Fd(0)
	STDOUT :: linux.Fd(1)
	STDERR :: linux.Fd(2)

	READ :: 0
	WRITE :: 1

	if pid == 0 {
		// in child process now
		write_errno_to_parent_and_abort :: proc(parent_fd: linux.Fd, errno: linux.Errno) -> ! {
			error_byte: [1]u8 = { u8(errno) }
			linux.write(parent_fd, error_byte[:])
			linux.exit(126)
		}

		stdin_fd: linux.Fd
		stdout_fd: linux.Fd
		stderr_fd: linux.Fd

		if desc.stdin != nil {
			stdin_fd = linux.Fd(fd(desc.stdin))
		} else {
			stdin_fd, errno = linux.open("/dev/null", {})
			if errno != .NONE {
				write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
			}
		}

		write_devnull: linux.Fd = -1

		if desc.stdout != nil {
			stdout_fd = linux.Fd(fd(desc.stdout))
		} else {
			write_devnull, errno = linux.open("/dev/null", {.WRONLY})
			if errno != .NONE {
				write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
			}
			stdout_fd = write_devnull
		}

		if desc.stderr != nil {
			stderr_fd = linux.Fd(fd(desc.stderr))
		} else {
			if write_devnull < 0 {
				write_devnull, errno = linux.open("/dev/null", {.WRONLY})
				if errno != .NONE {
					write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
				}
			}
			stderr_fd = write_devnull
		}

		if _, errno = linux.dup2(stdin_fd, STDIN); errno != .NONE {
			write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
		}
		if _, errno = linux.dup2(stdout_fd, STDOUT); errno != .NONE {
			write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
		}
		if _, errno = linux.dup2(stderr_fd, STDERR); errno != .NONE {
			write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
		}

		errno = linux.execveat(exe_fd, "", &cargs[0], env, {.AT_EMPTY_PATH})
		assert(errno != nil)
		write_errno_to_parent_and_abort(child_pipe_fds[WRITE], errno)
	}

	linux.close(child_pipe_fds[WRITE])

	process.pid = int(pid)

	child_byte: [1]u8
	errno = .EINTR
	for errno == .EINTR {
		_, errno = linux.read(child_pipe_fds[READ], child_byte[:])
	}

	// If the read failed, something weird happened. Do not return the read
	// error so the user knows to wait on it.
	if errno == .NONE {
		child_errno := linux.Errno(child_byte[0])
		if child_errno != .NONE {
			// We can assume it trapped here.
			_reap_terminated(process)
			process.pid = 0
			return process, _get_platform_error(child_errno)
		}
	}

	process, _ = process_open(int(pid))
	return
}

_process_state_update_times :: proc(state: ^Process_State) -> (err: Error) {
	TEMP_ALLOCATOR_GUARD()

	stat_path_buf: [48]u8
	path_builder := strings.builder_from_bytes(stat_path_buf[:])
	strings.write_string(&path_builder, "/proc/")
	strings.write_int(&path_builder, int(state.pid))
	strings.write_string(&path_builder, "/stat")

	stat_buf: []u8
	stat_buf, err = _read_entire_pseudo_file(strings.to_cstring(&path_builder), temp_allocator())
	if err != nil {
		return
	}

	// ')' will be the end of the executable name (item 2)
	idx := strings.last_index_byte(string(stat_buf), ')')
	stats := string(stat_buf[idx + 2:])

	// utime and stime are the 14 and 15th items, respectively, and we are
	// currently on item 3. Skip 11 items here.
	for _ in 0..<11 {
		stats = stats[strings.index_byte(stats, ' ') + 1:]
	}

	idx = strings.index_byte(stats, ' ')
	utime_str := stats[:idx]

	stats = stats[idx + 1:]
	stime_str := stats[:strings.index_byte(stats, ' ')]

	utime, stime: int
	ok: bool
	if utime, ok = strconv.parse_int(utime_str, 10); !ok {
		return .Invalid_File
	}
	if stime, ok = strconv.parse_int(stime_str, 10); !ok {
		return .Invalid_File
	}

	// NOTE: Assuming HZ of 100, 1 jiffy == 10 ms
	state.user_time = time.Duration(utime) * 10 * time.Millisecond
	state.system_time = time.Duration(stime) * 10 * time.Millisecond

	return
}

_reap_terminated :: proc(process: Process) -> (state: Process_State, err: Error) {
	state.pid = process.pid
	_process_state_update_times(&state)

	info: linux.Sig_Info
	errno := linux.Errno.EINTR
	for errno == .EINTR {
		errno = linux.waitid(.PID, linux.Id(process.pid), &info, {.WEXITED}, nil)
	}
	err = _get_platform_error(errno)

	switch linux.Sig_Child_Code(info.code) {
	case .NONE, .CONTINUED, .STOPPED:
		unreachable()
	case .EXITED:
		state.exited = true
		state.exit_code = int(info.status)
		state.success = state.exit_code == 0
	case .KILLED, .DUMPED, .TRAPPED:
		state.exited = true
		state.exit_code = int(info.status)
		state.success = false
	}
	return
}

_timed_wait_on_handle :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	timeout := timeout

	process_state.pid = process.pid
	pidfd := linux.Fd(process.handle)
	pollfd: [1]linux.Poll_Fd = {
		{
			fd = pidfd,
			events = {.IN},
		},
	}

	start_tick := time.tick_now()

	mask: bit_set[0..<64; u64]
	mask += { int(linux.Signal.SIGCHLD) - 1 }
	sigchld_set := transmute(linux.Sig_Set)(mask)

	info: linux.Sig_Info
	for {
		if timeout <= 0 {
			_process_state_update_times(&process_state)
			err = .Timeout
			return
		}

		ts: linux.Time_Spec = {
			time_sec  = uint(timeout / time.Second),
			time_nsec = uint(timeout % time.Second),
		}

		n, errno := linux.ppoll(pollfd[:], &ts, &sigchld_set)
		if errno != .NONE {
			if errno == .EINTR {
				timeout -= time.tick_since(start_tick)
				start_tick = time.tick_now()
				continue
			}
			return process_state, _get_platform_error(errno)
		}

		if n == 0 {  // timeout with no events
			_process_state_update_times(&process_state)
			err = .Timeout
			return
		}

		if errno = linux.waitid(.PIDFD, linux.Id(process.handle), &info, {.WEXITED, .WNOHANG, .WNOWAIT}, nil); errno != .NONE {
			return process_state, _get_platform_error(errno)
		}

		if info.signo == .SIGCHLD {
			break
		}

		timeout -= time.tick_since(start_tick)
		start_tick = time.tick_now()
	}

	// _reap_terminated for pidfd
	{
		_process_state_update_times(&process_state)

		errno := linux.Errno.EINTR
		for errno == .EINTR {
			errno = linux.waitid(.PIDFD, linux.Id(process.handle), &info, {.WEXITED}, nil)
		}
		err = _get_platform_error(errno)

		switch linux.Sig_Child_Code(info.code) {
		case .NONE, .CONTINUED, .STOPPED:
			unreachable()
		case .EXITED:
			process_state.exited = true
			process_state.exit_code = int(info.status)
			process_state.success = process_state.exit_code == 0
		case .KILLED, .DUMPED, .TRAPPED:
			process_state.exited = true
			process_state.exit_code = int(info.status)
			process_state.success = false
		}
	}
	return
}

_timed_wait_on_pid :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	timeout := timeout
	process_state.pid = process.pid

	mask: bit_set[0..<64; u64]
	mask += { int(linux.Signal.SIGCHLD) - 1 }
	sigchld_set := transmute(linux.Sig_Set)(mask)

	start_tick := time.tick_now()

	org_sigset: linux.Sig_Set
	errno := linux.rt_sigprocmask(.SIG_BLOCK, &sigchld_set, &org_sigset)
	if errno != .NONE {
		return process_state, _get_platform_error(errno)
	}
	defer linux.rt_sigprocmask(.SIG_SETMASK, &org_sigset, nil)

	// In case there was a signal handler on SIGCHLD, avoid race
	// condition by checking wait first.
	info: linux.Sig_Info
	errno = linux.waitid(.PID, linux.Id(process.pid), &info, {.WNOWAIT, .WEXITED, .WNOHANG}, nil)

	for errno != .NONE || info.code == 0 || info.pid != linux.Pid(process.pid) {
		if timeout <= 0 {
			_process_state_update_times(&process_state)
			err = .Timeout
			return
		}

		ts: linux.Time_Spec = {
			time_sec  = uint(timeout / time.Second),
			time_nsec = uint(timeout % time.Second),
		}

		_, errno = linux.rt_sigtimedwait(&sigchld_set, &info, &ts)
		#partial switch errno {
		case .EAGAIN:   // timeout
			_process_state_update_times(&process_state)
			err = .Timeout
			return
		case .EINTR:
			timeout -= time.tick_since(start_tick)
			start_tick = time.tick_now()
		case .EINVAL:
			return process_state, _get_platform_error(errno)
		}
	}

	return _reap_terminated(process)
}

@(private="package")
_process_wait :: proc(process: Process, timeout: time.Duration) -> (Process_State, Error) {
	if timeout > 0 {
		if process.handle == PIDFD_UNASSIGNED {
			return _timed_wait_on_pid(process, timeout)
		} else {
			return _timed_wait_on_handle(process, timeout)
		}
	}

	process_state: Process_State = {
		pid = process.pid,
	}

	errno: linux.Errno
	options: linux.Wait_Options = {.WEXITED}
	if timeout == 0 {
		options += {.WNOHANG}
	}

	info: linux.Sig_Info

	errno = .EINTR
	for errno == .EINTR {
		errno = linux.waitid(.PID, linux.Id(process.pid), &info, options + {.WNOWAIT}, nil)
	}
	if errno == .EAGAIN || (errno == .NONE && info.signo != .SIGCHLD) {
		_process_state_update_times(&process_state)
		return process_state, .Timeout
	}
	if errno != .NONE {
		return process_state, _get_platform_error(errno)
	}

	return _reap_terminated(process)
}

@(private="package")
_process_close :: proc(process: Process) -> Error {
	if process.handle == 0 || process.handle == PIDFD_UNASSIGNED {
		return nil
	}
	pidfd := linux.Fd(process.handle)
	return _get_platform_error(linux.close(pidfd))
}

@(private="package")
_process_kill :: proc(process: Process) -> Error {
	return _get_platform_error(linux.kill(linux.Pid(process.pid), .SIGKILL))
}

