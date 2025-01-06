package raylib

import "core:math"
import "core:math/linalg"

EPSILON :: 0.000001


//----------------------------------------------------------------------------------
// Module Functions Definition - Utils math
//----------------------------------------------------------------------------------


// Clamp float value
@(require_results)
Clamp :: proc "c" (value: f32, min, max: f32) -> f32 {
	return clamp(value, min, max)
}

// Calculate linear interpolation between two floats
@(require_results)
Lerp :: proc "c" (start, end: f32, amount: f32) -> f32 {
	return start*(1-amount) + end*amount
}

// Normalize input value within input range
@(require_results)
Normalize :: proc "c" (value: f32, start, end: f32) -> f32 {
	return (value - start) / (end - start)
}

// Remap input value within input range to output range
@(require_results)
Remap :: proc "c" (value: f32, inputStart, inputEnd: f32, outputStart, outputEnd: f32) -> f32 {
	return (value - inputStart)/(inputEnd - inputStart)*(outputEnd - outputStart) + outputStart
}

// Wrap input value from min to max
@(require_results)
Wrap :: proc "c" (value: f32, min, max: f32) -> f32 {
	return value - (max - min)*math.floor((value - min)/(max - min))
}

// Check whether two given floats are almost equal
@(require_results)
FloatEquals :: proc "c" (x, y: f32) -> bool {
	return abs(x - y) <= EPSILON*fmaxf(1.0, fmaxf(abs(x), abs(y)))
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Vector2 math
//----------------------------------------------------------------------------------


// Vector with components value 0.0
@(require_results, deprecated="Prefer Vector2(0)")
Vector2Zero :: proc "c" () -> Vector2 {
	return Vector2(0)
}
// Vector with components value 1.0
@(require_results, deprecated="Prefer Vector2(1)")
Vector2One :: proc "c" () -> Vector2 {
	return Vector2(1)
}
// Add two vectors (v1 + v2)
@(require_results, deprecated="Prefer v1 + v2")
Vector2Add :: proc "c" (v1, v2: Vector2) -> Vector2 {
	return v1 + v2
}
// Add vector and float value
@(require_results, deprecated="Prefer v + value")
Vector2AddValue :: proc "c" (v: Vector2, value: f32) -> Vector2 {
	return v + value
}
// Subtract two vectors (v1 - v2)
@(require_results, deprecated="Prefer a - b")
Vector2Subtract :: proc "c" (a, b: Vector2) -> Vector2 {
	return a - b
}
// Subtract vector by float value
@(require_results, deprecated="Prefer v + value")
Vector2SubtractValue :: proc "c" (v: Vector2, value: f32) -> Vector2 {
	return v - value
}
// Calculate vector length
@(require_results)
Vector2Length :: proc "c" (v: Vector2) -> f32 {
	return linalg.length(v)
}
// Calculate vector square length
@(require_results)
Vector2LengthSqr :: proc "c" (v: Vector2) -> f32 {
	return linalg.length2(v)
}
// Calculate two vectors dot product
@(require_results)
Vector2DotProduct :: proc "c" (v1, v2: Vector2) -> f32 {
	return linalg.dot(v1, v2)
}
// Calculate distance between two vectors
@(require_results)
Vector2Distance :: proc "c" (v1, v2: Vector2) -> f32 {
	return linalg.distance(v1, v2)
}
// Calculate square distance between two vectors
@(require_results)
Vector2DistanceSqrt :: proc "c" (v1, v2: Vector2) -> f32 {
	return linalg.length2(v2-v1)
}
// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)
@(require_results)
Vector2Angle :: proc "c" (v1, v2: Vector2) -> f32 {
	return linalg.angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle
@(require_results)
Vector2LineAngle :: proc "c" (start, end: Vector2) -> f32 {
	// TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
	return -math.atan2(end.y - start.y, end.x - start.x)
}

// Scale vector (multiply by value)
@(require_results, deprecated="Prefer v * scale")
Vector2Scale :: proc "c" (v: Vector2, scale: f32) -> Vector2 {
	return v * scale
}
// Multiply vector by vector
@(require_results, deprecated="Prefer v1 * v2")
Vector2Multiply :: proc "c" (v1, v2: Vector2) -> Vector2 {
	return v1 * v2
}
// Negate vector
@(require_results, deprecated="Prefer -v")
Vector2Negate :: proc "c" (v: Vector2) -> Vector2 {
	return -v
}
// Divide vector by vector
@(require_results, deprecated="Prefer v1 / v2")
Vector2Divide :: proc "c" (v1, v2: Vector2) -> Vector2 {
	return v1 / v2
}
// Normalize provided vector
@(require_results)
Vector2Normalize :: proc "c" (v: Vector2) -> Vector2 {
	return linalg.normalize0(v)
}
// Transforms a Vector2 by a given Matrix
@(require_results)
Vector2Transform :: proc "c" (v: Vector2, m: Matrix) -> Vector2 {
	v4 := Vector4{v.x, v.y, 0, 1}
	return (m * v4).xy
}
// Calculate linear interpolation between two vectors
@(require_results, deprecated="Prefer = linalg.lerp(v1, v2, amount)")
Vector2Lerp :: proc "c" (v1, v2: Vector2, amount: f32) -> Vector2 {
	return linalg.lerp(v1, v2, Vector2(amount))
}
// Calculate reflected vector to normal
@(require_results, deprecated="Prefer = linalg.reflect(v, normal)")
Vector2Reflect :: proc "c" (v, normal: Vector2) -> Vector2 {
	return linalg.reflect(v, normal)
}
// Rotate vector by angle
@(require_results)
Vector2Rotate :: proc "c" (v: Vector2, angle: f32) -> Vector2 {
	c, s := math.cos(angle), math.sin(angle)

	return Vector2{
		v.x*c - v.y*s,
		v.x*s + v.y*c,
	}
}

// Move Vector towards target
@(require_results)
Vector2MoveTowards :: proc "c" (v, target: Vector2, maxDistance: f32) -> Vector2 {
	dv := target - v
	value := linalg.dot(dv, dv)

	if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
		return target
	}

	dist := math.sqrt(value)
	return v + dv/dist*maxDistance
}

// Invert the given vector
@(require_results, deprecated="Prefer 1.0/v")
Vector2Invert :: proc "c" (v: Vector2) -> Vector2 {
	return 1.0/v
}

// Clamp the components of the vector between
// min and max values specified by the given vectors
@(require_results)
Vector2Clamp :: proc "c" (v: Vector2, min, max: Vector2) -> Vector2 {
	return Vector2{
		clamp(v.x, min.x, max.x),
		clamp(v.y, min.y, max.y),
	}
}

// Clamp the magnitude of the vector between two min and max values
@(require_results)
Vector2ClampValue :: proc "c" (v: Vector2, min, max: f32) -> Vector2 {
	result := v

	length := linalg.dot(v, v)
	if length > 0 {
		length = math.sqrt(length)
		scale := f32(1)
		if length < min {
			scale = min/length
		} else if length > max {
			scale = max/length
		}
		result = v*scale
	}
	return result
}

@(require_results)
Vector2Equals :: proc "c" (p, q: Vector2) -> bool {
	return FloatEquals(p.x, q.x) &&
	       FloatEquals(p.y, q.y)
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Vector3 math
//----------------------------------------------------------------------------------


// Vector with components value 0.0
@(require_results, deprecated="Prefer Vector3(0)")
Vector3Zero :: proc "c" () -> Vector3 {
	return Vector3(0)
}
// Vector with components value 1.0
@(require_results, deprecated="Prefer Vector3(1)")
Vector3One :: proc "c" () -> Vector3 {
	return Vector3(1)
}
// Add two vectors (v1 + v2)
@(require_results, deprecated="Prefer v1 + v2")
Vector3Add :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return v1 + v2
}
// Add vector and float value
@(require_results, deprecated="Prefer v + value")
Vector3AddValue :: proc "c" (v: Vector3, value: f32) -> Vector3 {
	return v + value
}
// Subtract two vectors (v1 - v2)
@(require_results, deprecated="Prefer a - b")
Vector3Subtract :: proc "c" (a, b: Vector3) -> Vector3 {
	return a - b
}
// Subtract vector by float value
@(require_results, deprecated="Prefer v + value")
Vector3SubtractValue :: proc "c" (v: Vector3, value: f32) -> Vector3 {
	return v - value
}
// Calculate vector length
@(require_results)
Vector3Length :: proc "c" (v: Vector3) -> f32 {
	return linalg.length(v)
}
// Calculate vector square length
@(require_results)
Vector3LengthSqr :: proc "c" (v: Vector3) -> f32 {
	return linalg.length2(v)
}
// Calculate two vectors dot product
@(require_results)
Vector3DotProduct :: proc "c" (v1, v2: Vector3) -> f32 {
	return linalg.dot(v1, v2)
}
// Calculate two vectors dot product
@(require_results)
Vector3CrossProduct :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return linalg.cross(v1, v2)
}
// Calculate distance between two vectors
@(require_results)
Vector3Distance :: proc "c" (v1, v2: Vector3) -> f32 {
	return linalg.distance(v1, v2)
}
// Calculate square distance between two vectors
@(require_results)
Vector3DistanceSqrt :: proc "c" (v1, v2: Vector3) -> f32 {
	return linalg.length2(v2-v1)
}
// Calculate angle between two vectors
// NOTE: Angle is calculated from origin point (0, 0)
@(require_results)
Vector3Angle :: proc "c" (v1, v2: Vector3) -> f32 {
	return linalg.angle_between(v1, v2)
}

