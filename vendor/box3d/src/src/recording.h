// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include "box3d/id.h"
#include "box3d/math_functions.h"
#include "box3d/types.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// FNV-1a 64-bit constants
#define B3_SNAP_FNV_INIT 14695981039346656037ull
#define B3_SNAP_FNV_PRIME 1099511628211ull

// Mix a world position at full width so the determinism gate validates past float precision
// when the body is far from the origin.
static inline uint64_t b3FnvMixPosition( uint64_t hash, b3Pos p )
{
#if defined( BOX3D_DOUBLE_PRECISION )
	uint64_t bx, by, bz;
	memcpy( &bx, &p.x, 8 );
	memcpy( &by, &p.y, 8 );
	memcpy( &bz, &p.z, 8 );
#else
	uint32_t fx, fy, fz;
	memcpy( &fx, &p.x, 4 );
	memcpy( &fy, &p.y, 4 );
	memcpy( &fz, &p.z, 4 );
	uint64_t bx = fx, by = fy, bz = fz;
#endif
	hash = ( hash ^ bx ) * B3_SNAP_FNV_PRIME;
	hash = ( hash ^ by ) * B3_SNAP_FNV_PRIME;
	hash = ( hash ^ bz ) * B3_SNAP_FNV_PRIME;
	return hash;
}

typedef struct b3World b3World;

// Magic 'B3RC' in little-endian: bytes B(0x42) 3(0x33) R(0x52) C(0x43)
#define B3_REC_MAGIC 0x43523342u

// Major recording version is bumped when writers change.
// Major version 4 added b3ShapeDef::enableSpeculativeContact
#define B3_REC_VERSION_MAJOR 4

// Minor tracks op-stream additions that keep the 48 byte header shape.
// Minor version 3 added name cache.
#define B3_REC_VERSION_MINOR 3

// File header, fixed 48 bytes, little-endian. Contains the registry locator so the player
// can load geometry before replaying any ops.
typedef struct b3RecHeader
{
	uint32_t magic;			   // 'B3RC' = 0x43523342
	uint16_t versionMajor;	   // B3_REC_VERSION_MAJOR
	uint16_t versionMinor;	   // B3_REC_VERSION_MINOR
	uint8_t pointerWidth;	   // sizeof(void*), gates POD-def struct layout
	uint8_t bigEndian;		   // 0 on all supported targets
	uint8_t validationEnabled; // 1 if built with BOX3D_VALIDATE, diagnostic only
	uint8_t reserved;
	float lengthScale; // b3GetLengthUnitsPerMeter()
	uint32_t reserved2;
	uint32_t reserved3;			// explicit pad so the 64-bit fields align with no implicit gap
	uint64_t snapshotSize;		// bytes of snapshot blob after the header (0 in Phase 1)
	uint64_t registryOffset;	// absolute offset to trailing registry block, backpatched at stop
	uint64_t registryByteCount; // size of the registry block
} b3RecHeader;

_Static_assert( sizeof( b3RecHeader ) == 48, "recording header must be 48 bytes" );

// Growable append-only byte buffer. Doubles on demand. countOnly mode tallies size without
// allocating, used to size a buffer cheaply before a second filling pass.
typedef struct b3RecBuffer
{
	uint8_t* data;
	int capacity;
	int size;
	bool countOnly;
} b3RecBuffer;

// Geometry kinds for the trailing registry section
typedef enum b3GeometryKind
{
	b3_geometryHull,
	b3_geometryMesh,
	b3_geometryHeightField,
	b3_geometryCompound,
} b3GeometryKind;

// One entry per unique geometry blob. id == index in the entries array.
// hashNext chains entries that share a content hash so dedup stays exact under a hash collision,
// which the keyframe registry depends on to never grow during capture. B3_NULL_INDEX ends the chain.
typedef struct b3GeometryEntry
{
	uint64_t contentHash;
	uint32_t id;
	b3GeometryKind kind;
	int byteCount;
	uint8_t* bytes;
	int hashNext;
} b3GeometryEntry;

