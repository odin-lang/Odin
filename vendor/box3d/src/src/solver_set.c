// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "solver_set.h"

#include "body.h"
#include "constraint_graph.h"
#include "contact.h"
#include "island.h"
#include "joint.h"
#include "physics_world.h"

#include <string.h>

void b3DestroySolverSet( b3World* world, int setIndex )
{
	b3SolverSet* set = b3Array_Get( world->solverSets, setIndex );

	b3Array_Destroy( set->bodySims );
	b3Array_Destroy( set->bodyStates );
	b3Array_Destroy( set->contactIndices );
	b3Array_Destroy( set->jointSims );
	b3Array_Destroy( set->islandSims );

	b3FreeId( &world->solverSetIdPool, setIndex );
	*set = (b3SolverSet){ 0 };
	set->setIndex = B3_NULL_INDEX;
}

// Wake a solver set. Does not merge islands.
// Contacts can be in several places:
// 1. non-touching contacts in the disabled set
// 2. non-touching contacts already in the awake set
// 3. touching contacts in the sleeping set
// This handles contact types 1 and 3. Type 2 doesn't need any action.
void b3WakeSolverSet( b3World* world, int setIndex )
{
	B3_ASSERT( setIndex >= b3_firstSleepingSet );
	b3SolverSet* set = b3Array_Get( world->solverSets, setIndex );
	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	b3SolverSet* disabledSet = b3Array_Get( world->solverSets, b3_disabledSet );

	b3Body* bodies = world->bodies.data;

	int bodyCount = set->bodySims.count;
	for ( int i = 0; i < bodyCount; ++i )
	{
		b3BodySim* simSrc = set->bodySims.data + i;

		b3Body* body = bodies + simSrc->bodyId;
		B3_ASSERT( body->setIndex == setIndex );
		body->setIndex = b3_awakeSet;
		body->localIndex = awakeSet->bodySims.count;

		// Reset sleep timer
		body->sleepTime = 0.0f;

		b3BodySim* simDst = b3Array_Emplace( awakeSet->bodySims );
		memcpy( simDst, simSrc, sizeof( b3BodySim ) );

		b3BodyState* state = b3Array_Emplace( awakeSet->bodyStates );
		*state = b3_identityBodyState;
		state->flags = body->flags;

		// move non-touching contacts from disabled set to awake set
		int contactKey = body->headContactKey;
		while ( contactKey != B3_NULL_INDEX )
		{
			int edgeIndex = contactKey & 1;
			int contactId = contactKey >> 1;

			b3Contact* contact = b3Array_Get( world->contacts, contactId );
			contactKey = contact->edges[edgeIndex].nextKey;

			if ( contact->setIndex != b3_disabledSet )
			{
				B3_ASSERT( contact->setIndex == b3_awakeSet || contact->setIndex == setIndex );
				continue;
			}

			int localIndex = contact->localIndex;

			B3_ASSERT( 0 <= localIndex && localIndex < disabledSet->contactIndices.count );
			B3_ASSERT( disabledSet->contactIndices.data[localIndex] == contactId );

			B3_ASSERT( ( contact->flags & b3_contactTouchingFlag ) == 0 && contact->manifoldCount == 0 );

			contact->setIndex = b3_awakeSet;
			contact->localIndex = awakeSet->contactIndices.count;
			b3Array_Push( awakeSet->contactIndices, contactId );

			int movedLocalIndex = b3Array_RemoveSwap( disabledSet->contactIndices, localIndex );
			if ( movedLocalIndex != B3_NULL_INDEX )
			{
				// fix moved element
				int movedContactIndex = disabledSet->contactIndices.data[localIndex];
				b3Contact* movedContact = b3Array_Get( world->contacts, movedContactIndex );
				B3_ASSERT( movedContact->localIndex == movedLocalIndex );
				movedContact->localIndex = localIndex;
			}
		}
	}

	// Transfer touching contacts from sleeping set to constraint graph.
	{
		int contactCount = set->contactIndices.count;
		for ( int i = 0; i < contactCount; ++i )
		{
			int contactIndex = set->contactIndices.data[i];
			b3Contact* contact = b3Array_Get( world->contacts, contactIndex );
			B3_ASSERT( contact->flags & b3_contactTouchingFlag );
			B3_ASSERT( contact->flags & b3_simTouchingFlag );
			B3_ASSERT( contact->setIndex == setIndex );
			b3AddContactToGraph( world, contact );
			contact->setIndex = b3_awakeSet;
		}
	}

	// transfer joints from sleeping set to awake set
	{
		int jointCount = set->jointSims.count;
		for ( int i = 0; i < jointCount; ++i )
		{
			b3JointSim* jointSim = set->jointSims.data + i;
			b3Joint* joint = b3Array_Get( world->joints, jointSim->jointId );
			B3_ASSERT( joint->setIndex == setIndex );
			b3AddJointToGraph( world, jointSim, joint );
			joint->setIndex = b3_awakeSet;
		}
	}

	// transfer island from sleeping set to awake set
	// Usually a sleeping set has only one island, but it is possible
	// that joints are created between sleeping islands and they
	// are moved to the same sleeping set.
	{
		int islandCount = set->islandSims.count;
		for ( int i = 0; i < islandCount; ++i )
		{
			b3IslandSim* islandSrc = set->islandSims.data + i;
			b3Island* island = b3Array_Get( world->islands, islandSrc->islandId );
			island->setIndex = b3_awakeSet;
			island->localIndex = awakeSet->islandSims.count;
			b3IslandSim* islandDst = b3Array_Emplace( awakeSet->islandSims );
			memcpy( islandDst, islandSrc, sizeof( b3IslandSim ) );
		}
	}

	// destroy the sleeping set
	b3DestroySolverSet( world, setIndex );
}

