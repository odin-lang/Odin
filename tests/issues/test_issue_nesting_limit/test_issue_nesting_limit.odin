package test_issue_nesting_limit

// The parser builds `a + a + ...` in a loop, but the chain is as deep as it is long.
main :: proc() {
	a := 1
	x := a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a +
	     a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a + a
	_ = x
}