// Growable array of geometry entries. Ids are array indices, so the array is serialized in order.
// dedupMap maps content hash to entry id for O(1) dedup; it is opaque here and owned by recording.c.
typedef struct b3GeometryRegistry
{
	b3GeometryEntry* entries;
	int count;
	int capacity;
	void* dedupMap;
} b3GeometryRegistry;

// Limit the maximum query name length to make recording simpler. Query names longer than this
// probably indicate a bug in user code.
#define B3_MAX_QUERY_NAME_LENGTH 64

// Query tag from b3QueryFilter.
// Stored once per key in the trailing block so a tagged query carries only the 8 byte key on the wire.
// Shared by the recorder (accumulate) and the player (load).
typedef struct b3RecTag
{
	// hash of (id, queryName)
	uint64_t key;				  
	uint64_t id;
	char queryName[B3_MAX_QUERY_NAME_LENGTH + 1];
} b3RecTag;

// User-owned recording buffer. The world appends into it while active; the host saves and
// destroys it. Opaque across the public API.
typedef struct b3Recording
{
	b3RecBuffer buffer;
	int recordStart; // offset of the 3-byte size field for u24 backpatch
	b3Mutex* lock;	 // serializes record writes from concurrent threads
	b3GeometryRegistry registry;

	// Interned query tags accumulated during capture, written to the tail of the registry block at stop.
	// tagMap maps a tag key to its index for O(1) dedup.
	b3RecTag* tags;
	int tagCount;
	int tagCapacity;
	void* tagMap;

	// Union of world bounds over every recorded step, written at stop.
	b3AABB accumulatedBounds;
	bool haveBounds;
} b3Recording;

// C type aliases per TAG, used in the X-macro codegen arg structs
typedef bool b3RecCType_BOOL;
typedef int32_t b3RecCType_I32;
typedef uint8_t b3RecCType_U8;
typedef uint16_t b3RecCType_U16;
typedef uint32_t b3RecCType_U32;
typedef uint64_t b3RecCType_U64;
typedef float b3RecCType_F32;
typedef double b3RecCType_F64;
typedef b3Vec3 b3RecCType_VEC3;
typedef b3Quat b3RecCType_QUAT;
typedef b3Transform b3RecCType_TRANSFORM;
typedef b3Pos b3RecCType_POSITION;
typedef b3WorldTransform b3RecCType_WORLDXF;
typedef b3Matrix3 b3RecCType_MATRIX3;
typedef b3AABB b3RecCType_AABB;
typedef b3Sphere b3RecCType_SPHERE;
typedef b3Capsule b3RecCType_CAPSULE;
typedef b3QueryFilter b3RecCType_QUERYFILTER;
typedef b3ShapeProxy b3RecCType_SHAPEPROXY;
// Geometry reference: a plain u32 id into the trailing registry
typedef uint32_t b3RecCType_GEOMID;
typedef b3Filter b3RecCType_FILTER;
typedef b3SurfaceMaterial b3RecCType_MATERIAL;
typedef b3MassData b3RecCType_MASSDATA;
typedef b3MotionLocks b3RecCType_LOCKS;
typedef const char* b3RecCType_STR;
typedef b3WorldId b3RecCType_WORLDID;
typedef b3BodyId b3RecCType_BODYID;
typedef b3ShapeId b3RecCType_SHAPEID;
typedef b3JointId b3RecCType_JOINTID;
typedef b3BodyDef b3RecCType_BODYDEF;
typedef b3ShapeDef b3RecCType_SHAPEDEF;
typedef b3ExplosionDef b3RecCType_EXPLOSIONDEF;
typedef b3ParallelJointDef b3RecCType_PARALLELJOINTDEF;
typedef b3DistanceJointDef b3RecCType_DISTANCEJOINTDEF;
typedef b3FilterJointDef b3RecCType_FILTERJOINTDEF;
typedef b3MotorJointDef b3RecCType_MOTORJOINTDEF;
typedef b3PrismaticJointDef b3RecCType_PRISMATICJOINTDEF;
typedef b3RevoluteJointDef b3RecCType_REVOLUTEJOINTDEF;
typedef b3SphericalJointDef b3RecCType_SPHERICALJOINTDEF;
typedef b3WeldJointDef b3RecCType_WELDJOINTDEF;
typedef b3WheelJointDef b3RecCType_WHEELJOINTDEF;

