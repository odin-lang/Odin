package test_custom_linkage

// Called from another package, so from another module: its declaration there must refer to these definitions.

@(linkage="weak")
weak_proc :: #force_no_inline proc(x: int) -> int {
	return x + 1
}

@(linkage="link_once")
link_once_proc :: #force_no_inline proc(x: int) -> int {
	return x + 2
}

@(linkage="weak")
weak_var := 5
