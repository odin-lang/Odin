// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

// Dirk Gregorius contributed portions of this code

#include "container.h"
#include "math_internal.h"
#include "shape.h"
#include "simd.h"

#include "box3d/collision.h"
#include "box3d/constants.h"

#include <stdint.h>

b3DeclareArray( b3VertexNode );
b3DeclareArray( b3MeshNode );
b3DeclareArray( b3MeshTriangle );
b3DeclareArray( b3Vec3 );
b3DeclareArray( b3Primitive );
b3DeclareArrayNative( uint8_t );

#define B3_BIN_COUNT 8
#define B3_DESIRED_TRIANGLES_PER_LEAF 4
#define B3_LEAF_NODE 3
#define B3_MAXIMUM_TRIANGLES_PER_LEAF 8
#define B3_MESH_STACK_SIZE 256

static bool b3IsLeaf( const b3MeshNode* node )
{
	return node->data.asLeaf.type == B3_LEAF_NODE;
}

static b3MeshNode* b3GetMeshNodesWrite( b3MeshData* mesh )
{
	if ( mesh->nodeOffset == 0 )
	{
		return NULL;
	}

	return (b3MeshNode*)( (intptr_t)mesh + mesh->nodeOffset );
}

static b3MeshNode* b3GetLeftChildWrite( b3MeshNode* node )
{
	// The left child follows its parent.
	B3_ASSERT( !b3IsLeaf( node ) );
	return node + 1;
}

static const b3MeshNode* b3GetLeftChild( const b3MeshNode* node )
{
	// The left child follows its parent.
	B3_ASSERT( !b3IsLeaf( node ) );
	return node + 1;
}

static b3MeshNode* b3GetRightChildWrite( b3MeshNode* node )
{
	// We store the offset of the right child relative to its parent
	B3_ASSERT( !b3IsLeaf( node ) );
	return node + node->data.asNode.childOffset;
}

static const b3MeshNode* b3GetRightChild( const b3MeshNode* node )
{
	// We store the offset of the right child relative to its parent
	B3_ASSERT( !b3IsLeaf( node ) );
	return node + node->data.asNode.childOffset;
}

static const b3MeshNode* b3GetRoot( const b3MeshData* mesh )
{
	// The first node is the root
	return b3GetMeshNodes( mesh );
}

static b3MeshNode* b3GetRootWrite( b3MeshData* mesh )
{
	// The first node is the root
	return b3GetMeshNodesWrite( mesh );
}

static b3MeshTriangle* b3GetMeshTrianglesWrite( b3MeshData* mesh )
{
	if ( mesh->triangleOffset == 0 )
	{
		return NULL;
	}

	return (b3MeshTriangle*)( (intptr_t)mesh + mesh->triangleOffset );
}

static b3Vec3* b3GetMeshVerticesWrite( b3MeshData* mesh )
{
	if ( mesh->vertexOffset == 0 )
	{
		return NULL;
	}

	return (b3Vec3*)( (intptr_t)mesh + mesh->vertexOffset );
}

// static b3Vec3 b3GetVertex( b3MeshData& mesh, int vertexIndex )
//{
//	B3_ASSERT( 0 <= vertexIndex && vertexIndex < mesh.vertexCount );
//	b3Vec3* vertices = b3GetMeshVertices( &mesh );
//	return vertices[vertexIndex];
// }

static uint8_t* b3GetMeshMaterialIndicesWrite( b3MeshData* mesh )
{
	if ( mesh->materialOffset == 0 )
	{
		return NULL;
	}

	return (uint8_t*)( (intptr_t)mesh + mesh->materialOffset );
}

static uint8_t* b3GetMeshFlagsWrite( b3MeshData* mesh )
{
	if ( mesh->flagsOffset == 0 )
	{
		return NULL;
	}

	return (uint8_t*)( (intptr_t)mesh + mesh->flagsOffset );
}

static int b3GetNodeHeight( const b3MeshNode* node )
{
	if ( b3IsLeaf( node ) )
	{
		return 0;
	}

	const b3MeshNode* leftChild = b3GetLeftChild( node );
	int leftHeight = b3GetNodeHeight( leftChild );
	const b3MeshNode* rightChild = b3GetRightChild( node );
	int rightHeight = b3GetNodeHeight( rightChild );

	return 1 + b3MaxInt( leftHeight, rightHeight );
}

int b3GetHeight( const b3MeshData* mesh )
{
	const b3MeshNode* root = b3GetRoot( mesh );
	if ( root == NULL )
	{
		return 0;
	}

	return b3GetNodeHeight( root );
}

#if B3_ENABLE_VALIDATION == 1
static bool b3IsDegenerate( b3Vec3 v1, b3Vec3 v2, b3Vec3 v3, float minArea )
{
	b3Vec3 normal = b3Cross( b3Sub( v2, v1 ), b3Sub( v3, v1 ) );
	float lengthSq = b3LengthSquared( normal );
	return lengthSq < minArea * minArea;
}

static bool b3IsNonDegenerate( const b3MeshData* mesh, float minArea )
{
	const b3MeshTriangle* triangles = b3GetMeshTriangles( mesh );
	const b3Vec3* vertices = b3GetMeshVertices( mesh );

	// Check triangles
	for ( int index = 0; index < mesh->triangleCount; ++index )
	{
		// Index range
		b3MeshTriangle triangle = triangles[index];
		if ( triangle.index1 >= mesh->vertexCount )
		{
			return false;
		}

		if ( triangle.index2 >= mesh->vertexCount )
		{
			return false;
		}

		if ( triangle.index3 >= mesh->vertexCount )
		{
			return false;
		}

		// Degenerate topology
		if ( triangle.index1 == triangle.index2 )
		{
			return false;
		}
		if ( triangle.index1 == triangle.index3 )
		{
			return false;
		}
		if ( triangle.index2 == triangle.index3 )
		{
			return false;
		}

		// Degenerate geometry
		b3Vec3 vertex1 = vertices[triangle.index1];
		b3Vec3 vertex2 = vertices[triangle.index2];
		b3Vec3 vertex3 = vertices[triangle.index3];
		if ( b3IsDegenerate( vertex1, vertex2, vertex3, minArea ) )
		{
			return false;
		}
	}

	return true;
}

static inline b3AABB b3GetNodeAABB( const b3MeshNode* node )
{
	return (b3AABB){
		node->lowerBound,
		node->upperBound,
	};
}

static bool b3IsConsistent( const b3MeshData* mesh )
{
	const b3MeshTriangle* triangles = b3GetMeshTriangles( mesh );
	const b3Vec3* vertices = b3GetMeshVertices( mesh );

	// Check nodes
	int count = 0;
	const b3MeshNode* stack[64];
	stack[count++] = b3GetRoot( mesh );

	while ( count > 0 )
	{
		const b3MeshNode* node = stack[--count];
		b3AABB nodeBounds = b3GetNodeAABB( node );

		if ( b3IsLeaf( node ) == false )
		{
			const b3MeshNode* child1 = b3GetLeftChild( node );
			b3AABB bounds1 = b3GetNodeAABB( child1 );
			const b3MeshNode* child2 = b3GetRightChild( node );
			b3AABB bounds2 = b3GetNodeAABB( child2 );

			if ( !b3AABB_Contains( nodeBounds, bounds1 ) )
			{
				return false;
			}

			if ( !b3AABB_Contains( nodeBounds, bounds2 ) )
			{
				return false;
			}

			stack[count++] = child2;
			stack[count++] = child1;
		}
		else
		{
			b3AABB triangleBounds = B3_BOUNDS3_EMPTY;
			for ( uint32_t index = 0; index < node->data.asLeaf.triangleCount; ++index )
			{
				int triangleIndex = node->triangleOffset + index;
				B3_ASSERT( 0 <= triangleIndex && triangleIndex < mesh->triangleCount );

				b3MeshTriangle triangle = triangles[triangleIndex];

				b3AABB vertexBounds = B3_BOUNDS3_EMPTY;
				vertexBounds = b3AABB_AddPoint( vertexBounds, vertices[triangle.index1] );
				vertexBounds = b3AABB_AddPoint( vertexBounds, vertices[triangle.index2] );
				vertexBounds = b3AABB_AddPoint( vertexBounds, vertices[triangle.index3] );

				triangleBounds = b3AABB_Union( triangleBounds, vertexBounds );
			}

			if ( !b3AABB_Contains( nodeBounds, triangleBounds ) )
			{
				return false;
			}
		}
	}

	return true;
}

bool b3IsValidMesh( const b3MeshData* meshData )
{
	if ( meshData == NULL )
	{
		return false;
	}

	if ( meshData->version != B3_MESH_VERSION )
	{
		return false;
	}

	if ( meshData->byteCount < (int)sizeof( b3MeshData ) )
	{
		return false;
	}

	return b3IsConsistent( meshData );
}

#else

bool b3IsValidMesh( const b3MeshData* meshData )
{
	if ( meshData == NULL )
	{
		return false;
	}

	if ( meshData->version != B3_MESH_VERSION )
	{
		return false;
	}

	if ( meshData->byteCount < (int)sizeof( b3MeshData ) )
	{
		return false;
	}

	return true;
}

#endif

// Node for a vertex linked list
typedef struct b3VertexNode
{
	int32_t vertexIndex;
	int nextNodeIndex;
} b3VertexNode;

#define NAME b3VertexMap
#define KEY_TY uint64_t
#define VAL_TY int
#define HASH_FN vt_hash_integer
#define CMPR_FN vt_cmpr_integer
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

typedef struct b3SpatialHash
{
	b3Array( b3VertexNode ) nodes;
	const b3Vec3* vertices;
	int vertexCount;
	b3VertexMap vertexMap;
	float cellSize;
	float tolerance;
} b3SpatialHash;

static void b3SpatialHash_Create( b3SpatialHash* h, const b3Vec3* vertices, int vertexCount, float tolerance )
{
	h->vertices = vertices;
	h->vertexCount = vertexCount;
	h->tolerance = tolerance;
	h->cellSize = 2.0f * tolerance;
	b3Array_CreateN( h->nodes, vertexCount );

	b3VertexMap_init( &h->vertexMap );
	b3VertexMap_reserve( &h->vertexMap, vertexCount );

	B3_ASSERT( h->cellSize > 0.0f );
}

static void b3SpatialHash_Destroy( b3SpatialHash* h )
{
	b3VertexMap_cleanup( &h->vertexMap );
	b3Array_Destroy( h->nodes );
}

