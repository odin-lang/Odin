package test_issue_poly_recursion_limit_record

// Each instantiation of `S` names a larger one.
S :: struct($T: typeid) {
	x:    T,
	next: ^S([1]T),
}

main :: proc() {
	s: S(int)
	_ = s
}