void b3TrySleepIsland( b3World* world, int islandId )
{
	b3Island* island = b3Array_Get( world->islands, islandId );
	B3_ASSERT( island->setIndex == b3_awakeSet );

	// Cannot put an island to sleep while it has a pending split and more than one body.
	if ( island->constraintRemoveCount > 0 && island->bodies.count > 1 )
	{
		return;
	}

	// island is sleeping
	// - create new sleeping solver set
	// - move island to sleeping solver set
	// - identify non-touching contacts that should move to sleeping solver set or disabled set
	// - remove old island
	// - fix island
	int sleepSetId = b3AllocId( &world->solverSetIdPool );
	if ( sleepSetId == world->solverSets.count )
	{
		b3SolverSet set = { 0 };
		set.setIndex = B3_NULL_INDEX;
		b3Array_Push( world->solverSets, set );
	}

	b3SolverSet* sleepSet = b3Array_Get( world->solverSets, sleepSetId );
	*sleepSet = (b3SolverSet){ 0 };

	// grab awake set after creating the sleep set because the solver set array may have been resized
	b3SolverSet* awakeSet = b3Array_Get( world->solverSets, b3_awakeSet );
	b3SolverSet* disabledSet = b3Array_Get( world->solverSets, b3_disabledSet );
	B3_ASSERT( 0 <= island->localIndex && island->localIndex < awakeSet->islandSims.count );

	sleepSet->setIndex = sleepSetId;
	b3Array_Reserve( sleepSet->bodySims, island->bodies.count );
	b3Array_Reserve( sleepSet->contactIndices, island->contacts.count );
	b3Array_Reserve( sleepSet->jointSims, island->joints.count );

	// move awake bodies to sleeping set
	// this shuffles around bodies in the awake set
	{
		for ( int i = 0; i < island->bodies.count; ++i )
		{
			int bodyId = island->bodies.data[i];
			b3Body* body = b3Array_Get( world->bodies, bodyId );
			B3_ASSERT( body->setIndex == b3_awakeSet );
			B3_ASSERT( body->islandId == islandId );
			B3_ASSERT( body->islandIndex == i );

			// Update the body move event to indicate this body fell asleep
			// It could happen the body is forced asleep before it ever moves.
			if ( body->bodyMoveIndex != B3_NULL_INDEX )
			{
				b3BodyMoveEvent* moveEvent = b3Array_Get( world->bodyMoveEvents, body->bodyMoveIndex );
				B3_ASSERT( moveEvent->bodyId.index1 - 1 == bodyId );
				B3_ASSERT( moveEvent->bodyId.generation == body->generation );
				moveEvent->fellAsleep = true;
				body->bodyMoveIndex = B3_NULL_INDEX;
			}

			int awakeBodyIndex = body->localIndex;
			b3BodySim* awakeSim = b3Array_Get( awakeSet->bodySims, awakeBodyIndex );

			// move body sim to sleep set
			int sleepBodyIndex = sleepSet->bodySims.count;
			b3BodySim* sleepBodySim = b3Array_Emplace( sleepSet->bodySims );
			memcpy( sleepBodySim, awakeSim, sizeof( b3BodySim ) );

			int movedIndex = b3Array_RemoveSwap( awakeSet->bodySims, awakeBodyIndex );
			if ( movedIndex != B3_NULL_INDEX )
			{
				// fix local index on moved element
				b3BodySim* movedSim = awakeSet->bodySims.data + awakeBodyIndex;
				int movedId = movedSim->bodyId;
				b3Body* movedBody = b3Array_Get( world->bodies, movedId );
				B3_ASSERT( movedBody->localIndex == movedIndex );
				movedBody->localIndex = awakeBodyIndex;
			}

			// destroy state, no need to clone
			b3Array_RemoveSwap( awakeSet->bodyStates, awakeBodyIndex );

			body->setIndex = sleepSetId;
			body->localIndex = sleepBodyIndex;

			// Move non-touching contacts to the disabled set.
			// Non-touching contacts may exist between sleeping islands and there is no clear ownership.
			int contactKey = body->headContactKey;
			while ( contactKey != B3_NULL_INDEX )
			{
				int contactId = contactKey >> 1;
				int edgeIndex = contactKey & 1;

				b3Contact* contact = b3Array_Get( world->contacts, contactId );

				B3_ASSERT( contact->setIndex == b3_awakeSet || contact->setIndex == b3_disabledSet );
				contactKey = contact->edges[edgeIndex].nextKey;

				if ( contact->setIndex == b3_disabledSet )
				{
					// already moved to disabled set by another body in the island
					continue;
				}

				if ( contact->colorIndex != B3_NULL_INDEX )
				{
					// contact is touching and will be moved separately
					B3_ASSERT( ( contact->flags & b3_contactTouchingFlag ) != 0 );
					continue;
				}

				// the other body may still be awake, it still may go to sleep and then it will be responsible
				// for moving this contact to the disabled set.
				int otherEdgeIndex = edgeIndex ^ 1;
				int otherBodyId = contact->edges[otherEdgeIndex].bodyId;
				b3Body* otherBody = b3Array_Get( world->bodies, otherBodyId );
				if ( otherBody->setIndex == b3_awakeSet )
				{
					continue;
				}

				int localIndex = contact->localIndex;
				B3_ASSERT( awakeSet->contactIndices.data[localIndex] == contactId );

				B3_ASSERT( contact->manifoldCount == 0 );
				B3_ASSERT( ( contact->flags & b3_contactTouchingFlag ) == 0 );

				// Move the non-touching contact to the disabled set.
				contact->setIndex = b3_disabledSet;

				// This is mandatory for validation to work correctly
				contact->localIndex = disabledSet->contactIndices.count;
				b3Array_Push( disabledSet->contactIndices, contact->contactId );

				int movedLocalIndex = b3Array_RemoveSwap( awakeSet->contactIndices, localIndex );
				if ( movedLocalIndex != B3_NULL_INDEX )
				{
					// fix moved element
					int movedContactIndex = awakeSet->contactIndices.data[localIndex];
					b3Contact* movedContact = b3Array_Get( world->contacts, movedContactIndex );
					B3_ASSERT( movedContact->localIndex == movedLocalIndex );
					movedContact->localIndex = localIndex;
				}
			}
		}
	}

	// move touching contacts to sleeping set
	// this shuffles contacts in the awake set
	{
		for ( int i = 0; i < island->contacts.count; ++i )
		{
			int contactId = island->contacts.data[i].contactId;
			b3Contact* contact = b3Array_Get( world->contacts, contactId );
			B3_ASSERT( contact->setIndex == b3_awakeSet );
			B3_ASSERT( contact->islandId == islandId );
			B3_ASSERT( contact->islandIndex == i );
			int colorIndex = contact->colorIndex;
			B3_ASSERT( 0 <= colorIndex && colorIndex < B3_GRAPH_COLOR_COUNT );

			b3GraphColor* color = world->constraintGraph.colors + colorIndex;

			// Remove bodies from graph coloring associated with this constraint
			if ( colorIndex != B3_OVERFLOW_INDEX )
			{
				// might clear a bit for a static body, but this has no effect
				b3ClearBit( &color->bodySet, contact->edges[0].bodyId );
				b3ClearBit( &color->bodySet, contact->edges[1].bodyId );
			}

			int sleepContactIndex = sleepSet->contactIndices.count;
			b3Array_Push( sleepSet->contactIndices, contactId );

			int localIndex = contact->localIndex;
			if ( ( contact->flags & b3_simMeshContact ) || colorIndex == B3_OVERFLOW_INDEX )
			{
				int movedLocalIndex = b3Array_RemoveSwap( color->contacts, localIndex );
				if ( movedLocalIndex != B3_NULL_INDEX )
				{
					// fix moved element
					int movedContactId = color->contacts.data[localIndex].contactId;
					b3Contact* movedContact = b3Array_Get( world->contacts, movedContactId );
					B3_ASSERT( movedContact->localIndex == movedLocalIndex );
					movedContact->localIndex = localIndex;
				}
			}
			else
			{
				int movedLocalIndex = b3Array_RemoveSwap( color->convexContacts, localIndex );
				if ( movedLocalIndex != B3_NULL_INDEX )
				{
					// fix moved element
					int movedContactId = color->convexContacts.data[localIndex];
					b3Contact* movedContact = b3Array_Get( world->contacts, movedContactId );
					B3_ASSERT( movedContact->localIndex == movedLocalIndex );
					movedContact->localIndex = localIndex;
				}
			}

			contact->setIndex = sleepSetId;
			contact->colorIndex = B3_NULL_INDEX;
			contact->localIndex = sleepContactIndex;
		}
	}

	// move joints
	// this shuffles joints in the awake set
	{
		for ( int i = 0; i < island->joints.count; ++i )
		{
			int jointId = island->joints.data[i].jointId;
			b3Joint* joint = b3Array_Get( world->joints, jointId );
			B3_ASSERT( joint->setIndex == b3_awakeSet );
			B3_ASSERT( joint->islandId == islandId );
			B3_ASSERT( joint->islandIndex == i );
			int colorIndex = joint->colorIndex;
			int localIndex = joint->localIndex;

			B3_ASSERT( 0 <= colorIndex && colorIndex < B3_GRAPH_COLOR_COUNT );

			b3GraphColor* color = world->constraintGraph.colors + colorIndex;

			b3JointSim* awakeJointSim = b3Array_Get( color->jointSims, localIndex );

			if ( colorIndex != B3_OVERFLOW_INDEX )
			{
				// might clear a bit for a static body, but this has no effect
				b3ClearBit( &color->bodySet, joint->edges[0].bodyId );
				b3ClearBit( &color->bodySet, joint->edges[1].bodyId );
			}

			int sleepJointIndex = sleepSet->jointSims.count;
			b3JointSim* sleepJointSim = b3Array_Emplace( sleepSet->jointSims );
			memcpy( sleepJointSim, awakeJointSim, sizeof( b3JointSim ) );

			int movedIndex = b3Array_RemoveSwap( color->jointSims, localIndex );
			if ( movedIndex != B3_NULL_INDEX )
			{
				// fix moved element
				b3JointSim* movedJointSim = color->jointSims.data + localIndex;
				int movedId = movedJointSim->jointId;
				b3Joint* movedJoint = b3Array_Get( world->joints, movedId );
				B3_ASSERT( movedJoint->localIndex == movedIndex );
				movedJoint->localIndex = localIndex;
			}

			joint->setIndex = sleepSetId;
			joint->colorIndex = B3_NULL_INDEX;
			joint->localIndex = sleepJointIndex;
		}
	}

	// move island struct
	{
		B3_ASSERT( island->setIndex == b3_awakeSet );

		int islandIndex = island->localIndex;
		b3IslandSim* sleepIsland = b3Array_Emplace( sleepSet->islandSims );
		sleepIsland->islandId = islandId;

		int movedIslandIndex = b3Array_RemoveSwap( awakeSet->islandSims, islandIndex );
		if ( movedIslandIndex != B3_NULL_INDEX )
		{
			// fix index on moved element
			b3IslandSim* movedIslandSim = awakeSet->islandSims.data + islandIndex;
			int movedIslandId = movedIslandSim->islandId;
			b3Island* movedIsland = b3Array_Get( world->islands, movedIslandId );
			B3_ASSERT( movedIsland->localIndex == movedIslandIndex );
			movedIsland->localIndex = islandIndex;
		}

		island->setIndex = sleepSetId;
		island->localIndex = 0;
	}

	if ( world->splitIslandId == islandId )
	{
		world->splitIslandId = B3_NULL_INDEX;
	}

	b3ValidateSolverSets( world );
}

