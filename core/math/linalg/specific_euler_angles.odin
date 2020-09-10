package linalg

import "core:math"


euler_angle_x :: proc(angle_x: Float) -> (m: Matrix4) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x);
	m[0][0] = 1;
	m[1][1] = +cos_x;
	m[2][1] = +sin_x;
	m[1][2] = -sin_x;
	m[2][2] = +cos_x;
	m[3][3] = 1;
	return;
}
euler_angle_y :: proc(angle_y: Float) -> (m: Matrix4) {
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y);
	m[0][0] = +cos_y;
	m[2][0] = -sin_y;
	m[1][1] = 1;
	m[0][2] = +sin_y;
	m[2][2] = +cos_y;
	m[3][3] = 1;
	return;
}
euler_angle_z :: proc(angle_z: Float) -> (m: Matrix4) {
	cos_z, sin_z := math.cos(angle_z), math.sin(angle_z);
	m[0][0] = +cos_z;
	m[1][0] = +sin_z;
	m[1][1] = +cos_z;
	m[0][1] = -sin_z;
	m[2][2] = 1;
	m[3][3] = 1;
	return;
}


derived_euler_angle_x :: proc(angle_x: Float, angular_velocity_x: Float) -> (m: Matrix4) {
	cos_x := math.cos(angle_x) * angular_velocity_x;
	sin_x := math.sin(angle_x) * angular_velocity_x;
	m[0][0] = 1;
	m[1][1] = +cos_x;
	m[2][1] = +sin_x;
	m[1][2] = -sin_x;
	m[2][2] = +cos_x;
	m[3][3] = 1;
	return;
}
derived_euler_angle_y :: proc(angle_y: Float, angular_velocity_y: Float) -> (m: Matrix4) {
	cos_y := math.cos(angle_y) * angular_velocity_y;
	sin_y := math.sin(angle_y) * angular_velocity_y;
	m[0][0] = +cos_y;
	m[2][0] = -sin_y;
	m[1][1] = 1;
	m[0][2] = +sin_y;
	m[2][2] = +cos_y;
	m[3][3] = 1;
	return;
}
derived_euler_angle_z :: proc(angle_z: Float, angular_velocity_z: Float) -> (m: Matrix4) {
	cos_z := math.cos(angle_z) * angular_velocity_z;
	sin_z := math.sin(angle_z) * angular_velocity_z;
	m[0][0] = +cos_z;
	m[1][0] = +sin_z;
	m[1][1] = +cos_z;
	m[0][1] = -sin_z;
	m[2][2] = 1;
	m[3][3] = 1;
	return;
}


euler_angle_xy :: proc(angle_x, angle_y: Float) -> (m: Matrix4) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x);
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y);
	m[0][0] = cos_y;
	m[1][0] = -sin_x * - sin_y;
	m[2][0] = -cos_x * - sin_y;
	m[1][1] = cos_x;
	m[2][1] = sin_x;
	m[0][2] = sin_y;
	m[1][2] = -sin_x * cos_y;
	m[2][2] = cos_x * cos_y;
	m[3][3] = 1;
	return;
}


euler_angle_yx :: proc(angle_y, angle_x: Float) -> (m: Matrix4) {
	cos_x, sin_x := math.cos(angle_x), math.sin(angle_x);
	cos_y, sin_y := math.cos(angle_y), math.sin(angle_y);
	m[0][0] = cos_y;
	m[2][0] = -sin_y;
	m[0][1] = sin_y*sin_x;
	m[1][1] = cos_x;
	m[2][1] = cos_y*sin_x;
	m[0][2] = sin_y*cos_x;
	m[1][2] = -sin_x;
	m[2][2] = cos_y*cos_x;
	m[3][3] = 1;
	return;
}

euler_angle_xz :: proc(angle_x, angle_z: Float) -> (m: Matrix4) {
	return mul(euler_angle_x(angle_x), euler_angle_z(angle_z));
}
euler_angle_zx :: proc(angle_z, angle_x: Float) -> (m: Matrix4) {
	return mul(euler_angle_z(angle_z), euler_angle_x(angle_x));
}
euler_angle_yz :: proc(angle_y, angle_z: Float) -> (m: Matrix4) {
	return mul(euler_angle_y(angle_y), euler_angle_z(angle_z));
}
euler_angle_zy :: proc(angle_z, angle_y: Float) -> (m: Matrix4) {
	return mul(euler_angle_z(angle_z), euler_angle_y(angle_y));
}


