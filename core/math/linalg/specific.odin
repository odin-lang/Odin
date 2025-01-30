package linalg

import "base:builtin"
import "core:math"

F16_EPSILON :: 1e-3
F32_EPSILON :: 1e-7
F64_EPSILON :: 1e-15

Vector2f16 :: [2]f16
Vector3f16 :: [3]f16
Vector4f16 :: [4]f16

Matrix1x1f16 :: matrix[1, 1]f16
Matrix1x2f16 :: matrix[1, 2]f16
Matrix1x3f16 :: matrix[1, 3]f16
Matrix1x4f16 :: matrix[1, 4]f16

Matrix2x1f16 :: matrix[2, 1]f16
Matrix2x2f16 :: matrix[2, 2]f16
Matrix2x3f16 :: matrix[2, 3]f16
Matrix2x4f16 :: matrix[2, 4]f16

Matrix3x1f16 :: matrix[3, 1]f16
Matrix3x2f16 :: matrix[3, 2]f16
Matrix3x3f16 :: matrix[3, 3]f16
Matrix3x4f16 :: matrix[3, 4]f16

Matrix4x1f16 :: matrix[4, 1]f16
Matrix4x2f16 :: matrix[4, 2]f16
Matrix4x3f16 :: matrix[4, 3]f16
Matrix4x4f16 :: matrix[4, 4]f16

Matrix1f16 :: Matrix1x1f16
Matrix2f16 :: Matrix2x2f16
Matrix3f16 :: Matrix3x3f16
Matrix4f16 :: Matrix4x4f16

Vector2f32 :: [2]f32
Vector3f32 :: [3]f32
Vector4f32 :: [4]f32

Matrix1x1f32 :: matrix[1, 1]f32
Matrix1x2f32 :: matrix[1, 2]f32
Matrix1x3f32 :: matrix[1, 3]f32
Matrix1x4f32 :: matrix[1, 4]f32

Matrix2x1f32 :: matrix[2, 1]f32
Matrix2x2f32 :: matrix[2, 2]f32
Matrix2x3f32 :: matrix[2, 3]f32
Matrix2x4f32 :: matrix[2, 4]f32

Matrix3x1f32 :: matrix[3, 1]f32
Matrix3x2f32 :: matrix[3, 2]f32
Matrix3x3f32 :: matrix[3, 3]f32
Matrix3x4f32 :: matrix[3, 4]f32

Matrix4x1f32 :: matrix[4, 1]f32
Matrix4x2f32 :: matrix[4, 2]f32
Matrix4x3f32 :: matrix[4, 3]f32
Matrix4x4f32 :: matrix[4, 4]f32

Matrix1f32 :: Matrix1x1f32
Matrix2f32 :: Matrix2x2f32
Matrix3f32 :: Matrix3x3f32
Matrix4f32 :: Matrix4x4f32

Vector2f64 :: [2]f64
Vector3f64 :: [3]f64
Vector4f64 :: [4]f64

Matrix1x1f64 :: matrix[1, 1]f64
Matrix1x2f64 :: matrix[1, 2]f64
Matrix1x3f64 :: matrix[1, 3]f64
Matrix1x4f64 :: matrix[1, 4]f64

Matrix2x1f64 :: matrix[2, 1]f64
Matrix2x2f64 :: matrix[2, 2]f64
Matrix2x3f64 :: matrix[2, 3]f64
Matrix2x4f64 :: matrix[2, 4]f64

Matrix3x1f64 :: matrix[3, 1]f64
Matrix3x2f64 :: matrix[3, 2]f64
Matrix3x3f64 :: matrix[3, 3]f64
Matrix3x4f64 :: matrix[3, 4]f64

Matrix4x1f64 :: matrix[4, 1]f64
Matrix4x2f64 :: matrix[4, 2]f64
Matrix4x3f64 :: matrix[4, 3]f64
Matrix4x4f64 :: matrix[4, 4]f64

Matrix1f64 :: Matrix1x1f64
Matrix2f64 :: Matrix2x2f64
Matrix3f64 :: Matrix3x3f64
Matrix4f64 :: Matrix4x4f64

Quaternionf16 :: quaternion64
Quaternionf32 :: quaternion128
Quaternionf64 :: quaternion256

MATRIX1F16_IDENTITY :: Matrix1f16(1)
MATRIX2F16_IDENTITY :: Matrix2f16(1)
MATRIX3F16_IDENTITY :: Matrix3f16(1)
MATRIX4F16_IDENTITY :: Matrix4f16(1)

MATRIX1F32_IDENTITY :: Matrix1f32(1)
MATRIX2F32_IDENTITY :: Matrix2f32(1)
MATRIX3F32_IDENTITY :: Matrix3f32(1)
MATRIX4F32_IDENTITY :: Matrix4f32(1)

MATRIX1F64_IDENTITY :: Matrix1f64(1)
MATRIX2F64_IDENTITY :: Matrix2f64(1)
MATRIX3F64_IDENTITY :: Matrix3f64(1)
MATRIX4F64_IDENTITY :: Matrix4f64(1)

QUATERNIONF16_IDENTITY :: Quaternionf16(1)
QUATERNIONF32_IDENTITY :: Quaternionf32(1)
QUATERNIONF64_IDENTITY :: Quaternionf64(1)

VECTOR3F16_X_AXIS :: Vector3f16{1, 0, 0}
VECTOR3F16_Y_AXIS :: Vector3f16{0, 1, 0}
VECTOR3F16_Z_AXIS :: Vector3f16{0, 0, 1}

VECTOR3F32_X_AXIS :: Vector3f32{1, 0, 0}
VECTOR3F32_Y_AXIS :: Vector3f32{0, 1, 0}
VECTOR3F32_Z_AXIS :: Vector3f32{0, 0, 1}

VECTOR3F64_X_AXIS :: Vector3f64{1, 0, 0}
VECTOR3F64_Y_AXIS :: Vector3f64{0, 1, 0}
VECTOR3F64_Z_AXIS :: Vector3f64{0, 0, 1}


@(require_results)
vector2_orthogonal :: proc "contextless" (v: $V/[2]$E) -> V where !IS_ARRAY(E), IS_FLOAT(E) {
	return {-v.y, v.x}
}

@(require_results)
vector3_orthogonal :: proc "contextless" (v: $V/[3]$E) -> V where !IS_ARRAY(E), IS_FLOAT(E) {
	x := abs(v.x)
	y := abs(v.y)
	z := abs(v.z)

	other: V
	if x < y {
		if x < z {
			other = {1, 0, 0}
		} else {
			other = {0, 0, 1}
		}
	} else {
		if y < z {
			other = {0, 1, 0}
		} else {
			other = {0, 0, 1}
		}
	}
	return normalize(cross(v, other))
}

orthogonal :: proc{vector2_orthogonal, vector3_orthogonal}



@(require_results)
vector4_srgb_to_linear_f16 :: proc "contextless" (col: Vector4f16) -> Vector4f16 {
	r := math.pow(col.x, 2.2)
	g := math.pow(col.y, 2.2)
	b := math.pow(col.z, 2.2)
	a := col.w
	return {r, g, b, a}
}
@(require_results)
vector4_srgb_to_linear_f32 :: proc "contextless" (col: Vector4f32) -> Vector4f32 {
	r := math.pow(col.x, 2.2)
	g := math.pow(col.y, 2.2)
	b := math.pow(col.z, 2.2)
	a := col.w
	return {r, g, b, a}
}
@(require_results)
vector4_srgb_to_linear_f64 :: proc "contextless" (col: Vector4f64) -> Vector4f64 {
	r := math.pow(col.x, 2.2)
	g := math.pow(col.y, 2.2)
	b := math.pow(col.z, 2.2)
	a := col.w
	return {r, g, b, a}
}
vector4_srgb_to_linear :: proc{
	vector4_srgb_to_linear_f16,
	vector4_srgb_to_linear_f32,
	vector4_srgb_to_linear_f64,
}


@(require_results)
vector4_linear_to_srgb_f16 :: proc "contextless" (col: Vector4f16) -> Vector4f16 {
	a :: 2.51
	b :: 0.03
	c :: 2.43
	d :: 0.59
	e :: 0.14

	x := col.x
	y := col.y
	z := col.z

	x = (x * (a * x + b)) / (x * (c * x + d) + e)
	y = (y * (a * y + b)) / (y * (c * y + d) + e)
	z = (z * (a * z + b)) / (z * (c * z + d) + e)

	x = math.pow(clamp(x, 0, 1), 1.0 / 2.2)
	y = math.pow(clamp(y, 0, 1), 1.0 / 2.2)
	z = math.pow(clamp(z, 0, 1), 1.0 / 2.2)

	return {x, y, z, col.w}
}
@(require_results)
vector4_linear_to_srgb_f32 :: proc "contextless" (col: Vector4f32) -> Vector4f32 {
	a :: 2.51
	b :: 0.03
	c :: 2.43
	d :: 0.59
	e :: 0.14

	x := col.x
	y := col.y
	z := col.z

	x = (x * (a * x + b)) / (x * (c * x + d) + e)
	y = (y * (a * y + b)) / (y * (c * y + d) + e)
	z = (z * (a * z + b)) / (z * (c * z + d) + e)

	x = math.pow(clamp(x, 0, 1), 1.0 / 2.2)
	y = math.pow(clamp(y, 0, 1), 1.0 / 2.2)
	z = math.pow(clamp(z, 0, 1), 1.0 / 2.2)

	return {x, y, z, col.w}
}
@(require_results)
vector4_linear_to_srgb_f64 :: proc "contextless" (col: Vector4f64) -> Vector4f64 {
	a :: 2.51
	b :: 0.03
	c :: 2.43
	d :: 0.59
	e :: 0.14

	x := col.x
	y := col.y
	z := col.z

	x = (x * (a * x + b)) / (x * (c * x + d) + e)
	y = (y * (a * y + b)) / (y * (c * y + d) + e)
	z = (z * (a * z + b)) / (z * (c * z + d) + e)

	x = math.pow(clamp(x, 0, 1), 1.0 / 2.2)
	y = math.pow(clamp(y, 0, 1), 1.0 / 2.2)
	z = math.pow(clamp(z, 0, 1), 1.0 / 2.2)

	return {x, y, z, col.w}
}
vector4_linear_to_srgb :: proc{
	vector4_linear_to_srgb_f16,
	vector4_linear_to_srgb_f32,
	vector4_linear_to_srgb_f64,
}


