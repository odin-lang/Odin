package linalg

import "core:math"


// Specific

Float :: f32;

FLOAT_EPSILON :: 1e-7 when size_of(Float) == 4 else 1e-15;

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

Quaternion :: distinct (quaternion128 when size_of(Float) == size_of(f32) else quaternion256);

MATRIX1_IDENTITY :: Matrix1{{1}};
MATRIX2_IDENTITY :: Matrix2{{1, 0}, {0, 1}};
MATRIX3_IDENTITY :: Matrix3{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
MATRIX4_IDENTITY :: Matrix4{{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}};

QUATERNION_IDENTITY :: Quaternion(1);

VECTOR3_X_AXIS :: Vector3{1, 0, 0};
VECTOR3_Y_AXIS :: Vector3{0, 1, 0};
VECTOR3_Z_AXIS :: Vector3{0, 0, 1};


radians :: proc(degrees: Float) -> Float {
	return math.TAU * degrees / 360.0;
}

degrees :: proc(radians: Float) -> Float {
	return 360.0 * radians / math.TAU;
}


vector2_orthogonal :: proc(v: Vector2) -> Vector2 {
	return {-v.y, v.x};
}

vector3_orthogonal :: proc(v: Vector3) -> Vector3 {
	x := abs(v.x);
	y := abs(v.y);
	z := abs(v.z);

	other: Vector3;
	if x < y {
		if x < z {
			other = {1, 0, 0};
		} else {
			other = {0, 0, 1};
		}
	} else {
		if y < z {
			other = {0, 1, 0};
		} else {
			other = {0, 0, 1};
		}
	}
	return normalize(cross(v, other));
}


vector4_srgb_to_linear :: proc(col: Vector4) -> Vector4 {
	r := math.pow(col.x, 2.2);
	g := math.pow(col.y, 2.2);
	b := math.pow(col.z, 2.2);
	a := col.w;
	return {r, g, b, a};
}

vector4_linear_to_srgb :: proc(col: Vector4) -> Vector4 {
	a :: 2.51;
	b :: 0.03;
	c :: 2.43;
	d :: 0.59;
	e :: 0.14;

	x := col.x;
	y := col.y;
	z := col.z;

	x = (x * (a * x + b)) / (x * (c * x + d) + e);
	y = (y * (a * y + b)) / (y * (c * y + d) + e);
	z = (z * (a * z + b)) / (z * (c * z + d) + e);

	x = math.pow(clamp(x, 0, 1), 1.0 / 2.2);
	y = math.pow(clamp(y, 0, 1), 1.0 / 2.2);
	z = math.pow(clamp(z, 0, 1), 1.0 / 2.2);

	return {x, y, z, col.w};
}

vector4_hsl_to_rgb :: proc(h, s, l: Float, a: Float = 1) -> Vector4 {
	hue_to_rgb :: proc(p, q, t0: Float) -> Float {
		t := math.mod(t0, 1.0);
		switch {
		case t < 1.0/6.0: return p + (q - p) * 6.0 * t;
		case t < 1.0/2.0: return q;
		case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t);
		}
		return p;
	}

	r, g, b: Float;
	if s == 0 {
		r = l;
		g = l;
		b = l;
	} else {
		q := l * (1+s) if l < 0.5 else l+s - l*s;
		p := 2*l - q;
		r = hue_to_rgb(p, q, h + 1.0/3.0);
		g = hue_to_rgb(p, q, h);
		b = hue_to_rgb(p, q, h - 1.0/3.0);
	}
	return {r, g, b, a};
}

vector4_rgb_to_hsl :: proc(col: Vector4) -> Vector4 {
	r := col.x;
	g := col.y;
	b := col.z;
	a := col.w;
	v_min := min(r, g, b);
	v_max := max(r, g, b);
	h, s, l: Float;
	h  = 0.0;
	s  = 0.0;
	l  = (v_min + v_max) * 0.5;

	if v_max != v_min {
		d: = v_max - v_min;
		s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min);
		switch {
		case v_max == r:
			h = (g - b) / d + (6.0 if g < b else 0.0);
		case v_max == g:
			h = (b - r) / d + 2.0;
		case v_max == b:
			h = (r - g) / d + 4.0;
		}

		h *= 1.0/6.0;
	}

	return {h, s, l, a};
}