// Welding works by bucketing nearby vertices into identical keys in a hash table.
// Bucketing is done manually with an array.
static int32_t b3SpatialHash_FindDuplicate( b3SpatialHash* h, int32_t currentIndex )
{
	B3_ASSERT( currentIndex < h->vertexCount );
	b3Vec3 vertex = h->vertices[currentIndex];
	float cellSize = h->cellSize;
	float tolerance = h->tolerance;

	// Get the grid coordinates for the current vertex
	int32_t baseX = (int32_t)( floorf( vertex.x / cellSize ) );
	int32_t baseY = (int32_t)( floorf( vertex.y / cellSize ) );
	int32_t baseZ = (int32_t)( floorf( vertex.z / cellSize ) );

	// Check the current cell and all 26 neighboring cells (3x3x3 - 1)
	for ( int dx = -1; dx <= 1; ++dx )
	{
		for ( int dy = -1; dy <= 1; ++dy )
		{
			for ( int dz = -1; dz <= 1; ++dz )
			{
				int32_t x = baseX + dx;
				int32_t y = baseY + dy;
				int32_t z = baseZ + dz;

				// Compute hash for this neighboring cell (this is the key in the map)
				uint64_t key = 0;
				key ^= (uint64_t)( x ) + 0x9e3779b9 + ( key << 6 ) + ( key >> 2 );
				key ^= (uint64_t)( y ) + 0x9e3779b9 + ( key << 6 ) + ( key >> 2 );
				key ^= (uint64_t)( z ) + 0x9e3779b9 + ( key << 6 ) + ( key >> 2 );

				b3VertexMap_itr it = b3VertexMap_get( &h->vertexMap, key );
				if ( b3VertexMap_is_end( it ) == false )
				{
					// Check all vertices in this key
					int nodeIndex = it.data->val;

					while ( nodeIndex != B3_NULL_INDEX )
					{
						b3VertexNode node = h->nodes.data[nodeIndex];

						int32_t existingIndex = node.vertexIndex;
						B3_ASSERT( existingIndex < currentIndex );
						B3_ASSERT( existingIndex < h->vertexCount );

						b3Vec3 other = h->vertices[existingIndex];

						// IsEqual inlined: check if vertices are within tolerance
						if ( fabsf( vertex.x - other.x ) <= tolerance && fabsf( vertex.y - other.y ) <= tolerance &&
							 fabsf( vertex.z - other.z ) <= tolerance )
						{
							// Found duplicate
							return existingIndex;
						}

						nodeIndex = node.nextNodeIndex;
					}
				}
			}
		}
	}

	// No duplicate found, add to hash table
	uint64_t currentKey = 0;
	currentKey ^= (uint64_t)( baseX ) + 0x9e3779b9 + ( currentKey << 6 ) + ( currentKey >> 2 );
	currentKey ^= (uint64_t)( baseY ) + 0x9e3779b9 + ( currentKey << 6 ) + ( currentKey >> 2 );
	currentKey ^= (uint64_t)( baseZ ) + 0x9e3779b9 + ( currentKey << 6 ) + ( currentKey >> 2 );

	b3VertexMap_itr it = b3VertexMap_get( &h->vertexMap, currentKey );
	if ( b3VertexMap_is_end( it ) == false )
	{
		int nodeIndex = it.data->val;

		b3VertexNode node = {
			.vertexIndex = currentIndex,
			.nextNodeIndex = nodeIndex,
		};

		it.data->val = h->nodes.count;
		b3Array_Push( h->nodes, node );
	}
	else
	{
		b3VertexNode node = {
			.vertexIndex = currentIndex,
			.nextNodeIndex = B3_NULL_INDEX,
		};

		b3VertexMap_insert( &h->vertexMap, currentKey, h->nodes.count );
		b3Array_Push( h->nodes, node );
	}

	// Not welded
	return B3_NULL_INDEX;
}

typedef struct b3WeldData
{
	const b3Vec3* srcVertices;
	const int32_t* srcIndices;

	b3Vec3* dstVertices;
	int32_t* dstIndices;

	int vertexCount;
	int indexCount;
} b3WeldData;

static int b3WeldVertices( b3WeldData* data, float tolerance )
{
	int vertexCount = data->vertexCount;
	int uniqueCount = 0;

	// Create spatial hash and find duplicates
	b3SpatialHash spatialHash;
	b3SpatialHash_Create( &spatialHash, data->srcVertices, vertexCount, tolerance );
	b3Array( int ) vertexMapping = { 0 };
	b3Array_Resize( vertexMapping, vertexCount );

	for ( int i = 0; i < vertexCount; ++i )
	{
		int32_t duplicateIndex = b3SpatialHash_FindDuplicate( &spatialHash, i );

		if ( duplicateIndex == B3_NULL_INDEX )
		{
			// New unique vertex
			vertexMapping.data[i] = uniqueCount;
			data->dstVertices[uniqueCount] = data->srcVertices[i];
			uniqueCount += 1;
		}
		else
		{
			// Found duplicate, map to existing vertex
			vertexMapping.data[i] = vertexMapping.data[duplicateIndex];
		}
	}

	// Update indices to reference the new vertex array
	int indexCount = data->indexCount;
	for ( int i = 0; i < indexCount; ++i )
	{
		int srcIndex = data->srcIndices[i];
		B3_ASSERT( srcIndex < vertexCount );
		data->dstIndices[i] = vertexMapping.data[srcIndex];
	}

	b3SpatialHash_Destroy( &spatialHash );
	b3Array_Destroy( vertexMapping );

	return uniqueCount;
}

static inline void b3StoreLeaf( b3MeshNode* node, const b3AABB* aabb, int triangleCount, int triangleOffset )
{
	node->data.asLeaf.type = B3_LEAF_NODE;
	node->data.asLeaf.triangleCount = triangleCount;
	node->triangleOffset = triangleOffset;
	node->lowerBound = aabb->lowerBound;
	node->upperBound = aabb->upperBound;
}

typedef struct b3Primitive
{
	b3AABB aabb;
	b3Vec3 center;
	int triangleIndex;
} b3Primitive;

typedef struct b3Bucket
{
	int count;
	b3AABB bounds;
} b3Bucket;

typedef struct b3Split
{
	b3AABB leftBounds;
	b3AABB rightBounds;
	int axis;
	int index;
} b3Split;

static b3Split b3SplitBinnedSah( int count, b3Primitive* primitives )
{
	b3Split split;
	split.axis = -1;
	split.index = -1;

	// Compute bounds of primitive centroids and choose split axis
	b3AABB bounds = { primitives[0].center, primitives[0].center };
	for ( int i = 1; i < count; ++i )
	{
		bounds = b3AABB_AddPoint( bounds, primitives[i].center );
	}

	// Compute costs for splitting after each bucket and keep track of best split
	// This is a small O(n^2) loop. This can be further optimized, but it is already
	// very fast and is kept for simplicity right now.
	int bestBucket = -1;
	float bestCost = FLT_MAX;

	for ( int axis = 0; axis < 3; ++axis )
	{
		b3Vec3 extent = b3AABB_Extents( bounds );
		if ( b3GetByIndex( extent, axis ) < B3_LINEAR_SLOP )
		{
			continue;
		}

		// Initialize buckets
		b3Bucket buckets[B3_BIN_COUNT];
		for ( int i = 0; i < B3_BIN_COUNT; ++i )
		{
			buckets[i].count = 0;
			buckets[i].bounds = B3_BOUNDS3_EMPTY;
		}

		// Fill buckets
		float factor = B3_BIN_COUNT * ( 1.0f - FLT_EPSILON ) /
					   ( b3GetByIndex( bounds.upperBound, axis ) - b3GetByIndex( bounds.lowerBound, axis ) );
		for ( int i = 0; i < count; ++i )
		{
			b3Vec3 center = primitives[i].center;
			int index = (int)( factor * ( b3GetByIndex( center, axis ) - b3GetByIndex( bounds.lowerBound, axis ) ) );
			B3_ASSERT( 0 <= index && index < B3_BIN_COUNT );

			buckets[index].count++;
			buckets[index].bounds = b3AABB_Union( buckets[index].bounds, primitives[i].aabb );
		}

		// Evaluate splits
		for ( int i = 0; i < B3_BIN_COUNT - 1; ++i )
		{
			int leftCount = 0;
			b3AABB leftBounds = B3_BOUNDS3_EMPTY;
			for ( int k = 0; k <= i; ++k )
			{
				leftCount += buckets[k].count;
				leftBounds = b3AABB_Union( leftBounds, buckets[k].bounds );
			}

			int rightCount = 0;
			b3AABB rightBounds = B3_BOUNDS3_EMPTY;
			for ( int k = i + 1; k < B3_BIN_COUNT; ++k )
			{
				rightCount += buckets[k].count;
				rightBounds = b3AABB_Union( rightBounds, buckets[k].bounds );
			}

			B3_ASSERT( leftCount + rightCount == count );
			if ( leftCount > 0 && rightCount > 0 )
			{
				float cost = leftCount * b3AABB_Area( leftBounds ) + rightCount * b3AABB_Area( rightBounds );

				if ( cost < bestCost )
				{
					bestBucket = i;
					bestCost = cost;

					split.axis = axis;
					split.index = leftCount;
					split.leftBounds = leftBounds;
					split.rightBounds = rightBounds;
				}
			}
		}
	}

	// Partition
	if ( bestBucket >= 0 )
	{
		int axis = split.axis;
		float factor = B3_BIN_COUNT * ( 1.0f - FLT_EPSILON ) /
					   ( b3GetByIndex( bounds.upperBound, axis ) - b3GetByIndex( bounds.lowerBound, axis ) );

		int splitIndex = 0;
		for ( int i = 0; i < count; ++i )
		{
			b3Vec3 center = primitives[i].center;
			int index = (int)( factor * ( b3GetByIndex( center, axis ) - b3GetByIndex( bounds.lowerBound, axis ) ) );

			if ( index <= bestBucket )
			{
				b3Primitive temp = primitives[i];
				primitives[i] = primitives[splitIndex];
				primitives[splitIndex] = temp;
				splitIndex++;
			}
		}
		B3_ASSERT( splitIndex == split.index );
	}

	return split;
}

