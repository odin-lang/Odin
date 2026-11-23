#+build windows
package tests_core_os

import "core:os"
import "core:slice"
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
