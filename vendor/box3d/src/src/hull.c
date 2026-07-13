// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "algorithm.h"
#include "hull_map.h"
#include "math_internal.h"
#include "shape.h"

#include "box3d/collision.h"
#include "box3d/constants.h"
#include "box3d/math_functions.h"

#include <float.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define B3_AXIS_X 0
#define B3_AXIS_Y 1
#define B3_AXIS_Z 2

#define B3_MARK_VISIBLE 0
#define B3_MARK_DELETE 1

// Final hull is index-encoded with uint8_t, so vertex/edge/face counts are capped at UINT8_MAX.
#define B3_HULL_LIMIT UINT8_MAX

typedef struct b3QHListNode
{
	struct b3QHListNode* prev;
	struct b3QHListNode* next;
} b3QHListNode;

typedef struct b3QHFace b3QHFace;

typedef struct b3QHVertex
{
	// Intrusive list link. Must be first so (b3QHVertex*)nodePtr is valid.
	b3QHListNode link;

	b3QHFace* conflictFace;
	b3Vec3 position;

	// Index in the finalized hull, stamped during emit. B3_NULL_INDEX until then.
	int finalIndex;
	bool reachable;
} b3QHVertex;

typedef struct b3QHHalfEdge
{
	// Edge ring (CCW) around the owning face. Not an external list.
	struct b3QHHalfEdge* prev;
	struct b3QHHalfEdge* next;

	b3QHVertex* origin;
	b3QHFace* face;
	struct b3QHHalfEdge* twin;

	// Index in the finalized hull, stamped during emit. B3_NULL_INDEX until then.
	int finalIndex;
} b3QHHalfEdge;

struct b3QHFace
{
	// Intrusive list link. Must be first so (b3QHFace*)nodePtr is valid.
	b3QHListNode link;

	b3QHHalfEdge* edge;

	int mark;
	float area;
	b3Plane plane;
	b3Vec3 centroid;
	float maxConflictDistance;

	// Sentinel head for this face's conflict list of b3QHVertex.
	b3QHVertex conflictListHead;

	// Cached farthest conflict vertex (above b3HullBuilder::minOutside).
	// NULL when no conflict above threshold; maxConflictDistance is then minOutside.
	b3QHVertex* maxConflict;

	// Index in the finalized hull, stamped during emit. B3_NULL_INDEX until then.
	int finalIndex;
	bool flipped;
};

// One frame of the iterative horizon DFS. Replaces a recursive call to b3HullBuilder_BuildHorizon.
typedef struct b3HorizonFrame
{
	b3QHFace* face;
	b3QHHalfEdge* startEdge; // ring termination sentinel
	b3QHHalfEdge* edge;		 // next edge to process
	bool started;			 // false until the first edge of this ring has been processed
} b3HorizonFrame;

// All working memory for one hull build, carved from a single b3Alloc block.
typedef struct b3HullBuilder
{
	float tolerance;
	float minRadius;
	float minOutside;

	b3Vec3 interiorPoint;

	// List sentinels. Only the link is meaningful; other fields are unused.
	b3QHVertex orphanedList;
	b3QHVertex vertexList;
	b3QHFace faceList;

	// Bump-allocated pools with pointer-based free lists for faces and edges.
	b3QHVertex* vertexBase;
	int vertexCapacity;
	int vertexCount;

	b3QHHalfEdge* edgeBase;
	int edgeCapacity;
	int edgeCount;
	b3QHHalfEdge* edgeFreeHead; // LIFO free list; overlays edge->next

	b3QHFace* faceBase;
	int faceCapacity;
	int faceCount;
	b3QHFace* faceFreeHead; // LIFO free list; overlays face->link.next

	// Reusable scratch buffers.
	b3QHHalfEdge** horizon;
	int horizonCapacity;
	int horizonCount;

	b3QHFace** cone;
	int coneCapacity;
	int coneCount;

	b3QHFace** mergedFaces;
	int mergedFacesCapacity;
	int mergedFacesCount;

	// DFS stack used by the iterative b3HullBuilder_BuildHorizon. Depth bounded by live faces.
	b3HorizonFrame* horizonStack;
	int horizonStackCapacity;

	// Final counts of the constructed hull (vertexList / faceList / half-edges around faces).
	// Populated by CleanHull; zero until then.
	int finalVertexCount;
	int finalHalfEdgeCount;
	int finalFaceCount;
} b3HullBuilder;

static inline void b3QHList_Init( b3QHListNode* head )
{
	head->prev = head;
	head->next = head;
}

#define B3_LIST_EMPTY( A ) ( ( A )->next == ( A ) )

static inline bool b3QHList_Contains( const b3QHListNode* node )
{
	return node->prev != NULL && node->next != NULL;
}

// Insert node before `where`.
static inline void b3QHList_Insert( b3QHListNode* node, b3QHListNode* where )
{
	B3_ASSERT( !b3QHList_Contains( node ) && b3QHList_Contains( where ) );

	node->prev = where->prev;
	node->next = where;

	node->prev->next = node;
	node->next->prev = node;
}

static inline void b3QHList_Remove( b3QHListNode* node )
{
	B3_ASSERT( b3QHList_Contains( node ) );

	node->prev->next = node->next;
	node->next->prev = node->prev;

	node->prev = NULL;
	node->next = NULL;
}

static inline void b3QHList_PushBack( b3QHListNode* head, b3QHListNode* node )
{
	b3QHList_Insert( node, head->prev );
}

static b3QHVertex* b3HullBuilder_NewVertex( b3HullBuilder* b, b3Vec3 position )
{
	B3_ASSERT( b->vertexCount < b->vertexCapacity );
	b3QHVertex* vertex = b->vertexBase + b->vertexCount++;

	vertex->link.prev = NULL;
	vertex->link.next = NULL;
	vertex->conflictFace = NULL;
	vertex->position = position;
	vertex->finalIndex = B3_NULL_INDEX;
	vertex->reachable = false;

	return vertex;
}

static b3QHHalfEdge* b3HullBuilder_NewEdge( b3HullBuilder* b )
{
	b3QHHalfEdge* edge;
	if ( b->edgeFreeHead != NULL )
	{
		edge = b->edgeFreeHead;
		b->edgeFreeHead = edge->next;
	}
	else
	{
		B3_ASSERT( b->edgeCount < b->edgeCapacity );
		edge = b->edgeBase + b->edgeCount++;
	}
	// All other fields (prev/next/origin/face/twin) are written by NewFace immediately after.
	edge->finalIndex = B3_NULL_INDEX;
	return edge;
}

static void b3HullBuilder_RetireEdge( b3HullBuilder* b, b3QHHalfEdge* edge )
{
	edge->next = b->edgeFreeHead;
	b->edgeFreeHead = edge;
}

static b3QHFace* b3HullBuilder_NewFace( b3HullBuilder* b, b3QHVertex* v1, b3QHVertex* v2, b3QHVertex* v3 )
{
	b3QHFace* face;
	if ( b->faceFreeHead != NULL )
	{
		face = b->faceFreeHead;
		// link.next was used as free-list pointer; recover next head before we clobber.
		b->faceFreeHead = (b3QHFace*)face->link.next;
	}
	else
	{
		B3_ASSERT( b->faceCount < b->faceCapacity );
		face = b->faceBase + b->faceCount++;
	}

	// link.prev: NULL on retired faces (cleared by Remove); NULL here so PushBack's
	// !b3QHList_Contains assert holds for fresh bump slots too.
	// link.next: was the free-list pointer on reused slots, now stale; PushBack overwrites.
	face->link.prev = NULL;
	face->link.next = NULL;
	face->maxConflict = NULL;
	face->maxConflictDistance = 0.0f;
	face->finalIndex = B3_NULL_INDEX;

	b3QHHalfEdge* edge1 = b3HullBuilder_NewEdge( b );
	b3QHHalfEdge* edge2 = b3HullBuilder_NewEdge( b );
	b3QHHalfEdge* edge3 = b3HullBuilder_NewEdge( b );

	b3Vec3 p1 = v1->position;
	b3Vec3 p2 = v2->position;
	b3Vec3 p3 = v3->position;

	b3Plane plane;
	plane.normal = b3Cross( b3Sub( p2, p1 ), b3Sub( p3, p1 ) );
	float length;
	plane.normal = b3GetLengthAndNormalize( &length, plane.normal );
	plane.offset = b3Dot( plane.normal, p1 );

	float area = 0.5f * length;

	face->edge = edge1;
	face->mark = B3_MARK_VISIBLE;
	face->area = area;
	face->centroid = b3MulSV( 1.0f / 3.0f, b3Add( v1->position, b3Add( v2->position, v3->position ) ) );
	face->plane = plane;
	face->flipped = b3PlaneSeparation( plane, b->interiorPoint ) > 0.0f;
	b3QHList_Init( &face->conflictListHead.link );

	edge1->prev = edge3;
	edge1->next = edge2;
	edge1->origin = v1;
	edge1->face = face;
	edge1->twin = NULL;

	edge2->prev = edge1;
	edge2->next = edge3;
	edge2->origin = v2;
	edge2->face = face;
	edge2->twin = NULL;

	edge3->prev = edge2;
	edge3->next = edge1;
	edge3->origin = v3;
	edge3->face = face;
	edge3->twin = NULL;

	return face;
}

// Remove face from faceList if still linked, clear its edge pointer, then push onto faceFreeHead.
// Uses face->link.next as the free-list next pointer (link.prev stays NULL, so b3QHList_Contains
// returns false on a free slot, as required by the retire-guard in ResolveFaces).
static void b3HullBuilder_RetireFace( b3HullBuilder* b, b3QHFace* face )
{
	if ( b3QHList_Contains( &face->link ) )
	{
		b3QHList_Remove( &face->link );
	}
	face->edge = NULL;
	// link.prev is already NULL after Remove (or was never set). link.next holds free-list ptr.
	face->link.next = (b3QHListNode*)b->faceFreeHead;
	b->faceFreeHead = face;
}

static b3AABB b3BuildBounds( int vertexCount, const b3Vec3* vertices )
{
	b3AABB bounds = B3_BOUNDS3_EMPTY;
	for ( int i = 0; i < vertexCount; ++i )
	{
		bounds.lowerBound = b3Min( bounds.lowerBound, vertices[i] );
		bounds.upperBound = b3Max( bounds.upperBound, vertices[i] );
	}
	return bounds;
}

static void b3FindFarthestPointsAlongCardinalAxes( int* index1Out, int* index2Out, float tolerance, int vertexCount,
												   const b3Vec3* vertexBase )
{
	*index1Out = B3_NULL_INDEX;
	*index2Out = B3_NULL_INDEX;

	b3Vec3 v0 = vertexBase[0];
	b3Vec3 minPt[3] = { v0, v0, v0 };
	b3Vec3 maxPt[3] = { v0, v0, v0 };

	int minIndex[3] = { 0, 0, 0 };
	int maxIndex[3] = { 0, 0, 0 };

	for ( int i = 1; i < vertexCount; ++i )
	{
		b3Vec3 v = vertexBase[i];

		if ( v.x < minPt[B3_AXIS_X].x )
		{
			minPt[B3_AXIS_X] = v;
			minIndex[B3_AXIS_X] = i;
		}
		else if ( v.x > maxPt[B3_AXIS_X].x )
		{
			maxPt[B3_AXIS_X] = v;
			maxIndex[B3_AXIS_X] = i;
		}

		if ( v.y < minPt[B3_AXIS_Y].y )
		{
			minPt[B3_AXIS_Y] = v;
			minIndex[B3_AXIS_Y] = i;
		}
		else if ( v.y > maxPt[B3_AXIS_Y].y )
		{
			maxPt[B3_AXIS_Y] = v;
			maxIndex[B3_AXIS_Y] = i;
		}

		if ( v.z < minPt[B3_AXIS_Z].z )
		{
			minPt[B3_AXIS_Z] = v;
			minIndex[B3_AXIS_Z] = i;
		}
		else if ( v.z > maxPt[B3_AXIS_Z].z )
		{
			maxPt[B3_AXIS_Z] = v;
			maxIndex[B3_AXIS_Z] = i;
		}
	}

	b3Vec3 distance;
	distance.x = maxPt[B3_AXIS_X].x - minPt[B3_AXIS_X].x;
	distance.y = maxPt[B3_AXIS_Y].y - minPt[B3_AXIS_Y].y;
	distance.z = maxPt[B3_AXIS_Z].z - minPt[B3_AXIS_Z].z;

	float distanceArray[3] = { distance.x, distance.y, distance.z };
	int maxElement = b3MaxElementIndex( distance );

	if ( distanceArray[maxElement] > 2.0f * tolerance )
	{
		*index1Out = minIndex[maxElement];
		*index2Out = maxIndex[maxElement];
	}
}

