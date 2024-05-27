package linalg

import "core:math"

@(require_results)
euler_angles_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64, order: Euler_Angle_Order) -> (t1, t2, t3: f64) {
	switch order {
	case .XYZ: t1, t2, t3 = euler_angles_xyz_from_matrix3(m)
	case .XZY: t1, t2, t3 = euler_angles_xzy_from_matrix3(m)
	case .YXZ: t1, t2, t3 = euler_angles_yxz_from_matrix3(m)
	case .YZX: t1, t2, t3 = euler_angles_yzx_from_matrix3(m)
	case .ZXY: t1, t2, t3 = euler_angles_zxy_from_matrix3(m)
	case .ZYX: t1, t2, t3 = euler_angles_zyx_from_matrix3(m)
	case .XYX: t1, t2, t3 = euler_angles_xyx_from_matrix3(m)
	case .XZX: t1, t2, t3 = euler_angles_xzx_from_matrix3(m)
	case .YXY: t1, t2, t3 = euler_angles_yxy_from_matrix3(m)
	case .YZY: t1, t2, t3 = euler_angles_yzy_from_matrix3(m)
	case .ZXZ: t1, t2, t3 = euler_angles_zxz_from_matrix3(m)
	case .ZYZ: t1, t2, t3 = euler_angles_zyz_from_matrix3(m)
	}
	return
}
@(require_results)
euler_angles_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64, order: Euler_Angle_Order) -> (t1, t2, t3: f64) {
	switch order {
	case .XYZ: t1, t2, t3 = euler_angles_xyz_from_matrix4(m)
	case .XZY: t1, t2, t3 = euler_angles_xzy_from_matrix4(m)
	case .YXZ: t1, t2, t3 = euler_angles_yxz_from_matrix4(m)
	case .YZX: t1, t2, t3 = euler_angles_yzx_from_matrix4(m)
	case .ZXY: t1, t2, t3 = euler_angles_zxy_from_matrix4(m)
	case .ZYX: t1, t2, t3 = euler_angles_zyx_from_matrix4(m)
	case .XYX: t1, t2, t3 = euler_angles_xyx_from_matrix4(m)
	case .XZX: t1, t2, t3 = euler_angles_xzx_from_matrix4(m)
	case .YXY: t1, t2, t3 = euler_angles_yxy_from_matrix4(m)
	case .YZY: t1, t2, t3 = euler_angles_yzy_from_matrix4(m)
	case .ZXZ: t1, t2, t3 = euler_angles_zxz_from_matrix4(m)
	case .ZYZ: t1, t2, t3 = euler_angles_zyz_from_matrix4(m)
	}
	return
}
@(require_results)
euler_angles_from_quaternion_f64 :: proc "contextless" (m: Quaternionf64, order: Euler_Angle_Order) -> (t1, t2, t3: f64) {
	switch order {
	case .XYZ: t1, t2, t3 = euler_angles_xyz_from_quaternion(m)
	case .XZY: t1, t2, t3 = euler_angles_xzy_from_quaternion(m)
	case .YXZ: t1, t2, t3 = euler_angles_yxz_from_quaternion(m)
	case .YZX: t1, t2, t3 = euler_angles_yzx_from_quaternion(m)
	case .ZXY: t1, t2, t3 = euler_angles_zxy_from_quaternion(m)
	case .ZYX: t1, t2, t3 = euler_angles_zyx_from_quaternion(m)
	case .XYX: t1, t2, t3 = euler_angles_xyx_from_quaternion(m)
	case .XZX: t1, t2, t3 = euler_angles_xzx_from_quaternion(m)
	case .YXY: t1, t2, t3 = euler_angles_yxy_from_quaternion(m)
	case .YZY: t1, t2, t3 = euler_angles_yzy_from_quaternion(m)
	case .ZXZ: t1, t2, t3 = euler_angles_zxz_from_quaternion(m)
	case .ZYZ: t1, t2, t3 = euler_angles_zyz_from_quaternion(m)
	}
	return
}

