// Tests issue #7073-part 1 https://github.com/odin-lang/Odin/issues/7073
package test_issues

main :: proc() {
	arr := [2]int{10, 20}
	_, _ = **arr          // ok: array value
	_, _ = **struct{x, y: int}{} // ok: struct value

	_, _ = **[2]int       // error: array type
	_, _ = **struct{x, y: int}   // error: struct type
}
