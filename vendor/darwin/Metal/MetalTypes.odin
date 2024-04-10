package objc_Metal

import NS "core:sys/darwin/Foundation"
import "base:intrinsics"

BOOL :: NS.BOOL
id :: ^NS.Object

CFTimeInterval :: NS.TimeInterval

IOSurfaceRef :: distinct rawptr

dispatch_queue_t :: id
dispatch_data_t  :: id

@(private)
msgSend :: intrinsics.objc_send

AccelerationStructureInstanceDescriptor :: struct {
	transformationMatrix:            PackedFloat4x3,
	options:                         AccelerationStructureInstanceOptions,
	mask:                            u32,
	intersectionFunctionTableOffset: u32,
	accelerationStructureIndex:      u32,
}

AccelerationStructureSizes :: struct {
	accelerationStructureSize: NS.Integer,
	buildScratchBufferSize:    NS.Integer,
	refitScratchBufferSize:    NS.Integer,
}

AxisAlignedBoundingBox :: struct {
	min: PackedFloat3,
	max: PackedFloat3,
}

ClearColor :: struct {
	red:   f64,
	green: f64,
	blue:  f64,
	alpha: f64,
}

Coordinate2D :: struct {
	x: f32,
	y: f32,
}

CounterResultStageUtilization :: struct {
	totalCycles:                  u64,
	vertexCycles:                 u64,
	tessellationCycles:           u64,
	postTessellationVertexCycles: u64,
	fragmentCycles:               u64,
	renderTargetCycles:           u64,
}

CounterResultStatistic :: struct {
	tessellationInputPatches:          u64,
	vertexInvocations:                 u64,
	postTessellationVertexInvocations: u64,
	clipperInvocations:                u64,
	clipperPrimitivesOut:              u64,
	fragmentInvocations:               u64,
	fragmentsPassed:                   u64,
	computeKernelInvocations:          u64,
}

CounterResultTimestamp :: struct {
	timestamp: u64,
}

DispatchThreadgroupsIndirectArguments :: struct {
	threadgroupsPerGrid: [3]u32,
}

DrawIndexedPrimitivesIndirectArguments :: struct {
	indexCount:    u32,
	instanceCount: u32,
	indexStart:    u32,
	baseVertex:    i32,
	baseInstance:  u32,
}

DrawPatchIndirectArguments :: struct {
	patchCount:    u32,
	instanceCount: u32,
	patchStart:    u32,
	baseInstance:  u32,
}

DrawPrimitivesIndirectArguments :: struct {
	vertexCount:   u32,
	instanceCount: u32,
	vertexStart:   u32,
	baseInstance:  u32,
}

IndirectCommandBufferExecutionRange :: struct {
	location: u32,
	length:   u32,
}

MapIndirectArguments :: struct {
	regionOriginX:    u32,
	regionOriginY:    u32,
	regionOriginZ:    u32,
	regionSizeWidth:  u32,
	regionSizeHeight: u32,
	regionSizeDepth:  u32,
	mipMapLevel:      u32,
	sliceId:          u32,
}

Origin :: distinct [3]NS.Integer

PackedFloat3 :: distinct [3]f32

PackedFloat4x3 :: struct {
	columns: [4]PackedFloat3,
}

QuadTessellationFactorsHalf :: struct {
	edgeTessellationFactor:   [4]u16,
	insideTessellationFactor: [2]u16,
}

Region :: struct {
	origin: Origin,
	size:   Size,
}

SamplePosition :: distinct [2]f32

ResourceID :: distinct u64

ScissorRect :: struct {
	x:      NS.Integer,
	y:      NS.Integer,
	width:  NS.Integer,
	height: NS.Integer,
}

Size :: struct {
	width:  NS.Integer,
	height: NS.Integer,
	depth:  NS.Integer,
}

SizeAndAlign :: struct {
	size:  NS.UInteger,
	align: NS.UInteger,
}

StageInRegionIndirectArguments :: struct {
	stageInOrigin: [3]u32,
	stageInSize:   [3]u32,
}

TextureSwizzleChannels :: struct {
	red:   TextureSwizzle,
	green: TextureSwizzle,
	blue:  TextureSwizzle,
	alpha: TextureSwizzle,
}

TriangleTessellationFactorsHalf :: struct {
	edgeTessellationFactor:   [3]u16,
	insideTessellationFactor: u16,
}

VertexAmplificationViewMapping :: struct {
	viewportArrayIndexOffset:     u32,
	renderTargetArrayIndexOffset: u32,
}

Viewport :: struct {
	originX: f64,
	originY: f64,
	width:   f64,
	height:  f64,
	znear:   f64,
	zfar:    f64,
}

Timestamp :: distinct u64

DeviceNotificationHandler                              :: ^NS.Block
AutoreleasedComputePipelineReflection                  :: ^ComputePipelineReflection
AutoreleasedRenderPipelineReflection                   :: ^RenderPipelineReflection
NewLibraryCompletionHandler                            :: ^NS.Block
NewRenderPipelineStateCompletionHandler                :: ^NS.Block
NewRenderPipelineStateWithReflectionCompletionHandler  :: ^NS.Block
NewComputePipelineStateCompletionHandler               :: ^NS.Block
NewComputePipelineStateWithReflectionCompletionHandler :: ^NS.Block
SharedEventNotificationBlock :: ^NS.Block

DrawablePresentedHandler :: ^NS.Block

AutoreleasedArgument :: ^Argument