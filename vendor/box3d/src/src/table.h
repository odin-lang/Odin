// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/constants.h"

#include <stdbool.h>
#include <stdint.h>

typedef struct b3SetItem
{
	uint64_t key;
	uint32_t hash;
} b3SetItem;

typedef struct b3HashSet
{
	b3SetItem* items;
	uint32_t capacity;
	uint32_t count;
} b3HashSet;

#define B3_SHAPE_MASK ( B3_MAX_SHAPES - 1 )
#define B3_CHILD_MASK ( B3_MAX_CHILD_SHAPES - 1 )

static inline uint64_t b3ShapePairKey( int s1, int s2, int c )
{
	if (s1 < s2)
	{
		return ( (uint64_t)( B3_SHAPE_MASK & s1 ) << ( 64 - B3_SHAPE_POWER ) ) |
			   ( (uint64_t)( B3_SHAPE_MASK & s2 ) << ( 64 - 2 * B3_SHAPE_POWER ) ) | ( (uint64_t)( B3_CHILD_MASK & c ) );
	}

	return ( (uint64_t)( B3_SHAPE_MASK & s2 ) << ( 64 - B3_SHAPE_POWER ) ) |
		   ( (uint64_t)( B3_SHAPE_MASK & s1 ) << ( 64 - 2 * B3_SHAPE_POWER ) ) |
		   ( (uint64_t)( B3_CHILD_MASK & c ) );
}

b3HashSet b3CreateSet( int32_t capacity );
void b3DestroySet( b3HashSet* set );

void b3ClearSet( b3HashSet* set );

// Returns true if key was already in set
bool b3AddKey( b3HashSet* set, uint64_t key );

// Returns true if the key was found
bool b3RemoveKey( b3HashSet* set, uint64_t key );

bool b3ContainsKey( const b3HashSet* set, uint64_t key );

int b3GetHashSetBytes( b3HashSet* set );
