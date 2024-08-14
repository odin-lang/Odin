package vendor_box2d

import "core:c"
import "core:math"

pi :: 3.14159265359

Vec2 :: [2]f32
Rot :: struct {
	c, s: f32, // cosine and sine
}

Transform :: struct {
	p: Vec2,
	q: Rot,
}

Mat22 :: matrix[2, 2]f32
AABB :: struct {
	lowerBound: Vec2,
	upperBound: Vec2,
}

Vec2_zero          :: Vec2{0, 0}
Rot_identity       :: Rot{1, 0}
Transform_identity :: Transform{{0, 0}, {1, 0}}
Mat22_zero         :: Mat22{0, 0, 0, 0}


// @return the minimum of two floats
@(deprecated="Prefer the built-in 'min(a, b)'", require_results)
MinFloat :: proc "c" (a, b: f32) -> f32 {
	return min(a, b)
}

// @return the maximum of two floats
@(deprecated="Prefer the built-in 'max(a, b)'", require_results)
MaxFloat :: proc "c" (a, b: f32) -> f32 {
	return max(a, b)
}

// @return the absolute value of a float
@(deprecated="Prefer the built-in 'abs(a)'", require_results)
AbsFloat :: proc "c" (a: f32) -> f32 {
	return abs(a)
}

// @return a f32 clamped between a lower and upper bound
@(deprecated="Prefer the built-in 'clamp(a, lower, upper)'", require_results)
ClampFloat :: proc "c" (a, lower, upper: f32) -> f32 {
	return clamp(a, lower, upper)
}

// @return the minimum of two integers
@(deprecated="Prefer the built-in 'min(a, b)'", require_results)
MinInt :: proc "c" (a, b: c.int) -> c.int {
	return min(a, b)
}

// @return the maximum of two integers
@(deprecated="Prefer the built-in 'max(a, b)'", require_results)
MaxInt :: proc "c" (a, b: c.int) -> c.int {
	return max(a, b)
}

// @return the absolute value of an integer
@(deprecated="Prefer the built-in 'abs(a)'", require_results)
AbsInt :: proc "c" (a: c.int) -> c.int {
	return abs(a)
}

// @return an integer clamped between a lower and upper bound
@(deprecated="Prefer the built-in 'clamp(a, lower, upper)'", require_results)
ClampInt :: proc "c" (a, lower, upper: c.int) -> c.int {
	return clamp(a, lower, upper)
}

// Vector dot product
@(require_results)
Dot :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}

// Vector cross product. In 2D this yields a scalar.
@(require_results)
Cross :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.y - a.y * b.x
}

// Perform the cross product on a vector and a scalar. In 2D this produces a vector.
@(require_results)
CrossVS :: proc "c" (v: Vec2, s: f32) -> Vec2 {
	return {s * v.y, -s * v.x}
}

// Perform the cross product on a scalar and a vector. In 2D this produces a vector.
@(require_results)
CrossSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return {-s * v.y, s * v.x}
}

// Get a left pointing perpendicular vector. Equivalent to b2CrossSV(1, v)
@(require_results)
LeftPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {-v.y, v.x}
}

// Get a right pointing perpendicular vector. Equivalent to b2CrossVS(v, 1)
@(require_results)
RightPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {v.y, -v.x}
}

// Vector addition
@(deprecated="Prefer 'a + b'", require_results)
Add :: proc "c" (a, b: Vec2) -> Vec2 {
	return a + b
}

// Vector subtraction
@(deprecated="Prefer 'a - b'", require_results)
Sub :: proc "c" (a, b: Vec2) -> Vec2 {
	return a - b
}

// Vector negation
@(deprecated="Prefer '-a'", require_results)
Neg :: proc "c" (a: Vec2) -> Vec2 {
	return -a
}

// Vector linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/
@(require_results)
Lerp :: proc "c" (a, b: Vec2, t: f32) -> Vec2 {
	return {(1 - t) * a.x + t * b.x, (1 - t) * a.y + t * b.y}
}

// Component-wise multiplication
@(deprecated="Prefer 'a * b'", require_results)
Mul :: proc "c" (a, b: Vec2) -> Vec2 {
	return a * b
}

