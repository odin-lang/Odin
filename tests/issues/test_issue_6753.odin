// test issue for #6753 https://github.com/odin-lang/odin/issues/6753
package test_issues
import "core:testing"

identity :: proc(x: $T) -> T { return x }

foo :: proc(x: int, poly: proc(int) -> int = identity) -> int {
	return foo(identity(x))
}

// failing as returns before specialized
@test
test_issue_6753 :: proc(t: ^testing.T) {
    p: proc(int) -> int = identity
	testing.expect(t, p != nil, "polymorphic procedure was not instantiated")
	testing.expect_value(t, p(123), 123)
}

// failing as returns before specialized
@test
test_issue_default_poly_parameter_6753 :: proc(t: ^testing.T) {
	testing.expect_value(t, foo(123), 123)
}