@(require_results)
matrix3_from_euler_angles_f64 :: proc "contextless" (t1, t2, t3: f64, order: Euler_Angle_Order) -> (m: Matrix3f64) {
	switch order {
	case .XYZ: return matrix3_from_euler_angles_xyz(t1, t2, t3) // m1, m2, m3 = X(t1), Y(t2), Z(t3);
	case .XZY: return matrix3_from_euler_angles_xzy(t1, t2, t3) // m1, m2, m3 = X(t1), Z(t2), Y(t3);
	case .YXZ: return matrix3_from_euler_angles_yxz(t1, t2, t3) // m1, m2, m3 = Y(t1), X(t2), Z(t3);
	case .YZX: return matrix3_from_euler_angles_yzx(t1, t2, t3) // m1, m2, m3 = Y(t1), Z(t2), X(t3);
	case .ZXY: return matrix3_from_euler_angles_zxy(t1, t2, t3) // m1, m2, m3 = Z(t1), X(t2), Y(t3);
	case .ZYX: return matrix3_from_euler_angles_zyx(t1, t2, t3) // m1, m2, m3 = Z(t1), Y(t2), X(t3);
	case .XYX: return matrix3_from_euler_angles_xyx(t1, t2, t3) // m1, m2, m3 = X(t1), Y(t2), X(t3);
	case .XZX: return matrix3_from_euler_angles_xzx(t1, t2, t3) // m1, m2, m3 = X(t1), Z(t2), X(t3);
	case .YXY: return matrix3_from_euler_angles_yxy(t1, t2, t3) // m1, m2, m3 = Y(t1), X(t2), Y(t3);
	case .YZY: return matrix3_from_euler_angles_yzy(t1, t2, t3) // m1, m2, m3 = Y(t1), Z(t2), Y(t3);
	case .ZXZ: return matrix3_from_euler_angles_zxz(t1, t2, t3) // m1, m2, m3 = Z(t1), X(t2), Z(t3);
	case .ZYZ: return matrix3_from_euler_angles_zyz(t1, t2, t3) // m1, m2, m3 = Z(t1), Y(t2), Z(t3);
	}
	return
}
@(require_results)
matrix4_from_euler_angles_f64 :: proc "contextless" (t1, t2, t3: f64, order: Euler_Angle_Order) -> (m: Matrix4f64) {
	switch order {
	case .XYZ: return matrix4_from_euler_angles_xyz(t1, t2, t3) // m1, m2, m3 = X(t1), Y(t2), Z(t3);
	case .XZY: return matrix4_from_euler_angles_xzy(t1, t2, t3) // m1, m2, m3 = X(t1), Z(t2), Y(t3);
	case .YXZ: return matrix4_from_euler_angles_yxz(t1, t2, t3) // m1, m2, m3 = Y(t1), X(t2), Z(t3);
	case .YZX: return matrix4_from_euler_angles_yzx(t1, t2, t3) // m1, m2, m3 = Y(t1), Z(t2), X(t3);
	case .ZXY: return matrix4_from_euler_angles_zxy(t1, t2, t3) // m1, m2, m3 = Z(t1), X(t2), Y(t3);
	case .ZYX: return matrix4_from_euler_angles_zyx(t1, t2, t3) // m1, m2, m3 = Z(t1), Y(t2), X(t3);
	case .XYX: return matrix4_from_euler_angles_xyx(t1, t2, t3) // m1, m2, m3 = X(t1), Y(t2), X(t3);
	case .XZX: return matrix4_from_euler_angles_xzx(t1, t2, t3) // m1, m2, m3 = X(t1), Z(t2), X(t3);
	case .YXY: return matrix4_from_euler_angles_yxy(t1, t2, t3) // m1, m2, m3 = Y(t1), X(t2), Y(t3);
	case .YZY: return matrix4_from_euler_angles_yzy(t1, t2, t3) // m1, m2, m3 = Y(t1), Z(t2), Y(t3);
	case .ZXZ: return matrix4_from_euler_angles_zxz(t1, t2, t3) // m1, m2, m3 = Z(t1), X(t2), Z(t3);
	case .ZYZ: return matrix4_from_euler_angles_zyz(t1, t2, t3) // m1, m2, m3 = Z(t1), Y(t2), Z(t3);
	}
	return
}

@(require_results)
quaternion_from_euler_angles_f64 :: proc "contextless" (t1, t2, t3: f64, order: Euler_Angle_Order) -> Quaternionf64 {
	X :: quaternion_from_euler_angle_x
	Y :: quaternion_from_euler_angle_y
	Z :: quaternion_from_euler_angle_z

	q1, q2, q3: Quaternionf64

	switch order {
	case .XYZ: q1, q2, q3 = X(t1), Y(t2), Z(t3)
	case .XZY: q1, q2, q3 = X(t1), Z(t2), Y(t3)
	case .YXZ: q1, q2, q3 = Y(t1), X(t2), Z(t3)
	case .YZX: q1, q2, q3 = Y(t1), Z(t2), X(t3)
	case .ZXY: q1, q2, q3 = Z(t1), X(t2), Y(t3)
	case .ZYX: q1, q2, q3 = Z(t1), Y(t2), X(t3)
	case .XYX: q1, q2, q3 = X(t1), Y(t2), X(t3)
	case .XZX: q1, q2, q3 = X(t1), Z(t2), X(t3)
	case .YXY: q1, q2, q3 = Y(t1), X(t2), Y(t3)
	case .YZY: q1, q2, q3 = Y(t1), Z(t2), Y(t3)
	case .ZXZ: q1, q2, q3 = Z(t1), X(t2), Z(t3)
	case .ZYZ: q1, q2, q3 = Z(t1), Y(t2), Z(t3)
	}

	return q1 * (q2 * q3)
}


// Quaternionf64s

@(require_results)
quaternion_from_euler_angle_x_f64 :: proc "contextless" (angle_x: f64) -> (q: Quaternionf64) {
	return quaternion_angle_axis_f64(angle_x, {1, 0, 0})
}
@(require_results)
quaternion_from_euler_angle_y_f64 :: proc "contextless" (angle_y: f64) -> (q: Quaternionf64) {
	return quaternion_angle_axis_f64(angle_y, {0, 1, 0})
}
@(require_results)
quaternion_from_euler_angle_z_f64 :: proc "contextless" (angle_z: f64) -> (q: Quaternionf64) {
	return quaternion_angle_axis_f64(angle_z, {0, 0, 1})
}

@(require_results)
quaternion_from_pitch_yaw_roll_f64 :: proc "contextless" (pitch, yaw, roll: f64) -> Quaternionf64 {
	a, b, c := pitch, yaw, roll

	ca, sa := math.cos(a*0.5), math.sin(a*0.5)
	cb, sb := math.cos(b*0.5), math.sin(b*0.5)
	cc, sc := math.cos(c*0.5), math.sin(c*0.5)

	q: Quaternionf64
	q.x = sa*cb*cc - ca*sb*sc
	q.y = ca*sb*cc + sa*cb*sc
	q.z = ca*cb*sc - sa*sb*cc
	q.w = ca*cb*cc + sa*sb*sc
	return q
}

@(require_results)
roll_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> f64 {
	return math.atan2(2 * q.x*q.y + q.w*q.z, q.w*q.w + q.x*q.x - q.y*q.y - q.z*q.z)
}

