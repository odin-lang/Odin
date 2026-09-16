// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "island.h"

#include "body.h"
#include "contact.h"
#include "core.h"
#include "id_pool.h"
#include "joint.h"
#include "physics_world.h"
#include "solver_set.h"

#include <stddef.h>

b3Island* b3CreateIsland( b3World* world, int setIndex )
{
	B3_ASSERT( setIndex == b3_awakeSet || setIndex >= b3_firstSleepingSet );

	int islandId = b3AllocId( &world->islandIdPool );

	if ( islandId == world->islands.count )
	{
		b3Island emptyIsland = { 0 };
		b3Array_Push( world->islands, emptyIsland );
	}
	else
	{
		B3_ASSERT( world->islands.data[islandId].setIndex == B3_NULL_INDEX );
	}

	b3SolverSet* set = b3Array_Get( world->solverSets, setIndex );

	b3Island* island = b3Array_Get( world->islands, islandId );
	island->setIndex = setIndex;
	island->localIndex = set->islandSims.count;
	island->islandId = islandId;
	b3Array_Create( island->bodies );
	b3Array_Create( island->contacts );
	b3Array_Create( island->joints );
	island->constraintRemoveCount = 0;

	b3IslandSim* islandSim = b3Array_Emplace( set->islandSims );
	islandSim->islandId = islandId;

	return island;
}

void b3DestroyIsland( b3World* world, int islandId )
{
	if ( world->splitIslandId == islandId )
	{
		world->splitIslandId = B3_NULL_INDEX;
	}

	// assume island is empty
	b3Island* island = b3Array_Get( world->islands, islandId );
	b3SolverSet* set = b3Array_Get( world->solverSets, island->setIndex );
	{
		int localIndex = island->localIndex;
		int lastIndex = set->islandSims.count - 1;
		B3_ASSERT( 0 <= localIndex && localIndex <= lastIndex );
		int moveIslandId = set->islandSims.data[lastIndex].islandId;
		set->islandSims.data[localIndex] = set->islandSims.data[lastIndex];
		world->islands.data[moveIslandId].localIndex = localIndex;
		set->islandSims.count -= 1;
	}

	// Free island and id (preserve island generation)
	b3Array_Destroy( island->bodies );
	b3Array_Destroy( island->contacts );
	b3Array_Destroy( island->joints );
	island->constraintRemoveCount = 0;
	island->localIndex = B3_NULL_INDEX;
	island->islandId = B3_NULL_INDEX;
	island->setIndex = B3_NULL_INDEX;

	b3FreeId( &world->islandIdPool, islandId );
}

