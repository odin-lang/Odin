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

@(private="file")
leaves_loop_at :: proc(stop: int, lines: ^[3]i32) {
	for i in 0..<3 {
		defer lines[i] = #branch_location.line
		if i == stop {
			break
		}
		if i == 0 {
			continue
		}
	}
}

// Each way out of a scope reports where it left: the branch, or the end of the block
@(test)
branch_location_of_loop_exits :: proc(t: ^testing.T) {
	lines: [3]i32
	leaves_loop_at(1, &lines)
	testing.expect_value(t, lines[0], 36)
	testing.expect_value(t, lines[1], 33)
	leaves_loop_at(5, &lines)
	testing.expect_value(t, lines[2], 38)
}
