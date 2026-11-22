#+build !windows
package tests_core_os

import "core:os"
import "core:log"
import "core:strings"
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
test_process_exec_inherits_environment :: proc(t: ^testing.T) {
	when ODIN_OS == .Darwin {
		log.info("skipping on darwin, SIP removes DYLD_* variables from the environment of `env`")
		return
	}

	env, env_err := os.environ(context.allocator)
	defer delete_environ(env)
	testing.expect_value(t, env_err, nil)

	expected: strings.Builder
	strings.builder_init(&expected)
	defer strings.builder_destroy(&expected)
	for entry in env {
		strings.write_string(&expected, entry)
		strings.write_byte(&expected, '\n')
	}

	state, stdout, stderr, err := os.process_exec({
		command = {"env"},
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
	testing.expect_value(t, string(stdout), strings.to_string(expected))
	testing.expect_value(t, string(stderr), "")
}
