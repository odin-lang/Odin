package objc_Metal

import NS "core:sys/darwin/Foundation"

foreign import "system:Metal.framework"

@(default_calling_convention="c", link_prefix="MTL")
foreign Metal {
	CopyAllDevices :: proc() -> ^NS.Array ---
	CopyAllDevicesWithObserver :: proc(observer: ^^NS.Object, handler: DeviceNotificationHandler) -> ^NS.Array ---
	CreateSystemDefaultDevice :: proc() -> ^NS.Object ---
	RemoveDeviceObserver :: proc(observer: ^NS.Object) ---
}





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
AccelerationStructureBoundingBoxGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureBoundingBoxGeometryDescriptor) }

@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureBoundingBoxGeometryDescriptor_alloc :: proc() -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="init")
AccelerationStructureBoundingBoxGeometryDescriptor_init :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBuffer :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, self, "boundingBoxBuffer")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxBufferOffset :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "boundingBoxBufferOffset")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxCount :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "boundingBoxCount")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="boundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_boundingBoxStride :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "boundingBoxStride")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_class_name="descriptor")
AccelerationStructureBoundingBoxGeometryDescriptor_descriptor :: proc() -> ^AccelerationStructureBoundingBoxGeometryDescriptor {
	return msgSend(^AccelerationStructureBoundingBoxGeometryDescriptor, AccelerationStructureBoundingBoxGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBuffer")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBuffer :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBuffer: ^NS.Object) {
	msgSend(nil, self, "setBoundingBoxBuffer:", boundingBoxBuffer)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxBufferOffset")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxBufferOffset :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxBufferOffset: NS.Integer) {
	msgSend(nil, self, "setBoundingBoxBufferOffset:", boundingBoxBufferOffset)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxCount")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxCount :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxCount: NS.Integer) {
	msgSend(nil, self, "setBoundingBoxCount:", boundingBoxCount)
}
@(objc_type=AccelerationStructureBoundingBoxGeometryDescriptor, objc_name="setBoundingBoxStride")
AccelerationStructureBoundingBoxGeometryDescriptor_setBoundingBoxStride :: proc(self: ^AccelerationStructureBoundingBoxGeometryDescriptor, boundingBoxStride: NS.Integer) {
	msgSend(nil, self, "setBoundingBoxStride:", boundingBoxStride)
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
AccelerationStructureDescriptor_alloc :: proc() -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, AccelerationStructureDescriptor, "alloc")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="init")
AccelerationStructureDescriptor_init :: proc(self: ^AccelerationStructureDescriptor) -> ^AccelerationStructureDescriptor {
	return msgSend(^AccelerationStructureDescriptor, self, "init")
}
@(objc_type=AccelerationStructureDescriptor, objc_name="setUsage")
AccelerationStructureDescriptor_setUsage :: proc(self: ^AccelerationStructureDescriptor, usage: AccelerationStructureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=AccelerationStructureDescriptor, objc_name="usage")
AccelerationStructureDescriptor_usage :: proc(self: ^AccelerationStructureDescriptor) -> AccelerationStructureUsage {
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
AccelerationStructureGeometryDescriptor_alloc :: proc() -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, AccelerationStructureGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="init")
AccelerationStructureGeometryDescriptor_init :: proc(self: ^AccelerationStructureGeometryDescriptor) -> ^AccelerationStructureGeometryDescriptor {
	return msgSend(^AccelerationStructureGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="allowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_allowDuplicateIntersectionFunctionInvocation :: proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowDuplicateIntersectionFunctionInvocation")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="intersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_intersectionFunctionTableOffset :: proc(self: ^AccelerationStructureGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "intersectionFunctionTableOffset")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="opaque")
AccelerationStructureGeometryDescriptor_opaque :: proc(self: ^AccelerationStructureGeometryDescriptor) -> BOOL {
	return msgSend(BOOL, self, "opaque")
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setAllowDuplicateIntersectionFunctionInvocation")
AccelerationStructureGeometryDescriptor_setAllowDuplicateIntersectionFunctionInvocation :: proc(self: ^AccelerationStructureGeometryDescriptor, allowDuplicateIntersectionFunctionInvocation: BOOL) {
	msgSend(nil, self, "setAllowDuplicateIntersectionFunctionInvocation:", allowDuplicateIntersectionFunctionInvocation)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setIntersectionFunctionTableOffset")
AccelerationStructureGeometryDescriptor_setIntersectionFunctionTableOffset :: proc(self: ^AccelerationStructureGeometryDescriptor, intersectionFunctionTableOffset: NS.Integer) {
	msgSend(nil, self, "setIntersectionFunctionTableOffset:", intersectionFunctionTableOffset)
}
@(objc_type=AccelerationStructureGeometryDescriptor, objc_name="setOpaque")
AccelerationStructureGeometryDescriptor_setOpaque :: proc(self: ^AccelerationStructureGeometryDescriptor, opaque: BOOL) {
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
AccelerationStructureTriangleGeometryDescriptor :: struct { using _: NS.Copying(AccelerationStructureTriangleGeometryDescriptor) }

@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_class_name="alloc")
AccelerationStructureTriangleGeometryDescriptor_alloc :: proc() -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "alloc")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="init")
AccelerationStructureTriangleGeometryDescriptor_init :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, self, "init")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_class_name="descriptor")
AccelerationStructureTriangleGeometryDescriptor_descriptor :: proc() -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, AccelerationStructureTriangleGeometryDescriptor, "descriptor")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBuffer")
AccelerationStructureTriangleGeometryDescriptor_indexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, self, "indexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_indexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "indexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="indexType")
AccelerationStructureTriangleGeometryDescriptor_indexType :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setIndexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexBuffer: ^NS.Object) {
	msgSend(nil, self, "setIndexBuffer:", indexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setIndexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexBufferOffset: NS.Integer) {
	msgSend(nil, self, "setIndexBufferOffset:", indexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setIndexType")
AccelerationStructureTriangleGeometryDescriptor_setIndexType :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setTriangleCount")
AccelerationStructureTriangleGeometryDescriptor_setTriangleCount :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, triangleCount: NS.Integer) {
	msgSend(nil, self, "setTriangleCount:", triangleCount)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_setVertexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBuffer: ^NS.Object) {
	msgSend(nil, self, "setVertexBuffer:", vertexBuffer)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_setVertexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexBufferOffset: NS.Integer) {
	msgSend(nil, self, "setVertexBufferOffset:", vertexBufferOffset)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="setVertexStride")
AccelerationStructureTriangleGeometryDescriptor_setVertexStride :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor, vertexStride: NS.Integer) {
	msgSend(nil, self, "setVertexStride:", vertexStride)
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="triangleCount")
AccelerationStructureTriangleGeometryDescriptor_triangleCount :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "triangleCount")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBuffer")
AccelerationStructureTriangleGeometryDescriptor_vertexBuffer :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> ^AccelerationStructureTriangleGeometryDescriptor {
	return msgSend(^AccelerationStructureTriangleGeometryDescriptor, self, "vertexBuffer")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexBufferOffset")
AccelerationStructureTriangleGeometryDescriptor_vertexBufferOffset :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "vertexBufferOffset")
}
@(objc_type=AccelerationStructureTriangleGeometryDescriptor, objc_name="vertexStride")
AccelerationStructureTriangleGeometryDescriptor_vertexStride :: proc(self: ^AccelerationStructureTriangleGeometryDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "vertexStride")
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
Argument_alloc :: proc() -> ^Argument {
	return msgSend(^Argument, Argument, "alloc")
}
@(objc_type=Argument, objc_name="init")
Argument_init :: proc(self: ^Argument) -> ^Argument {
	return msgSend(^Argument, self, "init")
}
@(objc_type=Argument, objc_name="access")
Argument_access :: proc(self: ^Argument) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=Argument, objc_name="arrayLength")
Argument_arrayLength :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "arrayLength")
}
@(objc_type=Argument, objc_name="bufferAlignment")
Argument_bufferAlignment :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferAlignment")
}
@(objc_type=Argument, objc_name="bufferDataSize")
Argument_bufferDataSize :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferDataSize")
}
@(objc_type=Argument, objc_name="bufferDataType")
Argument_bufferDataType :: proc(self: ^Argument) -> DataType {
	return msgSend(DataType, self, "bufferDataType")
}
@(objc_type=Argument, objc_name="bufferPointerType")
Argument_bufferPointerType :: proc(self: ^Argument) -> ^PointerType {
	return msgSend(^PointerType, self, "bufferPointerType")
}
@(objc_type=Argument, objc_name="bufferStructType")
Argument_bufferStructType :: proc(self: ^Argument) -> ^StructType {
	return msgSend(^StructType, self, "bufferStructType")
}
@(objc_type=Argument, objc_name="index")
Argument_index :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "index")
}
@(objc_type=Argument, objc_name="isActive")
Argument_isActive :: proc(self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Argument, objc_name="isDepthTexture")
Argument_isDepthTexture :: proc(self: ^Argument) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=Argument, objc_name="name")
Argument_name :: proc(self: ^Argument) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Argument, objc_name="textureDataType")
Argument_textureDataType :: proc(self: ^Argument) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=Argument, objc_name="textureType")
Argument_textureType :: proc(self: ^Argument) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Argument, objc_name="threadgroupMemoryAlignment")
Argument_threadgroupMemoryAlignment :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "threadgroupMemoryAlignment")
}
@(objc_type=Argument, objc_name="threadgroupMemoryDataSize")
Argument_threadgroupMemoryDataSize :: proc(self: ^Argument) -> NS.Integer {
	return msgSend(NS.Integer, self, "threadgroupMemoryDataSize")
}
@(objc_type=Argument, objc_name="type")
Argument_type :: proc(self: ^Argument) -> ArgumentType {
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
ArgumentDescriptor_alloc :: proc() -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "alloc")
}
@(objc_type=ArgumentDescriptor, objc_name="init")
ArgumentDescriptor_init :: proc(self: ^ArgumentDescriptor) -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, self, "init")
}
@(objc_type=ArgumentDescriptor, objc_name="access")
ArgumentDescriptor_access :: proc(self: ^ArgumentDescriptor) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=ArgumentDescriptor, objc_class_name="argumentDescriptor")
ArgumentDescriptor_argumentDescriptor :: proc() -> ^ArgumentDescriptor {
	return msgSend(^ArgumentDescriptor, ArgumentDescriptor, "argumentDescriptor")
}
@(objc_type=ArgumentDescriptor, objc_name="arrayLength")
ArgumentDescriptor_arrayLength :: proc(self: ^ArgumentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "arrayLength")
}
@(objc_type=ArgumentDescriptor, objc_name="constantBlockAlignment")
ArgumentDescriptor_constantBlockAlignment :: proc(self: ^ArgumentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "constantBlockAlignment")
}
@(objc_type=ArgumentDescriptor, objc_name="dataType")
ArgumentDescriptor_dataType :: proc(self: ^ArgumentDescriptor) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=ArgumentDescriptor, objc_name="index")
ArgumentDescriptor_index :: proc(self: ^ArgumentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "index")
}
@(objc_type=ArgumentDescriptor, objc_name="setAccess")
ArgumentDescriptor_setAccess :: proc(self: ^ArgumentDescriptor, access: ArgumentAccess) {
	msgSend(nil, self, "setAccess:", access)
}
@(objc_type=ArgumentDescriptor, objc_name="setArrayLength")
ArgumentDescriptor_setArrayLength :: proc(self: ^ArgumentDescriptor, arrayLength: NS.Integer) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=ArgumentDescriptor, objc_name="setConstantBlockAlignment")
ArgumentDescriptor_setConstantBlockAlignment :: proc(self: ^ArgumentDescriptor, constantBlockAlignment: NS.Integer) {
	msgSend(nil, self, "setConstantBlockAlignment:", constantBlockAlignment)
}
@(objc_type=ArgumentDescriptor, objc_name="setDataType")
ArgumentDescriptor_setDataType :: proc(self: ^ArgumentDescriptor, dataType: DataType) {
	msgSend(nil, self, "setDataType:", dataType)
}
@(objc_type=ArgumentDescriptor, objc_name="setIndex")
ArgumentDescriptor_setIndex :: proc(self: ^ArgumentDescriptor, index: NS.Integer) {
	msgSend(nil, self, "setIndex:", index)
}
@(objc_type=ArgumentDescriptor, objc_name="setTextureType")
ArgumentDescriptor_setTextureType :: proc(self: ^ArgumentDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=ArgumentDescriptor, objc_name="textureType")
ArgumentDescriptor_textureType :: proc(self: ^ArgumentDescriptor) -> TextureType {
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
ArrayType :: struct { using _: NS.Object }

@(objc_type=ArrayType, objc_class_name="alloc")
ArrayType_alloc :: proc() -> ^ArrayType {
	return msgSend(^ArrayType, ArrayType, "alloc")
}
@(objc_type=ArrayType, objc_name="init")
ArrayType_init :: proc(self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "init")
}
@(objc_type=ArrayType, objc_name="argumentIndexStride")
ArrayType_argumentIndexStride :: proc(self: ^ArrayType) -> NS.Integer {
	return msgSend(NS.Integer, self, "argumentIndexStride")
}
@(objc_type=ArrayType, objc_name="arrayLength")
ArrayType_arrayLength :: proc(self: ^ArrayType) -> NS.Integer {
	return msgSend(NS.Integer, self, "arrayLength")
}
@(objc_type=ArrayType, objc_name="elementArrayType")
ArrayType_elementArrayType :: proc(self: ^ArrayType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=ArrayType, objc_name="elementPointerType")
ArrayType_elementPointerType :: proc(self: ^ArrayType) -> ^PointerType {
	return msgSend(^PointerType, self, "elementPointerType")
}
@(objc_type=ArrayType, objc_name="elementStructType")
ArrayType_elementStructType :: proc(self: ^ArrayType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=ArrayType, objc_name="elementTextureReferenceType")
ArrayType_elementTextureReferenceType :: proc(self: ^ArrayType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "elementTextureReferenceType")
}
@(objc_type=ArrayType, objc_name="elementType")
ArrayType_elementType :: proc(self: ^ArrayType) -> DataType {
	return msgSend(DataType, self, "elementType")
}
@(objc_type=ArrayType, objc_name="stride")
ArrayType_stride :: proc(self: ^ArrayType) -> NS.Integer {
	return msgSend(NS.Integer, self, "stride")
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
Attribute_alloc :: proc() -> ^Attribute {
	return msgSend(^Attribute, Attribute, "alloc")
}
@(objc_type=Attribute, objc_name="init")
Attribute_init :: proc(self: ^Attribute) -> ^Attribute {
	return msgSend(^Attribute, self, "init")
}
@(objc_type=Attribute, objc_name="attributeIndex")
Attribute_attributeIndex :: proc(self: ^Attribute) -> NS.Integer {
	return msgSend(NS.Integer, self, "attributeIndex")
}
@(objc_type=Attribute, objc_name="attributeType")
Attribute_attributeType :: proc(self: ^Attribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=Attribute, objc_name="isActive")
Attribute_isActive :: proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=Attribute, objc_name="isPatchControlPointData")
Attribute_isPatchControlPointData :: proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=Attribute, objc_name="isPatchData")
Attribute_isPatchData :: proc(self: ^Attribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=Attribute, objc_name="name")
Attribute_name :: proc(self: ^Attribute) -> ^NS.String {
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
AttributeDescriptor_alloc :: proc() -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, AttributeDescriptor, "alloc")
}
@(objc_type=AttributeDescriptor, objc_name="init")
AttributeDescriptor_init :: proc(self: ^AttributeDescriptor) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "init")
}
@(objc_type=AttributeDescriptor, objc_name="bufferIndex")
AttributeDescriptor_bufferIndex :: proc(self: ^AttributeDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferIndex")
}
@(objc_type=AttributeDescriptor, objc_name="format")
AttributeDescriptor_format :: proc(self: ^AttributeDescriptor) -> AttributeFormat {
	return msgSend(AttributeFormat, self, "format")
}
@(objc_type=AttributeDescriptor, objc_name="offset")
AttributeDescriptor_offset :: proc(self: ^AttributeDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "offset")
}
@(objc_type=AttributeDescriptor, objc_name="setBufferIndex")
AttributeDescriptor_setBufferIndex :: proc(self: ^AttributeDescriptor, bufferIndex: NS.Integer) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=AttributeDescriptor, objc_name="setFormat")
AttributeDescriptor_setFormat :: proc(self: ^AttributeDescriptor, format: AttributeFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=AttributeDescriptor, objc_name="setOffset")
AttributeDescriptor_setOffset :: proc(self: ^AttributeDescriptor, offset: NS.Integer) {
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
AttributeDescriptorArray_alloc :: proc() -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, AttributeDescriptorArray, "alloc")
}
@(objc_type=AttributeDescriptorArray, objc_name="init")
AttributeDescriptorArray_init :: proc(self: ^AttributeDescriptorArray) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "init")
}
@(objc_type=AttributeDescriptorArray, objc_name="objectAtIndexedSubscript")
AttributeDescriptorArray_objectAtIndexedSubscript :: proc(self: ^AttributeDescriptorArray, index: ^NS.Object) -> ^AttributeDescriptor {
	return msgSend(^AttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=AttributeDescriptorArray, objc_name="setObject")
AttributeDescriptorArray_setObject :: proc(self: ^AttributeDescriptorArray, attributeDesc: ^AttributeDescriptor, index: ^NS.Object) {
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
BinaryArchiveDescriptor_alloc :: proc() -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, BinaryArchiveDescriptor, "alloc")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="init")
BinaryArchiveDescriptor_init :: proc(self: ^BinaryArchiveDescriptor) -> ^BinaryArchiveDescriptor {
	return msgSend(^BinaryArchiveDescriptor, self, "init")
}
@(objc_type=BinaryArchiveDescriptor, objc_name="setUrl")
BinaryArchiveDescriptor_setUrl :: proc(self: ^BinaryArchiveDescriptor, url: ^NS.URL) {
	msgSend(nil, self, "setUrl:", url)
}
@(objc_type=BinaryArchiveDescriptor, objc_name="url")
BinaryArchiveDescriptor_url :: proc(self: ^BinaryArchiveDescriptor) -> ^NS.URL {
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
BlitPassDescriptor_alloc :: proc() -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "alloc")
}
@(objc_type=BlitPassDescriptor, objc_name="init")
BlitPassDescriptor_init :: proc(self: ^BlitPassDescriptor) -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, self, "init")
}
@(objc_type=BlitPassDescriptor, objc_class_name="blitPassDescriptor")
BlitPassDescriptor_blitPassDescriptor :: proc() -> ^BlitPassDescriptor {
	return msgSend(^BlitPassDescriptor, BlitPassDescriptor, "blitPassDescriptor")
}
@(objc_type=BlitPassDescriptor, objc_name="sampleBufferAttachments")
BlitPassDescriptor_sampleBufferAttachments :: proc(self: ^BlitPassDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
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
BlitPassSampleBufferAttachmentDescriptor_alloc :: proc() -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, BlitPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="init")
BlitPassSampleBufferAttachmentDescriptor_init :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "endOfEncoderSampleIndex")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_sampleBuffer :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "sampleBuffer")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
BlitPassSampleBufferAttachmentDescriptor_setSampleBuffer :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor, sampleBuffer: ^NS.Object) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
BlitPassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: proc(self: ^BlitPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "startOfEncoderSampleIndex")
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
BlitPassSampleBufferAttachmentDescriptorArray_alloc :: proc() -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, BlitPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="init")
BlitPassSampleBufferAttachmentDescriptorArray_init :: proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray) -> ^BlitPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
BlitPassSampleBufferAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return msgSend(^BlitPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
BlitPassSampleBufferAttachmentDescriptorArray_setObject :: proc(self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachment: ^BlitPassSampleBufferAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
BufferLayoutDescriptor_alloc :: proc() -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, BufferLayoutDescriptor, "alloc")
}
@(objc_type=BufferLayoutDescriptor, objc_name="init")
BufferLayoutDescriptor_init :: proc(self: ^BufferLayoutDescriptor) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "init")
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepFunction")
BufferLayoutDescriptor_setStepFunction :: proc(self: ^BufferLayoutDescriptor, stepFunction: StepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStepRate")
BufferLayoutDescriptor_setStepRate :: proc(self: ^BufferLayoutDescriptor, stepRate: NS.Integer) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=BufferLayoutDescriptor, objc_name="setStride")
BufferLayoutDescriptor_setStride :: proc(self: ^BufferLayoutDescriptor, stride: NS.Integer) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepFunction")
BufferLayoutDescriptor_stepFunction :: proc(self: ^BufferLayoutDescriptor) -> StepFunction {
	return msgSend(StepFunction, self, "stepFunction")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stepRate")
BufferLayoutDescriptor_stepRate :: proc(self: ^BufferLayoutDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "stepRate")
}
@(objc_type=BufferLayoutDescriptor, objc_name="stride")
BufferLayoutDescriptor_stride :: proc(self: ^BufferLayoutDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "stride")
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
BufferLayoutDescriptorArray_alloc :: proc() -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, BufferLayoutDescriptorArray, "alloc")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="init")
BufferLayoutDescriptorArray_init :: proc(self: ^BufferLayoutDescriptorArray) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "init")
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="objectAtIndexedSubscript")
BufferLayoutDescriptorArray_objectAtIndexedSubscript :: proc(self: ^BufferLayoutDescriptorArray, index: ^NS.Object) -> ^BufferLayoutDescriptor {
	return msgSend(^BufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=BufferLayoutDescriptorArray, objc_name="setObject")
BufferLayoutDescriptorArray_setObject :: proc(self: ^BufferLayoutDescriptorArray, bufferDesc: ^BufferLayoutDescriptor, index: ^NS.Object) {
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
CaptureDescriptor_alloc :: proc() -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, CaptureDescriptor, "alloc")
}
@(objc_type=CaptureDescriptor, objc_name="init")
CaptureDescriptor_init :: proc(self: ^CaptureDescriptor) -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, self, "init")
}
@(objc_type=CaptureDescriptor, objc_name="captureObject")
CaptureDescriptor_captureObject :: proc(self: ^CaptureDescriptor) -> ^CaptureDescriptor {
	return msgSend(^CaptureDescriptor, self, "captureObject")
}
@(objc_type=CaptureDescriptor, objc_name="destination")
CaptureDescriptor_destination :: proc(self: ^CaptureDescriptor) -> CaptureDestination {
	return msgSend(CaptureDestination, self, "destination")
}
@(objc_type=CaptureDescriptor, objc_name="outputURL")
CaptureDescriptor_outputURL :: proc(self: ^CaptureDescriptor) -> ^NS.URL {
	return msgSend(^NS.URL, self, "outputURL")
}
@(objc_type=CaptureDescriptor, objc_name="setCaptureObject")
CaptureDescriptor_setCaptureObject :: proc(self: ^CaptureDescriptor, captureObject: ^NS.Object) {
	msgSend(nil, self, "setCaptureObject:", captureObject)
}
@(objc_type=CaptureDescriptor, objc_name="setDestination")
CaptureDescriptor_setDestination :: proc(self: ^CaptureDescriptor, destination: CaptureDestination) {
	msgSend(nil, self, "setDestination:", destination)
}
@(objc_type=CaptureDescriptor, objc_name="setOutputURL")
CaptureDescriptor_setOutputURL :: proc(self: ^CaptureDescriptor, outputURL: ^NS.URL) {
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
CaptureManager_alloc :: proc() -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "alloc")
}
@(objc_type=CaptureManager, objc_name="defaultCaptureScope")
CaptureManager_defaultCaptureScope :: proc(self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "defaultCaptureScope")
}
@(objc_type=CaptureManager, objc_name="init")
CaptureManager_init :: proc(self: ^CaptureManager) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "init")
}
@(objc_type=CaptureManager, objc_name="isCapturing")
CaptureManager_isCapturing :: proc(self: ^CaptureManager) -> BOOL {
	return msgSend(BOOL, self, "isCapturing")
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithCommandQueue")
CaptureManager_newCaptureScopeWithCommandQueue :: proc(self: ^CaptureManager, commandQueue: ^NS.Object) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "newCaptureScopeWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="newCaptureScopeWithDevice")
CaptureManager_newCaptureScopeWithDevice :: proc(self: ^CaptureManager, device: ^NS.Object) -> ^CaptureManager {
	return msgSend(^CaptureManager, self, "newCaptureScopeWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="setDefaultCaptureScope")
CaptureManager_setDefaultCaptureScope :: proc(self: ^CaptureManager, defaultCaptureScope: ^NS.Object) {
	msgSend(nil, self, "setDefaultCaptureScope:", defaultCaptureScope)
}
@(objc_type=CaptureManager, objc_class_name="sharedCaptureManager")
CaptureManager_sharedCaptureManager :: proc() -> ^CaptureManager {
	return msgSend(^CaptureManager, CaptureManager, "sharedCaptureManager")
}
@(objc_type=CaptureManager, objc_name="startCaptureWithCommandQueue")
CaptureManager_startCaptureWithCommandQueue :: proc(self: ^CaptureManager, commandQueue: ^NS.Object) {
	msgSend(nil, self, "startCaptureWithCommandQueue:", commandQueue)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDescriptor")
CaptureManager_startCaptureWithDescriptor :: proc(self: ^CaptureManager, descriptor: ^CaptureDescriptor, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "startCaptureWithDescriptor:error:", descriptor, error)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithDevice")
CaptureManager_startCaptureWithDevice :: proc(self: ^CaptureManager, device: ^NS.Object) {
	msgSend(nil, self, "startCaptureWithDevice:", device)
}
@(objc_type=CaptureManager, objc_name="startCaptureWithScope")
CaptureManager_startCaptureWithScope :: proc(self: ^CaptureManager, captureScope: ^NS.Object) {
	msgSend(nil, self, "startCaptureWithScope:", captureScope)
}
@(objc_type=CaptureManager, objc_name="stopCapture")
CaptureManager_stopCapture :: proc(self: ^CaptureManager) {
	msgSend(nil, self, "stopCapture")
}
@(objc_type=CaptureManager, objc_name="supportsDestination")
CaptureManager_supportsDestination :: proc(self: ^CaptureManager, destination: CaptureDestination) -> BOOL {
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
CommandBufferDescriptor_alloc :: proc() -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, CommandBufferDescriptor, "alloc")
}
@(objc_type=CommandBufferDescriptor, objc_name="init")
CommandBufferDescriptor_init :: proc(self: ^CommandBufferDescriptor) -> ^CommandBufferDescriptor {
	return msgSend(^CommandBufferDescriptor, self, "init")
}
@(objc_type=CommandBufferDescriptor, objc_name="errorOptions")
CommandBufferDescriptor_errorOptions :: proc(self: ^CommandBufferDescriptor) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBufferDescriptor, objc_name="retainedReferences")
CommandBufferDescriptor_retainedReferences :: proc(self: ^CommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBufferDescriptor, objc_name="setErrorOptions")
CommandBufferDescriptor_setErrorOptions :: proc(self: ^CommandBufferDescriptor, errorOptions: CommandBufferErrorOption) {
	msgSend(nil, self, "setErrorOptions:", errorOptions)
}
@(objc_type=CommandBufferDescriptor, objc_name="setRetainedReferences")
CommandBufferDescriptor_setRetainedReferences :: proc(self: ^CommandBufferDescriptor, retainedReferences: BOOL) {
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
CompileOptions_alloc :: proc() -> ^CompileOptions {
	return msgSend(^CompileOptions, CompileOptions, "alloc")
}
@(objc_type=CompileOptions, objc_name="init")
CompileOptions_init :: proc(self: ^CompileOptions) -> ^CompileOptions {
	return msgSend(^CompileOptions, self, "init")
}
@(objc_type=CompileOptions, objc_name="fastMathEnabled")
CompileOptions_fastMathEnabled :: proc(self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "fastMathEnabled")
}
@(objc_type=CompileOptions, objc_name="installName")
CompileOptions_installName :: proc(self: ^CompileOptions) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=CompileOptions, objc_name="languageVersion")
CompileOptions_languageVersion :: proc(self: ^CompileOptions) -> LanguageVersion {
	return msgSend(LanguageVersion, self, "languageVersion")
}
@(objc_type=CompileOptions, objc_name="libraries")
CompileOptions_libraries :: proc(self: ^CompileOptions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "libraries")
}
@(objc_type=CompileOptions, objc_name="libraryType")
CompileOptions_libraryType :: proc(self: ^CompileOptions) -> LibraryType {
	return msgSend(LibraryType, self, "libraryType")
}
@(objc_type=CompileOptions, objc_name="preprocessorMacros")
CompileOptions_preprocessorMacros :: proc(self: ^CompileOptions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "preprocessorMacros")
}
@(objc_type=CompileOptions, objc_name="preserveInvariance")
CompileOptions_preserveInvariance :: proc(self: ^CompileOptions) -> BOOL {
	return msgSend(BOOL, self, "preserveInvariance")
}
@(objc_type=CompileOptions, objc_name="setFastMathEnabled")
CompileOptions_setFastMathEnabled :: proc(self: ^CompileOptions, fastMathEnabled: BOOL) {
	msgSend(nil, self, "setFastMathEnabled:", fastMathEnabled)
}
@(objc_type=CompileOptions, objc_name="setInstallName")
CompileOptions_setInstallName :: proc(self: ^CompileOptions, installName: ^NS.String) {
	msgSend(nil, self, "setInstallName:", installName)
}
@(objc_type=CompileOptions, objc_name="setLanguageVersion")
CompileOptions_setLanguageVersion :: proc(self: ^CompileOptions, languageVersion: LanguageVersion) {
	msgSend(nil, self, "setLanguageVersion:", languageVersion)
}
@(objc_type=CompileOptions, objc_name="setLibraries")
CompileOptions_setLibraries :: proc(self: ^CompileOptions, libraries: ^NS.Array) {
	msgSend(nil, self, "setLibraries:", libraries)
}
@(objc_type=CompileOptions, objc_name="setLibraryType")
CompileOptions_setLibraryType :: proc(self: ^CompileOptions, libraryType: LibraryType) {
	msgSend(nil, self, "setLibraryType:", libraryType)
}
@(objc_type=CompileOptions, objc_name="setPreprocessorMacros")
CompileOptions_setPreprocessorMacros :: proc(self: ^CompileOptions, preprocessorMacros: ^NS.Dictionary) {
	msgSend(nil, self, "setPreprocessorMacros:", preprocessorMacros)
}
@(objc_type=CompileOptions, objc_name="setPreserveInvariance")
CompileOptions_setPreserveInvariance :: proc(self: ^CompileOptions, preserveInvariance: BOOL) {
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
ComputePassDescriptor_alloc :: proc() -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "alloc")
}
@(objc_type=ComputePassDescriptor, objc_name="init")
ComputePassDescriptor_init :: proc(self: ^ComputePassDescriptor) -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, self, "init")
}
@(objc_type=ComputePassDescriptor, objc_class_name="computePassDescriptor")
ComputePassDescriptor_computePassDescriptor :: proc() -> ^ComputePassDescriptor {
	return msgSend(^ComputePassDescriptor, ComputePassDescriptor, "computePassDescriptor")
}
@(objc_type=ComputePassDescriptor, objc_name="dispatchType")
ComputePassDescriptor_dispatchType :: proc(self: ^ComputePassDescriptor) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputePassDescriptor, objc_name="sampleBufferAttachments")
ComputePassDescriptor_sampleBufferAttachments :: proc(self: ^ComputePassDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=ComputePassDescriptor, objc_name="setDispatchType")
ComputePassDescriptor_setDispatchType :: proc(self: ^ComputePassDescriptor, dispatchType: DispatchType) {
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
ComputePassSampleBufferAttachmentDescriptor_alloc :: proc() -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, ComputePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="init")
ComputePassSampleBufferAttachmentDescriptor_init :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "endOfEncoderSampleIndex")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_sampleBuffer :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "sampleBuffer")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ComputePassSampleBufferAttachmentDescriptor_setSampleBuffer :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor, sampleBuffer: ^NS.Object) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ComputePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: proc(self: ^ComputePassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "startOfEncoderSampleIndex")
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
ComputePassSampleBufferAttachmentDescriptorArray_alloc :: proc() -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, ComputePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ComputePassSampleBufferAttachmentDescriptorArray_init :: proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray) -> ^ComputePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
ComputePassSampleBufferAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return msgSend(^ComputePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ComputePassSampleBufferAttachmentDescriptorArray_setObject :: proc(self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachment: ^ComputePassSampleBufferAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
ComputePipelineDescriptor_alloc :: proc() -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, ComputePipelineDescriptor, "alloc")
}
@(objc_type=ComputePipelineDescriptor, objc_name="init")
ComputePipelineDescriptor_init :: proc(self: ^ComputePipelineDescriptor) -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, self, "init")
}
@(objc_type=ComputePipelineDescriptor, objc_name="binaryArchives")
ComputePipelineDescriptor_binaryArchives :: proc(self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=ComputePipelineDescriptor, objc_name="buffers")
ComputePipelineDescriptor_buffers :: proc(self: ^ComputePipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "buffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="computeFunction")
ComputePipelineDescriptor_computeFunction :: proc(self: ^ComputePipelineDescriptor) -> ^ComputePipelineDescriptor {
	return msgSend(^ComputePipelineDescriptor, self, "computeFunction")
}
@(objc_type=ComputePipelineDescriptor, objc_name="insertLibraries")
ComputePipelineDescriptor_insertLibraries :: proc(self: ^ComputePipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "insertLibraries")
}
@(objc_type=ComputePipelineDescriptor, objc_name="label")
ComputePipelineDescriptor_label :: proc(self: ^ComputePipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineDescriptor, objc_name="linkedFunctions")
ComputePipelineDescriptor_linkedFunctions :: proc(self: ^ComputePipelineDescriptor) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "linkedFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxCallStackDepth")
ComputePipelineDescriptor_maxCallStackDepth :: proc(self: ^ComputePipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxCallStackDepth")
}
@(objc_type=ComputePipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_maxTotalThreadsPerThreadgroup :: proc(self: ^ComputePipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineDescriptor, objc_name="reset")
ComputePipelineDescriptor_reset :: proc(self: ^ComputePipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=ComputePipelineDescriptor, objc_name="setBinaryArchives")
ComputePipelineDescriptor_setBinaryArchives :: proc(self: ^ComputePipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setComputeFunction")
ComputePipelineDescriptor_setComputeFunction :: proc(self: ^ComputePipelineDescriptor, computeFunction: ^NS.Object) {
	msgSend(nil, self, "setComputeFunction:", computeFunction)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setInsertLibraries")
ComputePipelineDescriptor_setInsertLibraries :: proc(self: ^ComputePipelineDescriptor, insertLibraries: ^NS.Array) {
	msgSend(nil, self, "setInsertLibraries:", insertLibraries)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLabel")
ComputePipelineDescriptor_setLabel :: proc(self: ^ComputePipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setLinkedFunctions")
ComputePipelineDescriptor_setLinkedFunctions :: proc(self: ^ComputePipelineDescriptor, linkedFunctions: ^LinkedFunctions) {
	msgSend(nil, self, "setLinkedFunctions:", linkedFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxCallStackDepth")
ComputePipelineDescriptor_setMaxCallStackDepth :: proc(self: ^ComputePipelineDescriptor, maxCallStackDepth: NS.Integer) {
	msgSend(nil, self, "setMaxCallStackDepth:", maxCallStackDepth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
ComputePipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: proc(self: ^ComputePipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.Integer) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setStageInputDescriptor")
ComputePipelineDescriptor_setStageInputDescriptor :: proc(self: ^ComputePipelineDescriptor, stageInputDescriptor: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "setStageInputDescriptor:", stageInputDescriptor)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportAddingBinaryFunctions")
ComputePipelineDescriptor_setSupportAddingBinaryFunctions :: proc(self: ^ComputePipelineDescriptor, supportAddingBinaryFunctions: BOOL) {
	msgSend(nil, self, "setSupportAddingBinaryFunctions:", supportAddingBinaryFunctions)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
ComputePipelineDescriptor_setSupportIndirectCommandBuffers :: proc(self: ^ComputePipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=ComputePipelineDescriptor, objc_name="setThreadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_setThreadGroupSizeIsMultipleOfThreadExecutionWidth :: proc(self: ^ComputePipelineDescriptor, threadGroupSizeIsMultipleOfThreadExecutionWidth: BOOL) {
	msgSend(nil, self, "setThreadGroupSizeIsMultipleOfThreadExecutionWidth:", threadGroupSizeIsMultipleOfThreadExecutionWidth)
}
@(objc_type=ComputePipelineDescriptor, objc_name="stageInputDescriptor")
ComputePipelineDescriptor_stageInputDescriptor :: proc(self: ^ComputePipelineDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "stageInputDescriptor")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportAddingBinaryFunctions")
ComputePipelineDescriptor_supportAddingBinaryFunctions :: proc(self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportAddingBinaryFunctions")
}
@(objc_type=ComputePipelineDescriptor, objc_name="supportIndirectCommandBuffers")
ComputePipelineDescriptor_supportIndirectCommandBuffers :: proc(self: ^ComputePipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineDescriptor, objc_name="threadGroupSizeIsMultipleOfThreadExecutionWidth")
ComputePipelineDescriptor_threadGroupSizeIsMultipleOfThreadExecutionWidth :: proc(self: ^ComputePipelineDescriptor) -> BOOL {
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
ComputePipelineReflection_alloc :: proc() -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, ComputePipelineReflection, "alloc")
}
@(objc_type=ComputePipelineReflection, objc_name="init")
ComputePipelineReflection_init :: proc(self: ^ComputePipelineReflection) -> ^ComputePipelineReflection {
	return msgSend(^ComputePipelineReflection, self, "init")
}
@(objc_type=ComputePipelineReflection, objc_name="arguments")
ComputePipelineReflection_arguments :: proc(self: ^ComputePipelineReflection) -> ^NS.Array {
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
CounterSampleBufferDescriptor_alloc :: proc() -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, CounterSampleBufferDescriptor, "alloc")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="init")
CounterSampleBufferDescriptor_init :: proc(self: ^CounterSampleBufferDescriptor) -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, self, "init")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="counterSet")
CounterSampleBufferDescriptor_counterSet :: proc(self: ^CounterSampleBufferDescriptor) -> ^CounterSampleBufferDescriptor {
	return msgSend(^CounterSampleBufferDescriptor, self, "counterSet")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="label")
CounterSampleBufferDescriptor_label :: proc(self: ^CounterSampleBufferDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="sampleCount")
CounterSampleBufferDescriptor_sampleCount :: proc(self: ^CounterSampleBufferDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "sampleCount")
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setCounterSet")
CounterSampleBufferDescriptor_setCounterSet :: proc(self: ^CounterSampleBufferDescriptor, counterSet: ^NS.Object) {
	msgSend(nil, self, "setCounterSet:", counterSet)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setLabel")
CounterSampleBufferDescriptor_setLabel :: proc(self: ^CounterSampleBufferDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setSampleCount")
CounterSampleBufferDescriptor_setSampleCount :: proc(self: ^CounterSampleBufferDescriptor, sampleCount: NS.Integer) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="setStorageMode")
CounterSampleBufferDescriptor_setStorageMode :: proc(self: ^CounterSampleBufferDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=CounterSampleBufferDescriptor, objc_name="storageMode")
CounterSampleBufferDescriptor_storageMode :: proc(self: ^CounterSampleBufferDescriptor) -> StorageMode {
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
DepthStencilDescriptor_alloc :: proc() -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, DepthStencilDescriptor, "alloc")
}
@(objc_type=DepthStencilDescriptor, objc_name="init")
DepthStencilDescriptor_init :: proc(self: ^DepthStencilDescriptor) -> ^DepthStencilDescriptor {
	return msgSend(^DepthStencilDescriptor, self, "init")
}
@(objc_type=DepthStencilDescriptor, objc_name="backFaceStencil")
DepthStencilDescriptor_backFaceStencil :: proc(self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "backFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="depthCompareFunction")
DepthStencilDescriptor_depthCompareFunction :: proc(self: ^DepthStencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "depthCompareFunction")
}
@(objc_type=DepthStencilDescriptor, objc_name="frontFaceStencil")
DepthStencilDescriptor_frontFaceStencil :: proc(self: ^DepthStencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "frontFaceStencil")
}
@(objc_type=DepthStencilDescriptor, objc_name="isDepthWriteEnabled")
DepthStencilDescriptor_isDepthWriteEnabled :: proc(self: ^DepthStencilDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isDepthWriteEnabled")
}
@(objc_type=DepthStencilDescriptor, objc_name="label")
DepthStencilDescriptor_label :: proc(self: ^DepthStencilDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DepthStencilDescriptor, objc_name="setBackFaceStencil")
DepthStencilDescriptor_setBackFaceStencil :: proc(self: ^DepthStencilDescriptor, backFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setBackFaceStencil:", backFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthCompareFunction")
DepthStencilDescriptor_setDepthCompareFunction :: proc(self: ^DepthStencilDescriptor, depthCompareFunction: CompareFunction) {
	msgSend(nil, self, "setDepthCompareFunction:", depthCompareFunction)
}
@(objc_type=DepthStencilDescriptor, objc_name="setDepthWriteEnabled")
DepthStencilDescriptor_setDepthWriteEnabled :: proc(self: ^DepthStencilDescriptor, depthWriteEnabled: BOOL) {
	msgSend(nil, self, "setDepthWriteEnabled:", depthWriteEnabled)
}
@(objc_type=DepthStencilDescriptor, objc_name="setFrontFaceStencil")
DepthStencilDescriptor_setFrontFaceStencil :: proc(self: ^DepthStencilDescriptor, frontFaceStencil: ^StencilDescriptor) {
	msgSend(nil, self, "setFrontFaceStencil:", frontFaceStencil)
}
@(objc_type=DepthStencilDescriptor, objc_name="setLabel")
DepthStencilDescriptor_setLabel :: proc(self: ^DepthStencilDescriptor, label: ^NS.String) {
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
FunctionConstant_alloc :: proc() -> ^FunctionConstant {
	return msgSend(^FunctionConstant, FunctionConstant, "alloc")
}
@(objc_type=FunctionConstant, objc_name="init")
FunctionConstant_init :: proc(self: ^FunctionConstant) -> ^FunctionConstant {
	return msgSend(^FunctionConstant, self, "init")
}
@(objc_type=FunctionConstant, objc_name="index")
FunctionConstant_index :: proc(self: ^FunctionConstant) -> NS.Integer {
	return msgSend(NS.Integer, self, "index")
}
@(objc_type=FunctionConstant, objc_name="name")
FunctionConstant_name :: proc(self: ^FunctionConstant) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionConstant, objc_name="required")
FunctionConstant_required :: proc(self: ^FunctionConstant) -> BOOL {
	return msgSend(BOOL, self, "required")
}
@(objc_type=FunctionConstant, objc_name="type")
FunctionConstant_type :: proc(self: ^FunctionConstant) -> DataType {
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
FunctionConstantValues_alloc :: proc() -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, FunctionConstantValues, "alloc")
}
@(objc_type=FunctionConstantValues, objc_name="init")
FunctionConstantValues_init :: proc(self: ^FunctionConstantValues) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "init")
}
@(objc_type=FunctionConstantValues, objc_name="reset")
FunctionConstantValues_reset :: proc(self: ^FunctionConstantValues) {
	msgSend(nil, self, "reset")
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValue_type_atIndex_")
FunctionConstantValues_setConstantValue_type_atIndex_ :: proc(self: ^FunctionConstantValues, value: rawptr, type: DataType, index: ^NS.Object) {
	msgSend(nil, self, "setConstantValue:type:atIndex:", value, type, index)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValue_type_withName_")
FunctionConstantValues_setConstantValue_type_withName_ :: proc(self: ^FunctionConstantValues, value: rawptr, type: DataType, name: ^NS.String) {
	msgSend(nil, self, "setConstantValue:type:withName:", value, type, name)
}
@(objc_type=FunctionConstantValues, objc_name="setConstantValues")
FunctionConstantValues_setConstantValues :: proc(self: ^FunctionConstantValues, values: rawptr, type: DataType, range: NS.Range) {
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
FunctionDescriptor_alloc :: proc() -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "alloc")
}
@(objc_type=FunctionDescriptor, objc_name="init")
FunctionDescriptor_init :: proc(self: ^FunctionDescriptor) -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, self, "init")
}
@(objc_type=FunctionDescriptor, objc_name="constantValues")
FunctionDescriptor_constantValues :: proc(self: ^FunctionDescriptor) -> ^FunctionConstantValues {
	return msgSend(^FunctionConstantValues, self, "constantValues")
}
@(objc_type=FunctionDescriptor, objc_class_name="functionDescriptor")
FunctionDescriptor_functionDescriptor :: proc() -> ^FunctionDescriptor {
	return msgSend(^FunctionDescriptor, FunctionDescriptor, "functionDescriptor")
}
@(objc_type=FunctionDescriptor, objc_name="name")
FunctionDescriptor_name :: proc(self: ^FunctionDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=FunctionDescriptor, objc_name="options")
FunctionDescriptor_options :: proc(self: ^FunctionDescriptor) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=FunctionDescriptor, objc_name="setConstantValues")
FunctionDescriptor_setConstantValues :: proc(self: ^FunctionDescriptor, constantValues: ^FunctionConstantValues) {
	msgSend(nil, self, "setConstantValues:", constantValues)
}
@(objc_type=FunctionDescriptor, objc_name="setName")
FunctionDescriptor_setName :: proc(self: ^FunctionDescriptor, name: ^NS.String) {
	msgSend(nil, self, "setName:", name)
}
@(objc_type=FunctionDescriptor, objc_name="setOptions")
FunctionDescriptor_setOptions :: proc(self: ^FunctionDescriptor, options: FunctionOptions) {
	msgSend(nil, self, "setOptions:", options)
}
@(objc_type=FunctionDescriptor, objc_name="setSpecializedName")
FunctionDescriptor_setSpecializedName :: proc(self: ^FunctionDescriptor, specializedName: ^NS.String) {
	msgSend(nil, self, "setSpecializedName:", specializedName)
}
@(objc_type=FunctionDescriptor, objc_name="specializedName")
FunctionDescriptor_specializedName :: proc(self: ^FunctionDescriptor) -> ^NS.String {
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
IntersectionFunctionDescriptor_alloc :: proc() -> ^IntersectionFunctionDescriptor {
	return msgSend(^IntersectionFunctionDescriptor, IntersectionFunctionDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionDescriptor, objc_name="init")
IntersectionFunctionDescriptor_init :: proc(self: ^IntersectionFunctionDescriptor) -> ^IntersectionFunctionDescriptor {
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
HeapDescriptor_alloc :: proc() -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, HeapDescriptor, "alloc")
}
@(objc_type=HeapDescriptor, objc_name="init")
HeapDescriptor_init :: proc(self: ^HeapDescriptor) -> ^HeapDescriptor {
	return msgSend(^HeapDescriptor, self, "init")
}
@(objc_type=HeapDescriptor, objc_name="cpuCacheMode")
HeapDescriptor_cpuCacheMode :: proc(self: ^HeapDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=HeapDescriptor, objc_name="hazardTrackingMode")
HeapDescriptor_hazardTrackingMode :: proc(self: ^HeapDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=HeapDescriptor, objc_name="resourceOptions")
HeapDescriptor_resourceOptions :: proc(self: ^HeapDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=HeapDescriptor, objc_name="setCpuCacheMode")
HeapDescriptor_setCpuCacheMode :: proc(self: ^HeapDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}
@(objc_type=HeapDescriptor, objc_name="setHazardTrackingMode")
HeapDescriptor_setHazardTrackingMode :: proc(self: ^HeapDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=HeapDescriptor, objc_name="setResourceOptions")
HeapDescriptor_setResourceOptions :: proc(self: ^HeapDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=HeapDescriptor, objc_name="setSize")
HeapDescriptor_setSize :: proc(self: ^HeapDescriptor, size: NS.Integer) {
	msgSend(nil, self, "setSize:", size)
}
@(objc_type=HeapDescriptor, objc_name="setStorageMode")
HeapDescriptor_setStorageMode :: proc(self: ^HeapDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=HeapDescriptor, objc_name="setType")
HeapDescriptor_setType :: proc(self: ^HeapDescriptor, type: HeapType) {
	msgSend(nil, self, "setType:", type)
}
@(objc_type=HeapDescriptor, objc_name="size")
HeapDescriptor_size :: proc(self: ^HeapDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "size")
}
@(objc_type=HeapDescriptor, objc_name="storageMode")
HeapDescriptor_storageMode :: proc(self: ^HeapDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=HeapDescriptor, objc_name="type")
HeapDescriptor_type :: proc(self: ^HeapDescriptor) -> HeapType {
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
IndirectCommandBufferDescriptor_alloc :: proc() -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, IndirectCommandBufferDescriptor, "alloc")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="init")
IndirectCommandBufferDescriptor_init :: proc(self: ^IndirectCommandBufferDescriptor) -> ^IndirectCommandBufferDescriptor {
	return msgSend(^IndirectCommandBufferDescriptor, self, "init")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="commandTypes")
