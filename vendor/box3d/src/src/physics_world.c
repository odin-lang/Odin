// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "physics_world.h"

#include "arena_allocator.h"
#include "bitset.h"
#include "body.h"
#include "broad_phase.h"
#include "constraint_graph.h"
#include "contact.h"
#include "core.h"
#include "ctz.h"
#include "hull_map.h"
#include "island.h"
#include "joint.h"
#include "parallel_for.h"
#include "platform.h"
#include "recording.h"
#include "scheduler.h"
#include "sensor.h"
#include "shape.h"
#include "solver.h"
#include "solver_set.h"

#include "box3d/box3d.h"
#include "box3d/constants.h"

#include <float.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

_Static_assert( B3_MAX_WORLDS > 0, "must be 1 or more" );
_Static_assert( B3_MAX_WORLDS < UINT16_MAX, "B3_MAX_WORLDS limit exceeded" );
b3World b3_worlds[B3_MAX_WORLDS];
b3AtomicInt b3_worldCount;
int b3_maxWorldCount;

const b3HullData* b3AddHullToDatabase( b3World* world, const b3HullData* src )
{
	b3HullMap* database = world->hullDatabase;

	// Compare by content so an unowned query hull finds the shared copy.
	b3HullMap_itr itr = b3HullMap_get( database, src );
	if ( b3HullMap_is_end( itr ) == false )
	{
		itr.data->val += 1;
		return itr.data->key;
	}

	b3HullData* owned = b3CloneHull( src );
	B3_ASSERT( owned != NULL );
	b3HullMap_insert( database, owned, 1 );
	return owned;
}

const b3HullData* b3AddOwnedHullToDatabase( b3World* world, b3HullData* owned )
{
	b3HullMap* database = world->hullDatabase;

	b3HullMap_itr itr = b3HullMap_get( database, owned );
	if ( b3HullMap_is_end( itr ) == false )
	{
		itr.data->val += 1;
		b3DestroyHull( owned );
		return itr.data->key;
	}

	// Take ownership of input hull.
	b3HullMap_insert( database, owned, 1 );
	return owned;
}

void b3RemoveHullFromDatabase( b3World* world, const b3HullData* data )
{
	b3HullMap* database = world->hullDatabase;

	b3HullMap_itr itr = b3HullMap_get( database, data );
	B3_ASSERT( b3HullMap_is_end( itr ) == false );

	if ( --itr.data->val == 0 )
	{
		// Erase through the iterator we already have so the lookup runs once.
		b3HullData* owned = (b3HullData*)itr.data->key;
		b3HullMap_erase_itr( database, itr );
		b3DestroyHull( owned );
	}
}

b3World* b3GetUnlockedWorldFromId( b3WorldId id )
{
	B3_ASSERT( 1 <= id.index1 && id.index1 <= B3_MAX_WORLDS );
	b3World* world = b3_worlds + ( id.index1 - 1 );
	B3_ASSERT( id.index1 == world->worldId + 1 );
	B3_ASSERT( id.generation == world->generation );

	// A world accessed from an id should not be locked
	if ( world->locked )
	{
		B3_ASSERT( false );
		return NULL;
	}
	return world;
}

b3World* b3GetWorldFromId( b3WorldId id )
{
	B3_ASSERT( 1 <= id.index1 && id.index1 <= B3_MAX_WORLDS );
	b3World* world = b3_worlds + ( id.index1 - 1 );
	B3_ASSERT( id.index1 == world->worldId + 1 );
	B3_ASSERT( id.generation == world->generation );
	return world;
}

b3World* b3GetWorld( int index )
{
	B3_ASSERT( 0 <= index && index < B3_MAX_WORLDS );
	b3World* world = b3_worlds + index;
	B3_ASSERT( world->worldId == index );
	return world;
}

b3World* b3GetUnlockedWorld( int index )
{
	B3_ASSERT( 0 <= index && index < B3_MAX_WORLDS );
	b3World* world = b3_worlds + index;
	B3_ASSERT( world->worldId == index );
	if ( world->locked )
	{
		B3_ASSERT( false );
		return NULL;
	}

	return world;
}

static void* b3DefaultAddTaskFcn( b3TaskCallback* task, void* taskContext, void* userContext, const char* name )
{
	B3_UNUSED( userContext, name );
	task( taskContext );
	return NULL;
}

static void b3DefaultFinishTaskFcn( void* userTask, void* userContext )
{
	B3_UNUSED( userTask );
	B3_UNUSED( userContext );
}

static float b3DefaultFrictionCallback( float frictionA, uint64_t materialA, float frictionB, uint64_t materialB )
{
	B3_UNUSED( materialA, materialB );
	return sqrtf( frictionA * frictionB );
}

static float b3DefaultRestitutionCallback( float restitutionA, uint64_t materialA, float restitutionB, uint64_t materialB )
{
	B3_UNUSED( materialA, materialB );
	return b3MaxFloat( restitutionA, restitutionB );
}

static void b3CreateWorkerContexts( b3World* world )
{
	b3Array_Resize( world->taskContexts, world->workerCount );
	b3Array_MemZero( world->taskContexts );

	b3Array_Resize( world->sensorTaskContexts, world->workerCount );
	b3Array_MemZero( world->sensorTaskContexts );

	for ( int i = 0; i < world->workerCount; ++i )
	{
		world->taskContexts.data[i].arena = b3CreateArena( 128 * 1024 );
		b3Array_Reserve( world->taskContexts.data[i].sensorHits, 8 );
		world->taskContexts.data[i].contactStateBitSet = b3CreateBitSet( 1024 );
		world->taskContexts.data[i].hitEventBitSet = b3CreateBitSet( 1024 );
		world->taskContexts.data[i].hasHitEvents = false;
		world->taskContexts.data[i].jointStateBitSet = b3CreateBitSet( 1024 );
		world->taskContexts.data[i].enlargedSimBitSet = b3CreateBitSet( 256 );
		world->taskContexts.data[i].awakeIslandBitSet = b3CreateBitSet( 256 );
		world->taskContexts.data[i].splitIslandId = B3_NULL_INDEX;

		world->sensorTaskContexts.data[i].eventBits = b3CreateBitSet( 128 );
	}
}

static void b3DestroyWorkerContexts( b3World* world )
{
	for ( int i = 0; i < world->workerCount; ++i )
	{
		b3DestroyArena( &world->taskContexts.data[i].arena );
		b3Array_Destroy( world->taskContexts.data[i].sensorHits );
		b3DestroyBitSet( &world->taskContexts.data[i].contactStateBitSet );
		b3DestroyBitSet( &world->taskContexts.data[i].hitEventBitSet );
		b3DestroyBitSet( &world->taskContexts.data[i].jointStateBitSet );
		b3DestroyBitSet( &world->taskContexts.data[i].enlargedSimBitSet );
		b3DestroyBitSet( &world->taskContexts.data[i].awakeIslandBitSet );

		b3DestroyBitSet( &world->sensorTaskContexts.data[i].eventBits );
	}

	b3Array_Destroy( world->taskContexts );
	b3Array_Destroy( world->sensorTaskContexts );
}

b3WorldId b3CreateWorld( const b3WorldDef* def )
{
	B3_CHECK_DEF( def );

	B3_ASSERT( B3_LINEAR_SLOP <= B3_MESH_REST_OFFSET );
	B3_ASSERT( B3_MESH_REST_OFFSET < B3_SPECULATIVE_DISTANCE );

	int worldId = B3_NULL_INDEX;
	for ( int i = 0; i < B3_MAX_WORLDS; ++i )
	{
		if ( b3_worlds[i].inUse == false )
		{
			worldId = i;
			break;
		}
	}

	if ( worldId == B3_NULL_INDEX )
	{
		b3Log( "B3_MAX_WORLDS of %d exceeded!!!", B3_MAX_WORLDS );
		B3_ASSERT( worldId != B3_NULL_INDEX );
		return (b3WorldId){ 0 };
	}

	// b3Log( "b3_lengthUnitsPerMeter = %g", b3_lengthUnitsPerMeter );

	int oldCount = b3AtomicFetchAddInt( &b3_worldCount, 1 );
	b3_maxWorldCount = b3MaxInt( b3_maxWorldCount, oldCount + 1 );

	// b3Log( "Created world %d", worldId );

	b3InitializeContactRegisters();

	b3World* world = b3_worlds + worldId;
	uint16_t revision = world->generation;

	memset( world, 0, sizeof( b3World ) );

	world->worldId = (uint16_t)worldId;
	world->generation = revision;
	world->inUse = true;

	world->stack = b3CreateStack( 2048 );

	b3Array_Reserve( world->manifoldAllocators, 16 );
	world->manifoldAllocatorMutex = b3CreateMutex();

	b3CreateBroadPhase( &world->broadPhase, &def->capacity );
	b3CreateGraph( &world->constraintGraph, 16 );

	// pools
	world->bodyIdPool = b3CreateIdPool();

	int bodyCapacity = b3MaxInt( 16, def->capacity.staticBodyCount + def->capacity.dynamicBodyCount );
	b3Array_Reserve( world->bodies, bodyCapacity );
	b3Array_Reserve( world->solverSets, 8 );

	// add empty static, active, and disabled body sets
	world->solverSetIdPool = b3CreateIdPool();
	b3SolverSet set = { 0 };

	// static set
	set.setIndex = b3AllocId( &world->solverSetIdPool );
	b3Array_Push( world->solverSets, set );
	b3Array_Reserve( world->solverSets.data[b3_staticSet].bodySims, b3MaxInt( 16, def->capacity.staticBodyCount ) );
	B3_ASSERT( world->solverSets.data[b3_staticSet].setIndex == b3_staticSet );

	// disabled set
	set.setIndex = b3AllocId( &world->solverSetIdPool );
	b3Array_Push( world->solverSets, set );
	B3_ASSERT( world->solverSets.data[b3_disabledSet].setIndex == b3_disabledSet );

	// awake set
	set.setIndex = b3AllocId( &world->solverSetIdPool );
	b3Array_Push( world->solverSets, set );
	b3Array_Reserve( world->solverSets.data[b3_awakeSet].bodySims, b3MaxInt( 16, def->capacity.dynamicBodyCount ) );
	b3Array_Reserve( world->solverSets.data[b3_awakeSet].bodyStates, b3MaxInt( 16, def->capacity.dynamicBodyCount ) );
	b3Array_Reserve( world->solverSets.data[b3_awakeSet].contactIndices, b3MaxInt( 16, def->capacity.contactCount ) );
	B3_ASSERT( world->solverSets.data[b3_awakeSet].setIndex == b3_awakeSet );

	world->shapeIdPool = b3CreateIdPool();

	int shapeCapacity = b3MaxInt( 16, def->capacity.staticShapeCount + def->capacity.dynamicShapeCount );
	b3Array_Reserve( world->shapes, shapeCapacity );

	world->hullDatabase = b3Alloc( sizeof( b3HullMap ) );
	b3HullMap_init( world->hullDatabase );

	world->names = b3CreateNameCache();

	world->contactIdPool = b3CreateIdPool();
	b3Array_Reserve( world->contacts, b3MaxInt( 16, def->capacity.contactCount ) );

	world->jointIdPool = b3CreateIdPool();
	b3Array_Reserve( world->joints, 16 );

	world->islandIdPool = b3CreateIdPool();
	b3Array_Reserve( world->islands, b3MaxInt( 16, def->capacity.dynamicBodyCount ) );

	b3Array_Reserve( world->sensors, 4 );

	b3Array_Reserve( world->bodyMoveEvents, 4 );
	b3Array_Reserve( world->sensorBeginEvents, 4 );
	b3Array_Reserve( world->sensorEndEvents[0], 4 );
	b3Array_Reserve( world->sensorEndEvents[1], 4 );
	b3Array_Reserve( world->contactBeginEvents, 4 );
	b3Array_Reserve( world->contactEndEvents[0], 4 );
	b3Array_Reserve( world->contactEndEvents[1], 4 );
	b3Array_Reserve( world->contactHitEvents, 4 );
	b3Array_Reserve( world->jointEvents, 4 );
	world->endEventArrayIndex = 0;

	world->stepIndex = 0;
	world->splitIslandId = B3_NULL_INDEX;
	world->activeTaskCount = 0;
	world->taskCount = 0;
	world->gravity = def->gravity;
	world->hitEventThreshold = def->hitEventThreshold;
	world->restitutionThreshold = def->restitutionThreshold;
	world->maxLinearSpeed = def->maximumLinearSpeed;
	world->contactSpeed = def->contactSpeed;
	world->contactHertz = def->contactHertz;
	world->contactDampingRatio = def->contactDampingRatio;
	world->contactRecycleDistance = B3_CONTACT_RECYCLE_DISTANCE;

	if ( def->frictionCallback == NULL )
	{
		world->frictionCallback = b3DefaultFrictionCallback;
	}
	else
	{
		world->frictionCallback = def->frictionCallback;
	}

	if ( def->restitutionCallback == NULL )
	{
		world->restitutionCallback = b3DefaultRestitutionCallback;
	}
	else
	{
		world->restitutionCallback = def->restitutionCallback;
	}

	world->enableSleep = def->enableSleep;
	world->locked = false;
	world->enableWarmStarting = true;
	world->enableContinuous = def->enableContinuous;
	world->enableSpeculative = true;
	world->userTreeTask = NULL;
	world->userData = def->userData;

	if ( def->workerCount > 0 && def->enqueueTask != NULL && def->finishTask != NULL )
	{
		// External task system
		world->workerCount = b3MinInt( def->workerCount, B3_MAX_WORKERS );
		world->enqueueTaskFcn = def->enqueueTask;
		world->finishTaskFcn = def->finishTask;
		world->userTaskContext = def->userTaskContext;
		world->scheduler = NULL;
	}
	else if ( def->workerCount > 1 )
	{
		// Built-in scheduler
		world->workerCount = b3MinInt( def->workerCount, B3_MAX_WORKERS );
		world->scheduler = b3CreateScheduler( world->workerCount );
		world->enqueueTaskFcn = b3SchedulerEnqueueTask;
		world->finishTaskFcn = b3SchedulerFinishTask;
		world->userTaskContext = world->scheduler;
	}
	else
	{
		// Serial fallback
		world->workerCount = 1;
		world->enqueueTaskFcn = b3DefaultAddTaskFcn;
		world->finishTaskFcn = b3DefaultFinishTaskFcn;
		world->userTaskContext = NULL;
		world->scheduler = NULL;
	}

	b3CreateWorkerContexts( world );

	world->debugBodySet = b3CreateBitSet( 256 );
	world->debugJointSet = b3CreateBitSet( 256 );
	world->debugContactSet = b3CreateBitSet( 256 );
	world->debugIslandSet = b3CreateBitSet( 256 );
	world->createDebugShape = def->createDebugShape;
	world->destroyDebugShape = def->destroyDebugShape;
	world->userDebugShapeContext = def->userDebugShapeContext;

	// add one to worldId so that 0 represents a null b3WorldId
	return (b3WorldId){ (uint16_t)( worldId + 1 ), world->generation };
}

void b3DestroyWorld( b3WorldId worldId )
{
	b3AtomicFetchAddInt( &b3_worldCount, -1 );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	world->locked = true;

	// Detach any recording before teardown. The user owns and frees the recording buffer.
	b3StopRecordingInternal( world );

	if ( world->scheduler != NULL )
	{
		b3DestroyScheduler( world->scheduler );
		world->scheduler = NULL;
	}

	b3DestroyBitSet( &world->debugBodySet );
	b3DestroyBitSet( &world->debugJointSet );
	b3DestroyBitSet( &world->debugContactSet );
	b3DestroyBitSet( &world->debugIslandSet );

	b3DestroyWorkerContexts( world );

	b3Array_Destroy( world->bodyMoveEvents );
	b3Array_Destroy( world->sensorBeginEvents );
	b3Array_Destroy( world->sensorEndEvents[0] );
	b3Array_Destroy( world->sensorEndEvents[1] );
	b3Array_Destroy( world->contactBeginEvents );
	b3Array_Destroy( world->contactEndEvents[0] );
	b3Array_Destroy( world->contactEndEvents[1] );
	b3Array_Destroy( world->contactHitEvents );
	b3Array_Destroy( world->jointEvents );

	int sensorCount = world->sensors.count;
	for ( int i = 0; i < sensorCount; ++i )
	{
		b3Array_Destroy( world->sensors.data[i].hits );
		b3Array_Destroy( world->sensors.data[i].overlaps1 );
		b3Array_Destroy( world->sensors.data[i].overlaps2 );
	}

	b3Array_Destroy( world->sensors );
	b3Array_Destroy( world->bodies );

	int shapeCapacity = world->shapes.count;
	b3Shape* shapes = world->shapes.data;
	for ( int i = 0; i < shapeCapacity; ++i )
	{
		b3Shape* shape = shapes + i;
		if ( shape->id != B3_NULL_INDEX )
		{
			b3DestroyShapeAllocations( world, shapes + i );
		}
	}

	int contactCapacity = world->contacts.count;
	b3Contact* contacts = world->contacts.data;
	for ( int i = 0; i < contactCapacity; ++i )
	{
		b3Contact* contact = contacts + i;
		if ( contact->contactId != B3_NULL_INDEX )
		{
			if ( contact->flags & b3_simMeshContact )
			{
				b3Array_Destroy( contact->meshContact.triangleCache );
			}
		}
	}

	// Destroying every shape above released all hull references, so the database is empty.
	B3_ASSERT( b3HullMap_size( (b3HullMap*)world->hullDatabase ) == 0 );
	b3HullMap_cleanup( world->hullDatabase );
	b3Free( world->hullDatabase, sizeof( b3HullMap ) );
	world->hullDatabase = NULL;

	b3DestroyNameCache( &world->names );

	b3Array_Destroy( world->shapes );
	b3Array_Destroy( world->contacts );
	b3Array_Destroy( world->joints );

	for ( int i = 0; i < world->islands.count; ++i )
	{
		b3Array_Destroy( world->islands.data[i].bodies );
		b3Array_Destroy( world->islands.data[i].contacts );
		b3Array_Destroy( world->islands.data[i].joints );
	}
	b3Array_Destroy( world->islands );

	// Destroy solver sets
	int setCapacity = world->solverSets.count;
	for ( int i = 0; i < setCapacity; ++i )
	{
		b3SolverSet* set = world->solverSets.data + i;
		if ( set->setIndex != B3_NULL_INDEX )
		{
			b3DestroySolverSet( world, i );
		}
	}

	b3Array_Destroy( world->solverSets );

	b3DestroyGraph( &world->constraintGraph );
	b3DestroyBroadPhase( &world->broadPhase );

	b3DestroyIdPool( &world->bodyIdPool );
	b3DestroyIdPool( &world->shapeIdPool );
	b3DestroyIdPool( &world->contactIdPool );
	b3DestroyIdPool( &world->jointIdPool );
	b3DestroyIdPool( &world->islandIdPool );
	b3DestroyIdPool( &world->solverSetIdPool );

	for ( int i = 0; i < world->manifoldAllocators.count; ++i )
	{
		b3DestroyBlockAllocator( world->manifoldAllocators.data + i );
	}
	b3Array_Destroy( world->manifoldAllocators );
	b3DestroyMutex( world->manifoldAllocatorMutex );

	b3DestroyStack( &world->stack );

	// Wipe world but preserve generation
	uint16_t generation = world->generation;
	memset( world, 0, sizeof( b3World ) );
	world->generation = generation + 1;

	// b3Log( "Destroyed world %d", worldId.index1 - 1 );
}

