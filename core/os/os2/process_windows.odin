//+build windows
package os2

import "core:sys/windows"
import "core:strings"
import "core:time"

import "base:runtime"

_Process_Handle :: windows.HANDLE

_exit :: proc "contextless" (code: int) -> ! {
	windows.ExitProcess(u32(code))
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
	return cast(int) windows.GetCurrentProcessId()
}

_get_ppid :: proc() -> int {
	our_pid := windows.GetCurrentProcessId()
	snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snap == windows.INVALID_HANDLE_VALUE {
		return -1
	}
	defer windows.CloseHandle(snap)
	entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
	status := windows.Process32FirstW(snap, &entry)
	for status {
		if entry.th32ProcessID == our_pid {
			return cast(int) entry.th32ParentProcessID
		}
		status = windows.Process32NextW(snap, &entry)
	}
	return -1
}

_process_list :: proc(allocator: runtime.Allocator) -> ([]int, Error) {
	pid_list := make([dynamic]int, allocator)
	snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snap == windows.INVALID_HANDLE_VALUE {
		return pid_list[:], _get_platform_error()
	}
	entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
	status := windows.Process32FirstW(snap, &entry)
	for status {
		append(&pid_list, cast(int) entry.th32ProcessID)
		status = windows.Process32NextW(snap, &entry)
	}
	return pid_list[:], nil
}