// Multiply a scalar and vector
@(deprecated="Prefer 's * v'", require_results)
MulSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return s * v
}

// a + s * b
@(deprecated="Prefer 'a + s * b'", require_results)
MulAdd :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a + s * b
}

// a - s * b
@(deprecated="Prefer 'a - s * b'", require_results)
MulSub :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a - s * b
}

// Component-wise absolute vector
@(require_results)
Abs :: proc "c" (a: Vec2) -> (b: Vec2) {
	b.x = abs(a.x)
	b.y = abs(a.y)
	return
}

// Component-wise minimum vector
@(require_results)
Min :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = min(a.x, b.x)
	c.y = min(a.y, b.y)
	return
}

// Component-wise maximum vector
@(require_results)
Max :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = max(a.x, b.x)
	c.y = max(a.y, b.y)
	return
}

// Component-wise clamp vector v into the range [a, b]
@(require_results)
Clamp :: proc "c" (v: Vec2, a, b: Vec2) -> (c: Vec2) {
	c.x = clamp(v.x, a.x, b.x)
	c.y = clamp(v.y, a.y, b.y)
	return
}

// Get the length of this vector (the norm)
@(require_results)
Length :: proc "c" (v: Vec2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

// Get the length squared of this vector
@(require_results)
LengthSquared :: proc "c" (v: Vec2) -> f32 {
	return v.x * v.x + v.y * v.y
}

// Get the distance between two points
@(require_results)
Distance :: proc "c" (a, b: Vec2) -> f32 {
	dx := b.x - a.x
	dy := b.y - a.y
	return math.sqrt(dx * dx + dy * dy)
}

// Get the distance squared between points
@(require_results)
DistanceSquared :: proc "c" (a, b: Vec2) -> f32 {
	c := Vec2{b.x - a.x, b.y - a.y}
	return c.x * c.x + c.y * c.y
}

// Make a rotation using an angle in radians
@(require_results)
MakeRot :: proc "c" (angle: f32) -> Rot {
	// todo determinism
	return {math.cos(angle), math.sin(angle)}
}

// Normalize rotation
@(require_results)
NormalizeRot :: proc "c" (q: Rot) -> Rot {
	mag := math.sqrt(q.s * q.s + q.c * q.c)
	invMag := f32(mag > 0.0 ? 1.0 / mag : 0.0)
	return {q.c * invMag, q.s * invMag}
}

// Is this rotation normalized?
@(require_results)
IsNormalized :: proc "c" (q: Rot) -> bool {
	// larger tolerance due to failure on mingw 32-bit
	qq := q.s * q.s + q.c * q.c
	return 1.0 - 0.0006 < qq && qq < 1 + 0.0006
}

// Normalized linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/
@(require_results)
NLerp :: proc "c" (q1: Rot, q2: Rot, t: f32) -> Rot {
	omt := 1 - t
	return NormalizeRot({
		omt * q1.c + t * q2.c,
		omt * q1.s + t * q2.s,
	})
}

// Integration rotation from angular velocity
//	@param q1 initial rotation
//	@param deltaAngle the angular displacement in radians
@(require_results)
IntegrateRotation :: proc "c" (q1: Rot, deltaAngle: f32) -> Rot {
	// dc/dt = -omega * sin(t)
	// ds/dt = omega * cos(t)
	// c2 = c1 - omega * h * s1
	// s2 = s1 + omega * h * c1
	q2 := Rot{q1.c - deltaAngle * q1.s, q1.s + deltaAngle * q1.c}
	mag := math.sqrt(q2.s * q2.s + q2.c * q2.c)
	invMag := f32(mag > 0.0 ? 1 / mag : 0.0)
	return {q2.c * invMag, q2.s * invMag}
}

// Compute the angular velocity necessary to rotate between two rotations over a give time
//	@param q1 initial rotation
//	@param q2 final rotation
//	@param inv_h inverse time step
@(require_results)
ComputeAngularVelocity :: proc "c" (q1: Rot, q2: Rot, inv_h: f32) -> f32 {
	// ds/dt = omega * cos(t)
	// dc/dt = -omega * sin(t)
	// s2 = s1 + omega * h * c1
	// c2 = c1 - omega * h * s1

	// omega * h * s1 = c1 - c2
	// omega * h * c1 = s2 - s1
	// omega * h = (c1 - c2) * s1 + (s2 - s1) * c1
	// omega * h = s1 * c1 - c2 * s1 + s2 * c1 - s1 * c1
	// omega * h = s2 * c1 - c2 * s1 = sin(a2 - a1) ~= a2 - a1 for small delta
	omega := inv_h * (q2.s * q1.c - q2.c * q1.s)
	return omega
}

// Get the angle in radians in the range [-pi, pi]
@(require_results)
Rot_GetAngle :: proc "c" (q: Rot) -> f32 {
	// todo determinism
	return math.atan2(q.s, q.c)
}

// Get the x-axis
@(require_results)
Rot_GetXAxis :: proc "c" (q: Rot) -> Vec2 {
	return {q.c, q.s}
}

// Get the y-axis
@(require_results)
Rot_GetYAxis :: proc "c" (q: Rot) -> Vec2 {
	return {-q.s, q.c}
}

// Multiply two rotations: q * r
@(require_results)
MulRot :: proc "c" (q, r: Rot) -> (qr: Rot) {
	// [qc -qs] * [rc -rs] = [qc*rc-qs*rs -qc*rs-qs*rc]
	// [qs  qc]   [rs  rc]   [qs*rc+qc*rs -qs*rs+qc*rc]
	// s(q + r) = qs * rc + qc * rs
	// c(q + r) = qc * rc - qs * rs
	qr.s = q.s * r.c + q.c * r.s
	qr.c = q.c * r.c - q.s * r.s
	return
}

// Transpose multiply two rotations: qT * r
@(require_results)
InvMulRot :: proc "c" (q, r: Rot) -> (qr: Rot) {
	// [ qc qs] * [rc -rs] = [qc*rc+qs*rs -qc*rs+qs*rc]
	// [-qs qc]   [rs  rc]   [-qs*rc+qc*rs qs*rs+qc*rc]
	// s(q - r) = qc * rs - qs * rc
	// c(q - r) = qc * rc + qs * rs
	qr.s = q.c * r.s - q.s * r.c
	qr.c = q.c * r.c + q.s * r.s
	return
}

// relative angle between b and a (rot_b * inv(rot_a))
@(require_results)
RelativeAngle :: proc "c" (b, a: Rot) -> f32 {
	// sin(b - a) = bs * ac - bc * as
	// cos(b - a) = bc * ac + bs * as
	s := b.s * a.c - b.c * a.s
	c := b.c * a.c + b.s * a.s
	return math.atan2(s, c)
}

// Convert an angle in the range [-2*pi, 2*pi] into the range [-pi, pi]
@(require_results)
UnwindAngle :: proc "c" (angle: f32) -> f32 {
	if angle < -pi {
		return angle + 2.0 * pi
	} else if angle > pi {
		return angle - 2.0 * pi
	}
	return angle
}

// Rotate a vector
@(require_results)
RotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x - q.s * v.y, q.s * v.x + q.c * v.y}
}