static int b3FindFarthestPointFromLine( int index1, int index2, float tolerance, int vertexCount, const b3Vec3* vertexBase )
{
	b3Vec3 a = vertexBase[index1];
	b3Vec3 b = vertexBase[index2];

	// |ap x ab|^2 / |ab|^2 is the squared perpendicular distance from p to the line.
	// Compares against (2 * tolerance)^2
	b3Vec3 ab = b3Sub( b, a );
	float abLengthSqr = b3Dot( ab, ab );
	B3_ASSERT( abLengthSqr > 0.0f );

	float invAbLengthSqr = 1.0f / abLengthSqr;
	float maxDistanceSqr = 4.0f * tolerance * tolerance;
	int maxIndex = B3_NULL_INDEX;

	for ( int i = 0; i < vertexCount; ++i )
	{
		if ( i == index1 || i == index2 )
		{
			continue;
		}

		b3Vec3 ap = b3Sub( vertexBase[i], a );
		b3Vec3 cross = b3Cross( ap, ab );
		float distanceSqr = b3Dot( cross, cross ) * invAbLengthSqr;
		if ( distanceSqr > maxDistanceSqr )
		{
			maxDistanceSqr = distanceSqr;
			maxIndex = i;
		}
	}

	return maxIndex;
}

static int b3FindFarthestPointFromPlane( int index1, int index2, int index3, float tolerance, int vertexCount,
										 const b3Vec3* vertexBase )
{
	b3Vec3 a = vertexBase[index1];
	b3Vec3 b = vertexBase[index2];
	b3Vec3 c = vertexBase[index3];

	b3Plane plane = b3MakePlaneFromPoints( a, b, c );

	float maxDistance = 2.0f * tolerance;
	int maxIndex = B3_NULL_INDEX;

	for ( int i = 0; i < vertexCount; ++i )
	{
		if ( i == index1 || i == index2 || i == index3 )
		{
			continue;
		}

		float distance = b3AbsFloat( b3PlaneSeparation( plane, vertexBase[i] ) );
		if ( distance > maxDistance )
		{
			maxDistance = distance;
			maxIndex = i;
		}
	}

	return maxIndex;
}

static bool b3IsEdgeConvex( const b3QHHalfEdge* edge, float tolerance )
{
	float distance = b3PlaneSeparation( edge->face->plane, edge->twin->face->centroid );
	return distance < -tolerance;
}

static bool b3IsEdgeConcave( const b3QHHalfEdge* edge, float tolerance )
{
	float distance = b3PlaneSeparation( edge->face->plane, edge->twin->face->centroid );
	return distance > tolerance;
}

static int b3VertexCountOfFace( const b3QHFace* face )
{
	int count = 0;
	const b3QHHalfEdge* edge = face->edge;
	do
	{
		count++;
		edge = edge->next;
	}
	while ( edge != face->edge );

	return count;
}

static void b3LinkFace( b3QHFace* face, int index, b3QHHalfEdge* twin )
{
	B3_ASSERT( face != twin->face );

	b3QHHalfEdge* edge = face->edge;
	while ( index-- > 0 )
	{
		B3_ASSERT( edge->face == face );
		edge = edge->next;
	}

	B3_ASSERT( edge != twin );
	edge->twin = twin;
	twin->twin = edge;
}

static void b3LinkFaces( b3QHFace* face1, int index1, b3QHFace* face2, int index2 )
{
	B3_ASSERT( face1 != face2 );

	b3QHHalfEdge* edge1 = face1->edge;
	while ( index1-- > 0 )
	{
		edge1 = edge1->next;
	}

	b3QHHalfEdge* edge2 = face2->edge;
	while ( index2-- > 0 )
	{
		edge2 = edge2->next;
	}

	B3_ASSERT( edge1 != edge2 );
	edge1->twin = edge2;
	edge2->twin = edge1;
}

static void b3NewellPlane( b3QHFace* face )
{
	int count = 0;
	b3Vec3 centroid = b3Vec3_zero;
	b3Vec3 normal = b3Vec3_zero;

	b3QHHalfEdge* edge = face->edge;
	B3_ASSERT( edge->face == face );

	// Use the first vertex as the origin to reduce round-off
	b3Vec3 origin = edge->origin->position;

	do
	{
		b3QHHalfEdge* twin = edge->twin;
		B3_ASSERT( twin->twin == edge );

		b3Vec3 v1 = b3Sub( edge->origin->position, origin );
		b3Vec3 v2 = b3Sub( twin->origin->position, origin );

		count++;
		centroid = b3Add( centroid, v1 );
		normal.x += ( v1.y - v2.y ) * ( v1.z + v2.z );
		normal.y += ( v1.z - v2.z ) * ( v1.x + v2.x );
		normal.z += ( v1.x - v2.x ) * ( v1.y + v2.y );

		edge = edge->next;
	}
	while ( edge != face->edge );

	B3_ASSERT( count > 0 );
	centroid = b3MulSV( 1.0f / (float)count, centroid );
	centroid = b3Add( centroid, origin );

	float length = b3Length( normal );
	B3_VALIDATE( length > 0.0f );
	normal = b3MulSV( 1.0f / length, normal );

	face->centroid = centroid;
	face->plane = b3MakePlaneFromNormalAndPoint( normal, centroid );
	face->area = 0.5f * length;
}

#if B3_DEBUG
static bool b3CheckConsistency( const b3QHFace* face )
{
	if ( face->mark == B3_MARK_DELETE )
	{
		return false;
	}

	if ( b3VertexCountOfFace( face ) < 3 )
	{
		return false;
	}

	const b3QHHalfEdge* edge = face->edge;

	do
	{
		const b3QHHalfEdge* twin = edge->twin;

		if ( twin == NULL )
		{
			return false;
		}
		if ( twin->face == NULL )
		{
			return false;
		}
		if ( twin->face == face )
		{
			return false;
		}
		if ( twin->face->mark == B3_MARK_DELETE )
		{
			return false;
		}
		if ( twin->twin != edge )
		{
			return false;
		}
		if ( edge->next->origin != twin->origin )
		{
			return false;
		}
		if ( edge->origin != twin->next->origin )
		{
			return false;
		}
		if ( edge->face != face )
		{
			return false;
		}

		edge = edge->next;
	}
	while ( edge != face->edge );

	return true;
}
#endif

static void b3HullBuilder_ComputeTolerance( b3HullBuilder* b, int pointCount, const b3Vec3* points )
{
	b3AABB bounds = b3BuildBounds( pointCount, points );
	b3Vec3 maxAbs = b3Max( b3Abs( bounds.lowerBound ), b3Abs( bounds.upperBound ) );

	float maxSum = maxAbs.x + maxAbs.y + maxAbs.z;
	float maxCoord = b3MaxFloat( maxAbs.x, b3MaxFloat( maxAbs.y, maxAbs.z ) );
	float maxDistance = b3MinFloat( B3_SQRT3 * maxCoord, maxSum );

	float tolerance = ( 3.0f * maxDistance * 1.01f + maxCoord ) * FLT_EPSILON;

	b->tolerance = tolerance;
	b->minRadius = 4.0f * b->tolerance;
	b->minOutside = 2.0f * b->minRadius;
	B3_ASSERT( b->minRadius < b->minOutside + 3.0f * FLT_EPSILON );
}

static bool b3HullBuilder_BuildInitialHull( b3HullBuilder* b, int pointCount, const b3Vec3* points )
{
	int index1, index2;
	b3FindFarthestPointsAlongCardinalAxes( &index1, &index2, b->tolerance, pointCount, points );
	if ( index1 < 0 || index2 < 0 )
	{
		return false;
	}

	int index3 = b3FindFarthestPointFromLine( index1, index2, b->tolerance, pointCount, points );
	if ( index3 < 0 )
	{
		return false;
	}

	int index4 = b3FindFarthestPointFromPlane( index1, index2, index3, b->tolerance, pointCount, points );
	if ( index4 < 0 )
	{
		return false;
	}

	b3Vec3 v1 = b3Sub( points[index1], points[index4] );
	b3Vec3 v2 = b3Sub( points[index2], points[index4] );
	b3Vec3 v3 = b3Sub( points[index3], points[index4] );

	if ( b3ScalarTripleProduct( v1, v2, v3 ) < 0.0f )
	{
		int temp = index2;
		index2 = index3;
		index3 = temp;
	}

	b->interiorPoint = b3Vec3_zero;
	b->interiorPoint = b3Add( b->interiorPoint, points[index1] );
	b->interiorPoint = b3Add( b->interiorPoint, points[index2] );
	b->interiorPoint = b3Add( b->interiorPoint, points[index3] );
	b->interiorPoint = b3Add( b->interiorPoint, points[index4] );
	b->interiorPoint = b3MulSV( 0.25f, b->interiorPoint );

	b3QHVertex* vertex1 = b3HullBuilder_NewVertex( b, points[index1] );
	b3QHList_PushBack( &b->vertexList.link, &vertex1->link );
	b3QHVertex* vertex2 = b3HullBuilder_NewVertex( b, points[index2] );
	b3QHList_PushBack( &b->vertexList.link, &vertex2->link );
	b3QHVertex* vertex3 = b3HullBuilder_NewVertex( b, points[index3] );
	b3QHList_PushBack( &b->vertexList.link, &vertex3->link );
	b3QHVertex* vertex4 = b3HullBuilder_NewVertex( b, points[index4] );
	b3QHList_PushBack( &b->vertexList.link, &vertex4->link );

	b3QHFace* face1 = b3HullBuilder_NewFace( b, vertex1, vertex2, vertex3 );
	b3QHList_PushBack( &b->faceList.link, &face1->link );
	b3QHFace* face2 = b3HullBuilder_NewFace( b, vertex4, vertex2, vertex1 );
	b3QHList_PushBack( &b->faceList.link, &face2->link );
	b3QHFace* face3 = b3HullBuilder_NewFace( b, vertex4, vertex3, vertex2 );
	b3QHList_PushBack( &b->faceList.link, &face3->link );
	b3QHFace* face4 = b3HullBuilder_NewFace( b, vertex4, vertex1, vertex3 );
	b3QHList_PushBack( &b->faceList.link, &face4->link );

	b3LinkFaces( face1, 0, face2, 1 );
	b3LinkFaces( face1, 1, face3, 1 );
	b3LinkFaces( face1, 2, face4, 1 );

	b3LinkFaces( face2, 0, face3, 2 );
	b3LinkFaces( face3, 0, face4, 2 );
	b3LinkFaces( face4, 0, face2, 2 );

#if B3_DEBUG
	B3_ASSERT( b3CheckConsistency( face1 ) );
	B3_ASSERT( b3CheckConsistency( face2 ) );
	B3_ASSERT( b3CheckConsistency( face3 ) );
	B3_ASSERT( b3CheckConsistency( face4 ) );
#endif

	for ( int index = 0; index < pointCount; ++index )
	{
		if ( index == index1 || index == index2 || index == index3 || index == index4 )
		{
			continue;
		}

		b3Vec3 point = points[index];

		float maxDistance = b->minOutside;
		b3QHFace* maxFace = NULL;

		for ( b3QHListNode* node = b->faceList.link.next; node != &b->faceList.link; node = node->next )
		{
			b3QHFace* face = (b3QHFace*)node;
			float distance = b3PlaneSeparation( face->plane, point );
			if ( distance > maxDistance )
			{
				maxDistance = distance;
				maxFace = face;
			}
		}

		if ( maxFace != NULL )
		{
			b3QHVertex* vertex = b3HullBuilder_NewVertex( b, point );
			vertex->conflictFace = maxFace;
			b3QHList_PushBack( &maxFace->conflictListHead.link, &vertex->link );
			if ( maxDistance > maxFace->maxConflictDistance )
			{
				maxFace->maxConflictDistance = maxDistance;
				maxFace->maxConflict = vertex;
			}
		}
	}

	return true;
}

