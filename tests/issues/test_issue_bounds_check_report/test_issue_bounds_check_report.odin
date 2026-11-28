package test_issue_bounds_check_report

// `-export-bounds-checks-file` lists the bounds checks left after optimization, one of each kind here.
// At -o:none the check in `element` is kept, and the one of `make` is in the runtime, where its location is a parameter.
// At -o:speed `element` is inlined into `first` and its check is removed, and the runtime's `make` is inlined into `buffer`.

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

@(export)
cell :: proc "contextless" (m: matrix[4, 4]f32, i, j: int) -> f32 {
	return m[i, j]
}

@(export)
buffer :: proc(n: int) -> []int {
	return make([]int, n)
}
