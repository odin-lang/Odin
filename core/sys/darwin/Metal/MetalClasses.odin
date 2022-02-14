package objc_Metal

import NS "core:sys/darwin/Foundation"

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureBoundingBoxGeometryDescriptor
Class Methods:
	alloc
	descriptor
Methods:
	init
	boundingBoxBuffer
	boundingBoxBufferOffset
	boundingBoxCount
	boundingBoxStride
	setBoundingBoxBuffer
	setBoundingBoxBufferOffset
	setBoundingBoxCount
	setBoundingBoxStride
*/
@(objc_class="MTLAccelerationStructureBoundingBoxGeometryDescriptor")
AccelerationStructureBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureBoundingBoxGeometryDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureBoundingBoxGeometryDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="init")
AccelerationStructureBoundingBoxGeometryDescriptor_init :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBuffer :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "boundingBoxBuffer")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBufferOffset :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxBufferOffset")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxCount :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxCount")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxStride :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxStride")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_class_name="descriptor")
AccelerationStructureBoundingBoxGeometryDescriptor_descriptor :: #force_inline proc() -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBuffer :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBuffer: ^Buffer) {
	msgSend(nil, self, "setBoundingBoxBuffer:", boundingBoxBuffer)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBufferOffset :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxBufferOffset:", boundingBoxBufferOffset)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxCount :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxCount: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxCount:", boundingBoxCount)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxStride :: #force_inline proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxStride: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxStride:", boundingBoxStride)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	MotionKeyframeData
Class Methods:
	alloc
	data
Methods:
	init
	buffer
	setBuffer
	offset
	setOffset
*/

@(objc_class="MTLMotionKeyframeData")
MotionKeyframeData :: struct { using _: NS.Object }

@(objc_type=MotionKeyframeData, objc_class_name="alloc")
MotionKeyframeData_alloc :: #force_inline proc() -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, MotionKeyframeData, "alloc")
}
@(objc_type=MotionKeyframeData, objc_class_name="data")
MotionKeyframeData_data :: #force_inline proc() -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, MotionKeyframeData, "data")
}
@(objc_type=MotionKeyframeData, objc_class_name="init")
MotionKeyframeData_init :: #force_inline proc(self: ^MotionKeyframeData) -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, self, "init")
}
@(objc_type=MotionKeyframeData, objc_class_name="buffer")
MotionKeyframeData_buffer :: #force_inline proc(self: ^MotionKeyframeData) -> ^Buffer {
	return msgSend(^Buffer, self, "buffer")
}
@(objc_type=MotionKeyframeData, objc_class_name="setBuffer")
MotionKeyframeData_setBuffer :: #force_inline proc(self: ^MotionKeyframeData, buffer: ^Buffer) {
	msgSend(nil, self, "setBuffer:", buffer)
}
@(objc_type=MotionKeyframeData, objc_class_name="offset")
MotionKeyframeData_offset :: #force_inline proc(self: ^MotionKeyframeData) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=MotionKeyframeData, objc_class_name="setOffset")
MotionKeyframeData_setOffset :: #force_inline proc(self: ^MotionKeyframeData, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureMotionTriangleGeometryDescriptor
*/

@(objc_class="MTLAccelerationStructureMotionTriangleGeometryDescriptor")
AccelerationStructureMotionTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionTriangleGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureMotionTriangleGeometryDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureMotionTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionTriangleGeometryDescriptor, AccelerationStructureMotionTriangleGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="init")
AccelerationStructureMotionTriangleGeometryDescriptor_init :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^AccelerationStructureMotionTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionTriangleGeometryDescriptor, self, "init")
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="vertexBuffers")
AccelerationStructureMotionTriangleGeometryDescriptor_vertexBuffers :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexBuffers")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setVertexBuffers")
AccelerationStructureMotionTriangleGeometryDescriptor_setVertexBuffers :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, buffers: ^NS.Array) {
	msgSend(nil, self, "setVertexBuffers:", buffers)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="vertexStride")
AccelerationStructureMotionTriangleGeometryDescriptor_vertexStride :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexStride")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setVertexStride")
AccelerationStructureMotionTriangleGeometryDescriptor_setVertexStride :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setVertexStride:", stride)
}


@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_indexBuffer :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "indexBuffer")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexBuffer :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, buffer: ^Buffer) {
	msgSend(nil, self, "setIndexBuffer:", buffer)
}


@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_indexBufferOffset :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferOffset")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexBufferOffset :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferOffset:", offset)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexType")
AccelerationStructureMotionTriangleGeometryDescriptor_indexType :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexType")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexType :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="triangleCount")
AccelerationStructureMotionTriangleGeometryDescriptor_triangleCount :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "triangleCount")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setTriangleCount")
AccelerationStructureMotionTriangleGeometryDescriptor_setTriangleCount :: #force_inline proc(self: ^AccelerationStructureMotionTriangleGeometryDescriptor, count: NS.UInteger) {
	msgSend(nil, self, "setTriangleCount:", count)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureMotionBoundingBoxGeometryDescriptor
*/

@(objc_class="MTLAccelerationStructureMotionBoundingBoxGeometryDescriptor")
AccelerationStructureMotionBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionBoundingBoxGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, AccelerationStructureMotionBoundingBoxGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="init")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_init :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, self, "init")
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_class_name="descriptor")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_descriptor :: #force_inline proc() -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, AccelerationStructureMotionBoundingBoxGeometryDescriptor, "descriptor")
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxBuffers")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxBuffers :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "boundingBoxBuffers")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundBoxBuffers")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundBoxBuffers :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, buffers: ^NS.Array) {
	msgSend(nil, self, "setBoundBoxBuffers:", buffers)
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxStride")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxStride :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxStride")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxStride")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundingBoxStride :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxStride:", stride)
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxCount")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxCount :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxCount")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxCount")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundingBoxCount :: #force_inline proc(self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxCount:", offset)
}







////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureDescriptor
Class Methods:
	alloc
Methods:
	init
	setUsage
	usage
*/
@(objc_class="MTLAccelerationStructureDescriptor")
AccelerationStructureDescriptor :: struct { using _: NS.Copying(AccelerationStructureDescriptor) }

@(objc_type=AccelerationStructureDescriptor, objc_class_name="alloc")
AccelerationStructureDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, AccelerationStructureDescriptor, "alloc")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="init")
AccelerationStructureDescriptor_init :: #force_inline proc(self: ^AccelerationStructureDescriptor) -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, self, "init")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="setUsage")
AccelerationStructureDescriptor_setUsage :: #force_inline proc(self: ^AccelerationStructureDescriptor, usage: AccelerationStructureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=AccelerationStructureDescriptor, objc_name="usage")
AccelerationStructureDescriptor_usage :: #force_inline proc(self: ^AccelerationStructureDescriptor) -> AccelerationStructureUsage {
	return msgSend(AccelerationStructureUsage, self, "usage")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureGeometryDescriptor
Class Methods:
	alloc
Methods:
	init
	allowDuplicateIntersectionFunctionInvocation
	intersectionFunctionTableOffset
	opaque
	setAllowDuplicateIntersectionFunctionInvocation
	setIntersectionFunctionTableOffset
	setOpaque
*/
@(objc_class="MTLAccelerationStructureGeometryDescriptor")
AccelerationStructureGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureGeometryDescriptor) }

@(objc_type=AccelerationStructureGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureGeometryDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, AccelerationStructureGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="init")
AccelerationStructureGeometryDescriptor_init :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor) -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="allowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_allowDuplicateIntersectionFunctionInvocation :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowDuplicateIntersectionFunctionInvocation")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="intersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_intersectionFunctionTableOffset :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "intersectionFunctionTableOffset")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="opaque")
AccelerationStructureGeometryDescriptor_opaque :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "opaque")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setAllowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_setAllowDuplicateIntersectionFunctionInvocation :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor, allowDuplicateIntersectionFunctionInvocation: BOOL) {
	msgSend(nil, self, "setAllowDuplicateIntersectionFunctionInvocation:", allowDuplicateIntersectionFunctionInvocation)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setIntersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_setIntersectionFunctionTableOffset :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor, intersectionFunctionTableOffset: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTableOffset:", intersectionFunctionTableOffset)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setOpaque")
AccelerationStructureGeometryDescriptor_setOpaque :: #force_inline proc(self: ^AccelerationStructureGeometryDescriptor, opaque: BOOL) {
	msgSend(nil, self, "setOpaque:", opaque)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureTriangleGeometryDescriptor
Class Methods:
	alloc
	descriptor
Methods:
	init
	indexBuffer
	indexBufferOffset
	indexType
	setIndexBuffer
	setIndexBufferOffset
	setIndexType
	setTriangleCount
	setVertexBuffer
	setVertexBufferOffset
	setVertexStride
	triangleCount
	vertexBuffer
	vertexBufferOffset
	vertexStride
*/
@(objc_class="MTLAccelerationStructureTriangleGeometryDescriptor")
AccelerationStructureTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureTriangleGeometryDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureTriangleGeometryDescriptor_alloc :: #force_inline proc() -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="init")
AccelerationStructureTriangleGeometryDescriptor_init :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_class_name="descriptor")
AccelerationStructureTriangleGeometryDescriptor_descriptor :: #force_inline proc() -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBuffer")
AccelerationStructureTriangleGeometryDescriptor_indexBuffer :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "indexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_indexBufferOffset :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexType")
AccelerationStructureTriangleGeometryDescriptor_indexType :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setIndexBuffer :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexBuffer: ^Buffer) {
	msgSend(nil, self, "setIndexBuffer:", indexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setIndexBufferOffset :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferOffset:", indexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexType")
AccelerationStructureTriangleGeometryDescriptor_setIndexType :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setTriangleCount")
AccelerationStructureTriangleGeometryDescriptor_setTriangleCount :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, triangleCount: NS.UInteger) {
	msgSend(nil, self, "setTriangleCount:", triangleCount)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setVertexBuffer :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBuffer: ^Buffer) {
	msgSend(nil, self, "setVertexBuffer:", vertexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setVertexBufferOffset :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setVertexBufferOffset:", vertexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexStride")
AccelerationStructureTriangleGeometryDescriptor_setVertexStride :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexStride: NS.UInteger) {
	msgSend(nil, self, "setVertexStride:", vertexStride)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="triangleCount")
AccelerationStructureTriangleGeometryDescriptor_triangleCount :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "triangleCount")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_vertexBuffer :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "vertexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_vertexBufferOffset :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexStride")
AccelerationStructureTriangleGeometryDescriptor_vertexStride :: #force_inline proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexStride")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Argument
Class Methods:
	alloc
Methods:
	init
	access
	arrayLength
	bufferAlignment
	bufferDataSize
	bufferDataType
	bufferPointerType
	bufferStructType
	index
	isActive
	isDepthTexture
	name
	textureDataType
	textureType
	threadgroupMemoryAlignment
	threadgroupMemoryDataSize
	type
*/
@(objc_class="MTLArgument")
Argument :: struct { using _: NS.Object }

@(objc_type=Argument, objc_class_name="alloc")
Argument_alloc :: #force_inline proc() -> ^Argument {
	return msgSend(^Argument, Argument, "alloc")
}
@(objc_type=Argument, objc_name="init")
Argument_init :: #force_inline proc(self: ^Argument) -> ^Argument {
	return msgSend(^Argument, self, "init")
}
@(objc_type=Argument, objc_name="access")
Argument_access :: #force_inline proc(self: ^Argument) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=Argument, objc_name="arrayLength")
Argument_arrayLength :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=Argument, objc_name="bufferAlignment")
Argument_bufferAlignment :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferAlignment")
}
@(objc_type=Argument, objc_name="bufferDataSize")
Argument_bufferDataSize :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferDataSize")
}
@(objc_type=Argument, objc_name="bufferDataType")
Argument_bufferDataType :: #force_inline proc(self: ^Argument) -> DataType {
	return msgSend(DataType, self, "bufferDataType")
}
@(objc_type=Argument, objc_name="bufferPointerType")
Argument_bufferPointerType :: #force_inline proc(self: ^Argument) -> ^PointerType {
	return msgSend(^PointerType, self, "bufferPointerType")
}
@(objc_type=Argument, objc_name="bufferStructType")
Argument_bufferStructType :: #force_inline proc(self: ^Argument) -> ^StructType {
	return msgSend(^StructType, self, "bufferStructType")
}
@(objc_type=Argument, objc_name="index")
Argument_index :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=Argument, objc_name="isActive")
Argument_isActive :: #force_inline proc(self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Argument, objc_name="isDepthTexture")
Argument_isDepthTexture :: #force_inline proc(self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=Argument, objc_name="name")
Argument_name :: #force_inline proc(self: ^Argument) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Argument, objc_name="textureDataType")
Argument_textureDataType :: #force_inline proc(self: ^Argument) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=Argument, objc_name="textureType")
Argument_textureType :: #force_inline proc(self: ^Argument) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Argument, objc_name="threadgroupMemoryAlignment")
Argument_threadgroupMemoryAlignment :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryAlignment")
}
@(objc_type=Argument, objc_name="threadgroupMemoryDataSize")
Argument_threadgroupMemoryDataSize :: #force_inline proc(self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryDataSize")
}
@(objc_type=Argument, objc_name="type")
Argument_type :: #force_inline proc(self: ^Argument) -> ArgumentType {
	return msgSend(ArgumentType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ArgumentDescriptor
Class Methods:
	alloc
	argumentDescriptor
Methods:
	init
	access
	arrayLength
	constantBlockAlignment
	dataType
	index
	setAccess
	setArrayLength
	setConstantBlockAlignment
	setDataType
	setIndex
	setTextureType
	textureType
*/
@(objc_class="MTLArgumentDescriptor")
ArgumentDescriptor :: struct { using _: NS.Copying(ArgumentDescriptor) }

@(objc_type=ArgumentDescriptor, objc_class_name="alloc")
ArgumentDescriptor_alloc :: #force_inline proc() -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "alloc")
}
@(objc_type=ArgumentDescriptor, objc_name="init")
ArgumentDescriptor_init :: #force_inline proc(self: ^ArgumentDescriptor) -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, self, "init")
}
@(objc_type=ArgumentDescriptor, objc_name="access")
ArgumentDescriptor_access :: #force_inline proc(self: ^ArgumentDescriptor) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=ArgumentDescriptor, objc_class_name="argumentDescriptor")
ArgumentDescriptor_argumentDescriptor :: #force_inline proc() -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "argumentDescriptor")
}
@(objc_type=ArgumentDescriptor, objc_name="arrayLength")
ArgumentDescriptor_arrayLength :: #force_inline proc(self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=ArgumentDescriptor, objc_name="constantBlockAlignment")
ArgumentDescriptor_constantBlockAlignment :: #force_inline proc(self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "constantBlockAlignment")
}
@(objc_type=ArgumentDescriptor, objc_name="dataType")
ArgumentDescriptor_dataType :: #force_inline proc(self: ^ArgumentDescriptor) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=ArgumentDescriptor, objc_name="index")
ArgumentDescriptor_index :: #force_inline proc(self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=ArgumentDescriptor, objc_name="setAccess")
ArgumentDescriptor_setAccess :: #force_inline proc(self: ^ArgumentDescriptor, access: ArgumentAccess) {
	msgSend(nil, self, "setAccess:", access)
}
@(objc_type=ArgumentDescriptor, objc_name="setArrayLength")
ArgumentDescriptor_setArrayLength :: #force_inline proc(self: ^ArgumentDescriptor, arrayLength: NS.UInteger) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=ArgumentDescriptor, objc_name="setConstantBlockAlignment")
ArgumentDescriptor_setConstantBlockAlignment :: #force_inline proc(self: ^ArgumentDescriptor, constantBlockAlignment: NS.UInteger) {
	msgSend(nil, self, "setConstantBlockAlignment:", constantBlockAlignment)
}
@(objc_type=ArgumentDescriptor, objc_name="setDataType")
ArgumentDescriptor_setDataType :: #force_inline proc(self: ^ArgumentDescriptor, dataType: DataType) {
	msgSend(nil, self, "setDataType:", dataType)
}
@(objc_type=ArgumentDescriptor, objc_name="setIndex")
ArgumentDescriptor_setIndex :: #force_inline proc(self: ^ArgumentDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setIndex:", index)
}
@(objc_type=ArgumentDescriptor, objc_name="setTextureType")
ArgumentDescriptor_setTextureType :: #force_inline proc(self: ^ArgumentDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=ArgumentDescriptor, objc_name="textureType")
ArgumentDescriptor_textureType :: #force_inline proc(self: ^ArgumentDescriptor) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ArrayType
Class Methods:
	alloc
Methods:
	init
	argumentIndexStride
	arrayLength
	elementArrayType
	elementPointerType
	elementStructType
	elementTextureReferenceType
	elementType
	stride
*/
@(objc_class="MTLArrayType")
ArrayType :: struct { using _: Type }

@(objc_type=ArrayType, objc_class_name="alloc")
ArrayType_alloc :: #force_inline proc() -> ^ArrayType {
	return msgSend(^ArrayType, ArrayType, "alloc")
}
@(objc_type=ArrayType, objc_name="init")
ArrayType_init :: #force_inline proc(self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "init")
}
@(objc_type=ArrayType, objc_name="argumentIndexStride")
ArrayType_argumentIndexStride :: #force_inline proc(self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "argumentIndexStride")
}
@(objc_type=ArrayType, objc_name="arrayLength")
ArrayType_arrayLength :: #force_inline proc(self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=ArrayType, objc_name="elementArrayType")
ArrayType_elementArrayType :: #force_inline proc(self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=ArrayType, objc_name="elementPointerType")
ArrayType_elementPointerType :: #force_inline proc(self: ^ArrayType) -> ^PointerType {
	return msgSend(^PointerType, self, "elementPointerType")
}
@(objc_type=ArrayType, objc_name="elementStructType")
ArrayType_elementStructType :: #force_inline proc(self: ^ArrayType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=ArrayType, objc_name="elementTextureReferenceType")
ArrayType_elementTextureReferenceType :: #force_inline proc(self: ^ArrayType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "elementTextureReferenceType")
}
@(objc_type=ArrayType, objc_name="elementType")
ArrayType_elementType :: #force_inline proc(self: ^ArrayType) -> DataType {
	return msgSend(DataType, self, "elementType")
}
@(objc_type=ArrayType, objc_name="stride")
ArrayType_stride :: #force_inline proc(self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Attribute
Class Methods:
	alloc
Methods:
	init
	attributeIndex
	attributeType
	isActive
	isPatchControlPointData
	isPatchData
	name
*/
@(objc_class="MTLAttribute")
Attribute :: struct { using _: NS.Object }

@(objc_type=Attribute, objc_class_name="alloc")
Attribute_alloc :: #force_inline proc() -> ^Attribute {
	return msgSend(^Attribute, Attribute, "alloc")
}
@(objc_type=Attribute, objc_name="init")
Attribute_init :: #force_inline proc(self: ^Attribute) -> ^Attribute {
	return msgSend(^Attribute, self, "init")
}
@(objc_type=Attribute, objc_name="attributeIndex")
Attribute_attributeIndex :: #force_inline proc(self: ^Attribute) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "attributeIndex")
}
@(objc_type=Attribute, objc_name="attributeType")
Attribute_attributeType :: #force_inline proc(self: ^Attribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=Attribute, objc_name="isActive")
Attribute_isActive :: #force_inline proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Attribute, objc_name="isPatchControlPointData")
Attribute_isPatchControlPointData :: #force_inline proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=Attribute, objc_name="isPatchData")
Attribute_isPatchData :: #force_inline proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=Attribute, objc_name="name")
Attribute_name :: #force_inline proc(self: ^Attribute) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AttributeDescriptor
Class Methods:
	alloc
Methods:
	init
	bufferIndex
	format
	offset
	setBufferIndex
	setFormat
	setOffset
*/
@(objc_class="MTLAttributeDescriptor")
AttributeDescriptor :: struct { using _: NS.Copying(AttributeDescriptor) }

@(objc_type=AttributeDescriptor, objc_class_name="alloc")
AttributeDescriptor_alloc :: #force_inline proc() -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, AttributeDescriptor, "alloc")
}
@(objc_type=AttributeDescriptor, objc_name="init")
AttributeDescriptor_init :: #force_inline proc(self: ^AttributeDescriptor) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "init")
}
@(objc_type=AttributeDescriptor, objc_name="bufferIndex")
AttributeDescriptor_bufferIndex :: #force_inline proc(self: ^AttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferIndex")
}
@(objc_type=AttributeDescriptor, objc_name="format")
AttributeDescriptor_format :: #force_inline proc(self: ^AttributeDescriptor) -> AttributeFormat {
	return msgSend(AttributeFormat, self, "format")
}
@(objc_type=AttributeDescriptor, objc_name="offset")
AttributeDescriptor_offset :: #force_inline proc(self: ^AttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=AttributeDescriptor, objc_name="setBufferIndex")
AttributeDescriptor_setBufferIndex :: #force_inline proc(self: ^AttributeDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=AttributeDescriptor, objc_name="setFormat")
AttributeDescriptor_setFormat :: #force_inline proc(self: ^AttributeDescriptor, format: AttributeFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=AttributeDescriptor, objc_name="setOffset")
AttributeDescriptor_setOffset :: #force_inline proc(self: ^AttributeDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AttributeDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLAttributeDescriptorArray")
AttributeDescriptorArray :: struct { using _: NS.Object }

@(objc_type=AttributeDescriptorArray, objc_class_name="alloc")
AttributeDescriptorArray_alloc :: #force_inline proc() -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, AttributeDescriptorArray, "alloc")
}
@(objc_type=AttributeDescriptorArray, objc_name="init")
AttributeDescriptorArray_init :: #force_inline proc(self: ^AttributeDescriptorArray) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "init")
}
@(objc_type=AttributeDescriptorArray, objc_name="object")
AttributeDescriptorArray_object :: #force_inline proc(self: ^AttributeDescriptorArray, index: NS.UInteger) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=AttributeDescriptorArray, objc_name="setObject")
AttributeDescriptorArray_setObject :: #force_inline proc(self: ^AttributeDescriptorArray, attributeDesc: ^AttributeDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attributeDesc, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BinaryArchiveDescriptor
Class Methods:
	alloc
Methods:
	init
	setUrl
	url
*/
@(objc_class="MTLBinaryArchiveDescriptor")
BinaryArchiveDescriptor :: struct { using _: NS.Copying(BinaryArchiveDescriptor) }

@(objc_type=BinaryArchiveDescriptor, objc_class_name="alloc")
BinaryArchiveDescriptor_alloc :: #force_inline proc() -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, BinaryArchiveDescriptor, "alloc")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="init")
BinaryArchiveDescriptor_init :: #force_inline proc(self: ^BinaryArchiveDescriptor) -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, self, "init")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="setUrl")
BinaryArchiveDescriptor_setUrl :: #force_inline proc(self: ^BinaryArchiveDescriptor, url: ^NS.URL) {
	msgSend(nil, self, "setUrl:", url)
}
@(objc_type=BinaryArchiveDescriptor, objc_name="url")
BinaryArchiveDescriptor_url :: #force_inline proc(self: ^BinaryArchiveDescriptor) -> ^NS.URL {
	return msgSend(^NS.URL, self, "url")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BlitPassDescriptor
Class Methods:
	alloc
	blitPassDescriptor
Methods:
	init
	sampleBufferAttachments
*/
@(objc_class="MTLBlitPassDescriptor")
BlitPassDescriptor :: struct { using _: NS.Copying(BlitPassDescriptor) }

@(objc_type=BlitPassDescriptor, objc_class_name="alloc")
BlitPassDescriptor_alloc :: #force_inline proc() -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "alloc")
}
@(objc_type=BlitPassDescriptor, objc_name="init")
BlitPassDescriptor_init :: #force_inline proc(self: ^BlitPassDescriptor) -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, self, "init")
}
@(objc_type=BlitPassDescriptor, objc_class_name="blitPassDescriptor")
BlitPassDescriptor_blitPassDescriptor :: #force_inline proc() -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "blitPassDescriptor")
}
@(objc_type=BlitPassDescriptor, objc_name="sampleBufferAttachments")
BlitPassDescriptor_sampleBufferAttachments :: #force_inline proc(self: ^BlitPassDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BlitPassSampleBufferAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	endOfEncoderSampleIndex
	sampleBuffer
	setEndOfEncoderSampleIndex
	setSampleBuffer
	setStartOfEncoderSampleIndex
	startOfEncoderSampleIndex
*/
@(objc_class="MTLBlitPassSampleBufferAttachmentDescriptor")
BlitPassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(BlitPassSampleBufferAttachmentDescriptor) }

@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_class_name="alloc")
BlitPassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc() -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, BlitPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="init")
BlitPassSampleBufferAttachmentDescriptor_init :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor, sampleBuffer: ^CounterSampleBuffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BlitPassSampleBufferAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLBlitPassSampleBufferAttachmentDescriptorArray")
BlitPassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_class_name="alloc")
BlitPassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, BlitPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="init")
BlitPassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="object")
BlitPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
BlitPassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachment: ^BlitPassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BufferLayoutDescriptor
Class Methods:
	alloc
Methods:
	init
	setStepFunction
	setStepRate
	setStride
	stepFunction
	stepRate
	stride
*/
@(objc_class="MTLBufferLayoutDescriptor")
BufferLayoutDescriptor :: struct { using _: NS.Copying(BufferLayoutDescriptor) }

@(objc_type=BufferLayoutDescriptor, objc_class_name="alloc")
BufferLayoutDescriptor_alloc :: #force_inline proc() -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, BufferLayoutDescriptor, "alloc")
}
@(objc_type=BufferLayoutDescriptor, objc_name="init")
BufferLayoutDescriptor_init :: #force_inline proc(self: ^BufferLayoutDescriptor) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "init")
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepFunction")
BufferLayoutDescriptor_setStepFunction :: #force_inline proc(self: ^BufferLayoutDescriptor, stepFunction: StepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepRate")
BufferLayoutDescriptor_setStepRate :: #force_inline proc(self: ^BufferLayoutDescriptor, stepRate: NS.UInteger) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStride")
BufferLayoutDescriptor_setStride :: #force_inline proc(self: ^BufferLayoutDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepFunction")
BufferLayoutDescriptor_stepFunction :: #force_inline proc(self: ^BufferLayoutDescriptor) -> StepFunction {
	return msgSend(StepFunction, self, "stepFunction")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepRate")
BufferLayoutDescriptor_stepRate :: #force_inline proc(self: ^BufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stepRate")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stride")
BufferLayoutDescriptor_stride :: #force_inline proc(self: ^BufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BufferLayoutDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLBufferLayoutDescriptorArray")
BufferLayoutDescriptorArray :: struct { using _: NS.Object }

@(objc_type=BufferLayoutDescriptorArray, objc_class_name="alloc")
BufferLayoutDescriptorArray_alloc :: #force_inline proc() -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, BufferLayoutDescriptorArray, "alloc")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="init")
BufferLayoutDescriptorArray_init :: #force_inline proc(self: ^BufferLayoutDescriptorArray) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "init")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="object")
BufferLayoutDescriptorArray_object :: #force_inline proc(self: ^BufferLayoutDescriptorArray, index: NS.UInteger) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="setObject")
BufferLayoutDescriptorArray_setObject :: #force_inline proc(self: ^BufferLayoutDescriptorArray, bufferDesc: ^BufferLayoutDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", bufferDesc, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CaptureDescriptor
Class Methods:
	alloc
Methods:
	init
	captureObject
	destination
	outputURL
	setCaptureObject
	setDestination
	setOutputURL
*/
@(objc_class="MTLCaptureDescriptor")
CaptureDescriptor :: struct { using _: NS.Copying(CaptureDescriptor) }

@(objc_type=CaptureDescriptor, objc_class_name="alloc")
CaptureDescriptor_alloc :: #force_inline proc() -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, CaptureDescriptor, "alloc")
}
@(objc_type=CaptureDescriptor, objc_name="init")
CaptureDescriptor_init :: #force_inline proc(self: ^CaptureDescriptor) -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, self, "init")
}
@(objc_type=CaptureDescriptor, objc_name="captureObject")
CaptureDescriptor_captureObject :: #force_inline proc(self: ^CaptureDescriptor) -> id {
	return msgSend(id, self, "captureObject")
}
@(objc_type=CaptureDescriptor, objc_name="destination")
CaptureDescriptor_destination :: #force_inline proc(self: ^CaptureDescriptor) -> CaptureDestination {
	return msgSend(CaptureDestination, self, "destination")
}
@(objc_type=CaptureDescriptor, objc_name="outputURL")
CaptureDescriptor_outputURL :: #force_inline proc(self: ^CaptureDescriptor) -> ^NS.URL {
	return msgSend(^NS.URL, self, "outputURL")
}
@(objc_type=CaptureDescriptor, objc_name="setCaptureObject")
CaptureDescriptor_setCaptureObject :: #force_inline proc(self: ^CaptureDescriptor, captureObject: id) {
	msgSend(nil, self, "setCaptureObject:", captureObject)
}
@(objc_type=CaptureDescriptor, objc_name="setDestination")
CaptureDescriptor_setDestination :: #force_inline proc(self: ^CaptureDescriptor, destination: CaptureDestination) {
	msgSend(nil, self, "setDestination:", destination)
}
@(objc_type=CaptureDescriptor, objc_name="setOutputURL")
CaptureDescriptor_setOutputURL :: #force_inline proc(self: ^CaptureDescriptor, outputURL: ^NS.URL) {
	msgSend(nil, self, "setOutputURL:", outputURL)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CaptureManager
Class Methods:
	alloc
	sharedCaptureManager
Methods:
	defaultCaptureScope
	init
	isCapturing
	newCaptureScopeWithCommandQueue
	newCaptureScopeWithDevice
	setDefaultCaptureScope
	startCaptureWithCommandQueue
	startCaptureWithDescriptor
	startCaptureWithDevice
	startCaptureWithScope
	stopCapture
	supportsDestination
*/
@(objc_class="MTLCaptureManager")
CaptureManager :: struct { using _: NS.Object }

@(objc_type=CaptureManager, objc_class_name="alloc")
CaptureManager_alloc :: #force_inline proc() -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "alloc")
}
@(objc_type=CaptureManager, objc_name="defaultCaptureScope")
CaptureManager_defaultCaptureScope :: #force_inline proc(self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "defaultCaptureScope")
}
@(objc_type=CaptureManager, objc_name="init")
CaptureManager_init :: #force_inline proc(self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "init")
}
@(objc_type=CaptureManager, objc_name="isCapturing")
CaptureManager_isCapturing :: #force_inline proc(self: ^CaptureManager) -> BOOL {
	return msgSend(BOOL, self, "isCapturing")
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithCommandQueue")
CaptureManager_newCaptureScopeWithCommandQueue :: #force_inline proc(self: ^CaptureManager, commandQueue: ^CommandQueue) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "newCaptureScopeWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithDevice")
CaptureManager_newCaptureScopeWithDevice :: #force_inline proc(self: ^CaptureManager, device: ^Device) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "newCaptureScopeWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="setDefaultCaptureScope")
CaptureManager_setDefaultCaptureScope :: #force_inline proc(self: ^CaptureManager, defaultCaptureScope: ^CaptureScope) {
	msgSend(nil, self, "setDefaultCaptureScope:", defaultCaptureScope)
}
@(objc_type=CaptureManager, objc_class_name="sharedCaptureManager")
CaptureManager_sharedCaptureManager :: #force_inline proc() -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "sharedCaptureManager")
}
@(objc_type=CaptureManager, objc_name="startCaptureWithCommandQueue")
CaptureManager_startCaptureWithCommandQueue :: #force_inline proc(self: ^CaptureManager, commandQueue: ^CommandQueue) {
	msgSend(nil, self, "startCaptureWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDescriptor")
CaptureManager_startCaptureWithDescriptor :: #force_inline proc(self: ^CaptureManager, descriptor: ^CaptureDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "startCaptureWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDevice")
CaptureManager_startCaptureWithDevice :: #force_inline proc(self: ^CaptureManager, device: ^Device) {
	msgSend(nil, self, "startCaptureWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithScope")
CaptureManager_startCaptureWithScope :: #force_inline proc(self: ^CaptureManager, captureScope: ^CaptureScope) {
	msgSend(nil, self, "startCaptureWithScope:", captureScope)
}
@(objc_type=CaptureManager, objc_name="stopCapture")
CaptureManager_stopCapture :: #force_inline proc(self: ^CaptureManager) {
	msgSend(nil, self, "stopCapture")
}
@(objc_type=CaptureManager, objc_name="supportsDestination")
CaptureManager_supportsDestination :: #force_inline proc(self: ^CaptureManager, destination: CaptureDestination) -> BOOL {
	return msgSend(BOOL, self, "supportsDestination:", destination)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CommandBufferDescriptor
Class Methods:
	alloc
Methods:
	init
	errorOptions
	retainedReferences
	setErrorOptions
	setRetainedReferences
*/
@(objc_class="MTLCommandBufferDescriptor")
CommandBufferDescriptor :: struct { using _: NS.Copying(CommandBufferDescriptor) }

@(objc_type=CommandBufferDescriptor, objc_class_name="alloc")
CommandBufferDescriptor_alloc :: #force_inline proc() -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, CommandBufferDescriptor, "alloc")
}
@(objc_type=CommandBufferDescriptor, objc_name="init")
CommandBufferDescriptor_init :: #force_inline proc(self: ^CommandBufferDescriptor) -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, self, "init")
}
@(objc_type=CommandBufferDescriptor, objc_name="errorOptions")
CommandBufferDescriptor_errorOptions :: #force_inline proc(self: ^CommandBufferDescriptor) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBufferDescriptor, objc_name="retainedReferences")
CommandBufferDescriptor_retainedReferences :: #force_inline proc(self: ^CommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBufferDescriptor, objc_name="setErrorOptions")
CommandBufferDescriptor_setErrorOptions :: #force_inline proc(self: ^CommandBufferDescriptor, errorOptions: CommandBufferErrorOption) {
	msgSend(nil, self, "setErrorOptions:", errorOptions)
}
@(objc_type=CommandBufferDescriptor, objc_name="setRetainedReferences")
CommandBufferDescriptor_setRetainedReferences :: #force_inline proc(self: ^CommandBufferDescriptor, retainedReferences: BOOL) {
	msgSend(nil, self, "setRetainedReferences:", retainedReferences)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CompileOptions
Class Methods:
	alloc
Methods:
	init
	fastMathEnabled
	installName
	languageVersion
	libraries
	libraryType
	preprocessorMacros
	preserveInvariance
	setFastMathEnabled
	setInstallName
	setLanguageVersion
	setLibraries
	setLibraryType
	setPreprocessorMacros
	setPreserveInvariance
*/
@(objc_class="MTLCompileOptions")
CompileOptions :: struct { using _: NS.Copying(CompileOptions) }