// Recompute the farthest-conflict cache after a face's plane changes.
// Walks the existing conflict list once; cost is bounded by that list, not the global pool.
static void b3HullBuilder_RecacheConflicts( b3QHFace* face, float minOutside )
{
	b3QHVertex* maxVertex = NULL;
	float maxDistance = minOutside;

	for ( b3QHListNode* node = face->conflictListHead.link.next; node != &face->conflictListHead.link; node = node->next )
	{
		b3QHVertex* vertex = (b3QHVertex*)node;
		float distance = b3PlaneSeparation( face->plane, vertex->position );
		if ( distance > maxDistance )
		{
			maxDistance = distance;
			maxVertex = vertex;
		}
	}

	face->maxConflict = maxVertex;
	face->maxConflictDistance = maxDistance;
}

static b3QHVertex* b3HullBuilder_NextConflictVertex( const b3HullBuilder* b )
{
	b3QHVertex* maxVertex = NULL;
	float maxDistance = b->minOutside;

	for ( const b3QHListNode* faceNode = b->faceList.link.next; faceNode != &b->faceList.link; faceNode = faceNode->next )
	{
		const b3QHFace* face = (const b3QHFace*)faceNode;
		if ( face->maxConflict != NULL && face->maxConflictDistance > maxDistance )
		{
			maxDistance = face->maxConflictDistance;
			maxVertex = face->maxConflict;
		}
	}

	return maxVertex;
}

// Move every conflict vertex of `face` onto the orphaned list and clear their conflictFace.
static void b3HullBuilder_DrainConflictList( b3HullBuilder* b, b3QHFace* face )
{
	b3QHListNode* node = face->conflictListHead.link.next;
	while ( node != &face->conflictListHead.link )
	{
		b3QHVertex* orphan = (b3QHVertex*)node;
		node = node->next;

		orphan->conflictFace = NULL;
		b3QHList_Remove( &orphan->link );
		b3QHList_PushBack( &b->orphanedList.link, &orphan->link );
	}
	B3_ASSERT( B3_LIST_EMPTY( &face->conflictListHead.link ) );
}

// Mark a face for deletion, drain its conflict list, and populate a fresh DFS frame for it.
// `entryEdge` is the half-edge in `face` whose twin lies in the just-deleted parent face, or
// NULL for the seed. The frame skips `entryEdge` on recursive entries (it would be ignored
// anyway since the parent's mark is now DELETE, but skipping saves one iteration).
static void b3HullBuilder_EnterHorizonFace( b3HullBuilder* b, b3QHFace* face, b3QHHalfEdge* entryEdge, b3HorizonFrame* frameOut )
{
	face->mark = B3_MARK_DELETE;
	b3HullBuilder_DrainConflictList( b, face );

	frameOut->face = face;
	frameOut->started = false;
	if ( entryEdge != NULL )
	{
		frameOut->startEdge = entryEdge;
		frameOut->edge = entryEdge->next;
	}
	else
	{
		frameOut->startEdge = face->edge;
		frameOut->edge = face->edge;
	}
}

static void b3HullBuilder_BuildHorizon( b3HullBuilder* b, b3QHVertex* apex, b3QHFace* seed )
{
	b3HorizonFrame* stack = b->horizonStack;
	int top = 0;

	B3_ASSERT( top < b->horizonStackCapacity );
	b3HullBuilder_EnterHorizonFace( b, seed, NULL, &stack[top++] );

	while ( top > 0 )
	{
		b3HorizonFrame* f = &stack[top - 1];

		if ( f->started && f->edge == f->startEdge )
		{
			top--;
			continue;
		}
		f->started = true;

		b3QHHalfEdge* edge = f->edge;
		b3QHHalfEdge* twin = edge->twin;
		f->edge = edge->next;

		if ( twin->face->mark != B3_MARK_VISIBLE )
		{
			continue;
		}

		float distance = b3PlaneSeparation( twin->face->plane, apex->position );
		if ( distance > b->minRadius )
		{
			B3_ASSERT( top < b->horizonStackCapacity );
			b3HullBuilder_EnterHorizonFace( b, twin->face, twin, &stack[top++] );
		}
		else
		{
			B3_ASSERT( b->horizonCount < b->horizonCapacity );
			b->horizon[b->horizonCount++] = edge;
		}
	}
}

static void b3HullBuilder_BuildCone( b3HullBuilder* b, b3QHVertex* apex )
{
	for ( int i = 0; i < b->horizonCount; ++i )
	{
		b3QHHalfEdge* edge = b->horizon[i];
		B3_ASSERT( edge->twin->twin == edge );

		b3QHFace* face = b3HullBuilder_NewFace( b, apex, edge->origin, edge->twin->origin );
		B3_ASSERT( b->coneCount < b->coneCapacity );
		b->cone[b->coneCount++] = face;

		b3LinkFace( face, 1, edge->twin );
	}

	b3QHFace* face1 = b->cone[b->coneCount - 1];
	for ( int i = 0; i < b->coneCount; ++i )
	{
		b3QHFace* face2 = b->cone[i];
		b3LinkFaces( face1, 2, face2, 0 );
		face1 = face2;
	}
}

// Retire half-edges in the half-open ring range [begin, end) by pushing each onto edgeFreeHead.
// The caller has already detached these edges from the live face ring (rewire happens before
// destroy), so they are unreachable from the live hull.
static void b3HullBuilder_DestroyEdges( b3HullBuilder* b, b3QHHalfEdge* begin, b3QHHalfEdge* end )
{
	b3QHHalfEdge* edge = begin;
	while ( edge != end )
	{
		b3QHHalfEdge* next = edge->next;
		b3HullBuilder_RetireEdge( b, edge );
		edge = next;
	}
}

static void b3HullBuilder_ConnectEdges( b3HullBuilder* b, b3QHHalfEdge* prev, b3QHHalfEdge* next )
{
	B3_ASSERT( prev != next );
	B3_ASSERT( prev->face == next->face );

	// If both shared neighbors are the same face, prev and next together would orphan that face.
	if ( prev->twin->face == next->twin->face )
	{
		// next is redundant.
		if ( next->face->edge == next )
		{
			next->face->edge = prev;
		}

		b3QHHalfEdge* twin;
		if ( b3VertexCountOfFace( prev->twin->face ) == 3 )
		{
			// Capture all 3 half-edges of the dead triangle before the rewire overwrites prev->twin.
			b3QHHalfEdge* deadEdge0 = prev->twin;		// prev->twin (will be rewired below)
			b3QHHalfEdge* deadEdge1 = next->twin;		// next->twin
			b3QHHalfEdge* deadEdge2 = next->twin->prev; // third edge of the dead triangle

			twin = deadEdge2->twin;
			B3_ASSERT( twin->face->mark != B3_MARK_DELETE );

			b3QHFace* opposingFace = prev->twin->face;
			opposingFace->mark = B3_MARK_DELETE;
			B3_ASSERT( b->mergedFacesCount < b->mergedFacesCapacity );
			b->mergedFaces[b->mergedFacesCount++] = opposingFace;

			prev->next = next->next;
			prev->next->prev = prev;

			prev->twin = twin;
			twin->twin = prev;

			// Drop the redundant vertex (slot abandoned in the bump allocator).
			b3QHList_Remove( &next->origin->link );

			// Retire the 3 half-edges of the dead triangle now that the rewire is complete.
			b3HullBuilder_RetireEdge( b, deadEdge0 );
			b3HullBuilder_RetireEdge( b, deadEdge1 );
			b3HullBuilder_RetireEdge( b, deadEdge2 );
		}
		else
		{
			twin = next->twin;

			if ( twin->face->edge == prev->twin )
			{
				twin->face->edge = twin;
			}

			twin->next = prev->twin->next;
			twin->next->prev = twin;
			// prev->twin slot is retired to the edge free list.
			b3HullBuilder_RetireEdge( b, prev->twin );

			prev->next = next->next;
			prev->next->prev = prev;

			prev->twin = twin;
			twin->twin = prev;

			// Drop the redundant vertex (slot abandoned in the bump allocator).
			b3QHList_Remove( &next->origin->link );
		}

		// Twin->face changed shape; recompute its plane and refresh its cached max conflict.
		b3NewellPlane( twin->face );
		b3HullBuilder_RecacheConflicts( twin->face, b->minOutside );
	}
	else
	{
		prev->next = next;
		next->prev = prev;
	}
}

static void b3HullBuilder_AbsorbFaces( b3HullBuilder* b, b3QHFace* face )
{
	for ( int i = 0; i < b->mergedFacesCount; ++i )
	{
		B3_ASSERT( b->mergedFaces[i]->mark == B3_MARK_DELETE );
		b3QHListNode* head = &b->mergedFaces[i]->conflictListHead.link;

		b3QHListNode* node = head->next;
		while ( node != head )
		{
			b3QHVertex* vertex = (b3QHVertex*)node;
			node = node->next;

			b3QHList_Remove( &vertex->link );

			float distance = b3PlaneSeparation( face->plane, vertex->position );
			if ( distance > b->minOutside )
			{
				b3QHList_PushBack( &face->conflictListHead.link, &vertex->link );
				vertex->conflictFace = face;
				if ( distance > face->maxConflictDistance )
				{
					face->maxConflictDistance = distance;
					face->maxConflict = vertex;
				}
			}
			else
			{
				b3QHList_PushBack( &b->orphanedList.link, &vertex->link );
				vertex->conflictFace = NULL;
			}
		}

		B3_ASSERT( B3_LIST_EMPTY( head ) );

		// Conflict list is now drained. Retire this face to the free list.
		b3HullBuilder_RetireFace( b, b->mergedFaces[i] );
	}
}

static void b3HullBuilder_ConnectFaces( b3HullBuilder* b, b3QHHalfEdge* edge )
{
	b3QHFace* face = edge->face;

	b3QHHalfEdge* twin = edge->twin;

	b3QHHalfEdge* edgePrev = edge->prev;
	b3QHHalfEdge* edgeNext = edge->next;
	b3QHHalfEdge* twinPrev = twin->prev;
	b3QHHalfEdge* twinNext = twin->next;

	while ( edgePrev->twin->face == twin->face )
	{
		B3_ASSERT( edgePrev->twin == twinNext );
		B3_ASSERT( twinNext->twin == edgePrev );

		edgePrev = edgePrev->prev;
		twinNext = twinNext->next;
	}
	B3_ASSERT( edgePrev->face != twinNext->face );

	while ( edgeNext->twin->face == twin->face )
	{
		B3_ASSERT( edgeNext->twin == twinPrev );
		B3_ASSERT( twinPrev->twin == edgeNext );

		edgeNext = edgeNext->next;
		twinPrev = twinPrev->prev;
	}
	B3_ASSERT( edgeNext->face != twinPrev->face );

	face->edge = edgePrev;

	// Discard opposing face. mergedFaces is single-buffered: ConnectFaces does not nest.
	b->mergedFacesCount = 0;
	B3_ASSERT( b->mergedFacesCount < b->mergedFacesCapacity );
	b->mergedFaces[b->mergedFacesCount++] = twin->face;
	twin->face->mark = B3_MARK_DELETE;
	twin->face->edge = NULL;

	for ( b3QHHalfEdge* absorbed = twinNext; absorbed != twinPrev->next; absorbed = absorbed->next )
	{
		absorbed->face = face;
	}

	b3HullBuilder_DestroyEdges( b, edgePrev->next, edgeNext );
	b3HullBuilder_DestroyEdges( b, twinPrev->next, twinNext );

	b3HullBuilder_ConnectEdges( b, edgePrev, twinNext );
	b3HullBuilder_ConnectEdges( b, twinPrev, edgeNext );

	b3NewellPlane( face );
	// Existing conflicts now have stale distances under the new plane; AbsorbFaces will then
	// add more incrementally and update the cache as it goes.
	b3HullBuilder_RecacheConflicts( face, b->minOutside );
#if B3_DEBUG
	B3_ASSERT( b3CheckConsistency( face ) );
#endif

	b3HullBuilder_AbsorbFaces( b, face );
}

