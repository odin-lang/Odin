// Tests issue #7430 https://github.com/odin-lang/Odin/issues/7430
package test_issues

import "core:testing"

@(test)
test_issue_7430 :: proc(t: ^testing.T) {
	U :: union {T}
	T :: struct {_: []i32}

	u := [dynamic; 4]U{T{}}
	testing.expect_value(t, len(u), 1)
}
