// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "simd.h"

#if defined( B3_SIMD_SSE2 )

#define B3_TRANSPOSE3( C1, C2, C3 )                                                                                              \
	{                                                                                                                            \
		b3V32 T1 = _mm_unpacklo_ps( ( C1 ), ( C2 ) );                                                                            \
		b3V32 T2 = _mm_unpackhi_ps( ( C1 ), ( C2 ) );                                                                            \
		( C1 ) = _mm_shuffle_ps( ( T1 ), ( C3 ), _MM_SHUFFLE( 0, 0, 1, 0 ) );                                                    \
		( C2 ) = _mm_shuffle_ps( ( T1 ), ( C3 ), _MM_SHUFFLE( 1, 1, 3, 2 ) );                                                    \
		( C3 ) = _mm_shuffle_ps( ( T2 ), ( C3 ), _MM_SHUFFLE( 2, 2, 1, 0 ) );                                                    \
	}

static inline b3V32 b3SplatXV( b3V32 v )
{
	return _mm_shuffle_ps( v, v, _MM_SHUFFLE( 0, 0, 0, 0 ) );
}

static inline b3V32 b3SplatYV( b3V32 v )
{
	return _mm_shuffle_ps( v, v, _MM_SHUFFLE( 1, 1, 1, 1 ) );
}

static inline b3V32 b3SplatZV( b3V32 v )
{
	return _mm_shuffle_ps( v, v, _MM_SHUFFLE( 2, 2, 2, 2 ) );
}

static inline bool b3AnyGreaterEq3V( b3V32 a, b3V32 b )
{
	b3V32 v = _mm_cmpge_ps( a, b );
	return ( _mm_movemask_ps( v ) & 0x07 ) != 0;
}

static inline b3V32 b3Dot3V( b3V32 a, b3V32 b )
{
	b3V32 m = _mm_mul_ps( a, b );
	b3V32 x = _mm_shuffle_ps( m, m, _MM_SHUFFLE( 0, 0, 0, 0 ) );
	b3V32 y = _mm_shuffle_ps( m, m, _MM_SHUFFLE( 1, 1, 1, 1 ) );
	b3V32 z = _mm_shuffle_ps( m, m, _MM_SHUFFLE( 2, 2, 2, 2 ) );

	return _mm_add_ps( _mm_add_ps( x, y ), z );
}

#else

#define B3_TRANSPOSE3( C1, C2, C3 )                                                                                              \
	{                                                                                                                            \
		float temp1 = C1.y;                                                                                                      \
		float temp2 = C1.z;                                                                                                      \
		float temp3 = C2.z;                                                                                                      \
                                                                                                                                 \
		C1.y = C2.x;                                                                                                             \
		C1.z = C3.x;                                                                                                             \
		C2.z = C3.y;                                                                                                             \
                                                                                                                                 \
		C2.x = temp1;                                                                                                            \
		C3.x = temp2;                                                                                                            \
		C3.y = temp3;                                                                                                            \
	}

static inline b3V32 b3SplatXV( b3V32 a )
{
	return B3_LITERAL( b3V32 ){ a.x, a.x, a.x };
}

static inline b3V32 b3SplatYV( b3V32 a )
{
	return B3_LITERAL( b3V32 ){ a.y, a.y, a.y };
}

static inline b3V32 b3SplatZV( b3V32 a )
{
	return B3_LITERAL( b3V32 ){ a.z, a.z, a.z };
}

static inline bool b3AnyGreaterEq3V( b3V32 a, b3V32 b )
{
	return a.x >= b.x || a.y >= b.y || a.z >= b.z;
}

static inline b3V32 b3Dot3V( b3V32 a, b3V32 b )
{
	float d = a.x * b.x + a.y * b.y + a.z * b.z;
	return B3_LITERAL( b3V32 ){ d, d, d };
}

#endif

