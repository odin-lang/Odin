#+feature dynamic-literals

package test_internal

import "core:testing"

@test
test_type_inference_on_literals_for_various_parameters_combinations :: proc(t: ^testing.T) {
	Bit_Set :: bit_set[enum{A, B, C}]
	group :: proc{proc_0, proc_1, proc_2, proc_3, proc_4, proc_5}
	proc_0 :: proc()                       -> int { return 0 }
	proc_1 :: proc(Bit_Set)                -> int { return 1 }
	proc_2 :: proc(int, Bit_Set)           -> int { return 2 }
	proc_3 :: proc(f32, Bit_Set)           -> int { return 3 }
	proc_4 :: proc(int, int, Bit_Set)      -> int { return 4 }
	proc_5 :: proc(Bit_Set, int, int, int) -> int { return 5 }

	testing.expect_value(t, group({.A}),          1)
	testing.expect_value(t, group(9, {.A}),       2)
	testing.expect_value(t, group(3.14, {.A}),    3)
	testing.expect_value(t, group(9, 9, {.A}),    4)
	testing.expect_value(t, group({.A}, 9, 9, 9), 5)
}

@test
test_type_inference_on_literals_with_default_args :: proc(t: ^testing.T) {
	{
		Bit_Set :: bit_set[enum{A, B, C}]
		proc_nil :: proc() { }
		proc_default_arg :: proc(a: Bit_Set={.A}) -> Bit_Set { return a }
		group :: proc{proc_nil, proc_default_arg}

		testing.expect_value(t, group(Bit_Set{.A}), Bit_Set{.A})
		testing.expect_value(t, group({.A}),        Bit_Set{.A})
	}
	{
		// NOTE: the overloads differ in arity so that only one is ever viable, i.e. this
		// checks what was inferred rather than which overload won. See
		// test_proc_group_default_arg_precedence for the latter.
		Bit_Set :: bit_set[enum{A, B, C}]
		proc_1 :: proc(a: Bit_Set={.A}) -> Bit_Set { return a }
		proc_2 :: proc(a, b: Bit_Set)   -> Bit_Set { return b }
		group :: proc{proc_1, proc_2}

		testing.expect_value(t, group(),               Bit_Set{.A})
		testing.expect_value(t, group(Bit_Set{.B}),    Bit_Set{.B})
		testing.expect_value(t, group({.B}),           Bit_Set{.B})
		testing.expect_value(t, group({.B}, {.C}),     Bit_Set{.C})
	}
}

@test
test_proc_group_default_arg_precedence :: proc(t: ^testing.T) {
	// An overload that needs fewer default arguments synthesised is the closer match, so
	// proc_1 wins whenever both are viable.
	Bit_Set :: bit_set[enum{A, B, C}]
	proc_1 :: proc(a: Bit_Set={.A})                  -> int { return 1 }
	proc_2 :: proc(a: Bit_Set={.B}, b: Bit_Set={.C}) -> int { return 2 }
	group :: proc{proc_1, proc_2}

	testing.expect_value(t, group(),            1) // proc_1 synthesises 1, proc_2 synthesises 2
	testing.expect_value(t, group(Bit_Set{.A}), 1) // proc_1 synthesises 0, proc_2 synthesises 1
	testing.expect_value(t, group({.A}),        1)
	testing.expect_value(t, group({.B}, {.C}),  2) // only proc_2 takes two arguments
}

@test
test_proc_group_arity_precedence :: proc(t: ^testing.T) {
	{
		// a non-variadic overload is the closer match when the variadic part is empty
		proc_exact    :: proc(x: int)           -> int { return 1 }
		proc_variadic :: proc(x: int, r: ..int) -> int { return 2 }
		group :: proc{proc_exact, proc_variadic}

		testing.expect_value(t, group(1),       1)
		testing.expect_value(t, group(1, 2, 3), 2)
	}
	{
		// adding a defaulted sibling must not steal an exact match from an existing member
		proc_int    :: proc(x: int)            -> int { return 1 }
		proc_string :: proc(x: string)         -> int { return 2 }
		proc_f32    :: proc(x: f32)            -> int { return 3 }
		proc_f32_d  :: proc(x: f32, y: int=0)  -> int { return 4 }
		proc_rune   :: proc(x: rune)           -> int { return 5 }
		group :: proc{proc_int, proc_string, proc_f32, proc_f32_d, proc_rune}

		v: f32
		testing.expect_value(t, group(v), 3)
	}
}

