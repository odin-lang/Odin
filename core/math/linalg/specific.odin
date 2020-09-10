package linalg

import "core:math"


// Specific

Float :: f64 when #config(ODIN_MATH_LINALG_USE_F64, false) else f32;

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


vector2_orthogonal :: proc(v: $V/[2]$E) -> V where !IS_ARRAY(E), IS_FLOAT(E) {
	return {-v.y, v.x};
}

vector3_orthogonal :: proc(v: $V/[3]$E) -> V where !IS_ARRAY(E), IS_FLOAT(E) {
	x := abs(v.x);
	y := abs(v.y);
	z := abs(v.z);

	other: V;
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

orthogonal :: proc{vector2_orthogonal, vector3_orthogonal};



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
	hue_to_rgb :: proc(p, q, t: Float) -> Float {
		t := t;
		if t < 0 do t += 1;
		if t > 1 do t -= 1;
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



quaternion_angle_axis :: proc(angle_radians: Float, axis: Vector3) -> (q: Quaternion) {
	t := angle_radians*0.5;
	v := normalize(axis) * math.sin(t);
	q.x = v.x;
	q.y = v.y;
	q.z = v.z;
	q.w = math.cos(t);
	return;
}

angle_from_quaternion :: proc(q: Quaternion) -> Float {
	if abs(q.w) > math.SQRT_THREE*0.5 {
		return math.asin(q.x*q.x + q.y*q.y + q.z*q.z) * 2;
	}

	return math.cos(q.x) * 2;
}

axis_from_quaternion :: proc(q: Quaternion) -> Vector3 {
	t1 := 1 - q.w*q.w;
	if t1 < 0 {
		return Vector3{0, 0, 1};
	}
	t2 := 1.0 / math.sqrt(t1);
	return Vector3{q.x*t2, q.y*t2, q.z*t2};
}
angle_axis_from_quaternion :: proc(q: Quaternion) -> (angle: Float, axis: Vector3) {
	angle = angle_from_quaternion(q);
	axis  = axis_from_quaternion(q);
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
	return quaternion_from_matrix3(matrix3_look_at(eye, centre, up));
}


quaternion_nlerp :: proc(a, b: Quaternion, t: Float) -> (c: Quaternion) {
	c.x = a.x + (b.x-a.x)*t;
	c.y = a.y + (b.y-a.y)*t;
	c.z = a.z + (b.z-a.z)*t;
	c.w = a.w + (b.w-a.w)*t;
	return normalize(c);
}


quaternion_slerp :: proc(x, y: Quaternion, t: Float) -> (q: Quaternion) {
	a, b := x, y;
	cos_angle := dot(a, b);
	if cos_angle < 0 {
		b = -b;
		cos_angle = -cos_angle;
	}
	if cos_angle > 1 - FLOAT_EPSILON {
		q.x = a.x + (b.x-a.x)*t;
		q.y = a.y + (b.y-a.y)*t;
		q.z = a.z + (b.z-a.z)*t;
		q.w = a.w + (b.w-a.w)*t;
		return;
	}

	angle := math.acos(cos_angle);
	sin_angle := math.sin(angle);
	factor_a := math.sin((1-t) * angle) / sin_angle;
	factor_b := math.sin(t * angle)     / sin_angle;


	q.x = factor_a * a.x + factor_b * b.x;
	q.y = factor_a * a.y + factor_b * b.y;
	q.z = factor_a * a.z + factor_b * b.z;
	q.w = factor_a * a.w + factor_b * b.w;
	return;
}

quaternion_squad :: proc(q1, q2, s1, s2: Quaternion, h: Float) -> Quaternion {
	slerp :: quaternion_slerp;
	return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h);
}


quaternion_from_matrix4 :: proc(m: Matrix4) -> (q: Quaternion) {
	m3: Matrix3 = ---;
	m3[0][0], m3[0][1], m3[0][2] = m[0][0], m[0][1], m[0][2];
	m3[1][0], m3[1][1], m3[1][2] = m[1][0], m[1][1], m[1][2];
	m3[2][0], m3[2][1], m3[2][2] = m[2][0], m[2][1], m[2][2];
	return quaternion_from_matrix3(m3);
}


quaternion_from_matrix3 :: proc(m: Matrix3) -> (q: Quaternion) {
	four_x_squared_minus_1 := m[0][0] - m[1][1] - m[2][2];
	four_y_squared_minus_1 := m[1][1] - m[0][0] - m[2][2];
	four_z_squared_minus_1 := m[2][2] - m[0][0] - m[1][1];
	four_w_squared_minus_1 := m[0][0] + m[1][1] + m[2][2];

	biggest_index := 0;
	four_biggest_squared_minus_1 := four_w_squared_minus_1;
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1;
		biggest_index = 1;
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1;
		biggest_index = 2;
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1;
		biggest_index = 3;
	}

	biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5;
	mult := 0.25 / biggest_val;

	q = 1;
	switch biggest_index {
	case 0:
		q.w = biggest_val;
		q.x = (m[1][2] - m[2][1]) * mult;
		q.y = (m[2][0] - m[0][2]) * mult;
		q.z = (m[0][1] - m[1][0]) * mult;
	case 1:
		q.w = (m[1][2] - m[2][1]) * mult;
		q.x = biggest_val;
		q.y = (m[0][1] + m[1][0]) * mult;
		q.z = (m[2][0] + m[0][2]) * mult;
	case 2:
		q.w = (m[2][0] - m[0][2]) * mult;
		q.x = (m[0][1] + m[1][0]) * mult;
		q.y = biggest_val;
		q.z = (m[1][2] + m[2][1]) * mult;
	case 3:
		q.w = (m[0][1] - m[1][0]) * mult;
		q.x = (m[2][0] + m[0][2]) * mult;
		q.y = (m[1][2] + m[2][1]) * mult;
		q.z = biggest_val;
	}
	return;
}