_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	info.pid = pid
	defer if err != nil {
		free_process_info(info, allocator)
	}
	need_snapprocess := \
		.PPid in selection ||
		.Priority in selection
	need_snapmodule := \
		.Executable_Path in selection
	need_peb := \
		.Command_Line in selection ||
		.Environment in selection ||
		.Working_Dir in selection
	need_process_handle := need_peb || .Username in selection
	// Data obtained from process snapshots
	if need_snapprocess {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = General_Error.Not_Exist
			return
		}
		if .PPid in selection {
			info.fields |= {.PPid}
			info.ppid = int(entry.th32ParentProcessID)
		}
		if .Priority in selection {
			info.fields |= {.Priority}
			info.priority = int(entry.pcPriClassBase)
		}
	}
	if need_snapmodule {
		exe_path, exe_path_err := _process_exe_by_pid(pid, allocator)
		if exe_path_err != nil {
			err = exe_path_err
			return
		}
		info.fields |= {.Executable_Path}
		info.executable_path = exe_path
	}
	ph := windows.INVALID_HANDLE_VALUE
	if need_process_handle {
		ph = windows.OpenProcess(
			windows.PROCESS_QUERY_LIMITED_INFORMATION | windows.PROCESS_VM_READ,
			false,
			u32(pid),
		)
		if ph == windows.INVALID_HANDLE_VALUE {
			err = _get_platform_error()
			return
		}
	}
	defer if ph != windows.INVALID_HANDLE_VALUE {
		windows.CloseHandle(ph)
	}
	if need_peb {
		// TODO(flysand): This was not tested with WOW64 or 32-bit processes,
		// might need to be revised later when issues occur.
		ntdll_lib := windows.LoadLibraryW(windows.L("ntdll.dll"))
		if ntdll_lib == nil {
			err = _get_platform_error()
			return
		}
		defer windows.FreeLibrary(ntdll_lib)
		NtQueryInformationProcess := cast(NtQueryInformationProcess_T) windows.GetProcAddress(ntdll_lib, "NtQueryInformationProcess")
		if NtQueryInformationProcess == nil {
			err = _get_platform_error()
			return
		}
		process_info_size: u32 = ---
		process_info: PROCESS_BASIC_INFORMATION = ---
		status := NtQueryInformationProcess(ph, .ProcessBasicInformation, &process_info, size_of(process_info), &process_info_size)
		if status != 0 {
			// TODO(flysand): There's probably a mismatch between NTSTATUS and
			// windows userland error codes, I haven't checked.
			err = Platform_Error(status)
			return
		}
		if process_info.PebBaseAddress == nil {
			// Not sure what the error is
			err = General_Error.Unsupported
			return
		}
		process_peb: PEB = ---
		bytes_read: uint = ---
		read_struct :: proc(h: windows.HANDLE, addr: rawptr, dest: ^$T, br: ^uint) -> windows.BOOL {
			return windows.ReadProcessMemory(h, addr, dest, size_of(T), br)
		}
		read_slice :: proc(h: windows.HANDLE, addr: rawptr, dest: []$T, br: ^uint) -> windows.BOOL {
			return windows.ReadProcessMemory(h, addr, raw_data(dest), len(dest)*size_of(T), br)
		}
		if !read_struct(ph, process_info.PebBaseAddress, &process_peb, &bytes_read) {
			err = _get_platform_error()
			return
		}
		process_params: RTL_USER_PROCESS_PARAMETERS = ---
		if !read_struct(ph, process_peb.ProcessParameters, &process_params, &bytes_read) {
			err = _get_platform_error()
			return
		}
		if .Command_Line in selection || .Command_Args in selection {
			TEMP_ALLOCATOR_GUARD()
			cmdline_w := make([]u16, process_params.CommandLine.Length, temp_allocator())
			if !read_slice(ph, process_params.CommandLine.Buffer, cmdline_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			if .Command_Line in selection {
				cmdline, cmdline_err := windows.utf16_to_utf8(cmdline_w, allocator)
				if cmdline_err != nil {
					err = cmdline_err
					return
				}
				info.fields |= {.Command_Line}
				info.command_line = cmdline
			}
			if .Command_Args in selection {
				args, args_err := _parse_command_line(raw_data(cmdline_w), allocator)
				if args_err != nil {
					err = args_err
					return
				}
				info.fields += {.Command_Args}
				info.command_args = args
			}
		}
		if .Environment in selection {
			TEMP_ALLOCATOR_GUARD()
			env_len := process_params.EnvironmentSize / 2
			envs_w := make([]u16, env_len, temp_allocator())
			if !read_slice(ph, process_params.Environment, envs_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			envs, envs_err := _parse_environment_block(raw_data(envs_w), allocator)
			if envs_err != nil {
				err = envs_err
				return
			}
			info.fields |= {.Environment}
			info.environment = envs
		}
		if .Working_Dir in selection {
			TEMP_ALLOCATOR_GUARD()
			cwd_w := make([]u16, process_params.CurrentDirectoryPath.Length, temp_allocator())
			if !read_slice(ph, process_params.CurrentDirectoryPath.Buffer, cwd_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			cwd, cwd_err := windows.utf16_to_utf8(cwd_w, allocator)
			if cwd_err != nil {
				err = cwd_err
				return
			}
			info.fields |= {.Working_Dir}
			info.working_dir = cwd
		}
	}
	if .Username in selection {
		username, username_err := _get_process_user(ph, allocator)
		if username_err != nil {
			err = username_err
			return
		}
		info.fields |= {.Username}
		info.username = username
	}
	err = nil
	return
}

_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	pid := process.pid
	info.pid = pid
	defer if err != nil {
		free_process_info(info, allocator)
	}
	need_snapprocess := \
		.PPid in selection ||
		.Priority in selection
	need_snapmodule := \
		.Executable_Path in selection
	need_peb := \
		.Command_Line in selection ||
		.Environment in selection ||
		.Working_Dir in selection
	// Data obtained from process snapshots
	if need_snapprocess {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = General_Error.Not_Exist
			return
		}
		if .PPid in selection {
			info.fields |= {.PPid}
			info.ppid = int(entry.th32ParentProcessID)
		}
		if .Priority in selection {
			info.fields |= {.Priority}
			info.priority = int(entry.pcPriClassBase)
		}
	}
	if need_snapmodule {
		exe_path, exe_path_err := _process_exe_by_pid(pid, allocator)
		if exe_path_err != nil {
			err = exe_path_err
			return
		}
		info.fields |= {.Executable_Path}
		info.executable_path = exe_path
	}
	ph := cast(windows.HANDLE) process.handle
	if need_peb {
		ntdll_lib := windows.LoadLibraryW(windows.L("ntdll.dll"))
		if ntdll_lib == nil {
			err = _get_platform_error()
			return
		}
		defer windows.FreeLibrary(ntdll_lib)
		NtQueryInformationProcess := cast(NtQueryInformationProcess_T) windows.GetProcAddress(ntdll_lib, "NtQueryInformationProcess")
		if NtQueryInformationProcess == nil {
			err = _get_platform_error()
			return
		}
		process_info_size: u32 = ---
		process_info: PROCESS_BASIC_INFORMATION = ---
		status := NtQueryInformationProcess(ph, .ProcessBasicInformation, &process_info, size_of(process_info), &process_info_size)
		if status != 0 {
			// TODO(flysand): There's probably a mismatch between NTSTATUS and
			// windows userland error codes, I haven't checked.
			err = Platform_Error(status)
			return
		}
		if process_info.PebBaseAddress == nil {
			// Not sure what the error is
			err = General_Error.Unsupported
			return
		}
		process_peb: PEB = ---
		bytes_read: uint = ---
		read_struct :: proc(h: windows.HANDLE, addr: rawptr, dest: ^$T, br: ^uint) -> windows.BOOL {
			return windows.ReadProcessMemory(h, addr, dest, size_of(T), br)
		}
		read_slice :: proc(h: windows.HANDLE, addr: rawptr, dest: []$T, br: ^uint) -> windows.BOOL {
			return windows.ReadProcessMemory(h, addr, raw_data(dest), len(dest)*size_of(T), br)
		}
		if !read_struct(ph, process_info.PebBaseAddress, &process_peb, &bytes_read) {
			err = _get_platform_error()
			return
		}
		process_params: RTL_USER_PROCESS_PARAMETERS = ---
		if !read_struct(ph, process_peb.ProcessParameters, &process_params, &bytes_read) {
			err = _get_platform_error()
			return
		}
		if .Command_Line in selection || .Command_Args in selection {
			TEMP_ALLOCATOR_GUARD()
			cmdline_w := make([]u16, process_params.CommandLine.Length, temp_allocator())
			if !read_slice(ph, process_params.CommandLine.Buffer, cmdline_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			if .Command_Line in selection {
				cmdline, cmdline_err := windows.utf16_to_utf8(cmdline_w, allocator)
				if cmdline_err != nil {
					err = cmdline_err
					return
				}
				info.fields |= {.Command_Line}
				info.command_line = cmdline
			}
			if .Command_Args in selection {
				args, args_err := _parse_command_line(raw_data(cmdline_w), allocator)
				if args_err != nil {
					err = args_err
					return
				}
				info.fields += {.Command_Args}
				info.command_args = args
			}
		}
		if .Environment in selection {
			TEMP_ALLOCATOR_GUARD()
			env_len := process_params.EnvironmentSize / 2
			envs_w := make([]u16, env_len, temp_allocator())
			if !read_slice(ph, process_params.Environment, envs_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			envs, envs_err := _parse_environment_block(raw_data(envs_w), allocator)
			if envs_err != nil {
				err = envs_err
				return
			}
			info.fields |= {.Environment}
			info.environment = envs
		}
		if .Working_Dir in selection {
			TEMP_ALLOCATOR_GUARD()
			cwd_w := make([]u16, process_params.CurrentDirectoryPath.Length, temp_allocator())
			if !read_slice(ph, process_params.CurrentDirectoryPath.Buffer, cwd_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			cwd, cwd_err := windows.utf16_to_utf8(cwd_w, allocator)
			if cwd_err != nil {
				err = cwd_err
				return
			}
			info.fields |= {.Working_Dir}
			info.working_dir = cwd
		}
	}
	if .Username in selection {
		username, username_err := _get_process_user(ph, allocator)
		if username_err != nil {
			err = username_err
			return
		}
		info.fields |= {.Username}
		info.username = username
	}
	err = nil
	return
}

_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	info.pid = cast(int) windows.GetCurrentProcessId()
	defer if err != nil {
		free_process_info(info, allocator)
	}
	need_snapprocess := .PPid in selection || .Priority in selection
	if need_snapprocess {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = General_Error.Not_Exist
			return
		}
		if .PPid in selection {
			info.fields += {.PPid}
			info.ppid = int(entry.th32ProcessID)
		}
		if .Priority in selection {
			info.fields += {.Priority}
			info.priority = int(entry.pcPriClassBase)
		}
	}
	if .Executable_Path in selection {
		exe_filename_w: [256]u16
		path_len := windows.GetModuleFileNameW(nil, raw_data(exe_filename_w[:]), len(exe_filename_w))
		exe_filename, exe_filename_err := windows.utf16_to_utf8(exe_filename_w[:path_len], allocator)
		if exe_filename_err != nil {
			err = exe_filename_err
			return
		}
		info.fields += {.Executable_Path}
		info.executable_path = exe_filename
	}
	if .Command_Line in selection  || .Command_Args in selection {
		command_line_w := windows.GetCommandLineW()
		if .Command_Line in selection {
			command_line, command_line_err := windows.wstring_to_utf8(command_line_w, -1, allocator)
			if command_line_err != nil {
				err = command_line_err
				return
			}
			info.fields += {.Command_Line}
			info.command_line = command_line
		}
		if .Command_Args in selection {
			args, args_err := _parse_command_line(command_line_w, allocator)
			if args_err != nil {
				err = args_err
				return
			}
			info.fields += {.Command_Args}
			info.command_args = args
		}
	}
	if .Environment in selection {
		env_block := windows.GetEnvironmentStringsW()
		envs, envs_err := _parse_environment_block(env_block, allocator)
		if envs_err != nil {
			err = envs_err
			return
		}
		info.fields += {.Environment}
		info.environment = envs
	}
	if .Username in selection {
		process_handle := windows.GetCurrentProcess()
		username, username_err := _get_process_user(process_handle, allocator)
		if username_err != nil {
			err = username_err
			return
		}
		info.fields += {.Username}
		info.username = username
	}
	if .Working_Dir in selection {
		// TODO(flysand): Implement this by reading PEB
		err = .Mode_Not_Implemented
		return
	}
	err = nil
	return
}

_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (Process, Error) {
	// Note(flysand): The handle will be used for querying information so we
	// take the necessary permissions right away.
	dwDesiredAccess := windows.PROCESS_QUERY_LIMITED_INFORMATION | windows.SYNCHRONIZE
	if .Mem_Read in flags {
		dwDesiredAccess |= windows.PROCESS_VM_READ
	}
	if .Mem_Write in flags {
		dwDesiredAccess |= windows.PROCESS_VM_WRITE
	}
	handle := windows.OpenProcess(
		dwDesiredAccess,
		false,
		u32(pid),
	)
	if handle == windows.INVALID_HANDLE_VALUE {
		return {}, _get_platform_error()
	}
	return Process {
		pid = pid,
		handle = cast(uintptr) handle,
	}, nil
}

_Sys_Process_Attributes :: struct {}

_process_start :: proc(desc: Process_Desc) -> (Process, Error) {
	TEMP_ALLOCATOR_GUARD()
	command_line := _build_command_line(desc.command, temp_allocator())
	command_line_w := windows.utf8_to_wstring(command_line, temp_allocator())
	environment := desc.env
	if desc.env == nil {
		environment = environ(temp_allocator())
	}
	environment_block := _build_environment_block(environment, temp_allocator())
	environment_block_w := windows.utf8_to_utf16(environment_block, temp_allocator())
	stderr_handle := windows.GetStdHandle(windows.STD_ERROR_HANDLE)
	stdout_handle := windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
	stdin_handle := windows.GetStdHandle(windows.STD_INPUT_HANDLE)
	if desc.stdout != nil {
		stdout_handle = windows.HANDLE((^File_Impl)(desc.stdout.impl).fd)
	}
	if desc.stderr != nil {
		stderr_handle = windows.HANDLE((^File_Impl)(desc.stderr.impl).fd)
	}
	if desc.stdin != nil {
		stdin_handle = windows.HANDLE((^File_Impl)(desc.stderr.impl).fd)
	}
	working_dir_w := windows.wstring(nil)
	if len(desc.working_dir) > 0 {
		working_dir_w = windows.utf8_to_wstring(desc.working_dir, temp_allocator())
	}
	process_info: windows.PROCESS_INFORMATION = ---
	process_ok := windows.CreateProcessW(
		nil,
		command_line_w,
		nil,
		nil,
		true,
		windows.CREATE_UNICODE_ENVIRONMENT|windows.NORMAL_PRIORITY_CLASS,
		raw_data(environment_block_w),
		working_dir_w,
		&windows.STARTUPINFOW {
			cb = size_of(windows.STARTUPINFOW),
			hStdError = stderr_handle,
			hStdOutput = stdout_handle,
			hStdInput = stdin_handle,
			dwFlags = windows.STARTF_USESTDHANDLES,
		},
		&process_info,
	)
	if !process_ok {
		return {}, _get_platform_error()
	}
	return Process {
		pid = cast(int) process_info.dwProcessId,
		handle = cast(uintptr) process_info.hProcess,
	}, nil
}

_process_wait :: proc(process: Process, timeout: time.Duration) -> (Process_State, Error) {
	handle := windows.HANDLE(process.handle)
	timeout_ms := u32(timeout / time.Millisecond) if timeout > 0 else windows.INFINITE
	wait_result := windows.WaitForSingleObject(handle, timeout_ms)
	switch wait_result {
	case windows.WAIT_OBJECT_0:
		exit_code: u32 = ---
		if !windows.GetExitCodeProcess(handle, &exit_code) {
			return {}, _get_platform_error()
		}
		time_created: windows.FILETIME = ---
		time_exited: windows.FILETIME = ---
		time_kernel: windows.FILETIME = ---
		time_user: windows.FILETIME = ---
		if !windows.GetProcessTimes(handle, &time_created, &time_exited, &time_kernel, &time_user) {
			return {}, _get_platform_error()
		}
		return Process_State {
			exit_code = cast(int) exit_code,
			exited = true,
			pid = process.pid,
			success = true,
			system_time = _filetime_to_duration(time_kernel),
			user_time = _filetime_to_duration(time_user),
		}, nil
	case windows.WAIT_TIMEOUT:
		return {}, General_Error.Timeout
	case:
		return {}, _get_platform_error()
	}
}

_process_close :: proc(process: Process) -> (Error) {
	if !windows.CloseHandle(cast(windows.HANDLE) process.handle) {
		return _get_platform_error()
	}
	return nil
}

_process_kill :: proc(process: Process) -> (Error) {
	// Note(flysand): This is different than what the task manager's "kill process"
	// functionality does, as we don't try to send WM_CLOSE message first. This
	// is quite a rough way to kill the process, which should be consistent with
	// linux. The error code 9 is to mimic SIGKILL event.
	if !windows.TerminateProcess(windows.HANDLE(process.handle), 9) {
		return _get_platform_error()
	}
	return nil
}

@(private)
_filetime_to_duration :: proc(filetime: windows.FILETIME) -> time.Duration {
	ticks := u64(filetime.dwHighDateTime)<<32 | u64(filetime.dwLowDateTime)
	return time.Duration(ticks * 100)
}

@(private)
_process_entry_by_pid :: proc(pid: int) -> (windows.PROCESSENTRY32W, Error) {
	snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snap == windows.INVALID_HANDLE_VALUE {
		return {}, _get_platform_error()
	}
	defer windows.CloseHandle(snap)
	entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
	status := windows.Process32FirstW(snap, &entry)
	found := false
	for status {
		if u32(pid) == entry.th32ProcessID {
			found = true
			break
		}
		status = windows.Process32NextW(snap, &entry)
	}
	if !found {
		return {}, General_Error.Not_Exist
	}
	return entry, nil
}

// Note(flysand): Not sure which way it's better to get the executable path:
// via toolhelp snapshots or by reading other process' PEB memory. I have
// a slight suspicion that if both exe path and command line are desired,
// it's faster to just read both from PEB, but maybe the toolhelp snapshots
// are just better...?
@(private)
_process_exe_by_pid :: proc(pid: int, allocator: runtime.Allocator) -> (string, Error) {
	snap := windows.CreateToolhelp32Snapshot(
		windows.TH32CS_SNAPMODULE|windows.TH32CS_SNAPMODULE32,
		u32(pid),
	)
	if snap == windows.INVALID_HANDLE_VALUE {
		return "", _get_platform_error()
	}
	defer windows.CloseHandle(snap)
	entry := windows.MODULEENTRY32W { dwSize = size_of(windows.MODULEENTRY32W) }
	status := windows.Module32FirstW(snap, &entry)
	if !status {
		return "", _get_platform_error()
	}
	exe_path, err := windows.wstring_to_utf8(raw_data(entry.szExePath[:]), -1,  allocator)
	if err != nil {
		return "", err
	}
	return exe_path, nil
}

@(private)
_get_process_user :: proc(process_handle: windows.HANDLE, allocator: runtime.Allocator) -> (full_username: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	token_handle: windows.HANDLE = ---
	if !windows.OpenProcessToken(process_handle, windows.TOKEN_QUERY, &token_handle) {
		err = _get_platform_error()
		return
	}
	token_user_size: u32 = ---
	if !windows.GetTokenInformation(token_handle, .TokenUser, nil, 0, &token_user_size) {
		// Note(flysand): Make sure the buffer too small error comes out, and not any other error
		err = _get_platform_error()
		if v, ok := err.(Platform_Error); !ok || int(v) != 0x7a {
			return
		}
	}
	token_user := cast(^windows.TOKEN_USER) raw_data(make([]u8, token_user_size, temp_allocator()))
	if !windows.GetTokenInformation(token_handle, .TokenUser, token_user, token_user_size, &token_user_size) {
		err = _get_platform_error()
		return
	}
	sid_type: windows.SID_NAME_USE = ---
	username_w: [256]u16 = ---
	domain_w: [256]u16 = ---
	username_chrs: u32 = 256
	domain_chrs: u32 = 256
	if !windows.LookupAccountSidW(nil, token_user.User.Sid, &username_w[0], &username_chrs, &domain_w[0], &domain_chrs, &sid_type) {
		err = _get_platform_error()
		return
	}
	username, username_err := windows.utf16_to_utf8(username_w[:username_chrs], temp_allocator())
	if username_err != nil {
		err = username_err
		return
	}
	domain, domain_err := windows.utf16_to_utf8(domain_w[:domain_chrs], temp_allocator())
	if domain_err != nil {
		err = domain_err
		return
	}
	full_name, full_name_err := strings.concatenate([]string {domain, "\\", username}, allocator)
	if full_name_err != nil {
		err = full_name_err
		return
	}
	return full_name, nil
}

@(private)
_parse_command_line :: proc(cmd_line_w: [^]u16, allocator: runtime.Allocator) -> ([]string, Error) {
	argc: i32 = ---
	argv_w := windows.CommandLineToArgvW(cmd_line_w, &argc)
	if argv_w == nil {
		return nil, _get_platform_error()
	}
	argv, argv_err := make([]string, argc, allocator)
	if argv_err != nil {
		return nil, argv_err
	}
	for arg_w, i in argv_w[:argc] {
		arg, arg_err := windows.wstring_to_utf8(arg_w, -1, allocator)
		if arg_err != nil {
			for s in argv[:i] {
				delete(s, allocator)
			}
			delete(argv, allocator)
			return nil, arg_err
		}
		argv[i] = arg
	}
	return argv, nil
}

@(private)
_build_command_line :: proc(command: []string, allocator: runtime.Allocator) -> string {
	_write_byte_n_times :: #force_inline proc(builder: ^strings.Builder, b: byte, n: int) {
		for _ in 0 ..< n {
			strings.write_byte(builder, b)
		}
	}
	builder := strings.builder_make(allocator)
	for arg, i in command {
		if i != 0 {
			strings.write_byte(&builder, ' ')
		}
		j := 0
		strings.write_byte(&builder, '"')
		for j < len(arg) {
			backslashes := 0
			for j < len(arg) && arg[j] == '\\' {
				backslashes += 1
				j += 1
			}
			if j == len(arg) {
				_write_byte_n_times(&builder, '\\', 2*backslashes)
				break
			} else if arg[j] == '"' {
				_write_byte_n_times(&builder, '\\', 2*backslashes+1)
				strings.write_byte(&builder, '"')
			} else {
				_write_byte_n_times(&builder, '\\', backslashes)
				strings.write_byte(&builder, arg[j])
			}
			j += 1
		}
		strings.write_byte(&builder, '"')
	}
	return strings.to_string(builder)
}