static b3Split b3SplitHalf( int count, b3Primitive* primitives )
{
	// Split in the middle
	int splitIndex = count / 2;

	b3AABB leftBounds = B3_BOUNDS3_EMPTY;
	for ( int i = 0; i < splitIndex; ++i )
	{
		leftBounds = b3AABB_Union( leftBounds, primitives[i].aabb );
	}

	b3AABB rightBounds = B3_BOUNDS3_EMPTY;
	for ( int i = splitIndex; i < count; ++i )
	{

		rightBounds = b3AABB_Union( rightBounds, primitives[i].aabb );
	}

	b3AABB bounds = b3AABB_Union( leftBounds, rightBounds );
	int axis = b3MajorAxis( b3AABB_Extents( bounds ) );

	b3Split split;
	split.axis = axis;
	split.index = splitIndex;
	split.leftBounds = leftBounds;
	split.rightBounds = rightBounds;

	return split;
}

static b3Split b3SplitMedian( int count, b3Primitive* primitives )
{
	B3_ASSERT( count > 2 );

	b3Vec3 lowerBound = primitives[0].center;
	b3Vec3 upperBound = primitives[0].center;

	for ( int i = 1; i < count; ++i )
	{
		lowerBound = b3Min( lowerBound, primitives[i].center );
		upperBound = b3Max( upperBound, primitives[i].center );
	}

	b3Vec3 d = b3Sub( upperBound, lowerBound );
	b3Vec3 c = b3MulSV( 0.5f, b3Add( lowerBound, upperBound ) );

	b3Split split = { 0 };
	split.index = -1;

	// Partition longest axis using the Hoare partition scheme
	// https://en.wikipedia.org/wiki/Quicksort
	// https://nicholasvadivelu.com/2021/01/11/array-partition/
	int i1 = 0, i2 = count;
	if ( d.x >= d.y && d.x >= d.z )
	{
		split.axis = 0;

		float pivot = c.x;

		while ( i1 < i2 )
		{
			while ( i1 < i2 && primitives[i1].center.x < pivot )
			{
				i1 += 1;
			};

			while ( i1 < i2 && primitives[i2 - 1].center.x >= pivot )
			{
				i2 -= 1;
			};

			if ( i1 < i2 )
			{
				// Swap primitives
				b3Primitive temp = primitives[i1];
				primitives[i1] = primitives[i2 - 1];
				primitives[i2 - 1] = temp;

				i1 += 1;
				i2 -= 1;
			}
		}
	}
	else if ( d.y >= d.z )
	{
		split.axis = 1;

		float pivot = c.y;

		while ( i1 < i2 )
		{
			while ( i1 < i2 && primitives[i1].center.y < pivot )
			{
				i1 += 1;
			};

			while ( i1 < i2 && primitives[i2 - 1].center.y >= pivot )
			{
				i2 -= 1;
			};

			if ( i1 < i2 )
			{
				// Swap primitives
				b3Primitive temp = primitives[i1];
				primitives[i1] = primitives[i2 - 1];
				primitives[i2 - 1] = temp;

				i1 += 1;
				i2 -= 1;
			}
		}
	}
	else
	{
		split.axis = 2;

		float pivot = c.z;

		while ( i1 < i2 )
		{
			while ( i1 < i2 && primitives[i1].center.z < pivot )
			{
				i1 += 1;
			};

			while ( i1 < i2 && primitives[i2 - 1].center.z >= pivot )
			{
				i2 -= 1;
			};

			if ( i1 < i2 )
			{
				// Swap primitives
				b3Primitive temp = primitives[i1];
				primitives[i1] = primitives[i2 - 1];
				primitives[i2 - 1] = temp;

				i1 += 1;
				i2 -= 1;
			}
		}
	}
	B3_ASSERT( i1 == i2 );
	B3_ASSERT( 0 <= i1 && i1 < count );

	if ( i1 == 0 || i1 == count - 1 )
	{
		// failed to split
		i1 = count / 2;
	}

	b3AABB leftBounds = B3_BOUNDS3_EMPTY;
	for ( int i = 0; i < i1; ++i )
	{
		leftBounds = b3AABB_Union( leftBounds, primitives[i].aabb );
	}

	b3AABB rightBounds = B3_BOUNDS3_EMPTY;
	for ( int i = i1; i < count; ++i )
	{
		rightBounds = b3AABB_Union( rightBounds, primitives[i].aabb );
	}

	split.index = i1;
	split.leftBounds = leftBounds;
	split.rightBounds = rightBounds;
	return split;
}

#if B3_ENABLE_VALIDATION == 1

static bool b3ValidateSplit( int count, b3Primitive* primitives, const b3Split* split )
{
	if ( split->axis < 0 )
	{
		return false;
	}

	for ( int i = 0; i < split->index; ++i )
	{
		if ( !b3AABB_Contains( split->leftBounds, primitives[i].aabb ) )
		{
			return false;
		}
	}

	for ( int i = split->index; i < count; ++i )
	{
		if ( !b3AABB_Contains( split->rightBounds, primitives[i].aabb ) )
		{
			return false;
		}
	}

	return true;
}

#endif

static int b3BuildRecursive( b3Array( b3MeshNode ) * nodes, int count, b3Primitive* primitives, b3Primitive* base,
							 bool useMedianSplit, int* height )
{
	if ( count > B3_DESIRED_TRIANGLES_PER_LEAF )
	{
		// Try to split the input set using the SAH
		b3Split split;
		if ( useMedianSplit )
		{
			split = b3SplitMedian( count, primitives );
		}
		else
		{
			split = b3SplitBinnedSah( count, primitives );
		}

		if ( split.axis < 0 )
		{
			if ( count > B3_MAXIMUM_TRIANGLES_PER_LEAF )
			{
				// Re-split. This is a less optimal split and can create more false positives!
				split = b3SplitHalf( count, primitives );
			}
			else
			{
				b3AABB bounds = B3_BOUNDS3_EMPTY;
				for ( int i = 0; i < count; ++i )
				{
					bounds = b3AABB_Union( bounds, primitives[i].aabb );
				}

				// We have only a few triangles left. Create a leaf.
				int index = b3Array_AddIndex( *nodes );
				b3StoreLeaf( &nodes->data[index], &bounds, count, (int)( primitives - base ) );

				return index;
			}
		}
		B3_VALIDATE( b3ValidateSplit( count, primitives, &split ) );

		// Allocate node and recurse
		int index = b3Array_AddIndex( *nodes );
		int heightLeft = 0, heightRight = 0;
		int leftIndex = b3BuildRecursive( nodes, split.index, primitives, base, useMedianSplit, &heightLeft );
		int rightIndex =
			b3BuildRecursive( nodes, count - split.index, primitives + split.index, base, useMedianSplit, &heightRight );

		*height = b3MaxInt( heightLeft, heightRight ) + 1;

		B3_UNUSED( leftIndex );
		B3_ASSERT( leftIndex - index == 1 && rightIndex - index > 1 );

		b3AABB aabb = b3AABB_Union( split.leftBounds, split.rightBounds );
		b3MeshNode* node = b3Array_Get( *nodes, index );
		node->data.asNode.axis = split.axis;
		node->data.asNode.childOffset = rightIndex - index;
		node->lowerBound = aabb.lowerBound;
		node->upperBound = aabb.upperBound;
		// triangleOffset is leaf-only, but lives outside the union — zero it so mesh->hash is deterministic
		node->triangleOffset = 0;

		return index;
	}

	b3AABB aabb = B3_BOUNDS3_EMPTY;
	for ( int i = 0; i < count; ++i )
	{
		aabb = b3AABB_Union( aabb, primitives[i].aabb );
	}

	int index = b3Array_AddIndex( *nodes );
	b3StoreLeaf( &nodes->data[index], &aabb, count, (int)( primitives - base ) );

	*height = 1;

	return index;
}

static bool b3SortMeshTriangles( b3MeshData* mesh )
{
	b3MeshTriangle* triangles = b3GetMeshTrianglesWrite( mesh );
	uint8_t* materialIndices = b3GetMeshMaterialIndicesWrite( mesh );

	// Sort triangles in depth-first-order
	int offset = 0;
	b3Array( b3MeshTriangle ) tempTriangles;
	b3Array_CreateN( tempTriangles, mesh->triangleCount );

	b3Array( uint8_t ) tempMaterialIndices;
	b3Array_CreateN( tempMaterialIndices, mesh->triangleCount );

	int count = 0;
	b3MeshNode* stack[B3_MESH_STACK_SIZE];
	stack[count++] = b3GetRootWrite( mesh );

	while ( count > 0 )
	{
		b3MeshNode* node = stack[--count];

		if ( b3IsLeaf( node ) == false )
		{
			if ( count >= B3_MESH_STACK_SIZE - 2 )
			{
				return false;
			}

			stack[count++] = b3GetRightChildWrite( node );
			stack[count++] = b3GetLeftChildWrite( node );
		}
		else
		{
			int triangleCount = node->data.asLeaf.triangleCount;
			int triangleOffset = node->triangleOffset;

			for ( int triangle = 0; triangle < triangleCount; ++triangle )
			{
				int index = triangleOffset + triangle;
				b3Array_Push( tempTriangles, triangles[index] );
				b3Array_Push( tempMaterialIndices, materialIndices[index] );
			}

			node->triangleOffset = offset;
			offset += triangleCount;
		}
	}

	B3_ASSERT( offset == tempTriangles.count );
	B3_ASSERT( tempTriangles.count == mesh->triangleCount );
	B3_ASSERT( tempMaterialIndices.count == mesh->triangleCount );

	// Copy sorted triangle array back to tree
	memcpy( triangles, tempTriangles.data, mesh->triangleCount * sizeof( b3MeshTriangle ) );
	memcpy( materialIndices, tempMaterialIndices.data, mesh->triangleCount * sizeof( uint8_t ) );

	b3Array_Destroy( tempTriangles );
	b3Array_Destroy( tempMaterialIndices );

	return true;
}

typedef struct
{
	int vertex1;
	int vertex2;
	int triangle1;
	int triangle2;
	uint16_t triangleCount;

	// The index of an edge within the parent triangle: 0, 1, or 2. 0xFF is unset
	uint8_t triangleEdgeIndex1;
	uint8_t triangleEdgeIndex2;
} b3MeshEdge;

#define NAME b3EdgeMap
#define KEY_TY uint64_t
#define VAL_TY int
#define HASH_FN vt_hash_integer
#define CMPR_FN vt_cmpr_integer
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

#if 0
// todo this is for testing other hash tables
struct b3TestHash
{
	size_t operator()( uint64_t key ) const
	{
		key ^= key >> 23;
		key *= 0x2127599bf4325c37ull;
		key ^= key >> 47;
		return (size_t)key;
	}
};
#endif

