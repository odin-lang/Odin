#+private file
package os2

import "base:runtime"

import "core:strings"
import win32 "core:sys/windows"
import "core:time"

@(private="package")
_exit :: proc "contextless" (code: int) -> ! {
	win32.ExitProcess(u32(code))
}

@(private="package")
_get_uid :: proc() -> int {
	return -1
}

@(private="package")
_get_euid :: proc() -> int {
	return -1
}

@(private="package")
_get_gid :: proc() -> int {
	return -1
}

@(private="package")
_get_egid :: proc() -> int {
	return -1
}

@(private="package")
_get_pid :: proc() -> int {
	return int(win32.GetCurrentProcessId())
}

@(private="package")
_get_ppid :: proc() -> int {
	our_pid := win32.GetCurrentProcessId()
	snap := win32.CreateToolhelp32Snapshot(win32.TH32CS_SNAPPROCESS, 0)
	if snap == win32.INVALID_HANDLE_VALUE {
		return -1
	}
	defer win32.CloseHandle(snap)
	entry := win32.PROCESSENTRY32W { dwSize = size_of(win32.PROCESSENTRY32W) }
	for status := win32.Process32FirstW(snap, &entry); status; /**/ {
		if entry.th32ProcessID == our_pid {
			return int(entry.th32ParentProcessID)
		}
		status = win32.Process32NextW(snap, &entry)
	}
	return -1
}

@(private="package")
_process_list :: proc(allocator: runtime.Allocator) -> (list: []int, err: Error) {
	snap := win32.CreateToolhelp32Snapshot(win32.TH32CS_SNAPPROCESS, 0)
	if snap == win32.INVALID_HANDLE_VALUE {
		err = _get_platform_error()
		return
	}

	list_d := make([dynamic]int, allocator) or_return

	entry := win32.PROCESSENTRY32W{dwSize = size_of(win32.PROCESSENTRY32W)}
	status := win32.Process32FirstW(snap, &entry)
	for status {
		append(&list_d, int(entry.th32ProcessID))
		status = win32.Process32NextW(snap, &entry)
	}
	list = list_d[:]
	return
}

@(require_results)
read_memory_as_struct :: proc(h: win32.HANDLE, addr: rawptr, dest: ^$T) -> (bytes_read: uint, err: Error) {
	if !win32.ReadProcessMemory(h, addr, dest, size_of(T), &bytes_read) {
		err = _get_platform_error()
	}
	return
}
@(require_results)
read_memory_as_slice :: proc(h: win32.HANDLE, addr: rawptr, dest: []$T) -> (bytes_read: uint, err: Error) {
	if !win32.ReadProcessMemory(h, addr, raw_data(dest), len(dest)*size_of(T), &bytes_read) {
		err = _get_platform_error()
	}
	return
}