int b3GetWorldCount( void )
{
	return b3AtomicLoadInt( &b3_worldCount );
}

int b3GetMaxWorldCount( void )
{
	return b3_maxWorldCount;
}

// Issues T0 prefetches across the cache lines of a b3Contact (216 B / 4 lines).
// Used to hide the random-access latency of contact lookups while we work on an
// earlier index.
static inline void b3PrefetchContact( const b3Contact* contact )
{
	const char* p = (const char*)contact;
	b3Prefetch( p );
	b3Prefetch( p + 64 );
	b3Prefetch( p + 128 );
	b3Prefetch( p + 192 );
}

static void b3CollideTask( int startIndex, int endIndex, int workerIndex, void* context )
{
	b3TracyCZoneNC( collide_task, "Collide Task", b3_colorDodgerBlue, true );

	b3StepContext* stepContext = (b3StepContext*)context;
	b3World* world = stepContext->world;
	b3ConstraintGraph* graph = &world->constraintGraph;
	b3TaskContext* taskContext = world->taskContexts.data + workerIndex;
	int* contactIndices = stepContext->awakeContactIndices;
	b3Contact* contacts = world->contacts.data;
	b3Shape* shapes = world->shapes.data;
	b3Body* bodies = world->bodies.data;
	b3BodySim* awakeSims = world->solverSets.data[b3_awakeSet].bodySims.data;
	b3BodySim* staticSims = world->solverSets.data[b3_staticSet].bodySims.data;

	B3_ASSERT( startIndex < endIndex );

	float recycleDistance = world->contactRecycleDistance;
	float speculativeDistance = B3_SPECULATIVE_DISTANCE;
	float recycleDistanceNonTouching = b3MinFloat( recycleDistance, speculativeDistance );

	// Prefetch contact[i + contactPrefetchDistance] each iteration so the random
	// 216 B contact load lands in L1 by the time we reach it. Distance picked to
	// cover ~200 cycles of memory latency without overshooting the L1 working set.
	const int contactPrefetchDistance = 4;
	int prefetchEnd = endIndex - contactPrefetchDistance;

	for ( int i = startIndex; i < endIndex; ++i )
	{
		if ( i < prefetchEnd )
		{
			b3PrefetchContact( contacts + contactIndices[i + contactPrefetchDistance] );
		}

		int contactIndex = contactIndices[i];
		B3_ASSERT( contactIndex < world->contacts.count );

		b3Contact* contact = contacts + contactIndex;
		B3_VALIDATE( contact->contactId == contactIndex );

		b3Shape* shapeA = shapes + contact->shapeIdA;
		b3Shape* shapeB = shapes + contact->shapeIdB;

		// Do proxies still overlap?
		bool overlap = b3AABB_Overlaps( shapeA->fatAABB, shapeB->fatAABB );
		if ( overlap == false )
		{
			// This contact will be destroyed
			contact->flags |= b3_simDisjoint;
			contact->flags &= ~b3_simTouchingFlag;
			b3SetBit( &taskContext->contactStateBitSet, contactIndex );
			continue;
		}

		// Update contact respecting shape/body order (A,B). Bodies behind awake-set
		// contacts are always either awake or static - inline b3GetBodySim with that
		// invariant to skip the cross-TU call and per-call solverSets indirection.
		b3Body* bodyA = bodies + shapeA->bodyId;
		b3Body* bodyB = bodies + shapeB->bodyId;
		bool isStaticA = bodyA->type == b3_staticBody;
		bool isStaticB = bodyB->type == b3_staticBody;
		bool wasTouching = ( contact->flags & b3_simTouchingFlag );
		bool isMeshContact = ( contact->flags & b3_simMeshContact );
		b3BodySim* bodySimA;
		b3BodySim* bodySimB;
		if ( wasTouching )
		{
			B3_ASSERT( bodyA->setIndex == b3_awakeSet || bodyA->setIndex == b3_staticSet );
			B3_ASSERT( bodyB->setIndex == b3_awakeSet || bodyB->setIndex == b3_staticSet );
			bodySimA = ( isStaticA ? staticSims : awakeSims ) + bodyA->localIndex;
			bodySimB = ( isStaticB ? staticSims : awakeSims ) + bodyB->localIndex;
		}
		else
		{
			// There can be non-touching contacts between awake bodies and sleeping bodies.
			{
				b3SolverSet* set = b3Array_Get( world->solverSets, bodyA->setIndex );
				bodySimA = b3Array_Get( set->bodySims, bodyA->localIndex );
			}
			{
				b3SolverSet* set = b3Array_Get( world->solverSets, bodyB->setIndex );
				bodySimB = b3Array_Get( set->bodySims, bodyB->localIndex );
			}
		}

		b3WorldTransform transformA = bodySimA->transform;
		b3WorldTransform transformB = bodySimB->transform;

		bool isFast = ( bodySimA->flags & b3_isFast ) || ( bodySimB->flags & b3_isFast );

		// These are used by the contact solver. If the contact is between an awake body
		// and a sleeping body and the contact begins to touch, the these will be invalid
		// but fixed when linked in the constraint graph.
		contact->bodySimIndexA = isStaticA ? B3_NULL_INDEX : bodyA->localIndex;
		contact->bodySimIndexB = isStaticB ? B3_NULL_INDEX : bodyB->localIndex;
		float recycleTolerance = wasTouching ? recycleDistance : recycleDistanceNonTouching;

		// Contact recycling optimization. Please cite this library if you use this optimization.
		// This is inspired by persistent contact manifolds used in some physics engines, such as PhysX.
		// However, this allows larger relative motion and has fewer tuning parameters (just one).
		if ( ( isFast == false || isMeshContact == false ) && recycleDistance > 0.0f &&
			 ( contact->flags & b3_relativeTransformValid ) && ( contact->flags & b3_contactRecycleFlag ) )
		{
			float angleA = b3DotQuat( transformA.q, contact->cachedRotationA );
			float angleB = b3DotQuat( transformB.q, contact->cachedRotationB );
			float angularDistance = b3MinFloat( angleA * angleA, angleB * angleB );

			b3Transform xf = b3InvMulWorldTransforms( transformA, transformB );
			b3Transform xfc = contact->cachedRelativePose;
			b3Vec3 maxExtentA = isStaticA ? b3Vec3_zero : bodySimA->maxExtent;
			b3Vec3 maxExtentB = isStaticB ? b3Vec3_zero : bodySimB->maxExtent;
			b3Vec3 maxExtent = b3Max( maxExtentA, maxExtentB );

			// Variation of Conservative Advancement
			// distance + 2 * length(modified_cross(|qr.v|, maxExtent)) < recycleTolerance.
			// 2*|qr.v| == 2*|sin(theta/2)| ~= theta for small angles.
			float distSquared = b3DistanceSquared( xf.p, xfc.p );

			if ( angularDistance > B3_CONTACT_RECYCLE_ANGULAR_DISTANCE && distSquared < recycleTolerance * recycleTolerance )
			{
				float distance = sqrtf( distSquared );
				float slack = recycleTolerance - distance;

				// qr = inv( inv(qA0) * qB0 ) * inv(qA) * qB
				//    = inv(qB0) * qA0 * inv(qA) * qB
				// Suppose A is static
				// qr = inv(qB0) * qA0 * inv(qA0) * qB
				//    = inv(qB0) * qB
				// qB = qB0 * qr
				// Therefore qr is associated with the local angular velocity of body B when A is static.
				b3Quat qr = b3InvMulQuat( xfc.q, xf.q );
				b3Vec3 arc = b3ModifiedCross( b3Abs( qr.v ), maxExtent );

				float arcSq = 4.0f * b3LengthSquared( arc );
				if ( arcSq < slack * slack )
				{
					b3Quat dqA = b3MulQuat( transformA.q, b3Conjugate( contact->cachedRotationA ) );
					b3Quat dqB = b3MulQuat( transformB.q, b3Conjugate( contact->cachedRotationB ) );
					b3Matrix3 matrixA = b3MakeMatrixFromQuat( dqA );
					b3Matrix3 matrixB = b3MakeMatrixFromQuat( dqB );

					// Minimize round-off
					b3Vec3 dc = b3SubPos( bodySimB->center, bodySimA->center );

					int manifoldCount = contact->manifoldCount;
					for ( int manifoldIndex = 0; manifoldIndex < manifoldCount; ++manifoldIndex )
					{
						b3Manifold* manifold = contact->manifolds + manifoldIndex;
						b3Vec3 normal = manifold->normal;

						int pointCount = manifold->pointCount;
						for ( int pointIndex = 0; pointIndex < pointCount; ++pointIndex )
						{
							// Keep anchors but update separation, same as sub-stepping. This eliminates jitter.
							b3ManifoldPoint* mp = manifold->points + pointIndex;
							b3Vec3 rA = b3MulMV( matrixA, mp->anchorA );
							b3Vec3 rB = b3MulMV( matrixB, mp->anchorB );
							b3Vec3 dp = b3Add( dc, b3Sub( rB, rA ) );
							mp->separation = mp->baseSeparation + b3Dot( dp, normal );
							mp->persisted = true;
						}
					}

					// Diagnostics
					taskContext->recycledContactCount += 1;
					int bucketIndex = b3MinInt( manifoldCount, B3_CONTACT_MANIFOLD_COUNT_BUCKETS - 1 );
					if ( bucketIndex > 0 )
					{
						taskContext->manifoldCounts[bucketIndex - 1] += 1;
					}

					// Contact is recycled. This also skips updating other aspects of the contact
					// such as material parameters.
					continue;
				}
			}
		}

		// Caching for contact recycling.
		contact->cachedRotationA = transformA.q;
		contact->cachedRotationB = transformB.q;
		contact->cachedRelativePose = b3InvMulWorldTransforms( transformA, transformB );
		contact->flags |= b3_relativeTransformValid;

		// This updates solid contacts
		bool touching = b3UpdateContact( world, workerIndex, contact, shapeA, bodySimA->localCenter, transformA, shapeB,
										 bodySimB->localCenter, transformB, isFast, taskContext->arena );

		int bucketIndex = b3MinInt( contact->manifoldCount, B3_CONTACT_MANIFOLD_COUNT_BUCKETS - 1 );
		if ( bucketIndex > 0 )
		{
			taskContext->manifoldCounts[bucketIndex - 1] += 1;
		}

		// Update the mesh contact spec
		if ( touching == true && wasTouching == true && ( contact->flags & b3_simMeshContact ) )
		{
			B3_ASSERT( contact->colorIndex != B3_NULL_INDEX );
			B3_ASSERT( 0 <= contact->colorIndex && contact->colorIndex < B3_GRAPH_COLOR_COUNT );
			b3GraphColor* color = graph->colors + contact->colorIndex;
			b3ContactSpec* spec = b3Array_Get( color->contacts, contact->localIndex );
			spec->manifoldCount = (uint16_t)contact->manifoldCount;
		}

		// State changes that affect island connectivity. Also affects contact events.
		if ( touching == true && wasTouching == false )
		{
			contact->flags |= b3_simStartedTouching;
			b3SetBit( &taskContext->contactStateBitSet, contactIndex );
		}
		else if ( touching == false && wasTouching == true )
		{
			contact->flags |= b3_simStoppedTouching;
			b3SetBit( &taskContext->contactStateBitSet, contactIndex );
		}

		for ( int manifoldIndex = 0; manifoldIndex < contact->manifoldCount; ++manifoldIndex )
		{
			b3Manifold* manifold = contact->manifolds + manifoldIndex;
			for ( int pointIndex = 0; pointIndex < manifold->pointCount; ++pointIndex )
			{
				// Cache separation
				b3ManifoldPoint* mp = manifold->points + pointIndex;
				mp->baseSeparation = mp->separation;
			}
		}
	}

	b3TracyCZoneEnd( collide_task );
}

static void b3AddNonTouchingContact( b3World* world, b3Contact* contact )
{
	B3_ASSERT( contact->setIndex == b3_awakeSet );
	b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
	contact->colorIndex = B3_NULL_INDEX;
	contact->localIndex = set->contactIndices.count;
	contact->bodySimIndexA = B3_NULL_INDEX;
	contact->bodySimIndexB = B3_NULL_INDEX;
	b3Array_Push( set->contactIndices, contact->contactId );
}

static void b3RemoveNonTouchingContact( b3World* world, int setIndex, int localIndex )
{
	b3SolverSet* set = b3Array_Get( world->solverSets, setIndex );
	int movedIndex = b3Array_RemoveSwap( set->contactIndices, localIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		int movedContactIndex = set->contactIndices.data[localIndex];
		b3Contact* movedContact = b3Array_Get( world->contacts, movedContactIndex );
		B3_ASSERT( movedContact->setIndex == setIndex );
		B3_ASSERT( movedContact->colorIndex == B3_NULL_INDEX );
		B3_ASSERT( movedContact->localIndex == movedIndex );
		movedContact->localIndex = localIndex;
	}
}

