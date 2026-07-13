// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "algorithm.h"
#include "manifold.h"
#include "shape.h"

#include "box3d/base.h"
#include "box3d/collision.h"
#include "box3d/constants.h"

#include <stdbool.h>
#include <stddef.h>

static inline bool b3IsMinkowskiFaceIsolated( b3Vec3 a, b3Vec3 b, b3Vec3 n )
{
	// An isolated edge (e.g. like in a capsule) defines a circle through the
	// origin on the Gauss map. So testing for overlap between this circle and
	// the arc AB simplifies to a simple plane test.
	float an = b3Dot( a, n );
	float bn = b3Dot( b, n );

	return an * bn <= 0.0f;
}

// bxa = cross(b, a) and dxc = cross(d, c)
// but in practice we use the edge vector between the faces for robustness
static inline bool b3IsMinkowskiFace( b3Vec3 a, b3Vec3 b, b3Vec3 bxa, b3Vec3 c, b3Vec3 d, b3Vec3 dxc )
{
	// Two edges build a face on the Minkowski sum if the associated arcs ab and cd intersect on the Gauss map.
	// The associated arcs are defined by the adjacent face normals of each edge.
	float cba = b3Dot( c, bxa );
	float dba = b3Dot( d, bxa );
	float adc = b3Dot( a, dxc );
	float bdc = b3Dot( b, dxc );

	return cba * dba < 0.0f && adc * bdc < 0.0f && cba * bdc > 0.0f;
}

static int b3ClipSegment( b3ClipVertex segment[2], b3Plane plane )
{
	int vertexCount = 0;
	b3ClipVertex vertex1 = segment[0];
	b3ClipVertex vertex2 = segment[1];

	float distance1 = b3PlaneSeparation( plane, vertex1.position );
	float distance2 = b3PlaneSeparation( plane, vertex2.position );

	// If the points are behind the plane
	if ( distance1 <= 0.0f )
	{
		segment[vertexCount++] = vertex1;
	}
	if ( distance2 <= 0.0f )
	{
		segment[vertexCount++] = vertex2;
	}

	// If the points are on different sides of the plane
	if ( distance1 * distance2 < 0.0f )
	{
		// Find intersection point of edge and plane
		float t = distance1 / ( distance1 - distance2 );
		segment[vertexCount].position = b3Add( b3MulSV( 1.0f - t, vertex1.position ), b3MulSV( t, vertex2.position ) );
		segment[vertexCount].pair = distance1 > 0.0f ? vertex1.pair : vertex2.pair;
		vertexCount++;
	}

	return vertexCount;
}

static int b3ClipSegmentToHullFace( b3ClipVertex segment[2], const b3HullData* hull, int refFace )
{
	const b3HullFace* faces = b3GetHullFaces( hull );
	const b3Plane* planes = b3GetHullPlanes( hull );
	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	const b3Vec3* points = b3GetHullPoints( hull );

	b3Plane refPlane = planes[refFace];

	const b3HullFace* face = faces + refFace;

	int edgeIndex = face->edge;

	do
	{
		const b3HullHalfEdge* edge = edges + edgeIndex;
		int nextEdgeIndex = edge->next;
		const b3HullHalfEdge* next = edges + nextEdgeIndex;

		b3Vec3 vertex1 = points[edge->origin];
		b3Vec3 vertex2 = points[next->origin];
		b3Vec3 tangent = b3Normalize( b3Sub( vertex2, vertex1 ) );
		b3Vec3 binormal = b3Cross( tangent, refPlane.normal );

		int pointCount = b3ClipSegment( segment, b3MakePlaneFromNormalAndPoint( binormal, vertex1 ) );
		if ( pointCount < 2 )
		{
			return 0;
		}

		edgeIndex = nextEdgeIndex;
	}
	while ( edgeIndex != face->edge );

	return 2;
}

static b3FaceQuery b3QueryFaceDirectionHullAndCapsule( const b3HullData* hull, const b3Capsule* capsule,
													   b3Transform capsuleTransform )
{
	int maxFaceIndex = -1;
	int maxVertexIndex = -1;
	float maxFaceSeparation = -FLT_MAX;
	const b3Plane* planes = b3GetHullPlanes( hull );

	b3Vec3 capsulePoints[2] = {
		b3TransformPoint( capsuleTransform, capsule->center1 ),
		b3TransformPoint( capsuleTransform, capsule->center2 ),
	};

	for ( int faceIndex = 0; faceIndex < hull->faceCount; ++faceIndex )
	{
		b3Plane plane = planes[faceIndex];

		int vertexIndex = b3GetPointSupport( capsulePoints, 2, b3Neg( plane.normal ) );
		b3Vec3 support = capsulePoints[vertexIndex];
		float separation = b3PlaneSeparation( plane, support );
		if ( separation > maxFaceSeparation )
		{
			maxVertexIndex = vertexIndex;
			maxFaceIndex = faceIndex;
			maxFaceSeparation = separation;
		}
	}

	return (b3FaceQuery){
		.separation = maxFaceSeparation,
		.faceIndex = (uint8_t)maxFaceIndex,
		.vertexIndex = (uint8_t)maxVertexIndex,
	};
}

static b3FaceQuery b3QueryFaceDirections( const b3HullData* hullA, const b3HullData* hullB, b3Transform relativeTransform )
{
	// We perform all computations in local space of the second hull
	b3Transform transform = b3InvertTransform( relativeTransform );
	const b3Plane* planesA = b3GetHullPlanes( hullA );
	const b3Vec3* pointsB = b3GetHullPoints( hullB );

	int maxFaceIndex = -1;
	int maxVertexIndex = -1;
	float maxFaceSeparation = -FLT_MAX;

	for ( int faceIndex = 0; faceIndex < hullA->faceCount; ++faceIndex )
	{
		b3Plane plane = b3TransformPlane( transform, planesA[faceIndex] );

		int vertexIndex = b3FindHullSupportVertex( hullB, b3Neg( plane.normal ) );
		b3Vec3 support = pointsB[vertexIndex];
		float separation = b3PlaneSeparation( plane, support );
		if ( separation > maxFaceSeparation )
		{
			maxFaceIndex = faceIndex;
			maxVertexIndex = vertexIndex;
			maxFaceSeparation = separation;
		}
	}

	return (b3FaceQuery){
		.separation = maxFaceSeparation,
		.faceIndex = (uint8_t)maxFaceIndex,
		.vertexIndex = (uint8_t)maxVertexIndex,
	};
}

static b3EdgeQuery b3QueryEdgeDirectionHullAndCapsule( const b3HullData* hull, const b3Capsule* capsule,
													   b3Transform capsuleTransform )
{
	// Find axis of minimum penetration
	float maxSeparation = -FLT_MAX;
	int maxIndex1 = -1;
	int maxIndex2 = -1;

	// We perform all computations in local space of the hull
	b3Vec3 p1 = b3TransformPoint( capsuleTransform, capsule->center1 );
	b3Vec3 q1 = b3TransformPoint( capsuleTransform, capsule->center2 );
	b3Vec3 e1 = b3Sub( q1, p1 );

	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	const b3Vec3* points = b3GetHullPoints( hull );
	const b3Plane* planes = b3GetHullPlanes( hull );

	for ( int index = 0; index < hull->edgeCount; index += 2 )
	{
		const b3HullHalfEdge* edge = edges + index;
		const b3HullHalfEdge* twin = edges + index + 1;
		B3_ASSERT( edge->twin == index + 1 && twin->twin == index );

		b3Vec3 p2 = points[edge->origin];
		b3Vec3 q2 = points[twin->origin];
		b3Vec3 e2 = b3Sub( q2, p2 );

		b3Vec3 u2 = planes[edge->face].normal;
		b3Vec3 v2 = planes[twin->face].normal;

		if ( b3IsMinkowskiFaceIsolated( u2, v2, e1 ) )
		{
			// We can pass any point on the edge and choose
			// the edge centers for better numerical precision.
			b3Vec3 c1 = b3MulSV( 0.5f, b3Add( q1, p1 ) );
			b3Vec3 c2 = hull->center;
			float separation = b3EdgeEdgeSeparation( q1, e1, c1, q2, e2, c2 );
			if ( separation > maxSeparation )
			{
				// Note: We don't exit early if we find a separating axis here since we want to
				// find the best one for caching and account for the convex radius later.
				maxSeparation = separation;
				maxIndex1 = 0;
				maxIndex2 = index;
			}
		}
	}

	// Save result
	return (b3EdgeQuery){
		.separation = maxSeparation,
		.indexA = (uint8_t)maxIndex1,
		.indexB = (uint8_t)maxIndex2,
	};
}