@(objc_type=CompileOptions, objc_class_name="alloc")
CompileOptions_alloc :: #force_inline proc() -> ^CompileOptions {
	return msgSend(^CompileOptions, CompileOptions, "alloc")
}
@(objc_type=CompileOptions, objc_name="init")
CompileOptions_init :: #force_inline proc(self: ^CompileOptions) -> ^CompileOptions {
	return msgSend(^CompileOptions, self, "init")
}
@(objc_type=CompileOptions, objc_name="fastMathEnabled")
CompileOptions_fastMathEnabled :: #force_inline proc(self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "fastMathEnabled")
}
@(objc_type=CompileOptions, objc_name="installName")
CompileOptions_installName :: #force_inline proc(self: ^CompileOptions) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=CompileOptions, objc_name="languageVersion")
CompileOptions_languageVersion :: #force_inline proc(self: ^CompileOptions) -> LanguageVersion {
	return msgSend(LanguageVersion, self, "languageVersion")
}
@(objc_type=CompileOptions, objc_name="libraries")
CompileOptions_libraries :: #force_inline proc(self: ^CompileOptions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "libraries")
}
@(objc_type=CompileOptions, objc_name="libraryType")
CompileOptions_libraryType :: #force_inline proc(self: ^CompileOptions) -> LibraryType {
	return msgSend(LibraryType, self, "libraryType")
}
@(objc_type=CompileOptions, objc_name="preprocessorMacros")
CompileOptions_preprocessorMacros :: #force_inline proc(self: ^CompileOptions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "preprocessorMacros")
}
@(objc_type=CompileOptions, objc_name="preserveInvariance")
CompileOptions_preserveInvariance :: #force_inline proc(self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "preserveInvariance")
}
@(objc_type=CompileOptions, objc_name="setFastMathEnabled")
CompileOptions_setFastMathEnabled :: #force_inline proc(self: ^CompileOptions, fastMathEnabled: BOOL) {
	msgSend(nil, self, "setFastMathEnabled:", fastMathEnabled)
}
@(objc_type=CompileOptions, objc_name="setInstallName")
CompileOptions_setInstallName :: #force_inline proc(self: ^CompileOptions, installName: ^NS.String) {
	msgSend(nil, self, "setInstallName:", installName)
}
@(objc_type=CompileOptions, objc_name="setLanguageVersion")
CompileOptions_setLanguageVersion :: #force_inline proc(self: ^CompileOptions, languageVersion: LanguageVersion) {
	msgSend(nil, self, "setLanguageVersion:", languageVersion)
}
@(objc_type=CompileOptions, objc_name="setLibraries")
CompileOptions_setLibraries :: #force_inline proc(self: ^CompileOptions, libraries: ^NS.Array) {
	msgSend(nil, self, "setLibraries:", libraries)
}
@(objc_type=CompileOptions, objc_name="setLibraryType")
CompileOptions_setLibraryType :: #force_inline proc(self: ^CompileOptions, libraryType: LibraryType) {
	msgSend(nil, self, "setLibraryType:", libraryType)
}
@(objc_type=CompileOptions, objc_name="setPreprocessorMacros")
CompileOptions_setPreprocessorMacros :: #force_inline proc(self: ^CompileOptions, preprocessorMacros: ^NS.Dictionary) {
	msgSend(nil, self, "setPreprocessorMacros:", preprocessorMacros)
}
@(objc_type=CompileOptions, objc_name="setPreserveInvariance")
CompileOptions_setPreserveInvariance :: #force_inline proc(self: ^CompileOptions, preserveInvariance: BOOL) {
	msgSend(nil, self, "setPreserveInvariance:", preserveInvariance)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePassDescriptor
Class Methods:
	alloc
	computePassDescriptor
Methods:
	init
	dispatchType
	sampleBufferAttachments
	setDispatchType
*/
@(objc_class="MTLComputePassDescriptor")
ComputePassDescriptor :: struct { using _: NS.Copying(ComputePassDescriptor) }

@(objc_type=ComputePassDescriptor, objc_class_name="alloc")
ComputePassDescriptor_alloc :: #force_inline proc() -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "alloc")
}
@(objc_type=ComputePassDescriptor, objc_name="init")
ComputePassDescriptor_init :: #force_inline proc(self: ^ComputePassDescriptor) -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, self, "init")
}
@(objc_type=ComputePassDescriptor, objc_class_name="computePassDescriptor")
ComputePassDescriptor_computePassDescriptor :: #force_inline proc() -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "computePassDescriptor")
}
@(objc_type=ComputePassDescriptor, objc_name="dispatchType")
ComputePassDescriptor_dispatchType :: #force_inline proc(self: ^ComputePassDescriptor) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputePassDescriptor, objc_name="sampleBufferAttachments")
ComputePassDescriptor_sampleBufferAttachments :: #force_inline proc(self: ^ComputePassDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=ComputePassDescriptor, objc_name="setDispatchType")
ComputePassDescriptor_setDispatchType :: #force_inline proc(self: ^ComputePassDescriptor, dispatchType: DispatchType) {
	msgSend(nil, self, "setDispatchType:", dispatchType)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePassSampleBufferAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	endOfEncoderSampleIndex
	sampleBuffer
	setEndOfEncoderSampleIndex
	setSampleBuffer
	setStartOfEncoderSampleIndex
	startOfEncoderSampleIndex
*/
@(objc_class="MTLComputePassSampleBufferAttachmentDescriptor")
ComputePassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(ComputePassSampleBufferAttachmentDescriptor) }

@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_class_name="alloc")
ComputePassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc() -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, ComputePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="init")
ComputePassSampleBufferAttachmentDescriptor_init :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "sampleBuffer")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor, sampleBuffer: ^Buffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePassSampleBufferAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLComputePassSampleBufferAttachmentDescriptorArray")
ComputePassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_class_name="alloc")
ComputePassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, ComputePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ComputePassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ComputePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ComputePassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachment: ^ComputePassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePipelineDescriptor
Class Methods:
	alloc
Methods:
	init
	binaryArchives
	buffers
	computeFunction
	insertLibraries
	label
	linkedFunctions
	maxCallStackDepth
	maxTotalThreadsPerThreadgroup
	reset
	setBinaryArchives
	setComputeFunction
	setInsertLibraries
	setLabel
	setLinkedFunctions
	setMaxCallStackDepth
	setMaxTotalThreadsPerThreadgroup
	setStageInputDescriptor
	setSupportAddingBinaryFunctions
	setSupportIndirectCommandBuffers
	setThreadGroupSizeIsMultipleOfThreadExecutionWidth
	stageInputDescriptor
	supportAddingBinaryFunctions
	supportIndirectCommandBuffers
	threadGroupSizeIsMultipleOfThreadExecutionWidth
*/
@(objc_class="MTLComputePipelineDescriptor")
ComputePipelineDescriptor :: struct { using _: NS.Copying(ComputePipelineDescriptor) }

@(objc_type=ComputePipelineDescriptor, objc_class_name="alloc")
ComputePipelineDescriptor_alloc :: #force_inline proc() -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, ComputePipelineDescriptor, "alloc")
}
@(objc_type=ComputePipelineDescriptor, objc_name="init")
ComputePipelineDescriptor_init :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, self, "init")
}
@(objc_type=ComputePipelineDescriptor, objc_name="binaryArchives")
ComputePipelineDescriptor_binaryArchives :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=ComputePipelineDescriptor, objc_name="buffers")
ComputePipelineDescriptor_buffers :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "buffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="computeFunction")
ComputePipelineDescriptor_computeFunction :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, self, "computeFunction")
}
@(objc_type=ComputePipelineDescriptor, objc_name="insertLibraries")
ComputePipelineDescriptor_insertLibraries :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "insertLibraries")
}
@(objc_type=ComputePipelineDescriptor, objc_name="label")
ComputePipelineDescriptor_label :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineDescriptor, objc_name="linkedFunctions")
ComputePipelineDescriptor_linkedFunctions :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "linkedFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxCallStackDepth")
ComputePipelineDescriptor_maxCallStackDepth :: #force_inline proc(self: ^ComputePipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxCallStackDepth")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_maxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^ComputePipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineDescriptor, objc_name="reset")
ComputePipelineDescriptor_reset :: #force_inline proc(self: ^ComputePipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=ComputePipelineDescriptor, objc_name="setBinaryArchives")
ComputePipelineDescriptor_setBinaryArchives :: #force_inline proc(self: ^ComputePipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setComputeFunction")
ComputePipelineDescriptor_setComputeFunction :: #force_inline proc(self: ^ComputePipelineDescriptor, computeFunction: ^Function) {
	msgSend(nil, self, "setComputeFunction:", computeFunction)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setInsertLibraries")
ComputePipelineDescriptor_setInsertLibraries :: #force_inline proc(self: ^ComputePipelineDescriptor, insertLibraries: ^NS.Array) {
	msgSend(nil, self, "setInsertLibraries:", insertLibraries)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLabel")
ComputePipelineDescriptor_setLabel :: #force_inline proc(self: ^ComputePipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLinkedFunctions")
ComputePipelineDescriptor_setLinkedFunctions :: #force_inline proc(self: ^ComputePipelineDescriptor, linkedFunctions: ^LinkedFunctions) {
	msgSend(nil, self, "setLinkedFunctions:", linkedFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxCallStackDepth")
ComputePipelineDescriptor_setMaxCallStackDepth :: #force_inline proc(self: ^ComputePipelineDescriptor, maxCallStackDepth: NS.UInteger) {
	msgSend(nil, self, "setMaxCallStackDepth:", maxCallStackDepth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^ComputePipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setStageInputDescriptor")
ComputePipelineDescriptor_setStageInputDescriptor :: #force_inline proc(self: ^ComputePipelineDescriptor, stageInputDescriptor: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "setStageInputDescriptor:", stageInputDescriptor)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportAddingBinaryFunctions")
ComputePipelineDescriptor_setSupportAddingBinaryFunctions :: #force_inline proc(self: ^ComputePipelineDescriptor, supportAddingBinaryFunctions: BOOL) {
	msgSend(nil, self, "setSupportAddingBinaryFunctions:", supportAddingBinaryFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
ComputePipelineDescriptor_setSupportIndirectCommandBuffers :: #force_inline proc(self: ^ComputePipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setThreadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_setThreadGroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc(self: ^ComputePipelineDescriptor, threadGroupSizeIsMultipleOfThreadExecutionWidth: BOOL) {
	msgSend(nil, self, "setThreadGroupSizeIsMultipleOfThreadExecutionWidth:", threadGroupSizeIsMultipleOfThreadExecutionWidth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="stageInputDescriptor")
ComputePipelineDescriptor_stageInputDescriptor :: #force_inline proc(self: ^ComputePipelineDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "stageInputDescriptor")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportAddingBinaryFunctions")
ComputePipelineDescriptor_supportAddingBinaryFunctions :: #force_inline proc(self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportAddingBinaryFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportIndirectCommandBuffers")
ComputePipelineDescriptor_supportIndirectCommandBuffers :: #force_inline proc(self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="threadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_threadGroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc(self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "threadGroupSizeIsMultipleOfThreadExecutionWidth")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePipelineReflection
Class Methods:
	alloc
Methods:
	init
	arguments
*/
@(objc_class="MTLComputePipelineReflection")
ComputePipelineReflection :: struct { using _: NS.Object }

@(objc_type=ComputePipelineReflection, objc_class_name="alloc")
ComputePipelineReflection_alloc :: #force_inline proc() -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, ComputePipelineReflection, "alloc")
}
@(objc_type=ComputePipelineReflection, objc_name="init")
ComputePipelineReflection_init :: #force_inline proc(self: ^ComputePipelineReflection) -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, self, "init")
}
@(objc_type=ComputePipelineReflection, objc_name="arguments")
ComputePipelineReflection_arguments :: #force_inline proc(self: ^ComputePipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "arguments")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CounterSampleBufferDescriptor
Class Methods:
	alloc
Methods:
	init
	counterSet
	label
	sampleCount
	setCounterSet
	setLabel
	setSampleCount
	setStorageMode
	storageMode
*/
@(objc_class="MTLCounterSampleBufferDescriptor")
CounterSampleBufferDescriptor :: struct { using _: NS.Copying(CounterSampleBufferDescriptor) }

@(objc_type=CounterSampleBufferDescriptor, objc_class_name="alloc")
CounterSampleBufferDescriptor_alloc :: #force_inline proc() -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, CounterSampleBufferDescriptor, "alloc")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="init")
CounterSampleBufferDescriptor_init :: #force_inline proc(self: ^CounterSampleBufferDescriptor) -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, self, "init")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="counterSet")
CounterSampleBufferDescriptor_counterSet :: #force_inline proc(self: ^CounterSampleBufferDescriptor) -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, self, "counterSet")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="label")
CounterSampleBufferDescriptor_label :: #force_inline proc(self: ^CounterSampleBufferDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="sampleCount")
CounterSampleBufferDescriptor_sampleCount :: #force_inline proc(self: ^CounterSampleBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setCounterSet")
CounterSampleBufferDescriptor_setCounterSet :: #force_inline proc(self: ^CounterSampleBufferDescriptor, counterSet: ^CounterSet) {
	msgSend(nil, self, "setCounterSet:", counterSet)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setLabel")
CounterSampleBufferDescriptor_setLabel :: #force_inline proc(self: ^CounterSampleBufferDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setSampleCount")
CounterSampleBufferDescriptor_setSampleCount :: #force_inline proc(self: ^CounterSampleBufferDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setStorageMode")
CounterSampleBufferDescriptor_setStorageMode :: #force_inline proc(self: ^CounterSampleBufferDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="storageMode")
CounterSampleBufferDescriptor_storageMode :: #force_inline proc(self: ^CounterSampleBufferDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	DepthStencilDescriptor
Class Methods:
	alloc
Methods:
	init
	backFaceStencil
	depthCompareFunction
	frontFaceStencil
	isDepthWriteEnabled
	label
	setBackFaceStencil
	setDepthCompareFunction
	setDepthWriteEnabled
	setFrontFaceStencil
	setLabel
*/
@(objc_class="MTLDepthStencilDescriptor")
DepthStencilDescriptor :: struct { using _: NS.Copying(DepthStencilDescriptor) }

@(objc_type=DepthStencilDescriptor, objc_class_name="alloc")
DepthStencilDescriptor_alloc :: #force_inline proc() -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, DepthStencilDescriptor, "alloc")
}
@(objc_type=DepthStencilDescriptor, objc_name="init")
DepthStencilDescriptor_init :: #force_inline proc(self: ^DepthStencilDescriptor) -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, self, "init")
}
@(objc_type=DepthStencilDescriptor, objc_name="backFaceStencil")
DepthStencilDescriptor_backFaceStencil :: #force_inline proc(self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "backFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="depthCompareFunction")
DepthStencilDescriptor_depthCompareFunction :: #force_inline proc(self: ^DepthStencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "depthCompareFunction")
}
@(objc_type=DepthStencilDescriptor, objc_name="frontFaceStencil")
DepthStencilDescriptor_frontFaceStencil :: #force_inline proc(self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "frontFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="isDepthWriteEnabled")
DepthStencilDescriptor_isDepthWriteEnabled :: #force_inline proc(self: ^DepthStencilDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isDepthWriteEnabled")
}
@(objc_type=DepthStencilDescriptor, objc_name="label")
DepthStencilDescriptor_label :: #force_inline proc(self: ^DepthStencilDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DepthStencilDescriptor, objc_name="setBackFaceStencil")
DepthStencilDescriptor_setBackFaceStencil :: #force_inline proc(self: ^DepthStencilDescriptor, backFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setBackFaceStencil:", backFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthCompareFunction")
DepthStencilDescriptor_setDepthCompareFunction :: #force_inline proc(self: ^DepthStencilDescriptor, depthCompareFunction: CompareFunction) {
	msgSend(nil, self, "setDepthCompareFunction:", depthCompareFunction)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthWriteEnabled")
DepthStencilDescriptor_setDepthWriteEnabled :: #force_inline proc(self: ^DepthStencilDescriptor, depthWriteEnabled: BOOL) {
	msgSend(nil, self, "setDepthWriteEnabled:", depthWriteEnabled)
}
@(objc_type=DepthStencilDescriptor, objc_name="setFrontFaceStencil")
DepthStencilDescriptor_setFrontFaceStencil :: #force_inline proc(self: ^DepthStencilDescriptor, frontFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setFrontFaceStencil:", frontFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setLabel")
DepthStencilDescriptor_setLabel :: #force_inline proc(self: ^DepthStencilDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionConstant
Class Methods:
	alloc
Methods:
	init
	index
	name
	required
	type
*/
@(objc_class="MTLFunctionConstant")
FunctionConstant :: struct { using _: NS.Copying(FunctionConstant) }

@(objc_type=FunctionConstant, objc_class_name="alloc")
FunctionConstant_alloc :: #force_inline proc() -> ^FunctionConstant {
	return msgSend(^FunctionConstant, FunctionConstant, "alloc")
}
@(objc_type=FunctionConstant, objc_name="init")
FunctionConstant_init :: #force_inline proc(self: ^FunctionConstant) -> ^FunctionConstant {
	return msgSend(^FunctionConstant, self, "init")
}
@(objc_type=FunctionConstant, objc_name="index")
FunctionConstant_index :: #force_inline proc(self: ^FunctionConstant) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=FunctionConstant, objc_name="name")
FunctionConstant_name :: #force_inline proc(self: ^FunctionConstant) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionConstant, objc_name="required")
FunctionConstant_required :: #force_inline proc(self: ^FunctionConstant) -> BOOL {
	return msgSend(BOOL, self, "required")
}
@(objc_type=FunctionConstant, objc_name="type")
FunctionConstant_type :: #force_inline proc(self: ^FunctionConstant) -> DataType {
	return msgSend(DataType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionConstantValues
Class Methods:
	alloc
Methods:
	init
	reset
	setConstantValue
	setConstantValue
	setConstantValues
*/
@(objc_class="MTLFunctionConstantValues")
FunctionConstantValues :: struct { using _: NS.Copying(FunctionConstantValues) }

@(objc_type=FunctionConstantValues, objc_class_name="alloc")
FunctionConstantValues_alloc :: #force_inline proc() -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, FunctionConstantValues, "alloc")
}
@(objc_type=FunctionConstantValues, objc_name="init")
FunctionConstantValues_init :: #force_inline proc(self: ^FunctionConstantValues) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "init")
}
@(objc_type=FunctionConstantValues, objc_name="reset")
FunctionConstantValues_reset :: #force_inline proc(self: ^FunctionConstantValues) {
	msgSend(nil, self, "reset")
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValueAtIndex")
FunctionConstantValues_setConstantValueAtIndex :: #force_inline proc(self: ^FunctionConstantValues, value: rawptr, type: DataType, index: NS.UInteger) {
	msgSend(nil, self, "setConstantValue:type:atIndex:", value, type, index)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValueWithName")
FunctionConstantValues_setConstantValueWithName :: #force_inline proc(self: ^FunctionConstantValues, value: rawptr, type: DataType, name: ^NS.String) {
	msgSend(nil, self, "setConstantValue:type:withName:", value, type, name)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValues")
FunctionConstantValues_setConstantValues :: #force_inline proc(self: ^FunctionConstantValues, values: rawptr, type: DataType, range: NS.Range) {
	msgSend(nil, self, "setConstantValues:type:withRange:", values, type, range)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionDescriptor
Class Methods:
	alloc
	functionDescriptor
Methods:
	init
	constantValues
	name
	options
	setConstantValues
	setName
	setOptions
	setSpecializedName
	specializedName
*/
@(objc_class="MTLFunctionDescriptor")
FunctionDescriptor :: struct { using _: NS.Copying(FunctionDescriptor) }

@(objc_type=FunctionDescriptor, objc_class_name="alloc")
FunctionDescriptor_alloc :: #force_inline proc() -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "alloc")
}
@(objc_type=FunctionDescriptor, objc_name="init")
FunctionDescriptor_init :: #force_inline proc(self: ^FunctionDescriptor) -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, self, "init")
}
@(objc_type=FunctionDescriptor, objc_name="constantValues")
FunctionDescriptor_constantValues :: #force_inline proc(self: ^FunctionDescriptor) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "constantValues")
}
@(objc_type=FunctionDescriptor, objc_class_name="functionDescriptor")
FunctionDescriptor_functionDescriptor :: #force_inline proc() -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "functionDescriptor")
}
@(objc_type=FunctionDescriptor, objc_name="name")
FunctionDescriptor_name :: #force_inline proc(self: ^FunctionDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionDescriptor, objc_name="options")
FunctionDescriptor_options :: #force_inline proc(self: ^FunctionDescriptor) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=FunctionDescriptor, objc_name="setConstantValues")
FunctionDescriptor_setConstantValues :: #force_inline proc(self: ^FunctionDescriptor, constantValues: ^FunctionConstantValues) {
	msgSend(nil, self, "setConstantValues:", constantValues)
}
@(objc_type=FunctionDescriptor, objc_name="setName")
FunctionDescriptor_setName :: #force_inline proc(self: ^FunctionDescriptor, name: ^NS.String) {
	msgSend(nil, self, "setName:", name)
}
@(objc_type=FunctionDescriptor, objc_name="setOptions")
FunctionDescriptor_setOptions :: #force_inline proc(self: ^FunctionDescriptor, options: FunctionOptions) {
	msgSend(nil, self, "setOptions:", options)
}
@(objc_type=FunctionDescriptor, objc_name="setSpecializedName")
FunctionDescriptor_setSpecializedName :: #force_inline proc(self: ^FunctionDescriptor, specializedName: ^NS.String) {
	msgSend(nil, self, "setSpecializedName:", specializedName)
}
@(objc_type=FunctionDescriptor, objc_name="specializedName")
FunctionDescriptor_specializedName :: #force_inline proc(self: ^FunctionDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "specializedName")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IntersectionFunctionDescriptor
Class Methods:
	alloc
Methods:
	init
*/
@(objc_class="MTLIntersectionFunctionDescriptor")
IntersectionFunctionDescriptor :: struct { using _: NS.Copying(IntersectionFunctionDescriptor) }

@(objc_type=IntersectionFunctionDescriptor, objc_class_name="alloc")
IntersectionFunctionDescriptor_alloc :: #force_inline proc() -> ^IntersectionFunctionDescriptor {
	return msgSend(^IntersectionFunctionDescriptor, IntersectionFunctionDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionDescriptor, objc_name="init")
IntersectionFunctionDescriptor_init :: #force_inline proc(self: ^IntersectionFunctionDescriptor) -> ^IntersectionFunctionDescriptor {
	return msgSend(^IntersectionFunctionDescriptor, self, "init")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	HeapDescriptor
Class Methods:
	alloc
Methods:
	init
	cpuCacheMode
	hazardTrackingMode
	resourceOptions
	setCpuCacheMode
	setHazardTrackingMode
	setResourceOptions
	setSize
	setStorageMode
	setType
	size
	storageMode
	type
*/
@(objc_class="MTLHeapDescriptor")
HeapDescriptor :: struct { using _: NS.Copying(HeapDescriptor) }

@(objc_type=HeapDescriptor, objc_class_name="alloc")
HeapDescriptor_alloc :: #force_inline proc() -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, HeapDescriptor, "alloc")
}
@(objc_type=HeapDescriptor, objc_name="init")
HeapDescriptor_init :: #force_inline proc(self: ^HeapDescriptor) -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, self, "init")
}
@(objc_type=HeapDescriptor, objc_name="cpuCacheMode")
HeapDescriptor_cpuCacheMode :: #force_inline proc(self: ^HeapDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=HeapDescriptor, objc_name="hazardTrackingMode")
HeapDescriptor_hazardTrackingMode :: #force_inline proc(self: ^HeapDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=HeapDescriptor, objc_name="resourceOptions")
HeapDescriptor_resourceOptions :: #force_inline proc(self: ^HeapDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=HeapDescriptor, objc_name="setCpuCacheMode")
HeapDescriptor_setCpuCacheMode :: #force_inline proc(self: ^HeapDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}
@(objc_type=HeapDescriptor, objc_name="setHazardTrackingMode")
HeapDescriptor_setHazardTrackingMode :: #force_inline proc(self: ^HeapDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=HeapDescriptor, objc_name="setResourceOptions")
HeapDescriptor_setResourceOptions :: #force_inline proc(self: ^HeapDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=HeapDescriptor, objc_name="setSize")
HeapDescriptor_setSize :: #force_inline proc(self: ^HeapDescriptor, size: NS.UInteger) {
	msgSend(nil, self, "setSize:", size)
}
@(objc_type=HeapDescriptor, objc_name="setStorageMode")
HeapDescriptor_setStorageMode :: #force_inline proc(self: ^HeapDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=HeapDescriptor, objc_name="setType")
HeapDescriptor_setType :: #force_inline proc(self: ^HeapDescriptor, type: HeapType) {
	msgSend(nil, self, "setType:", type)
}
@(objc_type=HeapDescriptor, objc_name="size")
HeapDescriptor_size :: #force_inline proc(self: ^HeapDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}
@(objc_type=HeapDescriptor, objc_name="storageMode")
HeapDescriptor_storageMode :: #force_inline proc(self: ^HeapDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=HeapDescriptor, objc_name="type")
HeapDescriptor_type :: #force_inline proc(self: ^HeapDescriptor) -> HeapType {
	return msgSend(HeapType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IndirectCommandBufferDescriptor
Class Methods:
	alloc
Methods:
	init
	commandTypes
	inheritBuffers
	inheritPipelineState
	maxFragmentBufferBindCount
	maxKernelBufferBindCount
	maxVertexBufferBindCount
	setCommandTypes
	setInheritBuffers
	setInheritPipelineState
	setMaxFragmentBufferBindCount
	setMaxKernelBufferBindCount
	setMaxVertexBufferBindCount
*/
@(objc_class="MTLIndirectCommandBufferDescriptor")
IndirectCommandBufferDescriptor :: struct { using _: NS.Copying(IndirectCommandBufferDescriptor) }

@(objc_type=IndirectCommandBufferDescriptor, objc_class_name="alloc")
IndirectCommandBufferDescriptor_alloc :: #force_inline proc() -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, IndirectCommandBufferDescriptor, "alloc")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="init")
IndirectCommandBufferDescriptor_init :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, self, "init")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="commandTypes")
IndirectCommandBufferDescriptor_commandTypes :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> IndirectCommandType {
	return msgSend(IndirectCommandType, self, "commandTypes")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritBuffers")
IndirectCommandBufferDescriptor_inheritBuffers :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritBuffers")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritPipelineState")
IndirectCommandBufferDescriptor_inheritPipelineState :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritPipelineState")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_maxFragmentBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxFragmentBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxKernelBufferBindCount")
IndirectCommandBufferDescriptor_maxKernelBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxKernelBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxVertexBufferBindCount")
IndirectCommandBufferDescriptor_maxVertexBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxVertexBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setCommandTypes")
IndirectCommandBufferDescriptor_setCommandTypes :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, commandTypes: IndirectCommandType) {
	msgSend(nil, self, "setCommandTypes:", commandTypes)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritBuffers")
IndirectCommandBufferDescriptor_setInheritBuffers :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, inheritBuffers: BOOL) {
	msgSend(nil, self, "setInheritBuffers:", inheritBuffers)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritPipelineState")
IndirectCommandBufferDescriptor_setInheritPipelineState :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, inheritPipelineState: BOOL) {
	msgSend(nil, self, "setInheritPipelineState:", inheritPipelineState)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_setMaxFragmentBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, maxFragmentBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxFragmentBufferBindCount:", maxFragmentBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxKernelBufferBindCount")
IndirectCommandBufferDescriptor_setMaxKernelBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, maxKernelBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxKernelBufferBindCount:", maxKernelBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxVertexBufferBindCount")
IndirectCommandBufferDescriptor_setMaxVertexBufferBindCount :: #force_inline proc(self: ^IndirectCommandBufferDescriptor, maxVertexBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxVertexBufferBindCount:", maxVertexBufferBindCount)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	InstanceAccelerationStructureDescriptor
Class Methods:
	alloc
	descriptor
Methods:
	init
	instanceCount
	instanceDescriptorBuffer
	instanceDescriptorBufferOffset
	instanceDescriptorStride
	instancedAccelerationStructures
	setInstanceCount
	setInstanceDescriptorBuffer
	setInstanceDescriptorBufferOffset
	setInstanceDescriptorStride
	setInstancedAccelerationStructures
*/
@(objc_class="MTLInstanceAccelerationStructureDescriptor")
InstanceAccelerationStructureDescriptor :: struct { using _: NS.Copying(InstanceAccelerationStructureDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=InstanceAccelerationStructureDescriptor, objc_class_name="alloc")
InstanceAccelerationStructureDescriptor_alloc :: #force_inline proc() -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "alloc")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="init")
InstanceAccelerationStructureDescriptor_init :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, self, "init")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_class_name="descriptor")
InstanceAccelerationStructureDescriptor_descriptor :: #force_inline proc() -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceCount")
InstanceAccelerationStructureDescriptor_instanceCount :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceCount")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_instanceDescriptorBuffer :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "instanceDescriptorBuffer")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_instanceDescriptorBufferOffset :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceDescriptorBufferOffset")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorStride")
InstanceAccelerationStructureDescriptor_instanceDescriptorStride :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceDescriptorStride")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_instancedAccelerationStructures :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "instancedAccelerationStructures")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceCount")
InstanceAccelerationStructureDescriptor_setInstanceCount :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, instanceCount: NS.UInteger) {
	msgSend(nil, self, "setInstanceCount:", instanceCount)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBuffer :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBuffer: ^Buffer) {
	msgSend(nil, self, "setInstanceDescriptorBuffer:", instanceDescriptorBuffer)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBufferOffset :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setInstanceDescriptorBufferOffset:", instanceDescriptorBufferOffset)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorStride")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorStride :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorStride: NS.UInteger) {
	msgSend(nil, self, "setInstanceDescriptorStride:", instanceDescriptorStride)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_setInstancedAccelerationStructures :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, instancedAccelerationStructures: ^NS.Array) {
	msgSend(nil, self, "setInstancedAccelerationStructures:", instancedAccelerationStructures)
}

@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorType")
InstanceAccelerationStructureDescriptor_instanceDescriptorType :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> AccelerationStructureInstanceDescriptorType {
	return msgSend(AccelerationStructureInstanceDescriptorType, self, "instanceDescriptorType")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorType")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorType :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, buffer: AccelerationStructureInstanceDescriptorType) {
	msgSend(nil, self, "setInstanceDescriptorType:", buffer)
}


@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformBuffer")
InstanceAccelerationStructureDescriptor_motionTransformBuffer :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "motionTransformBuffer")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformBuffer")
InstanceAccelerationStructureDescriptor_setMotionTransformBuffer :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, buffer: ^Buffer) {
	msgSend(nil, self, "setMotionTransformBuffer:", buffer)
}


@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformBufferOffset")
InstanceAccelerationStructureDescriptor_motionTransformBufferOffset :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionTransformBufferOffset")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformBufferOffset")
InstanceAccelerationStructureDescriptor_setMotionTransformBufferOffset :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setMotionTransformBufferOffset:", offset)
}

@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformCount")
InstanceAccelerationStructureDescriptor_motionTransformCount :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionTransformCount")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformCount")
InstanceAccelerationStructureDescriptor_setMotionTransformCount :: #force_inline proc(self: ^InstanceAccelerationStructureDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setMotionTransformCount:", offset)
}



////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IntersectionFunctionTableDescriptor
Class Methods:
	alloc
	intersectionFunctionTableDescriptor
Methods:
	init
	functionCount
	setFunctionCount
*/
@(objc_class="MTLIntersectionFunctionTableDescriptor")
IntersectionFunctionTableDescriptor :: struct { using _: NS.Copying(IntersectionFunctionTableDescriptor) }

@(objc_type=IntersectionFunctionTableDescriptor, objc_class_name="alloc")
IntersectionFunctionTableDescriptor_alloc :: #force_inline proc() -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="init")
IntersectionFunctionTableDescriptor_init :: #force_inline proc(self: ^IntersectionFunctionTableDescriptor) -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, self, "init")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="functionCount")
IntersectionFunctionTableDescriptor_functionCount :: #force_inline proc(self: ^IntersectionFunctionTableDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "functionCount")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_class_name="intersectionFunctionTableDescriptor")
IntersectionFunctionTableDescriptor_intersectionFunctionTableDescriptor :: #force_inline proc() -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "intersectionFunctionTableDescriptor")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="setFunctionCount")
IntersectionFunctionTableDescriptor_setFunctionCount :: #force_inline proc(self: ^IntersectionFunctionTableDescriptor, functionCount: NS.UInteger) {
	msgSend(nil, self, "setFunctionCount:", functionCount)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	LinkedFunctions
Class Methods:
	alloc
	linkedFunctions
Methods:
	init
	binaryFunctions
	functions
	groups
	setBinaryFunctions
	setFunctions
	setGroups
*/
@(objc_class="MTLLinkedFunctions")
LinkedFunctions :: struct { using _: NS.Copying(LinkedFunctions) }

@(objc_type=LinkedFunctions, objc_class_name="alloc")
LinkedFunctions_alloc :: #force_inline proc() -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "alloc")
}
@(objc_type=LinkedFunctions, objc_name="init")
LinkedFunctions_init :: #force_inline proc(self: ^LinkedFunctions) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "init")
}
@(objc_type=LinkedFunctions, objc_name="binaryFunctions")
LinkedFunctions_binaryFunctions :: #force_inline proc(self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryFunctions")
}
@(objc_type=LinkedFunctions, objc_name="functions")
LinkedFunctions_functions :: #force_inline proc(self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functions")
}
@(objc_type=LinkedFunctions, objc_name="groups")
LinkedFunctions_groups :: #force_inline proc(self: ^LinkedFunctions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "groups")
}
@(objc_type=LinkedFunctions, objc_class_name="linkedFunctions")
LinkedFunctions_linkedFunctions :: #force_inline proc() -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "linkedFunctions")
}
@(objc_type=LinkedFunctions, objc_name="setBinaryFunctions")
LinkedFunctions_setBinaryFunctions :: #force_inline proc(self: ^LinkedFunctions, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "setBinaryFunctions:", binaryFunctions)
}
@(objc_type=LinkedFunctions, objc_name="setFunctions")
LinkedFunctions_setFunctions :: #force_inline proc(self: ^LinkedFunctions, functions: ^NS.Array) {
	msgSend(nil, self, "setFunctions:", functions)
}
@(objc_type=LinkedFunctions, objc_name="setGroups")
LinkedFunctions_setGroups :: #force_inline proc(self: ^LinkedFunctions, groups: ^NS.Dictionary) {
	msgSend(nil, self, "setGroups:", groups)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	PipelineBufferDescriptor
Class Methods:
	alloc
Methods:
	init
	mutability
	setMutability
*/
@(objc_class="MTLPipelineBufferDescriptor")
PipelineBufferDescriptor :: struct { using _: NS.Copying(PipelineBufferDescriptor) }

