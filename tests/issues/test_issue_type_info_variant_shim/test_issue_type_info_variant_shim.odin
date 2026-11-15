// `runtime.Type_Info.variant` holds `^Type_Info_X`. The old by-value forms
// `case Type_Info_X:` and `.(Type_Info_X)` still compile, with a warning each.
package test_issue_type_info_variant_shim

import "base:runtime"
import "core:testing"

Foo :: struct {
	a: int,
	b: f32,
}

@(test)
test_value_case_binding :: proc(t: ^testing.T) {
	ti := runtime.type_info_base(type_info_of(Foo))

	matched := false
	#partial switch v in ti.variant {
	case runtime.Type_Info_Struct:
		matched = true
		testing.expect_value(t, v.field_count, 2)
		testing.expect_value(t, v.size, size_of(Foo))
		testing.expect_value(t, v.names[1], "b")
	case runtime.Type_Info_Union:
		testing.fail(t)
	}
	testing.expect(t, matched)
}

@(test)
test_reference_case_binding :: proc(t: ^testing.T) {
	ti := runtime.type_info_base(type_info_of(Foo))

	#partial switch &v in ti.variant {
	case runtime.Type_Info_Struct:
		testing.expect(t, &v == ti.variant.(^runtime.Type_Info_Struct))
		testing.expect(t, rawptr(&v) == rawptr(ti))
	case:
		testing.fail(t)
	}
}

@(test)
test_exhaustive_value_cases :: proc(t: ^testing.T) {
	kind := ""
	switch v in type_info_of(f32).variant {
	case runtime.Type_Info_Named:                        kind = "named"
	case runtime.Type_Info_Integer:                      kind = "integer"
	case runtime.Type_Info_Rune:                         kind = "rune"
	case runtime.Type_Info_Float:                        kind = "float"
	case runtime.Type_Info_Complex:                      kind = "complex"
	case runtime.Type_Info_Quaternion:                   kind = "quaternion"
	case runtime.Type_Info_String:                       kind = "string"
	case runtime.Type_Info_Boolean:                      kind = "boolean"
	case runtime.Type_Info_Any:                          kind = "any"
	case runtime.Type_Info_Type_Id:                      kind = "typeid"
	case runtime.Type_Info_Pointer:                      kind = "pointer"
	case runtime.Type_Info_Multi_Pointer:                kind = "multi_pointer"
	case runtime.Type_Info_Procedure:                    kind = "procedure"
	case runtime.Type_Info_Array:                        kind = "array"
	case runtime.Type_Info_Enumerated_Array:             kind = "enumerated_array"
	case runtime.Type_Info_Dynamic_Array:                kind = "dynamic_array"
	case runtime.Type_Info_Slice:                        kind = "slice"
	case runtime.Type_Info_Parameters:                   kind = "parameters"
	case runtime.Type_Info_Struct:                       kind = "struct"
	case runtime.Type_Info_Union:                        kind = "union"
	case runtime.Type_Info_Enum:                         kind = "enum"
	case runtime.Type_Info_Map:                          kind = "map"
	case runtime.Type_Info_Bit_Set:                      kind = "bit_set"
	case runtime.Type_Info_Simd_Vector:                  kind = "simd_vector"
	case runtime.Type_Info_Matrix:                       kind = "matrix"
	case runtime.Type_Info_Soa_Pointer:                  kind = "soa_pointer"
	case runtime.Type_Info_Bit_Field:                    kind = "bit_field"
	case runtime.Type_Info_Fixed_Capacity_Dynamic_Array: kind = "fixed_capacity_dynamic_array"
	case nil:                                            kind = "nil"
	}
	testing.expect_value(t, kind, "float")
}

@(test)
test_multi_type_case :: proc(t: ^testing.T) {
	ti := runtime.type_info_base(type_info_of(Foo))

	matched := false
	#partial switch v in ti.variant {
	case runtime.Type_Info_Struct, runtime.Type_Info_Union:
		_, is_struct := v.(^runtime.Type_Info_Struct)
		matched = is_struct
	}
	testing.expect(t, matched)
}

@(test)
test_value_assertions :: proc(t: ^testing.T) {
	ti := runtime.type_info_base(type_info_of(Foo))

	s, ok := ti.variant.(runtime.Type_Info_Struct)
	testing.expect(t, ok)
	testing.expect_value(t, s.field_count, 2)

	u, u_ok := ti.variant.(runtime.Type_Info_Union)
	testing.expect(t, !u_ok)
	testing.expect(t, u.variants == nil)

	_, e_ok := ti.variant.(runtime.Type_Info_Enum)
	testing.expect(t, !e_ok)

	testing.expect_value(t, ti.variant.(runtime.Type_Info_Struct).field_count, 2)
}

@(test)
test_address_of_assertions :: proc(t: ^testing.T) {
	ti := runtime.type_info_base(type_info_of(Foo))

	p := &ti.variant.(runtime.Type_Info_Struct)
	testing.expect(t, rawptr(p) == rawptr(ti))
	testing.expect_value(t, p.field_count, 2)

	q, q_ok := &ti.variant.(runtime.Type_Info_Struct)
	testing.expect(t, q_ok)
	testing.expect(t, q == p)

	r, r_ok := &ti.variant.(runtime.Type_Info_Union)
	testing.expect(t, !r_ok)
	testing.expect(t, r == nil)
}