IndirectCommandBufferDescriptor_commandTypes :: proc(self: ^IndirectCommandBufferDescriptor) -> IndirectCommandType {
	return msgSend(IndirectCommandType, self, "commandTypes")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritBuffers")
IndirectCommandBufferDescriptor_inheritBuffers :: proc(self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritBuffers")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="inheritPipelineState")
IndirectCommandBufferDescriptor_inheritPipelineState :: proc(self: ^IndirectCommandBufferDescriptor) -> BOOL {
	return msgSend(BOOL, self, "inheritPipelineState")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_maxFragmentBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxFragmentBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxKernelBufferBindCount")
IndirectCommandBufferDescriptor_maxKernelBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxKernelBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="maxVertexBufferBindCount")
IndirectCommandBufferDescriptor_maxVertexBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxVertexBufferBindCount")
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setCommandTypes")
IndirectCommandBufferDescriptor_setCommandTypes :: proc(self: ^IndirectCommandBufferDescriptor, commandTypes: IndirectCommandType) {
	msgSend(nil, self, "setCommandTypes:", commandTypes)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritBuffers")
IndirectCommandBufferDescriptor_setInheritBuffers :: proc(self: ^IndirectCommandBufferDescriptor, inheritBuffers: BOOL) {
	msgSend(nil, self, "setInheritBuffers:", inheritBuffers)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setInheritPipelineState")
IndirectCommandBufferDescriptor_setInheritPipelineState :: proc(self: ^IndirectCommandBufferDescriptor, inheritPipelineState: BOOL) {
	msgSend(nil, self, "setInheritPipelineState:", inheritPipelineState)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxFragmentBufferBindCount")
IndirectCommandBufferDescriptor_setMaxFragmentBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor, maxFragmentBufferBindCount: NS.Integer) {
	msgSend(nil, self, "setMaxFragmentBufferBindCount:", maxFragmentBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxKernelBufferBindCount")
IndirectCommandBufferDescriptor_setMaxKernelBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor, maxKernelBufferBindCount: NS.Integer) {
	msgSend(nil, self, "setMaxKernelBufferBindCount:", maxKernelBufferBindCount)
}
@(objc_type=IndirectCommandBufferDescriptor, objc_name="setMaxVertexBufferBindCount")
IndirectCommandBufferDescriptor_setMaxVertexBufferBindCount :: proc(self: ^IndirectCommandBufferDescriptor, maxVertexBufferBindCount: NS.Integer) {
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
InstanceAccelerationStructureDescriptor :: struct { using _: NS.Copying(InstanceAccelerationStructureDescriptor) }

@(objc_type=InstanceAccelerationStructureDescriptor, objc_class_name="alloc")
InstanceAccelerationStructureDescriptor_alloc :: proc() -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "alloc")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="init")
InstanceAccelerationStructureDescriptor_init :: proc(self: ^InstanceAccelerationStructureDescriptor) -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, self, "init")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_class_name="descriptor")
InstanceAccelerationStructureDescriptor_descriptor :: proc() -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, InstanceAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceCount")
InstanceAccelerationStructureDescriptor_instanceCount :: proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "instanceCount")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_instanceDescriptorBuffer :: proc(self: ^InstanceAccelerationStructureDescriptor) -> ^InstanceAccelerationStructureDescriptor {
	return msgSend(^InstanceAccelerationStructureDescriptor, self, "instanceDescriptorBuffer")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_instanceDescriptorBufferOffset :: proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "instanceDescriptorBufferOffset")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instanceDescriptorStride")
InstanceAccelerationStructureDescriptor_instanceDescriptorStride :: proc(self: ^InstanceAccelerationStructureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "instanceDescriptorStride")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="instancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_instancedAccelerationStructures :: proc(self: ^InstanceAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "instancedAccelerationStructures")
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceCount")
InstanceAccelerationStructureDescriptor_setInstanceCount :: proc(self: ^InstanceAccelerationStructureDescriptor, instanceCount: NS.Integer) {
	msgSend(nil, self, "setInstanceCount:", instanceCount)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBuffer")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBuffer :: proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBuffer: ^NS.Object) {
	msgSend(nil, self, "setInstanceDescriptorBuffer:", instanceDescriptorBuffer)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorBufferOffset")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorBufferOffset :: proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorBufferOffset: NS.Integer) {
	msgSend(nil, self, "setInstanceDescriptorBufferOffset:", instanceDescriptorBufferOffset)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstanceDescriptorStride")
InstanceAccelerationStructureDescriptor_setInstanceDescriptorStride :: proc(self: ^InstanceAccelerationStructureDescriptor, instanceDescriptorStride: NS.Integer) {
	msgSend(nil, self, "setInstanceDescriptorStride:", instanceDescriptorStride)
}
@(objc_type=InstanceAccelerationStructureDescriptor, objc_name="setInstancedAccelerationStructures")
InstanceAccelerationStructureDescriptor_setInstancedAccelerationStructures :: proc(self: ^InstanceAccelerationStructureDescriptor, instancedAccelerationStructures: ^NS.Array) {
	msgSend(nil, self, "setInstancedAccelerationStructures:", instancedAccelerationStructures)
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
IntersectionFunctionTableDescriptor_alloc :: proc() -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "alloc")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="init")
IntersectionFunctionTableDescriptor_init :: proc(self: ^IntersectionFunctionTableDescriptor) -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, self, "init")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="functionCount")
IntersectionFunctionTableDescriptor_functionCount :: proc(self: ^IntersectionFunctionTableDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "functionCount")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_class_name="intersectionFunctionTableDescriptor")
IntersectionFunctionTableDescriptor_intersectionFunctionTableDescriptor :: proc() -> ^IntersectionFunctionTableDescriptor {
	return msgSend(^IntersectionFunctionTableDescriptor, IntersectionFunctionTableDescriptor, "intersectionFunctionTableDescriptor")
}
@(objc_type=IntersectionFunctionTableDescriptor, objc_name="setFunctionCount")
IntersectionFunctionTableDescriptor_setFunctionCount :: proc(self: ^IntersectionFunctionTableDescriptor, functionCount: NS.Integer) {
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
LinkedFunctions_alloc :: proc() -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "alloc")
}
@(objc_type=LinkedFunctions, objc_name="init")
LinkedFunctions_init :: proc(self: ^LinkedFunctions) -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, self, "init")
}
@(objc_type=LinkedFunctions, objc_name="binaryFunctions")
LinkedFunctions_binaryFunctions :: proc(self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryFunctions")
}
@(objc_type=LinkedFunctions, objc_name="functions")
LinkedFunctions_functions :: proc(self: ^LinkedFunctions) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functions")
}
@(objc_type=LinkedFunctions, objc_name="groups")
LinkedFunctions_groups :: proc(self: ^LinkedFunctions) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "groups")
}
@(objc_type=LinkedFunctions, objc_class_name="linkedFunctions")
LinkedFunctions_linkedFunctions :: proc() -> ^LinkedFunctions {
	return msgSend(^LinkedFunctions, LinkedFunctions, "linkedFunctions")
}
@(objc_type=LinkedFunctions, objc_name="setBinaryFunctions")
LinkedFunctions_setBinaryFunctions :: proc(self: ^LinkedFunctions, binaryFunctions: ^NS.Array) {
	msgSend(nil, self, "setBinaryFunctions:", binaryFunctions)
}
@(objc_type=LinkedFunctions, objc_name="setFunctions")
LinkedFunctions_setFunctions :: proc(self: ^LinkedFunctions, functions: ^NS.Array) {
	msgSend(nil, self, "setFunctions:", functions)
}
@(objc_type=LinkedFunctions, objc_name="setGroups")
LinkedFunctions_setGroups :: proc(self: ^LinkedFunctions, groups: ^NS.Dictionary) {
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
PipelineBufferDescriptor_alloc :: proc() -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, PipelineBufferDescriptor, "alloc")
}
@(objc_type=PipelineBufferDescriptor, objc_name="init")
PipelineBufferDescriptor_init :: proc(self: ^PipelineBufferDescriptor) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "init")
}
@(objc_type=PipelineBufferDescriptor, objc_name="mutability")
PipelineBufferDescriptor_mutability :: proc(self: ^PipelineBufferDescriptor) -> Mutability {
	return msgSend(Mutability, self, "mutability")
}
@(objc_type=PipelineBufferDescriptor, objc_name="setMutability")
PipelineBufferDescriptor_setMutability :: proc(self: ^PipelineBufferDescriptor, mutability: Mutability) {
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
PipelineBufferDescriptorArray_alloc :: proc() -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, PipelineBufferDescriptorArray, "alloc")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="init")
PipelineBufferDescriptorArray_init :: proc(self: ^PipelineBufferDescriptorArray) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "init")
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="objectAtIndexedSubscript")
PipelineBufferDescriptorArray_objectAtIndexedSubscript :: proc(self: ^PipelineBufferDescriptorArray, bufferIndex: ^NS.Object) -> ^PipelineBufferDescriptor {
	return msgSend(^PipelineBufferDescriptor, self, "objectAtIndexedSubscript:", bufferIndex)
}
@(objc_type=PipelineBufferDescriptorArray, objc_name="setObject")
PipelineBufferDescriptorArray_setObject :: proc(self: ^PipelineBufferDescriptorArray, buffer: ^PipelineBufferDescriptor, bufferIndex: ^NS.Object) {
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
PointerType :: struct { using _: NS.Object }

@(objc_type=PointerType, objc_class_name="alloc")
PointerType_alloc :: proc() -> ^PointerType {
	return msgSend(^PointerType, PointerType, "alloc")
}
@(objc_type=PointerType, objc_name="init")
PointerType_init :: proc(self: ^PointerType) -> ^PointerType {
	return msgSend(^PointerType, self, "init")
}
@(objc_type=PointerType, objc_name="access")
PointerType_access :: proc(self: ^PointerType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=PointerType, objc_name="alignment")
PointerType_alignment :: proc(self: ^PointerType) -> NS.Integer {
	return msgSend(NS.Integer, self, "alignment")
}
@(objc_type=PointerType, objc_name="dataSize")
PointerType_dataSize :: proc(self: ^PointerType) -> NS.Integer {
	return msgSend(NS.Integer, self, "dataSize")
}
@(objc_type=PointerType, objc_name="elementArrayType")
PointerType_elementArrayType :: proc(self: ^PointerType) -> ^ArrayType {
	return msgSend(^ArrayType, self, "elementArrayType")
}
@(objc_type=PointerType, objc_name="elementIsArgumentBuffer")
PointerType_elementIsArgumentBuffer :: proc(self: ^PointerType) -> BOOL {
	return msgSend(BOOL, self, "elementIsArgumentBuffer")
}
@(objc_type=PointerType, objc_name="elementStructType")
PointerType_elementStructType :: proc(self: ^PointerType) -> ^StructType {
	return msgSend(^StructType, self, "elementStructType")
}
@(objc_type=PointerType, objc_name="elementType")
PointerType_elementType :: proc(self: ^PointerType) -> DataType {
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
PrimitiveAccelerationStructureDescriptor :: struct { using _: NS.Copying(PrimitiveAccelerationStructureDescriptor) }

@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_class_name="alloc")
PrimitiveAccelerationStructureDescriptor_alloc :: proc() -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "alloc")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="init")
PrimitiveAccelerationStructureDescriptor_init :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, self, "init")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_class_name="descriptor")
PrimitiveAccelerationStructureDescriptor_descriptor :: proc() -> ^PrimitiveAccelerationStructureDescriptor {
	return msgSend(^PrimitiveAccelerationStructureDescriptor, PrimitiveAccelerationStructureDescriptor, "descriptor")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="geometryDescriptors")
PrimitiveAccelerationStructureDescriptor_geometryDescriptors :: proc(self: ^PrimitiveAccelerationStructureDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "geometryDescriptors")
}
@(objc_type=PrimitiveAccelerationStructureDescriptor, objc_name="setGeometryDescriptors")
PrimitiveAccelerationStructureDescriptor_setGeometryDescriptors :: proc(self: ^PrimitiveAccelerationStructureDescriptor, geometryDescriptors: ^NS.Array) {
	msgSend(nil, self, "setGeometryDescriptors:", geometryDescriptors)
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
RasterizationRateLayerArray_alloc :: proc() -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, RasterizationRateLayerArray, "alloc")
}
@(objc_type=RasterizationRateLayerArray, objc_name="init")
RasterizationRateLayerArray_init :: proc(self: ^RasterizationRateLayerArray) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "init")
}
@(objc_type=RasterizationRateLayerArray, objc_name="objectAtIndexedSubscript")
RasterizationRateLayerArray_objectAtIndexedSubscript :: proc(self: ^RasterizationRateLayerArray, layerIndex: ^NS.Object) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "objectAtIndexedSubscript:", layerIndex)
}
@(objc_type=RasterizationRateLayerArray, objc_name="setObject")
RasterizationRateLayerArray_setObject :: proc(self: ^RasterizationRateLayerArray, layer: ^RasterizationRateLayerDescriptor, layerIndex: ^NS.Object) {
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
RasterizationRateLayerDescriptor_alloc :: proc() -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, RasterizationRateLayerDescriptor, "alloc")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontal")
RasterizationRateLayerDescriptor_horizontal :: proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "horizontal")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="horizontalSampleStorage")
RasterizationRateLayerDescriptor_horizontalSampleStorage :: proc(self: ^RasterizationRateLayerDescriptor) -> ^f32 {
	return msgSend(^f32, self, "horizontalSampleStorage")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="init")
RasterizationRateLayerDescriptor_init :: proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "init")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCount")
RasterizationRateLayerDescriptor_initWithSampleCount :: proc(self: ^RasterizationRateLayerDescriptor, sampleCount: Size) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:", sampleCount)
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCountWithDimensions")
RasterizationRateLayerDescriptor_initWithSampleCountWithDimensions :: proc(self: ^RasterizationRateLayerDescriptor, sampleCount: Size, horizontal: ^f32, vertical: ^f32) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:horizontal:vertical:", sampleCount, horizontal, vertical)
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="sampleCount")
RasterizationRateLayerDescriptor_sampleCount :: proc(self: ^RasterizationRateLayerDescriptor) -> Size {
	return msgSend(Size, self, "sampleCount")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="vertical")
RasterizationRateLayerDescriptor_vertical :: proc(self: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "vertical")
}
@(objc_type=RasterizationRateLayerDescriptor, objc_name="verticalSampleStorage")
RasterizationRateLayerDescriptor_verticalSampleStorage :: proc(self: ^RasterizationRateLayerDescriptor) -> ^f32 {
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
RasterizationRateMapDescriptor_alloc :: proc() -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "alloc")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="init")
RasterizationRateMapDescriptor_init :: proc(self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, self, "init")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="label")
RasterizationRateMapDescriptor_label :: proc(self: ^RasterizationRateMapDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layerAtIndex")
RasterizationRateMapDescriptor_layerAtIndex :: proc(self: ^RasterizationRateMapDescriptor, layerIndex: ^NS.Object) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "layerAtIndex:", layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layerCount")
RasterizationRateMapDescriptor_layerCount :: proc(self: ^RasterizationRateMapDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "layerCount")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="layers")
RasterizationRateMapDescriptor_layers :: proc(self: ^RasterizationRateMapDescriptor) -> ^RasterizationRateLayerArray {
	return msgSend(^RasterizationRateLayerArray, self, "layers")
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSize")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSize :: proc(screenSize: Size) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:", screenSize)
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSize_layer_")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSize_layer_ :: proc(screenSize: Size, layer: ^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layer:", screenSize, layer)
}
@(objc_type=RasterizationRateMapDescriptor, objc_class_name="rasterizationRateMapDescriptorWithScreenSize_layerCount_layers_")
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSize_layerCount_layers_ :: proc(screenSize: Size, layerCount: ^NS.Object, layers: ^^RasterizationRateLayerDescriptor ) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layerCount:layers:", screenSize, layerCount, layers)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="screenSize")
RasterizationRateMapDescriptor_screenSize :: proc(self: ^RasterizationRateMapDescriptor) -> Size {
	return msgSend(Size, self, "screenSize")
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLabel")
RasterizationRateMapDescriptor_setLabel :: proc(self: ^RasterizationRateMapDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setLayer")
RasterizationRateMapDescriptor_setLayer :: proc(self: ^RasterizationRateMapDescriptor, layer: ^RasterizationRateLayerDescriptor, layerIndex: ^NS.Object) {
	msgSend(nil, self, "setLayer:atIndex:", layer, layerIndex)
}
@(objc_type=RasterizationRateMapDescriptor, objc_name="setScreenSize")
RasterizationRateMapDescriptor_setScreenSize :: proc(self: ^RasterizationRateMapDescriptor, screenSize: Size) {
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
RasterizationRateSampleArray_alloc :: proc() -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, RasterizationRateSampleArray, "alloc")
}
@(objc_type=RasterizationRateSampleArray, objc_name="init")
RasterizationRateSampleArray_init :: proc(self: ^RasterizationRateSampleArray) -> ^RasterizationRateSampleArray {
	return msgSend(^RasterizationRateSampleArray, self, "init")
}
@(objc_type=RasterizationRateSampleArray, objc_name="objectAtIndexedSubscript")
RasterizationRateSampleArray_objectAtIndexedSubscript :: proc(self: ^RasterizationRateSampleArray, index: ^NS.Object) -> ^NS.Number {
	return msgSend(^NS.Number, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=RasterizationRateSampleArray, objc_name="setObject")
RasterizationRateSampleArray_setObject :: proc(self: ^RasterizationRateSampleArray, value: ^NS.Number, index: ^NS.Object) {
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
RenderPassAttachmentDescriptor_alloc :: proc() -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, RenderPassAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="init")
RenderPassAttachmentDescriptor_init :: proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="depthPlane")
RenderPassAttachmentDescriptor_depthPlane :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "depthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="level")
RenderPassAttachmentDescriptor_level :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "level")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="loadAction")
RenderPassAttachmentDescriptor_loadAction :: proc(self: ^RenderPassAttachmentDescriptor) -> LoadAction {
	return msgSend(LoadAction, self, "loadAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveDepthPlane")
RenderPassAttachmentDescriptor_resolveDepthPlane :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "resolveDepthPlane")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveLevel")
RenderPassAttachmentDescriptor_resolveLevel :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "resolveLevel")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveSlice")
RenderPassAttachmentDescriptor_resolveSlice :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "resolveSlice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="resolveTexture")
RenderPassAttachmentDescriptor_resolveTexture :: proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
	return msgSend(^RenderPassAttachmentDescriptor, self, "resolveTexture")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setDepthPlane")
