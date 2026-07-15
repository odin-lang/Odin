// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "contact.h"
#include "manifold.h"
#include "physics_world.h"
#include "qsort.h"
#include "shape.h"

#include "box3d/types.h"

#include <stdio.h>

// This guards against excessive memory usage and complex collision
#define B3_MAX_MESH_CONTACT_TRIANGLES 256
#define B3_MAX_POINTS_PER_TRIANGLE 32

#if B3_ENABLE_VALIDATION
static bool b3IsSorted( const int* array, int count )
{
	for ( int i = 0; i < count - 1; ++i )
	{
		if ( array[i] >= array[i + 1] )
		{
			return false;
		}
	}

	return true;
}
#endif

typedef struct b3TriangleQueryContext
{
	int* indices;
	int capacity;
	int count;
} b3TriangleQueryContext;

static bool b3CollectTriangleIndicesCallback( b3Vec3 a, b3Vec3 b, b3Vec3 c, int triangleIndex, void* context )
{
	B3_UNUSED( a, b, c );
	b3TriangleQueryContext* triangleContext = (b3TriangleQueryContext*)context;
	if ( triangleContext->count == triangleContext->capacity )
	{
		return false;
	}
	triangleContext->indices[triangleContext->count] = triangleIndex;
	triangleContext->count += 1;
	return triangleContext->count < triangleContext->capacity;
}

static int b3QueryMeshTriangles( int* indices, int capacity, const b3Mesh* mesh, b3AABB bounds )
{
	b3TriangleQueryContext context = {
		.indices = indices,
		.capacity = capacity,
		.count = 0,
	};

	b3QueryMesh( mesh, bounds, b3CollectTriangleIndicesCallback, &context );
	return context.count;
}

static int b3QueryHeightFieldTriangles( int* indices, int capacity, const b3HeightFieldData* heightField, b3AABB bounds )
{
	b3TriangleQueryContext context = {
		.indices = indices,
		.capacity = capacity,
		.count = 0,
	};

	b3QueryHeightField( heightField, bounds, b3CollectTriangleIndicesCallback, &context );
	return context.count;
}

static void b3RefreshCache( b3Contact* contact, const b3Shape* shapeA, b3WorldTransform xfA, const b3AABB* bounds )
{
	B3_ASSERT( shapeA->type == b3_meshShape || shapeA->type == b3_heightShape );

	b3MeshContact* meshContact = &contact->meshContact;

	// If the dynamic body didn't move out of the cached query bounds we are done!
	if ( b3AABB_Contains( meshContact->queryBounds, *bounds ) )
	{
		if ( shapeA->type == b3_meshShape )
		{
			for ( int i = 0; i < contact->meshContact.triangleCache.count; ++i )
			{
				B3_ASSERT( 0 <= contact->meshContact.triangleCache.data[i].triangleIndex &&
						   contact->meshContact.triangleCache.data[i].triangleIndex < shapeA->mesh.data->triangleCount );
			}
		}

		return;
	}

	// Enlarge to the query bounds to absorb small movement
	float radius = B3_MAX_AABB_MARGIN + B3_SPECULATIVE_DISTANCE;
	b3Vec3 extension = { radius, radius, radius };
	meshContact->queryBounds.lowerBound = b3Sub( bounds->lowerBound, extension );
	meshContact->queryBounds.upperBound = b3Add( bounds->upperBound, extension );

	// Query triangles
	int triangleCapacity = B3_MAX_MESH_CONTACT_TRIANGLES;

	int triangleIndices[B3_MAX_MESH_CONTACT_TRIANGLES];

	// Bounds are in world space. Convert to the local mesh frame. The broadphase bounds are float,
	// so the demoted mesh transform is the matching float world frame (exact in float mode).
	b3Transform meshTransform = b3ToRelativeTransform( xfA, b3Pos_zero );
	b3AABB localBounds = b3AABB_Transform( b3InvertTransform( meshTransform ), meshContact->queryBounds );
	int triangleCount;
	if ( shapeA->type == b3_meshShape )
	{
		triangleCount = b3QueryMeshTriangles( triangleIndices, triangleCapacity, &shapeA->mesh, localBounds );
	}
	else
	{
		B3_ASSERT( shapeA->type == b3_heightShape );
		triangleCount = b3QueryHeightFieldTriangles( triangleIndices, triangleCapacity, shapeA->heightField, localBounds );
	}

	if ( triangleCount == triangleCapacity )
	{
		static bool s_once = false;
		if ( s_once == false )
		{
			b3Log( "WARNING: complex mesh detected, triangle buffer capacity of %d reached", triangleCapacity );
			s_once = true;
		}
	}

	// Triangle indices must be sorted to match caches.
	B3_VALIDATE( b3IsSorted( triangleIndices, triangleCount ) );

	// Create new contact cache and match with old one
	b3ContactCache contactCache[B3_MAX_MESH_CONTACT_TRIANGLES];

	int index2 = 0;
	for ( int index1 = 0; index1 < triangleCount; ++index1 )
	{
		contactCache[index1] = (b3ContactCache){ 0 };

		while ( index2 < contact->meshContact.triangleCache.count &&
				contact->meshContact.triangleCache.data[index2].triangleIndex < triangleIndices[index1] )
		{
			index2 += 1;
		}

		if ( index2 < contact->meshContact.triangleCache.count &&
			 contact->meshContact.triangleCache.data[index2].triangleIndex == triangleIndices[index1] )
		{
			contactCache[index1] = contact->meshContact.triangleCache.data[index2].cache;
		}
	}

	// Save new cache
	b3Array_Resize( contact->meshContact.triangleCache, triangleCount );
	for ( int i = 0; i < triangleCount; ++i )
	{
		contact->meshContact.triangleCache.data[i] = (b3TriangleCache){ triangleIndices[i], contactCache[i] };

		if ( shapeA->type == b3_meshShape )
		{
			B3_ASSERT( 0 <= contact->meshContact.triangleCache.data[i].triangleIndex &&
					   contact->meshContact.triangleCache.data[i].triangleIndex < shapeA->mesh.data->triangleCount );
		}
	}
}