@(objc_type=PipelineBufferDescriptor, objc_class_name="alloc")
PipelineBufferDescriptor_alloc :: #force_inline proc() -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, PipelineBufferDescriptor, "alloc")
}
@(objc_type=PipelineBufferDescriptor, objc_name="init")
PipelineBufferDescriptor_init :: #force_inline proc(self: ^PipelineBufferDescriptor) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "init")
}
@(objc_type=PipelineBufferDescriptor, objc_name="mutability")
PipelineBufferDescriptor_mutability :: #force_inline proc(self: ^PipelineBufferDescriptor) -> Mutability {
	return msgSend(Mutability, self, "mutability")
}
@(objc_type=PipelineBufferDescriptor, objc_name="setMutability")
PipelineBufferDescriptor_setMutability :: #force_inline proc(self: ^PipelineBufferDescriptor, mutability: Mutability) {
	msgSend(nil, self, "setMutability:", mutability)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	PipelineBufferDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLPipelineBufferDescriptorArray")
PipelineBufferDescriptorArray :: struct { using _: NS.Object }

@(objc_type=PipelineBufferDescriptorArray, objc_class_name="alloc")
PipelineBufferDescriptorArray_alloc :: #force_inline proc() -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, PipelineBufferDescriptorArray, "alloc")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="init")
PipelineBufferDescriptorArray_init :: #force_inline proc(self: ^PipelineBufferDescriptorArray) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "init")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="object")
PipelineBufferDescriptorArray_object :: #force_inline proc(self: ^PipelineBufferDescriptorArray, bufferIndex: NS.UInteger) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "objectAtIndexedSubscript:", bufferIndex)
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="setObject")
PipelineBufferDescriptorArray_setObject :: #force_inline proc(self: ^PipelineBufferDescriptorArray, buffer: ^PipelineBufferDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", buffer, bufferIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	PointerType
Class Methods:
	alloc
Methods:
	init
	access
	alignment
	dataSize
	elementArrayType
	elementIsArgumentBuffer
	elementStructType
	elementType
*/
@(objc_class="MTLPointerType")
PointerType :: struct { using _: Type }

@(objc_type=PointerType, objc_class_name="alloc")
PointerType_alloc :: #force_inline proc() -> ^PointerType {
	return msgSend(^PointerType, PointerType, "alloc")
}
@(objc_type=PointerType, objc_name="init")
PointerType_init :: #force_inline proc(self: ^PointerType) -> ^PointerType {
	return msgSend(^PointerType, self, "init")
}
@(objc_type=PointerType, objc_name="access")
PointerType_access :: #force_inline proc(self: ^PointerType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=PointerType, objc_name="alignment")
PointerType_alignment :: #force_inline proc(self: ^PointerType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "alignment")
}
@(objc_type=PointerType, objc_name="dataSize")
PointerType_dataSize :: #force_inline proc(self: ^PointerType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "dataSize")
}
@(objc_type=PointerType, objc_name="elementArrayType")
PointerType_elementArrayType :: #force_inline proc(self: ^PointerType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=PointerType, objc_name="elementIsArgumentBuffer")
PointerType_elementIsArgumentBuffer :: #force_inline proc(self: ^PointerType) -> BOOL {
	return msgSend(BOOL, self, "elementIsArgumentBuffer")
}
@(objc_type=PointerType, objc_name="elementStructType")
PointerType_elementStructType :: #force_inline proc(self: ^PointerType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=PointerType, objc_name="elementType")
PointerType_elementType :: #force_inline proc(self: ^PointerType) -> DataType {
	return msgSend(DataType, self, "elementType")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	PrimitiveAccelerationStructureDescriptor
Class Methods:
	alloc
	descriptor
Methods:
	init
	geometryDescriptors
	setGeometryDescriptors
*/
@(objc_class="MTLPrimitiveAccelerationStructureDescriptor")
PrimitiveAccelerationStructureDescriptor :: struct { using _: NS.Copying(PrimitiveAccelerationStructureDescriptor), using _: AccelerationStructureDescriptor }

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_class_name="alloc")
PrimitiveAccelerationStructureDescriptor_alloc :: #force_inline proc() -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "alloc")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="init")
PrimitiveAccelerationStructureDescriptor_init :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, self, "init")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_class_name="descriptor")
PrimitiveAccelerationStructureDescriptor_descriptor :: #force_inline proc() -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="geometryDescriptors")
PrimitiveAccelerationStructureDescriptor_geometryDescriptors :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "geometryDescriptors")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setGeometryDescriptors")
PrimitiveAccelerationStructureDescriptor_setGeometryDescriptors :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, geometryDescriptors: ^NS.Array) {
	msgSend(nil, self, "setGeometryDescriptors:", geometryDescriptors)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionStartBorderMode")
PrimitiveAccelerationStructureDescriptor_motionStartBorderMode :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionStartBorderMode")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionStartBorderMode")
PrimitiveAccelerationStructureDescriptor_setMotionStartBorderMode :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, motionStartBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionStartBorderMode:", motionStartBorderMode)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionEndBorderMode")
PrimitiveAccelerationStructureDescriptor_motionEndBorderMode :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionEndBorderMode")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionEndBorderMode")
PrimitiveAccelerationStructureDescriptor_setMotionEndBorderMode :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, motionEndBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionEndBorderMode:", motionEndBorderMode)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionStartTime")
PrimitiveAccelerationStructureDescriptor_motionStartTime :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> f32 {
	return msgSend(f32, self, "motionStartTime")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionStartTime")
PrimitiveAccelerationStructureDescriptor_setMotionStartTime :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, motionStartTime: f32) {
	msgSend(nil, self, "setMotionStartTime:", motionStartTime)
}


@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionEndTime")
PrimitiveAccelerationStructureDescriptor_motionEndTime :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> f32 {
	return msgSend(f32, self, "motionEndTime")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionEndTime")
PrimitiveAccelerationStructureDescriptor_setMotionEndTime :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, motionEndTime: f32) {
	msgSend(nil, self, "setMotionEndTime:", motionEndTime)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionKeyframeCount")
PrimitiveAccelerationStructureDescriptor_motionKeyframeCount :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionKeyframeCount")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionKeyframeCount")
PrimitiveAccelerationStructureDescriptor_setMotionKeyframeCount :: #force_inline proc(self: ^PrimitiveAccelerationStructureDescriptor, motionKeyframeCount: NS.UInteger) {
	msgSend(nil, self, "setMotionKeyframeCount:", motionKeyframeCount)
}



////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RasterizationRateLayerArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLRasterizationRateLayerArray")
RasterizationRateLayerArray :: struct { using _: NS.Object }

@(objc_type=RasterizationRateLayerArray, objc_class_name="alloc")
RasterizationRateLayerArray_alloc :: #force_inline proc() -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, RasterizationRateLayerArray, "alloc")
}
@(objc_type=RasterizationRateLayerArray, objc_name="init")
RasterizationRateLayerArray_init :: #force_inline proc(self: ^RasterizationRateLayerArray) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "init")
}
@(objc_type=RasterizationRateLayerArray, objc_name="object")
RasterizationRateLayerArray_object :: #force_inline proc(self: ^RasterizationRateLayerArray, layerIndex: NS.UInteger) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "objectAtIndexedSubscript:", layerIndex)
}
@(objc_type=RasterizationRateLayerArray, objc_name="setObject")
RasterizationRateLayerArray_setObject :: #force_inline proc(self: ^RasterizationRateLayerArray, layer: ^RasterizationRateLayerDescriptor, layerIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", layer, layerIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RasterizationRateLayerDescriptor
Class Methods:
	alloc
Methods:
	horizontal
	horizontalSampleStorage
	init
	initWithSampleCount
	initWithSampleCount
	sampleCount
	vertical
	verticalSampleStorage
*/
@(objc_class="MTLRasterizationRateLayerDescriptor")
RasterizationRateLayerDescriptor :: struct { using _: NS.Copying(RasterizationRateLayerDescriptor) }

@(objc_type=RasterizationRateLayerDescriptor, objc_class_name="alloc")
RasterizationRateLayerDescriptor_alloc :: #force_inline proc() -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, RasterizationRateLayerDescriptor, "alloc")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontal")
RasterizationRateLayerDescriptor_horizontal :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "horizontal")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontalSampleStorage")
RasterizationRateLayerDescriptor_horizontalSampleStorage :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> ^f32 {
	return msgSend(^f32, self, "horizontalSampleStorage")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="init")
RasterizationRateLayerDescriptor_init :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "init")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCount")
RasterizationRateLayerDescriptor_initWithSampleCount :: #force_inline proc(self: ^RasterizationRateLayerDescriptor, sampleCount: Size) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:", sampleCount)
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCountWithDimensions")
RasterizationRateLayerDescriptor_initWithSampleCountWithDimensions :: #force_inline proc(self: ^RasterizationRateLayerDescriptor, sampleCount: Size, horizontal: ^f32, vertical: ^f32) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:horizontal:vertical:", sampleCount, horizontal, vertical)
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="sampleCount")
RasterizationRateLayerDescriptor_sampleCount :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> Size {
	return msgSend(Size, self, "sampleCount")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="vertical")
RasterizationRateLayerDescriptor_vertical :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "vertical")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="verticalSampleStorage")
RasterizationRateLayerDescriptor_verticalSampleStorage :: #force_inline proc(self: ^RasterizationRateLayerDescriptor) -> ^f32 {
	return msgSend(^f32, self, "verticalSampleStorage")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RasterizationRateMapDescriptor
Class Methods:
	alloc
	rasterizationRateMapDescriptorWithScreenSize
	rasterizationRateMapDescriptorWithScreenSize
	rasterizationRateMapDescriptorWithScreenSize
Methods:
	init
	label
	layerAtIndex
	layerCount
	layers
	screenSize
	setLabel
	setLayer
	setScreenSize
*/
@(objc_class="MTLRasterizationRateMapDescriptor")
RasterizationRateMapDescriptor :: struct { using _: NS.Copying(RasterizationRateMapDescriptor) }

@(objc_type=RasterizationRateMapDescriptor, objc_class_name="alloc")
RasterizationRateMapDescriptor_alloc :: #force_inline proc() -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "alloc")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="init")
RasterizationRateMapDescriptor_init :: #force_inline proc(self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, self, "init")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="label")
RasterizationRateMapDescriptor_label :: #force_inline proc(self: ^RasterizationRateMapDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layerAtIndex")
RasterizationRateMapDescriptor_layerAtIndex :: #force_inline proc(self: ^RasterizationRateMapDescriptor, layerIndex: NS.UInteger) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "layerAtIndex:", layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layerCount")
RasterizationRateMapDescriptor_layerCount :: #force_inline proc(self: ^RasterizationRateMapDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "layerCount")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layers")
RasterizationRateMapDescriptor_layers :: #force_inline proc(self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "layers")
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSize")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSize :: #force_inline proc(screenSize: Size) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:", screenSize)
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSizeWithLayer")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSizeWithLayer :: #force_inline proc(screenSize: Size, layer: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layer:", screenSize, layer)
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSizeWithLayers")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSizeWithLayers :: #force_inline proc(screenSize: Size, layerCount: NS.UInteger, layers: [^]^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layerCount:layers:", screenSize, layerCount, layers)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="screenSize")
RasterizationRateMapDescriptor_screenSize :: #force_inline proc(self: ^RasterizationRateMapDescriptor) -> Size {
	return msgSend(Size, self, "screenSize")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLabel")
RasterizationRateMapDescriptor_setLabel :: #force_inline proc(self: ^RasterizationRateMapDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLayer")
RasterizationRateMapDescriptor_setLayer :: #force_inline proc(self: ^RasterizationRateMapDescriptor, layer: ^RasterizationRateLayerDescriptor, layerIndex: NS.UInteger) {
	msgSend(nil, self, "setLayer:atIndex:", layer, layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setScreenSize")
RasterizationRateMapDescriptor_setScreenSize :: #force_inline proc(self: ^RasterizationRateMapDescriptor, screenSize: Size) {
	msgSend(nil, self, "setScreenSize:", screenSize)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RasterizationRateSampleArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLRasterizationRateSampleArray")
RasterizationRateSampleArray :: struct { using _: NS.Object }

@(objc_type=RasterizationRateSampleArray, objc_class_name="alloc")
RasterizationRateSampleArray_alloc :: #force_inline proc() -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, RasterizationRateSampleArray, "alloc")
}
@(objc_type=RasterizationRateSampleArray, objc_name="init")
RasterizationRateSampleArray_init :: #force_inline proc(self: ^RasterizationRateSampleArray) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "init")
}
@(objc_type=RasterizationRateSampleArray, objc_name="object")
RasterizationRateSampleArray_object :: #force_inline proc(self: ^RasterizationRateSampleArray, index: NS.UInteger) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=RasterizationRateSampleArray, objc_name="setObject")
RasterizationRateSampleArray_setObject :: #force_inline proc(self: ^RasterizationRateSampleArray, value: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", value, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	depthPlane
	level
	loadAction
	resolveDepthPlane
	resolveLevel
	resolveSlice
	resolveTexture
	setDepthPlane
	setLevel
	setLoadAction
	setResolveDepthPlane
	setResolveLevel
	setResolveSlice
	setResolveTexture
	setSlice
	setStoreAction
	setStoreActionOptions
	setTexture
	slice
	storeAction
	storeActionOptions
	texture
*/
@(objc_class="MTLRenderPassAttachmentDescriptor")
RenderPassAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassAttachmentDescriptor) }

@(objc_type=RenderPassAttachmentDescriptor, objc_class_name="alloc")
RenderPassAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, RenderPassAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="init")
RenderPassAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="depthPlane")
RenderPassAttachmentDescriptor_depthPlane :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="level")
RenderPassAttachmentDescriptor_level :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "level")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="loadAction")
RenderPassAttachmentDescriptor_loadAction :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> LoadAction {
	return msgSend(LoadAction, self, "loadAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveDepthPlane")
RenderPassAttachmentDescriptor_resolveDepthPlane :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveDepthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveLevel")
RenderPassAttachmentDescriptor_resolveLevel :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveLevel")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveSlice")
RenderPassAttachmentDescriptor_resolveSlice :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveSlice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveTexture")
RenderPassAttachmentDescriptor_resolveTexture :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "resolveTexture")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setDepthPlane")
RenderPassAttachmentDescriptor_setDepthPlane :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, depthPlane: NS.UInteger) {
	msgSend(nil, self, "setDepthPlane:", depthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLevel")
RenderPassAttachmentDescriptor_setLevel :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, level: NS.UInteger) {
	msgSend(nil, self, "setLevel:", level)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLoadAction")
RenderPassAttachmentDescriptor_setLoadAction :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, loadAction: LoadAction) {
	msgSend(nil, self, "setLoadAction:", loadAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveDepthPlane")
RenderPassAttachmentDescriptor_setResolveDepthPlane :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, resolveDepthPlane: NS.UInteger) {
	msgSend(nil, self, "setResolveDepthPlane:", resolveDepthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveLevel")
RenderPassAttachmentDescriptor_setResolveLevel :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, resolveLevel: NS.UInteger) {
	msgSend(nil, self, "setResolveLevel:", resolveLevel)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveSlice")
RenderPassAttachmentDescriptor_setResolveSlice :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, resolveSlice: NS.UInteger) {
	msgSend(nil, self, "setResolveSlice:", resolveSlice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveTexture")
RenderPassAttachmentDescriptor_setResolveTexture :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, resolveTexture: ^Texture) {
	msgSend(nil, self, "setResolveTexture:", resolveTexture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setSlice")
RenderPassAttachmentDescriptor_setSlice :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, slice: NS.UInteger) {
	msgSend(nil, self, "setSlice:", slice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreAction")
RenderPassAttachmentDescriptor_setStoreAction :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, storeAction: StoreAction) {
	msgSend(nil, self, "setStoreAction:", storeAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreActionOptions")
RenderPassAttachmentDescriptor_setStoreActionOptions :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setTexture")
RenderPassAttachmentDescriptor_setTexture :: #force_inline proc(self: ^RenderPassAttachmentDescriptor, texture: ^Texture) {
	msgSend(nil, self, "setTexture:", texture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="slice")
RenderPassAttachmentDescriptor_slice :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "slice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeAction")
RenderPassAttachmentDescriptor_storeAction :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> StoreAction {
	return msgSend(StoreAction, self, "storeAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeActionOptions")
RenderPassAttachmentDescriptor_storeActionOptions :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> StoreActionOptions {
	return msgSend(StoreActionOptions, self, "storeActionOptions")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="texture")
RenderPassAttachmentDescriptor_texture :: #force_inline proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "texture")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassColorAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	clearColor
	setClearColor
*/
@(objc_class="MTLRenderPassColorAttachmentDescriptor")
RenderPassColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassColorAttachmentDescriptor), using _: RenderPassAttachmentDescriptor  }

@(objc_type=RenderPassColorAttachmentDescriptor, objc_class_name="alloc")
RenderPassColorAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, RenderPassColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="init")
RenderPassColorAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptor) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="clearColor")
RenderPassColorAttachmentDescriptor_clearColor :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptor) -> ClearColor {
	return msgSend(ClearColor, self, "clearColor")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="setClearColor")
RenderPassColorAttachmentDescriptor_setClearColor :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptor, clearColor: ClearColor) {
	msgSend(nil, self, "setClearColor:", clearColor)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassColorAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLRenderPassColorAttachmentDescriptorArray")
RenderPassColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_class_name="alloc")
RenderPassColorAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, RenderPassColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="init")
RenderPassColorAttachmentDescriptorArray_init :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptorArray) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="object")
RenderPassColorAttachmentDescriptorArray_object :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="setObject")
RenderPassColorAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^RenderPassColorAttachmentDescriptorArray, attachment: ^RenderPassColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassDepthAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	clearDepth
	depthResolveFilter
	setClearDepth
	setDepthResolveFilter
*/
@(objc_class="MTLRenderPassDepthAttachmentDescriptor")
RenderPassDepthAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassDepthAttachmentDescriptor), using _: RenderPassAttachmentDescriptor }

@(objc_type=RenderPassDepthAttachmentDescriptor, objc_class_name="alloc")
RenderPassDepthAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, RenderPassDepthAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="init")
RenderPassDepthAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPassDepthAttachmentDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="clearDepth")
RenderPassDepthAttachmentDescriptor_clearDepth :: #force_inline proc(self: ^RenderPassDepthAttachmentDescriptor) -> f64 {
	return msgSend(f64, self, "clearDepth")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="depthResolveFilter")
RenderPassDepthAttachmentDescriptor_depthResolveFilter :: #force_inline proc(self: ^RenderPassDepthAttachmentDescriptor) -> MultisampleDepthResolveFilter {
	return msgSend(MultisampleDepthResolveFilter, self, "depthResolveFilter")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setClearDepth")
RenderPassDepthAttachmentDescriptor_setClearDepth :: #force_inline proc(self: ^RenderPassDepthAttachmentDescriptor, clearDepth: f64) {
	msgSend(nil, self, "setClearDepth:", clearDepth)
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setDepthResolveFilter")
RenderPassDepthAttachmentDescriptor_setDepthResolveFilter :: #force_inline proc(self: ^RenderPassDepthAttachmentDescriptor, depthResolveFilter: MultisampleDepthResolveFilter) {
	msgSend(nil, self, "setDepthResolveFilter:", depthResolveFilter)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassDescriptor
Class Methods:
	alloc
	renderPassDescriptor
Methods:
	init
	colorAttachments
	defaultRasterSampleCount
	depthAttachment
	getSamplePositions
	imageblockSampleLength
	rasterizationRateMap
	renderTargetArrayLength
	renderTargetHeight
	renderTargetWidth
	sampleBufferAttachments
	setDefaultRasterSampleCount
	setDepthAttachment
	setImageblockSampleLength
	setRasterizationRateMap
	setRenderTargetArrayLength
	setRenderTargetHeight
	setRenderTargetWidth
	setSamplePositions
	setStencilAttachment
	setThreadgroupMemoryLength
	setTileHeight
	setTileWidth
	setVisibilityResultBuffer
	stencilAttachment
	threadgroupMemoryLength
	tileHeight
	tileWidth
	visibilityResultBuffer
*/
@(objc_class="MTLRenderPassDescriptor")
RenderPassDescriptor :: struct { using _: NS.Copying(RenderPassDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=RenderPassDescriptor, objc_class_name="alloc")
RenderPassDescriptor_alloc :: #force_inline proc() -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "alloc")
}
@(objc_type=RenderPassDescriptor, objc_name="init")
RenderPassDescriptor_init :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "init")
}
@(objc_type=RenderPassDescriptor, objc_name="colorAttachments")
RenderPassDescriptor_colorAttachments :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="defaultRasterSampleCount")
RenderPassDescriptor_defaultRasterSampleCount :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "defaultRasterSampleCount")
}
@(objc_type=RenderPassDescriptor, objc_name="depthAttachment")
RenderPassDescriptor_depthAttachment :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "depthAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="getSamplePositions")
RenderPassDescriptor_getSamplePositions :: #force_inline proc(self: ^RenderPassDescriptor, positions: ^SamplePosition, count: NS.UInteger) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "getSamplePositions:count:", positions, count)
}
@(objc_type=RenderPassDescriptor, objc_name="imageblockSampleLength")
RenderPassDescriptor_imageblockSampleLength :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "imageblockSampleLength")
}
@(objc_type=RenderPassDescriptor, objc_name="rasterizationRateMap")
RenderPassDescriptor_rasterizationRateMap :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "rasterizationRateMap")
}
@(objc_type=RenderPassDescriptor, objc_class_name="renderPassDescriptor")
RenderPassDescriptor_renderPassDescriptor :: #force_inline proc() -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "renderPassDescriptor")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetArrayLength")
RenderPassDescriptor_renderTargetArrayLength :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetArrayLength")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetHeight")
RenderPassDescriptor_renderTargetHeight :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetWidth")
RenderPassDescriptor_renderTargetWidth :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="sampleBufferAttachments")
RenderPassDescriptor_sampleBufferAttachments :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="setDefaultRasterSampleCount")
RenderPassDescriptor_setDefaultRasterSampleCount :: #force_inline proc(self: ^RenderPassDescriptor, defaultRasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setDefaultRasterSampleCount:", defaultRasterSampleCount)
}
@(objc_type=RenderPassDescriptor, objc_name="setDepthAttachment")
RenderPassDescriptor_setDepthAttachment :: #force_inline proc(self: ^RenderPassDescriptor, depthAttachment: ^RenderPassDepthAttachmentDescriptor) {
	msgSend(nil, self, "setDepthAttachment:", depthAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setImageblockSampleLength")
RenderPassDescriptor_setImageblockSampleLength :: #force_inline proc(self: ^RenderPassDescriptor, imageblockSampleLength: NS.UInteger) {
	msgSend(nil, self, "setImageblockSampleLength:", imageblockSampleLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRasterizationRateMap")
RenderPassDescriptor_setRasterizationRateMap :: #force_inline proc(self: ^RenderPassDescriptor, rasterizationRateMap: ^RasterizationRateMap) {
	msgSend(nil, self, "setRasterizationRateMap:", rasterizationRateMap)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetArrayLength")
RenderPassDescriptor_setRenderTargetArrayLength :: #force_inline proc(self: ^RenderPassDescriptor, renderTargetArrayLength: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetArrayLength:", renderTargetArrayLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetHeight")
RenderPassDescriptor_setRenderTargetHeight :: #force_inline proc(self: ^RenderPassDescriptor, renderTargetHeight: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetHeight:", renderTargetHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetWidth")
RenderPassDescriptor_setRenderTargetWidth :: #force_inline proc(self: ^RenderPassDescriptor, renderTargetWidth: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetWidth:", renderTargetWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setSamplePositions")
RenderPassDescriptor_setSamplePositions :: #force_inline proc(self: ^RenderPassDescriptor, positions: ^SamplePosition, count: NS.UInteger) {
	msgSend(nil, self, "setSamplePositions:count:", positions, count)
}
@(objc_type=RenderPassDescriptor, objc_name="setStencilAttachment")
RenderPassDescriptor_setStencilAttachment :: #force_inline proc(self: ^RenderPassDescriptor, stencilAttachment: ^RenderPassStencilAttachmentDescriptor) {
	msgSend(nil, self, "setStencilAttachment:", stencilAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setThreadgroupMemoryLength")
RenderPassDescriptor_setThreadgroupMemoryLength :: #force_inline proc(self: ^RenderPassDescriptor, threadgroupMemoryLength: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:", threadgroupMemoryLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileHeight")
RenderPassDescriptor_setTileHeight :: #force_inline proc(self: ^RenderPassDescriptor, tileHeight: NS.UInteger) {
	msgSend(nil, self, "setTileHeight:", tileHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileWidth")
RenderPassDescriptor_setTileWidth :: #force_inline proc(self: ^RenderPassDescriptor, tileWidth: NS.UInteger) {
	msgSend(nil, self, "setTileWidth:", tileWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setVisibilityResultBuffer")
RenderPassDescriptor_setVisibilityResultBuffer :: #force_inline proc(self: ^RenderPassDescriptor, visibilityResultBuffer: ^Buffer) {
	msgSend(nil, self, "setVisibilityResultBuffer:", visibilityResultBuffer)
}
@(objc_type=RenderPassDescriptor, objc_name="stencilAttachment")
RenderPassDescriptor_stencilAttachment :: #force_inline proc(self: ^RenderPassDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "stencilAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="threadgroupMemoryLength")
RenderPassDescriptor_threadgroupMemoryLength :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryLength")
}
@(objc_type=RenderPassDescriptor, objc_name="tileHeight")
RenderPassDescriptor_tileHeight :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="tileWidth")
RenderPassDescriptor_tileWidth :: #force_inline proc(self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="visibilityResultBuffer")
RenderPassDescriptor_visibilityResultBuffer :: #force_inline proc(self: ^RenderPassDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "visibilityResultBuffer")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassSampleBufferAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	endOfFragmentSampleIndex
	endOfVertexSampleIndex
	sampleBuffer
	setEndOfFragmentSampleIndex
	setEndOfVertexSampleIndex
	setSampleBuffer
	setStartOfFragmentSampleIndex
	setStartOfVertexSampleIndex
	startOfFragmentSampleIndex
	startOfVertexSampleIndex
*/
@(objc_class="MTLRenderPassSampleBufferAttachmentDescriptor")
RenderPassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassSampleBufferAttachmentDescriptor) }

@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_class_name="alloc")
RenderPassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, RenderPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="init")
RenderPassSampleBufferAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfFragmentSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfVertexSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfVertexSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "sampleBuffer")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfFragmentSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor, endOfFragmentSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfFragmentSampleIndex:", endOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfVertexSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor, endOfVertexSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfVertexSampleIndex:", endOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor, sampleBuffer: ^Buffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfFragmentSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor, startOfFragmentSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfFragmentSampleIndex:", startOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfVertexSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor, startOfVertexSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfVertexSampleIndex:", startOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfFragmentSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfVertexSampleIndex :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfVertexSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassSampleBufferAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLRenderPassSampleBufferAttachmentDescriptorArray")
RenderPassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_class_name="alloc")
RenderPassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, RenderPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="init")
RenderPassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="object")
RenderPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
RenderPassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachment: ^RenderPassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPassStencilAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	clearStencil
	setClearStencil
	setStencilResolveFilter
	stencilResolveFilter
*/
@(objc_class="MTLRenderPassStencilAttachmentDescriptor")
RenderPassStencilAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassStencilAttachmentDescriptor) }

@(objc_type=RenderPassStencilAttachmentDescriptor, objc_class_name="alloc")
RenderPassStencilAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, RenderPassStencilAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="init")
RenderPassStencilAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPassStencilAttachmentDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="clearStencil")
RenderPassStencilAttachmentDescriptor_clearStencil :: #force_inline proc(self: ^RenderPassStencilAttachmentDescriptor) -> u32 {
	return msgSend(u32, self, "clearStencil")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setClearStencil")
RenderPassStencilAttachmentDescriptor_setClearStencil :: #force_inline proc(self: ^RenderPassStencilAttachmentDescriptor, clearStencil: u32) {
	msgSend(nil, self, "setClearStencil:", clearStencil)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setStencilResolveFilter")
RenderPassStencilAttachmentDescriptor_setStencilResolveFilter :: #force_inline proc(self: ^RenderPassStencilAttachmentDescriptor, stencilResolveFilter: MultisampleStencilResolveFilter) {
	msgSend(nil, self, "setStencilResolveFilter:", stencilResolveFilter)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="stencilResolveFilter")
RenderPassStencilAttachmentDescriptor_stencilResolveFilter :: #force_inline proc(self: ^RenderPassStencilAttachmentDescriptor) -> MultisampleStencilResolveFilter {
	return msgSend(MultisampleStencilResolveFilter, self, "stencilResolveFilter")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPipelineColorAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	alphaBlendOperation
	destinationAlphaBlendFactor
	destinationRGBBlendFactor
	isBlendingEnabled
	pixelFormat
	rgbBlendOperation
	setAlphaBlendOperation
	setBlendingEnabled
	setDestinationAlphaBlendFactor
	setDestinationRGBBlendFactor
	setPixelFormat
	setRgbBlendOperation
	setSourceAlphaBlendFactor
	setSourceRGBBlendFactor
	setWriteMask
	sourceAlphaBlendFactor
	sourceRGBBlendFactor
	writeMask
*/
@(objc_class="MTLRenderPipelineColorAttachmentDescriptor")
RenderPipelineColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPipelineColorAttachmentDescriptor), using _: RenderPassAttachmentDescriptor }

@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_class_name="alloc")
RenderPipelineColorAttachmentDescriptor_alloc :: #force_inline proc() -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, RenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="init")
RenderPipelineColorAttachmentDescriptor_init :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="alphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_alphaBlendOperation :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "alphaBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationAlphaBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationRGBBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="isBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_isBlendingEnabled :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isBlendingEnabled")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
RenderPipelineColorAttachmentDescriptor_pixelFormat :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="rgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_rgbBlendOperation :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "rgbBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setAlphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_setAlphaBlendOperation :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, alphaBlendOperation: BlendOperation) {
	msgSend(nil, self, "setAlphaBlendOperation:", alphaBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_setBlendingEnabled :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, blendingEnabled: BOOL) {
	msgSend(nil, self, "setBlendingEnabled:", blendingEnabled)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationAlphaBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, destinationAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationAlphaBlendFactor:", destinationAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationRGBBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, destinationRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationRGBBlendFactor:", destinationRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
RenderPipelineColorAttachmentDescriptor_setPixelFormat :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setRgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_setRgbBlendOperation :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, rgbBlendOperation: BlendOperation) {
	msgSend(nil, self, "setRgbBlendOperation:", rgbBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceAlphaBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, sourceAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceAlphaBlendFactor:", sourceAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceRGBBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, sourceRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceRGBBlendFactor:", sourceRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setWriteMask")
RenderPipelineColorAttachmentDescriptor_setWriteMask :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor, writeMask: ColorWriteMask) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceAlphaBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceRGBBlendFactor :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="writeMask")
RenderPipelineColorAttachmentDescriptor_writeMask :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptor) -> ColorWriteMask {
	return msgSend(ColorWriteMask, self, "writeMask")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPipelineColorAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLRenderPipelineColorAttachmentDescriptorArray")
RenderPipelineColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_class_name="alloc")
RenderPipelineColorAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, RenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="init")
RenderPipelineColorAttachmentDescriptorArray_init :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptorArray) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="object")
RenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
RenderPipelineColorAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^RenderPipelineColorAttachmentDescriptorArray, attachment: ^RenderPipelineColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPipelineDescriptor
Class Methods:
	alloc
Methods:
	init
	binaryArchives
	colorAttachments
	depthAttachmentPixelFormat
	fragmentBuffers
	fragmentFunction
	inputPrimitiveTopology
	isAlphaToCoverageEnabled
	isAlphaToOneEnabled
	isRasterizationEnabled
	isTessellationFactorScaleEnabled
	label
	maxTessellationFactor
	maxVertexAmplificationCount
	rasterSampleCount
	reset
	sampleCount
	setAlphaToCoverageEnabled
	setAlphaToOneEnabled
	setBinaryArchives
	setDepthAttachmentPixelFormat
	setFragmentFunction
	setInputPrimitiveTopology
	setLabel
	setMaxTessellationFactor
	setMaxVertexAmplificationCount
	setRasterSampleCount
	setRasterizationEnabled
	setSampleCount
	setStencilAttachmentPixelFormat
	setSupportIndirectCommandBuffers
	setTessellationControlPointIndexType
	setTessellationFactorFormat
	setTessellationFactorScaleEnabled
	setTessellationFactorStepFunction
	setTessellationOutputWindingOrder
	setTessellationPartitionMode
	setVertexDescriptor
	setVertexFunction
	stencilAttachmentPixelFormat
	supportIndirectCommandBuffers
	tessellationControlPointIndexType
	tessellationFactorFormat
	tessellationFactorStepFunction
	tessellationOutputWindingOrder
	tessellationPartitionMode
	vertexBuffers
	vertexDescriptor
	vertexFunction
*/
@(objc_class="MTLRenderPipelineDescriptor")
RenderPipelineDescriptor :: struct { using _: NS.Copying(RenderPipelineDescriptor) }

@(objc_type=RenderPipelineDescriptor, objc_class_name="alloc")
RenderPipelineDescriptor_alloc :: #force_inline proc() -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, RenderPipelineDescriptor, "alloc")
}
@(objc_type=RenderPipelineDescriptor, objc_name="init")
RenderPipelineDescriptor_init :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "init")
}
@(objc_type=RenderPipelineDescriptor, objc_name="binaryArchives")
RenderPipelineDescriptor_binaryArchives :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=RenderPipelineDescriptor, objc_name="colorAttachments")
RenderPipelineDescriptor_colorAttachments :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPipelineDescriptor, objc_name="depthAttachmentPixelFormat")
RenderPipelineDescriptor_depthAttachmentPixelFormat :: #force_inline proc(self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "depthAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentBuffers")
RenderPipelineDescriptor_fragmentBuffers :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "fragmentBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentFunction")
RenderPipelineDescriptor_fragmentFunction :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "fragmentFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="inputPrimitiveTopology")
RenderPipelineDescriptor_inputPrimitiveTopology :: #force_inline proc(self: ^RenderPipelineDescriptor) -> PrimitiveTopologyClass {
	return msgSend(PrimitiveTopologyClass, self, "inputPrimitiveTopology")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToCoverageEnabled")
