package test_internal

import "core:testing"

// `U(3)` records the union as the constant's type, so the backend has to peel it back to the variant
// the checker resolved. It could not, and panicked in lb_const_value. The variant cannot be guessed
// from the value's kind either -- `W(i16(300))` below is an integer, and picking the first integer
// variant would silently choose i8
@(test)
union_constant_selects_the_declared_variant :: proc(t: ^testing.T) {
	U :: union { string, int, f32 }
	W :: union { i8, i16, i32 }
	E :: enum { None, Bad }
	EU :: union { E, string }

	CI :: U(int(3))
	CS :: U("s")
	CF :: U(f32(1.5))
	CW :: W(i16(300))
	CE :: EU(E.Bad)

	ci := CI
	cs := CS
	cf := CF
	cw := CW
	ce := CE

	if v, ok := ci.(int);    testing.expect(t, ok, "CI is not the int variant")    { testing.expect_value(t, v, 3) }
	if v, ok := cs.(string); testing.expect(t, ok, "CS is not the string variant") { testing.expect_value(t, v, "s") }
	if v, ok := cf.(f32);    testing.expect(t, ok, "CF is not the f32 variant")    { testing.expect_value(t, v, f32(1.5)) }
	// i16, not the first integer variant
	if v, ok := cw.(i16);    testing.expect(t, ok, "CW is not the i16 variant")    { testing.expect_value(t, v, i16(300)) }
	if v, ok := ce.(E);      testing.expect(t, ok, "CE is not the enum variant")   { testing.expect(t, v == E.Bad, "wrong enum value") }

	// the same constant reached through an aggregate
	S :: struct { u: U, n: int }
	s := S{CI, 7}
	if v, ok := s.u.(int); testing.expect(t, ok, "struct field lost its variant") { testing.expect_value(t, v, 3) }
	testing.expect_value(t, s.n, 7)

	arr := [2]U{U(int(1)), U("x")}
	if v, ok := arr[0].(int);    testing.expect(t, ok, "array element 0 lost its variant") { testing.expect_value(t, v, 1) }
	if v, ok := arr[1].(string); testing.expect(t, ok, "array element 1 lost its variant") { testing.expect_value(t, v, "x") }
}

@(private="file") U_G :: union { string, int }
@(private="file") G  := U_G(int(3))
@(private="file") GS := U_G("hello")

@(test)
union_constant_as_a_global_initializer :: proc(t: ^testing.T) {
	if v, ok := G.(int);     testing.expect(t, ok, "global lost its variant")        { testing.expect_value(t, v, 3) }
	if v, ok := GS.(string); testing.expect(t, ok, "string global lost its variant") { testing.expect_value(t, v, "hello") }
}
