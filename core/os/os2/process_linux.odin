//+build linux
//+private file
package os2

import "base:runtime"
import "base:intrinsics"

import "core:fmt"
import "core:mem"
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

	dir_fd: linux.Fd
	errno:  linux.Errno
	#partial switch dir_fd, errno = linux.open("/proc/", _OPENDIR_FLAGS); errno {
	case .ENOTDIR:
		return {}, .Invalid_Dir
	case .ENOENT:
		return {}, .Not_Exist
	}
	defer linux.close(dir_fd)

	dynamic_list := make([dynamic]int, temp_allocator())

	buf := make([dynamic]u8, 128, 128, temp_allocator())
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
	info.fields = selection

	// Use this so we can use bprintf to make cstrings with less copying.
	// The path_backing is manually zero terminated as we go.
	path_backing: [48]u8

	path_slice := path_backing[:len(path_backing) - 1]
	path_cstr  := cstring(&path_slice[0])
	path_len   := len(fmt.bprintf(path_slice, "/proc/%d", pid))
	// path_len unused here as path_backing[path_len] = 0 is assumed.

	proc_fd, errno := linux.open(path_cstr, _OPENDIR_FLAGS)
	if errno != .NONE {
		err = _get_platform_error(errno)
		return
	}
	defer linux.close(proc_fd)

	if .Username in selection {
		s: linux.Stat
		linux.fstat(proc_fd, &s)

		passwd_bytes := _read_entire_pseudo_file_cstring("/etc/passwd", temp_allocator()) or_return
		passwd := string(passwd_bytes)
		for len(passwd) > 0 {
			n := strings.index_byte(passwd, ':')
			if n == -1 {
				break
			}
			username := passwd[:n]
			passwd = passwd[n+1:]

			// skip password field
			passwd = passwd[strings.index_byte(passwd, ':') + 1:]

			n = strings.index_byte(passwd, ':')
			uid: int
			ok: bool
			if uid, ok = strconv.parse_int(passwd[:n]); ok && uid == int(s.uid) {
				info.username = strings.clone(username, allocator) or_return
				break
			} else if !ok {
				return info, .Invalid_File
			}

			eol := strings.index_byte(passwd, '\n')
			if eol == -1 {
				break
			}
			passwd = passwd[eol + 1:]
		}
	}

	cmdline_if: if selection & {.Working_Dir, .Command_Line, .Command_Args, .Executable_Path} != {} {
		path_len = len(fmt.bprintf(path_slice, "/proc/%d/cmdline", pid))
		path_backing[path_len] = 0

		cmdline_bytes := _read_entire_pseudo_file(path_cstr, temp_allocator()) or_return
		if len(cmdline_bytes) == 0 {
			break cmdline_if
		}
		cmdline := string(cmdline_bytes)

		terminator := strings.index_byte(cmdline, 0)

		command_line_exec := cmdline[:terminator]

		// Still need cwd if the execution on the command line is relative.
		cwd: string
		cwd_err: Error
		if .Working_Dir in selection || (.Executable_Path in selection && command_line_exec[0] != '/') {
			path_len = len(fmt.bprintf(path_slice, "/proc/%d/cwd", pid))
			path_backing[path_len] = 0

			cwd, cwd_err = _read_link_cstr(path_cstr, temp_allocator()) // allowed to fail
			if cwd_err == nil && .Working_Dir in selection {
				info.working_dir = strings.clone(cwd, allocator) or_return
			}
		}

		if .Executable_Path in selection {
			if cmdline[0] == '/' {
				info.executable_path = strings.clone(cmdline[:terminator], allocator) or_return
			} else if cwd_err == nil {
				join_paths: [2]string = { cwd, cmdline[:terminator] }
				info.executable_path = filepath.join(join_paths[:], allocator)
			}
		}
		if .Command_Line in selection {
			info.command_line = strings.clone(cmdline[:terminator], allocator) or_return
		}

		if .Command_Args in selection {
			// skip to first arg
			cmdline = cmdline[terminator + 1:]

			arg_list := make([dynamic]string, allocator) or_return
			for len(cmdline) > 0 {
				terminator = strings.index_byte(cmdline, 0)
				arg := strings.clone(cmdline[:terminator], allocator) or_return
				append(&arg_list, arg) or_return
				cmdline = cmdline[terminator + 1:]
			}
			info.command_args = arg_list[:]
		}
	}

	stat_if: if selection & {.PPid, .Priority} != {} {
		path_len = len(fmt.bprintf(path_slice, "/proc/%d/stat", pid))
		path_backing[path_len] = 0

		proc_stat_bytes := _read_entire_pseudo_file(path_cstr, temp_allocator()) or_return
		if len(proc_stat_bytes) <= 0 {
			break stat_if
		}

		start := strings.last_index_byte(string(proc_stat_bytes), ')')
		stats := string(proc_stat_bytes[start + 2:])

		// We are now on the 3rd field (skip)
		stats = stats[strings.index_byte(stats, ' ') + 1:]

		if .PPid in selection {
			ppid_str := stats[:strings.index_byte(stats, ' ')]
			if ppid, ok := strconv.parse_int(ppid_str); ok {
				info.ppid = ppid
			} else {
				return info, .Invalid_File
			}
		}

		if .Priority in selection {
			// On 4th field. Priority is field 18 and niceness is field 19.
			for _ in 4..<19 {
				stats = stats[strings.index_byte(stats, ' ') + 1:]
			}
			nice_str := stats[:strings.index_byte(stats, ' ')]
			if nice, ok := strconv.parse_int(nice_str); ok {
				info.priority = nice
			} else {
				return info, .Invalid_File
			}
		}
	}

	if .Environment in selection {
		path_len = len(fmt.bprintf(path_slice, "/proc/%d/environ", pid))
		path_backing[path_len] = 0

		if env_bytes, env_err := _read_entire_pseudo_file(path_cstr, temp_allocator()); env_err == nil {
			env := string(env_bytes)

			env_list := make([dynamic]string, allocator) or_return
			for len(env) > 0 {
				terminator := strings.index_byte(env, 0)
				if terminator == -1 || terminator == 0 {
					break
				}
				e := strings.clone(env[:terminator], allocator) or_return
				append(&env_list, e) or_return
				env = env[terminator + 1:]
			}
			info.environment = env_list[:]
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
	if errno != nil {
		return process, _get_platform_error(errno)
	}
	process.handle = uintptr(pidfd)
	return
}

@(private="package")
_Sys_Process_Attributes :: struct {}

@(private="package")
_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	_has_executable_permissions :: proc(fd: linux.Fd) -> bool {
		backing: [48]u8
		_ = fmt.bprintf(backing[:], "/proc/self/fd/%d", fd)
		return linux.access(cstring(&backing[0]), linux.X_OK) == .NONE
	}

	TEMP_ALLOCATOR_GUARD()

	if len(desc.command) == 0 {
		return process, .Invalid_File
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
	if strings.index_byte(executable_name, '/') == -1 {
		path_env := get_env("PATH", temp_allocator())
		path_dirs := filepath.split_list(path_env, temp_allocator())

		found: bool
		for dir in path_dirs {
			exe_path := fmt.caprintf("%s/%s", dir, executable_name, allocator=temp_allocator())
			if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
				continue
			}
			if !_has_executable_permissions(exe_fd) {
				linux.close(exe_fd)
				continue
			}
			found = true
			break
		}
		if !found {
			// check in cwd to match windows behavior
			exe_path := fmt.caprintf("./%s", executable_name, allocator=temp_allocator())
			if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
				return process, .Not_Exist
			}
			if !_has_executable_permissions(exe_fd) {
				linux.close(exe_fd)
				return process, .Permission_Denied
			}
		}
	} else {
		exe_path := temp_cstring(executable_name) or_return
		if exe_fd, errno = linux.openat(dir_fd, exe_path, {.PATH, .CLOEXEC}); errno != .NONE {
			return process, _get_platform_error(errno)
		}
		if !_has_executable_permissions(exe_fd) {
			linux.close(exe_fd)
			return process, .Permission_Denied
		}
	}

	// At this point, we have an executable.
	defer linux.close(exe_fd)

	// args and environment need to be a list of cstrings
	// that are terminated by a nil pointer.
	cargs := make([]cstring, len(desc.command) + 1, temp_allocator())
	for command, i in desc.command {
		cargs[i] = temp_cstring(command) or_return
	}

	// Use current process' environment if description didn't provide it.
	env: [^]cstring
	if desc.env == nil {
		// take this process's current environment
		env = raw_data(export_cstring_environment(temp_allocator()))
	} else {
		cenv := make([]cstring, len(desc.env) + 1, temp_allocator())
		for env, i in desc.env {
			cenv[i] = temp_cstring(env) or_return
		}
		env = &cenv[0]
	}

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
		return process, _get_platform_error(errno)
	}

	STDIN  :: linux.Fd(0)
	STDOUT :: linux.Fd(1)
	STDERR :: linux.Fd(2)

	if pid == 0 {
		// in child process now
		if desc.stdin != nil {
			fd := linux.Fd(fd(desc.stdin))
			if _, errno = linux.dup2(fd, STDIN); errno != .NONE {
				intrinsics.trap()
			}
		}
		if desc.stdout != nil {
			fd := linux.Fd(fd(desc.stdout))
			if _, errno = linux.dup2(fd, STDOUT); errno != .NONE {
				intrinsics.trap()
			}
		}
		if desc.stderr != nil {
			fd := linux.Fd(fd(desc.stderr))
			if _, errno = linux.dup2(fd, STDERR); errno != .NONE {
				intrinsics.trap()
			}
		}

		if errno = linux.execveat(exe_fd, "", &cargs[0], env, {.AT_EMPTY_PATH}); errno != .NONE {
			intrinsics.trap()
		}
		unreachable()
	}

	// TODO: We need to come up with a way to detect the execve failure from here.

	process, err = process_open(int(pid))
	if err == .Unsupported {
		return process, nil
	}
	return
}

