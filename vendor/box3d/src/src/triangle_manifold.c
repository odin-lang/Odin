// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "algorithm.h"
#include "contact.h"
#include "core.h"
#include "manifold.h"
#include "shape.h"

#include "box3d/base.h"
#include "box3d/collision.h"
#include "box3d/constants.h"

#include <stdbool.h>
#include <stddef.h>

typedef struct b3TriangleData
{
	b3Vec3 v1, v2, v3;
	b3Vec3 e1, e2, e3;
	b3Vec3 center;
	b3Plane plane;
	int flags;
} b3TriangleData;

// Indexed by the 3-bit vertex mask
static const b3TriangleFeature s_triangleFeatures[8] = {
	b3_featureNone,			// 000  (unreachable)
	b3_featureVertex1,		// 001
	b3_featureVertex2,		// 010
	b3_featureEdge1,		// 011  v1,v2
	b3_featureVertex3,		// 100
	b3_featureEdge3,		// 101  v1,v3
	b3_featureEdge2,		// 110  v2,v3
	b3_featureTriangleFace, // 111
};

static b3TriangleFeature b3GetTriangleFeature( const b3SimplexCache* cache )
{
	int count = cache->count;
	B3_ASSERT( 0 < count && count < 4 );

	// Bit i set means triangle vertex i participates in the simplex.
	int mask = 0;
	for ( int i = 0; i < count; ++i )
	{
		B3_ASSERT( cache->indexA[i] < 3 );
		mask |= 1 << cache->indexA[i];
	}

	return s_triangleFeatures[mask];
}

void b3CollideSphereAndTriangle( b3LocalManifold* manifold, int capacity, const b3Sphere* sphereA, const b3Vec3* triangleB )
{
	manifold->pointCount = 0;

	if ( capacity == 0 )
	{
		return;
	}

	b3Vec3 center = sphereA->center;
	b3Vec3 v1 = triangleB[0], v2 = triangleB[1], v3 = triangleB[2];
	b3Plane plane = b3MakePlaneFromPoints( v1, v2, v3 );

	float offset = b3PlaneSeparation( plane, center );
	if ( offset < 0.0f )
	{
		// Cull back side collision
		return;
	}

	// Closest point on triangle to sphere center
	b3TrianglePoint closest = b3ClosestPointOnTriangle( v1, v2, v3, center );

	// Test separating axis
	float squaredDistance = b3DistanceSquared( closest.point, center );
	float speculativeDistance = B3_SPECULATIVE_DISTANCE;
	float maxDistance = sphereA->radius + speculativeDistance;
	if ( squaredDistance > maxDistance * maxDistance )
	{
		return;
	}

	float distance = sqrtf( squaredDistance );
	b3Vec3 normal;
	if ( distance * distance > 1000.0f * FLT_MIN )
	{
		normal = b3MulSV( 1.0f / distance, b3Sub( center, closest.point ) );
	}
	else
	{
		normal = b3Normalize( b3Cross( b3Sub( v2, v1 ), b3Sub( v3, v1 ) ) );
	}

	// contact point mid-way
	b3Vec3 contactPoint = b3MulSV( 0.5f, b3Add( b3Sub( center, b3MulSV( sphereA->radius, normal ) ), closest.point ) );

	manifold->normal = normal;
	manifold->pointCount = 1;
	manifold->feature = closest.feature;
	manifold->squaredDistance = squaredDistance;

	b3LocalManifoldPoint* mp = manifold->points + 0;
	mp->point = contactPoint;
	mp->separation = distance - sphereA->radius;
	mp->pair = b3FeaturePair_single;
}

static bool b3ClipSegmentToTriangleFace( b3ClipVertex segment[2], const b3Vec3* points, b3Plane plane )
{
	b3Vec3 vertex1 = points[2];
	for ( int i = 0; i < 3; ++i )
	{
		b3Vec3 vertex2 = points[i];
		b3Vec3 tangent = b3Normalize( b3Sub( vertex2, vertex1 ) );
		b3Vec3 binormal = b3Cross( tangent, plane.normal );

		b3Plane clipPlane = b3MakePlaneFromNormalAndPoint( binormal, vertex1 );

		int vertexCount = 0;
		b3ClipVertex p1 = segment[0];
		b3ClipVertex p2 = segment[1];

		float distance1 = b3PlaneSeparation( clipPlane, p1.position );
		float distance2 = b3PlaneSeparation( clipPlane, p2.position );

		// If the points are behind the plane
		if ( distance1 <= 0.0f )
		{
			segment[vertexCount++] = p1;
		}
		if ( distance2 <= 0.0f )
		{
			segment[vertexCount++] = p2;
		}

		// If the points are on different sides of the plane
		if ( distance1 * distance2 < 0.0f )
		{
			// Find intersection point of edge and plane
			float t = distance1 / ( distance1 - distance2 );
			segment[vertexCount].position = b3Lerp( p1.position, p2.position, t );
			segment[vertexCount].pair = distance1 > 0.0f ? p1.pair : p2.pair;
			vertexCount++;
		}

		if ( vertexCount != 2 )
		{
			return false;
		}

		vertex1 = vertex2;
	}

	return true;
}

static b3FaceQuery b3QueryTriangleFaceAndCapsule( b3Plane plane, const b3Capsule* capsule )
{
	float separation1 = b3PlaneSeparation( plane, capsule->center1 );
	float separation2 = b3PlaneSeparation( plane, capsule->center2 );

	if ( separation1 < separation2 )
	{
		return (b3FaceQuery){
			.separation = separation1,
			.faceIndex = 0,
			.vertexIndex = 0,
		};
	}

	return (b3FaceQuery){
		.separation = separation2,
		.faceIndex = 0,
		.vertexIndex = 1,
	};
}

