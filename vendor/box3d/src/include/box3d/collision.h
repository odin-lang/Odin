// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "base.h"
#include "math_functions.h"
#include "types.h"

#include <stdbool.h>
#include <stddef.h>

/**
 * @addtogroup tree
 * @{
 */

/// Constructing the tree initializes the node pool.
B3_API b3DynamicTree b3DynamicTree_Create( int proxyCapacity );

/// Destroy the tree, freeing the node pool.
B3_API void b3DynamicTree_Destroy( b3DynamicTree* tree );

/// Create a proxy. Provide an AABB and a userData value.
B3_API int b3DynamicTree_CreateProxy( b3DynamicTree* tree, b3AABB aabb, uint64_t categoryBits, uint64_t userData );

/// Destroy a proxy. This asserts if the id is invalid.
B3_API void b3DynamicTree_DestroyProxy( b3DynamicTree* tree, int proxyId );

/// Move a proxy to a new AABB by removing and reinserting into the tree.
B3_API void b3DynamicTree_MoveProxy( b3DynamicTree* tree, int proxyId, b3AABB aabb );

/// Enlarge a proxy and enlarge ancestors as necessary.
B3_API void b3DynamicTree_EnlargeProxy( b3DynamicTree* tree, int proxyId, b3AABB aabb );

/// Modify the category bits on a proxy. This is an expensive operation.
B3_API void b3DynamicTree_SetCategoryBits( b3DynamicTree* tree, int proxyId, uint64_t categoryBits );

/// Get the category bits on a proxy.
B3_API uint64_t b3DynamicTree_GetCategoryBits( b3DynamicTree* tree, int proxyId );

/// Query an AABB for overlapping proxies. The callback function is called for each proxy that overlaps the supplied AABB.
///	@return performance data
B3_API b3TreeStats b3DynamicTree_Query( const b3DynamicTree* tree, b3AABB aabb, uint64_t maskBits, bool requireAllBits,
										b3TreeQueryCallbackFcn* callback, void* context );

/// Query an AABB for the closest object. The callback function is called for each proxy that might be closest to the supplied point.
/// @param tree the dynamic tree to query
/// @param point the query point
/// @param maskBits nodes are skipped if the bit-wise AND with the node category bits is zero
/// @param requireAllBits nodes are skipped if the bit-wise AND with the node category bits does not equal the maskBits
/// @param callback a user provided instance of b3TreeQueryClosestCallbackFcn
/// @param context a user context object that is provided to the callback
/// @param minDistanceSqr the initial and final minimum squared distance. Provide a small initial to restrict the search and
/// improve performance. If the value is large this query has performance that scales linearly with the number of proxies and
/// would be slower than a brute force search.
///	@return performance data
B3_API b3TreeStats b3DynamicTree_QueryClosest( const b3DynamicTree* tree, b3Vec3 point, uint64_t maskBits, bool requireAllBits,
											   b3TreeQueryClosestCallbackFcn* callback, void* context, float* minDistanceSqr );

/// Ray cast against the proxies in the tree. This relies on the callback
/// to perform an exact ray cast in the case where the proxy contains a shape.
/// The callback also performs any collision filtering. This has performance
/// roughly equal to k * log(n), where k is the number of collisions and n is the
/// number of proxies in the tree.
/// Bit-wise filtering using mask bits can greatly improve performance in some scenarios.
///	However, this filtering may be approximate, so the user should still apply filtering to results.
/// @param tree the dynamic tree to ray cast
/// @param input the ray cast input data. The ray extends from p1 to p1 + maxFraction * (p2 - p1)
/// @param maskBits bit mask test: `bool accept = (maskBits & node->categoryBits) != 0;`
/// @param requireAllBits modifies bit mask test: `bool accept = (maskBits & node->categoryBits) == maskBits;`
/// @param callback a callback function that is called for each proxy that is hit by the ray
/// @param context user context that is passed to the callback
///	@return performance data
B3_API b3TreeStats b3DynamicTree_RayCast( const b3DynamicTree* tree, const b3RayCastInput* input, uint64_t maskBits,
										  bool requireAllBits, b3TreeRayCastCallbackFcn* callback, void* context );

