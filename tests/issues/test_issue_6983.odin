// Tests issue #6983 https://github.com/odin-lang/Odin/issues/6983
package test_issues

import "core:testing"

@(test)
test_multidim_array_cast :: proc(t: ^testing.T) {
	Foo :: [3][2]f32

	a : [3][2]i32
	b: Foo
	b = cast(Foo)transmute([3][2]i32)a

	testing.expect_value(t, b, Foo{})
}