// Codegen pass 1a: arg structs. Generated here so call sites (body.c, shape.c, etc.) can see them.
#define ARG( TAG, field ) b3RecCType_##TAG field;
#define B3_REC_OP( op, Name, RET, ... )                                                                                          \
	typedef struct                                                                                                               \
	{                                                                                                                            \
		__VA_ARGS__                                                                                                              \
	} b3RecArgs_##Name;
#include "recording_ops.inl"
#undef B3_REC_OP
#undef ARG

// Opcode constants generated from the manifest, so call sites name an op instead of a raw byte and
// can't drift from the manifest if an op is renumbered.
enum
{
#define B3_REC_OP( op, Name, RET, ... ) b3_recOp##Name = ( op ),
#include "recording_ops.inl"
#undef B3_REC_OP
};

// Low-level buffer helpers
void b3RecBufAppend( b3RecBuffer* buf, const void* data, int size );
void b3RecBufFree( b3RecBuffer* buf );

// Write primitives
void b3RecW_U8( b3RecBuffer* buf, uint8_t v );
void b3RecW_U16( b3RecBuffer* buf, uint16_t v );
void b3RecW_U32( b3RecBuffer* buf, uint32_t v );
void b3RecW_U64( b3RecBuffer* buf, uint64_t v );
void b3RecW_I32( b3RecBuffer* buf, int32_t v );
void b3RecW_F32( b3RecBuffer* buf, float v );
void b3RecW_F64( b3RecBuffer* buf, double v );
void b3RecW_BOOL( b3RecBuffer* buf, bool v );
void b3RecW_VEC3( b3RecBuffer* buf, b3Vec3 v );
void b3RecW_QUAT( b3RecBuffer* buf, b3Quat v );
void b3RecW_TRANSFORM( b3RecBuffer* buf, b3Transform v );
// World position: doubles in large-world mode, floats otherwise (wire-identical to VEC3 in float build)
void b3RecW_POSITION( b3RecBuffer* buf, b3Pos v );
void b3RecW_WORLDXF( b3RecBuffer* buf, b3WorldTransform v );
void b3RecW_MATRIX3( b3RecBuffer* buf, b3Matrix3 v );
void b3RecW_AABB( b3RecBuffer* buf, b3AABB v );
void b3RecW_QUERYFILTER( b3RecBuffer* buf, b3QueryFilter v );
void b3RecW_SHAPEPROXY( b3RecBuffer* buf, b3ShapeProxy v );
void b3RecW_TREESTATS( b3RecBuffer* buf, b3TreeStats v );
void b3RecW_RAYRESULT( b3RecBuffer* buf, b3RayResult v );
void b3RecW_PLANERESULT( b3RecBuffer* buf, b3PlaneResult v );
void b3RecW_WORLDID( b3RecBuffer* buf, b3WorldId v );
void b3RecW_BODYID( b3RecBuffer* buf, b3BodyId v );
void b3RecW_SHAPEID( b3RecBuffer* buf, b3ShapeId v );
void b3RecW_JOINTID( b3RecBuffer* buf, b3JointId v );
void b3RecW_SPHERE( b3RecBuffer* buf, b3Sphere v );
void b3RecW_CAPSULE( b3RecBuffer* buf, b3Capsule v );
void b3RecW_GEOMID( b3RecBuffer* buf, uint32_t v );
void b3RecW_FILTER( b3RecBuffer* buf, b3Filter v );
void b3RecW_MATERIAL( b3RecBuffer* buf, b3SurfaceMaterial v );
void b3RecW_MASSDATA( b3RecBuffer* buf, b3MassData v );
void b3RecW_LOCKS( b3RecBuffer* buf, b3MotionLocks v );
void b3RecW_EXPLOSIONDEF( b3RecBuffer* buf, b3ExplosionDef v );
void b3RecW_BODYDEF( b3RecBuffer* buf, b3BodyDef v );
void b3RecW_SHAPEDEF( b3RecBuffer* buf, b3ShapeDef v );
void b3RecW_PARALLELJOINTDEF( b3RecBuffer* buf, b3ParallelJointDef v );
void b3RecW_DISTANCEJOINTDEF( b3RecBuffer* buf, b3DistanceJointDef v );
void b3RecW_FILTERJOINTDEF( b3RecBuffer* buf, b3FilterJointDef v );
void b3RecW_MOTORJOINTDEF( b3RecBuffer* buf, b3MotorJointDef v );
void b3RecW_PRISMATICJOINTDEF( b3RecBuffer* buf, b3PrismaticJointDef v );
void b3RecW_REVOLUTEJOINTDEF( b3RecBuffer* buf, b3RevoluteJointDef v );
void b3RecW_SPHERICALJOINTDEF( b3RecBuffer* buf, b3SphericalJointDef v );
void b3RecW_WELDJOINTDEF( b3RecBuffer* buf, b3WeldJointDef v );
void b3RecW_WHEELJOINTDEF( b3RecBuffer* buf, b3WheelJointDef v );

