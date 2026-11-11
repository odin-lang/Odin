package test_core_math_linalg

import "core:math/linalg"
import "core:testing"

@(private="file")
vector_close :: proc(a, b: $V/[$N]$E, eps: f64) -> bool {
	for i in 0..<N {
		if abs(f64(a[i]) - f64(b[i])) > eps {
			return false
		}
	}
	return true
}

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

@test
test_polar_from_euclidean_radius :: proc(t: ^testing.T) {
	for v in ([]linalg.Vector3f64{{0, 0, 5}, {3, 4, 0}, {1, 2, 2}, {-2, -3, 6}}) {
		p := linalg.polar_from_euclidean(v)
		r := linalg.length(v)
		testing.expectf(t, abs(p.z - r) <= 1e-12, "polar_from_euclidean(%v).z = %v, want %v", v, p.z, r)
		back := linalg.euclidean_from_polar(p.xy) * p.z
		testing.expectf(t, vector_close(back, v, 1e-12), "euclidean_from_polar(polar_from_euclidean(%v)) = %v", v, back)
	}
	{
		v := linalg.Vector3f32{0, 0, 5}
		p := linalg.polar_from_euclidean(v)
		testing.expectf(t, p == {0, 0, 5}, "polar_from_euclidean(%v) = %v, want [0, 0, 5]", v, p)
	}
	{
		v := linalg.Vector3f16{0, 0, 5}
		p := linalg.polar_from_euclidean(v)
		testing.expectf(t, p == {0, 0, 5}, "polar_from_euclidean(%v) = %v, want [0, 0, 5]", v, p)
	}
}
