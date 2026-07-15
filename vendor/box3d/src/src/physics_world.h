// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "arena_allocator.h"
#include "bitset.h"
#include "block_allocator.h"
#include "broad_phase.h"
#include "constraint_graph.h"
#include "id_pool.h"
#include "name_cache.h"

#include "box3d/types.h"

#define B3_DEBUG_POINT_CAPACITY 64
#define B3_DEBUG_LINE_CAPACITY 64

typedef struct b3Body b3Body;
typedef struct b3Recording b3Recording;
typedef struct b3Contact b3Contact;
typedef struct b3Island b3Island;
typedef struct b3Joint b3Joint;
typedef struct b3Sensor b3Sensor;
typedef struct b3SensorTaskContext b3SensorTaskContext;
typedef struct b3SensorHit b3SensorHit;
typedef struct b3Shape b3Shape;
typedef struct b3SolverSet b3SolverSet;

b3DeclareArray( b3BlockAllocator );
b3DeclareArray( b3Body );
b3DeclareArray( b3SolverSet );
b3DeclareArray( b3Joint );
b3DeclareArray( b3Contact );
b3DeclareArray( b3Island );
b3DeclareArray( b3Shape );
b3DeclareArray( b3Sensor );
b3DeclareArray( b3SensorTaskContext );
b3DeclareArray( b3SensorHit );
b3DeclareArray( b3BodyMoveEvent );
b3DeclareArray( b3SensorBeginTouchEvent );
b3DeclareArray( b3ContactBeginTouchEvent );
b3DeclareArray( b3SensorEndTouchEvent );
b3DeclareArray( b3ContactEndTouchEvent );
b3DeclareArray( b3ContactHitEvent );
b3DeclareArray( b3JointEvent );

enum b3SetType
{
	b3_staticSet = 0,
	b3_disabledSet = 1,
	b3_awakeSet = 2,
	b3_firstSleepingSet = 3,
};

typedef struct b3DebugPoint
{
	b3Pos p;
	int label;
	float value;
	b3HexColor color;
} b3DebugPoint;

typedef struct b3DebugLine
{
	b3Pos p1, p2;
	int label;
	b3HexColor color;
} b3DebugLine;

// Per thread task storage
typedef struct b3TaskContext
{
	b3Arena arena;

	// Collect per thread sensor continuous hit events.
	b3Array( b3SensorHit ) sensorHits;

	// These bits align with the b3ConstraintGraph::contactBlocks and signal a change in contact status
	b3BitSet contactStateBitSet;

	// These bits align with the joint id capacity and signal a change in contact status
	b3BitSet jointStateBitSet;

	// These bits align with the contact id capacity and signal a hit event.
	b3BitSet hitEventBitSet;

	// Fast-path flag: true when this worker set at least one bit in hitEventBitSet this step.
	bool hasHitEvents;

	// Used to track bodies with shapes that have enlarged AABBs. This avoids having a bit array
	// that is very large when there are many static shapes.
	b3BitSet enlargedSimBitSet;

	// Used to put islands to sleep
	b3BitSet awakeIslandBitSet;

	// Per worker split island candidate
	float splitSleepTime;
	int splitIslandId;

	// Profiling
	int satCallCount;
	int satCacheHitCount;
	int distanceIterations;
	int pushBackIterations;
	int rootIterations;

	// Number of contacts recycled this step (collide pass).
	int recycledContactCount;

	b3DebugPoint points[B3_DEBUG_POINT_CAPACITY];
	int pointCount;

	b3DebugLine lines[B3_DEBUG_LINE_CAPACITY];
	int lineCount;

	int manifoldCounts[B3_CONTACT_MANIFOLD_COUNT_BUCKETS];
	// Prevent false sharing
	char cacheLine[64];
} b3TaskContext;

b3DeclareArray( b3TaskContext );