typedef struct b3TentativeTriangle
{
	float squaredDistance;
	int index;
} b3TentativeTriangle;

#define B3_MAX_EDGE_COUNT 64

typedef struct b3FoundEdges
{
	uint64_t keys[B3_MAX_EDGE_COUNT];
	int count;
} b3FoundEdges;

static inline bool b3AddEdge( b3FoundEdges* edges, int vertex1, int vertex2 )
{
	uint64_t i1 = (uint64_t)b3MinInt( vertex1, vertex2 );
	uint64_t i2 = (uint64_t)b3MaxInt( vertex1, vertex2 );
	uint64_t key = i1 << 32 | i2;

	int count = edges->count;
	for ( int i = 0; i < count; ++i )
	{
		if ( edges->keys[i] == key )
		{
			return false;
		}
	}

	if ( count == B3_MAX_EDGE_COUNT )
	{
		// This will lead to a potential ghost collision
		return true;
	}

	edges->keys[count] = key;
	edges->count += 1;

	return true;
}

static inline bool b3FindEdge( b3FoundEdges* edges, int vertex1, int vertex2 )
{
	uint64_t i1 = (uint64_t)b3MinInt( vertex1, vertex2 );
	uint64_t i2 = (uint64_t)b3MaxInt( vertex1, vertex2 );
	uint64_t key = i1 << 32 | i2;

	int count = edges->count;
	for ( int i = 0; i < count; ++i )
	{
		if ( edges->keys[i] == key )
		{
			return true;
		}
	}

	return false;
}

#if 0
// Two triangles share an edge iff they share at least two vertex indices.
static inline bool b3TrianglesShareEdge( int a1, int a2, int a3, int b1, int b2, int b3 )
{
	int matches = 0;
	matches += ( a1 == b1 || a1 == b2 || a1 == b3 );
	matches += ( a2 == b1 || a2 == b2 || a2 == b3 );
	matches += ( a3 == b1 || a3 == b2 || a3 == b3 );
	return matches >= 2;
}
#endif

#define B3_MAX_VERTEX_COUNT 64

typedef struct b3FoundVertices
{
	int keys[B3_MAX_VERTEX_COUNT];
	int count;
} b3FoundVertices;

static inline bool b3AddVertex( b3FoundVertices* vertices, int vertex )
{
	int key = vertex;

	int count = vertices->count;
	for ( int i = 0; i < count; ++i )
	{
		if ( vertices->keys[i] == key )
		{
			return false;
		}
	}

	if ( count == B3_MAX_VERTEX_COUNT )
	{
		// This will lead to a potential ghost collision
		return true;
	}

	vertices->keys[count] = key;
	vertices->count += 1;

	return true;
}

// Returns true if (score, separation) should replace (bestScore, bestSeparation).
static inline bool b3IsBetterCullCandidate( float score, float separation, float bestScore, float bestSeparation, float scoreTol,
											float separationTol )
{
	if ( score > bestScore + scoreTol )
	{
		return true;
	}
	if ( score < bestScore - scoreTol )
	{
		return false;
	}

	// Break the tie using separation
	return separation < bestSeparation - separationTol;
}

typedef struct b3Point2D
{
	b3Vec2 p;
	float separation;
	int originalIndex;
} b3Point2D;

