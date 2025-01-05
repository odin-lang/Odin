//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan

import "core:c"

import win32 "core:sys/windows"
_ :: win32

import "vendor:x11/xlib"
_ :: xlib

when ODIN_OS == .Windows {
	HINSTANCE           :: win32.HINSTANCE
	HWND                :: win32.HWND
	HMONITOR            :: win32.HMONITOR
	HANDLE              :: win32.HANDLE
	LPCWSTR             :: win32.LPCWSTR
	SECURITY_ATTRIBUTES :: win32.SECURITY_ATTRIBUTES
	DWORD               :: win32.DWORD
	LONG                :: win32.LONG
	LUID                :: win32.LUID
} else {
	HINSTANCE           :: distinct rawptr
	HWND                :: distinct rawptr
	HMONITOR            :: distinct rawptr
	HANDLE              :: distinct rawptr
	LPCWSTR             :: ^u16
	SECURITY_ATTRIBUTES :: struct {}
	DWORD               :: u32
	LONG                :: c.long
	LUID :: struct {
		LowPart:  DWORD,
		HighPart: LONG,
	}
}

when xlib.IS_SUPPORTED {
	XlibDisplay  :: xlib.Display
	XlibWindow   :: xlib.Window
	XlibVisualID :: xlib.VisualID
} else {
	XlibDisplay  :: struct {} // Opaque struct defined by Xlib
	XlibWindow   :: c.ulong
	XlibVisualID :: c.ulong
}

xcb_visualid_t :: u32
xcb_window_t   :: u32
CAMetalLayer   :: struct {}

MTLBuffer_id       :: rawptr
MTLTexture_id      :: rawptr
MTLSharedEvent_id  :: rawptr
MTLDevice_id       :: rawptr
MTLCommandQueue_id :: rawptr

/********************************/

Extent2D :: struct {
	width:  u32,
	height: u32,
}

Extent3D :: struct {
	width:  u32,
	height: u32,
	depth:  u32,
}

Offset2D :: struct {
	x: i32,
	y: i32,
}

Offset3D :: struct {
	x: i32,
	y: i32,
	z: i32,
}

Rect2D :: struct {
	offset: Offset2D,
	extent: Extent2D,
}

BaseInStructure :: struct {
	sType: StructureType,
	pNext: ^BaseInStructure,
}

BaseOutStructure :: struct {
	sType: StructureType,
	pNext: ^BaseOutStructure,
}

BufferMemoryBarrier :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcAccessMask:       AccessFlags,
	dstAccessMask:       AccessFlags,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	buffer:              Buffer,
	offset:              DeviceSize,
	size:                DeviceSize,
}

DispatchIndirectCommand :: struct {
	x: u32,
	y: u32,
	z: u32,
}

DrawIndexedIndirectCommand :: struct {
	indexCount:    u32,
	instanceCount: u32,
	firstIndex:    u32,
	vertexOffset:  i32,
	firstInstance: u32,
}

DrawIndirectCommand :: struct {
	vertexCount:   u32,
	instanceCount: u32,
	firstVertex:   u32,
	firstInstance: u32,
}

ImageSubresourceRange :: struct {
	aspectMask:     ImageAspectFlags,
	baseMipLevel:   u32,
	levelCount:     u32,
	baseArrayLayer: u32,
	layerCount:     u32,
}

ImageMemoryBarrier :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcAccessMask:       AccessFlags,
	dstAccessMask:       AccessFlags,
	oldLayout:           ImageLayout,
	newLayout:           ImageLayout,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	image:               Image,
	subresourceRange:    ImageSubresourceRange,
}

MemoryBarrier :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	srcAccessMask: AccessFlags,
	dstAccessMask: AccessFlags,
}

PipelineCacheHeaderVersionOne :: struct {
	headerSize:        u32,
	headerVersion:     PipelineCacheHeaderVersion,
	vendorID:          u32,
	deviceID:          u32,
	pipelineCacheUUID: [UUID_SIZE]u8,
}

AllocationCallbacks :: struct {
	pUserData:             rawptr,
	pfnAllocation:         ProcAllocationFunction,
	pfnReallocation:       ProcReallocationFunction,
	pfnFree:               ProcFreeFunction,
	pfnInternalAllocation: ProcInternalAllocationNotification,
	pfnInternalFree:       ProcInternalFreeNotification,
}

ApplicationInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	pApplicationName:   cstring,
	applicationVersion: u32,
	pEngineName:        cstring,
	engineVersion:      u32,
	apiVersion:         u32,
}

FormatProperties :: struct {
	linearTilingFeatures:  FormatFeatureFlags,
	optimalTilingFeatures: FormatFeatureFlags,
	bufferFeatures:        FormatFeatureFlags,
}

ImageFormatProperties :: struct {
	maxExtent:       Extent3D,
	maxMipLevels:    u32,
	maxArrayLayers:  u32,
	sampleCounts:    SampleCountFlags,
	maxResourceSize: DeviceSize,
}

InstanceCreateInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   InstanceCreateFlags,
	pApplicationInfo:        ^ApplicationInfo,
	enabledLayerCount:       u32,
	ppEnabledLayerNames:     [^]cstring,
	enabledExtensionCount:   u32,
	ppEnabledExtensionNames: [^]cstring,
}

MemoryHeap :: struct {
	size:  DeviceSize,
	flags: MemoryHeapFlags,
}

MemoryType :: struct {
	propertyFlags: MemoryPropertyFlags,
	heapIndex:     u32,
}

PhysicalDeviceFeatures :: struct {
	robustBufferAccess:                      b32,
	fullDrawIndexUint32:                     b32,
	imageCubeArray:                          b32,
	independentBlend:                        b32,
	geometryShader:                          b32,
	tessellationShader:                      b32,
	sampleRateShading:                       b32,
	dualSrcBlend:                            b32,
	logicOp:                                 b32,
	multiDrawIndirect:                       b32,
	drawIndirectFirstInstance:               b32,
	depthClamp:                              b32,
	depthBiasClamp:                          b32,
	fillModeNonSolid:                        b32,
	depthBounds:                             b32,
	wideLines:                               b32,
	largePoints:                             b32,
	alphaToOne:                              b32,
	multiViewport:                           b32,
	samplerAnisotropy:                       b32,
	textureCompressionETC2:                  b32,
	textureCompressionASTC_LDR:              b32,
	textureCompressionBC:                    b32,
	occlusionQueryPrecise:                   b32,
	pipelineStatisticsQuery:                 b32,
	vertexPipelineStoresAndAtomics:          b32,
	fragmentStoresAndAtomics:                b32,
	shaderTessellationAndGeometryPointSize:  b32,
	shaderImageGatherExtended:               b32,
	shaderStorageImageExtendedFormats:       b32,
	shaderStorageImageMultisample:           b32,
	shaderStorageImageReadWithoutFormat:     b32,
	shaderStorageImageWriteWithoutFormat:    b32,
	shaderUniformBufferArrayDynamicIndexing: b32,
	shaderSampledImageArrayDynamicIndexing:  b32,
	shaderStorageBufferArrayDynamicIndexing: b32,
	shaderStorageImageArrayDynamicIndexing:  b32,
	shaderClipDistance:                      b32,
	shaderCullDistance:                      b32,
	shaderFloat64:                           b32,
	shaderInt64:                             b32,
	shaderInt16:                             b32,
	shaderResourceResidency:                 b32,
	shaderResourceMinLod:                    b32,
	sparseBinding:                           b32,
	sparseResidencyBuffer:                   b32,
	sparseResidencyImage2D:                  b32,
	sparseResidencyImage3D:                  b32,
	sparseResidency2Samples:                 b32,
	sparseResidency4Samples:                 b32,
	sparseResidency8Samples:                 b32,
	sparseResidency16Samples:                b32,
	sparseResidencyAliased:                  b32,
	variableMultisampleRate:                 b32,
	inheritedQueries:                        b32,
}

PhysicalDeviceLimits :: struct {
	maxImageDimension1D:                             u32,
	maxImageDimension2D:                             u32,
	maxImageDimension3D:                             u32,
	maxImageDimensionCube:                           u32,
	maxImageArrayLayers:                             u32,
	maxTexelBufferElements:                          u32,
	maxUniformBufferRange:                           u32,
	maxStorageBufferRange:                           u32,
	maxPushConstantsSize:                            u32,
	maxMemoryAllocationCount:                        u32,
	maxSamplerAllocationCount:                       u32,
	bufferImageGranularity:                          DeviceSize,
	sparseAddressSpaceSize:                          DeviceSize,
	maxBoundDescriptorSets:                          u32,
	maxPerStageDescriptorSamplers:                   u32,
	maxPerStageDescriptorUniformBuffers:             u32,
	maxPerStageDescriptorStorageBuffers:             u32,
	maxPerStageDescriptorSampledImages:              u32,
	maxPerStageDescriptorStorageImages:              u32,
	maxPerStageDescriptorInputAttachments:           u32,
	maxPerStageResources:                            u32,
	maxDescriptorSetSamplers:                        u32,
	maxDescriptorSetUniformBuffers:                  u32,
	maxDescriptorSetUniformBuffersDynamic:           u32,
	maxDescriptorSetStorageBuffers:                  u32,
	maxDescriptorSetStorageBuffersDynamic:           u32,
	maxDescriptorSetSampledImages:                   u32,
	maxDescriptorSetStorageImages:                   u32,
	maxDescriptorSetInputAttachments:                u32,
	maxVertexInputAttributes:                        u32,
	maxVertexInputBindings:                          u32,
	maxVertexInputAttributeOffset:                   u32,
	maxVertexInputBindingStride:                     u32,
	maxVertexOutputComponents:                       u32,
	maxTessellationGenerationLevel:                  u32,
	maxTessellationPatchSize:                        u32,
	maxTessellationControlPerVertexInputComponents:  u32,
	maxTessellationControlPerVertexOutputComponents: u32,
	maxTessellationControlPerPatchOutputComponents:  u32,
	maxTessellationControlTotalOutputComponents:     u32,
	maxTessellationEvaluationInputComponents:        u32,
	maxTessellationEvaluationOutputComponents:       u32,
	maxGeometryShaderInvocations:                    u32,
	maxGeometryInputComponents:                      u32,
	maxGeometryOutputComponents:                     u32,
	maxGeometryOutputVertices:                       u32,
	maxGeometryTotalOutputComponents:                u32,
	maxFragmentInputComponents:                      u32,
	maxFragmentOutputAttachments:                    u32,
	maxFragmentDualSrcAttachments:                   u32,
	maxFragmentCombinedOutputResources:              u32,
	maxComputeSharedMemorySize:                      u32,
	maxComputeWorkGroupCount:                        [3]u32,
	maxComputeWorkGroupInvocations:                  u32,
	maxComputeWorkGroupSize:                         [3]u32,
	subPixelPrecisionBits:                           u32,
	subTexelPrecisionBits:                           u32,
	mipmapPrecisionBits:                             u32,
	maxDrawIndexedIndexValue:                        u32,
	maxDrawIndirectCount:                            u32,
	maxSamplerLodBias:                               f32,
	maxSamplerAnisotropy:                            f32,
	maxViewports:                                    u32,
	maxViewportDimensions:                           [2]u32,
	viewportBoundsRange:                             [2]f32,
	viewportSubPixelBits:                            u32,
	minMemoryMapAlignment:                           int,
	minTexelBufferOffsetAlignment:                   DeviceSize,
	minUniformBufferOffsetAlignment:                 DeviceSize,
	minStorageBufferOffsetAlignment:                 DeviceSize,
	minTexelOffset:                                  i32,
	maxTexelOffset:                                  u32,
	minTexelGatherOffset:                            i32,
	maxTexelGatherOffset:                            u32,
	minInterpolationOffset:                          f32,
	maxInterpolationOffset:                          f32,
	subPixelInterpolationOffsetBits:                 u32,
	maxFramebufferWidth:                             u32,
	maxFramebufferHeight:                            u32,
	maxFramebufferLayers:                            u32,
	framebufferColorSampleCounts:                    SampleCountFlags,
	framebufferDepthSampleCounts:                    SampleCountFlags,
	framebufferStencilSampleCounts:                  SampleCountFlags,
	framebufferNoAttachmentsSampleCounts:            SampleCountFlags,
	maxColorAttachments:                             u32,
	sampledImageColorSampleCounts:                   SampleCountFlags,
	sampledImageIntegerSampleCounts:                 SampleCountFlags,
	sampledImageDepthSampleCounts:                   SampleCountFlags,
	sampledImageStencilSampleCounts:                 SampleCountFlags,
	storageImageSampleCounts:                        SampleCountFlags,
	maxSampleMaskWords:                              u32,
	timestampComputeAndGraphics:                     b32,
	timestampPeriod:                                 f32,
	maxClipDistances:                                u32,
	maxCullDistances:                                u32,
	maxCombinedClipAndCullDistances:                 u32,
	discreteQueuePriorities:                         u32,
	pointSizeRange:                                  [2]f32,
	lineWidthRange:                                  [2]f32,
	pointSizeGranularity:                            f32,
	lineWidthGranularity:                            f32,
	strictLines:                                     b32,
	standardSampleLocations:                         b32,
	optimalBufferCopyOffsetAlignment:                DeviceSize,
	optimalBufferCopyRowPitchAlignment:              DeviceSize,
	nonCoherentAtomSize:                             DeviceSize,
}

PhysicalDeviceMemoryProperties :: struct {
	memoryTypeCount: u32,
	memoryTypes:     [MAX_MEMORY_TYPES]MemoryType,
	memoryHeapCount: u32,
	memoryHeaps:     [MAX_MEMORY_HEAPS]MemoryHeap,
}

PhysicalDeviceSparseProperties :: struct {
	residencyStandard2DBlockShape:            b32,
	residencyStandard2DMultisampleBlockShape: b32,
	residencyStandard3DBlockShape:            b32,
	residencyAlignedMipSize:                  b32,
	residencyNonResidentStrict:               b32,
}

PhysicalDeviceProperties :: struct {
	apiVersion:        u32,
	driverVersion:     u32,
	vendorID:          u32,
	deviceID:          u32,
	deviceType:        PhysicalDeviceType,
	deviceName:        [MAX_PHYSICAL_DEVICE_NAME_SIZE]byte,
	pipelineCacheUUID: [UUID_SIZE]u8,
	limits:            PhysicalDeviceLimits,
	sparseProperties:  PhysicalDeviceSparseProperties,
}

QueueFamilyProperties :: struct {
	queueFlags:                  QueueFlags,
	queueCount:                  u32,
	timestampValidBits:          u32,
	minImageTransferGranularity: Extent3D,
}

DeviceQueueCreateInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            DeviceQueueCreateFlags,
	queueFamilyIndex: u32,
	queueCount:       u32,
	pQueuePriorities: [^]f32,
}

DeviceCreateInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   DeviceCreateFlags,
	queueCreateInfoCount:    u32,
	pQueueCreateInfos:       [^]DeviceQueueCreateInfo,
	enabledLayerCount:       u32,
	ppEnabledLayerNames:     [^]cstring,
	enabledExtensionCount:   u32,
	ppEnabledExtensionNames: [^]cstring,
	pEnabledFeatures:        [^]PhysicalDeviceFeatures,
}

ExtensionProperties :: struct {
	extensionName: [MAX_EXTENSION_NAME_SIZE]byte,
	specVersion:   u32,
}

LayerProperties :: struct {
	layerName:             [MAX_EXTENSION_NAME_SIZE]byte,
	specVersion:           u32,
	implementationVersion: u32,
	description:           [MAX_DESCRIPTION_SIZE]byte,
}

SubmitInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	waitSemaphoreCount:   u32,
	pWaitSemaphores:      [^]Semaphore,
	pWaitDstStageMask:    [^]PipelineStageFlags,
	commandBufferCount:   u32,
	pCommandBuffers:      [^]CommandBuffer,
	signalSemaphoreCount: u32,
	pSignalSemaphores:    [^]Semaphore,
}

MappedMemoryRange :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	memory: DeviceMemory,
	offset: DeviceSize,
	size:   DeviceSize,
}

MemoryAllocateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	allocationSize:  DeviceSize,
	memoryTypeIndex: u32,
}

MemoryRequirements :: struct {
	size:           DeviceSize,
	alignment:      DeviceSize,
	memoryTypeBits: u32,
}

SparseMemoryBind :: struct {
	resourceOffset: DeviceSize,
	size:           DeviceSize,
	memory:         DeviceMemory,
	memoryOffset:   DeviceSize,
	flags:          SparseMemoryBindFlags,
}

SparseBufferMemoryBindInfo :: struct {
	buffer:    Buffer,
	bindCount: u32,
	pBinds:    [^]SparseMemoryBind,
}

SparseImageOpaqueMemoryBindInfo :: struct {
	image:     Image,
	bindCount: u32,
	pBinds:    [^]SparseMemoryBind,
}

ImageSubresource :: struct {
	aspectMask: ImageAspectFlags,
	mipLevel:   u32,
	arrayLayer: u32,
}

SparseImageMemoryBind :: struct {
	subresource:  ImageSubresource,
	offset:       Offset3D,
	extent:       Extent3D,
	memory:       DeviceMemory,
	memoryOffset: DeviceSize,
	flags:        SparseMemoryBindFlags,
}

SparseImageMemoryBindInfo :: struct {
	image:     Image,
	bindCount: u32,
	pBinds:    [^]SparseImageMemoryBind,
}

BindSparseInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	waitSemaphoreCount:   u32,
	pWaitSemaphores:      [^]Semaphore,
	bufferBindCount:      u32,
	pBufferBinds:         [^]SparseBufferMemoryBindInfo,
	imageOpaqueBindCount: u32,
	pImageOpaqueBinds:    [^]SparseImageOpaqueMemoryBindInfo,
	imageBindCount:       u32,
	pImageBinds:          [^]SparseImageMemoryBindInfo,
	signalSemaphoreCount: u32,
	pSignalSemaphores:    [^]Semaphore,
}

SparseImageFormatProperties :: struct {
	aspectMask:       ImageAspectFlags,
	imageGranularity: Extent3D,
	flags:            SparseImageFormatFlags,
}

SparseImageMemoryRequirements :: struct {
	formatProperties:     SparseImageFormatProperties,
	imageMipTailFirstLod: u32,
	imageMipTailSize:     DeviceSize,
	imageMipTailOffset:   DeviceSize,
	imageMipTailStride:   DeviceSize,
}

FenceCreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: FenceCreateFlags,
}

SemaphoreCreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: SemaphoreCreateFlags,
}

EventCreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: EventCreateFlags,
}

QueryPoolCreateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	flags:              QueryPoolCreateFlags,
	queryType:          QueryType,
	queryCount:         u32,
	pipelineStatistics: QueryPipelineStatisticFlags,
}

BufferCreateInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 BufferCreateFlags,
	size:                  DeviceSize,
	usage:                 BufferUsageFlags,
	sharingMode:           SharingMode,
	queueFamilyIndexCount: u32,
	pQueueFamilyIndices:   [^]u32,
}

BufferViewCreateInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	flags:  BufferViewCreateFlags,
	buffer: Buffer,
	format: Format,
	offset: DeviceSize,
	range:  DeviceSize,
}

ImageCreateInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 ImageCreateFlags,
	imageType:             ImageType,
	format:                Format,
	extent:                Extent3D,
	mipLevels:             u32,
	arrayLayers:           u32,
	samples:               SampleCountFlags,
	tiling:                ImageTiling,
	usage:                 ImageUsageFlags,
	sharingMode:           SharingMode,
	queueFamilyIndexCount: u32,
	pQueueFamilyIndices:   [^]u32,
	initialLayout:         ImageLayout,
}

SubresourceLayout :: struct {
	offset:     DeviceSize,
	size:       DeviceSize,
	rowPitch:   DeviceSize,
	arrayPitch: DeviceSize,
	depthPitch: DeviceSize,
}

ComponentMapping :: struct {
	r: ComponentSwizzle,
	g: ComponentSwizzle,
	b: ComponentSwizzle,
	a: ComponentSwizzle,
}

ImageViewCreateInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            ImageViewCreateFlags,
	image:            Image,
	viewType:         ImageViewType,
	format:           Format,
	components:       ComponentMapping,
	subresourceRange: ImageSubresourceRange,
}

ShaderModuleCreateInfo :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	flags:    ShaderModuleCreateFlags,
	codeSize: int,
	pCode:    ^u32,
}

PipelineCacheCreateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           PipelineCacheCreateFlags,
	initialDataSize: int,
	pInitialData:    rawptr,
}

SpecializationMapEntry :: struct {
	constantID: u32,
	offset:     u32,
	size:       int,
}

SpecializationInfo :: struct {
	mapEntryCount: u32,
	pMapEntries:   [^]SpecializationMapEntry,
	dataSize:      int,
	pData:         rawptr,
}

PipelineShaderStageCreateInfo :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	flags:               PipelineShaderStageCreateFlags,
	stage:               ShaderStageFlags,
	module:              ShaderModule,
	pName:               cstring,
	pSpecializationInfo: ^SpecializationInfo,
}

ComputePipelineCreateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	flags:              PipelineCreateFlags,
	stage:              PipelineShaderStageCreateInfo,
	layout:             PipelineLayout,
	basePipelineHandle: Pipeline,
	basePipelineIndex:  i32,
}

VertexInputBindingDescription :: struct {
	binding:   u32,
	stride:    u32,
	inputRate: VertexInputRate,
}

VertexInputAttributeDescription :: struct {
	location: u32,
	binding:  u32,
	format:   Format,
	offset:   u32,
}

PipelineVertexInputStateCreateInfo :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	flags:                           PipelineVertexInputStateCreateFlags,
	vertexBindingDescriptionCount:   u32,
	pVertexBindingDescriptions:      [^]VertexInputBindingDescription,
	vertexAttributeDescriptionCount: u32,
	pVertexAttributeDescriptions:    [^]VertexInputAttributeDescription,
}

PipelineInputAssemblyStateCreateInfo :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  PipelineInputAssemblyStateCreateFlags,
	topology:               PrimitiveTopology,
	primitiveRestartEnable: b32,
}

PipelineTessellationStateCreateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	flags:              PipelineTessellationStateCreateFlags,
	patchControlPoints: u32,
}

Viewport :: struct {
	x:        f32,
	y:        f32,
	width:    f32,
	height:   f32,
	minDepth: f32,
	maxDepth: f32,
}

PipelineViewportStateCreateInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	flags:         PipelineViewportStateCreateFlags,
	viewportCount: u32,
	pViewports:    [^]Viewport,
	scissorCount:  u32,
	pScissors:     [^]Rect2D,
}

PipelineRasterizationStateCreateInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   PipelineRasterizationStateCreateFlags,
	depthClampEnable:        b32,
	rasterizerDiscardEnable: b32,
	polygonMode:             PolygonMode,
	cullMode:                CullModeFlags,
	frontFace:               FrontFace,
	depthBiasEnable:         b32,
	depthBiasConstantFactor: f32,
	depthBiasClamp:          f32,
	depthBiasSlopeFactor:    f32,
	lineWidth:               f32,
}

PipelineMultisampleStateCreateInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 PipelineMultisampleStateCreateFlags,
	rasterizationSamples:  SampleCountFlags,
	sampleShadingEnable:   b32,
	minSampleShading:      f32,
	pSampleMask:           ^SampleMask,
	alphaToCoverageEnable: b32,
	alphaToOneEnable:      b32,
}

StencilOpState :: struct {
	failOp:      StencilOp,
	passOp:      StencilOp,
	depthFailOp: StencilOp,
	compareOp:   CompareOp,
	compareMask: u32,
	writeMask:   u32,
	reference:   u32,
}

PipelineDepthStencilStateCreateInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 PipelineDepthStencilStateCreateFlags,
	depthTestEnable:       b32,
	depthWriteEnable:      b32,
	depthCompareOp:        CompareOp,
	depthBoundsTestEnable: b32,
	stencilTestEnable:     b32,
	front:                 StencilOpState,
	back:                  StencilOpState,
	minDepthBounds:        f32,
	maxDepthBounds:        f32,
}

PipelineColorBlendAttachmentState :: struct {
	blendEnable:         b32,
	srcColorBlendFactor: BlendFactor,
	dstColorBlendFactor: BlendFactor,
	colorBlendOp:        BlendOp,
	srcAlphaBlendFactor: BlendFactor,
	dstAlphaBlendFactor: BlendFactor,
	alphaBlendOp:        BlendOp,
	colorWriteMask:      ColorComponentFlags,
}

PipelineColorBlendStateCreateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           PipelineColorBlendStateCreateFlags,
	logicOpEnable:   b32,
	logicOp:         LogicOp,
	attachmentCount: u32,
	pAttachments:    [^]PipelineColorBlendAttachmentState,
	blendConstants:  [4]f32,
}

PipelineDynamicStateCreateInfo :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	flags:             PipelineDynamicStateCreateFlags,
	dynamicStateCount: u32,
	pDynamicStates:    [^]DynamicState,
}

GraphicsPipelineCreateInfo :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	flags:               PipelineCreateFlags,
	stageCount:          u32,
	pStages:             [^]PipelineShaderStageCreateInfo,
	pVertexInputState:   ^PipelineVertexInputStateCreateInfo,
	pInputAssemblyState: ^PipelineInputAssemblyStateCreateInfo,
	pTessellationState:  ^PipelineTessellationStateCreateInfo,
	pViewportState:      ^PipelineViewportStateCreateInfo,
	pRasterizationState: ^PipelineRasterizationStateCreateInfo,
	pMultisampleState:   ^PipelineMultisampleStateCreateInfo,
	pDepthStencilState:  ^PipelineDepthStencilStateCreateInfo,
	pColorBlendState:    ^PipelineColorBlendStateCreateInfo,
	pDynamicState:       ^PipelineDynamicStateCreateInfo,
	layout:              PipelineLayout,
	renderPass:          RenderPass,
	subpass:             u32,
	basePipelineHandle:  Pipeline,
	basePipelineIndex:   i32,
}

PushConstantRange :: struct {
	stageFlags: ShaderStageFlags,
	offset:     u32,
	size:       u32,
}

PipelineLayoutCreateInfo :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  PipelineLayoutCreateFlags,
	setLayoutCount:         u32,
	pSetLayouts:            [^]DescriptorSetLayout,
	pushConstantRangeCount: u32,
	pPushConstantRanges:    [^]PushConstantRange,
}

SamplerCreateInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   SamplerCreateFlags,
	magFilter:               Filter,
	minFilter:               Filter,
	mipmapMode:              SamplerMipmapMode,
	addressModeU:            SamplerAddressMode,
	addressModeV:            SamplerAddressMode,
	addressModeW:            SamplerAddressMode,
	mipLodBias:              f32,
	anisotropyEnable:        b32,
	maxAnisotropy:           f32,
	compareEnable:           b32,
	compareOp:               CompareOp,
	minLod:                  f32,
	maxLod:                  f32,
	borderColor:             BorderColor,
	unnormalizedCoordinates: b32,
}

CopyDescriptorSet :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	srcSet:          DescriptorSet,
	srcBinding:      u32,
	srcArrayElement: u32,
	dstSet:          DescriptorSet,
	dstBinding:      u32,
	dstArrayElement: u32,
	descriptorCount: u32,
}

DescriptorBufferInfo :: struct {
	buffer: Buffer,
	offset: DeviceSize,
	range:  DeviceSize,
}

DescriptorImageInfo :: struct {
	sampler:     Sampler,
	imageView:   ImageView,
	imageLayout: ImageLayout,
}

DescriptorPoolSize :: struct {
	type:            DescriptorType,
	descriptorCount: u32,
}

DescriptorPoolCreateInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	flags:         DescriptorPoolCreateFlags,
	maxSets:       u32,
	poolSizeCount: u32,
	pPoolSizes:    [^]DescriptorPoolSize,
}

DescriptorSetAllocateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	descriptorPool:     DescriptorPool,
	descriptorSetCount: u32,
	pSetLayouts:        [^]DescriptorSetLayout,
}

DescriptorSetLayoutBinding :: struct {
	binding:            u32,
	descriptorType:     DescriptorType,
	descriptorCount:    u32,
	stageFlags:         ShaderStageFlags,
	pImmutableSamplers: [^]Sampler,
}

DescriptorSetLayoutCreateInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	flags:        DescriptorSetLayoutCreateFlags,
	bindingCount: u32,
	pBindings:    [^]DescriptorSetLayoutBinding,
}

WriteDescriptorSet :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	dstSet:           DescriptorSet,
	dstBinding:       u32,
	dstArrayElement:  u32,
	descriptorCount:  u32,
	descriptorType:   DescriptorType,
	pImageInfo:       ^DescriptorImageInfo,
	pBufferInfo:      ^DescriptorBufferInfo,
	pTexelBufferView: ^BufferView,
}

AttachmentDescription :: struct {
	flags:          AttachmentDescriptionFlags,
	format:         Format,
	samples:        SampleCountFlags,
	loadOp:         AttachmentLoadOp,
	storeOp:        AttachmentStoreOp,
	stencilLoadOp:  AttachmentLoadOp,
	stencilStoreOp: AttachmentStoreOp,
	initialLayout:  ImageLayout,
	finalLayout:    ImageLayout,
}

AttachmentReference :: struct {
	attachment: u32,
	layout:     ImageLayout,
}

FramebufferCreateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           FramebufferCreateFlags,
	renderPass:      RenderPass,
	attachmentCount: u32,
	pAttachments:    [^]ImageView,
	width:           u32,
	height:          u32,
	layers:          u32,
}

SubpassDescription :: struct {
	flags:                   SubpassDescriptionFlags,
	pipelineBindPoint:       PipelineBindPoint,
	inputAttachmentCount:    u32,
	pInputAttachments:       [^]AttachmentReference,
	colorAttachmentCount:    u32,
	pColorAttachments:       [^]AttachmentReference,
	pResolveAttachments:     [^]AttachmentReference,
	pDepthStencilAttachment: ^AttachmentReference,
	preserveAttachmentCount: u32,
	pPreserveAttachments:    [^]u32,
}

SubpassDependency :: struct {
	srcSubpass:      u32,
	dstSubpass:      u32,
	srcStageMask:    PipelineStageFlags,
	dstStageMask:    PipelineStageFlags,
	srcAccessMask:   AccessFlags,
	dstAccessMask:   AccessFlags,
	dependencyFlags: DependencyFlags,
}

RenderPassCreateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           RenderPassCreateFlags,
	attachmentCount: u32,
	pAttachments:    [^]AttachmentDescription,
	subpassCount:    u32,
	pSubpasses:      [^]SubpassDescription,
	dependencyCount: u32,
	pDependencies:   [^]SubpassDependency,
}

CommandPoolCreateInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            CommandPoolCreateFlags,
	queueFamilyIndex: u32,
}

CommandBufferAllocateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	commandPool:        CommandPool,
	level:              CommandBufferLevel,
	commandBufferCount: u32,
}

CommandBufferInheritanceInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	renderPass:           RenderPass,
	subpass:              u32,
	framebuffer:          Framebuffer,
	occlusionQueryEnable: b32,
	queryFlags:           QueryControlFlags,
	pipelineStatistics:   QueryPipelineStatisticFlags,
}

CommandBufferBeginInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            CommandBufferUsageFlags,
	pInheritanceInfo: ^CommandBufferInheritanceInfo,
}

BufferCopy :: struct {
	srcOffset: DeviceSize,
	dstOffset: DeviceSize,
	size:      DeviceSize,
}

ImageSubresourceLayers :: struct {
	aspectMask:     ImageAspectFlags,
	mipLevel:       u32,
	baseArrayLayer: u32,
	layerCount:     u32,
}

BufferImageCopy :: struct {
	bufferOffset:      DeviceSize,
	bufferRowLength:   u32,
	bufferImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

ClearColorValue :: struct #raw_union {
	float32: [4]f32,
	int32:   [4]i32,
	uint32:  [4]u32,
}

ClearDepthStencilValue :: struct {
	depth:   f32,
	stencil: u32,
}

ClearValue :: struct #raw_union {
	color:        ClearColorValue,
	depthStencil: ClearDepthStencilValue,
}

ClearAttachment :: struct {
	aspectMask:      ImageAspectFlags,
	colorAttachment: u32,
	clearValue:      ClearValue,
}

ClearRect :: struct {
	rect:           Rect2D,
	baseArrayLayer: u32,
	layerCount:     u32,
}

ImageBlit :: struct {
	srcSubresource: ImageSubresourceLayers,
	srcOffsets:     [2]Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffsets:     [2]Offset3D,
}

ImageCopy :: struct {
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

ImageResolve :: struct {
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

RenderPassBeginInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	renderPass:      RenderPass,
	framebuffer:     Framebuffer,
	renderArea:      Rect2D,
	clearValueCount: u32,
	pClearValues:    [^]ClearValue,
}

PhysicalDeviceSubgroupProperties :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	subgroupSize:              u32,
	supportedStages:           ShaderStageFlags,
	supportedOperations:       SubgroupFeatureFlags,
	quadOperationsInAllStages: b32,
}

BindBufferMemoryInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	buffer:       Buffer,
	memory:       DeviceMemory,
	memoryOffset: DeviceSize,
}

BindImageMemoryInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	image:        Image,
	memory:       DeviceMemory,
	memoryOffset: DeviceSize,
}

PhysicalDevice16BitStorageFeatures :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	storageBuffer16BitAccess:           b32,
	uniformAndStorageBuffer16BitAccess: b32,
	storagePushConstant16:              b32,
	storageInputOutput16:               b32,
}

MemoryDedicatedRequirements :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	prefersDedicatedAllocation:  b32,
	requiresDedicatedAllocation: b32,
}

MemoryDedicatedAllocateInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	image:  Image,
	buffer: Buffer,
}

MemoryAllocateFlagsInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	flags:      MemoryAllocateFlags,
	deviceMask: u32,
}

DeviceGroupRenderPassBeginInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	deviceMask:            u32,
	deviceRenderAreaCount: u32,
	pDeviceRenderAreas:    [^]Rect2D,
}

DeviceGroupCommandBufferBeginInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	deviceMask: u32,
}

DeviceGroupSubmitInfo :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	waitSemaphoreCount:            u32,
	pWaitSemaphoreDeviceIndices:   [^]u32,
	commandBufferCount:            u32,
	pCommandBufferDeviceMasks:     [^]u32,
	signalSemaphoreCount:          u32,
	pSignalSemaphoreDeviceIndices: [^]u32,
}

DeviceGroupBindSparseInfo :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	resourceDeviceIndex: u32,
	memoryDeviceIndex:   u32,
}

BindBufferMemoryDeviceGroupInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	deviceIndexCount: u32,
	pDeviceIndices:   [^]u32,
}

BindImageMemoryDeviceGroupInfo :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	deviceIndexCount:             u32,
	pDeviceIndices:               [^]u32,
	splitInstanceBindRegionCount: u32,
	pSplitInstanceBindRegions:    [^]Rect2D,
}

PhysicalDeviceGroupProperties :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	physicalDeviceCount: u32,
	physicalDevices:     [MAX_DEVICE_GROUP_SIZE]PhysicalDevice,
	subsetAllocation:    b32,
}

DeviceGroupDeviceCreateInfo :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	physicalDeviceCount: u32,
	pPhysicalDevices:    [^]PhysicalDevice,
}

BufferMemoryRequirementsInfo2 :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	buffer: Buffer,
}

ImageMemoryRequirementsInfo2 :: struct {
	sType: StructureType,
	pNext: rawptr,
	image: Image,
}

ImageSparseMemoryRequirementsInfo2 :: struct {
	sType: StructureType,
	pNext: rawptr,
	image: Image,
}

MemoryRequirements2 :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	memoryRequirements: MemoryRequirements,
}

SparseImageMemoryRequirements2 :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	memoryRequirements: SparseImageMemoryRequirements,
}

PhysicalDeviceFeatures2 :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	features: PhysicalDeviceFeatures,
}

PhysicalDeviceProperties2 :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	properties: PhysicalDeviceProperties,
}

FormatProperties2 :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	formatProperties: FormatProperties,
}

ImageFormatProperties2 :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	imageFormatProperties: ImageFormatProperties,
}

PhysicalDeviceImageFormatInfo2 :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	format: Format,
	type:   ImageType,
	tiling: ImageTiling,
	usage:  ImageUsageFlags,
	flags:  ImageCreateFlags,
}

QueueFamilyProperties2 :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	queueFamilyProperties: QueueFamilyProperties,
}

PhysicalDeviceMemoryProperties2 :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	memoryProperties: PhysicalDeviceMemoryProperties,
}

SparseImageFormatProperties2 :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	properties: SparseImageFormatProperties,
}

PhysicalDeviceSparseImageFormatInfo2 :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	format:  Format,
	type:    ImageType,
	samples: SampleCountFlags,
	usage:   ImageUsageFlags,
	tiling:  ImageTiling,
}

PhysicalDevicePointClippingProperties :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	pointClippingBehavior: PointClippingBehavior,
}

InputAttachmentAspectReference :: struct {
	subpass:              u32,
	inputAttachmentIndex: u32,
	aspectMask:           ImageAspectFlags,
}

RenderPassInputAttachmentAspectCreateInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	aspectReferenceCount: u32,
	pAspectReferences:    [^]InputAttachmentAspectReference,
}

ImageViewUsageCreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	usage: ImageUsageFlags,
}

PipelineTessellationDomainOriginStateCreateInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	domainOrigin: TessellationDomainOrigin,
}

RenderPassMultiviewCreateInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	subpassCount:         u32,
	pViewMasks:           [^]u32,
	dependencyCount:      u32,
	pViewOffsets:         [^]i32,
	correlationMaskCount: u32,
	pCorrelationMasks:    [^]u32,
}

PhysicalDeviceMultiviewFeatures :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	multiview:                   b32,
	multiviewGeometryShader:     b32,
	multiviewTessellationShader: b32,
}