@(private)
_parse_environment_block :: proc(block: [^]u16, allocator: runtime.Allocator) -> ([]string, Error) {
	zt_count := 0
	for idx := 0; true; {
		if block[idx] == 0x0000 {
			zt_count += 1
			if block[idx+1] == 0x0000 {
				zt_count += 1
				break
			}
		}
		idx += 1
	}
	// Note(flysand): Each string in the environment block is terminated
	// by a NUL character. In addition, the environment block itself is
	// terminated by a NUL character. So the number of strings in the
	// environment block is the number of NUL character minus the
	// block terminator.
	env_count := zt_count - 1
	envs := make([]string, env_count, allocator)
	env_idx := 0
	last_idx := 0
	idx := 0
	for block[idx] != 0x0000 {
		for block[idx] != 0x0000 {
			idx += 1
		}
		env_w := block[last_idx:idx]
		env, env_err := windows.utf16_to_utf8(env_w, allocator)
		if env_err != nil {
			return nil, env_err
		}
		envs[env_idx] = env
		env_idx += 1
		idx += 1
		last_idx = idx
	}
	return envs, nil
}

@(private)
_build_environment_block :: proc(environment: []string, allocator: runtime.Allocator) -> string {
	builder := strings.builder_make(allocator)
	#reverse for kv, cur_idx in environment {
		eq_idx := strings.index_byte(kv, '=')
		assert(eq_idx != -1, "Malformed environment string. Expected '=' to separate keys and values")
		key := kv[:eq_idx]
		already_handled := false
		for old_kv in environment[cur_idx+1:] {
			old_key := old_kv[:strings.index_byte(old_kv, '=')]
			if key == old_key {
				already_handled = true
				break
			}
		}
		if already_handled {
			continue
		}
		strings.write_bytes(&builder, transmute([]byte) kv)
		strings.write_byte(&builder, 0)
	}
	// Note(flysand): In addition to the NUL-terminator for each string, the
	// environment block itself is NUL-terminated.
	strings.write_byte(&builder, 0)
	return strings.to_string(builder)
}

