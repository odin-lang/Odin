//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan

import "core:c"

when ODIN_OS == "windows" {
	import win32 "core:sys/windows"

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

CAMetalLayer :: struct {}

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

PhysicalDevicePushDescriptorPropertiesKHR :: struct {
	sType:              StructureType,
	pNext:              rawptr,
	maxPushDescriptors: u32,
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

PhysicalDeviceShaderTerminateInvocationFeaturesKHR :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	shaderTerminateInvocation: b32,
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

PhysicalDeviceShaderIntegerDotProductFeaturesKHR :: struct {
	sType:                   StructureType,
	pNext:                   rawptr,
	shaderIntegerDotProduct: b32,
}

PhysicalDeviceShaderIntegerDotProductPropertiesKHR :: struct {
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

MemoryBarrier2KHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	srcStageMask:  PipelineStageFlags2KHR,
	srcAccessMask: AccessFlags2KHR,
	dstStageMask:  PipelineStageFlags2KHR,
	dstAccessMask: AccessFlags2KHR,
}

BufferMemoryBarrier2KHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcStageMask:        PipelineStageFlags2KHR,
	srcAccessMask:       AccessFlags2KHR,
	dstStageMask:        PipelineStageFlags2KHR,
	dstAccessMask:       AccessFlags2KHR,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	buffer:              Buffer,
	offset:              DeviceSize,
	size:                DeviceSize,
}

ImageMemoryBarrier2KHR :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	srcStageMask:        PipelineStageFlags2KHR,
	srcAccessMask:       AccessFlags2KHR,
	dstStageMask:        PipelineStageFlags2KHR,
	dstAccessMask:       AccessFlags2KHR,
	oldLayout:           ImageLayout,
	newLayout:           ImageLayout,
	srcQueueFamilyIndex: u32,
	dstQueueFamilyIndex: u32,
	image:               Image,
	subresourceRange:    ImageSubresourceRange,
}

DependencyInfoKHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	dependencyFlags:          DependencyFlags,
	memoryBarrierCount:       u32,
	pMemoryBarriers:          [^]MemoryBarrier2KHR,
	bufferMemoryBarrierCount: u32,
	pBufferMemoryBarriers:    [^]BufferMemoryBarrier2KHR,
	imageMemoryBarrierCount:  u32,
	pImageMemoryBarriers:     [^]ImageMemoryBarrier2KHR,
}

SemaphoreSubmitInfoKHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	semaphore:   Semaphore,
	value:       u64,
	stageMask:   PipelineStageFlags2KHR,
	deviceIndex: u32,
}

CommandBufferSubmitInfoKHR :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	commandBuffer: CommandBuffer,
	deviceMask:    u32,
}

SubmitInfo2KHR :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	flags:                    SubmitFlagsKHR,
	waitSemaphoreInfoCount:   u32,
	pWaitSemaphoreInfos:      [^]SemaphoreSubmitInfoKHR,
	commandBufferInfoCount:   u32,
	pCommandBufferInfos:      [^]CommandBufferSubmitInfoKHR,
	signalSemaphoreInfoCount: u32,
	pSignalSemaphoreInfos:    [^]SemaphoreSubmitInfoKHR,
}

PhysicalDeviceSynchronization2FeaturesKHR :: struct {
	sType:            StructureType,
	pNext:            rawptr,
	synchronization2: b32,
}

QueueFamilyCheckpointProperties2NV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	checkpointExecutionStageMask: PipelineStageFlags2KHR,
}

CheckpointData2NV :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	stage:             PipelineStageFlags2KHR,
	pCheckpointMarker: rawptr,
}

PhysicalDeviceShaderSubgroupUniformControlFlowFeaturesKHR :: struct {
	sType:                            StructureType,
	pNext:                            rawptr,
	shaderSubgroupUniformControlFlow: b32,
}

PhysicalDeviceZeroInitializeWorkgroupMemoryFeaturesKHR :: struct {
	sType:                               StructureType,
	pNext:                               rawptr,
	shaderZeroInitializeWorkgroupMemory: b32,
}

