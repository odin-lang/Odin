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
MinFloat :: proc "c" (a, b: f32) -> f32 {
	return min(a, b)
}

// @return the maximum of two floats
MaxFloat :: proc "c" (a, b: f32) -> f32 {
	return max(a, b)
}

// @return the absolute value of a float
AbsFloat :: proc "c" (a: f32) -> f32 {
	return abs(a)
}

// @return a f32 clamped between a lower and upper bound
ClampFloat :: proc "c" (a, lower, upper: f32) -> f32 {
	return clamp(a, lower, upper)
}

// @return the minimum of two integers
MinInt :: proc "c" (a, b: c.int) -> c.int {
	return min(a, b)
}

// @return the maximum of two integers
MaxInt :: proc "c" (a, b: c.int) -> c.int {
	return max(a, b)
}

// @return the absolute value of an integer
AbsInt :: proc "c" (a: c.int) -> c.int {
	return abs(a)
}

// @return an integer clamped between a lower and upper bound
ClampInt :: proc "c" (a, lower, upper: c.int) -> c.int {
	return clamp(a, lower, upper)
}

// Vector dot product
Dot :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}

// Vector cross product. In 2D this yields a scalar.
Cross :: proc "c" (a, b: Vec2) -> f32 {
	return a.x * b.y - a.y * b.x
}

// Perform the cross product on a vector and a scalar. In 2D this produces a vector.
CrossVS :: proc "c" (v: Vec2, s: f32) -> Vec2 {
	return {s * v.y, -s * v.x}
}

// Perform the cross product on a scalar and a vector. In 2D this produces a vector.
CrossSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return {-s * v.y, s * v.x}
}

// Get a left pointing perpendicular vector. Equivalent to b2CrossSV(1, v)
LeftPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {-v.y, v.x}
}

// Get a right pointing perpendicular vector. Equivalent to b2CrossVS(v, 1)
RightPerp :: proc "c" (v: Vec2) -> Vec2 {
	return {v.y, -v.x}
}

// Vector addition
Add :: proc "c" (a, b: Vec2) -> Vec2 {
	return a + b
}

// Vector subtraction
Sub :: proc "c" (a, b: Vec2) -> Vec2 {
	return a - b
}

// Vector negation
Neg :: proc "c" (a: Vec2) -> Vec2 {
	return -a
}

// Vector linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/
Lerp :: proc "c" (a, b: Vec2, t: f32) -> Vec2 {
	return {(1 - t) * a.x + t * b.x, (1 - t) * a.y + t * b.y}
}

// Component-wise multiplication
Mul :: proc "c" (a, b: Vec2) -> Vec2 {
	return a * b
}

// Multiply a scalar and vector
MulSV :: proc "c" (s: f32, v: Vec2) -> Vec2 {
	return s * v
}

// a + s * b
MulAdd :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a + s * b
}

// a - s * b
MulSub :: proc "c" (a: Vec2, s: f32, b: Vec2) -> Vec2 {
	return a - s * b
}

// Component-wise absolute vector
Abs :: proc "c" (a: Vec2) -> (b: Vec2) {
	b.x = AbsFloat(a.x)
	b.y = AbsFloat(a.y)
	return
}

// Component-wise minimum vector
Min :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = MinFloat(a.x, b.x)
	c.y = MinFloat(a.y, b.y)
	return
}

// Component-wise maximum vector
Max :: proc "c" (a, b: Vec2) -> (c: Vec2) {
	c.x = MaxFloat(a.x, b.x)
	c.y = MaxFloat(a.y, b.y)
	return
}

// Component-wise clamp vector v into the range [a, b]
Clamp :: proc "c" (v: Vec2, a, b: Vec2) -> (c: Vec2) {
	c.x = ClampFloat(v.x, a.x, b.x)
	c.y = ClampFloat(v.y, a.y, b.y)
	return
}

// Get the length of this vector (the norm)
Length :: proc "c" (v: Vec2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

// Get the length squared of this vector
LengthSquared :: proc "c" (v: Vec2) -> f32 {
	return v.x * v.x + v.y * v.y
}

// Get the distance between two points
Distance :: proc "c" (a, b: Vec2) -> f32 {
	dx := b.x - a.x
	dy := b.y - a.y
	return math.sqrt(dx * dx + dy * dy)
}

// Get the distance squared between points
DistanceSquared :: proc "c" (a, b: Vec2) -> f32 {
	c := Vec2{b.x - a.x, b.y - a.y}
	return c.x * c.x + c.y * c.y
}

// Make a rotation using an angle in radians
MakeRot :: proc "c" (angle: f32) -> Rot {
	// todo determinism
	return {math.cos(angle), math.sin(angle)}
}

// Normalize rotation
NormalizeRot :: proc "c" (q: Rot) -> Rot {
	mag := math.sqrt(q.s * q.s + q.c * q.c)
	invMag := f32(mag > 0.0 ? 1.0 / mag : 0.0)
	return {q.c * invMag, q.s * invMag}
}

// Is this rotation normalized?
IsNormalized :: proc "c" (q: Rot) -> bool {
	// larger tolerance due to failure on mingw 32-bit
	qq := q.s * q.s + q.c * q.c
	return 1.0 - 0.0006 < qq && qq < 1 + 0.0006
}

// Normalized linear interpolation
// https://fgiesen.wordpress.com/2012/08/15/linear-interpolation-past-present-and-future/
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
Rot_GetAngle :: proc "c" (q: Rot) -> f32 {
	// todo determinism
	return math.atan2(q.s, q.c)
}

// Get the x-axis
Rot_GetXAxis :: proc "c" (q: Rot) -> Vec2 {
	return {q.c, q.s}
}

// Get the y-axis
Rot_GetYAxis :: proc "c" (q: Rot) -> Vec2 {
	return {-q.s, q.c}
}

// Multiply two rotations: q * r
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
RelativeAngle :: proc "c" (b, a: Rot) -> f32 {
	// sin(b - a) = bs * ac - bc * as
	// cos(b - a) = bc * ac + bs * as
	s := b.s * a.c - b.c * a.s
	c := b.c * a.c + b.s * a.s
	return math.atan2(s, c)
}

// Convert an angle in the range [-2*pi, 2*pi] into the range [-pi, pi]
UnwindAngle :: proc "c" (angle: f32) -> f32 {
	if angle < -pi {
		return angle + 2.0 * pi
	} else if angle > pi {
		return angle - 2.0 * pi
	}
	return angle
}

// Rotate a vector
RotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x - q.s * v.y, q.s * v.x + q.c * v.y}
}

