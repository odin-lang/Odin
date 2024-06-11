// Tests issue #829 https://github.com/odin-lang/Odin/issues/829
package test_issues

import "core:testing"

/* Original issue #829 example */
env : map[string]proc(a, b : int) -> int = {
	"+" = proc(a, b : int) -> int {
		return a + b
	},
}

@(test)
test_orig_ret :: proc(t: ^testing.T) {
	r := env["+"](1, 2)
	testing.expectf(t, r == 3, "%q != 3", r)
}