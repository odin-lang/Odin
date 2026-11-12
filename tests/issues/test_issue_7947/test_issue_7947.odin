package test_issue_7947

main :: proc() {
	res := (proc($T: typeid, x: T) -> T {
		return x
	})(int, 42)
	_ = res
}
