// Tests issue #6401 https://github.com/odin-lang/Odin/issues/6401
package test_issues

Wrapper :: struct(T: typeid) {
	value: T,
}

A :: struct {
	value: Wrapper(B),
}

B :: struct {
	value: A,
}

main :: proc() {}