PhysicalDeviceWorkgroupMemoryExplicitLayoutFeaturesKHR :: struct {
	sType:                                          StructureType,
	pNext:                                          rawptr,
	workgroupMemoryExplicitLayout:                  b32,
	workgroupMemoryExplicitLayoutScalarBlockLayout: b32,
	workgroupMemoryExplicitLayout8BitAccess:        b32,
	workgroupMemoryExplicitLayout16BitAccess:       b32,
}

BufferCopy2KHR :: struct {
	sType:     StructureType,
	pNext:     rawptr,
	srcOffset: DeviceSize,
	dstOffset: DeviceSize,
	size:      DeviceSize,
}

CopyBufferInfo2KHR :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	srcBuffer:   Buffer,
	dstBuffer:   Buffer,
	regionCount: u32,
	pRegions:    [^]BufferCopy2KHR,
}

ImageCopy2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

CopyImageInfo2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageCopy2KHR,
}

BufferImageCopy2KHR :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	bufferOffset:      DeviceSize,
	bufferRowLength:   u32,
	bufferImageHeight: u32,
	imageSubresource:  ImageSubresourceLayers,
	imageOffset:       Offset3D,
	imageExtent:       Extent3D,
}

CopyBufferToImageInfo2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcBuffer:      Buffer,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]BufferImageCopy2KHR,
}

CopyImageToBufferInfo2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstBuffer:      Buffer,
	regionCount:    u32,
	pRegions:       [^]BufferImageCopy2KHR,
}

ImageBlit2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffsets:     [2]Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffsets:     [2]Offset3D,
}

BlitImageInfo2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageBlit2KHR,
	filter:         Filter,
}

ImageResolve2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcSubresource: ImageSubresourceLayers,
	srcOffset:      Offset3D,
	dstSubresource: ImageSubresourceLayers,
	dstOffset:      Offset3D,
	extent:         Extent3D,
}

ResolveImageInfo2KHR :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	srcImage:       Image,
	srcImageLayout: ImageLayout,
	dstImage:       Image,
	dstImageLayout: ImageLayout,
	regionCount:    u32,
	pRegions:       [^]ImageResolve2KHR,
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

