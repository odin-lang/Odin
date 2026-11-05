package test_issue_7875_7471

import "core:testing"

// Matrices and #simd vectors are comparable, so they are accepted as map keys, but the backend only
// knew how to hash them through the byte-wise path, which is skipped when the element type is a float.
// Building a map keyed by `matrix[2, 2]f32` (#7875) or `#simd[4]f32` (#7471) panicked in the compiler
// with "Unhandled type for hasher".

@(test)
test_matrix_float_key :: proc(t: ^testing.T) {
	m := make(map[matrix[2, 2]f32]int)
	defer delete(m)

	identity := matrix[2, 2]f32{1, 0, 0, 1}
	other    := matrix[2, 2]f32{0, 1, 1, 0}
	m[identity] = 42
	m[other]    = 7

	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m[identity], 42)
	testing.expect_value(t, m[matrix[2, 2]f32{1, 0, 0, 1}], 42)
	testing.expect_value(t, m[other], 7)
	_, ok := m[matrix[2, 2]f32{1, 2, 3, 4}]
	testing.expect(t, !ok)

	// the same key overwrites rather than adding another entry
	m[matrix[2, 2]f32{1, 0, 0, 1}] = 43
	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m[identity], 43)
}

@(test)
test_matrix_float_key_shapes :: proc(t: ^testing.T) {
	// non-square and #row_major, so the element count and not the stride drives the hash
	a := make(map[matrix[2, 3]f64]int)
	defer delete(a)
	a[matrix[2, 3]f64{1, 2, 3, 4, 5, 6}] = 1
	a[matrix[2, 3]f64{6, 5, 4, 3, 2, 1}] = 2
	testing.expect_value(t, len(a), 2)
	testing.expect_value(t, a[matrix[2, 3]f64{1, 2, 3, 4, 5, 6}], 1)
	testing.expect_value(t, a[matrix[2, 3]f64{6, 5, 4, 3, 2, 1}], 2)

	b := make(map[#row_major matrix[3, 2]f32]int)
	defer delete(b)
	b[#row_major matrix[3, 2]f32{1, 2, 3, 4, 5, 6}] = 1
	b[#row_major matrix[3, 2]f32{1, 2, 3, 4, 5, 7}] = 2
	testing.expect_value(t, len(b), 2)
	testing.expect_value(t, b[#row_major matrix[3, 2]f32{1, 2, 3, 4, 5, 6}], 1)
	testing.expect_value(t, b[#row_major matrix[3, 2]f32{1, 2, 3, 4, 5, 7}], 2)
}

@(test)
test_simd_float_key :: proc(t: ^testing.T) {
	m := make(map[#simd[4]f32]int)
	defer delete(m)

	m[#simd[4]f32{1, 2, 3, 4}] = 1
	m[#simd[4]f32{4, 3, 2, 1}] = 2

	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m[#simd[4]f32{1, 2, 3, 4}], 1)
	testing.expect_value(t, m[#simd[4]f32{4, 3, 2, 1}], 2)
	_, ok := m[#simd[4]f32{1, 2, 3, 5}]
	testing.expect(t, !ok)
}

@(test)
test_simd_float_key_signed_zero :: proc(t: ^testing.T) {
	// `==` on float vectors is element-wise, so `+0` and `-0` are the same key and must hash the same
	pos := #simd[2]f64{0, 1}
	neg := #simd[2]f64{-0.0, 1}
	testing.expect(t, pos == neg)

	m := make(map[#simd[2]f64]int)
	defer delete(m)
	m[pos] = 1
	testing.expect_value(t, m[neg], 1)
	m[neg] = 2
	testing.expect_value(t, len(m), 1)
	testing.expect_value(t, m[pos], 2)
}

Nested :: struct {
	transform: matrix[2, 2]f32,
	velocity:  #simd[4]f32,
	id:        int,
}

@(test)
test_nested_key :: proc(t: ^testing.T) {
	// the struct hasher asks for a hasher for each field, which hit the same panic
	m := make(map[Nested]int)
	defer delete(m)

	a := Nested{matrix[2, 2]f32{1, 0, 0, 1}, #simd[4]f32{1, 2, 3, 4}, 1}
	b := Nested{matrix[2, 2]f32{1, 0, 0, 1}, #simd[4]f32{1, 2, 3, 4}, 2}
	m[a] = 10
	m[b] = 20

	testing.expect_value(t, len(m), 2)
	testing.expect_value(t, m[a], 10)
	testing.expect_value(t, m[b], 20)

	arr := make(map[[2]matrix[2, 2]f32]int)
	defer delete(arr)
	arr[{matrix[2, 2]f32{1, 0, 0, 1}, matrix[2, 2]f32{2, 0, 0, 2}}] = 3
	testing.expect_value(t, arr[{matrix[2, 2]f32{1, 0, 0, 1}, matrix[2, 2]f32{2, 0, 0, 2}}], 3)
}

@(test)
test_integer_keys_unchanged :: proc(t: ^testing.T) {
	// integer elements still go through the byte-wise path
	m := make(map[matrix[2, 2]i32]int)
	defer delete(m)
	m[matrix[2, 2]i32{1, 0, 0, 1}] = 42
	testing.expect_value(t, m[matrix[2, 2]i32{1, 0, 0, 1}], 42)

	s := make(map[#simd[4]i32]int)
	defer delete(s)
	s[#simd[4]i32{1, 2, 3, 4}] = 7
	testing.expect_value(t, s[#simd[4]i32{1, 2, 3, 4}], 7)
}
