// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#if defined( _MSC_VER ) && !defined( _CRT_SECURE_NO_WARNINGS )
#define _CRT_SECURE_NO_WARNINGS
#endif

#include "world_snapshot.h"

#include "bitset.h"
#include "body.h"
#include "broad_phase.h"
#include "compound.h"
#include "constraint_graph.h"
#include "contact.h"
#include "container.h"
#include "core.h"
#include "id_pool.h"
#include "island.h"
#include "joint.h"
#include "physics_world.h"
#include "recording.h"
#include "sensor.h"
#include "shape.h"
#include "solver_set.h"
#include "table.h"

#include "box3d/box3d.h"
#include "box3d/collision.h"
#include "box3d/types.h"

#include <string.h>

// Snapshot image magic 'BNS3' and version
#define B3_SNAP_MAGIC 0x33534E42u
#define B3_SNAP_VERSION 2u

#define B3_SNAP_FLAG_VALIDATION 0x1u
#define B3_SNAP_FLAG_DOUBLE_PRECISION 0x2u

// Layout hash over all POD-copied structs + key constants.
// Changing a struct size updates this, catching ABI drift early.
static uint32_t b3ComputeLayoutHash( void )
{
	uint32_t h = 2166136261u;
#define MIX( x )                                                                                                                 \
	h ^= (uint32_t)( x );                                                                                                        \
	h *= 16777619u;
	MIX( sizeof( b3Body ) )
	MIX( sizeof( b3BodySim ) )
	MIX( sizeof( b3BodyState ) )
	MIX( sizeof( b3Shape ) )
	MIX( sizeof( b3Contact ) )
	MIX( sizeof( b3Manifold ) )
	MIX( sizeof( b3Joint ) )
	MIX( sizeof( b3JointSim ) )
	MIX( sizeof( b3Island ) )
	MIX( sizeof( b3IslandSim ) )
	MIX( sizeof( b3ContactLink ) )
	MIX( sizeof( b3JointLink ) )
	MIX( sizeof( b3Sensor ) )
	MIX( sizeof( b3Visitor ) )
	MIX( sizeof( b3SolverSet ) )
	MIX( sizeof( b3GraphColor ) )
	MIX( sizeof( b3DynamicTree ) )
	MIX( sizeof( b3TreeNode ) )
	MIX( sizeof( b3SetItem ) )
	MIX( sizeof( b3IdPool ) )
	MIX( sizeof( b3SurfaceMaterial ) )
	MIX( sizeof( b3ContactSpec ) )
	MIX( sizeof( b3TriangleCache ) )
	MIX( B3_GRAPH_COLOR_COUNT )
	MIX( b3_bodyTypeCount )
	MIX( sizeof( void* ) )
#undef MIX
	return h;
}

typedef struct b3SnapHeader
{
	uint32_t magic;
	uint32_t version;
	uint32_t layoutHash;
	uint32_t flags;
} b3SnapHeader;

// Bounds-checked read cursor
typedef struct b3SnapReader
{
	const uint8_t* data;
	int cursor;
	int size;
	bool ok;
} b3SnapReader;

static void b3SnapRCheck( b3SnapReader* r, int need )
{
	if ( need < 0 || (int64_t)r->cursor + (int64_t)need > (int64_t)r->size )
	{
		r->ok = false;
	}
}

static void b3SnapR_Bytes( b3SnapReader* r, void* dst, int n )
{
	b3SnapRCheck( r, n );
	if ( !r->ok )
	{
		return;
	}
	memcpy( dst, r->data + r->cursor, n );
	r->cursor += n;
}

static int b3SnapR_I32( b3SnapReader* r )
{
	int32_t v = 0;
	b3SnapR_Bytes( r, &v, 4 );
	return (int)v;
}

static uint32_t b3SnapR_U32( b3SnapReader* r )
{
	uint32_t v = 0;
	b3SnapR_Bytes( r, &v, 4 );
	return v;
}

static void b3SnapW_I32( b3RecBuffer* buf, int v )
{
	int32_t w = (int32_t)v;
	b3RecBufAppend( buf, &w, 4 );
}

static void b3SnapW_U32( b3RecBuffer* buf, uint32_t v )
{
	b3RecBufAppend( buf, &v, 4 );
}

static void b3SnapW_Bytes( b3RecBuffer* buf, const void* src, int n )
{
	b3RecBufAppend( buf, src, n );
}

// Bounds check before allocating from image
static bool b3SnapCheckCount( const b3SnapReader* r, int count, int memSize, int minStreamBytes )
{
	if ( count < 0 || memSize < 0 || minStreamBytes < 0 )
	{
		return false;
	}
	if ( memSize > 0 && count > 0x7FFFFFFF / memSize )
	{
		return false;
	}
	int64_t remaining = (int64_t)r->size - (int64_t)r->cursor;
	return (int64_t)count * (int64_t)minStreamBytes <= remaining;
}

