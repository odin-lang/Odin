// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include <stddef.h>
#include <string.h>

// Swap two same-size lvalues through a byte buffer. Avoids __typeof__ so it builds on any C compiler.
#define B3_SWAP( x, y )                                                                                                          \
	do                                                                                                                           \
	{                                                                                                                            \
		_Static_assert( sizeof( x ) == sizeof( y ), "size mismatch" );                                                           \
		char B3_SWAP_TEMP[sizeof( x )];                                                                                          \
		memcpy( B3_SWAP_TEMP, &( x ), sizeof( x ) );                                                                             \
		memcpy( &( x ), &( y ), sizeof( x ) );                                                                                   \
		memcpy( &( y ), B3_SWAP_TEMP, sizeof( x ) );                                                                             \
	}                                                                                                                            \
	while ( 0 )
