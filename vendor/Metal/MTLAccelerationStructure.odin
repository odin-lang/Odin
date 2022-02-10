package objc_Metal

import NS "core:sys/darwin/Foundation"

AccelerationStructureUsage :: distinct bit_set[AccelerationStructureUsageFlag; NS.UInteger]
AccelerationStructureUsageFlag :: enum NS.UInteger {
	Refit           = 0,
	PreferFastBuild = 1,
	ExtendedLimits  = 2,
}
AccelerationStructureUsageNone :: AccelerationStructureUsage{}

AccelerationStructureInstanceOptions :: distinct bit_set[AccelerationStructureInstanceOption; u32]
AccelerationStructureInstanceOption :: enum u32 {
	DisableTriangleCulling                     = 0,
	TriangleFrontFacingWindingCounterClockwise = 1,
	Opaque                                     = 2,
	NonOpaque                                  = 3,
}
AccelerationStructureInstanceOptionNone :: AccelerationStructureInstanceOptions{}

MotionBorderMode :: enum u32 {
	Clamp  = 0,
	Vanish = 1,
}

AccelerationStructureInstanceDescriptor :: struct #packed {
	transformationMatrix:            PackedFloat4x3,
	options:                         AccelerationStructureInstanceOptions,
	mask:                            u32,
	intersectionFunctionTableOffset: u32,
	accelerationStructureIndex:      u32,
}

AccelerationStructureUserIDInstanceDescriptor :: struct #packed {
	transformationMatrix:            PackedFloat4x3,
	options:                         AccelerationStructureInstanceOptions,
	mask:                            u32,
	intersectionFunctionTableOffset: u32,
	accelerationStructureIndex:      u32,
	userID:                          u32,
}

AccelerationStructureInstanceDescriptorType :: enum NS.UInteger {
    	Default = 0,
    	UserID  = 1,
    	Motion  = 2,
}

AccelerationStructureMotionInstanceDescriptor :: struct #packed {
	options:                         AccelerationStructureInstanceOptions,
	mask:                            u32,
	intersectionFunctionTableOffset: u32,
	accelerationStructureIndex:      u32,
	userID:                          u32,
	motionTransformsStartIndex:      u32,
	motionTransformsCount:           u32,
	motionStartBorderMode:           MotionBorderMode,
	motionEndBorderMode:             MotionBorderMode,
	motionStartTime:                 f32,
	motionEndTime:                   f32,
}

@(objc_class="NSAccelerationStructureDescriptor")
AccelerationStructureDescriptor :: struct { using _: NS.Copying(AccelerationStructureDescriptor) }

@(objc_class="NSAccelerationStructureGeometryDescriptor")
AccelerationStructureGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureGeometryDescriptor) }

@(objc_class="NSPrimitiveAccelerationStructureDescriptor")
PrimitiveAccelerationStructureDescriptor :: struct { using _: NS.Copying(PrimitiveAccelerationStructureDescriptor), using _: AccelerationStructureDescriptor }

@(objc_class="NSAccelerationStructureTriangleGeometryDescriptor")
AccelerationStructureTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureTriangleGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_class="NSAccelerationStructureBoundingBoxGeometryDescriptor")
AccelerationStructureBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureBoundingBoxGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_class="NSMotionKeyframeData")
MotionKeyframeData :: struct { using _: NS.Object }

@(objc_class="NSAccelerationStructureMotionTriangleGeometryDescriptor")
AccelerationStructureMotionTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionTriangleGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_class="NSAccelerationStructureMotionBoundingBoxGeometryDescriptor")
AccelerationStructureMotionBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureMotionBoundingBoxGeometryDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_class="NSInstanceAccelerationStructureDescriptor")
InstanceAccelerationStructureDescriptor :: struct { using _: NS.Copying(InstanceAccelerationStructureDescriptor), using _: AccelerationStructureGeometryDescriptor }

@(objc_class="NSAccelerationStructure")
AccelerationStructure :: struct { using _: NS.Object }



AccelerationStructureDescriptor_usage :: proc(self: ^AccelerationStructureDescriptor) -> AccelerationStructureUsage {
	return msgSend(AccelerationStructureUsage, self, "usage")
}

AccelerationStructureGeometryDescriptor_intersectionFunctionTableOffset :: proc(self: ^AccelerationStructureGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "intersectionFunctionTableOffset")
}

AccelerationStructureGeometryDescriptor_setIntersectionFunctionTableOffset :: proc(self: ^AccelerationStructureGeometryDescriptor, intersectionFunctionTableOffset: NS.UInteger) {
	msgSend(nil, self, "setIntersectionFunctionTableOffset:", intersectionFunctionTableOffset)
}

AccelerationStructureGeometryDescriptor_opaque :: proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "opaque")
}

AccelerationStructureGeometryDescriptor_setOpaque :: proc(self: ^AccelerationStructureGeometryDescriptor, opaque: BOOL) {
	msgSend(nil, self, "setOpaque:", opaque)
}

AccelerationStructureGeometryDescriptor_allowDuplicateIntersectionFunctionInvocation :: proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowDuplicateIntersectionFunctionInvocation")
}

AccelerationStructureGeometryDescriptor_setAllowDuplicateIntersectionFunctionInvocation :: proc(self: ^AccelerationStructureGeometryDescriptor, allowDuplicateIntersectionFunctionInvocation: BOOL) {
	msgSend(nil, self, "setAllowDuplicateIntersectionFunctionInvocation:", allowDuplicateIntersectionFunctionInvocation)
}