@(require_results)
pitch_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> f64 {
	y := 2 * (q.y*q.z + q.w*q.x)
	x := q.w*q.w - q.x*q.x - q.y*q.y + q.z*q.z

	if abs(x) <= F64_EPSILON && abs(y) <= F64_EPSILON {
		return 2 * math.atan2(q.x, q.w)
	}

	return math.atan2(y, x)
}

@(require_results)
yaw_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> f64 {
	return math.asin(clamp(-2 * (q.x*q.z - q.w*q.y), -1, 1))
}


@(require_results)
pitch_yaw_roll_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (pitch, yaw, roll: f64) {
	pitch = pitch_from_quaternion(q)
	yaw = yaw_from_quaternion(q)
	roll = roll_from_quaternion(q)
	return
}

@(require_results)
euler_angles_xyz_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_xyz_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_yxz_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_yxz_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_xzx_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_xzx_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_xyx_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_xyx_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_yxy_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_yxy_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_yzy_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_yzy_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_zyz_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_zyz_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_zxz_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_zxz_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_xzy_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_xzy_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_yzx_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_yzx_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_zyx_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_zyx_from_matrix4(matrix4_from_quaternion(q))
}
@(require_results)
euler_angles_zxy_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (t1, t2, t3: f64) {
	return euler_angles_zxy_from_matrix4(matrix4_from_quaternion(q))
}


// Matrix3


@(require_results)
matrix3_from_euler_angle_x_f64 :: proc "contextless" (angle_x: f64) -> (m: Matrix3f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	m[0, 0] = 1
	m[1, 1] = +cos_x
	m[1, 2] = +sin_x
	m[2, 1] = -sin_x
	m[2, 2] = +cos_x
	return
}
@(require_results)
matrix3_from_euler_angle_y_f64 :: proc "contextless" (angle_y: f64) -> (m: Matrix3f64) {
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = +cos_y
	m[0, 2] = -sin_y
	m[1, 1] = 1
	m[2, 0] = +sin_y
	m[2, 2] = +cos_y
	return
}
@(require_results)
matrix3_from_euler_angle_z_f64 :: proc "contextless" (angle_z: f64) -> (m: Matrix3f64) {
	cos_z, sin_z := math.cos(angle_z), math.sin(angle_z)
	m[0, 0] = +cos_z
	m[0, 1] = +sin_z
	m[1, 1] = +cos_z
	m[1, 0] = -sin_z
	m[2, 2] = 1
	return
}


@(require_results)
matrix3_from_derived_euler_angle_x_f64 :: proc "contextless" (angle_x: f64, angular_velocity_x: f64) -> (m: Matrix3f64) {
	cos_x := math.cos(angle_x) * angular_velocity_x
	sin_x := math.sin(angle_x) * angular_velocity_x
	m[0, 0] = 1
	m[1, 1] = +cos_x
	m[1, 2] = +sin_x
	m[2, 1] = -sin_x
	m[2, 2] = +cos_x
	return
}
@(require_results)
matrix3_from_derived_euler_angle_y_f64 :: proc "contextless" (angle_y: f64, angular_velocity_y: f64) -> (m: Matrix3f64) {
	cos_y := math.cos(angle_y) * angular_velocity_y
	sin_y := math.sin(angle_y) * angular_velocity_y
	m[0, 0] = +cos_y
	m[0, 2] = -sin_y
	m[1, 1] = 1
	m[2, 0] = +sin_y
	m[2, 2] = +cos_y
	return
}
@(require_results)
matrix3_from_derived_euler_angle_z_f64 :: proc "contextless" (angle_z: f64, angular_velocity_z: f64) -> (m: Matrix3f64) {
	cos_z := math.cos(angle_z) * angular_velocity_z
	sin_z := math.sin(angle_z) * angular_velocity_z
	m[0, 0] = +cos_z
	m[0, 1] = +sin_z
	m[1, 1] = +cos_z
	m[1, 0] = -sin_z
	m[2, 2] = 1
	return
}


@(require_results)
matrix3_from_euler_angles_xy_f64 :: proc "contextless" (angle_x, angle_y: f64) -> (m: Matrix3f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = cos_y
	m[0, 1] = -sin_x * - sin_y
	m[0, 2] = -cos_x * - sin_y
	m[1, 1] = cos_x
	m[1, 2] = sin_x
	m[2, 0] = sin_y
	m[2, 1] = -sin_x * cos_y
	m[2, 2] = cos_x * cos_y
	return
}


@(require_results)
matrix3_from_euler_angles_yx_f64 :: proc "contextless" (angle_y, angle_x: f64) -> (m: Matrix3f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = cos_y
	m[0, 2] = -sin_y
	m[1, 0] = sin_y*sin_x
	m[1, 1] = cos_x
	m[1, 2] = cos_y*sin_x
	m[2, 0] = sin_y*cos_x
	m[2, 1] = -sin_x
	m[2, 2] = cos_y*cos_x
	return
}

@(require_results)
matrix3_from_euler_angles_xz_f64 :: proc "contextless" (angle_x, angle_z: f64) -> (m: Matrix3f64) {
	return mul(matrix3_from_euler_angle_x(angle_x), matrix3_from_euler_angle_z(angle_z))
}
@(require_results)
matrix3_from_euler_angles_zx_f64 :: proc "contextless" (angle_z, angle_x: f64) -> (m: Matrix3f64) {
	return mul(matrix3_from_euler_angle_z(angle_z), matrix3_from_euler_angle_x(angle_x))
}
@(require_results)
matrix3_from_euler_angles_yz_f64 :: proc "contextless" (angle_y, angle_z: f64) -> (m: Matrix3f64) {
	return mul(matrix3_from_euler_angle_y(angle_y), matrix3_from_euler_angle_z(angle_z))
}
@(require_results)
matrix3_from_euler_angles_zy_f64 :: proc "contextless" (angle_z, angle_y: f64) -> (m: Matrix3f64) {
	return mul(matrix3_from_euler_angle_z(angle_z), matrix3_from_euler_angle_y(angle_y))
}


