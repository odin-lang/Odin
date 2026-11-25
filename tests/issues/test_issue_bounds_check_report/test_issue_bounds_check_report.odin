package test_issue_bounds_check_report

// `-export-bounds-checks-file` lists the bounds checks left after optimization:
// three here at -o:none, and two at -o:speed, where `element` is inlined into `first` and its check is removed

@(export)
at :: proc "contextless" (a: []int, i: int) -> int {
	return a[i]
}

element :: proc "contextless" (a: []int, i: int) -> int {
	if i < len(a) {
		return a[i]
	}
	return 0
}

@(export)
first :: proc "contextless" (a: []int) -> int {
	return element(a, 0)
}

@(export)
prefix :: proc "contextless" (a: []int, n: int) -> []int {
	return a[:n]
}

@(export)
sum :: proc "contextless" (a: []int) -> (total: int) {
	for x in a {
		total += x
	}
	return
}
