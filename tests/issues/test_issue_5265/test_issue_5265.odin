// Tests issue #5265 https://github.com/odin-lang/Odin/issues/5265
package test_issue_5265

main :: proc() {
	a: i128 = 1
	assert(1 / a == 1)
	assert(a / 1 == 1)
}