PhysicalDeviceMultiviewProperties :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	maxMultiviewViewCount:     u32,
	maxMultiviewInstanceIndex: u32,
}

PhysicalDeviceVariablePointersFeatures :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	variablePointersStorageBuffer: b32,
	variablePointers:              b32,
}

PhysicalDeviceProtectedMemoryFeatures :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	protectedMemory: b32,
}

PhysicalDeviceProtectedMemoryProperties :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	protectedNoFault: b32,
}

DeviceQueueInfo2 :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            DeviceQueueCreateFlags,
	queueFamilyIndex: u32,
	queueIndex:       u32,
}

ProtectedSubmitInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	protectedSubmit: b32,
}

SamplerYcbcrConversionCreateInfo :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	format:                      Format,
	ycbcrModel:                  SamplerYcbcrModelConversion,
	ycbcrRange:                  SamplerYcbcrRange,
	components:                  ComponentMapping,
	xChromaOffset:               ChromaLocation,
	yChromaOffset:               ChromaLocation,
	chromaFilter:                Filter,
	forceExplicitReconstruction: b32,
}

SamplerYcbcrConversionInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	conversion: SamplerYcbcrConversion,
}

BindImagePlaneMemoryInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	planeAspect: ImageAspectFlags,
}

ImagePlaneMemoryRequirementsInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	planeAspect: ImageAspectFlags,
}

PhysicalDeviceSamplerYcbcrConversionFeatures :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	samplerYcbcrConversion: b32,
}

SamplerYcbcrConversionImageFormatProperties :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	combinedImageSamplerDescriptorCount: u32,
}

DescriptorUpdateTemplateEntry :: struct {
	dstBinding:      u32,
	dstArrayElement: u32,
	descriptorCount: u32,
	descriptorType:  DescriptorType,
	offset:          int,
	stride:          int,
}

DescriptorUpdateTemplateCreateInfo :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	flags:                      DescriptorUpdateTemplateCreateFlags,
	descriptorUpdateEntryCount: u32,
	pDescriptorUpdateEntries:   [^]DescriptorUpdateTemplateEntry,
	templateType:               DescriptorUpdateTemplateType,
	descriptorSetLayout:        DescriptorSetLayout,
	pipelineBindPoint:          PipelineBindPoint,
	pipelineLayout:             PipelineLayout,
	set:                        u32,
}

ExternalMemoryProperties :: struct {
	externalMemoryFeatures:        ExternalMemoryFeatureFlags,
	exportFromImportedHandleTypes: ExternalMemoryHandleTypeFlags,
	compatibleHandleTypes:         ExternalMemoryHandleTypeFlags,
}

PhysicalDeviceExternalImageFormatInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalMemoryHandleTypeFlags,
}

ExternalImageFormatProperties :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	externalMemoryProperties: ExternalMemoryProperties,
}

PhysicalDeviceExternalBufferInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	flags:      BufferCreateFlags,
	usage:      BufferUsageFlags,
	handleType: ExternalMemoryHandleTypeFlags,
}

ExternalBufferProperties :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	externalMemoryProperties: ExternalMemoryProperties,
}

PhysicalDeviceIDProperties :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	deviceUUID:      [UUID_SIZE]u8,
	driverUUID:      [UUID_SIZE]u8,
	deviceLUID:      [LUID_SIZE]u8,
	deviceNodeMask:  u32,
	deviceLUIDValid: b32,
}

ExternalMemoryImageCreateInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalMemoryHandleTypeFlags,
}

ExternalMemoryBufferCreateInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalMemoryHandleTypeFlags,
}

ExportMemoryAllocateInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalMemoryHandleTypeFlags,
}

PhysicalDeviceExternalFenceInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalFenceHandleTypeFlags,
}

ExternalFenceProperties :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	exportFromImportedHandleTypes: ExternalFenceHandleTypeFlags,
	compatibleHandleTypes:         ExternalFenceHandleTypeFlags,
	externalFenceFeatures:         ExternalFenceFeatureFlags,
}

ExportFenceCreateInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalFenceHandleTypeFlags,
}

ExportSemaphoreCreateInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalSemaphoreHandleTypeFlags,
}

PhysicalDeviceExternalSemaphoreInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalSemaphoreHandleTypeFlags,
}

ExternalSemaphoreProperties :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	exportFromImportedHandleTypes: ExternalSemaphoreHandleTypeFlags,
	compatibleHandleTypes:         ExternalSemaphoreHandleTypeFlags,
	externalSemaphoreFeatures:     ExternalSemaphoreFeatureFlags,
}

PhysicalDeviceMaintenance3Properties :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	maxPerSetDescriptors:    u32,
	maxMemoryAllocationSize: DeviceSize,
}

DescriptorSetLayoutSupport :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	supported: b32,
}

PhysicalDeviceShaderDrawParametersFeatures :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	shaderDrawParameters: b32,
}

PhysicalDeviceVulkan11Features :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	storageBuffer16BitAccess:           b32,
	uniformAndStorageBuffer16BitAccess: b32,
	storagePushConstant16:              b32,
	storageInputOutput16:               b32,
	multiview:                          b32,
	multiviewGeometryShader:            b32,
	multiviewTessellationShader:        b32,
	variablePointersStorageBuffer:      b32,
	variablePointers:                   b32,
	protectedMemory:                    b32,
	samplerYcbcrConversion:             b32,
	shaderDrawParameters:               b32,
}

PhysicalDeviceVulkan11Properties :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	deviceUUID:                        [UUID_SIZE]u8,
	driverUUID:                        [UUID_SIZE]u8,
	deviceLUID:                        [LUID_SIZE]u8,
	deviceNodeMask:                    u32,
	deviceLUIDValid:                   b32,
	subgroupSize:                      u32,
	subgroupSupportedStages:           ShaderStageFlags,
	subgroupSupportedOperations:       SubgroupFeatureFlags,
	subgroupQuadOperationsInAllStages: b32,
	pointClippingBehavior:             PointClippingBehavior,
	maxMultiviewViewCount:             u32,
	maxMultiviewInstanceIndex:         u32,
	protectedNoFault:                  b32,
	maxPerSetDescriptors:              u32,
	maxMemoryAllocationSize:           DeviceSize,
}

PhysicalDeviceVulkan12Features :: struct {
	sType:                                              StructureType,
	pNext:                                              rawptr,
	samplerMirrorClampToEdge:                           b32,
	drawIndirectCount:                                  b32,
	storageBuffer8BitAccess:                            b32,
	uniformAndStorageBuffer8BitAccess:                  b32,
	storagePushConstant8:                               b32,
	shaderBufferInt64Atomics:                           b32,
	shaderSharedInt64Atomics:                           b32,
	shaderFloat16:                                      b32,
	shaderInt8:                                         b32,
	descriptorIndexing:                                 b32,
	shaderInputAttachmentArrayDynamicIndexing:          b32,
	shaderUniformTexelBufferArrayDynamicIndexing:       b32,
	shaderStorageTexelBufferArrayDynamicIndexing:       b32,
	shaderUniformBufferArrayNonUniformIndexing:         b32,
	shaderSampledImageArrayNonUniformIndexing:          b32,
	shaderStorageBufferArrayNonUniformIndexing:         b32,
	shaderStorageImageArrayNonUniformIndexing:          b32,
	shaderInputAttachmentArrayNonUniformIndexing:       b32,
	shaderUniformTexelBufferArrayNonUniformIndexing:    b32,
	shaderStorageTexelBufferArrayNonUniformIndexing:    b32,
	descriptorBindingUniformBufferUpdateAfterBind:      b32,
	descriptorBindingSampledImageUpdateAfterBind:       b32,
	descriptorBindingStorageImageUpdateAfterBind:       b32,
	descriptorBindingStorageBufferUpdateAfterBind:      b32,
	descriptorBindingUniformTexelBufferUpdateAfterBind: b32,
	descriptorBindingStorageTexelBufferUpdateAfterBind: b32,
	descriptorBindingUpdateUnusedWhilePending:          b32,
	descriptorBindingPartiallyBound:                    b32,
	descriptorBindingVariableDescriptorCount:           b32,
	runtimeDescriptorArray:                             b32,
	samplerFilterMinmax:                                b32,
	scalarBlockLayout:                                  b32,
	imagelessFramebuffer:                               b32,
	uniformBufferStandardLayout:                        b32,
	shaderSubgroupExtendedTypes:                        b32,
	separateDepthStencilLayouts:                        b32,
	hostQueryReset:                                     b32,
	timelineSemaphore:                                  b32,
	bufferDeviceAddress:                                b32,
	bufferDeviceAddressCaptureReplay:                   b32,
	bufferDeviceAddressMultiDevice:                     b32,
	vulkanMemoryModel:                                  b32,
	vulkanMemoryModelDeviceScope:                       b32,
	vulkanMemoryModelAvailabilityVisibilityChains:      b32,
	shaderOutputViewportIndex:                          b32,
	shaderOutputLayer:                                  b32,
	subgroupBroadcastDynamicId:                         b32,
}

ConformanceVersion :: struct {
	major:    u8,
	minor:    u8,
	subminor: u8,
	patch:    u8,
}

PhysicalDeviceVulkan12Properties :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	driverID:                                             DriverId,
	driverName:                                           [MAX_DRIVER_NAME_SIZE]byte,
	driverInfo:                                           [MAX_DRIVER_INFO_SIZE]byte,
	conformanceVersion:                                   ConformanceVersion,
	denormBehaviorIndependence:                           ShaderFloatControlsIndependence,
	roundingModeIndependence:                             ShaderFloatControlsIndependence,
	shaderSignedZeroInfNanPreserveFloat16:                b32,
	shaderSignedZeroInfNanPreserveFloat32:                b32,
	shaderSignedZeroInfNanPreserveFloat64:                b32,
	shaderDenormPreserveFloat16:                          b32,
	shaderDenormPreserveFloat32:                          b32,
	shaderDenormPreserveFloat64:                          b32,
	shaderDenormFlushToZeroFloat16:                       b32,
	shaderDenormFlushToZeroFloat32:                       b32,
	shaderDenormFlushToZeroFloat64:                       b32,
	shaderRoundingModeRTEFloat16:                         b32,
	shaderRoundingModeRTEFloat32:                         b32,
	shaderRoundingModeRTEFloat64:                         b32,
	shaderRoundingModeRTZFloat16:                         b32,
	shaderRoundingModeRTZFloat32:                         b32,
	shaderRoundingModeRTZFloat64:                         b32,
	maxUpdateAfterBindDescriptorsInAllPools:              u32,
	shaderUniformBufferArrayNonUniformIndexingNative:     b32,
	shaderSampledImageArrayNonUniformIndexingNative:      b32,
	shaderStorageBufferArrayNonUniformIndexingNative:     b32,
	shaderStorageImageArrayNonUniformIndexingNative:      b32,
	shaderInputAttachmentArrayNonUniformIndexingNative:   b32,
	robustBufferAccessUpdateAfterBind:                    b32,
	quadDivergentImplicitLod:                             b32,
	maxPerStageDescriptorUpdateAfterBindSamplers:         u32,
	maxPerStageDescriptorUpdateAfterBindUniformBuffers:   u32,
	maxPerStageDescriptorUpdateAfterBindStorageBuffers:   u32,
	maxPerStageDescriptorUpdateAfterBindSampledImages:    u32,
	maxPerStageDescriptorUpdateAfterBindStorageImages:    u32,
	maxPerStageDescriptorUpdateAfterBindInputAttachments: u32,
	maxPerStageUpdateAfterBindResources:                  u32,
	maxDescriptorSetUpdateAfterBindSamplers:              u32,
	maxDescriptorSetUpdateAfterBindUniformBuffers:        u32,
	maxDescriptorSetUpdateAfterBindUniformBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindStorageBuffers:        u32,
	maxDescriptorSetUpdateAfterBindStorageBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindSampledImages:         u32,
	maxDescriptorSetUpdateAfterBindStorageImages:         u32,
	maxDescriptorSetUpdateAfterBindInputAttachments:      u32,
	supportedDepthResolveModes:                           ResolveModeFlags,
	supportedStencilResolveModes:                         ResolveModeFlags,
	independentResolveNone:                               b32,
	independentResolve:                                   b32,
	filterMinmaxSingleComponentFormats:                   b32,
	filterMinmaxImageComponentMapping:                    b32,
	maxTimelineSemaphoreValueDifference:                  u64,
	framebufferIntegerColorSampleCounts:                  SampleCountFlags,
}

ImageFormatListCreateInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	viewFormatCount: u32,
	pViewFormats:    [^]Format,
}

AttachmentDescription2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          AttachmentDescriptionFlags,
	format:         Format,
	samples:        SampleCountFlags,
	loadOp:         AttachmentLoadOp,
	storeOp:        AttachmentStoreOp,
	stencilLoadOp:  AttachmentLoadOp,
	stencilStoreOp: AttachmentStoreOp,
	initialLayout:  ImageLayout,
	finalLayout:    ImageLayout,
}

AttachmentReference2 :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	attachment: u32,
	layout:     ImageLayout,
	aspectMask: ImageAspectFlags,
}

SubpassDescription2 :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   SubpassDescriptionFlags,
	pipelineBindPoint:       PipelineBindPoint,
	viewMask:                u32,
	inputAttachmentCount:    u32,
	pInputAttachments:       [^]AttachmentReference2,
	colorAttachmentCount:    u32,
	pColorAttachments:       [^]AttachmentReference2,
	pResolveAttachments:     [^]AttachmentReference2,
	pDepthStencilAttachment: ^AttachmentReference2,
	preserveAttachmentCount: u32,
	pPreserveAttachments:    [^]u32,
}

SubpassDependency2 :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	srcSubpass:      u32,
	dstSubpass:      u32,
	srcStageMask:    PipelineStageFlags,
	dstStageMask:    PipelineStageFlags,
	srcAccessMask:   AccessFlags,
	dstAccessMask:   AccessFlags,
	dependencyFlags: DependencyFlags,
	viewOffset:      i32,
}

RenderPassCreateInfo2 :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   RenderPassCreateFlags,
	attachmentCount:         u32,
	pAttachments:            [^]AttachmentDescription2,
	subpassCount:            u32,
	pSubpasses:              [^]SubpassDescription2,
	dependencyCount:         u32,
	pDependencies:           [^]SubpassDependency2,
	correlatedViewMaskCount: u32,
	pCorrelatedViewMasks:    [^]u32,
}

SubpassBeginInfo :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	contents: SubpassContents,
}

SubpassEndInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
}

PhysicalDevice8BitStorageFeatures :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	storageBuffer8BitAccess:           b32,
	uniformAndStorageBuffer8BitAccess: b32,
	storagePushConstant8:              b32,
}

PhysicalDeviceDriverProperties :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	driverID:           DriverId,
	driverName:         [MAX_DRIVER_NAME_SIZE]byte,
	driverInfo:         [MAX_DRIVER_INFO_SIZE]byte,
	conformanceVersion: ConformanceVersion,
}

PhysicalDeviceShaderAtomicInt64Features :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	shaderBufferInt64Atomics: b32,
	shaderSharedInt64Atomics: b32,
}

PhysicalDeviceShaderFloat16Int8Features :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	shaderFloat16: b32,
	shaderInt8:    b32,
}

PhysicalDeviceFloatControlsProperties :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	denormBehaviorIndependence:            ShaderFloatControlsIndependence,
	roundingModeIndependence:              ShaderFloatControlsIndependence,
	shaderSignedZeroInfNanPreserveFloat16: b32,
	shaderSignedZeroInfNanPreserveFloat32: b32,
	shaderSignedZeroInfNanPreserveFloat64: b32,
	shaderDenormPreserveFloat16:           b32,
	shaderDenormPreserveFloat32:           b32,
	shaderDenormPreserveFloat64:           b32,
	shaderDenormFlushToZeroFloat16:        b32,
	shaderDenormFlushToZeroFloat32:        b32,
	shaderDenormFlushToZeroFloat64:        b32,
	shaderRoundingModeRTEFloat16:          b32,
	shaderRoundingModeRTEFloat32:          b32,
	shaderRoundingModeRTEFloat64:          b32,
	shaderRoundingModeRTZFloat16:          b32,
	shaderRoundingModeRTZFloat32:          b32,
	shaderRoundingModeRTZFloat64:          b32,
}

DescriptorSetLayoutBindingFlagsCreateInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	bindingCount:  u32,
	pBindingFlags: [^]DescriptorBindingFlags,
}

PhysicalDeviceDescriptorIndexingFeatures :: struct {
	sType:                                              StructureType,
	pNext:                                              rawptr,
	shaderInputAttachmentArrayDynamicIndexing:          b32,
	shaderUniformTexelBufferArrayDynamicIndexing:       b32,
	shaderStorageTexelBufferArrayDynamicIndexing:       b32,
	shaderUniformBufferArrayNonUniformIndexing:         b32,
	shaderSampledImageArrayNonUniformIndexing:          b32,
	shaderStorageBufferArrayNonUniformIndexing:         b32,
	shaderStorageImageArrayNonUniformIndexing:          b32,
	shaderInputAttachmentArrayNonUniformIndexing:       b32,
	shaderUniformTexelBufferArrayNonUniformIndexing:    b32,
	shaderStorageTexelBufferArrayNonUniformIndexing:    b32,
	descriptorBindingUniformBufferUpdateAfterBind:      b32,
	descriptorBindingSampledImageUpdateAfterBind:       b32,
	descriptorBindingStorageImageUpdateAfterBind:       b32,
	descriptorBindingStorageBufferUpdateAfterBind:      b32,
	descriptorBindingUniformTexelBufferUpdateAfterBind: b32,
	descriptorBindingStorageTexelBufferUpdateAfterBind: b32,
	descriptorBindingUpdateUnusedWhilePending:          b32,
	descriptorBindingPartiallyBound:                    b32,
	descriptorBindingVariableDescriptorCount:           b32,
	runtimeDescriptorArray:                             b32,
}

PhysicalDeviceDescriptorIndexingProperties :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	maxUpdateAfterBindDescriptorsInAllPools:              u32,
	shaderUniformBufferArrayNonUniformIndexingNative:     b32,
	shaderSampledImageArrayNonUniformIndexingNative:      b32,
	shaderStorageBufferArrayNonUniformIndexingNative:     b32,
	shaderStorageImageArrayNonUniformIndexingNative:      b32,
	shaderInputAttachmentArrayNonUniformIndexingNative:   b32,
	robustBufferAccessUpdateAfterBind:                    b32,
	quadDivergentImplicitLod:                             b32,
	maxPerStageDescriptorUpdateAfterBindSamplers:         u32,
	maxPerStageDescriptorUpdateAfterBindUniformBuffers:   u32,
	maxPerStageDescriptorUpdateAfterBindStorageBuffers:   u32,
	maxPerStageDescriptorUpdateAfterBindSampledImages:    u32,
	maxPerStageDescriptorUpdateAfterBindStorageImages:    u32,
	maxPerStageDescriptorUpdateAfterBindInputAttachments: u32,
	maxPerStageUpdateAfterBindResources:                  u32,
	maxDescriptorSetUpdateAfterBindSamplers:              u32,
	maxDescriptorSetUpdateAfterBindUniformBuffers:        u32,
	maxDescriptorSetUpdateAfterBindUniformBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindStorageBuffers:        u32,
	maxDescriptorSetUpdateAfterBindStorageBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindSampledImages:         u32,
	maxDescriptorSetUpdateAfterBindStorageImages:         u32,
	maxDescriptorSetUpdateAfterBindInputAttachments:      u32,
}

DescriptorSetVariableDescriptorCountAllocateInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	descriptorSetCount: u32,
	pDescriptorCounts:  [^]u32,
}

DescriptorSetVariableDescriptorCountLayoutSupport :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	maxVariableDescriptorCount: u32,
}

SubpassDescriptionDepthStencilResolve :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	depthResolveMode:               ResolveModeFlags,
	stencilResolveMode:             ResolveModeFlags,
	pDepthStencilResolveAttachment: ^AttachmentReference2,
}

PhysicalDeviceDepthStencilResolveProperties :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	supportedDepthResolveModes:   ResolveModeFlags,
	supportedStencilResolveModes: ResolveModeFlags,
	independentResolveNone:       b32,
	independentResolve:           b32,
}

PhysicalDeviceScalarBlockLayoutFeatures :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	scalarBlockLayout: b32,
}

ImageStencilUsageCreateInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	stencilUsage: ImageUsageFlags,
}

SamplerReductionModeCreateInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	reductionMode: SamplerReductionMode,
}

PhysicalDeviceSamplerFilterMinmaxProperties :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	filterMinmaxSingleComponentFormats: b32,
	filterMinmaxImageComponentMapping:  b32,
}

PhysicalDeviceVulkanMemoryModelFeatures :: struct {
	sType:                                         StructureType,
	pNext:                                         rawptr,
	vulkanMemoryModel:                             b32,
	vulkanMemoryModelDeviceScope:                  b32,
	vulkanMemoryModelAvailabilityVisibilityChains: b32,
}

PhysicalDeviceImagelessFramebufferFeatures :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	imagelessFramebuffer: b32,
}

FramebufferAttachmentImageInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           ImageCreateFlags,
	usage:           ImageUsageFlags,
	width:           u32,
	height:          u32,
	layerCount:      u32,
	viewFormatCount: u32,
	pViewFormats:    [^]Format,
}

FramebufferAttachmentsCreateInfo :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	attachmentImageInfoCount: u32,
	pAttachmentImageInfos:    [^]FramebufferAttachmentImageInfo,
}

RenderPassAttachmentBeginInfo :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	attachmentCount: u32,
	pAttachments:    [^]ImageView,
}

PhysicalDeviceUniformBufferStandardLayoutFeatures :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	uniformBufferStandardLayout: b32,
}

PhysicalDeviceShaderSubgroupExtendedTypesFeatures :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	shaderSubgroupExtendedTypes: b32,
}

PhysicalDeviceSeparateDepthStencilLayoutsFeatures :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	separateDepthStencilLayouts: b32,
}

AttachmentReferenceStencilLayout :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	stencilLayout: ImageLayout,
}

AttachmentDescriptionStencilLayout :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	stencilInitialLayout: ImageLayout,
	stencilFinalLayout:   ImageLayout,
}

PhysicalDeviceHostQueryResetFeatures :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	hostQueryReset: b32,
}

PhysicalDeviceTimelineSemaphoreFeatures :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	timelineSemaphore: b32,
}

PhysicalDeviceTimelineSemaphoreProperties :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	maxTimelineSemaphoreValueDifference: u64,
}

SemaphoreTypeCreateInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	semaphoreType: SemaphoreType,
	initialValue:  u64,
}

TimelineSemaphoreSubmitInfo :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	waitSemaphoreValueCount:   u32,
	pWaitSemaphoreValues:      [^]u64,
	signalSemaphoreValueCount: u32,
	pSignalSemaphoreValues:    [^]u64,
}

SemaphoreWaitInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          SemaphoreWaitFlags,
	semaphoreCount: u32,
	pSemaphores:    [^]Semaphore,
	pValues:        [^]u64,
}

SemaphoreSignalInfo :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	semaphore: Semaphore,
	value:     u64,
}

PhysicalDeviceBufferDeviceAddressFeatures :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	bufferDeviceAddress:              b32,
	bufferDeviceAddressCaptureReplay: b32,
	bufferDeviceAddressMultiDevice:   b32,
}

BufferDeviceAddressInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	buffer: Buffer,
}

BufferOpaqueCaptureAddressCreateInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	opaqueCaptureAddress: u64,
}

MemoryOpaqueCaptureAddressAllocateInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	opaqueCaptureAddress: u64,
}

DeviceMemoryOpaqueCaptureAddressInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	memory: DeviceMemory,
}

PhysicalDeviceVulkan13Features :: struct {
	sType:                                              StructureType,
	pNext:                                              rawptr,
	robustImageAccess:                                  b32,
	inlineUniformBlock:                                 b32,
	descriptorBindingInlineUniformBlockUpdateAfterBind: b32,
	pipelineCreationCacheControl:                       b32,
	privateData:                                        b32,
	shaderDemoteToHelperInvocation:                     b32,
	shaderTerminateInvocation:                          b32,
	subgroupSizeControl:                                b32,
	computeFullSubgroups:                               b32,
	synchronization2:                                   b32,
	textureCompressionASTC_HDR:                         b32,
	shaderZeroInitializeWorkgroupMemory:                b32,
	dynamicRendering:                                   b32,
	shaderIntegerDotProduct:                            b32,
	maintenance4:                                       b32,
}

PhysicalDeviceVulkan13Properties :: struct {
	sType:                                                                         StructureType,
	pNext:                                                                         rawptr,
	minSubgroupSize:                                                               u32,
	maxSubgroupSize:                                                               u32,
	maxComputeWorkgroupSubgroups:                                                  u32,
	requiredSubgroupSizeStages:                                                    ShaderStageFlags,
	maxInlineUniformBlockSize:                                                     u32,
	maxPerStageDescriptorInlineUniformBlocks:                                      u32,
	maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks:                       u32,
	maxDescriptorSetInlineUniformBlocks:                                           u32,
	maxDescriptorSetUpdateAfterBindInlineUniformBlocks:                            u32,
	maxInlineUniformTotalSize:                                                     u32,
	integerDotProduct8BitUnsignedAccelerated:                                      b32,
	integerDotProduct8BitSignedAccelerated:                                        b32,
	integerDotProduct8BitMixedSignednessAccelerated:                               b32,
	integerDotProduct4x8BitPackedUnsignedAccelerated:                              b32,
	integerDotProduct4x8BitPackedSignedAccelerated:                                b32,
	integerDotProduct4x8BitPackedMixedSignednessAccelerated:                       b32,
	integerDotProduct16BitUnsignedAccelerated:                                     b32,
	integerDotProduct16BitSignedAccelerated:                                       b32,
	integerDotProduct16BitMixedSignednessAccelerated:                              b32,
	integerDotProduct32BitUnsignedAccelerated:                                     b32,
	integerDotProduct32BitSignedAccelerated:                                       b32,
	integerDotProduct32BitMixedSignednessAccelerated:                              b32,
	integerDotProduct64BitUnsignedAccelerated:                                     b32,
	integerDotProduct64BitSignedAccelerated:                                       b32,
	integerDotProduct64BitMixedSignednessAccelerated:                              b32,
	integerDotProductAccumulatingSaturating8BitUnsignedAccelerated:                b32,
	integerDotProductAccumulatingSaturating8BitSignedAccelerated:                  b32,
	integerDotProductAccumulatingSaturating8BitMixedSignednessAccelerated:         b32,
	integerDotProductAccumulatingSaturating4x8BitPackedUnsignedAccelerated:        b32,
	integerDotProductAccumulatingSaturating4x8BitPackedSignedAccelerated:          b32,
	integerDotProductAccumulatingSaturating4x8BitPackedMixedSignednessAccelerated: b32,
	integerDotProductAccumulatingSaturating16BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating16BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating16BitMixedSignednessAccelerated:        b32,
	integerDotProductAccumulatingSaturating32BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating32BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating32BitMixedSignednessAccelerated:        b32,
	integerDotProductAccumulatingSaturating64BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating64BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating64BitMixedSignednessAccelerated:        b32,
	storageTexelBufferOffsetAlignmentBytes:                                        DeviceSize,
	storageTexelBufferOffsetSingleTexelAlignment:                                  b32,
	uniformTexelBufferOffsetAlignmentBytes:                                        DeviceSize,
	uniformTexelBufferOffsetSingleTexelAlignment:                                  b32,
	maxBufferSize:                                                                 DeviceSize,
}

PipelineCreationFeedback :: struct {
	flags:    PipelineCreationFeedbackFlags,
	duration: u64,
}

PipelineCreationFeedbackCreateInfo :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	pPipelineCreationFeedback:          ^PipelineCreationFeedback,
	pipelineStageCreationFeedbackCount: u32,
	pPipelineStageCreationFeedbacks:    [^]PipelineCreationFeedback,
}

PhysicalDeviceShaderTerminateInvocationFeatures :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	shaderTerminateInvocation: b32,
}

PhysicalDeviceToolProperties :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	name:        [MAX_EXTENSION_NAME_SIZE]byte,
	version:     [MAX_EXTENSION_NAME_SIZE]byte,
	purposes:    ToolPurposeFlags,
	description: [MAX_DESCRIPTION_SIZE]byte,
	layer:       [MAX_EXTENSION_NAME_SIZE]byte,
}

PhysicalDeviceShaderDemoteToHelperInvocationFeatures :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	shaderDemoteToHelperInvocation: b32,
}

PhysicalDevicePrivateDataFeatures :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	privateData: b32,
}

DevicePrivateDataCreateInfo :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	privateDataSlotRequestCount: u32,
}

PrivateDataSlotCreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: PrivateDataSlotCreateFlags,
}

PhysicalDevicePipelineCreationCacheControlFeatures :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	pipelineCreationCacheControl: b32,
}

MemoryBarrier2 :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	srcStageMask:  PipelineStageFlags2,
	srcAccessMask: AccessFlags2,
	dstStageMask:  PipelineStageFlags2,
	dstAccessMask: AccessFlags2,
}

BufferMemoryBarrier2 :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcStageMask:        PipelineStageFlags2,
	srcAccessMask:       AccessFlags2,
	dstStageMask:        PipelineStageFlags2,
	dstAccessMask:       AccessFlags2,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	buffer:              Buffer,
	offset:              DeviceSize,
	size:                DeviceSize,
}

ImageMemoryBarrier2 :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcStageMask:        PipelineStageFlags2,
	srcAccessMask:       AccessFlags2,
	dstStageMask:        PipelineStageFlags2,
	dstAccessMask:       AccessFlags2,
	oldLayout:           ImageLayout,
	newLayout:           ImageLayout,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	image:               Image,
	subresourceRange:    ImageSubresourceRange,
}

DependencyInfo :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	dependencyFlags:          DependencyFlags,
	memoryBarrierCount:       u32,
	pMemoryBarriers:          [^]MemoryBarrier2,
	bufferMemoryBarrierCount: u32,
	pBufferMemoryBarriers:    [^]BufferMemoryBarrier2,
	imageMemoryBarrierCount:  u32,
	pImageMemoryBarriers:     [^]ImageMemoryBarrier2,
}

SemaphoreSubmitInfo :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	semaphore:   Semaphore,
	value:       u64,
	stageMask:   PipelineStageFlags2,
	deviceIndex: u32,
}

CommandBufferSubmitInfo :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	commandBuffer: CommandBuffer,
	deviceMask:    u32,
}

SubmitInfo2 :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	flags:                    SubmitFlags,
	waitSemaphoreInfoCount:   u32,
	pWaitSemaphoreInfos:      [^]SemaphoreSubmitInfo,
	commandBufferInfoCount:   u32,
	pCommandBufferInfos:      [^]CommandBufferSubmitInfo,
	signalSemaphoreInfoCount: u32,
	pSignalSemaphoreInfos:    [^]SemaphoreSubmitInfo,
}

PhysicalDeviceSynchronization2Features :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	synchronization2: b32,
}

PhysicalDeviceZeroInitializeWorkgroupMemoryFeatures :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	shaderZeroInitializeWorkgroupMemory: b32,
}

PhysicalDeviceImageRobustnessFeatures :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	robustImageAccess: b32,
}

BufferCopy2 :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	srcOffset: DeviceSize,
	dstOffset: DeviceSize,
	size:      DeviceSize,
}

CopyBufferInfo2 :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	srcBuffer:   Buffer,
	dstBuffer:   Buffer,
	regionCount: u32,
	pRegions:    [^]BufferCopy2,
}

ImageCopy2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

CopyImageInfo2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageCopy2,
}

BufferImageCopy2 :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	bufferOffset:      DeviceSize,
	bufferRowLength:   u32,
	bufferImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

CopyBufferToImageInfo2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcBuffer:      Buffer,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]BufferImageCopy2,
}

CopyImageToBufferInfo2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstBuffer:      Buffer,
	regionCount:    u32,
	pRegions:       [^]BufferImageCopy2,
}

ImageBlit2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffsets:     [2]Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffsets:     [2]Offset3D,
}

BlitImageInfo2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageBlit2,
	filter:         Filter,
}

ImageResolve2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

ResolveImageInfo2 :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageResolve2,
}

PhysicalDeviceSubgroupSizeControlFeatures :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	subgroupSizeControl:  b32,
	computeFullSubgroups: b32,
}

PhysicalDeviceSubgroupSizeControlProperties :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	minSubgroupSize:              u32,
	maxSubgroupSize:              u32,
	maxComputeWorkgroupSubgroups: u32,
	requiredSubgroupSizeStages:   ShaderStageFlags,
}

PipelineShaderStageRequiredSubgroupSizeCreateInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	requiredSubgroupSize: u32,
}

PhysicalDeviceInlineUniformBlockFeatures :: struct {
	sType:                                              StructureType,
	pNext:                                              rawptr,
	inlineUniformBlock:                                 b32,
	descriptorBindingInlineUniformBlockUpdateAfterBind: b32,
}

PhysicalDeviceInlineUniformBlockProperties :: struct {
	sType:                                                   StructureType,
	pNext:                                                   rawptr,
	maxInlineUniformBlockSize:                               u32,
	maxPerStageDescriptorInlineUniformBlocks:                u32,
	maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks: u32,
	maxDescriptorSetInlineUniformBlocks:                     u32,
	maxDescriptorSetUpdateAfterBindInlineUniformBlocks:      u32,
}

WriteDescriptorSetInlineUniformBlock :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	dataSize: u32,
	pData:    rawptr,
}

DescriptorPoolInlineUniformBlockCreateInfo :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	maxInlineUniformBlockBindings: u32,
}

PhysicalDeviceTextureCompressionASTCHDRFeatures :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	textureCompressionASTC_HDR: b32,
}

RenderingAttachmentInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	imageView:          ImageView,
	imageLayout:        ImageLayout,
	resolveMode:        ResolveModeFlags,
	resolveImageView:   ImageView,
	resolveImageLayout: ImageLayout,
	loadOp:             AttachmentLoadOp,
	storeOp:            AttachmentStoreOp,
	clearValue:         ClearValue,
}

RenderingInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	flags:                RenderingFlags,
	renderArea:           Rect2D,
	layerCount:           u32,
	viewMask:             u32,
	colorAttachmentCount: u32,
	pColorAttachments:    [^]RenderingAttachmentInfo,
	pDepthAttachment:     ^RenderingAttachmentInfo,
	pStencilAttachment:   ^RenderingAttachmentInfo,
}

PipelineRenderingCreateInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	viewMask:                u32,
	colorAttachmentCount:    u32,
	pColorAttachmentFormats: [^]Format,
	depthAttachmentFormat:   Format,
	stencilAttachmentFormat: Format,
}

PhysicalDeviceDynamicRenderingFeatures :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	dynamicRendering: b32,
}

CommandBufferInheritanceRenderingInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   RenderingFlags,
	viewMask:                u32,
	colorAttachmentCount:    u32,
	pColorAttachmentFormats: [^]Format,
	depthAttachmentFormat:   Format,
	stencilAttachmentFormat: Format,
	rasterizationSamples:    SampleCountFlags,
}

PhysicalDeviceShaderIntegerDotProductFeatures :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	shaderIntegerDotProduct: b32,
}

PhysicalDeviceShaderIntegerDotProductProperties :: struct {
	sType:                                                                         StructureType,
	pNext:                                                                         rawptr,
	integerDotProduct8BitUnsignedAccelerated:                                      b32,
	integerDotProduct8BitSignedAccelerated:                                        b32,
	integerDotProduct8BitMixedSignednessAccelerated:                               b32,
	integerDotProduct4x8BitPackedUnsignedAccelerated:                              b32,
	integerDotProduct4x8BitPackedSignedAccelerated:                                b32,
	integerDotProduct4x8BitPackedMixedSignednessAccelerated:                       b32,
	integerDotProduct16BitUnsignedAccelerated:                                     b32,
	integerDotProduct16BitSignedAccelerated:                                       b32,
	integerDotProduct16BitMixedSignednessAccelerated:                              b32,
	integerDotProduct32BitUnsignedAccelerated:                                     b32,
	integerDotProduct32BitSignedAccelerated:                                       b32,
	integerDotProduct32BitMixedSignednessAccelerated:                              b32,
	integerDotProduct64BitUnsignedAccelerated:                                     b32,
	integerDotProduct64BitSignedAccelerated:                                       b32,
	integerDotProduct64BitMixedSignednessAccelerated:                              b32,
	integerDotProductAccumulatingSaturating8BitUnsignedAccelerated:                b32,
	integerDotProductAccumulatingSaturating8BitSignedAccelerated:                  b32,
	integerDotProductAccumulatingSaturating8BitMixedSignednessAccelerated:         b32,
	integerDotProductAccumulatingSaturating4x8BitPackedUnsignedAccelerated:        b32,
	integerDotProductAccumulatingSaturating4x8BitPackedSignedAccelerated:          b32,
	integerDotProductAccumulatingSaturating4x8BitPackedMixedSignednessAccelerated: b32,
	integerDotProductAccumulatingSaturating16BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating16BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating16BitMixedSignednessAccelerated:        b32,
	integerDotProductAccumulatingSaturating32BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating32BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating32BitMixedSignednessAccelerated:        b32,
	integerDotProductAccumulatingSaturating64BitUnsignedAccelerated:               b32,
	integerDotProductAccumulatingSaturating64BitSignedAccelerated:                 b32,
	integerDotProductAccumulatingSaturating64BitMixedSignednessAccelerated:        b32,
}

PhysicalDeviceTexelBufferAlignmentProperties :: struct {
	sType:                                        StructureType,
	pNext:                                        rawptr,
	storageTexelBufferOffsetAlignmentBytes:       DeviceSize,
	storageTexelBufferOffsetSingleTexelAlignment: b32,
	uniformTexelBufferOffsetAlignmentBytes:       DeviceSize,
	uniformTexelBufferOffsetSingleTexelAlignment: b32,
}

