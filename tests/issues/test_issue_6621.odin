// Tests issue #6621 https://github.com/odin-lang/Odin/issues/6621
package test_issues

t: struct {
	next: ^type_of(t),
}

main :: proc() {
	_ = t
}