bool b3TestBoundsTriangleOverlap( b3V32 nodeCenter, b3V32 nodeExtent, b3V32 vertex1, b3V32 vertex2, b3V32 vertex3 )
{
	b3V32 two = b3SplatV( 2.0f );

	// Setup triangle
	vertex1 = b3SubV( vertex1, nodeCenter );
	vertex2 = b3SubV( vertex2, nodeCenter );
	vertex3 = b3SubV( vertex3, nodeCenter );

	// Face separation
	b3V32 triangleMin = b3MinV( vertex1, b3MinV( vertex2, vertex3 ) );
	b3V32 triangleMax = b3MaxV( vertex1, b3MaxV( vertex2, vertex3 ) );

	b3V32 separation1 = b3SubV( triangleMin, nodeExtent );
	b3V32 separation2 = b3AddV( triangleMax, nodeExtent );

	b3V32 faceSeparation = b3MaxV( separation1, b3NegV( separation2 ) );
	if ( b3AnyGreater3V( faceSeparation, b3_zeroV ) )
	{
		return false;
	}

	// SAT: Face separation
	b3V32 edge1 = b3SubV( vertex2, vertex1 );
	b3V32 edge2 = b3SubV( vertex3, vertex2 );
	b3V32 edge3 = b3SubV( vertex1, vertex3 );

	b3V32 normal = b3CrossV( edge1, edge2 );

	b3V32 triangleSeparation = b3SubV( b3AbsV( b3Dot3V( normal, vertex1 ) ), b3Dot3V( b3AbsV( normal ), nodeExtent ) );
	if ( b3AnyGreater3V( triangleSeparation, b3_zeroV ) )
	{
		return false;
	}

	// SAT: Edge separation
	b3V32 edgeSeparation1 = b3SubV( b3SubV( b3AbsV( b3CrossV( edge1, b3AddV( vertex1, vertex3 ) ) ), b3AbsV( b3CrossV( edge1, edge3 ) ) ),
									b3MulV( two, b3ModifiedCrossV( b3AbsV( edge1 ), nodeExtent ) ) );
	if ( b3AnyGreater3V( edgeSeparation1, b3_zeroV ) )
	{
		return false;
	}

	b3V32 edgeSeparation2 = b3SubV( b3SubV( b3AbsV( b3CrossV( edge2, b3AddV( vertex1, vertex2 ) ) ), b3AbsV( b3CrossV( edge2, edge1 ) ) ),
									b3MulV( two, b3ModifiedCrossV( b3AbsV( edge2 ), nodeExtent ) ) );
	if ( b3AnyGreater3V( edgeSeparation2, b3_zeroV ) )
	{
		return false;
	}

	b3V32 edgeSeparation3 = b3SubV( b3SubV( b3AbsV( b3CrossV( edge3, b3AddV( vertex2, vertex3 ) ) ), b3AbsV( b3CrossV( edge3, edge2 ) ) ),
									b3MulV( two, b3ModifiedCrossV( b3AbsV( edge3 ), nodeExtent ) ) );
	if ( b3AnyGreater3V( edgeSeparation3, b3_zeroV ) )
	{
		return false;
	}

	return true;
}

float b3IntersectRayTriangle( b3V32 rayStart, b3V32 rayDelta, b3V32 vertex1, b3V32 vertex2, b3V32 vertex3 )
{
	// Test if ray intersects this triangle sharing same calculations for each triangle
	{
		b3V32 edge1 = b3SubV( vertex3, vertex2 );
		b3V32 edge2 = b3SubV( vertex1, vertex3 );
		b3V32 edge3 = b3SubV( vertex2, vertex1 );

		b3V32 midPoint1 = b3MulV( b3_halfV, b3AddV( vertex2, vertex3 ) );
		b3V32 midPoint2 = b3MulV( b3_halfV, b3AddV( vertex3, vertex1 ) );
		b3V32 midPoint3 = b3MulV( b3_halfV, b3AddV( vertex1, vertex2 ) );

		b3V32 normal1 = b3CrossV( edge1, b3SubV( midPoint1, rayStart ) );
		b3V32 normal2 = b3CrossV( edge2, b3SubV( midPoint2, rayStart ) );
		b3V32 normal3 = b3CrossV( edge3, b3SubV( midPoint3, rayStart ) );
		B3_TRANSPOSE3( normal1, normal2, normal3 );

		b3V32 rayDeltaX = b3SplatXV( rayDelta );
		b3V32 rayDeltaY = b3SplatYV( rayDelta );
		b3V32 rayDeltaZ = b3SplatZV( rayDelta );

		b3V32 volumes = b3AddV( b3AddV( b3MulV( normal1, rayDeltaX ), b3MulV( normal2, rayDeltaY ) ), b3MulV( normal3, rayDeltaZ ) );
		if ( b3AnyLess3V( volumes, b3_zeroV ) )
		{
			return 1.0f;
		}
	}

	// Compute intersection with triangle plane
	b3V32 edge1 = b3SubV( vertex2, vertex1 );
	b3V32 edge2 = b3SubV( vertex3, vertex1 );
	b3V32 normal = b3CrossV( edge1, edge2 );

	b3V32 denominator = b3Dot3V( normal, rayDelta );
	if ( b3AnyGreaterEq3V( denominator, b3_zeroV ) )
	{
		return 1.0f;
	}

	b3V32 lambda = b3DivV( b3Dot3V( normal, b3SubV( vertex1, rayStart ) ), denominator );
	if ( b3AnyLessEq3V( lambda, b3_zeroV ) )
	{
		return 1.0f;
	}

	lambda = b3MinV( lambda, b3_oneV );
	return b3GetXV( lambda );
}