// Results for MeshCreationBenchmark
// eastl::hash_map : 4.9703 ms and 5.1445ms with FastHash function
// std::unordered_map : 4.8755 ms and 4.4780ms with FastHash function
// verstable : 3.3968 ms with default FastHash
// no edge identification : 1.7396 ms
static void b3IdentifyEdges( b3MeshData* mesh )
{
	b3MeshTriangle* triangles = b3GetMeshTrianglesWrite( mesh );
	const b3Vec3* vertices = b3GetMeshVertices( mesh );
	uint8_t* flags = b3GetMeshFlagsWrite( mesh );

	int triangleCount = mesh->triangleCount;
	int edgeCount = 3 * triangleCount;
	b3MeshEdge* edges = B3_ALLOC( b3MeshEdge, edgeCount );
	b3Vec3* normals = B3_ALLOC( b3Vec3, triangleCount );

	for ( int i = 0; i < triangleCount; ++i )
	{
		b3MeshTriangle* triangle = triangles + i;
		int i1 = triangle->index1;
		int i2 = triangle->index2;
		int i3 = triangle->index3;

		edges[3 * i + 0].vertex1 = b3MinInt( i1, i2 );
		edges[3 * i + 0].vertex2 = b3MaxInt( i1, i2 );
		edges[3 * i + 0].triangle1 = i;
		edges[3 * i + 0].triangle2 = B3_NULL_INDEX;
		edges[3 * i + 0].triangleEdgeIndex1 = 0;
		edges[3 * i + 0].triangleEdgeIndex2 = 0xFF;
		edges[3 * i + 0].triangleCount = 1;

		edges[3 * i + 1].vertex1 = b3MinInt( i2, i3 );
		edges[3 * i + 1].vertex2 = b3MaxInt( i2, i3 );
		edges[3 * i + 1].triangle1 = i;
		edges[3 * i + 1].triangle2 = B3_NULL_INDEX;
		edges[3 * i + 1].triangleEdgeIndex1 = 1;
		edges[3 * i + 1].triangleEdgeIndex2 = 0xFF;
		edges[3 * i + 1].triangleCount = 1;

		edges[3 * i + 2].vertex1 = b3MinInt( i3, i1 );
		edges[3 * i + 2].vertex2 = b3MaxInt( i3, i1 );
		edges[3 * i + 2].triangle1 = i;
		edges[3 * i + 2].triangle2 = B3_NULL_INDEX;
		edges[3 * i + 2].triangleEdgeIndex1 = 2;
		edges[3 * i + 2].triangleEdgeIndex2 = 0xFF;
		edges[3 * i + 2].triangleCount = 1;

		b3Vec3 v1 = vertices[i1];
		b3Vec3 v2 = vertices[i2];
		b3Vec3 v3 = vertices[i3];

		b3Vec3 e1 = b3Sub( v2, v1 );
		b3Vec3 e2 = b3Sub( v3, v1 );
		b3Vec3 n = b3Cross( e1, e2 );

		normals[i] = b3Normalize( n );
	}

	b3EdgeMap map;
	b3EdgeMap_init( &map );
	b3EdgeMap_reserve( &map, edgeCount );

	uint64_t key = (uint64_t)edges[0].vertex1 << 32 | (uint64_t)edges[0].vertex2;
	b3EdgeMap_insert( &map, key, 0 );

	// Find unique edges and assign adjacency
	for ( int i = 1; i < edgeCount; ++i )
	{
		b3MeshEdge* edge = edges + i;
		key = (uint64_t)edge->vertex1 << 32 | (uint64_t)edge->vertex2;
		b3EdgeMap_itr itr = b3EdgeMap_get( &map, key );

		if ( b3EdgeMap_is_end( itr ) )
		{
			b3EdgeMap_insert( &map, key, i );
		}
		else
		{
			int otherIndex = itr.data->val;
			B3_ASSERT( otherIndex < i );

			b3MeshEdge* base = edges + otherIndex;
			if ( base->triangleCount == 1 )
			{
				base->triangle2 = edge->triangle1;
				base->triangleEdgeIndex2 = edge->triangleEdgeIndex1;
			}

			base->triangleCount += 1;
		}
	}

	b3EdgeMap_cleanup( &map );

	for ( int i = 0; i < edgeCount; ++i )
	{
		b3MeshEdge* edge = edges + i;
		if ( edge->triangleCount != 2 )
		{
			continue;
		}

		B3_ASSERT( edge->triangleEdgeIndex1 < 3 );
		B3_ASSERT( edge->triangleEdgeIndex2 < 3 );

		b3MeshTriangle* triangle1 = triangles + edge->triangle1;
		b3MeshTriangle* triangle2 = triangles + edge->triangle2;
		uint8_t* flag1 = flags + edge->triangle1;
		uint8_t* flag2 = flags + edge->triangle2;

		int j1 = triangle2->index1;
		int j2 = triangle2->index2;
		int j3 = triangle2->index3;

		int opposite = B3_NULL_INDEX;

		switch ( edge->triangleEdgeIndex2 )
		{
			case 0:
				opposite = j3;
				break;

			case 1:
				opposite = j1;
				break;

			case 2:
				opposite = j2;
				break;

			default:
				B3_ASSERT( false );
		}

		int i1 = triangle1->index1;
		int i2 = triangle1->index2;
		int i3 = triangle1->index3;

		b3Vec3 v1 = vertices[i1];
		b3Vec3 v2 = vertices[i2];
		b3Vec3 v3 = vertices[i3];
		b3Vec3 p = vertices[opposite];

		float cos5Deg = 0.9962f;
		float signedVolume = b3SignedVolume( v1, v2, v3, p );
		b3Vec3 n1 = normals[edge->triangle1];
		b3Vec3 n2 = normals[edge->triangle2];
		float cosAngle = b3Dot( n1, n2 );
		if ( signedVolume > 0.0f || cosAngle > cos5Deg )
		{
			int edgeFlags[3] = { b3_concaveEdge1, b3_concaveEdge2, b3_concaveEdge3 };
			*flag1 |= edgeFlags[edge->triangleEdgeIndex1];
			*flag2 |= edgeFlags[edge->triangleEdgeIndex2];
		}

		if ( signedVolume < 0.0f || cosAngle > cos5Deg )
		{
			int edgeFlags[3] = { b3_inverseConcaveEdge1, b3_inverseConcaveEdge2, b3_inverseConcaveEdge3 };
			*flag1 |= edgeFlags[edge->triangleEdgeIndex1];
			*flag2 |= edgeFlags[edge->triangleEdgeIndex2];
		}
	}

	B3_FREE( normals, b3Vec3, triangleCount );
	B3_FREE( edges, b3MeshEdge, edgeCount );
}

b3MeshData* b3CreateGridMesh( int xCount, int zCount, float cellWidth, int materialCount, bool identifyEdges )
{
	B3_ASSERT( 0 <= materialCount && materialCount <= UINT8_MAX );

	// Create vertices
	int vertexCount = ( xCount + 1 ) * ( zCount + 1 );

	b3Array( b3Vec3 ) vertices = { 0 };
	b3Array_Resize( vertices, vertexCount );
	int index = 0;

	float xWidth = cellWidth * xCount;
	float zWidth = cellWidth * zCount;

	float x = -0.5f * xWidth;
	for ( int ix = 0; ix <= xCount; ++ix )
	{
		float z = -0.5f * zWidth;
		for ( int iz = 0; iz <= zCount; ++iz )
		{
			vertices.data[index] = (b3Vec3){ x, 0.0f, z };
			z += cellWidth;
			index += 1;
		}
		x += cellWidth;
	}
	B3_ASSERT( index == vertexCount );

	// Triangles
	int triangleCount = 2 * xCount * zCount;

	b3Array( int ) indices = { 0 };
	b3Array_Resize( indices, 3 * triangleCount );

	b3Array( uint8_t ) materialIndices = { 0 };
	b3Array_Resize( materialIndices, triangleCount );

	int materialIndex = 0;
	index = 0;
	for ( int ix = 0; ix < xCount; ++ix )
	{
		for ( int iz = 0; iz < zCount; ++iz )
		{
			int index1 = iz + ( zCount + 1 ) * ix;
			int index2 = index1 + 1;
			int index3 = index2 + ( zCount + 1 );
			int index4 = index3 - 1;

			B3_ASSERT( index1 < vertexCount );
			B3_ASSERT( index2 < vertexCount );
			B3_ASSERT( index3 < vertexCount );
			B3_ASSERT( index4 < vertexCount );

			indices.data[index + 0] = index1;
			indices.data[index + 1] = index2;
			indices.data[index + 2] = index3;

			indices.data[index + 3] = index3;
			indices.data[index + 4] = index4;
			indices.data[index + 5] = index1;

			if ( materialCount > 0 )
			{
				materialIndices.data[2 * materialIndex + 0] = (uint8_t)( materialIndex % materialCount );
				materialIndices.data[2 * materialIndex + 1] = (uint8_t)( materialIndex % materialCount );
			}

			materialIndex += 1;
			index += 6;
		}
	}
	B3_ASSERT( index == 3 * triangleCount );

	b3MeshDef def = { 0 };
	def.vertexCount = vertices.count;
	def.vertices = vertices.data;
	def.triangleCount = indices.count / 3;
	def.indices = indices.data;
	def.materialIndices = materialCount > 0 ? materialIndices.data : NULL;
	def.useMedianSplit = true;
	def.identifyEdges = identifyEdges;

	b3MeshData* meshData = b3CreateMesh( &def, NULL, 0 );

	b3Array_Destroy( indices );
	b3Array_Destroy( vertices );
	b3Array_Destroy( materialIndices );

	return meshData;
}