quaternion_angle_axis :: proc(angle_radians: Float, axis: Vector3) -> Quaternion {
	t := angle_radians*0.5;
	w := math.cos(t);
	v := normalize(axis) * math.sin(t);
	return quaternion(w, v.x, v.y, v.z);
}


quaternion_from_euler_angles :: proc(roll, pitch, yaw: Float) -> Quaternion {
	x, y, z := roll, pitch, yaw;
	a, b, c := x, y, z;

	ca, sa := math.cos(a*0.5), math.sin(a*0.5);
	cb, sb := math.cos(b*0.5), math.sin(b*0.5);
	cc, sc := math.cos(c*0.5), math.sin(c*0.5);

	q: Quaternion;
	q.x = sa*cb*cc - ca*sb*sc;
	q.y = ca*sb*cc + sa*cb*sc;
	q.z = ca*cb*sc - sa*sb*cc;
	q.w = ca*cb*cc + sa*sb*sc;
	return q;
}

euler_angles_from_quaternion :: proc(q: Quaternion) -> (roll, pitch, yaw: Float) {
	// roll, x-axis rotation
	sinr_cosp: Float = 2 * (q.w * q.x + q.y * q.z);
	cosr_cosp: Float = 1 - 2 * (q.x * q.x + q.y * q.y);
	roll = math.atan2(sinr_cosp, cosr_cosp);

	// pitch, y-axis rotation
	sinp: Float = 2 * (q.w * q.y - q.z * q.x);
	if abs(sinp) >= 1 {
		pitch = math.copy_sign(math.TAU * 0.25, sinp);
	} else {
		pitch = 2 * math.asin(sinp);
	}

	// yaw, z-axis rotation
	siny_cosp: Float = 2 * (q.w * q.z + q.x * q.y);
	cosy_cosp: Float = 1 - 2 * (q.y * q.y + q.z * q.z);
	yaw = math.atan2(siny_cosp, cosy_cosp);

	return;
}

quaternion_from_forward_and_up :: proc(forward, up: Vector3) -> Quaternion {
	f := normalize(forward);
	s := normalize(cross(f, up));
	u := cross(s, f);
	m := Matrix3{
		{+s.x, +u.x, -f.x},
		{+s.y, +u.y, -f.y},
		{+s.z, +u.z, -f.z},
	};

	tr := trace(m);

	q: Quaternion;

	switch {
	case tr > 0:
		S := 2 * math.sqrt(1 + tr);
		q.w = 0.25 * S;
		q.x = (m[2][1] - m[1][2]) / S;
		q.y = (m[0][2] - m[2][0]) / S;
		q.z = (m[1][0] - m[0][1]) / S;
	case (m[0][0] > m[1][1]) && (m[0][0] > m[2][2]):
		S := 2 * math.sqrt(1 + m[0][0] - m[1][1] - m[2][2]);
		q.w = (m[2][1] - m[1][2]) / S;
		q.x = 0.25 * S;
		q.y = (m[0][1] + m[1][0]) / S;
		q.z = (m[0][2] + m[2][0]) / S;
	case m[1][1] > m[2][2]:
		S := 2 * math.sqrt(1 + m[1][1] - m[0][0] - m[2][2]);
		q.w = (m[0][2] - m[2][0]) / S;
		q.x = (m[0][1] + m[1][0]) / S;
		q.y = 0.25 * S;
		q.z = (m[1][2] + m[2][1]) / S;
	case:
		S := 2 * math.sqrt(1 + m[2][2] - m[0][0] - m[1][1]);
		q.w = (m[1][0] - m[0][1]) / S;
		q.x = (m[0][2] - m[2][0]) / S;
		q.y = (m[1][2] + m[2][1]) / S;
		q.z = 0.25 * S;
	}

	return normalize(q);
}

