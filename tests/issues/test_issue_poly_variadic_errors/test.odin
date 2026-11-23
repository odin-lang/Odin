// Arguments that cannot determine the element type of a polymorphic variadic parameter are one error at each call.
// The procedure is not generated with the type left polymorphic, which reported errors in its body as well.
package test_issue_poly_variadic_errors

first :: proc(args: ..$E) -> E {
	r: E
	if len(args) > 0 {
		r = args[0]
	}
	return r
}

main :: proc() {
	_ = first(nil)
	_ = first({1, 2})
}
