package vendor_box3d


@(link_prefix="b3", default_calling_convention="c")
foreign lib {
	// Box3D bases all length units on meters, but you may need different units for your game.
	// You can set this value to use different units. This should be done at application startup
	// and only modified once. Default value is 1.
	// @warning This must be modified before any calls to Box3D
	SetLengthUnitsPerMeter :: proc(lengthUnits: f32) ---

	// Get the current length units per meter.
	GetLengthUnitsPerMeter :: proc() -> f32 ---

	// Set the threshold for logging stalls.
	SetStallThreshold :: proc(seconds: f32) ---

	// Get the threshold for logging stalls.
	GetStallThreshold :: proc() -> f32 ---
}

// Used to detect bad values. In float mode positions greater than about 16km have precision
// problems, so 100km is a safe limit. Large world mode keeps coordinates accurate much farther
// from the origin, so the sanity limit widens to keep valid far-field positions from tripping it.
@(require_results)
HUGE :: #force_inline proc "c" () -> f32 {
	when DOUBLE_PRECISION {
		return 1.0e9 * GetLengthUnitsPerMeter()
	} else {
		return 1.0e5 * GetLengthUnitsPerMeter()
	}
}

// Maximum parallel workers. Used for some fixed size arrays.
MAX_WORKERS :: 32

// Maximum number of tasks queued per world step. b3EnqueueTaskCallback will never be called
// more than this per world step. This is related to B3_MAX_WORKERS. With 32 workers,
// the maximum observed task count is 130. This allows an external task system to use a fixed
// size array for Box3D task, which may help with creating stable user task pointers.
MAX_TASKS :: 256

// Maximum number of colors in the constraint graph. Constraints that cannot
// find a color are added to the overflow set which are solved single-threaded.
// The compound barrel benchmark has minor overflow with 24 colors
GRAPH_COLOR_COUNT :: 24

// Number of contact point buckets for counting the number of contact points per
// shape contact pair. This is just for reporting and doesn't affect simulation.
CONTACT_MANIFOLD_COUNT_BUCKETS :: 8

// A small length used as a collision and constraint tolerance. Usually it is
// chosen to be numerically significant, but visually insignificant. In meters.
// @warning modifying this can have a significant impact on stability
@(require_results)
LINEAR_SLOP :: #force_inline proc "c" () -> f32 {
	return 0.005 * GetLengthUnitsPerMeter()
}

@(require_results)
MIN_CAPSULE_LENGTH :: #force_inline proc "c" () -> f32 {
	return LINEAR_SLOP()
}

// The distance between shapes where they are considered overlapped. This is needed
// because GJK may return small positive values for overlapped shapes in degenerate
// configurations.
@(require_results)
OVERLAP_SLOP :: #force_inline proc "c" () -> f32 {
	return 0.1 * LINEAR_SLOP()
}

// Maximum number of simultaneous worlds that can be allocated
MAX_WORLDS :: 128

// The maximum rotation of a body per time step. This limit is very large and is used
// to prevent numerical problems. You shouldn't need to adjust this.
// @warning increasing this to 0.5f * B3_PI or greater will break continuous collision.
MAX_ROTATION :: 0.25 * PI

// @warning modifying this can have a significant impact on performance and stability
@(require_results)
SPECULATIVE_DISTANCE :: #force_inline proc "c" () -> f32 {
	return 4.0 * LINEAR_SLOP()
}

// The rest offset is used for mesh contact to reduce ghost collisions and assist with CCD.
// The rest offset adjusts the contact point separation value, making the solver push the shapes
// apart by this distance.
// Must be at least B3_LINEAR_SLOP and less than B3_SPECULATIVE_DISTANCE.
@(require_results)
MESH_REST_OFFSET :: #force_inline proc "c" () -> f32 {
	return 1.0 * LINEAR_SLOP()
}

// The default contact recycling distance.
@(require_results)
CONTACT_RECYCLE_DISTANCE :: #force_inline proc "c" () -> f32 {
	return 10.0 * LINEAR_SLOP()
}

// The default contact recycling world angle threshold. For performance this value
// is cos(angle/2)^2. This value corresponds to 10 degrees.
CONTACT_RECYCLE_ANGULAR_DISTANCE :: 0.99240388

// This is used to fatten AABBs in the dynamic tree. This allows proxies
// to move by a small amount without triggering a tree adjustment. This is in meters.
// @warning modifying this can have a significant impact on performance
@(require_results)
MAX_AABB_MARGIN :: #force_inline proc "c" () -> f32 {
	return 0.05 * GetLengthUnitsPerMeter()
}

// Per-shape AABB margin is a fraction of the shape extent (capped by B3_MAX_AABB_MARGIN).
// Small shapes get small margins; large shapes are clamped to the cap.
AABB_MARGIN_FRACTION :: 0.125

// The time that a body must be still before it will go to sleep. In seconds.
TIME_TO_SLEEP :: 0.5

// Maximum length of the body name. Can be 0 if you don't need names.
// Note: this gates recording capability.
BODY_NAME_LENGTH :: 18

// Maximum length of the shape name. Can be 0 if you don't need names.
// Note: this gates recording capability.
// todo waiting on this because it breaks existing recordings
SHAPE_NAME_LENGTH :: 18

// The maximum number of contact points between two touching shapes.
MAX_MANIFOLD_POINTS :: 4

// The maximum number points to use for shape cast proxies (swept point cloud).
MAX_SHAPE_CAST_POINTS :: 64

// These generous limits allow for easy hashing. See b3ShapePairKey.
SHAPE_POWER      :: 22
CHILD_POWER      :: 64 - 2 * SHAPE_POWER
MAX_SHAPES       :: 1 << SHAPE_POWER
MAX_CHILD_SHAPES :: 1 << CHILD_POWER