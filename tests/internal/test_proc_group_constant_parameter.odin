package test_internal

import "core:testing"

@test
test_proc_group_constant_parameter :: proc(t: ^testing.T) {
	plain_runtime  :: proc(x: int) -> string { return "runtime" }
	plain_constant :: proc($x: int) -> string { return "constant" }
	plain :: proc{plain_runtime, plain_constant}

	generic_runtime  :: proc(a: $T, b: T) -> string { return "runtime" }
	generic_constant :: proc(a: $T, $b: T) -> string { return "constant" }
	generic :: proc{generic_runtime, generic_constant}

	by_runtime  :: proc(data: []$E, less: proc(a, b: E) -> bool) -> string { return "runtime" }
	by_constant :: proc(data: []$E, $less: proc(a, b: E) -> bool) -> string { return "constant" }
	by :: proc{by_runtime, by_constant}
	by_gated :: proc{by_runtime, by_constant where ODIN_OPTIMIZATION_MODE >= .Speed}

	less_int :: proc(a, b: int) -> bool { return a < b }

	value := 3
	less  := less_int
	data  := []int{3, 1, 2}

	testing.expect_value(t, plain(3),     "constant")
	testing.expect_value(t, plain(value), "runtime")

	testing.expect_value(t, generic(1, 2),     "constant")
	testing.expect_value(t, generic(1, value), "runtime")

	testing.expect_value(t, by(data, less_int), "constant")
	testing.expect_value(t, by(data, proc(a, b: int) -> bool { return a > b }), "constant")
	testing.expect_value(t, by(data, less), "runtime")

	when ODIN_OPTIMIZATION_MODE >= .Speed {
		testing.expect_value(t, by_gated(data, less_int), "constant")
	} else {
		testing.expect_value(t, by_gated(data, less_int), "runtime")
	}
	testing.expect_value(t, by_gated(data, less), "runtime")
}
