// Tests that a bare `..` in a type position call is rejected rather than left as a
// null argument for the checker to walk off of.
package test_issues

Foo :: struct($T: typeid) {
	x: T,
}

S :: struct {
	a: int,
}

bare :: proc() {
	v: Foo(..)
	_ = v
}

named_then_bare :: proc() {
	v: Foo(T = int, ..)
	_ = v
}

bare_then_named :: proc() {
	v: Foo(.., T = int)
	_ = v
}

positional_then_bare :: proc() {
	v: Foo(int, ..)
	_ = v
}

conversion_to_struct :: proc() {
	v: S(..)
	_ = v
}

conversion_to_builtin :: proc() {
	v: int(..)
	_ = v
}

result_type :: proc() -> Foo(..) {
	return {}
}