static bool b3HullBuilder_MergeConcave( b3HullBuilder* b, b3QHFace* face )
{
	b3QHHalfEdge* edge = face->edge;

	do
	{
		b3QHHalfEdge* twin = edge->twin;

		if ( b3IsEdgeConcave( edge, b->minRadius ) || b3IsEdgeConcave( twin, b->minRadius ) )
		{
			b3HullBuilder_ConnectFaces( b, edge );
			return true;
		}

		edge = edge->next;
	}
	while ( edge != face->edge );

	return false;
}

static bool b3HullBuilder_MergeCoplanar( b3HullBuilder* b, b3QHFace* face )
{
	b3QHHalfEdge* edge = face->edge;

	do
	{
		b3QHHalfEdge* twin = edge->twin;

		if ( !b3IsEdgeConvex( edge, b->minRadius ) || !b3IsEdgeConvex( twin, b->minRadius ) )
		{
			b3HullBuilder_ConnectFaces( b, edge );
			return true;
		}

		edge = edge->next;
	}
	while ( edge != face->edge );

	return false;
}

static void b3HullBuilder_MergeFaces( b3HullBuilder* b )
{
	for ( int i = 0; i < b->coneCount; ++i )
	{
		b3QHFace* face = b->cone[i];
		if ( face->mark == B3_MARK_VISIBLE && face->flipped )
		{
			face->flipped = false;

			float bestArea = 0;
			b3QHHalfEdge* bestEdge = NULL;

			b3QHHalfEdge* edge = face->edge;
			do
			{
				b3QHHalfEdge* twin = edge->twin;
				float area = twin->face->area;
				if ( area > bestArea )
				{
					bestArea = area;
					bestEdge = edge;
				}

				edge = edge->next;
			}
			while ( edge != face->edge );

			B3_ASSERT( bestEdge != NULL );
			b3HullBuilder_ConnectFaces( b, bestEdge );
		}
	}

	for ( int i = 0; i < b->coneCount; ++i )
	{
		b3QHFace* face = b->cone[i];
		if ( face->mark == B3_MARK_VISIBLE )
		{
			while ( b3HullBuilder_MergeConcave( b, face ) )
			{
			}
		}
	}

	for ( int i = 0; i < b->coneCount; ++i )
	{
		b3QHFace* face = b->cone[i];
		if ( face->mark == B3_MARK_VISIBLE )
		{
			while ( b3HullBuilder_MergeCoplanar( b, face ) )
			{
			}
		}
	}
}

static void b3HullBuilder_ResolveVertices( b3HullBuilder* b )
{
	b3QHListNode* node = b->orphanedList.link.next;
	while ( node != &b->orphanedList.link )
	{
		b3QHVertex* vertex = (b3QHVertex*)node;
		node = node->next;
		b3QHList_Remove( &vertex->link );

		float maxDistance = b->minOutside;
		b3QHFace* maxFace = NULL;

		for ( int i = 0; i < b->coneCount; ++i )
		{
			if ( b->cone[i]->mark == B3_MARK_VISIBLE )
			{
				float distance = b3PlaneSeparation( b->cone[i]->plane, vertex->position );
				if ( distance > maxDistance )
				{
					maxDistance = distance;
					maxFace = b->cone[i];
				}
			}
		}

		if ( maxFace != NULL )
		{
			B3_ASSERT( maxFace->mark == B3_MARK_VISIBLE );
			b3QHList_PushBack( &maxFace->conflictListHead.link, &vertex->link );
			vertex->conflictFace = maxFace;
			if ( maxDistance > maxFace->maxConflictDistance )
			{
				maxFace->maxConflictDistance = maxDistance;
				maxFace->maxConflict = vertex;
			}
		}
		// Otherwise: vertex is interior to the hull. Its slot in the bump pool is abandoned.
	}

	B3_ASSERT( B3_LIST_EMPTY( &b->orphanedList.link ) );
}

static void b3HullBuilder_ResolveFaces( b3HullBuilder* b )
{
	// Splice deleted faces out of the face list. Faces already retired by AbsorbFaces are no
	// longer on faceList, so we guard with b3QHList_Contains before removing.
	b3QHListNode* node = b->faceList.link.next;
	while ( node != &b->faceList.link )
	{
		b3QHFace* face = (b3QHFace*)node;
		node = node->next;

		if ( face->mark == B3_MARK_DELETE && b3QHList_Contains( &face->link ) )
		{
			B3_ASSERT( B3_LIST_EMPTY( &face->conflictListHead.link ) );
			b3QHList_Remove( &face->link );
		}
	}

	for ( int i = 0; i < b->coneCount; ++i )
	{
		b3QHFace* face = b->cone[i];
		if ( face->mark == B3_MARK_DELETE )
		{
			continue;
		}
		b3QHList_PushBack( &b->faceList.link, &face->link );
	}
}

static void b3HullBuilder_AddVertexToHull( b3HullBuilder* b, b3QHVertex* vertex )
{
	b3QHFace* face = vertex->conflictFace;
	vertex->conflictFace = NULL;
	b3QHList_Remove( &vertex->link );
	b3QHList_PushBack( &b->vertexList.link, &vertex->link );

	b->horizonCount = 0;
	b3HullBuilder_BuildHorizon( b, vertex, face );
	B3_ASSERT( b->horizonCount >= 3 );

	b->coneCount = 0;
	b3HullBuilder_BuildCone( b, vertex );
	B3_ASSERT( b->coneCount >= 3 );

	b3HullBuilder_MergeFaces( b );
	b3HullBuilder_ResolveVertices( b );
	b3HullBuilder_ResolveFaces( b );
}

static void b3HullBuilder_CleanHull( b3HullBuilder* b, b3Vec3 origin )
{
	int faceCount = 0;
	int halfEdgeCount = 0;

	for ( b3QHListNode* faceNode = b->faceList.link.next; faceNode != &b->faceList.link; faceNode = faceNode->next )
	{
		b3QHFace* face = (b3QHFace*)faceNode;
		b3QHHalfEdge* edge = face->edge;

		do
		{
			edge->origin->reachable = true;
			edge = edge->next;
			halfEdgeCount++;
		}
		while ( edge != face->edge );

		face->plane.offset += b3Dot( face->plane.normal, origin );
		face->centroid = b3Add( face->centroid, origin );
		faceCount++;
	}

	int vertexCount = 0;
	b3QHListNode* node = b->vertexList.link.next;
	while ( node != &b->vertexList.link )
	{
		b3QHVertex* vertex = (b3QHVertex*)node;
		node = node->next;

		if ( !vertex->reachable )
		{
			b3QHList_Remove( &vertex->link );
		}
		else
		{
			vertex->position = b3Add( vertex->position, origin );
			vertexCount++;
		}
	}

	b->interiorPoint = b3Add( b->interiorPoint, origin );

	b->finalVertexCount = vertexCount;
	b->finalHalfEdgeCount = halfEdgeCount;
	b->finalFaceCount = faceCount;
}

#if B3_DEBUG
static bool b3HullBuilder_IsConsistent( const b3HullBuilder* b )
{
	int v = b->finalVertexCount;
	int e = b->finalHalfEdgeCount / 2;
	int f = b->finalFaceCount;

	if ( v - e + f != 2 )
	{
		return false;
	}

	for ( const b3QHListNode* faceNode = b->faceList.link.next; faceNode != &b->faceList.link; faceNode = faceNode->next )
	{
		const b3QHFace* face = (const b3QHFace*)faceNode;
		if ( face->edge->face != face )
		{
			return false;
		}

		if ( !b3CheckConsistency( face ) )
		{
			return false;
		}

		if ( b3PlaneSeparation( face->plane, b->interiorPoint ) > 0 )
		{
			return false;
		}

		if ( face->mark != B3_MARK_VISIBLE )
		{
			return false;
		}

		const b3QHHalfEdge* edge = face->edge;

		do
		{
			if ( edge->next->origin != edge->twin->origin )
			{
				return false;
			}
			if ( edge->prev->next != edge )
			{
				return false;
			}
			if ( edge->next->prev != edge )
			{
				return false;
			}
			if ( edge->twin->twin != edge )
			{
				return false;
			}
			if ( edge->face != face )
			{
				return false;
			}
			if ( b3DistanceSquared( edge->origin->position, edge->twin->origin->position ) < 1000.0f * FLT_MIN )
			{
				return false;
			}

			edge = edge->next;
		}
		while ( edge != face->edge );
	}

	return true;
}
#endif

static bool b3HullBuilder_HasHull( const b3HullBuilder* b )
{
	int v = b->finalVertexCount;
	int e = b->finalHalfEdgeCount / 2;
	int f = b->finalFaceCount;
	return v - e + f == 2 && f >= 4;
}

// Build the entire hull. Returns true iff the result satisfies Euler's identity.
static bool b3HullBuilder_Construct( b3HullBuilder* b, const b3Vec3* points, int pointCount, int maxVertexCount, b3Vec3 origin,
									 b3Vec3* shiftedPoints )
{
	if ( pointCount < 4 )
	{
		return false;
	}

	for ( int i = 0; i < pointCount; ++i )
	{
		shiftedPoints[i] = b3Sub( points[i], origin );
	}

	b3HullBuilder_ComputeTolerance( b, pointCount, shiftedPoints );
	if ( !b3HullBuilder_BuildInitialHull( b, pointCount, shiftedPoints ) )
	{
		return false;
	}

	int budget = b3ClampInt( maxVertexCount - 4, 0, B3_HULL_LIMIT - 4 );

	b3QHVertex* vertex = b3HullBuilder_NextConflictVertex( b );
	while ( vertex && budget > 0 )
	{
		b3HullBuilder_AddVertexToHull( b, vertex );
		vertex = b3HullBuilder_NextConflictVertex( b );
		budget -= 1;
	}

	b3HullBuilder_CleanHull( b, origin );

#if B3_DEBUG
	B3_ASSERT( b3HullBuilder_IsConsistent( b ) );
#endif

	return b3HullBuilder_HasHull( b );
}

typedef struct b3HullWorkSizes
{
	int N; // pointCount
	int M; // clamped maxVertexCount, in [4, B3_HULL_LIMIT]
	int vertexCapacity;
	int edgeCapacity;
	int faceCapacity;
	int horizonCapacity;
	int coneCapacity;
	int mergedFacesCapacity;
	int horizonStackCapacity;
	size_t totalBytes;

	size_t offsetVertex;
	size_t offsetEdge;
	size_t offsetFace;
	size_t offsetHorizon;
	size_t offsetCone;
	size_t offsetMergedFaces;
	size_t offsetHorizonStack;
	size_t offsetShiftedPoints;
} b3HullWorkSizes;