@(require_results)
matrix3_from_euler_angles_xyz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(-t1)
	c2 := math.cos(-t2)
	c3 := math.cos(-t3)
	s1 := math.sin(-t1)
	s2 := math.sin(-t2)
	s3 := math.sin(-t3)

	m[0, 0] = c2 * c3
	m[1, 0] =-c1 * s3 + s1 * s2 * c3
	m[2, 0] = s1 * s3 + c1 * s2 * c3
	m[0, 1] = c2 * s3
	m[1, 1] = c1 * c3 + s1 * s2 * s3
	m[2, 1] =-s1 * c3 + c1 * s2 * s3
	m[0, 2] =-s2
	m[1, 2] = s1 * c2
	m[2, 2] = c1 * c2
	return
}

@(require_results)
matrix3_from_euler_angles_yxz_f64 :: proc "contextless" (yaw, pitch, roll: f64) -> (m: Matrix3f64) {
	ch := math.cos(yaw)
	sh := math.sin(yaw)
	cp := math.cos(pitch)
	sp := math.sin(pitch)
	cb := math.cos(roll)
	sb := math.sin(roll)

	m[0, 0] = ch * cb + sh * sp * sb
	m[1, 0] = sb * cp
	m[2, 0] = -sh * cb + ch * sp * sb
	m[0, 1] = -ch * sb + sh * sp * cb
	m[1, 1] = cb * cp
	m[2, 1] = sb * sh + ch * sp * cb
	m[0, 2] = sh * cp
	m[1, 2] = -sp
	m[2, 2] = ch * cp
	return
}

@(require_results)
matrix3_from_euler_angles_xzx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2
	m[1, 0] = c1 * s2
	m[2, 0] = s1 * s2
	m[0, 1] =-c3 * s2
	m[1, 1] = c1 * c2 * c3 - s1 * s3
	m[2, 1] = c1 * s3 + c2 * c3 * s1
	m[0, 2] = s2 * s3
	m[1, 2] =-c3 * s1 - c1 * c2 * s3
	m[2, 2] = c1 * c3 - c2 * s1 * s3
	return
}

@(require_results)
matrix3_from_euler_angles_xyx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2
	m[1, 0] = s1 * s2
	m[2, 0] =-c1 * s2
	m[0, 1] = s2 * s3
	m[1, 1] = c1 * c3 - c2 * s1 * s3
	m[2, 1] = c3 * s1 + c1 * c2 * s3
	m[0, 2] = c3 * s2
	m[1, 2] =-c1 * s3 - c2 * c3 * s1
	m[2, 2] = c1 * c2 * c3 - s1 * s3
	return
}

@(require_results)
matrix3_from_euler_angles_yxy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - c2 * s1 * s3
	m[1, 0] = s2* s3
	m[2, 0] =-c3 * s1 - c1 * c2 * s3
	m[0, 1] = s1 * s2
	m[1, 1] = c2
	m[2, 1] = c1 * s2
	m[0, 2] = c1 * s3 + c2 * c3 * s1
	m[1, 2] =-c3 * s2
	m[2, 2] = c1 * c2 * c3 - s1 * s3
	return
}

@(require_results)
matrix3_from_euler_angles_yzy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2 * c3 - s1 * s3
	m[1, 0] = c3 * s2
	m[2, 0] =-c1 * s3 - c2 * c3 * s1
	m[0, 1] =-c1 * s2
	m[1, 1] = c2
	m[2, 1] = s1 * s2
	m[0, 2] = c3 * s1 + c1 * c2 * s3
	m[1, 2] = s2 * s3
	m[2, 2] = c1 * c3 - c2 * s1 * s3
	return
}

@(require_results)
matrix3_from_euler_angles_zyz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2 * c3 - s1 * s3
	m[1, 0] = c1 * s3 + c2 * c3 * s1
	m[2, 0] =-c3 * s2
	m[0, 1] =-c3 * s1 - c1 * c2 * s3
	m[1, 1] = c1 * c3 - c2 * s1 * s3
	m[2, 1] = s2 * s3
	m[0, 2] = c1 * s2
	m[1, 2] = s1 * s2
	m[2, 2] = c2
	return
}

@(require_results)
matrix3_from_euler_angles_zxz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - c2 * s1 * s3
	m[1, 0] = c3 * s1 + c1 * c2 * s3
	m[2, 0] = s2 *s3
	m[0, 1] =-c1 * s3 - c2 * c3 * s1
	m[1, 1] = c1 * c2 * c3 - s1 * s3
	m[2, 1] = c3 * s2
	m[0, 2] = s1 * s2
	m[1, 2] =-c1 * s2
	m[2, 2] = c2
	return
}


@(require_results)
matrix3_from_euler_angles_xzy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2 * c3
	m[1, 0] = s1 * s3 + c1 * c3 * s2
	m[2, 0] = c3 * s1 * s2 - c1 * s3
	m[0, 1] =-s2
	m[1, 1] = c1 * c2
	m[2, 1] = c2 * s1
	m[0, 2] = c2 * s3
	m[1, 2] = c1 * s2 * s3 - c3 * s1
	m[2, 2] = c1 * c3 + s1 * s2 *s3
	return
}