_process_state_update_times :: proc(p: Process, state: ^Process_State) -> (err: Error) {
	TEMP_ALLOCATOR_GUARD()

	stat_path_buf: [32]u8
	_ = fmt.bprintf(stat_path_buf[:], "/proc/%d/stat", p.pid)
	stat_buf: []u8
	stat_buf, err = _read_entire_pseudo_file(cstring(&stat_path_buf[0]), temp_allocator())
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

@(private="package")
_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	process_state.pid = process.pid

	errno: linux.Errno
	options: linux.Wait_Options
	big_if: if timeout == 0 {
		options += {.WNOHANG}
	} else if timeout > 0 {
		ts: linux.Time_Spec = {
			time_sec  = uint(timeout / time.Second),
			time_nsec = uint(timeout % time.Second),
		}

		if process.handle != PIDFD_UNASSIGNED {
			pollfd: [1]linux.Poll_Fd = {
				{
					fd = linux.Fd(process.handle),
					events = {.IN},
				},
			}

			for {
				n, e := linux.ppoll(pollfd[:], &ts, nil)
				if e == .EINTR {
					continue
				}
				if e != .NONE {
					return process_state, _get_platform_error(errno)
				}
				if n == 0 {
					_process_state_update_times(process, &process_state)
					return
				}
				break
			}
		} else {
			mask: bit_set[0..<64; u64]
			mask += { int(linux.Signal.SIGCHLD) - 1 }

			org_sigset: linux.Sig_Set
			sigset: linux.Sig_Set
			mem.copy(&sigset, &mask, size_of(mask))
			errno = linux.rt_sigprocmask(.SIG_BLOCK, &sigset, &org_sigset)
			if errno != .NONE {
				return process_state, _get_platform_error(errno)
			}
			defer linux.rt_sigprocmask(.SIG_SETMASK, &org_sigset, nil)

			// In case there was a signal handler on SIGCHLD, avoid race
			// condition by checking wait first.
			options += {.WNOHANG}
			waitid_options := options + {.WNOWAIT, .WEXITED}
			info: linux.Sig_Info
			errno = linux.waitid(.PID, linux.Id(process.pid), &info, waitid_options, nil)
			if errno == .NONE && info.code != 0 {
				break big_if
			}

			loop: for {
				sigset = {}
				mem.copy(&sigset, &mask, size_of(mask))

				_, errno = linux.rt_sigtimedwait(&sigset, &info, &ts)
				#partial switch errno {
				case .EAGAIN: // timeout
					_process_state_update_times(process, &process_state)
					return
				case .EINVAL:
					return process_state, _get_platform_error(errno)
				case .EINTR:
					continue
				case:
					if info.pid == linux.Pid(process.pid) {
						break loop
					}
				}
			}
		}
	}

	status: u32
	errno = .EINTR
	for errno == .EINTR {
		_, errno = linux.wait4(linux.Pid(process.pid), &status, options, nil)
		if errno != .NONE {
			_process_state_update_times(process, &process_state)
			return process_state, _get_platform_error(errno)
		}
	}

	_process_state_update_times(process, &process_state)

	// terminated by exit
	if linux.WIFEXITED(status) {
		process_state.exited = true
		process_state.exit_code = int(linux.WEXITSTATUS(status))
		process_state.success = process_state.exit_code == 0
		return
	}

	// terminated by signal
	if linux.WIFSIGNALED(status) {
		process_state.exited = false
		process_state.exit_code = int(linux.WTERMSIG(status))
		process_state.success = false
		return
	}
	return
}

@(private="package")
_process_close :: proc(process: Process) -> Error {
	pidfd := linux.Fd(process.handle)
	if pidfd < 0 {
		return nil
	}
	return _get_platform_error(linux.close(pidfd))
}

@(private="package")
_process_kill :: proc(process: Process) -> Error {
	return _get_platform_error(linux.kill(linux.Pid(process.pid), .SIGKILL))
}

