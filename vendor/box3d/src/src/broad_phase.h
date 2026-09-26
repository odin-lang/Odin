// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "bitset.h"
#include "container.h"
#include "table.h"

#include "box3d/collision.h"
#include "box3d/types.h"

typedef struct b3Shape b3Shape;
typedef struct b3MovePair b3MovePair;
typedef struct b3MoveResult b3MoveResult;
typedef struct b3Stack b3Stack;
typedef struct b3World b3World;

// Store the proxy type in the lower 2 bits of the proxy key. This leaves 30 bits for the id.
#define B3_PROXY_TYPE( KEY ) ( (b3BodyType)( ( KEY ) & 3 ) )
#define B3_PROXY_ID( KEY ) ( ( KEY ) >> 2 )
#define B3_PROXY_KEY( ID, TYPE ) ( ( ( ID ) << 2 ) | ( TYPE ) )

/// The broad-phase is used for computing pairs and performing volume queries and ray casts.
/// This broad-phase does not persist pairs. Instead, this reports potentially new pairs.
/// It is up to the client to consume the new pairs and to track subsequent overlap.
typedef struct b3BroadPhase
{
	b3DynamicTree trees[b3_bodyTypeCount];

	// Per body-type bit sets indexed by proxyId, marking proxies moved this step.
	// Paired with moveArray which preserves deterministic insertion order for pair queries.
	b3BitSet movedProxies[b3_bodyTypeCount];
	b3Array( int ) moveArray;

	// These are the results from the pair query and are used to create new contacts
	// in deterministic order.
	// todo these could be in the step context
	b3MoveResult* moveResults;
	b3MovePair* movePairs;
	int movePairCapacity;
	b3AtomicInt movePairIndex;

	// Tracks shape pairs that have a b3Contact
	// todo pairSet can grow quite large on the first time step and remain large
	b3HashSet pairSet;
} b3BroadPhase;

void b3CreateBroadPhase( b3BroadPhase* bp, const b3Capacity* capacity );
void b3DestroyBroadPhase( b3BroadPhase* bp );

int b3BroadPhase_CreateProxy( b3BroadPhase* bp, b3BodyType proxyType, b3AABB aabb, uint64_t categoryBits, int shapeIndex,
							  bool forcePairCreation );
void b3BroadPhase_DestroyProxy( b3BroadPhase* bp, int proxyKey );

void b3BroadPhase_MoveProxy( b3BroadPhase* bp, int proxyKey, b3AABB aabb );
void b3BroadPhase_EnlargeProxy( b3BroadPhase* bp, int proxyKey, b3AABB aabb );

int b3BroadPhase_GetShapeIndex( b3BroadPhase* bp, int proxyKey );

void b3UpdateBroadPhasePairs( b3World* world );
bool b3BroadPhase_TestOverlap( const b3BroadPhase* bp, int proxyKeyA, int proxyKeyB );

void b3ValidateBroadPhase( const b3BroadPhase* bp );
void b3ValidateNoEnlarged( const b3BroadPhase* bp );

// This is what triggers new contact pairs to be created
// Warning: this must be called in deterministic order
static inline void b3BufferMove( b3BroadPhase* bp, int queryProxy )
{
	b3BodyType proxyType = B3_PROXY_TYPE( queryProxy );
	int proxyId = B3_PROXY_ID( queryProxy );
	b3BitSet* set = &bp->movedProxies[proxyType];
	if ( b3GetBit( set, proxyId ) == false )
	{
		b3SetBitGrow( set, proxyId );
		b3Array_Push( bp->moveArray, queryProxy );
	}
}
