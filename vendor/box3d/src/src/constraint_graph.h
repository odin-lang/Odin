// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "bitset.h"
#include "contact.h"
#include "container.h"
#include "solver.h"
#include "solver_set.h"
#include "box3d/constants.h"

typedef struct b3Body b3Body;
typedef struct b3Contact b3Contact;
typedef struct b3JointSim b3JointSim;
typedef struct b3Joint b3Joint;
typedef struct b3StepContext b3StepContext;
typedef struct b3World b3World;

// This holds constraints that cannot fit the graph color limit. This happens when a single dynamic body
// is touching many other bodies.
#define B3_OVERFLOW_INDEX ( B3_GRAPH_COLOR_COUNT - 1 )

// This keeps constraints involving two dynamic bodies at a lower solver priority than constraints
// involving a dynamic and static bodies. This reduces tunneling due to push through.
#define B3_DYNAMIC_COLOR_COUNT ( B3_GRAPH_COLOR_COUNT - 4 )

// todo optimize mesh contact constraints
// They can be lumped with convex contacts and I can use the bitset event to re-link if the manifold count increases
// Could also create a group for two wide manifolds and use bitset event
// This could create ping-pong jitter so may need to pin to high water mark or introduce hysteresis somehow
//
// Dirk has the idea to do graph coloring based on manifolds. This suggests mesh contact will have manifolds
// in multiple graph colors. So each manifold with have a color and local index.
// Some concerns about this:
// - manifolds don't have a strong identity, would this affect stability/jitter?
// - this creates a lot of static graph colors and can overflow

typedef struct b3GraphColor
{
	// This bitset is indexed by bodyId so this is over-sized to encompass static bodies
	// however I never traverse these bits or use the bit count for anything
	// This bitset is unused on the overflow color.
	b3BitSet bodySet;

	// cache friendly arrays
	b3Array( b3JointSim ) jointSims;

	b3Array( int ) convexContacts;
	b3Array( b3ContactSpec ) contacts;

	// These are used for convex contacts
	struct b3ContactConstraintWide* wideConstraints;
	int wideConstraintCount;

	// These are used for mesh and overflow contacts
	struct b3ManifoldConstraint* manifoldConstraints;
	int manifoldConstraintCount;
	struct b3ContactConstraint* contactConstraints;
	int contactConstraintCount;
} b3GraphColor;

typedef struct b3ConstraintGraph
{
	// including overflow at the end
	b3GraphColor colors[B3_GRAPH_COLOR_COUNT];
} b3ConstraintGraph;

void b3CreateGraph( b3ConstraintGraph* graph, int bodyCapacity );
void b3DestroyGraph( b3ConstraintGraph* graph );

void b3AddContactToGraph( b3World* world, b3Contact* contact );
void b3RemoveContactFromGraph( b3World* world, int bodyIdA, int bodyIdB, int colorIndex, int localIndex, bool meshContact );

b3JointSim* b3CreateJointInGraph( b3World* world, b3Joint* joint );
void b3AddJointToGraph( b3World* world, b3JointSim* jointSim, b3Joint* joint );
void b3RemoveJointFromGraph( b3World* world, int bodyIdA, int bodyIdB, int colorIndex, int localIndex );