static int b3MergeIslands( b3World* world, int islandIdA, int islandIdB )
{
	if ( islandIdA == islandIdB )
	{
		return islandIdA;
	}

	if ( islandIdA == B3_NULL_INDEX )
	{
		B3_ASSERT( islandIdB != B3_NULL_INDEX );
		return islandIdB;
	}

	if ( islandIdB == B3_NULL_INDEX )
	{
		B3_ASSERT( islandIdA != B3_NULL_INDEX );
		return islandIdA;
	}

	b3Island* smallIsland;
	b3Island* bigIsland;
	{
		b3Island* islandA = b3Array_Get( world->islands, islandIdA );
		b3Island* islandB = b3Array_Get( world->islands, islandIdB );

		// Keep the biggest island to reduce cache misses
		if ( islandA->bodies.count >= islandB->bodies.count )
		{
			bigIsland = islandA;
			smallIsland = islandB;
		}
		else
		{
			bigIsland = islandB;
			smallIsland = islandA;
		}
	}

	int bigIslandId = bigIsland->islandId;
	b3Array_Reserve( bigIsland->bodies, bigIsland->bodies.count + smallIsland->bodies.count );

	// Move bodies from smaller island to larger island
	for ( int i = 0; i < smallIsland->bodies.count; ++i )
	{
		int bodyId = smallIsland->bodies.data[i];
		b3Body* body = b3Array_Get( world->bodies, bodyId );
		B3_VALIDATE( body->islandId == smallIsland->islandId );
		body->islandId = bigIslandId;
		body->islandIndex = bigIsland->bodies.count;
		b3Array_Push( bigIsland->bodies, bodyId );
	}

	// Migrate contacts from smaller island to larger island
	if ( smallIsland->contacts.count > 0 )
	{
		b3Array_Reserve( bigIsland->contacts, bigIsland->contacts.count + smallIsland->contacts.count );

		for ( int i = 0; i < smallIsland->contacts.count; ++i )
		{
			b3ContactLink* link = smallIsland->contacts.data + i;
			b3Contact* contact = b3Array_Get( world->contacts, link->contactId );
			contact->islandId = bigIslandId;
			contact->islandIndex = bigIsland->contacts.count;
			b3Array_Push( bigIsland->contacts, *link );
		}
	}

	// Migrate joints from smaller island to larger island
	if ( smallIsland->joints.count > 0 )
	{
		b3Array_Reserve( bigIsland->joints, bigIsland->joints.count + smallIsland->joints.count );

		for ( int i = 0; i < smallIsland->joints.count; ++i )
		{
			b3JointLink* link = smallIsland->joints.data + i;
			b3Joint* joint = b3Array_Get( world->joints, link->jointId );
			joint->islandId = bigIslandId;
			joint->islandIndex = bigIsland->joints.count;
			b3Array_Push( bigIsland->joints, *link );
		}
	}

	// Track removed constraints
	bigIsland->constraintRemoveCount += smallIsland->constraintRemoveCount;

	b3DestroyIsland( world, smallIsland->islandId );

	b3ValidateIsland( world, bigIslandId );

	return bigIslandId;
}

static void b3AddContactToIsland( b3World* world, int islandId, b3Contact* contact )
{
	B3_ASSERT( contact->islandId == B3_NULL_INDEX );
	B3_ASSERT( contact->islandIndex == B3_NULL_INDEX );

	b3Island* island = b3Array_Get( world->islands, islandId );

	contact->islandId = islandId;
	contact->islandIndex = island->contacts.count;

	b3ContactLink link;
	link.contactId = contact->contactId;
	link.bodyIdA = contact->edges[0].bodyId;
	link.bodyIdB = contact->edges[1].bodyId;
	b3Array_Push( island->contacts, link );

	b3ValidateIsland( world, islandId );
}

// Link a contact into an island.
void b3LinkContact( b3World* world, b3Contact* contact )
{
	B3_ASSERT( ( contact->flags & b3_contactTouchingFlag ) != 0 );

	int bodyIdA = contact->edges[0].bodyId;
	int bodyIdB = contact->edges[1].bodyId;

	b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
	b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );

	B3_ASSERT( bodyA->setIndex != b3_disabledSet && bodyB->setIndex != b3_disabledSet );
	B3_ASSERT( bodyA->setIndex != b3_staticSet || bodyB->setIndex != b3_staticSet );

	// Wake bodyB if bodyA is awake and bodyB is sleeping
	if ( bodyA->setIndex == b3_awakeSet && bodyB->setIndex >= b3_firstSleepingSet )
	{
		b3WakeSolverSet( world, bodyB->setIndex );
	}

	// Wake bodyA if bodyB is awake and bodyA is sleeping
	if ( bodyB->setIndex == b3_awakeSet && bodyA->setIndex >= b3_firstSleepingSet )
	{
		b3WakeSolverSet( world, bodyA->setIndex );
	}

	int islandIdA = bodyA->islandId;
	int islandIdB = bodyB->islandId;

	// Static bodies have null island indices.
	B3_ASSERT( bodyA->setIndex != b3_staticSet || islandIdA == B3_NULL_INDEX );
	B3_ASSERT( bodyB->setIndex != b3_staticSet || islandIdB == B3_NULL_INDEX );
	B3_ASSERT( islandIdA != B3_NULL_INDEX || islandIdB != B3_NULL_INDEX );

	// Merge islands. This will destroy one of the islands.
	int finalIslandId = b3MergeIslands( world, islandIdA, islandIdB );

	// Add contact to the island that survived
	b3AddContactToIsland( world, finalIslandId, contact );
}