// Calculate angle defined by a two vectors line
// NOTE: Parameters need to be normalized
// Current implementation should be aligned with glm::angle
@(require_results)
Vector3LineAngle :: proc "c" (start, end: Vector3) -> f32 {
	// TODO(10/9/2023): Currently angles move clockwise, determine if this is wanted behavior
	return -math.atan2(end.y - start.y, end.x - start.x)
}

// Scale vector (multiply by value)
@(require_results, deprecated="Prefer v * scale")
Vector3Scale :: proc "c" (v: Vector3, scale: f32) -> Vector3 {
	return v * scale
}
// Multiply vector by vector
@(require_results, deprecated="Prefer v1 * v2")
Vector3Multiply :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return v1 * v2
}
// Negate vector
@(require_results, deprecated="Prefer -v")
Vector3Negate :: proc "c" (v: Vector3) -> Vector3 {
	return -v
}
// Divide vector by vector
@(require_results, deprecated="Prefer v1 / v2")
Vector3Divide :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return v1 / v2
}
// Normalize provided vector
@(require_results)
Vector3Normalize :: proc "c" (v: Vector3) -> Vector3 {
	return linalg.normalize0(v)
}

// Calculate the projection of the vector v1 on to v2
@(require_results)
Vector3Project :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return linalg.projection(v1, v2)
}

