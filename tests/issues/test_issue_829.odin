// Tests issue #829 https://github.com/odin-lang/Odin/issues/829
package test_issues

import "core:fmt"
import "core:testing"
import tc "tests:common"

/* Original issue #829 example */

env : map[string]proc(a, b : int) -> int = {
	"+" = proc(a, b : int) -> int {
		return a + b
	},
}

test_orig :: proc() {
	fmt.println(env["+"](1, 2))
}

main :: proc() {
	t := testing.T{}

	test_orig()

	test_orig_ret(&t)

	tc.report(&t)
}

test_orig_ret :: proc(t: ^testing.T) {
	r := fmt.tprint(env["+"](1, 2))
	tc.expect(t, r == "3", fmt.tprintf("%s: \"%s\" != \"3\"\n", #procedure, r))
}
