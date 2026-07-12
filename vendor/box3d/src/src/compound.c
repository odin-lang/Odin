// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "compound.h"

#include "hull_map.h"
#include "math_internal.h"
#include "shape.h"

#include "box3d/base.h"
#include "box3d/collision.h"
#include "box3d/constants.h"
#include "box3d/types.h"

#include <stdint.h>
#include <string.h>

typedef struct b3SharedHull
{
	const b3HullData* hull;
	int hullOffset;
} b3SharedHull;

typedef struct b3SharedMesh
{
	const b3MeshData* meshData;
	int meshOffset;
} b3SharedMesh;

typedef struct b3HullInstance
{
	b3Transform transform;
	uint32_t hullOffset;
	uint32_t materialIndex;
} b3HullInstance;

typedef struct b3MeshInstance
{
	b3Transform transform;
	b3Vec3 scale;
	uint32_t meshOffset;
	uint32_t materialIndices[B3_MAX_COMPOUND_MESH_MATERIALS];
} b3MeshInstance;

static inline b3TreeNode* b3GetCompoundNodes( b3CompoundData* compound )
{
	if ( compound->nodeOffset == 0 )
	{
		return NULL;
	}

	return (b3TreeNode*)( (intptr_t)compound + compound->nodeOffset );
}

const b3SurfaceMaterial* b3GetCompoundMaterials( const b3CompoundData* compound )
{
	if ( compound->materialOffset == 0 )
	{
		return NULL;
	}

	return (b3SurfaceMaterial*)( (intptr_t)compound + compound->materialOffset );
}

b3CompoundCapsule b3GetCompoundCapsule( const b3CompoundData* compound, int index )
{
	B3_ASSERT( 0 <= index && index < compound->capsuleCount && compound->capsuleOffset > 0 );

	b3CompoundCapsule result = { 0 };
	if ( compound->capsuleOffset == 0 )
	{
		return result;
	}

	const b3CompoundCapsule* capsules = (const b3CompoundCapsule*)( (intptr_t)compound + compound->capsuleOffset );
	return capsules[index];
}

b3CompoundHull b3GetCompoundHull( const b3CompoundData* compound, int index )
{
	B3_ASSERT( 0 <= index && index < compound->hullCount && compound->hullOffset > 0 );

	b3CompoundHull result = { 0 };
	if ( compound->hullOffset == 0 )
	{
		return result;
	}

	const b3HullInstance* hullInstances = (const b3HullInstance*)( (intptr_t)compound + compound->hullOffset );
	uint32_t hullOffset = hullInstances[index].hullOffset;
	B3_ASSERT( hullOffset >= compound->hullOffset + compound->hullCount * sizeof( b3HullInstance ) );
	result.hull = (const b3HullData*)( (intptr_t)compound + hullOffset );
	result.transform = hullInstances[index].transform;
	result.materialIndex = hullInstances[index].materialIndex;
	return result;
}

b3CompoundMesh b3GetCompoundMesh( const b3CompoundData* compound, int index )
{
	B3_ASSERT( 0 <= index && index < compound->meshCount && compound->meshOffset > 0 );

	b3CompoundMesh result = { 0 };
	if ( compound->meshOffset == 0 )
	{
		return result;
	}

	const b3MeshInstance* meshInstances = (const b3MeshInstance*)( (intptr_t)compound + compound->meshOffset );
	uint32_t meshOffset = meshInstances[index].meshOffset;
	B3_ASSERT( meshOffset >= compound->meshOffset + compound->meshCount * sizeof( b3HullInstance ) );
	result.meshData = (const b3MeshData*)( (intptr_t)compound + meshOffset );
	result.transform = meshInstances[index].transform;
	result.scale = meshInstances[index].scale;
	for ( int i = 0; i < B3_MAX_COMPOUND_MESH_MATERIALS; ++i )
	{
		result.materialIndices[i] = meshInstances[index].materialIndices[i];
	}
	return result;
}

b3CompoundSphere b3GetCompoundSphere( const b3CompoundData* compound, int index )
{
	B3_ASSERT( 0 <= index && index < compound->sphereCount && compound->sphereOffset > 0 );

	b3CompoundSphere result = { 0 };
	if ( compound->sphereOffset == 0 )
	{
		return result;
	}

	const b3CompoundSphere* spheres = (const b3CompoundSphere*)( (intptr_t)compound + compound->sphereOffset );
	return spheres[index];
}