// Calculate the rejection  of the vector v1 on to v2
@(require_results)
Vector3Reject :: proc "c" (v1, v2: Vector3) -> Vector3 {
	mag := linalg.dot(v1, v2)/linalg.dot(v2, v2)
	return v1 - v2*mag
}

// Orthonormalize provided vectors
// Makes vectors normalized and orthogonal to each other
// Gram-Schmidt function implementation
Vector3OrthoNormalize :: proc "c" (v1, v2: ^Vector3) {
	v1^ = linalg.normalize0(v1^)
	v3 := linalg.normalize0(linalg.cross(v1^, v2^))
	v2^ = linalg.cross(v3, v1^)
}

// Transform a vector by quaternion rotation
@(require_results)
Vector3RotateByQuaternion :: proc "c" (v: Vector3, q: Quaternion) -> Vector3 {
	return linalg.mul(q, v)
}

// Rotates a vector around an axis
@(require_results)
Vector3RotateByAxisAngle :: proc "c" (v: Vector3, axis: Vector3, angle: f32) -> Vector3 {
	axis, angle := axis, angle

	axis = linalg.normalize0(axis)

	angle *= 0.5
	a := math.sin(angle)
	b := axis.x*a
	c := axis.y*a
	d := axis.z*a
	a = math.cos(angle)
	w := Vector3{b, c, d}

	wv := linalg.cross(w, v)
	wwv := linalg.cross(w, wv)

	a *= 2
	wv *= a

	wwv *= 2

	return v + wv + wwv

}

