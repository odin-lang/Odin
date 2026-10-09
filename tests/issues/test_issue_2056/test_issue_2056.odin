// Tests issue #2056 https://github.com/odin-lang/Odin/issues/2056
package test_issues

import "core:testing"

@test
test_scalar_matrix_conversion :: proc(t: ^testing.T) {
	l := f32(1.0)
	m := (matrix[4,4]f32)(l)

	for i in 0..<4 {
		for j in 0..<4 {
			if i == j {
				testing.expectf(t, m[i,j] == 1, "expected 1 at m[%d,%d], found %f\n", i, j, m[i,j])
			} else {
				testing.expectf(t, m[i,j] == 0, "expected 0 at m[%d,%d], found %f\n", i, j, m[i,j])
			}
		}
	}
}