quaternion_look_at :: proc(eye, centre: Vector3, up: Vector3) -> Quaternion {
	return quaternion_from_forward_and_up(centre-eye, up);
}


quaternion_nlerp :: proc(a, b: Quaternion, t: Float) -> Quaternion {
	c := a + (b-a)*quaternion(t, 0, 0, 0);
	return normalize(c);
}


quaternion_slerp :: proc(x, y: Quaternion, t: Float) -> Quaternion {

	a, b := x, y;
	cos_angle := dot(a, b);
	if cos_angle < 0 {
		b = -b;
		cos_angle = -cos_angle;
	}
	if cos_angle > 1 - FLOAT_EPSILON {
		return a + (b-a)*quaternion(t, 0, 0, 0);
	}

	angle := math.acos(cos_angle);
	sin_angle := math.sin(angle);
	factor_a, factor_b: Quaternion;
	factor_a = quaternion(math.sin((1-t) * angle) / sin_angle, 0, 0, 0);
	factor_b = quaternion(math.sin(t * angle)     / sin_angle, 0, 0, 0);

	return factor_a * a + factor_b * b;
}


quaternion_from_matrix4 :: proc(m: Matrix4) -> Quaternion {
	four_x_squared_minus_1, four_y_squared_minus_1,
	four_z_squared_minus_1, four_w_squared_minus_1,
	four_biggest_squared_minus_1: Float;

	/* xyzw */
	/* 0123 */
	biggest_index := 3;
	biggest_value, mult: Float;

	four_x_squared_minus_1 = m[0][0] - m[1][1] - m[2][2];
	four_y_squared_minus_1 = m[1][1] - m[0][0] - m[2][2];
	four_z_squared_minus_1 = m[2][2] - m[0][0] - m[1][1];
	four_w_squared_minus_1 = m[0][0] + m[1][1] + m[2][2];

	four_biggest_squared_minus_1 = four_w_squared_minus_1;
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1;
		biggest_index = 0;
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1;
		biggest_index = 1;
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1;
		biggest_index = 2;
	}

	biggest_value = math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5;
	mult = 0.25 / biggest_value;


	switch biggest_index {
	case 0:
		return quaternion(
			biggest_value,
			(m[0][1] + m[1][0]) * mult,
			(m[2][0] + m[0][2]) * mult,
			(m[1][2] - m[2][1]) * mult,
		);
	case 1:
		return quaternion(
			(m[0][1] + m[1][0]) * mult,
			biggest_value,
			(m[1][2] + m[2][1]) * mult,
			(m[2][0] - m[0][2]) * mult,
		);
	case 2:
		return quaternion(
			(m[2][0] + m[0][2]) * mult,
			(m[1][2] + m[2][1]) * mult,
			biggest_value,
			(m[0][1] - m[1][0]) * mult,
		);
	case 3:
		return quaternion(
			(m[1][2] - m[2][1]) * mult,
			(m[2][0] - m[0][2]) * mult,
			(m[0][1] - m[1][0]) * mult,
			biggest_value,
		);
	}

	return 0;
}


quaternion_from_matrix3 :: proc(m: Matrix3) -> Quaternion {
	four_x_squared_minus_1, four_y_squared_minus_1,
	four_z_squared_minus_1, four_w_squared_minus_1,
	four_biggest_squared_minus_1: Float;

	/* xyzw */
	/* 0123 */
	biggest_index := 3;
	biggest_value, mult: Float;

	four_x_squared_minus_1 = m[0][0] - m[1][1] - m[2][2];
	four_y_squared_minus_1 = m[1][1] - m[0][0] - m[2][2];
	four_z_squared_minus_1 = m[2][2] - m[0][0] - m[1][1];
	four_w_squared_minus_1 = m[0][0] + m[1][1] + m[2][2];

	four_biggest_squared_minus_1 = four_w_squared_minus_1;
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1;
		biggest_index = 0;
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1;
		biggest_index = 1;
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1;
		biggest_index = 2;
	}

	biggest_value = math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5;
	mult = 0.25 / biggest_value;


	switch biggest_index {
	case 0:
		return quaternion(
			biggest_value,
			(m[0][1] + m[1][0]) * mult,
			(m[2][0] + m[0][2]) * mult,
			(m[1][2] - m[2][1]) * mult,
		);
	case 1:
		return quaternion(
			(m[0][1] + m[1][0]) * mult,
			biggest_value,
			(m[1][2] + m[2][1]) * mult,
			(m[2][0] - m[0][2]) * mult,
		);
	case 2:
		return quaternion(
			(m[2][0] + m[0][2]) * mult,
			(m[1][2] + m[2][1]) * mult,
			biggest_value,
			(m[0][1] - m[1][0]) * mult,
		);
	case 3:
		return quaternion(
			(m[1][2] - m[2][1]) * mult,
			(m[2][0] - m[0][2]) * mult,
			(m[0][1] - m[1][0]) * mult,
			biggest_value,
		);
	}

	return 0;
}

