package vendor_box3d

/// World id references a world instance. This should be treated as an opaque handle.
WorldId :: struct {
	index1:     u16,
	generation: u16,
}

/// Body id references a body instance. This should be treated as an opaque handle.
BodyId :: struct {
	index1:     i32,
	world0:     u16,
	generation: u16,
}

/// Shape id references a shape instance. This should be treated as an opaque handle.
ShapeId :: struct {
	index1:     i32,
	world0:     u16,
	generation: u16,
}

/// Joint id references a joint instance. This should be treated as an opaque handle.
JointId :: struct {
	index1:     i32,
	world0:     u16,
	generation: u16,
}

/// Contact id references a contact instance. This should be treated as an opaque handle.
ContactId :: struct {
	index1:     i32,
	world0:     u16,
	_:          i16,
	generation: u32,
}


/// Use these to make your identifiers null.
/// You may also use zero initialization to get null.
nullWorldId   :: WorldId{}
nullBodyId    :: BodyId{}
nullShapeId   :: ShapeId{}
nullJointId   :: JointId{}
nullContactId :: ContactId{}

/// Macro to determine if any id is null.
@(require_results)
IS_NULL :: #force_inline proc "c" (id: $T) -> bool {
	return id.index1 == 0
}

/// Macro to determine if any id is non-null.
@(require_results)
IS_NON_NULL :: #force_inline proc "c" (id: $T) -> bool {
	return id.index1 != 0
}

/// Compare two ids for equality. Doesn't work for b3WorldId. Don't mix types.
@(require_results)
ID_EQUALS :: #force_inline proc "c" (id1, id2: $T) -> bool {
	return id1.index1 == id2.index1 && id1.world0 == id2.world0 && id1.generation == id2.generation
}

/// Store a world id into a u32.
@(require_results)
StoreWorldId :: #force_inline proc "c" (id: WorldId) -> u32 {
	return u32(id.index1) << 16 | u32(id.generation)
}

/// Load a u32 into a world id.
@(require_results)
LoadWorldId :: #force_inline proc "c" (x: u32) -> WorldId {
	return WorldId{u16(x >> 16), u16(x)}
}

/// Store a body id into a u64.
@(require_results)
StoreBodyId :: #force_inline proc "c" (id: BodyId) -> u64 {
	return (u64(id.index1) << 32) | u64(id.world0) << 16 | u64(id.generation)
}

/// Load a u64 into a body id.
@(require_results)
LoadBodyId :: #force_inline proc "c" (x: u64) -> BodyId {
	return BodyId{i32(x >> 32), u16(x >> 16), u16(x)}
}

/// Store a shape id into a u64.
@(require_results)
StoreShapeId :: #force_inline proc "c" (id: ShapeId) -> u64 {
	return (u64(id.index1) << 32) | u64(id.world0) << 16 | u64(id.generation)
}

/// Load a u64 into a shape id.
@(require_results)
LoadShapeId :: #force_inline proc "c" (x: u64) -> ShapeId {
	return ShapeId{i32(x >> 32), u16(x >> 16), u16(x)}
}

/// Store a joint id into a u64.
@(require_results)
StoreJointId :: #force_inline proc "c" (id: JointId) -> u64 {
	return (u64(id.index1) << 32) | u64(id.world0) << 16 | u64(id.generation)
}

/// Load a u64 into a joint id.
@(require_results)
LoadJointId :: #force_inline proc "c" (x: u64) -> JointId {
	return JointId{i32(x >> 32), u16(x >> 16), u16(x)}
}

/// Store a contact id into three uint32 values
@(require_results)
StoreContactId :: #force_inline proc "c" (id: ContactId) -> (values: [3]u32) {
	values[0] = u32(id.index1)
	values[1] = u32(id.world0)
	values[2] = u32(id.generation)
	return
}

/// Load a contact id from three uint32 values.
@(require_results)
LoadContactId :: #force_inline proc "c" (values: [3]u32) -> (id: ContactId) {
	id.index1     = i32(values[0])
	id.world0     = u16(values[1])
	id.generation = u32(values[2])
	return
}