// This is called when joints are created between sets. I want to allow the sets
// to continue sleeping if both are asleep. Otherwise one set is waked.
// Islands will get merge when the set is woke.
void b3MergeSolverSets( b3World* world, int setId1, int setId2 )
{
	B3_ASSERT( setId1 >= b3_firstSleepingSet );
	B3_ASSERT( setId2 >= b3_firstSleepingSet );
	b3SolverSet* set1 = b3Array_Get( world->solverSets, setId1 );
	b3SolverSet* set2 = b3Array_Get( world->solverSets, setId2 );

	// Move the fewest number of bodies
	if ( set1->bodySims.count < set2->bodySims.count )
	{
		b3SolverSet* tempSet = set1;
		set1 = set2;
		set2 = tempSet;

		int tempId = setId1;
		setId1 = setId2;
		setId2 = tempId;
	}

	// transfer bodies
	{
		b3Body* bodies = world->bodies.data;
		int bodyCount = set2->bodySims.count;
		for ( int i = 0; i < bodyCount; ++i )
		{
			b3BodySim* simSrc = set2->bodySims.data + i;

			b3Body* body = bodies + simSrc->bodyId;
			B3_ASSERT( body->setIndex == setId2 );
			body->setIndex = setId1;
			body->localIndex = set1->bodySims.count;

			b3BodySim* simDst = b3Array_Emplace( set1->bodySims );
			memcpy( simDst, simSrc, sizeof( b3BodySim ) );
		}
	}

	// transfer contacts
	{
		int contactCount = set2->contactIndices.count;
		for ( int i = 0; i < contactCount; ++i )
		{
			int contactIndex = set2->contactIndices.data[i];
			b3Contact* contact = b3Array_Get( world->contacts, contactIndex );
			B3_ASSERT( contact->setIndex == setId2 );
			contact->setIndex = setId1;
			contact->localIndex = set1->contactIndices.count;
			b3Array_Push( set1->contactIndices, contactIndex );
		}
	}

	// transfer joints
	{
		int jointCount = set2->jointSims.count;
		for ( int i = 0; i < jointCount; ++i )
		{
			b3JointSim* jointSrc = set2->jointSims.data + i;

			b3Joint* joint = b3Array_Get( world->joints, jointSrc->jointId );
			B3_ASSERT( joint->setIndex == setId2 );
			joint->setIndex = setId1;
			joint->localIndex = set1->jointSims.count;

			b3JointSim* jointDst = b3Array_Emplace( set1->jointSims );
			memcpy( jointDst, jointSrc, sizeof( b3JointSim ) );
		}
	}

	// transfer islands
	{
		int islandCount = set2->islandSims.count;
		for ( int i = 0; i < islandCount; ++i )
		{
			b3IslandSim* islandSrc = set2->islandSims.data + i;
			int islandId = islandSrc->islandId;

			b3Island* island = b3Array_Get( world->islands, islandId );
			island->setIndex = setId1;
			island->localIndex = set1->islandSims.count;

			b3IslandSim* islandDst = b3Array_Emplace( set1->islandSims );
			memcpy( islandDst, islandSrc, sizeof( b3IslandSim ) );
		}
	}

	// destroy the merged set
	// Warning: need to be careful not to destroy things that got transferred, like triangle caches.
	b3DestroySolverSet( world, setId2 );

	b3ValidateSolverSets( world );
}