@(require_results)
matrix3_from_euler_angles_yzx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2
	m[1, 0] = s2
	m[2, 0] =-c2 * s1
	m[0, 1] = s1 * s3 - c1 * c3 * s2
	m[1, 1] = c2 * c3
	m[2, 1] = c1 * s3 + c3 * s1 * s2
	m[0, 2] = c3 * s1 + c1 * s2 * s3
	m[1, 2] =-c2 * s3
	m[2, 2] = c1 * c3 - s1 * s2 * s3
	return
}

@(require_results)
matrix3_from_euler_angles_zyx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2
	m[1, 0] = c2 * s1
	m[2, 0] =-s2
	m[0, 1] = c1 * s2 * s3 - c3 * s1
	m[1, 1] = c1 * c3 + s1 * s2 * s3
	m[2, 1] = c2 * s3
	m[0, 2] = s1 * s3 + c1 * c3 * s2
	m[1, 2] = c3 * s1 * s2 - c1 * s3
	m[2, 2] = c2 * c3
	return
}

@(require_results)
matrix3_from_euler_angles_zxy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix3f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - s1 * s2 * s3
	m[1, 0] = c3 * s1 + c1 * s2 * s3
	m[2, 0] =-c2 * s3
	m[0, 1] =-c2 * s1
	m[1, 1] = c1 * c2
	m[2, 1] = s2
	m[0, 2] = c1 * s3 + c3 * s1 * s2
	m[1, 2] = s1 * s3 - c1 * c3 * s2
	m[2, 2] = c2 * c3
	return
}


@(require_results)
matrix3_from_yaw_pitch_roll_f64 :: proc "contextless" (yaw, pitch, roll: f64) -> (m: Matrix3f64) {
	ch := math.cos(yaw)
	sh := math.sin(yaw)
	cp := math.cos(pitch)
	sp := math.sin(pitch)
	cb := math.cos(roll)
	sb := math.sin(roll)

	m[0, 0] = ch * cb + sh * sp * sb
	m[1, 0] = sb * cp
	m[2, 0] = -sh * cb + ch * sp * sb
	m[0, 1] = -ch * sb + sh * sp * cb
	m[1, 1] = cb * cp
	m[2, 1] = sb * sh + ch * sp * cb
	m[0, 2] = sh * cp
	m[1, 2] = -sp
	m[2, 2] = ch * cp
	return m
}

@(require_results)
euler_angles_xyz_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 2], m[2, 2])
	C2 := math.sqrt(m[0, 0]*m[0, 0] + m[0, 1]*m[0, 1])
	T2 := math.atan2(-m[0, 2], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[2, 0] - C1*m[1, 0], C1*m[1, 1] - S1*m[2, 1])
	t1 = -T1
	t2 = -T2
	t3 = -T3
	return
}

@(require_results)
euler_angles_yxz_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 2], m[2, 2])
	C2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 1]*m[1, 1])
	T2 := math.atan2(-m[1, 2], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[2, 1] - C1*m[0, 1], C1*m[0, 0] - S1*m[2, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xzx_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 0], m[1, 0])
	S2 := math.sqrt(m[0, 1]*m[0, 1] + m[0, 2]*m[0, 2])
	T2 := math.atan2(S2, m[0, 0])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[2, 1] - S1*m[1, 1], C1*m[2, 2] - S1*m[1, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xyx_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 0], -m[2, 0])
	S2 := math.sqrt(m[0, 1]*m[0, 1] + m[0, 2]*m[0, 2])
	T2 := math.atan2(S2, m[0, 0])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-C1*m[1, 2] - S1*m[2, 2], C1*m[1, 1] + S1*m[2, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yxy_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 1], m[2, 1])
	S2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 2]*m[1, 2])
	T2 := math.atan2(S2, m[1, 1])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[0, 2] - S1*m[2, 2], C1*m[0, 0] - S1*m[2, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yzy_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 1], -m[0, 1])
	S2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 2]*m[1, 2])
	T2 := math.atan2(S2, m[1, 1])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-S1*m[0, 0] - C1*m[2, 0], S1*m[0, 2] + C1*m[2, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}