FormatProperties3 :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	linearTilingFeatures:  FormatFeatureFlags2,
	optimalTilingFeatures: FormatFeatureFlags2,
	bufferFeatures:        FormatFeatureFlags2,
}

PhysicalDeviceMaintenance4Features :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	maintenance4: b32,
}

PhysicalDeviceMaintenance4Properties :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	maxBufferSize: DeviceSize,
}

DeviceBufferMemoryRequirements :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pCreateInfo: ^BufferCreateInfo,
}

DeviceImageMemoryRequirements :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pCreateInfo: ^ImageCreateInfo,
	planeAspect: ImageAspectFlags,
}

PhysicalDeviceVulkan14Features :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	globalPriorityQuery:                    b32,
	shaderSubgroupRotate:                   b32,
	shaderSubgroupRotateClustered:          b32,
	shaderFloatControls2:                   b32,
	shaderExpectAssume:                     b32,
	rectangularLines:                       b32,
	bresenhamLines:                         b32,
	smoothLines:                            b32,
	stippledRectangularLines:               b32,
	stippledBresenhamLines:                 b32,
	stippledSmoothLines:                    b32,
	vertexAttributeInstanceRateDivisor:     b32,
	vertexAttributeInstanceRateZeroDivisor: b32,
	indexTypeUint8:                         b32,
	dynamicRenderingLocalRead:              b32,
	maintenance5:                           b32,
	maintenance6:                           b32,
	pipelineProtectedAccess:                b32,
	pipelineRobustness:                     b32,
	hostImageCopy:                          b32,
	pushDescriptor:                         b32,
}

PhysicalDeviceVulkan14Properties :: struct {
	sType:                                               StructureType,
	pNext:                                               rawptr,
	lineSubPixelPrecisionBits:                           u32,
	maxVertexAttribDivisor:                              u32,
	supportsNonZeroFirstInstance:                        b32,
	maxPushDescriptors:                                  u32,
	dynamicRenderingLocalReadDepthStencilAttachments:    b32,
	dynamicRenderingLocalReadMultisampledAttachments:    b32,
	earlyFragmentMultisampleCoverageAfterSampleCounting: b32,
	earlyFragmentSampleMaskTestBeforeSampleCounting:     b32,
	depthStencilSwizzleOneSupport:                       b32,
	polygonModePointSize:                                b32,
	nonStrictSinglePixelWideLinesUseParallelogram:       b32,
	nonStrictWideLinesUseParallelogram:                  b32,
	blockTexelViewCompatibleMultipleLayers:              b32,
	maxCombinedImageSamplerDescriptorCount:              u32,
	fragmentShadingRateClampCombinerInputs:              b32,
	defaultRobustnessStorageBuffers:                     PipelineRobustnessBufferBehavior,
	defaultRobustnessUniformBuffers:                     PipelineRobustnessBufferBehavior,
	defaultRobustnessVertexInputs:                       PipelineRobustnessBufferBehavior,
	defaultRobustnessImages:                             PipelineRobustnessImageBehavior,
	copySrcLayoutCount:                                  u32,
	pCopySrcLayouts:                                     [^]ImageLayout,
	copyDstLayoutCount:                                  u32,
	pCopyDstLayouts:                                     [^]ImageLayout,
	optimalTilingLayoutUUID:                             [UUID_SIZE]u8,
	identicalMemoryTypeRequirements:                     b32,
}

DeviceQueueGlobalPriorityCreateInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	globalPriority: QueueGlobalPriority,
}

PhysicalDeviceGlobalPriorityQueryFeatures :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	globalPriorityQuery: b32,
}

QueueFamilyGlobalPriorityProperties :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	priorityCount: u32,
	priorities:    [MAX_GLOBAL_PRIORITY_SIZE]QueueGlobalPriority,
}

PhysicalDeviceShaderSubgroupRotateFeatures :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	shaderSubgroupRotate:          b32,
	shaderSubgroupRotateClustered: b32,
}

PhysicalDeviceShaderFloatControls2Features :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	shaderFloatControls2: b32,
}

PhysicalDeviceShaderExpectAssumeFeatures :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	shaderExpectAssume: b32,
}

PhysicalDeviceLineRasterizationFeatures :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	rectangularLines:         b32,
	bresenhamLines:           b32,
	smoothLines:              b32,
	stippledRectangularLines: b32,
	stippledBresenhamLines:   b32,
	stippledSmoothLines:      b32,
}

PhysicalDeviceLineRasterizationProperties :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	lineSubPixelPrecisionBits: u32,
}

PipelineRasterizationLineStateCreateInfo :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	lineRasterizationMode: LineRasterizationMode,
	stippledLineEnable:    b32,
	lineStippleFactor:     u32,
	lineStipplePattern:    u16,
}

PhysicalDeviceVertexAttributeDivisorProperties :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	maxVertexAttribDivisor:       u32,
	supportsNonZeroFirstInstance: b32,
}

VertexInputBindingDivisorDescription :: struct {
	binding: u32,
	divisor: u32,
}

PipelineVertexInputDivisorStateCreateInfo :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	vertexBindingDivisorCount: u32,
	pVertexBindingDivisors:    [^]VertexInputBindingDivisorDescription,
}

PhysicalDeviceVertexAttributeDivisorFeatures :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	vertexAttributeInstanceRateDivisor:     b32,
	vertexAttributeInstanceRateZeroDivisor: b32,
}

PhysicalDeviceIndexTypeUint8Features :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	indexTypeUint8: b32,
}

MemoryMapInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	flags:  MemoryMapFlags,
	memory: DeviceMemory,
	offset: DeviceSize,
	size:   DeviceSize,
}

MemoryUnmapInfo :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	flags:  MemoryUnmapFlags,
	memory: DeviceMemory,
}

PhysicalDeviceMaintenance5Features :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	maintenance5: b32,
}

PhysicalDeviceMaintenance5Properties :: struct {
	sType:                                               StructureType,
	pNext:                                               rawptr,
	earlyFragmentMultisampleCoverageAfterSampleCounting: b32,
	earlyFragmentSampleMaskTestBeforeSampleCounting:     b32,
	depthStencilSwizzleOneSupport:                       b32,
	polygonModePointSize:                                b32,
	nonStrictSinglePixelWideLinesUseParallelogram:       b32,
	nonStrictWideLinesUseParallelogram:                  b32,
}

RenderingAreaInfo :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	viewMask:                u32,
	colorAttachmentCount:    u32,
	pColorAttachmentFormats: [^]Format,
	depthAttachmentFormat:   Format,
	stencilAttachmentFormat: Format,
}

ImageSubresource2 :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	imageSubresource: ImageSubresource,
}

DeviceImageSubresourceInfo :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	pCreateInfo:  ^ImageCreateInfo,
	pSubresource: ^ImageSubresource2,
}

SubresourceLayout2 :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	subresourceLayout: SubresourceLayout,
}

PipelineCreateFlags2CreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: PipelineCreateFlags2,
}

BufferUsageFlags2CreateInfo :: struct {
	sType: StructureType,
	pNext: rawptr,
	usage: BufferUsageFlags2,
}

PhysicalDevicePushDescriptorProperties :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxPushDescriptors: u32,
}

PhysicalDeviceDynamicRenderingLocalReadFeatures :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	dynamicRenderingLocalRead: b32,
}

RenderingAttachmentLocationInfo :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	colorAttachmentCount:      u32,
	pColorAttachmentLocations: [^]u32,
}

RenderingInputAttachmentIndexInfo :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	colorAttachmentCount:         u32,
	pColorAttachmentInputIndices: [^]u32,
	pDepthInputAttachmentIndex:   ^u32,
	pStencilInputAttachmentIndex: ^u32,
}

PhysicalDeviceMaintenance6Features :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	maintenance6: b32,
}

PhysicalDeviceMaintenance6Properties :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	blockTexelViewCompatibleMultipleLayers: b32,
	maxCombinedImageSamplerDescriptorCount: u32,
	fragmentShadingRateClampCombinerInputs: b32,
}

BindMemoryStatus :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	pResult: ^Result,
}

BindDescriptorSetsInfo :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	stageFlags:         ShaderStageFlags,
	layout:             PipelineLayout,
	firstSet:           u32,
	descriptorSetCount: u32,
	pDescriptorSets:    [^]DescriptorSet,
	dynamicOffsetCount: u32,
	pDynamicOffsets:    [^]u32,
}

PushConstantsInfo :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	layout:     PipelineLayout,
	stageFlags: ShaderStageFlags,
	offset:     u32,
	size:       u32,
	pValues:    rawptr,
}

PushDescriptorSetInfo :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	stageFlags:           ShaderStageFlags,
	layout:               PipelineLayout,
	set:                  u32,
	descriptorWriteCount: u32,
	pDescriptorWrites:    [^]WriteDescriptorSet,
}

PushDescriptorSetWithTemplateInfo :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	descriptorUpdateTemplate: DescriptorUpdateTemplate,
	layout:                   PipelineLayout,
	set:                      u32,
	pData:                    rawptr,
}

PhysicalDevicePipelineProtectedAccessFeatures :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	pipelineProtectedAccess: b32,
}

PhysicalDevicePipelineRobustnessFeatures :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	pipelineRobustness: b32,
}

PhysicalDevicePipelineRobustnessProperties :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	defaultRobustnessStorageBuffers: PipelineRobustnessBufferBehavior,
	defaultRobustnessUniformBuffers: PipelineRobustnessBufferBehavior,
	defaultRobustnessVertexInputs:   PipelineRobustnessBufferBehavior,
	defaultRobustnessImages:         PipelineRobustnessImageBehavior,
}

PipelineRobustnessCreateInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	storageBuffers: PipelineRobustnessBufferBehavior,
	uniformBuffers: PipelineRobustnessBufferBehavior,
	vertexInputs:   PipelineRobustnessBufferBehavior,
	images:         PipelineRobustnessImageBehavior,
}

PhysicalDeviceHostImageCopyFeatures :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	hostImageCopy: b32,
}

PhysicalDeviceHostImageCopyProperties :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	copySrcLayoutCount:              u32,
	pCopySrcLayouts:                 [^]ImageLayout,
	copyDstLayoutCount:              u32,
	pCopyDstLayouts:                 [^]ImageLayout,
	optimalTilingLayoutUUID:         [UUID_SIZE]u8,
	identicalMemoryTypeRequirements: b32,
}

MemoryToImageCopy :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pHostPointer:      rawptr,
	memoryRowLength:   u32,
	memoryImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

ImageToMemoryCopy :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pHostPointer:      rawptr,
	memoryRowLength:   u32,
	memoryImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

CopyMemoryToImageInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          HostImageCopyFlags,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]MemoryToImageCopy,
}

CopyImageToMemoryInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          HostImageCopyFlags,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageToMemoryCopy,
}

CopyImageToImageInfo :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          HostImageCopyFlags,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageCopy2,
}

HostImageLayoutTransitionInfo :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	image:            Image,
	oldLayout:        ImageLayout,
	newLayout:        ImageLayout,
	subresourceRange: ImageSubresourceRange,
}

SubresourceHostMemcpySize :: struct {
	sType: StructureType,
	pNext: rawptr,
	size:  DeviceSize,
}

HostImageCopyDevicePerformanceQuery :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	optimalDeviceAccess:   b32,
	identicalMemoryLayout: b32,
}

SurfaceCapabilitiesKHR :: struct {
	minImageCount:           u32,
	maxImageCount:           u32,
	currentExtent:           Extent2D,
	minImageExtent:          Extent2D,
	maxImageExtent:          Extent2D,
	maxImageArrayLayers:     u32,
	supportedTransforms:     SurfaceTransformFlagsKHR,
	currentTransform:        SurfaceTransformFlagsKHR,
	supportedCompositeAlpha: CompositeAlphaFlagsKHR,
	supportedUsageFlags:     ImageUsageFlags,
}

SurfaceFormatKHR :: struct {
	format:     Format,
	colorSpace: ColorSpaceKHR,
}

SwapchainCreateInfoKHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 SwapchainCreateFlagsKHR,
	surface:               SurfaceKHR,
	minImageCount:         u32,
	imageFormat:           Format,
	imageColorSpace:       ColorSpaceKHR,
	imageExtent:           Extent2D,
	imageArrayLayers:      u32,
	imageUsage:            ImageUsageFlags,
	imageSharingMode:      SharingMode,
	queueFamilyIndexCount: u32,
	pQueueFamilyIndices:   [^]u32,
	preTransform:          SurfaceTransformFlagsKHR,
	compositeAlpha:        CompositeAlphaFlagsKHR,
	presentMode:           PresentModeKHR,
	clipped:               b32,
	oldSwapchain:          SwapchainKHR,
}

PresentInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	waitSemaphoreCount: u32,
	pWaitSemaphores:    [^]Semaphore,
	swapchainCount:     u32,
	pSwapchains:        [^]SwapchainKHR,
	pImageIndices:      [^]u32,
	pResults:           [^]Result,
}

ImageSwapchainCreateInfoKHR :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	swapchain: SwapchainKHR,
}

BindImageMemorySwapchainInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	swapchain:  SwapchainKHR,
	imageIndex: u32,
}

AcquireNextImageInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	swapchain:  SwapchainKHR,
	timeout:    u64,
	semaphore:  Semaphore,
	fence:      Fence,
	deviceMask: u32,
}

DeviceGroupPresentCapabilitiesKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	presentMask: [MAX_DEVICE_GROUP_SIZE]u32,
	modes:       DeviceGroupPresentModeFlagsKHR,
}

DeviceGroupPresentInfoKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pDeviceMasks:   [^]u32,
	mode:           DeviceGroupPresentModeFlagsKHR,
}

DeviceGroupSwapchainCreateInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	modes: DeviceGroupPresentModeFlagsKHR,
}

DisplayModeParametersKHR :: struct {
	visibleRegion: Extent2D,
	refreshRate:   u32,
}

DisplayModeCreateInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	flags:      DisplayModeCreateFlagsKHR,
	parameters: DisplayModeParametersKHR,
}

DisplayModePropertiesKHR :: struct {
	displayMode: DisplayModeKHR,
	parameters:  DisplayModeParametersKHR,
}

DisplayPlaneCapabilitiesKHR :: struct {
	supportedAlpha: DisplayPlaneAlphaFlagsKHR,
	minSrcPosition: Offset2D,
	maxSrcPosition: Offset2D,
	minSrcExtent:   Extent2D,
	maxSrcExtent:   Extent2D,
	minDstPosition: Offset2D,
	maxDstPosition: Offset2D,
	minDstExtent:   Extent2D,
	maxDstExtent:   Extent2D,
}

DisplayPlanePropertiesKHR :: struct {
	currentDisplay:    DisplayKHR,
	currentStackIndex: u32,
}

DisplayPropertiesKHR :: struct {
	display:              DisplayKHR,
	displayName:          cstring,
	physicalDimensions:   Extent2D,
	physicalResolution:   Extent2D,
	supportedTransforms:  SurfaceTransformFlagsKHR,
	planeReorderPossible: b32,
	persistentContent:    b32,
}

DisplaySurfaceCreateInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           DisplaySurfaceCreateFlagsKHR,
	displayMode:     DisplayModeKHR,
	planeIndex:      u32,
	planeStackIndex: u32,
	transform:       SurfaceTransformFlagsKHR,
	globalAlpha:     f32,
	alphaMode:       DisplayPlaneAlphaFlagsKHR,
	imageExtent:     Extent2D,
}

DisplayPresentInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	srcRect:    Rect2D,
	dstRect:    Rect2D,
	persistent: b32,
}

QueueFamilyQueryResultStatusPropertiesKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	queryResultStatusSupport: b32,
}

QueueFamilyVideoPropertiesKHR :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	videoCodecOperations: VideoCodecOperationFlagsKHR,
}

VideoProfileInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	videoCodecOperation: VideoCodecOperationFlagsKHR,
	chromaSubsampling:   VideoChromaSubsamplingFlagsKHR,
	lumaBitDepth:        VideoComponentBitDepthFlagsKHR,
	chromaBitDepth:      VideoComponentBitDepthFlagsKHR,
}

VideoProfileListInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	profileCount: u32,
	pProfiles:    [^]VideoProfileInfoKHR,
}

VideoCapabilitiesKHR :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	flags:                             VideoCapabilityFlagsKHR,
	minBitstreamBufferOffsetAlignment: DeviceSize,
	minBitstreamBufferSizeAlignment:   DeviceSize,
	pictureAccessGranularity:          Extent2D,
	minCodedExtent:                    Extent2D,
	maxCodedExtent:                    Extent2D,
	maxDpbSlots:                       u32,
	maxActiveReferencePictures:        u32,
	stdHeaderVersion:                  ExtensionProperties,
}

PhysicalDeviceVideoFormatInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	imageUsage: ImageUsageFlags,
}

VideoFormatPropertiesKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	format:           Format,
	componentMapping: ComponentMapping,
	imageCreateFlags: ImageCreateFlags,
	imageType:        ImageType,
	imageTiling:      ImageTiling,
	imageUsageFlags:  ImageUsageFlags,
}

VideoPictureResourceInfoKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	codedOffset:      Offset2D,
	codedExtent:      Extent2D,
	baseArrayLayer:   u32,
	imageViewBinding: ImageView,
}

VideoReferenceSlotInfoKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	slotIndex:        i32,
	pPictureResource: ^VideoPictureResourceInfoKHR,
}

VideoSessionMemoryRequirementsKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	memoryBindIndex:    u32,
	memoryRequirements: MemoryRequirements,
}

BindVideoSessionMemoryInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	memoryBindIndex: u32,
	memory:          DeviceMemory,
	memoryOffset:    DeviceSize,
	memorySize:      DeviceSize,
}

VideoSessionCreateInfoKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	queueFamilyIndex:           u32,
	flags:                      VideoSessionCreateFlagsKHR,
	pVideoProfile:              ^VideoProfileInfoKHR,
	pictureFormat:              Format,
	maxCodedExtent:             Extent2D,
	referencePictureFormat:     Format,
	maxDpbSlots:                u32,
	maxActiveReferencePictures: u32,
	pStdHeaderVersion:          ^ExtensionProperties,
}

VideoSessionParametersCreateInfoKHR :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	flags:                          VideoSessionParametersCreateFlagsKHR,
	videoSessionParametersTemplate: VideoSessionParametersKHR,
	videoSession:                   VideoSessionKHR,
}

VideoSessionParametersUpdateInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	updateSequenceCount: u32,
}

VideoBeginCodingInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  VideoBeginCodingFlagsKHR,
	videoSession:           VideoSessionKHR,
	videoSessionParameters: VideoSessionParametersKHR,
	referenceSlotCount:     u32,
	pReferenceSlots:        [^]VideoReferenceSlotInfoKHR,
}

VideoEndCodingInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: VideoEndCodingFlagsKHR,
}

VideoCodingControlInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: VideoCodingControlFlagsKHR,
}

VideoDecodeCapabilitiesKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: VideoDecodeCapabilityFlagsKHR,
}

VideoDecodeUsageInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	videoUsageHints: VideoDecodeUsageFlagsKHR,
}

VideoDecodeInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	flags:               VideoDecodeFlagsKHR,
	srcBuffer:           Buffer,
	srcBufferOffset:     DeviceSize,
	srcBufferRange:      DeviceSize,
	dstPictureResource:  VideoPictureResourceInfoKHR,
	pSetupReferenceSlot: ^VideoReferenceSlotInfoKHR,
	referenceSlotCount:  u32,
	pReferenceSlots:     [^]VideoReferenceSlotInfoKHR,
}

VideoEncodeH264CapabilitiesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	flags:                            VideoEncodeH264CapabilityFlagsKHR,
	maxLevelIdc:                      VideoH264LevelIdc,
	maxSliceCount:                    u32,
	maxPPictureL0ReferenceCount:      u32,
	maxBPictureL0ReferenceCount:      u32,
	maxL1ReferenceCount:              u32,
	maxTemporalLayerCount:            u32,
	expectDyadicTemporalLayerPattern: b32,
	minQp:                            i32,
	maxQp:                            i32,
	prefersGopRemainingFrames:        b32,
	requiresGopRemainingFrames:       b32,
	stdSyntaxFlags:                   VideoEncodeH264StdFlagsKHR,
}

VideoEncodeH264QpKHR :: struct {
	qpI: i32,
	qpP: i32,
	qpB: i32,
}

VideoEncodeH264QualityLevelPropertiesKHR :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	preferredRateControlFlags:         VideoEncodeH264RateControlFlagsKHR,
	preferredGopFrameCount:            u32,
	preferredIdrPeriod:                u32,
	preferredConsecutiveBFrameCount:   u32,
	preferredTemporalLayerCount:       u32,
	preferredConstantQp:               VideoEncodeH264QpKHR,
	preferredMaxL0ReferenceCount:      u32,
	preferredMaxL1ReferenceCount:      u32,
	preferredStdEntropyCodingModeFlag: b32,
}

VideoEncodeH264SessionCreateInfoKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	useMaxLevelIdc: b32,
	maxLevelIdc:    VideoH264LevelIdc,
}

VideoEncodeH264SessionParametersAddInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	stdSPSCount: u32,
	pStdSPSs:    [^]VideoH264SequenceParameterSet,
	stdPPSCount: u32,
	pStdPPSs:    [^]VideoH264PictureParameterSet,
}

VideoEncodeH264SessionParametersCreateInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxStdSPSCount:     u32,
	maxStdPPSCount:     u32,
	pParametersAddInfo: ^VideoEncodeH264SessionParametersAddInfoKHR,
}

VideoEncodeH264SessionParametersGetInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	writeStdSPS: b32,
	writeStdPPS: b32,
	stdSPSId:    u32,
	stdPPSId:    u32,
}

VideoEncodeH264SessionParametersFeedbackInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	hasStdSPSOverrides: b32,
	hasStdPPSOverrides: b32,
}

VideoEncodeH264NaluSliceInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	constantQp:      i32,
	pStdSliceHeader: ^VideoEncodeH264SliceHeader,
}

VideoEncodeH264PictureInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	naluSliceEntryCount: u32,
	pNaluSliceEntries:   [^]VideoEncodeH264NaluSliceInfoKHR,
	pStdPictureInfo:     ^VideoEncodeH264PictureInfo,
	generatePrefixNalu:  b32,
}

VideoEncodeH264DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoEncodeH264ReferenceInfo,
}

VideoEncodeH264ProfileInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	stdProfileIdc: VideoH264ProfileIdc,
}

VideoEncodeH264RateControlInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  VideoEncodeH264RateControlFlagsKHR,
	gopFrameCount:          u32,
	idrPeriod:              u32,
	consecutiveBFrameCount: u32,
	temporalLayerCount:     u32,
}

VideoEncodeH264FrameSizeKHR :: struct {
	frameISize: u32,
	framePSize: u32,
	frameBSize: u32,
}

VideoEncodeH264RateControlLayerInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	useMinQp:        b32,
	minQp:           VideoEncodeH264QpKHR,
	useMaxQp:        b32,
	maxQp:           VideoEncodeH264QpKHR,
	useMaxFrameSize: b32,
	maxFrameSize:    VideoEncodeH264FrameSizeKHR,
}

VideoEncodeH264GopRemainingFrameInfoKHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	useGopRemainingFrames: b32,
	gopRemainingI:         u32,
	gopRemainingP:         u32,
	gopRemainingB:         u32,
}

VideoEncodeH265CapabilitiesKHR :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	flags:                               VideoEncodeH265CapabilityFlagsKHR,
	maxLevelIdc:                         VideoH265LevelIdc,
	maxSliceSegmentCount:                u32,
	maxTiles:                            Extent2D,
	ctbSizes:                            VideoEncodeH265CtbSizeFlagsKHR,
	transformBlockSizes:                 VideoEncodeH265TransformBlockSizeFlagsKHR,
	maxPPictureL0ReferenceCount:         u32,
	maxBPictureL0ReferenceCount:         u32,
	maxL1ReferenceCount:                 u32,
	maxSubLayerCount:                    u32,
	expectDyadicTemporalSubLayerPattern: b32,
	minQp:                               i32,
	maxQp:                               i32,
	prefersGopRemainingFrames:           b32,
	requiresGopRemainingFrames:          b32,
	stdSyntaxFlags:                      VideoEncodeH265StdFlagsKHR,
}

VideoEncodeH265SessionCreateInfoKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	useMaxLevelIdc: b32,
	maxLevelIdc:    VideoH265LevelIdc,
}

VideoEncodeH265QpKHR :: struct {
	qpI: i32,
	qpP: i32,
	qpB: i32,
}

VideoEncodeH265QualityLevelPropertiesKHR :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	preferredRateControlFlags:       VideoEncodeH265RateControlFlagsKHR,
	preferredGopFrameCount:          u32,
	preferredIdrPeriod:              u32,
	preferredConsecutiveBFrameCount: u32,
	preferredSubLayerCount:          u32,
	preferredConstantQp:             VideoEncodeH265QpKHR,
	preferredMaxL0ReferenceCount:    u32,
	preferredMaxL1ReferenceCount:    u32,
}

VideoEncodeH265SessionParametersAddInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	stdVPSCount: u32,
	pStdVPSs:    [^]VideoH265VideoParameterSet,
	stdSPSCount: u32,
	pStdSPSs:    [^]VideoH265SequenceParameterSet,
	stdPPSCount: u32,
	pStdPPSs:    [^]VideoH265PictureParameterSet,
}

VideoEncodeH265SessionParametersCreateInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxStdVPSCount:     u32,
	maxStdSPSCount:     u32,
	maxStdPPSCount:     u32,
	pParametersAddInfo: ^VideoEncodeH265SessionParametersAddInfoKHR,
}

VideoEncodeH265SessionParametersGetInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	writeStdVPS: b32,
	writeStdSPS: b32,
	writeStdPPS: b32,
	stdVPSId:    u32,
	stdSPSId:    u32,
	stdPPSId:    u32,
}

VideoEncodeH265SessionParametersFeedbackInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	hasStdVPSOverrides: b32,
	hasStdSPSOverrides: b32,
	hasStdPPSOverrides: b32,
}

VideoEncodeH265NaluSliceSegmentInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	constantQp:             i32,
	pStdSliceSegmentHeader: ^VideoEncodeH265SliceSegmentHeader,
}

VideoEncodeH265PictureInfoKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	naluSliceSegmentEntryCount: u32,
	pNaluSliceSegmentEntries:   [^]VideoEncodeH265NaluSliceSegmentInfoKHR,
	pStdPictureInfo:            ^VideoEncodeH265PictureInfo,
}

VideoEncodeH265DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoEncodeH265ReferenceInfo,
}

VideoEncodeH265ProfileInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	stdProfileIdc: VideoH265ProfileIdc,
}

VideoEncodeH265RateControlInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  VideoEncodeH265RateControlFlagsKHR,
	gopFrameCount:          u32,
	idrPeriod:              u32,
	consecutiveBFrameCount: u32,
	subLayerCount:          u32,
}

VideoEncodeH265FrameSizeKHR :: struct {
	frameISize: u32,
	framePSize: u32,
	frameBSize: u32,
}

VideoEncodeH265RateControlLayerInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	useMinQp:        b32,
	minQp:           VideoEncodeH265QpKHR,
	useMaxQp:        b32,
	maxQp:           VideoEncodeH265QpKHR,
	useMaxFrameSize: b32,
	maxFrameSize:    VideoEncodeH265FrameSizeKHR,
}

VideoEncodeH265GopRemainingFrameInfoKHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	useGopRemainingFrames: b32,
	gopRemainingI:         u32,
	gopRemainingP:         u32,
	gopRemainingB:         u32,
}

VideoDecodeH264ProfileInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	stdProfileIdc: VideoH264ProfileIdc,
	pictureLayout: VideoDecodeH264PictureLayoutFlagsKHR,
}

VideoDecodeH264CapabilitiesKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	maxLevelIdc:            VideoH264LevelIdc,
	fieldOffsetGranularity: Offset2D,
}

VideoDecodeH264SessionParametersAddInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	stdSPSCount: u32,
	pStdSPSs:    [^]VideoH264SequenceParameterSet,
	stdPPSCount: u32,
	pStdPPSs:    [^]VideoH264PictureParameterSet,
}

VideoDecodeH264SessionParametersCreateInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxStdSPSCount:     u32,
	maxStdPPSCount:     u32,
	pParametersAddInfo: ^VideoDecodeH264SessionParametersAddInfoKHR,
}

VideoDecodeH264PictureInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	pStdPictureInfo: ^VideoDecodeH264PictureInfo,
	sliceCount:      u32,
	pSliceOffsets:   [^]u32,
}

VideoDecodeH264DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoDecodeH264ReferenceInfo,
}

ImportMemoryFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalMemoryHandleTypeFlags,
	fd:         c.int,
}

MemoryFdPropertiesKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	memoryTypeBits: u32,
}

MemoryGetFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	memory:     DeviceMemory,
	handleType: ExternalMemoryHandleTypeFlags,
}

ImportSemaphoreFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	semaphore:  Semaphore,
	flags:      SemaphoreImportFlags,
	handleType: ExternalSemaphoreHandleTypeFlags,
	fd:         c.int,
}

SemaphoreGetFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	semaphore:  Semaphore,
	handleType: ExternalSemaphoreHandleTypeFlags,
}

RectLayerKHR :: struct {
	offset: Offset2D,
	extent: Extent2D,
	layer:  u32,
}

PresentRegionKHR :: struct {
	rectangleCount: u32,
	pRectangles:    [^]RectLayerKHR,
}

PresentRegionsKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pRegions:       [^]PresentRegionKHR,
}

SharedPresentSurfaceCapabilitiesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	sharedPresentSupportedUsageFlags: ImageUsageFlags,
}

ImportFenceFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	fence:      Fence,
	flags:      FenceImportFlags,
	handleType: ExternalFenceHandleTypeFlags,
	fd:         c.int,
}

FenceGetFdInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	fence:      Fence,
	handleType: ExternalFenceHandleTypeFlags,
}

PhysicalDevicePerformanceQueryFeaturesKHR :: struct {
	sType:                                StructureType,
	pNext:                                rawptr,
	performanceCounterQueryPools:         b32,
	performanceCounterMultipleQueryPools: b32,
}

PhysicalDevicePerformanceQueryPropertiesKHR :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	allowCommandBufferQueryCopies: b32,
}

PerformanceCounterKHR :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	unit:    PerformanceCounterUnitKHR,
	scope:   PerformanceCounterScopeKHR,
	storage: PerformanceCounterStorageKHR,
	uuid:    [UUID_SIZE]u8,
}

PerformanceCounterDescriptionKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	flags:       PerformanceCounterDescriptionFlagsKHR,
	name:        [MAX_DESCRIPTION_SIZE]byte,
	category:    [MAX_DESCRIPTION_SIZE]byte,
	description: [MAX_DESCRIPTION_SIZE]byte,
}

QueryPoolPerformanceCreateInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	queueFamilyIndex:  u32,
	counterIndexCount: u32,
	pCounterIndices:   [^]u32,
}

PerformanceCounterResultKHR :: struct #raw_union {
	int32:   i32,
	int64:   i64,
	uint32:  u32,
	uint64:  u64,
	float32: f32,
	float64: f64,
}

AcquireProfilingLockInfoKHR :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	flags:   AcquireProfilingLockFlagsKHR,
	timeout: u64,
}

PerformanceQuerySubmitInfoKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	counterPassIndex: u32,
}

PhysicalDeviceSurfaceInfo2KHR :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	surface: SurfaceKHR,
}

SurfaceCapabilities2KHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	surfaceCapabilities: SurfaceCapabilitiesKHR,
}

SurfaceFormat2KHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	surfaceFormat: SurfaceFormatKHR,
}

DisplayProperties2KHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	displayProperties: DisplayPropertiesKHR,
}

DisplayPlaneProperties2KHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	displayPlaneProperties: DisplayPlanePropertiesKHR,
}

DisplayModeProperties2KHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	displayModeProperties: DisplayModePropertiesKHR,
}

DisplayPlaneInfo2KHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	mode:       DisplayModeKHR,
	planeIndex: u32,
}

DisplayPlaneCapabilities2KHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	capabilities: DisplayPlaneCapabilitiesKHR,
}

PhysicalDeviceShaderClockFeaturesKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	shaderSubgroupClock: b32,
	shaderDeviceClock:   b32,
}

VideoDecodeH265ProfileInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	stdProfileIdc: VideoH265ProfileIdc,
}

VideoDecodeH265CapabilitiesKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	maxLevelIdc: VideoH265LevelIdc,
}

VideoDecodeH265SessionParametersAddInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	stdVPSCount: u32,
	pStdVPSs:    [^]VideoH265VideoParameterSet,
	stdSPSCount: u32,
	pStdSPSs:    [^]VideoH265SequenceParameterSet,
	stdPPSCount: u32,
	pStdPPSs:    [^]VideoH265PictureParameterSet,
}

VideoDecodeH265SessionParametersCreateInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxStdVPSCount:     u32,
	maxStdSPSCount:     u32,
	maxStdPPSCount:     u32,
	pParametersAddInfo: ^VideoDecodeH265SessionParametersAddInfoKHR,
}

VideoDecodeH265PictureInfoKHR :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	pStdPictureInfo:      ^VideoDecodeH265PictureInfo,
	sliceSegmentCount:    u32,
	pSliceSegmentOffsets: [^]u32,
}

VideoDecodeH265DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoDecodeH265ReferenceInfo,
}

FragmentShadingRateAttachmentInfoKHR :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	pFragmentShadingRateAttachment: ^AttachmentReference2,
	shadingRateAttachmentTexelSize: Extent2D,
}

PipelineFragmentShadingRateStateCreateInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	fragmentSize: Extent2D,
	combinerOps:  [2]FragmentShadingRateCombinerOpKHR,
}

PhysicalDeviceFragmentShadingRateFeaturesKHR :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	pipelineFragmentShadingRate:   b32,
	primitiveFragmentShadingRate:  b32,
	attachmentFragmentShadingRate: b32,
}

PhysicalDeviceFragmentShadingRatePropertiesKHR :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	minFragmentShadingRateAttachmentTexelSize:            Extent2D,
	maxFragmentShadingRateAttachmentTexelSize:            Extent2D,
	maxFragmentShadingRateAttachmentTexelSizeAspectRatio: u32,
	primitiveFragmentShadingRateWithMultipleViewports:    b32,
	layeredShadingRateAttachments:                        b32,
	fragmentShadingRateNonTrivialCombinerOps:             b32,
	maxFragmentSize:                                      Extent2D,
	maxFragmentSizeAspectRatio:                           u32,
	maxFragmentShadingRateCoverageSamples:                u32,
	maxFragmentShadingRateRasterizationSamples:           SampleCountFlags,
	fragmentShadingRateWithShaderDepthStencilWrites:      b32,
	fragmentShadingRateWithSampleMask:                    b32,
	fragmentShadingRateWithShaderSampleMask:              b32,
	fragmentShadingRateWithConservativeRasterization:     b32,
	fragmentShadingRateWithFragmentShaderInterlock:       b32,
	fragmentShadingRateWithCustomSampleLocations:         b32,
	fragmentShadingRateStrictMultiplyCombiner:            b32,
}

PhysicalDeviceFragmentShadingRateKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	sampleCounts: SampleCountFlags,
	fragmentSize: Extent2D,
}

RenderingFragmentShadingRateAttachmentInfoKHR :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	imageView:                      ImageView,
	imageLayout:                    ImageLayout,
	shadingRateAttachmentTexelSize: Extent2D,
}

PhysicalDeviceShaderQuadControlFeaturesKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	shaderQuadControl: b32,
}

SurfaceProtectedCapabilitiesKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	supportsProtected: b32,
}

PhysicalDevicePresentWaitFeaturesKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	presentWait: b32,
}

PhysicalDevicePipelineExecutablePropertiesFeaturesKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	pipelineExecutableInfo: b32,
}

PipelineInfoKHR :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	pipeline: Pipeline,
}

PipelineExecutablePropertiesKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	stages:       ShaderStageFlags,
	name:         [MAX_DESCRIPTION_SIZE]byte,
	description:  [MAX_DESCRIPTION_SIZE]byte,
	subgroupSize: u32,
}

PipelineExecutableInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	pipeline:        Pipeline,
	executableIndex: u32,
}

PipelineExecutableStatisticValueKHR :: struct #raw_union {
	b32: b32,
	i64: i64,
	u64: u64,
	f64: f64,
}

PipelineExecutableStatisticKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	name:        [MAX_DESCRIPTION_SIZE]byte,
	description: [MAX_DESCRIPTION_SIZE]byte,
	format:      PipelineExecutableStatisticFormatKHR,
	value:       PipelineExecutableStatisticValueKHR,
}

PipelineExecutableInternalRepresentationKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	name:        [MAX_DESCRIPTION_SIZE]byte,
	description: [MAX_DESCRIPTION_SIZE]byte,
	isText:      b32,
	dataSize:    int,
	pData:       rawptr,
}

PipelineLibraryCreateInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	libraryCount: u32,
	pLibraries:   [^]Pipeline,
}

PresentIdKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pPresentIds:    [^]u64,
}

PhysicalDevicePresentIdFeaturesKHR :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	presentId: b32,
}

VideoEncodeInfoKHR :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	flags:                           VideoEncodeFlagsKHR,
	dstBuffer:                       Buffer,
	dstBufferOffset:                 DeviceSize,
	dstBufferRange:                  DeviceSize,
	srcPictureResource:              VideoPictureResourceInfoKHR,
	pSetupReferenceSlot:             ^VideoReferenceSlotInfoKHR,
	referenceSlotCount:              u32,
	pReferenceSlots:                 [^]VideoReferenceSlotInfoKHR,
	precedingExternallyEncodedBytes: u32,
}

