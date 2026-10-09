// Tests issue #6302 https://github.com/odin-lang/Odin/issues/6302
package test_issues

import "core:testing"

@(test)
test_issue_6302 :: proc(t: ^testing.T) {
	a := [2]matrix[2, 2]f32{{0, 1, 2, 3}, {4, 5, 6, 7}}
	b := matrix[2, 2]f32{10, 10, 10, 10}

	ab_plus := a + b
	testing.expect(t, ab_plus[0] == {10, 11, 12, 13})
	testing.expect(t, ab_plus[1] == {14, 15, 16, 17})

	ba_minus := b - a
	testing.expect(t, ba_minus[0] == {10, 9, 8, 7})
	testing.expect(t, ba_minus[1] == {6, 5, 4, 3})

	ab_mult := a * b
	testing.expect(t, ab_mult[0] == {10, 10, 50, 50})
	testing.expect(t, ab_mult[1] == {90, 90, 130, 130})

	ba_mult := b * a
	testing.expect(t, ba_mult[0] == {20, 40, 20, 40})
	testing.expect(t, ba_mult[1] == {100, 120, 100, 120})

	aa_mult := a * a
	testing.expect(t, aa_mult[0] == {2, 3, 6, 11})
	testing.expect(t, aa_mult[1] == {46, 55, 66, 79})

	n := [2][2]matrix[2, 2]f32{{a[0], a[1]}, {a[1], a[0]}}
	nb_mult := n * b
	testing.expect(t, nb_mult[0][1] == {90, 90, 130, 130})
	testing.expect(t, nb_mult[1][1] == {10, 10, 50, 50})

	a *= b
	testing.expect(t, a[0] == {10, 10, 50, 50})
	testing.expect(t, a[1] == {90, 90, 130, 130})
}