b3MeshData* b3CreateWaveMesh( int xCount, int zCount, float cellWidth, float amplitude, float rowFrequency,
							  float columnFrequency )
{
	// Create vertices
	int vertexCount = ( xCount + 1 ) * ( zCount + 1 );

	b3Array( b3Vec3 ) vertices = { 0 };
	b3Array_Resize( vertices, vertexCount );
	int index = 0;

	float xWidth = cellWidth * xCount;
	float zWidth = cellWidth * zCount;

	float omegaZ = 2.0f * B3_PI * rowFrequency * cellWidth;
	float omegaX = 2.0f * B3_PI * columnFrequency * cellWidth;

	float x = -0.5f * xWidth;
	for ( int ix = 0; ix <= xCount; ++ix )
	{
		float rowHeight = sinf( omegaX * ix );

		float z = -0.5f * zWidth;
		for ( int iz = 0; iz <= zCount; ++iz )
		{
			float columnHeight = sinf( omegaZ * iz );

			float y = amplitude * rowHeight * columnHeight;
			vertices.data[index] = (b3Vec3){ x, y, z };
			z += cellWidth;
			index += 1;
		}
		x += cellWidth;
	}
	B3_ASSERT( index == vertexCount );

	// Triangles
	int triangleCount = 2 * xCount * zCount;

	b3Array( int ) indices = { 0 };
	b3Array_Resize( indices, 3 * triangleCount );

	index = 0;
	for ( int ix = 0; ix < xCount; ++ix )
	{
		for ( int iz = 0; iz < zCount; ++iz )
		{
			int index1 = iz + ( zCount + 1 ) * ix;
			int index2 = index1 + 1;
			int index3 = index2 + ( zCount + 1 );
			int index4 = index3 - 1;

			B3_ASSERT( index1 < vertexCount );
			B3_ASSERT( index2 < vertexCount );
			B3_ASSERT( index3 < vertexCount );
			B3_ASSERT( index4 < vertexCount );

			indices.data[index + 0] = index1;
			indices.data[index + 1] = index2;
			indices.data[index + 2] = index3;

			indices.data[index + 3] = index3;
			indices.data[index + 4] = index4;
			indices.data[index + 5] = index1;

			index += 6;
		}
	}
	B3_ASSERT( index == 3 * triangleCount );

	b3MeshDef def = { 0 };
	def.vertexCount = vertices.count;
	def.vertices = vertices.data;
	def.triangleCount = indices.count / 3;
	def.indices = indices.data;
	def.useMedianSplit = true;
	def.identifyEdges = true;

	b3MeshData* meshData = b3CreateMesh( &def, NULL, 0 );

	b3Array_Destroy( indices );
	b3Array_Destroy( vertices );

	return meshData;
}

b3MeshData* b3CreateTorusMesh( int radialResolution, int tubularResolution, float radius, float thickness )
{
	// Create vertices
	b3Array( b3Vec3 ) vertices = { 0 };

	for ( int radialIndex = 0; radialIndex < radialResolution; radialIndex++ )
	{
		for ( int tubularIndex = 0; tubularIndex < tubularResolution; tubularIndex++ )
		{
			float u = (float)tubularIndex / tubularResolution * B3_TWO_PI;
			float v = (float)radialIndex / radialResolution * B3_TWO_PI;

			float x = ( radius + thickness * b3Cos( v ) ) * b3Cos( u );
			float y = ( radius + thickness * b3Cos( v ) ) * b3Sin( u );
			float z = thickness * b3Sin( v );

			b3Vec3 vertex = { x, y, z };
			b3Array_Push( vertices, vertex );
		}
	}

	// Triangles
	b3Array( int ) indices = { 0 };
	for ( int radialIndex1 = 0; radialIndex1 < radialResolution; radialIndex1++ )
	{
		int radialIndex2 = ( radialIndex1 + 1 ) % radialResolution;
		for ( int tubularIndex1 = 0; tubularIndex1 < tubularResolution; tubularIndex1++ )
		{
			int tubularIndex2 = ( tubularIndex1 + 1 ) % tubularResolution;
			int index1 = radialIndex1 * tubularResolution + tubularIndex1;
			int index2 = radialIndex1 * tubularResolution + tubularIndex2;
			int index3 = radialIndex2 * tubularResolution + tubularIndex2;
			int index4 = radialIndex2 * tubularResolution + tubularIndex1;

			b3Array_Push( indices, index1 );
			b3Array_Push( indices, index2 );
			b3Array_Push( indices, index3 );

			b3Array_Push( indices, index3 );
			b3Array_Push( indices, index4 );
			b3Array_Push( indices, index1 );
		}
	}

	b3MeshDef def = { 0 };
	def.vertexCount = vertices.count;
	def.vertices = vertices.data;
	def.triangleCount = indices.count / 3;
	def.indices = indices.data;
	def.useMedianSplit = false;
	def.identifyEdges = true;

	b3MeshData* meshData = b3CreateMesh( &def, NULL, 0 );

	b3Array_Destroy( vertices );
	b3Array_Destroy( indices );
	return meshData;
}

b3MeshData* b3CreateBoxMesh( b3Vec3 center, b3Vec3 extent, bool identifyEdges )
{
	float x = extent.x;
	float y = extent.y;
	float z = extent.z;
	b3Vec3 vertices[] = {
		{ x, y, z }, { -x, y, z }, { -x, -y, z }, { x, -y, z }, { x, y, -z }, { -x, y, -z }, { -x, -y, -z }, { x, -y, -z },
	};

	for ( int i = 0; i < 8; ++i )
	{
		vertices[i] = b3Add( vertices[i], center );
	}

	int indices[] = {
		0, 1, 3, 1, 2, 3, // front
		0, 4, 1, 1, 4, 5, // top
		0, 3, 7, 4, 0, 7, // right
		4, 7, 5, 6, 5, 7, // back
		1, 5, 2, 6, 2, 5, // left
		3, 2, 7, 6, 7, 2, // bottom
	};

	b3MeshDef def = { 0 };
	def.vertexCount = 8;
	def.vertices = vertices;
	def.triangleCount = 12;
	def.indices = indices;
	def.useMedianSplit = false;
	def.identifyEdges = identifyEdges;

	return b3CreateMesh( &def, NULL, 0 );
}

b3MeshData* b3CreateHollowBoxMesh(b3Vec3 center, b3Vec3 extent)
{
	float x = extent.x;
	float y = extent.y;
	float z = extent.z;
	b3Vec3 vertices[] = {
		{ x, y, z }, { -x, y, z }, { -x, -y, z }, { x, -y, z }, { x, y, -z }, { -x, y, -z }, { -x, -y, -z }, { x, -y, -z },
	};

	for ( int i = 0; i < 8; ++i )
	{
		vertices[i] = b3Add( vertices[i], center );
	}

	int indices[] = {
		3, 1, 0, 3, 2, 1, // front
		1, 4, 0, 5, 4, 1, // top
		7, 3, 0, 7, 0, 4, // right
		5, 7, 4, 7, 5, 6, // back
		2, 5, 1, 5, 2, 6, // left
		7, 2, 3, 2, 7, 6, // bottom
	};

	b3MeshDef def = { 0 };
	def.vertexCount = 8;
	def.vertices = vertices;
	def.triangleCount = 12;
	def.indices = indices;
	def.useMedianSplit = false;
	def.identifyEdges = true;

	return b3CreateMesh( &def, NULL, 0 );
}

b3MeshData* b3CreatePlatformMesh( b3Vec3 center, float height, float topWidth, float bottomWidth )
{
	float hb = 0.5f * bottomWidth;
	float ht = 0.5f * topWidth;
	float hy = 0.5f * height;
	b3Vec3 vertices[] = {
		{ ht, hy, ht },	 { -ht, hy, ht },  { -hb, -hy, hb },  { hb, -hy, hb },
		{ ht, hy, -ht }, { -ht, hy, -ht }, { -hb, -hy, -hb }, { hb, -hy, -hb },
	};

	for ( int i = 0; i < 8; ++i )
	{
		vertices[i] = b3Add( vertices[i], center );
	}

	int indices[] = {
		0, 1, 3, 1, 2, 3, // front
		0, 4, 1, 1, 4, 5, // top
		0, 3, 7, 4, 0, 7, // right
		4, 7, 5, 6, 5, 7, // back
		1, 5, 2, 6, 2, 5, // left
		3, 2, 7, 6, 7, 2, // bottom
	};

	b3MeshDef def = { 0 };
	def.vertexCount = 8;
	def.vertices = vertices;
	def.triangleCount = 12;
	def.indices = indices;
	def.useMedianSplit = true;
	def.identifyEdges = true;

	return b3CreateMesh( &def, NULL, 0 );
}

