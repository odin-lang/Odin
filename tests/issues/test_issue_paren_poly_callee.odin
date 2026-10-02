// Calling a polymorphic procedure through a parenthesized callee, e.g. `(foo)(x)`
package test_issues

import "core:testing"

@(private="file")
double :: proc(x: $T) -> T { return x * 2 }
@(private="file")
splat :: proc($N: int, x: $T) -> [N]T { return x }

@(test)
test_paren_poly_callee :: proc(t: ^testing.T) {
	testing.expect_value(t, (double)(int(2)), 4)
	testing.expect_value(t, ((double))(f32(1.5)), 3)
	testing.expect_value(t, (splat)(2, i32(3)), [2]i32{3, 3})

	big := (splat)(16, f64(1))
	testing.expect_value(t, big[15], 1)

	s := (make)([]int, 3)
	defer delete(s)
	testing.expect_value(t, len(s), 3)
}
