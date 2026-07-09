// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include "box3d/collision.h"
#include "box3d/math_functions.h"

struct b3Sweep;
struct b3Plane;

#define B3_TWO_PI 6.283185307f
#define B3_PI_OVER_TWO 1.570796327f
#define B3_PI_OVER_FOUR 0.785398163f
#define B3_SQRT3 1.732050808f

// todo eliminate this
static const b3AABB B3_BOUNDS3_EMPTY = { { FLT_MAX, FLT_MAX, FLT_MAX }, { -FLT_MAX, -FLT_MAX, -FLT_MAX } };

typedef struct b3Matrix2
{
	b3Vec2 cx, cy;
} b3Matrix2;

typedef struct b3Triangle
{
	b3Vec3 vertices[3];
	int i1, i2, i3;
	int flags;
} b3Triangle;

typedef struct b3TrianglePoint
{
	b3Vec3 point;
	b3TriangleFeature feature;
} b3TrianglePoint;

typedef struct b3ShapeExtent
{
	float minExtent;
	b3Vec3 maxExtent;
} b3ShapeExtent;

b3TrianglePoint b3ClosestPointOnTriangle( b3Vec3 a, b3Vec3 b, b3Vec3 c, b3Vec3 q );

float b3IntersectSegmentTriangle( b3Vec3 p, b3Vec3 q, b3Vec3 a, b3Vec3 b, b3Vec3 c );
float b3IntersectSegmentSphere( b3Vec3 p, b3Vec3 q, b3Vec3 c, float r );

b3MassData b3ComputeMassProperties( int triangleCount, const int* triangles, int vertexCount, const b3Vec3* vertices,
									float density );

bool b3IsValidMassData( const b3MassData* massData );

b3Matrix3 b3SphereInertia( float mass, float radius );
b3Matrix3 b3CylinderInertia( float mass, float radius, float height );
b3Matrix3 b3BoxInertia( float mass, b3Vec3 min, b3Vec3 max );

// Inertia helper (Io = Ic + Is and Ic = Io - Is)
int b3GetProxySupport( const b3ShapeProxy* proxy, b3Vec3 axis );
int b3GetPointSupport( const b3Vec3* points, int count, b3Vec3 axis );

static inline size_t b3AlignUp8( size_t x )
{
	return ( x + 7u ) & ~(size_t)7u;
}

// https://en.wikipedia.org/wiki/Floor_and_ceiling_functions
static inline int b3CeilingInt( int numerator, int denominator )
{
	B3_VALIDATE( denominator > 0 );
	return ( numerator + denominator - 1 ) / denominator;
}

// Assumes denominator == 2^exponent
static inline int b3CeilingPow2( int numerator, int denominator, int exponent )
{
	B3_VALIDATE( exponent > 0 && ( denominator == 1 << exponent ) );
	return ( numerator + denominator - 1 ) >> exponent;
}

bool b3IsSweepNormalized( b3Sweep* sweep );

static inline float b3Dot2( b3Vec2 v1, b3Vec2 v2 )
{
	return v1.x * v2.x + v1.y * v2.y;
}

static inline float b3Length2( b3Vec2 v )
{
	return sqrtf( b3Dot2( v, v ) );
}

static inline float b3LengthSquared2( b3Vec2 v )
{
	return b3Dot2( v, v );
}

static inline b3Vec2 b3MinVec2( b3Vec2 v1, b3Vec2 v2 )
{
	b3Vec2 v;
	v.x = b3MinFloat( v1.x, v2.x );
	v.y = b3MinFloat( v1.y, v2.y );
	return v;
}

static inline b3Vec2 b3MaxVec2( b3Vec2 v1, b3Vec2 v2 )
{
	b3Vec2 v;
	v.x = b3MaxFloat( v1.x, v2.x );
	v.y = b3MaxFloat( v1.y, v2.y );
	return v;
}

static inline void b3Store( float* dst, b3Vec3 src )
{
	dst[0] = src.x;
	dst[1] = src.y;
	dst[2] = src.z;
}

static inline b3Vec3 b3ClampLength( b3Vec3 v, float maxLength )
{
	float lengthSq = b3LengthSquared( v );
	if ( lengthSq <= maxLength * maxLength )
	{
		return v;
	}

	float length = sqrtf( lengthSq );
	return b3MulSV( maxLength / length, v );
}