static b3HullWorkSizes b3ComputeHullWorkSizes( int pointCount, int clampedMaxCount )
{
	b3HullWorkSizes s;
	s.N = pointCount;
	s.M = clampedMaxCount;

	// Vertices: 4 initial hull vertices + at most one per remaining input point. No free list.
	s.vertexCapacity = pointCount + 4;

	// Edges and faces use free-list recycling; capacity is proportional to live hull size.
	// edgeCapacity: peak is ~twice live edges plus cone edges; floor 48.
	s.edgeCapacity = 24 * s.M - 48;
	if ( s.edgeCapacity < 48 )
	{
		s.edgeCapacity = 48;
	}

	// faceCapacity: peak intermediate state live faces (<=2*M-4) plus full cone (<=3*M-6); floor 16.
	s.faceCapacity = 5 * s.M - 10;
	if ( s.faceCapacity < 16 )
	{
		s.faceCapacity = 16;
	}

	// Horizon/cone bounded by current half-edge count; mergedFaces by face count.
	s.horizonCapacity = 3 * s.M - 6;
	if ( s.horizonCapacity < 6 )
	{
		s.horizonCapacity = 6;
	}
	s.coneCapacity = s.horizonCapacity;
	s.mergedFacesCapacity = 2 * s.M - 4;
	if ( s.mergedFacesCapacity < 4 )
	{
		s.mergedFacesCapacity = 4;
	}

	// Horizon DFS depth is bounded by the number of live faces (Euler: <=2*M-4).
	s.horizonStackCapacity = 2 * s.M - 4;
	if ( s.horizonStackCapacity < 4 )
	{
		s.horizonStackCapacity = 4;
	}

	size_t offset = 0;

	s.offsetVertex = offset;
	offset = b3AlignUp8( offset + (size_t)s.vertexCapacity * sizeof( b3QHVertex ) );

	s.offsetEdge = offset;
	offset = b3AlignUp8( offset + (size_t)s.edgeCapacity * sizeof( b3QHHalfEdge ) );

	s.offsetFace = offset;
	offset = b3AlignUp8( offset + (size_t)s.faceCapacity * sizeof( b3QHFace ) );

	s.offsetHorizon = offset;
	offset = b3AlignUp8( offset + (size_t)s.horizonCapacity * sizeof( b3QHHalfEdge* ) );

	s.offsetCone = offset;
	offset = b3AlignUp8( offset + (size_t)s.coneCapacity * sizeof( b3QHFace* ) );

	s.offsetMergedFaces = offset;
	offset = b3AlignUp8( offset + (size_t)s.mergedFacesCapacity * sizeof( b3QHFace* ) );

	s.offsetHorizonStack = offset;
	offset = b3AlignUp8( offset + (size_t)s.horizonStackCapacity * sizeof( b3HorizonFrame ) );

	s.offsetShiftedPoints = offset;
	offset += (size_t)pointCount * sizeof( b3Vec3 );

	s.totalBytes = offset;
	return s;
}

static void b3HullBuilder_Init( b3HullBuilder* b, char* mem, const b3HullWorkSizes* s )
{
	memset( b, 0, sizeof( *b ) );
	b3QHList_Init( &b->orphanedList.link );
	b3QHList_Init( &b->vertexList.link );
	b3QHList_Init( &b->faceList.link );

	b->vertexBase = (b3QHVertex*)( mem + s->offsetVertex );
	b->vertexCapacity = s->vertexCapacity;

	b->edgeBase = (b3QHHalfEdge*)( mem + s->offsetEdge );
	b->edgeCapacity = s->edgeCapacity;

	b->faceBase = (b3QHFace*)( mem + s->offsetFace );
	b->faceCapacity = s->faceCapacity;

	b->horizon = (b3QHHalfEdge**)( mem + s->offsetHorizon );
	b->horizonCapacity = s->horizonCapacity;

	b->cone = (b3QHFace**)( mem + s->offsetCone );
	b->coneCapacity = s->coneCapacity;

	b->mergedFaces = (b3QHFace**)( mem + s->offsetMergedFaces );
	b->mergedFacesCapacity = s->mergedFacesCapacity;

	b->horizonStack = (b3HorizonFrame*)( mem + s->offsetHorizonStack );
	b->horizonStackCapacity = s->horizonStackCapacity;
}

static b3Vec3* b3GetHullPointsWrite( b3HullData* hull )
{
	if ( hull->pointOffset == 0 )
	{
		return NULL;
	}
	return (b3Vec3*)( (intptr_t)hull + hull->pointOffset );
}

static b3Plane* b3GetHullPlanesWrite( b3HullData* hull )
{
	if ( hull->planeOffset == 0 )
	{
		return NULL;
	}
	return (b3Plane*)( (intptr_t)hull + hull->planeOffset );
}

static b3HullVertex* b3GetHullVerticesWrite( b3HullData* hull )
{
	if ( hull->vertexOffset == 0 )
	{
		return NULL;
	}
	return (b3HullVertex*)( (intptr_t)hull + hull->vertexOffset );
}

static b3HullHalfEdge* b3GetHullEdgesWrite( b3HullData* hull )
{
	if ( hull->edgeOffset == 0 )
	{
		return NULL;
	}
	return (b3HullHalfEdge*)( (intptr_t)hull + hull->edgeOffset );
}

int b3FindHullSupportVertex( const b3HullData* hull, b3Vec3 direction )
{
	int bestIndex = B3_NULL_INDEX;
	float bestDot = -FLT_MAX;

	int vertexCount = hull->vertexCount;
	const b3Vec3* points = b3GetHullPoints( hull );

	for ( int index = 0; index < vertexCount; ++index )
	{
		float dot = b3Dot( direction, points[index] );
		if ( dot > bestDot )
		{
			bestIndex = index;
			bestDot = dot;
		}
	}
	B3_ASSERT( bestIndex >= 0 );

	return bestIndex;
}

int b3FindHullSupportFace( const b3HullData* hull, b3Vec3 direction )
{
	int bestIndex = B3_NULL_INDEX;
	float bestDot = -FLT_MAX;

	int faceCount = hull->faceCount;
	const b3Plane* planes = b3GetHullPlanes( hull );

	for ( int index = 0; index < faceCount; ++index )
	{
		float dot = b3Dot( planes[index].normal, direction );
		if ( dot > bestDot )
		{
			bestDot = dot;
			bestIndex = index;
		}
	}
	B3_ASSERT( bestIndex >= 0 );

	return bestIndex;
}

#if B3_ENABLE_VALIDATION

bool b3IsValidHull( const b3HullData* hull )
{
	if ( hull->version != B3_HULL_VERSION )
	{
		return false;
	}

	int v = hull->vertexCount;
	int e = hull->edgeCount / 2;
	int f = hull->faceCount;

	if ( v - e + f != 2 )
	{
		return false;
	}

	const b3HullVertex* vertices = b3GetHullVertices( hull );
	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	for ( int index = 0; index < hull->vertexCount; ++index )
	{
		const b3HullVertex* vertex = vertices + index;
		const b3HullHalfEdge* edge = edges + vertex->edge;

		if ( edge->origin != index )
		{
			return false;
		}
	}

	for ( int index = 0; index < hull->edgeCount; index += 2 )
	{
		const b3HullHalfEdge* edge = edges + index + 0;
		const b3HullHalfEdge* twin = edges + index + 1;

		if ( edge->twin != index + 1 )
		{
			return false;
		}

		if ( twin->twin != index + 0 )
		{
			return false;
		}
	}

	const b3HullFace* faces = b3GetHullFaces( hull );
	const b3Plane* planes = b3GetHullPlanes( hull );
	for ( int faceIndex = 0; faceIndex < hull->faceCount; ++faceIndex )
	{
		const b3HullFace* face = faces + faceIndex;

		int baseEdgeIndex = face->edge;
		const b3HullHalfEdge* edge = edges + baseEdgeIndex;

		b3Plane plane = planes[faceIndex];
		if ( b3PlaneSeparation( plane, hull->center ) >= 0.0f )
		{
			return false;
		}

		int edgeIndex = baseEdgeIndex;
		do
		{
			edge = edges + edgeIndex;
			const b3HullHalfEdge* next = edges + edge->next;
			const b3HullHalfEdge* twin = edges + edge->twin;

			if ( edge->face != faceIndex )
			{
				return false;
			}

			if ( twin->twin != edgeIndex )
			{
				return false;
			}

			if ( next->origin != twin->origin )
			{
				return false;
			}

			edgeIndex = edge->next;
		}
		while ( edgeIndex != baseEdgeIndex );
	}

	if ( hull->volume <= 0.0f )
	{
		return false;
	}

	if ( hull->surfaceArea <= 0.0f )
	{
		return false;
	}

	if ( hull->innerRadius <= 0.0f )
	{
		return false;
	}

	return true;
}

#else

bool b3IsValidHull( const b3HullData* hull )
{
	B3_UNUSED( hull );
	return true;
}

#endif

b3HullData* b3CreateCylinder( float height, float radius, float yOffset, int sides )
{
	B3_ASSERT( height > 0.0f );
	B3_ASSERT( radius > 0.0f );
	B3_ASSERT( 3 <= sides && sides <= 32 );

	int pointCount = 2 * sides;
	b3Vec3* points = (b3Vec3*)b3Alloc( pointCount * sizeof( b3Vec3 ) );
	B3_ASSERT( points != NULL );

	float alpha = 0.0f;
	float deltaAlpha = 2.0f * B3_PI / sides;

	for ( int index = 0; index < sides; ++index )
	{
		float sinAlpha = b3Sin( alpha );
		float cosAlpha = b3Cos( alpha );

		points[2 * index + 0] = (b3Vec3){ radius * cosAlpha, yOffset, radius * sinAlpha };
		points[2 * index + 1] = (b3Vec3){ radius * cosAlpha, yOffset + height, radius * sinAlpha };

		alpha += deltaAlpha;
	}

	b3HullData* hull = b3CreateHull( points, pointCount, pointCount );
	B3_ASSERT( hull->vertexCount == pointCount );
	B3_ASSERT( hull->edgeCount == 6 * sides );
	B3_ASSERT( hull->faceCount == sides + 2 );

	b3Free( points, pointCount * sizeof( b3Vec3 ) );

	return hull;
}

b3HullData* b3CreateCone( float height, float radius1, float radius2, int slices )
{
	B3_ASSERT( height > 0.0f );
	B3_ASSERT( radius1 > 0.0f );
	B3_ASSERT( radius2 > 0.0f );
	B3_ASSERT( 4 <= slices && slices <= 32 );

	int pointCount = 2 * slices;
	b3Vec3* points = (b3Vec3*)b3Alloc( pointCount * sizeof( b3Vec3 ) );
	B3_ASSERT( points != NULL );

	float alpha = 0.0f;
	float deltaAlpha = 2.0f * B3_PI / slices;

	for ( int index = 0; index < slices; ++index )
	{
		float sinAlpha = b3Sin( alpha );
		float cosAlpha = b3Cos( alpha );

		points[2 * index + 0] = (b3Vec3){ radius1 * cosAlpha, 0.0f, radius1 * sinAlpha };
		points[2 * index + 1] = (b3Vec3){ radius2 * cosAlpha, height, radius2 * sinAlpha };

		alpha += deltaAlpha;
	}

	b3HullData* hull = b3CreateHull( points, pointCount, pointCount );
	B3_ASSERT( hull->vertexCount == pointCount );
	B3_ASSERT( hull->edgeCount == 6 * slices );
	B3_ASSERT( hull->faceCount == slices + 2 );

	b3Free( points, pointCount * sizeof( b3Vec3 ) );

	return hull;
}