// The world struct manages all physics entities, dynamic simulation,  and asynchronous queries.
// The world also contains efficient memory management facilities.
typedef struct b3World
{
	b3Stack stack;
	b3BroadPhase broadPhase;
	b3ConstraintGraph constraintGraph;

	// Manifold allocators have one allocator for each manifold count.
	b3Array( b3BlockAllocator ) manifoldAllocators;
	b3Mutex* manifoldAllocatorMutex;

	// The body id pool is used to allocate and recycle body ids. Body ids
	// provide a stable identifier for users, but incur caches misses when used
	// to access body data. Aligns with b3Body.
	b3IdPool bodyIdPool;

	// This is a sparse array that maps body ids to the body data
	// stored in solver sets. As sims move within a set or across set.
	// Indices come from id pool.
	b3Array( b3Body ) bodies;

	// Provides free list for solver sets.
	b3IdPool solverSetIdPool;

	// Solvers sets allow sims to be stored in contiguous arrays. The first
	// set is all static sims. The second set is active sims. The third set is disabled
	// sims. The remaining sets are sleeping islands.
	b3Array( b3SolverSet ) solverSets;

	// Used to create stable ids for joints
	b3IdPool jointIdPool;

	// This is a sparse array that maps joint ids to the joint data stored in the constraint graph
	// or in the solver sets.
	b3Array( b3Joint ) joints;

	// Used to create stable ids for contacts
	b3IdPool contactIdPool;

	// This is a sparse array that maps contact ids to the contact data stored in the constraint graph
	// or in the solver sets.
	b3Array( b3Contact ) contacts;

	// Used to create stable ids for islands
	b3IdPool islandIdPool;

	// This is a sparse array that maps island ids to the island data stored in the solver sets.
	b3Array( b3Island ) islands;

	b3IdPool shapeIdPool;

	// These are sparse arrays that point into the pools above
	b3Array( b3Shape ) shapes;

	// Reference counted store of shared hull data keyed by content. Shapes hold a
	// pointer to the owned copy here. Opaque to avoid leaking the verstable map
	// type into this header.
	void* hullDatabase;

	// Name cache for shape and body names. This works with recording.
	b3NameCache names;

	// This is a dense array of sensor data.
	b3Array( b3Sensor ) sensors;

	// Per thread storage
	b3Array( b3TaskContext ) taskContexts;
	b3Array( b3SensorTaskContext ) sensorTaskContexts;

	b3Array( b3BodyMoveEvent ) bodyMoveEvents;
	b3Array( b3SensorBeginTouchEvent ) sensorBeginEvents;
	b3Array( b3ContactBeginTouchEvent ) contactBeginEvents;

	// End events are double buffered so that the user doesn't need to flush events
	b3Array( b3SensorEndTouchEvent ) sensorEndEvents[2];
	b3Array( b3ContactEndTouchEvent ) contactEndEvents[2];
	int endEventArrayIndex;

	b3Array( b3ContactHitEvent ) contactHitEvents;
	b3Array( b3JointEvent ) jointEvents;

	// Used to track debug draw
	b3BitSet debugBodySet;
	b3BitSet debugJointSet;
	b3BitSet debugContactSet;
	b3BitSet debugIslandSet;
	b3CreateDebugShapeCallback* createDebugShape;
	b3DestroyDebugShapeCallback* destroyDebugShape;
	void* userDebugShapeContext;

	// Id that is incremented every time step
	uint64_t stepIndex;

	// Identify islands for splitting as follows:
	// - I want to split islands so smaller islands can sleep
	// - when a body comes to rest and its sleep timer trips, I can look at the island and flag it for splitting
	//   if it has removed constraints
	// - islands that have removed constraints must be put split first because I don't want to wake bodies incorrectly
	// - otherwise I can use the awake islands that have bodies wanting to sleep as the splitting candidates
	// - if no bodies want to sleep then there is no reason to perform island splitting
	int splitIslandId;

	b3Vec3 gravity;
	float hitEventThreshold;
	float restitutionThreshold;
	float maxLinearSpeed;
	float contactSpeed;
	float contactHertz;
	float contactDampingRatio;
	float contactRecycleDistance;

	b3FrictionCallback* frictionCallback;
	b3RestitutionCallback* restitutionCallback;

	uint16_t generation;

	b3Profile profile;
	int satCallCount;
	int satCacheHitCount;
	int manifoldCounts[B3_CONTACT_MANIFOLD_COUNT_BUCKETS];

	b3Capacity maxCapacity;

	b3PreSolveFcn* preSolveFcn;
	void* preSolveContext;

	b3CustomFilterFcn* customFilterFcn;
	void* customFilterContext;

	int workerCount;
	b3EnqueueTaskCallback* enqueueTaskFcn;
	b3FinishTaskCallback* finishTaskFcn;
	void* userTaskContext;
	void* userTreeTask;

	struct b3Scheduler* scheduler;

	void* userData;

	// Non-NULL while a recording session is active. Set by b3World_StartRecording,
	// cleared by b3World_StopRecording. Hooks in mutators check this before writing.
	struct b3Recording* recording;

	// latest inverse sub-step
	float inv_h;

	// latest inverse full-step
	float inv_dt;

	int activeTaskCount;
	int taskCount;

	uint16_t worldId;

	bool enableSleep;

	// This indicates there is a world write operation in progress. This is for debugging and
	// not a real mutex. This should have minimal performance impact.
	bool locked;
	bool enableWarmStarting;
	bool enableContinuous;
	bool enableSpeculative;
	bool inUse;
} b3World;