// Inverse rotate a vector
InvRotateVector :: proc "c" (q: Rot, v: Vec2) -> Vec2 {
	return {q.c * v.x + q.s * v.y, -q.s * v.x + q.c * v.y}
}

// Transform a point (e.g. local space to world space)
TransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	x := (t.q.c * p.x - t.q.s * p.y) + t.p.x
	y := (t.q.s * p.x + t.q.c * p.y) + t.p.y
	return {x, y}
}

// Inverse transform a point (e.g. world space to local space)
InvTransformPoint :: proc "c" (t: Transform, p: Vec2) -> Vec2 {
	vx := p.x - t.p.x
	vy := p.y - t.p.y
	return {t.q.c * vx + t.q.s * vy, -t.q.s * vx + t.q.c * vy}
}

// v2 = A.q.Rot(B.q.Rot(v1) + B.p) + A.p
//    = (A.q * B.q).Rot(v1) + A.q.Rot(B.p) + A.p
MulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = MulRot(A.q, B.q)
	C.p = RotateVector(A.q, B.p) + A.p
	return
}

// v2 = A.q' * (B.q * v1 + B.p - A.p)
//    = A.q' * B.q * v1 + A.q' * (B.p - A.p)
InvMulTransforms :: proc "c" (A, B: Transform) -> (C: Transform) {
	C.q = InvMulRot(A.q, B.q)
	C.p = InvRotateVector(A.q, B.p-A.p)
	return
}

// Multiply a 2-by-2 matrix times a 2D vector
MulMV :: proc "c" (A: Mat22, v: Vec2) -> Vec2 {
	return A * v
}

// Get the inverse of a 2-by-2 matrix
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
AABB_Contains :: proc "c" (a, b: AABB) -> bool {
	(a.lowerBound.x <= b.lowerBound.x) or_return
	(a.lowerBound.y <= b.lowerBound.y) or_return
	(b.upperBound.x <= a.upperBound.x) or_return
	(b.upperBound.y <= a.upperBound.y) or_return
	return true
}

// Get the center of the AABB.
AABB_Center :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.lowerBound.x + a.upperBound.x), 0.5 * (a.lowerBound.y + a.upperBound.y)}
}

// Get the extents of the AABB (half-widths).
AABB_Extents :: proc "c" (a: AABB) -> Vec2 {
	return {0.5 * (a.upperBound.x - a.lowerBound.x), 0.5 * (a.upperBound.y - a.lowerBound.y)}
}

// Union of two AABBs
AABB_Union :: proc "c" (a, b: AABB) -> (c: AABB) {
	c.lowerBound.x = MinFloat(a.lowerBound.x, b.lowerBound.x)
	c.lowerBound.y = MinFloat(a.lowerBound.y, b.lowerBound.y)
	c.upperBound.x = MaxFloat(a.upperBound.x, b.upperBound.x)
	c.upperBound.y = MaxFloat(a.upperBound.y, b.upperBound.y)
	return
}

Float_IsValid :: proc "c" (a: f32) -> bool {
	math.is_nan(a) or_return
	math.is_inf(a) or_return
	return true
}

Vec2_IsValid :: proc "c" (v: Vec2) -> bool {
	(math.is_nan(v.x) || math.is_nan(v.y)) or_return
	(math.is_inf(v.x) || math.is_inf(v.y)) or_return
	return true
}

Rot_IsValid :: proc "c" (q: Rot) -> bool {
	(math.is_nan(q.s) || math.is_nan(q.c)) or_return
	(math.is_inf(q.s) || math.is_inf(q.c)) or_return
	return IsNormalized(q)
}

Normalize :: proc "c" (v: Vec2) -> Vec2 {
	length := Length(v)
	if length < 1e-23 {
		return Vec2_zero
	}
	invLength := 1 / length
	return invLength * v
}

NormalizeChecked :: proc "odin" (v: Vec2) -> Vec2 {
	length := Length(v)
	if length < 1e-23 {
		panic("zero-length Vec2")
	}
	invLength := 1 / length
	return invLength * v
}

GetLengthAndNormalize :: proc "c" (v: Vec2) -> (length: f32, vn: Vec2) {
	length = Length(v)
	if length < 1e-23 {
		return
	}
	invLength := 1 / length
	vn = invLength * v
	return
}
