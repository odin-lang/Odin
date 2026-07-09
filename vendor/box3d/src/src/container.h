// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "algorithm.h"
#include "core.h"

#include <stddef.h>
#include <string.h>

#define b3DeclareArray( T )                                                                                                      \
	typedef struct b3DynamicArray_##T                                                                                            \
	{                                                                                                                            \
		struct T* data;                                                                                                          \
		int count;                                                                                                               \
		int capacity;                                                                                                            \
	} b3DynamicArray_##T

#define b3DeclareArrayNative( T )                                                                                                \
	typedef struct b3DynamicArray_##T                                                                                            \
	{                                                                                                                            \
		T* data;                                                                                                                 \
		int count;                                                                                                               \
		int capacity;                                                                                                            \
	} b3DynamicArray_##T

// Define an array.
// It may be zero initialized:
// b3Array(int) myArray = { 0 };
#define b3Array( T ) b3DynamicArray_##T

// Alternative to zero initialization
#define b3Array_Create( a )                                                                                                      \
	do                                                                                                                           \
	{                                                                                                                            \
		( a ).data = NULL;                                                                                                       \
		( a ).count = 0;                                                                                                         \
		( a ).capacity = 0;                                                                                                      \
	}                                                                                                                            \
	while ( 0 )

#define b3Array_CreateN( a, n )                                                                                                  \
	do                                                                                                                           \
	{                                                                                                                            \
		( a ).data = ( n ) > 0 ? b3GrowAlloc( NULL, 0, ( n ) * sizeof( *( a ).data ) ) : NULL;         \
		( a ).count = 0;                                                                                                         \
		( a ).capacity = ( n );                                                                                                  \
	}                                                                                                                            \
	while ( 0 )

#define b3Array_Destroy( a )                                                                                                     \
	do                                                                                                                           \
	{                                                                                                                            \
		b3Free( ( a ).data, ( a ).capacity * sizeof( *( a ).data ) );                                                            \
		( a ).data = NULL;                                                                                                       \
		( a ).count = 0;                                                                                                         \
		( a ).capacity = 0;                                                                                                      \
	}                                                                                                                            \
	while ( 0 )

