// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "base.h"

/// Box3D bases all length units on meters, but you may need different units for your game.
/// You can set this value to use different units. This should be done at application startup
/// and only modified once. Default value is 1.
/// @warning This must be modified before any calls to Box3D
B3_API void b3SetLengthUnitsPerMeter( float lengthUnits );

/// Get the current length units per meter.
B3_API float b3GetLengthUnitsPerMeter( void );

/// Set the threshold for logging stalls.
B3_API void b3SetStallThreshold( float seconds );

/// Get the threshold for logging stalls.
B3_API float b3GetStallThreshold( void );

// Used to detect bad values. In float mode positions greater than about 16km have precision
// problems, so 100km is a safe limit. Large world mode keeps coordinates accurate much farther
// from the origin, so the sanity limit widens to keep valid far-field positions from tripping it.
#if defined( BOX3D_DOUBLE_PRECISION )
#define B3_HUGE ( 1.0e9f * b3GetLengthUnitsPerMeter() )
#else
#define B3_HUGE ( 1.0e5f * b3GetLengthUnitsPerMeter() )
#endif

/// Maximum parallel workers. Used for some fixed size arrays.
#define B3_MAX_WORKERS 32

/// Maximum number of tasks queued per world step. b3EnqueueTaskCallback will never be called
/// more than this per world step. This is related to B3_MAX_WORKERS. With 32 workers,
/// the maximum observed task count is 130. This allows an external task system to use a fixed
/// size array for Box3D task, which may help with creating stable user task pointers.
#define B3_MAX_TASKS 256

// Maximum number of colors in the constraint graph. Constraints that cannot
// find a color are added to the overflow set which are solved single-threaded.
// The compound barrel benchmark has minor overflow with 24 colors
#define B3_GRAPH_COLOR_COUNT 24

// Number of contact point buckets for counting the number of contact points per
// shape contact pair. This is just for reporting and doesn't affect simulation.
#define B3_CONTACT_MANIFOLD_COUNT_BUCKETS 8

// A small length used as a collision and constraint tolerance. Usually it is
// chosen to be numerically significant, but visually insignificant. In meters.
// @warning modifying this can have a significant impact on stability
#define B3_LINEAR_SLOP ( 0.005f * b3GetLengthUnitsPerMeter() )

#define B3_MIN_CAPSULE_LENGTH ( B3_LINEAR_SLOP )

/// The distance between shapes where they are considered overlapped. This is needed
/// because GJK may return small positive values for overlapped shapes in degenerate
/// configurations.
#define B3_OVERLAP_SLOP ( 0.1f * B3_LINEAR_SLOP )

/// Maximum number of simultaneous worlds that can be allocated
#ifndef B3_MAX_WORLDS
#define B3_MAX_WORLDS 128
#endif

/// The maximum rotation of a body per time step. This limit is very large and is used
/// to prevent numerical problems. You shouldn't need to adjust this.
/// @warning increasing this to 0.5f * B3_PI or greater will break continuous collision.
#define B3_MAX_ROTATION ( 0.25f * B3_PI )

/// @warning modifying this can have a significant impact on performance and stability
#define B3_SPECULATIVE_DISTANCE ( 4.0f * B3_LINEAR_SLOP )

/// The rest offset is used for mesh contact to reduce ghost collisions and assist with CCD.
/// The rest offset adjusts the contact point separation value, making the solver push the shapes
/// apart by this distance.
/// Must be at least B3_LINEAR_SLOP and less than B3_SPECULATIVE_DISTANCE.
#define B3_MESH_REST_OFFSET ( 1.0f * B3_LINEAR_SLOP )

/// The default contact recycling distance.
#define B3_CONTACT_RECYCLE_DISTANCE ( 10.0f * B3_LINEAR_SLOP )

/// The default contact recycling world angle threshold. For performance this value
/// is cos(angle/2)^2. This value corresponds to 10 degrees.
#define B3_CONTACT_RECYCLE_ANGULAR_DISTANCE ( 0.99240388f )

/// This is used to fatten AABBs in the dynamic tree. This allows proxies
/// to move by a small amount without triggering a tree adjustment. This is in meters.
/// @warning modifying this can have a significant impact on performance
#define B3_MAX_AABB_MARGIN ( 0.05f * b3GetLengthUnitsPerMeter() )

/// Per-shape AABB margin is a fraction of the shape extent (capped by B3_MAX_AABB_MARGIN).
/// Small shapes get small margins; large shapes are clamped to the cap.
#define B3_AABB_MARGIN_FRACTION 0.125f

/// The time that a body must be still before it will go to sleep. In seconds.
#define B3_TIME_TO_SLEEP 0.5f

/// The maximum number of contact points between two touching shapes.
#define B3_MAX_MANIFOLD_POINTS 4

/// The maximum number points to use for shape cast proxies (swept point cloud).
#define B3_MAX_SHAPE_CAST_POINTS 64

/// These generous limits allow for easy hashing. See b3ShapePairKey.
#define B3_SHAPE_POWER 22
#define B3_CHILD_POWER ( 64 - 2 * B3_SHAPE_POWER )
#define B3_MAX_SHAPES ( 1 << B3_SHAPE_POWER )
#define B3_MAX_CHILD_SHAPES ( 1 << B3_CHILD_POWER )
