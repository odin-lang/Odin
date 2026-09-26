// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "box3d/math_functions.h"

#include "math_internal.h"

#include "box3d/collision.h"
#include "box3d/constants.h"

#include <math.h>
#include <string.h>

bool b3IsValidFloat( float a )
{
	if ( isnan( a ) )
	{
		return false;
	}

	if ( isinf( a ) )
	{
		return false;
	}

	return true;
}

bool b3IsValidVec3( b3Vec3 a )
{
	if ( isnan( a.x ) || isnan( a.y ) || isnan( a.z ) )
	{
		return false;
	}

	if ( isinf( a.x ) || isinf( a.y ) || isinf( a.z ) )
	{
		return false;
	}

	return true;
}

bool b3IsValidQuat( b3Quat a )
{
	if ( isnan( a.v.x ) || isnan( a.v.y ) || isnan( a.v.z ) || isnan( a.s ) )
	{
		return false;
	}

	if ( isinf( a.v.x ) || isinf( a.v.y ) || isinf( a.v.z ) || isinf( a.s ) )
	{
		return false;
	}

	return b3IsNormalizedQuat( a );
}

bool b3IsValidTransform( b3Transform a )
{
	return b3IsValidVec3( a.p ) && b3IsValidQuat( a.q );
}

bool b3IsValidMatrix3( b3Matrix3 a )
{
	return b3IsValidVec3( a.cx ) && b3IsValidVec3( a.cy ) && b3IsValidVec3( a.cz );
}

bool b3IsValidAABB( b3AABB a )
{
	if ( b3IsValidVec3( a.lowerBound ) == false )
	{
		return false;
	}

	if ( b3IsValidVec3( a.upperBound ) == false )
	{
		return false;
	}

	if ( a.lowerBound.x > a.upperBound.x )
	{
		return false;
	}

	if ( a.lowerBound.y > a.upperBound.y )
	{
		return false;
	}

	if ( a.lowerBound.z > a.upperBound.z )
	{
		return false;
	}

	return true;
}

bool b3IsBoundedAABB( b3AABB a )
{
	if ( a.lowerBound.x < -B3_HUGE || a.lowerBound.y < -B3_HUGE || a.lowerBound.z < -B3_HUGE )
	{
		return false;
	}

	if ( a.upperBound.x > B3_HUGE || a.upperBound.y > B3_HUGE || a.upperBound.z > B3_HUGE )
	{
		return false;
	}

	return true;
}

bool b3IsSaneAABB( b3AABB a )
{
	if ( b3IsValidAABB( a ) == false )
	{
		return false;
	}

	if ( a.lowerBound.x < -B3_HUGE || a.lowerBound.y < -B3_HUGE || a.lowerBound.z < -B3_HUGE )
	{
		return false;
	}

	if ( a.upperBound.x > B3_HUGE || a.upperBound.y > B3_HUGE || a.upperBound.z > B3_HUGE )
	{
		return false;
	}

	return true;
}

bool b3IsValidPlane( b3Plane a )
{
	if ( b3IsValidVec3( a.normal ) == false )
	{
		return false;
	}

	if ( b3IsNormalized( a.normal ) == false )
	{
		return false;
	}

	return b3IsValidFloat( a.offset );
}

bool b3IsValidPosition( b3Pos p )
{
	if ( isnan( p.x ) || isnan( p.y ) || isnan( p.z ) )
	{
		return false;
	}

	if ( isinf( p.x ) || isinf( p.y ) || isinf( p.z ) )
	{
		return false;
	}

	return true;
}

bool b3IsValidWorldTransform( b3WorldTransform t )
{
	return b3IsValidPosition( t.p ) && b3IsValidQuat( t.q );
}

// https://stackoverflow.com/questions/46210708/atan2-approximation-with-11bits-in-mantissa-on-x86with-sse2-and-armwith-vfpv4
float b3Atan2( float y, float x )
{
	// Added check for (0,0) to match atan2f and avoid NaN
	if ( x == 0.0f && y == 0.0f )
	{
		return 0.0f;
	}

	float ax = b3AbsFloat( x );
	float ay = b3AbsFloat( y );
	float mx = b3MaxFloat( ay, ax );
	float mn = b3MinFloat( ay, ax );
	float a = mn / mx;

	// Minimax polynomial approximation to atan(a) on [0,1]
	float s = a * a;
	float c = s * a;
	float q = s * s;
	float r = 0.024840285f * q + 0.18681418f;
	float t = -0.094097948f * q - 0.33213072f;
	r = r * s + t;
	r = r * c + a;

	// Map to full circle
	if ( ay > ax )
	{
		r = 1.57079637f - r;
	}

	if ( x < 0 )
	{
		r = 3.14159274f - r;
	}

	if ( y < 0 )
	{
		r = -r;
	}

	return r;
}

