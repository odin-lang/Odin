// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "recording.h"

#include <stdbool.h>
#include <stdint.h>

typedef struct b3RecPlayer b3RecPlayer;

// A single recorded callback hit, used both as reader scratch during a query replay and as the
// per-frame draw store. For collide-mover, one hit is one plane, with planeCount and userReturnB
// replicated across a shape's planes so the replay walker can re-group and compare per shape.
typedef struct b3RecRecordedHit
{
	b3ShapeId id;
	b3Pos point;
	b3Vec3 normal;
	float fraction;
	uint64_t userMaterialId;
	int triangleIndex;
	int childIndex;
	b3PlaneResult plane; // collide-mover: this plane
	int planeCount;		 // collide-mover: planes in this hit's shape group (replicated)
	float userReturnF;	 // cast queries
	bool userReturnB;	 // overlap / collide-mover (per shape, replicated)
} b3RecRecordedHit;

// Recorded query kind, matching the public b3RecQueryType order.
typedef enum b3RecQueryKind
{
	B3_RECQ_OVERLAP_AABB,
	B3_RECQ_OVERLAP_SHAPE,
	B3_RECQ_CAST_RAY,
	B3_RECQ_CAST_SHAPE,
	B3_RECQ_CAST_RAY_CLOSEST,
	B3_RECQ_CAST_MOVER,
	B3_RECQ_COLLIDE_MOVER,
} b3RecQueryKind;

// Per-frame draw record for one query call. Self-contained (no aliased pointers) so the player's
// frameQueries array can grow with a plain memcpy. Geometry is origin relative except the overlap
// AABB, which is world space in 3D.
typedef struct b3RecDrawQuery
{
	int kind;
	uint64_t key; // identity key (hash of caller id+name), 0 = untagged
	b3QueryFilter filter;
	b3AABB aabb;								  // world-space bounds of the query, swept for casts
	b3Vec3 proxyPoints[B3_MAX_SHAPE_CAST_POINTS]; // overlap/cast shape proxy, origin relative
	int proxyCount;
	float proxyRadius;
	b3Capsule mover; // cast/collide mover, origin relative
	b3Pos origin;
	b3Vec3 translation;
	float castFraction;	   // cast-mover result fraction
	b3RayResult rayResult; // cast-ray-closest result
	b3ShapeId shape;
	int hitStart; // first hit in the player's frameHits store
	int hitCount;
} b3RecDrawQuery;

// One slot in the preloaded geometry registry. Loaded from the trailing block before any
// ops run; live pointer built lazily on first shape create that references the id.
typedef struct b3RegistrySlot
{
	b3GeometryKind kind;
	int byteCount;
	uint8_t* bytes; // raw bytes from the file (always freed at teardown)
	void* live;		// reconstructed live object, freed after b3DestroyWorld
} b3RegistrySlot;

// This is used to simplify the scratch buffer lifetime. Names longer than this probably
// indicate a bug.
#define B3_MAX_NAME_LENGTH 256

// Reader state threaded through the replay loop and all dispatch functions
typedef struct b3RecReader
{
	const uint8_t* data;
	int size;
	int cursor;
	b3WorldId replayWorldId;
	bool ok;	   // false on read overrun or id mismatch, fatal stop
	bool diverged; // a StateHash failed, non-fatal

	// Player that owns this reader, or NULL during a headless b3ValidateReplay. Body
	// create/destroy and the bounds record fold back into it for the outliner and camera framing.
	b3RecPlayer* owner;

	// Scratch for per-triangle materials in shape defs (grown on demand, freed at teardown)
	b3SurfaceMaterial* matScratch;
	int matScratchCap;

	// Scratch for string reads. Used by b3RecR_STR to pass names to b3BodyDef and b3ShapeDef.
	char stringBuffers[4][B3_MAX_NAME_LENGTH + 1];
	int nextString;

	// Preloaded geometry registry
	b3RegistrySlot* slots;
	int slotCount;

	// Preloaded query-tag table (key -> id, name), loaded with the registry. Resolves the caller id and
	// label for the viewer. tagMap maps a key to its tag index for O(1) lookup; opaque, owned by the player.
	b3RecTag* tags;
	int tagCount;	 // tags that loaded; a truncated tail loads fewer
	int tagCapacity; // tags allocated, used to free the array
	void* tagMap;

	// Key from the QueryTag op preceding the next query, consumed by the next stash. 0 = untagged.
	uint64_t pendingQueryKey;

	// Scratch for recorded query hits; grown on demand, freed with the player.
	b3RecRecordedHit* hits;
	int hitCap;

	// Scratch for a shape-proxy point cloud read from the stream. b3ShapeProxy holds the points
	// behind a pointer, so a decoded proxy borrows this until the next proxy read or teardown.
	b3Vec3* proxyScratch;
	int proxyScratchCap;
} b3RecReader;

