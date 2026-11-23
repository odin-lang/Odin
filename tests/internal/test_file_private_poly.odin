package test_internal

import "core:testing"

// test_file_private_poly_other.odin declares its own `private_poly` and `Private_Poly_Box` with different bodies
@(private="file")
private_poly :: proc(v: $T) -> T { return v + 1 }

@(private="file")
Private_Poly_Box :: struct($T: typeid) { v: T }

file_private_poly_this :: proc(v: i64) -> i64 { return private_poly(v) }

@(test)
file_private_poly_same_name :: proc(t: ^testing.T) {
	// each file's instantiation for the same type must keep its own body
	testing.expect_value(t, file_private_poly_this(10),  11)
	testing.expect_value(t, file_private_poly_other(10), 12)
	testing.expect_value(t, private_poly(i32(10)), 11)

	// and each file's specialization of a same-named type must stay its own type
	other := file_private_poly_box_other()
	testing.expect(t, typeid_of(Private_Poly_Box(i64)) != other)
	testing.expect_value(t, type_info_of(Private_Poly_Box(i64)).size, 8)
	testing.expect_value(t, type_info_of(other).size, 16)
}
