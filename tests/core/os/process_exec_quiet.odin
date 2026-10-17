package tests_core_os

import "core:log"
import "core:os"
import "core:testing"

// The child writes only after a quiet second, during which `process_exec`
// sleeps between polls of the pipes.
@(test)
test_process_exec_output_after_quiet_period :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		command  := []string{"cmd", "/d", "/c", "ping -n 2 127.0.0.1 >NUL & echo hellope"}
		expected := "hellope\r\n"
	} else {
		command  := []string{"sh", "-c", "sleep 1; echo hellope"}
		expected := "hellope\n"
	}
	state, stdout, stderr, err := os.process_exec({command = command}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited, true)
	testing.expect_value(t, state.exit_code, 0)
	testing.expect_value(t, string(stdout), expected)
	testing.expect_value(t, string(stderr), "")
}