quaternion_between_two_vector3 :: proc(from, to: Vector3) -> Quaternion {
	x := normalize(from);
	y := normalize(to);

	cos_theta := dot(x, y);
	if abs(cos_theta + 1) < 2*FLOAT_EPSILON {
		v := vector3_orthogonal(x);
		return quaternion(0, v.x, v.y, v.z);
	}
	v := cross(x, y);
	w := cos_theta + 1;
	return Quaternion(normalize(quaternion(w, v.x, v.y, v.z)));
}


matrix2_inverse_transpose :: proc(m: Matrix2) -> Matrix2 {
	c: Matrix2;
	d := m[0][0]*m[1][1] - m[1][0]*m[0][1];
	id := 1.0/d;
	c[0][0] = +m[1][1] * id;
	c[0][1] = -m[0][1] * id;
	c[1][0] = -m[1][0] * id;
	c[1][1] = +m[0][0] * id;
	return c;
}
matrix2_determinant :: proc(m: Matrix2) -> Float {
	return m[0][0]*m[1][1] - m[1][0]*m[0][1];
}
matrix2_inverse :: proc(m: Matrix2) -> Matrix2 {
	c: Matrix2;
	d := m[0][0]*m[1][1] - m[1][0]*m[0][1];
	id := 1.0/d;
	c[0][0] = +m[1][1] * id;
	c[1][0] = -m[0][1] * id;
	c[0][1] = -m[1][0] * id;
	c[1][1] = +m[0][0] * id;
	return c;
}

matrix2_adjoint :: proc(m: Matrix2) -> Matrix2 {
	c: Matrix2;
	c[0][0] = +m[1][1];
	c[0][1] = -m[1][0];
	c[1][0] = -m[0][1];
	c[1][1] = +m[0][0];
	return c;
}


matrix3_from_quaternion :: proc(q: Quaternion) -> Matrix3 {
	xx := q.x * q.x;
	xy := q.x * q.y;
	xz := q.x * q.z;
	xw := q.x * q.w;
	yy := q.y * q.y;
	yz := q.y * q.z;
	yw := q.y * q.w;
	zz := q.z * q.z;
	zw := q.z * q.w;

	m: Matrix3;
	m[0][0] = 1 - 2 * (yy + zz);
	m[1][0] = 2 * (xy - zw);
	m[2][0] = 2 * (xz + yw);

	m[0][1] = 2 * (xy + zw);
	m[1][1] = 1 - 2 * (xx + zz);
	m[2][1] = 2 * (yz - xw);

	m[0][2] = 2 * (xz - yw);
	m[1][2] = 2 * (yz + xw);
	m[2][2] = 1 - 2 * (xx + yy);

	return m;
}

matrix3_inverse :: proc(m: Matrix3) -> Matrix3 {
	return transpose(matrix3_inverse_transpose(m));
}


matrix3_determinant :: proc(m: Matrix3) -> Float {
	a := +m[0][0] * (m[1][1] * m[2][2] - m[2][1] * m[1][2]);
	b := -m[1][0] * (m[0][1] * m[2][2] - m[2][1] * m[0][2]);
	c := +m[2][0] * (m[0][1] * m[1][2] - m[1][1] * m[0][2]);
	return a + b + c;
}

