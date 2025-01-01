// Tests issue #4584 https://github.com/odin-lang/Odin/issues/4584
package test_issues

import "core:testing"
import "core:log"
import "core:math/linalg"
import glm "core:math/linalg/glsl"
import hlm "core:math/linalg/hlsl"

@test
test_adjugate_2x2 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[2,2]int)
	m := matrix[2,2]int {
		-3, 2,
		-1, 0,
	}
	expected := matrix[2,2]int {
		 0, -2,
		 1, -3,
	}
	testing.expect_value(t, linalg.adjugate(m), expected)
	testing.expect_value(t, linalg.determinant(m), 2)
	testing.expect_value(t, linalg.adjugate(m) * m, 2 * I)
	testing.expect_value(t, m * linalg.adjugate(m), 2 * I)

	testing.expect_value(t, glm.adjugate(m), expected)
	testing.expect_value(t, glm.determinant(m), 2)
	testing.expect_value(t, glm.adjugate(m) * m, 2 * I)
	testing.expect_value(t, m * glm.adjugate(m), 2 * I)

	testing.expect_value(t, hlm.adjugate(m), expected)
	testing.expect_value(t, hlm.determinant(m), 2)
	testing.expect_value(t, hlm.adjugate(m) * m, 2 * I)
	testing.expect_value(t, m * hlm.adjugate(m), 2 * I)
}

@test
test_adjugate_3x3 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[3,3]int)
	m := matrix[3,3]int {
		-3,  2, -5,
		-1,  0, -2,
		 3, -4,  1,
	}
	expected := matrix[3,3]int {
		-8, 18, -4,
		-5, 12, -1,
		 4, -6,  2,
	}
	testing.expect_value(t, linalg.adjugate(m), expected)
	testing.expect_value(t, linalg.determinant(m), -6)
	testing.expect_value(t, linalg.adjugate(m) * m, -6 * I)
	testing.expect_value(t, m * linalg.adjugate(m), -6 * I)

	testing.expect_value(t, glm.adjugate(m), expected)
	testing.expect_value(t, glm.determinant(m), -6)
	testing.expect_value(t, glm.adjugate(m) * m, -6 * I)
	testing.expect_value(t, m * glm.adjugate(m), -6 * I)

	testing.expect_value(t, hlm.adjugate(m), expected)
	testing.expect_value(t, hlm.determinant(m), -6)
	testing.expect_value(t, hlm.adjugate(m) * m, -6 * I)
	testing.expect_value(t, m * hlm.adjugate(m), -6 * I)
}

@test
test_adjugate_4x4 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[4,4]int)
	m := matrix[4,4]int {
		-3,  2, -5, 1,
		-1,  0, -2, 2,
		 3, -4,  1, 3,
		 4,  5,  6, 7,
	}
	expected := matrix[4,4]int {
		-144,  266, -92, -16,
		 -57,   92,  -5, -16,
		 105, -142,  55,   2,
		  33,  -96,   9,  -6,
	}
	testing.expect_value(t, linalg.adjugate(m), expected)
	testing.expect_value(t, linalg.determinant(m), -174)
	testing.expect_value(t, linalg.adjugate(m) * m, -174 * I)
	testing.expect_value(t, m * linalg.adjugate(m), -174 * I)

	testing.expect_value(t, glm.adjugate(m), expected)
	testing.expect_value(t, glm.determinant(m), -174)
	testing.expect_value(t, glm.adjugate(m) * m, -174 * I)
	testing.expect_value(t, m * glm.adjugate(m), -174 * I)

	testing.expect_value(t, hlm.adjugate(m), expected)
	testing.expect_value(t, hlm.determinant(m), -174)
	testing.expect_value(t, hlm.adjugate(m) * m, -174 * I)
	testing.expect_value(t, m * hlm.adjugate(m), -174 * I)
}

