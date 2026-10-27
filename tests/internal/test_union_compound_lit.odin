package test_internal

import "core:testing"

// `x := []int{0}` lets the variable reuse the compound literal's storage, which is a stack saving.
// `x: U = []int{0}` is not the same thing: the variable is a union and the literal is one of its
// variants, so reusing that storage bound the variable to a bare `[]int` and never built the union.
// A later type assertion then reached the backend with the wrong operand type
@(test)
union_declared_from_a_variant_compound_literal :: proc(t: ^testing.T) {
	U :: union { []int, int }
	S :: struct { a: int }
	V :: union { S, int }
	A :: union { [2]int, int }

	x: U = []int{7}
	if v, ok := x.([]int); testing.expect(t, ok, "slice variant lost") {
		testing.expect_value(t, len(v), 1)
		testing.expect_value(t, v[0], 7)
	}

	// the same shape through a switch, which is how the union is usually consumed
	got := 0
	switch v in x {
	case []int: got = v[0]
	case int:   got = -1
	}
	testing.expect_value(t, got, 7)

	s: V = S{5}
	if v, ok := s.(S); testing.expect(t, ok, "struct variant lost") {
		testing.expect_value(t, v.a, 5)
	}

	a: A = [2]int{3, 4}
	if v, ok := a.([2]int); testing.expect(t, ok, "array variant lost") {
		testing.expect_value(t, v[1], 4)
	}

	// the reuse is still correct when the variable IS the literal
	plain := []int{1, 2}
	testing.expect_value(t, plain[1], 2)
	ps := S{9}
	testing.expect_value(t, ps.a, 9)
}