b3HullData* b3CreateRock( float radius )
{
	int pointCount = 10;

	// Golden ratio
	const float phi = ( 1.0f + sqrtf( 5.0f ) ) / 2.0f;

	// Fibonacci lattice
	b3Vec3 points[10];

	// Azimuthal angle
	float theta = 2.0f * B3_PI / phi;

	b3CosSin cs = { 1.0f, 0.0 };
	b3CosSin deltaCS = b3ComputeCosSin( theta );

	for ( int i = 0; i < pointCount; ++i )
	{
		// Z coordinate
		float z = 1.0f - ( 2.0f * i + 1.0f ) / pointCount;
		// Radius in xy-plane
		float radius_XY = sqrtf( 1.0f - z * z );

		points[i].x = radius * radius_XY * cs.cosine;
		points[i].y = radius * radius_XY * cs.sine;
		points[i].z = radius * z;

		b3CosSin cs0 = cs;
		cs.cosine = deltaCS.cosine * cs0.cosine - deltaCS.sine * cs0.sine;
		cs.sine = deltaCS.sine * cs0.cosine + deltaCS.cosine * cs0.sine;
	}

	return b3CreateHull( points, pointCount, pointCount );
}

static void b3UpdateHullBounds( b3HullData* hull )
{
	const b3Vec3* points = b3GetHullPoints( hull );
	int vertexCount = hull->vertexCount;

	B3_ASSERT( vertexCount > 0 );
	b3AABB bounds;
	bounds.lowerBound = points[0];
	bounds.upperBound = points[0];

	for ( int i = 1; i < vertexCount; ++i )
	{
		b3Vec3 p = points[i];
		bounds.lowerBound = b3Min( bounds.lowerBound, p );
		bounds.upperBound = b3Max( bounds.upperBound, p );
	}

	hull->aabb = bounds;
}

// M. Kallay - "Computing the Moment of Inertia of a Solid Defined by a Triangle Mesh"
static bool b3UpdateHullBulkProperties( b3HullData* hull )
{
	const b3Vec3* points = b3GetHullPoints( hull );
	const b3HullFace* faces = b3GetHullFaces( hull );
	const b3HullHalfEdge* edges = b3GetHullEdges( hull );
	const b3Plane* planes = b3GetHullPlanes( hull );

	float area = 0.0f;
	float volume = 0.0f;
	b3Vec3 center = b3Vec3_zero;

	// Use the first vertex to reduce round-off errors.
	b3Vec3 origin = points[0];

	float xx = 0.0f;
	float xy = 0.0f;
	float yy = 0.0f;
	float xz = 0.0f;
	float zz = 0.0f;
	float yz = 0.0f;

	int faceCount = hull->faceCount;

	for ( int faceIndex = 0; faceIndex < faceCount; ++faceIndex )
	{
		const b3HullFace* face = faces + faceIndex;
		const b3HullHalfEdge* edge1 = edges + face->edge;
		const b3HullHalfEdge* edge2 = edges + edge1->next;
		const b3HullHalfEdge* edge3 = edges + edge2->next;

		B3_ASSERT( edge1 != edge3 );
		B3_ASSERT( edge1->origin < hull->vertexCount );

		b3Vec3 v1 = b3Sub( points[edge1->origin], origin );

		do
		{
			B3_ASSERT( edge2->origin < hull->vertexCount );
			B3_ASSERT( edge3->origin < hull->vertexCount );

			b3Vec3 v2 = b3Sub( points[edge2->origin], origin );
			b3Vec3 v3 = b3Sub( points[edge3->origin], origin );

			area += b3Length( b3Cross( b3Sub( v2, v1 ), b3Sub( v3, v1 ) ) );

			float det = b3ScalarTripleProduct( v1, v2, v3 );

			volume += det;

			b3Vec3 v4 = b3Add( v1, b3Add( v2, v3 ) );
			center = b3Add( center, b3MulSV( det, v4 ) );

			xx += det * ( v1.x * v1.x + v2.x * v2.x + v3.x * v3.x + v4.x * v4.x );
			yy += det * ( v1.y * v1.y + v2.y * v2.y + v3.y * v3.y + v4.y * v4.y );
			zz += det * ( v1.z * v1.z + v2.z * v2.z + v3.z * v3.z + v4.z * v4.z );
			xy += det * ( v1.x * v1.y + v2.x * v2.y + v3.x * v3.y + v4.x * v4.y );
			xz += det * ( v1.x * v1.z + v2.x * v2.z + v3.x * v3.z + v4.x * v4.z );
			yz += det * ( v1.y * v1.z + v2.y * v2.z + v3.y * v3.z + v4.y * v4.z );

			edge2 = edge3;
			edge3 = edges + edge3->next;
		}
		while ( edge1 != edge3 );
	}

	B3_VALIDATE( volume > 0.0f );

	b3Vec3 localCenter = volume > 0.0f ? b3MulSV( 0.25f / volume, center ) : b3Vec3_zero;
	center = b3Add( localCenter, origin );

	float radius = FLT_MAX;
	for ( int faceIndex = 0; faceIndex < faceCount; ++faceIndex )
	{
		b3Plane plane = planes[faceIndex];
		float distance = b3PlaneSeparation( plane, center );
		B3_VALIDATE( distance < 0.0f );

		radius = b3MinFloat( radius, -distance );
	}

	B3_VALIDATE( 0.0f < radius && radius < FLT_MAX );

	b3Matrix3 inertia;
	inertia.cx.x = yy + zz;
	inertia.cy.x = -xy;
	inertia.cz.x = -xz;
	inertia.cx.y = -xy;
	inertia.cy.y = xx + zz;
	inertia.cz.y = -yz;
	inertia.cx.z = -xz;
	inertia.cy.z = -yz;
	inertia.cz.z = xx + yy;

	float mass = volume / 6.0f;

	b3Matrix3 centralInertia = b3MulSM( 1.0f / 120.0f, inertia );
	centralInertia = b3SubMM( centralInertia, b3Steiner( mass, localCenter ) );

	hull->center = center;
	hull->centralInertia = centralInertia;
	hull->volume = mass;
	hull->surfaceArea = 0.5f * area;
	hull->innerRadius = radius;

	if ( mass <= 0.0f )
	{
		return false;
	}

	if ( volume <= 0.0f )
	{
		return false;
	}

	if ( area <= 0.0f )
	{
		return false;
	}

	if ( radius <= 0.0f )
	{
		return false;
	}

	return true;
}

b3HullData* b3CreateHull( const b3Vec3* points, int pointCount, int maxVertexCount )
{
	if ( pointCount < 4 )
	{
		return NULL;
	}

	b3Vec3 origin = points[0];
	int clampedMaxCount = b3ClampInt( maxVertexCount, 4, B3_HULL_LIMIT );

	// Single allocation for all working memory.
	b3HullWorkSizes sizes = b3ComputeHullWorkSizes( pointCount, clampedMaxCount );
	char* work = b3Alloc( sizes.totalBytes );

	b3HullBuilder builder;
	b3HullBuilder_Init( &builder, work, &sizes );

	b3Vec3* shiftedPoints = (b3Vec3*)( work + sizes.offsetShiftedPoints );

	bool ok = b3HullBuilder_Construct( &builder, points, pointCount, clampedMaxCount, origin, shiftedPoints );
	if ( !ok )
	{
		b3Free( work, sizes.totalBytes );
		return NULL;
	}

	if ( builder.finalVertexCount >= B3_HULL_LIMIT )
	{
		b3Log( "hull final vertex count of %d exceeds limit of %d", builder.finalVertexCount, B3_HULL_LIMIT );
		b3Free( work, sizes.totalBytes );
		return NULL;
	}

	if ( builder.finalFaceCount >= B3_HULL_LIMIT )
	{
		b3Log( "hull final face count of %d exceeds limit of %d", builder.finalFaceCount, B3_HULL_LIMIT );
		b3Free( work, sizes.totalBytes );
		return NULL;
	}

	if ( builder.finalHalfEdgeCount >= B3_HULL_LIMIT )
	{
		b3Log( "hull final half edge count of %d exceeds limit of %d", builder.finalHalfEdgeCount, B3_HULL_LIMIT );
		b3Free( work, sizes.totalBytes );
		return NULL;
	}

	// Walk lists into temp arrays bounded by B3_HULL_LIMIT, stamping finalIndex on each node so
	// the resolution pass below is O(E + F) instead of O(E^2 + F^2).
	const b3QHVertex* tempVertices[B3_HULL_LIMIT];
	int vertexCount = 0;
	for ( b3QHListNode* node = builder.vertexList.link.next; node != &builder.vertexList.link; node = node->next )
	{
		B3_ASSERT( vertexCount <= B3_HULL_LIMIT - 1 );

		b3QHVertex* vertex = (b3QHVertex*)node;
		vertex->finalIndex = vertexCount;
		tempVertices[vertexCount++] = vertex;
	}

	// Collect edges in twin-paired order (i, i+1) by stamping each pair as we discover it.
	// Replaces b3SortEdges' O(E^2) twin pairing.
	const b3QHFace* tempFaces[B3_HULL_LIMIT];
	const b3QHHalfEdge* tempEdges[B3_HULL_LIMIT];
	int faceCount = 0;
	int edgeCount = 0;

	for ( b3QHListNode* faceNode = builder.faceList.link.next; faceNode != &builder.faceList.link; faceNode = faceNode->next )
	{
		B3_ASSERT( faceCount <= B3_HULL_LIMIT - 1 );

		b3QHFace* face = (b3QHFace*)faceNode;
		face->finalIndex = faceCount;
		tempFaces[faceCount++] = face;

		b3QHHalfEdge* edge = face->edge;
		do
		{
			if ( edge->finalIndex < 0 )
			{
				B3_ASSERT( edgeCount + 1 <= B3_HULL_LIMIT - 1 );

				edge->finalIndex = edgeCount;
				tempEdges[edgeCount++] = edge;
				edge->twin->finalIndex = edgeCount;
				tempEdges[edgeCount++] = edge->twin;
			}
			edge = edge->next;
		}
		while ( edge != face->edge );
	}

	// Allocate the hull. Arrays hang off the end.
	size_t byteCount = b3AlignUp8( sizeof( b3HullData ) );
	int vertexOffset = (int)byteCount;
	byteCount += b3AlignUp8( vertexCount * (int)sizeof( b3HullVertex ) );
	int pointOffset = (int)byteCount;
	byteCount += b3AlignUp8( vertexCount * (int)sizeof( b3Vec3 ) );
	int edgeOffset = (int)byteCount;
	byteCount += b3AlignUp8( edgeCount * (int)sizeof( b3HullHalfEdge ) );
	int faceOffset = (int)byteCount;
	byteCount += b3AlignUp8( faceCount * (int)sizeof( b3HullFace ) );
	int planeOffset = (int)byteCount;
	byteCount += b3AlignUp8( faceCount * (int)sizeof( b3Plane ) );

	b3HullData* hull = b3Alloc( byteCount );
	memset( hull, 0, byteCount );

	hull->version = B3_HULL_VERSION;
	hull->vertexOffset = vertexOffset;
	hull->pointOffset = pointOffset;
	hull->edgeOffset = edgeOffset;
	hull->faceOffset = faceOffset;
	hull->planeOffset = planeOffset;

	hull->vertexCount = vertexCount;
	hull->edgeCount = edgeCount;
	hull->faceCount = faceCount;

	hull->byteCount = (int)byteCount;

	b3HullVertex* vertices = b3GetHullVerticesWrite( hull );
	b3HullHalfEdge* edges = b3GetHullEdgesWrite( hull );
	b3HullFace* faces = (b3HullFace*)( (intptr_t)hull + hull->faceOffset );
	b3Vec3* finalPoints = b3GetHullPointsWrite( hull );
	b3Plane* planes = b3GetHullPlanesWrite( hull );

	for ( int index = 0; index < vertexCount; ++index )
	{
		vertices[index].edge = 0;
		finalPoints[index] = tempVertices[index]->position;
	}

	for ( int index = 0; index < edgeCount; ++index )
	{
		const b3QHHalfEdge* edge = tempEdges[index];
		B3_ASSERT( 0 <= edge->next->finalIndex && edge->next->finalIndex <= UINT8_MAX );
		B3_ASSERT( 0 <= edge->twin->finalIndex && edge->twin->finalIndex <= UINT8_MAX );
		B3_ASSERT( 0 <= edge->face->finalIndex && edge->face->finalIndex <= UINT8_MAX );
		B3_ASSERT( 0 <= edge->origin->finalIndex && edge->origin->finalIndex <= UINT8_MAX );

		edges[index].next = (uint8_t)edge->next->finalIndex;
		edges[index].twin = (uint8_t)edge->twin->finalIndex;
		edges[index].face = (uint8_t)edge->face->finalIndex;
		edges[index].origin = (uint8_t)edge->origin->finalIndex;

		vertices[edge->origin->finalIndex].edge = (uint8_t)index;
	}

	for ( int index = 0; index < faceCount; ++index )
	{
		const b3QHFace* face = tempFaces[index];
		B3_ASSERT( 0 <= face->edge->finalIndex && face->edge->finalIndex <= UINT8_MAX );

		faces[index].edge = (uint8_t)face->edge->finalIndex;
		planes[index] = face->plane;
	}

	// All builder pointers are dead from here on.
	b3Free( work, sizes.totalBytes );

	b3UpdateHullBounds( hull );
	bool success = b3UpdateHullBulkProperties( hull );
	if ( success == false )
	{
		b3DestroyHull( hull );
		return NULL;
	}

	if ( b3IsValidHull( hull ) == false )
	{
		b3DestroyHull( hull );
		return NULL;
	}

	hull->hash = 0;
	hull->hash = b3NonZeroHash( b3Hash( B3_HASH_INIT, (uint8_t*)hull, hull->byteCount ) );

	return hull;
}

