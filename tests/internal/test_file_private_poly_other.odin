#+private file
package test_internal

private_poly :: proc(v: $T) -> T { return v + 2 }

Private_Poly_Box :: struct($T: typeid) { v, w: T }

@(private="package")
file_private_poly_other :: proc(v: i64) -> i64 { return private_poly(v) }

@(private="package")
file_private_poly_box_other :: proc() -> typeid { return Private_Poly_Box(i64) }
