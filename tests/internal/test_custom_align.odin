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


// pass by val, the callee gets a ptr to the caller's storage;
// there is no temp copy, the struct only requires align 1

// big enough to get passed indirect
Under_Aligned_Big :: struct #align(1) {
	v: #simd[4]f32,
	w: #simd[4]f32,
}

Big_Helper :: struct {
	force: #simd[4]f32,        // force align to 16
	_:     u8,
	s:     Under_Aligned_Big, // offs 17, guaranteed misaligned
}

@(export)
u5: Big_Helper

@(private="file")
sum_fields :: proc(s: Under_Aligned_Big) -> #simd[4]f32 {
	return s.v + s.w
}

@(test)
test_align_lowered_struct_by_value :: proc(t: ^testing.T) {
	u5.s = {v = {1, 2, 3, 4}, w = {5, 6, 7, 8}}

	y := #force_no_inline sum_fields(u5.s)
	testing.expect(t, simd.to_array(y) == [4]f32{6, 8, 10, 12})
}


// #align(N) union below the variant alignment

Under_Union :: union #align(1) {
	#simd[4]f32,
	u8,
}

Union_Helper :: struct {
	force: #simd[4]f32, // force align to 16
	_:     u8,
	u:     Under_Union, // offs 17, guaranteed misaligned
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


// by-ref type switch on #align(N) union
// the case variable only gets the union's align N

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