static b3EdgeQuery b3QueryEdgeDirections( const b3HullData* hullA, const b3HullData* hullB, b3Transform transformBtoA )
{
	// Find axis of minimum penetration
	float maxSeparation = -FLT_MAX;
	int maxIndexA = B3_NULL_INDEX;
	int maxIndexB = B3_NULL_INDEX;

	const b3HullHalfEdge* edgesA = b3GetHullEdges( hullA );
	const b3Vec3* pointsA = b3GetHullPoints( hullA );
	const b3Plane* planesA = b3GetHullPlanes( hullA );
	const b3HullHalfEdge* edgesB = b3GetHullEdges( hullB );
	const b3Vec3* pointsB = b3GetHullPoints( hullB );
	const b3Plane* planesB = b3GetHullPlanes( hullB );

	// Work in frame A
	b3Matrix3 matrix = b3MakeMatrixFromQuat( transformBtoA.q );

	// Arranged to minimize transform operations
	for ( int indexB = 0; indexB < hullB->edgeCount; indexB += 2 )
	{
		const b3HullHalfEdge* edgeB = edgesB + indexB;
		const b3HullHalfEdge* twinB = edgesB + indexB + 1;
		B3_ASSERT( edgeB->twin == indexB + 1 && twinB->twin == indexB );

		b3Vec3 qB = pointsB[twinB->origin];
		b3Vec3 eB = b3MulMV( matrix, b3Sub( qB, pointsB[edgeB->origin] ) );
		qB = b3Add( b3MulMV( matrix, qB ), transformBtoA.p );

		b3Vec3 uB = b3MulMV( matrix, planesB[edgeB->face].normal );
		b3Vec3 vB = b3MulMV( matrix, planesB[twinB->face].normal );

		for ( int indexA = 0; indexA < hullA->edgeCount; indexA += 2 )
		{
			const b3HullHalfEdge* edgeA = edgesA + indexA;
			const b3HullHalfEdge* twinA = edgesA + indexA + 1;
			B3_ASSERT( edgeA->twin == indexA + 1 && twinA->twin == indexA );

			b3Vec3 qA = pointsA[twinA->origin];
			b3Vec3 eA = b3Sub( qA, pointsA[edgeA->origin] );
			b3Vec3 uA = planesA[edgeA->face].normal;
			b3Vec3 vA = planesA[twinA->face].normal;

			bool isMinkowski;
			{
				// Two edges build a face on the Minkowski sum if the associated arcs AB and CD intersect on the Gauss map.
				// The associated arcs are defined by the adjacent face normals of each edge.
				float cba = b3Dot( uB, eA );
				float dba = b3Dot( vB, eA );
				float adc = -b3Dot( uA, eB );
				float bdc = -b3Dot( vA, eB );

				isMinkowski = cba * dba < 0.0f && adc * bdc < 0.0f && cba * bdc > 0.0f;
			}

			if ( isMinkowski )
			{
				b3Vec3 centerA = hullA->center;
				b3Vec3 centerB = b3TransformPoint( transformBtoA, hullB->center );
				float separation = b3EdgeEdgeSeparation( qA, eA, centerA, qB, eB, centerB );

				if ( separation > maxSeparation )
				{
					// Continues to find the maximum separating axis
					maxSeparation = separation;
					maxIndexA = indexA;
					maxIndexB = indexB;
				}
			}
		}
	}

	return (b3EdgeQuery){
		.separation = maxSeparation,
		.indexA = maxIndexA,
		.indexB = maxIndexB,
	};
}

// Reduce the manifold points to a maximum of 4 points.
// Note: this modifies the input point array to improve performance
static void b3ReduceManifoldPoints( b3LocalManifold* manifold, int capacity, b3LocalManifoldPoint* points, int count )
{
	if ( capacity < 4 )
	{
		return;
	}

	if ( count <= 4 )
	{
		for ( int i = 0; i < count; ++i )
		{
			manifold->points[i] = points[i];
		}

		manifold->pointCount = count;
		return;
	}

	b3Vec3 normal = manifold->normal;
	// float linearSlop = B3_LINEAR_SLOP;
	float speculativeDistance = B3_SPECULATIVE_DISTANCE;
	float tolSqr = speculativeDistance * speculativeDistance;

	// This bias is very important for contact point consistency across time steps.
	// It creates a pecking order to avoid flickering between candidates with similar scores.
	float bias = 0.95f;

	// Step 1: find extreme point that is touching
	int bestIndex = B3_NULL_INDEX;
	float bestScore = -FLT_MAX;

	// Arbitrary tangent direction
	// b3Vec3 perp1 = b3Perp( normal );
	// b3Vec3 perp2 = b3Cross( perp1, normal );
	// b3Vec3 searchDirection = -0.4535961214255773f * perp1 + 0.8912073600614354f * perp2;
	b3Vec3 searchDirection = b3ArbitraryPerp( normal );
	for ( int index = 0; index < count; ++index )
	{
		b3LocalManifoldPoint* pt = points + index;

		if ( pt->separation > speculativeDistance )
		{
			continue;
		}

		// The deeper the better
		float score = -pt->separation + b3Dot( searchDirection, pt->point );
		if ( bias * score > bestScore )
		{
			bestIndex = index;
			bestScore = score;
		}
	}

	B3_VALIDATE( 0 <= bestIndex && bestIndex < count );
	if ( bestIndex == B3_NULL_INDEX )
	{
		manifold->pointCount = 0;
		return;
	}

	manifold->points[0] = points[bestIndex];
	manifold->pointCount = 1;

	// Remove best point from array
	points[bestIndex] = points[count - 1];
	count -= 1;

	b3Vec3 a = manifold->points[0].point;

	// Step 2: Find farthest point in 2D
	bestScore = 0.0f;
	bestIndex = B3_NULL_INDEX;
	float maxDistanceSquared = 0.0f;

	for ( int index = 0; index < count; ++index )
	{
		b3Vec3 p = points[index].point;
		b3Vec3 d = b3Sub( p, a );
		b3Vec3 v = b3MulSub( d, b3Dot( d, normal ), normal );
		float distanceSquared = b3LengthSquared( v );
		maxDistanceSquared = b3MaxFloat( maxDistanceSquared, distanceSquared );
		float separation = b3MaxFloat( 0.0f, -points[index].separation );
		float score = distanceSquared + 4.0f * separation * separation;
		if ( bias * score > bestScore )
		{
			bestScore = score;
			bestIndex = index;
		}
	}

	if ( bestScore < tolSqr )
	{
		return;
	}

	B3_ASSERT( 0 <= bestIndex && bestIndex < count );
	manifold->points[1] = points[bestIndex];
	manifold->pointCount = 2;

	// Remove best point from array
	points[bestIndex] = points[count - 1];
	count -= 1;

	b3Vec3 b = manifold->points[1].point;

	// Step 3: Find the point with the maximum triangular area
	bestScore = tolSqr;
	bestIndex = B3_NULL_INDEX;
	float bestSignedArea = 0.0f;
	b3Vec3 ba = b3Sub( b, a );
	for ( int index = 0; index < count; ++index )
	{
		b3Vec3 p = points[index].point;
		float signedArea = b3Dot( normal, b3Cross( ba, b3Sub( p, a ) ) );
		float score = b3AbsFloat( signedArea );
		if ( bias * score >= bestScore )
		{
			bestScore = score;
			bestIndex = index;
			bestSignedArea = signedArea;
		}
	}

	if ( bestIndex == B3_NULL_INDEX )
	{
		return;
	}

	B3_ASSERT( bestIndex != B3_NULL_INDEX );

	manifold->points[2] = points[bestIndex];
	manifold->pointCount = 3;
	points[bestIndex] = points[count - 1];
	count -= 1;

	b3Vec3 c = manifold->points[2].point;

	// Step 4: get the point that adds the most area outside the current triangle
	bestScore = tolSqr;
	bestIndex = B3_NULL_INDEX;
	float sign = bestSignedArea < 0.0f ? -1.0f : 1.0f;
	for ( int index = 0; index < count; ++index )
	{
		b3Vec3 p = points[index].point;
		float u1 = sign * b3Dot( normal, b3Cross( b3Sub( p, a ), ba ) );
		float u2 = sign * b3Dot( normal, b3Cross( b3Sub( p, b ), b3Sub( c, b ) ) );
		float u3 = sign * b3Dot( normal, b3Cross( b3Sub( p, c ), b3Sub( a, c ) ) );
		float score = b3MaxFloat( u1, b3MaxFloat( u2, u3 ) );

		if ( bias * score > bestScore )
		{
			bestScore = score;
			bestIndex = index;
		}
	}

	if ( bestIndex != B3_NULL_INDEX )
	{
		manifold->points[manifold->pointCount] = points[bestIndex];
		manifold->pointCount += 1;
	}
}

