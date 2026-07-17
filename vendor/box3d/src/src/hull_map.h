// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "box3d/types.h"

#include <stddef.h>

// Content hash and equality over the whole baked hull. Shared by every hull
// de-duplication map so they agree on identity.
uint64_t b3HashHullData( const b3HullData* hull );
bool b3CompareHullData( const b3HullData* hull1, const b3HullData* hull2 );

// Map keyed by hull content. The world hull database stores a reference count,
// compound baking stores a byte offset. Implementation lives in hull.c.
#define NAME b3HullMap
#define KEY_TY const b3HullData*
#define VAL_TY int
#define HEADER_MODE
#include "verstable.h"

// Total map allocation in bytes, excluding the stored hull data
size_t b3HullMapByteCount( b3HullMap* map );