VideoEncodeCapabilitiesKHR :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	flags:                         VideoEncodeCapabilityFlagsKHR,
	rateControlModes:              VideoEncodeRateControlModeFlagsKHR,
	maxRateControlLayers:          u32,
	maxBitrate:                    u64,
	maxQualityLevels:              u32,
	encodeInputPictureGranularity: Extent2D,
	supportedEncodeFeedbackFlags:  VideoEncodeFeedbackFlagsKHR,
}

QueryPoolVideoEncodeFeedbackCreateInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	encodeFeedbackFlags: VideoEncodeFeedbackFlagsKHR,
}

VideoEncodeUsageInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	videoUsageHints:   VideoEncodeUsageFlagsKHR,
	videoContentHints: VideoEncodeContentFlagsKHR,
	tuningMode:        VideoEncodeTuningModeKHR,
}

VideoEncodeRateControlLayerInfoKHR :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	averageBitrate:       u64,
	maxBitrate:           u64,
	frameRateNumerator:   u32,
	frameRateDenominator: u32,
}

VideoEncodeRateControlInfoKHR :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	flags:                        VideoEncodeRateControlFlagsKHR,
	rateControlMode:              VideoEncodeRateControlModeFlagsKHR,
	layerCount:                   u32,
	pLayers:                      [^]VideoEncodeRateControlLayerInfoKHR,
	virtualBufferSizeInMs:        u32,
	initialVirtualBufferSizeInMs: u32,
}

PhysicalDeviceVideoEncodeQualityLevelInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	pVideoProfile: ^VideoProfileInfoKHR,
	qualityLevel:  u32,
}

VideoEncodeQualityLevelPropertiesKHR :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	preferredRateControlMode:       VideoEncodeRateControlModeFlagsKHR,
	preferredRateControlLayerCount: u32,
}

VideoEncodeQualityLevelInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	qualityLevel: u32,
}

VideoEncodeSessionParametersGetInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	videoSessionParameters: VideoSessionParametersKHR,
}

VideoEncodeSessionParametersFeedbackInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	hasOverrides: b32,
}

PhysicalDeviceFragmentShaderBarycentricFeaturesKHR :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	fragmentShaderBarycentric: b32,
}

PhysicalDeviceFragmentShaderBarycentricPropertiesKHR :: struct {
	sType:                                           StructureType,
	pNext:                                           rawptr,
	triStripVertexOrderIndependentOfProvokingVertex: b32,
}

PhysicalDeviceShaderSubgroupUniformControlFlowFeaturesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	shaderSubgroupUniformControlFlow: b32,
}

PhysicalDeviceWorkgroupMemoryExplicitLayoutFeaturesKHR :: struct {
	sType:                                          StructureType,
	pNext:                                          rawptr,
	workgroupMemoryExplicitLayout:                  b32,
	workgroupMemoryExplicitLayoutScalarBlockLayout: b32,
	workgroupMemoryExplicitLayout8BitAccess:        b32,
	workgroupMemoryExplicitLayout16BitAccess:       b32,
}

PhysicalDeviceRayTracingMaintenance1FeaturesKHR :: struct {
	sType:                                StructureType,
	pNext:                                rawptr,
	rayTracingMaintenance1:               b32,
	rayTracingPipelineTraceRaysIndirect2: b32,
}

TraceRaysIndirectCommand2KHR :: struct {
	raygenShaderRecordAddress:         DeviceAddress,
	raygenShaderRecordSize:            DeviceSize,
	missShaderBindingTableAddress:     DeviceAddress,
	missShaderBindingTableSize:        DeviceSize,
	missShaderBindingTableStride:      DeviceSize,
	hitShaderBindingTableAddress:      DeviceAddress,
	hitShaderBindingTableSize:         DeviceSize,
	hitShaderBindingTableStride:       DeviceSize,
	callableShaderBindingTableAddress: DeviceAddress,
	callableShaderBindingTableSize:    DeviceSize,
	callableShaderBindingTableStride:  DeviceSize,
	width:                             u32,
	height:                            u32,
	depth:                             u32,
}

PhysicalDeviceShaderMaximalReconvergenceFeaturesKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	shaderMaximalReconvergence: b32,
}

PhysicalDeviceRayTracingPositionFetchFeaturesKHR :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	rayTracingPositionFetch: b32,
}

PhysicalDevicePipelineBinaryFeaturesKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	pipelineBinaries: b32,
}

PhysicalDevicePipelineBinaryPropertiesKHR :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	pipelineBinaryInternalCache:            b32,
	pipelineBinaryInternalCacheControl:     b32,
	pipelineBinaryPrefersInternalCache:     b32,
	pipelineBinaryPrecompiledInternalCache: b32,
	pipelineBinaryCompressedData:           b32,
}

DevicePipelineBinaryInternalCacheControlKHR :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	disableInternalCache: b32,
}

PipelineBinaryKeyKHR :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	keySize: u32,
	key:     [MAX_PIPELINE_BINARY_KEY_SIZE_KHR]u8,
}

PipelineBinaryDataKHR :: struct {
	dataSize: int,
	pData:    rawptr,
}

PipelineBinaryKeysAndDataKHR :: struct {
	binaryCount:         u32,
	pPipelineBinaryKeys: [^]PipelineBinaryKeyKHR,
	pPipelineBinaryData: ^PipelineBinaryDataKHR,
}

PipelineCreateInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
}

PipelineBinaryCreateInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	pKeysAndDataInfo:    ^PipelineBinaryKeysAndDataKHR,
	pipeline:            Pipeline,
	pPipelineCreateInfo: ^PipelineCreateInfoKHR,
}

PipelineBinaryInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	binaryCount:       u32,
	pPipelineBinaries: [^]PipelineBinaryKHR,
}

ReleaseCapturedPipelineDataInfoKHR :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	pipeline: Pipeline,
}

PipelineBinaryDataInfoKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	pipelineBinary: PipelineBinaryKHR,
}

PipelineBinaryHandlesInfoKHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	pipelineBinaryCount: u32,
	pPipelineBinaries:   [^]PipelineBinaryKHR,
}

CooperativeMatrixPropertiesKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	MSize:                  u32,
	NSize:                  u32,
	KSize:                  u32,
	AType:                  ComponentTypeKHR,
	BType:                  ComponentTypeKHR,
	CType:                  ComponentTypeKHR,
	ResultType:             ComponentTypeKHR,
	saturatingAccumulation: b32,
	scope:                  ScopeKHR,
}

PhysicalDeviceCooperativeMatrixFeaturesKHR :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	cooperativeMatrix:                   b32,
	cooperativeMatrixRobustBufferAccess: b32,
}

PhysicalDeviceCooperativeMatrixPropertiesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	cooperativeMatrixSupportedStages: ShaderStageFlags,
}

PhysicalDeviceComputeShaderDerivativesFeaturesKHR :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	computeDerivativeGroupQuads:  b32,
	computeDerivativeGroupLinear: b32,
}

PhysicalDeviceComputeShaderDerivativesPropertiesKHR :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	meshAndTaskShaderDerivatives: b32,
}

VideoDecodeAV1ProfileInfoKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	stdProfile:       VideoAV1Profile,
	filmGrainSupport: b32,
}

VideoDecodeAV1CapabilitiesKHR :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	maxLevel: VideoAV1Level,
}

VideoDecodeAV1SessionParametersCreateInfoKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	pStdSequenceHeader: ^VideoAV1SequenceHeader,
}

VideoDecodeAV1PictureInfoKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	pStdPictureInfo:          ^VideoDecodeAV1PictureInfo,
	referenceNameSlotIndices: [MAX_VIDEO_AV1_REFERENCES_PER_FRAME_KHR]i32,
	frameHeaderOffset:        u32,
	tileCount:                u32,
	pTileOffsets:             [^]u32,
	pTileSizes:               [^]u32,
}

VideoDecodeAV1DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoDecodeAV1ReferenceInfo,
}

PhysicalDeviceVideoEncodeAV1FeaturesKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	videoEncodeAV1: b32,
}

VideoEncodeAV1CapabilitiesKHR :: struct {
	sType:                                         StructureType,
	pNext:                                         rawptr,
	flags:                                         VideoEncodeAV1CapabilityFlagsKHR,
	maxLevel:                                      VideoAV1Level,
	codedPictureAlignment:                         Extent2D,
	maxTiles:                                      Extent2D,
	minTileSize:                                   Extent2D,
	maxTileSize:                                   Extent2D,
	superblockSizes:                               VideoEncodeAV1SuperblockSizeFlagsKHR,
	maxSingleReferenceCount:                       u32,
	singleReferenceNameMask:                       u32,
	maxUnidirectionalCompoundReferenceCount:       u32,
	maxUnidirectionalCompoundGroup1ReferenceCount: u32,
	unidirectionalCompoundReferenceNameMask:       u32,
	maxBidirectionalCompoundReferenceCount:        u32,
	maxBidirectionalCompoundGroup1ReferenceCount:  u32,
	maxBidirectionalCompoundGroup2ReferenceCount:  u32,
	bidirectionalCompoundReferenceNameMask:        u32,
	maxTemporalLayerCount:                         u32,
	maxSpatialLayerCount:                          u32,
	maxOperatingPoints:                            u32,
	minQIndex:                                     u32,
	maxQIndex:                                     u32,
	prefersGopRemainingFrames:                     b32,
	requiresGopRemainingFrames:                    b32,
	stdSyntaxFlags:                                VideoEncodeAV1StdFlagsKHR,
}

VideoEncodeAV1QIndexKHR :: struct {
	intraQIndex:        u32,
	predictiveQIndex:   u32,
	bipredictiveQIndex: u32,
}

VideoEncodeAV1QualityLevelPropertiesKHR :: struct {
	sType:                                                  StructureType,
	pNext:                                                  rawptr,
	preferredRateControlFlags:                              VideoEncodeAV1RateControlFlagsKHR,
	preferredGopFrameCount:                                 u32,
	preferredKeyFramePeriod:                                u32,
	preferredConsecutiveBipredictiveFrameCount:             u32,
	preferredTemporalLayerCount:                            u32,
	preferredConstantQIndex:                                VideoEncodeAV1QIndexKHR,
	preferredMaxSingleReferenceCount:                       u32,
	preferredSingleReferenceNameMask:                       u32,
	preferredMaxUnidirectionalCompoundReferenceCount:       u32,
	preferredMaxUnidirectionalCompoundGroup1ReferenceCount: u32,
	preferredUnidirectionalCompoundReferenceNameMask:       u32,
	preferredMaxBidirectionalCompoundReferenceCount:        u32,
	preferredMaxBidirectionalCompoundGroup1ReferenceCount:  u32,
	preferredMaxBidirectionalCompoundGroup2ReferenceCount:  u32,
	preferredBidirectionalCompoundReferenceNameMask:        u32,
}

VideoEncodeAV1SessionCreateInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	useMaxLevel: b32,
	maxLevel:    VideoAV1Level,
}

VideoEncodeAV1SessionParametersCreateInfoKHR :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	pStdSequenceHeader:     ^VideoAV1SequenceHeader,
	pStdDecoderModelInfo:   ^VideoEncodeAV1DecoderModelInfo,
	stdOperatingPointCount: u32,
	pStdOperatingPoints:    [^]VideoEncodeAV1OperatingPointInfo,
}

VideoEncodeAV1PictureInfoKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	predictionMode:             VideoEncodeAV1PredictionModeKHR,
	rateControlGroup:           VideoEncodeAV1RateControlGroupKHR,
	constantQIndex:             u32,
	pStdPictureInfo:            ^VideoEncodeAV1PictureInfo,
	referenceNameSlotIndices:   [MAX_VIDEO_AV1_REFERENCES_PER_FRAME_KHR]i32,
	primaryReferenceCdfOnly:    b32,
	generateObuExtensionHeader: b32,
}

VideoEncodeAV1DpbSlotInfoKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pStdReferenceInfo: ^VideoEncodeAV1ReferenceInfo,
}

VideoEncodeAV1ProfileInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	stdProfile: VideoAV1Profile,
}

VideoEncodeAV1FrameSizeKHR :: struct {
	intraFrameSize:        u32,
	predictiveFrameSize:   u32,
	bipredictiveFrameSize: u32,
}

VideoEncodeAV1GopRemainingFrameInfoKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	useGopRemainingFrames:    b32,
	gopRemainingIntra:        u32,
	gopRemainingPredictive:   u32,
	gopRemainingBipredictive: u32,
}

VideoEncodeAV1RateControlInfoKHR :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	flags:                             VideoEncodeAV1RateControlFlagsKHR,
	gopFrameCount:                     u32,
	keyFramePeriod:                    u32,
	consecutiveBipredictiveFrameCount: u32,
	temporalLayerCount:                u32,
}

VideoEncodeAV1RateControlLayerInfoKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	useMinQIndex:    b32,
	minQIndex:       VideoEncodeAV1QIndexKHR,
	useMaxQIndex:    b32,
	maxQIndex:       VideoEncodeAV1QIndexKHR,
	useMaxFrameSize: b32,
	maxFrameSize:    VideoEncodeAV1FrameSizeKHR,
}

PhysicalDeviceVideoMaintenance1FeaturesKHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	videoMaintenance1: b32,
}

VideoInlineQueryInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	queryPool:  QueryPool,
	firstQuery: u32,
	queryCount: u32,
}

CalibratedTimestampInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	timeDomain: TimeDomainKHR,
}

SetDescriptorBufferOffsetsInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	stageFlags:     ShaderStageFlags,
	layout:         PipelineLayout,
	firstSet:       u32,
	setCount:       u32,
	pBufferIndices: [^]u32,
	pOffsets:       [^]DeviceSize,
}

BindDescriptorBufferEmbeddedSamplersInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	stageFlags: ShaderStageFlags,
	layout:     PipelineLayout,
	set:        u32,
}

VideoEncodeQuantizationMapCapabilitiesKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	maxQuantizationMapExtent: Extent2D,
}

VideoFormatQuantizationMapPropertiesKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	quantizationMapTexelSize: Extent2D,
}

VideoEncodeQuantizationMapInfoKHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	quantizationMap:       ImageView,
	quantizationMapExtent: Extent2D,
}

VideoEncodeQuantizationMapSessionParametersCreateInfoKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	quantizationMapTexelSize: Extent2D,
}

PhysicalDeviceVideoEncodeQuantizationMapFeaturesKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	videoEncodeQuantizationMap: b32,
}

VideoEncodeH264QuantizationMapCapabilitiesKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	minQpDelta: i32,
	maxQpDelta: i32,
}

VideoEncodeH265QuantizationMapCapabilitiesKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	minQpDelta: i32,
	maxQpDelta: i32,
}

VideoFormatH265QuantizationMapPropertiesKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	compatibleCtbSizes: VideoEncodeH265CtbSizeFlagsKHR,
}

VideoEncodeAV1QuantizationMapCapabilitiesKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	minQIndexDelta: i32,
	maxQIndexDelta: i32,
}

VideoFormatAV1QuantizationMapPropertiesKHR :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	compatibleSuperblockSizes: VideoEncodeAV1SuperblockSizeFlagsKHR,
}

PhysicalDeviceShaderRelaxedExtendedInstructionFeaturesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	shaderRelaxedExtendedInstruction: b32,
}

PhysicalDeviceMaintenance7FeaturesKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	maintenance7: b32,
}

PhysicalDeviceMaintenance7PropertiesKHR :: struct {
	sType:                                                     StructureType,
	pNext:                                                     rawptr,
	robustFragmentShadingRateAttachmentAccess:                 b32,
	separateDepthStencilAttachmentAccess:                      b32,
	maxDescriptorSetTotalUniformBuffersDynamic:                u32,
	maxDescriptorSetTotalStorageBuffersDynamic:                u32,
	maxDescriptorSetTotalBuffersDynamic:                       u32,
	maxDescriptorSetUpdateAfterBindTotalUniformBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindTotalStorageBuffersDynamic: u32,
	maxDescriptorSetUpdateAfterBindTotalBuffersDynamic:        u32,
}

PhysicalDeviceLayeredApiPropertiesKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	vendorID:   u32,
	deviceID:   u32,
	layeredAPI: PhysicalDeviceLayeredApiKHR,
	deviceName: [MAX_PHYSICAL_DEVICE_NAME_SIZE]byte,
}

PhysicalDeviceLayeredApiPropertiesListKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	layeredApiCount: u32,
	pLayeredApis:    [^]PhysicalDeviceLayeredApiPropertiesKHR,
}

PhysicalDeviceLayeredApiVulkanPropertiesKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	properties: PhysicalDeviceProperties2,
}

DebugReportCallbackCreateInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	flags:       DebugReportFlagsEXT,
	pfnCallback: ProcDebugReportCallbackEXT,
	pUserData:   rawptr,
}

PipelineRasterizationStateRasterizationOrderAMD :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	rasterizationOrder: RasterizationOrderAMD,
}

DebugMarkerObjectNameInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	objectType:  DebugReportObjectTypeEXT,
	object:      u64,
	pObjectName: cstring,
}

DebugMarkerObjectTagInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	objectType: DebugReportObjectTypeEXT,
	object:     u64,
	tagName:    u64,
	tagSize:    int,
	pTag:       rawptr,
}

DebugMarkerMarkerInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pMarkerName: cstring,
	color:       [4]f32,
}

DedicatedAllocationImageCreateInfoNV :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	dedicatedAllocation: b32,
}

DedicatedAllocationBufferCreateInfoNV :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	dedicatedAllocation: b32,
}

DedicatedAllocationMemoryAllocateInfoNV :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	image:  Image,
	buffer: Buffer,
}

PhysicalDeviceTransformFeedbackFeaturesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	transformFeedback: b32,
	geometryStreams:   b32,
}

PhysicalDeviceTransformFeedbackPropertiesEXT :: struct {
	sType:                                      StructureType,
	pNext:                                      rawptr,
	maxTransformFeedbackStreams:                u32,
	maxTransformFeedbackBuffers:                u32,
	maxTransformFeedbackBufferSize:             DeviceSize,
	maxTransformFeedbackStreamDataSize:         u32,
	maxTransformFeedbackBufferDataSize:         u32,
	maxTransformFeedbackBufferDataStride:       u32,
	transformFeedbackQueries:                   b32,
	transformFeedbackStreamsLinesTriangles:     b32,
	transformFeedbackRasterizationStreamSelect: b32,
	transformFeedbackDraw:                      b32,
}

PipelineRasterizationStateStreamCreateInfoEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	flags:               PipelineRasterizationStateStreamCreateFlagsEXT,
	rasterizationStream: u32,
}

CuModuleCreateInfoNVX :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	dataSize: int,
	pData:    rawptr,
}

CuModuleTexturingModeCreateInfoNVX :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	use64bitTexturing: b32,
}

CuFunctionCreateInfoNVX :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	module: CuModuleNVX,
	pName:  cstring,
}

CuLaunchInfoNVX :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	function:       CuFunctionNVX,
	gridDimX:       u32,
	gridDimY:       u32,
	gridDimZ:       u32,
	blockDimX:      u32,
	blockDimY:      u32,
	blockDimZ:      u32,
	sharedMemBytes: u32,
	paramCount:     int,
	pParams:        [^]rawptr,
	extraCount:     int,
	pExtras:        [^]rawptr,
}

ImageViewHandleInfoNVX :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	imageView:      ImageView,
	descriptorType: DescriptorType,
	sampler:        Sampler,
}

ImageViewAddressPropertiesNVX :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	deviceAddress: DeviceAddress,
	size:          DeviceSize,
}

TextureLODGatherFormatPropertiesAMD :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	supportsTextureGatherLODBiasAMD: b32,
}

ShaderResourceUsageAMD :: struct {
	numUsedVgprs:             u32,
	numUsedSgprs:             u32,
	ldsSizePerLocalWorkGroup: u32,
	ldsUsageSizeInBytes:      int,
	scratchMemUsageInBytes:   int,
}

ShaderStatisticsInfoAMD :: struct {
	shaderStageMask:      ShaderStageFlags,
	resourceUsage:        ShaderResourceUsageAMD,
	numPhysicalVgprs:     u32,
	numPhysicalSgprs:     u32,
	numAvailableVgprs:    u32,
	numAvailableSgprs:    u32,
	computeWorkGroupSize: [3]u32,
}

PhysicalDeviceCornerSampledImageFeaturesNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	cornerSampledImage: b32,
}

ExternalImageFormatPropertiesNV :: struct {
	imageFormatProperties:         ImageFormatProperties,
	externalMemoryFeatures:        ExternalMemoryFeatureFlagsNV,
	exportFromImportedHandleTypes: ExternalMemoryHandleTypeFlagsNV,
	compatibleHandleTypes:         ExternalMemoryHandleTypeFlagsNV,
}

ExternalMemoryImageCreateInfoNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalMemoryHandleTypeFlagsNV,
}

ExportMemoryAllocateInfoNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	handleTypes: ExternalMemoryHandleTypeFlagsNV,
}

ValidationFlagsEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	disabledValidationCheckCount: u32,
	pDisabledValidationChecks:    [^]ValidationCheckEXT,
}

ImageViewASTCDecodeModeEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	decodeMode: Format,
}

PhysicalDeviceASTCDecodeFeaturesEXT :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	decodeModeSharedExponent: b32,
}

ConditionalRenderingBeginInfoEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	buffer: Buffer,
	offset: DeviceSize,
	flags:  ConditionalRenderingFlagsEXT,
}

PhysicalDeviceConditionalRenderingFeaturesEXT :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	conditionalRendering:          b32,
	inheritedConditionalRendering: b32,
}

CommandBufferInheritanceConditionalRenderingInfoEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	conditionalRenderingEnable: b32,
}

ViewportWScalingNV :: struct {
	xcoeff: f32,
	ycoeff: f32,
}

PipelineViewportWScalingStateCreateInfoNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	viewportWScalingEnable: b32,
	viewportCount:          u32,
	pViewportWScalings:     [^]ViewportWScalingNV,
}

SurfaceCapabilities2EXT :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	minImageCount:            u32,
	maxImageCount:            u32,
	currentExtent:            Extent2D,
	minImageExtent:           Extent2D,
	maxImageExtent:           Extent2D,
	maxImageArrayLayers:      u32,
	supportedTransforms:      SurfaceTransformFlagsKHR,
	currentTransform:         SurfaceTransformFlagsKHR,
	supportedCompositeAlpha:  CompositeAlphaFlagsKHR,
	supportedUsageFlags:      ImageUsageFlags,
	supportedSurfaceCounters: SurfaceCounterFlagsEXT,
}

DisplayPowerInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	powerState: DisplayPowerStateEXT,
}

DeviceEventInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	deviceEvent: DeviceEventTypeEXT,
}

DisplayEventInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	displayEvent: DisplayEventTypeEXT,
}

SwapchainCounterCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	surfaceCounters: SurfaceCounterFlagsEXT,
}

RefreshCycleDurationGOOGLE :: struct {
	refreshDuration: u64,
}

PastPresentationTimingGOOGLE :: struct {
	presentID:           u32,
	desiredPresentTime:  u64,
	actualPresentTime:   u64,
	earliestPresentTime: u64,
	presentMargin:       u64,
}

PresentTimeGOOGLE :: struct {
	presentID:          u32,
	desiredPresentTime: u64,
}

PresentTimesInfoGOOGLE :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pTimes:         [^]PresentTimeGOOGLE,
}

PhysicalDeviceMultiviewPerViewAttributesPropertiesNVX :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	perViewPositionAllComponents: b32,
}

MultiviewPerViewAttributesInfoNVX :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	perViewAttributes:              b32,
	perViewAttributesPositionXOnly: b32,
}

ViewportSwizzleNV :: struct {
	x: ViewportCoordinateSwizzleNV,
	y: ViewportCoordinateSwizzleNV,
	z: ViewportCoordinateSwizzleNV,
	w: ViewportCoordinateSwizzleNV,
}

PipelineViewportSwizzleStateCreateInfoNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	flags:             PipelineViewportSwizzleStateCreateFlagsNV,
	viewportCount:     u32,
	pViewportSwizzles: [^]ViewportSwizzleNV,
}

PhysicalDeviceDiscardRectanglePropertiesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	maxDiscardRectangles: u32,
}

PipelineDiscardRectangleStateCreateInfoEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 PipelineDiscardRectangleStateCreateFlagsEXT,
	discardRectangleMode:  DiscardRectangleModeEXT,
	discardRectangleCount: u32,
	pDiscardRectangles:    [^]Rect2D,
}

PhysicalDeviceConservativeRasterizationPropertiesEXT :: struct {
	sType:                                       StructureType,
	pNext:                                       rawptr,
	primitiveOverestimationSize:                 f32,
	maxExtraPrimitiveOverestimationSize:         f32,
	extraPrimitiveOverestimationSizeGranularity: f32,
	primitiveUnderestimation:                    b32,
	conservativePointAndLineRasterization:       b32,
	degenerateTrianglesRasterized:               b32,
	degenerateLinesRasterized:                   b32,
	fullyCoveredFragmentShaderInputVariable:     b32,
	conservativeRasterizationPostDepthCoverage:  b32,
}

PipelineRasterizationConservativeStateCreateInfoEXT :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	flags:                            PipelineRasterizationConservativeStateCreateFlagsEXT,
	conservativeRasterizationMode:    ConservativeRasterizationModeEXT,
	extraPrimitiveOverestimationSize: f32,
}

PhysicalDeviceDepthClipEnableFeaturesEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	depthClipEnable: b32,
}

PipelineRasterizationDepthClipStateCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           PipelineRasterizationDepthClipStateCreateFlagsEXT,
	depthClipEnable: b32,
}

XYColorEXT :: struct {
	x: f32,
	y: f32,
}

HdrMetadataEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	displayPrimaryRed:         XYColorEXT,
	displayPrimaryGreen:       XYColorEXT,
	displayPrimaryBlue:        XYColorEXT,
	whitePoint:                XYColorEXT,
	maxLuminance:              f32,
	minLuminance:              f32,
	maxContentLightLevel:      f32,
	maxFrameAverageLightLevel: f32,
}

PhysicalDeviceRelaxedLineRasterizationFeaturesIMG :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	relaxedLineRasterization: b32,
}

DebugUtilsLabelEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	pLabelName: cstring,
	color:      [4]f32,
}

DebugUtilsObjectNameInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	objectType:   ObjectType,
	objectHandle: u64,
	pObjectName:  cstring,
}

DebugUtilsMessengerCallbackDataEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	flags:            DebugUtilsMessengerCallbackDataFlagsEXT,
	pMessageIdName:   cstring,
	messageIdNumber:  i32,
	pMessage:         cstring,
	queueLabelCount:  u32,
	pQueueLabels:     [^]DebugUtilsLabelEXT,
	cmdBufLabelCount: u32,
	pCmdBufLabels:    [^]DebugUtilsLabelEXT,
	objectCount:      u32,
	pObjects:         [^]DebugUtilsObjectNameInfoEXT,
}

DebugUtilsMessengerCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           DebugUtilsMessengerCreateFlagsEXT,
	messageSeverity: DebugUtilsMessageSeverityFlagsEXT,
	messageType:     DebugUtilsMessageTypeFlagsEXT,
	pfnUserCallback: ProcDebugUtilsMessengerCallbackEXT,
	pUserData:       rawptr,
}

DebugUtilsObjectTagInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	objectType:   ObjectType,
	objectHandle: u64,
	tagName:      u64,
	tagSize:      int,
	pTag:         rawptr,
}

AttachmentSampleCountInfoAMD :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	colorAttachmentCount:          u32,
	pColorAttachmentSamples:       [^]SampleCountFlags,
	depthStencilAttachmentSamples: SampleCountFlags,
}

SampleLocationEXT :: struct {
	x: f32,
	y: f32,
}

SampleLocationsInfoEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	sampleLocationsPerPixel: SampleCountFlags,
	sampleLocationGridSize:  Extent2D,
	sampleLocationsCount:    u32,
	pSampleLocations:        [^]SampleLocationEXT,
}

AttachmentSampleLocationsEXT :: struct {
	attachmentIndex:     u32,
	sampleLocationsInfo: SampleLocationsInfoEXT,
}

SubpassSampleLocationsEXT :: struct {
	subpassIndex:        u32,
	sampleLocationsInfo: SampleLocationsInfoEXT,
}

RenderPassSampleLocationsBeginInfoEXT :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	attachmentInitialSampleLocationsCount: u32,
	pAttachmentInitialSampleLocations:     [^]AttachmentSampleLocationsEXT,
	postSubpassSampleLocationsCount:       u32,
	pPostSubpassSampleLocations:           [^]SubpassSampleLocationsEXT,
}

PipelineSampleLocationsStateCreateInfoEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	sampleLocationsEnable: b32,
	sampleLocationsInfo:   SampleLocationsInfoEXT,
}

PhysicalDeviceSampleLocationsPropertiesEXT :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	sampleLocationSampleCounts:    SampleCountFlags,
	maxSampleLocationGridSize:     Extent2D,
	sampleLocationCoordinateRange: [2]f32,
	sampleLocationSubPixelBits:    u32,
	variableSampleLocations:       b32,
}

MultisamplePropertiesEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	maxSampleLocationGridSize: Extent2D,
}

PhysicalDeviceBlendOperationAdvancedFeaturesEXT :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	advancedBlendCoherentOperations: b32,
}

PhysicalDeviceBlendOperationAdvancedPropertiesEXT :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	advancedBlendMaxColorAttachments:      u32,
	advancedBlendIndependentBlend:         b32,
	advancedBlendNonPremultipliedSrcColor: b32,
	advancedBlendNonPremultipliedDstColor: b32,
	advancedBlendCorrelatedOverlap:        b32,
	advancedBlendAllOperations:            b32,
}

PipelineColorBlendAdvancedStateCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	srcPremultiplied: b32,
	dstPremultiplied: b32,
	blendOverlap:     BlendOverlapEXT,
}

PipelineCoverageToColorStateCreateInfoNV :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	flags:                   PipelineCoverageToColorStateCreateFlagsNV,
	coverageToColorEnable:   b32,
	coverageToColorLocation: u32,
}

PipelineCoverageModulationStateCreateInfoNV :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	flags:                         PipelineCoverageModulationStateCreateFlagsNV,
	coverageModulationMode:        CoverageModulationModeNV,
	coverageModulationTableEnable: b32,
	coverageModulationTableCount:  u32,
	pCoverageModulationTable:      [^]f32,
}

PhysicalDeviceShaderSMBuiltinsPropertiesNV :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	shaderSMCount:    u32,
	shaderWarpsPerSM: u32,
}

PhysicalDeviceShaderSMBuiltinsFeaturesNV :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	shaderSMBuiltins: b32,
}

DrmFormatModifierPropertiesEXT :: struct {
	drmFormatModifier:               u64,
	drmFormatModifierPlaneCount:     u32,
	drmFormatModifierTilingFeatures: FormatFeatureFlags,
}

DrmFormatModifierPropertiesListEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	drmFormatModifierCount:       u32,
	pDrmFormatModifierProperties: [^]DrmFormatModifierPropertiesEXT,
}

PhysicalDeviceImageDrmFormatModifierInfoEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	drmFormatModifier:     u64,
	sharingMode:           SharingMode,
	queueFamilyIndexCount: u32,
	pQueueFamilyIndices:   [^]u32,
}

ImageDrmFormatModifierListCreateInfoEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	drmFormatModifierCount: u32,
	pDrmFormatModifiers:    [^]u64,
}

ImageDrmFormatModifierExplicitCreateInfoEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	drmFormatModifier:           u64,
	drmFormatModifierPlaneCount: u32,
	pPlaneLayouts:               [^]SubresourceLayout,
}

ImageDrmFormatModifierPropertiesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	drmFormatModifier: u64,
}

DrmFormatModifierProperties2EXT :: struct {
	drmFormatModifier:               u64,
	drmFormatModifierPlaneCount:     u32,
	drmFormatModifierTilingFeatures: FormatFeatureFlags2,
}

DrmFormatModifierPropertiesList2EXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	drmFormatModifierCount:       u32,
	pDrmFormatModifierProperties: [^]DrmFormatModifierProperties2EXT,
}

ValidationCacheCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           ValidationCacheCreateFlagsEXT,
	initialDataSize: int,
	pInitialData:    rawptr,
}

ShaderModuleValidationCacheCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	validationCache: ValidationCacheEXT,
}

ShadingRatePaletteNV :: struct {
	shadingRatePaletteEntryCount: u32,
	pShadingRatePaletteEntries:   [^]ShadingRatePaletteEntryNV,
}

PipelineViewportShadingRateImageStateCreateInfoNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	shadingRateImageEnable: b32,
	viewportCount:          u32,
	pShadingRatePalettes:   [^]ShadingRatePaletteNV,
}

PhysicalDeviceShadingRateImageFeaturesNV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	shadingRateImage:             b32,
	shadingRateCoarseSampleOrder: b32,
}

PhysicalDeviceShadingRateImagePropertiesNV :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	shadingRateTexelSize:        Extent2D,
	shadingRatePaletteSize:      u32,
	shadingRateMaxCoarseSamples: u32,
}

CoarseSampleLocationNV :: struct {
	pixelX: u32,
	pixelY: u32,
	sample: u32,
}

CoarseSampleOrderCustomNV :: struct {
	shadingRate:         ShadingRatePaletteEntryNV,
	sampleCount:         u32,
	sampleLocationCount: u32,
	pSampleLocations:    [^]CoarseSampleLocationNV,
}

PipelineViewportCoarseSampleOrderStateCreateInfoNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	sampleOrderType:        CoarseSampleOrderTypeNV,
	customSampleOrderCount: u32,
	pCustomSampleOrders:    [^]CoarseSampleOrderCustomNV,
}

RayTracingShaderGroupCreateInfoNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	type:               RayTracingShaderGroupTypeKHR,
	generalShader:      u32,
	closestHitShader:   u32,
	anyHitShader:       u32,
	intersectionShader: u32,
}

RayTracingPipelineCreateInfoNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	flags:              PipelineCreateFlags,
	stageCount:         u32,
	pStages:            [^]PipelineShaderStageCreateInfo,
	groupCount:         u32,
	pGroups:            [^]RayTracingShaderGroupCreateInfoNV,
	maxRecursionDepth:  u32,
	layout:             PipelineLayout,
	basePipelineHandle: Pipeline,
	basePipelineIndex:  i32,
}

GeometryTrianglesNV :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	vertexData:      Buffer,
	vertexOffset:    DeviceSize,
	vertexCount:     u32,
	vertexStride:    DeviceSize,
	vertexFormat:    Format,
	indexData:       Buffer,
	indexOffset:     DeviceSize,
	indexCount:      u32,
	indexType:       IndexType,
	transformData:   Buffer,
	transformOffset: DeviceSize,
}

GeometryAABBNV :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	aabbData: Buffer,
	numAABBs: u32,
	stride:   u32,
	offset:   DeviceSize,
}

GeometryDataNV :: struct {
	triangles: GeometryTrianglesNV,
	aabbs:     GeometryAABBNV,
}

GeometryNV :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	geometryType: GeometryTypeKHR,
	geometry:     GeometryDataNV,
	flags:        GeometryFlagsKHR,
}

AccelerationStructureInfoNV :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	type:          AccelerationStructureTypeNV,
	flags:         BuildAccelerationStructureFlagsNV,
	instanceCount: u32,
	geometryCount: u32,
	pGeometries:   [^]GeometryNV,
}

AccelerationStructureCreateInfoNV :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	compactedSize: DeviceSize,
	info:          AccelerationStructureInfoNV,
}

BindAccelerationStructureMemoryInfoNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	accelerationStructure: AccelerationStructureNV,
	memory:                DeviceMemory,
	memoryOffset:          DeviceSize,
	deviceIndexCount:      u32,
	pDeviceIndices:        [^]u32,
}

WriteDescriptorSetAccelerationStructureNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	accelerationStructureCount: u32,
	pAccelerationStructures:    [^]AccelerationStructureNV,
}

AccelerationStructureMemoryRequirementsInfoNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	type:                  AccelerationStructureMemoryRequirementsTypeNV,
	accelerationStructure: AccelerationStructureNV,
}

PhysicalDeviceRayTracingPropertiesNV :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	shaderGroupHandleSize:                  u32,
	maxRecursionDepth:                      u32,
	maxShaderGroupStride:                   u32,
	shaderGroupBaseAlignment:               u32,
	maxGeometryCount:                       u64,
	maxInstanceCount:                       u64,
	maxTriangleCount:                       u64,
	maxDescriptorSetAccelerationStructures: u32,
}

TransformMatrixKHR :: struct {
	mat: [3][4]f32,
}

AabbPositionsKHR :: struct {
	minX: f32,
	minY: f32,
	minZ: f32,
	maxX: f32,
	maxY: f32,
	maxZ: f32,
}

AccelerationStructureInstanceKHR :: struct {
	transform:                                      TransformMatrixKHR,
	instanceCustomIndexAndMask:                     u32, // Most significant byte is mask
	instanceShaderBindingTableRecordOffsetAndFlags: u32, // Most significant byte is flags
	accelerationStructureReference:                 u64,
}

PhysicalDeviceRepresentativeFragmentTestFeaturesNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	representativeFragmentTest: b32,
}

PipelineRepresentativeFragmentTestStateCreateInfoNV :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	representativeFragmentTestEnable: b32,
}

PhysicalDeviceImageViewImageFormatInfoEXT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	imageViewType: ImageViewType,
}

FilterCubicImageViewImageFormatPropertiesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	filterCubic:       b32,
	filterCubicMinmax: b32,
}

ImportMemoryHostPointerInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	handleType:   ExternalMemoryHandleTypeFlags,
	pHostPointer: rawptr,
}

MemoryHostPointerPropertiesEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	memoryTypeBits: u32,
}

PhysicalDeviceExternalMemoryHostPropertiesEXT :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	minImportedHostPointerAlignment: DeviceSize,
}

PipelineCompilerControlCreateInfoAMD :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	compilerControlFlags: PipelineCompilerControlFlagsAMD,
}

