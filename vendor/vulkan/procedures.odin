//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan

import "core:c"

// Procedure Types

when ODIN_OS == "windows" {
	ProcAllocationFunction                                              :: #type proc "stdcall" (pUserData: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
	ProcFreeFunction                                                    :: #type proc "stdcall" (pUserData: rawptr, pMemory: rawptr)
	ProcInternalAllocationNotification                                  :: #type proc "stdcall" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
	ProcInternalFreeNotification                                        :: #type proc "stdcall" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
	ProcReallocationFunction                                            :: #type proc "stdcall" (pUserData: rawptr, pOriginal: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
	ProcVoidFunction                                                    :: #type proc "stdcall" ()
	ProcCreateInstance                                                  :: #type proc "stdcall" (pCreateInfo: ^InstanceCreateInfo, pAllocator: ^AllocationCallbacks, pInstance: ^Instance) -> Result
	ProcDestroyInstance                                                 :: #type proc "stdcall" (instance: Instance, pAllocator: ^AllocationCallbacks)
	ProcEnumeratePhysicalDevices                                        :: #type proc "stdcall" (instance: Instance, pPhysicalDeviceCount: ^u32, pPhysicalDevices: ^PhysicalDevice) -> Result
	ProcGetPhysicalDeviceFeatures                                       :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures)
	ProcGetPhysicalDeviceFormatProperties                               :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties)
	ProcGetPhysicalDeviceImageFormatProperties                          :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, pImageFormatProperties: ^ImageFormatProperties) -> Result
	ProcGetPhysicalDeviceProperties                                     :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties)
	ProcGetPhysicalDeviceQueueFamilyProperties                          :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties)
	ProcGetPhysicalDeviceMemoryProperties                               :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties)
	ProcGetInstanceProcAddr                                             :: #type proc "stdcall" (instance: Instance, pName: cstring) -> ProcVoidFunction
	ProcGetDeviceProcAddr                                               :: #type proc "stdcall" (device: Device, pName: cstring) -> ProcVoidFunction
	ProcCreateDevice                                                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pCreateInfo: ^DeviceCreateInfo, pAllocator: ^AllocationCallbacks, pDevice: ^Device) -> Result
	ProcDestroyDevice                                                   :: #type proc "stdcall" (device: Device, pAllocator: ^AllocationCallbacks)
	ProcEnumerateInstanceExtensionProperties                            :: #type proc "stdcall" (pLayerName: cstring, pPropertyCount: ^u32, pProperties: ^ExtensionProperties) -> Result
	ProcEnumerateDeviceExtensionProperties                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pLayerName: cstring, pPropertyCount: ^u32, pProperties: ^ExtensionProperties) -> Result
	ProcEnumerateInstanceLayerProperties                                :: #type proc "stdcall" (pPropertyCount: ^u32, pProperties: ^LayerProperties) -> Result
	ProcEnumerateDeviceLayerProperties                                  :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^LayerProperties) -> Result
	ProcGetDeviceQueue                                                  :: #type proc "stdcall" (device: Device, queueFamilyIndex: u32, queueIndex: u32, pQueue: ^Queue)
	ProcQueueSubmit                                                     :: #type proc "stdcall" (queue: Queue, submitCount: u32, pSubmits: ^SubmitInfo, fence: Fence) -> Result
	ProcQueueWaitIdle                                                   :: #type proc "stdcall" (queue: Queue) -> Result
	ProcDeviceWaitIdle                                                  :: #type proc "stdcall" (device: Device) -> Result
	ProcAllocateMemory                                                  :: #type proc "stdcall" (device: Device, pAllocateInfo: ^MemoryAllocateInfo, pAllocator: ^AllocationCallbacks, pMemory: ^DeviceMemory) -> Result
	ProcFreeMemory                                                      :: #type proc "stdcall" (device: Device, memory: DeviceMemory, pAllocator: ^AllocationCallbacks)
	ProcMapMemory                                                       :: #type proc "stdcall" (device: Device, memory: DeviceMemory, offset: DeviceSize, size: DeviceSize, flags: MemoryMapFlags, ppData: ^rawptr) -> Result
	ProcUnmapMemory                                                     :: #type proc "stdcall" (device: Device, memory: DeviceMemory)
	ProcFlushMappedMemoryRanges                                         :: #type proc "stdcall" (device: Device, memoryRangeCount: u32, pMemoryRanges: ^MappedMemoryRange) -> Result
	ProcInvalidateMappedMemoryRanges                                    :: #type proc "stdcall" (device: Device, memoryRangeCount: u32, pMemoryRanges: ^MappedMemoryRange) -> Result
	ProcGetDeviceMemoryCommitment                                       :: #type proc "stdcall" (device: Device, memory: DeviceMemory, pCommittedMemoryInBytes: ^DeviceSize)
	ProcBindBufferMemory                                                :: #type proc "stdcall" (device: Device, buffer: Buffer, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
	ProcBindImageMemory                                                 :: #type proc "stdcall" (device: Device, image: Image, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
	ProcGetBufferMemoryRequirements                                     :: #type proc "stdcall" (device: Device, buffer: Buffer, pMemoryRequirements: ^MemoryRequirements)
	ProcGetImageMemoryRequirements                                      :: #type proc "stdcall" (device: Device, image: Image, pMemoryRequirements: ^MemoryRequirements)
	ProcGetImageSparseMemoryRequirements                                :: #type proc "stdcall" (device: Device, image: Image, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements)
	ProcGetPhysicalDeviceSparseImageFormatProperties                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, samples: SampleCountFlags, usage: ImageUsageFlags, tiling: ImageTiling, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties)
	ProcQueueBindSparse                                                 :: #type proc "stdcall" (queue: Queue, bindInfoCount: u32, pBindInfo: ^BindSparseInfo, fence: Fence) -> Result
	ProcCreateFence                                                     :: #type proc "stdcall" (device: Device, pCreateInfo: ^FenceCreateInfo, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcDestroyFence                                                    :: #type proc "stdcall" (device: Device, fence: Fence, pAllocator: ^AllocationCallbacks)
	ProcResetFences                                                     :: #type proc "stdcall" (device: Device, fenceCount: u32, pFences: ^Fence) -> Result
	ProcGetFenceStatus                                                  :: #type proc "stdcall" (device: Device, fence: Fence) -> Result
	ProcWaitForFences                                                   :: #type proc "stdcall" (device: Device, fenceCount: u32, pFences: ^Fence, waitAll: b32, timeout: u64) -> Result
	ProcCreateSemaphore                                                 :: #type proc "stdcall" (device: Device, pCreateInfo: ^SemaphoreCreateInfo, pAllocator: ^AllocationCallbacks, pSemaphore: ^Semaphore) -> Result
	ProcDestroySemaphore                                                :: #type proc "stdcall" (device: Device, semaphore: Semaphore, pAllocator: ^AllocationCallbacks)
	ProcCreateEvent                                                     :: #type proc "stdcall" (device: Device, pCreateInfo: ^EventCreateInfo, pAllocator: ^AllocationCallbacks, pEvent: ^Event) -> Result
	ProcDestroyEvent                                                    :: #type proc "stdcall" (device: Device, event: Event, pAllocator: ^AllocationCallbacks)
	ProcGetEventStatus                                                  :: #type proc "stdcall" (device: Device, event: Event) -> Result
	ProcSetEvent                                                        :: #type proc "stdcall" (device: Device, event: Event) -> Result
	ProcResetEvent                                                      :: #type proc "stdcall" (device: Device, event: Event) -> Result
	ProcCreateQueryPool                                                 :: #type proc "stdcall" (device: Device, pCreateInfo: ^QueryPoolCreateInfo, pAllocator: ^AllocationCallbacks, pQueryPool: ^QueryPool) -> Result
	ProcDestroyQueryPool                                                :: #type proc "stdcall" (device: Device, queryPool: QueryPool, pAllocator: ^AllocationCallbacks)
	ProcGetQueryPoolResults                                             :: #type proc "stdcall" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dataSize: int, pData: rawptr, stride: DeviceSize, flags: QueryResultFlags) -> Result
	ProcCreateBuffer                                                    :: #type proc "stdcall" (device: Device, pCreateInfo: ^BufferCreateInfo, pAllocator: ^AllocationCallbacks, pBuffer: ^Buffer) -> Result
	ProcDestroyBuffer                                                   :: #type proc "stdcall" (device: Device, buffer: Buffer, pAllocator: ^AllocationCallbacks)
	ProcCreateBufferView                                                :: #type proc "stdcall" (device: Device, pCreateInfo: ^BufferViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^BufferView) -> Result
	ProcDestroyBufferView                                               :: #type proc "stdcall" (device: Device, bufferView: BufferView, pAllocator: ^AllocationCallbacks)
	ProcCreateImage                                                     :: #type proc "stdcall" (device: Device, pCreateInfo: ^ImageCreateInfo, pAllocator: ^AllocationCallbacks, pImage: ^Image) -> Result
	ProcDestroyImage                                                    :: #type proc "stdcall" (device: Device, image: Image, pAllocator: ^AllocationCallbacks)
	ProcGetImageSubresourceLayout                                       :: #type proc "stdcall" (device: Device, image: Image, pSubresource: ^ImageSubresource, pLayout: ^SubresourceLayout)
	ProcCreateImageView                                                 :: #type proc "stdcall" (device: Device, pCreateInfo: ^ImageViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^ImageView) -> Result
	ProcDestroyImageView                                                :: #type proc "stdcall" (device: Device, imageView: ImageView, pAllocator: ^AllocationCallbacks)
	ProcCreateShaderModule                                              :: #type proc "stdcall" (device: Device, pCreateInfo: ^ShaderModuleCreateInfo, pAllocator: ^AllocationCallbacks, pShaderModule: ^ShaderModule) -> Result
	ProcDestroyShaderModule                                             :: #type proc "stdcall" (device: Device, shaderModule: ShaderModule, pAllocator: ^AllocationCallbacks)
	ProcCreatePipelineCache                                             :: #type proc "stdcall" (device: Device, pCreateInfo: ^PipelineCacheCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineCache: ^PipelineCache) -> Result
	ProcDestroyPipelineCache                                            :: #type proc "stdcall" (device: Device, pipelineCache: PipelineCache, pAllocator: ^AllocationCallbacks)
	ProcGetPipelineCacheData                                            :: #type proc "stdcall" (device: Device, pipelineCache: PipelineCache, pDataSize: ^int, pData: rawptr) -> Result
	ProcMergePipelineCaches                                             :: #type proc "stdcall" (device: Device, dstCache: PipelineCache, srcCacheCount: u32, pSrcCaches: ^PipelineCache) -> Result
	ProcCreateGraphicsPipelines                                         :: #type proc "stdcall" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^GraphicsPipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcCreateComputePipelines                                          :: #type proc "stdcall" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^ComputePipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcDestroyPipeline                                                 :: #type proc "stdcall" (device: Device, pipeline: Pipeline, pAllocator: ^AllocationCallbacks)
	ProcCreatePipelineLayout                                            :: #type proc "stdcall" (device: Device, pCreateInfo: ^PipelineLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineLayout: ^PipelineLayout) -> Result
	ProcDestroyPipelineLayout                                           :: #type proc "stdcall" (device: Device, pipelineLayout: PipelineLayout, pAllocator: ^AllocationCallbacks)
	ProcCreateSampler                                                   :: #type proc "stdcall" (device: Device, pCreateInfo: ^SamplerCreateInfo, pAllocator: ^AllocationCallbacks, pSampler: ^Sampler) -> Result
	ProcDestroySampler                                                  :: #type proc "stdcall" (device: Device, sampler: Sampler, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorSetLayout                                       :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pSetLayout: ^DescriptorSetLayout) -> Result
	ProcDestroyDescriptorSetLayout                                      :: #type proc "stdcall" (device: Device, descriptorSetLayout: DescriptorSetLayout, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorPool                                            :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorPoolCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorPool: ^DescriptorPool) -> Result
	ProcDestroyDescriptorPool                                           :: #type proc "stdcall" (device: Device, descriptorPool: DescriptorPool, pAllocator: ^AllocationCallbacks)
	ProcResetDescriptorPool                                             :: #type proc "stdcall" (device: Device, descriptorPool: DescriptorPool, flags: DescriptorPoolResetFlags) -> Result
	ProcAllocateDescriptorSets                                          :: #type proc "stdcall" (device: Device, pAllocateInfo: ^DescriptorSetAllocateInfo, pDescriptorSets: ^DescriptorSet) -> Result
	ProcFreeDescriptorSets                                              :: #type proc "stdcall" (device: Device, descriptorPool: DescriptorPool, descriptorSetCount: u32, pDescriptorSets: ^DescriptorSet) -> Result
	ProcUpdateDescriptorSets                                            :: #type proc "stdcall" (device: Device, descriptorWriteCount: u32, pDescriptorWrites: ^WriteDescriptorSet, descriptorCopyCount: u32, pDescriptorCopies: ^CopyDescriptorSet)
	ProcCreateFramebuffer                                               :: #type proc "stdcall" (device: Device, pCreateInfo: ^FramebufferCreateInfo, pAllocator: ^AllocationCallbacks, pFramebuffer: ^Framebuffer) -> Result
	ProcDestroyFramebuffer                                              :: #type proc "stdcall" (device: Device, framebuffer: Framebuffer, pAllocator: ^AllocationCallbacks)
	ProcCreateRenderPass                                                :: #type proc "stdcall" (device: Device, pCreateInfo: ^RenderPassCreateInfo, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcDestroyRenderPass                                               :: #type proc "stdcall" (device: Device, renderPass: RenderPass, pAllocator: ^AllocationCallbacks)
	ProcGetRenderAreaGranularity                                        :: #type proc "stdcall" (device: Device, renderPass: RenderPass, pGranularity: ^Extent2D)
	ProcCreateCommandPool                                               :: #type proc "stdcall" (device: Device, pCreateInfo: ^CommandPoolCreateInfo, pAllocator: ^AllocationCallbacks, pCommandPool: ^CommandPool) -> Result
	ProcDestroyCommandPool                                              :: #type proc "stdcall" (device: Device, commandPool: CommandPool, pAllocator: ^AllocationCallbacks)
	ProcResetCommandPool                                                :: #type proc "stdcall" (device: Device, commandPool: CommandPool, flags: CommandPoolResetFlags) -> Result
	ProcAllocateCommandBuffers                                          :: #type proc "stdcall" (device: Device, pAllocateInfo: ^CommandBufferAllocateInfo, pCommandBuffers: ^CommandBuffer) -> Result
	ProcFreeCommandBuffers                                              :: #type proc "stdcall" (device: Device, commandPool: CommandPool, commandBufferCount: u32, pCommandBuffers: ^CommandBuffer)
	ProcBeginCommandBuffer                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, pBeginInfo: ^CommandBufferBeginInfo) -> Result
	ProcEndCommandBuffer                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer) -> Result
	ProcResetCommandBuffer                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, flags: CommandBufferResetFlags) -> Result
	ProcCmdBindPipeline                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline)
	ProcCmdSetViewport                                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewports: ^Viewport)
	ProcCmdSetScissor                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstScissor: u32, scissorCount: u32, pScissors: ^Rect2D)
	ProcCmdSetLineWidth                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, lineWidth: f32)
	ProcCmdSetDepthBias                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthBiasConstantFactor: f32, depthBiasClamp: f32, depthBiasSlopeFactor: f32)
	ProcCmdSetBlendConstants                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdSetDepthBounds                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, minDepthBounds: f32, maxDepthBounds: f32)
	ProcCmdSetStencilCompareMask                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, compareMask: u32)
	ProcCmdSetStencilWriteMask                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, writeMask: u32)
	ProcCmdSetStencilReference                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, reference: u32)
	ProcCmdBindDescriptorSets                                           :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, firstSet: u32, descriptorSetCount: u32, pDescriptorSets: ^DescriptorSet, dynamicOffsetCount: u32, pDynamicOffsets: ^u32)
	ProcCmdBindIndexBuffer                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, indexType: IndexType)
	ProcCmdBindVertexBuffers                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize)
	ProcCmdDraw                                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32)
	ProcCmdDrawIndexed                                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, indexCount: u32, instanceCount: u32, firstIndex: u32, vertexOffset: i32, firstInstance: u32)
	ProcCmdDrawIndirect                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirect                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDispatch                                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcCmdDispatchIndirect                                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize)
	ProcCmdCopyBuffer                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstBuffer: Buffer, regionCount: u32, pRegions: ^BufferCopy)
	ProcCmdCopyImage                                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageCopy)
	ProcCmdBlitImage                                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageBlit, filter: Filter)
	ProcCmdCopyBufferToImage                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^BufferImageCopy)
	ProcCmdCopyImageToBuffer                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstBuffer: Buffer, regionCount: u32, pRegions: ^BufferImageCopy)
	ProcCmdUpdateBuffer                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, dataSize: DeviceSize, pData: rawptr)
	ProcCmdFillBuffer                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, size: DeviceSize, data: u32)
	ProcCmdClearColorImage                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pColor: ^ClearColorValue, rangeCount: u32, pRanges: ^ImageSubresourceRange)
	ProcCmdClearDepthStencilImage                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pDepthStencil: ^ClearDepthStencilValue, rangeCount: u32, pRanges: ^ImageSubresourceRange)
	ProcCmdClearAttachments                                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, attachmentCount: u32, pAttachments: ^ClearAttachment, rectCount: u32, pRects: ^ClearRect)
	ProcCmdResolveImage                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageResolve)
	ProcCmdSetEvent                                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
	ProcCmdResetEvent                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
	ProcCmdWaitEvents                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: ^Event, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, memoryBarrierCount: u32, pMemoryBarriers: ^MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: ^BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: ^ImageMemoryBarrier)
	ProcCmdPipelineBarrier                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, dependencyFlags: DependencyFlags, memoryBarrierCount: u32, pMemoryBarriers: ^MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: ^BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: ^ImageMemoryBarrier)
	ProcCmdBeginQuery                                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags)
	ProcCmdEndQuery                                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32)
	ProcCmdResetQueryPool                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcCmdWriteTimestamp                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, queryPool: QueryPool, query: u32)
	ProcCmdCopyQueryPoolResults                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dstBuffer: Buffer, dstOffset: DeviceSize, stride: DeviceSize, flags: QueryResultFlags)
	ProcCmdPushConstants                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, layout: PipelineLayout, stageFlags: ShaderStageFlags, offset: u32, size: u32, pValues: rawptr)
	ProcCmdBeginRenderPass                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, contents: SubpassContents)
	ProcCmdNextSubpass                                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, contents: SubpassContents)
	ProcCmdEndRenderPass                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdExecuteCommands                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, commandBufferCount: u32, pCommandBuffers: ^CommandBuffer)
	ProcEnumerateInstanceVersion                                        :: #type proc "stdcall" (pApiVersion: ^u32) -> Result
	ProcBindBufferMemory2                                               :: #type proc "stdcall" (device: Device, bindInfoCount: u32, pBindInfos: ^BindBufferMemoryInfo) -> Result
	ProcBindImageMemory2                                                :: #type proc "stdcall" (device: Device, bindInfoCount: u32, pBindInfos: ^BindImageMemoryInfo) -> Result
	ProcGetDeviceGroupPeerMemoryFeatures                                :: #type proc "stdcall" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: ^PeerMemoryFeatureFlags)
	ProcCmdSetDeviceMask                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, deviceMask: u32)
	ProcCmdDispatchBase                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcEnumeratePhysicalDeviceGroups                                   :: #type proc "stdcall" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: ^PhysicalDeviceGroupProperties) -> Result
	ProcGetImageMemoryRequirements2                                     :: #type proc "stdcall" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetBufferMemoryRequirements2                                    :: #type proc "stdcall" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetImageSparseMemoryRequirements2                               :: #type proc "stdcall" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements2)
	ProcGetPhysicalDeviceFeatures2                                      :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures2)
	ProcGetPhysicalDeviceProperties2                                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties2)
	ProcGetPhysicalDeviceFormatProperties2                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties2)
	ProcGetPhysicalDeviceImageFormatProperties2                         :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: ^ImageFormatProperties2) -> Result
	ProcGetPhysicalDeviceQueueFamilyProperties2                         :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties2)
	ProcGetPhysicalDeviceMemoryProperties2                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties2)
	ProcGetPhysicalDeviceSparseImageFormatProperties2                   :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties2)
	ProcTrimCommandPool                                                 :: #type proc "stdcall" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
	ProcGetDeviceQueue2                                                 :: #type proc "stdcall" (device: Device, pQueueInfo: ^DeviceQueueInfo2, pQueue: ^Queue)
	ProcCreateSamplerYcbcrConversion                                    :: #type proc "stdcall" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
	ProcDestroySamplerYcbcrConversion                                   :: #type proc "stdcall" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorUpdateTemplate                                  :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
	ProcDestroyDescriptorUpdateTemplate                                 :: #type proc "stdcall" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
	ProcUpdateDescriptorSetWithTemplate                                 :: #type proc "stdcall" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
	ProcGetPhysicalDeviceExternalBufferProperties                       :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: ^ExternalBufferProperties)
	ProcGetPhysicalDeviceExternalFenceProperties                        :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: ^ExternalFenceProperties)
	ProcGetPhysicalDeviceExternalSemaphoreProperties                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: ^ExternalSemaphoreProperties)
	ProcGetDescriptorSetLayoutSupport                                   :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
	ProcCmdDrawIndirectCount                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCount                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCreateRenderPass2                                               :: #type proc "stdcall" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcCmdBeginRenderPass2                                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
	ProcCmdNextSubpass2                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
	ProcCmdEndRenderPass2                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
	ProcResetQueryPool                                                  :: #type proc "stdcall" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcGetSemaphoreCounterValue                                        :: #type proc "stdcall" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
	ProcWaitSemaphores                                                  :: #type proc "stdcall" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
	ProcSignalSemaphore                                                 :: #type proc "stdcall" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
	ProcGetBufferDeviceAddress                                          :: #type proc "stdcall" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetBufferOpaqueCaptureAddress                                   :: #type proc "stdcall" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
	ProcGetDeviceMemoryOpaqueCaptureAddress                             :: #type proc "stdcall" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
	ProcDestroySurfaceKHR                                               :: #type proc "stdcall" (instance: Instance, surface: SurfaceKHR, pAllocator: ^AllocationCallbacks)
	ProcGetPhysicalDeviceSurfaceSupportKHR                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, surface: SurfaceKHR, pSupported: ^b32) -> Result
	ProcGetPhysicalDeviceSurfaceCapabilitiesKHR                         :: #type proc "stdcall" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: ^SurfaceCapabilitiesKHR) -> Result
	ProcGetPhysicalDeviceSurfaceFormatsKHR                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: ^SurfaceFormatKHR) -> Result
	ProcGetPhysicalDeviceSurfacePresentModesKHR                         :: #type proc "stdcall" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pPresentModeCount: ^u32, pPresentModes: ^PresentModeKHR) -> Result
	ProcCreateSwapchainKHR                                              :: #type proc "stdcall" (device: Device, pCreateInfo: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchain: ^SwapchainKHR) -> Result
	ProcDestroySwapchainKHR                                             :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, pAllocator: ^AllocationCallbacks)
	ProcGetSwapchainImagesKHR                                           :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, pSwapchainImageCount: ^u32, pSwapchainImages: ^Image) -> Result
	ProcAcquireNextImageKHR                                             :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, timeout: u64, semaphore: Semaphore, fence: Fence, pImageIndex: ^u32) -> Result
	ProcQueuePresentKHR                                                 :: #type proc "stdcall" (queue: Queue, pPresentInfo: ^PresentInfoKHR) -> Result
	ProcGetDeviceGroupPresentCapabilitiesKHR                            :: #type proc "stdcall" (device: Device, pDeviceGroupPresentCapabilities: ^DeviceGroupPresentCapabilitiesKHR) -> Result
	ProcGetDeviceGroupSurfacePresentModesKHR                            :: #type proc "stdcall" (device: Device, surface: SurfaceKHR, pModes: ^DeviceGroupPresentModeFlagsKHR) -> Result
	ProcGetPhysicalDevicePresentRectanglesKHR                           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pRectCount: ^u32, pRects: ^Rect2D) -> Result
	ProcAcquireNextImage2KHR                                            :: #type proc "stdcall" (device: Device, pAcquireInfo: ^AcquireNextImageInfoKHR, pImageIndex: ^u32) -> Result
	ProcGetPhysicalDeviceDisplayPropertiesKHR                           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPropertiesKHR) -> Result
	ProcGetPhysicalDeviceDisplayPlanePropertiesKHR                      :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPlanePropertiesKHR) -> Result
	ProcGetDisplayPlaneSupportedDisplaysKHR                             :: #type proc "stdcall" (physicalDevice: PhysicalDevice, planeIndex: u32, pDisplayCount: ^u32, pDisplays: ^DisplayKHR) -> Result
	ProcGetDisplayModePropertiesKHR                                     :: #type proc "stdcall" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: ^DisplayModePropertiesKHR) -> Result
	ProcCreateDisplayModeKHR                                            :: #type proc "stdcall" (physicalDevice: PhysicalDevice, display: DisplayKHR, pCreateInfo: ^DisplayModeCreateInfoKHR, pAllocator: ^AllocationCallbacks, pMode: ^DisplayModeKHR) -> Result
	ProcGetDisplayPlaneCapabilitiesKHR                                  :: #type proc "stdcall" (physicalDevice: PhysicalDevice, mode: DisplayModeKHR, planeIndex: u32, pCapabilities: ^DisplayPlaneCapabilitiesKHR) -> Result
	ProcCreateDisplayPlaneSurfaceKHR                                    :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^DisplaySurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateSharedSwapchainsKHR                                       :: #type proc "stdcall" (device: Device, swapchainCount: u32, pCreateInfos: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchains: ^SwapchainKHR) -> Result
	ProcGetPhysicalDeviceFeatures2KHR                                   :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures2)
	ProcGetPhysicalDeviceProperties2KHR                                 :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties2)
	ProcGetPhysicalDeviceFormatProperties2KHR                           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties2)
	ProcGetPhysicalDeviceImageFormatProperties2KHR                      :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: ^ImageFormatProperties2) -> Result
	ProcGetPhysicalDeviceQueueFamilyProperties2KHR                      :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties2)
	ProcGetPhysicalDeviceMemoryProperties2KHR                           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties2)
	ProcGetPhysicalDeviceSparseImageFormatProperties2KHR                :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties2)
	ProcGetDeviceGroupPeerMemoryFeaturesKHR                             :: #type proc "stdcall" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: ^PeerMemoryFeatureFlags)
	ProcCmdSetDeviceMaskKHR                                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, deviceMask: u32)
	ProcCmdDispatchBaseKHR                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcTrimCommandPoolKHR                                              :: #type proc "stdcall" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
	ProcEnumeratePhysicalDeviceGroupsKHR                                :: #type proc "stdcall" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: ^PhysicalDeviceGroupProperties) -> Result
	ProcGetPhysicalDeviceExternalBufferPropertiesKHR                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: ^ExternalBufferProperties)
	ProcGetMemoryFdKHR                                                  :: #type proc "stdcall" (device: Device, pGetFdInfo: ^MemoryGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcGetMemoryFdPropertiesKHR                                        :: #type proc "stdcall" (device: Device, handleType: ExternalMemoryHandleTypeFlags, fd: c.int, pMemoryFdProperties: ^MemoryFdPropertiesKHR) -> Result
	ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR                 :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: ^ExternalSemaphoreProperties)
	ProcImportSemaphoreFdKHR                                            :: #type proc "stdcall" (device: Device, pImportSemaphoreFdInfo: ^ImportSemaphoreFdInfoKHR) -> Result
	ProcGetSemaphoreFdKHR                                               :: #type proc "stdcall" (device: Device, pGetFdInfo: ^SemaphoreGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcCmdPushDescriptorSetKHR                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, set: u32, descriptorWriteCount: u32, pDescriptorWrites: ^WriteDescriptorSet)
	ProcCmdPushDescriptorSetWithTemplateKHR                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, descriptorUpdateTemplate: DescriptorUpdateTemplate, layout: PipelineLayout, set: u32, pData: rawptr)
	ProcCreateDescriptorUpdateTemplateKHR                               :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
	ProcDestroyDescriptorUpdateTemplateKHR                              :: #type proc "stdcall" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
	ProcUpdateDescriptorSetWithTemplateKHR                              :: #type proc "stdcall" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
	ProcCreateRenderPass2KHR                                            :: #type proc "stdcall" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcCmdBeginRenderPass2KHR                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
	ProcCmdNextSubpass2KHR                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
	ProcCmdEndRenderPass2KHR                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
	ProcGetSwapchainStatusKHR                                           :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcGetPhysicalDeviceExternalFencePropertiesKHR                     :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: ^ExternalFenceProperties)
	ProcImportFenceFdKHR                                                :: #type proc "stdcall" (device: Device, pImportFenceFdInfo: ^ImportFenceFdInfoKHR) -> Result
	ProcGetFenceFdKHR                                                   :: #type proc "stdcall" (device: Device, pGetFdInfo: ^FenceGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   :: #type proc "stdcall" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, pCounterCount: ^u32, pCounters: ^PerformanceCounterKHR, pCounterDescriptions: ^PerformanceCounterDescriptionKHR) -> Result
	ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPerformanceQueryCreateInfo: ^QueryPoolPerformanceCreateInfoKHR, pNumPasses: ^u32)
	ProcAcquireProfilingLockKHR                                         :: #type proc "stdcall" (device: Device, pInfo: ^AcquireProfilingLockInfoKHR) -> Result
	ProcReleaseProfilingLockKHR                                         :: #type proc "stdcall" (device: Device)
	ProcGetPhysicalDeviceSurfaceCapabilities2KHR                        :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceCapabilities: ^SurfaceCapabilities2KHR) -> Result
	ProcGetPhysicalDeviceSurfaceFormats2KHR                             :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: ^SurfaceFormat2KHR) -> Result
	ProcGetPhysicalDeviceDisplayProperties2KHR                          :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayProperties2KHR) -> Result
	ProcGetPhysicalDeviceDisplayPlaneProperties2KHR                     :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPlaneProperties2KHR) -> Result
	ProcGetDisplayModeProperties2KHR                                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: ^DisplayModeProperties2KHR) -> Result
	ProcGetDisplayPlaneCapabilities2KHR                                 :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pDisplayPlaneInfo: ^DisplayPlaneInfo2KHR, pCapabilities: ^DisplayPlaneCapabilities2KHR) -> Result
	ProcGetImageMemoryRequirements2KHR                                  :: #type proc "stdcall" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetBufferMemoryRequirements2KHR                                 :: #type proc "stdcall" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetImageSparseMemoryRequirements2KHR                            :: #type proc "stdcall" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements2)
	ProcCreateSamplerYcbcrConversionKHR                                 :: #type proc "stdcall" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
	ProcDestroySamplerYcbcrConversionKHR                                :: #type proc "stdcall" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
	ProcBindBufferMemory2KHR                                            :: #type proc "stdcall" (device: Device, bindInfoCount: u32, pBindInfos: ^BindBufferMemoryInfo) -> Result
	ProcBindImageMemory2KHR                                             :: #type proc "stdcall" (device: Device, bindInfoCount: u32, pBindInfos: ^BindImageMemoryInfo) -> Result
	ProcGetDescriptorSetLayoutSupportKHR                                :: #type proc "stdcall" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
	ProcCmdDrawIndirectCountKHR                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCountKHR                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcGetSemaphoreCounterValueKHR                                     :: #type proc "stdcall" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
	ProcWaitSemaphoresKHR                                               :: #type proc "stdcall" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
	ProcSignalSemaphoreKHR                                              :: #type proc "stdcall" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
	ProcGetPhysicalDeviceFragmentShadingRatesKHR                        :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pFragmentShadingRateCount: ^u32, pFragmentShadingRates: ^PhysicalDeviceFragmentShadingRateKHR) -> Result
	ProcCmdSetFragmentShadingRateKHR                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, pFragmentSize: ^Extent2D)
	ProcWaitForPresentKHR                                               :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, presentId: u64, timeout: u64) -> Result
	ProcGetBufferDeviceAddressKHR                                       :: #type proc "stdcall" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetBufferOpaqueCaptureAddressKHR                                :: #type proc "stdcall" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
	ProcGetDeviceMemoryOpaqueCaptureAddressKHR                          :: #type proc "stdcall" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
	ProcCreateDeferredOperationKHR                                      :: #type proc "stdcall" (device: Device, pAllocator: ^AllocationCallbacks, pDeferredOperation: ^DeferredOperationKHR) -> Result
	ProcDestroyDeferredOperationKHR                                     :: #type proc "stdcall" (device: Device, operation: DeferredOperationKHR, pAllocator: ^AllocationCallbacks)
	ProcGetDeferredOperationMaxConcurrencyKHR                           :: #type proc "stdcall" (device: Device, operation: DeferredOperationKHR) -> u32
	ProcGetDeferredOperationResultKHR                                   :: #type proc "stdcall" (device: Device, operation: DeferredOperationKHR) -> Result
	ProcDeferredOperationJoinKHR                                        :: #type proc "stdcall" (device: Device, operation: DeferredOperationKHR) -> Result
	ProcGetPipelineExecutablePropertiesKHR                              :: #type proc "stdcall" (device: Device, pPipelineInfo: ^PipelineInfoKHR, pExecutableCount: ^u32, pProperties: ^PipelineExecutablePropertiesKHR) -> Result
	ProcGetPipelineExecutableStatisticsKHR                              :: #type proc "stdcall" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pStatisticCount: ^u32, pStatistics: ^PipelineExecutableStatisticKHR) -> Result
	ProcGetPipelineExecutableInternalRepresentationsKHR                 :: #type proc "stdcall" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pInternalRepresentationCount: ^u32, pInternalRepresentations: ^PipelineExecutableInternalRepresentationKHR) -> Result
	ProcCmdSetEvent2KHR                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfoKHR)
	ProcCmdResetEvent2KHR                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2KHR)
	ProcCmdWaitEvents2KHR                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: ^Event, pDependencyInfos: ^DependencyInfoKHR)
	ProcCmdPipelineBarrier2KHR                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfoKHR)
	ProcCmdWriteTimestamp2KHR                                           :: #type proc "stdcall" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2KHR, queryPool: QueryPool, query: u32)
	ProcQueueSubmit2KHR                                                 :: #type proc "stdcall" (queue: Queue, submitCount: u32, pSubmits: ^SubmitInfo2KHR, fence: Fence) -> Result
	ProcCmdWriteBufferMarker2AMD                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2KHR, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
	ProcGetQueueCheckpointData2NV                                       :: #type proc "stdcall" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointData2NV)
	ProcCmdCopyBuffer2KHR                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2KHR)
	ProcCmdCopyImage2KHR                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2KHR)
	ProcCmdCopyBufferToImage2KHR                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2KHR)
	ProcCmdCopyImageToBuffer2KHR                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2KHR)
	ProcCmdBlitImage2KHR                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2KHR)
	ProcCmdResolveImage2KHR                                             :: #type proc "stdcall" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2KHR)
	ProcDebugReportCallbackEXT                                          :: #type proc "stdcall" (flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring, pUserData: rawptr) -> b32
	ProcCreateDebugReportCallbackEXT                                    :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^DebugReportCallbackCreateInfoEXT, pAllocator: ^AllocationCallbacks, pCallback: ^DebugReportCallbackEXT) -> Result
	ProcDestroyDebugReportCallbackEXT                                   :: #type proc "stdcall" (instance: Instance, callback: DebugReportCallbackEXT, pAllocator: ^AllocationCallbacks)
	ProcDebugReportMessageEXT                                           :: #type proc "stdcall" (instance: Instance, flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring)
	ProcDebugMarkerSetObjectTagEXT                                      :: #type proc "stdcall" (device: Device, pTagInfo: ^DebugMarkerObjectTagInfoEXT) -> Result
	ProcDebugMarkerSetObjectNameEXT                                     :: #type proc "stdcall" (device: Device, pNameInfo: ^DebugMarkerObjectNameInfoEXT) -> Result
	ProcCmdDebugMarkerBeginEXT                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
	ProcCmdDebugMarkerEndEXT                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdDebugMarkerInsertEXT                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
	ProcCmdBindTransformFeedbackBuffersEXT                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize, pSizes: ^DeviceSize)
	ProcCmdBeginTransformFeedbackEXT                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: ^Buffer, pCounterBufferOffsets: ^DeviceSize)
	ProcCmdEndTransformFeedbackEXT                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: ^Buffer, pCounterBufferOffsets: ^DeviceSize)
	ProcCmdBeginQueryIndexedEXT                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags, index: u32)
	ProcCmdEndQueryIndexedEXT                                           :: #type proc "stdcall" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, index: u32)
	ProcCmdDrawIndirectByteCountEXT                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, instanceCount: u32, firstInstance: u32, counterBuffer: Buffer, counterBufferOffset: DeviceSize, counterOffset: u32, vertexStride: u32)
	ProcCreateCuModuleNVX                                               :: #type proc "stdcall" (device: Device, pCreateInfo: ^CuModuleCreateInfoNVX, pAllocator: ^AllocationCallbacks, pModule: ^CuModuleNVX) -> Result
	ProcCreateCuFunctionNVX                                             :: #type proc "stdcall" (device: Device, pCreateInfo: ^CuFunctionCreateInfoNVX, pAllocator: ^AllocationCallbacks, pFunction: ^CuFunctionNVX) -> Result
	ProcDestroyCuModuleNVX                                              :: #type proc "stdcall" (device: Device, module: CuModuleNVX, pAllocator: ^AllocationCallbacks)
	ProcDestroyCuFunctionNVX                                            :: #type proc "stdcall" (device: Device, function: CuFunctionNVX, pAllocator: ^AllocationCallbacks)
	ProcCmdCuLaunchKernelNVX                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, pLaunchInfo: ^CuLaunchInfoNVX)
	ProcGetImageViewHandleNVX                                           :: #type proc "stdcall" (device: Device, pInfo: ^ImageViewHandleInfoNVX) -> u32
	ProcGetImageViewAddressNVX                                          :: #type proc "stdcall" (device: Device, imageView: ImageView, pProperties: ^ImageViewAddressPropertiesNVX) -> Result
	ProcCmdDrawIndirectCountAMD                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCountAMD                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcGetShaderInfoAMD                                                :: #type proc "stdcall" (device: Device, pipeline: Pipeline, shaderStage: ShaderStageFlags, infoType: ShaderInfoTypeAMD, pInfoSize: ^int, pInfo: rawptr) -> Result
	ProcGetPhysicalDeviceExternalImageFormatPropertiesNV                :: #type proc "stdcall" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, externalHandleType: ExternalMemoryHandleTypeFlagsNV, pExternalImageFormatProperties: ^ExternalImageFormatPropertiesNV) -> Result
	ProcCmdBeginConditionalRenderingEXT                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pConditionalRenderingBegin: ^ConditionalRenderingBeginInfoEXT)
	ProcCmdEndConditionalRenderingEXT                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdSetViewportWScalingNV                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewportWScalings: ^ViewportWScalingNV)
	ProcReleaseDisplayEXT                                               :: #type proc "stdcall" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
	ProcGetPhysicalDeviceSurfaceCapabilities2EXT                        :: #type proc "stdcall" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: ^SurfaceCapabilities2EXT) -> Result
	ProcDisplayPowerControlEXT                                          :: #type proc "stdcall" (device: Device, display: DisplayKHR, pDisplayPowerInfo: ^DisplayPowerInfoEXT) -> Result
	ProcRegisterDeviceEventEXT                                          :: #type proc "stdcall" (device: Device, pDeviceEventInfo: ^DeviceEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcRegisterDisplayEventEXT                                         :: #type proc "stdcall" (device: Device, display: DisplayKHR, pDisplayEventInfo: ^DisplayEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcGetSwapchainCounterEXT                                          :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, counter: SurfaceCounterFlagsEXT, pCounterValue: ^u64) -> Result
	ProcGetRefreshCycleDurationGOOGLE                                   :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, pDisplayTimingProperties: ^RefreshCycleDurationGOOGLE) -> Result
	ProcGetPastPresentationTimingGOOGLE                                 :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR, pPresentationTimingCount: ^u32, pPresentationTimings: ^PastPresentationTimingGOOGLE) -> Result
	ProcCmdSetDiscardRectangleEXT                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstDiscardRectangle: u32, discardRectangleCount: u32, pDiscardRectangles: ^Rect2D)
	ProcSetHdrMetadataEXT                                               :: #type proc "stdcall" (device: Device, swapchainCount: u32, pSwapchains: ^SwapchainKHR, pMetadata: ^HdrMetadataEXT)
	ProcDebugUtilsMessengerCallbackEXT                                  :: #type proc "stdcall" (messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32
	ProcSetDebugUtilsObjectNameEXT                                      :: #type proc "stdcall" (device: Device, pNameInfo: ^DebugUtilsObjectNameInfoEXT) -> Result
	ProcSetDebugUtilsObjectTagEXT                                       :: #type proc "stdcall" (device: Device, pTagInfo: ^DebugUtilsObjectTagInfoEXT) -> Result
	ProcQueueBeginDebugUtilsLabelEXT                                    :: #type proc "stdcall" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcQueueEndDebugUtilsLabelEXT                                      :: #type proc "stdcall" (queue: Queue)
	ProcQueueInsertDebugUtilsLabelEXT                                   :: #type proc "stdcall" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCmdBeginDebugUtilsLabelEXT                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCmdEndDebugUtilsLabelEXT                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdInsertDebugUtilsLabelEXT                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCreateDebugUtilsMessengerEXT                                    :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^DebugUtilsMessengerCreateInfoEXT, pAllocator: ^AllocationCallbacks, pMessenger: ^DebugUtilsMessengerEXT) -> Result
	ProcDestroyDebugUtilsMessengerEXT                                   :: #type proc "stdcall" (instance: Instance, messenger: DebugUtilsMessengerEXT, pAllocator: ^AllocationCallbacks)
	ProcSubmitDebugUtilsMessageEXT                                      :: #type proc "stdcall" (instance: Instance, messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT)
	ProcCmdSetSampleLocationsEXT                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, pSampleLocationsInfo: ^SampleLocationsInfoEXT)
	ProcGetPhysicalDeviceMultisamplePropertiesEXT                       :: #type proc "stdcall" (physicalDevice: PhysicalDevice, samples: SampleCountFlags, pMultisampleProperties: ^MultisamplePropertiesEXT)
	ProcGetImageDrmFormatModifierPropertiesEXT                          :: #type proc "stdcall" (device: Device, image: Image, pProperties: ^ImageDrmFormatModifierPropertiesEXT) -> Result
	ProcCreateValidationCacheEXT                                        :: #type proc "stdcall" (device: Device, pCreateInfo: ^ValidationCacheCreateInfoEXT, pAllocator: ^AllocationCallbacks, pValidationCache: ^ValidationCacheEXT) -> Result
	ProcDestroyValidationCacheEXT                                       :: #type proc "stdcall" (device: Device, validationCache: ValidationCacheEXT, pAllocator: ^AllocationCallbacks)
	ProcMergeValidationCachesEXT                                        :: #type proc "stdcall" (device: Device, dstCache: ValidationCacheEXT, srcCacheCount: u32, pSrcCaches: ^ValidationCacheEXT) -> Result
	ProcGetValidationCacheDataEXT                                       :: #type proc "stdcall" (device: Device, validationCache: ValidationCacheEXT, pDataSize: ^int, pData: rawptr) -> Result
	ProcCmdBindShadingRateImageNV                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
	ProcCmdSetViewportShadingRatePaletteNV                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pShadingRatePalettes: ^ShadingRatePaletteNV)
	ProcCmdSetCoarseSampleOrderNV                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, sampleOrderType: CoarseSampleOrderTypeNV, customSampleOrderCount: u32, pCustomSampleOrders: ^CoarseSampleOrderCustomNV)
	ProcCreateAccelerationStructureNV                                   :: #type proc "stdcall" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoNV, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureNV) -> Result
	ProcDestroyAccelerationStructureNV                                  :: #type proc "stdcall" (device: Device, accelerationStructure: AccelerationStructureNV, pAllocator: ^AllocationCallbacks)
	ProcGetAccelerationStructureMemoryRequirementsNV                    :: #type proc "stdcall" (device: Device, pInfo: ^AccelerationStructureMemoryRequirementsInfoNV, pMemoryRequirements: ^MemoryRequirements2KHR)
	ProcBindAccelerationStructureMemoryNV                               :: #type proc "stdcall" (device: Device, bindInfoCount: u32, pBindInfos: ^BindAccelerationStructureMemoryInfoNV) -> Result
	ProcCmdBuildAccelerationStructureNV                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pInfo: ^AccelerationStructureInfoNV, instanceData: Buffer, instanceOffset: DeviceSize, update: b32, dst: AccelerationStructureNV, src: AccelerationStructureNV, scratch: Buffer, scratchOffset: DeviceSize)
	ProcCmdCopyAccelerationStructureNV                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, dst: AccelerationStructureNV, src: AccelerationStructureNV, mode: CopyAccelerationStructureModeKHR)
	ProcCmdTraceRaysNV                                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, raygenShaderBindingTableBuffer: Buffer, raygenShaderBindingOffset: DeviceSize, missShaderBindingTableBuffer: Buffer, missShaderBindingOffset: DeviceSize, missShaderBindingStride: DeviceSize, hitShaderBindingTableBuffer: Buffer, hitShaderBindingOffset: DeviceSize, hitShaderBindingStride: DeviceSize, callableShaderBindingTableBuffer: Buffer, callableShaderBindingOffset: DeviceSize, callableShaderBindingStride: DeviceSize, width: u32, height: u32, depth: u32)
	ProcCreateRayTracingPipelinesNV                                     :: #type proc "stdcall" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^RayTracingPipelineCreateInfoNV, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcGetRayTracingShaderGroupHandlesKHR                              :: #type proc "stdcall" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcGetRayTracingShaderGroupHandlesNV                               :: #type proc "stdcall" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcGetAccelerationStructureHandleNV                                :: #type proc "stdcall" (device: Device, accelerationStructure: AccelerationStructureNV, dataSize: int, pData: rawptr) -> Result
	ProcCmdWriteAccelerationStructuresPropertiesNV                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureNV, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
	ProcCompileDeferredNV                                               :: #type proc "stdcall" (device: Device, pipeline: Pipeline, shader: u32) -> Result
	ProcGetMemoryHostPointerPropertiesEXT                               :: #type proc "stdcall" (device: Device, handleType: ExternalMemoryHandleTypeFlags, pHostPointer: rawptr, pMemoryHostPointerProperties: ^MemoryHostPointerPropertiesEXT) -> Result
	ProcCmdWriteBufferMarkerAMD                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
	ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pTimeDomainCount: ^u32, pTimeDomains: ^TimeDomainEXT) -> Result
	ProcGetCalibratedTimestampsEXT                                      :: #type proc "stdcall" (device: Device, timestampCount: u32, pTimestampInfos: ^CalibratedTimestampInfoEXT, pTimestamps: ^u64, pMaxDeviation: ^u64) -> Result
	ProcCmdDrawMeshTasksNV                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, taskCount: u32, firstTask: u32)
	ProcCmdDrawMeshTasksIndirectNV                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDrawMeshTasksIndirectCountNV                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdSetExclusiveScissorNV                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstExclusiveScissor: u32, exclusiveScissorCount: u32, pExclusiveScissors: ^Rect2D)
	ProcCmdSetCheckpointNV                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, pCheckpointMarker: rawptr)
	ProcGetQueueCheckpointDataNV                                        :: #type proc "stdcall" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointDataNV)
	ProcInitializePerformanceApiINTEL                                   :: #type proc "stdcall" (device: Device, pInitializeInfo: ^InitializePerformanceApiInfoINTEL) -> Result
	ProcUninitializePerformanceApiINTEL                                 :: #type proc "stdcall" (device: Device)
	ProcCmdSetPerformanceMarkerINTEL                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceMarkerInfoINTEL) -> Result
	ProcCmdSetPerformanceStreamMarkerINTEL                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceStreamMarkerInfoINTEL) -> Result
	ProcCmdSetPerformanceOverrideINTEL                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, pOverrideInfo: ^PerformanceOverrideInfoINTEL) -> Result
	ProcAcquirePerformanceConfigurationINTEL                            :: #type proc "stdcall" (device: Device, pAcquireInfo: ^PerformanceConfigurationAcquireInfoINTEL, pConfiguration: ^PerformanceConfigurationINTEL) -> Result
	ProcReleasePerformanceConfigurationINTEL                            :: #type proc "stdcall" (device: Device, configuration: PerformanceConfigurationINTEL) -> Result
	ProcQueueSetPerformanceConfigurationINTEL                           :: #type proc "stdcall" (queue: Queue, configuration: PerformanceConfigurationINTEL) -> Result
	ProcGetPerformanceParameterINTEL                                    :: #type proc "stdcall" (device: Device, parameter: PerformanceParameterTypeINTEL, pValue: ^PerformanceValueINTEL) -> Result
	ProcSetLocalDimmingAMD                                              :: #type proc "stdcall" (device: Device, swapChain: SwapchainKHR, localDimmingEnable: b32)
	ProcGetBufferDeviceAddressEXT                                       :: #type proc "stdcall" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetPhysicalDeviceToolPropertiesEXT                              :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: ^PhysicalDeviceToolPropertiesEXT) -> Result
	ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV                  :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^CooperativeMatrixPropertiesNV) -> Result
	ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pCombinationCount: ^u32, pCombinations: ^FramebufferMixedSamplesCombinationNV) -> Result
	ProcCreateHeadlessSurfaceEXT                                        :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^HeadlessSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCmdSetLineStippleEXT                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, lineStippleFactor: u32, lineStipplePattern: u16)
	ProcResetQueryPoolEXT                                               :: #type proc "stdcall" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcCmdSetCullModeEXT                                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
	ProcCmdSetFrontFaceEXT                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, frontFace: FrontFace)
	ProcCmdSetPrimitiveTopologyEXT                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
	ProcCmdSetViewportWithCountEXT                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: ^Viewport)
	ProcCmdSetScissorWithCountEXT                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: ^Rect2D)
	ProcCmdBindVertexBuffers2EXT                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize, pSizes: ^DeviceSize, pStrides: ^DeviceSize)
	ProcCmdSetDepthTestEnableEXT                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthTestEnable: b32)
	ProcCmdSetDepthWriteEnableEXT                                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
	ProcCmdSetDepthCompareOpEXT                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
	ProcCmdSetDepthBoundsTestEnableEXT                                  :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
	ProcCmdSetStencilTestEnableEXT                                      :: #type proc "stdcall" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
	ProcCmdSetStencilOpEXT                                              :: #type proc "stdcall" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
	ProcGetGeneratedCommandsMemoryRequirementsNV                        :: #type proc "stdcall" (device: Device, pInfo: ^GeneratedCommandsMemoryRequirementsInfoNV, pMemoryRequirements: ^MemoryRequirements2)
	ProcCmdPreprocessGeneratedCommandsNV                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
	ProcCmdExecuteGeneratedCommandsNV                                   :: #type proc "stdcall" (commandBuffer: CommandBuffer, isPreprocessed: b32, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
	ProcCmdBindPipelineShaderGroupNV                                    :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline, groupIndex: u32)
	ProcCreateIndirectCommandsLayoutNV                                  :: #type proc "stdcall" (device: Device, pCreateInfo: ^IndirectCommandsLayoutCreateInfoNV, pAllocator: ^AllocationCallbacks, pIndirectCommandsLayout: ^IndirectCommandsLayoutNV) -> Result
	ProcDestroyIndirectCommandsLayoutNV                                 :: #type proc "stdcall" (device: Device, indirectCommandsLayout: IndirectCommandsLayoutNV, pAllocator: ^AllocationCallbacks)
	ProcDeviceMemoryReportCallbackEXT                                   :: #type proc "stdcall" (pCallbackData: ^DeviceMemoryReportCallbackDataEXT, pUserData: rawptr)
	ProcAcquireDrmDisplayEXT                                            :: #type proc "stdcall" (physicalDevice: PhysicalDevice, drmFd: i32, display: DisplayKHR) -> Result
	ProcGetDrmDisplayEXT                                                :: #type proc "stdcall" (physicalDevice: PhysicalDevice, drmFd: i32, connectorId: u32, display: ^DisplayKHR) -> Result
	ProcCreatePrivateDataSlotEXT                                        :: #type proc "stdcall" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfoEXT, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlotEXT) -> Result
	ProcDestroyPrivateDataSlotEXT                                       :: #type proc "stdcall" (device: Device, privateDataSlot: PrivateDataSlotEXT, pAllocator: ^AllocationCallbacks)
	ProcSetPrivateDataEXT                                               :: #type proc "stdcall" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlotEXT, data: u64) -> Result
	ProcGetPrivateDataEXT                                               :: #type proc "stdcall" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlotEXT, pData: ^u64)
	ProcCmdSetFragmentShadingRateEnumNV                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, shadingRate: FragmentShadingRateNV)
	ProcAcquireWinrtDisplayNV                                           :: #type proc "stdcall" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
	ProcGetWinrtDisplayNV                                               :: #type proc "stdcall" (physicalDevice: PhysicalDevice, deviceRelativeId: u32, pDisplay: ^DisplayKHR) -> Result
	ProcCmdSetVertexInputEXT                                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, vertexBindingDescriptionCount: u32, pVertexBindingDescriptions: ^VertexInputBindingDescription2EXT, vertexAttributeDescriptionCount: u32, pVertexAttributeDescriptions: ^VertexInputAttributeDescription2EXT)
	ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI                   :: #type proc "stdcall" (device: Device, renderpass: RenderPass, pMaxWorkgroupSize: ^Extent2D) -> Result
	ProcCmdSubpassShadingHUAWEI                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer)
	ProcCmdBindInvocationMaskHUAWEI                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
	ProcGetMemoryRemoteAddressNV                                        :: #type proc "stdcall" (device: Device, pMemoryGetRemoteAddressInfo: ^MemoryGetRemoteAddressInfoNV, pAddress: ^RemoteAddressNV) -> Result
	ProcCmdSetPatchControlPointsEXT                                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, patchControlPoints: u32)
	ProcCmdSetRasterizerDiscardEnableEXT                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
	ProcCmdSetDepthBiasEnableEXT                                        :: #type proc "stdcall" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
	ProcCmdSetLogicOpEXT                                                :: #type proc "stdcall" (commandBuffer: CommandBuffer, logicOp: LogicOp)
	ProcCmdSetPrimitiveRestartEnableEXT                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
	ProcCmdDrawMultiEXT                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, drawCount: u32, pVertexInfo: ^MultiDrawInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32)
	ProcCmdDrawMultiIndexedEXT                                          :: #type proc "stdcall" (commandBuffer: CommandBuffer, drawCount: u32, pIndexInfo: ^MultiDrawIndexedInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32, pVertexOffset: ^i32)
	ProcCreateAccelerationStructureKHR                                  :: #type proc "stdcall" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoKHR, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureKHR) -> Result
	ProcDestroyAccelerationStructureKHR                                 :: #type proc "stdcall" (device: Device, accelerationStructure: AccelerationStructureKHR, pAllocator: ^AllocationCallbacks)
	ProcCmdBuildAccelerationStructuresKHR                               :: #type proc "stdcall" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^^AccelerationStructureBuildRangeInfoKHR)
	ProcCmdBuildAccelerationStructuresIndirectKHR                       :: #type proc "stdcall" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, pIndirectDeviceAddresses: ^DeviceAddress, pIndirectStrides: ^u32, ppMaxPrimitiveCounts: ^^u32)
	ProcBuildAccelerationStructuresKHR                                  :: #type proc "stdcall" (device: Device, deferredOperation: DeferredOperationKHR, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^^AccelerationStructureBuildRangeInfoKHR) -> Result
	ProcCopyAccelerationStructureKHR                                    :: #type proc "stdcall" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureInfoKHR) -> Result
	ProcCopyAccelerationStructureToMemoryKHR                            :: #type proc "stdcall" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR) -> Result
	ProcCopyMemoryToAccelerationStructureKHR                            :: #type proc "stdcall" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR) -> Result
	ProcWriteAccelerationStructuresPropertiesKHR                        :: #type proc "stdcall" (device: Device, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureKHR, queryType: QueryType, dataSize: int, pData: rawptr, stride: int) -> Result
	ProcCmdCopyAccelerationStructureKHR                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureInfoKHR)
	ProcCmdCopyAccelerationStructureToMemoryKHR                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR)
	ProcCmdCopyMemoryToAccelerationStructureKHR                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR)
	ProcGetAccelerationStructureDeviceAddressKHR                        :: #type proc "stdcall" (device: Device, pInfo: ^AccelerationStructureDeviceAddressInfoKHR) -> DeviceAddress
	ProcCmdWriteAccelerationStructuresPropertiesKHR                     :: #type proc "stdcall" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureKHR, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
	ProcGetDeviceAccelerationStructureCompatibilityKHR                  :: #type proc "stdcall" (device: Device, pVersionInfo: ^AccelerationStructureVersionInfoKHR, pCompatibility: ^AccelerationStructureCompatibilityKHR)
	ProcGetAccelerationStructureBuildSizesKHR                           :: #type proc "stdcall" (device: Device, buildType: AccelerationStructureBuildTypeKHR, pBuildInfo: ^AccelerationStructureBuildGeometryInfoKHR, pMaxPrimitiveCounts: ^u32, pSizeInfo: ^AccelerationStructureBuildSizesInfoKHR)
	ProcCmdTraceRaysKHR                                                 :: #type proc "stdcall" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: ^StridedDeviceAddressRegionKHR, pMissShaderBindingTable: ^StridedDeviceAddressRegionKHR, pHitShaderBindingTable: ^StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: ^StridedDeviceAddressRegionKHR, width: u32, height: u32, depth: u32)
	ProcCreateRayTracingPipelinesKHR                                    :: #type proc "stdcall" (device: Device, deferredOperation: DeferredOperationKHR, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^RayTracingPipelineCreateInfoKHR, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR                 :: #type proc "stdcall" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcCmdTraceRaysIndirectKHR                                         :: #type proc "stdcall" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: ^StridedDeviceAddressRegionKHR, pMissShaderBindingTable: ^StridedDeviceAddressRegionKHR, pHitShaderBindingTable: ^StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: ^StridedDeviceAddressRegionKHR, indirectDeviceAddress: DeviceAddress)
	ProcGetRayTracingShaderGroupStackSizeKHR                            :: #type proc "stdcall" (device: Device, pipeline: Pipeline, group: u32, groupShader: ShaderGroupShaderKHR) -> DeviceSize
	ProcCmdSetRayTracingPipelineStackSizeKHR                            :: #type proc "stdcall" (commandBuffer: CommandBuffer, pipelineStackSize: u32)
	ProcCreateWin32SurfaceKHR                                           :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^Win32SurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcGetPhysicalDeviceWin32PresentationSupportKHR                    :: #type proc "stdcall" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32) -> b32
	ProcGetMemoryWin32HandleKHR                                         :: #type proc "stdcall" (device: Device, pGetWin32HandleInfo: ^MemoryGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcGetMemoryWin32HandlePropertiesKHR                               :: #type proc "stdcall" (device: Device, handleType: ExternalMemoryHandleTypeFlags, handle: HANDLE, pMemoryWin32HandleProperties: ^MemoryWin32HandlePropertiesKHR) -> Result
	ProcImportSemaphoreWin32HandleKHR                                   :: #type proc "stdcall" (device: Device, pImportSemaphoreWin32HandleInfo: ^ImportSemaphoreWin32HandleInfoKHR) -> Result
	ProcGetSemaphoreWin32HandleKHR                                      :: #type proc "stdcall" (device: Device, pGetWin32HandleInfo: ^SemaphoreGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcImportFenceWin32HandleKHR                                       :: #type proc "stdcall" (device: Device, pImportFenceWin32HandleInfo: ^ImportFenceWin32HandleInfoKHR) -> Result
	ProcGetFenceWin32HandleKHR                                          :: #type proc "stdcall" (device: Device, pGetWin32HandleInfo: ^FenceGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcGetMemoryWin32HandleNV                                          :: #type proc "stdcall" (device: Device, memory: DeviceMemory, handleType: ExternalMemoryHandleTypeFlagsNV, pHandle: ^HANDLE) -> Result
	ProcGetPhysicalDeviceSurfacePresentModes2EXT                        :: #type proc "stdcall" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pPresentModeCount: ^u32, pPresentModes: ^PresentModeKHR) -> Result
	ProcAcquireFullScreenExclusiveModeEXT                               :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcReleaseFullScreenExclusiveModeEXT                               :: #type proc "stdcall" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcGetDeviceGroupSurfacePresentModes2EXT                           :: #type proc "stdcall" (device: Device, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pModes: ^DeviceGroupPresentModeFlagsKHR) -> Result
	ProcCreateMetalSurfaceEXT                                           :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^MetalSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateMacOSSurfaceMVK                                           :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^MacOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateIOSSurfaceMVK                                             :: #type proc "stdcall" (instance: Instance, pCreateInfo: ^IOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
} else {
	ProcAllocationFunction                                              :: #type proc "c" (pUserData: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
	ProcFreeFunction                                                    :: #type proc "c" (pUserData: rawptr, pMemory: rawptr)
	ProcInternalAllocationNotification                                  :: #type proc "c" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
	ProcInternalFreeNotification                                        :: #type proc "c" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
	ProcReallocationFunction                                            :: #type proc "c" (pUserData: rawptr, pOriginal: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
	ProcVoidFunction                                                    :: #type proc "c" ()
	ProcCreateInstance                                                  :: #type proc "c" (pCreateInfo: ^InstanceCreateInfo, pAllocator: ^AllocationCallbacks, pInstance: ^Instance) -> Result
	ProcDestroyInstance                                                 :: #type proc "c" (instance: Instance, pAllocator: ^AllocationCallbacks)
	ProcEnumeratePhysicalDevices                                        :: #type proc "c" (instance: Instance, pPhysicalDeviceCount: ^u32, pPhysicalDevices: ^PhysicalDevice) -> Result
	ProcGetPhysicalDeviceFeatures                                       :: #type proc "c" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures)
	ProcGetPhysicalDeviceFormatProperties                               :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties)
	ProcGetPhysicalDeviceImageFormatProperties                          :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, pImageFormatProperties: ^ImageFormatProperties) -> Result
	ProcGetPhysicalDeviceProperties                                     :: #type proc "c" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties)
	ProcGetPhysicalDeviceQueueFamilyProperties                          :: #type proc "c" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties)
	ProcGetPhysicalDeviceMemoryProperties                               :: #type proc "c" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties)
	ProcGetInstanceProcAddr                                             :: #type proc "c" (instance: Instance, pName: cstring) -> ProcVoidFunction
	ProcGetDeviceProcAddr                                               :: #type proc "c" (device: Device, pName: cstring) -> ProcVoidFunction
	ProcCreateDevice                                                    :: #type proc "c" (physicalDevice: PhysicalDevice, pCreateInfo: ^DeviceCreateInfo, pAllocator: ^AllocationCallbacks, pDevice: ^Device) -> Result
	ProcDestroyDevice                                                   :: #type proc "c" (device: Device, pAllocator: ^AllocationCallbacks)
	ProcEnumerateInstanceExtensionProperties                            :: #type proc "c" (pLayerName: cstring, pPropertyCount: ^u32, pProperties: ^ExtensionProperties) -> Result
	ProcEnumerateDeviceExtensionProperties                              :: #type proc "c" (physicalDevice: PhysicalDevice, pLayerName: cstring, pPropertyCount: ^u32, pProperties: ^ExtensionProperties) -> Result
	ProcEnumerateInstanceLayerProperties                                :: #type proc "c" (pPropertyCount: ^u32, pProperties: ^LayerProperties) -> Result
	ProcEnumerateDeviceLayerProperties                                  :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^LayerProperties) -> Result
	ProcGetDeviceQueue                                                  :: #type proc "c" (device: Device, queueFamilyIndex: u32, queueIndex: u32, pQueue: ^Queue)
	ProcQueueSubmit                                                     :: #type proc "c" (queue: Queue, submitCount: u32, pSubmits: ^SubmitInfo, fence: Fence) -> Result
	ProcQueueWaitIdle                                                   :: #type proc "c" (queue: Queue) -> Result
	ProcDeviceWaitIdle                                                  :: #type proc "c" (device: Device) -> Result
	ProcAllocateMemory                                                  :: #type proc "c" (device: Device, pAllocateInfo: ^MemoryAllocateInfo, pAllocator: ^AllocationCallbacks, pMemory: ^DeviceMemory) -> Result
	ProcFreeMemory                                                      :: #type proc "c" (device: Device, memory: DeviceMemory, pAllocator: ^AllocationCallbacks)
	ProcMapMemory                                                       :: #type proc "c" (device: Device, memory: DeviceMemory, offset: DeviceSize, size: DeviceSize, flags: MemoryMapFlags, ppData: ^rawptr) -> Result
	ProcUnmapMemory                                                     :: #type proc "c" (device: Device, memory: DeviceMemory)
	ProcFlushMappedMemoryRanges                                         :: #type proc "c" (device: Device, memoryRangeCount: u32, pMemoryRanges: ^MappedMemoryRange) -> Result
	ProcInvalidateMappedMemoryRanges                                    :: #type proc "c" (device: Device, memoryRangeCount: u32, pMemoryRanges: ^MappedMemoryRange) -> Result
	ProcGetDeviceMemoryCommitment                                       :: #type proc "c" (device: Device, memory: DeviceMemory, pCommittedMemoryInBytes: ^DeviceSize)
	ProcBindBufferMemory                                                :: #type proc "c" (device: Device, buffer: Buffer, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
	ProcBindImageMemory                                                 :: #type proc "c" (device: Device, image: Image, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
	ProcGetBufferMemoryRequirements                                     :: #type proc "c" (device: Device, buffer: Buffer, pMemoryRequirements: ^MemoryRequirements)
	ProcGetImageMemoryRequirements                                      :: #type proc "c" (device: Device, image: Image, pMemoryRequirements: ^MemoryRequirements)
	ProcGetImageSparseMemoryRequirements                                :: #type proc "c" (device: Device, image: Image, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements)
	ProcGetPhysicalDeviceSparseImageFormatProperties                    :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, samples: SampleCountFlags, usage: ImageUsageFlags, tiling: ImageTiling, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties)
	ProcQueueBindSparse                                                 :: #type proc "c" (queue: Queue, bindInfoCount: u32, pBindInfo: ^BindSparseInfo, fence: Fence) -> Result
	ProcCreateFence                                                     :: #type proc "c" (device: Device, pCreateInfo: ^FenceCreateInfo, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcDestroyFence                                                    :: #type proc "c" (device: Device, fence: Fence, pAllocator: ^AllocationCallbacks)
	ProcResetFences                                                     :: #type proc "c" (device: Device, fenceCount: u32, pFences: ^Fence) -> Result
	ProcGetFenceStatus                                                  :: #type proc "c" (device: Device, fence: Fence) -> Result
	ProcWaitForFences                                                   :: #type proc "c" (device: Device, fenceCount: u32, pFences: ^Fence, waitAll: b32, timeout: u64) -> Result
	ProcCreateSemaphore                                                 :: #type proc "c" (device: Device, pCreateInfo: ^SemaphoreCreateInfo, pAllocator: ^AllocationCallbacks, pSemaphore: ^Semaphore) -> Result
	ProcDestroySemaphore                                                :: #type proc "c" (device: Device, semaphore: Semaphore, pAllocator: ^AllocationCallbacks)
	ProcCreateEvent                                                     :: #type proc "c" (device: Device, pCreateInfo: ^EventCreateInfo, pAllocator: ^AllocationCallbacks, pEvent: ^Event) -> Result
	ProcDestroyEvent                                                    :: #type proc "c" (device: Device, event: Event, pAllocator: ^AllocationCallbacks)
	ProcGetEventStatus                                                  :: #type proc "c" (device: Device, event: Event) -> Result
	ProcSetEvent                                                        :: #type proc "c" (device: Device, event: Event) -> Result
	ProcResetEvent                                                      :: #type proc "c" (device: Device, event: Event) -> Result
	ProcCreateQueryPool                                                 :: #type proc "c" (device: Device, pCreateInfo: ^QueryPoolCreateInfo, pAllocator: ^AllocationCallbacks, pQueryPool: ^QueryPool) -> Result
	ProcDestroyQueryPool                                                :: #type proc "c" (device: Device, queryPool: QueryPool, pAllocator: ^AllocationCallbacks)
	ProcGetQueryPoolResults                                             :: #type proc "c" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dataSize: int, pData: rawptr, stride: DeviceSize, flags: QueryResultFlags) -> Result
	ProcCreateBuffer                                                    :: #type proc "c" (device: Device, pCreateInfo: ^BufferCreateInfo, pAllocator: ^AllocationCallbacks, pBuffer: ^Buffer) -> Result
	ProcDestroyBuffer                                                   :: #type proc "c" (device: Device, buffer: Buffer, pAllocator: ^AllocationCallbacks)
	ProcCreateBufferView                                                :: #type proc "c" (device: Device, pCreateInfo: ^BufferViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^BufferView) -> Result
	ProcDestroyBufferView                                               :: #type proc "c" (device: Device, bufferView: BufferView, pAllocator: ^AllocationCallbacks)
	ProcCreateImage                                                     :: #type proc "c" (device: Device, pCreateInfo: ^ImageCreateInfo, pAllocator: ^AllocationCallbacks, pImage: ^Image) -> Result
	ProcDestroyImage                                                    :: #type proc "c" (device: Device, image: Image, pAllocator: ^AllocationCallbacks)
	ProcGetImageSubresourceLayout                                       :: #type proc "c" (device: Device, image: Image, pSubresource: ^ImageSubresource, pLayout: ^SubresourceLayout)
	ProcCreateImageView                                                 :: #type proc "c" (device: Device, pCreateInfo: ^ImageViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^ImageView) -> Result
	ProcDestroyImageView                                                :: #type proc "c" (device: Device, imageView: ImageView, pAllocator: ^AllocationCallbacks)
	ProcCreateShaderModule                                              :: #type proc "c" (device: Device, pCreateInfo: ^ShaderModuleCreateInfo, pAllocator: ^AllocationCallbacks, pShaderModule: ^ShaderModule) -> Result
	ProcDestroyShaderModule                                             :: #type proc "c" (device: Device, shaderModule: ShaderModule, pAllocator: ^AllocationCallbacks)
	ProcCreatePipelineCache                                             :: #type proc "c" (device: Device, pCreateInfo: ^PipelineCacheCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineCache: ^PipelineCache) -> Result
	ProcDestroyPipelineCache                                            :: #type proc "c" (device: Device, pipelineCache: PipelineCache, pAllocator: ^AllocationCallbacks)
	ProcGetPipelineCacheData                                            :: #type proc "c" (device: Device, pipelineCache: PipelineCache, pDataSize: ^int, pData: rawptr) -> Result
	ProcMergePipelineCaches                                             :: #type proc "c" (device: Device, dstCache: PipelineCache, srcCacheCount: u32, pSrcCaches: ^PipelineCache) -> Result
	ProcCreateGraphicsPipelines                                         :: #type proc "c" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^GraphicsPipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcCreateComputePipelines                                          :: #type proc "c" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^ComputePipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcDestroyPipeline                                                 :: #type proc "c" (device: Device, pipeline: Pipeline, pAllocator: ^AllocationCallbacks)
	ProcCreatePipelineLayout                                            :: #type proc "c" (device: Device, pCreateInfo: ^PipelineLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineLayout: ^PipelineLayout) -> Result
	ProcDestroyPipelineLayout                                           :: #type proc "c" (device: Device, pipelineLayout: PipelineLayout, pAllocator: ^AllocationCallbacks)
	ProcCreateSampler                                                   :: #type proc "c" (device: Device, pCreateInfo: ^SamplerCreateInfo, pAllocator: ^AllocationCallbacks, pSampler: ^Sampler) -> Result
	ProcDestroySampler                                                  :: #type proc "c" (device: Device, sampler: Sampler, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorSetLayout                                       :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pSetLayout: ^DescriptorSetLayout) -> Result
	ProcDestroyDescriptorSetLayout                                      :: #type proc "c" (device: Device, descriptorSetLayout: DescriptorSetLayout, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorPool                                            :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorPoolCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorPool: ^DescriptorPool) -> Result
	ProcDestroyDescriptorPool                                           :: #type proc "c" (device: Device, descriptorPool: DescriptorPool, pAllocator: ^AllocationCallbacks)
	ProcResetDescriptorPool                                             :: #type proc "c" (device: Device, descriptorPool: DescriptorPool, flags: DescriptorPoolResetFlags) -> Result
	ProcAllocateDescriptorSets                                          :: #type proc "c" (device: Device, pAllocateInfo: ^DescriptorSetAllocateInfo, pDescriptorSets: ^DescriptorSet) -> Result
	ProcFreeDescriptorSets                                              :: #type proc "c" (device: Device, descriptorPool: DescriptorPool, descriptorSetCount: u32, pDescriptorSets: ^DescriptorSet) -> Result
	ProcUpdateDescriptorSets                                            :: #type proc "c" (device: Device, descriptorWriteCount: u32, pDescriptorWrites: ^WriteDescriptorSet, descriptorCopyCount: u32, pDescriptorCopies: ^CopyDescriptorSet)
	ProcCreateFramebuffer                                               :: #type proc "c" (device: Device, pCreateInfo: ^FramebufferCreateInfo, pAllocator: ^AllocationCallbacks, pFramebuffer: ^Framebuffer) -> Result
	ProcDestroyFramebuffer                                              :: #type proc "c" (device: Device, framebuffer: Framebuffer, pAllocator: ^AllocationCallbacks)
	ProcCreateRenderPass                                                :: #type proc "c" (device: Device, pCreateInfo: ^RenderPassCreateInfo, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcDestroyRenderPass                                               :: #type proc "c" (device: Device, renderPass: RenderPass, pAllocator: ^AllocationCallbacks)
	ProcGetRenderAreaGranularity                                        :: #type proc "c" (device: Device, renderPass: RenderPass, pGranularity: ^Extent2D)
	ProcCreateCommandPool                                               :: #type proc "c" (device: Device, pCreateInfo: ^CommandPoolCreateInfo, pAllocator: ^AllocationCallbacks, pCommandPool: ^CommandPool) -> Result
	ProcDestroyCommandPool                                              :: #type proc "c" (device: Device, commandPool: CommandPool, pAllocator: ^AllocationCallbacks)
	ProcResetCommandPool                                                :: #type proc "c" (device: Device, commandPool: CommandPool, flags: CommandPoolResetFlags) -> Result
	ProcAllocateCommandBuffers                                          :: #type proc "c" (device: Device, pAllocateInfo: ^CommandBufferAllocateInfo, pCommandBuffers: ^CommandBuffer) -> Result
	ProcFreeCommandBuffers                                              :: #type proc "c" (device: Device, commandPool: CommandPool, commandBufferCount: u32, pCommandBuffers: ^CommandBuffer)
	ProcBeginCommandBuffer                                              :: #type proc "c" (commandBuffer: CommandBuffer, pBeginInfo: ^CommandBufferBeginInfo) -> Result
	ProcEndCommandBuffer                                                :: #type proc "c" (commandBuffer: CommandBuffer) -> Result
	ProcResetCommandBuffer                                              :: #type proc "c" (commandBuffer: CommandBuffer, flags: CommandBufferResetFlags) -> Result
	ProcCmdBindPipeline                                                 :: #type proc "c" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline)
	ProcCmdSetViewport                                                  :: #type proc "c" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewports: ^Viewport)
	ProcCmdSetScissor                                                   :: #type proc "c" (commandBuffer: CommandBuffer, firstScissor: u32, scissorCount: u32, pScissors: ^Rect2D)
	ProcCmdSetLineWidth                                                 :: #type proc "c" (commandBuffer: CommandBuffer, lineWidth: f32)
	ProcCmdSetDepthBias                                                 :: #type proc "c" (commandBuffer: CommandBuffer, depthBiasConstantFactor: f32, depthBiasClamp: f32, depthBiasSlopeFactor: f32)
	ProcCmdSetBlendConstants                                            :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdSetDepthBounds                                               :: #type proc "c" (commandBuffer: CommandBuffer, minDepthBounds: f32, maxDepthBounds: f32)
	ProcCmdSetStencilCompareMask                                        :: #type proc "c" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, compareMask: u32)
	ProcCmdSetStencilWriteMask                                          :: #type proc "c" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, writeMask: u32)
	ProcCmdSetStencilReference                                          :: #type proc "c" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, reference: u32)
	ProcCmdBindDescriptorSets                                           :: #type proc "c" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, firstSet: u32, descriptorSetCount: u32, pDescriptorSets: ^DescriptorSet, dynamicOffsetCount: u32, pDynamicOffsets: ^u32)
	ProcCmdBindIndexBuffer                                              :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, indexType: IndexType)
	ProcCmdBindVertexBuffers                                            :: #type proc "c" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize)
	ProcCmdDraw                                                         :: #type proc "c" (commandBuffer: CommandBuffer, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32)
	ProcCmdDrawIndexed                                                  :: #type proc "c" (commandBuffer: CommandBuffer, indexCount: u32, instanceCount: u32, firstIndex: u32, vertexOffset: i32, firstInstance: u32)
	ProcCmdDrawIndirect                                                 :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirect                                          :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDispatch                                                     :: #type proc "c" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcCmdDispatchIndirect                                             :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize)
	ProcCmdCopyBuffer                                                   :: #type proc "c" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstBuffer: Buffer, regionCount: u32, pRegions: ^BufferCopy)
	ProcCmdCopyImage                                                    :: #type proc "c" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageCopy)
	ProcCmdBlitImage                                                    :: #type proc "c" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageBlit, filter: Filter)
	ProcCmdCopyBufferToImage                                            :: #type proc "c" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^BufferImageCopy)
	ProcCmdCopyImageToBuffer                                            :: #type proc "c" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstBuffer: Buffer, regionCount: u32, pRegions: ^BufferImageCopy)
	ProcCmdUpdateBuffer                                                 :: #type proc "c" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, dataSize: DeviceSize, pData: rawptr)
	ProcCmdFillBuffer                                                   :: #type proc "c" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, size: DeviceSize, data: u32)
	ProcCmdClearColorImage                                              :: #type proc "c" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pColor: ^ClearColorValue, rangeCount: u32, pRanges: ^ImageSubresourceRange)
	ProcCmdClearDepthStencilImage                                       :: #type proc "c" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pDepthStencil: ^ClearDepthStencilValue, rangeCount: u32, pRanges: ^ImageSubresourceRange)
	ProcCmdClearAttachments                                             :: #type proc "c" (commandBuffer: CommandBuffer, attachmentCount: u32, pAttachments: ^ClearAttachment, rectCount: u32, pRects: ^ClearRect)
	ProcCmdResolveImage                                                 :: #type proc "c" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: ^ImageResolve)
	ProcCmdSetEvent                                                     :: #type proc "c" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
	ProcCmdResetEvent                                                   :: #type proc "c" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
	ProcCmdWaitEvents                                                   :: #type proc "c" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: ^Event, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, memoryBarrierCount: u32, pMemoryBarriers: ^MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: ^BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: ^ImageMemoryBarrier)
	ProcCmdPipelineBarrier                                              :: #type proc "c" (commandBuffer: CommandBuffer, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, dependencyFlags: DependencyFlags, memoryBarrierCount: u32, pMemoryBarriers: ^MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: ^BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: ^ImageMemoryBarrier)
	ProcCmdBeginQuery                                                   :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags)
	ProcCmdEndQuery                                                     :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32)
	ProcCmdResetQueryPool                                               :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcCmdWriteTimestamp                                               :: #type proc "c" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, queryPool: QueryPool, query: u32)
	ProcCmdCopyQueryPoolResults                                         :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dstBuffer: Buffer, dstOffset: DeviceSize, stride: DeviceSize, flags: QueryResultFlags)
	ProcCmdPushConstants                                                :: #type proc "c" (commandBuffer: CommandBuffer, layout: PipelineLayout, stageFlags: ShaderStageFlags, offset: u32, size: u32, pValues: rawptr)
	ProcCmdBeginRenderPass                                              :: #type proc "c" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, contents: SubpassContents)
	ProcCmdNextSubpass                                                  :: #type proc "c" (commandBuffer: CommandBuffer, contents: SubpassContents)
	ProcCmdEndRenderPass                                                :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdExecuteCommands                                              :: #type proc "c" (commandBuffer: CommandBuffer, commandBufferCount: u32, pCommandBuffers: ^CommandBuffer)
	ProcEnumerateInstanceVersion                                        :: #type proc "c" (pApiVersion: ^u32) -> Result
	ProcBindBufferMemory2                                               :: #type proc "c" (device: Device, bindInfoCount: u32, pBindInfos: ^BindBufferMemoryInfo) -> Result
	ProcBindImageMemory2                                                :: #type proc "c" (device: Device, bindInfoCount: u32, pBindInfos: ^BindImageMemoryInfo) -> Result
	ProcGetDeviceGroupPeerMemoryFeatures                                :: #type proc "c" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: ^PeerMemoryFeatureFlags)
	ProcCmdSetDeviceMask                                                :: #type proc "c" (commandBuffer: CommandBuffer, deviceMask: u32)
	ProcCmdDispatchBase                                                 :: #type proc "c" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcEnumeratePhysicalDeviceGroups                                   :: #type proc "c" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: ^PhysicalDeviceGroupProperties) -> Result
	ProcGetImageMemoryRequirements2                                     :: #type proc "c" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetBufferMemoryRequirements2                                    :: #type proc "c" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetImageSparseMemoryRequirements2                               :: #type proc "c" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements2)
	ProcGetPhysicalDeviceFeatures2                                      :: #type proc "c" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures2)
	ProcGetPhysicalDeviceProperties2                                    :: #type proc "c" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties2)
	ProcGetPhysicalDeviceFormatProperties2                              :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties2)
	ProcGetPhysicalDeviceImageFormatProperties2                         :: #type proc "c" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: ^ImageFormatProperties2) -> Result
	ProcGetPhysicalDeviceQueueFamilyProperties2                         :: #type proc "c" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties2)
	ProcGetPhysicalDeviceMemoryProperties2                              :: #type proc "c" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties2)
	ProcGetPhysicalDeviceSparseImageFormatProperties2                   :: #type proc "c" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties2)
	ProcTrimCommandPool                                                 :: #type proc "c" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
	ProcGetDeviceQueue2                                                 :: #type proc "c" (device: Device, pQueueInfo: ^DeviceQueueInfo2, pQueue: ^Queue)
	ProcCreateSamplerYcbcrConversion                                    :: #type proc "c" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
	ProcDestroySamplerYcbcrConversion                                   :: #type proc "c" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
	ProcCreateDescriptorUpdateTemplate                                  :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
	ProcDestroyDescriptorUpdateTemplate                                 :: #type proc "c" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
	ProcUpdateDescriptorSetWithTemplate                                 :: #type proc "c" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
	ProcGetPhysicalDeviceExternalBufferProperties                       :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: ^ExternalBufferProperties)
	ProcGetPhysicalDeviceExternalFenceProperties                        :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: ^ExternalFenceProperties)
	ProcGetPhysicalDeviceExternalSemaphoreProperties                    :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: ^ExternalSemaphoreProperties)
	ProcGetDescriptorSetLayoutSupport                                   :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
	ProcCmdDrawIndirectCount                                            :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCount                                     :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCreateRenderPass2                                               :: #type proc "c" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcCmdBeginRenderPass2                                             :: #type proc "c" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
	ProcCmdNextSubpass2                                                 :: #type proc "c" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
	ProcCmdEndRenderPass2                                               :: #type proc "c" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
	ProcResetQueryPool                                                  :: #type proc "c" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcGetSemaphoreCounterValue                                        :: #type proc "c" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
	ProcWaitSemaphores                                                  :: #type proc "c" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
	ProcSignalSemaphore                                                 :: #type proc "c" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
	ProcGetBufferDeviceAddress                                          :: #type proc "c" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetBufferOpaqueCaptureAddress                                   :: #type proc "c" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
	ProcGetDeviceMemoryOpaqueCaptureAddress                             :: #type proc "c" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
	ProcDestroySurfaceKHR                                               :: #type proc "c" (instance: Instance, surface: SurfaceKHR, pAllocator: ^AllocationCallbacks)
	ProcGetPhysicalDeviceSurfaceSupportKHR                              :: #type proc "c" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, surface: SurfaceKHR, pSupported: ^b32) -> Result
	ProcGetPhysicalDeviceSurfaceCapabilitiesKHR                         :: #type proc "c" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: ^SurfaceCapabilitiesKHR) -> Result
	ProcGetPhysicalDeviceSurfaceFormatsKHR                              :: #type proc "c" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: ^SurfaceFormatKHR) -> Result
	ProcGetPhysicalDeviceSurfacePresentModesKHR                         :: #type proc "c" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pPresentModeCount: ^u32, pPresentModes: ^PresentModeKHR) -> Result
	ProcCreateSwapchainKHR                                              :: #type proc "c" (device: Device, pCreateInfo: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchain: ^SwapchainKHR) -> Result
	ProcDestroySwapchainKHR                                             :: #type proc "c" (device: Device, swapchain: SwapchainKHR, pAllocator: ^AllocationCallbacks)
	ProcGetSwapchainImagesKHR                                           :: #type proc "c" (device: Device, swapchain: SwapchainKHR, pSwapchainImageCount: ^u32, pSwapchainImages: ^Image) -> Result
	ProcAcquireNextImageKHR                                             :: #type proc "c" (device: Device, swapchain: SwapchainKHR, timeout: u64, semaphore: Semaphore, fence: Fence, pImageIndex: ^u32) -> Result
	ProcQueuePresentKHR                                                 :: #type proc "c" (queue: Queue, pPresentInfo: ^PresentInfoKHR) -> Result
	ProcGetDeviceGroupPresentCapabilitiesKHR                            :: #type proc "c" (device: Device, pDeviceGroupPresentCapabilities: ^DeviceGroupPresentCapabilitiesKHR) -> Result
	ProcGetDeviceGroupSurfacePresentModesKHR                            :: #type proc "c" (device: Device, surface: SurfaceKHR, pModes: ^DeviceGroupPresentModeFlagsKHR) -> Result
	ProcGetPhysicalDevicePresentRectanglesKHR                           :: #type proc "c" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pRectCount: ^u32, pRects: ^Rect2D) -> Result
	ProcAcquireNextImage2KHR                                            :: #type proc "c" (device: Device, pAcquireInfo: ^AcquireNextImageInfoKHR, pImageIndex: ^u32) -> Result
	ProcGetPhysicalDeviceDisplayPropertiesKHR                           :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPropertiesKHR) -> Result
	ProcGetPhysicalDeviceDisplayPlanePropertiesKHR                      :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPlanePropertiesKHR) -> Result
	ProcGetDisplayPlaneSupportedDisplaysKHR                             :: #type proc "c" (physicalDevice: PhysicalDevice, planeIndex: u32, pDisplayCount: ^u32, pDisplays: ^DisplayKHR) -> Result
	ProcGetDisplayModePropertiesKHR                                     :: #type proc "c" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: ^DisplayModePropertiesKHR) -> Result
	ProcCreateDisplayModeKHR                                            :: #type proc "c" (physicalDevice: PhysicalDevice, display: DisplayKHR, pCreateInfo: ^DisplayModeCreateInfoKHR, pAllocator: ^AllocationCallbacks, pMode: ^DisplayModeKHR) -> Result
	ProcGetDisplayPlaneCapabilitiesKHR                                  :: #type proc "c" (physicalDevice: PhysicalDevice, mode: DisplayModeKHR, planeIndex: u32, pCapabilities: ^DisplayPlaneCapabilitiesKHR) -> Result
	ProcCreateDisplayPlaneSurfaceKHR                                    :: #type proc "c" (instance: Instance, pCreateInfo: ^DisplaySurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateSharedSwapchainsKHR                                       :: #type proc "c" (device: Device, swapchainCount: u32, pCreateInfos: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchains: ^SwapchainKHR) -> Result
	ProcGetPhysicalDeviceFeatures2KHR                                   :: #type proc "c" (physicalDevice: PhysicalDevice, pFeatures: ^PhysicalDeviceFeatures2)
	ProcGetPhysicalDeviceProperties2KHR                                 :: #type proc "c" (physicalDevice: PhysicalDevice, pProperties: ^PhysicalDeviceProperties2)
	ProcGetPhysicalDeviceFormatProperties2KHR                           :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: ^FormatProperties2)
	ProcGetPhysicalDeviceImageFormatProperties2KHR                      :: #type proc "c" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: ^ImageFormatProperties2) -> Result
	ProcGetPhysicalDeviceQueueFamilyProperties2KHR                      :: #type proc "c" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: ^QueueFamilyProperties2)
	ProcGetPhysicalDeviceMemoryProperties2KHR                           :: #type proc "c" (physicalDevice: PhysicalDevice, pMemoryProperties: ^PhysicalDeviceMemoryProperties2)
	ProcGetPhysicalDeviceSparseImageFormatProperties2KHR                :: #type proc "c" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: ^SparseImageFormatProperties2)
	ProcGetDeviceGroupPeerMemoryFeaturesKHR                             :: #type proc "c" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: ^PeerMemoryFeatureFlags)
	ProcCmdSetDeviceMaskKHR                                             :: #type proc "c" (commandBuffer: CommandBuffer, deviceMask: u32)
	ProcCmdDispatchBaseKHR                                              :: #type proc "c" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
	ProcTrimCommandPoolKHR                                              :: #type proc "c" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
	ProcEnumeratePhysicalDeviceGroupsKHR                                :: #type proc "c" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: ^PhysicalDeviceGroupProperties) -> Result
	ProcGetPhysicalDeviceExternalBufferPropertiesKHR                    :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: ^ExternalBufferProperties)
	ProcGetMemoryFdKHR                                                  :: #type proc "c" (device: Device, pGetFdInfo: ^MemoryGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcGetMemoryFdPropertiesKHR                                        :: #type proc "c" (device: Device, handleType: ExternalMemoryHandleTypeFlags, fd: c.int, pMemoryFdProperties: ^MemoryFdPropertiesKHR) -> Result
	ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR                 :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: ^ExternalSemaphoreProperties)
	ProcImportSemaphoreFdKHR                                            :: #type proc "c" (device: Device, pImportSemaphoreFdInfo: ^ImportSemaphoreFdInfoKHR) -> Result
	ProcGetSemaphoreFdKHR                                               :: #type proc "c" (device: Device, pGetFdInfo: ^SemaphoreGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcCmdPushDescriptorSetKHR                                         :: #type proc "c" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, set: u32, descriptorWriteCount: u32, pDescriptorWrites: ^WriteDescriptorSet)
	ProcCmdPushDescriptorSetWithTemplateKHR                             :: #type proc "c" (commandBuffer: CommandBuffer, descriptorUpdateTemplate: DescriptorUpdateTemplate, layout: PipelineLayout, set: u32, pData: rawptr)
	ProcCreateDescriptorUpdateTemplateKHR                               :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
	ProcDestroyDescriptorUpdateTemplateKHR                              :: #type proc "c" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
	ProcUpdateDescriptorSetWithTemplateKHR                              :: #type proc "c" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
	ProcCreateRenderPass2KHR                                            :: #type proc "c" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: ^RenderPass) -> Result
	ProcCmdBeginRenderPass2KHR                                          :: #type proc "c" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
	ProcCmdNextSubpass2KHR                                              :: #type proc "c" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
	ProcCmdEndRenderPass2KHR                                            :: #type proc "c" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
	ProcGetSwapchainStatusKHR                                           :: #type proc "c" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcGetPhysicalDeviceExternalFencePropertiesKHR                     :: #type proc "c" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: ^ExternalFenceProperties)
	ProcImportFenceFdKHR                                                :: #type proc "c" (device: Device, pImportFenceFdInfo: ^ImportFenceFdInfoKHR) -> Result
	ProcGetFenceFdKHR                                                   :: #type proc "c" (device: Device, pGetFdInfo: ^FenceGetFdInfoKHR, pFd: ^c.int) -> Result
	ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   :: #type proc "c" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, pCounterCount: ^u32, pCounters: ^PerformanceCounterKHR, pCounterDescriptions: ^PerformanceCounterDescriptionKHR) -> Result
	ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           :: #type proc "c" (physicalDevice: PhysicalDevice, pPerformanceQueryCreateInfo: ^QueryPoolPerformanceCreateInfoKHR, pNumPasses: ^u32)
	ProcAcquireProfilingLockKHR                                         :: #type proc "c" (device: Device, pInfo: ^AcquireProfilingLockInfoKHR) -> Result
	ProcReleaseProfilingLockKHR                                         :: #type proc "c" (device: Device)
	ProcGetPhysicalDeviceSurfaceCapabilities2KHR                        :: #type proc "c" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceCapabilities: ^SurfaceCapabilities2KHR) -> Result
	ProcGetPhysicalDeviceSurfaceFormats2KHR                             :: #type proc "c" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: ^SurfaceFormat2KHR) -> Result
	ProcGetPhysicalDeviceDisplayProperties2KHR                          :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayProperties2KHR) -> Result
	ProcGetPhysicalDeviceDisplayPlaneProperties2KHR                     :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^DisplayPlaneProperties2KHR) -> Result
	ProcGetDisplayModeProperties2KHR                                    :: #type proc "c" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: ^DisplayModeProperties2KHR) -> Result
	ProcGetDisplayPlaneCapabilities2KHR                                 :: #type proc "c" (physicalDevice: PhysicalDevice, pDisplayPlaneInfo: ^DisplayPlaneInfo2KHR, pCapabilities: ^DisplayPlaneCapabilities2KHR) -> Result
	ProcGetImageMemoryRequirements2KHR                                  :: #type proc "c" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetBufferMemoryRequirements2KHR                                 :: #type proc "c" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: ^MemoryRequirements2)
	ProcGetImageSparseMemoryRequirements2KHR                            :: #type proc "c" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: ^SparseImageMemoryRequirements2)
	ProcCreateSamplerYcbcrConversionKHR                                 :: #type proc "c" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
	ProcDestroySamplerYcbcrConversionKHR                                :: #type proc "c" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
	ProcBindBufferMemory2KHR                                            :: #type proc "c" (device: Device, bindInfoCount: u32, pBindInfos: ^BindBufferMemoryInfo) -> Result
	ProcBindImageMemory2KHR                                             :: #type proc "c" (device: Device, bindInfoCount: u32, pBindInfos: ^BindImageMemoryInfo) -> Result
	ProcGetDescriptorSetLayoutSupportKHR                                :: #type proc "c" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
	ProcCmdDrawIndirectCountKHR                                         :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCountKHR                                  :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcGetSemaphoreCounterValueKHR                                     :: #type proc "c" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
	ProcWaitSemaphoresKHR                                               :: #type proc "c" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
	ProcSignalSemaphoreKHR                                              :: #type proc "c" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
	ProcGetPhysicalDeviceFragmentShadingRatesKHR                        :: #type proc "c" (physicalDevice: PhysicalDevice, pFragmentShadingRateCount: ^u32, pFragmentShadingRates: ^PhysicalDeviceFragmentShadingRateKHR) -> Result
	ProcCmdSetFragmentShadingRateKHR                                    :: #type proc "c" (commandBuffer: CommandBuffer, pFragmentSize: ^Extent2D)
	ProcWaitForPresentKHR                                               :: #type proc "c" (device: Device, swapchain: SwapchainKHR, presentId: u64, timeout: u64) -> Result
	ProcGetBufferDeviceAddressKHR                                       :: #type proc "c" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetBufferOpaqueCaptureAddressKHR                                :: #type proc "c" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
	ProcGetDeviceMemoryOpaqueCaptureAddressKHR                          :: #type proc "c" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
	ProcCreateDeferredOperationKHR                                      :: #type proc "c" (device: Device, pAllocator: ^AllocationCallbacks, pDeferredOperation: ^DeferredOperationKHR) -> Result
	ProcDestroyDeferredOperationKHR                                     :: #type proc "c" (device: Device, operation: DeferredOperationKHR, pAllocator: ^AllocationCallbacks)
	ProcGetDeferredOperationMaxConcurrencyKHR                           :: #type proc "c" (device: Device, operation: DeferredOperationKHR) -> u32
	ProcGetDeferredOperationResultKHR                                   :: #type proc "c" (device: Device, operation: DeferredOperationKHR) -> Result
	ProcDeferredOperationJoinKHR                                        :: #type proc "c" (device: Device, operation: DeferredOperationKHR) -> Result
	ProcGetPipelineExecutablePropertiesKHR                              :: #type proc "c" (device: Device, pPipelineInfo: ^PipelineInfoKHR, pExecutableCount: ^u32, pProperties: ^PipelineExecutablePropertiesKHR) -> Result
	ProcGetPipelineExecutableStatisticsKHR                              :: #type proc "c" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pStatisticCount: ^u32, pStatistics: ^PipelineExecutableStatisticKHR) -> Result
	ProcGetPipelineExecutableInternalRepresentationsKHR                 :: #type proc "c" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pInternalRepresentationCount: ^u32, pInternalRepresentations: ^PipelineExecutableInternalRepresentationKHR) -> Result
	ProcCmdSetEvent2KHR                                                 :: #type proc "c" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfoKHR)
	ProcCmdResetEvent2KHR                                               :: #type proc "c" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2KHR)
	ProcCmdWaitEvents2KHR                                               :: #type proc "c" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: ^Event, pDependencyInfos: ^DependencyInfoKHR)
	ProcCmdPipelineBarrier2KHR                                          :: #type proc "c" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfoKHR)
	ProcCmdWriteTimestamp2KHR                                           :: #type proc "c" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2KHR, queryPool: QueryPool, query: u32)
	ProcQueueSubmit2KHR                                                 :: #type proc "c" (queue: Queue, submitCount: u32, pSubmits: ^SubmitInfo2KHR, fence: Fence) -> Result
	ProcCmdWriteBufferMarker2AMD                                        :: #type proc "c" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2KHR, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
	ProcGetQueueCheckpointData2NV                                       :: #type proc "c" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointData2NV)
	ProcCmdCopyBuffer2KHR                                               :: #type proc "c" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2KHR)
	ProcCmdCopyImage2KHR                                                :: #type proc "c" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2KHR)
	ProcCmdCopyBufferToImage2KHR                                        :: #type proc "c" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2KHR)
	ProcCmdCopyImageToBuffer2KHR                                        :: #type proc "c" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2KHR)
	ProcCmdBlitImage2KHR                                                :: #type proc "c" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2KHR)
	ProcCmdResolveImage2KHR                                             :: #type proc "c" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2KHR)
	ProcDebugReportCallbackEXT                                          :: #type proc "c" (flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring, pUserData: rawptr) -> b32
	ProcCreateDebugReportCallbackEXT                                    :: #type proc "c" (instance: Instance, pCreateInfo: ^DebugReportCallbackCreateInfoEXT, pAllocator: ^AllocationCallbacks, pCallback: ^DebugReportCallbackEXT) -> Result
	ProcDestroyDebugReportCallbackEXT                                   :: #type proc "c" (instance: Instance, callback: DebugReportCallbackEXT, pAllocator: ^AllocationCallbacks)
	ProcDebugReportMessageEXT                                           :: #type proc "c" (instance: Instance, flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring)
	ProcDebugMarkerSetObjectTagEXT                                      :: #type proc "c" (device: Device, pTagInfo: ^DebugMarkerObjectTagInfoEXT) -> Result
	ProcDebugMarkerSetObjectNameEXT                                     :: #type proc "c" (device: Device, pNameInfo: ^DebugMarkerObjectNameInfoEXT) -> Result
	ProcCmdDebugMarkerBeginEXT                                          :: #type proc "c" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
	ProcCmdDebugMarkerEndEXT                                            :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdDebugMarkerInsertEXT                                         :: #type proc "c" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
	ProcCmdBindTransformFeedbackBuffersEXT                              :: #type proc "c" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize, pSizes: ^DeviceSize)
	ProcCmdBeginTransformFeedbackEXT                                    :: #type proc "c" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: ^Buffer, pCounterBufferOffsets: ^DeviceSize)
	ProcCmdEndTransformFeedbackEXT                                      :: #type proc "c" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: ^Buffer, pCounterBufferOffsets: ^DeviceSize)
	ProcCmdBeginQueryIndexedEXT                                         :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags, index: u32)
	ProcCmdEndQueryIndexedEXT                                           :: #type proc "c" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, index: u32)
	ProcCmdDrawIndirectByteCountEXT                                     :: #type proc "c" (commandBuffer: CommandBuffer, instanceCount: u32, firstInstance: u32, counterBuffer: Buffer, counterBufferOffset: DeviceSize, counterOffset: u32, vertexStride: u32)
	ProcCreateCuModuleNVX                                               :: #type proc "c" (device: Device, pCreateInfo: ^CuModuleCreateInfoNVX, pAllocator: ^AllocationCallbacks, pModule: ^CuModuleNVX) -> Result
	ProcCreateCuFunctionNVX                                             :: #type proc "c" (device: Device, pCreateInfo: ^CuFunctionCreateInfoNVX, pAllocator: ^AllocationCallbacks, pFunction: ^CuFunctionNVX) -> Result
	ProcDestroyCuModuleNVX                                              :: #type proc "c" (device: Device, module: CuModuleNVX, pAllocator: ^AllocationCallbacks)
	ProcDestroyCuFunctionNVX                                            :: #type proc "c" (device: Device, function: CuFunctionNVX, pAllocator: ^AllocationCallbacks)
	ProcCmdCuLaunchKernelNVX                                            :: #type proc "c" (commandBuffer: CommandBuffer, pLaunchInfo: ^CuLaunchInfoNVX)
	ProcGetImageViewHandleNVX                                           :: #type proc "c" (device: Device, pInfo: ^ImageViewHandleInfoNVX) -> u32
	ProcGetImageViewAddressNVX                                          :: #type proc "c" (device: Device, imageView: ImageView, pProperties: ^ImageViewAddressPropertiesNVX) -> Result
	ProcCmdDrawIndirectCountAMD                                         :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdDrawIndexedIndirectCountAMD                                  :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcGetShaderInfoAMD                                                :: #type proc "c" (device: Device, pipeline: Pipeline, shaderStage: ShaderStageFlags, infoType: ShaderInfoTypeAMD, pInfoSize: ^int, pInfo: rawptr) -> Result
	ProcGetPhysicalDeviceExternalImageFormatPropertiesNV                :: #type proc "c" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, externalHandleType: ExternalMemoryHandleTypeFlagsNV, pExternalImageFormatProperties: ^ExternalImageFormatPropertiesNV) -> Result
	ProcCmdBeginConditionalRenderingEXT                                 :: #type proc "c" (commandBuffer: CommandBuffer, pConditionalRenderingBegin: ^ConditionalRenderingBeginInfoEXT)
	ProcCmdEndConditionalRenderingEXT                                   :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdSetViewportWScalingNV                                        :: #type proc "c" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewportWScalings: ^ViewportWScalingNV)
	ProcReleaseDisplayEXT                                               :: #type proc "c" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
	ProcGetPhysicalDeviceSurfaceCapabilities2EXT                        :: #type proc "c" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: ^SurfaceCapabilities2EXT) -> Result
	ProcDisplayPowerControlEXT                                          :: #type proc "c" (device: Device, display: DisplayKHR, pDisplayPowerInfo: ^DisplayPowerInfoEXT) -> Result
	ProcRegisterDeviceEventEXT                                          :: #type proc "c" (device: Device, pDeviceEventInfo: ^DeviceEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcRegisterDisplayEventEXT                                         :: #type proc "c" (device: Device, display: DisplayKHR, pDisplayEventInfo: ^DisplayEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
	ProcGetSwapchainCounterEXT                                          :: #type proc "c" (device: Device, swapchain: SwapchainKHR, counter: SurfaceCounterFlagsEXT, pCounterValue: ^u64) -> Result
	ProcGetRefreshCycleDurationGOOGLE                                   :: #type proc "c" (device: Device, swapchain: SwapchainKHR, pDisplayTimingProperties: ^RefreshCycleDurationGOOGLE) -> Result
	ProcGetPastPresentationTimingGOOGLE                                 :: #type proc "c" (device: Device, swapchain: SwapchainKHR, pPresentationTimingCount: ^u32, pPresentationTimings: ^PastPresentationTimingGOOGLE) -> Result
	ProcCmdSetDiscardRectangleEXT                                       :: #type proc "c" (commandBuffer: CommandBuffer, firstDiscardRectangle: u32, discardRectangleCount: u32, pDiscardRectangles: ^Rect2D)
	ProcSetHdrMetadataEXT                                               :: #type proc "c" (device: Device, swapchainCount: u32, pSwapchains: ^SwapchainKHR, pMetadata: ^HdrMetadataEXT)
	ProcDebugUtilsMessengerCallbackEXT                                  :: #type proc "c" (messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32
	ProcSetDebugUtilsObjectNameEXT                                      :: #type proc "c" (device: Device, pNameInfo: ^DebugUtilsObjectNameInfoEXT) -> Result
	ProcSetDebugUtilsObjectTagEXT                                       :: #type proc "c" (device: Device, pTagInfo: ^DebugUtilsObjectTagInfoEXT) -> Result
	ProcQueueBeginDebugUtilsLabelEXT                                    :: #type proc "c" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcQueueEndDebugUtilsLabelEXT                                      :: #type proc "c" (queue: Queue)
	ProcQueueInsertDebugUtilsLabelEXT                                   :: #type proc "c" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCmdBeginDebugUtilsLabelEXT                                      :: #type proc "c" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCmdEndDebugUtilsLabelEXT                                        :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdInsertDebugUtilsLabelEXT                                     :: #type proc "c" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
	ProcCreateDebugUtilsMessengerEXT                                    :: #type proc "c" (instance: Instance, pCreateInfo: ^DebugUtilsMessengerCreateInfoEXT, pAllocator: ^AllocationCallbacks, pMessenger: ^DebugUtilsMessengerEXT) -> Result
	ProcDestroyDebugUtilsMessengerEXT                                   :: #type proc "c" (instance: Instance, messenger: DebugUtilsMessengerEXT, pAllocator: ^AllocationCallbacks)
	ProcSubmitDebugUtilsMessageEXT                                      :: #type proc "c" (instance: Instance, messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT)
	ProcCmdSetSampleLocationsEXT                                        :: #type proc "c" (commandBuffer: CommandBuffer, pSampleLocationsInfo: ^SampleLocationsInfoEXT)
	ProcGetPhysicalDeviceMultisamplePropertiesEXT                       :: #type proc "c" (physicalDevice: PhysicalDevice, samples: SampleCountFlags, pMultisampleProperties: ^MultisamplePropertiesEXT)
	ProcGetImageDrmFormatModifierPropertiesEXT                          :: #type proc "c" (device: Device, image: Image, pProperties: ^ImageDrmFormatModifierPropertiesEXT) -> Result
	ProcCreateValidationCacheEXT                                        :: #type proc "c" (device: Device, pCreateInfo: ^ValidationCacheCreateInfoEXT, pAllocator: ^AllocationCallbacks, pValidationCache: ^ValidationCacheEXT) -> Result
	ProcDestroyValidationCacheEXT                                       :: #type proc "c" (device: Device, validationCache: ValidationCacheEXT, pAllocator: ^AllocationCallbacks)
	ProcMergeValidationCachesEXT                                        :: #type proc "c" (device: Device, dstCache: ValidationCacheEXT, srcCacheCount: u32, pSrcCaches: ^ValidationCacheEXT) -> Result
	ProcGetValidationCacheDataEXT                                       :: #type proc "c" (device: Device, validationCache: ValidationCacheEXT, pDataSize: ^int, pData: rawptr) -> Result
	ProcCmdBindShadingRateImageNV                                       :: #type proc "c" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
	ProcCmdSetViewportShadingRatePaletteNV                              :: #type proc "c" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pShadingRatePalettes: ^ShadingRatePaletteNV)
	ProcCmdSetCoarseSampleOrderNV                                       :: #type proc "c" (commandBuffer: CommandBuffer, sampleOrderType: CoarseSampleOrderTypeNV, customSampleOrderCount: u32, pCustomSampleOrders: ^CoarseSampleOrderCustomNV)
	ProcCreateAccelerationStructureNV                                   :: #type proc "c" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoNV, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureNV) -> Result
	ProcDestroyAccelerationStructureNV                                  :: #type proc "c" (device: Device, accelerationStructure: AccelerationStructureNV, pAllocator: ^AllocationCallbacks)
	ProcGetAccelerationStructureMemoryRequirementsNV                    :: #type proc "c" (device: Device, pInfo: ^AccelerationStructureMemoryRequirementsInfoNV, pMemoryRequirements: ^MemoryRequirements2KHR)
	ProcBindAccelerationStructureMemoryNV                               :: #type proc "c" (device: Device, bindInfoCount: u32, pBindInfos: ^BindAccelerationStructureMemoryInfoNV) -> Result
	ProcCmdBuildAccelerationStructureNV                                 :: #type proc "c" (commandBuffer: CommandBuffer, pInfo: ^AccelerationStructureInfoNV, instanceData: Buffer, instanceOffset: DeviceSize, update: b32, dst: AccelerationStructureNV, src: AccelerationStructureNV, scratch: Buffer, scratchOffset: DeviceSize)
	ProcCmdCopyAccelerationStructureNV                                  :: #type proc "c" (commandBuffer: CommandBuffer, dst: AccelerationStructureNV, src: AccelerationStructureNV, mode: CopyAccelerationStructureModeKHR)
	ProcCmdTraceRaysNV                                                  :: #type proc "c" (commandBuffer: CommandBuffer, raygenShaderBindingTableBuffer: Buffer, raygenShaderBindingOffset: DeviceSize, missShaderBindingTableBuffer: Buffer, missShaderBindingOffset: DeviceSize, missShaderBindingStride: DeviceSize, hitShaderBindingTableBuffer: Buffer, hitShaderBindingOffset: DeviceSize, hitShaderBindingStride: DeviceSize, callableShaderBindingTableBuffer: Buffer, callableShaderBindingOffset: DeviceSize, callableShaderBindingStride: DeviceSize, width: u32, height: u32, depth: u32)
	ProcCreateRayTracingPipelinesNV                                     :: #type proc "c" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^RayTracingPipelineCreateInfoNV, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcGetRayTracingShaderGroupHandlesKHR                              :: #type proc "c" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcGetRayTracingShaderGroupHandlesNV                               :: #type proc "c" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcGetAccelerationStructureHandleNV                                :: #type proc "c" (device: Device, accelerationStructure: AccelerationStructureNV, dataSize: int, pData: rawptr) -> Result
	ProcCmdWriteAccelerationStructuresPropertiesNV                      :: #type proc "c" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureNV, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
	ProcCompileDeferredNV                                               :: #type proc "c" (device: Device, pipeline: Pipeline, shader: u32) -> Result
	ProcGetMemoryHostPointerPropertiesEXT                               :: #type proc "c" (device: Device, handleType: ExternalMemoryHandleTypeFlags, pHostPointer: rawptr, pMemoryHostPointerProperties: ^MemoryHostPointerPropertiesEXT) -> Result
	ProcCmdWriteBufferMarkerAMD                                         :: #type proc "c" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
	ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT                    :: #type proc "c" (physicalDevice: PhysicalDevice, pTimeDomainCount: ^u32, pTimeDomains: ^TimeDomainEXT) -> Result
	ProcGetCalibratedTimestampsEXT                                      :: #type proc "c" (device: Device, timestampCount: u32, pTimestampInfos: ^CalibratedTimestampInfoEXT, pTimestamps: ^u64, pMaxDeviation: ^u64) -> Result
	ProcCmdDrawMeshTasksNV                                              :: #type proc "c" (commandBuffer: CommandBuffer, taskCount: u32, firstTask: u32)
	ProcCmdDrawMeshTasksIndirectNV                                      :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
	ProcCmdDrawMeshTasksIndirectCountNV                                 :: #type proc "c" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
	ProcCmdSetExclusiveScissorNV                                        :: #type proc "c" (commandBuffer: CommandBuffer, firstExclusiveScissor: u32, exclusiveScissorCount: u32, pExclusiveScissors: ^Rect2D)
	ProcCmdSetCheckpointNV                                              :: #type proc "c" (commandBuffer: CommandBuffer, pCheckpointMarker: rawptr)
	ProcGetQueueCheckpointDataNV                                        :: #type proc "c" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointDataNV)
	ProcInitializePerformanceApiINTEL                                   :: #type proc "c" (device: Device, pInitializeInfo: ^InitializePerformanceApiInfoINTEL) -> Result
	ProcUninitializePerformanceApiINTEL                                 :: #type proc "c" (device: Device)
	ProcCmdSetPerformanceMarkerINTEL                                    :: #type proc "c" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceMarkerInfoINTEL) -> Result
	ProcCmdSetPerformanceStreamMarkerINTEL                              :: #type proc "c" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceStreamMarkerInfoINTEL) -> Result
	ProcCmdSetPerformanceOverrideINTEL                                  :: #type proc "c" (commandBuffer: CommandBuffer, pOverrideInfo: ^PerformanceOverrideInfoINTEL) -> Result
	ProcAcquirePerformanceConfigurationINTEL                            :: #type proc "c" (device: Device, pAcquireInfo: ^PerformanceConfigurationAcquireInfoINTEL, pConfiguration: ^PerformanceConfigurationINTEL) -> Result
	ProcReleasePerformanceConfigurationINTEL                            :: #type proc "c" (device: Device, configuration: PerformanceConfigurationINTEL) -> Result
	ProcQueueSetPerformanceConfigurationINTEL                           :: #type proc "c" (queue: Queue, configuration: PerformanceConfigurationINTEL) -> Result
	ProcGetPerformanceParameterINTEL                                    :: #type proc "c" (device: Device, parameter: PerformanceParameterTypeINTEL, pValue: ^PerformanceValueINTEL) -> Result
	ProcSetLocalDimmingAMD                                              :: #type proc "c" (device: Device, swapChain: SwapchainKHR, localDimmingEnable: b32)
	ProcGetBufferDeviceAddressEXT                                       :: #type proc "c" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
	ProcGetPhysicalDeviceToolPropertiesEXT                              :: #type proc "c" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: ^PhysicalDeviceToolPropertiesEXT) -> Result
	ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV                  :: #type proc "c" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: ^CooperativeMatrixPropertiesNV) -> Result
	ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV :: #type proc "c" (physicalDevice: PhysicalDevice, pCombinationCount: ^u32, pCombinations: ^FramebufferMixedSamplesCombinationNV) -> Result
	ProcCreateHeadlessSurfaceEXT                                        :: #type proc "c" (instance: Instance, pCreateInfo: ^HeadlessSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCmdSetLineStippleEXT                                            :: #type proc "c" (commandBuffer: CommandBuffer, lineStippleFactor: u32, lineStipplePattern: u16)
	ProcResetQueryPoolEXT                                               :: #type proc "c" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
	ProcCmdSetCullModeEXT                                               :: #type proc "c" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
	ProcCmdSetFrontFaceEXT                                              :: #type proc "c" (commandBuffer: CommandBuffer, frontFace: FrontFace)
	ProcCmdSetPrimitiveTopologyEXT                                      :: #type proc "c" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
	ProcCmdSetViewportWithCountEXT                                      :: #type proc "c" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: ^Viewport)
	ProcCmdSetScissorWithCountEXT                                       :: #type proc "c" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: ^Rect2D)
	ProcCmdBindVertexBuffers2EXT                                        :: #type proc "c" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: ^Buffer, pOffsets: ^DeviceSize, pSizes: ^DeviceSize, pStrides: ^DeviceSize)
	ProcCmdSetDepthTestEnableEXT                                        :: #type proc "c" (commandBuffer: CommandBuffer, depthTestEnable: b32)
	ProcCmdSetDepthWriteEnableEXT                                       :: #type proc "c" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
	ProcCmdSetDepthCompareOpEXT                                         :: #type proc "c" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
	ProcCmdSetDepthBoundsTestEnableEXT                                  :: #type proc "c" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
	ProcCmdSetStencilTestEnableEXT                                      :: #type proc "c" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
	ProcCmdSetStencilOpEXT                                              :: #type proc "c" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
	ProcGetGeneratedCommandsMemoryRequirementsNV                        :: #type proc "c" (device: Device, pInfo: ^GeneratedCommandsMemoryRequirementsInfoNV, pMemoryRequirements: ^MemoryRequirements2)
	ProcCmdPreprocessGeneratedCommandsNV                                :: #type proc "c" (commandBuffer: CommandBuffer, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
	ProcCmdExecuteGeneratedCommandsNV                                   :: #type proc "c" (commandBuffer: CommandBuffer, isPreprocessed: b32, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
	ProcCmdBindPipelineShaderGroupNV                                    :: #type proc "c" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline, groupIndex: u32)
	ProcCreateIndirectCommandsLayoutNV                                  :: #type proc "c" (device: Device, pCreateInfo: ^IndirectCommandsLayoutCreateInfoNV, pAllocator: ^AllocationCallbacks, pIndirectCommandsLayout: ^IndirectCommandsLayoutNV) -> Result
	ProcDestroyIndirectCommandsLayoutNV                                 :: #type proc "c" (device: Device, indirectCommandsLayout: IndirectCommandsLayoutNV, pAllocator: ^AllocationCallbacks)
	ProcDeviceMemoryReportCallbackEXT                                   :: #type proc "c" (pCallbackData: ^DeviceMemoryReportCallbackDataEXT, pUserData: rawptr)
	ProcAcquireDrmDisplayEXT                                            :: #type proc "c" (physicalDevice: PhysicalDevice, drmFd: i32, display: DisplayKHR) -> Result
	ProcGetDrmDisplayEXT                                                :: #type proc "c" (physicalDevice: PhysicalDevice, drmFd: i32, connectorId: u32, display: ^DisplayKHR) -> Result
	ProcCreatePrivateDataSlotEXT                                        :: #type proc "c" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfoEXT, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlotEXT) -> Result
	ProcDestroyPrivateDataSlotEXT                                       :: #type proc "c" (device: Device, privateDataSlot: PrivateDataSlotEXT, pAllocator: ^AllocationCallbacks)
	ProcSetPrivateDataEXT                                               :: #type proc "c" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlotEXT, data: u64) -> Result
	ProcGetPrivateDataEXT                                               :: #type proc "c" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlotEXT, pData: ^u64)
	ProcCmdSetFragmentShadingRateEnumNV                                 :: #type proc "c" (commandBuffer: CommandBuffer, shadingRate: FragmentShadingRateNV)
	ProcAcquireWinrtDisplayNV                                           :: #type proc "c" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
	ProcGetWinrtDisplayNV                                               :: #type proc "c" (physicalDevice: PhysicalDevice, deviceRelativeId: u32, pDisplay: ^DisplayKHR) -> Result
	ProcCmdSetVertexInputEXT                                            :: #type proc "c" (commandBuffer: CommandBuffer, vertexBindingDescriptionCount: u32, pVertexBindingDescriptions: ^VertexInputBindingDescription2EXT, vertexAttributeDescriptionCount: u32, pVertexAttributeDescriptions: ^VertexInputAttributeDescription2EXT)
	ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI                   :: #type proc "c" (device: Device, renderpass: RenderPass, pMaxWorkgroupSize: ^Extent2D) -> Result
	ProcCmdSubpassShadingHUAWEI                                         :: #type proc "c" (commandBuffer: CommandBuffer)
	ProcCmdBindInvocationMaskHUAWEI                                     :: #type proc "c" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
	ProcGetMemoryRemoteAddressNV                                        :: #type proc "c" (device: Device, pMemoryGetRemoteAddressInfo: ^MemoryGetRemoteAddressInfoNV, pAddress: ^RemoteAddressNV) -> Result
	ProcCmdSetPatchControlPointsEXT                                     :: #type proc "c" (commandBuffer: CommandBuffer, patchControlPoints: u32)
	ProcCmdSetRasterizerDiscardEnableEXT                                :: #type proc "c" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
	ProcCmdSetDepthBiasEnableEXT                                        :: #type proc "c" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
	ProcCmdSetLogicOpEXT                                                :: #type proc "c" (commandBuffer: CommandBuffer, logicOp: LogicOp)
	ProcCmdSetPrimitiveRestartEnableEXT                                 :: #type proc "c" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
	ProcCmdDrawMultiEXT                                                 :: #type proc "c" (commandBuffer: CommandBuffer, drawCount: u32, pVertexInfo: ^MultiDrawInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32)
	ProcCmdDrawMultiIndexedEXT                                          :: #type proc "c" (commandBuffer: CommandBuffer, drawCount: u32, pIndexInfo: ^MultiDrawIndexedInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32, pVertexOffset: ^i32)
	ProcCreateAccelerationStructureKHR                                  :: #type proc "c" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoKHR, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureKHR) -> Result
	ProcDestroyAccelerationStructureKHR                                 :: #type proc "c" (device: Device, accelerationStructure: AccelerationStructureKHR, pAllocator: ^AllocationCallbacks)
	ProcCmdBuildAccelerationStructuresKHR                               :: #type proc "c" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^^AccelerationStructureBuildRangeInfoKHR)
	ProcCmdBuildAccelerationStructuresIndirectKHR                       :: #type proc "c" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, pIndirectDeviceAddresses: ^DeviceAddress, pIndirectStrides: ^u32, ppMaxPrimitiveCounts: ^^u32)
	ProcBuildAccelerationStructuresKHR                                  :: #type proc "c" (device: Device, deferredOperation: DeferredOperationKHR, infoCount: u32, pInfos: ^AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^^AccelerationStructureBuildRangeInfoKHR) -> Result
	ProcCopyAccelerationStructureKHR                                    :: #type proc "c" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureInfoKHR) -> Result
	ProcCopyAccelerationStructureToMemoryKHR                            :: #type proc "c" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR) -> Result
	ProcCopyMemoryToAccelerationStructureKHR                            :: #type proc "c" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR) -> Result
	ProcWriteAccelerationStructuresPropertiesKHR                        :: #type proc "c" (device: Device, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureKHR, queryType: QueryType, dataSize: int, pData: rawptr, stride: int) -> Result
	ProcCmdCopyAccelerationStructureKHR                                 :: #type proc "c" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureInfoKHR)
	ProcCmdCopyAccelerationStructureToMemoryKHR                         :: #type proc "c" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR)
	ProcCmdCopyMemoryToAccelerationStructureKHR                         :: #type proc "c" (commandBuffer: CommandBuffer, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR)
	ProcGetAccelerationStructureDeviceAddressKHR                        :: #type proc "c" (device: Device, pInfo: ^AccelerationStructureDeviceAddressInfoKHR) -> DeviceAddress
	ProcCmdWriteAccelerationStructuresPropertiesKHR                     :: #type proc "c" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: ^AccelerationStructureKHR, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
	ProcGetDeviceAccelerationStructureCompatibilityKHR                  :: #type proc "c" (device: Device, pVersionInfo: ^AccelerationStructureVersionInfoKHR, pCompatibility: ^AccelerationStructureCompatibilityKHR)
	ProcGetAccelerationStructureBuildSizesKHR                           :: #type proc "c" (device: Device, buildType: AccelerationStructureBuildTypeKHR, pBuildInfo: ^AccelerationStructureBuildGeometryInfoKHR, pMaxPrimitiveCounts: ^u32, pSizeInfo: ^AccelerationStructureBuildSizesInfoKHR)
	ProcCmdTraceRaysKHR                                                 :: #type proc "c" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: ^StridedDeviceAddressRegionKHR, pMissShaderBindingTable: ^StridedDeviceAddressRegionKHR, pHitShaderBindingTable: ^StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: ^StridedDeviceAddressRegionKHR, width: u32, height: u32, depth: u32)
	ProcCreateRayTracingPipelinesKHR                                    :: #type proc "c" (device: Device, deferredOperation: DeferredOperationKHR, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: ^RayTracingPipelineCreateInfoKHR, pAllocator: ^AllocationCallbacks, pPipelines: ^Pipeline) -> Result
	ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR                 :: #type proc "c" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
	ProcCmdTraceRaysIndirectKHR                                         :: #type proc "c" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: ^StridedDeviceAddressRegionKHR, pMissShaderBindingTable: ^StridedDeviceAddressRegionKHR, pHitShaderBindingTable: ^StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: ^StridedDeviceAddressRegionKHR, indirectDeviceAddress: DeviceAddress)
	ProcGetRayTracingShaderGroupStackSizeKHR                            :: #type proc "c" (device: Device, pipeline: Pipeline, group: u32, groupShader: ShaderGroupShaderKHR) -> DeviceSize
	ProcCmdSetRayTracingPipelineStackSizeKHR                            :: #type proc "c" (commandBuffer: CommandBuffer, pipelineStackSize: u32)
	ProcCreateWin32SurfaceKHR                                           :: #type proc "c" (instance: Instance, pCreateInfo: ^Win32SurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcGetPhysicalDeviceWin32PresentationSupportKHR                    :: #type proc "c" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32) -> b32
	ProcGetMemoryWin32HandleKHR                                         :: #type proc "c" (device: Device, pGetWin32HandleInfo: ^MemoryGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcGetMemoryWin32HandlePropertiesKHR                               :: #type proc "c" (device: Device, handleType: ExternalMemoryHandleTypeFlags, handle: HANDLE, pMemoryWin32HandleProperties: ^MemoryWin32HandlePropertiesKHR) -> Result
	ProcImportSemaphoreWin32HandleKHR                                   :: #type proc "c" (device: Device, pImportSemaphoreWin32HandleInfo: ^ImportSemaphoreWin32HandleInfoKHR) -> Result
	ProcGetSemaphoreWin32HandleKHR                                      :: #type proc "c" (device: Device, pGetWin32HandleInfo: ^SemaphoreGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcImportFenceWin32HandleKHR                                       :: #type proc "c" (device: Device, pImportFenceWin32HandleInfo: ^ImportFenceWin32HandleInfoKHR) -> Result
	ProcGetFenceWin32HandleKHR                                          :: #type proc "c" (device: Device, pGetWin32HandleInfo: ^FenceGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
	ProcGetMemoryWin32HandleNV                                          :: #type proc "c" (device: Device, memory: DeviceMemory, handleType: ExternalMemoryHandleTypeFlagsNV, pHandle: ^HANDLE) -> Result
	ProcGetPhysicalDeviceSurfacePresentModes2EXT                        :: #type proc "c" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pPresentModeCount: ^u32, pPresentModes: ^PresentModeKHR) -> Result
	ProcAcquireFullScreenExclusiveModeEXT                               :: #type proc "c" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcReleaseFullScreenExclusiveModeEXT                               :: #type proc "c" (device: Device, swapchain: SwapchainKHR) -> Result
	ProcGetDeviceGroupSurfacePresentModes2EXT                           :: #type proc "c" (device: Device, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pModes: ^DeviceGroupPresentModeFlagsKHR) -> Result
	ProcCreateMetalSurfaceEXT                                           :: #type proc "c" (instance: Instance, pCreateInfo: ^MetalSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateMacOSSurfaceMVK                                           :: #type proc "c" (instance: Instance, pCreateInfo: ^MacOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
	ProcCreateIOSSurfaceMVK                                             :: #type proc "c" (instance: Instance, pCreateInfo: ^IOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
}


