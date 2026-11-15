package test_issue_8188

import "base:intrinsics"
import "core:testing"

Box :: struct($T: typeid) {
	v: T,
}

Rec :: struct($T: typeid) where size_of(T) > 0 {
	v: T,
}

Color :: enum {
	Red,
	Green,
}

box_size :: proc($E: typeid) -> int {
	b: Box(E)
	return size_of(b)
}

box_ptr_size :: proc($E: typeid) -> int {
	Concrete :: Box(E)
	p := (^Concrete)(nil)
	return size_of(p^)
}

boxed :: proc($T: typeid) -> Box(T) where intrinsics.type_is_integer(T) {
	return {}
}

enum_array :: proc($E: typeid) -> [E]int where intrinsics.type_is_enum(E) {
	return {}
}

rec_size :: proc($T: typeid, r: Rec(T)) -> int where size_of(T) > 1 {
	return size_of(r)
}

@(test)
test_typeid_instance_is_concrete :: proc(t: ^testing.T) {
	testing.expect_value(t, box_size(int), size_of(int))
	testing.expect_value(t, box_size(typeid), size_of(typeid))
	testing.expect_value(t, box_ptr_size(typeid), size_of(typeid))
}

@(test)
test_fixed_capacity_dynamic_typeid :: proc(t: ^testing.T) {
	a: [dynamic; 4]typeid
	append(&a, int)
	append(&a, f32)
	testing.expect_value(t, len(a), 2)
	testing.expect_value(t, a[0], int)
	testing.expect_value(t, a[1], f32)
}

@(test)
test_where_clauses_with_type_params :: proc(t: ^testing.T) {
	testing.expect_value(t, boxed(i32).v, 0)
	testing.expect_value(t, len(enum_array(Color)), 2)
	testing.expect_value(t, rec_size(i64, {}), size_of(i64))
}