// Approximate cosine and sine for determinism. In my testing cosf and sinf produced
// the same results on x64 and ARM using MSVC, GCC, and Clang. However, I don't trust
// this result.
// https://en.wikipedia.org/wiki/Bh%C4%81skara_I%27s_sine_approximation_formula
b3CosSin b3ComputeCosSin( float radians )
{
#if 0
	return {
		cosf( radians ),
		sinf( radians ),
	};
#else
	float x = b3UnwindAngle( radians );
	float pi2 = B3_PI * B3_PI;

	// cosine needs angle in [-pi/2, pi/2]
	float c;
	if ( x < -0.5f * B3_PI )
	{
		float y = x + B3_PI;
		float y2 = y * y;
		c = -( pi2 - 4.0f * y2 ) / ( pi2 + y2 );
	}
	else if ( x > 0.5f * B3_PI )
	{
		float y = x - B3_PI;
		float y2 = y * y;
		c = -( pi2 - 4.0f * y2 ) / ( pi2 + y2 );
	}
	else
	{
		float y2 = x * x;
		c = ( pi2 - 4.0f * y2 ) / ( pi2 + y2 );
	}

	// sine needs angle in [0, pi]
	float s;
	if ( x < 0.0f )
	{
		float y = x + B3_PI;
		s = -16.0f * y * ( B3_PI - y ) / ( 5.0f * pi2 - 4.0f * y * ( B3_PI - y ) );
	}
	else
	{
		s = 16.0f * x * ( B3_PI - x ) / ( 5.0f * pi2 - 4.0f * x * ( B3_PI - x ) );
	}

	float mag = sqrtf( s * s + c * c );
	float invMag = mag > 0.0f ? 1.0f / mag : 0.0f;
	b3CosSin cs = { c * invMag, s * invMag };
	return cs;
#endif
}

b3Quat b3MakeQuatFromMatrix( const b3Matrix3* m )
{
	b3Vec3 c1 = m->cx;
	b3Vec3 c2 = m->cy;
	b3Vec3 c3 = m->cz;

	b3Quat q;

	float trace = m->cx.x + m->cy.y + m->cz.z;
	if ( trace >= 0.0f )
	{
		q.v.x = c2.z - c3.y;
		q.v.y = c3.x - c1.z;
		q.v.z = c1.y - c2.x;
		q.s = trace + 1.0f;
	}
	else
	{
		if ( c1.x > c2.y && c1.x > c3.z )
		{
			q.v.x = c1.x - c2.y - c3.z + 1.0f;
			q.v.y = c2.x + c1.y;
			q.v.z = c3.x + c1.z;
			q.s = c2.z - c3.y;
		}
		else if ( c2.y > c3.z )
		{
			q.v.x = c1.y + c2.x;
			q.v.y = c2.y - c3.z - c1.x + 1.0f;
			q.v.z = c3.y + c2.z;
			q.s = c3.x - c1.z;
		}
		else
		{
			q.v.x = c1.z + c3.x;
			q.v.y = c2.z + c3.y;
			q.v.z = c3.z - c1.x - c2.y + 1.0f;
			q.s = c1.y - c2.x;
		}
	}

	// The algorithm is simplified and made more accurate by normalizing at the end
	return b3NormalizeQuat( q );
}

b3Quat b3ComputeQuatBetweenUnitVectors( b3Vec3 v1, b3Vec3 v2 )
{
	B3_ASSERT( b3IsNormalized( v1 ) );
	B3_ASSERT( b3IsNormalized( v2 ) );

	b3Quat out;

	b3Vec3 m = b3Lerp( v1, v2, 0.5f );
	float tolerance = 100.0f * FLT_EPSILON;
	if ( b3LengthSquared( m ) > tolerance * tolerance )
	{
		out.v = b3Cross( v1, m );
		out.s = b3Dot( v1, m );
	}
	else
	{
		// Anti-parallel: Use a perpendicular vector
		if ( b3AbsFloat( v1.x ) > 0.5f )
		{
			out.v.x = v1.y;
			out.v.y = -v1.x;
			out.v.z = 0.0f;
		}
		else
		{
			out.v.x = 0.0f;
			out.v.y = v1.z;
			out.v.z = -v1.y;
		}

		out.s = 0.0f;
	}

	// The algorithm is simplified and made more accurate by normalizing at the end
	return b3NormalizeQuat( out );
}

