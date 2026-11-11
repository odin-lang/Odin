package test_core_math_linalg

import "core:math"
import "core:math/linalg"
import "core:testing"

matrix_close :: proc(a, b: $M/matrix[$R, $C]$E, eps: f64) -> bool {
	for i in 0..<R {
		for j in 0..<C {
			if abs(f64(a[i, j]) - f64(b[i, j])) > eps {
				return false
			}
		}
	}
	return true
}

quaternion_close :: proc(a, b: $Q, eps: f64) -> bool {
	return abs(f64(a.w) - f64(b.w)) <= eps && abs(f64(a.x) - f64(b.x)) <= eps && abs(f64(a.y) - f64(b.y)) <= eps && abs(f64(a.z) - f64(b.z)) <= eps
}

check_adjoint :: proc(t: ^testing.T, m, adjoint: $M/matrix[$N, N]$E, loc := #caller_location) {
	e := linalg.adjugate(m)
	testing.expectf(t, adjoint == e, "%v: adjoint = %v, want %v", typeid_of(M), adjoint, e, loc = loc)
	d := linalg.determinant(m)
	p := m * adjoint
	testing.expectf(t, p == M(d), "%v: m * adjoint = %v, want %v * I", typeid_of(M), p, d, loc = loc)
}

@test
test_quaternion_nlerp_shortest_path :: proc(t: ^testing.T) {
	{
		id := linalg.QUATERNIONF32_IDENTITY
		q := linalg.quaternion_nlerp(id, -id, 0.5)
		testing.expectf(t, q == id, "nlerp(id, -id, 0.5) = %v, want %v", q, id)

		z90 := linalg.quaternion_angle_axis(f32(math.PI/2), linalg.Vector3f32{0, 0, 1})
		z45 := linalg.quaternion_angle_axis(f32(math.PI/4), linalg.Vector3f32{0, 0, 1})
		n := linalg.quaternion_nlerp(id, -z90, 0.5)
		testing.expectf(t, quaternion_close(n, z45, 1e-6), "nlerp(id, -z90, 0.5) = %v, want %v", n, z45)
	}
	{
		id := linalg.QUATERNIONF64_IDENTITY
		q := linalg.quaternion_nlerp(id, -id, 0.5)
		testing.expectf(t, q == id, "nlerp(id, -id, 0.5) = %v, want %v", q, id)

		z90 := linalg.quaternion_angle_axis(f64(math.PI/2), linalg.Vector3f64{0, 0, 1})
		z45 := linalg.quaternion_angle_axis(f64(math.PI/4), linalg.Vector3f64{0, 0, 1})
		n := linalg.quaternion_nlerp(id, -z90, 0.5)
		testing.expectf(t, quaternion_close(n, z45, 1e-12), "nlerp(id, -z90, 0.5) = %v, want %v", n, z45)
	}
}

@test
test_matrix_adjoint_is_adjugate :: proc(t: ^testing.T) {
	check_adjoint(t, linalg.Matrix2f16{1, 2, 3, 4}, linalg.matrix2_adjoint(linalg.Matrix2f16{1, 2, 3, 4}))
	check_adjoint(t, linalg.Matrix2f32{1, 2, 3, 4}, linalg.matrix2_adjoint(linalg.Matrix2f32{1, 2, 3, 4}))
	check_adjoint(t, linalg.Matrix2f64{1, 2, 3, 4}, linalg.matrix2_adjoint(linalg.Matrix2f64{1, 2, 3, 4}))

	m3_16 := linalg.Matrix3f16{2, 3, 5, 7, 11, 13, 17, 19, 23}
	m3_32 := linalg.Matrix3f32{2, 3, 5, 7, 11, 13, 17, 19, 23}
	m3_64 := linalg.Matrix3f64{2, 3, 5, 7, 11, 13, 17, 19, 23}
	check_adjoint(t, m3_16, linalg.matrix3_adjoint(m3_16))
	check_adjoint(t, m3_32, linalg.matrix3_adjoint(m3_32))
	check_adjoint(t, m3_64, linalg.matrix3_adjoint(m3_64))

	m4_32 := linalg.Matrix4f32{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53}
	m4_64 := linalg.Matrix4f64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53}
	check_adjoint(t, m4_32, linalg.matrix4_adjoint(m4_32))
	check_adjoint(t, m4_64, linalg.matrix4_adjoint(m4_64))
}

@test
test_matrix4_determinant_and_inverse :: proc(t: ^testing.T) {
	{
		m := linalg.Matrix4f32{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53}
		d := linalg.matrix4_determinant(m)
		testing.expectf(t, d == 880, "matrix4_determinant = %v, want 880", d)
		inv := linalg.matrix4_inverse(m)
		testing.expectf(t, matrix_close(inv, linalg.inverse(m), 1e-6), "matrix4_inverse = %v, want %v", inv, linalg.inverse(m))
		testing.expectf(t, matrix_close(m * inv, linalg.MATRIX4F32_IDENTITY, 1e-5), "m * matrix4_inverse = %v, want I", m * inv)
		it := linalg.matrix4_inverse_transpose(m)
		testing.expectf(t, it == linalg.transpose(inv), "matrix4_inverse_transpose = %v, want %v", it, linalg.transpose(inv))
	}
	{
		m := linalg.Matrix4f64{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53}
		d := linalg.matrix4_determinant(m)
		testing.expectf(t, d == 880, "matrix4_determinant = %v, want 880", d)
		inv := linalg.matrix4_inverse(m)
		testing.expectf(t, matrix_close(m * inv, linalg.MATRIX4F64_IDENTITY, 1e-12), "m * matrix4_inverse = %v, want I", m * inv)
	}
}