PhysicalDeviceShaderCorePropertiesAMD :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	shaderEngineCount:          u32,
	shaderArraysPerEngineCount: u32,
	computeUnitsPerShaderArray: u32,
	simdPerComputeUnit:         u32,
	wavefrontsPerSimd:          u32,
	wavefrontSize:              u32,
	sgprsPerSimd:               u32,
	minSgprAllocation:          u32,
	maxSgprAllocation:          u32,
	sgprAllocationGranularity:  u32,
	vgprsPerSimd:               u32,
	minVgprAllocation:          u32,
	maxVgprAllocation:          u32,
	vgprAllocationGranularity:  u32,
}

DeviceMemoryOverallocationCreateInfoAMD :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	overallocationBehavior: MemoryOverallocationBehaviorAMD,
}

PhysicalDeviceVertexAttributeDivisorPropertiesEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	maxVertexAttribDivisor: u32,
}

PhysicalDeviceMeshShaderFeaturesNV :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	taskShader: b32,
	meshShader: b32,
}

PhysicalDeviceMeshShaderPropertiesNV :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	maxDrawMeshTasksCount:             u32,
	maxTaskWorkGroupInvocations:       u32,
	maxTaskWorkGroupSize:              [3]u32,
	maxTaskTotalMemorySize:            u32,
	maxTaskOutputCount:                u32,
	maxMeshWorkGroupInvocations:       u32,
	maxMeshWorkGroupSize:              [3]u32,
	maxMeshTotalMemorySize:            u32,
	maxMeshOutputVertices:             u32,
	maxMeshOutputPrimitives:           u32,
	maxMeshMultiviewViewCount:         u32,
	meshOutputPerVertexGranularity:    u32,
	meshOutputPerPrimitiveGranularity: u32,
}

DrawMeshTasksIndirectCommandNV :: struct {
	taskCount: u32,
	firstTask: u32,
}

PhysicalDeviceShaderImageFootprintFeaturesNV :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	imageFootprint: b32,
}

PipelineViewportExclusiveScissorStateCreateInfoNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	exclusiveScissorCount: u32,
	pExclusiveScissors:    [^]Rect2D,
}

PhysicalDeviceExclusiveScissorFeaturesNV :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	exclusiveScissor: b32,
}

QueueFamilyCheckpointPropertiesNV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	checkpointExecutionStageMask: PipelineStageFlags,
}

CheckpointDataNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	stage:             PipelineStageFlags,
	pCheckpointMarker: rawptr,
}

QueueFamilyCheckpointProperties2NV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	checkpointExecutionStageMask: PipelineStageFlags2,
}

CheckpointData2NV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	stage:             PipelineStageFlags2,
	pCheckpointMarker: rawptr,
}

PhysicalDeviceShaderIntegerFunctions2FeaturesINTEL :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	shaderIntegerFunctions2: b32,
}

PerformanceValueDataINTEL :: struct #raw_union {
	value32:     u32,
	value64:     u64,
	valueFloat:  f32,
	valueBool:   b32,
	valueString: cstring,
}

PerformanceValueINTEL :: struct {
	type: PerformanceValueTypeINTEL,
	data: PerformanceValueDataINTEL,
}

InitializePerformanceApiInfoINTEL :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	pUserData: rawptr,
}

QueryPoolPerformanceQueryCreateInfoINTEL :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	performanceCountersSampling: QueryPoolSamplingModeINTEL,
}

PerformanceMarkerInfoINTEL :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	marker: u64,
}

PerformanceStreamMarkerInfoINTEL :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	marker: u32,
}

PerformanceOverrideInfoINTEL :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	type:      PerformanceOverrideTypeINTEL,
	enable:    b32,
	parameter: u64,
}

PerformanceConfigurationAcquireInfoINTEL :: struct {
	sType: StructureType,
	pNext: rawptr,
	type:  PerformanceConfigurationTypeINTEL,
}

PhysicalDevicePCIBusInfoPropertiesEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pciDomain:   u32,
	pciBus:      u32,
	pciDevice:   u32,
	pciFunction: u32,
}

DisplayNativeHdrSurfaceCapabilitiesAMD :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	localDimmingSupport: b32,
}

SwapchainDisplayNativeHdrCreateInfoAMD :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	localDimmingEnable: b32,
}

PhysicalDeviceFragmentDensityMapFeaturesEXT :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	fragmentDensityMap:                    b32,
	fragmentDensityMapDynamic:             b32,
	fragmentDensityMapNonSubsampledImages: b32,
}

PhysicalDeviceFragmentDensityMapPropertiesEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	minFragmentDensityTexelSize: Extent2D,
	maxFragmentDensityTexelSize: Extent2D,
	fragmentDensityInvocations:  b32,
}

RenderPassFragmentDensityMapCreateInfoEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	fragmentDensityMapAttachment: AttachmentReference,
}

RenderingFragmentDensityMapAttachmentInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	imageView:   ImageView,
	imageLayout: ImageLayout,
}

PhysicalDeviceShaderCoreProperties2AMD :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	shaderCoreFeatures:     ShaderCorePropertiesFlagsAMD,
	activeComputeUnitCount: u32,
}

PhysicalDeviceCoherentMemoryFeaturesAMD :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	deviceCoherentMemory: b32,
}

PhysicalDeviceShaderImageAtomicInt64FeaturesEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	shaderImageInt64Atomics: b32,
	sparseImageInt64Atomics: b32,
}

PhysicalDeviceMemoryBudgetPropertiesEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	heapBudget: [MAX_MEMORY_HEAPS]DeviceSize,
	heapUsage:  [MAX_MEMORY_HEAPS]DeviceSize,
}

PhysicalDeviceMemoryPriorityFeaturesEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	memoryPriority: b32,
}

MemoryPriorityAllocateInfoEXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	priority: f32,
}

PhysicalDeviceDedicatedAllocationImageAliasingFeaturesNV :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	dedicatedAllocationImageAliasing: b32,
}

PhysicalDeviceBufferDeviceAddressFeaturesEXT :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	bufferDeviceAddress:              b32,
	bufferDeviceAddressCaptureReplay: b32,
	bufferDeviceAddressMultiDevice:   b32,
}

BufferDeviceAddressCreateInfoEXT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	deviceAddress: DeviceAddress,
}

ValidationFeaturesEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	enabledValidationFeatureCount:  u32,
	pEnabledValidationFeatures:     [^]ValidationFeatureEnableEXT,
	disabledValidationFeatureCount: u32,
	pDisabledValidationFeatures:    [^]ValidationFeatureDisableEXT,
}

CooperativeMatrixPropertiesNV :: struct {
	sType: StructureType,
	pNext: rawptr,
	MSize: u32,
	NSize: u32,
	KSize: u32,
	AType: ComponentTypeNV,
	BType: ComponentTypeNV,
	CType: ComponentTypeNV,
	DType: ComponentTypeNV,
	scope: ScopeNV,
}

PhysicalDeviceCooperativeMatrixFeaturesNV :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	cooperativeMatrix:                   b32,
	cooperativeMatrixRobustBufferAccess: b32,
}

PhysicalDeviceCooperativeMatrixPropertiesNV :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	cooperativeMatrixSupportedStages: ShaderStageFlags,
}

PhysicalDeviceCoverageReductionModeFeaturesNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	coverageReductionMode: b32,
}

PipelineCoverageReductionStateCreateInfoNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	flags:                 PipelineCoverageReductionStateCreateFlagsNV,
	coverageReductionMode: CoverageReductionModeNV,
}

FramebufferMixedSamplesCombinationNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	coverageReductionMode: CoverageReductionModeNV,
	rasterizationSamples:  SampleCountFlags,
	depthStencilSamples:   SampleCountFlags,
	colorSamples:          SampleCountFlags,
}

PhysicalDeviceFragmentShaderInterlockFeaturesEXT :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	fragmentShaderSampleInterlock:      b32,
	fragmentShaderPixelInterlock:       b32,
	fragmentShaderShadingRateInterlock: b32,
}

PhysicalDeviceYcbcrImageArraysFeaturesEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	ycbcrImageArrays: b32,
}

PhysicalDeviceProvokingVertexFeaturesEXT :: struct {
	sType:                                     StructureType,
	pNext:                                     rawptr,
	provokingVertexLast:                       b32,
	transformFeedbackPreservesProvokingVertex: b32,
}

PhysicalDeviceProvokingVertexPropertiesEXT :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	provokingVertexModePerPipeline:                       b32,
	transformFeedbackPreservesTriangleFanProvokingVertex: b32,
}

PipelineRasterizationProvokingVertexStateCreateInfoEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	provokingVertexMode: ProvokingVertexModeEXT,
}

HeadlessSurfaceCreateInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: HeadlessSurfaceCreateFlagsEXT,
}

PhysicalDeviceShaderAtomicFloatFeaturesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	shaderBufferFloat32Atomics:   b32,
	shaderBufferFloat32AtomicAdd: b32,
	shaderBufferFloat64Atomics:   b32,
	shaderBufferFloat64AtomicAdd: b32,
	shaderSharedFloat32Atomics:   b32,
	shaderSharedFloat32AtomicAdd: b32,
	shaderSharedFloat64Atomics:   b32,
	shaderSharedFloat64AtomicAdd: b32,
	shaderImageFloat32Atomics:    b32,
	shaderImageFloat32AtomicAdd:  b32,
	sparseImageFloat32Atomics:    b32,
	sparseImageFloat32AtomicAdd:  b32,
}

PhysicalDeviceExtendedDynamicStateFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	extendedDynamicState: b32,
}

PhysicalDeviceMapMemoryPlacedFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	memoryMapPlaced:      b32,
	memoryMapRangePlaced: b32,
	memoryUnmapReserve:   b32,
}

PhysicalDeviceMapMemoryPlacedPropertiesEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	minPlacedMemoryMapAlignment: DeviceSize,
}

MemoryMapPlacedInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	pPlacedAddress: rawptr,
}

PhysicalDeviceShaderAtomicFloat2FeaturesEXT :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	shaderBufferFloat16Atomics:      b32,
	shaderBufferFloat16AtomicAdd:    b32,
	shaderBufferFloat16AtomicMinMax: b32,
	shaderBufferFloat32AtomicMinMax: b32,
	shaderBufferFloat64AtomicMinMax: b32,
	shaderSharedFloat16Atomics:      b32,
	shaderSharedFloat16AtomicAdd:    b32,
	shaderSharedFloat16AtomicMinMax: b32,
	shaderSharedFloat32AtomicMinMax: b32,
	shaderSharedFloat64AtomicMinMax: b32,
	shaderImageFloat32AtomicMinMax:  b32,
	sparseImageFloat32AtomicMinMax:  b32,
}

SurfacePresentModeEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	presentMode: PresentModeKHR,
}

SurfacePresentScalingCapabilitiesEXT :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	supportedPresentScaling:  PresentScalingFlagsEXT,
	supportedPresentGravityX: PresentGravityFlagsEXT,
	supportedPresentGravityY: PresentGravityFlagsEXT,
	minScaledImageExtent:     Extent2D,
	maxScaledImageExtent:     Extent2D,
}

SurfacePresentModeCompatibilityEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	presentModeCount: u32,
	pPresentModes:    [^]PresentModeKHR,
}

PhysicalDeviceSwapchainMaintenance1FeaturesEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	swapchainMaintenance1: b32,
}

SwapchainPresentFenceInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pFences:        [^]Fence,
}

SwapchainPresentModesCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	presentModeCount: u32,
	pPresentModes:    [^]PresentModeKHR,
}

SwapchainPresentModeInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	swapchainCount: u32,
	pPresentModes:  [^]PresentModeKHR,
}

SwapchainPresentScalingCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	scalingBehavior: PresentScalingFlagsEXT,
	presentGravityX: PresentGravityFlagsEXT,
	presentGravityY: PresentGravityFlagsEXT,
}

ReleaseSwapchainImagesInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	swapchain:       SwapchainKHR,
	imageIndexCount: u32,
	pImageIndices:   [^]u32,
}

PhysicalDeviceDeviceGeneratedCommandsPropertiesNV :: struct {
	sType:                                    StructureType,
	pNext:                                    rawptr,
	maxGraphicsShaderGroupCount:              u32,
	maxIndirectSequenceCount:                 u32,
	maxIndirectCommandsTokenCount:            u32,
	maxIndirectCommandsStreamCount:           u32,
	maxIndirectCommandsTokenOffset:           u32,
	maxIndirectCommandsStreamStride:          u32,
	minSequencesCountBufferOffsetAlignment:   u32,
	minSequencesIndexBufferOffsetAlignment:   u32,
	minIndirectCommandsBufferOffsetAlignment: u32,
}

PhysicalDeviceDeviceGeneratedCommandsFeaturesNV :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	deviceGeneratedCommands: b32,
}

GraphicsShaderGroupCreateInfoNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	stageCount:         u32,
	pStages:            [^]PipelineShaderStageCreateInfo,
	pVertexInputState:  ^PipelineVertexInputStateCreateInfo,
	pTessellationState: ^PipelineTessellationStateCreateInfo,
}

GraphicsPipelineShaderGroupsCreateInfoNV :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	groupCount:    u32,
	pGroups:       [^]GraphicsShaderGroupCreateInfoNV,
	pipelineCount: u32,
	pPipelines:    [^]Pipeline,
}

BindShaderGroupIndirectCommandNV :: struct {
	groupIndex: u32,
}

BindIndexBufferIndirectCommandNV :: struct {
	bufferAddress: DeviceAddress,
	size:          u32,
	indexType:     IndexType,
}

BindVertexBufferIndirectCommandNV :: struct {
	bufferAddress: DeviceAddress,
	size:          u32,
	stride:        u32,
}

SetStateFlagsIndirectCommandNV :: struct {
	data: u32,
}

IndirectCommandsStreamNV :: struct {
	buffer: Buffer,
	offset: DeviceSize,
}

IndirectCommandsLayoutTokenNV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	tokenType:                    IndirectCommandsTokenTypeNV,
	stream:                       u32,
	offset:                       u32,
	vertexBindingUnit:            u32,
	vertexDynamicStride:          b32,
	pushconstantPipelineLayout:   PipelineLayout,
	pushconstantShaderStageFlags: ShaderStageFlags,
	pushconstantOffset:           u32,
	pushconstantSize:             u32,
	indirectStateFlags:           IndirectStateFlagsNV,
	indexTypeCount:               u32,
	pIndexTypes:                  [^]IndexType,
	pIndexTypeValues:             [^]u32,
}

IndirectCommandsLayoutCreateInfoNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	flags:             IndirectCommandsLayoutUsageFlagsNV,
	pipelineBindPoint: PipelineBindPoint,
	tokenCount:        u32,
	pTokens:           [^]IndirectCommandsLayoutTokenNV,
	streamCount:       u32,
	pStreamStrides:    [^]u32,
}

GeneratedCommandsInfoNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	pipelineBindPoint:      PipelineBindPoint,
	pipeline:               Pipeline,
	indirectCommandsLayout: IndirectCommandsLayoutNV,
	streamCount:            u32,
	pStreams:               [^]IndirectCommandsStreamNV,
	sequencesCount:         u32,
	preprocessBuffer:       Buffer,
	preprocessOffset:       DeviceSize,
	preprocessSize:         DeviceSize,
	sequencesCountBuffer:   Buffer,
	sequencesCountOffset:   DeviceSize,
	sequencesIndexBuffer:   Buffer,
	sequencesIndexOffset:   DeviceSize,
}

GeneratedCommandsMemoryRequirementsInfoNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	pipelineBindPoint:      PipelineBindPoint,
	pipeline:               Pipeline,
	indirectCommandsLayout: IndirectCommandsLayoutNV,
	maxSequencesCount:      u32,
}

PhysicalDeviceInheritedViewportScissorFeaturesNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	inheritedViewportScissor2D: b32,
}

CommandBufferInheritanceViewportScissorInfoNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	viewportScissor2D:  b32,
	viewportDepthCount: u32,
	pViewportDepths:    [^]Viewport,
}

PhysicalDeviceTexelBufferAlignmentFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	texelBufferAlignment: b32,
}

RenderPassTransformBeginInfoQCOM :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	transform: SurfaceTransformFlagsKHR,
}

CommandBufferInheritanceRenderPassTransformInfoQCOM :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	transform:  SurfaceTransformFlagsKHR,
	renderArea: Rect2D,
}

PhysicalDeviceDepthBiasControlFeaturesEXT :: struct {
	sType:                                           StructureType,
	pNext:                                           rawptr,
	depthBiasControl:                                b32,
	leastRepresentableValueForceUnormRepresentation: b32,
	floatRepresentation:                             b32,
	depthBiasExact:                                  b32,
}

DepthBiasInfoEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	depthBiasConstantFactor: f32,
	depthBiasClamp:          f32,
	depthBiasSlopeFactor:    f32,
}

DepthBiasRepresentationInfoEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	depthBiasRepresentation: DepthBiasRepresentationEXT,
	depthBiasExact:          b32,
}

PhysicalDeviceDeviceMemoryReportFeaturesEXT :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	deviceMemoryReport: b32,
}

DeviceMemoryReportCallbackDataEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          DeviceMemoryReportFlagsEXT,
	type:           DeviceMemoryReportEventTypeEXT,
	memoryObjectId: u64,
	size:           DeviceSize,
	objectType:     ObjectType,
	objectHandle:   u64,
	heapIndex:      u32,
}

DeviceDeviceMemoryReportCreateInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	flags:           DeviceMemoryReportFlagsEXT,
	pfnUserCallback: ProcDeviceMemoryReportCallbackEXT,
	pUserData:       rawptr,
}

PhysicalDeviceRobustness2FeaturesEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	robustBufferAccess2: b32,
	robustImageAccess2:  b32,
	nullDescriptor:      b32,
}

PhysicalDeviceRobustness2PropertiesEXT :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	robustStorageBufferAccessSizeAlignment: DeviceSize,
	robustUniformBufferAccessSizeAlignment: DeviceSize,
}

SamplerCustomBorderColorCreateInfoEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	customBorderColor: ClearColorValue,
	format:            Format,
}

PhysicalDeviceCustomBorderColorPropertiesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	maxCustomBorderColorSamplers: u32,
}

PhysicalDeviceCustomBorderColorFeaturesEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	customBorderColors:             b32,
	customBorderColorWithoutFormat: b32,
}

PhysicalDevicePresentBarrierFeaturesNV :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	presentBarrier: b32,
}

SurfaceCapabilitiesPresentBarrierNV :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	presentBarrierSupported: b32,
}

SwapchainPresentBarrierCreateInfoNV :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	presentBarrierEnable: b32,
}

PhysicalDeviceDiagnosticsConfigFeaturesNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	diagnosticsConfig: b32,
}

DeviceDiagnosticsConfigCreateInfoNV :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: DeviceDiagnosticsConfigFlagsNV,
}

CudaModuleCreateInfoNV :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	dataSize: int,
	pData:    rawptr,
}

CudaFunctionCreateInfoNV :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	module: CudaModuleNV,
	pName:  cstring,
}

CudaLaunchInfoNV :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	function:       CudaFunctionNV,
	gridDimX:       u32,
	gridDimY:       u32,
	gridDimZ:       u32,
	blockDimX:      u32,
	blockDimY:      u32,
	blockDimZ:      u32,
	sharedMemBytes: u32,
	paramCount:     int,
	pParams:        [^]rawptr,
	extraCount:     int,
	pExtras:        [^]rawptr,
}

PhysicalDeviceCudaKernelLaunchFeaturesNV :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	cudaKernelLaunchFeatures: b32,
}

PhysicalDeviceCudaKernelLaunchPropertiesNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	computeCapabilityMinor: u32,
	computeCapabilityMajor: u32,
}

QueryLowLatencySupportNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	pQueriedLowLatencyData: rawptr,
}

PhysicalDeviceDescriptorBufferPropertiesEXT :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	combinedImageSamplerDescriptorSingleArray:            b32,
	bufferlessPushDescriptors:                            b32,
	allowSamplerImageViewPostSubmitCreation:              b32,
	descriptorBufferOffsetAlignment:                      DeviceSize,
	maxDescriptorBufferBindings:                          u32,
	maxResourceDescriptorBufferBindings:                  u32,
	maxSamplerDescriptorBufferBindings:                   u32,
	maxEmbeddedImmutableSamplerBindings:                  u32,
	maxEmbeddedImmutableSamplers:                         u32,
	bufferCaptureReplayDescriptorDataSize:                int,
	imageCaptureReplayDescriptorDataSize:                 int,
	imageViewCaptureReplayDescriptorDataSize:             int,
	samplerCaptureReplayDescriptorDataSize:               int,
	accelerationStructureCaptureReplayDescriptorDataSize: int,
	samplerDescriptorSize:                                int,
	combinedImageSamplerDescriptorSize:                   int,
	sampledImageDescriptorSize:                           int,
	storageImageDescriptorSize:                           int,
	uniformTexelBufferDescriptorSize:                     int,
	robustUniformTexelBufferDescriptorSize:               int,
	storageTexelBufferDescriptorSize:                     int,
	robustStorageTexelBufferDescriptorSize:               int,
	uniformBufferDescriptorSize:                          int,
	robustUniformBufferDescriptorSize:                    int,
	storageBufferDescriptorSize:                          int,
	robustStorageBufferDescriptorSize:                    int,
	inputAttachmentDescriptorSize:                        int,
	accelerationStructureDescriptorSize:                  int,
	maxSamplerDescriptorBufferRange:                      DeviceSize,
	maxResourceDescriptorBufferRange:                     DeviceSize,
	samplerDescriptorBufferAddressSpaceSize:              DeviceSize,
	resourceDescriptorBufferAddressSpaceSize:             DeviceSize,
	descriptorBufferAddressSpaceSize:                     DeviceSize,
}

PhysicalDeviceDescriptorBufferDensityMapPropertiesEXT :: struct {
	sType:                                        StructureType,
	pNext:                                        rawptr,
	combinedImageSamplerDensityMapDescriptorSize: int,
}

PhysicalDeviceDescriptorBufferFeaturesEXT :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	descriptorBuffer:                   b32,
	descriptorBufferCaptureReplay:      b32,
	descriptorBufferImageLayoutIgnored: b32,
	descriptorBufferPushDescriptors:    b32,
}

DescriptorAddressInfoEXT :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	address: DeviceAddress,
	range:   DeviceSize,
	format:  Format,
}

DescriptorBufferBindingInfoEXT :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	address: DeviceAddress,
	usage:   BufferUsageFlags,
}

DescriptorBufferBindingPushDescriptorBufferHandleEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	buffer: Buffer,
}

DescriptorDataEXT :: struct #raw_union {
	pSampler:              ^Sampler,
	pCombinedImageSampler: ^DescriptorImageInfo,
	pInputAttachmentImage: ^DescriptorImageInfo,
	pSampledImage:         ^DescriptorImageInfo,
	pStorageImage:         ^DescriptorImageInfo,
	pUniformTexelBuffer:   ^DescriptorAddressInfoEXT,
	pStorageTexelBuffer:   ^DescriptorAddressInfoEXT,
	pUniformBuffer:        ^DescriptorAddressInfoEXT,
	pStorageBuffer:        ^DescriptorAddressInfoEXT,
	accelerationStructure: DeviceAddress,
}

DescriptorGetInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	type:  DescriptorType,
	data:  DescriptorDataEXT,
}

BufferCaptureDescriptorDataInfoEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	buffer: Buffer,
}

ImageCaptureDescriptorDataInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	image: Image,
}

ImageViewCaptureDescriptorDataInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	imageView: ImageView,
}

SamplerCaptureDescriptorDataInfoEXT :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	sampler: Sampler,
}

OpaqueCaptureDescriptorDataCreateInfoEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	opaqueCaptureDescriptorData: rawptr,
}

AccelerationStructureCaptureDescriptorDataInfoEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	accelerationStructure:   AccelerationStructureKHR,
	accelerationStructureNV: AccelerationStructureNV,
}

PhysicalDeviceGraphicsPipelineLibraryFeaturesEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	graphicsPipelineLibrary: b32,
}

PhysicalDeviceGraphicsPipelineLibraryPropertiesEXT :: struct {
	sType:                                                     StructureType,
	pNext:                                                     rawptr,
	graphicsPipelineLibraryFastLinking:                        b32,
	graphicsPipelineLibraryIndependentInterpolationDecoration: b32,
}

GraphicsPipelineLibraryCreateInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: GraphicsPipelineLibraryFlagsEXT,
}

PhysicalDeviceShaderEarlyAndLateFragmentTestsFeaturesAMD :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	shaderEarlyAndLateFragmentTests: b32,
}

PhysicalDeviceFragmentShadingRateEnumsFeaturesNV :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	fragmentShadingRateEnums:         b32,
	supersampleFragmentShadingRates:  b32,
	noInvocationFragmentShadingRates: b32,
}

PhysicalDeviceFragmentShadingRateEnumsPropertiesNV :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	maxFragmentShadingRateInvocationCount: SampleCountFlags,
}

PipelineFragmentShadingRateEnumStateCreateInfoNV :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	shadingRateType: FragmentShadingRateTypeNV,
	shadingRate:     FragmentShadingRateNV,
	combinerOps:     [2]FragmentShadingRateCombinerOpKHR,
}

DeviceOrHostAddressConstKHR :: struct #raw_union {
	deviceAddress: DeviceAddress,
	hostAddress:   rawptr,
}

AccelerationStructureGeometryMotionTrianglesDataNV :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	vertexData: DeviceOrHostAddressConstKHR,
}

AccelerationStructureMotionInfoNV :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	maxInstances: u32,
	flags:        AccelerationStructureMotionInfoFlagsNV,
}

AccelerationStructureMatrixMotionInstanceNV :: struct {
	transformT0:                                    TransformMatrixKHR,
	transformT1:                                    TransformMatrixKHR,
	instanceCustomIndexAndMask:                     u32, // Most significant byte is mask
	instanceShaderBindingTableRecordOffsetAndFlags: u32, // Most significant byte is flags
	accelerationStructureReference:                 u64,
}

SRTDataNV :: struct {
	sx:  f32,
	a:   f32,
	b:   f32,
	pvx: f32,
	sy:  f32,
	c:   f32,
	pvy: f32,
	sz:  f32,
	pvz: f32,
	qx:  f32,
	qy:  f32,
	qz:  f32,
	qw:  f32,
	tx:  f32,
	ty:  f32,
	tz:  f32,
}

AccelerationStructureSRTMotionInstanceNV :: struct {
	transformT0:                                    SRTDataNV,
	transformT1:                                    SRTDataNV,
	instanceCustomIndexAndMask:                     u32, // Most significant byte is mask
	instanceShaderBindingTableRecordOffsetAndFlags: u32, // Most significant byte is flags
	accelerationStructureReference:                 u64,
}

AccelerationStructureMotionInstanceDataNV :: struct #raw_union {
	staticInstance:       AccelerationStructureInstanceKHR,
	matrixMotionInstance: AccelerationStructureMatrixMotionInstanceNV,
	srtMotionInstance:    AccelerationStructureSRTMotionInstanceNV,
}

AccelerationStructureMotionInstanceNV :: struct {
	type:  AccelerationStructureMotionInstanceTypeNV,
	flags: AccelerationStructureMotionInstanceFlagsNV,
	data:  AccelerationStructureMotionInstanceDataNV,
}

PhysicalDeviceRayTracingMotionBlurFeaturesNV :: struct {
	sType:                                         StructureType,
	pNext:                                         rawptr,
	rayTracingMotionBlur:                          b32,
	rayTracingMotionBlurPipelineTraceRaysIndirect: b32,
}

PhysicalDeviceYcbcr2Plane444FormatsFeaturesEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	ycbcr2plane444Formats: b32,
}

PhysicalDeviceFragmentDensityMap2FeaturesEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	fragmentDensityMapDeferred: b32,
}

PhysicalDeviceFragmentDensityMap2PropertiesEXT :: struct {
	sType:                                     StructureType,
	pNext:                                     rawptr,
	subsampledLoads:                           b32,
	subsampledCoarseReconstructionEarlyAccess: b32,
	maxSubsampledArrayLayers:                  u32,
	maxDescriptorSetSubsampledSamplers:        u32,
}

CopyCommandTransformInfoQCOM :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	transform: SurfaceTransformFlagsKHR,
}

PhysicalDeviceImageCompressionControlFeaturesEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	imageCompressionControl: b32,
}

ImageCompressionControlEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	flags:                        ImageCompressionFlagsEXT,
	compressionControlPlaneCount: u32,
	pFixedRateFlags:              [^]ImageCompressionFixedRateFlagsEXT,
}

ImageCompressionPropertiesEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	imageCompressionFlags:          ImageCompressionFlagsEXT,
	imageCompressionFixedRateFlags: ImageCompressionFixedRateFlagsEXT,
}

PhysicalDeviceAttachmentFeedbackLoopLayoutFeaturesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	attachmentFeedbackLoopLayout: b32,
}

PhysicalDevice4444FormatsFeaturesEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	formatA4R4G4B4: b32,
	formatA4B4G4R4: b32,
}

PhysicalDeviceFaultFeaturesEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	deviceFault:             b32,
	deviceFaultVendorBinary: b32,
}

DeviceFaultCountsEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	addressInfoCount: u32,
	vendorInfoCount:  u32,
	vendorBinarySize: DeviceSize,
}

DeviceFaultAddressInfoEXT :: struct {
	addressType:      DeviceFaultAddressTypeEXT,
	reportedAddress:  DeviceAddress,
	addressPrecision: DeviceSize,
}

DeviceFaultVendorInfoEXT :: struct {
	description:     [MAX_DESCRIPTION_SIZE]byte,
	vendorFaultCode: u64,
	vendorFaultData: u64,
}

DeviceFaultInfoEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	description:       [MAX_DESCRIPTION_SIZE]byte,
	pAddressInfos:     [^]DeviceFaultAddressInfoEXT,
	pVendorInfos:      [^]DeviceFaultVendorInfoEXT,
	pVendorBinaryData: rawptr,
}

DeviceFaultVendorBinaryHeaderVersionOneEXT :: struct {
	headerSize:            u32,
	headerVersion:         DeviceFaultVendorBinaryHeaderVersionEXT,
	vendorID:              u32,
	deviceID:              u32,
	driverVersion:         u32,
	pipelineCacheUUID:     [UUID_SIZE]u8,
	applicationNameOffset: u32,
	applicationVersion:    u32,
	engineNameOffset:      u32,
	engineVersion:         u32,
	apiVersion:            u32,
}

PhysicalDeviceRasterizationOrderAttachmentAccessFeaturesEXT :: struct {
	sType:                                     StructureType,
	pNext:                                     rawptr,
	rasterizationOrderColorAttachmentAccess:   b32,
	rasterizationOrderDepthAttachmentAccess:   b32,
	rasterizationOrderStencilAttachmentAccess: b32,
}

PhysicalDeviceRGBA10X6FormatsFeaturesEXT :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	formatRgba10x6WithoutYCbCrSampler: b32,
}

PhysicalDeviceMutableDescriptorTypeFeaturesEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	mutableDescriptorType: b32,
}

MutableDescriptorTypeListEXT :: struct {
	descriptorTypeCount: u32,
	pDescriptorTypes:    [^]DescriptorType,
}

MutableDescriptorTypeCreateInfoEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	mutableDescriptorTypeListCount: u32,
	pMutableDescriptorTypeLists:    [^]MutableDescriptorTypeListEXT,
}

PhysicalDeviceVertexInputDynamicStateFeaturesEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	vertexInputDynamicState: b32,
}

VertexInputBindingDescription2EXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	binding:   u32,
	stride:    u32,
	inputRate: VertexInputRate,
	divisor:   u32,
}

VertexInputAttributeDescription2EXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	location: u32,
	binding:  u32,
	format:   Format,
	offset:   u32,
}

PhysicalDeviceDrmPropertiesEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	hasPrimary:   b32,
	hasRender:    b32,
	primaryMajor: i64,
	primaryMinor: i64,
	renderMajor:  i64,
	renderMinor:  i64,
}

PhysicalDeviceAddressBindingReportFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	reportAddressBinding: b32,
}

DeviceAddressBindingCallbackDataEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	flags:       DeviceAddressBindingFlagsEXT,
	baseAddress: DeviceAddress,
	size:        DeviceSize,
	bindingType: DeviceAddressBindingTypeEXT,
}

PhysicalDeviceDepthClipControlFeaturesEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	depthClipControl: b32,
}

PipelineViewportDepthClipControlCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	negativeOneToOne: b32,
}

PhysicalDevicePrimitiveTopologyListRestartFeaturesEXT :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	primitiveTopologyListRestart:      b32,
	primitiveTopologyPatchListRestart: b32,
}

PhysicalDevicePresentModeFifoLatestReadyFeaturesEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	presentModeFifoLatestReady: b32,
}

SubpassShadingPipelineCreateInfoHUAWEI :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	renderPass: RenderPass,
	subpass:    u32,
}

PhysicalDeviceSubpassShadingFeaturesHUAWEI :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	subpassShading: b32,
}

PhysicalDeviceSubpassShadingPropertiesHUAWEI :: struct {
	sType:                                     StructureType,
	pNext:                                     rawptr,
	maxSubpassShadingWorkgroupSizeAspectRatio: u32,
}

PhysicalDeviceInvocationMaskFeaturesHUAWEI :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	invocationMask: b32,
}

MemoryGetRemoteAddressInfoNV :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	memory:     DeviceMemory,
	handleType: ExternalMemoryHandleTypeFlags,
}

PhysicalDeviceExternalMemoryRDMAFeaturesNV :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	externalMemoryRDMA: b32,
}

PipelinePropertiesIdentifierEXT :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	pipelineIdentifier: [UUID_SIZE]u8,
}

PhysicalDevicePipelinePropertiesFeaturesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	pipelinePropertiesIdentifier: b32,
}

PhysicalDeviceFrameBoundaryFeaturesEXT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	frameBoundary: b32,
}

FrameBoundaryEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	flags:       FrameBoundaryFlagsEXT,
	frameID:     u64,
	imageCount:  u32,
	pImages:     [^]Image,
	bufferCount: u32,
	pBuffers:    [^]Buffer,
	tagName:     u64,
	tagSize:     int,
	pTag:        rawptr,
}

PhysicalDeviceMultisampledRenderToSingleSampledFeaturesEXT :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	multisampledRenderToSingleSampled: b32,
}

SubpassResolvePerformanceQueryEXT :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	optimal: b32,
}

MultisampledRenderToSingleSampledInfoEXT :: struct {
	sType:                                   StructureType,
	pNext:                                   rawptr,
	multisampledRenderToSingleSampledEnable: b32,
	rasterizationSamples:                    SampleCountFlags,
}

PhysicalDeviceExtendedDynamicState2FeaturesEXT :: struct {
	sType:                                   StructureType,
	pNext:                                   rawptr,
	extendedDynamicState2:                   b32,
	extendedDynamicState2LogicOp:            b32,
	extendedDynamicState2PatchControlPoints: b32,
}

PhysicalDeviceColorWriteEnableFeaturesEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	colorWriteEnable: b32,
}

PipelineColorWriteCreateInfoEXT :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	attachmentCount:    u32,
	pColorWriteEnables: [^]b32,
}

PhysicalDevicePrimitivesGeneratedQueryFeaturesEXT :: struct {
	sType:                                         StructureType,
	pNext:                                         rawptr,
	primitivesGeneratedQuery:                      b32,
	primitivesGeneratedQueryWithRasterizerDiscard: b32,
	primitivesGeneratedQueryWithNonZeroStreams:    b32,
}

PhysicalDeviceImageViewMinLodFeaturesEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	minLod: b32,
}

ImageViewMinLodCreateInfoEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	minLod: f32,
}

PhysicalDeviceMultiDrawFeaturesEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	multiDraw: b32,
}

PhysicalDeviceMultiDrawPropertiesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	maxMultiDrawCount: u32,
}

MultiDrawInfoEXT :: struct {
	firstVertex: u32,
	vertexCount: u32,
}

MultiDrawIndexedInfoEXT :: struct {
	firstIndex:   u32,
	indexCount:   u32,
	vertexOffset: i32,
}

PhysicalDeviceImage2DViewOf3DFeaturesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	image2DViewOf3D:   b32,
	sampler2DViewOf3D: b32,
}

PhysicalDeviceShaderTileImageFeaturesEXT :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	shaderTileImageColorReadAccess:   b32,
	shaderTileImageDepthReadAccess:   b32,
	shaderTileImageStencilReadAccess: b32,
}

PhysicalDeviceShaderTileImagePropertiesEXT :: struct {
	sType:                                            StructureType,
	pNext:                                            rawptr,
	shaderTileImageCoherentReadAccelerated:           b32,
	shaderTileImageReadSampleFromPixelRateInvocation: b32,
	shaderTileImageReadFromHelperInvocation:          b32,
}

MicromapUsageEXT :: struct {
	count:            u32,
	subdivisionLevel: u32,
	format:           u32,
}

DeviceOrHostAddressKHR :: struct #raw_union {
	deviceAddress: DeviceAddress,
	hostAddress:   rawptr,
}

MicromapBuildInfoEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	type:                MicromapTypeEXT,
	flags:               BuildMicromapFlagsEXT,
	mode:                BuildMicromapModeEXT,
	dstMicromap:         MicromapEXT,
	usageCountsCount:    u32,
	pUsageCounts:        [^]MicromapUsageEXT,
	ppUsageCounts:       ^[^]MicromapUsageEXT,
	data:                DeviceOrHostAddressConstKHR,
	scratchData:         DeviceOrHostAddressKHR,
	triangleArray:       DeviceOrHostAddressConstKHR,
	triangleArrayStride: DeviceSize,
}

MicromapCreateInfoEXT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	createFlags:   MicromapCreateFlagsEXT,
	buffer:        Buffer,
	offset:        DeviceSize,
	size:          DeviceSize,
	type:          MicromapTypeEXT,
	deviceAddress: DeviceAddress,
}

