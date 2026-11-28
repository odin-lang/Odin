package test_issue_dwarf_nocall

// Odin procedures get `DW_CC_nocall` in DWARF: a debugger must not call them or read their results the C way

odin_results :: proc(a: int, b: string) -> (int, bool) {
	return a + len(b), true
}

c_result :: proc "c" (a: int) -> int {
	return a*2
}

main :: proc() {
	n, ok := odin_results(1, "two")
	if ok {
		n = int(c_result(n))
	}
	_ = n
}