@test
test_inverse_regression_2x2 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[2,2]f32)
	m := matrix[2,2]f32 {
		-3, 2,
		-1, 0,
	}
	expected := matrix[2,2]f32 {
		    0.0,     -1.0,
		1.0/2.0, -3.0/2.0,
	}
	expect_float_matrix_value(t, linalg.inverse(m), expected)
	expect_float_matrix_value(t, linalg.inverse_transpose(m), linalg.transpose(expected))
	expect_float_matrix_value(t, linalg.inverse(m) * m, I)
	expect_float_matrix_value(t, m * linalg.inverse(m), I)

	expect_float_matrix_value(t, glm.inverse(m), expected)
	expect_float_matrix_value(t, glm.inverse_transpose(m), glm.transpose(expected))
	expect_float_matrix_value(t, glm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * glm.inverse(m), I)

	expect_float_matrix_value(t, hlm.inverse(m), expected)
	expect_float_matrix_value(t, hlm.inverse_transpose(m), hlm.transpose(expected))
	expect_float_matrix_value(t, hlm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * hlm.inverse(m), I)
}

@test
test_inverse_regression_3x3 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[3,3]f32)
	m := matrix[3,3]f32 {
		-3,  2, -5,
		-1,  0, -2,
		 3, -4,  1,
	}
	expected := matrix[3,3]f32 {
		 4.0/3.0, -3.0,  2.0/3.0,
		 5.0/6.0, -2.0,  1.0/6.0,
		-2.0/3.0,  1.0, -1.0/3.0,
	}
	expect_float_matrix_value(t, linalg.inverse(m), expected)
	expect_float_matrix_value(t, linalg.inverse_transpose(m), linalg.transpose(expected))
	expect_float_matrix_value(t, linalg.inverse(m) * m, I)
	expect_float_matrix_value(t, m * linalg.inverse(m), I)

	expect_float_matrix_value(t, glm.inverse(m), expected)
	expect_float_matrix_value(t, glm.inverse_transpose(m), glm.transpose(expected))
	expect_float_matrix_value(t, glm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * glm.inverse(m), I)

	expect_float_matrix_value(t, hlm.inverse(m), expected)
	expect_float_matrix_value(t, hlm.inverse_transpose(m), hlm.transpose(expected))
	expect_float_matrix_value(t, hlm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * hlm.inverse(m), I)
}

@test
test_inverse_regression_4x4 :: proc(t: ^testing.T) {
	I := linalg.identity(matrix[4,4]f32)
	m := matrix[4,4]f32 {
		-3,  2, -5, 1,
		-1,  0, -2, 2,
		 3, -4,  1, 3,
		 4,  5,  6, 7,
	}
	expected := matrix[4,4]f32 {
		 24.0/29.0, -133.0/87.0,   46.0/87.0,  8.0/87.0,
		 19.0/58.0,  -46.0/87.0,   5.0/174.0,  8.0/87.0,
		-35.0/58.0,   71.0/87.0, -55.0/174.0, -1.0/87.0,
		-11.0/58.0,   16.0/29.0,   -3.0/58.0,  1.0/29.0,
	}
	expect_float_matrix_value(t, linalg.inverse(m), expected)
	expect_float_matrix_value(t, linalg.inverse_transpose(m), linalg.transpose(expected))
	expect_float_matrix_value(t, linalg.inverse(m) * m, I)
	expect_float_matrix_value(t, m * linalg.inverse(m), I)

	expect_float_matrix_value(t, glm.inverse(m), expected)
	expect_float_matrix_value(t, glm.inverse_transpose(m), glm.transpose(expected))
	expect_float_matrix_value(t, glm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * glm.inverse(m), I)

	expect_float_matrix_value(t, hlm.inverse(m), expected)
	expect_float_matrix_value(t, hlm.inverse_transpose(m), hlm.transpose(expected))
	expect_float_matrix_value(t, hlm.inverse(m) * m, I)
	expect_float_matrix_value(t, m * hlm.inverse(m), I)
}

@(private="file")
expect_float_matrix_value :: proc(t: ^testing.T, value, expected: $M/matrix[$N, N]f32, loc := #caller_location, value_expr := #caller_expression(value)) -> bool {
	ok := true
	outer: for i in 0..<N {
		for j in 0..<N {
			diff := abs(value[i, j] - expected[i, j])
			if diff > 1e-6 {
				ok = false
				break outer
			}
		}
	}
	if !ok do log.errorf("expected %v to be %v, got %v", value_expr, expected, value, location=loc)
	return ok
}