RenderPipelineDescriptor_isAlphaToCoverageEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToCoverageEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToOneEnabled")
RenderPipelineDescriptor_isAlphaToOneEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToOneEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isRasterizationEnabled")
RenderPipelineDescriptor_isRasterizationEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isRasterizationEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isTessellationFactorScaleEnabled")
RenderPipelineDescriptor_isTessellationFactorScaleEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isTessellationFactorScaleEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="label")
RenderPipelineDescriptor_label :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxTessellationFactor")
RenderPipelineDescriptor_maxTessellationFactor :: #force_inline proc(self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTessellationFactor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxVertexAmplificationCount")
RenderPipelineDescriptor_maxVertexAmplificationCount :: #force_inline proc(self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxVertexAmplificationCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="rasterSampleCount")
RenderPipelineDescriptor_rasterSampleCount :: #force_inline proc(self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "rasterSampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="reset")
RenderPipelineDescriptor_reset :: #force_inline proc(self: ^RenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=RenderPipelineDescriptor, objc_name="sampleCount")
RenderPipelineDescriptor_sampleCount :: #force_inline proc(self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToCoverageEnabled")
RenderPipelineDescriptor_setAlphaToCoverageEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor, alphaToCoverageEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToCoverageEnabled:", alphaToCoverageEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToOneEnabled")
RenderPipelineDescriptor_setAlphaToOneEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor, alphaToOneEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToOneEnabled:", alphaToOneEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setBinaryArchives")
RenderPipelineDescriptor_setBinaryArchives :: #force_inline proc(self: ^RenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setDepthAttachmentPixelFormat")
RenderPipelineDescriptor_setDepthAttachmentPixelFormat :: #force_inline proc(self: ^RenderPipelineDescriptor, depthAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setDepthAttachmentPixelFormat:", depthAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setFragmentFunction")
RenderPipelineDescriptor_setFragmentFunction :: #force_inline proc(self: ^RenderPipelineDescriptor, fragmentFunction: ^Function) {
	msgSend(nil, self, "setFragmentFunction:", fragmentFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setInputPrimitiveTopology")
RenderPipelineDescriptor_setInputPrimitiveTopology :: #force_inline proc(self: ^RenderPipelineDescriptor, inputPrimitiveTopology: PrimitiveTopologyClass) {
	msgSend(nil, self, "setInputPrimitiveTopology:", inputPrimitiveTopology)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setLabel")
RenderPipelineDescriptor_setLabel :: #force_inline proc(self: ^RenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTessellationFactor")
RenderPipelineDescriptor_setMaxTessellationFactor :: #force_inline proc(self: ^RenderPipelineDescriptor, maxTessellationFactor: NS.UInteger) {
	msgSend(nil, self, "setMaxTessellationFactor:", maxTessellationFactor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxVertexAmplificationCount")
RenderPipelineDescriptor_setMaxVertexAmplificationCount :: #force_inline proc(self: ^RenderPipelineDescriptor, maxVertexAmplificationCount: NS.UInteger) {
	msgSend(nil, self, "setMaxVertexAmplificationCount:", maxVertexAmplificationCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterSampleCount")
RenderPipelineDescriptor_setRasterSampleCount :: #force_inline proc(self: ^RenderPipelineDescriptor, rasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterizationEnabled")
RenderPipelineDescriptor_setRasterizationEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor, rasterizationEnabled: BOOL) {
	msgSend(nil, self, "setRasterizationEnabled:", rasterizationEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSampleCount")
RenderPipelineDescriptor_setSampleCount :: #force_inline proc(self: ^RenderPipelineDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setStencilAttachmentPixelFormat")
RenderPipelineDescriptor_setStencilAttachmentPixelFormat :: #force_inline proc(self: ^RenderPipelineDescriptor, stencilAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setStencilAttachmentPixelFormat:", stencilAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
RenderPipelineDescriptor_setSupportIndirectCommandBuffers :: #force_inline proc(self: ^RenderPipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationControlPointIndexType")
RenderPipelineDescriptor_setTessellationControlPointIndexType :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationControlPointIndexType: TessellationControlPointIndexType) {
	msgSend(nil, self, "setTessellationControlPointIndexType:", tessellationControlPointIndexType)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorFormat")
RenderPipelineDescriptor_setTessellationFactorFormat :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationFactorFormat: TessellationFactorFormat) {
	msgSend(nil, self, "setTessellationFactorFormat:", tessellationFactorFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorScaleEnabled")
RenderPipelineDescriptor_setTessellationFactorScaleEnabled :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationFactorScaleEnabled: BOOL) {
	msgSend(nil, self, "setTessellationFactorScaleEnabled:", tessellationFactorScaleEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorStepFunction")
RenderPipelineDescriptor_setTessellationFactorStepFunction :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationFactorStepFunction: TessellationFactorStepFunction) {
	msgSend(nil, self, "setTessellationFactorStepFunction:", tessellationFactorStepFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationOutputWindingOrder")
RenderPipelineDescriptor_setTessellationOutputWindingOrder :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationOutputWindingOrder: Winding) {
	msgSend(nil, self, "setTessellationOutputWindingOrder:", tessellationOutputWindingOrder)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationPartitionMode")
RenderPipelineDescriptor_setTessellationPartitionMode :: #force_inline proc(self: ^RenderPipelineDescriptor, tessellationPartitionMode: TessellationPartitionMode) {
	msgSend(nil, self, "setTessellationPartitionMode:", tessellationPartitionMode)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexDescriptor")
RenderPipelineDescriptor_setVertexDescriptor :: #force_inline proc(self: ^RenderPipelineDescriptor, vertexDescriptor: ^VertexDescriptor) {
	msgSend(nil, self, "setVertexDescriptor:", vertexDescriptor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexFunction")
RenderPipelineDescriptor_setVertexFunction :: #force_inline proc(self: ^RenderPipelineDescriptor, vertexFunction: ^Function) {
	msgSend(nil, self, "setVertexFunction:", vertexFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="stencilAttachmentPixelFormat")
RenderPipelineDescriptor_stencilAttachmentPixelFormat :: #force_inline proc(self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "stencilAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="supportIndirectCommandBuffers")
RenderPipelineDescriptor_supportIndirectCommandBuffers :: #force_inline proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationControlPointIndexType")
RenderPipelineDescriptor_tessellationControlPointIndexType :: #force_inline proc(self: ^RenderPipelineDescriptor) -> TessellationControlPointIndexType {
	return msgSend(TessellationControlPointIndexType, self, "tessellationControlPointIndexType")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorFormat")
RenderPipelineDescriptor_tessellationFactorFormat :: #force_inline proc(self: ^RenderPipelineDescriptor) -> TessellationFactorFormat {
	return msgSend(TessellationFactorFormat, self, "tessellationFactorFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorStepFunction")
RenderPipelineDescriptor_tessellationFactorStepFunction :: #force_inline proc(self: ^RenderPipelineDescriptor) -> TessellationFactorStepFunction {
	return msgSend(TessellationFactorStepFunction, self, "tessellationFactorStepFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationOutputWindingOrder")
RenderPipelineDescriptor_tessellationOutputWindingOrder :: #force_inline proc(self: ^RenderPipelineDescriptor) -> Winding {
	return msgSend(Winding, self, "tessellationOutputWindingOrder")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationPartitionMode")
RenderPipelineDescriptor_tessellationPartitionMode :: #force_inline proc(self: ^RenderPipelineDescriptor) -> TessellationPartitionMode {
	return msgSend(TessellationPartitionMode, self, "tessellationPartitionMode")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexBuffers")
RenderPipelineDescriptor_vertexBuffers :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "vertexBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexDescriptor")
RenderPipelineDescriptor_vertexDescriptor :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "vertexDescriptor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexFunction")
RenderPipelineDescriptor_vertexFunction :: #force_inline proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "vertexFunction")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPipelineReflection
Class Methods:
	alloc
Methods:
	init
	fragmentArguments
	tileArguments
	vertexArguments
*/
@(objc_class="MTLRenderPipelineReflection")
RenderPipelineReflection :: struct { using _: NS.Object }

@(objc_type=RenderPipelineReflection, objc_class_name="alloc")
RenderPipelineReflection_alloc :: #force_inline proc() -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, RenderPipelineReflection, "alloc")
}
@(objc_type=RenderPipelineReflection, objc_name="init")
RenderPipelineReflection_init :: #force_inline proc(self: ^RenderPipelineReflection) -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, self, "init")
}
@(objc_type=RenderPipelineReflection, objc_name="fragmentArguments")
RenderPipelineReflection_fragmentArguments :: #force_inline proc(self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "fragmentArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="tileArguments")
RenderPipelineReflection_tileArguments :: #force_inline proc(self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "tileArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="vertexArguments")
RenderPipelineReflection_vertexArguments :: #force_inline proc(self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexArguments")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ResourceStatePassDescriptor
Class Methods:
	alloc
	resourceStatePassDescriptor
Methods:
	init
	sampleBufferAttachments
*/
@(objc_class="MTLResourceStatePassDescriptor")
ResourceStatePassDescriptor :: struct { using _: NS.Copying(ResourceStatePassDescriptor) }

@(objc_type=ResourceStatePassDescriptor, objc_class_name="alloc")
ResourceStatePassDescriptor_alloc :: #force_inline proc() -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "alloc")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="init")
ResourceStatePassDescriptor_init :: #force_inline proc(self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, self, "init")
}
@(objc_type=ResourceStatePassDescriptor, objc_class_name="resourceStatePassDescriptor")
ResourceStatePassDescriptor_resourceStatePassDescriptor :: #force_inline proc() -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "resourceStatePassDescriptor")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="sampleBufferAttachments")
ResourceStatePassDescriptor_sampleBufferAttachments :: #force_inline proc(self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ResourceStatePassSampleBufferAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	endOfEncoderSampleIndex
	sampleBuffer
	setEndOfEncoderSampleIndex
	setSampleBuffer
	setStartOfEncoderSampleIndex
	startOfEncoderSampleIndex
*/
@(objc_class="MTLResourceStatePassSampleBufferAttachmentDescriptor")
ResourceStatePassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(ResourceStatePassSampleBufferAttachmentDescriptor) }

@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_class_name="alloc")
ResourceStatePassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc() -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, ResourceStatePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptor_init :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "sampleBuffer")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, sampleBuffer: ^Buffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ResourceStatePassSampleBufferAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLResourceStatePassSampleBufferAttachmentDescriptorArray")
ResourceStatePassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_class_name="alloc")
ResourceStatePassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, ResourceStatePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ResourceStatePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ResourceStatePassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachment: ^ResourceStatePassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SamplerDescriptor
Class Methods:
	alloc
Methods:
	init
	borderColor
	compareFunction
	label
	lodAverage
	lodMaxClamp
	lodMinClamp
	magFilter
	maxAnisotropy
	minFilter
	mipFilter
	normalizedCoordinates
	rAddressMode
	sAddressMode
	setBorderColor
	setCompareFunction
	setLabel
	setLodAverage
	setLodMaxClamp
	setLodMinClamp
	setMagFilter
	setMaxAnisotropy
	setMinFilter
	setMipFilter
	setNormalizedCoordinates
	setRAddressMode
	setSAddressMode
	setSupportArgumentBuffers
	setTAddressMode
	supportArgumentBuffers
	tAddressMode
*/
@(objc_class="MTLSamplerDescriptor")
SamplerDescriptor :: struct { using _: NS.Copying(SamplerDescriptor) }

@(objc_type=SamplerDescriptor, objc_class_name="alloc")
SamplerDescriptor_alloc :: #force_inline proc() -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, SamplerDescriptor, "alloc")
}
@(objc_type=SamplerDescriptor, objc_name="init")
SamplerDescriptor_init :: #force_inline proc(self: ^SamplerDescriptor) -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, self, "init")
}
@(objc_type=SamplerDescriptor, objc_name="borderColor")
SamplerDescriptor_borderColor :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerBorderColor {
	return msgSend(SamplerBorderColor, self, "borderColor")
}
@(objc_type=SamplerDescriptor, objc_name="compareFunction")
SamplerDescriptor_compareFunction :: #force_inline proc(self: ^SamplerDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "compareFunction")
}
@(objc_type=SamplerDescriptor, objc_name="label")
SamplerDescriptor_label :: #force_inline proc(self: ^SamplerDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=SamplerDescriptor, objc_name="lodAverage")
SamplerDescriptor_lodAverage :: #force_inline proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "lodAverage")
}
@(objc_type=SamplerDescriptor, objc_name="lodMaxClamp")
SamplerDescriptor_lodMaxClamp :: #force_inline proc(self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMaxClamp")
}
@(objc_type=SamplerDescriptor, objc_name="lodMinClamp")
SamplerDescriptor_lodMinClamp :: #force_inline proc(self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMinClamp")
}
@(objc_type=SamplerDescriptor, objc_name="magFilter")
SamplerDescriptor_magFilter :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "magFilter")
}
@(objc_type=SamplerDescriptor, objc_name="maxAnisotropy")
SamplerDescriptor_maxAnisotropy :: #force_inline proc(self: ^SamplerDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxAnisotropy")
}
@(objc_type=SamplerDescriptor, objc_name="minFilter")
SamplerDescriptor_minFilter :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "minFilter")
}
@(objc_type=SamplerDescriptor, objc_name="mipFilter")
SamplerDescriptor_mipFilter :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerMipFilter {
	return msgSend(SamplerMipFilter, self, "mipFilter")
}
@(objc_type=SamplerDescriptor, objc_name="normalizedCoordinates")
SamplerDescriptor_normalizedCoordinates :: #force_inline proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "normalizedCoordinates")
}
@(objc_type=SamplerDescriptor, objc_name="rAddressMode")
SamplerDescriptor_rAddressMode :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "rAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="sAddressMode")
SamplerDescriptor_sAddressMode :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "sAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="setBorderColor")
SamplerDescriptor_setBorderColor :: #force_inline proc(self: ^SamplerDescriptor, borderColor: SamplerBorderColor) {
	msgSend(nil, self, "setBorderColor:", borderColor)
}
@(objc_type=SamplerDescriptor, objc_name="setCompareFunction")
SamplerDescriptor_setCompareFunction :: #force_inline proc(self: ^SamplerDescriptor, compareFunction: CompareFunction) {
	msgSend(nil, self, "setCompareFunction:", compareFunction)
}
@(objc_type=SamplerDescriptor, objc_name="setLabel")
SamplerDescriptor_setLabel :: #force_inline proc(self: ^SamplerDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=SamplerDescriptor, objc_name="setLodAverage")
SamplerDescriptor_setLodAverage :: #force_inline proc(self: ^SamplerDescriptor, lodAverage: BOOL) {
	msgSend(nil, self, "setLodAverage:", lodAverage)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMaxClamp")
SamplerDescriptor_setLodMaxClamp :: #force_inline proc(self: ^SamplerDescriptor, lodMaxClamp: f32) {
	msgSend(nil, self, "setLodMaxClamp:", lodMaxClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMinClamp")
SamplerDescriptor_setLodMinClamp :: #force_inline proc(self: ^SamplerDescriptor, lodMinClamp: f32) {
	msgSend(nil, self, "setLodMinClamp:", lodMinClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setMagFilter")
SamplerDescriptor_setMagFilter :: #force_inline proc(self: ^SamplerDescriptor, magFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMagFilter:", magFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMaxAnisotropy")
SamplerDescriptor_setMaxAnisotropy :: #force_inline proc(self: ^SamplerDescriptor, maxAnisotropy: NS.UInteger) {
	msgSend(nil, self, "setMaxAnisotropy:", maxAnisotropy)
}
@(objc_type=SamplerDescriptor, objc_name="setMinFilter")
SamplerDescriptor_setMinFilter :: #force_inline proc(self: ^SamplerDescriptor, minFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMinFilter:", minFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMipFilter")
SamplerDescriptor_setMipFilter :: #force_inline proc(self: ^SamplerDescriptor, mipFilter: SamplerMipFilter) {
	msgSend(nil, self, "setMipFilter:", mipFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setNormalizedCoordinates")
SamplerDescriptor_setNormalizedCoordinates :: #force_inline proc(self: ^SamplerDescriptor, normalizedCoordinates: BOOL) {
	msgSend(nil, self, "setNormalizedCoordinates:", normalizedCoordinates)
}
@(objc_type=SamplerDescriptor, objc_name="setRAddressMode")
SamplerDescriptor_setRAddressMode :: #force_inline proc(self: ^SamplerDescriptor, rAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setRAddressMode:", rAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSAddressMode")
SamplerDescriptor_setSAddressMode :: #force_inline proc(self: ^SamplerDescriptor, sAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setSAddressMode:", sAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSupportArgumentBuffers")
SamplerDescriptor_setSupportArgumentBuffers :: #force_inline proc(self: ^SamplerDescriptor, supportArgumentBuffers: BOOL) {
	msgSend(nil, self, "setSupportArgumentBuffers:", supportArgumentBuffers)
}
@(objc_type=SamplerDescriptor, objc_name="setTAddressMode")
SamplerDescriptor_setTAddressMode :: #force_inline proc(self: ^SamplerDescriptor, tAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setTAddressMode:", tAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="supportArgumentBuffers")
SamplerDescriptor_supportArgumentBuffers :: #force_inline proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportArgumentBuffers")
}
@(objc_type=SamplerDescriptor, objc_name="tAddressMode")
SamplerDescriptor_tAddressMode :: #force_inline proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "tAddressMode")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SharedEventHandle
Class Methods:
	alloc
Methods:
	init
	label
*/
@(objc_class="MTLSharedEventHandle")
SharedEventHandle :: struct { using _: NS.Object }

@(objc_type=SharedEventHandle, objc_class_name="alloc")
SharedEventHandle_alloc :: #force_inline proc() -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, SharedEventHandle, "alloc")
}
@(objc_type=SharedEventHandle, objc_name="init")
SharedEventHandle_init :: #force_inline proc(self: ^SharedEventHandle) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "init")
}
@(objc_type=SharedEventHandle, objc_name="label")
SharedEventHandle_label :: #force_inline proc(self: ^SharedEventHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SharedEventListener
Class Methods:
	alloc
Methods:
	dispatchQueue
	init
	initWithDispatchQueue
*/
@(objc_class="MTLSharedEventListener")
SharedEventListener :: struct { using _: NS.Object }

@(objc_type=SharedEventListener, objc_class_name="alloc")
SharedEventListener_alloc :: #force_inline proc() -> ^SharedEventListener {
	return msgSend(^SharedEventListener, SharedEventListener, "alloc")
}
@(objc_type=SharedEventListener, objc_name="dispatchQueue")
SharedEventListener_dispatchQueue :: #force_inline proc(self: ^SharedEventListener) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "dispatchQueue")
}
@(objc_type=SharedEventListener, objc_name="init")
SharedEventListener_init :: #force_inline proc(self: ^SharedEventListener) -> ^SharedEventListener {
	return msgSend(^SharedEventListener, self, "init")
}
@(objc_type=SharedEventListener, objc_name="initWithDispatchQueue")
SharedEventListener_initWithDispatchQueue :: #force_inline proc(self: ^SharedEventListener, dispatchQueue: dispatch_queue_t) -> ^SharedEventListener {
	return msgSend(^SharedEventListener, self, "initWithDispatchQueue:", dispatchQueue)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SharedTextureHandle
Class Methods:
	alloc
Methods:
	init
	device
	label
*/
@(objc_class="MTLSharedTextureHandle")
SharedTextureHandle :: struct { using _: NS.Object }

@(objc_type=SharedTextureHandle, objc_class_name="alloc")
SharedTextureHandle_alloc :: #force_inline proc() -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, SharedTextureHandle, "alloc")
}
@(objc_type=SharedTextureHandle, objc_name="init")
SharedTextureHandle_init :: #force_inline proc(self: ^SharedTextureHandle) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "init")
}
@(objc_type=SharedTextureHandle, objc_name="device")
SharedTextureHandle_device :: #force_inline proc(self: ^SharedTextureHandle) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "device")
}
@(objc_type=SharedTextureHandle, objc_name="label")
SharedTextureHandle_label :: #force_inline proc(self: ^SharedTextureHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	StageInputOutputDescriptor
Class Methods:
	alloc
	stageInputOutputDescriptor
Methods:
	init
	attributes
	indexBufferIndex
	indexType
	layouts
	reset
	setIndexBufferIndex
	setIndexType
*/
@(objc_class="MTLStageInputOutputDescriptor")
StageInputOutputDescriptor :: struct { using _: NS.Copying(StageInputOutputDescriptor) }

@(objc_type=StageInputOutputDescriptor, objc_class_name="alloc")
StageInputOutputDescriptor_alloc :: #force_inline proc() -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, StageInputOutputDescriptor, "alloc")
}
@(objc_type=StageInputOutputDescriptor, objc_name="init")
StageInputOutputDescriptor_init :: #force_inline proc(self: ^StageInputOutputDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "init")
}
@(objc_type=StageInputOutputDescriptor, objc_name="attributes")
StageInputOutputDescriptor_attributes :: #force_inline proc(self: ^StageInputOutputDescriptor) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "attributes")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexBufferIndex")
StageInputOutputDescriptor_indexBufferIndex :: #force_inline proc(self: ^StageInputOutputDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferIndex")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexType")
StageInputOutputDescriptor_indexType :: #force_inline proc(self: ^StageInputOutputDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=StageInputOutputDescriptor, objc_name="layouts")
StageInputOutputDescriptor_layouts :: #force_inline proc(self: ^StageInputOutputDescriptor) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=StageInputOutputDescriptor, objc_name="reset")
StageInputOutputDescriptor_reset :: #force_inline proc(self: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexBufferIndex")
StageInputOutputDescriptor_setIndexBufferIndex :: #force_inline proc(self: ^StageInputOutputDescriptor, indexBufferIndex: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferIndex:", indexBufferIndex)
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexType")
StageInputOutputDescriptor_setIndexType :: #force_inline proc(self: ^StageInputOutputDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=StageInputOutputDescriptor, objc_class_name="stageInputOutputDescriptor")
StageInputOutputDescriptor_stageInputOutputDescriptor :: #force_inline proc() -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, StageInputOutputDescriptor, "stageInputOutputDescriptor")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	StencilDescriptor
Class Methods:
	alloc
Methods:
	init
	depthFailureOperation
	depthStencilPassOperation
	readMask
	setDepthFailureOperation
	setDepthStencilPassOperation
	setReadMask
	setStencilCompareFunction
	setStencilFailureOperation
	setWriteMask
	stencilCompareFunction
	stencilFailureOperation
	writeMask
*/
@(objc_class="MTLStencilDescriptor")
StencilDescriptor :: struct { using _: NS.Copying(StencilDescriptor) }

@(objc_type=StencilDescriptor, objc_class_name="alloc")
StencilDescriptor_alloc :: #force_inline proc() -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, StencilDescriptor, "alloc")
}
@(objc_type=StencilDescriptor, objc_name="init")
StencilDescriptor_init :: #force_inline proc(self: ^StencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "init")
}
@(objc_type=StencilDescriptor, objc_name="depthFailureOperation")
StencilDescriptor_depthFailureOperation :: #force_inline proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="depthStencilPassOperation")
StencilDescriptor_depthStencilPassOperation :: #force_inline proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthStencilPassOperation")
}
@(objc_type=StencilDescriptor, objc_name="readMask")
StencilDescriptor_readMask :: #force_inline proc(self: ^StencilDescriptor) -> u32 {
	return msgSend(u32, self, "readMask")
}
@(objc_type=StencilDescriptor, objc_name="setDepthFailureOperation")
StencilDescriptor_setDepthFailureOperation :: #force_inline proc(self: ^StencilDescriptor, depthFailureOperation: StencilOperation) {
	msgSend(nil, self, "setDepthFailureOperation:", depthFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setDepthStencilPassOperation")
StencilDescriptor_setDepthStencilPassOperation :: #force_inline proc(self: ^StencilDescriptor, depthStencilPassOperation: StencilOperation) {
	msgSend(nil, self, "setDepthStencilPassOperation:", depthStencilPassOperation)
}
@(objc_type=StencilDescriptor, objc_name="setReadMask")
StencilDescriptor_setReadMask :: #force_inline proc(self: ^StencilDescriptor, readMask: u32) {
	msgSend(nil, self, "setReadMask:", readMask)
}
@(objc_type=StencilDescriptor, objc_name="setStencilCompareFunction")
StencilDescriptor_setStencilCompareFunction :: #force_inline proc(self: ^StencilDescriptor, stencilCompareFunction: CompareFunction) {
	msgSend(nil, self, "setStencilCompareFunction:", stencilCompareFunction)
}
@(objc_type=StencilDescriptor, objc_name="setStencilFailureOperation")
StencilDescriptor_setStencilFailureOperation :: #force_inline proc(self: ^StencilDescriptor, stencilFailureOperation: StencilOperation) {
	msgSend(nil, self, "setStencilFailureOperation:", stencilFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setWriteMask")
StencilDescriptor_setWriteMask :: #force_inline proc(self: ^StencilDescriptor, writeMask: u32) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=StencilDescriptor, objc_name="stencilCompareFunction")
StencilDescriptor_stencilCompareFunction :: #force_inline proc(self: ^StencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "stencilCompareFunction")
}
@(objc_type=StencilDescriptor, objc_name="stencilFailureOperation")
StencilDescriptor_stencilFailureOperation :: #force_inline proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "stencilFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="writeMask")
StencilDescriptor_writeMask :: #force_inline proc(self: ^StencilDescriptor) -> u32 {
	return msgSend(u32, self, "writeMask")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	StructMember
Class Methods:
	alloc
Methods:
	init
	argumentIndex
	arrayType
	dataType
	name
	offset
	pointerType
	structType
	textureReferenceType
*/
@(objc_class="MTLStructMember")
StructMember :: struct { using _: NS.Object }

@(objc_type=StructMember, objc_class_name="alloc")
StructMember_alloc :: #force_inline proc() -> ^StructMember {
	return msgSend(^StructMember, StructMember, "alloc")
}
@(objc_type=StructMember, objc_name="init")
StructMember_init :: #force_inline proc(self: ^StructMember) -> ^StructMember {
	return msgSend(^StructMember, self, "init")
}
@(objc_type=StructMember, objc_name="argumentIndex")
StructMember_argumentIndex :: #force_inline proc(self: ^StructMember) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "argumentIndex")
}
@(objc_type=StructMember, objc_name="arrayType")
StructMember_arrayType :: #force_inline proc(self: ^StructMember) -> ^ArrayType {
	return msgSend(^ArrayType, self, "arrayType")
}
@(objc_type=StructMember, objc_name="dataType")
StructMember_dataType :: #force_inline proc(self: ^StructMember) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=StructMember, objc_name="name")
StructMember_name :: #force_inline proc(self: ^StructMember) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=StructMember, objc_name="offset")
StructMember_offset :: #force_inline proc(self: ^StructMember) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=StructMember, objc_name="pointerType")
StructMember_pointerType :: #force_inline proc(self: ^StructMember) -> ^PointerType {
	return msgSend(^PointerType, self, "pointerType")
}
@(objc_type=StructMember, objc_name="structType")
StructMember_structType :: #force_inline proc(self: ^StructMember) -> ^StructType {
	return msgSend(^StructType, self, "structType")
}
@(objc_type=StructMember, objc_name="textureReferenceType")
StructMember_textureReferenceType :: #force_inline proc(self: ^StructMember) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "textureReferenceType")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	StructType
Class Methods:
	alloc
Methods:
	init
	memberByName
	members
*/
@(objc_class="MTLStructType")
StructType :: struct { using _: Type }

@(objc_type=StructType, objc_class_name="alloc")
StructType_alloc :: #force_inline proc() -> ^StructType {
	return msgSend(^StructType, StructType, "alloc")
}
@(objc_type=StructType, objc_name="init")
StructType_init :: #force_inline proc(self: ^StructType) -> ^StructType {
	return msgSend(^StructType, self, "init")
}
@(objc_type=StructType, objc_name="memberByName")
StructType_memberByName :: #force_inline proc(self: ^StructType, name: ^NS.String) -> ^StructMember {
	return msgSend(^StructMember, self, "memberByName:", name)
}
@(objc_type=StructType, objc_name="members")
StructType_members :: #force_inline proc(self: ^StructType) -> ^NS.Array {
	return msgSend(^NS.Array, self, "members")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	TextureDescriptor
Class Methods:
	alloc
	texture2DDescriptorWithPixelFormat
	textureBufferDescriptorWithPixelFormat
	textureCubeDescriptorWithPixelFormat
Methods:
	init
	allowGPUOptimizedContents
	arrayLength
	cpuCacheMode
	depth
	hazardTrackingMode
	height
	mipmapLevelCount
	pixelFormat
	resourceOptions
	sampleCount
	setAllowGPUOptimizedContents
	setArrayLength
	setCpuCacheMode
	setDepth
	setHazardTrackingMode
	setHeight
	setMipmapLevelCount
	setPixelFormat
	setResourceOptions
	setSampleCount
	setStorageMode
	setSwizzle
	setTextureType
	setUsage
	setWidth
	storageMode
	swizzle
	textureType
	usage
	width
*/
@(objc_class="MTLTextureDescriptor")
TextureDescriptor :: struct { using _: NS.Copying(TextureDescriptor) }

@(objc_type=TextureDescriptor, objc_class_name="alloc")
TextureDescriptor_alloc :: #force_inline proc() -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "alloc")
}
@(objc_type=TextureDescriptor, objc_name="init")
TextureDescriptor_init :: #force_inline proc(self: ^TextureDescriptor) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, self, "init")
}
@(objc_type=TextureDescriptor, objc_name="allowGPUOptimizedContents")
TextureDescriptor_allowGPUOptimizedContents :: #force_inline proc(self: ^TextureDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=TextureDescriptor, objc_name="arrayLength")
TextureDescriptor_arrayLength :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=TextureDescriptor, objc_name="cpuCacheMode")
TextureDescriptor_cpuCacheMode :: #force_inline proc(self: ^TextureDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=TextureDescriptor, objc_name="depth")
TextureDescriptor_depth :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depth")
}
@(objc_type=TextureDescriptor, objc_name="hazardTrackingMode")
TextureDescriptor_hazardTrackingMode :: #force_inline proc(self: ^TextureDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=TextureDescriptor, objc_name="height")
TextureDescriptor_height :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "height")
}
@(objc_type=TextureDescriptor, objc_name="mipmapLevelCount")
TextureDescriptor_mipmapLevelCount :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "mipmapLevelCount")
}
@(objc_type=TextureDescriptor, objc_name="pixelFormat")
TextureDescriptor_pixelFormat :: #force_inline proc(self: ^TextureDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TextureDescriptor, objc_name="resourceOptions")
TextureDescriptor_resourceOptions :: #force_inline proc(self: ^TextureDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=TextureDescriptor, objc_name="sampleCount")
TextureDescriptor_sampleCount :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=TextureDescriptor, objc_name="setAllowGPUOptimizedContents")
TextureDescriptor_setAllowGPUOptimizedContents :: #force_inline proc(self: ^TextureDescriptor, allowGPUOptimizedContents: BOOL) {
	msgSend(nil, self, "setAllowGPUOptimizedContents:", allowGPUOptimizedContents)
}
@(objc_type=TextureDescriptor, objc_name="setArrayLength")
TextureDescriptor_setArrayLength :: #force_inline proc(self: ^TextureDescriptor, arrayLength: NS.UInteger) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=TextureDescriptor, objc_name="setCpuCacheMode")
TextureDescriptor_setCpuCacheMode :: #force_inline proc(self: ^TextureDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}
@(objc_type=TextureDescriptor, objc_name="setDepth")
TextureDescriptor_setDepth :: #force_inline proc(self: ^TextureDescriptor, depth: NS.UInteger) {
	msgSend(nil, self, "setDepth:", depth)
}
@(objc_type=TextureDescriptor, objc_name="setHazardTrackingMode")
TextureDescriptor_setHazardTrackingMode :: #force_inline proc(self: ^TextureDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=TextureDescriptor, objc_name="setHeight")
TextureDescriptor_setHeight :: #force_inline proc(self: ^TextureDescriptor, height: NS.UInteger) {
	msgSend(nil, self, "setHeight:", height)
}
@(objc_type=TextureDescriptor, objc_name="setMipmapLevelCount")
TextureDescriptor_setMipmapLevelCount :: #force_inline proc(self: ^TextureDescriptor, mipmapLevelCount: NS.UInteger) {
	msgSend(nil, self, "setMipmapLevelCount:", mipmapLevelCount)
}
@(objc_type=TextureDescriptor, objc_name="setPixelFormat")
TextureDescriptor_setPixelFormat :: #force_inline proc(self: ^TextureDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=TextureDescriptor, objc_name="setResourceOptions")
TextureDescriptor_setResourceOptions :: #force_inline proc(self: ^TextureDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=TextureDescriptor, objc_name="setSampleCount")
TextureDescriptor_setSampleCount :: #force_inline proc(self: ^TextureDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=TextureDescriptor, objc_name="setStorageMode")
TextureDescriptor_setStorageMode :: #force_inline proc(self: ^TextureDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=TextureDescriptor, objc_name="setSwizzle")
TextureDescriptor_setSwizzle :: #force_inline proc(self: ^TextureDescriptor, swizzle: TextureSwizzleChannels) {
	msgSend(nil, self, "setSwizzle:", swizzle)
}
@(objc_type=TextureDescriptor, objc_name="setTextureType")
TextureDescriptor_setTextureType :: #force_inline proc(self: ^TextureDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=TextureDescriptor, objc_name="setUsage")
TextureDescriptor_setUsage :: #force_inline proc(self: ^TextureDescriptor, usage: TextureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=TextureDescriptor, objc_name="setWidth")
TextureDescriptor_setWidth :: #force_inline proc(self: ^TextureDescriptor, width: NS.UInteger) {
	msgSend(nil, self, "setWidth:", width)
}
@(objc_type=TextureDescriptor, objc_name="storageMode")
TextureDescriptor_storageMode :: #force_inline proc(self: ^TextureDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=TextureDescriptor, objc_name="swizzle")
TextureDescriptor_swizzle :: #force_inline proc(self: ^TextureDescriptor) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=TextureDescriptor, objc_class_name="texture2DDescriptorWithPixelFormat")
TextureDescriptor_texture2DDescriptorWithPixelFormat :: #force_inline proc(pixelFormat: PixelFormat, width: NS.UInteger, height: NS.UInteger, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "texture2DDescriptorWithPixelFormat:width:height:mipmapped:", pixelFormat, width, height, mipmapped)
}
@(objc_type=TextureDescriptor, objc_class_name="textureBufferDescriptorWithPixelFormat")
TextureDescriptor_textureBufferDescriptorWithPixelFormat :: #force_inline proc(pixelFormat: PixelFormat, width: NS.UInteger, resourceOptions: ResourceOptions, usage: TextureUsage) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureBufferDescriptorWithPixelFormat:width:resourceOptions:usage:", pixelFormat, width, resourceOptions, usage)
}
@(objc_type=TextureDescriptor, objc_class_name="textureCubeDescriptorWithPixelFormat")
TextureDescriptor_textureCubeDescriptorWithPixelFormat :: #force_inline proc(pixelFormat: PixelFormat, size: NS.UInteger, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureCubeDescriptorWithPixelFormat:size:mipmapped:", pixelFormat, size, mipmapped)
}
@(objc_type=TextureDescriptor, objc_name="textureType")
TextureDescriptor_textureType :: #force_inline proc(self: ^TextureDescriptor) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=TextureDescriptor, objc_name="usage")
TextureDescriptor_usage :: #force_inline proc(self: ^TextureDescriptor) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=TextureDescriptor, objc_name="width")
TextureDescriptor_width :: #force_inline proc(self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "width")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	TextureReferenceType
Class Methods:
	alloc