@(private="package")
_process_info_by_pid :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	info.pid = pid
	// Note(flysand): Open the process handle right away to prevent some race
	// conditions. Once the handle is open, the process will be kept alive by
	// the OS.
	ph := win32.INVALID_HANDLE_VALUE
	if selection >= {.Command_Line, .Environment, .Working_Dir, .Username} {
		ph = win32.OpenProcess(
			win32.PROCESS_QUERY_LIMITED_INFORMATION | win32.PROCESS_VM_READ,
			false,
			u32(pid),
		)
		if ph == win32.INVALID_HANDLE_VALUE {
			err = _get_platform_error()
			return
		}
	}
	defer if ph != win32.INVALID_HANDLE_VALUE {
		win32.CloseHandle(ph)
	}
	snapshot_process: if selection >= {.PPid, .Priority} {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = entry_err
			if entry_err == General_Error.Not_Exist {
				return
			} else {
				break snapshot_process
			}
		}
		if .PPid in selection {
			info.fields += {.PPid}
			info.ppid = int(entry.th32ParentProcessID)
		}
		if .Priority in selection {
			info.fields += {.Priority}
			info.priority = int(entry.pcPriClassBase)
		}
	}
	snapshot_modules: if .Executable_Path in selection {
		exe_path: string
		exe_path, err = _process_exe_by_pid(pid, allocator)
		if _, ok := err.(runtime.Allocator_Error); ok {
			return
		} else if err != nil {
			break snapshot_modules
		}
		info.executable_path = exe_path
		info.fields += {.Executable_Path}
	}
	read_peb: if selection >= {.Command_Line, .Environment, .Working_Dir} {
		process_info_size: u32
		process_info: win32.PROCESS_BASIC_INFORMATION
		status := win32.NtQueryInformationProcess(ph, .ProcessBasicInformation, &process_info, size_of(process_info), &process_info_size)
		if status != 0 {
			// TODO(flysand): There's probably a mismatch between NTSTATUS and
			// windows userland error codes, I haven't checked.
			err = Platform_Error(status)
			break read_peb
		}
		assert(process_info.PebBaseAddress != nil)
		process_peb: win32.PEB
		_, err = read_memory_as_struct(ph, process_info.PebBaseAddress, &process_peb)
		if err != nil {
			break read_peb
		}
		process_params: win32.RTL_USER_PROCESS_PARAMETERS
		_, err = read_memory_as_struct(ph, process_peb.ProcessParameters, &process_params)
		if err != nil {
			break read_peb
		}
		if selection >= {.Command_Line, .Command_Args} {
			TEMP_ALLOCATOR_GUARD()
			cmdline_w := make([]u16, process_params.CommandLine.Length, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.CommandLine.Buffer, cmdline_w)
			if err != nil {
				break read_peb
			}
			if .Command_Line in selection {
				info.command_line = win32_utf16_to_utf8(cmdline_w, allocator) or_return
				info.fields += {.Command_Line}
			}
			if .Command_Args in selection {
				info.command_args = _parse_command_line(raw_data(cmdline_w), allocator) or_return
				info.fields += {.Command_Args}
			}
		}
		if .Environment in selection {
			TEMP_ALLOCATOR_GUARD()
			env_len := process_params.EnvironmentSize / 2
			envs_w := make([]u16, env_len, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.Environment, envs_w)
			if err != nil {
				break read_peb
			}
			info.environment = _parse_environment_block(raw_data(envs_w), allocator) or_return
			info.fields += {.Environment}
		}
		if .Working_Dir in selection {
			TEMP_ALLOCATOR_GUARD()
			cwd_w := make([]u16, process_params.CurrentDirectoryPath.Length, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.CurrentDirectoryPath.Buffer, cwd_w)
			if err != nil {
				break read_peb
			}
			info.working_dir = win32_utf16_to_utf8(cwd_w, allocator) or_return
			info.fields += {.Working_Dir}
		}
	}
	read_username: if .Username in selection {
		username: string
		username, err = _get_process_user(ph, allocator)
		if _, ok := err.(runtime.Allocator_Error); ok {
			return
		} else if err != nil {
			break read_username
		}
		info.username = username
		info.fields += {.Username}
	}
	err = nil
	return
}