@(require_results)
vector4_hsl_to_rgb_f16 :: proc "contextless" (h, s, l: f16, a: f16 = 1) -> Vector4f16 {
	@(require_results)
	hue_to_rgb :: proc "contextless" (p, q, t: f16) -> f16 {
		t := t
		if t < 0 { t += 1 }
		if t > 1 { t -= 1 }
		switch {
		case t < 1.0/6.0: return p + (q - p) * 6.0 * t
		case t < 1.0/2.0: return q
		case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
		}
		return p
	}

	r, g, b: f16
	if s == 0 {
		r = l
		g = l
		b = l
	} else {
		q := l * (1+s) if l < 0.5 else l+s - l*s
		p := 2*l - q
		r = hue_to_rgb(p, q, h + 1.0/3.0)
		g = hue_to_rgb(p, q, h)
		b = hue_to_rgb(p, q, h - 1.0/3.0)
	}
	return {r, g, b, a}
}
@(require_results)
vector4_hsl_to_rgb_f32 :: proc "contextless" (h, s, l: f32, a: f32 = 1) -> Vector4f32 {
	@(require_results)
	hue_to_rgb :: proc "contextless" (p, q, t: f32) -> f32 {
		t := t
		if t < 0 { t += 1 }
		if t > 1 { t -= 1 }
		switch {
		case t < 1.0/6.0: return p + (q - p) * 6.0 * t
		case t < 1.0/2.0: return q
		case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
		}
		return p
	}

	r, g, b: f32
	if s == 0 {
		r = l
		g = l
		b = l
	} else {
		q := l * (1+s) if l < 0.5 else l+s - l*s
		p := 2*l - q
		r = hue_to_rgb(p, q, h + 1.0/3.0)
		g = hue_to_rgb(p, q, h)
		b = hue_to_rgb(p, q, h - 1.0/3.0)
	}
	return {r, g, b, a}
}
@(require_results)
vector4_hsl_to_rgb_f64 :: proc "contextless" (h, s, l: f64, a: f64 = 1) -> Vector4f64 {
	@(require_results)
	hue_to_rgb :: proc "contextless" (p, q, t: f64) -> f64 {
		t := t
		if t < 0 { t += 1 }
		if t > 1 { t -= 1 }
		switch {
		case t < 1.0/6.0: return p + (q - p) * 6.0 * t
		case t < 1.0/2.0: return q
		case t < 2.0/3.0: return p + (q - p) * 6.0 * (2.0/3.0 - t)
		}
		return p
	}

	r, g, b: f64
	if s == 0 {
		r = l
		g = l
		b = l
	} else {
		q := l * (1+s) if l < 0.5 else l+s - l*s
		p := 2*l - q
		r = hue_to_rgb(p, q, h + 1.0/3.0)
		g = hue_to_rgb(p, q, h)
		b = hue_to_rgb(p, q, h - 1.0/3.0)
	}
	return {r, g, b, a}
}
vector4_hsl_to_rgb :: proc{
	vector4_hsl_to_rgb_f16,
	vector4_hsl_to_rgb_f32,
	vector4_hsl_to_rgb_f64,
}


@(require_results)
vector4_rgb_to_hsl_f16 :: proc "contextless" (col: Vector4f16) -> Vector4f16 {
	r := col.x
	g := col.y
	b := col.z
	a := col.w
	v_min := min(r, g, b)
	v_max := max(r, g, b)
	h, s, l: f16
	h  = 0.0
	s  = 0.0
	l  = (v_min + v_max) * 0.5

	if v_max != v_min {
		d: = v_max - v_min
		s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
		switch {
		case v_max == r:
			h = (g - b) / d + (6.0 if g < b else 0.0)
		case v_max == g:
			h = (b - r) / d + 2.0
		case v_max == b:
			h = (r - g) / d + 4.0
		}

		h *= 1.0/6.0
	}

	return {h, s, l, a}
}
@(require_results)
vector4_rgb_to_hsl_f32 :: proc "contextless" (col: Vector4f32) -> Vector4f32 {
	r := col.x
	g := col.y
	b := col.z
	a := col.w
	v_min := min(r, g, b)
	v_max := max(r, g, b)
	h, s, l: f32
	h  = 0.0
	s  = 0.0
	l  = (v_min + v_max) * 0.5

	if v_max != v_min {
		d: = v_max - v_min
		s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
		switch {
		case v_max == r:
			h = (g - b) / d + (6.0 if g < b else 0.0)
		case v_max == g:
			h = (b - r) / d + 2.0
		case v_max == b:
			h = (r - g) / d + 4.0
		}

		h *= 1.0/6.0
	}

	return {h, s, l, a}
}
@(require_results)
vector4_rgb_to_hsl_f64 :: proc "contextless" (col: Vector4f64) -> Vector4f64 {
	r := col.x
	g := col.y
	b := col.z
	a := col.w
	v_min := min(r, g, b)
	v_max := max(r, g, b)
	h, s, l: f64
	h  = 0.0
	s  = 0.0
	l  = (v_min + v_max) * 0.5

	if v_max != v_min {
		d: = v_max - v_min
		s = d / (2.0 - v_max - v_min) if l > 0.5 else d / (v_max + v_min)
		switch {
		case v_max == r:
			h = (g - b) / d + (6.0 if g < b else 0.0)
		case v_max == g:
			h = (b - r) / d + 2.0
		case v_max == b:
			h = (r - g) / d + 4.0
		}

		h *= 1.0/6.0
	}

	return {h, s, l, a}
}
vector4_rgb_to_hsl :: proc{
	vector4_rgb_to_hsl_f16,
	vector4_rgb_to_hsl_f32,
	vector4_rgb_to_hsl_f64,
}



@(require_results)
quaternion_angle_axis_f16 :: proc "contextless" (angle_radians: f16, axis: Vector3f16) -> (q: Quaternionf16) {
	t := angle_radians*0.5
	v := normalize(axis) * math.sin(t)
	q.x = v.x
	q.y = v.y
	q.z = v.z
	q.w = math.cos(t)
	return
}
@(require_results)
quaternion_angle_axis_f32 :: proc "contextless" (angle_radians: f32, axis: Vector3f32) -> (q: Quaternionf32) {
	t := angle_radians*0.5
	v := normalize(axis) * math.sin(t)
	q.x = v.x
	q.y = v.y
	q.z = v.z
	q.w = math.cos(t)
	return
}
@(require_results)
quaternion_angle_axis_f64 :: proc "contextless" (angle_radians: f64, axis: Vector3f64) -> (q: Quaternionf64) {
	t := angle_radians*0.5
	v := normalize(axis) * math.sin(t)
	q.x = v.x
	q.y = v.y
	q.z = v.z
	q.w = math.cos(t)
	return
}
quaternion_angle_axis :: proc{
	quaternion_angle_axis_f16,
	quaternion_angle_axis_f32,
	quaternion_angle_axis_f64,
}

@(require_results)
angle_from_quaternion_f16 :: proc "contextless" (q: Quaternionf16) -> f16 {
	if abs(q.w) > math.SQRT_THREE*0.5 {
		return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
	}

	return math.acos(q.w) * 2
}
@(require_results)
angle_from_quaternion_f32 :: proc "contextless" (q: Quaternionf32) -> f32 {
	if abs(q.w) > math.SQRT_THREE*0.5 {
		return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
	}

	return math.acos(q.w) * 2
}
@(require_results)
angle_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> f64 {
	if abs(q.w) > math.SQRT_THREE*0.5 {
		return math.asin(math.sqrt(q.x*q.x + q.y*q.y + q.z*q.z)) * 2
	}

	return math.acos(q.w) * 2
}
angle_from_quaternion :: proc{
	angle_from_quaternion_f16,
	angle_from_quaternion_f32,
	angle_from_quaternion_f64,
}

@(require_results)
axis_from_quaternion_f16 :: proc "contextless" (q: Quaternionf16) -> Vector3f16 {
	t1 := 1 - q.w*q.w
	if t1 <= 0 {
		return {0, 0, 1}
	}
	t2 := 1.0 / math.sqrt(t1)
	return {q.x*t2, q.y*t2, q.z*t2}
}
@(require_results)
axis_from_quaternion_f32 :: proc "contextless" (q: Quaternionf32) -> Vector3f32 {
	t1 := 1 - q.w*q.w
	if t1 <= 0 {
		return {0, 0, 1}
	}
	t2 := 1.0 / math.sqrt(t1)
	return {q.x*t2, q.y*t2, q.z*t2}
}
@(require_results)
axis_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> Vector3f64 {
	t1 := 1 - q.w*q.w
	if t1 <= 0 {
		return {0, 0, 1}
	}
	t2 := 1.0 / math.sqrt(t1)
	return {q.x*t2, q.y*t2, q.z*t2}
}
axis_from_quaternion :: proc{
	axis_from_quaternion_f16,
	axis_from_quaternion_f32,
	axis_from_quaternion_f64,
}


@(require_results)
angle_axis_from_quaternion_f16 :: proc "contextless" (q: Quaternionf16) -> (angle: f16, axis: Vector3f16) {
	angle = angle_from_quaternion(q)
	axis  = axis_from_quaternion(q)
	return
}
@(require_results)
angle_axis_from_quaternion_f32 :: proc "contextless" (q: Quaternionf32) -> (angle: f32, axis: Vector3f32) {
	angle = angle_from_quaternion(q)
	axis  = axis_from_quaternion(q)
	return
}
@(require_results)
angle_axis_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (angle: f64, axis: Vector3f64) {
	angle = angle_from_quaternion(q)
	axis  = axis_from_quaternion(q)
	return
}
angle_axis_from_quaternion :: proc {
	angle_axis_from_quaternion_f16,
	angle_axis_from_quaternion_f32,
	angle_axis_from_quaternion_f64,
}