quaternion_between_two_vector3 :: proc(from, to: Vector3) -> (q: Quaternion) {
	x := normalize(from);
	y := normalize(to);

	cos_theta := dot(x, y);
	if abs(cos_theta + 1) < 2*FLOAT_EPSILON {
		v := vector3_orthogonal(x);
		q.x = v.x;
		q.y = v.y;
		q.z = v.z;
		q.w = 0;
		return;
	}
	v := cross(x, y);
	w := cos_theta + 1;
	q.w = w;
	q.x = v.x;
	q.y = v.y;
	q.z = v.z;
	return normalize(q);
}


matrix2_inverse_transpose :: proc(m: Matrix2) -> (c: Matrix2) {
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
matrix2_inverse :: proc(m: Matrix2) -> (c: Matrix2) {
	d := m[0][0]*m[1][1] - m[1][0]*m[0][1];
	id := 1.0/d;
	c[0][0] = +m[1][1] * id;
	c[1][0] = -m[0][1] * id;
	c[0][1] = -m[1][0] * id;
	c[1][1] = +m[0][0] * id;
	return c;
}

matrix2_adjoint :: proc(m: Matrix2) -> (c: Matrix2) {
	c[0][0] = +m[1][1];
	c[0][1] = -m[1][0];
	c[1][0] = -m[0][1];
	c[1][1] = +m[0][0];
	return c;
}


matrix3_from_quaternion :: proc(q: Quaternion) -> (m: Matrix3) {
	qxx := q.x * q.x;
	qyy := q.y * q.y;
	qzz := q.z * q.z;
	qxz := q.x * q.z;
	qxy := q.x * q.y;
	qyz := q.y * q.z;
	qwx := q.w * q.x;
	qwy := q.w * q.y;
	qwz := q.w * q.z;

	m[0][0] = 1 - 2 * (qyy + qzz);
	m[0][1] = 2 * (qxy + qwz);
	m[0][2] = 2 * (qxz - qwy);

	m[1][0] = 2 * (qxy - qwz);
	m[1][1] = 1 - 2 * (qxx + qzz);
	m[1][2] = 2 * (qyz + qwx);

	m[2][0] = 2 * (qxz + qwy);
	m[2][1] = 2 * (qyz - qwx);
	m[2][2] = 1 - 2 * (qxx + qyy);
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

matrix3_adjoint :: proc(m: Matrix3) -> (adjoint: Matrix3) {
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


matrix3_scale :: proc(s: Vector3) -> (m: Matrix3) {
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

matrix4_from_quaternion :: proc(q: Quaternion) -> (m: Matrix4) {
	qxx := q.x * q.x;
	qyy := q.y * q.y;
	qzz := q.z * q.z;
	qxz := q.x * q.z;
	qxy := q.x * q.y;
	qyz := q.y * q.z;
	qwx := q.w * q.x;
	qwy := q.w * q.y;
	qwz := q.w * q.z;

	m[0][0] = 1 - 2 * (qyy + qzz);
	m[0][1] = 2 * (qxy + qwz);
	m[0][2] = 2 * (qxz - qwy);

	m[1][0] = 2 * (qxy - qwz);
	m[1][1] = 1 - 2 * (qxx + qzz);
	m[1][2] = 2 * (qyz + qwx);

	m[2][0] = 2 * (qxz + qwy);
	m[2][1] = 2 * (qyz - qwx);
	m[2][2] = 1 - 2 * (qxx + qyy);

	m[3][3] = 1;

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
	m := MATRIX4_IDENTITY;
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

	rot := MATRIX4_IDENTITY;

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

matrix4_look_at :: proc(eye, centre, up: Vector3, flip_z_axis := true) -> Matrix4 {
	f := normalize(centre - eye);
	s := normalize(cross(f, up));
	u := cross(s, f);

	fe := dot(f, eye);

	m := Matrix4{
		{+s.x, +u.x, -f.x, 0},
		{+s.y, +u.y, -f.y, 0},
		{+s.z, +u.z, -f.z, 0},
		{-dot(s, eye), -dot(u, eye), +fe if flip_z_axis else -fe, 1},
	};
	return m;
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


