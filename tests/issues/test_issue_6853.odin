package test_issues

import "core:testing"

@(test)
test_issue_6853 :: proc(t: ^testing.T) {

	test_s :: struct {
		a, b, c, d, e: u64,
	}

	expected := test_s{1, 2, 3, 4, 5}

	case0 :: proc() -> (u64, u64) {return 1, 2}
	test0 := test_s{case0(), 3, 4, 5}
	testing.expect_value(t, test0, expected)

	case1 :: proc() -> (u64, u64, u64) {return 1, 2, 3}
	test1 := test_s{case1(), 4, 5}
	testing.expect_value(t, test1, expected)

	case2 :: proc() -> (u64, u64) {return 2, 3}
	test2 := test_s{1, case2(), 4, 5}
	testing.expect_value(t, test2, expected)

	case3_1 :: proc() -> (u64, u64) {return 1, 2}
	case3_2 :: proc() -> (u64, u64) {return 3, 4}
	test3 := test_s{case3_1(), case3_2(), 5}
	testing.expect_value(t, test3, expected)
}