// This is called when a contact no longer has contact points or when a contact is destroyed.
void b3UnlinkContact( b3World* world, b3Contact* contact )
{
	B3_ASSERT( contact->islandId != B3_NULL_INDEX );

	// remove from island
	int islandId = contact->islandId;
	b3Island* island = b3Array_Get( world->islands, islandId );

	int removeIndex = contact->islandIndex;
	B3_ASSERT( 0 <= removeIndex && removeIndex < island->contacts.count );
	B3_ASSERT( island->contacts.data[removeIndex].contactId == contact->contactId );

	int movedIndex = b3Array_RemoveSwap( island->contacts, removeIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		// Fix islandIndex on the contact that was swapped into removeIndex
		b3ContactLink* movedLink = island->contacts.data + removeIndex;
		b3Contact* movedContact = b3Array_Get( world->contacts, movedLink->contactId );
		B3_ASSERT( movedContact->islandIndex == movedIndex );
		movedContact->islandIndex = removeIndex;
	}

	contact->islandId = B3_NULL_INDEX;
	contact->islandIndex = B3_NULL_INDEX;
	island->constraintRemoveCount += 1;

	b3ValidateIsland( world, islandId );
}

static void b3AddJointToIsland( b3World* world, int islandId, b3Joint* joint )
{
	B3_ASSERT( joint->islandId == B3_NULL_INDEX );
	B3_ASSERT( joint->islandIndex == B3_NULL_INDEX );

	b3Island* island = b3Array_Get( world->islands, islandId );

	joint->islandId = islandId;
	joint->islandIndex = island->joints.count;

	b3JointLink link;
	link.jointId = joint->jointId;
	link.bodyIdA = joint->edges[0].bodyId;
	link.bodyIdB = joint->edges[1].bodyId;
	b3Array_Push( island->joints, link );

	b3ValidateIsland( world, islandId );
}

void b3LinkJoint( b3World* world, b3Joint* joint )
{
	b3Body* bodyA = b3Array_Get( world->bodies, joint->edges[0].bodyId );
	b3Body* bodyB = b3Array_Get( world->bodies, joint->edges[1].bodyId );

	B3_ASSERT( bodyA->type == b3_dynamicBody || bodyB->type == b3_dynamicBody );

	if ( bodyA->setIndex == b3_awakeSet && bodyB->setIndex >= b3_firstSleepingSet )
	{
		b3WakeSolverSet( world, bodyB->setIndex );
	}
	else if ( bodyB->setIndex == b3_awakeSet && bodyA->setIndex >= b3_firstSleepingSet )
	{
		b3WakeSolverSet( world, bodyA->setIndex );
	}

	int islandIdA = bodyA->islandId;
	int islandIdB = bodyB->islandId;

	B3_ASSERT( islandIdA != B3_NULL_INDEX || islandIdB != B3_NULL_INDEX );

	// Merge islands. This will destroy one of the islands.
	int finalIslandId = b3MergeIslands( world, islandIdA, islandIdB );

	// Add joint the island that survived
	b3AddJointToIsland( world, finalIslandId, joint );
}

void b3UnlinkJoint( b3World* world, b3Joint* joint )
{
	if ( joint->islandId == B3_NULL_INDEX )
	{
		return;
	}

	// remove from island
	int islandId = joint->islandId;
	b3Island* island = b3Array_Get( world->islands, islandId );

	int removeIndex = joint->islandIndex;
	B3_ASSERT( 0 <= removeIndex && removeIndex < island->joints.count );
	B3_ASSERT( island->joints.data[removeIndex].jointId == joint->jointId );

	int movedIndex = b3Array_RemoveSwap( island->joints, removeIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		// Fix islandIndex on the joint that was swapped into removeIndex
		b3JointLink* movedLink = island->joints.data + removeIndex;
		b3Joint* movedJoint = b3Array_Get( world->joints, movedLink->jointId );
		B3_ASSERT( movedJoint->islandIndex == movedIndex );
		movedJoint->islandIndex = removeIndex;
	}

	joint->islandId = B3_NULL_INDEX;
	joint->islandIndex = B3_NULL_INDEX;
	island->constraintRemoveCount += 1;

	b3ValidateIsland( world, islandId );
}

