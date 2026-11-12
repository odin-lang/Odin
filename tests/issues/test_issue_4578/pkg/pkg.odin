package test_issue_4578_pkg

import "core:fmt"

@(private)
HIDDEN :: 41

add :: proc(v: $T, y: T = HIDDEN + 1) -> T {
	return v + y
}

describe :: proc(v: $T, p := proc(x: T) -> string { return fmt.tprint(x, HIDDEN) }) -> string {
	return p(v)
}
