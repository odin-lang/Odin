package objc_Metal

import NS "core:sys/darwin/Foundation"
import "core:mem"
_ :: mem

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructureBoundingBoxGeometryDescriptor")
AccelerationStructureBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureBoundingBoxGeometryDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureBoundingBoxGeometryDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="init")
AccelerationStructureBoundingBoxGeometryDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBuffer :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "boundingBoxBuffer")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxBufferOffset")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxCount :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxCount")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxStride :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxStride")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="descriptor", objc_is_class_method=true)
AccelerationStructureBoundingBoxGeometryDescriptor_descriptor :: #force_inline proc "c" () -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBuffer :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBuffer: ^Buffer) {
	msgSend(nil, self, "setBoundingBoxBuffer:", boundingBoxBuffer)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxBufferOffset:", boundingBoxBufferOffset)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxCount :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxCount: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxCount:", boundingBoxCount)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxStride :: #force_inline proc "c" (self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxStride: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxStride:", boundingBoxStride)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLMotionKeyframeData")
MotionKeyframeData :: struct { using _: NS.Object }

@(objc_type=MotionKeyframeData, objc_name="alloc", objc_is_class_method=true)
MotionKeyframeData_alloc :: #force_inline proc "c" () -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, MotionKeyframeData, "alloc")
}
@(objc_type=MotionKeyframeData, objc_name="data", objc_is_class_method=true)
MotionKeyframeData_data :: #force_inline proc "c" () -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, MotionKeyframeData, "data")
}
@(objc_type=MotionKeyframeData, objc_name="init", objc_is_class_method=true)
MotionKeyframeData_init :: #force_inline proc "c" (self: ^MotionKeyframeData) -> ^MotionKeyframeData {
	return msgSend(^MotionKeyframeData, self, "init")
}
@(objc_type=MotionKeyframeData, objc_name="buffer", objc_is_class_method=true)
MotionKeyframeData_buffer :: #force_inline proc "c" (self: ^MotionKeyframeData) -> ^Buffer {
	return msgSend(^Buffer, self, "buffer")
}
@(objc_type=MotionKeyframeData, objc_name="setBuffer", objc_is_class_method=true)
MotionKeyframeData_setBuffer :: #force_inline proc "c" (self: ^MotionKeyframeData, buffer: ^Buffer) {
	msgSend(nil, self, "setBuffer:", buffer)
}
@(objc_type=MotionKeyframeData, objc_name="offset", objc_is_class_method=true)
MotionKeyframeData_offset :: #force_inline proc "c" (self: ^MotionKeyframeData) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=MotionKeyframeData, objc_name="setOffset", objc_is_class_method=true)
MotionKeyframeData_setOffset :: #force_inline proc "c" (self: ^MotionKeyframeData, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////



@(objc_class="MTLAccelerationStructureMotionTriangleGeometryDescriptor")
AccelerationStructureMotionTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionTriangleGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureMotionTriangleGeometryDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureMotionTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionTriangleGeometryDescriptor, AccelerationStructureMotionTriangleGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="init")
AccelerationStructureMotionTriangleGeometryDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^AccelerationStructureMotionTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionTriangleGeometryDescriptor, self, "init")
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="vertexBuffers")
AccelerationStructureMotionTriangleGeometryDescriptor_vertexBuffers :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexBuffers")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setVertexBuffers")
AccelerationStructureMotionTriangleGeometryDescriptor_setVertexBuffers :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, buffers: ^NS.Array) {
	msgSend(nil, self, "setVertexBuffers:", buffers)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="vertexStride")
AccelerationStructureMotionTriangleGeometryDescriptor_vertexStride :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexStride")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setVertexStride")
AccelerationStructureMotionTriangleGeometryDescriptor_setVertexStride :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setVertexStride:", stride)
}


@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_indexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "indexBuffer")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, buffer: ^Buffer) {
	msgSend(nil, self, "setIndexBuffer:", buffer)
}


@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_indexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferOffset")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferOffset:", offset)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="indexType")
AccelerationStructureMotionTriangleGeometryDescriptor_indexType :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setIndexType")
AccelerationStructureMotionTriangleGeometryDescriptor_setIndexType :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="triangleCount")
AccelerationStructureMotionTriangleGeometryDescriptor_triangleCount :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "triangleCount")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setTriangleCount")
AccelerationStructureMotionTriangleGeometryDescriptor_setTriangleCount :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, count: NS.UInteger) {
	msgSend(nil, self, "setTriangleCount:", count)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="vertexFormat")
AccelerationStructureMotionTriangleGeometryDescriptor_vertexFormat :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> AttributeFormat {
	return msgSend(AttributeFormat, self, "vertexFormat")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setVertexFormat")
AccelerationStructureMotionTriangleGeometryDescriptor_setVertexFormat :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, vertexFormat: AttributeFormat) {
	msgSend(nil, self, "setVertexFormat:", vertexFormat)
}

@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="transformationMatrixBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_transformationMatrixBuffer :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "transformationMatrixBuffer")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setTransformationMatrixBuffer")
AccelerationStructureMotionTriangleGeometryDescriptor_setTransformationMatrixBuffer :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, transformationMatrixBuffer: ^Buffer) {
	msgSend(nil, self, "setTransformationMatrixBuffer:", transformationMatrixBuffer)
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="transformationMatrixBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_transformationMatrixBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "transformationMatrixBufferOffset")
}
@(objc_type=AccelerationStructureMotionTriangleGeometryDescriptor, objc_name="setTransformationMatrixBufferOffset")
AccelerationStructureMotionTriangleGeometryDescriptor_setTransformationMatrixBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureMotionTriangleGeometryDescriptor, transformationMatrixBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setTransformationMatrixBufferOffset:", transformationMatrixBufferOffset)
}

////////////////////////////////////////////////////////////////////////////////



@(objc_class="MTLAccelerationStructureMotionBoundingBoxGeometryDescriptor")
AccelerationStructureMotionBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionBoundingBoxGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureMotionBoundingBoxGeometryDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, AccelerationStructureMotionBoundingBoxGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="init")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, self, "init")
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="descriptor", objc_is_class_method=true)
AccelerationStructureMotionBoundingBoxGeometryDescriptor_descriptor :: #force_inline proc "c" () -> ^AccelerationStructureMotionBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureMotionBoundingBoxGeometryDescriptor, AccelerationStructureMotionBoundingBoxGeometryDescriptor, "descriptor")
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxBuffers")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxBuffers :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "boundingBoxBuffers")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundBoxBuffers")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundBoxBuffers :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, buffers: ^NS.Array) {
	msgSend(nil, self, "setBoundBoxBuffers:", buffers)
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxStride")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxStride :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxStride")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxStride")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundingBoxStride :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxStride:", stride)
}

@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="boundingBoxCount")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_boundingBoxCount :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxCount")
}
@(objc_type=AccelerationStructureMotionBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxCount")
AccelerationStructureMotionBoundingBoxGeometryDescriptor_setBoundingBoxCount :: #force_inline proc "c" (self: ^AccelerationStructureMotionBoundingBoxGeometryDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxCount:", offset)
}







////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructureDescriptor")
AccelerationStructureDescriptor :: struct { using _: NS.Copying(AccelerationStructureDescriptor) }

@(objc_type=AccelerationStructureDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, AccelerationStructureDescriptor, "alloc")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="init")
AccelerationStructureDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureDescriptor) -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, self, "init")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="setUsage")
AccelerationStructureDescriptor_setUsage :: #force_inline proc "c" (self: ^AccelerationStructureDescriptor, usage: AccelerationStructureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=AccelerationStructureDescriptor, objc_name="usage")
AccelerationStructureDescriptor_usage :: #force_inline proc "c" (self: ^AccelerationStructureDescriptor) -> AccelerationStructureUsage {
	return msgSend(AccelerationStructureUsage, self, "usage")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructureGeometryDescriptor")
AccelerationStructureGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureGeometryDescriptor) }

@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureGeometryDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, AccelerationStructureGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="init")
AccelerationStructureGeometryDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="allowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_allowDuplicateIntersectionFunctionInvocation :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowDuplicateIntersectionFunctionInvocation")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="intersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_intersectionFunctionTableOffset :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "intersectionFunctionTableOffset")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="opaque")
AccelerationStructureGeometryDescriptor_opaque :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "opaque")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setAllowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_setAllowDuplicateIntersectionFunctionInvocation :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, allowDuplicateIntersectionFunctionInvocation: BOOL) {
	msgSend(nil, self, "setAllowDuplicateIntersectionFunctionInvocation:", allowDuplicateIntersectionFunctionInvocation)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setIntersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_setIntersectionFunctionTableOffset :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, intersectionFunctionTableOffset: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTableOffset:", intersectionFunctionTableOffset)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setOpaque")
AccelerationStructureGeometryDescriptor_setOpaque :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, opaque: BOOL) {
	msgSend(nil, self, "setOpaque:", opaque)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="primitiveDataBuffer")
AccelerationStructureGeometryDescriptor_primitiveDataBuffer :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "primitiveDataBuffer")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setPrimitiveDataBuffer")
AccelerationStructureGeometryDescriptor_setPrimitiveDataBuffer :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, primitiveDataBuffer: ^Buffer) {
	msgSend(nil, self, "setPrimitiveDataBuffer:", primitiveDataBuffer)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="primitiveDataBufferOffset")
AccelerationStructureGeometryDescriptor_primitiveDataBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "primitiveDataBufferOffset")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setPrimitiveDataBufferOffset")
AccelerationStructureGeometryDescriptor_setPrimitiveDataBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setPrimitiveDataBufferOffset:", offset)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="primitiveDataStride")
AccelerationStructureGeometryDescriptor_primitiveDataStride :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "primitiveDataStride")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setPrimitiveDataStride")
AccelerationStructureGeometryDescriptor_setPrimitiveDataStride :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setPrimitiveDataStride:", stride)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="primitiveDataElementSize")
AccelerationStructureGeometryDescriptor_primitiveDataElementSize :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "primitiveDataElementSize")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setPrimitiveDataElementSize")
AccelerationStructureGeometryDescriptor_setPrimitiveDataElementSize :: #force_inline proc "c" (self: ^AccelerationStructureGeometryDescriptor, elementSize: NS.UInteger) {
	msgSend(nil, self, "setPrimitiveDataElementSize:", elementSize)
}



////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructureTriangleGeometryDescriptor")
AccelerationStructureTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureTriangleGeometryDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructureTriangleGeometryDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="init")
AccelerationStructureTriangleGeometryDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="descriptor", objc_is_class_method=true)
AccelerationStructureTriangleGeometryDescriptor_descriptor :: #force_inline proc "c" () -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBuffer")
AccelerationStructureTriangleGeometryDescriptor_indexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "indexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_indexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexType")
AccelerationStructureTriangleGeometryDescriptor_indexType :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setIndexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, indexBuffer: ^Buffer) {
	msgSend(nil, self, "setIndexBuffer:", indexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setIndexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, indexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferOffset:", indexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexType")
AccelerationStructureTriangleGeometryDescriptor_setIndexType :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setTriangleCount")
AccelerationStructureTriangleGeometryDescriptor_setTriangleCount :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, triangleCount: NS.UInteger) {
	msgSend(nil, self, "setTriangleCount:", triangleCount)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setVertexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBuffer: ^Buffer) {
	msgSend(nil, self, "setVertexBuffer:", vertexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setVertexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setVertexBufferOffset:", vertexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexStride")
AccelerationStructureTriangleGeometryDescriptor_setVertexStride :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, vertexStride: NS.UInteger) {
	msgSend(nil, self, "setVertexStride:", vertexStride)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="triangleCount")
AccelerationStructureTriangleGeometryDescriptor_triangleCount :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "triangleCount")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_vertexBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "vertexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_vertexBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexStride")
AccelerationStructureTriangleGeometryDescriptor_vertexStride :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexStride")
}

@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexFormat")
AccelerationStructureTriangleGeometryDescriptor_vertexFormat :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> AttributeFormat {
	return msgSend(AttributeFormat, self, "vertexFormat")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexFormat")
AccelerationStructureTriangleGeometryDescriptor_setVertexFormat :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, vertexFormat: AttributeFormat) {
	msgSend(nil, self, "setVertexFormat:", vertexFormat)
}

@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="transformationMatrixBuffer")
AccelerationStructureTriangleGeometryDescriptor_transformationMatrixBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "transformationMatrixBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setTransformationMatrixBuffer")
AccelerationStructureTriangleGeometryDescriptor_setTransformationMatrixBuffer :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, transformationMatrixBuffer: ^Buffer) {
	msgSend(nil, self, "setTransformationMatrixBuffer:", transformationMatrixBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="transformationMatrixBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_transformationMatrixBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "transformationMatrixBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setTransformationMatrixBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setTransformationMatrixBufferOffset :: #force_inline proc "c" (self: ^AccelerationStructureTriangleGeometryDescriptor, transformationMatrixBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setTransformationMatrixBufferOffset:", transformationMatrixBufferOffset)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLArgument")
Argument :: struct { using _: NS.Object }

@(objc_type=Argument, objc_name="alloc", objc_is_class_method=true)
Argument_alloc :: #force_inline proc "c" () -> ^Argument {
	return msgSend(^Argument, Argument, "alloc")
}
@(objc_type=Argument, objc_name="init")
Argument_init :: #force_inline proc "c" (self: ^Argument) -> ^Argument {
	return msgSend(^Argument, self, "init")
}
@(objc_type=Argument, objc_name="access")
Argument_access :: #force_inline proc "c" (self: ^Argument) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=Argument, objc_name="arrayLength")
Argument_arrayLength :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=Argument, objc_name="bufferAlignment")
Argument_bufferAlignment :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferAlignment")
}
@(objc_type=Argument, objc_name="bufferDataSize")
Argument_bufferDataSize :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferDataSize")
}
@(objc_type=Argument, objc_name="bufferDataType")
Argument_bufferDataType :: #force_inline proc "c" (self: ^Argument) -> DataType {
	return msgSend(DataType, self, "bufferDataType")
}
@(objc_type=Argument, objc_name="bufferPointerType")
Argument_bufferPointerType :: #force_inline proc "c" (self: ^Argument) -> ^PointerType {
	return msgSend(^PointerType, self, "bufferPointerType")
}
@(objc_type=Argument, objc_name="bufferStructType")
Argument_bufferStructType :: #force_inline proc "c" (self: ^Argument) -> ^StructType {
	return msgSend(^StructType, self, "bufferStructType")
}
@(objc_type=Argument, objc_name="index")
Argument_index :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=Argument, objc_name="isActive")
Argument_isActive :: #force_inline proc "c" (self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Argument, objc_name="isDepthTexture")
Argument_isDepthTexture :: #force_inline proc "c" (self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=Argument, objc_name="name")
Argument_name :: #force_inline proc "c" (self: ^Argument) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Argument, objc_name="textureDataType")
Argument_textureDataType :: #force_inline proc "c" (self: ^Argument) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=Argument, objc_name="textureType")
Argument_textureType :: #force_inline proc "c" (self: ^Argument) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Argument, objc_name="threadgroupMemoryAlignment")
Argument_threadgroupMemoryAlignment :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryAlignment")
}
@(objc_type=Argument, objc_name="threadgroupMemoryDataSize")
Argument_threadgroupMemoryDataSize :: #force_inline proc "c" (self: ^Argument) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryDataSize")
}
@(objc_type=Argument, objc_name="type")
Argument_type :: #force_inline proc "c" (self: ^Argument) -> ArgumentType {
	return msgSend(ArgumentType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLArgumentDescriptor")
ArgumentDescriptor :: struct { using _: NS.Copying(ArgumentDescriptor) }

@(objc_type=ArgumentDescriptor, objc_name="alloc", objc_is_class_method=true)
ArgumentDescriptor_alloc :: #force_inline proc "c" () -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "alloc")
}
@(objc_type=ArgumentDescriptor, objc_name="init")
ArgumentDescriptor_init :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, self, "init")
}
@(objc_type=ArgumentDescriptor, objc_name="access")
ArgumentDescriptor_access :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=ArgumentDescriptor, objc_name="argumentDescriptor", objc_is_class_method=true)
ArgumentDescriptor_argumentDescriptor :: #force_inline proc "c" () -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "argumentDescriptor")
}
@(objc_type=ArgumentDescriptor, objc_name="arrayLength")
ArgumentDescriptor_arrayLength :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=ArgumentDescriptor, objc_name="constantBlockAlignment")
ArgumentDescriptor_constantBlockAlignment :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "constantBlockAlignment")
}
@(objc_type=ArgumentDescriptor, objc_name="dataType")
ArgumentDescriptor_dataType :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=ArgumentDescriptor, objc_name="index")
ArgumentDescriptor_index :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=ArgumentDescriptor, objc_name="setAccess")
ArgumentDescriptor_setAccess :: #force_inline proc "c" (self: ^ArgumentDescriptor, access: ArgumentAccess) {
	msgSend(nil, self, "setAccess:", access)
}
@(objc_type=ArgumentDescriptor, objc_name="setArrayLength")
ArgumentDescriptor_setArrayLength :: #force_inline proc "c" (self: ^ArgumentDescriptor, arrayLength: NS.UInteger) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=ArgumentDescriptor, objc_name="setConstantBlockAlignment")
ArgumentDescriptor_setConstantBlockAlignment :: #force_inline proc "c" (self: ^ArgumentDescriptor, constantBlockAlignment: NS.UInteger) {
	msgSend(nil, self, "setConstantBlockAlignment:", constantBlockAlignment)
}
@(objc_type=ArgumentDescriptor, objc_name="setDataType")
ArgumentDescriptor_setDataType :: #force_inline proc "c" (self: ^ArgumentDescriptor, dataType: DataType) {
	msgSend(nil, self, "setDataType:", dataType)
}
@(objc_type=ArgumentDescriptor, objc_name="setIndex")
ArgumentDescriptor_setIndex :: #force_inline proc "c" (self: ^ArgumentDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setIndex:", index)
}
@(objc_type=ArgumentDescriptor, objc_name="setTextureType")
ArgumentDescriptor_setTextureType :: #force_inline proc "c" (self: ^ArgumentDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=ArgumentDescriptor, objc_name="textureType")
ArgumentDescriptor_textureType :: #force_inline proc "c" (self: ^ArgumentDescriptor) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLArrayType")
ArrayType :: struct { using _: Type }

@(objc_type=ArrayType, objc_name="alloc", objc_is_class_method=true)
ArrayType_alloc :: #force_inline proc "c" () -> ^ArrayType {
	return msgSend(^ArrayType, ArrayType, "alloc")
}
@(objc_type=ArrayType, objc_name="init")
ArrayType_init :: #force_inline proc "c" (self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "init")
}
@(objc_type=ArrayType, objc_name="argumentIndexStride")
ArrayType_argumentIndexStride :: #force_inline proc "c" (self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "argumentIndexStride")
}
@(objc_type=ArrayType, objc_name="arrayLength")
ArrayType_arrayLength :: #force_inline proc "c" (self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=ArrayType, objc_name="elementArrayType")
ArrayType_elementArrayType :: #force_inline proc "c" (self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=ArrayType, objc_name="elementPointerType")
ArrayType_elementPointerType :: #force_inline proc "c" (self: ^ArrayType) -> ^PointerType {
	return msgSend(^PointerType, self, "elementPointerType")
}
@(objc_type=ArrayType, objc_name="elementStructType")
ArrayType_elementStructType :: #force_inline proc "c" (self: ^ArrayType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=ArrayType, objc_name="elementTextureReferenceType")
ArrayType_elementTextureReferenceType :: #force_inline proc "c" (self: ^ArrayType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "elementTextureReferenceType")
}
@(objc_type=ArrayType, objc_name="elementType")
ArrayType_elementType :: #force_inline proc "c" (self: ^ArrayType) -> DataType {
	return msgSend(DataType, self, "elementType")
}
@(objc_type=ArrayType, objc_name="stride")
ArrayType_stride :: #force_inline proc "c" (self: ^ArrayType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAttribute")
Attribute :: struct { using _: NS.Object }

@(objc_type=Attribute, objc_name="alloc", objc_is_class_method=true)
Attribute_alloc :: #force_inline proc "c" () -> ^Attribute {
	return msgSend(^Attribute, Attribute, "alloc")
}
@(objc_type=Attribute, objc_name="init")
Attribute_init :: #force_inline proc "c" (self: ^Attribute) -> ^Attribute {
	return msgSend(^Attribute, self, "init")
}
@(objc_type=Attribute, objc_name="attributeIndex")
Attribute_attributeIndex :: #force_inline proc "c" (self: ^Attribute) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "attributeIndex")
}
@(objc_type=Attribute, objc_name="attributeType")
Attribute_attributeType :: #force_inline proc "c" (self: ^Attribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=Attribute, objc_name="isActive")
Attribute_isActive :: #force_inline proc "c" (self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Attribute, objc_name="isPatchControlPointData")
Attribute_isPatchControlPointData :: #force_inline proc "c" (self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=Attribute, objc_name="isPatchData")
Attribute_isPatchData :: #force_inline proc "c" (self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=Attribute, objc_name="name")
Attribute_name :: #force_inline proc "c" (self: ^Attribute) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAttributeDescriptor")
AttributeDescriptor :: struct { using _: NS.Copying(AttributeDescriptor) }

@(objc_type=AttributeDescriptor, objc_name="alloc", objc_is_class_method=true)
AttributeDescriptor_alloc :: #force_inline proc "c" () -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, AttributeDescriptor, "alloc")
}
@(objc_type=AttributeDescriptor, objc_name="init")
AttributeDescriptor_init :: #force_inline proc "c" (self: ^AttributeDescriptor) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "init")
}
@(objc_type=AttributeDescriptor, objc_name="bufferIndex")
AttributeDescriptor_bufferIndex :: #force_inline proc "c" (self: ^AttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferIndex")
}
@(objc_type=AttributeDescriptor, objc_name="format")
AttributeDescriptor_format :: #force_inline proc "c" (self: ^AttributeDescriptor) -> AttributeFormat {
	return msgSend(AttributeFormat, self, "format")
}
@(objc_type=AttributeDescriptor, objc_name="offset")
AttributeDescriptor_offset :: #force_inline proc "c" (self: ^AttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=AttributeDescriptor, objc_name="setBufferIndex")
AttributeDescriptor_setBufferIndex :: #force_inline proc "c" (self: ^AttributeDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=AttributeDescriptor, objc_name="setFormat")
AttributeDescriptor_setFormat :: #force_inline proc "c" (self: ^AttributeDescriptor, format: AttributeFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=AttributeDescriptor, objc_name="setOffset")
AttributeDescriptor_setOffset :: #force_inline proc "c" (self: ^AttributeDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAttributeDescriptorArray")
AttributeDescriptorArray :: struct { using _: NS.Object }

@(objc_type=AttributeDescriptorArray, objc_name="alloc", objc_is_class_method=true)
AttributeDescriptorArray_alloc :: #force_inline proc "c" () -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, AttributeDescriptorArray, "alloc")
}
@(objc_type=AttributeDescriptorArray, objc_name="init")
AttributeDescriptorArray_init :: #force_inline proc "c" (self: ^AttributeDescriptorArray) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "init")
}
@(objc_type=AttributeDescriptorArray, objc_name="object")
AttributeDescriptorArray_object :: #force_inline proc "c" (self: ^AttributeDescriptorArray, index: NS.UInteger) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=AttributeDescriptorArray, objc_name="setObject")
AttributeDescriptorArray_setObject :: #force_inline proc "c" (self: ^AttributeDescriptorArray, attributeDesc: ^AttributeDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attributeDesc, index)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBinaryArchiveDescriptor")
BinaryArchiveDescriptor :: struct { using _: NS.Copying(BinaryArchiveDescriptor) }

@(objc_type=BinaryArchiveDescriptor, objc_name="alloc", objc_is_class_method=true)
BinaryArchiveDescriptor_alloc :: #force_inline proc "c" () -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, BinaryArchiveDescriptor, "alloc")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="init")
BinaryArchiveDescriptor_init :: #force_inline proc "c" (self: ^BinaryArchiveDescriptor) -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, self, "init")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="setUrl")
BinaryArchiveDescriptor_setUrl :: #force_inline proc "c" (self: ^BinaryArchiveDescriptor, url: ^NS.URL) {
	msgSend(nil, self, "setUrl:", url)
}
@(objc_type=BinaryArchiveDescriptor, objc_name="url")
BinaryArchiveDescriptor_url :: #force_inline proc "c" (self: ^BinaryArchiveDescriptor) -> ^NS.URL {
	return msgSend(^NS.URL, self, "url")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBlitPassDescriptor")
BlitPassDescriptor :: struct { using _: NS.Copying(BlitPassDescriptor) }

@(objc_type=BlitPassDescriptor, objc_name="alloc", objc_is_class_method=true)
BlitPassDescriptor_alloc :: #force_inline proc "c" () -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "alloc")
}
@(objc_type=BlitPassDescriptor, objc_name="init")
BlitPassDescriptor_init :: #force_inline proc "c" (self: ^BlitPassDescriptor) -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, self, "init")
}
@(objc_type=BlitPassDescriptor, objc_name="blitPassDescriptor", objc_is_class_method=true)
BlitPassDescriptor_blitPassDescriptor :: #force_inline proc "c" () -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "blitPassDescriptor")
}
@(objc_type=BlitPassDescriptor, objc_name="sampleBufferAttachments")
BlitPassDescriptor_sampleBufferAttachments :: #force_inline proc "c" (self: ^BlitPassDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBlitPassSampleBufferAttachmentDescriptor")
BlitPassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(BlitPassSampleBufferAttachmentDescriptor) }

@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
BlitPassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, BlitPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="init")
BlitPassSampleBufferAttachmentDescriptor_init :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor, sampleBuffer: ^CounterSampleBuffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBlitPassSampleBufferAttachmentDescriptorArray")
BlitPassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
BlitPassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, BlitPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="init")
BlitPassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptorArray) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="object")
BlitPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
BlitPassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachment: ^BlitPassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBufferLayoutDescriptor")
BufferLayoutDescriptor :: struct { using _: NS.Copying(BufferLayoutDescriptor) }

@(objc_type=BufferLayoutDescriptor, objc_name="alloc", objc_is_class_method=true)
BufferLayoutDescriptor_alloc :: #force_inline proc "c" () -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, BufferLayoutDescriptor, "alloc")
}
@(objc_type=BufferLayoutDescriptor, objc_name="init")
BufferLayoutDescriptor_init :: #force_inline proc "c" (self: ^BufferLayoutDescriptor) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "init")
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepFunction")
BufferLayoutDescriptor_setStepFunction :: #force_inline proc "c" (self: ^BufferLayoutDescriptor, stepFunction: StepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepRate")
BufferLayoutDescriptor_setStepRate :: #force_inline proc "c" (self: ^BufferLayoutDescriptor, stepRate: NS.UInteger) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStride")
BufferLayoutDescriptor_setStride :: #force_inline proc "c" (self: ^BufferLayoutDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepFunction")
BufferLayoutDescriptor_stepFunction :: #force_inline proc "c" (self: ^BufferLayoutDescriptor) -> StepFunction {
	return msgSend(StepFunction, self, "stepFunction")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepRate")
BufferLayoutDescriptor_stepRate :: #force_inline proc "c" (self: ^BufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stepRate")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stride")
BufferLayoutDescriptor_stride :: #force_inline proc "c" (self: ^BufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLBufferLayoutDescriptorArray")
BufferLayoutDescriptorArray :: struct { using _: NS.Object }

@(objc_type=BufferLayoutDescriptorArray, objc_name="alloc", objc_is_class_method=true)
BufferLayoutDescriptorArray_alloc :: #force_inline proc "c" () -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, BufferLayoutDescriptorArray, "alloc")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="init")
BufferLayoutDescriptorArray_init :: #force_inline proc "c" (self: ^BufferLayoutDescriptorArray) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "init")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="object")
BufferLayoutDescriptorArray_object :: #force_inline proc "c" (self: ^BufferLayoutDescriptorArray, index: NS.UInteger) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="setObject")
BufferLayoutDescriptorArray_setObject :: #force_inline proc "c" (self: ^BufferLayoutDescriptorArray, bufferDesc: ^BufferLayoutDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", bufferDesc, index)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLCaptureDescriptor")
CaptureDescriptor :: struct { using _: NS.Copying(CaptureDescriptor) }

@(objc_type=CaptureDescriptor, objc_name="alloc", objc_is_class_method=true)
CaptureDescriptor_alloc :: #force_inline proc "c" () -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, CaptureDescriptor, "alloc")
}
@(objc_type=CaptureDescriptor, objc_name="init")
CaptureDescriptor_init :: #force_inline proc "c" (self: ^CaptureDescriptor) -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, self, "init")
}
@(objc_type=CaptureDescriptor, objc_name="captureObject")
CaptureDescriptor_captureObject :: #force_inline proc "c" (self: ^CaptureDescriptor) -> id {
	return msgSend(id, self, "captureObject")
}
@(objc_type=CaptureDescriptor, objc_name="destination")
CaptureDescriptor_destination :: #force_inline proc "c" (self: ^CaptureDescriptor) -> CaptureDestination {
	return msgSend(CaptureDestination, self, "destination")
}
@(objc_type=CaptureDescriptor, objc_name="outputURL")
CaptureDescriptor_outputURL :: #force_inline proc "c" (self: ^CaptureDescriptor) -> ^NS.URL {
	return msgSend(^NS.URL, self, "outputURL")
}
@(objc_type=CaptureDescriptor, objc_name="setCaptureObject")
CaptureDescriptor_setCaptureObject :: #force_inline proc "c" (self: ^CaptureDescriptor, captureObject: id) {
	msgSend(nil, self, "setCaptureObject:", captureObject)
}
@(objc_type=CaptureDescriptor, objc_name="setDestination")
CaptureDescriptor_setDestination :: #force_inline proc "c" (self: ^CaptureDescriptor, destination: CaptureDestination) {
	msgSend(nil, self, "setDestination:", destination)
}
@(objc_type=CaptureDescriptor, objc_name="setOutputURL")
CaptureDescriptor_setOutputURL :: #force_inline proc "c" (self: ^CaptureDescriptor, outputURL: ^NS.URL) {
	msgSend(nil, self, "setOutputURL:", outputURL)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLCaptureManager")
CaptureManager :: struct { using _: NS.Object }

@(objc_type=CaptureManager, objc_name="alloc", objc_is_class_method=true)
CaptureManager_alloc :: #force_inline proc "c" () -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "alloc")
}
@(objc_type=CaptureManager, objc_name="defaultCaptureScope")
CaptureManager_defaultCaptureScope :: #force_inline proc "c" (self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "defaultCaptureScope")
}
@(objc_type=CaptureManager, objc_name="init")
CaptureManager_init :: #force_inline proc "c" (self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "init")
}
@(objc_type=CaptureManager, objc_name="isCapturing")
CaptureManager_isCapturing :: #force_inline proc "c" (self: ^CaptureManager) -> BOOL {
	return msgSend(BOOL, self, "isCapturing")
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithCommandQueue")
CaptureManager_newCaptureScopeWithCommandQueue :: #force_inline proc "c" (self: ^CaptureManager, commandQueue: ^CommandQueue) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "newCaptureScopeWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithDevice")
CaptureManager_newCaptureScopeWithDevice :: #force_inline proc "c" (self: ^CaptureManager, device: ^Device) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "newCaptureScopeWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="newCaptureScope")
CaptureManager_newCaptureScope :: proc{
	CaptureManager_newCaptureScopeWithCommandQueue,
	CaptureManager_newCaptureScopeWithDevice,
}

@(objc_type=CaptureManager, objc_name="setDefaultCaptureScope")
CaptureManager_setDefaultCaptureScope :: #force_inline proc "c" (self: ^CaptureManager, defaultCaptureScope: ^CaptureScope) {
	msgSend(nil, self, "setDefaultCaptureScope:", defaultCaptureScope)
}
@(objc_type=CaptureManager, objc_name="sharedCaptureManager", objc_is_class_method=true)
CaptureManager_sharedCaptureManager :: #force_inline proc "c" () -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "sharedCaptureManager")
}
@(objc_type=CaptureManager, objc_name="startCaptureWithCommandQueue")
CaptureManager_startCaptureWithCommandQueue :: #force_inline proc "c" (self: ^CaptureManager, commandQueue: ^CommandQueue) {
	msgSend(nil, self, "startCaptureWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDescriptor")
CaptureManager_startCaptureWithDescriptor :: #force_inline proc "contextless" (self: ^CaptureManager, descriptor: ^CaptureDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "startCaptureWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDevice")
CaptureManager_startCaptureWithDevice :: #force_inline proc "c" (self: ^CaptureManager, device: ^Device) {
	msgSend(nil, self, "startCaptureWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithScope")
CaptureManager_startCaptureWithScope :: #force_inline proc "c" (self: ^CaptureManager, captureScope: ^CaptureScope) {
	msgSend(nil, self, "startCaptureWithScope:", captureScope)
}
@(objc_type=CaptureManager, objc_name="stopCapture")
CaptureManager_stopCapture :: #force_inline proc "c" (self: ^CaptureManager) {
	msgSend(nil, self, "stopCapture")
}
@(objc_type=CaptureManager, objc_name="supportsDestination")
CaptureManager_supportsDestination :: #force_inline proc "c" (self: ^CaptureManager, destination: CaptureDestination) -> BOOL {
	return msgSend(BOOL, self, "supportsDestination:", destination)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLCommandBufferDescriptor")
CommandBufferDescriptor :: struct { using _: NS.Copying(CommandBufferDescriptor) }

@(objc_type=CommandBufferDescriptor, objc_name="alloc", objc_is_class_method=true)
CommandBufferDescriptor_alloc :: #force_inline proc "c" () -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, CommandBufferDescriptor, "alloc")
}
@(objc_type=CommandBufferDescriptor, objc_name="init")
CommandBufferDescriptor_init :: #force_inline proc "c" (self: ^CommandBufferDescriptor) -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, self, "init")
}
@(objc_type=CommandBufferDescriptor, objc_name="errorOptions")
CommandBufferDescriptor_errorOptions :: #force_inline proc "c" (self: ^CommandBufferDescriptor) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBufferDescriptor, objc_name="retainedReferences")
CommandBufferDescriptor_retainedReferences :: #force_inline proc "c" (self: ^CommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBufferDescriptor, objc_name="setErrorOptions")
CommandBufferDescriptor_setErrorOptions :: #force_inline proc "c" (self: ^CommandBufferDescriptor, errorOptions: CommandBufferErrorOption) {
	msgSend(nil, self, "setErrorOptions:", errorOptions)
}
@(objc_type=CommandBufferDescriptor, objc_name="setRetainedReferences")
CommandBufferDescriptor_setRetainedReferences :: #force_inline proc "c" (self: ^CommandBufferDescriptor, retainedReferences: BOOL) {
	msgSend(nil, self, "setRetainedReferences:", retainedReferences)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLCompileOptions")
CompileOptions :: struct { using _: NS.Copying(CompileOptions) }

