#+build linux, darwin, freebsd, openbsd, netbsd
package test_internal

import "core:testing"

foreign import nested_libc "system:c"

// A foreign block inside a procedure only declares its procedures
@(test)
nested_foreign_block :: proc(t: ^testing.T) {
	foreign nested_libc {
		strlen :: proc "c" (s: cstring) -> uint ---
	}
	testing.expect_value(t, strlen("hellope"), 7)
}
