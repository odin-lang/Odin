package test_internal

import "core:testing"

// A constant aggregate over 64 bytes that is mostly zero is written by zeroing the destination and storing
// its non-zero parts, rather than by copying it whole out of read-only data. A struct literal mixing
// constant and run-time elements picks between the two the same way.
// Whichever is picked, every byte of the dest has to end up the same as a field-by-field assignment
// after zeroing memory would leave it (padding included).

@(private="file")
Sparse_Inner :: struct {
	x:   f32,
	tag: u8,
}

@(private="file")
Sparse :: struct {
	a:           u8,
	pad:         [100]u8,
	b:           i64,
	ptr:         ^int,
	using inner: Sparse_Inner,
	arr:         [8]i32,
	tail:        u16,
}

@(private="file")
Sparse_Dense :: struct {
	a: [20]i64,
	r: i64,
}

@(private="file")
Sparse_Slot :: struct {
	k:    i64,
	rest: [5]i64,
}

// few non-zero bytes, but more non-zero values than are stored one by one (16)
@(private="file")
Sparse_Wide :: struct {
	slots: [20]Sparse_Slot,
	n:     int,
}

// words is a single constant of 128 bytes inside a mostly zero struct
@(private="file")
Sparse_Blob :: struct {
	head:  u8,
	words: [16]u64,
	rest:  [1024]u8,
	n:     int,
}

@(private="file")
Sparse_Vectors :: struct {
	v:   #simd[4]f32,
	pad: [40]f32,
	w:   #simd[4]f32,
}

@(private="file")
Sparse_Packed :: struct #packed {
	x: u8,
	s: Sparse,
	y: u8,
}

@(private="file")
Sparse_Packed_Vectors :: struct #packed {
	x: u8,
	v: Sparse_Vectors,
}

@(private="file")
Sparse_Union :: union {
	Sparse,
	int,
}

@(private="file")
sparse_target: int

@(private="file")
sparse_dirty :: #force_no_inline proc(p: ^$T) {
	for &b in ([^]byte)(p)[:size_of(T)] {
		b = 0xaa
	}
}

@(private="file")
sparse_clear :: #force_no_inline proc(p: ^$T) {
	for &b in ([^]byte)(p)[:size_of(T)] {
		b = 0
	}
}

@(private="file")
sparse_same :: proc(a, b: ^$T) -> bool {
	x := ([^]byte)(a)[:size_of(T)]
	y := ([^]byte)(b)[:size_of(T)]
	for i in 0..<len(x) {
		if x[i] != y[i] {
			return false
		}
	}
	return true
}

@(private="file")
sparse_expected :: proc(want: ^Sparse, a: u8, b: i64, tag: u8) {
	sparse_clear(want)
	want.a      = a
	want.b      = b
	want.ptr    = &sparse_target
	want.x      = 3
	want.tag    = tag
	want.arr[7] = 9
	want.tail   = 5
}

@(private="file")
sparse_set_constant :: #force_no_inline proc(dst: ^Sparse) {
	dst^ = Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
}

@(private="file")
sparse_set_mixed :: #force_no_inline proc(dst: ^Sparse, a: u8, b: i64, tag: u8) {
	dst^ = Sparse{a = a, b = b, ptr = &sparse_target, x = 3, tag = tag, arr = {7 = 9}, tail = 5}
}

@(private="file")
sparse_set_nested :: #force_no_inline proc(dst: ^Sparse, tag: u8) {
	dst^ = Sparse{a = 1, b = 2, ptr = &sparse_target, inner = {x = 3, tag = tag}, arr = {7 = 9}, tail = 5}
}

@(private="file")
sparse_return_constant :: #force_no_inline proc() -> Sparse {
	return Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
}

@(private="file")
sparse_return_mixed :: #force_no_inline proc(a: u8, b: i64, tag: u8) -> Sparse {
	return Sparse{a = a, b = b, ptr = &sparse_target, x = 3, tag = tag, arr = {7 = 9}, tail = 5}
}

