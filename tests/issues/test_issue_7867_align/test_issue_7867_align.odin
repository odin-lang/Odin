package test_issue_7867_align

import "core:testing"

// The alignment of a polymorphic record is no longer checked for its polymorphic specializations (#7867),
// but still is for each instantiation, so it can depend on the parameters.

Param_Align :: struct($N: int) #align(N) {
	x: u8,
}

Type_Align :: struct($T: typeid) #align(align_of(T) * 2) {
	x: T,
}

Field_Align :: struct($N: int) #min_field_align(N) #max_field_align(16) {
	a: u8,
	b: u8,
}

Other :: struct {
	a: u8,
	b: u64,
}

Other_Offset_Align :: struct($T: typeid) #align(offset_of(Other, b)) {
	x: T,
}

@(test)
test_poly_align :: proc(t: ^testing.T) {
	testing.expect_value(t, align_of(Param_Align(4)), 4)
	testing.expect_value(t, align_of(Param_Align(16)), 16)
	testing.expect_value(t, size_of(Param_Align(16)), 16)

	testing.expect_value(t, align_of(Type_Align(f64)), 16)
	testing.expect_value(t, align_of(Type_Align(u8)), 2)

	testing.expect_value(t, offset_of(Field_Align(4), b), 4)
	testing.expect_value(t, offset_of(Field_Align(8), b), 8)

	testing.expect_value(t, align_of(Other_Offset_Align(u8)), 8)
}

@(test)
test_poly_align_through_proc :: proc(t: ^testing.T) {
	align_through :: proc(x: Type_Align($T)) -> int {
		return align_of(Type_Align(T))
	}
	testing.expect_value(t, align_through(Type_Align(u8){}), 2)
	testing.expect_value(t, align_through(Type_Align(f32){}), 8)
}