void b3CollideSpheres( b3LocalManifold* manifold, int capacity, const b3Sphere* sphereA, const b3Sphere* sphereB,
					   b3Transform transformBtoA )
{
	if ( capacity == 0 )
	{
		return;
	}

	// Work in shapeB coordinates
	b3Vec3 center1 = sphereA->center;
	b3Vec3 center2 = b3TransformPoint( transformBtoA, sphereB->center );

	float totalRadius = sphereA->radius + sphereB->radius;
	b3Vec3 offset = b3Sub( center2, center1 );
	float distanceSq = b3LengthSquared( offset );

	if ( distanceSq > totalRadius * totalRadius )
	{
		// We found a separating axis
		return;
	}

	b3Vec3 normal = { 0.0f, 1.0f, 0.0f };
	float distance = sqrtf( distanceSq );
	if ( distance * distance > 1000.0f * FLT_MIN )
	{
		normal = b3MulSV( 1.0f / distance, offset );
	}

	// Contact at the midpoint
	// 0.5 * ( ((c1 + rA*n) + c2) - rB*n )
	b3Vec3 point =
		b3MulSV( 0.5f, b3MulSub( b3Add( b3MulAdd( center1, sphereA->radius, normal ), center2 ), sphereB->radius, normal ) );

	// Manifold in frame B
	manifold->normal = normal;
	manifold->pointCount = 1;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = distance - totalRadius;
	pt->pair = b3FeaturePair_single;
}

void b3CollideCapsuleAndSphere( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA, const b3Sphere* sphereB,
								b3Transform transformBtoA )
{
	manifold->pointCount = 0;

	if ( capacity < 1 )
	{
		return;
	}

	// Work in shape B coordinates
	b3Vec3 center = b3TransformPoint( transformBtoA, sphereB->center );
	b3Vec3 center1 = capsuleA->center1;
	b3Vec3 center2 = capsuleA->center2;

	float totalRadius = sphereB->radius + capsuleA->radius;

	b3Vec3 closestPoint = b3PointToSegmentDistance( center1, center2, center );
	b3Vec3 offset = b3Sub( center, closestPoint );
	float distanceSq = b3LengthSquared( offset );

	if ( distanceSq > totalRadius * totalRadius )
	{
		// We found a separating axis
		return;
	}

	b3Vec3 normal = { 0.0f, 1.0f, 0.0f };
	float distance = sqrtf( distanceSq );
	if ( distance * distance > 1000.0f * FLT_MIN )
	{
		normal = b3MulSV( 1.0f / distance, offset );
	}

	// Contact at the midpoint
	// 0.5 * (((center - sB*n) + closestPoint) + cA*n)
	b3Vec3 point =
		b3MulSV( 0.5f, b3MulAdd( b3Add( b3MulSub( center, sphereB->radius, normal ), closestPoint ), capsuleA->radius, normal ) );

	// Manifold in frame B
	manifold->normal = normal;
	manifold->pointCount = 1;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = distance - totalRadius;
	pt->pair = b3FeaturePair_single;
}

void b3CollideHullAndSphere( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3Sphere* sphereB,
							 b3Transform transformBtoA, b3SimplexCache* cache )
{
	manifold->pointCount = 0;

	if ( capacity == 0 )
	{
		return;
	}

	b3Vec3 center = b3TransformPoint( transformBtoA, sphereB->center );

	const float speculativeDistance = B3_SPECULATIVE_DISTANCE;

	// Work in shapeA coordinates

	b3DistanceInput distanceInput;
	distanceInput.proxyA = (b3ShapeProxy){ b3GetHullPoints( hullA ), hullA->vertexCount, 0.0f };
	distanceInput.proxyB = (b3ShapeProxy){ &center, 1, 0.0f };
	distanceInput.transform = b3Transform_identity;
	distanceInput.useRadii = false;

	float radiusA = 0.0f;
	float radiusB = sphereB->radius;
	float radius = radiusA + radiusB;

	b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, cache, NULL, 0 );

	if ( distanceOutput.distance > radius + speculativeDistance )
	{
		// We found a separating axis
		*cache = (b3SimplexCache){ 0 };
		return;
	}

	if ( distanceOutput.distance > 100.0f * FLT_EPSILON )
	{
		// Shallow penetration
		b3Vec3 normal = b3Normalize( b3Sub( distanceOutput.pointB, distanceOutput.pointA ) );

		// cA is the projection of the sphere center onto to the hull (pointA if radiusA == 0).
		b3Vec3 cA = b3MulAdd( center, radiusA - b3Dot( b3Sub( center, distanceOutput.pointA ), normal ), normal );

		// cB is the deepest point on the sphere with respect to the reference f
		b3Vec3 cB = b3MulSub( center, radiusB, normal );

		b3Vec3 point = b3Lerp( cA, cB, 0.5f );

		// Manifold in frame A
		manifold->normal = normal;
		manifold->pointCount = 1;

		b3LocalManifoldPoint* pt = manifold->points + 0;
		pt->point = point;
		pt->separation = distanceOutput.distance - radius;
		pt->pair = b3FeaturePair_single;
	}
	else
	{
		// Deep penetration
		int bestIndex = -1;
		float bestDistance = -FLT_MAX;
		const b3Plane* planes = b3GetHullPlanes( hullA );

		for ( int index = 0; index < hullA->faceCount; ++index )
		{
			b3Plane plane = planes[index];

			float distance = b3PlaneSeparation( plane, center );
			if ( distance > bestDistance )
			{
				bestIndex = index;
				bestDistance = distance;
			}
		}
		B3_ASSERT( bestIndex >= 0 );

		b3Vec3 normal = planes[bestIndex].normal;

		// cA is the projection of the sphere center onto to the hull
		b3Vec3 cA = b3MulAdd( center, radiusA - b3Dot( b3Sub( center, distanceOutput.pointA ), normal ), normal );

		// cB is the deepest point on the sphere with respect to the reference f
		b3Vec3 cB = b3MulSub( center, radiusB, normal );

		b3Vec3 point = b3Lerp( cA, cB, 0.5f );

		// Manifold in frame A
		manifold->normal = normal;
		manifold->pointCount = 1;

		b3LocalManifoldPoint* pt = manifold->points + 0;
		pt->point = point;
		pt->separation = bestDistance - radius;
		pt->pair = b3FeaturePair_single;
	}
}