@(private="package")
_process_info_by_handle :: proc(process: Process, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	pid := process.pid
	info.pid = pid
	// Data obtained from process snapshots
	snapshot_process: if selection >= {.PPid, .Priority} {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = entry_err
			if entry_err == General_Error.Not_Exist {
				return
			} else {
				break snapshot_process
			}
		}
		if .PPid in selection {
			info.fields += {.PPid}
			info.ppid = int(entry.th32ParentProcessID)
		}
		if .Priority in selection {
			info.fields += {.Priority}
			info.priority = int(entry.pcPriClassBase)
		}
	}
	snapshot_module: if .Executable_Path in selection {
		exe_path: string
		exe_path, err = _process_exe_by_pid(pid, allocator)
		if _, ok := err.(runtime.Allocator_Error); ok {
			return
		} else if err != nil {
			break snapshot_module
		}
		info.executable_path = exe_path
		info.fields += {.Executable_Path}
	}
	ph := win32.HANDLE(process.handle)
	read_peb: if selection >= {.Command_Line, .Environment, .Working_Dir} {
		process_info_size: u32
		process_info: win32.PROCESS_BASIC_INFORMATION
		status := win32.NtQueryInformationProcess(ph, .ProcessBasicInformation, &process_info, size_of(process_info), &process_info_size)
		if status != 0 {
			// TODO(flysand): There's probably a mismatch between NTSTATUS and
			// windows userland error codes, I haven't checked.
			err = Platform_Error(status)
			return
		}
		assert(process_info.PebBaseAddress != nil)
		process_peb: win32.PEB
		_, err = read_memory_as_struct(ph, process_info.PebBaseAddress, &process_peb)
		if err != nil {
			break read_peb
		}
		process_params: win32.RTL_USER_PROCESS_PARAMETERS
		_, err = read_memory_as_struct(ph, process_peb.ProcessParameters, &process_params)
		if err != nil {
			break read_peb
		}
		if selection >= {.Command_Line, .Command_Args} {
			TEMP_ALLOCATOR_GUARD()
			cmdline_w := make([]u16, process_params.CommandLine.Length, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.CommandLine.Buffer, cmdline_w)
			if err != nil {
				break read_peb
			}
			if .Command_Line in selection {
				info.command_line = win32_utf16_to_utf8(cmdline_w, allocator) or_return
				info.fields += {.Command_Line}
			}
			if .Command_Args in selection {
				info.command_args = _parse_command_line(raw_data(cmdline_w), allocator) or_return
				info.fields += {.Command_Args}
			}
		}
		if .Environment in selection {
			TEMP_ALLOCATOR_GUARD()
			env_len := process_params.EnvironmentSize / 2
			envs_w := make([]u16, env_len, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.Environment, envs_w)
			if err != nil {
				break read_peb
			}
			info.environment =  _parse_environment_block(raw_data(envs_w), allocator) or_return
			info.fields += {.Environment}
		}
		if .Working_Dir in selection {
			TEMP_ALLOCATOR_GUARD()
			cwd_w := make([]u16, process_params.CurrentDirectoryPath.Length, temp_allocator()) or_return
			_, err = read_memory_as_slice(ph, process_params.CurrentDirectoryPath.Buffer, cwd_w)
			if err != nil {
				break read_peb
			}
			info.working_dir = win32_utf16_to_utf8(cwd_w, allocator) or_return
			info.fields += {.Working_Dir}
		}
	}
	read_username: if .Username in selection {
		username: string
		username, err = _get_process_user(ph, allocator)
		if _, ok := err.(runtime.Allocator_Error); ok {
			return
		} else if err != nil {
			break read_username
		}
		info.username = username
		info.fields += {.Username}
	}
	err = nil
	return
}