b3ChildShape b3GetCompoundChild( const b3CompoundData* compound, int childIndex )
{
	// Capsule?
	if ( 0 <= childIndex && childIndex < compound->capsuleCount )
	{
		b3CompoundCapsule compoundCapsule = b3GetCompoundCapsule( compound, childIndex );
		return (b3ChildShape){
			.capsule = compoundCapsule.capsule,
			.transform = b3Transform_identity,
			.materialIndices = { compoundCapsule.materialIndex },
			.type = b3_capsuleShape,
		};
	}
	childIndex -= compound->capsuleCount;

	// Hull?
	if ( 0 <= childIndex && childIndex < compound->hullCount )
	{
		b3CompoundHull compoundHull = b3GetCompoundHull( compound, childIndex );
		return (b3ChildShape){
			.hull = compoundHull.hull,
			.transform = compoundHull.transform,
			.materialIndices = { compoundHull.materialIndex },
			.type = b3_hullShape,
		};
	}
	childIndex -= compound->hullCount;

	// Mesh?
	if ( 0 <= childIndex && childIndex < compound->meshCount )
	{
		b3CompoundMesh compoundMesh = b3GetCompoundMesh( compound, childIndex );
		const int* m = compoundMesh.materialIndices;
		_Static_assert( B3_MAX_COMPOUND_MESH_MATERIALS == 4, "too many materials in compound mesh" );

		return (b3ChildShape){
			.mesh =
				{
					.data = compoundMesh.meshData,
					.scale = compoundMesh.scale,
				},
			.transform = compoundMesh.transform,
			.materialIndices = { m[0], m[1], m[2], m[3] },
			.type = b3_meshShape,
		};
	}
	childIndex -= compound->meshCount;

	B3_ASSERT( 0 <= childIndex && childIndex < compound->sphereCount );

	// Sphere?
	{
		b3CompoundSphere compoundSphere = b3GetCompoundSphere( compound, childIndex );
		return (b3ChildShape){
			.sphere = compoundSphere.sphere,
			.transform = b3Transform_identity,
			.materialIndices = { compoundSphere.materialIndex },
			.type = b3_sphereShape,
		};
	}
}

static inline size_t vt_wyhash( const void* key, size_t len );

static inline uint64_t b3HashMesh( const b3MeshData* mesh )
{
	return vt_wyhash( mesh, mesh->byteCount );
}

static bool b3CompareMeshes( const b3MeshData* mesh1, const b3MeshData* mesh2 )
{
	if ( mesh1 == mesh2 )
	{
		return true;
	}

	if ( mesh1->byteCount != mesh2->byteCount )
	{
		return false;
	}

	int result = memcmp( mesh1, mesh2, mesh1->byteCount );
	return result == 0;
}

#define NAME b3MeshMap
#define KEY_TY const b3MeshData*
#define VAL_TY int
#define HASH_FN b3HashMesh
#define CMPR_FN b3CompareMeshes
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

static inline uint64_t b3HashMaterial( const b3SurfaceMaterial* material )
{
	return vt_wyhash( material, sizeof( b3SurfaceMaterial ) );
}

static bool b3CompareMaterials( const b3SurfaceMaterial* mat1, const b3SurfaceMaterial* mat2 )
{
	if ( mat1 == mat2 )
	{
		return true;
	}

	int result = memcmp( mat1, mat2, sizeof( b3SurfaceMaterial ) );
	return result == 0;
}

#define NAME b3MaterialMap
#define KEY_TY const b3SurfaceMaterial*
#define VAL_TY int
#define HASH_FN b3HashMaterial
#define CMPR_FN b3CompareMaterials
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