// todo this should fail if the mesh has a height greater than B3_MESH_STACK_SIZE
b3MeshData* b3CreateMesh( const b3MeshDef* def, int* degenerateTriangleIndices, int degenerateCapacity )
{
	if ( def->vertexCount < 3 || def->vertices == NULL || def->triangleCount <= 0 || def->indices == NULL )
	{
		return NULL;
	}

	int triangleCount = def->triangleCount;
	if ( triangleCount == 0 )
	{
		return NULL;
	}

	int vertexCount = def->vertexCount;

	b3AABB meshBounds = B3_BOUNDS3_EMPTY;

	// Clone indices and vertices to support welding
	b3Array( int ) indices;
	b3Array_CreateN( indices, 3 * triangleCount );

	b3Array( b3Vec3 ) vertices;
	b3Array_CreateN( vertices, vertexCount );

	if ( def->weldVertices && def->weldTolerance > 0.0f )
	{
		b3Array_Resize( vertices, vertexCount );
		b3Array_Resize( indices, 3 * triangleCount );
		b3WeldData data = {
			.srcVertices = def->vertices,
			.srcIndices = def->indices,
			.dstVertices = vertices.data,
			.dstIndices = indices.data,
			.vertexCount = vertexCount,
			.indexCount = 3 * triangleCount,
		};
		vertices.count = b3WeldVertices( &data, def->weldTolerance );
		vertexCount = vertices.count;
		B3_ASSERT( vertexCount <= def->vertexCount );
	}
	else
	{
		b3Array_Append( vertices, def->vertices, vertexCount );
		b3Array_Append( indices, def->indices, 3 * triangleCount );
	}

	b3Array( b3Primitive ) primitives;
	b3Array_CreateN( primitives, triangleCount );
	int degenerateCount = 0;
	float minArea = 0.01f * B3_LINEAR_SLOP * B3_LINEAR_SLOP;
	float surfaceArea = 0.0f;
	int materialCount = 1;

	for ( int index = 0; index < triangleCount; ++index )
	{
		int index1 = indices.data[3 * index + 0];
		int index2 = indices.data[3 * index + 1];
		int index3 = indices.data[3 * index + 2];

		b3Vec3 vertex1 = vertices.data[index1];
		b3Vec3 vertex2 = vertices.data[index2];
		b3Vec3 vertex3 = vertices.data[index3];

		b3Vec3 normal = b3Cross( b3Sub( vertex2, vertex1 ), b3Sub( vertex3, vertex1 ) );
		float area = 0.5f * b3Length( normal );

		if ( area < minArea )
		{
			// b3Log( "degenerate: %d %d %d\n", index1, index2, index3 );

			if ( index1 != index2 && index1 != index3 && index2 != index3 )
			{
				degenerateCount += 1;
				if ( degenerateTriangleIndices != NULL && degenerateCount < degenerateCapacity )
				{
					degenerateTriangleIndices[degenerateCount - 1] = index;
				}
			}

			continue;
		}

		surfaceArea += area;

		b3AABB box = {
			b3Min( vertex1, b3Min( vertex2, vertex3 ) ),
			b3Max( vertex1, b3Max( vertex2, vertex3 ) ),
		};

		b3Vec3 center = b3AABB_Center( box );

		b3Primitive primitive = {
			.aabb = box,
			.center = center,
			.triangleIndex = index,
		};
		b3Array_Push( primitives, primitive );

		if ( def->materialIndices != NULL )
		{
			materialCount = b3MaxInt( materialCount, def->materialIndices[index] + 1 );
		}

		meshBounds = b3AABB_Union( meshBounds, box );
	}

	// Update triangle count due to degenerates being skipped
	triangleCount = primitives.count;

	if ( b3IsSaneAABB( meshBounds ) == false )
	{
		b3Array_Destroy( primitives );
		return NULL;
	}

	// Build the tree (this reorders the builder triangles)
	b3Array( b3MeshNode ) tempNodes;
	b3Array_CreateN( tempNodes, 2 * triangleCount - 1 );

	int treeHeight = 0;
	b3BuildRecursive( &tempNodes, triangleCount, primitives.data, primitives.data, def->useMedianSplit, &treeHeight );

	// Allocate the mesh
	size_t byteCount = b3AlignUp8( sizeof( b3MeshData ) );
	int nodeOffset = (int)byteCount;
	byteCount += b3AlignUp8( tempNodes.count * sizeof( b3MeshNode ) );
	int vertexOffset = (int)byteCount;
	byteCount += b3AlignUp8( vertexCount * sizeof( b3Vec3 ) );
	int triangleOffset = (int)byteCount;
	byteCount += b3AlignUp8( triangleCount * sizeof( b3MeshTriangle ) );
	int materialIndicesOffset = (int)byteCount;
	byteCount += b3AlignUp8( triangleCount * sizeof( uint8_t ) );
	int flagsOffset = (int)byteCount;
	byteCount += b3AlignUp8( triangleCount * sizeof( uint8_t ) );

	b3MeshData* mesh = b3Alloc( byteCount );

	// zero initialize for determinism
	memset( mesh, 0, byteCount );

	mesh->version = B3_MESH_VERSION;
	mesh->byteCount = (int)byteCount;
	mesh->bounds = meshBounds;
	mesh->surfaceArea = surfaceArea;
	mesh->nodeCount = tempNodes.count;
	mesh->treeHeight = treeHeight;
	mesh->vertexCount = vertexCount;
	mesh->triangleCount = triangleCount;
	mesh->degenerateCount = degenerateCount;
	mesh->nodeOffset = nodeOffset;
	mesh->vertexOffset = vertexOffset;
	mesh->triangleOffset = triangleOffset;
	mesh->materialOffset = materialIndicesOffset;
	mesh->materialCount = materialCount;
	mesh->flagsOffset = flagsOffset;

	b3MeshNode* nodes = b3GetMeshNodesWrite( mesh );
	b3MeshTriangle* triangles = b3GetMeshTrianglesWrite( mesh );
	b3Vec3* meshVertices = b3GetMeshVerticesWrite( mesh );
	uint8_t* materialIndices = b3GetMeshMaterialIndicesWrite( mesh );
	uint8_t* flags = b3GetMeshFlagsWrite( mesh );

	memcpy( nodes, tempNodes.data, tempNodes.count * sizeof( b3MeshNode ) );
	memcpy( meshVertices, vertices.data, vertexCount * sizeof( b3Vec3 ) );

	for ( int index = 0; index < triangleCount; ++index )
	{
		b3Primitive primitive = primitives.data[index];
		triangles[index].index1 = indices.data[3 * primitive.triangleIndex + 0];
		triangles[index].index2 = indices.data[3 * primitive.triangleIndex + 1];
		triangles[index].index3 = indices.data[3 * primitive.triangleIndex + 2];
		flags[index] = 0;

		// Copy material indices if they exist. Otherwise the material indices are all zeroes.
		if ( def->materialIndices != NULL )
		{
			uint8_t materialIndex = def->materialIndices[primitive.triangleIndex];
			materialIndices[index] = materialIndex;
		}
	}

	// Sort triangle in DFS order. Casts and volume queries will return sorted arrays.
	// This also sorts material indices, but not the materials.
	// This can fail if the BVH height is too large.
	bool success = b3SortMeshTriangles( mesh );
	if ( success == false )
	{
		b3Array_Destroy( tempNodes );
		b3Array_Destroy( primitives );
		return NULL;
	}

	if ( def->identifyEdges )
	{
		b3IdentifyEdges( mesh );
	}

	B3_VALIDATE( b3IsNonDegenerate( mesh, minArea ) );
	B3_VALIDATE( b3IsConsistent( mesh ) );

	b3Array_Destroy( tempNodes );
	b3Array_Destroy( primitives );
	b3Array_Destroy( indices );
	b3Array_Destroy( vertices );

	mesh->hash = 0;
	mesh->hash = b3NonZeroHash( b3Hash( B3_HASH_INIT, (uint8_t*)mesh, mesh->byteCount ) );

	return mesh;
}

void b3DestroyMesh( b3MeshData* mesh )
{
	b3Free( mesh, mesh->byteCount );
}

bool b3OverlapMesh( const b3Mesh* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy )
{
	B3_ASSERT( proxy->count > 0 );
	b3SimplexCache cache = { 0 };

	b3Vec3 buffer[B3_MAX_SHAPE_CAST_POINTS];
	b3ShapeProxy localProxy = b3MakeLocalProxy( proxy, shapeTransform, buffer );
	b3AABB aabb = b3ComputeProxyAABB( &localProxy );

	b3Vec3 meshScale = shape->scale;

	// Scale may have reflection so min/max may become invalid when unscaled
	b3V32 scale = b3LoadV( &meshScale.x );
	b3V32 invScale = b3DivV( b3_oneV, scale );
	b3V32 temp1 = b3MulV( invScale, b3LoadV( &aabb.lowerBound.x ) );
	b3V32 temp2 = b3MulV( invScale, b3LoadV( &aabb.upperBound.x ) );
	b3V32 invScaledBoundsMin = b3MinV( temp1, temp2 );
	b3V32 invScaledBoundsMax = b3MaxV( temp1, temp2 );
	b3V32 invScaledBoundsCenter = b3MulV( b3_halfV, b3AddV( invScaledBoundsMin, invScaledBoundsMax ) );
	b3V32 invScaledBoundsExtent = b3SubV( invScaledBoundsMax, invScaledBoundsCenter );

	b3DistanceInput input;
	input.proxyB = localProxy;
	input.transform = b3Transform_identity;
	input.useRadii = true;

	int count = 0;
	const b3MeshNode* stack[B3_MESH_STACK_SIZE];
	const b3MeshNode* node = b3GetRoot( shape->data );
	const b3MeshTriangle* triangles = b3GetMeshTriangles( shape->data );
	const b3Vec3* vertices = b3GetMeshVertices( shape->data );

	while ( true )
	{
		// Test node overlap in unscaled space
		b3V32 nodeMin = b3LoadV( &node->lowerBound.x );
		b3V32 nodeMax = b3LoadV( &node->upperBound.x );
		if ( b3TestBoundsOverlap( nodeMin, nodeMax, invScaledBoundsMin, invScaledBoundsMax ) )
		{
			if ( b3IsLeaf( node ) )
			{
				int triangleCount = node->data.asLeaf.triangleCount;
				int triangleOffset = node->triangleOffset;

				for ( int index = 0; index < triangleCount; ++index )
				{
					int triangleIndex = triangleOffset + index;
					b3MeshTriangle triangle = triangles[triangleIndex];

					b3Vec3 vertex1 = vertices[triangle.index1];
					b3Vec3 vertex2 = vertices[triangle.index2];
					b3Vec3 vertex3 = vertices[triangle.index3];
					b3V32 v1 = b3LoadV( &vertex1.x );
					b3V32 v2 = b3LoadV( &vertex2.x );
					b3V32 v3 = b3LoadV( &vertex3.x );

					// Bounding box overlap test in unscaled space
					if ( b3TestBoundsTriangleOverlap( invScaledBoundsCenter, invScaledBoundsExtent, v1, v2, v3 ) )
					{
						// Shape-triangle overlap test in scaled space. Winding order doesn't matter.
						b3Vec3 triangleVertices[] = { b3Mul( meshScale, vertex1 ), b3Mul( meshScale, vertex2 ),
													  b3Mul( meshScale, vertex3 ) };
						input.proxyA = (b3ShapeProxy){ triangleVertices, 3, 0.0f };

						// reset the cache
						cache.count = 0;

						// get distance between triangle and query shape
						b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );

						float tolerance = 0.1f * B3_LINEAR_SLOP;
						if ( output.distance < tolerance )
						{
							// overlap detected
							return true;
						}
					}
				}
			}
			else
			{
				// Recurse
				B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
				stack[count++] = b3GetRightChild( node );
				node = b3GetLeftChild( node );

				continue;
			}
		}

		if ( count == 0 )
		{
			break;
		}
		node = stack[--count];
	}

	return false;
}

b3AABB b3ComputeMeshAABB( const b3MeshData* shape, b3Transform transform, b3Vec3 scale )
{
	b3Vec3 scaledLower = b3Mul( scale, shape->bounds.lowerBound );
	b3Vec3 scaledUpper = b3Mul( scale, shape->bounds.upperBound );
	b3AABB bounds = { b3Min( scaledLower, scaledUpper ), b3Max( scaledLower, scaledUpper ) };
	return b3AABB_Transform( transform, bounds );
}

