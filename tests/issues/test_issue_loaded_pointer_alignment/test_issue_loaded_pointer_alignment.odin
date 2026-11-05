package test_issues

import "core:simd"
import "core:testing"

Packed :: struct #packed {
	v:    #simd[16]u8,
	rest: [70]u8, // > 64 bytes, so the copy below is a memmove
}

Packed_Slot :: struct #min_field_align(16) {
	p: ^Packed,
}

@(export)
double_packed :: #force_no_inline proc (s: ^Packed_Slot) -> #simd[16]u8 {
	x: Packed
	x = s.p^
	return x.v + x.v
}

@(test)
test_copy_through_aligned_pointer_slot :: proc(t: ^testing.T) {
	buf: [256]u8
	for &b, i in buf {
		b = u8(i)
	}
	s := Packed_Slot{p = (^Packed)(&buf[1])}
	v := double_packed(&s)
	testing.expect_value(t, simd.to_array(v), [16]u8{2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32})
}
