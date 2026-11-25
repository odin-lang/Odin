package test_issue_poly_recursion_limit

// Each call instantiates `f` again with a larger type.
f :: proc(x: $T) {
	f([1]T{x})
}

main :: proc() {
	f(1)
}