b3CompoundData* b3CreateCompound( const b3CompoundDef* def )
{
	int convexCount = def->capsuleCount + def->hullCount + def->sphereCount;
	int shapeCount = convexCount + def->meshCount;

	if ( shapeCount >= B3_MAX_CHILD_SHAPES )
	{
		B3_ASSERT( false );
		return NULL;
	}

	b3DynamicTree tree = b3DynamicTree_Create( shapeCount );

	int childIndex = 0;

	// Instances
	int capsuleCount = def->capsuleCount;
	b3CompoundCapsule* capsuleInstances = b3AllocZeroed( capsuleCount * sizeof( b3CompoundCapsule ) );
	int hullCount = def->hullCount;
	b3HullInstance* hullInstances = b3AllocZeroed( hullCount * sizeof( b3HullInstance ) );
	int meshCount = def->meshCount;
	b3MeshInstance* meshInstances = b3AllocZeroed( meshCount * sizeof( b3MeshInstance ) );
	int sphereCount = def->sphereCount;
	b3CompoundSphere* sphereInstances = b3AllocZeroed( sphereCount * sizeof( b3CompoundSphere ) );

	// Determine material capacity
	int materialCapacity = convexCount;
	for ( int i = 0; i < def->meshCount; ++i )
	{
		B3_ASSERT( def->meshes[i].materialCount > 0 );
		materialCapacity += def->meshes[i].materialCount;
	}

	// Material map for convex material sharing. Mesh materials are not shared for simplicity.
	b3MaterialMap materialMap;
	b3MaterialMap_init( &materialMap );
	b3MaterialMap_reserve( &materialMap, materialCapacity );
	b3SurfaceMaterial* materials = b3AllocZeroed( materialCapacity * sizeof( b3SurfaceMaterial ) );
	int materialCount = 0;

	for ( int i = 0; i < def->capsuleCount; ++i )
	{
		const b3CompoundCapsuleDef* capsuleDef = def->capsules + i;
		capsuleInstances[i].capsule = capsuleDef->capsule;

		// Look for an existing material
		b3MaterialMap_itr materialItr = b3MaterialMap_get_or_insert( &materialMap, &capsuleDef->material, materialCount );

		// Get the shared material index
		int materialIndex = materialItr.data->val;
		capsuleInstances[i].materialIndex = materialIndex;

		// Is this a new material?
		if ( materialIndex == materialCount )
		{
			materials[materialIndex] = capsuleDef->material;
			materialCount += 1;
		}

		b3AABB aabb = b3ComputeCapsuleAABB( &capsuleDef->capsule, b3Transform_identity );
		b3DynamicTree_CreateProxy( &tree, aabb, ~0ull, childIndex );
		childIndex += 1;
	}

	// Hulls
	b3SharedHull* sharedHulls = b3AllocZeroed( hullCount * sizeof( b3SharedHull ) );
	int sharedHullCount = 0;

	if ( hullCount > 0 )
	{
		b3HullMap hullMap;
		b3HullMap_init( &hullMap );
		b3HullMap_reserve( &hullMap, hullCount );

		for ( int i = 0; i < hullCount; ++i )
		{
			const b3CompoundHullDef* hullDef = def->hulls + i;
			const b3HullData* hull = hullDef->hull;
			b3AABB aabb = b3ComputeHullAABB( hull, hullDef->transform );
			b3DynamicTree_CreateProxy( &tree, aabb, ~0ull, childIndex );
			childIndex += 1;

			// Look for an existing material
			b3MaterialMap_itr materialItr = b3MaterialMap_get_or_insert( &materialMap, &hullDef->material, materialCount );

			// Get the shared material index
			int materialIndex = materialItr.data->val;
			hullInstances[i].materialIndex = materialIndex;

			// Is this a new material?
			if ( materialIndex == materialCount )
			{
				materials[materialIndex] = hullDef->material;
				materialCount += 1;
			}

			hullInstances[i].transform = hullDef->transform;

			// Look for an existing matching hull
			b3HullMap_itr itr = b3HullMap_get_or_insert( &hullMap, hull, sharedHullCount );

			// Get the unique index for this hull
			int sharedHullIndex = itr.data->val;

			// The offset isn't known yet, so store the index of the shared hull
			hullInstances[i].hullOffset = sharedHullIndex;

			// Is this a new hull?
			if ( sharedHullIndex == sharedHullCount )
			{
				// Create a shared hull. The offset is determined below.
				sharedHulls[sharedHullIndex].hull = hull;
				sharedHulls[sharedHullIndex].hullOffset = B3_NULL_INDEX;
				sharedHullCount += 1;
			}
		}

		b3HullMap_cleanup( &hullMap );
	}

	// Meshes
	b3SharedMesh* sharedMeshes = b3AllocZeroed( meshCount * sizeof( b3SharedMesh ) );
	int sharedMeshCount = 0;

	if ( meshCount > 0 )
	{
		b3MeshMap meshMap;
		b3MeshMap_init( &meshMap );
		b3MeshMap_reserve( &meshMap, meshCount );

		for ( int i = 0; i < meshCount; ++i )
		{
			const b3CompoundMeshDef* meshDef = def->meshes + i;

			const b3MeshData* meshData = meshDef->meshData;
			b3AABB aabb = b3ComputeMeshAABB( meshData, meshDef->transform, meshDef->scale );
			b3DynamicTree_CreateProxy( &tree, aabb, ~0ull, childIndex );
			childIndex += 1;

			// No effort to share mesh materials. It would be easier to do if the number of materials was limited.
			B3_ASSERT( meshData->materialCount == meshDef->materialCount );

			for ( int j = 0; j < meshDef->materialCount; ++j )
			{
				// Look for an existing material
				b3MaterialMap_itr materialItr =
					b3MaterialMap_get_or_insert( &materialMap, &meshDef->materials[j], materialCount );

				// Get the shared material index
				int materialIndex = materialItr.data->val;
				meshInstances[i].materialIndices[j] = materialIndex;

				// Is this a new material?
				if ( materialIndex == materialCount )
				{
					materials[materialIndex] = meshDef->materials[j];
					materialCount += 1;
				}
			}

			// Look for an existing matching mesh
			b3MeshMap_itr itr = b3MeshMap_get_or_insert( &meshMap, meshData, sharedMeshCount );

			// Get the shared mesh index
			int sharedMeshIndex = itr.data->val;

			// Create mesh instance
			meshInstances[i].transform = def->meshes[i].transform;
			meshInstances[i].scale = def->meshes[i].scale;

			// The offset isn't known yet, so store the index of the shared mesh
			meshInstances[i].meshOffset = sharedMeshIndex;

			// Is this a new mesh?
			if ( sharedMeshIndex == sharedMeshCount )
			{
				// Create a shared mesh. The offset is determined below.
				sharedMeshes[sharedMeshIndex].meshData = meshData;
				sharedMeshes[sharedMeshIndex].meshOffset = B3_NULL_INDEX;
				sharedMeshCount += 1;
			}
		}

		b3MeshMap_cleanup( &meshMap );
	}

	// Spheres
	for ( int i = 0; i < def->sphereCount; ++i )
	{
		const b3CompoundSphereDef* sphereDef = def->spheres + i;
		sphereInstances[i].sphere = sphereDef->sphere;

		// Look for an existing material
		b3MaterialMap_itr materialItr = b3MaterialMap_get_or_insert( &materialMap, &sphereDef->material, materialCount );

		// Get the shared material index
		int materialIndex = materialItr.data->val;
		sphereInstances[i].materialIndex = materialIndex;

		// Is this a new material?
		if ( materialIndex == materialCount )
		{
			materials[materialIndex] = sphereDef->material;
			materialCount += 1;
		}

		b3AABB aabb = b3ComputeSphereAABB( &sphereDef->sphere, b3Transform_identity );
		b3DynamicTree_CreateProxy( &tree, aabb, ~0ull, childIndex );
		childIndex += 1;
	}

	B3_ASSERT( materialCount <= materialCapacity );
	B3_ASSERT( tree.nodeCount > 0 );

	b3DynamicTree_Rebuild( &tree, true );

	int byteCount = sizeof( b3CompoundData );

	// Tree nodes - todo 64 byte alignment
	int nodeOffset = byteCount;
	byteCount += tree.nodeCapacity * sizeof( b3TreeNode );

	int materialOffset = byteCount;
	byteCount += materialCount * sizeof( b3SurfaceMaterial );

	int capsuleOffset = byteCount;
	byteCount += def->capsuleCount * sizeof( b3CompoundCapsule );

	// Hull data layout has another level of indirection to allow for tight data packing
	// 1. hull instance array : hull count array of b3HullInstance with individual hull transforms and offsets
	// 2. heterogeneous array of shared hull data : each shared hull can have a different byte count, so direct indexing is not
	// possible
	int hullArrayOffset = byteCount;

	// Array of hull instances
	byteCount += hullCount * sizeof( b3HullInstance );

	// Packed shared hull blobs
	for ( int i = 0; i < sharedHullCount; ++i )
	{
		sharedHulls[i].hullOffset = byteCount;
		byteCount += sharedHulls[i].hull->byteCount;
	}

	// Mesh data layout has another level of indirection to allow for tight data packing
	// 1. mesh instance array : mesh count array of b3MeshInstance with individual mesh transform, scale, and offset
	// 2. heterogeneous array of shared mesh data : each shared mesh can have a different byte count, so direct indexing is not
	// possible
	int meshArrayOffset = byteCount;

	// Array of mesh instances
	byteCount += meshCount * sizeof( b3MeshInstance );

	// Packed shared mesh blobs
	for ( int i = 0; i < sharedMeshCount; ++i )
	{
		sharedMeshes[i].meshOffset = byteCount;
		byteCount += sharedMeshes[i].meshData->byteCount;
	}

	int sphereOffset = byteCount;
	byteCount += def->sphereCount * sizeof( b3CompoundSphere );

	b3CompoundData* compound = b3Alloc( byteCount );
	memset( compound, 0, byteCount );

	compound->version = B3_COMPOUND_VERSION;
	compound->byteCount = byteCount;
	compound->nodeOffset = nodeOffset;
	memcpy( &compound->tree, &tree, sizeof( b3DynamicTree ) );

	// todo clean up this mess
	compound->tree.freeList = 0;
	compound->tree.leafIndices = NULL;
	compound->tree.leafBoxes = NULL;
	compound->tree.leafCenters = NULL;
	compound->tree.binIndices = NULL;
	compound->tree.rebuildCapacity = 0;

	compound->tree.nodes = NULL;
	compound->materialOffset = materialOffset;
	compound->materialCount = materialCount;
	compound->capsuleOffset = capsuleOffset;
	compound->capsuleCount = capsuleCount;
	compound->hullOffset = hullArrayOffset;
	compound->hullCount = hullCount;
	compound->meshOffset = meshArrayOffset;
	compound->meshCount = meshCount;
	compound->sphereOffset = sphereOffset;
	compound->sphereCount = sphereCount;

	// Tree nodes
	b3TreeNode* nodes = b3GetCompoundNodes( compound );
	memcpy( nodes, tree.nodes, tree.nodeCapacity * sizeof( b3TreeNode ) );
	compound->tree.nodes = nodes;

	// Materials
	B3_ASSERT( materialCount > 0 );
	b3SurfaceMaterial* destinationMaterials = (b3SurfaceMaterial*)( (intptr_t)compound + compound->materialOffset );
	if ( materials != NULL )
	{
		memcpy( destinationMaterials, materials, materialCount * sizeof( b3SurfaceMaterial ) );
	}

	// Capsules
	if ( def->capsuleCount > 0 )
	{
		B3_ASSERT( compound->capsuleOffset > 0 );
		b3CompoundCapsule* capsules = (b3CompoundCapsule*)( (intptr_t)compound + compound->capsuleOffset );
		memcpy( capsules, capsuleInstances, capsuleCount * sizeof( b3CompoundCapsule ) );
	}

	// Hulls
	for ( int i = 0; i < hullCount; ++i )
	{
		// Fix up offsets
		int sharedIndex = hullInstances[i].hullOffset;
		B3_ASSERT( 0 <= sharedIndex && sharedIndex < sharedHullCount );
		hullInstances[i].hullOffset = sharedHulls[sharedIndex].hullOffset;
	}

	b3HullInstance* destinationHullInstances = (b3HullInstance*)( (intptr_t)compound + hullArrayOffset );
	memcpy( destinationHullInstances, hullInstances, hullCount * sizeof( b3HullInstance ) );

	for ( int i = 0; i < sharedHullCount; ++i )
	{
		int offset = sharedHulls[i].hullOffset;
		b3HullData* destinationHull = (b3HullData*)( (intptr_t)compound + offset );
		memcpy( destinationHull, sharedHulls[i].hull, sharedHulls[i].hull->byteCount );
	}

	compound->sharedHullCount = sharedHullCount;

	// Meshes
	for ( int i = 0; i < meshCount; ++i )
	{
		// Fix up offsets
		int sharedIndex = meshInstances[i].meshOffset;
		B3_ASSERT( 0 <= sharedIndex && sharedIndex < sharedMeshCount );
		meshInstances[i].meshOffset = sharedMeshes[sharedIndex].meshOffset;
	}

	b3MeshInstance* destinationMeshInstances = (b3MeshInstance*)( (intptr_t)compound + meshArrayOffset );
	memcpy( destinationMeshInstances, meshInstances, meshCount * sizeof( b3MeshInstance ) );

	for ( int i = 0; i < sharedMeshCount; ++i )
	{
		int offset = sharedMeshes[i].meshOffset;
		b3MeshData* destinationMesh = (b3MeshData*)( (intptr_t)compound + offset );
		memcpy( destinationMesh, sharedMeshes[i].meshData, sharedMeshes[i].meshData->byteCount );
	}

	compound->sharedMeshCount = sharedMeshCount;

	// Spheres
	if ( def->sphereCount > 0 )
	{
		B3_ASSERT( compound->sphereOffset > 0 );
		b3CompoundSphere* spheres = (b3CompoundSphere*)( (intptr_t)compound + compound->sphereOffset );
		memcpy( spheres, sphereInstances, sphereCount * sizeof( b3CompoundSphere ) );
	}

	b3MaterialMap_cleanup( &materialMap );
	b3Free( sharedHulls, hullCount * sizeof( b3SharedHull ) );
	b3Free( sharedMeshes, meshCount * sizeof( b3SharedMesh ) );
	b3Free( capsuleInstances, capsuleCount * sizeof( b3CompoundCapsule ) );
	b3Free( hullInstances, hullCount * sizeof( b3HullInstance ) );
	b3Free( meshInstances, meshCount * sizeof( b3MeshInstance ) );
	b3Free( sphereInstances, sphereCount * sizeof( b3CompoundSphere ) );
	b3Free( materials, materialCapacity * sizeof( b3SurfaceMaterial ) );
	b3DynamicTree_Destroy( &tree );

	return compound;
}