// Stored snapshot for fast backward seek.
typedef struct b3RecKeyframe
{
	uint8_t* image; // serialized world image at the end of this frame
	int imageSize;
	int imageCapacity; // allocation size (may exceed imageSize)
	int frame;		   // frame index this restores to
	int cursor;		   // op-stream cursor for the frame AFTER this one
	int divergeFrame;  // divergeFrame state at capture
	bool diverged;	   // rdr.diverged state at capture

	// Outliner body list as it stood at this frame, restored verbatim so ordinals are stable.
	b3BodyId* bodyIds;
	int bodyIdCount;
} b3RecKeyframe;

typedef struct b3RecPlayer
{
	uint8_t* data; // owned copy of recording bytes
	int size;
	int headerEnd;	 // first byte of op stream (past header + snapshot blob)
	int registryEnd; // end of op stream = start of registry block (or size)
	float lengthScale;
	float previousLengthScale;
	int frame;
	int frameCount;
	float recordedDt;
	int recordedSubStepCount;
	int recordedWorkerCount; // worker count requested for the replay world
	b3AABB bounds;			 // accumulated world bounds, decoded from the trailing record
	bool atEnd;
	// Indicates all ops for the step have been consumed up to the world step op. The next sub-step
	// will clear this and perform the world step.
	bool atPreStep;
	int divergeFrame; // first frame that diverged, -1 until then

	// Outliner body list, indexed by creation ordinal. Holes (null ids) mark destroyed bodies so
	// later ordinals never shift. Snapshotted into each keyframe and the frame-0 copy, not rebuilt
	// from the world, so a stored selection survives backward seeks.
	b3BodyId* bodyIds;
	int bodyIdCount;
	int bodyIdCap;
	b3BodyId* frame0BodyIds;
	int frame0BodyIdCount;

	// Per-frame query store, reset at the top of each StepFrame and filled by the query dispatchers.
	// Drawn by b3RecPlayer_DrawFrameQueries and inspected via the public GetFrameQuery API.
	b3RecDrawQuery* frameQueries;
	int frameQueryCount;
	int frameQueryCap;
	b3RecRecordedHit* frameHits;
	int frameHitCount;
	int frameHitCap;

	// Host debug-shape callbacks applied to every world the player creates. The 3D
	// sample renderer builds GPU meshes here, so a replay world without them draws
	// nothing. Set once via b3RecPlayer_SetDebugShapeCallbacks; persisted so a world
	// rebuilt under new callbacks keeps drawing.
	b3CreateDebugShapeCallback* createDebugShape;
	b3DestroyDebugShapeCallback* destroyDebugShape;
	void* debugShapeContext;

	b3RecReader rdr;

	// Frame-0 restore image, points into the owned data copy. Restart and backward seek
	// deserialize this in place so the replay world id stays stable.
	const uint8_t* frame0Image;
	int frame0Size;

	// Keyframe ring
	b3RecKeyframe* keyframes;
	int keyframeCount;
	int keyframeCapacity;
	size_t keyframeBudget;
	size_t keyframeBytes;
	int keyframeMinInterval;
	int keyframeInterval;
	int lastKeyframeFrame;

	// Pre-populated recording used by b3SerializeWorld during keyframe capture.
	// Its registry mirrors rdr.slots so geometry ids stay stable.
	b3Recording* keyframeRec;
} b3RecPlayer;

