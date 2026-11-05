// Calls to a `@(disabled=true)` procedure are removed, but its value can still be taken.
// Built with `-disable-assert`, `rawptr(assert)` used to fail with "missing procedure 'assert'".

package test_issues

import "base:runtime"
import "core:testing"

@(disabled=true)
disabled_proc :: proc(n: ^int) { n^ += 1 }

global_assert := rawptr(assert)

@(test)
test_disabled_proc_value :: proc(t: ^testing.T) {
	testing.expect(t, rawptr(assert) != nil)
	testing.expect(t, rawptr(runtime.assert) == global_assert)

	n := 0
	disabled_proc(&n)
	testing.expect_value(t, n, 0)

	p := disabled_proc
	p(&n)
	testing.expect_value(t, n, 1)
}