@(private="package")
_current_process_info :: proc(selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	info.pid = get_pid()
	snapshot_process: if selection >= {.PPid, .Priority} {
		entry, entry_err := _process_entry_by_pid(info.pid)
		if entry_err != nil {
			err = entry_err
			if entry_err == General_Error.Not_Exist {
				return
			} else {
				break snapshot_process
			}
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
	module_filename: if .Executable_Path in selection {
		exe_filename_w: [256]u16
		path_len := win32.GetModuleFileNameW(nil, raw_data(exe_filename_w[:]), len(exe_filename_w))
		assert(path_len > 0)
		info.executable_path = win32_utf16_to_utf8(exe_filename_w[:path_len], allocator) or_return
		info.fields += {.Executable_Path}
	}
	command_line: if selection >= {.Command_Line,  .Command_Args} {
		command_line_w := win32.GetCommandLineW()
		assert(command_line_w != nil)
		if .Command_Line in selection {
			info.command_line = win32_wstring_to_utf8(command_line_w, allocator) or_return
			info.fields += {.Command_Line}
		}
		if .Command_Args in selection {
			info.command_args = _parse_command_line(command_line_w, allocator) or_return
			info.fields += {.Command_Args}
		}
	}
	read_environment: if .Environment in selection {
		env_block := win32.GetEnvironmentStringsW()
		assert(env_block != nil)
		info.environment = _parse_environment_block(env_block, allocator) or_return
		info.fields += {.Environment}
	}
	read_username: if .Username in selection {
		process_handle := win32.GetCurrentProcess()
		username: string
		username, err = _get_process_user(process_handle, allocator)
		if _, ok := err.(runtime.Allocator_Error); ok {
			return
		} else if err != nil {
			break read_username
		}
		info.username = username
		info.fields += {.Username}
	}
	if .Working_Dir in selection {
		// TODO(flysand): Implement this by reading PEB
		err = .Mode_Not_Implemented
		return
	}
	err = nil
	return
}

@(private="package")
_process_open :: proc(pid: int, flags: Process_Open_Flags) -> (process: Process, err: Error) {
	// Note(flysand): The handle will be used for querying information so we
	// take the necessary permissions right away.
	dwDesiredAccess := win32.PROCESS_QUERY_LIMITED_INFORMATION | win32.SYNCHRONIZE
	if .Mem_Read in flags {
		dwDesiredAccess |= win32.PROCESS_VM_READ
	}
	if .Mem_Write in flags {
		dwDesiredAccess |= win32.PROCESS_VM_WRITE
	}
	handle := win32.OpenProcess(
		dwDesiredAccess,
		false,
		u32(pid),
	)
	if handle == win32.INVALID_HANDLE_VALUE {
		err = _get_platform_error()
	} else {
		process = {pid = pid, handle = uintptr(handle)}
	}
	return
}

@(private="package")
_Sys_Process_Attributes :: struct {}

@(private="package")
_process_start :: proc(desc: Process_Desc) -> (process: Process, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	command_line   := _build_command_line(desc.command, temp_allocator())
	command_line_w := win32_utf8_to_wstring(command_line, temp_allocator()) or_return
	environment := desc.env
	if desc.env == nil {
		environment = environ(temp_allocator())
	}
	environment_block   := _build_environment_block(environment, temp_allocator())
	environment_block_w := win32_utf8_to_utf16(environment_block, temp_allocator()) or_return
	stderr_handle       := win32.GetStdHandle(win32.STD_ERROR_HANDLE)
	stdout_handle       := win32.GetStdHandle(win32.STD_OUTPUT_HANDLE)
	stdin_handle        := win32.GetStdHandle(win32.STD_INPUT_HANDLE)

	if desc.stdout != nil {
		stdout_handle = win32.HANDLE((^File_Impl)(desc.stdout.impl).fd)
	}
	if desc.stderr != nil {
		stderr_handle = win32.HANDLE((^File_Impl)(desc.stderr.impl).fd)
	}
	if desc.stdin != nil {
		stdin_handle = win32.HANDLE((^File_Impl)(desc.stdin.impl).fd)
	}

	working_dir_w := (win32_utf8_to_wstring(desc.working_dir, temp_allocator()) or_else nil) if len(desc.working_dir) > 0 else nil
	process_info: win32.PROCESS_INFORMATION
	ok := win32.CreateProcessW(
		nil,
		command_line_w,
		nil,
		nil,
		true,
		win32.CREATE_UNICODE_ENVIRONMENT|win32.NORMAL_PRIORITY_CLASS,
		raw_data(environment_block_w),
		working_dir_w,
		&win32.STARTUPINFOW{
			cb = size_of(win32.STARTUPINFOW),
			hStdError  = stderr_handle,
			hStdOutput = stdout_handle,
			hStdInput  = stdin_handle,
			dwFlags = win32.STARTF_USESTDHANDLES,
		},
		&process_info,
	)
	if !ok {
		err = _get_platform_error()
		return
	}
	process = {pid = int(process_info.dwProcessId), handle = uintptr(process_info.hProcess)}
	return
}

@(private="package")
_process_wait :: proc(process: Process, timeout: time.Duration) -> (process_state: Process_State, err: Error) {
	handle := win32.HANDLE(process.handle)
	timeout_ms := u32(timeout / time.Millisecond) if timeout >= 0 else win32.INFINITE

	switch win32.WaitForSingleObject(handle, timeout_ms) {
	case win32.WAIT_OBJECT_0:
		exit_code: u32
		if !win32.GetExitCodeProcess(handle, &exit_code) {
			err =_get_platform_error()
			return
		}
		time_created: win32.FILETIME
		time_exited: win32.FILETIME
		time_kernel: win32.FILETIME
		time_user: win32.FILETIME
		if !win32.GetProcessTimes(handle, &time_created, &time_exited, &time_kernel, &time_user) {
			err = _get_platform_error()
			return
		}
		process_state = {
			exit_code   = int(exit_code),
			exited      = true,
			pid         = process.pid,
			success     = true,
			system_time = _filetime_to_duration(time_kernel),
			user_time   = _filetime_to_duration(time_user),
		}
		return
	case win32.WAIT_TIMEOUT:
		err = General_Error.Timeout
		return
	case:
		err = _get_platform_error()
		return
	}
}

@(private="package")
_process_close :: proc(process: Process) -> Error {
	if !win32.CloseHandle(win32.HANDLE(process.handle)) {
		return _get_platform_error()
	}
	return nil
}

@(private="package")
_process_kill :: proc(process: Process) -> Error {
	// Note(flysand): This is different than what the task manager's "kill process"
	// functionality does, as we don't try to send WM_CLOSE message first. This
	// is quite a rough way to kill the process, which should be consistent with
	// linux. The error code 9 is to mimic SIGKILL event.
	if !win32.TerminateProcess(win32.HANDLE(process.handle), 9) {
		return _get_platform_error()
	}
	return nil
}

_filetime_to_duration :: proc(filetime: win32.FILETIME) -> time.Duration {
	ticks := u64(filetime.dwHighDateTime)<<32 | u64(filetime.dwLowDateTime)
	return time.Duration(ticks * 100)
}

_process_entry_by_pid :: proc(pid: int) -> (entry: win32.PROCESSENTRY32W, err: Error) {
	snap := win32.CreateToolhelp32Snapshot(win32.TH32CS_SNAPPROCESS, 0)
	if snap == win32.INVALID_HANDLE_VALUE {
		err = _get_platform_error()
		return
	}
	defer win32.CloseHandle(snap)

	entry = win32.PROCESSENTRY32W{dwSize = size_of(win32.PROCESSENTRY32W)}
	status := win32.Process32FirstW(snap, &entry)
	for status {
		if u32(pid) == entry.th32ProcessID {
			return
		}
		status = win32.Process32NextW(snap, &entry)
	}
	err = General_Error.Not_Exist
	return
}

// Note(flysand): Not sure which way it's better to get the executable path:
// via toolhelp snapshots or by reading other process' PEB memory. I have
// a slight suspicion that if both exe path and command line are desired,
// it's faster to just read both from PEB, but maybe the toolhelp snapshots
// are just better...?
@(private="package")
_process_exe_by_pid :: proc(pid: int, allocator: runtime.Allocator) -> (exe_path: string, err: Error) {
	snap := win32.CreateToolhelp32Snapshot(
		win32.TH32CS_SNAPMODULE|win32.TH32CS_SNAPMODULE32,
		u32(pid),
	)
	if snap == win32.INVALID_HANDLE_VALUE {
		err =_get_platform_error()
		return
	}
	defer win32.CloseHandle(snap)

	entry := win32.MODULEENTRY32W { dwSize = size_of(win32.MODULEENTRY32W) }
	status := win32.Module32FirstW(snap, &entry)
	if !status {
		err =_get_platform_error()
		return
	}
	return win32_wstring_to_utf8(raw_data(entry.szExePath[:]), allocator)
}

_get_process_user :: proc(process_handle: win32.HANDLE, allocator: runtime.Allocator) -> (full_username: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	token_handle: win32.HANDLE
	if !win32.OpenProcessToken(process_handle, win32.TOKEN_QUERY, &token_handle) {
		err = _get_platform_error()
		return
	}
	token_user_size: u32
	if !win32.GetTokenInformation(token_handle, .TokenUser, nil, 0, &token_user_size) {
		// Note(flysand): Make sure the buffer too small error comes out, and not any other error
		err = _get_platform_error()
		if v, ok := is_platform_error(err); !ok || v != i32(win32.ERROR_INSUFFICIENT_BUFFER) {
			return
		}
		err = nil
	}
	token_user := (^win32.TOKEN_USER)(raw_data(make([]u8, token_user_size, temp_allocator()) or_return))
	if !win32.GetTokenInformation(token_handle, .TokenUser, token_user, token_user_size, &token_user_size) {
		err = _get_platform_error()
		return
	}

	sid_type: win32.SID_NAME_USE
	username_w: [256]u16
	domain_w:   [256]u16
	username_chrs := u32(256)
	domain_chrs   := u32(256)

	if !win32.LookupAccountSidW(nil, token_user.User.Sid, &username_w[0], &username_chrs, &domain_w[0], &domain_chrs, &sid_type) {
		err = _get_platform_error()
		return
	}
	username := win32_utf16_to_utf8(username_w[:username_chrs], temp_allocator()) or_return
	domain   := win32_utf16_to_utf8(domain_w[:domain_chrs], temp_allocator()) or_return
	return strings.concatenate({domain, "\\", username}, allocator)
}

_parse_command_line :: proc(cmd_line_w: [^]u16, allocator: runtime.Allocator) -> (argv: []string, err: Error) {
	argc: i32
	argv_w := win32.CommandLineToArgvW(cmd_line_w, &argc)
	if argv_w == nil {
		return nil, _get_platform_error()
	}
	argv = make([]string, argc, allocator) or_return
	defer if err != nil {
		for arg in argv {
			delete(arg, allocator)
		}
		delete(argv, allocator)
	}
	for arg_w, i in argv_w[:argc] {
		argv[i] = win32_wstring_to_utf8(arg_w, allocator) or_return
	}
	return
}

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
		if strings.contains_any(arg, "()[]{}^=;!'+,`~\" ") {
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
					strings.write_byte(&builder, arg[j])
				} else {
					_write_byte_n_times(&builder, '\\', backslashes)
					strings.write_byte(&builder, arg[j])
				}
				j += 1
			}
			strings.write_byte(&builder, '"')
		} else {
			strings.write_string(&builder, arg)
		}
	}
	return strings.to_string(builder)
}

