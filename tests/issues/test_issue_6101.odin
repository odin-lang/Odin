// Tests issue #6101 https://github.com/odin-lang/Odin/issues/6101
package test_issues

import "core:testing"

@(test)
test_issue_6101_bmp :: proc(t: ^testing.T) {
	s := string16("\u732b")
	testing.expect_value(t, len(s), 1)

	u := transmute([]u16)s
	testing.expect_value(t, u[0], 0x732b)
}

@(test)
test_issue_6101_non_bmp :: proc(t: ^testing.T) {
	s := string16("\U0001F63A")
	testing.expect_value(t, len(s), 2)

	u := transmute([]u16)s
	testing.expect_value(t, u[0], 0xD83D)
	testing.expect_value(t, u[1], 0xDE3A)
}
