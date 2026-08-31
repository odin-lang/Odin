// Tests issue #7421: constant conditions in a tagless switch are conditions,
// not values to compare against one another for duplicate cases.
// https://github.com/odin-lang/Odin/issues/7421
package test_issues

import "core:testing"

Issue_7421_Alias :: u16

@(test)
test_issue_7421_tagless_switch_constant_conditions :: proc(t: ^testing.T) {
	selected := 0
	switch {
	case Issue_7421_Alias == u16:
		selected = 1
	case Issue_7421_Alias == i32:
		selected = 2
	case Issue_7421_Alias == string:
		selected = 3
	case:
		selected = 4
	}

	testing.expect_value(t, selected, 1)
}
