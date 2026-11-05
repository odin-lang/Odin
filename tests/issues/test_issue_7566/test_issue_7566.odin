// Tests issue #7566 https://github.com/odin-lang/Odin/issues/7566
// Polymorphic instances whose constant parameters are spelt the same but have different values
package test_issue_7566

import "core:testing"

Dim :: enum{ C, F }
Dims :: [Dim]int
Arr2 :: [2][2]int

get_dims :: proc($dims: Dims) -> Dims { return dims }
get_arr2 :: proc($a: Arr2) -> Arr2 { return a }

make_and_check :: proc($A, $I: int) -> Dims {
	dims :: Dims{.C = I, .F = A}
	return get_dims(dims)
}

make_inline :: proc($A, $I: int) -> Dims {
	return get_dims(Dims{.C = I, .F = A})
}

make_nested :: proc($A: int) -> Arr2 {
	a :: Arr2{{A, 1}, {2, A}}
	return get_arr2(a)
}

@(test)
test_issue_7566 :: proc(t: ^testing.T) {
	testing.expect_value(t, make_and_check(2, 2), Dims{.C = 2, .F = 2})
	testing.expect_value(t, make_and_check(3, 3), Dims{.C = 3, .F = 3})
	testing.expect_value(t, make_inline(4, 5), Dims{.C = 5, .F = 4})
	testing.expect_value(t, make_inline(6, 7), Dims{.C = 7, .F = 6})
	testing.expect_value(t, make_nested(8), Arr2{{8, 1}, {2, 8}})
	testing.expect_value(t, make_nested(9), Arr2{{9, 1}, {2, 9}})
}
