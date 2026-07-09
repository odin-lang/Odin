// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "manifold.h"

#include "algorithm.h"
#include "shape.h"

#include "box3d/math_functions.h"

// p1 : origin on edge 1
// e1 : edge 1
// c1 : shape 1 centroid
// p2 : origin on edge 2
// e2 : edge 2
// c2 : shape 2 centroid
float b3EdgeEdgeSeparation( b3Vec3 p1, b3Vec3 e1, b3Vec3 c1, b3Vec3 p2, b3Vec3 e2, b3Vec3 c2 )
{
	// Build search direction
	b3Vec3 u = b3Cross( e1, e2 );
	float length = b3Length( u );

	// Skip near parallel edges: |e1 x e1| = sin(alpha) * |e1| * |e2|
	const float kTolerance = 0.005f;
	if ( length < kTolerance * sqrtf( b3LengthSquared( e1 ) * b3LengthSquared( e2 ) ) )
	{
		return -FLT_MAX;
	}

	if ( length * length < 1000.0f * FLT_MIN )
	{
		return -FLT_MAX;
	}

	b3Vec3 n = b3MulSV( 1.0f / length, u );

	// Make sure normal points away from the first shape
	// For a triangle, it is possible that N is aligned with the triangle normal and the sign
	// value can be close to zero and flicker between small negative and positive values, leading to
	// an incorrect separation value. So we assume the other hull has some volume and pick the most
	// significant sign value to orient N.
	float sign1 = b3Dot( n, b3Sub( p1, c1 ) );
	float sign2 = b3Dot( n, b3Sub( p2, c2 ) );
	if ( b3AbsFloat( sign1 ) > b3AbsFloat( sign2 ) )
	{
		if ( sign1 < 0.0f )
		{
			n = b3Neg( n );
		}
	}
	else
	{
		if ( sign2 > 0.0f )
		{
			n = b3Neg( n );
		}
	}

	// s = Dot(n, p2) - d = Dot(n, p2) - Dot(n, p1) = Dot(n, p2 - p1)
	return b3Dot( n, b3Sub( p2, p1 ) );
}

// This was extended to make the wedge shape get the correct incident face.
// Instead of looking directly for the most anti-parallel face, we first find the closest vertex (passed in).
// Then we look for all edges coming out of that vertex and look for the edge that is
// most perpendicular to the reference normal.
// Then from that edge, we select the adjacent face that is most anti-parallel to the reference normal.
int b3FindIncidentFace( const b3HullData* hull, b3Vec3 refNormal, int vertexIndex )
{
	const b3HullVertex* vertices = b3GetHullVertices( hull );
	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	const b3Plane* planes = b3GetHullPlanes( hull );
	const b3Vec3* points = b3GetHullPoints( hull );

	int minEdgeIndex = -1;
	float minEdgeProjection = FLT_MAX;

	const b3HullVertex* vertex = vertices + vertexIndex;
	B3_ASSERT( vertex );

	int edgeIndex = vertex->edge;
	const b3HullHalfEdge* edge = edges + edgeIndex;
	b3Vec3 edgeOrigin = points[edge->origin];
	B3_ASSERT( edge->origin == vertexIndex );

	do
	{
		const b3HullHalfEdge* twin = edges + edge->twin;
		b3Vec3 twinOrigin = points[twin->origin];

		b3Vec3 axis = b3Normalize( b3Sub( twinOrigin, edgeOrigin ) );
		float edgeProjection = b3AbsFloat( b3Dot( axis, refNormal ) );
		if ( edgeProjection < minEdgeProjection )
		{
			minEdgeIndex = edgeIndex;
			minEdgeProjection = edgeProjection;
		}

		edgeIndex = twin->next;
		edge = edges + edgeIndex;
		B3_ASSERT( edge->origin == vertexIndex );
	}
	while ( edge != edges + vertex->edge );
	B3_ASSERT( minEdgeIndex >= 0 );

	const b3HullHalfEdge* minEdge = edges + minEdgeIndex;
	int minFaceIndex1 = minEdge->face;
	b3Plane minPlane1 = planes[minFaceIndex1];

	const b3HullHalfEdge* minTwin = edges + minEdge->twin;
	int minFaceIndex2 = minTwin->face;
	b3Plane minPlane2 = planes[minFaceIndex2];

	return b3Dot( minPlane1.normal, refNormal ) < b3Dot( minPlane2.normal, refNormal ) ? minFaceIndex1 : minFaceIndex2;
}