/// Sweep an AABB through the tree. The box is in the tree's world float frame and the callback
/// re-differences each shape at full precision against the query origin. Used by the large world
/// spatial queries so the tree traversal stays float while the narrow phase stays precise.
B3_API b3TreeStats b3DynamicTree_BoxCast( const b3DynamicTree* tree, const b3BoxCastInput* input, uint64_t maskBits,
										  bool requireAllBits, b3TreeBoxCastCallbackFcn* callback, void* context );

/// Get the height of the binary tree.
B3_API int b3DynamicTree_GetHeight( const b3DynamicTree* tree );

/// Get the ratio of the sum of the node areas to the root area.
B3_API float b3DynamicTree_GetAreaRatio( const b3DynamicTree* tree );

/// Get the bounding box that contains the entire tree
B3_API b3AABB b3DynamicTree_GetRootBounds( const b3DynamicTree* tree );

/// Get the number of proxies created
B3_API int b3DynamicTree_GetProxyCount( const b3DynamicTree* tree );

/// Rebuild the tree while retaining subtrees that haven't changed. Returns the number of boxes sorted.
B3_API int b3DynamicTree_Rebuild( b3DynamicTree* tree, bool fullBuild );

/// Get the number of bytes used by this tree
B3_API int b3DynamicTree_GetByteCount( const b3DynamicTree* tree );

/// Validate this tree. For testing.
B3_API void b3DynamicTree_Validate( const b3DynamicTree* tree );

/// Validate this tree has no enlarged AABBs. For testing.
B3_API void b3DynamicTree_ValidateNoEnlarged( const b3DynamicTree* tree );

/// Save this tree to a file for debugging
B3_API void b3DynamicTree_Save( const b3DynamicTree* tree, const char* fileName );

/// Load a file for debugging
B3_API b3DynamicTree b3DynamicTree_Load( const char* fileName, float scale );

/// Get proxy user data
B3_INLINE uint64_t b3DynamicTree_GetUserData( const b3DynamicTree* tree, int proxyId )
{
	return tree->nodes[proxyId].userData;
}

/// Get the AABB of a proxy
B3_INLINE b3AABB b3DynamicTree_GetAABB( const b3DynamicTree* tree, int proxyId )
{
	return tree->nodes[proxyId].aabb;
}

/**@}*/ // tree

/**
 * @addtogroup hull
 * @{
 */

/// Get read only hull vertices.
B3_INLINE const b3HullVertex* b3GetHullVertices( const b3HullData* hull )
{
	if ( hull->vertexOffset == 0 )
	{
		return NULL;
	}

	return (const b3HullVertex*)( (intptr_t)hull + hull->vertexOffset );
}

/// Get read only hull points.
B3_INLINE const b3Vec3* b3GetHullPoints( const b3HullData* hull )
{
	if ( hull->pointOffset == 0 )
	{
		return NULL;
	}

	return (const b3Vec3*)( (intptr_t)hull + hull->pointOffset );
}

/// Get read only hull half edges.
B3_INLINE const b3HullHalfEdge* b3GetHullEdges( const b3HullData* hull )
{
	if ( hull->edgeOffset == 0 )
	{
		return NULL;
	}

	return (const b3HullHalfEdge*)( (intptr_t)hull + hull->edgeOffset );
}

/// Get read only hull faces.
B3_INLINE const b3HullFace* b3GetHullFaces( const b3HullData* hull )
{
	if ( hull->faceOffset == 0 )
	{
		return NULL;
	}

	return (const b3HullFace*)( (intptr_t)hull + hull->faceOffset );
}