PhysicalDeviceOpacityMicromapFeaturesEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	micromap:              b32,
	micromapCaptureReplay: b32,
	micromapHostCommands:  b32,
}

PhysicalDeviceOpacityMicromapPropertiesEXT :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	maxOpacity2StateSubdivisionLevel: u32,
	maxOpacity4StateSubdivisionLevel: u32,
}

MicromapVersionInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	pVersionData: ^u8,
}

CopyMicromapToMemoryInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   MicromapEXT,
	dst:   DeviceOrHostAddressKHR,
	mode:  CopyMicromapModeEXT,
}

CopyMemoryToMicromapInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   DeviceOrHostAddressConstKHR,
	dst:   MicromapEXT,
	mode:  CopyMicromapModeEXT,
}

CopyMicromapInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   MicromapEXT,
	dst:   MicromapEXT,
	mode:  CopyMicromapModeEXT,
}

MicromapBuildSizesInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	micromapSize:     DeviceSize,
	buildScratchSize: DeviceSize,
	discardable:      b32,
}

AccelerationStructureTrianglesOpacityMicromapEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	indexType:        IndexType,
	indexBuffer:      DeviceOrHostAddressConstKHR,
	indexStride:      DeviceSize,
	baseTriangle:     u32,
	usageCountsCount: u32,
	pUsageCounts:     [^]MicromapUsageEXT,
	ppUsageCounts:    ^[^]MicromapUsageEXT,
	micromap:         MicromapEXT,
}

MicromapTriangleEXT :: struct {
	dataOffset:       u32,
	subdivisionLevel: u16,
	format:           u16,
}

PhysicalDeviceClusterCullingShaderFeaturesHUAWEI :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	clustercullingShader:          b32,
	multiviewClusterCullingShader: b32,
}

PhysicalDeviceClusterCullingShaderPropertiesHUAWEI :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	maxWorkGroupCount:             [3]u32,
	maxWorkGroupSize:              [3]u32,
	maxOutputClusterCount:         u32,
	indirectBufferOffsetAlignment: DeviceSize,
}

PhysicalDeviceClusterCullingShaderVrsFeaturesHUAWEI :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	clusterShadingRate: b32,
}

PhysicalDeviceBorderColorSwizzleFeaturesEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	borderColorSwizzle:          b32,
	borderColorSwizzleFromImage: b32,
}

SamplerBorderColorComponentMappingCreateInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	components: ComponentMapping,
	srgb:       b32,
}

PhysicalDevicePageableDeviceLocalMemoryFeaturesEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	pageableDeviceLocalMemory: b32,
}

PhysicalDeviceShaderCorePropertiesARM :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	pixelRate: u32,
	texelRate: u32,
	fmaRate:   u32,
}

DeviceQueueShaderCoreControlCreateInfoARM :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	shaderCoreCount: u32,
}

PhysicalDeviceSchedulingControlsFeaturesARM :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	schedulingControls: b32,
}

PhysicalDeviceSchedulingControlsPropertiesARM :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	schedulingControlsFlags: PhysicalDeviceSchedulingControlsFlagsARM,
}

PhysicalDeviceImageSlicedViewOf3DFeaturesEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	imageSlicedViewOf3D: b32,
}

ImageViewSlicedCreateInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	sliceOffset: u32,
	sliceCount:  u32,
}

PhysicalDeviceDescriptorSetHostMappingFeaturesVALVE :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	descriptorSetHostMapping: b32,
}

DescriptorSetBindingReferenceVALVE :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	descriptorSetLayout: DescriptorSetLayout,
	binding:             u32,
}

DescriptorSetLayoutHostMappingInfoVALVE :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	descriptorOffset: int,
	descriptorSize:   u32,
}

PhysicalDeviceDepthClampZeroOneFeaturesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	depthClampZeroOne: b32,
}

PhysicalDeviceNonSeamlessCubeMapFeaturesEXT :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	nonSeamlessCubeMap: b32,
}

PhysicalDeviceRenderPassStripedFeaturesARM :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	renderPassStriped: b32,
}

PhysicalDeviceRenderPassStripedPropertiesARM :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	renderPassStripeGranularity: Extent2D,
	maxRenderPassStripes:        u32,
}

RenderPassStripeInfoARM :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	stripeArea: Rect2D,
}

RenderPassStripeBeginInfoARM :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	stripeInfoCount: u32,
	pStripeInfos:    [^]RenderPassStripeInfoARM,
}

RenderPassStripeSubmitInfoARM :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	stripeSemaphoreInfoCount: u32,
	pStripeSemaphoreInfos:    [^]SemaphoreSubmitInfo,
}

PhysicalDeviceFragmentDensityMapOffsetFeaturesQCOM :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	fragmentDensityMapOffset: b32,
}

PhysicalDeviceFragmentDensityMapOffsetPropertiesQCOM :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	fragmentDensityOffsetGranularity: Extent2D,
}

SubpassFragmentDensityMapOffsetEndInfoQCOM :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	fragmentDensityOffsetCount: u32,
	pFragmentDensityOffsets:    [^]Offset2D,
}

CopyMemoryIndirectCommandNV :: struct {
	srcAddress: DeviceAddress,
	dstAddress: DeviceAddress,
	size:       DeviceSize,
}

CopyMemoryToImageIndirectCommandNV :: struct {
	srcAddress:        DeviceAddress,
	bufferRowLength:   u32,
	bufferImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

PhysicalDeviceCopyMemoryIndirectFeaturesNV :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	indirectCopy: b32,
}

PhysicalDeviceCopyMemoryIndirectPropertiesNV :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	supportedQueues: QueueFlags,
}

DecompressMemoryRegionNV :: struct {
	srcAddress:          DeviceAddress,
	dstAddress:          DeviceAddress,
	compressedSize:      DeviceSize,
	decompressedSize:    DeviceSize,
	decompressionMethod: MemoryDecompressionMethodFlagsNV,
}

PhysicalDeviceMemoryDecompressionFeaturesNV :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	memoryDecompression: b32,
}

PhysicalDeviceMemoryDecompressionPropertiesNV :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	decompressionMethods:          MemoryDecompressionMethodFlagsNV,
	maxDecompressionIndirectCount: u64,
}

PhysicalDeviceDeviceGeneratedCommandsComputeFeaturesNV :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	deviceGeneratedCompute:              b32,
	deviceGeneratedComputePipelines:     b32,
	deviceGeneratedComputeCaptureReplay: b32,
}

ComputePipelineIndirectBufferInfoNV :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	deviceAddress:                      DeviceAddress,
	size:                               DeviceSize,
	pipelineDeviceAddressCaptureReplay: DeviceAddress,
}

PipelineIndirectDeviceAddressInfoNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	pipelineBindPoint: PipelineBindPoint,
	pipeline:          Pipeline,
}

BindPipelineIndirectCommandNV :: struct {
	pipelineAddress: DeviceAddress,
}

PhysicalDeviceLinearColorAttachmentFeaturesNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	linearColorAttachment: b32,
}

PhysicalDeviceImageCompressionControlSwapchainFeaturesEXT :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	imageCompressionControlSwapchain: b32,
}

ImageViewSampleWeightCreateInfoQCOM :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	filterCenter: Offset2D,
	filterSize:   Extent2D,
	numPhases:    u32,
}

PhysicalDeviceImageProcessingFeaturesQCOM :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	textureSampleWeighted: b32,
	textureBoxFilter:      b32,
	textureBlockMatch:     b32,
}

PhysicalDeviceImageProcessingPropertiesQCOM :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	maxWeightFilterPhases:    u32,
	maxWeightFilterDimension: Extent2D,
	maxBlockMatchRegion:      Extent2D,
	maxBoxFilterBlockSize:    Extent2D,
}

PhysicalDeviceNestedCommandBufferFeaturesEXT :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	nestedCommandBuffer:                b32,
	nestedCommandBufferRendering:       b32,
	nestedCommandBufferSimultaneousUse: b32,
}

PhysicalDeviceNestedCommandBufferPropertiesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	maxCommandBufferNestingLevel: u32,
}

ExternalMemoryAcquireUnmodifiedEXT :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	acquireUnmodifiedMemory: b32,
}

PhysicalDeviceExtendedDynamicState3FeaturesEXT :: struct {
	sType:                                                 StructureType,
	pNext:                                                 rawptr,
	extendedDynamicState3TessellationDomainOrigin:         b32,
	extendedDynamicState3DepthClampEnable:                 b32,
	extendedDynamicState3PolygonMode:                      b32,
	extendedDynamicState3RasterizationSamples:             b32,
	extendedDynamicState3SampleMask:                       b32,
	extendedDynamicState3AlphaToCoverageEnable:            b32,
	extendedDynamicState3AlphaToOneEnable:                 b32,
	extendedDynamicState3LogicOpEnable:                    b32,
	extendedDynamicState3ColorBlendEnable:                 b32,
	extendedDynamicState3ColorBlendEquation:               b32,
	extendedDynamicState3ColorWriteMask:                   b32,
	extendedDynamicState3RasterizationStream:              b32,
	extendedDynamicState3ConservativeRasterizationMode:    b32,
	extendedDynamicState3ExtraPrimitiveOverestimationSize: b32,
	extendedDynamicState3DepthClipEnable:                  b32,
	extendedDynamicState3SampleLocationsEnable:            b32,
	extendedDynamicState3ColorBlendAdvanced:               b32,
	extendedDynamicState3ProvokingVertexMode:              b32,
	extendedDynamicState3LineRasterizationMode:            b32,
	extendedDynamicState3LineStippleEnable:                b32,
	extendedDynamicState3DepthClipNegativeOneToOne:        b32,
	extendedDynamicState3ViewportWScalingEnable:           b32,
	extendedDynamicState3ViewportSwizzle:                  b32,
	extendedDynamicState3CoverageToColorEnable:            b32,
	extendedDynamicState3CoverageToColorLocation:          b32,
	extendedDynamicState3CoverageModulationMode:           b32,
	extendedDynamicState3CoverageModulationTableEnable:    b32,
	extendedDynamicState3CoverageModulationTable:          b32,
	extendedDynamicState3CoverageReductionMode:            b32,
	extendedDynamicState3RepresentativeFragmentTestEnable: b32,
	extendedDynamicState3ShadingRateImageEnable:           b32,
}

PhysicalDeviceExtendedDynamicState3PropertiesEXT :: struct {
	sType:                                StructureType,
	pNext:                                rawptr,
	dynamicPrimitiveTopologyUnrestricted: b32,
}

ColorBlendEquationEXT :: struct {
	srcColorBlendFactor: BlendFactor,
	dstColorBlendFactor: BlendFactor,
	colorBlendOp:        BlendOp,
	srcAlphaBlendFactor: BlendFactor,
	dstAlphaBlendFactor: BlendFactor,
	alphaBlendOp:        BlendOp,
}

ColorBlendAdvancedEXT :: struct {
	advancedBlendOp:  BlendOp,
	srcPremultiplied: b32,
	dstPremultiplied: b32,
	blendOverlap:     BlendOverlapEXT,
	clampResults:     b32,
}

PhysicalDeviceSubpassMergeFeedbackFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	subpassMergeFeedback: b32,
}

RenderPassCreationControlEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	disallowMerging: b32,
}

RenderPassCreationFeedbackInfoEXT :: struct {
	postMergeSubpassCount: u32,
}

RenderPassCreationFeedbackCreateInfoEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	pRenderPassFeedback: ^RenderPassCreationFeedbackInfoEXT,
}

RenderPassSubpassFeedbackInfoEXT :: struct {
	subpassMergeStatus: SubpassMergeStatusEXT,
	description:        [MAX_DESCRIPTION_SIZE]byte,
	postMergeIndex:     u32,
}

RenderPassSubpassFeedbackCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	pSubpassFeedback: ^RenderPassSubpassFeedbackInfoEXT,
}

DirectDriverLoadingInfoLUNARG :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  DirectDriverLoadingFlagsLUNARG,
	pfnGetInstanceProcAddr: ProcGetInstanceProcAddrLUNARG,
}

DirectDriverLoadingListLUNARG :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	mode:        DirectDriverLoadingModeLUNARG,
	driverCount: u32,
	pDrivers:    [^]DirectDriverLoadingInfoLUNARG,
}

PhysicalDeviceShaderModuleIdentifierFeaturesEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	shaderModuleIdentifier: b32,
}

PhysicalDeviceShaderModuleIdentifierPropertiesEXT :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	shaderModuleIdentifierAlgorithmUUID: [UUID_SIZE]u8,
}

PipelineShaderStageModuleIdentifierCreateInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	identifierSize: u32,
	pIdentifier:    ^u8,
}

ShaderModuleIdentifierEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	identifierSize: u32,
	identifier:     [MAX_SHADER_MODULE_IDENTIFIER_SIZE_EXT]u8,
}

PhysicalDeviceOpticalFlowFeaturesNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	opticalFlow: b32,
}

PhysicalDeviceOpticalFlowPropertiesNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	supportedOutputGridSizes:   OpticalFlowGridSizeFlagsNV,
	supportedHintGridSizes:     OpticalFlowGridSizeFlagsNV,
	hintSupported:              b32,
	costSupported:              b32,
	bidirectionalFlowSupported: b32,
	globalFlowSupported:        b32,
	minWidth:                   u32,
	minHeight:                  u32,
	maxWidth:                   u32,
	maxHeight:                  u32,
	maxNumRegionsOfInterest:    u32,
}

OpticalFlowImageFormatInfoNV :: struct {
	sType: StructureType,
	pNext: rawptr,
	usage: OpticalFlowUsageFlagsNV,
}

OpticalFlowImageFormatPropertiesNV :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	format: Format,
}

OpticalFlowSessionCreateInfoNV :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	width:            u32,
	height:           u32,
	imageFormat:      Format,
	flowVectorFormat: Format,
	costFormat:       Format,
	outputGridSize:   OpticalFlowGridSizeFlagsNV,
	hintGridSize:     OpticalFlowGridSizeFlagsNV,
	performanceLevel: OpticalFlowPerformanceLevelNV,
	flags:            OpticalFlowSessionCreateFlagsNV,
}

OpticalFlowSessionCreatePrivateDataInfoNV :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	id:           u32,
	size:         u32,
	pPrivateData: rawptr,
}

OpticalFlowExecuteInfoNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	flags:       OpticalFlowExecuteFlagsNV,
	regionCount: u32,
	pRegions:    [^]Rect2D,
}

PhysicalDeviceLegacyDitheringFeaturesEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	legacyDithering: b32,
}

PhysicalDeviceAntiLagFeaturesAMD :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	antiLag: b32,
}

AntiLagPresentationInfoAMD :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	stage:      AntiLagStageAMD,
	frameIndex: u64,
}

AntiLagDataAMD :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	mode:              AntiLagModeAMD,
	maxFPS:            u32,
	pPresentationInfo: ^AntiLagPresentationInfoAMD,
}

PhysicalDeviceShaderObjectFeaturesEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	shaderObject: b32,
}

PhysicalDeviceShaderObjectPropertiesEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	shaderBinaryUUID:    [UUID_SIZE]u8,
	shaderBinaryVersion: u32,
}

ShaderCreateInfoEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	flags:                  ShaderCreateFlagsEXT,
	stage:                  ShaderStageFlags,
	nextStage:              ShaderStageFlags,
	codeType:               ShaderCodeTypeEXT,
	codeSize:               int,
	pCode:                  rawptr,
	pName:                  cstring,
	setLayoutCount:         u32,
	pSetLayouts:            [^]DescriptorSetLayout,
	pushConstantRangeCount: u32,
	pPushConstantRanges:    [^]PushConstantRange,
	pSpecializationInfo:    ^SpecializationInfo,
}

DepthClampRangeEXT :: struct {
	minDepthClamp: f32,
	maxDepthClamp: f32,
}

PhysicalDeviceTilePropertiesFeaturesQCOM :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	tileProperties: b32,
}

TilePropertiesQCOM :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	tileSize:  Extent3D,
	apronSize: Extent2D,
	origin:    Offset2D,
}

PhysicalDeviceAmigoProfilingFeaturesSEC :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	amigoProfiling: b32,
}

AmigoProfilingSubmitInfoSEC :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	firstDrawTimestamp:  u64,
	swapBufferTimestamp: u64,
}

PhysicalDeviceMultiviewPerViewViewportsFeaturesQCOM :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	multiviewPerViewViewports: b32,
}

PhysicalDeviceRayTracingInvocationReorderPropertiesNV :: struct {
	sType:                                     StructureType,
	pNext:                                     rawptr,
	rayTracingInvocationReorderReorderingHint: RayTracingInvocationReorderModeNV,
}

PhysicalDeviceRayTracingInvocationReorderFeaturesNV :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	rayTracingInvocationReorder: b32,
}

PhysicalDeviceExtendedSparseAddressSpaceFeaturesNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	extendedSparseAddressSpace: b32,
}

PhysicalDeviceExtendedSparseAddressSpacePropertiesNV :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	extendedSparseAddressSpaceSize: DeviceSize,
	extendedSparseImageUsageFlags:  ImageUsageFlags,
	extendedSparseBufferUsageFlags: BufferUsageFlags,
}

PhysicalDeviceLegacyVertexAttributesFeaturesEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	legacyVertexAttributes: b32,
}

PhysicalDeviceLegacyVertexAttributesPropertiesEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	nativeUnalignedPerformance: b32,
}

LayerSettingEXT :: struct {
	pLayerName:   cstring,
	pSettingName: cstring,
	type:         LayerSettingTypeEXT,
	valueCount:   u32,
	pValues:      rawptr,
}

LayerSettingsCreateInfoEXT :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	settingCount: u32,
	pSettings:    [^]LayerSettingEXT,
}

PhysicalDeviceShaderCoreBuiltinsFeaturesARM :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	shaderCoreBuiltins: b32,
}

PhysicalDeviceShaderCoreBuiltinsPropertiesARM :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	shaderCoreMask:     u64,
	shaderCoreCount:    u32,
	shaderWarpsPerCore: u32,
}

PhysicalDevicePipelineLibraryGroupHandlesFeaturesEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	pipelineLibraryGroupHandles: b32,
}

PhysicalDeviceDynamicRenderingUnusedAttachmentsFeaturesEXT :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	dynamicRenderingUnusedAttachments: b32,
}

LatencySleepModeInfoNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	lowLatencyMode:    b32,
	lowLatencyBoost:   b32,
	minimumIntervalUs: u32,
}

LatencySleepInfoNV :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	signalSemaphore: Semaphore,
	value:           u64,
}

SetLatencyMarkerInfoNV :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	presentID: u64,
	marker:    LatencyMarkerNV,
}

LatencyTimingsFrameReportNV :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	presentID:                u64,
	inputSampleTimeUs:        u64,
	simStartTimeUs:           u64,
	simEndTimeUs:             u64,
	renderSubmitStartTimeUs:  u64,
	renderSubmitEndTimeUs:    u64,
	presentStartTimeUs:       u64,
	presentEndTimeUs:         u64,
	driverStartTimeUs:        u64,
	driverEndTimeUs:          u64,
	osRenderQueueStartTimeUs: u64,
	osRenderQueueEndTimeUs:   u64,
	gpuRenderStartTimeUs:     u64,
	gpuRenderEndTimeUs:       u64,
}

GetLatencyMarkerInfoNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	timingCount: u32,
	pTimings:    [^]LatencyTimingsFrameReportNV,
}

LatencySubmissionPresentIdNV :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	presentID: u64,
}

SwapchainLatencyCreateInfoNV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	latencyModeEnable: b32,
}

OutOfBandQueueTypeInfoNV :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	queueType: OutOfBandQueueTypeNV,
}

LatencySurfaceCapabilitiesNV :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	presentModeCount: u32,
	pPresentModes:    [^]PresentModeKHR,
}

PhysicalDeviceMultiviewPerViewRenderAreasFeaturesQCOM :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	multiviewPerViewRenderAreas: b32,
}

MultiviewPerViewRenderAreasRenderPassBeginInfoQCOM :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	perViewRenderAreaCount: u32,
	pPerViewRenderAreas:    [^]Rect2D,
}

PhysicalDevicePerStageDescriptorSetFeaturesNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	perStageDescriptorSet: b32,
	dynamicPipelineLayout: b32,
}

PhysicalDeviceImageProcessing2FeaturesQCOM :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	textureBlockMatch2: b32,
}

PhysicalDeviceImageProcessing2PropertiesQCOM :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	maxBlockMatchWindow: Extent2D,
}

SamplerBlockMatchWindowCreateInfoQCOM :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	windowExtent:      Extent2D,
	windowCompareMode: BlockMatchWindowCompareModeQCOM,
}

PhysicalDeviceCubicWeightsFeaturesQCOM :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	selectableCubicWeights: b32,
}

SamplerCubicWeightsCreateInfoQCOM :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	cubicWeights: CubicFilterWeightsQCOM,
}

BlitImageCubicWeightsInfoQCOM :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	cubicWeights: CubicFilterWeightsQCOM,
}

PhysicalDeviceYcbcrDegammaFeaturesQCOM :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	ycbcrDegamma: b32,
}

SamplerYcbcrConversionYcbcrDegammaCreateInfoQCOM :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	enableYDegamma:    b32,
	enableCbCrDegamma: b32,
}

PhysicalDeviceCubicClampFeaturesQCOM :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	cubicRangeClamp: b32,
}

PhysicalDeviceAttachmentFeedbackLoopDynamicStateFeaturesEXT :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	attachmentFeedbackLoopDynamicState: b32,
}

PhysicalDeviceLayeredDriverPropertiesMSFT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	underlyingAPI: LayeredDriverUnderlyingApiMSFT,
}

PhysicalDeviceDescriptorPoolOverallocationFeaturesNV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	descriptorPoolOverallocation: b32,
}

DisplaySurfaceStereoCreateInfoNV :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	stereoType: DisplaySurfaceStereoTypeNV,
}

DisplayModeStereoPropertiesNV :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	hdmi3DSupported: b32,
}

PhysicalDeviceRawAccessChainsFeaturesNV :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	shaderRawAccessChains: b32,
}

PhysicalDeviceCommandBufferInheritanceFeaturesNV :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	commandBufferInheritance: b32,
}

PhysicalDeviceShaderAtomicFloat16VectorFeaturesNV :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	shaderFloat16VectorAtomics: b32,
}

PhysicalDeviceShaderReplicatedCompositesFeaturesEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	shaderReplicatedComposites: b32,
}

PhysicalDeviceRayTracingValidationFeaturesNV :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	rayTracingValidation: b32,
}

PhysicalDeviceDeviceGeneratedCommandsFeaturesEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	deviceGeneratedCommands:        b32,
	dynamicGeneratedPipelineLayout: b32,
}

PhysicalDeviceDeviceGeneratedCommandsPropertiesEXT :: struct {
	sType:                                                StructureType,
	pNext:                                                rawptr,
	maxIndirectPipelineCount:                             u32,
	maxIndirectShaderObjectCount:                         u32,
	maxIndirectSequenceCount:                             u32,
	maxIndirectCommandsTokenCount:                        u32,
	maxIndirectCommandsTokenOffset:                       u32,
	maxIndirectCommandsIndirectStride:                    u32,
	supportedIndirectCommandsInputModes:                  IndirectCommandsInputModeFlagsEXT,
	supportedIndirectCommandsShaderStages:                ShaderStageFlags,
	supportedIndirectCommandsShaderStagesPipelineBinding: ShaderStageFlags,
	supportedIndirectCommandsShaderStagesShaderBinding:   ShaderStageFlags,
	deviceGeneratedCommandsTransformFeedback:             b32,
	deviceGeneratedCommandsMultiDrawIndirectCount:        b32,
}

GeneratedCommandsMemoryRequirementsInfoEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	indirectExecutionSet:   IndirectExecutionSetEXT,
	indirectCommandsLayout: IndirectCommandsLayoutEXT,
	maxSequenceCount:       u32,
	maxDrawCount:           u32,
}

IndirectExecutionSetPipelineInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	initialPipeline:  Pipeline,
	maxPipelineCount: u32,
}

IndirectExecutionSetShaderLayoutInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	setLayoutCount: u32,
	pSetLayouts:    [^]DescriptorSetLayout,
}

IndirectExecutionSetShaderInfoEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	shaderCount:            u32,
	pInitialShaders:        [^]ShaderEXT,
	pSetLayoutInfos:        [^]IndirectExecutionSetShaderLayoutInfoEXT,
	maxShaderCount:         u32,
	pushConstantRangeCount: u32,
	pPushConstantRanges:    [^]PushConstantRange,
}

IndirectExecutionSetInfoEXT :: struct #raw_union {
	pPipelineInfo: ^IndirectExecutionSetPipelineInfoEXT,
	pShaderInfo:   ^IndirectExecutionSetShaderInfoEXT,
}

IndirectExecutionSetCreateInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	type:  IndirectExecutionSetInfoTypeEXT,
	info:  IndirectExecutionSetInfoEXT,
}

GeneratedCommandsInfoEXT :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	shaderStages:           ShaderStageFlags,
	indirectExecutionSet:   IndirectExecutionSetEXT,
	indirectCommandsLayout: IndirectCommandsLayoutEXT,
	indirectAddress:        DeviceAddress,
	indirectAddressSize:    DeviceSize,
	preprocessAddress:      DeviceAddress,
	preprocessSize:         DeviceSize,
	maxSequenceCount:       u32,
	sequenceCountAddress:   DeviceAddress,
	maxDrawCount:           u32,
}

WriteIndirectExecutionSetPipelineEXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	index:    u32,
	pipeline: Pipeline,
}

IndirectCommandsPushConstantTokenEXT :: struct {
	updateRange: PushConstantRange,
}

IndirectCommandsVertexBufferTokenEXT :: struct {
	vertexBindingUnit: u32,
}

IndirectCommandsIndexBufferTokenEXT :: struct {
	mode: IndirectCommandsInputModeFlagsEXT,
}

IndirectCommandsExecutionSetTokenEXT :: struct {
	type:         IndirectExecutionSetInfoTypeEXT,
	shaderStages: ShaderStageFlags,
}

IndirectCommandsTokenDataEXT :: struct #raw_union {
	pPushConstant: ^IndirectCommandsPushConstantTokenEXT,
	pVertexBuffer: ^IndirectCommandsVertexBufferTokenEXT,
	pIndexBuffer:  ^IndirectCommandsIndexBufferTokenEXT,
	pExecutionSet: ^IndirectCommandsExecutionSetTokenEXT,
}

IndirectCommandsLayoutTokenEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	type:   IndirectCommandsTokenTypeEXT,
	data:   IndirectCommandsTokenDataEXT,
	offset: u32,
}

IndirectCommandsLayoutCreateInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	flags:          IndirectCommandsLayoutUsageFlagsEXT,
	shaderStages:   ShaderStageFlags,
	indirectStride: u32,
	pipelineLayout: PipelineLayout,
	tokenCount:     u32,
	pTokens:        [^]IndirectCommandsLayoutTokenEXT,
}

DrawIndirectCountIndirectCommandEXT :: struct {
	bufferAddress: DeviceAddress,
	stride:        u32,
	commandCount:  u32,
}

BindVertexBufferIndirectCommandEXT :: struct {
	bufferAddress: DeviceAddress,
	size:          u32,
	stride:        u32,
}

BindIndexBufferIndirectCommandEXT :: struct {
	bufferAddress: DeviceAddress,
	size:          u32,
	indexType:     IndexType,
}

GeneratedCommandsPipelineInfoEXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	pipeline: Pipeline,
}

GeneratedCommandsShaderInfoEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	shaderCount: u32,
	pShaders:    [^]ShaderEXT,
}

WriteIndirectExecutionSetShaderEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	index:  u32,
	shader: ShaderEXT,
}

PhysicalDeviceImageAlignmentControlFeaturesMESA :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	imageAlignmentControl: b32,
}

PhysicalDeviceImageAlignmentControlPropertiesMESA :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	supportedImageAlignmentMask: u32,
}

ImageAlignmentControlCreateInfoMESA :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	maximumRequestedAlignment: u32,
}

PhysicalDeviceDepthClampControlFeaturesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	depthClampControl: b32,
}

PipelineViewportDepthClampControlCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	depthClampMode:   DepthClampModeEXT,
	pDepthClampRange: ^DepthClampRangeEXT,
}

PhysicalDeviceHdrVividFeaturesHUAWEI :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	hdrVivid: b32,
}

HdrVividDynamicMetadataHUAWEI :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	dynamicMetadataSize: int,
	pDynamicMetadata:    rawptr,
}

CooperativeMatrixFlexibleDimensionsPropertiesNV :: struct {
	sType:                  StructureType,
	pNext:                  rawptr,
	MGranularity:           u32,
	NGranularity:           u32,
	KGranularity:           u32,
	AType:                  ComponentTypeKHR,
	BType:                  ComponentTypeKHR,
	CType:                  ComponentTypeKHR,
	ResultType:             ComponentTypeKHR,
	saturatingAccumulation: b32,
	scope:                  ScopeKHR,
	workgroupInvocations:   u32,
}

PhysicalDeviceCooperativeMatrix2FeaturesNV :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	cooperativeMatrixWorkgroupScope:       b32,
	cooperativeMatrixFlexibleDimensions:   b32,
	cooperativeMatrixReductions:           b32,
	cooperativeMatrixConversions:          b32,
	cooperativeMatrixPerElementOperations: b32,
	cooperativeMatrixTensorAddressing:     b32,
	cooperativeMatrixBlockLoads:           b32,
}

PhysicalDeviceCooperativeMatrix2PropertiesNV :: struct {
	sType:                                               StructureType,
	pNext:                                               rawptr,
	cooperativeMatrixWorkgroupScopeMaxWorkgroupSize:     u32,
	cooperativeMatrixFlexibleDimensionsMaxDimension:     u32,
	cooperativeMatrixWorkgroupScopeReservedSharedMemory: u32,
}

PhysicalDeviceVertexAttributeRobustnessFeaturesEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	vertexAttributeRobustness: b32,
}

AccelerationStructureBuildRangeInfoKHR :: struct {
	primitiveCount:  u32,
	primitiveOffset: u32,
	firstVertex:     u32,
	transformOffset: u32,
}

AccelerationStructureGeometryTrianglesDataKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	vertexFormat:  Format,
	vertexData:    DeviceOrHostAddressConstKHR,
	vertexStride:  DeviceSize,
	maxVertex:     u32,
	indexType:     IndexType,
	indexData:     DeviceOrHostAddressConstKHR,
	transformData: DeviceOrHostAddressConstKHR,
}

AccelerationStructureGeometryAabbsDataKHR :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	data:   DeviceOrHostAddressConstKHR,
	stride: DeviceSize,
}

AccelerationStructureGeometryInstancesDataKHR :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	arrayOfPointers: b32,
	data:            DeviceOrHostAddressConstKHR,
}

AccelerationStructureGeometryDataKHR :: struct #raw_union {
	triangles: AccelerationStructureGeometryTrianglesDataKHR,
	aabbs:     AccelerationStructureGeometryAabbsDataKHR,
	instances: AccelerationStructureGeometryInstancesDataKHR,
}

AccelerationStructureGeometryKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	geometryType: GeometryTypeKHR,
	geometry:     AccelerationStructureGeometryDataKHR,
	flags:        GeometryFlagsKHR,
}

AccelerationStructureBuildGeometryInfoKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	type:                     AccelerationStructureTypeKHR,
	flags:                    BuildAccelerationStructureFlagsKHR,
	mode:                     BuildAccelerationStructureModeKHR,
	srcAccelerationStructure: AccelerationStructureKHR,
	dstAccelerationStructure: AccelerationStructureKHR,
	geometryCount:            u32,
	pGeometries:              [^]AccelerationStructureGeometryKHR,
	ppGeometries:             ^[^]AccelerationStructureGeometryKHR,
	scratchData:              DeviceOrHostAddressKHR,
}

AccelerationStructureCreateInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	createFlags:   AccelerationStructureCreateFlagsKHR,
	buffer:        Buffer,
	offset:        DeviceSize,
	size:          DeviceSize,
	type:          AccelerationStructureTypeKHR,
	deviceAddress: DeviceAddress,
}

WriteDescriptorSetAccelerationStructureKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	accelerationStructureCount: u32,
	pAccelerationStructures:    [^]AccelerationStructureKHR,
}

PhysicalDeviceAccelerationStructureFeaturesKHR :: struct {
	sType:                                                 StructureType,
	pNext:                                                 rawptr,
	accelerationStructure:                                 b32,
	accelerationStructureCaptureReplay:                    b32,
	accelerationStructureIndirectBuild:                    b32,
	accelerationStructureHostCommands:                     b32,
	descriptorBindingAccelerationStructureUpdateAfterBind: b32,
}

PhysicalDeviceAccelerationStructurePropertiesKHR :: struct {
	sType:                                                      StructureType,
	pNext:                                                      rawptr,
	maxGeometryCount:                                           u64,
	maxInstanceCount:                                           u64,
	maxPrimitiveCount:                                          u64,
	maxPerStageDescriptorAccelerationStructures:                u32,
	maxPerStageDescriptorUpdateAfterBindAccelerationStructures: u32,
	maxDescriptorSetAccelerationStructures:                     u32,
	maxDescriptorSetUpdateAfterBindAccelerationStructures:      u32,
	minAccelerationStructureScratchOffsetAlignment:             u32,
}

AccelerationStructureDeviceAddressInfoKHR :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	accelerationStructure: AccelerationStructureKHR,
}

AccelerationStructureVersionInfoKHR :: struct {
	sType:        StructureType,
	pNext:        rawptr,
	pVersionData: ^u8,
}

CopyAccelerationStructureToMemoryInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   AccelerationStructureKHR,
	dst:   DeviceOrHostAddressKHR,
	mode:  CopyAccelerationStructureModeKHR,
}

CopyMemoryToAccelerationStructureInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   DeviceOrHostAddressConstKHR,
	dst:   AccelerationStructureKHR,
	mode:  CopyAccelerationStructureModeKHR,
}

CopyAccelerationStructureInfoKHR :: struct {
	sType: StructureType,
	pNext: rawptr,
	src:   AccelerationStructureKHR,
	dst:   AccelerationStructureKHR,
	mode:  CopyAccelerationStructureModeKHR,
}

AccelerationStructureBuildSizesInfoKHR :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	accelerationStructureSize: DeviceSize,
	updateScratchSize:         DeviceSize,
	buildScratchSize:          DeviceSize,
}

RayTracingShaderGroupCreateInfoKHR :: struct {
	sType:                           StructureType,
	pNext:                           rawptr,
	type:                            RayTracingShaderGroupTypeKHR,
	generalShader:                   u32,
	closestHitShader:                u32,
	anyHitShader:                    u32,
	intersectionShader:              u32,
	pShaderGroupCaptureReplayHandle: rawptr,
}

RayTracingPipelineInterfaceCreateInfoKHR :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	maxPipelineRayPayloadSize:      u32,
	maxPipelineRayHitAttributeSize: u32,
}

RayTracingPipelineCreateInfoKHR :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	flags:                        PipelineCreateFlags,
	stageCount:                   u32,
	pStages:                      [^]PipelineShaderStageCreateInfo,
	groupCount:                   u32,
	pGroups:                      [^]RayTracingShaderGroupCreateInfoKHR,
	maxPipelineRayRecursionDepth: u32,
	pLibraryInfo:                 ^PipelineLibraryCreateInfoKHR,
	pLibraryInterface:            ^RayTracingPipelineInterfaceCreateInfoKHR,
	pDynamicState:                ^PipelineDynamicStateCreateInfo,
	layout:                       PipelineLayout,
	basePipelineHandle:           Pipeline,
	basePipelineIndex:            i32,
}

PhysicalDeviceRayTracingPipelineFeaturesKHR :: struct {
	sType:                                                 StructureType,
	pNext:                                                 rawptr,
	rayTracingPipeline:                                    b32,
	rayTracingPipelineShaderGroupHandleCaptureReplay:      b32,
	rayTracingPipelineShaderGroupHandleCaptureReplayMixed: b32,
	rayTracingPipelineTraceRaysIndirect:                   b32,
	rayTraversalPrimitiveCulling:                          b32,
}

PhysicalDeviceRayTracingPipelinePropertiesKHR :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	shaderGroupHandleSize:              u32,
	maxRayRecursionDepth:               u32,
	maxShaderGroupStride:               u32,
	shaderGroupBaseAlignment:           u32,
	shaderGroupHandleCaptureReplaySize: u32,
	maxRayDispatchInvocationCount:      u32,
	shaderGroupHandleAlignment:         u32,
	maxRayHitAttributeSize:             u32,
}

StridedDeviceAddressRegionKHR :: struct {
	deviceAddress: DeviceAddress,
	stride:        DeviceSize,
	size:          DeviceSize,
}

TraceRaysIndirectCommandKHR :: struct {
	width:  u32,
	height: u32,
	depth:  u32,
}

PhysicalDeviceRayQueryFeaturesKHR :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	rayQuery: b32,
}

PhysicalDeviceMeshShaderFeaturesEXT :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	taskShader:                             b32,
	meshShader:                             b32,
	multiviewMeshShader:                    b32,
	primitiveFragmentShadingRateMeshShader: b32,
	meshShaderQueries:                      b32,
}

