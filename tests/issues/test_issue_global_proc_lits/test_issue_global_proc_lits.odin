// Procedure literals within the initializations of globals, constant and not, nested, and called through them
package test_issue_global_proc_lits

import "core:testing"

Op :: struct {
	name: string,
	f:    proc(a, b: int) -> int,
}

// constant, so its literals are generated with the global's initializer
CONST_OPS := [?]Op{
	{"add", proc(a, b: int) -> int { return a + b }},
	{"sub", proc(a, b: int) -> int { return a - b }},
}

// not constant, so it is initialized at startup
runtime_ops := []Op{
	{"mul", proc(a, b: int) -> int { return a * b }},
	{"twice", proc(a, b: int) -> int {
		inner := proc(x: int) -> int { return x * 2 }
		return inner(a) + inner(b)
	}},
}

lazy_op := make_op(proc(a, b: int) -> int { return max(a, b) })

make_op :: proc "contextless" (f: proc(a, b: int) -> int) -> Op {
	return {"made", f}
}

@(test)
test_global_proc_lits :: proc(t: ^testing.T) {
	testing.expect_value(t, CONST_OPS[0].f(7, 3), 10)
	testing.expect_value(t, CONST_OPS[1].f(7, 3), 4)
	testing.expect_value(t, runtime_ops[0].f(7, 3), 21)
	testing.expect_value(t, runtime_ops[1].f(7, 3), 20)
	testing.expect_value(t, lazy_op.f(7, 3), 7)
	testing.expect_value(t, lazy_op.name, "made")
}
