// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "container.h"

#define B3_NULL_NAME 0u

typedef struct b3NameEntry
{
	// Names are used for debugging and I'm favoring simplicity and
	// minimal storage. Collisions will be logged.
	uint32_t hash;
	int length;
	char* name;
} b3NameEntry;

b3DeclareArray( b3NameEntry );

typedef struct b3NameCache
{
	b3Array( b3NameEntry ) entries;
	void* map;
} b3NameCache;

b3NameCache b3CreateNameCache( void );
void b3DestroyNameCache( b3NameCache* cache );

uint32_t b3AddName( b3NameCache* cache, const char* name );
const char* b3FindName( const b3NameCache* cache, uint32_t id );

// Load a name from a recording. Name ownership is transferred.
void b3LoadName( b3NameCache* cache, uint32_t id, char* name, int length );

uint32_t b3Hash32( const void* data, size_t length );

static inline const char* b3FindNameWithDefault( const b3NameCache* cache, uint32_t id, const char* def )
{
	const char* name = b3FindName( cache, id );
	return name == NULL ? def : name;
}