@test
test_proc_group_untyped_constant_default_type :: proc(t: ^testing.T) {
	// An untyped constant prefers its default type over other members of the same family,
	// and any same-family type over a cross-family one.
	{
		proc_int :: proc(int) -> int { return 1 }
		proc_i64 :: proc(i64) -> int { return 2 }
		group :: proc{proc_int, proc_i64}
		testing.expect_value(t, group(1), 1)
	}
	{
		// neither is the default type, but the integer family still beats the float one
		proc_i64 :: proc(i64) -> int { return 1 }
		proc_f64 :: proc(f64) -> int { return 2 }
		group :: proc{proc_i64, proc_f64}
		testing.expect_value(t, group(1), 1)
	}
	{
		proc_f32 :: proc(f32) -> int { return 1 }
		proc_f64 :: proc(f64) -> int { return 2 }
		group :: proc{proc_f32, proc_f64}
		testing.expect_value(t, group(1.5), 2)
	}
	{
		proc_rune :: proc(rune) -> int { return 1 }
		proc_int  :: proc(int)  -> int { return 2 }
		group :: proc{proc_rune, proc_int}
		testing.expect_value(t, group('x'), 1)
	}
	{
		proc_string  :: proc(string)  -> int { return 1 }
		proc_cstring :: proc(cstring) -> int { return 2 }
		group :: proc{proc_string, proc_cstring}
		testing.expect_value(t, group("hi"), 1)
	}
	{
		proc_bool :: proc(bool) -> int { return 1 }
		proc_b32  :: proc(b32)  -> int { return 2 }
		group :: proc{proc_bool, proc_b32}
		testing.expect_value(t, group(true), 1)
	}
	{
		// a value that does not fit the default type selects the overload that can hold it
		proc_u8  :: proc(u8)  -> int { return 1 }
		proc_i64 :: proc(i64) -> int { return 2 }
		group :: proc{proc_u8, proc_i64}
		testing.expect_value(t, group(100000), 2)
	}
}

@test
test_proc_group_polymorphic_precedence :: proc(t: ^testing.T) {
	// Candidates are ordered value-polymorphic > concrete > type-polymorphic: `proc($S: T)`
	// specializes on a compile-time value and is the most specific, `proc(x: $T)`
	// specializes on a type and is a fallback.
	{
		proc_concrete :: proc(x: int) -> int { return 1 }
		proc_generic  :: proc(x: $T)  -> int { return 2 }
		group :: proc{proc_concrete, proc_generic}

		testing.expect_value(t, group(1), 1)
		v: int = 1
		testing.expect_value(t, group(v), 1)
	}
	{
		// the generic is the only viable overload
		proc_concrete :: proc(x: string) -> int { return 1 }
		proc_generic  :: proc(x: $T)     -> int { return 2 }
		group :: proc{proc_concrete, proc_generic}
		testing.expect_value(t, group(1), 2)
	}
	{
		proc_static  :: proc($S: string) -> int { return 1 }
		proc_dynamic :: proc(s: string)  -> int { return 2 }
		group :: proc{proc_static, proc_dynamic}

		testing.expect_value(t, group("literal"), 1)
		s := "runtime"
		testing.expect_value(t, group(s), 2) // not a constant, only proc_dynamic is viable
	}
	{
		// all three tiers present, and the result must not depend on declaration order
		proc_generic  :: proc(x: $T)      -> int { return 3 }
		proc_concrete :: proc(s: string)  -> int { return 2 }
		proc_static   :: proc($S: string) -> int { return 1 }
		group :: proc{proc_generic, proc_concrete, proc_static}

		testing.expect_value(t, group("literal"), 1)
	}

	// NOTE: the two cases below are still reported as ambiguous. Both are in the
	// polymorphic instantiation machinery rather than in candidate scoring, and are
	// expected to be resolved by https://github.com/odin-lang/Odin/pull/7208
	//
	// A more specialised generic should beat a less specialised one:
	//
	// {
	// 	proc_slice   :: proc(x: $T/[]$E) -> int { return 1 }
	// 	proc_generic :: proc(x: $T)      -> int { return 2 }
	// 	group :: proc{proc_slice, proc_generic}
	//
	// 	s := []int{1}
	// 	testing.expect_value(t, group(s), 1)
	// }
	//
	// Passing a polymorphic procedure to a group whose members take procedure-typed
	// parameters: only foo_concrete can accept f_poly once instantiated.
	//
	// {
	// 	f_poly :: proc(x: $T) -> T { return x }
	// 	foo_concrete   :: proc(x: int, g: proc(int) -> int) -> int { return 1 }
	// 	foo_impossible :: proc(x: int, g: proc(int, int) -> string) -> int { return 2 }
	// 	group :: proc{foo_concrete, foo_impossible}
	//
	// 	testing.expect_value(t, group(1, f_poly), 1)
	// }
}