// Assume v is a unit vector
static inline b3Vec3 b3ArbitraryPerp( b3Vec3 v )
{
	// Suppose vector a has all equal components and is a unit vector: a = (s, s, s)
	// Then 3*s*s = 1, s = sqrt(1/3) = 0.57735. This means that at least one component
	// of a unit vector must be greater or equal to 0.57735.
	b3Vec3 p;
	if ( v.x < -0.5f || 0.5f < v.x )
	{
		// x is non-zero and it should not go into the x component
		// dot([ay + bz, cx, dx], [x, y, z]) = ayx + bzx + cxy + dzx
		// for the dot product to be zero need: c = -a, d = -b
		float a = 0.67f;
		float b = -0.42f;
		p = B3_LITERAL( b3Vec3 ){ a * v.y + b * v.z, -a * v.x, -b * v.x };
	}
	else if ( v.y < -0.5f || 0.5f < v.y )
	{
		// y is non-zero and it should not go into the y component
		// p = [ay, bx + cz, dy]
		// axy + bxy + cyz + dyz = 0
		// b = -a, d = -c
		float a = 0.67f;
		float c = -0.42f;
		p = B3_LITERAL( b3Vec3 ){ a * v.y, -a * v.x + c * v.z, -c * v.y };
	}
	else
	{
		// This would trip if the input is not a unit vector
		B3_VALIDATE( v.z < -0.5f || 0.5f < v.z );

		// z is non-zero and it should not go into the z component
		// p = [az, bz, cx + dy]
		// axz + byz + cxz + dyz = 0
		// c = -a, d = -b
		float a = 0.67f;
		float b = -0.42f;
		p = B3_LITERAL( b3Vec3 ){ a * v.z, b * v.z, -a * v.x - b * v.y };
	}

	B3_VALIDATE( b3LengthSquared( p ) > 0.1f );
	B3_VALIDATE( b3AbsFloat( b3Dot( p, v ) ) < 100.0f * FLT_EPSILON );

	return b3Normalize( p );
}

static inline b3Quat b3QuatFromExponentialMap( b3Vec3 v )
{
	// Exponential map (Grassia)
	float threshold = 0.018581361f;

	float angle = b3Length( v );
	if ( angle < threshold )
	{
		// Taylor expansion
		b3Quat out;
		out.v = b3MulSV( 0.5f + angle * angle / 48.0f, v );
		out.s = b3Cos( 0.5f * angle );

		return out;
	}

	return b3MakeQuatFromAxisAngle( b3MulSV( 1.0f / angle, v ), angle );
}

/// Integrate rotation from angular velocity
/// @param q1 initial rotation
/// @param deltaRotation the angular displacement vector in radians (angular velocity multiplied by the time step)
/// q2 = q1 + 0.5 * omega * q1
static inline b3Quat b3IntegrateRotation( b3Quat q1, b3Vec3 deltaRotation )
{
#if 1
	// https://fgiesen.wordpress.com/2012/08/24/quaternion-differentiation/
	b3Quat qd = { b3MulSV( 0.5f, deltaRotation ), 0.0f };
	qd = b3MulQuat( qd, q1 );
	b3Quat q2 = { b3Add( q1.v, qd.v ), qd.s + q1.s };
	q2 = b3NormalizeQuat( q2 );
	return q2;
#else
	return b3NormalizeQuat( b3MulQuat(b3QuatFromExponentialMap( deltaRotation ), q1) );
#endif
}

// Pseudo angular velocity from a quaternion target
// w = 2 * (target - q) * conj(q)
static inline b3Vec3 b3DeltaQuatToRotation( b3Quat q, b3Quat target )
{
	b3Quat s = q;
	if ( b3DotQuat( q, target ) < 0.0f )
	{
		// Correct polarity
		s = b3NegateQuat( q );
	}

	b3Quat diff = { b3Sub( target.v, s.v ), target.s - s.s };
	b3Quat product = b3MulQuat( diff, b3Conjugate( s ) );
	return b3MulSV( 2.0f, product.v );
}

static inline float b3ScalarTripleProduct( b3Vec3 a, b3Vec3 b, b3Vec3 c )
{
	b3Vec3 d;
	d.x = b.y * c.z - b.z * c.y;
	d.y = b.z * c.x - b.x * c.z;
	d.z = b.x * c.y - b.y * c.x;
	return a.x * d.x + a.y * d.y + a.z * d.z;
}