// Find parent of a node. Use path halving to speed up further queries.
static inline int b3IslandFindParent( int* parents, int node )
{
	// Walk the chain of parents to find the node that is its own parent (the root)
	while ( parents[node] != node )
	{
		int grandParent = parents[parents[node]];
		parents[node] = grandParent;
		node = grandParent;
	}

	return node;
}

// Connect the components containing node1 and node2.
// Uses rank to keep tree balanced. Tracks per-component contact and joint counts.
static inline void b3IslandUnion( int* parents, int* ranks, int node1, int node2, int* contactCounts, int* jointCounts )
{
	int root1 = b3IslandFindParent( parents, node1 );
	int root2 = b3IslandFindParent( parents, node2 );
	if ( root1 != root2 )
	{
		if ( ranks[root1] < ranks[root2] )
		{
			parents[root1] = root2;
			contactCounts[root2] += contactCounts[root1];
			jointCounts[root2] += jointCounts[root1];
		}
		else if ( ranks[root1] > ranks[root2] )
		{
			parents[root2] = root1;
			contactCounts[root1] += contactCounts[root2];
			jointCounts[root1] += jointCounts[root2];
		}
		else
		{
			parents[root2] = root1;
			ranks[root1] += 1;
			contactCounts[root1] += contactCounts[root2];
			jointCounts[root1] += jointCounts[root2];
		}
	}
}

