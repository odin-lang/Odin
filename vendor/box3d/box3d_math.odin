package vendor_box3d

import "base:builtin"
import "core:math"
import "core:math/linalg"

DOUBLE_PRECISION :: false

// https://en.wikipedia.org/wiki/Pi
PI :: math.PI

// Convenience constant to convert from degrees to radians.
DEG_TO_RAD :: math.RAD_PER_DEG
// Convenience constant to convert from radians to degrees.
RAD_TO_DEG :: math.DEG_PER_RAD


// Minimum scale used for scaling collision meshes, etc.
MIN_SCALE :: 0.01

Vec2 :: [2]f32
Vec3 :: [3]f32

// Cosine and sine pair.
// This uses a custom implementation designed for cross-platform determinism.
CosSin :: struct {
	cosine: f32,
	sine:   f32,
}

Quat :: quaternion128

Transform :: struct {
	p: Vec3,
	q: Quat,
}

Pos :: [3]f64 when DOUBLE_PRECISION else [3]f32

WorldTransform :: struct {
	p: Pos,
	q: Quat,
}

Matrix3 :: matrix[3, 3]f32

// Axis aligned bounding box.
AABB :: struct {
	lowerBound: Vec3,
	upperBound: Vec3,
}

// A plane.
// separation = dot(normal, point) - offset
Plane :: struct {
	normal: Vec3,
	offset: f32,
}

Vec3_zero          :: Vec3{0.0, 0.0, 0.0}
Vec3_one           :: Vec3{1.0, 1.0, 1.0}
Vec3_axisX         :: Vec3{1.0, 0.0, 0.0}
Vec3_axisY         :: Vec3{0.0, 1.0, 0.0}
Vec3_axisZ         :: Vec3{0.0, 0.0, 1.0}
Quat_identity      :: Quat(1)
Transform_identity :: Transform{p={0, 0, 0}, q=1}
Mat3_zero          :: Matrix3(0)
Mat3_identity      :: Matrix3(1)

Pos_zero                :: Pos{0.0, 0.0, 0.0}
WorldTransform_identity :: WorldTransform{p={0, 0, 0}, q=1}



// @return the minimum of two integers.

MinInt :: builtin.min
MaxInt :: builtin.max
ClampInt :: builtin.clamp

// The closest points between to segments or infinite lines.
SegmentDistanceResult :: struct {
	point1:    Vec3,
	fraction1: f32,
	point2:    Vec3,
	fraction2: f32,
}