// Get a value by index. Avoid undefined behavior of code like (&v.x)[2].
static inline float b3GetByIndex( b3Vec3 v, int index )
{
	B3_VALIDATE( 0 <= index && index < 3 );
	float temp[3] = { v.x, v.y, v.z };
	return temp[index];
}

static inline int b3MajorAxis( b3Vec3 v )
{
	return v.x < v.y ? ( v.y < v.z ? 2 : 1 ) : ( v.x < v.z ? 2 : 0 );
}

static inline float b3MinElement( b3Vec3 v )
{
	return b3MinFloat( v.x, b3MinFloat( v.y, v.z ) );
}

static inline float b3MaxElement( b3Vec3 v )
{
	return b3MaxFloat( v.x, b3MaxFloat( v.y, v.z ) );
}

static inline int b3MaxElementIndex( b3Vec3 v )
{
	return v.x < v.y ? ( v.y < v.z ? 2 : 1 ) : ( v.x < v.z ? 2 : 0 );
}

static inline b3Vec2 b3Add2( b3Vec2 a, b3Vec2 b )
{
	b3Vec2 c = { a.x + b.x, a.y + b.y };
	return c;
}

static inline b3Vec2 b3Sub2( b3Vec2 a, b3Vec2 b )
{
	b3Vec2 c = { a.x - b.x, a.y - b.y };
	return c;
}

static inline b3Vec2 b3Neg2( b3Vec2 v )
{
	b3Vec2 c = { -v.x, -v.y };
	return c;
}

static inline b3Vec2 b3MulSV2( float s, b3Vec2 v )
{
	b3Vec2 c = { s * v.x, s * v.y };
	return c;
}

// a + s * b
static inline b3Vec2 b3MulAdd2( b3Vec2 a, float s, b3Vec2 b )
{
	b3Vec2 c = { a.x + s * b.x, a.y + s * b.y };
	return c;
}

// a - s * b
static inline b3Vec2 b3MulSub2( b3Vec2 a, float s, b3Vec2 b )
{
	b3Vec2 c = { a.x - s * b.x, a.y - s * b.y };
	return c;
}

static inline float b3Cross2( b3Vec2 a, b3Vec2 b )
{
	return a.x * b.y - a.y * b.x;
}

static inline float b3DistanceSquared2( b3Vec2 a, b3Vec2 b )
{
	float dx = b.x - a.x;
	float dy = b.y - a.y;
	return dx * dx + dy * dy;
}

static inline b3Vec2 b3MulMV2( b3Matrix2 m, b3Vec2 a )
{
	b3Vec2 b = { m.cx.x * a.x + m.cy.x * a.y, m.cx.y * a.x + m.cy.y * a.y };
	return b;
}

static inline b3Matrix2 b3MulMM2( b3Matrix2 m1, b3Matrix2 m2 )
{
	b3Matrix2 out;
	out.cx = b3MulMV2( m1, m2.cx );
	out.cy = b3MulMV2( m1, m2.cy );
	return out;
}

static inline float b3Det2( b3Matrix2 m )
{
	return m.cx.x * m.cy.y - m.cx.y * m.cy.x;
}

static inline b3Matrix2 b3Invert2( b3Matrix2 m )
{
	float det = b3Det2( m );
	if ( b3AbsFloat( det ) > 1000.0f * FLT_MIN )
	{
		float invDet = 1.0f / det;
		return B3_LITERAL( b3Matrix2 ){
			{ invDet * m.cy.y, -invDet * m.cx.y },
			{ -invDet * m.cy.x, invDet * m.cx.x },
		};
	}

	return B3_LITERAL( b3Matrix2 ){ { 0.0f, 0.0f }, { 0.0f, 0.0f } };
}

// Assumes positive semi-definite
static inline b3Vec2 b3Solve2( b3Matrix2 m, b3Vec2 b )
{
	float det = b3Det2( m );
	if ( det > 1000.0f * FLT_MIN )
	{
		float invDet = 1.0f / det;
		return B3_LITERAL( b3Vec2 ){
			invDet * m.cy.y * b.x - invDet * m.cy.x * b.y,
			-invDet * m.cx.y * b.x + invDet * m.cx.x * b.y,
		};
	}

	return B3_LITERAL( b3Vec2 ){ 0.0f, 0.0f };
}

// Convenience function: s * a + t * b + u * c
static inline b3Vec3 b3Blend3( float s, b3Vec3 a, float t, b3Vec3 b, float u, b3Vec3 c )
{
	b3Vec3 d = {
		s * a.x + t * b.x + u * c.x,
		s * a.y + t * b.y + u * c.y,
		s * a.z + t * b.z + u * c.z,
	};
	return d;
}

