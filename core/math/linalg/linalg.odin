package linalg

import "core:math"
import "intrinsics"

// Generic

@private IS_NUMERIC :: intrinsics.type_is_numeric;
@private IS_QUATERNION :: intrinsics.type_is_quaternion;
@private IS_ARRAY :: intrinsics.type_is_array;


vector_dot :: proc(a, b: $T/[$N]$E) -> (c: E) where IS_NUMERIC(E) {
	for i in 0..<N {
		c += a[i] * b[i];
	}
	return;
}
quaternion128_dot :: proc(a, b: $T/quaternion128) -> (c: f32) {
	return real(a)*real(a) + imag(a)*imag(b) + jmag(a)*jmag(b) + kmag(a)*kmag(b);
}
quaternion256_dot :: proc(a, b: $T/quaternion256) -> (c: f64) {
	return real(a)*real(a) + imag(a)*imag(b) + jmag(a)*jmag(b) + kmag(a)*kmag(b);
}

dot :: proc{vector_dot, quaternion128_dot, quaternion256_dot};

quaternion_inverse :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return conj(q) * quaternion(1.0/dot(q, q), 0, 0, 0);
}


vector_cross2 :: proc(a, b: $T/[2]$E) -> E where IS_NUMERIC(E) {
	return a[0]*b[1] - b[0]*a[1];
}

vector_cross3 :: proc(a, b: $T/[3]$E) -> (c: T) where IS_NUMERIC(E) {
	c[0] = a[1]*b[2] - b[1]*a[2];
	c[1] = a[2]*b[0] - b[2]*a[0];
	c[2] = a[0]*b[1] - b[0]*a[1];
	return;
}

vector_cross :: proc{vector_cross2, vector_cross3};
cross :: vector_cross;

vector_normalize :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	return v / length(v);
}
quaternion_normalize :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return q/abs(q);
}
normalize :: proc{vector_normalize, quaternion_normalize};

vector_normalize0 :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	m := length(v);
	return m == 0 ? 0 : v/m;
}
quaternion_normalize0 :: proc(q: $Q) -> Q  where IS_QUATERNION(Q) {
	m := abs(q);
	return m == 0 ? 0 : q/m;
}
normalize0 :: proc{vector_normalize0, quaternion_normalize0};


vector_length :: proc(v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	return math.sqrt(dot(v, v));
}

vector_length2 :: proc(v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	return dot(v, v);
}

quaternion_length :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return abs(q);
}

quaternion_length2 :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return dot(q, q);
}

length :: proc{vector_length, quaternion_length};
length2 :: proc{vector_length2, quaternion_length2};



vector_sin :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sin(angle[i]);
	}
	return s;
}

vector_cos :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.cos(angle[i]);
	}
	return s;
}

vector_tan :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.tan(angle[i]);
	}
	return s;
}


vector_asin :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.asin(x[i]);
	}
	return s;
}

vector_acos :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.acos(x[i]);
	}
	return s;
}

vector_atan :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.atan(x[i]);
	}
	return s;
}

vector_atan2 :: proc(y, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.atan(y[i], x[i]);
	}
	return s;
}

vector_pow :: proc(x, y: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.pow(x[i], y[i]);
	}
	return s;
}

vector_expr :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.expr(x[i]);
	}
	return s;
}

vector_sqrt :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sqrt(x[i]);
	}
	return s;
}

vector_abs :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = abs(x[i]);
	}
	return s;
}

vector_sign :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sign(v[i]);
	}
	return s;
}

vector_floor :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.floor(v[i]);
	}
	return s;
}

vector_ceil :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.ceil(v[i]);
	}
	return s;
}


vector_mod :: proc(x, y: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.mod(x[i], y[i]);
	}
	return s;
}

vector_min :: proc(a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = min(a[i], b[i]);
	}
	return s;
}

vector_max :: proc(a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = max(a[i], b[i]);
	}
	return s;
}

vector_clamp :: proc(x, a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = clamp(x[i], a[i], b[i]);
	}
	return s;
}

vector_mix :: proc(x, y, a: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = x[i]*(1-a[i]) + y[i]*a[i];
	}
	return s;
}

vector_step :: proc(edge, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = x[i] < edge[i] ? 0 : 1;
	}
	return s;
}

vector_smoothstep :: proc(edge0, edge1, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		e0, e1 := edge0[i], edge1[i];
		t := clamp((x[i] - e0) / (e1 - e0), 0, 1);
		s[i] = t * t * (3 - 2*t);
	}
	return s;
}

vector_smootherstep :: proc(edge0, edge1, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		e0, e1 := edge0[i], edge1[i];
		t := clamp((x[i] - e0) / (e1 - e0), 0, 1);
		s[i] = t * t * t * (t * (6*t - 15) + 10);
	}
	return s;
}