// Instance Procedures
DestroyInstance:                                                 ProcDestroyInstance
EnumeratePhysicalDevices:                                        ProcEnumeratePhysicalDevices
GetPhysicalDeviceFeatures:                                       ProcGetPhysicalDeviceFeatures
GetPhysicalDeviceFormatProperties:                               ProcGetPhysicalDeviceFormatProperties
GetPhysicalDeviceImageFormatProperties:                          ProcGetPhysicalDeviceImageFormatProperties
GetPhysicalDeviceProperties:                                     ProcGetPhysicalDeviceProperties
GetPhysicalDeviceQueueFamilyProperties:                          ProcGetPhysicalDeviceQueueFamilyProperties
GetPhysicalDeviceMemoryProperties:                               ProcGetPhysicalDeviceMemoryProperties
GetInstanceProcAddr:                                             ProcGetInstanceProcAddr
CreateDevice:                                                    ProcCreateDevice
EnumerateDeviceExtensionProperties:                              ProcEnumerateDeviceExtensionProperties
EnumerateDeviceLayerProperties:                                  ProcEnumerateDeviceLayerProperties
GetPhysicalDeviceSparseImageFormatProperties:                    ProcGetPhysicalDeviceSparseImageFormatProperties
EnumeratePhysicalDeviceGroups:                                   ProcEnumeratePhysicalDeviceGroups
GetPhysicalDeviceFeatures2:                                      ProcGetPhysicalDeviceFeatures2
GetPhysicalDeviceProperties2:                                    ProcGetPhysicalDeviceProperties2
GetPhysicalDeviceFormatProperties2:                              ProcGetPhysicalDeviceFormatProperties2
GetPhysicalDeviceImageFormatProperties2:                         ProcGetPhysicalDeviceImageFormatProperties2
GetPhysicalDeviceQueueFamilyProperties2:                         ProcGetPhysicalDeviceQueueFamilyProperties2
GetPhysicalDeviceMemoryProperties2:                              ProcGetPhysicalDeviceMemoryProperties2
GetPhysicalDeviceSparseImageFormatProperties2:                   ProcGetPhysicalDeviceSparseImageFormatProperties2
GetPhysicalDeviceExternalBufferProperties:                       ProcGetPhysicalDeviceExternalBufferProperties
GetPhysicalDeviceExternalFenceProperties:                        ProcGetPhysicalDeviceExternalFenceProperties
GetPhysicalDeviceExternalSemaphoreProperties:                    ProcGetPhysicalDeviceExternalSemaphoreProperties
DestroySurfaceKHR:                                               ProcDestroySurfaceKHR
GetPhysicalDeviceSurfaceSupportKHR:                              ProcGetPhysicalDeviceSurfaceSupportKHR
GetPhysicalDeviceSurfaceCapabilitiesKHR:                         ProcGetPhysicalDeviceSurfaceCapabilitiesKHR
GetPhysicalDeviceSurfaceFormatsKHR:                              ProcGetPhysicalDeviceSurfaceFormatsKHR
GetPhysicalDeviceSurfacePresentModesKHR:                         ProcGetPhysicalDeviceSurfacePresentModesKHR
GetPhysicalDevicePresentRectanglesKHR:                           ProcGetPhysicalDevicePresentRectanglesKHR
GetPhysicalDeviceDisplayPropertiesKHR:                           ProcGetPhysicalDeviceDisplayPropertiesKHR
GetPhysicalDeviceDisplayPlanePropertiesKHR:                      ProcGetPhysicalDeviceDisplayPlanePropertiesKHR
GetDisplayPlaneSupportedDisplaysKHR:                             ProcGetDisplayPlaneSupportedDisplaysKHR
GetDisplayModePropertiesKHR:                                     ProcGetDisplayModePropertiesKHR
CreateDisplayModeKHR:                                            ProcCreateDisplayModeKHR
GetDisplayPlaneCapabilitiesKHR:                                  ProcGetDisplayPlaneCapabilitiesKHR
CreateDisplayPlaneSurfaceKHR:                                    ProcCreateDisplayPlaneSurfaceKHR
GetPhysicalDeviceFeatures2KHR:                                   ProcGetPhysicalDeviceFeatures2KHR
GetPhysicalDeviceProperties2KHR:                                 ProcGetPhysicalDeviceProperties2KHR
GetPhysicalDeviceFormatProperties2KHR:                           ProcGetPhysicalDeviceFormatProperties2KHR
GetPhysicalDeviceImageFormatProperties2KHR:                      ProcGetPhysicalDeviceImageFormatProperties2KHR
GetPhysicalDeviceQueueFamilyProperties2KHR:                      ProcGetPhysicalDeviceQueueFamilyProperties2KHR
GetPhysicalDeviceMemoryProperties2KHR:                           ProcGetPhysicalDeviceMemoryProperties2KHR
GetPhysicalDeviceSparseImageFormatProperties2KHR:                ProcGetPhysicalDeviceSparseImageFormatProperties2KHR
EnumeratePhysicalDeviceGroupsKHR:                                ProcEnumeratePhysicalDeviceGroupsKHR
GetPhysicalDeviceExternalBufferPropertiesKHR:                    ProcGetPhysicalDeviceExternalBufferPropertiesKHR
GetPhysicalDeviceExternalSemaphorePropertiesKHR:                 ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR
GetPhysicalDeviceExternalFencePropertiesKHR:                     ProcGetPhysicalDeviceExternalFencePropertiesKHR
EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR:   ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR
GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR:           ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR
GetPhysicalDeviceSurfaceCapabilities2KHR:                        ProcGetPhysicalDeviceSurfaceCapabilities2KHR
GetPhysicalDeviceSurfaceFormats2KHR:                             ProcGetPhysicalDeviceSurfaceFormats2KHR
GetPhysicalDeviceDisplayProperties2KHR:                          ProcGetPhysicalDeviceDisplayProperties2KHR
GetPhysicalDeviceDisplayPlaneProperties2KHR:                     ProcGetPhysicalDeviceDisplayPlaneProperties2KHR
GetDisplayModeProperties2KHR:                                    ProcGetDisplayModeProperties2KHR
GetDisplayPlaneCapabilities2KHR:                                 ProcGetDisplayPlaneCapabilities2KHR
GetPhysicalDeviceFragmentShadingRatesKHR:                        ProcGetPhysicalDeviceFragmentShadingRatesKHR
CreateDebugReportCallbackEXT:                                    ProcCreateDebugReportCallbackEXT
DestroyDebugReportCallbackEXT:                                   ProcDestroyDebugReportCallbackEXT
DebugReportMessageEXT:                                           ProcDebugReportMessageEXT
GetPhysicalDeviceExternalImageFormatPropertiesNV:                ProcGetPhysicalDeviceExternalImageFormatPropertiesNV
ReleaseDisplayEXT:                                               ProcReleaseDisplayEXT
GetPhysicalDeviceSurfaceCapabilities2EXT:                        ProcGetPhysicalDeviceSurfaceCapabilities2EXT
CreateDebugUtilsMessengerEXT:                                    ProcCreateDebugUtilsMessengerEXT
DestroyDebugUtilsMessengerEXT:                                   ProcDestroyDebugUtilsMessengerEXT
SubmitDebugUtilsMessageEXT:                                      ProcSubmitDebugUtilsMessageEXT
GetPhysicalDeviceMultisamplePropertiesEXT:                       ProcGetPhysicalDeviceMultisamplePropertiesEXT
GetPhysicalDeviceCalibrateableTimeDomainsEXT:                    ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT
GetPhysicalDeviceToolPropertiesEXT:                              ProcGetPhysicalDeviceToolPropertiesEXT
GetPhysicalDeviceCooperativeMatrixPropertiesNV:                  ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV
GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV: ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV
CreateHeadlessSurfaceEXT:                                        ProcCreateHeadlessSurfaceEXT
AcquireDrmDisplayEXT:                                            ProcAcquireDrmDisplayEXT
GetDrmDisplayEXT:                                                ProcGetDrmDisplayEXT
AcquireWinrtDisplayNV:                                           ProcAcquireWinrtDisplayNV
GetWinrtDisplayNV:                                               ProcGetWinrtDisplayNV
CreateWin32SurfaceKHR:                                           ProcCreateWin32SurfaceKHR
GetPhysicalDeviceWin32PresentationSupportKHR:                    ProcGetPhysicalDeviceWin32PresentationSupportKHR
GetPhysicalDeviceSurfacePresentModes2EXT:                        ProcGetPhysicalDeviceSurfacePresentModes2EXT
CreateMetalSurfaceEXT:                                           ProcCreateMetalSurfaceEXT
CreateMacOSSurfaceMVK:                                           ProcCreateMacOSSurfaceMVK
CreateIOSSurfaceMVK:                                             ProcCreateIOSSurfaceMVK