// Inverse rotate a vector
@(require_results)
InvRotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x + q.s * v.y, -q.s * v.x + q.c * v.y}
}

// Transform a point (e.g. local space to world space)
@(require_results)
TransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	x := (t.q.c * p.x - t.q.s * p.y) + t.p.x
	y := (t.q.s * p.x + t.q.c * p.y) + t.p.y
	return {x, y}
}

// Inverse transform a point (e.g. world space to local space)
@(require_results)
InvTransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	vx := p.x - t.p.x
	vy := p.y - t.p.y
	return {t.q.c * vx + t.q.s * vy, -t.q.s * vx + t.q.c * vy}
}

// v2 = A.q.Rot(B.q.Rot(v1) + B.p) + A.p
//    = (A.q * B.q).Rot(v1) + A.q.Rot(B.p) + A.p
@(require_results)
MulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = MulRot(A.q, B.q)
	C.p = RotateVector(A.q, B.p) + A.p
	return
}

// v2 = A.q' * (B.q * v1 + B.p - A.p)
//    = A.q' * B.q * v1 + A.q' * (B.p - A.p)
@(require_results)
InvMulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = InvMulRot(A.q, B.q)
	C.p = InvRotateVector(A.q, B.p-A.p)
	return
}

// Multiply a 2-by-2 matrix times a 2D vector
@(deprecated="Prefer 'A * v'", require_results)
MulMV :: proc "c" (A: Mat22, v: Vec2) -> Vec2 {
	return A * v
}