static inline b3Vec3 b3ModifiedCross( b3Vec3 a, b3Vec3 b )
{
	b3Vec3 c;
	c.x = a.y * b.z + a.z * b.y;
	c.y = a.z * b.x + a.x * b.z;
	c.z = a.x * b.y + a.y * b.x;
	return c;
}

static inline b3Matrix3 b3MakeDiagonalMatrix( float a, float b, float c )
{
	return (b3Matrix3){ { a, 0.0f, 0.0f }, { 0.0f, b, 0.0f }, { 0.0f, 0.0f, c } };
}

static inline b3Matrix3 b3Skew( b3Vec3 v )
{
	b3Matrix3 out;
	out.cx = (b3Vec3){ 0, v.z, -v.y };
	out.cy = (b3Vec3){ -v.z, 0, v.x };
	out.cz = (b3Vec3){ v.y, -v.x, 0 };

	return out;
}

static inline b3Plane b3NormalizePlane( b3Plane plane )
{
	float invLength = 1.0f / b3Length( plane.normal );
	return (b3Plane){ b3MulSV( invLength, plane.normal ), invLength * plane.offset };
}

static inline b3Plane b3MakePlaneFromNormalAndPoint( b3Vec3 normal, b3Vec3 point )
{
	return (b3Plane){ normal, b3Dot( normal, point ) };
}

static inline b3Plane b3MakePlaneFromPoints( b3Vec3 point1, b3Vec3 point2, b3Vec3 point3 )
{
	b3Plane plane;
	plane.normal = b3Cross( b3Sub( point2, point1 ), b3Sub( point3, point1 ) );
	plane.normal = b3Normalize( plane.normal );
	plane.offset = b3Dot( plane.normal, point1 );
	return plane;
}

static inline b3Vec3 b3MakeNormalFromPoints( b3Vec3 point1, b3Vec3 point2, b3Vec3 point3 )
{
	b3Vec3 normal = b3Cross( b3Sub( point2, point1 ), b3Sub( point3, point1 ) );
	return b3Normalize( normal );
}

// normal2 = q * normal1
// offset2 = dot(normal2, p) + offset1
static inline b3Plane b3TransformPlane( b3Transform transform, b3Plane plane )
{
	b3Vec3 normal = b3RotateVector( transform.q, plane.normal );
	return B3_LITERAL( b3Plane ){ normal, plane.offset + b3Dot( normal, transform.p ) };
}

/// Signed separation of a point from a plane
static inline float b3PlaneSeparation( b3Plane plane, b3Vec3 point )
{
	return b3Dot( plane.normal, point ) - plane.offset;
}

// Negative if p is below the triangle v1-v2-v3
static inline float b3SignedVolume( b3Vec3 v1, b3Vec3 v2, b3Vec3 v3, b3Vec3 p )
{
	b3Vec3 e1 = b3Sub( v2, v1 );
	b3Vec3 e2 = b3Sub( v3, v1 );
	b3Vec3 n = b3Cross( e1, e2 );
	return b3Dot( n, b3Sub( p, v1 ) );
}

// todo eliminate this
static inline bool b3IsWithinSegments( const b3SegmentDistanceResult* result )
{
	return ( 0.0f <= result->fraction1 && result->fraction1 <= 1.0f ) &&
		   ( 0.0f <= result->fraction2 && result->fraction2 <= 1.0f );
}

static inline b3Matrix3 b3RotateInertia( b3Quat q, b3Matrix3 centralInertia )
{
	b3Matrix3 rotationMatrix = b3MakeMatrixFromQuat( q );
	b3Matrix3 inertia = b3MulMM( rotationMatrix, b3MulMM( centralInertia, b3Transpose( rotationMatrix ) ) );
	return inertia;
}

static inline b3Matrix3 b3TransformInertia( b3Transform transform, b3Matrix3 centralInertia, float mass )
{
	b3Matrix3 inertia = b3RotateInertia( transform.q, centralInertia );
	inertia = b3AddMM( inertia, b3Steiner( mass, transform.p ) );
	return inertia;
}

// Add a point to an AABB.
static inline b3AABB b3AABB_AddPoint( b3AABB a, b3Vec3 point )
{
	return (b3AABB){ b3Min( a.lowerBound, point ), b3Max( a.upperBound, point ) };
}
