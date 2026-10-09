// A `distinct` copy of a record satisfies a `$T/Record` constraint, as it shares its base record.
package test_issues

import "core:testing"

@(private="file") Foo :: struct { a: int }
@(private="file") Bar :: distinct Foo
@(private="file") Baz :: distinct Bar
@(private="file") U   :: union { int, f32 }
@(private="file") DU  :: distinct U

@(private="file") take_foo :: proc(foo: $T/Foo) -> int { return foo.a }
@(private="file") take_u   :: proc(u: $T/U) -> bool { return u != nil }

@(test)
distinct_record_satisfies_constraint :: proc(t: ^testing.T) {
	testing.expect_value(t, take_foo(Foo{1}), 1)
	testing.expect_value(t, take_foo(Bar{2}), 2)
	testing.expect_value(t, take_foo(Baz{3}), 3)
	testing.expect(t, take_u(DU(2)), "a distinct union satisfies its constraint")
}