b3HullData* b3CloneHull( const b3HullData* hull )
{
	if ( hull == NULL || b3IsValidHull( hull ) == false )
	{
		return NULL;
	}

	b3HullData* clone = (b3HullData*)b3Alloc( hull->byteCount );
	memcpy( clone, hull, hull->byteCount );

	return clone;
}

uint64_t b3HashHullData( const b3HullData* hull )
{
	// The baked content hash already covers byteCount. Spread the 32 bits across 64 so the table
	// can use the high bits for its fast reject fragment.
	return (uint64_t)hull->hash * 0x9E3779B97F4A7C15ull;
}

bool b3CompareHullData( const b3HullData* hull1, const b3HullData* hull2 )
{
	if ( hull1 == hull2 )
	{
		return true;
	}

	if ( hull1->byteCount != hull2->byteCount )
	{
		return false;
	}

	return memcmp( hull1, hull2, hull1->byteCount ) == 0;
}

// Hull identity covers every byte, so the structs carry explicit padding. These lock
// the layout, re-audit padding if a size changes.
_Static_assert( sizeof( b3HullData ) == 136, "unexpected hull data size" );
_Static_assert( sizeof( b3BoxHull ) == 440, "unexpected box hull size" );

#define NAME b3HullMap
#define KEY_TY const b3HullData*
#define VAL_TY int
#define HASH_FN b3HashHullData
#define CMPR_FN b3CompareHullData
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#define IMPLEMENTATION_MODE
#include "verstable.h"

size_t b3HullMapByteCount( b3HullMap* map )
{
	// The map owns a combined bucket and metadata allocation, valid only when buckets exist
	size_t byteCount = sizeof( b3HullMap );
	if ( b3HullMap_bucket_count( map ) > 0 )
	{
		byteCount += b3HullMap_total_alloc_size( map );
	}
	return byteCount;
}

b3HullData* b3CloneAndTransformHull( const b3HullData* original, b3Transform transform, b3Vec3 scale )
{
	if ( original == NULL || b3IsValidHull( original ) == false )
	{
		return NULL;
	}

	b3HullData* hull = (b3HullData*)b3Alloc( original->byteCount );
	memcpy( hull, original, original->byteCount );

	b3Vec3 safeScale = b3SafeScale( scale );

	b3HullHalfEdge* edges = b3GetHullEdgesWrite( hull );
	const b3HullFace* faces = b3GetHullFaces( hull );
	int faceCount = hull->faceCount;
	int vertexCount = hull->vertexCount;

	if ( safeScale.x * safeScale.y * safeScale.z < 0.0f )
	{
		// Reflected: reverse edge winding for each face.
		for ( int i = 0; i < faceCount; ++i )
		{
			const b3HullFace* face = faces + i;

			uint8_t startEdgeIndex = face->edge;
			uint8_t currentEdgeIndex = startEdgeIndex;
			uint8_t prevEdgeIndex = UINT8_MAX;

			do
			{
				b3HullHalfEdge* edge = edges + currentEdgeIndex;

				if ( edge->next == startEdgeIndex )
				{
					prevEdgeIndex = currentEdgeIndex;
					break;
				}

				currentEdgeIndex = edge->next;
			}
			while ( currentEdgeIndex != startEdgeIndex );

			B3_ASSERT( prevEdgeIndex != UINT8_MAX );

			currentEdgeIndex = startEdgeIndex;

			do
			{
				b3HullHalfEdge* edge = edges + currentEdgeIndex;
				uint8_t nextIndex = edge->next;
				edge->next = prevEdgeIndex;

				if ( currentEdgeIndex < edge->twin )
				{
					b3HullHalfEdge* twin = edges + edge->twin;
					B3_SWAP( edge->origin, twin->origin );
				}

				prevEdgeIndex = currentEdgeIndex;
				currentEdgeIndex = nextIndex;
			}
			while ( currentEdgeIndex != startEdgeIndex );
		}

		b3HullVertex* vertices = b3GetHullVerticesWrite( hull );

		for ( int i = 0; i < vertexCount; ++i )
		{
			b3HullVertex* vertex = vertices + i;
			const b3HullHalfEdge* edge = edges + vertex->edge;
			vertex->edge = edge->twin;
		}
	}

	b3Matrix3 matrix = b3MakeMatrixFromQuat( transform.q );
	b3Vec3* points = b3GetHullPointsWrite( hull );

	for ( int i = 0; i < vertexCount; ++i )
	{
		points[i] = b3Add( b3MulMV( matrix, b3Mul( safeScale, points[i] ) ), transform.p );
	}

	b3Plane* planes = b3GetHullPlanesWrite( hull );

	for ( int i = 0; i < faceCount; ++i )
	{
		int count = 0;
		b3Vec3 centroid = b3Vec3_zero;
		b3Vec3 normal = b3Vec3_zero;

		const b3HullFace* face = faces + i;
		uint8_t startEdgeIndex = face->edge;
		uint8_t currentEdgeIndex = startEdgeIndex;

		const b3HullHalfEdge* startEdge = edges + currentEdgeIndex;
		B3_ASSERT( startEdge->face == i );
		B3_ASSERT( startEdge->origin < vertexCount );

		b3Vec3 origin = points[startEdge->origin];

		do
		{
			b3HullHalfEdge* edge = edges + currentEdgeIndex;
			b3HullHalfEdge* twin = edges + edge->twin;
			B3_ASSERT( twin->twin == currentEdgeIndex );

			b3Vec3 v1 = b3Sub( points[edge->origin], origin );
			b3Vec3 v2 = b3Sub( points[twin->origin], origin );

			count++;
			centroid = b3Add( centroid, v1 );
			normal.x += ( v1.y - v2.y ) * ( v1.z + v2.z );
			normal.y += ( v1.z - v2.z ) * ( v1.x + v2.x );
			normal.z += ( v1.x - v2.x ) * ( v1.y + v2.y );

			currentEdgeIndex = edge->next;
		}
		while ( currentEdgeIndex != startEdgeIndex );

		B3_ASSERT( count > 0 );
		centroid = b3MulSV( 1.0f / (float)count, centroid );
		centroid = b3Add( centroid, origin );

		float area = b3Length( normal );
		B3_ASSERT( area > 0.0f );
		normal = b3MulSV( 1.0f / area, normal );

		planes[i] = b3MakePlaneFromNormalAndPoint( normal, centroid );
	}

	b3UpdateHullBounds( hull );
	bool success = b3UpdateHullBulkProperties( hull );
	if ( success == false )
	{
		b3Free( hull, original->byteCount );
		return NULL;
	}

	hull->hash = 0;
	hull->hash = b3NonZeroHash( b3Hash( B3_HASH_INIT, (uint8_t*)hull, hull->byteCount ) );

	B3_VALIDATE( b3IsValidHull( hull ) );

	return hull;
}

void b3DestroyHull( b3HullData* hull )
{
	b3Free( hull, hull->byteCount );
}

b3MassData b3ComputeHullMass( const b3HullData* shape, float density )
{
	b3MassData out;
	out.mass = density * shape->volume;
	out.center = shape->center;

	// Inertia about the center of mass
	out.inertia = b3MulSM( density, shape->centralInertia );
	return out;
}

b3AABB b3ComputeHullAABB( const b3HullData* shape, b3Transform transform )
{
	return b3AABB_Transform( transform, shape->aabb );
}

b3AABB b3ComputeSweptHullAABB( const b3HullData* shape, b3Transform xf1, b3Transform xf2 )
{
	b3AABB aabb1 = b3AABB_Transform( xf1, shape->aabb );
	b3AABB aabb2 = b3AABB_Transform( xf2, shape->aabb );
	return b3AABB_Union( aabb1, aabb2 );
}

bool b3OverlapHull( const b3HullData* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy )
{
	const b3Vec3* points = b3GetHullPoints( shape );

	b3DistanceInput input;
	input.proxyA = (b3ShapeProxy){ points, shape->vertexCount, 0.0f };
	input.proxyB = *proxy;
	input.transform = b3InvMulTransforms( shapeTransform, b3Transform_identity );
	input.useRadii = true;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );
	return output.distance < B3_OVERLAP_SLOP;
}

b3CastOutput b3RayCastHull( const b3HullData* shape, const b3RayCastInput* input )
{
	B3_ASSERT( b3IsValidRay( input ) );
	b3CastOutput output = { 0 };

	float lower = 0.0f;
	float upper = input->maxFraction;
	int bestFace = B3_NULL_INDEX;

	const b3Plane* planes = b3GetHullPlanes( shape );

	for ( int faceIndex = 0; faceIndex < shape->faceCount; ++faceIndex )
	{
		b3Plane plane = planes[faceIndex];

		float distance = plane.offset - b3Dot( plane.normal, input->origin );
		float denominator = b3Dot( plane.normal, input->translation );

		if ( denominator == 0.0f )
		{
			if ( distance < 0.0f )
			{
				return output;
			}
		}
		else
		{
			float fraction = distance / denominator;

			if ( denominator < 0.0f )
			{
				if ( fraction > lower )
				{
					bestFace = faceIndex;
					lower = fraction;
				}
			}
			else
			{
				if ( fraction < upper )
				{
					upper = fraction;
				}
			}

			if ( upper < lower )
			{
				return output;
			}
		}
	}

	if ( bestFace >= 0 )
	{
		output.point = b3Add( input->origin, b3MulSV( lower, input->translation ) );
		output.normal = planes[bestFace].normal;
		output.fraction = lower;
		output.hit = true;
	}
	else
	{
		output.point = input->origin;
		output.hit = true;
	}

	return output;
}

b3CastOutput b3ShapeCastHull( const b3HullData* shape, const b3ShapeCastInput* input )
{
	const b3Vec3* points = b3GetHullPoints( shape );

	b3ShapeCastPairInput pairInput;
	pairInput.proxyA = (b3ShapeProxy){ points, shape->vertexCount, 0.0f };
	pairInput.proxyB = input->proxy;
	pairInput.transform = b3Transform_identity;
	pairInput.translationB = input->translation;
	pairInput.maxFraction = input->maxFraction;
	pairInput.canEncroach = input->canEncroach;

	b3CastOutput output = b3ShapeCast( &pairInput );
	return output;
}