// Read primitives
uint8_t b3RecR_U8( b3RecReader* rdr );
uint16_t b3RecR_U16( b3RecReader* rdr );
uint32_t b3RecR_U24( b3RecReader* rdr );
uint32_t b3RecR_U32( b3RecReader* rdr );
uint64_t b3RecR_U64( b3RecReader* rdr );
int32_t b3RecR_I32( b3RecReader* rdr );
float b3RecR_F32( b3RecReader* rdr );
double b3RecR_F64( b3RecReader* rdr );
bool b3RecR_BOOL( b3RecReader* rdr );
b3Vec3 b3RecR_VEC3( b3RecReader* rdr );
b3Quat b3RecR_QUAT( b3RecReader* rdr );
b3Transform b3RecR_TRANSFORM( b3RecReader* rdr );
b3Pos b3RecR_POSITION( b3RecReader* rdr );
b3WorldTransform b3RecR_WORLDXF( b3RecReader* rdr );
b3Matrix3 b3RecR_MATRIX3( b3RecReader* rdr );
b3AABB b3RecR_AABB( b3RecReader* rdr );
b3WorldId b3RecR_WORLDID( b3RecReader* rdr );
b3BodyId b3RecR_BODYID( b3RecReader* rdr );
b3ShapeId b3RecR_SHAPEID( b3RecReader* rdr );
b3JointId b3RecR_JOINTID( b3RecReader* rdr );
b3Sphere b3RecR_SPHERE( b3RecReader* rdr );
b3Capsule b3RecR_CAPSULE( b3RecReader* rdr );
uint32_t b3RecR_GEOMID( b3RecReader* rdr );
b3Filter b3RecR_FILTER( b3RecReader* rdr );
b3SurfaceMaterial b3RecR_MATERIAL( b3RecReader* rdr );
b3MassData b3RecR_MASSDATA( b3RecReader* rdr );
b3MotionLocks b3RecR_LOCKS( b3RecReader* rdr );
const char* b3RecR_STR( b3RecReader* rdr );
b3ExplosionDef b3RecR_EXPLOSIONDEF( b3RecReader* rdr );
b3BodyDef b3RecR_BODYDEF( b3RecReader* rdr );
b3ShapeDef b3RecR_SHAPEDEF( b3RecReader* rdr );
b3ParallelJointDef b3RecR_PARALLELJOINTDEF( b3RecReader* rdr );
b3DistanceJointDef b3RecR_DISTANCEJOINTDEF( b3RecReader* rdr );
b3FilterJointDef b3RecR_FILTERJOINTDEF( b3RecReader* rdr );
b3MotorJointDef b3RecR_MOTORJOINTDEF( b3RecReader* rdr );
b3PrismaticJointDef b3RecR_PRISMATICJOINTDEF( b3RecReader* rdr );
b3RevoluteJointDef b3RecR_REVOLUTEJOINTDEF( b3RecReader* rdr );
b3SphericalJointDef b3RecR_SPHERICALJOINTDEF( b3RecReader* rdr );
b3WeldJointDef b3RecR_WELDJOINTDEF( b3RecReader* rdr );
b3WheelJointDef b3RecR_WHEELJOINTDEF( b3RecReader* rdr );
b3QueryFilter b3RecR_QUERYFILTER( b3RecReader* rdr );
b3ShapeProxy b3RecR_SHAPEPROXY( b3RecReader* rdr );
b3TreeStats b3RecR_TREESTATS( b3RecReader* rdr );
b3RayResult b3RecR_RAYRESULT( b3RecReader* rdr );
b3PlaneResult b3RecR_PLANERESULT( b3RecReader* rdr );

// Grow the reader's hit scratch to at least n entries, preserving contents. n is bounded by the
// file size since every recorded hit consumes at least one byte.
void b3RecEnsureHits( b3RecReader* rdr, int n );