// Record framing
void b3RecBeginRecord( b3Recording* rec, uint8_t opcode );
void b3RecEndRecord( b3Recording* rec );

// Per-op arg writers (no framing) and full writers (framing + args), generated from the manifest.
#define B3_REC_OP( op, Name, RET, ... )                                                                                          \
	void b3RecWriteArgs_##Name( b3Recording* rec, const b3RecArgs_##Name* a );                                                   \
	void b3RecWrite_##Name( b3Recording* rec, const b3RecArgs_##Name* a );
#include "recording_ops.inl"
#undef B3_REC_OP

// Create ops: declare writers that also append the returned id inside the record.
#define B3_REC_RETDECL_RET_NONE( Name )
#define B3_REC_RETDECL_RET_BODYID( Name ) void b3RecWriteRet_##Name( b3Recording* rec, const b3RecArgs_##Name* a, b3BodyId id );
#define B3_REC_RETDECL_RET_SHAPEID( Name ) void b3RecWriteRet_##Name( b3Recording* rec, const b3RecArgs_##Name* a, b3ShapeId id );
#define B3_REC_RETDECL_RET_JOINTID( Name ) void b3RecWriteRet_##Name( b3Recording* rec, const b3RecArgs_##Name* a, b3JointId id );
#define B3_REC_OP( op, Name, RET, ... ) B3_REC_RETDECL_##RET( Name )
#include "recording_ops.inl"
#undef B3_REC_OP
#undef B3_REC_RETDECL_RET_NONE
#undef B3_REC_RETDECL_RET_BODYID
#undef B3_REC_RETDECL_RET_SHAPEID
#undef B3_REC_RETDECL_RET_JOINTID

