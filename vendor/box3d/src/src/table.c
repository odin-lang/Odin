// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "table.h"

#include "bitset.h"
#include "core.h"
#include "ctz.h"
#include "platform.h"

#include <string.h>

#if B3_DEBUG
b3AtomicInt b3_probeCount;
#endif

_Static_assert( 2 * B3_SHAPE_POWER + B3_CHILD_POWER == 64, "compound power" );
_Static_assert( B3_CHILD_POWER > 8, "compound child power" );

b3HashSet b3CreateSet( int32_t capacity )
{
	b3HashSet set = { 0 };

	// Capacity must be a power of 2
	if ( capacity > 16 )
	{
		set.capacity = b3RoundUpPowerOf2( capacity );
	}
	else
	{
		set.capacity = 16;
	}

	set.count = 0;
	set.items = (b3SetItem*)b3Alloc( set.capacity * sizeof( b3SetItem ) );
	memset( set.items, 0, set.capacity * sizeof( b3SetItem ) );

	return set;
}

void b3DestroySet( b3HashSet* set )
{
	b3Free( set->items, set->capacity * sizeof( b3SetItem ) );
	set->items = NULL;
	set->count = 0;
	set->capacity = 0;
}

void b3ClearSet( b3HashSet* set )
{
	set->count = 0;
	memset( set->items, 0, set->capacity * sizeof( b3SetItem ) );
}

// I need a good hash because the keys are built from pairs of increasing integers.
// A simple hash like hash = (integer1 XOR integer2) has many collisions.
// https://lemire.me/blog/2018/08/15/fast-strongly-universal-64-bit-hashing-everywhere/
// https://preshing.com/20130107/this-hash-set-is-faster-than-a-judy-array/
// todo try: https://www.jandrewrogers.com/2019/02/12/fast-perfect-hashing/
// todo try:
// https://probablydance.com/2018/06/16/fibonacci-hashing-the-optimization-that-the-world-forgot-or-a-better-alternative-to-integer-modulo/
static inline uint32_t b3KeyHash( uint64_t key )
{
	uint64_t h = key;
	h ^= h >> 33;
	h *= 0xff51afd7ed558ccdL;
	h ^= h >> 33;
	h *= 0xc4ceb9fe1a85ec53L;
	h ^= h >> 33;

	return (uint32_t)h;
}

static int32_t b3FindSlot( const b3HashSet* set, uint64_t key, uint32_t hash )
{
	uint32_t capacity = set->capacity;
	int32_t index = hash & ( capacity - 1 );
	const b3SetItem* items = set->items;
	while ( items[index].hash != 0 && items[index].key != key )
	{
#if B3_DEBUG
		b3AtomicFetchAddInt( &b3_probeCount, 1 );
#endif
		index = ( index + 1 ) & ( capacity - 1 );
	}

	return index;
}

static void b3AddKeyHaveCapacity( b3HashSet* set, uint64_t key, uint32_t hash )
{
	int32_t index = b3FindSlot( set, key, hash );
	b3SetItem* items = set->items;
	B3_ASSERT( items[index].hash == 0 );

	items[index].key = key;
	items[index].hash = hash;
	set->count += 1;
}

static void b3GrowTable( b3HashSet* set )
{
	uint32_t oldCount = set->count;
	B3_UNUSED( oldCount );

	uint32_t oldCapacity = set->capacity;
	b3SetItem* oldItems = set->items;

	set->count = 0;
	// Capacity must be a power of 2
	set->capacity = 2 * oldCapacity;
	set->items = (b3SetItem*)b3Alloc( set->capacity * sizeof( b3SetItem ) );
	memset( set->items, 0, set->capacity * sizeof( b3SetItem ) );

	// Transfer items into new array
	for ( uint32_t i = 0; i < oldCapacity; ++i )
	{
		b3SetItem* item = oldItems + i;
		if ( item->hash == 0 )
		{
			// this item was empty
			continue;
		}

		b3AddKeyHaveCapacity( set, item->key, item->hash );
	}

	B3_ASSERT( set->count == oldCount );

	b3Free( oldItems, oldCapacity * sizeof( b3SetItem ) );
}

bool b3ContainsKey( const b3HashSet* set, uint64_t key )
{
	// key of zero is a sentinel
	B3_ASSERT( key != 0 );
	uint32_t hash = b3KeyHash( key );
	int32_t index = b3FindSlot( set, key, hash );
	return set->items[index].key == key;
}

int b3GetHashSetBytes( b3HashSet* set )
{
	return set->capacity * (int)sizeof( b3SetItem );
}

bool b3AddKey( b3HashSet* set, uint64_t key )
{
	// key of zero is a sentinel
	B3_ASSERT( key != 0 );

	uint32_t hash = b3KeyHash( key );
	B3_ASSERT( hash != 0 );

	int32_t index = b3FindSlot( set, key, hash );
	if ( set->items[index].hash != 0 )
	{
		// Already in set
		B3_ASSERT( set->items[index].hash == hash && set->items[index].key == key );
		return true;
	}

	if ( 2 * set->count >= set->capacity )
	{
		b3GrowTable( set );
	}

	b3AddKeyHaveCapacity( set, key, hash );
	return false;
}

// See https://en.wikipedia.org/wiki/Open_addressing
bool b3RemoveKey( b3HashSet* set, uint64_t key )
{
	uint32_t hash = b3KeyHash( key );
	int32_t i = b3FindSlot( set, key, hash );
	b3SetItem* items = set->items;
	if ( items[i].hash == 0 )
	{
		// Not in set
		return false;
	}

	// Mark item i as unoccupied
	items[i].key = 0;
	items[i].hash = 0;

	B3_ASSERT( set->count > 0 );
	set->count -= 1;

	// Attempt to fill item i
	int32_t j = i;
	uint32_t capacity = set->capacity;
	for ( ;; )
	{
		j = ( j + 1 ) & ( capacity - 1 );
		if ( items[j].hash == 0 )
		{
			break;
		}

		// k is the first item for the hash of j
		int32_t k = items[j].hash & ( capacity - 1 );

		// determine if k lies cyclically in (i,j]
		// i <= j: | i..k..j |
		// i > j: |.k..j  i....| or |....j     i..k.|
		if ( i <= j )
		{
			if ( i < k && k <= j )
			{
				continue;
			}
		}
		else
		{
			if ( i < k || k <= j )
			{
				continue;
			}
		}

		// Move j into i
		items[i] = items[j];

		// Mark item j as unoccupied
		items[j].key = 0;
		items[j].hash = 0;

		i = j;
	}

	return true;
}

// This function is here because ctz.h is included by
// this file but not in bitset.c
int b3CountSetBits( b3BitSet* bitSet )
{
	int popCount = 0;
	uint32_t blockCount = bitSet->blockCount;
	for ( uint32_t i = 0; i < blockCount; ++i )
	{
		popCount += b3PopCount64( bitSet->bits[i] );
	}

	return popCount;
}
