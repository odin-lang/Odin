// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include <stdint.h>

// Note: this file should be stand-alone

/**
 * @defgroup id Ids
 * These ids serve as handles to internal Box3D objects.
 * These should be considered opaque data and passed by value.
 * Include this header if you need the id types and not the whole Box3D API.
 * All ids are considered null if initialized to zero.
 *
 * For example in C++:
 *
 * @code{.cxx}
 * b3WorldId worldId = {};
 * @endcode
 *
 * Or in C:
 *
 * @code{.c}
 * b3WorldId worldId = {0};
 * @endcode
 *
 * These are both considered null.
 *
 * @warning Do not use the internals of these ids. They are subject to change. Ids should be treated as opaque objects.
 * @warning You should use ids to access objects in Box3D. Do not access files within the src folder. Such usage is unsupported.
 * @{
 */

/// World id references a world instance. This should be treated as an opaque handle.
typedef struct b3WorldId
{
	uint16_t index1;
	uint16_t generation;
} b3WorldId;

/// Body id references a body instance. This should be treated as an opaque handle.
typedef struct b3BodyId
{
	int32_t index1;
	uint16_t world0;
	uint16_t generation;
} b3BodyId;

/// Shape id references a shape instance. This should be treated as an opaque handle.
typedef struct b3ShapeId
{
	int32_t index1;
	uint16_t world0;
	uint16_t generation;
} b3ShapeId;

/// Joint id references a joint instance. This should be treated as an opaque handle.
typedef struct b3JointId
{
	int32_t index1;
	uint16_t world0;
	uint16_t generation;
} b3JointId;

/// Contact id references a contact instance. This should be treated as an opaque handle.
typedef struct b3ContactId
{
	int32_t index1;
	uint16_t world0;
	int16_t padding;
	uint32_t generation;
} b3ContactId;

// clang-format off
#ifdef __cplusplus
	/// A null id. Works for any id type.
	#define B3_NULL_ID {}
	#define B3_ID_INLINE inline
#else
	/// A null id. Works for any id type.
	#define B3_NULL_ID { 0 }

	/// This macro bridges C and C++ inline functions. C++ has the one definition rule that C lacks.
	#define B3_ID_INLINE static inline
#endif
// clang-format on

/// Use these to make your identifiers null.
/// You may also use zero initialization to get null.
static const b3WorldId b3_nullWorldId = B3_NULL_ID;
static const b3BodyId b3_nullBodyId = B3_NULL_ID;
static const b3ShapeId b3_nullShapeId = B3_NULL_ID;
static const b3JointId b3_nullJointId = B3_NULL_ID;
static const b3ContactId b3_nullContactId = B3_NULL_ID;

/// Macro to determine if any id is null.
#define B3_IS_NULL( id ) ( id.index1 == 0 )

/// Macro to determine if any id is non-null.
#define B3_IS_NON_NULL( id ) ( id.index1 != 0 )

/// Compare two ids for equality. Doesn't work for b3WorldId. Don't mix types.
#define B3_ID_EQUALS( id1, id2 ) ( id1.index1 == id2.index1 && id1.world0 == id2.world0 && id1.generation == id2.generation )

/// Store a world id into a uint32_t.
B3_ID_INLINE uint32_t b3StoreWorldId( b3WorldId id )
{
	return ( (uint32_t)id.index1 << 16 ) | (uint32_t)id.generation;
}

/// Load a uint32_t into a world id.
B3_ID_INLINE b3WorldId b3LoadWorldId( uint32_t x )
{
	b3WorldId id = { (uint16_t)( x >> 16 ), (uint16_t)( x ) };
	return id;
}

/// Store a body id into a uint64_t.
B3_ID_INLINE uint64_t b3StoreBodyId( b3BodyId id )
{
	return ( (uint64_t)id.index1 << 32 ) | ( (uint64_t)id.world0 ) << 16 | (uint64_t)id.generation;
}

/// Load a uint64_t into a body id.
B3_ID_INLINE b3BodyId b3LoadBodyId( uint64_t x )
{
	b3BodyId id = { (int32_t)( x >> 32 ), (uint16_t)( x >> 16 ), (uint16_t)( x ) };
	return id;
}

/// Store a shape id into a uint64_t.
B3_ID_INLINE uint64_t b3StoreShapeId( b3ShapeId id )
{
	return ( (uint64_t)id.index1 << 32 ) | ( (uint64_t)id.world0 ) << 16 | (uint64_t)id.generation;
}

/// Load a uint64_t into a shape id.
B3_ID_INLINE b3ShapeId b3LoadShapeId( uint64_t x )
{
	b3ShapeId id = { (int32_t)( x >> 32 ), (uint16_t)( x >> 16 ), (uint16_t)( x ) };
	return id;
}

/// Store a joint id into a uint64_t.
B3_ID_INLINE uint64_t b3StoreJointId( b3JointId id )
{
	return ( (uint64_t)id.index1 << 32 ) | ( (uint64_t)id.world0 ) << 16 | (uint64_t)id.generation;
}

/// Load a uint64_t into a joint id.
B3_ID_INLINE b3JointId b3LoadJointId( uint64_t x )
{
	b3JointId id = { (int32_t)( x >> 32 ), (uint16_t)( x >> 16 ), (uint16_t)( x ) };
	return id;
}

/// Store a contact id into three uint32 values
B3_ID_INLINE void b3StoreContactId( b3ContactId id, uint32_t values[3] )
{
	values[0] = (uint32_t)id.index1;
	values[1] = (uint32_t)id.world0;
	values[2] = (uint32_t)id.generation;
}

/// Load a contact id from three uint32 values.
B3_ID_INLINE b3ContactId b3LoadContactId( uint32_t values[3] )
{
	b3ContactId id;
	id.index1 = (int32_t)values[0];
	id.world0 = (uint16_t)values[1];
	id.padding = 0;
	id.generation = (uint32_t)values[2];
	return id;
}

/**@}*/
