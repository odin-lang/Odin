// Tests issue #5335 https://github.com/odin-lang/Odin/issues/5335
// A constant cannot have type `any`
package test_issue_5335

main :: proc() {
	a : any : 1
	b := a.data
	_ = b

	C :: any(1)
	_ = C
}
