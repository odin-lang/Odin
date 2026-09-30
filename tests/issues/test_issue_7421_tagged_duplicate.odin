// Regression guard for issue #7421: tagged switches still reject duplicate cases.
package test_issues

main :: proc() {
	value := false
	switch value {
	case false:
	case false:
	}
}
