// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "math_internal.h"

#include "box3d/collision.h"
#include "box3d/constants.h"

#define B3_MAX_SIMPLEX_VERTICES 4
#define B3_MAX_GJK_ITERATIONS 32

int b3GetProxySupport( const b3ShapeProxy* proxy, b3Vec3 axis )
{
	int count = proxy->count;
	const b3Vec3* points = proxy->points;

	B3_ASSERT( count > 0 );
	B3_ASSERT( points != NULL );

	// We move the first vertex into the origin for improved precision.
	// This is necessary since we don't have shape transforms and
	// vertices can potentially be far away from the origin (large).
	b3Vec3 origin = points[0];
	int maxIndex = 0;
	float maxProjection = 0.0f;

	for ( int index = 1; index < count; ++index )
	{
		// We subtract the first vertex since we are shifting into the origin.
		float projection = b3Dot( axis, b3Sub( points[index], origin ) );
		if ( projection > maxProjection )
		{
			maxIndex = index;
			maxProjection = projection;
		}
	}

	return maxIndex;
}

int b3GetPointSupport( const b3Vec3* points, int count, b3Vec3 axis )
{
	B3_ASSERT( count > 0 );
	B3_ASSERT( points != NULL );

	// We move the first vertex into the origin for improved precision.
	// This is necessary since we don't have shape transforms and
	// vertices can potentially be far away from the origin (large).
	b3Vec3 origin = points[0];
	int maxIndex = 0;
	float maxProjection = 0.0f;

	for ( int index = 1; index < count; ++index )
	{
		// We subtract the first vertex since we are shifting into the origin.
		float projection = b3Dot( axis, b3Sub( points[index], origin ) );
		if ( projection > maxProjection )
		{
			maxIndex = index;
			maxProjection = projection;
		}
	}

	return maxIndex;
}

static void b3BarycentricCoordsEdge( float out[3], b3Vec3 a, b3Vec3 b )
{
	b3Vec3 ab = b3Sub( b, a );

	// Last element is divisor
	float divisor = b3Dot( ab, ab );

	out[0] = b3Dot( b, ab );
	out[1] = -b3Dot( a, ab );
	out[2] = divisor;
}

static void b3BarycentricCoordsTri( float out[4], b3Vec3 a, b3Vec3 b, b3Vec3 c )
{
	b3Vec3 ab = b3Sub( b, a );
	b3Vec3 ac = b3Sub( c, a );

	b3Vec3 bXC = b3Cross( b, c );
	b3Vec3 cXA = b3Cross( c, a );
	b3Vec3 aXB = b3Cross( a, b );

	b3Vec3 abXAc = b3Cross( ab, ac );

	// Last element is divisor
	float divisor = b3Dot( abXAc, abXAc );

	out[0] = b3Dot( bXC, abXAc );
	out[1] = b3Dot( cXA, abXAc );
	out[2] = b3Dot( aXB, abXAc );
	out[3] = divisor;
}

static void b3BarycentricCoordsTet( float out[5], b3Vec3 a, b3Vec3 b, b3Vec3 c, b3Vec3 d )
{
	b3Vec3 ab = b3Sub( b, a );
	b3Vec3 ac = b3Sub( c, a );
	b3Vec3 ad = b3Sub( d, a );

	// Last element is divisor (forced to be positive)
	float divisor = b3ScalarTripleProduct( ab, ac, ad );

	float sign = divisor < 0.0f ? -1.0f : 1.0f;
	out[0] = sign * b3ScalarTripleProduct( b, c, d );
	out[1] = sign * b3ScalarTripleProduct( a, d, c );
	out[2] = sign * b3ScalarTripleProduct( a, b, d );
	out[3] = sign * b3ScalarTripleProduct( a, c, b );
	out[4] = sign * divisor;
}

static float b3GetMetric( const b3Simplex* simplex )
{
	int count = simplex->count;
	B3_ASSERT( 1 <= count && count <= 4 );

	const b3SimplexVertex* vertices = simplex->vertices;

	switch ( count )
	{
		case 1:
		{
			return 0.0f;
		}

		case 2:
		{
			b3Vec3 a = vertices[0].w;
			b3Vec3 b = vertices[1].w;
			return b3Distance( a, b );
		}

		case 3:
		{
			b3Vec3 a = vertices[0].w;
			b3Vec3 b = vertices[1].w;
			b3Vec3 c = vertices[2].w;
			return b3Length( b3Cross( b3Sub( b, a ), b3Sub( c, a ) ) ) / 2.0f;
		}

		case 4:
		{
			b3Vec3 a = vertices[0].w;
			b3Vec3 b = vertices[1].w;
			b3Vec3 c = vertices[2].w;
			b3Vec3 d = vertices[3].w;
			return b3ScalarTripleProduct( b3Sub( b, a ), b3Sub( c, a ), b3Sub( d, a ) ) / 6.0f;
		}

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}

	return 0.0f;
}

static void b3WriteCache( b3SimplexCache* cache, const b3Simplex* simplex )
{
	int count = simplex->count;
	cache->metric = b3GetMetric( simplex );
	cache->count = (uint16_t)count;
	for ( int index = 0; index < count; ++index )
	{
		cache->indexA[index] = (uint8_t)simplex->vertices[index].indexA;
		cache->indexB[index] = (uint8_t)simplex->vertices[index].indexB;
	}
}

static bool b3SolveSimplex2( b3Simplex* simplex )
{
	b3SimplexVertex* vs = simplex->vertices;
	B3_ASSERT( simplex->count == 2 );

	// Vertex regions
	//float wAB[3];

	b3Vec3 a = vs[0].w;
	b3Vec3 b = vs[1].w;
	b3Vec3 ab = b3Sub( b, a );

	// Last element is divisor
	float divisor = b3Dot( ab, ab );

	float u = b3Dot( b, ab );
	float v = -b3Dot( a, ab );
	//wAB[2] = divisor;

	// V( A )
	if ( v <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0].a = 1.0f;

		return true;
	}

	// V( B )
	if ( u <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = vs[1];
		vs[0].a = 1.0f;

		return true;
	}

	// Edge region
	if ( divisor <= 0.0f )
	{
		return false;
	}

	// VR( AB )
	float denominator = 1.0f / divisor;
	vs[0].a = denominator * u;
	vs[1].a = denominator * v;

	return true;
}