euler_angle_xyz :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(-t1);
	c2 := math.cos(-t2);
	c3 := math.cos(-t3);
	s1 := math.sin(-t1);
	s2 := math.sin(-t2);
	s3 := math.sin(-t3);

	m[0][0] = c2 * c3;
	m[0][1] =-c1 * s3 + s1 * s2 * c3;
	m[0][2] = s1 * s3 + c1 * s2 * c3;
	m[0][3] = 0;
	m[1][0] = c2 * s3;
	m[1][1] = c1 * c3 + s1 * s2 * s3;
	m[1][2] =-s1 * c3 + c1 * s2 * s3;
	m[1][3] = 0;
	m[2][0] =-s2;
	m[2][1] = s1 * c2;
	m[2][2] = c1 * c2;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_yxz :: proc(yaw, pitch, roll: Float) -> (m: Matrix4) {
	ch := math.cos(yaw);
	sh := math.sin(yaw);
	cp := math.cos(pitch);
	sp := math.sin(pitch);
	cb := math.cos(roll);
	sb := math.sin(roll);

	m[0][0] = ch * cb + sh * sp * sb;
	m[0][1] = sb * cp;
	m[0][2] = -sh * cb + ch * sp * sb;
	m[0][3] = 0;
	m[1][0] = -ch * sb + sh * sp * cb;
	m[1][1] = cb * cp;
	m[1][2] = sb * sh + ch * sp * cb;
	m[1][3] = 0;
	m[2][0] = sh * cp;
	m[2][1] = -sp;
	m[2][2] = ch * cp;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_xzx :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c2;
	m[0][1] = c1 * s2;
	m[0][2] = s1 * s2;
	m[0][3] = 0;
	m[1][0] =-c3 * s2;
	m[1][1] = c1 * c2 * c3 - s1 * s3;
	m[1][2] = c1 * s3 + c2 * c3 * s1;
	m[1][3] = 0;
	m[2][0] = s2 * s3;
	m[2][1] =-c3 * s1 - c1 * c2 * s3;
	m[2][2] = c1 * c3 - c2 * s1 * s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_xyx :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c2;
	m[0][1] = s1 * s2;
	m[0][2] =-c1 * s2;
	m[0][3] = 0;
	m[1][0] = s2 * s3;
	m[1][1] = c1 * c3 - c2 * s1 * s3;
	m[1][2] = c3 * s1 + c1 * c2 * s3;
	m[1][3] = 0;
	m[2][0] = c3 * s2;
	m[2][1] =-c1 * s3 - c2 * c3 * s1;
	m[2][2] = c1 * c2 * c3 - s1 * s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_yxy :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c3 - c2 * s1 * s3;
	m[0][1] = s2* s3;
	m[0][2] =-c3 * s1 - c1 * c2 * s3;
	m[0][3] = 0;
	m[1][0] = s1 * s2;
	m[1][1] = c2;
	m[1][2] = c1 * s2;
	m[1][3] = 0;
	m[2][0] = c1 * s3 + c2 * c3 * s1;
	m[2][1] =-c3 * s2;
	m[2][2] = c1 * c2 * c3 - s1 * s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_yzy :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c2 * c3 - s1 * s3;
	m[0][1] = c3 * s2;
	m[0][2] =-c1 * s3 - c2 * c3 * s1;
	m[0][3] = 0;
	m[1][0] =-c1 * s2;
	m[1][1] = c2;
	m[1][2] = s1 * s2;
	m[1][3] = 0;
	m[2][0] = c3 * s1 + c1 * c2 * s3;
	m[2][1] = s2 * s3;
	m[2][2] = c1 * c3 - c2 * s1 * s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_zyz :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c2 * c3 - s1 * s3;
	m[0][1] = c1 * s3 + c2 * c3 * s1;
	m[0][2] =-c3 * s2;
	m[0][3] = 0;
	m[1][0] =-c3 * s1 - c1 * c2 * s3;
	m[1][1] = c1 * c3 - c2 * s1 * s3;
	m[1][2] = s2 * s3;
	m[1][3] = 0;
	m[2][0] = c1 * s2;
	m[2][1] = s1 * s2;
	m[2][2] = c2;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_zxz :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c3 - c2 * s1 * s3;
	m[0][1] = c3 * s1 + c1 * c2 * s3;
	m[0][2] = s2 *s3;
	m[0][3] = 0;
	m[1][0] =-c1 * s3 - c2 * c3 * s1;
	m[1][1] = c1 * c2 * c3 - s1 * s3;
	m[1][2] = c3 * s2;
	m[1][3] = 0;
	m[2][0] = s1 * s2;
	m[2][1] =-c1 * s2;
	m[2][2] = c2;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}


