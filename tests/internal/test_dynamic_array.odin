package test_internal

import "core:testing"
import "base:runtime"

@test
dynamic_array_reserve :: proc(t: ^testing.T) {
	d: [dynamic]int
	err_reserve := reserve_dynamic_array(&d, 10)

	testing.expect_value(t, err_reserve, nil)
	testing.expect_value(t, cap(d), 10)
	testing.expect_value(t, len(d), 0)
}

@test
dynamic_array_reserve_negative :: proc(t: ^testing.T) {
	d: [dynamic]int
	err_reserve := reserve_dynamic_array(&d, -10)

	testing.expect_value(t, err_reserve, runtime.Allocator_Error.Invalid_Argument)
	testing.expect_value(t, cap(d), 0)
	testing.expect_value(t, len(d), 0)
}

@test
soa_dynamic_array_reserve :: proc(t: ^testing.T) {
	d: #soa[dynamic]([2]int)
	err_reserve := reserve_soa(&d, 10)

	testing.expect_value(t, err_reserve, nil)
	testing.expect_value(t, cap(d), 10)
	testing.expect_value(t, len(d), 0)
}

@test
soa_dynamic_array_reserve_negative :: proc(t: ^testing.T) {
	d: #soa[dynamic]([2]int)
	err_reserve := reserve_soa(&d, -10)

	testing.expect_value(t, err_reserve, runtime.Allocator_Error.Invalid_Argument)
	testing.expect_value(t, cap(d), 0)
	testing.expect_value(t, len(d), 0)
}