@test
test_type_inference_on_literals_for_various_types :: proc(t: ^testing.T) {
	proc_nil :: proc() { }

	proc_array :: proc(a: [3]f32) -> [3]f32 { return a }
	group_array :: proc{proc_nil, proc_array}
	testing.expect_value(t, group_array([3]f32{1.1, 2.2, 3.3}), [3]f32{1.1, 2.2, 3.3})
	testing.expect_value(t, group_array({1.1, 2.2, 3.3}),       [3]f32{1.1, 2.2, 3.3})
	testing.expect_value(t, group_array({0=1.1, 1=2.2, 2=3.3}), [3]f32{1.1, 2.2, 3.3})
	testing.expect_value(t, group_array({}),                    [3]f32{})

	proc_slice_u8 :: proc(a: []u8) -> []u8 { return a }
	group_slice_u8 :: proc{proc_nil, proc_slice_u8}
	testing.expect_value(t, len(group_slice_u8([]u8{1, 2, 3})),   3)
	testing.expect_value(t, len(group_slice_u8({1, 2, 3})),       3)
	testing.expect_value(t, len(group_slice_u8({0=1, 1=2, 2=3})), 3)
	testing.expect_value(t, len(group_slice_u8({})),              0)
	testing.expect_value(t, group_slice_u8(nil) == nil,           true)

	proc_dynamic_array :: proc(t: ^testing.T, array: [dynamic]u8, expected_len: int) {
		if expected_len < 0 {
			testing.expect_value(t, array == nil, true)
		} else {
			testing.expect_value(t, len(array), expected_len)
		}
		delete(array)
	}
	group_dynamic_array :: proc{proc_nil, proc_dynamic_array}
	group_dynamic_array(t, [dynamic]u8{1, 2, 3}, 3)
	group_dynamic_array(t, {1, 2, 3},            3)
	group_dynamic_array(t, {0=1, 1=2, 2=3},      3)
	group_dynamic_array(t, {},                   0)
	group_dynamic_array(t, nil,                  -1)

	Enum :: enum{A, B, C}
	proc_enum :: proc(a: Enum) -> Enum { return a }
	group_enum :: proc{proc_nil, proc_enum}
	testing.expect_value(t, group_enum(Enum.A), Enum.A)
	testing.expect_value(t, group_enum(.A),     Enum.A)

	proc_enumerated_array :: proc(a: [Enum]u8) -> [Enum]u8 { return a }
	group_enumerated_array :: proc{proc_nil, proc_enumerated_array}
	testing.expect_value(t, group_enumerated_array([Enum]u8{.A=1, .B=2, .C=3}), [Enum]u8{.A=1, .B=2, .C=3})
	testing.expect_value(t, group_enumerated_array({.A=1, .B=2, .C=3}),         [Enum]u8{.A=1, .B=2, .C=3})

	Bit_Set :: bit_set[enum{A, B, C}]
	proc_bit_set :: proc(a: Bit_Set) -> Bit_Set { return a }
	group_bit_set :: proc{proc_nil, proc_bit_set}
	testing.expect_value(t, group_bit_set(Bit_Set{.A}), Bit_Set{.A})
	testing.expect_value(t, group_bit_set({.A}),        Bit_Set{.A})
	testing.expect_value(t, group_bit_set({}),          Bit_Set{})

	Struct :: struct{a: int, b: int, c: int}
	proc_struct :: proc(a: Struct) -> Struct { return a }
	group_struct :: proc{proc_nil, proc_struct}
	testing.expect_value(t, group_struct(Struct{a = 9}), Struct{a = 9})
	testing.expect_value(t, group_struct({a = 9}),       Struct{a = 9})
	testing.expect_value(t, group_struct({}),            Struct{})

	Raw_Union :: struct #raw_union{int_: int, f32_: f32}
	proc_raw_union :: proc(a: Raw_Union) -> Raw_Union { return a }
	group_raw_union :: proc{proc_nil, proc_raw_union}
	testing.expect_value(t, group_raw_union(Raw_Union{int_ = 9}).int_, 9)
	testing.expect_value(t, group_raw_union({int_ = 9}).int_,          9)
	testing.expect_value(t, group_raw_union({}).int_,                  0)

	Union :: union{int, f32}
	proc_union :: proc(a: Union) -> Union { return a }
	group_union :: proc{proc_nil, proc_union}
	testing.expect_value(t, group_union(int(9)).(int), 9)
	testing.expect_value(t, group_union({}),           nil)

	proc_map :: proc(t: ^testing.T, map_: map[u8]u8, expected_len: int) {
		if expected_len < 0 {
			testing.expect_value(t, map_ == nil, true)
		} else {
			testing.expect_value(t, len(map_), expected_len)
		}
		delete(map_)
	}
	group_map :: proc{proc_nil, proc_map}
	group_map(t, map[u8]u8{1=1, 2=2}, 2)
	group_map(t, {1=1, 2=2},          2)
	group_map(t, {},                  0)
	group_map(t, nil,                 -1)

	Bit_Field :: bit_field u16 {a: u8|4, b: u8|4, c: u8|4}
	proc_bit_field :: proc(a: Bit_Field) -> Bit_Field { return a }
	group_bit_field :: proc{proc_nil, proc_bit_field}
	testing.expect_value(t, group_bit_field(Bit_Field{a = 1}), Bit_Field{a = 1})
	testing.expect_value(t, group_bit_field({a = 1}),          Bit_Field{a = 1})
	testing.expect_value(t, group_bit_field({}),               Bit_Field{})

	SOA_Array :: #soa[2]struct{int, int}
	proc_soa_array :: proc(a: SOA_Array) -> SOA_Array { return a }
	group_soa_array :: proc{proc_nil, proc_soa_array}
	testing.expect_value(t, len(group_soa_array(SOA_Array{{}, {}})),                                2)
	testing.expect_value(t, len(group_soa_array({struct{int, int}{1, 2}, struct{int, int}{1, 2}})), 2)
	testing.expect_value(t, len(group_soa_array({})),                                               2)
	testing.expect_value(t, len(soa_zip(a=[]int{1, 2}, b=[]int{3, 4})),                             2)

	proc_matrix :: proc(a: matrix[2,2]f32) -> matrix[2,2]f32 { return a }
	group_matrix :: proc{proc_nil, proc_matrix}
	testing.expect_value(t, group_matrix(matrix[2,2]f32{1, 2, 3, 4}), matrix[2,2]f32{1, 2, 3, 4})
	testing.expect_value(t, group_matrix(1),                          (matrix[2,2]f32)(1))
	testing.expect_value(t, group_matrix({1, 2, 3, 4}),               matrix[2,2]f32{1, 2, 3, 4})
	testing.expect_value(t, group_matrix({}),                         matrix[2,2]f32{})
}
