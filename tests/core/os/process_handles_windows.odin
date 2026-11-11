#+build windows
package tests_core_os

import "core:os"
import "core:strings"
import "core:testing"

// A child that held the write end of a pipe of this process would keep the
// read end from reaching its end until the child exits.
@(test)
test_process_start_child_holds_no_other_handle :: proc(t: ^testing.T) {
	r, w, pipe_err := os.pipe()
	if !testing.expect_value(t, pipe_err, nil) {
		return
	}
	defer os.close(r)
	stdin_r, stdin_w, stdin_pipe_err := os.pipe()
	if !testing.expect_value(t, stdin_pipe_err, nil) {
		os.close(w)
		return
	}
	defer os.close(stdin_w)

	// `sort` waits for the end of its input, which this test never closes.
	process, start_err := os.process_start({command = {"sort"}, stdin = stdin_r})
	os.close(stdin_r)
	os.close(w)
	if !testing.expect_value(t, start_err, nil) {
		return
	}

	// With no write end left, the read end is broken.
	_, has_data_err := os.pipe_has_data(r)
	testing.expect_value(t, has_data_err, os.Error(os.General_Error.Broken_Pipe))

	testing.expect_value(t, os.process_kill(process), nil)
	_, wait_err := os.process_wait(process)
	testing.expect_value(t, wait_err, nil)
}

@(test)
test_process_start_same_file_for_stdout_and_stderr :: proc(t: ^testing.T) {
	r, w, pipe_err := os.pipe()
	if !testing.expect_value(t, pipe_err, nil) {
		return
	}
	defer os.close(r)

	process, start_err := os.process_start({
		command = {"cmd", "/d", "/c", "echo out& echo err>&2"},
		stdout  = w,
		stderr  = w,
	})
	os.close(w)
	if !testing.expect_value(t, start_err, nil) {
		return
	}

	output: [dynamic]byte
	defer delete(output)
	buf: [256]byte
	for {
		n, read_err := os.read(r, buf[:])
		append(&output, ..buf[:n])
		if read_err != nil || n == 0 {
			break
		}
	}
	state, wait_err := os.process_wait(process)
	testing.expect_value(t, wait_err, nil)
	testing.expect_value(t, state.exit_code, 0)
	testing.expect_value(t, strings.trim_space(string(output[:])), "out\r\nerr")
}
