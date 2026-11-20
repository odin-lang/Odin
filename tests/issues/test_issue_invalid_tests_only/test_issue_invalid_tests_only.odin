package test_issue_invalid_tests_only

import "core:testing"

@(test)
bad_signature :: proc(t: ^testing.T, x: int) {}

outer :: proc() {
	@(test)
	inner :: proc(t: ^testing.T) {}
}
