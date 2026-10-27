package vendor_box2d

// The constants of Box2D's constants.h, collision.h, types.h and base.h.

// Version of the bindings, and the library they were made for.
VERSION_MAJOR    :: 3
VERSION_MINOR    :: 2
VERSION_REVISION :: 0

// Starting hash value.
HASH_INIT :: 5381

// Maximum number of vertices of a convex polygon.
MAX_POLYGON_VERTICES :: 8

// Default filter category bits.
DEFAULT_CATEGORY_BITS :: 1

// Default filter mask bits.
DEFAULT_MASK_BITS :: max(u64)

// An index that is not valid.
NULL_INDEX :: -1

// Maximum parallel workers. Used for some fixed size arrays.
MAX_WORKERS :: 32

// Maximum number of tasks queued per world step. EnqueueTaskCallbackFcn will never be called more than this per world
// step. This is related to MAX_WORKERS. With 32 workers, the maximum observed task count is 130.
MAX_TASKS :: 256

// Maximum number of colors in the constraint graph. Constraints that cannot find a color are added to the overflow
// set, which is solved single-threaded.
GRAPH_COLOR_COUNT :: 24

// Maximum number of simultaneous worlds that can be allocated.
MAX_WORLDS :: 128

// Maximum length of the body name.
NAME_LENGTH :: 10

// The maximum rotation of a body per time step. This limit is very large and is used to prevent numerical problems.
// You shouldn't need to adjust this.
MAX_ROTATION :: 0.25 * PI

// For small objects the margin is limited to this fraction times the maximum extent.
AABB_MARGIN_FRACTION :: 0.125

// The default contact recycling world angle threshold. 0.98 ~= 11.5 degrees.
CONTACT_RECYCLE_COS_ANGLE :: 0.98

// The time that a body must be still before it will go to sleep. In seconds.
TIME_TO_SLEEP :: 0.5

// The maximum number of restitution iterations. Needed to avoid a solver overflow.
MAX_RESTITUTION_ITERATIONS :: 63


// Used to detect bad values. Positions greater than about 16km will have precision problems in single precision, so
// 100km as a limit should be fine in all cases.
@(require_results)
HUGE :: proc "c" () -> f32 {
	return (100.0 * 1000.0) * GetLengthUnitsPerMeter()
}

// A small length used as a collision and constraint tolerance. Usually it is chosen to be numerically significant,
// but visually insignificant. In meters. Normally this is 0.5cm.
// @warning modifying this can have a significant impact on stability
@(require_results)
LINEAR_SLOP :: proc "c" () -> f32 {
	return 0.005 * GetLengthUnitsPerMeter()
}

// Box2D uses limited speculative collision. This reduces jitter. Normally this is 2cm.
@(require_results)
SPECULATIVE_DISTANCE :: proc "c" () -> f32 {
	return 4.0 * LINEAR_SLOP()
}

// The default contact recycling distance.
@(require_results)
CONTACT_RECYCLE_DISTANCE :: proc "c" () -> f32 {
	return 10.0 * LINEAR_SLOP()
}

// This is used to fatten AABBs in the dynamic tree. This allows proxies to move by a small amount without triggering a
// tree adjustment. This is in meters. Normally this is 5cm.
@(require_results)
MAX_AABB_MARGIN :: proc "c" () -> f32 {
	return 0.05 * GetLengthUnitsPerMeter()
}