PhysicalDeviceTextureCompressionASTCHDRFeaturesEXT :: struct {
	sType:                      StructureType,
	pNext:                      rawptr,
	textureCompressionASTC_HDR: b32,
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

PhysicalDeviceInlineUniformBlockFeaturesEXT :: struct {
	sType:                                              StructureType,
	pNext:                                              rawptr,
	inlineUniformBlock:                                 b32,
	descriptorBindingInlineUniformBlockUpdateAfterBind: b32,
}

PhysicalDeviceInlineUniformBlockPropertiesEXT :: struct {
	sType:                                                   StructureType,
	pNext:                                                   rawptr,
	maxInlineUniformBlockSize:                               u32,
	maxPerStageDescriptorInlineUniformBlocks:                u32,
	maxPerStageDescriptorUpdateAfterBindInlineUniformBlocks: u32,
	maxDescriptorSetInlineUniformBlocks:                     u32,
	maxDescriptorSetUpdateAfterBindInlineUniformBlocks:      u32,
}

WriteDescriptorSetInlineUniformBlockEXT :: struct {
	sType:    StructureType,
	pNext:    rawptr,
	dataSize: u32,
	pData:    rawptr,
}

DescriptorPoolInlineUniformBlockCreateInfoEXT :: struct {
	sType:                         StructureType,
	pNext:                         rawptr,
	maxInlineUniformBlockBindings: u32,
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
	transform:                      TransformMatrixKHR,
	accelerationStructureReference: u64,
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

DeviceQueueGlobalPriorityCreateInfoEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	globalPriority: QueueGlobalPriorityEXT,
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

CalibratedTimestampInfoEXT :: struct {
	sType:      StructureType,
	pNext:      rawptr,
	timeDomain: TimeDomainEXT,
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

VertexInputBindingDivisorDescriptionEXT :: struct {
	binding: u32,
	divisor: u32,
}

PipelineVertexInputDivisorStateCreateInfoEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	vertexBindingDivisorCount: u32,
	pVertexBindingDivisors:    [^]VertexInputBindingDivisorDescriptionEXT,
}

PhysicalDeviceVertexAttributeDivisorFeaturesEXT :: struct {
	sType:                                  StructureType,
	pNext:                                  rawptr,
	vertexAttributeInstanceRateDivisor:     b32,
	vertexAttributeInstanceRateZeroDivisor: b32,
}

PipelineCreationFeedbackEXT :: struct {
	flags:    PipelineCreationFeedbackFlagsEXT,
	duration: u64,
}

PipelineCreationFeedbackCreateInfoEXT :: struct {
	sType:                              StructureType,
	pNext:                              rawptr,
	pPipelineCreationFeedback:          ^PipelineCreationFeedbackEXT,
	pipelineStageCreationFeedbackCount: u32,
	pPipelineStageCreationFeedbacks:    [^]PipelineCreationFeedbackEXT,
}

PhysicalDeviceComputeShaderDerivativesFeaturesNV :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	computeDerivativeGroupQuads:  b32,
	computeDerivativeGroupLinear: b32,
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

PhysicalDeviceFragmentShaderBarycentricFeaturesNV :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	fragmentShaderBarycentric: b32,
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

PhysicalDeviceSubgroupSizeControlFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	subgroupSizeControl:  b32,
	computeFullSubgroups: b32,
}

PhysicalDeviceSubgroupSizeControlPropertiesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	minSubgroupSize:              u32,
	maxSubgroupSize:              u32,
	maxComputeWorkgroupSubgroups: u32,
	requiredSubgroupSizeStages:   ShaderStageFlags,
}

PipelineShaderStageRequiredSubgroupSizeCreateInfoEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	requiredSubgroupSize: u32,
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

PhysicalDeviceToolPropertiesEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	name:        [MAX_EXTENSION_NAME_SIZE]byte,
	version:     [MAX_EXTENSION_NAME_SIZE]byte,
	purposes:    ToolPurposeFlagsEXT,
	description: [MAX_DESCRIPTION_SIZE]byte,
	layer:       [MAX_EXTENSION_NAME_SIZE]byte,
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

PhysicalDeviceLineRasterizationFeaturesEXT :: struct {
	sType:                    StructureType,
	pNext:                    rawptr,
	rectangularLines:         b32,
	bresenhamLines:           b32,
	smoothLines:              b32,
	stippledRectangularLines: b32,
	stippledBresenhamLines:   b32,
	stippledSmoothLines:      b32,
}

PhysicalDeviceLineRasterizationPropertiesEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	lineSubPixelPrecisionBits: u32,
}

PipelineRasterizationLineStateCreateInfoEXT :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	lineRasterizationMode: LineRasterizationModeEXT,
	stippledLineEnable:    b32,
	lineStippleFactor:     u32,
	lineStipplePattern:    u16,
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

PhysicalDeviceIndexTypeUint8FeaturesEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	indexTypeUint8: b32,
}

