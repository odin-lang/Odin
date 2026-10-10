package test_internal

import "core:testing"

@test
test_type_inference_from_the_other_operand :: proc(t: ^testing.T) {
	E  :: enum {A, B, C}
	EB :: bit_set[E]
	V2 :: [2]f32

	v := V2{1, 2}
	w := {1, 0} + v
	#assert(type_of(w) == V2)
	testing.expect_value(t, w, V2{2, 2})
	testing.expect(t, {1, 2} == v)

	s: f32 = 2
	u: V2 = {1, 2} * s
	testing.expect_value(t, u, V2{2, 4})

	c := true
	e := E.B
	testing.expect(t, (.A if c else .C) != e)

	b := EB{.B}
	testing.expect_value(t, {.A} | b, EB{.A, .B})
	testing.expect(t, {.B} <= b)
}

@test
test_type_inference_in_ranges :: proc(t: ^testing.T) {
	E :: enum {A, B, C}

	n := 0
	for e in E.A ..= .C {
		#assert(type_of(e) == E)
		n += 1
	}
	for _ in .A ..< E.C {
		n += 1
	}
	testing.expect_value(t, n, 5)
}

@test
test_type_inference_in_min_max_clamp :: proc(t: ^testing.T) {
	E :: enum {A, B, C}

	e := E.B
	testing.expect_value(t, min(e, .A),       E.A)
	testing.expect_value(t, min(.C, e),       E.B)
	testing.expect_value(t, max(.A, e, .C),   E.C)
	testing.expect_value(t, clamp(.C, .A, e), E.B)

	x: E = min(.B, .C)
	testing.expect_value(t, x, E.B)
}