@(require_results)
euler_angles_zyz_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 2], m[0, 2])
	S2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 1]*m[2, 1])
	T2 := math.atan2(S2, m[2, 2])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[1, 0] - S1*m[0, 0], C1*m[1, 1] - S1*m[0, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zxz_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 2], -m[1, 2])
	S2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 1]*m[2, 1])
	T2 := math.atan2(S2, m[2, 2])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-C1*m[0, 1] - S1*m[1, 1], C1*m[0, 0] + S1*m[1, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xzy_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 1], m[1, 1])
	C2 := math.sqrt(m[0, 0]*m[0, 0] + m[0, 2]*m[0, 2])
	T2 := math.atan2(-m[0, 1], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[1, 0] - C1*m[2, 0], C1*m[2, 2] - S1*m[1, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yzx_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(-m[2, 0], m[0, 0])
	C2 := math.sqrt(m[1, 1]*m[1, 1] + m[1, 2]*m[1, 2])
	T2 := math.atan2(m[1, 0], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[0, 1] + C1*m[2, 1], S1*m[0, 2] + C1*m[2, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zyx_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 0], m[0, 0])
	C2 := math.sqrt(m[2, 1]*m[2, 1] + m[2, 2]*m[2, 2])
	T2 := math.atan2(-m[2, 0], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[0, 2] - C1*m[1, 2], C1*m[1, 1] - S1*m[0, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zxy_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(-m[0, 1], m[1, 1])
	C2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 2]*m[2, 2])
	T2 := math.atan2(m[2, 1], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[0, 2] + S1*m[1, 2], C1*m[0, 0] + S1*m[1, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}


// Matrix4


@(require_results)
matrix4_from_euler_angle_x_f64 :: proc "contextless" (angle_x: f64) -> (m: Matrix4f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	m[0, 0] = 1
	m[1, 1] = +cos_x
	m[1, 2] = +sin_x
	m[2, 1] = -sin_x
	m[2, 2] = +cos_x
	m[3, 3] = 1
	return
}
@(require_results)
matrix4_from_euler_angle_y_f64 :: proc "contextless" (angle_y: f64) -> (m: Matrix4f64) {
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = +cos_y
	m[0, 2] = -sin_y
	m[1, 1] = 1
	m[2, 0] = +sin_y
	m[2, 2] = +cos_y
	m[3, 3] = 1
	return
}
@(require_results)
matrix4_from_euler_angle_z_f64 :: proc "contextless" (angle_z: f64) -> (m: Matrix4f64) {
	cos_z, sin_z := math.cos(angle_z), math.sin(angle_z)
	m[0, 0] = +cos_z
	m[0, 1] = +sin_z
	m[1, 1] = +cos_z
	m[1, 0] = -sin_z
	m[2, 2] = 1
	m[3, 3] = 1
	return
}


@(require_results)
matrix4_from_derived_euler_angle_x_f64 :: proc "contextless" (angle_x: f64, angular_velocity_x: f64) -> (m: Matrix4f64) {
	cos_x := math.cos(angle_x) * angular_velocity_x
	sin_x := math.sin(angle_x) * angular_velocity_x
	m[0, 0] = 1
	m[1, 1] = +cos_x
	m[1, 2] = +sin_x
	m[2, 1] = -sin_x
	m[2, 2] = +cos_x
	m[3, 3] = 1
	return
}
@(require_results)
matrix4_from_derived_euler_angle_y_f64 :: proc "contextless" (angle_y: f64, angular_velocity_y: f64) -> (m: Matrix4f64) {
	cos_y := math.cos(angle_y) * angular_velocity_y
	sin_y := math.sin(angle_y) * angular_velocity_y
	m[0, 0] = +cos_y
	m[0, 2] = -sin_y
	m[1, 1] = 1
	m[2, 0] = +sin_y
	m[2, 2] = +cos_y
	m[3, 3] = 1
	return
}
@(require_results)
matrix4_from_derived_euler_angle_z_f64 :: proc "contextless" (angle_z: f64, angular_velocity_z: f64) -> (m: Matrix4f64) {
	cos_z := math.cos(angle_z) * angular_velocity_z
	sin_z := math.sin(angle_z) * angular_velocity_z
	m[0, 0] = +cos_z
	m[0, 1] = +sin_z
	m[1, 1] = +cos_z
	m[1, 0] = -sin_z
	m[2, 2] = 1
	m[3, 3] = 1
	return
}


@(require_results)
matrix4_from_euler_angles_xy_f64 :: proc "contextless" (angle_x, angle_y: f64) -> (m: Matrix4f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = cos_y
	m[0, 1] = -sin_x * - sin_y
	m[0, 2] = -cos_x * - sin_y
	m[1, 1] = cos_x
	m[1, 2] = sin_x
	m[2, 0] = sin_y
	m[2, 1] = -sin_x * cos_y
	m[2, 2] = cos_x * cos_y
	m[3, 3] = 1
	return
}


@(require_results)
matrix4_from_euler_angles_yx_f64 :: proc "contextless" (angle_y, angle_x: f64) -> (m: Matrix4f64) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x)
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y)
	m[0, 0] = cos_y
	m[0, 2] = -sin_y
	m[1, 0] = sin_y*sin_x
	m[1, 1] = cos_x
	m[1, 2] = cos_y*sin_x
	m[2, 0] = sin_y*cos_x
	m[2, 1] = -sin_x
	m[2, 2] = cos_y*cos_x
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_xz_f64 :: proc "contextless" (angle_x, angle_z: f64) -> (m: Matrix4f64) {
	return mul(matrix4_from_euler_angle_x(angle_x), matrix4_from_euler_angle_z(angle_z))
}
@(require_results)
matrix4_from_euler_angles_zx_f64 :: proc "contextless" (angle_z, angle_x: f64) -> (m: Matrix4f64) {
	return mul(matrix4_from_euler_angle_z(angle_z), matrix4_from_euler_angle_x(angle_x))
}
@(require_results)
matrix4_from_euler_angles_yz_f64 :: proc "contextless" (angle_y, angle_z: f64) -> (m: Matrix4f64) {
	return mul(matrix4_from_euler_angle_y(angle_y), matrix4_from_euler_angle_z(angle_z))
}
@(require_results)
matrix4_from_euler_angles_zy_f64 :: proc "contextless" (angle_z, angle_y: f64) -> (m: Matrix4f64) {
	return mul(matrix4_from_euler_angle_z(angle_z), matrix4_from_euler_angle_y(angle_y))
}


@(require_results)
matrix4_from_euler_angles_xyz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(-t1)
	c2 := math.cos(-t2)
	c3 := math.cos(-t3)
	s1 := math.sin(-t1)
	s2 := math.sin(-t2)
	s3 := math.sin(-t3)

	m[0, 0] = c2 * c3
	m[1, 0] =-c1 * s3 + s1 * s2 * c3
	m[2, 0] = s1 * s3 + c1 * s2 * c3
	m[3, 0] = 0
	m[0, 1] = c2 * s3
	m[1, 1] = c1 * c3 + s1 * s2 * s3
	m[2, 1] =-s1 * c3 + c1 * s2 * s3
	m[3, 1] = 0
	m[0, 2] =-s2
	m[1, 2] = s1 * c2
	m[2, 2] = c1 * c2
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_yxz_f64 :: proc "contextless" (yaw, pitch, roll: f64) -> (m: Matrix4f64) {
	ch := math.cos(yaw)
	sh := math.sin(yaw)
	cp := math.cos(pitch)
	sp := math.sin(pitch)
	cb := math.cos(roll)
	sb := math.sin(roll)

	m[0, 0] = ch * cb + sh * sp * sb
	m[1, 0] = sb * cp
	m[2, 0] = -sh * cb + ch * sp * sb
	m[3, 0] = 0
	m[0, 1] = -ch * sb + sh * sp * cb
	m[1, 1] = cb * cp
	m[2, 1] = sb * sh + ch * sp * cb
	m[3, 1] = 0
	m[0, 2] = sh * cp
	m[1, 2] = -sp
	m[2, 2] = ch * cp
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_xzx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2
	m[1, 0] = c1 * s2
	m[2, 0] = s1 * s2
	m[3, 0] = 0
	m[0, 1] =-c3 * s2
	m[1, 1] = c1 * c2 * c3 - s1 * s3
	m[2, 1] = c1 * s3 + c2 * c3 * s1
	m[3, 1] = 0
	m[0, 2] = s2 * s3
	m[1, 2] =-c3 * s1 - c1 * c2 * s3
	m[2, 2] = c1 * c3 - c2 * s1 * s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_xyx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2
	m[1, 0] = s1 * s2
	m[2, 0] =-c1 * s2
	m[3, 0] = 0
	m[0, 1] = s2 * s3
	m[1, 1] = c1 * c3 - c2 * s1 * s3
	m[2, 1] = c3 * s1 + c1 * c2 * s3
	m[3, 1] = 0
	m[0, 2] = c3 * s2
	m[1, 2] =-c1 * s3 - c2 * c3 * s1
	m[2, 2] = c1 * c2 * c3 - s1 * s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_yxy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - c2 * s1 * s3
	m[1, 0] = s2* s3
	m[2, 0] =-c3 * s1 - c1 * c2 * s3
	m[3, 0] = 0
	m[0, 1] = s1 * s2
	m[1, 1] = c2
	m[2, 1] = c1 * s2
	m[3, 1] = 0
	m[0, 2] = c1 * s3 + c2 * c3 * s1
	m[1, 2] =-c3 * s2
	m[2, 2] = c1 * c2 * c3 - s1 * s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_yzy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2 * c3 - s1 * s3
	m[1, 0] = c3 * s2
	m[2, 0] =-c1 * s3 - c2 * c3 * s1
	m[3, 0] = 0
	m[0, 1] =-c1 * s2
	m[1, 1] = c2
	m[2, 1] = s1 * s2
	m[3, 1] = 0
	m[0, 2] = c3 * s1 + c1 * c2 * s3
	m[1, 2] = s2 * s3
	m[2, 2] = c1 * c3 - c2 * s1 * s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_zyz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2 * c3 - s1 * s3
	m[1, 0] = c1 * s3 + c2 * c3 * s1
	m[2, 0] =-c3 * s2
	m[3, 0] = 0
	m[0, 1] =-c3 * s1 - c1 * c2 * s3
	m[1, 1] = c1 * c3 - c2 * s1 * s3
	m[2, 1] = s2 * s3
	m[3, 1] = 0
	m[0, 2] = c1 * s2
	m[1, 2] = s1 * s2
	m[2, 2] = c2
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_zxz_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - c2 * s1 * s3
	m[1, 0] = c3 * s1 + c1 * c2 * s3
	m[2, 0] = s2 *s3
	m[3, 0] = 0
	m[0, 1] =-c1 * s3 - c2 * c3 * s1
	m[1, 1] = c1 * c2 * c3 - s1 * s3
	m[2, 1] = c3 * s2
	m[3, 1] = 0
	m[0, 2] = s1 * s2
	m[1, 2] =-c1 * s2
	m[2, 2] = c2
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}


@(require_results)
matrix4_from_euler_angles_xzy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c2 * c3
	m[1, 0] = s1 * s3 + c1 * c3 * s2
	m[2, 0] = c3 * s1 * s2 - c1 * s3
	m[3, 0] = 0
	m[0, 1] =-s2
	m[1, 1] = c1 * c2
	m[2, 1] = c2 * s1
	m[3, 1] = 0
	m[0, 2] = c2 * s3
	m[1, 2] = c1 * s2 * s3 - c3 * s1
	m[2, 2] = c1 * c3 + s1 * s2 *s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_yzx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2
	m[1, 0] = s2
	m[2, 0] =-c2 * s1
	m[3, 0] = 0
	m[0, 1] = s1 * s3 - c1 * c3 * s2
	m[1, 1] = c2 * c3
	m[2, 1] = c1 * s3 + c3 * s1 * s2
	m[3, 1] = 0
	m[0, 2] = c3 * s1 + c1 * s2 * s3
	m[1, 2] =-c2 * s3
	m[2, 2] = c1 * c3 - s1 * s2 * s3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_zyx_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c2
	m[1, 0] = c2 * s1
	m[2, 0] =-s2
	m[3, 0] = 0
	m[0, 1] = c1 * s2 * s3 - c3 * s1
	m[1, 1] = c1 * c3 + s1 * s2 * s3
	m[2, 1] = c2 * s3
	m[3, 1] = 0
	m[0, 2] = s1 * s3 + c1 * c3 * s2
	m[1, 2] = c3 * s1 * s2 - c1 * s3
	m[2, 2] = c2 * c3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}

