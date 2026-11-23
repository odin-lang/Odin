#+build !windows
package tests_core_os

import "core:os"
import "core:log"
import "core:testing"

@(test)
test_process_exec :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"echo", "hellope"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, state.exited,  true)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(stdout), "hellope\n")
	testing.expect_value(t, string(stderr), "")
}

@(test)
test_process_exit_code :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"sh", "-c", "exit 3"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,    true)
	testing.expect_value(t, state.success,   false)
	testing.expect_value(t, state.exit_code, 3)
	testing.expect_value(t, state.signal,    0)
}

@(test)
test_process_signal :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"sh", "-c", "kill -s KILL $$"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,    true)
	testing.expect_value(t, state.success,   false)
	testing.expect_value(t, state.exit_code, 9)
	testing.expect_value(t, state.signal,    9)
}