// Narrow-phase collision
static void b3Collide( b3StepContext* context )
{
	b3World* world = context->world;

	B3_ASSERT( world->workerCount > 0 );

	b3TracyCZoneNC( collide, "Collide", b3_colorDarkOrchid, true );

	// Gather contacts from all the graph colors into a single array for easier parallel-for
	int touchingCount = 0;

	b3GraphColor* graphColors = world->constraintGraph.colors;
	for ( int i = 0; i < B3_GRAPH_COLOR_COUNT; ++i )
	{
		touchingCount += graphColors[i].convexContacts.count + graphColors[i].contacts.count;
	}

	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	int nonTouchingCount = awakeSet->contactIndices.count;

	int contactCount = touchingCount + nonTouchingCount;

	if ( contactCount == 0 )
	{
		b3TracyCZoneEnd( collide );
		return;
	}

	int* contactIndices = (int*)b3StackAlloc( &world->stack, contactCount * sizeof( int ), "contact indices" );

	int contactIndex = 0;
	for ( int i = 0; i < B3_GRAPH_COLOR_COUNT; ++i )
	{
		b3GraphColor* color = graphColors + i;
		int count = color->convexContacts.count;
		for ( int j = 0; j < count; ++j )
		{
			contactIndices[contactIndex] = color->convexContacts.data[j];
			contactIndex += 1;
		}

		count = color->contacts.count;
		for ( int j = 0; j < count; ++j )
		{
			contactIndices[contactIndex] = color->contacts.data[j].contactId;
			contactIndex += 1;
		}
	}

	B3_ASSERT( contactIndex == touchingCount );

	if ( nonTouchingCount > 0 )
	{
		int* nonTouchingIndices = awakeSet->contactIndices.data;
		memcpy( contactIndices + touchingCount, nonTouchingIndices, nonTouchingCount * sizeof( int ) );
	}

	context->awakeContactIndices = contactIndices;

	// Contact bit set on ids because contact pointers are unstable as they move between touching and not touching.
	int contactIdCapacity = b3GetIdCapacity( &world->contactIdPool );
	for ( int i = 0; i < world->workerCount; ++i )
	{
		b3TaskContext* taskContext = world->taskContexts.data + i;
		b3SetBitCountAndClear( &taskContext->contactStateBitSet, contactIdCapacity );
		taskContext->satCallCount = 0;
		taskContext->satCacheHitCount = 0;
		taskContext->recycledContactCount = 0;
		memset( taskContext->manifoldCounts, 0, sizeof( taskContext->manifoldCounts ) );
	}

	// Task should take at least 40us on a 4GHz CPU (10K cycles)
	int minRange = 20;
	b3ParallelFor( world, b3CollideTask, contactCount, minRange, context, "collide" );

	b3StackFree( &world->stack, contactIndices );
	context->awakeContactIndices = NULL;
	contactIndices = NULL;

	// Serially update contact state
	// todo bring this zone together with island merge
	b3TracyCZoneNC( contact_state, "Contact State", b3_colorLightSlateGray, true );

	int satMultiplier = context->dt > 0.0f ? 1 : 0;

	// Bitwise OR all contact bits
	b3BitSet* bitSet = &world->taskContexts.data[0].contactStateBitSet;
	world->satCallCount = satMultiplier * world->taskContexts.data[0].satCallCount;
	world->satCacheHitCount = satMultiplier * world->taskContexts.data[0].satCacheHitCount;
	memcpy( world->manifoldCounts, world->taskContexts.data[0].manifoldCounts,
			B3_CONTACT_MANIFOLD_COUNT_BUCKETS * sizeof( int ) );

	for ( int i = 1; i < world->workerCount; ++i )
	{
		b3InPlaceUnion( bitSet, &world->taskContexts.data[i].contactStateBitSet );
		world->satCallCount += world->taskContexts.data[i].satCallCount;
		world->satCacheHitCount += world->taskContexts.data[i].satCacheHitCount;
		for ( int j = 0; j < B3_CONTACT_MANIFOLD_COUNT_BUCKETS; ++j )
		{
			world->manifoldCounts[j] += world->taskContexts.data[i].manifoldCounts[j];
		}
	}

	// Release per-step overflow blocks and grow the backing capacity if last
	// step's demand exceeded it. Contact processing is the only consumer of
	// these arenas and is finished by this point.
	for ( int i = 0; i < world->workerCount; ++i )
	{
		b3ArenaSync( &world->taskContexts.data[i].arena );
	}

	int endEventArrayIndex = world->endEventArrayIndex;

	const b3Shape* shapes = world->shapes.data;
	uint16_t worldId = world->worldId;

	// Process contact state changes. Iterate over set bits
	for ( uint32_t k = 0; k < bitSet->blockCount; ++k )
	{
		uint64_t bits = bitSet->bits[k];
		while ( bits != 0 )
		{
			uint32_t ctz = b3CTZ64( bits );
			int contactId = (int)( 64 * k + ctz );

			b3Contact* contact = b3Array_Get( world->contacts, contactId );
			B3_ASSERT( contact->setIndex == b3_awakeSet );

			const b3Shape* shapeA = shapes + contact->shapeIdA;
			const b3Shape* shapeB = shapes + contact->shapeIdB;
			b3ShapeId shapeIdA = { shapeA->id + 1, worldId, shapeA->generation };
			b3ShapeId shapeIdB = { shapeB->id + 1, worldId, shapeB->generation };
			b3ContactId contactFullId = {
				.index1 = contactId + 1,
				.world0 = worldId,
				.padding = 0,
				.generation = contact->generation,
			};
			uint32_t flags = contact->flags;

			if ( flags & b3_simDisjoint )
			{
				// Bounding boxes no longer overlap
				b3DestroyContact( world, contact, false );
				contact = NULL;
			}
			else if ( flags & b3_simStartedTouching )
			{
				B3_ASSERT( contact->islandId == B3_NULL_INDEX );

				if ( flags & b3_contactEnableContactEvents )
				{
					b3ContactBeginTouchEvent event = { shapeIdA, shapeIdB, contactFullId };
					b3Array_Push( world->contactBeginEvents, event );
				}

				B3_ASSERT( contact->manifoldCount > 0 );
				B3_ASSERT( contact->setIndex == b3_awakeSet );

				// Link first because this wakes colliding bodies and ensures the body sims
				// are in the correct place.
				contact->flags &= ~b3_simStartedTouching;
				contact->flags |= b3_contactTouchingFlag;
				b3LinkContact( world, contact );

				// Make sure these didn't change
				B3_ASSERT( contact->colorIndex == B3_NULL_INDEX );

				// Contact sim pointer may have become orphaned due to awake set growth,
				// so I just need to refresh it.

				int oldLocalIndex = contact->localIndex;

				b3AddContactToGraph( world, contact );
				b3RemoveNonTouchingContact( world, b3_awakeSet, oldLocalIndex );
			}
			else if ( flags & b3_simStoppedTouching )
			{
				contact->flags &= ~b3_simStoppedTouching;
				contact->flags &= ~b3_contactTouchingFlag;

				if ( contact->flags & b3_contactEnableContactEvents )
				{
					b3ContactEndTouchEvent event = { shapeIdA, shapeIdB, contactFullId };
					b3Array_Push( world->contactEndEvents[endEventArrayIndex], event );
				}

				B3_ASSERT( contact->manifoldCount == 0 );

				// Cache these here for the remove below
				int colorIndex = contact->colorIndex;
				int localIndex = contact->localIndex;

				b3UnlinkContact( world, contact );
				int bodyIdA = contact->edges[0].bodyId;
				int bodyIdB = contact->edges[1].bodyId;

				b3AddNonTouchingContact( world, contact );

				bool isMeshContact = contact->flags & b3_simMeshContact;
				b3RemoveContactFromGraph( world, bodyIdA, bodyIdB, colorIndex, localIndex, isMeshContact );
				contact = NULL;
			}

			// Clear the smallest set bit
			bits = bits & ( bits - 1 );
		}
	}

	b3ValidateSolverSets( world );
	b3ValidateContacts( world );

	b3TracyCZoneEnd( contact_state );
	b3TracyCZoneEnd( collide );
}

void b3World_Step( b3WorldId worldId, float timeStep, int subStepCount )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, Step, worldId, timeStep, subStepCount );

	world->locked = true;

	b3TracyCZoneNC( world_step, "Step", b3_colorBox2DGreen, true );

	// Clear debug buffers
	for ( int i = 0; i < world->workerCount; ++i )
	{
		world->taskContexts.data[i].pointCount = 0;
		world->taskContexts.data[i].lineCount = 0;
	}

	// Prepare to capture events
	// Ensure user does not access stale data if there is an early return
	b3Array_Clear( world->bodyMoveEvents );
	b3Array_Clear( world->sensorBeginEvents );
	b3Array_Clear( world->contactBeginEvents );
	b3Array_Clear( world->contactHitEvents );
	b3Array_Clear( world->jointEvents );

	world->profile = (b3Profile){ 0 };

	world->activeTaskCount = 0;
	world->taskCount = 0;

	if ( world->scheduler != NULL )
	{
		b3ResetScheduler( world->scheduler );
	}

	uint64_t stepTicks = b3GetTicks();

	{
		b3Capacity* c = &world->maxCapacity;
		c->staticShapeCount = b3MaxInt( c->staticShapeCount, world->broadPhase.trees[b3_staticBody].proxyCount );
		c->dynamicShapeCount = b3MaxInt( c->dynamicShapeCount, world->broadPhase.trees[b3_dynamicBody].proxyCount );

		int staticBodyCount = world->solverSets.data[b3_staticSet].bodySims.count;
		c->staticBodyCount = b3MaxInt( c->staticBodyCount, staticBodyCount );

		// this includes kinematic bodies
		int totalBodyCount = b3GetIdCount( &world->bodyIdPool );
		c->dynamicBodyCount = b3MaxInt( c->dynamicBodyCount, totalBodyCount - staticBodyCount );

		int totalContactCount = b3GetIdCount( &world->contactIdPool );
		c->contactCount = b3MaxInt( c->contactCount, totalContactCount );
	}

	// Update collision pairs and create contacts
	{
		uint64_t pairTicks = b3GetTicks();
		b3UpdateBroadPhasePairs( world );
		world->profile.pairs = b3GetMilliseconds( pairTicks );
	}

	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );

	b3StepContext context = { 0 };
	context.world = world;
	context.states = awakeSet->bodyStates.data;
	context.dt = timeStep;
	context.subStepCount = b3MaxInt( 1, subStepCount );

	if ( timeStep > 0.0f )
	{
		context.inv_dt = 1.0f / timeStep;
		context.h = timeStep / context.subStepCount;
		context.inv_h = context.subStepCount * context.inv_dt;
	}
	else
	{
		context.inv_dt = 0.0f;
		context.h = 0.0f;
		context.inv_h = 0.0f;
	}

	world->inv_h = context.inv_h;
	world->inv_dt = context.inv_dt;

	// Hertz values get reduced for large time steps
	float contactHertz = b3MinFloat( world->contactHertz, 0.125f * context.inv_h );
	context.contactSoftness = b3MakeSoft( contactHertz, world->contactDampingRatio, context.h );
	context.staticSoftness = b3MakeSoft( 2.0f * contactHertz, 0.5f * world->contactDampingRatio, context.h );

	context.restitutionThreshold = world->restitutionThreshold;
	context.maxLinearVelocity = world->maxLinearSpeed;
	context.enableWarmStarting = world->enableWarmStarting;

	// Narrow phase : update contacts
	{
		uint64_t collideTicks = b3GetTicks();
		b3Collide( &context );
		world->profile.collide = b3GetMilliseconds( collideTicks );
	}

	// Integrate velocities, solve velocity constraints, and integrate positions.
	if ( timeStep > 0.0f )
	{
		uint64_t solveTicks = b3GetTicks();
		b3Solve( world, &context );
		world->profile.solve = b3GetMilliseconds( solveTicks );
	}

	// Finish the tree task in case b3Solve didn't finish it
	if ( world->userTreeTask )
	{
		world->finishTaskFcn( world->userTreeTask, world->userTaskContext );
		world->userTreeTask = NULL;
		world->activeTaskCount -= 1;
	}

	// Update sensors
	{
		uint64_t sensorTicks = b3GetTicks();
		b3OverlapSensors( world );
		world->profile.sensors = b3GetMilliseconds( sensorTicks );
	}

	world->profile.step = b3GetMilliseconds( stepTicks );

	B3_ASSERT( world->stack.allocation == 0 );

	// Ensure stack is large enough
	b3GrowStack( &world->stack );

	// Make sure all tasks that were started were also finished
	B3_ASSERT( world->activeTaskCount == 0 );

	// Swap end event array buffers
	world->endEventArrayIndex = 1 - world->endEventArrayIndex;
	b3Array_Clear( world->sensorEndEvents[world->endEventArrayIndex] );
	b3Array_Clear( world->contactEndEvents[world->endEventArrayIndex] );
	world->locked = false;

	if ( world->recording != NULL )
	{
		uint64_t hash = b3HashWorldState( world );
		b3RecArgs_StateHash stateHash = { worldId, hash };
		b3RecWrite_StateHash( world->recording, &stateHash );

		// Fold this step's world bounds into the recording so a viewer can frame the whole motion.
		b3AABB worldBounds = { 0 };
		bool haveBounds = false;
		for ( int i = 0; i < b3_bodyTypeCount; ++i )
		{
			b3DynamicTree* tree = world->broadPhase.trees + i;
			if ( b3DynamicTree_GetProxyCount( tree ) == 0 )
			{
				continue;
			}
			b3AABB bounds = b3DynamicTree_GetRootBounds( tree );
			worldBounds = haveBounds ? b3AABB_Union( worldBounds, bounds ) : bounds;
			haveBounds = true;
		}
		if ( haveBounds )
		{
			b3RecAccumulateBounds( world->recording, worldBounds );
		}
	}

	b3TracyCZoneEnd( world_step );
	b3TracyCFrame;
}

typedef struct DrawContext
{
	b3World* world;
	b3DebugDraw* draw;
} DrawContext;

static bool DrawQueryCallback( int proxyId, uint64_t userData, void* context )
{
	int shapeId = (int)userData;

	B3_UNUSED( proxyId );

	struct DrawContext* drawContext = (DrawContext*)context;
	b3World* world = drawContext->world;
	b3DebugDraw* draw = drawContext->draw;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );
	B3_ASSERT( shape->id == shapeId );

	b3SetBit( &world->debugBodySet, shape->bodyId );

	if ( draw->drawShapes )
	{
		b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
		b3BodySim* bodySim = b3GetBodySim( world, body );

		b3HexColor color;

		const b3SurfaceMaterial* surfaceMaterial = b3GetShapeMaterials( shape );
		if ( surfaceMaterial[0].customColor != 0 )
		{
			// May already carry a packed material preset, pass through unchanged
			color = (b3HexColor)surfaceMaterial[0].customColor;
		}
		else
		{
			// Hue carries the state, material carries its energy. Calm matte for the
			// resting masses, glossy for fast bodies, metallic for the driven kinematic.
			// Diagnostic states keep a saturated hue and the default material so they pop.
			b3HexColor rgb;
			b3DebugMaterial material = b3_debugMaterialDefault;

			if ( body->type == b3_dynamicBody && body->mass == 0.0f )
			{
				// Bad body
				rgb = b3_colorRed;
			}
			else if ( body->setIndex == b3_disabledSet )
			{
				rgb = b3_colorSlateGray;
			}
			else if ( shape->sensorIndex != B3_NULL_INDEX )
			{
				rgb = b3_colorWheat;
			}
			else if ( body->flags & b3_hadTimeOfImpact )
			{
				rgb = b3_colorLime;
			}
			else if ( ( bodySim->flags & b3_isBullet ) && body->setIndex == b3_awakeSet )
			{
				rgb = b3_colorTurquoise;
			}
			else if ( body->flags & b3_isSpeedCapped )
			{
				rgb = b3_colorYellow;
			}
			else if ( bodySim->flags & b3_isFast )
			{
				rgb = b3_colorOrange;
				material = b3_debugMaterialGlossy;
			}
			else if ( body->type == b3_staticBody )
			{
				rgb = b3_colorDarkGray;
				material = b3_debugMaterialMatte;
			}
			else if ( body->type == b3_kinematicBody )
			{
				if ( body->setIndex == b3_awakeSet )
				{
					rgb = b3_colorSteelBlue;
					material = b3_debugMaterialMetallic;
				}
				else
				{
					rgb = b3_colorLightSteelBlue;
					material = b3_debugMaterialMatte;
				}
			}
			else if ( body->setIndex == b3_awakeSet )
			{
				rgb = b3_colorTan;
				material = b3_debugMaterialSoft;
			}
			else
			{
				rgb = b3_colorLightSlateGray;
				material = b3_debugMaterialDead;
			}

			color = (b3HexColor)b3MakeDebugColor( rgb, material );
		}

		if ( shape->userShape == NULL && world->createDebugShape != NULL )
		{
			b3DebugShape debugShape = { 0 };
			debugShape.shapeId = (b3ShapeId){
				.world0 = world->worldId,
				.index1 = shapeId + 1,
				.generation = shape->generation,
			};
			debugShape.type = shape->type;

			switch ( shape->type )
			{
				case b3_capsuleShape:
					debugShape.capsule = &shape->capsule;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				case b3_compoundShape:
					debugShape.compound = shape->compound;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				case b3_heightShape:
					debugShape.heightField = shape->heightField;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				case b3_hullShape:
					debugShape.hull = shape->hull;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				case b3_meshShape:
					debugShape.mesh = &shape->mesh;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				case b3_sphereShape:
					debugShape.sphere = &shape->sphere;
					shape->userShape = world->createDebugShape( &debugShape, world->userDebugShapeContext );
					break;
				default:
					B3_ASSERT( false );
					break;
			}
		}

		if ( shape->userShape != NULL )
		{
			draw->DrawShapeFcn( shape->userShape, bodySim->transform, color, draw->context );
		}
	}

	if ( draw->drawBounds )
	{
		draw->DrawBoundsFcn( shape->fatAABB, b3_colorGold, draw->context );
	}

	return true;
}