matrix3_adjoint :: proc(m: Matrix3) -> Matrix3 {
	adjoint: Matrix3;
	adjoint[0][0] = +(m[1][1] * m[2][2] - m[1][2] * m[2][1]);
	adjoint[1][0] = -(m[0][1] * m[2][2] - m[0][2] * m[2][1]);
	adjoint[2][0] = +(m[0][1] * m[1][2] - m[0][2] * m[1][1]);
	adjoint[0][1] = -(m[1][0] * m[2][2] - m[1][2] * m[2][0]);
	adjoint[1][1] = +(m[0][0] * m[2][2] - m[0][2] * m[2][0]);
	adjoint[2][1] = -(m[0][0] * m[1][2] - m[0][2] * m[1][0]);
	adjoint[0][2] = +(m[1][0] * m[2][1] - m[1][1] * m[2][0]);
	adjoint[1][2] = -(m[0][0] * m[2][1] - m[0][1] * m[2][0]);
	adjoint[2][2] = +(m[0][0] * m[1][1] - m[0][1] * m[1][0]);
	return adjoint;
}

matrix3_inverse_transpose :: proc(m: Matrix3) -> Matrix3 {
	inverse_transpose: Matrix3;

	adjoint := matrix3_adjoint(m);
	determinant := matrix3_determinant(m);
	inv_determinant := 1.0 / determinant;
	for i in 0..<3 {
		for j in 0..<3 {
			inverse_transpose[i][j] = adjoint[i][j] * inv_determinant;
		}
	}
	return inverse_transpose;
}


matrix3_scale :: proc(s: Vector3) -> Matrix3 {
	m: Matrix3;
	m[0][0] = s[0];
	m[1][1] = s[1];
	m[2][2] = s[2];
	return m;
}

matrix3_rotate :: proc(angle_radians: Float, v: Vector3) -> Matrix3 {
	c := math.cos(angle_radians);
	s := math.sin(angle_radians);

	a := normalize(v);
	t := a * (1-c);

	rot: Matrix3 = ---;

	rot[0][0] = c + t[0]*a[0];
	rot[0][1] = 0 + t[0]*a[1] + s*a[2];
	rot[0][2] = 0 + t[0]*a[2] - s*a[1];

	rot[1][0] = 0 + t[1]*a[0] - s*a[2];
	rot[1][1] = c + t[1]*a[1];
	rot[1][2] = 0 + t[1]*a[2] + s*a[0];

	rot[2][0] = 0 + t[2]*a[0] + s*a[1];
	rot[2][1] = 0 + t[2]*a[1] - s*a[0];
	rot[2][2] = c + t[2]*a[2];

	return rot;
}

matrix3_look_at :: proc(eye, centre, up: Vector3) -> Matrix3 {
	f := normalize(centre - eye);
	s := normalize(cross(f, up));
	u := cross(s, f);
	return Matrix3{
		{+s.x, +u.x, -f.x},
		{+s.y, +u.y, -f.y},
		{+s.z, +u.z, -f.z},
	};
}

matrix4_from_quaternion :: proc(q: Quaternion) -> Matrix4 {
	m := identity(Matrix4);

	xx := q.x * q.x;
	xy := q.x * q.y;
	xz := q.x * q.z;
	xw := q.x * q.w;
	yy := q.y * q.y;
	yz := q.y * q.z;
	yw := q.y * q.w;
	zz := q.z * q.z;
	zw := q.z * q.w;

	m[0][0] = 1 - 2 * (yy + zz);
	m[1][0] = 2 * (xy - zw);
	m[2][0] = 2 * (xz + yw);

	m[0][1] = 2 * (xy + zw);
	m[1][1] = 1 - 2 * (xx + zz);
	m[2][1] = 2 * (yz - xw);

	m[0][2] = 2 * (xz - yw);
	m[1][2] = 2 * (yz + xw);
	m[2][2] = 1 - 2 * (xx + yy);

	return m;
}

