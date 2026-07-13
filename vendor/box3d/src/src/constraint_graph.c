// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "constraint_graph.h"

#include "bitset.h"
#include "body.h"
#include "contact.h"
#include "joint.h"
#include "physics_world.h"

#include <string.h>

// Solver using graph coloring. Islands are only used for sleep.
// High-Performance Physical Simulations on Next-Generation Architecture with Many Cores
// http://web.eecs.umich.edu/~msmelyan/papers/physsim_onmanycore_itj.pdf

// Kinematic bodies have to be treated like dynamic bodies in graph coloring. Unlike static bodies, we cannot use a dummy solver
// body for kinematic bodies. We cannot access a kinematic body from multiple threads efficiently because the SIMD solver body
// scatter would write to the same kinematic body from multiple threads. Even if these writes don't modify the body, they will
// cause horrible cache stalls. To make this feasible I would need a way to block these writes.

// This is used for debugging by making all constraints be assigned to overflow.
#define B3_FORCE_OVERFLOW 0

static const b3HexColor b3_graphColors[B3_GRAPH_COLOR_COUNT] = {
	b3_colorRed,	   b3_colorOrange,		b3_colorYellow,			b3_colorLimeGreen,		 b3_colorSpringGreen,
	b3_colorAqua,	   b3_colorDodgerBlue,	b3_colorBlueViolet,		b3_colorMagenta,		 b3_colorDeepPink,
	b3_colorCrimson,   b3_colorCoral,		b3_colorGold,			b3_colorGreenYellow,	 b3_colorMediumSeaGreen,
	b3_colorTurquoise, b3_colorDeepSkyBlue, b3_colorCornflowerBlue, b3_colorMediumSlateBlue, b3_colorMediumOrchid,
	b3_colorHotPink,   b3_colorTomato,		b3_colorKhaki,			b3_colorSilver,
};

b3HexColor b3GetGraphColor( int index )
{
	B3_ASSERT( 0 <= index && index < B3_GRAPH_COLOR_COUNT );
	return b3_graphColors[index];
}

void b3CreateGraph( b3ConstraintGraph* graph, int bodyCapacity )
{
	_Static_assert( B3_GRAPH_COLOR_COUNT >= 2, "must have at least two constraint graph colors" );
	_Static_assert( B3_OVERFLOW_INDEX == B3_GRAPH_COLOR_COUNT - 1, "bad over flow index" );

	*graph = (b3ConstraintGraph){ 0 };

	bodyCapacity = b3MaxInt( bodyCapacity, 8 );

	// Initialize graph color bit set.
	// No bitset for overflow color.
	for ( int i = 0; i < B3_OVERFLOW_INDEX; ++i )
	{
		b3GraphColor* color = graph->colors + i;
		color->bodySet = b3CreateBitSet( bodyCapacity );
		b3SetBitCountAndClear( &color->bodySet, bodyCapacity );
	}
}

void b3DestroyGraph( b3ConstraintGraph* graph )
{
	for ( int i = 0; i < B3_GRAPH_COLOR_COUNT; ++i )
	{
		b3GraphColor* color = graph->colors + i;

		// The bit set should never be used on the overflow color
		B3_ASSERT( i != B3_OVERFLOW_INDEX || color->bodySet.bits == NULL );

		b3DestroyBitSet( &color->bodySet );

		b3Array_Destroy( color->convexContacts );
		b3Array_Destroy( color->contacts );
		b3Array_Destroy( color->jointSims );
	}
}

// Contacts are always created as non-touching. They get cloned into the constraint
// graph once they are found to be touching.
void b3AddContactToGraph( b3World* world, b3Contact* contact )
{
	B3_ASSERT( contact->manifoldCount > 0 );
	B3_ASSERT( contact->flags & b3_contactTouchingFlag );

	b3ConstraintGraph* graph = &world->constraintGraph;
	int colorIndex = B3_OVERFLOW_INDEX;

	int bodyIdA = contact->edges[0].bodyId;
	int bodyIdB = contact->edges[1].bodyId;
	b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
	b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );

	b3BodyType typeA = bodyA->type;
	b3BodyType typeB = bodyB->type;
	B3_ASSERT( typeA == b3_dynamicBody || typeB == b3_dynamicBody );