Methods:
	init
	access
	isDepthTexture
	textureDataType
	textureType
*/
@(objc_class="MTLTextureReferenceType")
TextureReferenceType :: struct { using _: Type }

@(objc_type=TextureReferenceType, objc_class_name="alloc")
TextureReferenceType_alloc :: #force_inline proc() -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, TextureReferenceType, "alloc")
}
@(objc_type=TextureReferenceType, objc_name="init")
TextureReferenceType_init :: #force_inline proc(self: ^TextureReferenceType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "init")
}
@(objc_type=TextureReferenceType, objc_name="access")
TextureReferenceType_access :: #force_inline proc(self: ^TextureReferenceType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=TextureReferenceType, objc_name="isDepthTexture")
TextureReferenceType_isDepthTexture :: #force_inline proc(self: ^TextureReferenceType) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=TextureReferenceType, objc_name="textureDataType")
TextureReferenceType_textureDataType :: #force_inline proc(self: ^TextureReferenceType) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=TextureReferenceType, objc_name="textureType")
TextureReferenceType_textureType :: #force_inline proc(self: ^TextureReferenceType) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	TileRenderPipelineColorAttachmentDescriptor
Class Methods:
	alloc
Methods:
	init
	pixelFormat
	setPixelFormat
*/
@(objc_class="MTLTileRenderPipelineColorAttachmentDescriptor")
TileRenderPipelineColorAttachmentDescriptor :: struct { using _: NS.Copying(TileRenderPipelineColorAttachmentDescriptor) }

@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_class_name="alloc")
TileRenderPipelineColorAttachmentDescriptor_alloc :: #force_inline proc() -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, TileRenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="init")
TileRenderPipelineColorAttachmentDescriptor_init :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
TileRenderPipelineColorAttachmentDescriptor_pixelFormat :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
TileRenderPipelineColorAttachmentDescriptor_setPixelFormat :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	TileRenderPipelineColorAttachmentDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLTileRenderPipelineColorAttachmentDescriptorArray")
TileRenderPipelineColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_class_name="alloc")
TileRenderPipelineColorAttachmentDescriptorArray_alloc :: #force_inline proc() -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, TileRenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="init")
TileRenderPipelineColorAttachmentDescriptorArray_init :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="object")
TileRenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
TileRenderPipelineColorAttachmentDescriptorArray_setObject :: #force_inline proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachment: ^TileRenderPipelineColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	TileRenderPipelineDescriptor
Class Methods:
	alloc
Methods:
	init
	binaryArchives
	colorAttachments
	label
	maxTotalThreadsPerThreadgroup
	rasterSampleCount
	reset
	setBinaryArchives
	setLabel
	setMaxTotalThreadsPerThreadgroup
	setRasterSampleCount
	setThreadgroupSizeMatchesTileSize
	setTileFunction
	threadgroupSizeMatchesTileSize
	tileBuffers
	tileFunction
*/
@(objc_class="MTLTileRenderPipelineDescriptor")
TileRenderPipelineDescriptor :: struct { using _: NS.Copying(TileRenderPipelineDescriptor) }

@(objc_type=TileRenderPipelineDescriptor, objc_class_name="alloc")
TileRenderPipelineDescriptor_alloc :: #force_inline proc() -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, TileRenderPipelineDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="init")
TileRenderPipelineDescriptor_init :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="binaryArchives")
TileRenderPipelineDescriptor_binaryArchives :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="colorAttachments")
TileRenderPipelineDescriptor_colorAttachments :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="label")
TileRenderPipelineDescriptor_label :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_maxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="rasterSampleCount")
TileRenderPipelineDescriptor_rasterSampleCount :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "rasterSampleCount")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="reset")
TileRenderPipelineDescriptor_reset :: #force_inline proc(self: ^TileRenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setBinaryArchives")
TileRenderPipelineDescriptor_setBinaryArchives :: #force_inline proc(self: ^TileRenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setLabel")
TileRenderPipelineDescriptor_setLabel :: #force_inline proc(self: ^TileRenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^TileRenderPipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setRasterSampleCount")
TileRenderPipelineDescriptor_setRasterSampleCount :: #force_inline proc(self: ^TileRenderPipelineDescriptor, rasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setThreadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_setThreadgroupSizeMatchesTileSize :: #force_inline proc(self: ^TileRenderPipelineDescriptor, threadgroupSizeMatchesTileSize: BOOL) {
	msgSend(nil, self, "setThreadgroupSizeMatchesTileSize:", threadgroupSizeMatchesTileSize)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setTileFunction")
TileRenderPipelineDescriptor_setTileFunction :: #force_inline proc(self: ^TileRenderPipelineDescriptor, tileFunction: ^Function) {
	msgSend(nil, self, "setTileFunction:", tileFunction)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="threadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_threadgroupSizeMatchesTileSize :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "threadgroupSizeMatchesTileSize")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileBuffers")
TileRenderPipelineDescriptor_tileBuffers :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "tileBuffers")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileFunction")
TileRenderPipelineDescriptor_tileFunction :: #force_inline proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, self, "tileFunction")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Type
Class Methods:
	alloc
Methods:
	init
	dataType
*/
@(objc_class="MTLType")
Type :: struct { using _: NS.Object }

@(objc_type=Type, objc_class_name="alloc")
Type_alloc :: #force_inline proc() -> ^Type {
	return msgSend(^Type, Type, "alloc")
}
@(objc_type=Type, objc_name="init")
Type_init :: #force_inline proc(self: ^Type) -> ^Type {
	return msgSend(^Type, self, "init")
}
@(objc_type=Type, objc_name="dataType")
Type_dataType :: #force_inline proc(self: ^Type) -> DataType {
	return msgSend(DataType, self, "dataType")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexAttribute
Class Methods:
	alloc
Methods:
	init
	attributeIndex
	attributeType
	isActive
	isPatchControlPointData
	isPatchData
	name
*/
@(objc_class="MTLVertexAttribute")
VertexAttribute :: struct { using _: NS.Object }

@(objc_type=VertexAttribute, objc_class_name="alloc")
VertexAttribute_alloc :: #force_inline proc() -> ^VertexAttribute {
	return msgSend(^VertexAttribute, VertexAttribute, "alloc")
}
@(objc_type=VertexAttribute, objc_name="init")
VertexAttribute_init :: #force_inline proc(self: ^VertexAttribute) -> ^VertexAttribute {
	return msgSend(^VertexAttribute, self, "init")
}
@(objc_type=VertexAttribute, objc_name="attributeIndex")
VertexAttribute_attributeIndex :: #force_inline proc(self: ^VertexAttribute) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "attributeIndex")
}
@(objc_type=VertexAttribute, objc_name="attributeType")
VertexAttribute_attributeType :: #force_inline proc(self: ^VertexAttribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=VertexAttribute, objc_name="isActive")
VertexAttribute_isActive :: #force_inline proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=VertexAttribute, objc_name="isPatchControlPointData")
VertexAttribute_isPatchControlPointData :: #force_inline proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=VertexAttribute, objc_name="isPatchData")
VertexAttribute_isPatchData :: #force_inline proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=VertexAttribute, objc_name="name")
VertexAttribute_name :: #force_inline proc(self: ^VertexAttribute) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexAttributeDescriptor
Class Methods:
	alloc
Methods:
	init
	bufferIndex
	format
	offset
	setBufferIndex
	setFormat
	setOffset
*/
@(objc_class="MTLVertexAttributeDescriptor")
VertexAttributeDescriptor :: struct { using _: NS.Copying(VertexAttributeDescriptor) }

@(objc_type=VertexAttributeDescriptor, objc_class_name="alloc")
VertexAttributeDescriptor_alloc :: #force_inline proc() -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, VertexAttributeDescriptor, "alloc")
}
@(objc_type=VertexAttributeDescriptor, objc_name="init")
VertexAttributeDescriptor_init :: #force_inline proc(self: ^VertexAttributeDescriptor) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "init")
}
@(objc_type=VertexAttributeDescriptor, objc_name="bufferIndex")
VertexAttributeDescriptor_bufferIndex :: #force_inline proc(self: ^VertexAttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferIndex")
}
@(objc_type=VertexAttributeDescriptor, objc_name="format")
VertexAttributeDescriptor_format :: #force_inline proc(self: ^VertexAttributeDescriptor) -> VertexFormat {
	return msgSend(VertexFormat, self, "format")
}
@(objc_type=VertexAttributeDescriptor, objc_name="offset")
VertexAttributeDescriptor_offset :: #force_inline proc(self: ^VertexAttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=VertexAttributeDescriptor, objc_name="setBufferIndex")
VertexAttributeDescriptor_setBufferIndex :: #force_inline proc(self: ^VertexAttributeDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setFormat")
VertexAttributeDescriptor_setFormat :: #force_inline proc(self: ^VertexAttributeDescriptor, format: VertexFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setOffset")
VertexAttributeDescriptor_setOffset :: #force_inline proc(self: ^VertexAttributeDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexAttributeDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLVertexAttributeDescriptorArray")
VertexAttributeDescriptorArray :: struct { using _: NS.Object }

@(objc_type=VertexAttributeDescriptorArray, objc_class_name="alloc")
VertexAttributeDescriptorArray_alloc :: #force_inline proc() -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, VertexAttributeDescriptorArray, "alloc")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="init")
VertexAttributeDescriptorArray_init :: #force_inline proc(self: ^VertexAttributeDescriptorArray) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "init")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="object")
VertexAttributeDescriptorArray_object :: #force_inline proc(self: ^VertexAttributeDescriptorArray, index: NS.UInteger) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="setObject")
VertexAttributeDescriptorArray_setObject :: #force_inline proc(self: ^VertexAttributeDescriptorArray, attributeDesc: ^VertexAttributeDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attributeDesc, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexBufferLayoutDescriptor
Class Methods:
	alloc
Methods:
	init
	setStepFunction
	setStepRate
	setStride
	stepFunction
	stepRate
	stride
*/
@(objc_class="MTLVertexBufferLayoutDescriptor")
VertexBufferLayoutDescriptor :: struct { using _: NS.Copying(VertexBufferLayoutDescriptor) }

@(objc_type=VertexBufferLayoutDescriptor, objc_class_name="alloc")
VertexBufferLayoutDescriptor_alloc :: #force_inline proc() -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, VertexBufferLayoutDescriptor, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="init")
VertexBufferLayoutDescriptor_init :: #force_inline proc(self: ^VertexBufferLayoutDescriptor) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepFunction")
VertexBufferLayoutDescriptor_setStepFunction :: #force_inline proc(self: ^VertexBufferLayoutDescriptor, stepFunction: VertexStepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepRate")
VertexBufferLayoutDescriptor_setStepRate :: #force_inline proc(self: ^VertexBufferLayoutDescriptor, stepRate: NS.UInteger) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStride")
VertexBufferLayoutDescriptor_setStride :: #force_inline proc(self: ^VertexBufferLayoutDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepFunction")
VertexBufferLayoutDescriptor_stepFunction :: #force_inline proc(self: ^VertexBufferLayoutDescriptor) -> VertexStepFunction {
	return msgSend(VertexStepFunction, self, "stepFunction")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepRate")
VertexBufferLayoutDescriptor_stepRate :: #force_inline proc(self: ^VertexBufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stepRate")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stride")
VertexBufferLayoutDescriptor_stride :: #force_inline proc(self: ^VertexBufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexBufferLayoutDescriptorArray
Class Methods:
	alloc
Methods:
	init
	objectAtIndexedSubscript
	setObject
*/
@(objc_class="MTLVertexBufferLayoutDescriptorArray")
VertexBufferLayoutDescriptorArray :: struct { using _: NS.Object }

@(objc_type=VertexBufferLayoutDescriptorArray, objc_class_name="alloc")
VertexBufferLayoutDescriptorArray_alloc :: #force_inline proc() -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, VertexBufferLayoutDescriptorArray, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="init")
VertexBufferLayoutDescriptorArray_init :: #force_inline proc(self: ^VertexBufferLayoutDescriptorArray) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="object")
VertexBufferLayoutDescriptorArray_object :: #force_inline proc(self: ^VertexBufferLayoutDescriptorArray, index: NS.UInteger) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="setObject")
VertexBufferLayoutDescriptorArray_setObject :: #force_inline proc(self: ^VertexBufferLayoutDescriptorArray, bufferDesc: ^VertexBufferLayoutDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", bufferDesc, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VertexDescriptor
Class Methods:
	alloc
	vertexDescriptor
Methods:
	init
	attributes
	layouts
	reset
*/
@(objc_class="MTLVertexDescriptor")
VertexDescriptor :: struct { using _: NS.Copying(VertexDescriptor) }

@(objc_type=VertexDescriptor, objc_class_name="alloc")
VertexDescriptor_alloc :: #force_inline proc() -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, VertexDescriptor, "alloc")
}
@(objc_type=VertexDescriptor, objc_name="init")
VertexDescriptor_init :: #force_inline proc(self: ^VertexDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "init")
}
@(objc_type=VertexDescriptor, objc_name="attributes")
VertexDescriptor_attributes :: #force_inline proc(self: ^VertexDescriptor) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "attributes")
}
@(objc_type=VertexDescriptor, objc_name="layouts")
VertexDescriptor_layouts :: #force_inline proc(self: ^VertexDescriptor) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=VertexDescriptor, objc_name="reset")
VertexDescriptor_reset :: #force_inline proc(self: ^VertexDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=VertexDescriptor, objc_class_name="vertexDescriptor")
VertexDescriptor_vertexDescriptor :: #force_inline proc() -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, VertexDescriptor, "vertexDescriptor")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VisibleFunctionTableDescriptor
Class Methods:
	alloc
	visibleFunctionTableDescriptor
Methods:
	init
	functionCount
	setFunctionCount
*/
@(objc_class="MTLVisibleFunctionTableDescriptor")
VisibleFunctionTableDescriptor :: struct { using _: NS.Copying(VisibleFunctionTableDescriptor) }

@(objc_type=VisibleFunctionTableDescriptor, objc_class_name="alloc")
VisibleFunctionTableDescriptor_alloc :: #force_inline proc() -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, VisibleFunctionTableDescriptor, "alloc")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="init")
VisibleFunctionTableDescriptor_init :: #force_inline proc(self: ^VisibleFunctionTableDescriptor) -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, self, "init")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="functionCount")
VisibleFunctionTableDescriptor_functionCount :: #force_inline proc(self: ^VisibleFunctionTableDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "functionCount")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="setFunctionCount")
VisibleFunctionTableDescriptor_setFunctionCount :: #force_inline proc(self: ^VisibleFunctionTableDescriptor, functionCount: NS.UInteger) {
	msgSend(nil, self, "setFunctionCount:", functionCount)
}
@(objc_type=VisibleFunctionTableDescriptor, objc_class_name="visibleFunctionTableDescriptor")
VisibleFunctionTableDescriptor_visibleFunctionTableDescriptor :: #force_inline proc() -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, VisibleFunctionTableDescriptor, "visibleFunctionTableDescriptor")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructure
Class Methods:
Methods:
	size
*/
@(objc_class="MTLAccelerationStructure")
AccelerationStructure :: struct { using _: Resource }

@(objc_type=AccelerationStructure, objc_name="size")
AccelerationStructure_size :: #force_inline proc(self: ^AccelerationStructure) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	AccelerationStructureCommandEncoder
Class Methods:
Methods:
	buildAccelerationStructure
	copyAccelerationStructure
	copyAndCompactAccelerationStructure
	refitAccelerationStructure
	sampleCountersInBuffer
	updateFence
	useHeap
	useHeaps
	useResource
	useResources
	waitForFence
	writeCompactedAccelerationStructureSize
*/
@(objc_class="MTLAccelerationStructureCommandEncoder")
AccelerationStructureCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=AccelerationStructureCommandEncoder, objc_name="buildAccelerationStructure")
AccelerationStructureCommandEncoder_buildAccelerationStructure :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^AccelerationStructure, descriptor: ^AccelerationStructureDescriptor, scratchBuffer: ^Buffer, scratchBufferOffset: NS.UInteger) {
	msgSend(nil, self, "buildAccelerationStructure:descriptor:scratchBuffer:scratchBufferOffset:", accelerationStructure, descriptor, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAccelerationStructure")
AccelerationStructureCommandEncoder_copyAccelerationStructure :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure, destinationAccelerationStructure: ^AccelerationStructure) {
	msgSend(nil, self, "copyAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAndCompactAccelerationStructure")
AccelerationStructureCommandEncoder_copyAndCompactAccelerationStructure :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure, destinationAccelerationStructure: ^AccelerationStructure) {
	msgSend(nil, self, "copyAndCompactAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="refitAccelerationStructure")
AccelerationStructureCommandEncoder_refitAccelerationStructure :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^AccelerationStructure, descriptor: ^AccelerationStructureDescriptor, destinationAccelerationStructure: ^AccelerationStructure, scratchBuffer: ^Buffer, scratchBufferOffset: NS.UInteger) {
	msgSend(nil, self, "refitAccelerationStructure:descriptor:destination:scratchBuffer:scratchBufferOffset:", sourceAccelerationStructure, descriptor, destinationAccelerationStructure, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="sampleCountersInBuffer")
AccelerationStructureCommandEncoder_sampleCountersInBuffer :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="updateFence")
AccelerationStructureCommandEncoder_updateFence :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeap")
AccelerationStructureCommandEncoder_useHeap :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeaps")
AccelerationStructureCommandEncoder_useHeaps :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResource")
AccelerationStructureCommandEncoder_useResource :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResources")
AccelerationStructureCommandEncoder_useResources :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, NS.UInteger(len(resources)), usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="waitForFence")
AccelerationStructureCommandEncoder_waitForFence :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="writeCompactedAccelerationStructureSize")
AccelerationStructureCommandEncoder_writeCompactedAccelerationStructureSize :: #force_inline proc(self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^AccelerationStructure, buffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "writeCompactedAccelerationStructureSize:toBuffer:offset:", accelerationStructure, buffer, offset)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ArgumentEncoder
Class Methods:
Methods:
	alignment
	constantDataAtIndex
	device
	encodedLength
	label
	newArgumentEncoderForBufferAtIndex
	setAccelerationStructure
	setArgumentBuffer
	setArgumentBuffer
	setBuffer
	setBuffers
	setComputePipelineState
	setComputePipelineStates
	setIndirectCommandBuffer
	setIndirectCommandBuffers
	setIntersectionFunctionTable
	setIntersectionFunctionTables
	setLabel
	setRenderPipelineState
	setRenderPipelineStates
	setSamplerState
	setSamplerStates
	setTexture
	setTextures
	setVisibleFunctionTable
	setVisibleFunctionTables
*/
@(objc_class="MTLArgumentEncoder")
ArgumentEncoder :: struct { using _: NS.Object }

@(objc_type=ArgumentEncoder, objc_name="alignment")
ArgumentEncoder_alignment :: #force_inline proc(self: ^ArgumentEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "alignment")
}
@(objc_type=ArgumentEncoder, objc_name="constantDataAtIndex")
ArgumentEncoder_constantDataAtIndex :: #force_inline proc(self: ^ArgumentEncoder, index: NS.UInteger) -> rawptr {
	return msgSend(rawptr, self, "constantDataAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="device")
ArgumentEncoder_device :: #force_inline proc(self: ^ArgumentEncoder) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=ArgumentEncoder, objc_name="encodedLength")
ArgumentEncoder_encodedLength :: #force_inline proc(self: ^ArgumentEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "encodedLength")
}
@(objc_type=ArgumentEncoder, objc_name="label")
ArgumentEncoder_label :: #force_inline proc(self: ^ArgumentEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ArgumentEncoder, objc_name="newArgumentEncoderForBufferAtIndex")
ArgumentEncoder_newArgumentEncoderForBufferAtIndex :: #force_inline proc(self: ^ArgumentEncoder, index: NS.UInteger) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderForBufferAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="setAccelerationStructure")
ArgumentEncoder_setAccelerationStructure :: #force_inline proc(self: ^ArgumentEncoder, accelerationStructure: ^AccelerationStructure, index: NS.UInteger) {
	msgSend(nil, self, "setAccelerationStructure:atIndex:", accelerationStructure, index)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBufferWithOffset")
ArgumentEncoder_setArgumentBufferWithOffset :: #force_inline proc(self: ^ArgumentEncoder, argumentBuffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "setArgumentBuffer:offset:", argumentBuffer, offset)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBuffer_startOffsetWithStartOffset")
ArgumentEncoder_setArgumentBuffer_startOffsetWithStartOffset :: #force_inline proc(self: ^ArgumentEncoder, argumentBuffer: ^Buffer, startOffset: NS.UInteger, arrayElement: NS.UInteger) {
	msgSend(nil, self, "setArgumentBuffer:startOffset:arrayElement:", argumentBuffer, startOffset, arrayElement)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffer")
ArgumentEncoder_setBuffer :: #force_inline proc(self: ^ArgumentEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffers")
ArgumentEncoder_setBuffers :: #force_inline proc(self: ^ArgumentEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineState")
ArgumentEncoder_setComputePipelineState :: #force_inline proc(self: ^ArgumentEncoder, pipeline: ^ComputePipelineState, index: NS.UInteger) {
	msgSend(nil, self, "setComputePipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineStates")
ArgumentEncoder_setComputePipelineStates :: #force_inline proc(self: ^ArgumentEncoder, pipelines: []^ComputePipelineState, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setComputePipelineStates:withRange:", raw_data(pipelines), range)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffer")
ArgumentEncoder_setIndirectCommandBuffer :: #force_inline proc(self: ^ArgumentEncoder, indirectCommandBuffer: ^IndirectCommandBuffer, index: NS.UInteger) {
	msgSend(nil, self, "setIndirectCommandBuffer:atIndex:", indirectCommandBuffer, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffers")
ArgumentEncoder_setIndirectCommandBuffers :: #force_inline proc(self: ^ArgumentEncoder, buffers: []^IndirectCommandBuffer, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setIndirectCommandBuffers:withRange:", raw_data(buffers), range)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTable")
ArgumentEncoder_setIntersectionFunctionTable :: #force_inline proc(self: ^ArgumentEncoder, intersectionFunctionTable: ^IntersectionFunctionTable, index: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTable:atIndex:", intersectionFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTables")
ArgumentEncoder_setIntersectionFunctionTables :: #force_inline proc(self: ^ArgumentEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withRange:", raw_data(intersectionFunctionTables), range)
}
@(objc_type=ArgumentEncoder, objc_name="setLabel")
ArgumentEncoder_setLabel :: #force_inline proc(self: ^ArgumentEncoder, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineState")
ArgumentEncoder_setRenderPipelineState :: #force_inline proc(self: ^ArgumentEncoder, pipeline: ^RenderPipelineState, index: NS.UInteger) {
	msgSend(nil, self, "setRenderPipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineStates")
ArgumentEncoder_setRenderPipelineStates :: #force_inline proc(self: ^ArgumentEncoder, pipelines: []^RenderPipelineState, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setRenderPipelineStates:withRange:", raw_data(pipelines), range)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerState")
ArgumentEncoder_setSamplerState :: #force_inline proc(self: ^ArgumentEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerStates")
ArgumentEncoder_setSamplerStates :: #force_inline proc(self: ^ArgumentEncoder, samplers: []^SamplerState, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(samplers)))
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=ArgumentEncoder, objc_name="setTexture")
ArgumentEncoder_setTexture :: #force_inline proc(self: ^ArgumentEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ArgumentEncoder, objc_name="setTextures")
ArgumentEncoder_setTextures :: #force_inline proc(self: ^ArgumentEncoder, textures: []^Texture, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(textures)))
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTable")
ArgumentEncoder_setVisibleFunctionTable :: #force_inline proc(self: ^ArgumentEncoder, visibleFunctionTable: ^VisibleFunctionTable, index: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atIndex:", visibleFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTables")
ArgumentEncoder_setVisibleFunctionTables :: #force_inline proc(self: ^ArgumentEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(visibleFunctionTables)))
	msgSend(nil, self, "setVisibleFunctionTables:withRange:", raw_data(visibleFunctionTables), range)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BinaryArchive
Class Methods:
Methods:
	addComputePipelineFunctionsWithDescriptor
	addRenderPipelineFunctionsWithDescriptor
	addTileRenderPipelineFunctionsWithDescriptor
	device
	label
	serializeToURL
	setLabel
*/
@(objc_class="MTLBinaryArchive")
BinaryArchive :: struct { using _: NS.Copying(BinaryArchive) }

@(objc_type=BinaryArchive, objc_name="addComputePipelineFunctionsWithDescriptor")
BinaryArchive_addComputePipelineFunctionsWithDescriptor :: #force_inline proc(self: ^BinaryArchive, descriptor: ^ComputePipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addComputePipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="addRenderPipelineFunctionsWithDescriptor")
BinaryArchive_addRenderPipelineFunctionsWithDescriptor :: #force_inline proc(self: ^BinaryArchive, descriptor: ^RenderPipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addRenderPipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="addTileRenderPipelineFunctionsWithDescriptor")
BinaryArchive_addTileRenderPipelineFunctionsWithDescriptor :: #force_inline proc(self: ^BinaryArchive, descriptor: ^TileRenderPipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addTileRenderPipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="device")
BinaryArchive_device :: #force_inline proc(self: ^BinaryArchive) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=BinaryArchive, objc_name="label")
BinaryArchive_label :: #force_inline proc(self: ^BinaryArchive) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=BinaryArchive, objc_name="serializeToURL")
BinaryArchive_serializeToURL :: #force_inline proc(self: ^BinaryArchive, url: ^NS.URL) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "serializeToURL:error:", url, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="setLabel")
BinaryArchive_setLabel :: #force_inline proc(self: ^BinaryArchive, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}


@(objc_type=BinaryArchive, objc_name="addFunction")
BinaryArchive_addFunction :: #force_inline proc(self: ^BinaryArchive, descriptor: ^FunctionDescriptor, library: ^Library) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addFunction:", descriptor, library, &error)
	return
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	BlitCommandEncoder
Class Methods:
Methods:
	copyFromBuffer
	copyFromBuffer
	copyFromBuffer
	copyFromTexture
	copyFromTexture
	copyFromTexture
	copyFromTexture
	copyFromTexture
	copyIndirectCommandBuffer
	fillBuffer
	generateMipmapsForTexture
	getTextureAccessCounters
	optimizeContentsForCPUAccess
	optimizeContentsForCPUAccess
	optimizeContentsForGPUAccess
	optimizeContentsForGPUAccess
	optimizeIndirectCommandBuffer
	resetCommandsInBuffer
	resetTextureAccessCounters
	resolveCounters
	sampleCountersInBuffer
	synchronizeResource
	synchronizeTexture
	updateFence
	waitForFence
*/
@(objc_class="MTLBlitCommandEncoder")
BlitCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=BlitCommandEncoder, objc_name="copyFromBufferEx")
BlitCommandEncoder_copyFromBufferEx :: #force_inline proc(self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, sourceBytesPerRow: NS.UInteger, sourceBytesPerImage: NS.UInteger, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBufferExWithOptions")
BlitCommandEncoder_copyFromBufferExWithOptions :: #force_inline proc(self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, sourceBytesPerRow: NS.UInteger, sourceBytesPerImage: NS.UInteger, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin, options: BlitOption) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:options:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBuffer")
BlitCommandEncoder_copyFromBuffer :: #force_inline proc(self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, size: NS.UInteger) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:toBuffer:destinationOffset:size:", sourceBuffer, sourceOffset, destinationBuffer, destinationOffset, size)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureEx")
BlitCommandEncoder_copyFromTextureEx :: #force_inline proc(self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, destinationBytesPerRow: NS.UInteger, destinationBytesPerImage: NS.UInteger) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureExWithOptions")
BlitCommandEncoder_copyFromTextureExWithOptions :: #force_inline proc(self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, destinationBytesPerRow: NS.UInteger, destinationBytesPerImage: NS.UInteger, options: BlitOption) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:options:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureWithDestinationOrigin")
BlitCommandEncoder_copyFromTextureWithDestinationOrigin :: #force_inline proc(self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureWithCounts")
BlitCommandEncoder_copyFromTextureWithCounts :: #force_inline proc(self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, sliceCount: NS.UInteger, levelCount: NS.UInteger) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:toTexture:destinationSlice:destinationLevel:sliceCount:levelCount:", sourceTexture, sourceSlice, sourceLevel, destinationTexture, destinationSlice, destinationLevel, sliceCount, levelCount)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture")
BlitCommandEncoder_copyFromTexture :: #force_inline proc(self: ^BlitCommandEncoder, sourceTexture: ^Texture, destinationTexture: ^Texture) {
	msgSend(nil, self, "copyFromTexture:toTexture:", sourceTexture, destinationTexture)
}
@(objc_type=BlitCommandEncoder, objc_name="copyIndirectCommandBuffer")
BlitCommandEncoder_copyIndirectCommandBuffer :: #force_inline proc(self: ^BlitCommandEncoder, source: ^IndirectCommandBuffer, sourceRange: NS.Range, destination: ^IndirectCommandBuffer, destinationIndex: NS.UInteger) {
	msgSend(nil, self, "copyIndirectCommandBuffer:sourceRange:destination:destinationIndex:", source, sourceRange, destination, destinationIndex)
}
@(objc_type=BlitCommandEncoder, objc_name="fillBuffer")
BlitCommandEncoder_fillBuffer :: #force_inline proc(self: ^BlitCommandEncoder, buffer: ^Buffer, range: NS.Range, value: u8) {
	msgSend(nil, self, "fillBuffer:range:value:", buffer, range, value)
}
@(objc_type=BlitCommandEncoder, objc_name="generateMipmapsForTexture")
BlitCommandEncoder_generateMipmapsForTexture :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "generateMipmapsForTexture:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="getTextureAccessCounters")
BlitCommandEncoder_getTextureAccessCounters :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger, resetCounters: BOOL, countersBuffer: ^Buffer, countersBufferOffset: NS.UInteger) {
	msgSend(nil, self, "getTextureAccessCounters:region:mipLevel:slice:resetCounters:countersBuffer:countersBufferOffset:", texture, region, mipLevel, slice, resetCounters, countersBuffer, countersBufferOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccess")
BlitCommandEncoder_optimizeContentsForCPUAccess :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccessWithSliceAndLevel")
BlitCommandEncoder_optimizeContentsForCPUAccessWithSliceAndLevel :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccess")
BlitCommandEncoder_optimizeContentsForGPUAccess :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccessWithSliceAndLevel")
BlitCommandEncoder_optimizeContentsForGPUAccessWithSliceAndLevel :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeIndirectCommandBuffer")
BlitCommandEncoder_optimizeIndirectCommandBuffer :: #force_inline proc(self: ^BlitCommandEncoder, indirectCommandBuffer: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "optimizeIndirectCommandBuffer:withRange:", indirectCommandBuffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetCommandsInBuffer")
BlitCommandEncoder_resetCommandsInBuffer :: #force_inline proc(self: ^BlitCommandEncoder, buffer: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "resetCommandsInBuffer:withRange:", buffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetTextureAccessCounters")
BlitCommandEncoder_resetTextureAccessCounters :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "resetTextureAccessCounters:region:mipLevel:slice:", texture, region, mipLevel, slice)
}
@(objc_type=BlitCommandEncoder, objc_name="resolveCounters")
BlitCommandEncoder_resolveCounters :: #force_inline proc(self: ^BlitCommandEncoder, sampleBuffer: ^Buffer, range: NS.Range, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger) {
	msgSend(nil, self, "resolveCounters:inRange:destinationBuffer:destinationOffset:", sampleBuffer, range, destinationBuffer, destinationOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="sampleCountersInBuffer")
BlitCommandEncoder_sampleCountersInBuffer :: #force_inline proc(self: ^BlitCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeResource")
BlitCommandEncoder_synchronizeResource :: #force_inline proc(self: ^BlitCommandEncoder, resource: ^Resource) {
	msgSend(nil, self, "synchronizeResource:", resource)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeTexture")
BlitCommandEncoder_synchronizeTexture :: #force_inline proc(self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "synchronizeTexture:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="updateFence")
BlitCommandEncoder_updateFence :: #force_inline proc(self: ^BlitCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=BlitCommandEncoder, objc_name="waitForFence")
BlitCommandEncoder_waitForFence :: #force_inline proc(self: ^BlitCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Buffer
Class Methods:
Methods:
	addDebugMarker
	contents
	didModifyRange
	length
	newRemoteBufferViewForDevice
	newTextureWithDescriptor
	remoteStorageBuffer
	removeAllDebugMarkers
*/
@(objc_class="MTLBuffer")
Buffer :: struct { using _: Resource }

@(objc_type=Buffer, objc_name="addDebugMarker")
Buffer_addDebugMarker :: #force_inline proc(self: ^Buffer, marker: ^NS.String, range: NS.Range) {
	msgSend(nil, self, "addDebugMarker:range:", marker, range)
}
@(objc_type=Buffer, objc_name="contents")
Buffer_contents :: #force_inline proc(self: ^Buffer) -> []byte {
	contents := msgSend([^]byte, self, "contents")
	length := Buffer_length(self)
	return contents[:length]
}
@(objc_type=Buffer, objc_name="contentsPointer")
Buffer_contentsPointer :: #force_inline proc(self: ^Buffer) -> rawptr {
	return msgSend([^]byte, self, "contents")
}
@(objc_type=Buffer, objc_name="didModifyRange")
Buffer_didModifyRange :: #force_inline proc(self: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "didModifyRange:", range)
}
@(objc_type=Buffer, objc_name="length")
Buffer_length :: #force_inline proc(self: ^Buffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "length")
}
@(objc_type=Buffer, objc_name="newRemoteBufferViewForDevice")
Buffer_newRemoteBufferViewForDevice :: #force_inline proc(self: ^Buffer, device: ^Device) -> ^Buffer {
	return msgSend(^Buffer, self, "newRemoteBufferViewForDevice:", device)
}
@(objc_type=Buffer, objc_name="newTextureWithDescriptor")
Buffer_newTextureWithDescriptor :: #force_inline proc(self: ^Buffer, descriptor: ^TextureDescriptor, offset: NS.UInteger, bytesPerRow: NS.UInteger) -> ^Buffer {
	return msgSend(^Buffer, self, "newTextureWithDescriptor:offset:bytesPerRow:", descriptor, offset, bytesPerRow)
}
@(objc_type=Buffer, objc_name="remoteStorageBuffer")
Buffer_remoteStorageBuffer :: #force_inline proc(self: ^Buffer) -> ^Buffer {
	return msgSend(^Buffer, self, "remoteStorageBuffer")
}
@(objc_type=Buffer, objc_name="removeAllDebugMarkers")
Buffer_removeAllDebugMarkers :: #force_inline proc(self: ^Buffer) {
	msgSend(nil, self, "removeAllDebugMarkers")
}

