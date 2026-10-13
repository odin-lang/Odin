package test_issue_7774

import "core:c/libc"
import "core:os"

// `os.exit` on Linux made the `exit_group` syscall directly, so nothing registered with `atexit` (such as the
// sanitizer runtimes' finalisers) ran. It now leaves through libc's `exit` when linked against it.

on_exit :: proc "c" () {
	libc.printf("atexit handler ran\n")
}

main :: proc() {
	libc.atexit(on_exit)
	os.exit(0)
}
