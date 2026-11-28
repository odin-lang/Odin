package test_internal

import "core:testing"

// A large parameter is passed by reference. On i386 it was pushed by value with a copy in
// every frame, and this recursion needed more than 3 MiB of stack.

@(private="file")
Large_Param :: struct {
	data: [16384]u8,
}

@(private="file")
large_param_depth :: proc(p: Large_Param, n: int) -> int {
	if n == 0 {
		return int(p.data[0])
	}
	return large_param_depth(p, n-1) + 1
}

@test
test_large_param_recursion :: proc(t: ^testing.T) {
	p: Large_Param
	p.data[0] = 7
	testing.expect_value(t, large_param_depth(p, 100), 107)
}