@(link_prefix="b3", default_calling_convention="c", require_results)
foreign lib {
	// @return is this float valid (finite and not NaN).
	IsValidFloat :: proc(a: f32) -> bool ---


	// Compute an approximate arctangent in the range [-pi, pi]
	// This is hand coded for cross-platform determinism. The atan2f
	// function in the standard library is not cross-platform deterministic.
	//	Accurate to around 0.0023 degrees.
	Atan2 :: proc(y, x: f32) -> f32 ---

	// Compute the cosine and sine of an angle in radians. Implemented
	// for cross-platform determinism.
	ComputeCosSin :: proc(radians: f32) -> CosSin ---

	// Compute the closest point on the segment a-b to the target q.
	PointToSegmentDistance :: proc(a, b: Vec3, q: Vec3) -> Vec3 ---

	// Compute the closest points on two infinite lines.
	LineDistance :: proc(p1, d1: Vec3, p2, d2: Vec3) -> SegmentDistanceResult ---

	// Compute the closest points on two line segments.
	SegmentDistance :: proc(p1, q1: Vec3, p2, q2: Vec3) -> SegmentDistanceResult ---

	// Is this a valid vector? Not NaN or infinity.
	IsValidVec3 :: proc(a: Vec3) -> bool ---

	// Is this a valid quaternion? Not NaN or infinity. Is normalized.
	IsValidQuat :: proc(q: Quat) -> bool ---

	// Is this a valid transform? Not NaN or infinity. Is normalized.
	IsValidTransform :: proc(a: Transform) -> bool ---

	// Is this a valid matrix? Not NaN or infinity.
	IsValidMatrix3 :: proc(a: Matrix3) -> bool ---

	// Is this a valid bounding box? Not Nan or infinity. Upper bound greater than or equal to lower bound.
	IsValidAABB :: proc(a: AABB) -> bool ---

	// Is this AABB reasonably close to the origin? See B3_HUGE.
	IsBoundedAABB :: proc(a: AABB) -> bool ---

	// Is this AABB valid and reasonable?
	IsSaneAABB :: proc(a: AABB) -> bool ---

	// Is this a valid plane? Normal is a unit vector. Not Nan or infinity.
	IsValidPlane :: proc(a: Plane) -> bool ---

	// Is this a valid world position? Not NaN or infinity.
	IsValidPosition :: proc(p: Pos) -> bool ---

	// Is this a valid world transform? Not NaN or infinity. Rotation is normalized.
	IsValidWorldTransform :: proc(t: WorldTransform) -> bool ---

	// Get the inertia tensor of an offset point.
	// https://en.wikipedia.org/wiki/Parallel_axis_theorem
	Steiner :: proc(mass: f32, origin: Vec3) -> Matrix3 ---

	// Extract a quaternion from a rotation matrix.
	MakeQuatFromMatrix :: proc(#by_ptr m: Matrix3) -> Quat ---

	// Find a quaternion that rotates one vector to another.
	ComputeQuatBetweenUnitVectors :: proc(v1, v2: Vec3) -> Quat ---



}

AbsFloat :: builtin.abs
MinFloat :: builtin.min
MaxFloat :: builtin.max
ClampFloat :: builtin.clamp
LerpFloat :: math.lerp

// Convert any angle into the range [-pi, pi].
@(require_results)
UnwindAngle :: #force_inline proc "c" (radians: f32) -> f32 {
	// Assuming this is deterministic
	return math.remainder(radians, 2.0 * PI)
}

// Vector dot product.
Dot :: linalg.dot
Length :: linalg.length
LengthSquared :: linalg.length2


// Distance between two points.
@(require_results)
Distance :: #force_inline proc "c" (a, b: Vec3) -> f32 {
	dv := b - a
	return Length(dv)
}

// Squared distance between two points.
@(require_results)
DistanceSquared :: #force_inline proc "c" (a, b: Vec3) -> f32 {
	dv := b - a
	return LengthSquared(dv)
}

FLT_EPSILON :: 1.1920928955078125e-07 /* 0x0.000002p0 */


// Normalize a vector. Returns a zero vector if the input vector is very small.
@(require_results)
Normalize :: proc "c" (a: Vec3) -> Vec3 {
	lengthSquared := a.x * a.x + a.y * a.y + a.z * a.z

	if lengthSquared > 1000.0 * min(f32) {
		s := 1.0 / math.sqrt(lengthSquared)
		return Vec3{ s * a.x, s * a.y, s * a.z }
	}

	return Vec3{0.0, 0.0, 0.0}
}

// Normalize a vector and return the length. Returns a zero vector
// if the input is very small.
@(require_results)
GetLengthAndNormalize :: proc "c" (a: Vec3) -> (length: f32, n: Vec3) {
	length = Length(a)
	if length < FLT_EPSILON {
		return
	}

	invLength := 1.0 / length
	n = {invLength * a.x, invLength * a.y, invLength * a.z}
	return
}

// Get a unit vector that is perpendicular to the supplied vector.
@(require_results)
Perp :: proc "c" (a: Vec3) -> Vec3 {
	// Suppose vector a has all equal components and is a unit vector: a = (s, s, s)
	// Then 3*s*s = 1, s = sqrt(1/3) = 0.57735. This means that at least one component
	// of a unit vector must be greater or equal to 0.57735.
	p: Vec3
	if a.x < -0.5 || 0.5 < a.x {
		p = {a.y, -a.x, 0.0}
	} else {
		p = {0.0, a.z, -a.y}
	}

	return Normalize(p)
}