@(require_results)
quaternion_from_forward_and_up_f16 :: proc "contextless" (forward, up: Vector3f16) -> Quaternionf16 #no_bounds_check {
	f := normalize(forward)
	s := normalize(cross(f, up))
	u := cross(s, f)
	m := Matrix3f16{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}

	tr := trace(m)

	q: Quaternionf16

	switch {
	case tr > 0:
		S := 2 * math.sqrt(1 + tr)
		q.w = 0.25 * S
		q.x = (m[1, 2] - m[2, 1]) / S
		q.y = (m[2, 0] - m[0, 2]) / S
		q.z = (m[0, 1] - m[1, 0]) / S
	case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
		S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
		q.w = (m[1, 2] - m[2, 1]) / S
		q.x = 0.25 * S
		q.y = (m[1, 0] + m[0, 1]) / S
		q.z = (m[2, 0] + m[0, 2]) / S
	case m[1, 1] > m[2, 2]:
		S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
		q.w = (m[2, 0] - m[0, 2]) / S
		q.x = (m[1, 0] + m[0, 1]) / S
		q.y = 0.25 * S
		q.z = (m[2, 1] + m[1, 2]) / S
	case:
		S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
		q.w = (m[0, 1] - m[1, 0]) / S
		q.x = (m[2, 0] - m[0, 2]) / S
		q.y = (m[2, 1] + m[1, 2]) / S
		q.z = 0.25 * S
	}

	return normalize(q)
}
@(require_results)
quaternion_from_forward_and_up_f32 :: proc "contextless" (forward, up: Vector3f32) -> Quaternionf32 #no_bounds_check {
	f := normalize(forward)
	s := normalize(cross(f, up))
	u := cross(s, f)
	m := Matrix3f32{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}

	tr := trace(m)

	q: Quaternionf32

	switch {
	case tr > 0:
		S := 2 * math.sqrt(1 + tr)
		q.w = 0.25 * S
		q.x = (m[1, 2] - m[2, 1]) / S
		q.y = (m[2, 0] - m[0, 2]) / S
		q.z = (m[0, 1] - m[1, 0]) / S
	case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
		S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
		q.w = (m[1, 2] - m[2, 1]) / S
		q.x = 0.25 * S
		q.y = (m[1, 0] + m[0, 1]) / S
		q.z = (m[2, 0] + m[0, 2]) / S
	case m[1, 1] > m[2, 2]:
		S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
		q.w = (m[2, 0] - m[0, 2]) / S
		q.x = (m[1, 0] + m[0, 1]) / S
		q.y = 0.25 * S
		q.z = (m[2, 1] + m[1, 2]) / S
	case:
		S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
		q.w = (m[0, 1] - m[1, 0]) / S
		q.x = (m[2, 0] - m[0, 2]) / S
		q.y = (m[2, 1] + m[1, 2]) / S
		q.z = 0.25 * S
	}

	return normalize(q)
}
@(require_results)
quaternion_from_forward_and_up_f64 :: proc "contextless" (forward, up: Vector3f64) -> Quaternionf64 #no_bounds_check {
	f := normalize(forward)
	s := normalize(cross(f, up))
	u := cross(s, f)
	m := Matrix3f64{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}

	tr := trace(m)

	q: Quaternionf64

	switch {
	case tr > 0:
		S := 2 * math.sqrt(1 + tr)
		q.w = 0.25 * S
		q.x = (m[1, 2] - m[2, 1]) / S
		q.y = (m[2, 0] - m[0, 2]) / S
		q.z = (m[0, 1] - m[1, 0]) / S
	case (m[0, 0] > m[1, 1]) && (m[0, 0] > m[2, 2]):
		S := 2 * math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2])
		q.w = (m[1, 2] - m[2, 1]) / S
		q.x = 0.25 * S
		q.y = (m[1, 0] + m[0, 1]) / S
		q.z = (m[2, 0] + m[0, 2]) / S
	case m[1, 1] > m[2, 2]:
		S := 2 * math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2])
		q.w = (m[2, 0] - m[0, 2]) / S
		q.x = (m[1, 0] + m[0, 1]) / S
		q.y = 0.25 * S
		q.z = (m[2, 1] + m[1, 2]) / S
	case:
		S := 2 * math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1])
		q.w = (m[0, 1] - m[1, 0]) / S
		q.x = (m[2, 0] - m[0, 2]) / S
		q.y = (m[2, 1] + m[1, 2]) / S
		q.z = 0.25 * S
	}

	return normalize(q)
}
quaternion_from_forward_and_up :: proc{
	quaternion_from_forward_and_up_f16,
	quaternion_from_forward_and_up_f32,
	quaternion_from_forward_and_up_f64,
}

@(require_results)
quaternion_look_at_f16 :: proc "contextless" (eye, centre: Vector3f16, up: Vector3f16) -> Quaternionf16 {
	return quaternion_from_matrix3(matrix3_look_at(eye, centre, up))
}
@(require_results)
quaternion_look_at_f32 :: proc "contextless" (eye, centre: Vector3f32, up: Vector3f32) -> Quaternionf32 {
	return quaternion_from_matrix3(matrix3_look_at(eye, centre, up))
}
@(require_results)
quaternion_look_at_f64 :: proc "contextless" (eye, centre: Vector3f64, up: Vector3f64) -> Quaternionf64 {
	return quaternion_from_matrix3(matrix3_look_at(eye, centre, up))
}
quaternion_look_at :: proc{
	quaternion_look_at_f16,
	quaternion_look_at_f32,
	quaternion_look_at_f64,
}



@(require_results)
quaternion_nlerp_f16 :: proc "contextless" (a, b: Quaternionf16, t: f16) -> (c: Quaternionf16) {
	c.x = a.x + (b.x-a.x)*t
	c.y = a.y + (b.y-a.y)*t
	c.z = a.z + (b.z-a.z)*t
	c.w = a.w + (b.w-a.w)*t
	return normalize(c)
}
@(require_results)
quaternion_nlerp_f32 :: proc "contextless" (a, b: Quaternionf32, t: f32) -> (c: Quaternionf32) {
	c.x = a.x + (b.x-a.x)*t
	c.y = a.y + (b.y-a.y)*t
	c.z = a.z + (b.z-a.z)*t
	c.w = a.w + (b.w-a.w)*t
	return normalize(c)
}
@(require_results)
quaternion_nlerp_f64 :: proc "contextless" (a, b: Quaternionf64, t: f64) -> (c: Quaternionf64) {
	c.x = a.x + (b.x-a.x)*t
	c.y = a.y + (b.y-a.y)*t
	c.z = a.z + (b.z-a.z)*t
	c.w = a.w + (b.w-a.w)*t
	return normalize(c)
}
quaternion_nlerp :: proc{
	quaternion_nlerp_f16,
	quaternion_nlerp_f32,
	quaternion_nlerp_f64,
}


@(require_results)
quaternion_slerp_f16 :: proc "contextless" (x, y: Quaternionf16, t: f16) -> (q: Quaternionf16) {
	a, b := x, y
	cos_angle := dot(a, b)
	if cos_angle < 0 {
		b = -b
		cos_angle = -cos_angle
	}
	if cos_angle > 1 - F32_EPSILON {
		q.x = a.x + (b.x-a.x)*t
		q.y = a.y + (b.y-a.y)*t
		q.z = a.z + (b.z-a.z)*t
		q.w = a.w + (b.w-a.w)*t
		return
	}

	angle := math.acos(cos_angle)
	sin_angle := math.sin(angle)
	factor_a := math.sin((1-t) * angle) / sin_angle
	factor_b := math.sin(t * angle)     / sin_angle


	q.x = factor_a * a.x + factor_b * b.x
	q.y = factor_a * a.y + factor_b * b.y
	q.z = factor_a * a.z + factor_b * b.z
	q.w = factor_a * a.w + factor_b * b.w
	return
}
@(require_results)
quaternion_slerp_f32 :: proc "contextless" (x, y: Quaternionf32, t: f32) -> (q: Quaternionf32) {
	a, b := x, y
	cos_angle := dot(a, b)
	if cos_angle < 0 {
		b = -b
		cos_angle = -cos_angle
	}
	if cos_angle > 1 - F32_EPSILON {
		q.x = a.x + (b.x-a.x)*t
		q.y = a.y + (b.y-a.y)*t
		q.z = a.z + (b.z-a.z)*t
		q.w = a.w + (b.w-a.w)*t
		return
	}

	angle := math.acos(cos_angle)
	sin_angle := math.sin(angle)
	factor_a := math.sin((1-t) * angle) / sin_angle
	factor_b := math.sin(t * angle)     / sin_angle


	q.x = factor_a * a.x + factor_b * b.x
	q.y = factor_a * a.y + factor_b * b.y
	q.z = factor_a * a.z + factor_b * b.z
	q.w = factor_a * a.w + factor_b * b.w
	return
}
@(require_results)
quaternion_slerp_f64 :: proc "contextless" (x, y: Quaternionf64, t: f64) -> (q: Quaternionf64) {
	a, b := x, y
	cos_angle := dot(a, b)
	if cos_angle < 0 {
		b = -b
		cos_angle = -cos_angle
	}
	if cos_angle > 1 - F64_EPSILON {
		q.x = a.x + (b.x-a.x)*t
		q.y = a.y + (b.y-a.y)*t
		q.z = a.z + (b.z-a.z)*t
		q.w = a.w + (b.w-a.w)*t
		return
	}

	angle := math.acos(cos_angle)
	sin_angle := math.sin(angle)
	factor_a := math.sin((1-t) * angle) / sin_angle
	factor_b := math.sin(t * angle)     / sin_angle


	q.x = factor_a * a.x + factor_b * b.x
	q.y = factor_a * a.y + factor_b * b.y
	q.z = factor_a * a.z + factor_b * b.z
	q.w = factor_a * a.w + factor_b * b.w
	return
}
quaternion_slerp :: proc{
	quaternion_slerp_f16,
	quaternion_slerp_f32,
	quaternion_slerp_f64,
}


@(require_results)
quaternion_squad_f16 :: proc "contextless" (q1, q2, s1, s2: Quaternionf16, h: f16) -> Quaternionf16 {
	slerp :: quaternion_slerp
	return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}
@(require_results)
quaternion_squad_f32 :: proc "contextless" (q1, q2, s1, s2: Quaternionf32, h: f32) -> Quaternionf32 {
	slerp :: quaternion_slerp
	return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}
@(require_results)
quaternion_squad_f64 :: proc "contextless" (q1, q2, s1, s2: Quaternionf64, h: f64) -> Quaternionf64 {
	slerp :: quaternion_slerp
	return slerp(slerp(q1, q2, h), slerp(s1, s2, h), 2 * (1 - h) * h)
}
quaternion_squad :: proc{
	quaternion_squad_f16,
	quaternion_squad_f32,
	quaternion_squad_f64,
}