vector_distance :: proc(p0, p1: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	return length(p1 - p0);
}

vector_reflect :: proc(i, n: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	b := n * (2 * dot(n, i));
	return i - b;
}

vector_refract :: proc(i, n: $V/[$N]$E, eta: E) -> V where IS_NUMERIC(E) {
	dv := dot(n, i);
	k := 1 - eta*eta - (1 - dv*dv);
	a := i * eta;
	b := n * eta*dv*math.sqrt(k);
	return (a - b) * E(int(k >= 0));
}



identity :: proc($T: typeid/[$N][N]$E) -> (m: T) {
	for i in 0..<N do m[i][i] = E(1);
	return m;
}

transpose :: proc(a: $T/[$N][$M]$E) -> (m: T) {
	for j in 0..<M {
		for i in 0..<N {
			m[j][i] = a[i][j];
		}
	}
	return;
}

matrix_mul :: proc(a, b: $M/[$N][N]$E) -> (c: M)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E) {
	for i in 0..<N {
		for k in 0..<N {
			for j in 0..<N {
				c[k][i] += a[j][i] * b[k][j];
			}
		}
	}
	return;
}

matrix_mul_differ :: proc(a: $A/[$J][$I]$E, b: $B/[$K][J]E) -> (c: [K][I]E)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E),
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


matrix_mul_vector :: proc(a: $A/[$I][$J]$E, b: $B/[I]E) -> (c: B)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E) {
	for i in 0..<I {
		for j in 0..<J {
			c[i] += a[i][j] * b[i];
		}
	}
	return;
}

quaternion128_mul_vector3 :: proc(q: $Q/quaternion128, v: $V/[3]$F/f32) -> V {
	Raw_Quaternion :: struct {xyz: [3]f32, r: f32};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f32)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}

quaternion256_mul_vector3 :: proc(q: $Q/quaternion256, v: $V/[3]$F/f64) -> V {
	Raw_Quaternion :: struct {xyz: [3]f64, r: f64};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f64)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}
quaternion_mul_vector3 :: proc{quaternion128_mul_vector3, quaternion256_mul_vector3};

mul :: proc{
	matrix_mul,
	matrix_mul_differ,
	matrix_mul_vector,
	quaternion128_mul_vector3,
	quaternion256_mul_vector3,
};

vector_to_ptr :: proc(v: ^$V/[$N]$E) -> ^E where IS_NUMERIC(E) {
	return &v[0];
}
matrix_to_ptr :: proc(m: ^$A/[$I][$J]$E) -> ^E where IS_NUMERIC(E) {
	return &m[0][0];
}


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