static b3EdgeQuery b3QueryTriangleAndCapsuleEdges( const b3Vec3* vertices, const b3Capsule* capsule )
{
	// Work in the local space of the capsule
	b3Vec3 p1 = capsule->center1;
	b3Vec3 p2 = capsule->center2;
	b3Vec3 capsuleEdge = b3Sub( p2, p1 );

	b3Vec3 capsuleCenter = b3Lerp( p1, p2, 0.5f );

	b3Vec3 triangleCenter = b3MulSV( 1.0f / 3.0f, b3Add( vertices[0], b3Add( vertices[1], vertices[2] ) ) );

	// Find axis of minimum penetration
	float maxSeparation = -FLT_MAX;
	int maxIndex1 = UINT8_MAX;
	int maxIndex2 = UINT8_MAX;

	int edgeIndex = 2;
	b3Vec3 v1 = vertices[2];
	for ( int index = 0; index < 3; ++index )
	{
		b3Vec3 v2 = vertices[index];

		b3Vec3 triangleEdge = b3Sub( v2, v1 );

		float separation = b3EdgeEdgeSeparation( p1, capsuleEdge, capsuleCenter, v1, triangleEdge, triangleCenter );
		if ( separation > maxSeparation )
		{
			// Note: We don't exit early if we find a separating axis here since we want to
			// find the best one for caching and account for the convex radius later.
			maxSeparation = separation;
			maxIndex1 = edgeIndex;
			maxIndex2 = 0;
		}

		v1 = v2;
		edgeIndex = index;
	}

	// Save result
	return (b3EdgeQuery){
		.separation = maxSeparation,
		.indexA = (uint8_t)maxIndex1,
		.indexB = (uint8_t)maxIndex2,
	};
}

static void b3BuildTriangleAndCapsuleFaceContact( b3LocalManifold* manifold, const b3Vec3* triangle, b3Plane plane,
												  const b3Capsule* capsule )
{
	B3_ASSERT( manifold->pointCount == 0 );

	b3ClipVertex segment[2];
	segment[0].position = capsule->center1;
	segment[0].separation = 0.0f;
	segment[0].pair = b3MakeFeaturePair( b3_featureShapeA, 0, b3_featureShapeA, 0 );
	segment[1].position = capsule->center2;
	segment[1].separation = 0.0f;
	segment[1].pair = b3MakeFeaturePair( b3_featureShapeA, 1, b3_featureShapeA, 1 );

	bool havePoints = b3ClipSegmentToTriangleFace( segment, triangle, plane );
	if ( havePoints == false )
	{
		return;
	}

	float radius = capsule->radius;
	float distance1 = b3PlaneSeparation( plane, segment[0].position );
	float distance2 = b3PlaneSeparation( plane, segment[1].position );

	float speculativeDistance = B3_SPECULATIVE_DISTANCE;
	if ( distance1 > speculativeDistance + radius && distance2 > speculativeDistance + radius )
	{
		return;
	}

	// Average points. Half-way between capsule bottom and triangle plane.
	b3Vec3 point1 = b3MulSub( segment[0].position, 0.5f * ( distance1 + capsule->radius ), plane.normal );
	b3Vec3 point2 = b3MulSub( segment[1].position, 0.5f * ( distance2 + capsule->radius ), plane.normal );

	manifold->normal = plane.normal;
	manifold->feature = b3_featureTriangleFace;
	manifold->pointCount = 2;

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point1;
	pt->separation = distance1 - capsule->radius;
	pt->pair = segment[0].pair;

	pt = manifold->points + 1;
	pt->point = point2;
	pt->separation = distance2 - capsule->radius;
	pt->pair = segment[1].pair;
}

static void b3BuildTriangleAndCapsuleEdgeContact( b3LocalManifold* manifold, const b3Vec3* triangle, const b3Capsule* capsule,
												  b3EdgeQuery query )
{
	B3_ASSERT( 0 <= query.indexA && query.indexA < 3 );

	b3Vec3 p1 = capsule->center1;
	b3Vec3 p2 = capsule->center2;
	b3Vec3 capsuleEdge = b3Sub( p2, p1 );

	const b3Vec3* vs = triangle;

	b3Vec3 triangleCenter = b3MulSV( 1.0f / 3.0f, b3Add( vs[0], b3Add( vs[1], vs[2] ) ) );
	b3Vec3 v1 = vs[query.indexA];
	b3Vec3 v2 = vs[( query.indexA + 1 ) % 3];
	b3Vec3 triangleEdge = b3Sub( v2, v1 );

	b3Vec3 normal = b3Cross( capsuleEdge, triangleEdge );
	normal = b3Normalize( normal );

	// Normal should point away from triangle center
	if ( b3Dot( normal, b3Sub( v1, triangleCenter ) ) < 0.0f )
	{
		normal = b3Neg( normal );
	}

	b3SegmentDistanceResult result = b3LineDistance( v1, triangleEdge, p1, capsuleEdge );

	if ( result.fraction1 < 0.0f || 1.0f < result.fraction1 || result.fraction2 < 0.0f || 1.0f < result.fraction2 )
	{
		// closest point beyond end points
		return;
	}

	b3Vec3 point = b3Lerp( b3MulSub( result.point1, capsule->radius, normal ), result.point2, 0.5f );

	float separation = b3Dot( normal, b3Sub( result.point2, result.point1 ) );
	B3_VALIDATE( b3AbsFloat( separation - query.separation ) < B3_LINEAR_SLOP );

	manifold->normal = normal;
	manifold->pointCount = 1;

	b3TriangleFeature edgesFeatures[] = { b3_featureEdge1, b3_featureEdge2, b3_featureEdge3 };
	manifold->feature = edgesFeatures[query.indexA];

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = separation - capsule->radius;
	pt->pair = b3MakeFeaturePair( b3_featureShapeA, query.indexA, b3_featureShapeB, query.indexB );
}