// Transforms a Vector3 by a given Matrix
@(require_results)
Vector3Transform :: proc "c" (v: Vector3, m: Matrix) -> Vector3 {
	v4 := Vector4{v.x, v.y, v.z, 1}
	return (m * v4).xyz
}
// Calculate linear interpolation between two vectors
@(require_results, deprecated="Prefer = linalg.lerp(v1, v2, amount)")
Vector3Lerp :: proc "c" (v1, v2: Vector3, amount: f32) -> Vector3 {
	return linalg.lerp(v1, v2, Vector3(amount))
}
// Calculate reflected vector to normal
@(require_results, deprecated="Prefer = linalg.reflect(v, normal)")
Vector3Reflect :: proc "c" (v, normal: Vector3) -> Vector3 {
	return linalg.reflect(v, normal)
}
// Compute the direction of a refracted ray
// v: normalized direction of the incoming ray
// n: normalized normal vector of the interface of two optical media
// r: ratio of the refractive index of the medium from where the ray comes
//    to the refractive index of the medium on the other side of the surface
@(require_results, deprecated="Prefer = linalg.refract(v, n, r)")
Vector3Refract :: proc "c" (v, n: Vector3, r: f32) -> Vector3 {
	return linalg.refract(v, n, r)
}

// Move Vector towards target
@(require_results)
Vector3MoveTowards :: proc "c" (v, target: Vector3, maxDistance: f32) -> Vector3 {
	dv := target - v
	value := linalg.dot(dv, dv)

	if value == 0 || (maxDistance >= 0 && value <= maxDistance*maxDistance) {
		return target
	}

	dist := math.sqrt(value)
	return v + dv/dist*maxDistance
}

// Invert the given vector
@(require_results, deprecated="Prefer 1.0/v")
Vector3Invert :: proc "c" (v: Vector3) -> Vector3 {
	return 1.0/v
}

// Clamp the components of the vector between
// min and max values specified by the given vectors
@(require_results)
Vector3Clamp :: proc "c" (v: Vector3, min, max: Vector3) -> Vector3 {
	return Vector3{
		clamp(v.x, min.x, max.x),
		clamp(v.y, min.y, max.y),
		clamp(v.z, min.z, max.z),
	}
}

// Clamp the magnitude of the vector between two min and max values
@(require_results)
Vector3ClampValue :: proc "c" (v: Vector3, min, max: f32) -> Vector3 {
	result := v

	length := linalg.dot(v, v)
	if length > 0 {
		length = math.sqrt(length)
		scale := f32(1)
		if length < min {
			scale = min/length
		} else if length > max {
			scale = max/length
		}
		result = v*scale
	}
	return result
}

@(require_results)
Vector3Equals :: proc "c" (p, q: Vector3) -> bool {
	return FloatEquals(p.x, q.x) &&
	       FloatEquals(p.y, q.y) &&
	       FloatEquals(p.z, q.z)
}


@(require_results)
Vector3Min :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return linalg.min(v1, v2)
}

@(require_results)
Vector3Max :: proc "c" (v1, v2: Vector3) -> Vector3 {
	return linalg.max(v1, v2)
}


// Compute barycenter coordinates (u, v, w) for point p with respect to triangle (a, b, c)
// NOTE: Assumes P is on the plane of the triangle
@(require_results)
Vector3Barycenter :: proc "c" (p: Vector3, a, b, c: Vector3) -> (result: Vector3) {
	v0 := b - a
	v1 := c - a
	v2 := p - a
	d00 := linalg.dot(v0, v0)
	d01 := linalg.dot(v0, v1)
	d11 := linalg.dot(v1, v1)
	d20 := linalg.dot(v2, v0)
	d21 := linalg.dot(v2, v1)

	denom := d00*d11 - d01*d01

	result.y = (d11*d20 - d01*d21)/denom
	result.z = (d00*d21 - d01*d20)/denom
	result.x = 1 - (result.z + result.y)

	return result
}


