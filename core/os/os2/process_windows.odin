//+private
package os2

import "base:runtime"
import "core:time"
import "core:sys/windows"
import "core:strings"

L :: windows.L
wstring :: windows.wstring
to_wstring :: windows.utf8_to_wstring

_Process :: struct {
	process: windows.HANDLE,
	thread: windows.HANDLE,
}

_process_open :: proc(desc: Process_Desc) -> (Process, Process_Error) {
	context.allocator = _temp_allocator()
	temp := _temp_allocator_temp_begin()
	defer _temp_allocator_temp_end(temp)
	app_name: wstring = ---
	command_line: wstring = ---
	environment := desc.environment
	switch command in desc.command {
	case string:
		command_line = to_wstring(_build_command_line(
			[]string {
				"cmd.exe",
				"/c",
				command,
			},
		))
	case []string:
		command_line = to_wstring(_build_command_line(command))
	}
	// Note(flysand): The write-ends of output pipes must be inheritable.
	stdout_handle := windows.HANDLE(desc.stdout.impl.fd)
	stderr_handle := windows.HANDLE(desc.stderr.impl.fd)
	windows.SetHandleInformation(stdout_handle, windows.HANDLE_FLAG_INHERIT, 1)
	windows.SetHandleInformation(stderr_handle, windows.HANDLE_FLAG_INHERIT, 1)
	process_info: windows.PROCESS_INFORMATION = ---
	process_ok := windows.CreateProcessW(
		nil,
		command_line,
		nil,
		nil,
		true,
		windows.CREATE_SUSPENDED,
		raw_data(_build_environment_block(desc.environment)),
		nil,
		&windows.STARTUPINFOW {
			cb = size_of(windows.STARTUPINFOW),
			hStdError = stderr_handle,
			hStdOutput = stdout_handle,
			dwFlags = windows.STARTF_USESTDHANDLES,
		},
		&process_info,
	)
	if !process_ok {
		windows_error := windows.GetLastError()
		switch windows_error {
		case windows.ERROR_FILE_NOT_FOUND:
			return {}, .Not_Found
		case:
			return {}, .Unspecified_Error
		}
	}
	return Process {
		_os_data = _Process {
			process = process_info.hProcess,
			thread = process_info.hThread,
		},
		pid = int(process_info.dwProcessId),
	}, .None
}

_process_close :: proc(process: Process) -> (Process_Error) {
	if !windows.CloseHandle(process._os_data.process) {
		return .Unspecified_Error
	}
	if !windows.CloseHandle(process._os_data.thread) {
		return .Unspecified_Error
	}
	return .None
}

_process_start :: proc(process: Process) -> (Process_Error) {
	return windows.ResumeThread(process._os_data.thread) >= 0? .None : .Unspecified_Error
}

_process_suspend :: proc(process: Process) -> (Process_Error) {
	return windows.SuspendThread(process._os_data.thread) >= 0? .None : .Unspecified_Error
}

_process_terminate :: proc(process: Process, code: i32) -> (Process_Error) {
	return windows.TerminateProcess(process._os_data.process, u32(code))? .None : .Unspecified_Error
}

_process_wait :: proc(process: Process, timeout: time.Duration) -> (int, Wait_Status) {
	timeout_ms := u32(timeout / time.Millisecond)
	wait_result := windows.WaitForSingleObject(process._os_data.process, timeout_ms)
	switch wait_result {
	case windows.WAIT_OBJECT_0:
		exit_code: u32 = ---
		windows.GetExitCodeProcess(process._os_data.process, &exit_code)
		return cast(int) i32(exit_code), .Exited
	case windows.WAIT_TIMEOUT:
		return 0, .Timeout
	case:
		return 0, .Error
	}
}

_build_command_line :: proc(command: []string) -> string {
	builder := strings.builder_make()
	for arg, i in command {
		if i != 0 {
			strings.write_byte(&builder, ' ')
		}
		_write_quoted_arg(&builder, arg)
	}
	return strings.to_string(builder)
}

_build_environment_block :: proc(environment: []string) -> string {
	builder := strings.builder_make()
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
	// Note(flysand): Environment block on windows is terminated by two
	// NUL-terminators: one for the string, and one for the array of strings.
	strings.write_byte(&builder, 0)
	return strings.to_string(builder)
}

_write_quoted_arg :: proc(builder: ^strings.Builder, arg: string) {
	i := 0
	strings.write_byte(builder, '"')
	for i < len(arg) {
		backslashes := 0
		for i < len(arg) && arg[i] == '\\' {
			backslashes += 1
			i += 1
		}
		if i == len(arg) {
			_write_byte_n_times(builder, '\\', 2*backslashes)
			break
		} else if arg[i] == '"' {
			_write_byte_n_times(builder, '\\', 2*backslashes+1)
			strings.write_byte(builder, '"')
		} else {
			_write_byte_n_times(builder, '\\', backslashes)
			strings.write_byte(builder, arg[i])
		}
		i += 1
	}
	strings.write_byte(builder, '"')
}

_write_byte_n_times :: #force_inline proc(builder: ^strings.Builder, b: byte, n: int) {
	for _ in 0 ..< n {
		strings.write_byte(builder, b)
	}
}
