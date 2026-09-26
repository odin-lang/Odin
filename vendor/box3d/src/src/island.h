// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "container.h"

#include <stdint.h>

typedef struct b3Contact b3Contact;
typedef struct b3Joint b3Joint;
typedef struct b3World b3World;

// Cached contact data stored in the island for fast contiguous iteration.
// Avoids touching b3Contact during union-find in b3SplitIsland.
typedef struct b3ContactLink
{
	int contactId;
	int bodyIdA;
	int bodyIdB;
} b3ContactLink;

b3DeclareArray( b3ContactLink );

// Cached joint data stored in the island for fast contiguous iteration.
typedef struct b3JointLink
{
	int jointId;
	int bodyIdA;
	int bodyIdB;
} b3JointLink;

b3DeclareArray( b3JointLink );

// Deterministic solver
//
// Collide all awake contacts
// Use bit array to emit start/stop touching events in defined order, per thread. Try using contact index, assuming contacts are
// created in a deterministic order. bit-wise OR together bit arrays and issue changes:
// - start touching: merge islands - temporary linked list - mark root island dirty - wake all - largest island is root
// - stop touching: increment constraintRemoveCount

// Persistent island for awake bodies, joints, and contacts.
// Contacts are touching.
// Contacts and joints may connect to static bodies, but static bodies are not in the island.
// https://en.wikipedia.org/wiki/Component_(graph_theory)
// https://en.wikipedia.org/wiki/Dynamic_connectivity
typedef struct b3Island
{
	// index of solver set stored in b3World
	// may be B3_NULL_INDEX
	int setIndex;

	// island index within set
	// may be B3_NULL_INDEX
	int localIndex;

	int islandId;

	// Keeps track of how many contacts have been removed from this island.
	// This is used to determine if an island is a candidate for splitting.
	int constraintRemoveCount;

	// I tried using a stack array for this but the data pointer goes out of
	// sync when the world island array grows.
	b3Array( int ) bodies;

	// Contacts and joints that belong to this island. May connect to static
	// bodies not in the island.
	// Each link has the two body ids so that b3SplitIsland's union-find pass
	// never needs to touch b3Contact/b3Joint.
	b3Array( b3ContactLink ) contacts;
	b3Array( b3JointLink ) joints;

} b3Island;

// This is used to move islands across solver sets
typedef struct b3IslandSim
{
	int islandId;
} b3IslandSim;

b3Island* b3CreateIsland( b3World* world, int setIndex );
void b3DestroyIsland( b3World* world, int islandId );

// Link contacts into the island graph when it starts having contact points
void b3LinkContact( b3World* world, b3Contact* contact );

// Unlink contact from the island graph when it stops having contact points
void b3UnlinkContact( b3World* world, b3Contact* contact );

// Link a joint into the island graph when it is created
void b3LinkJoint( b3World* world, b3Joint* joint );

// Unlink a joint from the island graph when it is destroyed
void b3UnlinkJoint( b3World* world, b3Joint* joint );

void b3SplitIsland( b3World* world, int baseId );
void b3SplitIslandTask( void* context );

void b3ValidateIsland( b3World* world, int islandId );