// Projects a Vector3 from screen space into object space
@(require_results)
Vector3Unproject :: proc "c" (source: Vector3, projection: Matrix, view: Matrix) -> Vector3 {
	matViewProj := view * projection

	matViewProjInv := linalg.inverse(matViewProj)

	quat: Quaternion
	quat.x = source.x
	quat.y = source.y
	quat.z = source.z
	quat.w = 1

	qtransformed := QuaternionTransform(quat, matViewProjInv)

	return Vector3{qtransformed.x/qtransformed.w, qtransformed.y/qtransformed.w, qtransformed.z/qtransformed.w}
}



//----------------------------------------------------------------------------------
// Module Functions Definition - Matrix math
//----------------------------------------------------------------------------------

// Compute matrix determinant
@(require_results)
MatrixDeterminant :: proc "c" (mat: Matrix) -> f32 {
	return linalg.determinant(mat)
}

// Get the trace of the matrix (sum of the values along the diagonal)
@(require_results)
MatrixTrace :: proc "c" (mat: Matrix) -> f32 {
	return linalg.trace(mat)
}

// Transposes provided matrix
@(require_results)
MatrixTranspose :: proc "c" (mat: Matrix) -> Matrix {
	return linalg.transpose(mat)
}

// Invert provided matrix
@(require_results)
MatrixInvert :: proc "c" (mat: Matrix) -> Matrix {
	return linalg.inverse(mat)
}

// Get identity matrix
@(require_results, deprecated="Prefer Matrix(1)")
MatrixIdentity :: proc "c" () -> Matrix {
	return Matrix(1)
}

// Add two matrices
@(require_results, deprecated="Prefer left + right")
MatrixAdd :: proc "c" (left, right: Matrix) -> Matrix {
	return left + right
}

// Subtract two matrices (left - right)
@(require_results, deprecated="Prefer left - right")
MatrixSubtract :: proc "c" (left, right: Matrix) -> Matrix {
	return left - right
}

// Get two matrix multiplication
// NOTE: When multiplying matrices... the order matters!
@(require_results, deprecated="Prefer left * right")
MatrixMultiply :: proc "c" (left, right: Matrix) -> Matrix {
	return left * right
}

// Get translation matrix
@(require_results)
MatrixTranslate :: proc "c" (x, y, z: f32) -> Matrix {
	return {
		1, 0, 0, x,
		0, 1, 0, y,
		0, 0, 1, z,
		0, 0, 0, 1,
	}
}

// Create rotation matrix from axis and angle
// NOTE: Angle should be provided in radians
@(require_results)
MatrixRotate :: proc "c" (axis: Vector3, angle: f32) -> Matrix {
	return auto_cast linalg.matrix4_rotate(angle, axis)
}

// Get x-rotation matrix
// NOTE: Angle must be provided in radians
@(require_results)
MatrixRotateX :: proc "c" (angle: f32) -> Matrix {
	return auto_cast linalg.matrix4_rotate(angle, Vector3{1, 0, 0})
}

// Get y-rotation matrix
// NOTE: Angle must be provided in radians
@(require_results)
MatrixRotateY :: proc "c" (angle: f32) -> Matrix {
	return auto_cast linalg.matrix4_rotate(angle, Vector3{0, 1, 0})
}

// Get z-rotation matrix
// NOTE: Angle must be provided in radians
@(require_results)
MatrixRotateZ :: proc "c" (angle: f32) -> Matrix {
	return auto_cast linalg.matrix4_rotate(angle, Vector3{0, 0, 1})
}

// Get xyz-rotation matrix
// NOTE: Angle must be provided in radians
@(require_results)
MatrixRotateXYZ :: proc "c" (angle: Vector3) -> Matrix {
	return auto_cast linalg.matrix4_from_euler_angles_xyz(angle.x, angle.y, angle.z)
}