#if B3_FORCE_OVERFLOW == 0
	if ( typeA == b3_dynamicBody && typeB == b3_dynamicBody )
	{
		// Dynamic constraint colors cannot encroach on colors reserved for static constraints
		for ( int i = 0; i < B3_DYNAMIC_COLOR_COUNT; ++i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdA ) || b3GetBit( &color->bodySet, bodyIdB ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdA );
			b3SetBitGrow( &color->bodySet, bodyIdB );
			colorIndex = i;
			break;
		}
	}
	else if ( typeA == b3_dynamicBody )
	{
		// Static constraint colors build from the end to get higher priority than dyn-dyn constraints
		for ( int i = B3_OVERFLOW_INDEX - 1; i >= 1; --i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdA ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdA );
			colorIndex = i;
			break;
		}
	}
	else if ( typeB == b3_dynamicBody )
	{
		// Static constraint colors build from the end to get higher priority than dyn-dyn constraints
		for ( int i = B3_OVERFLOW_INDEX - 1; i >= 1; --i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdB ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdB );
			colorIndex = i;
			break;
		}
	}
#endif

	bool isScalar = ( contact->flags & b3_simMeshContact ) || colorIndex == B3_OVERFLOW_INDEX;

	b3GraphColor* color = graph->colors + colorIndex;
	contact->colorIndex = colorIndex;
	contact->localIndex = isScalar ? color->contacts.count : color->convexContacts.count;
	contact->bodySimIndexA = bodyA->type == b3_staticBody ? B3_NULL_INDEX : bodyA->localIndex;
	contact->bodySimIndexB = bodyB->type == b3_staticBody ? B3_NULL_INDEX : bodyB->localIndex;

	if ( isScalar )
	{
		B3_ASSERT( contact->manifoldCount < UINT16_MAX );
		b3ContactSpec spec = {
			.contactId = contact->contactId,
			.manifoldStart = 0,
			.manifoldCount = (uint16_t)contact->manifoldCount,
		};
		b3Array_Push( color->contacts, spec );
	}
	else
	{
		b3Array_Push( color->convexContacts, contact->contactId );
	}
}

void b3RemoveContactFromGraph( b3World* world, int bodyIdA, int bodyIdB, int colorIndex, int localIndex, bool meshContact )
{
	b3ConstraintGraph* graph = &world->constraintGraph;

	B3_ASSERT( 0 <= colorIndex && colorIndex < B3_GRAPH_COLOR_COUNT );
	b3GraphColor* color = graph->colors + colorIndex;

	if ( colorIndex != B3_OVERFLOW_INDEX )
	{
		// This might clear a bit for a static body, but this has no effect
		b3ClearBit( &color->bodySet, bodyIdA );
		b3ClearBit( &color->bodySet, bodyIdB );
	}

	if ( meshContact || colorIndex == B3_OVERFLOW_INDEX )
	{
		int movedIndex = b3Array_RemoveSwap( color->contacts, localIndex );
		if ( movedIndex != B3_NULL_INDEX )
		{
			// Fix index on swapped contact
			int movedContactId = color->contacts.data[localIndex].contactId;
			b3Contact* movedContact = b3Array_Get( world->contacts, movedContactId );
			B3_ASSERT( movedContact->setIndex == b3_awakeSet );
			B3_ASSERT( movedContact->colorIndex == colorIndex );
			B3_ASSERT( movedContact->localIndex == movedIndex );
			movedContact->localIndex = localIndex;
		}
	}
	else
	{
		int movedIndex = b3Array_RemoveSwap( color->convexContacts, localIndex );
		if ( movedIndex != B3_NULL_INDEX )
		{
			// Fix index on swapped contact
			int movedContactId = color->convexContacts.data[localIndex];
			b3Contact* movedContact = b3Array_Get( world->contacts, movedContactId );
			B3_ASSERT( movedContact->setIndex == b3_awakeSet );
			B3_ASSERT( movedContact->colorIndex == colorIndex );
			B3_ASSERT( movedContact->localIndex == movedIndex );
			B3_ASSERT( ( movedContact->flags & b3_simMeshContact ) == 0 );
			movedContact->localIndex = localIndex;
		}
	}
}

