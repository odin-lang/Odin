package test_internal

import "core:testing"

// The element type of a polymorphic variadic parameter is determined from its arguments.
// The first typed argument decides it, or the default type of the first untyped one.

@(private="file")
first :: proc(args: ..$E) -> E {
	r: E
	if len(args) > 0 {
		r = args[0]
	}
	return r
}

@(private="file")
count :: proc(n: int, args: ..$E) -> int {
	return n + len(args)
}

@(private="file")
deref_first :: proc(args: ..^$E) -> E {
	return args[0]^
}

// Inside a polymorphic procedure the arguments have the type of its own type parameter
@(private="file")
first_of :: proc($T: typeid, a, b: T) -> T {
	return first(a, b)
}

@(private="file")
first_of_value :: proc(a: $T) -> T {
	return first(a, a)
}

@test
test_polymorphic_variadic :: proc(t: ^testing.T) {
	x := 5
	y: f32 = 2.5

	#assert(type_of(first(x, 7)) == int)
	testing.expect_value(t, first(x, 7), 5)

	#assert(type_of(first(7, 8)) == int)
	testing.expect_value(t, first(7, 8), 7)

	#assert(type_of(first(1, y)) == f32)
	testing.expect_value(t, first(1, y), 1)

	#assert(type_of(first(0.5, 2)) == f64)
	testing.expect_value(t, first(0.5, 2), 0.5)

	testing.expect_value(t, first(..[]int{4, 5}), 4)
	testing.expect_value(t, deref_first(&x, &x), 5)
	testing.expect_value(t, count(1, "a", "b"), 3)

	testing.expect_value(t, first_of(int, 3, 4), 3)
	testing.expect_value(t, first_of_value(f32(1.5)), 1.5)
}