#define b3Array_Reserve( a, n )                                                                                                  \
	do                                                                                                                           \
	{                                                                                                                            \
		if ( ( a ).capacity < n )                                                                                                \
		{                                                                                                                        \
			int oldSize = ( a ).capacity * sizeof( *( a ).data );                                                                \
			int newSize = ( n ) * sizeof( *( a ).data );                                                                         \
			( a ).data = b3GrowAlloc( ( a ).data, oldSize, newSize );                                  \
			( a ).capacity = ( n );                                                                                              \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

#define b3Array_Resize( a, n )                                                                                                   \
	do                                                                                                                           \
	{                                                                                                                            \
		b3Array_Reserve( a, n );                                                                                                 \
		( a ).count = ( n );                                                                                                     \
	}                                                                                                                            \
	while ( 0 )

// Push a new element by value
#define b3Array_Push( a, value )                                                                                                 \
	do                                                                                                                           \
	{                                                                                                                            \
		if ( ( a ).count >= ( a ).capacity )                                                                                     \
		{                                                                                                                        \
			int oldSize = ( a ).capacity * sizeof( *( a ).data );                                                                \
			int newCapacity = ( a ).capacity == 0 ? 8 : 2 * ( a ).capacity;                                                      \
			int newSize = newCapacity * sizeof( *( a ).data );                                                                   \
			( a ).data = b3GrowAlloc( ( a ).data, oldSize, newSize );                                  \
			( a ).capacity = newCapacity;                                                                                        \
		}                                                                                                                        \
		( a ).data[( a ).count++] = ( value );                                                                                   \
	}                                                                                                                            \
	while ( 0 )

// Get a pointer to an element
#define b3Array_Get( a, index ) ( B3_ASSERT( 0 <= ( index ) && ( index ) < ( a ).count ), ( a ).data + ( index ) )

// Create a new uninitialized element and return a pointer to it
#define b3Array_Emplace( a )                                                                                                     \
	( b3EmplaceHelper( (void**)&( a ).data, &( a ).count, &( a ).capacity, sizeof( *( a ).data ) ) )

// Remove the last element and return it by value.
#define b3Array_Pop( a ) ( B3_ASSERT( 0 < ( a ).count ), ( a ).data[-1 + ( a ).count--] )

// Add an uninitialized element and return its index.
#define b3Array_AddIndex( a )                                                                                                    \
	( b3EmplaceHelper( (void**)&( a ).data, &( a ).count, &( a ).capacity, sizeof( *( a ).data ) ), ( a ).count - 1 )

// Append a contiguous run of values. _n is used to cache the input count while avoiding naming conflicts.
#define b3Array_Append( a, src, n )                                                                                              \
	do                                                                                                                           \
	{                                                                                                                            \
		int _n = ( n );                                                                                                          \
		if ( ( a ).count + _n > ( a ).capacity )                                                                                 \
		{                                                                                                                        \
			int req = ( a ).count + _n;                                                                                          \
			int newCapacity = req > 2 ? req + ( req >> 1 ) : 8;                                                                  \
			int oldSize = ( a ).capacity * sizeof( *( a ).data );                                                                \
			int newSize = newCapacity * sizeof( *( a ).data );                                                                   \
			( a ).data = b3GrowAlloc( ( a ).data, oldSize, newSize );                                  \
			( a ).capacity = newCapacity;                                                                                        \
		}                                                                                                                        \
		memcpy( ( a ).data + ( a ).count, ( src ), _n * sizeof( *( a ).data ) );                                                 \
		( a ).count += _n;                                                                                                       \
	}                                                                                                                            \
	while ( 0 )

// Zero the entire allocated buffer (capacity, not just count).
#define b3Array_MemZero( a )                                                                                                     \
	do                                                                                                                           \
	{                                                                                                                            \
		if ( ( a ).capacity > 0 )                                                                                                \
		{                                                                                                                        \
			memset( ( a ).data, 0, ( a ).capacity * sizeof( *( a ).data ) );                                                     \
		}                                                                                                                        \
	}                                                                                                                            \
	while ( 0 )

// Remove and element by swapping with the last element. If the index is the last element it returns
// B3_NULL_INDEX, otherwise it returns the index of the last element (which is now out of bounds).
#define b3Array_RemoveSwap( a, index ) b3RemoveHelper( ( a ).data, &( a ).count, ( index ), sizeof( *( a ).data ) )

B3_INLINE void* b3EmplaceHelper( void** data, int* count, int* capacity, int elem_size )
{
	if ( *count >= *capacity )
	{
		int oldCapacity = *capacity;
		int oldSize = oldCapacity * elem_size;
		int newCapacity = ( oldCapacity == 0 ? 16 : 2 * oldCapacity );
		int newSize = newCapacity * elem_size;
		*data = b3GrowAlloc( *data, oldSize, newSize );
		*capacity = newCapacity;
	}
	return (char*)*data + ( *count )++ * elem_size;
}

B3_INLINE int b3RemoveHelper( void* data, int* count, int index, int elementSize )
{
	B3_ASSERT( 0 <= index && index < *count && "Array index out of bounds" );

	( *count )--;
	if ( index != *count )
	{
		memcpy( (char*)data + index * elementSize, (char*)data + ( *count ) * elementSize, elementSize );
		return *count;
	}

	return B3_NULL_INDEX;
}

#define b3Array_Clear( a )                                                                                                       \
	do                                                                                                                           \
	{                                                                                                                            \
		( a ).count = 0;                                                                                                         \
	}                                                                                                                            \
	while ( 0 )

#define b3Array_ByteCount( a ) ( ( a ).capacity * (int)sizeof( *( a ).data ) )

b3DeclareArrayNative( int );
