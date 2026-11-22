#+build !windows
package tests_core_os

import "core:os"
import "core:log"
import "core:testing"
import "core:time"

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
test_process_wait_exit_and_signal :: proc(t: ^testing.T) {
	Case :: struct {
		script:    string,
		exit_code: int,
		signal:    int,
		success:   bool,
	}
	cases := []Case{
		{"exit 0",        0, 0, true},
		{"exit 4",        4, 0, false},
		{"kill -KILL $$", 9, 9, false}, // SIGKILL is 9
	}

	for c in cases {
		for timeout in ([]time.Duration{os.TIMEOUT_INFINITE, 10 * time.Second}) {
			p, err := os.process_start({command = {"/bin/sh", "-c", c.script}})
			if err == .Unsupported {
				log.warn("process_start unsupported")
				return
			}
			if !testing.expect_value(t, err, nil) {
				continue
			}

			state, werr := os.process_wait(p, timeout)
			testing.expect_value(t, werr, nil)
			testing.expectf(t, state.exited, "%q: expected the process to have exited", c.script)
			testing.expectf(t, state.exit_code == c.exit_code, "%q: expected exit_code %d, got %d", c.script, c.exit_code, state.exit_code)
			testing.expectf(t, state.signal == c.signal, "%q: expected signal %d, got %d", c.script, c.signal, state.signal)
			testing.expectf(t, state.success == c.success, "%q: expected success %v, got %v", c.script, c.success, state.success)
		}
	}
}