/// Get read only hull planes.
B3_INLINE const b3Plane* b3GetHullPlanes( const b3HullData* hull )
{
	if ( hull->planeOffset == 0 )
	{
		return NULL;
	}

	return (const b3Plane*)( (intptr_t)hull + hull->planeOffset );
}

/// Create a tessellated cylinder as a hull.
B3_API b3HullData* b3CreateCylinder( float height, float radius, float yOffset, int sides );

/// Create a tessellated cone as a hull.
B3_API b3HullData* b3CreateCone( float height, float radius1, float radius2, int slices );

/// Create a rock shaped hull.
B3_API b3HullData* b3CreateRock( float radius );

/// Create a generic convex hull.
B3_API b3HullData* b3CreateHull( const b3Vec3* points, int pointCount, int maxVertexCount );

/// Deep clone a hull.
B3_API b3HullData* b3CloneHull( const b3HullData* hull );

/// Clone and transform a hull. Supports non-uniform and mirroring scale.
B3_API b3HullData* b3CloneAndTransformHull( const b3HullData* original, b3Transform transform, b3Vec3 scale );

/// Destroy a hull.
B3_API void b3DestroyHull( b3HullData* hull );

/// Make a cube as a hull. Do not call b3DestroyHull on this.
B3_API b3BoxHull b3MakeCubeHull( float halfWidth );

/// Make a box as a hull. Do not call b3DestroyHull on this.
B3_API b3BoxHull b3MakeBoxHull( float hx, float hy, float hz );

/// Make an offset box as a hull. Do not call b3DestroyHull on this.
B3_API b3BoxHull b3MakeOffsetBoxHull( float hx, float hy, float hz, b3Vec3 offset );

/// Make a transformed box as a hull. Do not call b3DestroyHull on this.
/// @param hx, hy, hz positive half widths
/// @param transform local transform of box
B3_API b3BoxHull b3MakeTransformedBoxHull( float hx, float hy, float hz, b3Transform transform );

/// This makes a transformed box hull with post scaling. This is useful for boxes that are scaled in
/// a level editor. Such scaling can have reflection and shear. In the case of shear the result
/// may be approximate. If you need to support shear consider using b3CreateHull.
/// Do not call b3DestroyHull on this.
/// @param halfWidths positive half widths
/// @param transform local transform of box
/// @param postScale scale applied after the transform, may be negative
B3_API b3BoxHull b3MakeScaledBoxHull( b3Vec3 halfWidths, b3Transform transform, b3Vec3 postScale );

/// This takes a box with a transform and post scale and converts it into a box with the post scale
/// resolved with new half-widths and transform. This accepts non-uniform and negative scale.
/// This is approximate if there is shear.
/// @param halfWidths [in/out] the box half widths
/// @param transform [in/out] the box transform with rotation and translation
/// @param postScale the post scale being applied to the box after the transform
/// @param minHalfWidth the minimum half width after scale is applied
B3_API void b3ScaleBox( b3Vec3* halfWidths, b3Transform* transform, b3Vec3 postScale, float minHalfWidth );

/**@}*/ // hull

/**
 * @addtogroup mesh
 * @{
 */

/// Get read only mesh BVH nodes.
B3_INLINE const b3MeshNode* b3GetMeshNodes( const b3MeshData* mesh )
{
	if ( mesh->nodeOffset == 0 )
	{
		return NULL;
	}

	return (const b3MeshNode*)( (intptr_t)mesh + mesh->nodeOffset );
}

/// Get read only mesh vertices.
B3_INLINE const b3Vec3* b3GetMeshVertices( const b3MeshData* mesh )
{
	if ( mesh->vertexOffset == 0 )
	{
		return NULL;
	}

	return (const b3Vec3*)( (intptr_t)mesh + mesh->vertexOffset );
}

/// Get read only mesh triangles.
B3_INLINE const b3MeshTriangle* b3GetMeshTriangles( const b3MeshData* mesh )
{
	if ( mesh->triangleOffset == 0 )
	{
		return NULL;
	}

	return (const b3MeshTriangle*)( (intptr_t)mesh + mesh->triangleOffset );
}