void b3DestroyCompound( b3CompoundData* compound )
{
	b3Free( compound, compound->byteCount );
}

uint8_t* b3ConvertCompoundToBytes( b3CompoundData* compound )
{
	// scrub this pointer before serialization
	compound->tree.nodes = NULL;
	return (uint8_t*)compound;
}

b3CompoundData* b3ConvertBytesToCompound( uint8_t* bytes, int byteCount )
{
	b3CompoundData* compound = (b3CompoundData*)bytes;
	if ( compound->version != B3_COMPOUND_VERSION )
	{
		return NULL;
	}

	if ( compound->byteCount < (int)sizeof( b3CompoundData ) )
	{
		return NULL;
	}

	if ( byteCount != compound->byteCount )
	{
		return NULL;
	}

	if ( compound->nodeOffset <= 0 )
	{
		return NULL;
	}

	// this mutates the input bytes
	compound->tree.nodes = (b3TreeNode*)( (intptr_t)compound + compound->nodeOffset );
	return compound;
}

b3AABB b3ComputeCompoundAABB( const b3CompoundData* shape, b3Transform transform )
{
	B3_ASSERT( shape->nodeOffset > 0 );

	const b3TreeNode* nodes = (const b3TreeNode*)( (intptr_t)shape + shape->nodeOffset );
	int root = shape->tree.root;
	b3AABB aabb = nodes[root].aabb;
	return b3AABB_Transform( transform, aabb );
}

