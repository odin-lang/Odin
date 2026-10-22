#+build darwin
package darwin_Metal

// Hand-written Odin-specific helpers which complement the generated bindings.
//
// Procedures named `<generated proc>_slice` take Odin slices instead of a pointer and a count, and
// are added to the overload group of `<generated proc>` by vendor/darwin/_gen/import_darwinkit.py,
// e.g. `encoder->setViewports(viewports[:])` alongside `encoder->setViewports(&viewport, 1)`.

import "base:intrinsics"
import "core:mem"
import NS "core:sys/darwin/Foundation"

_ :: mem // only used by polymorphic procedures

@(private="file")
msgSend :: intrinsics.objc_send

BufferDeallocator :: ^Objc_Block(proc "c" (pointer: rawptr, length: NS.UInteger))

new :: proc "c" ($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, NS.Object) {
	return msgSend(^T, msgSend(^T, T, "alloc"), "init")
}

@(objc_type=RasterizationRateLayerDescriptor, objc_name="initWithSampleCountWithDimensions")
RasterizationRateLayerDescriptor_initWithSampleCountWithDimensions :: #force_inline proc "c" (self: ^RasterizationRateLayerDescriptor, sampleCount: Size, horizontal: []f32, vertical: []f32) -> ^RasterizationRateLayerDescriptor {
	return msgSend(^RasterizationRateLayerDescriptor, self, "initWithSampleCount:horizontal:vertical:", sampleCount, raw_data(horizontal), raw_data(vertical))
}

@(objc_type=RasterizationRateMapDescriptor, objc_name="rasterizationRateMapDescriptorWithScreenSizeWithLayers", objc_is_class_method=true)
RasterizationRateMapDescriptor_rasterizationRateMapDescriptorWithScreenSizeWithLayers :: #force_inline proc "c" (screenSize: Size, layers: []^RasterizationRateLayerDescriptor) -> ^RasterizationRateMapDescriptor {
	return msgSend(^RasterizationRateMapDescriptor, RasterizationRateMapDescriptor, "rasterizationRateMapDescriptorWithScreenSize:layerCount:layers:", screenSize, NS.UInteger(len(layers)), raw_data(layers))
}

RenderPassDescriptor_getSamplePositions_slice :: #force_inline proc "c" (self: ^RenderPassDescriptor, positions: []SamplePosition) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "getSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}

RenderPassDescriptor_setSamplePositions_slice :: #force_inline proc "c" (self: ^RenderPassDescriptor, positions: []SamplePosition) {
	msgSend(nil, self, "setSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}

AccelerationStructureCommandEncoder_useHeaps_slice :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}

AccelerationStructureCommandEncoder_useResources_slice :: #force_inline proc "c" (self: ^AccelerationStructureCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}

ArgumentEncoder_setBuffers_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

ArgumentEncoder_setComputePipelineStates_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, pipelines: []^ComputePipelineState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setComputePipelineStates:withRange:", raw_data(pipelines), range)
}

ArgumentEncoder_setIndirectCommandBuffers_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, buffers: []^IndirectCommandBuffer, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setIndirectCommandBuffers:withRange:", raw_data(buffers), range)
}

ArgumentEncoder_setIntersectionFunctionTables_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withRange:", raw_data(intersectionFunctionTables), range)
}

ArgumentEncoder_setRenderPipelineStates_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, pipelines: []^RenderPipelineState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(pipelines)))
	msgSend(nil, self, "setRenderPipelineStates:withRange:", raw_data(pipelines), range)
}

ArgumentEncoder_setSamplerStates_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, samplers: []^SamplerState, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(samplers)))
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}

ArgumentEncoder_setTextures_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, textures: []^Texture, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(textures)))
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}

ArgumentEncoder_setVisibleFunctionTables_slice :: #force_inline proc "odin" (self: ^ArgumentEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(visibleFunctionTables)))
	msgSend(nil, self, "setVisibleFunctionTables:withRange:", raw_data(visibleFunctionTables), range)
}

@(objc_type=Buffer, objc_name="contentsAsSlice")
Buffer_contentsAsSlice :: #force_inline proc "c" (self: ^Buffer, $T: typeid/[]$E) -> T {
	contents := msgSend([^]byte, self, "contents")
	length := self->length()
	return mem.slice_data_cast(T, contents[:length])
}

@(objc_type=Buffer, objc_name="contentsAsType")
Buffer_contentsAsType :: #force_inline proc "c" (self: ^Buffer, $T: typeid, offset: uintptr = 0) -> ^T {
	ptr := msgSend(rawptr, self, "contents")
	return (^T)(uintptr(ptr) + offset)
}