RenderPassAttachmentDescriptor_setDepthPlane :: proc(self: ^RenderPassAttachmentDescriptor, depthPlane: NS.Integer) {
	msgSend(nil, self, "setDepthPlane:", depthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLevel")
RenderPassAttachmentDescriptor_setLevel :: proc(self: ^RenderPassAttachmentDescriptor, level: NS.Integer) {
	msgSend(nil, self, "setLevel:", level)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setLoadAction")
RenderPassAttachmentDescriptor_setLoadAction :: proc(self: ^RenderPassAttachmentDescriptor, loadAction: LoadAction) {
	msgSend(nil, self, "setLoadAction:", loadAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveDepthPlane")
RenderPassAttachmentDescriptor_setResolveDepthPlane :: proc(self: ^RenderPassAttachmentDescriptor, resolveDepthPlane: NS.Integer) {
	msgSend(nil, self, "setResolveDepthPlane:", resolveDepthPlane)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveLevel")
RenderPassAttachmentDescriptor_setResolveLevel :: proc(self: ^RenderPassAttachmentDescriptor, resolveLevel: NS.Integer) {
	msgSend(nil, self, "setResolveLevel:", resolveLevel)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveSlice")
RenderPassAttachmentDescriptor_setResolveSlice :: proc(self: ^RenderPassAttachmentDescriptor, resolveSlice: NS.Integer) {
	msgSend(nil, self, "setResolveSlice:", resolveSlice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setResolveTexture")
RenderPassAttachmentDescriptor_setResolveTexture :: proc(self: ^RenderPassAttachmentDescriptor, resolveTexture: ^NS.Object) {
	msgSend(nil, self, "setResolveTexture:", resolveTexture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setSlice")
RenderPassAttachmentDescriptor_setSlice :: proc(self: ^RenderPassAttachmentDescriptor, slice: NS.Integer) {
	msgSend(nil, self, "setSlice:", slice)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreAction")
RenderPassAttachmentDescriptor_setStoreAction :: proc(self: ^RenderPassAttachmentDescriptor, storeAction: StoreAction) {
	msgSend(nil, self, "setStoreAction:", storeAction)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setStoreActionOptions")
RenderPassAttachmentDescriptor_setStoreActionOptions :: proc(self: ^RenderPassAttachmentDescriptor, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="setTexture")
RenderPassAttachmentDescriptor_setTexture :: proc(self: ^RenderPassAttachmentDescriptor, texture: ^NS.Object) {
	msgSend(nil, self, "setTexture:", texture)
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="slice")
RenderPassAttachmentDescriptor_slice :: proc(self: ^RenderPassAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "slice")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeAction")
RenderPassAttachmentDescriptor_storeAction :: proc(self: ^RenderPassAttachmentDescriptor) -> StoreAction {
	return msgSend(StoreAction, self, "storeAction")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="storeActionOptions")
RenderPassAttachmentDescriptor_storeActionOptions :: proc(self: ^RenderPassAttachmentDescriptor) -> StoreActionOptions {
	return msgSend(StoreActionOptions, self, "storeActionOptions")
}
@(objc_type=RenderPassAttachmentDescriptor, objc_name="texture")
RenderPassAttachmentDescriptor_texture :: proc(self: ^RenderPassAttachmentDescriptor) -> ^RenderPassAttachmentDescriptor {
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
RenderPassColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassColorAttachmentDescriptor) }

@(objc_type=RenderPassColorAttachmentDescriptor, objc_class_name="alloc")
RenderPassColorAttachmentDescriptor_alloc :: proc() -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, RenderPassColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="init")
RenderPassColorAttachmentDescriptor_init :: proc(self: ^RenderPassColorAttachmentDescriptor) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="clearColor")
RenderPassColorAttachmentDescriptor_clearColor :: proc(self: ^RenderPassColorAttachmentDescriptor) -> ClearColor {
	return msgSend(ClearColor, self, "clearColor")
}
@(objc_type=RenderPassColorAttachmentDescriptor, objc_name="setClearColor")
RenderPassColorAttachmentDescriptor_setClearColor :: proc(self: ^RenderPassColorAttachmentDescriptor, clearColor: ClearColor) {
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
RenderPassColorAttachmentDescriptorArray_alloc :: proc() -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, RenderPassColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="init")
RenderPassColorAttachmentDescriptorArray_init :: proc(self: ^RenderPassColorAttachmentDescriptorArray) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
RenderPassColorAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^RenderPassColorAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^RenderPassColorAttachmentDescriptor {
	return msgSend(^RenderPassColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="setObject")
RenderPassColorAttachmentDescriptorArray_setObject :: proc(self: ^RenderPassColorAttachmentDescriptorArray, attachment: ^RenderPassColorAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
RenderPassDepthAttachmentDescriptor :: struct { using _: NS.Copying(RenderPassDepthAttachmentDescriptor) }

@(objc_type=RenderPassDepthAttachmentDescriptor, objc_class_name="alloc")
RenderPassDepthAttachmentDescriptor_alloc :: proc() -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, RenderPassDepthAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="init")
RenderPassDepthAttachmentDescriptor_init :: proc(self: ^RenderPassDepthAttachmentDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="clearDepth")
RenderPassDepthAttachmentDescriptor_clearDepth :: proc(self: ^RenderPassDepthAttachmentDescriptor) -> f64 {
	return msgSend(f64, self, "clearDepth")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="depthResolveFilter")
RenderPassDepthAttachmentDescriptor_depthResolveFilter :: proc(self: ^RenderPassDepthAttachmentDescriptor) -> MultisampleDepthResolveFilter {
	return msgSend(MultisampleDepthResolveFilter, self, "depthResolveFilter")
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setClearDepth")
RenderPassDepthAttachmentDescriptor_setClearDepth :: proc(self: ^RenderPassDepthAttachmentDescriptor, clearDepth: f64) {
	msgSend(nil, self, "setClearDepth:", clearDepth)
}
@(objc_type=RenderPassDepthAttachmentDescriptor, objc_name="setDepthResolveFilter")
RenderPassDepthAttachmentDescriptor_setDepthResolveFilter :: proc(self: ^RenderPassDepthAttachmentDescriptor, depthResolveFilter: MultisampleDepthResolveFilter) {
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
RenderPassDescriptor :: struct { using _: NS.Copying(RenderPassDescriptor) }

@(objc_type=RenderPassDescriptor, objc_class_name="alloc")
RenderPassDescriptor_alloc :: proc() -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "alloc")
}
@(objc_type=RenderPassDescriptor, objc_name="init")
RenderPassDescriptor_init :: proc(self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "init")
}
@(objc_type=RenderPassDescriptor, objc_name="colorAttachments")
RenderPassDescriptor_colorAttachments :: proc(self: ^RenderPassDescriptor) -> ^RenderPassColorAttachmentDescriptorArray {
	return msgSend(^RenderPassColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="defaultRasterSampleCount")
RenderPassDescriptor_defaultRasterSampleCount :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "defaultRasterSampleCount")
}
@(objc_type=RenderPassDescriptor, objc_name="depthAttachment")
RenderPassDescriptor_depthAttachment :: proc(self: ^RenderPassDescriptor) -> ^RenderPassDepthAttachmentDescriptor {
	return msgSend(^RenderPassDepthAttachmentDescriptor, self, "depthAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="getSamplePositions")
RenderPassDescriptor_getSamplePositions :: proc(self: ^RenderPassDescriptor, positions: ^SamplePosition, count: ^NS.Object) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "getSamplePositions:count:", positions, count)
}
@(objc_type=RenderPassDescriptor, objc_name="imageblockSampleLength")
RenderPassDescriptor_imageblockSampleLength :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "imageblockSampleLength")
}
@(objc_type=RenderPassDescriptor, objc_name="rasterizationRateMap")
RenderPassDescriptor_rasterizationRateMap :: proc(self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "rasterizationRateMap")
}
@(objc_type=RenderPassDescriptor, objc_class_name="renderPassDescriptor")
RenderPassDescriptor_renderPassDescriptor :: proc() -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, RenderPassDescriptor, "renderPassDescriptor")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetArrayLength")
RenderPassDescriptor_renderTargetArrayLength :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "renderTargetArrayLength")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetHeight")
RenderPassDescriptor_renderTargetHeight :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "renderTargetHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="renderTargetWidth")
RenderPassDescriptor_renderTargetWidth :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "renderTargetWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="sampleBufferAttachments")
RenderPassDescriptor_sampleBufferAttachments :: proc(self: ^RenderPassDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "sampleBufferAttachments")
}
@(objc_type=RenderPassDescriptor, objc_name="setDefaultRasterSampleCount")
RenderPassDescriptor_setDefaultRasterSampleCount :: proc(self: ^RenderPassDescriptor, defaultRasterSampleCount: NS.Integer) {
	msgSend(nil, self, "setDefaultRasterSampleCount:", defaultRasterSampleCount)
}
@(objc_type=RenderPassDescriptor, objc_name="setDepthAttachment")
RenderPassDescriptor_setDepthAttachment :: proc(self: ^RenderPassDescriptor, depthAttachment: ^RenderPassDepthAttachmentDescriptor) {
	msgSend(nil, self, "setDepthAttachment:", depthAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setImageblockSampleLength")
RenderPassDescriptor_setImageblockSampleLength :: proc(self: ^RenderPassDescriptor, imageblockSampleLength: NS.Integer) {
	msgSend(nil, self, "setImageblockSampleLength:", imageblockSampleLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRasterizationRateMap")
RenderPassDescriptor_setRasterizationRateMap :: proc(self: ^RenderPassDescriptor, rasterizationRateMap: ^NS.Object) {
	msgSend(nil, self, "setRasterizationRateMap:", rasterizationRateMap)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetArrayLength")
RenderPassDescriptor_setRenderTargetArrayLength :: proc(self: ^RenderPassDescriptor, renderTargetArrayLength: NS.Integer) {
	msgSend(nil, self, "setRenderTargetArrayLength:", renderTargetArrayLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetHeight")
RenderPassDescriptor_setRenderTargetHeight :: proc(self: ^RenderPassDescriptor, renderTargetHeight: NS.Integer) {
	msgSend(nil, self, "setRenderTargetHeight:", renderTargetHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setRenderTargetWidth")
RenderPassDescriptor_setRenderTargetWidth :: proc(self: ^RenderPassDescriptor, renderTargetWidth: NS.Integer) {
	msgSend(nil, self, "setRenderTargetWidth:", renderTargetWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setSamplePositions")
RenderPassDescriptor_setSamplePositions :: proc(self: ^RenderPassDescriptor, positions: ^SamplePosition, count: ^NS.Object) {
	msgSend(nil, self, "setSamplePositions:count:", positions, count)
}
@(objc_type=RenderPassDescriptor, objc_name="setStencilAttachment")
RenderPassDescriptor_setStencilAttachment :: proc(self: ^RenderPassDescriptor, stencilAttachment: ^RenderPassStencilAttachmentDescriptor) {
	msgSend(nil, self, "setStencilAttachment:", stencilAttachment)
}
@(objc_type=RenderPassDescriptor, objc_name="setThreadgroupMemoryLength")
RenderPassDescriptor_setThreadgroupMemoryLength :: proc(self: ^RenderPassDescriptor, threadgroupMemoryLength: NS.Integer) {
	msgSend(nil, self, "setThreadgroupMemoryLength:", threadgroupMemoryLength)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileHeight")
RenderPassDescriptor_setTileHeight :: proc(self: ^RenderPassDescriptor, tileHeight: NS.Integer) {
	msgSend(nil, self, "setTileHeight:", tileHeight)
}
@(objc_type=RenderPassDescriptor, objc_name="setTileWidth")
RenderPassDescriptor_setTileWidth :: proc(self: ^RenderPassDescriptor, tileWidth: NS.Integer) {
	msgSend(nil, self, "setTileWidth:", tileWidth)
}
@(objc_type=RenderPassDescriptor, objc_name="setVisibilityResultBuffer")
RenderPassDescriptor_setVisibilityResultBuffer :: proc(self: ^RenderPassDescriptor, visibilityResultBuffer: ^NS.Object) {
	msgSend(nil, self, "setVisibilityResultBuffer:", visibilityResultBuffer)
}
@(objc_type=RenderPassDescriptor, objc_name="stencilAttachment")
RenderPassDescriptor_stencilAttachment :: proc(self: ^RenderPassDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "stencilAttachment")
}
@(objc_type=RenderPassDescriptor, objc_name="threadgroupMemoryLength")
RenderPassDescriptor_threadgroupMemoryLength :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "threadgroupMemoryLength")
}
@(objc_type=RenderPassDescriptor, objc_name="tileHeight")
RenderPassDescriptor_tileHeight :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "tileHeight")
}
@(objc_type=RenderPassDescriptor, objc_name="tileWidth")
RenderPassDescriptor_tileWidth :: proc(self: ^RenderPassDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "tileWidth")
}
@(objc_type=RenderPassDescriptor, objc_name="visibilityResultBuffer")
RenderPassDescriptor_visibilityResultBuffer :: proc(self: ^RenderPassDescriptor) -> ^RenderPassDescriptor {
	return msgSend(^RenderPassDescriptor, self, "visibilityResultBuffer")
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
RenderPassSampleBufferAttachmentDescriptor_alloc :: proc() -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, RenderPassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="init")
RenderPassSampleBufferAttachmentDescriptor_init :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfFragmentSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "endOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="endOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_endOfVertexSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "endOfVertexSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_sampleBuffer :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "sampleBuffer")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfFragmentSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor, endOfFragmentSampleIndex: NS.Integer) {
	msgSend(nil, self, "setEndOfFragmentSampleIndex:", endOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setEndOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setEndOfVertexSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor, endOfVertexSampleIndex: NS.Integer) {
	msgSend(nil, self, "setEndOfVertexSampleIndex:", endOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
RenderPassSampleBufferAttachmentDescriptor_setSampleBuffer :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor, sampleBuffer: ^NS.Object) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfFragmentSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor, startOfFragmentSampleIndex: NS.Integer) {
	msgSend(nil, self, "setStartOfFragmentSampleIndex:", startOfFragmentSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="setStartOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_setStartOfVertexSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor, startOfVertexSampleIndex: NS.Integer) {
	msgSend(nil, self, "setStartOfVertexSampleIndex:", startOfVertexSampleIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfFragmentSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfFragmentSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "startOfFragmentSampleIndex")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptor, objc_name="startOfVertexSampleIndex")
RenderPassSampleBufferAttachmentDescriptor_startOfVertexSampleIndex :: proc(self: ^RenderPassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "startOfVertexSampleIndex")
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
RenderPassSampleBufferAttachmentDescriptorArray_alloc :: proc() -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, RenderPassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="init")
RenderPassSampleBufferAttachmentDescriptorArray_init :: proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray) -> ^RenderPassSampleBufferAttachmentDescriptorArray {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
RenderPassSampleBufferAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return msgSend(^RenderPassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
RenderPassSampleBufferAttachmentDescriptorArray_setObject :: proc(self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachment: ^RenderPassSampleBufferAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
RenderPassStencilAttachmentDescriptor_alloc :: proc() -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, RenderPassStencilAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="init")
RenderPassStencilAttachmentDescriptor_init :: proc(self: ^RenderPassStencilAttachmentDescriptor) -> ^RenderPassStencilAttachmentDescriptor {
	return msgSend(^RenderPassStencilAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="clearStencil")
RenderPassStencilAttachmentDescriptor_clearStencil :: proc(self: ^RenderPassStencilAttachmentDescriptor) -> u32 {
	return msgSend(u32, self, "clearStencil")
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setClearStencil")
RenderPassStencilAttachmentDescriptor_setClearStencil :: proc(self: ^RenderPassStencilAttachmentDescriptor, clearStencil: u32) {
	msgSend(nil, self, "setClearStencil:", clearStencil)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="setStencilResolveFilter")
RenderPassStencilAttachmentDescriptor_setStencilResolveFilter :: proc(self: ^RenderPassStencilAttachmentDescriptor, stencilResolveFilter: MultisampleStencilResolveFilter) {
	msgSend(nil, self, "setStencilResolveFilter:", stencilResolveFilter)
}
@(objc_type=RenderPassStencilAttachmentDescriptor, objc_name="stencilResolveFilter")
RenderPassStencilAttachmentDescriptor_stencilResolveFilter :: proc(self: ^RenderPassStencilAttachmentDescriptor) -> MultisampleStencilResolveFilter {
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
RenderPipelineColorAttachmentDescriptor :: struct { using _: NS.Copying(RenderPipelineColorAttachmentDescriptor) }

@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_class_name="alloc")
RenderPipelineColorAttachmentDescriptor_alloc :: proc() -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, RenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="init")
RenderPipelineColorAttachmentDescriptor_init :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="alphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_alphaBlendOperation :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "alphaBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationAlphaBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="destinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_destinationRGBBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "destinationRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="isBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_isBlendingEnabled :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isBlendingEnabled")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
RenderPipelineColorAttachmentDescriptor_pixelFormat :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="rgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_rgbBlendOperation :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendOperation {
	return msgSend(BlendOperation, self, "rgbBlendOperation")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setAlphaBlendOperation")
RenderPipelineColorAttachmentDescriptor_setAlphaBlendOperation :: proc(self: ^RenderPipelineColorAttachmentDescriptor, alphaBlendOperation: BlendOperation) {
	msgSend(nil, self, "setAlphaBlendOperation:", alphaBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setBlendingEnabled")
RenderPipelineColorAttachmentDescriptor_setBlendingEnabled :: proc(self: ^RenderPipelineColorAttachmentDescriptor, blendingEnabled: BOOL) {
	msgSend(nil, self, "setBlendingEnabled:", blendingEnabled)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationAlphaBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor, destinationAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationAlphaBlendFactor:", destinationAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setDestinationRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setDestinationRGBBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor, destinationRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setDestinationRGBBlendFactor:", destinationRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
RenderPipelineColorAttachmentDescriptor_setPixelFormat :: proc(self: ^RenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setRgbBlendOperation")
RenderPipelineColorAttachmentDescriptor_setRgbBlendOperation :: proc(self: ^RenderPipelineColorAttachmentDescriptor, rgbBlendOperation: BlendOperation) {
	msgSend(nil, self, "setRgbBlendOperation:", rgbBlendOperation)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceAlphaBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor, sourceAlphaBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceAlphaBlendFactor:", sourceAlphaBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setSourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_setSourceRGBBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor, sourceRGBBlendFactor: BlendFactor) {
	msgSend(nil, self, "setSourceRGBBlendFactor:", sourceRGBBlendFactor)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="setWriteMask")
RenderPipelineColorAttachmentDescriptor_setWriteMask :: proc(self: ^RenderPipelineColorAttachmentDescriptor, writeMask: ColorWriteMask) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceAlphaBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceAlphaBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceAlphaBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="sourceRGBBlendFactor")
RenderPipelineColorAttachmentDescriptor_sourceRGBBlendFactor :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> BlendFactor {
	return msgSend(BlendFactor, self, "sourceRGBBlendFactor")
}
@(objc_type=RenderPipelineColorAttachmentDescriptor, objc_name="writeMask")
RenderPipelineColorAttachmentDescriptor_writeMask :: proc(self: ^RenderPipelineColorAttachmentDescriptor) -> ColorWriteMask {
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
RenderPipelineColorAttachmentDescriptorArray_alloc :: proc() -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, RenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="init")
RenderPipelineColorAttachmentDescriptorArray_init :: proc(self: ^RenderPipelineColorAttachmentDescriptorArray) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
RenderPipelineColorAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^RenderPipelineColorAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^RenderPipelineColorAttachmentDescriptor {
	return msgSend(^RenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
RenderPipelineColorAttachmentDescriptorArray_setObject :: proc(self: ^RenderPipelineColorAttachmentDescriptorArray, attachment: ^RenderPipelineColorAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
RenderPipelineDescriptor_alloc :: proc() -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, RenderPipelineDescriptor, "alloc")
}
@(objc_type=RenderPipelineDescriptor, objc_name="init")
RenderPipelineDescriptor_init :: proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "init")
}
@(objc_type=RenderPipelineDescriptor, objc_name="binaryArchives")
RenderPipelineDescriptor_binaryArchives :: proc(self: ^RenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=RenderPipelineDescriptor, objc_name="colorAttachments")
RenderPipelineDescriptor_colorAttachments :: proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^RenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=RenderPipelineDescriptor, objc_name="depthAttachmentPixelFormat")
RenderPipelineDescriptor_depthAttachmentPixelFormat :: proc(self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "depthAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentBuffers")
RenderPipelineDescriptor_fragmentBuffers :: proc(self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "fragmentBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="fragmentFunction")
RenderPipelineDescriptor_fragmentFunction :: proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
	return msgSend(^RenderPipelineDescriptor, self, "fragmentFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="inputPrimitiveTopology")
RenderPipelineDescriptor_inputPrimitiveTopology :: proc(self: ^RenderPipelineDescriptor) -> PrimitiveTopologyClass {
	return msgSend(PrimitiveTopologyClass, self, "inputPrimitiveTopology")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToCoverageEnabled")
RenderPipelineDescriptor_isAlphaToCoverageEnabled :: proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToCoverageEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isAlphaToOneEnabled")
RenderPipelineDescriptor_isAlphaToOneEnabled :: proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isAlphaToOneEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isRasterizationEnabled")
RenderPipelineDescriptor_isRasterizationEnabled :: proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isRasterizationEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="isTessellationFactorScaleEnabled")
RenderPipelineDescriptor_isTessellationFactorScaleEnabled :: proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "isTessellationFactorScaleEnabled")
}
@(objc_type=RenderPipelineDescriptor, objc_name="label")
RenderPipelineDescriptor_label :: proc(self: ^RenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxTessellationFactor")
RenderPipelineDescriptor_maxTessellationFactor :: proc(self: ^RenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxTessellationFactor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="maxVertexAmplificationCount")
RenderPipelineDescriptor_maxVertexAmplificationCount :: proc(self: ^RenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxVertexAmplificationCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="rasterSampleCount")
RenderPipelineDescriptor_rasterSampleCount :: proc(self: ^RenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "rasterSampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="reset")
RenderPipelineDescriptor_reset :: proc(self: ^RenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=RenderPipelineDescriptor, objc_name="sampleCount")
RenderPipelineDescriptor_sampleCount :: proc(self: ^RenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "sampleCount")
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToCoverageEnabled")
RenderPipelineDescriptor_setAlphaToCoverageEnabled :: proc(self: ^RenderPipelineDescriptor, alphaToCoverageEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToCoverageEnabled:", alphaToCoverageEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setAlphaToOneEnabled")
RenderPipelineDescriptor_setAlphaToOneEnabled :: proc(self: ^RenderPipelineDescriptor, alphaToOneEnabled: BOOL) {
	msgSend(nil, self, "setAlphaToOneEnabled:", alphaToOneEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setBinaryArchives")
RenderPipelineDescriptor_setBinaryArchives :: proc(self: ^RenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setDepthAttachmentPixelFormat")
RenderPipelineDescriptor_setDepthAttachmentPixelFormat :: proc(self: ^RenderPipelineDescriptor, depthAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setDepthAttachmentPixelFormat:", depthAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setFragmentFunction")
RenderPipelineDescriptor_setFragmentFunction :: proc(self: ^RenderPipelineDescriptor, fragmentFunction: ^NS.Object) {
	msgSend(nil, self, "setFragmentFunction:", fragmentFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setInputPrimitiveTopology")
RenderPipelineDescriptor_setInputPrimitiveTopology :: proc(self: ^RenderPipelineDescriptor, inputPrimitiveTopology: PrimitiveTopologyClass) {
	msgSend(nil, self, "setInputPrimitiveTopology:", inputPrimitiveTopology)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setLabel")
RenderPipelineDescriptor_setLabel :: proc(self: ^RenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxTessellationFactor")
RenderPipelineDescriptor_setMaxTessellationFactor :: proc(self: ^RenderPipelineDescriptor, maxTessellationFactor: NS.Integer) {
	msgSend(nil, self, "setMaxTessellationFactor:", maxTessellationFactor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setMaxVertexAmplificationCount")
RenderPipelineDescriptor_setMaxVertexAmplificationCount :: proc(self: ^RenderPipelineDescriptor, maxVertexAmplificationCount: NS.Integer) {
	msgSend(nil, self, "setMaxVertexAmplificationCount:", maxVertexAmplificationCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterSampleCount")
RenderPipelineDescriptor_setRasterSampleCount :: proc(self: ^RenderPipelineDescriptor, rasterSampleCount: NS.Integer) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setRasterizationEnabled")
RenderPipelineDescriptor_setRasterizationEnabled :: proc(self: ^RenderPipelineDescriptor, rasterizationEnabled: BOOL) {
	msgSend(nil, self, "setRasterizationEnabled:", rasterizationEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSampleCount")
RenderPipelineDescriptor_setSampleCount :: proc(self: ^RenderPipelineDescriptor, sampleCount: NS.Integer) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setStencilAttachmentPixelFormat")
RenderPipelineDescriptor_setStencilAttachmentPixelFormat :: proc(self: ^RenderPipelineDescriptor, stencilAttachmentPixelFormat: PixelFormat) {
	msgSend(nil, self, "setStencilAttachmentPixelFormat:", stencilAttachmentPixelFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setSupportIndirectCommandBuffers")
RenderPipelineDescriptor_setSupportIndirectCommandBuffers :: proc(self: ^RenderPipelineDescriptor, supportIndirectCommandBuffers: BOOL) {
	msgSend(nil, self, "setSupportIndirectCommandBuffers:", supportIndirectCommandBuffers)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationControlPointIndexType")
RenderPipelineDescriptor_setTessellationControlPointIndexType :: proc(self: ^RenderPipelineDescriptor, tessellationControlPointIndexType: TessellationControlPointIndexType) {
	msgSend(nil, self, "setTessellationControlPointIndexType:", tessellationControlPointIndexType)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorFormat")
RenderPipelineDescriptor_setTessellationFactorFormat :: proc(self: ^RenderPipelineDescriptor, tessellationFactorFormat: TessellationFactorFormat) {
	msgSend(nil, self, "setTessellationFactorFormat:", tessellationFactorFormat)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorScaleEnabled")
RenderPipelineDescriptor_setTessellationFactorScaleEnabled :: proc(self: ^RenderPipelineDescriptor, tessellationFactorScaleEnabled: BOOL) {
	msgSend(nil, self, "setTessellationFactorScaleEnabled:", tessellationFactorScaleEnabled)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationFactorStepFunction")
RenderPipelineDescriptor_setTessellationFactorStepFunction :: proc(self: ^RenderPipelineDescriptor, tessellationFactorStepFunction: TessellationFactorStepFunction) {
	msgSend(nil, self, "setTessellationFactorStepFunction:", tessellationFactorStepFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationOutputWindingOrder")
RenderPipelineDescriptor_setTessellationOutputWindingOrder :: proc(self: ^RenderPipelineDescriptor, tessellationOutputWindingOrder: Winding) {
	msgSend(nil, self, "setTessellationOutputWindingOrder:", tessellationOutputWindingOrder)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setTessellationPartitionMode")
RenderPipelineDescriptor_setTessellationPartitionMode :: proc(self: ^RenderPipelineDescriptor, tessellationPartitionMode: TessellationPartitionMode) {
	msgSend(nil, self, "setTessellationPartitionMode:", tessellationPartitionMode)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexDescriptor")
RenderPipelineDescriptor_setVertexDescriptor :: proc(self: ^RenderPipelineDescriptor, vertexDescriptor: ^VertexDescriptor) {
	msgSend(nil, self, "setVertexDescriptor:", vertexDescriptor)
}
@(objc_type=RenderPipelineDescriptor, objc_name="setVertexFunction")
RenderPipelineDescriptor_setVertexFunction :: proc(self: ^RenderPipelineDescriptor, vertexFunction: ^NS.Object) {
	msgSend(nil, self, "setVertexFunction:", vertexFunction)
}
@(objc_type=RenderPipelineDescriptor, objc_name="stencilAttachmentPixelFormat")
RenderPipelineDescriptor_stencilAttachmentPixelFormat :: proc(self: ^RenderPipelineDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "stencilAttachmentPixelFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="supportIndirectCommandBuffers")
RenderPipelineDescriptor_supportIndirectCommandBuffers :: proc(self: ^RenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationControlPointIndexType")
RenderPipelineDescriptor_tessellationControlPointIndexType :: proc(self: ^RenderPipelineDescriptor) -> TessellationControlPointIndexType {
	return msgSend(TessellationControlPointIndexType, self, "tessellationControlPointIndexType")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorFormat")
RenderPipelineDescriptor_tessellationFactorFormat :: proc(self: ^RenderPipelineDescriptor) -> TessellationFactorFormat {
	return msgSend(TessellationFactorFormat, self, "tessellationFactorFormat")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationFactorStepFunction")
RenderPipelineDescriptor_tessellationFactorStepFunction :: proc(self: ^RenderPipelineDescriptor) -> TessellationFactorStepFunction {
	return msgSend(TessellationFactorStepFunction, self, "tessellationFactorStepFunction")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationOutputWindingOrder")
RenderPipelineDescriptor_tessellationOutputWindingOrder :: proc(self: ^RenderPipelineDescriptor) -> Winding {
	return msgSend(Winding, self, "tessellationOutputWindingOrder")
}
@(objc_type=RenderPipelineDescriptor, objc_name="tessellationPartitionMode")
RenderPipelineDescriptor_tessellationPartitionMode :: proc(self: ^RenderPipelineDescriptor) -> TessellationPartitionMode {
	return msgSend(TessellationPartitionMode, self, "tessellationPartitionMode")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexBuffers")
RenderPipelineDescriptor_vertexBuffers :: proc(self: ^RenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "vertexBuffers")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexDescriptor")
RenderPipelineDescriptor_vertexDescriptor :: proc(self: ^RenderPipelineDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "vertexDescriptor")
}
@(objc_type=RenderPipelineDescriptor, objc_name="vertexFunction")
RenderPipelineDescriptor_vertexFunction :: proc(self: ^RenderPipelineDescriptor) -> ^RenderPipelineDescriptor {
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
RenderPipelineReflection_alloc :: proc() -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, RenderPipelineReflection, "alloc")
}
@(objc_type=RenderPipelineReflection, objc_name="init")
RenderPipelineReflection_init :: proc(self: ^RenderPipelineReflection) -> ^RenderPipelineReflection {
	return msgSend(^RenderPipelineReflection, self, "init")
}
@(objc_type=RenderPipelineReflection, objc_name="fragmentArguments")
RenderPipelineReflection_fragmentArguments :: proc(self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "fragmentArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="tileArguments")
RenderPipelineReflection_tileArguments :: proc(self: ^RenderPipelineReflection) -> ^NS.Array {
	return msgSend(^NS.Array, self, "tileArguments")
}
@(objc_type=RenderPipelineReflection, objc_name="vertexArguments")
RenderPipelineReflection_vertexArguments :: proc(self: ^RenderPipelineReflection) -> ^NS.Array {
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
ResourceStatePassDescriptor_alloc :: proc() -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "alloc")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="init")
ResourceStatePassDescriptor_init :: proc(self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, self, "init")
}
@(objc_type=ResourceStatePassDescriptor, objc_class_name="resourceStatePassDescriptor")
ResourceStatePassDescriptor_resourceStatePassDescriptor :: proc() -> ^ResourceStatePassDescriptor {
	return msgSend(^ResourceStatePassDescriptor, ResourceStatePassDescriptor, "resourceStatePassDescriptor")
}
@(objc_type=ResourceStatePassDescriptor, objc_name="sampleBufferAttachments")
ResourceStatePassDescriptor_sampleBufferAttachments :: proc(self: ^ResourceStatePassDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
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
ResourceStatePassSampleBufferAttachmentDescriptor_alloc :: proc() -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, ResourceStatePassSampleBufferAttachmentDescriptor, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptor_init :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="endOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_endOfEncoderSampleIndex :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "endOfEncoderSampleIndex")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="sampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_sampleBuffer :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "sampleBuffer")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setEndOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setEndOfEncoderSampleIndex :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, endOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setEndOfEncoderSampleIndex:", endOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setSampleBuffer")
ResourceStatePassSampleBufferAttachmentDescriptor_setSampleBuffer :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, sampleBuffer: ^NS.Object) {
	msgSend(nil, self, "setSampleBuffer:", sampleBuffer)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="setStartOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_setStartOfEncoderSampleIndex :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor, startOfEncoderSampleIndex: NS.Integer) {
	msgSend(nil, self, "setStartOfEncoderSampleIndex:", startOfEncoderSampleIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptor, objc_name="startOfEncoderSampleIndex")
ResourceStatePassSampleBufferAttachmentDescriptor_startOfEncoderSampleIndex :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "startOfEncoderSampleIndex")
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
ResourceStatePassSampleBufferAttachmentDescriptorArray_alloc :: proc() -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, ResourceStatePassSampleBufferAttachmentDescriptorArray, "alloc")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="init")
ResourceStatePassSampleBufferAttachmentDescriptorArray_init :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray) -> ^ResourceStatePassSampleBufferAttachmentDescriptorArray {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptorArray, self, "init")
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
ResourceStatePassSampleBufferAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return msgSend(^ResourceStatePassSampleBufferAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="setObject")
ResourceStatePassSampleBufferAttachmentDescriptorArray_setObject :: proc(self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachment: ^ResourceStatePassSampleBufferAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
SamplerDescriptor_alloc :: proc() -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, SamplerDescriptor, "alloc")
}
@(objc_type=SamplerDescriptor, objc_name="init")
SamplerDescriptor_init :: proc(self: ^SamplerDescriptor) -> ^SamplerDescriptor {
	return msgSend(^SamplerDescriptor, self, "init")
}
@(objc_type=SamplerDescriptor, objc_name="borderColor")
SamplerDescriptor_borderColor :: proc(self: ^SamplerDescriptor) -> SamplerBorderColor {
	return msgSend(SamplerBorderColor, self, "borderColor")
}
@(objc_type=SamplerDescriptor, objc_name="compareFunction")
SamplerDescriptor_compareFunction :: proc(self: ^SamplerDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "compareFunction")
}
@(objc_type=SamplerDescriptor, objc_name="label")
SamplerDescriptor_label :: proc(self: ^SamplerDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=SamplerDescriptor, objc_name="lodAverage")
SamplerDescriptor_lodAverage :: proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "lodAverage")
}
@(objc_type=SamplerDescriptor, objc_name="lodMaxClamp")
SamplerDescriptor_lodMaxClamp :: proc(self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMaxClamp")
}
@(objc_type=SamplerDescriptor, objc_name="lodMinClamp")
SamplerDescriptor_lodMinClamp :: proc(self: ^SamplerDescriptor) -> f32 {
	return msgSend(f32, self, "lodMinClamp")
}
@(objc_type=SamplerDescriptor, objc_name="magFilter")
SamplerDescriptor_magFilter :: proc(self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "magFilter")
}
@(objc_type=SamplerDescriptor, objc_name="maxAnisotropy")
SamplerDescriptor_maxAnisotropy :: proc(self: ^SamplerDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxAnisotropy")
}
@(objc_type=SamplerDescriptor, objc_name="minFilter")
SamplerDescriptor_minFilter :: proc(self: ^SamplerDescriptor) -> SamplerMinMagFilter {
	return msgSend(SamplerMinMagFilter, self, "minFilter")
}
@(objc_type=SamplerDescriptor, objc_name="mipFilter")
SamplerDescriptor_mipFilter :: proc(self: ^SamplerDescriptor) -> SamplerMipFilter {
	return msgSend(SamplerMipFilter, self, "mipFilter")
}
@(objc_type=SamplerDescriptor, objc_name="normalizedCoordinates")
SamplerDescriptor_normalizedCoordinates :: proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "normalizedCoordinates")
}
@(objc_type=SamplerDescriptor, objc_name="rAddressMode")
SamplerDescriptor_rAddressMode :: proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "rAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="sAddressMode")
SamplerDescriptor_sAddressMode :: proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
	return msgSend(SamplerAddressMode, self, "sAddressMode")
}
@(objc_type=SamplerDescriptor, objc_name="setBorderColor")
SamplerDescriptor_setBorderColor :: proc(self: ^SamplerDescriptor, borderColor: SamplerBorderColor) {
	msgSend(nil, self, "setBorderColor:", borderColor)
}
@(objc_type=SamplerDescriptor, objc_name="setCompareFunction")
SamplerDescriptor_setCompareFunction :: proc(self: ^SamplerDescriptor, compareFunction: CompareFunction) {
	msgSend(nil, self, "setCompareFunction:", compareFunction)
}
@(objc_type=SamplerDescriptor, objc_name="setLabel")
SamplerDescriptor_setLabel :: proc(self: ^SamplerDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=SamplerDescriptor, objc_name="setLodAverage")
SamplerDescriptor_setLodAverage :: proc(self: ^SamplerDescriptor, lodAverage: BOOL) {
	msgSend(nil, self, "setLodAverage:", lodAverage)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMaxClamp")
SamplerDescriptor_setLodMaxClamp :: proc(self: ^SamplerDescriptor, lodMaxClamp: f32) {
	msgSend(nil, self, "setLodMaxClamp:", lodMaxClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setLodMinClamp")
SamplerDescriptor_setLodMinClamp :: proc(self: ^SamplerDescriptor, lodMinClamp: f32) {
	msgSend(nil, self, "setLodMinClamp:", lodMinClamp)
}
@(objc_type=SamplerDescriptor, objc_name="setMagFilter")
SamplerDescriptor_setMagFilter :: proc(self: ^SamplerDescriptor, magFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMagFilter:", magFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMaxAnisotropy")
SamplerDescriptor_setMaxAnisotropy :: proc(self: ^SamplerDescriptor, maxAnisotropy: NS.Integer) {
	msgSend(nil, self, "setMaxAnisotropy:", maxAnisotropy)
}
@(objc_type=SamplerDescriptor, objc_name="setMinFilter")
SamplerDescriptor_setMinFilter :: proc(self: ^SamplerDescriptor, minFilter: SamplerMinMagFilter) {
	msgSend(nil, self, "setMinFilter:", minFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setMipFilter")
SamplerDescriptor_setMipFilter :: proc(self: ^SamplerDescriptor, mipFilter: SamplerMipFilter) {
	msgSend(nil, self, "setMipFilter:", mipFilter)
}
@(objc_type=SamplerDescriptor, objc_name="setNormalizedCoordinates")
SamplerDescriptor_setNormalizedCoordinates :: proc(self: ^SamplerDescriptor, normalizedCoordinates: BOOL) {
	msgSend(nil, self, "setNormalizedCoordinates:", normalizedCoordinates)
}
@(objc_type=SamplerDescriptor, objc_name="setRAddressMode")
SamplerDescriptor_setRAddressMode :: proc(self: ^SamplerDescriptor, rAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setRAddressMode:", rAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSAddressMode")
SamplerDescriptor_setSAddressMode :: proc(self: ^SamplerDescriptor, sAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setSAddressMode:", sAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="setSupportArgumentBuffers")
SamplerDescriptor_setSupportArgumentBuffers :: proc(self: ^SamplerDescriptor, supportArgumentBuffers: BOOL) {
	msgSend(nil, self, "setSupportArgumentBuffers:", supportArgumentBuffers)
}
@(objc_type=SamplerDescriptor, objc_name="setTAddressMode")
SamplerDescriptor_setTAddressMode :: proc(self: ^SamplerDescriptor, tAddressMode: SamplerAddressMode) {
	msgSend(nil, self, "setTAddressMode:", tAddressMode)
}
@(objc_type=SamplerDescriptor, objc_name="supportArgumentBuffers")
SamplerDescriptor_supportArgumentBuffers :: proc(self: ^SamplerDescriptor) -> BOOL {
	return msgSend(BOOL, self, "supportArgumentBuffers")
}
@(objc_type=SamplerDescriptor, objc_name="tAddressMode")
SamplerDescriptor_tAddressMode :: proc(self: ^SamplerDescriptor) -> SamplerAddressMode {
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
SharedEventHandle_alloc :: proc() -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, SharedEventHandle, "alloc")
}
@(objc_type=SharedEventHandle, objc_name="init")
SharedEventHandle_init :: proc(self: ^SharedEventHandle) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "init")
}
@(objc_type=SharedEventHandle, objc_name="label")
SharedEventHandle_label :: proc(self: ^SharedEventHandle) -> ^NS.String {
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
SharedEventListener_alloc :: proc() -> ^SharedEventListener {
	return msgSend(^SharedEventListener, SharedEventListener, "alloc")
}
@(objc_type=SharedEventListener, objc_name="dispatchQueue")
SharedEventListener_dispatchQueue :: proc(self: ^SharedEventListener) -> NS.Integer {
	return msgSend(NS.Integer, self, "dispatchQueue")
}
@(objc_type=SharedEventListener, objc_name="init")
SharedEventListener_init :: proc(self: ^SharedEventListener) -> ^SharedEventListener {
	return msgSend(^SharedEventListener, self, "init")
}
@(objc_type=SharedEventListener, objc_name="initWithDispatchQueue")
SharedEventListener_initWithDispatchQueue :: proc(self: ^SharedEventListener, dispatchQueue: ^NS.Object) -> ^SharedEventListener {
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
SharedTextureHandle_alloc :: proc() -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, SharedTextureHandle, "alloc")
}
@(objc_type=SharedTextureHandle, objc_name="init")
SharedTextureHandle_init :: proc(self: ^SharedTextureHandle) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "init")
}
@(objc_type=SharedTextureHandle, objc_name="device")
SharedTextureHandle_device :: proc(self: ^SharedTextureHandle) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "device")
}
@(objc_type=SharedTextureHandle, objc_name="label")
SharedTextureHandle_label :: proc(self: ^SharedTextureHandle) -> ^NS.String {
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
StageInputOutputDescriptor_alloc :: proc() -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, StageInputOutputDescriptor, "alloc")
}
@(objc_type=StageInputOutputDescriptor, objc_name="init")
StageInputOutputDescriptor_init :: proc(self: ^StageInputOutputDescriptor) -> ^StageInputOutputDescriptor {
	return msgSend(^StageInputOutputDescriptor, self, "init")
}
@(objc_type=StageInputOutputDescriptor, objc_name="attributes")
StageInputOutputDescriptor_attributes :: proc(self: ^StageInputOutputDescriptor) -> ^AttributeDescriptorArray {
	return msgSend(^AttributeDescriptorArray, self, "attributes")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexBufferIndex")
StageInputOutputDescriptor_indexBufferIndex :: proc(self: ^StageInputOutputDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "indexBufferIndex")
}
@(objc_type=StageInputOutputDescriptor, objc_name="indexType")
StageInputOutputDescriptor_indexType :: proc(self: ^StageInputOutputDescriptor) -> IndexType {
	return msgSend(IndexType, self, "indexType")
}
@(objc_type=StageInputOutputDescriptor, objc_name="layouts")
StageInputOutputDescriptor_layouts :: proc(self: ^StageInputOutputDescriptor) -> ^BufferLayoutDescriptorArray {
	return msgSend(^BufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=StageInputOutputDescriptor, objc_name="reset")
StageInputOutputDescriptor_reset :: proc(self: ^StageInputOutputDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexBufferIndex")
StageInputOutputDescriptor_setIndexBufferIndex :: proc(self: ^StageInputOutputDescriptor, indexBufferIndex: NS.Integer) {
	msgSend(nil, self, "setIndexBufferIndex:", indexBufferIndex)
}
@(objc_type=StageInputOutputDescriptor, objc_name="setIndexType")
StageInputOutputDescriptor_setIndexType :: proc(self: ^StageInputOutputDescriptor, indexType: IndexType) {
	msgSend(nil, self, "setIndexType:", indexType)
}
@(objc_type=StageInputOutputDescriptor, objc_class_name="stageInputOutputDescriptor")
StageInputOutputDescriptor_stageInputOutputDescriptor :: proc() -> ^StageInputOutputDescriptor {
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
StencilDescriptor_alloc :: proc() -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, StencilDescriptor, "alloc")
}
@(objc_type=StencilDescriptor, objc_name="init")
StencilDescriptor_init :: proc(self: ^StencilDescriptor) -> ^StencilDescriptor {
	return msgSend(^StencilDescriptor, self, "init")
}
@(objc_type=StencilDescriptor, objc_name="depthFailureOperation")
StencilDescriptor_depthFailureOperation :: proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="depthStencilPassOperation")
StencilDescriptor_depthStencilPassOperation :: proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "depthStencilPassOperation")
}
@(objc_type=StencilDescriptor, objc_name="readMask")
StencilDescriptor_readMask :: proc(self: ^StencilDescriptor) -> u32 {
	return msgSend(u32, self, "readMask")
}
@(objc_type=StencilDescriptor, objc_name="setDepthFailureOperation")
StencilDescriptor_setDepthFailureOperation :: proc(self: ^StencilDescriptor, depthFailureOperation: StencilOperation) {
	msgSend(nil, self, "setDepthFailureOperation:", depthFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setDepthStencilPassOperation")
StencilDescriptor_setDepthStencilPassOperation :: proc(self: ^StencilDescriptor, depthStencilPassOperation: StencilOperation) {
	msgSend(nil, self, "setDepthStencilPassOperation:", depthStencilPassOperation)
}
@(objc_type=StencilDescriptor, objc_name="setReadMask")
StencilDescriptor_setReadMask :: proc(self: ^StencilDescriptor, readMask: u32) {
	msgSend(nil, self, "setReadMask:", readMask)
}
@(objc_type=StencilDescriptor, objc_name="setStencilCompareFunction")
StencilDescriptor_setStencilCompareFunction :: proc(self: ^StencilDescriptor, stencilCompareFunction: CompareFunction) {
	msgSend(nil, self, "setStencilCompareFunction:", stencilCompareFunction)
}
@(objc_type=StencilDescriptor, objc_name="setStencilFailureOperation")
StencilDescriptor_setStencilFailureOperation :: proc(self: ^StencilDescriptor, stencilFailureOperation: StencilOperation) {
	msgSend(nil, self, "setStencilFailureOperation:", stencilFailureOperation)
}
@(objc_type=StencilDescriptor, objc_name="setWriteMask")
StencilDescriptor_setWriteMask :: proc(self: ^StencilDescriptor, writeMask: u32) {
	msgSend(nil, self, "setWriteMask:", writeMask)
}
@(objc_type=StencilDescriptor, objc_name="stencilCompareFunction")
StencilDescriptor_stencilCompareFunction :: proc(self: ^StencilDescriptor) -> CompareFunction {
	return msgSend(CompareFunction, self, "stencilCompareFunction")
}
@(objc_type=StencilDescriptor, objc_name="stencilFailureOperation")
StencilDescriptor_stencilFailureOperation :: proc(self: ^StencilDescriptor) -> StencilOperation {
	return msgSend(StencilOperation, self, "stencilFailureOperation")
}
@(objc_type=StencilDescriptor, objc_name="writeMask")
StencilDescriptor_writeMask :: proc(self: ^StencilDescriptor) -> u32 {
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
StructMember_alloc :: proc() -> ^StructMember {
	return msgSend(^StructMember, StructMember, "alloc")
}
@(objc_type=StructMember, objc_name="init")
StructMember_init :: proc(self: ^StructMember) -> ^StructMember {
	return msgSend(^StructMember, self, "init")
}
@(objc_type=StructMember, objc_name="argumentIndex")
StructMember_argumentIndex :: proc(self: ^StructMember) -> NS.Integer {
	return msgSend(NS.Integer, self, "argumentIndex")
}
@(objc_type=StructMember, objc_name="arrayType")
StructMember_arrayType :: proc(self: ^StructMember) -> ^ArrayType {
	return msgSend(^ArrayType, self, "arrayType")
}
@(objc_type=StructMember, objc_name="dataType")
StructMember_dataType :: proc(self: ^StructMember) -> DataType {
	return msgSend(DataType, self, "dataType")
}
@(objc_type=StructMember, objc_name="name")
StructMember_name :: proc(self: ^StructMember) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=StructMember, objc_name="offset")
StructMember_offset :: proc(self: ^StructMember) -> NS.Integer {
	return msgSend(NS.Integer, self, "offset")
}
@(objc_type=StructMember, objc_name="pointerType")
StructMember_pointerType :: proc(self: ^StructMember) -> ^PointerType {
	return msgSend(^PointerType, self, "pointerType")
}
@(objc_type=StructMember, objc_name="structType")
StructMember_structType :: proc(self: ^StructMember) -> ^StructType {
	return msgSend(^StructType, self, "structType")
}
@(objc_type=StructMember, objc_name="textureReferenceType")
StructMember_textureReferenceType :: proc(self: ^StructMember) -> ^TextureReferenceType {
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
StructType :: struct { using _: NS.Object }

@(objc_type=StructType, objc_class_name="alloc")
StructType_alloc :: proc() -> ^StructType {
	return msgSend(^StructType, StructType, "alloc")
}
@(objc_type=StructType, objc_name="init")
StructType_init :: proc(self: ^StructType) -> ^StructType {
	return msgSend(^StructType, self, "init")
}
@(objc_type=StructType, objc_name="memberByName")
StructType_memberByName :: proc(self: ^StructType, name: ^NS.String) -> ^StructMember {
	return msgSend(^StructMember, self, "memberByName:", name)
}
@(objc_type=StructType, objc_name="members")
StructType_members :: proc(self: ^StructType) -> ^NS.Array {
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
TextureDescriptor_alloc :: proc() -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "alloc")
}
@(objc_type=TextureDescriptor, objc_name="init")
TextureDescriptor_init :: proc(self: ^TextureDescriptor) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, self, "init")
}
@(objc_type=TextureDescriptor, objc_name="allowGPUOptimizedContents")
TextureDescriptor_allowGPUOptimizedContents :: proc(self: ^TextureDescriptor) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=TextureDescriptor, objc_name="arrayLength")
TextureDescriptor_arrayLength :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "arrayLength")
}
@(objc_type=TextureDescriptor, objc_name="cpuCacheMode")
TextureDescriptor_cpuCacheMode :: proc(self: ^TextureDescriptor) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=TextureDescriptor, objc_name="depth")
TextureDescriptor_depth :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "depth")
}
@(objc_type=TextureDescriptor, objc_name="hazardTrackingMode")
TextureDescriptor_hazardTrackingMode :: proc(self: ^TextureDescriptor) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=TextureDescriptor, objc_name="height")
TextureDescriptor_height :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "height")
}
@(objc_type=TextureDescriptor, objc_name="mipmapLevelCount")
TextureDescriptor_mipmapLevelCount :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "mipmapLevelCount")
}
@(objc_type=TextureDescriptor, objc_name="pixelFormat")
TextureDescriptor_pixelFormat :: proc(self: ^TextureDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TextureDescriptor, objc_name="resourceOptions")
TextureDescriptor_resourceOptions :: proc(self: ^TextureDescriptor) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=TextureDescriptor, objc_name="sampleCount")
TextureDescriptor_sampleCount :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "sampleCount")
}
@(objc_type=TextureDescriptor, objc_name="setAllowGPUOptimizedContents")
TextureDescriptor_setAllowGPUOptimizedContents :: proc(self: ^TextureDescriptor, allowGPUOptimizedContents: BOOL) {
	msgSend(nil, self, "setAllowGPUOptimizedContents:", allowGPUOptimizedContents)
}
@(objc_type=TextureDescriptor, objc_name="setArrayLength")
TextureDescriptor_setArrayLength :: proc(self: ^TextureDescriptor, arrayLength: NS.Integer) {
	msgSend(nil, self, "setArrayLength:", arrayLength)
}
@(objc_type=TextureDescriptor, objc_name="setCpuCacheMode")
TextureDescriptor_setCpuCacheMode :: proc(self: ^TextureDescriptor, cpuCacheMode: CPUCacheMode) {
	msgSend(nil, self, "setCpuCacheMode:", cpuCacheMode)
}
@(objc_type=TextureDescriptor, objc_name="setDepth")
TextureDescriptor_setDepth :: proc(self: ^TextureDescriptor, depth: NS.Integer) {
	msgSend(nil, self, "setDepth:", depth)
}
@(objc_type=TextureDescriptor, objc_name="setHazardTrackingMode")
TextureDescriptor_setHazardTrackingMode :: proc(self: ^TextureDescriptor, hazardTrackingMode: HazardTrackingMode) {
	msgSend(nil, self, "setHazardTrackingMode:", hazardTrackingMode)
}
@(objc_type=TextureDescriptor, objc_name="setHeight")
TextureDescriptor_setHeight :: proc(self: ^TextureDescriptor, height: NS.Integer) {
	msgSend(nil, self, "setHeight:", height)
}
@(objc_type=TextureDescriptor, objc_name="setMipmapLevelCount")
TextureDescriptor_setMipmapLevelCount :: proc(self: ^TextureDescriptor, mipmapLevelCount: NS.Integer) {
	msgSend(nil, self, "setMipmapLevelCount:", mipmapLevelCount)
}
@(objc_type=TextureDescriptor, objc_name="setPixelFormat")
TextureDescriptor_setPixelFormat :: proc(self: ^TextureDescriptor, pixelFormat: PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}
@(objc_type=TextureDescriptor, objc_name="setResourceOptions")
TextureDescriptor_setResourceOptions :: proc(self: ^TextureDescriptor, resourceOptions: ResourceOptions) {
	msgSend(nil, self, "setResourceOptions:", resourceOptions)
}
@(objc_type=TextureDescriptor, objc_name="setSampleCount")
TextureDescriptor_setSampleCount :: proc(self: ^TextureDescriptor, sampleCount: NS.Integer) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=TextureDescriptor, objc_name="setStorageMode")
TextureDescriptor_setStorageMode :: proc(self: ^TextureDescriptor, storageMode: StorageMode) {
	msgSend(nil, self, "setStorageMode:", storageMode)
}
@(objc_type=TextureDescriptor, objc_name="setSwizzle")
TextureDescriptor_setSwizzle :: proc(self: ^TextureDescriptor, swizzle: TextureSwizzleChannels) {
	msgSend(nil, self, "setSwizzle:", swizzle)
}
@(objc_type=TextureDescriptor, objc_name="setTextureType")
TextureDescriptor_setTextureType :: proc(self: ^TextureDescriptor, textureType: TextureType) {
	msgSend(nil, self, "setTextureType:", textureType)
}
@(objc_type=TextureDescriptor, objc_name="setUsage")
TextureDescriptor_setUsage :: proc(self: ^TextureDescriptor, usage: TextureUsage) {
	msgSend(nil, self, "setUsage:", usage)
}
@(objc_type=TextureDescriptor, objc_name="setWidth")
TextureDescriptor_setWidth :: proc(self: ^TextureDescriptor, width: NS.Integer) {
	msgSend(nil, self, "setWidth:", width)
}
@(objc_type=TextureDescriptor, objc_name="storageMode")
TextureDescriptor_storageMode :: proc(self: ^TextureDescriptor) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=TextureDescriptor, objc_name="swizzle")
TextureDescriptor_swizzle :: proc(self: ^TextureDescriptor) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=TextureDescriptor, objc_class_name="texture2DDescriptorWithPixelFormat")
TextureDescriptor_texture2DDescriptorWithPixelFormat :: proc(pixelFormat: PixelFormat, width: ^NS.Object, height: ^NS.Object, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "texture2DDescriptorWithPixelFormat:width:height:mipmapped:", pixelFormat, width, height, mipmapped)
}
@(objc_type=TextureDescriptor, objc_class_name="textureBufferDescriptorWithPixelFormat")
TextureDescriptor_textureBufferDescriptorWithPixelFormat :: proc(pixelFormat: PixelFormat, width: ^NS.Object, resourceOptions: ResourceOptions, usage: TextureUsage) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureBufferDescriptorWithPixelFormat:width:resourceOptions:usage:", pixelFormat, width, resourceOptions, usage)
}
@(objc_type=TextureDescriptor, objc_class_name="textureCubeDescriptorWithPixelFormat")
TextureDescriptor_textureCubeDescriptorWithPixelFormat :: proc(pixelFormat: PixelFormat, size: ^NS.Object, mipmapped: BOOL) -> ^TextureDescriptor {
	return msgSend(^TextureDescriptor, TextureDescriptor, "textureCubeDescriptorWithPixelFormat:size:mipmapped:", pixelFormat, size, mipmapped)
}
@(objc_type=TextureDescriptor, objc_name="textureType")
TextureDescriptor_textureType :: proc(self: ^TextureDescriptor) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=TextureDescriptor, objc_name="usage")
TextureDescriptor_usage :: proc(self: ^TextureDescriptor) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=TextureDescriptor, objc_name="width")
TextureDescriptor_width :: proc(self: ^TextureDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "width")
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
TextureReferenceType :: struct { using _: NS.Object }

@(objc_type=TextureReferenceType, objc_class_name="alloc")
TextureReferenceType_alloc :: proc() -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, TextureReferenceType, "alloc")
}
@(objc_type=TextureReferenceType, objc_name="init")
TextureReferenceType_init :: proc(self: ^TextureReferenceType) -> ^TextureReferenceType {
	return msgSend(^TextureReferenceType, self, "init")
}
@(objc_type=TextureReferenceType, objc_name="access")
TextureReferenceType_access :: proc(self: ^TextureReferenceType) -> ArgumentAccess {
	return msgSend(ArgumentAccess, self, "access")
}
@(objc_type=TextureReferenceType, objc_name="isDepthTexture")
TextureReferenceType_isDepthTexture :: proc(self: ^TextureReferenceType) -> BOOL {
	return msgSend(BOOL, self, "isDepthTexture")
}
@(objc_type=TextureReferenceType, objc_name="textureDataType")
TextureReferenceType_textureDataType :: proc(self: ^TextureReferenceType) -> DataType {
	return msgSend(DataType, self, "textureDataType")
}
@(objc_type=TextureReferenceType, objc_name="textureType")
TextureReferenceType_textureType :: proc(self: ^TextureReferenceType) -> TextureType {
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
TileRenderPipelineColorAttachmentDescriptor_alloc :: proc() -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, TileRenderPipelineColorAttachmentDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="init")
TileRenderPipelineColorAttachmentDescriptor_init :: proc(self: ^TileRenderPipelineColorAttachmentDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="pixelFormat")
TileRenderPipelineColorAttachmentDescriptor_pixelFormat :: proc(self: ^TileRenderPipelineColorAttachmentDescriptor) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptor, objc_name="setPixelFormat")
TileRenderPipelineColorAttachmentDescriptor_setPixelFormat :: proc(self: ^TileRenderPipelineColorAttachmentDescriptor, pixelFormat: PixelFormat) {
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
TileRenderPipelineColorAttachmentDescriptorArray_alloc :: proc() -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, TileRenderPipelineColorAttachmentDescriptorArray, "alloc")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="init")
TileRenderPipelineColorAttachmentDescriptorArray_init :: proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "init")
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="objectAtIndexedSubscript")
TileRenderPipelineColorAttachmentDescriptorArray_objectAtIndexedSubscript :: proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachmentIndex: ^NS.Object) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptor, self, "objectAtIndexedSubscript:", attachmentIndex)
}
@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="setObject")
TileRenderPipelineColorAttachmentDescriptorArray_setObject :: proc(self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachment: ^TileRenderPipelineColorAttachmentDescriptor, attachmentIndex: ^NS.Object) {
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
TileRenderPipelineDescriptor_alloc :: proc() -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, TileRenderPipelineDescriptor, "alloc")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="init")
TileRenderPipelineDescriptor_init :: proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineDescriptor {
	return msgSend(^TileRenderPipelineDescriptor, self, "init")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="binaryArchives")