struct b3CompoundOverlapContext
{
	const b3CompoundData* compound;
	// transform of the compound
	b3Transform transform;
	b3ShapeProxy proxy;
	bool overlap;
};

static bool b3CompoundOverlapCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int childIndex = (int)userData;
	struct b3CompoundOverlapContext* overlapContext = context;
	b3ChildShape child = b3GetCompoundChild( overlapContext->compound, childIndex );

	b3Transform transform = b3MulTransforms( overlapContext->transform, child.transform );

	bool overlap = false;
	switch ( child.type )
	{
		case b3_capsuleShape:
			overlap = b3OverlapCapsule( &child.capsule, transform, &overlapContext->proxy );
			break;

		case b3_hullShape:
			overlap = b3OverlapHull( child.hull, transform, &overlapContext->proxy );
			break;

		case b3_meshShape:
			overlap = b3OverlapMesh( &child.mesh, transform, &overlapContext->proxy );
			break;

		case b3_sphereShape:
			overlap = b3OverlapSphere( &child.sphere, transform, &overlapContext->proxy );
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	if ( overlap )
	{
		// Done
		overlapContext->overlap = true;
		return false;
	}

	// Continue the query if there is no overlap
	return true;
}

bool b3OverlapCompound( const b3CompoundData* shape, b3Transform shapeTransform, const b3ShapeProxy* proxy )
{
	struct b3CompoundOverlapContext context = {
		.compound = shape,
		.transform = shapeTransform,
		.proxy = *proxy,
		.overlap = false,
	};

	b3AABB aabb = { proxy->points[0], proxy->points[0] };
	for ( int i = 1; i < proxy->count; ++i )
	{
		aabb.lowerBound = b3Min( aabb.lowerBound, proxy->points[i] );
		aabb.upperBound = b3Max( aabb.upperBound, proxy->points[i] );
	}

	b3Vec3 r = { proxy->radius, proxy->radius, proxy->radius };
	aabb.lowerBound = b3Sub( aabb.lowerBound, r );
	aabb.upperBound = b3Add( aabb.upperBound, r );

	(void)b3DynamicTree_Query( &shape->tree, aabb, ~0ull, false, b3CompoundOverlapCallback, &context );

	return context.overlap;
}