b3SegmentDistanceResult b3LineDistance( b3Vec3 p1, b3Vec3 d1, b3Vec3 p2, b3Vec3 d2 )
{
	b3SegmentDistanceResult result;

	// Solve A*x = b
	float a11 = b3Dot( d1, d1 );
	float a12 = -b3Dot( d1, d2 );
	float a21 = b3Dot( d2, d1 );
	float a22 = -b3Dot( d2, d2 );

	b3Vec3 w = b3Sub( p1, p2 );
	float b1 = -b3Dot( d1, w );
	float b2 = -b3Dot( d2, w );

	float det = a11 * a22 - a12 * a21;
	if ( det * det < 1000.0f * FLT_MIN )
	{
		// Lines are parallel - project p2 onto line L1: x1 = p1 + s1 * d1
		float s1 = b3Dot( b3Sub( p2, p1 ), d1 ) / b3Dot( d1, d1 );
		float s2 = 0.0f;

		result.point1 = b3MulAdd( p1, s1, d1 );
		result.fraction1 = s1;
		result.point2 = b3MulAdd( p2, s2, d2 );
		result.fraction2 = s2;

		return result;
	}

	float s1 = ( a22 * b1 - a12 * b2 ) / det;
	float s2 = ( a11 * b2 - a21 * b1 ) / det;

	result.point1 = b3MulAdd( p1, s1, d1 );
	result.fraction1 = s1;
	result.point2 = b3MulAdd( p2, s2, d2 );
	result.fraction2 = s2;
	return result;
}

b3SegmentDistanceResult b3SegmentDistance( b3Vec3 p1, b3Vec3 q1, b3Vec3 p2, b3Vec3 q2 )
{
	b3SegmentDistanceResult result;

	b3Vec3 d1 = b3Sub( q1, p1 );
	b3Vec3 d2 = b3Sub( q2, p2 );
	b3Vec3 r = b3Sub( p1, p2 );

	float a = b3Dot( d1, d1 );
	float b = b3Dot( d1, d2 );
	float c = b3Dot( d1, r );
	float e = b3Dot( d2, d2 );
	float f = b3Dot( d2, r );

	// Check if one of the segments degenerates into a point
	if ( a < 100.0f * FLT_EPSILON && e < 100.0f * FLT_EPSILON )
	{
		// Both segments degenerate into points
		result.point1 = p1;
		result.fraction1 = 0.0f;
		result.point2 = p2;
		result.fraction2 = 0.0f;

		return result;
	}

	if ( a < 100.0f * FLT_EPSILON )
	{
		// First segment degenerates into a point
		float s2 = b3ClampFloat( f / e, 0.0f, 1.0f );

		result.point1 = p1;
		result.fraction1 = 0.0f;
		result.point2 = b3MulAdd( p2, s2, d2 );
		result.fraction2 = s2;

		return result;
	}

	if ( e < 100.0f * FLT_EPSILON )
	{
		// Second segment degenerates into a point
		float s1 = b3ClampFloat( -c / a, 0.0f, 1.0f );

		result.point1 = b3MulAdd( p1, s1, d1 );
		result.fraction1 = s1;
		result.point2 = p2;
		result.fraction2 = 0.0f;

		return result;
	}

	// Non-degenerate case
	float denom = a * e - b * b;
	float s1 = denom > 1000.0f * FLT_MIN ? b3ClampFloat( ( b * f - c * e ) / denom, 0.0f, 1.0f ) : 0.0f;
	float s2 = ( b * s1 + f ) / e;

	// Clamp lambda2 and recompute lambda1 if necessary
	if ( s2 < 0.0f )
	{
		s1 = b3ClampFloat( -c / a, 0.0f, 1.0f );
		s2 = 0.0f;
	}
	else if ( s2 > 1.0f )
	{
		s1 = b3ClampFloat( ( b - c ) / a, 0.0f, 1.0f );
		s2 = 1.0f;
	}

	result.point1 = b3MulAdd( p1, s1, d1 );
	result.fraction1 = s1;
	result.point2 = b3MulAdd( p2, s2, d2 );
	result.fraction2 = s2;

	return result;
}

b3Vec3 b3PointToSegmentDistance( b3Vec3 a, b3Vec3 b, b3Vec3 q )
{
	b3Vec3 ab = b3Sub( b, a );
	b3Vec3 aq = b3Sub( q, a );

	float alpha = b3Dot( ab, aq );

	if ( alpha <= 0.0f )
	{
		// q projects outside interval [a, b] on the side of a
		return a;
	}
	else
	{
		float denominator = b3Dot( ab, ab );
		if ( alpha > denominator )
		{
			// q projects outside interval [a, b] on the side of b
			return b;
		}
		else
		{
			// q projects inside interval [a, b]
			alpha /= denominator;
			return b3MulAdd( a, alpha, ab );
		}
	}
}