@(objc_type=CompileOptions, objc_name="alloc", objc_is_class_method=true)
CompileOptions_alloc :: #force_inline proc "c" () -> ^CompileOptions {
	return msgSend(^CompileOptions, CompileOptions, "alloc")
}
@(objc_type=CompileOptions, objc_name="init")
CompileOptions_init :: #force_inline proc "c" (self: ^CompileOptions) -> ^CompileOptions {
	return msgSend(^CompileOptions, self, "init")
}
@(objc_type=CompileOptions, objc_name="fastMathEnabled")
CompileOptions_fastMathEnabled :: #force_inline proc "c" (self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "fastMathEnabled")
}
@(objc_type=CompileOptions, objc_name="installName")
CompileOptions_installName :: #force_inline proc "c" (self: ^CompileOptions) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=CompileOptions, objc_name="languageVersion")
CompileOptions_languageVersion :: #force_inline proc "c" (self: ^CompileOptions) -> LanguageVersion {
	return msgSend(LanguageVersion, self, "languageVersion")
}
@(objc_type=CompileOptions, objc_name="libraries")
CompileOptions_libraries :: #force_inline proc "c" (self: ^CompileOptions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "libraries")
}
@(objc_type=CompileOptions, objc_name="libraryType")
CompileOptions_libraryType :: #force_inline proc "c" (self: ^CompileOptions) -> LibraryType {
	return msgSend(LibraryType, self, "libraryType")
}
@(objc_type=CompileOptions, objc_name="preprocessorMacros")
CompileOptions_preprocessorMacros :: #force_inline proc "c" (self: ^CompileOptions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "preprocessorMacros")
}
@(objc_type=CompileOptions, objc_name="preserveInvariance")
CompileOptions_preserveInvariance :: #force_inline proc "c" (self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "preserveInvariance")
}
@(objc_type=CompileOptions, objc_name="setFastMathEnabled")
CompileOptions_setFastMathEnabled :: #force_inline proc "c" (self: ^CompileOptions, fastMathEnabled: BOOL) {
	msgSend(nil, self, "setFastMathEnabled:", fastMathEnabled)
}
@(objc_type=CompileOptions, objc_name="setInstallName")
CompileOptions_setInstallName :: #force_inline proc "c" (self: ^CompileOptions, installName: ^NS.String) {
	msgSend(nil, self, "setInstallName:", installName)
}
@(objc_type=CompileOptions, objc_name="setLanguageVersion")
CompileOptions_setLanguageVersion :: #force_inline proc "c" (self: ^CompileOptions, languageVersion: LanguageVersion) {
	msgSend(nil, self, "setLanguageVersion:", languageVersion)
}
@(objc_type=CompileOptions, objc_name="setLibraries")
CompileOptions_setLibraries :: #force_inline proc "c" (self: ^CompileOptions, libraries: ^NS.Array) {
	msgSend(nil, self, "setLibraries:", libraries)
}
@(objc_type=CompileOptions, objc_name="setLibraryType")
CompileOptions_setLibraryType :: #force_inline proc "c" (self: ^CompileOptions, libraryType: LibraryType) {
	msgSend(nil, self, "setLibraryType:", libraryType)
}
@(objc_type=CompileOptions, objc_name="setPreprocessorMacros")
CompileOptions_setPreprocessorMacros :: #force_inline proc "c" (self: ^CompileOptions, preprocessorMacros: ^NS.Dictionary) {
	msgSend(nil, self, "setPreprocessorMacros:", preprocessorMacros)
}
@(objc_type=CompileOptions, objc_name="setPreserveInvariance")
CompileOptions_setPreserveInvariance :: #force_inline proc "c" (self: ^CompileOptions, preserveInvariance: BOOL) {
	msgSend(nil, self, "setPreserveInvariance:", preserveInvariance)
}
@(objc_type=CompileOptions, objc_name="optimizationLevel")
CompileOptions_optimizationLevel :: #force_inline proc "c" (self: ^CompileOptions) -> LibraryOptimizationLevel {
	return msgSend(LibraryOptimizationLevel, self, "optimizationLevel")
}
@(objc_type=CompileOptions, objc_name="setOptimizationLevel")
CompileOptions_setOptimizationLevel :: #force_inline proc "c" (self: ^CompileOptions, optimizationLevel: LibraryOptimizationLevel) {
	msgSend(nil, self, "setOptimizationLevel:", optimizationLevel)
}


////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLComputePassDescriptor")
ComputePassDescriptor :: struct { using _: NS.Copying(ComputePassDescriptor) }

@(objc_type=ComputePassDescriptor, objc_name="alloc", objc_is_class_method=true)
ComputePassDescriptor_alloc :: #force_inline proc "c" () -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "alloc")
}
@(objc_type=ComputePassDescriptor, objc_name="init")
ComputePassDescriptor_init :: #force_inline proc "c" (self: ^ComputePassDescriptor) -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, self, "init")
}
@(objc_type=ComputePassDescriptor, objc_name="computePassDescriptor", objc_is_class_method=true)
ComputePassDescriptor_computePassDescriptor :: #force_inline proc "c" () -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "computePassDescriptor")
}
@(objc_type=ComputePassDescriptor, objc_name="dispatchType")
ComputePassDescriptor_dispatchType :: #force_inline proc "c" (self: ^ComputePassDescriptor) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputePassDescriptor, objc_name="sampleBufferAttachments")
ComputePassDescriptor_sampleBufferAttachments :: #force_inline proc "c" (self: ^ComputePassDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=ComputePassDescriptor, objc_name="setDispatchType")
ComputePassDescriptor_setDispatchType :: #force_inline proc "c" (self: ^ComputePassDescriptor, dispatchType: DispatchType) {
	msgSend(nil, self, "setDispatchType:", dispatchType)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLComputePassSampleBufferAttachmentDescriptor")
ComputePassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(ComputePassSampleBufferAttachmentDescriptor) }

@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
ComputePassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, ComputePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="init")
ComputePassSampleBufferAttachmentDescriptor_init :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor, sampleBuffer: ^Buffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLComputePassSampleBufferAttachmentDescriptorArray")
ComputePassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
ComputePassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, ComputePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ComputePassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptorArray) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ComputePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ComputePassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachment: ^ComputePassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLComputePipelineDescriptor")
ComputePipelineDescriptor :: struct { using _: NS.Copying(ComputePipelineDescriptor) }

@(objc_type=ComputePipelineDescriptor, objc_name="alloc", objc_is_class_method=true)
ComputePipelineDescriptor_alloc :: #force_inline proc "c" () -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, ComputePipelineDescriptor, "alloc")
}
@(objc_type=ComputePipelineDescriptor, objc_name="init")
ComputePipelineDescriptor_init :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, self, "init")
}
@(objc_type=ComputePipelineDescriptor, objc_name="binaryArchives")
ComputePipelineDescriptor_binaryArchives :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=ComputePipelineDescriptor, objc_name="buffers")
ComputePipelineDescriptor_buffers :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "buffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="computeFunction")
ComputePipelineDescriptor_computeFunction :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "computeFunction")
}
@(objc_type=ComputePipelineDescriptor, objc_name="insertLibraries")
ComputePipelineDescriptor_insertLibraries :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "insertLibraries")
}
@(objc_type=ComputePipelineDescriptor, objc_name="label")
ComputePipelineDescriptor_label :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineDescriptor, objc_name="linkedFunctions")
ComputePipelineDescriptor_linkedFunctions :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "linkedFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxCallStackDepth")
ComputePipelineDescriptor_maxCallStackDepth :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxCallStackDepth")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_maxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineDescriptor, objc_name="reset")
ComputePipelineDescriptor_reset :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=ComputePipelineDescriptor, objc_name="setBinaryArchives")
ComputePipelineDescriptor_setBinaryArchives :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setComputeFunction")
ComputePipelineDescriptor_setComputeFunction :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, computeFunction: ^Function) {
	msgSend(nil, self, "setComputeFunction:", computeFunction)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setInsertLibraries")
ComputePipelineDescriptor_setInsertLibraries :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, insertLibraries: ^NS.Array) {
	msgSend(nil, self, "setInsertLibraries:", insertLibraries)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLabel")
ComputePipelineDescriptor_setLabel :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLinkedFunctions")
ComputePipelineDescriptor_setLinkedFunctions :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, linkedFunctions: ^LinkedFunctions) {
	msgSend(nil, self, "setLinkedFunctions:", linkedFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxCallStackDepth")
ComputePipelineDescriptor_setMaxCallStackDepth :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, maxCallStackDepth: NS.UInteger) {
	msgSend(nil, self, "setMaxCallStackDepth:", maxCallStackDepth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setStageInputDescriptor")
ComputePipelineDescriptor_setStageInputDescriptor :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, stageInputDescriptor: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "setStageInputDescriptor:", stageInputDescriptor)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportAddingBinaryFunctions")
ComputePipelineDescriptor_setSupportAddingBinaryFunctions :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, supportAddingBinaryFunctions: BOOL) {
	msgSend(nil, self, "setSupportAddingBinaryFunctions:", supportAddingBinaryFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
ComputePipelineDescriptor_setSupportIndirectCommandBuffers :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setThreadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_setThreadGroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^ComputePipelineDescriptor, threadGroupSizeIsMultipleOfThreadExecutionWidth: BOOL) {
	msgSend(nil, self, "setThreadGroupSizeIsMultipleOfThreadExecutionWidth:", threadGroupSizeIsMultipleOfThreadExecutionWidth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="stageInputDescriptor")
ComputePipelineDescriptor_stageInputDescriptor :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "stageInputDescriptor")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportAddingBinaryFunctions")
ComputePipelineDescriptor_supportAddingBinaryFunctions :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportAddingBinaryFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportIndirectCommandBuffers")
ComputePipelineDescriptor_supportIndirectCommandBuffers :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="threadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_threadGroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "threadGroupSizeIsMultipleOfThreadExecutionWidth")
}
@(objc_type=ComputePipelineDescriptor, objc_name="gpuResourceID")
ComputePipelineDescriptor_gpuResourceID :: #force_inline proc "c" (self: ^ComputePipelineDescriptor) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}


////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLComputePipelineReflection")
ComputePipelineReflection :: struct { using _: NS.Object }

@(objc_type=ComputePipelineReflection, objc_name="alloc", objc_is_class_method=true)
ComputePipelineReflection_alloc :: #force_inline proc "c" () -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, ComputePipelineReflection, "alloc")
}
@(objc_type=ComputePipelineReflection, objc_name="init")
ComputePipelineReflection_init :: #force_inline proc "c" (self: ^ComputePipelineReflection) -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, self, "init")
}
@(objc_type=ComputePipelineReflection, objc_name="bindings")
ComputePipelineReflection_bindings :: #force_inline proc "c" (self: ^ComputePipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "bindings")
}
@(objc_type=ComputePipelineReflection, objc_name="arguments")
ComputePipelineReflection_arguments :: #force_inline proc "c" (self: ^ComputePipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "arguments")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLCounterSampleBufferDescriptor")
CounterSampleBufferDescriptor :: struct { using _: NS.Copying(CounterSampleBufferDescriptor) }

@(objc_type=CounterSampleBufferDescriptor, objc_name="alloc", objc_is_class_method=true)
CounterSampleBufferDescriptor_alloc :: #force_inline proc "c" () -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, CounterSampleBufferDescriptor, "alloc")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="init")
CounterSampleBufferDescriptor_init :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor) -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, self, "init")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="counterSet")
CounterSampleBufferDescriptor_counterSet :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor) -> ^CounterSet {
	return msgSend(^CounterSet, self, "counterSet")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="label")
CounterSampleBufferDescriptor_label :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="sampleCount")
CounterSampleBufferDescriptor_sampleCount :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setCounterSet")
CounterSampleBufferDescriptor_setCounterSet :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor, counterSet: ^CounterSet) {
	msgSend(nil, self, "setCounterSet:", counterSet)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setLabel")
CounterSampleBufferDescriptor_setLabel :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setSampleCount")
CounterSampleBufferDescriptor_setSampleCount :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setStorageMode")
CounterSampleBufferDescriptor_setStorageMode :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="storageMode")
CounterSampleBufferDescriptor_storageMode :: #force_inline proc "c" (self: ^CounterSampleBufferDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLDepthStencilDescriptor")
DepthStencilDescriptor :: struct { using _: NS.Copying(DepthStencilDescriptor) }

@(objc_type=DepthStencilDescriptor, objc_name="alloc", objc_is_class_method=true)
DepthStencilDescriptor_alloc :: #force_inline proc "c" () -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, DepthStencilDescriptor, "alloc")
}
@(objc_type=DepthStencilDescriptor, objc_name="init")
DepthStencilDescriptor_init :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, self, "init")
}
@(objc_type=DepthStencilDescriptor, objc_name="backFaceStencil")
DepthStencilDescriptor_backFaceStencil :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "backFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="depthCompareFunction")
DepthStencilDescriptor_depthCompareFunction :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "depthCompareFunction")
}
@(objc_type=DepthStencilDescriptor, objc_name="frontFaceStencil")
DepthStencilDescriptor_frontFaceStencil :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "frontFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="isDepthWriteEnabled")
DepthStencilDescriptor_isDepthWriteEnabled :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isDepthWriteEnabled")
}
@(objc_type=DepthStencilDescriptor, objc_name="label")
DepthStencilDescriptor_label :: #force_inline proc "c" (self: ^DepthStencilDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DepthStencilDescriptor, objc_name="setBackFaceStencil")
DepthStencilDescriptor_setBackFaceStencil :: #force_inline proc "c" (self: ^DepthStencilDescriptor, backFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setBackFaceStencil:", backFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthCompareFunction")
DepthStencilDescriptor_setDepthCompareFunction :: #force_inline proc "c" (self: ^DepthStencilDescriptor, depthCompareFunction: CompareFunction) {
	msgSend(nil, self, "setDepthCompareFunction:", depthCompareFunction)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthWriteEnabled")
DepthStencilDescriptor_setDepthWriteEnabled :: #force_inline proc "c" (self: ^DepthStencilDescriptor, depthWriteEnabled: BOOL) {
	msgSend(nil, self, "setDepthWriteEnabled:", depthWriteEnabled)
}
@(objc_type=DepthStencilDescriptor, objc_name="setFrontFaceStencil")
DepthStencilDescriptor_setFrontFaceStencil :: #force_inline proc "c" (self: ^DepthStencilDescriptor, frontFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setFrontFaceStencil:", frontFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setLabel")
DepthStencilDescriptor_setLabel :: #force_inline proc "c" (self: ^DepthStencilDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLFunctionConstant")
FunctionConstant :: struct { using _: NS.Copying(FunctionConstant) }

@(objc_type=FunctionConstant, objc_name="alloc", objc_is_class_method=true)
FunctionConstant_alloc :: #force_inline proc "c" () -> ^FunctionConstant {
	return msgSend(^FunctionConstant, FunctionConstant, "alloc")
}
@(objc_type=FunctionConstant, objc_name="init")
FunctionConstant_init :: #force_inline proc "c" (self: ^FunctionConstant) -> ^FunctionConstant {
	return msgSend(^FunctionConstant, self, "init")
}
@(objc_type=FunctionConstant, objc_name="index")
FunctionConstant_index :: #force_inline proc "c" (self: ^FunctionConstant) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=FunctionConstant, objc_name="name")
FunctionConstant_name :: #force_inline proc "c" (self: ^FunctionConstant) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionConstant, objc_name="required")
FunctionConstant_required :: #force_inline proc "c" (self: ^FunctionConstant) -> BOOL {
	return msgSend(BOOL, self, "required")
}
@(objc_type=FunctionConstant, objc_name="type")
FunctionConstant_type :: #force_inline proc "c" (self: ^FunctionConstant) -> DataType {
	return msgSend(DataType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLFunctionConstantValues")
FunctionConstantValues :: struct { using _: NS.Copying(FunctionConstantValues) }

@(objc_type=FunctionConstantValues, objc_name="alloc", objc_is_class_method=true)
FunctionConstantValues_alloc :: #force_inline proc "c" () -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, FunctionConstantValues, "alloc")
}
@(objc_type=FunctionConstantValues, objc_name="init")
FunctionConstantValues_init :: #force_inline proc "c" (self: ^FunctionConstantValues) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "init")
}
@(objc_type=FunctionConstantValues, objc_name="reset")
FunctionConstantValues_reset :: #force_inline proc "c" (self: ^FunctionConstantValues) {
	msgSend(nil, self, "reset")
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValue")
FunctionConstantValues_setConstantValue :: #force_inline proc "c" (self: ^FunctionConstantValues, value: rawptr, type: DataType, index: NS.UInteger) {
	msgSend(nil, self, "setConstantValue:type:atIndex:", value, type, index)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValueWithName")
FunctionConstantValues_setConstantValueWithName :: #force_inline proc "c" (self: ^FunctionConstantValues, value: rawptr, type: DataType, name: ^NS.String) {
	msgSend(nil, self, "setConstantValue:type:withName:", value, type, name)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValues")
FunctionConstantValues_setConstantValues :: #force_inline proc "c" (self: ^FunctionConstantValues, values: rawptr, type: DataType, range: NS.Range) {
	msgSend(nil, self, "setConstantValues:type:withRange:", values, type, range)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLFunctionDescriptor")
FunctionDescriptor :: struct { using _: NS.Copying(FunctionDescriptor) }

@(objc_type=FunctionDescriptor, objc_name="alloc", objc_is_class_method=true)
FunctionDescriptor_alloc :: #force_inline proc "c" () -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "alloc")
}
@(objc_type=FunctionDescriptor, objc_name="init")
FunctionDescriptor_init :: #force_inline proc "c" (self: ^FunctionDescriptor) -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, self, "init")
}
@(objc_type=FunctionDescriptor, objc_name="constantValues")
FunctionDescriptor_constantValues :: #force_inline proc "c" (self: ^FunctionDescriptor) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "constantValues")
}
@(objc_type=FunctionDescriptor, objc_name="functionDescriptor", objc_is_class_method=true)
FunctionDescriptor_functionDescriptor :: #force_inline proc "c" () -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "functionDescriptor")
}
@(objc_type=FunctionDescriptor, objc_name="name")
FunctionDescriptor_name :: #force_inline proc "c" (self: ^FunctionDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionDescriptor, objc_name="options")
FunctionDescriptor_options :: #force_inline proc "c" (self: ^FunctionDescriptor) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=FunctionDescriptor, objc_name="setConstantValues")
FunctionDescriptor_setConstantValues :: #force_inline proc "c" (self: ^FunctionDescriptor, constantValues: ^FunctionConstantValues) {
	msgSend(nil, self, "setConstantValues:", constantValues)
}
@(objc_type=FunctionDescriptor, objc_name="setName")
FunctionDescriptor_setName :: #force_inline proc "c" (self: ^FunctionDescriptor, name: ^NS.String) {
	msgSend(nil, self, "setName:", name)
}
@(objc_type=FunctionDescriptor, objc_name="setOptions")
FunctionDescriptor_setOptions :: #force_inline proc "c" (self: ^FunctionDescriptor, options: FunctionOptions) {
	msgSend(nil, self, "setOptions:", options)
}
@(objc_type=FunctionDescriptor, objc_name="setSpecializedName")
FunctionDescriptor_setSpecializedName :: #force_inline proc "c" (self: ^FunctionDescriptor, specializedName: ^NS.String) {
	msgSend(nil, self, "setSpecializedName:", specializedName)
}
@(objc_type=FunctionDescriptor, objc_name="specializedName")
FunctionDescriptor_specializedName :: #force_inline proc "c" (self: ^FunctionDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "specializedName")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLIntersectionFunctionDescriptor")
IntersectionFunctionDescriptor :: struct { using _: NS.Copying(IntersectionFunctionDescriptor) }

@(objc_type=IntersectionFunctionDescriptor, objc_name="alloc", objc_is_class_method=true)
IntersectionFunctionDescriptor_alloc :: #force_inline proc "c" () -> ^IntersectionFunctionDescriptor {
	return msgSend(^IntersectionFunctionDescriptor, IntersectionFunctionDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionDescriptor, objc_name="init")
IntersectionFunctionDescriptor_init :: #force_inline proc "c" (self: ^IntersectionFunctionDescriptor) -> ^IntersectionFunctionDescriptor {
	return msgSend(^IntersectionFunctionDescriptor, self, "init")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLHeapDescriptor")
HeapDescriptor :: struct { using _: NS.Copying(HeapDescriptor) }

@(objc_type=HeapDescriptor, objc_name="alloc", objc_is_class_method=true)
HeapDescriptor_alloc :: #force_inline proc "c" () -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, HeapDescriptor, "alloc")
}
@(objc_type=HeapDescriptor, objc_name="init")
HeapDescriptor_init :: #force_inline proc "c" (self: ^HeapDescriptor) -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, self, "init")
}
@(objc_type=HeapDescriptor, objc_name="cpuCacheMode")
HeapDescriptor_cpuCacheMode :: #force_inline proc "c" (self: ^HeapDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=HeapDescriptor, objc_name="hazardTrackingMode")
HeapDescriptor_hazardTrackingMode :: #force_inline proc "c" (self: ^HeapDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=HeapDescriptor, objc_name="resourceOptions")
HeapDescriptor_resourceOptions :: #force_inline proc "c" (self: ^HeapDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=HeapDescriptor, objc_name="setCpuCacheMode")
HeapDescriptor_setCpuCacheMode :: #force_inline proc "c" (self: ^HeapDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}

@(objc_type=HeapDescriptor, objc_name="sparsePageSize")
HeapDescriptor_sparsePageSize :: #force_inline proc "c" (self: ^HeapDescriptor) -> SparsePageSize {
	return msgSend(SparsePageSize, self, "sparsePageSize")
}
@(objc_type=HeapDescriptor, objc_name="setSparsePageSize")
HeapDescriptor_setSparsePageSize :: #force_inline proc "c" (self: ^HeapDescriptor, sparsePageSize: SparsePageSize) {
	msgSend(nil, self, "setSparsePageSize:", sparsePageSize)
}

@(objc_type=HeapDescriptor, objc_name="setHazardTrackingMode")
HeapDescriptor_setHazardTrackingMode :: #force_inline proc "c" (self: ^HeapDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=HeapDescriptor, objc_name="setResourceOptions")
HeapDescriptor_setResourceOptions :: #force_inline proc "c" (self: ^HeapDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=HeapDescriptor, objc_name="setSize")
HeapDescriptor_setSize :: #force_inline proc "c" (self: ^HeapDescriptor, size: NS.UInteger) {
	msgSend(nil, self, "setSize:", size)
}
@(objc_type=HeapDescriptor, objc_name="setStorageMode")
HeapDescriptor_setStorageMode :: #force_inline proc "c" (self: ^HeapDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=HeapDescriptor, objc_name="setType")
HeapDescriptor_setType :: #force_inline proc "c" (self: ^HeapDescriptor, type: HeapType) {
	msgSend(nil, self, "setType:", type)
}
@(objc_type=HeapDescriptor, objc_name="size")
HeapDescriptor_size :: #force_inline proc "c" (self: ^HeapDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}
@(objc_type=HeapDescriptor, objc_name="storageMode")
HeapDescriptor_storageMode :: #force_inline proc "c" (self: ^HeapDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=HeapDescriptor, objc_name="type")
HeapDescriptor_type :: #force_inline proc "c" (self: ^HeapDescriptor) -> HeapType {
	return msgSend(HeapType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLIndirectCommandBufferDescriptor")
IndirectCommandBufferDescriptor :: struct { using _: NS.Copying(IndirectCommandBufferDescriptor) }

@(objc_type=IndirectCommandBufferDescriptor, objc_name="alloc", objc_is_class_method=true)
IndirectCommandBufferDescriptor_alloc :: #force_inline proc "c" () -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, IndirectCommandBufferDescriptor, "alloc")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="init")
IndirectCommandBufferDescriptor_init :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, self, "init")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="commandTypes")
IndirectCommandBufferDescriptor_commandTypes :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> IndirectCommandType {
	return msgSend(IndirectCommandType, self, "commandTypes")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritBuffers")
IndirectCommandBufferDescriptor_inheritBuffers :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritBuffers")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritPipelineState")
IndirectCommandBufferDescriptor_inheritPipelineState :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritPipelineState")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_maxFragmentBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxFragmentBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxKernelBufferBindCount")
IndirectCommandBufferDescriptor_maxKernelBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxKernelBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxVertexBufferBindCount")
IndirectCommandBufferDescriptor_maxVertexBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxVertexBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setCommandTypes")
IndirectCommandBufferDescriptor_setCommandTypes :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, commandTypes: IndirectCommandType) {
	msgSend(nil, self, "setCommandTypes:", commandTypes)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritBuffers")
IndirectCommandBufferDescriptor_setInheritBuffers :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, inheritBuffers: BOOL) {
	msgSend(nil, self, "setInheritBuffers:", inheritBuffers)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritPipelineState")
IndirectCommandBufferDescriptor_setInheritPipelineState :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, inheritPipelineState: BOOL) {
	msgSend(nil, self, "setInheritPipelineState:", inheritPipelineState)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_setMaxFragmentBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, maxFragmentBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxFragmentBufferBindCount:", maxFragmentBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxKernelBufferBindCount")
IndirectCommandBufferDescriptor_setMaxKernelBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, maxKernelBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxKernelBufferBindCount:", maxKernelBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxVertexBufferBindCount")
IndirectCommandBufferDescriptor_setMaxVertexBufferBindCount :: #force_inline proc "c" (self: ^IndirectCommandBufferDescriptor, maxVertexBufferBindCount: NS.UInteger) {
	msgSend(nil, self, "setMaxVertexBufferBindCount:", maxVertexBufferBindCount)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLInstanceAccelerationStructureDescriptor")
InstanceAccelerationStructureDescriptor :: struct { using _: NS.Copying(InstanceAccelerationStructureDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="alloc", objc_is_class_method=true)
InstanceAccelerationStructureDescriptor_alloc :: #force_inline proc "c" () -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "alloc")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="init")
InstanceAccelerationStructureDescriptor_init :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, self, "init")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="descriptor", objc_is_class_method=true)
InstanceAccelerationStructureDescriptor_descriptor :: #force_inline proc "c" () -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceCount")
InstanceAccelerationStructureDescriptor_instanceCount :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceCount")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_instanceDescriptorBuffer :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "instanceDescriptorBuffer")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_instanceDescriptorBufferOffset :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceDescriptorBufferOffset")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorStride")
InstanceAccelerationStructureDescriptor_instanceDescriptorStride :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "instanceDescriptorStride")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_instancedAccelerationStructures :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "instancedAccelerationStructures")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceCount")
InstanceAccelerationStructureDescriptor_setInstanceCount :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, instanceCount: NS.UInteger) {
	msgSend(nil, self, "setInstanceCount:", instanceCount)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBuffer :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBuffer: ^Buffer) {
	msgSend(nil, self, "setInstanceDescriptorBuffer:", instanceDescriptorBuffer)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBufferOffset :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setInstanceDescriptorBufferOffset:", instanceDescriptorBufferOffset)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorStride")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorStride :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorStride: NS.UInteger) {
	msgSend(nil, self, "setInstanceDescriptorStride:", instanceDescriptorStride)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_setInstancedAccelerationStructures :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, instancedAccelerationStructures: ^NS.Array) {
	msgSend(nil, self, "setInstancedAccelerationStructures:", instancedAccelerationStructures)
}

@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorType")
InstanceAccelerationStructureDescriptor_instanceDescriptorType :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> AccelerationStructureInstanceDescriptorType {
	return msgSend(AccelerationStructureInstanceDescriptorType, self, "instanceDescriptorType")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorType")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorType :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, buffer: AccelerationStructureInstanceDescriptorType) {
	msgSend(nil, self, "setInstanceDescriptorType:", buffer)
}


@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformBuffer")
InstanceAccelerationStructureDescriptor_motionTransformBuffer :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "motionTransformBuffer")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformBuffer")
InstanceAccelerationStructureDescriptor_setMotionTransformBuffer :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, buffer: ^Buffer) {
	msgSend(nil, self, "setMotionTransformBuffer:", buffer)
}


@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformBufferOffset")
InstanceAccelerationStructureDescriptor_motionTransformBufferOffset :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionTransformBufferOffset")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformBufferOffset")
InstanceAccelerationStructureDescriptor_setMotionTransformBufferOffset :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setMotionTransformBufferOffset:", offset)
}

@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="motionTransformCount")
InstanceAccelerationStructureDescriptor_motionTransformCount :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionTransformCount")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setMotionTransformCount")
InstanceAccelerationStructureDescriptor_setMotionTransformCount :: #force_inline proc "c" (self: ^InstanceAccelerationStructureDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setMotionTransformCount:", offset)
}



////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLIntersectionFunctionTableDescriptor")
IntersectionFunctionTableDescriptor :: struct { using _: NS.Copying(IntersectionFunctionTableDescriptor) }

@(objc_type=IntersectionFunctionTableDescriptor, objc_name="alloc", objc_is_class_method=true)
IntersectionFunctionTableDescriptor_alloc :: #force_inline proc "c" () -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="init")
IntersectionFunctionTableDescriptor_init :: #force_inline proc "c" (self: ^IntersectionFunctionTableDescriptor) -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, self, "init")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="functionCount")
IntersectionFunctionTableDescriptor_functionCount :: #force_inline proc "c" (self: ^IntersectionFunctionTableDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "functionCount")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="intersectionFunctionTableDescriptor", objc_is_class_method=true)
IntersectionFunctionTableDescriptor_intersectionFunctionTableDescriptor :: #force_inline proc "c" () -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "intersectionFunctionTableDescriptor")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="setFunctionCount")
IntersectionFunctionTableDescriptor_setFunctionCount :: #force_inline proc "c" (self: ^IntersectionFunctionTableDescriptor, functionCount: NS.UInteger) {
	msgSend(nil, self, "setFunctionCount:", functionCount)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLLinkedFunctions")
LinkedFunctions :: struct { using _: NS.Copying(LinkedFunctions) }

@(objc_type=LinkedFunctions, objc_name="alloc", objc_is_class_method=true)
LinkedFunctions_alloc :: #force_inline proc "c" () -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "alloc")
}
@(objc_type=LinkedFunctions, objc_name="init")
LinkedFunctions_init :: #force_inline proc "c" (self: ^LinkedFunctions) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "init")
}
@(objc_type=LinkedFunctions, objc_name="binaryFunctions")
LinkedFunctions_binaryFunctions :: #force_inline proc "c" (self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryFunctions")
}
@(objc_type=LinkedFunctions, objc_name="functions")
LinkedFunctions_functions :: #force_inline proc "c" (self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functions")
}
@(objc_type=LinkedFunctions, objc_name="groups")
LinkedFunctions_groups :: #force_inline proc "c" (self: ^LinkedFunctions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "groups")
}
@(objc_type=LinkedFunctions, objc_name="linkedFunctions", objc_is_class_method=true)
LinkedFunctions_linkedFunctions :: #force_inline proc "c" () -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "linkedFunctions")
}
@(objc_type=LinkedFunctions, objc_name="setBinaryFunctions")
LinkedFunctions_setBinaryFunctions :: #force_inline proc "c" (self: ^LinkedFunctions, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "setBinaryFunctions:", binaryFunctions)
}
@(objc_type=LinkedFunctions, objc_name="setFunctions")
LinkedFunctions_setFunctions :: #force_inline proc "c" (self: ^LinkedFunctions, functions: ^NS.Array) {
	msgSend(nil, self, "setFunctions:", functions)
}
@(objc_type=LinkedFunctions, objc_name="setGroups")
LinkedFunctions_setGroups :: #force_inline proc "c" (self: ^LinkedFunctions, groups: ^NS.Dictionary) {
	msgSend(nil, self, "setGroups:", groups)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLPipelineBufferDescriptor")
PipelineBufferDescriptor :: struct { using _: NS.Copying(PipelineBufferDescriptor) }

@(objc_type=PipelineBufferDescriptor, objc_name="alloc", objc_is_class_method=true)
PipelineBufferDescriptor_alloc :: #force_inline proc "c" () -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, PipelineBufferDescriptor, "alloc")
}
@(objc_type=PipelineBufferDescriptor, objc_name="init")
PipelineBufferDescriptor_init :: #force_inline proc "c" (self: ^PipelineBufferDescriptor) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "init")
}
@(objc_type=PipelineBufferDescriptor, objc_name="mutability")
PipelineBufferDescriptor_mutability :: #force_inline proc "c" (self: ^PipelineBufferDescriptor) -> Mutability {
	return msgSend(Mutability, self, "mutability")
}
@(objc_type=PipelineBufferDescriptor, objc_name="setMutability")
PipelineBufferDescriptor_setMutability :: #force_inline proc "c" (self: ^PipelineBufferDescriptor, mutability: Mutability) {
	msgSend(nil, self, "setMutability:", mutability)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLPipelineBufferDescriptorArray")
PipelineBufferDescriptorArray :: struct { using _: NS.Object }

@(objc_type=PipelineBufferDescriptorArray, objc_name="alloc", objc_is_class_method=true)
PipelineBufferDescriptorArray_alloc :: #force_inline proc "c" () -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, PipelineBufferDescriptorArray, "alloc")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="init")
PipelineBufferDescriptorArray_init :: #force_inline proc "c" (self: ^PipelineBufferDescriptorArray) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "init")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="object")
PipelineBufferDescriptorArray_object :: #force_inline proc "c" (self: ^PipelineBufferDescriptorArray, bufferIndex: NS.UInteger) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "objectAtIndexedSubscript:", bufferIndex)
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="setObject")
PipelineBufferDescriptorArray_setObject :: #force_inline proc "c" (self: ^PipelineBufferDescriptorArray, buffer: ^PipelineBufferDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", buffer, bufferIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLPointerType")
PointerType :: struct { using _: Type }

@(objc_type=PointerType, objc_name="alloc", objc_is_class_method=true)
PointerType_alloc :: #force_inline proc "c" () -> ^PointerType {
	return msgSend(^PointerType, PointerType, "alloc")
}
@(objc_type=PointerType, objc_name="init")
PointerType_init :: #force_inline proc "c" (self: ^PointerType) -> ^PointerType {
	return msgSend(^PointerType, self, "init")
}
@(objc_type=PointerType, objc_name="access")
PointerType_access :: #force_inline proc "c" (self: ^PointerType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=PointerType, objc_name="alignment")
PointerType_alignment :: #force_inline proc "c" (self: ^PointerType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "alignment")
}
@(objc_type=PointerType, objc_name="dataSize")
PointerType_dataSize :: #force_inline proc "c" (self: ^PointerType) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "dataSize")
}
@(objc_type=PointerType, objc_name="elementArrayType")
PointerType_elementArrayType :: #force_inline proc "c" (self: ^PointerType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=PointerType, objc_name="elementIsArgumentBuffer")
PointerType_elementIsArgumentBuffer :: #force_inline proc "c" (self: ^PointerType) -> BOOL {
	return msgSend(BOOL, self, "elementIsArgumentBuffer")
}
@(objc_type=PointerType, objc_name="elementStructType")
PointerType_elementStructType :: #force_inline proc "c" (self: ^PointerType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=PointerType, objc_name="elementType")
PointerType_elementType :: #force_inline proc "c" (self: ^PointerType) -> DataType {
	return msgSend(DataType, self, "elementType")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLPrimitiveAccelerationStructureDescriptor")
PrimitiveAccelerationStructureDescriptor :: struct { using _: NS.Copying(PrimitiveAccelerationStructureDescriptor), using _: AccelerationStructureDescriptor }

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="alloc", objc_is_class_method=true)
PrimitiveAccelerationStructureDescriptor_alloc :: #force_inline proc "c" () -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "alloc")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="init")
PrimitiveAccelerationStructureDescriptor_init :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, self, "init")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="descriptor", objc_is_class_method=true)
PrimitiveAccelerationStructureDescriptor_descriptor :: #force_inline proc "c" () -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="geometryDescriptors")
PrimitiveAccelerationStructureDescriptor_geometryDescriptors :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "geometryDescriptors")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setGeometryDescriptors")
PrimitiveAccelerationStructureDescriptor_setGeometryDescriptors :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, geometryDescriptors: ^NS.Array) {
	msgSend(nil, self, "setGeometryDescriptors:", geometryDescriptors)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionStartBorderMode")
PrimitiveAccelerationStructureDescriptor_motionStartBorderMode :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionStartBorderMode")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionStartBorderMode")
PrimitiveAccelerationStructureDescriptor_setMotionStartBorderMode :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, motionStartBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionStartBorderMode:", motionStartBorderMode)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionEndBorderMode")
PrimitiveAccelerationStructureDescriptor_motionEndBorderMode :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionEndBorderMode")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionEndBorderMode")
PrimitiveAccelerationStructureDescriptor_setMotionEndBorderMode :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, motionEndBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionEndBorderMode:", motionEndBorderMode)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionStartTime")
PrimitiveAccelerationStructureDescriptor_motionStartTime :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> f32 {
	return msgSend(f32, self, "motionStartTime")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionStartTime")
PrimitiveAccelerationStructureDescriptor_setMotionStartTime :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, motionStartTime: f32) {
	msgSend(nil, self, "setMotionStartTime:", motionStartTime)
}


@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionEndTime")
PrimitiveAccelerationStructureDescriptor_motionEndTime :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> f32 {
	return msgSend(f32, self, "motionEndTime")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionEndTime")
PrimitiveAccelerationStructureDescriptor_setMotionEndTime :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, motionEndTime: f32) {
	msgSend(nil, self, "setMotionEndTime:", motionEndTime)
}

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="motionKeyframeCount")
PrimitiveAccelerationStructureDescriptor_motionKeyframeCount :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "motionKeyframeCount")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setMotionKeyframeCount")
PrimitiveAccelerationStructureDescriptor_setMotionKeyframeCount :: #force_inline proc "c" (self: ^PrimitiveAccelerationStructureDescriptor, motionKeyframeCount: NS.UInteger) {
	msgSend(nil, self, "setMotionKeyframeCount:", motionKeyframeCount)
}



////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRasterizationRateLayerArray")
RasterizationRateLayerArray :: struct { using _: NS.Object }

