package test_core_math_linalg

import "core:math/linalg"
import "core:testing"

@test
test_matrix2_inverse_transpose :: proc(t: ^testing.T) {
	{
		m := linalg.Matrix2f16{1, 2, 3, 4}
		it := linalg.matrix2_inverse_transpose(m)
		e := linalg.transpose(linalg.inverse(m))
		testing.expectf(t, it == e, "matrix2_inverse_transpose = %v, want %v", it, e)
	}
	{
		m := linalg.Matrix2f32{1, 2, 3, 4}
		it := linalg.matrix2_inverse_transpose(m)
		e := linalg.transpose(linalg.inverse(m))
		testing.expectf(t, it == e, "matrix2_inverse_transpose = %v, want %v", it, e)
	}
	{
		m := linalg.Matrix2f64{1, 2, 3, 4}
		it := linalg.matrix2_inverse_transpose(m)
		e := linalg.transpose(linalg.inverse(m))
		testing.expectf(t, it == e, "matrix2_inverse_transpose = %v, want %v", it, e)
	}
}