@(private="file")
PROCESSINFOCLASS :: enum i32 {
    ProcessBasicInformation = 0,
	ProcessDebugPort = 7,
    ProcessWow64Information = 26,
	ProcessImageFileName = 27,
	ProcessBreakOnTermination = 29,
	ProcessTelemetryIdInformation = 64,
	ProcessSubsystemInformation = 75,
}

@(private="file")
NtQueryInformationProcess_T :: #type proc (
    ProcessHandle: windows.HANDLE,
    ProcessInformationClass: PROCESSINFOCLASS,
    ProcessInformation: rawptr,
    ProcessInformationLength: u32,
    ReturnLength: ^u32,
) -> u32

@(private="file")
PROCESS_BASIC_INFORMATION :: struct {
    _: rawptr,
    PebBaseAddress: ^PEB,
    _: [2]rawptr,
    UniqueProcessId: ^u32,
    _: rawptr,
}

@(private="file")
PEB :: struct {
    _: [2]u8,
    BeingDebugged: u8,
    _: [1]u8,
    _: [2]rawptr,
    Ldr: ^PEB_LDR_DATA,
    ProcessParameters: ^RTL_USER_PROCESS_PARAMETERS,
    _: [104]u8,
    _: [52]rawptr,
    PostProcessInitRoutine: #type proc "stdcall" (),
    _: [128]u8,
    _: [1]rawptr,
    SessionId: u32,
}

