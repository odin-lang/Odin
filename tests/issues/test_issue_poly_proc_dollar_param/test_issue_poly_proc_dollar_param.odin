package test_issue_poly_proc_dollar_param

import "core:testing"

@(private="file")
add_one :: proc "contextless" (value: ^$T) -> i32 { return i32(value^) + 1 }

@(private="file")
add_ten :: proc "contextless" (value: ^$T) -> i32 { return i32(value^) + 10 }

@(private="file")
apply_const_i32 :: proc "contextless" ($f: proc "contextless" (^i32) -> i32) -> i32 {
	x := i32(41)
	return f(&x)
}

@(private="file")
forward_const_i32 :: proc "contextless" ($f: proc "contextless" (^i32) -> i32) -> i32 {
	return apply_const_i32(f)
}

@(private="file")
Box :: struct($T: typeid) { value: T }

@(private="file")
apply_box :: proc "contextless" (box: Box($T), $f: proc "contextless" (^T) -> i32) -> i32 {
	value := box.value
	return f(&value)
}

@(private="file")
apply_with_arg_i32 :: proc "contextless" ($f: proc "contextless" (^i32) -> i32, x: i32) -> i32 {
	v := x
	return f(&v)
}

@(private="file")
apply_with_arg_i16 :: proc "contextless" ($f: proc "contextless" (^i16) -> i32, x: i16) -> i32 {
	v := x
	return f(&v)
}

@(private="file")
apply_with_arg :: proc{apply_with_arg_i32, apply_with_arg_i16}

@(private="file")
apply_runtime_i32 :: proc "contextless" (f: proc "contextless" (^i32) -> i32) -> i32 {
	x := i32(41)
	return f(&x)
}

@(private="file")
Callback_i32 :: proc "contextless" (^i32) -> i32

@(private="file")
apply_named_i32 :: proc "contextless" ($f: Callback_i32) -> i32 {
	x := i32(41)
	return f(&x)
}

@(private="file")
apply_runtime_with_arg_i32 :: proc "contextless" (f: proc "contextless" (^i32) -> i32, x: i32) -> i32 {
	v := x
	return f(&v)
}

@(private="file")
apply_runtime_with_arg_i16 :: proc "contextless" (f: proc "contextless" (^i16) -> i32, x: i16) -> i32 {
	v := x
	return f(&v)
}

@(private="file")
apply_runtime_with_arg :: proc{apply_runtime_with_arg_i32, apply_runtime_with_arg_i16}

@(private="file")
Base :: struct { value: i32 }

@(private="file")
Derived :: struct { using base: Base, extra: i32 }

@(private="file")
derived_value :: proc "contextless" (d: ^Derived, offset: $T) -> i32 { return d.value + i32(offset) }

@(test)
test_poly_proc_as_const_proc_param :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_const_i32(add_one), i32(42))
	testing.expect_value(t, apply_const_i32(add_ten), i32(51))
	testing.expect_value(t, apply_const_i32((add_one)), i32(42))
}

@(test)
test_poly_proc_forwarded_to_const_proc_param :: proc(t: ^testing.T) {
	testing.expect_value(t, forward_const_i32(add_one), i32(42))
	testing.expect_value(t, forward_const_i32(add_ten), i32(51))
}

@(test)
test_poly_proc_with_poly_struct_const_param :: proc(t: ^testing.T) {
	box_i32 := Box(i32){41}
	box_i16 := Box(i16){41}
	testing.expect_value(t, apply_box(box_i32, add_one), i32(42))
	testing.expect_value(t, apply_box(box_i32, add_ten), i32(51))
	testing.expect_value(t, apply_box(box_i16, add_one), i32(42))
	testing.expect_value(t, apply_box(box_i16, add_ten), i32(51))
}

@(test)
test_poly_proc_in_proc_group_const_param :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_with_arg(add_one, i32(41)), i32(42))
	testing.expect_value(t, apply_with_arg(add_one, i16(41)), i32(42))
	testing.expect_value(t, apply_with_arg(add_ten, i16(41)), i32(51))
}

@(test)
test_poly_proc_as_runtime_proc_param :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_runtime_i32(add_one), i32(42))
	testing.expect_value(t, apply_runtime_i32(add_ten), i32(51))
}

@(test)
test_poly_proc_as_named_proc_type_const_param :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_named_i32(add_one), i32(42))
	testing.expect_value(t, apply_named_i32(add_ten), i32(51))
}

@(test)
test_poly_proc_in_proc_group_runtime_param :: proc(t: ^testing.T) {
	testing.expect_value(t, apply_runtime_with_arg(add_one, i32(41)), i32(42))
	testing.expect_value(t, apply_runtime_with_arg(add_ten, i16(41)), i32(51))
}

@(test)
test_poly_proc_assigned_with_subtype_param :: proc(t: ^testing.T) {
	// a procedure taking `^Derived` is assignable to one taking `^Base`, as with non-polymorphic procedures
	f: proc "contextless" (^Base, int) -> i32 = derived_value
	d := Derived{{40}, 0}
	testing.expect_value(t, f(&d.base, 2), i32(42))
}
