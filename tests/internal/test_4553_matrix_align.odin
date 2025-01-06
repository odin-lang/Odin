package test_internal

import "core:testing"

// See: https://github.com/odin-lang/Odin/issues/4553
// It would be great if Odin had the ability to test against LLVM output since
// this test erronously passing is dependent on alignment of the stack.
//
// Right now, I am manually checking LLVM ir

@test
test_4553_matrix_align :: proc(t: ^testing.T) {
	test_mat :: proc($T: typeid, $R: u32, $C: u32) {
		when R * C <= 16 {
			return_matrix :: proc() -> matrix[R, C]T {
				ret : matrix[R, C]T
				return ret
			}
			// the origin of the bug had to do with a temporary
			// created by a function return being loaded with bad
			// alignment. The bug only affected 4-element f32
			// matrices, but it would be prudent to test more than
			// that
			_ = return_matrix() * [C]T{}
		}
	}

	test_mat_set :: proc($T: typeid) {
		test_mat_row :: proc($T: typeid, $R: u32) {
			test_mat(T, R, 1)
			test_mat(T, R, 2)
			test_mat(T, R, 3)
			test_mat(T, R, 4)
			test_mat(T, R, 5)
			test_mat(T, R, 6)
		}
		test_mat_row(T, 1)
		test_mat_row(T, 2)
		test_mat_row(T, 3)
		test_mat_row(T, 4)
		test_mat_row(T, 5)
		test_mat_row(T, 6)

	}
	test_mat_set(f16)
	test_mat_set(f32)
	test_mat_set(f64)
	test_mat_set(i8)
	test_mat_set(i16)
	test_mat_set(i32)
	test_mat_set(i64)
	test_mat_set(i128)
}