AccelerationStructureGeometryDescriptor_label :: proc(self: ^AccelerationStructureGeometryDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}

AccelerationStructureGeometryDescriptor_setLabel :: proc(self: ^AccelerationStructureGeometryDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}

PrimitiveAccelerationStructureDescriptor_geometryDescriptors :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> (descriptors: ^NS.Array(^NS.Object)) {
	return msgSend(type_of(descriptors), self, "geometryDescriptors")
}

PrimitiveAccelerationStructureDescriptor_setGeometryDescriptors :: proc(self: ^PrimitiveAccelerationStructureDescriptor, descriptors: ^NS.Array(^NS.Object)) {
	msgSend(nil, self, "setGeometryDescriptors:", descriptors)
}

PrimitiveAccelerationStructureDescriptor_motionStartBorderMode :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionStartBorderMode")
}
PrimitiveAccelerationStructureDescriptor_setMotionStartBorderMode :: proc(self: ^PrimitiveAccelerationStructureDescriptor, motionStartBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionStartBorderMode:", motionStartBorderMode)
}

PrimitiveAccelerationStructureDescriptor_motionEndBorderMode :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> MotionBorderMode {
	return msgSend(MotionBorderMode, self, "motionEndBorderMode")
}
PrimitiveAccelerationStructureDescriptor_setMotionEndBorderMode :: proc(self: ^PrimitiveAccelerationStructureDescriptor, motionEndBorderMode: MotionBorderMode) {
	msgSend(nil, self, "setMotionEndBorderMode:", motionEndBorderMode)
}

PrimitiveAccelerationStructureDescriptor_motionStartTime :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> (motionStartTime: f32) {
	return msgSend(f32, self, "motionStartTime")
}
PrimitiveAccelerationStructureDescriptor_setMotionStartTime :: proc(self: ^PrimitiveAccelerationStructureDescriptor, motionStartTime: f32) {
	msgSend(nil, self, "setMotionStartTime:", motionStartTime)
}


PrimitiveAccelerationStructureDescriptor_motionEndTime :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> (motionEndTime: f32) {
	return msgSend(f32, self, "motionEndTime")
}
PrimitiveAccelerationStructureDescriptor_setMotionEndTime :: proc(self: ^PrimitiveAccelerationStructureDescriptor, motionEndTime: f32) {
	msgSend(nil, self, "setMotionEndTime:", motionEndTime)
}


PrimitiveAccelerationStructureDescriptor_motionKeyframeCount :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> (motionKeyframeCount: NS.UInteger) {
	return msgSend(NS.UInteger, self, "motionKeyframeCount")
}
PrimitiveAccelerationStructureDescriptor_setmotionKeyframeCount :: proc(self: ^PrimitiveAccelerationStructureDescriptor, motionKeyframeCount: NS.UInteger) {
	msgSend(nil, self, "setMotionKeyframeCount:", motionKeyframeCount)
}

PrimitiveAccelerationStructureDescriptor_descriptor :: proc() -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "descriptor")
}


AccelerationStructureTriangleGeometryDescriptor_vertexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "vertexBuffer")
}
AccelerationStructureTriangleGeometryDescriptor_setVertexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, buffer: ^Buffer)  {
	msgSend(nil, self, "setVertexBuffer:", buffer)
}

AccelerationStructureTriangleGeometryDescriptor_vertexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexBufferOffset")
}
AccelerationStructureTriangleGeometryDescriptor_setVertexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setVertexBufferOffset:", vertexBufferOffset)
}

AccelerationStructureTriangleGeometryDescriptor_vertexStride :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "vertexStride")
}
AccelerationStructureTriangleGeometryDescriptor_setVertexStride :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexStride: NS.UInteger) {
	msgSend(nil, self, "setVertexStride:", vertexStride)
}

AccelerationStructureTriangleGeometryDescriptor_indexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "indexBuffer")
}
AccelerationStructureTriangleGeometryDescriptor_setIndexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, buffer: ^Buffer)  {
	msgSend(nil, self, "setIndexBuffer:", buffer)
}

AccelerationStructureTriangleGeometryDescriptor_indexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "indexBufferOffset")
}
AccelerationStructureTriangleGeometryDescriptor_setIndexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setIndexBufferOffset:", indexBufferOffset)
}



AccelerationStructureTriangleGeometryDescriptor_indexType :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
AccelerationStructureTriangleGeometryDescriptor_setIndexType :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indextype: IndexType) {
	msgSend(nil, self, "setIndexType:", indextype)
}

AccelerationStructureTriangleGeometryDescriptor_triangleCount :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "triangleCount")
}
AccelerationStructureTriangleGeometryDescriptor_setTriangleCount :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, triangleCount: NS.UInteger) {
	msgSend(nil, self, "setTriangleCount", triangleCount)
}


AccelerationStructureTriangleGeometryDescriptor_descriptor :: proc() -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "descriptor")
}

AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBuffer :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^Buffer {
	return msgSend(^Buffer, self, "boundingBoxBuffer")
}

AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBuffer :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, buffer: ^Buffer) {
	msgSend(nil, self, "setBoundingBoxBuffer:", buffer)
}

AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBufferOffset :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxBufferOffset")
}

AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBufferOffset :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBufferOffset: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxBufferOffset:", boundingBoxBufferOffset)
}


AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxStride :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxStride")
}

AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxStride :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxStride: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxStride:", boundingBoxStride)
}

AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxCount :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "boundingBoxCount")
}

AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxCount :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxCount: NS.UInteger) {
	msgSend(nil, self, "setBoundingBoxCount:", boundingBoxCount)
}