@(require_results)
matrix4_from_euler_angles_zxy_f64 :: proc "contextless" (t1, t2, t3: f64) -> (m: Matrix4f64) {
	c1 := math.cos(t1)
	s1 := math.sin(t1)
	c2 := math.cos(t2)
	s2 := math.sin(t2)
	c3 := math.cos(t3)
	s3 := math.sin(t3)

	m[0, 0] = c1 * c3 - s1 * s2 * s3
	m[1, 0] = c3 * s1 + c1 * s2 * s3
	m[2, 0] =-c2 * s3
	m[3, 0] = 0
	m[0, 1] =-c2 * s1
	m[1, 1] = c1 * c2
	m[2, 1] = s2
	m[3, 1] = 0
	m[0, 2] = c1 * s3 + c3 * s1 * s2
	m[1, 2] = s1 * s3 - c1 * c3 * s2
	m[2, 2] = c2 * c3
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return
}


@(require_results)
matrix4_from_yaw_pitch_roll_f64 :: proc "contextless" (yaw, pitch, roll: f64) -> (m: Matrix4f64) {
	ch := math.cos(yaw)
	sh := math.sin(yaw)
	cp := math.cos(pitch)
	sp := math.sin(pitch)
	cb := math.cos(roll)
	sb := math.sin(roll)

	m[0, 0] = ch * cb + sh * sp * sb
	m[1, 0] = sb * cp
	m[2, 0] = -sh * cb + ch * sp * sb
	m[3, 0] = 0
	m[0, 1] = -ch * sb + sh * sp * cb
	m[1, 1] = cb * cp
	m[2, 1] = sb * sh + ch * sp * cb
	m[3, 1] = 0
	m[0, 2] = sh * cp
	m[1, 2] = -sp
	m[2, 2] = ch * cp
	m[3, 2] = 0
	m[0, 3] = 0
	m[1, 3] = 0
	m[2, 3] = 0
	m[3, 3] = 1
	return m
}

