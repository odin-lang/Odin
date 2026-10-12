package test_internal

import "core:simd"
import "core:testing"

// #align(N) below the type alignment;
// the struct only guarantees N for fields

Under_Aligned :: struct #align(1) {
	v: #simd[4]f32,
}

Under_Helper :: struct {
	force: #simd[4]f32,   // force align to 16
	_:     u8,
	s:     Under_Aligned, // offs 17, guaranteed misaligned
}

@(export)
u1: Under_Helper

@(private="file")
swap_under :: proc(s: ^Under_Aligned, x: #simd[4]f32) -> #simd[4]f32 {
	y := s.v
	s.v = x
	return y
}

@(test)
test_align_lowered_struct_access :: proc(t: ^testing.T) {
	u1.s.v = {1, 2, 3, 4} // store through const GEP

	y := #force_no_inline swap_under(&u1.s, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})
	testing.expect(t, simd.to_array(u1.s.v) == [4]f32{5, 6, 7, 8})
}


// #align(N) #raw_union below the type alignment

Under_Raw :: struct #raw_union #align(1) {
	v: #simd[4]f32,
	b: u8,
}

Raw_Helper :: struct {
	force: #simd[4]f32, // force align to 16
	_:     u8,
	r:     Under_Raw,   // offs 17, guaranteed misaligned
}

@(export)
u3: Raw_Helper

@(private="file")
swap_raw :: proc(r: ^Under_Raw, x: #simd[4]f32) -> #simd[4]f32 {
	y := r.v
	r.v = x
	return y
}

@(test)
test_align_lowered_raw_union_access :: proc(t: ^testing.T) {
	u3.r = Under_Raw{v = {1, 2, 3, 4}}

	y := #force_no_inline swap_raw(&u3.r, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})
	testing.expect(t, simd.to_array(u3.r.v) == [4]f32{5, 6, 7, 8})
}