int b3CollideMoverAndHull( b3PlaneResult* result, const b3HullData* shape, const b3Capsule* mover )
{
	const b3Vec3* points = b3GetHullPoints( shape );
	b3DistanceInput distanceInput;
	distanceInput.proxyA = (b3ShapeProxy){ points, shape->vertexCount, 0.0f };
	distanceInput.proxyB = (b3ShapeProxy){ &mover->center1, 2, mover->radius };
	distanceInput.transform = b3Transform_identity;
	distanceInput.useRadii = false;

	float totalRadius = mover->radius;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, &cache, NULL, 0 );

	if ( distanceOutput.distance == 0.0f )
	{
		// I could handle deep overlap on hulls, but there is no reasonable solution for
		// deep overlap on meshes. So if someone converted a hull to a mesh there would be
		// different behavior. So I think there is not a good reason to handle deep overlap
		// on hulls.
		return 0;
	}

	if ( distanceOutput.distance <= totalRadius )
	{
		b3Plane plane = { distanceOutput.normal, totalRadius - distanceOutput.distance };
		*result = (b3PlaneResult){ plane, distanceOutput.pointA };
		return 1;
	}

	return 0;
}

b3ShapeExtent b3ComputeHullExtent( const b3HullData* hull, b3Vec3 origin )
{
	const b3Vec3* points = b3GetHullPoints( hull );

	b3ShapeExtent extent;
	extent.minExtent = hull->innerRadius;
	extent.maxExtent = b3Vec3_zero;
	for ( int index = 0; index < hull->vertexCount; ++index )
	{
		b3Vec3 point = points[index];
		extent.maxExtent = b3Max( extent.maxExtent, b3Abs( b3Sub( point, origin ) ) );
	}

	return extent;
}

float b3ComputeHullProjectedArea( const b3HullData* hull, b3Vec3 direction )
{
	float area = 0.0f;

	int faceCount = hull->faceCount;
	const b3HullFace* hullFaces = b3GetHullFaces( hull );
	const b3HullHalfEdge* hullEdges = b3GetHullEdges( hull );
	const b3Vec3* hullPoints = b3GetHullPoints( hull );

	for ( int i = 0; i < faceCount; ++i )
	{
		const b3HullFace* face = hullFaces + i;

		int baseEdge = face->edge;
		const b3HullHalfEdge* edge = hullEdges + baseEdge;
		b3Vec3 p1 = hullPoints[edge->origin];

		int edgeIndex = edge->next;
		edge = hullEdges + edgeIndex;
		b3Vec3 p2 = hullPoints[edge->origin];

		edgeIndex = edge->next;

		do
		{
			edge = hullEdges + edgeIndex;
			b3Vec3 p3 = hullPoints[edge->origin];

			b3Vec3 e1 = b3Sub( p2, p1 );
			b3Vec3 e2 = b3Sub( p3, p1 );
			b3Vec3 n = b3Cross( e1, e2 );
			float a = b3Dot( n, direction );
			area += b3MaxFloat( a, 0.0f );

			p2 = p3;
			edgeIndex = edge->next;
		}
		while ( edgeIndex != baseEdge );
	}

	return 0.5f * area;
}

// Constant template box (vertex/edge/face/topology). b3MakeTransformedBoxHull copies and
// fills in the runtime-dependent fields (boxPoints, boxPlanes, aabb, mass properties, hash).
static const b3BoxHull s_boxHull = {
	.base =
		{
			.version = B3_HULL_VERSION,
			.byteCount = sizeof( b3BoxHull ),
			.hash = 0,
			.vertexCount = 8,
			.edgeCount = 24,
			.faceCount = 6,
			.vertexOffset = offsetof( b3BoxHull, boxVertices ),
			.pointOffset = offsetof( b3BoxHull, boxPoints ),
			.edgeOffset = offsetof( b3BoxHull, boxEdges ),
			.faceOffset = offsetof( b3BoxHull, boxFaces ),
			.planeOffset = offsetof( b3BoxHull, boxPlanes ),
		},
	.boxVertices =
		{
			[0] = { .edge = 8 },
			[1] = { .edge = 1 },
			[2] = { .edge = 0 },
			[3] = { .edge = 9 },
			[4] = { .edge = 13 },
			[5] = { .edge = 3 },
			[6] = { .edge = 5 },
			[7] = { .edge = 11 },
		},
	.boxEdges =
		{
			[0] = { 2, 1, 2, 0 },	 [1] = { 17, 0, 1, 5 },	  [2] = { 4, 3, 1, 0 },	   [3] = { 20, 2, 5, 3 },
			[4] = { 6, 5, 5, 0 },	 [5] = { 23, 4, 6, 4 },	  [6] = { 0, 7, 6, 0 },	   [7] = { 18, 6, 2, 2 },
			[8] = { 10, 9, 0, 1 },	 [9] = { 21, 8, 3, 5 },	  [10] = { 12, 11, 3, 1 }, [11] = { 16, 10, 7, 2 },
			[12] = { 14, 13, 7, 1 }, [13] = { 19, 12, 4, 4 }, [14] = { 8, 15, 4, 1 },  [15] = { 22, 14, 0, 3 },
			[16] = { 7, 17, 3, 2 },	 [17] = { 9, 16, 2, 5 },  [18] = { 11, 19, 6, 2 }, [19] = { 5, 18, 7, 4 },
			[20] = { 15, 21, 1, 3 }, [21] = { 1, 20, 0, 5 },  [22] = { 3, 23, 4, 3 },  [23] = { 13, 22, 5, 4 },
		},
	.boxFaces =
		{
			[0] = { .edge = 0 },
			[1] = { .edge = 8 },
			[2] = { .edge = 16 },
			[3] = { .edge = 20 },
			[4] = { .edge = 19 },
			[5] = { .edge = 21 },
		},
};

b3BoxHull b3MakeTransformedBoxHull( float hx, float hy, float hz, b3Transform transform )
{
	b3BoxHull boxHull = s_boxHull;

	float minH = 0.2f * B3_LINEAR_SLOP;
	b3Vec3 h = b3Max( (b3Vec3){ minH, minH, minH }, (b3Vec3){ hx, hy, hz } );

	boxHull.base.aabb = b3AABB_Transform( transform, (b3AABB){ b3Neg( h ), h } );
	boxHull.base.surfaceArea = 8.0f * ( h.x * h.y + h.x * h.z + h.y * h.z );
	boxHull.base.volume = 8.0f * h.x * h.y * h.z;
	boxHull.base.innerRadius = b3MinFloat( h.x, b3MinFloat( h.y, h.z ) );
	boxHull.base.center = transform.p;

	b3Matrix3 boxInertia = b3BoxInertia( boxHull.base.volume, b3Neg( h ), h );
	boxHull.base.centralInertia = b3RotateInertia( transform.q, boxInertia );

	b3Vec3 lower = b3Neg( h );
	b3Vec3 upper = h;

	boxHull.boxPlanes[0] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Neg( b3Vec3_axisX ), lower ) );
	boxHull.boxPlanes[1] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Vec3_axisX, upper ) );
	boxHull.boxPlanes[2] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Neg( b3Vec3_axisY ), lower ) );
	boxHull.boxPlanes[3] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Vec3_axisY, upper ) );
	boxHull.boxPlanes[4] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Neg( b3Vec3_axisZ ), lower ) );
	boxHull.boxPlanes[5] = b3TransformPlane( transform, b3MakePlaneFromNormalAndPoint( b3Vec3_axisZ, upper ) );

	boxHull.boxPoints[0] = b3TransformPoint( transform, (b3Vec3){ h.x, h.y, h.z } );
	boxHull.boxPoints[1] = b3TransformPoint( transform, (b3Vec3){ -h.x, h.y, h.z } );
	boxHull.boxPoints[2] = b3TransformPoint( transform, (b3Vec3){ -h.x, -h.y, h.z } );
	boxHull.boxPoints[3] = b3TransformPoint( transform, (b3Vec3){ h.x, -h.y, h.z } );
	boxHull.boxPoints[4] = b3TransformPoint( transform, (b3Vec3){ h.x, h.y, -h.z } );
	boxHull.boxPoints[5] = b3TransformPoint( transform, (b3Vec3){ -h.x, h.y, -h.z } );
	boxHull.boxPoints[6] = b3TransformPoint( transform, (b3Vec3){ -h.x, -h.y, -h.z } );
	boxHull.boxPoints[7] = b3TransformPoint( transform, (b3Vec3){ h.x, -h.y, -h.z } );

	boxHull.base.hash = 0;
	boxHull.base.hash = b3NonZeroHash( b3Hash( B3_HASH_INIT, (uint8_t*)&boxHull, sizeof( b3BoxHull ) ) );

	return boxHull;
}

b3BoxHull b3MakeCubeHull( float halfWidth )
{
	return b3MakeBoxHull( halfWidth, halfWidth, halfWidth );
}

b3BoxHull b3MakeOffsetBoxHull( float hx, float hy, float hz, b3Vec3 offset )
{
	b3Transform transform = { .p = offset, .q = b3Quat_identity };
	return b3MakeTransformedBoxHull( hx, hy, hz, transform );
}

b3BoxHull b3MakeBoxHull( float hx, float hy, float hz )
{
	return b3MakeTransformedBoxHull( hx, hy, hz, b3Transform_identity );
}

void b3ScaleBox( b3Vec3* halfWidths, b3Transform* transform, b3Vec3 postScale, float minHalfWidth )
{
	B3_ASSERT( b3IsValidFloat( minHalfWidth ) && minHalfWidth > 0.0f );

	b3Quat q = transform->q;

	if ( postScale.x < 0.0f || postScale.y < 0.0f || postScale.z < 0.0f )
	{
		// todo this might be unnecessary if rotation is identity
		// todo compare with polar decomposition (much more expensive)
		b3Matrix3 m = b3MakeMatrixFromQuat( q );
		m.cx.x *= postScale.x;
		m.cy.x *= postScale.x;
		m.cz.x *= postScale.x;
		m.cx.y *= postScale.y;
		m.cy.y *= postScale.y;
		m.cz.y *= postScale.y;
		m.cx.z *= postScale.z;
		m.cy.z *= postScale.z;
		m.cz.z *= postScale.z;
		m.cx = b3Normalize( m.cx );
		m.cy = b3Normalize( m.cy );
		m.cz = b3Normalize( m.cz );
		m.cx = postScale.x < 0.0f ? b3Neg( m.cx ) : m.cx;
		m.cy = postScale.y < 0.0f ? b3Neg( m.cy ) : m.cy;
		m.cz = postScale.z < 0.0f ? b3Neg( m.cz ) : m.cz;
		q = b3MakeQuatFromMatrix( &m );
	}

	b3Vec3 absScale = b3Abs( postScale );

	b3Vec3 h = *halfWidths;
	b3Vec3 p1 = b3Mul( absScale, b3RotateVector( q, b3Neg( h ) ) );
	b3Vec3 p2 = b3Mul( absScale, b3RotateVector( q, h ) );

	b3Vec3 localP1 = b3InvRotateVector( q, p1 );
	b3Vec3 localP2 = b3InvRotateVector( q, p2 );

	b3Vec3 lower = b3Min( localP1, localP2 );
	b3Vec3 upper = b3Max( localP1, localP2 );

	b3Vec3 scaledHalfWidth = b3MulSV( 0.5f, b3Sub( upper, lower ) );

	b3Vec3 mLimit = { minHalfWidth, minHalfWidth, minHalfWidth };
	*halfWidths = b3Max( scaledHalfWidth, mLimit );
	transform->p = b3Mul( postScale, transform->p );
	transform->q = q;
}

// todo use new hull scaling technique
b3BoxHull b3MakeScaledBoxHull( b3Vec3 halfWidths, b3Transform transform, b3Vec3 postScale )
{
	b3Vec3 h = halfWidths;
	b3Transform xf = transform;
	b3ScaleBox( &h, &xf, postScale, 4.0f * B3_LINEAR_SLOP );
	return b3MakeTransformedBoxHull( h.x, h.y, h.z, xf );
}