void b3World_Draw( b3WorldId worldId, b3DebugDraw* draw, uint64_t maskBits )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_ASSERT( b3IsValidAABB( draw->drawingBounds ) );

	float lengthScale = b3GetLengthUnitsPerMeter();
	float axisScale = 0.3f * lengthScale;
	b3HexColor farColor = b3_colorDarkBlue;
	b3HexColor speculativeColor = b3_colorBlue;
	b3HexColor addColor = b3_colorLimeGreen;
	b3HexColor persistColor = b3_colorLightBlue;
	// b3HexColor normalColors[3] = { b3_colorLightGray, b3_colorLightSalmon, b3_colorLightSeaGreen };
	b3HexColor impulseColor = b3_colorMagenta;
	b3HexColor frictionColor = b3_colorYellow;

	b3HexColor graphColors[B3_GRAPH_COLOR_COUNT] = {
		b3_colorRed,	b3_colorOrange, b3_colorYellow,	   b3_colorGreen,	  b3_colorCyan,		b3_colorBlue,
		b3_colorViolet, b3_colorPink,	b3_colorChocolate, b3_colorGoldenRod, b3_colorCoral,	b3_colorRosyBrown,
		b3_colorAqua,	b3_colorPeru,	b3_colorLime,	   b3_colorGold,	  b3_colorPlum,		b3_colorSnow,
		b3_colorTeal,	b3_colorKhaki,	b3_colorSalmon,	   b3_colorPeachPuff, b3_colorHoneyDew, b3_colorBlack,
	};

	int bodyCapacity = b3GetIdCapacity( &world->bodyIdPool );
	b3SetBitCountAndClear( &world->debugBodySet, bodyCapacity );

	int jointCapacity = b3GetIdCapacity( &world->jointIdPool );
	b3SetBitCountAndClear( &world->debugJointSet, jointCapacity );

	int contactCapacity = b3GetIdCapacity( &world->contactIdPool );
	b3SetBitCountAndClear( &world->debugContactSet, contactCapacity );

	int islandCapacity = b3GetIdCapacity( &world->islandIdPool );
	b3SetBitCountAndClear( &world->debugIslandSet, islandCapacity );

	struct DrawContext drawContext = { world, draw };

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3DynamicTree_Query( world->broadPhase.trees + i, draw->drawingBounds, maskBits, false, DrawQueryCallback, &drawContext );
	}

	uint32_t wordCount = world->debugBodySet.blockCount;
	uint64_t* bits = world->debugBodySet.bits;
	for ( uint32_t wordIndex = 0; wordIndex < wordCount; ++wordIndex )
	{
		uint64_t word = bits[wordIndex];
		while ( word != 0 )
		{
			uint32_t ctz = b3CTZ64( word );
			int bodyId = (int)( 64 * wordIndex + ctz );

			b3Body* body = b3Array_Get( world->bodies, bodyId );
			b3BodySim* bodySim = b3GetBodySim( world, body );

			if ( draw->drawBodyNames && body->nameId != B3_NULL_NAME )
			{
				b3Vec3 offset = { 0.05f, 0.05f, 0.05f };
				b3WorldTransform transform = { bodySim->center, bodySim->transform.q };
				b3Pos p = b3TransformWorldPoint( transform, offset );
				const char* name = b3FindName( &world->names, body->nameId );
				if ( name != NULL )
				{
					draw->DrawStringFcn( p, name, b3_colorOrange, draw->context );
				}
			}

			if ( draw->drawMass && body->type == b3_dynamicBody )
			{
				b3Vec3 offset = { 0.1f, 0.1f, 0.1f };

				b3WorldTransform transform = { bodySim->center, bodySim->transform.q };
				draw->DrawTransformFcn( transform, draw->context );
				b3Pos p = b3TransformWorldPoint( transform, offset );

				char buffer[32];
				snprintf( buffer, 32, "  %.2f", body->mass );
				draw->DrawStringFcn( p, buffer, b3_colorWhite, draw->context );
			}

			if ( draw->drawSleep )
			{
				b3BodyState* bodyState = b3GetBodyState( world, body );

				if ( bodyState != NULL )
				{
					b3HexColor colors[4] = { b3_colorBlue, b3_colorSkyBlue, b3_colorOrange, b3_colorRed };

					b3HexColor color = b3_colorBlack;
					if ( body->sleepThreshold > 0.0f )
					{
						float ratio = body->sleepVelocity / body->sleepThreshold;
						int index = b3ClampInt( (int)ratio, 0, 3 );
						color = colors[index];
					}

					b3Pos center = bodySim->center;
					draw->DrawPointFcn( center, 10.0f, color, draw->context );

					b3Vec3 offset = { 0.1f, 0.1f, 0.1f };
					b3Pos p = b3OffsetPos( center, offset );

					char buffer[32];
					snprintf( buffer, 32, "  %.3f", body->sleepVelocity );
					draw->DrawStringFcn( p, buffer, color, draw->context );
				}
			}

			if ( draw->drawJoints )
			{
				int jointKey = body->headJointKey;
				while ( jointKey != B3_NULL_INDEX )
				{
					int jointId = jointKey >> 1;
					int edgeIndex = jointKey & 1;
					b3Joint* joint = b3Array_Get( world->joints, jointId );

					// avoid double draw
					if ( b3GetBit( &world->debugJointSet, jointId ) == false )
					{
						b3DrawJoint( draw, world, joint );
						b3SetBit( &world->debugJointSet, jointId );
					}

					jointKey = joint->edges[edgeIndex].nextKey;
				}
			}

			const float speculativeDistance = B3_SPECULATIVE_DISTANCE;
			if ( draw->drawContacts && body->type == b3_dynamicBody && body->setIndex == b3_awakeSet )
			{
				int contactKey = body->headContactKey;
				while ( contactKey != B3_NULL_INDEX )
				{
					int contactId = contactKey >> 1;
					int edgeIndex = contactKey & 1;
					b3Contact* contact = b3Array_Get( world->contacts, contactId );
					contactKey = contact->edges[edgeIndex].nextKey;

					if ( contact->setIndex != b3_awakeSet || contact->colorIndex == B3_NULL_INDEX )
					{
						continue;
					}

					// avoid double draw
					if ( b3GetBit( &world->debugContactSet, contactId ) == false )
					{
						b3Body* bodyA = b3Array_Get( world->bodies, contact->edges[0].bodyId );
						b3BodySim* bodySimA = b3GetBodySim( world, bodyA );
						b3Body* bodyB = b3Array_Get( world->bodies, contact->edges[1].bodyId );
						b3BodySim* bodySimB = b3GetBodySim( world, bodyB );

						for ( int manifoldIndex = 0; manifoldIndex < contact->manifoldCount; ++manifoldIndex )
						{
							const b3Manifold* manifold = contact->manifolds + manifoldIndex;
							B3_ASSERT( manifold->pointCount > 0 );

							b3Vec3 normal = manifold->normal;

							// Average the anchors not the world points so the friction center stays exact far from the origin
							b3Pos contactCenter = draw->drawAnchorA == 1 ? bodySimA->center : bodySimB->center;
							b3Vec3 anchorSum = b3Vec3_zero;

							const b3ManifoldPoint* points = manifold->points;
							for ( int pointIndex = 0; pointIndex < manifold->pointCount; ++pointIndex )
							{
								const b3ManifoldPoint* mp = points + pointIndex;

								char buffer[32];

								b3Vec3 anchor = draw->drawAnchorA == 1 ? mp->anchorA : mp->anchorB;
								b3Pos p = b3OffsetPos( contactCenter, anchor );

								anchorSum = b3Add( anchorSum, anchor );

								if ( draw->drawContactNormals )
								{
									b3Pos p1 = p;
									b3Pos p2 = b3OffsetPos( p1, b3MulSV( axisScale, normal ) );
									draw->DrawSegmentFcn( p1, p2, b3_colorLightGray, draw->context );

									snprintf( buffer, B3_ARRAY_COUNT( buffer ), "   %.2f", 100.0f * mp->separation );
									draw->DrawStringFcn( p, buffer, b3_colorWhite, draw->context );
								}
								else if ( draw->drawContactForces )
								{
									// Hack inv_dt for single step debugging
									float inv_dt = world->inv_dt > 0.0f ? world->inv_dt : 60.0f;
									// todo validate
									// multiply by one-half due to relax iteration
									float force = 0.5f * mp->totalNormalImpulse * inv_dt;
									b3Pos p1 = p;
									b3Pos p2 = b3OffsetPos( p1, b3MulSV( draw->forceScale * force, normal ) );
									draw->DrawSegmentFcn( p1, p2, impulseColor, draw->context );
									snprintf( buffer, B3_ARRAY_COUNT( buffer ), "  %.1f", force );
									draw->DrawStringFcn( p1, buffer, b3_colorWhite, draw->context );
								}
								else if ( draw->drawContactFeatures )
								{
									snprintf( buffer, B3_ARRAY_COUNT( buffer ), "   %#X", mp->featureId );
									draw->DrawStringFcn( p, buffer, b3_colorWhite, draw->context );
								}

								if ( draw->drawGraphColors )
								{
									// graph color
									float pointSize = contact->colorIndex == B3_OVERFLOW_INDEX ? 15.0f : 10.0f;
									draw->DrawPointFcn( p, pointSize, graphColors[contact->colorIndex], draw->context );
									// g_draw.DrawString(point->position, "%d", point->color);
								}
								else if ( mp->persisted == false )
								{
									// Add
									draw->DrawPointFcn( p, 20.0f, addColor, draw->context );
								}
								else if ( mp->separation > speculativeDistance )
								{
									// Speculative
									draw->DrawPointFcn( p, 10.0f, farColor, draw->context );
								}
								else if ( mp->separation > 0.0f )
								{
									// Speculative
									draw->DrawPointFcn( p, 10.0f, speculativeColor, draw->context );
								}
								else
								{
									// Persist
									draw->DrawPointFcn( p, 10.0f, persistColor, draw->context );
								}
							}

							if ( draw->drawContactForces )
							{
								// Hack inv_dt for single step debugging
								float inv_dt = world->inv_dt > 0.0f ? world->inv_dt : 60.0f;

								b3Vec3 avgAnchor = b3MulSV( 1.0f / manifold->pointCount, anchorSum );
								b3Pos p1 = b3OffsetPos( contactCenter, avgAnchor );
								b3Vec3 frictionForce = b3MulSV( 0.5f * inv_dt, manifold->frictionImpulse );
								b3Pos p2 = b3OffsetPos( p1, b3MulSV( draw->forceScale, frictionForce ) );
								draw->DrawSegmentFcn( p1, p2, frictionColor, draw->context );
								draw->DrawPointFcn( p1, 5.0f, frictionColor, draw->context );

								p1 = b3OffsetPos( p1, b3MulSV( 0.05f * lengthScale, normal ) );
								char buffer[32];
								snprintf( buffer, B3_ARRAY_COUNT( buffer ), "%.2f", b3Length( frictionForce ) );
								draw->DrawStringFcn( p1, buffer, b3_colorWhite, draw->context );
							}
						}

						b3SetBit( &world->debugContactSet, contactId );
					}

					contactKey = contact->edges[edgeIndex].nextKey;
				}
			}

			if ( draw->drawIslands )
			{
				int islandId = body->islandId;
				if ( islandId != B3_NULL_INDEX && b3GetBit( &world->debugIslandSet, islandId ) == false )
				{
					b3Island* island = world->islands.data + islandId;
					if ( island->setIndex == B3_NULL_INDEX )
					{
						continue;
					}

					int shapeCount = 0;
					b3AABB aabb = {
						.lowerBound = { FLT_MAX, FLT_MAX, FLT_MAX },
						.upperBound = { -FLT_MAX, -FLT_MAX, -FLT_MAX },
					};

					for ( int b = 0; b < island->bodies.count; ++b )
					{
						int islandBodyId = island->bodies.data[b];
						b3Body* islandBody = b3Array_Get( world->bodies, islandBodyId );
						int shapeId = islandBody->headShapeId;
						while ( shapeId != B3_NULL_INDEX )
						{
							b3Shape* shape = b3Array_Get( world->shapes, shapeId );
							aabb = b3AABB_Union( aabb, shape->fatAABB );
							shapeCount += 1;
							shapeId = shape->nextShapeId;
						}
					}

					if ( shapeCount > 0 )
					{
						draw->DrawBoundsFcn( aabb, b3_colorOrangeRed, draw->context );
					}

					b3SetBit( &world->debugIslandSet, islandId );
				}
			}

			// Clear the smallest set bit
			word = word & ( word - 1 );
		}
	}

	char buffer[32] = { 0 };
	float lengthUnits = b3GetLengthUnitsPerMeter();
	b3Vec3 offset = { 0.002f * lengthUnits, 0.002f * lengthUnits, 0.002f * lengthUnits };
	for ( int i = 0; i < world->workerCount; ++i )
	{
		int pointCount = world->taskContexts.data[i].pointCount;
		b3DebugPoint* points = world->taskContexts.data[i].points;
		for ( int j = 0; j < pointCount; ++j )
		{
			b3DebugPoint* point = points + j;
			b3Pos p = point->p;
			draw->DrawPointFcn( p, 5.0f, point->color, draw->context );
			snprintf( buffer, 32, "   %d, %.2f", point->label, point->value );
			b3Pos ps = b3OffsetPos( p, offset );
			draw->DrawStringFcn( ps, buffer, point->color, draw->context );
		}

		int lineCount = world->taskContexts.data[i].lineCount;
		b3DebugLine* lines = world->taskContexts.data[i].lines;
		for ( int j = 0; j < lineCount; ++j )
		{
			b3DebugLine* line = lines + j;
			b3Pos p1 = line->p1;
			b3Pos p2 = line->p2;
			draw->DrawSegmentFcn( p1, p2, line->color, draw->context );
			draw->DrawPointFcn( p1, 10.0f, line->color, draw->context );
			snprintf( buffer, 32, "%d", line->label );
			b3Pos ps = b3OffsetPos( p1, offset );
			draw->DrawStringFcn( ps, buffer, line->color, draw->context );
		}
	}
}

b3AABB b3World_GetBounds( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3AABB){ 0 };
	}

	b3AABB worldBounds = { 0 };
	bool haveBounds = false;

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3DynamicTree* tree = world->broadPhase.trees + i;
		if ( b3DynamicTree_GetProxyCount( tree ) == 0 )
		{
			continue;
		}

		b3AABB bounds = b3DynamicTree_GetRootBounds( world->broadPhase.trees + i );

		if ( haveBounds )
		{
			worldBounds = b3AABB_Union( worldBounds, bounds );
		}
		else
		{
			worldBounds = bounds;
			haveBounds = true;
		}
	}

	return worldBounds;
}

b3BodyEvents b3World_GetBodyEvents( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3BodyEvents){ 0 };
	}

	int count = world->bodyMoveEvents.count;
	b3BodyEvents events = { world->bodyMoveEvents.data, count };
	return events;
}

b3SensorEvents b3World_GetSensorEvents( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3SensorEvents){ 0 };
	}

	// Careful to use previous buffer
	int endEventArrayIndex = 1 - world->endEventArrayIndex;

	int beginCount = world->sensorBeginEvents.count;
	int endCount = world->sensorEndEvents[endEventArrayIndex].count;

	b3SensorEvents events = {
		.beginEvents = world->sensorBeginEvents.data,
		.endEvents = world->sensorEndEvents[endEventArrayIndex].data,
		.beginCount = beginCount,
		.endCount = endCount,
	};
	return events;
}

b3ContactEvents b3World_GetContactEvents( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3ContactEvents){ 0 };
	}

	// Careful to use previous buffer
	int endEventArrayIndex = 1 - world->endEventArrayIndex;

	int beginCount = world->contactBeginEvents.count;
	int endCount = world->contactEndEvents[endEventArrayIndex].count;
	int hitCount = world->contactHitEvents.count;

	b3ContactEvents events = {
		.beginEvents = world->contactBeginEvents.data,
		.endEvents = world->contactEndEvents[endEventArrayIndex].data,
		.hitEvents = world->contactHitEvents.data,
		.beginCount = beginCount,
		.endCount = endCount,
		.hitCount = hitCount,
	};

	return events;
}

b3JointEvents b3World_GetJointEvents( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3JointEvents){ 0 };
	}

	int count = world->jointEvents.count;
	b3JointEvents events = { world->jointEvents.data, count };
	return events;
}

bool b3World_IsValid( b3WorldId id )
{
	if ( id.index1 < 1 || B3_MAX_WORLDS < id.index1 )
	{
		return false;
	}

	b3World* world = b3_worlds + ( id.index1 - 1 );

	if ( world->worldId != id.index1 - 1 )
	{
		// world is not allocated
		return false;
	}

	return id.generation == world->generation;
}

bool b3Body_IsValid( b3BodyId id )
{
	if ( B3_MAX_WORLDS <= id.world0 )
	{
		// invalid world
		return false;
	}

	b3World* world = b3_worlds + id.world0;
	if ( world->worldId != id.world0 )
	{
		// world is free
		return false;
	}

	if ( id.index1 < 1 || world->bodies.count < id.index1 )
	{
		// invalid index
		return false;
	}

	b3Body* body = world->bodies.data + ( id.index1 - 1 );
	if ( body->setIndex == B3_NULL_INDEX )
	{
		// this was freed
		return false;
	}

	B3_ASSERT( body->localIndex != B3_NULL_INDEX );

	if ( body->generation != id.generation )
	{
		// this id is orphaned
		return false;
	}

	return true;
}

bool b3Shape_IsValid( b3ShapeId id )
{
	if ( B3_MAX_WORLDS <= id.world0 )
	{
		return false;
	}

	b3World* world = b3_worlds + id.world0;
	if ( world->worldId != id.world0 )
	{
		// world is free
		return false;
	}

	int shapeId = id.index1 - 1;
	if ( shapeId < 0 || world->shapes.count <= shapeId )
	{
		return false;
	}

	b3Shape* shape = world->shapes.data + shapeId;
	if ( shape->id == B3_NULL_INDEX )
	{
		// shape is free
		return false;
	}

	B3_ASSERT( shape->id == shapeId );

	return id.generation == shape->generation;
}

bool b3Joint_IsValid( b3JointId id )
{
	if ( B3_MAX_WORLDS <= id.world0 )
	{
		return false;
	}

	b3World* world = b3_worlds + id.world0;
	if ( world->worldId != id.world0 )
	{
		// world is free
		return false;
	}

	int jointId = id.index1 - 1;
	if ( jointId < 0 || world->joints.count <= jointId )
	{
		return false;
	}

	b3Joint* joint = world->joints.data + jointId;
	if ( joint->jointId == B3_NULL_INDEX )
	{
		// joint is free
		return false;
	}

	B3_ASSERT( joint->jointId == jointId );

	return id.generation == joint->generation;
}

