package test_internal

import "core:simd"
import "core:testing"

// #align below the natural alignment

// Odin allocates and places the struct at align 1, so field accesses
// must not assume the field type natural alignment (here 16)
Under_Aligned :: struct #align(1) {
	v: #simd[4]f32,
}

// forces the global var below to align 16, this puts the
// underaligned member at a guaranteed misaligned offset
Under_Helper :: struct {
	force: #simd[4]f32,  // force align to 16
	_:     u8,
	s:     Under_Aligned, // offset 17
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
	u1.s.v = {1, 2, 3, 4} // store through a constant GEP

	y := #force_no_inline swap_under(&u1.s, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})
	testing.expect(t, simd.to_array(u1.s.v) == [4]f32{5, 6, 7, 8})
}


// #align union below the natural alignment;
// variant loads and stores go through a pointer cast of the union base,
// and not a GEP; these + the tag accesses must
// not assume more than the union's #align(N) alignment

Under_Union :: union #align(1) {
	#simd[4]f32,
	u8,
}

Union_Helper :: struct {
	force: #simd[4]f32,  // force align to 16
	_:     u8,
	u:     Under_Union,  // offset 17
}

@(export)
u2: Union_Helper

@(private="file")
read_variant :: proc(u: ^Under_Union) -> #simd[4]f32 {
	return u.(#simd[4]f32)
}

@(private="file")
write_variant :: proc(u: ^Under_Union, x: #simd[4]f32) {
	u^ = x
}

@(test)
test_align_lowered_union_variant :: proc(t: ^testing.T) {
	#force_no_inline write_variant(&u2.u, {1, 2, 3, 4})
	y := #force_no_inline read_variant(&u2.u)
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	u2.u = u8(7)
	b, ok := u2.u.(u8)
	testing.expect(t, ok)
	testing.expect(t, b == 7)
}


// by-reference type switch on an underaligned union;
// the case variable is a raw variant pointer;
// accesses through it must not assume more than the union's #align(N)

@(export)
u4: Union_Helper

@(private="file")
swap_by_ref :: proc(u: ^Under_Union, x: #simd[4]f32) -> #simd[4]f32 {
	#partial switch &v in u^ {
	case #simd[4]f32:
		y := v
		v = x
		return y
	}
	return {}
}

@(test)
test_align_lowered_union_type_switch_ref :: proc(t: ^testing.T) {
	u4.u = #simd[4]f32{1, 2, 3, 4}

	y := #force_no_inline swap_by_ref(&u4.u, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	v, ok := u4.u.(#simd[4]f32)
	testing.expect(t, ok)
	testing.expect(t, simd.to_array(v) == [4]f32{5, 6, 7, 8})
}


// #align #raw_union below the natural alignment
// (field pointers are zero-offset GEPs);
// accesses must not assume more than the union's #align(N) alignment

Under_Raw :: struct #raw_union #align(1) {
	v: #simd[4]f32,
	b: u8,
}

Raw_Helper :: struct {
	force: #simd[4]f32,  // force align to 16
	_:     u8,
	r:     Under_Raw,    // offset 17
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
