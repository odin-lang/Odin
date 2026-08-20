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

A :: union {B, bool}
B :: union {C, int }
C :: struct{}

@(test)
union_const_access :: proc(t: ^testing.T) {
	X :: struct{x: A}{B(C{})}
	testing.expect_value(t, X.x, A(B(C{})))

	E :: enum {y}
	Y : [E]A : {.y = true}
	testing.expect_value(t, Y[.y], A(true))
}

@(test)
nested_union_implicit_cast :: proc(t: ^testing.T) {
	Av: A: Bv
	Bv: B: Cv
	Cv: C: {}
	testing.expect_value(t, Av, A(B(C{})))
}

@(test)
union_ternary :: proc(t: ^testing.T) {
	E0 : A = B(C{}) if true else B(C{})
	E1 : A = true if true else true
	E2 := A(B(C{}) if true else B(C{}))
	E3 := A(true if true else true)

	testing.expect_value(t, E0, A(B(C{})))
	testing.expect_value(t, E1, A(true))
	testing.expect_value(t, E2, A(B(C{})))
	testing.expect_value(t, E3, A(true))
}

@(test)
union_array :: proc(t: ^testing.T) {
	C0: [2][2]A: B(C{})
	C1: struct {x: [2][2]A} : {B(C{})}
	testing.expect_value(t, C0, [2][2]A{0..<2 = B(C{})})
}

@(test)
union_multi_level_cast :: proc(t: ^testing.T) {
	UI :: union {int, bool}
	foo: Maybe(UI): 1
	bar: union{UI}: 2
	baz: UI: 3
	qux: struct{ui: UI}: {4}
	testing.expect_value(t, foo,    1)
	testing.expect_value(t, bar,    2)
	testing.expect_value(t, baz,    3)
	testing.expect_value(t, qux.ui, 4)
}

@(test)
union_args :: proc(t: ^testing.T) {
	implicit_bool :: proc(a: A = true   ) -> A { return a.(bool) }
	explicit_bool :: proc(a: A = A(true)) -> A { return a.(bool) }
	nil_union     :: proc(a: A = B{}    ) -> A { return a.(B   ) }
	struct_union  :: proc(a: A = B(C{}) ) -> A { return a.(B   ) }

	testing.expect_value(t, implicit_bool(), true)
	testing.expect_value(t, explicit_bool(), true)
	testing.expect_value(t, nil_union    (), B{})
	testing.expect_value(t, struct_union (), B(C{}))

	testing.expect_value(t, implicit_bool(true   ), true)
	testing.expect_value(t, explicit_bool(A(true)), true)
	testing.expect_value(t, nil_union    (B{}    ), B{})
	testing.expect_value(t, struct_union (B(C{}) ), B(C{}))

	testing.expect_value(t, implicit_bool(a=true   ), true)
	testing.expect_value(t, explicit_bool(a=A(true)), true)
	testing.expect_value(t, nil_union    (a=B{}    ), B{})
	testing.expect_value(t, struct_union (a=B(C{}) ), B(C{}))
}

@(test)
union_in_aggregates :: proc(t: ^testing.T) {
	S :: struct {
		x : union { int, string },
		y : u128,
	}
	U :: struct #packed {v: [2]S, n: i64}
	V :: struct {x: [dynamic; 2]S}

	s := [dynamic; 2]S { {x=1} }
	u := U { {{x=1}, {x=2}}, 2 }
	v := V{x = { {x=1} }}

	testing.expect_value(t, s  [0], S{x=1})
	testing.expect_value(t, u.v[1], S{x=2})
	testing.expect_value(t, v.x[0], S{x=1})
}

@(test)
union_named_constants :: proc(t: ^testing.T) {
	Inner_Left :: enum {
		a,
		b,
	}

	Inner_Right :: enum {
		c,
		d,
	}

	Inner :: union {
		Inner_Left,
		Inner_Right,
	}

	Outer :: union {
		Inner,
		int,
	}

	Atom :: struct {
		token: Outer,
	}

	Promoted_Value :: union {
		int,
		f32,
		string,
	}

	Promoted_Inner :: struct {
		value:    Promoted_Value,
		padding0: int,
		padding1: int,
	}

	Promoted_Outer :: struct {
		using inner: Promoted_Inner,
	}

	NAMED_INNER :: Inner(Inner_Left.a)

	DIRECT_ATOMS :: [?]Atom{{token = Inner(Inner_Left.a)}}

	NAMED_ATOMS :: [?]Atom{{token = NAMED_INNER}}

	INDEXED_OUTERS :: [1]Outer {
		0 = Inner(Inner_Left.a),
	}

	RANGED_OUTERS :: [1]Outer {
		0..=0 = Inner(Inner_Left.a),
	}

	Outer_Index :: enum {first}

	ENUMERATED_OUTERS :: [Outer_Index]Outer {
		.first = Inner(Inner_Left.a),
	}

	RANGED_ENUMERATED_OUTERS :: [Outer_Index]Outer {
		.first..=.first = Inner(Inner_Left.a),
	}

	FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
		0 = Inner(Inner_Left.a),
	}

	RANGED_FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
		0..=0 = Inner(Inner_Left.a),
	}

	POSITIONAL_FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
		Inner(Inner_Left.a),
	}

	testing.expect_value(t, DIRECT_ATOMS[0],                     Atom{token = Inner(.a)})
	testing.expect_value(t, NAMED_ATOMS[0],                      Atom{token = NAMED_INNER})
	testing.expect_value(t, INDEXED_OUTERS[0],                   Inner(.a))
	testing.expect_value(t, RANGED_OUTERS[0],                    Inner(.a))
	testing.expect_value(t, ENUMERATED_OUTERS[.first],           Inner(.a))
	testing.expect_value(t, RANGED_ENUMERATED_OUTERS[.first],    Inner(.a))
	fco := FIXED_CAPACITY_OUTERS
	rfco := RANGED_FIXED_CAPACITY_OUTERS
	testing.expect_value(t, fco[0],  Inner(.a))
	testing.expect_value(t, rfco[0], Inner(.a))
	testing.expect_value(t, POSITIONAL_FIXED_CAPACITY_OUTERS[0], Inner(.a))
	testing.expect_value(t, Promoted_Outer {
		value = Promoted_Value(int(1)),
	}, Promoted_Outer {
		inner = {Promoted_Value(int(1)), 0, 0},
	})
}
