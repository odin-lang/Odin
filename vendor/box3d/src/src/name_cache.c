// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#include "name_cache.h"

#include "recording.h"

#include <string.h>

#define NAME b3NameMap
#define KEY_TY uint32_t
#define VAL_TY int
#define HASH_FN vt_hash_integer
#define CMPR_FN vt_cmpr_integer
#define MALLOC_FN b3Alloc
#define FREE_FN b3Free
#include "verstable.h"

#define FNV32_OFFSET_BASIS 0x811c9dc5u
#define FNV32_PRIME 0x01000193u

// This is designed to hash small strings and while avoiding collisions
// for a 32-bit hash.
// Note: changing this will break recordings
uint32_t b3Hash32( const void* data, size_t length )
{
	// Cast to unsigned to avoid sign extension
	const unsigned char* p = data;

	// FNV-1a
	uint32_t h = FNV32_OFFSET_BASIS;
	for ( size_t i = 0; i < length; ++i )
	{
		h ^= p[i];
		h *= FNV32_PRIME;
	}

	// Murmur3 finalizer to help with short strings
	h ^= h >> 16;
	h *= 0x85ebca6bu;
	h ^= h >> 13;
	h *= 0xc2b2ae35u;
	h ^= h >> 16;
	return h;
}

b3NameCache b3CreateNameCache( void )
{
	b3NameCache cache = { 0 };
	b3Array_Create( cache.entries );

	b3NameMap* map = b3Alloc( sizeof( b3NameMap ) );
	b3NameMap_init( map );
	cache.map = map;
	return cache;
}

void b3DestroyNameCache( b3NameCache* cache )
{
	int count = cache->entries.count;
	for ( int i = 0; i < count; ++i )
	{
		b3NameEntry* entry = cache->entries.data + i;
		b3Free( entry->name, entry->length + 1 );
	}

	b3Array_Destroy( cache->entries );
	b3NameMap_cleanup( (b3NameMap*)cache->map );
	b3Free( cache->map, sizeof( b3NameMap ) );
}

uint32_t b3AddName( b3NameCache* cache, const char* name )
{
	if ( name == NULL || name[0] == 0 )
	{
		return B3_NULL_NAME;
	}

	size_t length = strlen( name );
	uint32_t id = b3Hash32( name, length );

	id = id == 0 ? 1 : id;

	b3NameMap* map = cache->map;
	b3NameMap_itr itr = b3NameMap_get( map, id );
	if ( b3NameMap_is_end( itr ) == false )
	{
		if ( strcmp( cache->entries.data[itr.data->val].name, name ) != 0 )
		{
			// Different name, same hash
			b3Log( "Hash collision on %s", name );
		}
		return id;
	}

	char* clone = b3Alloc( length + 1 );
	memcpy( clone, name, length + 1 );
	int index = cache->entries.count;
	b3NameEntry entry = {
		.hash = id,
		.name = clone,
		.length = (int)length,
	};

	b3Array_Push( cache->entries, entry );

	b3NameMap_insert( map, id, index );
	return id;
}

const char* b3FindName( const b3NameCache* cache, uint32_t id )
{
	b3NameMap* map = cache->map;
	b3NameMap_itr itr = b3NameMap_get( map, id );
	if ( b3NameMap_is_end( itr ) == false )
	{
		int index = itr.data->val;
		const b3NameEntry* entry = b3Array_Get( cache->entries, index );
		return entry->name;
	}

	return NULL;
}

void b3LoadName( b3NameCache* cache, uint32_t id, char* name, int length )
{
	if ( name == NULL )
	{
		return;
	}

	if ( name[0] == 0 || id == B3_NULL_NAME )
	{
		b3Free( name, length + 1 );
		return;
	}

	b3NameMap* map = cache->map;
	b3NameMap_itr itr = b3NameMap_get( map, id );
	if ( b3NameMap_is_end( itr ) == false )
	{
		b3Free( name, length + 1 );
		return;
	}

	int index = cache->entries.count;
	b3NameEntry entry = {
		.hash = id,
		.name = name,
		.length = length,
	};

	b3Array_Push( cache->entries, entry );
	b3NameMap_insert( map, id, index );
}