// Device Procedures
GetDeviceProcAddr:                               ProcGetDeviceProcAddr
DestroyDevice:                                   ProcDestroyDevice
GetDeviceQueue:                                  ProcGetDeviceQueue
QueueSubmit:                                     ProcQueueSubmit
QueueWaitIdle:                                   ProcQueueWaitIdle
DeviceWaitIdle:                                  ProcDeviceWaitIdle
AllocateMemory:                                  ProcAllocateMemory
FreeMemory:                                      ProcFreeMemory
MapMemory:                                       ProcMapMemory
UnmapMemory:                                     ProcUnmapMemory
FlushMappedMemoryRanges:                         ProcFlushMappedMemoryRanges
InvalidateMappedMemoryRanges:                    ProcInvalidateMappedMemoryRanges
GetDeviceMemoryCommitment:                       ProcGetDeviceMemoryCommitment
BindBufferMemory:                                ProcBindBufferMemory
BindImageMemory:                                 ProcBindImageMemory
GetBufferMemoryRequirements:                     ProcGetBufferMemoryRequirements
GetImageMemoryRequirements:                      ProcGetImageMemoryRequirements
GetImageSparseMemoryRequirements:                ProcGetImageSparseMemoryRequirements
QueueBindSparse:                                 ProcQueueBindSparse
CreateFence:                                     ProcCreateFence
DestroyFence:                                    ProcDestroyFence
ResetFences:                                     ProcResetFences
GetFenceStatus:                                  ProcGetFenceStatus
WaitForFences:                                   ProcWaitForFences
CreateSemaphore:                                 ProcCreateSemaphore
DestroySemaphore:                                ProcDestroySemaphore
CreateEvent:                                     ProcCreateEvent
DestroyEvent:                                    ProcDestroyEvent
GetEventStatus:                                  ProcGetEventStatus
SetEvent:                                        ProcSetEvent
ResetEvent:                                      ProcResetEvent
CreateQueryPool:                                 ProcCreateQueryPool
DestroyQueryPool:                                ProcDestroyQueryPool
GetQueryPoolResults:                             ProcGetQueryPoolResults
CreateBuffer:                                    ProcCreateBuffer
DestroyBuffer:                                   ProcDestroyBuffer
CreateBufferView:                                ProcCreateBufferView
DestroyBufferView:                               ProcDestroyBufferView
CreateImage:                                     ProcCreateImage
DestroyImage:                                    ProcDestroyImage
GetImageSubresourceLayout:                       ProcGetImageSubresourceLayout
CreateImageView:                                 ProcCreateImageView
DestroyImageView:                                ProcDestroyImageView
CreateShaderModule:                              ProcCreateShaderModule
DestroyShaderModule:                             ProcDestroyShaderModule
CreatePipelineCache:                             ProcCreatePipelineCache
DestroyPipelineCache:                            ProcDestroyPipelineCache
GetPipelineCacheData:                            ProcGetPipelineCacheData
MergePipelineCaches:                             ProcMergePipelineCaches
CreateGraphicsPipelines:                         ProcCreateGraphicsPipelines
CreateComputePipelines:                          ProcCreateComputePipelines
DestroyPipeline:                                 ProcDestroyPipeline
CreatePipelineLayout:                            ProcCreatePipelineLayout
DestroyPipelineLayout:                           ProcDestroyPipelineLayout
CreateSampler:                                   ProcCreateSampler
DestroySampler:                                  ProcDestroySampler
CreateDescriptorSetLayout:                       ProcCreateDescriptorSetLayout
DestroyDescriptorSetLayout:                      ProcDestroyDescriptorSetLayout
CreateDescriptorPool:                            ProcCreateDescriptorPool
DestroyDescriptorPool:                           ProcDestroyDescriptorPool
ResetDescriptorPool:                             ProcResetDescriptorPool
AllocateDescriptorSets:                          ProcAllocateDescriptorSets
FreeDescriptorSets:                              ProcFreeDescriptorSets
UpdateDescriptorSets:                            ProcUpdateDescriptorSets
CreateFramebuffer:                               ProcCreateFramebuffer
DestroyFramebuffer:                              ProcDestroyFramebuffer
CreateRenderPass:                                ProcCreateRenderPass
DestroyRenderPass:                               ProcDestroyRenderPass
GetRenderAreaGranularity:                        ProcGetRenderAreaGranularity
CreateCommandPool:                               ProcCreateCommandPool
DestroyCommandPool:                              ProcDestroyCommandPool
ResetCommandPool:                                ProcResetCommandPool
AllocateCommandBuffers:                          ProcAllocateCommandBuffers
FreeCommandBuffers:                              ProcFreeCommandBuffers
BeginCommandBuffer:                              ProcBeginCommandBuffer
EndCommandBuffer:                                ProcEndCommandBuffer
ResetCommandBuffer:                              ProcResetCommandBuffer
CmdBindPipeline:                                 ProcCmdBindPipeline
CmdSetViewport:                                  ProcCmdSetViewport
CmdSetScissor:                                   ProcCmdSetScissor
CmdSetLineWidth:                                 ProcCmdSetLineWidth
CmdSetDepthBias:                                 ProcCmdSetDepthBias
CmdSetBlendConstants:                            ProcCmdSetBlendConstants
CmdSetDepthBounds:                               ProcCmdSetDepthBounds
CmdSetStencilCompareMask:                        ProcCmdSetStencilCompareMask
CmdSetStencilWriteMask:                          ProcCmdSetStencilWriteMask
CmdSetStencilReference:                          ProcCmdSetStencilReference
CmdBindDescriptorSets:                           ProcCmdBindDescriptorSets
CmdBindIndexBuffer:                              ProcCmdBindIndexBuffer
CmdBindVertexBuffers:                            ProcCmdBindVertexBuffers
CmdDraw:                                         ProcCmdDraw
CmdDrawIndexed:                                  ProcCmdDrawIndexed
CmdDrawIndirect:                                 ProcCmdDrawIndirect
CmdDrawIndexedIndirect:                          ProcCmdDrawIndexedIndirect
CmdDispatch:                                     ProcCmdDispatch
CmdDispatchIndirect:                             ProcCmdDispatchIndirect
CmdCopyBuffer:                                   ProcCmdCopyBuffer
CmdCopyImage:                                    ProcCmdCopyImage
CmdBlitImage:                                    ProcCmdBlitImage
CmdCopyBufferToImage:                            ProcCmdCopyBufferToImage
CmdCopyImageToBuffer:                            ProcCmdCopyImageToBuffer
CmdUpdateBuffer:                                 ProcCmdUpdateBuffer
CmdFillBuffer:                                   ProcCmdFillBuffer
CmdClearColorImage:                              ProcCmdClearColorImage
CmdClearDepthStencilImage:                       ProcCmdClearDepthStencilImage
CmdClearAttachments:                             ProcCmdClearAttachments
CmdResolveImage:                                 ProcCmdResolveImage
CmdSetEvent:                                     ProcCmdSetEvent
CmdResetEvent:                                   ProcCmdResetEvent
CmdWaitEvents:                                   ProcCmdWaitEvents
CmdPipelineBarrier:                              ProcCmdPipelineBarrier
CmdBeginQuery:                                   ProcCmdBeginQuery
CmdEndQuery:                                     ProcCmdEndQuery
CmdResetQueryPool:                               ProcCmdResetQueryPool
CmdWriteTimestamp:                               ProcCmdWriteTimestamp
CmdCopyQueryPoolResults:                         ProcCmdCopyQueryPoolResults
CmdPushConstants:                                ProcCmdPushConstants
CmdBeginRenderPass:                              ProcCmdBeginRenderPass
CmdNextSubpass:                                  ProcCmdNextSubpass
CmdEndRenderPass:                                ProcCmdEndRenderPass
CmdExecuteCommands:                              ProcCmdExecuteCommands
BindBufferMemory2:                               ProcBindBufferMemory2
BindImageMemory2:                                ProcBindImageMemory2
GetDeviceGroupPeerMemoryFeatures:                ProcGetDeviceGroupPeerMemoryFeatures
CmdSetDeviceMask:                                ProcCmdSetDeviceMask
CmdDispatchBase:                                 ProcCmdDispatchBase
GetImageMemoryRequirements2:                     ProcGetImageMemoryRequirements2
GetBufferMemoryRequirements2:                    ProcGetBufferMemoryRequirements2
GetImageSparseMemoryRequirements2:               ProcGetImageSparseMemoryRequirements2
TrimCommandPool:                                 ProcTrimCommandPool
GetDeviceQueue2:                                 ProcGetDeviceQueue2
CreateSamplerYcbcrConversion:                    ProcCreateSamplerYcbcrConversion
DestroySamplerYcbcrConversion:                   ProcDestroySamplerYcbcrConversion
CreateDescriptorUpdateTemplate:                  ProcCreateDescriptorUpdateTemplate
DestroyDescriptorUpdateTemplate:                 ProcDestroyDescriptorUpdateTemplate
UpdateDescriptorSetWithTemplate:                 ProcUpdateDescriptorSetWithTemplate
GetDescriptorSetLayoutSupport:                   ProcGetDescriptorSetLayoutSupport
CmdDrawIndirectCount:                            ProcCmdDrawIndirectCount
CmdDrawIndexedIndirectCount:                     ProcCmdDrawIndexedIndirectCount
CreateRenderPass2:                               ProcCreateRenderPass2
CmdBeginRenderPass2:                             ProcCmdBeginRenderPass2
CmdNextSubpass2:                                 ProcCmdNextSubpass2
CmdEndRenderPass2:                               ProcCmdEndRenderPass2
ResetQueryPool:                                  ProcResetQueryPool
GetSemaphoreCounterValue:                        ProcGetSemaphoreCounterValue
WaitSemaphores:                                  ProcWaitSemaphores
SignalSemaphore:                                 ProcSignalSemaphore
GetBufferDeviceAddress:                          ProcGetBufferDeviceAddress
GetBufferOpaqueCaptureAddress:                   ProcGetBufferOpaqueCaptureAddress
GetDeviceMemoryOpaqueCaptureAddress:             ProcGetDeviceMemoryOpaqueCaptureAddress
CreateSwapchainKHR:                              ProcCreateSwapchainKHR
DestroySwapchainKHR:                             ProcDestroySwapchainKHR
GetSwapchainImagesKHR:                           ProcGetSwapchainImagesKHR
AcquireNextImageKHR:                             ProcAcquireNextImageKHR
QueuePresentKHR:                                 ProcQueuePresentKHR
GetDeviceGroupPresentCapabilitiesKHR:            ProcGetDeviceGroupPresentCapabilitiesKHR
GetDeviceGroupSurfacePresentModesKHR:            ProcGetDeviceGroupSurfacePresentModesKHR
AcquireNextImage2KHR:                            ProcAcquireNextImage2KHR
CreateSharedSwapchainsKHR:                       ProcCreateSharedSwapchainsKHR
GetDeviceGroupPeerMemoryFeaturesKHR:             ProcGetDeviceGroupPeerMemoryFeaturesKHR
CmdSetDeviceMaskKHR:                             ProcCmdSetDeviceMaskKHR
CmdDispatchBaseKHR:                              ProcCmdDispatchBaseKHR
TrimCommandPoolKHR:                              ProcTrimCommandPoolKHR
GetMemoryFdKHR:                                  ProcGetMemoryFdKHR
GetMemoryFdPropertiesKHR:                        ProcGetMemoryFdPropertiesKHR
ImportSemaphoreFdKHR:                            ProcImportSemaphoreFdKHR
GetSemaphoreFdKHR:                               ProcGetSemaphoreFdKHR
CmdPushDescriptorSetKHR:                         ProcCmdPushDescriptorSetKHR
CmdPushDescriptorSetWithTemplateKHR:             ProcCmdPushDescriptorSetWithTemplateKHR
CreateDescriptorUpdateTemplateKHR:               ProcCreateDescriptorUpdateTemplateKHR
DestroyDescriptorUpdateTemplateKHR:              ProcDestroyDescriptorUpdateTemplateKHR
UpdateDescriptorSetWithTemplateKHR:              ProcUpdateDescriptorSetWithTemplateKHR
CreateRenderPass2KHR:                            ProcCreateRenderPass2KHR
CmdBeginRenderPass2KHR:                          ProcCmdBeginRenderPass2KHR
CmdNextSubpass2KHR:                              ProcCmdNextSubpass2KHR
CmdEndRenderPass2KHR:                            ProcCmdEndRenderPass2KHR
GetSwapchainStatusKHR:                           ProcGetSwapchainStatusKHR
ImportFenceFdKHR:                                ProcImportFenceFdKHR
GetFenceFdKHR:                                   ProcGetFenceFdKHR
AcquireProfilingLockKHR:                         ProcAcquireProfilingLockKHR
ReleaseProfilingLockKHR:                         ProcReleaseProfilingLockKHR
GetImageMemoryRequirements2KHR:                  ProcGetImageMemoryRequirements2KHR
GetBufferMemoryRequirements2KHR:                 ProcGetBufferMemoryRequirements2KHR
GetImageSparseMemoryRequirements2KHR:            ProcGetImageSparseMemoryRequirements2KHR
CreateSamplerYcbcrConversionKHR:                 ProcCreateSamplerYcbcrConversionKHR
DestroySamplerYcbcrConversionKHR:                ProcDestroySamplerYcbcrConversionKHR
BindBufferMemory2KHR:                            ProcBindBufferMemory2KHR
BindImageMemory2KHR:                             ProcBindImageMemory2KHR
GetDescriptorSetLayoutSupportKHR:                ProcGetDescriptorSetLayoutSupportKHR
CmdDrawIndirectCountKHR:                         ProcCmdDrawIndirectCountKHR
CmdDrawIndexedIndirectCountKHR:                  ProcCmdDrawIndexedIndirectCountKHR
GetSemaphoreCounterValueKHR:                     ProcGetSemaphoreCounterValueKHR
WaitSemaphoresKHR:                               ProcWaitSemaphoresKHR
SignalSemaphoreKHR:                              ProcSignalSemaphoreKHR
CmdSetFragmentShadingRateKHR:                    ProcCmdSetFragmentShadingRateKHR
WaitForPresentKHR:                               ProcWaitForPresentKHR
GetBufferDeviceAddressKHR:                       ProcGetBufferDeviceAddressKHR
GetBufferOpaqueCaptureAddressKHR:                ProcGetBufferOpaqueCaptureAddressKHR
GetDeviceMemoryOpaqueCaptureAddressKHR:          ProcGetDeviceMemoryOpaqueCaptureAddressKHR
CreateDeferredOperationKHR:                      ProcCreateDeferredOperationKHR
DestroyDeferredOperationKHR:                     ProcDestroyDeferredOperationKHR
GetDeferredOperationMaxConcurrencyKHR:           ProcGetDeferredOperationMaxConcurrencyKHR
GetDeferredOperationResultKHR:                   ProcGetDeferredOperationResultKHR
DeferredOperationJoinKHR:                        ProcDeferredOperationJoinKHR
GetPipelineExecutablePropertiesKHR:              ProcGetPipelineExecutablePropertiesKHR
GetPipelineExecutableStatisticsKHR:              ProcGetPipelineExecutableStatisticsKHR
GetPipelineExecutableInternalRepresentationsKHR: ProcGetPipelineExecutableInternalRepresentationsKHR
CmdSetEvent2KHR:                                 ProcCmdSetEvent2KHR
CmdResetEvent2KHR:                               ProcCmdResetEvent2KHR
CmdWaitEvents2KHR:                               ProcCmdWaitEvents2KHR
CmdPipelineBarrier2KHR:                          ProcCmdPipelineBarrier2KHR
CmdWriteTimestamp2KHR:                           ProcCmdWriteTimestamp2KHR
QueueSubmit2KHR:                                 ProcQueueSubmit2KHR
CmdWriteBufferMarker2AMD:                        ProcCmdWriteBufferMarker2AMD
GetQueueCheckpointData2NV:                       ProcGetQueueCheckpointData2NV
CmdCopyBuffer2KHR:                               ProcCmdCopyBuffer2KHR
CmdCopyImage2KHR:                                ProcCmdCopyImage2KHR
CmdCopyBufferToImage2KHR:                        ProcCmdCopyBufferToImage2KHR
CmdCopyImageToBuffer2KHR:                        ProcCmdCopyImageToBuffer2KHR
CmdBlitImage2KHR:                                ProcCmdBlitImage2KHR
CmdResolveImage2KHR:                             ProcCmdResolveImage2KHR
DebugMarkerSetObjectTagEXT:                      ProcDebugMarkerSetObjectTagEXT
DebugMarkerSetObjectNameEXT:                     ProcDebugMarkerSetObjectNameEXT
CmdDebugMarkerBeginEXT:                          ProcCmdDebugMarkerBeginEXT
CmdDebugMarkerEndEXT:                            ProcCmdDebugMarkerEndEXT
CmdDebugMarkerInsertEXT:                         ProcCmdDebugMarkerInsertEXT
CmdBindTransformFeedbackBuffersEXT:              ProcCmdBindTransformFeedbackBuffersEXT
CmdBeginTransformFeedbackEXT:                    ProcCmdBeginTransformFeedbackEXT
CmdEndTransformFeedbackEXT:                      ProcCmdEndTransformFeedbackEXT
CmdBeginQueryIndexedEXT:                         ProcCmdBeginQueryIndexedEXT
CmdEndQueryIndexedEXT:                           ProcCmdEndQueryIndexedEXT
CmdDrawIndirectByteCountEXT:                     ProcCmdDrawIndirectByteCountEXT
CreateCuModuleNVX:                               ProcCreateCuModuleNVX
CreateCuFunctionNVX:                             ProcCreateCuFunctionNVX
DestroyCuModuleNVX:                              ProcDestroyCuModuleNVX
DestroyCuFunctionNVX:                            ProcDestroyCuFunctionNVX
CmdCuLaunchKernelNVX:                            ProcCmdCuLaunchKernelNVX
GetImageViewHandleNVX:                           ProcGetImageViewHandleNVX
GetImageViewAddressNVX:                          ProcGetImageViewAddressNVX
CmdDrawIndirectCountAMD:                         ProcCmdDrawIndirectCountAMD
CmdDrawIndexedIndirectCountAMD:                  ProcCmdDrawIndexedIndirectCountAMD
GetShaderInfoAMD:                                ProcGetShaderInfoAMD
CmdBeginConditionalRenderingEXT:                 ProcCmdBeginConditionalRenderingEXT
CmdEndConditionalRenderingEXT:                   ProcCmdEndConditionalRenderingEXT
CmdSetViewportWScalingNV:                        ProcCmdSetViewportWScalingNV
DisplayPowerControlEXT:                          ProcDisplayPowerControlEXT
RegisterDeviceEventEXT:                          ProcRegisterDeviceEventEXT
RegisterDisplayEventEXT:                         ProcRegisterDisplayEventEXT
GetSwapchainCounterEXT:                          ProcGetSwapchainCounterEXT
GetRefreshCycleDurationGOOGLE:                   ProcGetRefreshCycleDurationGOOGLE
GetPastPresentationTimingGOOGLE:                 ProcGetPastPresentationTimingGOOGLE
CmdSetDiscardRectangleEXT:                       ProcCmdSetDiscardRectangleEXT
SetHdrMetadataEXT:                               ProcSetHdrMetadataEXT
SetDebugUtilsObjectNameEXT:                      ProcSetDebugUtilsObjectNameEXT
SetDebugUtilsObjectTagEXT:                       ProcSetDebugUtilsObjectTagEXT
QueueBeginDebugUtilsLabelEXT:                    ProcQueueBeginDebugUtilsLabelEXT
QueueEndDebugUtilsLabelEXT:                      ProcQueueEndDebugUtilsLabelEXT
QueueInsertDebugUtilsLabelEXT:                   ProcQueueInsertDebugUtilsLabelEXT
CmdBeginDebugUtilsLabelEXT:                      ProcCmdBeginDebugUtilsLabelEXT
CmdEndDebugUtilsLabelEXT:                        ProcCmdEndDebugUtilsLabelEXT
CmdInsertDebugUtilsLabelEXT:                     ProcCmdInsertDebugUtilsLabelEXT
CmdSetSampleLocationsEXT:                        ProcCmdSetSampleLocationsEXT
GetImageDrmFormatModifierPropertiesEXT:          ProcGetImageDrmFormatModifierPropertiesEXT
CreateValidationCacheEXT:                        ProcCreateValidationCacheEXT
DestroyValidationCacheEXT:                       ProcDestroyValidationCacheEXT
MergeValidationCachesEXT:                        ProcMergeValidationCachesEXT
GetValidationCacheDataEXT:                       ProcGetValidationCacheDataEXT
CmdBindShadingRateImageNV:                       ProcCmdBindShadingRateImageNV
CmdSetViewportShadingRatePaletteNV:              ProcCmdSetViewportShadingRatePaletteNV
CmdSetCoarseSampleOrderNV:                       ProcCmdSetCoarseSampleOrderNV
CreateAccelerationStructureNV:                   ProcCreateAccelerationStructureNV
DestroyAccelerationStructureNV:                  ProcDestroyAccelerationStructureNV
GetAccelerationStructureMemoryRequirementsNV:    ProcGetAccelerationStructureMemoryRequirementsNV
BindAccelerationStructureMemoryNV:               ProcBindAccelerationStructureMemoryNV
CmdBuildAccelerationStructureNV:                 ProcCmdBuildAccelerationStructureNV
CmdCopyAccelerationStructureNV:                  ProcCmdCopyAccelerationStructureNV
CmdTraceRaysNV:                                  ProcCmdTraceRaysNV
CreateRayTracingPipelinesNV:                     ProcCreateRayTracingPipelinesNV
GetRayTracingShaderGroupHandlesKHR:              ProcGetRayTracingShaderGroupHandlesKHR
GetRayTracingShaderGroupHandlesNV:               ProcGetRayTracingShaderGroupHandlesNV
GetAccelerationStructureHandleNV:                ProcGetAccelerationStructureHandleNV
CmdWriteAccelerationStructuresPropertiesNV:      ProcCmdWriteAccelerationStructuresPropertiesNV
CompileDeferredNV:                               ProcCompileDeferredNV
GetMemoryHostPointerPropertiesEXT:               ProcGetMemoryHostPointerPropertiesEXT
CmdWriteBufferMarkerAMD:                         ProcCmdWriteBufferMarkerAMD
GetCalibratedTimestampsEXT:                      ProcGetCalibratedTimestampsEXT
CmdDrawMeshTasksNV:                              ProcCmdDrawMeshTasksNV
CmdDrawMeshTasksIndirectNV:                      ProcCmdDrawMeshTasksIndirectNV
CmdDrawMeshTasksIndirectCountNV:                 ProcCmdDrawMeshTasksIndirectCountNV
CmdSetExclusiveScissorNV:                        ProcCmdSetExclusiveScissorNV
CmdSetCheckpointNV:                              ProcCmdSetCheckpointNV
GetQueueCheckpointDataNV:                        ProcGetQueueCheckpointDataNV
InitializePerformanceApiINTEL:                   ProcInitializePerformanceApiINTEL
UninitializePerformanceApiINTEL:                 ProcUninitializePerformanceApiINTEL
CmdSetPerformanceMarkerINTEL:                    ProcCmdSetPerformanceMarkerINTEL
CmdSetPerformanceStreamMarkerINTEL:              ProcCmdSetPerformanceStreamMarkerINTEL
CmdSetPerformanceOverrideINTEL:                  ProcCmdSetPerformanceOverrideINTEL
AcquirePerformanceConfigurationINTEL:            ProcAcquirePerformanceConfigurationINTEL
ReleasePerformanceConfigurationINTEL:            ProcReleasePerformanceConfigurationINTEL
QueueSetPerformanceConfigurationINTEL:           ProcQueueSetPerformanceConfigurationINTEL
GetPerformanceParameterINTEL:                    ProcGetPerformanceParameterINTEL
SetLocalDimmingAMD:                              ProcSetLocalDimmingAMD
GetBufferDeviceAddressEXT:                       ProcGetBufferDeviceAddressEXT
CmdSetLineStippleEXT:                            ProcCmdSetLineStippleEXT
ResetQueryPoolEXT:                               ProcResetQueryPoolEXT
CmdSetCullModeEXT:                               ProcCmdSetCullModeEXT
CmdSetFrontFaceEXT:                              ProcCmdSetFrontFaceEXT
CmdSetPrimitiveTopologyEXT:                      ProcCmdSetPrimitiveTopologyEXT
CmdSetViewportWithCountEXT:                      ProcCmdSetViewportWithCountEXT
CmdSetScissorWithCountEXT:                       ProcCmdSetScissorWithCountEXT
CmdBindVertexBuffers2EXT:                        ProcCmdBindVertexBuffers2EXT
CmdSetDepthTestEnableEXT:                        ProcCmdSetDepthTestEnableEXT
CmdSetDepthWriteEnableEXT:                       ProcCmdSetDepthWriteEnableEXT
CmdSetDepthCompareOpEXT:                         ProcCmdSetDepthCompareOpEXT
CmdSetDepthBoundsTestEnableEXT:                  ProcCmdSetDepthBoundsTestEnableEXT
CmdSetStencilTestEnableEXT:                      ProcCmdSetStencilTestEnableEXT
CmdSetStencilOpEXT:                              ProcCmdSetStencilOpEXT
GetGeneratedCommandsMemoryRequirementsNV:        ProcGetGeneratedCommandsMemoryRequirementsNV
CmdPreprocessGeneratedCommandsNV:                ProcCmdPreprocessGeneratedCommandsNV
CmdExecuteGeneratedCommandsNV:                   ProcCmdExecuteGeneratedCommandsNV
CmdBindPipelineShaderGroupNV:                    ProcCmdBindPipelineShaderGroupNV
CreateIndirectCommandsLayoutNV:                  ProcCreateIndirectCommandsLayoutNV
DestroyIndirectCommandsLayoutNV:                 ProcDestroyIndirectCommandsLayoutNV
CreatePrivateDataSlotEXT:                        ProcCreatePrivateDataSlotEXT
DestroyPrivateDataSlotEXT:                       ProcDestroyPrivateDataSlotEXT
SetPrivateDataEXT:                               ProcSetPrivateDataEXT
GetPrivateDataEXT:                               ProcGetPrivateDataEXT
CmdSetFragmentShadingRateEnumNV:                 ProcCmdSetFragmentShadingRateEnumNV
CmdSetVertexInputEXT:                            ProcCmdSetVertexInputEXT
GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI:   ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI
CmdSubpassShadingHUAWEI:                         ProcCmdSubpassShadingHUAWEI
CmdBindInvocationMaskHUAWEI:                     ProcCmdBindInvocationMaskHUAWEI
GetMemoryRemoteAddressNV:                        ProcGetMemoryRemoteAddressNV
CmdSetPatchControlPointsEXT:                     ProcCmdSetPatchControlPointsEXT
CmdSetRasterizerDiscardEnableEXT:                ProcCmdSetRasterizerDiscardEnableEXT
CmdSetDepthBiasEnableEXT:                        ProcCmdSetDepthBiasEnableEXT
CmdSetLogicOpEXT:                                ProcCmdSetLogicOpEXT
CmdSetPrimitiveRestartEnableEXT:                 ProcCmdSetPrimitiveRestartEnableEXT
CmdDrawMultiEXT:                                 ProcCmdDrawMultiEXT
CmdDrawMultiIndexedEXT:                          ProcCmdDrawMultiIndexedEXT
CreateAccelerationStructureKHR:                  ProcCreateAccelerationStructureKHR
DestroyAccelerationStructureKHR:                 ProcDestroyAccelerationStructureKHR
CmdBuildAccelerationStructuresKHR:               ProcCmdBuildAccelerationStructuresKHR
CmdBuildAccelerationStructuresIndirectKHR:       ProcCmdBuildAccelerationStructuresIndirectKHR
BuildAccelerationStructuresKHR:                  ProcBuildAccelerationStructuresKHR
CopyAccelerationStructureKHR:                    ProcCopyAccelerationStructureKHR
CopyAccelerationStructureToMemoryKHR:            ProcCopyAccelerationStructureToMemoryKHR
CopyMemoryToAccelerationStructureKHR:            ProcCopyMemoryToAccelerationStructureKHR
WriteAccelerationStructuresPropertiesKHR:        ProcWriteAccelerationStructuresPropertiesKHR
CmdCopyAccelerationStructureKHR:                 ProcCmdCopyAccelerationStructureKHR
CmdCopyAccelerationStructureToMemoryKHR:         ProcCmdCopyAccelerationStructureToMemoryKHR
CmdCopyMemoryToAccelerationStructureKHR:         ProcCmdCopyMemoryToAccelerationStructureKHR
GetAccelerationStructureDeviceAddressKHR:        ProcGetAccelerationStructureDeviceAddressKHR
CmdWriteAccelerationStructuresPropertiesKHR:     ProcCmdWriteAccelerationStructuresPropertiesKHR
GetDeviceAccelerationStructureCompatibilityKHR:  ProcGetDeviceAccelerationStructureCompatibilityKHR
GetAccelerationStructureBuildSizesKHR:           ProcGetAccelerationStructureBuildSizesKHR
CmdTraceRaysKHR:                                 ProcCmdTraceRaysKHR
CreateRayTracingPipelinesKHR:                    ProcCreateRayTracingPipelinesKHR
GetRayTracingCaptureReplayShaderGroupHandlesKHR: ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR
CmdTraceRaysIndirectKHR:                         ProcCmdTraceRaysIndirectKHR
GetRayTracingShaderGroupStackSizeKHR:            ProcGetRayTracingShaderGroupStackSizeKHR
CmdSetRayTracingPipelineStackSizeKHR:            ProcCmdSetRayTracingPipelineStackSizeKHR
GetMemoryWin32HandleKHR:                         ProcGetMemoryWin32HandleKHR
GetMemoryWin32HandlePropertiesKHR:               ProcGetMemoryWin32HandlePropertiesKHR
ImportSemaphoreWin32HandleKHR:                   ProcImportSemaphoreWin32HandleKHR
GetSemaphoreWin32HandleKHR:                      ProcGetSemaphoreWin32HandleKHR
ImportFenceWin32HandleKHR:                       ProcImportFenceWin32HandleKHR
GetFenceWin32HandleKHR:                          ProcGetFenceWin32HandleKHR
GetMemoryWin32HandleNV:                          ProcGetMemoryWin32HandleNV
AcquireFullScreenExclusiveModeEXT:               ProcAcquireFullScreenExclusiveModeEXT
ReleaseFullScreenExclusiveModeEXT:               ProcReleaseFullScreenExclusiveModeEXT
GetDeviceGroupSurfacePresentModes2EXT:           ProcGetDeviceGroupSurfacePresentModes2EXT