// Get zyx-rotation matrix
// NOTE: Angle must be provided in radians
@(require_results)
MatrixRotateZYX :: proc "c" (angle: Vector3) -> Matrix {
	return auto_cast linalg.matrix4_from_euler_angles_zyx(angle.x, angle.y, angle.z)
}


// Get scaling matrix
@(require_results)
MatrixScale :: proc "c" (x, y, z: f32) -> Matrix {
	return auto_cast linalg.matrix4_scale(Vector3{x, y, z})
}

// Get orthographic projection matrix
@(require_results)
MatrixOrtho :: proc "c" (left, right, bottom, top, near, far: f32) -> Matrix {
	return auto_cast linalg.matrix_ortho3d(left, right, bottom, top, near, far)
}

// Get perspective projection matrix
// NOTE: Fovy angle must be provided in radians
@(require_results)
MatrixPerspective :: proc "c" (fovY, aspect, nearPlane, farPlane: f32) -> Matrix {
	return auto_cast linalg.matrix4_perspective(fovY, aspect, nearPlane, farPlane)
}
// Get camera look-at matrix (view matrix)
@(require_results)
MatrixLookAt :: proc "c" (eye, target, up: Vector3) -> Matrix {
	return auto_cast linalg.matrix4_look_at(eye, target, up)
}

// Get float array of matrix data
@(require_results)
MatrixToFloatV :: proc "c" (mat: Matrix) -> [16]f32 {
	return transmute([16]f32)linalg.transpose(mat)
}


//----------------------------------------------------------------------------------
// Module Functions Definition - Quaternion math
//----------------------------------------------------------------------------------