@(private="file")
PEB_LDR_DATA :: struct {
    _: [8]u8,
    _: [3]rawptr,
    InMemoryOrderModuleList: LIST_ENTRY,
}

@(private="file")
RTL_USER_PROCESS_PARAMETERS :: struct {
	MaximumLength: u32,
	Length: u32,
	Flags: u32,
	DebugFlags: u32,
	ConsoleHandle: rawptr,
	ConsoleFlags: u32,
	StdInputHandle: rawptr,
	StdOutputHandle: rawptr,
	StdErrorHandle: rawptr,
	CurrentDirectoryPath: UNICODE_STRING,
	CurrentDirectoryHandle: rawptr,
	DllPath: UNICODE_STRING,
    ImagePathName: UNICODE_STRING,
    CommandLine: UNICODE_STRING,
	Environment: rawptr,
	StartingPositionLeft: u32,
	StartingPositionTop: u32,
	Width: u32,
	Height: u32,
	CharWidth: u32,
	CharHeight: u32,
	ConsoleTextAttributes: u32,
	WindowFlags: u32,
	ShowWindowFlags: u32,
	WindowTitle: UNICODE_STRING,
	DesktopName: UNICODE_STRING,
	ShellInfo: UNICODE_STRING,
	RuntimeData: UNICODE_STRING,
	DLCurrentDirectory: [32]RTL_DRIVE_LETTER_CURDIR,
	EnvironmentSize: u32,
}

RTL_DRIVE_LETTER_CURDIR :: struct {
	Flags: u16,
	Length: u16,
	TimeStamp: u32,
	DosPath: UNICODE_STRING,
}

@(private="file")
UNICODE_STRING :: struct {
    Length: u16,
    MaximumLength: u16,
    Buffer: [^]u16,
}

@(private="file")
LIST_ENTRY :: struct {
	Flink: ^LIST_ENTRY,
	Blink: ^LIST_ENTRY,
}