@(objc_type=RasterizationRateLayerArray, objc_name="alloc", objc_is_class_method=true)
RasterizationRateLayerArray_alloc :: #force_inline proc "c" () -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, RasterizationRateLayerArray, "alloc")
}
@(objc_type=RasterizationRateLayerArray, objc_name="init")
RasterizationRateLayerArray_init :: #force_inline proc "c" (self: ^RasterizationRateLayerArray) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "init")
}
@(objc_type=RasterizationRateLayerArray, objc_name="object")
RasterizationRateLayerArray_object :: #force_inline proc "c" (self: ^RasterizationRateLayerArray, layerIndex: NS.UInteger) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "objectAtIndexedSubscript:", layerIndex)
}
@(objc_type=RasterizationRateLayerArray, objc_name="setObject")
RasterizationRateLayerArray_setObject :: #force_inline proc "c" (self: ^RasterizationRateLayerArray, layer: ^RasterizationRateLayerDescriptor, layerIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", layer, layerIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRasterizationRateLayerDescriptor")
RasterizationRateLayerDescriptor :: struct { using _: NS.Copying(RasterizationRateLayerDescriptor) }

@(objc_type=RasterizationRateLayerDescriptor, objc_name="alloc", objc_is_class_method=true)
RasterizationRateLayerDescriptor_alloc :: #force_inline proc "c" () -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, RasterizationRateLayerDescriptor, "alloc")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontal")
RasterizationRateLayerDescriptor_horizontal :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "horizontal")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontalSampleStorage")
RasterizationRateLayerDescriptor_horizontalSampleStorage :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> [^]f32 { // TODO: how could this be made into a slice?
	return msgSend([^]f32, self, "horizontalSampleStorage")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="init")
RasterizationRateLayerDescriptor_init :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "init")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCount")
RasterizationRateLayerDescriptor_initWithSampleCount :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor, sampleCount: Size) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:", sampleCount)
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCountWithDimensions")
RasterizationRateLayerDescriptor_initWithSampleCountWithDimensions :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor, sampleCount: Size, horizontal: []f32, vertical: []f32) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:horizontal:vertical:", sampleCount, raw_data(horizontal), raw_data(vertical))
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="sampleCount")
RasterizationRateLayerDescriptor_sampleCount :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> Size {
	return msgSend(Size, self, "sampleCount")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="vertical")
RasterizationRateLayerDescriptor_vertical :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "vertical")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="verticalSampleStorage")
RasterizationRateLayerDescriptor_verticalSampleStorage :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor) -> [^]f32 { // TODO: how could this be made into a slice?
	return msgSend([^]f32, self, "verticalSampleStorage")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRasterizationRateMapDescriptor")
RasterizationRateMapDescriptor :: struct { using _: NS.Copying(RasterizationRateMapDescriptor) }

@(objc_type=RasterizationRateMapDescriptor, objc_name="alloc", objc_is_class_method=true)
RasterizationRateMapDescriptor_alloc :: #force_inline proc "c" () -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "alloc")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="init")
RasterizationRateMapDescriptor_init :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, self, "init")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="label")
RasterizationRateMapDescriptor_label :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layer")
RasterizationRateMapDescriptor_layer :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor, layerIndex: NS.UInteger) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "layerAtIndex:", layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layerCount")
RasterizationRateMapDescriptor_layerCount :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "layerCount")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layers")
RasterizationRateMapDescriptor_layers :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "layers")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="rasterizationRateMapDescriptorWithScreenSize", objc_is_class_method=true)
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSize :: #force_inline proc "c" (screenSize: Size) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:", screenSize)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="rasterizationRateMapDescriptorWithScreenSizeWithLayer", objc_is_class_method=true)
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSizeWithLayer :: #force_inline proc "c" (screenSize: Size, layer: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layer:", screenSize, layer)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="rasterizationRateMapDescriptorWithScreenSizeWithLayers", objc_is_class_method=true)
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSizeWithLayers :: #force_inline proc "c" (screenSize: Size, layers: []^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layerCount:layers:", screenSize, NS.UInteger(len(layers)), layers)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="screenSize")
RasterizationRateMapDescriptor_screenSize :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor) -> Size {
	return msgSend(Size, self, "screenSize")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLabel")
RasterizationRateMapDescriptor_setLabel :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLayer")
RasterizationRateMapDescriptor_setLayer :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor, layer: ^RasterizationRateLayerDescriptor, layerIndex: NS.UInteger) {
	msgSend(nil, self, "setLayer:atIndex:", layer, layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setScreenSize")
RasterizationRateMapDescriptor_setScreenSize :: #force_inline proc "c" (self: ^RasterizationRateMapDescriptor, screenSize: Size) {
	msgSend(nil, self, "setScreenSize:", screenSize)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRasterizationRateSampleArray")
RasterizationRateSampleArray :: struct { using _: NS.Object }

@(objc_type=RasterizationRateSampleArray, objc_name="alloc", objc_is_class_method=true)
RasterizationRateSampleArray_alloc :: #force_inline proc "c" () -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, RasterizationRateSampleArray, "alloc")
}
@(objc_type=RasterizationRateSampleArray, objc_name="init")
RasterizationRateSampleArray_init :: #force_inline proc "c" (self: ^RasterizationRateSampleArray) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "init")
}
@(objc_type=RasterizationRateSampleArray, objc_name="object")
RasterizationRateSampleArray_object :: #force_inline proc "c" (self: ^RasterizationRateSampleArray, index: NS.UInteger) -> ^NS.Number {
	return msgSend(^NS.Number, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=RasterizationRateSampleArray, objc_name="setObject")
RasterizationRateSampleArray_setObject :: #force_inline proc "c" (self: ^RasterizationRateSampleArray, value: ^NS.Number, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", value, index)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassAttachmentDescriptor")
RenderPassAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassAttachmentDescriptor) }

@(objc_type=RenderPassAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, RenderPassAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="init")
RenderPassAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="depthPlane")
RenderPassAttachmentDescriptor_depthPlane :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="level")
RenderPassAttachmentDescriptor_level :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "level")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="loadAction")
RenderPassAttachmentDescriptor_loadAction :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> LoadAction {
	return msgSend(LoadAction, self, "loadAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveDepthPlane")
RenderPassAttachmentDescriptor_resolveDepthPlane :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveDepthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveLevel")
RenderPassAttachmentDescriptor_resolveLevel :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveLevel")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveSlice")
RenderPassAttachmentDescriptor_resolveSlice :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "resolveSlice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveTexture")
RenderPassAttachmentDescriptor_resolveTexture :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> ^Texture {
	return msgSend(^Texture, self, "resolveTexture")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setDepthPlane")
RenderPassAttachmentDescriptor_setDepthPlane :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, depthPlane: NS.UInteger) {
	msgSend(nil, self, "setDepthPlane:", depthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLevel")
RenderPassAttachmentDescriptor_setLevel :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, level: NS.UInteger) {
	msgSend(nil, self, "setLevel:", level)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLoadAction")
RenderPassAttachmentDescriptor_setLoadAction :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, loadAction: LoadAction) {
	msgSend(nil, self, "setLoadAction:", loadAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveDepthPlane")
RenderPassAttachmentDescriptor_setResolveDepthPlane :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, resolveDepthPlane: NS.UInteger) {
	msgSend(nil, self, "setResolveDepthPlane:", resolveDepthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveLevel")
RenderPassAttachmentDescriptor_setResolveLevel :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, resolveLevel: NS.UInteger) {
	msgSend(nil, self, "setResolveLevel:", resolveLevel)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveSlice")
RenderPassAttachmentDescriptor_setResolveSlice :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, resolveSlice: NS.UInteger) {
	msgSend(nil, self, "setResolveSlice:", resolveSlice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveTexture")
RenderPassAttachmentDescriptor_setResolveTexture :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, resolveTexture: ^Texture) {
	msgSend(nil, self, "setResolveTexture:", resolveTexture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setSlice")
RenderPassAttachmentDescriptor_setSlice :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, slice: NS.UInteger) {
	msgSend(nil, self, "setSlice:", slice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreAction")
RenderPassAttachmentDescriptor_setStoreAction :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, storeAction: StoreAction) {
	msgSend(nil, self, "setStoreAction:", storeAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreActionOptions")
RenderPassAttachmentDescriptor_setStoreActionOptions :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setTexture")
RenderPassAttachmentDescriptor_setTexture :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor, texture: ^Texture) {
	msgSend(nil, self, "setTexture:", texture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="slice")
RenderPassAttachmentDescriptor_slice :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "slice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeAction")
RenderPassAttachmentDescriptor_storeAction :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> StoreAction {
	return msgSend(StoreAction, self, "storeAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeActionOptions")
RenderPassAttachmentDescriptor_storeActionOptions :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> StoreActionOptions {
	return msgSend(StoreActionOptions, self, "storeActionOptions")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="texture")
RenderPassAttachmentDescriptor_texture :: #force_inline proc "c" (self: ^RenderPassAttachmentDescriptor) -> ^Texture {
	return msgSend(^Texture, self, "texture")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassColorAttachmentDescriptor")
RenderPassColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassColorAttachmentDescriptor), using _: RenderPassAttachmentDescriptor  }

@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassColorAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, RenderPassColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="init")
RenderPassColorAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptor) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="clearColor")
RenderPassColorAttachmentDescriptor_clearColor :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptor) -> ClearColor {
	return msgSend(ClearColor, self, "clearColor")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="setClearColor")
RenderPassColorAttachmentDescriptor_setClearColor :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptor, clearColor: ClearColor) {
	msgSend(nil, self, "setClearColor:", clearColor)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassColorAttachmentDescriptorArray")
RenderPassColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
RenderPassColorAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, RenderPassColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="init")
RenderPassColorAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptorArray) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="object")
RenderPassColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="setObject")
RenderPassColorAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptorArray, attachment: ^RenderPassColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassDepthAttachmentDescriptor")
RenderPassDepthAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassDepthAttachmentDescriptor), using _: RenderPassAttachmentDescriptor }

@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassDepthAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, RenderPassDepthAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="init")
RenderPassDepthAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPassDepthAttachmentDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="clearDepth")
RenderPassDepthAttachmentDescriptor_clearDepth :: #force_inline proc "c" (self: ^RenderPassDepthAttachmentDescriptor) -> f64 {
	return msgSend(f64, self, "clearDepth")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="depthResolveFilter")
RenderPassDepthAttachmentDescriptor_depthResolveFilter :: #force_inline proc "c" (self: ^RenderPassDepthAttachmentDescriptor) -> MultisampleDepthResolveFilter {
	return msgSend(MultisampleDepthResolveFilter, self, "depthResolveFilter")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setClearDepth")
RenderPassDepthAttachmentDescriptor_setClearDepth :: #force_inline proc "c" (self: ^RenderPassDepthAttachmentDescriptor, clearDepth: f64) {
	msgSend(nil, self, "setClearDepth:", clearDepth)
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setDepthResolveFilter")
RenderPassDepthAttachmentDescriptor_setDepthResolveFilter :: #force_inline proc "c" (self: ^RenderPassDepthAttachmentDescriptor, depthResolveFilter: MultisampleDepthResolveFilter) {
	msgSend(nil, self, "setDepthResolveFilter:", depthResolveFilter)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassDescriptor")
RenderPassDescriptor :: struct { using _: NS.Copying(RenderPassDescriptor), using _: AccelerationStructureDescriptor  }

@(objc_type=RenderPassDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "alloc")
}
@(objc_type=RenderPassDescriptor, objc_name="init")
RenderPassDescriptor_init :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "init")
}
@(objc_type=RenderPassDescriptor, objc_name="colorAttachments")
RenderPassDescriptor_colorAttachments :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="defaultRasterSampleCount")
RenderPassDescriptor_defaultRasterSampleCount :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "defaultRasterSampleCount")
}
@(objc_type=RenderPassDescriptor, objc_name="depthAttachment")
RenderPassDescriptor_depthAttachment :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "depthAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="getSamplePositions")
RenderPassDescriptor_getSamplePositions :: #force_inline proc "c" (self: ^RenderPassDescriptor, positions: []SamplePosition) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "getSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}
@(objc_type=RenderPassDescriptor, objc_name="imageblockSampleLength")
RenderPassDescriptor_imageblockSampleLength :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "imageblockSampleLength")
}
@(objc_type=RenderPassDescriptor, objc_name="rasterizationRateMap")
RenderPassDescriptor_rasterizationRateMap :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RasterizationRateMap {
	return msgSend(^RasterizationRateMap, self, "rasterizationRateMap")
}
@(objc_type=RenderPassDescriptor, objc_name="renderPassDescriptor", objc_is_class_method=true)
RenderPassDescriptor_renderPassDescriptor :: #force_inline proc "c" () -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "renderPassDescriptor")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetArrayLength")
RenderPassDescriptor_renderTargetArrayLength :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetArrayLength")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetHeight")
RenderPassDescriptor_renderTargetHeight :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetWidth")
RenderPassDescriptor_renderTargetWidth :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "renderTargetWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="sampleBufferAttachments")
RenderPassDescriptor_sampleBufferAttachments :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="setDefaultRasterSampleCount")
RenderPassDescriptor_setDefaultRasterSampleCount :: #force_inline proc "c" (self: ^RenderPassDescriptor, defaultRasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setDefaultRasterSampleCount:", defaultRasterSampleCount)
}
@(objc_type=RenderPassDescriptor, objc_name="setDepthAttachment")
RenderPassDescriptor_setDepthAttachment :: #force_inline proc "c" (self: ^RenderPassDescriptor, depthAttachment: ^RenderPassDepthAttachmentDescriptor) {
	msgSend(nil, self, "setDepthAttachment:", depthAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setImageblockSampleLength")
RenderPassDescriptor_setImageblockSampleLength :: #force_inline proc "c" (self: ^RenderPassDescriptor, imageblockSampleLength: NS.UInteger) {
	msgSend(nil, self, "setImageblockSampleLength:", imageblockSampleLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRasterizationRateMap")
RenderPassDescriptor_setRasterizationRateMap :: #force_inline proc "c" (self: ^RenderPassDescriptor, rasterizationRateMap: ^RasterizationRateMap) {
	msgSend(nil, self, "setRasterizationRateMap:", rasterizationRateMap)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetArrayLength")
RenderPassDescriptor_setRenderTargetArrayLength :: #force_inline proc "c" (self: ^RenderPassDescriptor, renderTargetArrayLength: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetArrayLength:", renderTargetArrayLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetHeight")
RenderPassDescriptor_setRenderTargetHeight :: #force_inline proc "c" (self: ^RenderPassDescriptor, renderTargetHeight: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetHeight:", renderTargetHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetWidth")
RenderPassDescriptor_setRenderTargetWidth :: #force_inline proc "c" (self: ^RenderPassDescriptor, renderTargetWidth: NS.UInteger) {
	msgSend(nil, self, "setRenderTargetWidth:", renderTargetWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setSamplePositions")
RenderPassDescriptor_setSamplePositions :: #force_inline proc "c" (self: ^RenderPassDescriptor, positions: []SamplePosition) {
	msgSend(nil, self, "setSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}
@(objc_type=RenderPassDescriptor, objc_name="setStencilAttachment")
RenderPassDescriptor_setStencilAttachment :: #force_inline proc "c" (self: ^RenderPassDescriptor, stencilAttachment: ^RenderPassStencilAttachmentDescriptor) {
	msgSend(nil, self, "setStencilAttachment:", stencilAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setThreadgroupMemoryLength")
RenderPassDescriptor_setThreadgroupMemoryLength :: #force_inline proc "c" (self: ^RenderPassDescriptor, threadgroupMemoryLength: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:", threadgroupMemoryLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileHeight")
RenderPassDescriptor_setTileHeight :: #force_inline proc "c" (self: ^RenderPassDescriptor, tileHeight: NS.UInteger) {
	msgSend(nil, self, "setTileHeight:", tileHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileWidth")
RenderPassDescriptor_setTileWidth :: #force_inline proc "c" (self: ^RenderPassDescriptor, tileWidth: NS.UInteger) {
	msgSend(nil, self, "setTileWidth:", tileWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setVisibilityResultBuffer")
RenderPassDescriptor_setVisibilityResultBuffer :: #force_inline proc "c" (self: ^RenderPassDescriptor, visibilityResultBuffer: ^Buffer) {
	msgSend(nil, self, "setVisibilityResultBuffer:", visibilityResultBuffer)
}
@(objc_type=RenderPassDescriptor, objc_name="stencilAttachment")
RenderPassDescriptor_stencilAttachment :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "stencilAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="threadgroupMemoryLength")
RenderPassDescriptor_threadgroupMemoryLength :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryLength")
}
@(objc_type=RenderPassDescriptor, objc_name="tileHeight")
RenderPassDescriptor_tileHeight :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="tileWidth")
RenderPassDescriptor_tileWidth :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="visibilityResultBuffer")
RenderPassDescriptor_visibilityResultBuffer :: #force_inline proc "c" (self: ^RenderPassDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "visibilityResultBuffer")
}

////////////////////////////////////////////////////////////////////////////////



@(objc_class="MTLRenderPassSampleBufferAttachmentDescriptor")
RenderPassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassSampleBufferAttachmentDescriptor) }

@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, RenderPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="init")
RenderPassSampleBufferAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfFragmentSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfVertexSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfVertexSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfFragmentSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor, endOfFragmentSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfFragmentSampleIndex:", endOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfVertexSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor, endOfVertexSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfVertexSampleIndex:", endOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor, sampleBuffer: ^CounterSampleBuffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfFragmentSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor, startOfFragmentSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfFragmentSampleIndex:", startOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfVertexSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor, startOfVertexSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfVertexSampleIndex:", startOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfFragmentSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfVertexSampleIndex :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfVertexSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassSampleBufferAttachmentDescriptorArray")
RenderPassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
RenderPassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, RenderPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="init")
RenderPassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptorArray) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="object")
RenderPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
RenderPassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachment: ^RenderPassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPassStencilAttachmentDescriptor")
RenderPassStencilAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassStencilAttachmentDescriptor) }

@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPassStencilAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, RenderPassStencilAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="init")
RenderPassStencilAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPassStencilAttachmentDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="clearStencil")
RenderPassStencilAttachmentDescriptor_clearStencil :: #force_inline proc "c" (self: ^RenderPassStencilAttachmentDescriptor) -> u32 {
	return msgSend(u32, self, "clearStencil")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setClearStencil")
RenderPassStencilAttachmentDescriptor_setClearStencil :: #force_inline proc "c" (self: ^RenderPassStencilAttachmentDescriptor, clearStencil: u32) {
	msgSend(nil, self, "setClearStencil:", clearStencil)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setStencilResolveFilter")
RenderPassStencilAttachmentDescriptor_setStencilResolveFilter :: #force_inline proc "c" (self: ^RenderPassStencilAttachmentDescriptor, stencilResolveFilter: MultisampleStencilResolveFilter) {
	msgSend(nil, self, "setStencilResolveFilter:", stencilResolveFilter)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="stencilResolveFilter")
RenderPassStencilAttachmentDescriptor_stencilResolveFilter :: #force_inline proc "c" (self: ^RenderPassStencilAttachmentDescriptor) -> MultisampleStencilResolveFilter {
	return msgSend(MultisampleStencilResolveFilter, self, "stencilResolveFilter")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPipelineColorAttachmentDescriptor")
RenderPipelineColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPipelineColorAttachmentDescriptor), using _: RenderPassAttachmentDescriptor }

@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPipelineColorAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, RenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="init")
RenderPipelineColorAttachmentDescriptor_init :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="alphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_alphaBlendOperation :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "alphaBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationAlphaBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationRGBBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="isBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_isBlendingEnabled :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isBlendingEnabled")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
RenderPipelineColorAttachmentDescriptor_pixelFormat :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="rgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_rgbBlendOperation :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "rgbBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setAlphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_setAlphaBlendOperation :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, alphaBlendOperation: BlendOperation) {
	msgSend(nil, self, "setAlphaBlendOperation:", alphaBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_setBlendingEnabled :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, blendingEnabled: BOOL) {
	msgSend(nil, self, "setBlendingEnabled:", blendingEnabled)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationAlphaBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, destinationAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationAlphaBlendFactor:", destinationAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationRGBBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, destinationRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationRGBBlendFactor:", destinationRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
RenderPipelineColorAttachmentDescriptor_setPixelFormat :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setRgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_setRgbBlendOperation :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, rgbBlendOperation: BlendOperation) {
	msgSend(nil, self, "setRgbBlendOperation:", rgbBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceAlphaBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, sourceAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceAlphaBlendFactor:", sourceAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceRGBBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, sourceRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceRGBBlendFactor:", sourceRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setWriteMask")
RenderPipelineColorAttachmentDescriptor_setWriteMask :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor, writeMask: ColorWriteMask) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceAlphaBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceRGBBlendFactor :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="writeMask")
RenderPipelineColorAttachmentDescriptor_writeMask :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptor) -> ColorWriteMask {
	return msgSend(ColorWriteMask, self, "writeMask")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPipelineColorAttachmentDescriptorArray")
RenderPipelineColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
RenderPipelineColorAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, RenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="init")
RenderPipelineColorAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptorArray) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="object")
RenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
RenderPipelineColorAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptorArray, attachment: ^RenderPipelineColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPipelineDescriptor")
RenderPipelineDescriptor :: struct { using _: NS.Copying(RenderPipelineDescriptor) }

@(objc_type=RenderPipelineDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPipelineDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, RenderPipelineDescriptor, "alloc")
}
@(objc_type=RenderPipelineDescriptor, objc_name="init")
RenderPipelineDescriptor_init :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "init")
}
@(objc_type=RenderPipelineDescriptor, objc_name="binaryArchives")
RenderPipelineDescriptor_binaryArchives :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=RenderPipelineDescriptor, objc_name="colorAttachments")
RenderPipelineDescriptor_colorAttachments :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPipelineDescriptor, objc_name="depthAttachmentPixelFormat")
RenderPipelineDescriptor_depthAttachmentPixelFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "depthAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentBuffers")
RenderPipelineDescriptor_fragmentBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "fragmentBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentFunction")
RenderPipelineDescriptor_fragmentFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "fragmentFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="inputPrimitiveTopology")
RenderPipelineDescriptor_inputPrimitiveTopology :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> PrimitiveTopologyClass {
	return msgSend(PrimitiveTopologyClass, self, "inputPrimitiveTopology")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToCoverageEnabled")
RenderPipelineDescriptor_isAlphaToCoverageEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToCoverageEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToOneEnabled")
RenderPipelineDescriptor_isAlphaToOneEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToOneEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isRasterizationEnabled")
RenderPipelineDescriptor_isRasterizationEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isRasterizationEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isTessellationFactorScaleEnabled")
RenderPipelineDescriptor_isTessellationFactorScaleEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isTessellationFactorScaleEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="label")
RenderPipelineDescriptor_label :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxTessellationFactor")
RenderPipelineDescriptor_maxTessellationFactor :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTessellationFactor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxVertexAmplificationCount")
RenderPipelineDescriptor_maxVertexAmplificationCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxVertexAmplificationCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="rasterSampleCount")
RenderPipelineDescriptor_rasterSampleCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "rasterSampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="reset")
RenderPipelineDescriptor_reset :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=RenderPipelineDescriptor, objc_name="sampleCount")
RenderPipelineDescriptor_sampleCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToCoverageEnabled")
RenderPipelineDescriptor_setAlphaToCoverageEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, alphaToCoverageEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToCoverageEnabled:", alphaToCoverageEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToOneEnabled")
RenderPipelineDescriptor_setAlphaToOneEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, alphaToOneEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToOneEnabled:", alphaToOneEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setBinaryArchives")
RenderPipelineDescriptor_setBinaryArchives :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setDepthAttachmentPixelFormat")
RenderPipelineDescriptor_setDepthAttachmentPixelFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, depthAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setDepthAttachmentPixelFormat:", depthAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setFragmentFunction")
RenderPipelineDescriptor_setFragmentFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, fragmentFunction: ^Function) {
	msgSend(nil, self, "setFragmentFunction:", fragmentFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setInputPrimitiveTopology")
RenderPipelineDescriptor_setInputPrimitiveTopology :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, inputPrimitiveTopology: PrimitiveTopologyClass) {
	msgSend(nil, self, "setInputPrimitiveTopology:", inputPrimitiveTopology)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setLabel")
RenderPipelineDescriptor_setLabel :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTessellationFactor")
RenderPipelineDescriptor_setMaxTessellationFactor :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, maxTessellationFactor: NS.UInteger) {
	msgSend(nil, self, "setMaxTessellationFactor:", maxTessellationFactor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxVertexAmplificationCount")
RenderPipelineDescriptor_setMaxVertexAmplificationCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, maxVertexAmplificationCount: NS.UInteger) {
	msgSend(nil, self, "setMaxVertexAmplificationCount:", maxVertexAmplificationCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterSampleCount")
RenderPipelineDescriptor_setRasterSampleCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, rasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterizationEnabled")
RenderPipelineDescriptor_setRasterizationEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, rasterizationEnabled: BOOL) {
	msgSend(nil, self, "setRasterizationEnabled:", rasterizationEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSampleCount")
RenderPipelineDescriptor_setSampleCount :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setStencilAttachmentPixelFormat")
RenderPipelineDescriptor_setStencilAttachmentPixelFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, stencilAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setStencilAttachmentPixelFormat:", stencilAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
RenderPipelineDescriptor_setSupportIndirectCommandBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationControlPointIndexType")
RenderPipelineDescriptor_setTessellationControlPointIndexType :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationControlPointIndexType: TessellationControlPointIndexType) {
	msgSend(nil, self, "setTessellationControlPointIndexType:", tessellationControlPointIndexType)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorFormat")
RenderPipelineDescriptor_setTessellationFactorFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationFactorFormat: TessellationFactorFormat) {
	msgSend(nil, self, "setTessellationFactorFormat:", tessellationFactorFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorScaleEnabled")
RenderPipelineDescriptor_setTessellationFactorScaleEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationFactorScaleEnabled: BOOL) {
	msgSend(nil, self, "setTessellationFactorScaleEnabled:", tessellationFactorScaleEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorStepFunction")
RenderPipelineDescriptor_setTessellationFactorStepFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationFactorStepFunction: TessellationFactorStepFunction) {
	msgSend(nil, self, "setTessellationFactorStepFunction:", tessellationFactorStepFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationOutputWindingOrder")
RenderPipelineDescriptor_setTessellationOutputWindingOrder :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationOutputWindingOrder: Winding) {
	msgSend(nil, self, "setTessellationOutputWindingOrder:", tessellationOutputWindingOrder)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationPartitionMode")
RenderPipelineDescriptor_setTessellationPartitionMode :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, tessellationPartitionMode: TessellationPartitionMode) {
	msgSend(nil, self, "setTessellationPartitionMode:", tessellationPartitionMode)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexDescriptor")
RenderPipelineDescriptor_setVertexDescriptor :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, vertexDescriptor: ^VertexDescriptor) {
	msgSend(nil, self, "setVertexDescriptor:", vertexDescriptor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexFunction")
RenderPipelineDescriptor_setVertexFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, vertexFunction: ^Function) {
	msgSend(nil, self, "setVertexFunction:", vertexFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="stencilAttachmentPixelFormat")
RenderPipelineDescriptor_stencilAttachmentPixelFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "stencilAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="supportIndirectCommandBuffers")
RenderPipelineDescriptor_supportIndirectCommandBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationControlPointIndexType")
RenderPipelineDescriptor_tessellationControlPointIndexType :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> TessellationControlPointIndexType {
	return msgSend(TessellationControlPointIndexType, self, "tessellationControlPointIndexType")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorFormat")
RenderPipelineDescriptor_tessellationFactorFormat :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> TessellationFactorFormat {
	return msgSend(TessellationFactorFormat, self, "tessellationFactorFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorStepFunction")
RenderPipelineDescriptor_tessellationFactorStepFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> TessellationFactorStepFunction {
	return msgSend(TessellationFactorStepFunction, self, "tessellationFactorStepFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationOutputWindingOrder")
RenderPipelineDescriptor_tessellationOutputWindingOrder :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> Winding {
	return msgSend(Winding, self, "tessellationOutputWindingOrder")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationPartitionMode")
RenderPipelineDescriptor_tessellationPartitionMode :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> TessellationPartitionMode {
	return msgSend(TessellationPartitionMode, self, "tessellationPartitionMode")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexBuffers")
RenderPipelineDescriptor_vertexBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "vertexBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexDescriptor")
RenderPipelineDescriptor_vertexDescriptor :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "vertexDescriptor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexFunction")
RenderPipelineDescriptor_vertexFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "vertexFunction")
}

@(objc_type=RenderPipelineDescriptor, objc_name="objectFunction")
RenderPipelineDescriptor_objectFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "objectFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setObjectFunction")
RenderPipelineDescriptor_setObjectFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, objectFunction: ^Function) {
	msgSend(nil, self, "setObjectFunction:", objectFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="meshFunction")
RenderPipelineDescriptor_meshFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "meshFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMeshFunction")
RenderPipelineDescriptor_setMeshFunction :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, meshFunction: ^Function) {
	msgSend(nil, self, "setMeshFunction:", meshFunction)
}

@(objc_type=RenderPipelineDescriptor, objc_name="maxTotalThreadsPerObjectThreadgroup")
RenderPipelineDescriptor_maxTotalThreadsPerObjectThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerObjectThreadgroup")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTotalThreadsPerObjectThreadgroup")
RenderPipelineDescriptor_setMaxTotalThreadsPerObjectThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, maxTotalThreadsPerObjectThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerObjectThreadgroup:", maxTotalThreadsPerObjectThreadgroup)
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxTotalThreadsPerMeshThreadgroup")
RenderPipelineDescriptor_maxTotalThreadsPerMeshThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerMeshThreadgroup")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTotalThreadsPerMeshThreadgroup")
RenderPipelineDescriptor_setMaxTotalThreadsPerMeshThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, maxTotalThreadsPerMeshThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerMeshThreadgroup:", maxTotalThreadsPerMeshThreadgroup)
}
@(objc_type=RenderPipelineDescriptor, objc_name="objectThreadgroupSizeIsMultipleOfThreadExecutionWidth")
RenderPipelineDescriptor_objectThreadgroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "objectThreadgroupSizeIsMultipleOfThreadExecutionWidth")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setObjectThreadgroupSizeIsMultipleOfThreadExecutionWidth")
RenderPipelineDescriptor_setObjectThreadgroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, objectThreadgroupSizeIsMultipleOfThreadExecutionWidth: NS.UInteger) {
	msgSend(nil, self, "setObjectThreadgroupSizeIsMultipleOfThreadExecutionWidth:", objectThreadgroupSizeIsMultipleOfThreadExecutionWidth)
}

@(objc_type=RenderPipelineDescriptor, objc_name="meshThreadgroupSizeIsMultipleOfThreadExecutionWidth")
RenderPipelineDescriptor_meshThreadgroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "meshThreadgroupSizeIsMultipleOfThreadExecutionWidth")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMeshThreadgroupSizeIsMultipleOfThreadExecutionWidth")
RenderPipelineDescriptor_setMeshThreadgroupSizeIsMultipleOfThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, meshThreadgroupSizeIsMultipleOfThreadExecutionWidth: BOOL) {
	msgSend(nil, self, "setMeshThreadgroupSizeIsMultipleOfThreadExecutionWidth:", meshThreadgroupSizeIsMultipleOfThreadExecutionWidth)
}


@(objc_type=RenderPipelineDescriptor, objc_name="payloadMemoryLength")
RenderPipelineDescriptor_payloadMemoryLength :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "payloadMemoryLength")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setPayloadMemoryLength")
RenderPipelineDescriptor_setPayloadMemoryLength :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, payloadMemoryLength: NS.UInteger) {
	msgSend(nil, self, "setPayloadMemoryLength:", payloadMemoryLength)
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxTotalThreadgroupsPerMeshGrid")
RenderPipelineDescriptor_maxTotalThreadgroupsPerMeshGrid :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadgroupsPerMeshGrid")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTotalThreadgroupsPerMeshGrid")
RenderPipelineDescriptor_setMaxTotalThreadgroupsPerMeshGrid :: #force_inline proc "c" (self: ^RenderPipelineDescriptor, maxTotalThreadgroupsPerMeshGrid: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadgroupsPerMeshGrid:", maxTotalThreadgroupsPerMeshGrid)
}

@(objc_type=RenderPipelineDescriptor, objc_name="objectBuffers")
RenderPipelineDescriptor_objectBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "objectBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="meshBuffers")
RenderPipelineDescriptor_meshBuffers :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "meshBuffers")
}



@(objc_type=RenderPipelineDescriptor, objc_name="alphaToCoverageEnabled")
RenderPipelineDescriptor_alphaToCoverageEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "alphaToCoverageEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="alphaToOneEnabled")
RenderPipelineDescriptor_alphaToOneEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "alphaToOneEnabled")
}

@(objc_type=RenderPipelineDescriptor, objc_name="rasterizationEnabled")
RenderPipelineDescriptor_rasterizationEnabled :: #force_inline proc "c" (self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "rasterizationEnabled")
}


////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLRenderPipelineReflection")
RenderPipelineReflection :: struct { using _: NS.Object }

@(objc_type=RenderPipelineReflection, objc_name="alloc", objc_is_class_method=true)
RenderPipelineReflection_alloc :: #force_inline proc "c" () -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, RenderPipelineReflection, "alloc")
}
@(objc_type=RenderPipelineReflection, objc_name="init")
RenderPipelineReflection_init :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, self, "init")
}
@(objc_type=RenderPipelineReflection, objc_name="fragmentArguments")
RenderPipelineReflection_fragmentArguments :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "fragmentArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="tileArguments")
RenderPipelineReflection_tileArguments :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "tileArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="vertexArguments")
RenderPipelineReflection_vertexArguments :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexArguments")
}

@(objc_type=RenderPipelineReflection, objc_name="vertexBindings")
RenderPipelineReflection_vertexBindings :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexBindings")
}
@(objc_type=RenderPipelineReflection, objc_name="fragmentBindings")
RenderPipelineReflection_fragmentBindings :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "fragmentBindings")
}
@(objc_type=RenderPipelineReflection, objc_name="tileBindings")
RenderPipelineReflection_tileBindings :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "tileBindings")
}
@(objc_type=RenderPipelineReflection, objc_name="objectBindings")
RenderPipelineReflection_objectBindings :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "objectBindings")
}
@(objc_type=RenderPipelineReflection, objc_name="meshBindings")
RenderPipelineReflection_meshBindings :: #force_inline proc "c" (self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "meshBindings")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLResourceStatePassDescriptor")
ResourceStatePassDescriptor :: struct { using _: NS.Copying(ResourceStatePassDescriptor) }

@(objc_type=ResourceStatePassDescriptor, objc_name="alloc", objc_is_class_method=true)
ResourceStatePassDescriptor_alloc :: #force_inline proc "c" () -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "alloc")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="init")
ResourceStatePassDescriptor_init :: #force_inline proc "c" (self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, self, "init")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="resourceStatePassDescriptor", objc_is_class_method=true)
ResourceStatePassDescriptor_resourceStatePassDescriptor :: #force_inline proc "c" () -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "resourceStatePassDescriptor")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="sampleBufferAttachments")
ResourceStatePassDescriptor_sampleBufferAttachments :: #force_inline proc "c" (self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLResourceStatePassSampleBufferAttachmentDescriptor")
ResourceStatePassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(ResourceStatePassSampleBufferAttachmentDescriptor) }

@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
ResourceStatePassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, ResourceStatePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptor_init :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor, sampleBuffer: ^CounterSampleBuffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLResourceStatePassSampleBufferAttachmentDescriptorArray")
ResourceStatePassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
ResourceStatePassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, ResourceStatePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ResourceStatePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ResourceStatePassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachment: ^ResourceStatePassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLSamplerDescriptor")
SamplerDescriptor :: struct { using _: NS.Copying(SamplerDescriptor) }

