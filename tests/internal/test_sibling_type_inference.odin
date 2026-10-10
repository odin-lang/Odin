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

@test
test_type_inference_of_implicit_selectors_against_arrays :: proc(t: ^testing.T) {
	E :: enum {A, B, C}

	a: [3]E = .B
	testing.expect_value(t, a, [3]E{.B, .B, .B})
	testing.expect(t, a == .B)

	b: [2][2]E = .C
	testing.expect_value(t, b[1][0], E.C)

	second :: proc(x: [2]E) -> E { return x[1] }
	testing.expect_value(t, second(.A), E.A)
}

@test
test_type_inference_of_polymorphic_types_from_later_arguments :: proc(t: ^testing.T) {
	E :: enum {A, B, C}
	second :: proc(a: $T, b: T) -> T { return b }

	e := E.C
	testing.expect_value(t, second(.A, e),          E.C)
	testing.expect_value(t, second(b = e, a = .A), E.C)

	x: f32 = 0.5
	y := second(1, x)
	#assert(type_of(y) == f32)
	testing.expect_value(t, y, 0.5)

	v := [2]f32{1, 2}
	testing.expect_value(t, second({3, 4}, v), v)

	p := new(int)
	defer free(p)
	testing.expect_value(t, second(nil, p), p)

	#assert(type_of(second(1, 2.0)) == int)

	member_any    :: proc(a: int, b: any) -> int { return 1 }
	member_poly   :: proc(a: $T, b: T) -> int { return 2 }
	member_string :: proc(s: string) -> int { return 3 }
	group_any    :: proc{member_any, member_poly}
	group_string :: proc{member_string, member_poly}

	f: f64 = 2.5
	testing.expect_value(t, group_any(1, f),    1)
	testing.expect_value(t, group_string(1, f), 2)
}
