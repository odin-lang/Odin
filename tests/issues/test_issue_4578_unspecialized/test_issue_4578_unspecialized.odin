package test_issue_4578_unspecialized

generic_literal_default :: proc($U: typeid, p: proc(x: U) = proc(x: $T) {}) {}

main :: proc() {
	generic_literal_default(int)
}