b3CastOutput b3RayCastMesh( const b3Mesh* mesh, const b3RayCastInput* input )
{
	const b3MeshData* data = mesh->data;
	b3Vec3 meshScale = mesh->scale;

	b3CastOutput bestOutput = { 0 };
	bestOutput.fraction = input->maxFraction;
	bestOutput.triangleIndex = B3_NULL_INDEX;

	b3V32 lambda = b3SplatV( input->maxFraction );

	b3V32 rayStart = b3LoadV( &input->origin.x );
	b3V32 rayDelta = b3LoadV( &input->translation.x );

	b3V32 scale = b3LoadV( &meshScale.x );
	b3V32 invScale = b3DivV( b3_oneV, scale );
	bool clockwise = meshScale.x * meshScale.y * meshScale.z < 0.0f;

	// Use the inverse scaled ray for traversal of the BVH
	b3V32 invScaledRayStart = b3MulV( invScale, rayStart );
	b3V32 invScaledRayDelta = b3MulV( invScale, rayDelta );
	b3V32 invScaledRayEnd = b3AddV( invScaledRayStart, b3MulV( lambda, invScaledRayDelta ) );
	b3V32 invScaledRayMin = b3MinV( invScaledRayStart, invScaledRayEnd );
	b3V32 invScaledRayMax = b3MaxV( invScaledRayStart, invScaledRayEnd );

	int count = 0;
	const b3MeshNode* stack[B3_MESH_STACK_SIZE];
	const b3MeshNode* node = b3GetRoot( data );
	const b3MeshTriangle* triangles = b3GetMeshTriangles( data );
	const b3Vec3* vertices = b3GetMeshVertices( data );
	const uint8_t* materialIndices = b3GetMeshMaterialIndices( data );

	while ( true )
	{
		// Test node/ray overlap using SAT
		b3V32 nodeMin = b3LoadV( &node->lowerBound.x );
		b3V32 nodeMax = b3LoadV( &node->upperBound.x );
		if ( b3TestBoundsOverlap( nodeMin, nodeMax, invScaledRayMin, invScaledRayMax ) &&
			 b3TestBoundsRayOverlap( nodeMin, nodeMax, invScaledRayStart, invScaledRayDelta ) )
		{
			// SAT: The node and ray overlap - process leaf node or recurse
			if ( b3IsLeaf( node ) )
			{
				int triangleCount = node->data.asLeaf.triangleCount;
				int triangleOffset = node->triangleOffset;

				for ( int index = 0; index < triangleCount; ++index )
				{
					int triangleIndex = triangleOffset + index;
					b3MeshTriangle triangle = triangles[triangleIndex];

					// Collide ray with triangle in scaled space
					b3Vec3 vertex1 = b3Mul( meshScale, vertices[triangle.index1] );
					b3Vec3 vertex2, vertex3;

					// The CPU should predict this branch
					if ( clockwise )
					{
						vertex2 = b3Mul( meshScale, vertices[triangle.index3] );
						vertex3 = b3Mul( meshScale, vertices[triangle.index2] );
					}
					else
					{
						vertex2 = b3Mul( meshScale, vertices[triangle.index2] );
						vertex3 = b3Mul( meshScale, vertices[triangle.index3] );
					}

					// Collide ray with triangle in scaled space
					b3V32 v1 = b3LoadV( &vertex1.x );
					b3V32 v2 = b3LoadV( &vertex2.x );
					b3V32 v3 = b3LoadV( &vertex3.x );

					float alpha = b3IntersectRayTriangle( rayStart, rayDelta, v1, v2, v3 );
					B3_ASSERT( 0 <= alpha && alpha <= 1.0f );

					if ( alpha < bestOutput.fraction )
					{
						b3Vec3 edge1 = b3Sub( vertex2, vertex1 );
						b3Vec3 edge2 = b3Sub( vertex3, vertex1 );
						bestOutput.normal = b3Normalize( b3Cross( edge1, edge2 ) );
						bestOutput.point = b3Add( input->origin, b3MulSV( alpha, input->translation ) );
						bestOutput.fraction = alpha;
						bestOutput.triangleIndex = triangleIndex;
						bestOutput.materialIndex = materialIndices[triangleIndex];
						bestOutput.hit = true;

						// Update ray bounds in unscaled space
						lambda = b3SplatV( alpha );
						invScaledRayEnd = b3AddV( invScaledRayStart, b3MulV( lambda, invScaledRayDelta ) );
						invScaledRayMin = b3MinV( invScaledRayStart, invScaledRayEnd );
						invScaledRayMax = b3MaxV( invScaledRayStart, invScaledRayEnd );
					}
				}
			}
			else
			{
				// Determine traversal order (front -> back) and recurse
				int axis = node->data.asNode.axis;
				if ( b3GetV( invScaledRayDelta, axis ) > 0.0f )
				{
					B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
					stack[count++] = b3GetRightChild( node );
					node = b3GetLeftChild( node );
				}
				else
				{
					B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
					stack[count++] = b3GetLeftChild( node );
					node = b3GetRightChild( node );
				}

				continue;
			}
		}

		if ( count == 0 )
		{
			break;
		}
		node = stack[--count];
	}

	return bestOutput;
}

b3CastOutput b3ShapeCastMesh( const b3Mesh* mesh, const b3ShapeCastInput* input )
{
	const b3MeshData* data = mesh->data;
	b3Vec3 meshScale = mesh->scale;

	b3CastOutput bestOutput = { 0 };
	bestOutput.fraction = input->maxFraction;
	bestOutput.triangleIndex = B3_NULL_INDEX;

	b3V32 lambda = b3SplatV( input->maxFraction );

	b3AABB shapeBounds = b3MakeAABB( input->proxy.points, input->proxy.count, input->proxy.radius );
	b3Vec3 center = b3AABB_Center( shapeBounds );
	b3Vec3 extents = b3AABB_Extents( shapeBounds );
	b3V32 shapeExtent = b3LoadV( &extents.x );

	b3V32 rayStart = b3LoadV( &center.x );
	b3V32 rayDelta = b3LoadV( &input->translation.x );
	b3V32 rayEnd = b3AddV( rayStart, b3MulV( lambda, rayDelta ) );
	b3V32 rayMin = b3MinV( rayStart, rayEnd );
	b3V32 rayMax = b3MaxV( rayStart, rayEnd );

	b3V32 scale = b3LoadV( &meshScale.x );
	b3V32 invScale = b3DivV( b3_oneV, scale );
	b3V32 absInvScale = b3AbsV( invScale );
	bool clockwise = meshScale.x * meshScale.y * meshScale.z < 0.0f;

	// Use the inverse scaled shape cast for traversal of the BVH
	b3V32 invScaledRayStart = b3MulV( invScale, rayStart );
	b3V32 invScaledRayDelta = b3MulV( invScale, rayDelta );
	b3V32 invScaledRayEnd = b3AddV( invScaledRayStart, b3MulV( lambda, invScaledRayDelta ) );
	b3V32 invScaledRayMin = b3MinV( invScaledRayStart, invScaledRayEnd );
	b3V32 invScaledRayMax = b3MaxV( invScaledRayStart, invScaledRayEnd );
	b3V32 invScaledShapeExtent = b3MulV( absInvScale, shapeExtent );

	int count = 0;
	const b3MeshNode* stack[B3_MESH_STACK_SIZE];
	const b3MeshNode* node = b3GetRoot( data );
	const b3MeshTriangle* triangles = b3GetMeshTriangles( data );
	const b3Vec3* vertices = b3GetMeshVertices( data );
	const uint8_t* materialIndices = b3GetMeshMaterialIndices( data );

	while ( true )
	{
		// Test node/ray overlap using SAT in unscaled space
		b3V32 nodeMin = b3SubV( b3LoadV( &node->lowerBound.x ), invScaledShapeExtent );
		b3V32 nodeMax = b3AddV( b3LoadV( &node->upperBound.x ), invScaledShapeExtent );

		if ( b3TestBoundsOverlap( nodeMin, nodeMax, invScaledRayMin, invScaledRayMax ) &&
			 b3TestBoundsRayOverlap( nodeMin, nodeMax, invScaledRayStart, invScaledRayDelta ) )
		{
			// SAT: The node and ray overlap - process leaf node or recurse
			if ( b3IsLeaf( node ) )
			{
				int triangleCount = node->data.asLeaf.triangleCount;
				int triangleOffset = node->triangleOffset;

				for ( int index = 0; index < triangleCount; ++index )
				{
					int triangleIndex = triangleOffset + index;
					b3MeshTriangle triangle = triangles[triangleIndex];

					// Collide ray with triangle in scaled space
					b3Vec3 vertex1 = b3Mul( meshScale, vertices[triangle.index1] );
					b3Vec3 vertex2, vertex3;

					// The CPU should predict this branch
					if ( clockwise )
					{
						vertex2 = b3Mul( meshScale, vertices[triangle.index3] );
						vertex3 = b3Mul( meshScale, vertices[triangle.index2] );
					}
					else
					{
						vertex2 = b3Mul( meshScale, vertices[triangle.index2] );
						vertex3 = b3Mul( meshScale, vertices[triangle.index3] );
					}

					b3V32 v1 = b3LoadV( &vertex1.x );
					b3V32 v2 = b3LoadV( &vertex2.x );
					b3V32 v3 = b3LoadV( &vertex3.x );

					b3V32 triangleMin = b3SubV( b3MinV( v1, b3MinV( v2, v3 ) ), shapeExtent );
					b3V32 triangleMax = b3AddV( b3MaxV( v1, b3MaxV( v2, v3 ) ), shapeExtent );

					// Test triangle-ray overlap in scaled space
					if ( b3TestBoundsOverlap( triangleMin, triangleMax, rayMin, rayMax ) )
					{
						// Collide shape with triangle in scaled space
						b3Vec3 origin = vertex1;
						b3Vec3 triangleVertices[] = { b3Vec3_zero, b3Sub( vertex2, origin ), b3Sub( vertex3, origin ) };
						b3Transform shiftedOrigin = { b3Neg( origin ), b3Quat_identity };

						b3ShapeCastPairInput pairInput;
						pairInput.proxyA = (b3ShapeProxy){ triangleVertices, 3, 0.0f };
						pairInput.proxyB = input->proxy;
						pairInput.transform = shiftedOrigin;
						pairInput.maxFraction = bestOutput.fraction;
						pairInput.translationB = input->translation;
						pairInput.canEncroach = input->canEncroach;

						b3CastOutput pairOutput = b3ShapeCast( &pairInput );

						if ( pairOutput.hit )
						{
							pairOutput.point = b3Add( pairOutput.point, origin );

							bestOutput = pairOutput;
							bestOutput.triangleIndex = triangleIndex;
							bestOutput.materialIndex = materialIndices[triangleIndex];

							// Update ray bounds in scaled space
							lambda = b3SplatV( pairOutput.fraction );
							rayEnd = b3AddV( rayStart, b3MulV( lambda, rayDelta ) );
							rayMin = b3MinV( rayStart, rayEnd );
							rayMax = b3MaxV( rayStart, rayEnd );

							// Ray bounds in unscaled space
							invScaledRayEnd = b3AddV( invScaledRayStart, b3MulV( lambda, invScaledRayDelta ) );
							invScaledRayMin = b3MinV( invScaledRayStart, invScaledRayEnd );
							invScaledRayMax = b3MaxV( invScaledRayStart, invScaledRayEnd );
						}
					}
				}
			}
			else
			{
				// Determine traversal order (front -> back) and recurse
				int axis = node->data.asNode.axis;
				if ( b3GetV( invScaledRayDelta, axis ) > 0.0f )
				{
					B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
					stack[count++] = b3GetRightChild( node );
					node = b3GetLeftChild( node );
				}
				else
				{
					B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
					stack[count++] = b3GetLeftChild( node );
					node = b3GetRightChild( node );
				}

				continue;
			}
		}

		if ( count == 0 )
		{
			break;
		}
		node = stack[--count];
	}

	return bestOutput;
}

