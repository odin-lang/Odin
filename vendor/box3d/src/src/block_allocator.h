// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "container.h"

#include "box3d/base.h"

#define B3_BLOCK_EXPONENT 8
#define B3_BLOCK_SIZE ( 1 << B3_BLOCK_EXPONENT )

typedef struct b3Block
{
	char* memory;
} b3Block;

b3DeclareArray( b3Block );

typedef struct b3BlockAllocator
{
	b3Array( b3Block ) blocks;
	void* freeList;
	int elementSize;
	int nextIndex;
	int allocationCount;
} b3BlockAllocator;

// Element must be large enough to hold a pointer
b3BlockAllocator b3CreateBlockAllocator( int elementSize, int initialCount );
void b3DestroyBlockAllocator( b3BlockAllocator* allocator );

// Returns one element of elementSize contiguous bytes. Address is stable until freed.
void* b3AllocateElement( b3BlockAllocator* allocator );
void b3FreeElement( b3BlockAllocator* allocator, void* element );