matrix4_from_trs :: proc(t: Vector3, r: Quaternion, s: Vector3) -> Matrix4 {
	translation := matrix4_translate(t);
	rotation := matrix4_from_quaternion(r);
	scale := matrix4_scale(s);
	return mul(translation, mul(rotation, scale));
}


matrix4_inverse :: proc(m: Matrix4) -> Matrix4 {
	return transpose(matrix4_inverse_transpose(m));
}


matrix4_minor :: proc(m: Matrix4, c, r: int) -> Float {
	cut_down: Matrix3;
	for i in 0..<3 {
		col := i if i < c else i+1;
		for j in 0..<3 {
			row := j if j < r else j+1;
			cut_down[i][j] = m[col][row];
		}
	}
	return matrix3_determinant(cut_down);
}

matrix4_cofactor :: proc(m: Matrix4, c, r: int) -> Float {
	sign, minor: Float;
	sign = 1 if (c + r) % 2 == 0 else -1;
	minor = matrix4_minor(m, c, r);
	return sign * minor;
}

matrix4_adjoint :: proc(m: Matrix4) -> Matrix4 {
	adjoint: Matrix4;
	for i in 0..<4 {
		for j in 0..<4 {
			adjoint[i][j] = matrix4_cofactor(m, i, j);
		}
	}
	return adjoint;
}

matrix4_determinant :: proc(m: Matrix4) -> Float {
	adjoint := matrix4_adjoint(m);
	determinant: Float = 0;
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0];
	}
	return determinant;

}

matrix4_inverse_transpose :: proc(m: Matrix4) -> Matrix4 {
	adjoint := matrix4_adjoint(m);
	determinant: Float = 0;
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0];
	}
	inv_determinant := 1.0 / determinant;
	inverse_transpose: Matrix4;
	for i in 0..<4 {
		for j in 0..<4 {
			inverse_transpose[i][j] = adjoint[i][j] * inv_determinant;
		}
	}
	return inverse_transpose;
}

matrix4_translate :: proc(v: Vector3) -> Matrix4 {
	m := identity(Matrix4);
	m[3][0] = v[0];
	m[3][1] = v[1];
	m[3][2] = v[2];
	return m;
}


matrix4_rotate :: proc(angle_radians: Float, v: Vector3) -> Matrix4 {
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

matrix4_scale :: proc(v: Vector3) -> Matrix4 {
	m: Matrix4;
	m[0][0] = v[0];
	m[1][1] = v[1];
	m[2][2] = v[2];
	m[3][3] = 1;
	return m;
}

matrix4_look_at :: proc(eye, centre, up: Vector3) -> Matrix4 {
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


matrix4_perspective :: proc(fovy, aspect, near, far: Float, flip_z_axis := true) -> (m: Matrix4) {
	tan_half_fovy := math.tan(0.5 * fovy);
	m[0][0] = 1 / (aspect*tan_half_fovy);
	m[1][1] = 1 / (tan_half_fovy);
	m[2][2] = +(far + near) / (far - near);
	m[2][3] = +1;
	m[3][2] = -2*far*near / (far - near);

	if flip_z_axis {
		m[2] = -m[2];
	}

	return;
}


matrix_ortho3d :: proc(left, right, bottom, top, near, far: Float, flip_z_axis := true) -> (m: Matrix4) {
	m[0][0] = +2 / (right - left);
	m[1][1] = +2 / (top - bottom);
	m[2][2] = +2 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top - bottom);
	m[3][2] = -(far + near) / (far- near);
	m[3][3] = 1;

	if flip_z_axis {
		m[2] = -m[2];
	}

	return;
}


matrix4_infinite_perspective :: proc(fovy, aspect, near: Float, flip_z_axis := true) -> (m: Matrix4) {
	tan_half_fovy := math.tan(0.5 * fovy);
	m[0][0] = 1 / (aspect*tan_half_fovy);
	m[1][1] = 1 / (tan_half_fovy);
	m[2][2] = +1;
	m[2][3] = +1;
	m[3][2] = -2*near;

	if flip_z_axis {
		m[2] = -m[2];
	}

	return;
}