void b3CollideCapsuleAndTriangle( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA, const b3Vec3* triangleB,
								  b3SimplexCache* cache )
{
	manifold->pointCount = 0;

	if ( capacity < 2 )
	{
		return;
	}

	b3Vec3 v1 = triangleB[0], v2 = triangleB[1], v3 = triangleB[2];
	b3Plane plane = b3MakePlaneFromPoints( v1, v2, v3 );
	b3Vec3 capsuleCenter = b3Lerp( capsuleA->center1, capsuleA->center2, 0.5f );

	float offset = b3PlaneSeparation( plane, capsuleCenter );
	if ( offset < 0.0f )
	{
		// Cull back side collision
		return;
	}

	b3DistanceInput distanceInput;
	distanceInput.proxyA = (b3ShapeProxy){ triangleB, 3, 0.0f };
	distanceInput.proxyB = (b3ShapeProxy){ &capsuleA->center1, 2, 0.0f };
	distanceInput.transform = b3Transform_identity;
	distanceInput.useRadii = false;

	b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, cache, NULL, 0 );

	float radius = capsuleA->radius;
	if ( distanceOutput.distance > radius + B3_SPECULATIVE_DISTANCE )
	{
		// Shapes are separated, persist the cache
		return;
	}

	if ( distanceOutput.distance > 100.0f * FLT_EPSILON )
	{
		// Shallow penetration
		b3Vec3 delta = b3Normalize( b3Sub( distanceOutput.pointB, distanceOutput.pointA ) );

		// Try to create two contact points if closest points difference is nearly parallel to face normal
		const float kTolerance = 0.2f;
		float cosAngle = b3AbsFloat( b3Dot( plane.normal, delta ) );
		if ( cosAngle > kTolerance )
		{
			// Clip capsule segment against side planes of reference face
			b3ClipVertex segment[2];
			segment[0].position = capsuleA->center1;
			segment[0].separation = 0.0f;
			segment[0].pair = b3MakeFeaturePair( b3_featureShapeA, 0, b3_featureShapeA, 0 );
			segment[1].position = capsuleA->center2;
			segment[1].separation = 0.0f;
			segment[1].pair = b3MakeFeaturePair( b3_featureShapeA, 1, b3_featureShapeA, 1 );

			bool havePoints = b3ClipSegmentToTriangleFace( segment, triangleB, plane );

			if ( havePoints == true )
			{
				float distance1 = b3PlaneSeparation( plane, segment[0].position );
				float distance2 = b3PlaneSeparation( plane, segment[1].position );

				b3Vec3 normal = plane.normal;
				b3Vec3 point1 = b3MulSub( segment[0].position, 0.5f * ( radius + distance1 ), normal );
				b3Vec3 point2 = b3MulSub( segment[1].position, 0.5f * ( radius + distance2 ), normal );

				manifold->normal = normal;
				manifold->feature = b3_featureTriangleFace;
				manifold->pointCount = 2;

				b3LocalManifoldPoint* mp = manifold->points + 0;
				mp->point = point1;
				mp->separation = distance1 - radius;
				mp->pair = segment[0].pair;

				mp = manifold->points + 1;
				mp->point = point2;
				mp->separation = distance2 - radius;
				mp->pair = segment[1].pair;

				return;
			}
		}

		// Create contact from closest points
		b3Vec3 point = b3MulSV( 0.5f, b3Add( b3Sub( distanceOutput.pointA, b3MulSV( radius, delta ) ), distanceOutput.pointB ) );

		manifold->normal = delta;
		manifold->pointCount = 1;
		manifold->feature = b3GetTriangleFeature( cache );

		b3LocalManifoldPoint* mp = manifold->points + 0;
		mp->point = point;
		mp->separation = distanceOutput.distance - radius;
		mp->pair = b3FeaturePair_single;

		return;
	}

	// Deep penetration

	b3FaceQuery faceQuery = b3QueryTriangleFaceAndCapsule( plane, capsuleA );
	if ( faceQuery.separation > radius )
	{
		// Shapes are separated
		return;
	}

	b3EdgeQuery edgeQuery = b3QueryTriangleAndCapsuleEdges( triangleB, capsuleA );
	if ( edgeQuery.separation > radius )
	{
		// Shapes are separated
		return;
	}

	// Create face contact
	float faceSeparation = faceQuery.separation - radius;
	b3BuildTriangleAndCapsuleFaceContact( manifold, triangleB, plane, capsuleA );
	if ( manifold->pointCount == 2 )
	{
		faceSeparation = b3MinFloat( manifold->points[0].separation, manifold->points[1].separation );
	}
	B3_VALIDATE( faceSeparation <= 0.0f );

	// Face contact can be empty if it does not realize the axis of minimum penetration.
	// Create edge contact if face contact fails or edge contact is significantly better!
	const float kRelEdgeTolerance = 0.50f;
	const float kAbsTolerance = 1.0f * B3_LINEAR_SLOP;
	float edgeSeparation = edgeQuery.separation - radius;
	if ( manifold->pointCount == 0 || edgeSeparation > kRelEdgeTolerance * faceSeparation + kAbsTolerance )
	{
		// Edge contact
		b3BuildTriangleAndCapsuleEdgeContact( manifold, triangleB, capsuleA, edgeQuery );
	}
}

static inline int b3GetTriangleSupport( b3Vec3* points, b3Vec3 direction )
{
	int index = 0;
	float distance = b3Dot( points[0], direction );

	float d = b3Dot( points[1], direction );
	if ( d > distance )
	{
		distance = d;
		index = 1;
	}

	d = b3Dot( points[2], direction );
	if ( d > distance )
	{
		return 2;
	}

	return index;
}

static b3FaceQuery b3QueryTriangleFace( const b3TriangleData* triangle, const b3HullData* hull )
{
	const b3Vec3* hullPoints = b3GetHullPoints( hull );
	b3Plane plane = triangle->plane;
	int vertexIndex = b3FindHullSupportVertex( hull, b3Neg( plane.normal ) );
	b3Vec3 support = hullPoints[vertexIndex];
	float separation = b3PlaneSeparation( plane, support );

	return (b3FaceQuery){
		.separation = separation,
		.faceIndex = 0,
		.vertexIndex = (uint8_t)vertexIndex,
	};
}