@(require_results)
quaternion_from_matrix4_f16 :: proc "contextless" (m: Matrix4f16) -> (q: Quaternionf16) #no_bounds_check {
	m3: Matrix3f16 = ---
	m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return quaternion_from_matrix3(m3)
}
@(require_results)
quaternion_from_matrix4_f32 :: proc "contextless" (m: Matrix4f32) -> (q: Quaternionf32) #no_bounds_check {
	m3: Matrix3f32 = ---
	m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return quaternion_from_matrix3(m3)
}
@(require_results)
quaternion_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (q: Quaternionf64) #no_bounds_check {
	m3: Matrix3f64 = ---
	m3[0, 0], m3[1, 0], m3[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	m3[0, 1], m3[1, 1], m3[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	m3[0, 2], m3[1, 2], m3[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return quaternion_from_matrix3(m3)
}
quaternion_from_matrix4 :: proc{
	quaternion_from_matrix4_f16,
	quaternion_from_matrix4_f32,
	quaternion_from_matrix4_f64,
}


@(require_results)
quaternion_from_matrix3_f16 :: proc "contextless" (m: Matrix3f16) -> (q: Quaternionf16) #no_bounds_check {
	four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
	four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
	four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
	four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

	biggest_index := 0
	four_biggest_squared_minus_1 := four_w_squared_minus_1
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1
		biggest_index = 1
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1
		biggest_index = 2
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1
		biggest_index = 3
	}

	biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
	mult := 0.25 / biggest_val

	q = 1
	switch biggest_index {
	case 0:
		q.w = biggest_val
		q.x = (m[2, 1] - m[1, 2]) * mult
		q.y = (m[0, 2] - m[2, 0]) * mult
		q.z = (m[1, 0] - m[0, 1]) * mult
	case 1:
		q.w = (m[2, 1] - m[1, 2]) * mult
		q.x = biggest_val
		q.y = (m[1, 0] + m[0, 1]) * mult
		q.z = (m[0, 2] + m[2, 0]) * mult
	case 2:
		q.w = (m[0, 2] - m[2, 0]) * mult
		q.x = (m[1, 0] + m[0, 1]) * mult
		q.y = biggest_val
		q.z = (m[2, 1] + m[1, 2]) * mult
	case 3:
		q.w = (m[1, 0] - m[0, 1]) * mult
		q.x = (m[0, 2] + m[2, 0]) * mult
		q.y = (m[2, 1] + m[1, 2]) * mult
		q.z = biggest_val
	}
	return
}
@(require_results)
quaternion_from_matrix3_f32 :: proc "contextless" (m: Matrix3f32) -> (q: Quaternionf32) #no_bounds_check {
	four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
	four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
	four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
	four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

	biggest_index := 0
	four_biggest_squared_minus_1 := four_w_squared_minus_1
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1
		biggest_index = 1
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1
		biggest_index = 2
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1
		biggest_index = 3
	}

	biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
	mult := 0.25 / biggest_val

	q = 1
	switch biggest_index {
	case 0:
		q.w = biggest_val
		q.x = (m[2, 1] - m[1, 2]) * mult
		q.y = (m[0, 2] - m[2, 0]) * mult
		q.z = (m[1, 0] - m[0, 1]) * mult
	case 1:
		q.w = (m[2, 1] - m[1, 2]) * mult
		q.x = biggest_val
		q.y = (m[1, 0] + m[0, 1]) * mult
		q.z = (m[0, 2] + m[2, 0]) * mult
	case 2:
		q.w = (m[0, 2] - m[2, 0]) * mult
		q.x = (m[1, 0] + m[0, 1]) * mult
		q.y = biggest_val
		q.z = (m[2, 1] + m[1, 2]) * mult
	case 3:
		q.w = (m[1, 0] - m[0, 1]) * mult
		q.x = (m[0, 2] + m[2, 0]) * mult
		q.y = (m[2, 1] + m[1, 2]) * mult
		q.z = biggest_val
	}
	return
}
@(require_results)
quaternion_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (q: Quaternionf64) #no_bounds_check {
	four_x_squared_minus_1 := m[0, 0] - m[1, 1] - m[2, 2]
	four_y_squared_minus_1 := m[1, 1] - m[0, 0] - m[2, 2]
	four_z_squared_minus_1 := m[2, 2] - m[0, 0] - m[1, 1]
	four_w_squared_minus_1 := m[0, 0] + m[1, 1] + m[2, 2]

	biggest_index := 0
	four_biggest_squared_minus_1 := four_w_squared_minus_1
	if four_x_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_x_squared_minus_1
		biggest_index = 1
	}
	if four_y_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_y_squared_minus_1
		biggest_index = 2
	}
	if four_z_squared_minus_1 > four_biggest_squared_minus_1 {
		four_biggest_squared_minus_1 = four_z_squared_minus_1
		biggest_index = 3
	}

	biggest_val := math.sqrt(four_biggest_squared_minus_1 + 1) * 0.5
	mult := 0.25 / biggest_val

	q = 1
	switch biggest_index {
	case 0:
		q.w = biggest_val
		q.x = (m[2, 1] - m[1, 2]) * mult
		q.y = (m[0, 2] - m[2, 0]) * mult
		q.z = (m[1, 0] - m[0, 1]) * mult
	case 1:
		q.w = (m[2, 1] - m[1, 2]) * mult
		q.x = biggest_val
		q.y = (m[1, 0] + m[0, 1]) * mult
		q.z = (m[0, 2] + m[2, 0]) * mult
	case 2:
		q.w = (m[0, 2] - m[2, 0]) * mult
		q.x = (m[1, 0] + m[0, 1]) * mult
		q.y = biggest_val
		q.z = (m[2, 1] + m[1, 2]) * mult
	case 3:
		q.w = (m[1, 0] - m[0, 1]) * mult
		q.x = (m[0, 2] + m[2, 0]) * mult
		q.y = (m[2, 1] + m[1, 2]) * mult
		q.z = biggest_val
	}
	return
}
quaternion_from_matrix3 :: proc{
	quaternion_from_matrix3_f16,
	quaternion_from_matrix3_f32,
	quaternion_from_matrix3_f64,
}


@(require_results)
quaternion_between_two_vector3_f16 :: proc "contextless" (from, to: Vector3f16) -> (q: Quaternionf16) {
	x := normalize(from)
	y := normalize(to)

	cos_theta := dot(x, y)
	if abs(cos_theta + 1) < 2*F32_EPSILON {
		v := vector3_orthogonal(x)
		q.x = v.x
		q.y = v.y
		q.z = v.z
		q.w = 0
		return
	}
	v := cross(x, y)
	w := cos_theta + 1
	q.w = w
	q.x = v.x
	q.y = v.y
	q.z = v.z
	return normalize(q)
}
@(require_results)
quaternion_between_two_vector3_f32 :: proc "contextless" (from, to: Vector3f32) -> (q: Quaternionf32) {
	x := normalize(from)
	y := normalize(to)

	cos_theta := dot(x, y)
	if abs(cos_theta + 1) < 2*F32_EPSILON {
		v := vector3_orthogonal(x)
		q.x = v.x
		q.y = v.y
		q.z = v.z
		q.w = 0
		return
	}
	v := cross(x, y)
	w := cos_theta + 1
	q.w = w
	q.x = v.x
	q.y = v.y
	q.z = v.z
	return normalize(q)
}
@(require_results)
quaternion_between_two_vector3_f64 :: proc "contextless" (from, to: Vector3f64) -> (q: Quaternionf64) {
	x := normalize(from)
	y := normalize(to)

	cos_theta := dot(x, y)
	if abs(cos_theta + 1) < 2*F64_EPSILON {
		v := vector3_orthogonal(x)
		q.x = v.x
		q.y = v.y
		q.z = v.z
		q.w = 0
		return
	}
	v := cross(x, y)
	w := cos_theta + 1
	q.w = w
	q.x = v.x
	q.y = v.y
	q.z = v.z
	return normalize(q)
}
quaternion_between_two_vector3 :: proc{
	quaternion_between_two_vector3_f16,
	quaternion_between_two_vector3_f32,
	quaternion_between_two_vector3_f64,
}


@(require_results)
matrix2_inverse_transpose_f16 :: proc "contextless" (m: Matrix2f16) -> (c: Matrix2f16) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
@(require_results)
matrix2_inverse_transpose_f32 :: proc "contextless" (m: Matrix2f32) -> (c: Matrix2f32) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
@(require_results)
matrix2_inverse_transpose_f64 :: proc "contextless" (m: Matrix2f64) -> (c: Matrix2f64) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
matrix2_inverse_transpose :: proc{
	matrix2_inverse_transpose_f16,
	matrix2_inverse_transpose_f32,
	matrix2_inverse_transpose_f64,
}


@(require_results)
matrix2_determinant_f16 :: proc "contextless" (m: Matrix2f16) -> f16 #no_bounds_check {
	return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
@(require_results)
matrix2_determinant_f32 :: proc "contextless" (m: Matrix2f32) -> f32 #no_bounds_check {
	return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
@(require_results)
matrix2_determinant_f64 :: proc "contextless" (m: Matrix2f64) -> f64 #no_bounds_check {
	return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
matrix2_determinant :: proc{
	matrix2_determinant_f16,
	matrix2_determinant_f32,
	matrix2_determinant_f64,
}


@(require_results)
matrix2_inverse_f16 :: proc "contextless" (m: Matrix2f16) -> (c: Matrix2f16) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
@(require_results)
matrix2_inverse_f32 :: proc "contextless" (m: Matrix2f32) -> (c: Matrix2f32) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
@(require_results)
matrix2_inverse_f64 :: proc "contextless" (m: Matrix2f64) -> (c: Matrix2f64) #no_bounds_check {
	d := m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
	id := 1.0/d
	c[0, 0] = +m[1, 1] * id
	c[0, 1] = -m[0, 1] * id
	c[1, 0] = -m[1, 0] * id
	c[1, 1] = +m[0, 0] * id
	return c
}
matrix2_inverse :: proc{
	matrix2_inverse_f16,
	matrix2_inverse_f32,
	matrix2_inverse_f64,
}


@(require_results)
matrix2_adjoint_f16 :: proc "contextless" (m: Matrix2f16) -> (c: Matrix2f16) #no_bounds_check {
	c[0, 0] = +m[1, 1]
	c[1, 0] = -m[0, 1]
	c[0, 1] = -m[1, 0]
	c[1, 1] = +m[0, 0]
	return c
}
@(require_results)
matrix2_adjoint_f32 :: proc "contextless" (m: Matrix2f32) -> (c: Matrix2f32) #no_bounds_check {
	c[0, 0] = +m[1, 1]
	c[1, 0] = -m[0, 1]
	c[0, 1] = -m[1, 0]
	c[1, 1] = +m[0, 0]
	return c
}
@(require_results)
matrix2_adjoint_f64 :: proc "contextless" (m: Matrix2f64) -> (c: Matrix2f64) #no_bounds_check {
	c[0, 0] = +m[1, 1]
	c[1, 0] = -m[0, 1]
	c[0, 1] = -m[1, 0]
	c[1, 1] = +m[0, 0]
	return c
}
matrix2_adjoint :: proc{
	matrix2_adjoint_f16,
	matrix2_adjoint_f32,
	matrix2_adjoint_f64,
}


@(require_results)
matrix2_rotate_f16 :: proc "contextless" (angle_radians: f16) -> Matrix2f16 {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	return Matrix2f16{
		c, -s,
		s,  c,
	}
}
@(require_results)
matrix2_rotate_f32 :: proc "contextless" (angle_radians: f32) -> Matrix2f32 {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	return Matrix2f32{
		c, -s,
		s,  c,
	}
}
@(require_results)
matrix2_rotate_f64 :: proc "contextless" (angle_radians: f64) -> Matrix2f64 {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	return Matrix2f64{
		c, -s,
		s,  c,
	}
}
matrix2_rotate :: proc{
	matrix2_rotate_f16,
	matrix2_rotate_f32,
	matrix2_rotate_f64,
}


@(require_results)
matrix3_from_quaternion_f16 :: proc "contextless" (q: Quaternionf16) -> (m: Matrix3f16) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)
	return m
}
@(require_results)
matrix3_from_quaternion_f32 :: proc "contextless" (q: Quaternionf32) -> (m: Matrix3f32) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)
	return m
}
@(require_results)
matrix3_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (m: Matrix3f64) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)
	return m
}
matrix3_from_quaternion :: proc{
	matrix3_from_quaternion_f16,
	matrix3_from_quaternion_f32,
	matrix3_from_quaternion_f64,
}


@(require_results)
matrix3_inverse_f16 :: proc "contextless" (m: Matrix3f16) -> Matrix3f16 {
	return transpose(matrix3_inverse_transpose(m))
}
@(require_results)
matrix3_inverse_f32 :: proc "contextless" (m: Matrix3f32) -> Matrix3f32 {
	return transpose(matrix3_inverse_transpose(m))
}
@(require_results)
matrix3_inverse_f64 :: proc "contextless" (m: Matrix3f64) -> Matrix3f64 {
	return transpose(matrix3_inverse_transpose(m))
}
matrix3_inverse :: proc{
	matrix3_inverse_f16,
	matrix3_inverse_f32,
	matrix3_inverse_f64,
}