// This uses union-find.
// https://en.wikipedia.org/wiki/Disjoint-set_data_structure
void b3SplitIsland( b3World* world, int baseId )
{
	b3Island* baseIsland = b3Array_Get( world->islands, baseId );
	B3_ASSERT( baseIsland->constraintRemoveCount > 0 );
	B3_ASSERT( baseIsland->setIndex == b3_awakeSet );

	b3ValidateIsland( world, baseId );

	// Cache base island fields before b3CreateIsland, which may reallocate
	// world->islands and invalidate the baseIsland pointer.
	int baseBodyCount = baseIsland->bodies.count;
	int* baseBodyIds = baseIsland->bodies.data;
	int baseBodyCapacity = baseIsland->bodies.capacity;

	int baseContactCount = baseIsland->contacts.count;
	b3ContactLink* baseContacts = baseIsland->contacts.data;
	int baseContactCapacity = baseIsland->contacts.capacity;

	int baseJointCount = baseIsland->joints.count;
	b3JointLink* baseJoints = baseIsland->joints.data;
	int baseJointCapacity = baseIsland->joints.capacity;

	b3Stack* alloc = &world->stack;

	// No lock is needed because I ensure the allocator is not used while this task is active.
	// Allocate contactCounts and jointCounts before ranks so ranks can be freed first (LIFO arena).
	int* parents = b3StackAlloc( alloc, baseBodyCount * sizeof( int ), "parents" );
	int* contactCounts = b3StackAlloc( alloc, baseBodyCount * sizeof( int ), "contact counts" );
	int* jointCounts = b3StackAlloc( alloc, baseBodyCount * sizeof( int ), "joint counts" );
	int* ranks = b3StackAlloc( alloc, baseBodyCount * sizeof( int ), "ranks" );
	for ( int i = 0; i < baseBodyCount; ++i )
	{
		parents[i] = i;
		ranks[i] = 0;
		contactCounts[i] = 0;
		jointCounts[i] = 0;
	}

	b3Body* bodies = world->bodies.data;

	// Union over contacts, tracking per-component contact counts
	for ( int i = 0; i < baseContactCount; ++i )
	{
		int bodyIdA = baseContacts[i].bodyIdA;
		int bodyIdB = baseContacts[i].bodyIdB;
		B3_VALIDATE( 0 <= bodyIdA && bodyIdA < world->bodies.count );
		B3_VALIDATE( 0 <= bodyIdB && bodyIdB < world->bodies.count );
		b3Body* bodyA = bodies + bodyIdA;
		b3Body* bodyB = bodies + bodyIdB;
		int islandIndexA = bodyA->islandIndex;
		int islandIndexB = bodyB->islandIndex;

		// Only connect non-static bodies
		if ( islandIndexA != B3_NULL_INDEX && islandIndexB != B3_NULL_INDEX )
		{
			B3_VALIDATE( 0 <= islandIndexA && islandIndexA < baseBodyCount );
			B3_VALIDATE( 0 <= islandIndexB && islandIndexB < baseBodyCount );
			b3IslandUnion( parents, ranks, islandIndexA, islandIndexB, contactCounts, jointCounts );
			int root = b3IslandFindParent( parents, islandIndexA );
			contactCounts[root] += 1;
		}
		else
		{
			int islandIndex = islandIndexA != B3_NULL_INDEX ? islandIndexA : islandIndexB;
			int root = b3IslandFindParent( parents, islandIndex );
			contactCounts[root] += 1;
		}
	}

	// Union over joints, tracking per-component joint counts
	for ( int i = 0; i < baseJointCount; ++i )
	{
		int bodyIdA = baseJoints[i].bodyIdA;
		int bodyIdB = baseJoints[i].bodyIdB;
		B3_VALIDATE( 0 <= bodyIdA && bodyIdA < world->bodies.count );
		B3_VALIDATE( 0 <= bodyIdB && bodyIdB < world->bodies.count );
		b3Body* bodyA = bodies + bodyIdA;
		b3Body* bodyB = bodies + bodyIdB;
		int islandIndexA = bodyA->islandIndex;
		int islandIndexB = bodyB->islandIndex;

		// Only connect non-static bodies
		if ( islandIndexA != B3_NULL_INDEX && islandIndexB != B3_NULL_INDEX )
		{
			B3_VALIDATE( 0 <= islandIndexA && islandIndexA < baseBodyCount );
			B3_VALIDATE( 0 <= islandIndexB && islandIndexB < baseBodyCount );
			b3IslandUnion( parents, ranks, islandIndexA, islandIndexB, contactCounts, jointCounts );
			int root = b3IslandFindParent( parents, islandIndexA );
			jointCounts[root] += 1;
		}
		else
		{
			int islandIndex = islandIndexA != B3_NULL_INDEX ? islandIndexA : islandIndexB;
			int root = b3IslandFindParent( parents, islandIndex );
			jointCounts[root] += 1;
		}
	}

	// Done with ranks
	b3StackFree( alloc, ranks );
	ranks = NULL;

	// Flatten all parent indices and count connected components.
	int componentCount = 0;
	for ( int i = 0; i < baseBodyCount; ++i )
	{
		parents[i] = b3IslandFindParent( parents, i );
		if ( parents[i] == i )
		{
			componentCount += 1;
		}
	}

	// Island is still fully connected, no split needed.
	if ( componentCount == 1 )
	{
		baseIsland->constraintRemoveCount = 0;
		b3StackFree( alloc, jointCounts );
		b3StackFree( alloc, contactCounts );
		b3StackFree( alloc, parents );
		return;
	}

	// Detach body/contact/joint arrays from base island so b3DestroyIsland won't free them
	baseIsland->bodies.data = NULL;
	baseIsland->bodies.count = 0;
	baseIsland->bodies.capacity = 0;

	baseIsland->contacts.data = NULL;
	baseIsland->contacts.count = 0;
	baseIsland->contacts.capacity = 0;

	baseIsland->joints.data = NULL;
	baseIsland->joints.count = 0;
	baseIsland->joints.capacity = 0;

	// Null so code below doesn't accidentally use this.
	baseIsland = NULL;

	// Map from body index to new island index. Only set for root bodies.
	int* rootMap = b3StackAlloc( alloc, baseBodyCount * sizeof( int ), "root map" );
	for ( int i = 0; i < baseBodyCount; ++i )
	{
		rootMap[i] = B3_NULL_INDEX;
	}

	int* componentBodyCounts = b3StackAlloc( alloc, componentCount * sizeof( int ), "component body counts" );
	int* componentContactCounts = b3StackAlloc( alloc, componentCount * sizeof( int ), "component contact counts" );
	int* componentJointCounts = b3StackAlloc( alloc, componentCount * sizeof( int ), "component joint counts" );
	int islandCount = 0;

	// Find the root body for each body and create islands as needed.
	// Extract per-component counts from the root nodes' accumulated counts.
	for ( int i = 0; i < baseBodyCount; ++i )
	{
		int rootIndex = parents[i];
		if ( rootMap[rootIndex] == B3_NULL_INDEX )
		{
			rootMap[rootIndex] = islandCount;
			componentBodyCounts[islandCount] = 0;
			componentContactCounts[islandCount] = contactCounts[rootIndex];
			componentJointCounts[islandCount] = jointCounts[rootIndex];
			islandCount += 1;
		}

		componentBodyCounts[rootMap[rootIndex]] += 1;
	}

	B3_ASSERT( islandCount == componentCount );

	// Map from new island index to island id
	int* islandIds = b3StackAlloc( alloc, islandCount * sizeof( int ), "island ids" );

	// Create new islands and reserve body/contact/joint arrays
	for ( int i = 0; i < islandCount; ++i )
	{
		// WARNING: this invalidates baseIsland pointer
		b3Island* newIsland = b3CreateIsland( world, b3_awakeSet );
		islandIds[i] = newIsland->islandId;

		// Reserve arrays to avoid wasteful growth and memcpy.
		b3Array_Reserve( newIsland->bodies, componentBodyCounts[i] );
		b3Array_Reserve( newIsland->contacts, componentContactCounts[i] );
		b3Array_Reserve( newIsland->joints, componentJointCounts[i] );
	}

	// Assign bodies to new islands
	for ( int i = 0; i < baseBodyCount; ++i )
	{
		int bodyId = baseBodyIds[i];
		int root = b3IslandFindParent( parents, i );
		int newIslandId = islandIds[rootMap[root]];

		b3Body* body = b3Array_Get( world->bodies, bodyId );
		b3Island* newIsland = b3Array_Get( world->islands, newIslandId );

		body->islandId = newIslandId;
		body->islandIndex = newIsland->bodies.count;

		// Ensure the array has the correct capacity
		B3_VALIDATE( newIsland->bodies.count < newIsland->bodies.capacity );
		b3Array_Push( newIsland->bodies, bodyId );
	}

	// Assign contacts to the island of their bodies
	for ( int i = 0; i < baseContactCount; ++i )
	{
		b3ContactLink* link = baseContacts + i;
		b3Contact* contact = b3Array_Get( world->contacts, link->contactId );

		// Static bodies don't have an island id.
		b3Body* bodyA = b3Array_Get( world->bodies, link->bodyIdA );
		b3Body* bodyB = b3Array_Get( world->bodies, link->bodyIdB );
		int targetIslandId = bodyA->islandId != B3_NULL_INDEX ? bodyA->islandId : bodyB->islandId;

		b3Island* targetIsland = b3Array_Get( world->islands, targetIslandId );
		contact->islandId = targetIslandId;
		contact->islandIndex = targetIsland->contacts.count;

		// Ensure the array has the correct capacity
		B3_VALIDATE( targetIsland->contacts.count < targetIsland->contacts.capacity );
		b3Array_Push( targetIsland->contacts, *link );
	}

	// Assign joints to the island of their bodies
	for ( int i = 0; i < baseJointCount; ++i )
	{
		b3JointLink* link = baseJoints + i;
		b3Joint* joint = b3Array_Get( world->joints, link->jointId );

		// Static bodies don't have an island id.
		b3Body* bodyA = b3Array_Get( world->bodies, link->bodyIdA );
		b3Body* bodyB = b3Array_Get( world->bodies, link->bodyIdB );
		int targetIslandId = bodyA->islandId != B3_NULL_INDEX ? bodyA->islandId : bodyB->islandId;

		b3Island* targetIsland = b3Array_Get( world->islands, targetIslandId );
		joint->islandId = targetIslandId;
		joint->islandIndex = targetIsland->joints.count;

		// Ensure the array has the correct capacity
		B3_VALIDATE( targetIsland->joints.count < targetIsland->joints.capacity );
		b3Array_Push( targetIsland->joints, *link );
	}

	// Destroy the base island
	b3DestroyIsland( world, baseId );

	// Free the detached arrays manually
	b3Free( baseBodyIds, baseBodyCapacity * sizeof( int ) );
	b3Free( baseContacts, baseContactCapacity * sizeof( b3ContactLink ) );
	b3Free( baseJoints, baseJointCapacity * sizeof( b3JointLink ) );

	// Free arena items in LIFO order
	b3StackFree( alloc, islandIds );
	b3StackFree( alloc, componentJointCounts );
	b3StackFree( alloc, componentContactCounts );
	b3StackFree( alloc, componentBodyCounts );
	b3StackFree( alloc, rootMap );
	b3StackFree( alloc, jointCounts );
	b3StackFree( alloc, contactCounts );
	b3StackFree( alloc, parents );
}

