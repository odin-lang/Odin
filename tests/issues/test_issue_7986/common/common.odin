package test_issue_7986_common

counter: int

@(init)
bump :: proc "contextless" () {
	counter += 1
}

get :: proc "contextless" () -> int {
	return counter
}
