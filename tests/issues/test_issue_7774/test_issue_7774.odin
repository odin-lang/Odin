package test_issue_7774

import "core:c/libc"
import "core:testing"

// The test runner left through `runtime.exit`, which on Linux makes the `exit_group` syscall directly, so nothing
// registered with `atexit` (such as the sanitizer runtimes' finalisers) ran. It now returns from `main` when linked
// against the CRT.

on_exit :: proc "c" () {
	libc.printf("atexit handler ran\n")
}

@(test)
test_atexit_runs :: proc(t: ^testing.T) {
	testing.expect_value(t, libc.atexit(on_exit), 0)
}