// Is a vector normalized? In other words, does it have unit length?
@(require_results)
IsNormalized :: proc "c" (a: Vec3) -> bool {
	aa := Dot(a, a)
	return AbsFloat(1.0 - aa) < 100.0 * FLT_EPSILON
}
// https://en.wikipedia.org/wiki/Cross_product
Cross :: linalg.cross

// Linearly interpolate between two vectors.
Lerp :: linalg.lerp

// Blend two vectors: s * a + t * b
@(require_results)
Blend2 :: proc "c" (s: f32, a: Vec3, t: f32, b: Vec3) -> Vec3 {
	return {
		s * a.x + t * b.x,
		s * a.y + t * b.y,
		s * a.z + t * b.z,
	}
}

// Component-wise absolute value.
Abs :: linalg.abs

// Component-wise -1 or 1 (1 if zero).
Sign :: linalg.sign

// Component-wise minimum value.
Min :: linalg.min

// Component-wise maximum value.
Max :: linalg.max

// Component-wise clamped value.
Clamp :: linalg.clamp

// Create a safe scaling value for scaling collision. This allows
// negative scale, but keeps scale sufficiently far from zero.
@(require_results)
SafeScale :: proc "c" (a: Vec3) -> Vec3 {
	absScale := Abs(a)
	minScale := Vec3{MIN_SCALE, MIN_SCALE, MIN_SCALE}
	safeScale := Sign(a) * Max(absScale, minScale)
	return safeScale
}

// Does the supplied quaternion have unit length?
@(require_results)
IsNormalizedQuat :: proc "c" (q: Quat)  -> bool {
	qq := q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
	return 1.0 - 20.0 * FLT_EPSILON < qq && qq < 1.0 + 20.0 * FLT_EPSILON
}

// Rotate a vector.
@(require_results)
RotateVector :: proc "c" (q: Quat, v: Vec3) -> Vec3 {
	// v + 2 * cross(q.xyz, cross(q.xyz, v) + q.w * v)
	// B3_ASSERT(IsNormalizedQuat(q));
	t1 := Cross(q.xyz, v)
	t2 := t1 * q.w + v
	t3 := Cross(q.xyz, t2)
	return v * 2.0 + t3
}

// Inverse rotate a vector.
@(require_results)
InvRotateVector :: proc "c" (q: Quat, v: Vec3) -> Vec3 {
	// v + 2 * cross(q.xyz, cross(q.xyz, v) - q.w * v)
	// B3_ASSERT(IsNormalizedQuat(q));
	t1 := Cross(q.xyz, v)
	t2 := t1 * q.w - v
	t3 := Cross(q.xyz, t2)
	return v * 2.0 + t3
}

// Compute dot product of two quaternions. Useful for polarity tests.
@(require_results)
DotQuat :: linalg.dot

// Multiply two quaternions.
@(require_results)
MulQuat :: proc "c" (q1, q2: Quat) -> Quat {
	return q1 * q2
}

// Compute a relative quaternion.
// inv(q1) * q2
@(require_results)
InvMulQuat :: proc "c" (q1, q2: Quat) -> Quat {
	t1 := Cross(q2.xyz, q1.xyz)
	t2 := t1 * q1.w + q2.xyz
	t3 := t2 * q2.w - q1.xyz
	return quaternion(x=t3.x, y=t3.y, z=t3.z, w=q1.w * q2.w + Dot(q1.xyz, q2.xyz))
}

// Quaternion conjugate (cheap inverse).
Conjugate :: builtin.conj

// Component-wise quaternion negation.
@(require_results)
NegateQuat :: proc "c" (q: Quat) -> Quat {
	return -q
}