@(require_results)
matrix3_determinant_f16 :: proc "contextless" (m: Matrix3f16) -> f16 #no_bounds_check {
	a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
	b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
	c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
	return a + b + c
}
@(require_results)
matrix3_determinant_f32 :: proc "contextless" (m: Matrix3f32) -> f32 #no_bounds_check {
	a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
	b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
	c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
	return a + b + c
}
@(require_results)
matrix3_determinant_f64 :: proc "contextless" (m: Matrix3f64) -> f64 #no_bounds_check {
	a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
	b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
	c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
	return a + b + c
}
matrix3_determinant :: proc{
	matrix3_determinant_f16,
	matrix3_determinant_f32,
	matrix3_determinant_f64,
}


@(require_results)
matrix3_adjoint_f16 :: proc "contextless" (m: Matrix3f16) -> (adjoint: Matrix3f16) #no_bounds_check {
	adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
	adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
	adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
	adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
	adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
	adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
	adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
	adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
	adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
	return adjoint
}
@(require_results)
matrix3_adjoint_f32 :: proc "contextless" (m: Matrix3f32) -> (adjoint: Matrix3f32) #no_bounds_check {
	adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
	adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
	adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
	adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
	adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
	adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
	adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
	adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
	adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
	return adjoint
}
@(require_results)
matrix3_adjoint_f64 :: proc "contextless" (m: Matrix3f64) -> (adjoint: Matrix3f64) #no_bounds_check {
	adjoint[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
	adjoint[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
	adjoint[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
	adjoint[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
	adjoint[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
	adjoint[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
	adjoint[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
	adjoint[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
	adjoint[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
	return adjoint
}
matrix3_adjoint :: proc{
	matrix3_adjoint_f16,
	matrix3_adjoint_f32,
	matrix3_adjoint_f64,
}



@(require_results)
matrix3_inverse_transpose_f16 :: proc "contextless" (m: Matrix3f16) -> (p: Matrix3f16) {
	return inverse_transpose(m)
}
@(require_results)
matrix3_inverse_transpose_f32 :: proc "contextless" (m: Matrix3f32) -> (p: Matrix3f32) {
	return inverse_transpose(m)
}
@(require_results)
matrix3_inverse_transpose_f64 :: proc "contextless" (m: Matrix3f64) -> (p: Matrix3f64) {
	return inverse_transpose(m)
}
matrix3_inverse_transpose :: proc{
	matrix3_inverse_transpose_f16,
	matrix3_inverse_transpose_f32,
	matrix3_inverse_transpose_f64,
}


@(require_results)
matrix3_scale_f16 :: proc "contextless" (s: Vector3f16) -> (m: Matrix3f16) #no_bounds_check {
	m[0, 0] = s[0]
	m[1, 1] = s[1]
	m[2, 2] = s[2]
	return m
}
@(require_results)
matrix3_scale_f32 :: proc "contextless" (s: Vector3f32) -> (m: Matrix3f32) #no_bounds_check {
	m[0, 0] = s[0]
	m[1, 1] = s[1]
	m[2, 2] = s[2]
	return m
}
@(require_results)
matrix3_scale_f64 :: proc "contextless" (s: Vector3f64) -> (m: Matrix3f64) #no_bounds_check {
	m[0, 0] = s[0]
	m[1, 1] = s[1]
	m[2, 2] = s[2]
	return m
}
matrix3_scale :: proc{
	matrix3_scale_f16,
	matrix3_scale_f32,
	matrix3_scale_f64,
}


@(require_results)
matrix3_rotate_f16 :: proc "contextless" (angle_radians: f16, v: Vector3f16) -> (rot: Matrix3f16) #no_bounds_check {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot[0, 0] = c + t[0]*a[0]
	rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
	rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

	rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
	rot[1, 1] = c + t[1]*a[1]
	rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

	rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
	rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
	rot[2, 2] = c + t[2]*a[2]

	return rot
}
@(require_results)
matrix3_rotate_f32 :: proc "contextless" (angle_radians: f32, v: Vector3f32) -> (rot: Matrix3f32) #no_bounds_check {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot[0, 0] = c + t[0]*a[0]
	rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
	rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

	rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
	rot[1, 1] = c + t[1]*a[1]
	rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

	rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
	rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
	rot[2, 2] = c + t[2]*a[2]

	return rot
}
@(require_results)
matrix3_rotate_f64 :: proc "contextless" (angle_radians: f64, v: Vector3f64) -> (rot: Matrix3f64) {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot[0, 0] = c + t[0]*a[0]
	rot[1, 0] = 0 + t[0]*a[1] + s*a[2]
	rot[2, 0] = 0 + t[0]*a[2] - s*a[1]

	rot[0, 1] = 0 + t[1]*a[0] - s*a[2]
	rot[1, 1] = c + t[1]*a[1]
	rot[2, 1] = 0 + t[1]*a[2] + s*a[0]

	rot[0, 2] = 0 + t[2]*a[0] + s*a[1]
	rot[1, 2] = 0 + t[2]*a[1] - s*a[0]
	rot[2, 2] = c + t[2]*a[2]

	return rot
}
matrix3_rotate :: proc{
	matrix3_rotate_f16,
	matrix3_rotate_f32,
	matrix3_rotate_f64,
}


@(require_results)
matrix3_look_at_f16 :: proc "contextless" (eye, centre, up: Vector3f16) -> Matrix3f16 {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)
	return Matrix3f16{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}
}
@(require_results)
matrix3_look_at_f32 :: proc "contextless" (eye, centre, up: Vector3f32) -> Matrix3f32 {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)
	return Matrix3f32{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}
}
@(require_results)
matrix3_look_at_f64 :: proc "contextless" (eye, centre, up: Vector3f64) -> Matrix3f64 {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)
	return Matrix3f64{
		+s.x, +s.y, +s.z,
		+u.x, +u.y, +u.z,
		-f.x, -f.y, -f.z,
	}
}
matrix3_look_at :: proc{
	matrix3_look_at_f16,
	matrix3_look_at_f32,
	matrix3_look_at_f64,
}


@(require_results)
matrix4_from_quaternion_f16 :: proc "contextless" (q: Quaternionf16) -> (m: Matrix4f16) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)

	m[3, 3] = 1

	return m
}
@(require_results)
matrix4_from_quaternion_f32 :: proc "contextless" (q: Quaternionf32) -> (m: Matrix4f32) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)

	m[3, 3] = 1

	return m
}
@(require_results)
matrix4_from_quaternion_f64 :: proc "contextless" (q: Quaternionf64) -> (m: Matrix4f64) #no_bounds_check {
	qxx := q.x * q.x
	qyy := q.y * q.y
	qzz := q.z * q.z
	qxz := q.x * q.z
	qxy := q.x * q.y
	qyz := q.y * q.z
	qwx := q.w * q.x
	qwy := q.w * q.y
	qwz := q.w * q.z

	m[0, 0] = 1 - 2 * (qyy + qzz)
	m[1, 0] = 2 * (qxy + qwz)
	m[2, 0] = 2 * (qxz - qwy)

	m[0, 1] = 2 * (qxy - qwz)
	m[1, 1] = 1 - 2 * (qxx + qzz)
	m[2, 1] = 2 * (qyz + qwx)

	m[0, 2] = 2 * (qxz + qwy)
	m[1, 2] = 2 * (qyz - qwx)
	m[2, 2] = 1 - 2 * (qxx + qyy)

	m[3, 3] = 1

	return m
}
matrix4_from_quaternion :: proc{
	matrix4_from_quaternion_f16,
	matrix4_from_quaternion_f32,
	matrix4_from_quaternion_f64,
}


@(require_results)
matrix4_from_trs_f16 :: proc "contextless" (t: Vector3f16, r: Quaternionf16, s: Vector3f16) -> Matrix4f16 {
	translation := matrix4_translate(t)
	rotation := matrix4_from_quaternion(r)
	scale := matrix4_scale(s)
	return mul(translation, mul(rotation, scale))
}
@(require_results)
matrix4_from_trs_f32 :: proc "contextless" (t: Vector3f32, r: Quaternionf32, s: Vector3f32) -> Matrix4f32 {
	translation := matrix4_translate(t)
	rotation := matrix4_from_quaternion(r)
	scale := matrix4_scale(s)
	return mul(translation, mul(rotation, scale))
}
@(require_results)
matrix4_from_trs_f64 :: proc "contextless" (t: Vector3f64, r: Quaternionf64, s: Vector3f64) -> Matrix4f64 {
	translation := matrix4_translate(t)
	rotation := matrix4_from_quaternion(r)
	scale := matrix4_scale(s)
	return mul(translation, mul(rotation, scale))
}
matrix4_from_trs :: proc{
	matrix4_from_trs_f16,
	matrix4_from_trs_f32,
	matrix4_from_trs_f64,
}



@(require_results)
matrix4_inverse_f16 :: proc "contextless" (m: Matrix4f16) -> Matrix4f16 {
	return transpose(matrix4_inverse_transpose(m))
}
@(require_results)
matrix4_inverse_f32 :: proc "contextless" (m: Matrix4f32) -> Matrix4f32 {
	return transpose(matrix4_inverse_transpose(m))
}
@(require_results)
matrix4_inverse_f64 :: proc "contextless" (m: Matrix4f64) -> Matrix4f64 {
	return transpose(matrix4_inverse_transpose(m))
}
matrix4_inverse :: proc{
	matrix4_inverse_f16,
	matrix4_inverse_f32,
	matrix4_inverse_f64,
}


@(require_results)
matrix4_minor_f16 :: proc "contextless" (m: Matrix4f16, c, r: int) -> f16 #no_bounds_check {
	cut_down: Matrix3f16
	for i in 0..<3 {
		col := i if i < c else i+1
		for j in 0..<3 {
			row := j if j < r else j+1
			cut_down[i][j] = m[col][row]
		}
	}
	return matrix3_determinant(cut_down)
}
@(require_results)
matrix4_minor_f32 :: proc "contextless" (m: Matrix4f32, c, r: int) -> f32 #no_bounds_check {
	cut_down: Matrix3f32
	for i in 0..<3 {
		col := i if i < c else i+1
		for j in 0..<3 {
			row := j if j < r else j+1
			cut_down[i][j] = m[col][row]
		}
	}
	return matrix3_determinant(cut_down)
}
@(require_results)
matrix4_minor_f64 :: proc "contextless" (m: Matrix4f64, c, r: int) -> f64 #no_bounds_check {
	cut_down: Matrix3f64
	for i in 0..<3 {
		col := i if i < c else i+1
		for j in 0..<3 {
			row := j if j < r else j+1
			cut_down[i][j] = m[col][row]
		}
	}
	return matrix3_determinant(cut_down)
}
matrix4_minor :: proc{
	matrix4_minor_f16,
	matrix4_minor_f32,
	matrix4_minor_f64,
}


