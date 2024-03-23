//+build windows
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
	app_name: wstring = ---
	command_line: wstring = ---
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
	startup_info: windows.STARTUPINFOW = ---
	process_info: windows.PROCESS_INFORMATION = ---
	process_ok := windows.CreateProcessW(
		nil,
		command_line,
		nil,
		nil,
		false,
		windows.CREATE_SUSPENDED,
		nil,
		nil,
		&startup_info,
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
	windows.CloseHandle(process._os_data.process)
	windows.CloseHandle(process._os_data.thread)
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
	case windows.WAIT_FAILED:
		return 0, .Error
	case windows.WAIT_TIMEOUT:
		return 0, .Timeout
	}
	exit_code: u32 = ---
	windows.GetExitCodeProcess(process._os_data.process, &exit_code)
	return cast(int) i32(exit_code), .Exited
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