// Normalize a quaternion.
@(require_results)
NormalizeQuat :: proc "c" (q: Quat) -> Quat {
	lengthSq := DotQuat(q, q)
	if lengthSq > 1000.0 * min(f32) {
		s := 1.0 / math.sqrt(lengthSq)
		return Quat(s) * q
	}

	return Quat_identity
}

// Make a quaternion that is equivalent to rotating around an axis by a specified angle.
@(require_results)
MakeQuatFromAxisAngle :: proc "c" (axis: Vec3, radians: f32) -> Quat {
	ASSERT(IsNormalized(axis))
	cs := ComputeCosSin(0.5 * radians)
	return quaternion(x=cs.sine * axis.x, y=cs.sine * axis.y, z=cs.sine * axis.z, w=cs.cosine)
}

// Get the axis and angle from a quaternion. Assumes the quaternion is normalized.
@(require_results)
GetAxisAngle :: proc "c" (q: Quat) -> (radians: f32, axis: Vec3) {
	length := math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z)
	radians = 2.0 * Atan2(length, q.w)
	if length > 0.0 {
		invLength := 1.0 / length
		axis = {invLength * q.x, invLength * q.y, invLength * q.z}
	}
	return
}

// Get the angle for a quaternion in radians
@(require_results)
GetQuatAngle :: proc "c" (q: Quat) -> f32 {
	length := math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z)
	return 2.0 * Atan2(length, q.w)
}

// Twist angle around the z-axis, used for twist limit and revolute angle limit
@(require_results)
GetTwistAngle :: proc "c" (q: Quat) -> f32 {
	// Account for polarity to keep the twist angle in range.
	// This is simpler than asking the user to check polarity or unwinding.
	twist := q.w < 0.0 ? Atan2(-q.z, -q.w) : Atan2(q.z, q.w)
	twist *= 2.0
	ASSERT(-PI <= twist && twist <= PI)
	return twist
}

// Swing angle used for cone limit
@(require_results)
GetSwingAngle :: proc "c" (q: Quat) -> f32 {
	// Polarity should not matter because all terms are squared.
	x := math.sqrt(q.z * q.z + q.w * q.w)
	y := math.sqrt(q.x * q.x + q.y * q.y)
	swing := 2.0 * Atan2(y, x)
	ASSERT(0.0 <= swing && swing <= PI)
	return swing
}

// Linearly interpolate and normalize between two quaternions
@(require_results)
NLerp :: proc "c" (q1, q2: Quat, alpha: f32) -> Quat {
	VALIDATE(0.0 <= alpha && alpha <= 1.0)
	q1 := q1
	if DotQuat(q1, q2) < 0.0 {
		q1 = -q1
	}

	q: Quat
	q.xyz = Lerp(q1.xyz, q2.xyz, alpha)
	q.w = (1.0 - alpha) * q1.w + alpha * q2.w

	return NormalizeQuat(q)
}

// Multiply two transforms. If the result is applied to a point p local to frame B,
// the transform would first convert p to a point local to frame A, then into a point
// in the world frame. This is useful if frame B is a child of frame A.
@(require_results)
MulTransforms :: proc "c" (a, b: Transform) -> (out: Transform) {
	out.p = RotateVector(a.q, b.p) + a.p
	out.q = a.q * b.q
	return
}

// Creates a transform that converts a local point in frame B to a local point in frame A.
// This is useful for transforming points between the local spaces of two frames that are
// in world space.
@(require_results)
InvMulTransforms :: #force_inline proc "c" (a, b: Transform) -> (out: Transform) {
	out.p = InvRotateVector(a.q, b.p - a.p)
	out.q = InvMulQuat(a.q, b.q)
	return
}

// Get the inverse of a transform.
@(require_results)
InvertTransform :: proc "c" (t: Transform) -> (out: Transform) {
	out.p = InvRotateVector(t.q, -t.p)
	out.q = Conjugate(t.q)
	return
}