TileRenderPipelineDescriptor_binaryArchives :: proc(self: ^TileRenderPipelineDescriptor) -> ^NS.Array {
	return msgSend(^NS.Array, self, "binaryArchives")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="colorAttachments")
TileRenderPipelineDescriptor_colorAttachments :: proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineColorAttachmentDescriptorArray {
	return msgSend(^TileRenderPipelineColorAttachmentDescriptorArray, self, "colorAttachments")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="label")
TileRenderPipelineDescriptor_label :: proc(self: ^TileRenderPipelineDescriptor) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="maxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_maxTotalThreadsPerThreadgroup :: proc(self: ^TileRenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="rasterSampleCount")
TileRenderPipelineDescriptor_rasterSampleCount :: proc(self: ^TileRenderPipelineDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "rasterSampleCount")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="reset")
TileRenderPipelineDescriptor_reset :: proc(self: ^TileRenderPipelineDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setBinaryArchives")
TileRenderPipelineDescriptor_setBinaryArchives :: proc(self: ^TileRenderPipelineDescriptor, binaryArchives: ^NS.Array) {
	msgSend(nil, self, "setBinaryArchives:", binaryArchives)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setLabel")
TileRenderPipelineDescriptor_setLabel :: proc(self: ^TileRenderPipelineDescriptor, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setMaxTotalThreadsPerThreadgroup")
TileRenderPipelineDescriptor_setMaxTotalThreadsPerThreadgroup :: proc(self: ^TileRenderPipelineDescriptor, maxTotalThreadsPerThreadgroup: NS.Integer) {
	msgSend(nil, self, "setMaxTotalThreadsPerThreadgroup:", maxTotalThreadsPerThreadgroup)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setRasterSampleCount")
TileRenderPipelineDescriptor_setRasterSampleCount :: proc(self: ^TileRenderPipelineDescriptor, rasterSampleCount: NS.Integer) {
	msgSend(nil, self, "setRasterSampleCount:", rasterSampleCount)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setThreadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_setThreadgroupSizeMatchesTileSize :: proc(self: ^TileRenderPipelineDescriptor, threadgroupSizeMatchesTileSize: BOOL) {
	msgSend(nil, self, "setThreadgroupSizeMatchesTileSize:", threadgroupSizeMatchesTileSize)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="setTileFunction")
TileRenderPipelineDescriptor_setTileFunction :: proc(self: ^TileRenderPipelineDescriptor, tileFunction: ^NS.Object) {
	msgSend(nil, self, "setTileFunction:", tileFunction)
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="threadgroupSizeMatchesTileSize")
TileRenderPipelineDescriptor_threadgroupSizeMatchesTileSize :: proc(self: ^TileRenderPipelineDescriptor) -> BOOL {
	return msgSend(BOOL, self, "threadgroupSizeMatchesTileSize")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileBuffers")
TileRenderPipelineDescriptor_tileBuffers :: proc(self: ^TileRenderPipelineDescriptor) -> ^PipelineBufferDescriptorArray {
	return msgSend(^PipelineBufferDescriptorArray, self, "tileBuffers")
}
@(objc_type=TileRenderPipelineDescriptor, objc_name="tileFunction")
TileRenderPipelineDescriptor_tileFunction :: proc(self: ^TileRenderPipelineDescriptor) -> ^TileRenderPipelineDescriptor {
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
Type_alloc :: proc() -> ^Type {
	return msgSend(^Type, Type, "alloc")
}
@(objc_type=Type, objc_name="init")
Type_init :: proc(self: ^Type) -> ^Type {
	return msgSend(^Type, self, "init")
}
@(objc_type=Type, objc_name="dataType")
Type_dataType :: proc(self: ^Type) -> DataType {
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
VertexAttribute_alloc :: proc() -> ^VertexAttribute {
	return msgSend(^VertexAttribute, VertexAttribute, "alloc")
}
@(objc_type=VertexAttribute, objc_name="init")
VertexAttribute_init :: proc(self: ^VertexAttribute) -> ^VertexAttribute {
	return msgSend(^VertexAttribute, self, "init")
}
@(objc_type=VertexAttribute, objc_name="attributeIndex")
VertexAttribute_attributeIndex :: proc(self: ^VertexAttribute) -> NS.Integer {
	return msgSend(NS.Integer, self, "attributeIndex")
}
@(objc_type=VertexAttribute, objc_name="attributeType")
VertexAttribute_attributeType :: proc(self: ^VertexAttribute) -> DataType {
	return msgSend(DataType, self, "attributeType")
}
@(objc_type=VertexAttribute, objc_name="isActive")
VertexAttribute_isActive :: proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isActive")
}
@(objc_type=VertexAttribute, objc_name="isPatchControlPointData")
VertexAttribute_isPatchControlPointData :: proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchControlPointData")
}
@(objc_type=VertexAttribute, objc_name="isPatchData")
VertexAttribute_isPatchData :: proc(self: ^VertexAttribute) -> BOOL {
	return msgSend(BOOL, self, "isPatchData")
}
@(objc_type=VertexAttribute, objc_name="name")
VertexAttribute_name :: proc(self: ^VertexAttribute) -> ^NS.String {
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
VertexAttributeDescriptor_alloc :: proc() -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, VertexAttributeDescriptor, "alloc")
}
@(objc_type=VertexAttributeDescriptor, objc_name="init")
VertexAttributeDescriptor_init :: proc(self: ^VertexAttributeDescriptor) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "init")
}
@(objc_type=VertexAttributeDescriptor, objc_name="bufferIndex")
VertexAttributeDescriptor_bufferIndex :: proc(self: ^VertexAttributeDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferIndex")
}
@(objc_type=VertexAttributeDescriptor, objc_name="format")
VertexAttributeDescriptor_format :: proc(self: ^VertexAttributeDescriptor) -> VertexFormat {
	return msgSend(VertexFormat, self, "format")
}
@(objc_type=VertexAttributeDescriptor, objc_name="offset")
VertexAttributeDescriptor_offset :: proc(self: ^VertexAttributeDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "offset")
}
@(objc_type=VertexAttributeDescriptor, objc_name="setBufferIndex")
VertexAttributeDescriptor_setBufferIndex :: proc(self: ^VertexAttributeDescriptor, bufferIndex: NS.Integer) {
	msgSend(nil, self, "setBufferIndex:", bufferIndex)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setFormat")
VertexAttributeDescriptor_setFormat :: proc(self: ^VertexAttributeDescriptor, format: VertexFormat) {
	msgSend(nil, self, "setFormat:", format)
}
@(objc_type=VertexAttributeDescriptor, objc_name="setOffset")
VertexAttributeDescriptor_setOffset :: proc(self: ^VertexAttributeDescriptor, offset: NS.Integer) {
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
VertexAttributeDescriptorArray_alloc :: proc() -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, VertexAttributeDescriptorArray, "alloc")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="init")
VertexAttributeDescriptorArray_init :: proc(self: ^VertexAttributeDescriptorArray) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "init")
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="objectAtIndexedSubscript")
VertexAttributeDescriptorArray_objectAtIndexedSubscript :: proc(self: ^VertexAttributeDescriptorArray, index: ^NS.Object) -> ^VertexAttributeDescriptor {
	return msgSend(^VertexAttributeDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexAttributeDescriptorArray, objc_name="setObject")
VertexAttributeDescriptorArray_setObject :: proc(self: ^VertexAttributeDescriptorArray, attributeDesc: ^VertexAttributeDescriptor, index: ^NS.Object) {
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
VertexBufferLayoutDescriptor_alloc :: proc() -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, VertexBufferLayoutDescriptor, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="init")
VertexBufferLayoutDescriptor_init :: proc(self: ^VertexBufferLayoutDescriptor) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepFunction")
VertexBufferLayoutDescriptor_setStepFunction :: proc(self: ^VertexBufferLayoutDescriptor, stepFunction: VertexStepFunction) {
	msgSend(nil, self, "setStepFunction:", stepFunction)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStepRate")
VertexBufferLayoutDescriptor_setStepRate :: proc(self: ^VertexBufferLayoutDescriptor, stepRate: NS.Integer) {
	msgSend(nil, self, "setStepRate:", stepRate)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="setStride")
VertexBufferLayoutDescriptor_setStride :: proc(self: ^VertexBufferLayoutDescriptor, stride: NS.Integer) {
	msgSend(nil, self, "setStride:", stride)
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepFunction")
VertexBufferLayoutDescriptor_stepFunction :: proc(self: ^VertexBufferLayoutDescriptor) -> VertexStepFunction {
	return msgSend(VertexStepFunction, self, "stepFunction")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stepRate")
VertexBufferLayoutDescriptor_stepRate :: proc(self: ^VertexBufferLayoutDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "stepRate")
}
@(objc_type=VertexBufferLayoutDescriptor, objc_name="stride")
VertexBufferLayoutDescriptor_stride :: proc(self: ^VertexBufferLayoutDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "stride")
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
VertexBufferLayoutDescriptorArray_alloc :: proc() -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, VertexBufferLayoutDescriptorArray, "alloc")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="init")
VertexBufferLayoutDescriptorArray_init :: proc(self: ^VertexBufferLayoutDescriptorArray) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "init")
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="objectAtIndexedSubscript")
VertexBufferLayoutDescriptorArray_objectAtIndexedSubscript :: proc(self: ^VertexBufferLayoutDescriptorArray, index: ^NS.Object) -> ^VertexBufferLayoutDescriptor {
	return msgSend(^VertexBufferLayoutDescriptor, self, "objectAtIndexedSubscript:", index)
}
@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="setObject")
VertexBufferLayoutDescriptorArray_setObject :: proc(self: ^VertexBufferLayoutDescriptorArray, bufferDesc: ^VertexBufferLayoutDescriptor, index: ^NS.Object) {
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
VertexDescriptor_alloc :: proc() -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, VertexDescriptor, "alloc")
}
@(objc_type=VertexDescriptor, objc_name="init")
VertexDescriptor_init :: proc(self: ^VertexDescriptor) -> ^VertexDescriptor {
	return msgSend(^VertexDescriptor, self, "init")
}
@(objc_type=VertexDescriptor, objc_name="attributes")
VertexDescriptor_attributes :: proc(self: ^VertexDescriptor) -> ^VertexAttributeDescriptorArray {
	return msgSend(^VertexAttributeDescriptorArray, self, "attributes")
}
@(objc_type=VertexDescriptor, objc_name="layouts")
VertexDescriptor_layouts :: proc(self: ^VertexDescriptor) -> ^VertexBufferLayoutDescriptorArray {
	return msgSend(^VertexBufferLayoutDescriptorArray, self, "layouts")
}
@(objc_type=VertexDescriptor, objc_name="reset")
VertexDescriptor_reset :: proc(self: ^VertexDescriptor) {
	msgSend(nil, self, "reset")
}
@(objc_type=VertexDescriptor, objc_class_name="vertexDescriptor")
VertexDescriptor_vertexDescriptor :: proc() -> ^VertexDescriptor {
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
VisibleFunctionTableDescriptor_alloc :: proc() -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, VisibleFunctionTableDescriptor, "alloc")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="init")
VisibleFunctionTableDescriptor_init :: proc(self: ^VisibleFunctionTableDescriptor) -> ^VisibleFunctionTableDescriptor {
	return msgSend(^VisibleFunctionTableDescriptor, self, "init")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="functionCount")