static bool b3SolveSimplex3( b3Simplex* simplex )
{
	b3SimplexVertex* vs = simplex->vertices;
	B3_ASSERT( simplex->count == 3 );

	// Get simplex (be aware of aliasing here!)
	b3SimplexVertex v1 = vs[0];
	b3SimplexVertex v2 = vs[1];
	b3SimplexVertex v3 = vs[2];

	// Vertex regions
	float wAB[3], wBC[3], wCA[3];
	b3BarycentricCoordsEdge( wAB, v1.w, v2.w );
	b3BarycentricCoordsEdge( wBC, v2.w, v3.w );
	b3BarycentricCoordsEdge( wCA, v3.w, v1.w );

	// VR( A )
	if ( wAB[1] <= 0.0f && wCA[0] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = v1;
		vs[0].a = 1.0f;

		return true;
	}

	// VR( B )
	if ( wBC[1] <= 0.0f && wAB[0] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = v2;
		vs[0].a = 1.0f;

		return true;
	}

	// VR( C )
	if ( wCA[1] <= 0.0f && wBC[0] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = v3;
		vs[0].a = 1.0f;

		return true;
	}

	// Edge regions
	float wABC[4];
	b3BarycentricCoordsTri( wABC, v1.w, v2.w, v3.w );

	// VR( AB )
	if ( wABC[2] <= 0.0f && wAB[0] > 0.0f && wAB[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = v1;
		vs[1] = v2;

		// Normalize
		float divisor = wAB[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wAB[0] / divisor;
		vs[1].a = wAB[1] / divisor;

		return true;
	}

	// VR( BC )
	if ( wABC[0] <= 0.0f && wBC[0] > 0.0f && wBC[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = v2;
		vs[1] = v3;

		// Normalize
		float divisor = wBC[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wBC[0] / divisor;
		vs[1].a = wBC[1] / divisor;

		return true;
	}

	// VR( CA )
	if ( wABC[1] <= 0.0f && wCA[0] > 0.0f && wCA[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = v3;
		vs[1] = v1;

		// Normalize
		float divisor = wCA[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wCA[0] / divisor;
		vs[1].a = wCA[1] / divisor;

		return true;
	}

	// Face region
	float divisor = wABC[3];
	if ( divisor <= 0.0f )
	{
		return false;
	}

	// VR( ABC )
	vs[0].a = wABC[0] / divisor;
	vs[1].a = wABC[1] / divisor;
	vs[2].a = wABC[2] / divisor;

	return true;
}

static bool b3SolveSimplex4( b3Simplex* simplex )
{
	b3SimplexVertex* vs = simplex->vertices;

	// Get simplex (be aware of aliasing here!)
	B3_ASSERT( simplex->count == 4 );
	b3SimplexVertex vertexA = vs[0];
	b3SimplexVertex vertexB = vs[1];
	b3SimplexVertex vertexC = vs[2];
	b3SimplexVertex vertexD = vs[3];

	// Vertex region
	float wAB[3], wAC[3], wAD[3], wBC[3], wCD[3], wDB[3];
	b3BarycentricCoordsEdge( wAB, vertexA.w, vertexB.w );
	b3BarycentricCoordsEdge( wAC, vertexA.w, vertexC.w );
	b3BarycentricCoordsEdge( wAD, vertexA.w, vertexD.w );
	b3BarycentricCoordsEdge( wBC, vertexB.w, vertexC.w );
	b3BarycentricCoordsEdge( wCD, vertexC.w, vertexD.w );
	b3BarycentricCoordsEdge( wDB, vertexD.w, vertexB.w );

	// VR( A )
	if ( wAB[1] <= 0.0f && wAC[1] <= 0.0f && wAD[1] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = vertexA;

		vs[0].a = 1.0f;

		return true;
	}

	// VR( B )
	if ( wAB[0] <= 0.0f && wDB[0] <= 0.0f && wBC[1] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = vertexB;

		vs[0].a = 1.0f;

		return true;
	}

	// VR( C )
	if ( wAC[0] <= 0.0f && wBC[0] <= 0.0f && wCD[1] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = vertexC;

		vs[0].a = 1.0f;

		return true;
	}

	// VR( D )
	if ( wAD[0] <= 0.0f && wCD[0] <= 0.0f && wDB[1] <= 0.0f )
	{
		// Reduce simplex
		simplex->count = 1;
		vs[0] = vertexD;

		vs[0].a = 1.0f;

		return true;
	}

	// Edge region
	float wACB[4], wABD[4], wADC[4], wBCD[4];
	b3BarycentricCoordsTri( wACB, vertexA.w, vertexC.w, vertexB.w );
	b3BarycentricCoordsTri( wABD, vertexA.w, vertexB.w, vertexD.w );
	b3BarycentricCoordsTri( wADC, vertexA.w, vertexD.w, vertexC.w );
	b3BarycentricCoordsTri( wBCD, vertexB.w, vertexC.w, vertexD.w );

	// VR( AB )
	if ( wABD[2] <= 0.0f && wACB[1] <= 0.0f && wAB[0] > 0.0f && wAB[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexA;
		vs[1] = vertexB;

		// Normalize
		float divisor = wAB[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wAB[0] / divisor;
		vs[1].a = wAB[1] / divisor;

		return true;
	}

	// VR( AC )
	if ( wACB[2] <= 0.0f && wADC[1] <= 0.0f && wAC[0] > 0.0f && wAC[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexA;
		vs[1] = vertexC;

		// Normalize
		float divisor = wAC[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wAC[0] / divisor;
		vs[1].a = wAC[1] / divisor;

		return true;
	}

	// VR( AD )
	if ( wADC[2] <= 0.0f && wABD[1] <= 0.0f && wAD[0] > 0.0f && wAD[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexA;
		vs[1] = vertexD;

		// Normalize
		float divisor = wAD[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wAD[0] / divisor;
		vs[1].a = wAD[1] / divisor;

		return true;
	}

	// VR( BC )
	if ( wACB[0] <= 0.0f && wBCD[2] <= 0.0f && wBC[0] > 0.0f && wBC[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexB;
		vs[1] = vertexC;

		// Normalize
		float divisor = wBC[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wBC[0] / divisor;
		vs[1].a = wBC[1] / divisor;

		return true;
	}

	// VR( CD )
	if ( wADC[0] <= 0.0f && wBCD[0] <= 0.0f && wCD[0] > 0.0f && wCD[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexC;
		vs[1] = vertexD;

		// Normalize
		float divisor = wCD[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wCD[0] / divisor;
		vs[1].a = wCD[1] / divisor;

		return true;
	}

	// VR( DB )
	if ( wABD[0] <= 0.0f && wBCD[1] <= 0.0f && wDB[0] > 0.0f && wDB[1] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 2;
		vs[0] = vertexD;
		vs[1] = vertexB;

		// Normalize
		float divisor = wDB[2];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wDB[0] / divisor;
		vs[1].a = wDB[1] / divisor;

		return true;
	}

	// Face regions
	float wABCD[5];
	b3BarycentricCoordsTet( wABCD, vertexA.w, vertexB.w, vertexC.w, vertexD.w );

	// VR( ACB )
	if ( wABCD[3] < 0.0f && wACB[0] > 0.0f && wACB[1] > 0.0f && wACB[2] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 3;
		vs[0] = vertexA;
		vs[1] = vertexC;
		vs[2] = vertexB;

		// Normalize
		float divisor = wACB[3];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wACB[0] / divisor;
		vs[1].a = wACB[1] / divisor;
		vs[2].a = wACB[2] / divisor;

		return true;
	}

	// VR( ABD )
	if ( wABCD[2] < 0.0f && wABD[0] > 0.0f && wABD[1] > 0.0f && wABD[2] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 3;
		vs[0] = vertexA;
		vs[1] = vertexB;
		vs[2] = vertexD;

		// Normalize
		float divisor = wABD[3];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wABD[0] / divisor;
		vs[1].a = wABD[1] / divisor;
		vs[2].a = wABD[2] / divisor;

		return true;
	}

	// VR( ADC )
	if ( wABCD[1] < 0.0f && wADC[0] > 0.0f && wADC[1] > 0.0f && wADC[2] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 3;
		vs[0] = vertexA;
		vs[1] = vertexD;
		vs[2] = vertexC;

		// Normalize
		float divisor = wADC[3];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wADC[0] / divisor;
		vs[1].a = wADC[1] / divisor;
		vs[2].a = wADC[2] / divisor;

		return true;
	}

	// VR( BCD )
	if ( wABCD[0] < 0.0f && wBCD[0] > 0.0f && wBCD[1] > 0.0f && wBCD[2] > 0.0f )
	{
		// Reduce simplex
		simplex->count = 3;
		vs[0] = vertexB;
		vs[1] = vertexC;
		vs[2] = vertexD;

		// Normalize
		float divisor = wBCD[3];
		if ( divisor <= 0.0f )
		{
			return false;
		}

		vs[0].a = wBCD[0] / divisor;
		vs[1].a = wBCD[1] / divisor;
		vs[2].a = wBCD[2] / divisor;

		return true;
	}

	// *** Inside tetrahedron ***
	float divisor = wABCD[4];
	if ( divisor <= 0.0f )
	{
		return false;
	}

	// VR( ABCD )
	vs[0].a = wABCD[0] / divisor;
	vs[1].a = wABCD[1] / divisor;
	vs[2].a = wABCD[2] / divisor;
	vs[3].a = wABCD[3] / divisor;

	return true;
}

static void b3ComputeWitnessPoints( const b3Simplex* simplex, b3Vec3* vertexA, b3Vec3* vertexB )
{
	const b3SimplexVertex* vs = simplex->vertices;
	int count = simplex->count;
	B3_ASSERT( 1 <= count && count <= 4 );

	switch ( count )
	{
		case 1:
			*vertexA = vs[0].wA;
			*vertexB = vs[0].wB;
			break;

		case 2:
			*vertexA = b3Blend2( vs[0].a, vs[0].wA, vs[1].a, vs[1].wA );
			*vertexB = b3Blend2( vs[0].a, vs[0].wB, vs[1].a, vs[1].wB );
			break;

		case 3:
			*vertexA = b3Blend3( vs[0].a, vs[0].wA, vs[1].a, vs[1].wA, vs[2].a, vs[2].wA );
			*vertexB = b3Blend3( vs[0].a, vs[0].wB, vs[1].a, vs[1].wB, vs[2].a, vs[2].wB );
			break;

		case 4:
		{
			// Force identical points and *zero* distance
			b3Vec3 sum = b3Add( b3Blend2( vs[0].a, vs[0].wA, vs[1].a, vs[1].wA ),
								b3Blend2( vs[2].a, vs[2].wA, vs[3].a, vs[3].wA ) );
			*vertexA = sum;
			*vertexB = sum;
		}
		break;

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}
}

b3DistanceOutput b3ShapeDistance( const b3DistanceInput* input, b3SimplexCache* cache, b3Simplex* simplexes, int simplexCapacity )
{
	// The query runs in frame A using the relative pose of B in A.
	b3Transform xf = input->transform;

	// Use matrices for faster math
	b3Matrix3 m = b3MakeMatrixFromQuat( xf.q );
	b3Matrix3 mt = b3Transpose( m );

	const b3ShapeProxy* proxyA = &input->proxyA;
	const b3ShapeProxy* proxyB = &input->proxyB;

	// Compute initial simplex from cache
	B3_ASSERT( cache->count <= B3_MAX_SIMPLEX_VERTICES );

	b3Simplex simplex = { 0 };
	b3SimplexVertex* vs = simplex.vertices;

	simplex.count = cache->count;
	for ( int i = 0; i < cache->count; ++i )
	{
		int index1 = cache->indexA[i];
		int index2 = cache->indexB[i];

		B3_ASSERT( 0 <= index1 && index1 < proxyA->count );
		B3_ASSERT( 0 <= index2 && index2 < proxyB->count );

		b3Vec3 vertex1 = proxyA->points[index1];
		b3Vec3 vertex2 = b3Add( b3MulMV( m, proxyB->points[index2] ), xf.p );

		vs[i].indexA = index1;
		vs[i].indexB = index2;
		vs[i].wA = vertex1;
		vs[i].wB = vertex2;
		vs[i].w = b3Sub( vertex2, vertex1 );
		vs[i].a = 0.0f;
	}

	// Compute the new simplex metric, if it is substantially
	// different than the old metric flush the simplex.
	if ( simplex.count > 0 )
	{
		float metric1 = cache->metric;
		float metric2 = b3GetMetric( &simplex );

		// todo the tetrahedron metric can be negative
		if ( 2.0f * metric1 < metric2 || metric2 < 0.5f * metric1 || metric2 < FLT_EPSILON )
		{
			// Flush the simplex
			simplex.count = 0;
		}
	}

	// If the cache is invalid or empty
	if ( simplex.count == 0 )
	{
		b3Vec3 vertex1 = proxyA->points[0];
		b3Vec3 vertex2 = b3Add( b3MulMV( m, proxyB->points[0] ), xf.p );

		simplex.count = 1;
		simplex.vertices[0].indexA = 0;
		simplex.vertices[0].indexB = 0;
		simplex.vertices[0].wA = vertex1;
		simplex.vertices[0].wB = vertex2;
		simplex.vertices[0].w = b3Sub( vertex2, vertex1 );
		simplex.vertices[0].a = 0.0f;
	}

	b3Simplex backup = { 0 };

	int simplexIndex = 0;
	if ( simplexes != NULL && simplexIndex < simplexCapacity )
	{
		simplexes[simplexIndex] = simplex;
		simplexIndex += 1;
	}

	b3DistanceOutput distanceOutput = { 0 };

	// Keep track of squared distance
	float distanceSq = FLT_MAX;

	b3Vec3 normal = b3Vec3_zero;

	// Run GJK
	int iteration = 0;
	for ( ; iteration < B3_MAX_GJK_ITERATIONS; ++iteration )
	{
		// Solve simplex
		bool solved = false;
		switch ( simplex.count )
		{
			case 1:
				simplex.vertices[0].a = 1.0f;
				solved = true;
				break;

			case 2:
				solved = b3SolveSimplex2( &simplex );
				break;

			case 3:
				solved = b3SolveSimplex3( &simplex );
				break;

			case 4:
				solved = b3SolveSimplex4( &simplex );
				break;

			default:
				B3_ASSERT( !"Should never get here!" );
				break;
		}

		if ( solved == false )
		{
			// No progress - reconstruct last simplex
			B3_ASSERT( backup.count != 0 );
			simplex = backup;
			break;
		}

		if ( simplexes != NULL && simplexIndex < simplexCapacity )
		{
			simplexes[simplexIndex] = simplex;
			simplexIndex += 1;
			distanceOutput.iterations = iteration;
			distanceOutput.simplexCount = simplexIndex;
		}

		if ( simplex.count == B3_MAX_SIMPLEX_VERTICES )
		{
			// Overlap
			b3Vec3 localPointA, localPointB;
			b3ComputeWitnessPoints( &simplex, &localPointA, &localPointB );
			distanceOutput.pointA = localPointA;
			distanceOutput.pointB = localPointB;
			return distanceOutput;
		}

		// Assure distance progression
		float oldDistanceSq = distanceSq;

		// Compute closest point
		b3Vec3 closestPoint = { 0 };

		switch ( simplex.count )
		{
			case 1:
				closestPoint = vs[0].w;
				break;

			case 2:
				closestPoint = b3Blend2( vs[0].a, vs[0].w, vs[1].a, vs[1].w );
				break;

			case 3:
				closestPoint = b3Blend3( vs[0].a, vs[0].w, vs[1].a, vs[1].w, vs[2].a, vs[2].w );
				break;

			case 4:
				closestPoint = b3Add( b3Blend2( vs[0].a, vs[0].w, vs[1].a, vs[1].w ),
									  b3Blend2( vs[2].a, vs[2].w, vs[3].a, vs[3].w ) );
				break;

			default:
				B3_ASSERT( !"Should never get here!" );
				break;
		}

		distanceSq = b3Dot( closestPoint, closestPoint );

		if ( distanceSq >= oldDistanceSq )
		{
			// No progress - reconstruct last simplex
			B3_ASSERT( backup.count != 0 );
			simplex = backup;
			break;
		}

		// Build new tentative support point
		b3Vec3 searchDirection = { 0 };

		switch ( simplex.count )
		{
			case 1:
			{
				// v = -A
				searchDirection = b3Neg( vs[0].w );
			}
			break;

			case 2:
			{
				// v = (AB x AO) x AB
				b3Vec3 a = vs[0].w;
				b3Vec3 b = vs[1].w;

				b3Vec3 ab = b3Sub( b, a );

				searchDirection = b3Cross( b3Cross( ab, b3Neg( a ) ), ab );
			}
			break;

			case 3:
			{
				// v = AB x AC or v = AC x AB
				b3Vec3 a = vs[0].w;
				b3Vec3 b = vs[1].w;
				b3Vec3 c = vs[2].w;

				b3Vec3 ab = b3Sub( b, a );
				b3Vec3 ac = b3Sub( c, a );

				b3Vec3 n = b3Cross( ab, ac );

				searchDirection = b3Dot( n, a ) < 0.0f ? n : b3Neg( n );
			}
			break;

			default:
				B3_ASSERT( !"Should never get here!" );
				break;
		}

		if ( b3LengthSquared( searchDirection ) < 1000.0f * FLT_MIN )
		{
			// The origin is probably contained by a line segment or triangle.
			// Thus the shapes are overlapped.
			b3Vec3 localPointA, localPointB;
			b3ComputeWitnessPoints( &simplex, &localPointA, &localPointB );
			distanceOutput.pointA = localPointA;
			distanceOutput.pointB = localPointB;
			B3_VALIDATE( b3Distance( localPointA, localPointB ) < FLT_EPSILON );
			return distanceOutput;
		}

		normal = b3Neg( searchDirection );

		// Get new support points
		b3Vec3 searchDirection1 = searchDirection;
		int indexA = b3GetProxySupport( &input->proxyA, b3Neg( searchDirection1 ) );
		b3Vec3 supportA = input->proxyA.points[indexA];
		b3Vec3 searchDirection2 = b3MulMV( mt, searchDirection );
		int indexB = b3GetProxySupport( &input->proxyB, searchDirection2 );
		b3Vec3 supportB = b3Add( b3MulMV( m, input->proxyB.points[indexB] ), xf.p );

		// Save current simplex and add new vertex - this can fail if we detect cycling
		backup = simplex;

		// Check for duplicate support points. This is the main termination criteria.
		bool duplicate = false;
		for ( int i = 0; i < simplex.count; ++i )
		{
			if ( vs[i].indexA == indexA && vs[i].indexB == indexB )
			{
				duplicate = true;
				break;
			}
		}

		if ( duplicate )
		{
			break;
		}

		vs[simplex.count].indexA = indexA;
		vs[simplex.count].indexB = indexB;
		vs[simplex.count].wA = supportA;
		vs[simplex.count].wB = supportB;
		vs[simplex.count].w = b3Sub( supportB, supportA );
		simplex.count += 1;
	}

	normal = b3Normalize( normal );
	if ( b3IsNormalized( normal ) == false )
	{
		// Treat as overlap
		return distanceOutput;
	}

	// Build witness points and safe cache
	b3Vec3 localPointA, localPointB;
	b3ComputeWitnessPoints( &simplex, &localPointA, &localPointB );
	b3WriteCache( cache, &simplex );

	// Results stay in frame A
	distanceOutput.pointA = localPointA;
	distanceOutput.pointB = localPointB;
	distanceOutput.distance = b3Distance( localPointA, localPointB );
	distanceOutput.normal = normal;
	distanceOutput.iterations = iteration;
	distanceOutput.simplexCount = simplexIndex;

	// Apply radii if requested
	if ( input->useRadii )
	{
		float rA = input->proxyA.radius;
		float rB = input->proxyB.radius;
		distanceOutput.distance = b3MaxFloat( 0.0f, distanceOutput.distance - rA - rB );

		// Keep closest points on perimeter even if overlapped, this way the points move smoothly.
		distanceOutput.pointA = b3Add( distanceOutput.pointA, b3MulSV( rA, normal ) );
		distanceOutput.pointB = b3Sub( distanceOutput.pointB, b3MulSV( rB, normal ) );
	}

	return distanceOutput;
}


// Separation function:
// f(t) = (c2 + t * dp2 - c1 - t * dp1 ) * n

// Root finding : f(t) - target = 0
// (c2 + t * dp2 - c1 - t * dp1 ) * n - target = 0
// (c2 - c1) * n + t * (dp2 - dp1) * n - target = 0
// t = [target - (c2 - c1) * n] / [(dp2 - dp1) * n]
// t = (target - d) / [(dp2 - dp1) * n]

b3CastOutput b3ShapeCast( const b3ShapeCastPairInput* input )
{
	// Compute tolerance
	float linearSlop = B3_LINEAR_SLOP;
	float totalRadius = input->proxyA.radius + input->proxyB.radius;
	float target = b3MaxFloat( linearSlop, totalRadius - linearSlop );
	float tolerance = 0.25f * linearSlop;

	B3_ASSERT( target > tolerance );

	// Prepare input for distance query
	b3SimplexCache cache = { 0 };

	float alpha = 0.0f;

	b3DistanceInput distanceInput = { 0 };
	distanceInput.proxyA = input->proxyA;
	distanceInput.proxyB = input->proxyB;
	distanceInput.useRadii = false;

	// The whole cast runs in frame A. Advance the relative pose of B in float each iteration,
	// which keeps the math near the local origin and avoids re-relativizing world poses.
	distanceInput.transform = input->transform;

	b3Vec3 delta2 = input->translationB;
	b3DistanceOutput distanceOutput = { 0 };
	b3CastOutput output = { 0 };
	output.triangleIndex = B3_NULL_INDEX;

	int iteration = 0;
	const int maxIterations = 20;

	for ( ; iteration < maxIterations; ++iteration )
	{
		output.iterations += 1;

		distanceOutput = b3ShapeDistance( &distanceInput, &cache, NULL, 0 );

		if ( distanceOutput.distance < target + tolerance )
		{
			if ( iteration == 0 )
			{
				if ( input->canEncroach && distanceOutput.distance > 2.0f * linearSlop )
				{
					target = distanceOutput.distance - linearSlop;
				}
				else
				{
					// Initial overlap
					output.hit = true;

					// Compute a common point
					b3Vec3 c1 = b3MulAdd( distanceOutput.pointA, input->proxyA.radius, distanceOutput.normal );
					b3Vec3 c2 = b3MulAdd( distanceOutput.pointB, -input->proxyB.radius, distanceOutput.normal );
					output.point = b3Lerp( c1, c2, 0.5f );
					return output;
				}
			}
			else
			{
				// Logging for bad input data
				if ( distanceOutput.distance > 0.0f && b3IsNormalized( distanceOutput.normal ) == false )
				{
					for ( int i = 0; i < input->proxyA.count; ++i )
					{
						b3Vec3 p = input->proxyA.points[i];
						b3Log( "pointA[%d] = {%.9f, %.9f, %.9f}", i, p.x, p.y, p.z );
					}
					b3Log( "radiusA = %.9f", input->proxyA.radius );

					for ( int i = 0; i < input->proxyB.count; ++i )
					{
						b3Vec3 p = input->proxyB.points[i];
						b3Log( "pointB[%d] = {%.9f, %.9f, %.9f}", i, p.x, p.y, p.z );
					}
					b3Log( "radiusB = %.9f", input->proxyB.radius );

					{
						b3Transform xf = input->transform;
						b3Log( "transform = {{%.9f, %.9f, %.9f}, {{%.9f, %.9f, %.9f}, %.9f}", xf.p.x, xf.p.y, xf.p.z, xf.q.v.x,
							   xf.q.v.y, xf.q.v.z, xf.q.s );
					}

					{
						b3Vec3 t = input->translationB;
						b3Log( "t = {%.9f, %.9f, %.9f}", t.x, t.y, t.z );
					}

					b3Log( "maxFraction = %.9f, canEncroach = %d", input->maxFraction, input->canEncroach );

					// Numerical problem. Likely extreme input.
					return output;
				}

				// Hitting this assert implies that the algorithm brought the shapes too close.
				// B3_ASSERT( distanceOutput.distance > 0.0f && b3IsNormalized( distanceOutput.normal ) );

				output.fraction = alpha;
				output.point = b3MulAdd( distanceOutput.pointA, input->proxyA.radius, distanceOutput.normal );
				output.normal = distanceOutput.normal;
				output.hit = true;
				return output;
			}
		}

		B3_ASSERT( distanceOutput.distance > 0.0f );
		B3_ASSERT( b3IsNormalized( distanceOutput.normal ) );

		// Check if shapes are approaching each other
		float denominator = b3Dot( delta2, distanceOutput.normal );
		if ( denominator >= 0.0f )
		{
			// Miss
			return output;
		}

		// Advance sweep
		alpha += ( target - distanceOutput.distance ) / denominator;
		if ( alpha >= input->maxFraction )
		{
			// Success!
			return output;
		}

		distanceInput.transform.p = b3MulAdd( input->transform.p, alpha, delta2 );
	}

	// Failure!
	return output;
}

b3Transform b3GetSweepTransform( const b3Sweep* sweep, float time )
{
	b3Transform transform;
	transform.q = b3NLerp( sweep->q1, sweep->q2, time );
	transform.p = b3Sub( b3Lerp( sweep->c1, sweep->c2, time ), b3RotateVector( transform.q, sweep->localCenter ) );
	return transform;
}

static inline b3Transform b3GetFinalSweepTransform( const b3Sweep* sweep )
{
	b3Transform transform;
	transform.q = sweep->q2;
	transform.p = b3Sub( sweep->c2, b3RotateVector( transform.q, sweep->localCenter ) );
	return transform;
}

static int b3UniqueCount( int vertexCount, int vertices[3] )
{
	B3_ASSERT( 1 <= vertexCount && vertexCount <= 3 );

	switch ( vertexCount )
	{
		case 1:
			return 1;

		case 2:
			return vertices[0] != vertices[1] ? 2 : 1;

		case 3:
			if ( vertices[0] != vertices[1] && vertices[0] != vertices[2] && vertices[1] != vertices[2] )
			{
				// All different
				return 3;
			}

			if ( vertices[0] == vertices[1] && vertices[0] == vertices[2] && vertices[1] == vertices[2] )
			{
				// All equal
				return 1;
			}

			return 2;

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}

	return 0;
}

// This checks if the cross product of two edges switches direction.
static inline bool b3CheckFastEdges( b3Transform xfA, b3Vec3 localEdgeA, b3Transform xfB, b3Vec3 localEdgeB, b3Vec3 axis0 )
{
	// By taking the local witness axes we make sure that we
	// get the correct orientations (e.g. if one axis was flipped)!
	b3Vec3 edgeA = b3RotateVector( xfA.q, localEdgeA );
	b3Vec3 edgeB = b3RotateVector( xfB.q, localEdgeB );
	b3Vec3 axis = b3Cross( edgeA, edgeB );
	return b3Dot( axis, axis0 ) < 0.0f;
}

typedef enum b3SeparationType
{
	b3_separationUnknown = 0,
	b3_separationVertices,
	b3_separationEdges,
	b3_separationFaceA,
	b3_separationFaceB,
} b3SeparationType;

typedef struct b3SeparationFunction
{
	const b3ShapeProxy* proxyA;
	const b3ShapeProxy* proxyB;
	b3Sweep sweepA;
	b3Sweep sweepB;

	// These are associated with different bodies depending on the separation function type.
	// It could be two local vectors/points on the same body (for example, both on bodyA).
	b3Vec3 witness1;
	b3Vec3 witness2;

	b3SeparationType type;
} b3SeparationFunction;

static b3SeparationFunction b3MakeSeparationFunction( const b3SimplexCache cache, const b3ShapeProxy* proxyA,
													  const b3Sweep* sweepA, const b3ShapeProxy* proxyB, const b3Sweep* sweepB,
													  b3Vec3 worldNormal, float t1 )
{
	B3_ASSERT( 1 <= cache.count && cache.count <= 3 );
	B3_VALIDATE( b3IsNormalized( worldNormal ) );

	b3SeparationFunction fcn = { 0 };
	fcn.proxyA = proxyA;
	fcn.proxyB = proxyB;
	fcn.sweepA = *sweepA;
	fcn.sweepB = *sweepB;
	fcn.type = b3_separationUnknown;

	int indexA[3] = { cache.indexA[0], cache.indexA[1], cache.indexA[2] };
	int indexB[3] = { cache.indexB[0], cache.indexB[1], cache.indexB[2] };

	int uniqueCountA = b3UniqueCount( cache.count, indexA );
	int uniqueCountB = b3UniqueCount( cache.count, indexB );

	b3Transform xfA1 = b3GetSweepTransform( sweepA, t1 );
	b3Transform xfB1 = b3GetSweepTransform( sweepB, t1 );

	b3Quat qA = xfA1.q;
	b3Quat qB = xfB1.q;

	// Minimize round-off
	b3Vec3 deltaP = b3Sub( xfB1.p, xfA1.p );

	switch ( cache.count )
	{
		case 1:
		{
			// Witness is the world space direction
			fcn.type = b3_separationVertices;
			fcn.witness1 = worldNormal;
		}
		break;

		case 2:
		{
			if ( uniqueCountA == 2 && uniqueCountB == 2 )
			{
				// Edge/Edge
				b3Vec3 vA1 = proxyA->points[indexA[0]];
				b3Vec3 localEdgeA = b3Sub( proxyA->points[indexA[1]], vA1 );
				localEdgeA = b3Normalize( localEdgeA );
				b3Vec3 edgeA = b3RotateVector( qA, localEdgeA );

				b3Vec3 vB1 = proxyB->points[indexB[0]];
				b3Vec3 localEdgeB = b3Sub( proxyB->points[indexB[1]], vB1 );
				localEdgeB = b3Normalize( localEdgeB );
				b3Vec3 edgeB = b3RotateVector( qB, localEdgeB );

				b3Vec3 axis = b3Cross( edgeA, edgeB );
				float lengthSquared = b3LengthSquared( axis );

				// Skip near parallel edges: |e1 x e1| = sin(alpha) * |e1| * |e2|
				const float kToleranceSquared = 0.05f * 0.05f;
				if ( lengthSquared < kToleranceSquared )
				{
					// The axis is not safe to normalize so we use a world axis instead!
					fcn.type = b3_separationVertices;
					fcn.witness1 = worldNormal;
				}
				else
				{
					b3Vec3 delta = b3Add( b3Sub( b3RotateVector( qB, vB1 ), b3RotateVector( qA, vA1 ) ), deltaP );
					if ( b3Dot( delta, axis ) < 0.0f )
					{
						// Make axis point from A to B
						axis = b3Neg( axis );
						localEdgeB = b3Neg( localEdgeB );
					}

					// Check for possible sign flip in edge/edge cross product
					b3Transform xfA2 = b3GetFinalSweepTransform( sweepA );
					b3Transform xfB2 = b3GetFinalSweepTransform( sweepB );
					bool fastEdges = b3CheckFastEdges( xfA2, localEdgeA, xfB2, localEdgeB, axis );
					if ( fastEdges == true )
					{
						// Not safe to use local edges, fall back to initial world space axis instead
						fcn.type = b3_separationVertices;
						fcn.witness1 = b3Normalize( axis );
					}
					else
					{
						// Edge cross product is safe. This converges faster than a fixed axis.
						fcn.type = b3_separationEdges;
						fcn.witness1 = localEdgeA;
						fcn.witness2 = localEdgeB;
					}
				}
			}
			else
			{
				B3_VALIDATE( b3IsNormalized( worldNormal ) );

				// Vertex versus edge, use world axis witness
				fcn.type = b3_separationVertices;
				fcn.witness1 = worldNormal;
			}
		}
		break;

		case 3:
		{
			if ( uniqueCountA == 3 )
			{
				b3Vec3 vA1 = proxyA->points[indexA[0]];
				b3Vec3 vA2 = proxyA->points[indexA[1]];
				b3Vec3 vA3 = proxyA->points[indexA[2]];
				b3Vec3 localAxisA = b3Cross( b3Sub( vA2, vA1 ), b3Sub( vA3, vA1 ) );
				localAxisA = b3Normalize( localAxisA );
				b3Vec3 axisA = b3RotateVector( qA, localAxisA );

				b3Vec3 localPointA = b3MulSV( 1.0f / 3.0f, b3Add( b3Add( vA1, vA2 ), vA3 ) );
				b3Vec3 localPointB = proxyB->points[indexB[0]];
				b3Vec3 delta = b3Add( b3Sub( b3RotateVector( qB, localPointB ), b3RotateVector( qA, localPointA ) ), deltaP );

				if ( b3Dot( delta, axisA ) < 0.0f )
				{
					// Make axis point from A to B
					localAxisA = b3Neg( localAxisA );
				}

				// Witness is the local plane of faceA
				fcn.type = b3_separationFaceA;
				fcn.witness1 = localAxisA;
				fcn.witness2 = localPointA;
			}
			else if ( uniqueCountB == 3 )
			{
				b3Vec3 vB1 = proxyB->points[indexB[0]];
				b3Vec3 vB2 = proxyB->points[indexB[1]];
				b3Vec3 vB3 = proxyB->points[indexB[2]];
				b3Vec3 localAxisB = b3Cross( b3Sub( vB2, vB1 ), b3Sub( vB3, vB1 ) );
				localAxisB = b3Normalize( localAxisB );
				b3Vec3 axisB = b3RotateVector( qB, localAxisB );

				b3Vec3 localPointA = proxyA->points[indexA[0]];
				b3Vec3 localPointB = b3MulSV( 1.0f / 3.0f, b3Add( b3Add( vB1, vB2 ), vB3 ) );
				b3Vec3 delta = b3Sub( b3Sub( b3RotateVector( qA, localPointA ), b3RotateVector( qB, localPointB ) ), deltaP );

				if ( b3Dot( delta, axisB ) < 0.0f )
				{
					// Make axis point from B to A
					localAxisB = b3Neg( localAxisB );
				}

				// Witness is the local plane of faceB
				fcn.type = b3_separationFaceB;
				fcn.witness1 = localAxisB;
				fcn.witness2 = localPointB;
			}
			else
			{
				B3_ASSERT( uniqueCountA == 2 && uniqueCountB == 2 );

				if ( indexA[0] == indexA[1] )
				{
					// Make first two indices are unique
					indexA[1] = indexA[2];
					B3_ASSERT( indexA[0] != indexA[1] );
				}

				b3Vec3 vA1 = proxyA->points[indexA[0]];
				b3Vec3 vA2 = proxyA->points[indexA[1]];
				b3Vec3 localEdgeA = b3Normalize( b3Sub( vA2, vA1 ) );
				b3Vec3 edgeA = b3RotateVector( qA, localEdgeA );

				if ( indexB[0] == indexB[1] )
				{
					// Make first two indices are unique
					indexB[1] = indexB[2];
					B3_ASSERT( indexB[0] != indexB[1] );
				}

				b3Vec3 vB1 = proxyB->points[indexB[0]];
				b3Vec3 vB2 = proxyB->points[indexB[1]];
				b3Vec3 localEdgeB = b3Normalize( b3Sub( vB2, vB1 ) );
				b3Vec3 edgeB = b3RotateVector( qB, localEdgeB );

				b3Vec3 axis = b3Cross( edgeA, edgeB );
				float lengthSquared = b3LengthSquared( axis );

				// Skip near parallel edges: |e1 x e1| = sin(alpha) * |e1| * |e2|
				const float kToleranceSquared = 0.005f * 0.005f;
				if ( lengthSquared < kToleranceSquared )
				{
					// The axis is not safe to normalize so we use a world axis instead!
					fcn.type = b3_separationVertices;
					fcn.witness1 = worldNormal;
				}
				else
				{
					b3Vec3 delta = b3Add( b3Sub( b3RotateVector( qB, vB1 ), b3RotateVector( qA, vA1 ) ), deltaP );
					if ( b3Dot( delta, axis ) < 0.0f )
					{
						// Make axis point from A to B
						axis = b3Neg( axis );
						localEdgeB = b3Neg( localEdgeB );
					}

					// Check for possible sign flip in edge/edge cross product
					b3Transform xfA2 = b3GetFinalSweepTransform( sweepA );
					b3Transform xfB2 = b3GetFinalSweepTransform( sweepB );
					bool fastEdges = b3CheckFastEdges( xfA2, localEdgeA, xfB2, localEdgeB, axis );
					if ( fastEdges )
					{
						// Not safe to use local edges, fall back to initial world space axis instead
						fcn.type = b3_separationVertices;
						fcn.witness1 = b3Normalize( axis );
					}
					else
					{
						// Edge cross product is safe. This converges faster than a fixed axis.
						fcn.type = b3_separationEdges;
						fcn.witness1 = localEdgeA;
						fcn.witness2 = localEdgeB;
					}
				}
			}
		}
		break;

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}

	return fcn;
}

static float b3FindMinSeparation( b3SeparationFunction* fcn, int* indexA, int* indexB, float t )
{
	b3Transform xfA = b3GetSweepTransform( &fcn->sweepA, t );
	b3Transform xfB = b3GetSweepTransform( &fcn->sweepB, t );

	switch ( fcn->type )
	{
		case b3_separationVertices:
		{
			b3Vec3 axis = fcn->witness1;

			b3Vec3 localAxisA = b3InvRotateVector( xfA.q, axis );
			b3Vec3 localAxisB = b3InvRotateVector( xfB.q, b3Neg( axis ) );

			*indexA = b3GetPointSupport( fcn->proxyA->points, fcn->proxyA->count, localAxisA );
			*indexB = b3GetPointSupport( fcn->proxyB->points, fcn->proxyB->count, localAxisB );

			b3Vec3 deltaP = b3Sub( xfB.p, xfA.p );
			b3Vec3 localPointA = fcn->proxyA->points[*indexA];
			b3Vec3 localPointB = fcn->proxyB->points[*indexB];
			b3Vec3 delta = b3Add( b3Sub( b3RotateVector( xfB.q, localPointB ), b3RotateVector( xfA.q, localPointA ) ), deltaP );
			return b3Dot( delta, axis );
		}

		case b3_separationEdges:
		{
			b3Vec3 edgeA = b3RotateVector( xfA.q, fcn->witness1 );
			b3Vec3 edgeB = b3RotateVector( xfB.q, fcn->witness2 );
			b3Vec3 axis = b3Cross( edgeA, edgeB );
			B3_ASSERT( axis.x != 0.0f || axis.y != 0.0f || axis.z != 0.0f );
			axis = b3Normalize( axis );

			b3Vec3 axisA = b3InvRotateVector( xfA.q, axis );
			*indexA = b3GetPointSupport( fcn->proxyA->points, fcn->proxyA->count, axisA );

			b3Vec3 axisB = b3InvRotateVector( xfB.q, axis );
			*indexB = b3GetPointSupport( fcn->proxyB->points, fcn->proxyB->count, b3Neg( axisB ) );

			b3Vec3 deltaP = b3Sub( xfB.p, xfA.p );
			b3Vec3 localPointA = fcn->proxyA->points[*indexA];
			b3Vec3 localPointB = fcn->proxyB->points[*indexB];
			b3Vec3 delta = b3Add( b3Sub( b3RotateVector( xfB.q, localPointB ), b3RotateVector( xfA.q, localPointA ) ), deltaP );

			return b3Dot( delta, axis );
		}

		case b3_separationFaceA:
		{
			b3Vec3 normal = b3RotateVector( xfA.q, fcn->witness1 );
			*indexA = -1;
			b3Vec3 pointA = b3TransformPoint( xfA, fcn->witness2 );

			b3Vec3 axisB = b3InvRotateVector( xfB.q, normal );
			*indexB = b3GetPointSupport( fcn->proxyB->points, fcn->proxyB->count, b3Neg( axisB ) );
			b3Vec3 pointB = b3TransformPoint( xfB, fcn->proxyB->points[*indexB] );

			return b3Dot( b3Sub( pointB, pointA ), normal );
		}

		case b3_separationFaceB:
		{
			b3Vec3 normal = b3RotateVector( xfB.q, fcn->witness1 );

			b3Vec3 axisA = b3InvRotateVector( xfA.q, normal );
			*indexA = b3GetPointSupport( fcn->proxyA->points, fcn->proxyA->count, b3Neg( axisA ) );
			b3Vec3 pointA = b3TransformPoint( xfA, fcn->proxyA->points[*indexA] );

			*indexB = -1;
			b3Vec3 pointB = b3TransformPoint( xfB, fcn->witness2 );

			return b3Dot( b3Sub( pointA, pointB ), normal );
		}

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}

	return 0.0f;
}

static float b3EvaluateSeparation( b3SeparationFunction* fcn, int index1, int index2, float beta )
{
	b3Transform transform1 = b3GetSweepTransform( &fcn->sweepA, beta );
	b3Transform transform2 = b3GetSweepTransform( &fcn->sweepB, beta );

	switch ( fcn->type )
	{
		case b3_separationVertices:
		{
			b3Vec3 axis = fcn->witness1;

			b3Vec3 point1 = b3TransformPoint( transform1, fcn->proxyA->points[index1] );
			b3Vec3 point2 = b3TransformPoint( transform2, fcn->proxyB->points[index2] );

			return b3Dot( b3Sub( point2, point1 ), axis );
		}

		case b3_separationEdges:
		{
			b3Vec3 edge1 = b3RotateVector( transform1.q, fcn->witness1 );
			b3Vec3 edge2 = b3RotateVector( transform2.q, fcn->witness2 );
			b3Vec3 axis = b3Cross( edge1, edge2 );
			axis = b3Normalize( axis );

			b3Vec3 point1 = b3TransformPoint( transform1, fcn->proxyA->points[index1] );
			b3Vec3 point2 = b3TransformPoint( transform2, fcn->proxyB->points[index2] );

			return b3Dot( b3Sub( point2, point1 ), axis );
		}

		case b3_separationFaceA:
		{
			b3Vec3 axis = b3RotateVector( transform1.q, fcn->witness1 );

			b3Vec3 point1 = b3TransformPoint( transform1, fcn->witness2 );
			b3Vec3 point2 = b3TransformPoint( transform2, fcn->proxyB->points[index2] );

			return b3Dot( b3Sub( point2, point1 ), axis );
		}

		case b3_separationFaceB:
		{
			b3Vec3 axis = b3RotateVector( transform2.q, fcn->witness1 );

			b3Vec3 point1 = b3TransformPoint( transform1, fcn->proxyA->points[index1] );
			b3Vec3 point2 = b3TransformPoint( transform2, fcn->witness2 );

			return b3Dot( b3Sub( point1, point2 ), axis );
		}

		default:
			B3_ASSERT( !"Should never get here!" );
			break;
	}

	return 0.0f;
}

static void b3ForceFixedAxis( b3SeparationFunction* fcn, float beta )
{
	B3_ASSERT( fcn->type == b3_separationEdges );

	b3Transform transform1 = b3GetSweepTransform( &fcn->sweepA, beta );
	b3Transform transform2 = b3GetSweepTransform( &fcn->sweepB, beta );

	b3Vec3 edge1 = b3RotateVector( transform1.q, fcn->witness1 );
	b3Vec3 edge2 = b3RotateVector( transform2.q, fcn->witness2 );
	b3Vec3 axis = b3Cross( edge1, edge2 );
	axis = b3Normalize( axis );

	fcn->type = b3_separationVertices;
	fcn->witness1 = axis;
	fcn->witness2 = b3Vec3_zero;
}

// Time of Impact using root finding
b3TOIOutput b3TimeOfImpact( const b3TOIInput* input )
{
	b3TOIOutput output = { 0 };

	// Set these to invalid values so they can be validated on exit
	output.state = b3_toiStateUnknown;
	output.fraction = -1.0f;

	b3Sweep sweepA = input->sweepA;
	b3Sweep sweepB = input->sweepB;

	// Shift to origin
	b3Vec3 origin = sweepA.c1;
	sweepA.c1 = b3Vec3_zero;
	sweepA.c2 = b3Sub( sweepA.c2, origin );
	sweepB.c1 = b3Sub( sweepB.c1, origin );
	sweepB.c2 = b3Sub( sweepB.c2, origin );

	b3ShapeProxy proxyA = input->proxyA;
	b3ShapeProxy proxyB = input->proxyB;

	int maxPushBackIterations = proxyA.count + proxyB.count;
	float tMax = input->maxFraction;

	// Setup target distance and tolerance
	float linearSlop = B3_LINEAR_SLOP;
	float totalRadius = proxyA.radius + proxyB.radius;
	float target = b3MaxFloat( linearSlop, totalRadius - linearSlop );
	float tolerance = 0.25f * linearSlop;
	B3_ASSERT( target > tolerance );

	float t1 = 0.0f;
	const int maxIterations = 25;
	int distanceIterations = 0;

	// Prepare input for distance query.
	b3SimplexCache cache = { 0 };
	b3DistanceInput distanceInput = { 0 };
	distanceInput.proxyA = proxyA;
	distanceInput.proxyB = proxyB;
	distanceInput.useRadii = false;

	// The outer loop progressively attempts to compute new separating axes.
	// This loop terminates when an axis is repeated (no progress is made).
	for ( ;; )
	{
		// Get the distance between shapes. We can also use the results to get a separating axis.
		b3Transform xfA = b3GetSweepTransform( &sweepA, t1 );
		b3Transform xfB = b3GetSweepTransform( &sweepB, t1 );
		distanceInput.transform = b3InvMulTransforms( xfA, xfB );
		b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, &cache, NULL, 0 );
		output.distance = distanceOutput.distance;

		// The distance query runs in frame A, project the witness data back to the shifted world
		b3Vec3 worldNormal = b3RotateVector( xfA.q, distanceOutput.normal );
		b3Vec3 worldPointA = b3TransformPoint( xfA, distanceOutput.pointA );
		b3Vec3 worldPointB = b3TransformPoint( xfA, distanceOutput.pointB );

		output.distanceIterations += 1;
		distanceIterations += 1;

		// If the shapes are overlapped, we give up on continuous collision.
		if ( distanceOutput.distance <= 0.0f )
		{
			output.state = b3_toiStateOverlapped;
			output.fraction = 0.0f;
			break;
		}

		if ( distanceOutput.distance <= target + tolerance )
		{
			// Success!
			output.state = b3_toiStateHit;

			// Averaged hit point
			b3Vec3 pA = b3MulAdd( worldPointA, proxyA.radius, worldNormal );
			b3Vec3 pB = b3MulAdd( worldPointB, -proxyB.radius, worldNormal );
			output.point = b3Lerp( pA, pB, 0.5f );
			output.point = b3Add( output.point, origin );
			output.normal = worldNormal;
			output.fraction = t1;
			break;
		}

		if ( distanceIterations == maxIterations )
		{
			// Progress too slow. This can happen when a capsule rotates around a
			// triangle vertex.
			output.state = b3_toiStateFailed;
			output.fraction = t1;

			// Averaged hit point
			b3Vec3 pA = b3MulAdd( worldPointA, input->proxyA.radius, worldNormal );
			b3Vec3 pB = b3MulAdd( worldPointB, -input->proxyB.radius, worldNormal );
			output.point = b3Lerp( pA, pB, 0.5f );
			output.point = b3Add( output.point, origin );
			output.normal = worldNormal;
			break;
		}

		// Initialize the separating axis.
		b3SeparationFunction function =
			b3MakeSeparationFunction( cache, &proxyA, &sweepA, &proxyB, &sweepB, worldNormal, t1 );

#if B3_ENABLE_VALIDATION && 0
		// todo this can give a negative value for diagonal edge contact on faces, typical GJK problem
		// to fix this I think the separation function would need to identify faces
		{
			int index1, index2;
			float minSeparation = b3FindMinSeparation( &function, &index1, &index2, t1 );
			// SAT should give a closer result than GJK
			B3_VALIDATE( minSeparation > target - tolerance && minSeparation - distanceOutput.distance < 0.1f * B3_LINEAR_SLOP );
		}
#endif

		// Compute the TOI on the separating axis. We do this by successively resolving the deepest point.
		bool done = false;
		float t2 = tMax;
		int pushBackIterations = 0;
		for ( ;; )
		{
			int indexA, indexB;
			float s2 = b3FindMinSeparation( &function, &indexA, &indexB, t2 );

			// Dump the function seen by the root finder
			// 			for ( int Step = 0; Step <= 100; ++Step )
			// 				{
			// 				float Alpha = 0.01f * Step;
			// 				float Separation = Function.Evaluate( Index1, Index2, Alpha );
			//
			// 				b3Report( "s(%4.2g) = %g\n", Alpha, Separation );
			// 				}

			// Is the final configuration separated?
			if ( s2 - target > tolerance )
			{
				// Success!
				output.state = b3_toiStateSeparated;
				output.fraction = input->maxFraction;
				done = true;
				break;
			}

			// Has the separation reached tolerance?
			if ( s2 >= target - tolerance )
			{
				// Advance the sweeps
				t1 = t2;
				break;
			}

			// Compute the initial separation of the witness points
			float s1 = b3EvaluateSeparation( &function, indexA, indexB, t1 );

			// Check for overlap. This might happen if the root finder runs out of iterations.
			if ( s1 < target - tolerance )
			{
				// Failed!
				B3_VALIDATE( false );
				output.state = b3_toiStateFailed;
				output.fraction = t1;
				done = true;
				break;
			}

			// Has the separation reached tolerance?
			if ( s1 <= target + tolerance )
			{
				// Success! t1 should hold the TOI (could be 0.0)
				output.state = b3_toiStateHit;
				output.fraction = t1;
				done = true;
				break;
			}

			// Compute 1D root of: f(x) - target = 0
			int rootIterationCount = 0;
			int maxRootIterations = 50;
			float a1 = t1;
			float a2 = t2;
			for ( ;; )
			{
				// Use a mix of false position and bisection.
				float t;
				if ( rootIterationCount & 1 )
				{
					// False position to improve convergence.
					t = a1 + ( target - s1 ) * ( a2 - a1 ) / ( s2 - s1 );
				}
				else
				{
					// Bisection to guarantee progress.
					t = 0.5f * ( a1 + a2 );
				}

				output.rootIterations += 1;
				rootIterationCount += 1;

				float s = b3EvaluateSeparation( &function, indexA, indexB, t );

				// Has the separation reached tolerance?
				if ( b3AbsFloat( s - target ) <= tolerance )
				{
					// t2 holds a tentative value for t1
					t2 = t;
					break;
				}

				// Ensure we continue to bracket the root.
				if ( s > target )
				{
					a1 = t;
					s1 = s;
				}
				else
				{
					a2 = t;
					s2 = s;
				}

				if ( rootIterationCount == maxRootIterations )
				{
					B3_VALIDATE( false );
					break;
				}
			}

			// Restart the inner loop if we have a failing edge case.
			if ( rootIterationCount == maxRootIterations - 1 && function.type == b3_separationEdges )
			{
				B3_VALIDATE( false );

				rootIterationCount = 0;
				t2 = input->maxFraction;
				b3ForceFixedAxis( &function, t1 );
				B3_ASSERT( function.type != b3_separationEdges );
			}

			output.pushBackIterations += 1;
			pushBackIterations += 1;

			if ( pushBackIterations == maxPushBackIterations )
			{
				break;
			}
		}

		if ( done )
		{
			// Averaged hit point
			b3Vec3 pA = b3MulAdd( worldPointA, input->proxyA.radius, worldNormal );
			b3Vec3 pB = b3MulAdd( worldPointB, -input->proxyB.radius, worldNormal );
			output.point = b3Lerp( pA, pB, 0.5f );
			output.point = b3Add( output.point, origin );
			output.normal = worldNormal;
			break;
		}
	}

	// It is expected that the state and fraction are set before reaching this
	B3_ASSERT( output.state != b3_toiStateUnknown );
	B3_ASSERT( output.fraction >= 0.0f );

	return output;
}