void b3CollideCapsules( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA, const b3Capsule* capsuleB,
						b3Transform transformBtoA )
{
	manifold->pointCount = 0;

	if ( capacity < 2 )
	{
		return;
	}

	// Work in shapeA coordinates
	b3Vec3 centerA1 = capsuleA->center1;
	b3Vec3 centerA2 = capsuleA->center2;
	b3Vec3 centerB1 = b3TransformPoint( transformBtoA, capsuleB->center1 );
	b3Vec3 centerB2 = b3TransformPoint( transformBtoA, capsuleB->center2 );

	float radius = capsuleA->radius + capsuleB->radius;
	float maxDistance = radius + B3_SPECULATIVE_DISTANCE;

	b3SegmentDistanceResult result = b3SegmentDistance( centerA1, centerA2, centerB1, centerB2 );
	b3Vec3 offset = b3Sub( result.point2, result.point1 );
	float distanceSquared = b3LengthSquared( offset );
	float linearSlop = B3_LINEAR_SLOP;
	float minDistance = 0.01f * linearSlop;

	if ( distanceSquared > maxDistance * maxDistance || distanceSquared < minDistance * minDistance )
	{
		// We found a separating axis
		return;
	}

	float lengthA;
	b3Vec3 segmentA = b3Sub( centerA2, centerA1 );
	b3Vec3 edgeA = b3GetLengthAndNormalize( &lengthA, segmentA );
	if ( lengthA < B3_MIN_CAPSULE_LENGTH )
	{
		return;
	}

	float lengthB;
	b3Vec3 segmentB = b3Sub( centerB2, centerB1 );
	b3Vec3 edgeB = b3GetLengthAndNormalize( &lengthB, segmentB );
	if ( lengthB < B3_MIN_CAPSULE_LENGTH )
	{
		return;
	}

	// Parallel edges: |eA x eB| = sin(alpha)
	const float alphaTol = 0.05f;
	const float alphaTolSqr = alphaTol * alphaTol;
	b3Vec3 axis = b3Cross( edgeA, edgeB );

	// Try to create two contact points if the capsules are nearly parallel
	if ( b3LengthSquared( axis ) < alphaTolSqr )
	{
		// Clip segment B against side planes of segment A

		// Sides planes of A
		b3Plane planesA[2];
		planesA[0].normal = b3Neg( edgeA );
		planesA[0].offset = -b3Dot( edgeA, capsuleA->center1 );
		planesA[1].normal = edgeA;
		planesA[1].offset = b3Dot( edgeA, capsuleA->center2 );

		// Clip points for B
		b3ClipVertex verticesB[2];
		verticesB[0].position = centerB1;
		verticesB[0].separation = 0.0f;
		verticesB[0].pair = b3MakeFeaturePair( b3_featureShapeA, 0, b3_featureShapeA, 0 );
		verticesB[1].position = centerB2;
		verticesB[1].separation = 0.0f;
		verticesB[1].pair = b3MakeFeaturePair( b3_featureShapeA, 1, b3_featureShapeA, 1 );

		int pointCount = b3ClipSegment( verticesB, planesA[0] );
		if ( pointCount == 2 )
		{
			pointCount = b3ClipSegment( verticesB, planesA[1] );
		}

		if ( pointCount == 2 )
		{
			// Closest points on A to the clipped points on B.
			b3Vec3 closestPoint1 = b3PointToSegmentDistance( centerA1, centerA2, verticesB[0].position );
			b3Vec3 closestPoint2 = b3PointToSegmentDistance( centerA1, centerA2, verticesB[1].position );

			float distance1 = b3Distance( closestPoint1, verticesB[0].position );
			float distance2 = b3Distance( closestPoint2, verticesB[1].position );
			if ( distance1 <= radius && distance2 <= radius )
			{
				if ( distance1 < minDistance || distance2 < minDistance )
				{
					// Avoid divide by zero
					return;
				}

				b3Vec3 normal1 = b3MulSV( 1.0f / distance1, b3Sub( verticesB[0].position, closestPoint1 ) );
				b3Vec3 normal2 = b3MulSV( 1.0f / distance2, b3Sub( verticesB[1].position, closestPoint2 ) );
				b3Vec3 normal = b3Normalize( b3Add( normal1, normal2 ) );
				float radiusA = capsuleA->radius;
				float radiusB = capsuleB->radius;

				// Contact is at the midpoint: 0.5 * (((vB.pos + rA*nK) + cP) - rB*n)
				b3Vec3 point1 =
					b3MulSV( 0.5f, b3MulSub( b3Add( b3MulAdd( verticesB[0].position, radiusA, normal1 ), closestPoint1 ), radiusB,
											 normal ) );
				b3Vec3 point2 =
					b3MulSV( 0.5f, b3MulSub( b3Add( b3MulAdd( verticesB[1].position, radiusA, normal2 ), closestPoint2 ), radiusB,
											 normal ) );

				// Manifold in frame A
				manifold->normal = normal;
				manifold->pointCount = 2;

				b3LocalManifoldPoint* pt1 = manifold->points + 0;
				pt1->point = point1;
				pt1->separation = distance1 - radius;
				pt1->pair = verticesB[0].pair;

				b3LocalManifoldPoint* pt2 = manifold->points + 1;
				pt2->point = point2;
				pt2->separation = distance2 - radius;
				pt2->pair = verticesB[1].pair;

				return;
			}
		}
	}

	float distance;
	b3Vec3 normal = b3GetLengthAndNormalize( &distance, offset );
	// Contact at the midpoint 0.5 * (((p1 + rA*n) + p2) - rB*n)
	b3Vec3 point = b3MulSV(
		0.5f, b3MulSub( b3Add( b3MulAdd( result.point1, capsuleA->radius, normal ), result.point2 ), capsuleB->radius, normal ) );

	// Manifold in frame A
	manifold->normal = normal;
	manifold->pointCount = 1;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = distance - radius;
	pt->pair = b3FeaturePair_single;
}