void b3TransferBody( b3World* world, b3SolverSet* targetSet, b3SolverSet* sourceSet, b3Body* body )
{
	if ( targetSet == sourceSet )
	{
		return;
	}

	int sourceIndex = body->localIndex;
	b3BodySim* sourceSim = b3Array_Get( sourceSet->bodySims, sourceIndex );

	int targetIndex = targetSet->bodySims.count;
	b3BodySim* targetSim = b3Array_Emplace( targetSet->bodySims );
	memcpy( targetSim, sourceSim, sizeof( b3BodySim ) );

	// Clear transient body flags
	targetSim->flags &= ~( b3_isFast | b3_isSpeedCapped | b3_hadTimeOfImpact );

	// Remove body sim from solver set that owns it
	int movedIndex = b3Array_RemoveSwap( sourceSet->bodySims, sourceIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		// Fix moved body index
		b3BodySim* movedSim = sourceSet->bodySims.data + sourceIndex;
		int movedId = movedSim->bodyId;
		b3Body* movedBody = b3Array_Get( world->bodies, movedId );
		B3_ASSERT( movedBody->localIndex == movedIndex );
		movedBody->localIndex = sourceIndex;
	}

	if ( sourceSet->setIndex == b3_awakeSet )
	{
		b3Array_RemoveSwap( sourceSet->bodyStates, sourceIndex );
	}
	else if ( targetSet->setIndex == b3_awakeSet )
	{
		b3BodyState* state = b3Array_Emplace( targetSet->bodyStates );
		*state = b3_identityBodyState;
		state->flags = body->flags;
	}

	body->setIndex = targetSet->setIndex;
	body->localIndex = targetIndex;
}

