package test_internal

import "base:runtime"
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

	p2.v = {}              // zero vector store -> lb_mem_zero_ptr's direct store path on most targets
	p2.n = 0               // zero small store path on every target
	testing.expect(t, simd.to_array(p2.v) == [4]f32{})
	testing.expect(t, p2.n == 0)
}


// element access to an array field of a #packed

Packed_Array :: struct #packed {
	_:   u8,
	arr: [2]#simd[4]f32, // elems at offsets 1 and 17
}

@(export)
p3: Packed_Array

@(private="file")
read_elem :: proc(p: ^Packed_Array, i: int) -> #simd[4]f32 {
	return p.arr[i]
}

@(private="file")
write_elem :: proc(p: ^Packed_Array, i: int, x: #simd[4]f32) {
	p.arr[i] = x
}

@(test)
test_packed_field_array_element_access :: proc(t: ^testing.T) {
	p3.arr[0] = {1, 2, 3, 4}
	p3.arr[1] = {5, 6, 7, 8}

	y := #force_no_inline read_elem(&p3, 0)
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	y = #force_no_inline read_elem(&p3, 1)
	testing.expect(t, simd.to_array(y) == [4]f32{5, 6, 7, 8})

	#force_no_inline write_elem(&p3, 0, {9, 10, 11, 12})
	testing.expect(t, simd.to_array(p3.arr[0]) == [4]f32{9, 10, 11, 12})
}


// field access through ^runtime.Unaligned must compile to misalignment safe code

@(export)
p4: Packed_Small

@(private="file")
read_wrapped :: proc(u: ^runtime.Unaligned(#simd[4]f32)) -> #simd[4]f32 {
	return u.value
}

@(private="file")
write_wrapped :: proc(u: ^runtime.Unaligned(#simd[4]f32), x: #simd[4]f32) {
	u.value = x
}

@(test)
test_packed_field_unaligned_wrapper :: proc(t: ^testing.T) {
	p4.v = {1, 2, 3, 4}

	u := (^runtime.Unaligned(#simd[4]f32))(&p4.v) // addr of field at offset 1
	y := #force_no_inline read_wrapped(u)
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	#force_no_inline write_wrapped(u, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(p4.v) == [4]f32{5, 6, 7, 8})
}


// accesses derived from a '#max_field_align' struct's field
// (array element, nested struct field) must not claim more than
// the struct's field alignment cap

Capped_Inner :: struct { x: i64 }

Capped :: struct #max_field_align(4) {
	a:     u16,
	b:     u64,          // offset 4
	arr:   [2]u64,       // elems at offs 12 and 20
	inner: Capped_Inner, // x at offs 28
}

@(export)
c1: Capped

@(private="file")
swap_elem :: proc(c: ^Capped, i: int, v: u64) -> u64 {
	y := c.arr[i]
	c.arr[i] = v
	return y
}

@(private="file")
swap_nested :: proc(c: ^Capped, v: i64) -> i64 {
	y := c.inner.x
	c.inner.x = v
	return y
}

@(test)
test_max_field_align_derived_access :: proc(t: ^testing.T) {
	c1.b = 0xCAFECAFE_11223344
	c1.arr[0] = 1
	c1.arr[1] = 2
	c1.inner.x = -1

	y := #force_no_inline swap_elem(&c1, 1, 5)
	testing.expect(t, y == 2)
	testing.expect(t, c1.arr[0] == 1)
	testing.expect(t, c1.arr[1] == 5)

	z := #force_no_inline swap_nested(&c1, -2)
	testing.expect(t, z == -1)
	testing.expect(t, c1.inner.x == -2)
	testing.expect(t, c1.b == 0xCAFECAFE_11223344)
}


// element type conversion of an array field of a #packed
// goes through a vector load of the source array;
// the load must not claim the element type alignment

Packed_Conv :: struct #packed {
	_:  u8,
	a4: [4]f32, // offs 1
}

@(export)
p5: Packed_Conv

@(private="file")
conv_float :: proc(p: ^Packed_Conv) -> [4]f64 {
	return cast([4]f64)p.a4
}

@(private="file")
conv_complex :: proc(p: ^Packed_Conv) -> [4]complex64 {
	return cast([4]complex64)p.a4
}

@(test)
test_packed_field_array_conv :: proc(t: ^testing.T) {
	p5.a4 = {1.5, 2.5, 3.5, 4.5}

	y := #force_no_inline conv_float(&p5)
	testing.expect(t, y == [4]f64{1.5, 2.5, 3.5, 4.5})

	z := #force_no_inline conv_complex(&p5)
	testing.expect(t, z == [4]complex64{1.5, 2.5, 3.5, 4.5})
}
