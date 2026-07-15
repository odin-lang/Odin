// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include <stdint.h>
#include <stdbool.h>

// Bit set provides fast operations on large arrays of bits.
typedef struct b3BitSet
{
	uint64_t* bits;
	uint32_t blockCapacity;
	uint32_t blockCount;
} b3BitSet;


b3BitSet b3CreateBitSet( uint32_t bitCapacity );
void b3DestroyBitSet( b3BitSet* bitSet );
void b3SetBitCountAndClear( b3BitSet* bitSet, uint32_t bitCount );
void b3InPlaceUnion( b3BitSet* setA, const b3BitSet* setB );
void b3GrowBitSet( b3BitSet* bitSet, uint32_t blockCount );
int b3CountSetBits( b3BitSet* bitSet );

static inline void b3SetBit( b3BitSet* bitSet, uint32_t bitIndex )
{
	uint32_t blockIndex = bitIndex / 64;
	B3_ASSERT( blockIndex < bitSet->blockCount );
	bitSet->bits[blockIndex] |= ( (uint64_t)1 << bitIndex % 64 );
}

static inline void b3SetBitGrow( b3BitSet* bitSet, uint32_t bitIndex )
{
	uint32_t blockIndex = bitIndex / 64;
	if ( blockIndex >= bitSet->blockCount )
	{
		b3GrowBitSet( bitSet, blockIndex + 1 );
	}
	bitSet->bits[blockIndex] |= ( (uint64_t)1 << bitIndex % 64 );
}

static inline void b3ClearBit( b3BitSet* bitSet, uint32_t bitIndex )
{
	uint32_t blockIndex = bitIndex / 64;
	if ( blockIndex >= bitSet->blockCount )
	{
		return;
	}
	bitSet->bits[blockIndex] &= ~( (uint64_t)1 << bitIndex % 64 );
}

static inline bool b3GetBit( const b3BitSet* bitSet, uint32_t bitIndex )
{
	uint32_t blockIndex = bitIndex / 64;
	if ( blockIndex >= bitSet->blockCount )
	{
		return false;
	}
	return ( bitSet->bits[blockIndex] & ( (uint64_t)1 << bitIndex % 64 ) ) != 0;
}

static inline int b3GetBitSetBytes( b3BitSet* bitSet )
{
	return bitSet->blockCapacity * sizeof( uint64_t );
}
