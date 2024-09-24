#+private
package os2

import "base:runtime"
import "base:intrinsics"

import "core:bytes"
import "core:sys/darwin"
import "core:sys/posix"
import "core:sys/unix"
import "core:time"

foreign import lib "system:System.framework"

foreign lib {
	sysctl :: proc(
		name: [^]i32, namelen: u32,
		oldp: rawptr, oldlenp: ^uint,
		newp: rawptr, newlen: uint,
	) -> posix.result ---
}

_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	get_pidinfo :: proc(pid: int, selection: Process_Info_Fields) -> (ppid: u32, prio: Maybe(i32), uid: posix.uid_t, ok: bool) {
		// Short info is enough and requires less permissions if the priority isn't requested.
		if .Priority in selection {
			info: darwin.proc_taskallinfo
			ret := darwin.proc_pidinfo(posix.pid_t(pid), .TASKALLINFO, 0, &info, size_of(info))
			if ret > 0 {
				assert(ret == size_of(info))
				ppid = info.pbsd.pbi_ppid
				prio = info.ptinfo.pti_priority
				uid  = info.pbsd.pbi_uid
				ok   = true
				return
			}
		}

		// Try short info, requires less permissions, but doesn't give a `nice`.
		psinfo: darwin.proc_bsdshortinfo
		ret := darwin.proc_pidinfo(posix.pid_t(pid), .SHORTBSDINFO, 0, &psinfo, size_of(psinfo))
		if ret > 0 {
			assert(ret == size_of(psinfo))
			ppid = psinfo.pbsi_ppid
			uid  = psinfo.pbsi_uid
			ok   = true
		}

		return
	}


	info.pid = pid

	// Thought on errors is: allocation failures return immediately (also why the non-allocation stuff is done first),
	// other errors usually mean other parts of the info could be retrieved though, so in those cases we keep trying to get the other information.

	pidinfo: {
		if selection & {.PPid, .Priority, .Username } != {} {
			ppid, mprio, uid, ok := get_pidinfo(pid, selection)
			if !ok {
				if err == nil {
					err = _get_platform_error()
				}
				break pidinfo
			}

			if .PPid in selection {
				info.ppid = int(ppid)
				info.fields += {.PPid}
			}

			if prio, has_prio := mprio.?; has_prio && .Priority in selection {
				info.priority = int(prio)
				info.fields += {.Priority}
			}

			if .Username in selection {
				pw := posix.getpwuid(uid)
				if pw == nil {
					if err == nil {
						err = _get_platform_error()
					}
					break pidinfo
				}

				info.username = clone_string(string(pw.pw_name), allocator) or_return
				info.fields += {.Username}
			}
		}
	}

	if .Working_Dir in selection {
		pinfo: darwin.proc_vnodepathinfo
		ret := darwin.proc_pidinfo(posix.pid_t(pid), .VNODEPATHINFO, 0, &pinfo, size_of(pinfo))
		if ret > 0 {
			assert(ret == size_of(pinfo))
			info.working_dir = clone_string(string(cstring(raw_data(pinfo.pvi_cdir.vip_path[:]))), allocator) or_return
			info.fields += {.Working_Dir}
		} else if err == nil {
			err = _get_platform_error()
		}
	}

	if .Executable_Path in selection {
		buffer: [darwin.PIDPATHINFO_MAXSIZE]byte = ---
		ret := darwin.proc_pidpath(posix.pid_t(pid), raw_data(buffer[:]), len(buffer))
		if ret > 0 {
			info.executable_path = clone_string(string(buffer[:ret]), allocator) or_return
			info.fields += {.Executable_Path}
		} else if err == nil {
			err = _get_platform_error()
		}
	}

	args: if selection & { .Command_Line, .Command_Args, .Environment } != {} {
		mib := []i32{
			unix.CTL_KERN,
			unix.KERN_PROCARGS2,
			i32(pid),
		}
		length: uint
		if sysctl(raw_data(mib), 3, nil, &length, nil, 0) != .OK {
			if err == nil {
				err = _get_platform_error()
			}
			break args
		}

		buf := runtime.make_aligned([]byte, length, 4, temp_allocator())
		if sysctl(raw_data(mib), 3, raw_data(buf), &length, nil, 0) != .OK {
			if err == nil {
				err = _get_platform_error()

				// Looks like EINVAL is returned here if you don't have permission.
				if err == Platform_Error(posix.Errno.EINVAL) {
					err = .Permission_Denied
				}
			}
			break args
		}

		buf = buf[:length]

		if len(buf) < 4 {
			break args
		}

		// Layout isn't really documented anywhere, I deduced it to be:
		// i32        - argc
		// cstring    - command name (skipped)
		// [^]byte    - couple of 0 bytes (skipped)
		// [^]cstring - argv (up to argc entries)
		// [^]cstring - key=value env entries until the end (many intermittent 0 bytes and entries without `=` we skip here too)

		argc := (^i32)(raw_data(buf))^
		buf = buf[size_of(i32):]

		{
			command_line: [dynamic]byte
			command_line.allocator = allocator

			argv: [dynamic]string
			argv.allocator = allocator

			defer if err != nil {
				for arg in argv { delete(arg, allocator) }
				delete(argv)
				delete(command_line)
			}

			_, _ = bytes.split_iterator(&buf, {0})
			buf = bytes.trim_left(buf, {0})

			first_arg := true
			for arg in bytes.split_iterator(&buf, {0}) {
				if .Command_Line in selection {
					if !first_arg {
						append(&command_line, ' ') or_return
					}
					append(&command_line, ..arg) or_return
				}

				if .Command_Args in selection {
					sarg := clone_string(string(arg), allocator) or_return
					append(&argv, sarg) or_return
				}

				first_arg = false
				argc -= 1
				if argc == 0 {
					break
				}
			}

			if .Command_Line in selection {
				info.command_line = string(command_line[:])
				info.fields += {.Command_Line}
			}
			if .Command_Args in selection {
				info.command_args = argv[:]
				info.fields += {.Command_Args}
			}
		}

		if .Environment in selection {
			environment: [dynamic]string
			environment.allocator = allocator

			defer if err != nil {
				for entry in environment { delete(entry, allocator) }
				delete(environment)
			}

			for entry in bytes.split_iterator(&buf, {0}) {
				if bytes.index_byte(entry, '=') > -1 {
					sentry := clone_string(string(entry), allocator) or_return
					append(&environment, sentry) or_return
				}
			}

			info.environment = environment[:]
			info.fields += {.Environment}
		}
	}

	// Fields were requested that we didn't add.
	if err == nil && selection - info.fields != {} {
		err = .Unsupported
	}

	return
}