bool b3Contact_IsValid( b3ContactId id )
{
	if ( B3_MAX_WORLDS <= id.world0 )
	{
		return false;
	}

	b3World* world = b3_worlds + id.world0;
	if ( world->worldId != id.world0 )
	{
		// world is free
		return false;
	}

	int contactId = id.index1 - 1;
	if ( contactId < 0 || world->contacts.count <= contactId )
	{
		return false;
	}

	b3Contact* contact = world->contacts.data + contactId;
	if ( contact->contactId == B3_NULL_INDEX )
	{
		// contact is free
		return false;
	}

	B3_ASSERT( contact->contactId == contactId );

	return id.generation == contact->generation;
}

void b3World_EnableSleeping( b3WorldId worldId, bool flag )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	if ( flag == world->enableSleep )
	{
		return;
	}

	B3_REC( world, WorldEnableSleeping, worldId, flag );

	world->enableSleep = flag;

	if ( flag == false )
	{
		int setCount = world->solverSets.count;
		for ( int i = b3_firstSleepingSet; i < setCount; ++i )
		{
			b3SolverSet* set = b3Array_Get( world->solverSets, i );
			if ( set->bodySims.count > 0 )
			{
				b3WakeSolverSet( world, i );
			}
		}
	}
}

bool b3World_IsSleepingEnabled( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->enableSleep;
}

void b3World_EnableWarmStarting( b3WorldId worldId, bool flag )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldEnableWarmStarting, worldId, flag );

	world->enableWarmStarting = flag;
}

bool b3World_IsWarmStartingEnabled( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->enableWarmStarting;
}

int b3World_GetAwakeBodyCount( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return 0;
	}
	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	return awakeSet->bodySims.count;
}

void b3World_EnableContinuous( b3WorldId worldId, bool flag )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldEnableContinuous, worldId, flag );

	world->enableContinuous = flag;
}

bool b3World_IsContinuousEnabled( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->enableContinuous;
}

void b3World_SetRestitutionThreshold( b3WorldId worldId, float value )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldSetRestitutionThreshold, worldId, value );

	world->restitutionThreshold = b3ClampFloat( value, 0.0f, FLT_MAX );
}

float b3World_GetRestitutionThreshold( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->restitutionThreshold;
}

void b3World_SetHitEventThreshold( b3WorldId worldId, float value )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldSetHitEventThreshold, worldId, value );

	world->hitEventThreshold = b3ClampFloat( value, 0.0f, FLT_MAX );
}

float b3World_GetHitEventThreshold( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->hitEventThreshold;
}

void b3World_SetContactTuning( b3WorldId worldId, float hertz, float dampingRatio, float contactSpeed )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldSetContactTuning, worldId, hertz, dampingRatio, contactSpeed );

	world->contactHertz = b3ClampFloat( hertz, 0.0f, FLT_MAX );
	world->contactDampingRatio = b3ClampFloat( dampingRatio, 0.0f, FLT_MAX );
	world->contactSpeed = b3ClampFloat( contactSpeed, 0.0f, FLT_MAX );
}

void b3World_SetContactRecycleDistance( b3WorldId worldId, float recycleDistance )
{
	b3World* world = b3GetWorldFromId( worldId );
	B3_ASSERT( world->locked == false );
	if ( world->locked )
	{
		return;
	}

	B3_REC( world, WorldSetContactRecycleDistance, worldId, recycleDistance );

	world->contactRecycleDistance = b3ClampFloat( recycleDistance, 0.0f, FLT_MAX );
}

float b3World_GetContactRecycleDistance( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->contactRecycleDistance;
}

void b3World_SetMaximumLinearSpeed( b3WorldId worldId, float maximumLinearSpeed )
{
	B3_ASSERT( b3IsValidFloat( maximumLinearSpeed ) && maximumLinearSpeed > 0.0f );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldSetMaximumLinearSpeed, worldId, maximumLinearSpeed );

	world->maxLinearSpeed = maximumLinearSpeed;
}

float b3World_GetMaximumLinearSpeed( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->maxLinearSpeed;
}

b3Profile b3World_GetProfile( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3Profile){ 0 };
	}
	return world->profile;
}

b3Counters b3World_GetCounters( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3Counters){ 0 };
	}

	b3Counters s = { 0 };
	s.bodyCount = b3GetIdCount( &world->bodyIdPool );
	s.shapeCount = b3GetIdCount( &world->shapeIdPool );
	s.contactCount = b3GetIdCount( &world->contactIdPool );
	s.jointCount = b3GetIdCount( &world->jointIdPool );
	s.islandCount = b3GetIdCount( &world->islandIdPool );

	b3DynamicTree* staticTree = world->broadPhase.trees + b3_staticBody;
	s.staticTreeHeight = b3DynamicTree_GetHeight( staticTree );

	b3DynamicTree* dynamicTree = world->broadPhase.trees + b3_dynamicBody;
	b3DynamicTree* kinematicTree = world->broadPhase.trees + b3_kinematicBody;
	s.treeHeight = b3MaxInt( b3DynamicTree_GetHeight( dynamicTree ), b3DynamicTree_GetHeight( kinematicTree ) );

	s.satCallCount = world->satCallCount;
	s.satCacheHitCount = world->satCacheHitCount;
	memcpy( s.manifoldCounts, world->manifoldCounts, B3_CONTACT_MANIFOLD_COUNT_BUCKETS * sizeof( int ) );
	s.stackUsed = world->stack.maxAllocation;
	s.byteCount = b3GetByteCount();
	s.taskCount = world->taskCount;

	_Static_assert( B3_GRAPH_COLOR_COUNT == sizeof( s.colorCounts ) / sizeof( s.colorCounts[0] ), "colorCounts size mismatch" );

	s.awakeContactCount = 0;
	for ( int i = 0; i < B3_GRAPH_COLOR_COUNT; ++i )
	{
		b3GraphColor* color = world->constraintGraph.colors + i;
		int colorContactCount = color->convexContacts.count + color->contacts.count;
		s.colorCounts[i] = colorContactCount + color->jointSims.count;
		s.awakeContactCount += colorContactCount;
	}
	s.awakeContactCount += world->solverSets.data[b3_awakeSet].contactIndices.count;

	s.recycledContactCount = 0;
	s.arenaCapacity = 0;
	s.distanceIterations = 0;
	s.pushBackIterations = 0;
	s.rootIterations = 0;
	for ( int i = 0; i < world->workerCount; ++i )
	{
		s.recycledContactCount += world->taskContexts.data[i].recycledContactCount;

		s.distanceIterations = b3MaxInt( s.distanceIterations, world->taskContexts.data[i].distanceIterations );
		s.pushBackIterations = b3MaxInt( s.pushBackIterations, world->taskContexts.data[i].pushBackIterations );
		s.rootIterations = b3MaxInt( s.rootIterations, world->taskContexts.data[i].rootIterations );

		int peak = world->taskContexts.data[i].arena.shared->peakDemand;
		if ( peak > s.arenaCapacity )
		{
			s.arenaCapacity = peak;
		}
	}

	return s;
}

b3Capacity b3World_GetMaxCapacity( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return (b3Capacity){ 0 };
	}
	return world->maxCapacity;
}

void b3World_SetUserData( b3WorldId worldId, void* userData )
{
	b3World* world = b3GetWorldFromId( worldId );
	world->userData = userData;
}

void* b3World_GetUserData( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->userData;
}

void b3World_SetFrictionCallback( b3WorldId worldId, b3FrictionCallback* callback )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	world->frictionCallback = callback != NULL ? callback : b3DefaultFrictionCallback;
}

void b3World_SetRestitutionCallback( b3WorldId worldId, b3RestitutionCallback* callback )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	world->restitutionCallback = callback != NULL ? callback : b3DefaultRestitutionCallback;
}

void b3World_SetWorkerCount( b3WorldId worldId, int count )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	if ( count == world->workerCount )
	{
		return;
	}

	b3DestroyWorkerContexts( world );
	world->workerCount = b3ClampInt( count, 1, B3_MAX_WORKERS );
	b3CreateWorkerContexts( world );
}

int b3World_GetWorkerCount( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return 0;
	}

	return world->workerCount;
}

void b3World_StartRecording( b3WorldId worldId, b3Recording* recording )
{
	// Must be a step boundary, so refuse a locked world
	b3World* world = b3GetUnlockedWorldFromId( worldId );

	if ( world == NULL || recording == NULL || world->recording != NULL )
	{
		return;
	}

	b3StartRecordingIntoBuffer( world, recording );
}

void b3World_StopRecording( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	b3StopRecordingInternal( world );
}

void b3World_DumpMemoryStats( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	// Large worlds can exceed 2GB, sum in 64 bits
	uint64_t total = 0;

	// id pools
	int bodyIdBytes = b3GetIdBytes( &world->bodyIdPool );
	int solverSetIdBytes = b3GetIdBytes( &world->solverSetIdPool );
	int jointIdBytes = b3GetIdBytes( &world->jointIdPool );
	int contactIdBytes = b3GetIdBytes( &world->contactIdPool );
	int islandIdBytes = b3GetIdBytes( &world->islandIdPool );
	int shapeIdBytes = b3GetIdBytes( &world->shapeIdPool );
	total += (uint64_t)bodyIdBytes + solverSetIdBytes + jointIdBytes + contactIdBytes + islandIdBytes + shapeIdBytes;

	b3Log( "id pools" );
	b3Log( "body ids: %d", bodyIdBytes );
	b3Log( "solver set ids: %d", solverSetIdBytes );
	b3Log( "joint ids: %d", jointIdBytes );
	b3Log( "contact ids: %d", contactIdBytes );
	b3Log( "island ids: %d", islandIdBytes );
	b3Log( "shape ids: %d", shapeIdBytes );

	// Islands own per-island body/contact/joint link arrays
	int islandLinkBytes = 0;
	for ( int i = 0; i < world->islands.count; ++i )
	{
		b3Island* island = world->islands.data + i;
		islandLinkBytes += b3Array_ByteCount( island->bodies );
		islandLinkBytes += b3Array_ByteCount( island->contacts );
		islandLinkBytes += b3Array_ByteCount( island->joints );
	}

	// world arrays
	int bodyArrayBytes = b3Array_ByteCount( world->bodies );
	int solverSetArrayBytes = b3Array_ByteCount( world->solverSets );
	int jointArrayBytes = b3Array_ByteCount( world->joints );
	int contactArrayBytes = b3Array_ByteCount( world->contacts );
	int islandArrayBytes = b3Array_ByteCount( world->islands );
	int shapeArrayBytes = b3Array_ByteCount( world->shapes );
	int sensorArrayBytes = b3Array_ByteCount( world->sensors );
	total += (uint64_t)bodyArrayBytes + solverSetArrayBytes + jointArrayBytes + contactArrayBytes + islandArrayBytes +
			 islandLinkBytes + shapeArrayBytes + sensorArrayBytes;

	b3Log( "world arrays" );
	b3Log( "bodies: %d", bodyArrayBytes );
	b3Log( "solver sets: %d", solverSetArrayBytes );
	b3Log( "joints: %d", jointArrayBytes );
	b3Log( "contacts: %d", contactArrayBytes );
	b3Log( "islands: %d", islandArrayBytes );
	b3Log( "island links: %d", islandLinkBytes );
	b3Log( "shapes: %d", shapeArrayBytes );
	b3Log( "sensors: %d", sensorArrayBytes );

	// Sensors own overlap tracking arrays. The sensor array is dense.
	int sensorOverlapBytes = 0;
	for ( int i = 0; i < world->sensors.count; ++i )
	{
		b3Sensor* sensor = world->sensors.data + i;
		sensorOverlapBytes += b3Array_ByteCount( sensor->hits );
		sensorOverlapBytes += b3Array_ByteCount( sensor->overlaps1 );
		sensorOverlapBytes += b3Array_ByteCount( sensor->overlaps2 );
	}
	total += sensorOverlapBytes;

	b3Log( "owned arrays" );
	b3Log( "sensor overlaps: %d", sensorOverlapBytes );

	// Shared hull database. The map owns a combined bucket and metadata allocation
	// plus the small map struct. Each stored key is an owned clone sized by byteCount.
	b3HullMap* hullDatabase = world->hullDatabase;
	int hullCount = (int)b3HullMap_size( hullDatabase );
	int hullBucketCount = (int)b3HullMap_bucket_count( hullDatabase );
	uint64_t hullMapBytes = b3HullMapByteCount( hullDatabase );
	uint64_t hullDataBytes = 0;
	for ( b3HullMap_itr itr = b3HullMap_first( hullDatabase ); b3HullMap_is_end( itr ) == false; itr = b3HullMap_next( itr ) )
	{
		hullDataBytes += itr.data->key->byteCount;
	}
	total += hullMapBytes + hullDataBytes;

	b3Log( "hulls" );
	b3Log( "database: %d (%d, %d)", (int)hullMapBytes, hullCount, hullBucketCount );
	b3Log( "hull data: %d", (int)hullDataBytes );

	// broad-phase
	int staticTreeBytes = b3DynamicTree_GetByteCount( world->broadPhase.trees + b3_staticBody );
	int kinematicTreeBytes = b3DynamicTree_GetByteCount( world->broadPhase.trees + b3_kinematicBody );
	int dynamicTreeBytes = b3DynamicTree_GetByteCount( world->broadPhase.trees + b3_dynamicBody );
	int movedBytes = 0;
	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		movedBytes += b3GetBitSetBytes( &world->broadPhase.movedProxies[i] );
	}
	int moveArrayBytes = b3Array_ByteCount( world->broadPhase.moveArray );
	b3HashSet* pairSet = &world->broadPhase.pairSet;
	int pairSetBytes = b3GetHashSetBytes( pairSet );
	total += (uint64_t)staticTreeBytes + kinematicTreeBytes + dynamicTreeBytes + movedBytes + moveArrayBytes + pairSetBytes;

	b3Log( "broad-phase" );
	b3Log( "static tree: %d", staticTreeBytes );
	b3Log( "kinematic tree: %d", kinematicTreeBytes );
	b3Log( "dynamic tree: %d", dynamicTreeBytes );
	b3Log( "movedProxies: %d", movedBytes );
	b3Log( "moveArray: %d", moveArrayBytes );
	b3Log( "pairSet: %d (%d, %d)", pairSetBytes, pairSet->count, pairSet->capacity );

	// Manifold block allocators, one per manifold point count
	int manifoldArrayBytes = b3Array_ByteCount( world->manifoldAllocators );
	int manifoldBlockBytes = 0;
	for ( int i = 0; i < world->manifoldAllocators.count; ++i )
	{
		b3BlockAllocator* allocator = world->manifoldAllocators.data + i;
		manifoldBlockBytes += b3Array_ByteCount( allocator->blocks );
		manifoldBlockBytes += allocator->blocks.count * B3_BLOCK_SIZE * allocator->elementSize;
	}
	total += (uint64_t)manifoldArrayBytes + manifoldBlockBytes;

	b3Log( "manifold allocators" );
	b3Log( "allocator array: %d", manifoldArrayBytes );
	b3Log( "blocks: %d", manifoldBlockBytes );

	// solver sets
	int bodySimCapacity = 0;
	int bodyStateCapacity = 0;
	int jointSimCapacity = 0;
	int contactIndexCapacity = 0;
	int islandSimCapacity = 0;
	int solverSetCapacity = world->solverSets.count;
	for ( int i = 0; i < solverSetCapacity; ++i )
	{
		b3SolverSet* set = world->solverSets.data + i;
		if ( set->setIndex == B3_NULL_INDEX )
		{
			continue;
		}

		bodySimCapacity += set->bodySims.capacity;
		bodyStateCapacity += set->bodyStates.capacity;
		jointSimCapacity += set->jointSims.capacity;
		contactIndexCapacity += set->contactIndices.capacity;
		islandSimCapacity += set->islandSims.capacity;
	}

	int setBodySimBytes = bodySimCapacity * (int)sizeof( b3BodySim );
	int setBodyStateBytes = bodyStateCapacity * (int)sizeof( b3BodyState );
	int setJointSimBytes = jointSimCapacity * (int)sizeof( b3JointSim );
	int setContactSimBytes = contactIndexCapacity * (int)sizeof( int );
	int setIslandSimBytes = islandSimCapacity * (int)sizeof( b3IslandSim );
	total += (uint64_t)setBodySimBytes + setBodyStateBytes + setJointSimBytes + setContactSimBytes + setIslandSimBytes;

	b3Log( "solver sets" );
	b3Log( "body sim: %d", setBodySimBytes );
	b3Log( "body state: %d", setBodyStateBytes );
	b3Log( "joint sim: %d", setJointSimBytes );
	b3Log( "contact sim: %d", setContactSimBytes );
	b3Log( "island sim: %d", setIslandSimBytes );

	// constraint graph
	int bodyBitSetBytes = 0;
	int graphContactBytes = 0;
	int graphJointSimBytes = 0;
	for ( int i = 0; i < B3_GRAPH_COLOR_COUNT; ++i )
	{
		b3GraphColor* c = world->constraintGraph.colors + i;
		bodyBitSetBytes += b3GetBitSetBytes( &c->bodySet );
		graphContactBytes += b3Array_ByteCount( c->convexContacts ) + b3Array_ByteCount( c->contacts );
		graphJointSimBytes += b3Array_ByteCount( c->jointSims );
	}
	total += (uint64_t)bodyBitSetBytes + graphJointSimBytes + graphContactBytes;

	b3Log( "constraint graph" );
	b3Log( "body bit sets: %d", bodyBitSetBytes );
	b3Log( "joint sim: %d", graphJointSimBytes );
	b3Log( "contact sim: %d", graphContactBytes );

	// Per worker task storage and its bit sets
	int taskContextBytes = b3Array_ByteCount( world->taskContexts );
	for ( int i = 0; i < world->taskContexts.count; ++i )
	{
		b3TaskContext* taskContext = world->taskContexts.data + i;
		taskContextBytes += b3Array_ByteCount( taskContext->sensorHits );
		taskContextBytes += b3GetBitSetBytes( &taskContext->contactStateBitSet );
		taskContextBytes += b3GetBitSetBytes( &taskContext->jointStateBitSet );
		taskContextBytes += b3GetBitSetBytes( &taskContext->hitEventBitSet );
		taskContextBytes += b3GetBitSetBytes( &taskContext->enlargedSimBitSet );
		taskContextBytes += b3GetBitSetBytes( &taskContext->awakeIslandBitSet );
	}

	int sensorTaskContextBytes = b3Array_ByteCount( world->sensorTaskContexts );
	for ( int i = 0; i < world->sensorTaskContexts.count; ++i )
	{
		b3SensorTaskContext* taskContext = world->sensorTaskContexts.data + i;
		sensorTaskContextBytes += b3GetBitSetBytes( &taskContext->eventBits );
	}
	total += (uint64_t)taskContextBytes + sensorTaskContextBytes;

	b3Log( "task contexts" );
	b3Log( "worker: %d", taskContextBytes );
	b3Log( "sensor: %d", sensorTaskContextBytes );

	// Double buffered event arrays
	int eventBytes = 0;
	eventBytes += b3Array_ByteCount( world->bodyMoveEvents );
	eventBytes += b3Array_ByteCount( world->sensorBeginEvents );
	eventBytes += b3Array_ByteCount( world->contactBeginEvents );
	eventBytes += b3Array_ByteCount( world->sensorEndEvents[0] );
	eventBytes += b3Array_ByteCount( world->sensorEndEvents[1] );
	eventBytes += b3Array_ByteCount( world->contactEndEvents[0] );
	eventBytes += b3Array_ByteCount( world->contactEndEvents[1] );
	eventBytes += b3Array_ByteCount( world->contactHitEvents );
	eventBytes += b3Array_ByteCount( world->jointEvents );
	total += eventBytes;

	b3Log( "events: %d", eventBytes );

	// Debug draw bit sets
	int debugBytes = 0;
	debugBytes += b3GetBitSetBytes( &world->debugBodySet );
	debugBytes += b3GetBitSetBytes( &world->debugJointSet );
	debugBytes += b3GetBitSetBytes( &world->debugContactSet );
	debugBytes += b3GetBitSetBytes( &world->debugIslandSet );
	total += debugBytes;

	b3Log( "debug draw: %d", debugBytes );

	// stack allocator
	total += world->stack.capacity;
	b3Log( "stack allocator: %d", world->stack.capacity );

	b3Log( "total: %u KB", (uint32_t)( total / 1024 ) );
}

