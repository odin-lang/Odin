package vendor_box2d

import "base:intrinsics"

// Use these to make your identifiers null. You may also use zero initialization to get null.
nullWorldId   :: WorldId{}
nullBodyId    :: BodyId{}
nullShapeId   :: ShapeId{}
nullChainId   :: ChainId{}
nullJointId   :: JointId{}
nullContactId :: ContactId{}

// Macro to determine if any id is null.
IS_NULL :: #force_inline proc "c" (id: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1") {
	return id.index1 == 0
}

// Macro to determine if any id is non-null.
IS_NON_NULL :: #force_inline proc "c" (id: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1") {
	return id.index1 != 0
}

// Compare two ids for equality. Doesn't work for WorldId. Don't mix types.
ID_EQUALS :: #force_inline proc "c" (id1, id2: $T) -> bool
	where intrinsics.type_is_struct(T),
	      intrinsics.type_has_field(T, "index1"),
	      intrinsics.type_has_field(T, "world0"),
	      intrinsics.type_has_field(T, "generation") {
	return id1.index1 == id2.index1 && id1.world0 == id2.world0 && id1.generation == id2.generation
}

// Store a world id into a u32.
StoreWorldId :: #force_inline proc "c" (id: WorldId) -> u32 {
	return (u32(id.index1) << 16) | u32(id.generation)
}

// Load a u32 into a world id.
LoadWorldId :: #force_inline proc "c" (x: u32) -> WorldId {
	return {
		u16(x >> 16),
		u16(x),
	}
}

// Store a body id into a u64.
StoreBodyId :: #force_inline proc "c" (id: BodyId) -> u64 {
	return u64(id.index1) << 32 | u64(id.world0) << 16 | u64(id.generation)
}

// Load a u64 into a body id.
LoadBodyId :: #force_inline proc "c" (x: u64) -> BodyId {
	return {
		i32(x >> 32),
		u16(x >> 16),
		u16(x),
	}
}

// Store a shape id into a u64.
StoreShapeId :: #force_inline proc "c" (id: ShapeId) -> u64 {
	return u64(id.index1) << 32 | u64(id.world0) << 16 | u64(id.generation)
}

// Load a u64 into a shape id.
LoadShapeId :: #force_inline proc "c" (x: u64) -> ShapeId {
	return {
		i32(x >> 32),
		u16(x >> 16),
		u16(x),
	}
}

// Store a chain id into a u64.
StoreChainId :: #force_inline proc "c" (id: ChainId) -> u64 {
	return u64(id.index1) << 32 | u64(id.world0) << 16 | u64(id.generation)
}

// Load a u64 into a chain id.
LoadChainId :: #force_inline proc "c" (x: u64) -> ChainId {
	return {
		i32(x >> 32),
		u16(x >> 16),
		u16(x),
	}
}

// Store a joint id into a u64.
StoreJointId :: #force_inline proc "c" (id: JointId) -> u64 {
	return u64(id.index1) << 32 | u64(id.world0) << 16 | u64(id.generation)
}

// Load a u64 into a joint id.
LoadJointId :: #force_inline proc "c" (x: u64) -> JointId {
	return {
		i32(x >> 32),
		u16(x >> 16),
		u16(x),
	}
}

// Store a contact id.
StoreContactId :: #force_inline proc "c" (id: ContactId) -> (values: [3]u32) {
	values[0] = u32(id.index1)
	values[1] = u32(id.world0)
	values[2] = id.generation
	return
}

// Load a contact id.
LoadContactId :: #force_inline proc "c" (values: [3]u32) -> ContactId {
	return {
		index1     = i32(values[0]),
		world0     = u16(values[1]),
		generation = values[2],
	}
}