void b3TransferJoint( b3World* world, b3SolverSet* targetSet, b3SolverSet* sourceSet, b3Joint* joint )
{
	if ( targetSet == sourceSet )
	{
		return;
	}

	int localIndex = joint->localIndex;
	int colorIndex = joint->colorIndex;

	// Retrieve source.
	b3JointSim* sourceSim;
	if ( sourceSet->setIndex == b3_awakeSet )
	{
		B3_ASSERT( 0 <= colorIndex && colorIndex < B3_GRAPH_COLOR_COUNT );
		b3GraphColor* color = world->constraintGraph.colors + colorIndex;

		sourceSim = b3Array_Get( color->jointSims, localIndex );
	}
	else
	{
		B3_ASSERT( colorIndex == B3_NULL_INDEX );
		sourceSim = b3Array_Get( sourceSet->jointSims, localIndex );
	}

	// Create target and copy. Fix joint.
	if ( targetSet->setIndex == b3_awakeSet )
	{
		b3AddJointToGraph( world, sourceSim, joint );
		joint->setIndex = b3_awakeSet;
	}
	else
	{
		joint->setIndex = targetSet->setIndex;
		joint->localIndex = targetSet->jointSims.count;
		joint->colorIndex = B3_NULL_INDEX;

		b3JointSim* targetSim = b3Array_Emplace( targetSet->jointSims );
		memcpy( targetSim, sourceSim, sizeof( b3JointSim ) );
	}

	// Destroy source.
	if ( sourceSet->setIndex == b3_awakeSet )
	{
		b3RemoveJointFromGraph( world, joint->edges[0].bodyId, joint->edges[1].bodyId, colorIndex, localIndex );
	}
	else
	{
		int movedIndex = b3Array_RemoveSwap( sourceSet->jointSims, localIndex );
		if ( movedIndex != B3_NULL_INDEX )
		{
			// fix swapped element
			b3JointSim* movedJointSim = sourceSet->jointSims.data + localIndex;
			int movedId = movedJointSim->jointId;
			b3Joint* movedJoint = b3Array_Get( world->joints, movedId );
			movedJoint->localIndex = localIndex;
		}
	}
}