// Get the inverse of a 2-by-2 matrix
@(require_results)
GetInverse22 :: proc "c" (A: Mat22) -> Mat22 {
	a := A[0, 0]
	b := A[0, 1]
	c := A[1, 0]
	d := A[1, 1]
	det := a * d - b * c
	if det != 0.0 {
		det = 1 / det
	}

	return Mat22{
		 det * d, -det * b,
		-det * c,  det * a,
	}
}

// Solve A * x = b, where b is a column vector. This is more efficient
// than computing the inverse in one-shot cases.
@(require_results)
Solve22 :: proc "c" (A: Mat22, b: Vec2) -> Vec2 {
	a11 := A[0, 0]
	a12 := A[0, 1]
	a21 := A[1, 0]
	a22 := A[1, 1]
	det := a11 * a22 - a12 * a21
	if det != 0.0 {
		det = 1 / det
	}
	return {det * (a22 * b.x - a12 * b.y), det * (a11 * b.y - a21 * b.x)}
}

// Does a fully contain b
@(require_results)
AABB_Contains :: proc "c" (a, b: AABB) -> bool {
	(a.lowerBound.x <= b.lowerBound.x) or_return
	(a.lowerBound.y <= b.lowerBound.y) or_return
	(b.upperBound.x <= a.upperBound.x) or_return
	(b.upperBound.y <= a.upperBound.y) or_return
	return true
}

// Get the center of the AABB.
@(require_results)
AABB_Center :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.lowerBound.x + a.upperBound.x), 0.5 * (a.lowerBound.y + a.upperBound.y)}
}

// Get the extents of the AABB (half-widths).
@(require_results)
AABB_Extents :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.upperBound.x - a.lowerBound.x), 0.5 * (a.upperBound.y - a.lowerBound.y)}
}

// Union of two AABBs
@(require_results)
AABB_Union :: proc "c" (a, b: AABB) -> (c: AABB) {
	c.lowerBound.x = min(a.lowerBound.x, b.lowerBound.x)
	c.lowerBound.y = min(a.lowerBound.y, b.lowerBound.y)
	c.upperBound.x = max(a.upperBound.x, b.upperBound.x)
	c.upperBound.y = max(a.upperBound.y, b.upperBound.y)
	return
}

@(require_results)
Float_IsValid :: proc "c" (a: f32) -> bool {
	math.is_nan(a) or_return
	math.is_inf(a) or_return
	return true
}

@(require_results)
Vec2_IsValid :: proc "c" (v: Vec2) -> bool {
	(math.is_nan(v.x) || math.is_nan(v.y)) or_return
	(math.is_inf(v.x) || math.is_inf(v.y)) or_return
	return true
}

@(require_results)
Rot_IsValid :: proc "c" (q: Rot) -> bool {
	(math.is_nan(q.s) || math.is_nan(q.c)) or_return
	(math.is_inf(q.s) || math.is_inf(q.c)) or_return
	return IsNormalized(q)
}

@(require_results)
Normalize :: proc "c" (v: Vec2) -> Vec2 {
	length := Length(v)
	if length < 1e-23 {
		return Vec2_zero
	}
	invLength := 1 / length
	return invLength * v
}

@(require_results)
NormalizeChecked :: proc "odin" (v: Vec2) -> Vec2 {
	length := Length(v)
	if length < 1e-23 {
		panic("zero-length Vec2")
	}
	invLength := 1 / length
	return invLength * v
}

@(require_results)
GetLengthAndNormalize :: proc "c" (v: Vec2) -> (length: f32, vn: Vec2) {
	length = Length(v)
	if length < 1e-23 {
		return
	}
	invLength := 1 / length
	vn = invLength * v
	return
}
