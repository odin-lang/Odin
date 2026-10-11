// Regression guard for issue #7421: tagged switches still reject duplicate cases.
package test_issue_7421_tagged_duplicate

main :: proc() {
	value := false
	switch value {
	case false:
	case false:
	}
}