struct b3CompoundCastContext
{
	const b3CompoundData* compound;
	b3CastOutput* output;
	// origin of the shape cast, the box cast callback only carries the advancing fraction
	const b3ShapeCastInput* shapeInput;
};

static float b3CompoundRayCastCallback( const b3RayCastInput* input, int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	struct b3CompoundCastContext* castContext = context;
	const b3CompoundData* compound = castContext->compound;

	int childIndex = (int)userData;

	b3ChildShape child = b3GetCompoundChild( compound, childIndex );

	b3RayCastInput localInput = *input;
	localInput.origin = b3InvTransformPoint( child.transform, input->origin );
	localInput.translation = b3InvRotateVector( child.transform.q, input->translation );

	b3CastOutput output = { 0 };

	switch ( child.type )
	{
		case b3_capsuleShape:
			output = b3RayCastCapsule( &child.capsule, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		case b3_hullShape:
			output = b3RayCastHull( child.hull, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		case b3_meshShape:
		{
			output = b3RayCastMesh( &child.mesh, &localInput );
			B3_ASSERT( 0 <= output.materialIndex );
			int childMaterialIndex = b3MinInt( output.materialIndex, B3_MAX_COMPOUND_MESH_MATERIALS - 1 );
			output.materialIndex = child.materialIndices[childMaterialIndex];
		}
		break;

		case b3_sphereShape:
			output = b3RayCastSphere( &child.sphere, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	if ( output.hit )
	{
		output.point = b3TransformPoint( child.transform, output.point );
		output.normal = b3RotateVector( child.transform.q, output.normal );
		output.childIndex = childIndex;
		*castContext->output = output;
		return output.fraction;
	}

	return input->maxFraction;
}

b3CastOutput b3RayCastCompound( const b3CompoundData* shape, const b3RayCastInput* input )
{
	b3CastOutput result = { 0 };

	struct b3CompoundCastContext context = {
		.compound = shape,
		.output = &result,
	};
	(void)b3DynamicTree_RayCast( &shape->tree, input, ~0ull, false, b3CompoundRayCastCallback, &context );
	return result;
}

static float b3CompoundShapeCastCallback( const b3BoxCastInput* input, int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	struct b3CompoundCastContext* castContext = context;
	const b3CompoundData* compound = castContext->compound;
	const b3ShapeCastInput* shapeInput = castContext->shapeInput;

	int childIndex = (int)userData;

	b3ChildShape child = b3GetCompoundChild( compound, childIndex );

	// Rebuild from the carried shape cast input, taking only the advancing fraction from the tree
	b3ShapeCastInput localInput = *shapeInput;
	localInput.maxFraction = input->maxFraction;
	b3Vec3 localPoints[B3_MAX_SHAPE_CAST_POINTS];

	localInput.proxy.count = b3MinInt( shapeInput->proxy.count, B3_MAX_SHAPE_CAST_POINTS );

	b3Transform invTransform = b3InvertTransform( child.transform );
	b3Matrix3 R = b3MakeMatrixFromQuat( invTransform.q );

	for ( int i = 0; i < localInput.proxy.count; ++i )
	{
		localPoints[i] = b3Add( b3MulMV( R, shapeInput->proxy.points[i] ), invTransform.p );
	}

	localInput.proxy.points = localPoints;
	localInput.translation = b3MulMV( R, shapeInput->translation );

	b3CastOutput output = { 0 };

	switch ( child.type )
	{
		case b3_capsuleShape:
			output = b3ShapeCastCapsule( &child.capsule, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		case b3_hullShape:
			output = b3ShapeCastHull( child.hull, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		case b3_meshShape:
		{
			output = b3ShapeCastMesh( &child.mesh, &localInput );
			B3_ASSERT( 0 <= output.materialIndex );
			int childMaterialIndex = b3MinInt( output.materialIndex, B3_MAX_COMPOUND_MESH_MATERIALS - 1 );
			output.materialIndex = child.materialIndices[childMaterialIndex];
		}
		break;

		case b3_sphereShape:
			output = b3ShapeCastSphere( &child.sphere, &localInput );
			output.materialIndex = child.materialIndices[0];
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	if ( output.hit )
	{
		output.point = b3TransformPoint( child.transform, output.point );
		output.normal = b3RotateVector( child.transform.q, output.normal );
		output.childIndex = childIndex;
		*castContext->output = output;
		return output.fraction;
	}

	return input->maxFraction;
}

b3CastOutput b3ShapeCastCompound( const b3CompoundData* shape, const b3ShapeCastInput* input )
{
	b3CastOutput result = { 0 };

	if ( input->proxy.count == 0 )
	{
		return result;
	}

	struct b3CompoundCastContext context = {
		.compound = shape,
		.output = &result,
		.shapeInput = input,
	};

	// The compound tree is in the compound local frame, so the proxy box needs no origin offset
	b3AABB box = b3MakeAABB( input->proxy.points, input->proxy.count, input->proxy.radius );
	b3BoxCastInput treeInput = { box, input->translation, input->maxFraction };
	(void)b3DynamicTree_BoxCast( &shape->tree, &treeInput, ~0ull, false, b3CompoundShapeCastCallback, &context );
	return result;
}

struct b3CompoundQueryContext
{
	const b3CompoundData* compound;
	b3CompoundQueryFcn* fcn;
	void* userContext;
};

static bool TreeQueryCallbackFcn( int proxyId, uint64_t userData, void* treeContext )
{
	B3_UNUSED( proxyId );
	struct b3CompoundQueryContext* context = treeContext;
	return context->fcn( context->compound, (int)userData, context->userContext );
}

void b3QueryCompound( const b3CompoundData* compound, b3AABB aabb, b3CompoundQueryFcn* fcn, void* context )
{
	struct b3CompoundQueryContext compoundContext = {
		.compound = compound,
		.fcn = fcn,
		.userContext = context,
	};

	b3DynamicTree_Query( &compound->tree, aabb, B3_DEFAULT_MASK_BITS, false, TreeQueryCallbackFcn, &compoundContext );
}

#if 0
struct b3CompoundImpactContext
{
	b3TOIInput toiInput;
	b3TOIOutput toiOutput;
	b3Transform compoundTransform;

	// Bounds local to compound
	b3AABB localSweepBoundsB;

	// Centroid of shape in body B local space
	b3Vec3 localCentroidB;
	float fallbackRadius;
};

static bool b3CompoundTimeOfImpactFcn( const b3CompoundData* compound, int childIndex, void* context )
{
	b3CompoundImpactContext* toiContext = (b3CompoundImpactContext*)context;

	b3ChildShape child = b3GetCompoundChild( compound, childIndex );

	b3TOIOutput output = {0 };
	toiContext->toiInput.sweepA = b3MakeCompoundChildSweep( toiContext->compoundTransform, child.transform );

	switch ( child.type )
	{
		case b3_capsuleShape:
		{
			toiContext->toiInput.proxyA.points = &child.capsule.center1;
			toiContext->toiInput.proxyA.count = 2;
			toiContext->toiInput.proxyA.radius = child.capsule.radius;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		case b3_hullShape:
		{
			toiContext->toiInput.proxyA.points = b3GetHullPoints( child.hull );
			toiContext->toiInput.proxyA.count = child.hull->vertexCount;
			toiContext->toiInput.proxyA.radius = 0.0f;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		case b3_meshShape:
		{
			b3MeshImpactContext meshContext = {0};
			meshContext.toiInput = toiContext->toiInput;
			meshContext.isSensor = false;
			meshContext.localCentroidB = toiContext->localCentroidB;
			meshContext.fallbackRadius = toiContext->fallbackRadius;

			b3Transform meshWorldTransform = b3MulTransforms( toiContext->compoundTransform, child.transform );

			const b3Sweep* sweepB = &toiContext->toiInput.sweepB;
			b3Transform xfB1 = {
				.p = sweepB->c1 - b3RotateVector( sweepB->q1, sweepB->localCenter ),
				.q = sweepB->q1,
			};

			b3Transform xfB2 = {
				.p = sweepB->c2 - b3RotateVector( sweepB->q2, sweepB->localCenter ),
				.q = sweepB->q2,
			};

			meshContext.meshLocalCentroidB1 =
				b3InvTransformPoint( meshWorldTransform, b3TransformPoint( xfB1, meshContext.localCentroidB ) );
			meshContext.meshLocalCentroidB2 =
				b3InvTransformPoint( meshWorldTransform, b3TransformPoint( xfB2, meshContext.localCentroidB ) );

			// Bounds local to mesh
			b3AABB localBounds = b3AABB_Transform( b3InvertTransform( child.transform ), toiContext->localSweepBoundsB );

			b3QueryMesh( &child.mesh, localBounds, b3MeshTimeOfImpactFcn, &meshContext );

			output = meshContext.toiOutput;
		}
		break;

		case b3_sphereShape:
		{
			toiContext->toiInput.proxyA.points = &child.sphere.center;
			toiContext->toiInput.proxyA.count = 1;
			toiContext->toiInput.proxyA.radius = child.sphere.radius;
			output = b3TimeOfImpact( &toiContext->toiInput );
		}
		break;

		default:
			B3_ASSERT( false );
			break;
	}

	if ( 0.0f < output.fraction && output.fraction < toiContext->toiInput.maxFraction )
	{
		toiContext->toiOutput = output;
		toiContext->toiInput.maxFraction = output.fraction;
	}

	// Clear this to be safe
	toiContext->toiInput.proxyA = {0};

	// Continue the query
	return true;
}

b3TOIOutput b3CompoundTimeOfImpact(const b3CompoundData* compound, b3Transform transform, const b3ShapeProxy* proxy,
	const b3Sweep* sweep, float maxFraction)
{
	b3CompoundImpactContext context = {0};
	context.toiInput.proxyB = b3MakeShapeProxy( shapeB );
	context.toiInput.sweepB = *sweepB;
	context.toiInput.maxFraction = maxFraction;

	context.compoundTransform = {
		.p = sweepA->c1,
		.q = sweepA->q1,
	};

	b3Vec3 localCentroidB = b3GetShapeCentroid( shapeB );
	context.localCentroidB = localCentroidB;

	b3ShapeExtent extents = b3ComputeShapeExtent( shapeB, context.localCentroidB );
	context.fallbackRadius = b3MaxFloat( 0.5f * extents.minExtent, B3_SPECULATIVE_DISTANCE );

	// Swept bounds of shapeB
	b3AABB aabb = b3ComputeSweptShapeAABB( shapeB, sweepB, maxFraction );

	// Bounds local to mesh
	b3AABB localBounds = b3AABB_Transform( b3InvertTransform( context.compoundTransform ), bounds );
	context.localSweepBoundsB = localBounds;

	b3DynamicTree_Query( &compound->tree, aabb, B3_DEFAULT_MASK_BITS, false, TreeQueryCallbackFcn, &compoundContext );

	return context.toiOutput;
}
#endif

// xf = xfP * xfC
b3Sweep b3MakeCompoundChildSweep( b3Transform compoundTransform, b3Transform childTransform )
{
	b3Transform xf = b3MulTransforms( compoundTransform, childTransform );
	return (b3Sweep){
		.localCenter = b3Vec3_zero,
		.c1 = xf.p,
		.c2 = xf.p,
		.q1 = xf.q,
		.q2 = xf.q,
	};
}

struct b3CompoundMoverContext
{
	const b3CompoundData* compound;
	b3PlaneResult* planes;
	int planeCapacity;
	int planeCount;
	b3Capsule mover;
};

static bool b3CompoundMoverCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int childIndex = (int)userData;
	struct b3CompoundMoverContext* moverContext = context;
	b3ChildShape child = b3GetCompoundChild( moverContext->compound, childIndex );

	// Transform mover to child space
	b3Capsule localMover;
	localMover.center1 = b3InvTransformPoint( child.transform, moverContext->mover.center1 );
	localMover.center2 = b3InvTransformPoint( child.transform, moverContext->mover.center2 );
	localMover.radius = moverContext->mover.radius;

	int capacity = moverContext->planeCapacity - moverContext->planeCount;
	B3_ASSERT( capacity > 0 );

	b3PlaneResult* planes = moverContext->planes + moverContext->planeCount;
	int planeCount = 0;

	switch ( child.type )
	{
		case b3_capsuleShape:
			planeCount = b3CollideMoverAndCapsule( planes, &child.capsule, &localMover );
			break;

		case b3_hullShape:
			planeCount = b3CollideMoverAndHull( planes, child.hull, &localMover );
			break;

		case b3_meshShape:
			planeCount = b3CollideMoverAndMesh( planes, capacity, &child.mesh, &localMover );
			break;

		case b3_sphereShape:
			planeCount = b3CollideMoverAndSphere( planes, &child.sphere, &localMover );
			break;

		default:
			B3_ASSERT( false );
			break;
	}

	// Transform results back to shape space
	for ( int i = 0; i < planeCount; ++i )
	{
		planes[i].plane.normal = b3RotateVector( child.transform.q, planes[i].plane.normal );
		planes[i].point = b3TransformPoint( child.transform, planes[i].point );
	}

	moverContext->planeCount += planeCount;

	// Continue query while there is room for more planes
	return moverContext->planeCount < moverContext->planeCapacity;
}

int b3CollideMoverAndCompound( b3PlaneResult* planes, int capacity, const b3CompoundData* shape, const b3Capsule* mover )
{
	struct b3CompoundMoverContext context = {
		.compound = shape,
		.planes = planes,
		.planeCapacity = capacity,
		.planeCount = 0,
		.mover = *mover,
	};

	b3AABB aabb;
	aabb.lowerBound = b3Min( mover->center1, mover->center2 );
	aabb.upperBound = b3Max( mover->center1, mover->center2 );
	b3Vec3 r = { mover->radius, mover->radius, mover->radius };
	aabb.lowerBound = b3Sub( aabb.lowerBound, r );
	aabb.upperBound = b3Add( aabb.upperBound, r );

	(void)b3DynamicTree_Query( &shape->tree, aabb, ~0ull, false, b3CompoundMoverCallback, &context );

	return context.planeCount;
}
