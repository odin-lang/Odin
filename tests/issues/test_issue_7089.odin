package test_issues

import "core:testing"

@(test)
test_issue_7089 :: proc(t: ^testing.T) {
	{
		A0 :: [dynamic; 8]int
		A1 :: union { A0 }
		A2 :: struct { elements: [dynamic; 8]A1 }

		value := A2{elements = {A0{1}, A0{2}, A0{3}}}
		testing.expect_value(t, len(value.elements), 3)
	}

	{
		A0 :: struct { _: int }
		A1 :: union { A0 }
		A2 :: struct { elements: [dynamic; 8]A1 }

		value := A2{elements = {A0{1}, A0{2}, A0{3}}}
		testing.expect_value(t, len(value.elements), 3)
	}
}
