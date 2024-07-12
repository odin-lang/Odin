//+build windows
package os2

import "core:sys/windows"
import "core:strings"
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

_process_info :: proc(pid: int, selection: Process_Info_Fields, allocator: runtime.Allocator) -> (info: Process_Info, err: Error) {
	info.pid = pid
	need_snapprocess := \
		.PPid in selection ||
		.Priority in selection
	need_snapmodule := \
		.Executable_Path in selection
	need_peb := \
		.Command_Line in selection ||
		.Environment in selection ||
		.CWD in selection
	need_process_handle := need_peb || .Username in selection
	// Data obtained from process snapshots
	if need_snapprocess {
		snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
		if snap == windows.INVALID_HANDLE_VALUE {
			return info, _get_platform_error()
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
	// Note(flysand): Not sure which way it's better to get the executable path:
	// via toolhelp snapshots or by reading other process' PEB memory. I have
	// a slight suspicion that if both exe path and command line are desired,
	// it's faster to just read both from PEB, but maybe the toolhelp snapshots
	// are just better...?
	if need_snapmodule {
		snap := windows.CreateToolhelp32Snapshot(
			windows.TH32CS_SNAPMODULE|windows.TH32CS_SNAPMODULE32,
			u32(pid),
		)
		if snap == windows.INVALID_HANDLE_VALUE {
			err = _get_platform_error()
			return
		}
		defer windows.CloseHandle(snap)
		entry := windows.MODULEENTRY32W { dwSize = size_of(windows.MODULEENTRY32W) }
		status := windows.Module32FirstW(snap, &entry)
		if !status {
			err = _get_platform_error()
			return
		}
		exe_path: string
		exe_path, err = windows.wstring_to_utf8(raw_data(entry.szExePath[:]), -1,  allocator)
		if err != nil {
			return
		}
		info.fields |= {.Executable_Path}
		info.executable_path = exe_path
	}
	defer if .Executable_Path in info.fields && err != nil {
		delete(info.executable_path, allocator)
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
	defer if .CWD in info.fields && err != nil {
		delete(info.cwd, allocator)
	}
	defer if .Environment in info.fields && err != nil {
		for s in info.environment {
			delete(s, allocator)
		}
		delete(info.environment, allocator)
	}
	defer if .Command_Line in info.fields && err != nil {
		delete(info.command_line, allocator)
	}
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
		if .Command_Line in selection {
			TEMP_ALLOCATOR_GUARD()
			cmdline_w := make([]u16, process_params.CommandLine.Length, temp_allocator())
			if !read_slice(ph, process_params.CommandLine.Buffer, cmdline_w, &bytes_read) {
				err = _get_platform_error()
				return
			}
			cmdline, cmdline_err := windows.utf16_to_utf8(cmdline_w, allocator)
			if cmdline_err != nil {
				err = cmdline_err
				return
			}
			info.fields |= {.Command_Line}
			info.command_line = cmdline
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
		if .CWD in selection {
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
			info.fields |= {.CWD}
			info.cwd = cwd
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
	need_snapprocess := .PPid in selection || .Priority in selection
	if need_snapprocess {
		snap := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
		if snap == windows.INVALID_HANDLE_VALUE {
			return
		}
		defer windows.CloseHandle(snap)
		entry := windows.PROCESSENTRY32W { dwSize = size_of(windows.PROCESSENTRY32W) }
		status := windows.Process32FirstW(snap, &entry)
		for status {
			if entry.th32ProcessID == u32(info.pid) {
				break
			}
			status = windows.Process32NextW(snap, &entry)
		}
		if entry.th32ProcessID != u32(info.pid) {
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
	defer if .Executable_Path in selection && err != nil {
		delete(info.executable_path, allocator)
	}
	if .Command_Line in selection {
		command_line_w := windows.GetCommandLineW()
		command_line, command_line_err := windows.wstring_to_utf8(command_line_w, -1, allocator)
		if command_line_err != nil {
			err = command_line_err
			return
		}
		info.fields += {.Command_Line}
		info.command_line = command_line
	}
	defer if .Command_Line in selection && err != nil {
		delete(info.command_line, allocator)
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
	defer if .Environment in selection && err != nil {
		for s in info.environment {
			delete(s, allocator)
		}
		delete(info.environment)
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
	defer if .Username in selection && err != nil {
		delete(info.username)
	}
	err = nil
	return
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