_parse_environment_block :: proc(block: [^]u16, allocator: runtime.Allocator) -> (envs: []string, err: Error) {
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
	envs = make([]string, env_count, allocator) or_return
	defer if err != nil {
		for env in envs {
			delete(env, allocator)
		}
		delete(envs, allocator)
	}

	env_idx := 0
	last_idx := 0
	idx := 0
	for block[idx] != 0x0000 {
		for block[idx] != 0x0000 {
			idx += 1
		}
		env_w := block[last_idx:idx]
		envs[env_idx] = win32_utf16_to_utf8(env_w, allocator) or_return
		env_idx += 1
		idx += 1
		last_idx = idx
	}
	return
}

_build_environment_block :: proc(environment: []string, allocator: runtime.Allocator) -> string {
	builder := strings.builder_make(allocator)
	loop: #reverse for kv, cur_idx in environment {
		eq_idx := strings.index_byte(kv, '=')
		assert(eq_idx >= 0, "Malformed environment string. Expected '=' to separate keys and values")
		key := kv[:eq_idx]
		for old_kv in environment[cur_idx+1:] {
			old_key := old_kv[:strings.index_byte(old_kv, '=')]
			if key == old_key {
				continue loop
			}
		}
		strings.write_string(&builder, kv)
		strings.write_byte(&builder, 0)
	}
	// Note(flysand): In addition to the NUL-terminator for each string, the
	// environment block itself is NUL-terminated.
	strings.write_byte(&builder, 0)
	return strings.to_string(builder)
}
