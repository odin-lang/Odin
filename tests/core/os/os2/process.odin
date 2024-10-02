package tests_core_os_os2

import    "base:runtime"

import    "core:log"
import os "core:os/os2"
import    "core:testing"

_ :: log

@(test)
test_process_exec :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"echo", "hellope"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	when (ODIN_OS not_in runtime.Odin_OS_Types{.Linux, .Darwin, .Windows}) {
		testing.expect_value(t, err, os.General_Error.Unsupported)
		_ = state
	} else {
		testing.expect_value(t, state.exited,  true)
		testing.expect_value(t, state.success, true)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, string(stdout), "hellope\n")
	}
}
