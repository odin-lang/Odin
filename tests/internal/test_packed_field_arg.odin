package test_internal

import "core:simd"
import "core:testing"

// passing a #packed struct field by value to an Odin cc proc;
// the field is at offset 1, so its address is misaligned
// for the type (type align 16);
// the backend must not pass the address as the indirect arg,
// cause the callee assumes the type alignment
//
// the global is exported so that the packed layout
// survives in memory at runtime

Vecs :: struct {
	a, b, c, d, e: #simd[4]f32,
}

Packed :: struct #packed {
	_:    u8,
	vecs: Vecs,
}

@(export)
a: Packed

@(private="file")
sum_vecs :: proc(v: Vecs) -> #simd[4]f32 {
	return v.a + v.b + v.c + v.d + v.e
}

@(test)
test_packed_field_arg :: proc(t: ^testing.T) {
	a.vecs = {
		{1, 1, 1, 1},
		{2, 2, 2, 2},
		{3, 3, 3, 3},
		{4, 4, 4, 4},
		{5, 5, 5, 5},
	}

	// misaligned
	s := #force_no_inline sum_vecs(a.vecs)
	testing.expect(t, simd.to_array(s) == [4]f32{15, 15, 15, 15})

	// same field through pointer
	pp := &a
	s = #force_no_inline sum_vecs(pp.vecs)
	testing.expect(t, simd.to_array(s) == [4]f32{15, 15, 15, 15})
}