@(objc_type=SamplerDescriptor, objc_name="alloc", objc_is_class_method=true)
SamplerDescriptor_alloc :: #force_inline proc "c" () -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, SamplerDescriptor, "alloc")
}
@(objc_type=SamplerDescriptor, objc_name="init")
SamplerDescriptor_init :: #force_inline proc "c" (self: ^SamplerDescriptor) -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, self, "init")
}
@(objc_type=SamplerDescriptor, objc_name="borderColor")
SamplerDescriptor_borderColor :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerBorderColor {
	return msgSend(SamplerBorderColor, self, "borderColor")
}
@(objc_type=SamplerDescriptor, objc_name="compareFunction")
SamplerDescriptor_compareFunction :: #force_inline proc "c" (self: ^SamplerDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "compareFunction")
}
@(objc_type=SamplerDescriptor, objc_name="label")
SamplerDescriptor_label :: #force_inline proc "c" (self: ^SamplerDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=SamplerDescriptor, objc_name="lodAverage")
SamplerDescriptor_lodAverage :: #force_inline proc "c" (self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "lodAverage")
}
@(objc_type=SamplerDescriptor, objc_name="lodMaxClamp")
SamplerDescriptor_lodMaxClamp :: #force_inline proc "c" (self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMaxClamp")
}
@(objc_type=SamplerDescriptor, objc_name="lodMinClamp")
SamplerDescriptor_lodMinClamp :: #force_inline proc "c" (self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMinClamp")
}
@(objc_type=SamplerDescriptor, objc_name="magFilter")
SamplerDescriptor_magFilter :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "magFilter")
}
@(objc_type=SamplerDescriptor, objc_name="maxAnisotropy")
SamplerDescriptor_maxAnisotropy :: #force_inline proc "c" (self: ^SamplerDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxAnisotropy")
}
@(objc_type=SamplerDescriptor, objc_name="minFilter")
SamplerDescriptor_minFilter :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "minFilter")
}
@(objc_type=SamplerDescriptor, objc_name="mipFilter")
SamplerDescriptor_mipFilter :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerMipFilter {
	return msgSend(SamplerMipFilter, self, "mipFilter")
}
@(objc_type=SamplerDescriptor, objc_name="normalizedCoordinates")
SamplerDescriptor_normalizedCoordinates :: #force_inline proc "c" (self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "normalizedCoordinates")
}
@(objc_type=SamplerDescriptor, objc_name="rAddressMode")
SamplerDescriptor_rAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "rAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="sAddressMode")
SamplerDescriptor_sAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "sAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="setBorderColor")
SamplerDescriptor_setBorderColor :: #force_inline proc "c" (self: ^SamplerDescriptor, borderColor: SamplerBorderColor) {
	msgSend(nil, self, "setBorderColor:", borderColor)
}
@(objc_type=SamplerDescriptor, objc_name="setCompareFunction")
SamplerDescriptor_setCompareFunction :: #force_inline proc "c" (self: ^SamplerDescriptor, compareFunction: CompareFunction) {
	msgSend(nil, self, "setCompareFunction:", compareFunction)
}
@(objc_type=SamplerDescriptor, objc_name="setLabel")
SamplerDescriptor_setLabel :: #force_inline proc "c" (self: ^SamplerDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=SamplerDescriptor, objc_name="setLodAverage")
SamplerDescriptor_setLodAverage :: #force_inline proc "c" (self: ^SamplerDescriptor, lodAverage: BOOL) {
	msgSend(nil, self, "setLodAverage:", lodAverage)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMaxClamp")
SamplerDescriptor_setLodMaxClamp :: #force_inline proc "c" (self: ^SamplerDescriptor, lodMaxClamp: f32) {
	msgSend(nil, self, "setLodMaxClamp:", lodMaxClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMinClamp")
SamplerDescriptor_setLodMinClamp :: #force_inline proc "c" (self: ^SamplerDescriptor, lodMinClamp: f32) {
	msgSend(nil, self, "setLodMinClamp:", lodMinClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setMagFilter")
SamplerDescriptor_setMagFilter :: #force_inline proc "c" (self: ^SamplerDescriptor, magFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMagFilter:", magFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMaxAnisotropy")
SamplerDescriptor_setMaxAnisotropy :: #force_inline proc "c" (self: ^SamplerDescriptor, maxAnisotropy: NS.UInteger) {
	msgSend(nil, self, "setMaxAnisotropy:", maxAnisotropy)
}
@(objc_type=SamplerDescriptor, objc_name="setMinFilter")
SamplerDescriptor_setMinFilter :: #force_inline proc "c" (self: ^SamplerDescriptor, minFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMinFilter:", minFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMipFilter")
SamplerDescriptor_setMipFilter :: #force_inline proc "c" (self: ^SamplerDescriptor, mipFilter: SamplerMipFilter) {
	msgSend(nil, self, "setMipFilter:", mipFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setNormalizedCoordinates")
SamplerDescriptor_setNormalizedCoordinates :: #force_inline proc "c" (self: ^SamplerDescriptor, normalizedCoordinates: BOOL) {
	msgSend(nil, self, "setNormalizedCoordinates:", normalizedCoordinates)
}
@(objc_type=SamplerDescriptor, objc_name="setRAddressMode")
SamplerDescriptor_setRAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor, rAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setRAddressMode:", rAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSAddressMode")
SamplerDescriptor_setSAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor, sAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setSAddressMode:", sAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSupportArgumentBuffers")
SamplerDescriptor_setSupportArgumentBuffers :: #force_inline proc "c" (self: ^SamplerDescriptor, supportArgumentBuffers: BOOL) {
	msgSend(nil, self, "setSupportArgumentBuffers:", supportArgumentBuffers)
}
@(objc_type=SamplerDescriptor, objc_name="setTAddressMode")
SamplerDescriptor_setTAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor, tAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setTAddressMode:", tAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="supportArgumentBuffers")
SamplerDescriptor_supportArgumentBuffers :: #force_inline proc "c" (self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportArgumentBuffers")
}
@(objc_type=SamplerDescriptor, objc_name="tAddressMode")
SamplerDescriptor_tAddressMode :: #force_inline proc "c" (self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "tAddressMode")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLSharedEventHandle")
SharedEventHandle :: struct { using _: NS.Object }

@(objc_type=SharedEventHandle, objc_name="alloc", objc_is_class_method=true)
SharedEventHandle_alloc :: #force_inline proc "c" () -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, SharedEventHandle, "alloc")
}
@(objc_type=SharedEventHandle, objc_name="init")
SharedEventHandle_init :: #force_inline proc "c" (self: ^SharedEventHandle) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "init")
}
@(objc_type=SharedEventHandle, objc_name="label")
SharedEventHandle_label :: #force_inline proc "c" (self: ^SharedEventHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLSharedEventListener")
SharedEventListener :: struct { using _: NS.Object }

@(objc_type=SharedEventListener, objc_name="alloc", objc_is_class_method=true)
SharedEventListener_alloc :: #force_inline proc "c" () -> ^SharedEventListener {
	return msgSend(^SharedEventListener, SharedEventListener, "alloc")
}
@(objc_type=SharedEventListener, objc_name="dispatchQueue")
SharedEventListener_dispatchQueue :: #force_inline proc "c" (self: ^SharedEventListener) -> dispatch_queue_t {
	return msgSend(dispatch_queue_t, self, "dispatchQueue")
}
@(objc_type=SharedEventListener, objc_name="init")
SharedEventListener_init :: #force_inline proc "c" (self: ^SharedEventListener) -> ^SharedEventListener {
	return msgSend(^SharedEventListener, self, "init")
}
@(objc_type=SharedEventListener, objc_name="initWithDispatchQueue")
SharedEventListener_initWithDispatchQueue :: #force_inline proc "c" (self: ^SharedEventListener, dispatchQueue: dispatch_queue_t) -> ^SharedEventListener {
	return msgSend(^SharedEventListener, self, "initWithDispatchQueue:", dispatchQueue)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLSharedTextureHandle")
SharedTextureHandle :: struct { using _: NS.Object }

@(objc_type=SharedTextureHandle, objc_name="alloc", objc_is_class_method=true)
SharedTextureHandle_alloc :: #force_inline proc "c" () -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, SharedTextureHandle, "alloc")
}
@(objc_type=SharedTextureHandle, objc_name="init")
SharedTextureHandle_init :: #force_inline proc "c" (self: ^SharedTextureHandle) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "init")
}
@(objc_type=SharedTextureHandle, objc_name="device")
SharedTextureHandle_device :: #force_inline proc "c" (self: ^SharedTextureHandle) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=SharedTextureHandle, objc_name="label")
SharedTextureHandle_label :: #force_inline proc "c" (self: ^SharedTextureHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLStageInputOutputDescriptor")
StageInputOutputDescriptor :: struct { using _: NS.Copying(StageInputOutputDescriptor) }

@(objc_type=StageInputOutputDescriptor, objc_name="alloc", objc_is_class_method=true)
StageInputOutputDescriptor_alloc :: #force_inline proc "c" () -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, StageInputOutputDescriptor, "alloc")
}
@(objc_type=StageInputOutputDescriptor, objc_name="init")
StageInputOutputDescriptor_init :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "init")
}
@(objc_type=StageInputOutputDescriptor, objc_name="attributes")
StageInputOutputDescriptor_attributes :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "attributes")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexBufferIndex")
StageInputOutputDescriptor_indexBufferIndex :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferIndex")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexType")
StageInputOutputDescriptor_indexType :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=StageInputOutputDescriptor, objc_name="layouts")
StageInputOutputDescriptor_layouts :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=StageInputOutputDescriptor, objc_name="reset")
StageInputOutputDescriptor_reset :: #force_inline proc "c" (self: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexBufferIndex")
StageInputOutputDescriptor_setIndexBufferIndex :: #force_inline proc "c" (self: ^StageInputOutputDescriptor, indexBufferIndex: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferIndex:", indexBufferIndex)
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexType")
StageInputOutputDescriptor_setIndexType :: #force_inline proc "c" (self: ^StageInputOutputDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=StageInputOutputDescriptor, objc_name="stageInputOutputDescriptor", objc_is_class_method=true)
StageInputOutputDescriptor_stageInputOutputDescriptor :: #force_inline proc "c" () -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, StageInputOutputDescriptor, "stageInputOutputDescriptor")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLStencilDescriptor")
StencilDescriptor :: struct { using _: NS.Copying(StencilDescriptor) }

@(objc_type=StencilDescriptor, objc_name="alloc", objc_is_class_method=true)
StencilDescriptor_alloc :: #force_inline proc "c" () -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, StencilDescriptor, "alloc")
}
@(objc_type=StencilDescriptor, objc_name="init")
StencilDescriptor_init :: #force_inline proc "c" (self: ^StencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "init")
}
@(objc_type=StencilDescriptor, objc_name="depthFailureOperation")
StencilDescriptor_depthFailureOperation :: #force_inline proc "c" (self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="depthStencilPassOperation")
StencilDescriptor_depthStencilPassOperation :: #force_inline proc "c" (self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthStencilPassOperation")
}
@(objc_type=StencilDescriptor, objc_name="readMask")
StencilDescriptor_readMask :: #force_inline proc "c" (self: ^StencilDescriptor) -> u32 {
	return msgSend(u32, self, "readMask")
}
@(objc_type=StencilDescriptor, objc_name="setDepthFailureOperation")
StencilDescriptor_setDepthFailureOperation :: #force_inline proc "c" (self: ^StencilDescriptor, depthFailureOperation: StencilOperation) {
	msgSend(nil, self, "setDepthFailureOperation:", depthFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setDepthStencilPassOperation")
StencilDescriptor_setDepthStencilPassOperation :: #force_inline proc "c" (self: ^StencilDescriptor, depthStencilPassOperation: StencilOperation) {
	msgSend(nil, self, "setDepthStencilPassOperation:", depthStencilPassOperation)
}
@(objc_type=StencilDescriptor, objc_name="setReadMask")
StencilDescriptor_setReadMask :: #force_inline proc "c" (self: ^StencilDescriptor, readMask: u32) {
	msgSend(nil, self, "setReadMask:", readMask)
}
@(objc_type=StencilDescriptor, objc_name="setStencilCompareFunction")
StencilDescriptor_setStencilCompareFunction :: #force_inline proc "c" (self: ^StencilDescriptor, stencilCompareFunction: CompareFunction) {
	msgSend(nil, self, "setStencilCompareFunction:", stencilCompareFunction)
}
@(objc_type=StencilDescriptor, objc_name="setStencilFailureOperation")
StencilDescriptor_setStencilFailureOperation :: #force_inline proc "c" (self: ^StencilDescriptor, stencilFailureOperation: StencilOperation) {
	msgSend(nil, self, "setStencilFailureOperation:", stencilFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setWriteMask")
StencilDescriptor_setWriteMask :: #force_inline proc "c" (self: ^StencilDescriptor, writeMask: u32) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=StencilDescriptor, objc_name="stencilCompareFunction")
StencilDescriptor_stencilCompareFunction :: #force_inline proc "c" (self: ^StencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "stencilCompareFunction")
}
@(objc_type=StencilDescriptor, objc_name="stencilFailureOperation")
StencilDescriptor_stencilFailureOperation :: #force_inline proc "c" (self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "stencilFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="writeMask")
StencilDescriptor_writeMask :: #force_inline proc "c" (self: ^StencilDescriptor) -> u32 {
	return msgSend(u32, self, "writeMask")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLStructMember")
StructMember :: struct { using _: NS.Object }

@(objc_type=StructMember, objc_name="alloc", objc_is_class_method=true)
StructMember_alloc :: #force_inline proc "c" () -> ^StructMember {
	return msgSend(^StructMember, StructMember, "alloc")
}
@(objc_type=StructMember, objc_name="init")
StructMember_init :: #force_inline proc "c" (self: ^StructMember) -> ^StructMember {
	return msgSend(^StructMember, self, "init")
}
@(objc_type=StructMember, objc_name="argumentIndex")
StructMember_argumentIndex :: #force_inline proc "c" (self: ^StructMember) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "argumentIndex")
}
@(objc_type=StructMember, objc_name="arrayType")
StructMember_arrayType :: #force_inline proc "c" (self: ^StructMember) -> ^ArrayType {
	return msgSend(^ArrayType, self, "arrayType")
}
@(objc_type=StructMember, objc_name="dataType")
StructMember_dataType :: #force_inline proc "c" (self: ^StructMember) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=StructMember, objc_name="name")
StructMember_name :: #force_inline proc "c" (self: ^StructMember) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=StructMember, objc_name="offset")
StructMember_offset :: #force_inline proc "c" (self: ^StructMember) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=StructMember, objc_name="pointerType")
StructMember_pointerType :: #force_inline proc "c" (self: ^StructMember) -> ^PointerType {
	return msgSend(^PointerType, self, "pointerType")
}
@(objc_type=StructMember, objc_name="structType")
StructMember_structType :: #force_inline proc "c" (self: ^StructMember) -> ^StructType {
	return msgSend(^StructType, self, "structType")
}
@(objc_type=StructMember, objc_name="textureReferenceType")
StructMember_textureReferenceType :: #force_inline proc "c" (self: ^StructMember) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "textureReferenceType")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLStructType")
StructType :: struct { using _: Type }

@(objc_type=StructType, objc_name="alloc", objc_is_class_method=true)
StructType_alloc :: #force_inline proc "c" () -> ^StructType {
	return msgSend(^StructType, StructType, "alloc")
}
@(objc_type=StructType, objc_name="init")
StructType_init :: #force_inline proc "c" (self: ^StructType) -> ^StructType {
	return msgSend(^StructType, self, "init")
}
@(objc_type=StructType, objc_name="memberByName")
StructType_memberByName :: #force_inline proc "c" (self: ^StructType, name: ^NS.String) -> ^StructMember {
	return msgSend(^StructMember, self, "memberByName:", name)
}
@(objc_type=StructType, objc_name="members")
StructType_members :: #force_inline proc "c" (self: ^StructType) -> ^NS.Array {
	return msgSend(^NS.Array, self, "members")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLTextureDescriptor")
TextureDescriptor :: struct { using _: NS.Copying(TextureDescriptor) }

@(objc_type=TextureDescriptor, objc_name="alloc", objc_is_class_method=true)
TextureDescriptor_alloc :: #force_inline proc "c" () -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "alloc")
}
@(objc_type=TextureDescriptor, objc_name="init")
TextureDescriptor_init :: #force_inline proc "c" (self: ^TextureDescriptor) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, self, "init")
}
@(objc_type=TextureDescriptor, objc_name="allowGPUOptimizedContents")
TextureDescriptor_allowGPUOptimizedContents :: #force_inline proc "c" (self: ^TextureDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=TextureDescriptor, objc_name="arrayLength")
TextureDescriptor_arrayLength :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=TextureDescriptor, objc_name="cpuCacheMode")
TextureDescriptor_cpuCacheMode :: #force_inline proc "c" (self: ^TextureDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=TextureDescriptor, objc_name="depth")
TextureDescriptor_depth :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depth")
}
@(objc_type=TextureDescriptor, objc_name="hazardTrackingMode")
TextureDescriptor_hazardTrackingMode :: #force_inline proc "c" (self: ^TextureDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=TextureDescriptor, objc_name="height")
TextureDescriptor_height :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "height")
}
@(objc_type=TextureDescriptor, objc_name="mipmapLevelCount")
TextureDescriptor_mipmapLevelCount :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "mipmapLevelCount")
}
@(objc_type=TextureDescriptor, objc_name="pixelFormat")
TextureDescriptor_pixelFormat :: #force_inline proc "c" (self: ^TextureDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TextureDescriptor, objc_name="resourceOptions")
TextureDescriptor_resourceOptions :: #force_inline proc "c" (self: ^TextureDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=TextureDescriptor, objc_name="sampleCount")
TextureDescriptor_sampleCount :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=TextureDescriptor, objc_name="setAllowGPUOptimizedContents")
TextureDescriptor_setAllowGPUOptimizedContents :: #force_inline proc "c" (self: ^TextureDescriptor, allowGPUOptimizedContents: BOOL) {
	msgSend(nil, self, "setAllowGPUOptimizedContents:", allowGPUOptimizedContents)
}
@(objc_type=TextureDescriptor, objc_name="setArrayLength")
TextureDescriptor_setArrayLength :: #force_inline proc "c" (self: ^TextureDescriptor, arrayLength: NS.UInteger) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=TextureDescriptor, objc_name="setCpuCacheMode")
TextureDescriptor_setCpuCacheMode :: #force_inline proc "c" (self: ^TextureDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}
@(objc_type=TextureDescriptor, objc_name="setDepth")
TextureDescriptor_setDepth :: #force_inline proc "c" (self: ^TextureDescriptor, depth: NS.UInteger) {
	msgSend(nil, self, "setDepth:", depth)
}
@(objc_type=TextureDescriptor, objc_name="setHazardTrackingMode")
TextureDescriptor_setHazardTrackingMode :: #force_inline proc "c" (self: ^TextureDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=TextureDescriptor, objc_name="setHeight")
TextureDescriptor_setHeight :: #force_inline proc "c" (self: ^TextureDescriptor, height: NS.UInteger) {
	msgSend(nil, self, "setHeight:", height)
}
@(objc_type=TextureDescriptor, objc_name="setMipmapLevelCount")
TextureDescriptor_setMipmapLevelCount :: #force_inline proc "c" (self: ^TextureDescriptor, mipmapLevelCount: NS.UInteger) {
	msgSend(nil, self, "setMipmapLevelCount:", mipmapLevelCount)
}
@(objc_type=TextureDescriptor, objc_name="setPixelFormat")
TextureDescriptor_setPixelFormat :: #force_inline proc "c" (self: ^TextureDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=TextureDescriptor, objc_name="setResourceOptions")
TextureDescriptor_setResourceOptions :: #force_inline proc "c" (self: ^TextureDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=TextureDescriptor, objc_name="setSampleCount")
TextureDescriptor_setSampleCount :: #force_inline proc "c" (self: ^TextureDescriptor, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=TextureDescriptor, objc_name="setStorageMode")
TextureDescriptor_setStorageMode :: #force_inline proc "c" (self: ^TextureDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=TextureDescriptor, objc_name="setSwizzle")
TextureDescriptor_setSwizzle :: #force_inline proc "c" (self: ^TextureDescriptor, swizzle: TextureSwizzleChannels) {
	msgSend(nil, self, "setSwizzle:", swizzle)
}
@(objc_type=TextureDescriptor, objc_name="setTextureType")
TextureDescriptor_setTextureType :: #force_inline proc "c" (self: ^TextureDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=TextureDescriptor, objc_name="setUsage")
TextureDescriptor_setUsage :: #force_inline proc "c" (self: ^TextureDescriptor, usage: TextureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=TextureDescriptor, objc_name="setWidth")
TextureDescriptor_setWidth :: #force_inline proc "c" (self: ^TextureDescriptor, width: NS.UInteger) {
	msgSend(nil, self, "setWidth:", width)
}
@(objc_type=TextureDescriptor, objc_name="storageMode")
TextureDescriptor_storageMode :: #force_inline proc "c" (self: ^TextureDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=TextureDescriptor, objc_name="swizzle")
TextureDescriptor_swizzle :: #force_inline proc "c" (self: ^TextureDescriptor) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=TextureDescriptor, objc_name="texture2DDescriptorWithPixelFormat", objc_is_class_method=true)
TextureDescriptor_texture2DDescriptorWithPixelFormat :: #force_inline proc "c" (pixelFormat: PixelFormat, width: NS.UInteger, height: NS.UInteger, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "texture2DDescriptorWithPixelFormat:width:height:mipmapped:", pixelFormat, width, height, mipmapped)
}
@(objc_type=TextureDescriptor, objc_name="textureBufferDescriptorWithPixelFormat", objc_is_class_method=true)
TextureDescriptor_textureBufferDescriptorWithPixelFormat :: #force_inline proc "c" (pixelFormat: PixelFormat, width: NS.UInteger, resourceOptions: ResourceOptions, usage: TextureUsage) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureBufferDescriptorWithPixelFormat:width:resourceOptions:usage:", pixelFormat, width, resourceOptions, usage)
}
@(objc_type=TextureDescriptor, objc_name="textureCubeDescriptorWithPixelFormat", objc_is_class_method=true)
TextureDescriptor_textureCubeDescriptorWithPixelFormat :: #force_inline proc "c" (pixelFormat: PixelFormat, size: NS.UInteger, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureCubeDescriptorWithPixelFormat:size:mipmapped:", pixelFormat, size, mipmapped)
}
@(objc_type=TextureDescriptor, objc_name="textureType")
TextureDescriptor_textureType :: #force_inline proc "c" (self: ^TextureDescriptor) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=TextureDescriptor, objc_name="usage")
TextureDescriptor_usage :: #force_inline proc "c" (self: ^TextureDescriptor) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=TextureDescriptor, objc_name="width")
TextureDescriptor_width :: #force_inline proc "c" (self: ^TextureDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "width")
}

@(objc_type=TextureDescriptor, objc_name="compressionType")
TextureDescriptor_compressionType :: #force_inline proc "c" (self: ^TextureDescriptor) -> TextureCompressionType {
	return msgSend(TextureCompressionType, self, "compressionType")
}
@(objc_type=TextureDescriptor, objc_name="setCompressionType")
TextureDescriptor_setCompressionType :: #force_inline proc "c" (self: ^TextureDescriptor, compressionType: TextureCompressionType) {
	msgSend(nil, self, "setCompressionType:", compressionType)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLTextureReferenceType")
TextureReferenceType :: struct { using _: Type }

@(objc_type=TextureReferenceType, objc_name="alloc", objc_is_class_method=true)
TextureReferenceType_alloc :: #force_inline proc "c" () -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, TextureReferenceType, "alloc")
}
@(objc_type=TextureReferenceType, objc_name="init")
TextureReferenceType_init :: #force_inline proc "c" (self: ^TextureReferenceType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "init")
}
@(objc_type=TextureReferenceType, objc_name="access")
TextureReferenceType_access :: #force_inline proc "c" (self: ^TextureReferenceType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=TextureReferenceType, objc_name="isDepthTexture")
TextureReferenceType_isDepthTexture :: #force_inline proc "c" (self: ^TextureReferenceType) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=TextureReferenceType, objc_name="textureDataType")
TextureReferenceType_textureDataType :: #force_inline proc "c" (self: ^TextureReferenceType) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=TextureReferenceType, objc_name="textureType")
TextureReferenceType_textureType :: #force_inline proc "c" (self: ^TextureReferenceType) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLTileRenderPipelineColorAttachmentDescriptor")
TileRenderPipelineColorAttachmentDescriptor :: struct { using _: NS.Copying(TileRenderPipelineColorAttachmentDescriptor) }

@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
TileRenderPipelineColorAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, TileRenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="init")
TileRenderPipelineColorAttachmentDescriptor_init :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
TileRenderPipelineColorAttachmentDescriptor_pixelFormat :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
TileRenderPipelineColorAttachmentDescriptor_setPixelFormat :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLTileRenderPipelineColorAttachmentDescriptorArray")
TileRenderPipelineColorAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
TileRenderPipelineColorAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, TileRenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="init")
TileRenderPipelineColorAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptorArray) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="object")
TileRenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
TileRenderPipelineColorAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachment: ^TileRenderPipelineColorAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLTileRenderPipelineDescriptor")
TileRenderPipelineDescriptor :: struct { using _: NS.Copying(TileRenderPipelineDescriptor) }

@(objc_type=TileRenderPipelineDescriptor, objc_name="alloc", objc_is_class_method=true)
TileRenderPipelineDescriptor_alloc :: #force_inline proc "c" () -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, TileRenderPipelineDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="init")
TileRenderPipelineDescriptor_init :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="binaryArchives")
TileRenderPipelineDescriptor_binaryArchives :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="colorAttachments")
TileRenderPipelineDescriptor_colorAttachments :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="label")
TileRenderPipelineDescriptor_label :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_maxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="rasterSampleCount")
TileRenderPipelineDescriptor_rasterSampleCount :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "rasterSampleCount")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="reset")
TileRenderPipelineDescriptor_reset :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setBinaryArchives")
TileRenderPipelineDescriptor_setBinaryArchives :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setLabel")
TileRenderPipelineDescriptor_setLabel :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.UInteger) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setRasterSampleCount")
TileRenderPipelineDescriptor_setRasterSampleCount :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, rasterSampleCount: NS.UInteger) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setThreadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_setThreadgroupSizeMatchesTileSize :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, threadgroupSizeMatchesTileSize: BOOL) {
	msgSend(nil, self, "setThreadgroupSizeMatchesTileSize:", threadgroupSizeMatchesTileSize)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setTileFunction")
TileRenderPipelineDescriptor_setTileFunction :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor, tileFunction: ^Function) {
	msgSend(nil, self, "setTileFunction:", tileFunction)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="threadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_threadgroupSizeMatchesTileSize :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "threadgroupSizeMatchesTileSize")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileBuffers")
TileRenderPipelineDescriptor_tileBuffers :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "tileBuffers")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileFunction")
TileRenderPipelineDescriptor_tileFunction :: #force_inline proc "c" (self: ^TileRenderPipelineDescriptor) -> ^Function {
	return msgSend(^Function, self, "tileFunction")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLType")
Type :: struct { using _: NS.Object }

@(objc_type=Type, objc_name="alloc", objc_is_class_method=true)
Type_alloc :: #force_inline proc "c" () -> ^Type {
	return msgSend(^Type, Type, "alloc")
}
@(objc_type=Type, objc_name="init")
Type_init :: #force_inline proc "c" (self: ^Type) -> ^Type {
	return msgSend(^Type, self, "init")
}
@(objc_type=Type, objc_name="dataType")
Type_dataType :: #force_inline proc "c" (self: ^Type) -> DataType {
	return msgSend(DataType, self, "dataType")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLVertexAttribute")
VertexAttribute :: struct { using _: NS.Object }

@(objc_type=VertexAttribute, objc_name="alloc", objc_is_class_method=true)
VertexAttribute_alloc :: #force_inline proc "c" () -> ^VertexAttribute {
	return msgSend(^VertexAttribute, VertexAttribute, "alloc")
}
@(objc_type=VertexAttribute, objc_name="init")
VertexAttribute_init :: #force_inline proc "c" (self: ^VertexAttribute) -> ^VertexAttribute {
	return msgSend(^VertexAttribute, self, "init")
}
@(objc_type=VertexAttribute, objc_name="attributeIndex")
VertexAttribute_attributeIndex :: #force_inline proc "c" (self: ^VertexAttribute) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "attributeIndex")
}
@(objc_type=VertexAttribute, objc_name="attributeType")
VertexAttribute_attributeType :: #force_inline proc "c" (self: ^VertexAttribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=VertexAttribute, objc_name="isActive")
VertexAttribute_isActive :: #force_inline proc "c" (self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=VertexAttribute, objc_name="isPatchControlPointData")
VertexAttribute_isPatchControlPointData :: #force_inline proc "c" (self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=VertexAttribute, objc_name="isPatchData")
VertexAttribute_isPatchData :: #force_inline proc "c" (self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=VertexAttribute, objc_name="name")
VertexAttribute_name :: #force_inline proc "c" (self: ^VertexAttribute) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLVertexAttributeDescriptor")
VertexAttributeDescriptor :: struct { using _: NS.Copying(VertexAttributeDescriptor) }

@(objc_type=VertexAttributeDescriptor, objc_name="alloc", objc_is_class_method=true)
VertexAttributeDescriptor_alloc :: #force_inline proc "c" () -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, VertexAttributeDescriptor, "alloc")
}
@(objc_type=VertexAttributeDescriptor, objc_name="init")
VertexAttributeDescriptor_init :: #force_inline proc "c" (self: ^VertexAttributeDescriptor) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "init")
}
@(objc_type=VertexAttributeDescriptor, objc_name="bufferIndex")
VertexAttributeDescriptor_bufferIndex :: #force_inline proc "c" (self: ^VertexAttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferIndex")
}
@(objc_type=VertexAttributeDescriptor, objc_name="format")
VertexAttributeDescriptor_format :: #force_inline proc "c" (self: ^VertexAttributeDescriptor) -> VertexFormat {
	return msgSend(VertexFormat, self, "format")
}
@(objc_type=VertexAttributeDescriptor, objc_name="offset")
VertexAttributeDescriptor_offset :: #force_inline proc "c" (self: ^VertexAttributeDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "offset")
}
@(objc_type=VertexAttributeDescriptor, objc_name="setBufferIndex")
VertexAttributeDescriptor_setBufferIndex :: #force_inline proc "c" (self: ^VertexAttributeDescriptor, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setFormat")
VertexAttributeDescriptor_setFormat :: #force_inline proc "c" (self: ^VertexAttributeDescriptor, format: VertexFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setOffset")
VertexAttributeDescriptor_setOffset :: #force_inline proc "c" (self: ^VertexAttributeDescriptor, offset: NS.UInteger) {
	msgSend(nil, self, "setOffset:", offset)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLVertexAttributeDescriptorArray")
VertexAttributeDescriptorArray :: struct { using _: NS.Object }

@(objc_type=VertexAttributeDescriptorArray, objc_name="alloc", objc_is_class_method=true)
VertexAttributeDescriptorArray_alloc :: #force_inline proc "c" () -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, VertexAttributeDescriptorArray, "alloc")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="init")
VertexAttributeDescriptorArray_init :: #force_inline proc "c" (self: ^VertexAttributeDescriptorArray) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "init")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="object")
VertexAttributeDescriptorArray_object :: #force_inline proc "c" (self: ^VertexAttributeDescriptorArray, index: NS.UInteger) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="setObject")
VertexAttributeDescriptorArray_setObject :: #force_inline proc "c" (self: ^VertexAttributeDescriptorArray, attributeDesc: ^VertexAttributeDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attributeDesc, index)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLVertexBufferLayoutDescriptor")
VertexBufferLayoutDescriptor :: struct { using _: NS.Copying(VertexBufferLayoutDescriptor) }

@(objc_type=VertexBufferLayoutDescriptor, objc_name="alloc", objc_is_class_method=true)
VertexBufferLayoutDescriptor_alloc :: #force_inline proc "c" () -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, VertexBufferLayoutDescriptor, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="init")
VertexBufferLayoutDescriptor_init :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepFunction")
VertexBufferLayoutDescriptor_setStepFunction :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor, stepFunction: VertexStepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepRate")
VertexBufferLayoutDescriptor_setStepRate :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor, stepRate: NS.UInteger) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStride")
VertexBufferLayoutDescriptor_setStride :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor, stride: NS.UInteger) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepFunction")
VertexBufferLayoutDescriptor_stepFunction :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor) -> VertexStepFunction {
	return msgSend(VertexStepFunction, self, "stepFunction")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepRate")
VertexBufferLayoutDescriptor_stepRate :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stepRate")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stride")
VertexBufferLayoutDescriptor_stride :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "stride")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLVertexBufferLayoutDescriptorArray")
VertexBufferLayoutDescriptorArray :: struct { using _: NS.Object }

@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="alloc", objc_is_class_method=true)
VertexBufferLayoutDescriptorArray_alloc :: #force_inline proc "c" () -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, VertexBufferLayoutDescriptorArray, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="init")
VertexBufferLayoutDescriptorArray_init :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptorArray) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="object")
VertexBufferLayoutDescriptorArray_object :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptorArray, index: NS.UInteger) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="setObject")
VertexBufferLayoutDescriptorArray_setObject :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptorArray, bufferDesc: ^VertexBufferLayoutDescriptor, index: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", bufferDesc, index)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLVertexDescriptor")
VertexDescriptor :: struct { using _: NS.Copying(VertexDescriptor) }

@(objc_type=VertexDescriptor, objc_name="alloc", objc_is_class_method=true)
VertexDescriptor_alloc :: #force_inline proc "c" () -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, VertexDescriptor, "alloc")
}
@(objc_type=VertexDescriptor, objc_name="init")
VertexDescriptor_init :: #force_inline proc "c" (self: ^VertexDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "init")
}
@(objc_type=VertexDescriptor, objc_name="attributes")
VertexDescriptor_attributes :: #force_inline proc "c" (self: ^VertexDescriptor) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "attributes")
}
@(objc_type=VertexDescriptor, objc_name="layouts")
VertexDescriptor_layouts :: #force_inline proc "c" (self: ^VertexDescriptor) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=VertexDescriptor, objc_name="reset")
VertexDescriptor_reset :: #force_inline proc "c" (self: ^VertexDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=VertexDescriptor, objc_name="vertexDescriptor", objc_is_class_method=true)
VertexDescriptor_vertexDescriptor :: #force_inline proc "c" () -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, VertexDescriptor, "vertexDescriptor")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLVisibleFunctionTableDescriptor")
VisibleFunctionTableDescriptor :: struct { using _: NS.Copying(VisibleFunctionTableDescriptor) }

@(objc_type=VisibleFunctionTableDescriptor, objc_name="alloc", objc_is_class_method=true)
VisibleFunctionTableDescriptor_alloc :: #force_inline proc "c" () -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, VisibleFunctionTableDescriptor, "alloc")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="init")
VisibleFunctionTableDescriptor_init :: #force_inline proc "c" (self: ^VisibleFunctionTableDescriptor) -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, self, "init")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="functionCount")
VisibleFunctionTableDescriptor_functionCount :: #force_inline proc "c" (self: ^VisibleFunctionTableDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "functionCount")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="setFunctionCount")
VisibleFunctionTableDescriptor_setFunctionCount :: #force_inline proc "c" (self: ^VisibleFunctionTableDescriptor, functionCount: NS.UInteger) {
	msgSend(nil, self, "setFunctionCount:", functionCount)
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="visibleFunctionTableDescriptor", objc_is_class_method=true)
VisibleFunctionTableDescriptor_visibleFunctionTableDescriptor :: #force_inline proc "c" () -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, VisibleFunctionTableDescriptor, "visibleFunctionTableDescriptor")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructure")
AccelerationStructure :: struct { using _: Resource }

@(objc_type=AccelerationStructure, objc_name="size")
AccelerationStructure_size :: #force_inline proc "c" (self: ^AccelerationStructure) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}

@(objc_type=AccelerationStructure, objc_name="getResourceID")
AccelerationStructure_getResourceID :: #force_inline proc "c" (self: ^AccelerationStructure) -> ResourceID {
	return msgSend(ResourceID, self, "getResourceID")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructureCommandEncoder")
AccelerationStructureCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=AccelerationStructureCommandEncoder, objc_name="buildAccelerationStructure")
AccelerationStructureCommandEncoder_buildAccelerationStructure :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^AccelerationStructure, descriptor: ^AccelerationStructureDescriptor, scratchBuffer: ^Buffer, scratchBufferOffset: NS.UInteger) {
	msgSend(nil, self, "buildAccelerationStructure:descriptor:scratchBuffer:scratchBufferOffset:", accelerationStructure, descriptor, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAccelerationStructure")
AccelerationStructureCommandEncoder_copyAccelerationStructure :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure, destinationAccelerationStructure: ^AccelerationStructure) {
	msgSend(nil, self, "copyAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAndCompactAccelerationStructure")
AccelerationStructureCommandEncoder_copyAndCompactAccelerationStructure :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure, destinationAccelerationStructure: ^AccelerationStructure) {
	msgSend(nil, self, "copyAndCompactAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="refitAccelerationStructure")
AccelerationStructureCommandEncoder_refitAccelerationStructure :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^AccelerationStructure, descriptor: ^AccelerationStructureDescriptor, destinationAccelerationStructure: ^AccelerationStructure, scratchBuffer: ^Buffer, scratchBufferOffset: NS.UInteger) {
	msgSend(nil, self, "refitAccelerationStructure:descriptor:destination:scratchBuffer:scratchBufferOffset:", sourceAccelerationStructure, descriptor, destinationAccelerationStructure, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="refitAccelerationStructureWithOptions")
AccelerationStructureCommandEncoder_refitAccelerationStructureWithOptions :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^AccelerationStructure, descriptor: ^AccelerationStructureDescriptor, destinationAccelerationStructure: ^AccelerationStructure, scratchBuffer: ^Buffer, scratchBufferOffset: NS.UInteger, options: AccelerationStructureRefitOptions) {
	msgSend(nil, self, "refitAccelerationStructure:descriptor:destination:scratchBuffer:scratchBufferOffset:options:", sourceAccelerationStructure, descriptor, destinationAccelerationStructure, scratchBuffer, scratchBufferOffset, options)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="sampleCountersInBuffer")
AccelerationStructureCommandEncoder_sampleCountersInBuffer :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="updateFence")
AccelerationStructureCommandEncoder_updateFence :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeap")
AccelerationStructureCommandEncoder_useHeap :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeaps")
AccelerationStructureCommandEncoder_useHeaps :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResource")
AccelerationStructureCommandEncoder_useResource :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResources")
AccelerationStructureCommandEncoder_useResources :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, NS.UInteger(len(resources)), usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="waitForFence")
AccelerationStructureCommandEncoder_waitForFence :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="writeCompactedAccelerationStructureSize")
AccelerationStructureCommandEncoder_writeCompactedAccelerationStructureSize :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^AccelerationStructure, buffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "writeCompactedAccelerationStructureSize:toBuffer:offset:", accelerationStructure, buffer, offset)
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLAccelerationStructurePassSampleBufferAttachmentDescriptor")
AccelerationStructurePassSampleBufferAttachmentDescriptor :: struct { using _: NS.Copying(AccelerationStructurePassSampleBufferAttachmentDescriptor) }

@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructurePassSampleBufferAttachmentDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructurePassSampleBufferAttachmentDescriptor {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptor, AccelerationStructurePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="init")
AccelerationStructurePassSampleBufferAttachmentDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor) -> ^AccelerationStructurePassSampleBufferAttachmentDescriptor {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptor, self, "init")
}


@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
AccelerationStructurePassSampleBufferAttachmentDescriptor_sampleBuffer :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "sampleBuffer")
}
@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
AccelerationStructurePassSampleBufferAttachmentDescriptor_setSampleBuffer :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor, sampleBuffer: ^CounterSampleBuffer) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}


@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
AccelerationStructurePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "startOfEncoderSampleIndex")
}
@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
AccelerationStructurePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}


@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
AccelerationStructurePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "endOfEncoderSampleIndex")
}
@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
AccelerationStructurePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.UInteger) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLAccelerationStructurePassSampleBufferAttachmentDescriptorArray")
AccelerationStructurePassSampleBufferAttachmentDescriptorArray :: struct { using _: NS.Object }

@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptorArray, objc_name="alloc", objc_is_class_method=true)
AccelerationStructurePassSampleBufferAttachmentDescriptorArray_alloc :: #force_inline proc "c" () -> ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, AccelerationStructurePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptorArray, objc_name="init")
AccelerationStructurePassSampleBufferAttachmentDescriptorArray_init :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray) -> ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, self, "init")
}

@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptorArray, objc_name="object")
AccelerationStructurePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^AccelerationStructurePassSampleBufferAttachmentDescriptor {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}

@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
AccelerationStructurePassSampleBufferAttachmentDescriptorArray_setObject :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, attachment: ^AccelerationStructurePassSampleBufferAttachmentDescriptor, attachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setObject:atIndexedSubscript:", attachment, attachmentIndex)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLAccelerationStructurePassDescriptor")
AccelerationStructurePassDescriptor :: struct { using _: NS.Copying(AccelerationStructurePassDescriptor) }


@(objc_type=AccelerationStructurePassDescriptor, objc_name="alloc", objc_is_class_method=true)
AccelerationStructurePassDescriptor_alloc :: #force_inline proc "c" () -> ^AccelerationStructurePassDescriptor {
	return msgSend(^AccelerationStructurePassDescriptor, AccelerationStructurePassDescriptor, "alloc")
}
@(objc_type=AccelerationStructurePassDescriptor, objc_name="init")
AccelerationStructurePassDescriptor_init :: #force_inline proc "c" (self: ^AccelerationStructurePassDescriptor) -> ^AccelerationStructurePassDescriptor {
	return msgSend(^AccelerationStructurePassDescriptor, self, "init")
}


@(objc_type=AccelerationStructurePassDescriptor, objc_name="accelerationStructurePassDescriptor", objc_is_class_method=true)
AccelerationStructurePassDescriptor_accelerationStructurePassDescriptor :: #force_inline proc "c" () -> ^AccelerationStructurePassDescriptor {
	return msgSend(^AccelerationStructurePassDescriptor, AccelerationStructurePassDescriptor, "accelerationStructurePassDescriptor")
}
@(objc_type=AccelerationStructurePassDescriptor, objc_name="sampleBufferAttachments")
AccelerationStructurePassDescriptor_sampleBufferAttachments  :: #force_inline proc "c" (self: ^AccelerationStructurePassDescriptor) -> ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}


////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLBinding")
Binding :: struct { using _: NS.Object }

@(objc_type=Binding, objc_name="name")
Binding_name :: #force_inline proc "c" (self: ^Binding) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Binding, objc_name="type")
Binding_type :: #force_inline proc "c" (self: ^Binding) -> BindingType {
	return msgSend(BindingType, self, "type")
}
@(objc_type=Binding, objc_name="access")
Binding_access :: #force_inline proc "c" (self: ^Binding) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=Binding, objc_name="index")
Binding_index :: #force_inline proc "c" (self: ^Binding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "index")
}
@(objc_type=Binding, objc_name="isUsed")
Binding_isUsed :: #force_inline proc "c" (self: ^Binding) -> BOOL {
	return msgSend(BOOL, self, "isUsed")
}
@(objc_type=Binding, objc_name="isArgument")
Binding_isArgument :: #force_inline proc "c" (self: ^Binding) -> BOOL {
	return msgSend(BOOL, self, "isArgument")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLBufferBinding")
BufferBinding :: struct { using _: Binding }

@(objc_type=BufferBinding, objc_name="bufferAlignment")
BufferBinding_bufferAlignment :: #force_inline proc "c" (self: ^BufferBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferAlignment")
}
@(objc_type=BufferBinding, objc_name="bufferDataSize")
BufferBinding_bufferDataSize :: #force_inline proc "c" (self: ^BufferBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferDataSize")
}
@(objc_type=BufferBinding, objc_name="bufferDataType")
BufferBinding_bufferDataType :: #force_inline proc "c" (self: ^BufferBinding) -> DataType {
	return msgSend(DataType, self, "bufferDataType")
}
@(objc_type=BufferBinding, objc_name="bufferStructType")
BufferBinding_bufferStructType :: #force_inline proc "c" (self: ^BufferBinding) -> ^StructType {
	return msgSend(^StructType, self, "bufferStructType")
}
@(objc_type=BufferBinding, objc_name="bufferPointerType")
BufferBinding_bufferPointerType :: #force_inline proc "c" (self: ^BufferBinding) -> ^PointerType {
	return msgSend(^PointerType, self, "bufferPointerType")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLThreadgroupBinding")
ThreadgroupBinding :: struct { using _: Binding }

@(objc_type=ThreadgroupBinding, objc_name="threadgroupMemoryAlignment")
ThreadgroupBinding_threadgroupMemoryAlignment :: #force_inline proc "c" (self: ^ThreadgroupBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryAlignment")
}
@(objc_type=ThreadgroupBinding, objc_name="threadgroupMemoryDataSize")
ThreadgroupBinding_threadgroupMemoryDataSize :: #force_inline proc "c" (self: ^ThreadgroupBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadgroupMemoryDataSize")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLTextureBinding")
TextureBinding :: struct { using _: Binding }

@(objc_type=TextureBinding, objc_name="textureType")
TextureBinding_textureType :: #force_inline proc "c" (self: ^TextureBinding) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=TextureBinding, objc_name="textureDataType")
TextureBinding_textureDataType :: #force_inline proc "c" (self: ^TextureBinding) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=TextureBinding, objc_name="isDepthTexture")
TextureBinding_isDepthTexture :: #force_inline proc "c" (self: ^TextureBinding) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=TextureBinding, objc_name="arrayLength")
TextureBinding_arrayLength :: #force_inline proc "c" (self: ^TextureBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLObjectPayloadBinding")
ObjectPayloadBinding :: struct { using _: Binding }

@(objc_type=ObjectPayloadBinding, objc_name="objectPayloadAlignment")
ObjectPayloadBinding_objectPayloadAlignment :: #force_inline proc "c" (self: ^ObjectPayloadBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "objectPayloadAlignment")
}
@(objc_type=ObjectPayloadBinding, objc_name="objectPayloadDataSize")
ObjectPayloadBinding_objectPayloadDataSize :: #force_inline proc "c" (self: ^ObjectPayloadBinding) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "objectPayloadDataSize")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLArgumentEncoder")
ArgumentEncoder :: struct { using _: NS.Object }

@(objc_type=ArgumentEncoder, objc_name="alignment")
ArgumentEncoder_alignment :: #force_inline proc "c" (self: ^ArgumentEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "alignment")
}
@(objc_type=ArgumentEncoder, objc_name="constantData")
ArgumentEncoder_constantData :: #force_inline proc "c" (self: ^ArgumentEncoder, index: NS.UInteger) -> rawptr {
	return msgSend(rawptr, self, "constantDataAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="device")
ArgumentEncoder_device :: #force_inline proc "c" (self: ^ArgumentEncoder) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=ArgumentEncoder, objc_name="encodedLength")
ArgumentEncoder_encodedLength :: #force_inline proc "c" (self: ^ArgumentEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "encodedLength")
}
@(objc_type=ArgumentEncoder, objc_name="label")
ArgumentEncoder_label :: #force_inline proc "c" (self: ^ArgumentEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ArgumentEncoder, objc_name="newArgumentEncoderForBuffer")
ArgumentEncoder_newArgumentEncoderForBuffer :: #force_inline proc "c" (self: ^ArgumentEncoder, index: NS.UInteger) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderForBufferAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="setAccelerationStructure")
ArgumentEncoder_setAccelerationStructure :: #force_inline proc "c" (self: ^ArgumentEncoder, accelerationStructure: ^AccelerationStructure, index: NS.UInteger) {
	msgSend(nil, self, "setAccelerationStructure:atIndex:", accelerationStructure, index)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBufferWithOffset")
ArgumentEncoder_setArgumentBufferWithOffset :: #force_inline proc "c" (self: ^ArgumentEncoder, argumentBuffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "setArgumentBuffer:offset:", argumentBuffer, offset)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBufferWithStartOffset")
ArgumentEncoder_setArgumentBuffer_startOffsetWithStartOffset :: #force_inline proc "c" (self: ^ArgumentEncoder, argumentBuffer: ^Buffer, startOffset: NS.UInteger, arrayElement: NS.UInteger) {
	msgSend(nil, self, "setArgumentBuffer:startOffset:arrayElement:", argumentBuffer, startOffset, arrayElement)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffer")
ArgumentEncoder_setBuffer :: #force_inline proc "c" (self: ^ArgumentEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffers")
ArgumentEncoder_setBuffers :: #force_inline proc "odin" (self: ^ArgumentEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineState")
ArgumentEncoder_setComputePipelineState :: #force_inline proc "c" (self: ^ArgumentEncoder, pipeline: ^ComputePipelineState, index: NS.UInteger) {
	msgSend(nil, self, "setComputePipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineStates")
ArgumentEncoder_setComputePipelineStates :: #force_inline proc "odin" (self: ^ArgumentEncoder, pipelines: []^ComputePipelineState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setComputePipelineStates:withRange:", raw_data(pipelines), range)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffer")
ArgumentEncoder_setIndirectCommandBuffer :: #force_inline proc "c" (self: ^ArgumentEncoder, indirectCommandBuffer: ^IndirectCommandBuffer, index: NS.UInteger) {
	msgSend(nil, self, "setIndirectCommandBuffer:atIndex:", indirectCommandBuffer, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffers")
ArgumentEncoder_setIndirectCommandBuffers :: #force_inline proc "odin" (self: ^ArgumentEncoder, buffers: []^IndirectCommandBuffer, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setIndirectCommandBuffers:withRange:", raw_data(buffers), range)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTable")
ArgumentEncoder_setIntersectionFunctionTable :: #force_inline proc "c" (self: ^ArgumentEncoder, intersectionFunctionTable: ^IntersectionFunctionTable, index: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTable:atIndex:", intersectionFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTables")
ArgumentEncoder_setIntersectionFunctionTables :: #force_inline proc "odin" (self: ^ArgumentEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withRange:", raw_data(intersectionFunctionTables), range)
}
@(objc_type=ArgumentEncoder, objc_name="setLabel")
ArgumentEncoder_setLabel :: #force_inline proc "c" (self: ^ArgumentEncoder, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineState")
ArgumentEncoder_setRenderPipelineState :: #force_inline proc "c" (self: ^ArgumentEncoder, pipeline: ^RenderPipelineState, index: NS.UInteger) {
	msgSend(nil, self, "setRenderPipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineStates")
ArgumentEncoder_setRenderPipelineStates :: #force_inline proc "odin" (self: ^ArgumentEncoder, pipelines: []^RenderPipelineState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setRenderPipelineStates:withRange:", raw_data(pipelines), range)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerState")
ArgumentEncoder_setSamplerState :: #force_inline proc "c" (self: ^ArgumentEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerStates")
ArgumentEncoder_setSamplerStates :: #force_inline proc "odin" (self: ^ArgumentEncoder, samplers: []^SamplerState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(samplers)))
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=ArgumentEncoder, objc_name="setTexture")
ArgumentEncoder_setTexture :: #force_inline proc "c" (self: ^ArgumentEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ArgumentEncoder, objc_name="setTextures")
ArgumentEncoder_setTextures :: #force_inline proc "odin" (self: ^ArgumentEncoder, textures: []^Texture, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(textures)))
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTable")
ArgumentEncoder_setVisibleFunctionTable :: #force_inline proc "c" (self: ^ArgumentEncoder, visibleFunctionTable: ^VisibleFunctionTable, index: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atIndex:", visibleFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTables")
ArgumentEncoder_setVisibleFunctionTables :: #force_inline proc "odin" (self: ^ArgumentEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(visibleFunctionTables)))
	msgSend(nil, self, "setVisibleFunctionTables:withRange:", raw_data(visibleFunctionTables), range)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLBinaryArchive")
BinaryArchive :: struct { using _: NS.Copying(BinaryArchive) }

@(objc_type=BinaryArchive, objc_name="addComputePipelineFunctions")
BinaryArchive_addComputePipelineFunctions :: #force_inline proc "contextless" (self: ^BinaryArchive, descriptor: ^ComputePipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addComputePipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="addRenderPipelineFunctions")
BinaryArchive_addRenderPipelineFunctions :: #force_inline proc "contextless" (self: ^BinaryArchive, descriptor: ^RenderPipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addRenderPipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="addTileRenderPipelineFunctions")
BinaryArchive_addTileRenderPipelineFunctions :: #force_inline proc "contextless" (self: ^BinaryArchive, descriptor: ^TileRenderPipelineDescriptor) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addTileRenderPipelineFunctionsWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="device")
BinaryArchive_device :: #force_inline proc "c" (self: ^BinaryArchive) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=BinaryArchive, objc_name="label")
BinaryArchive_label :: #force_inline proc "c" (self: ^BinaryArchive) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=BinaryArchive, objc_name="serializeToURL")
BinaryArchive_serializeToURL :: #force_inline proc "contextless" (self: ^BinaryArchive, url: ^NS.URL) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "serializeToURL:error:", url, &error)
	return
}
@(objc_type=BinaryArchive, objc_name="setLabel")
BinaryArchive_setLabel :: #force_inline proc "c" (self: ^BinaryArchive, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}


@(objc_type=BinaryArchive, objc_name="addFunction")
BinaryArchive_addFunction :: #force_inline proc "contextless" (self: ^BinaryArchive, descriptor: ^FunctionDescriptor, library: ^Library) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "addFunction:", descriptor, library, &error)
	return
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLBlitCommandEncoder")
BlitCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=BlitCommandEncoder, objc_name="copyFromBufferEx")
BlitCommandEncoder_copyFromBufferEx :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, sourceBytesPerRow: NS.UInteger, sourceBytesPerImage: NS.UInteger, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBufferExWithOptions")
BlitCommandEncoder_copyFromBufferExWithOptions :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, sourceBytesPerRow: NS.UInteger, sourceBytesPerImage: NS.UInteger, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin, options: BlitOption) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:options:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBuffer")
BlitCommandEncoder_copyFromBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceBuffer: ^Buffer, sourceOffset: NS.UInteger, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, size: NS.UInteger) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:toBuffer:destinationOffset:size:", sourceBuffer, sourceOffset, destinationBuffer, destinationOffset, size)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureEx")
BlitCommandEncoder_copyFromTextureEx :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, destinationBytesPerRow: NS.UInteger, destinationBytesPerImage: NS.UInteger) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureExWithOptions")
BlitCommandEncoder_copyFromTextureExWithOptions :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger, destinationBytesPerRow: NS.UInteger, destinationBytesPerImage: NS.UInteger, options: BlitOption) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:options:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureWithDestinationOrigin")
BlitCommandEncoder_copyFromTextureWithDestinationOrigin :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, sourceOrigin: Origin, sourceSize: Size, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTextureWithCounts")
BlitCommandEncoder_copyFromTextureWithCounts :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceTexture: ^Texture, sourceSlice: NS.UInteger, sourceLevel: NS.UInteger, destinationTexture: ^Texture, destinationSlice: NS.UInteger, destinationLevel: NS.UInteger, sliceCount: NS.UInteger, levelCount: NS.UInteger) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:toTexture:destinationSlice:destinationLevel:sliceCount:levelCount:", sourceTexture, sourceSlice, sourceLevel, destinationTexture, destinationSlice, destinationLevel, sliceCount, levelCount)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture")
BlitCommandEncoder_copyFromTexture :: #force_inline proc "c" (self: ^BlitCommandEncoder, sourceTexture: ^Texture, destinationTexture: ^Texture) {
	msgSend(nil, self, "copyFromTexture:toTexture:", sourceTexture, destinationTexture)
}
@(objc_type=BlitCommandEncoder, objc_name="copyIndirectCommandBuffer")
BlitCommandEncoder_copyIndirectCommandBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, source: ^IndirectCommandBuffer, sourceRange: NS.Range, destination: ^IndirectCommandBuffer, destinationIndex: NS.UInteger) {
	msgSend(nil, self, "copyIndirectCommandBuffer:sourceRange:destination:destinationIndex:", source, sourceRange, destination, destinationIndex)
}
@(objc_type=BlitCommandEncoder, objc_name="fillBuffer")
BlitCommandEncoder_fillBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, buffer: ^Buffer, range: NS.Range, value: u8) {
	msgSend(nil, self, "fillBuffer:range:value:", buffer, range, value)
}
@(objc_type=BlitCommandEncoder, objc_name="generateMipmapsForTexture")
BlitCommandEncoder_generateMipmapsForTexture :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "generateMipmapsForTexture:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="getTextureAccessCounters")
BlitCommandEncoder_getTextureAccessCounters :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger, resetCounters: BOOL, countersBuffer: ^Buffer, countersBufferOffset: NS.UInteger) {
	msgSend(nil, self, "getTextureAccessCounters:region:mipLevel:slice:resetCounters:countersBuffer:countersBufferOffset:", texture, region, mipLevel, slice, resetCounters, countersBuffer, countersBufferOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccess")
BlitCommandEncoder_optimizeContentsForCPUAccess :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccessWithSliceAndLevel")
BlitCommandEncoder_optimizeContentsForCPUAccessWithSliceAndLevel :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccess")
BlitCommandEncoder_optimizeContentsForGPUAccess :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccessWithSliceAndLevel")
BlitCommandEncoder_optimizeContentsForGPUAccessWithSliceAndLevel :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeIndirectCommandBuffer")
BlitCommandEncoder_optimizeIndirectCommandBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, indirectCommandBuffer: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "optimizeIndirectCommandBuffer:withRange:", indirectCommandBuffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetCommandsInBuffer")
BlitCommandEncoder_resetCommandsInBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, buffer: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "resetCommandsInBuffer:withRange:", buffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetTextureAccessCounters")
BlitCommandEncoder_resetTextureAccessCounters :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "resetTextureAccessCounters:region:mipLevel:slice:", texture, region, mipLevel, slice)
}
@(objc_type=BlitCommandEncoder, objc_name="resolveCounters")
BlitCommandEncoder_resolveCounters :: #force_inline proc "c" (self: ^BlitCommandEncoder, sampleBuffer: ^Buffer, range: NS.Range, destinationBuffer: ^Buffer, destinationOffset: NS.UInteger) {
	msgSend(nil, self, "resolveCounters:inRange:destinationBuffer:destinationOffset:", sampleBuffer, range, destinationBuffer, destinationOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="sampleCountersInBuffer")
BlitCommandEncoder_sampleCountersInBuffer :: #force_inline proc "c" (self: ^BlitCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeResource")
BlitCommandEncoder_synchronizeResource :: #force_inline proc "c" (self: ^BlitCommandEncoder, resource: ^Resource) {
	msgSend(nil, self, "synchronizeResource:", resource)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeTexture")
BlitCommandEncoder_synchronizeTexture :: #force_inline proc "c" (self: ^BlitCommandEncoder, texture: ^Texture, slice: NS.UInteger, level: NS.UInteger) {
	msgSend(nil, self, "synchronizeTexture:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="updateFence")
BlitCommandEncoder_updateFence :: #force_inline proc "c" (self: ^BlitCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=BlitCommandEncoder, objc_name="waitForFence")
BlitCommandEncoder_waitForFence :: #force_inline proc "c" (self: ^BlitCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLBuffer")
Buffer :: struct { using _: Resource }

@(objc_type=Buffer, objc_name="addDebugMarker")
Buffer_addDebugMarker :: #force_inline proc "c" (self: ^Buffer, marker: ^NS.String, range: NS.Range) {
	msgSend(nil, self, "addDebugMarker:range:", marker, range)
}
@(objc_type=Buffer, objc_name="contents")
Buffer_contents :: #force_inline proc "c" (self: ^Buffer) -> []byte {
	contents := msgSend([^]byte, self, "contents")
	length := Buffer_length(self)
	return contents[:length]
}
@(objc_type=Buffer, objc_name="contentsPointer")
Buffer_contentsPointer :: #force_inline proc "c" (self: ^Buffer) -> rawptr {
	return msgSend(rawptr, self, "contents")
}
@(objc_type=Buffer, objc_name="contentsAsSlice")
Buffer_contentsAsSlice :: #force_inline proc "c" (self: ^Buffer, $T: typeid/[]$E) -> T {
	contents := msgSend([^]byte, self, "contents")
	length := Buffer_length(self)
	return mem.slice_data_cast(T, contents[:length])
}
@(objc_type=Buffer, objc_name="contentsAsType")
Buffer_contentsAsType :: #force_inline proc "c" (self: ^Buffer, $T: typeid, offset: uintptr = 0) -> ^T {
	ptr := msgSend(rawptr, self, "contents")
	return (^T)(uintptr(ptr) + offset)
}
@(objc_type=Buffer, objc_name="didModifyRange")
Buffer_didModifyRange :: #force_inline proc "c" (self: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "didModifyRange:", range)
}
@(objc_type=Buffer, objc_name="length")
Buffer_length :: #force_inline proc "c" (self: ^Buffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "length")
}
@(objc_type=Buffer, objc_name="newRemoteBufferViewForDevice")
Buffer_newRemoteBufferViewForDevice :: #force_inline proc "c" (self: ^Buffer, device: ^Device) -> ^Buffer {
	return msgSend(^Buffer, self, "newRemoteBufferViewForDevice:", device)
}
@(objc_type=Buffer, objc_name="newTexture")
Buffer_newTexture :: #force_inline proc "c" (self: ^Buffer, descriptor: ^TextureDescriptor, offset: NS.UInteger, bytesPerRow: NS.UInteger) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:offset:bytesPerRow:", descriptor, offset, bytesPerRow)
}
@(objc_type=Buffer, objc_name="remoteStorageBuffer")
Buffer_remoteStorageBuffer :: #force_inline proc "c" (self: ^Buffer) -> ^Buffer {
	return msgSend(^Buffer, self, "remoteStorageBuffer")
}
@(objc_type=Buffer, objc_name="removeAllDebugMarkers")
Buffer_removeAllDebugMarkers :: #force_inline proc "c" (self: ^Buffer) {
	msgSend(nil, self, "removeAllDebugMarkers")
}
@(objc_type=Buffer, objc_name="newRemoveBufferViewForDevice")
Buffer_newRemoveBufferViewForDevice :: #force_inline proc "c" (self: ^Buffer, device: ^Device) -> ^Buffer {
	return msgSend(^Buffer, self, "newRemoteBufferViewForDevice:", device)
}
@(objc_type=Buffer, objc_name="gpuAddress")
Buffer_gpuAddress :: #force_inline proc "c" (self: ^Buffer) -> u64 {
	return msgSend(u64, self, "gpuAddress")
}


////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCaptureScope")
CaptureScope :: struct { using _: NS.Object }

@(objc_type=CaptureScope, objc_name="beginScope")
CaptureScope_beginScope :: #force_inline proc "c" (self: ^CaptureScope) {
	msgSend(nil, self, "beginScope")
}
@(objc_type=CaptureScope, objc_name="commandQueue")
CaptureScope_commandQueue :: #force_inline proc "c" (self: ^CaptureScope) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandQueue")
}
@(objc_type=CaptureScope, objc_name="device")
CaptureScope_device :: #force_inline proc "c" (self: ^CaptureScope) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CaptureScope, objc_name="endScope")
CaptureScope_endScope :: #force_inline proc "c" (self: ^CaptureScope) {
	msgSend(nil, self, "endScope")
}
@(objc_type=CaptureScope, objc_name="label")
CaptureScope_label :: #force_inline proc "c" (self: ^CaptureScope) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CaptureScope, objc_name="setLabel")
CaptureScope_setLabel :: #force_inline proc "c" (self: ^CaptureScope, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCommandBuffer")
CommandBuffer :: struct { using _: NS.Object }

@(objc_type=CommandBuffer, objc_name="GPUEndTime")
CommandBuffer_GPUEndTime :: #force_inline proc "c" (self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUEndTime")
}
@(objc_type=CommandBuffer, objc_name="GPUStartTime")
CommandBuffer_GPUStartTime :: #force_inline proc "c" (self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUStartTime")
}
@(objc_type=CommandBuffer, objc_name="accelerationStructureCommandEncoder")
CommandBuffer_accelerationStructureCommandEncoder :: #force_inline proc "c" (self: ^CommandBuffer) -> ^AccelerationStructureCommandEncoder {
	return msgSend(^AccelerationStructureCommandEncoder, self, "accelerationStructureCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="accelerationStructureCommandEncoderWithDescriptor")
CommandBuffer_accelerationStructureCommandEncoderWithDescriptor :: #force_inline proc "c" (self: ^CommandBuffer, descriptor: ^AccelerationStructurePassDescriptor) -> ^AccelerationStructureCommandEncoder {
	return msgSend(^AccelerationStructureCommandEncoder, self, "accelerationStructureCommandEncoderWithDescriptor:", descriptor)
}
@(objc_type=CommandBuffer, objc_name="addCompletedHandler")
CommandBuffer_addCompletedHandler :: #force_inline proc "c" (self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addCompletedHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="addScheduledHandler")
CommandBuffer_addScheduledHandler :: #force_inline proc "c" (self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addScheduledHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoder")
CommandBuffer_blitCommandEncoder :: #force_inline proc "c" (self: ^CommandBuffer) -> ^BlitCommandEncoder {
	return msgSend(^BlitCommandEncoder, self, "blitCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoderWithDescriptor")
CommandBuffer_blitCommandEncoderWithDescriptor :: #force_inline proc "c" (self: ^CommandBuffer, blitPassDescriptor: ^BlitPassDescriptor) -> ^BlitCommandEncoder {
	return msgSend(^BlitCommandEncoder, self, "blitCommandEncoderWithDescriptor:", blitPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="commandQueue")
CommandBuffer_commandQueue :: #force_inline proc "c" (self: ^CommandBuffer) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandQueue")
}
@(objc_type=CommandBuffer, objc_name="commit")
CommandBuffer_commit :: #force_inline proc "c" (self: ^CommandBuffer) {
	msgSend(nil, self, "commit")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoder")
CommandBuffer_computeCommandEncoder :: #force_inline proc "c" (self: ^CommandBuffer) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDescriptor")
CommandBuffer_computeCommandEncoderWithDescriptor :: #force_inline proc "c" (self: ^CommandBuffer, computePassDescriptor: ^ComputePassDescriptor) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoderWithDescriptor:", computePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDispatchType")
CommandBuffer_computeCommandEncoderWithDispatchType :: #force_inline proc "c" (self: ^CommandBuffer, dispatchType: DispatchType) -> ^ComputeCommandEncoder {
	return msgSend(^ComputeCommandEncoder, self, "computeCommandEncoderWithDispatchType:", dispatchType)
}
@(objc_type=CommandBuffer, objc_name="device")
CommandBuffer_device :: #force_inline proc "c" (self: ^CommandBuffer) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandBuffer, objc_name="encodeSignalEvent")
CommandBuffer_encodeSignalEvent :: #force_inline proc "c" (self: ^CommandBuffer, event: ^Event, value: u64) {
	msgSend(nil, self, "encodeSignalEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="encodeWaitForEvent")
CommandBuffer_encodeWaitForEvent :: #force_inline proc "c" (self: ^CommandBuffer, event: ^Event, value: u64) {
	msgSend(nil, self, "encodeWaitForEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="enqueue")
CommandBuffer_enqueue :: #force_inline proc "c" (self: ^CommandBuffer) {
	msgSend(nil, self, "enqueue")
}
@(objc_type=CommandBuffer, objc_name="error")
CommandBuffer_error :: #force_inline proc "c" (self: ^CommandBuffer) -> ^NS.Error {
	return msgSend(^NS.Error, self, "error")
}
@(objc_type=CommandBuffer, objc_name="errorOptions")
CommandBuffer_errorOptions :: #force_inline proc "c" (self: ^CommandBuffer) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBuffer, objc_name="kernelEndTime")
CommandBuffer_kernelEndTime :: #force_inline proc "c" (self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelEndTime")
}
@(objc_type=CommandBuffer, objc_name="kernelStartTime")
CommandBuffer_kernelStartTime :: #force_inline proc "c" (self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelStartTime")
}
@(objc_type=CommandBuffer, objc_name="label")
CommandBuffer_label :: #force_inline proc "c" (self: ^CommandBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandBuffer, objc_name="logs")
CommandBuffer_logs :: #force_inline proc "c" (self: ^CommandBuffer) -> ^LogContainer {
	return msgSend(^LogContainer, self, "logs")
}
@(objc_type=CommandBuffer, objc_name="parallelRenderCommandEncoder")
CommandBuffer_parallelRenderCommandEncoder :: #force_inline proc "c" (self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^ParallelRenderCommandEncoder {
	return msgSend(^ParallelRenderCommandEncoder, self, "parallelRenderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="popDebugGroup")
CommandBuffer_popDebugGroup :: #force_inline proc "c" (self: ^CommandBuffer) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandBuffer, objc_name="presentDrawable")
CommandBuffer_presentDrawable :: #force_inline proc "c" (self: ^CommandBuffer, drawable: ^Drawable) {
	msgSend(nil, self, "presentDrawable:", drawable)
}
@(objc_type=CommandBuffer, objc_name="presentDrawableAfterMinimumDuration")
CommandBuffer_presentDrawableAfterMinimumDuration :: #force_inline proc "c" (self: ^CommandBuffer, drawable: ^Drawable, duration: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:afterMinimumDuration:", drawable, duration)
}
@(objc_type=CommandBuffer, objc_name="presentDrawableAtTime")
CommandBuffer_presentDrawableAtTime :: #force_inline proc "c" (self: ^CommandBuffer, drawable: ^Drawable, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:atTime:", drawable, presentationTime)
}
@(objc_type=CommandBuffer, objc_name="pushDebugGroup")
CommandBuffer_pushDebugGroup :: #force_inline proc "c" (self: ^CommandBuffer, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandBuffer, objc_name="renderCommandEncoderWithDescriptor")
CommandBuffer_renderCommandEncoderWithDescriptor :: #force_inline proc "c" (self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^RenderCommandEncoder {
	return msgSend(^RenderCommandEncoder, self, "renderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoder")
CommandBuffer_resourceStateCommandEncoder :: #force_inline proc "c" (self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "resourceStateCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoderWithDescriptor")
CommandBuffer_resourceStateCommandEncoderWithDescriptor :: #force_inline proc "c" (self: ^CommandBuffer, resourceStatePassDescriptor: ^ResourceStatePassDescriptor) -> ^ResourceStateCommandEncoder {
	return msgSend(^ResourceStateCommandEncoder, self, "resourceStateCommandEncoderWithDescriptor:", resourceStatePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="retainedReferences")
CommandBuffer_retainedReferences :: #force_inline proc "c" (self: ^CommandBuffer) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBuffer, objc_name="setLabel")
CommandBuffer_setLabel :: #force_inline proc "c" (self: ^CommandBuffer, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CommandBuffer, objc_name="status")
CommandBuffer_status :: #force_inline proc "c" (self: ^CommandBuffer) -> CommandBufferStatus {
	return msgSend(CommandBufferStatus, self, "status")
}
@(objc_type=CommandBuffer, objc_name="waitUntilCompleted")
CommandBuffer_waitUntilCompleted :: #force_inline proc "c" (self: ^CommandBuffer) {
	msgSend(nil, self, "waitUntilCompleted")
}
@(objc_type=CommandBuffer, objc_name="waitUntilScheduled")
CommandBuffer_waitUntilScheduled :: #force_inline proc "c" (self: ^CommandBuffer) {
	msgSend(nil, self, "waitUntilScheduled")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCommandBufferEncoderInfo")
CommandBufferEncoderInfo :: struct { using _: NS.Object }

@(objc_type=CommandBufferEncoderInfo, objc_name="debugSignposts")
CommandBufferEncoderInfo_debugSignposts :: #force_inline proc "c" (self: ^CommandBufferEncoderInfo) -> ^NS.Array {
	return msgSend(^NS.Array, self, "debugSignposts")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="errorState")
CommandBufferEncoderInfo_errorState :: #force_inline proc "c" (self: ^CommandBufferEncoderInfo) -> CommandEncoderErrorState {
	return msgSend(CommandEncoderErrorState, self, "errorState")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="label")
CommandBufferEncoderInfo_label :: #force_inline proc "c" (self: ^CommandBufferEncoderInfo) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCommandEncoder")
CommandEncoder :: struct { using _: NS.Object }

@(objc_type=CommandEncoder, objc_name="device")
CommandEncoder_device :: #force_inline proc "c" (self: ^CommandEncoder) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandEncoder, objc_name="endEncoding")
CommandEncoder_endEncoding :: #force_inline proc "c" (self: ^CommandEncoder) {
	msgSend(nil, self, "endEncoding")
}
@(objc_type=CommandEncoder, objc_name="insertDebugSignpost")
CommandEncoder_insertDebugSignpost :: #force_inline proc "c" (self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "insertDebugSignpost:", string)
}
@(objc_type=CommandEncoder, objc_name="label")
CommandEncoder_label :: #force_inline proc "c" (self: ^CommandEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandEncoder, objc_name="popDebugGroup")
CommandEncoder_popDebugGroup :: #force_inline proc "c" (self: ^CommandEncoder) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandEncoder, objc_name="pushDebugGroup")
CommandEncoder_pushDebugGroup :: #force_inline proc "c" (self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandEncoder, objc_name="setLabel")
CommandEncoder_setLabel :: #force_inline proc "c" (self: ^CommandEncoder, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCommandQueue")
CommandQueue :: struct { using _: NS.Object }

