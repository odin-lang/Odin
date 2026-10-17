package tests_core_os

import "core:os"
import "core:slice"
import "core:testing"

@(test)
test_environ :: proc(t: ^testing.T) {
	env, err := os.environ(context.allocator)
	defer delete_environ(env)
	testing.expect_value(t, err, nil)

	for entry, i in env {
		testing.expectf(t, entry != "", "entry %v of the environment is empty", i)
		testing.expectf(t, !slice.contains(env[i + 1:], entry), "%q appears more than once in the environment", entry)
	}
}

delete_environ :: proc(env: []string) {
	for entry in env {
		delete(entry)
	}
	delete(env)
}