@(require_results)
euler_angles_xyz_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 2], m[2, 2])
	C2 := math.sqrt(m[0, 0]*m[0, 0] + m[0, 1]*m[0, 1])
	T2 := math.atan2(-m[0, 2], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[2, 0] - C1*m[1, 0], C1*m[1, 1] - S1*m[2, 1])
	t1 = -T1
	t2 = -T2
	t3 = -T3
	return
}

@(require_results)
euler_angles_yxz_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 2], m[2, 2])
	C2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 1]*m[1, 1])
	T2 := math.atan2(-m[1, 2], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[2, 1] - C1*m[0, 1], C1*m[0, 0] - S1*m[2, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xzx_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 0], m[1, 0])
	S2 := math.sqrt(m[0, 1]*m[0, 1] + m[0, 2]*m[0, 2])
	T2 := math.atan2(S2, m[0, 0])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[2, 1] - S1*m[1, 1], C1*m[2, 2] - S1*m[1, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xyx_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 0], -m[2, 0])
	S2 := math.sqrt(m[0, 1]*m[0, 1] + m[0, 2]*m[0, 2])
	T2 := math.atan2(S2, m[0, 0])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-C1*m[1, 2] - S1*m[2, 2], C1*m[1, 1] + S1*m[2, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yxy_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 1], m[2, 1])
	S2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 2]*m[1, 2])
	T2 := math.atan2(S2, m[1, 1])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[0, 2] - S1*m[2, 2], C1*m[0, 0] - S1*m[2, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yzy_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 1], -m[0, 1])
	S2 := math.sqrt(m[1, 0]*m[1, 0] + m[1, 2]*m[1, 2])
	T2 := math.atan2(S2, m[1, 1])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-S1*m[0, 0] - C1*m[2, 0], S1*m[0, 2] + C1*m[2, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}
@(require_results)
euler_angles_zyz_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 2], m[0, 2])
	S2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 1]*m[2, 1])
	T2 := math.atan2(S2, m[2, 2])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[1, 0] - S1*m[0, 0], C1*m[1, 1] - S1*m[0, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zxz_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[0, 2], -m[1, 2])
	S2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 1]*m[2, 1])
	T2 := math.atan2(S2, m[2, 2])
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(-C1*m[0, 1] - S1*m[1, 1], C1*m[0, 0] + S1*m[1, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_xzy_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[2, 1], m[1, 1])
	C2 := math.sqrt(m[0, 0]*m[0, 0] + m[0, 2]*m[0, 2])
	T2 := math.atan2(-m[0, 1], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[1, 0] - C1*m[2, 0], C1*m[2, 2] - S1*m[1, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_yzx_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(-m[2, 0], m[0, 0])
	C2 := math.sqrt(m[1, 1]*m[1, 1] + m[1, 2]*m[1, 2])
	T2 := math.atan2(m[1, 0], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[0, 1] + C1*m[2, 1], S1*m[0, 2] + C1*m[2, 2])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zyx_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(m[1, 0], m[0, 0])
	C2 := math.sqrt(m[2, 1]*m[2, 1] + m[2, 2]*m[2, 2])
	T2 := math.atan2(-m[2, 0], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(S1*m[0, 2] - C1*m[1, 2], C1*m[1, 1] - S1*m[0, 1])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}

@(require_results)
euler_angles_zxy_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (t1, t2, t3: f64) {
	T1 := math.atan2(-m[0, 1], m[1, 1])
	C2 := math.sqrt(m[2, 0]*m[2, 0] + m[2, 2]*m[2, 2])
	T2 := math.atan2(m[2, 1], C2)
	S1 := math.sin(T1)
	C1 := math.cos(T1)
	T3 := math.atan2(C1*m[0, 2] + S1*m[1, 2], C1*m[0, 0] + S1*m[1, 0])
	t1 = T1
	t2 = T2
	t3 = T3
	return
}