// Transform a point.
@(require_results)
TransformPoint :: proc "c" (t: Transform, v: Vec3) -> Vec3 {
	rv := RotateVector(t.q, v)
	return rv + t.p
}

// Inverse transform a point.
@(require_results)
InvTransformPoint :: proc "c" (t: Transform, v: Vec3) -> Vec3 {
	return InvRotateVector(t.q, v - t.p)
}

// World position boundary. These cross between the double precision world space at the public
// boundary and the float interior. One set of bodies serves both modes: the typedefs collapse
// the types in float mode and the explicit float casts become no-ops.

// Convert a vector to a world position.
@(require_results)
ToPos :: proc "c" (v: Vec3) -> Pos {
	T :: type_of(Pos{}.x)
	return {T(v.x), T(v.y), T(v.z)}
}

// Lossy conversion of a world position to a float vector.
@(require_results)
ToVec3 :: proc "c" (p: Pos) -> Vec3 {
	return {f32(p.x), f32(p.y), f32(p.z)}
}

// Narrow a world coordinate to float, rounding toward negative infinity. Use with
// RoundUpFloat to build a conservative float box that always contains the double bounds,
// where plain rounding far from the origin could clip. nextafterf is an exact IEEE operation,
// so this is cross-platform deterministic. With large world mode off this is a plain conversion.
@(require_results)
RoundDownFloat :: proc "c" (x: f64) -> f32 {
	when DOUBLE_PRECISION {
		f := f32(x)
		return f64(f) > f64(x) ? math.nextafter(f, -max(f32)) : f
	} else {
		return f32(x)
	}
}

// Narrow a world coordinate to float, rounding toward positive infinity.
@(require_results)
RoundUpFloat :: proc "c" (x: f32) -> f32 {
	when DOUBLE_PRECISION {
		f := f32(x)
		return f64(f) < f64(x) ? math.nextafter(f, max(f32)) : f
	} else {
		return f32(x)
	}
}

// p + d
@(require_results)
OffsetPos :: proc "c" (p: Pos, d: Vec3) -> Pos {
	T :: type_of(Pos{}.x)
	return {p.x + T(d.x), p.y + T(d.y), p.z + T(d.z)}
}

// World position interpolation for sweeps and sampling.
LerpPosition :: linalg.lerp

// Transform a local point to a world position. Rotation in float, translation in double.
@(require_results)
TransformWorldPoint :: proc "c" (t: WorldTransform, p: Vec3) -> Pos {
	T :: type_of(Pos{}.x)
	r := RotateVector(t.q, p)
	return {T(t.p.x + r.x), T(t.p.y + r.y), T(t.p.z + r.z)}
}

// Transform a world position to a local point. One double subtraction, then float.
@(require_results)
InvTransformWorldPoint :: proc "c" (t: WorldTransform, p: Pos) -> Vec3 {
	d := Vec3{f32(p.x - t.p.x), f32(p.y - t.p.y), f32(p.z - t.p.z)}
	return InvRotateVector(t.q, d)
}

// Relative transform of frame B in frame A. The narrow phase boundary.
@(require_results)
InvMulWorldTransforms :: proc "c" (A, B: WorldTransform) -> (C: Transform) {
	C.q = InvMulQuat(A.q, B.q)
	d := Vec3{f32(B.p.x - A.p.x), f32(B.p.y - A.p.y), f32(B.p.z - A.p.z)}
	C.p = InvRotateVector(A.q, d)
	return
}

// Compose a world transform with a local transform.
@(require_results)
MulWorldTransforms :: proc "c" (A: WorldTransform, B: Transform) -> (C: WorldTransform) {
	T :: type_of(Pos{}.x)
	C.q = A.q * B.q
	r := RotateVector(A.q, B.p)
	C.p = Pos{T(A.p.x + r.x), T(A.p.y + r.y), T(A.p.z + r.z)}
	return
}