ComputeCommandEncoder_memoryBarrierWithResources_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, resources: []^Resource) {
	msgSend(nil, self, "memoryBarrierWithResources:count:", raw_data(resources), NS.UInteger(len(resources)))
}

ComputeCommandEncoder_setBuffers_slice :: #force_inline proc "odin" (self: ^ComputeCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	assert(len(buffers) == len(offsets))
	assert(range.length <= NS.UInteger(len(buffers)))
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

ComputeCommandEncoder_setBytes_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}

ComputeCommandEncoder_setIntersectionFunctionTables_slice :: #force_inline proc "odin" (self: ^ComputeCommandEncoder, intersectionFunctionTables: []^IntersectionFunctionTable, range: NS.Range) {
	assert(range.length <= NS.UInteger(len(intersectionFunctionTables)))
	msgSend(nil, self, "setIntersectionFunctionTables:withBufferRange:", raw_data(intersectionFunctionTables), range)
}

@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStatesWithLod")
ComputeCommandEncoder_setSamplerStatesWithLod :: #force_inline proc "c" (self: ^ComputeCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}

@(objc_type=ComputeCommandEncoder, objc_name="setSamplerStatesWithRange")
ComputeCommandEncoder_setSamplerStatesWithRange :: #force_inline proc "c" (self: ^ComputeCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setSamplerStates:withRange:", raw_data(samplers), range)
}

ComputeCommandEncoder_setTextures_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setTextures:withRange:", raw_data(textures), range)
}

ComputeCommandEncoder_setVisibleFunctionTables_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", raw_data(visibleFunctionTables), range)
}

ComputeCommandEncoder_useHeaps_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}

ComputeCommandEncoder_useResources_slice :: #force_inline proc "c" (self: ^ComputeCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}

Device_getDefaultSamplePositions_slice :: #force_inline proc "c" (self: ^Device, positions: []SamplePosition) {
	msgSend(nil, self, "getDefaultSamplePositions:count:", raw_data(positions), NS.UInteger(len(positions)))
}

Device_newBufferWithBytes_slice :: #force_inline proc "c" (self: ^Device, bytes: []byte, options: ResourceOptions) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytes:length:options:", raw_data(bytes), NS.UInteger(len(bytes)), options)
}

Device_newBufferWithBytesNoCopy_slice :: #force_inline proc "c" (self: ^Device, bytes: []byte, options: ResourceOptions, deallocator: BufferDeallocator = nil) -> ^Buffer {
	return msgSend(^Buffer, self, "newBufferWithBytesNoCopy:length:options:deallocator:", raw_data(bytes), NS.UInteger(len(bytes)), options, deallocator)
}

@(objc_type=Device, objc_name="newBufferWithSlice")
Device_newBufferWithSlice :: #force_inline proc "c" (self: ^Device, slice: $S/[]$E, options: ResourceOptions) -> ^Buffer {
	return Device_newBufferWithBytes_slice(self, mem.slice_to_bytes(slice), options)
}

@(objc_type=Device, objc_name="newBufferWithSliceNoCopy")
Device_newBufferWithSliceNoCopy :: #force_inline proc "c" (self: ^Device, slice: $S/[]$E, options: ResourceOptions, deallocator: BufferDeallocator = nil) -> ^Buffer {
	return Device_newBufferWithBytesNoCopy_slice(self, mem.slice_to_bytes(slice), options, deallocator)
}

IntersectionFunctionTable_setBuffers_slice :: #force_inline proc "c" (self: ^IntersectionFunctionTable, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

IntersectionFunctionTable_setFunctions_slice :: #force_inline proc "c" (self: ^IntersectionFunctionTable, functions: []^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", raw_data(functions), range)
}

IntersectionFunctionTable_setVisibleFunctionTables_slice :: #force_inline proc "c" (self: ^IntersectionFunctionTable, visibleFunctionTables: []^VisibleFunctionTable, range: NS.Range) {
	msgSend(nil, self, "setVisibleFunctionTables:withBufferRange:", raw_data(visibleFunctionTables), range)
}

RenderCommandEncoder_memoryBarrierWithResources_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, after: RenderStages, before: RenderStages) {
	msgSend(nil, self, "memoryBarrierWithResources:count:afterStages:beforeStages:", raw_data(resources), NS.UInteger(len(resources)), after, before)
}

RenderCommandEncoder_setFragmentBuffers_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setFragmentBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

RenderCommandEncoder_setFragmentBytes_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setFragmentBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}

@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStatesWithLod")
RenderCommandEncoder_setFragmentSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}