@(objc_type=Buffer, objc_name="newTexture")
Buffer_newTexture :: #force_inline proc(self: ^Buffer, descriptor: ^TextureDescriptor, offset: NS.UInteger, bytesPerRow: NS.UInteger) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:offset:bytesPerRow:")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CaptureScope
Class Methods:
Methods:
	beginScope
	commandQueue
	device
	endScope
	label
	setLabel
*/
@(objc_class="MTLCaptureScope")
CaptureScope :: struct { using _: NS.Object }

@(objc_type=CaptureScope, objc_name="beginScope")
CaptureScope_beginScope :: #force_inline proc(self: ^CaptureScope) {
	msgSend(nil, self, "beginScope")
}
@(objc_type=CaptureScope, objc_name="commandQueue")
CaptureScope_commandQueue :: #force_inline proc(self: ^CaptureScope) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandQueue")
}
@(objc_type=CaptureScope, objc_name="device")
CaptureScope_device :: #force_inline proc(self: ^CaptureScope) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CaptureScope, objc_name="endScope")
CaptureScope_endScope :: #force_inline proc(self: ^CaptureScope) {
	msgSend(nil, self, "endScope")
}
@(objc_type=CaptureScope, objc_name="label")
CaptureScope_label :: #force_inline proc(self: ^CaptureScope) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CaptureScope, objc_name="setLabel")
CaptureScope_setLabel :: #force_inline proc(self: ^CaptureScope, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CommandBuffer
Class Methods:
Methods:
	GPUEndTime
	GPUStartTime
	accelerationStructureCommandEncoder
	addCompletedHandler
	addScheduledHandler
	blitCommandEncoder
	blitCommandEncoderWithDescriptor
	commandQueue
	commit
	computeCommandEncoder
	computeCommandEncoderWithDescriptor
	computeCommandEncoderWithDispatchType
	device
	encodeSignalEvent
	encodeWaitForEvent
	enqueue
	error
	errorOptions
	kernelEndTime
	kernelStartTime
	label
	logs
	parallelRenderCommandEncoderWithDescriptor
	popDebugGroup
	presentDrawable
	presentDrawable
	presentDrawable
	pushDebugGroup
	renderCommandEncoderWithDescriptor
	resourceStateCommandEncoder
	resourceStateCommandEncoderWithDescriptor
	retainedReferences
	setLabel
	status
	waitUntilCompleted
	waitUntilScheduled
*/
@(objc_class="MTLCommandBuffer")
CommandBuffer :: struct { using _: NS.Object }

@(objc_type=CommandBuffer, objc_name="GPUEndTime")
CommandBuffer_GPUEndTime :: #force_inline proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUEndTime")
}
@(objc_type=CommandBuffer, objc_name="GPUStartTime")
CommandBuffer_GPUStartTime :: #force_inline proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUStartTime")
}
@(objc_type=CommandBuffer, objc_name="accelerationStructureCommandEncoder")
CommandBuffer_accelerationStructureCommandEncoder :: #force_inline proc(self: ^CommandBuffer) -> ^AccelerationStructureCommandEncoder {
	return msgSend(^AccelerationStructureCommandEncoder, self, "accelerationStructureCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="addCompletedHandler")
CommandBuffer_addCompletedHandler :: #force_inline proc(self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addCompletedHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="addScheduledHandler")
CommandBuffer_addScheduledHandler :: #force_inline proc(self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addScheduledHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoder")
CommandBuffer_blitCommandEncoder :: #force_inline proc(self: ^CommandBuffer) -> ^BlitCommandEncoder {
	return msgSend(^BlitCommandEncoder, self, "blitCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoderWithDescriptor")
CommandBuffer_blitCommandEncoderWithDescriptor :: #force_inline proc(self: ^CommandBuffer, blitPassDescriptor: ^BlitPassDescriptor) -> ^BlitCommandEncoder {
	return msgSend(^BlitCommandEncoder, self, "blitCommandEncoderWithDescriptor:", blitPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="commandQueue")
CommandBuffer_commandQueue :: #force_inline proc(self: ^CommandBuffer) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandQueue")
}
@(objc_type=CommandBuffer, objc_name="commit")
CommandBuffer_commit :: #force_inline proc(self: ^CommandBuffer) {
	msgSend(nil, self, "commit")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoder")
CommandBuffer_computeCommandEncoder :: #force_inline proc(self: ^CommandBuffer) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDescriptor")
CommandBuffer_computeCommandEncoderWithDescriptor :: #force_inline proc(self: ^CommandBuffer, computePassDescriptor: ^ComputePassDescriptor) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoderWithDescriptor:", computePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDispatchType")
CommandBuffer_computeCommandEncoderWithDispatchType :: #force_inline proc(self: ^CommandBuffer, dispatchType: DispatchType) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoderWithDispatchType:", dispatchType)
}
@(objc_type=CommandBuffer, objc_name="device")
CommandBuffer_device :: #force_inline proc(self: ^CommandBuffer) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandBuffer, objc_name="encodeSignalEvent")
CommandBuffer_encodeSignalEvent :: #force_inline proc(self: ^CommandBuffer, event: ^Event, value: u64) {
	msgSend(nil, self, "encodeSignalEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="encodeWaitForEvent")
CommandBuffer_encodeWaitForEvent :: #force_inline proc(self: ^CommandBuffer, event: ^Event, value: u64) {
	msgSend(nil, self, "encodeWaitForEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="enqueue")
CommandBuffer_enqueue :: #force_inline proc(self: ^CommandBuffer) {
	msgSend(nil, self, "enqueue")
}
@(objc_type=CommandBuffer, objc_name="error")
CommandBuffer_error :: #force_inline proc(self: ^CommandBuffer) -> ^NS.Error {
	return msgSend(^NS.Error, self, "error")
}
@(objc_type=CommandBuffer, objc_name="errorOptions")
CommandBuffer_errorOptions :: #force_inline proc(self: ^CommandBuffer) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBuffer, objc_name="kernelEndTime")
CommandBuffer_kernelEndTime :: #force_inline proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelEndTime")
}
@(objc_type=CommandBuffer, objc_name="kernelStartTime")
CommandBuffer_kernelStartTime :: #force_inline proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelStartTime")
}
@(objc_type=CommandBuffer, objc_name="label")
CommandBuffer_label :: #force_inline proc(self: ^CommandBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandBuffer, objc_name="logs")
CommandBuffer_logs :: #force_inline proc(self: ^CommandBuffer) -> ^LogContainer {
	return msgSend(^LogContainer, self, "logs")
}
@(objc_type=CommandBuffer, objc_name="parallelRenderCommandEncoderWithDescriptor")
CommandBuffer_parallelRenderCommandEncoderWithDescriptor :: #force_inline proc(self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^ParallelRenderCommandEncoder {
	return msgSend(^ParallelRenderCommandEncoder, self, "parallelRenderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="popDebugGroup")
CommandBuffer_popDebugGroup :: #force_inline proc(self: ^CommandBuffer) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandBuffer, objc_name="presentDrawable")
CommandBuffer_presentDrawable :: #force_inline proc(self: ^CommandBuffer, drawable: ^Drawable) {
	msgSend(nil, self, "presentDrawable:", drawable)
}
@(objc_type=CommandBuffer, objc_name="presentDrawableAfterMinimumDuration")
CommandBuffer_presentDrawableAfterMinimumDuration :: #force_inline proc(self: ^CommandBuffer, drawable: ^Drawable, duration: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:afterMinimumDuration:", drawable, duration)
}
@(objc_type=CommandBuffer, objc_name="presentDrawableAtTime")
CommandBuffer_presentDrawableAtTime :: #force_inline proc(self: ^CommandBuffer, drawable: ^Drawable, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:atTime:", drawable, presentationTime)
}
@(objc_type=CommandBuffer, objc_name="pushDebugGroup")
CommandBuffer_pushDebugGroup :: #force_inline proc(self: ^CommandBuffer, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandBuffer, objc_name="renderCommandEncoderWithDescriptor")
CommandBuffer_renderCommandEncoderWithDescriptor :: #force_inline proc(self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^RenderCommandEncoder {
	return msgSend(^RenderCommandEncoder, self, "renderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoder")
CommandBuffer_resourceStateCommandEncoder :: #force_inline proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "resourceStateCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoderWithDescriptor")
CommandBuffer_resourceStateCommandEncoderWithDescriptor :: #force_inline proc(self: ^CommandBuffer, resourceStatePassDescriptor: ^ResourceStatePassDescriptor) -> ^ResourceStateCommandEncoder {
	return msgSend(^ResourceStateCommandEncoder, self, "resourceStateCommandEncoderWithDescriptor:", resourceStatePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="retainedReferences")
CommandBuffer_retainedReferences :: #force_inline proc(self: ^CommandBuffer) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBuffer, objc_name="setLabel")
CommandBuffer_setLabel :: #force_inline proc(self: ^CommandBuffer, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CommandBuffer, objc_name="status")
CommandBuffer_status :: #force_inline proc(self: ^CommandBuffer) -> CommandBufferStatus {
	return msgSend(CommandBufferStatus, self, "status")
}
@(objc_type=CommandBuffer, objc_name="waitUntilCompleted")
CommandBuffer_waitUntilCompleted :: #force_inline proc(self: ^CommandBuffer) {
	msgSend(nil, self, "waitUntilCompleted")
}
@(objc_type=CommandBuffer, objc_name="waitUntilScheduled")
CommandBuffer_waitUntilScheduled :: #force_inline proc(self: ^CommandBuffer) {
	msgSend(nil, self, "waitUntilScheduled")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CommandBufferEncoderInfo
Class Methods:
Methods:
	debugSignposts
	errorState
	label
*/
@(objc_class="MTLCommandBufferEncoderInfo")
CommandBufferEncoderInfo :: struct { using _: NS.Object }

@(objc_type=CommandBufferEncoderInfo, objc_name="debugSignposts")
CommandBufferEncoderInfo_debugSignposts :: #force_inline proc(self: ^CommandBufferEncoderInfo) -> ^NS.Array {
	return msgSend(^NS.Array, self, "debugSignposts")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="errorState")
CommandBufferEncoderInfo_errorState :: #force_inline proc(self: ^CommandBufferEncoderInfo) -> CommandEncoderErrorState {
	return msgSend(CommandEncoderErrorState, self, "errorState")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="label")
CommandBufferEncoderInfo_label :: #force_inline proc(self: ^CommandBufferEncoderInfo) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CommandEncoder
Class Methods:
Methods:
	device
	endEncoding
	insertDebugSignpost
	label
	popDebugGroup
	pushDebugGroup
	setLabel
*/
@(objc_class="MTLCommandEncoder")
CommandEncoder :: struct { using _: NS.Object }

@(objc_type=CommandEncoder, objc_name="device")
CommandEncoder_device :: #force_inline proc(self: ^CommandEncoder) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandEncoder, objc_name="endEncoding")
CommandEncoder_endEncoding :: #force_inline proc(self: ^CommandEncoder) {
	msgSend(nil, self, "endEncoding")
}
@(objc_type=CommandEncoder, objc_name="insertDebugSignpost")
CommandEncoder_insertDebugSignpost :: #force_inline proc(self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "insertDebugSignpost:", string)
}
@(objc_type=CommandEncoder, objc_name="label")
CommandEncoder_label :: #force_inline proc(self: ^CommandEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandEncoder, objc_name="popDebugGroup")
CommandEncoder_popDebugGroup :: #force_inline proc(self: ^CommandEncoder) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandEncoder, objc_name="pushDebugGroup")
CommandEncoder_pushDebugGroup :: #force_inline proc(self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandEncoder, objc_name="setLabel")
CommandEncoder_setLabel :: #force_inline proc(self: ^CommandEncoder, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CommandQueue
Class Methods:
Methods:
	commandBuffer
	commandBufferWithDescriptor
	commandBufferWithUnretainedReferences
	device
	insertDebugCaptureBoundary
	label
	setLabel
*/
@(objc_class="MTLCommandQueue")
CommandQueue :: struct { using _: NS.Object }

@(objc_type=CommandQueue, objc_name="commandBuffer")
CommandQueue_commandBuffer :: #force_inline proc(self: ^CommandQueue) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "commandBuffer")
}
@(objc_type=CommandQueue, objc_name="commandBufferWithDescriptor")
CommandQueue_commandBufferWithDescriptor :: #force_inline proc(self: ^CommandQueue, descriptor: ^CommandBufferDescriptor) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandBufferWithDescriptor:", descriptor)
}
@(objc_type=CommandQueue, objc_name="commandBufferWithUnretainedReferences")
CommandQueue_commandBufferWithUnretainedReferences :: #force_inline proc(self: ^CommandQueue) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandBufferWithUnretainedReferences")
}
@(objc_type=CommandQueue, objc_name="device")
CommandQueue_device :: #force_inline proc(self: ^CommandQueue) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandQueue, objc_name="insertDebugCaptureBoundary")
CommandQueue_insertDebugCaptureBoundary :: #force_inline proc(self: ^CommandQueue) {
	msgSend(nil, self, "insertDebugCaptureBoundary")
}
@(objc_type=CommandQueue, objc_name="label")
CommandQueue_label :: #force_inline proc(self: ^CommandQueue) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandQueue, objc_name="setLabel")
CommandQueue_setLabel :: #force_inline proc(self: ^CommandQueue, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputeCommandEncoder
Class Methods:
Methods:
	dispatchThreadgroups
	dispatchThreadgroupsWithIndirectBuffer
	dispatchThreads
	dispatchType
	executeCommandsInBuffer
	executeCommandsInBuffer
	memoryBarrierWithResources
	memoryBarrierWithScope
	sampleCountersInBuffer
	setAccelerationStructure
	setBuffer
	setBufferOffset
	setBuffers
	setBytes
	setComputePipelineState
	setImageblockWidth
	setIntersectionFunctionTable
	setIntersectionFunctionTables
	setSamplerState
	setSamplerState
	setSamplerStates
	setSamplerStates
	setStageInRegion
	setStageInRegionWithIndirectBuffer
	setTexture
	setTextures
	setThreadgroupMemoryLength
	setVisibleFunctionTable
	setVisibleFunctionTables
	updateFence
	useHeap
	useHeaps
	useResource
	useResources
	waitForFence
*/
@(objc_class="MTLComputeCommandEncoder")
ComputeCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroups")
ComputeCommandEncoder_dispatchThreadgroups :: #force_inline proc(self: ^ComputeCommandEncoder, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroupsWithIndirectBuffer")
ComputeCommandEncoder_dispatchThreadgroupsWithIndirectBuffer :: #force_inline proc(self: ^ComputeCommandEncoder, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:", indirectBuffer, indirectBufferOffset, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreads")
ComputeCommandEncoder_dispatchThreads :: #force_inline proc(self: ^ComputeCommandEncoder, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchType")
ComputeCommandEncoder_dispatchType :: #force_inline proc(self: ^ComputeCommandEncoder) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBuffer")
ComputeCommandEncoder_executeCommandsInBuffer :: #force_inline proc(self: ^ComputeCommandEncoder, indirectCommandbuffer: ^Buffer, indirectRangeBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBufferWithRange")
ComputeCommandEncoder_executeCommandsInBufferWithRange :: #force_inline proc(self: ^ComputeCommandEncoder, indirectCommandBuffer: ^Buffer, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithResources")
ComputeCommandEncoder_memoryBarrierWithResources :: #force_inline proc(self: ^ComputeCommandEncoder, resources: []^Resource) {
	msgSend(nil, self, "memoryBarrierWithResources:count:", raw_data(resources), NS.UInteger(len(resources)))
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithScope")
ComputeCommandEncoder_memoryBarrierWithScope :: #force_inline proc(self: ^ComputeCommandEncoder, scope: BarrierScope) {
	msgSend(nil, self, "memoryBarrierWithScope:", scope)
}
@(objc_type=ComputeCommandEncoder, objc_name="sampleCountersInBuffer")
ComputeCommandEncoder_sampleCountersInBuffer :: #force_inline proc(self: ^ComputeCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=ComputeCommandEncoder, objc_name="setAccelerationStructure")
ComputeCommandEncoder_setAccelerationStructure :: #force_inline proc(self: ^ComputeCommandEncoder, accelerationStructure: ^AccelerationStructure, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setAccelerationStructure:atBufferIndex:", accelerationStructure, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffer")
ComputeCommandEncoder_setBuffer :: #force_inline proc(self: ^ComputeCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBufferOffset")
ComputeCommandEncoder_setBufferOffset :: #force_inline proc(self: ^ComputeCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBufferOffset:atIndex:", offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffers")
ComputeCommandEncoder_setBuffers :: #force_inline proc(self: ^ComputeCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	assert(range.length   <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBytes")
ComputeCommandEncoder_setBytes :: #force_inline proc(self: ^ComputeCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setComputePipelineState")
ComputeCommandEncoder_setComputePipelineState :: #force_inline proc(self: ^ComputeCommandEncoder, pipelineState: ^ComputePipelineState) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=ComputeCommandEncoder, objc_name="setImageblockWidth")
ComputeCommandEncoder_setImageblockWidth :: #force_inline proc(self: ^ComputeCommandEncoder, width: NS.UInteger, height: NS.UInteger) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTable")
ComputeCommandEncoder_setIntersectionFunctionTable :: #force_inline proc(self: ^ComputeCommandEncoder, intersectionFunctionTable: ^IntersectionFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTable:atBufferIndex:", intersectionFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTables")
ComputeCommandEncoder_setIntersectionFunctionTables :: #force_inline proc(self: ^ComputeCommandEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length   <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withBufferRange:", raw_data(intersectionFunctionTables), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStateAtIndex")
ComputeCommandEncoder_setSamplerStateAtIndex :: #force_inline proc(self: ^ComputeCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerState_lodMinClamp_lodMaxClampAtIndex")
ComputeCommandEncoder_setSamplerState_lodMinClamp_lodMaxClampAtIndex :: #force_inline proc(self: ^ComputeCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStates_lodMinClamps_lodMaxClampsWithRange")
ComputeCommandEncoder_setSamplerStates_lodMinClamps_lodMaxClampsWithRange :: #force_inline proc(self: ^ComputeCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStatesWithRange")
ComputeCommandEncoder_setSamplerStatesWithRange :: #force_inline proc(self: ^ComputeCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegion")
ComputeCommandEncoder_setStageInRegion :: #force_inline proc(self: ^ComputeCommandEncoder, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegionWithIndirectBuffer")
ComputeCommandEncoder_setStageInRegionWithIndirectBuffer :: #force_inline proc(self: ^ComputeCommandEncoder, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setStageInRegionWithIndirectBuffer:indirectBufferOffset:", indirectBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTexture")
ComputeCommandEncoder_setTexture :: #force_inline proc(self: ^ComputeCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTextures")
ComputeCommandEncoder_setTextures :: #force_inline proc(self: ^ComputeCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setThreadgroupMemoryLength")
ComputeCommandEncoder_setThreadgroupMemoryLength :: #force_inline proc(self: ^ComputeCommandEncoder, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:atIndex:", length, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTable")
ComputeCommandEncoder_setVisibleFunctionTable :: #force_inline proc(self: ^ComputeCommandEncoder, visibleFunctionTable: ^VisibleFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTables")
ComputeCommandEncoder_setVisibleFunctionTables :: #force_inline proc(self: ^ComputeCommandEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", raw_data(visibleFunctionTables), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="updateFence")
ComputeCommandEncoder_updateFence :: #force_inline proc(self: ^ComputeCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeap")
ComputeCommandEncoder_useHeap :: #force_inline proc(self: ^ComputeCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeaps")
ComputeCommandEncoder_useHeaps :: #force_inline proc(self: ^ComputeCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}
@(objc_type=ComputeCommandEncoder, objc_name="useResource")
ComputeCommandEncoder_useResource :: #force_inline proc(self: ^ComputeCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="useResources")
ComputeCommandEncoder_useResources :: #force_inline proc(self: ^ComputeCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="waitForFence")
ComputeCommandEncoder_waitForFence :: #force_inline proc(self: ^ComputeCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ComputePipelineState
Class Methods:
Methods:
	device
	functionHandleWithFunction
	imageblockMemoryLengthForDimensions
	label
	maxTotalThreadsPerThreadgroup
	newComputePipelineStateWithAdditionalBinaryFunctions
	newIntersectionFunctionTableWithDescriptor
	newVisibleFunctionTableWithDescriptor
	staticThreadgroupMemoryLength
	supportIndirectCommandBuffers
	threadExecutionWidth
*/
@(objc_class="MTLComputePipelineState")
ComputePipelineState :: struct { using _: NS.Object }

@(objc_type=ComputePipelineState, objc_name="device")
ComputePipelineState_device :: #force_inline proc(self: ^ComputePipelineState) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "device")
}
@(objc_type=ComputePipelineState, objc_name="functionHandleWithFunction")
ComputePipelineState_functionHandleWithFunction :: #force_inline proc(self: ^ComputePipelineState, function: ^Function) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "functionHandleWithFunction:", function)
}
@(objc_type=ComputePipelineState, objc_name="imageblockMemoryLengthForDimensions")
ComputePipelineState_imageblockMemoryLengthForDimensions :: #force_inline proc(self: ^ComputePipelineState, imageblockDimensions: Size) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=ComputePipelineState, objc_name="label")
ComputePipelineState_label :: #force_inline proc(self: ^ComputePipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineState, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineState_maxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineState, objc_name="newComputePipelineStateWithAdditionalBinaryFunctions")
ComputePipelineState_newComputePipelineStateWithAdditionalBinaryFunctions :: #force_inline proc(self: ^ComputePipelineState, functions: ^NS.Array) -> (state: ^ComputePipelineState, error: ^NS.Error) {
	state = msgSend(^ComputePipelineState, self, "newComputePipelineStateWithAdditionalBinaryFunctions:error:", functions, &error)
	return
}
@(objc_type=ComputePipelineState, objc_name="newIntersectionFunctionTableWithDescriptor")
ComputePipelineState_newIntersectionFunctionTableWithDescriptor :: #force_inline proc(self: ^ComputePipelineState, descriptor: ^IntersectionFunctionTableDescriptor) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newIntersectionFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="newVisibleFunctionTableWithDescriptor")
ComputePipelineState_newVisibleFunctionTableWithDescriptor :: #force_inline proc(self: ^ComputePipelineState, descriptor: ^VisibleFunctionTableDescriptor) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newVisibleFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="staticThreadgroupMemoryLength")
ComputePipelineState_staticThreadgroupMemoryLength :: #force_inline proc(self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "staticThreadgroupMemoryLength")
}
@(objc_type=ComputePipelineState, objc_name="supportIndirectCommandBuffers")
ComputePipelineState_supportIndirectCommandBuffers :: #force_inline proc(self: ^ComputePipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineState, objc_name="threadExecutionWidth")
ComputePipelineState_threadExecutionWidth :: #force_inline proc(self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadExecutionWidth")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Counter
Class Methods:
Methods:
	name
*/
@(objc_class="MTLCounter")
Counter :: struct { using _: NS.Object }

@(objc_type=Counter, objc_name="name")
Counter_name :: #force_inline proc(self: ^Counter) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CounterSampleBuffer
Class Methods:
Methods:
	device
	label
	resolveCounterRange
	sampleCount
*/
@(objc_class="MTLCounterSampleBuffer")
CounterSampleBuffer :: struct { using _: NS.Object }

@(objc_type=CounterSampleBuffer, objc_name="device")
CounterSampleBuffer_device :: #force_inline proc(self: ^CounterSampleBuffer) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "device")
}
@(objc_type=CounterSampleBuffer, objc_name="label")
CounterSampleBuffer_label :: #force_inline proc(self: ^CounterSampleBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBuffer, objc_name="resolveCounterRange")
CounterSampleBuffer_resolveCounterRange :: #force_inline proc(self: ^CounterSampleBuffer, range: NS.Range) -> ^NS.Data {
	return msgSend(^NS.Data, self, "resolveCounterRange:", range)
}
@(objc_type=CounterSampleBuffer, objc_name="sampleCount")
CounterSampleBuffer_sampleCount :: #force_inline proc(self: ^CounterSampleBuffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	CounterSet
Class Methods:
Methods:
	counters
	name
*/
@(objc_class="MTLCounterSet")
CounterSet :: struct { using _: NS.Object }

@(objc_type=CounterSet, objc_name="counters")
CounterSet_counters :: #force_inline proc(self: ^CounterSet) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counters")
}
@(objc_type=CounterSet, objc_name="name")
CounterSet_name :: #force_inline proc(self: ^CounterSet) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	DepthStencilState
Class Methods:
Methods:
	device
	label
*/
@(objc_class="MTLDepthStencilState")
DepthStencilState :: struct { using _: NS.Object }

@(objc_type=DepthStencilState, objc_name="device")
DepthStencilState_device :: #force_inline proc(self: ^DepthStencilState) -> ^DepthStencilState {
	return msgSend(^DepthStencilState, self, "device")
}
@(objc_type=DepthStencilState, objc_name="label")
DepthStencilState_label :: #force_inline proc(self: ^DepthStencilState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Device
Class Methods:
Methods:
	accelerationStructureSizesWithDescriptor
	areBarycentricCoordsSupported
	areProgrammableSamplePositionsSupported
	areRasterOrderGroupsSupported
	argumentBuffersSupport
	convertSparsePixelRegions
	convertSparseTileRegions
	counterSets
	currentAllocatedSize
	getDefaultSamplePositions
	hasUnifiedMemory
	heapBufferSizeAndAlignWithLength
	heapTextureSizeAndAlignWithDescriptor
	isDepth24Stencil8PixelFormatSupported
	isHeadless
	isLowPower
	isRemovable
	location
	locationNumber
	maxArgumentBufferSamplerCount
	maxBufferLength
	maxThreadgroupMemoryLength
	maxThreadsPerThreadgroup
	maxTransferRate
	minimumLinearTextureAlignmentForPixelFormat
	minimumTextureBufferAlignmentForPixelFormat
	name
	newAccelerationStructureWithDescriptor
	newAccelerationStructureWithSize
	newArgumentEncoderWithArguments
	newBinaryArchiveWithDescriptor
	newBufferWithBytes
	newBufferWithBytesNoCopy
	newBufferWithLength
	newCommandQueue
	newCommandQueueWithMaxCommandBufferCount
	newComputePipelineStateWithDescriptor
	newComputePipelineStateWithDescriptor
	newComputePipelineStateWithFunction
	newComputePipelineStateWithFunction
	newComputePipelineStateWithFunction
	newComputePipelineStateWithFunction
	newCounterSampleBufferWithDescriptor
	newDefaultLibrary
	newDefaultLibraryWithBundle
	newDepthStencilStateWithDescriptor
	newDynamicLibrary
	newDynamicLibraryWithURL
	newEvent
	newFence
	newHeapWithDescriptor
	newIndirectCommandBufferWithDescriptor
	newLibraryWithData
	newLibraryWithFile
	newLibraryWithSource
	newLibraryWithSource
	newLibraryWithURL
	newRasterizationRateMapWithDescriptor
	newRenderPipelineStateWithDescriptor
	newRenderPipelineStateWithDescriptor
	newRenderPipelineStateWithDescriptor
	newRenderPipelineStateWithDescriptor
	newRenderPipelineStateWithTileDescriptor
	newRenderPipelineStateWithTileDescriptor
	newSamplerState
	newSharedEvent
	newSharedEventWithHandle
	newSharedTextureWithDescriptor
	newSharedTextureWithHandle
	newTextureWithDescriptor
	newTextureWithDescriptor
	peerCount
	peerGroupID
	peerIndex
	readWriteTextureSupport
	recommendedMaxWorkingSetSize
	registryID
	sampleTimestamps
	sparseTileSizeInBytes
	sparseTileSizeWithTextureType
	supports32BitFloatFiltering
	supports32BitMSAA
	supportsBCTextureCompression
	supportsCounterSampling
	supportsDynamicLibraries
	supportsFamily
	supportsFeatureSet
	supportsFunctionPointers
	supportsPullModelInterpolation
	supportsQueryTextureLOD
	supportsRasterizationRateMapWithLayerCount
	supportsRaytracing
	supportsShaderBarycentricCoordinates
	supportsTextureSampleCount
	supportsVertexAmplificationCount
*/
@(objc_class="MTLDevice")
Device :: struct { using _: NS.Object }

@(objc_type=Device, objc_name="accelerationStructureSizesWithDescriptor")
Device_accelerationStructureSizesWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> AccelerationStructureSizes {
	return msgSend(AccelerationStructureSizes, self, "accelerationStructureSizesWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="areBarycentricCoordsSupported")
Device_areBarycentricCoordsSupported :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areBarycentricCoordsSupported")
}
@(objc_type=Device, objc_name="areProgrammableSamplePositionsSupported")
Device_areProgrammableSamplePositionsSupported :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areProgrammableSamplePositionsSupported")
}
@(objc_type=Device, objc_name="areRasterOrderGroupsSupported")
Device_areRasterOrderGroupsSupported :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areRasterOrderGroupsSupported")
}
@(objc_type=Device, objc_name="argumentBuffersSupport")
Device_argumentBuffersSupport :: #force_inline proc(self: ^Device) -> ArgumentBuffersTier {
	return msgSend(ArgumentBuffersTier, self, "argumentBuffersSupport")
}
@(objc_type=Device, objc_name="convertSparsePixelRegions")
Device_convertSparsePixelRegions :: #force_inline proc(self: ^Device, pixelRegions: ^Region, tileRegions: ^Region, tileSize: Size, mode: SparseTextureRegionAlignmentMode, numRegions: NS.UInteger) {
	msgSend(nil, self, "convertSparsePixelRegions:toTileRegions:withTileSize:alignmentMode:numRegions:", pixelRegions, tileRegions, tileSize, mode, numRegions)
}
@(objc_type=Device, objc_name="convertSparseTileRegions")
Device_convertSparseTileRegions :: #force_inline proc(self: ^Device, tileRegions: ^Region, pixelRegions: ^Region, tileSize: Size, numRegions: NS.UInteger) {
	msgSend(nil, self, "convertSparseTileRegions:toPixelRegions:withTileSize:numRegions:", tileRegions, pixelRegions, tileSize, numRegions)
}
@(objc_type=Device, objc_name="counterSets")
Device_counterSets :: #force_inline proc(self: ^Device) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counterSets")
}
@(objc_type=Device, objc_name="currentAllocatedSize")
Device_currentAllocatedSize :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "currentAllocatedSize")
}
@(objc_type=Device, objc_name="getDefaultSamplePositions")
Device_getDefaultSamplePositions :: #force_inline proc(self: ^Device, positions: ^SamplePosition, count: NS.UInteger) {
	msgSend(nil, self, "getDefaultSamplePositions:count:", positions, count)
}
@(objc_type=Device, objc_name="hasUnifiedMemory")
Device_hasUnifiedMemory :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "hasUnifiedMemory")
}
@(objc_type=Device, objc_name="heapBufferSizeAndAlignWithLength")
Device_heapBufferSizeAndAlignWithLength :: #force_inline proc(self: ^Device, length: NS.UInteger, options: ResourceOptions) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "heapBufferSizeAndAlignWithLength:options:", length, options)
}
@(objc_type=Device, objc_name="heapTextureSizeAndAlignWithDescriptor")
Device_heapTextureSizeAndAlignWithDescriptor :: #force_inline proc(self: ^Device, desc: ^TextureDescriptor) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "heapTextureSizeAndAlignWithDescriptor:", desc)
}
@(objc_type=Device, objc_name="isDepth24Stencil8PixelFormatSupported")
Device_isDepth24Stencil8PixelFormatSupported :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isDepth24Stencil8PixelFormatSupported")
}
@(objc_type=Device, objc_name="isHeadless")
Device_isHeadless :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isHeadless")
}
@(objc_type=Device, objc_name="isLowPower")
Device_isLowPower :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isLowPower")
}
@(objc_type=Device, objc_name="isRemovable")
Device_isRemovable :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isRemovable")
}
@(objc_type=Device, objc_name="location")
Device_location :: #force_inline proc(self: ^Device) -> DeviceLocation {
	return msgSend(DeviceLocation, self, "location")
}
@(objc_type=Device, objc_name="locationNumber")
Device_locationNumber :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "locationNumber")
}
@(objc_type=Device, objc_name="maxArgumentBufferSamplerCount")
Device_maxArgumentBufferSamplerCount :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxArgumentBufferSamplerCount")
}
@(objc_type=Device, objc_name="maxBufferLength")
Device_maxBufferLength :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxBufferLength")
}
@(objc_type=Device, objc_name="maxThreadgroupMemoryLength")
Device_maxThreadgroupMemoryLength :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxThreadgroupMemoryLength")
}
@(objc_type=Device, objc_name="maxThreadsPerThreadgroup")
Device_maxThreadsPerThreadgroup :: #force_inline proc(self: ^Device) -> Size {
	return msgSend(Size, self, "maxThreadsPerThreadgroup")
}
@(objc_type=Device, objc_name="maxTransferRate")
Device_maxTransferRate :: #force_inline proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "maxTransferRate")
}
@(objc_type=Device, objc_name="minimumLinearTextureAlignmentForPixelFormat")
Device_minimumLinearTextureAlignmentForPixelFormat :: #force_inline proc(self: ^Device, format: PixelFormat) -> ^Device {
	return msgSend(^Device, self, "minimumLinearTextureAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="minimumTextureBufferAlignmentForPixelFormat")
Device_minimumTextureBufferAlignmentForPixelFormat :: #force_inline proc(self: ^Device, format: PixelFormat) -> ^Device {
	return msgSend(^Device, self, "minimumTextureBufferAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="name")
Device_name :: #force_inline proc(self: ^Device) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Device, objc_name="newAccelerationStructureWithDescriptor")
Device_newAccelerationStructureWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newAccelerationStructureWithSize")
Device_newAccelerationStructureWithSize :: #force_inline proc(self: ^Device, size: NS.UInteger) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithSize:", size)
}
@(objc_type=Device, objc_name="newArgumentEncoderWithArguments")
Device_newArgumentEncoderWithArguments :: #force_inline proc(self: ^Device, arguments: ^NS.Array) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderWithArguments:", arguments)
}
@(objc_type=Device, objc_name="newBinaryArchiveWithDescriptor")
Device_newBinaryArchiveWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^BinaryArchiveDescriptor) -> (res: ^BinaryArchive, error: ^NS.Error) {
	res = msgSend(^BinaryArchive, self, "newBinaryArchiveWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newBufferWithBytes")
Device_newBufferWithBytes :: #force_inline proc(self: ^Device, pointer: rawptr, length: NS.UInteger, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytes:length:options:", pointer, length, options)
}
@(objc_type=Device, objc_name="newBufferWithBytesNoCopy")
Device_newBufferWithBytesNoCopy :: #force_inline proc(self: ^Device, pointer: rawptr, length: NS.UInteger, options: ResourceOptions, deallocator: rawptr) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytesNoCopy:length:options:deallocator:", pointer, length, options, deallocator)
}
@(objc_type=Device, objc_name="newBufferWithLength")
Device_newBufferWithLength :: #force_inline proc(self: ^Device, length: NS.UInteger, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithLength:options:", length, options)
}
@(objc_type=Device, objc_name="newCommandQueue")
Device_newCommandQueue :: #force_inline proc(self: ^Device) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "newCommandQueue")
}
@(objc_type=Device, objc_name="newCommandQueueWithMaxCommandBufferCount")
Device_newCommandQueueWithMaxCommandBufferCount :: #force_inline proc(self: ^Device, maxCommandBufferCount: NS.UInteger) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "newCommandQueueWithMaxCommandBufferCount:", maxCommandBufferCount)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptorWithCompletionHandler")
Device_newComputePipelineStateWithDescriptorWithCompletionHandler :: #force_inline proc(self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptorWithReflection")
Device_newComputePipelineStateWithDescriptorWithReflection :: #force_inline proc(self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection) -> (device: ^Device, error: ^NS.Error) {
	device = msgSend(^Device, self, "newComputePipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithCompletionHandler")