static bool b3BuildHullFaceAndCapsuleContact( b3LocalManifold* manifold, const b3HullData* hullA, const b3Capsule* capsuleB,
											  b3Transform transformBtoA, b3FaceQuery query )
{
	// Work in shapeA coordinates
	const b3Plane* planes = b3GetHullPlanes( hullA );

	// Clip the capsule edge against the side planes of the reference face
	int refFace = query.faceIndex;
	b3Plane refPlane = planes[refFace];

	b3ClipVertex segmentB[2];
	segmentB[0].position = b3TransformPoint( transformBtoA, capsuleB->center1 );
	segmentB[0].separation = 0.0f;
	segmentB[0].pair = b3MakeFeaturePair( b3_featureShapeA, 0, b3_featureShapeA, 0 );
	segmentB[1].position = b3TransformPoint( transformBtoA, capsuleB->center2 );
	segmentB[1].separation = 0.0f;
	segmentB[1].pair = b3MakeFeaturePair( b3_featureShapeA, 1, b3_featureShapeA, 1 );

	int pointCount = b3ClipSegmentToHullFace( segmentB, hullA, refFace );
	if ( pointCount < 2 )
	{
		return false;
	}

	float distance1 = b3PlaneSeparation( refPlane, segmentB[0].position );
	float distance2 = b3PlaneSeparation( refPlane, segmentB[1].position );
	const float speculativeDistance = B3_SPECULATIVE_DISTANCE;

	if ( distance1 <= speculativeDistance || distance2 <= speculativeDistance )
	{
		b3Vec3 normal = refPlane.normal;
		b3Vec3 point1 = b3MulSub( segmentB[0].position, 0.5f * ( distance1 + capsuleB->radius ), normal );
		b3Vec3 point2 = b3MulSub( segmentB[1].position, 0.5f * ( distance2 + capsuleB->radius ), normal );

		// Manifold in frame A
		manifold->normal = normal;
		manifold->pointCount = 2;

		b3LocalManifoldPoint* pt1 = manifold->points + 0;
		pt1->point = point1;
		pt1->separation = distance1 - capsuleB->radius;
		pt1->pair = segmentB[0].pair;

		b3LocalManifoldPoint* pt2 = manifold->points + 1;
		pt2->point = point2;
		pt2->separation = distance2 - capsuleB->radius;
		pt2->pair = segmentB[1].pair;

		return true;
	}

	return false;
}

static inline float b3DeepestPointSeparation( const b3LocalManifold* manifold )
{
	// Deepest point
	float minSeparation = FLT_MAX;
	int pointCount = manifold->pointCount;
	for ( int i = 0; i < pointCount; ++i )
	{
		minSeparation = b3MinFloat( minSeparation, manifold->points[i].separation );
	}

	return minSeparation;
}

static bool b3BuildHullAndCapsuleEdgeContact( b3LocalManifold* manifold, int capacity, const b3HullData* hullA,
											  const b3Capsule* capsuleB, b3Transform transformBtoA, b3EdgeQuery query )
{
	if ( capacity < 1 )
	{
		return false;
	}

	// Work in shapeA coordinates

	b3Vec3 pc = b3TransformPoint( transformBtoA, capsuleB->center1 );
	b3Vec3 qc = b3TransformPoint( transformBtoA, capsuleB->center2 );
	b3Vec3 ec = b3Sub( qc, pc );

	const b3HullHalfEdge* edges = b3GetHullEdges( hullA );
	const b3Vec3* points = b3GetHullPoints( hullA );

	const b3HullHalfEdge* edge2 = edges + query.indexB;
	const b3HullHalfEdge* twin2 = edges + edge2->twin;
	b3Vec3 ch = hullA->center;
	b3Vec3 ph = points[edge2->origin];
	b3Vec3 qh = points[twin2->origin];
	b3Vec3 eh = b3Sub( qh, ph );

	b3Vec3 normal = b3Cross( ec, eh );
	normal = b3Normalize( normal );

	// Normal should point outward from hull
	if ( b3Dot( normal, b3Sub( ph, ch ) ) < 0.0f )
	{
		normal = b3Neg( normal );
	}

	b3SegmentDistanceResult result = b3LineDistance( ph, eh, pc, ec );

	if ( b3IsWithinSegments( &result ) == false )
	{
		// closest point beyond end points
		return false;
	}

	b3Vec3 point = b3MulSV( 0.5f, b3Add( b3MulSub( result.point1, capsuleB->radius, normal ), result.point2 ) );

	float separation = b3Dot( normal, b3Sub( result.point2, result.point1 ) );
	B3_VALIDATE( b3AbsFloat( separation - query.separation ) < B3_LINEAR_SLOP );

	// Manifold in frame A
	manifold->normal = normal;
	manifold->pointCount = 1;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = separation - capsuleB->radius;
	pt->pair = b3MakeFeaturePair( b3_featureShapeA, query.indexA, b3_featureShapeB, query.indexB );
	return true;
}

void b3CollideHullAndCapsule( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3Capsule* capsuleB,
							  b3Transform transformBtoA, b3SimplexCache* cache )
{
	manifold->pointCount = 0;

	if ( capacity < 2 )
	{
		return;
	}

	// Work in shapeA coordinates
	b3DistanceInput distanceInput;
	distanceInput.proxyA = (b3ShapeProxy){ b3GetHullPoints( hullA ), hullA->vertexCount, 0.0f };
	distanceInput.proxyB = (b3ShapeProxy){ &capsuleB->center1, 2, 0.0f };
	distanceInput.transform = transformBtoA;
	distanceInput.useRadii = false;

	b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, cache, NULL, 0 );
	const float speculativeDistance = B3_SPECULATIVE_DISTANCE;

	if ( distanceOutput.distance > capsuleB->radius + speculativeDistance )
	{
		// We found a separating axis
		*cache = (b3SimplexCache){ 0 };
		return;
	}

	if ( distanceOutput.distance > 100.0f * FLT_EPSILON )
	{
		const b3Plane* planes = b3GetHullPlanes( hullA );

		// Shallow penetration
		b3Vec3 delta = distanceOutput.normal;
		int refFace = b3FindHullSupportFace( hullA, delta );
		b3Plane refPlane = planes[refFace];

		// Try to create two contact points if closest
		// points difference is nearly parallel to face normal
		const float kTolerance = 0.998f;
		if ( b3AbsFloat( b3Dot( refPlane.normal, delta ) ) > kTolerance )
		{
			// Clip capsule segment against side planes of reference face
			b3ClipVertex verticesB[2];
			verticesB[0].position = b3TransformPoint( transformBtoA, capsuleB->center1 );
			verticesB[0].separation = 0.0f;
			verticesB[0].pair = b3MakeFeaturePair( b3_featureShapeA, 0, b3_featureShapeA, 0 );
			verticesB[1].position = b3TransformPoint( transformBtoA, capsuleB->center2 );
			verticesB[1].separation = 0.0f;
			verticesB[1].pair = b3MakeFeaturePair( b3_featureShapeA, 1, b3_featureShapeA, 1 );

			int pointCount = b3ClipSegmentToHullFace( verticesB, hullA, refFace );

			if ( pointCount == 2 )
			{
				float distance1 = b3PlaneSeparation( refPlane, verticesB[0].position );
				float distance2 = b3PlaneSeparation( refPlane, verticesB[1].position );
				if ( distance1 <= capsuleB->radius + speculativeDistance || distance2 <= capsuleB->radius + speculativeDistance )
				{
					b3Vec3 normal = refPlane.normal;
					b3Vec3 point1 = b3MulSub( verticesB[0].position, 0.5f * ( capsuleB->radius + distance1 ), normal );
					b3Vec3 point2 = b3MulSub( verticesB[1].position, 0.5f * ( capsuleB->radius + distance2 ), normal );

					// Manifold in frame A
					manifold->normal = normal;
					manifold->pointCount = 2;

					b3LocalManifoldPoint* pt1 = manifold->points + 0;
					pt1->point = point1;
					pt1->separation = distance1 - capsuleB->radius;
					pt1->pair = verticesB[0].pair;

					b3LocalManifoldPoint* pt2 = manifold->points + 1;
					pt2->point = point2;
					pt2->separation = distance2 - capsuleB->radius;
					pt2->pair = verticesB[1].pair;

					return;
				}
			}
		}

		// Create contact from closest points
		b3Vec3 point =
			b3MulSV( 0.5f, b3Add( b3MulSub( distanceOutput.pointA, capsuleB->radius, delta ), distanceOutput.pointB ) );

		// Manifold in frame A
		manifold->normal = delta;
		manifold->pointCount = 1;

		b3LocalManifoldPoint* pt = manifold->points + 0;
		pt->point = point;
		pt->separation = distanceOutput.distance - capsuleB->radius;
		pt->pair = b3FeaturePair_single;
		return;
	}

	// Deep penetration

	b3FaceQuery faceQuery = b3QueryFaceDirectionHullAndCapsule( hullA, capsuleB, transformBtoA );
	if ( faceQuery.separation > capsuleB->radius )
	{
		// We found a separating axis
		return;
	}

	b3EdgeQuery edgeQuery = b3QueryEdgeDirectionHullAndCapsule( hullA, capsuleB, transformBtoA );
	if ( edgeQuery.separation > capsuleB->radius )
	{
		// We found a separating axis
		return;
	}

	// Create face contact
	float faceSeparation = faceQuery.separation - capsuleB->radius;
	b3BuildHullFaceAndCapsuleContact( manifold, hullA, capsuleB, transformBtoA, faceQuery );
	if ( manifold->pointCount > 1 )
	{
		// If ( Out.PointCount <= 1 ) -> Compare with unclipped separation
		// If ( Out.PointCount > 1 ) -> Be aggressive and compare with clipped separation
		// Face contact can be empty if it does not realize the axis of minimum penetration
		faceSeparation = b3DeepestPointSeparation( manifold );
	}
	B3_VALIDATE( faceSeparation <= 0.0f );

	// Face contact can be empty if it does not realize the axis of minimum penetration.
	// Create edge contact if face contact fails or edge contact is significantly better!
	const float kRelEdgeTolerance = 0.90f;
	const float kAbsTolerance = 0.5f * B3_LINEAR_SLOP;
	float edgeSeparation = edgeQuery.separation - capsuleB->radius;
	if ( manifold->pointCount == 0 || edgeSeparation > kRelEdgeTolerance * faceSeparation + kAbsTolerance )
	{
		// Edge contact
		b3BuildHullAndCapsuleEdgeContact( manifold, capacity, hullA, capsuleB, transformBtoA, edgeQuery );
	}
}

