// Tests issue: https://github.com/odin-lang/Odin/issues/7010

package test_issues

Matrix4x4 :: struct {
	columns: [4]#simd[4]f32,
}

Matrix5x4 :: struct {
	columns: [5]#simd[4]f32,
}

Matrix4x2 :: struct {
	columns: [4]#simd[2]f32,
}

odin_add_vec4f32 :: proc (a: #simd[4]f32, b: #simd[4]f32) -> #simd[4]f32 {
  	return a + b
}

odin_add_vec2u32 :: proc (a: #simd[2]u32, b: #simd[2]u32) -> #simd[2]u32 {
  	return a + b
}

odin_add_matrix4x4 :: proc (a: Matrix4x4, b: Matrix4x4) -> Matrix4x4 {
	copy_mat := a
	copy_mat.columns[0] += b.columns[0]
	copy_mat.columns[1] += b.columns[1]
	copy_mat.columns[2] += b.columns[2]
	copy_mat.columns[3] += b.columns[3]
	return copy_mat
}

odin_add_matrix5x4 :: proc (a: Matrix5x4, b: Matrix5x4) -> Matrix5x4 {
	copy_mat := a
	copy_mat.columns[0] += b.columns[0]
	copy_mat.columns[1] += b.columns[1]
	copy_mat.columns[2] += b.columns[2]
	copy_mat.columns[3] += b.columns[3]
	copy_mat.columns[4] += b.columns[4]
	return copy_mat
}

odin_add_matrix4x2 :: proc (a: Matrix4x2, b: Matrix4x2) -> Matrix4x2 {
	copy_mat := a
	copy_mat.columns[0] += b.columns[0]
	copy_mat.columns[1] += b.columns[1]
	copy_mat.columns[2] += b.columns[2]
	copy_mat.columns[3] += b.columns[3]
	return copy_mat
}

foreign import ctest "build/test_issue_7010_c.o"
foreign ctest {
	c_add_vec4f32 :: proc "c" (a: #simd[4]f32, b: #simd[4]f32) -> #simd[4]f32 ---
	c_add_vec2u32 :: proc "c" (a: #simd[2]u32, b: #simd[2]u32) -> #simd[2]u32 ---
	c_add_matrix4x4 :: proc "c" (a: Matrix4x4, b: Matrix4x4) -> Matrix4x4 ---
	c_add_matrix5x4 :: proc "c" (a: Matrix5x4, b: Matrix5x4) -> Matrix5x4 ---
	c_add_matrix4x2 :: proc "c" (a: Matrix4x2, b: Matrix4x2) -> Matrix4x2 ---
}

import "core:testing"

@test
test_simd :: proc(t: ^testing.T) {
	a_f32 :#simd[4]f32 = {1.0, 2.0, 3.0, 4.0}
	b_f32 :#simd[4]f32 = {4.0, 3.0, 2.0, 1.0}

	a_u32 :#simd[2]u32 = {1, 2}
	b_u32 :#simd[2]u32 = {4, 3}

	mat_a_4x4: Matrix4x4 = {
		{{1.0, 0.0, 0.0, 0.0},
		{0.0, 2.0, 0.0, 0.0},
		{0.0, 0.0, 3.0, 0.0},
		{0.0, 0.0, 0.0, 4.0}},
	}

	mat_b_4x4: Matrix4x4 = {
		{{0.0, 0.0, 0.0, 0.0},
		{0.0, 1.0, 2.0, 0.0},
		{0.0, 3.0, 4.0, 0.0},
		{0.0, 0.0, 0.0, 0.0}},
	}

	mat_a_5x4: Matrix5x4 = {
		{{1.0, 0.0, 0.0, 0.0},
		{0.0, 2.0, 0.0, 0.0},
		{0.0, 0.0, 3.0, 0.0},
		{0.0, 0.0, 0.0, 4.0},
		{1.0, 0.0, 0.0, 1.0}},
	}

	mat_b_5x4: Matrix5x4 = {
		{{0.0, 0.0, 0.0, 0.0},
		{0.0, 1.0, 2.0, 0.0},
		{0.0, 3.0, 4.0, 0.0},
		{0.0, 0.0, 0.0, 0.0},
		{0.0, 1.0, 1.0, 0.0}},
	}

	mat_a_4x2: Matrix4x2 = {
		{{1.0, 0.0},
		 {0.0, 2.0},
		 {0.0, 0.0},
		 {0.0, 0.0}},
	}

	mat_b_4x2: Matrix4x2 = {
		{{0.0, 0.0},
		 {0.0, 1.0},
		 {0.0, 3.0},
		 {1.0, 0.0}},
	}

	odin_add_vec4_f32_result := odin_add_vec4f32(a_f32, b_f32)
	testing.expect(t, odin_add_vec4_f32_result == {5.0, 5.0, 5.0, 5.0})

	odin_add_vec2_u32_result := odin_add_vec2u32(a_u32, b_u32)
	testing.expect(t, odin_add_vec2_u32_result == {5, 5})

	odin_add_matrix4x4_result := odin_add_matrix4x4(mat_a_4x4, mat_b_4x4)
	testing.expect(t, odin_add_matrix4x4_result == {
		{{1.0, 0.0, 0.0, 0.0},
		{0.0, 3.0, 2.0, 0.0},
		{0.0, 3.0, 7.0, 0.0},
		{0.0, 0.0, 0.0, 4.0}},
	})

	odin_add_matrix5x4_result := odin_add_matrix5x4(mat_a_5x4, mat_b_5x4)
	testing.expect(t, odin_add_matrix5x4_result == {
		{{1.0, 0.0, 0.0, 0.0},
		{0.0, 3.0, 2.0, 0.0},
		{0.0, 3.0, 7.0, 0.0},
		{0.0, 0.0, 0.0, 4.0},
		{1.0, 1.0, 1.0, 1.0}},
	})

	odin_add_matrix4x2_result := odin_add_matrix4x2(mat_a_4x2, mat_b_4x2)
	testing.expect(t, odin_add_matrix4x2_result == {
		{{1.0, 0.0},
		 {0.0, 3.0},
		 {0.0, 3.0},
		 {1.0, 0.0}},
	})

	c_add_vec4_f32_result := c_add_vec4f32(a_f32, b_f32)
	testing.expect(t, c_add_vec4_f32_result == odin_add_vec4_f32_result)

	c_add_vec2_u32_result := c_add_vec2u32(a_u32, b_u32)
	testing.expect(t, c_add_vec2_u32_result == odin_add_vec2_u32_result)

	c_add_matrix4x4_result := c_add_matrix4x4(mat_a_4x4, mat_b_4x4)
	testing.expect(t, c_add_matrix4x4_result == odin_add_matrix4x4_result)

	c_add_matrix5x4_result := c_add_matrix5x4(mat_a_5x4, mat_b_5x4)
	testing.expect(t, c_add_matrix5x4_result == odin_add_matrix5x4_result)

	c_add_matrix4x2_result := c_add_matrix4x2(mat_a_4x2, mat_b_4x2)
	testing.expect(t, c_add_matrix4x2_result == odin_add_matrix4x2_result)
}

// clang -c test_issue_7010.c -o test_issue_7010_c.o
// odin test test_issue_7010.odin -file
