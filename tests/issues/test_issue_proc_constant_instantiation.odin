package test_issues

import "core:testing"

// Passing the same procedure to a `$` parameter from two calls used to generate two instantiations,
// each with its own `Box` crashing the compiler.

box_of :: proc($f: proc() -> int) -> typeid {
	Box :: struct {}
	return Box
}
one :: proc() -> int { return 1 }

@(test)
proc_constant_instantiation :: proc(t: ^testing.T) {
	testing.expect_value(t, box_of(one), box_of(one))
}
