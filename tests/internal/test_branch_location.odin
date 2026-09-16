package test_internal

import "core:testing"

@(private="file")
returns_at :: proc(early: bool, got: ^i32) -> (expected: i32) {
	defer got^ = #branch_location.line

	if early {
		return #line
	}

	return #line
}

// A selector on `#branch_location` reached `lb_build_addr`, which had no case for a directive
@(test)
branch_location_field_access :: proc(t: ^testing.T) {
	got: i32

	expected := returns_at(true, &got)
	testing.expect_value(t, got, expected)

	expected = returns_at(false, &got)
	testing.expect_value(t, got, expected)
}