static int b3AssignJointColor( b3ConstraintGraph* graph, int bodyIdA, int bodyIdB, b3BodyType typeA, b3BodyType typeB )
{
	B3_ASSERT( typeA == b3_dynamicBody || typeB == b3_dynamicBody );
	B3_UNUSED( graph );
	B3_UNUSED( bodyIdA );
	B3_UNUSED( bodyIdB );
	B3_UNUSED( typeA );
	B3_UNUSED( typeB );

#if B3_FORCE_OVERFLOW == 0
	if ( typeA == b3_dynamicBody && typeB == b3_dynamicBody )
	{
		// Dynamic constraint colors cannot encroach on colors reserved for static constraints
		for ( int i = 0; i < B3_DYNAMIC_COLOR_COUNT; ++i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdA ) || b3GetBit( &color->bodySet, bodyIdB ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdA );
			b3SetBitGrow( &color->bodySet, bodyIdB );
			return i;
		}
	}
	else if ( typeA == b3_dynamicBody )
	{
		// Static constraint colors build from the end to get higher priority than dyn-dyn constraints
		for ( int i = B3_OVERFLOW_INDEX - 1; i >= 1; --i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdA ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdA );
			return i;
		}
	}
	else if ( typeB == b3_dynamicBody )
	{
		// Static constraint colors build from the end to get higher priority than dyn-dyn constraints
		for ( int i = B3_OVERFLOW_INDEX - 1; i >= 1; --i )
		{
			b3GraphColor* color = graph->colors + i;
			if ( b3GetBit( &color->bodySet, bodyIdB ) )
			{
				continue;
			}

			b3SetBitGrow( &color->bodySet, bodyIdB );
			return i;
		}
	}
#endif

	return B3_OVERFLOW_INDEX;
}

b3JointSim* b3CreateJointInGraph( b3World* world, b3Joint* joint )
{
	b3ConstraintGraph* graph = &world->constraintGraph;

	int bodyIdA = joint->edges[0].bodyId;
	int bodyIdB = joint->edges[1].bodyId;
	b3Body* bodyA = b3Array_Get( world->bodies, bodyIdA );
	b3Body* bodyB = b3Array_Get( world->bodies, bodyIdB );

	int colorIndex = b3AssignJointColor( graph, bodyIdA, bodyIdB, bodyA->type, bodyB->type );

	b3JointSim* jointSim = b3Array_Emplace( graph->colors[colorIndex].jointSims );
	memset( jointSim, 0, sizeof( b3JointSim ) );

	joint->colorIndex = colorIndex;
	joint->localIndex = graph->colors[colorIndex].jointSims.count - 1;
	return jointSim;
}

void b3AddJointToGraph( b3World* world, b3JointSim* jointSim, b3Joint* joint )
{
	b3JointSim* jointDst = b3CreateJointInGraph( world, joint );
	memcpy( jointDst, jointSim, sizeof( b3JointSim ) );
}

void b3RemoveJointFromGraph( b3World* world, int bodyIdA, int bodyIdB, int colorIndex, int localIndex )
{
	b3ConstraintGraph* graph = &world->constraintGraph;

	B3_ASSERT( 0 <= colorIndex && colorIndex < B3_GRAPH_COLOR_COUNT );
	b3GraphColor* color = graph->colors + colorIndex;

	if ( colorIndex != B3_OVERFLOW_INDEX )
	{
		// May clear static bodies, no effect
		b3ClearBit( &color->bodySet, bodyIdA );
		b3ClearBit( &color->bodySet, bodyIdB );
	}

	int movedIndex = b3Array_RemoveSwap( color->jointSims, localIndex );
	if ( movedIndex != B3_NULL_INDEX )
	{
		// Fix moved joint
		b3JointSim* movedJointSim = color->jointSims.data + localIndex;
		int movedId = movedJointSim->jointId;
		b3Joint* movedJoint = b3Array_Get( world->joints, movedId );
		B3_ASSERT( movedJoint->setIndex == b3_awakeSet );
		B3_ASSERT( movedJoint->colorIndex == colorIndex );
		B3_ASSERT( movedJoint->localIndex == movedIndex );
		movedJoint->localIndex = localIndex;
	}
}