_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	ret := darwin.proc_listallpids(nil, 0)
	if ret < 0 {
		err = _get_platform_error()
		return
	}

	TEMP_ALLOCATOR_GUARD()

	buffer := make([]i32, ret, temp_allocator())
	ret = darwin.proc_listallpids(raw_data(buffer), ret*size_of(i32))
	if ret < 0 {
		err = _get_platform_error()
		return
	}

	list = make([]int, ret, allocator) or_return
	#no_bounds_check for &entry, i in list {
		entry = int(buffer[i])
	}

	return
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	rusage: darwin.rusage_info_v0
	if ret := darwin.proc_pid_rusage(posix.pid_t(pid), .V0, &rusage); ret != 0 {
		err = _get_platform_error()
		return
	}

	// Using the start time as the handle, there is no pidfd or anything on Darwin.
	// There is a uuid, but once a process becomes a zombie it changes...
	process.handle = uintptr(rusage.ri_proc_start_abstime)
	process.pid    = int(pid)
	return
}

_process_handle_still_valid :: proc(p: Process) -> Error {
	rusage: darwin.rusage_info_v0
	if ret := darwin.proc_pid_rusage(posix.pid_t(p.pid), .V0, &rusage); ret != 0 {
		return _get_platform_error()
	}

	handle := uintptr(rusage.ri_proc_start_abstime)
	if p.handle != handle {
		return posix.Errno.ESRCH
	}

	return nil
}

_process_state_update_times :: proc(p: Process, state: ^Process_State) {
	rusage: darwin.rusage_info_v0
	if ret := darwin.proc_pid_rusage(posix.pid_t(p.pid), .V0, &rusage); ret != 0 {
		return
	}

	// NOTE(laytan): I have no clue if this is correct, the output seems correct comparing it with `time`'s output.
	HZ :: 20000000

	state.user_time   = (
		(time.Duration(rusage.ri_user_time) / HZ * time.Second) +
		 time.Duration(rusage.ri_user_time  % HZ))
	state.system_time = (
		(time.Duration(rusage.ri_system_time) / HZ * time.Second) +
		 time.Duration(rusage.ri_system_time % HZ))

	return
}
