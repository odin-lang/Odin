package vendor_box2d

import "base:intrinsics"

/**
 * @defgroup id Ids
 * These ids serve as handles to internal Box2D objects.
 * These should be considered opaque data and passed by value.
 * Include this header if you need the id types and not the whole Box2D API.
 * All ids are considered null if initialized to zero.
 *
 * For example in Odin:
 *
 * @code{.odin}
 * worldId := b2.WorldId{}
 * @endcode
 *
 * This is considered null.
 *
 * @warning Do not use the internals of these ids. They are subject to change. Ids should be treated as opaque objects.
 * @warning You should use ids to access objects in Box2D. Do not access files within the src folder. Such usage is unsupported.
 */

/// World id references a world instance. This should be treated as an opaque handle.
WorldId :: struct {
	index1:   u16,
	revision: u16,
}

/// Body id references a body instance. This should be treated as an opaque handle.
BodyId :: struct {
	index1:   i32,
	world0:   u16,
	revision: u16,
}

/// Shape id references a shape instance. This should be treated as an opaque handle.
ShapeId :: struct {
	index1:   i32,
	world0:   u16,
	revision: u16,
}

/// Joint id references a joint instance. This should be treated as an opaque handle.
JointId :: struct {
	index1:   i32,
	world0:   u16,
	revision: u16,
}

/// Chain id references a chain instances. This should be treated as an opaque handle.
ChainId :: struct {
	index1:   i32,
	world0:   u16,
	revision: u16,
}

/// Use these to make your identifiers null.
/// You may also use zero initialization to get null.
nullWorldId :: WorldId{}
nullBodyId  :: BodyId{}
nullShapeId :: ShapeId{}
nullJointId :: JointId{}
nullChainId :: ChainId{}

/// Macro to determine if any id is null.
IS_NULL :: #force_inline proc "c" (id: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1") {
	return id.index1 == 0
}

/// Macro to determine if any id is non-null.
IS_NON_NULL :: #force_inline proc "c" (id: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1") {
	return id.index1 != 0
}

/// Compare two ids for equality. Doesn't work for b2WorldId.
ID_EQUALS :: #force_inline proc "c" (id1, id2: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1"),
	      intrinsics.type_has_field(T, "world0"),
	      intrinsics.type_has_field(T, "revision") {
	return id1.index1 == id2.index1 && id1.world0 == id2.world0 && id1.revision == id2.revision
}
