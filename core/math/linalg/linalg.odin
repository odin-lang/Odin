package linalg

import "core:math"
import "intrinsics"

// Generic

dot_vector :: proc(a, b: $T/[$N]$E) -> (c: E) {
	for i in 0..<N {
		c += a[i] * b[i];
	}
	return;
}
dot_quaternion128 :: proc(a, b: $T/quaternion128) -> (c: f32) {
	return real(a)*real(a) + imag(a)*imag(b) + jmag(a)*jmag(b) + kmag(a)*kmag(b);
}
dot_quaternion256 :: proc(a, b: $T/quaternion256) -> (c: f64) {
	return real(a)*real(a) + imag(a)*imag(b) + jmag(a)*jmag(b) + kmag(a)*kmag(b);
}

dot :: proc{dot_vector, dot_quaternion128, dot_quaternion256};

cross2 :: proc(a, b: $T/[2]$E) -> E {
	return a[0]*b[1] - b[0]*a[1];
}

cross3 :: proc(a, b: $T/[3]$E) -> (c: T) {
	c[0] = +(a[1]*b[2] - b[1]*a[2]);
	c[1] = -(a[2]*b[0] - b[2]*a[0]);
	c[2] = +(a[0]*b[1] - b[0]*a[1]);
	return;
}

cross :: proc{cross2, cross3};


normalize_vector :: proc(v: $T/[$N]$E) -> T {
	return v / length(v);
}
normalize_quaternion128 :: proc(q: $Q/quaternion128) -> Q {
	return q/abs(q);
}
normalize_quaternion256 :: proc(q: $Q/quaternion256) -> Q {
	return q/abs(q);
}
normalize :: proc{normalize_vector, normalize_quaternion128, normalize_quaternion256};

normalize0_vector :: proc(v: $T/[$N]$E) -> T {
	m := length(v);
	return m == 0 ? 0 : v/m;
}
normalize0_quaternion128 :: proc(q: $Q/quaternion128) -> Q {
	m := abs(q);
	return m == 0 ? 0 : q/m;
}
normalize0_quaternion256 :: proc(q: $Q/quaternion256) -> Q {
	m := abs(q);
	return m == 0 ? 0 : q/m;
}
normalize0 :: proc{normalize0_vector, normalize0_quaternion128, normalize0_quaternion256};


length :: proc(v: $T/[$N]$E) -> E {
	return math.sqrt(dot(v, v));
}


identity :: proc($T: typeid/[$N][N]$E) -> (m: T) {
	for i in 0..<N do m[i][i] = E(1);
	return m;
}

transpose :: proc(a: $T/[$N][$M]$E) -> (m: [M][N]E) {
	for j in 0..<M {
		for i in 0..<N {
			m[j][i] = a[i][j];
		}
	}
	return;
}

mul_matrix :: proc(a, b: $M/[$N][N]$E) -> (c: M)
	where !intrinsics.type_is_array(E),
	      intrinsics.type_is_numeric(E) {
	for i in 0..<N {
		for k in 0..<N {
			for j in 0..<N {
				c[k][i] += a[j][i] * b[k][j];
			}
		}
	}
	return;
}

mul_matrix_differ :: proc(a: $A/[$J][$I]$E, b: $B/[$K][J]E) -> (c: [K][I]E)
	where !intrinsics.type_is_array(E),
	      intrinsics.type_is_numeric(E),
	      I != K {
	for k in 0..<K {
		for j in 0..<J {
			for i in 0..<I {
				c[k][i] += a[j][i] * b[k][j];
			}
		}
	}
	return;
}


mul_matrix_vector :: proc(a: $A/[$I][$J]$E, b: $B/[I]E) -> (c: B)
	where !intrinsics.type_is_array(E),
	      intrinsics.type_is_numeric(E) {
	for i in 0..<I {
		for j in 0..<J {
			c[i] += a[i][j] * b[i];
		}
	}
	return;
}

mul_quaternion128_vector3 :: proc(q: $Q/quaternion128, v: $V/[3]$F/f32) -> V {
	Raw_Quaternion :: struct {xyz: [3]f32, r: f32};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f32)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}

mul_quaternion256_vector3 :: proc(q: $Q/quaternion256, v: $V/[3]$F/f64) -> V {
	Raw_Quaternion :: struct {xyz: [3]f64, r: f64};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f64)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}
mul_quaternion_vector3 :: proc{mul_quaternion128_vector3, mul_quaternion256_vector3};

mul :: proc{
	mul_matrix,
	mul_matrix_differ,
	mul_matrix_vector,
	mul_quaternion128_vector3,
	mul_quaternion256_vector3,
};


// Specific

Float :: f32;