@(objc_type=CommandQueue, objc_name="commandBuffer")
CommandQueue_commandBuffer :: #force_inline proc "c" (self: ^CommandQueue) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "commandBuffer")
}
@(objc_type=CommandQueue, objc_name="commandBufferWithDescriptor")
CommandQueue_commandBufferWithDescriptor :: #force_inline proc "c" (self: ^CommandQueue, descriptor: ^CommandBufferDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "commandBufferWithDescriptor:", descriptor)
}
@(objc_type=CommandQueue, objc_name="commandBufferWithUnretainedReferences")
CommandQueue_commandBufferWithUnretainedReferences :: #force_inline proc "c" (self: ^CommandQueue) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "commandBufferWithUnretainedReferences")
}
@(objc_type=CommandQueue, objc_name="device")
CommandQueue_device :: #force_inline proc "c" (self: ^CommandQueue) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CommandQueue, objc_name="insertDebugCaptureBoundary")
CommandQueue_insertDebugCaptureBoundary :: #force_inline proc "c" (self: ^CommandQueue) {
	msgSend(nil, self, "insertDebugCaptureBoundary")
}
@(objc_type=CommandQueue, objc_name="label")
CommandQueue_label :: #force_inline proc "c" (self: ^CommandQueue) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandQueue, objc_name="setLabel")
CommandQueue_setLabel :: #force_inline proc "c" (self: ^CommandQueue, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLComputeCommandEncoder")
ComputeCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroups")
ComputeCommandEncoder_dispatchThreadgroups :: #force_inline proc "c" (self: ^ComputeCommandEncoder, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroupsWithIndirectBuffer")
ComputeCommandEncoder_dispatchThreadgroupsWithIndirectBuffer :: #force_inline proc "c" (self: ^ComputeCommandEncoder, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:", indirectBuffer, indirectBufferOffset, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreads")
ComputeCommandEncoder_dispatchThreads :: #force_inline proc "c" (self: ^ComputeCommandEncoder, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchType")
ComputeCommandEncoder_dispatchType :: #force_inline proc "c" (self: ^ComputeCommandEncoder) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBuffer")
ComputeCommandEncoder_executeCommandsInBuffer :: #force_inline proc "c" (self: ^ComputeCommandEncoder, indirectCommandbuffer: ^Buffer, indirectRangeBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBufferWithRange")
ComputeCommandEncoder_executeCommandsInBufferWithRange :: #force_inline proc "c" (self: ^ComputeCommandEncoder, indirectCommandBuffer: ^Buffer, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithResources")
ComputeCommandEncoder_memoryBarrierWithResources :: #force_inline proc "c" (self: ^ComputeCommandEncoder, resources: []^Resource) {
	msgSend(nil, self, "memoryBarrierWithResources:count:", raw_data(resources), NS.UInteger(len(resources)))
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithScope")
ComputeCommandEncoder_memoryBarrierWithScope :: #force_inline proc "c" (self: ^ComputeCommandEncoder, scope: BarrierScope) {
	msgSend(nil, self, "memoryBarrierWithScope:", scope)
}
@(objc_type=ComputeCommandEncoder, objc_name="sampleCountersInBuffer")
ComputeCommandEncoder_sampleCountersInBuffer :: #force_inline proc "c" (self: ^ComputeCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=ComputeCommandEncoder, objc_name="setAccelerationStructure")
ComputeCommandEncoder_setAccelerationStructure :: #force_inline proc "c" (self: ^ComputeCommandEncoder, accelerationStructure: ^AccelerationStructure, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setAccelerationStructure:atBufferIndex:", accelerationStructure, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffer")
ComputeCommandEncoder_setBuffer :: #force_inline proc "c" (self: ^ComputeCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBufferOffset")
ComputeCommandEncoder_setBufferOffset :: #force_inline proc "c" (self: ^ComputeCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBufferOffset:atIndex:", offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffers")
ComputeCommandEncoder_setBuffers :: #force_inline proc "odin" (self: ^ComputeCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	assert(range.length <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBytes")
ComputeCommandEncoder_setBytes :: #force_inline proc "c" (self: ^ComputeCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setComputePipelineState")
ComputeCommandEncoder_setComputePipelineState :: #force_inline proc "c" (self: ^ComputeCommandEncoder, pipelineState: ^ComputePipelineState) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=ComputeCommandEncoder, objc_name="setImageblockWidth")
ComputeCommandEncoder_setImageblockWidth :: #force_inline proc "c" (self: ^ComputeCommandEncoder, width: NS.UInteger, height: NS.UInteger) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTable")
ComputeCommandEncoder_setIntersectionFunctionTable :: #force_inline proc "c" (self: ^ComputeCommandEncoder, intersectionFunctionTable: ^IntersectionFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTable:atBufferIndex:", intersectionFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTables")
ComputeCommandEncoder_setIntersectionFunctionTables :: #force_inline proc "odin" (self: ^ComputeCommandEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withBufferRange:", raw_data(intersectionFunctionTables), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerState")
ComputeCommandEncoder_setSamplerState :: #force_inline proc "c" (self: ^ComputeCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStateWithLod")
ComputeCommandEncoder_setSamplerState_lodMinClamp_lodMaxClamp :: #force_inline proc "c" (self: ^ComputeCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStatesWithLod")
ComputeCommandEncoder_setSamplerStatesWithLod :: #force_inline proc "c" (self: ^ComputeCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStatesWithRange")
ComputeCommandEncoder_setSamplerStatesWithRange :: #force_inline proc "c" (self: ^ComputeCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegion")
ComputeCommandEncoder_setStageInRegion :: #force_inline proc "c" (self: ^ComputeCommandEncoder, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegionWithIndirectBuffer")
ComputeCommandEncoder_setStageInRegionWithIndirectBuffer :: #force_inline proc "c" (self: ^ComputeCommandEncoder, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setStageInRegionWithIndirectBuffer:indirectBufferOffset:", indirectBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTexture")
ComputeCommandEncoder_setTexture :: #force_inline proc "c" (self: ^ComputeCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTextures")
ComputeCommandEncoder_setTextures :: #force_inline proc "c" (self: ^ComputeCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setThreadgroupMemoryLength")
ComputeCommandEncoder_setThreadgroupMemoryLength :: #force_inline proc "c" (self: ^ComputeCommandEncoder, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:atIndex:", length, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTable")
ComputeCommandEncoder_setVisibleFunctionTable :: #force_inline proc "c" (self: ^ComputeCommandEncoder, visibleFunctionTable: ^VisibleFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTables")
ComputeCommandEncoder_setVisibleFunctionTables :: #force_inline proc "c" (self: ^ComputeCommandEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", raw_data(visibleFunctionTables), range)
}
@(objc_type=ComputeCommandEncoder, objc_name="updateFence")
ComputeCommandEncoder_updateFence :: #force_inline proc "c" (self: ^ComputeCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeap")
ComputeCommandEncoder_useHeap :: #force_inline proc "c" (self: ^ComputeCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeaps")
ComputeCommandEncoder_useHeaps :: #force_inline proc "c" (self: ^ComputeCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}
@(objc_type=ComputeCommandEncoder, objc_name="useResource")
ComputeCommandEncoder_useResource :: #force_inline proc "c" (self: ^ComputeCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="useResources")
ComputeCommandEncoder_useResources :: #force_inline proc "c" (self: ^ComputeCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="waitForFence")
ComputeCommandEncoder_waitForFence :: #force_inline proc "c" (self: ^ComputeCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLComputePipelineState")
ComputePipelineState :: struct { using _: NS.Object }

@(objc_type=ComputePipelineState, objc_name="device")
ComputePipelineState_device :: #force_inline proc "c" (self: ^ComputePipelineState) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=ComputePipelineState, objc_name="functionHandleWithFunction")
ComputePipelineState_functionHandleWithFunction :: #force_inline proc "c" (self: ^ComputePipelineState, function: ^Function) -> ^FunctionHandle {
	return msgSend(^FunctionHandle, self, "functionHandleWithFunction:", function)
}
@(objc_type=ComputePipelineState, objc_name="imageblockMemoryLengthForDimensions")
ComputePipelineState_imageblockMemoryLengthForDimensions :: #force_inline proc "c" (self: ^ComputePipelineState, imageblockDimensions: Size) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=ComputePipelineState, objc_name="label")
ComputePipelineState_label :: #force_inline proc "c" (self: ^ComputePipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineState, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineState_maxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineState, objc_name="newComputePipelineState")
ComputePipelineState_newComputePipelineState :: #force_inline proc "contextless" (self: ^ComputePipelineState, functions: ^NS.Array) -> (state: ^ComputePipelineState, error: ^NS.Error) {
	state = msgSend(^ComputePipelineState, self, "newComputePipelineStateWithAdditionalBinaryFunctions:error:", functions, &error)
	return
}
@(objc_type=ComputePipelineState, objc_name="newIntersectionFunctionTable")
ComputePipelineState_newIntersectionFunctionTable :: #force_inline proc "c" (self: ^ComputePipelineState, descriptor: ^IntersectionFunctionTableDescriptor) -> ^IntersectionFunctionTable {
	return msgSend(^IntersectionFunctionTable, self, "newIntersectionFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="newVisibleFunctionTable")
ComputePipelineState_newVisibleFunctionTable :: #force_inline proc "c" (self: ^ComputePipelineState, descriptor: ^VisibleFunctionTableDescriptor) -> ^VisibleFunctionTable {
	return msgSend(^VisibleFunctionTable, self, "newVisibleFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="staticThreadgroupMemoryLength")
ComputePipelineState_staticThreadgroupMemoryLength :: #force_inline proc "c" (self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "staticThreadgroupMemoryLength")
}
@(objc_type=ComputePipelineState, objc_name="supportIndirectCommandBuffers")
ComputePipelineState_supportIndirectCommandBuffers :: #force_inline proc "c" (self: ^ComputePipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineState, objc_name="threadExecutionWidth")
ComputePipelineState_threadExecutionWidth :: #force_inline proc "c" (self: ^ComputePipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "threadExecutionWidth")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCounter")
Counter :: struct { using _: NS.Object }

@(objc_type=Counter, objc_name="name")
Counter_name :: #force_inline proc "c" (self: ^Counter) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCounterSampleBuffer")
CounterSampleBuffer :: struct { using _: NS.Object }

@(objc_type=CounterSampleBuffer, objc_name="device")
CounterSampleBuffer_device :: #force_inline proc "c" (self: ^CounterSampleBuffer) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=CounterSampleBuffer, objc_name="label")
CounterSampleBuffer_label :: #force_inline proc "c" (self: ^CounterSampleBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBuffer, objc_name="resolveCounterRange")
CounterSampleBuffer_resolveCounterRange :: #force_inline proc "c" (self: ^CounterSampleBuffer, range: NS.Range) -> ^NS.Data {
	return msgSend(^NS.Data, self, "resolveCounterRange:", range)
}
@(objc_type=CounterSampleBuffer, objc_name="sampleCount")
CounterSampleBuffer_sampleCount :: #force_inline proc "c" (self: ^CounterSampleBuffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLCounterSet")
CounterSet :: struct { using _: NS.Object }

@(objc_type=CounterSet, objc_name="counters")
CounterSet_counters :: #force_inline proc "c" (self: ^CounterSet) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counters")
}
@(objc_type=CounterSet, objc_name="name")
CounterSet_name :: #force_inline proc "c" (self: ^CounterSet) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLDepthStencilState")
DepthStencilState :: struct { using _: NS.Object }

@(objc_type=DepthStencilState, objc_name="device")
DepthStencilState_device :: #force_inline proc "c" (self: ^DepthStencilState) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=DepthStencilState, objc_name="label")
DepthStencilState_label :: #force_inline proc "c" (self: ^DepthStencilState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLDevice")
Device :: struct { using _: NS.Object }

@(objc_type=Device, objc_name="accelerationStructureSizesWithDescriptor")
Device_accelerationStructureSizesWithDescriptor :: #force_inline proc "c" (self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> AccelerationStructureSizes {
	return msgSend(AccelerationStructureSizes, self, "accelerationStructureSizesWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="areBarycentricCoordsSupported")
Device_areBarycentricCoordsSupported :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areBarycentricCoordsSupported")
}
@(objc_type=Device, objc_name="areProgrammableSamplePositionsSupported")
Device_areProgrammableSamplePositionsSupported :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areProgrammableSamplePositionsSupported")
}
@(objc_type=Device, objc_name="areRasterOrderGroupsSupported")
Device_areRasterOrderGroupsSupported :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areRasterOrderGroupsSupported")
}
@(objc_type=Device, objc_name="argumentBuffersSupport")
Device_argumentBuffersSupport :: #force_inline proc "c" (self: ^Device) -> ArgumentBuffersTier {
	return msgSend(ArgumentBuffersTier, self, "argumentBuffersSupport")
}
@(objc_type=Device, objc_name="convertSparsePixelRegions")
Device_convertSparsePixelRegions :: #force_inline proc "c" (self: ^Device, pixelRegions, tileRegions: ^Region, tileSize: Size, mode: SparseTextureRegionAlignmentMode, numRegions: NS.UInteger) {
	msgSend(nil, self, "convertSparsePixelRegions:toTileRegions:withTileSize:alignmentMode:numRegions:", pixelRegions, tileRegions, tileSize, mode, numRegions)
}
@(objc_type=Device, objc_name="convertSparseTileRegions")
Device_convertSparseTileRegions :: #force_inline proc "c" (self: ^Device, tileRegions, pixelRegions: ^Region, tileSize: Size, numRegions: NS.UInteger) {
	msgSend(nil, self, "convertSparseTileRegions:toPixelRegions:withTileSize:numRegions:", tileRegions, pixelRegions, tileSize, numRegions)
}
@(objc_type=Device, objc_name="counterSets")
Device_counterSets :: #force_inline proc "c" (self: ^Device) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counterSets")
}
@(objc_type=Device, objc_name="currentAllocatedSize")
Device_currentAllocatedSize :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "currentAllocatedSize")
}
@(objc_type=Device, objc_name="getDefaultSamplePositions")
Device_getDefaultSamplePositions :: #force_inline proc "c" (self: ^Device, positions: []SamplePosition) {
	msgSend(nil, self, "getDefaultSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}
@(objc_type=Device, objc_name="hasUnifiedMemory")
Device_hasUnifiedMemory :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "hasUnifiedMemory")
}
@(objc_type=Device, objc_name="heapBufferSizeAndAlignWithLength")
Device_heapBufferSizeAndAlignWithLength :: #force_inline proc "c" (self: ^Device, length: NS.UInteger, options: ResourceOptions) -> (size, align: NS.UInteger) {
	res := msgSend(SizeAndAlign, self, "heapBufferSizeAndAlignWithLength:options:", length, options)
	return res.size, res.align
}
@(objc_type=Device, objc_name="heapTextureSizeAndAlignWithDescriptor")
Device_heapTextureSizeAndAlignWithDescriptor :: #force_inline proc "c" (self: ^Device, desc: ^TextureDescriptor) -> (size, align: NS.UInteger) {
	res := msgSend(SizeAndAlign, self, "heapTextureSizeAndAlignWithDescriptor:", desc)
	return res.size, res.align
}
@(objc_type=Device, objc_name="isDepth24Stencil8PixelFormatSupported")
Device_isDepth24Stencil8PixelFormatSupported :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isDepth24Stencil8PixelFormatSupported")
}
@(objc_type=Device, objc_name="isHeadless")
Device_isHeadless :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isHeadless")
}
@(objc_type=Device, objc_name="isLowPower")
Device_isLowPower :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isLowPower")
}
@(objc_type=Device, objc_name="isRemovable")
Device_isRemovable :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isRemovable")
}
@(objc_type=Device, objc_name="location")
Device_location :: #force_inline proc "c" (self: ^Device) -> DeviceLocation {
	return msgSend(DeviceLocation, self, "location")
}
@(objc_type=Device, objc_name="locationNumber")
Device_locationNumber :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "locationNumber")
}
@(objc_type=Device, objc_name="maxArgumentBufferSamplerCount")
Device_maxArgumentBufferSamplerCount :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxArgumentBufferSamplerCount")
}
@(objc_type=Device, objc_name="maxBufferLength")
Device_maxBufferLength :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxBufferLength")
}
@(objc_type=Device, objc_name="maxThreadgroupMemoryLength")
Device_maxThreadgroupMemoryLength :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxThreadgroupMemoryLength")
}
@(objc_type=Device, objc_name="maxThreadsPerThreadgroup")
Device_maxThreadsPerThreadgroup :: #force_inline proc "c" (self: ^Device) -> Size {
	return msgSend(Size, self, "maxThreadsPerThreadgroup")
}
@(objc_type=Device, objc_name="maxTransferRate")
Device_maxTransferRate :: #force_inline proc "c" (self: ^Device) -> u64 {
	return msgSend(u64, self, "maxTransferRate")
}
@(objc_type=Device, objc_name="minimumLinearTextureAlignmentForPixelFormat")
Device_minimumLinearTextureAlignmentForPixelFormat :: #force_inline proc "c" (self: ^Device, format: PixelFormat) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "minimumLinearTextureAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="minimumTextureBufferAlignmentForPixelFormat")
Device_minimumTextureBufferAlignmentForPixelFormat :: #force_inline proc "c" (self: ^Device, format: PixelFormat) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "minimumTextureBufferAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="name")
Device_name :: #force_inline proc "c" (self: ^Device) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Device, objc_name="newAccelerationStructureWithDescriptor")
Device_newAccelerationStructureWithDescriptor :: #force_inline proc "c" (self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newAccelerationStructureWithSize")
Device_newAccelerationStructureWithSize :: #force_inline proc "c" (self: ^Device, size: NS.UInteger) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithSize:", size)
}
@(objc_type=Device, objc_name="newArgumentEncoderWithArguments")
Device_newArgumentEncoderWithArguments :: #force_inline proc "c" (self: ^Device, arguments: ^NS.Array) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderWithArguments:", arguments)
}
@(objc_type=Device, objc_name="newBinaryArchive")
Device_newBinaryArchive :: #force_inline proc "contextless" (self: ^Device, descriptor: ^BinaryArchiveDescriptor) -> (res: ^BinaryArchive, error: ^NS.Error) {
	res = msgSend(^BinaryArchive, self, "newBinaryArchiveWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newBufferWithBytes")
Device_newBufferWithBytes :: #force_inline proc "c" (self: ^Device, bytes: []byte, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytes:length:options:", raw_data(bytes), NS.UInteger(len(bytes)), options)
}
@(objc_type=Device, objc_name="newBufferWithBytesNoCopy")
Device_newBufferWithBytesNoCopy :: #force_inline proc "c" (self: ^Device, bytes: []byte, options: ResourceOptions, deallocator: rawptr) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytesNoCopy:length:options:deallocator:", raw_data(bytes), NS.UInteger(len(bytes)), options, deallocator)
}
@(objc_type=Device, objc_name="newBufferWithSlice")
Device_newBufferWithSlice :: #force_inline proc "c" (self: ^Device, slice: $S/[]$E, options: ResourceOptions) -> ^Buffer {
	return Device_newBufferWithBytes(self, mem.slice_to_bytes(slice), options)
}
@(objc_type=Device, objc_name="newBufferWithSliceNoCopy")
Device_newBufferWithSliceNoCopy :: #force_inline proc "c" (self: ^Device, slice: $S/[]$E, options: ResourceOptions, deallocator: rawptr) -> ^Buffer {
	return Device_newBufferWithBytesNotCopy(self, mem.slice_to_bytes(slice), options, deallocator)
}
@(objc_type=Device, objc_name="newBufferWithLength")
Device_newBufferWithLength :: #force_inline proc "c" (self: ^Device, length: NS.UInteger, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithLength:options:", length, options)
}

@(objc_type=Device, objc_name="newBuffer")
Device_newBuffer :: proc{
	Device_newBufferWithBytes,
	Device_newBufferWithBytesNoCopy,
	Device_newBufferWithSlice,
	Device_newBufferWithSliceNoCopy,
	Device_newBufferWithLength,
}

@(objc_type=Device, objc_name="newCommandQueue")
Device_newCommandQueue :: #force_inline proc "c" (self: ^Device) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "newCommandQueue")
}
@(objc_type=Device, objc_name="newCommandQueueWithMaxCommandBufferCount")
Device_newCommandQueueWithMaxCommandBufferCount :: #force_inline proc "c" (self: ^Device, maxCommandBufferCount: NS.UInteger) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "newCommandQueueWithMaxCommandBufferCount:", maxCommandBufferCount)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptorWithCompletionHandler")
Device_newComputePipelineStateWithDescriptorWithCompletionHandler :: #force_inline proc "c" (self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newComputePipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptorWithReflection")
Device_newComputePipelineStateWithDescriptorWithReflection :: #force_inline proc "contextless" (self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection) -> (res: ^ComputePipelineState, error: ^NS.Error) {
	res = msgSend(^ComputePipelineState, self, "newComputePipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithCompletionHandler")
Device_newComputePipelineStateWithFunctionWithCompletionHandler :: #force_inline proc "c" (self: ^Device, computeFunction: ^Function, completionHandler: NewComputePipelineStateCompletionHandler) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newComputePipelineStateWithFunction:completionHandler:", computeFunction, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction")
Device_newComputePipelineStateWithFunction :: #force_inline proc "contextless" (self: ^Device, computeFunction: ^Function) -> (res: ^ComputePipelineState, error: ^NS.Error) {
	res = msgSend(^ComputePipelineState, self, "newComputePipelineStateWithFunction:error:", computeFunction, &error)
	return
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithOptionsAndCompletionHandler")
Device_newComputePipelineStateWithFunctionWithOptionsAndCompletionHandler :: #force_inline proc "c" (self: ^Device, computeFunction: ^Function, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) -> (res: ^ComputePipelineState) {
	return msgSend(^ComputePipelineState, self, "newComputePipelineStateWithFunction:options:completionHandler:", computeFunction, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunctionWithReflection")
Device_newComputePipelineStateWithFunctionWithReflection :: #force_inline proc "contextless" (self: ^Device, computeFunction: ^Function, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection) -> (res: ^ComputePipelineState, error: ^NS.Error) {
	res = msgSend(^ComputePipelineState, self, "newComputePipelineStateWithFunction:options:reflection:error:", computeFunction, options, reflection, &error)
	return
}

@(objc_type=Device, objc_name="newComputePipelineState")
Device_newComputePipelineState :: proc{
	Device_newComputePipelineStateWithDescriptorWithCompletionHandler,
	Device_newComputePipelineStateWithDescriptorWithReflection,
	Device_newComputePipelineStateWithFunctionWithCompletionHandler,
	Device_newComputePipelineStateWithFunction,
	Device_newComputePipelineStateWithFunctionWithOptionsAndCompletionHandler,
	Device_newComputePipelineStateWithFunctionWithReflection,
}

@(objc_type=Device, objc_name="newCounterSampleBuffer")
Device_newCounterSampleBuffer :: #force_inline proc "contextless" (self: ^Device, descriptor: ^CounterSampleBufferDescriptor) -> (counter: ^Counter, error: ^NS.Error) {
	counter = msgSend(^Counter, self, "newCounterSampleBufferWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newDefaultLibrary")
Device_newDefaultLibrary :: #force_inline proc "c" (self: ^Device) -> ^Library {
	return msgSend(^Library, self, "newDefaultLibrary")
}
@(objc_type=Device, objc_name="newDefaultLibraryWithBundle")
Device_newDefaultLibraryWithBundle :: #force_inline proc "contextless" (self: ^Device, bundle: ^NS.Bundle) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newDefaultLibraryWithBundle:error:", bundle, &error)
	return
}
@(objc_type=Device, objc_name="newDepthStencilState")
Device_newDepthStencilState :: #force_inline proc "c" (self: ^Device, descriptor: ^DepthStencilDescriptor) -> ^DepthStencilState {
	return msgSend(^DepthStencilState, self, "newDepthStencilStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newDynamicLibrary")
Device_newDynamicLibrary :: #force_inline proc "contextless" (self: ^Device, library: ^Library) -> (dyn_library: ^DynamicLibrary, error: ^NS.Error) {
	dyn_library = msgSend(^DynamicLibrary, self, "newDynamicLibrary:error:", library, &error)
	return
}
@(objc_type=Device, objc_name="newDynamicLibraryWithURL")
Device_newDynamicLibraryWithURL :: #force_inline proc "contextless" (self: ^Device, url: ^NS.URL) -> (dyn_library: ^DynamicLibrary, error: ^NS.Error) {
	dyn_library = msgSend(^DynamicLibrary, self, "newDynamicLibraryWithURL:error:", url, &error)
	return
}
@(objc_type=Device, objc_name="newEvent")
Device_newEvent :: #force_inline proc "c" (self: ^Device) -> ^Event {
	return msgSend(^Event, self, "newEvent")
}
@(objc_type=Device, objc_name="newFence")
Device_newFence :: #force_inline proc "c" (self: ^Device) -> ^Fence {
	return msgSend(^Fence, self, "newFence")
}
@(objc_type=Device, objc_name="newHeap")
Device_newHeap :: #force_inline proc "c" (self: ^Device, descriptor: ^HeapDescriptor) -> ^Heap {
	return msgSend(^Heap, self, "newHeapWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newIndirectCommandBuffer")
Device_newIndirectCommandBuffer :: #force_inline proc "c" (self: ^Device, descriptor: ^IndirectCommandBufferDescriptor, maxCount: NS.UInteger, options: ResourceOptions) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "newIndirectCommandBufferWithDescriptor:maxCommandCount:options:", descriptor, maxCount, options)
}

@(objc_type=Device, objc_name="newLibraryWithData")
Device_newLibraryWithData :: #force_inline proc "contextless" (self: ^Device, data: dispatch_data_t) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithData:error:", data, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithFile")
Device_newLibraryWithFile :: #force_inline proc "contextless" (self: ^Device, filepath: ^NS.String) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithFile:error:", filepath, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithSourceWithCompletionHandler")
Device_newLibraryWithSourceWithCompletionHandler :: #force_inline proc "c" (self: ^Device, source: ^NS.String, options: ^CompileOptions, completionHandler: NewLibraryCompletionHandler) -> ^Library {
	return msgSend(^Library, self, "newLibraryWithSource:options:completionHandler:", source, options, completionHandler)
}
@(objc_type=Device, objc_name="newLibraryWithSource")
Device_newLibraryWithSource :: #force_inline proc "contextless" (self: ^Device, source: ^NS.String, options: ^CompileOptions) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithSource:options:error:", source, options, &error)
	return
}
@(objc_type=Device, objc_name="newLibraryWithURL")
Device_newLibraryWithURL :: #force_inline proc "contextless" (self: ^Device, url: ^NS.URL) -> (library: ^Library, error: ^NS.Error) {
	library = msgSend(^Library, self, "newLibraryWithURL:error:", url, &error)
	return
}
@(objc_type=Device, objc_name="newLibrary")
Device_newLibrary :: proc{
	Device_newLibraryWithData,
	Device_newLibraryWithFile,
	Device_newLibraryWithSourceWithCompletionHandler,
	Device_newLibraryWithSource,
	Device_newLibraryWithURL,
}


@(objc_type=Device, objc_name="newRasterizationRateMap")
Device_newRasterizationRateMap :: #force_inline proc "c" (self: ^Device, descriptor: ^RasterizationRateMapDescriptor) -> ^RasterizationRateMap {
	return msgSend(^RasterizationRateMap, self, "newRasterizationRateMapWithDescriptor:", descriptor)
}

@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithCompletionHandler")
Device_newRenderPipelineStateWithDescriptorWithCompletionHandler :: #force_inline proc "c" (self: ^Device, descriptor: ^RenderPipelineDescriptor, completionHandler: NewRenderPipelineStateCompletionHandler) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor")
Device_newRenderPipelineStateWithDescriptor :: #force_inline proc "contextless" (self: ^Device, descriptor: ^RenderPipelineDescriptor) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithOptionsAndCompletionHandler")
Device_newRenderPipelineStateWithDescriptorWithOptionsAndCompletionHandler :: #force_inline proc "c" (self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptorWithReflection")
Device_newRenderPipelineStateWithDescriptorWithReflection :: #force_inline proc "contextless" (self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptorWithCompletionHandler")
Device_newRenderPipelineStateWithTileDescriptorWithCompletionHandler :: #force_inline proc "c" (self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithTileDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptorWithReflection")
Device_newRenderPipelineStateWithTileDescriptorWithReflection :: #force_inline proc "contextless" (self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection) -> (pipeline: ^RenderPipelineState, error: ^NS.Error) {
	pipeline = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithTileDescriptor:options:reflection:error:", descriptor, options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineState")
Device_newRenderPipelineState :: proc{
	Device_newRenderPipelineStateWithDescriptorWithCompletionHandler,
	Device_newRenderPipelineStateWithDescriptor,
	Device_newRenderPipelineStateWithDescriptorWithOptionsAndCompletionHandler,
	Device_newRenderPipelineStateWithDescriptorWithReflection,
	Device_newRenderPipelineStateWithTileDescriptorWithCompletionHandler,
	Device_newRenderPipelineStateWithTileDescriptorWithReflection,
}


@(objc_type=Device, objc_name="newSamplerState")
Device_newSamplerState :: #force_inline proc "c" (self: ^Device, descriptor: ^SamplerDescriptor) -> ^SamplerState {
	return msgSend(^SamplerState, self, "newSamplerStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedEvent")
Device_newSharedEvent :: #force_inline proc "c" (self: ^Device) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedEvent")
}
@(objc_type=Device, objc_name="newSharedEventWithHandle")
Device_newSharedEventWithHandle :: #force_inline proc "c" (self: ^Device, sharedEventHandle: ^SharedEventHandle) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedEventWithHandle:", sharedEventHandle)
}
@(objc_type=Device, objc_name="newSharedTextureWithDescriptor")
Device_newSharedTextureWithDescriptor :: #force_inline proc "c" (self: ^Device, descriptor: ^TextureDescriptor) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedTextureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedTextureWithHandle")
Device_newSharedTextureWithHandle :: #force_inline proc "c" (self: ^Device, sharedHandle: ^SharedTextureHandle) -> ^SharedEvent {
	return msgSend(^SharedEvent, self, "newSharedTextureWithHandle:", sharedHandle)
}
@(objc_type=Device, objc_name="newSharedTexture")
Device_newSharedTexture :: proc{
	Device_newSharedTextureWithDescriptor,
	Device_newSharedTextureWithHandle,
}

@(objc_type=Device, objc_name="newTextureWithDescriptor")
Device_newTextureWithDescriptor :: #force_inline proc "c" (self: ^Device, desc: ^TextureDescriptor) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Device, objc_name="newTextureWithIOSurface")
Device_newTextureWithIOSurface :: #force_inline proc "c" (self: ^Device, descriptor: ^TextureDescriptor, iosurface: IOSurfaceRef, plane: NS.UInteger) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:iosurface:plane:", descriptor, iosurface, plane)
}
@(objc_type=Device, objc_name="newTexture")
Device_newTexture :: proc{
	Device_newTextureWithDescriptor,
	Device_newTextureWithIOSurface,
}

@(objc_type=Device, objc_name="peerCount")
Device_peerCount :: #force_inline proc "c" (self: ^Device) -> u32 {
	return msgSend(u32, self, "peerCount")
}
@(objc_type=Device, objc_name="peerGroupID")
Device_peerGroupID :: #force_inline proc "c" (self: ^Device) -> u64 {
	return msgSend(u64, self, "peerGroupID")
}
@(objc_type=Device, objc_name="peerIndex")
Device_peerIndex :: #force_inline proc "c" (self: ^Device) -> u32 {
	return msgSend(u32, self, "peerIndex")
}
@(objc_type=Device, objc_name="readWriteTextureSupport")
Device_readWriteTextureSupport :: #force_inline proc "c" (self: ^Device) -> ReadWriteTextureTier {
	return msgSend(ReadWriteTextureTier, self, "readWriteTextureSupport")
}
@(objc_type=Device, objc_name="recommendedMaxWorkingSetSize")
Device_recommendedMaxWorkingSetSize :: #force_inline proc "c" (self: ^Device) -> u64 {
	return msgSend(u64, self, "recommendedMaxWorkingSetSize")
}
@(objc_type=Device, objc_name="registryID")
Device_registryID :: #force_inline proc "c" (self: ^Device) -> u64 {
	return msgSend(u64, self, "registryID")
}
@(objc_type=Device, objc_name="sampleTimestamps")
Device_sampleTimestamps :: #force_inline proc "c" (self: ^Device, cpuTimestamp: ^Timestamp, gpuTimestamp: ^Timestamp) {
	msgSend(nil, self, "sampleTimestamps:gpuTimestamp:", cpuTimestamp, gpuTimestamp)
}
@(objc_type=Device, objc_name="sparseTileSizeInBytes")
Device_sparseTileSizeInBytes :: #force_inline proc "c" (self: ^Device) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sparseTileSizeInBytes")
}
@(objc_type=Device, objc_name="sparseTileSizeWithTextureType")
Device_sparseTileSizeWithTextureType :: #force_inline proc "c" (self: ^Device, textureType: TextureType, pixelFormat: PixelFormat, sampleCount: NS.UInteger) -> Size {
	return msgSend(Size, self, "sparseTileSizeWithTextureType:pixelFormat:sampleCount:", textureType, pixelFormat, sampleCount)
}
@(objc_type=Device, objc_name="supports32BitFloatFiltering")
Device_supports32BitFloatFiltering :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitFloatFiltering")
}
@(objc_type=Device, objc_name="supports32BitMSAA")
Device_supports32BitMSAA :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitMSAA")
}
@(objc_type=Device, objc_name="supportsBCTextureCompression")
Device_supportsBCTextureCompression :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsBCTextureCompression")
}
@(objc_type=Device, objc_name="supportsCounterSampling")
Device_supportsCounterSampling :: #force_inline proc "c" (self: ^Device, samplingPoint: CounterSamplingPoint) -> BOOL {
	return msgSend(BOOL, self, "supportsCounterSampling:", samplingPoint)
}
@(objc_type=Device, objc_name="supportsDynamicLibraries")
Device_supportsDynamicLibraries :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsDynamicLibraries")
}
@(objc_type=Device, objc_name="supportsFamily")
Device_supportsFamily :: #force_inline proc "c" (self: ^Device, gpuFamily: GPUFamily) -> BOOL {
	return msgSend(BOOL, self, "supportsFamily:", gpuFamily)
}
@(objc_type=Device, objc_name="supportsFeatureSet")
Device_supportsFeatureSet :: #force_inline proc "c" (self: ^Device, featureSet: FeatureSet) -> BOOL {
	return msgSend(BOOL, self, "supportsFeatureSet:", featureSet)
}
@(objc_type=Device, objc_name="supportsFunctionPointers")
Device_supportsFunctionPointers :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsFunctionPointers")
}
@(objc_type=Device, objc_name="supportsPullModelInterpolation")
Device_supportsPullModelInterpolation :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsPullModelInterpolation")
}
@(objc_type=Device, objc_name="supportsQueryTextureLOD")
Device_supportsQueryTextureLOD :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsQueryTextureLOD")
}
@(objc_type=Device, objc_name="supportsRasterizationRateMapWithLayerCount")
Device_supportsRasterizationRateMapWithLayerCount :: #force_inline proc "c" (self: ^Device, layerCount: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsRasterizationRateMapWithLayerCount:", layerCount)
}
@(objc_type=Device, objc_name="supportsRaytracing")
Device_supportsRaytracing :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsRaytracing")
}
@(objc_type=Device, objc_name="supportsShaderBarycentricCoordinates")
Device_supportsShaderBarycentricCoordinates :: #force_inline proc "c" (self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsShaderBarycentricCoordinates")
}
@(objc_type=Device, objc_name="supportsTextureSampleCount")
Device_supportsTextureSampleCount :: #force_inline proc "c" (self: ^Device, sampleCount: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsTextureSampleCount:", sampleCount)
}
@(objc_type=Device, objc_name="supportsVertexAmplificationCount")
Device_supportsVertexAmplificationCount :: #force_inline proc "c" (self: ^Device, count: NS.UInteger) -> BOOL {
	return msgSend(BOOL, self, "supportsVertexAmplificationCount:", count)
}


@(objc_type=Device, objc_name="newRenderPipelineStateWithMeshDescriptor")
Device_newRenderPipelineStateWithMeshDescriptor :: #force_inline proc "contextless" (self: ^Device, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection) -> (state: ^RenderPipelineState, error: ^NS.Error) {
	state = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithMeshDescriptor:options:reflection:error:", options, reflection, &error)
	return
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithMeshDescriptorAndCompletionHandler")
Device_newRenderPipelineStateWithMeshDescriptorAndCompletionHandler :: #force_inline proc "c" (self: ^Device, options: PipelineOption, completionHandler: ^NewRenderPipelineStateWithReflectionCompletionHandler) -> (state: ^RenderPipelineState) {
	state = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithMeshDescriptor:options:completionHandler:", options, completionHandler)
	return
}

