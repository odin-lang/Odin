// Tests issue https://github.com/odin-lang/Odin/issues/2615
// Cannot iterate over string literals
package test_issues

import "core:testing"

@(test)
test_cannot_iterate_over_string_literal :: proc(t: ^testing.T) {
	for c, i in "fo世" {
		switch i {
		case 0:
			testing.expect_value(t, c, 'f')
		case 1:
			testing.expect_value(t, c, 'o')
		case 2:
			testing.expect_value(t, c, '世')
		}
	}
}