static int b3BuildPolygon( b3ClipVertex* out, b3Transform transform, const b3HullData* hull, int incFace, b3Plane refPlane )
{
	const b3HullFace* faces = b3GetHullFaces( hull );
	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	const b3Vec3* points = b3GetHullPoints( hull );

	const b3HullFace* face = faces + incFace;
	int edgeIndex = face->edge;
	B3_ASSERT( edges[edgeIndex].face == incFace );

	int outCount = 0;

	b3Matrix3 matrix = b3MakeMatrixFromQuat( transform.q );

	do
	{
		const b3HullHalfEdge* edge = edges + edgeIndex;

		int nextEdgeIndex = edge->next;
		const b3HullHalfEdge* next = edges + nextEdgeIndex;

		b3ClipVertex vertex;
		vertex.position = b3Add( b3MulMV( matrix, points[next->origin] ), transform.p );
		vertex.separation = b3PlaneSeparation( refPlane, vertex.position );
		vertex.pair = b3MakeFeaturePair( b3_featureShapeB, edgeIndex, b3_featureShapeB, nextEdgeIndex );

		out[outCount] = vertex;
		outCount += 1;

		edgeIndex = nextEdgeIndex;
	}
	while ( edgeIndex != face->edge && outCount < B3_MAX_CLIP_POINTS );

	B3_VALIDATE( b3ValidatePolygon( out, outCount ) );

	return outCount;
}

static bool b3BuildFaceAContact( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3HullData* hullB,
								 b3Transform transformBtoA, b3FaceQuery query, b3SATCache* cache )
{
	const b3HullFace* facesA = b3GetHullFaces( hullA );
	const b3HullHalfEdge* edgesA = b3GetHullEdges( hullA );
	const b3Plane* planesA = b3GetHullPlanes( hullA );
	const b3Vec3* pointsA = b3GetHullPoints( hullA );

	// Reference face
	int refFace = query.faceIndex;
	b3Plane refPlane = planesA[refFace];

	// Find incident face
	b3Vec3 refNormalInB = b3InvRotateVector( transformBtoA.q, refPlane.normal );
	int incFace = b3FindIncidentFace( hullB, refNormalInB, query.vertexIndex );

	// Build clip polygon from incident face in frame A
	b3ClipVertex buffer1[B3_MAX_CLIP_POINTS], buffer2[B3_MAX_CLIP_POINTS];
	int pointCount = b3BuildPolygon( buffer1, transformBtoA, hullB, incFace, refPlane );

	// Clip incident face against side planes of reference face
	b3ClipVertex* input = buffer1;
	b3ClipVertex* output = buffer2;

	const b3HullFace* face = facesA + refFace;
	int edgeIndex = face->edge;

	do
	{
		const b3HullHalfEdge* edge = edgesA + edgeIndex;
		int nextEdgeIndex = edge->next;
		const b3HullHalfEdge* next = edgesA + nextEdgeIndex;
		b3Vec3 vertex1 = pointsA[edge->origin];
		b3Vec3 vertex2 = pointsA[next->origin];
		b3Vec3 tangent = b3Normalize( b3Sub( vertex2, vertex1 ) );
		b3Vec3 binormal = b3Cross( tangent, refPlane.normal );

		b3Plane clipPlane = b3MakePlaneFromNormalAndPoint( binormal, vertex1 );

		pointCount = b3ClipPolygon( output, input, pointCount, clipPlane, edgeIndex, refPlane );
		B3_ASSERT( pointCount <= B3_MAX_CLIP_POINTS );

		B3_SWAP( output, input );

		if ( pointCount < 3 )
		{
			*cache = (b3SATCache){ 0 };
			return false;
		}

		edgeIndex = nextEdgeIndex;
	}
	while ( edgeIndex != face->edge );

	pointCount = b3MinInt( pointCount, B3_MAX_CLIP_POINTS );

	b3LocalManifoldPoint points[B3_MAX_CLIP_POINTS];
	float minSeparation = FLT_MAX;

	manifold->normal = refPlane.normal;

	for ( int i = 0; i < pointCount; ++i )
	{
		b3ClipVertex* clipPoint = input + i;
		b3LocalManifoldPoint* pt = points + i;
		*pt = (b3LocalManifoldPoint){ 0 };

		// Using the half-way point keeps the points in the same position when swapping reference face from A to B.
		b3Vec3 point = b3MulSub( clipPoint->position, 0.5f * clipPoint->separation, refPlane.normal );

		// Old way of pushing onto the reference face.
		// b3Vec3 point = clipPoint->position - clipPoint->separation * refPlane.normal;

		pt->point = point;
		pt->separation = clipPoint->separation;
		pt->pair = clipPoint->pair;

		minSeparation = b3MinFloat( minSeparation, clipPoint->separation );
	}

	if ( minSeparation >= B3_SPECULATIVE_DISTANCE )
	{
		*cache = (b3SATCache){ 0 };
		return false;
	}

	b3ReduceManifoldPoints( manifold, capacity, points, pointCount );

	// Save cache
	cache->separation = minSeparation;
	cache->type = (uint8_t)b3_faceAxisA;
	cache->indexA = (uint8_t)query.faceIndex;
	cache->indexB = (uint8_t)query.vertexIndex;

	return true;
}