@(private="file")
sparse_set_vectors :: #force_no_inline proc(dst: ^Sparse_Vectors) {
	dst^ = Sparse_Vectors{v = {1, 2, 3, 4}, w = {5, 6, 7, 8}}
}

@(test)
test_sparse_literal_constant :: proc(t: ^testing.T) {
	want, got: Sparse
	sparse_expected(&want, 1, 2, 4)

	sparse_dirty(&got)
	sparse_set_constant(&got)
	testing.expect(t, sparse_same(&got, &want), "through a pointer")

	sparse_dirty(&got)
	got = sparse_return_constant()
	testing.expect(t, sparse_same(&got, &want), "returned")

	local := Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
	testing.expect(t, sparse_same(&local, &want), "local")

	elems: [3]Sparse
	sparse_dirty(&elems)
	index := len(elems) - 2
	elems[index] = Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
	testing.expect(t, sparse_same(&elems[1], &want), "array element")
	testing.expect(t, ([^]byte)(&elems[0])[size_of(Sparse)-1] == 0xaa, "element before is untouched")
	testing.expect(t, ([^]byte)(&elems[2])[0] == 0xaa, "element after is untouched")
}

@(test)
test_sparse_literal_mixed :: proc(t: ^testing.T) {
	want, got: Sparse
	sparse_expected(&want, 11, -12, 14)

	sparse_dirty(&got)
	sparse_set_mixed(&got, 11, -12, 14)
	testing.expect(t, sparse_same(&got, &want), "through a pointer")

	sparse_dirty(&got)
	got = sparse_return_mixed(11, -12, 14)
	testing.expect(t, sparse_same(&got, &want), "returned")

	sparse_expected(&want, 1, 2, 14)
	sparse_dirty(&got)
	sparse_set_nested(&got, 14)
	testing.expect(t, sparse_same(&got, &want), "nested literal")

	// the elements of a literal are all evaluated before it is assigned
	a, b: Sparse
	sparse_set_mixed(&a, 1, 2, 4)
	sparse_set_mixed(&b, 21, 22, 24)
	a, b = b, Sparse{a = a.a, b = a.b, ptr = &sparse_target, x = 3, tag = a.tag, arr = {7 = 9}, tail = 5}
	sparse_expected(&want, 21, 22, 24)
	testing.expect(t, sparse_same(&a, &want), "swapped in")
	sparse_expected(&want, 1, 2, 4)
	testing.expect(t, sparse_same(&b, &want), "built from the value it replaces")
}

@(test)
test_sparse_literal_positional :: proc(t: ^testing.T) {
	want, got: Sparse_Slot
	sparse_clear(&want)
	want.k       = 7
	want.rest[4] = 3

	sparse_dirty(&got)
	got = Sparse_Slot{7, {4 = 3}}
	testing.expect(t, sparse_same(&got, &want), "constant")

	k := i64(7)
	sparse_dirty(&got)
	got = Sparse_Slot{k, {4 = 3}}
	testing.expect(t, sparse_same(&got, &want), "mixed")
}

@(test)
test_sparse_literal_dense :: proc(t: ^testing.T) {
	want, got: Sparse_Dense
	sparse_clear(&want)
	for &v, i in want.a {
		v = i64(i + 1)
	}
	want.r = 99

	sparse_dirty(&got)
	got = Sparse_Dense{a = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}, r = 99}
	testing.expect(t, sparse_same(&got, &want), "constant")

	r := i64(99)
	sparse_dirty(&got)
	got = Sparse_Dense{a = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}, r = r}
	testing.expect(t, sparse_same(&got, &want), "mixed")
}

