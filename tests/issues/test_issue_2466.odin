// Tests issue #2466 https://github.com/odin-lang/Odin/issues/2466
package test_issues

import "core:fmt"
import "core:testing"

Bug :: struct  {
	val: int,
	arr: []int,
}

@test
test_compound_literal_local_reuse :: proc(t: ^testing.T) {
	v: int = 123
	bug := Bug {
		val = v,
		arr = {42},
	}
	testing.expect(t, bug.val == 123, fmt.tprintf("expected 123, found %d", bug.val))
	testing.expect(t, bug.arr[0] == 42, fmt.tprintf("expected 42, found %d", bug.arr[0]))
}