b3Triangle b3GetMeshTriangle( const b3Mesh* mesh, int triangleIndex )
{
	B3_ASSERT( 0 <= triangleIndex && triangleIndex < mesh->data->triangleCount );

	const b3MeshTriangle* triangles = b3GetMeshTriangles( mesh->data );
	const uint8_t* flags = b3GetMeshFlags( mesh->data );
	const b3Vec3* vertices = b3GetMeshVertices( mesh->data );

	b3Triangle result;
	b3MeshTriangle triangle = triangles[triangleIndex];
	uint8_t triangleFlags = flags[triangleIndex];

	b3Vec3 scale = mesh->scale;

	result.vertices[0] = b3Mul( scale, vertices[triangle.index1] );
	result.i1 = triangle.index1;

	if ( scale.x * scale.y * scale.z < 0.0f )
	{
		result.vertices[1] = b3Mul( scale, vertices[triangle.index3] );
		result.vertices[2] = b3Mul( scale, vertices[triangle.index2] );

		result.i2 = triangle.index3;
		result.i3 = triangle.index2;

		// mesh is inverted, so concave edges are now convex
		result.flags = 0;
		result.flags |= ( triangleFlags & b3_inverseConcaveEdge1 ) ? b3_concaveEdge1 : 0;
		result.flags |= ( triangleFlags & b3_inverseConcaveEdge2 ) ? b3_concaveEdge2 : 0;
		result.flags |= ( triangleFlags & b3_inverseConcaveEdge3 ) ? b3_concaveEdge3 : 0;
	}
	else
	{
		result.vertices[1] = b3Mul( scale, vertices[triangle.index2] );
		result.vertices[2] = b3Mul( scale, vertices[triangle.index3] );

		result.i2 = triangle.index2;
		result.i3 = triangle.index3;
		result.flags = triangleFlags;
	}

	return result;
}

int b3CollideMoverAndMesh( b3PlaneResult* planes, int capacity, const b3Mesh* shape, const b3Capsule* mover )
{
	if ( capacity == 0 )
	{
		return 0;
	}

	b3DistanceInput distanceInput = { 0 };
	distanceInput.proxyB = (b3ShapeProxy){ &mover->center1, 2, 0.0f };
	distanceInput.transform = b3Transform_identity;
	distanceInput.useRadii = false;

	b3SimplexCache cache = { 0 };
	float radius = mover->radius;

	b3V32 center1 = b3LoadV( &mover->center1.x );
	b3V32 center2 = b3LoadV( &mover->center2.x );
	b3V32 r = b3SplatV( radius );
	b3V32 boundsMin = b3SubV( b3MinV( center1, center2 ), r );
	b3V32 boundsMax = b3AddV( b3MaxV( center1, center2 ), r );

	// Scale may have reflection so min/max may become invalid when unscaled
	b3Vec3 meshScale = shape->scale;
	b3V32 scale = b3LoadV( &meshScale.x );
	b3V32 invScale = b3DivV( b3_oneV, scale );
	b3V32 temp1 = b3MulV( invScale, boundsMin );
	b3V32 temp2 = b3MulV( invScale, boundsMax );
	b3V32 invScaledBoundsMin = b3MinV( temp1, temp2 );
	b3V32 invScaledBoundsMax = b3MaxV( temp1, temp2 );
	b3V32 invScaledBoundsCenter = b3MulV( b3_halfV, b3AddV( invScaledBoundsMin, invScaledBoundsMax ) );
	b3V32 invScaledBoundsExtent = b3SubV( invScaledBoundsMax, invScaledBoundsCenter );

	int count = 0;
	const b3MeshNode* stack[B3_MESH_STACK_SIZE];
	const b3MeshNode* node = b3GetRoot( shape->data );
	const b3MeshTriangle* triangles = b3GetMeshTriangles( shape->data );
	const b3Vec3* vertices = b3GetMeshVertices( shape->data );

	int planeCount = 0;
	while ( planeCount < capacity )
	{
		// Test node overlap in unscaled space
		b3V32 nodeMin = b3LoadV( &node->lowerBound.x );
		b3V32 nodeMax = b3LoadV( &node->upperBound.x );
		if ( b3TestBoundsOverlap( nodeMin, nodeMax, invScaledBoundsMin, invScaledBoundsMax ) )
		{
			if ( b3IsLeaf( node ) )
			{
				int triangleCount = node->data.asLeaf.triangleCount;
				int triangleOffset = node->triangleOffset;

				for ( int index = 0; index < triangleCount; ++index )
				{
					int triangleIndex = triangleOffset + index;
					b3MeshTriangle triangle = triangles[triangleIndex];

					b3Vec3 vertex1 = vertices[triangle.index1];
					b3Vec3 vertex2 = vertices[triangle.index2];
					b3Vec3 vertex3 = vertices[triangle.index3];
					b3V32 v1 = b3LoadV( &vertex1.x );
					b3V32 v2 = b3LoadV( &vertex2.x );
					b3V32 v3 = b3LoadV( &vertex3.x );

					// Test triangle bounds overlap in unscaled space
					if ( b3TestBoundsTriangleOverlap( invScaledBoundsCenter, invScaledBoundsExtent, v1, v2, v3 ) )
					{
						// Compute shape distance in scaled space. Winding order doesn't matter.
						// todo implement one-sided collision?
						b3Vec3 triangleVertices[] = { b3Mul( meshScale, vertex1 ), b3Mul( meshScale, vertex2 ),
													  b3Mul( meshScale, vertex3 ) };
						distanceInput.proxyA = (b3ShapeProxy){ triangleVertices, 3, 0.0f };

						// reset the cache
						cache.count = 0;

						// get distance between triangle and query shape
						b3DistanceOutput distanceOutput = b3ShapeDistance( &distanceInput, &cache, NULL, 0 );

						if ( distanceOutput.distance == 0.0f )
						{
							// todo SAT
						}
						else if ( distanceOutput.distance <= mover->radius )
						{
							b3Plane plane = { distanceOutput.normal, mover->radius - distanceOutput.distance };
							planes[planeCount] = (b3PlaneResult){ plane, distanceOutput.pointA };
							planeCount += 1;

							if ( planeCount == capacity )
							{
								return planeCount;
							}
						}
					}
				}
			}
			else
			{
				// Recurse
				B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
				stack[count++] = b3GetRightChild( node );
				node = b3GetLeftChild( node );

				continue;
			}
		}

		if ( count == 0 )
		{
			break;
		}
		node = stack[--count];
	}

	return planeCount;
}

void b3QueryMesh( const b3Mesh* mesh, b3AABB bounds, b3MeshQueryFcn* fcn, void* context )
{
	b3Vec3 meshScale = mesh->scale;
	bool clockwise = meshScale.x * meshScale.y * meshScale.z > 0.0f;

	// Scale may have reflection so min/max may become invalid when unscaled
	b3V32 scale = b3LoadV( &meshScale.x );
	b3V32 invScale = b3DivV( b3_oneV, scale );
	b3V32 temp1 = b3MulV( invScale, b3LoadV( &bounds.lowerBound.x ) );
	b3V32 temp2 = b3MulV( invScale, b3LoadV( &bounds.upperBound.x ) );
	b3V32 invScaledBoundsMin = b3MinV( temp1, temp2 );
	b3V32 invScaledBoundsMax = b3MaxV( temp1, temp2 );
	b3V32 invScaledBoundsCenter = b3MulV( b3_halfV, b3AddV( invScaledBoundsMin, invScaledBoundsMax ) );
	b3V32 invScaledBoundsExtent = b3SubV( invScaledBoundsMax, invScaledBoundsCenter );

	const b3MeshData* data = mesh->data;

	int count = 0;
	const b3MeshNode* stack[B3_MESH_STACK_SIZE];
	const b3MeshNode* node = b3GetRoot( data );
	const b3MeshTriangle* triangles = b3GetMeshTriangles( data );
	const b3Vec3* vertices = b3GetMeshVertices( data );

	while ( true )
	{
		// Test node overlap in unscaled space
		b3V32 nodeMin = b3LoadV( &node->lowerBound.x );
		b3V32 nodeMax = b3LoadV( &node->upperBound.x );

		if ( b3TestBoundsOverlap( nodeMin, nodeMax, invScaledBoundsMin, invScaledBoundsMax ) )
		{
			if ( b3IsLeaf( node ) )
			{
				int triangleCount = node->data.asLeaf.triangleCount;
				int triangleOffset = node->triangleOffset;

				for ( int index = 0; index < triangleCount; ++index )
				{
					int triangleIndex = triangleOffset + index;
					b3MeshTriangle triangle = triangles[triangleIndex];

					b3Vec3 vertex1 = vertices[triangle.index1];
					b3Vec3 vertex2 = vertices[triangle.index2];
					b3Vec3 vertex3 = vertices[triangle.index3];
					b3V32 v1 = b3LoadV( &vertex1.x );
					b3V32 v2 = b3LoadV( &vertex2.x );
					b3V32 v3 = b3LoadV( &vertex3.x );

					// Perform triangle overlap test in unscaled space. Winding order doesn't matter.
					// todo it is possible that some margins are getting scaled
					if ( b3TestBoundsTriangleOverlap( invScaledBoundsCenter, invScaledBoundsExtent, v1, v2, v3 ) )
					{
						b3Vec3 a = b3Mul( meshScale, vertex1 );
						b3Vec3 b, c;
						if ( clockwise )
						{
							b = b3Mul( meshScale, vertex2 );
							c = b3Mul( meshScale, vertex3 );
						}
						else
						{
							b = b3Mul( meshScale, vertex3 );
							c = b3Mul( meshScale, vertex2 );
						}

						bool result = fcn( a, b, c, triangleIndex, context );
						if ( result == false )
						{
							return;
						}
					}
				}
			}
			else
			{
				// Recurse
				B3_ASSERT( count <= B3_MESH_STACK_SIZE - 1 );
				stack[count++] = b3GetRightChild( node );
				node = b3GetLeftChild( node );

				continue;
			}
		}

		if ( count == 0 )
		{
			break;
		}
		node = stack[--count];
	}
}