static b3FaceQuery b3QueryHullFace( const b3TriangleData* triangle, const b3HullData* hull )
{
	const b3Plane* hullPlanes = b3GetHullPlanes( hull );
	int faceCount = hull->faceCount;

	b3Vec3 trianglePoints[] = { triangle->v1, triangle->v2, triangle->v3 };

	int maxFaceIndex = -1;
	int maxVertexIndex = -1;
	float maxFaceSeparation = -FLT_MAX;

	for ( int faceIndex = 0; faceIndex < faceCount; ++faceIndex )
	{
		b3Plane plane = hullPlanes[faceIndex];

		int vertexIndex = b3GetTriangleSupport( trianglePoints, b3Neg( plane.normal ) );
		b3Vec3 support = trianglePoints[vertexIndex];
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
		.faceIndex = maxFaceIndex,
		.vertexIndex = maxVertexIndex,
	};
}

static b3EdgeQuery b3TestEdgePairs( const b3TriangleData* triangle, const b3HullData* hull )
{
	b3EdgeQuery result = {
		.separation = -FLT_MAX,
		.indexA = B3_NULL_INDEX,
		.indexB = B3_NULL_INDEX,
	};

	b3Vec3 trianglePoints[] = { triangle->v1, triangle->v2, triangle->v3 };
	b3Vec3 triangleEdges[] = { triangle->e1, triangle->e2, triangle->e3 };
	// int edgeFlags[] = { b3_concaveEdge1, b3_concaveEdge1, b3_concaveEdge3 };

#if B3_FORCE_GHOST_COLLISIONS
	int triangleFlags = 0xFF;
#else
	int triangleFlags = triangle->flags;
#endif
	(void)triangleFlags;

	b3Vec3 triNormal = triangle->plane.normal;

	const b3HullHalfEdge* hullEdges = b3GetHullEdges( hull );
	const b3Vec3* hullPoints = b3GetHullPoints( hull );
	const b3Plane* hullPlanes = b3GetHullPlanes( hull );
	int edgeCount = hull->edgeCount;

	for ( int i = 0; i < edgeCount; i += 2 )
	{
		const b3HullHalfEdge* edge = hullEdges + i;
		const b3HullHalfEdge* twin = hullEdges + i + 1;
		B3_ASSERT( edge->twin == i + 1 && twin->twin == i );

		b3Vec3 hullPoint = hullPoints[edge->origin];
		b3Vec3 hullEdge = b3Sub( hullPoints[twin->origin], hullPoint );

		b3Vec3 hullNormal1 = hullPlanes[edge->face].normal;
		b3Vec3 hullNormal2 = hullPlanes[twin->face].normal;

		for ( int j = 0; j < 3; ++j )
		{
			b3Vec3 triEdge = triangleEdges[j];

			float cab = b3Dot( hullNormal1, triEdge );
			float dab = b3Dot( hullNormal2, triEdge );
			float bcd = b3Dot( triNormal, hullEdge );
			if ( cab * dab >= 0.0f || cab * bcd <= 0.0f )
			{
				continue;
			}

			b3Vec3 triPoint = trianglePoints[j];
			float separation = b3EdgeEdgeSeparation( triPoint, triEdge, triangle->center, hullPoint, hullEdge, hull->center );

			// if ( separation > result.separation && ( edgeFlags[j] & triangleFlags ) == 0 )
			if ( separation > result.separation )
			{
				// Note: We don't exit early if we find a separating axis here since we want to
				// find the best one for caching.
				result.separation = separation;
				result.indexA = j;
				result.indexB = i;
			}
		}
	}

	return result;
}

static float b3CollideHullFace( b3LocalManifold* manifold, int pointCapacity, const b3TriangleData* triangle,
								const b3HullData* hull, b3FaceQuery query, b3SATCache* cache, bool enableSpeculative )
{
	manifold->pointCount = 0;

	const b3HullFace* hullFaces = b3GetHullFaces( hull );
	const b3HullHalfEdge* hullEdges = b3GetHullEdges( hull );
	const b3Plane* hullPlanes = b3GetHullPlanes( hull );
	const b3Vec3* hullPoints = b3GetHullPoints( hull );

	// Reference hull face
	int refFace = query.faceIndex;
	b3Plane refPlane = hullPlanes[refFace];

	// Build clip polygon from triangle face (the incident face)
	b3ClipVertex buffer1[B3_MAX_CLIP_POINTS], buffer2[B3_MAX_CLIP_POINTS];

	b3Vec3 v1 = triangle->v1;
	b3Vec3 v2 = triangle->v2;
	b3Vec3 v3 = triangle->v3;
	buffer1[0].position = v1;
	buffer1[0].separation = b3PlaneSeparation( refPlane, v1 );
	buffer1[0].pair = b3MakeFeaturePair( b3_featureShapeB, 2, b3_featureShapeB, 0 );
	buffer1[1].position = v2;
	buffer1[1].separation = b3PlaneSeparation( refPlane, v2 );
	buffer1[1].pair = b3MakeFeaturePair( b3_featureShapeB, 0, b3_featureShapeB, 1 );
	buffer1[2].position = v3;
	buffer1[2].separation = b3PlaneSeparation( refPlane, v3 );
	buffer1[2].pair = b3MakeFeaturePair( b3_featureShapeB, 1, b3_featureShapeB, 2 );
	int pointCount = 3;

	// Clip triangle face against side planes of reference face
	b3ClipVertex* input = buffer1;
	b3ClipVertex* output = buffer2;

	const b3HullFace* face = hullFaces + refFace;
	int edgeIndex = face->edge;

	do
	{
		const b3HullHalfEdge* edge = hullEdges + edgeIndex;
		int nextEdgeIndex = edge->next;
		const b3HullHalfEdge* next = hullEdges + nextEdgeIndex;
		b3Vec3 vertex1 = hullPoints[edge->origin];
		b3Vec3 vertex2 = hullPoints[next->origin];
		b3Vec3 tangent = b3Normalize( b3Sub( vertex2, vertex1 ) );
		b3Vec3 binormal = b3Cross( tangent, refPlane.normal );

		b3Plane clipPlane = b3MakePlaneFromNormalAndPoint( binormal, vertex1 );

		pointCount = b3ClipPolygon( output, input, pointCount, clipPlane, edgeIndex, refPlane );
		B3_ASSERT( pointCount <= B3_MAX_CLIP_POINTS );

		if ( pointCount < 3 )
		{
			// Using a stale cache
			*cache = (b3SATCache){ 0 };
			return query.separation;
		}

		// Swap buffers, output becomes input for the next clipping plane
		B3_SWAP( output, input );
		edgeIndex = nextEdgeIndex;
	}
	while ( edgeIndex != face->edge );

	pointCount = b3MinInt( pointCount, pointCapacity );
	float minSeparation = FLT_MAX;
	int finalPointCount = 0;

	for ( int i = 0; i < pointCount; ++i )
	{
		b3ClipVertex* clipPoint = input + i;
		minSeparation = b3MinFloat( minSeparation, clipPoint->separation );

		if ( enableSpeculative == false && clipPoint->separation > 0.0f )
		{
			continue;
		}

		// Move point onto hull face improved culling
		b3Vec3 point = b3MulSub( clipPoint->position, clipPoint->separation, refPlane.normal );

		b3LocalManifoldPoint* pt = manifold->points + finalPointCount;
		pt->point = point;
		pt->separation = clipPoint->separation;
		pt->pair = b3FlipPair( clipPoint->pair );

		finalPointCount += 1;
	}

	float speculativeDistance = enableSpeculative ? B3_SPECULATIVE_DISTANCE : 0.0f;
	if ( minSeparation > speculativeDistance )
	{
		// This can occur with a stale SAT cache
		manifold->pointCount = 0;
		*cache = (b3SATCache){ 0 };
		return minSeparation;
	}

	manifold->pointCount = finalPointCount;
	manifold->normal = b3Neg( refPlane.normal );
	manifold->feature = b3_featureHullFace;

	// Save cache
	cache->separation = minSeparation;
	cache->type = b3_faceAxisB;
	cache->indexA = (uint8_t)query.vertexIndex;
	cache->indexB = (uint8_t)query.faceIndex;
	return minSeparation;
}