PhysicalDeviceMeshShaderPropertiesEXT :: struct {
	sType:                                 StructureType,
	pNext:                                 rawptr,
	maxTaskWorkGroupTotalCount:            u32,
	maxTaskWorkGroupCount:                 [3]u32,
	maxTaskWorkGroupInvocations:           u32,
	maxTaskWorkGroupSize:                  [3]u32,
	maxTaskPayloadSize:                    u32,
	maxTaskSharedMemorySize:               u32,
	maxTaskPayloadAndSharedMemorySize:     u32,
	maxMeshWorkGroupTotalCount:            u32,
	maxMeshWorkGroupCount:                 [3]u32,
	maxMeshWorkGroupInvocations:           u32,
	maxMeshWorkGroupSize:                  [3]u32,
	maxMeshSharedMemorySize:               u32,
	maxMeshPayloadAndSharedMemorySize:     u32,
	maxMeshOutputMemorySize:               u32,
	maxMeshPayloadAndOutputMemorySize:     u32,
	maxMeshOutputComponents:               u32,
	maxMeshOutputVertices:                 u32,
	maxMeshOutputPrimitives:               u32,
	maxMeshOutputLayers:                   u32,
	maxMeshMultiviewViewCount:             u32,
	meshOutputPerVertexGranularity:        u32,
	meshOutputPerPrimitiveGranularity:     u32,
	maxPreferredTaskWorkGroupInvocations:  u32,
	maxPreferredMeshWorkGroupInvocations:  u32,
	prefersLocalInvocationVertexOutput:    b32,
	prefersLocalInvocationPrimitiveOutput: b32,
	prefersCompactVertexOutput:            b32,
	prefersCompactPrimitiveOutput:         b32,
}

DrawMeshTasksIndirectCommandEXT :: struct {
	groupCountX: u32,
	groupCountY: u32,
	groupCountZ: u32,
}

Win32SurfaceCreateInfoKHR :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	flags:     Win32SurfaceCreateFlagsKHR,
	hinstance: HINSTANCE,
	hwnd:      HWND,
}

ImportMemoryWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalMemoryHandleTypeFlags,
	handle:     HANDLE,
	name:       LPCWSTR,
}

ExportMemoryWin32HandleInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pAttributes: [^]SECURITY_ATTRIBUTES,
	dwAccess:    DWORD,
	name:        LPCWSTR,
}

MemoryWin32HandlePropertiesKHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	memoryTypeBits: u32,
}

MemoryGetWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	memory:     DeviceMemory,
	handleType: ExternalMemoryHandleTypeFlags,
}

Win32KeyedMutexAcquireReleaseInfoKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	acquireCount:     u32,
	pAcquireSyncs:    [^]DeviceMemory,
	pAcquireKeys:     [^]u64,
	pAcquireTimeouts: [^]u32,
	releaseCount:     u32,
	pReleaseSyncs:    [^]DeviceMemory,
	pReleaseKeys:     [^]u64,
}

ImportSemaphoreWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	semaphore:  Semaphore,
	flags:      SemaphoreImportFlags,
	handleType: ExternalSemaphoreHandleTypeFlags,
	handle:     HANDLE,
	name:       LPCWSTR,
}

ExportSemaphoreWin32HandleInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pAttributes: [^]SECURITY_ATTRIBUTES,
	dwAccess:    DWORD,
	name:        LPCWSTR,
}

D3D12FenceSubmitInfoKHR :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	waitSemaphoreValuesCount:   u32,
	pWaitSemaphoreValues:       [^]u64,
	signalSemaphoreValuesCount: u32,
	pSignalSemaphoreValues:     [^]u64,
}

SemaphoreGetWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	semaphore:  Semaphore,
	handleType: ExternalSemaphoreHandleTypeFlags,
}

ImportFenceWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	fence:      Fence,
	flags:      FenceImportFlags,
	handleType: ExternalFenceHandleTypeFlags,
	handle:     HANDLE,
	name:       LPCWSTR,
}

ExportFenceWin32HandleInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pAttributes: [^]SECURITY_ATTRIBUTES,
	dwAccess:    DWORD,
	name:        LPCWSTR,
}

FenceGetWin32HandleInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	fence:      Fence,
	handleType: ExternalFenceHandleTypeFlags,
}

ImportMemoryWin32HandleInfoNV :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	handleType: ExternalMemoryHandleTypeFlagsNV,
	handle:     HANDLE,
}

ExportMemoryWin32HandleInfoNV :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	pAttributes: [^]SECURITY_ATTRIBUTES,
	dwAccess:    DWORD,
}

Win32KeyedMutexAcquireReleaseInfoNV :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	acquireCount:                u32,
	pAcquireSyncs:               [^]DeviceMemory,
	pAcquireKeys:                [^]u64,
	pAcquireTimeoutMilliseconds: [^]u32,
	releaseCount:                u32,
	pReleaseSyncs:               [^]DeviceMemory,
	pReleaseKeys:                [^]u64,
}

SurfaceFullScreenExclusiveInfoEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	fullScreenExclusive: FullScreenExclusiveEXT,
}

SurfaceCapabilitiesFullScreenExclusiveEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	fullScreenExclusiveSupported: b32,
}

SurfaceFullScreenExclusiveWin32InfoEXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	hmonitor: HMONITOR,
}

MetalSurfaceCreateInfoEXT :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	flags:  MetalSurfaceCreateFlagsEXT,
	pLayer: ^CAMetalLayer,
}

ExportMetalObjectCreateInfoEXT :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	exportObjectType: ExportMetalObjectTypeFlagsEXT,
}

ExportMetalObjectsInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
}

ExportMetalDeviceInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	mtlDevice: MTLDevice_id,
}

ExportMetalCommandQueueInfoEXT :: struct {
	sType:           StructureType,
	pNext:           rawptr,
	queue:           Queue,
	mtlCommandQueue: MTLCommandQueue_id,
}

ExportMetalBufferInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	memory:    DeviceMemory,
	mtlBuffer: MTLBuffer_id,
}

ImportMetalBufferInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	mtlBuffer: MTLBuffer_id,
}

ExportMetalTextureInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	image:      Image,
	imageView:  ImageView,
	bufferView: BufferView,
	plane:      ImageAspectFlags,
	mtlTexture: MTLTexture_id,
}

ImportMetalTextureInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	plane:      ImageAspectFlags,
	mtlTexture: MTLTexture_id,
}

ExportMetalIOSurfaceInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	image:     Image,
	ioSurface: IOSurfaceRef,
}

ImportMetalIOSurfaceInfoEXT :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	ioSurface: IOSurfaceRef,
}

ExportMetalSharedEventInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	semaphore:      Semaphore,
	event:          Event,
	mtlSharedEvent: MTLSharedEvent_id,
}

ImportMetalSharedEventInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	mtlSharedEvent: MTLSharedEvent_id,
}

MacOSSurfaceCreateInfoMVK :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: MacOSSurfaceCreateFlagsMVK,
	pView: rawptr,
}

IOSSurfaceCreateInfoMVK :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: IOSSurfaceCreateFlagsMVK,
	pView: rawptr,
}

WaylandSurfaceCreateInfoKHR :: struct {
	sType:   StructureType,
	pNext:   rawptr,
	flags:   WaylandSurfaceCreateFlagsKHR,
	display: ^wl_display,
	surface: ^wl_surface,
}

XlibSurfaceCreateInfoKHR :: struct {
	sType:  StructureType,
	pNext:  rawptr,
	flags:  XlibSurfaceCreateFlagsKHR,
	dpy:    ^XlibDisplay,
	window: XlibWindow,
}

XcbSurfaceCreateInfoKHR :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	flags:      XcbSurfaceCreateFlagsKHR,
	connection: ^xcb_connection_t,
	window:     xcb_window_t,
}

VideoAV1ColorConfigFlags :: struct {
	bitfield: u32,
}

VideoAV1ColorConfig :: struct {
	flags:                    VideoAV1ColorConfigFlags,
	BitDepth:                 u8,
	subsampling_x:            u8,
	subsampling_y:            u8,
	reserved1:                u8,
	color_primaries:          VideoAV1ColorPrimaries,
	transfer_characteristics: VideoAV1TransferCharacteristics,
	matrix_coefficients:      VideoAV1MatrixCoefficients,
	chroma_sample_position:   VideoAV1ChromaSamplePosition,
}

VideoAV1TimingInfoFlags :: struct {
	bitfield: u32,
}

VideoAV1TimingInfo :: struct {
	flags:                         VideoAV1TimingInfoFlags,
	num_units_in_display_tick:     u32,
	time_scale:                    u32,
	num_ticks_per_picture_minus_1: u32,
}

VideoAV1LoopFilterFlags :: struct {
	bitfield: u32,
}

VideoAV1LoopFilter :: struct {
	flags:                   VideoAV1LoopFilterFlags,
	loop_filter_level:       [VIDEO_AV1_MAX_LOOP_FILTER_STRENGTHS]u8,
	loop_filter_sharpness:   u8,
	update_ref_delta:        u8,
	loop_filter_ref_deltas:  [VIDEO_AV1_TOTAL_REFS_PER_FRAME]i8,
	update_mode_delta:       u8,
	loop_filter_mode_deltas: [VIDEO_AV1_LOOP_FILTER_ADJUSTMENTS]i8,
}

VideoAV1QuantizationFlags :: struct {
	bitfield: u32,
}

VideoAV1Quantization :: struct {
	flags:      VideoAV1QuantizationFlags,
	base_q_idx: u8,
	DeltaQYDc:  i8,
	DeltaQUDc:  i8,
	DeltaQUAc:  i8,
	DeltaQVDc:  i8,
	DeltaQVAc:  i8,
	qm_y:       u8,
	qm_u:       u8,
	qm_v:       u8,
}

VideoAV1Segmentation :: struct {
	FeatureEnabled: [VIDEO_AV1_MAX_SEGMENTS]u8,
	FeatureData:    [VIDEO_AV1_MAX_SEGMENTS][VIDEO_AV1_SEG_LVL_MAX]i16,
}

VideoAV1TileInfoFlags :: struct {
	bitfield: u32,
}

VideoAV1TileInfo :: struct {
	flags:                   VideoAV1TileInfoFlags,
	TileCols:                u8,
	TileRows:                u8,
	context_update_tile_id:  u16,
	tile_size_bytes_minus_1: u8,
	reserved1:               [7]u8,
	pMiColStarts:            [^]u16,
	pMiRowStarts:            [^]u16,
	pWidthInSbsMinus1:       ^u16,
	pHeightInSbsMinus1:      ^u16,
}

VideoAV1CDEF :: struct {
	cdef_damping_minus_3: u8,
	cdef_bits:            u8,
	cdef_y_pri_strength:  [VIDEO_AV1_MAX_CDEF_FILTER_STRENGTHS]u8,
	cdef_y_sec_strength:  [VIDEO_AV1_MAX_CDEF_FILTER_STRENGTHS]u8,
	cdef_uv_pri_strength: [VIDEO_AV1_MAX_CDEF_FILTER_STRENGTHS]u8,
	cdef_uv_sec_strength: [VIDEO_AV1_MAX_CDEF_FILTER_STRENGTHS]u8,
}

VideoAV1LoopRestoration :: struct {
	FrameRestorationType: [VIDEO_AV1_MAX_NUM_PLANES]VideoAV1FrameRestorationType,
	LoopRestorationSize:  [VIDEO_AV1_MAX_NUM_PLANES]u16,
}

VideoAV1GlobalMotion :: struct {
	GmType:    [VIDEO_AV1_NUM_REF_FRAMES]u8,
	gm_params: [VIDEO_AV1_NUM_REF_FRAMES][VIDEO_AV1_GLOBAL_MOTION_PARAMS]i32,
}

VideoAV1FilmGrainFlags :: struct {
	bitfield: u32,
}

VideoAV1FilmGrain :: struct {
	flags:                     VideoAV1FilmGrainFlags,
	grain_scaling_minus_8:     u8,
	ar_coeff_lag:              u8,
	ar_coeff_shift_minus_6:    u8,
	grain_scale_shift:         u8,
	grain_seed:                u16,
	film_grain_params_ref_idx: u8,
	num_y_points:              u8,
	point_y_value:             [VIDEO_AV1_MAX_NUM_Y_POINTS]u8,
	point_y_scaling:           [VIDEO_AV1_MAX_NUM_Y_POINTS]u8,
	num_cb_points:             u8,
	point_cb_value:            [VIDEO_AV1_MAX_NUM_CB_POINTS]u8,
	point_cb_scaling:          [VIDEO_AV1_MAX_NUM_CB_POINTS]u8,
	num_cr_points:             u8,
	point_cr_value:            [VIDEO_AV1_MAX_NUM_CR_POINTS]u8,
	point_cr_scaling:          [VIDEO_AV1_MAX_NUM_CR_POINTS]u8,
	ar_coeffs_y_plus_128:      [VIDEO_AV1_MAX_NUM_POS_LUMA]i8,
	ar_coeffs_cb_plus_128:     [VIDEO_AV1_MAX_NUM_POS_CHROMA]i8,
	ar_coeffs_cr_plus_128:     [VIDEO_AV1_MAX_NUM_POS_CHROMA]i8,
	cb_mult:                   u8,
	cb_luma_mult:              u8,
	cb_offset:                 u16,
	cr_mult:                   u8,
	cr_luma_mult:              u8,
	cr_offset:                 u16,
}

VideoAV1SequenceHeaderFlags :: struct {
	bitfield: u32,
}

VideoAV1SequenceHeader :: struct {
	flags:                              VideoAV1SequenceHeaderFlags,
	seq_profile:                        VideoAV1Profile,
	frame_width_bits_minus_1:           u8,
	frame_height_bits_minus_1:          u8,
	max_frame_width_minus_1:            u16,
	max_frame_height_minus_1:           u16,
	delta_frame_id_length_minus_2:      u8,
	additional_frame_id_length_minus_1: u8,
	order_hint_bits_minus_1:            u8,
	seq_force_integer_mv:               u8,
	seq_force_screen_content_tools:     u8,
	reserved1:                          [5]u8,
	pColorConfig:                       ^VideoAV1ColorConfig,
	pTimingInfo:                        ^VideoAV1TimingInfo,
}

VideoDecodeAV1PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeAV1PictureInfo :: struct {
	flags:                VideoDecodeAV1PictureInfoFlags,
	frame_type:           VideoAV1FrameType,
	current_frame_id:     u32,
	OrderHint:            u8,
	primary_ref_frame:    u8,
	refresh_frame_flags:  u8,
	reserved1:            u8,
	interpolation_filter: VideoAV1InterpolationFilter,
	TxMode:               VideoAV1TxMode,
	delta_q_res:          u8,
	delta_lf_res:         u8,
	SkipModeFrame:        [VIDEO_AV1_SKIP_MODE_FRAMES]u8,
	coded_denom:          u8,
	reserved2:            [3]u8,
	OrderHints:           [VIDEO_AV1_NUM_REF_FRAMES]u8,
	expectedFrameId:      [VIDEO_AV1_NUM_REF_FRAMES]u32,
	pTileInfo:            ^VideoAV1TileInfo,
	pQuantization:        ^VideoAV1Quantization,
	pSegmentation:        ^VideoAV1Segmentation,
	pLoopFilter:          ^VideoAV1LoopFilter,
	pCDEF:                ^VideoAV1CDEF,
	pLoopRestoration:     ^VideoAV1LoopRestoration,
	pGlobalMotion:        ^VideoAV1GlobalMotion,
	pFilmGrain:           ^VideoAV1FilmGrain,
}

VideoDecodeAV1ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeAV1ReferenceInfo :: struct {
	flags:            VideoDecodeAV1ReferenceInfoFlags,
	frame_type:       u8,
	RefFrameSignBias: u8,
	OrderHint:        u8,
	SavedOrderHints:  [VIDEO_AV1_NUM_REF_FRAMES]u8,
}

VideoEncodeAV1DecoderModelInfo :: struct {
	buffer_delay_length_minus_1:            u8,
	buffer_removal_time_length_minus_1:     u8,
	frame_presentation_time_length_minus_1: u8,
	reserved1:                              u8,
	num_units_in_decoding_tick:             u32,
}

VideoEncodeAV1ExtensionHeader :: struct {
	temporal_id: u8,
	spatial_id:  u8,
}

VideoEncodeAV1OperatingPointInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeAV1OperatingPointInfo :: struct {
	flags:                         VideoEncodeAV1OperatingPointInfoFlags,
	operating_point_idc:           u16,
	seq_level_idx:                 u8,
	seq_tier:                      u8,
	decoder_buffer_delay:          u32,
	encoder_buffer_delay:          u32,
	initial_display_delay_minus_1: u8,
}

VideoEncodeAV1PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeAV1PictureInfo :: struct {
	flags:                   VideoEncodeAV1PictureInfoFlags,
	frame_type:              VideoAV1FrameType,
	frame_presentation_time: u32,
	current_frame_id:        u32,
	order_hint:              u8,
	primary_ref_frame:       u8,
	refresh_frame_flags:     u8,
	coded_denom:             u8,
	render_width_minus_1:    u16,
	render_height_minus_1:   u16,
	interpolation_filter:    VideoAV1InterpolationFilter,
	TxMode:                  VideoAV1TxMode,
	delta_q_res:             u8,
	delta_lf_res:            u8,
	ref_order_hint:          [VIDEO_AV1_NUM_REF_FRAMES]u8,
	ref_frame_idx:           [VIDEO_AV1_REFS_PER_FRAME]i8,
	reserved1:               [3]u8,
	delta_frame_id_minus_1:  [VIDEO_AV1_REFS_PER_FRAME]u32,
	pTileInfo:               ^VideoAV1TileInfo,
	pQuantization:           ^VideoAV1Quantization,
	pSegmentation:           ^VideoAV1Segmentation,
	pLoopFilter:             ^VideoAV1LoopFilter,
	pCDEF:                   ^VideoAV1CDEF,
	pLoopRestoration:        ^VideoAV1LoopRestoration,
	pGlobalMotion:           ^VideoAV1GlobalMotion,
	pExtensionHeader:        ^VideoEncodeAV1ExtensionHeader,
	pBufferRemovalTimes:     [^]u32,
}

VideoEncodeAV1ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeAV1ReferenceInfo :: struct {
	flags:            VideoEncodeAV1ReferenceInfoFlags,
	RefFrameId:       u32,
	frame_type:       VideoAV1FrameType,
	OrderHint:        u8,
	reserved1:        [3]u8,
	pExtensionHeader: ^VideoEncodeAV1ExtensionHeader,
}

VideoH264SpsVuiFlags :: struct {
	bitfield: u32,
}

VideoH264HrdParameters :: struct {
	cpb_cnt_minus1:                          u8,
	bit_rate_scale:                          u8,
	cpb_size_scale:                          u8,
	reserved1:                               u8,
	bit_rate_value_minus1:                   [VIDEO_H264_CPB_CNT_LIST_SIZE]u32,
	cpb_size_value_minus1:                   [VIDEO_H264_CPB_CNT_LIST_SIZE]u32,
	cbr_flag:                                [VIDEO_H264_CPB_CNT_LIST_SIZE]u8,
	initial_cpb_removal_delay_length_minus1: u32,
	cpb_removal_delay_length_minus1:         u32,
	dpb_output_delay_length_minus1:          u32,
	time_offset_length:                      u32,
}

VideoH264SequenceParameterSetVui :: struct {
	flags:                               VideoH264SpsVuiFlags,
	aspect_ratio_idc:                    VideoH264AspectRatioIdc,
	sar_width:                           u16,
	sar_height:                          u16,
	video_format:                        u8,
	colour_primaries:                    u8,
	transfer_characteristics:            u8,
	matrix_coefficients:                 u8,
	num_units_in_tick:                   u32,
	time_scale:                          u32,
	max_num_reorder_frames:              u8,
	max_dec_frame_buffering:             u8,
	chroma_sample_loc_type_top_field:    u8,
	chroma_sample_loc_type_bottom_field: u8,
	reserved1:                           u32,
	pHrdParameters:                      [^]VideoH264HrdParameters,
}

VideoH264SpsFlags :: struct {
	bitfield: u32,
}

VideoH264ScalingLists :: struct {
	scaling_list_present_mask:       u16,
	use_default_scaling_matrix_mask: u16,
	ScalingList4x4:                  [VIDEO_H264_SCALING_LIST_4X4_NUM_LISTS][VIDEO_H264_SCALING_LIST_4X4_NUM_ELEMENTS]u8,
	ScalingList8x8:                  [VIDEO_H264_SCALING_LIST_8X8_NUM_LISTS][VIDEO_H264_SCALING_LIST_8X8_NUM_ELEMENTS]u8,
}

VideoH264SequenceParameterSet :: struct {
	flags:                                 VideoH264SpsFlags,
	profile_idc:                           VideoH264ProfileIdc,
	level_idc:                             VideoH264LevelIdc,
	chroma_format_idc:                     VideoH264ChromaFormatIdc,
	seq_parameter_set_id:                  u8,
	bit_depth_luma_minus8:                 u8,
	bit_depth_chroma_minus8:               u8,
	log2_max_frame_num_minus4:             u8,
	pic_order_cnt_type:                    VideoH264PocType,
	offset_for_non_ref_pic:                i32,
	offset_for_top_to_bottom_field:        i32,
	log2_max_pic_order_cnt_lsb_minus4:     u8,
	num_ref_frames_in_pic_order_cnt_cycle: u8,
	max_num_ref_frames:                    u8,
	reserved1:                             u8,
	pic_width_in_mbs_minus1:               u32,
	pic_height_in_map_units_minus1:        u32,
	frame_crop_left_offset:                u32,
	frame_crop_right_offset:               u32,
	frame_crop_top_offset:                 u32,
	frame_crop_bottom_offset:              u32,
	reserved2:                             u32,
	pOffsetForRefFrame:                    ^i32,
	pScalingLists:                         [^]VideoH264ScalingLists,
	pSequenceParameterSetVui:              ^VideoH264SequenceParameterSetVui,
}

VideoH264PpsFlags :: struct {
	bitfield: u32,
}

VideoH264PictureParameterSet :: struct {
	flags:                                VideoH264PpsFlags,
	seq_parameter_set_id:                 u8,
	pic_parameter_set_id:                 u8,
	num_ref_idx_l0_default_active_minus1: u8,
	num_ref_idx_l1_default_active_minus1: u8,
	weighted_bipred_idc:                  VideoH264WeightedBipredIdc,
	pic_init_qp_minus26:                  i8,
	pic_init_qs_minus26:                  i8,
	chroma_qp_index_offset:               i8,
	second_chroma_qp_index_offset:        i8,
	pScalingLists:                        [^]VideoH264ScalingLists,
}

VideoDecodeH264PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeH264PictureInfo :: struct {
	flags:                VideoDecodeH264PictureInfoFlags,
	seq_parameter_set_id: u8,
	pic_parameter_set_id: u8,
	reserved1:            u8,
	reserved2:            u8,
	frame_num:            u16,
	idr_pic_id:           u16,
	PicOrderCnt:          [VIDEO_DECODE_H264_FIELD_ORDER_COUNT_LIST_SIZE]i32,
}

VideoDecodeH264ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeH264ReferenceInfo :: struct {
	flags:       VideoDecodeH264ReferenceInfoFlags,
	FrameNum:    u16,
	reserved:    u16,
	PicOrderCnt: [VIDEO_DECODE_H264_FIELD_ORDER_COUNT_LIST_SIZE]i32,
}

VideoEncodeH264WeightTableFlags :: struct {
	luma_weight_l0_flag:   u32,
	chroma_weight_l0_flag: u32,
	luma_weight_l1_flag:   u32,
	chroma_weight_l1_flag: u32,
}

VideoEncodeH264WeightTable :: struct {
	flags:                    VideoEncodeH264WeightTableFlags,
	luma_log2_weight_denom:   u8,
	chroma_log2_weight_denom: u8,
	luma_weight_l0:           [VIDEO_H264_MAX_NUM_LIST_REF]i8,
	luma_offset_l0:           [VIDEO_H264_MAX_NUM_LIST_REF]i8,
	chroma_weight_l0:         [VIDEO_H264_MAX_NUM_LIST_REF][VIDEO_H264_MAX_CHROMA_PLANES]i8,
	chroma_offset_l0:         [VIDEO_H264_MAX_NUM_LIST_REF][VIDEO_H264_MAX_CHROMA_PLANES]i8,
	luma_weight_l1:           [VIDEO_H264_MAX_NUM_LIST_REF]i8,
	luma_offset_l1:           [VIDEO_H264_MAX_NUM_LIST_REF]i8,
	chroma_weight_l1:         [VIDEO_H264_MAX_NUM_LIST_REF][VIDEO_H264_MAX_CHROMA_PLANES]i8,
	chroma_offset_l1:         [VIDEO_H264_MAX_NUM_LIST_REF][VIDEO_H264_MAX_CHROMA_PLANES]i8,
}

VideoEncodeH264SliceHeaderFlags :: struct {
	bitfield: u32,
}

VideoEncodeH264PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH264ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH264ReferenceListsInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH264RefListModEntry :: struct {
	modification_of_pic_nums_idc: VideoH264ModificationOfPicNumsIdc,
	abs_diff_pic_num_minus1:      u16,
	long_term_pic_num:            u16,
}

VideoEncodeH264RefPicMarkingEntry :: struct {
	memory_management_control_operation: VideoH264MemMgmtControlOp,
	difference_of_pic_nums_minus1:       u16,
	long_term_pic_num:                   u16,
	long_term_frame_idx:                 u16,
	max_long_term_frame_idx_plus1:       u16,
}

VideoEncodeH264ReferenceListsInfo :: struct {
	flags:                        VideoEncodeH264ReferenceListsInfoFlags,
	num_ref_idx_l0_active_minus1: u8,
	num_ref_idx_l1_active_minus1: u8,
	RefPicList0:                  [VIDEO_H264_MAX_NUM_LIST_REF]u8,
	RefPicList1:                  [VIDEO_H264_MAX_NUM_LIST_REF]u8,
	refList0ModOpCount:           u8,
	refList1ModOpCount:           u8,
	refPicMarkingOpCount:         u8,
	reserved1:                    [7]u8,
	pRefList0ModOperations:       [^]VideoEncodeH264RefListModEntry,
	pRefList1ModOperations:       [^]VideoEncodeH264RefListModEntry,
	pRefPicMarkingOperations:     [^]VideoEncodeH264RefPicMarkingEntry,
}

VideoEncodeH264PictureInfo :: struct {
	flags:                VideoEncodeH264PictureInfoFlags,
	seq_parameter_set_id: u8,
	pic_parameter_set_id: u8,
	idr_pic_id:           u16,
	primary_pic_type:     VideoH264PictureType,
	frame_num:            u32,
	PicOrderCnt:          i32,
	temporal_id:          u8,
	reserved1:            [3]u8,
	pRefLists:            [^]VideoEncodeH264ReferenceListsInfo,
}

VideoEncodeH264ReferenceInfo :: struct {
	flags:               VideoEncodeH264ReferenceInfoFlags,
	primary_pic_type:    VideoH264PictureType,
	FrameNum:            u32,
	PicOrderCnt:         i32,
	long_term_pic_num:   u16,
	long_term_frame_idx: u16,
	temporal_id:         u8,
}

VideoEncodeH264SliceHeader :: struct {
	flags:                         VideoEncodeH264SliceHeaderFlags,
	first_mb_in_slice:             u32,
	slice_type:                    VideoH264SliceType,
	slice_alpha_c0_offset_div2:    i8,
	slice_beta_offset_div2:        i8,
	slice_qp_delta:                i8,
	reserved1:                     u8,
	cabac_init_idc:                VideoH264CabacInitIdc,
	disable_deblocking_filter_idc: VideoH264DisableDeblockingFilterIdc,
	pWeightTable:                  [^]VideoEncodeH264WeightTable,
}

VideoH265DecPicBufMgr :: struct {
	max_latency_increase_plus1:   [VIDEO_H265_SUBLAYERS_LIST_SIZE]u32,
	max_dec_pic_buffering_minus1: [VIDEO_H265_SUBLAYERS_LIST_SIZE]u8,
	max_num_reorder_pics:         [VIDEO_H265_SUBLAYERS_LIST_SIZE]u8,
}

VideoH265SubLayerHrdParameters :: struct {
	bit_rate_value_minus1:    [VIDEO_H265_CPB_CNT_LIST_SIZE]u32,
	cpb_size_value_minus1:    [VIDEO_H265_CPB_CNT_LIST_SIZE]u32,
	cpb_size_du_value_minus1: [VIDEO_H265_CPB_CNT_LIST_SIZE]u32,
	bit_rate_du_value_minus1: [VIDEO_H265_CPB_CNT_LIST_SIZE]u32,
	cbr_flag:                 u32,
}

VideoH265HrdFlags :: struct {
	bitfield: u32,
}

VideoH265HrdParameters :: struct {
	flags:                                        VideoH265HrdFlags,
	tick_divisor_minus2:                          u8,
	du_cpb_removal_delay_increment_length_minus1: u8,
	dpb_output_delay_du_length_minus1:            u8,
	bit_rate_scale:                               u8,
	cpb_size_scale:                               u8,
	cpb_size_du_scale:                            u8,
	initial_cpb_removal_delay_length_minus1:      u8,
	au_cpb_removal_delay_length_minus1:           u8,
	dpb_output_delay_length_minus1:               u8,
	cpb_cnt_minus1:                               [VIDEO_H265_SUBLAYERS_LIST_SIZE]u8,
	elemental_duration_in_tc_minus1:              [VIDEO_H265_SUBLAYERS_LIST_SIZE]u16,
	reserved:                                     [3]u16,
	pSubLayerHrdParametersNal:                    ^VideoH265SubLayerHrdParameters,
	pSubLayerHrdParametersVcl:                    ^VideoH265SubLayerHrdParameters,
}

VideoH265VpsFlags :: struct {
	bitfield: u32,
}

VideoH265ProfileTierLevelFlags :: struct {
	bitfield: u32,
}

VideoH265ProfileTierLevel :: struct {
	flags:               VideoH265ProfileTierLevelFlags,
	general_profile_idc: VideoH265ProfileIdc,
	general_level_idc:   VideoH265LevelIdc,
}

VideoH265VideoParameterSet :: struct {
	flags:                             VideoH265VpsFlags,
	vps_video_parameter_set_id:        u8,
	vps_max_sub_layers_minus1:         u8,
	reserved1:                         u8,
	reserved2:                         u8,
	vps_num_units_in_tick:             u32,
	vps_time_scale:                    u32,
	vps_num_ticks_poc_diff_one_minus1: u32,
	reserved3:                         u32,
	pDecPicBufMgr:                     ^VideoH265DecPicBufMgr,
	pHrdParameters:                    [^]VideoH265HrdParameters,
	pProfileTierLevel:                 ^VideoH265ProfileTierLevel,
}

VideoH265ScalingLists :: struct {
	ScalingList4x4:         [VIDEO_H265_SCALING_LIST_4X4_NUM_LISTS][VIDEO_H265_SCALING_LIST_4X4_NUM_ELEMENTS]u8,
	ScalingList8x8:         [VIDEO_H265_SCALING_LIST_8X8_NUM_LISTS][VIDEO_H265_SCALING_LIST_8X8_NUM_ELEMENTS]u8,
	ScalingList16x16:       [VIDEO_H265_SCALING_LIST_16X16_NUM_LISTS][VIDEO_H265_SCALING_LIST_16X16_NUM_ELEMENTS]u8,
	ScalingList32x32:       [VIDEO_H265_SCALING_LIST_32X32_NUM_LISTS][VIDEO_H265_SCALING_LIST_32X32_NUM_ELEMENTS]u8,
	ScalingListDCCoef16x16: [VIDEO_H265_SCALING_LIST_16X16_NUM_LISTS]u8,
	ScalingListDCCoef32x32: [VIDEO_H265_SCALING_LIST_32X32_NUM_LISTS]u8,
}

VideoH265SpsVuiFlags :: struct {
	bitfield: u32,
}

VideoH265SequenceParameterSetVui :: struct {
	flags:                               VideoH265SpsVuiFlags,
	aspect_ratio_idc:                    VideoH265AspectRatioIdc,
	sar_width:                           u16,
	sar_height:                          u16,
	video_format:                        u8,
	colour_primaries:                    u8,
	transfer_characteristics:            u8,
	matrix_coeffs:                       u8,
	chroma_sample_loc_type_top_field:    u8,
	chroma_sample_loc_type_bottom_field: u8,
	reserved1:                           u8,
	reserved2:                           u8,
	def_disp_win_left_offset:            u16,
	def_disp_win_right_offset:           u16,
	def_disp_win_top_offset:             u16,
	def_disp_win_bottom_offset:          u16,
	vui_num_units_in_tick:               u32,
	vui_time_scale:                      u32,
	vui_num_ticks_poc_diff_one_minus1:   u32,
	min_spatial_segmentation_idc:        u16,
	reserved3:                           u16,
	max_bytes_per_pic_denom:             u8,
	max_bits_per_min_cu_denom:           u8,
	log2_max_mv_length_horizontal:       u8,
	log2_max_mv_length_vertical:         u8,
	pHrdParameters:                      [^]VideoH265HrdParameters,
}

VideoH265PredictorPaletteEntries :: struct {
	PredictorPaletteEntries: [VIDEO_H265_PREDICTOR_PALETTE_COMPONENTS_LIST_SIZE][VIDEO_H265_PREDICTOR_PALETTE_COMP_ENTRIES_LIST_SIZE]u16,
}

VideoH265SpsFlags :: struct {
	bitfield: u32,
}

VideoH265ShortTermRefPicSetFlags :: struct {
	bitfield: u32,
}

VideoH265ShortTermRefPicSet :: struct {
	flags:                    VideoH265ShortTermRefPicSetFlags,
	delta_idx_minus1:         u32,
	use_delta_flag:           u16,
	abs_delta_rps_minus1:     u16,
	used_by_curr_pic_flag:    u16,
	used_by_curr_pic_s0_flag: u16,
	used_by_curr_pic_s1_flag: u16,
	reserved1:                u16,
	reserved2:                u8,
	reserved3:                u8,
	num_negative_pics:        u8,
	num_positive_pics:        u8,
	delta_poc_s0_minus1:      [VIDEO_H265_MAX_DPB_SIZE]u16,
	delta_poc_s1_minus1:      [VIDEO_H265_MAX_DPB_SIZE]u16,
}

VideoH265LongTermRefPicsSps :: struct {
	used_by_curr_pic_lt_sps_flag: u32,
	lt_ref_pic_poc_lsb_sps:       [VIDEO_H265_MAX_LONG_TERM_REF_PICS_SPS]u32,
}

VideoH265SequenceParameterSet :: struct {
	flags:                                         VideoH265SpsFlags,
	chroma_format_idc:                             VideoH265ChromaFormatIdc,
	pic_width_in_luma_samples:                     u32,
	pic_height_in_luma_samples:                    u32,
	sps_video_parameter_set_id:                    u8,
	sps_max_sub_layers_minus1:                     u8,
	sps_seq_parameter_set_id:                      u8,
	bit_depth_luma_minus8:                         u8,
	bit_depth_chroma_minus8:                       u8,
	log2_max_pic_order_cnt_lsb_minus4:             u8,
	log2_min_luma_coding_block_size_minus3:        u8,
	log2_diff_max_min_luma_coding_block_size:      u8,
	log2_min_luma_transform_block_size_minus2:     u8,
	log2_diff_max_min_luma_transform_block_size:   u8,
	max_transform_hierarchy_depth_inter:           u8,
	max_transform_hierarchy_depth_intra:           u8,
	num_short_term_ref_pic_sets:                   u8,
	num_long_term_ref_pics_sps:                    u8,
	pcm_sample_bit_depth_luma_minus1:              u8,
	pcm_sample_bit_depth_chroma_minus1:            u8,
	log2_min_pcm_luma_coding_block_size_minus3:    u8,
	log2_diff_max_min_pcm_luma_coding_block_size:  u8,
	reserved1:                                     u8,
	reserved2:                                     u8,
	palette_max_size:                              u8,
	delta_palette_max_predictor_size:              u8,
	motion_vector_resolution_control_idc:          u8,
	sps_num_palette_predictor_initializers_minus1: u8,
	conf_win_left_offset:                          u32,
	conf_win_right_offset:                         u32,
	conf_win_top_offset:                           u32,
	conf_win_bottom_offset:                        u32,
	pProfileTierLevel:                             ^VideoH265ProfileTierLevel,
	pDecPicBufMgr:                                 ^VideoH265DecPicBufMgr,
	pScalingLists:                                 [^]VideoH265ScalingLists,
	pShortTermRefPicSet:                           ^VideoH265ShortTermRefPicSet,
	pLongTermRefPicsSps:                           [^]VideoH265LongTermRefPicsSps,
	pSequenceParameterSetVui:                      ^VideoH265SequenceParameterSetVui,
	pPredictorPaletteEntries:                      [^]VideoH265PredictorPaletteEntries,
}

VideoH265PpsFlags :: struct {
	bitfield: u32,
}

VideoH265PictureParameterSet :: struct {
	flags:                                     VideoH265PpsFlags,
	pps_pic_parameter_set_id:                  u8,
	pps_seq_parameter_set_id:                  u8,
	sps_video_parameter_set_id:                u8,
	num_extra_slice_header_bits:               u8,
	num_ref_idx_l0_default_active_minus1:      u8,
	num_ref_idx_l1_default_active_minus1:      u8,
	init_qp_minus26:                           i8,
	diff_cu_qp_delta_depth:                    u8,
	pps_cb_qp_offset:                          i8,
	pps_cr_qp_offset:                          i8,
	pps_beta_offset_div2:                      i8,
	pps_tc_offset_div2:                        i8,
	log2_parallel_merge_level_minus2:          u8,
	log2_max_transform_skip_block_size_minus2: u8,
	diff_cu_chroma_qp_offset_depth:            u8,
	chroma_qp_offset_list_len_minus1:          u8,
	cb_qp_offset_list:                         [VIDEO_H265_CHROMA_QP_OFFSET_LIST_SIZE]i8,
	cr_qp_offset_list:                         [VIDEO_H265_CHROMA_QP_OFFSET_LIST_SIZE]i8,
	log2_sao_offset_scale_luma:                u8,
	log2_sao_offset_scale_chroma:              u8,
	pps_act_y_qp_offset_plus5:                 i8,
	pps_act_cb_qp_offset_plus5:                i8,
	pps_act_cr_qp_offset_plus3:                i8,
	pps_num_palette_predictor_initializers:    u8,
	luma_bit_depth_entry_minus8:               u8,
	chroma_bit_depth_entry_minus8:             u8,
	num_tile_columns_minus1:                   u8,
	num_tile_rows_minus1:                      u8,
	reserved1:                                 u8,
	reserved2:                                 u8,
	column_width_minus1:                       [VIDEO_H265_CHROMA_QP_OFFSET_TILE_COLS_LIST_SIZE]u16,
	row_height_minus1:                         [VIDEO_H265_CHROMA_QP_OFFSET_TILE_ROWS_LIST_SIZE]u16,
	reserved3:                                 u32,
	pScalingLists:                             [^]VideoH265ScalingLists,
	pPredictorPaletteEntries:                  [^]VideoH265PredictorPaletteEntries,
}