// Shift a world transform into the frame of a base position.
@(require_results)
ToRelativeTransform :: proc "c" (t: WorldTransform, base: Pos) -> (r: Transform) {
	r.q = t.q
	r.p = {f32(t.p.x - base.x), f32(t.p.y - base.y), f32(t.p.z - base.z)}
	return
}

// Promote a float transform to a world transform. Lossless.
@(require_results)
MakeWorldTransform :: proc "c" (t: Transform) -> (w: WorldTransform) {
	w.p = ToPos(t.p)
	w.q = t.q
	return
}

// Translate a local AABB by a world origin, rounding outward so the float box always contains
// the double box. Far from the origin a plain conversion could clip a shape out of its own box.
// In float mode the origin is float and the rounding is a no-op.
@(require_results)
OffsetAABB :: proc "c" (localBox: AABB, origin: Pos) -> (out: AABB) {
	out.lowerBound.x = RoundDownFloat(f64(origin.x + localBox.lowerBound.x))
	out.lowerBound.y = RoundDownFloat(f64(origin.y + localBox.lowerBound.y))
	out.lowerBound.z = RoundDownFloat(f64(origin.z + localBox.lowerBound.z))
	out.upperBound.x = RoundUpFloat(f32(origin.x + localBox.upperBound.x))
	out.upperBound.y = RoundUpFloat(f32(origin.y + localBox.upperBound.y))
	out.upperBound.z = RoundUpFloat(f32(origin.z + localBox.upperBound.z))
	return
}

// Compute the determinant of a 3-by-3 matrix.
Det :: linalg.determinant

// Matrix transpose.
Transpose :: linalg.transpose

// General matrix inverse.
@(require_results)
InvertMatrix :: proc "c" (m: Matrix3) -> Matrix3 {
	det := Det(m)
	if AbsFloat(det) > 1000.0 * min(f32) {
		invDet := 1.0 / det
		out: Matrix3
		out[0] = invDet * Cross(m[1], m[2])
		out[1] = invDet * Cross(m[2], m[0])
		out[2] = invDet * Cross(m[0], m[1])
		return Transpose(out)
	}
	return Mat3_zero
}

// Solve a matrix equation.
// @return inv(m) * a
@(require_results)
Solve3 :: proc "c" (m: Matrix3, a: Vec3) -> Vec3 {
	return InvertMatrix(m) * a
}

// Invert a matrix.
@(require_results)
InvertT :: proc "c" (m: Matrix3) -> Matrix3 {
	det := Det(m)
	if AbsFloat(det) > 1000.0 * min(f32) {
		invDet := 1.0 / det
		out: Matrix3
		out[0] = invDet * Cross(m[1], m[2])
		out[1] = invDet * Cross(m[2], m[0])
		out[2] = invDet * Cross(m[0], m[1])
		return out
	}
	return Mat3_zero
}

// Get the component-wise absolute value of a matrix.
@(require_results)
AbsMatrix3 :: proc "c" (m: Matrix3) -> (out: Matrix3) {
	out[0] = Abs(m[0])
	out[1] = Abs(m[1])
	out[2] = Abs(m[2])
	return
}

// Make a matrix from a quaternion. This is useful if you need to
// rotate many vectors.
// The force inline improves the performance of ShapeDistance.
@(require_results)
MakeMatrixFromQuat :: proc "c" (q: Quat) -> (out: Matrix3) {
	xx := q.x * q.x
	yy := q.y * q.y
	zz := q.z * q.z
	xy := q.x * q.y
	xz := q.x * q.z
	xw := q.x * q.w
	yz := q.y * q.z
	yw := q.y * q.w
	zw := q.z * q.w

	out[0] = { 1.0 - 2.0 * (yy + zz), 2.0 * (xy + zw), 2.0 * (xz - yw) }
	out[1] = { 2.0 * (xy - zw), 1.0 - 2.0 * (xx + zz), 2.0 * (yz + xw) }
	out[2] = { 2.0 * (xz + yw), 2.0 * (yz - xw), 1.0 - 2.0 * (xx + yy) }
	return
}