@(test)
test_sparse_literal_many_values :: proc(t: ^testing.T) {
	want, got: Sparse_Wide
	sparse_clear(&want)
	for &s, i in want.slots {
		s.k = i64(i + 1)
	}
	want.n = 5

	sparse_dirty(&got)
	got = Sparse_Wide{
		slots = {
			{k =  1}, {k =  2}, {k =  3}, {k =  4}, {k =  5}, {k =  6}, {k =  7}, {k =  8}, {k =  9}, {k = 10},
			{k = 11}, {k = 12}, {k = 13}, {k = 14}, {k = 15}, {k = 16}, {k = 17}, {k = 18}, {k = 19}, {k = 20},
		},
		n = 5,
	}
	testing.expect(t, sparse_same(&got, &want), "constant")

	sparse_clear(&want)
	want.slots[3].k       = 4
	want.slots[17].rest[2] = 6
	want.n = 5
	n := 5
	sparse_dirty(&got)
	got = Sparse_Wide{slots = {3 = {k = 4}, 17 = {rest = {2 = 6}}}, n = n}
	testing.expect(t, sparse_same(&got, &want), "few of many")
}

@(test)
test_sparse_literal_large_element :: proc(t: ^testing.T) {
	want, got: Sparse_Blob
	sparse_clear(&want)
	want.head = 1
	for &w, i in want.words {
		w = u64(i)*0x0101010101010101 + 3
	}
	want.n = 7

	M :: 0x0101010101010101
	sparse_dirty(&got)
	got = Sparse_Blob{
		head  = 1,
		words = {
			0*M + 3, 1*M + 3,  2*M + 3,  3*M + 3,  4*M + 3,  5*M + 3,  6*M + 3,  7*M + 3,
			8*M + 3, 9*M + 3, 10*M + 3, 11*M + 3, 12*M + 3, 13*M + 3, 14*M + 3, 15*M + 3,
		},
		n = 7,
	}
	testing.expect(t, sparse_same(&got, &want), "constant")

	n := 7
	sparse_dirty(&got)
	got = Sparse_Blob{
		head  = 1,
		words = {
			0*M + 3, 1*M + 3,  2*M + 3,  3*M + 3,  4*M + 3,  5*M + 3,  6*M + 3,  7*M + 3,
			8*M + 3, 9*M + 3, 10*M + 3, 11*M + 3, 12*M + 3, 13*M + 3, 14*M + 3, 15*M + 3,
		},
		n = n,
	}
	testing.expect(t, sparse_same(&got, &want), "mixed")
}

@(test)
test_sparse_literal_union_variant :: proc(t: ^testing.T) {
	want: Sparse
	sparse_expected(&want, 1, 2, 4)

	u: Sparse_Union = 5
	u = Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
	got, ok := &u.(Sparse)
	testing.expect(t, ok)
	testing.expect(t, ok && sparse_same(got, &want))
}

@(test)
test_sparse_literal_unaligned_destination :: proc(t: ^testing.T) {
	want: Sparse
	sparse_expected(&want, 1, 2, 4)

	p: Sparse_Packed
	sparse_dirty(&p)
	p.s = Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = 4, arr = {7 = 9}, tail = 5}
	got := p.s
	testing.expect(t, sparse_same(&got, &want), "packed field")
	testing.expect(t, p.x == 0xaa && p.y == 0xaa, "neighbouring fields are untouched")

	tag := u8(4)
	sparse_dirty(&p)
	p.s = Sparse{a = 1, b = 2, ptr = &sparse_target, x = 3, tag = tag, arr = {7 = 9}, tail = 5}
	got = p.s
	testing.expect(t, sparse_same(&got, &want), "packed field, mixed")
	testing.expect(t, p.x == 0xaa && p.y == 0xaa, "neighbouring fields are untouched")

	pv: Sparse_Packed_Vectors
	sparse_dirty(&pv)
	sparse_set_vectors(&pv.v)
	v := pv.v
	testing.expect(t, v.v == #simd[4]f32{1, 2, 3, 4}, "first vector")
	testing.expect(t, v.w == #simd[4]f32{5, 6, 7, 8}, "last vector")
	testing.expect(t, v.pad == [40]f32{}, "between the vectors")
	testing.expect(t, pv.x == 0xaa, "field before is untouched")
}