@(require_results)
matrix4_cofactor_f16 :: proc "contextless" (m: Matrix4f16, c, r: int) -> f16 {
	sign, minor: f16
	sign = 1 if (c + r) % 2 == 0 else -1
	minor = matrix4_minor(m, c, r)
	return sign * minor
}
@(require_results)
matrix4_cofactor_f32 :: proc "contextless" (m: Matrix4f32, c, r: int) -> f32 {
	sign, minor: f32
	sign = 1 if (c + r) % 2 == 0 else -1
	minor = matrix4_minor(m, c, r)
	return sign * minor
}
@(require_results)
matrix4_cofactor_f64 :: proc "contextless" (m: Matrix4f64, c, r: int) -> f64 {
	sign, minor: f64
	sign = 1 if (c + r) % 2 == 0 else -1
	minor = matrix4_minor(m, c, r)
	return sign * minor
}
matrix4_cofactor :: proc{
	matrix4_cofactor_f16,
	matrix4_cofactor_f32,
	matrix4_cofactor_f64,
}


@(require_results)
matrix4_adjoint_f16 :: proc "contextless" (m: Matrix4f16) -> (adjoint: Matrix4f16) #no_bounds_check {
	for i in 0..<4 {
		for j in 0..<4 {
			adjoint[i][j] = matrix4_cofactor(m, i, j)
		}
	}
	return
}
@(require_results)
matrix4_adjoint_f32 :: proc "contextless" (m: Matrix4f32) -> (adjoint: Matrix4f32) #no_bounds_check {
	for i in 0..<4 {
		for j in 0..<4 {
			adjoint[i][j] = matrix4_cofactor(m, i, j)
		}
	}
	return
}
@(require_results)
matrix4_adjoint_f64 :: proc "contextless" (m: Matrix4f64) -> (adjoint: Matrix4f64) #no_bounds_check {
	for i in 0..<4 {
		for j in 0..<4 {
			adjoint[i][j] = matrix4_cofactor(m, i, j)
		}
	}
	return
}
matrix4_adjoint :: proc{
	matrix4_adjoint_f16,
	matrix4_adjoint_f32,
	matrix4_adjoint_f64,
}


@(require_results)
matrix4_determinant_f16 :: proc "contextless" (m: Matrix4f16) -> (determinant: f16) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	return
}
@(require_results)
matrix4_determinant_f32 :: proc "contextless" (m: Matrix4f32) -> (determinant: f32) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	return
}
@(require_results)
matrix4_determinant_f64 :: proc "contextless" (m: Matrix4f64) -> (determinant: f64) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	return
}
matrix4_determinant :: proc{
	matrix4_determinant_f16,
	matrix4_determinant_f32,
	matrix4_determinant_f64,
}


@(require_results)
matrix4_inverse_transpose_f16 :: proc "contextless" (m: Matrix4f16) -> (inverse_transpose: Matrix4f16) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	determinant: f16 = 0
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	inv_determinant := 1.0 / determinant
	for i in 0..<4 {
		for j in 0..<4 {
			inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
		}
	}
	return
}
@(require_results)
matrix4_inverse_transpose_f32 :: proc "contextless" (m: Matrix4f32) -> (inverse_transpose: Matrix4f32) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	determinant: f32 = 0
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	inv_determinant := 1.0 / determinant
	for i in 0..<4 {
		for j in 0..<4 {
			inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
		}
	}
	return
}
@(require_results)
matrix4_inverse_transpose_f64 :: proc "contextless" (m: Matrix4f64) -> (inverse_transpose: Matrix4f64) #no_bounds_check {
	adjoint := matrix4_adjoint(m)
	determinant: f64 = 0
	for i in 0..<4 {
		determinant += m[i][0] * adjoint[i][0]
	}
	inv_determinant := 1.0 / determinant
	for i in 0..<4 {
		for j in 0..<4 {
			inverse_transpose[i][j] = adjoint[i][j] * inv_determinant
		}
	}
	return
}
matrix4_inverse_transpose :: proc{
	matrix4_inverse_transpose_f16,
	matrix4_inverse_transpose_f32,
	matrix4_inverse_transpose_f64,
}


@(require_results)
matrix4_translate_f16 :: proc "contextless" (v: Vector3f16) -> Matrix4f16 #no_bounds_check {
	m := MATRIX4F16_IDENTITY
	m[3][0] = v[0]
	m[3][1] = v[1]
	m[3][2] = v[2]
	return m
}
@(require_results)
matrix4_translate_f32 :: proc "contextless" (v: Vector3f32) -> Matrix4f32 #no_bounds_check {
	m := MATRIX4F32_IDENTITY
	m[3][0] = v[0]
	m[3][1] = v[1]
	m[3][2] = v[2]
	return m
}
@(require_results)
matrix4_translate_f64 :: proc "contextless" (v: Vector3f64) -> Matrix4f64 #no_bounds_check {
	m := MATRIX4F64_IDENTITY
	m[3][0] = v[0]
	m[3][1] = v[1]
	m[3][2] = v[2]
	return m
}
matrix4_translate :: proc{
	matrix4_translate_f16,
	matrix4_translate_f32,
	matrix4_translate_f64,
}


@(require_results)
matrix4_rotate_f16 :: proc "contextless" (angle_radians: f16, v: Vector3f16) -> Matrix4f16 #no_bounds_check {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot := MATRIX4F16_IDENTITY

	rot[0][0] = c + t[0]*a[0]
	rot[0][1] = 0 + t[0]*a[1] + s*a[2]
	rot[0][2] = 0 + t[0]*a[2] - s*a[1]
	rot[0][3] = 0

	rot[1][0] = 0 + t[1]*a[0] - s*a[2]
	rot[1][1] = c + t[1]*a[1]
	rot[1][2] = 0 + t[1]*a[2] + s*a[0]
	rot[1][3] = 0

	rot[2][0] = 0 + t[2]*a[0] + s*a[1]
	rot[2][1] = 0 + t[2]*a[1] - s*a[0]
	rot[2][2] = c + t[2]*a[2]
	rot[2][3] = 0

	return rot
}
@(require_results)
matrix4_rotate_f32 :: proc "contextless" (angle_radians: f32, v: Vector3f32) -> Matrix4f32 #no_bounds_check {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot := MATRIX4F32_IDENTITY

	rot[0][0] = c + t[0]*a[0]
	rot[0][1] = 0 + t[0]*a[1] + s*a[2]
	rot[0][2] = 0 + t[0]*a[2] - s*a[1]
	rot[0][3] = 0

	rot[1][0] = 0 + t[1]*a[0] - s*a[2]
	rot[1][1] = c + t[1]*a[1]
	rot[1][2] = 0 + t[1]*a[2] + s*a[0]
	rot[1][3] = 0

	rot[2][0] = 0 + t[2]*a[0] + s*a[1]
	rot[2][1] = 0 + t[2]*a[1] - s*a[0]
	rot[2][2] = c + t[2]*a[2]
	rot[2][3] = 0

	return rot
}
@(require_results)
matrix4_rotate_f64 :: proc "contextless" (angle_radians: f64, v: Vector3f64) -> Matrix4f64 #no_bounds_check {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	a := normalize(v)
	t := a * (1-c)

	rot := MATRIX4F64_IDENTITY

	rot[0][0] = c + t[0]*a[0]
	rot[0][1] = 0 + t[0]*a[1] + s*a[2]
	rot[0][2] = 0 + t[0]*a[2] - s*a[1]
	rot[0][3] = 0

	rot[1][0] = 0 + t[1]*a[0] - s*a[2]
	rot[1][1] = c + t[1]*a[1]
	rot[1][2] = 0 + t[1]*a[2] + s*a[0]
	rot[1][3] = 0

	rot[2][0] = 0 + t[2]*a[0] + s*a[1]
	rot[2][1] = 0 + t[2]*a[1] - s*a[0]
	rot[2][2] = c + t[2]*a[2]
	rot[2][3] = 0

	return rot
}
matrix4_rotate :: proc{
	matrix4_rotate_f16,
	matrix4_rotate_f32,
	matrix4_rotate_f64,
}


@(require_results)
matrix4_scale_f16 :: proc "contextless" (v: Vector3f16) -> (m: Matrix4f16) #no_bounds_check {
	m[0][0] = v[0]
	m[1][1] = v[1]
	m[2][2] = v[2]
	m[3][3] = 1
	return
}
@(require_results)
matrix4_scale_f32 :: proc "contextless" (v: Vector3f32) -> (m: Matrix4f32) #no_bounds_check {
	m[0][0] = v[0]
	m[1][1] = v[1]
	m[2][2] = v[2]
	m[3][3] = 1
	return
}
@(require_results)
matrix4_scale_f64 :: proc "contextless" (v: Vector3f64) -> (m: Matrix4f64) #no_bounds_check {
	m[0][0] = v[0]
	m[1][1] = v[1]
	m[2][2] = v[2]
	m[3][3] = 1
	return
}
matrix4_scale :: proc{
	matrix4_scale_f16,
	matrix4_scale_f32,
	matrix4_scale_f64,
}


@(require_results)
matrix4_look_at_f16 :: proc "contextless" (eye, centre, up: Vector3f16, flip_z_axis := true) -> (m: Matrix4f16) {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)

	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
@(require_results)
matrix4_look_at_f32 :: proc "contextless" (eye, centre, up: Vector3f32, flip_z_axis := true) -> (m: Matrix4f32) {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)

	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