// Add two quaternions
@(require_results, deprecated="Prefer q1 + q2")
QuaternionAdd :: proc "c" (q1, q2: Quaternion) -> Quaternion {
	return q1 + q2
}
// Add quaternion and float value
@(require_results)
QuaternionAddValue :: proc "c" (q: Quaternion, add: f32) -> Quaternion {
	return q + Quaternion(add)
}
// Subtract two quaternions
@(require_results, deprecated="Prefer q1 - q2")
QuaternionSubtract :: proc "c" (q1, q2: Quaternion) -> Quaternion {
	return q1 - q2
}
// Subtract quaternion and float value
@(require_results)
QuaternionSubtractValue :: proc "c" (q: Quaternion, sub: f32) -> Quaternion {
	return q - Quaternion(sub)
}
// Get identity quaternion
@(require_results, deprecated="Prefer Quaternion(1)")
QuaternionIdentity :: proc "c" () -> Quaternion {
	return 1
}
// Computes the length of a quaternion
@(require_results, deprecated="Prefer abs(q)")
QuaternionLength :: proc "c" (q: Quaternion) -> f32 {
	return abs(q)
}
// Normalize provided quaternion
@(require_results)
QuaternionNormalize :: proc "c" (q: Quaternion) -> Quaternion {
	return linalg.normalize0(q)
}
// Invert provided quaternion
@(require_results, deprecated="Prefer 1/q")
QuaternionInvert :: proc "c" (q: Quaternion) -> Quaternion {
	return 1/q
}
// Calculate two quaternion multiplication
@(require_results, deprecated="Prefer q1 * q2")
QuaternionMultiply :: proc "c" (q1, q2: Quaternion) -> Quaternion {
	return q1 * q2
}
// Scale quaternion by float value
@(require_results)
QuaternionScale :: proc "c" (q: Quaternion, mul: f32) -> Quaternion {
	return q * Quaternion(mul)
}
// Divide two quaternions
@(require_results, deprecated="Prefer q1 / q2")
QuaternionDivide :: proc "c" (q1, q2: Quaternion) -> Quaternion {
	return q1 / q2
}
// Calculate linear interpolation between two quaternions
@(require_results)
QuaternionLerp :: proc "c" (q1, q2: Quaternion, amount: f32) -> (q3: Quaternion) {
	q3.x = q1.x + (q2.x-q1.x)*amount
	q3.y = q1.y + (q2.y-q1.y)*amount
	q3.z = q1.z + (q2.z-q1.z)*amount
	q3.w = q1.w + (q2.w-q1.w)*amount
	return
}
// Calculate slerp-optimized interpolation between two quaternions
@(require_results)
QuaternionNlerp :: proc "c" (q1, q2: Quaternion, amount: f32) -> Quaternion {
	return linalg.quaternion_nlerp(q1, q2, amount)
}
// Calculates spherical linear interpolation between two quaternions
@(require_results)
QuaternionSlerp :: proc "c" (q1, q2: Quaternion, amount: f32) -> Quaternion {
	return linalg.quaternion_slerp(q1, q2, amount)
}
// Calculate quaternion based on the rotation from one vector to another
@(require_results)
QuaternionFromVector3ToVector3 :: proc "c" (from, to: Vector3) -> Quaternion {
	return linalg.quaternion_between_two_vector3(from, to)
}
// Get a quaternion for a given rotation matrix
@(require_results)
QuaternionFromMatrix :: proc "c" (mat: Matrix) -> Quaternion {
	return linalg.quaternion_from_matrix4(linalg.Matrix4f32(mat))
}
// Get a matrix for a given quaternion
@(require_results)
QuaternionToMatrix :: proc "c" (q: Quaternion) -> Matrix {
	return auto_cast linalg.matrix4_from_quaternion(q)
}
// Get rotation quaternion for an angle and axis NOTE: Angle must be provided in radians
@(require_results)
QuaternionFromAxisAngle :: proc "c" (axis: Vector3, angle: f32) -> Quaternion {
	return linalg.quaternion_angle_axis(angle, axis)
}
// Get the rotation angle and axis for a given quaternion
@(require_results)
QuaternionToAxisAngle :: proc "c" (q: Quaternion) -> (outAxis: Vector3, outAngle: f32) {
	outAngle, outAxis = linalg.angle_axis_from_quaternion(q)
	return
}
// Get the quaternion equivalent to Euler angles NOTE: Rotation order is ZYX
@(require_results)
QuaternionFromEuler :: proc "c" (pitch, yaw, roll: f32) -> Quaternion {
	return linalg.quaternion_from_pitch_yaw_roll(pitch, yaw, roll)
}
// Get the Euler angles equivalent to quaternion (roll, pitch, yaw) NOTE: Angles are returned in a Vector3 struct in radians
@(require_results)
QuaternionToEuler :: proc "c" (q: Quaternion) -> Vector3 {
	result: Vector3

	// Roll (x-axis rotation)
	x0 := 2.0*(q.w*q.x + q.y*q.z)
	x1 := 1.0 - 2.0*(q.x*q.x + q.y*q.y)
	result.x = math.atan2(x0, x1)

	// Pitch (y-axis rotation)
	y0 := 2.0*(q.w*q.y - q.z*q.x)
	y0 =  1.0 if y0 >  1.0 else y0
	y0 = -1.0 if y0 < -1.0 else y0
	result.y = math.asin(y0)

	// Yaw (z-axis rotation)
	z0 := 2.0*(q.w*q.z + q.x*q.y)
	z1 := 1.0 - 2.0*(q.y*q.y + q.z*q.z)
	result.z = math.atan2(z0, z1)

	return result
}
// Transform a quaternion given a transformation matrix
@(require_results)
QuaternionTransform :: proc "c" (q: Quaternion, mat: Matrix) -> Quaternion {
	v := mat * transmute(Vector4)q
	return transmute(Quaternion)v
}
// Check whether two given quaternions are almost equal
@(require_results)
QuaternionEquals :: proc "c" (p, q: Quaternion) -> bool {
	return FloatEquals(p.x, q.x) &&
	       FloatEquals(p.y, q.y) &&
	       FloatEquals(p.z, q.z) &&
	       FloatEquals(p.w, q.w)
}

@(private, require_results)
fmaxf :: proc "contextless" (x, y: f32) -> f32 {
	if math.is_nan(x) {
		return y
	}

	if math.is_nan(y) {
		return x
	}

	if math.signbit(x) != math.signbit(y) {
		return y if math.signbit(x) else x
	}

	return y if x < y else x
}