// Split an island because some contacts and/or joints have been removed.
// This is called during the constraint solve while islands are not being touched. This uses union find and
// touches a lot of memory, so it can be slow.
// Note: contacts/joints connected to static bodies must belong to an island but don't affect island connectivity
// Note: static bodies are never in an island
// Note: this task interacts with some allocators without locks under the assumption that no other tasks
// are interacting with these data structures.
void b3SplitIslandTask( void* context )
{
	b3TracyCZoneNC( split, "Split Island", b3_colorOlive, true );

	uint64_t ticks = b3GetTicks();
	b3World* world = context;

	B3_ASSERT( world->splitIslandId != B3_NULL_INDEX );

	b3SplitIsland( world, world->splitIslandId );

	world->splitIslandId = B3_NULL_INDEX;
	world->profile.splitIslands += b3GetMilliseconds( ticks );
	b3TracyCZoneEnd( split );
}

#if B3_ENABLE_VALIDATION
void b3ValidateIsland( b3World* world, int islandId )
{
	if ( islandId == B3_NULL_INDEX )
	{
		return;
	}

	b3Island* island = b3Array_Get( world->islands, islandId );
	B3_ASSERT( island->islandId == islandId );
	B3_ASSERT( island->setIndex != B3_NULL_INDEX );

	{
		B3_ASSERT( island->bodies.count > 0 );
		B3_ASSERT( island->bodies.count <= b3GetIdCount( &world->bodyIdPool ) );

		for ( int i = 0; i < island->bodies.count; ++i )
		{
			b3Body* body = b3Array_Get( world->bodies, island->bodies.data[i] );
			B3_ASSERT( body->islandId == islandId );
			B3_ASSERT( body->islandIndex == i );
			B3_ASSERT( body->setIndex == island->setIndex );
		}
	}

	if ( island->contacts.count > 0 )
	{
		B3_ASSERT( island->contacts.count <= b3GetIdCount( &world->contactIdPool ) );

		for ( int i = 0; i < island->contacts.count; ++i )
		{
			b3ContactLink* link = island->contacts.data + i;
			b3Contact* contact = b3Array_Get( world->contacts, link->contactId );
			B3_ASSERT( contact->setIndex == island->setIndex );
			B3_ASSERT( contact->islandId == islandId );
			B3_ASSERT( contact->islandIndex == i );
		}
	}

	if ( island->joints.count > 0 )
	{
		B3_ASSERT( island->joints.count <= b3GetIdCount( &world->jointIdPool ) );

		for ( int i = 0; i < island->joints.count; ++i )
		{
			b3JointLink* link = island->joints.data + i;
			b3Joint* joint = b3Array_Get( world->joints, link->jointId );
			B3_ASSERT( joint->setIndex == island->setIndex );
			B3_ASSERT( joint->islandId == islandId );
			B3_ASSERT( joint->islandIndex == i );
		}
	}
}

#else

void b3ValidateIsland( b3World* world, int islandId )
{
	B3_UNUSED( world );
	B3_UNUSED( islandId );
}
#endif
