// Tests issue #5318 https://github.com/odin-lang/Odin/issues/5318
package test_issues

import "core:testing"

common :: proc($f: proc(i64, i64) -> i64) -> i64 { return f(16, 4) }

sum :: proc() -> i64 {
	internal :: proc(l, r: i64) -> i64 { return l + r }
	return common(internal)
}

difference :: proc() -> i64 {
	internal :: proc(l, r: i64) -> i64 { return l - r }
	return common(internal)
}

apply :: proc(v: ^int, $f: proc(^int)) { f(v) }

by_amount :: proc(v: ^int, $amount: int) {
	add :: proc(v: ^int) { v^ += amount }
	apply(v, add)
	apply(v, proc(v: ^int) { v^ += amount })
}

@(test)
test_issue_5318 :: proc(t: ^testing.T) {
	testing.expect_value(t, sum(), 20)
	testing.expect_value(t, difference(), 12)

	x := 0
	by_amount(&x, 1)
	by_amount(&x, 100)
	testing.expect_value(t, x, 202)
}