b3World* b3GetUnlockedWorldFromId( b3WorldId id );
b3World* b3GetWorldFromId( b3WorldId id );

b3World* b3GetUnlockedWorld( int index );
b3World* b3GetWorld( int index );

void b3ValidateConnectivity( b3World* world );
void b3ValidateSolverSets( b3World* world );
void b3ValidateContacts( b3World* world );

// Register a hull in the world database, returning the owned shared copy. Identical hulls
// share one copy with a reference count. The input may be freed after this call.
const b3HullData* b3AddHullToDatabase( b3World* world, const b3HullData* src );

// Like b3AddHullToDatabase but takes ownership of a heap hull: inserted directly on a miss,
// freed on a hit. Avoids cloning data the caller already allocated.
const b3HullData* b3AddOwnedHullToDatabase( b3World* world, b3HullData* owned );

// Release a reference to a shared hull. The owned copy is freed when the count reaches zero.
void b3RemoveHullFromDatabase( b3World* world, const b3HullData* data );

static inline b3Manifold* b3AllocateManifolds( b3World* world, int count )
{
	if ( count == 0 )
	{
		return NULL;
	}

	int index = count - 1;

	// Need lock because this is called from the parallel narrow phase
	b3LockMutex( world->manifoldAllocatorMutex );
	int currentCount = world->manifoldAllocators.count;
	for ( int i = currentCount; i < count; ++i )
	{
		b3BlockAllocator allocator = b3CreateBlockAllocator( ( i + 1 ) * sizeof( b3Manifold ), 2 * B3_BLOCK_SIZE );
		b3Array_Push( world->manifoldAllocators, allocator );
	}

	b3BlockAllocator* allocator = b3Array_Get( world->manifoldAllocators, index );
	b3Manifold* manifolds = (b3Manifold*)b3AllocateElement( allocator );
	b3UnlockMutex( world->manifoldAllocatorMutex );
	memset( manifolds, 0, count * sizeof( b3Manifold ) );
	return manifolds;
}

static inline void b3FreeManifolds( b3World* world, b3Manifold* manifolds, int count )
{
	if ( count == 0 )
	{
		return;
	}

	int index = count - 1;
	b3LockMutex( world->manifoldAllocatorMutex );
	b3BlockAllocator* allocator = b3Array_Get( world->manifoldAllocators, index );
	b3FreeElement( allocator, manifolds );
	b3UnlockMutex( world->manifoldAllocatorMutex );
}

