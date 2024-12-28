// Tests issue #4584 https://github.com/odin-lang/Odin/issues/4584
package test_issues

import "core:testing"
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