static float b3CollideTriangleFace( b3LocalManifold* manifold, int pointCapacity, const b3TriangleData* triangle,
									const b3HullData* hull, b3FaceQuery query, b3SATCache* cache, bool enableSpeculative )
{
	B3_VALIDATE( manifold->pointCount == 0 );

	const b3HullFace* hullFaces = b3GetHullFaces( hull );
	const b3HullHalfEdge* hullEdges = b3GetHullEdges( hull );
	const b3Vec3* hullPoints = b3GetHullPoints( hull );

	// Find incident face
	B3_ASSERT( query.faceIndex == 0 );
	b3Plane refPlane = triangle->plane;

	int incFace = b3FindIncidentFace( hull, refPlane.normal, query.vertexIndex );

	// Build clip polygon from incident face
	b3ClipVertex buffer1[2 * B3_MAX_CLIP_POINTS], buffer2[2 * B3_MAX_CLIP_POINTS];
	int pointCount = 0;
	const b3HullFace* face = hullFaces + incFace;
	int hullEdgeIndex = face->edge;

	do
	{
		const b3HullHalfEdge* edge = hullEdges + hullEdgeIndex;

		int nextEdgeIndex = edge->next;
		const b3HullHalfEdge* next = hullEdges + nextEdgeIndex;

		b3Vec3 hullPoint = hullPoints[next->origin];
		buffer1[pointCount].position = hullPoint;
		buffer1[pointCount].separation = b3PlaneSeparation( refPlane, hullPoint );
		buffer1[pointCount].pair = b3MakeFeaturePair( b3_featureShapeB, hullEdgeIndex, b3_featureShapeB, nextEdgeIndex );

		pointCount += 1;
		hullEdgeIndex = nextEdgeIndex;
	}
	while ( hullEdgeIndex != face->edge && pointCount < 2 * B3_MAX_CLIP_POINTS );

	B3_ASSERT( pointCount >= 3 );

	// Clip incident face against side planes of reference face (triangle)
	b3ClipVertex* input = buffer1;
	b3ClipVertex* output = buffer2;

	b3Vec3 trianglePoints[] = { triangle->v1, triangle->v2, triangle->v3 };
	b3Vec3 triangleEdges[] = { triangle->e1, triangle->e2, triangle->e3 };

	for ( int i = 0; i < 3 && pointCount > 0; ++i )
	{
		b3Vec3 sideNormal = b3Cross( triangleEdges[i], refPlane.normal );
		sideNormal = b3Normalize( sideNormal );

		b3Plane clipPlane = b3MakePlaneFromNormalAndPoint( sideNormal, trianglePoints[i] );

		pointCount = b3ClipPolygon( output, input, pointCount, clipPlane, i, refPlane );
		B3_ASSERT( pointCount <= 2 * B3_MAX_CLIP_POINTS );

		B3_SWAP( output, input );
	}

	if ( pointCount == 0 )
	{
		// Triangle face clipped away. Invalidate cache.
		*cache = (b3SATCache){ 0 };
		return FLT_MAX;
	}

	pointCount = b3MinInt( pointCount, pointCapacity );

	float minSeparation = FLT_MAX;

	int finalPointCount = 0;
	for ( int i = 0; i < pointCount; ++i )
	{
		b3ClipVertex* clipPoint = input + i;
		minSeparation = b3MinFloat( minSeparation, clipPoint->separation );

		if ( enableSpeculative == false && clipPoint->separation > 0.0f )
		{
			continue;
		}

		// Move point onto triangle surface for improved culling
		// b3Vec3 point = b3MulSub( clipPoint->position, clipPoint->separation, refPlane.normal );
		b3Vec3 point = clipPoint->position;

		b3LocalManifoldPoint* pt = manifold->points + finalPointCount;
		pt->point = point;
		pt->separation = clipPoint->separation;
		pt->pair = clipPoint->pair;

		finalPointCount += 1;
	}

	float speculativeDistance = enableSpeculative ? B3_SPECULATIVE_DISTANCE : 0.0f;
	if ( minSeparation >= speculativeDistance )
	{
		// This can happens if the objects move a part while re-using a cached axis
		*cache = (b3SATCache){ 0 };
		return minSeparation;
	}

	manifold->pointCount = finalPointCount;
	manifold->normal = refPlane.normal;
	manifold->feature = b3_featureTriangleFace;

	// Save cache
	cache->separation = minSeparation;
	cache->type = b3_faceAxisA;
	cache->indexA = (uint8_t)query.faceIndex;
	cache->indexB = (uint8_t)query.vertexIndex;
	return minSeparation;
}