static bool b3BuildFaceBContact( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3HullData* hullB,
								 b3Transform transformBtoA, b3FaceQuery query, b3SATCache* cache )
{
	b3Transform transformAtoB = b3InvertTransform( transformBtoA );
	bool touching = b3BuildFaceAContact( manifold, capacity, hullB, hullA, transformAtoB, query, cache );
	if ( touching == false )
	{
		return false;
	}

	// Results are in frame B, need to transform them into frame A
	b3Matrix3 matrix = b3MakeMatrixFromQuat( transformBtoA.q );

	// Transform and flip normal so it points from A to B, even though the B has the reference face.
	manifold->normal = b3Neg( b3MulMV( matrix, manifold->normal ) );
	cache->type = (uint8_t)b3_faceAxisB;
	cache->indexA = (uint8_t)query.vertexIndex;
	cache->indexB = (uint8_t)query.faceIndex;

	// Transform points from frame B to frame A.
	// Also flip the pairs to ensure correct matches.
	for ( int i = 0; i < manifold->pointCount; ++i )
	{
		b3LocalManifoldPoint* pt = manifold->points + i;
		pt->point = b3Add( b3MulMV( matrix, pt->point ), transformBtoA.p );
		pt->pair = b3FlipPair( pt->pair );
	}

	return true;
}

static bool b3BuildEdgeContact( b3LocalManifold* manifold, const b3HullData* hullA, const b3HullData* hullB, b3Transform transformBtoA,
								b3EdgeQuery query, b3SATCache* cache )
{
	// Work in shapeA coordinates
	const b3HullHalfEdge* edgesA = b3GetHullEdges( hullA );
	const b3Vec3* pointsA = b3GetHullPoints( hullA );

	const b3HullHalfEdge* edgesB = b3GetHullEdges( hullB );
	const b3Vec3* pointsB = b3GetHullPoints( hullB );

	// B3_VALIDATE( query.separation <= 2.0f * B3_SPECULATIVE_DISTANCE );

	const b3HullHalfEdge* edgeA = edgesA + query.indexA;
	const b3HullHalfEdge* twinA = edgesA + edgeA->twin;
	b3Vec3 centerA = hullA->center;
	b3Vec3 pA = pointsA[edgeA->origin];
	b3Vec3 qA = pointsA[twinA->origin];
	b3Vec3 eA = b3Sub( qA, pA );

	const b3HullHalfEdge* edgeB = edgesB + query.indexB;
	const b3HullHalfEdge* twinB = edgesB + edgeB->twin;
	b3Vec3 pB = b3TransformPoint( transformBtoA, pointsB[edgeB->origin] );
	b3Vec3 qB = b3TransformPoint( transformBtoA, pointsB[twinB->origin] );
	b3Vec3 eB = b3Sub( qB, pB );

	b3Vec3 normal = b3Cross( eA, eB );
	normal = b3Normalize( normal );

	if ( b3Dot( normal, b3Sub( pA, centerA ) ) < 0.0f )
	{
		normal = b3Neg( normal );
	}

	b3SegmentDistanceResult result = b3LineDistance( pA, eA, pB, eB );

	if ( b3IsWithinSegments( &result ) == false )
	{
		*cache = (b3SATCache){ 0 };
		return false;
	}

	// This can slide off the end from caching
	float separation = b3Dot( normal, b3Sub( result.point2, result.point1 ) );

	// todo I suspect this could trip if the cache becomes invalid
	// B3_VALIDATE( b3AbsFloat( separation - query.separation ) < B3_LINEAR_SLOP );

	b3Vec3 point = b3MulSV( 0.5f, b3Add( result.point1, result.point2 ) );

	// Result in frame A
	manifold->normal = normal;
	manifold->pointCount = 1;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = separation;
	pt->pair = b3MakeFeaturePair( b3_featureShapeA, query.indexA, b3_featureShapeB, query.indexB );

	// Save cache
	cache->separation = separation;
	cache->type = (uint8_t)b3_edgePairAxis;
	cache->indexA = (uint8_t)query.indexA;
	cache->indexB = (uint8_t)query.indexB;

	return true;
}

