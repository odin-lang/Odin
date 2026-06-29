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
		Bit_Set :: bit_set[enum{A, B, C}]
		proc_1 :: proc(a: Bit_Set={.A})                  -> int { return 1 }
		proc_2 :: proc(a: Bit_Set={.B}, b: Bit_Set={.C}) -> int { return 2 }
		group :: proc{proc_1, proc_2}

		testing.expect_value(t, group(),            2)
		testing.expect_value(t, group(Bit_Set{.A}), 2)
		testing.expect_value(t, group({.A}),        2)
		testing.expect_value(t, group({.B}, {.C}),  2)
	}
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