b3FeaturePair b3MakeFeaturePair( b3FeatureOwner owner1, int index1, b3FeatureOwner owner2, int index2 )
{
	B3_ASSERT( 0 <= index1 && index1 <= UINT8_MAX );
	B3_ASSERT( 0 <= index2 && index2 <= UINT8_MAX );

	b3FeaturePair pair;
	pair.index1 = (uint8_t)index1;
	pair.owner1 = (uint8_t)owner1;
	pair.index2 = (uint8_t)index2;
	pair.owner2 = (uint8_t)owner2;
	return pair;
}

// This logic seems wrong but it is designed so that choosing
// face A or B as the reference face does not change the resulting
// feature pair. This way the contact impulses are persisted even
// if there is reference face flip-flop. This is verified in the
// HullAndHull sample using the b3SATCache with a manual feature
// specified such as b3_manualFaceAxisA.
b3FeaturePair b3FlipPair( b3FeaturePair pair )
{
	B3_ASSERT( pair.owner1 == 0 || pair.owner1 == 1 );
	B3_ASSERT( pair.owner2 == 0 || pair.owner2 == 1 );
	B3_SWAP( pair.owner1, pair.owner2 );
	pair.owner1 = 1 - pair.owner1;
	pair.owner2 = 1 - pair.owner2;
	B3_SWAP( pair.index1, pair.index2 );
	return pair;
}

#if B3_ENABLE_VALIDATION
bool b3ValidatePolygon( b3ClipVertex* polygon, int count )
{
	// Empty polygons are valid (we can clip away all points when re-constructing manifolds from cache)
	if ( count == 0 )
	{
		return true;
	}

	// Validate that incoming and outgoing edges match
	b3ClipVertex vertex1 = polygon[count - 1];
	for ( int i = 0; i < count; ++i )
	{
		b3ClipVertex vertex2 = polygon[i];

		if ( vertex1.pair.owner2 != vertex2.pair.owner1 )
		{
			return false;
		}

		if ( vertex1.pair.index2 != vertex2.pair.index1 )
		{
			return false;
		}

		vertex1 = vertex2;
	}

	return true;
}
#endif

int b3ClipPolygon( b3ClipVertex* out, b3ClipVertex* polygon, int count, b3Plane clipPlane, int edge, b3Plane refPlane )
{
	B3_ASSERT( count >= 3 );

	b3ClipVertex vertex1 = polygon[count - 1];
	float distance1 = b3PlaneSeparation( clipPlane, vertex1.position );
	int outCount = 0;

	for ( int index = 0; index < count; ++index )
	{
		b3ClipVertex vertex2 = polygon[index];
		float distance2 = b3PlaneSeparation( clipPlane, vertex2.position );

		// Clip edge against plane (Sutherland-Hodgman clipping)
		if ( distance1 <= 0.0f && distance2 <= 0.0f )
		{
			// Both vertices are behind the plane - keep vertex2
			out[outCount] = vertex2;
			outCount += 1;
		}
		else if ( distance1 <= 0.0f && distance2 > 0.0f )
		{
			// Vertex1 is behind of the plane, vertex2 is in front -> intersection point
			float fraction = distance1 / ( distance1 - distance2 );
			b3Vec3 position = b3MulAdd( vertex1.position, fraction, b3Sub( vertex2.position, vertex1.position ) );

			// Keep intersection point and adjust outgoing edge
			b3ClipVertex vertex;
			vertex.position = position;
			vertex.separation = b3PlaneSeparation( refPlane, position );
			vertex.pair = vertex2.pair;
			vertex.pair.owner2 = b3_featureShapeA;
			vertex.pair.index2 = (uint8_t)edge;
			out[outCount] = vertex;
			outCount += 1;
		}
		else if ( distance2 <= 0.0f && distance1 > 0.0f )
		{
			// Vertex1 is in front, vertex2 is behind of the plane, -> intersection point
			float fraction = distance1 / ( distance1 - distance2 );
			b3Vec3 position = b3MulAdd( vertex1.position, fraction, b3Sub( vertex2.position, vertex1.position ) );

			// Keep intersection point and adjust incoming edge
			b3ClipVertex vertex;
			vertex.position = position;
			vertex.separation = b3PlaneSeparation( refPlane, position );
			vertex.pair = vertex1.pair;
			vertex.pair.owner1 = b3_featureShapeA;
			vertex.pair.index1 = (uint8_t)edge;
			out[outCount] = vertex;
			outCount += 1;

			// And also keep vertex2
			out[outCount] = vertex2;
			outCount += 1;
		}

		// Keep vertex2 as starting vertex for next edge
		vertex1 = vertex2;
		distance1 = distance2;
	}

	B3_VALIDATE( b3ValidatePolygon( out, outCount ) );

	return outCount;
}