MATRIX1_IDENTITY :: Matrix1{{1}};
MATRIX2_IDENTITY :: Matrix2{{1, 0}, {0, 1}};
MATRIX3_IDENTITY :: Matrix3{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
MATRIX4_IDENTITY :: Matrix4{{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}};

QUATERNION_IDENTITY :: Quaternion(1);

VECTOR3_X_AXIS :: Vector3{1, 0, 0};
VECTOR3_Y_AXIS :: Vector3{0, 1, 0};
VECTOR3_Z_AXIS :: Vector3{0, 0, 1};



vector2_orthogonal :: proc(v: Vector2) -> Vector2 {
	return {-v.y, v.x};
}

vector3_orthogonal :: proc(v: Vector3) -> Vector3 {
	x := abs(v.x);
	y := abs(v.y);
	z := abs(v.z);

	other: Vector3 = x < y ? (x < z ? {1, 0, 0} : {0, 0, 1}) : (y < z ? {0, 1, 0} : {0, 0, 1});

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
		q := l < 0.5 ? l * (1+s) : l+s - l*s;
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
		s = l > 0.5 ? d / (2.0 - v_max - v_min) : d / (v_max + v_min);
		switch {
		case v_max == r:
			h = (g - b) / d + (g < b ? 6.0 : 0.0);
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

quaternion_from_euler_angles :: proc(pitch, yaw, roll: Float) -> Quaternion {
	p := quaternion_angle_axis(pitch, {1, 0, 0});
	y := quaternion_angle_axis(yaw,   {0, 1, 0});
	r := quaternion_angle_axis(roll,  {0, 0, 1});
	return (y * p) * r;
}

euler_angles_from_quaternion :: proc(q: Quaternion) -> (roll, pitch, yaw: Float) {
	// roll (x-axis rotation)
	sinr_cosp: Float = 2 * (real(q)*imag(q) + jmag(q)*kmag(q));
	cosr_cosp: Float = 1 - 2 * (imag(q)*imag(q) + jmag(q)*jmag(q));
	roll = Float(math.atan2(sinr_cosp, cosr_cosp));

	// pitch (y-axis rotation)
	sinp: Float = 2 * (real(q)*kmag(q) - kmag(q)*imag(q));
	if abs(sinp) >= 1 {
		pitch = Float(math.copy_sign(math.TAU * 0.25, sinp));
	} else {
		pitch = Float(math.asin(sinp));
	}

	// yaw (z-axis rotation)
	siny_cosp: Float = 2 * (real(q)*kmag(q) + imag(q)*jmag(q));
	cosy_cosp: Float = 1 - 2 * (jmag(q)*jmag(q) + kmag(q)*kmag(q));
	yaw = Float(math.atan2(siny_cosp, cosy_cosp));

	return;
}


quaternion_nlerp :: proc(a, b: Quaternion, t: Float) -> Quaternion {
	c := a + (b-a)*quaternion(t, 0, 0, 0);
	return normalize(c);
}


quaternion_slerp :: proc(x, y: Quaternion, t: Float) -> Quaternion {
	EPSILON :: size_of(Float) == 4 ? 1e-7 : 1e-15;

	a, b := x, y;
	cos_angle := dot(a, b);
	if cos_angle < 0 {
		b = -b;
		cos_angle = -cos_angle;
	}
	if cos_angle > 1 - EPSILON {
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


quaternion_between_two_vector3 :: proc(from, to: Vector3) -> Quaternion {
	EPSILON :: size_of(Float) == 4 ? 1e-7 : 1e-15;

	x := normalize(from);
	y := normalize(to);

	cos_theta := dot(x, y);
	if abs(cos_theta + 1) < 2*EPSILON {
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

matrix2_adjoint :: proc(m: Matrix2) -> Matrix2 {
	c: Matrix2;
	c[0][0] = +m[1][1];
	c[0][1] = -m[1][0];
	c[1][0] = -m[0][1];
	c[1][1] = +m[0][0];
	return c;
}


matrix3_from_quaternion :: proc(q: Quaternion) -> Matrix3 {
	xx := imag(q) * imag(q);
	xy := imag(q) * jmag(q);
	xz := imag(q) * kmag(q);
	xw := imag(q) * real(q);
	yy := jmag(q) * jmag(q);
	yz := jmag(q) * kmag(q);
	yw := jmag(q) * real(q);
	zz := kmag(q) * kmag(q);
	zw := kmag(q) * real(q);

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

matrix4_from_quaternion :: proc(q: Quaternion) -> Matrix4 {
	m := identity(Matrix4);

	xx := imag(q) * imag(q);
	xy := imag(q) * jmag(q);
	xz := imag(q) * kmag(q);
	xw := imag(q) * real(q);
	yy := jmag(q) * jmag(q);
	yz := jmag(q) * kmag(q);
	yw := jmag(q) * real(q);
	zz := kmag(q) * kmag(q);
	zw := kmag(q) * real(q);

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
		col := i < c ? i : i+1;
		for j in 0..<3 {
			row := j < r ? j : j+1;
			cut_down[i][j] = m[col][row];
		}
	}
	return matrix3_determinant(cut_down);
}

matrix4_cofactor :: proc(m: Matrix4, c, r: int) -> Float {
	sign := (c + r) % 2 == 0 ? Float(1) : Float(-1);
	minor := matrix4_minor(m, c, r);
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


translate_matrix4 :: matrix4_translate;
matrix4_translate :: proc(v: Vector3) -> Matrix4 {
	m := identity(Matrix4);
	m[3][0] = v[0];
	m[3][1] = v[1];
	m[3][2] = v[2];
	return m;
}


rotate_matrix4 :: matrix4_rotate;
matrix4_rotate :: proc(v: Vector3, angle_radians: Float) -> Matrix4 {
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


matrix4_perspective :: proc(fovy, aspect, near, far: Float) -> (m: Matrix4) {
	tan_half_fovy := math.tan(0.5 * fovy);
	m[0][0] = 1 / (aspect*tan_half_fovy);
	m[1][1] = 1 / (tan_half_fovy);
	m[2][2] = -(far + near) / (far - near);
	m[2][3] = -1;
	m[3][2] = -2*far*near / (far - near);
	return;
}


matrix_ortho3d :: proc(left, right, bottom, top, near, far: Float) -> (m: Matrix4) {
	m[0][0] = +2 / (right - left);
	m[1][1] = +2 / (top - bottom);
	m[2][2] = -2 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top - bottom);
	m[3][2] = -(far + near) / (far- near);
	m[3][3] = 1;
	return;
}


matrix4_infinite_perspective :: proc(fovy, aspect, near: Float) -> (m: Matrix4) {
	tan_half_fovy := math.tan(0.5 * fovy);
	m[0][0] = 1 / (aspect*tan_half_fovy);
	m[1][1] = 1 / (tan_half_fovy);
	m[2][2] = -1;
	m[2][3] = -1;
	m[3][2] = -2*near;
	return;
}