@(objc_type=Device, objc_name="newIOHandle")
Device_newIOHandle :: #force_inline proc "contextless" (self: ^Device, url: ^NS.URL) -> (handle: ^IOFileHandle, err: ^NS.Error) {
	handle = msgSend(^IOFileHandle, self, "newIOHandleWithURL:error:", url, &err)
	return
}
@(objc_type=Device, objc_name="newIOHandleWithCompressionMethod")
Device_newIOHandleWithCompressionMethod :: #force_inline proc "contextless" (self: ^Device, url: ^NS.URL, compressionMethod: IOCompressionMethod) -> (handle: ^IOFileHandle, err: ^NS.Error) {
	handle = msgSend(^IOFileHandle, self, "newIOHandleWithURL:compressionMethod:error:", url, compressionMethod, &err)
	return
}
@(objc_type=Device, objc_name="newIOCommandQueue")
Device_newIOCommandQueue :: #force_inline proc "contextless" (self: ^Device, descriptor: ^IOCommandQueueDescriptor) -> (handle: ^IOCommandQueue, err: ^NS.Error) {
	handle = msgSend(^IOCommandQueue, self, "newIOCommandQueueWithDescriptor:error:", descriptor, &err)
	return
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLDrawable")
Drawable :: struct { using _: NS.Object }

@(objc_type=Drawable, objc_name="addPresentedHandler")
Drawable_addPresentedHandler :: #force_inline proc "c" (self: ^Drawable, block: DrawablePresentedHandler) {
	msgSend(nil, self, "addPresentedHandler:", block)
}
@(objc_type=Drawable, objc_name="drawableID")
Drawable_drawableID :: #force_inline proc "c" (self: ^Drawable) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "drawableID")
}
@(objc_type=Drawable, objc_name="present")
Drawable_present :: #force_inline proc "c" (self: ^Drawable) {
	msgSend(nil, self, "present")
}
@(objc_type=Drawable, objc_name="presentAfterMinimumDuration")
Drawable_presentAfterMinimumDuration :: #force_inline proc "c" (self: ^Drawable, duration: CFTimeInterval) {
	msgSend(nil, self, "presentAfterMinimumDuration:", duration)
}
@(objc_type=Drawable, objc_name="presentAtTime")
Drawable_presentAtTime :: #force_inline proc "c" (self: ^Drawable, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentAtTime:", presentationTime)
}
@(objc_type=Drawable, objc_name="presentedTime")
Drawable_presentedTime :: #force_inline proc "c" (self: ^Drawable) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "presentedTime")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLDynamicLibrary")
DynamicLibrary :: struct { using _: NS.Object }

@(objc_type=DynamicLibrary, objc_name="device")
DynamicLibrary_device :: #force_inline proc "c" (self: ^DynamicLibrary) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=DynamicLibrary, objc_name="installName")
DynamicLibrary_installName :: #force_inline proc "c" (self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=DynamicLibrary, objc_name="label")
DynamicLibrary_label :: #force_inline proc "c" (self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DynamicLibrary, objc_name="serializeToURL")
DynamicLibrary_serializeToURL :: #force_inline proc "contextless" (self: ^DynamicLibrary, url: ^NS.URL) -> (ok: BOOL, error: ^NS.Error) {
	ok = msgSend(BOOL, self, "serializeToURL:error:", url, &error)
	return
}
@(objc_type=DynamicLibrary, objc_name="setLabel")
DynamicLibrary_setLabel :: #force_inline proc "c" (self: ^DynamicLibrary, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLEvent")
Event :: struct { using _: NS.Object }

@(objc_type=Event, objc_name="device")
Event_device :: #force_inline proc "c" (self: ^Event) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Event, objc_name="label")
Event_label :: #force_inline proc "c" (self: ^Event) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Event, objc_name="setLabel")
Event_setLabel :: #force_inline proc "c" (self: ^Event, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLFence")
Fence :: struct { using _: NS.Object }

@(objc_type=Fence, objc_name="device")
Fence_device :: #force_inline proc "c" (self: ^Fence) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Fence, objc_name="label")
Fence_label :: #force_inline proc "c" (self: ^Fence) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Fence, objc_name="setLabel")
Fence_setLabel :: #force_inline proc "c" (self: ^Fence, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLFunction")
Function :: struct { using _: NS.Object }

@(objc_type=Function, objc_name="device")
Function_device :: #force_inline proc "c" (self: ^Function) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Function, objc_name="functionConstantsDictionary")
Function_functionConstantsDictionary :: #force_inline proc "c" (self: ^Function) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "functionConstantsDictionary")
}
@(objc_type=Function, objc_name="functionType")
Function_functionType :: #force_inline proc "c" (self: ^Function) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=Function, objc_name="label")
Function_label :: #force_inline proc "c" (self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Function, objc_name="name")
Function_name :: #force_inline proc "c" (self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Function, objc_name="newArgumentEncoder")
Function_newArgumentEncoder :: #force_inline proc "c" (self: ^Function, bufferIndex: NS.UInteger) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderWithBufferIndex:", bufferIndex)
}
@(objc_type=Function, objc_name="newArgumentEncoderWithReflection")
Function_newArgumentEncoderWithReflection :: #force_inline proc "c" (self: ^Function, bufferIndex: NS.UInteger, reflection: ^AutoreleasedArgument) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderWithBufferIndex:reflection:", bufferIndex, reflection)
}
@(objc_type=Function, objc_name="options")
Function_options :: #force_inline proc "c" (self: ^Function) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=Function, objc_name="patchControlPointCount")
Function_patchControlPointCount :: #force_inline proc "c" (self: ^Function) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "patchControlPointCount")
}
@(objc_type=Function, objc_name="patchType")
Function_patchType :: #force_inline proc "c" (self: ^Function) -> PatchType {
	return msgSend(PatchType, self, "patchType")
}
@(objc_type=Function, objc_name="setLabel")
Function_setLabel :: #force_inline proc "c" (self: ^Function, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Function, objc_name="stageInputAttributes")
Function_stageInputAttributes :: #force_inline proc "c" (self: ^Function) -> ^NS.Array {
	return msgSend(^NS.Array, self, "stageInputAttributes")
}
@(objc_type=Function, objc_name="vertexAttributes")
Function_vertexAttributes :: #force_inline proc "c" (self: ^Function) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexAttributes")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLFunctionHandle")
FunctionHandle :: struct { using _: NS.Object }

@(objc_type=FunctionHandle, objc_name="device")
FunctionHandle_device :: #force_inline proc "c" (self: ^FunctionHandle) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=FunctionHandle, objc_name="functionType")
FunctionHandle_functionType :: #force_inline proc "c" (self: ^FunctionHandle) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=FunctionHandle, objc_name="name")
FunctionHandle_name :: #force_inline proc "c" (self: ^FunctionHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLLogContainer")
LogContainer :: struct { using _: NS.FastEnumeration }

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLFunctionLog")
FunctionLog :: struct { using _: NS.Object }

@(objc_type=FunctionLog, objc_name="debugLocation")
FunctionLog_debugLocation :: #force_inline proc "c" (self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "debugLocation")
}
@(objc_type=FunctionLog, objc_name="encoderLabel")
FunctionLog_encoderLabel :: #force_inline proc "c" (self: ^FunctionLog) -> ^NS.String {
	return msgSend(^NS.String, self, "encoderLabel")
}
@(objc_type=FunctionLog, objc_name="function")
FunctionLog_function :: #force_inline proc "c" (self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "function")
}
@(objc_type=FunctionLog, objc_name="type")
FunctionLog_type :: #force_inline proc "c" (self: ^FunctionLog) -> FunctionLogType {
	return msgSend(FunctionLogType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLFunctionLogDebugLocation")
FunctionLogDebugLocation :: struct { using _: NS.Object }

@(objc_type=FunctionLogDebugLocation, objc_name="URL")
FunctionLogDebugLocation_URL :: #force_inline proc "c" (self: ^FunctionLogDebugLocation) -> ^NS.URL {
	return msgSend(^NS.URL, self, "URL")
}
@(objc_type=FunctionLogDebugLocation, objc_name="column")
FunctionLogDebugLocation_column :: #force_inline proc "c" (self: ^FunctionLogDebugLocation) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "column")
}
@(objc_type=FunctionLogDebugLocation, objc_name="functionName")
FunctionLogDebugLocation_functionName :: #force_inline proc "c" (self: ^FunctionLogDebugLocation) -> ^NS.String {
	return msgSend(^NS.String, self, "functionName")
}
@(objc_type=FunctionLogDebugLocation, objc_name="line")
FunctionLogDebugLocation_line :: #force_inline proc "c" (self: ^FunctionLogDebugLocation) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "line")
}

////////////////////////////////////////////////////////////////////////////////


@(objc_class="MTLHeap")
Heap :: struct { using _: NS.Object }

@(objc_type=Heap, objc_name="cpuCacheMode")
Heap_cpuCacheMode :: #force_inline proc "c" (self: ^Heap) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Heap, objc_name="currentAllocatedSize")
Heap_currentAllocatedSize :: #force_inline proc "c" (self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "currentAllocatedSize")
}
@(objc_type=Heap, objc_name="device")
Heap_device :: #force_inline proc "c" (self: ^Heap) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Heap, objc_name="hazardTrackingMode")
Heap_hazardTrackingMode :: #force_inline proc "c" (self: ^Heap) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Heap, objc_name="label")
Heap_label :: #force_inline proc "c" (self: ^Heap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Heap, objc_name="maxAvailableSizeWithAlignment")
Heap_maxAvailableSizeWithAlignment :: #force_inline proc "c" (self: ^Heap, alignment: NS.UInteger) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxAvailableSizeWithAlignment:", alignment)
}
@(objc_type=Heap, objc_name="newBufferWithLength")
Heap_newBufferWithLength :: #force_inline proc "c" (self: ^Heap, length: NS.UInteger, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithLength:options:", length, options)
}
@(objc_type=Heap, objc_name="newBufferWithOptions")
Heap_newBufferWithOptions :: #force_inline proc "c" (self: ^Heap, length: NS.UInteger, options: ResourceOptions, offset: NS.UInteger) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithLength:options:offset:", length, options, offset)
}
@(objc_type=Heap, objc_name="newBuffer")
Heap_newBuffer :: proc{
	Heap_newBufferWithLength,
	Heap_newBufferWithOptions,
}

@(objc_type=Heap, objc_name="newTextureWithDescriptor")
Heap_newTextureWithDescriptor :: #force_inline proc "c" (self: ^Heap, desc: ^TextureDescriptor) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Heap, objc_name="newTextureWithDescriptorAndOffset")
Heap_newTextureWithDescriptorAndOffset :: #force_inline proc "c" (self: ^Heap, descriptor: ^TextureDescriptor, offset: NS.UInteger) -> ^Texture {
	return msgSend(^Texture, self, "newTextureWithDescriptor:offset:", descriptor, offset)
}
@(objc_type=Heap, objc_name="newTexture")
Heap_newTexture :: proc{
	Heap_newTextureWithDescriptor,
	Heap_newTextureWithDescriptorAndOffset,
}

@(objc_type=Heap, objc_name="newAccelerationStructureWithSize")
Heap_newAccelerationStructureWithSize :: #force_inline proc "c" (self: ^Heap, size: NS.UInteger) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithSize:", size)
}
@(objc_type=Heap, objc_name="newAccelerationStructureWithDescriptor")
Heap_newAccelerationStructureWithDescriptor :: #force_inline proc "c" (self: ^Heap, descriptor: ^AccelerationStructureDescriptor) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithDescriptor:", descriptor)
}
@(objc_type=Heap, objc_name="newAccelerationStructureWithSizeAndOffset")
Heap_newAccelerationStructureWithSizeAndOffset :: #force_inline proc "c" (self: ^Heap, size, offset: NS.UInteger) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithSize:offset:", size, offset)
}
@(objc_type=Heap, objc_name="newAccelerationStructureWithDescriptorAndOffset")
Heap_newAccelerationStructureWithDescriptorAndOffset :: #force_inline proc "c" (self: ^Heap, descriptor: ^AccelerationStructureDescriptor, offset: NS.UInteger) -> ^AccelerationStructure {
	return msgSend(^AccelerationStructure, self, "newAccelerationStructureWithDescriptor:offset:", descriptor, offset)
}
@(objc_type=Heap, objc_name="newAccelerationStructure")
Heap_newAccelerationStructure :: proc{
	Heap_newAccelerationStructureWithSize,
	Heap_newAccelerationStructureWithDescriptor,
	Heap_newAccelerationStructureWithSizeAndOffset,
	Heap_newAccelerationStructureWithDescriptorAndOffset,
}

@(objc_type=Heap, objc_name="resourceOptions")
Heap_resourceOptions :: #force_inline proc "c" (self: ^Heap) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Heap, objc_name="setLabel")
Heap_setLabel :: #force_inline proc "c" (self: ^Heap, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Heap, objc_name="setPurgeableState")
Heap_setPurgeableState :: #force_inline proc "c" (self: ^Heap, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Heap, objc_name="size")
Heap_size :: #force_inline proc "c" (self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}
@(objc_type=Heap, objc_name="storageMode")
Heap_storageMode :: #force_inline proc "c" (self: ^Heap) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=Heap, objc_name="type")
Heap_type :: #force_inline proc "c" (self: ^Heap) -> FunctionLogType {
	return msgSend(FunctionLogType, self, "type")
}
@(objc_type=Heap, objc_name="usedSize")
Heap_usedSize :: #force_inline proc "c" (self: ^Heap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "usedSize")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIndirectCommandBuffer")
IndirectCommandBuffer :: struct { using _: Resource }

@(objc_type=IndirectCommandBuffer, objc_name="indirectComputeCommand")
IndirectCommandBuffer_indirectComputeCommand :: #force_inline proc "c" (self: ^IndirectCommandBuffer, commandIndex: NS.UInteger) -> ^IndirectComputeCommand {
	return msgSend(^IndirectComputeCommand, self, "indirectComputeCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="indirectRenderCommand")
IndirectCommandBuffer_indirectRenderCommand :: #force_inline proc "c" (self: ^IndirectCommandBuffer, commandIndex: NS.UInteger) -> ^IndirectRenderCommand {
	return msgSend(^IndirectRenderCommand, self, "indirectRenderCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="resetWithRange")
IndirectCommandBuffer_resetWithRange :: #force_inline proc "c" (self: ^IndirectCommandBuffer, range: NS.Range) {
	msgSend(nil, self, "resetWithRange:", range)
}
@(objc_type=IndirectCommandBuffer, objc_name="size")
IndirectCommandBuffer_size :: #force_inline proc "c" (self: ^IndirectCommandBuffer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "size")
}

@(objc_type=IndirectCommandBuffer, objc_name="supportRayTracing")
IndirectCommandBuffer_supportRayTracing :: #force_inline proc "c" (self: ^IndirectCommandBuffer) -> BOOL {
	return msgSend(BOOL, self, "supportRayTracing")
}
@(objc_type=IndirectCommandBuffer, objc_name="setSupportRayTracing")
IndirectCommandBuffer_setSupportRayTracing :: #force_inline proc "c" (self: ^IndirectCommandBuffer, supportRayTracing: BOOL) {
	msgSend(nil, self, "setSupportRayTracing:", supportRayTracing)
}

@(objc_type=IndirectCommandBuffer, objc_name="gpuResourceID")
IndirectCommandBuffer_gpuResourceID :: #force_inline proc "c" (self: ^IndirectCommandBuffer) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}


////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIndirectComputeCommand")
IndirectComputeCommand :: struct { using _: NS.Object }

@(objc_type=IndirectComputeCommand, objc_name="clearBarrier")
IndirectComputeCommand_clearBarrier :: #force_inline proc "c" (self: ^IndirectComputeCommand) {
	msgSend(nil, self, "clearBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreadgroups")
IndirectComputeCommand_concurrentDispatchThreadgroups :: #force_inline proc "c" (self: ^IndirectComputeCommand, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreads")
IndirectComputeCommand_concurrentDispatchThreads :: #force_inline proc "c" (self: ^IndirectComputeCommand, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="reset")
IndirectComputeCommand_reset :: #force_inline proc "c" (self: ^IndirectComputeCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectComputeCommand, objc_name="setBarrier")
IndirectComputeCommand_setBarrier :: #force_inline proc "c" (self: ^IndirectComputeCommand) {
	msgSend(nil, self, "setBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="setComputePipelineState")
IndirectComputeCommand_setComputePipelineState :: #force_inline proc "c" (self: ^IndirectComputeCommand, pipelineState: ^ComputePipelineState) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=IndirectComputeCommand, objc_name="setImageblockWidth")
IndirectComputeCommand_setImageblockWidth :: #force_inline proc "c" (self: ^IndirectComputeCommand, width: NS.UInteger, height: NS.UInteger) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=IndirectComputeCommand, objc_name="setKernelBuffer")
IndirectComputeCommand_setKernelBuffer :: #force_inline proc "c" (self: ^IndirectComputeCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setKernelBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectComputeCommand, objc_name="setStageInRegion")
IndirectComputeCommand_setStageInRegion :: #force_inline proc "c" (self: ^IndirectComputeCommand, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=IndirectComputeCommand, objc_name="setThreadgroupMemoryLength")
IndirectComputeCommand_setThreadgroupMemoryLength :: #force_inline proc "c" (self: ^IndirectComputeCommand, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:atIndex:", length, index)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIndirectRenderCommand")
IndirectRenderCommand :: struct { using _: NS.Object }

@(objc_type=IndirectRenderCommand, objc_name="drawIndexedPatches")
IndirectRenderCommand_drawIndexedPatches :: #force_inline proc "c" (self: ^IndirectRenderCommand, numberOfPatchControlPoints: NS.UInteger, patchStart, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawIndexedPrimitives")
IndirectRenderCommand_drawIndexedPrimitives :: #force_inline proc "c" (self: ^IndirectRenderCommand, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseVertex: NS.Integer, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPatches")
IndirectRenderCommand_drawPatches :: #force_inline proc "c" (self: ^IndirectRenderCommand, numberOfPatchControlPoints: NS.UInteger, patchStart, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPrimitives")
IndirectRenderCommand_drawPrimitives :: #force_inline proc "c" (self: ^IndirectRenderCommand, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger = 0) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="reset")
IndirectRenderCommand_reset :: #force_inline proc "c" (self: ^IndirectRenderCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectRenderCommand, objc_name="setFragmentBuffer")
IndirectRenderCommand_setFragmentBuffer :: #force_inline proc "c" (self: ^IndirectRenderCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectRenderCommand, objc_name="setRenderPipelineState")
IndirectRenderCommand_setRenderPipelineState :: #force_inline proc "c" (self: ^IndirectRenderCommand, pipelineState: ^RenderPipelineState) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=IndirectRenderCommand, objc_name="setVertexBuffer")
IndirectRenderCommand_setVertexBuffer :: #force_inline proc "c" (self: ^IndirectRenderCommand, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBuffer:offset:atIndex:", buffer, offset, index)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIntersectionFunctionTable")
IntersectionFunctionTable :: struct { using _: Resource }

@(objc_type=IntersectionFunctionTable, objc_name="setBuffer")
IntersectionFunctionTable_setBuffer :: #force_inline proc "c" (self: ^IntersectionFunctionTable, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setBuffers")
IntersectionFunctionTable_setBuffers :: #force_inline proc "c" (self: ^IntersectionFunctionTable, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunction")
IntersectionFunctionTable_setFunction :: #force_inline proc "c" (self: ^IntersectionFunctionTable, function: ^FunctionHandle, index: NS.UInteger) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunctions")
IntersectionFunctionTable_setFunctions :: #force_inline proc "c" (self: ^IntersectionFunctionTable, functions: []^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", raw_data(functions), range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignature")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignature :: #force_inline proc "c" (self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, index: NS.UInteger) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:atIndex:", signature, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignatureWithRange")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignatureWithRange :: #force_inline proc "c" (self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, range: NS.Range) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:withRange:", signature, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTable")
IntersectionFunctionTable_setVisibleFunctionTable :: #force_inline proc "c" (self: ^IntersectionFunctionTable, visibleFunctionTable: ^VisibleFunctionTable, bufferIndex: NS.UInteger) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTables")
IntersectionFunctionTable_setVisibleFunctionTables :: #force_inline proc "c" (self: ^IntersectionFunctionTable, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", raw_data(visibleFunctionTables), range)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOCommandQueue")
IOCommandQueue :: struct { using _: NS.Object }

@(objc_type=IOCommandQueue, objc_name="enqueueBarrier")
IOCommandQueue_enqueueBarrier :: #force_inline proc "c" (self: ^IOCommandQueue) {
	msgSend(nil, self, "enqueueBarrier")
}
@(objc_type=IOCommandQueue, objc_name="commandBuffer")
IOCommandQueue_commandBuffer :: #force_inline proc "c" (self: ^IOCommandQueue) -> ^IOCommandBuffer {
	return msgSend(^IOCommandBuffer, self, "commandBuffer")
}
@(objc_type=IOCommandQueue, objc_name="commandBufferWithUnretainedReferences")
IOCommandQueue_commandBufferWithUnretainedReferences :: #force_inline proc "c" (self: ^IOCommandQueue) -> ^IOCommandBuffer {
	return msgSend(^IOCommandBuffer, self, "commandBufferWithUnretainedReferences")
}
@(objc_type=IOCommandQueue, objc_name="label")
IOCommandQueue_label :: #force_inline proc "c" (self: ^IOCommandQueue) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=IOCommandQueue, objc_name="setLabel")
IOCommandQueue_setLabel :: #force_inline proc "c" (self: ^IOCommandQueue, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOScratchBuffer")
IOScratchBuffer :: struct { using _: NS.Object }

@(objc_type=IOScratchBuffer, objc_name="buffer")
IOScratchBuffer_buffer :: #force_inline proc "c" (self: ^IOCommandQueue) -> ^Buffer {
	return msgSend(^Buffer, self, "buffer")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOScratchBufferAllocator")
IOScratchBufferAllocator :: struct { using _: NS.Object }

@(objc_type=IOScratchBufferAllocator, objc_name="newScratchBuffer")
IOScratchBufferAllocator_newScratchBuffer :: #force_inline proc "c" (self: ^IOCommandQueue, minimumSize: NS.UInteger) -> ^IOScratchBuffer {
	return msgSend(^IOScratchBuffer, self, "newScratchBufferWithMinimumSize:", minimumSize)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOCommandQueueDescriptor")
IOCommandQueueDescriptor :: struct { using _: NS.Copying(IOCommandQueueDescriptor) }


@(objc_type=IOCommandQueueDescriptor, objc_name="alloc", objc_is_class_method=true)
IOCommandQueueDescriptor_alloc :: #force_inline proc "c" () -> ^IOCommandQueueDescriptor {
	return msgSend(^IOCommandQueueDescriptor, IOCommandQueueDescriptor, "alloc")
}
@(objc_type=IOCommandQueueDescriptor, objc_name="init")
IOCommandQueueDescriptor_init :: #force_inline proc "c" (self: ^IOCommandQueueDescriptor) -> ^IOCommandQueueDescriptor {
	return msgSend(^IOCommandQueueDescriptor, self, "init")
}

@(objc_type=IOCommandQueueDescriptor, objc_name="maxCommandBufferCount")
IOCommandQueueDescriptor_maxCommandBufferCount :: #force_inline proc "c" (self: ^IOCommandQueueDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxCommandBufferCount")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOFileHandle")
IOFileHandle :: struct { using _: NS.Object }

@(objc_type=IOFileHandle, objc_name="label")
IOFileHandle_label :: #force_inline proc "c" (self: ^IOFileHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=IOFileHandle, objc_name="setLabel")
IOFileHandle_setLabel :: #force_inline proc "c" (self: ^IOFileHandle, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLIOCommandBuffer")
IOCommandBuffer :: struct { using _: NS.Object }

@(objc_type=IOCommandBuffer, objc_name="addCompletedHandler")
IOCommandBuffer_addCompletedHandler :: #force_inline proc "c" (self: ^IOCommandBuffer, block: ^NS.Block) {
	msgSend(nil, self, "addCompletedHandler:", block)
}
@(objc_type=IOCommandBuffer, objc_name="loadBytes")
IOCommandBuffer_loadBytes :: #force_inline proc "c" (self: ^IOCommandBuffer, pointer: rawptr, size: NS.UInteger, sourceHandle: ^IOFileHandle, sourceHandleOffset: NS.UInteger) {
	msgSend(nil, self, "loadBytes:size:sourceHandle:sourceHandleOffset:", pointer, size, sourceHandle, sourceHandleOffset)
}
@(objc_type=IOCommandBuffer, objc_name="loadBuffer")
IOCommandBuffer_loadBuffer :: #force_inline proc "c" (self: ^IOCommandBuffer, buffer: ^Buffer, offset: NS.UInteger, size: NS.UInteger, sourceHandle: ^IOFileHandle, sourceHandleOffset: NS.UInteger) {
	msgSend(nil, self, "loadBuffer:offset:sourceHandle:sourceHandleOffset:", buffer, offset, size, sourceHandle, sourceHandleOffset)
}
@(objc_type=IOCommandBuffer, objc_name="loadTexture")
IOCommandBuffer_loadTexture :: #force_inline proc "c" (self: ^IOCommandBuffer, texture: ^Texture, slice: NS.UInteger, level, size, sourceBytesPerRow, sourceBytesPerImage: NS.UInteger, destinationOrigin: Origin, sourceHandle: ^IOFileHandle, sourceHandleOffset: NS.UInteger) {
	msgSend(nil, self, "loadTexture:slice:level:size:sourceBytesPerRow:sourceBytesPerImage:destinationOrigin:sourceHandle:sourceHandleOffset:", texture, slice, level, size, sourceBytesPerRow, sourceBytesPerImage, destinationOrigin, sourceHandle, sourceHandleOffset)
}

@(objc_type=IOCommandBuffer, objc_name="copyStatusToBuffer")
IOCommandBuffer_copyStatusToBuffer :: #force_inline proc "c" (self: ^IOCommandBuffer, buffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "copyStatusToBuffer:offset:", buffer, offset)
}

@(objc_type=IOCommandBuffer, objc_name="commit")
IOCommandBuffer_commit :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "commit")
}
@(objc_type=IOCommandBuffer, objc_name="waitUntilCompleted")
IOCommandBuffer_waitUntilCompleted :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "waitUntilCompleted")
}
@(objc_type=IOCommandBuffer, objc_name="tryCancel")
IOCommandBuffer_tryCancel :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "tryCancel")
}
@(objc_type=IOCommandBuffer, objc_name="addBarrier")
IOCommandBuffer_addBarrier :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "addBarrier")
}
@(objc_type=IOCommandBuffer, objc_name="enqueue")
IOCommandBuffer_enqueue :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "enqueue")
}
@(objc_type=IOCommandBuffer, objc_name="waitForEvent")
IOCommandBuffer_waitForEvent :: #force_inline proc "c" (self: ^IOCommandBuffer, event: ^SharedEvent, value: u64) {
	msgSend(nil, self, "waitForEvent:value", event, value)
}
@(objc_type=IOCommandBuffer, objc_name="signalEvent")
IOCommandBuffer_signalEvent :: #force_inline proc "c" (self: ^IOCommandBuffer, event: ^SharedEvent, value: u64) {
	msgSend(nil, self, "signalEvent:value", event, value)
}


@(objc_type=IOCommandBuffer, objc_name="pushDebugGroup")
IOCommandBuffer_pushDebugGroup :: #force_inline proc "c" (self: ^IOCommandBuffer, name: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", name)
}
@(objc_type=IOCommandBuffer, objc_name="popDebugGroup")
IOCommandBuffer_popDebugGroup :: #force_inline proc "c" (self: ^IOCommandBuffer) {
	msgSend(nil, self, "popDebugGroup")
}


@(objc_type=IOCommandBuffer, objc_name="label")
IOCommandBuffer_label :: #force_inline proc "c" (self: ^IOCommandBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=IOCommandBuffer, objc_name="setLabel")
IOCommandBuffer_setLabel :: #force_inline proc "c" (self: ^IOCommandBuffer, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

@(objc_type=IOCommandBuffer, objc_name="status")
IOCommandBuffer_status :: #force_inline proc "c" (self: ^IOCommandBuffer) -> IOStatus {
	return msgSend(IOStatus, self, "status")
}
@(objc_type=IOCommandBuffer, objc_name="error")
IOCommandBuffer_error :: #force_inline proc "c" (self: ^IOCommandBuffer) -> ^NS.Error {
	return msgSend(^NS.Error, self, "error")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLLibrary")
Library :: struct { using _: NS.Object }

@(objc_type=Library, objc_name="device")
Library_device :: #force_inline proc "c" (self: ^Library) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Library, objc_name="functionNames")
Library_functionNames :: #force_inline proc "c" (self: ^Library) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functionNames")
}
@(objc_type=Library, objc_name="installName")
Library_installName :: #force_inline proc "c" (self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=Library, objc_name="label")
Library_label :: #force_inline proc "c" (self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Library, objc_name="newFunctionWithCompletionHandler")
Library_newFunctionWithCompletionHandler :: #force_inline proc "c" (self: ^Library, descriptor: ^FunctionDescriptor, completionHandler: ^NS.Block) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithDescriptor")
Library_newFunctionWithDescriptor :: #force_inline proc "contextless" (self: ^Library, descriptor: ^FunctionDescriptor) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newFunctionWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Library, objc_name="newFunctionWithName")
Library_newFunctionWithName :: #force_inline proc "c" (self: ^Library, functionName: ^NS.String) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithName:", functionName)
}
@(objc_type=Library, objc_name="newFunctionWithConstantValuesAndCompletionHandler")
Library_newFunctionWithConstantValuesAndCompletionHandler :: #force_inline proc "c" (self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues, completionHandler: ^NS.Block) -> ^Function {
	return msgSend(^Function, self, "newFunctionWithName:constantValues:completionHandler:", name, constantValues, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithConstantValues")
Library_newFunctionWithConstantValues :: #force_inline proc "contextless" (self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newFunctionWithName:constantValues:error:", name, constantValues, &error)
	return
}
@(objc_type=Library, objc_name="newFunction")
Library_newFunction :: proc{
	Library_newFunctionWithCompletionHandler,
	Library_newFunctionWithDescriptor,
	Library_newFunctionWithName,
	Library_newFunctionWithConstantValuesAndCompletionHandler,
	Library_newFunctionWithConstantValues,
}

@(objc_type=Library, objc_name="newIntersectionFunctionWithCompletionHandler")
Library_newIntersectionFunctionWithCompletionHandler :: #force_inline proc "c" (self: ^Library, descriptor: ^IntersectionFunctionDescriptor, completionHandler: ^NS.Block) -> ^Function {
	return msgSend(^Function, self, "newIntersectionFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newIntersectionFunction")
Library_newIntersectionFunction :: #force_inline proc "contextless" (self: ^Library, descriptor: ^IntersectionFunctionDescriptor) -> (function: ^Function, error: ^NS.Error) {
	function = msgSend(^Function, self, "newIntersectionFunctionWithDescriptor:error:", descriptor, &error)
	return
}
@(objc_type=Library, objc_name="setLabel")
Library_setLabel :: #force_inline proc "c" (self: ^Library, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Library, objc_name="type")
Library_type :: #force_inline proc "c" (self: ^Library) -> LibraryType {
	return msgSend(LibraryType, self, "type")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLParallelRenderCommandEncoder")
ParallelRenderCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ParallelRenderCommandEncoder, objc_name="renderCommandEncoder")
ParallelRenderCommandEncoder_renderCommandEncoder :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder) -> ^RenderCommandEncoder {
	return msgSend(^RenderCommandEncoder, self, "renderCommandEncoder")
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreAction")
ParallelRenderCommandEncoder_setColorStoreAction :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreActionOptions")
ParallelRenderCommandEncoder_setColorStoreActionOptions :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreAction")
ParallelRenderCommandEncoder_setDepthStoreAction :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreActionOptions")
ParallelRenderCommandEncoder_setDepthStoreActionOptions :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreAction")
ParallelRenderCommandEncoder_setStencilStoreAction :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreActionOptions")
ParallelRenderCommandEncoder_setStencilStoreActionOptions :: #force_inline proc "c" (self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStencilStoreActionOptions:", storeActionOptions)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLRasterizationRateMap")
RasterizationRateMap :: struct { using _: NS.Object }

@(objc_type=RasterizationRateMap, objc_name="copyParameterDataToBuffer")
RasterizationRateMap_copyParameterDataToBuffer :: #force_inline proc "c" (self: ^RasterizationRateMap, buffer: ^Buffer, offset: NS.UInteger) {
	msgSend(nil, self, "copyParameterDataToBuffer:offset:", buffer, offset)
}
@(objc_type=RasterizationRateMap, objc_name="device")
RasterizationRateMap_device :: #force_inline proc "c" (self: ^RasterizationRateMap) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=RasterizationRateMap, objc_name="label")
RasterizationRateMap_label :: #force_inline proc "c" (self: ^RasterizationRateMap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMap, objc_name="layerCount")
RasterizationRateMap_layerCount :: #force_inline proc "c" (self: ^RasterizationRateMap) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "layerCount")
}
@(objc_type=RasterizationRateMap, objc_name="mapPhysicalToScreenCoordinates")
RasterizationRateMap_mapPhysicalToScreenCoordinates :: #force_inline proc "c" (self: ^RasterizationRateMap, physicalCoordinates: Coordinate2D, layerIndex: NS.UInteger) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapPhysicalToScreenCoordinates:forLayer:", physicalCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="mapScreenToPhysicalCoordinates")
RasterizationRateMap_mapScreenToPhysicalCoordinates :: #force_inline proc "c" (self: ^RasterizationRateMap, screenCoordinates: Coordinate2D, layerIndex: NS.UInteger) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapScreenToPhysicalCoordinates:forLayer:", screenCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="parameterBufferSizeAndAlign")
RasterizationRateMap_parameterBufferSizeAndAlign :: #force_inline proc "c" (self: ^RasterizationRateMap) -> (size, align: NS.UInteger) {
	res := msgSend(SizeAndAlign, self, "parameterBufferSizeAndAlign")
	return res.size, res.align
}
@(objc_type=RasterizationRateMap, objc_name="physicalGranularity")
RasterizationRateMap_physicalGranularity :: #force_inline proc "c" (self: ^RasterizationRateMap) -> Size {
	return msgSend(Size, self, "physicalGranularity")
}
@(objc_type=RasterizationRateMap, objc_name="physicalSizeForLayer")
RasterizationRateMap_physicalSizeForLayer :: #force_inline proc "c" (self: ^RasterizationRateMap, layerIndex: NS.UInteger) -> Size {
	return msgSend(Size, self, "physicalSizeForLayer:", layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="screenSize")
RasterizationRateMap_screenSize :: #force_inline proc "c" (self: ^RasterizationRateMap) -> Size {
	return msgSend(Size, self, "screenSize")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLRenderCommandEncoder")
RenderCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=RenderCommandEncoder, objc_name="dispatchThreadsPerTile")
RenderCommandEncoder_dispatchThreadsPerTile :: #force_inline proc "c" (self: ^RenderCommandEncoder, threadsPerTile: Size) {
	msgSend(nil, self, "dispatchThreadsPerTile:", threadsPerTile)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPatchesWihtIndirect")