static int b3CullPoints( b3Point2D* points, int count )
{
	if ( count <= 1 )
	{
		return count;
	}

	float tol = 0.25f * B3_LINEAR_SLOP;
	float tolSqr = tol * tol;
	float separationTol = B3_LINEAR_SLOP;

	b3Point2D finalPoints[4];
	int count1 = count;

	// Step 1: the two points with the largest distance, ties broken by deepest combined separation
	float bestScore = 0.0f;
	float bestSeparation = FLT_MAX;
	int bestIndex1 = B3_NULL_INDEX;
	int bestIndex2 = B3_NULL_INDEX;

	for ( int i = 0; i < count1; ++i )
	{
		b3Vec2 p1 = points[i].p;
		for ( int j = i + 1; j < count1; ++j )
		{
			float score = b3DistanceSquared2( p1, points[j].p );
			// Separation sum heuristic
			float separation = points[i].separation + points[j].separation;

			if ( b3IsBetterCullCandidate( score, separation, bestScore, bestSeparation, tolSqr, separationTol ) )
			{
				bestIndex1 = i;
				bestIndex2 = j;
				bestScore = score;
				bestSeparation = separation;
			}
		}
	}

	if ( bestScore < tolSqr )
	{
		// Choose deepest point
		int deepestIndex = 0;
		for ( int i = 1; i < count1; ++i )
		{
			if ( points[i].separation < points[deepestIndex].separation )
			{
				deepestIndex = i;
			}
		}

		if ( deepestIndex != 0 )
		{
			points[0] = points[deepestIndex];
		}
		return 1;
	}

	finalPoints[0] = points[bestIndex1];
	finalPoints[1] = points[bestIndex2];

	// Cull
	points[bestIndex2] = points[count1 - 1];
	points[bestIndex1] = points[count1 - 2];
	count1 -= 2;

	if ( count1 == 0 )
	{
		points[0] = finalPoints[0];
		points[1] = finalPoints[1];
		return 2;
	}

	// First anchor point
	b3Vec2 a = finalPoints[0].p;

	// Second anchor point
	b3Vec2 b = finalPoints[1].p;
	b3Vec2 ba = b3Sub2( b, a );
	// float length = b3Length2( ba );
	// float areaTol = tol * length;

	// Step 2: find the point with the maximum triangular area, ties broken by deepest separation
	bestScore = 0.0f;
	bestSeparation = FLT_MAX;
	int bestIndex = B3_NULL_INDEX;
	float bestSignedArea = 0.0f;
	for ( int i = 0; i < count1; ++i )
	{
		b3Vec2 p = points[i].p;
		float signedArea = b3Cross2( ba, b3Sub2( p, a ) );
		float score = b3AbsFloat( signedArea );

		if ( b3IsBetterCullCandidate( score, points[i].separation, bestScore, bestSeparation, tolSqr, separationTol ) )
		{
			bestSignedArea = signedArea;
			bestScore = score;
			bestSeparation = points[i].separation;
			bestIndex = i;
		}
	}

	if ( bestIndex == B3_NULL_INDEX )
	{
		// All points collinear
		points[0] = finalPoints[0];
		points[1] = finalPoints[1];
		return 2;
	}

	// Store best point
	finalPoints[2] = points[bestIndex];

	if ( count1 == 1 )
	{
		points[0] = finalPoints[0];
		points[1] = finalPoints[1];
		points[2] = finalPoints[2];
		return 3;
	}

	// Cull
	points[bestIndex] = points[count1 - 1];
	count1 -= 1;

	// Step 4: get the point that adds the most area outside the current triangle

	// Third anchor
	b3Vec2 c = finalPoints[2].p;

	// Ensure CCW ordering
	if ( bestSignedArea < 0.0f )
	{
		B3_SWAP( b, c );
		ba = b3Sub2( b, a );
	}

	b3Vec2 cb = b3Sub2( c, b );
	b3Vec2 ac = b3Sub2( a, c );

	bestScore = 0.0f;
	bestSeparation = FLT_MAX;
	bestIndex = B3_NULL_INDEX;
	for ( int i = 0; i < count1; ++i )
	{
		b3Vec2 p = points[i].p;
		float u1 = b3Cross2( b3Sub2( p, a ), ba );
		float u2 = b3Cross2( b3Sub2( p, b ), cb );
		float u3 = b3Cross2( b3Sub2( p, c ), ac );
		float score = b3MaxFloat( u1, b3MaxFloat( u2, u3 ) );

		// Use the area tolerance for collinear points and hysteresis
		if ( b3IsBetterCullCandidate( score, points[i].separation, bestScore, bestSeparation, tolSqr, separationTol ) )
		{
			bestScore = score;
			bestSeparation = points[i].separation;
			bestIndex = i;
		}
	}

	if ( bestIndex == B3_NULL_INDEX )
	{
		// No additional area
		points[0] = finalPoints[0];
		points[1] = finalPoints[1];
		points[2] = finalPoints[2];
		return 3;
	}

	// Store best point
	finalPoints[3] = points[bestIndex];

	// Full quad
	points[0] = finalPoints[0];
	points[1] = finalPoints[1];
	points[2] = finalPoints[2];
	points[3] = finalPoints[3];
	return 4;
}

static int b3ReduceCluster( b3LocalManifoldPoint* points, int count1, b3Vec3 normal, b3Arena arena )
{
	int targetCount = 1;
	if ( count1 <= targetCount )
	{
		return count1;
	}

	b3Point2D* pts = b3Bump( &arena, count1 * sizeof( b3Point2D ) );
	b3Vec3 u = b3Perp( normal );
	b3Vec3 v = b3Cross( normal, u );
	b3Vec3 origin = points[0].point;

	for ( int i = 0; i < count1; ++i )
	{
		b3Vec3 d = b3Sub( points[i].point, origin );
		pts[i].p = (b3Vec2){ b3Dot( d, u ), b3Dot( d, v ) };
		pts[i].separation = points[i].separation;
		pts[i].originalIndex = i;
	}

	int count2 = b3CullPoints( pts, count1 );
	B3_ASSERT( count2 <= B3_MAX_MANIFOLD_POINTS );

	b3LocalManifoldPoint finalPoints[B3_MAX_MANIFOLD_POINTS];
	for ( int i = 0; i < count2; ++i )
	{
		int index = pts[i].originalIndex;
		B3_ASSERT( 0 <= index && index < count1 );
		finalPoints[i] = points[index];
	}

	memcpy( points, finalPoints, count2 * sizeof( b3LocalManifoldPoint ) );
	return count2;
}

