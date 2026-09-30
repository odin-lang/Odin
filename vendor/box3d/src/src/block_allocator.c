// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#include "block_allocator.h"

#include "core.h"

b3BlockAllocator b3CreateBlockAllocator( int elementSize, int initialCount )
{
	B3_ASSERT( elementSize >= (int)sizeof( void* ) );

	// The free list stores a pointer inside each element, so the stride must keep every element aligned.
	// Blocks come from b3Alloc, so a stride that is a multiple of B3_ALIGNMENT aligns all elements.
	elementSize = ( ( elementSize - 1 ) | ( B3_ALIGNMENT - 1 ) ) + 1;

	b3BlockAllocator allocator = { 0 };

	b3Array_Create( allocator.blocks );
	allocator.elementSize = elementSize;
	allocator.freeList = NULL;
	allocator.nextIndex = 0;
	allocator.allocationCount = 0;

	if ( initialCount > 0 )
	{
		int count = ( initialCount + B3_BLOCK_SIZE - 1 ) >> B3_BLOCK_EXPONENT;
		b3Array_Resize( allocator.blocks, count );

		for ( int i = 0; i < allocator.blocks.count; ++i )
		{
			allocator.blocks.data[i].memory = b3Alloc( B3_BLOCK_SIZE * elementSize );
		}
	}

	return allocator;
}

void b3DestroyBlockAllocator( b3BlockAllocator* allocator )
{
	for ( int i = 0; i < allocator->blocks.count; ++i )
	{
		b3Free( allocator->blocks.data[i].memory, B3_BLOCK_SIZE * allocator->elementSize );
	}

	b3Array_Destroy( allocator->blocks );
}

void* b3AllocateElement( b3BlockAllocator* allocator )
{
	B3_ASSERT( allocator != NULL );

	allocator->allocationCount += 1;

	// Pop from free list first
	if ( allocator->freeList != NULL )
	{
		void* element = allocator->freeList;
		allocator->freeList = *(void**)element;
		return element;
	}

	int index = allocator->nextIndex++;

	int requiredBlockCount = ( index >> B3_BLOCK_EXPONENT ) + 1;

	if ( requiredBlockCount > allocator->blocks.count )
	{
		int oldCount = allocator->blocks.count;
		b3Array_Resize( allocator->blocks, requiredBlockCount );

		for ( int i = oldCount; i < requiredBlockCount; ++i )
		{
			allocator->blocks.data[i].memory = b3Alloc( B3_BLOCK_SIZE * allocator->elementSize );
		}
	}

	int blockIndex = index >> B3_BLOCK_EXPONENT;
	int blockOffset = index & ( B3_BLOCK_SIZE - 1 );

	return allocator->blocks.data[blockIndex].memory + blockOffset * allocator->elementSize;
}

void b3FreeElement( b3BlockAllocator* allocator, void* element )
{
	B3_ASSERT( allocator != NULL );
	B3_ASSERT( element != NULL );
	B3_ASSERT( allocator->allocationCount > 0 );
	B3_ASSERT( ( (uintptr_t)element & ( B3_ALIGNMENT - 1 ) ) == 0 );

	allocator->allocationCount -= 1;

	// Push onto free list
	*(void**)element = allocator->freeList;
	allocator->freeList = element;
}
