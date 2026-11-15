package test_issue_8194

import "core:testing"

int_to_type :: proc($type: typeid) -> (val: type = cast(type)(5)) {
	return
}

int_to_type_2 :: proc($type: typeid) -> (val: type = (type)(5)) {
	return
}

int_to_type_3 :: proc($type: typeid) -> (val: type = type(5)) {
	return
}

add_two :: proc(value: ^$T) -> (r: T = T(2)) {
	r += value^
	return
}

@(test)
test_polymorphic_conversion_default :: proc(t: ^testing.T) {
	testing.expect_value(t, int_to_type(f32), 5)
	testing.expect_value(t, int_to_type_2(f32), 5)
	testing.expect_value(t, int_to_type_3(f32), 5)
	testing.expect_value(t, int_to_type_2(u8), 5)
	testing.expect_value(t, int_to_type_3(i64), 5)
	testing.expect_value(t, typeid_of(type_of(int_to_type_2(f64))), f64)
	testing.expect_value(t, typeid_of(type_of(int_to_type_3(i16))), i16)

	f: f32 = 1.5
	u: u8 = 3
	testing.expect_value(t, add_two(&f), 3.5)
	testing.expect_value(t, add_two(&u), 5)
}