static void b3CollideHullAndTriangleEdges( b3LocalManifold* manifold, int capacity, b3Vec3 trianglePoint, b3Vec3 triangleEdge,
										   b3Vec3 triangleCenter, const b3HullData* hull, b3EdgeQuery query, b3SATCache* cache )
{
	B3_VALIDATE( query.separation <= 2.0f * B3_SPECULATIVE_DISTANCE );
	B3_ASSERT( query.indexA < 3 );

	b3Vec3 cA = triangleCenter;
	b3Vec3 pA = trianglePoint;
	b3Vec3 eA = triangleEdge;

	const b3HullHalfEdge* edgesB = b3GetHullEdges( hull );
	const b3Vec3* pointsB = b3GetHullPoints( hull );
	const b3HullHalfEdge* edgeB = edgesB + query.indexB;
	const b3HullHalfEdge* twinB = edgesB + edgeB->twin;
	b3Vec3 pB = pointsB[edgeB->origin];
	b3Vec3 qB = pointsB[twinB->origin];
	b3Vec3 eB = b3Sub( qB, pB );

	b3Vec3 normal = b3Cross( eA, eB );
	normal = b3Normalize( normal );

	// Ensure normal points outward from triangle center
	float outwardA = b3Dot( normal, b3Sub( pA, cA ) );

	// Ensure normal points towards hull center
	float outwardB = b3Dot( normal, b3Sub( hull->center, pB ) );

	// Use the largest magnitude. The triangle outward value
	// may be unreliable as some angles.
	if ( b3AbsFloat( outwardA ) > b3AbsFloat( outwardB ) )
	{
		if ( outwardA < 0.0f )
		{
			normal = b3Neg( normal );
		}
	}
	else
	{
		if ( outwardB < 0.0f )
		{
			normal = b3Neg( normal );
		}
	}

	// Get the closest points between the infinite edge lines
	b3SegmentDistanceResult result = b3LineDistance( pA, eA, pB, eB );

	// Is one of the closest points outside of the associated edge segment?
	if ( capacity == 0 || result.fraction1 < 0.0f || 1.0f < result.fraction1 || result.fraction2 < 0.0f ||
		 1.0f < result.fraction2 )
	{
		// Invalid edge pair, no points generated
		B3_ASSERT( manifold->pointCount == 0 );
		*cache = (b3SATCache){ 0 };
		return;
	}

	// This can slide off the end from caching
	float separation = b3Dot( normal, b3Sub( result.point2, result.point1 ) );
	B3_VALIDATE( b3AbsFloat( separation - query.separation ) < B3_LINEAR_SLOP );

	b3Vec3 point = b3MulSV( 0.5f, b3Add( result.point1, result.point2 ) );

	b3LocalManifoldPoint* pt = manifold->points + 0;
	pt->point = point;
	pt->separation = separation;
	pt->pair = b3MakeFeaturePair( b3_featureShapeA, query.indexA, b3_featureShapeB, query.indexB );

	// Save cache
	cache->separation = separation;
	cache->type = b3_edgePairAxis;
	cache->indexA = (uint8_t)query.indexA;
	cache->indexB = (uint8_t)query.indexB;

	manifold->normal = normal;
	manifold->pointCount = 1;

	b3TriangleFeature edgesFeatures[] = { b3_featureEdge1, b3_featureEdge2, b3_featureEdge3 };
	manifold->feature = edgesFeatures[query.indexA];
}

// See "Collision Detection of Convex Polyhedra Based on Duality Transformation"
// Simplified for triangle versus hull
static inline bool b3IsTriangleMinkowskiFace( b3Vec3 triNormal, b3Vec3 triEdge, b3Vec3 hullNormal1, b3Vec3 hullNormal2,
											  b3Vec3 hullEdge )
{
	float cab = b3Dot( hullNormal1, triEdge );
	float dab = b3Dot( hullNormal2, triEdge );
	float bcd = b3Dot( triNormal, hullEdge );
	return cab * dab < 0.0f && cab * bcd > 0.0f;
}

b3AtomicInt b3_triangleConvexCalls;
b3AtomicInt b3_triangleCacheHits;

