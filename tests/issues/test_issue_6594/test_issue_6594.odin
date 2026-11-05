// Test issue #6594 https://github.com/odin-lang/Odin/issues/6594
package test_issue_6594

a := a

main :: proc() {
	_ = a + 1
}