// Record a void op. The branch is free when recording is off.
#define B3_REC( world, Name, ... )                                                                                               \
	do                                                                                                                           \
	{                                                                                                                            \
		if ( ( world )->recording != NULL )                                                                                      \
		{                                                                                                                        \
			b3RecArgs_##Name recArgs = { __VA_ARGS__ };                                                                          \
			b3RecWrite_##Name( ( world )->recording, &recArgs );                                                                 \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

// Record a create op and its returned id in one framed record. Place after the real create call.
#define B3_REC_CREATE( world, Name, id, ... )                                                                                    \
	do                                                                                                                           \
	{                                                                                                                            \
		if ( ( world )->recording != NULL )                                                                                      \
		{                                                                                                                        \
			b3RecArgs_##Name recCreateArgs = { __VA_ARGS__ };                                                                    \
			b3RecWriteRet_##Name( ( world )->recording, &recCreateArgs, id );                                                    \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

// Patch helpers for the query hit-count backfill
int b3RecReserveU32( b3RecBuffer* buf );
void b3RecPatchU32( b3RecBuffer* buf, int offset, uint32_t v );

// Commit a finished query record under the lock. The payload buffer stays owned by the caller.
void b3RecCommitRecord( b3Recording* rec, uint8_t opcode, const uint8_t* payload, int payloadSize );

// Per-query writer context: holds the user fcn+ctx, the local payload buffer, and the hit counter
typedef struct b3RecQueryWriter
{
	union
	{
		b3OverlapResultFcn* overlapFcn;
		b3CastResultFcn* castFcn;
		b3PlaneResultFcn* planeFcn;
		b3MoverFilterFcn* moverFilterFcn;
	} userFcn;
	void* userContext;
	b3RecBuffer buf; // per-call local payload, heap-backed
	int countOffset; // offset of the reserved u32 hit-count slot
	uint32_t hitCount;
	uint64_t tagId;		 // caller query id, 0 = untagged. Emitted as a QueryTag before the record.
	const char* tagName; // caller query name, interned by id. NULL = none.
} b3RecQueryWriter;

void b3RecQueryBegin( b3RecQueryWriter* w, void* context, uint64_t tagId, const char* tagName );
void b3RecQueryCommit( b3Recording* rec, uint8_t opcode, b3RecQueryWriter* w );

// Recording trampolines: replace the user fcn so hits are captured before dispatch. The overlap
// trampoline doubles for the mover filter, which has the same bool(shapeId, ctx) shape.
bool b3RecOverlapTrampoline( b3ShapeId id, void* ctx );
float b3RecCastTrampoline( b3ShapeId id, b3Pos point, b3Vec3 normal, float fraction, uint64_t userMaterialId, int triangleIndex,
						   int childIndex, void* ctx );
bool b3RecPlaneTrampoline( b3ShapeId id, const b3PlaneResult* planes, int planeCount, void* ctx );

// Geometry registry
uint32_t b3InternGeometry( b3GeometryRegistry* reg, b3GeometryKind kind, uint64_t contentHash, uint8_t* bytes, int byteCount );
// Append an entry unconditionally and return its id, which equals its array index. Unlike
// b3InternGeometry it never deduplicates, so the keyframe seed can mirror slots 1:1 even when an
// already-recorded file carries byte-identical duplicate slots (a hash collision wrote them apart).
uint32_t b3AppendGeometry( b3GeometryRegistry* reg, b3GeometryKind kind, uint64_t contentHash, uint8_t* bytes, int byteCount );
void b3FreeRegistry( b3GeometryRegistry* reg );
void b3RecWriteRegistry( b3Recording* rec );

// Hash a query (id, name) pair into the stable key the viewer tracks the query by. Never returns 0,
// so the key doubles as a tagged/untagged flag.
uint64_t b3HashQueryTag( uint64_t id, const char* name );

// Record a key->(id, name) mapping once, deduped by key (a repeated key keeps its first id/name).
void b3RecInternTag( b3Recording* rec, uint64_t key, uint64_t id, const char* name );

// Intern each large geometry kind and return a stable u32 id for use in create ops.
// Caller does NOT free bytes; b3InternGeometry takes ownership (frees on duplicate).
uint32_t b3RecInternHull( b3Recording* rec, const b3HullData* hull );
uint32_t b3RecInternMesh( b3Recording* rec, const b3MeshData* mesh );
uint32_t b3RecInternHeightField( b3Recording* rec, const b3HeightFieldData* hf );
uint32_t b3RecInternCompound( b3Recording* rec, const b3CompoundData* compound );

uint64_t b3Hash64Blob( const uint8_t* bytes, int n );

// Lifecycle engine-side hooks
void b3StartRecordingIntoBuffer( b3World* world, b3Recording* recording );
void b3StopRecordingInternal( b3World* world );

// Fold one step's world bounds into the running union.
void b3RecAccumulateBounds( b3Recording* rec, b3AABB bounds );

// Deterministic hash over all body transforms and velocities.
// Called by both recorder and replayer to verify simulation reproduces exactly.
uint64_t b3HashWorldState( b3World* world );