Device_newComputePipelineStateWithFunctionWithCompletionHandler :: #force_inline proc(self: ^Device, computeFunction: ^Function, completionHandler: NewComputePipelineStateCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithFunction:completionHandler:", computeFunction, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction")
Device_newComputePipelineStateWithFunction :: #force_inline proc(self: ^Device, computeFunction: ^Function) -> (res: ^Device, error: ^NS.Error) {
	res = msgSend(^Device, self, "newComputePipelineStateWithFunction:error:", computeFunction, &error)
	return
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithOptionsAndCompletionHandler")
Device_newComputePipelineStateWithFunctionWithOptionsAndCompletionHandler :: #force_inline proc(self: ^Device, computeFunction: ^Function, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithFunction:options:completionHandler:", computeFunction, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithReflection")
Device_newComputePipelineStateWithFunctionWithReflection :: #force_inline proc(self: ^Device, computeFunction: ^Function, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection) -> (device: ^Device, error: ^NS.Error) {
	device = msgSend(^Device, self, "newComputePipelineStateWithFunction:options:reflection:error:", computeFunction, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newCounterSampleBufferWithDescriptor")
Device_newCounterSampleBufferWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^CounterSampleBufferDescriptor) -> (device: ^Device, error: ^NS.Error) {
	device = msgSend(^Device, self, "newCounterSampleBufferWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newDefaultLibrary")
Device_newDefaultLibrary :: #force_inline proc(self: ^Device) -> ^Library {
	return msgSend(^Library, self, "newDefaultLibrary")
}
@(objc_type=Device, objc_name="newDefaultLibraryWithBundle")
Device_newDefaultLibraryWithBundle :: #force_inline proc(self: ^Device, bundle: ^NS.Bundle) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newDefaultLibraryWithBundle:error:", bundle, &error)
	return
}
@(objc_type=Device, objc_name="newDepthStencilStateWithDescriptor")
Device_newDepthStencilStateWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^DepthStencilDescriptor) -> ^DepthStencilState {
	return msgSend(^DepthStencilState, self, "newDepthStencilStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newDynamicLibrary")
Device_newDynamicLibrary :: #force_inline proc(self: ^Device, library: ^Library) -> (dyn_library: ^DynamicLibrary, error: ^NS.Error) {
	dyn_library = msgSend(^DynamicLibrary, self, "newDynamicLibrary:error:", library, &error)
	return
}
@(objc_type=Device, objc_name="newDynamicLibraryWithURL")
Device_newDynamicLibraryWithURL :: #force_inline proc(self: ^Device, url: ^NS.URL) -> (dyn_library: ^DynamicLibrary, error: ^NS.Error) {
	dyn_library = msgSend(^DynamicLibrary, self, "newDynamicLibraryWithURL:error:", url, &error)
	return
}
@(objc_type=Device, objc_name="newEvent")
Device_newEvent :: #force_inline proc(self: ^Device) -> ^Event {
	return msgSend(^Event, self, "newEvent")
}
@(objc_type=Device, objc_name="newFence")
Device_newFence :: #force_inline proc(self: ^Device) -> ^Fence {
	return msgSend(^Fence, self, "newFence")
}
@(objc_type=Device, objc_name="newHeapWithDescriptor")
Device_newHeapWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^HeapDescriptor) -> ^Heap {
	return msgSend(^Heap, self, "newHeapWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newIndirectCommandBufferWithDescriptor")
Device_newIndirectCommandBufferWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^IndirectCommandBufferDescriptor, maxCount: NS.UInteger, options: ResourceOptions) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "newIndirectCommandBufferWithDescriptor:maxCommandCount:options:", descriptor, maxCount, options)
}
@(objc_type=Device, objc_name="newLibraryWithData")
Device_newLibraryWithData :: #force_inline proc(self: ^Device, data: dispatch_data_t) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithData:error:", data, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithFile")
Device_newLibraryWithFile :: #force_inline proc(self: ^Device, filepath: ^NS.String) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithFile:error:", filepath, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithSourceWithCompletionHandler")
Device_newLibraryWithSourceWithCompletionHandler :: #force_inline proc(self: ^Device, source: ^NS.String, options: ^CompileOptions, completionHandler: NewLibraryCompletionHandler) -> ^Library {
	return msgSend(^Library, self, "newLibraryWithSource:options:completionHandler:", source, options, completionHandler)
}
@(objc_type=Device, objc_name="newLibraryWithSource")
Device_newLibraryWithSource :: #force_inline proc(self: ^Device, source: ^NS.String, options: ^CompileOptions) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithSource:options:error:", source, options, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithURL")
Device_newLibraryWithURL :: #force_inline proc(self: ^Device, url: ^NS.URL) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithURL:error:", url, &error)
	return
}
@(objc_type=Device, objc_name="newRasterizationRateMapWithDescriptor")
Device_newRasterizationRateMapWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^RasterizationRateMapDescriptor) -> ^RasterizationRateMap {
	return msgSend(^RasterizationRateMap, self, "newRasterizationRateMapWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithCompletionHandler")
Device_newRenderPipelineStateWithDescriptorWithCompletionHandler :: #force_inline proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, completionHandler: NewRenderPipelineStateCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor")
Device_newRenderPipelineStateWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^RenderPipelineDescriptor) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithOptionsAndCompletionHandler")
Device_newRenderPipelineStateWithDescriptorWithOptionsAndCompletionHandler :: #force_inline proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithReflection")
Device_newRenderPipelineStateWithDescriptorWithReflection :: #force_inline proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptorWithCompletionHandler")
Device_newRenderPipelineStateWithTileDescriptorWithCompletionHandler :: #force_inline proc(self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithTileDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptorWithReflection")
Device_newRenderPipelineStateWithTileDescriptorWithReflection :: #force_inline proc(self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithTileDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newSamplerStateWithDescriptor")
Device_newSamplerState :: #force_inline proc(self: ^Device, descriptor: ^SamplerDescriptor) -> ^SamplerState {
	return msgSend(^SamplerState, self, "newSamplerStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedEvent")
Device_newSharedEvent :: #force_inline proc(self: ^Device) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedEvent")
}
@(objc_type=Device, objc_name="newSharedEventWithHandle")
Device_newSharedEventWithHandle :: #force_inline proc(self: ^Device, sharedEventHandle: ^SharedEventHandle) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedEventWithHandle:", sharedEventHandle)
}
@(objc_type=Device, objc_name="newSharedTextureWithDescriptor")
Device_newSharedTextureWithDescriptor :: #force_inline proc(self: ^Device, descriptor: ^TextureDescriptor) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedTextureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedTextureWithHandle")
Device_newSharedTextureWithHandle :: #force_inline proc(self: ^Device, sharedHandle: ^SharedTextureHandle) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedTextureWithHandle:", sharedHandle)
}
@(objc_type=Device, objc_name="newTextureWithDescriptor")
Device_newTextureWithDescriptor :: #force_inline proc(self: ^Device, desc: ^TextureDescriptor) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Device, objc_name="newTextureWithDescriptorWithIOSurface")
Device_newTextureWithDescriptorWithIOSurface :: #force_inline proc(self: ^Device, descriptor: ^TextureDescriptor, iosurface: IOSurfaceRef, plane: NS.UInteger) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:iosurface:plane:", descriptor, iosurface, plane)
}
@(objc_type=Device, objc_name="peerCount")
Device_peerCount :: #force_inline proc(self: ^Device) -> u32 {
	return msgSend(u32, self, "peerCount")
}
@(objc_type=Device, objc_name="peerGroupID")
Device_peerGroupID :: #force_inline proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "peerGroupID")
}
@(objc_type=Device, objc_name="peerIndex")
Device_peerIndex :: #force_inline proc(self: ^Device) -> u32 {
	return msgSend(u32, self, "peerIndex")
}
@(objc_type=Device, objc_name="readWriteTextureSupport")
Device_readWriteTextureSupport :: #force_inline proc(self: ^Device) -> ReadWriteTextureTier {
	return msgSend(ReadWriteTextureTier, self, "readWriteTextureSupport")
}
@(objc_type=Device, objc_name="recommendedMaxWorkingSetSize")
Device_recommendedMaxWorkingSetSize :: #force_inline proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "recommendedMaxWorkingSetSize")
}
@(objc_type=Device, objc_name="registryID")
Device_registryID :: #force_inline proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "registryID")
}
@(objc_type=Device, objc_name="sampleTimestamps")
Device_sampleTimestamps :: #force_inline proc(self: ^Device, cpuTimestamp: ^Timestamp, gpuTimestamp: ^Timestamp) {
	msgSend(nil, self, "sampleTimestamps:gpuTimestamp:", cpuTimestamp, gpuTimestamp)
}
@(objc_type=Device, objc_name="sparseTileSizeInBytes")
Device_sparseTileSizeInBytes :: #force_inline proc(self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sparseTileSizeInBytes")
}
@(objc_type=Device, objc_name="sparseTileSizeWithTextureType")
Device_sparseTileSizeWithTextureType :: #force_inline proc(self: ^Device, textureType: TextureType, pixelFormat: PixelFormat, sampleCount: NS.UInteger) -> Size {
	return msgSend(Size, self, "sparseTileSizeWithTextureType:pixelFormat:sampleCount:", textureType, pixelFormat, sampleCount)
}
@(objc_type=Device, objc_name="supports32BitFloatFiltering")
Device_supports32BitFloatFiltering :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitFloatFiltering")
}
@(objc_type=Device, objc_name="supports32BitMSAA")
Device_supports32BitMSAA :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitMSAA")
}
@(objc_type=Device, objc_name="supportsBCTextureCompression")
Device_supportsBCTextureCompression :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsBCTextureCompression")
}
@(objc_type=Device, objc_name="supportsCounterSampling")
Device_supportsCounterSampling :: #force_inline proc(self: ^Device, samplingPoint: CounterSamplingPoint) -> BOOL {
	return msgSend(BOOL, self, "supportsCounterSampling:", samplingPoint)
}
@(objc_type=Device, objc_name="supportsDynamicLibraries")
Device_supportsDynamicLibraries :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsDynamicLibraries")
}
@(objc_type=Device, objc_name="supportsFamily")
Device_supportsFamily :: #force_inline proc(self: ^Device, gpuFamily: GPUFamily) -> BOOL {
	return msgSend(BOOL, self, "supportsFamily:", gpuFamily)
}
@(objc_type=Device, objc_name="supportsFeatureSet")
Device_supportsFeatureSet :: #force_inline proc(self: ^Device, featureSet: FeatureSet) -> BOOL {
	return msgSend(BOOL, self, "supportsFeatureSet:", featureSet)
}
@(objc_type=Device, objc_name="supportsFunctionPointers")
Device_supportsFunctionPointers :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsFunctionPointers")
}
@(objc_type=Device, objc_name="supportsPullModelInterpolation")
Device_supportsPullModelInterpolation :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsPullModelInterpolation")
}
@(objc_type=Device, objc_name="supportsQueryTextureLOD")
Device_supportsQueryTextureLOD :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsQueryTextureLOD")
}
@(objc_type=Device, objc_name="supportsRasterizationRateMapWithLayerCount")
Device_supportsRasterizationRateMapWithLayerCount :: #force_inline proc(self: ^Device, layerCount: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsRasterizationRateMapWithLayerCount:", layerCount)
}
@(objc_type=Device, objc_name="supportsRaytracing")
Device_supportsRaytracing :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsRaytracing")
}
@(objc_type=Device, objc_name="supportsShaderBarycentricCoordinates")
Device_supportsShaderBarycentricCoordinates :: #force_inline proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsShaderBarycentricCoordinates")
}
@(objc_type=Device, objc_name="supportsTextureSampleCount")
Device_supportsTextureSampleCount :: #force_inline proc(self: ^Device, sampleCount: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsTextureSampleCount:", sampleCount)
}
@(objc_type=Device, objc_name="supportsVertexAmplificationCount")
Device_supportsVertexAmplificationCount :: #force_inline proc(self: ^Device, count: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsVertexAmplificationCount:", count)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Drawable
Class Methods:
Methods:
	addPresentedHandler
	drawableID
	present
	presentAfterMinimumDuration
	presentAtTime
	presentedTime
*/
@(objc_class="MTLDrawable")
Drawable :: struct { using _: NS.Object }

@(objc_type=Drawable, objc_name="addPresentedHandler")
Drawable_addPresentedHandler :: #force_inline proc(self: ^Drawable, block: DrawablePresentedHandler) {
	msgSend(nil, self, "addPresentedHandler:", block)
}
@(objc_type=Drawable, objc_name="drawableID")
Drawable_drawableID :: #force_inline proc(self: ^Drawable) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "drawableID")
}
@(objc_type=Drawable, objc_name="present")
Drawable_present :: #force_inline proc(self: ^Drawable) {
	msgSend(nil, self, "present")
}
@(objc_type=Drawable, objc_name="presentAfterMinimumDuration")
Drawable_presentAfterMinimumDuration :: #force_inline proc(self: ^Drawable, duration: CFTimeInterval) {
	msgSend(nil, self, "presentAfterMinimumDuration:", duration)
}
@(objc_type=Drawable, objc_name="presentAtTime")
Drawable_presentAtTime :: #force_inline proc(self: ^Drawable, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentAtTime:", presentationTime)
}
@(objc_type=Drawable, objc_name="presentedTime")
Drawable_presentedTime :: #force_inline proc(self: ^Drawable) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "presentedTime")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	DynamicLibrary
Class Methods:
Methods:
	device
	installName
	label
	serializeToURL
	setLabel
*/
@(objc_class="MTLDynamicLibrary")
DynamicLibrary :: struct { using _: NS.Object }

@(objc_type=DynamicLibrary, objc_name="device")
DynamicLibrary_device :: #force_inline proc(self: ^DynamicLibrary) -> ^DynamicLibrary {
	return msgSend(^DynamicLibrary, self, "device")
}
@(objc_type=DynamicLibrary, objc_name="installName")
DynamicLibrary_installName :: #force_inline proc(self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=DynamicLibrary, objc_name="label")
DynamicLibrary_label :: #force_inline proc(self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DynamicLibrary, objc_name="serializeToURL")
DynamicLibrary_serializeToURL :: #force_inline proc(self: ^DynamicLibrary, url: ^NS.URL) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "serializeToURL:error:", url, &error)
	return
}
@(objc_type=DynamicLibrary, objc_name="setLabel")
DynamicLibrary_setLabel :: #force_inline proc(self: ^DynamicLibrary, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Event
Class Methods:
Methods:
	device
	label
	setLabel
*/
@(objc_class="MTLEvent")
Event :: struct { using _: NS.Object }

@(objc_type=Event, objc_name="device")
Event_device :: #force_inline proc(self: ^Event) -> ^Event {
	return msgSend(^Event, self, "device")
}
@(objc_type=Event, objc_name="label")
Event_label :: #force_inline proc(self: ^Event) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Event, objc_name="setLabel")
Event_setLabel :: #force_inline proc(self: ^Event, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Fence
Class Methods:
Methods:
	device
	label
	setLabel
*/
@(objc_class="MTLFence")
Fence :: struct { using _: NS.Object }

@(objc_type=Fence, objc_name="device")
Fence_device :: #force_inline proc(self: ^Fence) -> ^Fence {
	return msgSend(^Fence, self, "device")
}
@(objc_type=Fence, objc_name="label")
Fence_label :: #force_inline proc(self: ^Fence) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Fence, objc_name="setLabel")
Fence_setLabel :: #force_inline proc(self: ^Fence, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Function
Class Methods:
Methods:
	device
	functionConstantsDictionary
	functionType
	label
	name
	newArgumentEncoderWithBufferIndex
	newArgumentEncoderWithBufferIndex
	options
	patchControlPointCount
	patchType
	setLabel
	stageInputAttributes
	vertexAttributes
*/
@(objc_class="MTLFunction")
Function :: struct { using _: NS.Object }

@(objc_type=Function, objc_name="device")
Function_device :: #force_inline proc(self: ^Function) -> ^Function {
	return msgSend(^Function, self, "device")
}
@(objc_type=Function, objc_name="functionConstantsDictionary")
Function_functionConstantsDictionary :: #force_inline proc(self: ^Function) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "functionConstantsDictionary")
}
@(objc_type=Function, objc_name="functionType")
Function_functionType :: #force_inline proc(self: ^Function) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=Function, objc_name="label")
Function_label :: #force_inline proc(self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Function, objc_name="name")
Function_name :: #force_inline proc(self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Function, objc_name="newArgumentEncoderWithBufferIndex")
Function_newArgumentEncoderWithBufferIndex :: #force_inline proc(self: ^Function, bufferIndex: NS.UInteger) -> ^Function {
	return msgSend(^Function, self, "newArgumentEncoderWithBufferIndex:", bufferIndex)
}
@(objc_type=Function, objc_name="newArgumentEncoderWithBufferIndexWithReflection")
Function_newArgumentEncoderWithBufferIndexWithReflection :: #force_inline proc(self: ^Function, bufferIndex: NS.UInteger, reflection: ^AutoreleasedArgument) -> ^Function {
	return msgSend(^Function, self, "newArgumentEncoderWithBufferIndex:reflection:", bufferIndex, reflection)
}
@(objc_type=Function, objc_name="options")
Function_options :: #force_inline proc(self: ^Function) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=Function, objc_name="patchControlPointCount")
Function_patchControlPointCount :: #force_inline proc(self: ^Function) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "patchControlPointCount")
}
@(objc_type=Function, objc_name="patchType")
Function_patchType :: #force_inline proc(self: ^Function) -> PatchType {
	return msgSend(PatchType, self, "patchType")
}
@(objc_type=Function, objc_name="setLabel")
Function_setLabel :: #force_inline proc(self: ^Function, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Function, objc_name="stageInputAttributes")
Function_stageInputAttributes :: #force_inline proc(self: ^Function) -> ^NS.Array {
	return msgSend(^NS.Array, self, "stageInputAttributes")
}
@(objc_type=Function, objc_name="vertexAttributes")
Function_vertexAttributes :: #force_inline proc(self: ^Function) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexAttributes")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionHandle
Class Methods:
Methods:
	device
	functionType
	name
*/
@(objc_class="MTLFunctionHandle")
FunctionHandle :: struct { using _: NS.Object }

@(objc_type=FunctionHandle, objc_name="device")
FunctionHandle_device :: #force_inline proc(self: ^FunctionHandle) -> ^FunctionHandle {
	return msgSend(^FunctionHandle, self, "device")
}
@(objc_type=FunctionHandle, objc_name="functionType")
FunctionHandle_functionType :: #force_inline proc(self: ^FunctionHandle) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=FunctionHandle, objc_name="name")
FunctionHandle_name :: #force_inline proc(self: ^FunctionHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	LogContainer
*/

@(objc_class="MTLLogContainer")
LogContainer :: struct { using _: NS.FastEnumeration }

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionLog
Class Methods:
Methods:
	debugLocation
	encoderLabel
	function
	type
*/
@(objc_class="MTLFunctionLog")
FunctionLog :: struct { using _: NS.Object }

@(objc_type=FunctionLog, objc_name="debugLocation")
FunctionLog_debugLocation :: #force_inline proc(self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "debugLocation")
}
@(objc_type=FunctionLog, objc_name="encoderLabel")
FunctionLog_encoderLabel :: #force_inline proc(self: ^FunctionLog) -> ^NS.String {
	return msgSend(^NS.String, self, "encoderLabel")
}
@(objc_type=FunctionLog, objc_name="function")
FunctionLog_function :: #force_inline proc(self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "function")
}
@(objc_type=FunctionLog, objc_name="type")
FunctionLog_type :: #force_inline proc(self: ^FunctionLog) -> FunctionLogType {
	return msgSend(FunctionLogType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	FunctionLogDebugLocation
Class Methods:
Methods:
	URL
	column
	functionName
	line
*/
@(objc_class="MTLFunctionLogDebugLocation")
FunctionLogDebugLocation :: struct { using _: NS.Object }

@(objc_type=FunctionLogDebugLocation, objc_name="URL")
FunctionLogDebugLocation_URL :: #force_inline proc(self: ^FunctionLogDebugLocation) -> ^NS.URL {
	return msgSend(^NS.URL, self, "URL")
}
@(objc_type=FunctionLogDebugLocation, objc_name="column")
FunctionLogDebugLocation_column :: #force_inline proc(self: ^FunctionLogDebugLocation) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "column")
}
@(objc_type=FunctionLogDebugLocation, objc_name="functionName")
FunctionLogDebugLocation_functionName :: #force_inline proc(self: ^FunctionLogDebugLocation) -> ^NS.String {
	return msgSend(^NS.String, self, "functionName")
}
@(objc_type=FunctionLogDebugLocation, objc_name="line")
FunctionLogDebugLocation_line :: #force_inline proc(self: ^FunctionLogDebugLocation) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "line")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Heap
Class Methods:
Methods:
	cpuCacheMode
	currentAllocatedSize
	device
	hazardTrackingMode
	label
	maxAvailableSizeWithAlignment
	newBufferWithLength
	newBufferWithLength
	newTextureWithDescriptor
	newTextureWithDescriptor
	resourceOptions
	setLabel
	setPurgeableState
	size
	storageMode
	type
	usedSize
*/
@(objc_class="MTLHeap")
Heap :: struct { using _: NS.Object }

@(objc_type=Heap, objc_name="cpuCacheMode")
Heap_cpuCacheMode :: #force_inline proc(self: ^Heap) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Heap, objc_name="currentAllocatedSize")
Heap_currentAllocatedSize :: #force_inline proc(self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "currentAllocatedSize")
}
@(objc_type=Heap, objc_name="device")
Heap_device :: #force_inline proc(self: ^Heap) -> ^Heap {
	return msgSend(^Heap, self, "device")
}
@(objc_type=Heap, objc_name="hazardTrackingMode")
Heap_hazardTrackingMode :: #force_inline proc(self: ^Heap) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Heap, objc_name="label")
Heap_label :: #force_inline proc(self: ^Heap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Heap, objc_name="maxAvailableSizeWithAlignment")
Heap_maxAvailableSizeWithAlignment :: #force_inline proc(self: ^Heap, alignment: NS.UInteger) -> ^Heap {
	return msgSend(^Heap, self, "maxAvailableSizeWithAlignment:", alignment)
}
@(objc_type=Heap, objc_name="newBufferWithLength")
Heap_newBufferWithLength :: #force_inline proc(self: ^Heap, length: NS.UInteger, options: ResourceOptions) -> ^Heap {
	return msgSend(^Heap, self, "newBufferWithLength:options:", length, options)
}
@(objc_type=Heap, objc_name="newBufferWithLengthWithOptions")
Heap_newBufferWithLengthWithOptions :: #force_inline proc(self: ^Heap, length: NS.UInteger, options: ResourceOptions, offset: NS.UInteger) -> ^Heap {
	return msgSend(^Heap, self, "newBufferWithLength:options:offset:", length, options, offset)
}
@(objc_type=Heap, objc_name="newTextureWithDescriptor")
Heap_newTextureWithDescriptor :: #force_inline proc(self: ^Heap, desc: ^TextureDescriptor) -> ^Heap {
	return msgSend(^Heap, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Heap, objc_name="newTextureWithDescriptorWithOffset")
Heap_newTextureWithDescriptorWithOffset :: #force_inline proc(self: ^Heap, descriptor: ^TextureDescriptor, offset: NS.UInteger) -> ^Heap {
	return msgSend(^Heap, self, "newTextureWithDescriptor:offset:", descriptor, offset)
}
@(objc_type=Heap, objc_name="resourceOptions")
Heap_resourceOptions :: #force_inline proc(self: ^Heap) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Heap, objc_name="setLabel")
Heap_setLabel :: #force_inline proc(self: ^Heap, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Heap, objc_name="setPurgeableState")
Heap_setPurgeableState :: #force_inline proc(self: ^Heap, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Heap, objc_name="size")
Heap_size :: #force_inline proc(self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}
@(objc_type=Heap, objc_name="storageMode")
Heap_storageMode :: #force_inline proc(self: ^Heap) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=Heap, objc_name="type")
Heap_type :: #force_inline proc(self: ^Heap) -> FunctionLogType {
	return msgSend(FunctionLogType, self, "type")
}
@(objc_type=Heap, objc_name="usedSize")
Heap_usedSize :: #force_inline proc(self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "usedSize")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IndirectCommandBuffer
Class Methods:
Methods:
	indirectComputeCommandAtIndex
	indirectRenderCommandAtIndex
	resetWithRange
	size
*/
@(objc_class="MTLIndirectCommandBuffer")
IndirectCommandBuffer :: struct { using _: Resource }

@(objc_type=IndirectCommandBuffer, objc_name="indirectComputeCommandAtIndex")
IndirectCommandBuffer_indirectComputeCommandAtIndex :: #force_inline proc(self: ^IndirectCommandBuffer, commandIndex: NS.UInteger) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "indirectComputeCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="indirectRenderCommandAtIndex")
IndirectCommandBuffer_indirectRenderCommandAtIndex :: #force_inline proc(self: ^IndirectCommandBuffer, commandIndex: NS.UInteger) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "indirectRenderCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="resetWithRange")
IndirectCommandBuffer_resetWithRange :: #force_inline proc(self: ^IndirectCommandBuffer, range: NS.Range) {
	msgSend(nil, self, "resetWithRange:", range)
}
@(objc_type=IndirectCommandBuffer, objc_name="size")
IndirectCommandBuffer_size :: #force_inline proc(self: ^IndirectCommandBuffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IndirectComputeCommand
Class Methods:
Methods:
	clearBarrier
	concurrentDispatchThreadgroups
	concurrentDispatchThreads
	reset
	setBarrier
	setComputePipelineState
	setImageblockWidth
	setKernelBuffer
	setStageInRegion
	setThreadgroupMemoryLength
*/
@(objc_class="MTLIndirectComputeCommand")
IndirectComputeCommand :: struct { using _: NS.Object }

@(objc_type=IndirectComputeCommand, objc_name="clearBarrier")
IndirectComputeCommand_clearBarrier :: #force_inline proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "clearBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreadgroups")
IndirectComputeCommand_concurrentDispatchThreadgroups :: #force_inline proc(self: ^IndirectComputeCommand, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreads")
IndirectComputeCommand_concurrentDispatchThreads :: #force_inline proc(self: ^IndirectComputeCommand, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="reset")
IndirectComputeCommand_reset :: #force_inline proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectComputeCommand, objc_name="setBarrier")
IndirectComputeCommand_setBarrier :: #force_inline proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "setBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="setComputePipelineState")
IndirectComputeCommand_setComputePipelineState :: #force_inline proc(self: ^IndirectComputeCommand, pipelineState: ^ComputePipelineState) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=IndirectComputeCommand, objc_name="setImageblockWidth")
IndirectComputeCommand_setImageblockWidth :: #force_inline proc(self: ^IndirectComputeCommand, width: NS.UInteger, height: NS.UInteger) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=IndirectComputeCommand, objc_name="setKernelBuffer")
IndirectComputeCommand_setKernelBuffer :: #force_inline proc(self: ^IndirectComputeCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setKernelBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectComputeCommand, objc_name="setStageInRegion")
IndirectComputeCommand_setStageInRegion :: #force_inline proc(self: ^IndirectComputeCommand, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=IndirectComputeCommand, objc_name="setThreadgroupMemoryLength")
IndirectComputeCommand_setThreadgroupMemoryLength :: #force_inline proc(self: ^IndirectComputeCommand, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:atIndex:", length, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IndirectRenderCommand
Class Methods:
Methods:
	drawIndexedPatches
	drawIndexedPrimitives
	drawPatches
	drawPrimitives
	reset
	setFragmentBuffer
	setRenderPipelineState
	setVertexBuffer
*/
@(objc_class="MTLIndirectRenderCommand")
IndirectRenderCommand :: struct { using _: NS.Object }

@(objc_type=IndirectRenderCommand, objc_name="drawIndexedPatches")
IndirectRenderCommand_drawIndexedPatches :: #force_inline proc(self: ^IndirectRenderCommand, numberOfPatchControlPoints: NS.UInteger, patchStart: NS.UInteger, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawIndexedPrimitives")
IndirectRenderCommand_drawIndexedPrimitives :: #force_inline proc(self: ^IndirectRenderCommand, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseVertex: NS.Integer, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPatches")
IndirectRenderCommand_drawPatches :: #force_inline proc(self: ^IndirectRenderCommand, numberOfPatchControlPoints: NS.UInteger, patchStart: NS.UInteger, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPrimitives")
IndirectRenderCommand_drawPrimitives :: #force_inline proc(self: ^IndirectRenderCommand, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger = 0, baseInstance: NS.UInteger = 0) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="reset")
IndirectRenderCommand_reset :: #force_inline proc(self: ^IndirectRenderCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectRenderCommand, objc_name="setFragmentBuffer")
IndirectRenderCommand_setFragmentBuffer :: #force_inline proc(self: ^IndirectRenderCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectRenderCommand, objc_name="setRenderPipelineState")
IndirectRenderCommand_setRenderPipelineState :: #force_inline proc(self: ^IndirectRenderCommand, pipelineState: ^RenderPipelineState) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=IndirectRenderCommand, objc_name="setVertexBuffer")
IndirectRenderCommand_setVertexBuffer :: #force_inline proc(self: ^IndirectRenderCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBuffer:offset:atIndex:", buffer, offset, index)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	IntersectionFunctionTable
Class Methods:
Methods:
	setBuffer
	setBuffers
	setFunction
	setFunctions
	setOpaqueTriangleIntersectionFunctionWithSignature
	setOpaqueTriangleIntersectionFunctionWithSignature
	setVisibleFunctionTable
	setVisibleFunctionTables
*/
@(objc_class="MTLIntersectionFunctionTable")
IntersectionFunctionTable :: struct { using _: Resource }

@(objc_type=IntersectionFunctionTable, objc_name="setBuffer")
IntersectionFunctionTable_setBuffer :: #force_inline proc(self: ^IntersectionFunctionTable, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setBuffers")
IntersectionFunctionTable_setBuffers :: #force_inline proc(self: ^IntersectionFunctionTable, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunction")
IntersectionFunctionTable_setFunction :: #force_inline proc(self: ^IntersectionFunctionTable, function: ^FunctionHandle, index: NS.UInteger) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunctions")
IntersectionFunctionTable_setFunctions :: #force_inline proc(self: ^IntersectionFunctionTable, functions: [^]^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", functions, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignatureAtIndex")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignatureAtIndex :: #force_inline proc(self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, index: NS.UInteger) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:atIndex:", signature, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignatureWithRange")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignatureWithRange :: #force_inline proc(self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, range: NS.Range) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:withRange:", signature, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTable")
IntersectionFunctionTable_setVisibleFunctionTable :: #force_inline proc(self: ^IntersectionFunctionTable, visibleFunctionTable: ^VisibleFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTables")
IntersectionFunctionTable_setVisibleFunctionTables :: #force_inline proc(self: ^IntersectionFunctionTable, visibleFunctionTables: [^]^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", visibleFunctionTables, range)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Library
Class Methods:
Methods:
	device
	functionNames
	installName
	label
	newFunctionWithDescriptor
	newFunctionWithDescriptor
	newFunctionWithName
	newFunctionWithName
	newFunctionWithName
	newIntersectionFunctionWithDescriptor
	newIntersectionFunctionWithDescriptor
	setLabel
	type
*/
@(objc_class="MTLLibrary")
Library :: struct { using _: NS.Object }

@(objc_type=Library, objc_name="device")
Library_device :: #force_inline proc(self: ^Library) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Library, objc_name="functionNames")
Library_functionNames :: #force_inline proc(self: ^Library) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functionNames")
}
@(objc_type=Library, objc_name="installName")
Library_installName :: #force_inline proc(self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=Library, objc_name="label")
Library_label :: #force_inline proc(self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Library, objc_name="newFunctionWithDescriptorWithCompletionHandler")
Library_newFunctionWithDescriptorWithCompletionHandler :: #force_inline proc(self: ^Library, descriptor: ^FunctionDescriptor, completionHandler: rawptr) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithDescriptor")
Library_newFunctionWithDescriptor :: #force_inline proc(self: ^Library, descriptor: ^FunctionDescriptor) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newFunctionWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Library, objc_name="newFunctionWithName")
Library_newFunctionWithName :: #force_inline proc(self: ^Library, functionName: ^NS.String) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithName:", functionName)
}
@(objc_type=Library, objc_name="newFunctionWithNameWithConstantValuesAndCompletionHandler")
Library_newFunctionWithNameWithConstantValuesAndCompletionHandler :: #force_inline proc(self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues, completionHandler: rawptr) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithName:constantValues:completionHandler:", name, constantValues, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithNameWithConstantValues")
Library_newFunctionWithNameWithConstantValues :: #force_inline proc(self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newFunctionWithName:constantValues:error:", name, constantValues, &error)
	return
}
@(objc_type=Library, objc_name="newIntersectionFunctionWithDescriptorWithCompletionHandler")
Library_newIntersectionFunctionWithDescriptorWithCompletionHandler :: #force_inline proc(self: ^Library, descriptor: ^IntersectionFunctionDescriptor, completionHandler: rawptr) -> ^Function {
	return msgSend(^Function, self, "newIntersectionFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newIntersectionFunctionWithDescriptor")
