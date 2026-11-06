package tests_core_os

import "base:runtime"
import "core:log"
import "core:os"
import "core:testing"
import "core:time"

// The test program is also the child of this test: started with `QUIET_CHILD`
// as its first argument, it writes only after a pause and exits.
@(private="file")
QUIET_CHILD :: "tests-core-os-quiet-child"

@(init, private="file")
quiet_child :: proc "contextless" () {
	if len(os.args) < 2 || os.args[1] != QUIET_CHILD {
		return
	}
	context = runtime.default_context()
	time.sleep(50 * time.Millisecond)
	_, _ = os.write_string(os.stdout, "hellope")
	os.exit(0)
}

@(test)
test_process_exec_output_after_quiet_period :: proc(t: ^testing.T) {
	exe, exe_err := os.get_executable_path(context.temp_allocator)
	if exe_err == .Unsupported {
		log.warn("get_executable_path unsupported")
		return
	}
	testing.expect_value(t, exe_err, nil)

	state, stdout, stderr, err := os.process_exec({command = {exe, QUIET_CHILD}}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited, true)
	testing.expect_value(t, state.exit_code, 0)
	testing.expect_value(t, string(stdout), "hellope")
	testing.expect_value(t, string(stderr), "")
}