b3TrianglePoint b3ClosestPointOnTriangle( b3Vec3 a, b3Vec3 b, b3Vec3 c, b3Vec3 q )
{
	// Check if P lies in vertex region of A
	b3Vec3 ab = b3Sub( b, a );
	b3Vec3 ac = b3Sub( c, a );
	b3Vec3 aq = b3Sub( q, a );

	float d1 = b3Dot( ab, aq );
	float d2 = b3Dot( ac, aq );
	if ( d1 <= 0.0f && d2 <= 0.0f )
	{
		return (b3TrianglePoint){ a, b3_featureVertex1 };
	}

	// Check if P lies in vertex region of B
	b3Vec3 bq = b3Sub( q, b );

	float d3 = b3Dot( ab, bq );
	float d4 = b3Dot( ac, bq );
	if ( d3 > 0.0f && d4 <= d3 )
	{
		return (b3TrianglePoint){ b, b3_featureVertex2 };
	}

	// Check if P lies in edge region AB
	float vc = d1 * d4 - d3 * d2;
	if ( vc <= 0.0f && d1 >= 0.0f && d3 <= 0.0f )
	{
		float t = d1 / ( d1 - d3 );
		return (b3TrianglePoint){ b3MulAdd( a, t, ab ), b3_featureEdge1 };
	}

	// Check if P lies in vertex region of C
	b3Vec3 cq = b3Sub( q, c );

	float d5 = b3Dot( ab, cq );
	float d6 = b3Dot( ac, cq );
	if ( d6 >= 0.0f && d5 <= d6 )
	{
		return (b3TrianglePoint){ c, b3_featureVertex3 };
	}

	// Check if P lies in edge region AC
	float vb = d5 * d2 - d1 * d6;
	if ( vb <= 0.0f && d2 >= 0.0f && d6 <= 0.0f )
	{
		float t = d2 / ( d2 - d6 );
		return (b3TrianglePoint){ b3MulAdd( a, t, ac ), b3_featureEdge3 };
	}

	// Check if P lies in edge region of BC
	float va = d3 * d6 - d5 * d4;
	if ( va <= 0.0f && d4 >= d3 && d5 >= d6 )
	{
		b3Vec3 bc = b3Sub( c, b );

		float t = ( d4 - d3 ) / ( ( d4 - d3 ) + ( d5 - d6 ) );
		return (b3TrianglePoint){ b3MulAdd( b, t, bc ), b3_featureEdge2 };
	}

	// P inside face region ABC
	float t1 = vb / ( va + vb + vc );
	float t2 = vc / ( va + vb + vc );

	b3Vec3 p = b3MulAdd( a, t1, ab );
	p = b3MulAdd( p, t2, ac );
	return (b3TrianglePoint){ p, b3_featureTriangleFace };
}

b3Matrix3 b3SphereInertia( float mass, float radius )
{
	float i = 0.4f * mass * radius * radius;
	return b3MakeDiagonalMatrix( i, i, i );
}

b3Matrix3 b3CylinderInertia( float mass, float radius, float height )
{
	float ixx = mass * ( 3 * radius * radius + height * height ) / 12.0f;
	float iyy = 0.5f * mass * radius * radius;
	return b3MakeDiagonalMatrix( ixx, iyy, ixx );
}

b3Matrix3 b3BoxInertia( float mass, b3Vec3 min, b3Vec3 max )
{
	b3Vec3 delta = b3Sub( max, min );
	float ixx = mass * ( delta.y * delta.y + delta.z * delta.z ) / 12.0f;
	float iyy = mass * ( delta.x * delta.x + delta.z * delta.z ) / 12.0f;
	float izz = mass * ( delta.x * delta.x + delta.y * delta.y ) / 12.0f;

	return b3MakeDiagonalMatrix( ixx, iyy, izz );
}

// https://en.wikipedia.org/wiki/Parallel_axis_theorem
b3Matrix3 b3Steiner( float mass, b3Vec3 origin )
{
	// Usage: Io = Ic + Is and Ic = Io - Is
	float ixx = mass * ( origin.y * origin.y + origin.z * origin.z );
	float iyy = mass * ( origin.x * origin.x + origin.z * origin.z );
	float izz = mass * ( origin.x * origin.x + origin.y * origin.y );
	float ixy = -mass * origin.x * origin.y;
	float ixz = -mass * origin.x * origin.z;
	float iyz = -mass * origin.y * origin.z;

	// Write
	b3Matrix3 out;
	out.cx.x = ixx;
	out.cy.x = ixy;
	out.cz.x = ixz;
	out.cx.y = ixy;
	out.cy.y = iyy;
	out.cz.y = iyz;
	out.cx.z = ixz;
	out.cy.z = iyz;
	out.cz.z = izz;

	return out;
}

bool b3IsValidRay( const b3RayCastInput* input )
{
	bool isValid = b3IsValidVec3( input->origin ) && b3IsValidVec3( input->translation ) &&
				   b3IsValidFloat( input->maxFraction ) && 0.0f <= input->maxFraction && input->maxFraction < B3_HUGE;
	return isValid;
}
