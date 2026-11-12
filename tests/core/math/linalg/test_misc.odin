package test_core_math_linalg

import "core:math"
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

@(private="file")
quaternion_close :: proc(a, b: $Q, eps: f64) -> bool {
	return abs(f64(a.w) - f64(b.w)) <= eps && abs(f64(a.x) - f64(b.x)) <= eps && abs(f64(a.y) - f64(b.y)) <= eps && abs(f64(a.z) - f64(b.z)) <= eps
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

@test
test_matrix1x1_adjugate_and_cofactor :: proc(t: ^testing.T) {
	{
		m := matrix[1, 1]f32{5}
		a := linalg.adjugate(m)
		c := linalg.cofactor(m)
		testing.expectf(t, a == 1, "adjugate(%v) = %v, want [1]", m, a)
		testing.expectf(t, c == 1, "cofactor(%v) = %v, want [1]", m, c)
		testing.expectf(t, m * a == linalg.determinant(m), "m * adjugate(m) = %v, want det(m)", m * a)
	}
	{
		m := matrix[1, 1]int{-7}
		a := linalg.adjugate(m)
		c := linalg.cofactor(m)
		testing.expectf(t, a == 1, "adjugate(%v) = %v, want [1]", m, a)
		testing.expectf(t, c == 1, "cofactor(%v) = %v, want [1]", m, c)
	}
}

@test
test_quaternion_from_forward_and_up :: proc(t: ^testing.T) {
	fwd := linalg.Vector3f64{1, 0, 0}
	up := linalg.Vector3f64{0, 1, 0}
	q := linalg.quaternion_from_forward_and_up(fwd, up)

	f := linalg.quaternion_mul_vector3(q, linalg.Vector3f64{0, 0, -1})
	testing.expectf(t, vector_close(f, fwd, 1e-12), "q * -Z = %v, want %v", f, fwd)
	u := linalg.quaternion_mul_vector3(q, linalg.Vector3f64{0, 1, 0})
	testing.expectf(t, vector_close(u, up, 1e-12), "q * +Y = %v, want %v", u, up)

	look := linalg.quaternion_look_at(linalg.Vector3f64{}, fwd, up)
	testing.expectf(t, quaternion_close(q, conj(look), 1e-12), "quaternion_from_forward_and_up = %v, want conj(quaternion_look_at) = %v", q, conj(look))
}

@test
test_quaternion_angle_between :: proc(t: ^testing.T) {
	{
		id := linalg.QUATERNIONF64_IDENTITY
		z90 := linalg.quaternion_angle_axis(f64(math.PI/2), linalg.Vector3f64{0, 0, 1})
		z270 := linalg.quaternion_angle_axis(f64(3*math.PI/2), linalg.Vector3f64{0, 0, 1})
		x180 := linalg.quaternion_angle_axis(f64(math.PI), linalg.Vector3f64{1, 0, 0})

		Case :: struct {
			a, b: linalg.Quaternionf64,
			want: f64,
		}
		for c in ([]Case{
			{id,     id,   0},
			{id,     -id,  0},
			{id,     z90,  math.PI/2},
			{id,     -z90, math.PI/2},
			{2 * id, z90,  math.PI/2},
			{id,     z270, math.PI/2},
			{id,     x180, math.PI},
			{z90,    z270, math.PI},
		}) {
			got := linalg.angle_between(c.a, c.b)
			testing.expectf(t, abs(got - c.want) <= 1e-12, "angle_between(%v, %v) = %v, want %v", c.a, c.b, got, c.want)
		}
	}
	{
		id := linalg.QUATERNIONF32_IDENTITY
		z90 := linalg.quaternion_angle_axis(f32(math.PI/2), linalg.Vector3f32{0, 0, 1})
		got := linalg.angle_between(id, z90)
		testing.expectf(t, abs(got - math.PI/2) <= 1e-6, "angle_between(id, z90) = %v, want %v", got, math.PI/2)
		got = linalg.angle_between(id, -id)
		testing.expectf(t, got == 0, "angle_between(id, -id) = %v, want 0", got)
	}
	{
		id := linalg.QUATERNIONF16_IDENTITY
		got := linalg.angle_between(id, -id)
		testing.expectf(t, got == 0, "angle_between(id, -id) = %v, want 0", got)
	}
}