typedef struct b3Cluster
{
	b3Vec3 manifoldNormal;
	b3Vec3 triangleNormal;
	b3LocalManifoldPoint* points;
	int pointCapacity;
	int pointCount;
} b3Cluster;

bool b3ComputeMeshManifolds( b3World* world, int workerIndex, b3Contact* contact, const b3Shape* shapeA, const int* materialMap,
							 b3WorldTransform xfA, const b3Shape* shapeB, b3WorldTransform xfB, bool isFast, b3Arena arena )
{
	B3_ASSERT( shapeA->type == b3_meshShape || shapeA->type == b3_heightShape );
	B3_UNUSED( workerIndex );
	B3_UNUSED( isFast );
	B3_UNUSED( materialMap );

	b3TaskContext* context = b3Array_Get( world->taskContexts, workerIndex );

	b3RefreshCache( contact, shapeA, xfA, &shapeB->aabb );

	// Collide with triangles and build manifolds
	b3MeshContact* meshContact = &contact->meshContact;
	int triangleCount = meshContact->triangleCache.count;

	b3LocalManifold** acceptedManifolds = b3Bump( &arena, triangleCount * sizeof( b3LocalManifold* ) );
	int acceptedManifoldCount = 0;
	b3LocalManifold** tentativeManifolds = b3Bump( &arena, triangleCount * sizeof( b3LocalManifold* ) );
	int tentativeManifoldCount = 0;
	b3TentativeTriangle* tentativeTriangles = b3Bump( &arena, triangleCount * sizeof( b3TentativeTriangle ) );
	int tentativeTriangleCount = 0;

	b3FoundEdges foundEdges;
	b3FoundVertices foundVertices;
	foundEdges.count = 0;
	foundVertices.count = 0;

	// This transform converts from mesh frame into the shapeB frame
	b3Transform transformAtoB = b3InvMulWorldTransforms( xfB, xfA );
	b3Matrix3 relativeMatrix = b3MakeMatrixFromQuat( transformAtoB.q );
	float linearSlop = B3_LINEAR_SLOP;

	// This should push apart shapes after a time of impact event.
	// In the past I've called this `polygon skin`, but PhysX and Unreal
	// call it `rest offset` which seems appropriate in this case.
	// It leads to a small visual gap but seems to improve the quality of mesh
	// collision, especially for hull versus mesh.
	float restOffset = B3_MESH_REST_OFFSET;
	bool enableSpeculative = contact->flags & b3_enableSpeculativePoints;

	// Make room for clip points
	int pointBufferCapacity = B3_MAX_POINTS_PER_TRIANGLE * triangleCount;

	b3LocalManifoldPoint* pointBuffer = b3Bump( &arena, pointBufferCapacity * sizeof( b3LocalManifoldPoint ) );
	int totalPointCount = 0;

	b3LocalManifold* manifoldBuffer = b3Bump( &arena, triangleCount * sizeof( b3LocalManifold ) );
	int manifoldCount = 0;

	b3TriangleCache* triangleCaches = meshContact->triangleCache.data;

	const b3HullData* hullB = shapeB->type == b3_hullShape ? shapeB->hull : NULL;

	for ( int index = 0; index < triangleCount && totalPointCount + 3 < pointBufferCapacity; ++index )
	{
		int triangleIndex = triangleCaches[index].triangleIndex;

		b3Triangle triangle;
		if ( shapeA->type == b3_meshShape )
		{
			triangle = b3GetMeshTriangle( &shapeA->mesh, triangleIndex );
		}
		else
		{
			B3_ASSERT( shapeA->type == b3_heightShape );
			triangle = b3GetHeightFieldTriangle( shapeA->heightField, triangleIndex );
		}

		// Transform triangle into the shape frame
		b3Vec3 vertices[3];
		vertices[0] = b3Add( b3MulMV( relativeMatrix, triangle.vertices[0] ), transformAtoB.p );
		vertices[1] = b3Add( b3MulMV( relativeMatrix, triangle.vertices[1] ), transformAtoB.p );
		vertices[2] = b3Add( b3MulMV( relativeMatrix, triangle.vertices[2] ), transformAtoB.p );

		b3ContactCache* cache = &triangleCaches[index].cache;
		int pointCapacity = pointBufferCapacity - totalPointCount;
		b3LocalManifold* manifold = manifoldBuffer + manifoldCount;
		manifold->points = pointBuffer + totalPointCount;
		manifold->pointCount = 0;
		manifold->triangleFlags = triangle.flags;
		manifold->feature = b3_featureNone;

		switch ( shapeB->type )
		{
			case b3_capsuleShape:
				b3CollideCapsuleAndTriangle( manifold, pointCapacity, &shapeB->capsule, vertices, &cache->simplexCache );
				break;

			case b3_hullShape:
				// Cached edge contact is dangerous at high speed because the hull can rotate around the edge and tunnel
				// through the triangle.
				if ( isFast && cache->satCache.type == b3_edgePairAxis )
				{
					cache->satCache = (b3SATCache){ 0 };
				}

				b3CollideHullAndTriangle( manifold, pointCapacity, hullB, vertices[0], vertices[1], vertices[2], triangle.flags,
										  &cache->satCache, enableSpeculative );
				context->satCallCount += 1;
				context->satCacheHitCount += cache->satCache.hit;
				break;

			case b3_sphereShape:
				b3CollideSphereAndTriangle( manifold, pointCapacity, &shapeB->sphere, vertices );
				break;

			default:
				B3_ASSERT( false );
				return false;
		}

		int manifoldPointCount = manifold->pointCount;

		if ( manifoldPointCount > 0 )
		{
			B3_ASSERT( manifold->feature != b3_featureNone );

			manifoldCount += 1;
			totalPointCount += manifoldPointCount;
			manifold->triangleIndex = triangleIndex;
			manifold->triangleNormal = b3MakeNormalFromPoints( vertices[0], vertices[1], vertices[2] );
			manifold->i1 = triangle.i1;
			manifold->i2 = triangle.i2;
			manifold->i3 = triangle.i3;

			if ( manifold->feature == b3_featureTriangleFace || B3_FORCE_GHOST_COLLISIONS )
			{
				(void)b3AddEdge( &foundEdges, triangle.i1, triangle.i2 );
				(void)b3AddEdge( &foundEdges, triangle.i2, triangle.i3 );
				(void)b3AddEdge( &foundEdges, triangle.i3, triangle.i1 );
				(void)b3AddVertex( &foundVertices, triangle.i1 );
				(void)b3AddVertex( &foundVertices, triangle.i2 );
				(void)b3AddVertex( &foundVertices, triangle.i3 );

				acceptedManifolds[acceptedManifoldCount++] = manifold;
			}
			else if ( manifold->feature == b3_featureHullFace )
			{
				float cosNormalAngle = b3Dot( manifold->triangleNormal, manifold->normal );
				if ( cosNormalAngle > 0.5f )
				{
					(void)b3AddEdge( &foundEdges, triangle.i1, triangle.i2 );
					(void)b3AddEdge( &foundEdges, triangle.i2, triangle.i3 );
					(void)b3AddEdge( &foundEdges, triangle.i3, triangle.i1 );
					(void)b3AddVertex( &foundVertices, triangle.i1 );
					(void)b3AddVertex( &foundVertices, triangle.i2 );
					(void)b3AddVertex( &foundVertices, triangle.i3 );

					acceptedManifolds[acceptedManifoldCount++] = manifold;
				}
				else
				{
					float minSeparation = manifold->points[0].separation;
					for ( int i = 1; i < manifoldPointCount; ++i )
					{
						minSeparation = b3MinFloat( minSeparation, manifold->points[i].separation );
					}

					if ( minSeparation < -2.0f * linearSlop )
					{
						// Deep overlap
						(void)b3AddEdge( &foundEdges, triangle.i1, triangle.i2 );
						(void)b3AddEdge( &foundEdges, triangle.i2, triangle.i3 );
						(void)b3AddEdge( &foundEdges, triangle.i3, triangle.i1 );
						(void)b3AddVertex( &foundVertices, triangle.i1 );
						(void)b3AddVertex( &foundVertices, triangle.i2 );
						(void)b3AddVertex( &foundVertices, triangle.i3 );
						acceptedManifolds[acceptedManifoldCount++] = manifold;
					}
					else
					{
						b3TentativeTriangle tentativeTriangle = { .squaredDistance = manifold->squaredDistance,
																  .index = tentativeManifoldCount };
						tentativeTriangles[tentativeTriangleCount++] = tentativeTriangle;
						tentativeManifolds[tentativeManifoldCount++] = manifold;
					}
				}
			}
			else
			{
				b3TentativeTriangle tentativeTriangle = { .squaredDistance = manifold->squaredDistance,
														  .index = tentativeManifoldCount };
				tentativeTriangles[tentativeTriangleCount++] = tentativeTriangle;
				tentativeManifolds[tentativeManifoldCount++] = manifold;
			}
		}
	}

	B3_ASSERT( acceptedManifoldCount <= triangleCount );
	B3_ASSERT( tentativeManifoldCount <= triangleCount );
	B3_ASSERT( tentativeTriangleCount <= triangleCount );

	if ( shapeB->type == b3_sphereShape )
	{
		// Sort triangles so the closest triangles are processed first
		{
#define LESS( i, j ) tentativeTriangles[(int)i].squaredDistance < tentativeTriangles[(int)j].squaredDistance
#define SWAP( i, j )                                                                                                             \
	do                                                                                                                           \
	{                                                                                                                            \
		b3TentativeTriangle tmp = tentativeTriangles[(int)i];                                                                    \
		tentativeTriangles[(int)i] = tentativeTriangles[(int)j];                                                                 \
		tentativeTriangles[(int)j] = tmp;                                                                                        \
	}                                                                                                                            \
	while ( 0 )
			QSORT( tentativeTriangleCount, LESS, SWAP );
#undef LESS
#undef SWAP
		}

		// Add tentative manifolds in sorted order. Avoid adding manifolds that generate ghost collisions.
		for ( int i = 0; i < tentativeTriangleCount; ++i )
		{
			b3LocalManifold* m = tentativeManifolds[tentativeTriangles[i].index];

			bool addedEdge1 = b3AddEdge( &foundEdges, m->i1, m->i2 );
			bool addedEdge2 = b3AddEdge( &foundEdges, m->i2, m->i3 );
			bool addedEdge3 = b3AddEdge( &foundEdges, m->i3, m->i1 );
			bool addedVertex1 = b3AddVertex( &foundVertices, m->i1 );
			bool addedVertex2 = b3AddVertex( &foundVertices, m->i2 );
			bool addedVertex3 = b3AddVertex( &foundVertices, m->i3 );

			b3TriangleFeature feature = m->feature;
			bool shouldCollide = false;
			switch ( feature )
			{
				case b3_featureNone:
				case b3_featureTriangleFace:
					B3_ASSERT( false );
					break;

				case b3_featureEdge1:
					shouldCollide = addedEdge1;
					break;

				case b3_featureEdge2:
					shouldCollide = addedEdge2;
					break;

				case b3_featureEdge3:
					shouldCollide = addedEdge3;
					break;

				case b3_featureVertex1:
					shouldCollide = addedVertex1;
					break;

				case b3_featureVertex2:
					shouldCollide = addedVertex2;
					break;

				case b3_featureVertex3:
					shouldCollide = addedVertex3;
					break;

				default:
					B3_ASSERT( false );
					break;
			}

			if ( shouldCollide == true )
			{
				acceptedManifolds[acceptedManifoldCount++] = m;
			}
		}
	}
	else
	{
		// Problem: hull can tunnel if time of impact is at concave edge
		// Example: flat box sliding down a ramp to a flat bottom
		// Solution: only ignore flat edges
		for ( int i = 0; i < tentativeManifoldCount; ++i )
		{
			b3LocalManifold* m = tentativeManifolds[i];
			int triangleFlags = m->triangleFlags;

			if ( ( triangleFlags & b3_allFlatEdges ) == b3_allFlatEdges )
			{
				continue;
			}

			if ( ( triangleFlags & b3_flatEdge1 ) == b3_flatEdge1 )
			{
				if ( b3FindEdge( &foundEdges, m->i1, m->i2 ) )
				{
					continue;
				}
			}

			if ( ( triangleFlags & b3_flatEdge2 ) == b3_flatEdge2 )
			{
				if ( b3FindEdge( &foundEdges, m->i2, m->i3 ) )
				{
					continue;
				}
			}

			if ( ( triangleFlags & b3_flatEdge3 ) == b3_flatEdge3 )
			{
				if ( b3FindEdge( &foundEdges, m->i3, m->i1 ) )
				{
					continue;
				}
			}

			acceptedManifolds[acceptedManifoldCount++] = m;
		}
	}

	B3_ASSERT( acceptedManifoldCount <= triangleCount );

	if ( acceptedManifoldCount == 0 )
	{
		if ( contact->manifoldCount > 0 )
		{
			b3FreeManifolds( world, contact->manifolds, contact->manifoldCount );
			contact->manifolds = NULL;
			contact->manifoldCount = 0;
		}
		return false;
	}

	b3Cluster* clusters = b3Bump( &arena, acceptedManifoldCount * sizeof( b3Cluster ) );
	int* clusterMemberships = b3Bump( &arena, acceptedManifoldCount * sizeof( int ) );

	// Cluster tolerance is tighter than the warm starting manifold matching tolerance. These
	// serve different purposes.
	const float clusterThreshold = 0.996f;
	int clusterCount = 0;
	int clusterPointCount = 0;
	for ( int i = 0; i < acceptedManifoldCount; ++i )
	{
		clusterMemberships[i] = B3_NULL_INDEX;

		const b3LocalManifold* manifold = acceptedManifolds[i];
		clusterPointCount += manifold->pointCount;

		// Cluster based on the triangle normal and contact normal.
		// The first cluster found is accepted because the tolerance is tight.
		// todo consider requiring the triangles to be connect by an edge.
		// todo consider looking for the best cluster instead of the first one within tolerance
		// This bool is here to allow quick testing with and without clustering.
		bool allowClustering = true;
		b3Vec3 manifoldNormal = manifold->normal;
		b3Vec3 triangleNormal = manifold->triangleNormal;
		int clusterIndex = B3_NULL_INDEX;
		for ( int j = 0; j < clusterCount && allowClustering; ++j )
		{
			float cosManifoldAngle = b3Dot( clusters[j].manifoldNormal, manifoldNormal );
			float cosTriangleAngle = b3Dot( clusters[j].triangleNormal, triangleNormal );
			if ( cosManifoldAngle <= clusterThreshold || cosTriangleAngle <= clusterThreshold )
			{
				continue;
			}

#if 0
			// todo there could be later triangles that create the connection
			// then failure to cluster breaks greedy impulse warm starting
			bool edgeConnected = false;

			for ( int k = 0; k < i; ++k )
			{
				if ( clusterMemberships[k] != j )
				{
					continue;
				}

				const b3LocalManifold* other = acceptedManifolds[k];
				if ( b3TrianglesShareEdge( manifold->i1, manifold->i2, manifold->i3, other->i1, other->i2, other->i3 ) )
				{
					edgeConnected = true;
					break;
				}
			}

			if ( edgeConnected )
			{
				clusterIndex = j;
				break;
			}
#else

			// Found a cluster
			clusterIndex = j;
			break;
#endif
		}

		if ( clusterIndex != B3_NULL_INDEX )
		{
			clusterMemberships[i] = clusterIndex;
			clusters[clusterIndex].pointCapacity += manifold->pointCount;
		}
		else
		{
			clusters[clusterCount].manifoldNormal = manifoldNormal;
			clusters[clusterCount].triangleNormal = triangleNormal;
			clusters[clusterCount].pointCapacity = manifold->pointCount;
			clusterMemberships[i] = clusterCount;
			clusterCount += 1;
		}
	}

	if ( clusterPointCount == 0 )
	{
		return false;
	}

	// Setup clusters
	b3LocalManifoldPoint* clusterPoints = b3Bump( &arena, clusterPointCount * sizeof( b3LocalManifoldPoint ) );
	int pointOffset = 0;

	for ( int i = 0; i < clusterCount; ++i )
	{
		b3Cluster* cluster = clusters + i;
		cluster->points = clusterPoints + pointOffset;
		cluster->pointCount = 0;
		pointOffset += cluster->pointCapacity;
	}

	// Populate clusters
	for ( int i = 0; i < acceptedManifoldCount; ++i )
	{
		int clusterIndex = clusterMemberships[i];
		if ( clusterIndex == B3_NULL_INDEX )
		{
			continue;
		}

		B3_ASSERT( 0 <= clusterIndex && clusterIndex < clusterCount );

		b3LocalManifold* am = acceptedManifolds[i];
		b3Cluster* cm = clusters + clusterIndex;
		for ( int j = 0; j < am->pointCount; ++j )
		{
			B3_ASSERT( cm->pointCount < cm->pointCapacity );
			b3LocalManifoldPoint* ap = am->points + j;
			b3LocalManifoldPoint* cp = cm->points + cm->pointCount;

			cp->triangleIndex = am->triangleIndex;
			cp->point = ap->point;
			cp->separation = ap->separation;
			cp->pair = ap->pair;
			cm->pointCount += 1;
		}
	}

	// Simplify clusters
	for ( int i = 0; i < clusterCount; ++i )
	{
		b3Cluster* cm = clusters + i;
		B3_ASSERT( cm->pointCount == cm->pointCapacity );
		int reducedCount = b3ReduceCluster( cm->points, cm->pointCount, cm->triangleNormal, arena );
		cm->pointCount = reducedCount;
	}

	// Make a temporary copy of previous manifolds
	int oldManifoldCount = contact->manifoldCount;
	b3Manifold* oldManifolds = NULL;
	if ( oldManifoldCount > 0 )
	{
		oldManifolds = b3Bump( &arena, oldManifoldCount * sizeof( b3Manifold ) );
		memcpy( oldManifolds, contact->manifolds, oldManifoldCount * sizeof( b3Manifold ) );
	}

	// Resize manifolds if needed
	if ( oldManifoldCount != clusterCount )
	{
		b3FreeManifolds( world, contact->manifolds, contact->manifoldCount );
		contact->manifolds = b3AllocateManifolds( world, clusterCount );
		contact->manifoldCount = (uint16_t)clusterCount;
	}
	else
	{
		// Mem zero manifolds
		memset( contact->manifolds, 0, contact->manifoldCount * sizeof( b3Manifold ) );
	}

	bool* consumed = NULL;
	if ( oldManifoldCount > 0 )
	{
		consumed = b3Bump( &arena, oldManifoldCount * sizeof( bool ) );
		memset( consumed, 0, oldManifoldCount * sizeof( bool ) );
	}

	b3Matrix3 matrixB = b3MakeMatrixFromQuat( xfB.q );
	b3Vec3 offsetA = b3SubPos( xfB.p, xfA.p );

	const float normalMatchTolerance = 0.995f;
	for ( int i = 0; i < clusterCount; ++i )
	{
		b3Cluster* cm = clusters + i;
		int pointCount = cm->pointCount;
		B3_ASSERT( 0 < pointCount && pointCount <= B3_MAX_MANIFOLD_POINTS );

		b3Manifold* manifold = contact->manifolds + i;
		manifold->pointCount = pointCount;
		manifold->normal = b3MulMV( matrixB, cm->manifoldNormal );

		b3Vec3 clusterNormal = b3MulMV( matrixB, cm->manifoldNormal );
		float bestDot = normalMatchTolerance;
		int bestIndex = B3_NULL_INDEX;

		for ( int j = 0; j < oldManifoldCount; ++j )
		{
			if ( consumed[j] == true )
			{
				continue;
			}

			float dot = b3Dot( oldManifolds[j].normal, clusterNormal );
			if ( dot > bestDot )
			{
				bestIndex = j;
				bestDot = dot;
			}
		}

		b3Manifold* matchedManifold = NULL;
		if ( bestIndex != B3_NULL_INDEX )
		{
			matchedManifold = oldManifolds + bestIndex;
			manifold->frictionImpulse = matchedManifold->frictionImpulse;
			manifold->rollingImpulse = matchedManifold->rollingImpulse;
			manifold->twistImpulse = matchedManifold->twistImpulse;
			consumed[bestIndex] = true;
		}

		for ( int j = 0; j < pointCount; ++j )
		{
			const b3LocalManifoldPoint* source = cm->points + j;
			b3ManifoldPoint* target = manifold->points + j;

			// Contact points are computed in frame B
			target->anchorB = b3MulMV( matrixB, source->point );
			target->anchorA = b3Add( target->anchorB, offsetA );
			target->separation = source->separation - restOffset;
			target->featureId = b3MakeFeatureId( source->pair );
			target->triangleIndex = source->triangleIndex;

			// Preserve normal impulse if possible
			if ( matchedManifold != NULL )
			{
				int oldPointCount = matchedManifold->pointCount;
				for ( int k = 0; k < oldPointCount; ++k )
				{
					b3ManifoldPoint* oldPt = matchedManifold->points + k;

					if ( target->featureId == oldPt->featureId && target->triangleIndex == oldPt->triangleIndex )
					{
						target->normalImpulse = oldPt->normalImpulse;
						target->persisted = true;

						// claimed
						oldPt->triangleIndex = B3_NULL_INDEX;
						break;
					}
				}
			}
		}
	}

	const b3SurfaceMaterial* materialsA = b3GetShapeMaterials( shapeA );
	const b3SurfaceMaterial* materialB = b3GetShapeMaterials( shapeB );
	b3Vec3 tangentVelocityA = b3Vec3_zero;

	// Update friction and restitution if the mesh has per triangle material
	if ( shapeA->materialCount > 0 )
	{
		float friction = 0.0f;
		float restitution = 0.0f;
		float sampleCount = 0.0f;

		const uint8_t* materialIndices;
		if ( shapeA->type == b3_meshShape )
		{
			materialIndices = b3GetMeshMaterialIndices( shapeA->mesh.data );
		}
		else
		{
			materialIndices = b3GetHeightFieldMaterialIndices( shapeA->heightField );
		}

		for ( int i = 0; i < clusterCount; ++i )
		{
			b3Manifold* manifold = contact->manifolds + i;
			int pointCount = manifold->pointCount;
			for ( int j = 0; j < pointCount; ++j )
			{
				int triangleIndex = manifold->points[j].triangleIndex;
				int materialIndex;
				if ( shapeA->type == b3_meshShape )
				{
					materialIndex = materialIndices[triangleIndex];

					if ( materialMap != NULL )
					{
						materialIndex = materialMap[materialIndex];
					}
				}
				else
				{
					materialIndex = materialIndices[triangleIndex >> 1];
				}

				materialIndex = b3ClampInt( materialIndex, 0, shapeA->materialCount - 1 );
				b3SurfaceMaterial material = materialsA[materialIndex];
				friction += world->frictionCallback( material.friction, material.userMaterialId, materialB->friction,
													 materialB->userMaterialId );
				restitution += world->restitutionCallback( material.restitution, material.userMaterialId, materialB->restitution,
														   materialB->userMaterialId );

				tangentVelocityA = b3Add( tangentVelocityA, material.tangentVelocity );

				sampleCount += 1.0f;
			}
		}

		if ( sampleCount > 0.0f )
		{
			float invCount = 1.0f / sampleCount;
			contact->friction = invCount * friction;
			contact->restitution = invCount * restitution;
			tangentVelocityA = b3MulSV( invCount, tangentVelocityA );
		}

		B3_ASSERT( b3IsValidFloat( contact->friction ) && contact->friction >= 0.0f );
		B3_ASSERT( b3IsValidFloat( contact->restitution ) && contact->restitution >= 0.0f );
	}
	else
	{
		// Keep these updated in case the values on the shapes are modified
		contact->friction = world->frictionCallback( materialsA[0].friction, materialsA[0].userMaterialId, materialB->friction,
													 materialB->userMaterialId );
		contact->restitution = world->restitutionCallback( materialsA[0].restitution, materialsA[0].userMaterialId,
														   materialB->restitution, materialB->userMaterialId );
		tangentVelocityA = materialsA[0].tangentVelocity;
	}

	tangentVelocityA = b3RotateVector( xfA.q, tangentVelocityA );

	float radiusB = 0.0f;
	if ( shapeB->type == b3_sphereShape )
	{
		radiusB = shapeB->sphere.radius;
	}
	else if ( shapeB->type == b3_capsuleShape )
	{
		radiusB = shapeB->capsule.radius;
	}
	else if ( shapeB->type == b3_hullShape )
	{
		radiusB = shapeB->hull->innerRadius;
	}

	contact->rollingResistance = materialB->rollingResistance * radiusB;

	b3Vec3 tangentVelocityB = b3RotateVector( xfB.q, materialB->tangentVelocity );
	contact->tangentVelocity = b3Sub( tangentVelocityA, tangentVelocityB );
	return true;
}
