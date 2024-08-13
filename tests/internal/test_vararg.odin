package test_internal

import "core:testing"

@(test)
test_default_vararg :: proc(t: ^testing.T) {

	no_default :: proc(t: ^testing.T, args: ..int) {
		testing.expect_value(t, len(args), 0)
	}
	no_default(t)

	no_default_overwritten :: proc(t: ^testing.T, args: ..int) {
		testing.expect_value(t, len(args), 1)
		testing.expect_value(t, args[0], 1)
	}
	no_default_overwritten(t, 1)

	one_default :: proc(t: ^testing.T, args: ..int = {1}) {
		testing.expect_value(t, len(args), 1)
		testing.expect_value(t, args[0], 1)
	}
	one_default(t)

	one_default_overwritten :: proc(t: ^testing.T, args: ..int = {1}) {
		testing.expect_value(t, len(args), 0)
	}
	one_default_overwritten(t, ..[]int{})

	more_defaults :: proc(t: ^testing.T, args: ..int = {1, 2, 3}) {
		testing.expect_value(t, len(args), 3)
		testing.expect_value(t, args[0], 1)
		testing.expect_value(t, args[1], 2)
		testing.expect_value(t, args[2], 3)
	}
	more_defaults(t)

	more_defaults_overwritten :: proc(t: ^testing.T, args: ..int = {1, 2, 3}) {
		testing.expect_value(t, len(args), 3)
		testing.expect_value(t, args[0], 3)
		testing.expect_value(t, args[1], 2)
		testing.expect_value(t, args[2], 1)
	}
	more_defaults_overwritten(t, 3, 2, 1)
}