/// Get read only mesh materials. The count is equal to the triangle count.
B3_INLINE const uint8_t* b3GetMeshMaterialIndices( const b3MeshData* mesh )
{
	if ( mesh->materialOffset == 0 )
	{
		return NULL;
	}

	return (const uint8_t*)( (intptr_t)mesh + mesh->materialOffset );
}

/// Get read only mesh flags. The count is equal to the triangle count.
B3_INLINE const uint8_t* b3GetMeshFlags( const b3MeshData* mesh )
{
	if ( mesh->flagsOffset == 0 )
	{
		return NULL;
	}

	return (const uint8_t*)( (intptr_t)mesh + mesh->flagsOffset );
}

/// Create a grid mesh along the x and z axes.
/// @param xCount the number of rows in the x direction
/// @param zCount the number of rows in the z direction
/// @param cellWidth the width of each cell
/// @param materialCount the number of materials to generate
/// @param identifyEdges compute adjacency information
B3_API b3MeshData* b3CreateGridMesh( int xCount, int zCount, float cellWidth, int materialCount, bool identifyEdges );

/// Create a wave mesh along the x and z axes.
B3_API b3MeshData* b3CreateWaveMesh( int xCount, int zCount, float cellWidth, float amplitude, float rowFrequency,
									 float columnFrequency );

/// Create a torus mesh.
B3_API b3MeshData* b3CreateTorusMesh( int radialResolution, int tubularResolution, float radius, float thickness );

/// Create a box mesh.
B3_API b3MeshData* b3CreateBoxMesh( b3Vec3 center, b3Vec3 extent, bool identifyEdges );

/// Create a hollow box mesh.
B3_API b3MeshData* b3CreateHollowBoxMesh( b3Vec3 center, b3Vec3 extent );

/// Create a platform mesh. A truncated pyramid.
B3_API b3MeshData* b3CreatePlatformMesh( b3Vec3 center, float height, float topWidth, float bottomWidth );

/// Create a generic mesh.
B3_API b3MeshData* b3CreateMesh( const b3MeshDef* def, int* degenerateTriangleIndices, int degenerateCapacity );

/// Destroy a mesh.
B3_API void b3DestroyMesh( b3MeshData* mesh );

/// Get the height of the mesh BVH.
B3_API int b3GetHeight( const b3MeshData* mesh );

/**@}*/ // mesh

/**
 * @addtogroup height_field
 * @{
 */

/// Get read only compressed heights. One uint16_t per grid point.
B3_INLINE const uint16_t* b3GetHeightFieldCompressedHeights( const b3HeightFieldData* hf )
{
	if ( hf->heightsOffset == 0 )
	{
		return NULL;
	}

	return (const uint16_t*)( (intptr_t)hf + hf->heightsOffset );
}

/// Get read only material indices. One uint8_t per cell.
B3_INLINE const uint8_t* b3GetHeightFieldMaterialIndices( const b3HeightFieldData* hf )
{
	if ( hf->materialOffset == 0 )
	{
		return NULL;
	}

	return (const uint8_t*)( (intptr_t)hf + hf->materialOffset );
}

/// Get read only triangle flags. One uint8_t per triangle.
B3_INLINE const uint8_t* b3GetHeightFieldFlags( const b3HeightFieldData* hf )
{
	if ( hf->flagsOffset == 0 )
	{
		return NULL;
	}

	return (const uint8_t*)( (intptr_t)hf + hf->flagsOffset );
}

/// Create a generic height field.
B3_API b3HeightFieldData* b3CreateHeightField( const b3HeightFieldDef* data );

/// Create a grid as a height field.
B3_API b3HeightFieldData* b3CreateGrid( int rowCount, int columnCount, b3Vec3 scale, bool makeHoles );

/// Create a wave grid as a height field.
B3_API b3HeightFieldData* b3CreateWave( int rowCount, int columnCount, b3Vec3 scale, float rowFrequency, float columnFrequency,
										bool makeHoles );