// POD array: count + raw bytes
#define b3SerPodArray( buf, arr )                                                                                                \
	do                                                                                                                           \
	{                                                                                                                            \
		b3SnapW_I32( buf, ( arr ).count );                                                                                       \
		if ( ( arr ).count > 0 )                                                                                                 \
		{                                                                                                                        \
			b3SnapW_Bytes( buf, ( arr ).data, ( arr ).count * (int)sizeof( *( arr ).data ) );                                    \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

#define b3DesPodArray( r, arr )                                                                                                  \
	do                                                                                                                           \
	{                                                                                                                            \
		int cnt = b3SnapR_I32( r );                                                                                              \
		int elemSize = (int)sizeof( *( arr ).data );                                                                             \
		if ( ( r )->ok && b3SnapCheckCount( r, cnt, elemSize, elemSize ) == false )                                              \
		{                                                                                                                        \
			( r )->ok = false;                                                                                                   \
		}                                                                                                                        \
		if ( ( r )->ok && cnt > 0 )                                                                                              \
		{                                                                                                                        \
			b3Array_Resize( arr, cnt );                                                                                          \
			b3SnapR_Bytes( r, ( arr ).data, cnt * elemSize );                                                                    \
		}                                                                                                                        \
		else if ( ( r )->ok )                                                                                                    \
		{                                                                                                                        \
			( arr ).count = 0;                                                                                                   \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

// Id pool: nextIndex + freeArray
static void b3SerIdPool( b3RecBuffer* buf, const b3IdPool* pool )
{
	b3SnapW_I32( buf, pool->nextIndex );
	b3SerPodArray( buf, pool->freeArray );
}

static void b3DesIdPool( b3SnapReader* r, b3IdPool* pool )
{
	pool->nextIndex = b3SnapR_I32( r );
	b3DesPodArray( r, pool->freeArray );
}

// BitSet: blockCount + raw words
static void b3SerBitSet( b3RecBuffer* buf, const b3BitSet* bs )
{
	b3SnapW_U32( buf, bs->blockCount );
	if ( bs->blockCount > 0 )
	{
		b3SnapW_Bytes( buf, bs->bits, (int)( bs->blockCount * sizeof( uint64_t ) ) );
	}
}

static void b3DesBitSet( b3SnapReader* r, b3BitSet* bs )
{
	uint32_t blockCount = b3SnapR_U32( r );
	if ( r->ok && b3SnapCheckCount( r, (int)blockCount, (int)sizeof( uint64_t ), (int)sizeof( uint64_t ) ) == false )
	{
		r->ok = false;
	}
	b3DestroyBitSet( bs );
	if ( !r->ok )
	{
		return;
	}
	uint32_t blockCapacity = blockCount > 0 ? blockCount : 1;
	bs->bits = (uint64_t*)b3Alloc( blockCapacity * sizeof( uint64_t ) );
	memset( bs->bits, 0, blockCapacity * sizeof( uint64_t ) );
	bs->blockCapacity = blockCapacity;
	bs->blockCount = blockCount;
	if ( blockCount > 0 )
	{
		b3SnapR_Bytes( r, bs->bits, (int)( blockCount * sizeof( uint64_t ) ) );
	}
}

// HashSet: capacity + count + raw items (probe order depends on layout)
static void b3SerHashSet( b3RecBuffer* buf, const b3HashSet* hs )
{
	b3SnapW_U32( buf, hs->capacity );
	b3SnapW_U32( buf, hs->count );
	if ( hs->capacity > 0 )
	{
		b3SnapW_Bytes( buf, hs->items, (int)( hs->capacity * sizeof( b3SetItem ) ) );
	}
}

static void b3DesHashSet( b3SnapReader* r, b3HashSet* hs )
{
	uint32_t cap = b3SnapR_U32( r );
	uint32_t cnt = b3SnapR_U32( r );
	bool valid = b3SnapCheckCount( r, (int)cap, (int)sizeof( b3SetItem ), (int)sizeof( b3SetItem ) ) &&
				 ( cap & ( cap - 1 ) ) == 0 && cnt <= cap;
	if ( r->ok && valid == false && ( cap != 0 || cnt != 0 ) )
	{
		r->ok = false;
	}
	b3DestroySet( hs );
	if ( !r->ok )
	{
		return;
	}
	if ( cap > 0 )
	{
		hs->items = (b3SetItem*)b3Alloc( cap * sizeof( b3SetItem ) );
		hs->capacity = cap;
		hs->count = cnt;
		b3SnapR_Bytes( r, hs->items, (int)( cap * sizeof( b3SetItem ) ) );
	}
	else
	{
		hs->items = NULL;
		hs->capacity = 0;
		hs->count = 0;
	}
}

// DynamicTree: version, scalars, full nodeCapacity nodes (rebuild scratch excluded)
static void b3SerTree( b3RecBuffer* buf, const b3DynamicTree* tree )
{
	b3SnapW_Bytes( buf, &tree->version, sizeof( uint64_t ) );
	b3SnapW_I32( buf, tree->root );
	b3SnapW_I32( buf, tree->nodeCount );
	b3SnapW_I32( buf, tree->nodeCapacity );
	b3SnapW_I32( buf, tree->freeList );
	b3SnapW_I32( buf, tree->proxyCount );
	if ( tree->nodeCapacity > 0 )
	{
		b3SnapW_Bytes( buf, tree->nodes, tree->nodeCapacity * (int)sizeof( b3TreeNode ) );
	}
}

static void b3DesTree( b3SnapReader* r, b3DynamicTree* tree )
{
	uint64_t version;
	b3SnapR_Bytes( r, &version, sizeof( uint64_t ) );
	int root = b3SnapR_I32( r );
	int nodeCount = b3SnapR_I32( r );
	int nodeCapacity = b3SnapR_I32( r );
	int freeList = b3SnapR_I32( r );
	int proxyCount = b3SnapR_I32( r );

	if ( r->ok && b3SnapCheckCount( r, nodeCapacity, (int)sizeof( b3TreeNode ), (int)sizeof( b3TreeNode ) ) == false )
	{
		r->ok = false;
	}

	// Free existing allocation including any rebuild scratch
	b3Free( tree->nodes, tree->nodeCapacity * (int)sizeof( b3TreeNode ) );
	b3Free( tree->leafIndices, tree->rebuildCapacity * (int)sizeof( int ) );
	b3Free( tree->leafBoxes, tree->rebuildCapacity * (int)sizeof( b3AABB ) );
	b3Free( tree->leafCenters, tree->rebuildCapacity * (int)sizeof( b3Vec3 ) );
	b3Free( tree->binIndices, tree->rebuildCapacity * (int)sizeof( int ) );
	tree->nodes = NULL;
	tree->leafIndices = NULL;
	tree->leafBoxes = NULL;
	tree->leafCenters = NULL;
	tree->binIndices = NULL;
	tree->nodeCapacity = 0;
	tree->rebuildCapacity = 0;

	if ( !r->ok )
	{
		return;
	}

	tree->version = version;
	tree->root = root;
	tree->nodeCount = nodeCount;
	tree->nodeCapacity = nodeCapacity;
	tree->freeList = freeList;
	tree->proxyCount = proxyCount;

	if ( nodeCapacity > 0 )
	{
		tree->nodes = (b3TreeNode*)b3Alloc( nodeCapacity * (int)sizeof( b3TreeNode ) );
		b3SnapR_Bytes( r, tree->nodes, nodeCapacity * (int)sizeof( b3TreeNode ) );
	}
}

// Solver set: setIndex + 4 arrays (note: contactIndices is int array, not contactSims)
static void b3SerSolverSet( b3RecBuffer* buf, const b3SolverSet* set )
{
	b3SnapW_I32( buf, set->setIndex );
	b3SerPodArray( buf, set->bodySims );
	b3SerPodArray( buf, set->bodyStates );
	b3SerPodArray( buf, set->jointSims );
	b3SerPodArray( buf, set->contactIndices );
	b3SerPodArray( buf, set->islandSims );
}

static void b3DesSolverSet( b3SnapReader* r, b3SolverSet* set )
{
	set->setIndex = b3SnapR_I32( r );
	b3DesPodArray( r, set->bodySims );
	b3DesPodArray( r, set->bodyStates );
	b3DesPodArray( r, set->jointSims );
	b3DesPodArray( r, set->contactIndices );
	b3DesPodArray( r, set->islandSims );
}

static void b3SerNames( b3RecBuffer* buf, const b3NameCache* cache )
{
	b3SnapW_I32( buf, cache->entries.count );
	int count = cache->entries.count;
	for ( int i = 0; i < count; ++i )
	{
		const b3NameEntry* entry = cache->entries.data + i;
		b3SnapW_U32( buf, entry->hash );
		b3SnapW_I32( buf, entry->length );
		b3RecBufAppend( buf, entry->name, entry->length );
	}
}

static void b3DesNames( b3SnapReader* r, b3NameCache* cache )
{
	int count = b3SnapR_I32( r );

	if ( r->ok && b3SnapCheckCount( r, count, (int)sizeof( b3NameEntry ), 8 ) == false )
	{
		r->ok = false;
	}

	if ( r->ok == false )
	{
		return;
	}

	b3Array_Reserve( cache->entries, count );
	for ( int i = 0; i < count; ++i )
	{
		uint32_t hash = b3SnapR_U32( r );
		int length = b3SnapR_I32( r );
		if ( r->ok == false || length < 0 || length > r->size - r->cursor )
		{
			r->ok = false;
			return;
		}
		char* name = b3Alloc( length + 1 );
		b3SnapR_Bytes( r, name, length );
		name[length] = 0;
		b3LoadName( cache, hash, name, length );
	}
}

// Graph color: bodySet (non-overflow only) + jointSims + convexContacts + contacts
static void b3SerGraphColor( b3RecBuffer* buf, const b3GraphColor* color, bool isOverflow )
{
	if ( !isOverflow )
	{
		b3SerBitSet( buf, &color->bodySet );
	}
	b3SerPodArray( buf, color->jointSims );
	b3SerPodArray( buf, color->convexContacts );
	b3SerPodArray( buf, color->contacts );
	// wideConstraints / manifoldConstraints / contactConstraints are transient, not serialized
}

static void b3DesGraphColor( b3SnapReader* r, b3GraphColor* color, bool isOverflow )
{
	if ( !isOverflow )
	{
		b3DesBitSet( r, &color->bodySet );
	}
	b3DesPodArray( r, color->jointSims );
	b3DesPodArray( r, color->convexContacts );
	b3DesPodArray( r, color->contacts );
	// Transient pointers left at NULL/0 from shell
}

// World simulation scalars (never host/callback/worker state)
static void b3SerWorldConfig( b3RecBuffer* buf, const b3World* world )
{
	b3SnapW_Bytes( buf, &world->gravity, sizeof( b3Vec3 ) );
	b3SnapW_Bytes( buf, &world->hitEventThreshold, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->restitutionThreshold, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->maxLinearSpeed, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->contactSpeed, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->contactHertz, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->contactDampingRatio, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->contactRecycleDistance, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->stepIndex, sizeof( uint64_t ) );
	b3SnapW_I32( buf, world->splitIslandId );
	b3SnapW_Bytes( buf, &world->inv_h, sizeof( float ) );
	b3SnapW_Bytes( buf, &world->inv_dt, sizeof( float ) );
	b3SnapW_I32( buf, world->endEventArrayIndex );
	b3SnapW_Bytes( buf, &world->maxCapacity, sizeof( b3Capacity ) );
	uint8_t flags = 0;
	flags |= world->enableSleep ? 0x01u : 0u;
	flags |= world->enableWarmStarting ? 0x02u : 0u;
	flags |= world->enableContinuous ? 0x04u : 0u;
	flags |= world->enableSpeculative ? 0x08u : 0u;
	b3RecBufAppend( buf, &flags, 1 );
}

static void b3DesWorldConfig( b3SnapReader* r, b3World* world )
{
	b3SnapR_Bytes( r, &world->gravity, sizeof( b3Vec3 ) );
	b3SnapR_Bytes( r, &world->hitEventThreshold, sizeof( float ) );
	b3SnapR_Bytes( r, &world->restitutionThreshold, sizeof( float ) );
	b3SnapR_Bytes( r, &world->maxLinearSpeed, sizeof( float ) );
	b3SnapR_Bytes( r, &world->contactSpeed, sizeof( float ) );
	b3SnapR_Bytes( r, &world->contactHertz, sizeof( float ) );
	b3SnapR_Bytes( r, &world->contactDampingRatio, sizeof( float ) );
	b3SnapR_Bytes( r, &world->contactRecycleDistance, sizeof( float ) );
	b3SnapR_Bytes( r, &world->stepIndex, sizeof( uint64_t ) );
	world->splitIslandId = b3SnapR_I32( r );
	b3SnapR_Bytes( r, &world->inv_h, sizeof( float ) );
	b3SnapR_Bytes( r, &world->inv_dt, sizeof( float ) );
	world->endEventArrayIndex = b3SnapR_I32( r );
	b3SnapR_Bytes( r, &world->maxCapacity, sizeof( b3Capacity ) );
	uint8_t flags = 0;
	b3SnapR_Bytes( r, &flags, 1 );
	world->enableSleep = ( flags & 0x01u ) != 0;
	world->enableWarmStarting = ( flags & 0x02u ) != 0;
	world->enableContinuous = ( flags & 0x04u ) != 0;
	world->enableSpeculative = ( flags & 0x08u ) != 0;
}

// Shapes carry pointer fields: materials, userData, userShape, and the geometry union.
// Serialize the POD scalars with pointers nulled, then the owned materials array, then geometry.
// A single material lives inline in the struct image.
// Hull/mesh/heightField/compound are interned into the recording registry; sphere/capsule inline.
static void b3SerShapes( b3RecBuffer* buf, b3World* world, b3Recording* rec )
{
	int count = world->shapes.count;
	b3SnapW_I32( buf, count );

	for ( int i = 0; i < count; ++i )
	{
		b3Shape shape = world->shapes.data[i];
		bool isLive = ( shape.id == i );

		// Null out pointer fields before writing the raw struct
		shape.materials = NULL;
		shape.userData = NULL;
		shape.userShape = NULL;
		// Zero the geometry union so free-slot images have deterministic bytes
		if ( !isLive )
		{
			memset( &shape.capsule, 0, sizeof( shape.capsule ) );
		}
		b3SnapW_Bytes( buf, &shape, sizeof( b3Shape ) );

		if ( !isLive )
		{
			// Free slot: no materials or geometry
			b3SnapW_I32( buf, 0 );	// materialCount
			b3SnapW_I32( buf, -1 ); // geometry kind sentinel
			continue;
		}

		// Owned material array. Only multi material meshes and compounds have one. A single material
		// already rode along inline in the struct image, so write a zero length for it.
		const b3Shape* src = world->shapes.data + i;
		if ( src->materials != NULL )
		{
			b3SnapW_I32( buf, src->materialCount );
			b3SnapW_Bytes( buf, src->materials, src->materialCount * (int)sizeof( b3SurfaceMaterial ) );
		}
		else
		{
			b3SnapW_I32( buf, 0 );
		}

		// Geometry
		switch ( src->type )
		{
			case b3_sphereShape:
				b3SnapW_I32( buf, (int)b3_sphereShape );
				b3SnapW_Bytes( buf, &src->sphere, sizeof( b3Sphere ) );
				break;
			case b3_capsuleShape:
				b3SnapW_I32( buf, (int)b3_capsuleShape );
				b3SnapW_Bytes( buf, &src->capsule, sizeof( b3Capsule ) );
				break;
			case b3_hullShape:
			{
				b3SnapW_I32( buf, (int)b3_hullShape );
				uint32_t gid = b3RecInternHull( rec, src->hull );
				b3SnapW_U32( buf, gid );
				break;
			}
			case b3_meshShape:
			{
				b3SnapW_I32( buf, (int)b3_meshShape );
				uint32_t gid = b3RecInternMesh( rec, src->mesh.data );
				b3SnapW_U32( buf, gid );
				b3SnapW_Bytes( buf, &src->mesh.scale, sizeof( b3Vec3 ) );
				break;
			}
			case b3_heightShape:
			{
				b3SnapW_I32( buf, (int)b3_heightShape );
				uint32_t gid = b3RecInternHeightField( rec, src->heightField );
				b3SnapW_U32( buf, gid );
				break;
			}
			case b3_compoundShape:
			{
				b3SnapW_I32( buf, (int)b3_compoundShape );
				uint32_t gid = b3RecInternCompound( rec, src->compound );
				b3SnapW_U32( buf, gid );
				break;
			}
			default:
				// A live shape must have a known geometry type. Fail loudly rather than emit a shape
				// with no geometry that would silently lose its collision on restore.
				B3_ASSERT( false );
				b3SnapW_I32( buf, -1 );
				break;
		}
	}
}

static void b3DesShapes( b3SnapReader* r, b3World* world, b3RecReader* rdr )
{
	int count = b3SnapR_I32( r );
	if ( r->ok && b3SnapCheckCount( r, count, (int)sizeof( b3Shape ), (int)sizeof( b3Shape ) ) == false )
	{
		r->ok = false;
	}
	if ( !r->ok )
	{
		return;
	}

	// Save renderer handles before the array is wiped. A keyframe restore is a deterministic replay
	// state, so a live shape that still occupies the same slot with the same generation is the same
	// shape with the same geometry. Carrying its handle over avoids tearing down and rebuilding every
	// GPU mesh on each seek, which the host (a 3D renderer) would otherwise pay for. Handles that are
	// not reclaimed below belong to shapes that are gone or were replaced, and get released so the host
	// pool does not leak across seeks. Box2D has no such handles, so its restore skips all of this.
	int oldShapeCount = world->shapes.count;
	void** savedUserShape = NULL;
	uint16_t* savedGeneration = NULL;
	if ( oldShapeCount > 0 )
	{
		savedUserShape = (void**)b3Alloc( (size_t)oldShapeCount * sizeof( void* ) );
		savedGeneration = (uint16_t*)b3Alloc( (size_t)oldShapeCount * sizeof( uint16_t ) );
		for ( int i = 0; i < oldShapeCount; ++i )
		{
			b3Shape* old = world->shapes.data + i;
			bool oldLive = ( old->id == i );
			savedUserShape[i] = oldLive ? old->userShape : NULL;
			savedGeneration[i] = old->generation;
		}
	}

	b3Array_Resize( world->shapes, count );
	memset( world->shapes.data, 0, (size_t)count * sizeof( b3Shape ) );

	for ( int i = 0; i < count && r->ok; ++i )
	{
		b3Shape* dst = world->shapes.data + i;
		b3SnapR_Bytes( r, dst, sizeof( b3Shape ) );
		// Pointer fields were written as NULL; set them cleanly
		dst->materials = NULL;
		dst->userData = NULL;
		dst->userShape = NULL;
		memset( &dst->capsule, 0, sizeof( dst->capsule ) );

		bool isLive = ( dst->id == i );

		// Carry the renderer handle over when the same shape still occupies this slot. Consumed
		// handles are nulled so the teardown sweep only releases the ones that vanished.
		if ( isLive && i < oldShapeCount && savedUserShape != NULL && savedUserShape[i] != NULL &&
			 savedGeneration[i] == dst->generation )
		{
			dst->userShape = savedUserShape[i];
			savedUserShape[i] = NULL;
		}

		// Serializer writes: matCount, matData, geoKind, geoData
		int matCount = b3SnapR_I32( r );

		if ( !r->ok )
		{
			break;
		}

		if ( !isLive )
		{
			// Free slot: matCount=0, geoKind=-1
			(void)matCount;
			b3SnapR_I32( r ); // consume the geoKind sentinel
			continue;
		}

		// Owned material array (written before geoKind in serializer). A zero length means the single
		// material is already inline in the restored struct image, so leave materialCount as restored.
		if ( matCount > 0 )
		{
			if ( b3SnapCheckCount( r, matCount, (int)sizeof( b3SurfaceMaterial ), (int)sizeof( b3SurfaceMaterial ) ) == false )
			{
				r->ok = false;
				break;
			}
			dst->materialCount = matCount;
			dst->materials = (b3SurfaceMaterial*)b3Alloc( (size_t)matCount * sizeof( b3SurfaceMaterial ) );
			b3SnapR_Bytes( r, dst->materials, matCount * (int)sizeof( b3SurfaceMaterial ) );
		}
		else
		{
			dst->materials = NULL;
		}

		int geoKind = b3SnapR_I32( r );

		// Geometry
		switch ( (b3ShapeType)geoKind )
		{
			case b3_sphereShape:
				b3SnapR_Bytes( r, &dst->sphere, sizeof( b3Sphere ) );
				break;
			case b3_capsuleShape:
				b3SnapR_Bytes( r, &dst->capsule, sizeof( b3Capsule ) );
				break;
			case b3_hullShape:
			{
				uint32_t gid = b3SnapR_U32( r );
				if ( !r->ok )
				{
					break;
				}
				if ( rdr == NULL || gid >= (uint32_t)rdr->slotCount )
				{
					r->ok = false;
					break;
				}
				// Hull is cloned into the world DB; pass raw bytes directly
				b3RegistrySlot* slot = rdr->slots + gid;
				dst->hull = b3AddHullToDatabase( world, (const b3HullData*)slot->bytes );
				break;
			}
			case b3_meshShape:
			{
				uint32_t gid = b3SnapR_U32( r );
				b3Vec3 scale;
				b3SnapR_Bytes( r, &scale, sizeof( b3Vec3 ) );
				if ( !r->ok )
				{
					break;
				}
				if ( rdr == NULL || gid >= (uint32_t)rdr->slotCount )
				{
					r->ok = false;
					break;
				}
				b3RegistrySlot* slot = rdr->slots + gid;
				// Mesh is a self-contained blob used by reference; point straight at the pristine bytes.
				dst->mesh.data = (const b3MeshData*)slot->bytes;
				dst->mesh.scale = scale;
				break;
			}
			case b3_heightShape:
			{
				uint32_t gid = b3SnapR_U32( r );
				if ( !r->ok )
				{
					break;
				}
				if ( rdr == NULL || gid >= (uint32_t)rdr->slotCount )
				{
					r->ok = false;
					break;
				}
				b3RegistrySlot* slot = rdr->slots + gid;
				// Self-contained blob used by reference; point straight at the pristine bytes.
				dst->heightField = (const b3HeightFieldData*)slot->bytes;
				break;
			}
			case b3_compoundShape:
			{
				uint32_t gid = b3SnapR_U32( r );
				if ( !r->ok )
				{
					break;
				}
				if ( rdr == NULL || gid >= (uint32_t)rdr->slotCount )
				{
					r->ok = false;
					break;
				}
				b3RegistrySlot* slot = rdr->slots + gid;
				if ( slot->live == NULL )
				{
					slot->live = b3Alloc( (size_t)slot->byteCount );
					memcpy( slot->live, slot->bytes, (size_t)slot->byteCount );
					b3ConvertBytesToCompound( (uint8_t*)slot->live, slot->byteCount );
				}
				dst->compound = (const b3CompoundData*)slot->live;
				break;
			}
			default:
				// Unknown geometry kind means a corrupt or unsupported snapshot. Fail the load instead
				// of leaving a shape with no geometry.
				r->ok = false;
				break;
		}
	}

	// Release handles for shapes that are gone or were replaced this restore, so the host pool and any
	// GPU resources they pinned do not leak across seeks.
	if ( savedUserShape != NULL )
	{
		for ( int i = 0; i < oldShapeCount; ++i )
		{
			if ( savedUserShape[i] != NULL && world->destroyDebugShape != NULL )
			{
				world->destroyDebugShape( savedUserShape[i], world->userDebugShapeContext );
			}
		}
		b3Free( savedUserShape, (size_t)oldShapeCount * sizeof( void* ) );
		b3Free( savedGeneration, (size_t)oldShapeCount * sizeof( uint16_t ) );
	}
}

// Contact serialization. b3Contact is not fully POD:
// - manifolds: heap array of b3Manifold, allocated via b3AllocateManifolds
// - meshContact.triangleCache: heap b3Array, active when b3_simMeshContact flag is set
// Serialize: raw struct (with nulled manifolds/triangleCache), then manifolds, then triangleCache.
static void b3SerContacts( b3RecBuffer* buf, b3World* world )
{
	int count = world->contacts.count;
	b3SnapW_I32( buf, count );

	for ( int i = 0; i < count; ++i )
	{
		const b3Contact* c = world->contacts.data + i;
		bool isLive = ( c->contactId == i );

		// Write raw struct with pointer fields zeroed
		b3Contact copy = *c;
		copy.manifolds = NULL;
		copy.bodySimIndexA = B3_NULL_INDEX;
		copy.bodySimIndexB = B3_NULL_INDEX;
		if ( copy.flags & b3_simMeshContact )
		{
			copy.meshContact.triangleCache.data = NULL;
			copy.meshContact.triangleCache.count = 0;
			copy.meshContact.triangleCache.capacity = 0;
		}
		b3SnapW_Bytes( buf, &copy, sizeof( b3Contact ) );

		if ( !isLive )
		{
			// Free slot: no heap data
			b3SnapW_I32( buf, 0 ); // manifoldCount
			// No triangleCache
			continue;
		}

		// Manifolds
		b3SnapW_I32( buf, c->manifoldCount );
		if ( c->manifoldCount > 0 && c->manifolds != NULL )
		{
			b3SnapW_Bytes( buf, c->manifolds, c->manifoldCount * (int)sizeof( b3Manifold ) );
		}

		// Mesh triangleCache
		if ( c->flags & b3_simMeshContact )
		{
			b3SnapW_I32( buf, c->meshContact.triangleCache.count );
			if ( c->meshContact.triangleCache.count > 0 )
			{
				b3SnapW_Bytes( buf, c->meshContact.triangleCache.data,
							   c->meshContact.triangleCache.count * (int)sizeof( b3TriangleCache ) );
			}
		}
	}
}

static void b3DesContacts( b3SnapReader* r, b3World* world )
{
	int count = b3SnapR_I32( r );
	if ( r->ok && b3SnapCheckCount( r, count, (int)sizeof( b3Contact ), (int)sizeof( b3Contact ) ) == false )
	{
		r->ok = false;
	}
	if ( !r->ok )
	{
		return;
	}

	b3Array_Resize( world->contacts, count );
	memset( world->contacts.data, 0, (size_t)count * sizeof( b3Contact ) );

	for ( int i = 0; i < count && r->ok; ++i )
	{
		b3Contact* dst = world->contacts.data + i;
		b3SnapR_Bytes( r, dst, sizeof( b3Contact ) );
		dst->manifolds = NULL;
		dst->bodySimIndexA = B3_NULL_INDEX;
		dst->bodySimIndexB = B3_NULL_INDEX;
		if ( dst->flags & b3_simMeshContact )
		{
			dst->meshContact.triangleCache.data = NULL;
			dst->meshContact.triangleCache.count = 0;
			dst->meshContact.triangleCache.capacity = 0;
		}

		bool isLive = ( dst->contactId == i );

		int manifoldCount = b3SnapR_I32( r );

		if ( !r->ok )
		{
			break;
		}

		if ( isLive && manifoldCount > 0 )
		{
			if ( b3SnapCheckCount( r, manifoldCount, (int)sizeof( b3Manifold ), (int)sizeof( b3Manifold ) ) == false )
			{
				r->ok = false;
				break;
			}
			dst->manifolds = b3AllocateManifolds( world, manifoldCount );
			dst->manifoldCount = manifoldCount;
			b3SnapR_Bytes( r, dst->manifolds, manifoldCount * (int)sizeof( b3Manifold ) );
		}
		else
		{
			dst->manifolds = NULL;
			dst->manifoldCount = 0;
		}

		// Mesh triangleCache
		if ( isLive && ( dst->flags & b3_simMeshContact ) )
		{
			int cacheCount = b3SnapR_I32( r );
			if ( !r->ok )
			{
				break;
			}
			if ( cacheCount > 0 )
			{
				if ( b3SnapCheckCount( r, cacheCount, (int)sizeof( b3TriangleCache ), (int)sizeof( b3TriangleCache ) ) == false )
				{
					r->ok = false;
					break;
				}
				b3Array_Resize( dst->meshContact.triangleCache, cacheCount );
				b3SnapR_Bytes( r, dst->meshContact.triangleCache.data, cacheCount * (int)sizeof( b3TriangleCache ) );
			}
		}
	}
}

// Free per-object heap that b3DeserializeIntoShell will overwrite,
// so restoring over a populated world doesn't leak.
static void b3FreeLiveSimElements( b3World* world )
{
	// Shape heap: materials and hull DB references
	for ( int i = 0; i < world->shapes.count; ++i )
	{
		b3Shape* s = world->shapes.data + i;
		if ( s->id != i )
		{
			continue;
		}
		// A single material lives inline (materials == NULL). Multi material meshes and compounds own
		// the array, so free it exactly as b3DestroyShapeAllocations does.
		if ( s->materials != NULL )
		{
			b3Free( s->materials, (size_t)s->materialCount * sizeof( b3SurfaceMaterial ) );
			s->materials = NULL;
			s->materialCount = 0;
		}
		// Hull is ref-counted in the world DB; release before overwrite so re-adding is ref-neutral.
		if ( s->type == b3_hullShape && s->hull != NULL )
		{
			b3RemoveHullFromDatabase( world, s->hull );
			s->hull = NULL;
		}
		// name / userData / userShape are host-owned; do not free
	}

	// Contact heap: manifolds + mesh triangleCache
	for ( int i = 0; i < world->contacts.count; ++i )
	{
		b3Contact* c = world->contacts.data + i;
		if ( c->contactId == i )
		{
			if ( c->manifolds != NULL )
			{
				b3FreeManifolds( world, c->manifolds, c->manifoldCount );
				c->manifolds = NULL;
				c->manifoldCount = 0;
			}
			if ( c->flags & b3_simMeshContact )
			{
				b3Array_Destroy( c->meshContact.triangleCache );
			}
		}
	}

	// Sensor heap: inner arrays
	for ( int i = 0; i < world->sensors.count; ++i )
	{
		b3Sensor* sensor = world->sensors.data + i;
		b3Array_Destroy( sensor->hits );
		b3Array_Destroy( sensor->overlaps1 );
		b3Array_Destroy( sensor->overlaps2 );
	}

	// Island heap: inner arrays
	for ( int i = 0; i < world->islands.count; ++i )
	{
		b3Island* island = world->islands.data + i;
		b3Array_Destroy( island->bodies );
		b3Array_Destroy( island->contacts );
		b3Array_Destroy( island->joints );
	}
}

int b3SerializeWorld( b3World* world, b3RecBuffer* buf, b3Recording* rec )
{
	int startSize = buf->size;

	// Snapshot header
	b3SnapHeader hdr;
	hdr.magic = B3_SNAP_MAGIC;
	hdr.version = B3_SNAP_VERSION;
	hdr.layoutHash = b3ComputeLayoutHash();
	hdr.flags = B3_ENABLE_VALIDATION ? B3_SNAP_FLAG_VALIDATION : 0u;
#if defined( BOX3D_DOUBLE_PRECISION )
	hdr.flags |= B3_SNAP_FLAG_DOUBLE_PRECISION;
#endif
	b3SnapW_Bytes( buf, &hdr, (int)sizeof( hdr ) );

	// World scalars
	b3SerWorldConfig( buf, world );

	// 6 id pools (Box3D has no chainIdPool)
	b3SerIdPool( buf, &world->bodyIdPool );
	b3SerIdPool( buf, &world->shapeIdPool );
	b3SerIdPool( buf, &world->contactIdPool );
	b3SerIdPool( buf, &world->jointIdPool );
	b3SerIdPool( buf, &world->islandIdPool );
	b3SerIdPool( buf, &world->solverSetIdPool );

	// Solver sets
	int setCount = world->solverSets.count;
	b3SnapW_I32( buf, setCount );
	for ( int i = 0; i < setCount; ++i )
	{
		b3SerSolverSet( buf, world->solverSets.data + i );
	}

	// Sparse body array (userData is host wiring, zero it on the copy)
	{
		int bodyCount = world->bodies.count;
		b3SnapW_I32( buf, bodyCount );
		for ( int i = 0; i < bodyCount; ++i )
		{
			b3Body elem = world->bodies.data[i];
			elem.userData = NULL;
			b3SnapW_Bytes( buf, &elem, sizeof( b3Body ) );
		}
	}

	// Shape sparse array with geometry interning
	b3SerShapes( buf, world, rec );

	// Contact sparse array with manifold and mesh triangleCache
	b3SerContacts( buf, world );

	// Joint sparse array (userData scrubbed)
	{
		int jointCount = world->joints.count;
		b3SnapW_I32( buf, jointCount );
		for ( int i = 0; i < jointCount; ++i )
		{
			b3Joint elem = world->joints.data[i];
			elem.userData = NULL;
			b3SnapW_Bytes( buf, &elem, sizeof( b3Joint ) );
		}
	}

	// Sensors: shapeId + 3 inner arrays each
	{
		int sensorCount = world->sensors.count;
		b3SnapW_I32( buf, sensorCount );
		for ( int i = 0; i < sensorCount; ++i )
		{
			b3Sensor* s = world->sensors.data + i;
			b3SnapW_I32( buf, s->shapeId );
			b3SerPodArray( buf, s->hits );
			b3SerPodArray( buf, s->overlaps1 );
			b3SerPodArray( buf, s->overlaps2 );
		}
	}

	// Islands: 4 scalars + 3 inner arrays each
	{
		int islandCount = world->islands.count;
		b3SnapW_I32( buf, islandCount );
		for ( int i = 0; i < islandCount; ++i )
		{
			b3Island* island = world->islands.data + i;
			b3SnapW_I32( buf, island->setIndex );
			b3SnapW_I32( buf, island->localIndex );
			b3SnapW_I32( buf, island->islandId );
			b3SnapW_I32( buf, island->constraintRemoveCount );
			b3SerPodArray( buf, island->bodies );
			b3SerPodArray( buf, island->contacts );
			b3SerPodArray( buf, island->joints );
		}
	}

	// Broad phase
	b3BroadPhase* bp = &world->broadPhase;
	for ( int t = 0; t < b3_bodyTypeCount; ++t )
	{
		b3SerTree( buf, &bp->trees[t] );
	}
	for ( int t = 0; t < b3_bodyTypeCount; ++t )
	{
		b3SerBitSet( buf, &bp->movedProxies[t] );
	}
	b3SerPodArray( buf, bp->moveArray );
	b3SerHashSet( buf, &bp->pairSet );

	// Constraint graph
	b3ConstraintGraph* graph = &world->constraintGraph;
	for ( int c = 0; c < B3_GRAPH_COLOR_COUNT; ++c )
	{
		b3SerGraphColor( buf, &graph->colors[c], c == B3_OVERFLOW_INDEX );
	}

	b3SerNames( buf, &world->names );

	return buf->size - startSize;
}

bool b3DeserializeIntoShell( const uint8_t* data, int size, b3World* world, b3RecReader* rdr )
{
	if ( data == NULL || size < (int)sizeof( b3SnapHeader ) )
	{
		return false;
	}

	// Validate header
	b3SnapHeader hdr;
	memcpy( &hdr, data, sizeof( hdr ) );
	if ( hdr.magic != B3_SNAP_MAGIC || hdr.version != B3_SNAP_VERSION )
	{
		printf( "b3DeserializeIntoShell: bad magic/version\n" );
		return false;
	}
	bool imageDouble = ( hdr.flags & B3_SNAP_FLAG_DOUBLE_PRECISION ) != 0;
#if defined( BOX3D_DOUBLE_PRECISION )
	bool buildDouble = true;
#else
	bool buildDouble = false;
#endif
	if ( imageDouble != buildDouble )
	{
		printf( "b3DeserializeIntoShell: precision mismatch\n" );
		return false;
	}
	if ( hdr.layoutHash != b3ComputeLayoutHash() )
	{
		printf( "b3DeserializeIntoShell: layout hash mismatch\n" );
		return false;
	}

	b3SnapReader readerStorage;
	b3SnapReader* r = &readerStorage;
	r->data = data;
	r->cursor = (int)sizeof( b3SnapHeader );
	r->size = size;
	r->ok = true;

	// Free existing per-object heap before overwriting
	b3FreeLiveSimElements( world );

	// 1. World scalars
	b3DesWorldConfig( r, world );

	// 2. 6 id pools; destroy the pre-created sets' pool state first
	b3DesIdPool( r, &world->bodyIdPool );
	b3DesIdPool( r, &world->shapeIdPool );
	b3DesIdPool( r, &world->contactIdPool );
	b3DesIdPool( r, &world->jointIdPool );
	b3DesIdPool( r, &world->islandIdPool );
	b3DesIdPool( r, &world->solverSetIdPool );

	// 3. Solver sets: destroy inner arrays of existing sets first
	for ( int i = 0; i < world->solverSets.count; ++i )
	{
		b3SolverSet* set = world->solverSets.data + i;
		b3Array_Destroy( set->bodySims );
		b3Array_Destroy( set->bodyStates );
		b3Array_Destroy( set->jointSims );
		b3Array_Destroy( set->contactIndices );
		b3Array_Destroy( set->islandSims );
	}

	int setCount = b3SnapR_I32( r );
	if ( r->ok && b3SnapCheckCount( r, setCount, (int)sizeof( b3SolverSet ), 6 * (int)sizeof( int ) ) == false )
	{
		r->ok = false;
	}
	if ( r->ok )
	{
		b3Array_Resize( world->solverSets, setCount );
		memset( world->solverSets.data, 0, (size_t)setCount * sizeof( b3SolverSet ) );
		for ( int i = 0; i < setCount; ++i )
		{
			b3DesSolverSet( r, world->solverSets.data + i );
		}
	}

	if ( !r->ok )
	{
		return false;
	}

	// 4. Body sparse array
	{
		int bodyCount = b3SnapR_I32( r );
		if ( r->ok && b3SnapCheckCount( r, bodyCount, (int)sizeof( b3Body ), (int)sizeof( b3Body ) ) == false )
		{
			r->ok = false;
		}
		if ( r->ok )
		{
			b3Array_Resize( world->bodies, bodyCount );
			for ( int i = 0; i < bodyCount; ++i )
			{
				b3SnapR_Bytes( r, world->bodies.data + i, sizeof( b3Body ) );
				world->bodies.data[i].userData = NULL;
			}
		}
	}

	if ( !r->ok )
	{
		return false;
	}

	// 5. Shape sparse array
	b3DesShapes( r, world, rdr );

	if ( !r->ok )
	{
		return false;
	}

	// 6. Contact sparse array
	b3DesContacts( r, world );

	if ( !r->ok )
	{
		return false;
	}

	// 7. Joint sparse array
	{
		int jointCount = b3SnapR_I32( r );
		if ( r->ok && b3SnapCheckCount( r, jointCount, (int)sizeof( b3Joint ), (int)sizeof( b3Joint ) ) == false )
		{
			r->ok = false;
		}
		if ( r->ok )
		{
			b3Array_Resize( world->joints, jointCount );
			for ( int i = 0; i < jointCount; ++i )
			{
				b3SnapR_Bytes( r, world->joints.data + i, sizeof( b3Joint ) );
				world->joints.data[i].userData = NULL;
			}
		}
	}

	// 8. Sensors
	{
		b3Array_Destroy( world->sensors );
		b3Array_Create( world->sensors );

		int sensorCount = b3SnapR_I32( r );
		if ( r->ok && b3SnapCheckCount( r, sensorCount, (int)sizeof( b3Sensor ), 4 * (int)sizeof( int ) ) == false )
		{
			r->ok = false;
		}
		if ( r->ok )
		{
			b3Array_Resize( world->sensors, sensorCount );
			memset( world->sensors.data, 0, (size_t)sensorCount * sizeof( b3Sensor ) );
		}

		for ( int i = 0; i < sensorCount && r->ok; ++i )
		{
			b3Sensor* s = world->sensors.data + i;
			s->shapeId = b3SnapR_I32( r );
			b3Array_Create( s->hits );
			b3Array_Create( s->overlaps1 );
			b3Array_Create( s->overlaps2 );
			b3DesPodArray( r, s->hits );
			b3DesPodArray( r, s->overlaps1 );
			b3DesPodArray( r, s->overlaps2 );
		}
	}

	// 9. Islands
	{
		b3Array_Destroy( world->islands );
		b3Array_Create( world->islands );

		int islandCount = b3SnapR_I32( r );
		if ( r->ok && b3SnapCheckCount( r, islandCount, (int)sizeof( b3Island ), 7 * (int)sizeof( int ) ) == false )
		{
			r->ok = false;
		}
		if ( r->ok )
		{
			b3Array_Resize( world->islands, islandCount );
			memset( world->islands.data, 0, (size_t)islandCount * sizeof( b3Island ) );
		}

		for ( int i = 0; i < islandCount && r->ok; ++i )
		{
			b3Island* island = world->islands.data + i;
			island->setIndex = b3SnapR_I32( r );
			island->localIndex = b3SnapR_I32( r );
			island->islandId = b3SnapR_I32( r );
			island->constraintRemoveCount = b3SnapR_I32( r );
			b3Array_Create( island->bodies );
			b3Array_Create( island->contacts );
			b3Array_Create( island->joints );
			b3DesPodArray( r, island->bodies );
			b3DesPodArray( r, island->contacts );
			b3DesPodArray( r, island->joints );
		}
	}

	// 10. Broad phase
	{
		b3BroadPhase* bp = &world->broadPhase;

		for ( int t = 0; t < b3_bodyTypeCount; ++t )
		{
			b3DesTree( r, &bp->trees[t] );
		}
		for ( int t = 0; t < b3_bodyTypeCount; ++t )
		{
			b3DesBitSet( r, &bp->movedProxies[t] );
		}

		b3Array_Destroy( bp->moveArray );
		b3Array_Create( bp->moveArray );
		b3DesPodArray( r, bp->moveArray );

		b3DesHashSet( r, &bp->pairSet );
		// Transient moveResults/movePairs stay at shell's NULL/0
	}

	// 11. Constraint graph
	{
		b3ConstraintGraph* graph = &world->constraintGraph;
		for ( int c = 0; c < B3_GRAPH_COLOR_COUNT; ++c )
		{
			b3DesGraphColor( r, &graph->colors[c], c == B3_OVERFLOW_INDEX );
		}
	}

	b3DesNames( r, &world->names );

	return r->ok;
}