Vector2 :: distinct [2]Float;
Vector3 :: distinct [3]Float;
Vector4 :: distinct [4]Float;

Matrix1x1 :: distinct [1][1]Float;
Matrix1x2 :: distinct [1][2]Float;
Matrix1x3 :: distinct [1][3]Float;
Matrix1x4 :: distinct [1][4]Float;

Matrix2x1 :: distinct [2][1]Float;
Matrix2x2 :: distinct [2][2]Float;
Matrix2x3 :: distinct [2][3]Float;
Matrix2x4 :: distinct [2][4]Float;

Matrix3x1 :: distinct [3][1]Float;
Matrix3x2 :: distinct [3][2]Float;
Matrix3x3 :: distinct [3][3]Float;
Matrix3x4 :: distinct [3][4]Float;

Matrix4x1 :: distinct [4][1]Float;
Matrix4x2 :: distinct [4][2]Float;
Matrix4x3 :: distinct [4][3]Float;
Matrix4x4 :: distinct [4][4]Float;


Matrix1 :: Matrix1x1;
Matrix2 :: Matrix2x2;
Matrix3 :: Matrix3x3;
Matrix4 :: Matrix4x4;


Quaternion :: distinct (size_of(Float) == size_of(f32) ? quaternion128 : quaternion256);


translate_matrix4 :: proc(v: Vector3) -> Matrix4 {
	m := identity(Matrix4);
	m[3][0] = v[0];
	m[3][1] = v[1];
	m[3][2] = v[2];
	return m;
}


rotate_matrix4 :: proc(v: Vector3, angle_radians: Float) -> Matrix4 {
	c := math.cos(angle_radians);
	s := math.sin(angle_radians);

	a := normalize(v);
	t := a * (1-c);

	rot := identity(Matrix4);

	rot[0][0] = c + t[0]*a[0];
	rot[0][1] = 0 + t[0]*a[1] + s*a[2];
	rot[0][2] = 0 + t[0]*a[2] - s*a[1];
	rot[0][3] = 0;

	rot[1][0] = 0 + t[1]*a[0] - s*a[2];
	rot[1][1] = c + t[1]*a[1];
	rot[1][2] = 0 + t[1]*a[2] + s*a[0];
	rot[1][3] = 0;

	rot[2][0] = 0 + t[2]*a[0] + s*a[1];
	rot[2][1] = 0 + t[2]*a[1] - s*a[0];
	rot[2][2] = c + t[2]*a[2];
	rot[2][3] = 0;

	return rot;
}

scale_matrix4 :: proc(m: Matrix4, v: Vector3) -> Matrix4 {
	mm := m;
	mm[0][0] *= v[0];
	mm[1][1] *= v[1];
	mm[2][2] *= v[2];
	return mm;
}


look_at :: proc(eye, centre, up: Vector3) -> Matrix4 {
	f := normalize(centre - eye);
	s := normalize(cross(f, up));
	u := cross(s, f);
	return Matrix4{
		{+s.x, +u.x, -f.x, 0},
		{+s.y, +u.y, -f.y, 0},
		{+s.z, +u.z, -f.z, 0},
		{-dot(s, eye), -dot(u, eye), +dot(f, eye), 1},
	};
}


perspective :: proc(fovy, aspect, near, far: Float) -> (m: Matrix4) {
	tan_half_fovy := math.tan(0.5 * fovy);
	m[0][0] = 1 / (aspect*tan_half_fovy);
	m[1][1] = 1 / (tan_half_fovy);
	m[2][2] = -(far + near) / (far - near);
	m[2][3] = -1;
	m[3][2] = -2*far*near / (far - near);
	return;
}


ortho3d :: proc(left, right, bottom, top, near, far: Float) -> (m: Matrix4) {
	m[0][0] = +2 / (right - left);
	m[1][1] = +2 / (top - bottom);
	m[2][2] = -2 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top - bottom);
	m[3][2] = -(far + near) / (far- near);
	m[3][3] = 1;
	return;
}


axis_angle :: proc(axis: Vector3, angle_radians: Float) -> Quaternion {
	t := angle_radians*0.5;
	w := math.cos(t);
	v := normalize(axis) * math.sin(t);
	return quaternion(w, v.x, v.y, v.z);
}

angle_axis :: proc(angle_radians: Float, axis: Vector3) -> Quaternion {
	t := angle_radians*0.5;
	w := math.cos(t);
	v := normalize(axis) * math.sin(t);
	return quaternion(w, v.x, v.y, v.z);
}

euler_angles :: proc(pitch, yaw, roll: Float) -> Quaternion {
	p := axis_angle({1, 0, 0}, pitch);
	y := axis_angle({0, 1, 0}, yaw);
	r := axis_angle({0, 0, 1}, roll);
	return (y * p) * r;
}
