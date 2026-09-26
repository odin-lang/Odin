// Tests issue #5573 https://github.com/odin-lang/Odin/issues/5573
package test_issues

poly :: proc(x: $T) -> string {
	return "poly"
}

takes_concrete :: proc(f: proc(a: int, b: f32, c: rawptr) -> ^int) {
}

main :: proc() {
	// should error - wrong arity, wrong parameter types, wrong return type
	mismatched: proc(a: int, b: f32, c: rawptr) -> ^int = poly
	_ = mismatched

	// should error - same, as a procedure argument
	takes_concrete(poly)
}