euler_angle_xzy :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c2 * c3;
	m[0][1] = s1 * s3 + c1 * c3 * s2;
	m[0][2] = c3 * s1 * s2 - c1 * s3;
	m[0][3] = 0;
	m[1][0] =-s2;
	m[1][1] = c1 * c2;
	m[1][2] = c2 * s1;
	m[1][3] = 0;
	m[2][0] = c2 * s3;
	m[2][1] = c1 * s2 * s3 - c3 * s1;
	m[2][2] = c1 * c3 + s1 * s2 *s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_yzx :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c2;
	m[0][1] = s2;
	m[0][2] =-c2 * s1;
	m[0][3] = 0;
	m[1][0] = s1 * s3 - c1 * c3 * s2;
	m[1][1] = c2 * c3;
	m[1][2] = c1 * s3 + c3 * s1 * s2;
	m[1][3] = 0;
	m[2][0] = c3 * s1 + c1 * s2 * s3;
	m[2][1] =-c2 * s3;
	m[2][2] = c1 * c3 - s1 * s2 * s3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_zyx :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c2;
	m[0][1] = c2 * s1;
	m[0][2] =-s2;
	m[0][3] = 0;
	m[1][0] = c1 * s2 * s3 - c3 * s1;
	m[1][1] = c1 * c3 + s1 * s2 * s3;
	m[1][2] = c2 * s3;
	m[1][3] = 0;
	m[2][0] = s1 * s3 + c1 * c3 * s2;
	m[2][1] = c3 * s1 * s2 - c1 * s3;
	m[2][2] = c2 * c3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}

euler_angle_zxy :: proc(t1, t2, t3: Float) -> (m: Matrix4) {
	c1 := math.cos(t1);
	s1 := math.sin(t1);
	c2 := math.cos(t2);
	s2 := math.sin(t2);
	c3 := math.cos(t3);
	s3 := math.sin(t3);

	m[0][0] = c1 * c3 - s1 * s2 * s3;
	m[0][1] = c3 * s1 + c1 * s2 * s3;
	m[0][2] =-c2 * s3;
	m[0][3] = 0;
	m[1][0] =-c2 * s1;
	m[1][1] = c1 * c2;
	m[1][2] = s2;
	m[1][3] = 0;
	m[2][0] = c1 * s3 + c3 * s1 * s2;
	m[2][1] = s1 * s3 - c1 * c3 * s2;
	m[2][2] = c2 * c3;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return;
}


yaw_pitch_roll :: proc(yaw, pitch, roll: Float) -> (m: Matrix4) {
	ch := math.cos(yaw);
	sh := math.sin(yaw);
	cp := math.cos(pitch);
	sp := math.sin(pitch);
	cb := math.cos(roll);
	sb := math.sin(roll);

	m[0][0] = ch * cb + sh * sp * sb;
	m[0][1] = sb * cp;
	m[0][2] = -sh * cb + ch * sp * sb;
	m[0][3] = 0;
	m[1][0] = -ch * sb + sh * sp * cb;
	m[1][1] = cb * cp;
	m[1][2] = sb * sh + ch * sp * cb;
	m[1][3] = 0;
	m[2][0] = sh * cp;
	m[2][1] = -sp;
	m[2][2] = ch * cp;
	m[2][3] = 0;
	m[3][0] = 0;
	m[3][1] = 0;
	m[3][2] = 0;
	m[3][3] = 1;
	return m;
}

