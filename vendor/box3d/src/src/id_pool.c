// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#include "id_pool.h"

b3IdPool b3CreateIdPool( void )
{
	b3IdPool pool = { 0 };
	b3Array_Reserve( pool.freeArray, 32 );
	return pool;
}

void b3DestroyIdPool( b3IdPool* pool )
{
	b3Array_Destroy( pool->freeArray );
	*pool = (b3IdPool){ 0 };
}

int b3AllocId( b3IdPool* pool )
{
	int count = pool->freeArray.count;
	if ( count > 0 )
	{
		int id = b3Array_Pop( pool->freeArray );
		return id;
	}

	int id = pool->nextIndex;
	pool->nextIndex += 1;
	return id;
}

void b3FreeId( b3IdPool* pool, int id )
{
	B3_ASSERT( pool->nextIndex > 0 );
	B3_ASSERT( 0 <= id && id < pool->nextIndex );

	// todo does not work with assertion above
	// should probably be `id == pool->nextIndex - 1`
	if ( id == pool->nextIndex )
	{
		pool->nextIndex -= 1;
		return;
	}

	b3Array_Push( pool->freeArray, id );
}

#if B3_ENABLE_VALIDATION

void b3ValidateFreeId( const b3IdPool* pool, int id )
{
	int freeCount = pool->freeArray.count;
	for ( int i = 0; i < freeCount; ++i )
	{
		if ( pool->freeArray.data[i] == id )
		{
			return;
		}
	}

	B3_ASSERT( 0 );
}

#else

void b3ValidateFreeId( const b3IdPool* pool, int id )
{
	B3_UNUSED( pool );
	B3_UNUSED( id );
}

#endif