typedef struct WorldQueryContext
{
	b3World* world;
	b3OverlapResultFcn* fcn;
	b3QueryFilter filter;
	void* userContext;
} WorldQueryContext;

static bool TreeQueryCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldQueryContext* worldContext = (WorldQueryContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );

	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return true;
	}

	b3ShapeId id = { shapeId + 1, world->worldId, shape->generation };
	bool result = worldContext->fcn( id, worldContext->userContext );
	return result;
}

b3TreeStats b3World_OverlapAABB( b3WorldId worldId, b3AABB aabb, b3QueryFilter filter, b3OverlapResultFcn* fcn, void* context )
{
	b3TreeStats treeStats = { 0 };

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return treeStats;
	}

	B3_ASSERT( b3IsValidAABB( aabb ) );

	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.overlapFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_AABB( &recWriter.buf, aabb );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecOverlapTrampoline;
		context = &recWriter;
	}

	WorldQueryContext worldContext = { world, fcn, filter, context };

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3TreeStats treeResult =
			b3DynamicTree_Query( world->broadPhase.trees + i, aabb, filter.maskBits, false, TreeQueryCallback, &worldContext );

		treeStats.nodeVisits += treeResult.nodeVisits;
		treeStats.leafVisits += treeResult.leafVisits;
	}

	if ( world->recording != NULL )
	{
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecW_TREESTATS( &recWriter.buf, treeStats );
		b3RecQueryCommit( world->recording, b3_recOpQueryOverlapAABB, &recWriter );
	}

	return treeStats;
}

typedef struct WorldOverlapContext
{
	b3World* world;
	b3OverlapResultFcn* fcn;
	b3QueryFilter filter;
	b3ShapeProxy proxy;
	b3Pos origin;
	void* userContext;
} WorldOverlapContext;

static bool b3TreeOverlapCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldOverlapContext* worldContext = (WorldOverlapContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );

	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return true;
	}

	// Re-center on the query origin so the overlap test stays in float precision far from the origin
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3Transform transform = b3ToRelativeTransform( b3GetBodyTransformQuick( world, body ), worldContext->origin );

	bool overlapping = b3OverlapShape( shape, transform, &worldContext->proxy );
	if ( overlapping == false )
	{
		return true;
	}

	b3ShapeId id = { shape->id + 1, world->worldId, shape->generation };
	bool result = worldContext->fcn( id, worldContext->userContext );
	return result;
}

b3TreeStats b3World_OverlapShape( b3WorldId worldId, b3Pos origin, const b3ShapeProxy* proxy, b3QueryFilter filter,
								  b3OverlapResultFcn* fcn, void* context )
{
	b3TreeStats treeStats = { 0 };

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return treeStats;
	}

	B3_ASSERT( b3IsValidPosition( origin ) );

	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.overlapFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_SHAPEPROXY( &recWriter.buf, *proxy );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecOverlapTrampoline;
		context = &recWriter;
	}

	// Bound the proxy in origin relative space then lift to a conservative world float box
	b3AABB aabb = b3OffsetAABB( b3MakeAABB( proxy->points, proxy->count, proxy->radius ), origin );
	WorldOverlapContext worldContext = {
		world, fcn, filter, *proxy, origin, context,
	};

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3TreeStats treeResult = b3DynamicTree_Query( world->broadPhase.trees + i, aabb, filter.maskBits, false,
													  b3TreeOverlapCallback, &worldContext );

		treeStats.nodeVisits += treeResult.nodeVisits;
		treeStats.leafVisits += treeResult.leafVisits;
	}

	if ( world->recording != NULL )
	{
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecW_TREESTATS( &recWriter.buf, treeStats );
		b3RecQueryCommit( world->recording, b3_recOpQueryOverlapShape, &recWriter );
	}

	return treeStats;
}

typedef struct WorldMoverContext
{
	b3World* world;
	b3PlaneResultFcn* fcn;
	b3QueryFilter filter;
	b3Capsule mover;
	b3Pos origin;
	void* userContext;
} WorldMoverContext;

static bool TreeCollideCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldMoverContext* worldContext = (WorldMoverContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );

	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return true;
	}

	// Re-center on the query origin, the mover and the resulting planes are origin relative
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3WorldTransform bodyTransform = b3GetBodyTransformQuick( world, body );
	b3Transform transform = b3ToRelativeTransform( bodyTransform, worldContext->origin );

	b3PlaneResult buffer[64];
	int count = b3CollideMover( buffer, 64, shape, transform, &worldContext->mover );

	if ( count > 0 )
	{
		b3ShapeId id = { shape->id + 1, world->worldId, shape->generation };
		return worldContext->fcn( id, buffer, count, worldContext->userContext );
	}

	return true;
}

// It is tempting to use a shape proxy for the mover, but this makes handling deep overlap difficult and the generality may
// not be worth it.
void b3World_CollideMover( b3WorldId worldId, b3Pos origin, const b3Capsule* mover, b3QueryFilter filter, b3PlaneResultFcn* fcn,
						   void* context )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_ASSERT( b3IsValidPosition( origin ) );

	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.planeFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_CAPSULE( &recWriter.buf, *mover );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecPlaneTrampoline;
		context = &recWriter;
	}

	b3Vec3 r = { mover->radius, mover->radius, mover->radius };

	// Relative box lifted to world float with outward rounding, conservative for the tree
	b3AABB relBox;
	relBox.lowerBound = b3Sub( b3Min( mover->center1, mover->center2 ), r );
	relBox.upperBound = b3Add( b3Max( mover->center1, mover->center2 ), r );
	b3AABB aabb = b3OffsetAABB( relBox, origin );

	WorldMoverContext worldContext = {
		world, fcn, filter, *mover, origin, context,
	};

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3DynamicTree_Query( world->broadPhase.trees + i, aabb, filter.maskBits, false, TreeCollideCallback, &worldContext );
	}

	if ( world->recording != NULL )
	{
		// CollideMover returns void: no treestats tail, just the per-shape plane batches.
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecQueryCommit( world->recording, b3_recOpQueryCollideMover, &recWriter );
	}
}

typedef struct WorldRayCastContext
{
	b3World* world;
	b3CastResultFcn* fcn;
	b3QueryFilter filter;
	float fraction;
	b3Pos origin;
	void* userContext;
} WorldRayCastContext;

static float RayCastCallback( const b3RayCastInput* input, int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldRayCastContext* worldContext = (WorldRayCastContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );
	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return input->maxFraction;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3WorldTransform bodyTransform = b3GetBodyTransformQuick( world, body );
	b3Transform transform = b3ToRelativeTransform( bodyTransform, worldContext->origin );

	b3RayCastInput localInput = *input;
	localInput.origin = b3Vec3_zero;
	b3CastOutput output = b3RayCastShape( shape, transform, &localInput );

	if ( output.hit )
	{
		B3_ASSERT( output.fraction <= input->maxFraction );

		b3ShapeId id = { shapeId + 1, world->worldId, shape->generation };
		b3Pos point = b3OffsetPos( worldContext->origin, output.point );
		int materialIndex = b3ClampInt( output.materialIndex, 0, shape->materialCount - 1 );
		uint64_t userMaterialId = b3GetShapeMaterials( shape )[materialIndex].userMaterialId;

		int triangleIndex = output.triangleIndex;
		int childIndex = output.childIndex;
		float fraction = worldContext->fcn( id, point, output.normal, output.fraction, userMaterialId, triangleIndex, childIndex,
											worldContext->userContext );

		// The user may return -1 to skip this shape
		if ( 0.0f <= fraction && fraction <= 1.0f )
		{
			worldContext->fraction = fraction;
		}

		return fraction;
	}

	return input->maxFraction;
}

b3TreeStats b3World_CastRay( b3WorldId worldId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter, b3CastResultFcn* fcn,
							 void* context )
{
	b3TreeStats treeStats = { 0 };

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return treeStats;
	}

	B3_ASSERT( b3IsValidPosition( origin ) );
	B3_ASSERT( b3IsValidVec3( translation ) );

	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.castFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_VEC3( &recWriter.buf, translation );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecCastTrampoline;
		context = &recWriter;
	}

	// The tree traverses in float relative to the world origin. Each shape is then re-differenced at
	// full precision against the origin, so a hit stays accurate far from the origin.
	b3RayCastInput input = { b3ToVec3( origin ), translation, 1.0f };

	WorldRayCastContext worldContext = { world, fcn, filter, 1.0f, origin, context };

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3TreeStats treeResult =
			b3DynamicTree_RayCast( world->broadPhase.trees + i, &input, filter.maskBits, false, RayCastCallback, &worldContext );
		treeStats.nodeVisits += treeResult.nodeVisits;
		treeStats.leafVisits += treeResult.leafVisits;

		if ( worldContext.fraction == 0.0f )
		{
			break;
		}

		input.maxFraction = worldContext.fraction;
	}

	if ( world->recording != NULL )
	{
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecW_TREESTATS( &recWriter.buf, treeStats );
		b3RecQueryCommit( world->recording, b3_recOpQueryCastRay, &recWriter );
	}

	return treeStats;
}

// This callback finds the closest hit. This is the most common callback used in games.
static float b3RayCastClosestFcn( b3ShapeId shapeId, b3Pos point, b3Vec3 normal, float fraction, uint64_t userMaterialId,
								  int triangleIndex, int childIndex, void* context )
{
	// Ignore initial overlap
	if ( fraction == 0.0f )
	{
		return -1.0f;
	}

	b3RayResult* rayResult = (b3RayResult*)context;
	rayResult->shapeId = shapeId;
	rayResult->point = point;
	rayResult->normal = normal;
	rayResult->fraction = fraction;
	rayResult->userMaterialId = userMaterialId;
	rayResult->triangleIndex = triangleIndex;
	rayResult->childIndex = childIndex;
	rayResult->hit = true;
	return fraction;
}

b3RayResult b3World_CastRayClosest( b3WorldId worldId, b3Pos origin, b3Vec3 translation, b3QueryFilter filter )
{
	b3RayResult result = { 0 };

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return result;
	}

	B3_ASSERT( b3IsValidPosition( origin ) );
	B3_ASSERT( b3IsValidVec3( translation ) );

	// The tree traverses in float relative to the world origin. Each shape is then re-differenced at
	// full precision against its body, so a hit stays accurate far from the origin.
	b3RayCastInput input = { b3ToVec3( origin ), translation, 1.0f };
	WorldRayCastContext worldContext = {
		.world = world,
		.fcn = b3RayCastClosestFcn,
		.filter = filter,
		.fraction = 1.0f,
		.origin = origin,
		.userContext = &result,
	};

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3TreeStats treeResult =
			b3DynamicTree_RayCast( world->broadPhase.trees + i, &input, filter.maskBits, false, RayCastCallback, &worldContext );
		result.nodeVisits += treeResult.nodeVisits;
		result.leafVisits += treeResult.leafVisits;

		if ( worldContext.fraction == 0.0f )
		{
			break;
		}

		input.maxFraction = worldContext.fraction;
	}

	// Closed query, no user callback: record the inputs and the single result for the replay compare.
	if ( world->recording != NULL )
	{
		b3RecQueryWriter recWriter = { 0 };
		b3RecQueryBegin( &recWriter, NULL, filter.id, filter.name );
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_VEC3( &recWriter.buf, translation );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		b3RecW_RAYRESULT( &recWriter.buf, result );
		b3RecQueryCommit( world->recording, b3_recOpQueryCastRayClosest, &recWriter );
	}

	return result;
}

typedef struct WorldShapeCastContext
{
	b3World* world;
	b3CastResultFcn* fcn;
	b3QueryFilter filter;
	float fraction;
	b3Pos origin;
	// origin relative input
	b3ShapeCastInput input;
	void* userContext;
} WorldShapeCastContext;

static float b3ShapeCastCallback( const b3BoxCastInput* input, int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldShapeCastContext* worldContext = (WorldShapeCastContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );
	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return input->maxFraction;
	}

	// Rebuild from the origin relative input, taking only the advancing fraction from the tree.
	// The tree box is world float and would lose the cast far from the origin.
	b3ShapeCastInput localInput = worldContext->input;
	localInput.maxFraction = input->maxFraction;

	// Re-center on the query origin so the per-shape cast stays in float precision far from the origin
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3Transform transform = b3ToRelativeTransform( b3GetBodyTransformQuick( world, body ), worldContext->origin );

	b3CastOutput output = b3ShapeCastShape( shape, transform, &localInput );

	if ( output.hit )
	{
		b3ShapeId id = { shapeId + 1, world->worldId, shape->generation };
		int materialIndex = b3ClampInt( output.materialIndex, 0, shape->materialCount - 1 );
		uint64_t userMaterialId = b3GetShapeMaterials( shape )[materialIndex].userMaterialId;

		int triangleIndex = output.triangleIndex;
		int childIndex = output.childIndex;
		float fraction = worldContext->fcn( id, b3OffsetPos( worldContext->origin, output.point ), output.normal, output.fraction,
											userMaterialId, triangleIndex, childIndex, worldContext->userContext );

		// The user may return -1 to skip this shape
		if ( 0.0f <= fraction && fraction <= 1.0f )
		{
			worldContext->fraction = fraction;
		}

		return fraction;
	}

	return input->maxFraction;
}

