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


// small loads and stores (<= 64 byte) through a #packed field;
// access must not claim the field's type alignment (here 16),
// because the field is at align 1
// 1) through a ptr param (the field GEP carries is-packed metadata)
// 2) directly on the global (the GEP folds to ConstantExpr, no metadata)


Packed_Small :: struct #packed {
	_: u8,
	v: #simd[4]f32, // offset 1
	n: i64,         // offset 17
}

@(export)
p1: Packed_Small

@(export)
p2: Packed_Small

@(private="file")
swap_v :: proc(p: ^Packed_Small, x: #simd[4]f32) -> #simd[4]f32 {
	y := p.v
	p.v = x
	return y
}

@(test)
test_packed_field_pointer_access :: proc(t: ^testing.T) {
	p1.v = {1, 2, 3, 4} // store through a constant GEP

	old := #force_no_inline swap_v(&p1, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(old) == [4]f32{1, 2, 3, 4})
	testing.expect(t, simd.to_array(p1.v) == [4]f32{5, 6, 7, 8})
}

@(test)
test_packed_field_direct_access :: proc(t: ^testing.T) {
	p2.v = {9, 10, 11, 12} // store through a constant GEP
	p2.n = -1              // scalar store at offset 17

	y := p2.v              // load through a constant GEP
	testing.expect(t, simd.to_array(y) == [4]f32{9, 10, 11, 12})
	testing.expect(t, p2.n == -1)

	p2.v = {}              // 16 bytes is memset on most targets
	p2.n = 0               // zero small store path on every target
	testing.expect(t, simd.to_array(p2.v) == [4]f32{})
	testing.expect(t, p2.n == 0)
}
