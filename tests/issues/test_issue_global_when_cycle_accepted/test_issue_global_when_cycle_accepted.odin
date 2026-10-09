// Cycles of global 'when's with exactly one consistent choice of branches
package test_issues

import "core:testing"

// only the first branch of the second 'when' is consistent, so `int` stays the builtin
when size_of(int) == 8 { Y :: 1 }
when Y == 1 { Z :: 1 } else { int :: i32 }

// through an unconditional declaration, whose value is checked for each choice
SIZE :: size_of(uint)
when SIZE == 8 { V :: 1 }
when V == 1 { W :: 2 } else { uint :: u32 }

// nested and 'else when' branches
when size_of(rawptr) == 8 {
	when true { N :: 1 }
}
when N != 1 { rawptr :: u32 } else when N == 1 { M :: 3 } else { rawptr :: u16 }

@(test)
test_global_when_cycle_accepted :: proc(t: ^testing.T) {
	testing.expect_value(t, Z, 1)
	testing.expect_value(t, size_of(int), 8)
	testing.expect_value(t, SIZE, 8)
	testing.expect_value(t, W, 2)
	testing.expect_value(t, M, 3)
}