void b3CollideHulls( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3HullData* hullB, b3Transform transformBtoA,
					 b3SATCache* cache )
{
	manifold->pointCount = 0;

	if ( capacity < 4 )
	{
		return;
	}

	// Work in shapeA coordinates
	float speculativeDistance = B3_SPECULATIVE_DISTANCE;

	float linearSlop = B3_LINEAR_SLOP;
	const b3HullHalfEdge* edgesA = b3GetHullEdges( hullA );
	const b3Plane* planesA = b3GetHullPlanes( hullA );
	const b3Vec3* pointsA = b3GetHullPoints( hullA );

	const b3HullHalfEdge* edgesB = b3GetHullEdges( hullB );
	const b3Plane* planesB = b3GetHullPlanes( hullB );
	const b3Vec3* pointsB = b3GetHullPoints( hullB );

	// Attempt to use the cache to speed up collision
	switch ( cache->type )
	{
		case b3_invalidAxis:
			*cache = (b3SATCache){ 0 };
			break;

		case b3_faceAxisA:
		{
			B3_ASSERT( cache->indexA < hullA->faceCount );

			// Check for separation using cached face
			b3Plane plane = planesA[cache->indexA];
			b3Vec3 searchDirectionInB = b3Neg( b3InvRotateVector( transformBtoA.q, plane.normal ) );
			int vertexIndex = b3FindHullSupportVertex( hullB, searchDirectionInB );
			b3Vec3 support = b3TransformPoint( transformBtoA, pointsB[vertexIndex] );
			float separation = b3PlaneSeparation( plane, support );

			if ( separation >= speculativeDistance )
			{
				// Cache hit, shapes are separated
				return;
			}

			// if ( cache->separation < speculativeDistance )
			{
				// Attempt face contact using cached feature
				b3FaceQuery faceQuery;
				faceQuery.separation = 0.0f;
				faceQuery.faceIndex = cache->indexA;
				faceQuery.vertexIndex = vertexIndex;

				b3SATCache localCache = { 0 };
				bool touching = b3BuildFaceAContact( manifold, capacity, hullA, hullB, transformBtoA, faceQuery, &localCache );
				if ( touching == true && b3AbsFloat( cache->separation - localCache.separation ) < linearSlop )
				{
					// Cache hit, contact points generated
					return;
				}
			}
		}
		break;

		case b3_faceAxisB:
		{
			B3_ASSERT( cache->indexB < hullB->faceCount );

			// Check for separation using cached face
			b3Plane plane = planesB[cache->indexB];
			b3Vec3 searchDirectionInA = b3Neg( b3RotateVector( transformBtoA.q, plane.normal ) );
			int vertexIndex = b3FindHullSupportVertex( hullA, searchDirectionInA );
			b3Vec3 support = b3InvTransformPoint( transformBtoA, pointsA[vertexIndex] );
			float separation = b3PlaneSeparation( plane, support );

			if ( separation >= speculativeDistance )
			{
				// Cache hit, shapes are separated
				return;
			}

			// if ( cache->separation < speculativeDistance )
			{
				// Attempt face contact using cached feature
				b3FaceQuery faceQuery;
				faceQuery.separation = 0.0f;
				faceQuery.faceIndex = cache->indexB;
				faceQuery.vertexIndex = vertexIndex;

				b3SATCache localCache = { 0 };
				bool touching = b3BuildFaceBContact( manifold, capacity, hullA, hullB, transformBtoA, faceQuery, &localCache );
				if ( touching == true && b3AbsFloat( cache->separation - localCache.separation ) < linearSlop )
				{
					// Cache hit, contact points generated
					return;
				}
			}
		}
		break;

		case b3_edgePairAxis:
		{
			int index1 = cache->indexA;
			const b3HullHalfEdge* edge1 = edgesA + index1;
			const b3HullHalfEdge* twin1 = edgesA + index1 + 1;
			B3_ASSERT( edge1->twin == index1 + 1 && twin1->twin == index1 );

			b3Vec3 p1 = pointsA[edge1->origin];
			b3Vec3 q1 = pointsA[twin1->origin];
			b3Vec3 e1 = b3Sub( q1, p1 );

			b3Vec3 u1 = planesA[edge1->face].normal;
			b3Vec3 v1 = planesA[twin1->face].normal;

			int index2 = cache->indexB;
			const b3HullHalfEdge* edge2 = edgesB + index2;
			const b3HullHalfEdge* twin2 = edgesB + index2 + 1;
			B3_ASSERT( edge2->twin == index2 + 1 && twin2->twin == index2 );

			b3Vec3 p2 = b3TransformPoint( transformBtoA, pointsB[edge2->origin] );
			b3Vec3 q2 = b3TransformPoint( transformBtoA, pointsB[twin2->origin] );
			b3Vec3 e2 = b3Sub( q2, p2 );

			b3Vec3 u2 = b3RotateVector( transformBtoA.q, planesB[edge2->face].normal );
			b3Vec3 v2 = b3RotateVector( transformBtoA.q, planesB[twin2->face].normal );

			// flipping the signs of u2 and v2
			// cross(v2, u2) == cross(-v2, -u2)
			// so we still use -e2
			// but we can also use e1 = cross(u1, v1) and e2 = cross(u2, v2)
			bool isMinkowski = b3IsMinkowskiFace( u1, v1, e1, b3Neg( u2 ), b3Neg( v2 ), e2 );
			if ( isMinkowski == true )
			{
				// Transform reference center of the first hull into local space of the second hull
				b3Vec3 c1 = hullA->center;
				b3Vec3 c2 = b3TransformPoint( transformBtoA, hullB->center );

				float separation = b3EdgeEdgeSeparation( p1, e1, c1, p2, e2, c2 );
				if ( separation > speculativeDistance )
				{
					// Cache hit, shapes are separated
					return;
				}

				// if ( cache->separation <= speculativeDistance )
				{
					// Try to rebuild contact from last features
					b3EdgeQuery edgeQuery;
					edgeQuery.indexA = cache->indexA;
					edgeQuery.indexB = cache->indexB;
					edgeQuery.separation = 0.0f;

					b3SATCache localCache = { 0 };
					bool touching = b3BuildEdgeContact( manifold, hullA, hullB, transformBtoA, edgeQuery, &localCache );
					if ( touching && b3AbsFloat( cache->separation - localCache.separation ) < linearSlop )
					{
						// Cache hit, contact point generated
						return;
					}
				}
			}
		}
		break;

			// This case is for testing
		case b3_manualFaceAxisA:
		{
			b3FaceQuery faceQueryA = b3QueryFaceDirections( hullA, hullB, transformBtoA );
			b3BuildFaceAContact( manifold, capacity, hullA, hullB, transformBtoA, faceQueryA, cache );
			return;
		}

			// This case is for testing
		case b3_manualFaceAxisB:
		{
			b3FaceQuery faceQueryB = b3QueryFaceDirections( hullB, hullA, b3InvertTransform( transformBtoA ) );
			b3BuildFaceBContact( manifold, capacity, hullA, hullB, transformBtoA, faceQueryB, cache );
			return;
		}

			// This case is for testing
		case b3_manualEdgePairAxis:
		{
			b3EdgeQuery edgeQuery = b3QueryEdgeDirections( hullA, hullB, transformBtoA );
			if ( edgeQuery.indexA != B3_NULL_INDEX )
			{
				b3BuildEdgeContact( manifold, hullA, hullB, transformBtoA, edgeQuery, cache );
			}
			return;
		}

		default:
			B3_ASSERT( false );
			break;
	}

	manifold->pointCount = 0;
	*cache = (b3SATCache){ 0 };

	// Find axis of minimum penetration
	b3FaceQuery faceQueryA = b3QueryFaceDirections( hullA, hullB, transformBtoA );
	if ( faceQueryA.separation > speculativeDistance )
	{
		B3_ASSERT( faceQueryA.faceIndex < hullA->faceCount );
		B3_ASSERT( faceQueryA.vertexIndex < hullB->vertexCount );

		// We found a separating axis
		cache->separation = faceQueryA.separation;
		cache->type = (uint8_t)b3_faceAxisA;
		cache->indexA = (uint8_t)faceQueryA.faceIndex;
		cache->indexB = (uint8_t)faceQueryA.vertexIndex;
		return;
	}

	b3FaceQuery faceQueryB = b3QueryFaceDirections( hullB, hullA, b3InvertTransform( transformBtoA ) );
	if ( faceQueryB.separation > speculativeDistance )
	{
		B3_ASSERT( faceQueryB.faceIndex < hullB->faceCount );
		B3_ASSERT( faceQueryB.vertexIndex < hullA->vertexCount );

		// We found a separating axis
		cache->separation = faceQueryB.separation;
		cache->type = (uint8_t)b3_faceAxisB;
		cache->indexA = (uint8_t)faceQueryB.vertexIndex;
		cache->indexB = (uint8_t)faceQueryB.faceIndex;
		return;
	}

	b3EdgeQuery edgeQuery = b3QueryEdgeDirections( hullA, hullB, transformBtoA );
	if ( edgeQuery.separation > speculativeDistance )
	{
		// We found a separating axis
		cache->separation = edgeQuery.separation;
		cache->type = (uint8_t)b3_edgePairAxis;
		cache->indexA = (uint8_t)edgeQuery.indexA;
		cache->indexB = (uint8_t)edgeQuery.indexB;
		return;
	}

	// Always build a face contact (e.g. Jenga problem)
	float faceSeparationA = faceQueryA.separation;
	float faceSeparationB = faceQueryB.separation;
	B3_VALIDATE( faceSeparationA <= speculativeDistance && faceSeparationB <= speculativeDistance );

	if ( faceSeparationB > faceSeparationA + 0.5f * linearSlop )
	{
		// Face contact B
		b3BuildFaceBContact( manifold, capacity, hullA, hullB, transformBtoA, faceQueryB, cache );
	}
	else
	{
		// Face contact A
		b3BuildFaceAContact( manifold, capacity, hullA, hullB, transformBtoA, faceQueryA, cache );
	}

	if ( edgeQuery.indexA == B3_NULL_INDEX )
	{
		// There are no valid edge pairs (all edges parallel)
		return;
	}

	float clippedFaceSeparation = cache->separation;

	B3_VALIDATE( edgeQuery.separation <= speculativeDistance );

	// todo get rid of relative tolerance
	const float kRelEdgeTolerance = 0.90f;
	// const float kRelFaceTolerance = 0.98f;
	const float kAbsTolerance = 0.5f * linearSlop;

	// Face contact can be empty if it does not realize the axis of minimum penetration.
	// Create edge contact if face contact fails or edge contact is significantly better!
	if ( manifold->pointCount == 0 || edgeQuery.separation > kRelEdgeTolerance * clippedFaceSeparation + kAbsTolerance )
	{
		// Edge contact
		b3LocalManifold edgeManifold = { 0 };
		b3LocalManifoldPoint edgePoint = { 0 };
		edgeManifold.points = &edgePoint;

		b3BuildEdgeContact( &edgeManifold, hullA, hullB, transformBtoA, edgeQuery, cache );

		// It is possible with speculation to have vertex-vertex collision that is missed by SAT.
		// todo I doubt this backup scheme matters because I'm using the clipped face separation.
		// B3_VALIDATE( edgeManifold.pointCount == 1 );

		if ( edgeManifold.pointCount == 1 )
		{
			// Copy edge manifold out, being careful to preserve manifold point buffer.
			b3LocalManifoldPoint* points = manifold->points;
			*manifold = edgeManifold;
			manifold->points = points;
			manifold->points[0] = edgePoint;
		}
	}
}