/// Destroy a height field.
B3_API void b3DestroyHeightField( b3HeightFieldData* heightField );

/// Save input height data to a file
B3_API void b3DumpHeightData( const b3HeightFieldDef* data, const char* fileName );

/// Create a height field by loading a previously saved height data
B3_API b3HeightFieldData* b3LoadHeightField( const char* fileName );

/**@}*/ // height_field

/**
 * @addtogroup compound
 * @{
 */

/// Get a child shape of a compound.
B3_API b3ChildShape b3GetCompoundChild( const b3CompoundData* compound, int childIndex );

/// Query a compound shape for children that overlap an AABB.
B3_API void b3QueryCompound( const b3CompoundData* compound, b3AABB aabb, b3CompoundQueryFcn* fcn, void* context );

/// Access a child capsule by index.
B3_API b3CompoundCapsule b3GetCompoundCapsule( const b3CompoundData* compound, int index );

/// Access a child hull by index.
B3_API b3CompoundHull b3GetCompoundHull( const b3CompoundData* compound, int index );

/// Access a child mesh by index.
B3_API b3CompoundMesh b3GetCompoundMesh( const b3CompoundData* compound, int index );

/// Access a child sphere by index.
B3_API b3CompoundSphere b3GetCompoundSphere( const b3CompoundData* compound, int index );

/// Access the compound material array.
B3_API const b3SurfaceMaterial* b3GetCompoundMaterials( const b3CompoundData* compound );

/// Create a compound shape. All input data in the definition is cloned into the resulting compound.
B3_API b3CompoundData* b3CreateCompound( const b3CompoundDef* def );

/// Destroy a compound shape.
B3_API void b3DestroyCompound( b3CompoundData* compound );

/// If bytes is null then this returns the number of required bytes. This clones all the
/// data into the bytes buffer. This is expected to run offline or asynchronously.
/// This mutates the compound to nullify pointers, leaving the compound in an unusable state.
B3_API uint8_t* b3ConvertCompoundToBytes( b3CompoundData* compound );

/// Convert bytes to compound. This does not clone. The bytes must remain in scope while the
/// compound is used. This is done to improve run-time performance and allow for instancing.
/// The bytes are mutated to fixup pointers.
B3_API b3CompoundData* b3ConvertBytesToCompound( uint8_t* bytes, int byteCount );

/**@}*/ // compound

/**
 * @addtogroup geometry
 * @{
 */

/// Compute mass properties of a sphere
B3_API b3MassData b3ComputeSphereMass( const b3Sphere* shape, float density );

/// Compute mass properties of a capsule
B3_API b3MassData b3ComputeCapsuleMass( const b3Capsule* shape, float density );

/// Compute mass properties of a hull
B3_API b3MassData b3ComputeHullMass( const b3HullData* shape, float density );

/// Compute the bounding box of a transformed sphere
B3_API b3AABB b3ComputeSphereAABB( const b3Sphere* shape, b3Transform transform );

/// Compute the bounding box of a transformed capsule
B3_API b3AABB b3ComputeCapsuleAABB( const b3Capsule* shape, b3Transform transform );

/// Compute the bounding box of a transformed hull
B3_API b3AABB b3ComputeHullAABB( const b3HullData* shape, b3Transform transform );

/// Compute the bounding box of a transformed mesh. Scale may be non-uniform and have negative components.
B3_API b3AABB b3ComputeMeshAABB( const b3MeshData* shape, b3Transform transform, b3Vec3 scale );

/// Compute the bounding box of a transformed height-field
B3_API b3AABB b3ComputeHeightFieldAABB( const b3HeightFieldData* shape, b3Transform transform );

/// Compute the bounding box of a compound
B3_API b3AABB b3ComputeCompoundAABB( const b3CompoundData* shape, b3Transform transform );

/**@}*/ // geometry