// Computes the manifold in the local space of the hull
void b3CollideHullAndTriangle( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, b3Vec3 v1, b3Vec3 v2, b3Vec3 v3,
							   int triangleFlags, b3SATCache* cache, bool enableSpeculative )
{
	manifold->pointCount = 0;
	manifold->feature = b3_featureNone;

	if ( capacity < 4 )
	{
		return;
	}

	b3Plane trianglePlane = b3MakePlaneFromPoints( v1, v2, v3 );
	float linearSlop = B3_LINEAR_SLOP;

	float offset = b3PlaneSeparation( trianglePlane, hullA->center );
	if ( cache->type == b3_backsideAxis )
	{
		// Use hysteresis to avoid jitter on wavy meshes
		if ( b3AbsFloat( cache->separation - offset ) < linearSlop )
		{
			return;
		}

		cache->type = b3_invalidAxis;
	}

	if ( offset < -linearSlop )
	{
		// Cull back side collision. Cache offset to add hysteresis.
		cache->type = b3_backsideAxis;
		cache->separation = offset;
		return;
	}

	b3Vec3 triangleCenter = b3MulSV( 1.0f / 3.0f, b3Add( v1, b3Add( v2, v3 ) ) );
	b3Vec3 trianglePoints[] = { v1, v2, v3 };
	b3Vec3 triangleEdges[] = { b3Sub( v2, v1 ), b3Sub( v3, v2 ), b3Sub( v1, v3 ) };

	b3TriangleData triangle = {
		.v1 = v1,
		.v2 = v2,
		.v3 = v3,
		.e1 = triangleEdges[0],
		.e2 = triangleEdges[1],
		.e3 = triangleEdges[2],
		.center = triangleCenter,
		.plane = trianglePlane,
		.flags = triangleFlags,
	};

	const b3HullHalfEdge* edges = b3GetHullEdges( hullA );
	const b3Plane* hullPlanes = b3GetHullPlanes( hullA );
	const b3Vec3* hullPoints = b3GetHullPoints( hullA );

	float speculativeDistance = enableSpeculative ? B3_SPECULATIVE_DISTANCE : 0.0f;
	cache->hit = 1;

	// Attempt to use the cache to speed up collision
	switch ( cache->type )
	{
		case b3_faceAxisA:
		{
			B3_ASSERT( cache->indexA == 0 );

			int vertexIndex = b3FindHullSupportVertex( hullA, b3Neg( trianglePlane.normal ) );
			b3Vec3 support = hullPoints[vertexIndex];
			float separation = b3PlaneSeparation( trianglePlane, support );
			if ( separation > speculativeDistance )
			{
				// Cache hit, shapes are separated
				return;
			}

			b3FaceQuery faceQuery;
			faceQuery.separation = separation;
			faceQuery.faceIndex = cache->indexA;
			faceQuery.vertexIndex = vertexIndex;

			// Read cache but don't modify it
			b3SATCache localCache = *cache;
			float clippedSeparation =
				b3CollideTriangleFace( manifold, capacity, &triangle, hullA, faceQuery, &localCache, enableSpeculative );

			if ( manifold->pointCount > 0 && b3AbsFloat( cache->separation - clippedSeparation ) < linearSlop )
			{
				// Cache hit, contact points generated
				return;
			}

			// Invalidate cache and fall through
			manifold->pointCount = 0;
			*cache = (b3SATCache){ 0 };
		}
		break;

		case b3_faceAxisB:
		{
			B3_ASSERT( cache->indexB < hullA->faceCount );

			b3Plane plane = hullPlanes[cache->indexB];

			// Get triangle support point
			int vertexIndex = 0;
			float distance = -b3Dot( v1, plane.normal );
			for ( int i = 1; i < 3; ++i )
			{
				float d = -b3Dot( trianglePoints[i], plane.normal );
				if ( d > distance )
				{
					distance = d;
					vertexIndex = i;
				}
			}

			b3Vec3 support = trianglePoints[vertexIndex];

			// Separation of triangle support point with hull plane
			float separation = b3PlaneSeparation( plane, support );
			if ( separation > speculativeDistance )
			{
				// Cache hit, shapes are separated
				return;
			}

			// Deep overlap may lead to an invalid cache
			// todo confirm
			bool isDeep = separation < -2.0f * linearSlop;

			// Don't persist deep cache or allow separation to change too much
			if ( isDeep == false )
			{
				//  Try to rebuild contact from last features
				b3FaceQuery faceQuery;
				faceQuery.separation = separation;
				faceQuery.faceIndex = cache->indexB;
				faceQuery.vertexIndex = vertexIndex;

				// Read cache but don't modify it
				b3SATCache localCache = *cache;
				float clippedSeparation =
					b3CollideHullFace( manifold, capacity, &triangle, hullA, faceQuery, &localCache, enableSpeculative );

				// Cache reuse is only successful if it creates contact points and the clipped separation didn't change much.
				if ( manifold->pointCount > 0 && b3AbsFloat( cache->separation - clippedSeparation ) < linearSlop )
				{
					// Cache hit, contact points generated
					return;
				}
			}

			// Invalidate cache and fall through
			manifold->pointCount = 0;
			*cache = (b3SATCache){ 0 };
		}
		break;

		case b3_edgePairAxis:
		{
			B3_ASSERT( cache->indexA < 3 );
			int indexA = cache->indexA;

			b3Vec3 triPoint = trianglePoints[indexA];
			b3Vec3 triEdge = triangleEdges[indexA];

			B3_ASSERT( cache->indexB < hullA->edgeCount - 1 );
			int indexB = cache->indexB;

			const b3HullHalfEdge* edge2 = edges + indexB;
			const b3HullHalfEdge* twin2 = edges + indexB + 1;
			B3_ASSERT( edge2->twin == indexB + 1 && twin2->twin == indexB );

			b3Vec3 hullPoint = hullPoints[edge2->origin];
			b3Vec3 hullEdge = b3Sub( hullPoints[twin2->origin], hullPoint );
			b3Vec3 hullNormal1 = hullPlanes[edge2->face].normal;
			b3Vec3 hullNormal2 = hullPlanes[twin2->face].normal;

			// Confirm the edge pair is still a Minkowski face
			bool isMinkowski = b3IsTriangleMinkowskiFace( trianglePlane.normal, triEdge, hullNormal1, hullNormal2, hullEdge );
			if ( isMinkowski )
			{
				// Transform reference center of the first hull into local space of the second hull
				float separation = b3EdgeEdgeSeparation( triPoint, triEdge, triangleCenter, hullPoint, hullEdge, hullA->center );
				if ( separation > speculativeDistance )
				{
					// Cache hit, shapes are separated
					return;
				}

				if ( b3AbsFloat( cache->separation - separation ) < linearSlop )
				{
					// Try to rebuild contact from last features
					b3EdgeQuery edgeQuery;
					edgeQuery.indexA = indexA;
					edgeQuery.indexB = indexB;
					edgeQuery.separation = separation;

					// Read cache but don't modify it
					b3SATCache localCache = *cache;
					b3CollideHullAndTriangleEdges( manifold, capacity, triPoint, triEdge, triangleCenter, hullA, edgeQuery,
												   &localCache );

					if ( manifold->pointCount > 0 )
					{
						// Cache hit, contact point generated
						return;
					}
				}
			}

			// Invalidate cache and fall through
			*cache = (b3SATCache){ 0 };
		}
		break;

			// This case is for testing
		case b3_manualFaceAxisA:
		{
			b3FaceQuery faceQueryA = b3QueryTriangleFace( &triangle, hullA );
			b3CollideTriangleFace( manifold, capacity, &triangle, hullA, faceQueryA, cache, enableSpeculative );
			return;
		}

			// This case is for testing
		case b3_manualFaceAxisB:
		{
			b3FaceQuery faceQueryB = b3QueryHullFace( &triangle, hullA );
			b3CollideHullFace( manifold, capacity, &triangle, hullA, faceQueryB, cache, enableSpeculative );
			return;
		}

			// This case is for testing
		case b3_manualEdgePairAxis:
		{
			b3EdgeQuery edgeQuery = b3TestEdgePairs( &triangle, hullA );
			if ( edgeQuery.indexA != B3_NULL_INDEX )
			{
				b3Vec3 trianglePoint = trianglePoints[edgeQuery.indexA];
				b3Vec3 triangleEdge = triangleEdges[edgeQuery.indexA];
				b3CollideHullAndTriangleEdges( manifold, capacity, trianglePoint, triangleEdge, triangleCenter, hullA, edgeQuery,
											   cache );
			}
			return;
		}

		default:
			B3_ASSERT( cache->type == b3_invalidAxis );
			break;
	}

	// Cache miss
	cache->hit = 0;

	// Find axis of minimum penetration
	b3FaceQuery faceQueryA = b3QueryTriangleFace( &triangle, hullA );
	if ( faceQueryA.separation > speculativeDistance )
	{
		// Separating axis found
		cache->separation = faceQueryA.separation;
		cache->type = b3_faceAxisA;
		cache->indexA = 0;
		cache->indexB = UINT8_MAX;
		return;
	}

	b3FaceQuery faceQueryB = b3QueryHullFace( &triangle, hullA );
	if ( faceQueryB.separation > speculativeDistance )
	{
		// Separating axis found
		cache->separation = faceQueryB.separation;
		cache->type = b3_faceAxisB;
		cache->indexA = UINT8_MAX;
		cache->indexB = (uint8_t)faceQueryB.faceIndex;
		return;
	}

	b3EdgeQuery edgeQuery = b3TestEdgePairs( &triangle, hullA );
	if ( edgeQuery.separation > speculativeDistance )
	{
		// Separating axis found
		cache->separation = edgeQuery.separation;
		cache->type = b3_edgePairAxis;
		cache->indexA = (uint8_t)edgeQuery.indexA;
		cache->indexB = (uint8_t)edgeQuery.indexB;
		return;
	}

	float clippedFaceSeparation;

	// Don't admit a hull face significantly opposed to the triangle face.
	// Need a tolerance to avoid ghost collisions.
	// todo hull query skips faces that point along the triangle normal
	b3Vec3 hullNormal = hullPlanes[faceQueryB.faceIndex].normal;
	bool pushingDown = b3Dot( hullNormal, trianglePlane.normal ) > 0.25f;
	if ( faceQueryB.separation > faceQueryA.separation + linearSlop && pushingDown == false )
	{
		clippedFaceSeparation = b3CollideHullFace( manifold, capacity, &triangle, hullA, faceQueryB, cache, enableSpeculative );
	}
	else
	{
		clippedFaceSeparation =
			b3CollideTriangleFace( manifold, capacity, &triangle, hullA, faceQueryA, cache, enableSpeculative );
	}

	// Does an edge axis exist?
	if ( edgeQuery.indexA != B3_NULL_INDEX )
	{
		// When axes are aligned the edge separation can be garbage.
		// If a face axis has positive separation there may be no points.
		float maxFaceSeparation = b3MaxFloat( faceQueryA.separation, faceQueryB.separation );

		if ( ( manifold->pointCount == 0 && edgeQuery.separation > maxFaceSeparation ) ||
			 ( manifold->pointCount == 1 && edgeQuery.separation > clippedFaceSeparation + linearSlop ) )
		{
			B3_ASSERT( 0 <= edgeQuery.indexA && edgeQuery.indexA < 3 );
			b3Vec3 trianglePoint = trianglePoints[edgeQuery.indexA];
			b3Vec3 triangleEdge = triangleEdges[edgeQuery.indexA];
			manifold->pointCount = 0;
			b3CollideHullAndTriangleEdges( manifold, capacity, trianglePoint, triangleEdge, triangleCenter, hullA, edgeQuery,
										   cache );
		}
	}

	// Using the speculative distance means that sometimes there are no valid contact points from SAT.
	// In this fall back to GJK. This is important to prevent tunneling in rare cases.
	if ( manifold->pointCount == 0 )
	{
		b3Vec3 triangleB[] = { v1, v2, v3 };
		b3DistanceInput input = { 0 };
		input.proxyA = (b3ShapeProxy){
			.points = triangleB,
			.count = 3,
			.radius = 0.0f,
		};
		input.proxyB = (b3ShapeProxy){ .points = hullPoints, .count = hullA->vertexCount, .radius = 0.0f };
		input.transform = b3Transform_identity;
		input.useRadii = false;

		b3SimplexCache simplexCache = { 0 };
		b3DistanceOutput output = b3ShapeDistance( &input, &simplexCache, NULL, 0 );

		if ( output.distance > 0.0f )
		{
			B3_ASSERT( 0 < simplexCache.count && simplexCache.count <= 3 );

			manifold->pointCount = 1;
			manifold->feature = b3GetTriangleFeature( &simplexCache );
			manifold->normal = output.normal;
			manifold->points[0].point = output.pointB;
			manifold->points[0].separation = output.distance;

			// This feature pair not accurate but maybe it doesn't matter
			manifold->points[0].pair = b3FeaturePair_single;
		}
	}
}
