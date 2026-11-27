#+build windows
package tests_core_os

import "core:log"
import "core:os"
import "core:slice"
import "core:strings"
import win32 "core:sys/windows"
import "core:testing"

@(test)
test_process_command_line_round_trip :: proc(t: ^testing.T) {
	command := []string{"cmd.exe", "/d", "/q", "/k", "rem", "", "a\tb", "two words", `trailing\`, `dir with\`, `in"side`}

	r, w, pipe_err := os.pipe()
	if !testing.expect_value(t, pipe_err, nil) {
		return
	}
	defer os.close(w)

	process, start_err := os.process_start({command = command, stdin = r})
	os.close(r)
	if !testing.expect_value(t, start_err, nil) {
		return
	}

	info, info_err := os.process_info_by_handle(process, {.Command_Args}, context.temp_allocator)
	testing.expect_value(t, os.process_kill(process), nil)
	state, wait_err := os.process_wait(process)

	testing.expect_value(t, info_err, nil)
	testing.expectf(t, slice.equal(info.command_args, command), "got %q", info.command_args)
	testing.expect_value(t, wait_err, nil)
	testing.expect_value(t, state.exit_code, 9)
	testing.expect_value(t, state.signal, 0)
}

@(test)
test_process_open_fails_for_invalid_pid :: proc(t: ^testing.T) {
	// `OpenProcess` refuses pid 0, the System Idle Process.
	process, err := os.process_open(0)
	testing.expect_value(t, err, os.Platform_Error.INVALID_PARAMETER)
	testing.expect_value(t, process.handle, uintptr(0))
}

@(test)
test_process_kill_opened_process :: proc(t: ^testing.T) {
	child, start_err := os.process_start({command = {"ping.exe", "-n", "30", "127.0.0.1"}})
	if !testing.expect_value(t, start_err, nil) {
		return
	}
	// The handle `process_start` returned has every right; it ends the child
	// whatever happens below.
	defer {
		_ = os.process_kill(child)
		_, _ = os.process_wait(child)
	}

	opened, open_err := os.process_open(child.pid)
	if !testing.expect_value(t, open_err, nil) {
		return
	}
	kill_err := os.process_kill(opened)
	testing.expect_value(t, kill_err, nil)
	if kill_err != nil {
		_ = os.process_kill(child)
	}
	state, wait_err := os.process_wait(opened)
	testing.expect_value(t, wait_err, nil)
	testing.expect_value(t, state.exited, true)
	testing.expect_value(t, state.exit_code, 9)
}

// csrss.exe is a protected process: even an administrator may query it but
// not terminate it.
@(test)
test_process_open_without_terminate_right :: proc(t: ^testing.T) {
	snap := win32.CreateToolhelp32Snapshot(win32.TH32CS_SNAPPROCESS, 0)
	if !testing.expect(t, snap != win32.INVALID_HANDLE_VALUE) {
		return
	}
	defer win32.CloseHandle(snap)

	pid := -1
	entry := win32.PROCESSENTRY32W{dwSize = size_of(win32.PROCESSENTRY32W)}
	buf: [len(entry.szExeFile) * 3]u8
	for status := win32.Process32FirstW(snap, &entry); status; status = win32.Process32NextW(snap, &entry) {
		if strings.equal_fold(win32.wstring_to_utf8(buf[:], cstring16(&entry.szExeFile[0])), "csrss.exe") {
			pid = int(entry.th32ProcessID)
			break
		}
	}
	if !testing.expectf(t, pid != -1, "csrss.exe is not running") {
		return
	}

	process, open_err := os.process_open(pid)
	if open_err != nil {
		log.infof("skipping, os.process_open of csrss.exe failed: %v", open_err)
		return
	}
	testing.expect_value(t, os.process_kill(process), os.Error(.Permission_Denied))
	testing.expect(t, win32.CloseHandle(win32.HANDLE(process.handle)) == true)
}