extract_euler_angle_xyz :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[2][1], m[2][2]);
	C2 := math.sqrt(m[0][0]*m[0][0] + m[1][0]*m[1][0]);
	T2 := math.atan2(-m[2][0], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(S1*m[0][2] - C1*m[0][1], C1*m[1][1] - S1*m[1][2]);
	t1 = -T1;
	t2 = -T2;
	t3 = -T3;
	return;
}

extract_euler_angle_yxz :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[2][0], m[2][2]);
	C2 := math.sqrt(m[0][1]*m[0][1] + m[1][1]*m[1][1]);
	T2 := math.atan2(-m[2][1], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(S1*m[1][2] - C1*m[1][0], C1*m[0][0] - S1*m[0][2]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_xzx :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[0][2], m[0][1]);
	S2 := math.sqrt(m[1][0]*m[1][0] + m[2][0]*m[2][0]);
	T2 := math.atan2(S2, m[0][0]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(C1*m[1][2] - S1*m[1][1], C1*m[2][2] - S1*m[2][1]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_xyx :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[0][1], -m[0][2]);
	S2 := math.sqrt(m[1][0]*m[1][0] + m[2][0]*m[2][0]);
	T2 := math.atan2(S2, m[0][0]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(-C1*m[2][1] - S1*m[2][2], C1*m[1][1] + S1*m[1][2]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_yxy :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[1][0], m[1][2]);
	S2 := math.sqrt(m[0][1]*m[0][1] + m[2][1]*m[2][1]);
	T2 := math.atan2(S2, m[1][1]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(C1*m[2][0] - S1*m[2][2], C1*m[0][0] - S1*m[0][2]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_yzy :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[1][2], -m[1][0]);
	S2 := math.sqrt(m[0][1]*m[0][1] + m[2][1]*m[2][1]);
	T2 := math.atan2(S2, m[1][1]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(-S1*m[0][0] - C1*m[0][2], S1*m[2][0] + C1*m[2][2]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}
extract_euler_angle_zyz :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[2][1], m[2][0]);
	S2 := math.sqrt(m[0][2]*m[0][2] + m[1][2]*m[1][2]);
	T2 := math.atan2(S2, m[2][2]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(C1*m[0][1] - S1*m[0][0], C1*m[1][1] - S1*m[1][0]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_zxz :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[2][0], -m[2][1]);
	S2 := math.sqrt(m[0][2]*m[0][2] + m[1][2]*m[1][2]);
	T2 := math.atan2(S2, m[2][2]);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(-C1*m[1][0] - S1*m[1][1], C1*m[0][0] + S1*m[0][1]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_xzy :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[1][2], m[1][1]);
	C2 := math.sqrt(m[0][0]*m[0][0] + m[2][0]*m[2][0]);
	T2 := math.atan2(-m[1][0], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(S1*m[0][1] - C1*m[0][2], C1*m[2][2] - S1*m[2][1]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_yzx :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(-m[0][2], m[0][0]);
	C2 := math.sqrt(m[1][1]*m[1][1] + m[2][1]*m[2][1]);
	T2 := math.atan2(m[0][1], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(S1*m[1][0] + C1*m[1][2], S1*m[2][0] + C1*m[2][2]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_zyx :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(m[0][1], m[0][0]);
	C2 := math.sqrt(m[1][2]*m[1][2] + m[2][2]*m[2][2]);
	T2 := math.atan2(-m[0][2], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(S1*m[2][0] - C1*m[2][1], C1*m[1][1] - S1*m[1][0]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}

extract_euler_angle_zxy :: proc(m: Matrix4) -> (t1, t2, t3: Float) {
	T1 := math.atan2(-m[1][0], m[1][1]);
	C2 := math.sqrt(m[0][2]*m[0][2] + m[2][2]*m[2][2]);
	T2 := math.atan2(m[1][2], C2);
	S1 := math.sin(T1);
	C1 := math.cos(T1);
	T3 := math.atan2(C1*m[2][0] + S1*m[2][1], C1*m[0][0] + S1*m[0][1]);
	t1 = T1;
	t2 = T2;
	t3 = T3;
	return;
}