@(require_results)
matrix4_look_at_f64 :: proc "contextless" (eye, centre, up: Vector3f64, flip_z_axis := true) -> (m: Matrix4f64) {
	f := normalize(centre - eye)
	s := normalize(cross(f, up))
	u := cross(s, f)

	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
matrix4_look_at :: proc{
	matrix4_look_at_f16,
	matrix4_look_at_f32,
	matrix4_look_at_f64,
}


@(require_results)
matrix4_look_at_from_fru_f16 :: proc "contextless" (eye, f, r, u: Vector3f16, flip_z_axis := true) -> (m: Matrix4f16) {
	f, s, u := f, r, u
	f = normalize(f)
	s = normalize(s)
	u = normalize(u)
	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
@(require_results)
matrix4_look_at_from_fru_f32 :: proc "contextless" (eye, f, r, u: Vector3f32, flip_z_axis := true) -> (m: Matrix4f32) {
	f, s, u := f, r, u
	f = normalize(f)
	s = normalize(s)
	u = normalize(u)
	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
@(require_results)
matrix4_look_at_from_fru_f64 :: proc "contextless" (eye, f, r, u: Vector3f64, flip_z_axis := true) -> (m: Matrix4f64) {
	f, s, u := f, r, u
	f = normalize(f)
	s = normalize(s)
	u = normalize(u)
	fe := dot(f, eye)

	return {
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, +fe if flip_z_axis else -fe,
		   0,    0,    0, 1,
	}
}
matrix4_look_at_from_fru :: proc{
	matrix4_look_at_from_fru_f16,
	matrix4_look_at_from_fru_f32,
	matrix4_look_at_from_fru_f64,
}


@(require_results)
matrix4_perspective_f16 :: proc "contextless" (fovy, aspect, near, far: f16, flip_z_axis := true) -> (m: Matrix4f16) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +(far + near) / (far - near)
	m[3, 2] = +1
	m[2, 3] = -2*far*near / (far - near)

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix4_perspective_f32 :: proc "contextless" (fovy, aspect, near, far: f32, flip_z_axis := true) -> (m: Matrix4f32) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +(far + near) / (far - near)
	m[3, 2] = +1
	m[2, 3] = -2*far*near / (far - near)

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix4_perspective_f64 :: proc "contextless" (fovy, aspect, near, far: f64, flip_z_axis := true) -> (m: Matrix4f64) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +(far + near) / (far - near)
	m[3, 2] = +1
	m[2, 3] = -2*far*near / (far - near)

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
matrix4_perspective :: proc{
	matrix4_perspective_f16,
	matrix4_perspective_f32,
	matrix4_perspective_f64,
}



@(require_results)
matrix_ortho3d_f16 :: proc "contextless" (left, right, bottom, top, near, far: f16, flip_z_axis := true) -> (m: Matrix4f16) #no_bounds_check {
	m[0, 0] = +2 / (right - left)
	m[1, 1] = +2 / (top - bottom)
	m[2, 2] = +2 / (far - near)
	m[0, 3] = -(right + left)   / (right - left)
	m[1, 3] = -(top   + bottom) / (top - bottom)
	m[2, 3] = -(far + near) / (far- near)
	m[3, 3] = 1

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix_ortho3d_f32 :: proc "contextless" (left, right, bottom, top, near, far: f32, flip_z_axis := true) -> (m: Matrix4f32) #no_bounds_check {
	m[0, 0] = +2 / (right - left)
	m[1, 1] = +2 / (top - bottom)
	m[2, 2] = +2 / (far - near)
	m[0, 3] = -(right + left)   / (right - left)
	m[1, 3] = -(top   + bottom) / (top - bottom)
	m[2, 3] = -(far + near) / (far- near)
	m[3, 3] = 1

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix_ortho3d_f64 :: proc "contextless" (left, right, bottom, top, near, far: f64, flip_z_axis := true) -> (m: Matrix4f64) #no_bounds_check {
	m[0, 0] = +2 / (right - left)
	m[1, 1] = +2 / (top - bottom)
	m[2, 2] = +2 / (far - near)
	m[0, 3] = -(right + left)   / (right - left)
	m[1, 3] = -(top   + bottom) / (top - bottom)
	m[2, 3] = -(far + near) / (far- near)
	m[3, 3] = 1

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
matrix_ortho3d :: proc{
	matrix_ortho3d_f16,
	matrix_ortho3d_f32,
	matrix_ortho3d_f64,
}



@(require_results)
matrix4_infinite_perspective_f16 :: proc "contextless" (fovy, aspect, near: f16, flip_z_axis := true) -> (m: Matrix4f16) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +1
	m[3, 2] = +1
	m[2, 3] = -2*near

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix4_infinite_perspective_f32 :: proc "contextless" (fovy, aspect, near: f32, flip_z_axis := true) -> (m: Matrix4f32) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +1
	m[3, 2] = +1
	m[2, 3] = -2*near

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
@(require_results)
matrix4_infinite_perspective_f64 :: proc "contextless" (fovy, aspect, near: f64, flip_z_axis := true) -> (m: Matrix4f64) #no_bounds_check {
	tan_half_fovy := math.tan(0.5 * fovy)
	m[0, 0] = 1 / (aspect*tan_half_fovy)
	m[1, 1] = 1 / (tan_half_fovy)
	m[2, 2] = +1
	m[3, 2] = +1
	m[2, 3] = -2*near

	if flip_z_axis {
		m[2] = -m[2]
	}

	return
}
matrix4_infinite_perspective :: proc{
	matrix4_infinite_perspective_f16,
	matrix4_infinite_perspective_f32,
	matrix4_infinite_perspective_f64,
}



@(require_results)
matrix2_from_scalar_f16 :: proc "contextless" (f: f16) -> (m: Matrix2f16) #no_bounds_check {
	m[0, 0], m[1, 0] = f, 0
	m[0, 1], m[1, 1] = 0, f
	return
}
@(require_results)
matrix2_from_scalar_f32 :: proc "contextless" (f: f32) -> (m: Matrix2f32) #no_bounds_check {
	m[0, 0], m[1, 0] = f, 0
	m[0, 1], m[1, 1] = 0, f
	return
}
@(require_results)
matrix2_from_scalar_f64 :: proc "contextless" (f: f64) -> (m: Matrix2f64) #no_bounds_check {
	m[0, 0], m[1, 0] = f, 0
	m[0, 1], m[1, 1] = 0, f
	return
}
matrix2_from_scalar :: proc{
	matrix2_from_scalar_f16,
	matrix2_from_scalar_f32,
	matrix2_from_scalar_f64,
}


@(require_results)
matrix3_from_scalar_f16 :: proc "contextless" (f: f16) -> (m: Matrix3f16) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
	m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
	m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
	return
}
@(require_results)
matrix3_from_scalar_f32 :: proc "contextless" (f: f32) -> (m: Matrix3f32) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
	m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
	m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
	return
}
@(require_results)
matrix3_from_scalar_f64 :: proc "contextless" (f: f64) -> (m: Matrix3f64) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0] = f, 0, 0
	m[0, 1], m[1, 1], m[2, 1] = 0, f, 0
	m[0, 2], m[1, 2], m[2, 2] = 0, 0, f
	return
}
matrix3_from_scalar :: proc{
	matrix3_from_scalar_f16,
	matrix3_from_scalar_f32,
	matrix3_from_scalar_f64,
}


@(require_results)
matrix4_from_scalar_f16 :: proc "contextless" (f: f16) -> (m: Matrix4f16) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
	m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
	m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
	m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
	return
}
@(require_results)
matrix4_from_scalar_f32 :: proc "contextless" (f: f32) -> (m: Matrix4f32) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
	m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
	m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
	m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
	return
}
@(require_results)
matrix4_from_scalar_f64 :: proc "contextless" (f: f64) -> (m: Matrix4f64) #no_bounds_check {
	m[0, 0], m[1, 0], m[2, 0], m[3, 0] = f, 0, 0, 0
	m[0, 1], m[1, 1], m[2, 1], m[3, 1] = 0, f, 0, 0
	m[0, 2], m[1, 2], m[2, 2], m[3, 2] = 0, 0, f, 0
	m[0, 3], m[1, 3], m[2, 3], m[3, 3] = 0, 0, 0, f
	return
}
matrix4_from_scalar :: proc{
	matrix4_from_scalar_f16,
	matrix4_from_scalar_f32,
	matrix4_from_scalar_f64,
}


@(require_results)
matrix2_from_matrix3_f16 :: proc "contextless" (m: Matrix3f16) -> (r: Matrix2f16) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
@(require_results)
matrix2_from_matrix3_f32 :: proc "contextless" (m: Matrix3f32) -> (r: Matrix2f32) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
@(require_results)
matrix2_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (r: Matrix2f64) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
matrix2_from_matrix3 :: proc{
	matrix2_from_matrix3_f16,
	matrix2_from_matrix3_f32,
	matrix2_from_matrix3_f64,
}


@(require_results)
matrix2_from_matrix4_f16 :: proc "contextless" (m: Matrix4f16) -> (r: Matrix2f16) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
@(require_results)
matrix2_from_matrix4_f32 :: proc "contextless" (m: Matrix4f32) -> (r: Matrix2f32) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
@(require_results)
matrix2_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (r: Matrix2f64) #no_bounds_check {
	r[0, 0], r[1, 0] = m[0, 0], m[1, 0]
	r[0, 1], r[1, 1] = m[0, 1], m[1, 1]
	return
}
matrix2_from_matrix4 :: proc{
	matrix2_from_matrix4_f16,
	matrix2_from_matrix4_f32,
	matrix2_from_matrix4_f64,
}


@(require_results)
matrix3_from_matrix2_f16 :: proc "contextless" (m: Matrix2f16) -> (r: Matrix3f16) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
	r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
	return
}
@(require_results)
matrix3_from_matrix2_f32 :: proc "contextless" (m: Matrix2f32) -> (r: Matrix3f32) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
	r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
	return
}
@(require_results)
matrix3_from_matrix2_f64 :: proc "contextless" (m: Matrix2f64) -> (r: Matrix3f64) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], 0
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], 0
	r[0, 2], r[1, 2], r[2, 2] =       0,       0, 1
	return
}
matrix3_from_matrix2 :: proc{
	matrix3_from_matrix2_f16,
	matrix3_from_matrix2_f32,
	matrix3_from_matrix2_f64,
}


@(require_results)
matrix3_from_matrix4_f16 :: proc "contextless" (m: Matrix4f16) -> (r: Matrix3f16) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return
}
@(require_results)
matrix3_from_matrix4_f32 :: proc "contextless" (m: Matrix4f32) -> (r: Matrix3f32) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return
}
@(require_results)
matrix3_from_matrix4_f64 :: proc "contextless" (m: Matrix4f64) -> (r: Matrix3f64) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0] = m[0, 0], m[1, 0], m[2, 0]
	r[0, 1], r[1, 1], r[2, 1] = m[0, 1], m[1, 1], m[2, 1]
	r[0, 2], r[1, 2], r[2, 2] = m[0, 2], m[1, 2], m[2, 2]
	return
}
matrix3_from_matrix4 :: proc{
	matrix3_from_matrix4_f16,
	matrix3_from_matrix4_f32,
	matrix3_from_matrix4_f64,
}


@(require_results)
matrix4_from_matrix2_f16 :: proc "contextless" (m: Matrix2f16) -> (r: Matrix4f16) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
	return
}
@(require_results)
matrix4_from_matrix2_f32 :: proc "contextless" (m: Matrix2f32) -> (r: Matrix4f32) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
	return
}
@(require_results)
matrix4_from_matrix2_f64 :: proc "contextless" (m: Matrix2f64) -> (r: Matrix4f64) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], 0, 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], 0, 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] =       0,       0, 1, 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0, 0, 1
	return
}
matrix4_from_matrix2 :: proc{
	matrix4_from_matrix2_f16,
	matrix4_from_matrix2_f32,
	matrix4_from_matrix2_f64,
}


@(require_results)
matrix4_from_matrix3_f16 :: proc "contextless" (m: Matrix3f16) -> (r: Matrix4f16) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
	return
}
@(require_results)
matrix4_from_matrix3_f32 :: proc "contextless" (m: Matrix3f32) -> (r: Matrix4f32) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
	return
}
@(require_results)
matrix4_from_matrix3_f64 :: proc "contextless" (m: Matrix3f64) -> (r: Matrix4f64) #no_bounds_check {
	r[0, 0], r[1, 0], r[2, 0], r[3, 0] = m[0, 0], m[1, 0], m[2, 0], 0
	r[0, 1], r[1, 1], r[2, 1], r[3, 1] = m[0, 1], m[1, 1], m[2, 1], 0
	r[0, 2], r[1, 2], r[2, 2], r[3, 2] = m[0, 2], m[1, 2], m[2, 2], 0
	r[0, 3], r[1, 3], r[2, 3], r[3, 3] =       0,       0,       0, 1
	return
}
matrix4_from_matrix3 :: proc{
	matrix4_from_matrix3_f16,
	matrix4_from_matrix3_f32,
	matrix4_from_matrix3_f64,
}