VisibleFunctionTableDescriptor_functionCount :: proc(self: ^VisibleFunctionTableDescriptor) -> NS.Integer {
	return msgSend(NS.Integer, self, "functionCount")
}
@(objc_type=VisibleFunctionTableDescriptor, objc_name="setFunctionCount")
VisibleFunctionTableDescriptor_setFunctionCount :: proc(self: ^VisibleFunctionTableDescriptor, functionCount: NS.Integer) {
	msgSend(nil, self, "setFunctionCount:", functionCount)
}
@(objc_type=VisibleFunctionTableDescriptor, objc_class_name="visibleFunctionTableDescriptor")
VisibleFunctionTableDescriptor_visibleFunctionTableDescriptor :: proc() -> ^VisibleFunctionTableDescriptor {
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
AccelerationStructure :: struct { using _: NS.Object }

@(objc_type=AccelerationStructure, objc_name="size")
AccelerationStructure_size :: proc(self: ^AccelerationStructure) -> NS.Integer {
	return msgSend(NS.Integer, self, "size")
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
AccelerationStructureCommandEncoder :: struct { using _: NS.Object }

@(objc_type=AccelerationStructureCommandEncoder, objc_name="buildAccelerationStructure")
AccelerationStructureCommandEncoder_buildAccelerationStructure :: proc(self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^NS.Object, descriptor: ^AccelerationStructureDescriptor, scratchBuffer: ^NS.Object, scratchBufferOffset: ^NS.Object) {
	msgSend(nil, self, "buildAccelerationStructure:descriptor:scratchBuffer:scratchBufferOffset:", accelerationStructure, descriptor, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAccelerationStructure")
AccelerationStructureCommandEncoder_copyAccelerationStructure :: proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^NS.Object, destinationAccelerationStructure: ^NS.Object) {
	msgSend(nil, self, "copyAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="copyAndCompactAccelerationStructure")
AccelerationStructureCommandEncoder_copyAndCompactAccelerationStructure :: proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^NS.Object, destinationAccelerationStructure: ^NS.Object) {
	msgSend(nil, self, "copyAndCompactAccelerationStructure:toAccelerationStructure:", sourceAccelerationStructure, destinationAccelerationStructure)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="refitAccelerationStructure")
AccelerationStructureCommandEncoder_refitAccelerationStructure :: proc(self: ^AccelerationStructureCommandEncoder, sourceAccelerationStructure: ^NS.Object, descriptor: ^AccelerationStructureDescriptor, destinationAccelerationStructure: ^NS.Object, scratchBuffer: ^NS.Object, scratchBufferOffset: ^NS.Object) {
	msgSend(nil, self, "refitAccelerationStructure:descriptor:destination:scratchBuffer:scratchBufferOffset:", sourceAccelerationStructure, descriptor, destinationAccelerationStructure, scratchBuffer, scratchBufferOffset)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="sampleCountersInBuffer")
AccelerationStructureCommandEncoder_sampleCountersInBuffer :: proc(self: ^AccelerationStructureCommandEncoder, sampleBuffer: ^NS.Object, sampleIndex: ^NS.Object, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="updateFence")
AccelerationStructureCommandEncoder_updateFence :: proc(self: ^AccelerationStructureCommandEncoder, fence: ^NS.Object) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeap")
AccelerationStructureCommandEncoder_useHeap :: proc(self: ^AccelerationStructureCommandEncoder, heap: ^NS.Object) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useHeaps")
AccelerationStructureCommandEncoder_useHeaps :: proc(self: ^AccelerationStructureCommandEncoder, heaps: ^^NS.Object, count: ^NS.Object) {
	msgSend(nil, self, "useHeaps:count:", heaps, count)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResource")
AccelerationStructureCommandEncoder_useResource :: proc(self: ^AccelerationStructureCommandEncoder, resource: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="useResources")
AccelerationStructureCommandEncoder_useResources :: proc(self: ^AccelerationStructureCommandEncoder, resources: ^^NS.Object, count: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, count, usage)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="waitForFence")
AccelerationStructureCommandEncoder_waitForFence :: proc(self: ^AccelerationStructureCommandEncoder, fence: ^NS.Object) {
	msgSend(nil, self, "waitForFence:", fence)
}
@(objc_type=AccelerationStructureCommandEncoder, objc_name="writeCompactedAccelerationStructureSize")
AccelerationStructureCommandEncoder_writeCompactedAccelerationStructureSize :: proc(self: ^AccelerationStructureCommandEncoder, accelerationStructure: ^NS.Object, buffer: ^NS.Object, offset: ^NS.Object) {
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
ArgumentEncoder_alignment :: proc(self: ^ArgumentEncoder) -> NS.Integer {
	return msgSend(NS.Integer, self, "alignment")
}
@(objc_type=ArgumentEncoder, objc_name="constantDataAtIndex")
ArgumentEncoder_constantDataAtIndex :: proc(self: ^ArgumentEncoder, index: ^NS.Object) -> rawptr {
	return msgSend(rawptr, self, "constantDataAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="device")
ArgumentEncoder_device :: proc(self: ^ArgumentEncoder) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "device")
}
@(objc_type=ArgumentEncoder, objc_name="encodedLength")
ArgumentEncoder_encodedLength :: proc(self: ^ArgumentEncoder) -> NS.Integer {
	return msgSend(NS.Integer, self, "encodedLength")
}
@(objc_type=ArgumentEncoder, objc_name="label")
ArgumentEncoder_label :: proc(self: ^ArgumentEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ArgumentEncoder, objc_name="newArgumentEncoderForBufferAtIndex")
ArgumentEncoder_newArgumentEncoderForBufferAtIndex :: proc(self: ^ArgumentEncoder, index: ^NS.Object) -> ^ArgumentEncoder {
	return msgSend(^ArgumentEncoder, self, "newArgumentEncoderForBufferAtIndex:", index)
}
@(objc_type=ArgumentEncoder, objc_name="setAccelerationStructure")
ArgumentEncoder_setAccelerationStructure :: proc(self: ^ArgumentEncoder, accelerationStructure: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setAccelerationStructure:atIndex:", accelerationStructure, index)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBuffer_offset_")
ArgumentEncoder_setArgumentBuffer_offset_ :: proc(self: ^ArgumentEncoder, argumentBuffer: ^NS.Object, offset: ^NS.Object) {
	msgSend(nil, self, "setArgumentBuffer:offset:", argumentBuffer, offset)
}
@(objc_type=ArgumentEncoder, objc_name="setArgumentBuffer_startOffset_arrayElement_")
ArgumentEncoder_setArgumentBuffer_startOffset_arrayElement_ :: proc(self: ^ArgumentEncoder, argumentBuffer: ^NS.Object, startOffset: ^NS.Object, arrayElement: ^NS.Object) {
	msgSend(nil, self, "setArgumentBuffer:startOffset:arrayElement:", argumentBuffer, startOffset, arrayElement)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffer")
ArgumentEncoder_setBuffer :: proc(self: ^ArgumentEncoder, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ArgumentEncoder, objc_name="setBuffers")
ArgumentEncoder_setBuffers :: proc(self: ^ArgumentEncoder, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineState")
ArgumentEncoder_setComputePipelineState :: proc(self: ^ArgumentEncoder, pipeline: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setComputePipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setComputePipelineStates")
ArgumentEncoder_setComputePipelineStates :: proc(self: ^ArgumentEncoder, pipelines: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setComputePipelineStates:withRange:", pipelines, range)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffer")
ArgumentEncoder_setIndirectCommandBuffer :: proc(self: ^ArgumentEncoder, indirectCommandBuffer: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setIndirectCommandBuffer:atIndex:", indirectCommandBuffer, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIndirectCommandBuffers")
ArgumentEncoder_setIndirectCommandBuffers :: proc(self: ^ArgumentEncoder, buffers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setIndirectCommandBuffers:withRange:", buffers, range)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTable")
ArgumentEncoder_setIntersectionFunctionTable :: proc(self: ^ArgumentEncoder, intersectionFunctionTable: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setIntersectionFunctionTable:atIndex:", intersectionFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setIntersectionFunctionTables")
ArgumentEncoder_setIntersectionFunctionTables :: proc(self: ^ArgumentEncoder, intersectionFunctionTables: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setIntersectionFunctionTables:withRange:", intersectionFunctionTables, range)
}
@(objc_type=ArgumentEncoder, objc_name="setLabel")
ArgumentEncoder_setLabel :: proc(self: ^ArgumentEncoder, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineState")
ArgumentEncoder_setRenderPipelineState :: proc(self: ^ArgumentEncoder, pipeline: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setRenderPipelineState:atIndex:", pipeline, index)
}
@(objc_type=ArgumentEncoder, objc_name="setRenderPipelineStates")
ArgumentEncoder_setRenderPipelineStates :: proc(self: ^ArgumentEncoder, pipelines: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setRenderPipelineStates:withRange:", pipelines, range)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerState")
ArgumentEncoder_setSamplerState :: proc(self: ^ArgumentEncoder, sampler: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ArgumentEncoder, objc_name="setSamplerStates")
ArgumentEncoder_setSamplerStates :: proc(self: ^ArgumentEncoder, samplers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:withRange:", samplers, range)
}
@(objc_type=ArgumentEncoder, objc_name="setTexture")
ArgumentEncoder_setTexture :: proc(self: ^ArgumentEncoder, texture: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ArgumentEncoder, objc_name="setTextures")
ArgumentEncoder_setTextures :: proc(self: ^ArgumentEncoder, textures: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setTextures:withRange:", textures, range)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTable")
ArgumentEncoder_setVisibleFunctionTable :: proc(self: ^ArgumentEncoder, visibleFunctionTable: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVisibleFunctionTable:atIndex:", visibleFunctionTable, index)
}
@(objc_type=ArgumentEncoder, objc_name="setVisibleFunctionTables")
ArgumentEncoder_setVisibleFunctionTables :: proc(self: ^ArgumentEncoder, visibleFunctionTables: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withRange:", visibleFunctionTables, range)
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
BinaryArchive_addComputePipelineFunctionsWithDescriptor :: proc(self: ^BinaryArchive, descriptor: ^ComputePipelineDescriptor, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "addComputePipelineFunctionsWithDescriptor:error:", descriptor, error)
}
@(objc_type=BinaryArchive, objc_name="addRenderPipelineFunctionsWithDescriptor")
BinaryArchive_addRenderPipelineFunctionsWithDescriptor :: proc(self: ^BinaryArchive, descriptor: ^RenderPipelineDescriptor, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "addRenderPipelineFunctionsWithDescriptor:error:", descriptor, error)
}
@(objc_type=BinaryArchive, objc_name="addTileRenderPipelineFunctionsWithDescriptor")
BinaryArchive_addTileRenderPipelineFunctionsWithDescriptor :: proc(self: ^BinaryArchive, descriptor: ^TileRenderPipelineDescriptor, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "addTileRenderPipelineFunctionsWithDescriptor:error:", descriptor, error)
}
@(objc_type=BinaryArchive, objc_name="device")
BinaryArchive_device :: proc(self: ^BinaryArchive) -> ^BinaryArchive {
	return msgSend(^BinaryArchive, self, "device")
}
@(objc_type=BinaryArchive, objc_name="label")
BinaryArchive_label :: proc(self: ^BinaryArchive) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=BinaryArchive, objc_name="serializeToURL")
BinaryArchive_serializeToURL :: proc(self: ^BinaryArchive, url: ^NS.URL, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "serializeToURL:error:", url, error)
}
@(objc_type=BinaryArchive, objc_name="setLabel")
BinaryArchive_setLabel :: proc(self: ^BinaryArchive, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
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
BlitCommandEncoder :: struct { using _: NS.Object }

@(objc_type=BlitCommandEncoder, objc_name="copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_")
BlitCommandEncoder_copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_ :: proc(self: ^BlitCommandEncoder, sourceBuffer: ^NS.Object, sourceOffset: ^NS.Object, sourceBytesPerRow: ^NS.Object, sourceBytesPerImage: ^NS.Object, sourceSize: Size, destinationTexture: ^NS.Object, destinationSlice: ^NS.Object, destinationLevel: ^NS.Object, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_options_")
BlitCommandEncoder_copyFromBuffer_sourceOffset_sourceBytesPerRow_sourceBytesPerImage_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_options_ :: proc(self: ^BlitCommandEncoder, sourceBuffer: ^NS.Object, sourceOffset: ^NS.Object, sourceBytesPerRow: ^NS.Object, sourceBytesPerImage: ^NS.Object, sourceSize: Size, destinationTexture: ^NS.Object, destinationSlice: ^NS.Object, destinationLevel: ^NS.Object, destinationOrigin: Origin, options: BlitOption) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:sourceBytesPerRow:sourceBytesPerImage:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:options:", sourceBuffer, sourceOffset, sourceBytesPerRow, sourceBytesPerImage, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromBuffer_sourceOffset_toBuffer_destinationOffset_size_")
BlitCommandEncoder_copyFromBuffer_sourceOffset_toBuffer_destinationOffset_size_ :: proc(self: ^BlitCommandEncoder, sourceBuffer: ^NS.Object, sourceOffset: ^NS.Object, destinationBuffer: ^NS.Object, destinationOffset: ^NS.Object, size: ^NS.Object) {
	msgSend(nil, self, "copyFromBuffer:sourceOffset:toBuffer:destinationOffset:size:", sourceBuffer, sourceOffset, destinationBuffer, destinationOffset, size)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_")
BlitCommandEncoder_copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_ :: proc(self: ^BlitCommandEncoder, sourceTexture: ^NS.Object, sourceSlice: ^NS.Object, sourceLevel: ^NS.Object, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^NS.Object, destinationOffset: ^NS.Object, destinationBytesPerRow: ^NS.Object, destinationBytesPerImage: ^NS.Object) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_options_")
BlitCommandEncoder_copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toBuffer_destinationOffset_destinationBytesPerRow_destinationBytesPerImage_options_ :: proc(self: ^BlitCommandEncoder, sourceTexture: ^NS.Object, sourceSlice: ^NS.Object, sourceLevel: ^NS.Object, sourceOrigin: Origin, sourceSize: Size, destinationBuffer: ^NS.Object, destinationOffset: ^NS.Object, destinationBytesPerRow: ^NS.Object, destinationBytesPerImage: ^NS.Object, options: BlitOption) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toBuffer:destinationOffset:destinationBytesPerRow:destinationBytesPerImage:options:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationBuffer, destinationOffset, destinationBytesPerRow, destinationBytesPerImage, options)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_")
BlitCommandEncoder_copyFromTexture_sourceSlice_sourceLevel_sourceOrigin_sourceSize_toTexture_destinationSlice_destinationLevel_destinationOrigin_ :: proc(self: ^BlitCommandEncoder, sourceTexture: ^NS.Object, sourceSlice: ^NS.Object, sourceLevel: ^NS.Object, sourceOrigin: Origin, sourceSize: Size, destinationTexture: ^NS.Object, destinationSlice: ^NS.Object, destinationLevel: ^NS.Object, destinationOrigin: Origin) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:sourceOrigin:sourceSize:toTexture:destinationSlice:destinationLevel:destinationOrigin:", sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize, destinationTexture, destinationSlice, destinationLevel, destinationOrigin)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture_sourceSlice_sourceLevel_toTexture_destinationSlice_destinationLevel_sliceCount_levelCount_")
BlitCommandEncoder_copyFromTexture_sourceSlice_sourceLevel_toTexture_destinationSlice_destinationLevel_sliceCount_levelCount_ :: proc(self: ^BlitCommandEncoder, sourceTexture: ^NS.Object, sourceSlice: ^NS.Object, sourceLevel: ^NS.Object, destinationTexture: ^NS.Object, destinationSlice: ^NS.Object, destinationLevel: ^NS.Object, sliceCount: ^NS.Object, levelCount: ^NS.Object) {
	msgSend(nil, self, "copyFromTexture:sourceSlice:sourceLevel:toTexture:destinationSlice:destinationLevel:sliceCount:levelCount:", sourceTexture, sourceSlice, sourceLevel, destinationTexture, destinationSlice, destinationLevel, sliceCount, levelCount)
}
@(objc_type=BlitCommandEncoder, objc_name="copyFromTexture_toTexture_")
BlitCommandEncoder_copyFromTexture_toTexture_ :: proc(self: ^BlitCommandEncoder, sourceTexture: ^NS.Object, destinationTexture: ^NS.Object) {
	msgSend(nil, self, "copyFromTexture:toTexture:", sourceTexture, destinationTexture)
}
@(objc_type=BlitCommandEncoder, objc_name="copyIndirectCommandBuffer")
BlitCommandEncoder_copyIndirectCommandBuffer :: proc(self: ^BlitCommandEncoder, source: ^NS.Object, sourceRange: NS.Range, destination: ^NS.Object, destinationIndex: ^NS.Object) {
	msgSend(nil, self, "copyIndirectCommandBuffer:sourceRange:destination:destinationIndex:", source, sourceRange, destination, destinationIndex)
}
@(objc_type=BlitCommandEncoder, objc_name="fillBuffer")
BlitCommandEncoder_fillBuffer :: proc(self: ^BlitCommandEncoder, buffer: ^NS.Object, range: NS.Range, value: u8) {
	msgSend(nil, self, "fillBuffer:range:value:", buffer, range, value)
}
@(objc_type=BlitCommandEncoder, objc_name="generateMipmapsForTexture")
BlitCommandEncoder_generateMipmapsForTexture :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object) {
	msgSend(nil, self, "generateMipmapsForTexture:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="getTextureAccessCounters")
BlitCommandEncoder_getTextureAccessCounters :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object, region: Region, mipLevel: ^NS.Object, slice: ^NS.Object, resetCounters: BOOL, countersBuffer: ^NS.Object, countersBufferOffset: ^NS.Object) {
	msgSend(nil, self, "getTextureAccessCounters:region:mipLevel:slice:resetCounters:countersBuffer:countersBufferOffset:", texture, region, mipLevel, slice, resetCounters, countersBuffer, countersBufferOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccess")
BlitCommandEncoder_optimizeContentsForCPUAccess :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForCPUAccess_slice_level_")
BlitCommandEncoder_optimizeContentsForCPUAccess_slice_level_ :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object, slice: ^NS.Object, level: ^NS.Object) {
	msgSend(nil, self, "optimizeContentsForCPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccess")
BlitCommandEncoder_optimizeContentsForGPUAccess :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:", texture)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeContentsForGPUAccess_slice_level_")
BlitCommandEncoder_optimizeContentsForGPUAccess_slice_level_ :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object, slice: ^NS.Object, level: ^NS.Object) {
	msgSend(nil, self, "optimizeContentsForGPUAccess:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="optimizeIndirectCommandBuffer")
BlitCommandEncoder_optimizeIndirectCommandBuffer :: proc(self: ^BlitCommandEncoder, indirectCommandBuffer: ^NS.Object, range: NS.Range) {
	msgSend(nil, self, "optimizeIndirectCommandBuffer:withRange:", indirectCommandBuffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetCommandsInBuffer")
BlitCommandEncoder_resetCommandsInBuffer :: proc(self: ^BlitCommandEncoder, buffer: ^NS.Object, range: NS.Range) {
	msgSend(nil, self, "resetCommandsInBuffer:withRange:", buffer, range)
}
@(objc_type=BlitCommandEncoder, objc_name="resetTextureAccessCounters")
BlitCommandEncoder_resetTextureAccessCounters :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object, region: Region, mipLevel: ^NS.Object, slice: ^NS.Object) {
	msgSend(nil, self, "resetTextureAccessCounters:region:mipLevel:slice:", texture, region, mipLevel, slice)
}
@(objc_type=BlitCommandEncoder, objc_name="resolveCounters")
BlitCommandEncoder_resolveCounters :: proc(self: ^BlitCommandEncoder, sampleBuffer: ^NS.Object, range: NS.Range, destinationBuffer: ^NS.Object, destinationOffset: ^NS.Object) {
	msgSend(nil, self, "resolveCounters:inRange:destinationBuffer:destinationOffset:", sampleBuffer, range, destinationBuffer, destinationOffset)
}
@(objc_type=BlitCommandEncoder, objc_name="sampleCountersInBuffer")
BlitCommandEncoder_sampleCountersInBuffer :: proc(self: ^BlitCommandEncoder, sampleBuffer: ^NS.Object, sampleIndex: ^NS.Object, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeResource")
BlitCommandEncoder_synchronizeResource :: proc(self: ^BlitCommandEncoder, resource: ^NS.Object) {
	msgSend(nil, self, "synchronizeResource:", resource)
}
@(objc_type=BlitCommandEncoder, objc_name="synchronizeTexture")
BlitCommandEncoder_synchronizeTexture :: proc(self: ^BlitCommandEncoder, texture: ^NS.Object, slice: ^NS.Object, level: ^NS.Object) {
	msgSend(nil, self, "synchronizeTexture:slice:level:", texture, slice, level)
}
@(objc_type=BlitCommandEncoder, objc_name="updateFence")
BlitCommandEncoder_updateFence :: proc(self: ^BlitCommandEncoder, fence: ^NS.Object) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=BlitCommandEncoder, objc_name="waitForFence")
BlitCommandEncoder_waitForFence :: proc(self: ^BlitCommandEncoder, fence: ^NS.Object) {
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
Buffer :: struct { using _: NS.Object }

@(objc_type=Buffer, objc_name="addDebugMarker")
Buffer_addDebugMarker :: proc(self: ^Buffer, marker: ^NS.String, range: NS.Range) {
	msgSend(nil, self, "addDebugMarker:range:", marker, range)
}
@(objc_type=Buffer, objc_name="contents")
Buffer_contents :: proc(self: ^Buffer) -> rawptr {
	return msgSend(rawptr, self, "contents")
}
@(objc_type=Buffer, objc_name="didModifyRange")
Buffer_didModifyRange :: proc(self: ^Buffer, range: NS.Range) {
	msgSend(nil, self, "didModifyRange:", range)
}
@(objc_type=Buffer, objc_name="length")
Buffer_length :: proc(self: ^Buffer) -> NS.Integer {
	return msgSend(NS.Integer, self, "length")
}
@(objc_type=Buffer, objc_name="newRemoteBufferViewForDevice")
Buffer_newRemoteBufferViewForDevice :: proc(self: ^Buffer, device: ^NS.Object) -> ^Buffer {
	return msgSend(^Buffer, self, "newRemoteBufferViewForDevice:", device)
}
@(objc_type=Buffer, objc_name="newTextureWithDescriptor")
Buffer_newTextureWithDescriptor :: proc(self: ^Buffer, descriptor: ^TextureDescriptor, offset: ^NS.Object, bytesPerRow: ^NS.Object) -> ^Buffer {
	return msgSend(^Buffer, self, "newTextureWithDescriptor:offset:bytesPerRow:", descriptor, offset, bytesPerRow)
}
@(objc_type=Buffer, objc_name="remoteStorageBuffer")
Buffer_remoteStorageBuffer :: proc(self: ^Buffer) -> ^Buffer {
	return msgSend(^Buffer, self, "remoteStorageBuffer")
}
@(objc_type=Buffer, objc_name="removeAllDebugMarkers")
Buffer_removeAllDebugMarkers :: proc(self: ^Buffer) {
	msgSend(nil, self, "removeAllDebugMarkers")
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
CaptureScope_beginScope :: proc(self: ^CaptureScope) {
	msgSend(nil, self, "beginScope")
}
@(objc_type=CaptureScope, objc_name="commandQueue")
CaptureScope_commandQueue :: proc(self: ^CaptureScope) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "commandQueue")
}
@(objc_type=CaptureScope, objc_name="device")
CaptureScope_device :: proc(self: ^CaptureScope) -> ^CaptureScope {
	return msgSend(^CaptureScope, self, "device")
}
@(objc_type=CaptureScope, objc_name="endScope")
CaptureScope_endScope :: proc(self: ^CaptureScope) {
	msgSend(nil, self, "endScope")
}
@(objc_type=CaptureScope, objc_name="label")
CaptureScope_label :: proc(self: ^CaptureScope) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CaptureScope, objc_name="setLabel")
CaptureScope_setLabel :: proc(self: ^CaptureScope, label: ^NS.String) {
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
CommandBuffer_GPUEndTime :: proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUEndTime")
}
@(objc_type=CommandBuffer, objc_name="GPUStartTime")
CommandBuffer_GPUStartTime :: proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "GPUStartTime")
}
@(objc_type=CommandBuffer, objc_name="accelerationStructureCommandEncoder")
CommandBuffer_accelerationStructureCommandEncoder :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "accelerationStructureCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="addCompletedHandler")
CommandBuffer_addCompletedHandler :: proc(self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addCompletedHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="addScheduledHandler")
CommandBuffer_addScheduledHandler :: proc(self: ^CommandBuffer, block: CommandBufferHandler) {
	msgSend(nil, self, "addScheduledHandler:", block)
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoder")
CommandBuffer_blitCommandEncoder :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "blitCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="blitCommandEncoderWithDescriptor")
CommandBuffer_blitCommandEncoderWithDescriptor :: proc(self: ^CommandBuffer, blitPassDescriptor: ^BlitPassDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "blitCommandEncoderWithDescriptor:", blitPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="commandQueue")
CommandBuffer_commandQueue :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "commandQueue")
}
@(objc_type=CommandBuffer, objc_name="commit")
CommandBuffer_commit :: proc(self: ^CommandBuffer) {
	msgSend(nil, self, "commit")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoder")
CommandBuffer_computeCommandEncoder :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "computeCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDescriptor")
CommandBuffer_computeCommandEncoderWithDescriptor :: proc(self: ^CommandBuffer, computePassDescriptor: ^ComputePassDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "computeCommandEncoderWithDescriptor:", computePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="computeCommandEncoderWithDispatchType")
CommandBuffer_computeCommandEncoderWithDispatchType :: proc(self: ^CommandBuffer, dispatchType: DispatchType) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "computeCommandEncoderWithDispatchType:", dispatchType)
}
@(objc_type=CommandBuffer, objc_name="device")
CommandBuffer_device :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "device")
}
@(objc_type=CommandBuffer, objc_name="encodeSignalEvent")
CommandBuffer_encodeSignalEvent :: proc(self: ^CommandBuffer, event: ^NS.Object, value: u64) {
	msgSend(nil, self, "encodeSignalEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="encodeWaitForEvent")
CommandBuffer_encodeWaitForEvent :: proc(self: ^CommandBuffer, event: ^NS.Object, value: u64) {
	msgSend(nil, self, "encodeWaitForEvent:value:", event, value)
}
@(objc_type=CommandBuffer, objc_name="enqueue")
CommandBuffer_enqueue :: proc(self: ^CommandBuffer) {
	msgSend(nil, self, "enqueue")
}
@(objc_type=CommandBuffer, objc_name="error")
CommandBuffer_error :: proc(self: ^CommandBuffer) -> ^NS.Error {
	return msgSend(^NS.Error, self, "error")
}
@(objc_type=CommandBuffer, objc_name="errorOptions")
CommandBuffer_errorOptions :: proc(self: ^CommandBuffer) -> CommandBufferErrorOption {
	return msgSend(CommandBufferErrorOption, self, "errorOptions")
}
@(objc_type=CommandBuffer, objc_name="kernelEndTime")
CommandBuffer_kernelEndTime :: proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelEndTime")
}
@(objc_type=CommandBuffer, objc_name="kernelStartTime")
CommandBuffer_kernelStartTime :: proc(self: ^CommandBuffer) -> CFTimeInterval {
	return msgSend(CFTimeInterval, self, "kernelStartTime")
}
@(objc_type=CommandBuffer, objc_name="label")
CommandBuffer_label :: proc(self: ^CommandBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandBuffer, objc_name="logs")
CommandBuffer_logs :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "logs")
}
@(objc_type=CommandBuffer, objc_name="parallelRenderCommandEncoderWithDescriptor")
CommandBuffer_parallelRenderCommandEncoderWithDescriptor :: proc(self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "parallelRenderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="popDebugGroup")
CommandBuffer_popDebugGroup :: proc(self: ^CommandBuffer) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandBuffer, objc_name="presentDrawable")
CommandBuffer_presentDrawable :: proc(self: ^CommandBuffer, drawable: ^NS.Object) {
	msgSend(nil, self, "presentDrawable:", drawable)
}
@(objc_type=CommandBuffer, objc_name="presentDrawable_afterMinimumDuration_")
CommandBuffer_presentDrawable_afterMinimumDuration_ :: proc(self: ^CommandBuffer, drawable: ^NS.Object, duration: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:afterMinimumDuration:", drawable, duration)
}
@(objc_type=CommandBuffer, objc_name="presentDrawable_atTime_")
CommandBuffer_presentDrawable_atTime_ :: proc(self: ^CommandBuffer, drawable: ^NS.Object, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentDrawable:atTime:", drawable, presentationTime)
}
@(objc_type=CommandBuffer, objc_name="pushDebugGroup")
CommandBuffer_pushDebugGroup :: proc(self: ^CommandBuffer, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandBuffer, objc_name="renderCommandEncoderWithDescriptor")
CommandBuffer_renderCommandEncoderWithDescriptor :: proc(self: ^CommandBuffer, renderPassDescriptor: ^RenderPassDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "renderCommandEncoderWithDescriptor:", renderPassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoder")
CommandBuffer_resourceStateCommandEncoder :: proc(self: ^CommandBuffer) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "resourceStateCommandEncoder")
}
@(objc_type=CommandBuffer, objc_name="resourceStateCommandEncoderWithDescriptor")
CommandBuffer_resourceStateCommandEncoderWithDescriptor :: proc(self: ^CommandBuffer, resourceStatePassDescriptor: ^ResourceStatePassDescriptor) -> ^CommandBuffer {
	return msgSend(^CommandBuffer, self, "resourceStateCommandEncoderWithDescriptor:", resourceStatePassDescriptor)
}
@(objc_type=CommandBuffer, objc_name="retainedReferences")
CommandBuffer_retainedReferences :: proc(self: ^CommandBuffer) -> BOOL {
	return msgSend(BOOL, self, "retainedReferences")
}
@(objc_type=CommandBuffer, objc_name="setLabel")
CommandBuffer_setLabel :: proc(self: ^CommandBuffer, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=CommandBuffer, objc_name="status")
CommandBuffer_status :: proc(self: ^CommandBuffer) -> CommandBufferStatus {
	return msgSend(CommandBufferStatus, self, "status")
}
@(objc_type=CommandBuffer, objc_name="waitUntilCompleted")
CommandBuffer_waitUntilCompleted :: proc(self: ^CommandBuffer) {
	msgSend(nil, self, "waitUntilCompleted")
}
@(objc_type=CommandBuffer, objc_name="waitUntilScheduled")
CommandBuffer_waitUntilScheduled :: proc(self: ^CommandBuffer) {
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
CommandBufferEncoderInfo_debugSignposts :: proc(self: ^CommandBufferEncoderInfo) -> ^NS.Array {
	return msgSend(^NS.Array, self, "debugSignposts")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="errorState")
CommandBufferEncoderInfo_errorState :: proc(self: ^CommandBufferEncoderInfo) -> CommandEncoderErrorState {
	return msgSend(CommandEncoderErrorState, self, "errorState")
}
@(objc_type=CommandBufferEncoderInfo, objc_name="label")
CommandBufferEncoderInfo_label :: proc(self: ^CommandBufferEncoderInfo) -> ^NS.String {
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
CommandEncoder_device :: proc(self: ^CommandEncoder) -> ^CommandEncoder {
	return msgSend(^CommandEncoder, self, "device")
}
@(objc_type=CommandEncoder, objc_name="endEncoding")
CommandEncoder_endEncoding :: proc(self: ^CommandEncoder) {
	msgSend(nil, self, "endEncoding")
}
@(objc_type=CommandEncoder, objc_name="insertDebugSignpost")
CommandEncoder_insertDebugSignpost :: proc(self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "insertDebugSignpost:", string)
}
@(objc_type=CommandEncoder, objc_name="label")
CommandEncoder_label :: proc(self: ^CommandEncoder) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandEncoder, objc_name="popDebugGroup")
CommandEncoder_popDebugGroup :: proc(self: ^CommandEncoder) {
	msgSend(nil, self, "popDebugGroup")
}
@(objc_type=CommandEncoder, objc_name="pushDebugGroup")
CommandEncoder_pushDebugGroup :: proc(self: ^CommandEncoder, string: ^NS.String) {
	msgSend(nil, self, "pushDebugGroup:", string)
}
@(objc_type=CommandEncoder, objc_name="setLabel")
CommandEncoder_setLabel :: proc(self: ^CommandEncoder, label: ^NS.String) {
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
CommandQueue_commandBuffer :: proc(self: ^CommandQueue) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandBuffer")
}
@(objc_type=CommandQueue, objc_name="commandBufferWithDescriptor")
CommandQueue_commandBufferWithDescriptor :: proc(self: ^CommandQueue, descriptor: ^CommandBufferDescriptor) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandBufferWithDescriptor:", descriptor)
}
@(objc_type=CommandQueue, objc_name="commandBufferWithUnretainedReferences")
CommandQueue_commandBufferWithUnretainedReferences :: proc(self: ^CommandQueue) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "commandBufferWithUnretainedReferences")
}
@(objc_type=CommandQueue, objc_name="device")
CommandQueue_device :: proc(self: ^CommandQueue) -> ^CommandQueue {
	return msgSend(^CommandQueue, self, "device")
}
@(objc_type=CommandQueue, objc_name="insertDebugCaptureBoundary")
CommandQueue_insertDebugCaptureBoundary :: proc(self: ^CommandQueue) {
	msgSend(nil, self, "insertDebugCaptureBoundary")
}
@(objc_type=CommandQueue, objc_name="label")
CommandQueue_label :: proc(self: ^CommandQueue) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CommandQueue, objc_name="setLabel")
CommandQueue_setLabel :: proc(self: ^CommandQueue, label: ^NS.String) {
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
ComputeCommandEncoder :: struct { using _: NS.Object }

@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroups")
ComputeCommandEncoder_dispatchThreadgroups :: proc(self: ^ComputeCommandEncoder, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreadgroupsWithIndirectBuffer")
ComputeCommandEncoder_dispatchThreadgroupsWithIndirectBuffer :: proc(self: ^ComputeCommandEncoder, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:", indirectBuffer, indirectBufferOffset, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchThreads")
ComputeCommandEncoder_dispatchThreads :: proc(self: ^ComputeCommandEncoder, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "dispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=ComputeCommandEncoder, objc_name="dispatchType")
ComputeCommandEncoder_dispatchType :: proc(self: ^ComputeCommandEncoder) -> DispatchType {
	return msgSend(DispatchType, self, "dispatchType")
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_")
ComputeCommandEncoder_executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_ :: proc(self: ^ComputeCommandEncoder, indirectCommandbuffer: ^NS.Object, indirectRangeBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="executeCommandsInBuffer_withRange_")
ComputeCommandEncoder_executeCommandsInBuffer_withRange_ :: proc(self: ^ComputeCommandEncoder, indirectCommandBuffer: ^NS.Object, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithResources")
ComputeCommandEncoder_memoryBarrierWithResources :: proc(self: ^ComputeCommandEncoder, resources: ^^NS.Object, count: ^NS.Object) {
	msgSend(nil, self, "memoryBarrierWithResources:count:", resources, count)
}
@(objc_type=ComputeCommandEncoder, objc_name="memoryBarrierWithScope")
ComputeCommandEncoder_memoryBarrierWithScope :: proc(self: ^ComputeCommandEncoder, scope: BarrierScope) {
	msgSend(nil, self, "memoryBarrierWithScope:", scope)
}
@(objc_type=ComputeCommandEncoder, objc_name="sampleCountersInBuffer")
ComputeCommandEncoder_sampleCountersInBuffer :: proc(self: ^ComputeCommandEncoder, sampleBuffer: ^NS.Object, sampleIndex: ^NS.Object, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=ComputeCommandEncoder, objc_name="setAccelerationStructure")
ComputeCommandEncoder_setAccelerationStructure :: proc(self: ^ComputeCommandEncoder, accelerationStructure: ^NS.Object, bufferIndex: ^NS.Object) {
	msgSend(nil, self, "setAccelerationStructure:atBufferIndex:", accelerationStructure, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffer")
ComputeCommandEncoder_setBuffer :: proc(self: ^ComputeCommandEncoder, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBufferOffset")
ComputeCommandEncoder_setBufferOffset :: proc(self: ^ComputeCommandEncoder, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setBufferOffset:atIndex:", offset, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBuffers")
ComputeCommandEncoder_setBuffers :: proc(self: ^ComputeCommandEncoder, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setBytes")
ComputeCommandEncoder_setBytes :: proc(self: ^ComputeCommandEncoder, bytes: rawptr, length: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setComputePipelineState")
ComputeCommandEncoder_setComputePipelineState :: proc(self: ^ComputeCommandEncoder, pipelineState: ^NS.Object) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=ComputeCommandEncoder, objc_name="setImageblockWidth")
ComputeCommandEncoder_setImageblockWidth :: proc(self: ^ComputeCommandEncoder, width: ^NS.Object, height: ^NS.Object) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTable")
ComputeCommandEncoder_setIntersectionFunctionTable :: proc(self: ^ComputeCommandEncoder, intersectionFunctionTable: ^NS.Object, bufferIndex: ^NS.Object) {
	msgSend(nil, self, "setIntersectionFunctionTable:atBufferIndex:", intersectionFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setIntersectionFunctionTables")
ComputeCommandEncoder_setIntersectionFunctionTables :: proc(self: ^ComputeCommandEncoder, intersectionFunctionTables: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setIntersectionFunctionTables:withBufferRange:", intersectionFunctionTables, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerState_atIndex_")
ComputeCommandEncoder_setSamplerState_atIndex_ :: proc(self: ^ComputeCommandEncoder, sampler: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setSamplerState:atIndex:", sampler, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerState_lodMinClamp_lodMaxClamp_atIndex_")
ComputeCommandEncoder_setSamplerState_lodMinClamp_lodMaxClamp_atIndex_ :: proc(self: ^ComputeCommandEncoder, sampler: ^NS.Object, lodMinClamp: f32, lodMaxClamp: f32, index: ^NS.Object) {
	msgSend(nil, self, "setSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStates_lodMinClamps_lodMaxClamps_withRange_")
ComputeCommandEncoder_setSamplerStates_lodMinClamps_lodMaxClamps_withRange_ :: proc(self: ^ComputeCommandEncoder, samplers: ^^NS.Object, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStates_withRange_")
ComputeCommandEncoder_setSamplerStates_withRange_ :: proc(self: ^ComputeCommandEncoder, samplers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:withRange:", samplers, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegion")
ComputeCommandEncoder_setStageInRegion :: proc(self: ^ComputeCommandEncoder, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=ComputeCommandEncoder, objc_name="setStageInRegionWithIndirectBuffer")
ComputeCommandEncoder_setStageInRegionWithIndirectBuffer :: proc(self: ^ComputeCommandEncoder, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "setStageInRegionWithIndirectBuffer:indirectBufferOffset:", indirectBuffer, indirectBufferOffset)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTexture")
ComputeCommandEncoder_setTexture :: proc(self: ^ComputeCommandEncoder, texture: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTexture:atIndex:", texture, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setTextures")
ComputeCommandEncoder_setTextures :: proc(self: ^ComputeCommandEncoder, textures: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setTextures:withRange:", textures, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="setThreadgroupMemoryLength")
ComputeCommandEncoder_setThreadgroupMemoryLength :: proc(self: ^ComputeCommandEncoder, length: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setThreadgroupMemoryLength:atIndex:", length, index)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTable")
ComputeCommandEncoder_setVisibleFunctionTable :: proc(self: ^ComputeCommandEncoder, visibleFunctionTable: ^NS.Object, bufferIndex: ^NS.Object) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=ComputeCommandEncoder, objc_name="setVisibleFunctionTables")
ComputeCommandEncoder_setVisibleFunctionTables :: proc(self: ^ComputeCommandEncoder, visibleFunctionTables: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", visibleFunctionTables, range)
}
@(objc_type=ComputeCommandEncoder, objc_name="updateFence")
ComputeCommandEncoder_updateFence :: proc(self: ^ComputeCommandEncoder, fence: ^NS.Object) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeap")
ComputeCommandEncoder_useHeap :: proc(self: ^ComputeCommandEncoder, heap: ^NS.Object) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=ComputeCommandEncoder, objc_name="useHeaps")
ComputeCommandEncoder_useHeaps :: proc(self: ^ComputeCommandEncoder, heaps: ^^NS.Object, count: ^NS.Object) {
	msgSend(nil, self, "useHeaps:count:", heaps, count)
}
@(objc_type=ComputeCommandEncoder, objc_name="useResource")
ComputeCommandEncoder_useResource :: proc(self: ^ComputeCommandEncoder, resource: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="useResources")
ComputeCommandEncoder_useResources :: proc(self: ^ComputeCommandEncoder, resources: ^^NS.Object, count: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, count, usage)
}
@(objc_type=ComputeCommandEncoder, objc_name="waitForFence")
ComputeCommandEncoder_waitForFence :: proc(self: ^ComputeCommandEncoder, fence: ^NS.Object) {
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
ComputePipelineState_device :: proc(self: ^ComputePipelineState) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "device")
}
@(objc_type=ComputePipelineState, objc_name="functionHandleWithFunction")
ComputePipelineState_functionHandleWithFunction :: proc(self: ^ComputePipelineState, function: ^NS.Object) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "functionHandleWithFunction:", function)
}
@(objc_type=ComputePipelineState, objc_name="imageblockMemoryLengthForDimensions")
ComputePipelineState_imageblockMemoryLengthForDimensions :: proc(self: ^ComputePipelineState, imageblockDimensions: Size) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=ComputePipelineState, objc_name="label")
ComputePipelineState_label :: proc(self: ^ComputePipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=ComputePipelineState, objc_name="maxTotalThreadsPerThreadgroup")
ComputePipelineState_maxTotalThreadsPerThreadgroup :: proc(self: ^ComputePipelineState) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=ComputePipelineState, objc_name="newComputePipelineStateWithAdditionalBinaryFunctions")
ComputePipelineState_newComputePipelineStateWithAdditionalBinaryFunctions :: proc(self: ^ComputePipelineState, functions: ^NS.Array, error: ^^NS.Error ) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newComputePipelineStateWithAdditionalBinaryFunctions:error:", functions, error)
}
@(objc_type=ComputePipelineState, objc_name="newIntersectionFunctionTableWithDescriptor")
ComputePipelineState_newIntersectionFunctionTableWithDescriptor :: proc(self: ^ComputePipelineState, descriptor: ^IntersectionFunctionTableDescriptor) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newIntersectionFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="newVisibleFunctionTableWithDescriptor")
ComputePipelineState_newVisibleFunctionTableWithDescriptor :: proc(self: ^ComputePipelineState, descriptor: ^VisibleFunctionTableDescriptor) -> ^ComputePipelineState {
	return msgSend(^ComputePipelineState, self, "newVisibleFunctionTableWithDescriptor:", descriptor)
}
@(objc_type=ComputePipelineState, objc_name="staticThreadgroupMemoryLength")
ComputePipelineState_staticThreadgroupMemoryLength :: proc(self: ^ComputePipelineState) -> NS.Integer {
	return msgSend(NS.Integer, self, "staticThreadgroupMemoryLength")
}
@(objc_type=ComputePipelineState, objc_name="supportIndirectCommandBuffers")
ComputePipelineState_supportIndirectCommandBuffers :: proc(self: ^ComputePipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=ComputePipelineState, objc_name="threadExecutionWidth")
ComputePipelineState_threadExecutionWidth :: proc(self: ^ComputePipelineState) -> NS.Integer {
	return msgSend(NS.Integer, self, "threadExecutionWidth")
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
Counter_name :: proc(self: ^Counter) -> ^NS.String {
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
CounterSampleBuffer_device :: proc(self: ^CounterSampleBuffer) -> ^CounterSampleBuffer {
	return msgSend(^CounterSampleBuffer, self, "device")
}
@(objc_type=CounterSampleBuffer, objc_name="label")
CounterSampleBuffer_label :: proc(self: ^CounterSampleBuffer) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=CounterSampleBuffer, objc_name="resolveCounterRange")
CounterSampleBuffer_resolveCounterRange :: proc(self: ^CounterSampleBuffer, range: NS.Range) -> ^NS.Data {
	return msgSend(^NS.Data, self, "resolveCounterRange:", range)
}
@(objc_type=CounterSampleBuffer, objc_name="sampleCount")
CounterSampleBuffer_sampleCount :: proc(self: ^CounterSampleBuffer) -> NS.Integer {
	return msgSend(NS.Integer, self, "sampleCount")
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
CounterSet_counters :: proc(self: ^CounterSet) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counters")
}
@(objc_type=CounterSet, objc_name="name")
CounterSet_name :: proc(self: ^CounterSet) -> ^NS.String {
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
DepthStencilState_device :: proc(self: ^DepthStencilState) -> ^DepthStencilState {
	return msgSend(^DepthStencilState, self, "device")
}
@(objc_type=DepthStencilState, objc_name="label")
DepthStencilState_label :: proc(self: ^DepthStencilState) -> ^NS.String {
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
	newSamplerStateWithDescriptor
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
Device_accelerationStructureSizesWithDescriptor :: proc(self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> AccelerationStructureSizes {
	return msgSend(AccelerationStructureSizes, self, "accelerationStructureSizesWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="areBarycentricCoordsSupported")
Device_areBarycentricCoordsSupported :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areBarycentricCoordsSupported")
}
@(objc_type=Device, objc_name="areProgrammableSamplePositionsSupported")
Device_areProgrammableSamplePositionsSupported :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areProgrammableSamplePositionsSupported")
}
@(objc_type=Device, objc_name="areRasterOrderGroupsSupported")
Device_areRasterOrderGroupsSupported :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "areRasterOrderGroupsSupported")
}
@(objc_type=Device, objc_name="argumentBuffersSupport")
Device_argumentBuffersSupport :: proc(self: ^Device) -> ArgumentBuffersTier {
	return msgSend(ArgumentBuffersTier, self, "argumentBuffersSupport")
}
@(objc_type=Device, objc_name="convertSparsePixelRegions")
Device_convertSparsePixelRegions :: proc(self: ^Device, pixelRegions: ^Region, tileRegions: ^Region, tileSize: Size, mode: SparseTextureRegionAlignmentMode, numRegions: ^NS.Object) {
	msgSend(nil, self, "convertSparsePixelRegions:toTileRegions:withTileSize:alignmentMode:numRegions:", pixelRegions, tileRegions, tileSize, mode, numRegions)
}
@(objc_type=Device, objc_name="convertSparseTileRegions")
Device_convertSparseTileRegions :: proc(self: ^Device, tileRegions: ^Region, pixelRegions: ^Region, tileSize: Size, numRegions: ^NS.Object) {
	msgSend(nil, self, "convertSparseTileRegions:toPixelRegions:withTileSize:numRegions:", tileRegions, pixelRegions, tileSize, numRegions)
}
@(objc_type=Device, objc_name="counterSets")
Device_counterSets :: proc(self: ^Device) -> ^NS.Array {
	return msgSend(^NS.Array, self, "counterSets")
}
@(objc_type=Device, objc_name="currentAllocatedSize")
Device_currentAllocatedSize :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "currentAllocatedSize")
}
@(objc_type=Device, objc_name="getDefaultSamplePositions")
Device_getDefaultSamplePositions :: proc(self: ^Device, positions: ^SamplePosition, count: ^NS.Object) {
	msgSend(nil, self, "getDefaultSamplePositions:count:", positions, count)
}
@(objc_type=Device, objc_name="hasUnifiedMemory")
Device_hasUnifiedMemory :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "hasUnifiedMemory")
}
@(objc_type=Device, objc_name="heapBufferSizeAndAlignWithLength")
Device_heapBufferSizeAndAlignWithLength :: proc(self: ^Device, length: ^NS.Object, options: ResourceOptions) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "heapBufferSizeAndAlignWithLength:options:", length, options)
}
@(objc_type=Device, objc_name="heapTextureSizeAndAlignWithDescriptor")
Device_heapTextureSizeAndAlignWithDescriptor :: proc(self: ^Device, desc: ^TextureDescriptor) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "heapTextureSizeAndAlignWithDescriptor:", desc)
}
@(objc_type=Device, objc_name="isDepth24Stencil8PixelFormatSupported")
Device_isDepth24Stencil8PixelFormatSupported :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isDepth24Stencil8PixelFormatSupported")
}
@(objc_type=Device, objc_name="isHeadless")
Device_isHeadless :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isHeadless")
}
@(objc_type=Device, objc_name="isLowPower")
Device_isLowPower :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isLowPower")
}
@(objc_type=Device, objc_name="isRemovable")
Device_isRemovable :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "isRemovable")
}
@(objc_type=Device, objc_name="location")
Device_location :: proc(self: ^Device) -> DeviceLocation {
	return msgSend(DeviceLocation, self, "location")
}
@(objc_type=Device, objc_name="locationNumber")
Device_locationNumber :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "locationNumber")
}
@(objc_type=Device, objc_name="maxArgumentBufferSamplerCount")
Device_maxArgumentBufferSamplerCount :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxArgumentBufferSamplerCount")
}
@(objc_type=Device, objc_name="maxBufferLength")
Device_maxBufferLength :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxBufferLength")
}
@(objc_type=Device, objc_name="maxThreadgroupMemoryLength")
Device_maxThreadgroupMemoryLength :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxThreadgroupMemoryLength")
}
@(objc_type=Device, objc_name="maxThreadsPerThreadgroup")
Device_maxThreadsPerThreadgroup :: proc(self: ^Device) -> Size {
	return msgSend(Size, self, "maxThreadsPerThreadgroup")
}
@(objc_type=Device, objc_name="maxTransferRate")
Device_maxTransferRate :: proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "maxTransferRate")
}
@(objc_type=Device, objc_name="minimumLinearTextureAlignmentForPixelFormat")
Device_minimumLinearTextureAlignmentForPixelFormat :: proc(self: ^Device, format: PixelFormat) -> ^Device {
	return msgSend(^Device, self, "minimumLinearTextureAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="minimumTextureBufferAlignmentForPixelFormat")
Device_minimumTextureBufferAlignmentForPixelFormat :: proc(self: ^Device, format: PixelFormat) -> ^Device {
	return msgSend(^Device, self, "minimumTextureBufferAlignmentForPixelFormat:", format)
}
@(objc_type=Device, objc_name="name")
Device_name :: proc(self: ^Device) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Device, objc_name="newAccelerationStructureWithDescriptor")
Device_newAccelerationStructureWithDescriptor :: proc(self: ^Device, descriptor: ^AccelerationStructureDescriptor) -> ^Device {
	return msgSend(^Device, self, "newAccelerationStructureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newAccelerationStructureWithSize")
Device_newAccelerationStructureWithSize :: proc(self: ^Device, size: ^NS.Object) -> ^Device {
	return msgSend(^Device, self, "newAccelerationStructureWithSize:", size)
}
@(objc_type=Device, objc_name="newArgumentEncoderWithArguments")
Device_newArgumentEncoderWithArguments :: proc(self: ^Device, arguments: ^NS.Array) -> ^Device {
	return msgSend(^Device, self, "newArgumentEncoderWithArguments:", arguments)
}
@(objc_type=Device, objc_name="newBinaryArchiveWithDescriptor")
Device_newBinaryArchiveWithDescriptor :: proc(self: ^Device, descriptor: ^BinaryArchiveDescriptor, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newBinaryArchiveWithDescriptor:error:", descriptor, error)
}
@(objc_type=Device, objc_name="newBufferWithBytes")
Device_newBufferWithBytes :: proc(self: ^Device, pointer: rawptr, length: ^NS.Object, options: ResourceOptions) -> ^Device {
	return msgSend(^Device, self, "newBufferWithBytes:length:options:", pointer, length, options)
}
@(objc_type=Device, objc_name="newBufferWithBytesNoCopy")
Device_newBufferWithBytesNoCopy :: proc(self: ^Device, pointer: rawptr, length: ^NS.Object, options: ResourceOptions, deallocator: rawptr) -> ^Device {
	return msgSend(^Device, self, "newBufferWithBytesNoCopy:length:options:deallocator:", pointer, length, options, deallocator)
}
@(objc_type=Device, objc_name="newBufferWithLength")
Device_newBufferWithLength :: proc(self: ^Device, length: ^NS.Object, options: ResourceOptions) -> ^Device {
	return msgSend(^Device, self, "newBufferWithLength:options:", length, options)
}
@(objc_type=Device, objc_name="newCommandQueue")
Device_newCommandQueue :: proc(self: ^Device) -> ^Device {
	return msgSend(^Device, self, "newCommandQueue")
}
@(objc_type=Device, objc_name="newCommandQueueWithMaxCommandBufferCount")
Device_newCommandQueueWithMaxCommandBufferCount :: proc(self: ^Device, maxCommandBufferCount: ^NS.Object) -> ^Device {
	return msgSend(^Device, self, "newCommandQueueWithMaxCommandBufferCount:", maxCommandBufferCount)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptor_options_completionHandler_")
Device_newComputePipelineStateWithDescriptor_options_completionHandler_ :: proc(self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithDescriptor_options_reflection_error_")
Device_newComputePipelineStateWithDescriptor_options_reflection_error_ :: proc(self: ^Device, descriptor: ^ComputePipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newComputePipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, error)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction_completionHandler_")
Device_newComputePipelineStateWithFunction_completionHandler_ :: proc(self: ^Device, computeFunction: ^NS.Object, completionHandler: NewComputePipelineStateCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithFunction:completionHandler:", computeFunction, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction_error_")
Device_newComputePipelineStateWithFunction_error_ :: proc(self: ^Device, computeFunction: ^NS.Object, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newComputePipelineStateWithFunction:error:", computeFunction, error)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction_options_completionHandler_")
Device_newComputePipelineStateWithFunction_options_completionHandler_ :: proc(self: ^Device, computeFunction: ^NS.Object, options: PipelineOption, completionHandler: NewComputePipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newComputePipelineStateWithFunction:options:completionHandler:", computeFunction, options, completionHandler)
}
@(objc_type=Device, objc_name="newComputePipelineStateWithFunction_options_reflection_error_")
Device_newComputePipelineStateWithFunction_options_reflection_error_ :: proc(self: ^Device, computeFunction: ^NS.Object, options: PipelineOption, reflection: ^AutoreleasedComputePipelineReflection, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newComputePipelineStateWithFunction:options:reflection:error:", computeFunction, options, reflection, error)
}
@(objc_type=Device, objc_name="newCounterSampleBufferWithDescriptor")
Device_newCounterSampleBufferWithDescriptor :: proc(self: ^Device, descriptor: ^CounterSampleBufferDescriptor, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newCounterSampleBufferWithDescriptor:error:", descriptor, error)
}
@(objc_type=Device, objc_name="newDefaultLibrary")
Device_newDefaultLibrary :: proc(self: ^Device) -> ^Device {
	return msgSend(^Device, self, "newDefaultLibrary")
}
@(objc_type=Device, objc_name="newDefaultLibraryWithBundle")
Device_newDefaultLibraryWithBundle :: proc(self: ^Device, bundle: ^NS.Bundle, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newDefaultLibraryWithBundle:error:", bundle, error)
}
@(objc_type=Device, objc_name="newDepthStencilStateWithDescriptor")
Device_newDepthStencilStateWithDescriptor :: proc(self: ^Device, descriptor: ^DepthStencilDescriptor) -> ^Device {
	return msgSend(^Device, self, "newDepthStencilStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newDynamicLibrary")
Device_newDynamicLibrary :: proc(self: ^Device, library: ^NS.Object, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newDynamicLibrary:error:", library, error)
}
@(objc_type=Device, objc_name="newDynamicLibraryWithURL")
Device_newDynamicLibraryWithURL :: proc(self: ^Device, url: ^NS.URL, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newDynamicLibraryWithURL:error:", url, error)
}
@(objc_type=Device, objc_name="newEvent")
Device_newEvent :: proc(self: ^Device) -> ^Device {
	return msgSend(^Device, self, "newEvent")
}
@(objc_type=Device, objc_name="newFence")
Device_newFence :: proc(self: ^Device) -> ^Device {
	return msgSend(^Device, self, "newFence")
}
@(objc_type=Device, objc_name="newHeapWithDescriptor")
Device_newHeapWithDescriptor :: proc(self: ^Device, descriptor: ^HeapDescriptor) -> ^Device {
	return msgSend(^Device, self, "newHeapWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newIndirectCommandBufferWithDescriptor")
Device_newIndirectCommandBufferWithDescriptor :: proc(self: ^Device, descriptor: ^IndirectCommandBufferDescriptor, maxCount: ^NS.Object, options: ResourceOptions) -> ^Device {
	return msgSend(^Device, self, "newIndirectCommandBufferWithDescriptor:maxCommandCount:options:", descriptor, maxCount, options)
}
@(objc_type=Device, objc_name="newLibraryWithData")
Device_newLibraryWithData :: proc(self: ^Device, data: ^NS.Object, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newLibraryWithData:error:", data, error)
}
@(objc_type=Device, objc_name="newLibraryWithFile")
Device_newLibraryWithFile :: proc(self: ^Device, filepath: ^NS.String, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newLibraryWithFile:error:", filepath, error)
}
@(objc_type=Device, objc_name="newLibraryWithSource_options_completionHandler_")
Device_newLibraryWithSource_options_completionHandler_ :: proc(self: ^Device, source: ^NS.String, options: ^CompileOptions, completionHandler: NewLibraryCompletionHandler) {
	msgSend(nil, self, "newLibraryWithSource:options:completionHandler:", source, options, completionHandler)
}
@(objc_type=Device, objc_name="newLibraryWithSource_options_error_")
Device_newLibraryWithSource_options_error_ :: proc(self: ^Device, source: ^NS.String, options: ^CompileOptions, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newLibraryWithSource:options:error:", source, options, error)
}
@(objc_type=Device, objc_name="newLibraryWithURL")
Device_newLibraryWithURL :: proc(self: ^Device, url: ^NS.URL, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newLibraryWithURL:error:", url, error)
}
@(objc_type=Device, objc_name="newRasterizationRateMapWithDescriptor")
Device_newRasterizationRateMapWithDescriptor :: proc(self: ^Device, descriptor: ^RasterizationRateMapDescriptor) -> ^Device {
	return msgSend(^Device, self, "newRasterizationRateMapWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor_completionHandler_")
Device_newRenderPipelineStateWithDescriptor_completionHandler_ :: proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, completionHandler: NewRenderPipelineStateCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor_error_")
Device_newRenderPipelineStateWithDescriptor_error_ :: proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newRenderPipelineStateWithDescriptor:error:", descriptor, error)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor_options_completionHandler_")
Device_newRenderPipelineStateWithDescriptor_options_completionHandler_ :: proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithDescriptor_options_reflection_error_")
Device_newRenderPipelineStateWithDescriptor_options_reflection_error_ :: proc(self: ^Device, descriptor: ^RenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newRenderPipelineStateWithDescriptor:options:reflection:error:", descriptor, options, reflection, error)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptor_options_completionHandler_")
Device_newRenderPipelineStateWithTileDescriptor_options_completionHandler_ :: proc(self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, completionHandler: NewRenderPipelineStateWithReflectionCompletionHandler) {
	msgSend(nil, self, "newRenderPipelineStateWithTileDescriptor:options:completionHandler:", descriptor, options, completionHandler)
}
@(objc_type=Device, objc_name="newRenderPipelineStateWithTileDescriptor_options_reflection_error_")
Device_newRenderPipelineStateWithTileDescriptor_options_reflection_error_ :: proc(self: ^Device, descriptor: ^TileRenderPipelineDescriptor, options: PipelineOption, reflection: ^AutoreleasedRenderPipelineReflection, error: ^^NS.Error ) -> ^Device {
	return msgSend(^Device, self, "newRenderPipelineStateWithTileDescriptor:options:reflection:error:", descriptor, options, reflection, error)
}
@(objc_type=Device, objc_name="newSamplerStateWithDescriptor")
Device_newSamplerStateWithDescriptor :: proc(self: ^Device, descriptor: ^SamplerDescriptor) -> ^Device {
	return msgSend(^Device, self, "newSamplerStateWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedEvent")
Device_newSharedEvent :: proc(self: ^Device) -> ^Device {
	return msgSend(^Device, self, "newSharedEvent")
}
@(objc_type=Device, objc_name="newSharedEventWithHandle")
Device_newSharedEventWithHandle :: proc(self: ^Device, sharedEventHandle: ^SharedEventHandle) -> ^Device {
	return msgSend(^Device, self, "newSharedEventWithHandle:", sharedEventHandle)
}
@(objc_type=Device, objc_name="newSharedTextureWithDescriptor")
Device_newSharedTextureWithDescriptor :: proc(self: ^Device, descriptor: ^TextureDescriptor) -> ^Device {
	return msgSend(^Device, self, "newSharedTextureWithDescriptor:", descriptor)
}
@(objc_type=Device, objc_name="newSharedTextureWithHandle")
Device_newSharedTextureWithHandle :: proc(self: ^Device, sharedHandle: ^SharedTextureHandle) -> ^Device {
	return msgSend(^Device, self, "newSharedTextureWithHandle:", sharedHandle)
}
@(objc_type=Device, objc_name="newTextureWithDescriptor")
Device_newTextureWithDescriptor :: proc(self: ^Device, desc: ^TextureDescriptor) -> ^Device {
	return msgSend(^Device, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Device, objc_name="newTextureWithDescriptor_iosurface_plane_")
Device_newTextureWithDescriptor_iosurface_plane_ :: proc(self: ^Device, descriptor: ^TextureDescriptor, iosurface: IOSurfaceRef, plane: ^NS.Object) -> ^Device {
	return msgSend(^Device, self, "newTextureWithDescriptor:iosurface:plane:", descriptor, iosurface, plane)
}
@(objc_type=Device, objc_name="peerCount")
Device_peerCount :: proc(self: ^Device) -> u32 {
	return msgSend(u32, self, "peerCount")
}
@(objc_type=Device, objc_name="peerGroupID")
Device_peerGroupID :: proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "peerGroupID")
}
@(objc_type=Device, objc_name="peerIndex")
Device_peerIndex :: proc(self: ^Device) -> u32 {
	return msgSend(u32, self, "peerIndex")
}
@(objc_type=Device, objc_name="readWriteTextureSupport")
Device_readWriteTextureSupport :: proc(self: ^Device) -> ReadWriteTextureTier {
	return msgSend(ReadWriteTextureTier, self, "readWriteTextureSupport")
}
@(objc_type=Device, objc_name="recommendedMaxWorkingSetSize")
Device_recommendedMaxWorkingSetSize :: proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "recommendedMaxWorkingSetSize")
}
@(objc_type=Device, objc_name="registryID")
Device_registryID :: proc(self: ^Device) -> u64 {
	return msgSend(u64, self, "registryID")
}
@(objc_type=Device, objc_name="sampleTimestamps")
Device_sampleTimestamps :: proc(self: ^Device, cpuTimestamp: ^Timestamp, gpuTimestamp: ^Timestamp) {
	msgSend(nil, self, "sampleTimestamps:gpuTimestamp:", cpuTimestamp, gpuTimestamp)
}
@(objc_type=Device, objc_name="sparseTileSizeInBytes")
Device_sparseTileSizeInBytes :: proc(self: ^Device) -> NS.Integer {
	return msgSend(NS.Integer, self, "sparseTileSizeInBytes")
}
@(objc_type=Device, objc_name="sparseTileSizeWithTextureType")
Device_sparseTileSizeWithTextureType :: proc(self: ^Device, textureType: TextureType, pixelFormat: PixelFormat, sampleCount: ^NS.Object) -> Size {
	return msgSend(Size, self, "sparseTileSizeWithTextureType:pixelFormat:sampleCount:", textureType, pixelFormat, sampleCount)
}
@(objc_type=Device, objc_name="supports32BitFloatFiltering")
Device_supports32BitFloatFiltering :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitFloatFiltering")
}
@(objc_type=Device, objc_name="supports32BitMSAA")
Device_supports32BitMSAA :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supports32BitMSAA")
}
@(objc_type=Device, objc_name="supportsBCTextureCompression")
Device_supportsBCTextureCompression :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsBCTextureCompression")
}
@(objc_type=Device, objc_name="supportsCounterSampling")
Device_supportsCounterSampling :: proc(self: ^Device, samplingPoint: CounterSamplingPoint) -> BOOL {
	return msgSend(BOOL, self, "supportsCounterSampling:", samplingPoint)
}
@(objc_type=Device, objc_name="supportsDynamicLibraries")
Device_supportsDynamicLibraries :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsDynamicLibraries")
}
@(objc_type=Device, objc_name="supportsFamily")
Device_supportsFamily :: proc(self: ^Device, gpuFamily: GPUFamily) -> BOOL {
	return msgSend(BOOL, self, "supportsFamily:", gpuFamily)
}
@(objc_type=Device, objc_name="supportsFeatureSet")
Device_supportsFeatureSet :: proc(self: ^Device, featureSet: FeatureSet) -> BOOL {
	return msgSend(BOOL, self, "supportsFeatureSet:", featureSet)
}
@(objc_type=Device, objc_name="supportsFunctionPointers")
Device_supportsFunctionPointers :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsFunctionPointers")
}
@(objc_type=Device, objc_name="supportsPullModelInterpolation")
Device_supportsPullModelInterpolation :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsPullModelInterpolation")
}
@(objc_type=Device, objc_name="supportsQueryTextureLOD")
Device_supportsQueryTextureLOD :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsQueryTextureLOD")
}
@(objc_type=Device, objc_name="supportsRasterizationRateMapWithLayerCount")
Device_supportsRasterizationRateMapWithLayerCount :: proc(self: ^Device, layerCount: ^NS.Object) -> BOOL {
	return msgSend(BOOL, self, "supportsRasterizationRateMapWithLayerCount:", layerCount)
}
@(objc_type=Device, objc_name="supportsRaytracing")
Device_supportsRaytracing :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsRaytracing")
}
@(objc_type=Device, objc_name="supportsShaderBarycentricCoordinates")
Device_supportsShaderBarycentricCoordinates :: proc(self: ^Device) -> BOOL {
	return msgSend(BOOL, self, "supportsShaderBarycentricCoordinates")
}
@(objc_type=Device, objc_name="supportsTextureSampleCount")
Device_supportsTextureSampleCount :: proc(self: ^Device, sampleCount: ^NS.Object) -> BOOL {
	return msgSend(BOOL, self, "supportsTextureSampleCount:", sampleCount)
}
@(objc_type=Device, objc_name="supportsVertexAmplificationCount")
Device_supportsVertexAmplificationCount :: proc(self: ^Device, count: ^NS.Object) -> BOOL {
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
Drawable_addPresentedHandler :: proc(self: ^Drawable, block: DrawablePresentedHandler) {
	msgSend(nil, self, "addPresentedHandler:", block)
}
@(objc_type=Drawable, objc_name="drawableID")
Drawable_drawableID :: proc(self: ^Drawable) -> NS.Integer {
	return msgSend(NS.Integer, self, "drawableID")
}
@(objc_type=Drawable, objc_name="present")
Drawable_present :: proc(self: ^Drawable) {
	msgSend(nil, self, "present")
}
@(objc_type=Drawable, objc_name="presentAfterMinimumDuration")
Drawable_presentAfterMinimumDuration :: proc(self: ^Drawable, duration: CFTimeInterval) {
	msgSend(nil, self, "presentAfterMinimumDuration:", duration)
}
@(objc_type=Drawable, objc_name="presentAtTime")
Drawable_presentAtTime :: proc(self: ^Drawable, presentationTime: CFTimeInterval) {
	msgSend(nil, self, "presentAtTime:", presentationTime)
}
@(objc_type=Drawable, objc_name="presentedTime")
Drawable_presentedTime :: proc(self: ^Drawable) -> CFTimeInterval {
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
DynamicLibrary_device :: proc(self: ^DynamicLibrary) -> ^DynamicLibrary {
	return msgSend(^DynamicLibrary, self, "device")
}
@(objc_type=DynamicLibrary, objc_name="installName")
DynamicLibrary_installName :: proc(self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=DynamicLibrary, objc_name="label")
DynamicLibrary_label :: proc(self: ^DynamicLibrary) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=DynamicLibrary, objc_name="serializeToURL")
DynamicLibrary_serializeToURL :: proc(self: ^DynamicLibrary, url: ^NS.URL, error: ^^NS.Error ) -> BOOL {
	return msgSend(BOOL, self, "serializeToURL:error:", url, error)
}
@(objc_type=DynamicLibrary, objc_name="setLabel")
DynamicLibrary_setLabel :: proc(self: ^DynamicLibrary, label: ^NS.String) {
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
Event_device :: proc(self: ^Event) -> ^Event {
	return msgSend(^Event, self, "device")
}
@(objc_type=Event, objc_name="label")
Event_label :: proc(self: ^Event) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Event, objc_name="setLabel")
Event_setLabel :: proc(self: ^Event, label: ^NS.String) {
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
Fence_device :: proc(self: ^Fence) -> ^Fence {
	return msgSend(^Fence, self, "device")
}
@(objc_type=Fence, objc_name="label")
Fence_label :: proc(self: ^Fence) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Fence, objc_name="setLabel")
Fence_setLabel :: proc(self: ^Fence, label: ^NS.String) {
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
Function_device :: proc(self: ^Function) -> ^Function {
	return msgSend(^Function, self, "device")
}
@(objc_type=Function, objc_name="functionConstantsDictionary")
Function_functionConstantsDictionary :: proc(self: ^Function) -> ^NS.Dictionary {
	return msgSend(^NS.Dictionary, self, "functionConstantsDictionary")
}
@(objc_type=Function, objc_name="functionType")
Function_functionType :: proc(self: ^Function) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=Function, objc_name="label")
Function_label :: proc(self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Function, objc_name="name")
Function_name :: proc(self: ^Function) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}
@(objc_type=Function, objc_name="newArgumentEncoderWithBufferIndex")
Function_newArgumentEncoderWithBufferIndex :: proc(self: ^Function, bufferIndex: ^NS.Object) -> ^Function {
	return msgSend(^Function, self, "newArgumentEncoderWithBufferIndex:", bufferIndex)
}
@(objc_type=Function, objc_name="newArgumentEncoderWithBufferIndex_reflection_")
Function_newArgumentEncoderWithBufferIndex_reflection_ :: proc(self: ^Function, bufferIndex: ^NS.Object, reflection: ^AutoreleasedArgument) -> ^Function {
	return msgSend(^Function, self, "newArgumentEncoderWithBufferIndex:reflection:", bufferIndex, reflection)
}
@(objc_type=Function, objc_name="options")
Function_options :: proc(self: ^Function) -> FunctionOptions {
	return msgSend(FunctionOptions, self, "options")
}
@(objc_type=Function, objc_name="patchControlPointCount")
Function_patchControlPointCount :: proc(self: ^Function) -> NS.Integer {
	return msgSend(NS.Integer, self, "patchControlPointCount")
}
@(objc_type=Function, objc_name="patchType")
Function_patchType :: proc(self: ^Function) -> PatchType {
	return msgSend(PatchType, self, "patchType")
}
@(objc_type=Function, objc_name="setLabel")
Function_setLabel :: proc(self: ^Function, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Function, objc_name="stageInputAttributes")
Function_stageInputAttributes :: proc(self: ^Function) -> ^NS.Array {
	return msgSend(^NS.Array, self, "stageInputAttributes")
}
@(objc_type=Function, objc_name="vertexAttributes")
Function_vertexAttributes :: proc(self: ^Function) -> ^NS.Array {
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
FunctionHandle_device :: proc(self: ^FunctionHandle) -> ^FunctionHandle {
	return msgSend(^FunctionHandle, self, "device")
}
@(objc_type=FunctionHandle, objc_name="functionType")
FunctionHandle_functionType :: proc(self: ^FunctionHandle) -> FunctionType {
	return msgSend(FunctionType, self, "functionType")
}
@(objc_type=FunctionHandle, objc_name="name")
FunctionHandle_name :: proc(self: ^FunctionHandle) -> ^NS.String {
	return msgSend(^NS.String, self, "name")
}

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
FunctionLog_debugLocation :: proc(self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "debugLocation")
}
@(objc_type=FunctionLog, objc_name="encoderLabel")
FunctionLog_encoderLabel :: proc(self: ^FunctionLog) -> ^NS.String {
	return msgSend(^NS.String, self, "encoderLabel")
}
@(objc_type=FunctionLog, objc_name="function")
FunctionLog_function :: proc(self: ^FunctionLog) -> ^FunctionLog {
	return msgSend(^FunctionLog, self, "function")
}
@(objc_type=FunctionLog, objc_name="type")
FunctionLog_type :: proc(self: ^FunctionLog) -> FunctionLogType {
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
FunctionLogDebugLocation_URL :: proc(self: ^FunctionLogDebugLocation) -> ^NS.URL {
	return msgSend(^NS.URL, self, "URL")
}
@(objc_type=FunctionLogDebugLocation, objc_name="column")
FunctionLogDebugLocation_column :: proc(self: ^FunctionLogDebugLocation) -> NS.Integer {
	return msgSend(NS.Integer, self, "column")
}
@(objc_type=FunctionLogDebugLocation, objc_name="functionName")
FunctionLogDebugLocation_functionName :: proc(self: ^FunctionLogDebugLocation) -> ^NS.String {
	return msgSend(^NS.String, self, "functionName")
}
@(objc_type=FunctionLogDebugLocation, objc_name="line")
FunctionLogDebugLocation_line :: proc(self: ^FunctionLogDebugLocation) -> NS.Integer {
	return msgSend(NS.Integer, self, "line")
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
Heap_cpuCacheMode :: proc(self: ^Heap) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Heap, objc_name="currentAllocatedSize")
Heap_currentAllocatedSize :: proc(self: ^Heap) -> NS.Integer {
	return msgSend(NS.Integer, self, "currentAllocatedSize")
}
@(objc_type=Heap, objc_name="device")
Heap_device :: proc(self: ^Heap) -> ^Heap {
	return msgSend(^Heap, self, "device")
}
@(objc_type=Heap, objc_name="hazardTrackingMode")
Heap_hazardTrackingMode :: proc(self: ^Heap) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Heap, objc_name="label")
Heap_label :: proc(self: ^Heap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Heap, objc_name="maxAvailableSizeWithAlignment")
Heap_maxAvailableSizeWithAlignment :: proc(self: ^Heap, alignment: ^NS.Object) -> ^Heap {
	return msgSend(^Heap, self, "maxAvailableSizeWithAlignment:", alignment)
}
@(objc_type=Heap, objc_name="newBufferWithLength")
Heap_newBufferWithLength :: proc(self: ^Heap, length: ^NS.Object, options: ResourceOptions) -> ^Heap {
	return msgSend(^Heap, self, "newBufferWithLength:options:", length, options)
}
@(objc_type=Heap, objc_name="newBufferWithLength_options_offset_")
Heap_newBufferWithLength_options_offset_ :: proc(self: ^Heap, length: ^NS.Object, options: ResourceOptions, offset: ^NS.Object) -> ^Heap {
	return msgSend(^Heap, self, "newBufferWithLength:options:offset:", length, options, offset)
}
@(objc_type=Heap, objc_name="newTextureWithDescriptor")
Heap_newTextureWithDescriptor :: proc(self: ^Heap, desc: ^TextureDescriptor) -> ^Heap {
	return msgSend(^Heap, self, "newTextureWithDescriptor:", desc)
}
@(objc_type=Heap, objc_name="newTextureWithDescriptor_offset_")
Heap_newTextureWithDescriptor_offset_ :: proc(self: ^Heap, descriptor: ^TextureDescriptor, offset: ^NS.Object) -> ^Heap {
	return msgSend(^Heap, self, "newTextureWithDescriptor:offset:", descriptor, offset)
}
@(objc_type=Heap, objc_name="resourceOptions")
Heap_resourceOptions :: proc(self: ^Heap) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Heap, objc_name="setLabel")
Heap_setLabel :: proc(self: ^Heap, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Heap, objc_name="setPurgeableState")
Heap_setPurgeableState :: proc(self: ^Heap, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Heap, objc_name="size")
Heap_size :: proc(self: ^Heap) -> NS.Integer {
	return msgSend(NS.Integer, self, "size")
}
@(objc_type=Heap, objc_name="storageMode")
Heap_storageMode :: proc(self: ^Heap) -> StorageMode {
	return msgSend(StorageMode, self, "storageMode")
}
@(objc_type=Heap, objc_name="type")
Heap_type :: proc(self: ^Heap) -> FunctionLogType {
	return msgSend(FunctionLogType, self, "type")
}
@(objc_type=Heap, objc_name="usedSize")
Heap_usedSize :: proc(self: ^Heap) -> NS.Integer {
	return msgSend(NS.Integer, self, "usedSize")
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
IndirectCommandBuffer :: struct { using _: NS.Object }

@(objc_type=IndirectCommandBuffer, objc_name="indirectComputeCommandAtIndex")
IndirectCommandBuffer_indirectComputeCommandAtIndex :: proc(self: ^IndirectCommandBuffer, commandIndex: ^NS.Object) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "indirectComputeCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="indirectRenderCommandAtIndex")
IndirectCommandBuffer_indirectRenderCommandAtIndex :: proc(self: ^IndirectCommandBuffer, commandIndex: ^NS.Object) -> ^IndirectCommandBuffer {
	return msgSend(^IndirectCommandBuffer, self, "indirectRenderCommandAtIndex:", commandIndex)
}
@(objc_type=IndirectCommandBuffer, objc_name="resetWithRange")
IndirectCommandBuffer_resetWithRange :: proc(self: ^IndirectCommandBuffer, range: NS.Range) {
	msgSend(nil, self, "resetWithRange:", range)
}
@(objc_type=IndirectCommandBuffer, objc_name="size")
IndirectCommandBuffer_size :: proc(self: ^IndirectCommandBuffer) -> NS.Integer {
	return msgSend(NS.Integer, self, "size")
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
IndirectComputeCommand_clearBarrier :: proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "clearBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreadgroups")
IndirectComputeCommand_concurrentDispatchThreadgroups :: proc(self: ^IndirectComputeCommand, threadgroupsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreadgroups:threadsPerThreadgroup:", threadgroupsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="concurrentDispatchThreads")
IndirectComputeCommand_concurrentDispatchThreads :: proc(self: ^IndirectComputeCommand, threadsPerGrid: Size, threadsPerThreadgroup: Size) {
	msgSend(nil, self, "concurrentDispatchThreads:threadsPerThreadgroup:", threadsPerGrid, threadsPerThreadgroup)
}
@(objc_type=IndirectComputeCommand, objc_name="reset")
IndirectComputeCommand_reset :: proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectComputeCommand, objc_name="setBarrier")
IndirectComputeCommand_setBarrier :: proc(self: ^IndirectComputeCommand) {
	msgSend(nil, self, "setBarrier")
}
@(objc_type=IndirectComputeCommand, objc_name="setComputePipelineState")
IndirectComputeCommand_setComputePipelineState :: proc(self: ^IndirectComputeCommand, pipelineState: ^NS.Object) {
	msgSend(nil, self, "setComputePipelineState:", pipelineState)
}
@(objc_type=IndirectComputeCommand, objc_name="setImageblockWidth")
IndirectComputeCommand_setImageblockWidth :: proc(self: ^IndirectComputeCommand, width: ^NS.Object, height: ^NS.Object) {
	msgSend(nil, self, "setImageblockWidth:height:", width, height)
}
@(objc_type=IndirectComputeCommand, objc_name="setKernelBuffer")
IndirectComputeCommand_setKernelBuffer :: proc(self: ^IndirectComputeCommand, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setKernelBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectComputeCommand, objc_name="setStageInRegion")
IndirectComputeCommand_setStageInRegion :: proc(self: ^IndirectComputeCommand, region: Region) {
	msgSend(nil, self, "setStageInRegion:", region)
}
@(objc_type=IndirectComputeCommand, objc_name="setThreadgroupMemoryLength")
IndirectComputeCommand_setThreadgroupMemoryLength :: proc(self: ^IndirectComputeCommand, length: ^NS.Object, index: ^NS.Object) {
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
IndirectRenderCommand_drawIndexedPatches :: proc(self: ^IndirectRenderCommand, numberOfPatchControlPoints: ^NS.Object, patchStart: ^NS.Object, patchCount: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, controlPointIndexBuffer: ^NS.Object, controlPointIndexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object, buffer: ^NS.Object, offset: ^NS.Object, instanceStride: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawIndexedPrimitives")
IndirectRenderCommand_drawIndexedPrimitives :: proc(self: ^IndirectRenderCommand, primitiveType: PrimitiveType, indexCount: ^NS.Object, indexType: IndexType, indexBuffer: ^NS.Object, indexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseVertex: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPatches")
IndirectRenderCommand_drawPatches :: proc(self: ^IndirectRenderCommand, numberOfPatchControlPoints: ^NS.Object, patchStart: ^NS.Object, patchCount: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object, buffer: ^NS.Object, offset: ^NS.Object, instanceStride: ^NS.Object) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:tessellationFactorBuffer:tessellationFactorBufferOffset:tessellationFactorBufferInstanceStride:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance, buffer, offset, instanceStride)
}
@(objc_type=IndirectRenderCommand, objc_name="drawPrimitives")
IndirectRenderCommand_drawPrimitives :: proc(self: ^IndirectRenderCommand, primitiveType: PrimitiveType, vertexStart: ^NS.Object, vertexCount: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=IndirectRenderCommand, objc_name="reset")
IndirectRenderCommand_reset :: proc(self: ^IndirectRenderCommand) {
	msgSend(nil, self, "reset")
}
@(objc_type=IndirectRenderCommand, objc_name="setFragmentBuffer")
IndirectRenderCommand_setFragmentBuffer :: proc(self: ^IndirectRenderCommand, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IndirectRenderCommand, objc_name="setRenderPipelineState")
IndirectRenderCommand_setRenderPipelineState :: proc(self: ^IndirectRenderCommand, pipelineState: ^NS.Object) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=IndirectRenderCommand, objc_name="setVertexBuffer")
IndirectRenderCommand_setVertexBuffer :: proc(self: ^IndirectRenderCommand, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
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
IntersectionFunctionTable :: struct { using _: NS.Object }

@(objc_type=IntersectionFunctionTable, objc_name="setBuffer")
IntersectionFunctionTable_setBuffer :: proc(self: ^IntersectionFunctionTable, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setBuffers")
IntersectionFunctionTable_setBuffers :: proc(self: ^IntersectionFunctionTable, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunction")
IntersectionFunctionTable_setFunction :: proc(self: ^IntersectionFunctionTable, function: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setFunctions")
IntersectionFunctionTable_setFunctions :: proc(self: ^IntersectionFunctionTable, functions: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", functions, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignature_atIndex_")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignature_atIndex_ :: proc(self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, index: ^NS.Object) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:atIndex:", signature, index)
}
@(objc_type=IntersectionFunctionTable, objc_name="setOpaqueTriangleIntersectionFunctionWithSignature_withRange_")
IntersectionFunctionTable_setOpaqueTriangleIntersectionFunctionWithSignature_withRange_ :: proc(self: ^IntersectionFunctionTable, signature: IntersectionFunctionSignature, range: NS.Range) {
	msgSend(nil, self, "setOpaqueTriangleIntersectionFunctionWithSignature:withRange:", signature, range)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTable")
IntersectionFunctionTable_setVisibleFunctionTable :: proc(self: ^IntersectionFunctionTable, visibleFunctionTable: ^NS.Object, bufferIndex: ^NS.Object) {
	msgSend(nil, self, "setVisibleFunctionTable:atBufferIndex:", visibleFunctionTable, bufferIndex)
}
@(objc_type=IntersectionFunctionTable, objc_name="setVisibleFunctionTables")
IntersectionFunctionTable_setVisibleFunctionTables :: proc(self: ^IntersectionFunctionTable, visibleFunctionTables: ^^NS.Object, range: NS.Range) {
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
Library_device :: proc(self: ^Library) -> ^Library {
	return msgSend(^Library, self, "device")
}
@(objc_type=Library, objc_name="functionNames")
Library_functionNames :: proc(self: ^Library) -> ^NS.Array {
	return msgSend(^NS.Array, self, "functionNames")
}
@(objc_type=Library, objc_name="installName")
Library_installName :: proc(self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "installName")
}
@(objc_type=Library, objc_name="label")
Library_label :: proc(self: ^Library) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Library, objc_name="newFunctionWithDescriptor_completionHandler_")
Library_newFunctionWithDescriptor_completionHandler_ :: proc(self: ^Library, descriptor: ^FunctionDescriptor, completionHandler: rawptr) {
	msgSend(nil, self, "newFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithDescriptor_error_")
Library_newFunctionWithDescriptor_error_ :: proc(self: ^Library, descriptor: ^FunctionDescriptor, error: ^^NS.Error ) -> ^Library {
	return msgSend(^Library, self, "newFunctionWithDescriptor:error:", descriptor, error)
}
@(objc_type=Library, objc_name="newFunctionWithName")
Library_newFunctionWithName :: proc(self: ^Library, functionName: ^NS.String) -> ^Library {
	return msgSend(^Library, self, "newFunctionWithName:", functionName)
}
@(objc_type=Library, objc_name="newFunctionWithName_constantValues_completionHandler_")
Library_newFunctionWithName_constantValues_completionHandler_ :: proc(self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues, completionHandler: rawptr) {
	msgSend(nil, self, "newFunctionWithName:constantValues:completionHandler:", name, constantValues, completionHandler)
}
@(objc_type=Library, objc_name="newFunctionWithName_constantValues_error_")
Library_newFunctionWithName_constantValues_error_ :: proc(self: ^Library, name: ^NS.String, constantValues: ^FunctionConstantValues, error: ^^NS.Error ) -> ^Library {
	return msgSend(^Library, self, "newFunctionWithName:constantValues:error:", name, constantValues, error)
}
@(objc_type=Library, objc_name="newIntersectionFunctionWithDescriptor_completionHandler_")
Library_newIntersectionFunctionWithDescriptor_completionHandler_ :: proc(self: ^Library, descriptor: ^IntersectionFunctionDescriptor, completionHandler: rawptr) {
	msgSend(nil, self, "newIntersectionFunctionWithDescriptor:completionHandler:", descriptor, completionHandler)
}
@(objc_type=Library, objc_name="newIntersectionFunctionWithDescriptor_error_")
Library_newIntersectionFunctionWithDescriptor_error_ :: proc(self: ^Library, descriptor: ^IntersectionFunctionDescriptor, error: ^^NS.Error ) -> ^Library {
	return msgSend(^Library, self, "newIntersectionFunctionWithDescriptor:error:", descriptor, error)
}
@(objc_type=Library, objc_name="setLabel")
Library_setLabel :: proc(self: ^Library, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Library, objc_name="type")
Library_type :: proc(self: ^Library) -> LibraryType {
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
ParallelRenderCommandEncoder :: struct { using _: NS.Object }

@(objc_type=ParallelRenderCommandEncoder, objc_name="renderCommandEncoder")
ParallelRenderCommandEncoder_renderCommandEncoder :: proc(self: ^ParallelRenderCommandEncoder) -> ^ParallelRenderCommandEncoder {
	return msgSend(^ParallelRenderCommandEncoder, self, "renderCommandEncoder")
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreAction")
ParallelRenderCommandEncoder_setColorStoreAction :: proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: ^NS.Object) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setColorStoreActionOptions")
ParallelRenderCommandEncoder_setColorStoreActionOptions :: proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: ^NS.Object) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreAction")
ParallelRenderCommandEncoder_setDepthStoreAction :: proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setDepthStoreActionOptions")
ParallelRenderCommandEncoder_setDepthStoreActionOptions :: proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreAction")
ParallelRenderCommandEncoder_setStencilStoreAction :: proc(self: ^ParallelRenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=ParallelRenderCommandEncoder, objc_name="setStencilStoreActionOptions")
ParallelRenderCommandEncoder_setStencilStoreActionOptions :: proc(self: ^ParallelRenderCommandEncoder, storeActionOptions: StoreActionOptions) {
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
RasterizationRateMap_copyParameterDataToBuffer :: proc(self: ^RasterizationRateMap, buffer: ^NS.Object, offset: ^NS.Object) {
	msgSend(nil, self, "copyParameterDataToBuffer:offset:", buffer, offset)
}
@(objc_type=RasterizationRateMap, objc_name="device")
RasterizationRateMap_device :: proc(self: ^RasterizationRateMap) -> ^RasterizationRateMap {
	return msgSend(^RasterizationRateMap, self, "device")
}
@(objc_type=RasterizationRateMap, objc_name="label")
RasterizationRateMap_label :: proc(self: ^RasterizationRateMap) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RasterizationRateMap, objc_name="layerCount")
RasterizationRateMap_layerCount :: proc(self: ^RasterizationRateMap) -> NS.Integer {
	return msgSend(NS.Integer, self, "layerCount")
}
@(objc_type=RasterizationRateMap, objc_name="mapPhysicalToScreenCoordinates")
RasterizationRateMap_mapPhysicalToScreenCoordinates :: proc(self: ^RasterizationRateMap, physicalCoordinates: Coordinate2D, layerIndex: ^NS.Object) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapPhysicalToScreenCoordinates:forLayer:", physicalCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="mapScreenToPhysicalCoordinates")
RasterizationRateMap_mapScreenToPhysicalCoordinates :: proc(self: ^RasterizationRateMap, screenCoordinates: Coordinate2D, layerIndex: ^NS.Object) -> Coordinate2D {
	return msgSend(Coordinate2D, self, "mapScreenToPhysicalCoordinates:forLayer:", screenCoordinates, layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="parameterBufferSizeAndAlign")
RasterizationRateMap_parameterBufferSizeAndAlign :: proc(self: ^RasterizationRateMap) -> SizeAndAlign {
	return msgSend(SizeAndAlign, self, "parameterBufferSizeAndAlign")
}
@(objc_type=RasterizationRateMap, objc_name="physicalGranularity")
RasterizationRateMap_physicalGranularity :: proc(self: ^RasterizationRateMap) -> Size {
	return msgSend(Size, self, "physicalGranularity")
}
@(objc_type=RasterizationRateMap, objc_name="physicalSizeForLayer")
RasterizationRateMap_physicalSizeForLayer :: proc(self: ^RasterizationRateMap, layerIndex: ^NS.Object) -> Size {
	return msgSend(Size, self, "physicalSizeForLayer:", layerIndex)
}
@(objc_type=RasterizationRateMap, objc_name="screenSize")
RasterizationRateMap_screenSize :: proc(self: ^RasterizationRateMap) -> Size {
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
RenderCommandEncoder :: struct { using _: NS.Object }

@(objc_type=RenderCommandEncoder, objc_name="dispatchThreadsPerTile")
RenderCommandEncoder_dispatchThreadsPerTile :: proc(self: ^RenderCommandEncoder, threadsPerTile: Size) {
	msgSend(nil, self, "dispatchThreadsPerTile:", threadsPerTile)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawIndexedPatches_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_indirectBuffer_indirectBufferOffset_ :: proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, controlPointIndexBuffer: ^NS.Object, controlPointIndexBufferOffset: ^NS.Object, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPatches:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_")
RenderCommandEncoder_drawIndexedPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_controlPointIndexBuffer_controlPointIndexBufferOffset_instanceCount_baseInstance_ :: proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: ^NS.Object, patchStart: ^NS.Object, patchCount: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, controlPointIndexBuffer: ^NS.Object, controlPointIndexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:controlPointIndexBuffer:controlPointIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: ^NS.Object, indexType: IndexType, indexBuffer: ^NS.Object, indexBufferOffset: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: ^NS.Object, indexType: IndexType, indexBuffer: ^NS.Object, indexBufferOffset: ^NS.Object, instanceCount: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_")
RenderCommandEncoder_drawIndexedPrimitives_indexCount_indexType_indexBuffer_indexBufferOffset_instanceCount_baseVertex_baseInstance_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexCount: ^NS.Object, indexType: IndexType, indexBuffer: ^NS.Object, indexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseVertex: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:", primitiveType, indexCount, indexType, indexBuffer, indexBufferOffset, instanceCount, baseVertex, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawIndexedPrimitives_indexType_indexBuffer_indexBufferOffset_indirectBuffer_indirectBufferOffset_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indexType: IndexType, indexBuffer: ^NS.Object, indexBufferOffset: ^NS.Object, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "drawIndexedPrimitives:indexType:indexBuffer:indexBufferOffset:indirectBuffer:indirectBufferOffset:", primitiveType, indexType, indexBuffer, indexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawPatches_patchIndexBuffer_patchIndexBufferOffset_indirectBuffer_indirectBufferOffset_ :: proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "drawPatches:patchIndexBuffer:patchIndexBufferOffset:indirectBuffer:indirectBufferOffset:", numberOfPatchControlPoints, patchIndexBuffer, patchIndexBufferOffset, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_")
RenderCommandEncoder_drawPatches_patchStart_patchCount_patchIndexBuffer_patchIndexBufferOffset_instanceCount_baseInstance_ :: proc(self: ^RenderCommandEncoder, numberOfPatchControlPoints: ^NS.Object, patchStart: ^NS.Object, patchCount: ^NS.Object, patchIndexBuffer: ^NS.Object, patchIndexBufferOffset: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawPatches:patchStart:patchCount:patchIndexBuffer:patchIndexBufferOffset:instanceCount:baseInstance:", numberOfPatchControlPoints, patchStart, patchCount, patchIndexBuffer, patchIndexBufferOffset, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_drawPrimitives_indirectBuffer_indirectBufferOffset_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "drawPrimitives:indirectBuffer:indirectBufferOffset:", primitiveType, indirectBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: ^NS.Object, vertexCount: ^NS.Object) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:", primitiveType, vertexStart, vertexCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_instanceCount_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_instanceCount_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: ^NS.Object, vertexCount: ^NS.Object, instanceCount: ^NS.Object) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:", primitiveType, vertexStart, vertexCount, instanceCount)
}
@(objc_type=RenderCommandEncoder, objc_name="drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_")
RenderCommandEncoder_drawPrimitives_vertexStart_vertexCount_instanceCount_baseInstance_ :: proc(self: ^RenderCommandEncoder, primitiveType: PrimitiveType, vertexStart: ^NS.Object, vertexCount: ^NS.Object, instanceCount: ^NS.Object, baseInstance: ^NS.Object) {
	msgSend(nil, self, "drawPrimitives:vertexStart:vertexCount:instanceCount:baseInstance:", primitiveType, vertexStart, vertexCount, instanceCount, baseInstance)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_")
RenderCommandEncoder_executeCommandsInBuffer_indirectBuffer_indirectBufferOffset_ :: proc(self: ^RenderCommandEncoder, indirectCommandbuffer: ^NS.Object, indirectRangeBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "executeCommandsInBuffer:indirectBuffer:indirectBufferOffset:", indirectCommandbuffer, indirectRangeBuffer, indirectBufferOffset)
}
@(objc_type=RenderCommandEncoder, objc_name="executeCommandsInBuffer_withRange_")
RenderCommandEncoder_executeCommandsInBuffer_withRange_ :: proc(self: ^RenderCommandEncoder, indirectCommandBuffer: ^NS.Object, executionRange: NS.Range) {
	msgSend(nil, self, "executeCommandsInBuffer:withRange:", indirectCommandBuffer, executionRange)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithResources")
RenderCommandEncoder_memoryBarrierWithResources :: proc(self: ^RenderCommandEncoder, resources: ^^NS.Object, count: ^NS.Object, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithResources:count:afterStages:beforeStages:", resources, count, after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="memoryBarrierWithScope")
RenderCommandEncoder_memoryBarrierWithScope :: proc(self: ^RenderCommandEncoder, scope: BarrierScope, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithScope:afterStages:beforeStages:", scope, after, before)
}
@(objc_type=RenderCommandEncoder, objc_name="sampleCountersInBuffer")
RenderCommandEncoder_sampleCountersInBuffer :: proc(self: ^RenderCommandEncoder, sampleBuffer: ^NS.Object, sampleIndex: ^NS.Object, barrier: BOOL) {
	msgSend(nil, self, "sampleCountersInBuffer:atSampleIndex:withBarrier:", sampleBuffer, sampleIndex, barrier)
}
@(objc_type=RenderCommandEncoder, objc_name="setBlendColorRed")
RenderCommandEncoder_setBlendColorRed :: proc(self: ^RenderCommandEncoder, red: f32, green: f32, blue: f32, alpha: f32) {
	msgSend(nil, self, "setBlendColorRed:green:blue:alpha:", red, green, blue, alpha)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreAction")
RenderCommandEncoder_setColorStoreAction :: proc(self: ^RenderCommandEncoder, storeAction: StoreAction, colorAttachmentIndex: ^NS.Object) {
	msgSend(nil, self, "setColorStoreAction:atIndex:", storeAction, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setColorStoreActionOptions")
RenderCommandEncoder_setColorStoreActionOptions :: proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions, colorAttachmentIndex: ^NS.Object) {
	msgSend(nil, self, "setColorStoreActionOptions:atIndex:", storeActionOptions, colorAttachmentIndex)
}
@(objc_type=RenderCommandEncoder, objc_name="setCullMode")
RenderCommandEncoder_setCullMode :: proc(self: ^RenderCommandEncoder, cullMode: CullMode) {
	msgSend(nil, self, "setCullMode:", cullMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthBias")
RenderCommandEncoder_setDepthBias :: proc(self: ^RenderCommandEncoder, depthBias: f32, slopeScale: f32, clamp: f32) {
	msgSend(nil, self, "setDepthBias:slopeScale:clamp:", depthBias, slopeScale, clamp)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthClipMode")
RenderCommandEncoder_setDepthClipMode :: proc(self: ^RenderCommandEncoder, depthClipMode: DepthClipMode) {
	msgSend(nil, self, "setDepthClipMode:", depthClipMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStencilState")
RenderCommandEncoder_setDepthStencilState :: proc(self: ^RenderCommandEncoder, depthStencilState: ^NS.Object) {
	msgSend(nil, self, "setDepthStencilState:", depthStencilState)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreAction")
RenderCommandEncoder_setDepthStoreAction :: proc(self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setDepthStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setDepthStoreActionOptions")
RenderCommandEncoder_setDepthStoreActionOptions :: proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setDepthStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffer")
RenderCommandEncoder_setFragmentBuffer :: proc(self: ^RenderCommandEncoder, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBufferOffset")
RenderCommandEncoder_setFragmentBufferOffset :: proc(self: ^RenderCommandEncoder, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBuffers")
RenderCommandEncoder_setFragmentBuffers :: proc(self: ^RenderCommandEncoder, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setFragmentBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentBytes")
RenderCommandEncoder_setFragmentBytes :: proc(self: ^RenderCommandEncoder, bytes: rawptr, length: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerState_atIndex_")
RenderCommandEncoder_setFragmentSamplerState_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerState_lodMinClamp_lodMaxClamp_atIndex_")
RenderCommandEncoder_setFragmentSamplerState_lodMinClamp_lodMaxClamp_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, lodMinClamp: f32, lodMaxClamp: f32, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStates_lodMinClamps_lodMaxClamps_withRange_")
RenderCommandEncoder_setFragmentSamplerStates_lodMinClamps_lodMaxClamps_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStates_withRange_")
RenderCommandEncoder_setFragmentSamplerStates_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTexture")
RenderCommandEncoder_setFragmentTexture :: proc(self: ^RenderCommandEncoder, texture: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFragmentTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setFragmentTextures")
RenderCommandEncoder_setFragmentTextures :: proc(self: ^RenderCommandEncoder, textures: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setFragmentTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setFrontFacingWinding")
RenderCommandEncoder_setFrontFacingWinding :: proc(self: ^RenderCommandEncoder, frontFacingWinding: Winding) {
	msgSend(nil, self, "setFrontFacingWinding:", frontFacingWinding)
}
@(objc_type=RenderCommandEncoder, objc_name="setRenderPipelineState")
RenderCommandEncoder_setRenderPipelineState :: proc(self: ^RenderCommandEncoder, pipelineState: ^NS.Object) {
	msgSend(nil, self, "setRenderPipelineState:", pipelineState)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRect")
RenderCommandEncoder_setScissorRect :: proc(self: ^RenderCommandEncoder, rect: ScissorRect) {
	msgSend(nil, self, "setScissorRect:", rect)
}
@(objc_type=RenderCommandEncoder, objc_name="setScissorRects")
RenderCommandEncoder_setScissorRects :: proc(self: ^RenderCommandEncoder, scissorRects: ^ScissorRect, count: ^NS.Object) {
	msgSend(nil, self, "setScissorRects:count:", scissorRects, count)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilFrontReferenceValue")
RenderCommandEncoder_setStencilFrontReferenceValue :: proc(self: ^RenderCommandEncoder, frontReferenceValue: u32, backReferenceValue: u32) {
	msgSend(nil, self, "setStencilFrontReferenceValue:backReferenceValue:", frontReferenceValue, backReferenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilReferenceValue")
RenderCommandEncoder_setStencilReferenceValue :: proc(self: ^RenderCommandEncoder, referenceValue: u32) {
	msgSend(nil, self, "setStencilReferenceValue:", referenceValue)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreAction")
RenderCommandEncoder_setStencilStoreAction :: proc(self: ^RenderCommandEncoder, storeAction: StoreAction) {
	msgSend(nil, self, "setStencilStoreAction:", storeAction)
}
@(objc_type=RenderCommandEncoder, objc_name="setStencilStoreActionOptions")
RenderCommandEncoder_setStencilStoreActionOptions :: proc(self: ^RenderCommandEncoder, storeActionOptions: StoreActionOptions) {
	msgSend(nil, self, "setStencilStoreActionOptions:", storeActionOptions)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorBuffer")
RenderCommandEncoder_setTessellationFactorBuffer :: proc(self: ^RenderCommandEncoder, buffer: ^NS.Object, offset: ^NS.Object, instanceStride: ^NS.Object) {
	msgSend(nil, self, "setTessellationFactorBuffer:offset:instanceStride:", buffer, offset, instanceStride)
}
@(objc_type=RenderCommandEncoder, objc_name="setTessellationFactorScale")
RenderCommandEncoder_setTessellationFactorScale :: proc(self: ^RenderCommandEncoder, scale: f32) {
	msgSend(nil, self, "setTessellationFactorScale:", scale)
}
@(objc_type=RenderCommandEncoder, objc_name="setThreadgroupMemoryLength")
RenderCommandEncoder_setThreadgroupMemoryLength :: proc(self: ^RenderCommandEncoder, length: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setThreadgroupMemoryLength:offset:atIndex:", length, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffer")
RenderCommandEncoder_setTileBuffer :: proc(self: ^RenderCommandEncoder, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTileBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBufferOffset")
RenderCommandEncoder_setTileBufferOffset :: proc(self: ^RenderCommandEncoder, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTileBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBuffers")
RenderCommandEncoder_setTileBuffers :: proc(self: ^RenderCommandEncoder, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setTileBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileBytes")
RenderCommandEncoder_setTileBytes :: proc(self: ^RenderCommandEncoder, bytes: rawptr, length: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTileBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerState_atIndex_")
RenderCommandEncoder_setTileSamplerState_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTileSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerState_lodMinClamp_lodMaxClamp_atIndex_")
RenderCommandEncoder_setTileSamplerState_lodMinClamp_lodMaxClamp_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, lodMinClamp: f32, lodMaxClamp: f32, index: ^NS.Object) {
	msgSend(nil, self, "setTileSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStates_lodMinClamps_lodMaxClamps_withRange_")
RenderCommandEncoder_setTileSamplerStates_lodMinClamps_lodMaxClamps_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStates_withRange_")
RenderCommandEncoder_setTileSamplerStates_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTexture")
RenderCommandEncoder_setTileTexture :: proc(self: ^RenderCommandEncoder, texture: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setTileTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setTileTextures")
RenderCommandEncoder_setTileTextures :: proc(self: ^RenderCommandEncoder, textures: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setTileTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setTriangleFillMode")
RenderCommandEncoder_setTriangleFillMode :: proc(self: ^RenderCommandEncoder, fillMode: TriangleFillMode) {
	msgSend(nil, self, "setTriangleFillMode:", fillMode)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexAmplificationCount")
RenderCommandEncoder_setVertexAmplificationCount :: proc(self: ^RenderCommandEncoder, count: ^NS.Object, viewMappings: ^VertexAmplificationViewMapping) {
	msgSend(nil, self, "setVertexAmplificationCount:viewMappings:", count, viewMappings)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffer")
RenderCommandEncoder_setVertexBuffer :: proc(self: ^RenderCommandEncoder, buffer: ^NS.Object, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVertexBuffer:offset:atIndex:", buffer, offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBufferOffset")
RenderCommandEncoder_setVertexBufferOffset :: proc(self: ^RenderCommandEncoder, offset: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVertexBufferOffset:atIndex:", offset, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBuffers")
RenderCommandEncoder_setVertexBuffers :: proc(self: ^RenderCommandEncoder, buffers: ^^NS.Object, offsets: NS.Integer, range: NS.Range) {
	msgSend(nil, self, "setVertexBuffers:offsets:withRange:", buffers, offsets, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexBytes")
RenderCommandEncoder_setVertexBytes :: proc(self: ^RenderCommandEncoder, bytes: rawptr, length: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVertexBytes:length:atIndex:", bytes, length, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerState_atIndex_")
RenderCommandEncoder_setVertexSamplerState_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVertexSamplerState:atIndex:", sampler, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerState_lodMinClamp_lodMaxClamp_atIndex_")
RenderCommandEncoder_setVertexSamplerState_lodMinClamp_lodMaxClamp_atIndex_ :: proc(self: ^RenderCommandEncoder, sampler: ^NS.Object, lodMinClamp: f32, lodMaxClamp: f32, index: ^NS.Object) {
	msgSend(nil, self, "setVertexSamplerState:lodMinClamp:lodMaxClamp:atIndex:", sampler, lodMinClamp, lodMaxClamp, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStates_lodMinClamps_lodMaxClamps_withRange_")
RenderCommandEncoder_setVertexSamplerStates_lodMinClamps_lodMaxClamps_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, lodMinClamps: ^f32, lodMaxClamps: ^f32, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:lodMinClamps:lodMaxClamps:withRange:", samplers, lodMinClamps, lodMaxClamps, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStates_withRange_")
RenderCommandEncoder_setVertexSamplerStates_withRange_ :: proc(self: ^RenderCommandEncoder, samplers: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:withRange:", samplers, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTexture")
RenderCommandEncoder_setVertexTexture :: proc(self: ^RenderCommandEncoder, texture: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setVertexTexture:atIndex:", texture, index)
}
@(objc_type=RenderCommandEncoder, objc_name="setVertexTextures")
RenderCommandEncoder_setVertexTextures :: proc(self: ^RenderCommandEncoder, textures: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setVertexTextures:withRange:", textures, range)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewport")
RenderCommandEncoder_setViewport :: proc(self: ^RenderCommandEncoder, viewport: Viewport) {
	msgSend(nil, self, "setViewport:", viewport)
}
@(objc_type=RenderCommandEncoder, objc_name="setViewports")
RenderCommandEncoder_setViewports :: proc(self: ^RenderCommandEncoder, viewports: ^Viewport, count: ^NS.Object) {
	msgSend(nil, self, "setViewports:count:", viewports, count)
}
@(objc_type=RenderCommandEncoder, objc_name="setVisibilityResultMode")
RenderCommandEncoder_setVisibilityResultMode :: proc(self: ^RenderCommandEncoder, mode: VisibilityResultMode, offset: ^NS.Object) {
	msgSend(nil, self, "setVisibilityResultMode:offset:", mode, offset)
}
@(objc_type=RenderCommandEncoder, objc_name="textureBarrier")
RenderCommandEncoder_textureBarrier :: proc(self: ^RenderCommandEncoder) {
	msgSend(nil, self, "textureBarrier")
}
@(objc_type=RenderCommandEncoder, objc_name="tileHeight")
RenderCommandEncoder_tileHeight :: proc(self: ^RenderCommandEncoder) -> NS.Integer {
	return msgSend(NS.Integer, self, "tileHeight")
}
@(objc_type=RenderCommandEncoder, objc_name="tileWidth")
RenderCommandEncoder_tileWidth :: proc(self: ^RenderCommandEncoder) -> NS.Integer {
	return msgSend(NS.Integer, self, "tileWidth")
}
@(objc_type=RenderCommandEncoder, objc_name="updateFence")
RenderCommandEncoder_updateFence :: proc(self: ^RenderCommandEncoder, fence: ^NS.Object, stages: RenderStages) {
	msgSend(nil, self, "updateFence:afterStages:", fence, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeap")
RenderCommandEncoder_useHeap :: proc(self: ^RenderCommandEncoder, heap: ^NS.Object) {
	msgSend(nil, self, "useHeap:", heap)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeap_stages_")
RenderCommandEncoder_useHeap_stages_ :: proc(self: ^RenderCommandEncoder, heap: ^NS.Object, stages: RenderStages) {
	msgSend(nil, self, "useHeap:stages:", heap, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeaps")
RenderCommandEncoder_useHeaps :: proc(self: ^RenderCommandEncoder, heaps: ^^NS.Object, count: ^NS.Object) {
	msgSend(nil, self, "useHeaps:count:", heaps, count)
}
@(objc_type=RenderCommandEncoder, objc_name="useHeaps_count_stages_")
RenderCommandEncoder_useHeaps_count_stages_ :: proc(self: ^RenderCommandEncoder, heaps: ^^NS.Object, count: ^NS.Object, stages: RenderStages) {
	msgSend(nil, self, "useHeaps:count:stages:", heaps, count, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResource")
RenderCommandEncoder_useResource :: proc(self: ^RenderCommandEncoder, resource: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResource:usage:", resource, usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResource_usage_stages_")
RenderCommandEncoder_useResource_usage_stages_ :: proc(self: ^RenderCommandEncoder, resource: ^NS.Object, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResource:usage:stages:", resource, usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="useResources")
RenderCommandEncoder_useResources :: proc(self: ^RenderCommandEncoder, resources: ^^NS.Object, count: ^NS.Object, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", resources, count, usage)
}
@(objc_type=RenderCommandEncoder, objc_name="useResources_count_usage_stages_")
RenderCommandEncoder_useResources_count_usage_stages_ :: proc(self: ^RenderCommandEncoder, resources: ^^NS.Object, count: ^NS.Object, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResources:count:usage:stages:", resources, count, usage, stages)
}
@(objc_type=RenderCommandEncoder, objc_name="waitForFence")
RenderCommandEncoder_waitForFence :: proc(self: ^RenderCommandEncoder, fence: ^NS.Object, stages: RenderStages) {
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
RenderPipelineState_device :: proc(self: ^RenderPipelineState) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "device")
}
@(objc_type=RenderPipelineState, objc_name="imageblockMemoryLengthForDimensions")
RenderPipelineState_imageblockMemoryLengthForDimensions :: proc(self: ^RenderPipelineState, imageblockDimensions: Size) -> ^RenderPipelineState {
	return msgSend(^RenderPipelineState, self, "imageblockMemoryLengthForDimensions:", imageblockDimensions)
}
@(objc_type=RenderPipelineState, objc_name="imageblockSampleLength")
RenderPipelineState_imageblockSampleLength :: proc(self: ^RenderPipelineState) -> NS.Integer {
	return msgSend(NS.Integer, self, "imageblockSampleLength")
}
@(objc_type=RenderPipelineState, objc_name="label")
RenderPipelineState_label :: proc(self: ^RenderPipelineState) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=RenderPipelineState, objc_name="maxTotalThreadsPerThreadgroup")
RenderPipelineState_maxTotalThreadsPerThreadgroup :: proc(self: ^RenderPipelineState) -> NS.Integer {
	return msgSend(NS.Integer, self, "maxTotalThreadsPerThreadgroup")
}
@(objc_type=RenderPipelineState, objc_name="supportIndirectCommandBuffers")
RenderPipelineState_supportIndirectCommandBuffers :: proc(self: ^RenderPipelineState) -> BOOL {
	return msgSend(BOOL, self, "supportIndirectCommandBuffers")
}
@(objc_type=RenderPipelineState, objc_name="threadgroupSizeMatchesTileSize")
RenderPipelineState_threadgroupSizeMatchesTileSize :: proc(self: ^RenderPipelineState) -> BOOL {
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
Resource_allocatedSize :: proc(self: ^Resource) -> NS.Integer {
	return msgSend(NS.Integer, self, "allocatedSize")
}
@(objc_type=Resource, objc_name="cpuCacheMode")
Resource_cpuCacheMode :: proc(self: ^Resource) -> CPUCacheMode {
	return msgSend(CPUCacheMode, self, "cpuCacheMode")
}
@(objc_type=Resource, objc_name="device")
Resource_device :: proc(self: ^Resource) -> ^Resource {
	return msgSend(^Resource, self, "device")
}
@(objc_type=Resource, objc_name="hazardTrackingMode")
Resource_hazardTrackingMode :: proc(self: ^Resource) -> HazardTrackingMode {
	return msgSend(HazardTrackingMode, self, "hazardTrackingMode")
}
@(objc_type=Resource, objc_name="heap")
Resource_heap :: proc(self: ^Resource) -> ^Resource {
	return msgSend(^Resource, self, "heap")
}
@(objc_type=Resource, objc_name="heapOffset")
Resource_heapOffset :: proc(self: ^Resource) -> NS.Integer {
	return msgSend(NS.Integer, self, "heapOffset")
}
@(objc_type=Resource, objc_name="isAliasable")
Resource_isAliasable :: proc(self: ^Resource) -> BOOL {
	return msgSend(BOOL, self, "isAliasable")
}
@(objc_type=Resource, objc_name="label")
Resource_label :: proc(self: ^Resource) -> ^NS.String {
	return msgSend(^NS.String, self, "label")
}
@(objc_type=Resource, objc_name="makeAliasable")
Resource_makeAliasable :: proc(self: ^Resource) {
	msgSend(nil, self, "makeAliasable")
}
@(objc_type=Resource, objc_name="resourceOptions")
Resource_resourceOptions :: proc(self: ^Resource) -> ResourceOptions {
	return msgSend(ResourceOptions, self, "resourceOptions")
}
@(objc_type=Resource, objc_name="setLabel")
Resource_setLabel :: proc(self: ^Resource, label: ^NS.String) {
	msgSend(nil, self, "setLabel:", label)
}
@(objc_type=Resource, objc_name="setPurgeableState")
Resource_setPurgeableState :: proc(self: ^Resource, state: PurgeableState) -> PurgeableState {
	return msgSend(PurgeableState, self, "setPurgeableState:", state)
}
@(objc_type=Resource, objc_name="storageMode")
Resource_storageMode :: proc(self: ^Resource) -> StorageMode {
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
ResourceStateCommandEncoder :: struct { using _: NS.Object }

@(objc_type=ResourceStateCommandEncoder, objc_name="updateFence")
ResourceStateCommandEncoder_updateFence :: proc(self: ^ResourceStateCommandEncoder, fence: ^NS.Object) {
	msgSend(nil, self, "updateFence:", fence)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMapping_mode_indirectBuffer_indirectBufferOffset_")
ResourceStateCommandEncoder_updateTextureMapping_mode_indirectBuffer_indirectBufferOffset_ :: proc(self: ^ResourceStateCommandEncoder, texture: ^NS.Object, mode: SparseTextureMappingMode, indirectBuffer: ^NS.Object, indirectBufferOffset: ^NS.Object) {
	msgSend(nil, self, "updateTextureMapping:mode:indirectBuffer:indirectBufferOffset:", texture, mode, indirectBuffer, indirectBufferOffset)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMapping_mode_region_mipLevel_slice_")
ResourceStateCommandEncoder_updateTextureMapping_mode_region_mipLevel_slice_ :: proc(self: ^ResourceStateCommandEncoder, texture: ^NS.Object, mode: SparseTextureMappingMode, region: Region, mipLevel: NS.Integer, slice: NS.Integer) {
	msgSend(nil, self, "updateTextureMapping:mode:region:mipLevel:slice:", texture, mode, region, mipLevel, slice)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="updateTextureMappings")
ResourceStateCommandEncoder_updateTextureMappings :: proc(self: ^ResourceStateCommandEncoder, texture: ^NS.Object, mode: SparseTextureMappingMode, regions: ^Region, mipLevels: NS.Integer, slices: NS.Integer, numRegions: ^NS.Object) {
	msgSend(nil, self, "updateTextureMappings:mode:regions:mipLevels:slices:numRegions:", texture, mode, regions, mipLevels, slices, numRegions)
}
@(objc_type=ResourceStateCommandEncoder, objc_name="waitForFence")
ResourceStateCommandEncoder_waitForFence :: proc(self: ^ResourceStateCommandEncoder, fence: ^NS.Object) {
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
SamplerState_device :: proc(self: ^SamplerState) -> ^SamplerState {
	return msgSend(^SamplerState, self, "device")
}
@(objc_type=SamplerState, objc_name="label")
SamplerState_label :: proc(self: ^SamplerState) -> ^NS.String {
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
SharedEvent :: struct { using _: NS.Object }

@(objc_type=SharedEvent, objc_name="newSharedEventHandle")
SharedEvent_newSharedEventHandle :: proc(self: ^SharedEvent) -> ^SharedEventHandle {
	return msgSend(^SharedEventHandle, self, "newSharedEventHandle")
}
@(objc_type=SharedEvent, objc_name="notifyListener")
SharedEvent_notifyListener :: proc(self: ^SharedEvent, listener: ^SharedEventListener, value: u64, block: SharedEventNotificationBlock) {
	msgSend(nil, self, "notifyListener:atValue:block:", listener, value, block)
}
@(objc_type=SharedEvent, objc_name="setSignaledValue")
SharedEvent_setSignaledValue :: proc(self: ^SharedEvent, signaledValue: u64) {
	msgSend(nil, self, "setSignaledValue:", signaledValue)
}
@(objc_type=SharedEvent, objc_name="signaledValue")
SharedEvent_signaledValue :: proc(self: ^SharedEvent) -> u64 {
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
Texture :: struct { using _: NS.Object }

@(objc_type=Texture, objc_name="allowGPUOptimizedContents")
Texture_allowGPUOptimizedContents :: proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "allowGPUOptimizedContents")
}
@(objc_type=Texture, objc_name="arrayLength")
Texture_arrayLength :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "arrayLength")
}
@(objc_type=Texture, objc_name="buffer")
Texture_buffer :: proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "buffer")
}
@(objc_type=Texture, objc_name="bufferBytesPerRow")
Texture_bufferBytesPerRow :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferBytesPerRow")
}
@(objc_type=Texture, objc_name="bufferOffset")
Texture_bufferOffset :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "bufferOffset")
}
@(objc_type=Texture, objc_name="depth")
Texture_depth :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "depth")
}
@(objc_type=Texture, objc_name="firstMipmapInTail")
Texture_firstMipmapInTail :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "firstMipmapInTail")
}
@(objc_type=Texture, objc_name="getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_")
Texture_getBytes_bytesPerRow_bytesPerImage_fromRegion_mipmapLevel_slice_ :: proc(self: ^Texture, pixelBytes: rawptr, bytesPerRow: ^NS.Object, bytesPerImage: ^NS.Object, region: Region, level: ^NS.Object, slice: ^NS.Object) {
	msgSend(nil, self, "getBytes:bytesPerRow:bytesPerImage:fromRegion:mipmapLevel:slice:", pixelBytes, bytesPerRow, bytesPerImage, region, level, slice)
}
@(objc_type=Texture, objc_name="getBytes_bytesPerRow_fromRegion_mipmapLevel_")
Texture_getBytes_bytesPerRow_fromRegion_mipmapLevel_ :: proc(self: ^Texture, pixelBytes: rawptr, bytesPerRow: ^NS.Object, region: Region, level: ^NS.Object) {
	msgSend(nil, self, "getBytes:bytesPerRow:fromRegion:mipmapLevel:", pixelBytes, bytesPerRow, region, level)
}
@(objc_type=Texture, objc_name="height")
Texture_height :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "height")
}
@(objc_type=Texture, objc_name="iosurface")
Texture_iosurface :: proc(self: ^Texture) -> IOSurfaceRef {
	return msgSend(IOSurfaceRef, self, "iosurface")
}
@(objc_type=Texture, objc_name="iosurfacePlane")
Texture_iosurfacePlane :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "iosurfacePlane")
}
@(objc_type=Texture, objc_name="isFramebufferOnly")
Texture_isFramebufferOnly :: proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isFramebufferOnly")
}
@(objc_type=Texture, objc_name="isShareable")
Texture_isShareable :: proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isShareable")
}
@(objc_type=Texture, objc_name="isSparse")
Texture_isSparse :: proc(self: ^Texture) -> BOOL {
	return msgSend(BOOL, self, "isSparse")
}
@(objc_type=Texture, objc_name="mipmapLevelCount")
Texture_mipmapLevelCount :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "mipmapLevelCount")
}
@(objc_type=Texture, objc_name="newRemoteTextureViewForDevice")
Texture_newRemoteTextureViewForDevice :: proc(self: ^Texture, device: ^NS.Object) -> ^Texture {
	return msgSend(^Texture, self, "newRemoteTextureViewForDevice:", device)
}
@(objc_type=Texture, objc_name="newSharedTextureHandle")
Texture_newSharedTextureHandle :: proc(self: ^Texture) -> ^SharedTextureHandle {
	return msgSend(^SharedTextureHandle, self, "newSharedTextureHandle")
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat")
Texture_newTextureViewWithPixelFormat :: proc(self: ^Texture, pixelFormat: PixelFormat) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:", pixelFormat)
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat_textureType_levels_slices_")
Texture_newTextureViewWithPixelFormat_textureType_levels_slices_ :: proc(self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:", pixelFormat, textureType, levelRange, sliceRange)
}
@(objc_type=Texture, objc_name="newTextureViewWithPixelFormat_textureType_levels_slices_swizzle_")
Texture_newTextureViewWithPixelFormat_textureType_levels_slices_swizzle_ :: proc(self: ^Texture, pixelFormat: PixelFormat, textureType: TextureType, levelRange: NS.Range, sliceRange: NS.Range, swizzle: TextureSwizzleChannels) -> ^Texture {
	return msgSend(^Texture, self, "newTextureViewWithPixelFormat:textureType:levels:slices:swizzle:", pixelFormat, textureType, levelRange, sliceRange, swizzle)
}
@(objc_type=Texture, objc_name="parentRelativeLevel")
Texture_parentRelativeLevel :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "parentRelativeLevel")
}
@(objc_type=Texture, objc_name="parentRelativeSlice")
Texture_parentRelativeSlice :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "parentRelativeSlice")
}
@(objc_type=Texture, objc_name="parentTexture")
Texture_parentTexture :: proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "parentTexture")
}
@(objc_type=Texture, objc_name="pixelFormat")
Texture_pixelFormat :: proc(self: ^Texture) -> PixelFormat {
	return msgSend(PixelFormat, self, "pixelFormat")
}
@(objc_type=Texture, objc_name="remoteStorageTexture")
Texture_remoteStorageTexture :: proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "remoteStorageTexture")
}
@(objc_type=Texture, objc_name="replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_")
Texture_replaceRegion_mipmapLevel_slice_withBytes_bytesPerRow_bytesPerImage_ :: proc(self: ^Texture, region: Region, level: ^NS.Object, slice: ^NS.Object, pixelBytes: rawptr, bytesPerRow: ^NS.Object, bytesPerImage: ^NS.Object) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:", region, level, slice, pixelBytes, bytesPerRow, bytesPerImage)
}
@(objc_type=Texture, objc_name="replaceRegion_mipmapLevel_withBytes_bytesPerRow_")
Texture_replaceRegion_mipmapLevel_withBytes_bytesPerRow_ :: proc(self: ^Texture, region: Region, level: ^NS.Object, pixelBytes: rawptr, bytesPerRow: ^NS.Object) {
	msgSend(nil, self, "replaceRegion:mipmapLevel:withBytes:bytesPerRow:", region, level, pixelBytes, bytesPerRow)
}
@(objc_type=Texture, objc_name="rootResource")
Texture_rootResource :: proc(self: ^Texture) -> ^Texture {
	return msgSend(^Texture, self, "rootResource")
}
@(objc_type=Texture, objc_name="sampleCount")
Texture_sampleCount :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "sampleCount")
}
@(objc_type=Texture, objc_name="swizzle")
Texture_swizzle :: proc(self: ^Texture) -> TextureSwizzleChannels {
	return msgSend(TextureSwizzleChannels, self, "swizzle")
}
@(objc_type=Texture, objc_name="tailSizeInBytes")
Texture_tailSizeInBytes :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "tailSizeInBytes")
}
@(objc_type=Texture, objc_name="textureType")
Texture_textureType :: proc(self: ^Texture) -> TextureType {
	return msgSend(TextureType, self, "textureType")
}
@(objc_type=Texture, objc_name="usage")
Texture_usage :: proc(self: ^Texture) -> TextureUsage {
	return msgSend(TextureUsage, self, "usage")
}
@(objc_type=Texture, objc_name="width")
Texture_width :: proc(self: ^Texture) -> NS.Integer {
	return msgSend(NS.Integer, self, "width")
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
VisibleFunctionTable :: struct { using _: NS.Object }

@(objc_type=VisibleFunctionTable, objc_name="setFunction")
VisibleFunctionTable_setFunction :: proc(self: ^VisibleFunctionTable, function: ^NS.Object, index: ^NS.Object) {
	msgSend(nil, self, "setFunction:atIndex:", function, index)
}
@(objc_type=VisibleFunctionTable, objc_name="setFunctions")
VisibleFunctionTable_setFunctions :: proc(self: ^VisibleFunctionTable, functions: ^^NS.Object, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", functions, range)
}