@(objc_type=RenderCommandEncoder, objc_name="setFragmentSamplerStatesWithRange")
RenderCommandEncoder_setFragmentSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setFragmentSamplerStates:withRange:", raw_data(samplers), range)
}

RenderCommandEncoder_setFragmentTextures_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setFragmentTextures:withRange:", raw_data(textures), range)
}

RenderCommandEncoder_setScissorRects_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, scissorRects: []ScissorRect) {
	msgSend(nil, self, "setScissorRects:count:", raw_data(scissorRects), NS.UInteger(len(scissorRects)))
}

RenderCommandEncoder_setTileBuffers_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setTileBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

RenderCommandEncoder_setTileBytes_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setTileBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}

@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStatesWithLod")
RenderCommandEncoder_setTileSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}

@(objc_type=RenderCommandEncoder, objc_name="setTileSamplerStatesWithRange")
RenderCommandEncoder_setTileSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setTileSamplerStates:withRange:", raw_data(samplers), range)
}

RenderCommandEncoder_setTileTextures_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setTileTextures:withRange:", raw_data(textures), range)
}

RenderCommandEncoder_setVertexAmplificationCount_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, viewMappings: []VertexAmplificationViewMapping) {
	msgSend(nil, self, "setVertexAmplificationCount:viewMappings:", NS.UInteger(len(viewMappings)), raw_data(viewMappings))
}

RenderCommandEncoder_setVertexBuffers_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, buffers: []^Buffer, offsets: []NS.UInteger, range: NS.Range) {
	msgSend(nil, self, "setVertexBuffers:offsets:withRange:", raw_data(buffers), raw_data(offsets), range)
}

RenderCommandEncoder_setVertexBytes_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, bytes: []byte, index: NS.UInteger) {
	msgSend(nil, self, "setVertexBytes:length:atIndex:", raw_data(bytes), NS.UInteger(len(bytes)), index)
}

@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStatesWithLod")
RenderCommandEncoder_setVertexSamplerStatesWithLod :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, lodMinClamps, lodMaxClamps: []f32, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:lodMinClamps:lodMaxClamps:withRange:", raw_data(samplers), raw_data(lodMinClamps), raw_data(lodMaxClamps), range)
}

@(objc_type=RenderCommandEncoder, objc_name="setVertexSamplerStatesWithRange")
RenderCommandEncoder_setVertexSamplerStatesWithRange :: #force_inline proc "c" (self: ^RenderCommandEncoder, samplers: []^SamplerState, range: NS.Range) {
	msgSend(nil, self, "setVertexSamplerStates:withRange:", raw_data(samplers), range)
}

RenderCommandEncoder_setVertexTextures_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, textures: []^Texture, range: NS.Range) {
	msgSend(nil, self, "setVertexTextures:withRange:", raw_data(textures), range)
}

RenderCommandEncoder_setViewports_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, viewports: []Viewport) {
	msgSend(nil, self, "setViewports:count:", raw_data(viewports), NS.UInteger(len(viewports)))
}

RenderCommandEncoder_useHeaps_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, heaps: []^Heap) {
	msgSend(nil, self, "useHeaps:count:", raw_data(heaps), NS.UInteger(len(heaps)))
}

@(objc_type=RenderCommandEncoder, objc_name="useHeapsWithStages")
RenderCommandEncoder_useHeapsWithStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, heaps: []^Heap, stages: RenderStages) {
	msgSend(nil, self, "useHeaps:count:stages:", raw_data(heaps), NS.UInteger(len(heaps)), stages)
}

RenderCommandEncoder_useResources_slice :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, usage: ResourceUsage) {
	msgSend(nil, self, "useResources:count:usage:", raw_data(resources), NS.UInteger(len(resources)), usage)
}

@(objc_type=RenderCommandEncoder, objc_name="useResourcesStages")
RenderCommandEncoder_useResourcesStages :: #force_inline proc "c" (self: ^RenderCommandEncoder, resources: []^Resource, usage: ResourceUsage, stages: RenderStages) {
	msgSend(nil, self, "useResources:count:usage:stages:", raw_data(resources), NS.UInteger(len(resources)), usage, stages)
}

ResourceStateCommandEncoder_updateTextureMappings_slice :: #force_inline proc "c" (self: ^ResourceStateCommandEncoder, texture: ^Texture, mode: SparseTextureMappingMode, regions: []Region, mipLevels: []NS.UInteger, slices: []NS.UInteger) {
	msgSend(nil, self, "updateTextureMappings:mode:regions:mipLevels:slices:numRegions:", texture, mode, raw_data(regions), raw_data(mipLevels), raw_data(slices), NS.UInteger(len(regions)))
}

