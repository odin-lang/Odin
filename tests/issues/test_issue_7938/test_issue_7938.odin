// Tests issue #7938 https://github.com/odin-lang/Odin/issues/7938
package test_issue_7938

f :: proc() -> (int, bool) {
	return 42, false
}

g :: proc(x: int) -> Maybe(int) {
	return x
}

// Each loop can be left through the nested `or_break`, so each procedure is missing a return
or_else_fallback :: proc() -> int {
	for {
		_ = f() or_else (f() or_break)
	}
}

or_return_operand :: proc() -> (n: int, ok: bool) {
	for {
		_ = g(f() or_break).? or_return
	}
}

or_continue_operand :: proc() -> int {
	for {
		_ = g(f() or_break).? or_continue
	}
}