b3TreeStats b3World_CastShape( b3WorldId worldId, b3Pos origin, const b3ShapeProxy* proxy, b3Vec3 translation,
							   b3QueryFilter filter, b3CastResultFcn* fcn, void* context )
{
	b3TreeStats treeStats = { 0 };

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return treeStats;
	}

	B3_ASSERT( b3IsValidPosition( origin ) );
	B3_ASSERT( b3IsValidVec3( translation ) );

	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.castFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_SHAPEPROXY( &recWriter.buf, *proxy );
		b3RecW_VEC3( &recWriter.buf, translation );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecCastTrampoline;
		context = &recWriter;
	}

	WorldShapeCastContext worldContext = { 0 };
	worldContext.world = world;
	worldContext.fcn = fcn;
	worldContext.filter = filter;
	worldContext.fraction = 1.0f;
	worldContext.origin = origin;
	worldContext.input.proxy = *proxy;
	worldContext.input.translation = translation;
	worldContext.input.maxFraction = 1.0f;
	worldContext.input.canEncroach = false;
	worldContext.userContext = context;

	// Bound the proxy in origin relative space then lift to a conservative world float box. The tree
	// node boxes use the same directed rounding, so the swept box never clips a shape far from the
	// origin. Per shape casts re-difference at full precision against the carried origin.
	b3AABB localBox = b3MakeAABB( proxy->points, proxy->count, proxy->radius );
	b3BoxCastInput treeInput = { b3OffsetAABB( localBox, origin ), translation, 1.0f };

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3TreeStats treeResult = b3DynamicTree_BoxCast( world->broadPhase.trees + i, &treeInput, filter.maskBits, false,
														b3ShapeCastCallback, &worldContext );
		treeStats.nodeVisits += treeResult.nodeVisits;
		treeStats.leafVisits += treeResult.leafVisits;

		if ( worldContext.fraction == 0.0f )
		{
			break;
		}

		treeInput.maxFraction = worldContext.fraction;
	}

	if ( world->recording != NULL )
	{
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecW_TREESTATS( &recWriter.buf, treeStats );
		b3RecQueryCommit( world->recording, b3_recOpQueryCastShape, &recWriter );
	}

	return treeStats;
}

typedef struct WorldMoverCastContext
{
	b3World* world;
	b3MoverFilterFcn* fcn;
	b3QueryFilter filter;
	float fraction;
	b3Pos origin;
	// origin relative input
	b3ShapeCastInput input;
	void* userContext;
} WorldMoverCastContext;

static float MoverCastCallback( const b3BoxCastInput* input, int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	WorldMoverCastContext* worldContext = (WorldMoverCastContext*)context;
	b3World* world = worldContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );
	b3Filter shapeFilter = shape->filter;
	b3QueryFilter queryFilter = worldContext->filter;

	if ( b3ShouldQueryCollide( &shapeFilter, &queryFilter ) == false )
	{
		return worldContext->fraction;
	}

	if ( worldContext->fcn != NULL )
	{
		b3ShapeId id = { shapeId + 1, world->worldId, shape->generation };
		bool shouldCollide = worldContext->fcn( id, worldContext->userContext );
		if ( shouldCollide == false )
		{
			return worldContext->fraction;
		}
	}

	// Rebuild from the origin relative input, taking only the advancing fraction from the tree
	b3ShapeCastInput localInput = worldContext->input;
	localInput.maxFraction = input->maxFraction;

	// Re-center on the query origin so the per-shape cast stays in float precision far from the origin
	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	b3Transform transform = b3ToRelativeTransform( b3GetBodyTransformQuick( world, body ), worldContext->origin );

	b3CastOutput output = b3ShapeCastShape( shape, transform, &localInput );
	if ( output.fraction == 0.0f )
	{
		// Ignore overlapping shapes
		return worldContext->fraction;
	}

	worldContext->fraction = output.fraction;
	return output.fraction;
}

float b3World_CastMover( b3WorldId worldId, b3Pos origin, const b3Capsule* mover, b3Vec3 translation, b3QueryFilter filter,
						 b3MoverFilterFcn* fcn, void* context )
{
	B3_ASSERT( b3IsValidPosition( origin ) );
	B3_ASSERT( b3IsValidVec3( translation ) );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return 1.0f;
	}

	// The mover filter is a per-shape bool(shapeId, ctx) decision, the same shape as an overlap
	// callback, so the overlap trampoline captures it. Installing it even when the user passed no
	// filter records an accept-all stream that replays identically.
	b3RecQueryWriter recWriter = { 0 };
	if ( world->recording != NULL )
	{
		b3RecQueryBegin( &recWriter, context, filter.id, filter.name );
		recWriter.userFcn.moverFilterFcn = fcn;
		b3RecW_WORLDID( &recWriter.buf, worldId );
		b3RecW_POSITION( &recWriter.buf, origin );
		b3RecW_CAPSULE( &recWriter.buf, *mover );
		b3RecW_VEC3( &recWriter.buf, translation );
		b3RecW_QUERYFILTER( &recWriter.buf, filter );
		recWriter.countOffset = b3RecReserveU32( &recWriter.buf );
		fcn = b3RecOverlapTrampoline;
		context = &recWriter;
	}

	WorldMoverCastContext worldContext = {
		.world = world,
		.fcn = fcn,
		.filter = filter,
		.fraction = 1.0f,
		.origin = origin,
		.userContext = context,
	};
	worldContext.input.proxy = (b3ShapeProxy){ &mover->center1, 2, mover->radius };
	worldContext.input.translation = translation;
	worldContext.input.maxFraction = 1.0f;
	worldContext.input.canEncroach = mover->radius > 0.0f;

	// Bound the capsule in origin relative space then lift to a conservative world float box
	b3Vec3 centers[2] = { mover->center1, mover->center2 };
	b3BoxCastInput treeInput = { b3OffsetAABB( b3MakeAABB( centers, 2, mover->radius ), origin ), translation, 1.0f };

	for ( int i = 0; i < b3_bodyTypeCount; ++i )
	{
		b3DynamicTree_BoxCast( world->broadPhase.trees + i, &treeInput, filter.maskBits, false, MoverCastCallback,
							   &worldContext );

		if ( worldContext.fraction == 0.0f )
		{
			break;
		}

		treeInput.maxFraction = worldContext.fraction;
	}

	if ( world->recording != NULL )
	{
		// The mover filter type aliases the overlap trampoline, so the user fcn lands in the same
		// union slot. Backpatch the accept count, then record the returned fraction as the tail.
		b3RecPatchU32( &recWriter.buf, recWriter.countOffset, recWriter.hitCount );
		b3RecW_F32( &recWriter.buf, worldContext.fraction );
		b3RecQueryCommit( world->recording, b3_recOpQueryCastMover, &recWriter );
	}

	return worldContext.fraction;
}

void b3World_SetCustomFilterCallback( b3WorldId worldId, b3CustomFilterFcn* fcn, void* context )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}
	world->customFilterFcn = fcn;
	world->customFilterContext = context;
}

void b3World_SetPreSolveCallback( b3WorldId worldId, b3PreSolveFcn* fcn, void* context )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}
	world->preSolveFcn = fcn;
	world->preSolveContext = context;
}

void b3World_SetGravity( b3WorldId worldId, b3Vec3 gravity )
{
	b3World* world = b3GetWorldFromId( worldId );

	B3_REC( world, WorldSetGravity, worldId, gravity );

	world->gravity = gravity;
}

b3Vec3 b3World_GetGravity( b3WorldId worldId )
{
	b3World* world = b3GetWorldFromId( worldId );
	return world->gravity;
}

typedef struct ExplosionContext
{
	b3World* world;
	b3Pos position;
	float radius;
	float falloff;
	float impulsePerArea;
} ExplosionContext;

static bool ExplosionCallback( int proxyId, uint64_t userData, void* context )
{
	B3_UNUSED( proxyId );

	int shapeId = (int)userData;
	ExplosionContext* explosionContext = (ExplosionContext*)context;
	b3World* world = explosionContext->world;

	b3Shape* shape = b3Array_Get( world->shapes, shapeId );
	if ( shape->explosionScale == 0.0f )
	{
		return true;
	}

	b3Body* body = b3Array_Get( world->bodies, shape->bodyId );
	B3_ASSERT( body->type == b3_dynamicBody );

	b3WorldTransform xf = b3GetBodyTransformQuick( world, body );

	// Re-center the explosion into the shape local frame so distance and direction stay precise
	// far from the origin. Everything below runs in that near-origin frame.
	b3Vec3 localPosition = b3InvTransformWorldPoint( xf, explosionContext->position );

	b3DistanceInput input;
	input.proxyA = b3MakeShapeProxy( shape );
	input.proxyB = (b3ShapeProxy){ &localPosition, 1, 0.0f };
	input.transform = b3Transform_identity;
	input.useRadii = true;

	b3SimplexCache cache = { 0 };
	b3DistanceOutput output = b3ShapeDistance( &input, &cache, NULL, 0 );

	float radius = explosionContext->radius;
	float falloff = explosionContext->falloff;
	if ( output.distance > radius + falloff )
	{
		return true;
	}

	b3WakeBody( world, body );

	if ( body->setIndex != b3_awakeSet )
	{
		return true;
	}

	// Witness point is already in the body local query frame
	b3Vec3 closestPoint = output.pointA;
	if ( output.distance == 0.0f )
	{
		closestPoint = b3GetShapeCentroid( shape );
	}

	b3Vec3 direction = b3Sub( closestPoint, localPosition );
	if ( b3LengthSquared( direction ) > 100.0f * FLT_EPSILON * FLT_EPSILON )
	{
		direction = b3Normalize( direction );
	}
	else
	{
		direction = (b3Vec3){ 1.0f, 0.0f, 0.0f };
	}

	float area = b3GetShapeProjectedArea( shape, direction );
	float scale = 1.0f;
	if ( output.distance > radius && falloff > 0.0f )
	{
		scale = b3ClampFloat( ( radius + falloff - output.distance ) / falloff, 0.0f, 1.0f );
	}

	float magnitude = explosionContext->impulsePerArea * area * scale * shape->explosionScale;
	b3Vec3 impulse = b3MulSV( magnitude, b3RotateVector( xf.q, direction ) );

	int localIndex = body->localIndex;
	b3SolverSet* set = b3Array_Get( world->solverSets, b3_awakeSet );
	b3BodyState* state = b3Array_Get( set->bodyStates, localIndex );
	b3BodySim* bodySim = b3Array_Get( set->bodySims, localIndex );
	state->linearVelocity = b3MulAdd( state->linearVelocity, bodySim->invMass, impulse );

	// Lever arm from the center of mass to the closest point, rotated to world
	b3Vec3 r = b3RotateVector( xf.q, b3Sub( closestPoint, bodySim->localCenter ) );
	state->angularVelocity = b3Add( state->angularVelocity, b3MulMV( bodySim->invInertiaWorld, b3Cross( r, impulse ) ) );

	return true;
}

void b3World_Explode( b3WorldId worldId, const b3ExplosionDef* explosionDef )
{
	uint64_t maskBits = explosionDef->maskBits;
	b3Pos position = explosionDef->position;
	float radius = explosionDef->radius;
	float falloff = explosionDef->falloff;
	float impulsePerArea = explosionDef->impulsePerArea;

	B3_ASSERT( b3IsValidPosition( position ) );
	B3_ASSERT( b3IsValidFloat( radius ) && radius >= 0.0f );
	B3_ASSERT( b3IsValidFloat( falloff ) && falloff >= 0.0f );
	B3_ASSERT( b3IsValidFloat( impulsePerArea ) );

	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldExplode, worldId, *explosionDef );

	// Locked due to waking
	world->locked = true;

	struct ExplosionContext explosionContext = { world, position, radius, falloff, impulsePerArea };

	// The broad-phase tree is float, so translate a local query box out to world with outward rounding
	float extent = radius + falloff;
	b3AABB localBox = { { -extent, -extent, -extent }, { extent, extent, extent } };
	b3AABB aabb = b3OffsetAABB( localBox, position );

	b3DynamicTree_Query( world->broadPhase.trees + b3_dynamicBody, aabb, maskBits, false, ExplosionCallback, &explosionContext );

	world->locked = false;
}

void b3World_RebuildStaticTree( b3WorldId worldId )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldRebuildStaticTree, worldId );

	b3DynamicTree* staticTree = world->broadPhase.trees + b3_staticBody;
	b3DynamicTree_Rebuild( staticTree, true );
}

void b3World_EnableSpeculative( b3WorldId worldId, bool flag )
{
	b3World* world = b3GetUnlockedWorldFromId( worldId );
	if ( world == NULL )
	{
		return;
	}

	B3_REC( world, WorldEnableSpeculative, worldId, flag );

	world->enableSpeculative = flag;
}

#if B3_ENABLE_VALIDATION
// This validates island graph connectivity for each body
void b3ValidateConnectivity( b3World* world )
{
	b3Body* bodies = world->bodies.data;
	int bodyCapacity = world->bodies.count;

	for ( int bodyIndex = 0; bodyIndex < bodyCapacity; ++bodyIndex )
	{
		b3Body* body = bodies + bodyIndex;
		if ( body->id == B3_NULL_INDEX )
		{
			b3ValidateFreeId( &world->bodyIdPool, bodyIndex );
			continue;
		}

		B3_ASSERT( bodyIndex == body->id );

		// Need to get the root island because islands are not merged until the next time step
		int bodyIslandId = body->islandId;
		int bodySetIndex = body->setIndex;

		int contactKey = body->headContactKey;
		while ( contactKey != B3_NULL_INDEX )
		{
			int contactId = contactKey >> 1;
			int edgeIndex = contactKey & 1;

			b3Contact* contact = b3Array_Get( world->contacts, contactId );

			bool touching = ( contact->flags & b3_contactTouchingFlag ) != 0;
			if ( touching )
			{
				if ( bodySetIndex != b3_staticSet )
				{
					int contactIslandId = contact->islandId;
					B3_ASSERT( contactIslandId == bodyIslandId );
				}
			}
			else
			{
				B3_ASSERT( contact->islandId == B3_NULL_INDEX );
			}

			contactKey = contact->edges[edgeIndex].nextKey;
		}

		int jointKey = body->headJointKey;
		while ( jointKey != B3_NULL_INDEX )
		{
			int jointId = jointKey >> 1;
			int edgeIndex = jointKey & 1;

			b3Joint* joint = b3Array_Get( world->joints, jointId );

			int otherEdgeIndex = edgeIndex ^ 1;

			b3Body* otherBody = b3Array_Get( world->bodies, joint->edges[otherEdgeIndex].bodyId );

			if ( bodySetIndex == b3_disabledSet || otherBody->setIndex == b3_disabledSet )
			{
				B3_ASSERT( joint->islandId == B3_NULL_INDEX );
			}
			else if ( bodySetIndex == b3_staticSet )
			{
				// Intentional nesting
				if ( otherBody->setIndex == b3_staticSet )
				{
					B3_ASSERT( joint->islandId == B3_NULL_INDEX );
				}
			}
			else if ( body->type != b3_dynamicBody && otherBody->type != b3_dynamicBody )
			{
				B3_ASSERT( joint->islandId == B3_NULL_INDEX );
			}
			else
			{
				int jointIslandId = joint->islandId;
				B3_ASSERT( jointIslandId == bodyIslandId );
			}

			jointKey = joint->edges[edgeIndex].nextKey;
		}
	}
}