VideoDecodeH265PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeH265PictureInfo :: struct {
	flags:                        VideoDecodeH265PictureInfoFlags,
	sps_video_parameter_set_id:   u8,
	pps_seq_parameter_set_id:     u8,
	pps_pic_parameter_set_id:     u8,
	NumDeltaPocsOfRefRpsIdx:      u8,
	PicOrderCntVal:               i32,
	NumBitsForSTRefPicSetInSlice: u16,
	reserved:                     u16,
	RefPicSetStCurrBefore:        [VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE]u8,
	RefPicSetStCurrAfter:         [VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE]u8,
	RefPicSetLtCurr:              [VIDEO_DECODE_H265_REF_PIC_SET_LIST_SIZE]u8,
}

VideoDecodeH265ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoDecodeH265ReferenceInfo :: struct {
	flags:          VideoDecodeH265ReferenceInfoFlags,
	PicOrderCntVal: i32,
}

VideoEncodeH265WeightTableFlags :: struct {
	luma_weight_l0_flag:   u16,
	chroma_weight_l0_flag: u16,
	luma_weight_l1_flag:   u16,
	chroma_weight_l1_flag: u16,
}

VideoEncodeH265WeightTable :: struct {
	flags:                          VideoEncodeH265WeightTableFlags,
	luma_log2_weight_denom:         u8,
	delta_chroma_log2_weight_denom: i8,
	delta_luma_weight_l0:           [VIDEO_H265_MAX_NUM_LIST_REF]i8,
	luma_offset_l0:                 [VIDEO_H265_MAX_NUM_LIST_REF]i8,
	delta_chroma_weight_l0:         [VIDEO_H265_MAX_NUM_LIST_REF][VIDEO_H265_MAX_CHROMA_PLANES]i8,
	delta_chroma_offset_l0:         [VIDEO_H265_MAX_NUM_LIST_REF][VIDEO_H265_MAX_CHROMA_PLANES]i8,
	delta_luma_weight_l1:           [VIDEO_H265_MAX_NUM_LIST_REF]i8,
	luma_offset_l1:                 [VIDEO_H265_MAX_NUM_LIST_REF]i8,
	delta_chroma_weight_l1:         [VIDEO_H265_MAX_NUM_LIST_REF][VIDEO_H265_MAX_CHROMA_PLANES]i8,
	delta_chroma_offset_l1:         [VIDEO_H265_MAX_NUM_LIST_REF][VIDEO_H265_MAX_CHROMA_PLANES]i8,
}

VideoEncodeH265SliceSegmentHeaderFlags :: struct {
	bitfield: u32,
}

VideoEncodeH265SliceSegmentHeader :: struct {
	flags:                  VideoEncodeH265SliceSegmentHeaderFlags,
	slice_type:             VideoH265SliceType,
	slice_segment_address:  u32,
	collocated_ref_idx:     u8,
	MaxNumMergeCand:        u8,
	slice_cb_qp_offset:     i8,
	slice_cr_qp_offset:     i8,
	slice_beta_offset_div2: i8,
	slice_tc_offset_div2:   i8,
	slice_act_y_qp_offset:  i8,
	slice_act_cb_qp_offset: i8,
	slice_act_cr_qp_offset: i8,
	slice_qp_delta:         i8,
	reserved1:              u16,
	pWeightTable:           [^]VideoEncodeH265WeightTable,
}

VideoEncodeH265ReferenceListsInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH265ReferenceListsInfo :: struct {
	flags:                        VideoEncodeH265ReferenceListsInfoFlags,
	num_ref_idx_l0_active_minus1: u8,
	num_ref_idx_l1_active_minus1: u8,
	RefPicList0:                  [VIDEO_H265_MAX_NUM_LIST_REF]u8,
	RefPicList1:                  [VIDEO_H265_MAX_NUM_LIST_REF]u8,
	list_entry_l0:                [VIDEO_H265_MAX_NUM_LIST_REF]u8,
	list_entry_l1:                [VIDEO_H265_MAX_NUM_LIST_REF]u8,
}

VideoEncodeH265PictureInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH265LongTermRefPics :: struct {
	num_long_term_sps:          u8,
	num_long_term_pics:         u8,
	lt_idx_sps:                 [VIDEO_H265_MAX_LONG_TERM_REF_PICS_SPS]u8,
	poc_lsb_lt:                 [VIDEO_H265_MAX_LONG_TERM_PICS]u8,
	used_by_curr_pic_lt_flag:   u16,
	delta_poc_msb_present_flag: [VIDEO_H265_MAX_DELTA_POC]u8,
	delta_poc_msb_cycle_lt:     [VIDEO_H265_MAX_DELTA_POC]u8,
}

VideoEncodeH265PictureInfo :: struct {
	flags:                      VideoEncodeH265PictureInfoFlags,
	pic_type:                   VideoH265PictureType,
	sps_video_parameter_set_id: u8,
	pps_seq_parameter_set_id:   u8,
	pps_pic_parameter_set_id:   u8,
	short_term_ref_pic_set_idx: u8,
	PicOrderCntVal:             i32,
	TemporalId:                 u8,
	reserved1:                  [7]u8,
	pRefLists:                  [^]VideoEncodeH265ReferenceListsInfo,
	pShortTermRefPicSet:        ^VideoH265ShortTermRefPicSet,
	pLongTermRefPics:           [^]VideoEncodeH265LongTermRefPics,
}

VideoEncodeH265ReferenceInfoFlags :: struct {
	bitfield: u32,
}

VideoEncodeH265ReferenceInfo :: struct {
	flags:          VideoEncodeH265ReferenceInfoFlags,
	pic_type:       VideoH265PictureType,
	PicOrderCntVal: i32,
	TemporalId:     u8,
}

// Opaque structs

wl_surface       :: struct {} // Opaque struct defined by Wayland
wl_display       :: struct {} // Opaque struct defined by Wayland
xcb_connection_t :: struct {} // Opaque struct defined by xcb
IOSurfaceRef     :: struct {} // Opaque struct defined by Apple’s CoreGraphics framework
// Aliases
PhysicalDeviceVariablePointerFeatures                       :: PhysicalDeviceVariablePointersFeatures
PhysicalDeviceShaderDrawParameterFeatures                   :: PhysicalDeviceShaderDrawParametersFeatures
RenderingFlagsKHR                                           :: RenderingFlags
RenderingFlagKHR                                            :: RenderingFlag
RenderingInfoKHR                                            :: RenderingInfo
RenderingAttachmentInfoKHR                                  :: RenderingAttachmentInfo
PipelineRenderingCreateInfoKHR                              :: PipelineRenderingCreateInfo
PhysicalDeviceDynamicRenderingFeaturesKHR                   :: PhysicalDeviceDynamicRenderingFeatures
CommandBufferInheritanceRenderingInfoKHR                    :: CommandBufferInheritanceRenderingInfo
RenderPassMultiviewCreateInfoKHR                            :: RenderPassMultiviewCreateInfo
PhysicalDeviceMultiviewFeaturesKHR                          :: PhysicalDeviceMultiviewFeatures
PhysicalDeviceMultiviewPropertiesKHR                        :: PhysicalDeviceMultiviewProperties
PhysicalDeviceFeatures2KHR                                  :: PhysicalDeviceFeatures2
PhysicalDeviceProperties2KHR                                :: PhysicalDeviceProperties2
FormatProperties2KHR                                        :: FormatProperties2
ImageFormatProperties2KHR                                   :: ImageFormatProperties2
PhysicalDeviceImageFormatInfo2KHR                           :: PhysicalDeviceImageFormatInfo2
QueueFamilyProperties2KHR                                   :: QueueFamilyProperties2
PhysicalDeviceMemoryProperties2KHR                          :: PhysicalDeviceMemoryProperties2
SparseImageFormatProperties2KHR                             :: SparseImageFormatProperties2
PhysicalDeviceSparseImageFormatInfo2KHR                     :: PhysicalDeviceSparseImageFormatInfo2
PeerMemoryFeatureFlagsKHR                                   :: PeerMemoryFeatureFlags
PeerMemoryFeatureFlagKHR                                    :: PeerMemoryFeatureFlag
MemoryAllocateFlagsKHR                                      :: MemoryAllocateFlags
MemoryAllocateFlagKHR                                       :: MemoryAllocateFlag
MemoryAllocateFlagsInfoKHR                                  :: MemoryAllocateFlagsInfo
DeviceGroupRenderPassBeginInfoKHR                           :: DeviceGroupRenderPassBeginInfo
DeviceGroupCommandBufferBeginInfoKHR                        :: DeviceGroupCommandBufferBeginInfo
DeviceGroupSubmitInfoKHR                                    :: DeviceGroupSubmitInfo
DeviceGroupBindSparseInfoKHR                                :: DeviceGroupBindSparseInfo
BindBufferMemoryDeviceGroupInfoKHR                          :: BindBufferMemoryDeviceGroupInfo
BindImageMemoryDeviceGroupInfoKHR                           :: BindImageMemoryDeviceGroupInfo
CommandPoolTrimFlagsKHR                                     :: CommandPoolTrimFlags
PhysicalDeviceGroupPropertiesKHR                            :: PhysicalDeviceGroupProperties
DeviceGroupDeviceCreateInfoKHR                              :: DeviceGroupDeviceCreateInfo
ExternalMemoryHandleTypeFlagsKHR                            :: ExternalMemoryHandleTypeFlags
ExternalMemoryHandleTypeFlagKHR                             :: ExternalMemoryHandleTypeFlag
ExternalMemoryFeatureFlagsKHR                               :: ExternalMemoryFeatureFlags
ExternalMemoryFeatureFlagKHR                                :: ExternalMemoryFeatureFlag
ExternalMemoryPropertiesKHR                                 :: ExternalMemoryProperties
PhysicalDeviceExternalImageFormatInfoKHR                    :: PhysicalDeviceExternalImageFormatInfo
ExternalImageFormatPropertiesKHR                            :: ExternalImageFormatProperties
PhysicalDeviceExternalBufferInfoKHR                         :: PhysicalDeviceExternalBufferInfo
ExternalBufferPropertiesKHR                                 :: ExternalBufferProperties
PhysicalDeviceIDPropertiesKHR                               :: PhysicalDeviceIDProperties
ExternalMemoryImageCreateInfoKHR                            :: ExternalMemoryImageCreateInfo
ExternalMemoryBufferCreateInfoKHR                           :: ExternalMemoryBufferCreateInfo
ExportMemoryAllocateInfoKHR                                 :: ExportMemoryAllocateInfo
ExternalSemaphoreHandleTypeFlagsKHR                         :: ExternalSemaphoreHandleTypeFlags
ExternalSemaphoreHandleTypeFlagKHR                          :: ExternalSemaphoreHandleTypeFlag
ExternalSemaphoreFeatureFlagsKHR                            :: ExternalSemaphoreFeatureFlags
ExternalSemaphoreFeatureFlagKHR                             :: ExternalSemaphoreFeatureFlag
PhysicalDeviceExternalSemaphoreInfoKHR                      :: PhysicalDeviceExternalSemaphoreInfo
ExternalSemaphorePropertiesKHR                              :: ExternalSemaphoreProperties
SemaphoreImportFlagsKHR                                     :: SemaphoreImportFlags
SemaphoreImportFlagKHR                                      :: SemaphoreImportFlag
ExportSemaphoreCreateInfoKHR                                :: ExportSemaphoreCreateInfo
PhysicalDevicePushDescriptorPropertiesKHR                   :: PhysicalDevicePushDescriptorProperties
PhysicalDeviceShaderFloat16Int8FeaturesKHR                  :: PhysicalDeviceShaderFloat16Int8Features
PhysicalDeviceFloat16Int8FeaturesKHR                        :: PhysicalDeviceShaderFloat16Int8Features
PhysicalDevice16BitStorageFeaturesKHR                       :: PhysicalDevice16BitStorageFeatures
DescriptorUpdateTemplateKHR                                 :: DescriptorUpdateTemplate
DescriptorUpdateTemplateTypeKHR                             :: DescriptorUpdateTemplateType
DescriptorUpdateTemplateCreateFlagsKHR                      :: DescriptorUpdateTemplateCreateFlags
DescriptorUpdateTemplateEntryKHR                            :: DescriptorUpdateTemplateEntry
DescriptorUpdateTemplateCreateInfoKHR                       :: DescriptorUpdateTemplateCreateInfo
PhysicalDeviceImagelessFramebufferFeaturesKHR               :: PhysicalDeviceImagelessFramebufferFeatures
FramebufferAttachmentsCreateInfoKHR                         :: FramebufferAttachmentsCreateInfo
FramebufferAttachmentImageInfoKHR                           :: FramebufferAttachmentImageInfo
RenderPassAttachmentBeginInfoKHR                            :: RenderPassAttachmentBeginInfo
RenderPassCreateInfo2KHR                                    :: RenderPassCreateInfo2
AttachmentDescription2KHR                                   :: AttachmentDescription2
AttachmentReference2KHR                                     :: AttachmentReference2
SubpassDescription2KHR                                      :: SubpassDescription2
SubpassDependency2KHR                                       :: SubpassDependency2
SubpassBeginInfoKHR                                         :: SubpassBeginInfo
SubpassEndInfoKHR                                           :: SubpassEndInfo
ExternalFenceHandleTypeFlagsKHR                             :: ExternalFenceHandleTypeFlags
ExternalFenceHandleTypeFlagKHR                              :: ExternalFenceHandleTypeFlag
ExternalFenceFeatureFlagsKHR                                :: ExternalFenceFeatureFlags
ExternalFenceFeatureFlagKHR                                 :: ExternalFenceFeatureFlag
PhysicalDeviceExternalFenceInfoKHR                          :: PhysicalDeviceExternalFenceInfo
ExternalFencePropertiesKHR                                  :: ExternalFenceProperties
FenceImportFlagsKHR                                         :: FenceImportFlags
FenceImportFlagKHR                                          :: FenceImportFlag
ExportFenceCreateInfoKHR                                    :: ExportFenceCreateInfo
PointClippingBehaviorKHR                                    :: PointClippingBehavior
TessellationDomainOriginKHR                                 :: TessellationDomainOrigin
PhysicalDevicePointClippingPropertiesKHR                    :: PhysicalDevicePointClippingProperties
RenderPassInputAttachmentAspectCreateInfoKHR                :: RenderPassInputAttachmentAspectCreateInfo
InputAttachmentAspectReferenceKHR                           :: InputAttachmentAspectReference
ImageViewUsageCreateInfoKHR                                 :: ImageViewUsageCreateInfo
PipelineTessellationDomainOriginStateCreateInfoKHR          :: PipelineTessellationDomainOriginStateCreateInfo
PhysicalDeviceVariablePointerFeaturesKHR                    :: PhysicalDeviceVariablePointersFeatures
PhysicalDeviceVariablePointersFeaturesKHR                   :: PhysicalDeviceVariablePointersFeatures
MemoryDedicatedRequirementsKHR                              :: MemoryDedicatedRequirements
MemoryDedicatedAllocateInfoKHR                              :: MemoryDedicatedAllocateInfo
BufferMemoryRequirementsInfo2KHR                            :: BufferMemoryRequirementsInfo2
ImageMemoryRequirementsInfo2KHR                             :: ImageMemoryRequirementsInfo2
ImageSparseMemoryRequirementsInfo2KHR                       :: ImageSparseMemoryRequirementsInfo2
MemoryRequirements2KHR                                      :: MemoryRequirements2
SparseImageMemoryRequirements2KHR                           :: SparseImageMemoryRequirements2
ImageFormatListCreateInfoKHR                                :: ImageFormatListCreateInfo
SamplerYcbcrConversionKHR                                   :: SamplerYcbcrConversion
SamplerYcbcrModelConversionKHR                              :: SamplerYcbcrModelConversion
SamplerYcbcrRangeKHR                                        :: SamplerYcbcrRange
ChromaLocationKHR                                           :: ChromaLocation
SamplerYcbcrConversionCreateInfoKHR                         :: SamplerYcbcrConversionCreateInfo
SamplerYcbcrConversionInfoKHR                               :: SamplerYcbcrConversionInfo
BindImagePlaneMemoryInfoKHR                                 :: BindImagePlaneMemoryInfo
ImagePlaneMemoryRequirementsInfoKHR                         :: ImagePlaneMemoryRequirementsInfo
PhysicalDeviceSamplerYcbcrConversionFeaturesKHR             :: PhysicalDeviceSamplerYcbcrConversionFeatures
SamplerYcbcrConversionImageFormatPropertiesKHR              :: SamplerYcbcrConversionImageFormatProperties
BindBufferMemoryInfoKHR                                     :: BindBufferMemoryInfo
BindImageMemoryInfoKHR                                      :: BindImageMemoryInfo
PhysicalDeviceMaintenance3PropertiesKHR                     :: PhysicalDeviceMaintenance3Properties
DescriptorSetLayoutSupportKHR                               :: DescriptorSetLayoutSupport
PhysicalDeviceShaderSubgroupExtendedTypesFeaturesKHR        :: PhysicalDeviceShaderSubgroupExtendedTypesFeatures
PhysicalDevice8BitStorageFeaturesKHR                        :: PhysicalDevice8BitStorageFeatures
PhysicalDeviceShaderAtomicInt64FeaturesKHR                  :: PhysicalDeviceShaderAtomicInt64Features
QueueGlobalPriorityKHR                                      :: QueueGlobalPriority
DeviceQueueGlobalPriorityCreateInfoKHR                      :: DeviceQueueGlobalPriorityCreateInfo
PhysicalDeviceGlobalPriorityQueryFeaturesKHR                :: PhysicalDeviceGlobalPriorityQueryFeatures
QueueFamilyGlobalPriorityPropertiesKHR                      :: QueueFamilyGlobalPriorityProperties
DriverIdKHR                                                 :: DriverId
ConformanceVersionKHR                                       :: ConformanceVersion
PhysicalDeviceDriverPropertiesKHR                           :: PhysicalDeviceDriverProperties
ShaderFloatControlsIndependenceKHR                          :: ShaderFloatControlsIndependence
PhysicalDeviceFloatControlsPropertiesKHR                    :: PhysicalDeviceFloatControlsProperties
ResolveModeFlagKHR                                          :: ResolveModeFlag
ResolveModeFlagsKHR                                         :: ResolveModeFlags
SubpassDescriptionDepthStencilResolveKHR                    :: SubpassDescriptionDepthStencilResolve
PhysicalDeviceDepthStencilResolvePropertiesKHR              :: PhysicalDeviceDepthStencilResolveProperties
SemaphoreTypeKHR                                            :: SemaphoreType
SemaphoreWaitFlagKHR                                        :: SemaphoreWaitFlag
SemaphoreWaitFlagsKHR                                       :: SemaphoreWaitFlags
PhysicalDeviceTimelineSemaphoreFeaturesKHR                  :: PhysicalDeviceTimelineSemaphoreFeatures
PhysicalDeviceTimelineSemaphorePropertiesKHR                :: PhysicalDeviceTimelineSemaphoreProperties
SemaphoreTypeCreateInfoKHR                                  :: SemaphoreTypeCreateInfo
TimelineSemaphoreSubmitInfoKHR                              :: TimelineSemaphoreSubmitInfo
SemaphoreWaitInfoKHR                                        :: SemaphoreWaitInfo
SemaphoreSignalInfoKHR                                      :: SemaphoreSignalInfo
PhysicalDeviceVulkanMemoryModelFeaturesKHR                  :: PhysicalDeviceVulkanMemoryModelFeatures
PhysicalDeviceShaderTerminateInvocationFeaturesKHR          :: PhysicalDeviceShaderTerminateInvocationFeatures
PhysicalDeviceDynamicRenderingLocalReadFeaturesKHR          :: PhysicalDeviceDynamicRenderingLocalReadFeatures
RenderingAttachmentLocationInfoKHR                          :: RenderingAttachmentLocationInfo
RenderingInputAttachmentIndexInfoKHR                        :: RenderingInputAttachmentIndexInfo
PhysicalDeviceSeparateDepthStencilLayoutsFeaturesKHR        :: PhysicalDeviceSeparateDepthStencilLayoutsFeatures
AttachmentReferenceStencilLayoutKHR                         :: AttachmentReferenceStencilLayout
AttachmentDescriptionStencilLayoutKHR                       :: AttachmentDescriptionStencilLayout
PhysicalDeviceUniformBufferStandardLayoutFeaturesKHR        :: PhysicalDeviceUniformBufferStandardLayoutFeatures
PhysicalDeviceBufferDeviceAddressFeaturesKHR                :: PhysicalDeviceBufferDeviceAddressFeatures
BufferDeviceAddressInfoKHR                                  :: BufferDeviceAddressInfo
BufferOpaqueCaptureAddressCreateInfoKHR                     :: BufferOpaqueCaptureAddressCreateInfo
MemoryOpaqueCaptureAddressAllocateInfoKHR                   :: MemoryOpaqueCaptureAddressAllocateInfo
DeviceMemoryOpaqueCaptureAddressInfoKHR                     :: DeviceMemoryOpaqueCaptureAddressInfo
MemoryUnmapFlagKHR                                          :: MemoryUnmapFlag
MemoryUnmapFlagsKHR                                         :: MemoryUnmapFlags
MemoryMapInfoKHR                                            :: MemoryMapInfo
MemoryUnmapInfoKHR                                          :: MemoryUnmapInfo
PhysicalDeviceShaderIntegerDotProductFeaturesKHR            :: PhysicalDeviceShaderIntegerDotProductFeatures
PhysicalDeviceShaderIntegerDotProductPropertiesKHR          :: PhysicalDeviceShaderIntegerDotProductProperties
PipelineStageFlags2KHR                                      :: PipelineStageFlags2
PipelineStageFlag2KHR                                       :: PipelineStageFlag2
AccessFlags2KHR                                             :: AccessFlags2
AccessFlag2KHR                                              :: AccessFlag2
SubmitFlagKHR                                               :: SubmitFlag
SubmitFlagsKHR                                              :: SubmitFlags
MemoryBarrier2KHR                                           :: MemoryBarrier2
BufferMemoryBarrier2KHR                                     :: BufferMemoryBarrier2
ImageMemoryBarrier2KHR                                      :: ImageMemoryBarrier2
DependencyInfoKHR                                           :: DependencyInfo
SubmitInfo2KHR                                              :: SubmitInfo2
SemaphoreSubmitInfoKHR                                      :: SemaphoreSubmitInfo
CommandBufferSubmitInfoKHR                                  :: CommandBufferSubmitInfo
PhysicalDeviceSynchronization2FeaturesKHR                   :: PhysicalDeviceSynchronization2Features
PhysicalDeviceZeroInitializeWorkgroupMemoryFeaturesKHR      :: PhysicalDeviceZeroInitializeWorkgroupMemoryFeatures
CopyBufferInfo2KHR                                          :: CopyBufferInfo2
CopyImageInfo2KHR                                           :: CopyImageInfo2
CopyBufferToImageInfo2KHR                                   :: CopyBufferToImageInfo2
CopyImageToBufferInfo2KHR                                   :: CopyImageToBufferInfo2
BlitImageInfo2KHR                                           :: BlitImageInfo2
ResolveImageInfo2KHR                                        :: ResolveImageInfo2
BufferCopy2KHR                                              :: BufferCopy2
ImageCopy2KHR                                               :: ImageCopy2
ImageBlit2KHR                                               :: ImageBlit2
BufferImageCopy2KHR                                         :: BufferImageCopy2
ImageResolve2KHR                                            :: ImageResolve2
FormatFeatureFlags2KHR                                      :: FormatFeatureFlags2
FormatFeatureFlag2KHR                                       :: FormatFeatureFlag2
FormatProperties3KHR                                        :: FormatProperties3
PhysicalDeviceMaintenance4FeaturesKHR                       :: PhysicalDeviceMaintenance4Features
PhysicalDeviceMaintenance4PropertiesKHR                     :: PhysicalDeviceMaintenance4Properties
DeviceBufferMemoryRequirementsKHR                           :: DeviceBufferMemoryRequirements
DeviceImageMemoryRequirementsKHR                            :: DeviceImageMemoryRequirements
PhysicalDeviceShaderSubgroupRotateFeaturesKHR               :: PhysicalDeviceShaderSubgroupRotateFeatures
PipelineCreateFlags2KHR                                     :: PipelineCreateFlags2
PipelineCreateFlag2KHR                                      :: PipelineCreateFlag2
BufferUsageFlags2KHR                                        :: BufferUsageFlags2
BufferUsageFlag2KHR                                         :: BufferUsageFlag2
PhysicalDeviceMaintenance5FeaturesKHR                       :: PhysicalDeviceMaintenance5Features
PhysicalDeviceMaintenance5PropertiesKHR                     :: PhysicalDeviceMaintenance5Properties
RenderingAreaInfoKHR                                        :: RenderingAreaInfo
DeviceImageSubresourceInfoKHR                               :: DeviceImageSubresourceInfo
ImageSubresource2KHR                                        :: ImageSubresource2
SubresourceLayout2KHR                                       :: SubresourceLayout2
PipelineCreateFlags2CreateInfoKHR                           :: PipelineCreateFlags2CreateInfo
BufferUsageFlags2CreateInfoKHR                              :: BufferUsageFlags2CreateInfo
PhysicalDeviceVertexAttributeDivisorPropertiesKHR           :: PhysicalDeviceVertexAttributeDivisorProperties
VertexInputBindingDivisorDescriptionKHR                     :: VertexInputBindingDivisorDescription
PipelineVertexInputDivisorStateCreateInfoKHR                :: PipelineVertexInputDivisorStateCreateInfo
PhysicalDeviceVertexAttributeDivisorFeaturesKHR             :: PhysicalDeviceVertexAttributeDivisorFeatures
PhysicalDeviceShaderFloatControls2FeaturesKHR               :: PhysicalDeviceShaderFloatControls2Features
PhysicalDeviceIndexTypeUint8FeaturesKHR                     :: PhysicalDeviceIndexTypeUint8Features
LineRasterizationModeKHR                                    :: LineRasterizationMode
PhysicalDeviceLineRasterizationFeaturesKHR                  :: PhysicalDeviceLineRasterizationFeatures
PhysicalDeviceLineRasterizationPropertiesKHR                :: PhysicalDeviceLineRasterizationProperties
PipelineRasterizationLineStateCreateInfoKHR                 :: PipelineRasterizationLineStateCreateInfo
PhysicalDeviceShaderExpectAssumeFeaturesKHR                 :: PhysicalDeviceShaderExpectAssumeFeatures
PhysicalDeviceMaintenance6FeaturesKHR                       :: PhysicalDeviceMaintenance6Features
PhysicalDeviceMaintenance6PropertiesKHR                     :: PhysicalDeviceMaintenance6Properties
BindMemoryStatusKHR                                         :: BindMemoryStatus
BindDescriptorSetsInfoKHR                                   :: BindDescriptorSetsInfo
PushConstantsInfoKHR                                        :: PushConstantsInfo
PushDescriptorSetInfoKHR                                    :: PushDescriptorSetInfo
PushDescriptorSetWithTemplateInfoKHR                        :: PushDescriptorSetWithTemplateInfo
PhysicalDeviceTextureCompressionASTCHDRFeaturesEXT          :: PhysicalDeviceTextureCompressionASTCHDRFeatures
PipelineRobustnessBufferBehaviorEXT                         :: PipelineRobustnessBufferBehavior
PipelineRobustnessImageBehaviorEXT                          :: PipelineRobustnessImageBehavior
PhysicalDevicePipelineRobustnessFeaturesEXT                 :: PhysicalDevicePipelineRobustnessFeatures
PhysicalDevicePipelineRobustnessPropertiesEXT               :: PhysicalDevicePipelineRobustnessProperties
PipelineRobustnessCreateInfoEXT                             :: PipelineRobustnessCreateInfo
SamplerReductionModeEXT                                     :: SamplerReductionMode
SamplerReductionModeCreateInfoEXT                           :: SamplerReductionModeCreateInfo
PhysicalDeviceSamplerFilterMinmaxPropertiesEXT              :: PhysicalDeviceSamplerFilterMinmaxProperties
PhysicalDeviceInlineUniformBlockFeaturesEXT                 :: PhysicalDeviceInlineUniformBlockFeatures
PhysicalDeviceInlineUniformBlockPropertiesEXT               :: PhysicalDeviceInlineUniformBlockProperties
WriteDescriptorSetInlineUniformBlockEXT                     :: WriteDescriptorSetInlineUniformBlock
DescriptorPoolInlineUniformBlockCreateInfoEXT               :: DescriptorPoolInlineUniformBlockCreateInfo
AttachmentSampleCountInfoNV                                 :: AttachmentSampleCountInfoAMD
DescriptorBindingFlagEXT                                    :: DescriptorBindingFlag
DescriptorBindingFlagsEXT                                   :: DescriptorBindingFlags
DescriptorSetLayoutBindingFlagsCreateInfoEXT                :: DescriptorSetLayoutBindingFlagsCreateInfo
PhysicalDeviceDescriptorIndexingFeaturesEXT                 :: PhysicalDeviceDescriptorIndexingFeatures
PhysicalDeviceDescriptorIndexingPropertiesEXT               :: PhysicalDeviceDescriptorIndexingProperties
DescriptorSetVariableDescriptorCountAllocateInfoEXT         :: DescriptorSetVariableDescriptorCountAllocateInfo
DescriptorSetVariableDescriptorCountLayoutSupportEXT        :: DescriptorSetVariableDescriptorCountLayoutSupport
RayTracingShaderGroupTypeNV                                 :: RayTracingShaderGroupTypeKHR
GeometryTypeNV                                              :: GeometryTypeKHR
AccelerationStructureTypeNV                                 :: AccelerationStructureTypeKHR
CopyAccelerationStructureModeNV                             :: CopyAccelerationStructureModeKHR
GeometryFlagsNV                                             :: GeometryFlagsKHR
GeometryFlagNV                                              :: GeometryFlagKHR
GeometryInstanceFlagsNV                                     :: GeometryInstanceFlagsKHR
GeometryInstanceFlagNV                                      :: GeometryInstanceFlagKHR
BuildAccelerationStructureFlagsNV                           :: BuildAccelerationStructureFlagsKHR
BuildAccelerationStructureFlagNV                            :: BuildAccelerationStructureFlagKHR
TransformMatrixNV                                           :: TransformMatrixKHR
AabbPositionsNV                                             :: AabbPositionsKHR
AccelerationStructureInstanceNV                             :: AccelerationStructureInstanceKHR
QueueGlobalPriorityEXT                                      :: QueueGlobalPriority
DeviceQueueGlobalPriorityCreateInfoEXT                      :: DeviceQueueGlobalPriorityCreateInfo
TimeDomainEXT                                               :: TimeDomainKHR
CalibratedTimestampInfoEXT                                  :: CalibratedTimestampInfoKHR
VertexInputBindingDivisorDescriptionEXT                     :: VertexInputBindingDivisorDescription
PipelineVertexInputDivisorStateCreateInfoEXT                :: PipelineVertexInputDivisorStateCreateInfo
PhysicalDeviceVertexAttributeDivisorFeaturesEXT             :: PhysicalDeviceVertexAttributeDivisorFeatures
PipelineCreationFeedbackFlagEXT                             :: PipelineCreationFeedbackFlag
PipelineCreationFeedbackFlagsEXT                            :: PipelineCreationFeedbackFlags
PipelineCreationFeedbackCreateInfoEXT                       :: PipelineCreationFeedbackCreateInfo
PipelineCreationFeedbackEXT                                 :: PipelineCreationFeedback
PhysicalDeviceComputeShaderDerivativesFeaturesNV            :: PhysicalDeviceComputeShaderDerivativesFeaturesKHR
PhysicalDeviceFragmentShaderBarycentricFeaturesNV           :: PhysicalDeviceFragmentShaderBarycentricFeaturesKHR
QueryPoolCreateInfoINTEL                                    :: QueryPoolPerformanceQueryCreateInfoINTEL
PhysicalDeviceScalarBlockLayoutFeaturesEXT                  :: PhysicalDeviceScalarBlockLayoutFeatures
PhysicalDeviceSubgroupSizeControlFeaturesEXT                :: PhysicalDeviceSubgroupSizeControlFeatures
PhysicalDeviceSubgroupSizeControlPropertiesEXT              :: PhysicalDeviceSubgroupSizeControlProperties
PipelineShaderStageRequiredSubgroupSizeCreateInfoEXT        :: PipelineShaderStageRequiredSubgroupSizeCreateInfo
PhysicalDeviceBufferAddressFeaturesEXT                      :: PhysicalDeviceBufferDeviceAddressFeaturesEXT
BufferDeviceAddressInfoEXT                                  :: BufferDeviceAddressInfo
ToolPurposeFlagEXT                                          :: ToolPurposeFlag
ToolPurposeFlagsEXT                                         :: ToolPurposeFlags
PhysicalDeviceToolPropertiesEXT                             :: PhysicalDeviceToolProperties
ImageStencilUsageCreateInfoEXT                              :: ImageStencilUsageCreateInfo
ComponentTypeNV                                             :: ComponentTypeKHR
ScopeNV                                                     :: ScopeKHR
LineRasterizationModeEXT                                    :: LineRasterizationMode
PhysicalDeviceLineRasterizationFeaturesEXT                  :: PhysicalDeviceLineRasterizationFeatures
PhysicalDeviceLineRasterizationPropertiesEXT                :: PhysicalDeviceLineRasterizationProperties
PipelineRasterizationLineStateCreateInfoEXT                 :: PipelineRasterizationLineStateCreateInfo
PhysicalDeviceHostQueryResetFeaturesEXT                     :: PhysicalDeviceHostQueryResetFeatures
PhysicalDeviceIndexTypeUint8FeaturesEXT                     :: PhysicalDeviceIndexTypeUint8Features
HostImageCopyFlagEXT                                        :: HostImageCopyFlag
HostImageCopyFlagsEXT                                       :: HostImageCopyFlags
PhysicalDeviceHostImageCopyFeaturesEXT                      :: PhysicalDeviceHostImageCopyFeatures
PhysicalDeviceHostImageCopyPropertiesEXT                    :: PhysicalDeviceHostImageCopyProperties
MemoryToImageCopyEXT                                        :: MemoryToImageCopy
ImageToMemoryCopyEXT                                        :: ImageToMemoryCopy
CopyMemoryToImageInfoEXT                                    :: CopyMemoryToImageInfo
CopyImageToMemoryInfoEXT                                    :: CopyImageToMemoryInfo
CopyImageToImageInfoEXT                                     :: CopyImageToImageInfo
HostImageLayoutTransitionInfoEXT                            :: HostImageLayoutTransitionInfo
SubresourceHostMemcpySizeEXT                                :: SubresourceHostMemcpySize
HostImageCopyDevicePerformanceQueryEXT                      :: HostImageCopyDevicePerformanceQuery
SubresourceLayout2EXT                                       :: SubresourceLayout2
ImageSubresource2EXT                                        :: ImageSubresource2
PhysicalDeviceShaderDemoteToHelperInvocationFeaturesEXT     :: PhysicalDeviceShaderDemoteToHelperInvocationFeatures
PhysicalDeviceTexelBufferAlignmentPropertiesEXT             :: PhysicalDeviceTexelBufferAlignmentProperties
PrivateDataSlotEXT                                          :: PrivateDataSlot
PrivateDataSlotCreateFlagsEXT                               :: PrivateDataSlotCreateFlags
PhysicalDevicePrivateDataFeaturesEXT                        :: PhysicalDevicePrivateDataFeatures
DevicePrivateDataCreateInfoEXT                              :: DevicePrivateDataCreateInfo
PrivateDataSlotCreateInfoEXT                                :: PrivateDataSlotCreateInfo
PhysicalDevicePipelineCreationCacheControlFeaturesEXT       :: PhysicalDevicePipelineCreationCacheControlFeatures
PhysicalDeviceImageRobustnessFeaturesEXT                    :: PhysicalDeviceImageRobustnessFeatures
PhysicalDeviceRasterizationOrderAttachmentAccessFeaturesARM :: PhysicalDeviceRasterizationOrderAttachmentAccessFeaturesEXT
PhysicalDeviceMutableDescriptorTypeFeaturesVALVE            :: PhysicalDeviceMutableDescriptorTypeFeaturesEXT
MutableDescriptorTypeListVALVE                              :: MutableDescriptorTypeListEXT
MutableDescriptorTypeCreateInfoVALVE                        :: MutableDescriptorTypeCreateInfoEXT
PipelineInfoEXT                                             :: PipelineInfoKHR
PhysicalDeviceGlobalPriorityQueryFeaturesEXT                :: PhysicalDeviceGlobalPriorityQueryFeatures
QueueFamilyGlobalPriorityPropertiesEXT                      :: QueueFamilyGlobalPriorityProperties
PhysicalDeviceSchedulingControlsFlagsARM                    :: Flags64
PhysicalDeviceSchedulingControlsFlagARM                     :: Flags64
MemoryDecompressionMethodFlagNV                             :: Flags64
MemoryDecompressionMethodFlagsNV                            :: Flags64
PhysicalDevicePipelineProtectedAccessFeaturesEXT            :: PhysicalDevicePipelineProtectedAccessFeatures
ShaderRequiredSubgroupSizeCreateInfoEXT                     :: PipelineShaderStageRequiredSubgroupSizeCreateInfo


