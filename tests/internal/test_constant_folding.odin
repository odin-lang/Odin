package test_internal

import "core:testing"

// `<=` and `<` on a `bit_set` are subset and proper subset, `>=` and `>` superset. The folder
// asked `(lhs & rhs) <= lhs` where the definition is `(lhs & rhs) == lhs`, which is true for
// any operands, so `<=` folded true unconditionally; `<` compounded it by requiring `lhs < rhs`
// where it needs `lhs != rhs`. Under `when` this decides which declarations exist.

@(test)
bit_set_subset_folding_matches_runtime :: proc(t: ^testing.T) {
	B :: bit_set[0..<4]

	{	// disjoint: neither a subset nor a superset
		a, b := B{0, 3}, B{0, 1}
		testing.expect_value(t, B{0, 3} <= B{0, 1}, a <= b)
		testing.expect_value(t, B{0, 3} <= B{0, 1}, false)
		testing.expect_value(t, B{0, 3} >= B{0, 1}, a >= b)
		testing.expect_value(t, B{0, 3} >= B{0, 1}, false)
	}
	{	// proper subset
		a, b := B{0}, B{0, 1}
		testing.expect_value(t, B{0} <= B{0, 1}, a <= b)
		testing.expect_value(t, B{0} <= B{0, 1}, true)
		testing.expect_value(t, B{0} < B{0, 1}, a < b)
		testing.expect_value(t, B{0} < B{0, 1}, true)
	}
	{	// equal: a subset but not a proper one
		a, b := B{0, 1}, B{0, 1}
		testing.expect_value(t, B{0, 1} <= B{0, 1}, a <= b)
		testing.expect_value(t, B{0, 1} <= B{0, 1}, true)
		testing.expect_value(t, B{0, 1} < B{0, 1}, a < b)
		testing.expect_value(t, B{0, 1} < B{0, 1}, false)
	}
	{	// superset
		a, b := B{0, 1}, B{0}
		testing.expect_value(t, B{0, 1} <= B{0}, a <= b)
		testing.expect_value(t, B{0, 1} <= B{0}, false)
		testing.expect_value(t, B{0, 1} > B{0}, a > b)
		testing.expect_value(t, B{0, 1} > B{0}, true)
	}
	{	// the empty set is a subset of everything, and a proper one unless both are empty
		a, b := B{}, B{0}
		testing.expect_value(t, B{} < B{0}, a < b)
		testing.expect_value(t, B{} < B{0}, true)
	}
	{
		a, b := B{}, B{}
		testing.expect_value(t, B{} <= B{}, a <= b)
		testing.expect_value(t, B{} <= B{}, true)
		testing.expect_value(t, B{} < B{}, a < b)
		testing.expect_value(t, B{} < B{}, false)
	}

	// equality was never affected, so a fix here must not disturb it
	{
		a, b := B{0, 1}, B{1, 0}
		testing.expect_value(t, B{0, 1} == B{1, 0}, a == b)
		testing.expect_value(t, B{0, 1} == B{1, 0}, true)
		testing.expect_value(t, B{0, 1} != B{0}, a != B{0})
	}
}

// a mis-folded subset test selects the wrong `when` arm, which changes which declarations exist
@(test)
bit_set_subset_folding_selects_the_right_when_arm :: proc(t: ^testing.T) {
	B :: bit_set[0..<4]

	when (B{0} < B{0, 1})     { W1 :: 1 } else { W1 :: 0 }
	when (B{0, 3} <= B{0, 1}) { W2 :: 0 } else { W2 :: 1 }
	when (B{0, 1} <= B{0, 1}) { W3 :: 1 } else { W3 :: 0 }
	when (B{0, 1} > B{0})     { W4 :: 1 } else { W4 :: 0 }

	testing.expect_value(t, W1, 1)
	testing.expect_value(t, W2, 1)
	testing.expect_value(t, W3, 1)
	testing.expect_value(t, W4, 1)
}