// Validates solver sets, but not island connectivity
void b3ValidateSolverSets( b3World* world )
{
	B3_ASSERT( b3GetIdCapacity( &world->bodyIdPool ) == world->bodies.count );
	B3_ASSERT( b3GetIdCapacity( &world->contactIdPool ) == world->contacts.count );
	B3_ASSERT( b3GetIdCapacity( &world->jointIdPool ) == world->joints.count );
	B3_ASSERT( b3GetIdCapacity( &world->islandIdPool ) == world->islands.count );
	B3_ASSERT( b3GetIdCapacity( &world->solverSetIdPool ) == world->solverSets.count );

	int activeSetCount = 0;
	int totalBodyCount = 0;
	int totalJointCount = 0;
	int totalContactCount = 0;
	int totalIslandCount = 0;

	// Validate all solver sets
	int setCount = world->solverSets.count;
	for ( int setIndex = 0; setIndex < setCount; ++setIndex )
	{
		b3SolverSet* set = world->solverSets.data + setIndex;
		if ( set->setIndex != B3_NULL_INDEX )
		{
			activeSetCount += 1;

			if ( setIndex == b3_staticSet )
			{
				B3_ASSERT( set->contactIndices.count == 0 );
				B3_ASSERT( set->islandSims.count == 0 );
				B3_ASSERT( set->bodyStates.count == 0 );
			}
			else if ( setIndex == b3_disabledSet )
			{
				B3_ASSERT( set->islandSims.count == 0 );
				B3_ASSERT( set->bodyStates.count == 0 );
			}
			else if ( setIndex == b3_awakeSet )
			{
				B3_ASSERT( set->bodySims.count == set->bodyStates.count );
				B3_ASSERT( set->jointSims.count == 0 );
			}
			else
			{
				B3_ASSERT( set->bodyStates.count == 0 );
			}

			// Validate bodies
			{
				b3Body* bodies = world->bodies.data;
				B3_ASSERT( set->bodySims.count >= 0 );
				totalBodyCount += set->bodySims.count;
				for ( int i = 0; i < set->bodySims.count; ++i )
				{
					b3BodySim* bodySim = set->bodySims.data + i;

					int bodyId = bodySim->bodyId;
					B3_ASSERT( 0 <= bodyId && bodyId < world->bodies.count );
					b3Body* body = bodies + bodyId;
					B3_ASSERT( body->setIndex == setIndex );
					B3_ASSERT( body->localIndex == i );

					uint32_t syncedFlags = body->flags & ~b3_bodyTransientFlags;
					B3_ASSERT( ( bodySim->flags & syncedFlags ) == syncedFlags );

					b3BodyState* bodyState = b3GetBodyState( world, body );
					if ( bodyState != NULL )
					{
						B3_ASSERT( ( bodyState->flags & syncedFlags ) == syncedFlags );
					}

					if ( body->type == b3_dynamicBody )
					{
						B3_ASSERT( body->flags & b3_dynamicFlag );
					}

					if ( setIndex == b3_disabledSet )
					{
						B3_ASSERT( body->headContactKey == B3_NULL_INDEX );
					}

					// Validate body shapes
					int prevShapeId = B3_NULL_INDEX;
					int shapeId = body->headShapeId;
					while ( shapeId != B3_NULL_INDEX )
					{
						b3Shape* shape = b3Array_Get( world->shapes, shapeId );
						B3_ASSERT( shape->id == shapeId );
						B3_ASSERT( shape->prevShapeId == prevShapeId );

						if ( setIndex == b3_disabledSet )
						{
							B3_ASSERT( shape->proxyKey == B3_NULL_INDEX );
						}
						else if ( setIndex == b3_staticSet )
						{
							B3_ASSERT( B3_PROXY_TYPE( shape->proxyKey ) == b3_staticBody );
						}
						else
						{
							b3BodyType proxyType = B3_PROXY_TYPE( shape->proxyKey );
							B3_ASSERT( proxyType == b3_kinematicBody || proxyType == b3_dynamicBody );
						}

						prevShapeId = shapeId;
						shapeId = shape->nextShapeId;
					}

					// Validate body contacts
					int contactKey = body->headContactKey;
					while ( contactKey != B3_NULL_INDEX )
					{
						int contactId = contactKey >> 1;
						int edgeIndex = contactKey & 1;

						b3Contact* contact = b3Array_Get( world->contacts, contactId );
						B3_ASSERT( contact->setIndex != b3_staticSet );
						B3_ASSERT( contact->edges[0].bodyId == bodyId || contact->edges[1].bodyId == bodyId );
						contactKey = contact->edges[edgeIndex].nextKey;
					}

					// Validate body joints
					int jointKey = body->headJointKey;
					while ( jointKey != B3_NULL_INDEX )
					{
						int jointId = jointKey >> 1;
						int edgeIndex = jointKey & 1;

						b3Joint* joint = b3Array_Get( world->joints, jointId );

						int otherEdgeIndex = edgeIndex ^ 1;

						b3Body* otherBody = b3Array_Get( world->bodies, joint->edges[otherEdgeIndex].bodyId );

						if ( setIndex == b3_disabledSet || otherBody->setIndex == b3_disabledSet )
						{
							B3_ASSERT( joint->setIndex == b3_disabledSet );
						}
						else if ( setIndex == b3_staticSet && otherBody->setIndex == b3_staticSet )
						{
							B3_ASSERT( joint->setIndex == b3_staticSet );
						}
						else if ( body->type != b3_dynamicBody && otherBody->type != b3_dynamicBody )
						{
							B3_ASSERT( joint->setIndex == b3_staticSet );
						}
						else if ( setIndex == b3_awakeSet )
						{
							B3_ASSERT( joint->setIndex == b3_awakeSet );
						}
						else if ( setIndex >= b3_firstSleepingSet )
						{
							B3_ASSERT( joint->setIndex == setIndex );
						}

						b3JointSim* jointSim = b3GetJointSim( world, joint );
						B3_ASSERT( jointSim->jointId == jointId );
						B3_ASSERT( jointSim->bodyIdA == joint->edges[0].bodyId );
						B3_ASSERT( jointSim->bodyIdB == joint->edges[1].bodyId );

						jointKey = joint->edges[edgeIndex].nextKey;
					}
				}
			}

			// Validate contacts
			{
				B3_ASSERT( set->contactIndices.count >= 0 );
				totalContactCount += set->contactIndices.count;
				for ( int i = 0; i < set->contactIndices.count; ++i )
				{
					int contactIndex = set->contactIndices.data[i];
					b3Contact* contact = b3Array_Get( world->contacts, contactIndex );
					if ( setIndex == b3_awakeSet )
					{
						// contact should be non-touching if awake
						// or it could be this contact hasn't been transferred yet
						B3_ASSERT( contact->manifoldCount == 0 || ( contact->flags & b3_simStartedTouching ) != 0 );
					}
					B3_ASSERT( contact->setIndex == setIndex );
					B3_ASSERT( contact->colorIndex == B3_NULL_INDEX );
					B3_ASSERT( contact->localIndex == i );
				}
			}

			// Validate joints
			{
				B3_ASSERT( set->jointSims.count >= 0 );
				totalJointCount += set->jointSims.count;
				for ( int i = 0; i < set->jointSims.count; ++i )
				{
					b3JointSim* jointSim = set->jointSims.data + i;
					b3Joint* joint = b3Array_Get( world->joints, jointSim->jointId );
					B3_ASSERT( joint->setIndex == setIndex );
					B3_ASSERT( joint->colorIndex == B3_NULL_INDEX );
					B3_ASSERT( joint->localIndex == i );
				}
			}

			// Validate islands
			{
				B3_ASSERT( set->islandSims.count >= 0 );
				totalIslandCount += set->islandSims.count;
				for ( int i = 0; i < set->islandSims.count; ++i )
				{
					b3IslandSim* islandSim = set->islandSims.data + i;
					b3Island* island = b3Array_Get( world->islands, islandSim->islandId );
					B3_ASSERT( island->setIndex == setIndex );
					B3_ASSERT( island->localIndex == i );
				}
			}
		}
		else
		{
			B3_ASSERT( set->bodySims.count == 0 );
			B3_ASSERT( set->contactIndices.count == 0 );
			B3_ASSERT( set->jointSims.count == 0 );
			B3_ASSERT( set->islandSims.count == 0 );
			B3_ASSERT( set->bodyStates.count == 0 );
		}
	}

	int setIdCount = b3GetIdCount( &world->solverSetIdPool );
	B3_ASSERT( activeSetCount == setIdCount );

	int bodyIdCount = b3GetIdCount( &world->bodyIdPool );
	B3_ASSERT( totalBodyCount == bodyIdCount );

	int islandIdCount = b3GetIdCount( &world->islandIdPool );
	B3_ASSERT( totalIslandCount == islandIdCount );

	// Validate constraint graph
	for ( int colorIndex = 0; colorIndex < B3_GRAPH_COLOR_COUNT; ++colorIndex )
	{
		b3GraphColor* color = world->constraintGraph.colors + colorIndex;
		int bitCount = 0;

		B3_ASSERT( color->convexContacts.count >= 0 );
		totalContactCount += color->convexContacts.count;
		for ( int i = 0; i < color->convexContacts.count; ++i )
		{
			int contactId = color->convexContacts.data[i];
			b3Contact* contact = b3Array_Get( world->contacts, contactId );
			// contact should be touching in the constraint graph or awaiting transfer to non-touching
			B3_ASSERT( contact->manifoldCount > 0 || ( contact->flags & ( b3_simStoppedTouching | b3_simDisjoint ) ) != 0 );
			B3_ASSERT( contact->setIndex == b3_awakeSet );
			B3_ASSERT( contact->colorIndex == colorIndex );
			B3_ASSERT( contact->localIndex == i );

			int bodyIdA = contact->edges[0].bodyId;
			int bodyIdB = contact->edges[1].bodyId;

			if ( colorIndex < B3_OVERFLOW_INDEX )
			{
				b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
				b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdA ) == ( bodyA->type == b3_dynamicBody ) );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdB ) == ( bodyB->type == b3_dynamicBody ) );

				bitCount += bodyA->type == b3_dynamicBody ? 1 : 0;
				bitCount += bodyB->type == b3_dynamicBody ? 1 : 0;
			}
		}

		totalContactCount += color->contacts.count;
		for ( int i = 0; i < color->contacts.count; ++i )
		{
			int contactId = color->contacts.data[i].contactId;
			b3Contact* contact = b3Array_Get( world->contacts, contactId );
			// contact should be touching in the constraint graph or awaiting transfer to non-touching
			B3_ASSERT( contact->manifoldCount > 0 || ( contact->flags & ( b3_simStoppedTouching | b3_simDisjoint ) ) != 0 );
			B3_ASSERT( contact->setIndex == b3_awakeSet );
			B3_ASSERT( contact->colorIndex == colorIndex );
			B3_ASSERT( contact->localIndex == i );

			int bodyIdA = contact->edges[0].bodyId;
			int bodyIdB = contact->edges[1].bodyId;

			if ( colorIndex < B3_OVERFLOW_INDEX )
			{
				b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
				b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdA ) == ( bodyA->type == b3_dynamicBody ) );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdB ) == ( bodyB->type == b3_dynamicBody ) );

				bitCount += bodyA->type == b3_dynamicBody ? 1 : 0;
				bitCount += bodyB->type == b3_dynamicBody ? 1 : 0;
			}
		}

		B3_ASSERT( color->jointSims.count >= 0 );
		totalJointCount += color->jointSims.count;
		for ( int i = 0; i < color->jointSims.count; ++i )
		{
			b3JointSim* jointSim = color->jointSims.data + i;
			b3Joint* joint = b3Array_Get( world->joints, jointSim->jointId );
			B3_ASSERT( joint->setIndex == b3_awakeSet );
			B3_ASSERT( joint->colorIndex == colorIndex );
			B3_ASSERT( joint->localIndex == i );

			int bodyIdA = joint->edges[0].bodyId;
			int bodyIdB = joint->edges[1].bodyId;

			if ( colorIndex < B3_OVERFLOW_INDEX )
			{
				b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
				b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdA ) == ( bodyA->type == b3_dynamicBody ) );
				B3_ASSERT( b3GetBit( &color->bodySet, bodyIdB ) == ( bodyB->type == b3_dynamicBody ) );

				bitCount += bodyA->type == b3_dynamicBody ? 1 : 0;
				bitCount += bodyB->type == b3_dynamicBody ? 1 : 0;
			}
		}

		// Validate the bit population for this graph color
		B3_ASSERT( bitCount == b3CountSetBits( &color->bodySet ) );
	}

	int contactIdCount = b3GetIdCount( &world->contactIdPool );
	B3_ASSERT( totalContactCount == contactIdCount );
	B3_ASSERT( totalContactCount == (int)world->broadPhase.pairSet.count );

	int jointIdCount = b3GetIdCount( &world->jointIdPool );
	B3_ASSERT( totalJointCount == jointIdCount );

// Validate shapes
// This is very slow on compounds
#if 0
	int shapeCapacity = b3Array(world->shapeArray).count;
	for (int shapeIndex = 0; shapeIndex < shapeCapacity; shapeIndex += 1)
	{
		b3Shape* shape = world->shapeArray + shapeIndex;
		if (shape->id != shapeIndex)
		{
			continue;
		}

		B3_ASSERT(0 <= shape->bodyId && shape->bodyId < b3Array(world->bodyArray).count);

		b3Body* body = world->bodyArray + shape->bodyId;
		B3_ASSERT(0 <= body->setIndex && body->setIndex < b3Array(world->solverSetArray).count);

		b3SolverSet* set = world->solverSetArray + body->setIndex;
		B3_ASSERT(0 <= body->localIndex && body->localIndex < set->sims.count);

		b3BodySim* bodySim = set->sims.mData + body->localIndex;
		B3_ASSERT(bodySim->bodyId == shape->bodyId);

		bool found = false;
		int shapeCount = 0;
		int index = body->headShapeId;
		while (index != B3_NULL_INDEX)
		{
			b3CheckId(world->shapeArray, index);
			b3Shape* s = world->shapeArray + index;
			if (index == shapeIndex)
			{
				found = true;
			}

			index = s->nextShapeId;
			shapeCount += 1;
		}

		B3_ASSERT(found);
		B3_ASSERT(shapeCount == body->shapeCount);
	}
#endif
}

// Validate contact touching status.
void b3ValidateContacts( b3World* world )
{
	b3ConstraintGraph* graph = &world->constraintGraph;
	int contactCount = world->contacts.count;
	B3_ASSERT( contactCount == b3GetIdCapacity( &world->contactIdPool ) );
	int allocatedContactCount = 0;

	for ( int contactIndex = 0; contactIndex < contactCount; ++contactIndex )
	{
		b3Contact* contact = b3Array_Get( world->contacts, contactIndex );
		if ( contact->contactId == B3_NULL_INDEX )
		{
			continue;
		}

		B3_ASSERT( contact->contactId == contactIndex );

		allocatedContactCount += 1;

		bool touching = ( contact->flags & b3_contactTouchingFlag ) != 0;

		int setId = contact->setIndex;
		b3SolverSet* set = b3Array_Get( world->solverSets, setId );

		if ( setId == b3_awakeSet )
		{
			if ( touching )
			{
				B3_ASSERT( 0 <= contact->colorIndex && contact->colorIndex < B3_GRAPH_COLOR_COUNT );
				// Validate body sim indices
				b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
				b3Shape* shapeB = b3Array_Get( world->shapes, contact->shapeIdB );

				b3Body* bodyA = b3Array_Get( world->bodies, shapeA->bodyId );
				b3Body* bodyB = b3Array_Get( world->bodies, shapeB->bodyId );

				if ( bodyA->type == b3_staticBody )
				{
					B3_ASSERT( contact->bodySimIndexA == B3_NULL_INDEX );
				}
				else
				{
					B3_ASSERT( contact->bodySimIndexA == bodyA->localIndex );
				}

				if ( bodyB->type == b3_staticBody )
				{
					B3_ASSERT( contact->bodySimIndexB == B3_NULL_INDEX );
				}
				else
				{
					B3_ASSERT( contact->bodySimIndexB == bodyB->localIndex );
				}

				if ( ( contact->flags & b3_simMeshContact ) != 0 || contact->colorIndex == B3_OVERFLOW_INDEX )
				{
					b3GraphColor* color = graph->colors + contact->colorIndex;
					int contactId = b3Array_Get( color->contacts, contact->localIndex )->contactId;
					B3_ASSERT( contactId == contactIndex );
				}
				else
				{
					b3GraphColor* color = graph->colors + contact->colorIndex;
					int contactId = *b3Array_Get( color->convexContacts, contact->localIndex );
					B3_ASSERT( contactId == contactIndex );
				}
			}
			else
			{
				B3_ASSERT( contact->colorIndex == B3_NULL_INDEX );
				B3_ASSERT( contact->manifolds == NULL );
				B3_ASSERT( contact->manifoldCount == 0 );

				int* index = b3Array_Get( set->contactIndices, contact->localIndex );
				B3_ASSERT( *index == contactIndex );
			}
		}
		else if ( setId >= b3_firstSleepingSet )
		{
			// Only touching contacts allowed in a sleeping set
			B3_ASSERT( touching == true );
			B3_ASSERT( contact->manifolds != NULL );
			B3_ASSERT( contact->manifoldCount > 0 );
			int* index = b3Array_Get( set->contactIndices, contact->localIndex );
			B3_ASSERT( *index == contactIndex );
		}
		else
		{
			// Sleeping and non-touching contacts belong in the disabled set
			B3_ASSERT( touching == false && setId == b3_disabledSet );
			B3_ASSERT( contact->manifolds == NULL );
			B3_ASSERT( contact->manifoldCount == 0 );
			int* index = b3Array_Get( set->contactIndices, contact->localIndex );
			B3_ASSERT( *index == contactIndex );
		}

		if ( contact->flags & b3_simMeshContact )
		{
			int cacheCount = contact->meshContact.triangleCache.count;
			if ( cacheCount > 0 )
			{
				B3_ASSERT( contact->meshContact.triangleCache.data != NULL );
				B3_ASSERT( contact->meshContact.triangleCache.capacity >= cacheCount );

				b3Shape* shapeA = b3Array_Get( world->shapes, contact->shapeIdA );
				if ( shapeA->type == b3_meshShape )
				{
					int triangleCount = shapeA->mesh.data->triangleCount;
					for ( int i = 0; i < cacheCount; ++i )
					{
						int triangleIndex = contact->meshContact.triangleCache.data[i].triangleIndex;
						B3_ASSERT( 0 <= triangleIndex && triangleIndex < triangleCount );
					}
				}
				else if ( shapeA->type == b3_heightShape )
				{
					int triangleCount = b3GetHeightFieldTriangleCount( shapeA->heightField );
					for ( int i = 0; i < cacheCount; ++i )
					{
						int triangleIndex = contact->meshContact.triangleCache.data[i].triangleIndex;
						B3_ASSERT( 0 <= triangleIndex && triangleIndex < triangleCount );
					}
				}
				else
				{
					B3_ASSERT( shapeA->type == b3_compoundShape );
					b3ChildShape child = b3GetCompoundChild( shapeA->compound, contact->childIndex );
					B3_ASSERT( child.type == b3_meshShape );

					int triangleCount = child.mesh.data->triangleCount;
					for ( int i = 0; i < cacheCount; ++i )
					{
						int triangleIndex = contact->meshContact.triangleCache.data[i].triangleIndex;
						B3_ASSERT( 0 <= triangleIndex && triangleIndex < triangleCount );
					}
				}
			}
		}
	}

	int contactIdCount = b3GetIdCount( &world->contactIdPool );
	B3_ASSERT( allocatedContactCount == contactIdCount );
}

#else

void b3ValidateConnectivity( b3World* world )
{
	B3_UNUSED( world );
}

void b3ValidateSolverSets( b3World* world )
{
	B3_UNUSED( world );
}

void b3ValidateContacts( b3World* world )
{
	B3_UNUSED( world );
}

#endif
