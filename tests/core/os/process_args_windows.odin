#+build windows
package tests_core_os

import "base:runtime"
import "core:os"
import "core:strings"
import "core:testing"

// The test program is also the child of this test: started with `ARGS_CHILD`
// as its first argument, it writes the other ones to stdout, each followed by
// a NUL, and exits before the tests run.
@(private="file")
ARGS_CHILD :: "tests-core-os-args-child"

@(init, private="file")
args_child :: proc "contextless" () {
	if len(os.args) < 2 || os.args[1] != ARGS_CHILD {
		return
	}
	context = runtime.default_context()
	for arg in os.args[2:] {
		_, _ = os.write_string(os.stdout, arg)
		_, _ = os.write_byte(os.stdout, 0)
	}
	os.exit(0)
}

@(test)
test_process_start_passes_arguments_unchanged :: proc(t: ^testing.T) {
	args := []string{
		"plain",
		"",
		"with space",
		"tab\there",
		"line\nfeed",
		`quote"inside`,
		`trailing\`,
		`two\\`,
		`back\"quote`,
		`\\server\share\`,
		"",
	}
	exe, exe_err := os.get_executable_path(context.temp_allocator)
	testing.expect_value(t, exe_err, nil)
	command := make([dynamic]string, context.temp_allocator)
	append(&command, exe, ARGS_CHILD)
	append(&command, ..args)

	state, stdout, _, err := os.process_exec({command = command[:]}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exit_code, 0)
	received := strings.split(string(stdout), "\x00", context.temp_allocator)
	if !testing.expect_value(t, len(received), len(args) + 1) {
		return
	}
	for arg, i in args {
		testing.expect_value(t, received[i], arg)
	}
}
