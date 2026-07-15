// Recursive polymorphic field queries must report a cycle instead of waiting forever.
package test_issues

import "base:intrinsics"

Value :: struct {
	x: int,
}

Recursive :: struct(t: typeid) {
	x: intrinsics.type_field_type(Recursive(t.x), "x"),
}

_ :: intrinsics.type_field_type(Recursive(Value), "x")