Library_newIntersectionFunctionWithDescriptor :: #force_inline proc(self: ^Library, descriptor: ^IntersectionFunctionDescriptor) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newIntersectionFunctionWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Library, objc_name="setLabel")
Library_setLabel :: #force_inline proc(self: ^Library, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Library, objc_name="type")
Library_type :: #force_inline proc(self: ^Library) -> LibraryType {
	return msgSend(LibraryType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ParallelRenderCommandEncoder
Class Methods:
Methods:
	renderCommandEncoder
	setColorStoreAction
	setColorStoreActionOptions
	setDepthStoreAction
	setDepthStoreActionOptions
	setStencilStoreAction
	setStencilStoreActionOptions
*/
@(objc_class="MTLParallelRenderCommandEncoder")
ParallelRenderCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ParallelRenderCommandEncoder, objc_name="renderCommandEncoder")
ParallelRenderCommandEncoder_renderCommandEncoder :: #force_inline proc(self: ^ParallelRenderCommandEncoder) -> ^ParallelRenderCommandEncoder {
	return msgSend(^ParallelRenderCommandEncoder, self, "renderCommandEncoder")
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreAction")
ParallelRenderCommandEncoder_setColorStoreAction :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreActionOptions")
ParallelRenderCommandEncoder_setColorStoreActionOptions :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreAction")
ParallelRenderCommandEncoder_setDepthStoreAction :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreActionOptions")
ParallelRenderCommandEncoder_setDepthStoreActionOptions :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreAction")
ParallelRenderCommandEncoder_setStencilStoreAction :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreActionOptions")
ParallelRenderCommandEncoder_setStencilStoreActionOptions :: #force_inline proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStencilStoreActionOptions:", storeActionOptions)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RasterizationRateMap
Class Methods:
Methods:
	copyParameterDataToBuffer
	device
	label
	layerCount
	mapPhysicalToScreenCoordinates
	mapScreenToPhysicalCoordinates
	parameterBufferSizeAndAlign
	physicalGranularity
	physicalSizeForLayer
	screenSize
*/
@(objc_class="MTLRasterizationRateMap")
RasterizationRateMap :: struct { using _: NS.Object }

@(objc_type=RasterizationRateMap, objc_name="copyParameterDataToBuffer")
RasterizationRateMap_copyParameterDataToBuffer :: #force_inline proc(self: ^RasterizationRateMap, buffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "copyParameterDataToBuffer:offset:", buffer, offset)
}
@(objc_type=RasterizationRateMap, objc_name="device")
RasterizationRateMap_device :: #force_inline proc(self: ^RasterizationRateMap) -> ^RasterizationRateMap {
	return msgSend(^RasterizationRateMap, self, "device")
}
@(objc_type=RasterizationRateMap, objc_name="label")
RasterizationRateMap_label :: #force_inline proc(self: ^RasterizationRateMap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMap, objc_name="layerCount")
RasterizationRateMap_layerCount :: #force_inline proc(self: ^RasterizationRateMap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "layerCount")
}
@(objc_type=RasterizationRateMap, objc_name="mapPhysicalToScreenCoordinates")
RasterizationRateMap_mapPhysicalToScreenCoordinates :: #force_inline proc(self: ^RasterizationRateMap, physicalCoordinates: Coordinate2D, layerIndex: NS.UInteger) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapPhysicalToScreenCoordinates:forLayer:", physicalCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="mapScreenToPhysicalCoordinates")
RasterizationRateMap_mapScreenToPhysicalCoordinates :: #force_inline proc(self: ^RasterizationRateMap, screenCoordinates: Coordinate2D, layerIndex: NS.UInteger) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapScreenToPhysicalCoordinates:forLayer:", screenCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="parameterBufferSizeAndAlign")
RasterizationRateMap_parameterBufferSizeAndAlign :: #force_inline proc(self: ^RasterizationRateMap) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "parameterBufferSizeAndAlign")
}
@(objc_type=RasterizationRateMap, objc_name="physicalGranularity")
RasterizationRateMap_physicalGranularity :: #force_inline proc(self: ^RasterizationRateMap) -> Size {
	return msgSend(Size, self, "physicalGranularity")
}
@(objc_type=RasterizationRateMap, objc_name="physicalSizeForLayer")
RasterizationRateMap_physicalSizeForLayer :: #force_inline proc(self: ^RasterizationRateMap, layerIndex: NS.UInteger) -> Size {
	return msgSend(Size, self, "physicalSizeForLayer:", layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="screenSize")
RasterizationRateMap_screenSize :: #force_inline proc(self: ^RasterizationRateMap) -> Size {
	return msgSend(Size, self, "screenSize")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderCommandEncoder
Class Methods:
Methods:
	dispatchThreadsPerTile
	drawIndexedPatches
	drawIndexedPatches
	drawIndexedPrimitives
	drawIndexedPrimitives
	drawIndexedPrimitives
	drawIndexedPrimitives
	drawPatches
	drawPatches
	drawPrimitives
	drawPrimitives
	drawPrimitives
	drawPrimitives
	executeCommandsInBuffer
	executeCommandsInBuffer
	memoryBarrierWithResources
	memoryBarrierWithScope
	sampleCountersInBuffer
	setBlendColorRed
	setColorStoreAction
	setColorStoreActionOptions
	setCullMode
	setDepthBias
	setDepthClipMode
	setDepthStencilState
	setDepthStoreAction
	setDepthStoreActionOptions
	setFragmentBuffer
	setFragmentBufferOffset
	setFragmentBuffers
	setFragmentBytes
	setFragmentSamplerState
	setFragmentSamplerState
	setFragmentSamplerStates
	setFragmentSamplerStates
	setFragmentTexture
	setFragmentTextures
	setFrontFacingWinding
	setRenderPipelineState
	setScissorRect
	setScissorRects
	setStencilFrontReferenceValue
	setStencilReferenceValue
	setStencilStoreAction
	setStencilStoreActionOptions
	setTessellationFactorBuffer
	setTessellationFactorScale
	setThreadgroupMemoryLength
	setTileBuffer
	setTileBufferOffset
	setTileBuffers
	setTileBytes
	setTileSamplerState
	setTileSamplerState
	setTileSamplerStates
	setTileSamplerStates
	setTileTexture
	setTileTextures
	setTriangleFillMode
	setVertexAmplificationCount
	setVertexBuffer
	setVertexBufferOffset
	setVertexBuffers
	setVertexBytes
	setVertexSamplerState
	setVertexSamplerState
	setVertexSamplerStates
	setVertexSamplerStates
	setVertexTexture
	setVertexTextures
	setViewport
	setViewports
	setVisibilityResultMode
	textureBarrier
	tileHeight
	tileWidth
	updateFence
	useHeap
	useHeap
	useHeaps
	useHeaps
	useResource
	useResource
	useResources
	useResources
	waitForFence
*/
@(objc_class="MTLRenderCommandEncoder")
RenderCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=RenderCommandEncoder, objc_name="dispatchThreadsPerTile")
RenderCommandEncoder_dispatchThreadsPerTile :: #force_inline proc(self: ^RenderCommandEncoder, threadsPerTile: Size) {
	msgSend(nil, self, "dispatchThreadsPerTile:", threadsPerTile)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_ :: #force_inline proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_")
RenderCommandEncoder_drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_ :: #force_inline proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchStart: NS.UInteger, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseVertex: NS.Integer, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexType:indexBuffer:indexBufferOffset:indirectBuffer:indirectBufferOffset:", primitiveType, indexType, indexBuffer, indexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_ :: #force_inline proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchIndexBuffer:patchIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_")
RenderCommandEncoder_drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_ :: #force_inline proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchStart: NS.UInteger, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawPrimitives_indirectBuffer_indirectBufferOffset_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:indirectBuffer:indirectBufferOffset:", primitiveType, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:", primitiveType, vertexStart, vertexCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_instanceCount_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_instanceCount_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:", primitiveType, vertexStart, vertexCount, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_ :: #force_inline proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBuffer")
RenderCommandEncoder_executeCommandsInBuffer :: #force_inline proc(self: ^RenderCommandEncoder, indirectCommandbuffer: ^Buffer, indirectRangeBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBufferWithRange")
RenderCommandEncoder_executeCommandsInBufferWithRange :: #force_inline proc(self: ^RenderCommandEncoder, indirectCommandBuffer: ^Buffer, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithResources")
RenderCommandEncoder_memoryBarrierWithResources :: #force_inline proc(self: ^RenderCommandEncoder, resources: [^]^Resource, count: NS.UInteger, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithResources:count:afterStages:beforeStages:", resources, count, after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithScope")
RenderCommandEncoder_memoryBarrierWithScope :: #force_inline proc(self: ^RenderCommandEncoder, scope: BarrierScope, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithScope:afterStages:beforeStages:", scope, after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="sampleCountersInBuffer")
RenderCommandEncoder_sampleCountersInBuffer :: #force_inline proc(self: ^RenderCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=RenderCommandEncoder, objc_name="setBlendColorRed")
RenderCommandEncoder_setBlendColorRed :: #force_inline proc(self: ^RenderCommandEncoder, red: f32, green: f32, blue: f32, alpha: f32) {
	msgSend(nil, self, "setBlendColorRed:green:blue:alpha:", red, green, blue, alpha)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreAction")
RenderCommandEncoder_setColorStoreAction :: #force_inline proc(self: ^RenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreActionOptions")
RenderCommandEncoder_setColorStoreActionOptions :: #force_inline proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setCullMode")
RenderCommandEncoder_setCullMode :: #force_inline proc(self: ^RenderCommandEncoder, cullMode: CullMode) {
	msgSend(nil, self, "setCullMode:", cullMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthBias")
RenderCommandEncoder_setDepthBias :: #force_inline proc(self: ^RenderCommandEncoder, depthBias: f32, slopeScale: f32, clamp: f32) {
	msgSend(nil, self, "setDepthBias:slopeScale:clamp:", depthBias, slopeScale, clamp)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthClipMode")
RenderCommandEncoder_setDepthClipMode :: #force_inline proc(self: ^RenderCommandEncoder, depthClipMode: DepthClipMode) {
	msgSend(nil, self, "setDepthClipMode:", depthClipMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStencilState")
RenderCommandEncoder_setDepthStencilState :: #force_inline proc(self: ^RenderCommandEncoder, depthStencilState: ^DepthStencilState) {
	msgSend(nil, self, "setDepthStencilState:", depthStencilState)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreAction")
RenderCommandEncoder_setDepthStoreAction :: #force_inline proc(self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreActionOptions")
RenderCommandEncoder_setDepthStoreActionOptions :: #force_inline proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffer")
RenderCommandEncoder_setFragmentBuffer :: #force_inline proc(self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBufferOffset")
RenderCommandEncoder_setFragmentBufferOffset :: #force_inline proc(self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffers")
RenderCommandEncoder_setFragmentBuffers :: #force_inline proc(self: ^RenderCommandEncoder, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setFragmentBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBytes")
RenderCommandEncoder_setFragmentBytes :: #force_inline proc(self: ^RenderCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStateAtIndex")
RenderCommandEncoder_setFragmentSamplerStateAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerState_lodMinClamp_lodMaxClampAtIndex")
RenderCommandEncoder_setFragmentSamplerState_lodMinClamp_lodMaxClampAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStates_lodMinClamps_lodMaxClampsWithRange")
RenderCommandEncoder_setFragmentSamplerStates_lodMinClamps_lodMaxClampsWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStatesWithRange")
RenderCommandEncoder_setFragmentSamplerStatesWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTexture")
RenderCommandEncoder_setFragmentTexture :: #force_inline proc(self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTextures")
RenderCommandEncoder_setFragmentTextures :: #force_inline proc(self: ^RenderCommandEncoder, textures: [^]^Texture, range: NS.Range) {
	msgSend(nil, self, "setFragmentTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFrontFacingWinding")
RenderCommandEncoder_setFrontFacingWinding :: #force_inline proc(self: ^RenderCommandEncoder, frontFacingWinding: Winding) {
	msgSend(nil, self, "setFrontFacingWinding:", frontFacingWinding)
}
@(objc_type=RenderCommandEncoder, objc_name="setRenderPipelineState")
RenderCommandEncoder_setRenderPipelineState :: #force_inline proc(self: ^RenderCommandEncoder, pipelineState: ^RenderPipelineState) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRect")
RenderCommandEncoder_setScissorRect :: #force_inline proc(self: ^RenderCommandEncoder, rect: ScissorRect) {
	msgSend(nil, self, "setScissorRect:", rect)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRects")
RenderCommandEncoder_setScissorRects :: #force_inline proc(self: ^RenderCommandEncoder, scissorRects: ^ScissorRect, count: NS.UInteger) {
	msgSend(nil, self, "setScissorRects:count:", scissorRects, count)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilFrontReferenceValue")
RenderCommandEncoder_setStencilFrontReferenceValue :: #force_inline proc(self: ^RenderCommandEncoder, frontReferenceValue: u32, backReferenceValue: u32) {
	msgSend(nil, self, "setStencilFrontReferenceValue:backReferenceValue:", frontReferenceValue, backReferenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilReferenceValue")
RenderCommandEncoder_setStencilReferenceValue :: #force_inline proc(self: ^RenderCommandEncoder, referenceValue: u32) {
	msgSend(nil, self, "setStencilReferenceValue:", referenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreAction")
RenderCommandEncoder_setStencilStoreAction :: #force_inline proc(self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreActionOptions")
RenderCommandEncoder_setStencilStoreActionOptions :: #force_inline proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStencilStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorBuffer")
RenderCommandEncoder_setTessellationFactorBuffer :: #force_inline proc(self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "setTessellationFactorBuffer:offset:instanceStride:", buffer, offset, instanceStride)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorScale")
RenderCommandEncoder_setTessellationFactorScale :: #force_inline proc(self: ^RenderCommandEncoder, scale: f32) {
	msgSend(nil, self, "setTessellationFactorScale:", scale)
}
@(objc_type=RenderCommandEncoder, objc_name="setThreadgroupMemoryLength")
RenderCommandEncoder_setThreadgroupMemoryLength :: #force_inline proc(self: ^RenderCommandEncoder, length: NS.UInteger, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:offset:atIndex:", length, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffer")
RenderCommandEncoder_setTileBuffer :: #force_inline proc(self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setTileBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBufferOffset")
RenderCommandEncoder_setTileBufferOffset :: #force_inline proc(self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setTileBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffers")
RenderCommandEncoder_setTileBuffers :: #force_inline proc(self: ^RenderCommandEncoder, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setTileBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBytes")
RenderCommandEncoder_setTileBytes :: #force_inline proc(self: ^RenderCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setTileBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStateAtIndex")
RenderCommandEncoder_setTileSamplerStateAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setTileSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerState_lodMinClamp_lodMaxClampAtIndex")
RenderCommandEncoder_setTileSamplerState_lodMinClamp_lodMaxClampAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setTileSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStates_lodMinClamps_lodMaxClampsWithRange")
RenderCommandEncoder_setTileSamplerStates_lodMinClamps_lodMaxClampsWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStatesWithRange")
RenderCommandEncoder_setTileSamplerStatesWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTexture")
RenderCommandEncoder_setTileTexture :: #force_inline proc(self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTileTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTextures")
RenderCommandEncoder_setTileTextures :: #force_inline proc(self: ^RenderCommandEncoder, textures: [^]^Texture, range: NS.Range) {
	msgSend(nil, self, "setTileTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTriangleFillMode")
RenderCommandEncoder_setTriangleFillMode :: #force_inline proc(self: ^RenderCommandEncoder, fillMode: TriangleFillMode) {
	msgSend(nil, self, "setTriangleFillMode:", fillMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexAmplificationCount")
RenderCommandEncoder_setVertexAmplificationCount :: #force_inline proc(self: ^RenderCommandEncoder, count: NS.UInteger, viewMappings: ^VertexAmplificationViewMapping) {
	msgSend(nil, self, "setVertexAmplificationCount:viewMappings:", count, viewMappings)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffer")
RenderCommandEncoder_setVertexBuffer :: #force_inline proc(self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBufferOffset")
RenderCommandEncoder_setVertexBufferOffset :: #force_inline proc(self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffers")
RenderCommandEncoder_setVertexBuffers :: #force_inline proc(self: ^RenderCommandEncoder, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setVertexBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBytes")
RenderCommandEncoder_setVertexBytes :: #force_inline proc(self: ^RenderCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStateAtIndex")
RenderCommandEncoder_setVertexSamplerStateAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setVertexSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerState_lodMinClamp_lodMaxClampAtIndex")
RenderCommandEncoder_setVertexSamplerState_lodMinClamp_lodMaxClampAtIndex :: #force_inline proc(self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setVertexSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStates_lodMinClamps_lodMaxClampsWithRange")
RenderCommandEncoder_setVertexSamplerStates_lodMinClamps_lodMaxClampsWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStatesWithRange")
RenderCommandEncoder_setVertexSamplerStatesWithRange :: #force_inline proc(self: ^RenderCommandEncoder, samplers: [^]^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTexture")
RenderCommandEncoder_setVertexTexture :: #force_inline proc(self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setVertexTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTextures")
RenderCommandEncoder_setVertexTextures :: #force_inline proc(self: ^RenderCommandEncoder, textures: [^]^Texture, range: NS.Range) {
	msgSend(nil, self, "setVertexTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewport")
RenderCommandEncoder_setViewport :: #force_inline proc(self: ^RenderCommandEncoder, viewport: Viewport) {
	msgSend(nil, self, "setViewport:", viewport)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewports")
RenderCommandEncoder_setViewports :: #force_inline proc(self: ^RenderCommandEncoder, viewports: ^Viewport, count: NS.UInteger) {
	msgSend(nil, self, "setViewports:count:", viewports, count)
}
@(objc_type=RenderCommandEncoder, objc_name="setVisibilityResultMode")
RenderCommandEncoder_setVisibilityResultMode :: #force_inline proc(self: ^RenderCommandEncoder, mode: VisibilityResultMode, offset: NS.UInteger) {
	msgSend(nil, self, "setVisibilityResultMode:offset:", mode, offset)
}
@(objc_type=RenderCommandEncoder, objc_name="textureBarrier")
RenderCommandEncoder_textureBarrier :: #force_inline proc(self: ^RenderCommandEncoder) {
	msgSend(nil, self, "textureBarrier")
}
@(objc_type=RenderCommandEncoder, objc_name="tileHeight")
RenderCommandEncoder_tileHeight :: #force_inline proc(self: ^RenderCommandEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileHeight")
}
@(objc_type=RenderCommandEncoder, objc_name="tileWidth")
RenderCommandEncoder_tileWidth :: #force_inline proc(self: ^RenderCommandEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileWidth")
}
@(objc_type=RenderCommandEncoder, objc_name="updateFence")
RenderCommandEncoder_updateFence :: #force_inline proc(self: ^RenderCommandEncoder, fence: ^Fence, stages: RenderStages) {
	msgSend(nil, self, "updateFence:afterStages:", fence, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeap")
RenderCommandEncoder_useHeap :: #force_inline proc(self: ^RenderCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeapWithStages")
RenderCommandEncoder_useHeapWithStages :: #force_inline proc(self: ^RenderCommandEncoder, heap: ^Heap, stages: RenderStages) {
	msgSend(nil, self, "useHeap:stages:", heap, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeaps")
RenderCommandEncoder_useHeaps :: #force_inline proc(self: ^RenderCommandEncoder, heaps: [^]^Heap, count: NS.UInteger) {
	msgSend(nil, self, "useHeaps:count:", heaps, count)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeapsWithStages")
RenderCommandEncoder_useHeapsWithStages :: #force_inline proc(self: ^RenderCommandEncoder, heaps: [^]^Heap, count: NS.UInteger, stages: RenderStages) {
	msgSend(nil, self, "useHeaps:count:stages:", heaps, count, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResource")
RenderCommandEncoder_useResource :: #force_inline proc(self: ^RenderCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResourceWithStages")
RenderCommandEncoder_useResourceWithStages :: #force_inline proc(self: ^RenderCommandEncoder, resource: ^Resource, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResource:usage:stages:", resource, usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResources")
RenderCommandEncoder_useResources :: #force_inline proc(self: ^RenderCommandEncoder, resources: [^]^Resource, count: NS.UInteger, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, count, usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResourcesStages")
RenderCommandEncoder_useResourcesStages :: #force_inline proc(self: ^RenderCommandEncoder, resources: [^]^Resource, count: NS.UInteger, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResources:count:usage:stages:", resources, count, usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="waitForFence")
RenderCommandEncoder_waitForFence :: #force_inline proc(self: ^RenderCommandEncoder, fence: ^Fence, stages: RenderStages) {
	msgSend(nil, self, "waitForFence:beforeStages:", fence, stages)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	RenderPipelineState
Class Methods:
Methods:
	device
	imageblockMemoryLengthForDimensions
	imageblockSampleLength
	label
	maxTotalThreadsPerThreadgroup
	supportIndirectCommandBuffers
	threadgroupSizeMatchesTileSize
*/
@(objc_class="MTLRenderPipelineState")
RenderPipelineState :: struct { using _: NS.Object }

@(objc_type=RenderPipelineState, objc_name="device")
RenderPipelineState_device :: #force_inline proc(self: ^RenderPipelineState) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "device")
}
@(objc_type=RenderPipelineState, objc_name="imageblockMemoryLengthForDimensions")
RenderPipelineState_imageblockMemoryLengthForDimensions :: #force_inline proc(self: ^RenderPipelineState, imageblockDimensions: Size) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=RenderPipelineState, objc_name="imageblockSampleLength")
RenderPipelineState_imageblockSampleLength :: #force_inline proc(self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "imageblockSampleLength")
}
@(objc_type=RenderPipelineState, objc_name="label")
RenderPipelineState_label :: #force_inline proc(self: ^RenderPipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineState, objc_name="maxTotalThreadsPerThreadgroup")
RenderPipelineState_maxTotalThreadsPerThreadgroup :: #force_inline proc(self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=RenderPipelineState, objc_name="supportIndirectCommandBuffers")
RenderPipelineState_supportIndirectCommandBuffers :: #force_inline proc(self: ^RenderPipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineState, objc_name="threadgroupSizeMatchesTileSize")
RenderPipelineState_threadgroupSizeMatchesTileSize :: #force_inline proc(self: ^RenderPipelineState) -> BOOL {
	return msgSend(BOOL, self, "threadgroupSizeMatchesTileSize")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Resource
Class Methods:
Methods:
	allocatedSize
	cpuCacheMode
	device
	hazardTrackingMode
	heap
	heapOffset
	isAliasable
	label
	makeAliasable
	resourceOptions
	setLabel
	setPurgeableState
	storageMode
*/
@(objc_class="MTLResource")
Resource :: struct { using _: NS.Object }

@(objc_type=Resource, objc_name="allocatedSize")
Resource_allocatedSize :: #force_inline proc(self: ^Resource) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "allocatedSize")
}
@(objc_type=Resource, objc_name="cpuCacheMode")
Resource_cpuCacheMode :: #force_inline proc(self: ^Resource) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Resource, objc_name="device")
Resource_device :: #force_inline proc(self: ^Resource) -> ^Resource {
	return msgSend(^Resource, self, "device")
}
@(objc_type=Resource, objc_name="hazardTrackingMode")
Resource_hazardTrackingMode :: #force_inline proc(self: ^Resource) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Resource, objc_name="heap")
Resource_heap :: #force_inline proc(self: ^Resource) -> ^Resource {
	return msgSend(^Resource, self, "heap")
}
@(objc_type=Resource, objc_name="heapOffset")
Resource_heapOffset :: #force_inline proc(self: ^Resource) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "heapOffset")
}
@(objc_type=Resource, objc_name="isAliasable")
Resource_isAliasable :: #force_inline proc(self: ^Resource) -> BOOL {
	return msgSend(BOOL, self, "isAliasable")
}
@(objc_type=Resource, objc_name="label")
Resource_label :: #force_inline proc(self: ^Resource) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Resource, objc_name="makeAliasable")
Resource_makeAliasable :: #force_inline proc(self: ^Resource) {
	msgSend(nil, self, "makeAliasable")
}
@(objc_type=Resource, objc_name="resourceOptions")
Resource_resourceOptions :: #force_inline proc(self: ^Resource) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Resource, objc_name="setLabel")
Resource_setLabel :: #force_inline proc(self: ^Resource, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Resource, objc_name="setPurgeableState")
Resource_setPurgeableState :: #force_inline proc(self: ^Resource, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Resource, objc_name="storageMode")
Resource_storageMode :: #force_inline proc(self: ^Resource) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	ResourceStateCommandEncoder
Class Methods:
Methods:
	updateFence
	updateTextureMapping
	updateTextureMapping
	updateTextureMappings
	waitForFence
*/
@(objc_class="MTLResourceStateCommandEncoder")
ResourceStateCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ResourceStateCommandEncoder, objc_name="updateFence")
ResourceStateCommandEncoder_updateFence :: #force_inline proc(self: ^ResourceStateCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMappingIndirect")
ResourceStateCommandEncoder_updateTextureMappingIndirect :: #force_inline proc(self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "updateTextureMapping:mode:indirectBuffer:indirectBufferOffset:", texture, mode, indirectBuffer, indirectBufferOffset)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMapping")
ResourceStateCommandEncoder_updateTextureMapping :: #force_inline proc(self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "updateTextureMapping:mode:region:mipLevel:slice:", texture, mode, region, mipLevel, slice)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMappings")
ResourceStateCommandEncoder_updateTextureMappings :: #force_inline proc(self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, regions: ^Region, mipLevels: NS.UInteger, slices: NS.UInteger, numRegions: NS.UInteger) {
	msgSend(nil, self, "updateTextureMappings:mode:regions:mipLevels:slices:numRegions:", texture, mode, regions, mipLevels, slices, numRegions)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="waitForFence")
ResourceStateCommandEncoder_waitForFence :: #force_inline proc(self: ^ResourceStateCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SamplerState
Class Methods:
Methods:
	device
	label
*/
@(objc_class="MTLSamplerState")
SamplerState :: struct { using _: NS.Object }

@(objc_type=SamplerState, objc_name="device")
SamplerState_device :: #force_inline proc(self: ^SamplerState) -> ^SamplerState {
	return msgSend(^SamplerState, self, "device")
}
@(objc_type=SamplerState, objc_name="label")
SamplerState_label :: #force_inline proc(self: ^SamplerState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	SharedEvent
Class Methods:
Methods:
	newSharedEventHandle
	notifyListener
	setSignaledValue
	signaledValue
*/
@(objc_class="MTLSharedEvent")
SharedEvent :: struct { using _: Event }

@(objc_type=SharedEvent, objc_name="newSharedEventHandle")
SharedEvent_newSharedEventHandle :: #force_inline proc(self: ^SharedEvent) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "newSharedEventHandle")
}
@(objc_type=SharedEvent, objc_name="notifyListener")
SharedEvent_notifyListener :: #force_inline proc(self: ^SharedEvent, listener: ^SharedEventListener, value: u64, block: SharedEventNotificationBlock) {
	msgSend(nil, self, "notifyListener:atValue:block:", listener, value, block)
}
@(objc_type=SharedEvent, objc_name="setSignaledValue")
SharedEvent_setSignaledValue :: #force_inline proc(self: ^SharedEvent, signaledValue: u64) {
	msgSend(nil, self, "setSignaledValue:", signaledValue)
}
@(objc_type=SharedEvent, objc_name="signaledValue")
SharedEvent_signaledValue :: #force_inline proc(self: ^SharedEvent) -> u64 {
	return msgSend(u64, self, "signaledValue")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	Texture
Class Methods:
Methods:
	allowGPUOptimizedContents
	arrayLength
	buffer
	bufferBytesPerRow
	bufferOffset
	depth
	firstMipmapInTail
	getBytes
	getBytes
	height
	iosurface
	iosurfacePlane
	isFramebufferOnly
	isShareable
	isSparse
	mipmapLevelCount
	newRemoteTextureViewForDevice
	newSharedTextureHandle
	newTextureViewWithPixelFormat
	newTextureViewWithPixelFormat
	newTextureViewWithPixelFormat
	parentRelativeLevel
	parentRelativeSlice
	parentTexture
	pixelFormat
	remoteStorageTexture
	replaceRegion
	replaceRegion
	rootResource
	sampleCount
	swizzle
	tailSizeInBytes
	textureType
	usage
	width
*/
@(objc_class="MTLTexture")
Texture :: struct { using _: Resource }

@(objc_type=Texture, objc_name="allowGPUOptimizedContents")
Texture_allowGPUOptimizedContents :: #force_inline proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=Texture, objc_name="arrayLength")
Texture_arrayLength :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=Texture, objc_name="buffer")
Texture_buffer :: #force_inline proc(self: ^Texture) -> ^Buffer {
	return msgSend(^Buffer, self, "buffer")
}
@(objc_type=Texture, objc_name="bufferBytesPerRow")
Texture_bufferBytesPerRow :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferBytesPerRow")
}
@(objc_type=Texture, objc_name="bufferOffset")
Texture_bufferOffset :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferOffset")
}
@(objc_type=Texture, objc_name="depth")
Texture_depth :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depth")
}
@(objc_type=Texture, objc_name="firstMipmapInTail")
Texture_firstMipmapInTail :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "firstMipmapInTail")
}
@(objc_type=Texture, objc_name="getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_")
Texture_getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_ :: #force_inline proc(self: ^Texture, pixelBytes: rawptr, bytesPerRow: NS.UInteger, bytesPerImage: NS.UInteger, region: Region, level: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "getBytes:bytesPerRow:bytesPerImage:fromRegion:mipmapLevel:slice:", pixelBytes, bytesPerRow, bytesPerImage, region, level, slice)
}
@(objc_type=Texture, objc_name="getBytes_bytesPerRow_fromRegion_mipmapLevel_")
Texture_getBytes_bytesPerRow_fromRegion_mipmapLevel_ :: #force_inline proc(self: ^Texture, pixelBytes: rawptr, bytesPerRow: NS.UInteger, region: Region, level: NS.UInteger) {
	msgSend(nil, self, "getBytes:bytesPerRow:fromRegion:mipmapLevel:", pixelBytes, bytesPerRow, region, level)
}
@(objc_type=Texture, objc_name="height")
Texture_height :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "height")
}
@(objc_type=Texture, objc_name="iosurface")
Texture_iosurface :: #force_inline proc(self: ^Texture) -> IOSurfaceRef {
	return msgSend(IOSurfaceRef, self, "iosurface")
}
@(objc_type=Texture, objc_name="iosurfacePlane")
Texture_iosurfacePlane :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "iosurfacePlane")
}
@(objc_type=Texture, objc_name="isFramebufferOnly")
Texture_isFramebufferOnly :: #force_inline proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isFramebufferOnly")
}
@(objc_type=Texture, objc_name="isShareable")
Texture_isShareable :: #force_inline proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isShareable")
}
@(objc_type=Texture, objc_name="isSparse")
Texture_isSparse :: #force_inline proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isSparse")
}
@(objc_type=Texture, objc_name="mipmapLevelCount")
Texture_mipmapLevelCount :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "mipmapLevelCount")
}
@(objc_type=Texture, objc_name="newRemoteTextureViewForDevice")
Texture_newRemoteTextureViewForDevice :: #force_inline proc(self: ^Texture, device: ^Device) -> ^Texture {
	return msgSend(^Texture, self, "newRemoteTextureViewForDevice:", device)
}
@(objc_type=Texture, objc_name="newSharedTextureHandle")
Texture_newSharedTextureHandle :: #force_inline proc(self: ^Texture) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "newSharedTextureHandle")
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat")
Texture_newTextureViewWithPixelFormat :: #force_inline proc(self: ^Texture, pixelFormat: PixelFormat) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:", pixelFormat)
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat_textureType_levels_slices_")
Texture_newTextureViewWithPixelFormat_textureType_levels_slices_ :: #force_inline proc(self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:", pixelFormat, textureType, levelRange, sliceRange)
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat_textureType_levels_slices_swizzle_")
Texture_newTextureViewWithPixelFormat_textureType_levels_slices_swizzle_ :: #force_inline proc(self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range, swizzle: TextureSwizzleChannels) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:", pixelFormat, textureType, levelRange, sliceRange, swizzle)
}
@(objc_type=Texture, objc_name="parentRelativeLevel")
Texture_parentRelativeLevel :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "parentRelativeLevel")
}
@(objc_type=Texture, objc_name="parentRelativeSlice")
Texture_parentRelativeSlice :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "parentRelativeSlice")
}
@(objc_type=Texture, objc_name="parentTexture")
Texture_parentTexture :: #force_inline proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "parentTexture")
}
@(objc_type=Texture, objc_name="pixelFormat")
Texture_pixelFormat :: #force_inline proc(self: ^Texture) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=Texture, objc_name="remoteStorageTexture")
Texture_remoteStorageTexture :: #force_inline proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "remoteStorageTexture")
}
@(objc_type=Texture, objc_name="replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_")
Texture_replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_ :: #force_inline proc(self: ^Texture, region: Region, level: NS.UInteger, slice: NS.UInteger, pixelBytes: rawptr, bytesPerRow: NS.UInteger, bytesPerImage: NS.UInteger) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:", region, level, slice, pixelBytes, bytesPerRow, bytesPerImage)
}
@(objc_type=Texture, objc_name="replaceRegion_mipmapLevel_withBytes_bytesPerRow_")
Texture_replaceRegion_mipmapLevel_withBytes_bytesPerRow_ :: #force_inline proc(self: ^Texture, region: Region, level: NS.UInteger, pixelBytes: rawptr, bytesPerRow: NS.UInteger) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:withBytes:bytesPerRow:", region, level, pixelBytes, bytesPerRow)
}
@(objc_type=Texture, objc_name="rootResource")
Texture_rootResource :: #force_inline proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "rootResource")
}
@(objc_type=Texture, objc_name="sampleCount")
Texture_sampleCount :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=Texture, objc_name="swizzle")
Texture_swizzle :: #force_inline proc(self: ^Texture) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=Texture, objc_name="tailSizeInBytes")
Texture_tailSizeInBytes :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tailSizeInBytes")
}
@(objc_type=Texture, objc_name="textureType")
Texture_textureType :: #force_inline proc(self: ^Texture) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Texture, objc_name="usage")
Texture_usage :: #force_inline proc(self: ^Texture) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=Texture, objc_name="width")
Texture_width :: #force_inline proc(self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "width")
}

////////////////////////////////////////////////////////////////////////////////

/*
Class:
	VisibleFunctionTable
Class Methods:
Methods:
	setFunction
	setFunctions
*/
@(objc_class="MTLVisibleFunctionTable")
VisibleFunctionTable :: struct { using _: Resource }

@(objc_type=VisibleFunctionTable, objc_name="setFunction")
VisibleFunctionTable_setFunction :: #force_inline proc(self: ^VisibleFunctionTable, function: ^FunctionHandle, index: NS.UInteger) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=VisibleFunctionTable, objc_name="setFunctions")
VisibleFunctionTable_setFunctions :: #force_inline proc(self: ^VisibleFunctionTable, functions: [^]^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", functions, range)
}