PhysicalDeviceExtendedDynamicStateFeaturesEXT :: struct {
	sType:                StructureType,
	pNext:                rawptr,
	extendedDynamicState: b32,
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

PhysicalDeviceShaderDemoteToHelperInvocationFeaturesEXT :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	shaderDemoteToHelperInvocation: b32,
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

PhysicalDeviceTexelBufferAlignmentPropertiesEXT :: struct {
	sType:                                        StructureType,
	pNext:                                        rawptr,
	storageTexelBufferOffsetAlignmentBytes:       DeviceSize,
	storageTexelBufferOffsetSingleTexelAlignment: b32,
	uniformTexelBufferOffsetAlignmentBytes:       DeviceSize,
	uniformTexelBufferOffsetSingleTexelAlignment: b32,
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

PhysicalDevicePrivateDataFeaturesEXT :: struct {
	sType:       StructureType,
	pNext:       rawptr,
	privateData: b32,
}

DevicePrivateDataCreateInfoEXT :: struct {
	sType:                       StructureType,
	pNext:                       rawptr,
	privateDataSlotRequestCount: u32,
}

PrivateDataSlotCreateInfoEXT :: struct {
	sType: StructureType,
	pNext: rawptr,
	flags: PrivateDataSlotCreateFlagsEXT,
}

PhysicalDevicePipelineCreationCacheControlFeaturesEXT :: struct {
	sType:                        StructureType,
	pNext:                        rawptr,
	pipelineCreationCacheControl: b32,
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
	transformT0:                    TransformMatrixKHR,
	transformT1:                    TransformMatrixKHR,
	accelerationStructureReference: u64,
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
	transformT0:                    SRTDataNV,
	transformT1:                    SRTDataNV,
	accelerationStructureReference: u64,
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

PhysicalDeviceImageRobustnessFeaturesEXT :: struct {
	sType:             StructureType,
	pNext:             rawptr,
	robustImageAccess: b32,
}

PhysicalDevice4444FormatsFeaturesEXT :: struct {
	sType:          StructureType,
	pNext:          rawptr,
	formatA4R4G4B4: b32,
	formatA4B4G4R4: b32,
}

PhysicalDeviceMutableDescriptorTypeFeaturesVALVE :: struct {
	sType:                 StructureType,
	pNext:                 rawptr,
	mutableDescriptorType: b32,
}

MutableDescriptorTypeListVALVE :: struct {
	descriptorTypeCount: u32,
	pDescriptorTypes:    [^]DescriptorType,
}

MutableDescriptorTypeCreateInfoVALVE :: struct {
	sType:                          StructureType,
	pNext:                          rawptr,
	mutableDescriptorTypeListCount: u32,
	pMutableDescriptorTypeLists:    [^]MutableDescriptorTypeListVALVE,
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

PhysicalDevicePrimitiveTopologyListRestartFeaturesEXT :: struct {
	sType:                             StructureType,
	pNext:                             rawptr,
	primitiveTopologyListRestart:      b32,
	primitiveTopologyPatchListRestart: b32,
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

PhysicalDeviceGlobalPriorityQueryFeaturesEXT :: struct {
	sType:               StructureType,
	pNext:               rawptr,
	globalPriorityQuery: b32,
}

QueueFamilyGlobalPriorityPropertiesEXT :: struct {
	sType:         StructureType,
	pNext:         rawptr,
	priorityCount: u32,
	priorities:    [MAX_GLOBAL_PRIORITY_SIZE_EXT]QueueGlobalPriorityEXT,
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

PhysicalDevicePageableDeviceLocalMemoryFeaturesEXT :: struct {
	sType:                     StructureType,
	pNext:                     rawptr,
	pageableDeviceLocalMemory: b32,
}

DeviceOrHostAddressKHR :: struct #raw_union {
	deviceAddress: DeviceAddress,
	hostAddress:   rawptr,
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

// Aliases
PhysicalDeviceVariablePointerFeatures                :: PhysicalDeviceVariablePointersFeatures
PhysicalDeviceShaderDrawParameterFeatures            :: PhysicalDeviceShaderDrawParametersFeatures
RenderPassMultiviewCreateInfoKHR                     :: RenderPassMultiviewCreateInfo
PhysicalDeviceMultiviewFeaturesKHR                   :: PhysicalDeviceMultiviewFeatures
PhysicalDeviceMultiviewPropertiesKHR                 :: PhysicalDeviceMultiviewProperties
PhysicalDeviceFeatures2KHR                           :: PhysicalDeviceFeatures2
PhysicalDeviceProperties2KHR                         :: PhysicalDeviceProperties2
FormatProperties2KHR                                 :: FormatProperties2
ImageFormatProperties2KHR                            :: ImageFormatProperties2
PhysicalDeviceImageFormatInfo2KHR                    :: PhysicalDeviceImageFormatInfo2
QueueFamilyProperties2KHR                            :: QueueFamilyProperties2
PhysicalDeviceMemoryProperties2KHR                   :: PhysicalDeviceMemoryProperties2
SparseImageFormatProperties2KHR                      :: SparseImageFormatProperties2
PhysicalDeviceSparseImageFormatInfo2KHR              :: PhysicalDeviceSparseImageFormatInfo2
PeerMemoryFeatureFlagsKHR                            :: PeerMemoryFeatureFlags
PeerMemoryFeatureFlagKHR                             :: PeerMemoryFeatureFlag
MemoryAllocateFlagsKHR                               :: MemoryAllocateFlags
MemoryAllocateFlagKHR                                :: MemoryAllocateFlag
MemoryAllocateFlagsInfoKHR                           :: MemoryAllocateFlagsInfo
DeviceGroupRenderPassBeginInfoKHR                    :: DeviceGroupRenderPassBeginInfo
DeviceGroupCommandBufferBeginInfoKHR                 :: DeviceGroupCommandBufferBeginInfo
DeviceGroupSubmitInfoKHR                             :: DeviceGroupSubmitInfo
DeviceGroupBindSparseInfoKHR                         :: DeviceGroupBindSparseInfo
BindBufferMemoryDeviceGroupInfoKHR                   :: BindBufferMemoryDeviceGroupInfo
BindImageMemoryDeviceGroupInfoKHR                    :: BindImageMemoryDeviceGroupInfo
CommandPoolTrimFlagsKHR                              :: CommandPoolTrimFlags
PhysicalDeviceGroupPropertiesKHR                     :: PhysicalDeviceGroupProperties
DeviceGroupDeviceCreateInfoKHR                       :: DeviceGroupDeviceCreateInfo
ExternalMemoryHandleTypeFlagsKHR                     :: ExternalMemoryHandleTypeFlags
ExternalMemoryHandleTypeFlagKHR                      :: ExternalMemoryHandleTypeFlag
ExternalMemoryFeatureFlagsKHR                        :: ExternalMemoryFeatureFlags
ExternalMemoryFeatureFlagKHR                         :: ExternalMemoryFeatureFlag
ExternalMemoryPropertiesKHR                          :: ExternalMemoryProperties
PhysicalDeviceExternalImageFormatInfoKHR             :: PhysicalDeviceExternalImageFormatInfo
ExternalImageFormatPropertiesKHR                     :: ExternalImageFormatProperties
PhysicalDeviceExternalBufferInfoKHR                  :: PhysicalDeviceExternalBufferInfo
ExternalBufferPropertiesKHR                          :: ExternalBufferProperties
PhysicalDeviceIDPropertiesKHR                        :: PhysicalDeviceIDProperties
ExternalMemoryImageCreateInfoKHR                     :: ExternalMemoryImageCreateInfo
ExternalMemoryBufferCreateInfoKHR                    :: ExternalMemoryBufferCreateInfo
ExportMemoryAllocateInfoKHR                          :: ExportMemoryAllocateInfo
ExternalSemaphoreHandleTypeFlagsKHR                  :: ExternalSemaphoreHandleTypeFlags
ExternalSemaphoreHandleTypeFlagKHR                   :: ExternalSemaphoreHandleTypeFlag
ExternalSemaphoreFeatureFlagsKHR                     :: ExternalSemaphoreFeatureFlags
ExternalSemaphoreFeatureFlagKHR                      :: ExternalSemaphoreFeatureFlag
PhysicalDeviceExternalSemaphoreInfoKHR               :: PhysicalDeviceExternalSemaphoreInfo
ExternalSemaphorePropertiesKHR                       :: ExternalSemaphoreProperties
SemaphoreImportFlagsKHR                              :: SemaphoreImportFlags
SemaphoreImportFlagKHR                               :: SemaphoreImportFlag
ExportSemaphoreCreateInfoKHR                         :: ExportSemaphoreCreateInfo
PhysicalDeviceShaderFloat16Int8FeaturesKHR           :: PhysicalDeviceShaderFloat16Int8Features
PhysicalDeviceFloat16Int8FeaturesKHR                 :: PhysicalDeviceShaderFloat16Int8Features
PhysicalDevice16BitStorageFeaturesKHR                :: PhysicalDevice16BitStorageFeatures
DescriptorUpdateTemplateKHR                          :: DescriptorUpdateTemplate
DescriptorUpdateTemplateTypeKHR                      :: DescriptorUpdateTemplateType
DescriptorUpdateTemplateCreateFlagsKHR               :: DescriptorUpdateTemplateCreateFlags
DescriptorUpdateTemplateEntryKHR                     :: DescriptorUpdateTemplateEntry
DescriptorUpdateTemplateCreateInfoKHR                :: DescriptorUpdateTemplateCreateInfo
PhysicalDeviceImagelessFramebufferFeaturesKHR        :: PhysicalDeviceImagelessFramebufferFeatures
FramebufferAttachmentsCreateInfoKHR                  :: FramebufferAttachmentsCreateInfo
FramebufferAttachmentImageInfoKHR                    :: FramebufferAttachmentImageInfo
RenderPassAttachmentBeginInfoKHR                     :: RenderPassAttachmentBeginInfo
RenderPassCreateInfo2KHR                             :: RenderPassCreateInfo2
AttachmentDescription2KHR                            :: AttachmentDescription2
AttachmentReference2KHR                              :: AttachmentReference2
SubpassDescription2KHR                               :: SubpassDescription2
SubpassDependency2KHR                                :: SubpassDependency2
SubpassBeginInfoKHR                                  :: SubpassBeginInfo
SubpassEndInfoKHR                                    :: SubpassEndInfo
ExternalFenceHandleTypeFlagsKHR                      :: ExternalFenceHandleTypeFlags
ExternalFenceHandleTypeFlagKHR                       :: ExternalFenceHandleTypeFlag
ExternalFenceFeatureFlagsKHR                         :: ExternalFenceFeatureFlags
ExternalFenceFeatureFlagKHR                          :: ExternalFenceFeatureFlag
PhysicalDeviceExternalFenceInfoKHR                   :: PhysicalDeviceExternalFenceInfo
ExternalFencePropertiesKHR                           :: ExternalFenceProperties
FenceImportFlagsKHR                                  :: FenceImportFlags
FenceImportFlagKHR                                   :: FenceImportFlag
ExportFenceCreateInfoKHR                             :: ExportFenceCreateInfo
PointClippingBehaviorKHR                             :: PointClippingBehavior
TessellationDomainOriginKHR                          :: TessellationDomainOrigin
PhysicalDevicePointClippingPropertiesKHR             :: PhysicalDevicePointClippingProperties
RenderPassInputAttachmentAspectCreateInfoKHR         :: RenderPassInputAttachmentAspectCreateInfo
InputAttachmentAspectReferenceKHR                    :: InputAttachmentAspectReference
ImageViewUsageCreateInfoKHR                          :: ImageViewUsageCreateInfo
PipelineTessellationDomainOriginStateCreateInfoKHR   :: PipelineTessellationDomainOriginStateCreateInfo
PhysicalDeviceVariablePointerFeaturesKHR             :: PhysicalDeviceVariablePointersFeatures
PhysicalDeviceVariablePointersFeaturesKHR            :: PhysicalDeviceVariablePointersFeatures
MemoryDedicatedRequirementsKHR                       :: MemoryDedicatedRequirements
MemoryDedicatedAllocateInfoKHR                       :: MemoryDedicatedAllocateInfo
BufferMemoryRequirementsInfo2KHR                     :: BufferMemoryRequirementsInfo2
ImageMemoryRequirementsInfo2KHR                      :: ImageMemoryRequirementsInfo2
ImageSparseMemoryRequirementsInfo2KHR                :: ImageSparseMemoryRequirementsInfo2
MemoryRequirements2KHR                               :: MemoryRequirements2
SparseImageMemoryRequirements2KHR                    :: SparseImageMemoryRequirements2
ImageFormatListCreateInfoKHR                         :: ImageFormatListCreateInfo
SamplerYcbcrConversionKHR                            :: SamplerYcbcrConversion
SamplerYcbcrModelConversionKHR                       :: SamplerYcbcrModelConversion
SamplerYcbcrRangeKHR                                 :: SamplerYcbcrRange
ChromaLocationKHR                                    :: ChromaLocation
SamplerYcbcrConversionCreateInfoKHR                  :: SamplerYcbcrConversionCreateInfo
SamplerYcbcrConversionInfoKHR                        :: SamplerYcbcrConversionInfo
BindImagePlaneMemoryInfoKHR                          :: BindImagePlaneMemoryInfo
ImagePlaneMemoryRequirementsInfoKHR                  :: ImagePlaneMemoryRequirementsInfo
PhysicalDeviceSamplerYcbcrConversionFeaturesKHR      :: PhysicalDeviceSamplerYcbcrConversionFeatures
SamplerYcbcrConversionImageFormatPropertiesKHR       :: SamplerYcbcrConversionImageFormatProperties
BindBufferMemoryInfoKHR                              :: BindBufferMemoryInfo
BindImageMemoryInfoKHR                               :: BindImageMemoryInfo
PhysicalDeviceMaintenance3PropertiesKHR              :: PhysicalDeviceMaintenance3Properties
DescriptorSetLayoutSupportKHR                        :: DescriptorSetLayoutSupport
PhysicalDeviceShaderSubgroupExtendedTypesFeaturesKHR :: PhysicalDeviceShaderSubgroupExtendedTypesFeatures
PhysicalDevice8BitStorageFeaturesKHR                 :: PhysicalDevice8BitStorageFeatures
PhysicalDeviceShaderAtomicInt64FeaturesKHR           :: PhysicalDeviceShaderAtomicInt64Features
DriverIdKHR                                          :: DriverId
ConformanceVersionKHR                                :: ConformanceVersion
PhysicalDeviceDriverPropertiesKHR                    :: PhysicalDeviceDriverProperties
ShaderFloatControlsIndependenceKHR                   :: ShaderFloatControlsIndependence
PhysicalDeviceFloatControlsPropertiesKHR             :: PhysicalDeviceFloatControlsProperties
ResolveModeFlagKHR                                   :: ResolveModeFlag
ResolveModeFlagsKHR                                  :: ResolveModeFlags
SubpassDescriptionDepthStencilResolveKHR             :: SubpassDescriptionDepthStencilResolve
PhysicalDeviceDepthStencilResolvePropertiesKHR       :: PhysicalDeviceDepthStencilResolveProperties
SemaphoreTypeKHR                                     :: SemaphoreType
SemaphoreWaitFlagKHR                                 :: SemaphoreWaitFlag
SemaphoreWaitFlagsKHR                                :: SemaphoreWaitFlags
PhysicalDeviceTimelineSemaphoreFeaturesKHR           :: PhysicalDeviceTimelineSemaphoreFeatures
PhysicalDeviceTimelineSemaphorePropertiesKHR         :: PhysicalDeviceTimelineSemaphoreProperties
SemaphoreTypeCreateInfoKHR                           :: SemaphoreTypeCreateInfo
TimelineSemaphoreSubmitInfoKHR                       :: TimelineSemaphoreSubmitInfo
SemaphoreWaitInfoKHR                                 :: SemaphoreWaitInfo
SemaphoreSignalInfoKHR                               :: SemaphoreSignalInfo
PhysicalDeviceVulkanMemoryModelFeaturesKHR           :: PhysicalDeviceVulkanMemoryModelFeatures
PhysicalDeviceSeparateDepthStencilLayoutsFeaturesKHR :: PhysicalDeviceSeparateDepthStencilLayoutsFeatures
AttachmentReferenceStencilLayoutKHR                  :: AttachmentReferenceStencilLayout
AttachmentDescriptionStencilLayoutKHR                :: AttachmentDescriptionStencilLayout
PhysicalDeviceUniformBufferStandardLayoutFeaturesKHR :: PhysicalDeviceUniformBufferStandardLayoutFeatures
PhysicalDeviceBufferDeviceAddressFeaturesKHR         :: PhysicalDeviceBufferDeviceAddressFeatures
BufferDeviceAddressInfoKHR                           :: BufferDeviceAddressInfo
BufferOpaqueCaptureAddressCreateInfoKHR              :: BufferOpaqueCaptureAddressCreateInfo
MemoryOpaqueCaptureAddressAllocateInfoKHR            :: MemoryOpaqueCaptureAddressAllocateInfo
DeviceMemoryOpaqueCaptureAddressInfoKHR              :: DeviceMemoryOpaqueCaptureAddressInfo
PipelineStageFlags2KHR                               :: Flags64
PipelineStageFlag2KHR                                :: Flags64
AccessFlags2KHR                                      :: Flags64
AccessFlag2KHR                                       :: Flags64
SamplerReductionModeEXT                              :: SamplerReductionMode
SamplerReductionModeCreateInfoEXT                    :: SamplerReductionModeCreateInfo
PhysicalDeviceSamplerFilterMinmaxPropertiesEXT       :: PhysicalDeviceSamplerFilterMinmaxProperties
DescriptorBindingFlagEXT                             :: DescriptorBindingFlag
DescriptorBindingFlagsEXT                            :: DescriptorBindingFlags
DescriptorSetLayoutBindingFlagsCreateInfoEXT         :: DescriptorSetLayoutBindingFlagsCreateInfo
PhysicalDeviceDescriptorIndexingFeaturesEXT          :: PhysicalDeviceDescriptorIndexingFeatures
PhysicalDeviceDescriptorIndexingPropertiesEXT        :: PhysicalDeviceDescriptorIndexingProperties
DescriptorSetVariableDescriptorCountAllocateInfoEXT  :: DescriptorSetVariableDescriptorCountAllocateInfo
DescriptorSetVariableDescriptorCountLayoutSupportEXT :: DescriptorSetVariableDescriptorCountLayoutSupport
RayTracingShaderGroupTypeNV                          :: RayTracingShaderGroupTypeKHR
GeometryTypeNV                                       :: GeometryTypeKHR
AccelerationStructureTypeNV                          :: AccelerationStructureTypeKHR
CopyAccelerationStructureModeNV                      :: CopyAccelerationStructureModeKHR
GeometryFlagsNV                                      :: GeometryFlagsKHR
GeometryFlagNV                                       :: GeometryFlagKHR
GeometryInstanceFlagsNV                              :: GeometryInstanceFlagsKHR
GeometryInstanceFlagNV                               :: GeometryInstanceFlagKHR
BuildAccelerationStructureFlagsNV                    :: BuildAccelerationStructureFlagsKHR
BuildAccelerationStructureFlagNV                     :: BuildAccelerationStructureFlagKHR
TransformMatrixNV                                    :: TransformMatrixKHR
AabbPositionsNV                                      :: AabbPositionsKHR
AccelerationStructureInstanceNV                      :: AccelerationStructureInstanceKHR
QueryPoolCreateInfoINTEL                             :: QueryPoolPerformanceQueryCreateInfoINTEL
PhysicalDeviceScalarBlockLayoutFeaturesEXT           :: PhysicalDeviceScalarBlockLayoutFeatures
PhysicalDeviceBufferAddressFeaturesEXT               :: PhysicalDeviceBufferDeviceAddressFeaturesEXT
BufferDeviceAddressInfoEXT                           :: BufferDeviceAddressInfo
ImageStencilUsageCreateInfoEXT                       :: ImageStencilUsageCreateInfo
PhysicalDeviceHostQueryResetFeaturesEXT              :: PhysicalDeviceHostQueryResetFeatures


