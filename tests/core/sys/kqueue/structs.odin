#+build darwin, freebsd, openbsd, netbsd
package tests_core_sys_kqueue

import    "core:strings"
import    "core:testing"
import os "core:os/os2"

@(test)
structs :: proc(t: ^testing.T) {
	{
		c_compiler := os.get_env("CC", context.temp_allocator)
		if c_compiler == "" {
			c_compiler = "clang"
		}

		c_compilation, c_start_err := os.process_start({
			command = {c_compiler, #directory + "/structs/structs.c", "-o", #directory + "/structs/c_structs"},
			stdout = os.stdout,
			stderr = os.stderr,
		})
		testing.expect_value(t, c_start_err, nil)

		o_compilation, o_start_err := os.process_start({
			command = {ODIN_ROOT + "/odin", "build", #directory + "/structs", "-out:" + #directory + "/structs/odin_structs"},
			stdout = os.stdout,
			stderr = os.stderr,
		})
		testing.expect_value(t, o_start_err, nil)

		c_status, c_err := os.process_wait(c_compilation)
		testing.expect_value(t, c_err, nil)
		testing.expect_value(t, c_status.exit_code, 0)

		o_status, o_err := os.process_wait(o_compilation)
		testing.expect_value(t, o_err, nil)
		testing.expect_value(t, o_status.exit_code, 0)
	}

	c_status, c_stdout, c_stderr, c_err := os.process_exec({command={#directory + "/structs/c_structs"}}, context.temp_allocator)
	testing.expect_value(t, c_err, nil)
	testing.expect_value(t, c_status.exit_code, 0)
	testing.expect_value(t, string(c_stderr), "")

	o_status, o_stdout, o_stderr, o_err := os.process_exec({command={#directory + "/structs/odin_structs"}}, context.temp_allocator)
	testing.expect_value(t, o_err, nil)
	testing.expect_value(t, o_status.exit_code, 0)
	testing.expect_value(t, string(o_stderr), "")

	testing.expect(t, strings.trim_space(string(c_stdout)) != "")

	testing.expect_value(
		t,
		strings.trim_space(string(o_stdout)),
		strings.trim_space(string(c_stdout)),
	)
}