// Get the AABB of a point cloud.
@(require_results)
MakeAABB :: proc "c" (points: []Vec3, radius: f32) -> (a: AABB) #no_bounds_check {
	ASSERT(len(points) > 0)
	a = AABB{points[0], points[0]}
	for i in 1..<len(points) {
		a.lowerBound = Min(a.lowerBound, points[i])
		a.upperBound = Max(a.upperBound, points[i])
	}
	a.lowerBound = a.lowerBound - radius
	a.upperBound = a.upperBound + radius
	return
}

// Does a fully contain b?
@(require_results)
AABB_Contains :: proc "c" (a, b: AABB) -> bool {
	switch {
	case a.lowerBound.x > b.lowerBound.x || b.upperBound.x > a.upperBound.x:
		return false
	case a.lowerBound.y > b.lowerBound.y || b.upperBound.y > a.upperBound.y:
		return false
	case a.lowerBound.z > b.lowerBound.z || b.upperBound.z > a.upperBound.z:
		return false
	}
	return true
}

// Get the surface area of an axis-aligned bounding box.
@(require_results)
AABB_Area :: proc "c" (a: AABB) -> f32 {
	delta := a.upperBound - a.lowerBound
	return 2.0 * (delta.x * delta.y + delta.y * delta.z + delta.z * delta.x)
}

// Get the center of an axis-aligned bounding box.
@(require_results)
AABB_Center :: proc "c" (a: AABB) -> Vec3 {
	return 0.5 * (a.upperBound + a.lowerBound)
}

// Get the extents (half-widths) of an axis-aligned bounding box.
@(require_results)
AABB_Extents :: proc "c" (a: AABB) -> Vec3 {
	return 0.5 * (a.upperBound - a.lowerBound)
}

// Get the union of two axis-aligned bounding boxes.
@(require_results)
AABB_Union :: proc "c" (a, b: AABB) -> (out: AABB) {
	out.lowerBound = Min(a.lowerBound, b.lowerBound)
	out.upperBound = Max(a.upperBound, b.upperBound)
	return
}

// Add uniform padding to an axis-aligned bounding box.
@(require_results)
AABB_Inflate :: proc "c" (a: AABB, extension: f32) -> (out: AABB) {
	radius := Vec3{extension, extension, extension}

	out.lowerBound = a.lowerBound - radius
	out.upperBound = a.upperBound + radius
	return
}

// Do two axis-aligned boxes overlap?
@(require_results)
AABB_Overlaps :: proc "c" (a, b: AABB) -> bool {
	// No intersection if separated along one axis
	switch {
	case a.upperBound.x < b.lowerBound.x || a.lowerBound.x > b.upperBound.x:
		return false
	case a.upperBound.y < b.lowerBound.y || a.lowerBound.y > b.upperBound.y:
		return false
	case a.upperBound.z < b.lowerBound.z || a.lowerBound.z > b.upperBound.z:
		return false
	}

	// Overlapping on all axis means bounds are intersecting
	return true
}

// Transform an axis-aligned bounding box. This can create a larger box
// than if you recomputed the AABB of the original shape with the transform
// applied.
@(require_results)
AABB_Transform :: proc "c" (transform: Transform, a: AABB) -> AABB {
	center := TransformPoint(transform, AABB_Center(a))
	m := MakeMatrixFromQuat(transform.q)
	extent := AbsMatrix3(m) * AABB_Extents(a)
	return AABB{center - extent, center + extent}
}

// Get the closest point on an axis-aligned bounding box.
@(require_results)
ClosestPointToAABB :: proc "c" (point: Vec3, a: AABB) -> Vec3 {
	return Clamp(point, a.lowerBound, a.upperBound)
}