@(require_results)
quaternion_from_scalar_f16 :: proc "contextless" (f: f16) -> (q: Quaternionf16) {
	q.w = f
	return
}
@(require_results)
quaternion_from_scalar_f32 :: proc "contextless" (f: f32) -> (q: Quaternionf32) {
	q.w = f
	return
}
@(require_results)
quaternion_from_scalar_f64 :: proc "contextless" (f: f64) -> (q: Quaternionf64) {
	q.w = f
	return
}
quaternion_from_scalar :: proc{
	quaternion_from_scalar_f16,
	quaternion_from_scalar_f32,
	quaternion_from_scalar_f64,
}



to_matrix2f16    :: proc{matrix2_from_scalar_f16,    matrix2_from_matrix3_f16,    matrix2_from_matrix4_f16}
to_matrix3f16    :: proc{matrix3_from_scalar_f16,    matrix3_from_matrix2_f16,    matrix3_from_matrix4_f16, matrix3_from_quaternion_f16}
to_matrix4f16    :: proc{matrix4_from_scalar_f16,    matrix4_from_matrix2_f16,    matrix4_from_matrix3_f16, matrix4_from_quaternion_f16}
to_quaternionf16 :: proc{quaternion_from_scalar_f16, quaternion_from_matrix3_f16, quaternion_from_matrix4_f16}


to_matrix2f32    :: proc{matrix2_from_scalar_f32,    matrix2_from_matrix3_f32,    matrix2_from_matrix4_f32}
to_matrix3f32    :: proc{matrix3_from_scalar_f32,    matrix3_from_matrix2_f32,    matrix3_from_matrix4_f32, matrix3_from_quaternion_f32}
to_matrix4f32    :: proc{matrix4_from_scalar_f32,    matrix4_from_matrix2_f32,    matrix4_from_matrix3_f32, matrix4_from_quaternion_f32}
to_quaternionf32 :: proc{quaternion_from_scalar_f32, quaternion_from_matrix3_f32, quaternion_from_matrix4_f32}



to_matrix2f64    :: proc{matrix2_from_scalar_f64,    matrix2_from_matrix3_f64,    matrix2_from_matrix4_f64}
to_matrix3f64    :: proc{matrix3_from_scalar_f64,    matrix3_from_matrix2_f64,    matrix3_from_matrix4_f64, matrix3_from_quaternion_f64}
to_matrix4f64    :: proc{matrix4_from_scalar_f64,    matrix4_from_matrix2_f64,    matrix4_from_matrix3_f64, matrix4_from_quaternion_f64}
to_quaternionf64 :: proc{quaternion_from_scalar_f64, quaternion_from_matrix3_f64, quaternion_from_matrix4_f64}





to_matrix2f :: proc{
	matrix2_from_scalar_f16, matrix2_from_matrix3_f16, matrix2_from_matrix4_f16,
	matrix2_from_scalar_f32, matrix2_from_matrix3_f32, matrix2_from_matrix4_f32,
	matrix2_from_scalar_f64, matrix2_from_matrix3_f64, matrix2_from_matrix4_f64,
}

to_matrix3 :: proc{
	matrix3_from_scalar_f16, matrix3_from_matrix2_f16, matrix3_from_matrix4_f16, matrix3_from_quaternion_f16,
	matrix3_from_scalar_f32, matrix3_from_matrix2_f32, matrix3_from_matrix4_f32, matrix3_from_quaternion_f32,
	matrix3_from_scalar_f64, matrix3_from_matrix2_f64, matrix3_from_matrix4_f64, matrix3_from_quaternion_f64,
}

to_matrix4 :: proc{
	matrix4_from_scalar_f16, matrix4_from_matrix2_f16, matrix4_from_matrix3_f16, matrix4_from_quaternion_f16,
	matrix4_from_scalar_f32, matrix4_from_matrix2_f32, matrix4_from_matrix3_f32, matrix4_from_quaternion_f32,
	matrix4_from_scalar_f64, matrix4_from_matrix2_f64, matrix4_from_matrix3_f64, matrix4_from_quaternion_f64,
}

to_quaternion :: proc{
	quaternion_from_scalar_f16, quaternion_from_matrix3_f16, quaternion_from_matrix4_f16,
	quaternion_from_scalar_f32, quaternion_from_matrix3_f32, quaternion_from_matrix4_f32,
	quaternion_from_scalar_f64, quaternion_from_matrix3_f64, quaternion_from_matrix4_f64,
}



@(require_results)
matrix2_orthonormalize_f16 :: proc "contextless" (m: Matrix2f16) -> (r: Matrix2f16) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	return
}
@(require_results)
matrix2_orthonormalize_f32 :: proc "contextless" (m: Matrix2f32) -> (r: Matrix2f32) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	return
}
@(require_results)
matrix2_orthonormalize_f64 :: proc "contextless" (m: Matrix2f64) -> (r: Matrix2f64) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	return
}
matrix2_orthonormalize :: proc{
	matrix2_orthonormalize_f16,
	matrix2_orthonormalize_f32,
	matrix2_orthonormalize_f64,
}


@(require_results)
matrix3_orthonormalize_f16 :: proc "contextless" (m: Matrix3f16) -> (r: Matrix3f16) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	d1 := dot(r[1], r[2])
	d0 = dot(r[0], r[2])
	r[2] -= r[0]*d0 + r[1]*d1
	r[2] = normalize(r[2])

	return
}
@(require_results)
matrix3_orthonormalize_f32 :: proc "contextless" (m: Matrix3f32) -> (r: Matrix3f32) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	d1 := dot(r[1], r[2])
	d0 = dot(r[0], r[2])
	r[2] -= r[0]*d0 + r[1]*d1
	r[2] = normalize(r[2])

	return
}
@(require_results)
matrix3_orthonormalize_f64 :: proc "contextless" (m: Matrix3f64) -> (r: Matrix3f64) #no_bounds_check {
	r = m
	r[0] = normalize(m[0])

	d0 := dot(r[0], r[1])
	r[1] -= r[0] * d0
	r[1] = normalize(r[1])

	d1 := dot(r[1], r[2])
	d0 = dot(r[0], r[2])
	r[2] -= r[0]*d0 + r[1]*d1
	r[2] = normalize(r[2])

	return
}
matrix3_orthonormalize :: proc{
	matrix3_orthonormalize_f16,
	matrix3_orthonormalize_f32,
	matrix3_orthonormalize_f64,
}


@(require_results)
vector3_orthonormalize_f16 :: proc "contextless" (x, y: Vector3f16) -> (z: Vector3f16) {
	return normalize(x - y * dot(y, x))
}
@(require_results)
vector3_orthonormalize_f32 :: proc "contextless" (x, y: Vector3f32) -> (z: Vector3f32) {
	return normalize(x - y * dot(y, x))
}
@(require_results)
vector3_orthonormalize_f64 :: proc "contextless" (x, y: Vector3f64) -> (z: Vector3f64) {
	return normalize(x - y * dot(y, x))
}
vector3_orthonormalize :: proc{
	vector3_orthonormalize_f16,
	vector3_orthonormalize_f32,
	vector3_orthonormalize_f64,
}


orthonormalize :: proc{
	matrix2_orthonormalize_f16, matrix3_orthonormalize_f16, vector3_orthonormalize_f16,
	matrix2_orthonormalize_f32, matrix3_orthonormalize_f32, vector3_orthonormalize_f32,
	matrix2_orthonormalize_f64, matrix3_orthonormalize_f64, vector3_orthonormalize_f64,
}


@(require_results)
matrix4_orientation_f16 :: proc "contextless" (normal, up: Vector3f16) -> Matrix4f16 {
	if all(equal(normal, up)) {
		return MATRIX4F16_IDENTITY
	}

	rotation_axis := cross(up, normal)
	angle := math.acos(dot(normal, up))

	return matrix4_rotate(angle, rotation_axis)
}
@(require_results)
matrix4_orientation_f32 :: proc "contextless" (normal, up: Vector3f32) -> Matrix4f32 {
	if all(equal(normal, up)) {
		return MATRIX4F32_IDENTITY
	}

	rotation_axis := cross(up, normal)
	angle := math.acos(dot(normal, up))

	return matrix4_rotate(angle, rotation_axis)
}
@(require_results)
matrix4_orientation_f64 :: proc "contextless" (normal, up: Vector3f64) -> Matrix4f64 {
	if all(equal(normal, up)) {
		return MATRIX4F64_IDENTITY
	}

	rotation_axis := cross(up, normal)
	angle := math.acos(dot(normal, up))

	return matrix4_rotate(angle, rotation_axis)
}
matrix4_orientation :: proc{
	matrix4_orientation_f16,
	matrix4_orientation_f32,
	matrix4_orientation_f64,
}


@(require_results)
euclidean_from_polar_f16 :: proc "contextless" (polar: Vector2f16) -> Vector3f16 {
	latitude, longitude := polar.x, polar.y
	cx, sx := math.cos(latitude), math.sin(latitude)
	cy, sy := math.cos(longitude), math.sin(longitude)

	return {
		cx*sy,
		sx,
		cx*cy,
	}
}
@(require_results)
euclidean_from_polar_f32 :: proc "contextless" (polar: Vector2f32) -> Vector3f32 {
	latitude, longitude := polar.x, polar.y
	cx, sx := math.cos(latitude), math.sin(latitude)
	cy, sy := math.cos(longitude), math.sin(longitude)

	return {
		cx*sy,
		sx,
		cx*cy,
	}
}
@(require_results)
euclidean_from_polar_f64 :: proc "contextless" (polar: Vector2f64) -> Vector3f64 {
	latitude, longitude := polar.x, polar.y
	cx, sx := math.cos(latitude), math.sin(latitude)
	cy, sy := math.cos(longitude), math.sin(longitude)

	return {
		cx*sy,
		sx,
		cx*cy,
	}
}
euclidean_from_polar :: proc{
	euclidean_from_polar_f16,
	euclidean_from_polar_f32,
	euclidean_from_polar_f64,
}


@(require_results)
polar_from_euclidean_f16 :: proc "contextless" (euclidean: Vector3f16) -> Vector3f16 {
	n := length(euclidean)
	tmp := euclidean / n

	xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

	return {
		math.asin(tmp.y),
		math.atan2(tmp.x, tmp.z),
		xz_dist,
	}
}
@(require_results)
polar_from_euclidean_f32 :: proc "contextless" (euclidean: Vector3f32) -> Vector3f32 {
	n := length(euclidean)
	tmp := euclidean / n

	xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

	return {
		math.asin(tmp.y),
		math.atan2(tmp.x, tmp.z),
		xz_dist,
	}
}
@(require_results)
polar_from_euclidean_f64 :: proc "contextless" (euclidean: Vector3f64) -> Vector3f64 {
	n := length(euclidean)
	tmp := euclidean / n

	xz_dist := math.sqrt(tmp.x*tmp.x + tmp.z*tmp.z)

	return {
		math.asin(tmp.y),
		math.atan2(tmp.x, tmp.z),
		xz_dist,
	}
}
polar_from_euclidean :: proc{
	polar_from_euclidean_f16,
	polar_from_euclidean_f32,
	polar_from_euclidean_f64,
}

