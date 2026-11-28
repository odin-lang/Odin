// A `weak` procedure can be replaced at link time by another body, which may write.
// The read-only analysis trusted the weak body, and a call to it passed a global by value without copying it.
// The replacement then saw its parameter change when it wrote the global.
package test_issues

import "core:testing"

Weak_Big :: struct { a, b, c: int }

@(export, link_name="issue_weak_g_big")
issue_weak_g_big: Weak_Big

foreign import weak_lib "../build/test_issue_weak_read_only_c.o"

@(default_calling_convention="c")
foreign weak_lib {
	issue_weak_linked :: proc() -> i32 --- // pulls the object into the link
}

// Read-only, but test_issue_weak_read_only.c replaces it
@(linkage="weak", link_name="issue_weak_hook")
weak_hook :: #force_no_inline proc(v: Weak_Big) -> int {
	return 1
}

@(test)
test_weak_read_only :: proc(t: ^testing.T) {
	testing.expect_value(t, issue_weak_linked(), 1)

	issue_weak_g_big = {a = 1}
	testing.expect_value(t, weak_hook(issue_weak_g_big), 1)
	testing.expect_value(t, issue_weak_g_big.a, 99) // the replacement ran
}
