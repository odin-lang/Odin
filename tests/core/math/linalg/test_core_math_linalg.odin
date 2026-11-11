package test_core_math_linalg

import "core:math"
import "core:math/linalg"
import "core:testing"

quaternion_close :: proc(a, b: $Q, eps: f64) -> bool {
	return abs(f64(a.w) - f64(b.w)) <= eps && abs(f64(a.x) - f64(b.x)) <= eps && abs(f64(a.y) - f64(b.y)) <= eps && abs(f64(a.z) - f64(b.z)) <= eps
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