VisibleFunctionTable_setFunctions_slice :: #force_inline proc "c" (self: ^VisibleFunctionTable, functions: []^FunctionHandle, range: NS.Range) {
	msgSend(nil, self, "setFunctions:withRange:", raw_data(functions), range)
}


// `presentDrawable:`, `presentDrawable:atTime:` and `presentDrawable:afterMinimumDuration:` share a name,
// but the last two have the same parameter types, so csgen emits no overload group for them.
@(objc_type=CommandBuffer, objc_name="presentDrawable")
CommandBuffer_presentDrawable :: proc{
	CommandBuffer_presentDrawable_,
	CommandBuffer_presentDrawable_atTime,
}

// `array->object(i)` for `array->objectAtIndexedSubscript(i)`; `setObject` is generated.

@(objc_type=AccelerationStructurePassSampleBufferAttachmentDescriptorArray, objc_name="object")
AccelerationStructurePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^AccelerationStructurePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^AccelerationStructurePassSampleBufferAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=AttributeDescriptorArray, objc_name="object")
AttributeDescriptorArray_object :: #force_inline proc "c" (self: ^AttributeDescriptorArray, index: NS.UInteger) -> ^AttributeDescriptor {
	return self->objectAtIndexedSubscript(index)
}

@(objc_type=BlitPassSampleBufferAttachmentDescriptorArray, objc_name="object")
BlitPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^BlitPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^BlitPassSampleBufferAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=BufferLayoutDescriptorArray, objc_name="object")
BufferLayoutDescriptorArray_object :: #force_inline proc "c" (self: ^BufferLayoutDescriptorArray, index: NS.UInteger) -> ^BufferLayoutDescriptor {
	return self->objectAtIndexedSubscript(index)
}

@(objc_type=ComputePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ComputePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^ComputePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ComputePassSampleBufferAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=MTL4RenderPipelineColorAttachmentDescriptorArray, objc_name="object")
MTL4RenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^MTL4RenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^MTL4RenderPipelineColorAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=PipelineBufferDescriptorArray, objc_name="object")
PipelineBufferDescriptorArray_object :: #force_inline proc "c" (self: ^PipelineBufferDescriptorArray, bufferIndex: NS.UInteger) -> ^PipelineBufferDescriptor {
	return self->objectAtIndexedSubscript(bufferIndex)
}

@(objc_type=RasterizationRateLayerArray, objc_name="object")
RasterizationRateLayerArray_object :: #force_inline proc "c" (self: ^RasterizationRateLayerArray, layerIndex: NS.UInteger) -> ^RasterizationRateLayerDescriptor {
	return self->objectAtIndexedSubscript(layerIndex)
}

@(objc_type=RasterizationRateSampleArray, objc_name="object")
RasterizationRateSampleArray_object :: #force_inline proc "c" (self: ^RasterizationRateSampleArray, index: NS.UInteger) -> ^NS.Number {
	return self->objectAtIndexedSubscript(index)
}

@(objc_type=RenderPassColorAttachmentDescriptorArray, objc_name="object")
RenderPassColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPassColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassColorAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=RenderPassSampleBufferAttachmentDescriptorArray, objc_name="object")
RenderPassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPassSampleBufferAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=RenderPipelineColorAttachmentDescriptorArray, objc_name="object")
RenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^RenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^RenderPipelineColorAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=ResourceStatePassSampleBufferAttachmentDescriptorArray, objc_name="object")
ResourceStatePassSampleBufferAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^ResourceStatePassSampleBufferAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^ResourceStatePassSampleBufferAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=TileRenderPipelineColorAttachmentDescriptorArray, objc_name="object")
TileRenderPipelineColorAttachmentDescriptorArray_object :: #force_inline proc "c" (self: ^TileRenderPipelineColorAttachmentDescriptorArray, attachmentIndex: NS.UInteger) -> ^TileRenderPipelineColorAttachmentDescriptor {
	return self->objectAtIndexedSubscript(attachmentIndex)
}

@(objc_type=VertexAttributeDescriptorArray, objc_name="object")
VertexAttributeDescriptorArray_object :: #force_inline proc "c" (self: ^VertexAttributeDescriptorArray, index: NS.UInteger) -> ^VertexAttributeDescriptor {
	return self->objectAtIndexedSubscript(index)
}

@(objc_type=VertexBufferLayoutDescriptorArray, objc_name="object")
VertexBufferLayoutDescriptorArray_object :: #force_inline proc "c" (self: ^VertexBufferLayoutDescriptorArray, index: NS.UInteger) -> ^VertexBufferLayoutDescriptor {
	return self->objectAtIndexedSubscript(index)
}