/**
 * @addtogroup query
 * @{
 */

/// Use this to ensure your ray cast input is valid and avoid internal assertions.
B3_API bool b3IsValidRay( const b3RayCastInput* input );

/// Overlap shape versus capsule
B3_API bool b3OverlapCapsule( const b3Capsule* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Overlap shape versus compound
B3_API bool b3OverlapCompound( const b3CompoundData* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Overlap shape versus height field
B3_API bool b3OverlapHeightField( const b3HeightFieldData* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Overlap shape versus hull
B3_API bool b3OverlapHull( const b3HullData* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Overlap shape versus mesh
B3_API bool b3OverlapMesh( const b3Mesh* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Overlap shape versus sphere
B3_API bool b3OverlapSphere( const b3Sphere* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy );

/// Ray cast versus sphere in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
B3_API b3CastOutput b3RayCastSphere( const b3Sphere* shape, const b3RayCastInput* input );

/// Ray cast versus a hollow sphere shell in local space. Unlike the solid sphere a ray starting
/// inside is not an overlap: it passes through and hits the far wall.
B3_API b3CastOutput b3RayCastHollowSphere( const b3Sphere* shape, const b3RayCastInput* input );

/// Ray cast versus capsule in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
B3_API b3CastOutput b3RayCastCapsule( const b3Capsule* shape, const b3RayCastInput* input );

/// Ray cast versus compound in local space. A zero length ray is a point query. Initial overlap
/// with a child reports a hit at the ray origin with zero fraction and zero normal.
B3_API b3CastOutput b3RayCastCompound( const b3CompoundData* shape, const b3RayCastInput* input );

/// Ray cast versus hull shape in local space. A zero length ray is a point query. Initial overlap
/// reports a hit at the ray origin with zero fraction and zero normal.
B3_API b3CastOutput b3RayCastHull( const b3HullData* shape, const b3RayCastInput* input );

/// Ray cast versus mesh in local space. A thin surface with no interior, so there is no overlap case.
B3_API b3CastOutput b3RayCastMesh( const b3Mesh* shape, const b3RayCastInput* input );

/// Ray cast versus height field in local space. A thin surface with no interior, so there is no overlap case.
B3_API b3CastOutput b3RayCastHeightField( const b3HeightFieldData* shape, const b3RayCastInput* input );

/// Shape cast versus a sphere. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastSphere( const b3Sphere* shape, const b3ShapeCastInput* input );

/// Shape cast versus a capsule. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastCapsule( const b3Capsule* shape, const b3ShapeCastInput* input );

/// Shape cast versus compound. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastCompound( const b3CompoundData* shape, const b3ShapeCastInput* input );

/// Shape cast versus a hull. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastHull( const b3HullData* shape, const b3ShapeCastInput* input );

/// Shape cast versus a mesh. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastMesh( const b3Mesh* shape, const b3ShapeCastInput* input );

/// Shape cast versus a height field. Initial overlap is treated as a miss.
B3_API b3CastOutput b3ShapeCastHeightField( const b3HeightFieldData* shape, const b3ShapeCastInput* input );

/// Query callback.
typedef bool b3MeshQueryFcn( b3Vec3 a, b3Vec3 b, b3Vec3 c, int triangleIndex, void* context );

/// Query a mesh for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
/// @param mesh the mesh to query, includes scale
/// @param bounds the bounding box in local space
/// @param fcn a user function to collect triangles
/// @param context the context sent to the user function.
B3_API void b3QueryMesh( const b3Mesh* mesh, const b3AABB bounds, b3MeshQueryFcn* fcn, void* context );

/// Query a height field for triangles overlapping a bounding box in local space. May have false positives. Useful for debug draw.
/// @param heightField the height field to query
/// @param bounds the bounding box in local space
/// @param fcn a user function to collect triangles
/// @param context the context sent to the user function.
B3_API void b3QueryHeightField( const b3HeightFieldData* heightField, b3AABB bounds, b3MeshQueryFcn* fcn, void* context );

/// Compute the closest points between two shapes represented as point clouds.
/// b3SimplexCache cache is input/output. On the first call set b3SimplexCache.count to zero.
/// The query runs in frame A, so the witness points and normal are returned in frame A.
/// The underlying GJK algorithm may be debugged by passing in debug simplexes and capacity. You may pass in NULL and 0 for these.
B3_API b3DistanceOutput b3ShapeDistance( const b3DistanceInput* input, b3SimplexCache* cache, b3Simplex* simplexes,
										 int simplexCapacity );

/// Perform a linear shape cast of shape B moving and shape A fixed. Determines the hit point, normal, and translation fraction.
/// The query runs in frame A, so the hit point and normal are returned in frame A. Initially touching shapes are a miss.
B3_API b3CastOutput b3ShapeCast( const b3ShapeCastPairInput* input );

/// Evaluate the transform sweep at a specific time.
B3_API b3Transform b3GetSweepTransform( const b3Sweep* sweep, float time );

/// Compute the upper bound on time before two shapes penetrate. Time is represented as
/// a fraction between [0,tMax]. This uses a swept separating axis and may miss some intermediate,
/// non-tunneling collisions. If you change the time interval, you should call this function
/// again.
B3_API b3TOIOutput b3TimeOfImpact( const b3TOIInput* input );

/**@}*/ // query

/**
 * @addtogroup collision
 * @{
 */

/// Collide two spheres.
B3_API void b3CollideSpheres( b3LocalManifold* manifold, int capacity, const b3Sphere* sphereA, const b3Sphere* sphereB,
							  b3Transform transformBtoA );

/// Collide a capsule and a sphere.
B3_API void b3CollideCapsuleAndSphere( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA,
									   const b3Sphere* sphereB, b3Transform transformBtoA );

/// Collide a hull and a sphere.
B3_API void b3CollideHullAndSphere( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3Sphere* sphereB,
									b3Transform transformBtoA, b3SimplexCache* cache );

/// Collide two capsules.
B3_API void b3CollideCapsules( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA, const b3Capsule* capsuleB,
							   b3Transform transformBtoA );

/// Collide a hull and a capsule.
B3_API void b3CollideHullAndCapsule( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3Capsule* capsuleB,
									 b3Transform transformBtoA, b3SimplexCache* cache );

/// Collide two hulls.
B3_API void b3CollideHulls( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, const b3HullData* hullB,
							b3Transform transformBtoA, b3SATCache* cache );

/// Collide a capsule and a triangle.
B3_API void b3CollideCapsuleAndTriangle( b3LocalManifold* manifold, int capacity, const b3Capsule* capsuleA,
										 const b3Vec3* triangleB, b3SimplexCache* cache );

/// Collide a hull and a triangle.
B3_API void b3CollideHullAndTriangle( b3LocalManifold* manifold, int capacity, const b3HullData* hullA, b3Vec3 v1, b3Vec3 v2,
									  b3Vec3 v3, int triangleFlags, b3SATCache* cache, bool enableSpeculative );

/// Collide a sphere and a triangle.
B3_API void b3CollideSphereAndTriangle( b3LocalManifold* manifold, int capacity, const b3Sphere* sphereA,
										const b3Vec3* triangleB );

/**@}*/ // collision

/**
 * @addtogroup character
 * @{
 */

/// Solves the position of a mover that satisfies the given collision planes.
/// @param targetDelta the desired translation from the position used to generate the collision planes
/// @param planes the collision planes
/// @param count the number of collision planes
B3_API b3PlaneSolverResult b3SolvePlanes( b3Vec3 targetDelta, b3CollisionPlane* planes, int count );

/// Clips the velocity against the given collision planes. Planes with zero push or clipVelocity
/// set to false are skipped.
B3_API b3Vec3 b3ClipVector( b3Vec3 vector, const b3CollisionPlane* planes, int count );

/**@}*/ // character
