package test_internal

import "base:intrinsics"
import "core:testing"

@(private="file")
Soa_Mixed :: struct {
	a: u8,
	b: f64,
	c: [3]u16,
	d: struct { x, y: i32 },
}

// `type_soa_field_sizes` points to the element size of each field of an #soa type
@(test)
test_soa_field_sizes :: proc(t: ^testing.T) {
	sizes := intrinsics.type_soa_field_sizes(#soa[dynamic]Soa_Mixed)
	testing.expect_value(t, len(sizes), 4)
	testing.expect_value(t, sizes^, [4]int{1, 8, 6, 8})

	// One table per type
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[dynamic]Soa_Mixed), sizes)

	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[]Soa_Mixed)^,  [4]int{1, 8, 6, 8})
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[7]Soa_Mixed)^, [4]int{1, 8, 6, 8})

	// An array element type has a field per element
	testing.expect_value(t, intrinsics.type_soa_field_sizes(#soa[][3]f64)^, [3]int{8, 8, 8})
}
