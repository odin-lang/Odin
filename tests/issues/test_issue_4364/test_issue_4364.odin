// Tests issue #4364 https://github.com/odin-lang/Odin/issues/4364
package test_issues

import "core:testing"

@test
test_const_array_fill_assignment :: proc(t: ^testing.T) {
	MAGIC :: 12345
	Struct :: struct {x: int}
	CONST_ARR : [4]Struct : Struct{MAGIC}
	arr := CONST_ARR

	testing.expect_value(t, len(arr), 4)
	testing.expect_value(t, arr[0], Struct{MAGIC})
	testing.expect_value(t, arr[1], Struct{MAGIC})
	testing.expect_value(t, arr[2], Struct{MAGIC})
	testing.expect_value(t, arr[3], Struct{MAGIC})
}
