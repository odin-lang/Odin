package test_internal

import "core:simd"
import "core:testing"

U :: union { int, f64 }
Packed :: struct #packed { _: u8, arr: [2]int, u: U, fc: [dynamic; 4]int }

@(test)
test_packed_field_by_reference :: proc(t: ^testing.T) {
	p: Packed

	// array field of a #packed
	for &v in p.arr {
		v = 1
	}
	testing.expect_value(t, p.arr, [2]int{1, 1})

	#reverse for &v in p.arr {
		v = 2
	}
	testing.expect_value(t, p.arr, [2]int{2, 2})

	q := &p
	for &v in q.arr {
		v = 3
	}
	testing.expect_value(t, p.arr, [2]int{3, 3})

	// fixed capacity dyn array field of a #packed
	append(&p.fc, 1, 2)
	for &v in p.fc {
		v = 5
	}
	testing.expect_value(t, p.fc[0], 5)
	testing.expect_value(t, p.fc[1], 5)

	// type switch over a field of a #packed
	p.u = 1
	switch &v in p.u {
	case int: v = 42
	case f64: v = 0
	}
	testing.expect_value(t, p.u, U(42))

	// ptr to a variant of a union field of a #packed
	ptr := &p.u.(int)
	ptr^ = 7
	testing.expect_value(t, p.u, U(7))
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


// element access to an array field of a #packed

Packed_Array :: struct #packed {
	_:   u8,
	arr: [2]#simd[4]f32, // elems at offsets 1 and 17
}

@(export)
p2: Packed_Array

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
	p2.arr[0] = {1, 2, 3, 4}
	p2.arr[1] = {5, 6, 7, 8}

	y := #force_no_inline read_elem(&p2, 0)
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	y = #force_no_inline read_elem(&p2, 1)
	testing.expect(t, simd.to_array(y) == [4]f32{5, 6, 7, 8})

	#force_no_inline write_elem(&p2, 0, {9, 10, 11, 12})
	testing.expect(t, simd.to_array(p2.arr[0]) == [4]f32{9, 10, 11, 12})
}


// accesses derived from a #max_field_align struct's field
// (array element, nested struct field) must not assume more
// than the max_field_align cap

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


// a #min_field_align inner struct placed in a #packed outer struct;
// the outer's #packed provides only align 1;
// accesses must not assume the #min_field_align

Raised_Inner :: struct #min_field_align(16) {
	v: #simd[4]f32,
}

Packed_Raised :: struct #packed {
	_:     u8,
	inner: Raised_Inner, // offs 1
}

@(export)
p3: Packed_Raised

@(private="file")
swap_raised :: proc(p: ^Packed_Raised, x: #simd[4]f32) -> #simd[4]f32 {
	y := p.inner.v
	p.inner.v = x
	return y
}

@(test)
test_packed_field_min_align :: proc(t: ^testing.T) {
	p3.inner.v = {1, 2, 3, 4}

	y := #force_no_inline swap_raised(&p3, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})
	testing.expect(t, simd.to_array(p3.inner.v) == [4]f32{5, 6, 7, 8})
}


// by-reference type switch on a union field of a #packed struct;
// the bound case variable inherits the field GEP's is-packed metadata;
// accesses through it must not assume the variant type alignment

Packed_Union :: union {
	#simd[4]f32,
	u8,
}

Packed_With_Union :: struct #packed {
	_: u8,
	u: Packed_Union, // offset 1
}

Packed_Union_Helper :: struct {
	force: #simd[4]f32,       // force align to 16
	_:     u8,
	p:     Packed_With_Union, // offset 17, union at 18
}

@(export)
p4: Packed_Union_Helper

@(private="file")
swap_variant_ref :: proc(p: ^Packed_With_Union, x: #simd[4]f32) -> #simd[4]f32 {
	#partial switch &v in p.u {
	case #simd[4]f32:
		y := v
		v = x
		return y
	}
	return {}
}

@(test)
test_packed_field_union_type_switch_ref :: proc(t: ^testing.T) {
	p4.p.u = #simd[4]f32{1, 2, 3, 4}

	y := #force_no_inline swap_variant_ref(&p4.p, {5, 6, 7, 8})
	testing.expect(t, simd.to_array(y) == [4]f32{1, 2, 3, 4})

	v, ok := p4.p.u.(#simd[4]f32)
	testing.expect(t, ok)
	testing.expect(t, simd.to_array(v) == [4]f32{5, 6, 7, 8})
}


// element type conversion of an array field of a #packed,
// and matrix * array mul do a vector load of the array;
// the load must not assume the element type alignment

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

@(private="file")
mul_matrix :: proc(m: ^matrix[4, 4]f32, p: ^Packed_Conv) -> [4]f32 {
	return m^ * p.a4
}

@(test)
test_packed_field_array_conv :: proc(t: ^testing.T) {
	p5.a4 = {1.5, 2.5, 3.5, 4.5} // exactly represenatble

	y := #force_no_inline conv_float(&p5)
	testing.expect(t, y == [4]f64{1.5, 2.5, 3.5, 4.5})

	z := #force_no_inline conv_complex(&p5)
	testing.expect(t, z == [4]complex64{1.5, 2.5, 3.5, 4.5})

	m := matrix[4, 4]f32{
		2, 0, 0, 0,
		0, 2, 0, 0,
		0, 0, 2, 0,
		0, 0, 0, 2,
	}
	w := #force_no_inline mul_matrix(&m, &p5)
	testing.expect(t, w == [4]f32{3, 5, 7, 9}) // exact float
}