// Loader Procedures
CreateInstance:                       ProcCreateInstance
EnumerateInstanceExtensionProperties: ProcEnumerateInstanceExtensionProperties
EnumerateInstanceLayerProperties:     ProcEnumerateInstanceLayerProperties
EnumerateInstanceVersion:             ProcEnumerateInstanceVersion
DebugUtilsMessengerCallbackEXT:       ProcDebugUtilsMessengerCallbackEXT
DeviceMemoryReportCallbackEXT:        ProcDeviceMemoryReportCallbackEXT

load_proc_addresses :: proc(set_proc_address: SetProcAddressType) {
	// Instance Procedures
	set_proc_address(&DestroyInstance,                                                 "vkDestroyInstance")
	set_proc_address(&EnumeratePhysicalDevices,                                        "vkEnumeratePhysicalDevices")
	set_proc_address(&GetPhysicalDeviceFeatures,                                       "vkGetPhysicalDeviceFeatures")
	set_proc_address(&GetPhysicalDeviceFormatProperties,                               "vkGetPhysicalDeviceFormatProperties")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties,                          "vkGetPhysicalDeviceImageFormatProperties")
	set_proc_address(&GetPhysicalDeviceProperties,                                     "vkGetPhysicalDeviceProperties")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties,                          "vkGetPhysicalDeviceQueueFamilyProperties")
	set_proc_address(&GetPhysicalDeviceMemoryProperties,                               "vkGetPhysicalDeviceMemoryProperties")
	set_proc_address(&GetInstanceProcAddr,                                             "vkGetInstanceProcAddr")
	set_proc_address(&CreateDevice,                                                    "vkCreateDevice")
	set_proc_address(&EnumerateDeviceExtensionProperties,                              "vkEnumerateDeviceExtensionProperties")
	set_proc_address(&EnumerateDeviceLayerProperties,                                  "vkEnumerateDeviceLayerProperties")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties,                    "vkGetPhysicalDeviceSparseImageFormatProperties")
	set_proc_address(&EnumeratePhysicalDeviceGroups,                                   "vkEnumeratePhysicalDeviceGroups")
	set_proc_address(&GetPhysicalDeviceFeatures2,                                      "vkGetPhysicalDeviceFeatures2")
	set_proc_address(&GetPhysicalDeviceProperties2,                                    "vkGetPhysicalDeviceProperties2")
	set_proc_address(&GetPhysicalDeviceFormatProperties2,                              "vkGetPhysicalDeviceFormatProperties2")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties2,                         "vkGetPhysicalDeviceImageFormatProperties2")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties2,                         "vkGetPhysicalDeviceQueueFamilyProperties2")
	set_proc_address(&GetPhysicalDeviceMemoryProperties2,                              "vkGetPhysicalDeviceMemoryProperties2")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties2,                   "vkGetPhysicalDeviceSparseImageFormatProperties2")
	set_proc_address(&GetPhysicalDeviceExternalBufferProperties,                       "vkGetPhysicalDeviceExternalBufferProperties")
	set_proc_address(&GetPhysicalDeviceExternalFenceProperties,                        "vkGetPhysicalDeviceExternalFenceProperties")
	set_proc_address(&GetPhysicalDeviceExternalSemaphoreProperties,                    "vkGetPhysicalDeviceExternalSemaphoreProperties")
	set_proc_address(&DestroySurfaceKHR,                                               "vkDestroySurfaceKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceSupportKHR,                              "vkGetPhysicalDeviceSurfaceSupportKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilitiesKHR,                         "vkGetPhysicalDeviceSurfaceCapabilitiesKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceFormatsKHR,                              "vkGetPhysicalDeviceSurfaceFormatsKHR")
	set_proc_address(&GetPhysicalDeviceSurfacePresentModesKHR,                         "vkGetPhysicalDeviceSurfacePresentModesKHR")
	set_proc_address(&GetPhysicalDevicePresentRectanglesKHR,                           "vkGetPhysicalDevicePresentRectanglesKHR")
	set_proc_address(&GetPhysicalDeviceDisplayPropertiesKHR,                           "vkGetPhysicalDeviceDisplayPropertiesKHR")
	set_proc_address(&GetPhysicalDeviceDisplayPlanePropertiesKHR,                      "vkGetPhysicalDeviceDisplayPlanePropertiesKHR")
	set_proc_address(&GetDisplayPlaneSupportedDisplaysKHR,                             "vkGetDisplayPlaneSupportedDisplaysKHR")
	set_proc_address(&GetDisplayModePropertiesKHR,                                     "vkGetDisplayModePropertiesKHR")
	set_proc_address(&CreateDisplayModeKHR,                                            "vkCreateDisplayModeKHR")
	set_proc_address(&GetDisplayPlaneCapabilitiesKHR,                                  "vkGetDisplayPlaneCapabilitiesKHR")
	set_proc_address(&CreateDisplayPlaneSurfaceKHR,                                    "vkCreateDisplayPlaneSurfaceKHR")
	set_proc_address(&GetPhysicalDeviceFeatures2KHR,                                   "vkGetPhysicalDeviceFeatures2KHR")
	set_proc_address(&GetPhysicalDeviceProperties2KHR,                                 "vkGetPhysicalDeviceProperties2KHR")
	set_proc_address(&GetPhysicalDeviceFormatProperties2KHR,                           "vkGetPhysicalDeviceFormatProperties2KHR")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties2KHR,                      "vkGetPhysicalDeviceImageFormatProperties2KHR")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties2KHR,                      "vkGetPhysicalDeviceQueueFamilyProperties2KHR")
	set_proc_address(&GetPhysicalDeviceMemoryProperties2KHR,                           "vkGetPhysicalDeviceMemoryProperties2KHR")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties2KHR,                "vkGetPhysicalDeviceSparseImageFormatProperties2KHR")
	set_proc_address(&EnumeratePhysicalDeviceGroupsKHR,                                "vkEnumeratePhysicalDeviceGroupsKHR")
	set_proc_address(&GetPhysicalDeviceExternalBufferPropertiesKHR,                    "vkGetPhysicalDeviceExternalBufferPropertiesKHR")
	set_proc_address(&GetPhysicalDeviceExternalSemaphorePropertiesKHR,                 "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR")
	set_proc_address(&GetPhysicalDeviceExternalFencePropertiesKHR,                     "vkGetPhysicalDeviceExternalFencePropertiesKHR")
	set_proc_address(&EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR,   "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR")
	set_proc_address(&GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR,           "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilities2KHR,                        "vkGetPhysicalDeviceSurfaceCapabilities2KHR")
	set_proc_address(&GetPhysicalDeviceSurfaceFormats2KHR,                             "vkGetPhysicalDeviceSurfaceFormats2KHR")
	set_proc_address(&GetPhysicalDeviceDisplayProperties2KHR,                          "vkGetPhysicalDeviceDisplayProperties2KHR")
	set_proc_address(&GetPhysicalDeviceDisplayPlaneProperties2KHR,                     "vkGetPhysicalDeviceDisplayPlaneProperties2KHR")
	set_proc_address(&GetDisplayModeProperties2KHR,                                    "vkGetDisplayModeProperties2KHR")
	set_proc_address(&GetDisplayPlaneCapabilities2KHR,                                 "vkGetDisplayPlaneCapabilities2KHR")
	set_proc_address(&GetPhysicalDeviceFragmentShadingRatesKHR,                        "vkGetPhysicalDeviceFragmentShadingRatesKHR")
	set_proc_address(&CreateDebugReportCallbackEXT,                                    "vkCreateDebugReportCallbackEXT")
	set_proc_address(&DestroyDebugReportCallbackEXT,                                   "vkDestroyDebugReportCallbackEXT")
	set_proc_address(&DebugReportMessageEXT,                                           "vkDebugReportMessageEXT")
	set_proc_address(&GetPhysicalDeviceExternalImageFormatPropertiesNV,                "vkGetPhysicalDeviceExternalImageFormatPropertiesNV")
	set_proc_address(&ReleaseDisplayEXT,                                               "vkReleaseDisplayEXT")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilities2EXT,                        "vkGetPhysicalDeviceSurfaceCapabilities2EXT")
	set_proc_address(&CreateDebugUtilsMessengerEXT,                                    "vkCreateDebugUtilsMessengerEXT")
	set_proc_address(&DestroyDebugUtilsMessengerEXT,                                   "vkDestroyDebugUtilsMessengerEXT")
	set_proc_address(&SubmitDebugUtilsMessageEXT,                                      "vkSubmitDebugUtilsMessageEXT")
	set_proc_address(&GetPhysicalDeviceMultisamplePropertiesEXT,                       "vkGetPhysicalDeviceMultisamplePropertiesEXT")
	set_proc_address(&GetPhysicalDeviceCalibrateableTimeDomainsEXT,                    "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT")
	set_proc_address(&GetPhysicalDeviceToolPropertiesEXT,                              "vkGetPhysicalDeviceToolPropertiesEXT")
	set_proc_address(&GetPhysicalDeviceCooperativeMatrixPropertiesNV,                  "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV")
	set_proc_address(&GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV")
	set_proc_address(&CreateHeadlessSurfaceEXT,                                        "vkCreateHeadlessSurfaceEXT")
	set_proc_address(&AcquireDrmDisplayEXT,                                            "vkAcquireDrmDisplayEXT")
	set_proc_address(&GetDrmDisplayEXT,                                                "vkGetDrmDisplayEXT")
	set_proc_address(&AcquireWinrtDisplayNV,                                           "vkAcquireWinrtDisplayNV")
	set_proc_address(&GetWinrtDisplayNV,                                               "vkGetWinrtDisplayNV")
	set_proc_address(&CreateWin32SurfaceKHR,                                           "vkCreateWin32SurfaceKHR")
	set_proc_address(&GetPhysicalDeviceWin32PresentationSupportKHR,                    "vkGetPhysicalDeviceWin32PresentationSupportKHR")
	set_proc_address(&GetPhysicalDeviceSurfacePresentModes2EXT,                        "vkGetPhysicalDeviceSurfacePresentModes2EXT")
	set_proc_address(&CreateMetalSurfaceEXT,                                           "vkCreateMetalSurfaceEXT")
	set_proc_address(&CreateMacOSSurfaceMVK,                                           "vkCreateMacOSSurfaceMVK")
	set_proc_address(&CreateIOSSurfaceMVK,                                             "vkCreateIOSSurfaceMVK")

	// Device Procedures
	set_proc_address(&GetDeviceProcAddr,                               "vkGetDeviceProcAddr")
	set_proc_address(&DestroyDevice,                                   "vkDestroyDevice")
	set_proc_address(&GetDeviceQueue,                                  "vkGetDeviceQueue")
	set_proc_address(&QueueSubmit,                                     "vkQueueSubmit")
	set_proc_address(&QueueWaitIdle,                                   "vkQueueWaitIdle")
	set_proc_address(&DeviceWaitIdle,                                  "vkDeviceWaitIdle")
	set_proc_address(&AllocateMemory,                                  "vkAllocateMemory")
	set_proc_address(&FreeMemory,                                      "vkFreeMemory")
	set_proc_address(&MapMemory,                                       "vkMapMemory")
	set_proc_address(&UnmapMemory,                                     "vkUnmapMemory")
	set_proc_address(&FlushMappedMemoryRanges,                         "vkFlushMappedMemoryRanges")
	set_proc_address(&InvalidateMappedMemoryRanges,                    "vkInvalidateMappedMemoryRanges")
	set_proc_address(&GetDeviceMemoryCommitment,                       "vkGetDeviceMemoryCommitment")
	set_proc_address(&BindBufferMemory,                                "vkBindBufferMemory")
	set_proc_address(&BindImageMemory,                                 "vkBindImageMemory")
	set_proc_address(&GetBufferMemoryRequirements,                     "vkGetBufferMemoryRequirements")
	set_proc_address(&GetImageMemoryRequirements,                      "vkGetImageMemoryRequirements")
	set_proc_address(&GetImageSparseMemoryRequirements,                "vkGetImageSparseMemoryRequirements")
	set_proc_address(&QueueBindSparse,                                 "vkQueueBindSparse")
	set_proc_address(&CreateFence,                                     "vkCreateFence")
	set_proc_address(&DestroyFence,                                    "vkDestroyFence")
	set_proc_address(&ResetFences,                                     "vkResetFences")
	set_proc_address(&GetFenceStatus,                                  "vkGetFenceStatus")
	set_proc_address(&WaitForFences,                                   "vkWaitForFences")
	set_proc_address(&CreateSemaphore,                                 "vkCreateSemaphore")
	set_proc_address(&DestroySemaphore,                                "vkDestroySemaphore")
	set_proc_address(&CreateEvent,                                     "vkCreateEvent")
	set_proc_address(&DestroyEvent,                                    "vkDestroyEvent")
	set_proc_address(&GetEventStatus,                                  "vkGetEventStatus")
	set_proc_address(&SetEvent,                                        "vkSetEvent")
	set_proc_address(&ResetEvent,                                      "vkResetEvent")
	set_proc_address(&CreateQueryPool,                                 "vkCreateQueryPool")
	set_proc_address(&DestroyQueryPool,                                "vkDestroyQueryPool")
	set_proc_address(&GetQueryPoolResults,                             "vkGetQueryPoolResults")
	set_proc_address(&CreateBuffer,                                    "vkCreateBuffer")
	set_proc_address(&DestroyBuffer,                                   "vkDestroyBuffer")
	set_proc_address(&CreateBufferView,                                "vkCreateBufferView")
	set_proc_address(&DestroyBufferView,                               "vkDestroyBufferView")
	set_proc_address(&CreateImage,                                     "vkCreateImage")
	set_proc_address(&DestroyImage,                                    "vkDestroyImage")
	set_proc_address(&GetImageSubresourceLayout,                       "vkGetImageSubresourceLayout")
	set_proc_address(&CreateImageView,                                 "vkCreateImageView")
	set_proc_address(&DestroyImageView,                                "vkDestroyImageView")
	set_proc_address(&CreateShaderModule,                              "vkCreateShaderModule")
	set_proc_address(&DestroyShaderModule,                             "vkDestroyShaderModule")
	set_proc_address(&CreatePipelineCache,                             "vkCreatePipelineCache")
	set_proc_address(&DestroyPipelineCache,                            "vkDestroyPipelineCache")
	set_proc_address(&GetPipelineCacheData,                            "vkGetPipelineCacheData")
	set_proc_address(&MergePipelineCaches,                             "vkMergePipelineCaches")
	set_proc_address(&CreateGraphicsPipelines,                         "vkCreateGraphicsPipelines")
	set_proc_address(&CreateComputePipelines,                          "vkCreateComputePipelines")
	set_proc_address(&DestroyPipeline,                                 "vkDestroyPipeline")
	set_proc_address(&CreatePipelineLayout,                            "vkCreatePipelineLayout")
	set_proc_address(&DestroyPipelineLayout,                           "vkDestroyPipelineLayout")
	set_proc_address(&CreateSampler,                                   "vkCreateSampler")
	set_proc_address(&DestroySampler,                                  "vkDestroySampler")
	set_proc_address(&CreateDescriptorSetLayout,                       "vkCreateDescriptorSetLayout")
	set_proc_address(&DestroyDescriptorSetLayout,                      "vkDestroyDescriptorSetLayout")
	set_proc_address(&CreateDescriptorPool,                            "vkCreateDescriptorPool")
	set_proc_address(&DestroyDescriptorPool,                           "vkDestroyDescriptorPool")
	set_proc_address(&ResetDescriptorPool,                             "vkResetDescriptorPool")
	set_proc_address(&AllocateDescriptorSets,                          "vkAllocateDescriptorSets")
	set_proc_address(&FreeDescriptorSets,                              "vkFreeDescriptorSets")
	set_proc_address(&UpdateDescriptorSets,                            "vkUpdateDescriptorSets")
	set_proc_address(&CreateFramebuffer,                               "vkCreateFramebuffer")
	set_proc_address(&DestroyFramebuffer,                              "vkDestroyFramebuffer")
	set_proc_address(&CreateRenderPass,                                "vkCreateRenderPass")
	set_proc_address(&DestroyRenderPass,                               "vkDestroyRenderPass")
	set_proc_address(&GetRenderAreaGranularity,                        "vkGetRenderAreaGranularity")
	set_proc_address(&CreateCommandPool,                               "vkCreateCommandPool")
	set_proc_address(&DestroyCommandPool,                              "vkDestroyCommandPool")
	set_proc_address(&ResetCommandPool,                                "vkResetCommandPool")
	set_proc_address(&AllocateCommandBuffers,                          "vkAllocateCommandBuffers")
	set_proc_address(&FreeCommandBuffers,                              "vkFreeCommandBuffers")
	set_proc_address(&BeginCommandBuffer,                              "vkBeginCommandBuffer")
	set_proc_address(&EndCommandBuffer,                                "vkEndCommandBuffer")
	set_proc_address(&ResetCommandBuffer,                              "vkResetCommandBuffer")
	set_proc_address(&CmdBindPipeline,                                 "vkCmdBindPipeline")
	set_proc_address(&CmdSetViewport,                                  "vkCmdSetViewport")
	set_proc_address(&CmdSetScissor,                                   "vkCmdSetScissor")
	set_proc_address(&CmdSetLineWidth,                                 "vkCmdSetLineWidth")
	set_proc_address(&CmdSetDepthBias,                                 "vkCmdSetDepthBias")
	set_proc_address(&CmdSetBlendConstants,                            "vkCmdSetBlendConstants")
	set_proc_address(&CmdSetDepthBounds,                               "vkCmdSetDepthBounds")
	set_proc_address(&CmdSetStencilCompareMask,                        "vkCmdSetStencilCompareMask")
	set_proc_address(&CmdSetStencilWriteMask,                          "vkCmdSetStencilWriteMask")
	set_proc_address(&CmdSetStencilReference,                          "vkCmdSetStencilReference")
	set_proc_address(&CmdBindDescriptorSets,                           "vkCmdBindDescriptorSets")
	set_proc_address(&CmdBindIndexBuffer,                              "vkCmdBindIndexBuffer")
	set_proc_address(&CmdBindVertexBuffers,                            "vkCmdBindVertexBuffers")
	set_proc_address(&CmdDraw,                                         "vkCmdDraw")
	set_proc_address(&CmdDrawIndexed,                                  "vkCmdDrawIndexed")
	set_proc_address(&CmdDrawIndirect,                                 "vkCmdDrawIndirect")
	set_proc_address(&CmdDrawIndexedIndirect,                          "vkCmdDrawIndexedIndirect")
	set_proc_address(&CmdDispatch,                                     "vkCmdDispatch")
	set_proc_address(&CmdDispatchIndirect,                             "vkCmdDispatchIndirect")
	set_proc_address(&CmdCopyBuffer,                                   "vkCmdCopyBuffer")
	set_proc_address(&CmdCopyImage,                                    "vkCmdCopyImage")
	set_proc_address(&CmdBlitImage,                                    "vkCmdBlitImage")
	set_proc_address(&CmdCopyBufferToImage,                            "vkCmdCopyBufferToImage")
	set_proc_address(&CmdCopyImageToBuffer,                            "vkCmdCopyImageToBuffer")
	set_proc_address(&CmdUpdateBuffer,                                 "vkCmdUpdateBuffer")
	set_proc_address(&CmdFillBuffer,                                   "vkCmdFillBuffer")
	set_proc_address(&CmdClearColorImage,                              "vkCmdClearColorImage")
	set_proc_address(&CmdClearDepthStencilImage,                       "vkCmdClearDepthStencilImage")
	set_proc_address(&CmdClearAttachments,                             "vkCmdClearAttachments")
	set_proc_address(&CmdResolveImage,                                 "vkCmdResolveImage")
	set_proc_address(&CmdSetEvent,                                     "vkCmdSetEvent")
	set_proc_address(&CmdResetEvent,                                   "vkCmdResetEvent")
	set_proc_address(&CmdWaitEvents,                                   "vkCmdWaitEvents")
	set_proc_address(&CmdPipelineBarrier,                              "vkCmdPipelineBarrier")
	set_proc_address(&CmdBeginQuery,                                   "vkCmdBeginQuery")
	set_proc_address(&CmdEndQuery,                                     "vkCmdEndQuery")
	set_proc_address(&CmdResetQueryPool,                               "vkCmdResetQueryPool")
	set_proc_address(&CmdWriteTimestamp,                               "vkCmdWriteTimestamp")
	set_proc_address(&CmdCopyQueryPoolResults,                         "vkCmdCopyQueryPoolResults")
	set_proc_address(&CmdPushConstants,                                "vkCmdPushConstants")
	set_proc_address(&CmdBeginRenderPass,                              "vkCmdBeginRenderPass")
	set_proc_address(&CmdNextSubpass,                                  "vkCmdNextSubpass")
	set_proc_address(&CmdEndRenderPass,                                "vkCmdEndRenderPass")
	set_proc_address(&CmdExecuteCommands,                              "vkCmdExecuteCommands")
	set_proc_address(&BindBufferMemory2,                               "vkBindBufferMemory2")
	set_proc_address(&BindImageMemory2,                                "vkBindImageMemory2")
	set_proc_address(&GetDeviceGroupPeerMemoryFeatures,                "vkGetDeviceGroupPeerMemoryFeatures")
	set_proc_address(&CmdSetDeviceMask,                                "vkCmdSetDeviceMask")
	set_proc_address(&CmdDispatchBase,                                 "vkCmdDispatchBase")
	set_proc_address(&GetImageMemoryRequirements2,                     "vkGetImageMemoryRequirements2")
	set_proc_address(&GetBufferMemoryRequirements2,                    "vkGetBufferMemoryRequirements2")
	set_proc_address(&GetImageSparseMemoryRequirements2,               "vkGetImageSparseMemoryRequirements2")
	set_proc_address(&TrimCommandPool,                                 "vkTrimCommandPool")
	set_proc_address(&GetDeviceQueue2,                                 "vkGetDeviceQueue2")
	set_proc_address(&CreateSamplerYcbcrConversion,                    "vkCreateSamplerYcbcrConversion")
	set_proc_address(&DestroySamplerYcbcrConversion,                   "vkDestroySamplerYcbcrConversion")
	set_proc_address(&CreateDescriptorUpdateTemplate,                  "vkCreateDescriptorUpdateTemplate")
	set_proc_address(&DestroyDescriptorUpdateTemplate,                 "vkDestroyDescriptorUpdateTemplate")
	set_proc_address(&UpdateDescriptorSetWithTemplate,                 "vkUpdateDescriptorSetWithTemplate")
	set_proc_address(&GetDescriptorSetLayoutSupport,                   "vkGetDescriptorSetLayoutSupport")
	set_proc_address(&CmdDrawIndirectCount,                            "vkCmdDrawIndirectCount")
	set_proc_address(&CmdDrawIndexedIndirectCount,                     "vkCmdDrawIndexedIndirectCount")
	set_proc_address(&CreateRenderPass2,                               "vkCreateRenderPass2")
	set_proc_address(&CmdBeginRenderPass2,                             "vkCmdBeginRenderPass2")
	set_proc_address(&CmdNextSubpass2,                                 "vkCmdNextSubpass2")
	set_proc_address(&CmdEndRenderPass2,                               "vkCmdEndRenderPass2")
	set_proc_address(&ResetQueryPool,                                  "vkResetQueryPool")
	set_proc_address(&GetSemaphoreCounterValue,                        "vkGetSemaphoreCounterValue")
	set_proc_address(&WaitSemaphores,                                  "vkWaitSemaphores")
	set_proc_address(&SignalSemaphore,                                 "vkSignalSemaphore")
	set_proc_address(&GetBufferDeviceAddress,                          "vkGetBufferDeviceAddress")
	set_proc_address(&GetBufferOpaqueCaptureAddress,                   "vkGetBufferOpaqueCaptureAddress")
	set_proc_address(&GetDeviceMemoryOpaqueCaptureAddress,             "vkGetDeviceMemoryOpaqueCaptureAddress")
	set_proc_address(&CreateSwapchainKHR,                              "vkCreateSwapchainKHR")
	set_proc_address(&DestroySwapchainKHR,                             "vkDestroySwapchainKHR")
	set_proc_address(&GetSwapchainImagesKHR,                           "vkGetSwapchainImagesKHR")
	set_proc_address(&AcquireNextImageKHR,                             "vkAcquireNextImageKHR")
	set_proc_address(&QueuePresentKHR,                                 "vkQueuePresentKHR")
	set_proc_address(&GetDeviceGroupPresentCapabilitiesKHR,            "vkGetDeviceGroupPresentCapabilitiesKHR")
	set_proc_address(&GetDeviceGroupSurfacePresentModesKHR,            "vkGetDeviceGroupSurfacePresentModesKHR")
	set_proc_address(&AcquireNextImage2KHR,                            "vkAcquireNextImage2KHR")
	set_proc_address(&CreateSharedSwapchainsKHR,                       "vkCreateSharedSwapchainsKHR")
	set_proc_address(&GetDeviceGroupPeerMemoryFeaturesKHR,             "vkGetDeviceGroupPeerMemoryFeaturesKHR")
	set_proc_address(&CmdSetDeviceMaskKHR,                             "vkCmdSetDeviceMaskKHR")
	set_proc_address(&CmdDispatchBaseKHR,                              "vkCmdDispatchBaseKHR")
	set_proc_address(&TrimCommandPoolKHR,                              "vkTrimCommandPoolKHR")
	set_proc_address(&GetMemoryFdKHR,                                  "vkGetMemoryFdKHR")
	set_proc_address(&GetMemoryFdPropertiesKHR,                        "vkGetMemoryFdPropertiesKHR")
	set_proc_address(&ImportSemaphoreFdKHR,                            "vkImportSemaphoreFdKHR")
	set_proc_address(&GetSemaphoreFdKHR,                               "vkGetSemaphoreFdKHR")
	set_proc_address(&CmdPushDescriptorSetKHR,                         "vkCmdPushDescriptorSetKHR")
	set_proc_address(&CmdPushDescriptorSetWithTemplateKHR,             "vkCmdPushDescriptorSetWithTemplateKHR")
	set_proc_address(&CreateDescriptorUpdateTemplateKHR,               "vkCreateDescriptorUpdateTemplateKHR")
	set_proc_address(&DestroyDescriptorUpdateTemplateKHR,              "vkDestroyDescriptorUpdateTemplateKHR")
	set_proc_address(&UpdateDescriptorSetWithTemplateKHR,              "vkUpdateDescriptorSetWithTemplateKHR")
	set_proc_address(&CreateRenderPass2KHR,                            "vkCreateRenderPass2KHR")
	set_proc_address(&CmdBeginRenderPass2KHR,                          "vkCmdBeginRenderPass2KHR")
	set_proc_address(&CmdNextSubpass2KHR,                              "vkCmdNextSubpass2KHR")
	set_proc_address(&CmdEndRenderPass2KHR,                            "vkCmdEndRenderPass2KHR")
	set_proc_address(&GetSwapchainStatusKHR,                           "vkGetSwapchainStatusKHR")
	set_proc_address(&ImportFenceFdKHR,                                "vkImportFenceFdKHR")
	set_proc_address(&GetFenceFdKHR,                                   "vkGetFenceFdKHR")
	set_proc_address(&AcquireProfilingLockKHR,                         "vkAcquireProfilingLockKHR")
	set_proc_address(&ReleaseProfilingLockKHR,                         "vkReleaseProfilingLockKHR")
	set_proc_address(&GetImageMemoryRequirements2KHR,                  "vkGetImageMemoryRequirements2KHR")
	set_proc_address(&GetBufferMemoryRequirements2KHR,                 "vkGetBufferMemoryRequirements2KHR")
	set_proc_address(&GetImageSparseMemoryRequirements2KHR,            "vkGetImageSparseMemoryRequirements2KHR")
	set_proc_address(&CreateSamplerYcbcrConversionKHR,                 "vkCreateSamplerYcbcrConversionKHR")
	set_proc_address(&DestroySamplerYcbcrConversionKHR,                "vkDestroySamplerYcbcrConversionKHR")
	set_proc_address(&BindBufferMemory2KHR,                            "vkBindBufferMemory2KHR")
	set_proc_address(&BindImageMemory2KHR,                             "vkBindImageMemory2KHR")
	set_proc_address(&GetDescriptorSetLayoutSupportKHR,                "vkGetDescriptorSetLayoutSupportKHR")
	set_proc_address(&CmdDrawIndirectCountKHR,                         "vkCmdDrawIndirectCountKHR")
	set_proc_address(&CmdDrawIndexedIndirectCountKHR,                  "vkCmdDrawIndexedIndirectCountKHR")
	set_proc_address(&GetSemaphoreCounterValueKHR,                     "vkGetSemaphoreCounterValueKHR")
	set_proc_address(&WaitSemaphoresKHR,                               "vkWaitSemaphoresKHR")
	set_proc_address(&SignalSemaphoreKHR,                              "vkSignalSemaphoreKHR")
	set_proc_address(&CmdSetFragmentShadingRateKHR,                    "vkCmdSetFragmentShadingRateKHR")
	set_proc_address(&WaitForPresentKHR,                               "vkWaitForPresentKHR")
	set_proc_address(&GetBufferDeviceAddressKHR,                       "vkGetBufferDeviceAddressKHR")
	set_proc_address(&GetBufferOpaqueCaptureAddressKHR,                "vkGetBufferOpaqueCaptureAddressKHR")
	set_proc_address(&GetDeviceMemoryOpaqueCaptureAddressKHR,          "vkGetDeviceMemoryOpaqueCaptureAddressKHR")
	set_proc_address(&CreateDeferredOperationKHR,                      "vkCreateDeferredOperationKHR")
	set_proc_address(&DestroyDeferredOperationKHR,                     "vkDestroyDeferredOperationKHR")
	set_proc_address(&GetDeferredOperationMaxConcurrencyKHR,           "vkGetDeferredOperationMaxConcurrencyKHR")
	set_proc_address(&GetDeferredOperationResultKHR,                   "vkGetDeferredOperationResultKHR")
	set_proc_address(&DeferredOperationJoinKHR,                        "vkDeferredOperationJoinKHR")
	set_proc_address(&GetPipelineExecutablePropertiesKHR,              "vkGetPipelineExecutablePropertiesKHR")
	set_proc_address(&GetPipelineExecutableStatisticsKHR,              "vkGetPipelineExecutableStatisticsKHR")
	set_proc_address(&GetPipelineExecutableInternalRepresentationsKHR, "vkGetPipelineExecutableInternalRepresentationsKHR")
	set_proc_address(&CmdSetEvent2KHR,                                 "vkCmdSetEvent2KHR")
	set_proc_address(&CmdResetEvent2KHR,                               "vkCmdResetEvent2KHR")
	set_proc_address(&CmdWaitEvents2KHR,                               "vkCmdWaitEvents2KHR")
	set_proc_address(&CmdPipelineBarrier2KHR,                          "vkCmdPipelineBarrier2KHR")
	set_proc_address(&CmdWriteTimestamp2KHR,                           "vkCmdWriteTimestamp2KHR")
	set_proc_address(&QueueSubmit2KHR,                                 "vkQueueSubmit2KHR")
	set_proc_address(&CmdWriteBufferMarker2AMD,                        "vkCmdWriteBufferMarker2AMD")
	set_proc_address(&GetQueueCheckpointData2NV,                       "vkGetQueueCheckpointData2NV")
	set_proc_address(&CmdCopyBuffer2KHR,                               "vkCmdCopyBuffer2KHR")
	set_proc_address(&CmdCopyImage2KHR,                                "vkCmdCopyImage2KHR")
	set_proc_address(&CmdCopyBufferToImage2KHR,                        "vkCmdCopyBufferToImage2KHR")
	set_proc_address(&CmdCopyImageToBuffer2KHR,                        "vkCmdCopyImageToBuffer2KHR")
	set_proc_address(&CmdBlitImage2KHR,                                "vkCmdBlitImage2KHR")
	set_proc_address(&CmdResolveImage2KHR,                             "vkCmdResolveImage2KHR")
	set_proc_address(&DebugMarkerSetObjectTagEXT,                      "vkDebugMarkerSetObjectTagEXT")
	set_proc_address(&DebugMarkerSetObjectNameEXT,                     "vkDebugMarkerSetObjectNameEXT")
	set_proc_address(&CmdDebugMarkerBeginEXT,                          "vkCmdDebugMarkerBeginEXT")
	set_proc_address(&CmdDebugMarkerEndEXT,                            "vkCmdDebugMarkerEndEXT")
	set_proc_address(&CmdDebugMarkerInsertEXT,                         "vkCmdDebugMarkerInsertEXT")
	set_proc_address(&CmdBindTransformFeedbackBuffersEXT,              "vkCmdBindTransformFeedbackBuffersEXT")
	set_proc_address(&CmdBeginTransformFeedbackEXT,                    "vkCmdBeginTransformFeedbackEXT")
	set_proc_address(&CmdEndTransformFeedbackEXT,                      "vkCmdEndTransformFeedbackEXT")
	set_proc_address(&CmdBeginQueryIndexedEXT,                         "vkCmdBeginQueryIndexedEXT")
	set_proc_address(&CmdEndQueryIndexedEXT,                           "vkCmdEndQueryIndexedEXT")
	set_proc_address(&CmdDrawIndirectByteCountEXT,                     "vkCmdDrawIndirectByteCountEXT")
	set_proc_address(&CreateCuModuleNVX,                               "vkCreateCuModuleNVX")
	set_proc_address(&CreateCuFunctionNVX,                             "vkCreateCuFunctionNVX")
	set_proc_address(&DestroyCuModuleNVX,                              "vkDestroyCuModuleNVX")
	set_proc_address(&DestroyCuFunctionNVX,                            "vkDestroyCuFunctionNVX")
	set_proc_address(&CmdCuLaunchKernelNVX,                            "vkCmdCuLaunchKernelNVX")
	set_proc_address(&GetImageViewHandleNVX,                           "vkGetImageViewHandleNVX")
	set_proc_address(&GetImageViewAddressNVX,                          "vkGetImageViewAddressNVX")
	set_proc_address(&CmdDrawIndirectCountAMD,                         "vkCmdDrawIndirectCountAMD")
	set_proc_address(&CmdDrawIndexedIndirectCountAMD,                  "vkCmdDrawIndexedIndirectCountAMD")
	set_proc_address(&GetShaderInfoAMD,                                "vkGetShaderInfoAMD")
	set_proc_address(&CmdBeginConditionalRenderingEXT,                 "vkCmdBeginConditionalRenderingEXT")
	set_proc_address(&CmdEndConditionalRenderingEXT,                   "vkCmdEndConditionalRenderingEXT")
	set_proc_address(&CmdSetViewportWScalingNV,                        "vkCmdSetViewportWScalingNV")
	set_proc_address(&DisplayPowerControlEXT,                          "vkDisplayPowerControlEXT")
	set_proc_address(&RegisterDeviceEventEXT,                          "vkRegisterDeviceEventEXT")
	set_proc_address(&RegisterDisplayEventEXT,                         "vkRegisterDisplayEventEXT")
	set_proc_address(&GetSwapchainCounterEXT,                          "vkGetSwapchainCounterEXT")
	set_proc_address(&GetRefreshCycleDurationGOOGLE,                   "vkGetRefreshCycleDurationGOOGLE")
	set_proc_address(&GetPastPresentationTimingGOOGLE,                 "vkGetPastPresentationTimingGOOGLE")
	set_proc_address(&CmdSetDiscardRectangleEXT,                       "vkCmdSetDiscardRectangleEXT")
	set_proc_address(&SetHdrMetadataEXT,                               "vkSetHdrMetadataEXT")
	set_proc_address(&SetDebugUtilsObjectNameEXT,                      "vkSetDebugUtilsObjectNameEXT")
	set_proc_address(&SetDebugUtilsObjectTagEXT,                       "vkSetDebugUtilsObjectTagEXT")
	set_proc_address(&QueueBeginDebugUtilsLabelEXT,                    "vkQueueBeginDebugUtilsLabelEXT")
	set_proc_address(&QueueEndDebugUtilsLabelEXT,                      "vkQueueEndDebugUtilsLabelEXT")
	set_proc_address(&QueueInsertDebugUtilsLabelEXT,                   "vkQueueInsertDebugUtilsLabelEXT")
	set_proc_address(&CmdBeginDebugUtilsLabelEXT,                      "vkCmdBeginDebugUtilsLabelEXT")
	set_proc_address(&CmdEndDebugUtilsLabelEXT,                        "vkCmdEndDebugUtilsLabelEXT")
	set_proc_address(&CmdInsertDebugUtilsLabelEXT,                     "vkCmdInsertDebugUtilsLabelEXT")
	set_proc_address(&CmdSetSampleLocationsEXT,                        "vkCmdSetSampleLocationsEXT")
	set_proc_address(&GetImageDrmFormatModifierPropertiesEXT,          "vkGetImageDrmFormatModifierPropertiesEXT")
	set_proc_address(&CreateValidationCacheEXT,                        "vkCreateValidationCacheEXT")
	set_proc_address(&DestroyValidationCacheEXT,                       "vkDestroyValidationCacheEXT")
	set_proc_address(&MergeValidationCachesEXT,                        "vkMergeValidationCachesEXT")
	set_proc_address(&GetValidationCacheDataEXT,                       "vkGetValidationCacheDataEXT")
	set_proc_address(&CmdBindShadingRateImageNV,                       "vkCmdBindShadingRateImageNV")
	set_proc_address(&CmdSetViewportShadingRatePaletteNV,              "vkCmdSetViewportShadingRatePaletteNV")
	set_proc_address(&CmdSetCoarseSampleOrderNV,                       "vkCmdSetCoarseSampleOrderNV")
	set_proc_address(&CreateAccelerationStructureNV,                   "vkCreateAccelerationStructureNV")
	set_proc_address(&DestroyAccelerationStructureNV,                  "vkDestroyAccelerationStructureNV")
	set_proc_address(&GetAccelerationStructureMemoryRequirementsNV,    "vkGetAccelerationStructureMemoryRequirementsNV")
	set_proc_address(&BindAccelerationStructureMemoryNV,               "vkBindAccelerationStructureMemoryNV")
	set_proc_address(&CmdBuildAccelerationStructureNV,                 "vkCmdBuildAccelerationStructureNV")
	set_proc_address(&CmdCopyAccelerationStructureNV,                  "vkCmdCopyAccelerationStructureNV")
	set_proc_address(&CmdTraceRaysNV,                                  "vkCmdTraceRaysNV")
	set_proc_address(&CreateRayTracingPipelinesNV,                     "vkCreateRayTracingPipelinesNV")
	set_proc_address(&GetRayTracingShaderGroupHandlesKHR,              "vkGetRayTracingShaderGroupHandlesKHR")
	set_proc_address(&GetRayTracingShaderGroupHandlesNV,               "vkGetRayTracingShaderGroupHandlesNV")
	set_proc_address(&GetAccelerationStructureHandleNV,                "vkGetAccelerationStructureHandleNV")
	set_proc_address(&CmdWriteAccelerationStructuresPropertiesNV,      "vkCmdWriteAccelerationStructuresPropertiesNV")
	set_proc_address(&CompileDeferredNV,                               "vkCompileDeferredNV")
	set_proc_address(&GetMemoryHostPointerPropertiesEXT,               "vkGetMemoryHostPointerPropertiesEXT")
	set_proc_address(&CmdWriteBufferMarkerAMD,                         "vkCmdWriteBufferMarkerAMD")
	set_proc_address(&GetCalibratedTimestampsEXT,                      "vkGetCalibratedTimestampsEXT")
	set_proc_address(&CmdDrawMeshTasksNV,                              "vkCmdDrawMeshTasksNV")
	set_proc_address(&CmdDrawMeshTasksIndirectNV,                      "vkCmdDrawMeshTasksIndirectNV")
	set_proc_address(&CmdDrawMeshTasksIndirectCountNV,                 "vkCmdDrawMeshTasksIndirectCountNV")
	set_proc_address(&CmdSetExclusiveScissorNV,                        "vkCmdSetExclusiveScissorNV")
	set_proc_address(&CmdSetCheckpointNV,                              "vkCmdSetCheckpointNV")
	set_proc_address(&GetQueueCheckpointDataNV,                        "vkGetQueueCheckpointDataNV")
	set_proc_address(&InitializePerformanceApiINTEL,                   "vkInitializePerformanceApiINTEL")
	set_proc_address(&UninitializePerformanceApiINTEL,                 "vkUninitializePerformanceApiINTEL")
	set_proc_address(&CmdSetPerformanceMarkerINTEL,                    "vkCmdSetPerformanceMarkerINTEL")
	set_proc_address(&CmdSetPerformanceStreamMarkerINTEL,              "vkCmdSetPerformanceStreamMarkerINTEL")
	set_proc_address(&CmdSetPerformanceOverrideINTEL,                  "vkCmdSetPerformanceOverrideINTEL")
	set_proc_address(&AcquirePerformanceConfigurationINTEL,            "vkAcquirePerformanceConfigurationINTEL")
	set_proc_address(&ReleasePerformanceConfigurationINTEL,            "vkReleasePerformanceConfigurationINTEL")
	set_proc_address(&QueueSetPerformanceConfigurationINTEL,           "vkQueueSetPerformanceConfigurationINTEL")
	set_proc_address(&GetPerformanceParameterINTEL,                    "vkGetPerformanceParameterINTEL")
	set_proc_address(&SetLocalDimmingAMD,                              "vkSetLocalDimmingAMD")
	set_proc_address(&GetBufferDeviceAddressEXT,                       "vkGetBufferDeviceAddressEXT")
	set_proc_address(&CmdSetLineStippleEXT,                            "vkCmdSetLineStippleEXT")
	set_proc_address(&ResetQueryPoolEXT,                               "vkResetQueryPoolEXT")
	set_proc_address(&CmdSetCullModeEXT,                               "vkCmdSetCullModeEXT")
	set_proc_address(&CmdSetFrontFaceEXT,                              "vkCmdSetFrontFaceEXT")
	set_proc_address(&CmdSetPrimitiveTopologyEXT,                      "vkCmdSetPrimitiveTopologyEXT")
	set_proc_address(&CmdSetViewportWithCountEXT,                      "vkCmdSetViewportWithCountEXT")
	set_proc_address(&CmdSetScissorWithCountEXT,                       "vkCmdSetScissorWithCountEXT")
	set_proc_address(&CmdBindVertexBuffers2EXT,                        "vkCmdBindVertexBuffers2EXT")
	set_proc_address(&CmdSetDepthTestEnableEXT,                        "vkCmdSetDepthTestEnableEXT")
	set_proc_address(&CmdSetDepthWriteEnableEXT,                       "vkCmdSetDepthWriteEnableEXT")
	set_proc_address(&CmdSetDepthCompareOpEXT,                         "vkCmdSetDepthCompareOpEXT")
	set_proc_address(&CmdSetDepthBoundsTestEnableEXT,                  "vkCmdSetDepthBoundsTestEnableEXT")
	set_proc_address(&CmdSetStencilTestEnableEXT,                      "vkCmdSetStencilTestEnableEXT")
	set_proc_address(&CmdSetStencilOpEXT,                              "vkCmdSetStencilOpEXT")
	set_proc_address(&GetGeneratedCommandsMemoryRequirementsNV,        "vkGetGeneratedCommandsMemoryRequirementsNV")
	set_proc_address(&CmdPreprocessGeneratedCommandsNV,                "vkCmdPreprocessGeneratedCommandsNV")
	set_proc_address(&CmdExecuteGeneratedCommandsNV,                   "vkCmdExecuteGeneratedCommandsNV")
	set_proc_address(&CmdBindPipelineShaderGroupNV,                    "vkCmdBindPipelineShaderGroupNV")
	set_proc_address(&CreateIndirectCommandsLayoutNV,                  "vkCreateIndirectCommandsLayoutNV")
	set_proc_address(&DestroyIndirectCommandsLayoutNV,                 "vkDestroyIndirectCommandsLayoutNV")
	set_proc_address(&CreatePrivateDataSlotEXT,                        "vkCreatePrivateDataSlotEXT")
	set_proc_address(&DestroyPrivateDataSlotEXT,                       "vkDestroyPrivateDataSlotEXT")
	set_proc_address(&SetPrivateDataEXT,                               "vkSetPrivateDataEXT")
	set_proc_address(&GetPrivateDataEXT,                               "vkGetPrivateDataEXT")
	set_proc_address(&CmdSetFragmentShadingRateEnumNV,                 "vkCmdSetFragmentShadingRateEnumNV")
	set_proc_address(&CmdSetVertexInputEXT,                            "vkCmdSetVertexInputEXT")
	set_proc_address(&GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI,   "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI")
	set_proc_address(&CmdSubpassShadingHUAWEI,                         "vkCmdSubpassShadingHUAWEI")
	set_proc_address(&CmdBindInvocationMaskHUAWEI,                     "vkCmdBindInvocationMaskHUAWEI")
	set_proc_address(&GetMemoryRemoteAddressNV,                        "vkGetMemoryRemoteAddressNV")
	set_proc_address(&CmdSetPatchControlPointsEXT,                     "vkCmdSetPatchControlPointsEXT")
	set_proc_address(&CmdSetRasterizerDiscardEnableEXT,                "vkCmdSetRasterizerDiscardEnableEXT")
	set_proc_address(&CmdSetDepthBiasEnableEXT,                        "vkCmdSetDepthBiasEnableEXT")
	set_proc_address(&CmdSetLogicOpEXT,                                "vkCmdSetLogicOpEXT")
	set_proc_address(&CmdSetPrimitiveRestartEnableEXT,                 "vkCmdSetPrimitiveRestartEnableEXT")
	set_proc_address(&CmdDrawMultiEXT,                                 "vkCmdDrawMultiEXT")
	set_proc_address(&CmdDrawMultiIndexedEXT,                          "vkCmdDrawMultiIndexedEXT")
	set_proc_address(&CreateAccelerationStructureKHR,                  "vkCreateAccelerationStructureKHR")
	set_proc_address(&DestroyAccelerationStructureKHR,                 "vkDestroyAccelerationStructureKHR")
	set_proc_address(&CmdBuildAccelerationStructuresKHR,               "vkCmdBuildAccelerationStructuresKHR")
	set_proc_address(&CmdBuildAccelerationStructuresIndirectKHR,       "vkCmdBuildAccelerationStructuresIndirectKHR")
	set_proc_address(&BuildAccelerationStructuresKHR,                  "vkBuildAccelerationStructuresKHR")
	set_proc_address(&CopyAccelerationStructureKHR,                    "vkCopyAccelerationStructureKHR")
	set_proc_address(&CopyAccelerationStructureToMemoryKHR,            "vkCopyAccelerationStructureToMemoryKHR")
	set_proc_address(&CopyMemoryToAccelerationStructureKHR,            "vkCopyMemoryToAccelerationStructureKHR")
	set_proc_address(&WriteAccelerationStructuresPropertiesKHR,        "vkWriteAccelerationStructuresPropertiesKHR")
	set_proc_address(&CmdCopyAccelerationStructureKHR,                 "vkCmdCopyAccelerationStructureKHR")
	set_proc_address(&CmdCopyAccelerationStructureToMemoryKHR,         "vkCmdCopyAccelerationStructureToMemoryKHR")
	set_proc_address(&CmdCopyMemoryToAccelerationStructureKHR,         "vkCmdCopyMemoryToAccelerationStructureKHR")
	set_proc_address(&GetAccelerationStructureDeviceAddressKHR,        "vkGetAccelerationStructureDeviceAddressKHR")
	set_proc_address(&CmdWriteAccelerationStructuresPropertiesKHR,     "vkCmdWriteAccelerationStructuresPropertiesKHR")
	set_proc_address(&GetDeviceAccelerationStructureCompatibilityKHR,  "vkGetDeviceAccelerationStructureCompatibilityKHR")
	set_proc_address(&GetAccelerationStructureBuildSizesKHR,           "vkGetAccelerationStructureBuildSizesKHR")
	set_proc_address(&CmdTraceRaysKHR,                                 "vkCmdTraceRaysKHR")
	set_proc_address(&CreateRayTracingPipelinesKHR,                    "vkCreateRayTracingPipelinesKHR")
	set_proc_address(&GetRayTracingCaptureReplayShaderGroupHandlesKHR, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR")
	set_proc_address(&CmdTraceRaysIndirectKHR,                         "vkCmdTraceRaysIndirectKHR")
	set_proc_address(&GetRayTracingShaderGroupStackSizeKHR,            "vkGetRayTracingShaderGroupStackSizeKHR")
	set_proc_address(&CmdSetRayTracingPipelineStackSizeKHR,            "vkCmdSetRayTracingPipelineStackSizeKHR")
	set_proc_address(&GetMemoryWin32HandleKHR,                         "vkGetMemoryWin32HandleKHR")
	set_proc_address(&GetMemoryWin32HandlePropertiesKHR,               "vkGetMemoryWin32HandlePropertiesKHR")
	set_proc_address(&ImportSemaphoreWin32HandleKHR,                   "vkImportSemaphoreWin32HandleKHR")
	set_proc_address(&GetSemaphoreWin32HandleKHR,                      "vkGetSemaphoreWin32HandleKHR")
	set_proc_address(&ImportFenceWin32HandleKHR,                       "vkImportFenceWin32HandleKHR")
	set_proc_address(&GetFenceWin32HandleKHR,                          "vkGetFenceWin32HandleKHR")
	set_proc_address(&GetMemoryWin32HandleNV,                          "vkGetMemoryWin32HandleNV")
	set_proc_address(&AcquireFullScreenExclusiveModeEXT,               "vkAcquireFullScreenExclusiveModeEXT")
	set_proc_address(&ReleaseFullScreenExclusiveModeEXT,               "vkReleaseFullScreenExclusiveModeEXT")
	set_proc_address(&GetDeviceGroupSurfacePresentModes2EXT,           "vkGetDeviceGroupSurfacePresentModes2EXT")

	// Loader Procedures
	set_proc_address(&CreateInstance,                       "vkCreateInstance")
	set_proc_address(&EnumerateInstanceExtensionProperties, "vkEnumerateInstanceExtensionProperties")
	set_proc_address(&EnumerateInstanceLayerProperties,     "vkEnumerateInstanceLayerProperties")
	set_proc_address(&EnumerateInstanceVersion,             "vkEnumerateInstanceVersion")
	set_proc_address(&DebugUtilsMessengerCallbackEXT,       "vkDebugUtilsMessengerCallbackEXT")
	set_proc_address(&DeviceMemoryReportCallbackEXT,        "vkDeviceMemoryReportCallbackEXT")

}


