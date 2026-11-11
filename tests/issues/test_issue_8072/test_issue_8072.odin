// Tests issue #8072 https://github.com/odin-lang/Odin/issues/8072
package test_issue_8072

import "core:testing"

sum :: proc "contextless" (n: u64, acc: ^u64) -> u64 {
	if n == 0 {
		return acc^
	}
	x := n
	acc^ += x
	return #must_tail sum(n - 1, acc)
}

sum_void :: proc "contextless" (n: u64, acc: ^u64) {
	if n == 0 {
		return
	}
	x := n
	acc^ += x
	#must_tail sum_void(n - 1, acc)
}

@test
test_must_tail_with_local :: proc(t: ^testing.T) {
	acc: u64
	testing.expect_value(t, sum(10, &acc), 55)

	acc = 0
	sum_void(10, &acc)
	testing.expect_value(t, acc, 55)
}