RenderCommandEncoder_drawIndexedPatchesWihtIndirect :: #force_inline proc "c" (self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexPatchesWithInstances")
RenderCommandEncoder_drawIndexPatchesWithInstance :: #force_inline proc "c" (self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchStart, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, controlPointIndexBuffer: ^Buffer, controlPointIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives")
RenderCommandEncoder_drawIndexedPrimitives :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitivesWithInstanceCount")
RenderCommandEncoder_drawIndexedPrimitivesWithInstanceCount :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexPrimitivesWithBaseVertex")
RenderCommandEncoder_drawIndexPrimitivesWithBaseVertex :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: NS.UInteger, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseVertex: NS.Integer, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexPrimitivesWithIndirect")
RenderCommandEncoder_drawIndexPrimitivesWithIndirect :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexType: IndexType, indexBuffer: ^Buffer, indexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawIndexedPrimitives:indexType:indexBuffer:indexBufferOffset:indirectBuffer:indirectBufferOffset:", primitiveType, indexType, indexBuffer, indexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatches")
RenderCommandEncoder_drawPatches :: #force_inline proc "c" (self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchIndexBuffer:patchIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatchesWithInstances")
RenderCommandEncoder_drawPatchesWithInstance :: #force_inline proc "c" (self: ^RenderCommandEncoder, numberOfPatchControlPoints: NS.UInteger, patchStart, patchCount: NS.UInteger, patchIndexBuffer: ^Buffer, patchIndexBufferOffset: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitivesWithIndirect")
RenderCommandEncoder_drawPrimitivesWithIndirect :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:indirectBuffer:indirectBufferOffset:", primitiveType, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives")
RenderCommandEncoder_drawPrimitives :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:", primitiveType, vertexStart, vertexCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitivesWithInstanceCount")
RenderCommandEncoder_drawPrimitivesWithInstanceCount :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:", primitiveType, vertexStart, vertexCount, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitivesWithInstances")
RenderCommandEncoder_drawPrimitivesWithInstances :: #force_inline proc "c" (self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: NS.UInteger, vertexCount: NS.UInteger, instanceCount: NS.UInteger, baseInstance: NS.UInteger) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBuffer")
RenderCommandEncoder_executeCommandsInBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, indirectCommandbuffer: ^Buffer, indirectRangeBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBufferWithRange")
RenderCommandEncoder_executeCommandsInBufferWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, indirectCommandBuffer: ^Buffer, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithResources")
RenderCommandEncoder_memoryBarrierWithResources :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithResources:count:afterStages:beforeStages:", raw_data(resources), NS.UInteger(len(resources)), after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithScope")
RenderCommandEncoder_memoryBarrierWithScope :: #force_inline proc "c" (self: ^RenderCommandEncoder, scope: BarrierScope, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithScope:afterStages:beforeStages:", scope, after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="sampleCountersInBuffer")
RenderCommandEncoder_sampleCountersInBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampleBuffer: ^Buffer, sampleIndex: NS.UInteger, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=RenderCommandEncoder, objc_name="setBlendColorRed")
RenderCommandEncoder_setBlendColorRed :: #force_inline proc "c" (self: ^RenderCommandEncoder, red: f32, green: f32, blue: f32, alpha: f32) {
	msgSend(nil, self, "setBlendColorRed:green:blue:alpha:", red, green, blue, alpha)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreAction")
RenderCommandEncoder_setColorStoreAction :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreActionOptions")
RenderCommandEncoder_setColorStoreActionOptions :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: NS.UInteger) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setCullMode")
RenderCommandEncoder_setCullMode :: #force_inline proc "c" (self: ^RenderCommandEncoder, cullMode: CullMode) {
	msgSend(nil, self, "setCullMode:", cullMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthBias")
RenderCommandEncoder_setDepthBias :: #force_inline proc "c" (self: ^RenderCommandEncoder, depthBias: f32, slopeScale: f32, clamp: f32) {
	msgSend(nil, self, "setDepthBias:slopeScale:clamp:", depthBias, slopeScale, clamp)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthClipMode")
RenderCommandEncoder_setDepthClipMode :: #force_inline proc "c" (self: ^RenderCommandEncoder, depthClipMode: DepthClipMode) {
	msgSend(nil, self, "setDepthClipMode:", depthClipMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStencilState")
RenderCommandEncoder_setDepthStencilState :: #force_inline proc "c" (self: ^RenderCommandEncoder, depthStencilState: ^DepthStencilState) {
	msgSend(nil, self, "setDepthStencilState:", depthStencilState)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreAction")
RenderCommandEncoder_setDepthStoreAction :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreActionOptions")
RenderCommandEncoder_setDepthStoreActionOptions :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffer")
RenderCommandEncoder_setFragmentBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBufferOffset")
RenderCommandEncoder_setFragmentBufferOffset :: #force_inline proc "c" (self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffers")
RenderCommandEncoder_setFragmentBuffers :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setFragmentBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBytes")
RenderCommandEncoder_setFragmentBytes :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerState")
RenderCommandEncoder_setFragmentSamplerState :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStateWithLod")
RenderCommandEncoder_setFragmentSamplerStateWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStatesWithLod")
RenderCommandEncoder_setFragmentSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStatesWithRange")
RenderCommandEncoder_setFragmentSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTexture")
RenderCommandEncoder_setFragmentTexture :: #force_inline proc "c" (self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTextures")
RenderCommandEncoder_setFragmentTextures :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setFragmentTextures:withRange:", raw_data(textures), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFrontFacingWinding")
RenderCommandEncoder_setFrontFacingWinding :: #force_inline proc "c" (self: ^RenderCommandEncoder, frontFacingWinding: Winding) {
	msgSend(nil, self, "setFrontFacingWinding:", frontFacingWinding)
}
@(objc_type=RenderCommandEncoder, objc_name="setRenderPipelineState")
RenderCommandEncoder_setRenderPipelineState :: #force_inline proc "c" (self: ^RenderCommandEncoder, pipelineState: ^RenderPipelineState) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRect")
RenderCommandEncoder_setScissorRect :: #force_inline proc "c" (self: ^RenderCommandEncoder, rect: ScissorRect) {
	msgSend(nil, self, "setScissorRect:", rect)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRects")
RenderCommandEncoder_setScissorRects :: #force_inline proc "c" (self: ^RenderCommandEncoder, scissorRects: []ScissorRect) {
	msgSend(nil, self, "setScissorRects:count:", raw_data(scissorRects), NS.UInteger(len(scissorRects)))
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilFrontReferenceValue")
RenderCommandEncoder_setStencilFrontReferenceValue :: #force_inline proc "c" (self: ^RenderCommandEncoder, frontReferenceValue: u32, backReferenceValue: u32) {
	msgSend(nil, self, "setStencilFrontReferenceValue:backReferenceValue:", frontReferenceValue, backReferenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilReferenceValue")
RenderCommandEncoder_setStencilReferenceValue :: #force_inline proc "c" (self: ^RenderCommandEncoder, referenceValue: u32) {
	msgSend(nil, self, "setStencilReferenceValue:", referenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreAction")
RenderCommandEncoder_setStencilStoreAction :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreActionOptions")
RenderCommandEncoder_setStencilStoreActionOptions :: #force_inline proc "c" (self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStencilStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorBuffer")
RenderCommandEncoder_setTessellationFactorBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, instanceStride: NS.UInteger) {
	msgSend(nil, self, "setTessellationFactorBuffer:offset:instanceStride:", buffer, offset, instanceStride)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorScale")
RenderCommandEncoder_setTessellationFactorScale :: #force_inline proc "c" (self: ^RenderCommandEncoder, scale: f32) {
	msgSend(nil, self, "setTessellationFactorScale:", scale)
}
@(objc_type=RenderCommandEncoder, objc_name="setThreadgroupMemoryLength")
RenderCommandEncoder_setThreadgroupMemoryLength :: #force_inline proc "c" (self: ^RenderCommandEncoder, length: NS.UInteger, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setThreadgroupMemoryLength:offset:atIndex:", length, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffer")
RenderCommandEncoder_setTileBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setTileBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBufferOffset")
RenderCommandEncoder_setTileBufferOffset :: #force_inline proc "c" (self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setTileBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffers")
RenderCommandEncoder_setTileBuffers :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setTileBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBytes")
RenderCommandEncoder_setTileBytes :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setTileBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerState")
RenderCommandEncoder_setTileSamplerState :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setTileSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStateWithLod")
RenderCommandEncoder_setTileSamplerStateWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setTileSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStatesWithLod")
RenderCommandEncoder_setTileSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStatesWithRange")
RenderCommandEncoder_setTileSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTexture")
RenderCommandEncoder_setTileTexture :: #force_inline proc "c" (self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setTileTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTextures")
RenderCommandEncoder_setTileTextures :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setTileTextures:withRange:", raw_data(textures), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTriangleFillMode")
RenderCommandEncoder_setTriangleFillMode :: #force_inline proc "c" (self: ^RenderCommandEncoder, fillMode: TriangleFillMode) {
	msgSend(nil, self, "setTriangleFillMode:", fillMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexAmplificationCount")
RenderCommandEncoder_setVertexAmplificationCount :: #force_inline proc "c" (self: ^RenderCommandEncoder, viewMappings: []VertexAmplificationViewMapping) {
	msgSend(nil, self, "setVertexAmplificationCount:viewMappings:", NS.UInteger(len(viewMappings)), raw_data(viewMappings))
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffer")
RenderCommandEncoder_setVertexBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBufferOffset")
RenderCommandEncoder_setVertexBufferOffset :: #force_inline proc "c" (self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffers")
RenderCommandEncoder_setVertexBuffers :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setVertexBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBytes")
RenderCommandEncoder_setVertexBytes :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerState")
RenderCommandEncoder_setVertexSamplerState :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setVertexSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStateWithLod")
RenderCommandEncoder_setVertexSamplerStateWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp: f32, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setVertexSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStatesWithLod")
RenderCommandEncoder_setVertexSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStatesWithRange")
RenderCommandEncoder_setVertexSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:withRange:", raw_data(samplers), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTexture")
RenderCommandEncoder_setVertexTexture :: #force_inline proc "c" (self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setVertexTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTextures")
RenderCommandEncoder_setVertexTextures :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setVertexTextures:withRange:", raw_data(textures), range)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewport")
RenderCommandEncoder_setViewport :: #force_inline proc "c" (self: ^RenderCommandEncoder, viewport: Viewport) {
	msgSend(nil, self, "setViewport:", viewport)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewports")
RenderCommandEncoder_setViewports :: #force_inline proc "c" (self: ^RenderCommandEncoder, viewports: []Viewport) {
	msgSend(nil, self, "setViewports:count:", raw_data(viewports), NS.UInteger(len(viewports)))
}
@(objc_type=RenderCommandEncoder, objc_name="setVisibilityResultMode")
RenderCommandEncoder_setVisibilityResultMode :: #force_inline proc "c" (self: ^RenderCommandEncoder, mode: VisibilityResultMode, offset: NS.UInteger) {
	msgSend(nil, self, "setVisibilityResultMode:offset:", mode, offset)
}
@(objc_type=RenderCommandEncoder, objc_name="textureBarrier")
RenderCommandEncoder_textureBarrier :: #force_inline proc "c" (self: ^RenderCommandEncoder) {
	msgSend(nil, self, "textureBarrier")
}
@(objc_type=RenderCommandEncoder, objc_name="tileHeight")
RenderCommandEncoder_tileHeight :: #force_inline proc "c" (self: ^RenderCommandEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileHeight")
}
@(objc_type=RenderCommandEncoder, objc_name="tileWidth")
RenderCommandEncoder_tileWidth :: #force_inline proc "c" (self: ^RenderCommandEncoder) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tileWidth")
}
@(objc_type=RenderCommandEncoder, objc_name="updateFence")
RenderCommandEncoder_updateFence :: #force_inline proc "c" (self: ^RenderCommandEncoder, fence: ^Fence, stages: RenderStages) {
	msgSend(nil, self, "updateFence:afterStages:", fence, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeap")
RenderCommandEncoder_useHeap :: #force_inline proc "c" (self: ^RenderCommandEncoder, heap: ^Heap) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeapWithStages")
RenderCommandEncoder_useHeapWithStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, heap: ^Heap, stages: RenderStages) {
	msgSend(nil, self, "useHeap:stages:", heap, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeaps")
RenderCommandEncoder_useHeaps :: #force_inline proc "c" (self: ^RenderCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}
@(objc_type=RenderCommandEncoder, objc_name="useHeapsWithStages")
RenderCommandEncoder_useHeapsWithStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, heaps: []^Heap, stages: RenderStages) {
	msgSend(nil, self, "useHeaps:count:stages:", raw_data(heaps), NS.UInteger(len(heaps)), stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResource")
RenderCommandEncoder_useResource :: #force_inline proc "c" (self: ^RenderCommandEncoder, resource: ^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResourceWithStages")
RenderCommandEncoder_useResourceWithStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, resource: ^Resource, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResource:usage:stages:", resource, usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResources")
RenderCommandEncoder_useResources :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResourcesStages")
RenderCommandEncoder_useResourcesStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResources:count:usage:stages:", raw_data(resources), NS.UInteger(len(resources)), usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="waitForFence")
RenderCommandEncoder_waitForFence :: #force_inline proc "c" (self: ^RenderCommandEncoder, fence: ^Fence, stages: RenderStages) {
	msgSend(nil, self, "waitForFence:beforeStages:", fence, stages)
}

@(objc_type=RenderCommandEncoder, objc_name="setObjectBytes")
RenderCommandEncoder_setObjectBytes :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setObjectBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectBuffer")
RenderCommandEncoder_setObjectBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setObjectBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectBufferOffset")
RenderCommandEncoder_setObjectBufferOffset :: #force_inline proc "c" (self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setObjectBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectBuffers")
RenderCommandEncoder_setObjectBuffers :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setObjectBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectTexture")
RenderCommandEncoder_setObjectTexture :: #force_inline proc "c" (self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setObjectTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectTextures")
RenderCommandEncoder_setObjectTextures :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: [^]^Texture, range: NS.Range) {
	msgSend(nil, self, "setObjectTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectSamplerState")
RenderCommandEncoder_setObjectSamplerState :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setObjectSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectSamplerStates")
RenderCommandEncoder_setObjectSamplerStates :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: [^]^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setObjectSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectSamplerStateWithLod")
RenderCommandEncoder_setObjectSamplerStateWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setObjectSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setObjectSamplerStatesWithLod")
RenderCommandEncoder_setObjectSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: [^]^SamplerState, lodMinClamps, lodMaxClamps: [^]f32, range: NS.Range) {
	msgSend(nil, self, "setObjectSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}

@(objc_type=RenderCommandEncoder, objc_name="setObjectThreadgroupMemoryLength")
RenderCommandEncoder_setObjectThreadgroupMemoryLength :: #force_inline proc "c" (self: ^RenderCommandEncoder, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setObjectThreadgroupMemoryLength:atIndex:", length, index)
}

@(objc_type=RenderCommandEncoder, objc_name="setMeshBytes")
RenderCommandEncoder_setMeshBytes :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: rawptr, length: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setMeshBytes:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshBuffer")
RenderCommandEncoder_setMeshBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffer: ^Buffer, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setMeshBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshBufferOffset")
RenderCommandEncoder_setMeshBufferOffset :: #force_inline proc "c" (self: ^RenderCommandEncoder, offset: NS.UInteger, index: NS.UInteger) {
	msgSend(nil, self, "setMeshBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshBuffers")
RenderCommandEncoder_setMeshBuffers :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: [^]^Buffer, offsets: [^]NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setMeshBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshTexture")
RenderCommandEncoder_setMeshTexture :: #force_inline proc "c" (self: ^RenderCommandEncoder, texture: ^Texture, index: NS.UInteger) {
	msgSend(nil, self, "setMeshTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshTextures")
RenderCommandEncoder_setMeshTextures :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: [^]^Texture, range: NS.Range) {
	msgSend(nil, self, "setMeshTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshSamplerState")
RenderCommandEncoder_setMeshSamplerState :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, index: NS.UInteger) {
	msgSend(nil, self, "setMeshSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshSamplerStates")
RenderCommandEncoder_setMeshSamplerStates :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: [^]^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setMeshSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshSamplerStateWithLod")
RenderCommandEncoder_setMeshSamplerStateWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, sampler: ^SamplerState, lodMinClamp, lodMaxClamp: f32, index: NS.UInteger) {
	msgSend(nil, self, "setMeshSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setMeshSamplerStatesWithLod")
RenderCommandEncoder_setMeshSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: [^]^SamplerState, lodMinClamps, lodMaxClamps: [^]f32, range: NS.Range) {
	msgSend(nil, self, "setMeshSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}

@(objc_type=RenderCommandEncoder, objc_name="drawMeshThreadgroups")
RenderCommandEncoder_drawMeshThreadgroups :: #force_inline proc "c" (self: ^RenderCommandEncoder, threadgroupsPerGrid, threadPerObjectThreadgroup, threadsPerMeshThreadgroup: Size) {
	msgSend(nil, self, "drawMeshThreadgroups:threadsPerObjectThreadgroup:threadsPerMeshThreadgroup:", threadgroupsPerGrid, threadPerObjectThreadgroup, threadsPerMeshThreadgroup)
}
@(objc_type=RenderCommandEncoder, objc_name="drawMeshThreads")
RenderCommandEncoder_drawMeshThreads :: #force_inline proc "c" (self: ^RenderCommandEncoder, threadsPerGrid, threadPerObjectThreadgroup, threadsPerMeshThreadgroup: Size) {
	msgSend(nil, self, "drawMeshThreads:threadsPerObjectThreadgroup:threadsPerMeshThreadgroup:", threadsPerGrid, threadPerObjectThreadgroup, threadsPerMeshThreadgroup)
}
@(objc_type=RenderCommandEncoder, objc_name="drawMeshThreadgroupsWithIndirectBuffer")
RenderCommandEncoder_drawMeshThreadgroupsWithIndirectBuffer :: #force_inline proc "c" (self: ^RenderCommandEncoder, indirectBuffer: ^Buffer, indirectBufferOffset, threadPerObjectThreadgroup, threadsPerMeshThreadgroup: Size) {
	msgSend(nil, self, "drawMeshThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerObjectThreadgroup:threadsPerMeshThreadgroup:", indirectBuffer, indirectBufferOffset, threadPerObjectThreadgroup, threadsPerMeshThreadgroup)
}



////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLRenderPipelineFunctionsDescriptor")
RenderPipelineFunctionsDescriptor :: struct { using _: NS.Copying(RenderPipelineFunctionsDescriptor) }

@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="alloc", objc_is_class_method=true)
RenderPipelineFunctionsDescriptor_alloc :: #force_inline proc "c" () -> ^RenderPipelineFunctionsDescriptor {
	return msgSend(^RenderPipelineFunctionsDescriptor, RenderPipelineFunctionsDescriptor, "alloc")
}

@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="init")
RenderPipelineFunctionsDescriptor_init :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor) -> ^RenderPipelineFunctionsDescriptor {
	return msgSend(^RenderPipelineFunctionsDescriptor, self, "init")
}

@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="vertexAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_vertexAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "vertexAdditionalBinaryFunctions")
}
@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="fragmentAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_fragmentAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "fragmentAdditionalBinaryFunctions")
}
@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="tileAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_tileAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "tileAdditionalBinaryFunctions")
}

@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="setVertexAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_setVertexAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "setVertexAdditionalBinaryFunctions:", binaryFunctions)
}
@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="setFragmentAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_setFragmentAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "setFragmentAdditionalBinaryFunctions:", binaryFunctions)
}
@(objc_type=RenderPipelineFunctionsDescriptor, objc_name="setTileAdditionalBinaryFunctions")
RenderPipelineFunctionsDescriptor_setTileAdditionalBinaryFunctions :: #force_inline proc "c" (self: ^RenderPipelineFunctionsDescriptor, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "tileAdditionalBinaryFunctions:", binaryFunctions)
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLRenderPipelineState")
RenderPipelineState :: struct { using _: NS.Object }

@(objc_type=RenderPipelineState, objc_name="device")
RenderPipelineState_device :: #force_inline proc "c" (self: ^RenderPipelineState) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=RenderPipelineState, objc_name="imageblockMemoryLengthForDimensions")
RenderPipelineState_imageblockMemoryLengthForDimensions :: #force_inline proc "c" (self: ^RenderPipelineState, imageblockDimensions: Size) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=RenderPipelineState, objc_name="imageblockSampleLength")
RenderPipelineState_imageblockSampleLength :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "imageblockSampleLength")
}
@(objc_type=RenderPipelineState, objc_name="label")
RenderPipelineState_label :: #force_inline proc "c" (self: ^RenderPipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineState, objc_name="maxTotalThreadsPerThreadgroup")
RenderPipelineState_maxTotalThreadsPerThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=RenderPipelineState, objc_name="supportIndirectCommandBuffers")
RenderPipelineState_supportIndirectCommandBuffers :: #force_inline proc "c" (self: ^RenderPipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineState, objc_name="threadgroupSizeMatchesTileSize")
RenderPipelineState_threadgroupSizeMatchesTileSize :: #force_inline proc "c" (self: ^RenderPipelineState) -> BOOL {
	return msgSend(BOOL, self, "threadgroupSizeMatchesTileSize")
}

@(objc_type=RenderPipelineState, objc_name="functionHandle")
RenderPipelineState_functionHandle :: #force_inline proc "c" (self: ^RenderPipelineState, function: ^Function, stage: RenderStages) -> ^FunctionHandle {
	return msgSend(^FunctionHandle, self, "functionHandleWithFunction:stage:", function, stage)
}

@(objc_type=RenderPipelineState, objc_name="newVisibleFunctionTable")
RenderPipelineState_newVisibleFunctionTable :: #force_inline proc "c" (self: ^RenderPipelineState, descriptor: ^VisibleFunctionTableDescriptor, stage: RenderStages) -> ^VisibleFunctionTable {
	return msgSend(^VisibleFunctionTable, self, "newVisibleFunctionTableWithDescriptor:stage:", descriptor, stage)
}

@(objc_type=RenderPipelineState, objc_name="newIntersectionFunctionTable")
RenderPipelineState_newIntersectionFunctionTable :: #force_inline proc "c" (self: ^RenderPipelineState, descriptor: ^IntersectionFunctionTableDescriptor, stage: RenderStages) -> ^IntersectionFunctionTable {
	return msgSend(^IntersectionFunctionTable, self, "newIntersectionFunctionTable:stage:", descriptor, stage)
}

@(objc_type=RenderPipelineState, objc_name="newRenderPipelineState")
RenderPipelineState_newRenderPipelineState :: #force_inline proc "contextless" (self: ^RenderPipelineState, additionalBinaryFunctions: ^RenderPipelineFunctionsDescriptor) -> (state: ^RenderPipelineState, error: ^NS.Error) {
	state = msgSend(^RenderPipelineState, self, "newRenderPipelineStateWithAdditionalBinaryFunctions:error:", additionalBinaryFunctions, &error)
	return
}


@(objc_type=RenderPipelineState, objc_name="maxTotalThreadsPerObjectThreadgroup")
RenderPipelineState_maxTotalThreadsPerObjectThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerObjectThreadgroup")
}
@(objc_type=RenderPipelineState, objc_name="maxTotalThreadsPerMeshThreadgroup")
RenderPipelineState_maxTotalThreadsPerMeshThreadgroup :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadsPerMeshThreadgroup")
}
@(objc_type=RenderPipelineState, objc_name="objectThreadExecutionWidth")
RenderPipelineState_objectThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "objectThreadExecutionWidth")
}
@(objc_type=RenderPipelineState, objc_name="meshThreadExecutionWidth")
RenderPipelineState_meshThreadExecutionWidth :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "meshThreadExecutionWidth")
}
@(objc_type=RenderPipelineState, objc_name="maxTotalThreadgroupsPerMeshGrid")
RenderPipelineState_maxTotalThreadgroupsPerMeshGrid :: #force_inline proc "c" (self: ^RenderPipelineState) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maxTotalThreadgroupsPerMeshGrid")
}
@(objc_type=RenderPipelineState, objc_name="gpuResourceID")
RenderPipelineState_gpuResourceID :: #force_inline proc "c" (self: ^RenderPipelineState) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}



////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLResource")
Resource :: struct { using _: NS.Object }

@(objc_type=Resource, objc_name="allocatedSize")
Resource_allocatedSize :: #force_inline proc "c" (self: ^Resource) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "allocatedSize")
}
@(objc_type=Resource, objc_name="cpuCacheMode")
Resource_cpuCacheMode :: #force_inline proc "c" (self: ^Resource) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Resource, objc_name="device")
Resource_device :: #force_inline proc "c" (self: ^Resource) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=Resource, objc_name="hazardTrackingMode")
Resource_hazardTrackingMode :: #force_inline proc "c" (self: ^Resource) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Resource, objc_name="heap")
Resource_heap :: #force_inline proc "c" (self: ^Resource) -> ^Heap {
	return msgSend(^Heap, self, "heap")
}
@(objc_type=Resource, objc_name="heapOffset")
Resource_heapOffset :: #force_inline proc "c" (self: ^Resource) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "heapOffset")
}
@(objc_type=Resource, objc_name="isAliasable")
Resource_isAliasable :: #force_inline proc "c" (self: ^Resource) -> BOOL {
	return msgSend(BOOL, self, "isAliasable")
}
@(objc_type=Resource, objc_name="label")
Resource_label :: #force_inline proc "c" (self: ^Resource) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Resource, objc_name="makeAliasable")
Resource_makeAliasable :: #force_inline proc "c" (self: ^Resource) {
	msgSend(nil, self, "makeAliasable")
}
@(objc_type=Resource, objc_name="resourceOptions")
Resource_resourceOptions :: #force_inline proc "c" (self: ^Resource) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Resource, objc_name="setLabel")
Resource_setLabel :: #force_inline proc "c" (self: ^Resource, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Resource, objc_name="setPurgeableState")
Resource_setPurgeableState :: #force_inline proc "c" (self: ^Resource, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Resource, objc_name="storageMode")
Resource_storageMode :: #force_inline proc "c" (self: ^Resource) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLResourceStateCommandEncoder")
ResourceStateCommandEncoder :: struct { using _: CommandEncoder }

@(objc_type=ResourceStateCommandEncoder, objc_name="updateFence")
ResourceStateCommandEncoder_updateFence :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMappingIndirect")
ResourceStateCommandEncoder_updateTextureMappingIndirect :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, indirectBuffer: ^Buffer, indirectBufferOffset: NS.UInteger) {
	msgSend(nil, self, "updateTextureMapping:mode:indirectBuffer:indirectBufferOffset:", texture, mode, indirectBuffer, indirectBufferOffset)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMapping")
ResourceStateCommandEncoder_updateTextureMapping :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, region: Region, mipLevel: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "updateTextureMapping:mode:region:mipLevel:slice:", texture, mode, region, mipLevel, slice)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMappings")
ResourceStateCommandEncoder_updateTextureMappings :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, regions: []Region, mipLevels: []NS.UInteger, slices: NS.UInteger) {
	msgSend(nil, self, "updateTextureMappings:mode:regions:mipLevels:slices:numRegions:", texture, mode, raw_data(regions), raw_data(mipLevels), slices, NS.UInteger(len(regions)))
}
@(objc_type=ResourceStateCommandEncoder, objc_name="waitForFence")
ResourceStateCommandEncoder_waitForFence :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, fence: ^Fence) {
	msgSend(nil, self, "waitForFence:", fence)
}

@(objc_type=ResourceStateCommandEncoder, objc_name="moveTextureMappingsFromTexture")
ResourceStateCommandEncoder_moveTextureMappingsFromTexture :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder,
	sourceTexture:      ^Texture, sourceSlice,      sourceLevel:      NS.UInteger, sourceOrigin:      Origin, sourceSize: Size,
	destinationTexture: ^Texture, destinationSlice, destinationLevel: NS.UInteger, destinationOrigin: Origin,
) {
	msgSend(nil, self, "moveTextureMappingsFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:",
	        sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize,
	        destinationTexture, destinationSlice, destinationLevel, destinationOrigin,
        )
}


////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLSamplerState")
SamplerState :: struct { using _: NS.Object }

@(objc_type=SamplerState, objc_name="device")
SamplerState_device :: #force_inline proc "c" (self: ^SamplerState) -> ^Device {
	return msgSend(^Device, self, "device")
}
@(objc_type=SamplerState, objc_name="label")
SamplerState_label :: #force_inline proc "c" (self: ^SamplerState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=SamplerState, objc_name="gpuResourceID")
SamplerState_gpuResourceID :: #force_inline proc "c" (self: ^SamplerState) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLSharedEvent")
SharedEvent :: struct { using _: Event }

@(objc_type=SharedEvent, objc_name="newSharedEventHandle")
SharedEvent_newSharedEventHandle :: #force_inline proc "c" (self: ^SharedEvent) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "newSharedEventHandle")
}
@(objc_type=SharedEvent, objc_name="notifyListener")
SharedEvent_notifyListener :: #force_inline proc "c" (self: ^SharedEvent, listener: ^SharedEventListener, value: u64, block: SharedEventNotificationBlock) {
	msgSend(nil, self, "notifyListener:atValue:block:", listener, value, block)
}
@(objc_type=SharedEvent, objc_name="setSignaledValue")
SharedEvent_setSignaledValue :: #force_inline proc "c" (self: ^SharedEvent, signaledValue: u64) {
	msgSend(nil, self, "setSignaledValue:", signaledValue)
}
@(objc_type=SharedEvent, objc_name="signaledValue")
SharedEvent_signaledValue :: #force_inline proc "c" (self: ^SharedEvent) -> u64 {
	return msgSend(u64, self, "signaledValue")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLTexture")
Texture :: struct { using _: Resource }

@(objc_type=Texture, objc_name="allowGPUOptimizedContents")
Texture_allowGPUOptimizedContents :: #force_inline proc "c" (self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=Texture, objc_name="arrayLength")
Texture_arrayLength :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "arrayLength")
}
@(objc_type=Texture, objc_name="buffer")
Texture_buffer :: #force_inline proc "c" (self: ^Texture) -> ^Buffer {
	return msgSend(^Buffer, self, "buffer")
}
@(objc_type=Texture, objc_name="bufferBytesPerRow")
Texture_bufferBytesPerRow :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferBytesPerRow")
}
@(objc_type=Texture, objc_name="bufferOffset")
Texture_bufferOffset :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "bufferOffset")
}
@(objc_type=Texture, objc_name="depth")
Texture_depth :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "depth")
}
@(objc_type=Texture, objc_name="firstMipmapInTail")
Texture_firstMipmapInTail :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "firstMipmapInTail")
}
@(objc_type=Texture, objc_name="getBytesWithLevel")
Texture_getBytesWithLevel :: #force_inline proc "c" (self: ^Texture, pixelBytes: rawptr, bytesPerRow: NS.UInteger, bytesPerImage: NS.UInteger, region: Region, level: NS.UInteger, slice: NS.UInteger) {
	msgSend(nil, self, "getBytes:bytesPerRow:bytesPerImage:fromRegion:mipmapLevel:slice:", pixelBytes, bytesPerRow, bytesPerImage, region, level, slice)
}
@(objc_type=Texture, objc_name="getBytes")
Texture_getBytes :: #force_inline proc "c" (self: ^Texture, pixelBytes: rawptr, bytesPerRow: NS.UInteger, region: Region, level: NS.UInteger) {
	msgSend(nil, self, "getBytes:bytesPerRow:fromRegion:mipmapLevel:", pixelBytes, bytesPerRow, region, level)
}
@(objc_type=Texture, objc_name="height")
Texture_height :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "height")
}
@(objc_type=Texture, objc_name="iosurface")
Texture_iosurface :: #force_inline proc "c" (self: ^Texture) -> IOSurfaceRef {
	return msgSend(IOSurfaceRef, self, "iosurface")
}
@(objc_type=Texture, objc_name="iosurfacePlane")
Texture_iosurfacePlane :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "iosurfacePlane")
}
@(objc_type=Texture, objc_name="isFramebufferOnly")
Texture_isFramebufferOnly :: #force_inline proc "c" (self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isFramebufferOnly")
}
@(objc_type=Texture, objc_name="isShareable")
Texture_isShareable :: #force_inline proc "c" (self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isShareable")
}
@(objc_type=Texture, objc_name="isSparse")
Texture_isSparse :: #force_inline proc "c" (self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isSparse")
}
@(objc_type=Texture, objc_name="mipmapLevelCount")
Texture_mipmapLevelCount :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "mipmapLevelCount")
}
@(objc_type=Texture, objc_name="newRemoteTextureViewForDevice")
Texture_newRemoteTextureViewForDevice :: #force_inline proc "c" (self: ^Texture, device: ^Device) -> ^Texture {
	return msgSend(^Texture, self, "newRemoteTextureViewForDevice:", device)
}
@(objc_type=Texture, objc_name="newSharedTextureHandle")
Texture_newSharedTextureHandle :: #force_inline proc "c" (self: ^Texture) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "newSharedTextureHandle")
}

@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat")
Texture_newTextureViewWithPixelFormat :: #force_inline proc "c" (self: ^Texture, pixelFormat: PixelFormat) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:", pixelFormat)
}
@(objc_type=Texture, objc_name="newTextureViewWithLevels")
Texture_newTextureViewWithLevels :: #force_inline proc "c" (self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:", pixelFormat, textureType, levelRange, sliceRange)
}
@(objc_type=Texture, objc_name="newTextureViewWithLevelsAndSwizzle")
Texture_newTextureViewWithLevelsAndSwizzle :: #force_inline proc "c" (self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range, swizzle: TextureSwizzleChannels) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:", pixelFormat, textureType, levelRange, sliceRange, swizzle)
}
@(objc_type=Texture, objc_name="newTextureView")
Texture_newTextureView :: proc{
	Texture_newTextureViewWithPixelFormat,
	Texture_newTextureViewWithLevels,
	Texture_newTextureViewWithLevelsAndSwizzle,
}

@(objc_type=Texture, objc_name="parentRelativeLevel")
Texture_parentRelativeLevel :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "parentRelativeLevel")
}
@(objc_type=Texture, objc_name="parentRelativeSlice")
Texture_parentRelativeSlice :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "parentRelativeSlice")
}
@(objc_type=Texture, objc_name="parentTexture")
Texture_parentTexture :: #force_inline proc "c" (self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "parentTexture")
}
@(objc_type=Texture, objc_name="pixelFormat")
Texture_pixelFormat :: #force_inline proc "c" (self: ^Texture) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=Texture, objc_name="remoteStorageTexture")
Texture_remoteStorageTexture :: #force_inline proc "c" (self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "remoteStorageTexture")
}
@(objc_type=Texture, objc_name="replaceRegionWithLevel")
Texture_replaceRegionWithLevel :: #force_inline proc "c" (self: ^Texture, region: Region, level: NS.UInteger, slice: NS.UInteger, pixelBytes: rawptr, bytesPerRow: NS.UInteger, bytesPerImage: NS.UInteger) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:", region, level, slice, pixelBytes, bytesPerRow, bytesPerImage)
}
@(objc_type=Texture, objc_name="replaceRegion")
Texture_replaceRegion :: #force_inline proc "c" (self: ^Texture, region: Region, level: NS.UInteger, pixelBytes: rawptr, bytesPerRow: NS.UInteger) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:withBytes:bytesPerRow:", region, level, pixelBytes, bytesPerRow)
}
@(objc_type=Texture, objc_name="rootResource")
Texture_rootResource :: #force_inline proc "c" (self: ^Texture) -> ^Resource {
	return msgSend(^Resource, self, "rootResource")
}
@(objc_type=Texture, objc_name="sampleCount")
Texture_sampleCount :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}
@(objc_type=Texture, objc_name="swizzle")
Texture_swizzle :: #force_inline proc "c" (self: ^Texture) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=Texture, objc_name="tailSizeInBytes")
Texture_tailSizeInBytes :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "tailSizeInBytes")
}
@(objc_type=Texture, objc_name="textureType")
Texture_textureType :: #force_inline proc "c" (self: ^Texture) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Texture, objc_name="usage")
Texture_usage :: #force_inline proc "c" (self: ^Texture) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=Texture, objc_name="width")
Texture_width :: #force_inline proc "c" (self: ^Texture) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "width")
}

@(objc_type=Texture, objc_name="compressionType")
Texture_compressionType :: #force_inline proc "c" (self: ^Texture) -> TextureCompressionType {
	return msgSend(TextureCompressionType, self, "compressionType")
}
@(objc_type=Texture, objc_name="gpuResourceID")
Texture_gpuResourceID :: #force_inline proc "c" (self: ^Texture) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}

////////////////////////////////////////////////////////////////////////////////

@(objc_class="MTLVisibleFunctionTable")
VisibleFunctionTable :: struct { using _: Resource }

@(objc_type=VisibleFunctionTable, objc_name="setFunction")
VisibleFunctionTable_setFunction :: #force_inline proc "c" (self: ^VisibleFunctionTable, function: ^FunctionHandle, index: NS.UInteger) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=VisibleFunctionTable, objc_name="setFunctions")
VisibleFunctionTable_setFunctions :: #force_inline proc "c" (self: ^VisibleFunctionTable, functions: []^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", raw_data(functions), range)
}

@(objc_type=VisibleFunctionTable, objc_name="gpuResourceID")
VisibleFunctionTable_gpuResourceID :: #force_inline proc "c" (self: ^VisibleFunctionTable) -> ResourceID {
	return msgSend(ResourceID, self, "gpuResourceID")
}




